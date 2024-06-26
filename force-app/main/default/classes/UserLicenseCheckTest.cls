/* Test Methods for the UserLicenseCheck class

   
  History
  -------
  12/04/2017 Dan Carmen      Created
  04/05/2018 Dan Carmen      Modify format of output file.
  
 */
@isTest
private class UserLicenseCheckTest {

   static testMethod void testSuccess() {
      UserLicenseCheck.READ_ONLY_PROFILES = new String[]{'Read Only','Read Only - Contract'};
      UserLicenseCheck.NBR_READ_ONLY = 5;
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='UserLicenseCheck', Active__c=true, AdditionalEmails__c='test@test.com' );
      insert abc;
      
      Test.startTest();
      UserLicenseCheck ulc = new UserLicenseCheck();
      ulc.execute(null);
      Test.stopTest();
    } // testSuccess

   static testMethod void testFailure() {
      UserLicenseCheck.READ_ONLY_PROFILES = new String[]{'Read Only','Read Only - Contract'};
      UserLicenseCheck.NBR_READ_ONLY = 5000;
      Test.startTest();
      Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[]{};
      String[] processMsgs = new String[]{};
      UserLicenseCheck ulc = new UserLicenseCheck();
      ulc.handleProcessCheck(null, null, emails, processMsgs);
      Test.stopTest();
    } // testFailure
   
} // class UserLicenseCheckTest