/* Test methods for the TrackerBatch class
   
  History
  -------
  08/23/2017 Dan Carmen       Created
  09/25/2017 Dan Carmen       Summarize by person per day
  11/10/2023 Dan Carmen       Comment out code
  
 */
@isTest
private class TrackerBatchTest {
   static testMethod void testNothing() {
      new TrackerBatch();
   } // testNothing
/*
   static testMethod void testBatch() {
      // create test tracker records
      
      User[] users = [Select Id, Name from User Where IsActive=true and Sales_Org__c = :UserHelper.SO_CORE limit 3];

      PlatformTracker__c[] trackers1Read = new PlatformTracker__c[]{};
      PlatformTracker__c[] trackers1Insert = new PlatformTracker__c[]{};
      PlatformTracker__c[] trackers1Update = new PlatformTracker__c[]{};
      PlatformTracker__c[] trackers2Read = new PlatformTracker__c[]{};
      PlatformTracker__c[] trackers2Insert = new PlatformTracker__c[]{};
      PlatformTracker__c[] trackers2Update = new PlatformTracker__c[]{};
      
      PlatformTracker__c[] trackersUser1 = new PlatformTracker__c[]{};
      PlatformTracker__c[] trackersUser2 = new PlatformTracker__c[]{};
      PlatformTracker__c[] trackersUser3 = new PlatformTracker__c[]{};
      
      System.runAs(users[0]) {
         createTrackers(trackers1Read, 15, ObjectHelper.OBJECT_ACCOUNT, 'Theme1', 'Read');
         createTrackers(trackers1Insert, 15, ObjectHelper.OBJECT_CONTACT, 'Theme1', 'Insert');
         createTrackers(trackers1Update, 15, ObjectHelper.OBJECT_ACCOUNT, 'Theme2', 'Update');

         trackersUser1.addAll(trackers1Read);
         trackersUser1.addAll(trackers1Insert);
         trackersUser1.addAll(trackers1Update);
         insert trackersUser1;
      } // System.runAs(users[0]
      
      System.runAs(users[1]) {
         createTrackers(trackers2Read, 15, ObjectHelper.OBJECT_ACCOUNT, 'Theme1', 'Read');
         createTrackers(trackers2Insert, 15, ObjectHelper.OBJECT_ACCOUNT, 'Theme1', 'Insert');
         createTrackers(trackers2Update, 15, ObjectHelper.OBJECT_CONTACT, 'Theme2', 'Update');

         trackersUser2.addAll(trackers2Read);
         trackersUser2.addAll(trackers2Insert);
         trackersUser2.addAll(trackers2Update);
         insert trackersUser2;
      } // System.runAs(users[1]
      
      PlatformTracker__c tracker = null;
      TrackerSummary__c existingSummary = null;
      PlatformTracker__c timeTracker = null;

      PlatformTracker__c[] trackers3Read = new PlatformTracker__c[]{};
      PlatformTracker__c[] trackers3Update = new PlatformTracker__c[]{};
      
      System.runAs(users[2]) {
         // create 1 existing summary record/detail record for update
         tracker = new PlatformTracker__c(ObjectType__c=ObjectHelper.OBJECT_CONTACT
                                            ,UITheme__c='Theme2',UsageType__c='Update');
         insert tracker;
         Map<Id,PlatformTracker__c> trackerMap = queryTrackers(new Id[]{tracker.Id});
         tracker = trackerMap.get(tracker.Id);
         String keySummary = TrackerBatch.buildKey(tracker, TrackerBatch.SUMMARY);
         existingSummary = TrackerBatch.buildSummary(tracker, keySummary);
         insert existingSummary;
         
         String keyDetail = TrackerBatch.buildKey(tracker, TrackerBatch.DETAIL);
         TrackerSummaryDetail__c existingDetail = TrackerBatch.buildDetail(tracker, keySummary);
         existingDetail.TrackerSummary__c = existingSummary.Id;
         existingDetail.TrackerKey__c = keyDetail;
         insert existingDetail;

         createTrackers(trackers3Update, 14, ObjectHelper.OBJECT_CONTACT, 'Theme2', 'Update');
         createTrackers(trackers3Read, 15, ObjectHelper.OBJECT_CONTACT, 'Theme2', 'Read');
      
         // test within a different time period
         timeTracker = new PlatformTracker__c(ObjectType__c=ObjectHelper.OBJECT_CONTACT
                                            ,UITheme__c='Theme2',UsageType__c='Insert');

         trackersUser3.addAll(trackers3Update);
         trackersUser3.addAll(trackers3Read);
         trackersUser3.add(timeTracker);
         insert trackersUser3;
         
         Test.setCreatedDate(timeTracker.Id, Datetime.now().addDays(-1));

         // so all of the records will be in the list         
         trackers3Update.add(tracker);
         trackersUser3.add(tracker);
      } // System.runAs(users[2]
      
      
      TrackerBatch tb = new TrackerBatch();
      Test.startTest();
      Database.executeBatch(tb,200);
      Test.stopTest();

      Integer allTrackerCnt = trackersUser1.size() + trackersUser2.size() + trackersUser3.size();      
      
      // all of the tracker records should be marked as processed - include the one added separately
      System.assertEquals(allTrackerCnt, [select count() from PlatformTracker__c where AddedToSummary__c=true]);
      
      // should be 4 different summary records
      TrackerSummary__c[] summaries = [Select Id, OwnerId, TrackerKey__c
                                                ,(Select Id
                                                        ,NbrInserts__c, NbrReads__c, NbrUpdates__c
                                                        ,ObjectType__c, TrackerKey__c
                                                        ,TrackerSummary__c, UITheme__c
                                                    From TrackerSummaryDetails__r)
                                            From TrackerSummary__c];
      System.assertEquals(4, summaries.size());
      Map<String,TrackerSummary__c> summaryMap = new Map<String,TrackerSummary__c>();
      // put in the map for easy reference
      for (TrackerSummary__c summary : summaries) {
         summaryMap.put(summary.TrackerKey__c, summary);
      }
      
      List<PlatformTracker__c[]> allSummaryTrackers = new List<PlatformTracker__c[]>();
      allSummaryTrackers.add(trackers1Read);
      allSummaryTrackers.add(trackers1Update);
      allSummaryTrackers.add(trackers1Insert);
      
      testSummary('Summary 1', summaryMap, 3, users[0].Id, allSummaryTrackers);

      allSummaryTrackers.clear();
      allSummaryTrackers.add(trackers2Read);
      allSummaryTrackers.add(trackers2Update);
      allSummaryTrackers.add(trackers2Insert);
      testSummary('Summary 2', summaryMap, 2, users[1].Id, allSummaryTrackers);
      
      allSummaryTrackers.clear();
      allSummaryTrackers.add(trackers3Read);
      allSummaryTrackers.add(trackers3Update);
      testSummary('Summary 3', summaryMap, 1, users[2].Id, allSummaryTrackers);
      
      allSummaryTrackers.clear();
      allSummaryTrackers.add(new PlatformTracker__c[]{timeTracker});
      testSummary('Summary 4', summaryMap, 1, users[2].Id, allSummaryTrackers);
      
      
   } // testBatch
   
   public static void createTrackers(PlatformTracker__c[] trackers, Integer nbrRecs, String objectType, String uITheme, String usageType) {
      for (Integer cnt=0; cnt<nbrRecs; cnt++) {
         trackers.add(new PlatformTracker__c(ObjectType__c=objectType
                                            ,UITheme__c=uITheme,UsageType__c=usageType));
      }
   } // createTrackers
   
   public static Map<Id, PlatformTracker__c> queryTrackers(Id[] trackerIds) {
      Map<Id, PlatformTracker__c> trackerMap = new Map<Id, PlatformTracker__c>(
                                                 [Select Id, ObjectType__c, UITheme__c, UsageType__c
                                                       , CreatedDate, CreatedById, CreatedBy.Id, CreatedBy.Profile.Id 
                                                    from PlatformTracker__c 
                                                   where Id in:trackerIds]);
      return trackerMap;                                     
   } // queryTrackers

   public static void testSummary(String testName, Map<String,TrackerSummary__c> summaryMap, Integer nbrDetails, Id userId, List<PlatformTracker__c[]> allSummaryTrackers) {
      System.debug('testSummary for '+testName);
      Id[] trackerIds = new Id[]{};
      for (PlatformTracker__c[] trackers : allSummaryTrackers) {
         trackerIds.add(trackers[0].Id);
      }
      Map<Id, PlatformTracker__c> trackerMap = queryTrackers(trackerIds);
      
      // should always be a read record for testing purposes
      PlatformTracker__c firstTracker = trackerMap.get(allSummaryTrackers[0][0].Id);
      String keySummary = TrackerBatch.buildKey(firstTracker, TrackerBatch.SUMMARY);
      TrackerSummary__c summary = summaryMap.get(keySummary);

      System.assertEquals(userId, summary.OwnerId, testName+' owner Id not matched ');
      System.assertEquals(nbrDetails, summary.TrackerSummaryDetails__r.size(), testName+' detail count failed ');
      
      // put detail in a map for easy reference
      Map<String, TrackerSummaryDetail__c> detailMap = new Map<String, TrackerSummaryDetail__c>();
      for (TrackerSummaryDetail__c detail : summary.TrackerSummaryDetails__r) {
         detailMap.put(detail.TrackerKey__c, detail);
      }
      
      for (PlatformTracker__c[] trackers : allSummaryTrackers) {
         PlatformTracker__c checkTracker = trackerMap.get(trackers[0].Id);
         String keyDetail = TrackerBatch.buildKey(checkTracker, TrackerBatch.DETAIL);
         TrackerSummaryDetail__c detail = detailMap.get(keyDetail);
         System.assertEquals(true, detail != null, testName+' detail not found detailKey='+keyDetail);
         if (checkTracker.UsageType__c == 'Read') {
            System.assertEquals(trackers.size(), detail.NbrReads__c, testName+' reads not equal!');
         } else if (checkTracker.UsageType__c == 'Update') {
            System.assertEquals(trackers.size(), detail.NbrUpdates__c, testName+' updates not equal!');
         } else if (checkTracker.UsageType__c == 'Insert') {
            System.assertEquals(trackers.size(), detail.NbrInserts__c, testName+' inserts not equal!');
         }
         
      } // for (PlatformTracker__c[] trackers
      
   } // testSummary
    
   static testMethod void testScheduler() {
      TestHelper.testScheduler('testTrackerBatch', new TrackerBatch());
   } // testScheduler
   */

} // class TrackerBatchTest