/*
* Before Trigger Test for Reference CTT
* 
* 11/30/2020	Matt Fritschi	Created
* 03/02/2021	Matt Fritschi	Sets SubmissionDate__c when the NCP is marker as submitted.
  08/01/2022    Dan Carmen      Clean up code

*/

@isTest(seeAllData=false) 
public class ReferenceCTTBeforeTest {

    // we can keep this as false, we're just going to make sure it hits the code.
    @isTest(SeeAllData=false)
    static void testProspectClient() {     
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'testAccountA', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081234',NumberOfEmployees = 60);
        insert acctA;
        
        Opportunity opptyA = new Opportunity(Name='testOpptyA', StageName = 'Sold', CloseDate = System.today(), AccountId=acctA.Id);
        insert opptyA;
        
        //Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true limit 1];
        
        opptyA = [SELECT Id, Name FROM Opportunity WHERE Id=:opptyA.Id LIMIT 1];
        
        Onboarding_Tool__c onbRec = new Onboarding_Tool__c(Name = 'Onboarding Rec', NCP_Submitted__c = false, Is_Parent__c = false, Opportunity_Id__c = opptyA.Id);
        insert onbRec;
        
        onbRec = [SELECT Id, Name, NCP_Submitted__c, Is_Parent__c, Multi_ID__c, Opportunity_Id__c FROM Onboarding_Tool__c WHERE Id=:onbRec.Id LIMIT 1];
        System.assertEquals(false, onbRec.Multi_ID__c);
        List<Reference_CTT__C> refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        System.assertEquals(0, refCTTRecs.size());        
        
        User[] users = [Select Id, Name from user where IsActive=true and Job_Name__c=:UserHelper.JOB_REP AND ManagerId != null limit 1];
        onbRec.NCP_Submitted__c = true;
        onbRec.NCP_Submitter__c = users[0].Id;
        onbRec.SubmissionDate__c = date.Today();
        update onbRec;
        
        refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c, Ready_To_Be_Worked__c, Prospect_Client__c, Status__c
                                                       , Other_Missing__c, Other_Reason__c, Fed_Doc_Missing__c, Sign_Quote_or_Fee_Schedule_Missing__c, Client_Profile_Incomplete_or_Missing__c 
                                                   FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        System.assertEquals(1, refCTTRecs.size());
        System.assertEquals(acctA.Id, refCTTRecs[0].Prospect_Client__c);
        
        refCTTRecs[0].Status__c = 'Returned to Sales - Sales Requirements Not Met';
        refCTTRecs[0].Fed_Doc_Missing__c = true;
        refCTTRecs[0].Sign_Quote_or_Fee_Schedule_Missing__c = true;
        refCTTRecs[0].Client_Profile_Incomplete_or_Missing__c = true;
        refCTTRecs[0].Other_Missing__c = true;
        refCTTRecs[0].Other_Reason__c = 'TEST';
        update refCTTRecs[0];
        
        //list<feedItem> fItemList = [Select Id, Body from feedItem where parentId = :refCTTRecs[0].id];
        //system.assertEquals(fItemList.size(),1);
        System.assertEquals(1,ChatterMentionPost.feedItemsToPostSize);
    } // testProspectClient
    
    static testMethod void testProspectClient2() {     
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'testAccountA', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081234',NumberOfEmployees = 60);
        insert acctA;
        
        Opportunity opptyA = new Opportunity(Name='testOpptyA', StageName = 'Sold', CloseDate = System.today(), AccountId=acctA.Id, Mandate_Sale__c=true);
        insert opptyA;
        
        //Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true limit 1];
        
        opptyA = [SELECT Id, Name FROM Opportunity WHERE Id=:opptyA.Id LIMIT 1];
        
        Onboarding_Tool__c onbRec = new Onboarding_Tool__c(Name = 'Onboarding Rec', NCP_Submitted__c = false, Is_Parent__c = false, Opportunity_Id__c = opptyA.Id);
        insert onbRec;
        
        onbRec = [SELECT Id, Name, NCP_Submitted__c, Is_Parent__c, Multi_ID__c, Opportunity_Id__c FROM Onboarding_Tool__c WHERE Id=:onbRec.Id LIMIT 1];
        System.assertEquals(false, onbRec.Multi_ID__c);
        List<Reference_CTT__C> refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        System.assertEquals(0, refCTTRecs.size());        
        
        User[] users = [Select Id, Name from user where IsActive=true and Job_Name__c=:UserHelper.JOB_REP AND ManagerId != null limit 1];
        onbRec.NCP_Submitted__c = true;
        onbRec.NCP_Submitter__c = users[0].Id;
        onbRec.SubmissionDate__c = date.Today();
        update onbRec;
        
        refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c, Ready_To_Be_Worked__c, Prospect_Client__c, Status__c
                                                       , Other_Missing__c, Other_Reason__c, Fed_Doc_Missing__c, Sign_Quote_or_Fee_Schedule_Missing__c, Client_Profile_Incomplete_or_Missing__c 
                                                   FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        System.assertEquals(1, refCTTRecs.size());
        System.assertEquals(acctA.Id, refCTTRecs[0].Prospect_Client__c);
        
        refCTTRecs[0].Status__c = 'Returned to Sales - Sales Requirements Not Met';
        refCTTRecs[0].Fed_Doc_Missing__c = true;
        refCTTRecs[0].Sign_Quote_or_Fee_Schedule_Missing__c = true;
        refCTTRecs[0].Client_Profile_Incomplete_or_Missing__c = true;
        refCTTRecs[0].Other_Missing__c = true;
        refCTTRecs[0].Other_Reason__c = 'TEST';
        update refCTTRecs[0];
        
        //list<feedItem> fItemList = [Select Id, Body from feedItem where parentId = :refCTTRecs[0].id];
        //system.assertEquals(fItemList.size(),1);
        System.assertEquals(1,ChatterMentionPost.feedItemsToPostSize);
    } // testProspectClient2
    
