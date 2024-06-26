/* 
 * Test methods for CheckRecordAura
 *
 * History
 * -------
   01/15/2019 Dan Carmen     Created
   02/26/2019 Dan Carmen     Change range of 5-9 pilot to 5-19, do a check for virtual user
   04/18/2019 Dan Carmen     Comment out 20-99 code, add code for Inbound 0-19
   05/21/2019 Jake Hinds     Show the banner when lead/contact has 20-49 emps and there's a level 1 mms rep.
   05/31/2019 Jake Hinds     Changing 0-19 to 0-9, commenting out pilot
   08/21/2020 Brandon Vidro  Modified tests to use custom setting
   07/28/2021 Josh Cartwright APR0121853 - added in test for NSS Inbound Banner
   04/11/2022 Shilpa Govindarajulu  APR0133856 - NSS Banner for PEO Product of Interest Lead Routing
   06/01/2022 Pujitha Madamanchi APR0122251 GL CPA deatils message on banner.
   01/03/2023 Pujitha Madamanchi APR0141981 Ecom Abandned Banner.
   11/13/2023 Vinay   APR0157779  Speed To Lead updates.
   01/19/2024 Pujitha Madamanchi   APR0158354  Strategic Accounts/MMS/PEO Banners.
   05/10/2024 Pujitha Madamanchi   Ecom Backend banners
 */
@isTest
private class CheckRecordAuraTest {
   
   public static String ZIP1='14625';
   public static String ZIP2='14626';
    
   public static Date sellingStartDate = Date.newInstance(2019, 5, 15);
   public static Campaign camp;
   @testSetup
   public static void setupData() {
      getCampaign();
      Map<String,List<Zip_Assignment__c>> zaMap = ZipCheckOwnerTest.getZaMapList(ZIP1,new Id[]{});
      // make sure the selling start date is set
      getTestZa(15,UserHelper.SO_CORE, true);
        // create ServiceAgreementTemplateMapping
          List<Virtual_Banner_Settings__c> vbsList = new List<Virtual_Banner_Settings__c>();                    
          vbsList.add(new Virtual_Banner_Settings__c(Name='Inbound Banner',Active__c = true, Employee_Count_Min__c = 0, Employee_Count_Max__c = 9, Message__c = 'This is a 0-9 EE lead. Pass over to Virtual Sales after initial contact attempt'));       
          vbsList.add(new Virtual_Banner_Settings__c(Name='MMS Level 1 Banner',Active__c = true, Employee_Count_Min__c = 20, Employee_Count_Max__c = 49, Message__c = 'STOP and READ: If you are sending this opportunity out for payroll, you must select the MMS rep.'));      
          vbsList.add(new Virtual_Banner_Settings__c(Name='Multi-Cultural Banner',Active__c = true, Employee_Count_Min__c = 0, Employee_Count_Max__c = 99, Zip_Segment_Name__c = 'HISP', Send_to_Virtual__c = 'Spanish', Ethnicity__c = 'HA1;HA2;HA3;HA4;HA5', Message__c = 'This is a Multi-Cultural lead. When creating an Opportunity, the Opportunity is to be routed to the Multi-Cultural Rep')); 
          vbsList.add(new Virtual_Banner_Settings__c(Name='Virtual Channel Banner',Active__c = true, Employee_Count_Min__c = 0, Employee_Count_Max__c = 19, Sales_Division__c = 'SMB Virtual Channel', Message__c = 'This is a lead in a Virtual Channel Payroll territory. Routing should go to Virtual Inbound after initial contact attempt')); 
          vbsList.add(new Virtual_Banner_Settings__c(Name='Veteran Rep Banner',Active__c = true, Employee_Count_Min__c = 10, Employee_Count_Max__c = 19, DateToCheck__c=sellingStartDate, Message__c = 'This is a Veteran Channel Rep Territory - please do not One-and-Done (if applicable).')); 
          vbsList.add(new Virtual_Banner_Settings__c(Name='GL CPA',Active__c = true, Message__c = 'Contact the CPA for GL setup')); 
          vbsList.add(new Virtual_Banner_Settings__c(Name='NSS PEO Product Banner',Active__c = true, Employee_Count_Min__c = 6, Message__c = 'This a PEO specific lead and must be assigned to the Oasis PEO Rep.')); 
          vbsList.add(new Virtual_Banner_Settings__c(Name='Speed To Lead',Active__c = true, Message__c = 'This is Speed To Lead Banner.'));   
          vbsList.add(new Virtual_Banner_Settings__c(Name='Strategic Account',Active__c = true, Message__c = 'Strategic Account')); 
          vbsList.add(new Virtual_Banner_Settings__c(Name='PEO Sales Play',Active__c = true, Message__c = 'PEO Sales Play Banner'));
          vbsList.add(new Virtual_Banner_Settings__c(Name='MMS Sales Play',Active__c = true, Message__c = 'MMS Sales Play Banner'));
       vbsList.add(new Virtual_Banner_Settings__c(Name='Ecom Abandon',Active__c = true, Message__c = 'This is an Ecommerce Abandoned MQL.')); 
      vbsList.add(new Virtual_Banner_Settings__c(Name='Ecom Backend',Active__c = true, Message__c = 'This is an Ecommerce Backend MQL.', Campaign_Id__c = camp.Id)); 
          insert vbsList;
   } // setupData
   
