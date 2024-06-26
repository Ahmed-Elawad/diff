/*
 * A scheduled job to check if Marketo is sending in Webleads.  
 * Looks for Partner Referrals created within last 45 minutes.
 * Sends an email if none are found.
 * Only runs between 8 am and 8 pm.
 * History
 * -------
 * 01/31/2020 Cindy Freeman     created
   03/15/2022 Dan Carmen        Remove all Logic - don't need this class anymore

 */

public class PartnerReferralMonitor  {
    public PartnerReferralMonitor() {}
} // PartnerReferralMonitor