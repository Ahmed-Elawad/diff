/*
*  .
*
* History
* --------
* 06/21/2021  Matt Fritschi  created
* 06/29/2021  Ahmed Elawad   set data accessibility to false for class and true for individual test method
*/

@isTest(SeeAllData=false)
public class PEOUWProspectChatterMessagesTest {
    
   /* @testSetup
    public static void setupData() {
        List<String> docNames = new List<String>();
        docNames.add('Census');
        
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'Test Prospect 1', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, ShippingStreet = 'Billling Street', 
                                    ShippingPostalCode='1234', ShippingState='NY', ShippingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='', agentsync__ID_FEIN__c='Test1');
        insert acctA;
        
        User salesAnalyst = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name = :Utilities.PROF_HRS_PEO_CENTRIC and IsActive=true limit 1];
        User salesRep = [Select Id, FirstName, LastName, Email from User where Job_Name__c = :UserHelper.JOB_REP and IsActive=true and Id != :salesAnalyst.Id limit 1];
        
        PEO_Onboarding_Checklist__c chklst = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctA.Id, Medical_Benefits_Underwriting_Requested__c='Yes', Sales_Rep__c=salesRep.Id, OwnerId=salesAnalyst.Id);
        Insert chklst;
        
        PEO_Onboarding_Medical_Questionnaire__c medQs = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=chklst.Id);
        insert medQs;
        
        List<PEO_Onboarding_Document__c> docLst = new List<PEO_Onboarding_Document__c>();
        
        for (String docName : docNames) {
            docLst.add(new PEO_Onboarding_Document__c(Name=docName,PEO_Onboarding_Checklist__c=chklst.Id, Status__c='', Routing_Name__c=docName));
        }
        System.debug('docLst:'+docLst);
        insert docLst;
        
        PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c(OwnerId=salesAnalyst.Id, PEO_Underwriting_Checklist__c=chklst.Id, Prospect_Comments__c='TEST', Discrepancy_Type__c='Other');
        insert disc;
    } // setupData*/
    
