/* 
 * Test methods for the ContactCheckType class
 *
 * History
 * -------
   01/28/2016 Dan Carmen      Created
   12/13/2017 Dan Carmen      Changed the Payroll Contact criteria
   07/18/2019 Dan Carmen      Add criteria for Business Owner

 */
@isTest
private class ContactCheckTypeTest {

   static testMethod void testCheckType() {
      Account acct = new Account(Name='Enterprise');
      insert acct;
      
      Contact ctct1 = new Contact(AccountId=acct.Id,LastName='Kirk');
      Contact ctct2 = new Contact(AccountId=acct.Id,LastName='Spock', Contact_Types__c='Live Long and Prosper');
      Contact ctct3 = new Contact(AccountId=acct.Id,LastName='McCoy', Contact_Types__c='Medical Payroll');
      Contact ctct4 = new Contact(AccountId=acct.Id,LastName='Sulu', Contact_Types__c='Payroll');
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;
      
      Map<Id, Contact> ctctMap = new Map<Id,Contact>([Select id, Name, PayrollContact__c, Contact_Types__c from Contact where Id in :ctcts]);
      System.assertEquals(false,ctctMap.get(ctct1.Id).PayrollContact__c);
      System.assertEquals(false,ctctMap.get(ctct2.Id).PayrollContact__c);
      System.assertEquals(true,ctctMap.get(ctct3.Id).PayrollContact__c);
      System.assertEquals(true,ctctMap.get(ctct4.Id).PayrollContact__c);
      
      ctctMap.get(ctct3.Id).Contact_Types__c='Medical;Payroll';
      ctctMap.get(ctct4.Id).Contact_Types__c='Navigation Payroll';
      // create new array since they were re-selected
      update ctctMap.values();
      
      ctctMap = new Map<Id,Contact>([Select id, Name, PayrollContact__c, Contact_Types__c from Contact where Id in :ctctMap.keySet()]);
      System.assertEquals(false,ctctMap.get(ctct1.Id).PayrollContact__c);
      System.assertEquals(false,ctctMap.get(ctct2.Id).PayrollContact__c);
      System.assertEquals(true,ctctMap.get(ctct3.Id).PayrollContact__c);
      System.assertEquals(true,ctctMap.get(ctct4.Id).PayrollContact__c);

   } // static testMethod
   
   static testMethod void testOtherAttributes() {
      Account acct = new Account(Name='Test Account');
      insert acct;
      
      Contact ctct = new Contact(LastName='Contact', AccountId=acct.Id, Referral_Type__c='Test Type');
      ctct.Title = 'Business Owner';
      ctct.Willing_to_Be_a_Reference_TAA__c = 'Yes';
      ctct.AICPA_Enrolled__c = 'Y';
      ctct.AKC_Registered__c = true;
      
      insert ctct;
      
      ctct = [Select Id, LastName, Title, Business_Owner__c
                    ,Willing_to_Be_a_Reference_TAA__c, TAA_Reference_Date__c
                    ,AICPA_Enrolled__c, AICPA_Enrolled_Date__c, AICPA_Original_Type__c
                    ,AKC_Registered__c, Date_AKC_Registered__c
                From Contact
               Where Id=:ctct.Id];
      System.assertEquals('Business Owner', ctct.Title);
      System.assertEquals(true, ctct.Business_Owner__c);
      System.assertEquals('Yes', ctct.Willing_to_Be_a_Reference_TAA__c);
      System.assertEquals(Date.today(), ctct.TAA_Reference_Date__c);
      System.assertEquals('Y', ctct.AICPA_Enrolled__c);
      System.assertEquals(Date.today(), ctct.AICPA_Enrolled_Date__c);
      System.assertEquals('Test Type', ctct.AICPA_Original_Type__c);
      System.assertEquals(true, ctct.AKC_Registered__c);
      System.assertEquals(Date.today(), ctct.Date_AKC_Registered__c);
   } // testOtherAttributes
   
} // class ContactCheckTypeTest