/* 
   Test methods for Tarmika Bridge 

   
  History
  -------
  12/01/2022 Carrie Marciano        Created
  02/06/2024 Carrie Marciano		Updated test methods to include Onboarding_Format__c = 'Direct Bill' when creating test opportunitites to pass validation rules

*/
@isTest
public class TarmikaBridgeControllerTest {
	public static ID pcRT = Label.PCQuoteDataRecordTypeId;
    public static string oppProb = label.PCQuoteDataProbability;
    public static String [] dqSalesOrgs = Label.PCQuoteDataSalesOrg.split(',');
    public static ID smbRT = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity').getRecordTypeId();
    
    @testSetup
    public static void setupData() {
    	WebServiceSettings__c TarmikaBOP = new WebServiceSettings__c(
            Name = 'TarmikaBOP'
            ,Timeout__c = '10000'
            ,IsActive__c=true
            ,LogAllCalls__c=true
            ,Endpoint__c = 'https://test2ca.mond-cloud.com/TarmikaInsuranceAgencyQuoteAPIV2/submitInsuredBusinessData'
        );
        WebServiceSettings__c TarmikaWC = new WebServiceSettings__c(
            Name = 'TarmikaWC'
            ,Timeout__c = '10000'
            ,IsActive__c=true
            ,LogAllCalls__c=true
            ,Endpoint__c = 'https://test2ca.mond-cloud.com/TarmikaInsuranceAgencyQuoteAPIWC/submitInsuredBusinessData'
        );
        WebServiceSettings__c[] wssList = new WebServiceSettings__c[]{TarmikaBOP,TarmikaWC};
            insert wssList;	
    }
    
    static testMethod void testToken() {
            Test.startTest();
            TarmikaBridgeControllerMock mock = new TarmikaBridgeControllerMock();
            mock.responseToUse = TarmikaBridgeControllerMock.tokenResponse;
        	Test.setMock(HttpCalloutMock.class, mock);
            String token = TarmikaBridgeToken.getToken();
            System.assertEquals(TarmikaBridgeControllerMock.returnToken,token);
    } // testToken
    
