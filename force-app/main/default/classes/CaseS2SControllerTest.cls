/*-- Test Class for CaseS2SController.
 * -------
*   02/15/2018  Jermaine Stukes Created
    04/13/2018  Dan Carmen      Update user selection in test
    11/08/2018  Lynn Michels    Edited to allow for Sales2Support
    11/13/2018  Lynn Michels    Edited to fix failures
    11/19/2018  Lynn Michels    Edited for post-imp work
	6/29/2020	Jake Hinds		Adding product multi-select
*/

@isTest
public class CaseS2SControllerTest 
{
    @testSetup
    Static void Setup()
    {
        //Add Defaults
        List<S2S_Mapping_Defaults__c> S2SDefaultList = new List<S2S_Mapping_Defaults__c>();
        S2S_Mapping_Defaults__c hrs401k = new S2S_Mapping_Defaults__c(Name='401K', QueueId__c='00G700000044XPz',Product__c='401K');
        insert hrs401k;
        //Add Case Types
        List<S2S_Case_Types__c> caseTypeList = new List<S2S_Case_Types__c>();
        S2S_Case_Types__c Sales_to_Service = new S2S_Case_Types__c(Name='Sales2Service',Field_List__c='Type,Product__c,Issue_Type__c,Subject,Description');
        S2S_Case_Types__c ACT = new S2S_Case_Types__c(Name='Act Support',Field_List__c='ACT_Category_1__c,Subject,Description');
        S2S_Case_Types__c Do_Not_Contact = new S2S_Case_Types__c(Name='Do Not Contact',Field_List__c='Type,Sub_Type__c,Reason_For_Request__c,Description');
        S2S_Case_Types__c Sales2Support = new S2S_Case_Types__c(Name='Sales2Support',Field_List__c='Subject,Description');
        
        caseTypeList.add(Sales_to_Service);
        caseTypeList.add(ACT);
        caseTypeList.add(Do_Not_Contact);
        caseTypeList.add(Sales2Support);
        insert caseTypeList;
        //Create Account and contacts
        CreateTestData.createSingleAandTwoCts();
    }//Setup()

