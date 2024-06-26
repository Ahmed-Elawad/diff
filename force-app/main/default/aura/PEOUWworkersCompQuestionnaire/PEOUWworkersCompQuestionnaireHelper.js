({
    getFieldInfoForAcc: function(cmp, e) {
        // add a delay if info isn't loaded
        let data = cmp.get('v.PEOChecklist');
        for (let fld in data) {
            if (data[fld] === 'Yes') cmp.set(`v.show${fld}`, true);
            if(fld === 'emp_drive_for_business_purposes__c' && data[fld].includes('Yes'))
            {
                cmp.set(`v.show${fld}`, true);
            }
        }
    },
    saveForm: function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            console.log('wcQuestionnaire.saveForm.send');
            let Tabs = component.get('v.parentTabs');
            
            if(!component.get('v.noIndustryFound') && !Tabs.includes('industry')){
                Tabs.push('industry');
                component.set('v.parentTabs', Tabs);				
            }
            
            let todayDate = new Date();
            //helper.cancelAutoSaveEvents(component, event, helper);
            let isCommUser = component.get('v.user').Profile.Name =='Customer Community Login User Clone';
            let relatedFieldList = component.get('v.relatedFieldList');
            if(isCommUser){
                component.set('v.PEOChecklist.Peo_WC_formStatus__c','Complete');
                component.set('v.PEOChecklist.Peo_WC_SubmissionTime__c', todayDate.toJSON());
                relatedFieldList.push('Peo_WC_formStatus__c','Peo_WC_SubmissionTime__c');
                helper.relatedFieldChanges(component, event, helper,'PEO_Onboarding_Checklist__c',relatedFieldList);
            }
            helper.saveRecord(component, event, helper)
            .then(() => resolve(true))
            .catch(() => reject(false));
        });
    },
    saveRecord: function(cmp, evt, helper) {
        return new Promise(function(resolve, reject) {
            let saveRec = cmp.get('c.savePeoOnboardingChecklist');
            let relatedFieldList = cmp.get('v.relatedFieldList');
            try {
                var buttonLabel = cmp.get('v.buttonLabel');
                // let updatedFields = this.getFields(cmp);
                let peo = cmp.get('v.PEOChecklist');
                //peo.nature_of_business__c = peo.description_principle_product_business__c;
                peo.description_principle_product_business__c = peo.nature_of_business__c;
                cmp.set('v.PEOChecklist.description_principle_product_business__c',peo.description_principle_product_business__c);
                relatedFieldList.push('description_principle_product_business__c','nature_of_business__c');
                helper.relatedFieldChanges(cmp, evt, helper,'PEO_Onboarding_Checklist__c',relatedFieldList);
                //helper.natureOfBusinessChange(cmp, evt, helper);
               /* saveRec.setParams({
                    peoOnbChecklist: peo,
                    formName: 'WorkersCompQuestionnaire.cmp'
                });
                saveRec.setCallback(this, function(res){
                    console.log('here resp');
                    if (res.getState() !== 'SUCCESS' || !res.getReturnValue()) {
                        console.log(res.getError());
                        helper.displayMsg({
                            t: 'Error',
                            m: cmp.get('v.errMsg'),
                            ty: 'Error'
                        });
                        cmp.set('v.PEOChecklist.Peo_401k_formStatus__c','');
                        cmp.set('v.formSubmitted', false);
                        reject(false);
                    } else {
                        helper.displayMsg({
                            t: 'Success',
                            m: "Your progress has been saved!",
                            ty: 'success'
                        });
                        if( cmp.get('v.communityUser')){
                            cmp.set('v.formSubmitted', true);
                        }
                        resolve(true);
                    }
                })
                
                $A.enqueueAction(saveRec);*/
                helper.saveThroughAutoSave(cmp, evt, helper)
                .then(function(res) {
                    console.log('wcQuestionnaire.saveRecord.recieve');
                    helper.displayMsg({
                        t: 'Success',
                        m: "Your progress has been saved!",
                        ty: 'success'
                    });
                    if( cmp.get('v.communityUser')){
                        cmp.set('v.formSubmitted', true);
                    }
                    resolve(helper.setRecordsOnForms(cmp, evt, helper, res));
                })
                .catch(function(err) {
                    console.log('wcQuestionnaire.saveRecord.err');
                    console.log(err);
                    throw err;
                })
            } catch (err) {
                helper.displayMsg({
                    t: 'Error',
                    m: cmp.get('v.errMsg'),
                    ty: 'Error'
                });
                reject(false);
            }
        })
    },
    getFields: function(cmp) {
        let oldRec = cmp.get('v.PEOChecklist');
        // get all  the parent fields and check values
        return cmp.find('questionnaireFields').reduce(function(res, fld) {
            let val = fld.get('v.value');
            if (val == 'default') val = '';
            if (val && val != 'default') {
                res[fld.get('v.name')] = fld.get('v.value');
            }
            return res;
        }, oldRec);
    },
    updateChildView: function(cmp, evt, helper) {
        try {
            // add some field clearning
            // maybe use an update obj to only send the objs that need to be updated
            let parentID = evt.getSource().get("v.name");
            let valSelect = evt.getSource().get('v.value');
            console.log('parentID:'+parentID);	
            console.log('valSelect:'+valSelect);
            const relatedFieldList = [];
            switch(parentID){
                case 'employees_employer_rule_subjectivity__c' :	
                    if(valSelect == 'Private Employer Rules' || valSelect == 'State Rules'){	
                        cmp.set('v.PEOChecklist.employees_employer_rule_subjectivity__c', valSelect);	
                        relatedFieldList.push('employees_employer_rule_subjectivity__c');	
                    }	
                    break;
                case 'bid_or_do_government_work__c' :
                    if(valSelect == 'No'){
                        cmp.set('v.PEOChecklist.employees_employer_rule_subjectivity__c', null);
                        cmp.set('v.PEOChecklist.exposure_to_gvt_rules_or_sovrgn_immunity__c', null);
                        cmp.set('v.PEOChecklist.default_gvt_contractor_decision__c', null);
                        cmp.set('v.PEOChecklist.use_of_service_disqualifies_emp__c', null);
                        cmp.set('v.PEOChecklist.Assert_sovereign_immunity__c', null);
                        relatedFieldList.push('employees_employer_rule_subjectivity__c', 
                                              'exposure_to_gvt_rules_or_sovrgn_immunity__c',
                                              'default_gvt_contractor_decision__c',
                                              'use_of_service_disqualifies_emp__c',
                                              'Assert_sovereign_immunity__c');
                    }
                    break;
                case 'has_non_w2_wrkrs__c' :
                    if(valSelect == 'No'){
                        cmp.set('v.PEOChecklist.number_of_volunteers__c', null);
                        cmp.set('v.PEOChecklist.has_sprt_policy_for_donated_labor__c', null);
                        cmp.set('v.PEOChecklist.number_of_seasonal_wrkrs__c', null);
                        relatedFieldList.push('number_of_volunteers__c', 
                                              'has_sprt_policy_for_donated_labor__c',
                                              'number_of_seasonal_wrkrs__c');
                    }
                    break;
                case 'Has_active_Ohio_WC_Policy__c' :
                    if(valSelect == 'No'){
                        cmp.set('v.PEOChecklist.OH_WC_Policy_number__c', null);
                        cmp.set('v.PEOChecklist.Allow_PEO_admin_OH_WC_Policy__c', null);
                        relatedFieldList.push('OH_WC_Policy_number__c', 
                                              'Allow_PEO_admin_OH_WC_Policy__c');
                    }
                    break;
                    /*case 'Has_active_Ohio_WC_Policy__c' :
                        if(valSelect == 'Yes'){
                            cmp.set('v.PEOChecklist.Allow_PEO_admin_OH_WC_Policy__c', null);
                            relatedFieldList.push('Allow_PEO_admin_OH_WC_Policy__c');
                        }
                        break;*/
                case 'Subcontractors_1099_ind_contractors__c' :
                    if(valSelect == 'No'){
                        cmp.set('v.PEOChecklist.Percentage_of_subcontracted_work__c', null);
                        cmp.set('v.PEOChecklist.How_many_subcontractors__c', null);
                        cmp.set('v.PEOChecklist.What_services_are_subcontracted__c', null);
                        cmp.set('v.PEOChecklist.subcntractrs_insured_wrkrs_comp__c', null);
                        cmp.set('v.PEOChecklist.occurance_of_coi_updates__c', null);
                        cmp.set('v.PEOChecklist.Subcontractors_req_to_provide_a_foreman__c', null);
                        relatedFieldList.push('Percentage_of_subcontracted_work__c', 
                                              'How_many_subcontractors__c',
                                              'What_services_are_subcontracted__c',
                                              'subcntractrs_insured_wrkrs_comp__c',
                                              'occurance_of_coi_updates__c',
                                              'Subcontractors_req_to_provide_a_foreman__c');
                    }
                    break;
                case 'wrk_underground_or_10_ft_above__c' :
                    if(valSelect == 'No'){
                        cmp.set('v.PEOChecklist.Type_of_work_is_done_at_these_places__c', null);
                        cmp.set('v.PEOChecklist.Maximum_height_applicants_work_from__c', null);
                        cmp.set('v.PEOChecklist.Any_bucket_trucks_or_scaffolding_used__c', null);
                        cmp.set('v.PEOChecklist.info_wrk_underground_or_10_ft_above__c', null);
                        cmp.set('v.PEOChecklist.Safety_Equipment_and_training_provided__c', null);
                        relatedFieldList.push('Type_of_work_is_done_at_these_places__c',
                                              'Maximum_height_applicants_work_from__c',
                                              'Any_bucket_trucks_or_scaffolding_used__c',
                                              'info_wrk_underground_or_10_ft_above__c', 
                                          'Safety_Equipment_and_training_provided__c');
                }
                    break;
                case 'emp_drive_for_business_purposes__c' :
                    if(valSelect.includes('Yes')){
                        cmp.set(`v.show${parentID}`, true);
                    }else{
                        cmp.set(`v.show${parentID}`, false);
                        cmp.set('v.PEOChecklist.prsnl_driver_record_verification__c', null);
                        cmp.set('v.PEOChecklist.prsnl_driver_driving_radius__c', null);
                        cmp.set('v.PEOChecklist.Max_num_of_employees_allowed_per_vehicle__c', null);
                        relatedFieldList.push('prsnl_driver_record_verification__c', 
                                              'prsnl_driver_driving_radius__c',
                                          'Max_num_of_employees_allowed_per_vehicle__c');
                }
                    break;
            }
            if(relatedFieldList != undefined && relatedFieldList.length > 0){
                this.relatedFieldChanges(cmp, evt, helper,'PEO_Onboarding_Checklist__c',relatedFieldList);
            }
        }catch(err) {
            console.log(`Err peoUwWorkersCompQuestionnaireHelper.updateChildView: ${err}`)
        }
    },
    displayMsg: function(data) {    
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: data.t,
            message: data.m,
            type: data.ty
        });
        toastEvent.fire();
    }, // displays a toast message for the user
    triggerEvt: function(cmp, e) {
        try {
            let cmpEvent = cmp.getEvent("discrepancyEvt");
            cmpEvent.setParams({
                formName: cmp.get('v.formName'),
                checklistId: cmp.get('v.PEOChecklist').Id,
                type: 'Workers Comp Questionnaire'
            });
            cmpEvent.fire(); 
        } catch(e) {
            console.log('Err in evt fire')
            console.log(e);
        }
    },
    sendAutoSaveEvent: function(cmp, evt, helper) {
        let field = evt.getSource();
        let fieldName = field.get('v.name');
        let objectAPIName = 'PEO_Onboarding_Checklist__c';
        let Account = cmp.get('v.account');
        let fieldValue = field.get('v.value');
        if (fieldValue && fieldValue.length) {
            try {
                let recordId = cmp.get('v.PEOChecklist').Id;
                
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
    
    runAddressAutoSave: function(cmp, e, helper, field) {
        //debugger;
        // Get and set the values to be passed as params into the event
        let fieldName = field.get('v.name');
        let fieldAPIName, objectAPIName, fieldValue;
        let Account = cmp.get('v.account');
        // The field name should be in the format of OBJAPIName.FieldAPIName for the purpose
        // of the auto save. If these values are innacurate on the form they will not
        // be saved on the record.
        if (fieldName) {
            let splitName =  fieldName.split('.');
            objectAPIName = splitName[0];
            fieldAPIName = splitName[1];
        }
        fieldValue = field.get('v.value');
        // only send the request to log this field on the auto save storage if there is
        // actually a value to be save. 
        // This may need to be set to check if the other params exist if some fields
        // need to be saved as blank.
        if (fieldValue && fieldValue.length) {
            try {
                //debugger;
                let recordId;
                if (objectAPIName == 'Account') recordId = Account.Id;
                if (objectAPIName == 'PEO_Onboarding_Checklist__c') recordId = cmp.get('v.PEOChecklist.Id');
                let autoSaveEvt = cmp.getEvent('autoSave');
                autoSaveEvt.setParam('objectName', objectAPIName);
                autoSaveEvt.setParam('accountId', Account.Id);
                autoSaveEvt.setParam('fieldName', fieldAPIName);
                autoSaveEvt.setParam('fieldValue', fieldValue);
                autoSaveEvt.setParam('recordId', recordId);
                autoSaveEvt.setParam('accountName', Account.Name);
                if(fieldAPIName == 'PEO_WC_Address_Info__c')cmp.set('v.PEOChecklist.PEO_WC_Address_Info__c',fieldValue);
                if(fieldAPIName == 'PEO_emp_Info_for_multiple_shft__c')cmp.set('v.PEOChecklist.PEO_emp_Info_for_multiple_shft__c',fieldValue); 
                autoSaveEvt.fire();
            } catch(e) {
                console.log('err occured:')
                console.log(e);
            }
        }
    },
    
    cancelAutoSaveEvents: function(cmp,e, helper) {
        try {
            let autoSaveEvt = cmp.getEvent('autoSave');
            autoSaveEvt.setParam('cancelAll', true);
            autoSaveEvt.fire();
        } catch(e) {
            console.error('Error cancelAutoSaveEvents');
            console.error(e);
        }
    },
    
    sendAddressAutoSave: function(cmp, e, helper) {
        let addressRecs = cmp.get('v.addressRecs');
        let addressData = ''; 
        console.log("addressRecs");
        console.log(addressRecs);
        // iterate the list of records and concatonate the values into the addressData variable
        // result of loop should be: 'address1, number1, address2, number2, etc'
        // EX: Ahmed, 25, Matt, 25, Jidesh, 25, Jake, 25 
        for(let index = 0; index < addressRecs.length; index++){
            addressData += addressRecs[index].address + '^' + addressRecs[index].numberOfemployees;
            if(index != addressRecs.length-1){
                addressData += ';';
            }
        }
        
        // the event like object is passed into the helper.runAutoSave to be parsed as if it's an
        // event. Need a get method to retrieve the obj values
        let field = {
            'v.name': 'PEO_Onboarding_Checklist__c.PEO_WC_Address_Info__c',
            'v.value': addressData,
            get: function(param) {
                return this[param];
            }	
        };
        helper.runAddressAutoSave(cmp, e, helper, field);
    },
    
    sendManagerInfoAutoSave: function(cmp, e, helper) {
        let multiShiftRecs = cmp.get('v.multiShiftRecs');
        let shiftData = '';
        for(let index = 0; index < multiShiftRecs.length; index++){
            shiftData += multiShiftRecs[index].numberOfemployees + '^' + multiShiftRecs[index].manager;
            if(index != multiShiftRecs.length-1){
                shiftData += ';';
            }
        }
        
        // the event like object is passed into the helper.runAutoSave to be parsed as if it's an
        // event. Need a get method to retrieve the obj values
        let field = {
            'v.name': 'PEO_Onboarding_Checklist__c.PEO_emp_Info_for_multiple_shft__c',
            'v.value': shiftData,
            get: function(param) {
                return this[param];
            }	
        };
        helper.runAddressAutoSave(cmp, e, helper, field);
    },
    
    sendShiftCountAutoSave: function(cmp, e, helper) {
        let multiShiftRecs = cmp.get('v.multiShiftRecs');
        let multiShiftData = '';
        for(let index = 0; index < multiShiftRecs.length; index++){
            multiShiftData += multiShiftRecs[index].numberOfemployees + '^' + multiShiftRecs[index].manager;
            if(index != multiShiftRecs.length-1){
                multiShiftData += ';';
            }
        }
        let field = {
            'v.name': 'PEO_Onboarding_Checklist__c.PEO_emp_Info_for_multiple_shft__c',
            'v.value': multiShiftData,
            get: function(param) {
                return this[param];
            }	
        };
        helper.runAddressAutoSave(cmp, e, helper, field);
    },    
    
    prepareAddressRecData: function(cmp, e){
        let addressRecs = [];
        let addressDetails = {"address":"", "numberOfemployees":""};
        let percentageTotal = 0;
        let checklistData = cmp.get("v.PEOChecklist");
        if(checklistData != null && checklistData.hasOwnProperty('PEO_WC_Address_Info__c') &&  checklistData.PEO_WC_Address_Info__c != null &&  checklistData.PEO_WC_Address_Info__c != 'undefined' && checklistData.PEO_WC_Address_Info__c != ''){
            let existingAddressData = checklistData.PEO_WC_Address_Info__c;
            let addressAndCountArr = existingAddressData.split(';');
            for(let cnt = 0; cnt < addressAndCountArr.length; cnt++){
                let addressDetAndCountArr = addressAndCountArr[cnt].split('^');
                let addressObj = Object.assign({},addressDetails);
                addressObj.address = addressDetAndCountArr[0];
                if(addressDetAndCountArr[1] != null && addressDetAndCountArr[1] != '' && addressDetAndCountArr[1] != 'undefined'){
                    addressObj.numberOfemployees = parseInt(addressDetAndCountArr[1]);
                }
                addressRecs.push(addressObj);
            }
        }else{
            let addressObj = Object.assign({},addressDetails);
            addressRecs.push(addressObj);
        }
        cmp.set("v.addressRecs",addressRecs);
    },
    
    prepareShiftRecData: function(cmp, e){
        let multiShiftRecs = [];
        let shiftDetails = {"numberOfemployees":"", "manager":""};
        let checklistData = cmp.get("v.PEOChecklist");
        if(checklistData != null && checklistData.hasOwnProperty('PEO_emp_Info_for_multiple_shft__c') &&  checklistData.PEO_emp_Info_for_multiple_shft__c != null &&  checklistData.PEO_emp_Info_for_multiple_shft__c != 'undefined' && checklistData.PEO_emp_Info_for_multiple_shft__c != ''){
            let existingShiftData = checklistData.PEO_emp_Info_for_multiple_shft__c;
            let shiftAndCountArr = existingShiftData.split(';');
            for(let cnt = 0; cnt < shiftAndCountArr.length; cnt++){
                let shiftDetAndCountArr = shiftAndCountArr[cnt].split('^');
                let shiftObj = Object.assign({},shiftDetails);
                shiftObj.numberOfemployees = parseInt(shiftDetAndCountArr[0]);
                if(shiftDetAndCountArr[1] != null && shiftDetAndCountArr[1] != '' && shiftDetAndCountArr[1] != 'undefined'){
                    shiftObj.manager = shiftDetAndCountArr[1];
                }
                multiShiftRecs.push(shiftObj);
            }
        }else{
            let shiftObj = Object.assign({},shiftDetails);
            multiShiftRecs.push(shiftObj);
        }
        cmp.set("v.multiShiftRecs",multiShiftRecs);
    },
    
    saveThroughAutoSave: function(cmp, e, helper) {
        return new Promise(function(resolve, reject) {
            try {
                console.log('wcQuestionnaire.saveThroughAutoSave.send')
                let autoSaveEvt = cmp.get('v.saveAction');
                
                autoSaveEvt(cmp, e, helper, true)
                .then(function(result) {
                    console.log('wcQuestionnaire.saveThroughAutoSave.recieve');
                    resolve(result);
                })
                .catch(function(err) {
                    console.log('err:' + err);
                })
            } catch(e) {
                console.log('wcQuestionnaire.saveThroughAutoSave err');
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
                if (rec.Id == recIds.PEO_Onboarding_Checklist__c) {
                    //cmp.set('v.PEOChecklist', rec);
                    const keys = Object.keys(rec);
                    keys.forEach((key, index) => {
                        //console.log(`${key}: ${rec[key]}`);
                        var fieldInfo = 'v.PEOChecklist.'+`${key}`;
                                 cmp.set(fieldInfo, `${rec[key]}`);
                	});
                }
            })
        }
        return true;
    },

    natureOfBusinessChange: function(cmp, e, helper) {
        console.log('description_principle_product_business__c changed');
        try {
            //let field = e.getSource();
            let peo = cmp.get('v.PEOChecklist');
            let fieldName = 'description_principle_product_business__c';
            let fieldValue = peo.description_principle_product_business__c;
            console.log('auto save field'+fieldValue);
            console.log('auto save field name:'+fieldName+' val:'+fieldValue);
            let objectAPIName = '';
            let recordId;
            objectAPIName = 'PEO_Onboarding_Checklist__c';
            recordId = cmp.get('v.PEOChecklist.Id');
            let Account = cmp.get('v.account');
            if (fieldName == 'description_principle_product_business__c') {
                
                let autoSaveEvt = cmp.getEvent('autoSave');
                autoSaveEvt.setParam('objectName', objectAPIName);
                autoSaveEvt.setParam('accountId', Account.Id);
                autoSaveEvt.setParam('fieldName', fieldName);
                autoSaveEvt.setParam('fieldValue', fieldValue);
                autoSaveEvt.setParam('recordId', recordId);
                autoSaveEvt.setParam('accountName', Account.Name);
                autoSaveEvt.fire();
                console.log('firing  autoSaveEvt');
            }
        } catch(e) {
            console.error('Error sendMultiFieldUpdate');
            console.error(e);
        }
    },      
    
    relatedFieldChanges: function(cmp, e, helper,objectAPINameToSave, relatedFieldListToSave) {
        try {
            console.log('relatedFieldListToSave:'+relatedFieldListToSave);
            console.log('objectAPINameToSave:'+objectAPINameToSave);
            let objectAPIName = '';
            let recordId;
            let Account = cmp.get('v.account');
            let fieldName,fieldValue;
            if(relatedFieldListToSave.length>0){
                relatedFieldListToSave.forEach(function (item, index) {
                    console.log(item, index);
                    fieldName = item;
                    if(objectAPINameToSave == 'PEO_Onboarding_Checklist__c'){
                        fieldValue = cmp.get(`v.PEOChecklist.`+item);
                        recordId = cmp.get('v.PEOChecklist.Id');
                    }
                    console.log("fieldName:"+fieldName+"fieldValue:"+fieldValue);
                    objectAPIName = objectAPINameToSave;
                    let autoSaveEvt = cmp.getEvent('autoSave');
                    autoSaveEvt.setParam('objectName', objectAPIName);
                    autoSaveEvt.setParam('accountId', Account.Id);
                    autoSaveEvt.setParam('fieldName', fieldName);
                    autoSaveEvt.setParam('fieldValue', fieldValue);
                    autoSaveEvt.setParam('recordId', recordId);
                    autoSaveEvt.setParam('accountName', Account.Name);
                    autoSaveEvt.fire();
                    
                });
            }
            
        } catch(e) {
            console.error('Error relatedFieldChanges');
            console.error(e);
        }
    },
    
})