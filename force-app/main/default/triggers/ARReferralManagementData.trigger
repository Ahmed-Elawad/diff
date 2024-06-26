/*  
   
  History
  -------
  09/04/2019 Carie Marciano created to move data received into AR Referral Management Data into Payx Referral and AMP Referral 

 */

trigger ARReferralManagementData on AR_Referral_Management_Data__c (before insert, after insert) {
    // do we skip this trigger?
    System.debug('ARReferralManagementData ARReferralManagementDataMethods.SKIP_TRIGGER='+ARReferralManagementDataMethods.SKIP_TRIGGER);
    if (ARReferralManagementDataMethods.SKIP_TRIGGER) {
       return;
    }
    if (Trigger.isBefore) {
        for (AR_Referral_Management_Data__c newARupdate : Trigger.new)  {
    		ARReferralManagementDataMethods.checkTriggerBeforeActions(newARupdate);
    	}
    }
    if (Trigger.isAfter) {
    	ARReferralManagementDataMethods.processARUpdates();
        
    }    	
     
}