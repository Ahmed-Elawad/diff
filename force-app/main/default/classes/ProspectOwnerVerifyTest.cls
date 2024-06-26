/* Test methods for the ProspectOwnerVerify class
   
   History
   -------
   09/09/2014 Dan Carmen   Created
   03/18/2016 Dan Carmen   Better handle ended records
   04/26/2017 Cindy Freeman		Add checks for VerifyCount and VerifyNeeded
 */
@isTest
private class ProspectOwnerVerifyTest {

   static testMethod void testBatch() {
      // create the account and contact, set up the life of lead settings.
      ProspectOwnershipTest.setupAcctCtct();
      ProspectOwnershipTest.acct.AssignedToOutboundNSR__c = true;
      update ProspectOwnershipTest.acct;

      Lead ld1 = new Lead(LastName='TestLast',Company='Test Company', PostalCode='12345');
      insert ld1;
      Map<Id,Lead> leadMap = ReferralQueries.selectLeadMap(new Id[]{ld1.Id}, null);
      ld1 = leadMap.get(ld1.Id);
      
      User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(2);
      Prospect_Ownership__c po1 = new Prospect_Ownership__c(Prospect_Client__c=ProspectOwnershipTest.acct.Id
                                                           ,Decision_Maker__c=ProspectOwnershipTest.ctct.Id
                                                           ,NSR_Name__c=outboundNSRs[0].Id
                                                           ,StartDate__c=Date.today().addDays(-30)
                                                           ,CommissionStart__c=Date.today().addDays(-30)
                                                           ,CommissionEnd__c=Date.today().addDays(90)
                                                           ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                                           ,NSS_Team__c=UserHelper.SO_CORE
                                                           ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_LOCKOUT
                                                           ,LockoutStart__c=Date.today()
                                                           );
      Prospect_Ownership__c po2 = new Prospect_Ownership__c(Lead__c=ld1.Id, Lead_Company__c=ld1.Lead_Company__c
                                                           ,NSR_Name__c=outboundNSRs[0].Id
                                                           ,StartDate__c=Date.today().addDays(-30)
                                                           ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                                           ,NSS_Team__c=UserHelper.SO_CORE
                                                           ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                                           ,ProspectingStart__c=Date.today().addDays(-30)
                                                           );
      Prospect_Ownership__c po3 = new Prospect_Ownership__c(Prospect_Client__c=ProspectOwnershipTest.acct.Id
                                                           ,Decision_Maker__c=ProspectOwnershipTest.ctct.Id
                                                           ,NSR_Name__c=outboundNSRs[0].Id
                                                           ,StartDate__c=Date.today().addDays(-30)
                                                           ,EndDate__c=Date.today()
                                                           ,CommissionStart__c=Date.today().addDays(-30)
                                                           ,CommissionEnd__c=Date.today().addDays(90)
                                                           ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                                           ,NSS_Team__c=UserHelper.SO_CORE
                                                           ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_EXPIRED
                                                           );
      Prospect_Ownership__c po4 = new Prospect_Ownership__c(Lead__c=ld1.Id, Lead_Company__c=ld1.Lead_Company__c
                                                           ,NSR_Name__c=outboundNSRs[0].Id
                                                           ,StartDate__c=Date.today().addDays(-30)
                                                           ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                                           ,NSS_Team__c=UserHelper.SO_CORE
                                                           ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_EXPIRED
                                                           ,EndDate__c=Date.today().addDays(-5)
                                                           ,LastVerified__c=Datetime.now().addDays(-5)
                                                           ,EndDateVerified__c=true
                                                           ,VerifyCount__c=2
                                                           );
      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{po1,po2,po3,po4};
      insert pos;
      
      // create an opportunity
      Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
      Opportunity opp1 = new Opportunity(Name='Test OppType1', AccountId=ProspectOwnershipTest.acct.Id, RecordTypeId=rtCore.getRecordTypeId(), CloseDate=Date.today().addDays(14), StageName='Pending');
      insert opp1;

      Test.startTest();
      Database.executeBatch(new ProspectOwnerVerify(), ProspectOwnerVerify.BATCH_SIZE);
      Test.stopTest();
      
      po1 = [Select Id, LastVerified__c,VerifyCount__c  from Prospect_Ownership__c where Id=:po1.Id];
      System.assertEquals(Date.today(), po1.LastVerified__c.date());

      po2 = [Select Id, LastVerified__c from Prospect_Ownership__c where Id=:po2.Id];
      System.assertEquals(Date.today(), po2.LastVerified__c.date());
      
      po3 = [Select Id, EndDate__c, EndDateVerified__c, LastVerified__c,VerifyCount__c  from Prospect_Ownership__c where Id=:po3.Id];
      System.assertEquals(Date.today(), po3.LastVerified__c.date());
      System.assertEquals(Date.today(), po3.EndDate__c);
      System.assertEquals(true, po3.EndDateVerified__c);

      // this one shouldn't change
      po4 = [Select Id, EndDate__c, EndDateVerified__c, LastVerified__c,VerifyCount__c, VerifyNeeded__c  from Prospect_Ownership__c where Id=:po4.Id];
      System.assertEquals(Date.today().addDays(-5), po4.LastVerified__c.date());
      //System.assertEquals(Date.today(), po4.LastVerified__c.date());
      System.assertEquals(false, po4.VerifyNeeded__c);
      System.assertEquals(2, po4.VerifyCount__c);
      System.assertEquals(true, po4.EndDateVerified__c);

      Account acct = [Select Id, Name, AssignedToOutboundNSR__c from Account where Id=:ProspectOwnershipTest.acct.Id];
      System.assertEquals(true,acct.AssignedToOutboundNSR__c);
   } // testBatch

