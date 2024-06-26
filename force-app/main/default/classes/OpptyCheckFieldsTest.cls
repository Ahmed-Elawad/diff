/** Test methods for the OpptyCheckPayroll trigger.
    
  History
  -------
  11/04/2010 Dan Carmen   Created
  03/07/2011 Dan Carmen   Added Core_Setup_Fee_v2__c field.
  09/07/2011 Dan Carmen   Updated primary comp mapping
  11/22/2011 Dan Carmen   Update for Default Product.
  11/28/2012 Dan Carmen   Changes for Primary Competition/Current Method
  01/16/2014 Dan Carmen   Added check that a user is active before adding them to the sales team
  08/02/2016 Dan Carmen   Remove some old NSS code.
  03/27/2017 Cindy Freeman  Changes for new Employees__c field instead of NumberOfEmployees
  01/10/2020 Dan Carmen         Update test, increment API version
  11/30/2020 Dan Carmen   Store the previous probability when it changes.
  12/10/2020 Karthik Pedditi    Added Created by timeframe field. 
  03/16/2021 Karthik Pedditi    Payroll Client Checkbox Functionality
  04/09/2021 Pujitha Madamanchi  Change timeframe to hour from range for consistency.
  04/28/2022 Dan Carmen         Change code to use ZipQueries.getAccountQueryFields
  01/25/2023 Dan Carmen         Changed recursion check because wasn't hitting the trigger for internal referrals without the approval process
  06/21/2023 Dan Carmen         Fixed account query - was getting duplicate fields.
  08/29/2023 Dan Carmen         Add testSkipTriggers
  10/16/2023 Dan Carmen         Updated checkMPSC to be more dynamic
  12/28/2023 Pujitha Madamanchi Move Original PC Type code to execute only on insert

 */
