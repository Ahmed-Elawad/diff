/*
* Before Trigger Test for Onboarding
* 
* 11/30/2020	Matt Fritschi	Created
* 03/01/2021	Matt Fritschi	Sets SubmissionDate on NCP submit
  08/01/2022    Dan Carmen      Clean up code
  05/22/2023    Dan Carmen      Updated Quote test to set the Data Set name based on the cafsl__Embedded_CPQ_Settings__c
  09/01/2023    Dan Carmen      Add methods to set record attributes consistently
  09/27/2023    Dan Carmen      Set additional parent attribute

*/

@isTest(seeAllData=false) 
public class OnboardingToolBeforeTest {

    static testMethod void testNonMultiId()
    {     
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'testAccountA', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081234',NumberOfEmployees = 60);
        insert acctA;
        
        Opportunity opptyA = new Opportunity(Name='testOpptyA', StageName = 'Sold', CloseDate = System.today(), Account=acctA);
        insert opptyA;
        
        OracleQuoteTriggerPayxHelperTest.setupOracleSetting();
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opptyA.AccountId;
        quote.cafsl__Opportunity__c = opptyA.Id;
        quote.Name = 'TestQuote';
        quote.Multi_ID__c = false;
        //quote.cafsl__Pricebook_Id__c = spricebookId;
        quote.cafsl__CPQ_External_Id__c='12345678';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        insert quote;
        
        opptyA.Primary_Oracle_Quote__c=quote.id;
        update opptyA;
        
        opptyA = [SELECT Id, Name, Primary_Oracle_Quote__c, Primary_Oracle_Quote__r.Multi_ID__c FROM Opportunity WHERE Id=:opptyA.Id LIMIT 1];
        
        Onboarding_Tool__c onbRec = new Onboarding_Tool__c(Name = 'Onboarding Rec', NCP_Submitted__c = false, Is_Parent__c = false, Opportunity_Id__c = opptyA.Id);
        insert onbRec;
        
        Integer nbrRecs = [SELECT count() FROM Reference_CTT__c where Opportunity__c=:opptyA.Id];
        System.debug('testNonMultiId 1 nbrRecs='+nbrRecs);

        onbRec = [SELECT Id, Name, NCP_Submitted__c, Is_Parent__c, Multi_ID__c, Opportunity_Id__c, Opportunity_Id__r.Primary_Oracle_Quote__c, Opportunity_Id__r.Primary_Oracle_Quote__r.Multi_ID__c FROM Onboarding_Tool__c WHERE Id=:onbRec.Id LIMIT 1];
        System.assertEquals(false, onbRec.Multi_ID__c);
        List<Reference_CTT__C> refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        System.assertEquals(0, refCTTRecs.size());        
        
        onbRec.NCP_Submitted__c = true;
        onbRec.SubmissionDate__c = date.today();
        update onbRec;
        
        nbrRecs = [SELECT count() FROM Reference_CTT__c where Opportunity__c=:opptyA.Id];
        System.debug('testNonMultiId 1 nbrRecs='+nbrRecs);

        refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c, Ready_To_Be_Worked__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        System.assertEquals(1, refCTTRecs.size());
        System.assertEquals(true, refCTTRecs[0].Ready_To_Be_Worked__c);
    } // testNonMultiId

        
    static testMethod void testNonMultiIdCAMandate()
    {     
        //setupData();
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctB = new Account(Name = 'testAccountB', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081298',NumberOfEmployees = 50);
        insert acctB;
        
        Opportunity opptyB = new Opportunity(Name='testOpptyB', StageName = 'Sold', CloseDate = System.today(), Account=acctB, Mandate_Sale__c = true);
        insert opptyB;
        
        //Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true limit 1];

        OracleQuoteTriggerPayxHelperTest.setupOracleSetting();
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opptyB.AccountId;
        quote.cafsl__Opportunity__c = opptyB.Id;
        quote.Name = 'TestQuote';
        quote.Multi_ID__c = false;
        //quote.cafsl__Pricebook_Id__c = spricebookId;
        quote.cafsl__CPQ_External_Id__c='12345678';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        insert quote;
        
        opptyB.Primary_Oracle_Quote__c=quote.id;
        update opptyB;
        
        opptyB = [SELECT Id, Name, Primary_Oracle_Quote__c, Primary_Oracle_Quote__r.Multi_ID__c FROM Opportunity WHERE Id=:opptyB.Id LIMIT 1];
        
        Onboarding_Tool__c onbRec = new Onboarding_Tool__c(Name = 'Onboarding Rec', NCP_Submitted__c = true, Is_Parent__c = false, Opportunity_Id__c = opptyB.Id, SubmissionDate__c = date.today());
        insert onbRec;
        
        Integer nbrRecs = [SELECT count() FROM Reference_CTT__c where Opportunity__c=:opptyB.Id];
        System.debug('testNonMultiIdCAMandate 1 nbrRecs='+nbrRecs);
        
        onbRec = [SELECT Id, Name, NCP_Submitted__c, Is_Parent__c, Multi_ID__c, Opportunity_Id__c, Opportunity_Id__r.Primary_Oracle_Quote__c, Opportunity_Id__r.Primary_Oracle_Quote__r.Multi_ID__c FROM Onboarding_Tool__c WHERE Id=:onbRec.Id LIMIT 1];
        System.assertEquals(false, onbRec.Multi_ID__c);
        //List<Reference_CTT__C> refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        List<Reference_CTT__C> refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c FROM Reference_CTT__c WHERE Opportunity__c=:opptyB.Id]);
        System.assertEquals(1, refCTTRecs.size());        
                
        nbrRecs = [SELECT count() FROM Reference_CTT__c where Opportunity__c=:opptyB.Id];
        System.debug('testNonMultiIdCAMandate 2 nbrRecs='+nbrRecs);
    } // testNonMultiIdCAMandate
    
    static testMethod void testAllSubmitted()
    {     
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'testAccountA', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081234',NumberOfEmployees = 60);
        insert acctA;
        
        Opportunity opptyA = new Opportunity(Name='testOpptyA', StageName = 'Sold', CloseDate = System.today(), Account=acctA);
        insert opptyA;
        Opportunity opptyB = new Opportunity(Name='testOpptyB', StageName = 'Sold', CloseDate = System.today());
        insert opptyB;
        
        OracleQuoteTriggerPayxHelperTest.setupOracleSetting();
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opptyA.AccountId;
        quote.cafsl__Opportunity__c = opptyA.Id;
        quote.Name = 'TestQuote';
        quote.Multi_ID__c = true;
        //quote.cafsl__Pricebook_Id__c = spricebookId;
        quote.cafsl__CPQ_External_Id__c='12345679';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        insert quote;
        
        opptyA.Primary_Oracle_Quote__c=quote.id;
        update opptyA;
        
        opptyA = [SELECT Id, Name, Primary_Oracle_Quote__c, Primary_Oracle_Quote__r.Multi_ID__c FROM Opportunity WHERE Id=:opptyA.Id LIMIT 1];
        
        Onboarding_Tool__c parentOnbRec = new Onboarding_Tool__c(Name = 'Parent', NCP_Submitted__c = false, Is_Parent__c = false, Opportunity_Id__c = opptyA.Id);
        OnboardingToolHelper.SKIP_TRIGGERS=true;
        insert parentOnbRec;
        
        parentOnbRec = [SELECT Id, Name, NCP_Submitted__c, Is_Parent__c, Multi_ID__c, Opportunity_Id__c, Opportunity_Id__r.Primary_Oracle_Quote__c, Opportunity_Id__r.Primary_Oracle_Quote__r.Multi_ID__c FROM Onboarding_Tool__c WHERE Id=:parentOnbRec.Id LIMIT 1];
        System.assertEquals(true, parentOnbRec.Multi_ID__c);
        List<Reference_CTT__C> refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :parentOnbRec.Id]);
        System.assertEquals(0, refCTTRecs.size());        
        
