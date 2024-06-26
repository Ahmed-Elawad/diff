/* 
 * Test methods for the HRAssessmentCloneController.
 *
 * History
 * -------
 * 06/29/2016 Jermaine Stukes Created
 *
 */
@isTest
public class HRAssessmentCloneControllerTest 
{
    static testMethod void testAssessmentClone()
    {
        ///Create Test Account
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert(testAccount);
        
        //Create TEst CSM
        Client_Success_Manager__c testCSM = new Client_Success_Manager__c();
        testCSM.Prospect_Client_Name__c = testAccount.Id;
        insert(testCSM);
            
        //Create Test HR Assessment
        HR_Assessment__c testAssessment = new HR_Assessment__c();
        testAssessment.Name = 'testAssessment';
        testAssessment.Client_Success_Manager__c = testCSM.Id;
        insert(testAssessment);
        
        //Create Test HR Action Plan
        HR_Action_Plan__c testActionPlan = new HR_Action_Plan__c();
        testActionPlan.Name = 'testActionPlan';
        testActionPlan.HR_Assessment__c = testAssessment.Id;
        insert(testActionPlan);
        
        //Set Current Page to test assessment
        PageReference pageRef = new PageReference('apex/HRAssessmentClone?id='+testAssessment.Id);
        test.setCurrentPageReference(pageRef);
        
        //Clone Assessment
        HRAssessmentCloneController testController = new HRAssessmentCloneController();
        testController.CloneAssessment();
        
        //Verify cloned assessment
        HR_Assessment__c clonedAssessment = [Select id, name from HR_Assessment__c where name =:testAssessment.Name+'_Clone'];
        System.assertEquals(testAssessment.Name+'_Clone', clonedAssessment.Name);  
        
        //Verify cloned Action plan
        HR_Action_Plan__c clonedActionPlan = [Select id, name,HR_Assessment__c from HR_Action_Plan__c where HR_Assessment__c =:clonedAssessment.Id];
        System.assertEquals(testActionPlan.Name, clonedActionPlan.Name);                       
    }
}