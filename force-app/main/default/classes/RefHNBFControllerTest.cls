/* 
 * Test methods for the RefHNBFCloneController.
 *
 * History
 * -------
 * 05/18/2016 Jermaine Stukes Created
 * 08/10/2016 Jermaine Stukes - Add Policy Type test
   02/24/2020 Dan Carmen        Increment API version
   06/01/2022 Carrie Marciano added Policy_Effective_Date__c for new validation

 */
@isTest
public class RefHNBFControllerTest 
{
    static testMethod void testCloneHNBF() 
    {
        Case testCase = new Case();
        testCase.Status = 'New';
        testCase.Current_Step__c = 'Case Creation';
        testCase.Type = 'ACT';
        testCase.Description = 'TEST CLONE FUNCTION';
        insert testCase;

        //Create Reference_HNBF__c
        Reference_HNBF__c testReference = new Reference_HNBF__C();
        testReference.Case_Number__c= testCase.Id;
        testReference.Submission_Type__c= 'New Case';
        testReference.Current_Step__c = 'Onboarding in Progress';
        insert testReference;
        System.assertNotEquals(Null, testReference.Id);
        
        //Create Policy Type
        Reference_HNBF_Policy_Type__c testPolicyType = new Reference_HNBF_Policy_Type__c();
        testPolicyType.Reference_HNBF__c = testReference.Id;
        testPolicyType.Policy_Type__c = 'Dental';
        testPolicyType.AOR_Effective_Date__c = Date.today();
        testpolicyType.Policy_Effective_Date__c = Date.today();
        insert testPolicyType;
        System.assertNotEquals(Null, testPolicyType.Id);
        
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/ReferenceHNBFClone?id='+testReference.Id);
        test.setCurrentPageReference(pageRef);
        
        //Clone testCase
        RefHNBFCloneController newTest = new RefHNBFCloneController();
        newTest.CloneHNBF();
        
        //Verify Case cloned
        case clonedCase = [SELECT Id, Description FROM Case where Status =:testCase.Status and Current_Step__c =:testCase.Current_Step__c and id!=:testCase.Id];
        System.assertNotEquals(Null, clonedCase.Id);
        System.assertEquals('TEST CLONE FUNCTION', clonedCase.Description);  
        
        //Verify Reference cloned
        Reference_HNBF__c clonedReference = [SELECT Id, Case_Number__c,Submission_Type__c FROM Reference_HNBF__c where  Case_Number__c=:clonedCase.Id];
        System.assertNotEquals(Null, clonedReference.Id);
        System.assertEquals(testReference.Submission_Type__c, clonedReference.Submission_Type__c); 
        
        //Verify Policy Type cloned
        Reference_HNBF_Policy_Type__c clonedPolicy = [SELECT Id, Reference_HNBF__c, Policy_Type__c FROM Reference_HNBF_Policy_Type__c where  Reference_HNBF__c=:clonedReference.Id];
        System.assertNotEquals(Null, clonedPolicy.Id);
        System.assertEquals(testPolicyType.Policy_Type__c, clonedPolicy.Policy_Type__c); 
 
    }
    
}