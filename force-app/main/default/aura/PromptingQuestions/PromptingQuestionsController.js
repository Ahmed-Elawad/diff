({
    saveProgress : function(component, event, helper) {
        helper.saveFormProgress(component, event);
    },
    
    clearFields : function(component, event, helper) {
        console.log("Clearing fields...");
        helper.clearOutFields(component, event);
    },
    
    handleChange : function(component, event, helper) {
        helper.answersHaveChanged(component, event);
    },
    
    handleRenDateChanged : function(component, event, helper) {
        helper.checkValidDate(component, event);
    },
    /*
    doInit : function(component, event, helper){  
       console.log("component.get('v.PEOChecklist.Current_Medical_Coverage_Provided__c') = "+component.get('v.PEOChecklist.Current_Medical_Coverage_Provided__c'));
        console.log("component.get('v.PEOChecklist.medical_coverage_carrier__c') = "+component.get('v.PEOChecklist.medical_coverage_carrier__c'));
        console.log("component.get('v.PEOChecklist.medical_coverage_renewal_date__c') = "+component.get('v.PEOChecklist.medical_coverage_renewal_date__c'));
    },
    /*
	saveAndNext : function(component, event, helper) {
        helper.validateFields(component, event);
		helper.saveAndNext(component, event);
	},
    
    submitSuccessful : function(component, event, helper) {
		console.log("Submit Successful!");
	},
    
    saveProgress : function(component, event, helper) {
		console.log("Saving Progress...");
        helper.saveProgress(component, event);
	},
    /*
    stepBackward : function(component, event, helper) {
        helper.decreaseStep(component, event);
    },
    
    clearFields : function(component, event, helper) {
		console.log("Clearing fields...");
        helper.clearOutFields(component, event);
        var a = component.get('c.saveForm');
        $A.enqueueAction(a);
	},
    
    handleChange : function(component, event, helper) {
		component.set("v.answersChanged", true);
        console.log("setting  answersChanged to true");
	},
    
    saveForm : function(component, event, helper) {
        console.log("saving PromptingQuestions Form...");
        console.log('component.get("v.answersChanged") = '+component.get("v.answersChanged"));
        if(component.get("v.answersChanged") == true)
        {
            component.find("promptingQuestionsForm").submit();
            component.set("v.answersChanged", false);
        }
	},
    */
})