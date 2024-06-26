/** Sync the Accounts defined as banks to the Bank object
 *
 * History
 * -------
   09/28/2015 Dan Carmen      Created
   05/25/2017 Dan Carmen      Move logic to class
   01/24/2023 Dan Carmen      Comment out and deactivate trigger.
   
 */

trigger AccountPartnerSync on Account (after insert, after update) {
   /*
   if (AccountPartnerSync.SKIP_TRIGGER) {
      return;
   }

   AccountPartnerSync aps = new AccountPartnerSync();
   
   
   if (Trigger.isAfter && (Trigger.isInsert || Trigger.IsUpdate)) {
      //Set<String> syncReferralTypes = AccountPartnerSync.getSyncReferralTypes();
      for (Account acct : Trigger.new) {
         Account oldAcct = (Trigger.isInsert ? null : Trigger.oldMap.get(acct.Id));
         aps.checkAfterTrigger(acct,oldAcct);
      } // for (Account acct
   } // if (Trigger.isAfter
   
   aps.processAfterTriggerActions();
   */
} // trigger AccountPartnerSync