    @isTest(SeeAllData=true)
    static void testProspectMadeDiscrepancyComments() { 
        PEOUWProspectChatterMessages PPCM=New PEOUWProspectChatterMessages();
        List<String> docNames = new List<String>();
        docNames.add('Census');
        
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acc = new Account(Name = 'PEO Edge Communities Test Prospect 1', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, ShippingStreet = 'Billling Street', 
                                    ShippingPostalCode='1234', ShippingState='NY', ShippingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='',
                                  BenAdmin_Hold_Out__c=false,agentsync__ID_FEIN__c='Test1');
        insert acc;
        
        User salesAnalyst = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name = :Utilities.PROF_HRS_PEO_CENTRIC and IsActive=true limit 1];
        User salesRep = [Select Id, FirstName, LastName, Email from User where Job_Name__c = :UserHelper.JOB_REP and IsActive=true and Id != :salesAnalyst.Id limit 1];
        
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acc.Id, Medical_Benefits_Underwriting_Requested__c='Yes', Sales_Rep__c=salesRep.Id, OwnerId=salesAnalyst.Id);
        Insert checklist;
        
        PEO_Onboarding_Medical_Questionnaire__c medQs = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=checklist.Id);
        insert medQs;
        
        List<PEO_Onboarding_Document__c> docLst = new List<PEO_Onboarding_Document__c>();
        
        for (String docName : docNames) {
            docLst.add(new PEO_Onboarding_Document__c(Name=docName,PEO_Onboarding_Checklist__c=checklist.Id, Status__c='', Routing_Name__c=docName));
        }
        System.debug('docLst:'+docLst);
        insert docLst;
        
        PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c(PEO_Underwriting_Checklist__c=checklist.Id, Prospect_Comments__c='TEST', Discrepancy_Type__c='Other');
        insert disc;
                
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = 'Id:' + disc.Id + ';\nProspect_Comments__c:' + disc.Prospect_Comments__c;
        
        email.subject = 'Prospect Comments Chatter';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        PEOUWProspectChatterMessages PeoUWpcm = new PEOUWProspectChatterMessages();
        Test.startTest();
        PeoUWpcm.handleInboundEmail(email, env); 
        PPCM.createDiscrepancyChatterFromProspect(email.plainTextBody);
        Test.stopTest();
        list<feedItem> fItemList = [Select Id, Body from feedItem where parentId = :disc.Id];
        system.assertEquals(fItemList.size(),1);
        delete fItemList;
        
        PEO_Onboarding_Document_Discrepency__c udisc = [SELECT Id,Comment_Log__c,Prospect_Comments__c FROM PEO_Onboarding_Document_Discrepency__c WHERE Id = :disc.Id LIMIT 1];
        system.debug('byRohith'+ udisc.Prospect_Comments__c );
        system.assert(udisc.Prospect_Comments__c==null);
        system.assert(udisc.Comment_Log__c!=null);
        
    }
    @isTest
    public static void testCompleteStep() { 
        
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acc = new Account(Name = 'PEO Edge Communities Test Prospect 1', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, ShippingStreet = 'Billling Street', 
                                    ShippingPostalCode='1234', ShippingState='NY', ShippingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='', agentsync__ID_FEIN__c='Test1');
        insert acc;
        
        Schema.RecordTypeInfo rtCtct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');
        Contact ctct = new Contact(FirstName='test',LastName='test',AccountId=acc.Id,RecordTypeId=rtCtct.getRecordTypeId(),email='test@testtest.test');
        insert ctct;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Login User Clone'];
        User u = new User(Alias = 'testComm', ProfileId = p.Id, ContactId = ctct.Id, Sales_Org__c = 'PAY', Username='commTestUser@testorg.com51516663', FirstName=ctct.FirstName, LastName=ctct.LastName, 
                          Email=ctct.Email, TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US');
        insert u;
        
        User salesAnalyst = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name = :Utilities.PROF_HRS_PEO_CENTRIC and IsActive=true limit 1];
        User salesRep = [Select Id, FirstName, LastName, Email from User where Job_Name__c = :UserHelper.JOB_REP and IsActive=true and Id != :salesAnalyst.Id limit 1];
        User salesNSC = [Select Id, FirstName, LastName, Email from User where Job_Name__c = :UserHelper.JOB_REP and IsActive=true and Id != :salesRep.Id AND Id != :salesAnalyst.Id limit 1];
        
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acc.Id, Medical_Benefits_Underwriting_Requested__c='Yes', 
                                                                                Sales_Rep__c=salesRep.Id, Sales_Analyst__c =salesAnalyst.Id,Community_User__c = u.Id,
                                                                                OwnerId=salesAnalyst.Id,Medical_Underwriting_Path__c='Gradient Pre-Qualifier');
        Insert checklist;
        
        //body text is going to be a semi colon separated list.  The first element will be the current step, the second is the prospect name, 
        //the third is the checklist Id, the fourth is the contact id, the remaining will be those to @mention
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = 'medical;'+acc.Name+';'+checklist.Id+';'+u.ContactId+';'+salesRep.Id+';'+salesNSC.Id+';'+salesAnalyst.Id+';';
        
        email.subject = 'Step Complete Chatter';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        PEOUWProspectChatterMessages PeoUWpcm = new PEOUWProspectChatterMessages();
        Test.startTest();
        Boolean success = CommunitiesAccountUpdateController.sendCompleteEmail(checklist,acc.Name,'medicalPrequal');
        system.assertEquals(true,success);
        PeoUWpcm.handleInboundEmail(email, env);
        
        checklist.Medical_Underwriting_Path__c = 'Full Master Medical Submission';
        
        success = CommunitiesAccountUpdateController.sendCompleteEmail(checklist,acc.Name,'medical');
        system.assertEquals(true,success);
        PeoUWpcm.handleInboundEmail(email, env);
        
        email.plainTextBody = 'wc;'+acc.Name+';'+checklist.Id+';'+u.ContactId+';'+salesRep.Id+';'+salesNSC.Id+';'+salesAnalyst.Id+';';
        PeoUWpcm.handleInboundEmail(email, env); 
        
        email.plainTextBody = 'acctUpdatePrequal;'+acc.Name+';'+checklist.Id+';'+u.ContactId+';'+salesRep.Id+';'+salesNSC.Id+';'+salesAnalyst.Id+';';
        PeoUWpcm.handleInboundEmail(email, env); 
        
        email.plainTextBody = 'addtlInfo;'+acc.Name+';'+checklist.Id+';'+u.ContactId+';'+salesRep.Id+';'+salesNSC.Id+';'+salesAnalyst.Id+';';
        PeoUWpcm.handleInboundEmail(email, env); 
        Test.stopTest();
        
    }
}