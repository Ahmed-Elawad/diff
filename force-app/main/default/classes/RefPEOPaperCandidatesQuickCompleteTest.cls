/**
 * 06/19/2017	Lynn Michels	Created
 */
@isTest
private class RefPEOPaperCandidatesQuickCompleteTest {

    static testMethod void testMassComplete() {
        Reference_PEO__c refPEO = new Reference_PEO__c();
        insert refPEO;
        
         //Set test page reference to the Id of the inserted reference peo
        pageReference pageRef = new pageReference('/'+refPEO.Id);
        pageRef.getParameters().put('retURL', refPEO.Id);
        test.setCurrentPageReference(pageRef);
        
        List<Reference_PEO_Onboarding_Candidates__c> candidates = new List<Reference_PEO_Onboarding_Candidates__c>();
        Reference_PEO_Onboarding_Candidates__c cand1 = new Reference_PEO_Onboarding_Candidates__c(
        											Employee_First_Name__c = 'Test1',
        											Employee_Last_Name__c = 'LastTest1',
        											Last4SSN__c = '1111',
        											Reference_PEO_ID__c = refPEO.id);
        candidates.add(cand1);
        Reference_PEO_Onboarding_Candidates__c cand2 = new Reference_PEO_Onboarding_Candidates__c(
        											Employee_First_Name__c = 'Test2',
        											Employee_Last_Name__c = 'LastTest2',
        											Last4SSN__c = '2222',
        											Reference_PEO_ID__c = refPEO.id);
        candidates.add(cand2);
        Reference_PEO_Onboarding_Candidates__c cand3 = new Reference_PEO_Onboarding_Candidates__c(
        											Employee_First_Name__c = 'Test3',
        											Employee_Last_Name__c = 'LastTest3',
        											Last4SSN__c = '3333',
        											Reference_PEO_ID__c = refPEO.id);
        candidates.add(cand3);
        Reference_PEO_Onboarding_Candidates__c cand4 = new Reference_PEO_Onboarding_Candidates__c(
        											Employee_First_Name__c = 'Test4',
        											Employee_Last_Name__c = 'LastTest4',
        											Last4SSN__c = '4444',
        											Reference_PEO_ID__c = refPEO.id);
        candidates.add(cand4);
        insert candidates;

      	ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(candidates);
      	ssc.setSelected(candidates);
      	RefPEOPaperCandidatesQuickComplete refPEOController = new RefPEOPaperCandidatesQuickComplete(ssc);
      	refPEOController.quickComplete();																
      	List<Reference_PEO_Onboarding_Candidates__c> completedCandidates = [Select Id, Complete__c
      																		From Reference_PEO_Onboarding_Candidates__c
      																		Where Id in: candidates];
      	system.assertEquals(true, completedCandidates[0].Complete__c);
      	system.assertEquals(true, completedCandidates[1].Complete__c);
      	system.assertEquals(true, completedCandidates[2].Complete__c);
      	system.assertEquals(true, completedCandidates[3].Complete__c);
      	
		
        													
    }
}