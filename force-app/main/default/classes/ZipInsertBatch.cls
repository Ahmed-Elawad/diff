/* 
 * Batch process to import zip code update information
 *
 * History
 * -------
   03/13/2015 Dan Carmen   Created
   09/05/2023 Dan Carmen   Add launchBatch method
   02/09/2024 Dan Carmen   Extra check for creating a change record

 */
global without sharing class ZipInsertBatch implements Database.Batchable<SObject>, Database.Stateful , Schedulable {
    
   public static final String CLASSNAME='ZipInsertBatch';

   // The number of distinct zip insert records processed. */
   global Integer numberZipInserts = 0;
   
   global Integer numberNotSuccess = 0;

   /** Keep track of totals by district number and sales org/segment name */
   global Map<String,Integer> changeByDistrictMap = new Map<String,Integer>();
   
   global String batchMsg = '';
   
   global Set<Id> zipImportIdSet = new Set<Id>();

   global JobHelper jh = new JobHelper(CLASSNAME);

   // The maximum number of records to retrieve at once. 
   //public static Integer BATCH_SIZE=1000;
   
   // Query the batches to be processed.
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      // for normal running
      return Database.getQueryLocator([SELECT Id
                                             ,Name
                                             ,District__c
                                             ,District__r.Id
                                             ,DistrictKey__c
                                             ,DistrictNbr__c
                                             ,ImportFieldsOkay__c
                                             ,IsSuccess__c
                                             ,Notes__c
                                             ,Processed__c
                                             ,Sales_Org__c
                                             ,Zip_Assignment__c
                                             ,Zip_Assignment__r.Id
                                             ,ZipImport__c
                                             ,ZipSegmentName__c
                                             ,ZipTerritory__c
                                             ,ZipTerritory__r.Id
                                             ,ZipTerritoryName__c
                                             ,ZipTerritoryOld__c
                                             ,ZipTerritoryOld__r.Id
                                         FROM ZipImportDetail__c
                                        WHERE Processed__c = false
                                        ORDER BY Name]);
   } // start

   // In order to schedule a batch run
   global void execute(SchedulableContext sc) {
      launchBatch();
   } // execute

   global void execute(Database.BatchableContext BC, List<SObject> scope) {
      List<ZipImportDetail__c> zips = (List<ZipImportDetail__c>)scope;
      System.debug('ZipBatch number of zips='+zips.size());
      numberZipInserts += zips.size();
      
      processZips(zips);
      
      ErrorLog.checkSave();
   } // execute
   
   private void processZips(List<ZipImportDetail__c> zips) {
   	Boolean okayToContinue = ZipInsertMethods.checkDistrict(zips);
   	if (okayToContinue) {
   	   List<Zip_Assignment__c> updateZas = new List<Zip_Assignment__c>();
   	   List<ZipImportDetail__c> checkZipDetailInsert = new List<ZipImportDetail__c>();
   	   List<Zip_Assignment__c> insertZas = new List<Zip_Assignment__c>();
         okayToContinue = ZipInsertMethods.findZipAssignments(zips, updateZas, checkZipDetailInsert, insertZas);
         if (okayToContinue) {
         	if (!updateZas.isEmpty()) {
               ZipAssignment.SKIP_TRIGGER=false;
               DmlHelper.performDML2(updateZas, DmlHelper.DML_UPDATE, 'ZipInsertBatch', 'processZips', 'Update Zip Assigns', false); 
         	} // if (!updateZas.isEmpty
         	
            if (!insertZas.isEmpty()) {
               ZipAssignment.SKIP_TRIGGER=false;
               DmlHelper.performDML2(insertZas, DmlHelper.DML_INSERT, 'ZipInsertBatch', 'processZips', 'Insert Zip Assigns', false); 
               
            } // if (!insertZas.isEmpty()
            
            if (!checkZipDetailInsert.isEmpty()) {
               for (ZipImportDetail__c zipDetail : checkZipDetailInsert) {
                  if (zipDetail.Zip_Assignment__r != null) {
                     zipDetail.Zip_Assignment__c = zipDetail.Zip_Assignment__r.Id;
                     zipDetail.Zip_Assignment__r = null;
                  }
               } // for (ZipImportDetail
            } // if (!checkZipDetailInsert.isEmpty()
            
         } // if (okayToContinue
   	} // if (okayToContinue
      
      addToTotal(zips);
      
      DmlHelper.performDML2(zips, DmlHelper.DML_UPDATE, 'ZipInsertBatch', 'processZips', 'Update ZipImportDetail__c', false); 
   } // processZips
   
   private void addToTotal(List<ZipImportDetail__c> zips) {
   	for (ZipImportDetail__c zipDetail : zips) {
   		zipImportIdSet.add(zipDetail.ZipImport__c);

         if (zipDetail.ZipTerritory__r != null) {
            zipDetail.ZipTerritory__c = zipDetail.ZipTerritory__r.Id;
            zipDetail.ZipTerritory__r = null;
         }

         if (zipDetail.ZipTerritory__c != null) {
            Integer nbrChanges = changeByDistrictMap.get(zipDetail.DistrictKey__c);
            if (nbrChanges == null) {
               nbrChanges = 1;
            } else {
               nbrChanges++;
            }
            changeByDistrictMap.put(zipDetail.DistrictKey__c,nbrChanges);
         } else {
            // if no territory, not successful
            numberNotSuccess++;
         }
   	} // for (ZipImportDetail__c
   } // addToTotal
   
   
   global void finish(Database.BatchableContext BC){
      ErrorLog.checkSave();
      
      // Get the ID of the AsyncApexJob representing this batch job
      String message = '\nTotal Changes Processed: '+numberZipInserts;
      message += '\nNumber Success: '+(numberZipInserts-numberNotSuccess);
      message += '\nNumber Failed: '+numberNotSuccess;
      
      /*
      message += ' \n\n Total Accounts updated='+totalChanges.Accounts_Updated__c;
      message += ' \n Total Contacts updated='+totalChanges.Contacts_Updated__c;
      message += ' \n Total Leads updated='+totalChanges.Leads_Updated__c;
      message += ' \n Total Referral Accounts updated='+totalChanges.Referral_Accounts_Updated__c;
      message += ' \n Total Referral Contacts updated='+totalChanges.Referral_Contacts_Updated__c+'\n';
      */

      for (String districtInfo : changeByDistrictMap.keySet()) {
         Integer nbrChanges = changeByDistrictMap.get(districtInfo);
            message += ' \n For '+districtInfo+', Nbr Changes: '+nbrChanges;
      } // for (String districtInfo

      message += '\n'+batchMsg;
      
      jh.completeJob(bc, 'Zip File Insert', message);

      ZipInsertMethods.processCompleteZipImports(zipImportIdSet);
   } // finish
    
   public static void launchBatch() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      if (abc != null && abc.Active__c) {
         //Integer batchSize = (abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 500);
         //Database.executeBatch(new ZipInsertBatch(), batchSize);
         JobHelper.launchBatchWithSchedule(new ZipInsertBatch(), CLASSNAME, Datetime.now(), 1);
      }

   } // launchBatch

} // class ZipInsertBatch