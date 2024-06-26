/** This trigger will only fire on an update, because on an insert
    the ownership needs to be initially set and the flag will
    not matter. 
 *
 * History
 * -------
 * 09/03/2009 Dan Carmen   Created
   09/25/2012 Dan Carmen   Added logic to set owners based on zip code.
   06/22/2015 Dan Carmen   Modifications for ownership
   08/07/2015 Dan Carmen   Make sure User Lookup always gets populated
   03/25/2022 Dan Carmen   Move code to ZipCheckOwner, deactivate trigger

*/
trigger ReferralContactCheckOwner on Referral_Contact__c (before update, before insert) {
   
} // trigger ReferralContactCheckOwner