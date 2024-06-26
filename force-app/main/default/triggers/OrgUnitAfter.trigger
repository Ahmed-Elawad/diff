/* Trigger that fires off the after actions for the Org_Unit__c object.
   
  History
  -------
  02/26/2015 Dan Carmen   Created
  
 */
trigger OrgUnitAfter on Org_Unit__c (after insert, after update) {

   for (Org_Unit__c orgUnit : Trigger.new) {
      Org_Unit__c oldOrgUnit = (Trigger.isUpdate ? Trigger.oldMap.get(orgUnit.Id) : null);

      OrgUnitMethods.checkForUserUpdate(orgUnit, oldOrgUnit, Trigger.isBefore);
      
   } // for (Org_Unit__c orgUnit
   
   OrgUnitMethods.checkToProcessOrgUnitUserUpdate(UserInfo.getSessionId());
} // trigger OrgUnitAfter