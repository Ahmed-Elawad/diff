/*
 *
 * History
 * --------
   04/17/2024  Carrie Marciano  created

*/ 

@isTest
public class MPSCEmailHelperTest {

    static testMethod void testCaseStatuses(){
        Id caseRT = RecordTypeHelper.getRecordType('Multi-Product Service Case','Case').getRecordTypeId();    
        PaychexSettings__c pxs = new PaychexSettings__c (name='MPSCForwardErrorEmail',IsActive__c = true , Attribute1__c ='cmarciano@paychex.com'); 
        insert pxs;
        
        Account acct1 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913', AccountNumber='903-19048033', Bis_ID__c=4759974
                                    ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct1;
        
        Contact ctct1 = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct1.id);
        insert ctct1;
        
        Case case1 = new Case(recordTypeId = caseRT, ContactId = ctct1.Id, AccountId=acct1.Id, Subject = 'TaxPay Submission', Type = 'Taxpay', Status = 'Submitted', Is_Created_by_Mid_Market_Flow__c = True);
        insert case1;
        
        Reference_MPSC_Service_Submission__c rMPSC1 = new Reference_MPSC_Service_Submission__c(Case__c = case1.Id);
        insert rMPSC1;
        
        // populate plain text email body
        String test1 = '<MPSCINFORMATION>\r  <CaseNumber>'+ case1.CaseNumber +'</CaseNumber>\r <CaseId>'+ case1.Id+'</CaseId>\r';
        test1 += '<ProcessType>TaxPay</ProcessType>\r <Status>Submitted</Status>\r <ReasonForRequest>Want to make changes</ReasonForRequest>\r';
        test1 += '<AgencyType>CPA</AgencyType>\r <IncorrectAgencyState>Yes</IncorrectAgencyState>\r <IncorrectAgencySUI>Yes</IncorrectAgencySUI>\r';
        test1 += '<IncorrectAgencyDBL>Yes</IncorrectAgencyDBL>\r <IncorrectAgencyLocal>Yes</IncorrectAgencyLocal>\r <CorrectAgencyState>NY</CorrectAgencyState>\r';
        test1 += '<CorrectAgencySUI>NYSUI</CorrectAgencySUI>\r <CorrectAgencyDBL>NYDBL</CorrectAgencyDBL>\r <CorrectAgencyLocal>Monroe</CorrectAgencyLocal>\r <RequestDetails>deductions</RequestDetails>\r';
        test1 += '<NumOfEEsAffected>112</NumOfEEsAffected>\r <EENumbers>1,2,3,4,5,6,7,8,9</EENumbers>\r <BeginningCheckDate>4/12/2024</BeginningCheckDate>\r <EndingCheckDate>4/26/2024</EndingCheckDate>\r';
        test1 += '<ErrorResponsibilityClient>Yes</ErrorResponsibilityClient>\r <ErrorResponsibilityPaychex>No</ErrorResponsibilityPaychex>\r <AssignedTo>calvin Broadus</AssignedTo>\r <EstCompleteDate>5/1/2024</EstCompleteDate>\r';
        test1 += '<LateOriginalsNeeded>Yes</LateOriginalsNeeded>\r <AmededReturnsNeeded>No</AmededReturnsNeeded>\r'; 
        test1 += '</MPSCINFORMATION>';         
        
        // call Helper class directly to check parsing then process list        
        MPSCEmailHelper.pAppInfo pApp = new MPSCEmailHelper.pAppInfo();        
        pApp = MPSCEmailHelper.parseXml(test1);
        
        List<MPSCEmailHelper.pAppInfo> pAppList = new List<MPSCEmailHelper.pAppInfo>();
		pAppList.add(pApp);
        
        MPSCEmailHelper.processInfo(pAppList); 
        
        case1 = [Select Id, CaseNumber, Status, Status_Description__c, Submitted_Date__c from Case where Id =:case1.Id];   
        System.assertEquals('Submitted', case1.Status);
        System.assertNotEquals(null, case1.Submitted_Date__c);
        
        // Status Change - On Hold
        MPSCStatusMapping__mdt[] statusMapping = [select MasterLabel, PowerAppStatus__c, Case_Status__c from MPSCStatusMapping__mdt where label ='Waiting on Submitter Response']; 
        System.assertEquals('On Hold',statusMapping[0].Case_Status__c);
        
