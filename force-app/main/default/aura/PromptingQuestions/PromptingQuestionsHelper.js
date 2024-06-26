({
    clearOutFields : function(component, event) {
        if(component.get('v.PEOChecklist.Current_Medical_Coverage_Provided__c') != 'Yes')
        {
            component.set('v.PEOChecklist.medical_coverage_carrier__c', "");
            component.set('v.PEOChecklist.medical_coverage_renewal_date__c', "");
            component.set('v.PEOChecklist.Cobra_Participants__c', "");
            component.set('v.PEOChecklist.Number_of_Enrolled_Employees__c', "");
            component.set('v.PEOChecklist.Has_Self_or_Level_Funded_Plan__c', "");
        }
        component.set("v.answersChanged", true);
    },
    
    saveFormProgress : function(component, event) {
        try {
            console.log('component.get("v.answersChanged") = ' + component.get("v.answersChanged"));
            if(component.get("v.answersChanged") == true)
            {
                var saveChecklist = component.get("c.savePeoOnboardingChecklist");
                saveChecklist.setParams({
                    'peoOnbChecklist': component.get("v.PEOChecklist")
                });
                saveChecklist.setCallback(this, function(data) {
                    var state = data.getState();
            		if (state === "SUCCESS") {
                		component.set("v.answersChanged", false);
                        this.displayMsg('Success saving', 'Your progress has been saved', 'success', null);
            		}
                    else
                    {
                        this.displayMsg('Error saving record', 'Record not saved. Please refresh the page and try again.\nIf the error persists reach out to your admin', 'error');
                    }
                });
                $A.enqueueAction(saveChecklist);
            }
        }
        catch(err) {
            this.displayMsg('Error saving record', 'Record not saved. Please refresh the page and try again.\nIf the error persists reach out to your admin', 'error');
        }
    },
    
    displayMsg: function(title, msg, type, duration) {    
		var toastEvent = $A.get("e.force:showToast");
    	toastEvent.setParams({
        	title: title,
            message: msg,
			type: type
    	});
    	toastEvent.fire();
	}, // displays a toast message for the user
    
    answersHaveChanged: function(component, event) {    
		console.log('CHANGING');
        if(component.get("v.answersChanged") == false)
        {
            component.set("v.answersChanged", true);
            console.log("setting  answersChanged to true");
        }
	}, 
    
    setMedicalQuestionnaireRenDate: function(component, event) {    
        if(component.get("v.medQuestionnaire") != null && component.get("v.medQuestionnaire") != 'undefined')
        {
            if(component.get("v.medQuestionnaire.Renewal_date__c") == null || component.get("v.medQuestionnaire.Renewal_date__c") == 'undefined' || component.get("v.medQuestionnaire.Renewal_date__c") == "")
            {
                console.log('setting med questionnaire renewal date');
                component.set("v.medQuestionnaire.Renewal_date__c", component.get("v.PEOChecklist.medical_coverage_renewal_date__c"));
                console.log('component.get("v.medQuestionnaire.Renewal_date__c") = ' + component.get("v.medQuestionnaire.Renewal_date__c"));
            }
        }
	},
    
    checkValidDate : function(component, event) {
    	var rencmp = component.find("renDate");
        rencmp.setCustomValidity('') ;
    	var chckvalididty = rencmp.get("v.validity");
    	console.log(chckvalididty.valid); // it gives false when 1st enter wrong format then i changed to correct format still shows
    	if(!chckvalididty.valid){
        	rencmp.setCustomValidity('format must be mm/dd/yyyy');
            component.set("v.PEOChecklist.medical_coverage_renewal_date__c", "");
    	}
        else{
            console.log("In Else");
        	rencmp.setCustomValidity('');
            this.setMedicalQuestionnaireRenDate(component, event);
    	}
    	rencmp.reportValidity();
        this.answersHaveChanged(component, event);
	},
    
    /*
	saveAndNext : function(component, event) {
        if(component.get("v.answersChanged") == true)
        {
            component.find("promptingQuestionsForm").submit();
        }
		
        var step = component.get("v.childStep");
        step = step + 1;
        component.set("v.childStep", step);
	},
    
    saveProgress : function(component, event) {
        if(component.get("v.answersChanged") == true)
        {
            component.find("promptingQuestionsForm").submit();
        	alert("Your progress has been saved!");
        }
	},
    /*
    decreaseStep : function(component, event) {
        if(component.get("v.answersChanged") == true)
        {
            component.find("promptingQuestionsForm").submit();
        }
        var step = component.get("v.childStep");
        step = step - 1;
        component.set("v.childStep", step);
        console.log("v.childStep = "+step);
    },
    
    clearOutFields : function(component, event) {
        if(component.get('v.PEOChecklist.Current_Medical_Coverage_Provided__c') != 'Yes')
        {
            component.set('v.PEOChecklist.medical_coverage_carrier__c', "");
            component.set('v.PEOChecklist.medical_coverage_renewal_date__c', "");
            component.set('v.PEOChecklist.Cobra_Participants__c', "");
        }
        component.set("v.answersChanged", true);
    },
    */
})