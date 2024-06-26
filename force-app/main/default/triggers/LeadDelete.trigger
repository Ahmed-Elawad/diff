/* 
 *  A trigger to handle after Delete and Undelete operations.
 *  Deleting the Lead will also delete the company if no other leads are linked to it.
 *  Undeleting a Lead will cause a new company to be created if it isn't already there
 * 
 * History
 * -------
 * 04/21/2014 Cindy Freeman     created
 * 01/25/2017 Josh Cartwright changes for Dataflux 
   03/16/2024 Dan Carmen        Added call to TriggerMethods, move dataflux code

 */

trigger LeadDelete on Lead (after delete, after undelete, before delete) {
	
    if (Trigger.isDelete) {
       TriggerMethods.checkBeforeLoop('LeadDelete', Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter);
    }

   // companies that may need to be deleted if linked to only 1 lead
   Set<Id> companyIdSet = new Set<Id>();
   // companies that need to be undeleted to go with undeleted lead
   Set<Id> compIdUndeleteSet = new Set<Id>();
   
   if (Trigger.isDelete) {
      for (Lead oldL : Trigger.old) {
         if (oldL.Lead_Company__c != null) {
            //companyIdSet.add(oldL.Lead_Company__c);	
            LeadCompanyMethods.companyIdsToEvaluateSet.add(oldL.Lead_Company__c);	// CMF
            System.debug('**CMF ** LeadDelete add LC to companyIdSet-'+oldL.Lead_Company__c);   			
         }
      } // for (Lead oldL : Trigger.old
	} // isDelete
	
   if (Trigger.isUnDelete) {
      Id[] leadIds = new Id[]{};
      leadIds.addAll(Trigger.newMap.keySet());
      // send UNdeletes to LeadCompanyMethods to recreate Lead_Companies that were deleted at the same time
      LeadCompanyMethods.handleLeadsNow(leadIds, new Id[]{});
   } // if isUnDelete
		
   LeadCompanyMethods.checkLeadCompanies();
    
} // trigger LeadDelete