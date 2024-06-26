/*
 * History
 * --------
 * 05/25/2016  Lynn Michels  created
 *
 */
public with sharing class RefCorePayChatterPost {

    public static void collectInfoForChatterPost(list<Id> caseIds)
    {
        //collect Reference Core Payroll objects related to the cases
        List<Reference_Core_Payroll__c> refCoreList = [SELECT Id, Implementation_Specialist_Name__c, Payroll_Status__c
            FROM Reference_Core_Payroll__c WHERE Case_Lookup__c IN: caseIds];
        
        //collect information from the Reference Core Payroll object
        for (Reference_Core_Payroll__c rcp: refCoreList) 
        {
            List<ID> usersToMention = new List<ID>();
            if(rcp.Implementation_Specialist_Name__c != null)
            {
                usersToMention.add(rcp.Implementation_Specialist_Name__c);
            }
            String postText = 'The Status of the audit has been changed to '+rcp.Payroll_Status__c+ '.';   
            ChatterMentionPost.createChatterMentionPost(rcp.id, usersToMention, new String[]{postText}, true, false);
        } // for (Reference_Core_Payroll__c rcp  

        ChatterMentionPost.postBatchFeedElements();
        
    } // collectInfoForChatterPost
} // class RefCorePayChatterPost