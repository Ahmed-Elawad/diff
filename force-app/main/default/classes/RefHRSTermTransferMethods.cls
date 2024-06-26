/*
    Used to keep Reference HRS Termination/Transfer records that have children in sync with the parent
    
    History
    --------
    02/16/2017  Lynn Michels    Created
    05/12/2023	Reetesh Pandey	Fiscal Year and Fiscal month to push to child ref record
*/

public without sharing class RefHRSTermTransferMethods implements TriggerInterface {
    
    public RefHRSTermTransferMethods() {
      
   }//RefHRSTermTransferMethods
   
   public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

   public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

   public void checkBeforeTrigger(SObject newRec, SObject oldRec) {
       
   } //checkBeforeTrigger
   
   public void processBeforeTriggerActions() {
     
   } //processBeforeTriggerActions
   
   public static Set<ID> changedRecordIds = new Set<ID>();
   public static Boolean skipTrigger = false;
   public static Case[] casesToUpdate = new Case[]{};
    
   public void checkAfterTrigger(SObject newRec, SObject oldRec) {

        //if any of these field values change on the parent record, continue
        if (newRec.get('Parent_Ref_HRS_Termination_Transfer__c')==null){
            if(newRec.get('Code_Lost_Date__c') != oldRec.get('Code_Lost_Date__c') ||
                newRec.get('Total_of_Employees__c') != oldRec.get('Total_of_Employees__c') ||
                newRec.get('Total_of_IDs__c') != oldRec.get('Total_of_IDs__c') ||
                newRec.get('Case_Type__c') != oldRec.get('Case_Type__c') ||
                newRec.get('Termination_or_Transfer__c') != oldRec.get('Termination_or_Transfer__c') ||
                newRec.get('Primary_Tier_1_Reasons__c') != oldRec.get('Primary_Tier_1_Reasons__c') ||
                newRec.get('Primary_Tier_2_Reasons__c') != oldRec.get('Primary_Tier_2_Reasons__c') ||
                newRec.get('Primary_Tier_3_Reasons__c') != oldRec.get('Primary_Tier_3_Reasons__c')){
            //collect the ids of the records that have changed  
            changedRecordIds.add(newRec.id);
            }//end if 
        }//end if
       
       if(!oldRec.isSet('Rejection_Date__c') && newRec.get('Rejection_Date__c') != oldRec.get('Rejection_Date__c')) {
           Case c = new Case(Id=(Id)newRec.get('Case_Lookup__c'),Status = 'Solved');
           casesToUpdate.add(c);
       }
    
   } //checkAfterTrigger
   
   public void processAfterTriggerActions() {
        List<Reference_HRS_Termination_Transfer__c> recordsToUpdate = new List<Reference_HRS_Termination_Transfer__c>();
        Id relatedTermTransferRtId = Schema.SObjectType.Reference_HRS_Termination_Transfer__c.getRecordTypeInfosByName().get('Related Term/Transfer Record').getRecordTypeId(); 
        if(!changedRecordIds.isEmpty()){        
            //query for the child records   
            List<Reference_HRS_Termination_Transfer__c> childrecords = [SELECT Id, Parent_Ref_HRS_Termination_Transfer__r.Code_Lost_Date__c,
                                    Parent_Ref_HRS_Termination_Transfer__r.Total_of_Employees__c,
                                    Parent_Ref_HRS_Termination_Transfer__r.Total_of_IDs__c,
                                    Parent_Ref_HRS_Termination_Transfer__r.Case_Type__c,
                                    Parent_Ref_HRS_Termination_Transfer__r.Termination_or_Transfer__c,
                                    Parent_Ref_HRS_Termination_Transfer__r.Primary_Tier_1_Reasons__c,
                                    Parent_Ref_HRS_Termination_Transfer__r.Primary_Tier_2_Reasons__c,
                                    Parent_Ref_HRS_Termination_Transfer__r.Primary_Tier_3_Reasons__c,
                                    Parent_Ref_HRS_Termination_Transfer__r.Fiscal_Year__c,
                                    Parent_Ref_HRS_Termination_Transfer__r.Fiscal_Lost_Month__c                                    
                                    FROM Reference_HRS_Termination_Transfer__c
                                    WHERE Parent_Ref_HRS_Termination_Transfer__c IN: changedRecordIds AND RecordTypeId =: relatedTermTransferRtId];
        
            if(!childrecords.isEmpty()){
                for(Reference_HRS_Termination_Transfer__c child : childrecords){
                    Reference_HRS_Termination_Transfer__c r = new Reference_HRS_Termination_Transfer__c (
                                Id = child.Id,
                                Code_Lost_Date__c = child.Parent_Ref_HRS_Termination_Transfer__r.Code_Lost_Date__c,
                                Total_of_Employees__c = child.Parent_Ref_HRS_Termination_Transfer__r.Total_of_Employees__c,
                                Total_of_IDs__c = child.Parent_Ref_HRS_Termination_Transfer__r.Total_of_IDs__c,
                                Case_Type__c = child.Parent_Ref_HRS_Termination_Transfer__r.Case_Type__c,
                                Termination_or_Transfer__c = child.Parent_Ref_HRS_Termination_Transfer__r.Termination_or_Transfer__c,
                                Primary_Tier_1_Reasons__c = child.Parent_Ref_HRS_Termination_Transfer__r.Primary_Tier_1_Reasons__c,
                                Primary_Tier_2_Reasons__c = child.Parent_Ref_HRS_Termination_Transfer__r.Primary_Tier_2_Reasons__c,
                                Primary_Tier_3_Reasons__c = child.Parent_Ref_HRS_Termination_Transfer__r.Primary_Tier_3_Reasons__c,
                                Fiscal_Year__c = child.Parent_Ref_HRS_Termination_Transfer__r.Fiscal_Year__c,
                                Fiscal_Lost_Month__c = child.Parent_Ref_HRS_Termination_Transfer__r.Fiscal_Lost_Month__c
                                ); 
                recordsToUpdate.add(r); 
                }//for child
            }//if childRecords
        } //changedRecords not empty

        try{
            skipTrigger = true;
            update recordsToUpdate;
        }catch (Exception e){
            System.debug('No records were updated: ' + e.getMessage());
        }
    changedRecordIds.clear();
       
       if(!casesToUpdate.isEmpty()){
           DMLHelper.performDML(casesToUpdate, 'UPDATE', 'RefHRSTermTransferMethods', 'handle after', 'saving updated cases', true);
       }
   } //processAfterTriggerActions
}