   public static Zip_Assignment__c getTestZa(Integer nbrEmps,String salesOrg, boolean checkSellingStart) {
      Zip_Assignment__c za = [Select Id, Name, User__c
                                    ,User__r.Id
                                    ,User__r.Hire_Date__c
                                    ,User__r.Selling_Start_Date__c
                                    ,User__r.NSS_Team__c
                                    ,User__r.Zone__c
                                    ,Zip_Segment__r.Name
                                From Zip_Assignment__c
                               Where Sales_Org__c = :salesOrg
                                 and Zip_Segment__r.Emps_Min__c <= :nbrEmps
                                 and Zip_Segment__r.Emps_Max__c >= :nbrEmps
                               limit 1];
      // make sure we have a hire date on the user
      if (checkSellingStart) {
         System.assertNotEquals(null, za.User__r.Selling_Start_Date__c);
         System.assertEquals(false,CheckRecordAura.isUserVirtual(za.User__r));
         // set up the criteria so that it will return the appropriate message
        // za.User__r.Selling_Start_Date__c =sellingStartDate.addDays(-7);
         sellingStartDate = za.User__r.Selling_Start_Date__c.addDays(7);
      }
      return za;
   } // getTestZa
    /*
   static testMethod void testPilot5_9Lead() {
      // get the test zip 
      getTestZa(7,UserHelper.SO_CORE);
      CheckRecordAura.overrideInbound = true;
      CheckRecordAura.PILOT_5_9_ACTIVE = true;

      Lead ld1 = new Lead(LastName='TestLead1', Company='Test Company1');
      Lead ld2 = new Lead(LastName='TestLead2', Company='Test Company2', NumberOfEmployees=7);
      Lead ld3 = new Lead(LastName='TestLead3', Company='Test Company3', NumberOfEmployees=7, PostalCode=ZIP2);
      Lead ld4 = new Lead(LastName='TestLead4', Company='Test Company4', NumberOfEmployees=7, PostalCode=ZIP1);
      Lead[] lds = new Lead[]{ld1,ld2,ld3,ld4};
      
      // we don't need the triggers to fire
      LeadMethods.LEAD_BEFORE_EXECUTING = true;
      LeadMethods.LEAD_AFTER_EXECUTING = true;
      insert lds;
      
      Test.startTest();
      String[] msgs = CheckRecordAura.getRecordMsgs(ld1.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ld2.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ld3.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ld4.Id);
      System.assertEquals(1,msgs.size());
      System.assertEquals(Label.CheckRecord_Micro5_9,msgs[0]);

      Test.stopTest();
   } // testPilot5_9Lead
   
   static testMethod void testPilot5_9AcctCtct() {
      CheckRecordAura.overrideInbound = true;
      CheckRecordAura.PILOT_5_9_ACTIVE = true;
      Zip_Assignment__c za = getTestZa(7,UserHelper.SO_CORE);
      
      Account acct1 = new Account(Name='Account1');
      Account acct2 = new Account(Name='Account2', NumberOfEmployees=20, Employees__c=20);
      Account acct3 = new Account(Name='Account3', NumberOfEmployees=7, Employees__c=7, OwnerId=za.User__c,Owner_Zip_Code__c=ZIP1);
      Account[] accts = new Account[]{acct1,acct2,acct3};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
      
      Contact ctct1 = new Contact(LastName='Contact1', AccountId=acct1.Id);
      Contact ctct2 = new Contact(LastName='Contact2', AccountId=acct2.Id);
      Contact ctct3 = new Contact(LastName='Contact3', AccountId=acct3.Id);
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3};
      insert ctcts;
      
      Test.startTest();
      String[] msgs = CheckRecordAura.getRecordMsgs(acct1.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(acct2.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(acct3.Id);
      System.assertEquals(1,msgs.size());
      System.assertEquals(Label.CheckRecord_Micro5_9,msgs[0]);
      
      msgs = CheckRecordAura.getRecordMsgs(ctct1.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ctct2.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ctct3.Id);
      System.assertEquals(1,msgs.size());
      System.assertEquals(Label.CheckRecord_Micro5_9,msgs[0]);
      
     Test.stopTest();

   } // testPilot5_9AcctCtct*/
   static testMethod void testMMSLevel1Lead() {
      // get the test zip 
      getTestZa(25,UserHelper.SO_CORE,false);
      CheckRecordAura.overrideInbound = true;

      Lead ld1 = new Lead(LastName='TestLead1', Company='Test Company1');
      Lead ld2 = new Lead(LastName='TestLead2', Company='Test Company2', NumberOfEmployees=25);
      Lead ld3 = new Lead(LastName='TestLead3', Company='Test Company3', NumberOfEmployees=25, PostalCode=ZIP2);
      Lead ld4 = new Lead(LastName='TestLead4', Company='Test Company4', NumberOfEmployees=25, PostalCode=ZIP1);
      Lead[] lds = new Lead[]{ld1,ld2,ld3,ld4};
      
      // we don't need the triggers to fire
      LeadMethods.LEAD_BEFORE_EXECUTING = true;
      LeadMethods.LEAD_AFTER_EXECUTING = true;
      insert lds;
      
      Test.startTest();
      String[] msgs = CheckRecordAura.getRecordMsgs(ld1.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ld2.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ld3.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ld4.Id);
      System.assertEquals(1,msgs.size());
      System.assertEquals(Label.CheckRecord_MMS_Level_1_Msg,msgs[0]);

      Test.stopTest();
   } // testPilot5_9Lead
   
