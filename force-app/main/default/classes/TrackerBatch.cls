/* Batch process to summarize the tracking object
   
  History
  -------
  08/23/2017 Dan Carmen       Created
  09/25/2017 Dan Carmen       Summarize by person per day
  11/10/2023 Dan Carmen       Comment out code
  
 */
global without sharing class TrackerBatch {

    public TrackerBatch() {}
/*    
global without sharing class TrackerBatch implements Database.Batchable<SObject>, Database.Stateful , Schedulable {
    
   // The total number of tracker records found. 
   global Integer numberTrackers = 0;
   
   // messages that occur during the process.
   global String processNotes = '';
   
   global JobHelper jh = new JobHelper('TrackerBatch');

   global TrackerBatch() {
   } // UserUpdateFromContact
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      
      return Database.getQueryLocator([SELECT Id,AddedToSummary__c,ObjectType__c,Platform__c
                                             ,RecordId__c,UITheme__c,UsageType__c
                                             ,CreatedDate
                                             ,CreatedById
                                             ,CreatedBy.Id
                                             ,CreatedBy.Profile.Id
                                         FROM PlatformTracker__c 
                                        WHERE AddedToSummary__c = false
                                        ORDER BY CreatedDate ASC]);
   } // start

   // In order to schedule a batch run
   global void execute(SchedulableContext sc) {
      TrackerBatch tb = new TrackerBatch();
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('TrackerBatch');
      Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 1000);
      database.executeBatch(tb, batchSize);
   } // execute

   // Execute a batch.
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<PlatformTracker__c> trackers = (List<PlatformTracker__c>)scope;
      numberTrackers += trackers.size();
      for (PlatformTracker__c tracker : trackers) {
         summarizeRecord(tracker);
      }
      // save the AddedToSummary__c flag
      update trackers;
      checkSummaryRecords();
   } // execute

   global class TrackerWrapper {
      public TrackerSummary__c summary = null;
      public Map<String, TrackerSummaryDetail__c> detailMap = new Map<String, TrackerSummaryDetail__c>();
   } // class TrackerWrapper

   global Map<String, TrackerWrapper> summaryMap = new Map<String, TrackerWrapper>();
   
   global static String SUMMARY='Summary';
   global static String DETAIL='Detail';
   
   global void summarizeRecord(PlatformTracker__c tracker) {
      String summaryKey = buildKey(tracker,SUMMARY);
      String detailKey = buildKey(tracker,DETAIL);
      
      TrackerWrapper wrapper = (summaryMap.containsKey(summaryKey) ? summaryMap.get(summaryKey) : new TrackerWrapper());
      if (wrapper.summary == null) {
         wrapper.summary = buildSummary(tracker, summaryKey);
      }
      summaryMap.put(summaryKey, wrapper);
      TrackerSummaryDetail__c detail = wrapper.detailMap.get(detailKey);
      if (detail == null) {
         detail = buildDetail(tracker, detailKey);
         wrapper.detailMap.put(detailKey, detail);
      }
      
      if (tracker.UsageType__c == 'Read') {
         detail.NbrReads__c++;
      } else if (tracker.UsageType__c == 'Update') {
         detail.NbrUpdates__c++;
      } else if (tracker.UsageType__c == 'Insert') {
         detail.NbrInserts__c++;
      }
      tracker.AddedToSummary__c = true;
   } // summarizeRecord
   
   public static final Integer KEY_SIZE = TrackerSummary__c.TrackerKey__c.getDescribe().getLength();
   
   global static TrackerSummary__c buildSummary(PlatformTracker__c tracker, String key) {
      System.debug('buildSummary new summary for key='+key);
      TrackerSummary__c summary = new TrackerSummary__c(TrackerKey__c=key
                          ,OwnerId=tracker.CreatedById
                          //,ObjectType__c=tracker.ObjectType__c
                          //,NumberRecs__c=0
                          //,NbrInserts__c=0
                          //,NbrReads__c=0
                          //,NbrUpdates__c=0
                          //,UITheme__c=tracker.UITheme__c
                          //,UsageType__c=tracker.UsageType__c
                          //,ProfileId__c=tracker.CreatedBy.Profile.Id
                          );
      // interval is the entire day
      Time startTime = Time.newInstance(0,0,0,0);
      Time endTime = Time.newInstance(23,59,59,999);
      summary.StartTime__c = DateTime.newInstance(tracker.CreatedDate.date(), startTime);
      summary.EndTime__c = DateTime.newInstance(tracker.CreatedDate.date(), endTime); 
      summary.IntervalDate__c = tracker.CreatedDate.date();
      return summary;
   } // buildSummary

   global static TrackerSummaryDetail__c buildDetail(PlatformTracker__c tracker, String key) {
      System.debug('buildDetail new detail for key='+key);
      TrackerSummaryDetail__c detail = new TrackerSummaryDetail__c(TrackerKey__c=key
                          ,ObjectType__c=tracker.ObjectType__c
                          ,NbrInserts__c=0
                          ,NbrReads__c=0
                          ,NbrUpdates__c=0
                          ,UITheme__c=tracker.UITheme__c);
      return detail;
   } // buildDetail

   global static String buildKey(PlatformTracker__c tracker, String summaryOrDetail) {
      String key = tracker.CreatedById;
      String dateKey=tracker.CreatedDate.format('yyyyMMdd');
      key = key + ':' + dateKey+':';
      if (summaryOrDetail == DETAIL) {
         key += tracker.ObjectType__c+tracker.UITheme__c;
      }
      
      //String key = tracker.ObjectType__c+tracker.CreatedBy.Profile.Id+tracker.UITheme__c.left(20);
      // make sure we don't go beyond the size
      key = key.left(KEY_SIZE);
      // put the key to the beginning of the hour
      System.debug('buildKey '+summaryOrDetail+' key='+key);
      return key;
   } // buildKey
   
   global Integer existingSummaryRecords = 0;
   global Integer existingDetailRecords = 0;
   global Integer totalSummaryRecordsSaved = 0;
   global Integer totalDetailRecordsSaved = 0;
      
   global void checkSummaryRecords() {
      if (!summaryMap.isEmpty()) {

         // check for existing records
         TrackerSummary__c[] summaries = [Select Id, OwnerId, TrackerKey__c
                                                ,(Select Id
                                                        ,NbrInserts__c, NbrReads__c, NbrUpdates__c
                                                        ,ObjectType__c, TrackerKey__c
                                                        ,TrackerSummary__c, UITheme__c
                                                    From TrackerSummaryDetails__r)
                                            From TrackerSummary__c
                                           Where TrackerKey__c in :summaryMap.keySet()];
         
         existingSummaryRecords += summaries.size();
         for (TrackerSummary__c savedSummary : summaries) {
            TrackerWrapper wrapper = summaryMap.get(savedSummary.TrackerKey__c);
            if (wrapper != null) {
               existingSummaryRecords++;
               for (TrackerSummaryDetail__c savedDetail : savedSummary.TrackerSummaryDetails__r) {
                  TrackerSummaryDetail__c newDetail = wrapper.detailMap.get(savedDetail.TrackerKey__c);
                  if (newDetail != null) {
                     existingDetailRecords++;
                     newDetail.NbrInserts__c += savedDetail.NbrInserts__c;
                     newDetail.NbrReads__c += savedDetail.NbrReads__c;
                     newDetail.NbrUpdates__c += savedDetail.NbrUpdates__c;
                  }
               } // for (TrackerSummaryDetail__c savedDetail
            } // if (wrapper != null
         } // for (TrackerSummary__c savedSummary
         
         saveRecords();
      } // if (!summaryMap.isEmpty
   } // checkSummaryRecords
   
   global void saveRecords() {
      TrackerSummary__c[] recordsToUpsert = new TrackerSummary__c[]{};
      for (TrackerWrapper wrapper : summaryMap.values()) {
         recordsToUpsert.add(wrapper.summary);
      }
      totalSummaryRecordsSaved += recordsToUpsert.size();
      Database.upsert(recordsToUpsert, TrackerSummary__c.Fields.TrackerKey__c, false);
      
      TrackerSummaryDetail__c[] detailsToUpsert = new TrackerSummaryDetail__c[]{};
      for (TrackerWrapper wrapper : summaryMap.values()) {
         if (wrapper.summary.Id != null) {
            for (TrackerSummaryDetail__c detail : wrapper.detailMap.values()) {
               if (detail.TrackerSummary__c == null) {
                  detail.TrackerSummary__c = wrapper.summary.Id;
               }
               detailsToUpsert.add(detail);
            } // for (TrackerSummaryDetail__c detail
         }
      } // for (TrackerWrapper wrapper
      
      totalDetailRecordsSaved += detailsToUpsert.size();
      Database.upsert(detailsToUpsert, TrackerSummaryDetail__c.Fields.TrackerKey__c, false);
      summaryMap.clear();

   } // saveRecords
   
   global void finish(Database.BatchableContext bc){
      String message = '\nTotal Trackers Processed: '+numberTrackers+' ';
      message += '\n Existing Summary Records: '+existingSummaryRecords+' ';
      message += '\n Total Summary Records Saved: '+totalSummaryRecordsSaved+' ';
      message += '\n Existing Detail Records: '+existingDetailRecords+' ';
      message += '\n Total Detail Records Saved: '+totalDetailRecordsSaved+' ';
      
      message += '\n\n'+processNotes;
      
      jh.completeJob(bc, 'TrackerBatch', message);
   } // finish
   */

} // class TrackerBatch