    Static testMethod void testSucessfulS2S()
    {
        test.startTest();
        Contact ct1 = [Select Id, Name, Account.Name from Contact where Email=:'fLast1@abc.com'];
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/SalesToService?id='+ct1.Id);
        test.setCurrentPageReference(pageRef);
        CaseS2SController newS2S = new CaseS2SController();
        System.assertEquals('Contact Name: '+ct1.Name, newS2S.headerInfo1);
        System.assertEquals('Prospect-Client: '+ct1.Account.Name, newS2S.headerInfo2);
        System.assertEquals(null, newS2S.s2sCase.Type);
        newS2S.saveKase();
        //did not validate so there was no case created yet
        System.assert(newS2S.s2sCase.Id == Null);
        System.assertEquals(false,newS2S.validateCase());
        newS2S.s2sCase.Type = 'Sales2Service';
        System.assertEquals(false,newS2S.validateCase());
      //  newS2S.s2sCase.Products_Multi__c = '401k';
      //  System.assertEquals(false,newS2S.validateCase());
        newS2S.s2sCase.Issue_Type__c = 'New Client / Implementation Issue';
        System.assertEquals(false,newS2S.validateCase());
        newS2S.s2sCase.Subject = 'New Test';
        System.assertEquals(false,newS2S.validateCase());
        newS2S.s2sCase.Description = 'Test Description';
        newS2S.validateCase();
        System.assertEquals(false, newS2S.disableButton);
        System.assertEquals('slds-button_success', newS2S.buttonStyle);
     // TO DO  System.assertEquals(true,newS2S.validateCase());
        //Add Attachment
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        newS2S.attachName = 'Unit Test Attachment';
        newS2S.attachName2 = 'Unit Test Attachment';
        newS2S.attachName3 = 'Unit Test Attachment';
        newS2S.attachBody = bodyBlob;
        newS2S.attachBody2 = bodyBlob;
        newS2S.attachBody3 = bodyBlob;
        newS2S.saveKase();
     //TO DO   System.assert(newS2S.s2sCase.Id !=Null); 
        test.stopTest();
    }
 /*   Static testMethod void testMultiProduct()   
    {
        List<String> multiProfileList = Label.S2SMultiProduct.split(';');
        User testUser = [SELECT id FROM User WHERE isActive = true AND Profile.Name = :multiProfileList[0] LIMIT 1];
        system.runAs(testUser){
            test.startTest();
            Account acct1 = new Account(Name='test Account');
            insert acct1;
            Contact ctct1 = new Contact(FirstName='test',LastName='con',AccountId=acct1.Id);
            insert ctct1;
            //Set Current Page to new reference
            PageReference pageRef = new PageReference('/apex/SalesToService?id='+ctct1.Id);
            test.setCurrentPageReference(pageRef);
            CaseS2SController newS2S = new CaseS2SController();
            System.assertEquals('Contact Name: '+ctct1.FirstName+' '+ctct1.LastName, newS2S.headerInfo1);
            System.assertEquals('Prospect-Client: '+acct1.Name, newS2S.headerInfo2);
            System.assertEquals(null, newS2S.s2sCase.Type);
            System.assertEquals(true, newS2S.showMultiProduct);
        	test.stopTest();
        }
        
    } */
    Static testMethod void testSucessfulRC()
    {
        test.startTest();
        Schema.RecordTypeInfo hrsRefAcctRt = RecordTypeHelper.getRecordType('HRS Referral Source Record Type', 'Referral_Account__c');
        Schema.RecordTypeInfo hrsRefCtctRt = RecordTypeHelper.getRecordType('HRS Referral Record Type', 'Referral_Contact__c');
        
        Referral_Account__c refacct = new Referral_Account__c (name = 'Referral Account1'
                                                               ,RecordTypeId=hrsRefAcctRt.getRecordTypeId()
                                                               ,Referral_Type__c = 'Broker'
                                                               ,Zip_Postal_Code__c = '10000'
                                                               ,To_Be_Deleted__c = false);
        insert refacct;
        
        Referral_Contact__c refcon1 = new Referral_Contact__c(Name = 'First Ref Ctct1'
                                                              ,RecordTypeId=hrsRefCtctRt.getRecordTypeId()
                                                              ,Phone__c = '585-555-1212'
                                                              ,Email__c = 'fLast1@abc.com'
                                                              ,Referral_Type__c = '100 Broker'
                                                              ,Referral_Account__c = refacct.Id);
        insert refcon1;
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/SalesToService?id='+refcon1.Id);
        test.setCurrentPageReference(pageRef);
        CaseS2SController newS2S = new CaseS2SController();
        System.assertEquals('Referral Contact Name: '+refcon1.Name, newS2S.headerInfo1);
        System.assertEquals('Referral Account: '+refacct.Name, newS2S.headerInfo2);
        System.assertEquals('Act Support', newS2S.s2sCase.Type);
        newS2S.saveKase();
        System.assert(newS2S.s2sCase.Id == Null);
        System.assertEquals(false,newS2S.validateCase());
        newS2S.s2sCase.Type = 'Act Support';
        System.assertEquals(false,newS2S.validateCase());
        newS2S.s2sCase.ACT_Category_1__c = 'Payroll Service';
        System.assertEquals(false,newS2S.validateCase());
        newS2S.s2sCase.Subject = 'New Test';
        System.assertEquals(false,newS2S.validateCase());
        newS2S.s2sCase.Description = 'Test Description';
        System.assertEquals(true,newS2S.validateCase());
        newS2S.saveKase();
        //System.assert(newS2S.s2sCase.Id !=Null);
        test.stopTest();
    }  
    /* JSH Commenting out 8/27/2020.  Fixed a null pointer error in S2SEscalationProcessing that this test seemed to be relying on.
    Static testMethod void testUnSucessfulS2S()
    {
        test.startTest();
        //Add Custom Setting
        //Add Defaults
        User uzer = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true limit 1];
        System.runAs(uzer)
        {
            Account acct1 = new Account(name = 'testAcct');
            insert acct1;
            Contact ct1 = new Contact(firstName = 'test', lastname='Contact', Email='fLast1@abc.com', AccountId = acct1.Id);
            insert ct1;
            Contact testContact = [Select Id, Name, Account.Name from Contact where Email=:'fLast1@abc.com' and Account.Id=:acct1.Id limit 1];
            //Set Current Page to new reference
            PageReference pageRef = new PageReference('/apex/SalesToService?id='+testContact.Id);
            test.setCurrentPageReference(pageRef);
            CaseS2SController newS2SCase = new CaseS2SController();
            System.assertEquals('Contact Name: '+testContact.Name, newS2SCase.headerInfo1);
            System.assertEquals('Prospect-Client: '+testContact.Account.Name, newS2SCase.headerInfo2);
            System.assertEquals(null, newS2SCase.s2sCase.Type);
            newS2SCase.s2sCase.Type = 'Sales2Service';
            newS2SCase.s2sCase.Product__c = 'PEO';
            newS2SCase.s2sCase.Issue_Type__c = 'New Client / Implementation Issue';
            newS2SCase.s2sCase.Subject = 'New Test';
            newS2SCase.s2sCase.Description = 'Test Description';
            newS2SCase.validateCase();
            System.assertEquals(false, newS2SCase.disableButton);
            System.assertEquals('slds-button_success', newS2SCase.buttonStyle);
            System.assertEquals(true,newS2SCase.validateCase());
            newS2SCase.saveKase();
            //Catch Validation Rule
            System.assertNotEquals(null, newS2SCase.errorMessages);
        }
        
        test.stopTest();
    }*/
        Static testMethod void testAttachments()
    {
        Contact ct1 = [Select Id, Name, Account.Name from Contact where Email=:'fLast1@abc.com'];
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/SalesToService?id='+ct1.Id);
        test.setCurrentPageReference(pageRef);
        CaseS2SController newS2S = new CaseS2SController();
        newS2S.s2sCase.Type = 'Sales2Service';
        newS2S.s2sCase.Product__c = '401k';
        newS2S.s2sCase.Issue_Type__c = 'New Client / Implementation Issue';
        newS2S.s2sCase.Subject = 'New Test';
        newS2S.s2sCase.Description = 'Test Description';
        //Add Attachment
        Blob bodyBlob=Blob.valueOf('Unit Test');
        newS2S.attachName = 'Unit Test Attachment';
        newS2S.attachBody = bodyBlob;
        newS2S.attachName2 = 'Unit Test Attachment';
        newS2S.attachBody2 = bodyBlob;
        newS2S.attachName3 = 'Unit Test Attachment';
        newS2S.attachBody3 = bodyBlob;
        test.startTest();
        newS2S.saveKase();
        test.stopTest();
        ContentDocumentLink cdl = [Select ContentDocument.Id, ContentDocument.Title, ContentDocument.ContentSize from ContentDocumentLink where LinkedEntityId=:newS2S.s2sCase.Id limit 1];
        System.assertNotEquals(null, cdl);
    }
   /* Static testMethod void testLargeAttachments()
    {
        test.startTest();
        Contact ct1 = [Select Id, Name, Account.Name from Contact where Email=:'fLast1@abc.com'];
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/SalesToService?id='+ct1.Id);
        test.setCurrentPageReference(pageRef);
        CaseS2SController newS2S = new CaseS2SController();
        newS2S.s2sCase.Type = 'Sales2Service';
        newS2S.s2sCase.Product__c = 'Payroll';
        newS2S.s2sCase.Issue_Type__c = 'New Client / Implementation Issue';
        newS2S.s2sCase.Subject = 'New Test';
        newS2S.s2sCase.Description = 'Test Description';
        //Add Attachment
        Blob bodyBlob=Blob.valueOf('Unit Test of Large Attachments Body');
        newS2S.attachName = 'Unit Test Attachment';
        newS2S.attachBody = bodyBlob;
        newS2S.saveKase();
        ContentDocumentLink cdl = [Select ContentDocument.Id, ContentDocument.Title, ContentDocument.ContentSize from ContentDocumentLink where LinkedEntityId=:newS2S.s2sCase.Id];
        System.assertNotEquals(null, cdl);
        test.stopTest();
    }*/
    Static testMethod void testAccount()
    {
        test.startTest();
        Account acct1 = [Select Id, Name from Account where Name=:'Test Account1' limit 1];
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/SalesToService?id='+acct1.Id);
        test.setCurrentPageReference(pageRef);
        CaseS2SController newDNCAcct = new CaseS2SController();
        System.assertEquals('Prospect-Client Name: '+acct1.Name, newDNCAcct.headerInfo1);
        System.assertEquals('', newDNCAcct.headerInfo2);
        System.assertEquals(null, newDNCAcct.s2sCase.Type);
        newDNCAcct.s2sCase.Type = 'Do Not Contact';
        test.stopTest();
    } 
    Static testMethod void testLead()
    {
        test.startTest();
        Lead_Company__c lc1 = new Lead_Company__c(Name='Test Lead Company 1', Postal_Code__c='12345');
        insert lc1;
        Lead ld1 = new Lead(Company=lc1.Name, LastName='Last1', LeadSource='LeadSource', Lead_Company__c=lc1.Id);
        insert ld1;
        Lead testLead = [Select Id, Name from Lead where Id=:ld1.Id];
        Profile_List__c plSetting = new Profile_List__c(Name = 'System Administrator', Sales2Support__c = false);
        insert plSetting;
        
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/SalesToService?id='+testLead.Id);
        test.setCurrentPageReference(pageRef);
        CaseS2SController newDNCLead1 = new CaseS2SController();
        System.assertEquals('Lead Name: '+testLead.Name, newDNCLead1.headerInfo1);
        System.assertEquals('', newDNCLead1.headerInfo2);
        System.assertEquals(3, newDNCLead1.typeOptions.size());
        
        plSetting.Sales2Support__c = true;
        update plSetting;
        CaseS2SController newDNCLead = new CaseS2SController();
        System.assertEquals(4, newDNCLead.typeOptions.size());
        
        System.assertEquals(null, newDNCLead.s2sCase.Type);
        newDNCLead.s2sCase.Type = 'Do Not Contact';
        
        test.stopTest();
    } 
    
