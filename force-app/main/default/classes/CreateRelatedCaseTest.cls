/**
 * History
 * -------
 * 07/25/2017 Lynn Michels	Created
 * 06/29/2018 Lynn Michels	Edited to reflect new current step values
 * 3/20/2024  Carrie Marciano    CanBeDeleted old MPSC tech debt
 */
@isTest
private class CreateRelatedCaseTest {
    static testMethod void myUnitTest() {
        new CreateRelatedCase();
    }

/*
    static testMethod void testOneCase() {
    	Client_Overview_Configuration__c coc = new Client_Overview_Configuration__c(Name='Core Advance Payroll' 
      																			  ,Product_Name__c='Core Payroll'
                                                                                  ,Reference_Object_Relationship_API_Name__c='Reference_Core_Payroll__r'
                                                                                  ,Completed_Onboarding_Status__c='(7 of 7) Onboarding Complete – Transitioned to support,(6 of 6) Client ready for transition'
                                                                                  ,Case_Record_Type_Name__c='Service Onboarding MPSC Core Payroll Case'
                                                                                  ,Owner_Custom_Label__c='Service Team - New Client Specialist'
                                                                                  ,Case_Only__c=FALSE
                                                                                  ,MPSC__c=TRUE);
  		insert coc;
                                                                                  
                                                                                  
       Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
       User u1 = new User(Alias = 'mickey', Email='mickeymouse@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Mouse', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Sales_Org__c = 'PAY',
            TimeZoneSidKey='America/Los_Angeles', UserName='mickeymouse@testorg.com');
       insert u1;
       
       Account acct = new Account (name = 'Test Account', OwnerId = u1.id);

        //MPSC Onboarding Case is the parent case of the MPSC Transfer case
        //The owner of this case is the Payroll IS on the Reference MPSC record
        Id mpscOnboardingCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Onboarding MPSC Core Payroll Case').getRecordTypeId();
        Case mpscOnboardingCase = new Case (recordtypeId = mpscOnboardingCaseRT
        						,AccountId = acct.id
        						,Current_Step__c = '(5 of 6) 1st run complete - Finalizing implementation');		    		
		insert mpscOnboardingCase;
		
		Id caseMPSCTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('MPSC Transfer Case').getRecordTypeId();	
		List<Case> mpscTransferCases = new List<Case>();
		mpscTransferCases = [SELECT ParentId, RecordTypeId
							FROM Case 
							WHERE ParentId =: mpscOnboardingCase.id AND RecordTypeId =: caseMPSCTransfer];
		system.assertEquals(mpscTransferCases.size(), 0);
		
		mpscOnboardingCase.Current_Step__c = '(6 of 6) Client ready for transition';
		update mpscOnboardingCase;
		
		mpscTransferCases = [SELECT ParentId, RecordTypeId
							FROM Case 
							WHERE ParentId =: mpscOnboardingCase.id AND RecordTypeId =: caseMPSCTransfer];
		system.assertEquals(mpscTransferCases.size(), 1);
		
		mpscOnboardingCase.Current_Step__c = '(4 of 6) Audit complete - Ready to run payroll';
		update mpscOnboardingCase;
		
		mpscTransferCases = [SELECT ParentId, RecordTypeId
							FROM Case 
							WHERE ParentId =: mpscOnboardingCase.id AND RecordTypeId =: caseMPSCTransfer];
		system.assertEquals(mpscTransferCases.size(), 1);
		
		mpscOnboardingCase.Current_Step__c = '(6 of 6) Client ready for transition';
		update mpscOnboardingCase;
		
		//when the current step goes below step 6 and back, a new MPSC Transfer Case should not be created.
		mpscTransferCases = [SELECT ParentId, RecordTypeId
							FROM Case 
							WHERE ParentId =: mpscOnboardingCase.id AND RecordTypeId =: caseMPSCTransfer];
		system.assertEquals(mpscTransferCases.size(), 1);
    }
    
    static testMethod void testMultipleCases() {
    	Client_Overview_Configuration__c coc = new Client_Overview_Configuration__c(Name='Core Advance Payroll' 
      																			  ,Product_Name__c='Core Payroll'
                                                                                  ,Reference_Object_Relationship_API_Name__c='Reference_Core_Payroll__r'
                                                                                  ,Completed_Onboarding_Status__c='(7 of 7) Onboarding Complete – Transitioned to support,(6 of 6) Client ready for transition'
                                                                                  ,Case_Record_Type_Name__c='Service Onboarding MPSC Core Payroll Case'
                                                                                  ,Owner_Custom_Label__c='Service Team - New Client Specialist'
                                                                                  ,Case_Only__c=FALSE
                                                                                  ,MPSC__c=TRUE);
        insert coc;
       Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
       User u1 = new User(Alias = 'mickey', Email='mickeymouse@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Mouse', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Sales_Org__c = 'PAY',
            TimeZoneSidKey='America/Los_Angeles', UserName='mickeymouse@testorg.com');
       insert u1;
       
       Account acct = new Account (name = 'Test Account', OwnerId = u1.id);

        //MPSC Onboarding Case is the parent case of the MPSC Transfer case
        List<Case> mpscOnboardCases = new List<Case>();
        Id mpscOnboardingCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Onboarding MPSC Core Payroll Case').getRecordTypeId();
        Case mpscOnboardingCase1 = new Case (recordtypeId = mpscOnboardingCaseRT
        						,AccountId = acct.id
        						,Current_Step__c = '(5 of 6) 1st run complete - Finalizing implementation');		    		
		mpscOnboardCases.add(mpscOnboardingCase1);
		Case mpscOnboardingCase2 = new Case (recordtypeId = mpscOnboardingCaseRT
        						,AccountId = acct.id
        						,Current_Step__c = '(4 of 6) Audit complete - Ready to run payroll');		    		
		mpscOnboardCases.add(mpscOnboardingCase2);
		Case mpscOnboardingCase3 = new Case (recordtypeId = mpscOnboardingCaseRT
        						,AccountId = acct.id
        						,Current_Step__c = '(5 of 6) 1st run complete - Finalizing implementation');		    		
		mpscOnboardCases.add(mpscOnboardingCase3);
		insert mpscOnboardCases;
		
		//confirm no transfer cases exist right now
		Id caseMPSCTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('MPSC Transfer Case').getRecordTypeId();	
		List<Case> mpscTransferCases = new List<Case>();
		mpscTransferCases = [SELECT ParentId, RecordTypeId
							FROM Case 
							WHERE ParentId IN: mpscOnboardCases AND RecordTypeId =: caseMPSCTransfer];
		system.assertEquals(mpscTransferCases.size(), 0);
		
		//update just case 3, should create a MPSC Transfer Case related to that case
		mpscOnboardingCase3.Current_Step__c = '(6 of 6) Client ready for transition';
		update mpscOnboardingCase3;
		
		List<Case> caseList = new List<Case>();
		caseList = [SELECT ParentId, RecordTypeId
							FROM Case 
							WHERE ParentId =: mpscOnboardingCase3.id AND RecordTypeId =: caseMPSCTransfer];
		system.assertEquals(caseList.size(), 1);
		
		//change the step back from 6
		mpscOnboardingCase3.Current_Step__c = '(4 of 6) Audit complete - Ready to run payroll';
		update mpscOnboardingCase3;
		
		caseList = [SELECT ParentId, RecordTypeId
							FROM Case 
							WHERE ParentId =: mpscOnboardingCase3.id AND RecordTypeId =: caseMPSCTransfer];
		system.assertEquals(caseList.size(), 1);
		
		//update all of the cases' current step to 6
		List<Case> updatedCases = new List<Case>();
		mpscOnboardingCase1.Current_Step__c = '(6 of 6) Client ready for transition';
		mpscOnboardingCase2.Current_Step__c = '(6 of 6) Client ready for transition';
		mpscOnboardingCase3.Current_Step__c = '(6 of 6) Client ready for transition';
		updatedCases.add(mpscOnboardingCase1);
		updatedCases.add(mpscOnboardingCase2);
		updatedCases.add(mpscOnboardingCase3);
		update updatedCases;
		
		//confirm transfer cases were created for cases 1 and 2, not for 3 becuase one already exists
		caseList = [SELECT ParentId, RecordTypeId
							FROM Case 
							WHERE ParentId =: mpscOnboardingCase1.id AND RecordTypeId =: caseMPSCTransfer];
		system.assertEquals(caseList.size(), 1);
		caseList = [SELECT ParentId, RecordTypeId
							FROM Case 
							WHERE ParentId =: mpscOnboardingCase2.id AND RecordTypeId =: caseMPSCTransfer];
		system.assertEquals(caseList.size(), 1);
		caseList = [SELECT ParentId, RecordTypeId
							FROM Case 
							WHERE ParentId =: mpscOnboardingCase3.id AND RecordTypeId =: caseMPSCTransfer];
		system.assertEquals(caseList.size(), 1);
    }
*/	
}