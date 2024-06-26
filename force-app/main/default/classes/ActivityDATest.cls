/* 

  History
  -------
  03/22/2022 Dan Carmen          Cleaned up code

 */
@IsTest
private class ActivityDATest {
    @testSetup
    public static void setupData() {
        ObjectBannerAuraServiceTest.setupData();
        UserHelperTest.setupSalesOrgSetting();
    } // setupData
    
    @IsTest
    static void testGetOpenActivities() {
       Contact ctct = ObjectBannerAuraServiceTest.getTestCtct();
       ActivityDA.ActivityCombined[] expectedActivities = ActivityDA.getOpenActivities(ctct.Id);
       System.assertEquals(true, expectedActivities.size() > 0);
 
       Account acct = ObjectBannerAuraServiceTest.getTestAcct();
       expectedActivities = ActivityDA.getOpenActivities(acct.Id);
       System.assertEquals(true, expectedActivities.size() > 0);
        
       Referral_Account__c refAcct = ObjectBannerAuraServiceTest.getTestRefAcct();
       expectedActivities = ActivityDA.getOpenActivities(refAcct.Id);
       System.assertEquals(true, expectedActivities.size() > 0);

       Referral_Contact__c refCtct = ObjectBannerAuraServiceTest.getTestRefCtct();
       expectedActivities = ActivityDA.getOpenActivities(refCtct.Id);
       System.assertEquals(true, expectedActivities.size() > 0);

       Opportunity opp = ObjectBannerAuraServiceTest.getTestOpp();
       expectedActivities = ActivityDA.getOpenActivities(opp.Id);
       System.assertEquals(true, expectedActivities.size() > 0);

    } // testGetOpenActivities

    @IsTest
    static void testInitialPresentations() {
        Opportunity opp = ObjectBannerAuraServiceTest.getTestOpp();
        
        List<Event> returnEvents = new ActivityDA().getInitialPresentationEventsByOpportunityId(opp.Id);
        System.assertEquals(returnEvents.size(), 1);
        System.assertEquals(returnEvents[0].Type, 'Presentation - Initial');
    } // getInitialPresenetationEventsByOpportunityId_GivenOpportunityId_ReturnsAllInitialPresentationEvents

    @IsTest
    static void testContactRoles() {
        Opportunity opp = ObjectBannerAuraServiceTest.getTestOpp();
        List<OpportunityContactRole> returnContactRoles = new ActivityDA().getContactRolesByOpportunityId(opp.Id);
        System.debug('return contact roles: ' + returnContactRoles);

        System.assertEquals(returnContactRoles.size(), 1);
    } // getContactRolesByOpportunityId_GivenOpportunityId_ReturnsAllContactRoles

    static testMethod void testActivityCombined() {
       Task tsk = new Task(Subject='Test', ActivityDate=Date.today());
       ActivityDA.ActivityCombined act = new ActivityDA.ActivityCombined(tsk);
       System.assertEquals(null,act.recId);
       System.assertEquals(Date.today(), act.activityDate);
       System.assertEquals('Task',act.type);
       System.assertEquals('Test',act.subject);
       System.assertEquals(null,act.whoId);
       System.assertEquals(null,act.whatId);
       //String whoName = act.whoName;
       //String whatName = act.whatName;
       System.assertEquals(null,act.whoLink);
       System.assertEquals(null,act.whatLink);
        
    }
} // class ActivityDATest