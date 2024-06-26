/* 
 * Clones Case and Reference Agency for HNBF cases.
 *
 * History
 * -------
 * 05/04/2016 Jermaine Stukes Created
 * 07/18/2016 Jermaine Stukes updated with the addition of Policy Types
 * 02/24/2020 Dan Carmen        Increment API version
 * 07/06/2020  Jacob Hinds         Added without sharing per PMD
 * 05/30/2022 Reetesh Pandey  Apex code scan resolution
 */
public without sharing class RefHNBFCloneController 
{
    //Clone HNBF reference as well as the case it is created from
    Public PageReference CloneHNBF()
    {   //Grab ID and set it as the id of the reference object
        String Id = ApexPages.CurrentPage().getParameters().get('id'); 
        // Apex code scan
        Id = String.escapeSingleQuotes(Id);
        String creatableReferenceFields = ObjectHelper.getCreatableFields('Reference_HNBF__c','id=\''+Id +'\'');        
        Reference_HNBF__c originalReference= (Reference_HNBF__c)Database.query(creatableReferenceFields);
        
        /* query Case and then clone all creatable fields with values */
        String creatableCaseFields = ObjectHelper.getCreatableFields('Case','id=\''+originalReference.Case_Number__c+'\'');        
        Case originalCase= (Case)Database.query(creatableCaseFields);
        Case clonedCase = originalCase.clone(false, true);
        clonedCase.Reference_Cloned__c = 'true';
        insert clonedCase;
        
        //Clone reference agency
        Reference_HNBF__c clonedReference = originalReference.clone();
        clonedReference.Case_Number__c = clonedCase.id;
        insert(clonedReference);
        
        //List of related policy types
        list<Reference_HNBF_Policy_Type__c> policyList = [Select Id, Reference_HNBF__c
                                           from Reference_HNBF_Policy_Type__c
                                           where Reference_HNBF__c = :originalReference.Id
                                          ];
        //If Policy Types exist, clone them
        if(policyList.size() > 0)
        {
            //Create list for cloned policy types
            List<Reference_HNBF_Policy_Type__c> policyCloneList = new List<Reference_HNBF_Policy_Type__c>();
            //Clone each Policy type
            for(Reference_HNBF_Policy_Type__c aPolicyType :policyList)
            {
                //Get createable fields for each policy type
                String creatablePolicyFields = ObjectHelper.getCreatableFields('Reference_HNBF_Policy_Type__c','id=\''+aPolicyType.Id +'\'');                
                Reference_HNBF_Policy_Type__c originalPolicy = (Reference_HNBF_Policy_Type__c)Database.query(creatablePolicyFields);
                
                //Clone the policy type and add to list
                Reference_HNBF_Policy_Type__c clonedPolicy = originalPolicy.clone(false, true);
                clonedPolicy.Reference_HNBF__c = clonedReference.Id;
                policyCloneList.add(clonedPolicy);
            }
            insert(policyCloneList);
        }
        
        //Redirect page to cloned reference agency
        PageReference pageref;
        pageref = new PageReference('/'+clonedReference.Id);
        pageref.setRedirect(true);
        return pageref;   
    }
}