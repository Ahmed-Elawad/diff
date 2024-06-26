/* 
 * Trigger for license requests.
 *
 * History
 * -------
 * 06/28/2017 Saketh Mysa   Created
   *
 */
trigger ManagePackageLicenseTrigger on Manage_Package_License__c (after update) {
    ManagePackageLicenseHelper afterTriggerHelper = new ManagePackageLicenseHelper ();

    if(Trigger.isAfter && Trigger.isUpdate){
        afterTriggerHelper.intake(trigger.new, trigger.oldMap);
    }
}