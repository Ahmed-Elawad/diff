/* Batch process for updating a large quantity of Zip Assignments.  Built to run quarterly since we're no longer reevaluating ownership based on employee count changes.
   
   History
   -------
   03/25/2016 Jacob Hinds       Created
   05/05/2016 Jacob Hinds        Changing process to mark Zip Assignments to be changed based on MassupdateAccts Custom Setting
   03/25/2017 Dan Carmen        Change how zip assignment change records are being created.
   08/19/2019 Dan Carmen        Allow to set different sales orgs for each month (to split up so don't all run at once)
   06/23/2020 Dan Carmen        Changes due to new zip segment handling
   
 */
 
global with sharing class AcctEmployeeBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
   
   public static final String CLASS_NAME='AcctEmployeeBatch';

    global JobHelper jh = new JobHelper('AcctEmployeeBatch');
    global List<ID> zipIdList;
    global Date todayDate = System.today();
    global String[] salesOrgs;
    global Boolean isOffCycle = false;

    /** The time the process started. */
    global DateTime startTime;
    /** messages that occur during the process. */
    global String processNotes = '';
    
   global AcctEmployeeBatch() {
        system.debug('in constructor');
        /*
        if(salesOrgs==null){
            salesOrgs = new String[]{};
        }
        startTime = DateTime.now();
        List<MassUpdateAccts__c> settings = MassUpdateAccts__c.getAll().values();
                system.debug('list:'+settings);
        for(MassUpdateAccts__c setting:settings){
            if(setting.IsActive__c){
                salesOrgs.add(setting.Name);
            }
            if(setting.RunOffCycle__c){
                isOffCycle=true;
            }
        }
        */
    } // zipEmployeeBatch

    /** The total number of zips found. */
    global Integer numberZips = 0;
    
    global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();

      String monthNbrStr = String.valueOf(DateTime.now().Month());
      salesOrgs = new String[]{};
      // build a dynamic list of sales orgs so we can run difference onces for each month.
      for (SalesOrg__c so : SalesOrg__c.getAll().values()) {
         if (so.HasOwnership__c && String.isNotBlank(so.BatchMonthNumbers__c)) {
            Set<String> monthNbrs = new Set<String>(so.BatchMonthNumbers__c.split(','));
            if (monthNbrs.contains(monthNbrStr)) {
               salesOrgs.add(so.Name);
            }
         }
      } // for (SalesOrg__c so
      system.debug('starting Batch process');
      return Database.getQueryLocator([SELECT Id,Sales_Org__c,CreateChangeRecord__c 
                                         FROM Zip_Assignment__c 
                                        WHERE Sales_Org__c in :salesOrgs]);
    } // start
    
   global void execute(SchedulableContext sc) {
      system.debug('Batch Process scheduled');
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
      if (abc != null && abc.Active__c) {
         AcctEmployeeBatch aeb = new AcctEmployeeBatch();
         Integer batchSize = (abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 500);
         //Integer month = system.today().Month();
         //Set<Integer> monthSet = new Set<Integer>{1,4,7,10};
         //if(monthSet.contains(month)||isOffCycle){
            database.executeBatch(aeb, batchSize);
         //}
      }
   } // execute
   
    global void execute(Database.BatchableContext BC, List<SObject> scope)
    {
      List<Zip_Assignment__c> zips = (List<Zip_Assignment__c>)scope;
      system.debug('Batch Process Zips to Update: '+zips);
      numberZips += zips.size();
      List<Zip_Assignment__c> updateZips = new List<Zip_Assignment__c>();
      Set<Id> zaIdSet = new Set<Id>();
      for (Zip_Assignment__c zip : zips) {
         zaIdSet.add(zip.Id);
         zip.CreateChangeRecord__c=true;
         updateZips.add(zip);
      }
      if (!zaIdSet.isEmpty()) {
         try {
            ZipAssignment.createChangeRecords(zaIdSet);
         } catch (Exception e) {
            ErrorLog.logError('AcctEmployeeBatch', 'execute', 'updateZips', zips[0].Id, e, zips[0],true);
         }
      }
                
    } // execute
    
   global void finish(Database.BatchableContext BC){
      String message = '\nSales Orgs='+salesOrgs;
      message += '\nTotal Zip Assignment processed: '+ numberZips+' ';
       message += '\n\n'+processNotes;
       system.debug('message:'+message);
      jh.completeJob(bc, 'AcctEmployeeBatch process', message);

   } // finish     
    
}