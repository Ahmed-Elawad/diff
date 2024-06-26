/* 
 * Test Methods for the OpptyUpdateAcct class
 *
 * History
 * -------
   09/06/2018 Dan Carmen       Created
   12/23/2018 Cindy Freeman    added test for account owner update to match opty owner   
   03/12/2019 Cindy Freeman    cleanup up test data for testOptyNotSold
   07/08/2019 Dan Carmen        Change for Core Sales profile move
   07/12/2019 Brandon Vidro    Added check for Current_Prior_Method__c update on Account
   10/14/2019 Brandon Vidro    Updated testCurrentPriorMethod test to check for null values
   07/24/2020 Jake Hinds       Automation for Service Model Type
   08/18/2020 Jake Hinds       Set MPSC for Service Model Type
   10/21/2020 Dan Carmen        Add Local_Competitors__c field to copy from Opp
   02/08/2021 Matt Fritschi		Test for extending SMB Channel Holdouts from created Opptys
   02/21/2021 Brandon Vidro    Test for automatic HRS crossover
   05/18/2021 Carrie Marciano Updated StageName to use OppStage labels
   11/21/2022 Carrie Marciano Commented out failing test testSetHrsHoldoutAndCrossover
   11/22/2022 Carrie Marciano  Updated to test P&C oppty and renewal date update to Account Workers Comp Renewal Date

 */

@isTest
private class OpptyUpdateAcctTest {

