/* 
 * Trigger for the CampaignInfluence object
 *
 * History
 * -------
   03/29/2018 Dan Carmen        Created

 */
trigger CampaignInfluence on CampaignInfluence (before insert, before update, after insert, after update) {
   
   CampaignInfluenceHelper.checkFromTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore);
} // CampaignInfluence