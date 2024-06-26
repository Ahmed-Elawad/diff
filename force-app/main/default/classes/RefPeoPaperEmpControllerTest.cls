/* The test methods for the RefPeoPaperEmpController.
 *
 * History
 * -------
 * 02/14/2017 Jermaine Stukes   Created
 *
 */
@isTest
public class RefPeoPaperEmpControllerTest {
    
    //Test addition of Paper Employee
    static testMethod void test_addPaperEmployee()
    {
        //Create Reference PEO
        Reference_PEO__c testPEO =  new Reference_PEO__c();
        insert testPEO;
        //Update Page Reference
        Test.SetCurrentPageReference(Page.ReferencePEODiscrepancy);
        ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(testPEO);
        System.CurrentPageReference().getParameters().put('id',testPEO.Id);
        //Add Paper Employee
        Reference_PEO_Onboarding_Candidates__c OC = new Reference_PEO_Onboarding_Candidates__c();
        OC.Reference_PEO_ID__c = testPEO.Id;
        OC.Complete__c = true;
        OC.Employee_First_Name__c = 'Test';
        OC.Employee_Last_Name__c = 'Paper Candidate';
        OC.Last4SSN__c = '2222';
        
        RefPeoPaperEmpController testReference = new RefPeoPaperEmpController();
        testReference.OnboardingCandidate = OC;
        testReference.submitUpdates();
        OC.Complete__c = false;
        
        testReference.updateSave();

        //Verify Paper Employee added
        System.assertEquals(true, testReference.candidatesEntered);
        System.assertEquals(1, testReference.refOnCandidates.size());
    }
    
    //Test Removal of Paper Employee
    static testMethod void test_RemoveCandidate()
    {
        //Create Reference PEO
        Reference_PEO__c testPEO =  new Reference_PEO__c();
        insert testPEO;
        //Update Page Reference
        Test.SetCurrentPageReference(Page.ReferencePEODiscrepancy);
        ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(testPEO);
        System.CurrentPageReference().getParameters().put('id',testPEO.Id);
        //Add Paper Employee
        RefPeoPaperEmpController testReference = new RefPeoPaperEmpController();
        //testReference.cancel();
        List<Reference_PEO_Onboarding_Candidates__c> ocList = new List<Reference_PEO_Onboarding_Candidates__c>();
        Reference_PEO_Onboarding_Candidates__c OC = new Reference_PEO_Onboarding_Candidates__c();
        OC.Reference_PEO_ID__c = testPEO.Id;
        OC.Complete__c = true;
        OC.Employee_First_Name__c = 'Test';
        OC.Employee_Last_Name__c = 'Paper Candidate';
        OC.Last4SSN__c = '1111';
        ocList.add(OC);
        Reference_PEO_Onboarding_Candidates__c OC2 = new Reference_PEO_Onboarding_Candidates__c();
        OC2.Reference_PEO_ID__c = testPEO.Id;
        OC2.Complete__c = true;
        OC2.Employee_First_Name__c = 'Test2';
        OC2.Employee_Last_Name__c = 'Paper Candidate';
        OC2.Last4SSN__c = '2222';
        ocList.add(OC2);
        Reference_PEO_Onboarding_Candidates__c OC3 = new Reference_PEO_Onboarding_Candidates__c();
        OC3.Reference_PEO_ID__c = testPEO.Id;
        OC3.Complete__c = true;
        OC3.Employee_First_Name__c = 'Test3';
        OC3.Employee_Last_Name__c = 'Paper Candidate';
        OC3.Last4SSN__c = '3333';
        ocList.add(OC3);
        insert ocList;
        testReference.refOnCandidates = ocList;
        testReference.removeEmp();
        //Verify Candidate is removed
        System.assertEquals(2, testReference.refOnCandidates.size());
    }
    
    //Test disabled buttons and additional Code Coverage 
    static testMethod void test_DisabledButtons()
    {
        //Create Reference PEO
        Reference_PEO__c testPEO =  new Reference_PEO__c();
        List<Reference_PEO_Onboarding_Candidates__c> ocList = new List<Reference_PEO_Onboarding_Candidates__c>();
        insert testPEO;
        //Update Page Reference
        Test.SetCurrentPageReference(Page.ReferencePEODiscrepancy);
        ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(testPEO);
        System.CurrentPageReference().getParameters().put('id',testPEO.Id);
        RefPEODiscrepancyController rpdc = new RefPEODiscrepancyController(sc1);
        //Add Paper Employee
        RefPeoPaperEmpController testReference = new RefPeoPaperEmpController();
        
        
        Reference_PEO_Onboarding_Candidates__c OC = new Reference_PEO_Onboarding_Candidates__c();
        OC.Reference_PEO_ID__c = testPEO.Id;
        OC.Complete__c = true;
        OC.Employee_First_Name__c = 'first';
        OC.Employee_Last_Name__c = 'last';
        OC.Last4SSN__c = '2222';
        testReference.OnboardingCandidate = OC;
        testReference.Validate();
        //Verify Button not disabled
        System.assertEquals(false, testReference.disableButtons);
        //Misc code coverage
        testReference.cancel();
        testReference.quickSave();
        testReference.Updated();
        System.assertEquals(true, testReference.candidateUpdated);
        
    }
    

        
}