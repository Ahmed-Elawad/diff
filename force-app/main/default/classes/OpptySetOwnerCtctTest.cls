/* 
 * Test methods for OpptySetOwnerCtct
 *
 * History
 * -------
   01/29/2019 Dan Carmen       Created
   
 */
@isTest
private class OpptySetOwnerCtctTest {
   
   @testSetup
   public static void setupData() {
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createCustomSetting(null, 'OpptyBefore', true, false, new String[]{'OpptySetOwnerCtct'},setupClasses, TriggerMethods.INTERFACE_B);
      insert setupClasses;
      ContactFormatPaychexEmpsTest.checkSetupData();
   } // setupData

   static testMethod void testOpptyOwner() {

      Schema.RecordTypeInfo ctctSArt = RecordTypeHelper.getRecordType('Paychex Employee', ObjectHelper.OBJECT_CONTACT);
        
      Account payxSA = ContactFormatPaychexEmps.getParentAcct();
      
      User[] users = [Select Id, FirstName, LastName, HR_Person_Id__c, Email from User where IsActive=true and HR_Person_Id__c != null and Job_Name__c = :UserHelper.JOB_REP limit 3];
      User user1 = users[0];
      User user2 = users[1];
      User user3 = users[2];
      Contact empCtct1 = createCtct(user1,payxSA.Id,ctctSArt.getRecordTypeId());
      Contact empCtct2 = createCtct(user2,payxSA.Id,ctctSArt.getRecordTypeId());
      Contact empCtct3 = createCtct(user3,payxSA.Id,ctctSArt.getRecordTypeId());
      Contact[] empCtcts = new Contact[]{empCtct1,empCtct2,empCtct3};
      insert empCtcts;
      
      System.assertEquals(empCtcts.size(), [select count() from Contact where User_Lookup__c != null and id in :empCtcts]);
      
      Account acct1 = new Account(Name='Test Acct1'); 
      Account acct2 = new Account(Name='Test Acct2');
      Account[] accts = new Account[]{acct1,acct2};
      insert accts;
        
      Test.startTest();
      Opportunity opp1 = new Opportunity(Name='Opp1',AccountId=acct1.Id, OwnerId=user1.Id, CloseDate=Date.today().addDays(7), StageName='Pending');
      Opportunity opp2 = new Opportunity(Name='Opp2',AccountId=acct1.Id, OwnerId=user2.Id, CloseDate=Date.today().addDays(7), StageName='Pending');
      Opportunity[] opps = new Opportunity[]{opp1,opp2};
      insert opps;
      
      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, OwnerId, OwnerContact__c from Opportunity where Id in :opps]);
      
      System.assertEquals(empCtct1.Id, oppMap.get(opp1.Id).OwnerContact__c);
      System.assertEquals(empCtct2.Id, oppMap.get(opp2.Id).OwnerContact__c);
      
      opp1.OwnerId = user2.Id;
      opp2.OwnerId = user3.Id;
      update opps;
      
      oppMap = new Map<Id,Opportunity>([Select Id, OwnerId, OwnerContact__c from Opportunity where Id in :opps]);
      
      System.assertEquals(empCtct2.Id, oppMap.get(opp1.Id).OwnerContact__c);
      System.assertEquals(empCtct3.Id, oppMap.get(opp2.Id).OwnerContact__c);
      
   } // testOpptyOwner
   
   public static Contact createCtct(User usr, Id acctId, Id recordTypeId) {
      Contact ctct = new Contact(Firstname = usr.FirstName
                                ,Lastname = usr.LastName
                                ,recordtypeId = recordTypeId
                                ,HR_Person_Id__c = usr.HR_Person_Id__c
                                ,Email = usr.Email
                                ,AccountId=acctId
                                ,User_Lookup__c=usr.Id);
      return ctct;
   } // createCtct
   
} // class OpptySetOwnerCtctTest