/* Created by Pujitha Madmananchi 10/09/2020
 * 
 * 
 * 
 */

trigger MarketingInsights on Marketing_Insights__c (before insert, before update, after insert) {
     if(Trigger.isBefore){
          InsightHelper.updateAccount(trigger.new); 
     }
     if(Trigger.isAfter){
          InsightHelper.ChatterPost(trigger.new);
     }
       
}