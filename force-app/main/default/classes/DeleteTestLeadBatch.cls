/* 
  History
  -------
  01/23/2023 Pujitha Madamanchi   Remove DFR related code

 */
 global class DeleteTestLeadBatch implements Database.Batchable<sObject>, Database.Stateful {
    public static String CLASSNAME='DeleteTestLeadBatch';
    global JobHelper jh = new JobHelper(CLASSNAME);

    global Database.QueryLocator start(Database.BatchableContext bc) {
        jh = new JobHelper(CLASSNAME);
        // the query for the dataload object
        jh.tracker.Nbr_Batches__c=0;

        String query= Label.DeleteLeadsQuery;
        System.debug(' query='+query);
        try{
            return Database.getQueryLocator(query); 
        }
        catch (Exception e) {
            System.debug('Exception finding leads: '+e.getMessage());
            return null;  
        }
    }
    global void execute(SchedulableContext sc) {
        system.debug('Batch Process scheduled');
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
        // pull from the custom setting, otherwise use a default value.
        Integer batchSize = (abc != null ? Integer.valueOf(abc.BatchSize__c) : 200);
        DeleteTestLeadBatch deleteTestLeads = new DeleteTestLeadBatch();
        database.executeBatch(deleteTestLeads, batchSize);
     } // execute

    global void execute(Database.BatchableContext bc, List<SObject> scope){
        Set<Id> leadIds = new Set<Id>();
        Set<Id> referralIds = new Set<Id>();
        List<SObject> recordsToBeDeleted = new List<SObject>();
        for(SObject ld : scope){
            leadIds.add(ld.Id);
        }
        // quety each object based on lead Id and add then all to a sobject list
        List<Referral__c> referralList = [Select Id from Referral__c where SourceLead__c IN: leadIds];
        for(Referral__c ref: referralList){
            referralIds.add(ref.Id);
        }
        List<Transfer_Tracking__c> ttList = [Select Id from Transfer_Tracking__c where Referral_Lookup__c IN: referralIds];
        List<PartnerReferral__c> prList = [Select Id from PartnerReferral__c where (Lead__c IN: leadIds or Referral__c IN: referralIds)];
        List<Stage_History__c> stageHisList = [Select Id from Stage_History__c where Lead__c IN: leadIds];
        List<Marketing_Call_Tracking__c> mctList = [Select Id from Marketing_Call_Tracking__c where Lead__c IN: leadIds];
        List<Cadence_Assignment_Record__c> carList = [Select Id from Cadence_Assignment_Record__c where LeadId__c IN: leadIds];
        List<Task> tskList = [Select Id from Task where WhoId IN: leadIds];

        //We can only delete 10 objects at once in a single DML Statement. If we have more objects, we need to indiavially delete each object. 
        recordsToBeDeleted.addall(stageHisList);
        recordsToBeDeleted.addall(ttList);
        recordsToBeDeleted.addall(prList);
        recordsToBeDeleted.addall(referralList);
        recordsToBeDeleted.addall(mctList);
        recordsToBeDeleted.addall(carList);
        recordsToBeDeleted.addall(tskList);
        recordsToBeDeleted.addall(scope);

               
        jh.tracker.Nbr_Batches__c = recordsToBeDeleted.size();
        // delete the records
        try{
            delete recordsToBeDeleted;
            DataBase.emptyRecycleBin(recordsToBeDeleted);
            jh.addToNotes2('# of deleted test leads='+scope.size());
            jh.addToNotes2('# of deleted prList ='+prList.size());
            jh.addToNotes2('# of deleted referralList ='+referralList.size());
            jh.addToNotes2('# of deleted ttList ='+ttList.size());
            jh.addToNotes2('# of deleted stageHisList ='+stageHisList.size());
            jh.addToNotes2('# of deleted mctList ='+mctList.size());
            jh.addToNotes2('# of deleted carList ='+carList.size());
            jh.addToNotes2('# of deleted tskList ='+tskList.size());
        }
        catch(Exception ex){ 
            jh.addToNotes2('Error deleting records=');
        }
    }
    
    global void finish(Database.BatchableContext bc){
        System.debug(jh.tracker.Nbr_Batches__c + ' records deleted.');
       if ( !Test.isRunningTest()) {
        //  launchBatch();
       }
       jh.tracker.Process_End__c = Datetime.now();
       jh.tracker.Status__c = JobHelper.STATUS_COMPLETED;
       jh.saveJob();
    }
}