   // Test the scheduler for the batch process.
   static testMethod void testSchedule() {
      ProspectOwnerVerify pov = new ProspectOwnerVerify();
      TestHelper.testScheduler('ProspectOwnerVerify', pov);
   } // testSchedule

   // test for Account expired
   static testMethod void testAccount() {
   	   // create the account and contact, set up the life of lead settings.
      ProspectOwnershipTest.setupAcctCtct();
      ProspectOwnershipTest.acct.AssignedToOutboundNSR__c = true;
      update ProspectOwnershipTest.acct;
   	  
   	  User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(2);
      Prospect_Ownership__c po1 = new Prospect_Ownership__c(Prospect_Client__c=ProspectOwnershipTest.acct.Id
                                                           ,Decision_Maker__c=ProspectOwnershipTest.ctct.Id
                                                           ,NSR_Name__c=outboundNSRs[0].Id
                                                           ,StartDate__c=Date.today().addDays(-30)
                                                           ,CommissionStart__c=Date.today().addDays(-30)
                                                           ,CommissionEnd__c=Date.today().addDays(90)
                                                           ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                                           ,NSS_Team__c=UserHelper.SO_CORE
                                                           ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_EXPIRED
                                                           ,EndDate__c=Date.today().addDays(-5)
                                                           ,ProspectingStart__c=Date.today().addDays(-15)
                                                           );
	  insert po1;
	  
	  Test.startTest();
      Database.executeBatch(new ProspectOwnerVerify(), ProspectOwnerVerify.BATCH_SIZE);
      Test.stopTest();
      
      po1 = [Select Id, LastVerified__c,VerifyCount__c, VerifyNeeded__c from Prospect_Ownership__c where Id=:po1.Id];
      System.assertEquals(Date.today(), po1.LastVerified__c.date());  
      System.assertEquals(true, po1.VerifyNeeded__c);
      System.assertEquals(1, po1.VerifyCount__c);                                                           
	      
	  Account testAcct = [select Id, AssignedToNSR__c from Account where Id = :ProspectOwnershipTest.acct.Id];
	  System.assertEquals(false, testAcct.AssignedToNSR__c);
	  	  
   } // testAccount

} // class ProspectOwnerVerifyTest