    // this needs to remain true to actually post the chatter messages so we can see the content.
    @isTest(SeeAllData=true)
    static void testChatterMessages() {     
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'testAccountA', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081234',NumberOfEmployees = 60);
        insert acctA;
        
        Opportunity opptyA = new Opportunity(Name='testOpptyA', StageName = 'Sold', CloseDate = System.today(), AccountId=acctA.Id);
        insert opptyA;
        
        //Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true limit 1];
                
        opptyA = [SELECT Id, Name FROM Opportunity WHERE Id=:opptyA.Id LIMIT 1];
        
        Onboarding_Tool__c onbRec = new Onboarding_Tool__c(Name = 'Onboarding Rec', NCP_Submitted__c = false, Is_Parent__c = false, Opportunity_Id__c = opptyA.Id);
        insert onbRec;
        
        onbRec = [SELECT Id, Name, NCP_Submitted__c, Is_Parent__c, Multi_ID__c, Opportunity_Id__c FROM Onboarding_Tool__c WHERE Id=:onbRec.Id LIMIT 1];
        //System.assertEquals(false, onbRec.Multi_ID__c);
        List<Reference_CTT__C> refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        System.assertEquals(0, refCTTRecs.size());        
        
        User[] users = [Select Id, Name from user where IsActive=true and Job_Name__c=:UserHelper.JOB_REP AND ManagerId != null limit 1];
        onbRec.NCP_Submitted__c = true;
        onbRec.NCP_Submitter__c = users[0].Id;
        onbRec.SubmissionDate__c = date.Today();
        update onbRec;
        
       
        refCTTRecs = new List<Reference_CTT__C>([SELECT Id, Name, Opportunity__c, Onboarding_Tool__c, Ready_To_Be_Worked__c, Prospect_Client__c, Status__c, Other_Missing__c, Other_Reason__c, Fed_Doc_Missing__c, Sign_Quote_or_Fee_Schedule_Missing__c, Client_Profile_Incomplete_or_Missing__c FROM Reference_CTT__c WHERE Onboarding_Tool__c = :onbRec.Id]);
        System.assertEquals(1, refCTTRecs.size());
        
        // one chatter is created from the creation of the Reference object.
        list<feedItem> fItemList1 = [Select Id, Body from feedItem where parentId = :refCTTRecs[0].id];
        System.debug('fItemList1='+fItemList1);
 
        System.assertEquals(acctA.Id, refCTTRecs[0].Prospect_Client__c);
        
        refCTTRecs[0].Status__c = 'Sales Action Required';
        refCTTRecs[0].Fed_Doc_Missing__c = true;
        refCTTRecs[0].Sign_Quote_or_Fee_Schedule_Missing__c = true;
        refCTTRecs[0].Client_Profile_Incomplete_or_Missing__c = true;
        refCTTRecs[0].Other_Missing__c = true;
        refCTTRecs[0].Other_Reason__c = 'TEST';
        update refCTTRecs[0];
        
        list<feedItem> fItemList2 = [Select Id, Body from feedItem where parentId = :refCTTRecs[0].id order by CreatedDate desc];
        system.debug('fItemList2='+fItemList2);
        //system.assertEquals(2,fItemList2.size());
        
        System.assertEquals(true, fItemList2[0].body.contains('Fed Doc'));
        System.assertEquals(true, fItemList2[0].body.contains('Signed quote'));
        System.assertEquals(true, fItemList2[0].body.contains('incomplete'));
        System.assertEquals(true, fItemList2[0].body.contains('TEST'));
    } // testChatterMessages
    
} // class ReferenceCTTBeforeTest