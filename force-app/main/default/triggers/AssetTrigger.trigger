/** When the Asset object field met the condition 
then the task object field should be updated
 *
 * History
 * -------
 * 04/17/2012 Dan Carmen        Added in some more product codes to check for condition
 * 07/11/2012 Dan Carmen        Added in logic to match the product
 * 02/01/2013 Carrie Marciano   Added logic for TAA plan codes to check for plan cancel dates
 * 02/01/2016 Lynn Michels      Added logic for Asset mapping to product indicator checkboxes on Prospect-Client
 * 03/04/2016 Jacob Hinds       Adding in call to check Account Type in the before trigger 
 * 06/15/2016 Carmen/Michels    Updated code to work with changes in AssetMappingToProductIndicators.cls
 * 08/30/2016 Lynn Michels      Added code to look for Payroll Assets and send them to the AssetMethods.cls
 * 11/03/2016 Lynn Michels      Backing out code for Payroll Assets per Leslie
 * 05/12/2017 Lynn Michels      Adding code to populate Client Start Date on Reference HRS Termination/Transfer object
   12/08/2017 Dan Carmen      Remove extra code from the trigger
   
 */

trigger AssetTrigger on Asset (before insert, before update, after insert,after update,after delete) {

    if(system.label.TriggerMethods_DisableAssetTrigger != 'Y'){      
       if (Trigger.isBefore) {   
          for (Asset asst: Trigger.new){  
             Asset oldRec = (Trigger.isUpdate ? Trigger.oldMap.get(asst.id) : null); 
    
             AssetMappingToProductIndicators.checkBeforeTrigger(asst,oldRec);
             AssetMethods.checkBeforeTrigger(asst,oldRec);
             
          } //end forloop
       } //end isBefore
            
       else if(Trigger.isAfter){
          if(Trigger.isDelete) {
             for (Asset oldAsset : Trigger.old) {
                // check the mapping on the delete of an asset
                AssetMappingToProductIndicators.checkTriggerDelete(oldAsset);
             } // for (Asset oldAsset
          } //end isDelete
          else{
             for (Asset asst: Trigger.new){ 
                Asset oldRec = (Trigger.isUpdate ? Trigger.oldMap.get(asst.id) : null);
                AssetMappingToProductIndicators.checkAfterTrigger(asst,oldRec);
    
               // AccountMethods.checkAssetForClientType(asst, oldRec);
                AssetMethods.checkAfterTrigger(asst,oldRec);
                 
             } //end for loop
            
          }
       } // end isAfter
       
       
       if (Trigger.isBefore) {
          AssetMethods.processBeforeTrigger();
       }
       
       if (Trigger.isAfter) {
         // AccountMethods.processFromAssetTrigger(AssetMappingToProductIndicators.acctMap);
          AssetMappingToProductIndicators.handleAfterActions();
          AssetMethods.processAfterTrigger();
       }  
    }
     
} // trigger AssetTrigger