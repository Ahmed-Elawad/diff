/* 
 *This is the test class for the LeadCheckContactRecordType trigger and class.
 *
 * History
 * -------
 * 09/10/2009 Dan Carmen   Created
   10/28/2011 Dan Carmen   Change to use Schema.RecordTypeInfo
   07/02/2013 J Stouffer   Added Remote Locations code
   09/06/2013 J Stouffer   Added TestMSPLead
   07/14/2015 Dan Carmen   Adjustment to tests to account for number of employees being the prime segmentation component.
   11/20/2015 Dan Carmen   Add referrals
   05/24/2017 Dan Carmen   Update the Partner Referrals and Marketing Call Tracking on lead convert.
   09/17/2018 Dan Carmen        Add TriggerSetupClasses__c so test will pass with new Lead Company Methods
   12/14/2018 Dan Carmen   Pull out some of the updates into a non-future method (seem to be causing an issue further down the line)
                           Have to leave most of them future because of DML limits being hit.
   02/06/2020 Dan Carmen   Increment API version
   03/28/2022 Dan Carmen   Change to allow account ownership to fire

 */
@isTest
private class LeadCheckContactRecordTypeTest {

   @testSetup
   public static void setupData(){
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, new String[]{'LeadCompanyMethods'},setupClasses, TriggerMethods.INTERFACE_B);
      insert setupClasses;
      RecordTypeHelperTest.setupRecordType();
      DataFluxDeltaServiceTest.disableDeltaTriggers();
   } // setupData

   private static void setupTestData() {
      // get all of the Core and MMS Record types
      String[] objectNames = new String[]{'Account','Contact'};
      RecordTypeHelper.getRecordTypesMap(objectNames, LeadCheckContactRecordType.RECORD_TYPE_NAMES, byId, byName);
    
      convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
   } // setupTestData
   
   private static Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
   private static Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
   private static LeadStatus convertStatus;
    /** Test that the record type on the contact is either Core or MMS after a convert.
     */

   static testMethod void testLeadConvert_a() {
      setupTestData();
    
      // run as a system admin ensuring not PAY or MMS
      User user0 = [select id, isActive, Sales_Org__c from User where isActive=true and Id != :UserInfo.getUserId() and Profile.Name='System Administrator' and Sales_Org__c != 'PAY'and Sales_Org__c != 'MMS' limit 1];
      System.runAs(user0) {
         System.debug('Testing Core lead - number of employees=30, sys admin user');
         testLead('1', 30, byName.get(AccountHelper.CORE_ACCOUNT), byName.get(AccountHelper.CORE_CONTACT));
      } // System.runAs

   } // testLeadConvert_a

   static testMethod void testLeadConvert_b() {
      setupTestData();
    
      // run as a system admin ensuring not PAY or MMS
      User user0 = [select id, isActive, Sales_Org__c from User where isActive=true and Id != :UserInfo.getUserId() and Profile.Name='System Administrator' and Sales_Org__c != 'PAY'and Sales_Org__c != 'MMS' limit 1];
      System.runAs(user0) {
         System.debug('Testing MMS lead - number of employees=80, sys admin user');
         testLead('2', 80, byName.get(AccountHelper.MMS_ACCOUNT), byName.get(AccountHelper.MMS_CONTACT));
      } // System.runAs

   } // testLeadConvert_b
   
   static testMethod void testLeadConvert_c() {
      setupTestData();
    
      // run as a system admin ensuring not PAY or MMS
      User user0 = [select id, isActive, Sales_Org__c from User where isActive=true and Id != :UserInfo.getUserId() and Profile.Name='System Administrator' and Sales_Org__c != 'PAY'and Sales_Org__c != 'MMS' limit 1];
      System.runAs(user0) {
         System.debug('Testing Core lead - number of employees=null, sys admin user');
         testLead('3', null, byName.get(AccountHelper.CORE_ACCOUNT), byName.get(AccountHelper.CORE_CONTACT));
      } // System.runAs

   } // testLeadConvert_c
   
   static testMethod void testLeadConvert2_a() {
      setupTestData();
      
      // run as a PAY user
      User user1 = [select id, isActive, Sales_Org__c from User where isActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c = :UserHelper.SO_CORE limit 1];
      System.runAs(user1) {        
         System.debug('Testing Core lead based on Sales Org- number of employees=40, PAY user');
         //testLead('4', 40, byName.get(AccountHelper.CORE_ACCOUNT), byName.get(AccountHelper.CORE_CONTACT));
      } // System.runAs
      
   } // testLeadConvert2_a

   static testMethod void testLeadConvert2_b() {
      setupTestData();
      
      // run as an MMS user
      User user2 = [select id, isActive, Sales_Org__c from User where isActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c = :UserHelper.SO_MMS limit 1];
      System.runAs(user2) {        
         System.debug('Testing MMS lead based on Sales Org- number of employees=80, MMS user');
         testLead('5', 80, byName.get(AccountHelper.MMS_ACCOUNT), byName.get(AccountHelper.MMS_CONTACT));
      } // System.runAs      
      
   } // testLeadConvert2_b

   static testMethod void testLeadConvertMSP() {
      Utilities.SKIP_FUTURE=true;
      
      // find the MSP profile
      Profile mspProf = [Select Id, Name from Profile where Name=:Utilities.PROF_MSP_REP];
      // get the running user
      User runningUser = UserHelper.getRunningUser();
      User mspUser = new UserTestHelper().createUser(1, mspProf, runningUser.UserRole, runningUser);
      insert mspUser;
      
      //User user3 = [select id, Name, isActive, ProfileId, Sales_Org__c from User where isActive=true and Id != :UserInfo.getUserId() and Profile.Name = :Utilities.PROF_MSP_REP and Sales_Org__c = 'MSP' limit 1];
      System.runAs(mspUser) {
         setupTestData();
         System.debug('Testing MSP lead user3='+mspUser.Name);
         testMSPLead('6', 40, byName.get(AccountHelper.CORE_ACCOUNT), byName.get(AccountHelper.CORE_CONTACT));        
      } // System.runAs
   } // testLeadConvertMSP

   private static void testLead(String leadNum, Integer numEmps, Schema.RecordTypeInfo acctRT, Schema.RecordTypeInfo ctctRT) {
      // create a new Lead
      Lead lead = new Lead(FirstName='Johnny'
                           ,LastName='Test'+leadNum
                           ,Company='Johnny Test Lead'+leadNum+' Co'
                           ,NumberOfEmployees=numEmps
                           ,Status='Qualified'
                           ,LeadSource='62 Cold Call'
                           ,PostalCode='14514');
      insert lead;
       
      Remote_Locations__c rl = new Remote_Locations__c(Lead__c=lead.Id);
      insert rl;

      Referral__c rfrl = new Referral__c(SourceLead__c=lead.Id);
      insert rfrl;
      
      PartnerReferral__c partRef = new PartnerReferral__c(Lead__c=lead.id);
      insert partRef;
      
      Marketing_Call_Tracking__c mct = new Marketing_Call_Tracking__c(Lead__c=lead.Id, MM_Call_Date__c=DateTime.now());
      insert mct;
      
      Prospect_Ownership__c po = new Prospect_Ownership__c(Lead__c=lead.Id);
      insert po;
      
      // create a LeadConvert object       
      Database.LeadConvert lc = new database.LeadConvert();
      lc.setLeadId(lead.id);

      // set the status
      lc.setConvertedStatus(convertStatus.MasterLabel);
      
      Test.startTest();
      // convert the lead
      Database.LeadConvertResult lcr = Database.convertLead(lc);
      Test.stopTest();
      
      System.assert(lcr.isSuccess());

      // get the Contact Record
      Contact c1 = [select id, RecordTypeId from Contact where Id = :lcr.getContactId()];
      // verify the contact record type
      System.assertEquals(c1.RecordTypeId,ctctRT.getRecordTypeId());
      
      // get the Account Record
      Account a1 = [select Id, RecordTypeId from Account where Id = :lcr.getAccountId()];
      // verify the account record type
      System.assertEquals(a1.RecordTypeId,acctRT.getRecordTypeId());
       
      // get the Remote Location Record 
      Remote_Locations__c rl1 = [Select Id, Prospect_Client_Name__c from Remote_Locations__c where Id =: rl.Id];
      // verify the Prospect Client on the Remote Location has been populated as expected.        
      system.assertEquals(rl1.Prospect_Client_Name__c, a1.Id);     
      
      rfrl = [Select Id, Account__c, SourceContact__c, SourceLead__c from Referral__c where Id = :rfrl.Id];
      System.assertEquals(a1.Id,rfrl.Account__c);
      System.assertEquals(c1.Id,rfrl.SourceContact__c);
      
      partRef = [Select Id, Account__c, Contact__c, Lead__c from PartnerReferral__c where Id=:partRef.Id];
      System.assertEquals(a1.Id,partRef.Account__c);
      System.assertEquals(c1.Id,partRef.Contact__c);
      
      mct = [Select Id, Account__c, Contact__c, Lead__c from Marketing_Call_Tracking__c where Id=:mct.Id];
      System.assertEquals(a1.Id,mct.Account__c);
      System.assertEquals(c1.Id,mct.Contact__c);
      
      po = [Select Id, Prospect_Client__c, Decision_Maker__c, Lead__c from Prospect_Ownership__c where Id=:po.Id];
      System.assertEquals(a1.Id,po.Prospect_Client__c);
      System.assertEquals(c1.Id,po.Decision_Maker__c);
      
   } // testLead

   private static void testMSPLead(String leadNum, Integer numEmps, Schema.RecordTypeInfo acctRT, Schema.RecordTypeInfo ctctRT) {   
         // create a new Lead
         Lead ld = new Lead(FirstName='Johnny'
                           ,LastName='Test'+leadNum
                           ,Company='Johnny Test Lead'+leadNum+' Co'
                           ,NumberOfEmployees=numEmps
                           ,Status='Qualified'
                           ,LeadSource='62 Cold Call'
                           ,PostalCode='14514');
         insert ld;
         Lead newLead = [select Id, Ownerid, Name, Company, Lead_Company__c, LeadGroupId__c from Lead where id = :ld.Id];
         System.assertNotEquals(null, newLead.LeadGroupId__c);
         Id lOwnerId = newLead.OwnerId;
      
         // create a LeadConvert object       
         Database.LeadConvert lc = new database.LeadConvert();
         lc.setLeadId(ld.id);

         // set the status
         lc.setConvertedStatus(convertStatus.MasterLabel);
       
         Test.startTest();
         // convert the lead
         Database.LeadConvertResult lcr = Database.convertLead(lc);
         Test.stopTest();
         System.assert(lcr.isSuccess());
      
         // get the Account Record
         Account a1 = [select Id, RecordTypeId from Account where Id = :lcr.getAccountId()];
      
         // get the AccountTeamMember Record 
         AccountTeamMember act1 = [Select Id, AccountId, UserId, CreatedDate from AccountTeamMember where AccountId =: a1.Id Order By CreatedDate DESC Limit 1];
         // verify the UserID on the AccountTeamMember record has been populated as expected.        
         system.assertEquals(lOwnerId, act1.UserId);
   } // testMSPLead
   
} // class LeadCheckContactRecordTypeTest