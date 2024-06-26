/* 
   Handle all of the "Before" trigger actions 
   
  History
  -------
  12/21/2012 Dan Carmen   Created from OpptyCheckFields
  01/18/2016 Dan Carmen   Check that branch client number is all uppercase.
  08/02/2016 Dan Carmen   Remove some old NSS code.
  09/09/2016 Dan Carmen   Added a call to OpptyMethods
  09/14/2016 Dan Carmen   Add ability to skip the triggers.
  10/17/2016 Jacob Hinds  Adding in Round Robin
  10/25/2017 Dan Carmen   Remove OpportunityType check from trigger
  01/15/2018 Jacob Hinds  adding in small line to keep payroll units in sync with payroll unit currency - forecasting workaround
  04/09/2019 Dan Carmen   Remove OpptyCheckFields from trigger
  04/22/2019 Dan Carmen         Add more logging
  06/02/2020 Dan Carmen         Remove call to SRRTransitionHelper
  12/01/2020 Dan Carmen         Move code to OpptyMethods
  08/18/2023 Dan Carmen         Add ability to skip the trigger at a record level
  01/02/2024 Dan Carmen         Fix SKIP_OPPTY_TRIGGERS logic
   
 */
trigger OpptyBefore on Opportunity (before insert, before update) {
   System.debug('OpptyBefore SKIP_OPPTY_TRIGGERS='+OpptyMethods.SKIP_OPPTY_TRIGGERS);
   if (OpptyMethods.SKIP_OPPTY_TRIGGERS) {
      return;
   }

   if (Trigger.new != null && !Trigger.new.isEmpty() && Trigger.new[0].SkipTriggers__c) {
      System.debug('OpptyBefore skipping triggers due to SkipTriggers__c');
      // reset the flag
      for (Opportunity opp : Trigger.new) {
         opp.SkipTriggers__c=false;
      }
      // do not execute the after trigger
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      return;
   } // if (Trigger.new != null && !Trigger.new.isEmpty() && Trigger.new[0].SkipTriggers__c
    
   TriggerMethods.checkBeforeLoop('OpptyBefore', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);

   for (Opportunity newRec: Trigger.new) {
      // set the oldRec if it's an update
      Opportunity oldRec = (Trigger.isUpdate ? Trigger.oldMap.get(newRec.Id) : null);

      TriggerMethods.checkInLoop('OpptyBefore', newRec, oldRec, Trigger.IsBefore, Trigger.IsAfter);
      
   } // for (Opportunity
   
   TriggerMethods.checkOutsideLoop('OpptyBefore', Trigger.isBefore, Trigger.isAfter);

   
   
} // trigger OpptyBefore