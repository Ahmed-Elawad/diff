/* 
 * The methods used for marking zip codes to be re-run.
 *
 * History
 * -------
 * 02/03/2010 Dan Carmen   Created
 * 10/18/2010 Dan Carmen   Added isSystemAdmin variable.
 * 10/22/2010 Dan Carmen   Added HNBF, option to select which ownership field to set.
   07/11/2011 Dan Carmen   Remove normalize options.
   12/23/2011 Dan Carmen   Commented out testRunBatch methods.
   06/22/2012 Dan Carmen   Added Run Add User Batch option.
   03/25/2013 Dan Carmen   Add Org Structure/Org Unit options
   04/04/2016 Dan Carmen   Added ability to setup the batch jobs in the custom settings.
   05/26/2016 Dan Carmen   Remove the extra batches from the code - rely on the custom settings
   08/03/2016 Dan Carmen   Changes for making it dynamic.
   08/13/2018 Dan Carmen   Change to run schedulable only classes
   08/17/2021 Dan Carmen   Pull out launchJob so it can be called separately
   11/09/2021 Dan Carmen   Fix for jobs launching twice

 */
@isTest
private class UpdateZipOwnershipControllerTest {

   @testSetup
   private static void setupData() {
      UserHelperTest.setupSalesOrgSetting();
   } // setupData

   static testMethod void testDefaultSettings() {
      UpdateZipOwnershipController uzoc = new UpdateZipOwnershipController();
      // check blank fields
      System.assertEquals('',uzoc.zip1);
      System.assertEquals('',uzoc.zip2);
      System.assertEquals(null,uzoc.za.User__c);
      System.assertEquals('',uzoc.getSearchMsg());
      System.assertEquals(false,uzoc.showSearchResults);
      System.assertEquals(0,uzoc.numberChanges);
      System.assertEquals(null,uzoc.getZips());
      // make sure default option is set
      System.assertEquals('Any',uzoc.ownershipOption);
      // make sure correct number of options is present
      System.assertEquals(true,uzoc.getOwnershipOptions().size() > 1);
      System.assertEquals(true,uzoc.showRunBatchBlock);
   } // testDefaultSettings
   
   /** Test with no search criteria.
    */
   static testMethod void testNoSearchCriteria() {
      System.debug('Start testNoSearchCriteria');
      UpdateZipOwnershipController uzoc = new UpdateZipOwnershipController();
      String resultPage = uzoc.searchZips().getUrl();
      System.assertEquals('/apex/updatezipownership',resultPage);
      System.assertEquals(true,ApexPages.hasMessages());    
      System.debug('End testNoSearchCriteria');
   } // testNoSearchCriteria

   /** Test a zip code value that is not a valid length.
    */
   static testMethod void testBadZipCode() {
      System.debug('Start testBadZipCode');
      UpdateZipOwnershipController uzoc = new UpdateZipOwnershipController();
      uzoc.zip1 = '123';
      String resultPage = uzoc.searchZips().getUrl();
      System.assertEquals('/apex/updatezipownership',resultPage);
      System.assertEquals(true,ApexPages.hasMessages());
      System.debug('End testBadZipCode');
   } // testBadZipCode

   /** Test a zip code value that is of a valid length, but does not exist.
    */
   static testMethod void testValidNotExists() {
      System.debug('Start testValidNotExists');
      UpdateZipOwnershipController uzoc = new UpdateZipOwnershipController();
      uzoc.zip1 = '00010';
      String resultPage = uzoc.searchZips().getUrl();
      System.assertEquals('/apex/updatezipownership',resultPage);
      System.assertEquals(true,ApexPages.hasMessages());
      System.debug('End testValidNotExists');
   } // testBadZipCode

   /** Test with one valid zip code.
    */
   static testMethod void testOneZip() {
      System.debug('Start testOneZip');
      
      // create zip objects to use in the search
      Zip_Assignment__c za1 = new Zip_Assignment__c(
                     Name='00011'
                    ,User__c=UserInfo.getUserId());
      insert za1;
      
      // test with one zip code
      UpdateZipOwnershipController uzoc = new UpdateZipOwnershipController();
      Boolean changesPending = uzoc.changesPending;
      System.debug('Start changesPending='+changesPending);
      uzoc.zip1 = za1.Name;
      //uzoc.ownershipOption = 'Any';
      String resultPage = uzoc.searchZips().getUrl();
      System.assertEquals('/apex/updatezipownership',resultPage);
      System.assertEquals(false,ApexPages.hasMessages());

      System.assertEquals('Search Criteria, Zip Code = 00011',uzoc.getSearchMsg().trim());
      System.assertEquals(true,uzoc.showSearchResults);
      System.assertEquals(1,uzoc.numberChanges);
      System.assertEquals(null,uzoc.getZips());
      System.assertEquals(false,uzoc.changesDisplayed);
      System.assertEquals('Click to Display the Zip Codes that were found',uzoc.getDisplayButtonTitle());
      uzoc.changeChangesDisplayed();
      System.assertEquals(true,uzoc.changesDisplayed);
      System.assertEquals('Click to Hide the Zip Codes that were found',uzoc.getDisplayButtonTitle());
      System.assertEquals(1,uzoc.getZips().size());
      
      resultPage = uzoc.saveChanges().getUrl();
      System.assertEquals('/apex/updatezipownership',resultPage);
      System.assertEquals(true,ApexPages.hasMessages());
      System.assertEquals(false,uzoc.showSearchResults);

      System.assertEquals(false,uzoc.showJobInfo);
      uzoc.selectedBatchOption = 'Update Ownership';
      resultPage = uzoc.runBatchJob().getUrl();
      System.assertEquals('/apex/updatezipownership',resultPage);
      System.assertEquals(true,uzoc.showJobInfo);

      System.debug('End testOneZip');
   } // testOneZip
   
