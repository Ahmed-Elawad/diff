/* Clones HR Assessment as well as action plan if any exists.
 *
 * History
 * -------
 * 06/28/2016 Jermaine Stukes Created
 * 07/06/2020  Jacob Hinds         Added without sharing per PMD
 * 05/30/2022 Reetesh Pandey  Apex code scan resolution
 *
 */
public without sharing class HRAssessmentCloneController 
{ 
    Public PageReference CloneAssessment()
    {
        //Grab ID and set it as the id of the current HR_Assessment object
        String pageId = ApexPages.CurrentPage().getParameters().get('id');
        // Apex code scan
        pageId = String.escapeSingleQuotes(pageId);
        String creatableAssessmentFields = ObjectHelper.getCreatableFields('HR_Assessment__c','id=\''+pageId +'\'');
      
        HR_Assessment__c originalHrAssessment = (HR_Assessment__c)Database.query(creatableAssessmentFields);
        
        //Clone current HR_Assessment 
        HR_Assessment__c clonedHr_Assessment = originalHrAssessment.clone(false, true);
        clonedHr_Assessment.Name = clonedHr_Assessment.Name+'_Clone';
        insert clonedHr_Assessment;
        
        //Query to verify whether HR Action Plan exists for current HR Assessment
        HR_Action_Plan__c[] actionPlans = [Select Id, HR_Assessment__c
                                           from HR_Action_Plan__c
                                           where HR_Assessment__c = :pageId
                                          ];
        //If Action Plans exists for current HR Assessment, clone and re-map to cloned assessment
        if(actionPlans.size() > 0)
        {
            list<HR_Action_Plan__c> actionPlanList = new list<HR_Action_Plan__c>();
            for(HR_Action_Plan__c aPlan :actionPlans)
            {
                //Get createable fields for each action plan
                String creatableActionPlanFields = ObjectHelper.getCreatableFields('HR_Action_Plan__c','id=\''+aPlan.Id +'\'');                
                HR_Action_Plan__c originalActionPlan = (HR_Action_Plan__c)Database.query(creatableActionPlanFields);
                
                //Clone the HR Action Plan and add to list
                HR_Action_Plan__c clonedActionPlan = originalActionPlan.clone(false, true);
                clonedActionPlan.HR_Assessment__c = clonedHr_Assessment.Id;
                actionPlanList.add(clonedActionPlan);
            }
            insert(actionPlanList);
        }

        //Redirect page to cloned reference agency
        PageReference pageref;
        pageref = new PageReference('/'+clonedHr_Assessment.Id);
        pageref.setRedirect(true);
        return pageref;   
    }
}