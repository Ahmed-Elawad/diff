/*
* 
* 
* History
* -------
* 10/04/2022 Pujitha Madamanchi   Created
  11/15/2023 Pujitha Madamanchi   Added Contact
*/
@isTest
public  class ReferralZipMissingControllerTest {

    public static String LLC_NAME='WEBLEAD';

    static testMethod void testZipMissingLead() {
      Lead ld = new Lead();
      User userNsr = [Select Id, Name, NSS_Team__c from User where IsActive=true and NSS_Team__c='Inbound' and Job_Name__c=:UserHelper.JOB_NSR limit 1];
      System.runAs(userNsr) {   
        ld = new Lead(LastName='Test Lead', Company='Test Lead Company', Products__c='Prod1;Prod2;Prod3',OwnedBy__c=LLC_NAME
                            ,Current_Prior_Method__c='test');
        insert ld;
        
        Test.startTest();
          Test.SetCurrentPageReference(Page.Referral);
          System.CurrentPageReference().getParameters().put('Id',ld.Id);
          
          ReferralControllerSmall rcs = new ReferralControllerSmall();
          System.assertEquals(true, rcs.displayZip); 

          ReferralZipMissingController rzm = new ReferralZipMissingController();
          rzm.lead.PostalCode = '12345';
          rzm.save();
          rzm.cancel();       
        Test.stopTest();
      }
       Lead checkLead = [Select Id, PostalCode from Lead where Id=:ld.Id];
       System.assertEquals('12345', checkLead.PostalCode); 
    } // testZipMissingLead
    
    static testMethod void testZipMissingContact() {
      Contact ctct = new Contact();
        User userNsr = [Select Id, Name, NSS_Team__c from User where IsActive=true and NSS_Team__c='Inbound' and Job_Name__c=:UserHelper.JOB_NSR limit 1];
      System.runAs(userNsr) {   
        Account testAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60);
        insert testAccount;

        // create test contact
        ctct = new Contact(FirstName = 'Test Contact', LastName = 'Contact 1', AccountId = testAccount.Id, 
                                            DoNotCall = false, Email = 'c1a1@whoknows.com', HasOptedOutOfEmail = false);
        insert ctct;
        
        Test.startTest();
          Test.SetCurrentPageReference(Page.Referral);
          System.CurrentPageReference().getParameters().put('Id',ctct.Id);
          
          ReferralControllerSmall rcs = new ReferralControllerSmall();
          System.assertEquals(true, rcs.displayZip); 

          ReferralZipMissingController rzm = new ReferralZipMissingController();
          rzm.ctct.Account.ShippingPostalCode = '12345';
          rzm.save();
          rzm.cancel();       
        Test.stopTest();
      }
       Account acc = [Select Id, ShippingPostalCode from Account where Id=:ctct.AccountId];
       System.assertEquals('12345', acc.ShippingPostalCode); 
    } // testZipMissingContact

}