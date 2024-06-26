/* Trigger that fires off the before actions for the Org_Unit__c object.
   
  History
  -------
  04/04/2012 Dan Carmen   Created
  06/19/2012 Dan Carmen   Added update to the OrgUnitBefore trigger.
  02/26/2015 Dan Carmen   Added trigger actions to populate the role ids based on the role names
  05/21/2022 Dan Carmen   Updated checkRoleNames method
  
 */
trigger OrgUnitBefore on Org_Unit__c (before insert, before update) {
   if (OrgUnitMethods.SKIP_TRIGGERS) {
      return;
   }
   // the records to check for duplicates - or profiles
   List<Org_Unit__c> checkOrgs = new List<Org_Unit__c>();
   // if we have a role name and no id, check for the role id
   List<Org_Unit__c> checkRoleIds = new List<Org_Unit__c>();
   
   for (Org_Unit__c ou : Trigger.new) {
      Org_Unit__c oldOrgUnit = (Trigger.isUpdate ? Trigger.oldMap.get(ou.Id) : null);
      if (Trigger.isInsert) {
         checkOrgs.add(ou);
      } else if (Trigger.isUpdate && ou.Available_Profiles__c == null) {
         checkOrgs.add(ou);
      }
      
      OrgUnitMethods.checkRoleNames(ou, oldOrgUnit);
      
      OrgUnitMethods.checkForUserUpdate(ou, oldOrgUnit, Trigger.isBefore); 
   } // for (Org_Unit__c
   
   if (!checkOrgs.isEmpty()) {
      OrgUnitMethods.processTriggerRecords(checkOrgs,Trigger.isInsert);
   } 
   
   OrgUnitMethods.processRoleNames();
} // trigger OrgUnitBefore