        static testMethod void testValidPCBOP() {
    	Opportunity returnOpp;
        User userPC = [SELECT Id FROM User WHERE isActive = true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:dqSalesOrgs LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Access_to_P_C_Quote_Data_PC_Rep' Limit 1];
        //query custom permission, cannot create in test
        CustomPermission cp = [SELECT Id,MasterLabel,DeveloperName FROM CustomPermission WHERE MasterLabel = 'P&C Quote Data Access' LIMIT 1];
        PermissionSetAssignment[] existingPSA = [SELECT Id, AssigneeId, PermissionSetId from PermissionSetAssignment WHERE AssigneeId=:userPC.Id and PermissionSetId=: ps.Id LIMIT 1];
        if (existingPSA.isEmpty()){
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userPC.Id, PermissionSetId = ps.Id);
            insert psa;
        }
        
        System.RunAs(userPC){
       		Account acct1 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913'
                                   ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
            insert acct1;
            
            Contact ctct1a = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct1.id);
            insert ctct1a;
               
            Opportunity oppPCValidBOP = new Opportunity(Name='PC OPP', AccountId=acct1.Id, RecordTypeId = pcRT, OpportunityType__c = 'BOP (Business Owners Package)', HNBF_Sales_Type__c = 'New Case', Renewal_Date__c=null, Employees_Paid_Per_Payroll__c=0, CloseDate=Date.today().addDays(7), Onboarding_Format__c = 'Direct Bill', StageName = 'Proposal', Probability = 50);
            insert oppPCValidBOP;	    
            
            OpportunityContactRole ocrBOP = new OpportunityContactRole(OpportunityId=oppPCValidBOP.Id, ContactId=ctct1a.Id, IsPrimary=true, Role='Decision Maker');
            insert ocrBOP;
            
       		TarmikaBridgeController.OppWrapper wrapBOP = TarmikaBridgeController.validCheck(oppPCValidBOP.Id, returnOpp);
            System.assertEquals(True, wrapBOP.hasOpptyStage);
            System.assertEquals(True, wrapBOP.hasOpptyRecordType);
            System.assertEquals(True, wrapBOP.hasValidUser);
            
            Test.startTest();
            TarmikaBridgeToken.TarmikaTokenWrapper wrap = new TarmikaBridgeToken.TarmikaTokenWrapper();
            wrap.Token = 'Token';
            wrap.TokenExp = 1;
            wrap.TokenStartDT = DateTime.now();
            wrap.TokenExpiryDT = DateTime.now().addHours(1);
            TarmikaBridgeToken.tokenWrap=wrap;
            
            TarmikaBridgeControllerMock mock = new TarmikaBridgeControllerMock();
            mock.responseToUse = TarmikaBridgeControllerMock.successResponse;
        	Test.setMock(HttpCalloutMock.class, mock);
            TarmikaBridgeController.OppWrapper pWrapBOP = TarmikaBridgeController.postCall(wrapBOP.quoteRec);
            Test.stopTest();
            
            System.assertEquals(True, pWrapBOP.validAPICall);
            System.assertEquals(True, pWrapBOP.quoteCreated);
            
        }
    } //testValidPCBOP
    
    static testMethod void testValidPCWC() {
    	Opportunity returnOpp;
        User userPC = [SELECT Id FROM User WHERE isActive = true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:dqSalesOrgs LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Access_to_P_C_Quote_Data_PC_Rep' Limit 1];
        //query custom permission, cannot create in test
        CustomPermission cp = [SELECT Id,MasterLabel,DeveloperName FROM CustomPermission WHERE MasterLabel = 'P&C Quote Data Access' LIMIT 1];
        PermissionSetAssignment[] existingPSA = [SELECT Id, AssigneeId, PermissionSetId from PermissionSetAssignment WHERE AssigneeId=:userPC.Id and PermissionSetId=: ps.Id LIMIT 1];
        if (existingPSA.isEmpty()){
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userPC.Id, PermissionSetId = ps.Id);
            insert psa;
        }
        
        System.RunAs(userPC){
       		Account acct1 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913'
                                   ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
            insert acct1;
            
            Contact ctct1a = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct1.id);
            insert ctct1a;
               
            Opportunity oppPCValidWC = new Opportunity(Name='PC OPP', AccountId=acct1.Id, RecordTypeId = pcRT, OpportunityType__c = 'Workers Comp', HNBF_Sales_Type__c = 'New Case', Renewal_Date__c=Date.today(), Employees_Paid_Per_Payroll__c=57, CloseDate=Date.today().addDays(7), Onboarding_Format__c = 'Direct Bill', StageName = 'Proposal', Probability = 50);
            insert oppPCValidWC;	    
            
            OpportunityContactRole ocrWC = new OpportunityContactRole(OpportunityId=oppPCValidWC.Id, ContactId=ctct1a.Id, IsPrimary=true, Role='Decision Maker');
            insert ocrWC;
            
            TarmikaBridgeController.OppWrapper wrapWC = TarmikaBridgeController.validCheck(oppPCValidWC.Id, returnOpp);
            System.assertEquals(True, wrapWC.hasOpptyStage);
            System.assertEquals(True, wrapWC.hasOpptyRecordType);
            System.assertEquals(True, wrapWC.hasValidUser);
            
            Test.startTest();
            TarmikaBridgeToken.TarmikaTokenWrapper wrap = new TarmikaBridgeToken.TarmikaTokenWrapper();
            wrap.Token = 'Token';
            wrap.TokenExp = 1;
            wrap.TokenStartDT = DateTime.now();
            wrap.TokenExpiryDT = DateTime.now().addHours(1);
            TarmikaBridgeToken.tokenWrap=wrap;
            
            TarmikaBridgeControllerMock mock = new TarmikaBridgeControllerMock();
            mock.responseToUse = TarmikaBridgeControllerMock.successResponse;
        	Test.setMock(HttpCalloutMock.class, mock);
            TarmikaBridgeController.OppWrapper pWrapWC = TarmikaBridgeController.postCall(wrapWC.quoteRec);
            Test.stopTest();
           
            System.assertEquals(True, pWrapWC.validAPICall);
            System.assertEquals(True, pWrapWC.quoteCreated);
        }
    } //testValidPCWC
    
    static testMethod void testInvalidPCWC() {
        Opportunity returnOpp;
        User userPC = [SELECT Id FROM User WHERE isActive = true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:dqSalesOrgs LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Access_to_P_C_Quote_Data_PC_Rep' Limit 1];
        //query custom permission, cannot create in test
        CustomPermission cp = [SELECT Id,MasterLabel,DeveloperName FROM CustomPermission WHERE MasterLabel = 'P&C Quote Data Access' LIMIT 1];
        PermissionSetAssignment[] existingPSA = [SELECT Id, AssigneeId, PermissionSetId from PermissionSetAssignment WHERE AssigneeId=:userPC.Id and PermissionSetId=: ps.Id LIMIT 1];
        if (existingPSA.isEmpty()){
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userPC.Id, PermissionSetId = ps.Id);
            insert psa;
        }
        
        System.RunAs(userPC){
            Account acct1 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913'
                                        ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
            insert acct1;
            
            Contact ctct1a = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct1.id);
            insert ctct1a;
            
            Opportunity oppPCValidWC = new Opportunity(Name='PC OPP', AccountId=acct1.Id, RecordTypeId = pcRT, OpportunityType__c = 'Workers Comp', HNBF_Sales_Type__c = 'New Case', Renewal_Date__c=Date.today(), Employees_Paid_Per_Payroll__c=57, CloseDate=Date.today().addDays(7), Onboarding_Format__c = 'Direct Bill', StageName = 'Proposal', Probability = 50);
            insert oppPCValidWC;	    
            
            OpportunityContactRole ocrWC = new OpportunityContactRole(OpportunityId=oppPCValidWC.Id, ContactId=ctct1a.Id, IsPrimary=true, Role='Decision Maker');
            insert ocrWC;
            
            TarmikaBridgeController.OppWrapper wrapWC = TarmikaBridgeController.validCheck(oppPCValidWC.Id, returnOpp);
            System.assertEquals(True, wrapWC.hasOpptyStage);
            System.assertEquals(True, wrapWC.hasOpptyRecordType);
            System.assertEquals(True, wrapWC.hasValidUser);
            
            Test.startTest();
            TarmikaBridgeToken.TarmikaTokenWrapper wrap = new TarmikaBridgeToken.TarmikaTokenWrapper();
            wrap.Token = 'Token';
            wrap.TokenExp = 1;
            wrap.TokenStartDT = DateTime.now();
            wrap.TokenExpiryDT = DateTime.now().addHours(1);
            TarmikaBridgeToken.tokenWrap=wrap;
            
            TarmikaBridgeControllerMock mock = new TarmikaBridgeControllerMock();
            mock.responseToUse = TarmikaBridgeControllerMock.failureResponse;
            Test.setMock(HttpCalloutMock.class, mock);
            TarmikaBridgeController.OppWrapper pWrapWC = TarmikaBridgeController.postCall(wrapWC.quoteRec);
            Test.stopTest();
            
            System.assertEquals(False, pWrapWC.validAPICall);
            System.assertEquals(False, pWrapWC.quoteCreated);
            
        }
    } //testInvalidPCWC
    
    static testMethod void testNotValidPC() {
    	Opportunity returnOpp;
        User dummyUser = [SELECT id FROM User WHERE IsActive = true and Profile.Name = 'System Administrator' AND Id != :UserInfo.getUserId() LIMIT 1];
        User userPC = [SELECT Id FROM User WHERE isActive = true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:dqSalesOrgs LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Access_to_P_C_Quote_Data_PC_Rep' Limit 1];
        //query custom permission, cannot create in test
        CustomPermission cp = [SELECT Id,MasterLabel,DeveloperName FROM CustomPermission WHERE MasterLabel = 'P&C Quote Data Access' LIMIT 1];
        PermissionSetAssignment[] existingPSA = [SELECT Id, AssigneeId, PermissionSetId from PermissionSetAssignment WHERE AssigneeId=:userPC.Id and PermissionSetId=: ps.Id LIMIT 1];
        if (existingPSA.isEmpty()){
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userPC.Id, PermissionSetId = ps.Id);
            insert psa;
        }
        
        System.RunAs(userPC){
            Account acct1 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913'
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
            insert acct1;
            
            Contact ctct1a = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct1.id);
            insert ctct1a;
               
            Opportunity oppPCNotValid = new Opportunity(Name='PC OPP', AccountId=acct1.Id, RecordTypeId = pcRT, OpportunityType__c = 'BOP (Business Owners Package)', HNBF_Sales_Type__c = 'New Case', CloseDate=Date.today().addDays(7), Renewal_Date__c=Date.today().addDays(25),StageName = 'IEUP', Probability = 30);
            insert oppPCNotValid;
            
            OpportunityContactRole ocr1 = new OpportunityContactRole(OpportunityId=oppPCNotValid.Id, ContactId=ctct1a.Id, IsPrimary=true, Role='Decision Maker');
            insert ocr1;
        
        
        	TarmikaBridgeController.OppWrapper wrap = TarmikaBridgeController.validCheck(oppPCNotValid.Id, returnOpp);
            System.assertEquals(False, wrap.hasOpptyStage);
            System.assertEquals(True, wrap.hasOpptyRecordType);
            System.assertEquals(True, wrap.hasValidUser);    
        }    
    } //testNotValidPC
    
    static testMethod void testPay() {
        Opportunity returnOpp;
        User userPay = [SELECT Id FROM User WHERE isActive = true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c!=:dqSalesOrgs LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Access_to_P_C_Quote_Data_Payroll_Rep' Limit 1];
        //query custom permission, cannot create in test
        CustomPermission cp = [SELECT Id,MasterLabel,DeveloperName FROM CustomPermission WHERE MasterLabel = 'P&C Quote Data Access' LIMIT 1];
        PermissionSetAssignment[] existingPSA = [SELECT Id, AssigneeId, PermissionSetId from PermissionSetAssignment WHERE AssigneeId=:userPay.Id and PermissionSetId=: ps.Id LIMIT 1];
        if (existingPSA.isEmpty()){
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userPay.Id, PermissionSetId = ps.Id);
            insert psa;
        }
        
        System.RunAs(userPay){
            Account acct1 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913'
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
            insert acct1;
            
            Contact ctct1a = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct1.id);
            insert ctct1a;
               
            Opportunity oppPay = new Opportunity(Name='Pay OPP', AccountId=acct1.Id, RecordTypeId = smbRT, CloseDate=Date.today().addDays(7), StageName = 'Proposal', Probability = 50);
            insert oppPay; 
            
            OpportunityContactRole ocr1 = new OpportunityContactRole(OpportunityId=oppPay.Id, ContactId=ctct1a.Id, IsPrimary=true, Role='Decision Maker');
            insert ocr1;
        
        	TarmikaBridgeController.OppWrapper wrap = TarmikaBridgeController.validCheck(oppPay.Id, returnOpp);
            System.assertEquals(True, wrap.hasOpptyStage);
            System.assertEquals(False, wrap.hasOpptyRecordType);
            System.assertEquals(False, wrap.hasValidUser);    
        }    
    } //testPay
    
}