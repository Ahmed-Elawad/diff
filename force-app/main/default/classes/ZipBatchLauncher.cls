/* Checks how to launch the zip batch process
   
  History
  -------
  08/03/2016 Dan Carmen   Created
  06/26/2019 Dan Carmen   Kill the existing batch jobs before launching new jobs
  
 */
global without sharing class ZipBatchLauncher implements Schedulable {

   global ZipBatchLauncher() {
      
   }

   global void execute(SchedulableContext SC) {
      runProcess();
   } // execute
   
   public static Boolean USE_ZIPBATCH_KEY = Label.ZipBatch_UseKey == 'Y';
   
   global void runProcess() {
      // default to 2 batches unless says otherwise.
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('ZipBatchLauncher');
      Integer nbrBatches = (abc != null && abc.BatchSize__c != null ? (Integer)abc.BatchSize__c : 2);
      String[] salesOrgStrings = new String[]{};
      if (USE_ZIPBATCH_KEY) {
         salesOrgStrings = getSalesOrgStrings();
      } else {
      
         for (Integer cnt=0; cnt<nbrBatches; cnt++) {
            salesOrgStrings.add('');
         } // for
         if (nbrBatches > 1) {
            // look for pending changes - we don't need to do this if there's only 1 batch.
            findPendingChanges(salesOrgStrings);
         }
      } // if (USE_ZIPBATCH_KEY
      System.debug('execute USE_ZIPBATCH_KEY='+USE_ZIPBATCH_KEY+' nbrBatches='+nbrBatches+' salesOrgStrings='+salesOrgStrings);
      
      Integer nbrAborted=0;
      // if ZipBatch is currently running, kill the existing processes so we start fresh
      for (AsyncApexJob aaj : [Select id 
              from AsyncApexJob
             Where ApexClass.Name = 'ZipBatch'
               and Status='Processing'
               and JobType='BatchApex']) {
         if (!Test.isRunningTest()) {
            System.AbortJob(aaj.Id);
         }
         nbrAborted++;
      }
      
      System.debug('execute nbrAborted='+nbrAborted);
      // group by sales org
      // launch 1 or more ZipBatch instances with specific sales orgs
      for (String salesOrgStr : salesOrgStrings) {
         System.debug('ZipBatchLauncher salesOrgStr='+salesOrgStr);
         if (!Test.isRunningTest()) {
            database.executeBatch(new ZipBatch(salesOrgStr), 1);
         }
      }
   } // runProcess
   
   public String[] getSalesOrgStrings() {
      Map<String,String> byKeyMap = new Map<String,String>();
      for (SalesOrg__c salesOrg : SalesOrg__c.getAll().values()) {
         if (salesOrg.HasOwnership__c && String.isNotBlank(salesOrg.ZipBatchKey__c)) {
            String salesOrgStr = (byKeyMap.containsKey(salesOrg.ZipBatchKey__c) ? byKeyMap.get(salesOrg.ZipBatchKey__c)+';' : '') + salesOrg.Name;
            byKeyMap.put(salesOrg.ZipBatchKey__c, salesOrgStr);
         }
      } // for (SalesOrg__c salesOrg
      return byKeyMap.values();
   } // getSalesOrgStrings
   
   global void findPendingChanges(String[] salesOrgStrings) {
      List<AggregateResult> zipResults = new List<AggregateResult>( 
                      [select COUNT(Id) cnt,Zip_Assignment__r.Sales_Org__c salesOrg 
                         from Zip_Assignment_Change__c
                        where Processed__c = false
                          AND Zip_Assignment__r.ZipOkay__c = true
                          AND Zip_Assignment__r.Zip_Segment__c != null
                        group by Zip_Assignment__r.Sales_Org__c
                          order by count(Id) desc ]);
      Integer arrayCounter = 0;
      for (AggregateResult result : zipResults) {
         System.debug('findPendingChanges arrayCounter='+arrayCounter+' result='+result);
         if (String.isNotBlank(salesOrgStrings[arrayCounter])) {
            salesOrgStrings[arrayCounter] += ';';
         }
         salesOrgStrings[arrayCounter] += (String)result.get('salesOrg');
         arrayCounter++;
         if (arrayCounter >= salesOrgStrings.size()) {
            arrayCounter = 0;
         }
      } // for (Integer cnt=0
   } // findPendingChanges
} // class ZipBatchLauncher