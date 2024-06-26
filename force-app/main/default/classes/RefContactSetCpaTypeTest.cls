/* 
 * The test methods for the RefContactSetCpaType class.
*
* History 
* -------
*  01/05/2011 Dan Carmen   Created
   06/28/2012 Dan Carmen   Modified to use JobHelper class
   11/06/2013 Josh Cartwright modified to update referral type picklist field with CPA values
   09/17/2014 J Stouffer   Modified to use a custom setting to specify Referral Lead sources.
   08/30/2016 Dan Carmen   Make sure it only runs for CPAs
   06/22/2020 Dan Carmen   Setup custom settings
   05/18/2021 Carrie Marciano   Changed to use OppStage Labels

*/
@isTest
private class RefContactSetCpaTypeTest {
   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('ReferralContactBefore', true, false, false, false,new String[]{'ReferralAccountMethods'});
      TriggerMethodsTest.saveSetupClasses();
      SRRTransitionHelperTest.setupCustomSettings();
   } // setupData

   // Test the getRefType method.
   static testMethod void testGetRefType() {
      RefContactSetCpaType rcsct = new RefContactSetCpaType();
      System.assertEquals('50 CPA Non-referring',rcsct.getRefType(null));
      System.assertEquals('50 CPA Non-referring',rcsct.getRefType(0));
      System.assertEquals('30 CPA Referring <3/Year',rcsct.getRefType(1));
      System.assertEquals('30 CPA Referring <3/Year',rcsct.getRefType(2));
      System.assertEquals('10 CPA Referring 3-4/Year',rcsct.getRefType(3));
      System.assertEquals('10 CPA Referring 3-4/Year',rcsct.getRefType(4));
      System.assertEquals('5 CPA Referring >4/Year',rcsct.getRefType(5));
      System.assertEquals('5 CPA Referring >4/Year',rcsct.getRefType(6));
      System.assertEquals('5 CPA Referring >4/Year',rcsct.getRefType(100));

   } // testGetRefType
    
   /** Get a Referral_Counter__c record based on the Referral_Contact__c.Id
    */
   public static Referral_Counter__c getCounterByCtct(Id ctctId, Id acctId) {
      Referral_Counter__c counter = 
                            [Select Id
                                               ,X6_Months_Sold__c
                                               ,X6_Months_Any__c
                                               ,X1_Year_Sold__c
                                               ,X1_Year_Any__c
                                               ,X2_Years_Sold__c
                                               ,X2_Years_Any__c
                                               ,Mutual_Clients_Active__c
                                               ,Mutual_Clients_Lost__c
                                               ,Referral_Account__c
                                           From Referral_Counter__c
                                          where Referral_Contact__c = :ctctId
                                            and Referral_Account__c = :acctId];
      return counter;
   } // getCounterByCtct
    
   /** Test with no opportunities.
    */
   static testMethod void testNoOpps() {
    System.debug('testNoOpps');
      Referral_Contact__c rc = createReferral('test1','Test Bus Type');
      createTestCustomSetting();
      User u = [Select Id, Name from User where Profile.Name='System Administrator' and IsActive=true limit 1];
      RefContactSetCpaType rcsct = new RefContactSetCpaType();
      rcsct.busType = 'Test Bus Type';
      System.runAs(u) {
         Test.startTest();
         Database.executeBatch(rcsct,2);
         Test.stopTest();
      }
      // verify referral_counter__c record is created with zeroes
      Referral_Counter__c counter = getCounterByCtct(rc.Id, rc.Referral_Account__c);
      System.assertEquals(0,counter.X6_Months_Sold__c);
      System.assertEquals(0,counter.X6_Months_Any__c);
      System.assertEquals(0,counter.X1_Year_Sold__c);
      System.assertEquals(0,counter.X1_Year_Any__c);
      System.assertEquals(0,counter.X2_Years_Sold__c);
      System.assertEquals(0,counter.X2_Years_Any__c);
      System.assertEquals(0,counter.Mutual_Clients_Active__c);
      System.assertEquals(0,counter.Mutual_Clients_Lost__c);
      System.assertEquals(rc.Referral_Account__c,counter.Referral_Account__c);
      
   } // testNoOpps

   public static string BUS_TYPE='Accounting Firm';
   public static String NOT_SOLD=Label.OppStage_Lost;
   /** Test with two opportunities.
    */
   static testMethod void testMoreOpps() {
      Referral_Contact__c rc = createReferral('test1',BUS_TYPE);
      // save the id of the first referral account
      Id ra1Id = rc.Referral_Account__c;
       
      //josh added second referral account
      Referral_Account__c ra2 = new Referral_Account__C();
      ra2.name='Test Acct2';
      ra2.Street_Address_1__c='456';
      ra2.City__c='rochester';
      ra2.State_Province__c='NY';
      ra2.Zip_Postal_Code__c='14624';
      ra2.Referral_Source_Business_Type__c=BUS_TYPE;
      insert ra2; 

      User u = [Select Id, Name from User where Profile.Name='System Administrator' and IsActive=true limit 1];
      createTestCustomSetting();
      RefContactSetCpaType rcsct = new RefContactSetCpaType();
      rcsct.busType = BUS_TYPE;
      System.runAs(u) {
          
         // mutual clients
         Account acct1 = new Account(Name='Test Acct1', BIS_ID__c = 6, Lost_Date__c=null);
         Account acct2 = new Account(Name='Test Acct2', BIS_ID__c = 7, Lost_Date__c=null);
         Account acct3 = new Account(Name='Test Acct3', BIS_ID__c = 8, Lost_Date__c=Date.today());
         Account[] accts = new Account[]{acct1,acct2,acct3};
         insert accts;

         Opportunity opp1 = new Opportunity(Name='Test Opp 1', AccountId=acct1.Id, LeadSource = 'Test Lead Source', StageName='Sold', Referral_Contact__c=rc.Id, CloseDate=Date.today()); 
         Opportunity opp2 = new Opportunity(Name='Test Opp 2', AccountId=acct1.Id, LeadSource = 'Test Lead Source', StageName='Sold', Referral_Contact__c=rc.Id, CloseDate=Date.today()); 
         Opportunity opp3 = new Opportunity(Name='Test Opp 3', AccountId=acct2.Id, LeadSource = 'Test Lead Source', StageName='Sold', Referral_Contact__c=rc.Id, CloseDate=Date.today().addMonths(-9)); 
         Opportunity opp4 = new Opportunity(Name='Test Opp 4', AccountId=acct1.Id, LeadSource = 'Test Lead Source', StageName= NOT_SOLD, Referral_Contact__c=rc.Id, CloseDate=Date.today().addMonths(-9)); 
         Opportunity opp5 = new Opportunity(Name='Test Opp 5', AccountId=acct1.Id, LeadSource = 'Test Lead Source', StageName='Pending', Referral_Contact__c=rc.Id, CloseDate=Date.today().addMonths(-13)); 
         Opportunity opp6 = new Opportunity(Name='Test Opp 6', AccountId=acct3.Id, LeadSource = 'Test Lead Source', StageName='Sold', Referral_Contact__c=rc.Id, CloseDate=Date.today().addMonths(-13));
         Opportunity opp7 = new Opportunity(Name='Test opp 7', AccountId=acct1.Id, LeadSource = 'Test Lead Source', StageName='Sold', Referral_Contact__c=rc.Id, CloseDate=Date.Today()); 
         Opportunity opp7a = new Opportunity(Name='Test opp 7a', AccountId=acct1.Id, LeadSource = 'Bad Lead Source', StageName='Sold', Referral_Contact__c=rc.Id, CloseDate=Date.Today()); 
                                  
         Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4,opp5,opp6,opp7,opp7a};
         insert opps;
          
         System.debug('testMoreOpps ra2.id='+ra2.Id);
         rc.Referral_Account__c=ra2.id;
         update rc;
         
         rc = [Select Id, Referral_Type__c, Referral_Account__c from Referral_Contact__c where id=:rc.Id];
         //Verify referral type = 50 - this is being set by a workflow.
         //System.assertEquals('50 CPA Non-referring',rc.Referral_Type__c);
         System.assertEquals(rc.Referral_Account__c,ra2.Id);  
          
         Opportunity opp8= new Opportunity(Name='Test opp 8', AccountId=acct1.Id, LeadSource = 'Test Lead Source', StageName='Sold', Referral_Contact__c=rc.Id, CloseDate=Date.Today()); 
         insert opp8;
          
                 
         // mutual clients
         acct1.CPA_Name_Ref__c=rc.Id;
         acct2.CPA_Name_Ref__c=rc.Id;
         acct3.CPA_Name_Ref__c=rc.Id;
         update accts;
 
         Test.startTest();
         Database.executeBatch(rcsct,2);
         Test.stopTest();
      } // System.runAs
      
      rc = [Select Id, Referral_Type__c, Referral_Account__c from Referral_Contact__c where id=:rc.Id];
      //Verify new Referral Type 
      System.assertEquals('5 CPA Referring >4/Year',rc.Referral_Type__c);
 
      System.assertEquals(2,[select count() from Referral_Counter__c where Referral_Contact__c = :rc.Id]);
      // verify results
      Referral_Counter__c counter1 = getCounterByCtct(rc.Id, ra1Id);
      System.assertEquals(3,counter1.X6_Months_Sold__c);
      System.assertEquals(3,counter1.X6_Months_Any__c);
      System.assertEquals(4,counter1.X1_Year_Sold__c);
      System.assertEquals(5,counter1.X1_Year_Any__c);
      System.assertEquals(5,counter1.X2_Years_Sold__c);
      System.assertEquals(7,counter1.X2_Years_Any__c);
      System.assertEquals(0,counter1.Mutual_Clients_Active__c);
      System.assertEquals(0,counter1.Mutual_Clients_Lost__c);
      System.assertEquals(ra1Id,counter1.Referral_Account__c);

      Referral_Counter__c counter2 = getCounterByCtct(rc.Id, ra2.Id);
      System.assertEquals(1,counter2.X6_Months_Sold__c);
      System.assertEquals(1,counter2.X6_Months_Any__c);
      System.assertEquals(1,counter2.X1_Year_Sold__c);
      System.assertEquals(1,counter2.X1_Year_Any__c);
      System.assertEquals(1,counter2.X2_Years_Sold__c);
      System.assertEquals(1,counter2.X2_Years_Any__c);
      System.assertEquals(2,counter2.Mutual_Clients_Active__c);
      System.assertEquals(1,counter2.Mutual_Clients_Lost__c);
      System.assertEquals(rc.Referral_Account__c,counter2.Referral_Account__c);

   } // testMoreOpps
   
   static testMethod void testGetCounter() {
      Referral_Contact__c rc = createReferral('test1','Test Bus Type');
      RefContactSetCpaType rcsct = new RefContactSetCpaType();
      // test creating a counter
      List<Referral_Counter__c> counters = new List<Referral_Counter__c>();
                  Referral_Counter__c[] upsertRCs = new Referral_Counter__c[]{};
      rcsct.getCounter(null, rc, counters, upsertRCs);
      // should be just one record created
      System.assertEquals(1,counters.size());
      // make sure the record matches the contact and account
      Referral_Counter__c counter = counters.get(0);
      System.assertEquals(rc.Id,counter.Referral_Contact__c);
      System.assertEquals(rc.Referral_Account__c,counter.Referral_Account__c);
   } // testGetCounter 
    
   
   /** Create a Referral Contact and Account.
    */
   private static Referral_Contact__c createReferral(String name, String busType) {
      Referral_Account__c ra= new Referral_Account__c();
      ra.Name=name;
      ra.Street_Address_1__c='123';
      ra.City__c='centre';
      ra.State_Province__c='VA';
      ra.Zip_Postal_Code__c='20120';
      ra.Referral_Source_Business_Type__c=busType;
      insert ra;
           
      Referral_Contact__c rc= new Referral_Contact__c();
      rc.Referral_Account__c=ra.id;
      rc.Name=name;
      rc.Phone__c='3456789087';
      insert rc;
      return rc;
   } // createReferral
   
   static void createTestCustomSetting() {
      list<Lead_Source_for_Referrals__c> ls = new list<Lead_Source_for_Referrals__c>();
      ls.add(new Lead_Source_for_Referrals__c(Name = 'Test Lead Source', value__c = 'Test Lead Source', Lead_Source__c = TRUE, ReferralSource__c=RefContactSetCpaType.REF_SOURCE_CPA));   
      ls.add(new Lead_Source_for_Referrals__c(Name = 'Test Bus Type1', value__c = 'Test Bus Type', Business_Type__c = TRUE, ReferralSource__c=RefContactSetCpaType.REF_SOURCE_CPA));
      ls.add(new Lead_Source_for_Referrals__c(Name = 'Test Bus Type', value__c = Bus_Type, Business_Type__c = TRUE, ReferralSource__c=RefContactSetCpaType.REF_SOURCE_CPA));  
      insert ls;
   } // createTestCustomSetting

   static testMethod void testScheduler() {
      TestHelper.testScheduler('testRefContactSetCpaType', new RefContactSetCpaType());
   } // testScheduler

} // RefContactSetCpaTypeTest