   @testSetup 
   public static void setupTestData() {
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, new String[]{'OpptyUpdateAcct'}, setupClasses, TriggerMethods.INTERFACE_B);
      TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, new String[]{'HoldOutExpirationMethods'}, setupClasses, TriggerMethods.INTERFACE_B);
      insert setupClasses;

      OpptyCheckJoinTest.setupRecordTypes();
      RecordTypeHelperTest.setupRecordType();
      
      List<HoldOut_Dictionary__c> hoList = new List<HoldOut_Dictionary__c>();
      HoldOut_Dictionary__c hod = new HoldOut_Dictionary__c(Name='Advantage Rep',Permanent__c=true, Use_Opty_Owner__c=false,
                                        Description__c='can not be changed');
      hoList.add(hod);
      hod = new HoldOut_Dictionary__c(Name='Admin',Permanent__c=false, Use_Opty_Owner__c=false,
                                        Description__c='can be changed');
      hoList.add(hod);
      hod = new HoldOut_Dictionary__c(Name='Micro Size Prospect worked by Virtual',Permanent__c=false, Use_Opty_Owner__c=true,
                                        Description__c='set account to opty owner', Next_HO_reason__c='Micro Size Client Sold by Virtual',
                                        Sold_clears_Expiration_Date__c=true, Not_Sold_clears_Hold_Out__c=true );
      hoList.add(hod);
      hod = new HoldOut_Dictionary__c(Name='Micro Size Client Sold by Virtual',Permanent__c=false, Use_Opty_Owner__c=false,
                                        Description__c='set account to opty owner', Next_HO_reason__c=null,
                                        Sold_clears_Expiration_Date__c=true, Not_Sold_clears_Hold_Out__c=true );
      hoList.add(hod);
      upsert hoList; 
       
      // populate HoldOut ExpirationDates custom setting
      HoldOutExpirationMethodsTest.populateSetting();
       
   } // setupTestData

    
   static testMethod void testLinkToAccount() {
      Account acct = new Account(Name='Test Acct');
      insert acct;
      
      Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
      Schema.RecordTypeInfo rtMms = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS, ObjectHelper.OBJECT_OPPTY);
      Schema.RecordTypeInfo rtHrs = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_401K, ObjectHelper.OBJECT_OPPTY);

      RecordType__c rtSettingCore = RecordTypeHelper.getRtSetting(OpportunityCreateCase.RT_OPPTY_CORE);
      RecordType__c rtSettingHRS = RecordTypeHelper.getRtSetting(OpportunityCreateCase.RT_OPPTY_401K);
      OpptyUpdateAcct.PAY_OPP_TYPES = new Set<String>(new String[]{rtSettingCore.OpportunityType__c});
      OpptyUpdateAcct.HRS_OPP_TYPES = new Set<String>(new String[]{rtSettingHRS.OpportunityType__c});

      Opportunity opp1 = new Opportunity(Name='Opp 1',RecordTypeId=rtCore.getRecordTypeId(), AccountId=acct.Id, StageName=Label.OppStage_Qualified, CloseDate=Date.today(), NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND);
      Opportunity opp2 = new Opportunity(Name='Opp 2',RecordTypeId=rtHrs.getRecordTypeId(), AccountId=acct.Id, StageName=Label.OppStage_Qualified, CloseDate=Date.today(), NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND);
      Opportunity[] opps = new Opportunity[]{opp1,opp2};
      OpptyUpdateAcct.TEST_PROCESS_NOW = true;
      insert opps;

      acct = getAccount(acct.Id);
                   
      System.assertEquals(acct.LatestHRSOpp__c, opp2.Id);
      System.assertEquals(acct.HRSOppNSSSource__c, opp2.NSS_Source__c);
      System.assertEquals(acct.HRSOppStatus__c, opp2.StageName);
      System.assertEquals(acct.HRSOppDateNotSold__c, null);
      
      System.assertEquals(acct.LatestPayrollOpp__c, opp1.Id);
      System.assertEquals(acct.PayOppNSSSource__c, opp1.NSS_Source__c);
      System.assertEquals(acct.PayOppStatus__c, opp1.StageName);
      System.assertEquals(acct.PayOppDateNotSold__c, null);
      
      opp1.StageName = Label.OppStage_Sold;
      opp1.Payroll_Current_Prior_Method__c = 'Bank';
      opp2.StageName = Label.OppStage_Lost;
      OpptyUpdateAcct.TEST_PROCESS_NOW = false;
      Test.startTest();
      update opps;
      Test.stopTest();
      
      acct = getAccount(acct.Id);
                   
      System.assertEquals(acct.LatestHRSOpp__c, opp2.Id);
      System.assertEquals(acct.HRSOppNSSSource__c, opp2.NSS_Source__c);
      System.assertEquals(acct.HRSOppStatus__c, opp2.StageName);
      System.assertEquals(acct.HRSOppDateNotSold__c, Date.Today());
      
      System.assertEquals(acct.LatestPayrollOpp__c, opp1.Id);
      System.assertEquals(acct.PayOppNSSSource__c, opp1.NSS_Source__c);
      System.assertEquals(acct.PayOppStatus__c, opp1.StageName);
      System.assertEquals(acct.PayOppDateNotSold__c, null);
      System.assertEquals(acct.Current_Prior_Method__c, opp1.Payroll_Current_Prior_Method__c);
      
   } // testLinkToAccount

   private static Account getAccount(Id acctId) {
      Account acct = [Select Id, Name
                    ,HRSOppCreatedDate__c
                    ,HRSOppDateNotSold__c
                    ,HRSOppNSSSource__c
                    ,HRSOppStatus__c
                    ,LatestHRSOpp__c
                    ,LatestPayrollOpp__c
                    ,PAYOppCreatedDate__c
                    ,PAYOppDateNotSold__c
                    ,PAYOppNSSSource__c
                    ,PAYOppStatus__c
                    ,Current_Prior_Method__c
                    ,Service_Model_Type__c
                    ,Work_Comp_Renewal_Date__c  
                From Account Where Id=:acctId];
      return acct;
   } // getAccount

   static testMethod void testOptyToAccount() {
      List<HoldOut_Dictionary__c> hoDictList = HoldOut_Dictionary__c.getall().values();
      System.assertEquals(4, hoDictList.size());
      
      // select test users
      User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.CORE_PROFS limit 2];
      User uCore = users[0];
      User uCore2 = users[1];
      
      // create referral partners w/ and w/o HO reason
      Referral_Partner__c rp20 = new Referral_Partner__c(Name='Test20',Partner_Type__c=ReferralController.REF_NSS,Sort_Order__c=20,Ref_To_Type__c='User',CreateRefOpp__c=false, IsActive__c=true, 
                                Always_Check_Send_Email__c=false);
      insert rp20;                                
      Referral_Partner__c rp21 = new Referral_Partner__c(Name='Test21',Partner_Type__c=ReferralController.REF_NSS,Sort_Order__c=21,Ref_To_Type__c='User',CreateRefOpp__c=false, IsActive__c=true, 
                                Always_Check_Send_Email__c=false,Permanent_Hold_Out_Description__c='Micro Size Prospect worked by Virtual');
      insert rp21;
      
      Account acct = new Account(Name='Test Acct', OwnerId=uCore.Id);
      insert acct;
      
      Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
      Opportunity opp20 = new Opportunity(Name='Opp 20',RecordTypeId=rtCore.getRecordTypeId(), AccountId=acct.Id, StageName=Label.OppStage_Qualified, CloseDate=Date.today(), NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND);
      insert opp20;
      
      // create referral
      Referral__c ref20 = new Referral__c(Name='Ref20',Account__c=acct.Id,Selling_Opportunity__c=opp20.Id,Referral_Partner__c=rp20.Id);
      insert ref20;
      Account updatedAcct = [Select Id, OwnerId from Account where id = :acct.Id];
      System.assertEquals(acct.OwnerId, updatedAcct.OwnerId);
      
      // update opty owner, acct owner shouldnt change
      opp20.OwnerId = uCore2.Id;
      update opp20;
      updatedAcct = [Select Id, OwnerId from Account where id = :acct.Id];
      System.assertNotEquals(opp20.OwnerId, updatedAcct.OwnerId);
            
      // create new opty and referral
      Opportunity opp21 = new Opportunity(Name='Opp 21',RecordTypeId=rtCore.getRecordTypeId(), AccountId=acct.Id, StageName=Label.OppStage_Qualified, CloseDate=Date.today(), NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND);
      insert opp21;
      Referral__c ref21 = new Referral__c(Name='Ref21',Account__c=acct.Id,Selling_Opportunity__c=opp21.Id,Referral_Partner__c=rp21.Id);
      insert ref21;
      opp21.ReferralLookup__c = ref21.Id;
      update opp21;
      updatedAcct = [Select Id, OwnerId from Account where id = :acct.Id];
      System.assertEquals(acct.OwnerId, updatedAcct.OwnerId);
       
      OpptyUpdateAcct.TEST_PROCESS_NOW = true;
      // update opty owner, acct owner should change
      opp21.OwnerId = uCore2.Id;
      update opp21;
      updatedAcct = [Select Id, OwnerId from Account where id = :acct.Id];
      System.assertEquals(opp21.OwnerId, updatedAcct.OwnerId);
      
      OpptyUpdateAcct.TEST_PROCESS_NOW = false;
      OpptyMethods.SKIP_OPPTY_TRIGGERS = false;
      TriggerMethods.clearVariables();
      HoldOutExpirationMethods.ALREADY_RAN_SET.clear();
      Test.startTest();
     
      System.debug('testOptyToAccount before last update');
      // mark opty sold and make sure hold out fields change
      opp21.StageName=Label.OppStage_Sold;
      opp21.service_Location__c ='Albany Branch 0015';
      opp21.Payroll_Unit__c = true;
      update opp21;
      Test.stopTest();
      
      updatedAcct = [Select Id, OwnerId, Permanent_Hold_Out_Description__c, Hold_Out__c, Hold_Out_Expiration__c from Account where id = :acct.Id];
      System.assertEquals('Micro Size Client Sold by Virtual',updatedAcct.Permanent_Hold_Out_Description__c);
      System.assertEquals(null,updatedAcct.Hold_Out_Expiration__c);
   
   } // testOptyToAccount

   static testMethod void testOptyNotSold() {
      List<HoldOut_Dictionary__c> hoDictList = HoldOut_Dictionary__c.getall().values();
      System.assertEquals(4, hoDictList.size());
      
      // select test users
      User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.CORE_PROFS limit 2];
      User uCore = users[0];
      User uCore2 = users[1];
      User uVirtual = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Profile.Name = 'Core Virtual Sales Rep'
                       and Id != :uCore.Id and Id != :uCore2.Id limit 1];
      // create referral partners w/ and w/o HO reason
      Referral_Partner__c rp20 = new Referral_Partner__c(Name='Test20',Partner_Type__c=ReferralController.REF_NSS,Sort_Order__c=20,Ref_To_Type__c='User',CreateRefOpp__c=false, IsActive__c=true, 
                                Always_Check_Send_Email__c=false);
      insert rp20;                                
      Referral_Partner__c rp21 = new Referral_Partner__c(Name='Test21',Partner_Type__c=ReferralController.REF_NSS,Sort_Order__c=21,Ref_To_Type__c='User',CreateRefOpp__c=false, IsActive__c=true, 
                                Always_Check_Send_Email__c=false,Permanent_Hold_Out_Description__c='Micro Size Prospect worked by Virtual');
      insert rp21;
      
      Account acct = new Account(Name='Test Acct', OwnerId=uCore.Id);
      insert acct;      
      
      // create new opty and referral
      Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
      Opportunity opp21 = new Opportunity(Name='Opp 21',RecordTypeId=rtCore.getRecordTypeId(), AccountId=acct.Id, StageName=Label.OppStage_Qualified, 
                                          CloseDate=Date.today(), NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND,
                                          Service_Location__c='Albany 101', Payroll_Unit__c=TRUE, 
                                          OwnerId=uVirtual.Id);
      insert opp21;
      Referral__c ref21 = new Referral__c(Name='Ref21',Account__c=acct.Id,Selling_Opportunity__c=opp21.Id,Referral_Partner__c=rp21.Id);
      insert ref21;
      opp21.ReferralLookup__c = ref21.Id;
      update opp21;
      acct.Permanent_Hold_Out_Description__c = 'Micro Size Prospect worked by Virtual';
      acct.Hold_Out__c = true;
      acct.Hold_Out_Expiration__c = System.Today().addDays(3);
      update acct;
      
      OpptyUpdateAcct.TEST_PROCESS_NOW = false;
      Test.startTest();  
      // mark opty Not Sold and make sure hold out is cleared
      opp21.StageName=Label.OppStage_Lost;
      opp21.Who_did_we_lose_to__c='ADP';
      System.debug('testOptyNotSold before update to Not Sold');
      update opp21;
      Test.stopTest();
      Account updatedAcct = [Select Id, OwnerId, Permanent_Hold_Out_Description__c, Hold_Out__c, Hold_Out_Expiration__c from Account where id = :acct.Id];
      //System.assertEquals(null,updatedAcct.Permanent_Hold_Out_Description__c);
      //System.assertEquals(false,updatedAcct.Hold_Out__c);
     
      
   } // testOptyNotSold
    
    static testMethod void testCurrentPriorMethod() {
        Account acct = new Account(Name='Test Acct', Current_Prior_Method__c = 'Bank');
        insert acct;
        Account acct2 = new Account(Name='Test Acct2');
        insert acct2;
        
        Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
        
        Opportunity opp1 = new Opportunity(Name='Opp 1',RecordTypeId=rtCore.getRecordTypeId(), AccountId=acct.Id, StageName=Label.OppStage_Qualified, CloseDate=Date.today());
        Opportunity opp2 = new Opportunity(Name='Opp 2',RecordTypeId=rtCore.getRecordTypeId(), AccountId=acct2.Id, StageName=Label.OppStage_Qualified, CloseDate=Date.today());
        OpptyUpdateAcct.TEST_PROCESS_NOW = true;
        insert opp1;
        insert opp2;
               
        acct = getAccount(acct.Id);
        acct2 = getAccount(acct2.Id);
        
        System.assertEquals(acct.Current_Prior_Method__c, 'Bank');
        System.assertEquals(acct2.Current_Prior_Method__c, null);
        
        opp1.Payroll_Current_Prior_Method__c = null;
        opp1.StageName = Label.OppStage_Sold;
        
        opp2.Payroll_Current_Prior_Method__c = 'Bank';
        opp2.StageName = Label.OppStage_Sold;

        OpptyUpdateAcct.TEST_PROCESS_NOW = false;
        Test.startTest();
        update opp1;
        update opp2;
        Test.stopTest();
        
        acct = getAccount(acct.Id);
        acct2 = getAccount(acct2.Id);
        
        System.assertEquals(acct.Current_Prior_Method__c, 'Bank');
        System.assertEquals(acct2.Current_Prior_Method__c, opp2.Payroll_Current_Prior_Method__c);
        
    } // testCurrentPriorMethod
    
   static testMethod void testSetHoldoutAndCrossover() {
      User usr1 = [Select Id, Name, Sales_Division__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c != null limit 1];
      User usr2 = [Select Id, Name, Sales_Division__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c != null and Sales_Division__c != :usr1.Sales_Division__c limit 1];
      User usr3 = [Select Id, Name, Sales_Division__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Id != :usr1.Id and Id != :usr2.Id limit 1];
      OpptyUpdateAcct.ACCT_TYPES_FOR_HOLDOUTS = new String[]{'Payroll','Pseudo Payroll','Formerly Known As Payroll'};
      // insert a record specifically for this use case.
      HoldOut_Dictionary__c hod = new HoldOut_Dictionary__c(Name='Very Cool Holdout',Permanent__c=false, Use_Opty_Owner__c=false
                                       ,Description__c='set account to opty owner', Next_HO_reason__c=null
                                       ,Sold_clears_Expiration_Date__c=true, Not_Sold_clears_Hold_Out__c=true
                                       ,InitialNbrDays__c=77, SalesDivisionsToSet__c='Odd Division,'+usr1.Sales_Division__c
                                       ,Sales_Org__c='PAY');
      insert hod;
       
      Account acct1 = new Account(Name='Account1', OwnerId=usr3.Id);
      Account acct2 = new Account(Name='Account2', OwnerId=usr3.Id);
      Account[] accts = new Account[]{acct1,acct2};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
       
      Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct1.Id, OwnerId=usr1.Id, OpportunityType__c='Pseudo Payroll', CloseDate=Date.today().addDays(7), StageName=Label.OppStage_Qualified);
      Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct2.Id, OwnerId=usr2.Id, OpportunityType__c='Formerly Known As Payroll', CloseDate=Date.today().addDays(7), StageName=Label.OppStage_Qualified);
      Opportunity[] opps = new Opportunity[]{opp1,opp2};
      Test.startTest();
      insert opps;
      Test.stopTest();
       
      acct1 = [Select Id, Name, OwnerId, Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c from Account where Id=:acct1.Id];
      System.assertEquals(usr1.Id, acct1.OwnerId);
      System.assertEquals(true,acct1.Hold_Out__c);
      System.assertEquals(Date.today().addDays(77), acct1.Hold_Out_Expiration__c);
      System.assertEquals(hod.Name, acct1.Permanent_Hold_Out_Description__c);

      acct2 = [Select Id, Name, OwnerId, Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c from Account where Id=:acct2.Id];
      System.assertEquals(usr3.Id, acct2.OwnerId);
      System.assertEquals(false,acct2.Hold_Out__c);
      System.assertEquals(null, acct2.Hold_Out_Expiration__c);
      System.assertEquals(null, acct2.Permanent_Hold_Out_Description__c);

   } // testSetHoldoutAndCrossover
   
