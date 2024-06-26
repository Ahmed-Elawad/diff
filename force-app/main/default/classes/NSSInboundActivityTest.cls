/* 
 * Test methods for the NSS Inbound Activity controller
 *
 * History
 * -------
   04/02/2015 Dan Carmen            Created
   12/11/2018 Dan Carmen            Replace qbdialer__Call_Date_Time__c with CallDateTime__c

 */
@isTest
private class NSSInboundActivityTest {

   private static Id nssTaskRecordTypeId = TaskHelper.getNSSTaskRecordTypeId();

   static testMethod void testAsNSR() {
      User inboundNSR = ProspectOwnershipMethodsTest.getInboundNSRs(1)[0];
      Account acct1 = new Account(Name='Account 1');
      Account acct2 = new Account(Name='Account 2');
      Account acct3 = new Account(Name='Account 3');
      Account acct4 = new Account(Name='Account 4');
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      insert accts;
      
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='Last1');
      Contact ctct2 = new Contact(AccountId=acct2.Id, LastName='Last2');
      Contact ctct3 = new Contact(AccountId=acct3.Id, LastName='Last3');
      Contact ctct4 = new Contact(AccountId=acct3.Id, LastName='Last4');
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;

      Lead ld1 = new Lead(Company='Company 1', LastName='LeadLast1');
      Lead ld2 = new Lead(Company='Company 2', LastName='LeadLast2');
      Lead[] leads = new Lead[]{ld1,ld2};
      insert leads;
      
      LeadCallDisposition__c[] callDispositions = LeadMethodsTest.createLeadCallDispositions();
      
      // no records
      System.runAs(inboundNSR) {
         NSSInboundActivity nia = new NSSInboundActivity();
         System.assertEquals(false,nia.promptForUser);
         System.assertEquals(0,nia.displayList.size());
         System.assertEquals(false,nia.hasDisplayList);
      } // System.runAs

      // create the tasks
      Task[] tsks = new Task[]{};
      tsks.add(new Task(WhoId=ctct1.Id, ActivityDate=Date.today(), Status='Pending', OwnerId=inboundNSR.Id, CallDisposition=callDispositions[0].CallDisposition__c, RecordTypeId=nssTaskRecordTypeId));
      tsks.add(new Task(WhoId=ctct2.Id, ActivityDate=Date.today(), Status='Pending', OwnerId=inboundNSR.Id, CallDisposition=callDispositions[0].CallDisposition__c, RecordTypeId=nssTaskRecordTypeId));
      tsks.add(new Task(WhoId=ctct3.Id, ActivityDate=Date.today(), Status='Pending', OwnerId=inboundNSR.Id, CallDisposition=callDispositions[0].CallDisposition__c, RecordTypeId=nssTaskRecordTypeId));
      tsks.add(new Task(WhoId=ctct4.Id, ActivityDate=Date.today(), Status='Pending', OwnerId=inboundNSR.Id, CallDisposition=callDispositions[0].CallDisposition__c, RecordTypeId=nssTaskRecordTypeId));
      tsks.add(new Task(WhoId=ld1.Id, ActivityDate=Date.today(), Status='Pending', OwnerId=inboundNSR.Id, CallDisposition=callDispositions[0].CallDisposition__c, RecordTypeId=nssTaskRecordTypeId));
      tsks.add(new Task(WhoId=ld2.Id, ActivityDate=Date.today(), Status='Pending', OwnerId=inboundNSR.Id, CallDisposition=callDispositions[0].CallDisposition__c, RecordTypeId=nssTaskRecordTypeId));
      insert tsks;
     
      // no referrals - all tasks should come in the lst.
      System.runAs(inboundNSR) {
         NSSInboundActivity nia = new NSSInboundActivity();
         System.assertEquals(false,nia.promptForUser);
         System.assertEquals(6,nia.displayList.size());
         System.assertEquals(true,nia.hasDisplayList);
      } // System.runAs
      
      // add a couple of referrals
      Referral__c ref1 = new Referral__c(OwnerId=inboundNSR.Id, Account__c=acct1.Id);
      Referral__c ref2 = new Referral__c(OwnerId=inboundNSR.Id, Account__c=acct2.Id);
      Referral__c[] referrals = new Referral__c[]{ref1,ref2};
      insert referrals;
      
      // no referrals - all tasks should come in the lst.
      System.runAs(inboundNSR) {
         NSSInboundActivity nia = new NSSInboundActivity();
         nia.selectedDispositionFilter = callDispositions[0].CallDisposition__c;
         nia.queryData();
         System.assertEquals(false,nia.promptForUser);
         System.assertEquals(4,nia.displayList.size());
         System.assertEquals(true,nia.hasDisplayList);
      } // System.runAs

   } // testAsNSR
} // class NSSInboundActivityTest