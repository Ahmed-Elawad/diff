/* 
 * A batch job for checking Batch Consent to text reset 
 *
 * History
 * -------
 * 01/30/2020   Cindy Freeman   Created
 * 02/06/2020 	Cindy Freeman	fix name of scheduled job
   03/15/2022 Dan Carmen        Remove all Logic - don't need this class anymore

*/ 
@isTest
private class PartnerReferralMonitorTest {

    static testMethod void myUnitTest() {
        new PartnerReferralMonitor();
    }
}