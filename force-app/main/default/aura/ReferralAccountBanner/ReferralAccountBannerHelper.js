({
    getReferralAccountWrapper: function(component, event, helper) {
        var action = component.get("c.getReferralAccountWrapperById");
        var referralAccountId = component.get("v.referralAccountId");
        action.setParams({
            referralAccountId: referralAccountId
        });
        console.log('referralAccountId' + referralAccountId); 
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state === 'SUCCESS') {
                var referralAccountWrapper = response.getReturnValue();
		        console.log('referralAccountWrapper' + referralAccountWrapper); 
                console.log('referralAccountWrapper Jaipal' + referralAccountWrapper.ReferralAccount.Referral_Source_Business_Type__c); 
                console.log('referralAccountWrapper Pratik-- ' + referralAccountWrapper.ReferralAccount.Referral_Payment_Program_Name__c); 
                component.set("v.referralAccountWrapper", referralAccountWrapper);
                component.set("v.sensitivityList", referralAccountWrapper.getSensitivities);
                helper.checkForSensitiveReferralContacts(component, referralAccountWrapper.RelatedReferralContacts);
                helper.populateEngagedDetails(component, referralAccountWrapper);
                
            } else {
                console.error(response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    checkForSensitiveReferralContacts: function(component, referralContacts) {
        var sensitiveReferralContacts = referralContacts.find(function(referralContact) {
            return !!referralContact.Sensitivity_List__c;
        });

        if (sensitiveReferralContacts) {
            component.set("v.hasSensitiveReferralContacts", true);
            
            
        }
    },

    populateEngagedDetails: function(component, referralAccountWrapper) {
        var engagedTextList = [];
        if(referralAccountWrapper.ReferralAccount.CPA_Relationship_Manager__c) {
            engagedTextList.push("ABDM Engaged");
        }
        if(referralAccountWrapper.ReferralAccount.Bank_Centric_Rep__c) {
            engagedTextList.push("Bank Centric Rep");
        }
        if(referralAccountWrapper.ReferralAccount.Dedicated_Rep__c) {
            engagedTextList.push("Dedicated Rep");
        }

        // loop through referralAccountWrapper.RelatedReferralContacts
            // if the contact has ARM_owner__c || CAS_Engaged__c || Independent_Agent_Relationship_Manager__c
            // add corresponding text to the list
        var filteredEngagedContacts = referralAccountWrapper.RelatedReferralContacts.filter(function(relatedContact) {
            return relatedContact.ARM_owner__c || relatedContact.CAS_Engaged__c || relatedContact.Independent_Agent_Relationship_Manager__c || relatedContact.CPA_Relationship_Manager__c;
        });

        if (filteredEngagedContacts.find(contact => contact.ARM_owner__c)) {
            engagedTextList.push("ARM Engaged");
        }
        if (filteredEngagedContacts.find(contact => contact.CAS_Engaged__c)) {
            engagedTextList.push("CAS Engaged");
        }
        if (filteredEngagedContacts.find(contact => contact.Independent_Agent_Relationship_Manager__c)) {
            engagedTextList.push("IA Relationship Manager");
        }
        if (filteredEngagedContacts.find(contact => contact.CPA_Relationship_Manager__c)) {
            engagedTextList.push("ABDM Engaged");
        }

        var uniqueTextList = [...new Set(engagedTextList)];
        component.set("v.engagementTextDisplayList", uniqueTextList);
    },
    checkAccessPerm : function(component, event, helper){
        var action2 = component.get("c.hasCustomPermission");
        action2.setCallback(this, function(response){
            console.log('hasPermission in ref Account'+response.getReturnValue());
            component.set("v.hasPermission", response.getReturnValue())
        });
        $A.enqueueAction(action2);
    }
})