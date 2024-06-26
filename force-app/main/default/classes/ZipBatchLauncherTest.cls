/* Test methods for the ZipBatchLauncher class
   
  History
  -------
  08/04/2016 Dan Carmen   Created
  06/26/2019 Dan Carmen   Kill the existing batch jobs before launching new jobs
  
 */
@isTest
private class ZipBatchLauncherTest {

   private static void setupData() {
      // setup Batch controller
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='ZipBatchLauncher', Active__c=true, BatchSize__c=3);
      insert abc;
      // setup zip assignments and changes
      ZipCheckOwnerTest.setupZipsAndSegments(true);
   } // setupData
   
   static testMethod void testSalesOrgSplitting() {
      setupData();
      ZipBatchLauncher.USE_ZIPBATCH_KEY = false;
      ZipBatchLauncher zbl = new ZipBatchLauncher();
      zbl.runProcess();
   } // testSalesOrgSplitting
   
   static testMethod void testBatchKey() {
      ZipBatchLauncher.USE_ZIPBATCH_KEY = true;
      UserHelperTest.setupSalesOrgSetting();
      ZipBatchLauncher zbl = new ZipBatchLauncher();
      zbl.runProcess();
   } // testBatchKey
   
   static testMethod void testScheduler() {
      TestHelper.testScheduler('testZipBatchLauncher', new ZipBatchLauncher());
   } // testScheduler


} // class ZipBatchLauncherTest