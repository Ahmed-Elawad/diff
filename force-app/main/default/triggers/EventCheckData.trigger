/* 
 * Set the initial presentation flag on the event.
 *
 * History
 * -------
 * 01/26/2011 Dan Carmen   Created from workflow because the workflow was causing another trigger to fire again.
 * 06/16/2016 Justin Stouffer Updated to limit ESR Events
 * 11/30/2017 Jake Hinds	Commenting out above ESR
 * 09/20/2018 Cindy Freeman	  populate Referral Contact field if event is Related To referral contact
 * 01/10/2020 Brandon Vidro Added EventCheckData.checkEventType
   10/22/2020 Dan Carmen      Move logic to EventCheckData class
  
 */

trigger EventCheckData on Event (before insert, before update) {
    
   new EventCheckData().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter, Trigger.IsDelete);

} // trigger EventCheckData