        // populate plain text email body
        String test2 = '<MPSCINFORMATION>\r  <CaseNumber>'+ case1.CaseNumber +'</CaseNumber>\r <CaseId>'+ case1.Id+'</CaseId>\r';
        test2 += '<ProcessType>TaxPay</ProcessType>\r <Status>Waiting on Submitter Response</Status>\r';
        test2 += '</MPSCINFORMATION>';         
        
        // call Helper class directly to check parsing then process list        
        MPSCEmailHelper.pAppInfo pApp2 = new MPSCEmailHelper.pAppInfo();        
        pApp2 = MPSCEmailHelper.parseXml(test2);
        
        List<MPSCEmailHelper.pAppInfo> pAppList2 = new List<MPSCEmailHelper.pAppInfo>();
		pAppList2.add(pApp2);
        
        MPSCEmailHelper.processInfo(pAppList2);  
        
        case1 = [Select Id, CaseNumber, Status, Status_Description__c, Submitted_Date__c from Case where Id =:case1.Id];
        System.assertEquals('On Hold', case1.Status);
                
        // Status Change - Closed
        MPSCStatusMapping__mdt[] statusMapping2 = [select MasterLabel, PowerAppStatus__c, Case_Status__c from MPSCStatusMapping__mdt where label ='Adjustment Completed - No Further Action']; 
        System.assertEquals('Closed',statusMapping2[0].Case_Status__c);
        
        // populate plain text email body
        String test3 = '<MPSCINFORMATION>\r  <CaseNumber>'+ case1.CaseNumber +'</CaseNumber>\r <CaseId>'+ case1.Id+'</CaseId>\r';
        test3 += '<ProcessType>TaxPay</ProcessType>\r <Status>Adjustment Completed - No Further Action Needed</Status>\r';
        test3 += '</MPSCINFORMATION>';         
        
        // call Helper class directly to check parsing then process list creating new account and contact       
        MPSCEmailHelper.pAppInfo pApp3 = new MPSCEmailHelper.pAppInfo();
        //Test.startTest();        
        pApp3 = MPSCEmailHelper.parseXml(test3);
        
        List<MPSCEmailHelper.pAppInfo> pAppList3 = new List<MPSCEmailHelper.pAppInfo>();
		pAppList3.add(pApp3);
        
        MPSCEmailHelper.processInfo(pAppList3); 
        