        parentOnbRec.NCP_Submitted__c = true;
        parentOnbRec.SubmissionDate__c = date.today();
        OnboardingToolHelper.SKIP_TRIGGERS=false;
        update parentOnbRec;
        
        refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c, Ready_To_Be_Worked__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :parentOnbRec.Id]);
        System.assertEquals(1, refCTTRecs.size());
        System.assertEquals(false, refCTTRecs[0].Ready_To_Be_Worked__c);
        
        List<Onboarding_Tool__c> childOnboardingRecs = new List<Onboarding_Tool__c>();
        parentOnbRec.Is_Parent__c = true; 
        
        Onboarding_Tool__c childOnbRec1 = new Onboarding_Tool__c(Name = 'child1', Is_Child__c = true, Parent_Onboarding_Record__c = parentOnbRec.Id, Opportunity_Id__c = opptyB.Id);
        Onboarding_Tool__c childOnbRec2 = new Onboarding_Tool__c(Name = 'child1', Is_Child__c = true, Parent_Onboarding_Record__c = parentOnbRec.Id, Opportunity_Id__c = opptyB.Id);
        Onboarding_Tool__c childOnbRec3 = new Onboarding_Tool__c(Name = 'child1', Is_Child__c = true, Parent_Onboarding_Record__c = parentOnbRec.Id, Opportunity_Id__c = opptyB.Id);
        childOnboardingRecs.add(childOnbRec1);
        childOnboardingRecs.add(childOnbRec2);
        childOnboardingRecs.add(childOnbRec3);
        childOnboardingRecs.add(parentOnbRec);
        upsert childOnboardingRecs;
        
        childOnboardingRecs.clear();
        childOnbRec1.NCP_Submitted__c = true;
        childOnbRec1.SubmissionDate__c = date.today();
        childOnboardingRecs.add(childOnbRec1);
        childOnbRec2.NCP_Submitted__c = true;
        childOnbRec2.SubmissionDate__c = date.today();
        childOnboardingRecs.add(childOnbRec2);
        OnboardingToolHelper.SKIP_TRIGGERS=false;
        update childOnboardingRecs;
        
        childOnbRec3.NCP_Submitted__c = true;
        childOnbRec3.SubmissionDate__c = date.today();
        OnboardingToolHelper.SKIP_TRIGGERS=false;
        update childOnbRec3;
        
        parentOnbRec = [SELECT Id, Name, All_Children_Submitted__c FROM Onboarding_Tool__c WHERE Id = :parentOnbRec.Id LIMIT 1];
        System.assertEquals(true, parentOnbRec.All_Children_Submitted__c);
        refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c, Ready_To_Be_Worked__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :parentOnbRec.Id]);
        System.assertEquals(1, refCTTRecs.size());
        System.assertEquals(true, refCTTRecs[0].Ready_To_Be_Worked__c);
    } // testAllSubmitted
    
    static testMethod void testParentSubmittedAfterSplit()
    {       
        
        Opportunity opptyA = new Opportunity(Name='testOpptyA', StageName = 'Sold', CloseDate = System.today());
        insert opptyA;
        Opportunity opptyB = new Opportunity(Name='testOpptyB', StageName = 'Sold', CloseDate = System.today(), Primary_Opportunity__c = opptyA.Id);
        insert opptyB;
        
        OracleQuoteTriggerPayxHelperTest.setupOracleSetting();
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opptyA.AccountId;
        quote.cafsl__Opportunity__c = opptyA.Id;
        quote.Name = 'TestQuote';
        quote.Multi_ID__c = true;
        //quote.cafsl__Pricebook_Id__c = spricebookId;
        quote.cafsl__CPQ_External_Id__c='12345670';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        insert quote;
        
        opptyA.Primary_Oracle_Quote__c=quote.id;
        update opptyA;
            
        List<Onboarding_Tool__c> childOnboardingRecs = new List<Onboarding_Tool__c>();
        Onboarding_Tool__c childOnbRec1 = new Onboarding_Tool__c(Name = 'child1', Is_Child__c = false, Opportunity_Id__c = opptyB.Id);
        Onboarding_Tool__c childOnbRec2 = new Onboarding_Tool__c(Name = 'child1', Is_Child__c = false, Opportunity_Id__c = opptyB.Id);
        Onboarding_Tool__c childOnbRec3 = new Onboarding_Tool__c(Name = 'child1', Is_Child__c = false, Opportunity_Id__c = opptyB.Id);
        childOnboardingRecs.add(childOnbRec1);
        childOnboardingRecs.add(childOnbRec2);
        childOnboardingRecs.add(childOnbRec3);
        insert childOnboardingRecs;
        
        Onboarding_Tool__c parentOnbRec = new Onboarding_Tool__c(Name = 'Parent', NCP_Submitted__c = false, Opportunity_Id__c = opptyA.Id);
        insert parentOnbRec;
        
        parentOnbRec=[SELECT Id, Name, Multi_Id__c, Is_Parent__c, NCP_Submitted__c FROM Onboarding_Tool__c WHERE Id=:parentOnbRec.Id];
        System.assertEquals(true, parentOnbRec.Multi_Id__c);
        System.assertEquals(true, parentOnbRec.Is_Parent__c);
        
        parentOnbRec.NCP_Submitted__c = true;
        parentOnbRec.SubmissionDate__c = date.today();
        System.debug('Updating the Parent NCP to be submitted.');
        update parentOnbRec;
        
        childOnbRec1 = [SELECT Id, Name, Multi_Id__c, Parent_Onboarding_Record__c, Is_Parent__c, NumComboIds__c, Combo__c, EmpsToLoad__c, NumOf1099s__c, Business_Structure__c, PreAssignedClientNum__c, PreAssignedId__c, Taxed_as_S_Corp__c, Is_Child__c, Irs_Address__c, IrsIsDelivery__c, PriorWagesLoaded__c, PeriodEndDate__c, First_Check_Date__c, PayrollContact_Title__c, PayrollContact_Email__c, PayrollContact_Phone__c, Authorized_Off_is_Payroll_Contact__c, NCP_Submitted__c, Authorized_Officer_Email__c, Pay_Demand__c, Workers_Compensation__c, Authorized_Officer_Phone__c, GL__c, Other_Accounting_Software__c, Skylight__c, Accounting_Software__c, ReadyChex__c, Authorize_Officer__c, PayrollContact__c, Run_Date__c, StateProcessedIn__c, Submitter__c FROM Onboarding_Tool__c WHERE Id=:childOnbRec1.Id];
        System.assertEquals(true, childOnbRec1.Is_Child__c);
        
        childOnbRec2 = [SELECT Id, Name, Multi_Id__c, Is_Parent__c, Is_Child__c, NCP_Submitted__c FROM Onboarding_Tool__c WHERE Id=:childOnbRec2.Id];
        System.assertEquals(true, childOnbRec2.Is_Child__c);
        
        childOnbRec3 = [SELECT Id, Name, Multi_Id__c, Is_Parent__c, Is_Child__c, NCP_Submitted__c FROM Onboarding_Tool__c WHERE Id=:childOnbRec3.Id];
        System.assertEquals(true, childOnbRec3.Is_Child__c);
        System.assertEquals(false, childOnbRec3.Is_Parent__c);
        System.assertEquals(null, childOnbRec1.ReadyChex__c);
        System.assertEquals(null, childOnbRec1.GL__c);
        System.assertEquals(null, childOnbRec1.Accounting_Software__c);
        System.assertEquals(null, childOnbRec1.Other_Accounting_Software__c);
        System.assertEquals(null, childOnbRec1.Skylight__c);
        System.assertEquals(null, childOnbRec1.Pay_Demand__c);
        System.assertEquals(null, childOnbRec1.Workers_Compensation__c);
        System.assertEquals(null, childOnbRec1.Authorized_Officer_Phone__c);
        System.assertEquals(null, childOnbRec1.Authorized_Officer_Email__c);
        System.assertEquals(null, childOnbRec1.Authorized_Off_is_Payroll_Contact__c);
        System.assertEquals(null, childOnbRec1.PayrollContact_Title__c);
        System.assertEquals(null, childOnbRec1.PayrollContact_Phone__c);
        System.assertEquals(null, childOnbRec1.PayrollContact_Email__c);
        System.assertEquals(null, childOnbRec1.First_Check_Date__c);
        System.assertEquals(null, childOnbRec1.PriorWagesLoaded__c);
        System.assertEquals(null, childOnbRec1.IrsIsDelivery__c);
        System.assertEquals(null, childOnbRec1.Irs_Address__c);
        System.assertEquals(null, childOnbRec1.Business_Structure__c);
        System.assertEquals(false, childOnbRec1.Taxed_as_S_Corp__c);
        System.assertEquals('No', childOnbRec1.PreAssignedClientNum__c);
        System.assertEquals(null, childOnbRec1.PreAssignedId__c);
        System.assertEquals(null, childOnbRec1.NumOf1099s__c);
        System.assertEquals(null, childOnbRec1.EmpsToLoad__c);
        System.assertEquals(null, childOnbRec1.Combo__c);
        System.assertEquals(null, childOnbRec1.NumComboIds__c);
        System.assertEquals(null, childOnbRec1.PayrollContact__c);
        System.assertEquals(null, childOnbRec1.Run_Date__c);
        System.assertEquals(parentOnbRec.Id, childOnbRec1.Parent_Onboarding_Record__c);
        System.assertEquals(false, childOnbRec1.NCP_Submitted__c);
        System.assertEquals(null, childOnbRec1.Submitter__c);
        System.assertEquals(null, childOnbRec1.StateProcessedIn__c);
        
        childOnboardingRecs.clear();
        childOnbRec1.NCP_Submitted__c = true;
        childOnbRec1.SubmissionDate__c = date.today();
        childOnboardingRecs.add(childOnbRec1);
        childOnbRec2.NCP_Submitted__c = true;
        childOnbRec2.SubmissionDate__c = date.today();
        childOnboardingRecs.add(childOnbRec2);
        System.debug('Submitting childOnbRec1 and childOnbRec2');
        update childOnboardingRecs;
        
        
        childOnbRec3.NCP_Submitted__c = true;
        childOnbRec3.SubmissionDate__c = date.today();
        System.debug('Submitting childOnbRec3');
        update childOnbRec3;
        
        parentOnbRec = [SELECT Id, Name, All_Children_Submitted__c FROM Onboarding_Tool__c WHERE Id = :parentOnbRec.Id LIMIT 1];
        System.assertEquals(true, parentOnbRec.All_Children_Submitted__c);

    } //testPCAdvocateOwnership
    
    @isTest(SeeAllData=true)
    static void testChatterMessage()
    {     
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Group testGroup = new Group(Name='NCP Paco Submission Team Test Queue', type='Queue');
            insert testGroup;
            
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SobjectType = 'Reference_CTT__c');
            insert testQueue;
            
            CollaborationGroup chatterGroup = new CollaborationGroup(CollaborationType='Public', Name='NCP Paco Submission Team Test Queue');
            insert chatterGroup;
        }
        
        List<CollaborationGroup> chatterGroups = [SELECT Id, Name From CollaborationGroup WHERE CollaborationType='Public'AND Name = 'NCP Paco Submission Team Test Queue'];
        System.debug('chatterGroups.size()='+chatterGroups.size());
            
        List<QueueSobject> q1 = [Select Id, q.Queue.Name, q.Queue.ID from QueueSobject q WHERE q.Queue.Name='NCP Paco Submission Team Test Queue' ORDER BY q.Queue.Name];
        System.debug('testChatterMessage q1[0].Queue.Name='+q1[0].Queue.Name);
        System.debug('testChatterMessage q1='+q1);
        
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'testAccountA', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081234',NumberOfEmployees = 60);
        insert acctA;
        
        Opportunity opptyA = new Opportunity(Name='testOpptyA', StageName = 'Sold', CloseDate = System.today(), Account=acctA);
        insert opptyA;
        
        OracleQuoteTriggerPayxHelperTest.setupOracleSetting();
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opptyA.AccountId;
        quote.cafsl__Opportunity__c = opptyA.Id;
        quote.Name = 'TestQuote';
        quote.Multi_ID__c = false;
        //quote.cafsl__Pricebook_Id__c = spricebookId;
        quote.cafsl__CPQ_External_Id__c='12345671';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        insert quote;
        
        opptyA.Primary_Oracle_Quote__c=quote.id;
        update opptyA;
        
        opptyA = [SELECT Id, Name, Primary_Oracle_Quote__c, Primary_Oracle_Quote__r.Multi_ID__c FROM Opportunity WHERE Id=:opptyA.Id LIMIT 1];
        
        Onboarding_Tool__c onbRec = new Onboarding_Tool__c(Name = 'Onboarding Rec', Is_Parent__c = false, Opportunity_Id__c = opptyA.Id, NCP_Submitted__c = false, ReadyChex__c='Decline Both', Skylight__c='Decline Both', GL__c='GL Report', Pay_Demand__c='Decline', Workers_Compensation__c='WC Payment Service', Business_Structure__c='LLC');
        insert onbRec;
        
        Test.startTest();
        onbRec.NCP_Submitted__c = true;
        onbRec.SubmissionDate__c = date.today();
        update onbRec;
        Test.stopTest();
        
        onbRec = [SELECT Id, Name, NCP_Submitted__c, Is_Parent__c, Multi_ID__c, Opportunity_Id__c, ReadyChex__c, Skylight__c, GL__c, Pay_Demand__c FROM Onboarding_Tool__c WHERE Id=:onbRec.Id LIMIT 1];
        System.assertEquals(false, onbRec.Multi_ID__c);

        List<Reference_CTT__C> refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c, X501c_Proof_Received__c, Ready_To_Be_Worked__c, Paid_On_Demand_Received__c, Workers_Comp_Declaration_Page__c, OwnerId, Check_Signing_Received__c, Skylight_Card_Received__c, Chart_of_Accounts__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        System.assertEquals(1, refCTTRecs.size());  
        System.assertEquals('N/A', refCTTRecs[0].Check_Signing_Received__c);
		System.assertEquals('N/A', refCTTRecs[0].Skylight_Card_Received__c);
		System.assertEquals('N/A', refCTTRecs[0].Chart_of_Accounts__c);
        System.assertEquals('N/A', refCTTRecs[0].Paid_On_Demand_Received__c);
        System.assertEquals('N/A', refCTTRecs[0].Workers_Comp_Declaration_Page__c);
        System.assertEquals('N/A', refCTTRecs[0].X501c_Proof_Received__c);
        System.assertEquals(true, refCTTRecs[0].Ready_To_Be_Worked__c);
        
        
        Group testGroup = [SELECT Id, Name FROM Group WHERE Name='NCP Paco Submission Team Test Queue' LIMIT 1];
        System.assertEquals(testGroup.Id, refCTTRecs[0].OwnerId);
        
        list<feedItem> fItemList = [Select Id, Body from feedItem where parentId = :refCTTRecs[0].Id];
        system.assertEquals(fItemList.size(),1);
            
    } //testChatterMessage
    
    
    static testMethod void testNonMultiIdSubmittedTwice()
    {     
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'testAccountA', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081234',NumberOfEmployees = 60);
        insert acctA;
        
        Opportunity opptyA = new Opportunity(Name='testOpptyA', StageName = 'Sold', CloseDate = System.today(), Account=acctA);
        insert opptyA;
        
        OracleQuoteTriggerPayxHelperTest.setupOracleSetting();
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opptyA.AccountId;
        quote.cafsl__Opportunity__c = opptyA.Id;
        quote.Name = 'TestQuote';
        quote.Multi_ID__c = false;
        //quote.cafsl__Pricebook_Id__c = spricebookId;
        quote.cafsl__CPQ_External_Id__c='12345672';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        insert quote;
        
        opptyA.Primary_Oracle_Quote__c=quote.id;
        update opptyA;
        
        opptyA = [SELECT Id, Name, Primary_Oracle_Quote__c, Primary_Oracle_Quote__r.Multi_ID__c FROM Opportunity WHERE Id=:opptyA.Id LIMIT 1];
        
        Onboarding_Tool__c onbRec = new Onboarding_Tool__c(Name = 'Onboarding Rec', NCP_Submitted__c = false, Is_Parent__c = false, Opportunity_Id__c = opptyA.Id);
        insert onbRec;
        
        onbRec = [SELECT Id, Name, NCP_Submitted__c, Is_Parent__c, Multi_ID__c, Opportunity_Id__c, Opportunity_Id__r.Primary_Oracle_Quote__c, Opportunity_Id__r.Primary_Oracle_Quote__r.Multi_ID__c FROM Onboarding_Tool__c WHERE Id=:onbRec.Id LIMIT 1];
        System.assertEquals(false, onbRec.Multi_ID__c);
        List<Reference_CTT__C> refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        System.assertEquals(0, refCTTRecs.size());        
        
        onbRec.NCP_Submitted__c = true;
        onbRec.SubmissionDate__c = date.today();
        update onbRec;
        
        refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c, Ready_To_Be_Worked__c, Status__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        System.assertEquals(1, refCTTRecs.size());
        System.assertEquals(true, refCTTRecs[0].Ready_To_Be_Worked__c);
        System.assertEquals('Submitted to CTT', refCTTRecs[0].Status__c);
        
        System.debug('This one should be caught as a duplicate ncp');
        onbRec.Name = 'Onb Test 1';
        update onbRec;
        
        refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c, Ready_To_Be_Worked__c, Status__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        System.assertEquals(1, refCTTRecs.size());
        System.assertEquals(true, refCTTRecs[0].Ready_To_Be_Worked__c);
        System.assertEquals('Submitted to CTT', refCTTRecs[0].Status__c);
        
        refCTTRecs[0].Status__c = 'Cancelled';
        update refCTTRecs[0];
        
        System.debug('This one should create a new CTT since the old one was closed.');
        onbRec.Name = 'Onb Test 2';
        update onbRec;
        
        refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c, Ready_To_Be_Worked__c, Status__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        System.assertEquals(2, refCTTRecs.size());
    } // testNonMultiIdSubmittedTwice
    
    static testMethod void testEntryCriteria() {
       Map<String,Schema.RecordTypeInfo> byNameMap = Account.getSobjectType().getDescribe().getRecordTypeInfosByName();
       Id acctRtId = byNameMap.get(RecordTypeHelper.MMS_ACCOUNT).getRecordTypeId();
       Account acct1 = new Account(Name='Account1', RecordTypeId=acctRtId);
       Account acct2 = new Account(Name='Account2', RecordTypeId=acctRtId);
       Account acct3 = new Account(Name='Account3', RecordTypeId=acctRtId);
       Account acct4 = new Account(Name='Account4', RecordTypeId=acctRtId);
       Account acct5 = new Account(Name='Account5', RecordTypeId=acctRtId);
       Account acct6 = new Account(Name='Account6', RecordTypeId=acctRtId);
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert new Account[]{acct1,acct2,acct3,acct4,acct5,acct6};
       
       acct5.SalesParent__c = acct4.Id;
       acct6.SalesParent__c = acct4.Id;
       update new Account[]{acct5,acct6};
           
       Account_Junction__c aj5 = new Account_Junction__c(Parent_Account__c=acct4.Id, Child_Account__c=acct5.Id, Type__c='Sales Parent-Child');
       Account_Junction__c aj6 = new Account_Junction__c(Parent_Account__c=acct4.Id, Child_Account__c=acct6.Id, Type__c='Sales Parent-Child');
       insert new Account_Junction__c[]{aj5,aj6};

       // verify the accounts are set as expected
       Assert.areEqual(1,[Select count() from Account where IsParent__c=true]);
       Assert.areEqual(2,[Select count() from Account where IsChild__c=true]);

       Opportunity opp1 = new Opportunity(Name='Opportunity1', AccountId=acct1.Id, CloseDate=Date.today().addDays(7), StageName='Pending');
       Opportunity opp2 = new Opportunity(Name='Opportunity2', AccountId=acct2.Id, CloseDate=Date.today().addDays(7), StageName='Pending');
       Opportunity opp3 = new Opportunity(Name='Opportunity3', AccountId=acct3.Id, CloseDate=Date.today().addDays(7), StageName='Pending');
       Opportunity opp4 = new Opportunity(Name='Opportunity4', AccountId=acct4.Id, CloseDate=Date.today().addDays(7), StageName='Pending');
       OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
       //insert opp1;
       //insert opp2;
       //insert opp3;
       //insert opp4;
       insert new Opportunity[]{opp1,opp2,opp3,opp4}; 
       Opportunity[] opps = [Select Id, Name, Primary_Opportunity__c from Opportunity];
       System.debug('testEntryCriteria opps='+opps);
        
       Onboarding_Tool__c onb1 = new Onboarding_Tool__c(Opportunity_Id__c=opp1.Id);
       Onboarding_Tool__c onb2 = new Onboarding_Tool__c(Opportunity_Id__c=opp2.Id);
       Onboarding_Tool__c onb3 = new Onboarding_Tool__c(AccountId__c=acct3.Id, Opportunity_Id__c=opp3.Id);
       Onboarding_Tool__c onb4 = new Onboarding_Tool__c(AccountId__c=acct4.Id, Opportunity_Id__c=opp4.Id);
       Onboarding_Tool__c onb5 = new Onboarding_Tool__c(AccountId__c=acct5.Id);
       Onboarding_Tool__c onb6 = new Onboarding_Tool__c(AccountId__c=acct6.Id);
       insert new Onboarding_Tool__c[]{onb1,onb2,onb3,onb4,onb5,onb6};
       
       Map<Id,Onboarding_Tool__c> toolMap = new Map<Id,Onboarding_Tool__c>([Select Id, Opportunity_Id__c, AccountId__c
                                                                                  ,Is_Parent__c, Is_Child__c, isMultiIdParent__c
                                                                                  ,Sales_Parent__c
                                                                              From Onboarding_Tool__c]);
       onb1 = toolMap.get(onb1.Id);
       System.debug('testEntryCriteria onb1='+onb2);
       Assert.areEqual(acct1.Id, onb1.AccountId__c);
       Assert.areEqual(opp1.Id, onb1.Opportunity_Id__c);
       Assert.isFalse(onb1.Is_Child__c);
       Assert.isFalse(onb1.Is_Parent__c);
       Assert.isFalse(onb1.isMultiIdParent__c);
       Assert.isNull(onb1.Sales_Parent__c);
        
       onb2 = toolMap.get(onb2.Id);
       System.debug('testEntryCriteria onb2='+onb2);
       Assert.areEqual(acct2.Id, onb2.AccountId__c);
       Assert.areEqual(opp2.Id, onb2.Opportunity_Id__c);
       Assert.isFalse(onb2.Is_Child__c);
       Assert.isFalse(onb2.Is_Parent__c);
       Assert.isFalse(onb2.isMultiIdParent__c);
       Assert.isNull(onb2.Sales_Parent__c);
        
       onb3 = toolMap.get(onb3.Id);
       System.debug('testEntryCriteria onb3='+onb3);
       Assert.areEqual(acct3.Id, onb3.AccountId__c);
       Assert.areEqual(opp3.Id, onb3.Opportunity_Id__c);
       Assert.isFalse(onb3.Is_Child__c);
       Assert.isFalse(onb3.Is_Parent__c);
       Assert.isFalse(onb3.isMultiIdParent__c);
       Assert.isNull(onb3.Sales_Parent__c);
        
       onb4 = toolMap.get(onb4.Id);
       System.debug('testEntryCriteria onb4='+onb4);
       Assert.areEqual(acct4.Id, onb4.AccountId__c);
       Assert.areEqual(opp4.Id, onb4.Opportunity_Id__c);
       Assert.isFalse(onb4.Is_Child__c);
       Assert.isTrue(onb4.Is_Parent__c);
       Assert.isTrue(onb4.isMultiIdParent__c);
       Assert.isNull(onb4.Sales_Parent__c);
        
       onb5 = toolMap.get(onb5.Id);
       System.debug('testEntryCriteria onb5='+onb5);
       Assert.areEqual(acct5.Id, onb5.AccountId__c);
       Assert.areEqual(opp4.Id, onb5.Opportunity_Id__c);
       Assert.isTrue(onb5.Is_Child__c);
       Assert.isFalse(onb5.Is_Parent__c);
       Assert.isFalse(onb5.isMultiIdParent__c);
       Assert.areEqual(acct4.Id, onb5.Sales_Parent__c);
        
       onb6 = toolMap.get(onb6.Id);
       System.debug('testEntryCriteria onb6='+onb6);
       Assert.areEqual(acct6.Id, onb6.AccountId__c);
       Assert.areEqual(opp4.Id, onb6.Opportunity_Id__c);
       Assert.isTrue(onb6.Is_Child__c);
       Assert.isFalse(onb6.Is_Parent__c);
       Assert.isFalse(onb6.isMultiIdParent__c);
       Assert.areEqual(acct4.Id, onb6.Sales_Parent__c);
        
    } // testEntryCriteria
    
    static testMethod void testMarkingParent() {
       Map<String,Schema.RecordTypeInfo> byNameMap = Account.getSobjectType().getDescribe().getRecordTypeInfosByName();
       Id acctRtId = byNameMap.get(RecordTypeHelper.MMS_ACCOUNT).getRecordTypeId();
       Account acct1 = new Account(Name='Account1', RecordTypeId=acctRtId);
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert acct1;
           
       Opportunity opp1 = new Opportunity(Name='Opportunity1', AccountId=acct1.Id, CloseDate=Date.today().addDays(7), StageName='Pending');
       OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
       insert opp1;

       Onboarding_Tool__c onb1 = new Onboarding_Tool__c(AccountId__c=acct1.Id, Opportunity_Id__c=opp1.Id);
       insert onb1;
        
       onb1 = [Select Id, AccountId__c, Opportunity_Id__c, Is_Parent__c, Is_Child__c from Onboarding_Tool__c where Id=:onb1.Id ];
       Assert.isFalse(onb1.Is_Child__c);
       Assert.isFalse(onb1.Is_Parent__c);
        
       Account acct2 = new Account(Name='Account2', RecordTypeId=acctRtId, SalesParent__c=acct1.Id);
       Account acct3 = new Account(Name='Account3', RecordTypeId=acctRtId, SalesParent__c=acct1.Id);
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert new Account[]{acct2,acct3};
       
       Account_Junction__c aj2 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=acct2.Id, Type__c='Sales Parent-Child');
       Account_Junction__c aj3 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=acct3.Id, Type__c='Sales Parent-Child');
       insert new Account_Junction__c[]{aj2,aj3};

       // verify the accounts are set as expected
       Assert.areEqual(1,[Select count() from Account where IsParent__c=true]);
       Assert.areEqual(2,[Select count() from Account where IsChild__c=true]);

       Onboarding_Tool__c onb2 = new Onboarding_Tool__c(AccountId__c=acct2.Id, Combo__c='Yes');
       Onboarding_Tool__c onb3 = new Onboarding_Tool__c(AccountId__c=acct3.Id);
       insert new Onboarding_Tool__c[]{onb2,onb3};
       
       Map<Id,Onboarding_Tool__c> toolMap = new Map<Id,Onboarding_Tool__c>([Select Id, Opportunity_Id__c, AccountId__c, Combo__c
                                                                                  ,Is_Parent__c, Is_Child__c, isMultiIdParent__c
                                                                                  ,Sales_Parent__c
                                                                              From Onboarding_Tool__c]);
       onb1 = toolMap.get(onb1.Id);
       System.debug('testEntryCriteria onb1='+onb2);
       Assert.areEqual(acct1.Id, onb1.AccountId__c);
       Assert.areEqual(opp1.Id, onb1.Opportunity_Id__c);
       Assert.areEqual('Yes',onb1.Combo__c);
       Assert.isFalse(onb1.Is_Child__c);
       Assert.isTrue(onb1.Is_Parent__c);
       Assert.isTrue(onb1.isMultiIdParent__c);
       Assert.isNull(onb1.Sales_Parent__c);
        
       onb2 = toolMap.get(onb2.Id);
       System.debug('testEntryCriteria onb2='+onb2);
       Assert.areEqual(acct2.Id, onb2.AccountId__c);
       Assert.areEqual(opp1.Id, onb2.Opportunity_Id__c);
       Assert.areEqual('Yes',onb2.Combo__c);
       Assert.isTrue(onb2.Is_Child__c);
       Assert.isFalse(onb2.Is_Parent__c);
       Assert.isFalse(onb2.isMultiIdParent__c);
       Assert.areEqual(acct1.Id, onb2.Sales_Parent__c);
        
       onb3 = toolMap.get(onb3.Id);
       System.debug('testEntryCriteria onb3='+onb3);
       Assert.areEqual(acct3.Id, onb3.AccountId__c);
       Assert.areEqual(opp1.Id, onb3.Opportunity_Id__c);
       Assert.isNull(onb3.Combo__c);
       Assert.isTrue(onb3.Is_Child__c);
       Assert.isFalse(onb3.Is_Parent__c);
       Assert.isFalse(onb3.isMultiIdParent__c);
       Assert.areEqual(acct1.Id, onb3.Sales_Parent__c);

    } // testMarkingParent
    
    
} // class OnboardingToolBeforeTest