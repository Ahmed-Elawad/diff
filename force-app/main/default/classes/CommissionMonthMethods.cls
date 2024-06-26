/* Methods for the Commissions Month object
   
  History
  -------
  03/10/2016 Dan Carmen   Created
  
 */
public with sharing class CommissionMonthMethods {

   public static void checkTriggerBeforeActions(CommissionMonth__c commMonth, CommissionMonth__c oldCommMonth) {
      
   } // checkTriggerBeforeActions
 
   public static void checkTriggerAfterActions(CommissionMonth__c commMonth,CommissionMonth__c oldCommMonth) {
      if (oldCommMonth != null && commMonth.NSSStatus__c != oldCommMonth.NSSStatus__c) {
         createChatterNotification(commMonth,oldCommMonth);
      }
      
   } // checkTriggerAfterActions
   
   public static void processTriggerBefore() {
   } // processTriggerBefore
   
   public static void processTriggerAfter() {
      processChatterNotifications();
   } // processTriggerAfter

   public static final String MONTH_NOTIFICATION_SETTING = 'Commission Month Notification';
   
   // the notifications we're going to make
   public static Map<Id,String> notificationMap = new Map<Id,String>();
   
   public static void createChatterNotification(CommissionMonth__c commMonth,CommissionMonth__c oldCommMonth) {
      String msg = 'The Commission Month status changed from '+oldCommMonth.NSSStatus__c+' to '+commMonth.NSSStatus__c;
      notificationMap.put(commMonth.Id, msg);
      
   } // createChatterNotification
   
   public static void processChatterNotifications() {
      if (!notificationMap.isEmpty()) {
         ChatterMentionPost.sendPostsMentionPublicGroup(MONTH_NOTIFICATION_SETTING, notificationMap, true);
      } // if (!notificationMap.isEmpty

   } // processChatterNotifications
   
} // class CommissionMonthMethod