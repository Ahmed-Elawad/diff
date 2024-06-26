/*
*  Test method for MPSCEmailHandler
*
* History
* --------
* 04/17/2024  Carrie Marciano  created
*/ 

@isTest
public class MPSCEmailHandlerTest {
    
    // test good parsing of plain text
    @isTest(SeeAllData=false)
    static void testGoodDataLossSubmission() {   
        Id caseRT = RecordTypeHelper.getRecordType('Multi-Product Service Case','Case').getRecordTypeId();    
        
        Account acct1 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913', AccountNumber='903-19048033', Bis_ID__c=4759974
                                    ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct1;
        
        Contact ctct1 = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct1.id);
        insert ctct1;
        
        Case case1 = new Case(recordTypeId = caseRT, ContactId = ctct1.Id, AccountId=acct1.Id, Subject = 'Loss Submission Valid Data', Type = 'Loss', Status = 'New', Is_Created_by_Mid_Market_Flow__c = True);
        insert case1;
        
        case1 = [Select Id, CaseNumber, Status, Status_Description__c, Submitted_Date__c from Case where Id =:case1.Id];
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        // setup the data for the email
        email.subject = 'MPSC Information';
        email.fromname = 'FirstName LastName';
        env.fromAddress = 'someaddress@email.com';
        
        // populate plain text email body
        String test1 = '<MPSCINFORMATION>\r  <CaseNumber>'+ case1.CaseNumber +'</CaseNumber>\r <CaseId>'+ case1.Id+'</CaseId>\r';
        test1 += '<ProcessType>Loss</ProcessType>\r <Status>Submitted</Status>\r <LastPayrollDate>4/10/2024</LastPayrollDate>\r';
        test1 += '<ReasonForLeaving>Because I want to</ReasonForLeaving>\r <AlreadyHavePayrol>Yes</AlreadyHavePayrol>\r <IsClientASO>False</IsClientASO>\r';
        test1 += '<LastCheckDate>4/17/2024</LastCheckDate>\r <LastTaxQuarterWorked>Q4</LastTaxQuarterWorked>\r <PayrollTermDate>4/10/2024</PayrollTermDate>\r';
        test1 += '<NeedYEReturns>Yes</NeedYEReturns>\r <filedOnTaxpay>Yes</filedOnTaxpay>\r <FuturePayroll>No</FuturePayroll>\r <ExplanationOfLoss>Didnt like it</ExplanationOfLoss>\r';
        test1 += '</MPSCINFORMATION>';         
        email.plainTextBody = test1;
        
        // call Helper class directly to check parsing then process list       
        MPSCEmailHelper.pAppInfo pApp = new MPSCEmailHelper.pAppInfo();
        //Test.startTest();        
        pApp = MPSCEmailHelper.parseXml(email.plainTextBody);
        
        System.assertEquals(pApp.CaseNumber, case1.CaseNumber);
        System.assertEquals(pApp.Status, 'Submitted');
        
