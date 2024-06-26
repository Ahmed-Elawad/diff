/* 

  History
  -------
  03/22/2022 Dan Carmen          Cleaned up code

 */
@isTest
private class ActivityRelatedListAuraServiceTest {
	
    @testSetup
    public static void setupData() {
        ObjectBannerAuraServiceTest.setupData();
    } // setupData

	@isTest 
    static void testGetActivities() {
       Account acct = ObjectBannerAuraServiceTest.getTestAcct();
       ActivityRelatedListAuraService.DataEnvelope envelope = ActivityRelatedListAuraService.getOpenActivities(acct.Id);
       List<ActivityDA.ActivityCombined> openActivities = envelope.activities;

       System.assertEquals(true, openActivities.size()>0);
	} // testGetActivities
	

	
} // class ActivityRelatedListAuraServiceTest