        case1 = [Select Id, CaseNumber, Status, Status_Description__c, Submitted_Date__c from Case where Id =:case1.Id];
        System.assertEquals('Closed', case1.Status);
     
    } //testCaseStatuses
    
    static testMethod void testReferenceSubmissionwithFields(){
        Id caseRT = RecordTypeHelper.getRecordType('Multi-Product Service Case','Case').getRecordTypeId();    
        PaychexSettings__c pxs = new PaychexSettings__c (name='MPSCForwardErrorEmail',IsActive__c = true , Attribute1__c ='cmarciano@paychex.com'); 
        insert pxs;
        
        Account acct2 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913', AccountNumber='903-19048033', Bis_ID__c=4759974
                                    ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct2;
        
        Contact ctct2 = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct2.id);
        insert ctct2;
        
        Case case2 = new Case(recordTypeId = caseRT, ContactId = ctct2.Id, AccountId=acct2.Id, Subject = 'TaxPay Submission', Type = 'Taxpay', Status = 'Submitted', Is_Created_by_Mid_Market_Flow__c = True);
        insert case2;
        
        Reference_MPSC_Service_Submission__c rMPSC2 = new Reference_MPSC_Service_Submission__c(Case__c = case2.Id);
        insert rMPSC2;
        
        // populate plain text email body
        String test2 = '<MPSCINFORMATION>\r  <CaseNumber>'+ case2.CaseNumber +'</CaseNumber>\r <CaseId>'+ case2.Id+'</CaseId>\r';
        test2 += '<ProcessType>Loss</ProcessType>\r <Status>Submitted</Status>\r <LastPayrollDate>4/10/2024</LastPayrollDate>\r';
        test2 += '<ReasonForLeaving>Because I want to</ReasonForLeaving>\r <AlreadyHavePayrol>Yes</AlreadyHavePayrol>\r <IsClientASO>False</IsClientASO>\r';
        test2 += '<LastCheckDate>4/17/2024</LastCheckDate>\r <LastTaxQuarterWorked>Q4</LastTaxQuarterWorked>\r <PayrollTermDate>4/10/2024</PayrollTermDate>\r';
        test2 += '<NeedYEReturns>Yes</NeedYEReturns>\r <filedOnTaxpay>Yes</filedOnTaxpay>\r <FuturePayroll>No</FuturePayroll>\r <ExplanationOfLoss>Didnt like it</ExplanationOfLoss>\r';
        test2 += '</MPSCINFORMATION>';         
        
        // call Helper class directly to check parsing then process list        
        MPSCEmailHelper.pAppInfo pApp2 = new MPSCEmailHelper.pAppInfo();        
        pApp2 = MPSCEmailHelper.parseXml(test2);
        
        List<MPSCEmailHelper.pAppInfo> pAppList2 = new List<MPSCEmailHelper.pAppInfo>();
		pAppList2.add(pApp2);
        
        MPSCEmailHelper.processInfo(pAppList2); 
        
        case2 = [Select Id, CaseNumber, Status, Status_Description__c, Submitted_Date__c from Case where Id =:case2.Id];   
        System.assertEquals('Submitted', case2.Status);
        System.assertNotEquals(null, case2.Submitted_Date__c);
        
        // Status Change - On Hold
        MPSCStatusMapping__mdt[] statusMapping = [select MasterLabel, PowerAppStatus__c, Case_Status__c from MPSCStatusMapping__mdt where label ='Waiting on Submitter Response']; 
        System.assertEquals('On Hold',statusMapping[0].Case_Status__c);
        
    } //testReferenceSubmissionwithFields
    
   /* static testMethod void testBadCaseId(){
        Boolean testPassed = false;
    	Id caseRT = RecordTypeHelper.getRecordType('Multi-Product Service Case','Case').getRecordTypeId();    
        PaychexSettings__c pxs = new PaychexSettings__c (name='MPSCForwardErrorEmail',IsActive__c = true , Attribute1__c ='cmarciano@paychex.com'); 
        insert pxs;
        
        Account acct3 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913', AccountNumber='903-19048033', Bis_ID__c=4759974
                                    ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct3;
        
        Contact ctct3 = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct3.id);
        insert ctct3;
        
        Case case3 = new Case(recordTypeId = caseRT, ContactId = ctct3.Id, AccountId=acct3.Id, Subject = 'TaxPay Submission', Type = 'Taxpay', Status = 'Submitted');
        insert case3;
        
        Reference_MPSC_Service_Submission__c rMPSC3 = new Reference_MPSC_Service_Submission__c(Case__c = case3.Id);
        insert rMPSC3;
        
        // populate plain text email body
        String test3 = '<MPSCINFORMATION>\r  <CaseNumber>'+ case3.CaseNumber +'</CaseNumber>\r <CaseId></CaseId>\r';
        test3 += '<ProcessType>Loss</ProcessType>\r <Status>Submitted</Status>\r <LastPayrollDate>4/10/2024</LastPayrollDate>\r';
        test3 += '<ReasonForLeaving>Because I want to</ReasonForLeaving>\r <AlreadyHavePayrol>Yes</AlreadyHavePayrol>\r <IsClientASO>False</IsClientASO>\r';
        test3 += '<LastCheckDate>4/17/2024</LastCheckDate>\r <LastTaxQuarterWorked>Q4</LastTaxQuarterWorked>\r <PayrollTermDate>4/10/2024</PayrollTermDate>\r';
        test3 += '<NeedYEReturns>Yes</NeedYEReturns>\r <filedOnTaxpay>Yes</filedOnTaxpay>\r <FuturePayroll>No</FuturePayroll>\r <ExplanationOfLoss>Didnt like it</ExplanationOfLoss>\r';
        test3 += '</MPSCINFORMATION>';         
        
        // call Helper class directly to check parsing then process list        
        MPSCEmailHelper.pAppInfo pApp3 = new MPSCEmailHelper.pAppInfo();        
        pApp3 = MPSCEmailHelper.parseXml(test3);
        
        List<MPSCEmailHelper.pAppInfo> pAppList3 = new List<MPSCEmailHelper.pAppInfo>();
		pAppList3.add(pApp3);
        
        try{
        	MPSCEmailHelper.processInfo(pAppList3);    
        }
        catch(MPSCEmailHelper.MPSCEmailException ex){
        	testPassed = true;  // sends email instead of throwing error coz email body is empty    
        }
        System.assertEquals(false, testPassed); 
           
    } //testBadCaseId */
}