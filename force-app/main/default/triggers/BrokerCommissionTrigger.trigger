/*
 History
  -------
  07/10/2022 Rohit Ranjan   Created
  05/12/2022 Tej Pothuri  APR0163741: Broker commission work queues
*/

trigger BrokerCommissionTrigger on Broker_Commission__c (after insert, after Update) {
   Broker_Commission__c[] recs = (Broker_Commission__c[])Trigger.new;
   BrokerCommissionTriggerMethods.handleTrigger(recs, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
}