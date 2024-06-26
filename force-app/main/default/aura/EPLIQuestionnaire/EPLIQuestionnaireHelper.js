({
     validateFormFields: function(cmp, e, helpr) {
        let valid = true;
        let fields = cmp.find("EPLIRequiredField")
        //var reg = new RegExp('/^\d+$/');
        fields.forEach(function(fld) {
            if (fld.get('v.type') == 'number' && fld.get('v.value') && fld.get('v.value')!=''){
                let validVal = fld.get("v.validity");
                if (!validVal) {
                    fld.setCustomValidity("This response requires a number. Please enter a number");
                }
                /*let val = fld.get('v.value');
                console.log('field value:'+val);
                let validVal = reg.test(val);
                if (!validVal) {
                    fld.setCustomValidity("This response requires a number. Please enter a number");
                    valid = false;
                    console.log('fieldName invalid:'+fld.get('v.name'));
                }*/
            }
            fld.reportValidity();
        });
        return valid;
    },
    saveFormProgress : function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            try {
                let isCommUser = component.get('v.communityUser');
                console.log('component.get("v.answersChanged") = ' + component.get("v.answersChanged"));
                if(component.get("v.answersChanged") == true || component.get("v.policyPeriodChanged") == true || isCommUser)
                {
                    if (!helper.validateFormFields(component, event, helper)) return;
                    let user = component.get("v.user");
                    if(!component.get("v.agreementSigned")  && isCommUser){
                        console.log('No comm user')
                        helper.displayMsg('Failed to save', 'The aknowlegement is required for submission of any EPLI Questionnaire', 'warning');
                        component.set('v.PEOChecklist.Client_Id_user_agreement_acknowledgment__c','');
                        reject(false);
                    }
                    else if(component.get('v.communityUser') && component.get("v.agreementSigned")){
                        component.set('v.PEOChecklist.EPLI_Acknowledged_Date__c', new Date());
                    }
                    
                    var saveChecklist = component.get("c.savePeoOnboardingChecklist");
                    let peo = component.get("v.PEOChecklist");
                    peo.nature_of_business__c = peo.description_principle_product_business__c;
                    
                    helper.saveThroughAutoSave(component, event, helper)
                    .then(function(res) {
                        console.log('epliForm.saveFormProgress.recieve');
                        
                        if(isCommUser){
                            component.set('v.formSubmitted', true);
                        }
                        // should have save policy periods and chk
                        resolve(helper.setRecordsOnForms(component, event, helper, res));
                    })
                    .catch(function(err) {
                        console.log('epliForm.saveFormProgress.err');
                        console.log(err);
                        helper.displayMsg('Error', component.get('v.errMsg'), 'error');
                        reject(false);
                    })
                    
                    /*saveChecklist.setParams({
                        'peoOnbChecklist': peo,
                        formName: 'EPLIQuestionnaire.cmp'
                    });
                    saveChecklist.setCallback(this, function(data) {
                        
                        var state = data.getState();
                        if (state != 'SUCCESS' || !data.getReturnValue()) {
                            console.log('Server save err')
                            console.log(data.getError())
                            helper.displayMsg('Error', component.get('v.errMsg'), 'error');
                            reject(false);
                            return;
                        }
                        
                        if(isCommUser){
                            component.set('v.formSubmitted', true);
                        }
                        if(component.get("v.policyPeriodChanged") == true)
                        {
                            component.set("v.policyPeriodChanged", false);
                            var action = component.get("c.saveEPLIPolicyPeriods");
                            action.setParams({
                                newPolPeriods : component.get("v.PolicyPeriods"),
                                formName: 'EPLIQuestionnaire.cmp'
                            });
                            
                            action.setCallback(this, function(res) {
                                var responseState = res.getState();
                                if (responseState === "SUCCESS") {
                                    let data = res.getReturnValue();
                                    component.set("v.PolicyPeriods", data);
                                    helper.displayMsg('Success', 'Your progress has been saved!', 'success', null);
                                    component.set("v.answersChanged", false);
                                    resolve(true);
                                    return;
                                }
                                else
                                {
                                    console.log('Error');
                                    helper.displayMsg('Error', component.get('v.errMsg'), 'error');
                                    reject(false);
                                    return;
                                }
                            })
                            
                            $A.enqueueAction(action);
                            
                        }
                        else
                        {
                            helper.displayMsg('Success', 'Your progress has been saved!', 'success', null);
                            component.set("v.answersChanged", false);
                            resolve(true);
                        }
                    });
                    $A.enqueueAction(saveChecklist);*/
                }
                else{
                    //resolve(true);
                    console.log('epliForm.saveFormProgress.noChangesMadeErr')
                    helper.displayMsg('No Changes to save', 'Please make any changes for EPLI Questionnaire to be saved', 'warning');
                    reject(false);
                }
            }
            catch(err) {
                console.log('Catch err');
                console.log(err)
                helper.displayMsg('Error', component.get('v.errMsg'), 'error');
                reject(false);
            } 
        });
    },
    
    clearOutFields : function(component, event, helper) {
        if(component.get('v.PEOChecklist.has_150_or_more_emp_for_svc_agreement__c') != 'Yes' && component.get('v.PEOChecklist.has_three_or_more_employment_matters__c') != 'Yes' && component.get('v.PEOChecklist.has_any_emp_matter_exceeded_75k_inclusve__c') != 'Yes')
        {
            component.set('v.PEOChecklist.num_emp_matters_3_past_yrs_ignore_cost__c', "");
        }
        if(component.get('v.PEOChecklist.emp_matter_anticipated_connected_to_rif__c') != 'Yes'){
            component.set('v.PEOChecklist.prev_12_mnth_rif_exp_and_emp_count__c', "N/A");
            component.set('v.PEOChecklist.future_12_mnth_rif_exp_emp_count_nd_date__c', "N/A");
            component.set('v.PEOChecklist.desc_circ_potential_lead_to_matter__c', "N/A");
        }
        else{
            component.set('v.PEOChecklist.prev_12_mnth_rif_exp_and_emp_count__c', "");
            component.set('v.PEOChecklist.future_12_mnth_rif_exp_emp_count_nd_date__c', "");
            component.set('v.PEOChecklist.desc_circ_potential_lead_to_matter__c', "");
        }
        component.set("v.answersChanged", true);
        if(component.get("v.agreementSigned") == true){
            component.set("v.agreementSigned",false);
            helper.AKNUpdateAutoSave(component, event, helper, true);
            helper.displayMsg('Please Re-Acknowledge', 'Due to changes to the form(s), you must click the acknowledgement box again.', 'error', 10000);
            
        }
        this.sendSaveForAllFields(component, event, this);
    },
    
    verifyPolicyPeriods : function(component, event) {
        let verified = false;
        let missingFields = false;
        
        console.log('component.get("v.PolicyPeriods").length = ' + component.get("v.PolicyPeriods").length);
        if(component.get("v.PolicyPeriods").length == 1) {
            var polPeriod = component.get("v.PolicyPeriods")[0];
            console.log('polPeriod.Policy_Period__c = ' + polPeriod.Policy_Period__c);
            if(polPeriod.Policy_Period__c == 'N/A' || polPeriod.Policy_Period__c == 'n/a' || polPeriod.Policy_Period__c == 'NA') {
                verified = true;
                
                /*console.log('looping through fields...');
                component.find("policyPeriodField").forEach( function(itemcmp) {
                    console.log('itemcmp = ' + itemcmp);
                    if(itemcmp != 'undefined') { 
                        console.log('Setting Validity to be true.');
                        itemcmp.set("v.validity", true);
                    }
                })*/
                console.log('verified = ' + verified);
                return verified;
            }
        }
        
        component.find("policyPeriodField").forEach( function(itemcmp) {
            if(itemcmp != 'undefined') {
                //console.log('itemcmp.get("v.name") = ' + itemcmp.get("v.name"));
                if(!itemcmp.get("v.disabled")) {
                    itemcmp.reportValidity();
                    if(itemcmp.get("v.value") == null || itemcmp.get("v.value") == '' || itemcmp.get("v.value") == 'undefined') {
                        if(!missingFields) {
                            missingFields = true;
                        }
                    }
                    else {
                        console.log('itemcmp.get("v.value") = '+ itemcmp.get("v.value"));
                    }
                }
            }
            
        } );
        
        if(!missingFields) {
            verified = true;
        }
        
        return verified;
    },
    
    verifyEPLIFields : function(component, event) {
        var missingFieldList = '';
        component.find("EPLIRequiredField").forEach( function(itemcmp) {
            if(itemcmp != 'undefined') {
                //console.log('itemcmp.get("v.name") = ' + itemcmp.get("v.name"));
                if(!itemcmp.get("v.disabled") && itemcmp.get("v.required")) {
                    console.log('itemcmp.get("v.label")=' + itemcmp.get("v.label"));
                    if(itemcmp.get("v.name") == 'other_business_type_engagement__c') {
                        itemcmp.checkValidity();
                    }
                    else {
                        itemcmp.reportValidity();
                    }
                    
                    if(itemcmp.get("v.value") == null || itemcmp.get("v.value") == '' || itemcmp.get("v.value") == 'undefined') {
                        if(itemcmp.get("v.label") != null && itemcmp.get("v.label") != '' && itemcmp.get("v.label") != 'undefined') {
                            missingFieldList += '- ' + itemcmp.get("v.label") + '\n';
                        }
                        else {
                            missingFieldList += '- Matter 1\n';
                        }
                    }
                    else {
                        console.log('itemcmp.get("v.value") = '+ itemcmp.get("v.value"));
                    }
                }
            }
        });
        
        return missingFieldList;
    },
    
    saveAllPolicyPeriods : function(component, event) {
        if(component.get("v.policyPeriodChanged") == true)
        {
            let verified = false;
            
            if(component.get('v.communityUser')){
                verified = this.verifyPolicyPeriods(component, event);
                
                if(!verified) {
                    this.displayMsg('Failed to save', 'Policy Periods are missing information. Please enter N/A if none exists.', 'warning');
                    return;
                }
            }
            
            component.set("v.policyPeriodChanged", false);
            var action = component.get("c.saveEPLIPolicyPeriods");
            action.setParams({
                newPolPeriods : component.get("v.PolicyPeriods"),
                formName: 'EPLIQuestionnaire.cmp'
            });
            
            action.setCallback(this, function(res) {
                var state = res.getState();
                if (state === "SUCCESS") {
                    let data = res.getReturnValue();
                    component.set("v.PolicyPeriods", data);
                    this.displayMsg('Success', 'Your progress has been saved!', 'success', null);
                }
                else
                {
                    this.displayMsg('Error saving record', 'Record not saved. Please refresh the page and try again.\nIf the error persists reach out to your admin', 'error');           
                }
                
            })
            
            $A.enqueueAction(action);
        }
    },
    
    getPolPeriods : function(component, event) {
        let data = component.get('v.PEOChecklist');	
        if (component.get('v.user')) {
            let user = component.get('v.user');
            let prfName = user.Profile.Name;
            let isAnalyst = prfName == 'HRS Regional Sales Admin SB';
            let isNsc = prfName == 'HRS PEO Centric Sales - SB';
            let isDSM = prfName == 'HRS Sales Manager - SB';
            let isAdmin = prfName == 'System Administrator' || prfName == 'System Administrator - TAF';
            
            if (isAnalyst || isNsc || isDSM || isAdmin) {
                component.set('v.allowDiscLog', true);
            }
        }
        if (data !== null && data.Client_Id_user_agreement_acknowledgment__c) {
            console.log('inside if condition');
            component.set('v.agreementSigned', true);	
            component.set('v.aknSelected', true);	
        }	
        var action = component.get("c.getEPLIPolicyPeriods");
        console.log('Getting policy periods...');
        action.setParams({
            peoOnboardingChecklistId: component.get('v.PEOChecklist.Id'),
            formName: 'EPLIQuestionnaire.cmp'
        });
        
        action.setCallback(this, function(res) {
            console.log('In callback...');
            if (res.getState() !== 'SUCCESS') {
                console.log(res.getError());
                this.displayMsg('Error', 'Record not loaded. Will not save to account', 'error');
            }
            let data = res.getReturnValue();
            
            component.set("v.PolicyPeriods", data);
            
            console.log('component.get("v.PolicyPeriods").length = '+component.get("v.PolicyPeriods").length);
            
        })
        $A.enqueueAction(action);
    },
    setAkn: function(component, event, helper) {	
        // updates the flag that the user aknowleged the agreement	
        
        var epliFieldsMissing = '';
        var policyPeriodVerified = false;
        
        epliFieldsMissing = this.verifyEPLIFields(component, event);
        policyPeriodVerified = this.verifyPolicyPeriods(component, event);
        
        if(epliFieldsMissing == '' && policyPeriodVerified == true) { 
            
            let currSet = component.get('v.aknSelected');	
            let q = component.get('v.PEOChecklist');	
            q.Client_Id_user_agreement_acknowledgment__c = component.get('v.user').Id;	
            component.set('v.PEOChecklist', q);	
            component.set('v.aknSelected', !currSet);	
            component.set("v.answersChanged", true);
            helper.AKNUpdateAutoSave(component, event, helper, false);
        }
        else {
            if(!policyPeriodVerified) {
                epliFieldsMissing += '- Policy Period'
            }
            component.set("v.agreementSigned", false);
            this.displayMsg('Please complete all required fields:', epliFieldsMissing, 'error', 10000);
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
    triggerEvt: function(cmp, e) {
        try {
            let cmpEvent = cmp.getEvent("discrepancyEvt");
            cmpEvent.setParams({
                formName: cmp.get('v.formName'),
                checklistId: cmp.get('v.PEOChecklist').Id,
                type: 'EPLI Questionnaire'
            });
            cmpEvent.fire(); 
        } catch(e) {
            console.log('Err in evt fire')
            console.log(e);
        }
    },
    // gets the neccesary parameters for the field through the passed in change
    // event and sets those params on the auto save event.
    // Fires the event for a single field and logs message on fetal error
    // firing the event
    sendAutoSave: function(cmp, e, helper) {
        let field = e.getSource();
        let fieldName = field.get('v.name');
        let Account = cmp.get('v.parentAccount');
        let fieldAPIName, objectAPIName, fieldValue;
        if (fieldName) {
            let splitName =  fieldName.split('.');
            objectAPIName = splitName[0];
            fieldAPIName = splitName[1];
        }
        fieldValue = field.get('v.value');
        
        if (fieldValue && fieldValue.length) {
            try {
                let recordId =cmp.get('v.PEOChecklist.Id');
                let autoSaveEvt = cmp.getEvent('autoSave');
                console.log(`recordId before send: ${recordId}`);
                autoSaveEvt.setParam('objectName', objectAPIName);
                autoSaveEvt.setParam('accountId', Account.Id);
                autoSaveEvt.setParam('fieldName', fieldAPIName);
                autoSaveEvt.setParam('fieldValue', fieldValue);
                autoSaveEvt.setParam('recordId', recordId);
                autoSaveEvt.setParam('accountName', Account.Name);
                autoSaveEvt.fire();
            } catch(e) {
                console.log('err occured:')
                console.log(e);
            }
        }
        if(fieldAPIName == 'Client_Id_user_agreement_acknowledgment__c'  && fieldValue.length == 0){
            try {
                let recordId =cmp.get('v.PEOChecklist.Id');
                let autoSaveEvt = cmp.getEvent('autoSave');
                console.log(`recordId before send: ${recordId}`);
                autoSaveEvt.setParam('objectName', objectAPIName);
                autoSaveEvt.setParam('accountId', Account.Id);
                autoSaveEvt.setParam('fieldName', fieldAPIName);
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
    // helper method to handle calling the autoSave method adding the params
    // to save multiple fields at once
    // expects the record params object to be preconfigured to contain
    // objectAPIName, an object containing fieldAPI: fieldValue mapping, and
    // the record ID
    // {objApiName: 'PEO_Onboarding_Checklist__c', recordID: xxxxxxxxxxxxxxxxx, fields: {field1: 'xx', field2: ''}}
    sendMultiFieldUpdate: function(cmp, e, helper, recordParams) {
        let objectAPIName =recordParams.objectAPIName;
        let Account = cmp.get('v.parentAccount');
        let recordId = recordParams.recordId;
        let fields = recordParams.fields;
        // delete fields.Id;
        
        let multipleFieldsMap = {};
        
        multipleFieldsMap[objectAPIName] = {
            recordId:  recordId,
            fields: fields,
            accountName:  Account.Name
        }
        
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
    // sends a call to cancel all currently queued auto save regardless of
    // how long they've been in queue
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
    // gets all existing epli policy period entries and information entered
    // on the checklist and sends an auto save event with all values
    sendSaveForAllFields: function(cmp, e, helper) {
        
        // get the policy periods
        // get the questionnaire values
        try {
            let pol = cmp.get('v.PolicyPeriods');  // an array of records
            
            if (pol && pol.length) {
                for (let recordPosition in pol){
                    let policyRec = pol[recordPosition];
                    
                    let params = {
                        objectAPIName: 'Policy_Period__c',
                        recordId: policyRec.Id,
                        fields: policyRec
                    };
                    
                    helper.sendMultiFieldUpdate(cmp, e, helper, params);
                }
            }
            
            let checklist = cmp.get('v.PEOChecklist');
            if (checklist) {
                let params = {
                    objectAPIName: 'PEO_Onboarding_Checklist__c',
                    recordId: checklist.Id,
                    fields: checklist
                };
                helper.sendMultiFieldUpdate(cmp, e, helper, params);
            }
        } catch(e) {
            console.log(e);
        }
    },
    // build an event like object to populate the 
    // aknowlegemnt and send an autop save for its value
    // If the 'Clear' boolean is passed in as true the akn value
    // is cleared out, otherwise the current users ID is populated
    // for the field
    /*AKNUpdateAutoSave: function(cmp, e, helper, clear) {   
        let questionnaire = cmp.get('v.questionnaire');
        let usertAknId = clear ? '' : cmp.get('v.user').Id;
        let params = {
            getSource: function() {
                let obj =  {
                    'v.name': 'PEO_Onboarding_Checklist__c.Client_Id_user_agreement_acknowledgment__c',
                    'v.value': usertAknId,
                    get: function(p) {return this[p];}
                };
                return obj;
            }
        };
        helper.sendAutoSave(cmp, params, helper);
    },*/
    
    AKNUpdateAutoSave: function(cmp, e, helper, clear) {   
        if(cmp.get('v.agreementSigned')!= null){
            let PEOChecklist = cmp.get("v.PEOChecklist");
            let usertAknId;
            let ackTime;
            if(clear == true){
                cmp.set('v.agreementSigned', false);
                cmp.set('v.aknSelected',false);
                cmp.set('v.PEOChecklist.Client_Id_user_agreement_acknowledgment__c','');
                cmp.set('v.PEOChecklist.EPLI_Acknowledged_Date__c',null);
                usertAknId = '';
                ackTime = null;
            }
            else{
                cmp.set('v.agreementSigned', true);
                cmp.set('v.aknSelected',true);
                usertAknId = cmp.get('v.user').Id
                var prevStamp = cmp.get('v.PEOChecklist.EPLI_Acknowledged_Date__c')
                if(prevStamp){
                    ackTime = prevStamp;
                }
                else{
                    var todayDate = new Date();
                    ackTime = todayDate.toJSON();
                }
                
            }
            let lookupFieldEvent = {
                getSource: function() {
                    let obj =  {
                        'v.name': 'PEO_Onboarding_Checklist__c.Client_Id_user_agreement_acknowledgment__c',
                        'v.value': usertAknId,
                        get: function(p) {return this[p];}
                    };
                    return obj;
                }
            };
            helper.sendAutoSave(cmp, lookupFieldEvent, helper);
            let dateFieldEvent = {
                getSource: function() {
                    let obj =  {
                        'v.name': 'PEO_Onboarding_Checklist__c.EPLI_Acknowledged_Date__c',
                        'v.value': ackTime,
                        get: function(p) {return this[p];}
                    };
                    return obj;
                }
            };
            helper.sendAutoSave(cmp, dateFieldEvent, helper);
        }
        else{
            //console.log('agreementSigned'+cmp.get('v.agreementSigned'));
        }
    },
    
    setMatters: function(cmp, e, helper) {
        let q = cmp.get('v.PEOChecklist');
        if (q.Additional_Matters_Information__c && q.Additional_Matters_Information__c.length) cmp.set('v.numOfMatters', 6);
        else if (q.Matters_5__c && q.Matters_5__c.length) cmp.set('v.numOfMatters', 5);
        else if (q.Matters_4__c && q.Matters_4__c.length) cmp.set('v.numOfMatters', 4);
    },
    eraseMatter: function(cmp, e, helper) {
        let n = cmp.get('v.numOfMatters');
        let q = cmp.get('v.PEOChecklist');
        if (n === 6) q.Additional_Matters_Information__c = '';
        else {
            let matterAPI = `Matters_${n}__c`;
            console.log(matterAPI)
            q[matterAPI] = '';
        }
        cmp.set('v.PEOChecklist', q);
        cmp.set('v.numOfMatters', n - 1);
    },
    saveProgress : function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            let todayDate = new Date();
            let isCommUser = component.get('v.communityUser');
            console.log('Initing save: ' +isCommUser )
            if(isCommUser){
                component.set('v.PEOChecklist.Peo_EPLI_formStatus__c','Complete');
                component.set('v.PEOChecklist.Peo_EPLI_SubmissionTime__c', todayDate.toJSON());
            }
            helper.saveFormProgress(component, event, helper)
            .then(() => resolve(true))
            .catch(() => reject(false));
        });
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