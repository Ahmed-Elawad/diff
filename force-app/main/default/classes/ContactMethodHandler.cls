/** Methods on the Contact object
*
* History
* -------
 12/11/2023 Lalan kumar      APR0162915: Created
 05/30/2024 Lalan Kumar     APR0171000: Update fields on the Oppty object with the exact data on the Contact
* 
*/
public without sharing class ContactMethodHandler implements TriggerInterfaceC {
    
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        if (TriggerMethods.didTriggerRun('ContactMethodHandler',recs,isBefore,isAfter)) {
            return;
        }
        SObjectType objType = TriggerMethods.objType;
        if (isAfter) {
            if (objType == Contact.sObjectType) {
                verifyPhoneandConsentToText((Contact[])recs, (Map<Id,Contact>)oldMap);
            } 
        }
    } // handleTrigger
    
    public static void verifyPhoneandConsentToText(Contact[] conList, Map<Id,Contact> oldMap) {
        Id[] conPhoneandConsentToText = new Id[]{};
            for(Contact ctct: conList){
                Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);           
                //oppty phone, consent to text, SMS opt out, Last SMS Engagement date, Consent to text Date, SMS owmer,Verbal SMS Consent and Verbal SMS Consent Date are not null then add it to Con id
                if(/*((ctct.MobilePhone!= null && ctct.Consent_to_Text__c)||ctct.tdc_tsw__SMS_Opt_out__c)
                   &&*/ (oldCtct == null || (ctct.MobilePhone != oldCtct.MobilePhone ||ctct.Consent_to_Text__c !=oldCtct.Consent_to_Text__c ||(ctct.tdc_tsw__SMS_Opt_out__c == true && ctct.tdc_tsw__SMS_Opt_out__c!=oldCtct.tdc_tsw__SMS_Opt_out__c)||ctct.Last_Sms_Engagement_Date__c != oldCtct.Last_Sms_Engagement_Date__c || ctct.Consent_to_Text_Date__c != oldCtct.Consent_to_Text_Date__c || ctct.Current_SMS_Owner__c != oldCtct.Current_SMS_Owner__c || ctct.Verbal_SMS_Consent__c != oldCtct.Verbal_SMS_Consent__c || ctct.Verbal_SMS_Consent_Date__c != oldCtct.Verbal_SMS_Consent_Date__c))){
                                               conPhoneandConsentToText.add(ctct.Id);
                                           } 
            } // for(Contact ctct: conList
        //calling method updateOppPhoneandConsentToText 
        if(!conPhoneandConsentToText.isEmpty())
        {
            system.debug('loop==>');
            updateOppPhoneandConsentToText(conPhoneandConsentToText);
        }
    }
    /*APR0156837: Added below method to copy phone,consent to text and SMS opt out from contact role to oppty */
    public static void updateOppPhoneandConsentToText(Id[] conPhoneandConsentToText){
        Map<String,Set<OpportunityContactRole>> mapCntOppRole = new Map<String,Set<OpportunityContactRole>>();
        Map<Id,Opportunity> updateOppMap = new Map<Id,Opportunity>();
        
         /*APR0171000: Added Oppty and contact fields Last_Sms_Engagement_Date__c,Consent_to_Text_Date__c, Current_SMS_Owner__c,Verbal_SMS_Consent__c and Verbal_SMS_Consent_Date__c in the query*/ 
        for(OpportunityContactRole rec:[Select Id,OpportunityId,Opportunity.Id
                                        ,ContactId,Contact.Consent_to_Text__c,Opportunity.Consent_to_Text__c
                                        ,Contact.MobilePhone,Contact.tdc_tsw__SMS_Opt_out__c,Contact.Last_Sms_Engagement_Date__c,Contact.Consent_to_Text_Date__c,Contact.Current_SMS_Owner__c,Contact.Verbal_SMS_Consent__c,Contact.Verbal_SMS_Consent_Date__c,
                                        Opportunity.Phone__c,Opportunity.tdc_tsw__SMS_Opt_out__c,Opportunity.Last_Sms_Engagement_Date__c,Opportunity.Consent_to_Text_Date__c,Opportunity.Current_SMS_Owner__c ,Opportunity.Verbal_SMS_Consent__c ,Opportunity.Verbal_SMS_Consent_Date__c
                                        from OpportunityContactRole 
                                        where ContactId in :conPhoneandConsentToText and IsPrimary = true
                                        and Opportunity.IsClosed = false]) { 
                                            Contact ctct = rec.Contact;
                                            Opportunity opp = rec.Opportunity;
                                            if (ctct.Consent_to_Text__c != opp.Consent_to_Text__c || ctct.MobilePhone != opp.Phone__c || ctct.tdc_tsw__SMS_Opt_out__c!=opp.tdc_tsw__SMS_Opt_out__c ||ctct.Last_Sms_Engagement_Date__c != opp.Last_Sms_Engagement_Date__c || ctct.Consent_to_Text_Date__c != opp.Consent_to_Text_Date__c || ctct.Current_SMS_Owner__c != opp.Current_SMS_Owner__c || ctct.Verbal_SMS_Consent__c != opp.Verbal_SMS_Consent__c || ctct.Verbal_SMS_Consent_Date__c != opp.Verbal_SMS_Consent_Date__c) {
                                                
                                             /*APR0171000: Updating Oppty fields Last_Sms_Engagement_Date__c,Consent_to_Text_Date__c, Current_SMS_Owner__c,Verbal_SMS_Consent__c and Verbal_SMS_Consent_Date__c from contact fields*/ 
                                                Opportunity updateOpp = new Opportunity(Id=opp.Id, Consent_to_Text__c=ctct.Consent_to_Text__c
                                                                                        ,Phone__c=ctct.MobilePhone,tdc_tsw__SMS_Opt_out__c=ctct.tdc_tsw__SMS_Opt_out__c,Last_Sms_Engagement_Date__c=ctct.Last_Sms_Engagement_Date__c,Consent_to_Text_Date__c=ctct.Consent_to_Text_Date__c,Current_SMS_Owner__c=ctct.Current_SMS_Owner__c,Verbal_SMS_Consent__c=ctct.Verbal_SMS_Consent__c,Verbal_SMS_Consent_Date__c=ctct.Verbal_SMS_Consent_Date__c);
                                                updateOppMap.put(updateOpp.Id, updateOpp);
                                            }
                                            
                                        } // for(OpportunityContactRole rec
        
        if(!updateOppMap.isEmpty()){
            DmlHelper.performDML(updateOppMap.values(), DmlHelper.DML_UPDATE, 'ContactMethodHandler', 'updateOppPhoneandConsentToText', 'Update Oppty Phone and Consent to text', true);
        }
    }//End - updateOppPhoneandConsentToText 
    
} // class ContactMethodHandler