   /** Test with one valid zip code - setting only zip2.
    */
   static testMethod void testOneZip2() {
      System.debug('Start testOneZip2');
      
      // create zip objects to use in the search
      Zip_Assignment__c za1 = new Zip_Assignment__c(
                     Name='00011'
                    ,User__c=UserInfo.getUserId());
      insert za1;
      
      // test with one zip code
      UpdateZipOwnershipController uzoc = new UpdateZipOwnershipController();
      Boolean changesPending = uzoc.changesPending;
      System.debug('Start changesPending='+changesPending);
      uzoc.zip2 = za1.Name;
      String resultPage = uzoc.searchZips().getUrl();
      System.assertEquals('/apex/updatezipownership',resultPage);
      System.assertEquals(false,ApexPages.hasMessages());

      System.debug('End testOneZip2');
   } // testOneZip2
   
   /** Test with two valid zip codes and a name.
    */
   static testMethod void testTwoZips() {
      System.debug('Start testTwoZips');
      
      // create zip objects to use in the search
      Zip_Assignment__c za1 = new Zip_Assignment__c(
                     Name='00011'
                    ,User__c=UserInfo.getUserId());
      insert za1;
      Zip_Assignment__c za2 = new Zip_Assignment__c(
                     Name='00012'
                    ,User__c=UserInfo.getUserId());
      insert za2;
      
      // test with two zip codes and a name
      UpdateZipOwnershipController uzoc = new UpdateZipOwnershipController();
      uzoc.zip1 = za1.Name;
      uzoc.zip2 = za2.Name;
      uzoc.za.User__c = UserInfo.getUserId();
      String resultPage = uzoc.searchZips().getUrl();
      System.assertEquals('/apex/updatezipownership',resultPage);
      System.assertEquals(false,ApexPages.hasMessages());

      System.debug('End testTwoZips');
      
   } // testTwoZips
   
   /** Test with two valid zip codes and a name.
    */
   static testMethod void testBulkData() {
      System.debug('Start testBulkData');
      // create zips
      List<Zip_Assignment__c> zas = new List<Zip_Assignment__c>();
      for (Integer i=100; i<110; i++) {
         Zip_Assignment__c za = new Zip_Assignment__c(
                     Name='00'+i
                    ,User__c=UserInfo.getUserId());
         zas.add(za);
      } // for
      insert zas;
      
      Test.startTest();
      // test with two zip codes and a name
      UpdateZipOwnershipController uzoc = new UpdateZipOwnershipController();
      uzoc.setMaxRows(10);
      uzoc.zip1 = '00100';
      uzoc.zip2 = '00110';
      uzoc.za.User__c = UserInfo.getUserId();
      String resultPage = uzoc.searchZips().getUrl();
      System.assertEquals('/apex/updatezipownership',resultPage);
      System.assertEquals(true,ApexPages.hasMessages());
      Test.stopTest();
      
      System.debug('End testBulkData');
   } //  testBulkData
   
   static testMethod void testBatchOptions() {
      UpdateZipOwnershipController uzoc = new UpdateZipOwnershipController();
      List<SelectOption> options = uzoc.getBatchOptions();
      // check how many batch options
      System.assertEquals(true,(options.size() >= 1));
      // make sure the options are correct.
      System.assertEquals('Update Ownership',options.get(0).getValue());

   } // testBatchOptions
   
   static testMethod void testBatchOptionsFromCustomSettings() {
      Apex_Batch_Control__c abc1 = new Apex_Batch_Control__c(Name='ZipBatch', BatchSize__c=1, BatchTitle__c='Update Ownership', Active__c=true);
      insert abc1;
      
      UpdateZipOwnershipController uzoc = new UpdateZipOwnershipController();
      List<SelectOption> options = uzoc.getBatchOptions();
      // check how many batch options
      System.assertEquals(1,(options.size()));
      // make sure the options are correct.
      System.assertEquals('ZipBatch',options.get(0).getValue());
      
      uzoc.selectedBatchOption = abc1.Name;
      Test.startTest();
      uzoc.runBatchJob();
      Test.stopTest();

   } // testBatchOptionsFromCustomSettings
   
   static testMethod void testBatchOptionsFromCustomSettings2() {
      Apex_Batch_Control__c abc1 = new Apex_Batch_Control__c(Name='ZipBatch', BatchSize__c=1, BatchTitle__c='Update Ownership', Active__c=true);
      insert abc1;
      
      UpdateZipOwnershipController uzoc = new UpdateZipOwnershipController();
      List<SelectOption> options = uzoc.getBatchOptions();
      // check how many batch options
      System.assertEquals(1,(options.size()));
      // make sure the options are correct.
      System.assertEquals('ZipBatch',options.get(0).getValue());
      
      uzoc.selectedBatchOption = abc1.Name;
      Test.startTest();
      uzoc.launchJob(abc1);
      Test.stopTest();

   } // testBatchOptionsFromCustomSettings
   
} // UpdateZipOwnershipControllerTest