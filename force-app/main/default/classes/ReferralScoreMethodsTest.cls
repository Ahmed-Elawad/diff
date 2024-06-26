/* 
 * Test Methods for referral scoring
 *
 * History
 * -------
   05/10/2016 Dan Carmen   Created
   06/19/2020 Dan Carmen   Clean up queries, remove extra code
   01/05/2020 Jake Hinds   Addition of sold oppty tracking
   05/11/2021 Dan Carmen    Clean up code, add Mutual client counts
   05/12/2022 Dan Carmen    Add Opportunity types as a filter
   09/01/2022 Dan Carmen    Fix for Referral Type being set (if different than score fields)
   09/04/2022 Dan Carmen    Ability to calculate sold score if no units based on Lead Source

*/
@isTest
public class ReferralScoreMethodsTest {
    
   public static String DEF_REF_SOURCE = Label.ReferralTypeDefaultSource;
   public static String REF_SOURCE_CPA=Label.ReferralSourceCPA;
   public static String REF_SOURCE_CLIENT=Label.ReferralSourceClient;
   public static String REF_SOURCE_FA=Label.ReferralSourceFA;
   // for testing purposes only
   public static string CPA_BUS_TYPE=Label.ReferralBusTypeCPA;
   public static String REF_SOURCE_BANK='Bank Employee';

   

