/* 
 * A batch job to run checks on objects to see if they're being used.
 * 
        Database.executeBatch(new ProcessChecker(), 1);

  replace PartnerReferralMonitor, BatchJobChecker

 *
 * History
 * -------
   01/14/2019 Dan Carmen        Created
   09/04/2020 Dan Carmen        Update code so it works properly.
   01/22/2021 Dan Carmen        Add option to permanently delete 
   04/22/2021 Dan Carmen        Change launchBatch method
   08/10/2022 Justin Stouffer   Add option to check recycle bin
 */
global with sharing class ProcessChecker implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

   global static final String CLASSNAME='ProcessChecker';
   // which process types does this process run for?
   global static String[] PROCESS_TYPES = new String[]{'Data Check Only'};
   
   // The total number of purge records found.
   global Integer numberPurges = 0;
   // The total number processes that we found that were outside of the acceptable range.
   global Integer numberOutsideRange = 0;
   /** The time the process started. */
   global DateTime startTime;
   
   // messages that occur during the process. 
   global String processNotes = '';
   
   global JobHelper jh = new JobHelper(CLASSNAME);
   
   global ProcessChecker() {
      startTime = DateTime.now();
   } // UserUpdateFromContact
   
   global String[] processMsgs = new String[]{};

   global String msgExtra = '';
    
   global Database.QueryLocator start(Database.BatchableContext BC){
       
      String instanceName = Utilities.checkForProduction();
      if (String.isNotBlank(instanceName)) {
         msgExtra = 'This was running in the '+instanceName+' instance. \n\n';
      }

      // save the record - show that the job started
      jh.setStarted();
      return getDataLocator(PROCESS_TYPES);
   } // start

   global static Database.QueryLocator getDataLocator(String[] processTypes){
       
      return Database.getQueryLocator([SELECT id, Name
                                             ,AdditionalPurgeCriteria__c
                                             ,AlwaysEmail__c
                                             //,Archive__c
                                             //,ArchiveFrequency__c
                                             ,BatchSize__c
                                             ,BusinessHoursOnly__c
                                             ,CheckApexClass__c
                                             ,CheckRecycleBin__c
                                             ,DateFieldToCheck__c
                                             ,DaysToRun__c
                                             ,EmailBody__c
                                             ,EmailNotification__c
                                             ,EmailSubject__c
                                             ,IsActive__c
                                             ,LatestQuery__c
                                             ,MoreRecords__c
                                             ,NbrDaysToKeep__c
                                             ,NbrMinutesToQuery__c
                                             //,Next_Archive_Date__c
                                             ,NextRunDays__c
                                             ,NextRunInterval__c
                                             ,NextRunTime__c
                                             ,Notes__c
                                             ,ObjectAPIName__c
                                             ,PermanentlyDelete__c
                                             ,ProcessCheckMinRecs__c
                                             ,ProcessCheckMaxRecs__c
                                             ,ProcessNotes__c
                                             ,ProcessType__c
                                             ,RelaunchBatch__c 
                                             ,TimeOfDayToRun__c
                                             ,TotalNbrRecordsPurged__c
                                             // only pull the latest tracker record to see if we reuse based on purge date 
                                             ,(Select Id
                                                     ,EndDate__c
                                                     ,NbrFailed__c
                                                     ,NbrFound__c
                                                     ,NbrIterations__c
                                                     ,NbrRecsPurged__c
                                                     ,OutsideRange__c
                                                     ,PurgeDate__c
                                                     ,SecondsProcessed__c
                                                     ,StartDate__c
                                                 From PurgeControlTrackers__r
                                                order by CreatedDate desc limit 1 )
                                         FROM PurgeControl__c 
                                        WHERE IsActive__c = true
                                          AND ProcessType__c in :processTypes
                                          AND (NextRunTime__c=null OR NextRunTime__c <= :Datetime.now())
                                       order by NextRunTime__c ASC]);
   } // getDataLocator

   // get a single record to process that can be run anytime. Get the oldest record that meets the criteria
   global static PurgeControl__c getAnyTimeRecord(String[] processTypes){
       
      PurgeControl__c[] pcs = [SELECT id, Name
                                             ,AdditionalPurgeCriteria__c
                                             ,AlwaysEmail__c
                                             //,Archive__c
                                             //,ArchiveFrequency__c
                                             ,BatchSize__c
                                             ,BusinessHoursOnly__c
                                             ,CheckApexClass__c
                                             ,CheckRecycleBin__c
                                             ,DateFieldToCheck__c
                                             ,DaysToRun__c
                                             ,EmailBody__c
                                             ,EmailNotification__c
                                             ,EmailSubject__c
                                             ,IsActive__c
                                             ,LatestQuery__c
                                             ,MoreRecords__c
                                             ,NbrDaysToKeep__c
                                             ,NbrMinutesToQuery__c
                                             //,Next_Archive_Date__c
                                             ,NextRunDays__c
                                             ,NextRunInterval__c
                                             ,NextRunTime__c
                                             ,Notes__c
                                             ,ObjectAPIName__c
                                             ,PermanentlyDelete__c
                                             ,ProcessCheckMinRecs__c
                                             ,ProcessCheckMaxRecs__c
                                             ,ProcessNotes__c
                                             ,ProcessType__c
                                             ,RelaunchBatch__c
                                             ,TimeOfDayToRun__c
                                             ,TotalNbrRecordsPurged__c
                                             // only pull the latest tracker record to see if we reuse based on purge date 
                                             ,(Select Id
                                                     ,EndDate__c
                                                     ,NbrFailed__c
                                                     ,NbrFound__c
                                                     ,NbrIterations__c
                                                     ,NbrRecsPurged__c
                                                     ,OutsideRange__c
                                                     ,PurgeDate__c
                                                     ,SecondsProcessed__c
                                                     ,StartDate__c
                                                 From PurgeControlTrackers__r
                                                order by CreatedDate desc limit 1 )
                                         FROM PurgeControl__c 
                                        WHERE IsActive__c = true
                                          AND ProcessType__c in :processTypes
                                          AND AllowRunAnytime__c = true
                                       ORDER BY LastModifiedDate Asc ];
      return (pcs.size() > 0 ? pcs[0] : null);
   } // getAnyTimeRecord

   // In order to schedule a batch run
   global void execute(SchedulableContext sc) {
      launchBatch();
   } // execute

   // Execute a batch.
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<PurgeControl__c> purges = (List<PurgeControl__c>)scope;
      numberPurges += purges.size();
      PurgeControlTracker__c[] insertTrackers = new PurgeControlTracker__c[]{};
      PurgeControlTracker__c[] updateTrackers = new PurgeControlTracker__c[]{};
      Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[]{};
      
      for (PurgeControl__c pc : purges) {
         PurgeControlTracker__c pcd = getTracker(pc, Date.today(), insertTrackers, updateTrackers);
         if (String.isNotBlank(pc.CheckApexClass__c)) {
            try {
               Type t = Type.forName(pc.CheckApexClass__c);
               BatchControlInterface batchInstance = (BatchControlInterface)t.newInstance();
               Boolean success = batchInstance.handleProcessCheck(pc, pcd,emails, processMsgs);
               numberOutsideRange = numberOutsideRange + (!success ? 1 : 0);
            } catch  (Exception e) {
               pc.IsActive__c = false;
               String exMessage = pc.Name+' Exception instantiating class '+pc.CheckApexClass__c+': '+e.getMessage()+'; '+e.getStackTraceString();
               StringHelper.addToProcessNotes(pc, exMessage);
               processMsgs.add(exMessage);
               numberOutsideRange++;
            }
         } else {
            handleProcessCheck(pc,pcd, emails);
         }
         setNextRunTime(pc);
      } // for (PurgeControl__c pc
      
      System.debug('execute purges='+purges.size()+' insertTrackers='+insertTrackers.size()+' updateTrackers='+updateTrackers.size());
      DmlHelper.performDML(purges, DmlHelper.DML_UPDATE, 'PurgeBatch', 'execute', 'update the purge records', true);
      DmlHelper.performDML(insertTrackers, DmlHelper.DML_INSERT, 'PurgeBatch', 'execute', 'inserting purge trackers', true);
      DmlHelper.performDML(updateTrackers, DmlHelper.DML_UPDATE, 'PurgeBatch', 'execute', 'updating purge trackers', true);
      if (!emails.isEmpty()) {
         Messaging.sendEmail(emails);
      }

   } // execute

  // The maximum number of records to retrieve at once. 
   public static Integer MAX_BATCH=1000;

   global void handleProcessCheck(PurgeControl__c pc, PurgeControlTracker__c pcd, Messaging.SingleEmailMessage[] emails) {
      System.debug('handleProcessCheck pc='+pc.Name);
      // verify Purge Control has criteria
      if ((String.isBlank(pc.DateFieldToCheck__c) || (pc.NbrDaysToKeep__c == null && pc.NbrMinutesToQuery__c == null)) && (String.isBlank(pc.AdditionalPurgeCriteria__c))) {
         pc.IsActive__c = false;
         numberOutsideRange++;
         StringHelper.addToProcessNotes(pc, 'Check criteria could not be found!');
         processMsgs.add(pc.Name+': Check criteria could not be found!');
         System.debug('handleProcessCheck check criteria could not be found');
         return;
      } // if ((String.isBlank(pc.DateFieldToCheck__c
      
      // need number of records to check for - if more than x records or less than x records? 
      // email body?
      

      // so we can calculate how many seconds this is running
      Datetime processStart = DateTime.now();
      Integer batchSize = MAX_BATCH;
      if (pc.BatchSize__c != null && pc.BatchSize__c > 0) {
         batchSize = Integer.valueOf(pc.BatchSize__c);
      }
       
      String procInfo = 'Count for '+pc.Name+', object '+pc.ObjectAPIName__c+', ';
      // build the query
      String query = 'Select count() from '+pc.ObjectAPIName__c;   // change this from PurgeBatch
      Date checkDate = Date.today(); // we will be running this every day to check the status - keep track here
      Datetime checkDateTime = Datetime.now();
      
      String[] addlCriteria = new String[]{};
      if (String.isNotBlank(pc.DateFieldToCheck__c) && pc.NbrMinutesToQuery__c != null) {
         checkDateTime = Datetime.now().addMinutes(-(Integer)pc.NbrMinutesToQuery__c);
         procInfo += 'checkDateTime='+checkDateTime.format('M/d/yyyy hh:mm')+' ';
         addlCriteria.add(pc.DateFieldToCheck__c+'>= :checkDateTime ');
      }
      // to check for records found in the last N days
      if (String.isNotBlank(pc.DateFieldToCheck__c) && pc.NbrDaysToKeep__c != null) {
         checkDate = Date.today().addDays(-(Integer)pc.NbrDaysToKeep__c);
         procInfo += 'checkDate='+checkDate+' ';
         addlCriteria.add(pc.DateFieldToCheck__c+'>= :checkDate ');
      }
      if (String.isNotBlank(pc.AdditionalPurgeCriteria__c)) {
         addlCriteria.add(pc.AdditionalPurgeCriteria__c);
      }
      if (!addlCriteria.isEmpty()) {
         query += (' where '+String.join(addlCriteria,' and '));
      }
      query += ' limit :batchSize ';
      if (pc.CheckRecycleBin__c){
         query += ' ALL ROWS ';     
      }

      pc.LatestQuery__c = query;
      
      try {
         Integer foundNow = Database.countQuery(query);
         System.debug('handleProcessCheck foundNow='+foundNow);
         pcd.NbrFound__c += foundNow;
         pcd.NbrIterations__c++;
         
         
         String emailBody = null;
         procInfo += 'Number of records found: '+foundNow+'. ';
         Boolean outsideRange = false;
         if (pc.ProcessCheckMaxRecs__c != null && foundNow > pc.ProcessCheckMaxRecs__c) {
            outsideRange = true;
            procInfo += 'Maximum expected is '+pc.ProcessCheckMaxRecs__c+'! ****';
         } else if (pc.ProcessCheckMinRecs__c != null && foundNow < pc.ProcessCheckMinRecs__c) {
            outsideRange = true;
            procInfo += 'We are expecting at least '+pc.ProcessCheckMinRecs__c+' record(s)! **** ';
         }
         if (outsideRange) {
            numberOutsideRange++;
            pcd.OutsideRange__c = true;
         }
         if (outsideRange || pc.AlwaysEmail__c) {
            procInfo += '\n\n'+query;
            buildEmail(pc, procInfo, emails);
         }
         
         String checkNotes = (pc.Name+' foundNow='+foundNow+' procInfo='+procInfo);
         processMsgs.add(checkNotes);
         //processNotes += ('\n    '+checkNotes);

         StringHelper.addToProcessNotes(pc, checkNotes);
      } catch (Exception e) {
         pc.IsActive__c=false;
         StringHelper.addToProcessNotes(pc, 'Error in query: '+query+'. Ex='+e.getMessage()+'; '+e.getStackTraceString());
         System.debug(pc.Name+' handleProcessCheck notes='+pc.Notes__c);
         processMsgs.add('Exception occurred with '+pc.Name+'! query: '+query+'. Ex='+e.getMessage());
      }
      pcd.EndDate__c=DateTime.now();
      Integer numSeconds = Integer.valueOf((pcd.EndDate__c.getTime() - processStart.getTime())/1000);
      pcd.SecondsProcessed__c += numSeconds;
   } // handleProcessCheck
    
   global static void setNextRunTime(PurgeControl__c pc) {
      pc.NextRunTime__c = null;
      if (pc.TimeOfDayToRun__c != null) {
         Integer nbrDays = (pc.NextRunDays__c != null && pc.NextRunDays__c > 0 ? Integer.valueOf(pc.NextRunDays__c) : 1);
         pc.NextRunTime__c = DateTime.newInstance(Date.today().addDays(nbrDays), pc.TimeOfDayToRun__c);
      } else if (pc.NextRunInterval__c != null) {
         Integer nbrMinutes = Integer.valueOf(pc.NextRunInterval__c);
         if (!pc.BusinessHoursOnly__c) {
            pc.NextRunTime__c = Datetime.now().addMinutes(nbrMinutes);
            if (pc.NextRunDays__c != null && pc.NextRunDays__c > 0) {
               pc.NextRunTime__c.addDays(Integer.valueOf(pc.NextRunDays__c));
            }
         } else {
            BusinessHours[] hours = [Select Id, Name, TimeZoneSidKey from BusinessHours where IsActive=true and Name = 'Sales Support' limit 1];
            if (!hours.isEmpty()) {
                pc.NextRunTime__c = BusinessHours.add(hours[0].id , Datetime.now(), (nbrMinutes * 60000));
            } else {
                StringHelper.addToProcessNotes(pc,'\n **** Could NOT find the Sales Support Business Hours');
            }
         }
      }
      // if days of the week are specified, make sure the scheduled next run time is on one of those days
      if (pc.NextRunTime__c != null && String.isNotBlank(pc.DaysToRun__c) && pc.DaysToRun__c != 'All') {
         Set<String> daysSet = new Set<String>(pc.DaysToRun__c.split(';'));
         String nextDay = pc.NextRunTime__c.format('EEEE');
         Integer dayCounter = 0;
         while (!daysSet.contains(nextDay) && dayCounter < 7) {
            pc.NextRunTime__c = pc.NextRunTime__c.addDays(1);
            nextDay = pc.NextRunTime__c.format('EEEE');
            dayCounter++;
         } // while
      }
        
   } // setNextRunTime
    
   public static PurgeControlTracker__c getTracker(PurgeControl__c pc, Date purgeDate, PurgeControlTracker__c[] insertTrackers, PurgeControlTracker__c[] updateTrackers) {
      PurgeControlTracker__c pcd = null;
      if (pc.PurgeControlTrackers__r != null && !pc.PurgeControlTrackers__r.isEmpty()) {
         // only check the latest one (only one should be returned)
         if (pc.PurgeControlTrackers__r[0].PurgeDate__c == purgeDate) {
            pcd = pc.PurgeControlTrackers__r[0];
            updateTrackers.add(pcd);
         }
      }
      if (pcd == null) {
         // if one doesn't already exist for the date create a new one.
         pcd = new PurgeControlTracker__c(PurgeControl__c=pc.Id, NbrRecsPurged__c=0, NbrIterations__c=0
                                         ,NbrFound__c=0, NbrFailed__c=0
                                         ,StartDate__c=Datetime.now()
                                         ,PurgeDate__c=purgeDate, SecondsProcessed__c=0);
         insertTrackers.add(pcd);
      }
      return pcd;
   } // getTracker
   
   // send an email for a specific process
   global void buildEmail(PurgeControl__c pc, String emailBody, Messaging.SingleEmailMessage[] emails) {
      if (String.isNotBlank(pc.EmailNotification__c )) {
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         mail.setTargetObjectId(UserInfo.getUserId());
         mail.setSaveAsActivity(false);
         String[] addressList = pc.EmailNotification__c.split(',');
         if (!addressList.isEmpty()) {
            mail.setCcAddresses(addressList);
         }
         String subject = (String.isNotBlank(pc.EmailSubject__c) ? pc.EmailSubject__c : '**'+pc.Name+' falls outside of its expected range!');
         mail.setSubject(subject);
         String body = msgExtra+(emailBody+ '\n'+ (String.isNotBlank(pc.EmailBody__c) ? pc.EmailBody__c : 'Please take appropriate action.'));
         mail.setPlainTextBody(body);
         emails.add(mail);
      }
   } // buildEmail
   
   global void finish(Database.BatchableContext bc){
      // did this job already run today?
      Integer jobRuns = [select count() from Job_Tracker__c where Job_Name__c=:CLASSNAME and CreatedDate=today];
      
      String message = '\nTotal ProcessChecks Processed: '+numberPurges+' '; 
      message += '\nNumber of checks that fell outside acceptable range: '+numberOutsideRange+' \n'; 
      
      String msgSummary = '\n'+String.join(processMsgs,'\n\n');
      message += msgSummary;
      System.debug('finish processNotes='+processNotes);
      message += '\n\n'+processNotes;
      
      jh.completeJob(bc, 'Purge Batch', message);
      
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
       
      // update Apex Batch Control with the latest 
      System.debug('finish has numberOutsideRange='+numberOutsideRange+' jobRuns='+jobRuns+' abc='+abc);
      // send an email for the entire job. Only send if the first run of the day or results are falling outside of range.
      if ((numberOutsideRange > 0 || jobRuns == 0) && abc != null && abc.AdditionalEmails__c != null) {
         String subject = 'COE Process Tracker' + (numberOutsideRange > 0 ? ': HAS RESULTS OUTSIDE OF ACCEPTED RANGE' : '');
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         mail.setSaveAsActivity(false);

         mail.setTargetObjectId(UserInfo.getUserId());
         mail.setSubject(subject);
         mail.setPlainTextBody (msgExtra+message);

         if (String.isNotBlank(abc.AdditionalEmails__c)) {
            mail.setCcAddresses(abc.AdditionalEmails__c.split(','));
         }

         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      } // if (String.isNotBlank
      
      // only run once for a test
      if (!Test.isRunningTest()) {
         launchBatch();
      }
   } // finish
   
   public static DateTime getNextRunTime(String[] processTypes) {
      PurgeControl__c[] pcs = [SELECT Id, BusinessHoursOnly__c,IsActive__c
                                     ,NextRunTime__c
                                 FROM PurgeControl__c 
                                WHERE IsActive__c = true
                                  AND ProcessType__c in :processTypes
                                  AND NextRunTime__c !=null
                                order by NextRunTime__c asc];
      Datetime nextRunTime = (!pcs.isEmpty() ? pcs[0].NextRunTime__c : null);
      System.debug('getNextRunTime pcs='+pcs.size()+' nextRunTime='+nextRunTime);
      return nextRunTime;
   }

   public static void launchBatch() {
      DateTime nextRunTime = getNextRunTime(PROCESS_TYPES);
      if (nextRunTime != null) {
         JobHelper.launchBatchWithSchedule(new ProcessChecker(), CLASSNAME, nextRunTime, 1);
      }
   } // launchBatch

} // class ProcessChecker