   static testMethod void testMMSLevel1AcctCtct() {
      CheckRecordAura.overrideInbound = true;
      Zip_Assignment__c za = getTestZa(25,UserHelper.SO_MMS,false);
      
      Account acct1 = new Account(Name='Account1');
      Account acct2 = new Account(Name='Account2', NumberOfEmployees=50, Employees__c=50);
      Account acct3 = new Account(Name='Account3', NumberOfEmployees=25, Employees__c=25, OwnerId=za.User__c,Owner_Zip_Code__c=ZIP1);
      Account[] accts = new Account[]{acct1,acct2,acct3};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
      
      Contact ctct1 = new Contact(LastName='Contact1', AccountId=acct1.Id);
      Contact ctct2 = new Contact(LastName='Contact2', AccountId=acct2.Id);
      Contact ctct3 = new Contact(LastName='Contact3', AccountId=acct3.Id);
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3};
      insert ctcts;
      
      Test.startTest();
      String[] msgs = CheckRecordAura.getRecordMsgs(acct1.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(acct2.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(acct3.Id);
      System.assertEquals(1,msgs.size());
      System.assertEquals(Label.CheckRecord_MMS_Level_1_Msg,msgs[0]);
      
      msgs = CheckRecordAura.getRecordMsgs(ctct1.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ctct2.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ctct3.Id);
      System.assertEquals(1,msgs.size());
      System.assertEquals(Label.CheckRecord_MMS_Level_1_Msg,msgs[0]);
      
     Test.stopTest();

   } // testPilot5_9AcctCtct
   
   static testMethod void testInboundMsgs() {
      CheckRecordAura.overrideInbound = true;
      //CheckRecordAura.INBOUND_0_9_ACTIVE = true;
      //
      Referral_Account__c ra1 = new Referral_Account__c(name = 'RefAcctCreate'
                                       ,Referral_Source_Business_Type__c = 'Strategic Account'
                                       ,Street_Address_1__c = '911 Panorama Trail South'
                                       ,City__c = 'Rochester'
                                       ,State_Province__c = 'NY'
                                       ,Zip_Postal_Code__c = '14586');
      insert ra1;

      User runningUser = [Select Id, Name,ProfileId,Selling_Start_Date__c from User where IsActive=true and NSS_Team__c='VS PAY' and Selling_Start_Date__c != null and Selling_Start_Date__c < :sellingStartDate  limit 1 ];
      LeadMethods.LEAD_BEFORE_EXECUTING = true;
      LeadMethods.LEAD_AFTER_EXECUTING = true;
      Lead ld1 = new Lead(LastName='TestLead1', Company='Test Company1', NumberOfEmployees=2);
      Lead ld2 = new Lead(LastName='TestLead2', Company='Test Company2', NumberOfEmployees=7);
      Lead ld3 = new Lead(LastName='TestLead3', Company='Test Company3', NumberOfEmployees=22);
      Lead ld4 = new Lead(LastName='TestLead4', Company='Test Company4', NumberOfEmployees=15, PostalCode=ZIP1);
      Lead ld5 = new Lead(LastName='TestLead5', Company='Test Company5', NumberOfEmployees=6, Current_Prior_Method__c = 'Advantage HR-PEO');
      Lead ld6 = new Lead(LastName='TestLead6', Company='Test Company6', Referral_National_Account__c=ra1.Id);
      Lead[] lds = new Lead[]{ld1,ld2,ld3,ld4,ld5,ld6};
      insert lds;
      
      Account acct1 = new Account(Name='Account1', NumberOfEmployees=3, Employees__c=3);
      Account acct2 = new Account(Name='Account2', NumberOfEmployees=20, Employees__c=20);
      Account acct3 = new Account(Name='Account3', NumberOfEmployees=7, Employees__c=7);
      Account acct4 = new Account(Name='Account4');
      Account acct5 = new Account(Name='Account3', NumberOfEmployees=7, Employees__c=15, ShippingPostalCode=ZIP1, Owner_Zip_Code__c=ZIP1);
      Account acct6 = new Account(Name='Account6', NumberOfEmployees=6, Employees__c=6, Current_Prior_Method__c = 'HR Select-PEO');
      Account acct7 = new Account(Name='Account7', NumberOfEmployees=20, Employees__c=20, Active_Sales_Play__c = 'PEO');
      Account acct8 = new Account(Name='Account8', NumberOfEmployees=20, Employees__c=20, Active_Sales_Play__c = 'MMS');
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5,acct6,acct7,acct8};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
      
      Contact ctct1 = new Contact(LastName='Contact1', AccountId=acct1.Id, Scheduled_Appt_Date_Time__c = System.now());
      Contact ctct2 = new Contact(LastName='Contact2', AccountId=acct2.Id, Scheduled_Appt_Date_Time__c = null);
      Contact ctct3 = new Contact(LastName='Contact3', AccountId=acct3.Id, Scheduled_Appt_Date_Time__c = null);
      Contact ctct4 = new Contact(LastName='Contact4', AccountId=acct4.Id, Scheduled_Appt_Date_Time__c = null);
      Contact ctct5 = new Contact(LastName='Contact5', AccountId=acct5.Id, Scheduled_Appt_Date_Time__c = System.now());
      Contact ctct6 = new Contact(LastName='Contact6', AccountId=acct6.Id, Scheduled_Appt_Date_Time__c = null);
      Contact ctct7 = new Contact(LastName='Contact7', AccountId=acct7.Id, Scheduled_Appt_Date_Time__c = null);
      Contact ctct8 = new Contact(LastName='Contact8', AccountId=acct8.Id, Scheduled_Appt_Date_Time__c = null);
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4,ctct5,ctct6,ctct7,ctct8};
      insert ctcts;
      
