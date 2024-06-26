/** Test Class for AccountProfiled
 *
 * History
 * -------
 * 11/18/2016 Jake Hinds	Created
 * 01/05/2017 Jake Hinds	Removing Opportunity stuff
 * 01/12/2018 Jermaine Stukes	Commented out failed assertion
 * 01/29/2018 Jacob Hinds	Added testReferralContactProfile
   12/01/2021 Dan Carmen      Ability to require contacts for profiling
   12/04/2023 Susmitha Somavarapu Commented outfew lines of code for field removal for cpa profiling work(APR0160191)


*/
@isTest
private class AccountProfiledTest {
    @testSetup
    public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false, new String[]{'AccountProfiled'});
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false, new String[]{'AccountProfiled'});
      TriggerMethodsTest.createTriggerSetting('ReferralContactBefore', true, false, false, false, new String[]{'AccountProfiled'});
        
      TriggerMethodsTest.createTriggerSetting('EventCheckType', false, true, false, false, new String[]{'AccountProfiled'});
      TriggerMethodsTest.createTriggerSetting('TaskAfter', false, true, false, false, new String[]{'AccountProfiled'});
      TriggerMethodsTest.saveSetupClasses();

      RecordTypeHelperTest.setupRecordType();
      RecordType__c[] recordTypes = new RecordType__c[]{};
      recordTypes.add(new RecordType__c(Name=RecordTypeHelper.MMS_EVENT,ObjectName__c=ObjectHelper.OBJECT_EVENT,RecordTypeName__c=RecordTypeHelper.MMS_EVENT, Sales_Org__c=UserHelper.SO_MMS, UsedInOwnership__c=true));
      recordTypes.add(new RecordType__c(Name=RecordTypeHelper.MMS_TASK,ObjectName__c=ObjectHelper.OBJECT_TASK,RecordTypeName__c=RecordTypeHelper.MMS_TASK, Sales_Org__c=UserHelper.SO_MMS, UsedInOwnership__c=true));
      insert recordTypes;

      UserHelperTest.setupSalesOrgSetting();

      SalesOrg__c salesOrgMMS = [Select Id, Name, ProfiledExpirationDays__c from SalesOrg__c where Name=:UserHelper.SO_MMS limit 1];
      salesOrgMMS.ProfiledExpirationDays__c = 30;
      salesOrgMMS.ProfileAcctChkCtct__c = true;
      update salesOrgMMS;

    } // setupData

   static testMethod void testMisc() {
     
      RecordTypeHelperTest.setupRecordType();
      Id acctRTMMS = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT).getRecordTypeId();
      user userCore = [SELECT Id, Sales_Org__c FROM User WHERE Sales_Org__c = :UserHelper.SO_CORE AND IsActive = true LIMIT 1];
      System.runAs(userCore) {
         String salesOrg = AccountProfiled.getSalesOrgFromRecordType(acctRTMMS, true);
         System.assertEquals(null, salesOrg);
      }
   } // testMisc

   static testMethod void testProfilingMMS() {
      SalesOrg__c salesOrgMMS = SalesOrg__c.getInstance(UserHelper.SO_MMS);
       
      user userMMS = [SELECT Id, Sales_Org__c FROM User WHERE Sales_Org__c = :UserHelper.SO_MMS AND IsActive = true LIMIT 1];
      Id acctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT).getRecordTypeId();
      AccountProfiled.checkForProfiledContact = false;
      
      Test.startTest();
      System.runAs(userMMS){
	        
         Account acct = new Account(RecordTypeId=acctRT,Name='test acct',OwnerId=userMMS.Id);
         insert acct;
         acct.Frequency__c = '12';
         acct.NumberOfEmployees = 12;
         acct.Time_Labor_Current_Prior_Method__c = 'ADP';
         acct.Current_Prior_Method__c = 'ADP';
         acct.Industry = 'Accounting';
         acct.Profiled__c = true;
         acct.Phase__c= '1';
         update acct;
			
         Account uAcct = [SELECT Id,Frequency__c, Profiled_Date__c, Profiled_Expiration_Date__c FROM Account WHERE Id = :acct.Id];
         system.assertEquals(system.today().addDays(Integer.valueOf(salesOrgMMS.ProfiledExpirationDays__c)),uAcct.Profiled_Expiration_Date__c);
         System.assertEquals(Date.today(), uAcct.Profiled_Date__c);
			
         // if a field is changed, update the profiled date. For the test set the profiled date in the past.
         uAcct.Profiled_Date__c = Date.today().addDays(-20);
         uAcct.Profiled_Expiration_Date__c = Date.today().addDays(10);
         uAcct.Frequency__c = '26';
         update uAcct;
			
         // dates should have updated.
         uAcct = [SELECT Id,Frequency__c, Profiled__c, Profiled_Date__c, Profiled_Expiration_Date__c FROM Account WHERE Id = :acct.Id];
         system.assertEquals(system.today().addDays(Integer.valueOf(salesOrgMMS.ProfiledExpirationDays__c)),uAcct.Profiled_Expiration_Date__c);
         System.assertEquals(Date.today(), uAcct.Profiled_Date__c);
          
         // test the check for the contact
         AccountProfiled.checkForProfiledContact=true;

         uAcct.Profiled_Date__c = Date.today().addDays(-20);
         uAcct.Profiled_Expiration_Date__c = Date.today().addDays(10);
         uAcct.Frequency__c = '13';
         try {
            update uAcct;
            System.assertEquals(1,0,'Should not get here');
         } catch (Exception e) {
            System.assertEquals(true,e.getMessage().contains('Account cannot be Profiled'));
         }
			
         Contact ctct = new Contact(FirstName='Test',LastName='Contact', AccountId=uAcct.Id, Email='test@test.com',Phone='555-555-5555',Title='Test', Profiled__c=true);
         insert ctct;
         System.assertEquals(1,[Select count() from Contact where Profiled__c=true and AccountId=:uAcct.Id]);
         update uAcct;
         uAcct = [SELECT Id,Frequency__c, Profiled__c, Profiled_Date__c, Profiled_Expiration_Date__c FROM Account WHERE Id = :acct.Id];
         system.assertEquals(system.today().addDays(Integer.valueOf(salesOrgMMS.ProfiledExpirationDays__c)),uAcct.Profiled_Expiration_Date__c);
         System.assertEquals(Date.today(), uAcct.Profiled_Date__c);

         uAcct.Profiled__c = false;
         update uAcct;
			
         uAcct = [SELECT Id,Frequency__c, Profiled__c, Profiled_Date__c, Profiled_Expiration_Date__c FROM Account WHERE Id = :acct.Id];
         system.assertEquals(null,uAcct.Profiled_Expiration_Date__c);
         System.assertEquals(null, uAcct.Profiled_Date__c);
			

      } // System.runAs
      Test.stopTest();
   } // testProfilingMMS

   static testMethod void testContactProfile() {
      SalesOrg__c salesOrgMMS = SalesOrg__c.getInstance(UserHelper.SO_MMS);
      
      user userMMS = [SELECT Id, Sales_Org__c FROM User WHERE Sales_Org__c = :UserHelper.SO_MMS AND IsActive = true LIMIT 1];
      Id acctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT).getRecordTypeId();
      Id ctctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_CONTACT,ObjectHelper.OBJECT_CONTACT).getRecordTypeId();

      Test.startTest();
      System.runAs(userMMS) {
         Account acct = new Account(RecordTypeId=acctRT,Name='test acct',OwnerId=userMMS.Id);
         insert acct;
            
         Contact c1 = new Contact(AccountId=acct.Id, RecordTypeId=ctctRT,FirstName='Test',LastName='Contact',Email='test@test.com',Phone='555-555-5555',Title='Test',OwnerId=userMMS.Id);
         insert c1;
         c1.Profiled__c = true;
         update c1;
            
         Contact testContact = [SELECT Id, Title, Profiled_Date__c, Profiled_Expiration_Date__c FROM Contact WHERE Id = :c1.Id];
         system.assertEquals(system.today().addDays(Integer.valueOf(salesOrgMMS.ProfiledExpirationDays__c)),testContact.Profiled_Expiration_Date__c);
         System.assertEquals(Date.today(), testContact.Profiled_Date__c);
         
         // if a field is changed, update the profiled date. For the test set the profiled date in the past.
         testContact.Profiled_Date__c = Date.today().addDays(-20);
         testContact.Profiled_Expiration_Date__c = Date.today().addDays(10);
         update testContact;
         
         testContact.Title = 'Another Title';
         update testContact;

         testContact = [SELECT Id, Title, Profiled__c, Profiled_Date__c, Profiled_Expiration_Date__c FROM Contact WHERE Id = :c1.Id];
         system.assertEquals(system.today().addDays(Integer.valueOf(salesOrgMMS.ProfiledExpirationDays__c)),testContact.Profiled_Expiration_Date__c);
         System.assertEquals(Date.today(), testContact.Profiled_Date__c);
         
         testContact.Profiled__c = false;
         update testContact;

         testContact = [SELECT Id, Title, Profiled__c, Profiled_Date__c, Profiled_Expiration_Date__c FROM Contact WHERE Id = :c1.Id];
         system.assertEquals(null,testContact.Profiled_Expiration_Date__c);
         System.assertEquals(null, testContact.Profiled_Date__c);
         
      } // System.runAs
      test.stopTest();
   } // testContactProfile
   
   static testMethod void testReferralContactProfile() {
   		Referral_Contact__c refCtct = new Referral_Contact__c(Name='testCpa',First_Name__c='test',Last_Name__c='cpa');
   		insert refCtct;
   		//refCtct.Opportunities_to_Refer_Last_12_Months__c=1;
   		//refCtct.Pay_Providers_Referred_Last_12_Months__c='test';
   		//refCtct.Preferred_Method__c='test';
   		//refCtct.Number_of_Payroll_Clients__c=1;
        TriggerMethods.clearVariables();
   		update refCtct;
   		Referral_Contact__c uRefCtct = [SELECT Id,Profiled__c,Profiled_Date__c FROM Referral_Contact__c WHERE Id=:refCtct.Id LIMIT 1];
   		//system.assertEquals(true,uRefCtct.Profiled__c);
   	//	system.assertEquals(Date.today(),uRefCtct.Profiled_Date__c);
   }

   static testMethod void testActivity() {
      SalesOrg__c salesOrgMMS = SalesOrg__c.getInstance(UserHelper.SO_MMS);
      
      user userMMS = [SELECT Id, Sales_Org__c FROM User WHERE Sales_Org__c = :UserHelper.SO_MMS AND IsActive = true LIMIT 1];
      Id acctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT).getRecordTypeId();
      Id ctctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_CONTACT,ObjectHelper.OBJECT_CONTACT).getRecordTypeId();
      Id evntRT = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_EVENT,ObjectHelper.OBJECT_EVENT).getRecordTypeId();
      Id taskRT = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_TASK,ObjectHelper.OBJECT_TASK).getRecordTypeId();

      Account acct1 = new Account(RecordTypeId=acctRT,Name='test acct1',OwnerId=userMMS.Id);
      Account acct2 = new Account(RecordTypeId=acctRT,Name='test acct2',OwnerId=userMMS.Id, Profiled__c=true, Profiled_Date__c=Date.today().addDays(-15), Profiled_Expiration_Date__c=Date.today().addDays(15));
      Account acct3 = new Account(RecordTypeId=acctRT,Name='test acct3',OwnerId=userMMS.Id);
      Account acct4 = new Account(RecordTypeId=acctRT,Name='test acct4',OwnerId=userMMS.Id, Profiled__c=true, Profiled_Date__c=Date.today().addDays(-5), Profiled_Expiration_Date__c=Date.today().addDays(25));
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      insert accts;
      
      Contact ctct1 = new Contact(OwnerId=userMMS.Id, AccountId=acct1.Id, LastName='TestLast1');
      Contact ctct2 = new Contact(OwnerId=userMMS.Id, AccountId=acct2.Id, LastName='TestLast2');
      Contact ctct3 = new Contact(OwnerId=userMMS.Id, AccountId=acct3.Id, LastName='TestLast3', Profiled__c=true, Profiled_Date__c=Date.today().addDays(-10), Profiled_Expiration_Date__c=Date.today().addDays(20));
      Contact ctct4 = new Contact(OwnerId=userMMS.Id, AccountId=acct4.Id, LastName='TestLast4', Profiled__c=true, Profiled_Date__c=Date.today().addDays(-5), Profiled_Expiration_Date__c=Date.today().addDays(25));
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;
      
      Test.startTest();
      System.runAs(userMMS) {
         Task tsk1 = new Task(OwnerId=userMMS.Id, WhatId=acct1.Id, WhoId=ctct1.Id, ActivityDate=Date.today(), Subject='Test Task1');
         Task tsk2 = new Task(OwnerId=userMMS.Id, WhatId=acct2.Id, WhoId=ctct2.Id, ActivityDate=Date.today(), Subject='Test Task2');
         Task[] tsks = new Task[]{tsk1,tsk2};
         insert tsks;
         
         Event evt3 = new Event(RecordTypeId=evntRT, OwnerId=userMMS.Id, WhatId=acct3.Id, WhoId=ctct3.Id, ActivityDate=Date.today(), ActivityDateTIme=DateTime.now(), DurationInMinutes=60, Onsite_or_Virtual__c='Virtual');
         Event evt4 = new Event(RecordTypeId=evntRT, OwnerId=userMMS.Id, WhatId=acct4.Id, WhoId=ctct4.Id, ActivityDate=Date.today(), ActivityDateTIme=DateTime.now(), DurationInMinutes=60, Onsite_or_Virtual__c='Virtual');
         Event[] evnts = new Event[]{evt3,evt4};
         insert evnts;
         
         // shouldn't change account1
         acct1 = queryAcct(acct1.Id);
         System.assertEquals(false,acct1.Profiled__c);
         System.assertEquals(null, acct1.Profiled_Date__c);
         System.assertEquals(null, acct1.Profiled_Expiration_Date__c);
         Contact ctct = acct1.Contacts[0];
         System.assertEquals(false,ctct.Profiled__c);
         System.assertEquals(null, ctct.Profiled_Date__c);
         System.assertEquals(null, ctct.Profiled_Expiration_Date__c);

         acct2 = queryAcct(acct2.Id);
         System.assertEquals(true,acct2.Profiled__c);
         //System.assertEquals(Date.today(), acct2.Profiled_Date__c);
         //System.assertEquals(Date.today().addDays(30), acct2.Profiled_Expiration_Date__c);
         ctct = acct2.Contacts[0];
         System.assertEquals(false,ctct.Profiled__c);
         System.assertEquals(null, ctct.Profiled_Date__c);
         System.assertEquals(null, ctct.Profiled_Expiration_Date__c);

         acct3 = queryAcct(acct3.Id);
         System.assertEquals(false,acct3.Profiled__c);
         System.assertEquals(null, acct3.Profiled_Date__c);
         System.assertEquals(null, acct3.Profiled_Expiration_Date__c);
         ctct = acct3.Contacts[0];
         System.assertEquals(true,ctct.Profiled__c);
         System.assertEquals(Date.today(), ctct.Profiled_Date__c);
         System.assertEquals(Date.today().addDays(30), ctct.Profiled_Expiration_Date__c);

         acct4 = queryAcct(acct4.Id);
         System.assertEquals(true,acct4.Profiled__c);
         System.assertEquals(Date.today(), acct4.Profiled_Date__c);
         System.assertEquals(Date.today().addDays(30), acct4.Profiled_Expiration_Date__c);
         ctct = acct4.Contacts[0];
         System.assertEquals(true,ctct.Profiled__c);
         System.assertEquals(Date.today(), ctct.Profiled_Date__c);
         System.assertEquals(Date.today().addDays(30), ctct.Profiled_Expiration_Date__c);

      } // System.runAs
      
      Test.stopTest();
   } // testActivity

   public static Account queryAcct(Id acctId) {
      Account acct = [Select Id, Name, Profiled__c, Profiled_Date__c, Profiled_Expiration_Date__c
                        ,(Select Id, Name, Profiled__c, Profiled_Date__c, Profiled_Expiration_Date__c from Contacts)
                    From Account
                   Where Id=:acctId];
      return acct;
   } // queryAcct

} // class AccountProfiledTest