    @testSetup  
   static void setupData() {    
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='ReferralScoreBatch', Active__c=true, BatchSize__c=10);
      insert abc;
      TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false, new String[]{'OpptyMethods'});  
      TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, new String[]{'OpptyMethods'});   
      TriggerMethodsTest.saveSetupClasses();    
      createTestCustomSettings();
      createReferralSource('Test',CPA_BUS_TYPE);
   } // setupData   

   public static Referral_Account__c v_refAcct;
   public static Account v_acct;
   public static Referral_Contact__c v_refCtct;
   public static Contact v_ctct;
   public static Referral_Contact__c v_refCtct2;
   public static Contact v_ctct2;

   public static Contact createCpa(String name) {
      return createReferralSource(name, CPA_BUS_TYPE);
   } // createCpa

   // Create a Referral Contact and Account.
   public static Contact createReferralSource(String name, String busType) {
      ReferralObjectsSync.SKIP_SYNC=true;
      ReferralAccountMethods.SKIP_TRIGGERS=true;
      ZipCheckOwner.SKIP_TRIGGERS=true;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
 
      
      v_refAcct = new Referral_Account__c(Name=name, Referral_Source_Business_Type__c=busType, Best_CPA_Score_in_Firm__c='A', Managed_by_Channel__c=true);
      insert v_refAcct; 

      v_acct = new Account(Name=name,ShippingStreet='123 Main',ShippingCity='centre',ShippingState='VA',ShippingPostalCode='20120',Referral__c=busType,Mirror_Referral_Account__c = v_refAcct.Id);
      insert v_acct;
      v_refAcct.Account__c = v_acct.Id;
      update v_refAcct;

      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_REFERRAL_CONTACT, ObjectHelper.OBJECT_CONTACT);

      v_refCtct = new Referral_Contact__c(Name=name, Referral_Account__c=v_refAcct.Id, CPA_Referral_Score__c='C');
      v_refCtct2 = new Referral_Contact__c(Name=name+'2', Referral_Account__c=v_refAcct.Id, CPA_Referral_Score__c='B');
      Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{v_refCtct,v_refCtct2};
      insert refCtcts;
                 
      v_ctct = new Contact(AccountId=v_acct.Id, LastName=name, RecordTypeId=rt.getRecordTypeId(),Phone='3456789087',PrimaryReferralType__c=REF_SOURCE_CPA);
      v_ctct.Mirror_Ref_Ctct__c = v_refCtct.Id;
      v_ctct2 = new Contact(AccountId=v_acct.Id, LastName=name+'2', RecordTypeId=rt.getRecordTypeId(),Phone='3456789088',PrimaryReferralType__c=REF_SOURCE_CPA);
      v_ctct2.Mirror_Ref_Ctct__c = v_refCtct2.Id;
      Contact[] ctcts = new Contact[]{v_ctct,v_ctct2};
      insert ctcts;
      v_refCtct.Contact__c=v_ctct.Id;
      v_refCtct2.Contact__c=v_ctct2.Id;
      update refCtcts;
       
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
      return v_ctct;
   } // createReferralSource
   
   public static void queryReferralSource() {
      v_refAcct = [Select Id, Name, Referral_Source_Business_Type__c, Best_CPA_Score_in_Firm__c, Managed_by_Channel__c
                         ,Account__r.Id, Account__r.Referral__c, Account__r.Mirror_Referral_Account__c
                         ,MutualClients__c, MutualClientTier__c, Referral_Type__c
                         ,(Select Id, Name, Referral_Account__c
                                 ,Contact__r.Id, Contact__r.Name, Contact__r.LastName, Contact__r.AccountId, Contact__r.PrimaryReferralType__c
                                 ,Contact__r.Mirror_Ref_Ctct__c
                           From Referral_Contacts__r)
                     From Referral_Account__c
                    Where Name='Test' limit 1];
      v_acct = v_refAcct.Account__r;
      for (Referral_Contact__c refCtct : v_refAcct.Referral_Contacts__r) {
         if (refCtct.Name == 'Test') {
            v_refCtct = refCtct;
            v_ctct = refCtct.Contact__r;
         } else if (refCtct.Name == 'Test2') {
            v_refCtct2 = refCtct;
            v_ctct2 = refCtct.Contact__r;
         }
      }
   } // queryReferralSource
   
   /** Get a Referral_Counter__c record based on the Referral_Contact__c.Id
    */
   public static ReferralCounter__c getCounter(Id ctctId, Id acctId, String refSource) {
      ReferralCounter__c counter = 
                    [Select Id
                           ,X6MonthsSold__c
                           ,X6MonthsAny__c
                           ,X1YearSold__c
                           ,X1YearAny__c
                           ,X2YearsSold__c
                           ,X2YearsAny__c
                           ,Latest_Opportunity_Date__c
                           ,Latest_Sold_Opportunity_Date__c
                           ,MutualAll__c
                           ,MutualClients__c
                           ,ReferralSource2__c
                           ,Contact__c
                           ,Account__c
                       From ReferralCounter__c
                      where Contact__c = :ctctId
                        and Account__c = :acctId limit 1];
      return counter;
   } // getCounter

   public static Lead_Source_for_Referrals__c lsr1 = null;
   public static Lead_Source_for_Referrals__c lsr2 = null;
   public static Lead_Source_for_Referrals__c lsr3 = null;
   public static Lead_Source_for_Referrals__c lsr4 = null;
   public static Lead_Source_for_Referrals__c lsr5 = null;
   public static Lead_Source_for_Referrals__c lsr6 = null;
   public static Lead_Source_for_Referrals__c lsr7 = null;
   
   public static ReferralScoreSetup__c rsCpa1 = null;
   public static ReferralScoreSetup__c rsCpa2 = null;
   public static ReferralScoreSetup__c rsCpa3 = null;
   public static ReferralScoreSetup__c rsCpa4 = null;
   //public static ReferralScoreSetup__c rsCpa5 = null;
   //public static ReferralScoreSetup__c rsCpa6 = null;
   //public static ReferralScoreSetup__c rsCpa7 = null;
   //public static ReferralScoreSetup__c rsCpa8 = null;
   public static ReferralScoreSetup__c rsBank1 = null;
   public static ReferralScoreSetup__c rsBank2 = null;
   public static ReferralScoreSetup__c rsBank3 = null;
   public static ReferralScoreSetup__c rsBank4 = null;
   
   static void createTestCustomSettings() {
      lsr1 = new Lead_Source_for_Referrals__c(Name = 'Test Lead Source', value__c = 'Test Lead Source', Lead_Source__c = TRUE, ReferralSource__c=REF_SOURCE_CPA);   
      lsr2 = new Lead_Source_for_Referrals__c(Name = 'Test Bus Type1', value__c = 'Test Bus Type', Business_Type__c = TRUE);
      lsr3 = new Lead_Source_for_Referrals__c(Name = 'Test Bus Type', value__c = CPA_BUS_TYPE, Business_Type__c = TRUE,ReferralSource__c=REF_SOURCE_CPA);  
      lsr4 = new Lead_Source_for_Referrals__c(Name = 'Test Client Lead Source', value__c = 'Referral-Client', Lead_Source__c = TRUE,ReferralSource__c=REF_SOURCE_CLIENT);  
      lsr5 = new Lead_Source_for_Referrals__c(Name = 'FA', value__c = 'Referral-Financial Advisor', Lead_Source__c = TRUE, ReferralSource__c=REF_SOURCE_FA);   
      lsr6 = new Lead_Source_for_Referrals__c(Name = 'Bank', value__c = 'Bank', Business_Type__c = TRUE,ReferralSource__c=REF_SOURCE_BANK);  
      lsr7 = new Lead_Source_for_Referrals__c(Name = 'Bank Lead Source', value__c = 'Referral - Bank Referral', Lead_Source__c = TRUE, ReferralSource__c=REF_SOURCE_BANK);   
      Lead_Source_for_Referrals__c[] lsrs = new Lead_Source_for_Referrals__c[]{lsr1,lsr2,lsr3,lsr4,lsr5,lsr6,lsr7};
      insert lsrs;

      rsCpa1 = new ReferralScoreSetup__c(Name='CPA1',ReferralSource__c=REF_SOURCE_CPA,ReferralType__c='Bronze',RangeMin__c=0,RangeMax__c=.9,SoldReferrals__c=true,ReferralScore__c='C,D,F',AllowBlankScore__c=true);
      rsCpa2 = new ReferralScoreSetup__c(Name='CPA2',ReferralSource__c=REF_SOURCE_CPA,ReferralType__c='Silver',RangeMin__c=0,RangeMax__c=.9,SoldReferrals__c=true,ReferralScore__c='A,B');
      rsCpa3 = new ReferralScoreSetup__c(Name='CPA3',ReferralSource__c=REF_SOURCE_CPA,ReferralType__c='Gold',RangeMin__c=1,RangeMax__c=4.9,SoldReferrals__c=true);
      rsCpa4 = new ReferralScoreSetup__c(Name='CPA4',ReferralSource__c=REF_SOURCE_CPA,ReferralType__c='Platinum',RangeMin__c=5,RangeMax__c=9999,SoldReferrals__c=true);
      //rsCpa5 = new ReferralScoreSetup__c(Name='CPA5',ReferralSource__c=REF_SOURCE_CPA,ReferralType__c='Bronze',RangeMin__c=0,RangeMax__c=.9,SoldReferrals__c=false,ReferralScore__c='C,D,F',AllowBlankScore__c=true);
      //rsCpa6 = new ReferralScoreSetup__c(Name='CPA6',ReferralSource__c=REF_SOURCE_CPA,ReferralType__c='Silver',RangeMin__c=0,RangeMax__c=.9,SoldReferrals__c=false,ReferralScore__c='A,B');
      //rsCpa7 = new ReferralScoreSetup__c(Name='CPA7',ReferralSource__c=REF_SOURCE_CPA,ReferralType__c='Gold',RangeMin__c=1,RangeMax__c=4.9,SoldReferrals__c=false);
      //rsCpa8 = new ReferralScoreSetup__c(Name='CPA8',ReferralSource__c=REF_SOURCE_CPA,ReferralType__c='Platinum',RangeMin__c=5,RangeMax__c=9999,SoldReferrals__c=false);
      rsBank1 = new ReferralScoreSetup__c(Name='Bank1',ReferralSource__c=REF_SOURCE_BANK,ReferralType__c='Bronze',RangeMin__c=0,RangeMax__c=.9,SoldReferrals__c=false,ManagedByChannel__c='False');
      rsBank2 = new ReferralScoreSetup__c(Name='Bank2',ReferralSource__c=REF_SOURCE_BANK,ReferralType__c='Silver',RangeMin__c=0,RangeMax__c=.9,SoldReferrals__c=false,ManagedByChannel__c='True');
      rsBank3 = new ReferralScoreSetup__c(Name='Bank3',ReferralSource__c=REF_SOURCE_BANK,ReferralType__c='Gold',RangeMin__c=1,RangeMax__c=4.9,SoldReferrals__c=false,ManagedByChannel__c=null);
      rsBank4 = new ReferralScoreSetup__c(Name='Bank4',ReferralSource__c=REF_SOURCE_BANK,ReferralType__c='Platinum',RangeMin__c=5,RangeMax__c=9999,SoldReferrals__c=false,ManagedByChannel__c=null);
       
      ReferralScoreSetup__c afTierA = new ReferralScoreSetup__c(Name='AccountFirmTierA',ReferralSource__c=CPA_BUS_TYPE,ReferralType__c='Tier A',RangeMin__c=1,RangeMax__c=4,MutualClient__c=true);
      ReferralScoreSetup__c afTierB = new ReferralScoreSetup__c(Name='AccountFirmTierB',ReferralSource__c=CPA_BUS_TYPE,ReferralType__c='Tier B',RangeMin__c=5,RangeMax__c=19,MutualClient__c=true);
      ReferralScoreSetup__c afTierC = new ReferralScoreSetup__c(Name='AccountFirmTierC',ReferralSource__c=CPA_BUS_TYPE,ReferralType__c='Tier C',RangeMin__c=20,RangeMax__c=9999,MutualClient__c=true);
      //ReferralScoreSetup__c[] insertRss = new ReferralScoreSetup__c[]{rsCpa1,rsCpa2,rsCpa3,rsCpa4,rsCpa5,rsCpa6,rsCpa7,rsCpa8,afTierA,afTierB,afTierC};
      ReferralScoreSetup__c[] insertRss = new ReferralScoreSetup__c[]{rsCpa1,rsCpa2,rsCpa3,rsCpa4,afTierA,afTierB,afTierC};
      insert insertRss;
   } // createTestCustomSettings

   static void setTestCustomSettings() {
      lsr1 = Lead_Source_for_Referrals__c.getInstance('Test Lead Source');   
      lsr2 = Lead_Source_for_Referrals__c.getInstance('Test Bus Type1');
      lsr3 = Lead_Source_for_Referrals__c.getInstance('Test Bus Type'); 
      lsr4 = Lead_Source_for_Referrals__c.getInstance('Test Client Lead Source');
      lsr5 = Lead_Source_for_Referrals__c.getInstance('FA');
      lsr5 = Lead_Source_for_Referrals__c.getInstance('Bank');
      lsr5 = Lead_Source_for_Referrals__c.getInstance('Bank Lead Source');

      rsCpa1 = ReferralScoreSetup__c.getInstance('CPA1');
      rsCpa2 = ReferralScoreSetup__c.getInstance('CPA2');
      rsCpa3 = ReferralScoreSetup__c.getInstance('CPA3');
      rsCpa4 = ReferralScoreSetup__c.getInstance('CPA4');
      //rsCpa5 = ReferralScoreSetup__c.getInstance('CPA5');
      //rsCpa6 = ReferralScoreSetup__c.getInstance('CPA6');
      //rsCpa7 = ReferralScoreSetup__c.getInstance('CPA7');
      //rsCpa8 = ReferralScoreSetup__c.getInstance('CPA8');
       
      rsBank1 = ReferralScoreSetup__c.getInstance('Bank1');
      rsBank2 = ReferralScoreSetup__c.getInstance('Bank2');
      rsBank3 = ReferralScoreSetup__c.getInstance('Bank3');
      rsBank4 = ReferralScoreSetup__c.getInstance('Bank4');

   } // setTestCustomSettings

   // Test with no referrals
   static testMethod void testNoReferrals() {
      System.debug('testNoReferrals');
      setTestCustomSettings();
      queryReferralSource();
      Contact ctct = v_ctct;
      User usr = UserHelper.getRunningUser();
      ReferralScoreBatch rsb = new ReferralScoreBatch();
      System.runAs(usr) {
         Test.startTest();
         new ReferralScoreBatch().launchBatchJob(ObjectHelper.OBJECT_CONTACT);
         //Database.executeBatch(rsb,30);
         Test.stopTest();
      }
      // since there's no data, no referral counters should have been created
      System.assertEquals(0,[select count() from ReferralCounter__c]);
      //System.assertEquals(1,rsb.referralSourcesFound);

      // verify referral_counter__c record is created with zeroes
      
   } // testNoReferrals

   // Test with referrals
   static testMethod void testWithReferrals() {
      ReferralScoreMethods.SET_CONTACT_REF_SCORE = true;
      setTestCustomSettings();
      queryReferralSource();
      Contact ctct = v_ctct;

      // save the id of the first account
      Id acctId = ctct.AccountId;
      
      // add a second account (the referral source moved companies)
      Account refAcct2 = new Account(Name='Test Acct2');
      refAcct2.ShippingStreet='456';
      refAcct2.ShippingCity='Rochester';
      refAcct2.ShippingState='NY';
      refAcct2.ShippingPostalCode='14624';
      refAcct2.Referral__c=lsr3.Value__c;
      insert refAcct2; 

      User usr = UserHelper.getRunningUser();
      ReferralScoreBatch rsb = new ReferralScoreBatch();

      System.runAs(usr) {
          
         // mutual clients
         Account acct1 = new Account(Name='Test Acct1', BIS_ID__c = 6, Lost_Date__c=null);
         Account acct2 = new Account(Name='Test Acct2', BIS_ID__c = 7, Lost_Date__c=null);
         Account acct3 = new Account(Name='Test Acct3', BIS_ID__c = 8, Lost_Date__c=Date.today());
         Account[] accts = new Account[]{acct1,acct2,acct3};
         insert accts;

         Opportunity opp1 = new Opportunity(Name='Test Opp 1', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started'
                                               , ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today(), Payroll_Units__c = 1.0); 
         Opportunity opp2 = new Opportunity(Name='Test Opp 2', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started'
                                               , ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today(), Payroll_Units__c = 1.0); 
         Opportunity opp3 = new Opportunity(Name='Test Opp 3', AccountId=acct2.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started'
                                               , ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-9), Payroll_Units__c = .5); 
         Opportunity opp4 = new Opportunity(Name='Test Opp 4', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Not Sold'
                                               , ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-9), Payroll_Units__c = 1.0); 
         Opportunity opp5 = new Opportunity(Name='Test Opp 5', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Pending'
                                               , ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-13), Payroll_Units__c = 1.0); 
         Opportunity opp6 = new Opportunity(Name='Test Opp 6', AccountId=acct3.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started'
                                               , ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-13), Payroll_Units__c = 1.0);
         Opportunity opp7 = new Opportunity(Name='Test opp 7', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started'
                                               , ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.Today(), Payroll_Units__c = 1.0); 
         Opportunity opp7a = new Opportunity(Name='Test opp 7a', AccountId=acct1.Id, LeadSource = 'Bad Lead Source', StageName='Sold - Started'
                                               , ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.Today(), Payroll_Units__c = 1.0); 
                                  
         Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4,opp5,opp6,opp7,opp7a};
         insert opps;
         
         Test.setCreatedDate(opp3.Id, Datetime.now().addMonths(-9));
         Test.setCreatedDate(opp4.Id, Datetime.now().addMonths(-9));
         Test.setCreatedDate(opp5.Id, Datetime.now().addMonths(-13));
         Test.setCreatedDate(opp6.Id, Datetime.now().addMonths(-13));
         
         // move the contact to another account
         System.debug('testMoreOpps refAcct2.id='+refAcct2.Id);
         ctct.AccountId=refAcct2.id;
         System.debug('testWithReferrals before updating contact to refAcct2');
         update ctct;
         System.debug('testWithReferrals after updating contact to refAcct2');
         
         //rc = [Select Id, Referral_Type__c, Referral_Account__c from Referral_Contact__c where id=:rc.Id];
         //Verify referral type = 50 - this is being set by a workflow.
         //System.assertEquals('50 CPA Non-referring',rc.Referral_Type__c);
         //System.assertEquals(rc.Referral_Account__c,ra2.Id);  
          
         Opportunity opp8= new Opportunity(Name='Test opp 8', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.Today(), Payroll_Units__c = 1.0); 
         insert opp8;
                 
         // mutual clients
         //acct1.CPA_Name_Ref__c=rc.Id;
         //acct2.CPA_Name_Ref__c=rc.Id;
         //acct3.CPA_Name_Ref__c=rc.Id;
         //update accts;
 
         Test.startTest();
         Database.executeBatch(rsb,20);
         Test.stopTest();
      } // System.runAs

      System.assertEquals(2,[select count() from ReferralCounter__c]);

      // verify results
      ReferralCounter__c counter1 = getCounter(ctct.Id, acctId,REF_SOURCE_CPA);
      System.assertEquals(3,counter1.X6MonthsSold__c);
      System.assertEquals(3,counter1.X6MonthsAny__c);
      System.assertEquals(3.5,counter1.X1YearSold__c);
      System.assertEquals(5,counter1.X1YearAny__c);
      System.assertEquals(4.5,counter1.X2YearsSold__c);
      System.assertEquals(7,counter1.X2YearsAny__c);
      System.assertEquals(0,counter1.MutualClients__c);
      System.assertEquals(lsr1.ReferralSource__c, counter1.ReferralSource2__c);
      System.assertEquals(acctId,counter1.Account__c);

      // verify results
      ReferralCounter__c counter2 = getCounter(ctct.Id, ctct.AccountId,REF_SOURCE_CPA);
      System.assertEquals(1,counter2.X6MonthsSold__c);
      System.assertEquals(1,counter2.X6MonthsAny__c);
      System.assertEquals(1,counter2.X1YearSold__c);
      System.assertEquals(1,counter2.X1YearAny__c);
      System.assertEquals(1,counter2.X2YearsSold__c);
      System.assertEquals(1,counter2.X2YearsAny__c);
      System.assertEquals(lsr1.ReferralSource__c, counter2.ReferralSource2__c);
      //System.assertEquals(0,counter1.MutualClients__c);
      System.assertEquals(ctct.AccountId,counter2.Account__c);

      ctct = [Select Id, ScoreRfrlsSold__c, ScoreTotalRfrls__c from Contact where Id=:ctct.Id];
      System.assertEquals(rsCpa3.ReferralType__c, ctct.ScoreRfrlsSold__c);
      System.assertEquals(rsCpa4.ReferralType__c, ctct.ScoreTotalRfrls__c);
      
      refAcct2 = [Select Id, ScoreRfrlsSold__c, ScoreTotalRfrls__c from Account where Id=:refAcct2.Id];
      //System.assertEquals(rsCpa2.ReferralType__c, refAcct2.ScoreRfrlsSold__c);
      //System.assertEquals(rsCpa6.ReferralType__c, refAcct2.ScoreTotalRfrls__c);
      

   } // testWithReferrals

   // Test with referrals
   @isTest
   static void testWithReferralsOneAccount() {
      ReferralScoreMethods.SET_CONTACT_REF_SCORE = true;
      setTestCustomSettings();
      queryReferralSource();
      Contact ctct = v_ctct;

      // save the id of the first account
      Id acctId = ctct.AccountId;
      
      User usr = UserHelper.getRunningUser();
      ReferralScoreBatch rsb = new ReferralScoreBatch();

      System.runAs(usr) {
          
         // mutual clients
         Account acct1 = new Account(Name='Test Acct1', BIS_ID__c = 6, Lost_Date__c=null);
         Account acct2 = new Account(Name='Test Acct2', BIS_ID__c = 7, Lost_Date__c=null);
         Account acct3 = new Account(Name='Test Acct3', BIS_ID__c = 8, Lost_Date__c=Date.today());
         Account[] accts = new Account[]{acct1,acct2,acct3};
         insert accts;

         Opportunity opp1 = new Opportunity(Name='Test Opp 1', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today(), Payroll_Units__c = 1.0); 
         Opportunity opp2 = new Opportunity(Name='Test Opp 2', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today(), Payroll_Units__c = 1.0); 
         Opportunity opp3 = new Opportunity(Name='Test Opp 3', AccountId=acct2.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-9), Payroll_Units__c = 1.0); 
         Opportunity opp4 = new Opportunity(Name='Test Opp 4', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Not Sold', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-9), Payroll_Units__c = 1.0); 
         Opportunity opp5 = new Opportunity(Name='Test Opp 5', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Pending', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-13), Payroll_Units__c = 1.0); 
         Opportunity opp6 = new Opportunity(Name='Test Opp 6', AccountId=acct3.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-13), Payroll_Units__c = 1.0);
         Opportunity opp7 = new Opportunity(Name='Test opp 7', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.Today(), Payroll_Units__c = 1.0); 
         Opportunity opp7a = new Opportunity(Name='Test opp 7a', AccountId=acct1.Id, LeadSource = 'Bad Lead Source', StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.Today(), Payroll_Units__c = 1.0); 
                                  
         Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4,opp5,opp6,opp7,opp7a};
         insert opps;
         
         Test.setCreatedDate(opp3.Id, Datetime.now().addMonths(-9));
         Test.setCreatedDate(opp4.Id, Datetime.now().addMonths(-9));
         Test.setCreatedDate(opp5.Id, Datetime.now().addMonths(-13));
         Test.setCreatedDate(opp6.Id, Datetime.now().addMonths(-13));

         // mutual clients
         //acct1.CPA_Name_Ref__c=rc.Id;
         //acct2.CPA_Name_Ref__c=rc.Id;
         //acct3.CPA_Name_Ref__c=rc.Id;
         //update accts;
 
         Test.startTest();
         Database.executeBatch(rsb,20);
         Test.stopTest();
      } // System.runAs

      System.assertEquals(1,[select count() from ReferralCounter__c]);

      // verify results
      ReferralCounter__c counter1 = getCounter(ctct.Id, acctId,REF_SOURCE_CPA);
      System.assertEquals(3,counter1.X6MonthsSold__c);
      System.assertEquals(3,counter1.X6MonthsAny__c);
      System.assertEquals(4,counter1.X1YearSold__c);
      System.assertEquals(5,counter1.X1YearAny__c);
      System.assertEquals(5,counter1.X2YearsSold__c);
      System.assertEquals(7,counter1.X2YearsAny__c);
      System.assertEquals(0,counter1.MutualClients__c);
      System.assertEquals(lsr1.ReferralSource__c, counter1.ReferralSource2__c);
      System.assertEquals(acctId,counter1.Account__c);

      ctct = [Select Id, AccountId, ScoreRfrlsSold__c from Contact where Id=:ctct.Id];
      System.assertEquals(rsCpa3.ReferralType__c, ctct.ScoreRfrlsSold__c);
      
      //Account acct = [Select Id, Name, ScoreRfrlsSold__c from Account where Id=:ctct.AccountId];
      //System.assertEquals(rsCpa3.ReferralType__c, acct.ScoreRfrlsSold__c);


   } // testWithReferralsOneAccount

   // Test the account batch
   static testMethod void testAccountBatch() {
      ReferralScoreMethods.SET_CONTACT_REF_SCORE = true;
      setTestCustomSettings();
      queryReferralSource();
      Contact ctct = v_ctct;
       
      Referral_Account__c refAcct = v_refAcct;
      Referral_Contact__c refCtct = v_refCtct;

      // save the id of the first account
      Id acctId = ctct.AccountId;
      
      User usr = UserHelper.getRunningUser();
      ReferralScoreBatch rsb = new ReferralScoreBatch();
      rsb.batchMode = ObjectHelper.OBJECT_ACCOUNT;

      System.runAs(usr) {
          
         // mutual clients
         Account acct1 = new Account(Name='Test Acct1', BIS_ID__c = 6, First_Run_Date__c=Date.today().addDays(-10), Lost_Date__c=null);
         Account acct2 = new Account(Name='Test Acct2', BIS_ID__c = 7, First_Run_Date__c=Date.today().addDays(-10), Lost_Date__c=null);
         Account acct3 = new Account(Name='Test Acct3', BIS_ID__c = 8, Lost_Date__c=Date.today());
         Account[] accts = new Account[]{acct1,acct2,acct3};
         ZipCheckOwner.SKIP_TRIGGERS=true;
         insert accts;

         Opportunity opp1 = new Opportunity(Name='Test Opp 1', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today(), Payroll_Units__c = 1.0); 
         Opportunity opp2 = new Opportunity(Name='Test Opp 2', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today(), Payroll_Units__c = 1.0); 
         Opportunity opp3 = new Opportunity(Name='Test Opp 3', AccountId=acct2.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-9), Payroll_Units__c = 1.0); 
         Opportunity opp4 = new Opportunity(Name='Test Opp 4', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Not Sold', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-9), Payroll_Units__c = 1.0); 
         Opportunity opp5 = new Opportunity(Name='Test Opp 5', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Pending', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-13), Payroll_Units__c = 1.0); 
         Opportunity opp6 = new Opportunity(Name='Test Opp 6', AccountId=acct3.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-13), Payroll_Units__c = 1.0);
         Opportunity opp7 = new Opportunity(Name='Test opp 7', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.Today(), Payroll_Units__c = 1.0); 
         Opportunity opp7a = new Opportunity(Name='Test opp 7a', AccountId=acct1.Id, LeadSource = 'Bad Lead Source', StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.Today(), Payroll_Units__c = 1.0); 
                                  
         Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4,opp5,opp6,opp7,opp7a};
         insert opps;

         Test.setCreatedDate(opp3.Id, Datetime.now().addMonths(-9));
         Test.setCreatedDate(opp4.Id, Datetime.now().addMonths(-9));
         Test.setCreatedDate(opp5.Id, Datetime.now().addMonths(-13));
         Test.setCreatedDate(opp6.Id, Datetime.now().addMonths(-13));
         
         // mutual clients
         acct1.CPA_Name_Ref__c=refCtct.Id;
         acct2.CPA_Name_Ref__c=refCtct.Id;
         acct3.CPA_Name_Ref__c=refCtct.Id;
         update accts;
 
         Test.startTest();
         Database.executeBatch(rsb,20);
         Test.stopTest();
      } // System.runAs

      System.assertEquals(1,[select count() from ReferralCounter__c]);

      // verify results
      //ReferralCounter__c counter1 = getCounter(null, acctId,REF_SOURCE_CPA);
      //System.assertEquals(3,counter1.X6MonthsSold__c);
      //System.assertEquals(3,counter1.X6MonthsAny__c);
      //System.assertEquals(4,counter1.X1YearSold__c);
      //System.assertEquals(5,counter1.X1YearAny__c);
      //System.assertEquals(5,counter1.X2YearsSold__c);
      //System.assertEquals(7,counter1.X2YearsAny__c);
      //System.assertEquals(2,counter1.MutualClients__c);
      //System.assertEquals(lsr1.ReferralSource__c, counter1.ReferralSource2__c);
      //System.assertEquals(acctId,counter1.Account__c);

      //ctct = [Select Id, AccountId, ScoreRfrlsSold__c, ScoreTotalRfrls__c from Contact where Id=:ctct.Id];
      //System.assertEquals(rsCpa3.ReferralType__c, ctct.ScoreRfrlsSold__c);
      //System.assertEquals(rsCpa8.ReferralType__c, ctct.ScoreTotalRfrls__c);
      
      Account acct = [Select Id, Name, ScoreRfrlsSold__c, ScoreTotalRfrls__c from Account where Id=:ctct.AccountId];
      System.assertEquals(rsCpa3.ReferralType__c, acct.ScoreRfrlsSold__c);
      System.assertEquals(rsCpa4.ReferralType__c, acct.ScoreTotalRfrls__c);

      Referral_Account__c refAcct1 = [Select Id, MutualClients__c, MutualClientTier__c from Referral_Account__c where Id=:refAcct.Id];
      System.assertEquals(2,refAcct1.MutualClients__c);
      System.assertEquals('Tier A',refAcct1.MutualClientTier__c);
   } // testAccountBatch

    /*
   // Test with referrals
   static testMethod void testClientReferral() {
      ReferralScoreMethods.SET_CONTACT_REF_SCORE = true;
      createTestCustomSettings();
      Account client1 = new Account(Name='Referring Client', Bis_ID__c=1);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert client1;
      //Contact ctct = createReferralSource('test1',lsr3.Value__c);

      // save the id of the first account
      //Id acctId = ctct.AccountId;
      
      User usr = UserHelper.getRunningUser();
      ReferralScoreBatch rsb = new ReferralScoreBatch(ObjectHelper.OBJECT_ACCOUNT);

      System.runAs(usr) {
          
         // referred clients
         Account acct1 = new Account(Name='Test Acct1', BIS_ID__c = 6, Lost_Date__c=null);
         Account acct2 = new Account(Name='Test Acct2', BIS_ID__c = 7, Lost_Date__c=null);
         Account acct3 = new Account(Name='Test Acct3', BIS_ID__c = null, Lost_Date__c=null);
         Account[] accts = new Account[]{acct1,acct2,acct3};
         insert accts;

         Opportunity opp1 = new Opportunity(Name='Test Opp 1', AccountId=acct1.Id, LeadSource = lsr4.Value__c, StageName='Sold - Started', Client_Referral__c=client1.Id, CloseDate=Date.today()); 
         Opportunity opp2 = new Opportunity(Name='Test Opp 2', AccountId=acct2.Id, LeadSource = lsr4.Value__c, StageName='Sold - Started', Client_Referral__c=client1.Id, CloseDate=Date.today()); 
         Opportunity opp3 = new Opportunity(Name='Test Opp 3', AccountId=acct3.Id, LeadSource = lsr4.Value__c, StageName='Pending', Client_Referral__c=client1.Id, CloseDate=Date.today()); 
                                  
         Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3};
         insert opps;
         
         Test.startTest();
         Database.executeBatch(rsb,20);
         Test.stopTest();
      } // System.runAs

      System.assertEquals(1,[select count() from ReferralCounter__c]);

      // verify results
      ReferralCounter__c counter1 = getCounter(null, client1.Id, ReferralScoreMethods.REF_SOURCE_CLIENT);
      System.assertEquals(2,counter1.X6MonthsSold__c);
      System.assertEquals(3,counter1.X6MonthsAny__c);
      System.assertEquals(2,counter1.X1YearSold__c);
      System.assertEquals(3,counter1.X1YearAny__c);
      System.assertEquals(2,counter1.X2YearsSold__c);
      System.assertEquals(3,counter1.X2YearsAny__c);
      System.assertEquals(0,counter1.MutualClients__c);
      System.assertEquals(lsr4.ReferralSource__c, counter1.ReferralSource2__c);
      System.assertEquals(client1.Id,counter1.Account__c);

      //Account acct = [Select Id, Name, ScoreRfrlsSold__c from Account where Id=:ctct.AccountId];
      //System.assertEquals(rsCpa3.ReferralType__c, acct.ScoreRfrlsSold__c);


   } // testClientReferral
   */
   static testMethod void testScheduler() {
      TestHelper.testScheduler('testReferralScoreBatch', new ReferralScoreBatch());
   } // testScheduler

   //static testMethod void testOld() {
   //   ReferralScoreOppBatch rsob = new ReferralScoreOppBatch();
   //}

   static testMethod void testWithReferralObjects1() {
      ReferralScoreBatch.queryReferralsSeparately = false;
      testWithReferralObjects();
   }

   static testMethod void testWithReferralObjects2() {
      ReferralScoreBatch.queryReferralsSeparately = true;
      testWithReferralObjects();
   }

   private static void testWithReferralObjects() {
      ReferralScoreMethods.SET_CONTACT_REF_SCORE = true;
      setTestCustomSettings();
      queryReferralSource();
      Contact ctctRef = v_ctct;
      Contact ctctRef2 = v_ctct2;
      //ctctRef = [Select Id, AccountId, Name, Mirror_Ref_Ctct__c from Contact where Id = :ctctRef.Id];
      //Account acctRef = [Select Id, Name, Mirror_Referral_Account__c from Account where Id = :ctctRef.AccountId];
      Account acctRef = v_acct;
       
      Referral_Account__c refAcct = v_refAcct;
      Referral_Contact__c refCtct = v_refCtct;
      Referral_Contact__c refCtct2 = v_refCtct2;
      /*
      // the custom object logic will eventually be removed - but to make sure everything is working correctly...
      ReferralObjectsSync.SKIP_SYNC = true;
      Referral_Account__c refAcct = new Referral_Account__c(Name=acctRef.Name, Account__c=acctRef.Id);
      insert refAcct;
      Referral_Contact__c refCtct = new Referral_Contact__c(Name=ctctRef.name, Referral_Account__c=refAcct.Id, Contact__c=ctctRef.Id);
      insert refCtct;
      ReferralObjectsSync.SKIP_SYNC = false;
      
      // link the standard and custom objects together.
      ctctRef.Mirror_Ref_Ctct__c = refCtct.Id;
      update ctctRef;
      acctRef.Mirror_Referral_Account__c = refAcct.Id;
      update acctRef;
      */
      
      User usr = UserHelper.getRunningUser();
      ReferralScoreBatch rsb = new ReferralScoreBatch();
      
      // create an existing history record so the process can update it.
      ReferralScoreHistory__c refScoreHist = new ReferralScoreHistory__c(Name=ctctRef.Name, Contact__c=ctctRef.Id, ReferralSource__c=rsCpa1.ReferralSource__c, ReferralScore__c=rsCpa1.ReferralType__c);
      refScoreHist.StartDate__c = Date.today().addMonths(-6);
      insert refScoreHist;
      
      // create an existing counter record for the contact so the code will reuse it.
      ReferralCounter__c counterFA = new ReferralCounter__c(Account__c=acctRef.Id, Contact__c=ctctRef.Id, ReferralSource2__c=REF_SOURCE_FA);
      ReferralScoreMethods.clearCounter(counterFA,null);
      insert counterFA;
      
      // verify only 1 counter
      System.assertEquals(1,[Select count() from ReferralCounter__c]);
      
      
      System.runAs(usr) {
         // referred clients
         ZipCheckOwner.SKIP_TRIGGERS=true;
         Account acct1 = new Account(Name='Test Acct1', BIS_ID__c = 6, Lost_Date__c=null);
         Account acct2 = new Account(Name='Test Acct2', BIS_ID__c = 7, Lost_Date__c=null);
         Account acct3 = new Account(Name='Test Acct3', BIS_ID__c = null, Lost_Date__c=null);
         // setup mutual clients
         Account acct4 = new Account(Name='Test Acct4', BIS_ID__c = 9, Lost_Date__c=null, First_Run_Date__c=Date.today(), CPA_Name_Ref__c=refCtct.Id);
         Account acct5 = new Account(Name='Test Acct5', BIS_ID__c = null, Lost_Date__c=null, CPA_Name_Ref__c=refCtct.Id);   // not a client
         Account acct6 = new Account(Name='Test Acct6', BIS_ID__c = 11, Lost_Date__c=null, First_Run_Date__c=Date.today(), CPA_Name_Ref__c=refCtct2.Id);
         Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5,acct6};
         insert accts;

         Opportunity opp1 = new Opportunity(Name='Test Opp 1', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctctRef.Id, ReferralAccount__c=ctctRef.AccountId, CloseDate=Date.today(), Payroll_Units__c = 1.0); 
         Opportunity opp2 = new Opportunity(Name='Test Opp 2', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctctRef.Id, ReferralAccount__c=ctctRef.AccountId, CloseDate=Date.today(), Payroll_Units__c = 1.0); 

         Opportunity[] opps = new Opportunity[]{opp1,opp2};
         insert opps;

         // create referrals too
         Referral__c ref1 = new Referral__c(Name='Test Ref1', Account__c=acct1.Id, SellingLeadSource__c=lsr1.Value__c, Selling_Opportunity__c=opp1.Id, ReferralSourceContact__c=ctctRef.Id, ReferralSourceAccount__c=ctctRef.AccountId);
         Referral__c ref2 = new Referral__c(Name='Test Ref2', Account__c=acct2.Id, SellingLeadSource__c=lsr1.Value__c, Selling_Opportunity__c=opp2.Id, ReferralSourceContact__c=ctctRef.Id, ReferralSourceAccount__c=ctctRef.AccountId);
         Referral__c ref3 = new Referral__c(Name='Test Ref3', Account__c=acct3.Id, SellingLeadSource__c=lsr1.Value__c, Selling_Opportunity__c=null, ReferralSourceContact__c=ctctRef.Id, ReferralSourceAccount__c=ctctRef.AccountId);
         Referral__c ref4 = new Referral__c(Name='Test Ref4', Account__c=acct3.Id, SellingLeadSource__c=lsr1.Value__c, Selling_Opportunity__c=null, ReferralSourceContact__c=ctctRef.Id, ReferralSourceAccount__c=ctctRef.AccountId);
         // make this one an FA referral - should be under a different referral count record.
         Referral__c ref5 = new Referral__c(Name='Test Ref5', Account__c=acct3.Id, SellingLeadSource__c=lsr5.Value__c, Selling_Opportunity__c=null, ReferralSourceContact__c=ctctRef.Id, ReferralSourceAccount__c=ctctRef.AccountId);
         Referral__c[] refs = new Referral__c[]{ref1,ref2,ref3,ref4,ref5};
         insert refs;

         Test.setCreatedDate(ref3.Id, DateTime.now().addMonths(-13));         
         Test.setCreatedDate(ref4.Id, DateTime.now().addMonths(-13));         

         Test.startTest();
         Database.executeBatch(rsb,20);
         Test.stopTest();

      } // System.runAs

      // verify there are now 2 referral counters
      System.assertEquals(2,[Select count() from ReferralCounter__c]);

      ReferralCounter__c counter1 = getCounter(ctctRef.Id, ctctRef.AccountId ,REF_SOURCE_CPA);
      System.assertEquals(2,counter1.X6MonthsSold__c);
      System.assertEquals(3,counter1.X6MonthsAny__c);
      System.assertEquals(2,counter1.X1YearSold__c);
      System.assertEquals(3,counter1.X1YearAny__c);
      System.assertEquals(2,counter1.X2YearsSold__c);
      System.assertEquals(5,counter1.X2YearsAny__c);
      System.assertEquals(1,counter1.MutualClients__c);
      System.assertEquals(2,counter1.MutualAll__c);
      System.assertEquals(Date.today(),counter1.Latest_Opportunity_Date__c);
      System.assertEquals(Date.today(),counter1.Latest_Sold_Opportunity_Date__c);

      ReferralCounter__c counter2 = getCounter(ctctRef2.Id, ctctRef.AccountId ,REF_SOURCE_CPA);
      System.assertEquals(0,counter2.X6MonthsSold__c);
      System.assertEquals(0,counter2.X6MonthsAny__c);
      System.assertEquals(0,counter2.X1YearSold__c);
      System.assertEquals(0,counter2.X1YearAny__c);
      System.assertEquals(0,counter2.X2YearsSold__c);
      System.assertEquals(0,counter2.X2YearsAny__c);
      System.assertEquals(1,counter2.MutualClients__c);
      System.assertEquals(1,counter2.MutualAll__c);
      System.assertEquals(null,counter2.Latest_Opportunity_Date__c);
      System.assertEquals(null,counter2.Latest_Sold_Opportunity_Date__c);


      ctctRef = [Select Id, AccountId, Name, LatestReferralDate__c, ScoreRfrlsSold__c, ScoreTotalRfrls__c
                       ,Mirror_Ref_Ctct__r.LatestReferralDate__c
                   from Contact where Id = :ctctRef.Id];
      System.assertEquals(Date.today(), ctctRef.LatestReferralDate__c);
      System.assertEquals(Date.today(), ctctRef.Mirror_Ref_Ctct__r.LatestReferralDate__c);
      System.assertEquals(rsCpa3.ReferralType__c, ctctRef.ScoreRfrlsSold__c);
      System.assertEquals(rsCpa3.ReferralType__c, ctctRef.ScoreTotalRfrls__c);
       
      // a total of three. The one we created previously, plus 2 new ones.
      System.assertEquals(3,[select count() from ReferralScoreHistory__c]);
       
      ReferralScoreMethods.getRefHistories(new Set<Id>{ctctRef.Id});
      ReferralScoreHistory__c hist = ReferralScoreMethods.historyMap.get(ctctRef.id)[0];
      System.assertEquals(1,hist.MutualClients__c);
      System.assertEquals(2,hist.MutualAll__c);
      System.assertEquals(2,hist.Count_Referrals_Sold__c);
      System.assertEquals(3,hist.Count_Total_Referrals__c);
      System.assertEquals(refScoreHist.Id,hist.PreviousReferralScore__c);
       
   } // testWithReferralObjects

   @isTest
   static void testWithReferralsOneAccountNoBatch() {
      ReferralScoreMethods.SET_CONTACT_REF_SCORE = true;
      setTestCustomSettings();
      queryReferralSource();
      Contact ctct = v_ctct;
      Referral_Contact__c refCtct = v_refCtct;
      Referral_Account__c refAcct = v_refAcct;
      refAcct.MutualClients__c = 6;
      refAcct.MutualClientTier__c = 'Tier B';
      ReferralAccountMethods.SKIP_TRIGGERS = true;
      update refAcct;
      ReferralAccountMethods.SKIP_TRIGGERS = false;

      // save the id of the first account
      Id acctId = ctct.AccountId;
       
      // make sure the code won't go down a tier. Set the date to make sure we don't fall in the range.
      Date dateNow = Date.today();
      // to account for the beginning or end of year
      Integer dayOfYear = dateNow.dayOfYear();
      // for the dates that are out of range
      Date startDate2 = (dayOfYear < 180 ? dateNow.addDays(40) : dateNow.addDays(-40));
      Date endDate2 = (dayOfYear < 180 ? dateNow.addDays(45) : dateNow.addDays(-35));
      String dateRange2 = startDate2.month()+'/'+startDate2.day()+'-'+endDate2.month()+'/'+endDate2.day();
      System.debug('testWithReferralsOneAccountNoBatch startDate2='+startDate2+' endDate2='+endDate2+' dateRange2='+dateRange2);
      ReferralScoreMethods.RESET_MUTUALS_KEY = dateRange2;
      
      User usr = UserHelper.getRunningUser();
      ReferralScoreBatch rsb = new ReferralScoreBatch();

      System.runAs(usr) {
          
         // mutual clients
         Account acct1 = new Account(Name='Test Acct1', BIS_ID__c = 6, Lost_Date__c=null);
         Account acct2 = new Account(Name='Test Acct2', BIS_ID__c = 7, Lost_Date__c=null);
         Account acct3 = new Account(Name='Test Acct3', BIS_ID__c = 8, Lost_Date__c=Date.today());
         Account acct4 = new Account(Name='Test Acct4', BIS_ID__c = 9, Lost_Date__c=null, First_Run_Date__c=Date.today(), CPA_Name_Ref__c=refCtct.Id);
         Account acct5 = new Account(Name='Test Acct5', BIS_ID__c = null, Lost_Date__c=null, CPA_Name_Ref__c=refCtct.Id);   // not a client
         Account acct6 = new Account(Name='Test Acct6', BIS_ID__c = 11, Lost_Date__c=null, First_Run_Date__c=Date.today(), CPA_Name_Ref__c=refCtct.Id);
         ZipCheckOwner.SKIP_TRIGGERS=true;
         Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5,acct6};
         insert accts;

         Opportunity opp1 = new Opportunity(Name='Test Opp 1', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today(), Payroll_Units__c = 1.0); 
         Opportunity opp2 = new Opportunity(Name='Test Opp 2', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today(), Payroll_Units__c = 1.0); 
         Opportunity opp3 = new Opportunity(Name='Test Opp 3', AccountId=acct2.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-9), Payroll_Units__c = 1.0); 
         Opportunity opp4 = new Opportunity(Name='Test Opp 4', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Not Sold', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-9), Payroll_Units__c = 1.0); 
         Opportunity opp5 = new Opportunity(Name='Test Opp 5', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Pending', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-13), Payroll_Units__c = 1.0); 
         Opportunity opp6 = new Opportunity(Name='Test Opp 6', AccountId=acct3.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.today().addMonths(-13), Payroll_Units__c = 1.0);
         Opportunity opp7 = new Opportunity(Name='Test opp 7', AccountId=acct1.Id, LeadSource = lsr1.Value__c, StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.Today(), Payroll_Units__c = 1.0); 
         Opportunity opp7a = new Opportunity(Name='Test opp 7a', AccountId=acct1.Id, LeadSource = 'Bad Lead Source', StageName='Sold - Started', ReferralContact__c=ctct.Id, ReferralAccount__c=ctct.AccountId, CloseDate=Date.Today(), Payroll_Units__c = 1.0); 
                                  
         Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4,opp5,opp6,opp7,opp7a};
         insert opps;
         
         Test.setCreatedDate(opp3.Id, Datetime.now().addMonths(-9));
         Test.setCreatedDate(opp4.Id, Datetime.now().addMonths(-9));
         Test.setCreatedDate(opp5.Id, Datetime.now().addMonths(-13));
         Test.setCreatedDate(opp6.Id, Datetime.now().addMonths(-13));
 
         Test.startTest();
         ctct.CalculateScore__c=true;
         update ctct;
         Test.stopTest();
      } // System.runAs

      System.assertEquals(1,[select count() from ReferralCounter__c]);

      // verify results
      ReferralCounter__c counter1 = getCounter(ctct.Id, acctId,REF_SOURCE_CPA);
      System.assertEquals(3,counter1.X6MonthsSold__c);
      System.assertEquals(3,counter1.X6MonthsAny__c);
      System.assertEquals(4,counter1.X1YearSold__c);
      System.assertEquals(5,counter1.X1YearAny__c);
      System.assertEquals(5,counter1.X2YearsSold__c);
      System.assertEquals(7,counter1.X2YearsAny__c);
      System.assertEquals(2,counter1.MutualClients__c);
      System.assertEquals(3,counter1.MutualAll__c);
      System.assertEquals(lsr1.ReferralSource__c, counter1.ReferralSource2__c);
      System.assertEquals(acctId,counter1.Account__c);

      ctct = [Select Id, AccountId, ScoreRfrlsSold__c from Contact where Id=:ctct.Id];
      System.assertEquals(rsCpa3.ReferralType__c, ctct.ScoreRfrlsSold__c);
      
      ReferralScoreMethods.getRefHistories(new Set<Id>{acctId});
      ReferralScoreHistory__c hist = ReferralScoreMethods.historyMap.get(acctId)[0];
      System.assertEquals(2,hist.MutualClients__c);
      System.assertEquals(3,hist.MutualAll__c);
      System.assertEquals(4,hist.Count_Referrals_Sold__c);
      System.assertEquals(5,hist.Count_Total_Referrals__c);
      System.assertEquals(null,hist.PreviousReferralScore__c);
       
      Referral_Account__c checkRefAcct = [Select Id, Name, MutualClients__c, MutualClientTier__c from Referral_Account__c where Id=:refAcct.Id];
      Assert.areEqual(2,checkRefAcct.MutualClients__c);
      // tier shouldn't change even though the number of mutuals has moved down to a lower tier.
      Assert.areEqual('Tier B', checkRefAcct.MutualClientTier__c);

   } // testWithReferralsOneAccountNoBatch
    
   static testMethod void testCustomSettings() {
      ReferralScoreMethods.checkReferralScoreSetupCustomSetting();
      System.assertNotEquals(null,ReferralScoreMethods.refAcctTiers);
      ReferralScoreSetup__c[] acctFirmSetups = ReferralScoreMethods.refAcctTiers.get(CPA_BUS_TYPE);
      System.assertEquals(3,acctFirmSetups.size());
   } // testCustomSettings
    
   static testMethod void testCheckToResetMutuals() {
      Date dateNow = Date.today();
      // to account for the beginning or end of year
      Integer dayOfYear = dateNow.dayOfYear();
      // for the dates that are in range
      Date startDate1 = (dayOfYear > 4 ? dateNow.addDays(-4) : dateNow);
      Date endDate1 = (dayOfYear < 360 ? dateNow.addDays(4) : dateNow);
      System.debug('testheckToResetMutuals startDate1='+startDate1+' endDate1='+endDate1);
      // for the dates that are out of range
      Date startDate2 = (dayOfYear < 180 ? dateNow.addDays(40) : dateNow.addDays(-40));
      Date endDate2 = (dayOfYear < 180 ? dateNow.addDays(45) : dateNow.addDays(-35));
      System.debug('testheckToResetMutuals startDate2='+startDate2+' endDate2='+endDate2);
      String dateRange1 = startDate1.month()+'/'+startDate1.day()+'-'+endDate1.month()+'/'+endDate1.day();
      String dateRange2 = startDate2.month()+'/'+startDate2.day()+'-'+endDate2.month()+'/'+endDate2.day();
      System.debug('testheckToResetMutuals dateRange1='+dateRange1+' dateRange2='+dateRange2);
       
      ReferralScoreMethods.RESET_MUTUALS_KEY = dateRange1;
      System.assertEquals(true,ReferralScoreMethods.checkToResetMutuals());

      ReferralScoreMethods.RESET_MUTUALS_KEY = dateRange2;
      System.assertEquals(false,ReferralScoreMethods.checkToResetMutuals());
   } // testCheckToResetMutuals

   static testMethod void testScheduleBatch() {
      TestHelper.testScheduler('ReferralScoreBatch', new ReferralScoreBatch());
   }

    
} // class ReferralScoreMethodsTest