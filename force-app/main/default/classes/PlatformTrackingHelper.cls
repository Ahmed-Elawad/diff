/* 
 * Track the platform transactions occur
 *
 * History
 * -------
   08/21/2017 Dan Carmen       Created
   11/10/2023 Dan Carmen       Comment out code

 */
public without sharing class PlatformTrackingHelper {
    public PlatformTrackingHelper() {}

   /*
   public static Set<Id> idProcessedSet = new Set<Id>();
   
   public static Boolean TRACK_ANY_USER=Label.PlatformTracker_AnyUser == 'Y';
      
   public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {
   } // checkAllBeforeTrigger

   public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {
      // only process if one record and not already processed
      //System.debug('PlatformTrackingHelper.checkAllAfterTrigger recs='+recs.size());
      if (recs.size() == 1 && !idProcessedSet.contains(recs[0].Id)) {
         idProcessedSet.add(recs[0].Id);
         String objectName = recs[0].getSObjectType().getDescribe().getName();
         //System.debug('PlatformTrackingHelper.checkAllAfterTrigger objectName='+objectName);
         // if a lead, don't log on convert
         Boolean doNotProceed = false;
         if (recs[0].getSObjectType() == Lead.sObjectType && oldMap != null) {
            Lead ld = (Lead)recs[0];
            Lead oldLd = (Lead)oldMap.get(ld.Id);
            doNotProceed = (ld.IsConverted && !oldLd.IsConverted);
         }

         if (!doNotProceed && !TRACK_ANY_USER) {
            // only log if a sales user
            User runningUser = UserHelper.getRunningUser();
            system.debug('runningUser'+runningUser);
            if(runningUser == null){
                doNotProceed = true;
            }
            else{
                doNotProceed = !(runningUser.Profile != null && Utilities.isSalesProf(runningUser.Profile.Name));
            }
         }

         if (!doNotProceed) {
            String usageType = (oldMap == null ? 'Insert' : 'Update');
            //System.debug('PlatformTrackingHelper.checkAllAfterTrigger usageType='+usageType);
            PlatformTracker__c tracker = new PlatformTracker__c(RecordId__c=recs[0].Id,
                                      ObjectType__c=objectName,
                                      UITheme__c=UserInfo.getUiThemeDisplayed(),
                                     UsageType__c=usageType);
            try {
               insert tracker;
            } catch (Exception e) {
               System.debug('PlatformTrackingHelper exception: '+e.getMessage()+'; '+e.getStackTraceString());
            }
         }
      } // if (recs.size() == 1
   } // checkAllAfterTrigger

   public void checkBeforeTrigger(SObject newRec, SObject oldRec) {}
   
   public void processBeforeTriggerActions() {}
   
   public void checkAfterTrigger(SObject newRec, SObject oldRec) {}
   
   public void processAfterTriggerActions() {}
   */

} // class PlatformTrackingHelper