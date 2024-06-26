/* 
   Trigger for the Campaign object
   
  History
  -------
  06/13/2014 Dan Carmen   Created
  12/11/2023 Dan Carmen   Moved logic to CampaignMethods
  
 */
trigger CampaignTrigger on Campaign (before insert, before update, after insert, after update) {
   
   new CampaignMethods().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.isAfter, Trigger.IsDelete);
   
} // trigger CampaignTrigger