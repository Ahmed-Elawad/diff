trigger AmpReferralTrigger on amp_dev__Amp_Referral__c (before insert, before update) {
    
    new AmplifinityHelper().triggerCheckAllFirst(trigger.New, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter);

}//AmpReferralTrigger