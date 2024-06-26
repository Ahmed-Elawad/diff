({
    clearOutFields : function(component, event) {
        let fieldsToUpdate = {};
        let sendUpdate;
        let fieldName = event.getSource().get('v.name');
        if(component.get('v.PEOChecklist.Have_employees_tested_pos_for_COVID_19__c') != 'Yes')
        {
            component.set('v.PEOChecklist.How_many_employees_had_positive_tests__c', "");
            component.set('v.PEOChecklist.When_did_the_employes_test_positive__c', "");
            component.set('v.PEOChecklist.any_employee_deaths_as_a_result_of_covid__c', "");
            component.set('v.PEOChecklist.space_clean_sani_protocol_for_pos_covid__c', "");
            component.set('v.PEOChecklist.process_for_employees_return_to_work__c', "");
            if (fieldName == 'Have_employees_tested_pos_for_COVID_19__c') {
                sendUpdate = true;
                fieldsToUpdate.Have_employees_tested_pos_for_COVID_19__c = 'No';
                fieldsToUpdate.How_many_employees_had_positive_tests__c = '';
                fieldsToUpdate.When_did_the_employes_test_positive__c = '';
                fieldsToUpdate.any_employee_deaths_as_a_result_of_covid__c = '';
                fieldsToUpdate.space_clean_sani_protocol_for_pos_covid__c = '';
                fieldsToUpdate.process_for_employees_return_to_work__c = '';
            } 
        }
        
        if(component.get('v.PEOChecklist.complience_to_org_cov_midigation_guids__c') != 'Yes')
        {
            component.set('v.PEOChecklist.Provide_the_PPE_being_used__c', "");
            component.set('v.PEOChecklist.engineering_controls_to_min_emp_contact__c', "");
            component.set('v.PEOChecklist.clean_and_disinfect_procedures_in_place__c', "");
            if (fieldName == 'complience_to_org_cov_midigation_guids__c') {
                sendUpdate = true;
                fieldsToUpdate.complience_to_org_cov_midigation_guids__c = 'No';
                fieldsToUpdate.clean_and_disinfect_procedures_in_place__c = '';
                fieldsToUpdate.engineering_controls_to_min_emp_contact__c = '';
                fieldsToUpdate.Provide_the_PPE_being_used__c = '';
            }
        }
        
        if(component.get('v.PEOChecklist.is_vacciine_available_for_staff__c') != 'Yes')
        {
            component.set('v.PEOChecklist.Has_any_of_the_staff_received_vaccine__c', "");
            if (fieldName == 'is_vacciine_available_for_staff__c') {
                sendUpdate = true;
                fieldsToUpdate.is_vacciine_available_for_staff__c = 'No';
                fieldsToUpdate.Has_any_of_the_staff_received_vaccine__c = '';
            }
        }
        
        if(component.get('v.PEOChecklist.employees_enter_hospitals_for_work__c') != 'Yes')
        {
            component.set('v.PEOChecklist.occurance_of_employee_entering_hospitals__c', "");
            component.set('v.PEOChecklist.emp_additional_precautions_in_hosp__c', "");
            if (fieldName == 'complience_to_org_cov_midigation_guids__c') {
                sendUpdate = true;
                fieldsToUpdate.employees_enter_hospitals_for_work__c = 'No';
                fieldsToUpdate.occurance_of_employee_entering_hospitals__c = '';
                fieldsToUpdate.emp_additional_precautions_in_hosp__c = '';
            }
        }
        
        component.set("v.answersChanged", true);
       	if (sendUpdate) this.sendMultiFieldUpdate(component, event, this, fieldsToUpdate);
        
    },
    
    saveProgress : function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            let todayDate = new Date();
            let isCommUser = component.get('v.user').Profile.Name == 'Customer Community Login User Clone';
            console.log(component.get('v.user'))
            console.log(isCommUser)
            if(isCommUser){
                component.set('v.PEOChecklist.Peo_Covid_formStatus__c','Complete');
                component.set('v.PEOChecklist.Peo_Covid_formSubmissionTime__c', todayDate.toJSON());
            }
            helper.cancelAutoSaveEvents(component, event, helper);
            helper.saveFormProgress(component, event,helper)
            .then(res => resolve(true))
            .catch(res => reject(false));
        });
    },
    saveFormProgress : function(component, event,helper) {
        return new Promise(function(resolve, reject) {
            let isCommUser = component.get('v.user').Profile.Name == 'Customer Community Login User Clone';
            helper.cancelAutoSaveEvents(component, event, this);
            try {
                var buttonLabel = component.get("v.buttonLabel");
                console.log('component.get("v.answersChanged") = ' + component.get("v.answersChanged"));
                if(component.get("v.answersChanged") == true)
                {
                    var saveChecklist = component.get("c.savePeoOnboardingChecklist");
                    saveChecklist.setParams({
                        'peoOnbChecklist': component.get("v.PEOChecklist"),
                        formName: 'CovidQuestionnaire.cmp'
                    });
                    saveChecklist.setCallback(this, function(data) {
                        var state = data.getState();
                        if (state != 'SUCCESS' || !data.getReturnValue()) {
                            console.log(data.getError());
                            component.set('v.PEOChecklist.Peo_Covid_formStatus__c','');
                            component.set('v.formSubmitted', false);
                            this.displayMsg('Error saving record', component.get('v.errMsg'), 'error');
                            reject(false);
                        }
                        console.log('done saving')
                        component.set("v.answersChanged", false);
                        console.log('after')
                        helper.displayMsg('Success', 'Your progress has been saved!', 'success', null);
                        console.log('after 2')
                        console.log(isCommUser)
                        if(isCommUser){
                            console.log('comm user')
                            component.set('v.formSubmitted', true);
                        }
                        console.log('resolveing')
                        resolve(true);
                    });
                    $A.enqueueAction(saveChecklist);
                } else {
                    resolve(true);
                }
            }
            catch(err) {
                this.displayMsg('Error saving record', component.get('v.errMsg'), 'error');
                reject(false);
            } 
        });
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
    triggerEvt: function(cmp, e) {
        try {
             let cmpEvent = cmp.getEvent("discrepancyEvt");
            cmpEvent.setParams({
                formName: cmp.get('v.formName'),
                checklistId: cmp.get('v.PEOChecklist').Id,
                type: 'Covid Questionnaire'
            });
            cmpEvent.fire(); 
        } catch(e) {
            console.log('Err in evt fire')
            console.log(e);
        }
    },
    sendAutoSave: function(cmp, e, helper) {
        let field = e.getSource();
        let fieldName = field.get('v.name');
        let objectAPIName = 'PEO_Onboarding_Checklist__c';
        let Account = cmp.get('v.account');
        let fieldValue = field.get('v.value');
        console.log(fieldName)
        if (fieldValue && fieldValue.length) {
            try {
                let recordId = cmp.get('v.PEOChecklist.Id');
                
                let autoSaveEvt = cmp.getEvent('autoSave');
                autoSaveEvt.setParam('objectName', objectAPIName);
                autoSaveEvt.setParam('accountId', Account.Id);
                autoSaveEvt.setParam('fieldName', fieldName);
                autoSaveEvt.setParam('fieldValue', fieldValue);
                autoSaveEvt.setParam('recordId', recordId);
                autoSaveEvt.setParam('accountName', Account.Name);
                autoSaveEvt.fire();
            } catch(e) {
                console.log('err occured:')
                console.log(e);
            }
        }
    },
    sendMultiFieldUpdate: function(cmp, e, helper, fields) {
        let objectAPIName = 'PEO_Onboarding_Checklist__c';
        let Account = cmp.get('v.account');
        let recordId = cmp.get('v.PEOChecklist.Id');
        let multipleFieldsMap = {
            PEO_Onboarding_Checklist__c: {
                recordId:  recordId,
                fields: fields,
                accountName:  Account.Name
            }
        };
        try {
            let autoSaveEvt = cmp.getEvent('autoSave');
            autoSaveEvt.setParam('objectName', objectAPIName);
            autoSaveEvt.setParam('objectToFieldsMap', multipleFieldsMap);
            autoSaveEvt.fire();
        } catch(e) {
            console.log('err occured:')
            console.log(e);
        }
        
    },
    cancelAutoSaveEvents: function(cmp,e, helper) {
        try {
            let autoSaveEvt = cmp.getEvent('autoSave');
            autoSaveEvt.setParam('cancelAll', true);
            autoSaveEvt.fire();
        } catch(e) {
            console.log('err occured:')
            console.log(e);
        }
    }
})