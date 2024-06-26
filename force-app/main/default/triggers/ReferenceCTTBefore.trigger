/*
* Before Trigger for Reference CTT Records
* 
* 11/30/2020	Matt Fritschi	Created
  05/14/2021	Carrie Marciano	Added skip trigger check to prevent duplicate chatterposts (one from code and one was happening after workflow update)
  08/01/2022    Dan Carmen      Clean up code


*/

trigger ReferenceCTTBefore on Reference_CTT__c (before insert, before update, after insert, after update) {
    System.debug('ReferenceCTTHelper.SKIP_TRIGGER='+ReferenceCTTHelper.SKIP_TRIGGER+' isBefore='+Trigger.isBefore+' isAfter='+Trigger.isAfter);
    if (ReferenceCTTHelper.SKIP_TRIGGER) {
      return;
    }
    
    List<Id> opportunityIds = new List<Id>();
    List<Reference_CTT__c> refCTTUpdateAccount = new List<Reference_CTT__c>();
    List<Reference_CTT__c> postChatterMessage = new List<Reference_CTT__c>();
    List<Reference_CTT__c> postChatterMessage2 = new List<Reference_CTT__c>();
    Id[] onbToolIds = new Id[]{};
    
    List<String> chatterStatuses = Label.Reference_CTT_Status_for_Chatter.split(',');
    
    for (Reference_CTT__c newRefCTT : Trigger.new) {
        Reference_CTT__c oldRefCTT = (Trigger.isUpdate ? Trigger.oldMap.get(newRefCTT.id) : null);
        
            //See if we need to populate the Account on the Reference CTT from the Opportunity.
            if(Trigger.isBefore && newRefCTT.Opportunity__c != null ) {
                opportunityIds.add(newRefCTT.Opportunity__c);
                refCTTUpdateAccount.add(newRefCTT);
            }      
            
            if (Trigger.IsAfter && newRefCTT.Ready_to_be_Worked__c && (oldRefCTT == null || !oldRefCTT.Ready_to_be_Worked__c)) {
               postChatterMessage2.add(newRefCTT);
               onbToolIds.add(newRefCTT.Onboarding_Tool__c);
            } else if (Trigger.IsAfter && String.isNotBlank(newRefCTT.Status__c) && (oldRefCTT == null || newRefCTT.Status__c != oldRefCTT.Status__c)) {
               Boolean statusCanChatter=chatterStatuses.contains(newRefCTT.Status__c);
               System.debug('ReferenceCTTHelper statusCanChatter='+statusCanChatter);
               postChatterMessage.add(newRefCTT);
               onbToolIds.add(newRefCTT.Onboarding_Tool__c);
            }

    } // for newOT
    
    system.debug('ReferenceCTTBefore refCTTUpdateAccount='+refCTTUpdateAccount.size()+' postChatterMessage='+postChatterMessage.size());
    
    if(!refCTTUpdateAccount.isEmpty()) {
        ReferenceCTTHelper.updateProspectClient(refCTTUpdateAccount, opportunityIds);
    }
    
    if(!postChatterMessage.isEmpty()) {
        ReferenceCTTHelper.postChatters(postChatterMessage, onbToolIds);
    }
    if (!postChatterMessage2.isEmpty()) {
        OnboardingToolHelper.createChatterPosts(postChatterMessage2);
    }    
    
} // trigger ReferenceCTTBefore