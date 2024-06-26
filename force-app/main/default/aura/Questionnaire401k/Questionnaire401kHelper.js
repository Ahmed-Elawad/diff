({ 
    clearOutFields : function(component, event) {
        if(component.get('v.PEOChecklist.Does_company_offer_a_retirement_plan__c') != 'No')
        {
            component.set('v.PEOChecklist.no_retierment_plan_explanation__c', "");
        }
        
        if(component.get('v.PEOChecklist.Does_company_offer_a_retirement_plan__c') != 'Yes')
        {
            component.set('v.PEOChecklist.Who_is_your_retirement_plan_provider__c', "");
            component.set('v.PEOChecklist.retirment_plan_kind__c', "");
            component.set('v.PEOChecklist.total_asset_size_of_retierment_plan__c', "");
            component.set('v.PEOChecklist.peo_plan_utilized_if_peo_previously_used__c', "");
            component.set('v.PEOChecklist.request_for_changes_to_peo_plan_used__c', "");
        }
        if(component.get('v.PEOChecklist.Has_current_dental_carrier__c') != 'Yes')
        {
            component.set('v.PEOChecklist.Who_is_your_Current_Dental_Carrier__c', "");
        }
        if(component.get('v.PEOChecklist.Has_current_dental_carrier__c') == 'Yes')
        {
            component.set('v.PEOChecklist.Interested_in_dental__c', "");
        }
        if(component.get('v.PEOChecklist.has_current_Vision_Carrier__c') != 'Yes')
        {
            component.set('v.PEOChecklist.Who_is_your_Current_Vision_Carrier__c', "");
        }
        if(component.get('v.PEOChecklist.has_current_Vision_Carrier__c') == 'Yes')
        {
            component.set('v.PEOChecklist.interested_in_Vision__c', "");
        }
        component.set("v.answersChanged", true);
    },
    
    
    saveFormProgress : function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            let iscommUser = component.get('v.user').Profile.Name == 'Customer Community Login User Clone';
            try {
                if(component.get("v.answersChanged") == true || iscommUser){
                    var saveChecklist = component.get("c.savePeoOnboardingChecklist");
                    /*saveChecklist.setParams({
                        'peoOnbChecklist': component.get("v.PEOChecklist"),
                        formName: 'questionnaire401k.cmp'
                    });
                    console.log(component.get("v.PEOChecklist"))
                    saveChecklist.setCallback(this, function(data) {
                        var state = data.getState();
                        if (state != 'SUCCESS' || !data.getReturnValue()) {
                            component.set('v.PEOChecklist.Peo_401k_formStatus__c','');
                            component.set('v.formSubmitted', false);
                            helper.displayMsg('Error', component.get('v.errMsg'), 'error');
                            reject(false);
                        }
                        component.set("v.answersChanged", false);
                        helper.displayMsg('Success', 'Your progress has been saved!', 'success', null);
                        if(iscommUser){
                            component.set('v.formSubmitted', true);
                        }
                        resolve(true);
                    });
                    $A.enqueueAction(saveChecklist);*/
                    helper.saveThroughAutoSave(component, event, helper)
                    .then(function(res) {
                        component.set("v.answersChanged", false);
                        helper.displayMsg('Success', 'Your progress has been saved!', 'success', null);
                        if(iscommUser){
                            component.set('v.formSubmitted', true);
                        }
                        resolve(true);
                    })
                    .catch(function(err) {
                        console.log('401kQuestionnaire.saveFormProgress.err');
                        console.log(err);
                        component.set('v.PEOChecklist.Peo_401k_formStatus__c','');
                        component.set('v.formSubmitted', false);
                        helper.displayMsg('Error', component.get('v.errMsg'), 'error');
                        reject(false);
                    })
                }
            } catch(err) {
                helper.displayMsg('Error', component.get('v.errMsg'), 'error');
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
                type: 'PEO Information Sheet'
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
    },
    saveProgress : function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            let iscommUser = component.get('v.user').Profile.Name == 'Customer Community Login User Clone';
            let todayDate = new Date();
            if(iscommUser){
                component.set('v.PEOChecklist.Peo_401k_formStatus__c','Complete');
                component.set('v.PEOChecklist.Peo_401k_SubmissionTime__c', todayDate.toJSON());
            }
            //helper.cancelAutoSaveEvents(component, event, helper);
            helper.saveFormProgress(component, event, helper)
            .then(() => resolve(true))
            .catch(() => reject(false));
        })        
    },
    
    saveThroughAutoSave: function(cmp, e, helper) {
        return new Promise(function(resolve, reject) {
            try {
                console.log('saveThroughAutoSave.send')
                let autoSaveEvt = cmp.get('v.saveAction');
                
                autoSaveEvt(cmp, e, helper, true)
                .then(function(result) {
                    console.log('saveThroughAutoSave.recieve');
                    resolve(result);
                })
                .catch(function(err) {
                    console.log('err:' + err);
                })
            } catch(e) {
                console.log('saveThroughAutoSave err');
                console.log(e);
            }  
        })
    },
    setRecordsOnForms: function(cmp, e, helper, records) {
        let recIds = {};
        if (cmp.get('v.PEOChecklist') !== null) recIds.PEO_Onboarding_Checklist__c = cmp.get('v.PEOChecklist').Id; 
        for (let soObjectName in records) {
            let sObjectList = records[soObjectName];
            let failedList = sObjectList !== null ? sObjectList.Fail : [];
            let successList = sObjectList !== null ? sObjectList.Success : [];
            successList.forEach(function(rec) {
                // if (rec.Id == recIds.PEO_Onboarding_Checklist__c) cmp.set('v.PEOChecklist', rec);
            })
        }
        return true;
    }
})