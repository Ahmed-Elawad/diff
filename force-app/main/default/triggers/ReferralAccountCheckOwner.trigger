/** This trigger will only fire on an update, because on an insert
    the ownership needs to be initially set and the flag will
    not matter.
 *
 * History
 * -------
 * 09/03/2009 Dan Carmen   Created
   09/25/2012 Dan Carmen   Added logic to set owners based on zip code.
   06/22/2015 Dan Carmen   Modifications for ownership
   08/06/2015 Dan Carmen   Change position of where User_Lookup__c field is getting populated 
                            - wasn't reflecting owner changes in the trigger.
   08/07/2015 Dan Carmen   Make sure User Lookup always gets populated
   08/09/2016 Dan Carmen   Added condition if record type changes.
   03/25/2022 Dan Carmen   Move logic to ZipCheckOwner

*/
trigger ReferralAccountCheckOwner on Referral_Account__c (before insert, before update) {


} // trigger ReferralAccountCheckOwner