@isTest
private class OpptyCheckFieldsTest {

   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false,false , new String[]{'OpptyCheckFields'});
      TriggerMethodsTest.saveSetupClasses();
      
      Account acct = new Account(Name='Test Account', Type='FLEX Client');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo mmsRT = byNameMap.get(OpportunityCreateCase.RT_OPPTY_MMS);

      Opportunity opp = new Opportunity(AccountId=acct.Id, RecordTypeId=mmsRT.getRecordTypeId(), Name='Test MMS Opportunity', StageName='Pending', CloseDate=Date.today().addDays(7));
      OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
      insert opp;
      System.assertEquals(1, [Select count() from Opportunity where Name='Test MMS Opportunity']);
      OpptyMethods.SKIP_OPPTY_TRIGGERS = false;
      ZipCheckOwner.SKIP_TRIGGERS=false;
   } // setupData
   
   public static Opportunity getTestMMSOpp() {
      Opportunity opp = [Select Id, Name, StageName, CloseDate, Service_Location__c, Payroll_Units__c
                               ,RecordTypeId, RecordType.Name
                               ,AccountId
                               ,Account.Id, Account.Name
                          from Opportunity
                         where Name='Test MMS Opportunity'];
      return opp;
   } // getTestMMSOpp


   // Check the Primary Competition field.
   static testMethod void checkPrimaryComp() {
      System.assertEquals('3 SERVICE',OpptyCheckFields.checkPrimaryComp('3 SERVICE', null));
      System.assertEquals('4 SERVICE',OpptyCheckFields.checkPrimaryComp('4 SERVICE', 'ADP'));
      System.assertEquals('ADP',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'ADP'));

      System.assertEquals('Local Competitor',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'LOC'));
      System.assertEquals('EE Leasing/PEO',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'EE'));
      System.assertEquals('Bank',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'BNK'));
      
      System.assertEquals('Paychex',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'PAX'));
      System.assertEquals('CompuPay',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'CMP'));
      System.assertEquals('PrimePay/Payroll 1',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'PPY'));
      System.assertEquals('Paycor',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'PAC'));
      System.assertEquals('Ceridian',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'CD'));
      System.assertEquals('TPA',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'TPA'));
      System.assertEquals('Wells Fargo',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'WF'));
      System.assertEquals('Intuit - Quickbooks Software',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'INU'));
      System.assertEquals('SurePayroll',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'SUR'));
      System.assertEquals('Unknown',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'UNK'));
      
      System.assertEquals('Other',OpptyCheckFields.checkPrimaryComp('3 SERVICE', 'TEST'));

      System.assertEquals('CPA',OpptyCheckFields.checkPrimaryComp('CPA', null));
      System.assertEquals('CPA',OpptyCheckFields.checkPrimaryComp('5 CPA', null));

      System.assertEquals('Manually',OpptyCheckFields.checkPrimaryComp('COMPUTER', null));
      System.assertEquals('Manually',OpptyCheckFields.checkPrimaryComp('MANUALLY', null));
      System.assertEquals('Manually',OpptyCheckFields.checkPrimaryComp('2 MANUALLY', null));

      System.assertEquals('No Competitor',OpptyCheckFields.checkPrimaryComp('1 NONE', null));
      System.assertEquals('No Competitor',OpptyCheckFields.checkPrimaryComp('9 NEW BUSINESS/NO COMPETITION', null));
      System.assertEquals('No Competitor',OpptyCheckFields.checkPrimaryComp('7 NEW BUSINESS', null));

      System.assertEquals('Paychex',OpptyCheckFields.checkPrimaryComp('PAYCHEX', null));
      System.assertEquals('Unknown',OpptyCheckFields.checkPrimaryComp('UNKNOWN', null));

   } // checkPrimaryComp

   static testMethod void testCheckForZipTier() {
      AccountJunctionMethodsTest.setupCustomSettings();
      
      String testZip = '12345';
      // get zip code assignments
      Id[] excludeUserIds = new Id[]{};
      Map<String,List<Zip_Assignment__c>> zaMapList = ZipCheckOwnerTest.getZaMapList(testZip,excludeUserIds);
      
      // create accounts
      //Account acct1 = new Account(Name='Account 1', BillingPostalCode=testZip, NumberOfEmployees=5, X401k_Large_Market__c=false, X401K_Assets__c=null);      
      //Account acct2 = new Account(Name='Account 2', ShippingPostalCode=testZip, NumberOfEmployees=150, X401k_Large_Market__c=false, X401K_Assets__c=null);
      //Account acct3 = new Account(Name='Account 3', ShippingPostalCode=testZip, NumberOfEmployees=50, X401k_Large_Market__c=false, X401K_Assets__c=1000000);
      //Account acct4 = new Account(Name='Account 4', ShippingPostalCode=testZip, NumberOfEmployees=5, X401k_Large_Market__c=false, X401K_Assets__c=null);
      Account acct1 = new Account(Name='Account 1', AccountNumber='77-1313', Type='Client', BillingPostalCode=testZip, Employees__c=5, NumberOfEmployees=5, Frequency__c='1 Weekly', X401k_Large_Market__c=false, X401K_Assets__c=null,Client_Start_Date__c= Date.Today());
      Account acct2 = new Account(Name='Account 2', ShippingPostalCode=testZip, Employees__c=150, X401k_Large_Market__c=false, X401K_Assets__c=null);
      Account acct3 = new Account(Name='Account 3', ShippingPostalCode=testZip, Employees__c=50, X401k_Large_Market__c=false, X401K_Assets__c=1000000);
      Account acct4 = new Account(Name='Account 4', ShippingPostalCode=testZip, Employees__c=5, X401k_Large_Market__c=false, X401K_Assets__c=null);
      // for checking the default setting
      //Account acct5 = new Account(Name='Account 5', ShippingPostalCode=null, NumberOfEmployees=120, X401k_Large_Market__c=true, X401K_Assets__c=null, Bis_Id__c=1);
      //Account acct6 = new Account(Name='Account 6', ShippingPostalCode=testZip, NumberOfEmployees=120, X401k_Large_Market__c=true, X401K_Assets__c=null,Bis_Id__c=2);
      //Account acct7 = new Account(Name='Account 7', ShippingPostalCode=null, NumberOfEmployees=120, X401k_Large_Market__c=true, X401K_Assets__c=null,Bis_Id__c=null);
      Account acct5 = new Account(Name='Account 5', ShippingPostalCode=null, Employees__c=120, X401k_Large_Market__c=true, X401K_Assets__c=null, Bis_Id__c=1);
      Account acct6 = new Account(Name='Account 6', ShippingPostalCode=testZip, Employees__c=120, X401k_Large_Market__c=true, X401K_Assets__c=null,Bis_Id__c=2);
      Account acct7 = new Account(Name='Account 7', ShippingPostalCode=null, Employees__c=120, X401k_Large_Market__c=true, X401K_Assets__c=null,Bis_Id__c=null);
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5,acct6,acct7};
      insert accts;
      
      // get the Opportunity record types
      Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      
      RecordTypeHelper.getRecordTypesMap(ObjectHelper.OBJECT_OPPTY, byId, byName);
      
      Opportunity opp1a = new Opportunity(Name='Account 1 opp a', AccountId=acct1.Id, RecordTypeId=byName.get(OpportunityCreateCase.RT_OPPTY_CORE).getRecordTypeId(), StageName='Pending', CloseDate=Date.Today());
      Opportunity opp2a = new Opportunity(Name='Account 2 opp a', AccountId=acct2.Id, RecordTypeId=byName.get(OpportunityCreateCase.RT_OPPTY_MMS).getRecordTypeId(), StageName='Pending', CloseDate=Date.Today());
      //Opportunity opp3a = new Opportunity(Name='Account 3 opp a', AccountId=acct3.Id, RecordTypeId=byName.get(OpportunityCreateCase.RT_OPPTY_PEO).getRecordTypeId(), StageName='Pending', CloseDate=Date.Today());
      Opportunity opp4a = new Opportunity(Name='Account 4 opp a', AccountId=acct4.Id, RecordTypeId=byName.get(OpportunityCreateCase.RT_OPPTY_401K).getRecordTypeId(), StageName='Pending', CloseDate=Date.Today());
      Opportunity opp5a = new Opportunity(Name='Account 5 opp a', AccountId=acct5.Id, RecordTypeId=byName.get(OpportunityCreateCase.RT_OPPTY_401K).getRecordTypeId(), StageName='Pending', CloseDate=Date.Today());
      Opportunity opp6a = new Opportunity(Name='Account 6 opp a', AccountId=acct6.Id, RecordTypeId=byName.get(OpportunityCreateCase.RT_OPPTY_401K).getRecordTypeId(), StageName='Pending', CloseDate=Date.Today());

      Opportunity opp7a = new Opportunity(Name='Account 7 opp a', AccountId=acct7.Id, RecordTypeId=byName.get(OpportunityCreateCase.RT_OPPTY_401K).getRecordTypeId(), StageName='Pending', CloseDate=Date.Today());
      
      //Opportunity[] opps = new Opportunity[]{opp1a,opp2a,opp3a,opp4a,opp5a,opp6a,opp7a};
      Opportunity[] opps = new Opportunity[]{opp1a,opp2a,opp4a,opp5a,opp6a,opp7a};
      insert opps;
      
      Id[] oppIds = new Id[]{opp1a.Id,opp2a.Id,opp4a.Id,opp5a.Id,opp6a.Id,opp7a.Id};
      
      Map<Id,Opportunity> oppMap = getOppMap(oppIds);
      
      Opportunity opp1aCheck = oppMap.get(opp1a.Id);
      checkOppZipTier(opp1aCheck,'PAY1',false);
      System.assertEquals(acct1.Type, opp1aCheck.Original_PC_Type__c);
      System.assertEquals(acct1.Client_Start_Date__c, opp1aCheck.Original_PC_Client_Start_Date__c);
      System.assertEquals(acct1.AccountNumber, opp1aCheck.Original_PC_Number__c);
      System.assertEquals(acct1.NumberOfEmployees, opp1aCheck.Employees_Paid_Per_Payroll__c);
      System.assertEquals('52',opp1aCheck.Frequency__c);
   
      checkOppZipTier(oppMap.get(opp2a.Id),'MMS2',false);
      //checkOppZipTier(opp3a.Id,'TESTPAS1',false);
      checkOppZipTier(oppMap.get(opp4a.Id),'HRS1',false);
      // this is false because there's no zip code
      checkOppZipTier(oppMap.get(opp5a.Id),OpptyCheckFields.LARGE_MARKET,false);
      // this is true because there is a zip code
      checkOppZipTier(oppMap.get(opp6a.Id),OpptyCheckFields.LARGE_MARKET,true);
      checkOppZipTier(oppMap.get(opp7a.Id),null,false);

      // update the zip code and bis id on acct7
      acct7.ShippingPostalCode=testZip;
      acct7.Bis_ID__c = 3;
      update acct7;
      
      User[] users = [Select Id from User where IsActive=true and Id not in :excludeUserIds and UserRoleId != null and HR_Person_Id__c != null limit 2];
      // insert the opportunity team members for opp7a.
      OpportunityTeamMember otm1 = new OpportunityTeamMember(OpportunityId=opp7a.Id, UserId=users[0].Id, TeamMemberRole=ZipCheckOwner.AT_INT_WHOLE);
      OpportunityTeamMember otm2 = new OpportunityTeamMember(OpportunityId=opp7a.Id, UserId=users[1].Id, TeamMemberRole=ZipCheckOwner.AT_EXT_WHOLE);
      insert new OpportunityTeamMember[]{otm1,otm2};
      
      TriggerMethods.clearVariables();
      // update opp7a to force the trigger through again
      update opp7a;
      oppIds = new Id[]{opp7a.Id};
      oppMap = getOppMap(oppIds);
      // verify only two team members - shouldn't have created more since they already exist.
      checkOppZipTier(oppMap.get(opp7a.Id),OpptyCheckFields.LARGE_MARKET,true);
      
   } // testCheckForZipTier
   
   public static Map<Id,Opportunity> getOppMap(Id[] oppIds) {
      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>(
                        [Select Id, Name, Zip_Tier__c, Original_PC_Number__c, Original_PC_Type__c,Original_PC_Client_Start_Date__c
                               ,Frequency__c, Employees_Paid_Per_Payroll__c
                               ,(Select Id,TeamMemberRole,UserId From OpportunityTeamMembers
                          Where TeamMemberRole in (:ZipCheckOwner.AT_INT_WHOLE,:ZipCheckOwner.AT_EXT_WHOLE))
                           from Opportunity 
                          where Id = :oppIds]);
      return oppMap;
   } // getOppMap
   
   private static Opportunity checkOppZipTier(Opportunity opp, String zipTier, Boolean hasTeamMembers) {
      System.debug('checkOppZipTier opp Name='+opp.Name+' zipTier='+opp.Zip_Tier__c+' check zipTier='+zipTier+' hasTeamMembers='+hasTeamMembers);
      System.assertEquals(zipTier,opp.Zip_Tier__c);
      if (hasTeamMembers) {
         //System.assertEquals(true,(opp.OpportunityTeamMembers != null && opp.OpportunityTeamMembers.size() == 2));
      } else {
         System.assertEquals(true,(opp.OpportunityTeamMembers == null || opp.OpportunityTeamMembers.isEmpty()));
      }
      return opp;
   } // checkOppZipTier

   static testMethod void testMPSC1() {
      User usr = [Select Id, Name, Sales_Org__c, Zone__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_MMS and Job_Name__c=:UserHelper.JOB_REP limit 1];
      Opportunity opp = getTestMMSOpp();
      opp.OwnerId = usr.Id;
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      update opp;
      OpptyMethods.SKIP_OPPTY_TRIGGERS=false;

       
      testMPSCServiceLocation(usr, opp, null);
   } // testMPSC1

   static testMethod void testMPSC2() {
      User usr = [Select Id, Name, Sales_Org__c, Zone__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_MMS and Job_Name__c=:UserHelper.JOB_REP limit 1];
      Opportunity opp = getTestMMSOpp();
      opp.OwnerId = usr.Id;
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      update opp;
      OpptyMethods.SKIP_OPPTY_TRIGGERS=false;

      String key = OpptyCheckFields.getServiceLocationKey(usr);
      System.debug('testMPSC2 key='+key);
      OpptyMapping__c oppMap = new OpptyMapping__c(Name=key, ServiceLocation__c='MPSC Rochester 940');
      insert oppMap;
      testMPSCServiceLocation(usr, opp, 'MPSC Rochester 940');
   } // testMPSC2

   public static void testMPSCServiceLocation(User usr, Opportunity opp, String serviceLocation) {
      System.debug('testMPSCServiceLocation serviceLocation='+serviceLocation);
      OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
      TriggerMethods.clearVariables();
      System.runAs(usr) {
         opp.Payroll_Units__c = 1;
         update opp;
         opp = [Select Id, Name, Service_Location__c from Opportunity where Id=:opp.Id];
         System.assertEquals(serviceLocation, opp.Service_Location__c);
      } // System.runAs
   } // testMPSCServiceLocation
   
   static testMethod void testChatCampaigns() {
      Campaign campReactive = new Campaign(Name=OpptyCheckFields.CHAT_CAMP_REACTIVE, IsActive=true, StartDate=Date.today().addDays(-7));
      Campaign campProactive = new Campaign(Name=OpptyCheckFields.CHAT_CAMP_PROACTIVE, IsActive=true, StartDate=Date.today().addDays(-7));
      Campaign[] camps = new Campaign[]{campReactive,campProactive};
      insert camps;
      
      Account acct1 = new Account(Name='Account1');
      Account acct2 = new Account(Name='Account2');
      Account acct3 = new Account(Name='Account3');
      Account acct4 = new Account(Name='Account4');
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
      
      Opportunity opp1 = new Opportunity(AccountId=acct1.Id, Name='Opp 1', StageName='Pending', CloseDate=Date.today().addDays(7), Chat_Type__c='Reactive');
      Opportunity opp2 = new Opportunity(AccountId=acct2.Id, Name='Opp 2', StageName='Pending', CloseDate=Date.today().addDays(7), Chat_Type__c='Proactive');
      Opportunity opp3 = new Opportunity(AccountId=acct3.Id, Name='Opp 3', StageName='Pending', CloseDate=Date.today().addDays(7), Campaign__c=campReactive.Id);
      Opportunity opp4 = new Opportunity(AccountId=acct4.Id, Name='Opp 4', StageName='Pending', CloseDate=Date.today().addDays(7), Campaign__c=campProactive.Id);
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4};
      insert opps;
      
      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, Name, Chat_Type__c, Campaign__c from Opportunity where Id in :opps]);
      opp1 = oppMap.get(opp1.Id);
      System.assertEquals('Reactive',opp1.Chat_Type__c);
      System.assertEquals(campReactive.Id, opp1.Campaign__c);

      opp2 = oppMap.get(opp2.Id);
      System.assertEquals('Proactive',opp2.Chat_Type__c);
      System.assertEquals(campProactive.Id, opp2.Campaign__c);

      opp3 = oppMap.get(opp3.Id);
      System.assertEquals('Reactive',opp3.Chat_Type__c);
      System.assertEquals(campReactive.Id, opp3.Campaign__c);

      opp4 = oppMap.get(opp4.Id);
      System.assertEquals('Proactive',opp4.Chat_Type__c);
      System.assertEquals(campProactive.Id, opp4.Campaign__c);
   } // testChatCampaigns

   static testMethod void testupdateTimeframeonOpps() {
      test.startTest();
      Account acc=[SELECT Id FROM ACCOUNT WHERE Name='Test Account' LIMIT 1];
       
      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo mmsRT = byNameMap.get(OpportunityCreateCase.RT_OPPTY_MMS);
       
      Opportunity oppRec = new Opportunity(AccountId=acc.Id, RecordTypeId=mmsRT.getRecordTypeId(), Name='Test updateTimeframeonOpp',NSS_Source__c='Inbound', StageName='Pending', CloseDate=Date.today().addDays(7));
      insert oppRec;
      test.stopTest();
       
      Opportunity checkOPP=[SELECT id,Created_by_Timeframe__c FROM Opportunity WHERE Name='Test updateTimeframeonOpp'];
       
      datetime currentDateTime=Datetime.now();         
      string timeframeCal=  currentDateTime.format(label.CallTime_format,label.CallTime_TimeZone);
      system.assertEquals(timeframeCal, checkOPP.Created_by_Timeframe__c, 'Timeframe Matched');
   }

   static testMethod void testupdatePayrollcheckbox() {
      test.startTest();
      Account acc=[SELECT Id FROM ACCOUNT WHERE Name='Test Account' LIMIT 1];
      
      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo mmsRT = byNameMap.get(OpportunityCreateCase.RT_OPPTY_MMS);
       
      Opportunity oppRec = new Opportunity(AccountId=acc.Id, RecordTypeId=mmsRT.getRecordTypeId(), Name='updatePayrollcheckboxonOpp',StageName='Pending', CloseDate=Date.today().addDays(7));
      insert oppRec;
      test.stopTest();
       
      Opportunity checkOPP=[SELECT id,Payroll_Client__c FROM Opportunity WHERE Name='updatePayrollcheckboxonOpp']; 
       
       system.assertEquals(true, checkOPP.Payroll_Client__c, 'Matched');
    }
    
    static testMethod void testSkipTriggers() {
      Account acct=[SELECT Id FROM ACCOUNT WHERE Name='Test Account' LIMIT 1];
      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo mmsRT = byNameMap.get(OpportunityCreateCase.RT_OPPTY_MMS);
       
      Opportunity oppty = new Opportunity(AccountId=acct.Id, RecordTypeId=mmsRT.getRecordTypeId(), Name='updatePayrollcheckboxonOpp',StageName='Pending', CloseDate=Date.today().addDays(7), SkipTriggers__c=true);
      insert oppty;
       
      oppty = [Select Id, SkipTriggers__c from Opportunity where Id=:oppty.Id];
      Assert.isFalse(oppty.SkipTriggers__c);
      

    } // testSkipTriggers

} // OpptyCheckFieldsTest