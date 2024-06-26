/* Test methods for the AccountCheckFlds class

  History
  -------
  02/08/2017 Dan Carmen        Created
  06/14/2017 Dan Carmen        If Lead Loader, update the Employees__c field from NumberOfEmployees
  11/02/2018 Dan Carmen        Call the AcctSensitivityQueueable if a referral source changes
  10/15/2018 Lynn Michels	   If SFDC Data, do not save employee count and create Account Field Tracking record.
  06/24/2021 Dan Carmen        Log Main_Owner_Changed_Date__c if the owner id changes and the owner is a certain type.
  07/01/2021 Jake Hinds        Check if runningUser is null
  12/30/2022 Dan Carmen        Added check for address information

 */
@isTest
private class AccountCheckFldsTest {

   @testSetup
   static void setupData() {
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false, new String[]{'AccountCheckFlds'});
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'AccountCheckFlds'});
      TriggerMethodsTest.saveSetupClasses();

      populateSetting();
   } // setupData
    
   public static HoldOut_ExpirationDates__c hoPAY;
   public static HoldOut_ExpirationDates__c hoMMS;
   public static HoldOut_ExpirationDates__c hoHRS;
   public static HoldOut_ExpirationDates__c hoHNBF;
   public static HoldOut_ExpirationDates__c hoPAS;
   public static HoldOut_ExpirationDates__c hoMS;
    
   // populated custom setting
   public static void populateSetting() {
      if (HoldOut_ExpirationDates__c.getAll().size() == 0) {
        hoPAY = new HoldOut_ExpirationDates__c(Name='PAY',Sales_Org__c='PAY',Account_Hold_Out__c='Hold_Out__c',Account_Hold_Out_Date__c='Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=30,Account_Date_Field__c='First_Run_Date__c',OptySoldNumberOfDays__c=90,
                                                                          TaskNumberOfDays__c=90,UseForOwnershipChange__c=true,HoldOutReasonFld__c='Permanent_Hold_Out_Description__c'
                                                                          ,Account_Owner__c='OwnerId', Opportunity_Date__c='CloseDate');
        hoMMS = new HoldOut_ExpirationDates__c(Name='MMS',Sales_Org__c='MMS',Account_Hold_Out__c='Hold_Out__c',Account_Hold_Out_Date__c='Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=120,Account_Date_Field__c='First_Run_Date__c',OptySoldNumberOfDays__c=120
                                                                          ,TaskNumberOfDays__c=90,UseForOwnershipChange__c=true,HoldOutReasonFld__c='Permanent_Hold_Out_Description__c'
                                                                          ,Account_Owner__c='OwnerId', Opportunity_Date__c='CloseDate');
        hoHRS = new HoldOut_ExpirationDates__c(Name='HRS',Sales_Org__c='HRS',Account_Hold_Out__c='HRS_Hold_Out__c',Account_Hold_Out_Date__c='HRS_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=180,Opportunity_Date__c='CloseDate',OptySoldNumberOfDays__c=180
                                                                          ,TaskNumberOfDays__c=90,HoldOutReasonFld__c='HRS_Permanent_Hold_Out_Description__c'
                                                                          ,UseForOwnershipChange__c=true, Account_Owner__c='HRS_Account_Owner__c');
        hoHNBF = new HoldOut_ExpirationDates__c(Name='HNBF',Sales_Org__c='HNBF',Account_Hold_Out__c='HNBF_Hold_Out__c',Account_Hold_Out_Date__c='HNBF_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=180,Opportunity_Date__c='CloseDate',OptySoldNumberOfDays__c=180
                                                                          ,UseForOwnershipChange__c=true, Account_Owner__c='HNBF_Account_Owner__c');
        hoPAS = new HoldOut_ExpirationDates__c(Name='PAS',Sales_Org__c='PAS',Account_Hold_Out__c='Premier_PBS_Hold_Out__c',Account_Hold_Out_Date__c='Premier_PBS_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=180,Opportunity_Date__c='CloseDate',OptySoldNumberOfDays__c=180
                                                                          ,TaskNumberOfDays__c=90,UseForOwnershipChange__c=true,HoldOutReasonFld__c='PEO_ASO_Permanent_Hold_Out_Description__c'
                                                                          ,Account_Owner__c='Premier_PBS_Account_Owner__c');
        hoMS = new HoldOut_ExpirationDates__c(Name='MS',Sales_Org__c='MS',Account_Hold_Out__c='MS_Hold_Out__c',Account_Hold_Out_Date__c='MS_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=null,Opportunity_Date__c=null,OptySoldNumberOfDays__c=null
                                                                          ,UseForOwnershipChange__c=true);
        HoldOut_ExpirationDates__c[] hoList = new HoldOut_ExpirationDates__c[]{hoPAY,hoMMS, hoHRS, hoHNBF, hoPAS,hoMS};
        insert hoList;
     } else {
        hoPAY = HoldOut_ExpirationDates__c.getInstance('PAY');
        hoMMS = HoldOut_ExpirationDates__c.getInstance('MMS');
        hoHRS = HoldOut_ExpirationDates__c.getInstance('HRS');
        hoHNBF = HoldOut_ExpirationDates__c.getInstance('HNBF');
        hoPAS = HoldOut_ExpirationDates__c.getInstance('PAS');
        hoMS = HoldOut_ExpirationDates__c.getInstance('MS');
     }
   } // populateSetting

   static testMethod void testSicCode() {
      Account acct = new Account(Name='Test Account', SIC='1234');
      insert acct;
      acct = [Select Id, Name, SIC, SIC_Code__c from Account where Id=:acct.Id];
      System.assertEquals('1234',acct.SIC);
      System.assertEquals('1234',acct.SIC_Code__c);
      
      acct.SIC_Code__c='2345';
      update acct;
      acct = [Select Id, Name, SIC, SIC_Code__c from Account where Id=:acct.Id];
      System.assertEquals('2345',acct.SIC);
      System.assertEquals('2345',acct.SIC_Code__c);
      
      acct.SIC='3456';
      acct.SIC_Code__c='4567';
      update acct;
      acct = [Select Id, Name, SIC, SIC_Code__c from Account where Id=:acct.Id];
      System.assertEquals('3456',acct.SIC);
      System.assertEquals('3456',acct.SIC_Code__c);
      
      
   } // testSicCode
   
   static testMethod void testAsLeadLoader() {
     AccountJunctionMethodsTest.setupCustomSettings();
      
      User runningUser = UserHelper.getRunningUser();

      ProcessNameMap__c pnm = new ProcessNameMap__c(Name=UserHelper.PREFIX_LL+runningUser.Name,IsActive__c=true);
      insert pnm;

      System.runAs(runningUser) {
         Account acct = new Account(Name='Test Acct', NumberOfEmployees=12);
         insert acct;
         
         acct = [Select Id, Name, NumberOfEmployees, Employees__c from Account where Id=:acct.Id];
         System.assertEquals(12,acct.Employees__c);
         System.assertEquals(12,acct.NumberOfEmployees);
         
         acct.NumberOfEmployees = 15;
         update acct;

         acct = [Select Id, Name, NumberOfEmployees, Employees__c from Account where Id=:acct.Id];
         System.assertEquals(15,acct.Employees__c);
         System.assertEquals(15,acct.NumberOfEmployees);
         
         delete pnm;
         // to reset the attributes
         UserHelper.currentRunningUserId=null;
         
         acct.NumberOfEmployees = 20;
         TriggerMethods.clearVariables();
         update acct;

         acct = [Select Id, Name, NumberOfEmployees, Employees__c from Account where Id=:acct.Id];
         System.assertEquals(15,acct.Employees__c);
         System.assertEquals(15,acct.NumberOfEmployees);
         
      } // System.runAs
      
          
      
   } // testAsLeadLoader
   
   static testMethod void testReferralSources() {
      Referral_Account__c refAcct = new Referral_Account__c(Name='Test RefAcct');
      insert refAcct;
      
      Referral_Contact__c refCtct = new Referral_Contact__c(Name='Test RefCtct', Referral_Account__c=refAcct.Id);
      insert refCtct;
      
      Account acct1 = new Account(Name='TestAcct1', CPA_Name_Ref__c=refCtct.Id);
      Account acct2 = new Account(Name='TestAcct2');
      Account[] accts = new Account[]{acct1,acct2};
      insert accts;
      
      acct2.CheckSensitivityList__c = true;
      acct1.CPA_Name_Ref__c=null;
      acct1.Broker_Name_Ref__c=refCtct.Id;
      update accts;
       
      
   } // testReferralSources
   static testMethod void testUpdateFromSFDCData() {
		Account acct = new Account(Name = 'Test Acct', NumberOfEmployees = 12,EE_Count_From_Risk__c = Date.newInstance(2018, 12, 9));
        insert acct;
        UserHelperTest.setupGenericUsers();
        User sdata = [select id from User where Name = :UserHelper.SFDC_DATA limit 1];

      System.runAs(sdata) {
      	 acct.Employees__c = 55;
         update acct;
      }//end system.runAs   
         acct = [Select Id, Name, NumberOfEmployees, Employees__c from Account where Id=:acct.Id];
         //show that the employee count did not change
         System.assertEquals(12,acct.Employees__c);
         
         List<Account_Field_Tracking__c> aft = new List<Account_Field_Tracking__c>();
         aft = [SELECT Id, Prospect_Client__c, EE_Count_From_Feed__c, EE_Count_From_Risk__c FROM Account_Field_Tracking__c];
         System.assertEquals(1,aft.size());
         System.assertEquals(acct.id,aft[0].Prospect_Client__c);
         System.assertEquals(55,aft[0].EE_Count_From_Feed__c);
         System.assertEquals(12,aft[0].EE_Count_From_Risk__c);
      
   
   }//end testUpdateFromSFDCData
    
    static testMethod void testSMBChannelHoldOut() {
        HoldOut_Dictionary__c hod = new HoldOut_Dictionary__c(Name='Payroll Lost Client',InitialNbrDays__c=365,Next_HO_reason__c=null, Permanent__c=false, Sold_clears_Expiration_Date__c=false, SoldExtendsHoldout__c=null, Use_Opty_Owner__c=true, Not_Sold_clears_Hold_Out__c=false, Min_Employees__c = 1, Max_Employees__c = 19 );
        insert hod;
        
        UserHelperTest.setupGenericUsers();
        
		User[] smbUser = [Select Id, Name from user where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c = 'SMB Channel' limit 1];
      	Account acct = new Account(Name='Account', OwnerId=smbUser[0].Id, Hold_Out__c=false, NumberOfEmployees=5, Type = 'FLEX Client');
		insert acct;
      
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, 'Opportunity');
        Id coreRtId = coreRt.getRecordTypeId();
        
        String[] smbSoldStatus = Label.SMBChannelOwnershipStatus.split(',');
        Opportunity opp = new Opportunity(Name='Opp', OwnerId = acct.OwnerId, AccountId=acct.Id, RecordTypeId=coreRtId, CloseDate=Date.today().addDays(1), StageName=smbSoldStatus[0], Probability=100, Payroll_Unit__c=true, Type = 'Payroll');
        insert opp;
        
        acct.Type = 'Lost Client';
        update acct;
        
        acct = [SELECT Id, Name, Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c FROM Account WHERE Id=:acct.Id];
        
        System.assertEquals(true, acct.Hold_Out__c);
        System.assertEquals(null, acct.Hold_Out_Expiration__c);
        System.assertEquals('Payroll Lost Client', acct.Permanent_Hold_Out_Description__c);
        
   }//end testSMBChannelHoldOut
    
   static testMethod void testOwnerChange() {
      AccountCheckFlds.OWNER_CHANGE_TYPES = new String[]{'All'};
      Account acct = new Account(Name='Test Account', OwnerId=UserInfo.getUserId());
      insert acct;
      acct = [Select Id, Name, Main_Owner_Changed_Date__c from Account where Id=:acct.Id];
      System.assertNotEquals(null,acct.Main_Owner_Changed_Date__c);
   } // testOwnerChange
    
   
} // class AccountCheckFldsTest