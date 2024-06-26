({
    saveProgress : function(component, event, helper) {
        helper.saveProgress(component, event, helper);
    },
    
    clearFields : function(component, event, helper) {
        helper.sendAutoSave(component, event, helper);
        helper.clearOutFields(component, event, helper);
    },
    
    handleChange : function(component, event, helper) {
        let relatedFieldList = component.get('v.relatedFieldList');
        let field = event.getSource();
        let fieldName = field.get('v.name');
        let fieldAPIName, objectAPIName, fieldValue,fedIdField;
        fieldValue = field.get('v.value');
        let matterField = (fieldName == 'PEO_Onboarding_Checklist__c.matter_1__c'  ||
                           fieldName == 'PEO_Onboarding_Checklist__c.Matters_2__c' ||
                           fieldName == 'PEO_Onboarding_Checklist__c.Matters_3__c' ||
                           fieldName == 'PEO_Onboarding_Checklist__c.Matters_4__c' || 
                           fieldName == 'PEO_Onboarding_Checklist__c.Matters_5__c'
                          );
        let matterFedField = (fieldName == 'PEO_Onboarding_Checklist__c.Matter1_Fed_id__c'  ||
						  fieldName == 'PEO_Onboarding_Checklist__c.Matter2_Fed_id__c' ||
						  fieldName == 'PEO_Onboarding_Checklist__c.Matter3_Fed_id__c' ||
						  fieldName == 'PEO_Onboarding_Checklist__c.Matter4_Fed_id__c' || 
						  fieldName == 'PEO_Onboarding_Checklist__c.Matter5_Fed_id__c'
						 );	
        if(matterField){
            if(fieldName == 'PEO_Onboarding_Checklist__c.matter_1__c' && fieldValue.length ==0){
                fedIdField = 'Matter1_Fed_id__c';
                component.set('v.PEOChecklist.'+fedIdField,'');
            }else if(fieldName == 'PEO_Onboarding_Checklist__c.Matters_2__c'  && fieldValue.length ==0){
                fedIdField = 'Matter2_Fed_id__c';
                component.set('v.PEOChecklist.'+fedIdField,'');
            }else if(fieldName ==  'PEO_Onboarding_Checklist__c.Matters_3__c'  && fieldValue.length ==0){
                fedIdField = 'Matter3_Fed_id__c';
                component.set('v.PEOChecklist.'+fedIdField,'');
            }else if(fieldName ==  'PEO_Onboarding_Checklist__c.Matters_4__c'  && fieldValue.length ==0){
                fedIdField = 'Matter4_Fed_id__c';
                component.set('v.PEOChecklist.'+fedIdField,'');
            }else if(fieldName ==  'PEO_Onboarding_Checklist__c.Matters_5__c'  && fieldValue.length ==0){
                fedIdField = 'Matter5_Fed_id__c';
                component.set('v.PEOChecklist.'+fedIdField,'');
            }
            
            relatedFieldList.push(fieldName.split('PEO_Onboarding_Checklist__c.')[1],fedIdField);
            helper.relatedFieldChanges(component, event, helper,'PEO_Onboarding_Checklist__c',relatedFieldList); 
        }
        if(matterFedField ){
            let matterFedFieldValue = ''+fieldValue;
            if(matterFedFieldValue.length== 0){
                relatedFieldList.push(fieldName.split('PEO_Onboarding_Checklist__c.')[1]);
                console.log('relatedFieldList:'+relatedFieldList);
                helper.relatedFieldChanges(component, event, helper,'PEO_Onboarding_Checklist__c',relatedFieldList); 
            }
            
        }
        if(component.get("v.answersChanged") == false)
        {
            component.set("v.answersChanged", true);
        }
        
        if(component.get("v.agreementSigned") == true){
            component.set("v.agreementSigned",false);
            helper.displayMsg('Please Re-Acknowledge', 'Due to changes to the form(s), you must click the acknowledgement box again.', 'error', 10000);
            helper.AKNUpdateAutoSave(component, event, helper, true);
        }
        helper.sendAutoSave(component, event, helper);
    },
    
    handlePolicyPeriodChange : function(component, event, helper) {
        if(component.get("v.policyPeriodChanged") == false)
        {
            component.set("v.policyPeriodChanged", true);
            console.log("setting  policyPeriodChanged to true");
        }
        if(component.get("v.agreementSigned") == true){
            component.set("v.agreementSigned",false);
        }
        helper.sendSaveForAllFields(component, event, helper);
    },
    
    getPolicyPeriods : function(component, event, helper) {
        let isCommUser = component.get('v.communityUser');
        if (isCommUser) component.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, visit the Need Help section on our homepage, so we can promptly address the issue.');
        else component.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.')
        
        component.set('v.saveFunc' , $A.getCallback(() => helper.saveProgress(component, event, helper)));
        
        var submissionStatus = component.get('v.PEOChecklist.Peo_EPLI_formStatus__c');
        if(submissionStatus === 'Complete'){
            component.set('v.formSubmitted', true);
        }
        helper.getPolPeriods(component, event);
        helper.setMatters(component, event, helper);
    },
    
    addPolicyPeriod : function(component, event, helper) {
        var addRec = {'sobjectType' : 'Policy_Period__c','PEO_Onboarding_Checklist__c' : component.get("v.PEOChecklist.Id")};
        var existingRecords = component.get("v.PolicyPeriods");
        existingRecords.push(addRec);
        component.set("v.PolicyPeriods", existingRecords);
        component.set("v.policyPeriodChanged", true);
    },
    
    removeRow : function(component, event, helper) {
        
        var indexPosition = event.target.name;
        var existingRecords = component.get("v.PolicyPeriods");
        console.log("indexPosition",indexPosition);
        existingRecords.splice(indexPosition, 1);
        component.set("v.PolicyPeriods", existingRecords);
        component.set("v.policyPeriodChanged", true);
    },
    
    savePolicyPeriods : function(component, event, helper) {
        helper.saveAllPolicyPeriods(component, event);
        
    },
     handleAkn: function(component, event, helper) {
    	helper.setAkn(component, event, helper);
	},
     openTab: function(cmp, e, helper) {
        helper.triggerEvt(cmp, e);
    },
    handleMatterUpdate: function(cmp, e, helper) {
        let buttonName = e.getSource().get('v.name');
		cmp.set("v.answersChanged", true);
        if (buttonName =='AddMatter' ) cmp.set('v.numOfMatters', cmp.get('v.numOfMatters') + 1);
        else {
            helper.eraseMatter(cmp, e, helper);
        }
    },
    showRemainingAccts: function(cmp, e, helper) {
        cmp.set('v.showRemainingAccounts', !cmp.get('v.showRemainingAccounts'));
        cmp.set('v.allAcctsVisible', cmp.get('v.showRemainingAccounts'));
    }
})