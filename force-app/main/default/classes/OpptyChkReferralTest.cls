/* 
   Test methods for OpptyChkReferral class and OpptyCheckReferral trigger 
   
  History
  -------
  06/30/2010 Dan Carmen   Created - moved test methods from OpptyCheckReferral class
  09/13/2011 Dan Carmen   Added logic to populate the Referral Account field on the Opportunity.
  07/19/2018 Jake Hinds    changing insert method to use bank since the update tests cpa
  09/20/2018 Jake Hinds   Updating insert method to match new credit card logic
  03/19/2019 Dan Carmen   Add logic to set other types of referral sources
  01/15/2020 Cindy Freeman	add test for bank referrals 
 */
@isTest
private class OpptyChkReferralTest {
   
   @testSetup
   public static void setupData() {
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createCustomSetting('LeadAfter', false, true, new String[]{'OpptyChkReferral'},setupClasses, TriggerMethods.INTERFACE_B);
      TriggerMethodsTest.createCustomSetting('OpptyAfter', false, true, new String[]{'OpptyChkReferral'},setupClasses, TriggerMethods.INTERFACE_B);
      insert setupClasses;

      LeadSourceHelperTest.setupData();
      
      Account a1 = new Account(name='Test 1',CPA_Name_Ref__c=null,ownerId=UserInfo.getUserId());
      insert a1;
      Referral_Account__c ra = new Referral_Account__c(name='Test Ref Acct');
      insert ra;
      Referral_Contact__c r1 = new Referral_Contact__c(name='Test1',Referral_Id__c='Dan1', Referral_Account__c=ra.Id);
      Referral_Contact__c r2 = new Referral_Contact__c(name='Test2',Referral_Id__c='Dan2', Referral_Account__c=ra.Id);
      Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{r1,r2};
      insert refCtcts;
   } // setupData
   
   public static Account getTestAcct() {
      Account acct = [select Id, name, CPA_Name_Ref__c, Broker_Name_Ref__c, Banker_Name_Ref__c, Referral_National_Account__c from Account where Name='Test 1'];
      return acct;
   } // getTestAcct
   
   public static Referral_Account__c getTestRefAcct() {
      Referral_Account__c refAcct = [Select Id, Name, RecordTypeId from Referral_Account__c where Name='Test Ref Acct'];
      return refAcct;
   } // getTestRefAcct
   
