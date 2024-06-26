/** Check the territories and make sure everything looks correct and zip assignments match the territories.
 *
 * History
 * -------
 * 10/22/2014 Dan Carmen        Created.
   01/18/2017 Dan Carmen        Changes to allow the code to run in production.
 *
 */
global without sharing class ZipTerritoryCheck implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

   global JobHelper jh = new JobHelper('ZipTerritoryCheck');
   
   global Integer numOfTerritories = 0;
   
   /** Default constructor.
    */
   global ZipTerritoryCheck() {
   } // ZipTerritoryCheck

   /** Query the batches to be processed.
    */
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      // for normal running
      return Database.getQueryLocator([Select Id
                                             ,Name
                                             ,CheckZipUser__c
                                             ,District__c
                                             ,District__r.Assistant__c
                                             ,District__r.Assistant__r.Id
                                             ,District__r.Assistant__r.IsActive
                                             ,District__r.Assistant__r.Name
                                             ,District__r.Manager__c
                                             ,District__r.Manager__r.Id
                                             ,District__r.Manager__r.IsActive
                                             ,District__r.Manager__r.Name
                                             ,Rep_Name__c
                                             ,Sales_Org__c
                                             ,TerritoryContact__c
                                             ,TerritoryRep__c
                                             ,TerritoryRep__r.Id
                                             ,TerritoryRep__r.IsActive
                                             ,TerritoryRep__r.HR_Person_Id__c
                                             ,TerritoryRep__r.Name
                                         From ZipTerritory__c
                                        Where Id in (Select ZipTerritory__c from Zip_Assignment__c where NeedsUpdate__c=true)
                                          and (TerritoryRep__r.IsActive = true or District__r.Assistant__r.IsActive = true or District__r.Manager__r.IsActive = true)]);
   } // start
   
   //global static Integer BATCH_SIZE=1;
   
   // In order to schedule a batch run
   global void execute(SchedulableContext sc) {
      ZipTerritoryCheck ztc = new ZipTerritoryCheck();
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('ZipTerritoryCheck');
      Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 1);
      database.executeBatch(ztc, batchSize);
   } // execute

   public static Boolean EVALUATE_TERRITORY_REP=Label.ZipTerritoryEvaluateRep == 'Y';
   
   global void execute(Database.BatchableContext BC, List<SObject> scope) {
      List<ZipTerritory__c> territories = (List<ZipTerritory__c>)scope;
      numOfTerritories += territories.size();
      System.debug('ZipTerritoryCheck number of territories='+territories.size());
      for (ZipTerritory__c terr : territories) {
         terr.CheckZipUser__c = true;
         if (EVALUATE_TERRITORY_REP && (terr.TerritoryRep__r == null || (terr.TerritoryRep__r != null && !terr.TerritoryRep__r.IsActive))) {
            evaluateTerritoryRep(terr);
         }
      }
      update territories;
   } // execute

   // if rep is not active, search for DSM or DSA. If not found, and is payroll, set to unassigned
   global void evaluateTerritoryRep(ZipTerritory__c terr) {
   	User territoryRep = terr.TerritoryRep__r;
      if (terr.District__r != null) {
         if (terr.District__r.Assistant__r != null && terr.District__r.Assistant__r.IsActive) {
            terr.TerritoryRep__c = terr.District__r.Assistant__c;
            territoryRep = terr.District__r.Assistant__r;
      	} else if (terr.District__r.Manager__r != null && terr.District__r.Manager__r.IsActive) {
            terr.TerritoryRep__c = terr.District__r.Manager__c;
            territoryRep = terr.District__r.Manager__r;
      	}
      } // if Terr
      
      ZipAssignment.setTerritoryRep(terr, territoryRep);
   } // evaluateTerritoryRep
   
   global void finish(Database.BatchableContext BC){
      // Get the ID of the AsyncApexJob representing this batch job
      String message = '\nTotal Territories Found to process: '+numOfTerritories;
      message += '\n';

     jh.completeJob(bc, 'Zip Territory Check', message);
     
     // see if there are remaining records to process
   
   } // finish
} // class ZipTerritoryCheck