    Static testMethod void testDNC()
    {
        Contact ct1 = [Select Id, Name, Account.Name from Contact where Email=:'fLast1@abc.com'];
        test.startTest();
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/SalesToService?id='+ct1.Id);
        test.setCurrentPageReference(pageRef);
        CaseS2SController newS2S = new CaseS2SController();
        System.assertEquals('Contact Name: '+ct1.Name, newS2S.headerInfo1);
        System.assertEquals('Prospect-Client: '+ct1.Account.Name, newS2S.headerInfo2);
        newS2S.s2sCase.Type = 'Do Not Contact';
        newS2S.s2sCase.Sub_Type__c = 'Do Not Call';
        newS2S.s2sCase.Description = 'Test Description';
        newS2S.s2sCase.Reason_For_Request__c='I am testing';
        system.assert(newS2S.subTypeOptions!=null);
        newS2S.saveKase();
        system.assertEquals('S2S Submission',newS2S.s2sCase.Origin);
        system.assertEquals('Do Not Call Request',newS2s.s2sCase.Subject);
        System.assert(newS2S.s2sCase.Id !=Null);
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean successMessageShown = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('case has been created.')){
             successMessageShown = true;
             }//end if
        }//end for
        system.assert(successMessageShown);
        test.stopTest();
    } 
    
    Static testMethod void testSales2Support()
    {
        test.startTest();
        Account acct1 = new Account(Name = 'Test Account 1');
        insert acct1;
        Profile_List__c plSetting = new Profile_List__c(Name = 'System Administrator', Sales2Support__c = false);
        insert plSetting;
        
       //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/SalesToService?id='+acct1.Id);
        test.setCurrentPageReference(pageRef);
        CaseS2SController newS2S1 = new CaseS2SController();
        System.assertEquals('Prospect-Client Name: '+acct1.Name, newS2S1.headerInfo1);
        System.assertEquals('', newS2S1.headerInfo2);
        System.assertEquals(3, newS2S1.typeOptions.size());
        
        plSetting.Sales2Support__c = true;
        update plSetting;
        CaseS2SController newS2S = new CaseS2SController();
        System.assertEquals(4, newS2S.typeOptions.size());
        newS2S.s2sCase.Type = 'Sales2Support';
        newS2S.s2sCase.Subject = 'Test Sales2Support';
        newS2S.s2sCase.Description = 'Test Description';
        System.assertEquals(true,newS2S.validateCase());
        newS2S.saveKase();
        system.assertEquals('Salesforce Case',newS2S.s2sCase.Origin);
        System.assert(newS2S.s2sCase.Id !=Null);
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean successMessageShown = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('A new Sales2Support case has been created.')){
             successMessageShown = true;
             }//end if
        }//end for
        system.assert(successMessageShown);
        //test creating another case
        newS2S.reload();
        system.assertEquals(null,newS2S.s2sCase.Origin);
        system.assertEquals(null,newS2s.s2sCase.Subject);
        test.stopTest();
    }
    
}