   public static Referral_Contact__c getTestRefCtct(String name) {
      Referral_Contact__c refCtct = [Select Id, Name, Referral_Account__c, Referral_Account__r.Name from Referral_Contact__c where Name=:name and Referral_Account__r.Name='Test Ref Acct'];
      return refCtct;
   } // getTestRefCtct
/*
   public static testmethod void testCheckOpptysInsert() {
      LeadSource__c ls = LeadSourceHelperTest.getLeadSourceByCategory(Label.LeadSourceCat_Bank);
      System.assertNotEquals(null,ls,'Could not find a LeadSource__c for '+Label.LeadSourceCat_Bank);
      
      Account a1 = getTestAcct();
      System.assert(a1.Banker_Name_Ref__c == null,'The Banker Full Name is not null!');
      Referral_Account__c ra = getTestRefAcct();
      Referral_Contact__c r1 = getTestRefCtct('Test1');
      Referral_Contact__c r2 = getTestRefCtct('Test2');
      
      Opportunity o1 = new Opportunity(accountId=a1.Id,name='Test 1 oppty',LeadSource=ls.Name,StageName='Pending',CloseDate=System.Today(),Referral_Contact__c=r1.Id);
      Test.startTest();
      insert o1;
      Test.stopTest();
      System.assertEquals(o1.Referral_Contact__c,r1.Id);
      a1 = [Select a.name, a.CPA_Name_Ref__c, a.Broker_Name_Ref__c, a.Banker_Name_Ref__c,a.Credit_Card_Sensitivity__c From Account a where Id = :o1.accountId];
      // check that referral gets changed on Opportunity insert
      System.assertEquals(true,a1.Credit_Card_Sensitivity__c);
      // check that the referral account gets set on the opportunity
      o1 = [Select Id, Referral_Contact__c,Referral_Contact__r.Sensitivity_Credit_Card_Processing__c, Referral_Account__c from Opportunity where Id=:o1.Id];
      System.assertEquals(ra.Id,o1.Referral_Account__c);
      System.assertEquals(true,o1.Referral_Contact__r.Sensitivity_Credit_Card_Processing__c);
       
   } // testCheckOpptysInsert
   public static testmethod void testCheckOpptysUpdate1() {
      LeadSource__c ls = LeadSourceHelperTest.getLeadSourceByCategory(Label.LeadSourceCat_CPA);
      System.assertNotEquals(null,ls,'Could not find a LeadSource__c for '+Label.LeadSourceCat_CPA);
      System.debug('testCheckOpptysUpdate1 ls='+ls);

      Account a1 = getTestAcct();
      System.assert(a1.CPA_Name_Ref__c == null,'The CPA Name is not null!');
      Referral_Account__c ra = getTestRefAcct();
      Referral_Contact__c r1 = getTestRefCtct('Test1');
      Referral_Contact__c r2 = getTestRefCtct('Test2');

      Opportunity o1 = new Opportunity(accountId=a1.Id,name='Test 1 oppty',LeadSource='Cold Call',StageName='Pending',CloseDate=System.Today(),Referral_Contact__c=r1.Id);
      insert o1;
      System.assertEquals(o1.Referral_Contact__c,r1.Id);
      a1 = [Select a.name, a.CPA_Name_Ref__c, a.Broker_Name_Ref__c, a.Banker_Name_Ref__c From Account a where Id = :o1.accountId];
      // check that referral gets changed on Opportunity insert
      System.assertEquals(null,a1.CPA_Name_Ref__c);
      o1.Referral_Contact__c = r2.Id;
      o1.LeadSource = ls.Name;
      OpptyChkReferral.ALREADY_RAN_SET.clear();
      Test.startTest();
      update o1;
      Test.stopTest();
      a1 = [Select a.name, a.CPA_Name_Ref__c, a.Broker_Name_Ref__c, a.Banker_Name_Ref__c From Account a where Id = :o1.accountId];
      // check that referral gets changed on Opportunity update
      System.assertEquals(r2.Id,a1.CPA_Name_Ref__c);
      // check that the referral account gets set on the opportunity
      o1 = [Select Id, Referral_Contact__c, Referral_Account__c from Opportunity where Id=:o1.Id];
      System.assertEquals(ra.Id,o1.Referral_Account__c);
   } // testCheckOpptysUpdate

   public static testmethod void testCheckOpptysUpdate2() {
      LeadSource__c ls = LeadSourceHelperTest.getLeadSourceByCategory(Label.LeadSourceCat_CPA);
      System.assertNotEquals(null,ls,'Could not find a LeadSource__c for '+Label.LeadSourceCat_CPA);

      Account a1 = getTestAcct();
      System.assert(a1.CPA_Name_Ref__c == null,'The CPA Name is not null!');
      Referral_Account__c ra = getTestRefAcct();
      Referral_Contact__c r1 = getTestRefCtct('Test1');
      Referral_Contact__c r2 = getTestRefCtct('Test2');

      Opportunity o1 = new Opportunity(accountId=a1.Id,name='Test 1 oppty',LeadSource='Cold Call',StageName='Pending',CloseDate=System.Today(),Referral_Contact__c=r1.Id);
      insert o1;
      System.assertEquals(o1.Referral_Contact__c,r1.Id);
      a1 = [Select a.name, a.CPA_Name_Ref__c, a.Broker_Name_Ref__c, a.Banker_Name_Ref__c From Account a where Id = :o1.accountId];
      // check that referral gets changed on Opportunity insert
      System.assertEquals(null,a1.CPA_Name_Ref__c);
      o1.Referral_Contact__c = r2.Id;
      OpptyChkReferral.ALREADY_RAN_SET.clear();
      update o1;
      a1 = [Select a.name, a.CPA_Name_Ref__c, a.Broker_Name_Ref__c, a.Banker_Name_Ref__c From Account a where Id = :o1.accountId];
      // check that referral gets changed on Opportunity update
      System.assertEquals(null,a1.CPA_Name_Ref__c);
      // check that referral does not change with different call type and update
      o1.LeadSource = ls.Name;
      o1.Referral_Contact__c = r1.Id;
      OpptyChkReferral.ALREADY_RAN_SET.clear();
      Test.startTest();
      update o1;
      Test.stopTest();
      a1 = [Select a.name, a.CPA_Name_Ref__c, a.Broker_Name_Ref__c, a.Banker_Name_Ref__c From Account a where Id = :o1.accountId];
      // check that referral does not gets changed on Opportunity update (since call type is different).
      System.assertEquals(r1.Id,a1.CPA_Name_Ref__c);
      // check that the referral account gets set on the opportunity
      o1 = [Select Id, Referral_Contact__c, Referral_Account__c from Opportunity where Id=:o1.Id];
      System.assertEquals(ra.Id,o1.Referral_Account__c);
   } // testCheckOpptysUpdate2

   public static testmethod void testStrategicAcct() {
      LeadSource__c ls = LeadSourceHelperTest.getLeadSourceByCategory(Label.LeadSourceCat_Strategic);
      System.assertNotEquals(null,ls,'Could not find a LeadSource__c for '+Label.LeadSourceCat_Strategic);

      Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType('Sales Channel Referral Account Record Type', 'Referral_Account__c'); 
      
      Account a1 = getTestAcct();
      System.assert(a1.CPA_Name_Ref__c == null,'The CPA Name is not null!');

      Referral_Account__c ra = getTestRefAcct();
      ra.RecordTypeId = rtInfo.getRecordTypeId();
      update ra;
      Referral_Contact__c r1 = getTestRefCtct('Test1');
      Referral_Contact__c r2 = getTestRefCtct('Test2');

      Opportunity o1 = new Opportunity(accountId=a1.Id,name='Test 1 oppty',LeadSource='Cold Call',StageName='Pending',CloseDate=System.Today(),Referral_Contact__c=r1.Id);
      insert o1;
      System.assertEquals(o1.Referral_Contact__c,r1.Id);
      a1 = getTestAcct();
      // check that referral gets changed on Opportunity insert
      System.assertEquals(null,a1.Referral_National_Account__c);
      OpptyChkReferral.ALREADY_RAN_SET.clear();
      o1.Referral_Account__c = null;
      update o1;
      a1 = getTestAcct();
      // check that referral gets changed on Opportunity update
      System.assertEquals(null,a1.Referral_National_Account__c);
      // check that referral does not change with different call type and update
      o1.LeadSource = ls.Name;
      o1.Referral_Account__c = ra.Id;
      OpptyChkReferral.ALREADY_RAN_SET.clear();
      Test.startTest();
      update o1;
      Test.stopTest();
      a1 = getTestAcct();
      // check that referral does not gets changed on Opportunity update (since call type is different).
      System.assertEquals(ra.Id,a1.Referral_National_Account__c);
   } // testStrategicAcct
   
   public static testmethod void testBroker() {
      LeadSource__c ls = LeadSourceHelperTest.getLeadSourceByCategory(Label.LeadSourceCat_FinAdv);
      System.assertNotEquals(null,ls,'Could not find a LeadSource__c for '+Label.LeadSourceCat_FinAdv);

      Account a1 = getTestAcct();
      System.assert(a1.CPA_Name_Ref__c == null,'The CPA Name is not null!');
      Referral_Account__c ra = getTestRefAcct();
      Referral_Contact__c r1 = getTestRefCtct('Test1');
      Referral_Contact__c r2 = getTestRefCtct('Test2');

      Opportunity o1 = new Opportunity(accountId=a1.Id,name='Test 1 oppty',LeadSource=ls.Name,StageName='Pending',CloseDate=System.Today(),Referral_Contact__c=r1.Id);
      Test.startTest();
      insert o1;
      Test.stopTest();
      a1 = getTestAcct();
      // check that referral gets changed on Opportunity insert
      System.assertEquals(r1.Id,a1.Broker_Name_Ref__c);
   } // testBroker

   public static testmethod void testBanker() {
      LeadSource__c ls = LeadSourceHelperTest.getLeadSourceByCategory(Label.LeadSourceCat_Bank);
      System.assertNotEquals(null,ls,'Could not find a LeadSource__c for '+Label.LeadSourceCat_Bank);

      Account a1 = getTestAcct();
      System.assert(a1.Banker_Name_Ref__c == null,'The Banker Name is not null!');
      Referral_Account__c ra = getTestRefAcct();
      Referral_Contact__c r1 = getTestRefCtct('Test1');
      Referral_Contact__c r2 = getTestRefCtct('Test2');

      Opportunity o1 = new Opportunity(accountId=a1.Id,name='Test 1 oppty',LeadSource=ls.Name,StageName='Pending',CloseDate=System.Today(),Referral_Contact__c=r1.Id);
      Test.startTest();
      insert o1;
      Test.stopTest();
      a1 = getTestAcct();
      // check that referral gets changed on Opportunity insert
      System.assertEquals(r1.Id,a1.Banker_Name_Ref__c);
   } // testBanker
*/
   public static testMethod void testLeadCPA() {
      LeadSource__c ls = LeadSourceHelperTest.getLeadSourceByCategory(Label.LeadSourceCat_CPA);
      System.assertNotEquals(null,ls,'Could not find a LeadSource__c for '+Label.LeadSourceCat_CPA);

      Referral_Account__c ra = getTestRefAcct();
      Referral_Contact__c rc = getTestRefCtct('Test1');

      Lead ld = new Lead(LastName='TestLast', Company='Test Company', PostalCode='14624', LeadSource=ls.Name, Referral_Contact__c=rc.Id);
      insert ld;
      
      OpptyChkReferral.ALREADY_RAN_SET.clear();
     
      LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
      Database.LeadConvert lc = new database.LeadConvert();
      lc.setLeadId(ld.id);
      // set the status
      lc.setConvertedStatus(convertStatus.MasterLabel);

      Test.StartTest();
      // convert the lead
      Database.LeadConvertResult lcr = Database.convertLead(lc);
      Test.stopTest();
      
      System.assert(lcr.isSuccess());
    
      // get the Account Record
      Account a1 = [select Id, CPA_Name_Ref__c from Account where Id = :lcr.getAccountId()];
      System.assertEquals(rc.Id,a1.CPA_Name_Ref__c);
       
   } // testLeadCPA
   