      Test.startTest();
      CheckRecordMsg[] msgs = CheckRecordAura.getRecordMsgs2(ld1.Id);
      System.assertEquals(1,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs2(ld2.Id);
      System.assertEquals(1,msgs.size());

      msgs = CheckRecordAura.getRecordMsgs2(ld3.Id);
      System.assertEquals(0,msgs.size());
      msgs = CheckRecordAura.getRecordMsgs2(ld5.Id);
      System.assertEquals(1,msgs.size());
       
      msgs = CheckRecordAura.getRecordMsgs2(ld6.Id);
      System.assertEquals(1,msgs.size());

      msgs = CheckRecordAura.getRecordMsgs2(acct1.Id);
      System.assertEquals(2,msgs.size());

      msgs = CheckRecordAura.getRecordMsgs2(acct2.Id);
      System.assertEquals(0,msgs.size());

      msgs = CheckRecordAura.getRecordMsgs2(acct3.Id);
      System.assertEquals(1,msgs.size());

      msgs = CheckRecordAura.getRecordMsgs2(acct4.Id);
      System.assertEquals(0,msgs.size());

      msgs = CheckRecordAura.getRecordMsgs2(acct4.Id);
      System.assertEquals(0,msgs.size());

      msgs = CheckRecordAura.getRecordMsgs2(acct6.Id);
      System.assertEquals(1,msgs.size());
       
      msgs = CheckRecordAura.getRecordMsgs2(ctct1.Id);
      System.assertEquals(2,msgs.size());

      msgs = CheckRecordAura.getRecordMsgs2(ctct2.Id);
      System.assertEquals(0,msgs.size());

      msgs = CheckRecordAura.getRecordMsgs2(ctct3.Id);
      System.assertEquals(1,msgs.size());
       msgs = CheckRecordAura.getRecordMsgs2(ctct7.Id);
      System.assertEquals(1,msgs.size());

       msgs = CheckRecordAura.getRecordMsgs2(ctct8.Id);
      System.assertEquals(1,msgs.size());
      
              
      Virtual_Banner_Settings__c vrb = Virtual_Banner_Settings__c.getInstance('Veteran Rep Banner');
      System.debug('testInboundMsgs vrb='+vrb);
      Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
       String orgId=UserInfo.getOrganizationId(); 
       String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
       Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
       String uniqueName=orgId+dateString+RandomId; 
       User u = [Select Id, Name
                           From User
                          Where IsActive=true
                            and Selling_Start_Date__c != null
                            and Selling_Start_Date__c < :vrb.DateToCheck__c
                            and Job_Name__c=:UserHelper.JOB_REP
                          limit 1];
      System.runAs(u){
          Zip_Segment__c seg = new Zip_Segment__c(Name='Channel', Sales_Org__c='PAY');
          insert seg;
          Zip_Assignment__c za=new Zip_Assignment__c(Name=ZIP1,Sales_Org__c='PAY',Segment_Name__c='Channel',Zip_Segment__c=seg.Id, user__c= u.id);
          insert za;      
          list<CheckRecordMsg> msgs1 = CheckRecordAura.getRecordMsgs2(ld4.Id);
          system.debug('testInboundMsgs msgs1='+(msgs1 != null ? msgs1.size() : -1));
          system.debug('testInboundMsgs msgs1='+msgs1);
          //system.debug(msgs + 'test class');
          System.assertEquals(1,msgs1.size());
      }
      
   } // testInboundMsgs

/*
   static testMethod void testPilot20_49Lead() {
      CheckRecordAura.PILOT_5_9_ACTIVE = false;
      CheckRecordAura.PILOT_20_99_ACTIVE = true;
      // get the test zip 
      Zip_Assignment__c za = getTestZa(29);
      System.assertNotEquals(null,za.User__r.Zone__c);
      CheckRecordAura.MMS_PILOT_ZONES.clear();
      CheckRecordAura.MMS_PILOT_ZONES.add(za.User__r.Zone__c);
      CheckRecordAura.PILOT_SEGMENT_NAME=za.Zip_Segment__r.Name;
      CheckRecordAura.overrideInbound = true;

      Lead ld1 = new Lead(LastName='TestLead1', Company='Test Company1');
      Lead ld2 = new Lead(LastName='TestLead2', Company='Test Company2', NumberOfEmployees=29);
      Lead ld3 = new Lead(LastName='TestLead3', Company='Test Company3', NumberOfEmployees=29, PostalCode=ZIP2);
      Lead ld4 = new Lead(LastName='TestLead4', Company='Test Company4', NumberOfEmployees=29, PostalCode=ZIP1);
      Lead[] lds = new Lead[]{ld1,ld2,ld3,ld4};
      
      // we don't need the triggers to fire
      LeadMethods.LEAD_BEFORE_EXECUTING = true;
      LeadMethods.LEAD_AFTER_EXECUTING = true;
      insert lds;
      
      Test.startTest();
      String[] msgs = CheckRecordAura.getRecordMsgs(ld1.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ld2.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ld3.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ld4.Id);
      System.assertEquals(1,msgs.size());
      System.assertEquals(Label.CheckRecord_MMS20_49,msgs[0]);
      
      ld3.PostalCode=Zip1;
      ld4.NumberOfEmployees=15;
      lds = new Lead[]{ld3,ld4};
      update lds;
      
      msgs = CheckRecordAura.getRecordMsgs(ld3.Id);
      System.assertEquals(1,msgs.size());
      System.assertEquals(Label.CheckRecord_MMS20_49,msgs[0]);
      
      msgs = CheckRecordAura.getRecordMsgs(ld4.Id);
      System.assertEquals(0,msgs.size());
      
      Test.stopTest();

   } // testPilot20_49Lead

   static testMethod void testPilot50_99AcctCtct() {
      CheckRecordAura.PILOT_5_9_ACTIVE = false;
      CheckRecordAura.PILOT_20_99_ACTIVE = true;
      // get the test zip 
      Zip_Assignment__c za = getTestZa(77);
      System.assertNotEquals(null,za.User__r.Zone__c);
      CheckRecordAura.SMB_PILOT_ZONES.clear();
      CheckRecordAura.SMB_PILOT_ZONES.add(za.User__r.Zone__c);
      CheckRecordAura.PILOT_SEGMENT_NAME=za.Zip_Segment__r.Name;
      CheckRecordAura.overrideInbound = true;
      
      // setting Owner_Zip_Code__c because we're skipping the triggers at the end.
      Account acct1 = new Account(Name='Account1', ShippingPostalCode=ZIP1, Owner_Zip_Code__c=ZIP1);
      Account acct2 = new Account(Name='Account2', NumberOfEmployees=20, Employees__c=20, ShippingPostalCode=ZIP1, Owner_Zip_Code__c=ZIP1);
      Account acct3 = new Account(Name='Account3', NumberOfEmployees=55, Employees__c=55, ShippingPostalCode=ZIP1, Owner_Zip_Code__c=ZIP1);
      Account acct4 = new Account(Name='Account4', NumberOfEmployees=55, Employees__c=55, ShippingPostalCode=ZIP2, Owner_Zip_Code__c=ZIP2);
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
      
      Contact ctct1 = new Contact(LastName='Contact1', AccountId=acct1.Id);
      Contact ctct2 = new Contact(LastName='Contact2', AccountId=acct2.Id);
      Contact ctct3 = new Contact(LastName='Contact3', AccountId=acct3.Id);
      Contact ctct4 = new Contact(LastName='Contact4', AccountId=acct4.Id);
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;
      
      Test.startTest();
      String[] msgs = CheckRecordAura.getRecordMsgs(acct1.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(acct2.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(acct3.Id);
      System.assertEquals(1,msgs.size());
      System.assertEquals(Label.CheckRecord_SMB50_99,msgs[0]);
      
      msgs = CheckRecordAura.getRecordMsgs(acct4.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ctct1.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ctct2.Id);
      System.assertEquals(0,msgs.size());
      
      msgs = CheckRecordAura.getRecordMsgs(ctct3.Id);
      System.assertEquals(1,msgs.size());
      System.assertEquals(Label.CheckRecord_SMB50_99,msgs[0]);
      
      msgs = CheckRecordAura.getRecordMsgs(ctct4.Id);
      System.assertEquals(0,msgs.size());

      acct4.ShippingPostalCode = ZIP1;
      acct4.Owner_Zip_Code__c = ZIP1;
      acct3.NumberOfEmployees = 15;
      acct3.Employees__c = 15;
      acct2.NumberOfEmployees = 75;
      acct2.Employees__c = 75;
      update accts;
      
      CheckRecordMsg[] msgs2 = CheckRecordAura.getRecordMsgs2(ctct1.Id);
      System.assertEquals(0,msgs.size());
      
      msgs2 = CheckRecordAura.getRecordMsgs2(ctct2.Id);
      System.assertEquals(1,msgs2.size());
      System.assertEquals(Label.CheckRecord_SMB50_99,msgs2[0].message);
      
      msgs2 = CheckRecordAura.getRecordMsgs2(ctct3.Id);
      System.assertEquals(0,msgs2.size());
      
      msgs2 = CheckRecordAura.getRecordMsgs2(ctct4.Id);
      System.assertEquals(1,msgs2.size());
      System.assertEquals(Label.CheckRecord_SMB50_99,msgs2[0].message);


      Test.stopTest();


   } // testPilot50_99AcctCtct
  */ 
  static testMethod void testGlMsgs() {
      CheckRecordAura.overrideInbound = true;
      
      LeadMethods.LEAD_BEFORE_EXECUTING = true;
      LeadMethods.LEAD_AFTER_EXECUTING = true;
      Lead ld = new Lead(LastName='TestLead1', Company='Test Company1', NumberOfEmployees=2);
      insert ld;

      Marketing_Call_Tracking__c theMarkCallTrac = new Marketing_Call_Tracking__c(Lead__c = ld.Id, Source__c='WEBLEAD'
                                                                                 ,gl_Current_Client__c='Yes'
                                                                                 ,gl_Accounting_Professional__c='No'
                                                                                 ,gl_CPA_Processing_On_Your_Behalf__c='Yes'
                                                                                 ,gl_CPA_First_Name__c='FirstName'
                                                                                 ,gl_CPA_Last_Name__c='LastName'
                                                                                 ,gl_CPA_Company_Name__c='Test Company'
                                                                                 ,gl_CPA_Phone__c='9090909090'
                                                                                 ,gl_CPA_Email__c='test@paychextest.com'
                                                                                 ,gl_CPA_ZIP_Code__c='90909');
      insert theMarkCallTrac;
      
      Account acct = new Account(Name='Account1', NumberOfEmployees=3, Employees__c=3); 
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      Contact ctct = new Contact(LastName='Contact1', AccountId=acct.Id);
      insert ctct;
      
      Test.startTest();
      CheckRecordMsg[] msgs = CheckRecordAura.getRecordMsgs2(ld.Id);
      System.assertEquals(2,msgs.size());
      Test.stopTest();
   } // testGlMsgs
   
