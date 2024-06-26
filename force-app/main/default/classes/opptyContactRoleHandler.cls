/* Methods for the OpportunityContactRoleChangeEvent object.
   
  History
  -------
  03/18/2024 Lalan Kumar     Created
  05/30/2024 Lalan Kumar     APR0171000: Update fields on the Oppty object with the exact data on the Contact

*/
public class opptyContactRoleHandler {
    
    public static void updateOppPhoneandConsentToText(Set<String> ocrIDs){
        Map<Id,Opportunity> updateOppMap = new Map<Id,Opportunity>();
       /*APR0171000: Added Oppty and contact fields Last_Sms_Engagement_Date__c,Consent_to_Text_Date__c, Current_SMS_Owner__c,Verbal_SMS_Consent__c and Verbal_SMS_Consent_Date__c in the query*/ 
        list<OpportunityContactRole> ocRoles = new list<OpportunityContactRole>([select id,contactId,OpportunityId,Opportunity.Id,IsPrimary,Contact.MobilePhone,Contact.Consent_to_Text__c,Contact.tdc_tsw__SMS_Opt_out__c,Contact.Last_Sms_Engagement_Date__c,Contact.Consent_to_Text_Date__c,Contact.Current_SMS_Owner__c,Contact.Verbal_SMS_Consent__c,Contact.Verbal_SMS_Consent_Date__c,
                                                                                 Opportunity.Phone__c,Opportunity.Consent_to_Text__c,Opportunity.tdc_tsw__SMS_Opt_out__c,Opportunity.Last_Sms_Engagement_Date__c,Opportunity.Consent_to_Text_Date__c,Opportunity.Current_SMS_Owner__c,Opportunity.Verbal_SMS_Consent__c,Opportunity.Verbal_SMS_Consent_Date__c
                                                                                 from OpportunityContactRole
                                                                                    where Id in :ocrIDs ORDER BY IsPrimary DESC
                                                                                   ]);
        
        for(OpportunityContactRole ocr: ocRoles){
            Contact ctct = ocr.Contact;
            Opportunity opp = ocr.Opportunity;
            if (ocr.IsPrimary && (ctct.Consent_to_Text__c != opp.Consent_to_Text__c || ctct.MobilePhone != opp.Phone__c|| ctct.tdc_tsw__SMS_Opt_out__c != opp.tdc_tsw__SMS_Opt_out__c||ctct.Last_Sms_Engagement_Date__c != opp.Last_Sms_Engagement_Date__c || ctct.Consent_to_Text_Date__c != opp.Consent_to_Text_Date__c || ctct.Current_SMS_Owner__c != opp.Current_SMS_Owner__c || ctct.Verbal_SMS_Consent__c != opp.Verbal_SMS_Consent__c || ctct.Verbal_SMS_Consent_Date__c != opp.Verbal_SMS_Consent_Date__c)) {
                /*APR0171000: Updating Oppty fields Last_Sms_Engagement_Date__c,Consent_to_Text_Date__c, Current_SMS_Owner__c,Verbal_SMS_Consent__c and Verbal_SMS_Consent_Date__c from contact fields*/ 
                Opportunity updateOpp = new Opportunity(Id=opp.Id, Consent_to_Text__c=ctct.Consent_to_Text__c,Phone__c=ctct.MobilePhone,tdc_tsw__SMS_Opt_out__c=ctct.tdc_tsw__SMS_Opt_out__c,Last_Sms_Engagement_Date__c=ctct.Last_Sms_Engagement_Date__c,Consent_to_Text_Date__c=ctct.Consent_to_Text_Date__c,Current_SMS_Owner__c=ctct.Current_SMS_Owner__c,Verbal_SMS_Consent__c=ctct.Verbal_SMS_Consent__c,Verbal_SMS_Consent_Date__c=ctct.Verbal_SMS_Consent_Date__c);
                updateOppMap.put(updateOpp.Id, updateOpp);
             }
           
        }
          
         if(!updateOppMap.isEmpty()){
             OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
            DmlHelper.performDML(updateOppMap.values(), DmlHelper.DML_UPDATE, 'opptyContactRoleHandler', 'updateOppPhoneandConsentToText', 'Update Oppty Phone and Consent to text', true);
             OpptyMethods.SKIP_OPPTY_TRIGGERS = false;
        }
    }
}