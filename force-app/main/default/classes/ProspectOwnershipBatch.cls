/* 
 * Batch process to update the Prospect Ownership records
 *
 * History
 * -------
 * 10/14/2013 Dan Carmen   Created
   07/12/2017 Dan Carmen   Add additional logging
   10/21/2021 Dan Carmen   Ability to run for 1 status at a time

 */
global without sharing class ProspectOwnershipBatch implements Database.Batchable<SObject>, Database.Stateful , Schedulable  {
   public static final String CLASSNAME='ProspectOwnershipBatch';

   /** The number of distinct prospect ownership found. */
   global Integer numOwnershipRecs = 0;
   global CounterObj totalRecs = new CounterObj();
   
   /** The number of records at the end of their status cycle. */
   global CounterObj endOfStatusLeads = new CounterObj();
   global CounterObj endOfStatusAccts = new CounterObj();

   /** The number of records that changed to a new status - not expired. */
   global CounterObj newStatusLeads = new CounterObj();
   global CounterObj newStatusAccts = new CounterObj();

   /** The number of account team members created. */
   global Integer teamMembersCreated = 0;
   /** The number of account team members deleted. */
   global Integer teamMembersDeleted = 0;
   /** The number of accounts updated. */
   global Integer acctsUpdated = 0;
   /** The number of leads updated. */
   global Integer leadsUpdated = 0;
   
   /** The number of ownership records modified. */
   global Integer numOwnershipModified = 0;
   /** The number of ownership records ended. */
   global Integer numOwnershipRecsEnded = 0;
   /** The number of ownership records changed to workable. */
   global Integer numOwnershipRecsWorkable = 0;
   /** The number of ownership records where commission stage changed to end. */
   global Integer numOwnershipRecsComEnd = 0;
   /** The number of ownership records attached to accounts. */
   global Integer numAccountOwnerships = 0;
   /** The number of ownership records attached to leads. */
   global Integer numLeadOwnerships = 0;
   
   
   global String processingMsg = '';
   
   global String batchMsg = '';
   
   global JobHelper jh = new JobHelper('ProspectOwnershipBatch');
   
   public static String[] STATUSES = Label.ProspectOwnershipBatch_Statuses.split(',');
   public String mode=null;
    
   /** Default constructor.
    */
   global ProspectOwnershipBatch() {
   } // ProspectOwnershipBatch
   
      /** Query the batches to be processed.
    */
   global Database.QueryLocator start(Database.BatchableContext BC){
      if (mode == null) {
         mode = STATUSES[0];
      }
      String queryMode = mode;
      // save the record - show that the job started
      jh.setStarted();
      // for normal running
      String query = ProspectOwnershipMethods.getProspectOwnerQuery(); //ObjectHelper.getSOQLQuery('Prospect_Ownership__c',null,true, true);
      // get all non-ended ownership records
      return Database.getQueryLocator(query+' Where EndDate__c = null and Ownership_Status__c=:queryMode');

   } // start
   
   global static Integer BATCH_SIZE=100;
   
   /** In order to schedule a batch run
    */
   global void execute(SchedulableContext sc) {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      Integer batchSize = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 100);
      ProspectOwnershipBatch pob = new ProspectOwnershipBatch();
      database.executeBatch(pob, batchSize);
   } // execute

   global void execute(Database.BatchableContext BC, List<SObject> scope) {
      List<Prospect_Ownership__c> recs = (List<Prospect_Ownership__c>)scope;
      System.debug('ProspectOwnershipBatch number of recs='+recs.size());
      
      // the records to update
      Prospect_Ownership__c[] updateRecs = new Prospect_Ownership__c[]{};
      
      // the ownership records that are linked to accounts
      Prospect_Ownership__c[] acctRecs = new Prospect_Ownership__c[]{};
      // the account ids
      Id[] acctIds = new Id[]{};
      // the ownership records that are linked to leads
      Prospect_Ownership__c[] leadRecs = new Prospect_Ownership__c[]{};
      // the lead ids
      Id[] leadIds = new Id[]{};
      
      ProspectOwnershipMethods.initializeSaveObjects();
      
      // keep a total count
      numOwnershipRecs += recs.size();
      
      // separate out the leads and the accounts
      for (Prospect_Ownership__c po : recs) {
      	// keep track of total number of records found
      	addToCounter(totalRecs, po.NSS_Team__c, po.Ownership_Status__c, 1);
      	
      	//String key = po.Ownership_Status__c+'-'+po.NSS_Team__c;
      	
      	// see if there's a setting for this value. If not - what do we do with this record?
      	LifeOfLeadSettings__c lols = ProspectOwnershipMethods.getSetting(po);
      	if (lols != null) {
      		// check the start date of the ownership record
      		if (String.IsNotBlank(lols.StageStartDateField__c)) {
      		   Date startDate = (Date)po.get(lols.StageStartDateField__c);
      		   Date endDate = (Date)po.get(lols.StageEndDateField__c);
      		   if (startDate != null) {
      		      // get how many days from the start date
      		      Integer numDays = startDate.daysBetween(Date.today());
      		      // if we're at the end of a stage
      		      if (numDays >= lols.NumOfDays__c) {
      		      	// we will be updating this record
      		      	updateRecs.add(po);
      		      	
      		      	// should always be either an account or a lead.
                     if (po.Prospect_Client__c != null) {
                        // the number of records that have reached the end of their status
                        addToCounter(endOfStatusAccts, po.NSS_Team__c, po.Ownership_Status__c, 1);

                        acctRecs.add(po);
                        acctIds.add(po.Prospect_Client__c);
                     } else if (po.Lead__c != null) {
                        // the number of records that have reached the end of their status
                        addToCounter(endOfStatusLeads, po.NSS_Team__c, po.Ownership_Status__c, 1);

                        leadRecs.add(po);
                        leadIds.add(po.Lead__c);
                     }

      		         
      		      }
      		   } // if (startDate != null
      		} // if (String.IsNotBlank
      	} // if (lols != null
      	
      } // for
      
      if (!updateRecs.isEmpty()) {
      
         if (!acctRecs.isEmpty()) {
      	   processAccounts(acctRecs,acctIds);
         }
      
         if (!leadRecs.isEmpty()) {
            processLeads(leadRecs,leadIds);
         }
         
         Database.SaveResult[] results = Database.update(updateRecs,false);
         
         ProspectOwnershipMethods.checkForSaves();
         
         // update quantity counts
         teamMembersCreated += ProspectOwnershipMethods.newATMMap.size();
         teamMembersDeleted += ProspectOwnershipMethods.delATMMap.size();
         acctsUpdated += ProspectOwnershipMethods.saveAcctMap.size();
         leadsUpdated += ProspectOwnershipMethods.saveLeadMap.size();
      } // if (!updateRecs

   } // execute
   
   global Boolean processAccounts(Prospect_Ownership__c[] acctRecs, Id[] acctIds) {
      Boolean okay = true;
      numAccountOwnerships += acctRecs.size();
      // select the accounts
      Map<Id, Account> acctMap = ReferralQueries.selectAcctMap(acctIds);
      for (Prospect_Ownership__c po : acctRecs) {
      	// keep original status to see if it changes
      	String originalStatus = po.Ownership_Status__c;
         ProspectOwnerShipMethods.setStageExitInfo(po,acctMap.get(po.Prospect_Client__c), null, null, null, true, true, false);
         System.debug('ProspectOwnershipBatch.processAccounts originalStatus='+originalStatus+' new status='+po.Ownership_Status__c);
         ProspectOwnershipMethods.addToProcessTracker(po,'ProspectOwnershipBatch.processAccounts originalStatus='+originalStatus+' new status='+po.Ownership_Status__c);
         
         // if status changes and not ended, go to settings for new status
         if (po.EndDate__c == null && originalStatus != po.Ownership_Status__c) {
            // the number of records that have reached the end of their status
            addToCounter(newStatusAccts, po.NSS_Team__c, po.Ownership_Status__c, 1);

            ProspectOwnershipMethods.setStageEntryInfo(po, acctMap.get(po.Prospect_Client__c), null, null, null, true, false);
         }
      } // for
      return okay;
   } // processAccounts
   
   global Boolean processLeads(Prospect_Ownership__c[] leadRecs, Id[] leadIds) {
      Boolean okay = true;
      numLeadOwnerships += leadRecs.size();
      // select the leads
      Map<Id, Lead> leadMap = ReferralQueries.selectLeadMap(leadIds,null);
      for (Prospect_Ownership__c po : leadRecs) {
         // keep original status to see if it changes
         String originalStatus = po.Ownership_Status__c;
         ProspectOwnerShipMethods.setStageExitInfo(po,null, null, null, leadMap.get(po.Lead__c), true, true, false);
         System.debug('ProspectOwnershipBatch.processLeads originalStatus='+originalStatus+' new status='+po.Ownership_Status__c);
         ProspectOwnershipMethods.addToProcessTracker(po,'ProspectOwnershipBatch.processLeads originalStatus='+originalStatus+' new status='+po.Ownership_Status__c);
         
         // if status changes and not ended, go to settings for new status
         if (po.EndDate__c == null && originalStatus != po.Ownership_Status__c) {
            // the number of records that have reached the end of their status
            addToCounter(newStatusLeads, po.NSS_Team__c, po.Ownership_Status__c, 1);

            ProspectOwnershipMethods.setStageEntryInfo(po, null, null, null, leadMap.get(po.Lead__c), true, false);
         }
      } // for
      return okay;
   } // processLeads
   
   /** Add statistics to the counter object.
    */
   public void addToCounter(CounterObj counter, String team, String status, Integer nbrToAdd) {
   	Integer cnt = counter.countByTeamMap.get(team);
   	Integer newCnt = (cnt != null ? cnt : 0) + nbrToAdd;
   	counter.countByTeamMap.put(team, newCnt);
   	
   	cnt = counter.countByStatusMap.get(status);
      newCnt = (cnt != null ? cnt : 0) + nbrToAdd;
      counter.countByStatusMap.put(status, newCnt);
   } // addToCounter
   
   /** Output the stats from the counter object.
    */
   public String outputCounter(String title, CounterObj counter) {
      String output = '';
      output += printMap(title+' by Team:',counter.countByTeamMap);
      output += printMap(title+' by Status:',counter.countByStatusMap);
      return output;
   } // outputCounter
   
   public String printMap(String title, Map<String,Integer> mapToPrint) {
   	String output = '';
      if (!mapToPrint.isEmpty()) {
         output += ('\n'+title);
         // sort the keys
         List<String> keys = new List<String>();
         keys.addAll(mapToPrint.keySet());
         keys.sort();
         for (String key : keys) {
            output += '\n   '+key+'='+mapToPrint.get(key);
         }
      } // if (!mapToPrint
      return output;
   } // printMap
   
   global void finish(Database.BatchableContext BC){
      // Get the ID of the AsyncApexJob representing this batch job
      String message = 'Running for Ownership_Status__c='+mode+'\n\n';
      message += '\nTotal Open Ownership Records Found: '+numOwnershipRecs;
      message += '\n';
      message += outputCounter('Total Records', totalRecs);

      message += '\n';
      message += outputCounter('Leads at End of Status', endOfStatusLeads);
      message += outputCounter('Prospect-Clients at End of Status', endOfStatusAccts);

      message += '\n';
      message += outputCounter('Leads with new Status', newStatusLeads);
      message += outputCounter('Prospect-Clients with new Status', newStatusAccts);
      
      message += '\n\nNumber of Prospect-Client Team members created='+teamMembersCreated;
      message += '\nNumber of Prospect-Client Team members deleted='+teamMembersCreated;

      message += '\n\nNumber of Prospect-Clients updated='+acctsUpdated;
      message += '\nNumber of Leads updated='+leadsUpdated;

      message += '\n'+batchMsg;
      
      jh.completeJob(bc, 'Prospect Ownership update', message);
      String nextMode = null;
      // find the next status in the list
      for (Integer cnt=0; cnt<STATUSES.size(); cnt++) {
         if (mode == STATUSES[cnt]) {
            if (cnt+1 <= STATUSES.size()) {
               nextMode = STATUSES[cnt+1];
            }
         }
      } // for (Integer cnt=0; cnt<STATUSES.size
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      // run for the next status
      if (!Test.isRunningTest() && nextMode != null && abc != null && abc.Active__c) {
         Integer batchSize = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 100);
         ProspectOwnershipBatch pob = new ProspectOwnershipBatch();
         pob.mode = nextMode;
         database.executeBatch(pob, batchSize);
      }
   } // finish
   
   // class used to count records being processed
   global class CounterObj {
   	global Map<String,Integer> countByTeamMap = new Map<String,Integer>();
   	global Map<String,Integer> countByStatusMap = new Map<String,Integer>();
      
      global Integer totalByTeam {
         get { Integer total=0;
         	   for (String key : countByTeamMap.keySet()) {
         	      total += countByTeamMap.get(key);
         	   }
         	   return total;
             }
      } // totalByTeam

      global Integer totalByStatus {
         get { Integer total=0;
               for (String key : countByStatusMap.keySet()) {
                  total += countByStatusMap.get(key);
               }
               return total;
             }
      } // totalByStatus
       
   } // class CounterObj
   
   /*
   Ownership Stage / Actions to take at end of stage
   Prospecting - end date ownership object/prospecting end date
       - Lead - ownership back to NSS queue, NSS Ownership Start Date = null
   Lockout - end date lockout stage, change to workable stage. Add to account team
   Workable - end date workable stage, change to expired, end date ownership.
   Expired
   Not Interested - end date NFI/Wash, change to expired, end date ownership
       - Lead - change to Recycle, NSS Ownership Start Date = null
   Wash - end date NFI/Wash, change to expired, end date ownership
       - Lead - change to Recycle, NSS Ownership Start Date = null
   */
   
} // class ProspectOwnershipBatch