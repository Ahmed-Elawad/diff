/**
 * This class contains unit tests for validating the RefMMSPayrollHelper class which is called by RefMMSPayrollAfter trigger
 *
 * History
 * --------
 * 03/21/2013	Cindy Freeman	created
 * 12/14/2015   Lynn Michels	edited to pass and test MPSC documents also.
 * 03/25/2024 Carrie Marciano	CanBeDeleted old MPSC tech debt
 */
 @isTest
private class RefMMSPayrollHelperTest {
    static testMethod void myUnitTest() {
        new RefMMSPayrollHelper();
    }
/*
    static testMethod void refMMSPayrollTest() {
		
		// create test onboarding documents
		List<MMS_Onboarding_Documents__c> mmsOnbrdingDocs = new List<MMS_Onboarding_Documents__c>();
		MMS_Onboarding_Documents__c doc1 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Payroll Doc1'
																			, Mandatory__c = true
																			, MMS_Payroll_Document__c = true
																			, Product_Category__c = null );
		mmsOnbrdingDocs.add(doc1);
		MMS_Onboarding_Documents__c doc2 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Taxpay Doc2'
																			, Mandatory__c = false
																			, MMS_Payroll_Document__c = true
																			, Product_Category__c = 'TaxPay' );
		mmsOnbrdingDocs.add(doc2);
		MMS_Onboarding_Documents__c doc3 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Signature Doc3'
																			, Mandatory__c = false
																			, MMS_Payroll_Document__c = true
																			, Product_Category__c = 'CheckSign;Logo Service' );
		mmsOnbrdingDocs.add(doc3);
		insert mmsOnbrdingDocs;
		  	
		   	
        CreateTestData.createTestAandC();
        Account a1 = [select Id, Name from Account where name = 'Test Account2'];
		Contact ctct1 = [select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First'];
		
		List<Id> testOptyIds = new List<Id>();		
		// create and mark Sold MMS opty that will create Case and Reference Object and Onboarding Documents
		testOptyIds.add(CreateTestData.createTestMMSSoldOptys(a1.Id, ctct1.Id));       
        	
        Date testDate = Date.valueOf(System.now());	
		Reference_MMS_Payroll__c refmmsObj = new Reference_MMS_Payroll__c(Date_Client_Load_Received__c = testDate
																		, Client_Load_Submission_Method__c ='Mid-Market Sales Tool'
																		, Zero_Wage_Start__c = 'Yes'
																		, Taxpay_Indicator__c = 'Yes'
																		, New_Business_Indicator__c = 'Yes'
																		, Opportunity_Name__c = testOptyIds.get(0)
																		, Product_Summary__c = 'Payroll;TaxPay'
																		);
		insert refmmsObj;
		Reference_MMS_Payroll_Documents__c[] mmsDocs = [SELECT Id, Document__c, Mandatory__c from Reference_MMS_Payroll_Documents__c
														WHERE Reference_MMS_Payroll__c = :refmmsObj.Id];
		
		System.assertEquals(2, mmsDocs.size());

    }
    
     static testMethod void refCorePayrollTest() {
		
		// create test onboarding documents
		List<MMS_Onboarding_Documents__c> mmsOnbrdingDocs = new List<MMS_Onboarding_Documents__c>();
		MMS_Onboarding_Documents__c doc1 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Payroll Doc1'
																			, Mandatory_for_MPSC__c = true
																			, MPSC_Onboarding_Document__c = true
																			, Product_Category__c = null );
		mmsOnbrdingDocs.add(doc1);
		MMS_Onboarding_Documents__c doc2 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Taxpay Doc2'
																			, Mandatory_for_MPSC__c = false
																			, MPSC_Onboarding_Document__c = true
																			, Product_Category__c = 'TaxPay' );
		mmsOnbrdingDocs.add(doc2);
		MMS_Onboarding_Documents__c doc3 = new MMS_Onboarding_Documents__c(Document_Name__c = 'Signature Doc3'
																			, Mandatory_for_MPSC__c = false
																			, MPSC_Onboarding_Document__c = true
																			, Product_Category__c = 'CheckSign;Logo Service' );
		mmsOnbrdingDocs.add(doc3);
		insert mmsOnbrdingDocs;
		  	
		   	
        // create account, contact   
        CreateTestData.createTestAandC();
        Account a1 = [select Id, Name from Account where name = 'Test Account2'];
		Contact ctct1 = [select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First'];
		List<Id> testOptyIds = new List<Id>();	
                                
		// create a Core Opportunity, mark it Sold - that will create Case and Reference Object and Onboarding Documents
		testOptyIds.add(CreateTestData.createTestCoreOptys(a1.Id, ctct1.Id)); 
		List<Opportunity> opps = [SELECT Id, OwnerId, Product_Summary__c FROM Opportunity WHERE AccountId =: a1.id]; 
		opps.get(0).Product_Summary__c = 'TaxPay;Payroll';
		opps.get(0).TotalOpportunityQuantity = 1;
        opps.get(0).Employees_Paid_Per_Payroll__c = 2;
        opps.get(0).Frequency__c = '1';
        opps.get(0).Amount = 100;
        opps.get(0).StageName = 'Sold';
        opps.get(0).Service_Location__c = 'Foxboro Branch 0008';
        opps.get(0).Prod_Payroll__c = true;
		update opps;
	
    	Reference_MPSC_Onboarding_Document__c[] refMPSCDoc = [SELECT Id, Document__c, Received_State__c, Comments__c, 
														    	Discrepancy_Resolution_Date__c, Check_In_Date__c
														    	FROM Reference_MPSC_Onboarding_Document__c];
		System.assertEquals(2, refMPSCDoc.size());

    }
*/	
}