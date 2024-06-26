/* 

  History
  -------
  03/22/2022 Dan Carmen          Cleaned up code
  10/12/2023 Carrie Marciano	added code to create banner on Reference Client Retention object
  12/14/2023 Shilpa G			 APR0155814: Added customer intent signal records in test setup and asserts

 */
@IsTest
public class ObjectBannerAuraServiceTest {
    @testSetup
    public static void setupData() {
       ZipCheckOwner.SKIP_TRIGGERS=true;
       TriggerMethods.SKIP_TRIGGERS=true;
       ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
       ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
       OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
       ReferralAccountMethods.SKIP_TRIGGERS=true;
       Id caseCRrt = RecordTypeHelper.getRecordType('Service Support Client Retention', 'Case').getRecordTypeId();
       Id rcrRT = RecordTypeHelper.getRecordType('Reference Client Retention','Reference_Client_Retention__c').getRecordTypeId();
       Id emailRT = RecordTypeHelper.getRecordType('Client Retention - Email Analytics', 'Reference_Client_Retention__c').getRecordTypeId(); 
        
       Referral_Account__c refAcct = new Referral_Account__c(Name='RefAcct', Sensitivity_401_k__c = true, Referral_Source_Business_Type__c = 'Strategic Account');
       insert refAcct;
       Referral_Contact__c refCtct = new Referral_Contact__c(Referral_Account__c=refAcct.Id, Name='Referral Contact', Sensitivity_FSA__c = true);
       insert refCtct;

       Account acct = new Account(Name='Test Account', CPA_Name_Ref__c=refCtct.Id);
       Account acct1 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913', AccountNumber='903-19048033', Bis_ID__c=4759974
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US'); 
       insert new Account[]{acct,acct1};
           
       Contact ctct = new Contact(AccountId=acct.Id, LastName='LastName');
       Contact ctct1 = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct1.id);
       insert new Contact[]{ctct, ctct1};
            
       Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acct.Id, Contact_Name_TAA__c=ctct.Id, CloseDate=Date.today().addDays(7), StageName='Pending'
                                        ,Referral_Account__c=refAcct.Id, Referral_Contact__c=refCtct.Id);
       insert opp;
       OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=opp.Id, ContactId=ctct.Id);
       insert ocr;
       Lead ld = new Lead(Company='Test Lead Co', LastName='LeadLast', Referral_Contact__c=refCtct.Id, Referral_National_Account__c=refAcct.Id);
       insert ld;
        
       // open activity
       Task tsk1 = new Task(WhatId=acct.Id, Subject='Task Account', ActivityDate=Date.today(), Status='Not Started');
       Task tsk2 = new Task(WhoId=ctct.Id, Subject='Task Contact', ActivityDate=Date.today(), Status='Not Started');
       Task tsk3 = new Task(WhatId=opp.Id, Subject='Task Opportunity', ActivityDate=Date.today(), Status='Not Started');
       Task tsk4 = new Task(WhatId=refAcct.Id, Subject='Task Referral Account', ActivityDate=Date.today(), Status='Not Started');
       Task tsk5 = new Task(WhatId=refCtct.Id, Subject='Task Referral Contact', ActivityDate=Date.today(), Status='Not Started');
       Task tsk6 = new Task(WhoId=ld.Id, Subject='Task Lead Contact', ActivityDate=Date.today(), Status='Not Started');
       // closed activity
       Task tsk1a = new Task(WhatId=acct.Id, Subject='Task Account', ActivityDate=Date.today(), Status='Completed');
       Task tsk2a = new Task(WhoId=ctct.Id, Subject='Task Contact', ActivityDate=Date.today(), Status='Completed');
       Task tsk3a = new Task(WhatId=opp.Id, Subject='Task Opportunity', ActivityDate=Date.today(), Status='Completed');
       Task tsk4a = new Task(WhatId=refAcct.Id, Subject='Task Referral Account', ActivityDate=Date.today(), Status='Completed');
       Task tsk5a = new Task(WhatId=refCtct.Id, Subject='Task Referral Contact', ActivityDate=Date.today(), Status='Completed');
       Task tsk6a = new Task(WhoId=ld.Id, Subject='Task Lead Contact', ActivityDate=Date.today(), Status='Completed');
       TaskHelper.SKIP_TRIGGERS=true;
       insert new Task[]{tsk1,tsk2,tsk3,tsk4,tsk5,tsk6,tsk1a,tsk2a,tsk3a,tsk4a,tsk5a,tsk6a};
           
        
       Event evt1 = new Event(WhatId=acct.Id, Subject='Event Account', ActivityDate=Date.today().addDays(7), ActivityDateTime=Datetime.now(), DurationInMinutes=60);
       Event evt2 = new Event(WhoId=ctct.Id, Subject='Event Contact', ActivityDate=Date.today().addDays(7), ActivityDateTime=Datetime.now(), DurationInMinutes=60);
       Event evt3 = new Event(WhatId=opp.Id, Subject='Event Opportunity', Type = 'Presentation - Initial', ActivityDate=Date.today().addDays(7), ActivityDateTime=Datetime.now().addDays(7), DurationInMinutes=60);
       Event evt4 = new Event(WhatId=refAcct.Id, Subject='Event Referral Account', ActivityDate=Date.today().addDays(7), ActivityDateTime=Datetime.now(), DurationInMinutes=60);
       Event evt5 = new Event(WhatId=refCtct.Id, Subject='Event Referral Contact', ActivityDate=Date.today().addDays(7), ActivityDateTime=Datetime.now(), DurationInMinutes=60);
       Event evt6 = new Event(WhoId=ld.Id, Subject='Event Referral Contact', ActivityDate=Date.today().addDays(7), ActivityDateTime=Datetime.now(), DurationInMinutes=60);
       insert new Event[]{evt1,evt2,evt3,evt4,evt5,evt6};

       Marketing_Insights__c insight1 = new Marketing_Insights__c(Name__c='Name1', Type__c='Type', Account__c=acct.Id, Contact__c=ctct.Id);
       Marketing_Insights__c insight2 = new Marketing_Insights__c(Name__c='Name2', Type__c='Type', Account__c=acct.Id, Contact__c=ctct.Id);
       Marketing_Insights__c insight3 = new Marketing_Insights__c(Name__c='Name3', Type__c='Type', Lead__c=ld.Id);
       Marketing_Insights__c insight4 = new Marketing_Insights__c(Name__c='Name4', Type__c='Type', Lead__c=ld.Id);
       insert new Marketing_Insights__c[]{insight1,insight2,insight3,insight4};
	   
	   Customer_Intent_Signal__c intent1 = new Customer_Intent_Signal__c(Marketing_Action__c='Name1', Intent_Type__c='Type', Account__c=acct.Id, Contact__c=ctct.Id);
       Customer_Intent_Signal__c intent2 = new Customer_Intent_Signal__c(Marketing_Action__c='Name2', Intent_Type__c='Type', Account__c=acct.Id, Contact__c=ctct.Id);
       Customer_Intent_Signal__c intent3 = new Customer_Intent_Signal__c(Marketing_Action__c='Name3', Intent_Type__c='Type', Lead__c=ld.Id);
       Customer_Intent_Signal__c intent4 = new Customer_Intent_Signal__c(Marketing_Action__c='Name4', Intent_Type__c='Type', Lead__c=ld.Id);
       insert new Customer_Intent_Signal__c[]{intent1,intent2,intent3,intent4};

       Case testCase1 = new Case(Description = 'test case 1', Status = 'Approved/Ready', ContactId = ctct.Id, AccountId = acct.Id
                                  , Referral_Account__c = refAcct.Id);
       Case testCase2 = new Case(Description = 'test case 2', Status = 'Awaiting Reply', ContactId = ctct.Id, AccountId = acct.Id
                                  ,Referral_Account__c = refAcct.Id);
       //Closed Cases
       Case testCase4 = new Case(Description = 'test case 4', Status = 'Cancelled', ContactId = ctct.Id, AccountId = acct.Id
                                 ,Referral_Account__c = refAcct.Id);
       Case testCase5 = new Case(Description = 'test case 5', Status = 'Client Unresponsive', ContactId = ctct.Id, AccountId = acct.Id
                                 ,Referral_Account__c = refAcct.Id);
       Case testCase6 = new Case(RecordTypeId=caseCRrt, Status='Closed - Duplicate', Origin='Risk Model File', Current_Step__c='Closed - Duplicate', AccountId=acct1.Id);
       Case testCase7 = new Case(RecordTypeId=caseCRrt, Status='New', Origin='Risk Model File', Current_Step__c='New', AccountId=acct1.Id); 
       insert new Case[]{testCase1,testCase2,testCase4,testCase5,testCase6,testCase7};
           
       //Open Reference Client Retention records
       Reference_Client_Retention__c refCR1 = new Reference_Client_Retention__c(Prospect_Client_Name__c=acct1.Id, Prospect_Client_Contact__c=ctct1.Id, Case__c = testCase7.Id, Case_Type__c='Retention Model', RecordtypeId = rcrRT, Current_Step__c='New');       
       //Closed Reference Client Retention records
       Reference_Client_Retention__c refCR2 = new Reference_Client_Retention__c(Prospect_Client_Name__c=acct1.Id, Prospect_Client_Contact__c=ctct1.Id, Case__c = testCase6.Id, Case_Type__c='Retention Model', RecordtypeId = rcrRT, Current_Step__c='Closed - Duplicate');
       insert new Reference_Client_Retention__c[]{refCR1, refCR2};	
           
    } // setupData
    
    public static Account getTestAcct() {
       Account acct = [Select Id, Name from Account where Name='Test Account'];
       return acct;
    } // getTestAcct
    
    public static Account getTestAcctbyName(String acctName) {
       Account acct = [Select Id, Name from Account where Name=:acctName];
       return acct;
    } // getTestAcctbyName
    
    public static Contact getTestCtct() {
       Contact ctct = [Select Id, FirstName, LastName, AccountId, Account.Name
                        From Contact
                       Where Account.Name='Test Account'
                         and LastName='LastName'];
       return ctct;
    } // getTestCtct
    
    public static Contact getTestCtctByAcctName(String acctName) {
       Contact ctct = [Select Id, FirstName, LastName, AccountId, Account.Name
                        From Contact
                       Where Account.Name=:acctName
                         and LastName='LastName'];
       return ctct;
    } // getTestCtctByAcctName
    
    public static Referral_Account__c getTestRefAcct() {
       Referral_Account__c refAcct = [Select Id, Name from Referral_Account__c where Name='RefAcct'];
       return refAcct;
    } // getTestRefAcct
    
    public static Referral_Contact__c getTestRefCtct() {
       Referral_Contact__c refCtct = [Select Id, Name, Referral_Account__c, Referral_Account__r.Name
                                        From Referral_Contact__c
                                       Where Referral_Account__r.Name='RefAcct'
                                         and Name='Referral Contact'];
       return refCtct;
    } // getTestRefCtct
    
    public static Opportunity getTestOpp() {
       Opportunity opp = [Select Id, Name, AccountId, Account.Name from Opportunity
                            Where Account.Name='Test Account'
                              and Name='Test Opp'];
       return opp;
    } // getTestOpp
    
    public static Lead getTestLd() {
        Lead ld = [Select Id, Name, FirstName, LastName, Company 
                     From Lead
                    Where Company='Test Lead Co'];
        return ld;
    } // getTestLd
    
    //getContactWrapperById
    @IsTest
    static void testContactWrapper() {
       Contact ctct = getTestCtct();
       ContactWrapper wrapper = ObjectBannerAuraService.getContactWrapperById(ctct.Id);
       System.assert(wrapper.OpenActivities.size() > 0, 'no Open Activity');
       System.assert(wrapper.OpenCases.size() > 0, 'no Cases');
       System.assert(wrapper.OpenOpportunities.size() > 0, 'no Open Opps');
       System.assert(wrapper.marketingInsights.size() > 0, 'no Marketing Insights');
	   System.assert(wrapper.customerIntentSignals.size() > 0, 'no Customer Intent Signals');
    } // contactWrapperPopulated


    @IsTest
    static void testContactWrapperException() {
        ActivityDA.throwTestException=true;
        Contact ctct = getTestCtct();
        try {
           ContactWrapper wrapper = ObjectBannerAuraService.getContactWrapperById(ctct.Id);
           System.assert(false, 'Should have thrown AuraHandledException but did not');
        } catch(AuraHandledException ex) {
           System.assert(true);
        }
    } // testContactWrapperException

    @IsTest
    static void testOpportunityWrapper() {
        Account acct = getTestAcct();
        Opportunity opp = getTestOpp();
        OpportunityWrapper wrapper = ObjectBannerAuraService.getOpportunityWrapperById(opp.Id);
       
        System.assert(wrapper.RelatedEvents.size() > 0, 'no events');
        System.assert(wrapper.OpenActivities.size() > 0, 'no Open Activity');
        System.assert(wrapper.ContactRoles.size() > 0, 'no contact roles');
        System.assertEquals(acct.Id, wrapper.StrategicAccount.Id);
        System.assert(wrapper.portalUsers != null, 'should have populated it with something');
        System.assertEquals(opp.Id, wrapper.opp.Id);
        
    } // testOpportunityWrapper


    @IsTest
    static void testOpportunityWrapperException() {
        ActivityDA.throwTestException=true;
        Opportunity opp = getTestOpp();

            try {
                OpportunityWrapper wrapper = ObjectBannerAuraService.getOpportunityWrapperById(opp.Id);
                System.assert(false, 'Should have thrown AuraHandledException');
            } catch(AuraHandledException ex) {
                System.assert(true);
            }
    } // testOpportunityWrapperException

    // test Account Wrapper
    @IsTest
    static void testAccountWrapper() {
        Account acct = getTestAcct();
        AccountWrapper wrapper = ObjectBannerAuraService.getAccountWrapperById(acct.Id);

        //System.assert(wrapper.MarketingOwnedContact.size() == 0, 'Marketing Owned Contact');
        System.assert(wrapper.EmailOptOutContacts.size() == 0, 'Email Opt Out Contact');
        System.assert(wrapper.DNCContacts.size() == 0, 'DNC Contact');
        System.assert(wrapper.OpenActivities.size() > 0, 'no open activity');
        System.assert(wrapper.OpenActivities.size() > 0, 'no open activity');
        System.assert(wrapper.OpenCases.size() > 0, 'no open cases');
        System.assert(wrapper.OpenOpportunities.size() > 0, 'no open opportunities');
        System.assert(wrapper.marketingInsights.size() > 0, 'no marketing insights');
		System.assert(wrapper.customerIntentSignals.size() > 0, 'no Customer Intent Signals');
    } // testAccountWrapper



    @IsTest
    static void testAccountWrapperException() {
        ActivityDA.throwTestException=true;
        Account acct = getTestAcct();

        try {
            AccountWrapper wrapper = ObjectBannerAuraService.getAccountWrapperById(acct.Id);
            System.assert(false, 'Should have thrown AuraHandledException but did not');
        } catch(AuraHandledException ex) {
            System.assert(true);
        }
    } // testAccountWrapperException

    
    @IsTest
    static void testReferralContactWrapper() {
        Referral_Contact__c refCtct = getTestRefCtct();
        
        ReferralContactWrapper wrapper = ObjectBannerAuraService.getReferralContactWrapperById(refCtct.Id);

        System.assertEquals(refCtct.Id, wrapper.ReferralContact.Id);
        System.assertNotEquals(0, wrapper.OpenActivities.size());
        System.assertNotEquals(0, wrapper.OpenOpportunities.size());
        System.assertNotEquals(0, wrapper.OpenCases.size());
        System.assertEquals(1, wrapper.MutualClientCount);
        System.assertEquals(1, wrapper.MutualClients.size());
    } // testReferralContactWrapper

    @IsTest
    static void testReferralContactWrapperException() {
        ActivityDA.throwTestException=true;
        Referral_Contact__c refCtct = getTestRefCtct();
            try {

                ReferralContactWrapper wrapper = ObjectBannerAuraService.getReferralContactWrapperById(refCtct.Id);

                System.assert(false, 'Should have thrown AuraHandledException but did not');
            }  catch(AuraHandledException ex) {
                System.assert(true);
            }
    } // testReferralContactWrapperException


    @IsTest
    static void testReferralAccountWrapper() {

        Referral_Account__c refAcct = getTestRefAcct();
            ReferralAccountWrapper wrapper = ObjectBannerAuraService.getReferralAccountWrapperById(refAcct.Id);

            System.assertNotEquals(wrapper.ReferralAccount, null);
            System.assertNotEquals(wrapper.OpenActivities.size(), 0);
            System.assertNotEquals(wrapper.OpenOpportunities.size(), 0);
            System.assertEquals(wrapper.OpenCases.size(), 0);
            System.assertNotEquals(wrapper.RelatedReferralContacts.size(), 0);
            System.assertNotEquals(wrapper.MutualClientCount, 0);
    } // testReferralAccountWrapper

    @IsTest
    static void testReferralAccountWrapperException() {
        ActivityDA.throwTestException=true;
        Referral_Account__c refAcct = getTestRefAcct();
        try {
            ReferralAccountWrapper wrapper = ObjectBannerAuraService.getReferralAccountWrapperById(refAcct.Id);

            System.assert(false, 'Should have thrown AuraHandledException but did not');
        }
        catch(AuraHandledException ex) {
            System.assert(true);
        }
    } // testReferralAccountWrapperException
    
    // getLeadWrapperById
    @IsTest
    static void testLeadWrapper() {
        Lead ld = getTestLd();
        LeadWrapper wrapper = ObjectBannerAuraService.getLeadWrapperById(ld.Id);
        System.assertEquals(ld.Id, wrapper.Lead.Id);
        System.assertNotEquals(0,wrapper.OpenActivities.size());
        System.assertNotEquals(0,wrapper.marketingInsights.size());
		System.assertNotEquals(0,wrapper.customerIntentSignals.size());
    } // testLeadWrapper
    
    
    @IsTest
    static void testLeadWrapperException() {
        ActivityDA.throwTestException=true;
        Lead ld = getTestLd();
        
        try {
          LeadWrapper wrapper = ObjectBannerAuraService.getLeadWrapperById(ld.Id);
            
            System.assert(false, 'Should have thrown AuraHandledException but did not');
        }
        catch(AuraHandledException ex) {
            System.assert(true);
        }
    } // testLeadWrapperException
    
    @IsTest
    static void testReferenceClientRetentionWrapper() {

        Account acct = getTestAcctbyName('ACCT1');
        Reference_Client_Retention__c rcr = [Select Id from Reference_Client_Retention__c where Reference_Client_Retention__c.Prospect_Client_Name__c =:acct.Id LIMIT 1];	
    	
        ReferenceClientRetentionWrapper wrapper = ObjectBannerAuraService.getRefClientRetWrapperById(rcr.Id);
            System.assertEquals(rcr.Id, wrapper.refClientRet.Id);
            System.assertEquals(1, wrapper.openRCRs.size());
            System.assertEquals(2, wrapper.totalRCRs.size());
            
    } // testReferenceClientRetentionWrapper

} // class ObjectBannerAuraServiceTest