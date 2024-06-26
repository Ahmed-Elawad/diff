/* 

  History
  -------
  07/05/2018 Lynn Michels        Created
 
 */
 public with sharing class ReferencePC implements TriggerInterface{
   //called in TriggerMethods.checkBeforeLoop
   public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {}
        
   //called in TriggerMethods.checkBeforeLoop
   public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {

        List<Reference_P_C__c> listofRefPC= [SELECT id, case_Lookup__c, Case_Lookup__r.AccountId, RecordTypeId FROM Reference_P_C__c WHERE Id IN: (List<Reference_P_C__c>)recs];
        List<Reference_P_C__c> refsToUpdate = new List<Reference_P_C__c>();
        Id recTypeId = RecordTypeHelper.getRecordType('P&C Onboarding', 'Reference_P_C__c').getRecordTypeID();
system.debug('recTypeId' +recTypeId);
        map<id,Reference_P_C__c> accountToRefPC = new map<id,Reference_P_C__c>();
        //collect Prospect client ids
        for (Reference_P_C__c refPC : listofRefPC){         
            //only collect the records for the P&C Onboarding records
            if (refPC.RecordTypeId == recTypeId){
        system.debug('only for onboarding');
                accountToRefPC.put(refPC.Case_Lookup__r.Accountid, refPC);
            }
        }//end for
        
        List<Acord__c> acords = [SELECT id, Prospect_Client__c, 
                    (Select id FROM Carrier_Quotes__r ORDER BY CreatedDate DESC LIMIT 1)
                FROM Acord__c WHERE Prospect_Client__c IN: accountToRefPC.keyset()
                ORDER BY CreatedDate DESC LIMIT 1];
system.debug('checkAllBeforeTrigger acords' + acords);
    
        if (!acords.isEmpty()){
            for (Acord__c a: acords){
                Reference_P_C__c ref = accountToRefPC.get(a.Prospect_Client__c);
                
                for (Carrier_Quote__c cq: a.Carrier_Quotes__r){
                    ref.Carrier_Quote_Lookup__c = cq.id;
                }
                refsToUpdate.add(ref);
                
            }
        }//end if
system.debug('checkAllBeforeTrigger refsToUpdate' + refsToUpdate);
        update refsToUpdate;

    
    }//end checkAllAfterTrigger
   
   //called in TriggerMethods.checkInLoop
   public void checkBeforeTrigger(SObject newRec, SObject oldRec) {} 
   //called in TriggerMethods.checkInLoop
   public void processBeforeTriggerActions() {}
   
   //called in TriggerMethods.checkOutsideLoop
   public void checkAfterTrigger(SObject newRec, SObject oldRec) {}
   //called in TriggerMethods.checkOutsideLoop
   public void processAfterTriggerActions() {}
   
      
   
  
}