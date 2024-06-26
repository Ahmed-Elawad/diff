/**********************************************************/
//Created by: DemandGen, Gram Bischof 10/31/2018
//Last Modified: Gram Bischof 2/18/2019
//
//Description: 
//
/*  History
   -------------
   10/29/2019 Cindy Freeman  added lines to test PartnerReferral lookup
   01/13/2020  Dan Carmen            Change to use LeadLoaderConfig__c custom setting when selecting referrals from Lead/Contact
   05/18/2021  Dan Carmen            Updated to pull the stage named from DFR_Stage_conversion__mdt
   05/19/2023  Dan Carmen            Fix for NPE when processing opps.
  
*/
/**********************************************************/
@isTest
public class DG_DFR_ControllerTest {
   public static String QUALIFIED=Label.OppStage_Qualified;
   public static String NOT_SOLD=Label.OppStage_Lost;

   @testSetup
   public static void setup(){ 
      String[] classString1 = new String[]{'CampaignMethods'};
      String[] classString2 = new String[]{'DG_DFR_Controller'};

      TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, false, false, classString1);
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, false, false, classString1);
      TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, classString2);
      TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, false, false, classString2);
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, false, false, classString2);
      TriggerMethodsTest.createTriggerSetting('ReferralTrigger', false, true, false, false, classString2);
      TriggerMethodsTest.saveSetupClasses();


      LeadLoaderConfig__c llc1 = new LeadLoaderConfig__c(Name='WEBLEAD', IsActive__c=true, NSSSource__c='Inbound', StoreOrginalData__c=true, QueueName__c='NSS Inbound Queue', Sales_Org__c='NSS');
      LeadLoaderConfig__c llc2 = new LeadLoaderConfig__c(Name='WEBLEAD-Oasis', IsActive__c=true, NSSSource__c='Inbound-Oasis', StoreOrginalData__c=true, QueueName__c='Oasis Queue', CheckForDuplicate__c=true, Sales_Org__c='Oasis');
      LeadLoaderConfig__c[] llcs = new LeadLoaderConfig__c[]{llc1,llc2};
      insert llcs;

      DFRSettings__c dfrSettings = new DFRSettings__c();
      dfrSettings.Name = 'DFR Settings';
      dfrSettings.DFR_Start_Date__c = date.valueof('2019-05-01');
      insert dfrSettings;

      Campaign camp = new Campaign(Name='Cool Campaign', LeadSource__c='CampLeadSource', Product__c='Prod1', StartDate=Date.today().addDays(-7), IsActive=true);
      insert camp;
      
      Account testAccount = new Account(Name='Test Company');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert testAccount;

      Contact testContact = new Contact(firstName='Test',lastName='Person',email='test@email.com',Contact_Stage__c='Suspect',AccountId=testAccount.id , OwnedByPrev__c ='WEBLEAD'  );
      testContact.LatestCampaign__c=camp.Id;
      testContact.UTM_Medium_Most_Recent__c='UTM_Medium_Most_Recent__c';
      testContact.UTM_Campaign_Most_Recent__c='UTM_Campaign_Most_Recent__c';
      testContact.UTM_Source_Most_Recent__c='UTM_Source_Most_Recent__c';
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert testContact;

      CampaignMember campMem = new CampaignMember(ContactId=testContact.Id, CampaignId=camp.Id);
      insert campMem;
      
    //  demand_funnel__c dfr = new demand_funnel__c(contact__c = testcontact.id, Account__c = testAccount.id, Current_Funnel_Status__c = 'TQO');
    //  insert dfr;

      DFR_Stage_conversion__mdt dsc = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='TQO' limit 1];
      Opportunity opp = new Opportunity (AccountId = testAccount.id , Name = 'Test Opp full test', StageName = dsc.Field_Value__c,NSS_Source__c = 'Inbound', CloseDate = System.today().adddays(30), LeadSource='OppLeadSource');
      insert opp;
      PartnerReferral__c thePartRef = new PartnerReferral__c(FirstName__c='Test',LastName__c='Person',Account__c=testAccount.Id, Contact__c=testContact.Id,Company__c='Test Company');
      insert thePartRef;
      Referral__c theRef = new Referral__c(Name = 'Test Ref', Primary__c = True, SourceContact__C = testContact.Id, Account__c = testContact.AccountId, selling_opportunity__c = opp.id,
                                  DateLeadSubmitted__c = Date.today(), PartnerReferral__c=thePartRef.Id);
      insert theRef;
      thePartRef.Referral__c = theRef.Id;
      update thePartRef;
      Referral__c newRef = new Referral__c(Name = 'Test Ref', Primary__c = True, SourceContact__C = testContact.Id, Account__c = testContact.AccountId,DateLeadSubmitted__c = Date.today());
      insert newRef;
        
   } // setup
   
   public static Campaign getTestCampaign() {
      Campaign camp = [Select Id, Name, LeadSource__c, Product__c from Campaign Where Name='Cool Campaign'];
      return camp;
   } // getTestCampaign
    
   public static Account getTestAccount() {
      Account acct = [Select Id, Name
                            ,(Select Id, FirstName,LastName,Email,Contact_Stage__c,AccountId
                                From Contacts)
                        from Account
                       Where Name='Test Company' limit 1];
      return acct;
   } // getTestAccount
    
   public static Opportunity getTestOpp() {
      Opportunity opp = [Select Id, AccountId, Name, StageName, NSS_Source__c
                           From Opportunity
                          Where Name='Test Opp full test'
                          limit 1];
      return opp;
   } // getTestOpp
    
 /*  public static Demand_Funnel__c getTestDFR() {
      Demand_Funnel__c dfr = [select Contact__c, Account__c, Current_Funnel_Status__c, PartnerReferral__c 
                                from Demand_Funnel__c
                               Where Account__r.Name='Test Company' 
                               limit 1];
      return dfr;
   } // getTestDFR */
    
   public static void resetTriggers() {
      TriggerMethods.clearVariables();
      ReferralTriggerActions.SKIP_TRIGGER=false;
   } // resetTriggers

   public static testMethod void testLeadStageUpdate() {
            
      Lead ld = new Lead(FirstName='Taylor', LastName='Test', Company='Tunes Inc', Email='taylor@test.com', LeadSource='LeadSource1', OWNEDBY__c = 'WEBLEAD');
      insert ld;

      Referral__c theRef = new Referral__c(Name = 'Test Ref', Primary__c = True, SourceLead__C = ld.Id ,DateLeadSubmitted__c = Date.today());
      insert theRef;

      TriggerMethods.clearVariables();
      ld.Lead_Stage__c='TAL';
      update ld;

      Referral__c ref1 =[Select Id, Funnel_Stage__c from Referral__c Where SourceLead__c=:ld.Id];
      System.assertEquals('TAL',ref1.Funnel_Stage__c);
      
   } // testLeadStageUpdate

   public static testMethod void updateRef(){
      //System.assertEquals(null, dfr.Partnerreferral__c);
      Account acc = getTestAccount();
      Contact con = [Select Id from Contact where AccountId=:acc.Id];
      Opportunity theOpp = new Opportunity();
      theOpp.AccountId = acc.Id;
      theOpp.Name = 'Test Opp';
      theOpp.StageName = 'Pending';
      theOpp.CloseDate = System.today().adddays(30);
      theOpp.RecordTypeId = '012500000000n4LAAQ';
      theOpp.NSS_Source__c = 'Inbound';
      insert theOpp; 
      DFR_Stage_conversion__mdt dsc = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='SQO' limit 1];
      
      theOpp.StageName = dsc.Field_Value__c;
      // skip the trigger here because we want it to fire for the Opportunity update
      TriggerMethods.SKIP_TRIGGERS=true;
      Referral__c ref = new Referral__c(Name='Test Referral', SourceContact__c=con.Id, Account__c = acc.Id, Selling_Opportunity__c=theOpp.Id);
      insert ref;

      Test.startTest();
      TriggerMethods.SKIP_TRIGGERS=false;
      resetTriggers();
      System.debug('updateRef before update theOpp');
      update theOpp;
      Test.stopTest();
      List<Opportunity> opp1 = [select id, StageName from Opportunity where id =: theOpp.id];
      // TODO - this doesn't test anything
      system.assertEquals(dsc.Field_Value__c, Opp1[0].StageName);
      ref = [Select Id, Funnel_Stage__c
               from Referral__c
              Where Selling_Opportunity__c=:theOpp.Id];
      // this is based on the mapping in DFR Stage Conversions custom Metadate Type
      System.assertEquals('SQO',ref.Funnel_Stage__c);
        
   } // updateRef

   public static testMethod void UpdateOppDFRPrimary(){
      Opportunity opp = [select id, StageName from Opportunity where Name = 'Test Opp full test'];
      System.assertNotEquals(null, opp);
      Referral__c theRef = [select id, Primary__c,PartnerReferral__c, Selling_Opportunity__c from Referral__c where Selling_Opportunity__c = :opp.Id limit 1];
      System.assertNotEquals(null, theRef);
      Contact testContact = [Select id,Contact_Stage__c,AccountId  From Contact where OwnedByPrev__c ='WEBLEAD' Limit 1 ];
        
      theRef.Primary__c = false;
      DFR_Stage_conversion__mdt dsc = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='SQO' limit 1];
        
      Opp.StageName = dsc.Field_Value__c;
        
      Opportunity theOpp = new Opportunity();
      theOpp.AccountId = testContact.AccountId;
      theOpp.Name = 'Test Opp';
      theOpp.StageName = dsc.Field_Value__c;
      theOpp.CloseDate = System.today().adddays(30);
      theOpp.NSS_Source__c = 'Inbound';
        
      insert theOpp; 
      DG_DFR_Controller.SKIP_FUTURE=false;
      TriggerMethods.clearVariables();
      theRef.Selling_Opportunity__c = theOpp.id;
      Test.startTest();
      update theRef;
      Test.stopTest();
       
      system.assertEquals(dsc.Field_Value__c, theOpp.StageName);
      Referral__c[] ref = [Select Id, Name, PartnerReferral__c from Referral__c where Selling_Opportunity__c = :theOpp.Id];
      System.assertEquals(theRef.PartnerReferral__c, ref.get(0).PartnerReferral__c,'theRef='+theRef.PartnerReferral__c+' ref='+ref.get(0).PartnerReferral__c);
        
   } // UpdateOppDFRPrimary

    public static testMethod void UpdateOppRefnonPrimary(){
        Opportunity opp = [select id, StageName from Opportunity];
        Referral__c theRef = [select id, Primary__c from Referral__c limit 1];
        Contact testContact = [Select id,Contact_Stage__c,AccountId  From Contact where OwnedByPrev__c ='WEBLEAD' Limit 1 ];
        
        Test.startTest();
        theRef.Primary__c = true;
        DFR_Stage_conversion__mdt dsc = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='SQO' limit 1];
        
        Opp.StageName = dsc.Field_Value__c;
        
        Opportunity theOpp = new Opportunity();
        theOpp.AccountId = testContact.AccountId;
        theOpp.Name = 'Test Opp';
        theOpp.StageName = dsc.Field_Value__c;
        theOpp.CloseDate = System.today().adddays(30);
        theOpp.NSS_Source__c = 'Inbound';
        
        insert theOpp; 
        theRef.Selling_Opportunity__c = theOpp.id;
         update theRef;
        Test.stopTest();
       
        system.assertEquals(dsc.Field_Value__c, theOpp.StageName);
    }

    
    public static testMethod void convertMQLLeadToContact(){
        Lead testLead = new Lead(Company='Test Company',firstName='Test',lastName='Person',email='test@email.com',Lead_Stage__c='MQL', OwnedByPrev__c ='WEBLEAD' );
        insert testLead;
        Referral__c theRef = new Referral__c(Name = 'Test Ref', Primary__c = True, SourceLead__C = testLead.Id,DateLeadSubmitted__c = Date.today());
        insert theRef;
        Database.LeadConvertResult lcr;
        
        DG_DFR_Controller.SKIP_FUTURE=true;
        TriggerMethods.clearVariables();
        Test.startTest();
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lcr = Database.convertLead(lc);
        Test.stopTest();
        
        List<Referral__c> refs = [Select id,SourceLead__c,SourceContact__c From Referral__c Where SourceLead__c = :testLead.id limit 1];
        //System.assertEquals(1,dfrs.size());
        System.assertEquals(lcr.getContactId(),refs.get(0).SourceContact__c);
        
    }

    public static testMethod void convertMQLLEadToContactAndOpp(){
        Lead testLead = new Lead(Company='Test Company',firstName='Test',lastName='Person',email='test@email.com',Lead_Stage__c='MQL',OwnedByPrev__c ='WEBLEAD' );
        insert testLead;
        Referral__c theRef = new Referral__c(Name = 'Test Ref', Primary__c = True, SourceLead__C = testLead.Id ,DateLeadSubmitted__c = Date.today());
        insert theRef;
        
        Database.LeadConvertResult lcr;
        
        DG_DFR_Controller.SKIP_FUTURE=true;
        TriggerMethods.clearVariables();
        Test.startTest();
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.id);
        lc.setDoNotCreateOpportunity(true);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lcr = Database.convertLead(lc);
        Test.stopTest();
        
        List<Referral__c> dfrs = [Select id,SourceLead__c,SourceContact__c,Selling_Opportunity__c,PartnerReferral__c From Referral__c Where SourceLead__c = :testLead.id limit 1];
       // System.assertEquals(1,dfrs.size());
        System.assertEquals(lcr.getContactId(),dfrs.get(0).SourceContact__c);
        System.assertEquals(lcr.getOpportunityId(),dfrs.get(0).Selling_Opportunity__c);   
        
    }
     

    static testmethod void testReferralUpdate(){
         Test.startTest();
       
        Contact theCont = [Select FirstName,LastName,Email,Contact_Stage__c,AccountId,Account.Name From Contact Limit 1];
        Referral__c theRef = new Referral__c(Name = 'Test Ref', Primary__c = True,Account__c = theCont.Accountid, SourceContact__C = theCont.id,DateLeadSubmitted__c = Date.today());
        insert theRef;
        PartnerReferral__c thePartRef = new PartnerReferral__c(FirstName__c=theCont.FirstName,LastName__c=theCont.LastName,Account__c=theCont.AccountId, 
               Contact__c=theCont.Id,Company__c=theCont.Account.Name,Referral__c=theRef.Id);
        insert thePartRef;
        theRef.PartnerReferral__c = thePartRef.Id;
        update theRef;
        Referral__c theRef2 = new Referral__c(Name = 'Test Ref', Primary__c = false,Account__c = theCont.Accountid, SourceContact__C = theCont.id,DateLeadSubmitted__c = Date.today());
        insert theRef2;
        PartnerReferral__c thePartRef2 = new PartnerReferral__c(FirstName__c=theCont.FirstName,LastName__c=theCont.LastName,Account__c=theCont.AccountId, 
               Contact__c=theCont.Id,Company__c=theCont.Account.Name,Referral__c=theRef2.Id);
        insert thePartRef2;
        theRef2.PartnerReferral__c = thePartRef2.Id;
        update theRef2;

        DFR_Stage_conversion__mdt dsc = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='TQO' limit 1];
        Opportunity theOpp = new Opportunity();
        theOpp.AccountId = theCont.AccountId;
        theOpp.Name = 'Test Opp';
        theOpp.StageName = dsc.Field_Value__c;
        theOpp.CloseDate = System.today().adddays(30);               
        theOpp.NSS_Source__c = 'Inbound';
        insert theOpp;
       
        Opportunity theOpp2 = new Opportunity();
        theOpp2.AccountId = theCont.AccountId;
        theOpp2.Name = 'Test Opp2';
        theOpp2.StageName = dsc.Field_Value__c;
        theOpp2.CloseDate = System.today().adddays(30);               
        theOpp2.NSS_Source__c = 'Inbound';
        insert theOpp2;

       
        Referral__c nRef = [select id,Name, Primary__c , Selling_Opportunity__c from Referral__c where Primary__c = True and Selling_Opportunity__c != null limit 1];
        nref.Selling_Opportunity__c = theOpp.id;
        update nref;
        theRef.Selling_Opportunity__c = theOpp.id;
        update theRef;
        theRef2.Selling_Opportunity__c = theOpp2.id;
        update nref;
        theRef2.Selling_Opportunity__c = theOpp.id;
        update theRef2;
        
        Referral__c nRef2 = [select id,Name, Primary__c , Selling_Opportunity__c, PartnerReferral__c from Referral__c where id =: nref.id limit 1];
        system.assertEquals(theOpp.id, nRef2.Selling_Opportunity__c);
        Test.stopTest();
        
    } // testReferralUpdate

   static testMethod void testMultipleOppsCreated() {
      Account acct = new Account(Name='ThisIsATestInc');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      Campaign camp = getTestCampaign();
      Campaign camp2 = new Campaign(Name='TestCampaign2',IsActive=true,Product__c='Prod2',LeadSource__c='Camp2LeadSource');
      insert camp2;
      
      Contact ctct = new Contact(AccountId=acct.Id, LastName='LastName',FirstName='FirstName',Contact_Stage__c='MQL', LatestCampaign__c=camp.Id, LeadSource='CtctLeadSource');
      ctct.UTM_Medium_Most_Recent__c='UTM_Medium_Most_Recent__c';
      insert ctct;
      
      Marketing_Call_Tracking__c mct = new Marketing_Call_Tracking__c(Contact__c=ctct.Id, Source__c='TestMethod', Campaign_ID__c=camp.Id, Keywords__c='LotsOfWords');
      mct.MM_Call_Date__c=Date.today();
      mct.utm_content__c = 'utm_content__c';
      mct.querystring__c = 'querystring__c';
      insert mct;
      
    
      Referral__c ref1 = new Referral__c(Name='Referral1',Account__c=acct.Id, SourceContact__c=ctct.Id, Primary__c=true,DateLeadSubmitted__c=Date.today());
      Referral__c ref2 = new Referral__c(Name='Referral2',Account__c=acct.Id, SourceContact__c=ctct.Id, Primary__c=false,DateLeadSubmitted__c=Date.today());
      Referral__c[] refs = new Referral__c[]{ref1,ref2};
      insert refs;
      
      DFR_Stage_conversion__mdt dsc = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='TQO' limit 1];
      DG_DFR_Controller.SKIP_FUTURE=true;
      Opportunity opp1 = new Opportunity(Name='TestOpportunity1',AccountId=acct.Id,CloseDate=Date.today().addDays(7), StageName=dsc.Field_Value__c
                                        ,NSS_Source__c='Inbound');
      Opportunity opp2 = new Opportunity(Name='TestOpportunity2',AccountId=acct.Id,CloseDate=Date.today().addDays(7), StageName=dsc.Field_Value__c
                                        ,NSS_Source__c='Inbound');
      Opportunity[] opps = new Opportunity[]{opp1,opp2};
      insert opps;
      
      // insert a second campaign member - the code should use this one for the next stage
      CampaignMember campMember2 = new CampaignMember(CampaignId=camp2.Id, ContactId=ctct.Id);
      insert campMember2;
      
      OpportunityContactRole ocr1 = new OpportunityContactRole(OpportunityId=opp1.Id, ContactId=ctct.Id, Role='Decision Maker', IsPrimary=true);
      OpportunityContactRole ocr2 = new OpportunityContactRole(OpportunityId=opp2.Id, ContactId=ctct.Id, Role='Decision Maker', IsPrimary=true);
      OpportunityContactRole[] ocrs = new OpportunityContactRole[]{ocr1,ocr2};
      insert ocrs;
      
      resetTriggers();
      ref1.Selling_Opportunity__c=opp1.Id;
      ref2.Selling_Opportunity__c=opp2.Id;
      update refs;
      
      Referral__c checkRef1 = [select Id, Funnel_Stage__c,TQO_Lead_Source__c
                                from Referral__c where Selling_Opportunity__c=:opp1.Id];
      System.assertEquals('TQO',checkRef1.Funnel_Stage__c);
      System.assertEquals('CtctLeadSource',checkRef1.TQO_Lead_Source__c);

 
      Referral__c checkRef2 = [select Id, Funnel_Stage__c, TQO_Lead_Source__c
                                from Referral__c where Selling_Opportunity__c=:opp2.Id];
      System.assertEquals('TQO',checkRef2.Funnel_Stage__c);
      System.assertEquals('CtctLeadSource',checkRef2.TQO_Lead_Source__c);
                                
      resetTriggers();
      DFR_Stage_conversion__mdt dsc2 = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='SQO' limit 1];
      DFR_Stage_conversion__mdt dsc3 = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='Recycle' limit 1];
      opp1.StageName=dsc2.Field_Value__c;
      opp2.StageName=dsc3.Field_Value__c;
      opp2.Reason_Not_Sold__c='Functionality';
      update opps;
      
      checkRef1 = [select Id, Funnel_Stage__c, SQO_Lead_Source__c
                                from Referral__c where Selling_Opportunity__c=:opp1.Id];
      System.assertEquals('SQO',checkRef1.Funnel_Stage__c);
      System.assertEquals('CtctLeadSource',checkRef1.SQO_Lead_Source__c);

      checkRef2 = [select Id, Funnel_Stage__c, EOL_Reason__c
                                from Referral__c where Selling_Opportunity__c=:opp2.Id];

      System.assertEquals('Recycle',checkRef2.Funnel_Stage__c);
      System.assertEquals('Functionality',checkRef2.EOL_Reason__c);
      
   } // testMultipleOppsCreated

} // class DG_DFR_ControllerTest