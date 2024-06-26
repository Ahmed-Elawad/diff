/* To handle AccountProductSensitivity insert/update after
 * 
 * History
 * -------
 * 01/08/2020 Michael Karcz    Created
 *
 */

trigger AccountProductSensitivityAfter on Account_Product_Sensitivities__c (after insert, after update) {
    if(trigger.isAfter) {
        AccountProductSensitivityMethods apsm = new AccountProductSensitivityMethods();
        apsm.triggerCheckAllFirst(trigger.newMap.values(), trigger.oldMap, trigger.isBefore, trigger.isAfter);
    }
}