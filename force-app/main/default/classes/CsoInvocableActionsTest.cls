/* 
   Test class for CsoInvocableActions

   
  History
  -------
  10/12/2022 Dan Carmen        Created

 */
@isTest
public class CsoInvocableActionsTest {
   static testMethod void testResendUserRegistration() {
       FlexNewClientOnboardingControllerTest.testSetupMethod();
       Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name=CsoInvocableActions.CLASSNAME, Active__c=true);
       insert abc;
       Account acct = new Account(Name='Ice Cream');
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert acct;
       Contact ctct = new Contact(AccountId=acct.Id, FirstName='Ben', LastName='Jerry', MobilePhone='(585) 867-5309', Email='benjerry@icecream.com', FlexUEID__c='benjerryicecream');
       insert ctct;
       Opportunity opp = new Opportunity(AccountId=acct.Id, Name='Test Opp', CloseDate=Date.today().addDays(7), StageName='Pending');
       insert opp;
       CSO_Tracking__c cso = new CSO_Tracking__c(Opportunity__c=opp.Id, AccountId__c=acct.Id, Contact__c=ctct.Id);
       insert cso;
       Test.startTest();
       Test.setMock(HttpCalloutMock.class, new FlexNewClientOnboardingMock(true));
       CsoInvocableActions.resendUserRegistration(new Contact[]{ctct});
       Test.stopTest();
       
       cso = [Select Id, UserRegistrationResent__c, UserRegistrationResentDate__c, ProcessNotes__c from CSO_Tracking__c where AccountId__c=:acct.Id];
       System.assertEquals(1, cso.UserRegistrationResent__c);
       System.assertNotEquals(null, cso.UserRegistrationResentDate__c);
       System.assertEquals(true, cso.ProcessNotes__c.contains('Resent User Registration '), cso.ProcessNotes__c);
       
   } // testResendUserRegistration
    
} // class CsoInvocableActionsTest