    static testMethod void testSpeedToLeadBanner() {
      CheckRecordAura.overrideInbound = true;

      LeadMethods.LEAD_BEFORE_EXECUTING = true;
      LeadMethods.LEAD_AFTER_EXECUTING = true;
      Lead ld = new Lead(LastName='TestLead+123323', Company='Test Company+232342', NumberOfEmployees=2, Scheduled_Appt_Date_Time__c = System.now());
      insert ld;
      Account acct = new Account(Name='Account+12313131', NumberOfEmployees=3, Employees__c=3); 
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      Contact ctct = new Contact(LastName='Contact+242421', AccountId=acct.Id, Scheduled_Appt_Date_Time__c = System.now());
      insert ctct;
      
      Test.startTest();
      CheckRecordMsg[] msgs = CheckRecordAura.getRecordMsgs2(ld.Id);
      System.assertEquals(2,msgs.size());
      Test.stopTest();
    }
    
    static campaign getCampaign(){
        if(camp!=null){
             camp = [Select Id from Campaign where Id=:camp.Id limit 1];
        }
       
        if(camp==null){
            camp = new Campaign(Name='AB_EC_Front_End', Originator__c='Marketing', IsActive=true);
        }
        return camp;
    }
    
     static testMethod void testEcomBackend() {
      CheckRecordAura.overrideInbound = true;
      getCampaign();

      LeadMethods.LEAD_BEFORE_EXECUTING = true;
      LeadMethods.LEAD_AFTER_EXECUTING = true;
      
      Account acct = new Account(Name='Account1', NumberOfEmployees=3, Employees__c=25);
      insert acct;
      Contact ctct = new Contact(LastName='Contact1', AccountId=acct.Id, LatestCampaign__c=camp.Id);
      insert ctct;

      Test.startTest();
      CheckRecordMsg[] msgs = CheckRecordAura.getRecordMsgs2(ctct.Id);
      System.assertEquals(1,msgs.size());
      Test.stopTest();
   } // testEcomBackend
} // class CheckRecordAuraTest