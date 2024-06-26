/*
 * A new class created to get the list of SMS History records which has matching phone number(Sender Number)to 
   related Contact/Lead phone number and update the related Contact/Lead Consent to text fields
   
  History
  -------
  07/20/2023 Jaipal     APR0148811 US4--Created
  01/11/2024 Lalan      APR0162915 SMS Conversation Box - Opportunity View 
 */

public without sharing class SMSHistoryHandler {


    public static void SMSHistoryAfter(Map<Id, tdc_tsw__Message__c> oldSMSMap, Map<Id, tdc_tsw__Message__c> newSMSMap, Boolean isInsert, Boolean isUpdate){
        updateContactLead(oldSMSMap, newSMSMap, isInsert, isUpdate); 

    }
    public static void SMSHistoryBefore(List<tdc_tsw__Message__c> smsList,Boolean isInsert, Boolean isUpdate) {
        updateSMSHistorywithOpportunityId(smsList);
    }

    public static void updateContactLead(Map<Id, tdc_tsw__Message__c> oldSMSMap, Map<Id, tdc_tsw__Message__c> newSMSMap, Boolean isInsert, Boolean isUpdate){
        List<Contact>cnctList = new List<Contact>();
        List<Lead>ldList = new List<Lead>();
        String squishedCntctPhone;
        String squishedLeadPhone;
        system.debug('InsideupdateContactLeadMethod');
         List<tdc_tsw__Message__c> smsList = new List<tdc_tsw__Message__c>();
        smsList = [Select Id, Name, tdc_tsw__Sender_Number__c, tdc_tsw__Contact__c, tdc_tsw__Lead__c, tdc_tsw__Contact__r.Phone, tdc_tsw__Contact__r.tdc_tsw__SMS_Opt_out__c, tdc_tsw__Contact__r.Consent_to_Text__c, tdc_tsw__Contact__r.Consent_to_Text_Date__c, tdc_tsw__Lead__r.Phone, tdc_tsw__Contact__r.Consent_to_Text_reason__c, tdc_tsw__Lead__r.tdc_tsw__SMS_Opt_out__c, tdc_tsw__Lead__r.Consent_to_Text__c, tdc_tsw__Lead__r.Consent_to_Text_Date__c, tdc_tsw__Lead__r.Consent_to_Text_reason__c From tdc_tsw__Message__c where Id in :newSMSMap.keySet()];
            
        for(tdc_tsw__Message__c newSMS : smsList){
            squishedCntctPhone = Utilities.removeExtraChars(newSMS.tdc_tsw__Contact__r.Phone, '0123456789');  
            squishedLeadPhone = Utilities.removeExtraChars(newSMS.tdc_tsw__Lead__r.Phone, '0123456789');  

        if((isInsert && (newSMS.tdc_tsw__Lead__c!= null || newSMS.tdc_tsw__Contact__c!= null)) || 
           (isUpdate && ((oldSMSMap.get(newSMS.Id)).tdc_tsw__Lead__c!= newSMS.tdc_tsw__Lead__c || (oldSMSMap.get(newSMS.Id)).tdc_tsw__Contact__c!= newSMS.tdc_tsw__Contact__c))){
           system.debug('isInsert'+isInsert+'isUpdate'+isUpdate+'squishedPhone'+squishedCntctPhone+'squishedLeadPhone'+squishedLeadPhone);
               system.debug(newSMS.tdc_tsw__Contact__c+'tdc_tsw__Contact__c'+newSMS.tdc_tsw__Sender_Number__c+'tdc_tsw__Sender_Number__c'+newSMS.tdc_tsw__Contact__r.Phone+'tdc_tsw__Contact__r.Phone');
               if(newSMS.Name == 'Incoming' && newSMS.tdc_tsw__Contact__c!= null && newSMS.tdc_tsw__Contact__r.Consent_to_Text__c!= True && newSMS.tdc_tsw__Contact__r.tdc_tsw__SMS_Opt_out__c == false && squishedCntctPhone == newSMS.tdc_tsw__Sender_Number__c.right(10)){
                
                newSMS.tdc_tsw__Contact__r.Consent_to_Text__c = True;
                newSMS.tdc_tsw__Contact__r.Consent_to_Text_Date__c = DateTime.now();
                newSMS.tdc_tsw__Contact__r.Consent_to_Text_reason__c = 'Prospect Opt In Via Text';
                cnctList.add(newSMS.tdc_tsw__Contact__r);
            } //if(newSMS.Name
                  if(newSMS.Name == 'Incoming' && newSMS.tdc_tsw__Lead__c!= null && newSMS.tdc_tsw__Lead__r.Consent_to_Text__c!= True && newSMS.tdc_tsw__Lead__r.tdc_tsw__SMS_Opt_out__c == false && squishedLeadPhone == newSMS.tdc_tsw__Sender_Number__c.right(10)){
                newSMS.tdc_tsw__Lead__r.Consent_to_Text__c = True;
                newSMS.tdc_tsw__Lead__r.Consent_to_Text_Date__c = DateTime.now();
                newSMS.tdc_tsw__Lead__r.Consent_to_Text_reason__c = 'Prospect Opt In Via Text';
                ldList.add(newSMS.tdc_tsw__Lead__r);
            }  //if(newSMS.Name
        }  //if((isInsert
                  
        } //for(tdc_tsw__Message__c newSMS
    
        if(!cnctList.isEmpty()){
            DMLHelper.performDML2(cnctList,DmlHelper.DML_UPDATE,'SMSHistoryHandler','updateContactLead','Update Contact From SMS History',null);
        }
        if(!ldList.isEmpty()){
            DMLHelper.performDML2(ldList,DmlHelper.DML_UPDATE,'SMSHistoryHandler','updateContactLead','Update Lead From SMS History',null);
        }
        
    } //updateContactLead 
    
    /* APR0162915: Below method is created to update the opportunity id when SMS history record is created */
    public static void updateSMSHistorywithOpportunityId(List<tdc_tsw__Message__c> newSMSHistories) {
        Set<Id> smsOwnerId = new Set<Id>();
        Set<Id> smsContactId = new Set<Id>();
        Set<Id> smsOpptyId = new Set<Id>();
        Map<Id,Id> newMapID = new Map<Id,Id>();
        
        for (tdc_tsw__Message__c smsHistory : newSMSHistories) {
            if(smsHistory.tdc_tsw__Opportunity__c==null && smsHistory.tdc_tsw__Contact__c!=null){
               smsOwnerId.add(smsHistory.ownerId);
                smsContactId.add(smsHistory.tdc_tsw__Contact__c);
			}
            else if(smsHistory.tdc_tsw__Opportunity__c!=null && smsHistory.tdc_tsw__Contact__c==null){
                smsOpptyId.add(smsHistory.tdc_tsw__Opportunity__c);
            }
        }
        
        // Query OpportunityContactRole
        for(OpportunityContactRole opptyContactRoleQuery :[Select Id, OpportunityId, ContactId,Opportunity.OwnerId From OpportunityContactRole Where IsPrimary = true and (OpportunityId =:smsOpptyId OR (ContactId = :smsContactId 
                                                 and Opportunity.OwnerId = :smsOwnerId)) ORDER BY Opportunity.Probability DESC, 
                                                 Opportunity.CreatedDate DESC limit 1]){
            
                                         
               if (opptyContactRoleQuery != null && opptyContactRoleQuery.OpportunityId != null && !newMapID.containsKey(opptyContactRoleQuery.ContactId) && !smsContactId.isEmpty()) {
                newMapID.put(opptyContactRoleQuery.ContactId,opptyContactRoleQuery.OpportunityId);
                }
               else if (opptyContactRoleQuery != null && opptyContactRoleQuery.ContactId != null && !newMapID.containsKey(opptyContactRoleQuery.OpportunityId) && !smsOpptyId.isEmpty()) {
                newMapID.put(opptyContactRoleQuery.OpportunityId,opptyContactRoleQuery.ContactId);
                }
          }//OpportunityContactRole opptyContactRoleQuery 
             // Update SMS history Opportunity field with Opportunity Id  
          for (tdc_tsw__Message__c smsHistory : newSMSHistories) {
              if(newMapID.containsKey(smsHistory.tdc_tsw__Contact__c)){
                smsHistory.tdc_tsw__Opportunity__c = newMapID.get(smsHistory.tdc_tsw__Contact__c);
             }
              // Update SMS history Contact field with Contact Id
              else if(newMapID.containsKey(smsHistory.tdc_tsw__Opportunity__c)){
                smsHistory.tdc_tsw__Contact__c = newMapID.get(smsHistory.tdc_tsw__Opportunity__c);
             }
           }//tdc_tsw__Message__c smsHistory

    } //updateSMSHistorywithOpportunityId
    
} //SMSHistoryHandler