   public static testMethod void testLeadStrategic() {
      LeadSource__c ls = LeadSourceHelperTest.getLeadSourceByCategory(Label.LeadSourceCat_Strategic);
      System.assertNotEquals(null,ls,'Could not find a LeadSource__c for '+Label.LeadSourceCat_Strategic);

      Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType('Sales Channel Referral Account Record Type', 'Referral_Account__c'); 
      
      Referral_Account__c ra = getTestRefAcct();
      ra.RecordTypeId = rtInfo.getRecordTypeId();
      update ra;

      Lead ld = new Lead(LastName='TestLast', Company='Test Company', PostalCode='14624', LeadSource=ls.Name, Referral_National_Account__c=ra.Id);
      insert ld;
      
      OpptyChkReferral.ALREADY_RAN_SET.clear();
     
      LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
      Database.LeadConvert lc = new database.LeadConvert();
      lc.setLeadId(ld.id);
      // set the status
      lc.setConvertedStatus(convertStatus.MasterLabel);

      Test.StartTest();
      // convert the lead
      Database.LeadConvertResult lcr = Database.convertLead(lc);
      Test.stopTest();
      
      System.assert(lcr.isSuccess());
    
      // get the Account Record
      Account a1 = [select Id, Referral_National_Account__c from Account where Id = :lcr.getAccountId()];
      System.assertEquals(ra.Id,a1.Referral_National_Account__c);
       
   } // testLeadStrategic
   
