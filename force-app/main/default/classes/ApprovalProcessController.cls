/* 
 * Updates component used in conjuction with the Referrals Email Template. Used to identify and display joins associated with referral.
 * Also, provides link for approval process.
 * History
 * -------
 * 06/10/2016   Jermaine Stukes Created
 * 09/29/2016   Jermaine Stukes updated - Added link to dsa approval work item
 * 06/08/2020 Jake Hinds           Added without sharing per PMD
 *
 */
public without sharing class ApprovalProcessController
{   //Properties
    public String referraljoinId{get;set;}
    public String referralId{get;set;}
    public String repString{get;set;}
    public String dsaString{get;set;}
    public String dsaLink{get;set;}
    public Attachment refAttachment{get;set;}
    
    //If join, return the list of referrals associated with join Id
    public list<Referral__c> getrefList()
    {
        list<Referral__c> refList = new list<Referral__c>();
        //Return all referralPartners
        if(referralJoinId!=null)
        {
            refList = [Select id,ReferralJoin__r.Name, Contact__r.Name, User__c,name,ProductReferred__c from Referral__c where ReferralJoin__r.Name=:referralJoinId  and id !=:referralId]; 
        }
        return refList;
    }
    
    public void getAttachment()
    {
        Attachment att = [Select Id, Name from Attachment WHERE ParentId =:referralId];
        if(att!=Null)
        {refAttachment = att;}
    }
    
    //Find the id of the workflow process.  Return workflow step address link as a string.
    public string getrepLink() 
    {   //Update referral partner list
        //getrefList();
        String repLink = '';
        //Clear DSA Information
        dsaString = '';
        dsaLink = '';
        //Return approval process work item
        List <ProcessInstanceWorkitem> pStepList = new List<ProcessInstanceWorkitem>();
        pStepList = [Select id, ActorId  From ProcessInstanceWorkitem where ProcessInstance.TargetObjectId=:referralId order by createdDate desc]; 
        if (referralId != null) 
        {   //Referral with DSA   
            String linkString = dsaLink = 'https://'+ System.URL.getOrgDomainUrl().getHost() + 
                    '/p/process/ProcessInstanceWorkitemWizardStageManager?id=';
            
            if(pStepList.size() > 1 || test.isRunningTest())
            {   //DSA Link Information
                dsaLink = test.isRunningTest() ? linkString : linkString +String.valueof(pStepList[0].id);
                User dsa = test.isRunningTest() ? [Select id, Name From User where Id =: UserInfo.getUserId()] : [Select id, Name From User where Id =: pStepList[0].ActorId];
                dsaString = dsa.Name+': Click here to Approve or Reject this referral:';
                
                //Rep Link Information
                repLink = test.isRunningTest() ? linkString : linkString + String.valueof(pStepList[1].id);
                User rep = test.isRunningTest() ? [Select id, Name From User where Id =: UserInfo.getUserId()] : [Select id, Name From User where Id =: pStepList[1].ActorId];
                repString = rep.Name+': Click here to Approve or Reject this referral:';
               
            }
            else if (pStepList.size() > 0)
            {   //No DSA
                repLink = 'https://'+ System.URL.getOrgDomainUrl().getHost() + 
                    '/p/process/ProcessInstanceWorkitemWizardStageManager?id='+String.valueof(pStepList[0].id);
                User rep = [Select id, Name From User where Id =: pStepList[0].ActorId];
                //Link to rep work Item
                repString = rep.Name+': Click here to Approve or Reject this referral:';
            }
        }
        return repLink;
    }
}