/* the code is commented out for Virtal Retirement and there are no Sales Divisions called Virtual Retirement any more  
   static testMethod void testSetHrsHoldoutAndCrossover() {
        
        User usr1 = [Select Id, Name, Sales_Division__c, Sales_Org__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c != null limit 1];
        User usr2 = [Select Id, Name, Sales_Division__c, Sales_Org__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c != null and Sales_Division__c != :usr1.Sales_Division__c limit 1];
        User usr3 = [Select Id, Name, Sales_Division__c, Sales_Org__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Id != :usr1.Id and Id != :usr2.Id limit 1];
        User usr4 = [Select Id, Name, Sales_Division__c, Sales_Org__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Id != :usr1.Id and Id != :usr2.Id and Id != :usr3.Id and Sales_Org__c = 'HRS' and Sales_Division__c = 'Virtual Retirement' limit 1];
        
        OpptyUpdateAcct.ACCT_TYPES_FOR_HOLDOUTS = new String[]{'Payroll','Pseudo Payroll','Formerly Known As Payroll'};
            
            HoldOut_Dictionary__c hodTwo = new HoldOut_Dictionary__c(Name='Open Retirement Opportunity',Permanent__c=false, Use_Opty_Owner__c=false
                                                                     ,Description__c='Open Retirement Opportunity', Next_HO_reason__c=null
                                                                     ,Sold_clears_Expiration_Date__c=false, Not_Sold_clears_Hold_Out__c=false
                                                                     ,InitialNbrDays__c=90, SalesDivisionsToSet__c='Virtual Retirement', Sales_Org__c = 'HRS');
        insert hodTwo;
        
        HoldOutExpirationMethodsTest.populateSetting();
        
        Account acct3 = new Account(Name='Account3', OwnerId=usr3.Id, First_Run_Date__c	= Date.today());
        Account[] accts = new Account[]{acct3};
            ZipCheckOwner.SKIP_TRIGGERS=true;
        insert accts;
        
        Opportunity opp3 = new Opportunity(Name='Opp3', AccountId=acct3.Id, OwnerId=usr4.Id, OpportunityType__c='Formerly Known As Payroll', CloseDate=Date.today().addDays(7), StageName=Label.OppStage_Qualified, ReferralLookup__c = null);
        Opportunity[] opps = new Opportunity[]{opp3};
            Test.startTest();
        insert opps;
        Test.stopTest();
        
        acct3 = [Select Id, Name, OwnerId, HRS_Account_Owner__c, Hold_Out__c, HRS_Hold_Out__c, Hold_Out_Expiration__c, HRS_Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c, HRS_Permanent_Hold_Out_Description__c from Account where Id=:acct3.Id];
        System.assertEquals(usr4.Id, acct3.HRS_Account_Owner__c);
        System.assertEquals(true,acct3.HRS_Hold_Out__c);
        System.assertEquals(Date.today().addDays(90), acct3.HRS_Hold_Out_Expiration__c);
        System.assertEquals(hodTwo.Name, acct3.HRS_Permanent_Hold_Out_Description__c);
        System.assertEquals(usr3.Id, acct3.OwnerId);
        System.assertEquals(false,acct3.Hold_Out__c);
        System.assertEquals(null, acct3.Hold_Out_Expiration__c);
        System.assertEquals(null, acct3.Permanent_Hold_Out_Description__c);
        
    } // testSetHrsHoldoutAndCrossover
*/
    
   static testMethod void testServiceModel() {
        Account acct = new Account(Name='Test Acct');
        Account acct2 = new Account(Name='Test Acct2');
        Account[] accts = new Account[]{acct,acct2};
        insert accts;
        
        Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
        
        Opportunity opp1 = new Opportunity(Name='Opp 1',RecordTypeId=rtCore.getRecordTypeId(), AccountId=acct.Id, StageName=Label.OppStage_Qualified, CloseDate=Date.today());
        Opportunity opp2 = new Opportunity(Name='Opp 2',RecordTypeId=rtCore.getRecordTypeId(), AccountId=acct2.Id, StageName=Label.OppStage_Qualified, CloseDate=Date.today(),Service_Location__c='MPSC Indianapolis 943');
        Opportunity opp3 = new Opportunity(Name='Opp 3',RecordTypeId=rtCore.getRecordTypeId(), AccountId=acct2.Id, StageName=Label.OppStage_Qualified, CloseDate=Date.today());
        OpptyUpdateAcct.TEST_PROCESS_NOW = true;
        Opportunity[]opps = new Opportunity[]{opp1,opp2,opp3};
        insert opps;
        
        opp1.StageName = Label.OppStage_Sold;
        opp3.StageName = Label.OppStage_Sold;

        OpptyUpdateAcct.TEST_PROCESS_NOW = false;
        Test.startTest();
        update opp1;
        update opp3;
        Test.stopTest();
        
        acct = getAccount(acct.Id);
        acct2 = getAccount(acct2.Id);
        
        System.assertEquals('NCO',acct.Service_Model_Type__c);
        System.assertEquals('MPSC', acct2.Service_Model_Type__c);
        
    } // testServiceModel
    
    static testMethod void testSMBNewlyOpenedOpportunity() {
        HoldOut_Dictionary__c hod1 = new HoldOut_Dictionary__c(Name='Open Payroll Opportunity',Permanent__c=false, Use_Opty_Owner__c=false
                                       ,Description__c=null, Next_HO_reason__c=null
                                       ,Sold_clears_Expiration_Date__c=false, Not_Sold_clears_Hold_Out__c=false
                                       ,InitialNbrDays__c=90, SalesDivisionsToSet__c='SMB Channel,SMB Virtual Channel');
        insert hod1;
        
        User[] smbUser = [Select Id, Name from user where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c = 'SMB Channel' and Sales_Org__c='PAY' limit 1];
        Account acct = new Account(Name='Account', OwnerId=smbUser[0].Id, Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(2), Permanent_Hold_Out_Description__c='Not Sold Opportunity', Employees__c = 5, NumberOfEmployees=5);
        insert acct;
        
        acct=[SELECT Id, Name, OwnerId, Owner.Sales_Division__c, Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c FROM Account WHERE Id=:acct.Id];
        System.debug('acct.Id='+acct.Id+' acct.OwnerId='+ acct.OwnerId+' acct.Owner.Sales_Division__c=' +acct.Owner.Sales_Division__c+ ' acct.Hold_Out__c='+acct.Hold_Out__c+' acct.Hold_Out_Expiration__c='+acct.Hold_Out_Expiration__c+' acct.Hold_Out_Expiration__c='+acct.Hold_Out_Expiration__c);
        
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, 'Opportunity');
      	Id coreRtId = coreRt.getRecordTypeId();
      	Opportunity opp = new Opportunity(Name='Opp', OwnerId=acct.OwnerId, AccountId=acct.Id, RecordTypeId=coreRtId, OpportunityType__c='Payroll', CloseDate=Date.today().addDays(1), StageName=Label.OppStage_Lost, Payroll_Unit__c=true);
        insert opp;
        
        acct=[SELECT Id, Name, OwnerId, Owner.Sales_Division__c, Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c FROM Account WHERE Id=:acct.Id];
        System.debug('acct.Id='+acct.Id+' acct.OwnerId='+ acct.OwnerId+' acct.Owner.Sales_Division__c=' +acct.Owner.Sales_Division__c+ ' acct.Hold_Out__c='+acct.Hold_Out__c+' acct.Hold_Out_Expiration__c='+acct.Hold_Out_Expiration__c+' acct.Hold_Out_Expiration__c='+acct.Hold_Out_Expiration__c);
        opp=[SELECT Id, Name, OwnerId, Owner.Sales_Division__c, AccountId FROM Opportunity WHERE Id=:opp.Id];
        System.debug('opp.Id='+opp.Id+' opp.OwnerId='+ opp.OwnerId+' opp.Owner.Sales_Division__c=' +opp.Owner.Sales_Division__c+ ' opp.AccountId='+opp.AccountId);    
            
        Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct.Id, RecordTypeId=coreRtId, OpportunityType__c='Payroll', CloseDate=Date.today().addDays(1), StageName='Plan', Payroll_Unit__c=true);
        OpptyUpdateAcct.TEST_PROCESS_NOW = true;
        insert opp2;
        
        acct=[SELECT Id, Name, Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c FROM Account WHERE Id=:acct.Id];
        System.assertEquals(True, acct.Hold_Out__c);
        System.assertEquals(System.today()+90, acct.Hold_Out_Expiration__c);
        System.assertEquals('Open Payroll Opportunity', acct.Permanent_Hold_Out_Description__c);
    } // testSMBNewlyOpenedOpportunity
    
    static testMethod void testHrPartnerOppty(){
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(Label.RT_Core_Account, ObjectHelper.OBJECT_ACCOUNT);
        User payRep = [SELECT Id,HR_Services_Partner__c FROM User WHERE Profile.Name = 'Core Sales - SB' and IsActive = true LIMIT 1];
        User hrRep = [SELECT Id FROM User WHERE Profile.Name = 'HRS PEO-ASO Sales - SB' and IsActive = true LIMIT 1];
        payRep.HR_Services_Partner__c = hrRep.Id;
        update payRep;          
        Account acct1 = new Account (name = 'Test Account1'
                                     ,recordtypeId = coreRt.getRecordTypeId()
                                     ,ownerId = payRep.Id
                                     ,BillingPostalCode = '14514'
                                     ,AccountNumber = '83-1234567'
                                     ,Employees__c = 60
                                     ,Larkspur_401k_Assets__c = 10000
                                     ,Do_Not_Call__c = true
                                     ,Phone = '555-1212');
        insert acct1;
        Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
        Opportunity opp1 = new Opportunity(Name='Opp 1',RecordTypeId=rtCore.getRecordTypeId(), AccountId=acct1.Id, StageName=Label.OppStage_Qualified, OwnerId = payRep.Id, CloseDate=Date.today() + 1);
       Test.startTest();
        insert opp1;
        Test.stopTest();
        Account acct2 = [Select Id,Premier_PBS_Account_Owner__c,Premier_PBS_Hold_Out__c,Premier_PBS_Hold_Out_Expiration__c,PEO_ASO_Permanent_Hold_Out_Description__c from Account where Id=:acct1.Id];
        system.assertEquals(hrRep.Id,acct2.Premier_PBS_Account_Owner__c);
        system.assertEquals(true,acct2.Premier_PBS_Hold_Out__c);
        system.assertEquals(Label.Account_HR_Partnership_Holdout_Reason,acct2.PEO_ASO_Permanent_Hold_Out_Description__c);
    }
    
    static testMethod void testPCRenewalDate() {
        Account acct = new Account(Name='Test Acct');
        insert acct;
        
        ID pcOppRTId = RecordTypeHelper.getRecordType('PC Opportunity Record Type','Opportunity').getRecordTypeId();
        
        Opportunity opp1 = new Opportunity(Name='Opp 1',RecordTypeId=pcOppRTId, AccountId=acct.Id, StageName=Label.OppStage_Qualified, 
                                           CloseDate=Date.today(), OpportunityType__c='Workers Comp', Renewal_Date__c=null);
        OpptyUpdateAcct.TEST_PROCESS_NOW = true;
        insert opp1;
        
        opp1.Renewal_Date__c =  Date.newInstance(2022, 11, 9);

        OpptyUpdateAcct.TEST_PROCESS_NOW = false;
        Test.startTest();
        update opp1;
        Test.stopTest();
        
        acct = getAccount(acct.Id);
        
        System.assertEquals('NOV',acct.Work_Comp_Renewal_Date__c);
        
    } // testPCRenewalDate
} // class OpptyUpdateAcctTest