   public static testMethod void testLeadBank() {
      LeadSource__c ls = LeadSourceHelperTest.getLeadSourceByCategory(Label.LeadSourceCat_Bank);
      System.assertNotEquals(null,ls,'Could not find a LeadSource__c for '+Label.LeadSourceCat_Bank);

      Referral_Account__c ra = getTestRefAcct();
      ra.Sensitivity_Credit_Card_Processing__c = true;
      update ra;
      Referral_Contact__c rc = getTestRefCtct('Test1');

      Lead ld = new Lead(LastName='TestLast', Company='Test Company', PostalCode='14624', LeadSource=ls.Name, Referral_Contact__c=rc.Id);
      insert ld;
      
      OpptyChkReferral.ALREADY_RAN_SET.clear();
     
      LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
      Database.LeadConvert lc = new database.LeadConvert();
      lc.setLeadId(ld.id);
      // set the status
      lc.setConvertedStatus(convertStatus.MasterLabel);

      Test.StartTest();
      // convert the lead
      Database.LeadConvertResult lcr = Database.convertLead(lc);
      Test.stopTest();
      
      System.assert(lcr.isSuccess());
    
      // get the Account Record
      Account a1 = [select Id, Banker_Name_Ref__c, SensitivityList__c from Account where Id = :lcr.getAccountId()];
      System.assertEquals(rc.Id,a1.Banker_Name_Ref__c);
      //System.assertEquals(true, a1.SensitivityList__c.contains('CC Processing'));
       
   } // testLeadBank   
    
} // class OpptyChkReferralTest