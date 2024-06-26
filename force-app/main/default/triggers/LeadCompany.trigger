/* 
 *  A trigger for the Lead Company object
 *   
 * History
 * -------
 * 06/18/2014 Cindy Freeman     created
 */
trigger LeadCompany on Lead_Company__c (before update, after update) {

   if (LeadCompanyMethods.SKIP_TRIGGER) {
      return;
   }

   Set<Id> evaluateCompanyIdSet = new Set<Id>();
   
   // when the account id is set, convert the attached leads
   List<Id> leadCompaniesToConvertIds = new List<Id>();
   
   for (Lead_Company__c leadCompany : Trigger.new) {
    Lead_Company__c oldLeadCompany = (Trigger.isUpdate ? Trigger.oldMap.get(leadCompany.Id) : null);
    //if (Trigger.isAfter) {
      //   LeadCompanyMethods.checkForSignificanceRecalc(leadCompany,null);
    //}
    if (Trigger.isBefore && leadCompany.EvaluateAccountId__c) {
        leadCompany.EvaluateAccountId__c = false;
        System.debug('LeadCompany adding to leadCompaniesToConvertIds');
       LeadCompanyMethods.leadCompaniesToEvaluateAccountId.add(leadCompany.Id);
    }
   } // for (Lead_Company__c leadCompany
   
   if (Trigger.isAfter) {
      //LeadCompanyMethods.checkLeadCompany(false);
      LeadCompanyMethods.checkHandleAccountId();
   }   
   
} // trigger LeadCompany