        MPSCEmailHandler mpscEH = new MPSCEmailHandler();
        mpscEH.handleInboundEmail(email, env); 
        
    } // testGoodDataLossSubmission  
    
    static string addXML(string tag, string content){
        return '<' + tag + '>' + content + '</' + tag + '>\r\n';
    }
    
    @isTest(SeeAllData=false)
    static void testGoodDataHTML() {
        Id caseRT = RecordTypeHelper.getRecordType('Multi-Product Service Case','Case').getRecordTypeId();    
        
        Account acct2 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913', AccountNumber='903-19048033', Bis_ID__c=4759974
                                    ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct2;
        
        Contact ctct2 = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct2.id);
        insert ctct2;
        
        Case case2 = new Case(recordTypeId = caseRT, ContactId = ctct2.Id, AccountId=acct2.Id, Subject = 'Loss Submission Valid Data', Type = 'Loss', Status = 'New', Is_Created_by_Mid_Market_Flow__c = True);
        insert case2;
        
        case2 = [Select Id, CaseNumber, Status, Status_Description__c, Submitted_Date__c from Case where Id =:case2.Id];
        
        Messaging.InboundEmail email2 = new Messaging.InboundEmail();        
        
        email2.htmlBody = '<MPSCInformation>';           
        email2.htmlBody += addXML('CaseNumber',case2.CaseNumber);
        email2.htmlBody += addXML('CaseId',case2.Id);
        email2.htmlBody += addXML('ProcessType','Loss');
        email2.htmlBody += addXML('Status','Submitted');
        email2.htmlBody += addXML('LastPayrollDat','4/10/2024');
        email2.htmlBody += addXML('ReasonForLeaving','Because');
        email2.htmlBody += addXML('AlreadyHavePayrol','yes');
        email2.htmlBody += '</MPSCInformation>\r\nThe information contained';
        
        Messaging.InboundEnvelope env2 = new Messaging.InboundEnvelope();
        MPSCEmailHandler mpscEH2 = new MPSCEmailHandler();
        mpscEH2.handleInboundEmail(email2, env2); 
        
    } // testGoodDataHTML
    
    @isTest(SeeAllData=false)
    static void testGoodDataHTMLCaps() {
        Id caseRT = RecordTypeHelper.getRecordType('Multi-Product Service Case','Case').getRecordTypeId();    
        
        Account acct3 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913', AccountNumber='903-19048033', Bis_ID__c=4759974
                                    ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct3;
        
        Contact ctct3 = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct3.id);
        insert ctct3;
        
        Case case3 = new Case(recordTypeId = caseRT, ContactId = ctct3.Id, AccountId=acct3.Id, Subject = 'Loss Submission Valid Data', Type = 'Loss', Status = 'New', Is_Created_by_Mid_Market_Flow__c = True);
        insert case3;
        
        case3 = [Select Id, CaseNumber, Status, Status_Description__c, Submitted_Date__c from Case where Id =:case3.Id];
        
        Messaging.InboundEmail email3 = new Messaging.InboundEmail();
        
        email3.htmlBody = '<MPSCINFORMATION>';           
        email3.htmlBody += addXML('CaseNumber',case3.CaseNumber);
        email3.htmlBody += addXML('CaseId',case3.Id);
        email3.htmlBody += addXML('ProcessType','Loss');
        email3.htmlBody += addXML('Status','Submitted');
        email3.htmlBody += addXML('LastPayrollDat','4/10/2024');
        email3.htmlBody += addXML('ReasonForLeaving','Because');
        email3.htmlBody += addXML('AlreadyHavePayrol','yes');
        email3.htmlBody += '</MPSCINFORMATION>\r\nThe information contained';

        Messaging.InboundEnvelope env3 = new Messaging.InboundEnvelope();
        MPSCEmailHandler mpscEH3 = new MPSCEmailHandler();
        mpscEH3.handleInboundEmail(email3, env3); 
        
    } // testGoodDataHTMLCaps
    
    static testMethod void testLossStatusUpdateCamel(){
        Id caseRT = RecordTypeHelper.getRecordType('Multi-Product Service Case','Case').getRecordTypeId();    
        
        Account acct4 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913', AccountNumber='903-19048033', Bis_ID__c=4759974
                                    ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct4;
        
        Contact ctct4 = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct4.id);
        insert ctct4;
        
        Case case4 = new Case(recordTypeId = caseRT, ContactId = ctct4.Id, AccountId=acct4.Id, Subject = 'Loss Submission Valid Data', Type = 'Loss', Status = 'Submitted', Is_Created_by_Mid_Market_Flow__c = True);
        insert case4;
        
        case4 = [Select Id, CaseNumber, Status, Status_Description__c, Submitted_Date__c from Case where Id =:case4.Id];
        
        MPSCStatusMapping__mdt[] statusMapping = [select MasterLabel, PowerAppStatus__c, Case_Status__c from MPSCStatusMapping__mdt where label ='Waiting for PRS to follow up']; 
        System.assertEquals('On Hold',statusMapping[0].Case_Status__c);
        
        Messaging.InboundEmail email4 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env4 = new Messaging.InboundEnvelope();
        
        // setup the data for the email
        email4.subject = 'MPSC Information';
        email4.fromname = 'FirstName LastName';
        env4.fromAddress = 'someaddress@email.com';
        
        // populate plain text email body
        String test4 = '<MPSCInformation>\r  <CaseNumber>'+ case4.CaseNumber +'</CaseNumber>\r <CaseId>'+ case4.Id+'</CaseId>\r';
        test4 += '<ProcessType>Loss</ProcessType>\r <Status>Waiting for PRS to followup</Status>\r';
        test4 += '</MPSCInformation>';         
        email4.plainTextBody = test4;
        
        // call Helper class directly to check parsing then process list creating new account and contact       
        MPSCEmailHelper.pAppInfo pApp = new MPSCEmailHelper.pAppInfo();
        //Test.startTest();        
        pApp = MPSCEmailHelper.parseXml(email4.plainTextBody);
        
        System.assertEquals(pApp.CaseNumber, case4.CaseNumber);
        System.assertEquals(pApp.Status, 'Waiting for PRS to followup');
        
        MPSCEmailHandler mpscEH4 = new MPSCEmailHandler();
        mpscEH4.handleInboundEmail(email4, env4);     
    } //testLossStatusUpdateCamel
    
    static testMethod void testBlankEmail(){
        // clear setting for this test
        try {
            delete [Select Id from PaychexSettings__c where Name='MPSCForwardErrorEmail'];
        } catch (Exception e) {
            // do nothing here.
        }
        
        Boolean testPassed = false;
        string except;
        messaging.Inboundemail email = new messaging.Inboundemail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        MPSCEmailHandler mpscEH = new MPSCEmailHandler();
        try{
            mpscEH.handleInboundEmail(email, env);
        }
        catch(MPSCEmailHandler.PAIEmailException pAe)
        {   testPassed = true;  }     // sends email instead of throwing error coz email body is empty
        System.assertEquals(false, testPassed);
        
    } //testBlankEmail
    
    static testMethod void testBadXML(){
        populatePayxSetting();
        Boolean testPassed = false;
        string except;
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.htmlBody = '<MPSCInformation><junk></MPSCInformation>';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        MPSCEmailHandler mpscEH = new MPSCEmailHandler();
        try{
            mpscEH.handleInboundEmail(email, env);
        }
        catch(MPSCEmailHandler.PAIEmailException pAe)
        {   testPassed = true;  }     // sends email instead of throwing error coz email body is empty
        System.assertEquals(false, testPassed);
        
    } //testBadXML
    
    public static void populatePayxSetting() { 
        PaychexSettings__c payx = new PaychexSettings__c (
            Name = 'MPSCForwardErrorEmail'
            ,IsActive__c=true
            ,Attribute1__c = 'dcarmen@paychex.com; someone@paychex.com');
        upsert payx;
        return;
        
    } // populatePayxSetting 
}