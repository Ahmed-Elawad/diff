/* Handles after actions on SMS History Object
 * 
 * 
 * History
 * -------
 * 07/20/2023 Jaipal        APR0148811- Created this trigger to call the SMSHistoryHandler Class if it is an Update or Insert for Old and New
   01/11/2024 Lalan         APR0162915 SMS Conversation Box - Opportunity View 
*/

trigger SMSHistoryAfter on tdc_tsw__Message__c (before insert, after insert, after update) {
    
    
    if(Trigger.isInsert || Trigger.isUpdate){
        if(trigger.isafter){
         SMSHistoryHandler.SMSHistoryAfter(Trigger.OldMap, Trigger.NewMap, Trigger.isInsert, Trigger.isUpdate);
        }
        /*APR0162915 : Added before logic */
        if(trigger.isBefore){
        SMSHistoryHandler.SMSHistoryBefore(Trigger.new,Trigger.isInsert, Trigger.isUpdate);
        }
        

    
    }
  //  SObjectType smsHist = tdc_tsw__Message__c;
  //  sObject smsHist = tdc_tsw__Message__c;
 //   SMSHistoryHelper.updateContactLead(smsHist.tdc_tsw__Contact__c, smsHist.tdc_tsw__Lead__c);

  /*  List <tdc_tsw__Message__c>eligibleToText = new List<tdc_tsw__Message__c>();
   // List <Id>notEligibleToEmail = new List<Id>();
    eligibleToText = [Select Name, tdc_tsw__Lead__c, tdc_tsw__Contact__c, tdc_tsw__Sender_Number__c From tdc_tsw__Message__c Where tdc_tsw__Contact__c!= null && tdc_tsw__Lead__c!= null];
    for(tdc_tsw__Message__c smsHist : Trigger.New){
        SMSHistoryHelper.updateContactLead(eligibleToEmail.tdc_tsw__Contact__r, eligibleToEmail.tdc_tsw__Lead__r);
    }
    */
}