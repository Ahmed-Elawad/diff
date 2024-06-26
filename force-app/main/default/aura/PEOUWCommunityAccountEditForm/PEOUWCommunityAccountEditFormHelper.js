({
    // takes in a list of fields
    // for each field the function iterates the field then 
    // adds a error message if the field input types don't match
    // what is expected
    validateFields: function(cmp, e, helper, flds, buttonClicked) {
        return new Promise(function(resolve, reject) {
            // valid is set to a boolean, which is the result of the reduce call
            let valid = true;
            let errorText = "";
            //if(buttonClicked != 'Save'){
            if(flds.length != undefined){
                
                for (let f of flds) {
                    if (f.get('v.name') === 'Account.Federal_ID_Number__c') {
                        let val = f.get('v.value');
                        if(val && val.length == 2 && !cmp.get('v.onBackspacePress')){
                            val+='-'; 
                            cmp.set('v.currentAccount.Federal_ID_Number__c',val);
                        }
                        if (val && val.length && (val[2] !== '-' || val.length < 10)) {
                            if (!cmp.get('v.invalidFedID')) {
                                cmp.set('v.invalidFedID', true);
                            } 
                            return reject({t: 'Field Error', m:'Please enter valid data and provide value for required fields', ty:'error'});
                        } else if(val== undefined){
                            if (!cmp.get('v.invalidFedID')) {
                                cmp.set('v.invalidFedID', true);
                            } 
                            return reject({t: 'Field Error', m:'Please enter valid data and provide value for required fields', ty:'error'});
                        }else {
                            cmp.set('v.invalidFedID', false);
                        }
                        let finValidation = helper.finFieldValidation(cmp, e, helper);
                        if (!finValidation) {
                            errorText = "Please enter a valid Federal Identification Number.";
                            if (!cmp.get('v.invalidFedID')) {
                                cmp.set('v.invalidFedID', true);
                            }
                            cmp.set("v.errorText", errorText);
                            f.reportValidity();
                            valid = false;
                        } else {
                            cmp.set("v.errorText", '');
                            valid = true;
                        }
                    }
                    
                    // if any previous return was false then consider the entire form invalid
                    // and return false. 
                    // Otherwise return if the current field is valud
                    valid = valid && f.checkValidity()
                    if (!valid) return reject({t: 'Field Error', m:'Please enter valid data and provide value for required fields', ty:'error'});
                }
            }                
            if(cmp.get('v.selectedTab') == 'Additional Details' && !cmp.get('v.communityUser')){
                if(cmp.get('v.currentAccount.NAICS_Code__c') == undefined){
                    valid = false;
                }
                if(!cmp.get('v.isChild') || cmp.get('v.clientAddOn')){
                    if(cmp.get('v.viewPEOChecklist.state_with_most_employees__c') == ''){
                        valid = false;
                    }
                    if(cmp.get('v.haveMedical') && cmp.get('v.viewPEOChecklist.Is_Your_Plan_Self_Funded_or_Level_Funded__c') == undefined){
                        valid = false;
                    }
                    //console.log('haveMedical:'+cmp.get('v.haveMedical'));
                    if(cmp.get('v.haveMedical') && cmp.get('v.viewPEOChecklist.Medical_Carriers_currently_in_use__c') == undefined){
                        valid = false;
                    }
                }
            }
            //}
            if(buttonClicked != 'Save'){
                if (valid) {
                    var relatedFieldList = cmp.get('v.relatedFieldList');
                    if(cmp.get('v.selectedTab') == 'About Your Business'){
                        cmp.set('v.viewPEOChecklist.Company_Info_About_Your_Business_Form__c', 'Complete');
                        relatedFieldList.push('Company_Info_About_Your_Business_Form__c');
                    }else if(cmp.get('v.selectedTab') == 'Additional Details'){
                        cmp.set('v.viewPEOChecklist.Company_Info_Addt_Details_Form__c', 'Complete');
                        relatedFieldList.push('Company_Info_Addt_Details_Form__c');
                    }
                    helper.relatedFieldChanges(cmp, e, helper,'PEO_Onboarding_Checklist__c',relatedFieldList);
                    return resolve(true);
                }
                else {
                    return reject({t: 'Field error', m:'Please enter valid data and provide value for required fields', ty:'error'});
                }
            }
            /*else if(buttonClicked == 'Save'){
                if (valid) {
                    var relatedFieldList = cmp.get('v.relatedFieldList');
                    if(cmp.get('v.selectedTab') == 'About Your Business'){
                        cmp.set('v.viewPEOChecklist.Company_Info_About_Your_Business_Form__c', 'Complete');
                        relatedFieldList.push('Company_Info_About_Your_Business_Form__c');
                    }else if(cmp.get('v.selectedTab') == 'Additional Details'){
                        cmp.set('v.viewPEOChecklist.Company_Info_Addt_Details_Form__c', 'Complete');
                        relatedFieldList.push('Company_Info_Addt_Details_Form__c');
                    }
                    helper.relatedFieldChanges(cmp, e, helper,'PEO_Onboarding_Checklist__c',relatedFieldList);
                    resolve(true);
                }
                else reject({t: 'Field error', m:'Please enter valid data and provide value for required fields', ty:'error'});
            }*/
            else{
                var relatedFieldList = cmp.get('v.relatedFieldList');
                if(valid){
                    if(cmp.get('v.selectedTab') == 'About Your Business'){
                        cmp.set('v.viewPEOChecklist.Company_Info_About_Your_Business_Form__c', 'Complete');
                        relatedFieldList.push('Company_Info_About_Your_Business_Form__c');
                    }else if(cmp.get('v.selectedTab') == 'Additional Details'){
                        cmp.set('v.viewPEOChecklist.Company_Info_Addt_Details_Form__c', 'Complete');
                        relatedFieldList.push('Company_Info_Addt_Details_Form__c');
                    }
                }else{
                    if(cmp.get('v.selectedTab') == 'About Your Business'){
                        cmp.set('v.viewPEOChecklist.Company_Info_About_Your_Business_Form__c', 'Pending');
                        relatedFieldList.push('Company_Info_About_Your_Business_Form__c');
                    }else if(cmp.get('v.selectedTab') == 'Additional Details'){
                        cmp.set('v.viewPEOChecklist.Company_Info_Addt_Details_Form__c', 'Pending');
                        relatedFieldList.push('Company_Info_Addt_Details_Form__c');
                    }
                }
                helper.relatedFieldChanges(cmp, e, helper,'PEO_Onboarding_Checklist__c',relatedFieldList);
                return resolve(true);
            }
            //else reject({t: 'Invalid fields', m:'Please review errors below', ty:'error'});
        });
    },
    finFieldValidation: function (cmp, e, helper) {
        let val = cmp.get('v.currentAccount.Federal_ID_Number__c');
        let repeatingCharsRegex = new RegExp($A.get("$Label.c.repeatingCharsRegex"));
        let consecutiveNumbersRegex = new RegExp($A.get("$Label.c.consecutiveNumbersRegex"));
        let invalidPrefixes = $A.get("$Label.c.invalidPrefixes");

        if (!val) {
            return true;
        }
        let prefix = val.substring(0, 2);
        if ((repeatingCharsRegex.test(val) || invalidPrefixes.includes(prefix) || consecutiveNumbersRegex.test(val)) || val.length < 10) {
            //val.reportValidity();
            return false;
        }

        return true;
    },
    
    // save the records on the current view in a syncornys fashion
    // Save account, then checklist, then medical form(if there is one)
    // Catch any errors and reject the save request if there is one
    // Each save function rejects with the error provided by the server
   saveRecord: function(cmp, e, helper) {
       
       console.log("companyInfo.saveRecord.send");
        return new Promise(function(resolve, reject) {
            try {
                // run auto save
                // get updated objects for tab
                // Account, checklist, 
                // refresh ind attributes
                helper.triggerImmedieteAutoSaveOfRecords(cmp, e, helper)
                .then(function(result) {
                    console.log('companyInfo.saveRecord.Recieve');
                    return helper.setRecordsOnForms(cmp, e, helper, result)
                })
                .then(function(SetRecResul) {
                    console.log('setRecordsOnForms')
                    resolve(true);
                })
                .catch(function(err) {
                    console.log('save error'+err);
                    cmp.set('v.waitingForResp', false);
                    let msg = cmp.get('v.errorMsg');
                    reject({t:'Error',m:msg,ty: 'Error'})
                })
            }catch(e) {
                cmp.set('v.waitingForResp', false);
                let msg = cmp.get('v.errorMsg');
                reject({t:'Error',m:msg,ty: 'Error'})
            }
        });
    },
    
    showUserMsg: function(cmp, err) {
        console.log('Shpuld show msg')
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: err.t,
            message: err.m,
            type: err.ty
        });
        toastEvent.fire(); 
    },
    switchLoadState: function(cmp, e) {
        // set the spinner view to the oposite of what it is now
        console.log('In load state');
        // Continously update the spinner for 5 seconds
        let updateLoading = function(cmp, cb, stillLoading) {
            
            if (cmp.get('v.progressRate') < 100 && stillLoading) {
                let newval = cmp.get('v.progressRate');
                newval+=10;
                cmp.set('v.progressRate', newval);
                window.setTimeout(
                    $A.getCallback(updateLoading.bind(this, cmp, cb, cmp.get('v.waitingForResp'))
                                  ),1000
                );
                // this function calls itself again
            } else if (stillLoading) {
                console.log('Msg thrown')
                let dets = {ty: 'warning', t: 'Slow server response', m:  'Waiting for record update to complete. Please do not exit.'};
                cb(dets);
                cmp.set('v.progressRate', 0);
                window.setTimeout(
                    $A.getCallback(updateLoading.bind(this, cmp, cb, cmp.get('v.waitingForResp'))
                                  ),1000);
            } else {
                console.log('clearTimeout');
                clearTimeout(updateLoading);
            }
        }
        
        let showSpinner = cmp.get("v.waitingForResp");
        
        cmp.set("v.waitingForResp", !showSpinner);
        
        if (!showSpinner) {
            let toastHelper = function(dets){
                this.showUserMsg(null, dets);
            };
            updateLoading(cmp, toastHelper.bind(this), true);
        } else {
            cmp.set('v.progressRate', 0);
        }
    },
    getChecklist: function(cmp, e) {
        let getChecklist = cmp.get('c.getPEOOnboardingChecklist');
        
        getChecklist.setParams({
            accountId: cmp.get('v.currentAccount.Id'),
            formName: 'CommunityAccountEditForm.cmp'
        });
        
        getChecklist.setCallback(this, function(res) {
            if (res.getState() != 'SUCCESS') {
                console.log(res.getError());
            }
            let data = res.getReturnValue();
            cmp.set('v.viewPEOChecklist', data);
            
            var frequencies = (!$A.util.isUndefinedOrNull(data.Payroll_Frequency__c) ? data.Payroll_Frequency__c.split(';'):[]);
            cmp.set('v.frequencyValues', frequencies);
            
            if(cmp.get("v.PEOChecklist").Medical_Benefits_Underwriting_Requested__c == 'Yes' ||  cmp.get("v.medicalWasRequested")) {
                this.getMedicalQuestionnaire(cmp, e);
            }
            
            this.prepareOwnerRecData(cmp, e);
        })
        $A.enqueueAction(getChecklist);
    },
    
    getMedicalQuestionnaire: function(cmp, e) {
        let getMedQuestionnaire = cmp.get('c.getMedicalQuestionnaire');
        
        getMedQuestionnaire.setParams({
            peoUnderwritingChecklistId: cmp.get('v.viewPEOChecklist.Id'),
            formName: 'CommunityAccountEditForm.cmp'
        });
        
        getMedQuestionnaire.setCallback(this, function(res) {
            if (res.getState() != 'SUCCESS') {
                console.log(res.getError());
            }
            let data = res.getReturnValue();
            cmp.set('v.viewMedicalQuestionnaire', data);
            
        })
        $A.enqueueAction(getMedQuestionnaire);
    },
    
    prepareOwnerRecData: function(cmp, e){
        //debugger;
        let ownerRecs = [];
        let ownerDetails = {"nameOfOwner":"", "percentOfOwner":""};
        let percentageTotal = 0;
        let checklistData = cmp.get("v.viewPEOChecklist");
        console.log('checklistData:');
        console.log(checklistData);
        if(checklistData != null && checklistData.hasOwnProperty('List_of_Owners__c') &&  checklistData.List_of_Owners__c != null &&  checklistData.List_of_Owners__c != 'undefined' && checklistData.List_of_Owners__c != ''){
            console.log('Inside if');
            let existingOwnershipData = checklistData.List_of_Owners__c;
            let ownersDataAndPercentArr = existingOwnershipData.split(';');
            for(let cnt = 0; cnt < ownersDataAndPercentArr.length; cnt++){
                let ownerNameAndPercentArr = ownersDataAndPercentArr[cnt].split(',');
                let ownerObj = Object.assign({},ownerDetails);
                ownerObj.nameOfOwner = ownerNameAndPercentArr[0];
                if(ownerNameAndPercentArr[1] != null && ownerNameAndPercentArr[1] != '' && ownerNameAndPercentArr[1] != 'undefined'){
                    ownerObj.percentOfOwner = parseFloat(ownerNameAndPercentArr[1]);
                    percentageTotal += parseFloat(ownerNameAndPercentArr[1]);
                }
                ownerRecs.push(ownerObj);
            }
        }else{
            console.log('Inside else');
            let ownerObj = Object.assign({},ownerDetails);
            ownerRecs.push(ownerObj);
        }
        //console.log('ownerRecs:'+ownerRecs);
        //console.log('percentageTotal:'+percentageTotal);
        //cmp.set("v.ownerRecs",ownerRecs);
        //cmp.set("v.percentageTotal",percentageTotal);
    },
    
    calcPercentOwnership : function(cmp, e, helper) {
        let ownerRecs = cmp.get("v.ownerRecs");
        let percentageTotal = 0;
        if(ownerRecs != null && ownerRecs != 'undefined' && ownerRecs.length > 0){
            for(let index= 0;  index < ownerRecs.length; index++)
            {
                if(ownerRecs[index].percentOfOwner != null && ownerRecs[index].percentOfOwner != '' && ownerRecs[index].percentOfOwner != 'undefined')
                {
                    percentageTotal += parseFloat(ownerRecs[index].percentOfOwner);
                    console.log(percentageTotal);
                }
            }
        }
        cmp.set("v.percentageTotal",percentageTotal);
    },
    
    fetchPickListVal: function(component) {
        var action = component.get("c.getSelectOptions");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var stateMap = [];
                for(var key in result){
                    stateMap.push({key: key, value: result[key]});
                }
                component.set("v.stateMap", stateMap);
            }
        });
        $A.enqueueAction(action);
    }, 
    // this method handles the auto save for changed ownership values
    // It gets the ownerRecords from the component, constructs and event like
    // object of the field name & field value so that the runAutoSave can parse
    //  it as it would normally
    sendOwnerAutoSave: function(cmp, e, helper) {
        let ownerRecs = cmp.get('v.ownerRecs');
        let ownershipData = '';
        
        // iterate the list of records and concatonate the values into the ownershipData variable
        // result of loop should be: 'ownerName1, percentforownerName1, ownerName2, percentforownerName2, etc'
        // EX: Ahmed, 25, Matt, 25, Jidesh, 25, Jake, 25 
        for(let index = 0; index < ownerRecs.length; index++){
            ownershipData += ownerRecs[index].nameOfOwner + ',' + ownerRecs[index].percentOfOwner;
            if(index != ownerRecs.length-1){
                ownershipData += ';';
            }
        }
        
        // the event like object is passed into the helper.runAutoSave to be parsed as if it's an
        // event. Need a get method to retrieve the obj values
        let field = {
            'v.name': 'PEO_Onboarding_Checklist__c.List_of_Owners__c',
            'v.value': ownershipData,
            get: function(param) {
                return this[param];
            }	
        };
        
        // call the auto save request passing the field obj as the params
        helper.runAutoSave(cmp, e, helper, field);
    },
    // Get the neccessary params to be passed into the autoSave event that will be
    // handled by the community forms. Gets the field API name, Object API Name,
    // Field value, ID of the record the field belongs to, and the Account name and
    // ID. Adds all these params to the event and fires the event. 
    runAutoSave: function(cmp, e, helper, field) {
        // Get and set the values to be passed as params into the event
        let fieldName = field.get('v.name');
        let fieldAPIName, objectAPIName, fieldValue;
        let Account = cmp.get('v.currentAccount');
        
        // The field name should be in the format of OBJAPIName.FieldAPIName for the purpose
        // of the auto save. If these values are innacurate on the form they will not
        // be saved on the record.
        if (fieldName) {
            let splitName =  fieldName.split('.');
            objectAPIName = splitName[0];
            fieldAPIName = splitName[1];
        }
        fieldValue = field.get('v.value');
        let finValidation = helper.finFieldValidation(cmp, e, helper);
        if (fieldName == 'Account.Federal_ID_Number__c' && !finValidation) {
            fieldValue = '';
        }
        
        // only send the request to log this field on the auto save storage if there is
        // actually a value to be save. 
        // This may need to be set to check if the other params exist if some fields
        // need to be saved as blank.
        if (((fieldValue && fieldValue.length) || typeof fieldValue == 'boolean') || (fieldName == 'Account.Federal_ID_Number__c' && !fieldValue)) {
            try {
                let recordId;
                if (objectAPIName == 'Account') recordId = Account.Id;
                if (objectAPIName == 'PEO_Onboarding_Checklist__c') recordId = cmp.get('v.viewPEOChecklist.Id');
                console.log(field);
                let autoSaveEvt = cmp.getEvent('autoSave');
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
    
    // get the records being manually saved: checklist, medicalForm.
    // get the event to trigger
    // create the params for the event as an object containing a key value pairing
    // of object APi name to record ID. These will be removed from the auto save
    // object before the auto save is sent.
    triggerImmedieteAutoSaveOfRecords: function(cmp, e, helper) {
         return new Promise(function(resolve, reject) {
            try {
                console.log('triggerImmedieteAutoSaveOfRecords.send')
                let recordsToIgnore = {};
                let currentAccountBeingSaved = cmp.get('v.currentAccount');
                let checklistBeingSaved = cmp.get('v.viewPEOChecklist');
                /*if (cmp.get('v.currentAccount.Legal_Name__c').length == 0) {
                    console.log('triggerImmedieteAutoSaveOfRecords save blank Legal_Name__c');
                    cmp.set('v.currentAccount.Legal_Name__c','');
                }*/
                let autoSaveEvt = cmp.get('v.saveAction');
                autoSaveEvt(cmp, e, helper, true)
                .then(function(result) {
                    console.log('triggerImmedieteAutoSaveOfRecords.recieve');
                    resolve(result);
                })
                .catch(function(err) {
                    console.log('err:' + err);
                })
            } catch(e) {
                console.log('triggerImmedieteAutoSaveOfRecords err');
                console.log(e);
            }  
        })
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
    setParentTablistForButtons: function(cmp, e, helper) {
        let allAccounts = cmp.get('v.allAccts');
        let tabListArr = allAccounts.reduce(function(store, acc){
            store.push(acc.Id);
            return store;
        }, []);
    },
    
    getIndNames: function(cmp, e, helper) {
        cmp.set('v.lastNaicsCode',cmp.get('v.currentAccount.NAICS_Code__c'));
        var initNaics = cmp.get('v.initialNaicsCode');
        var lastNaics = cmp.get('v.lastNaicsCode');
        //if(initNaics != lastNaics){
           $A.get('e.force:refreshView').fire();
        //}
    },
    // returns a promise that resolves if the save request for the medical
    // form for the current checklist was succesfully saves. Rejects with the error
    // obj provided by the server if the operration fails.
    saveMedicalAsyn: function(cmp, e, helper) {
        console.log('Starting save Medical...');
        return new Promise(function(resolve, reject) {
            let saveMedicalQuestionnaire = cmp.get('c.saveMedicalQuestionnaire');
            
            // view med questionnaire is set when the tab loads
            saveMedicalQuestionnaire.setParams({
                "rec": cmp.get("v.viewMedicalQuestionnaire"),
                formName: 'CommunityAccountEditForm.cmp'
            });
            
            // on response we need to reject if there's an error
            // otherwise if the viewed tab is for a parent account
            // set the medical questionnaire as the updated
            // medical questionnaire value.
            saveMedicalQuestionnaire.setCallback(this, function(res) {
                if (res.getState() !== 'SUCCESS') {
                    console.error(res.getError());
                   	return reject(res.getError());
                }
                return resolve(res.getReturnValue());
            })
            $A.enqueueAction(saveMedicalQuestionnaire);
        });
    },
    // return a promise that sends an account update request to the server
    // Save the currentAccount on the form.
    // On a server failure reject with the err provided by the server
    // otherwise resolve with the return value of the server
    saveAccAsync: function(cmp, e, helper) {
        console.log('Starting save Account...');
        return new Promise(function(resolve, reject) {
            let saveAcc = cmp.get('c.saveThisAccount');
            
            saveAcc.setParams({
                acct: cmp.get('v.currentAccount'),
                formName: 'CommunityAccountEditForm.cmp'
            });
            
            saveAcc.setCallback(this, function(res) {
                
                if (res.getState() !== 'SUCCESS') {
                    console.error(res.getError());
                    reject(res.getError());
                    return;
                }
                resolve(res.getReturnValue());
            });
            
            $A.enqueueAction(saveAcc);  
        })
    },
    saveChecklistAsync: function(cmp, e, helper) {
        console.log('Starting save checklist...');
        return new Promise(function(resolve, reject) {
            let ownershipData = '';
            let ownerRecs = cmp.get('v.ownerRecs');
            for(let index = 0; index < ownerRecs.length; index++){
                ownershipData += ownerRecs[index].nameOfOwner + ',' + ownerRecs[index].percentOfOwner;
                if(index != ownerRecs.length-1){
                    ownershipData += ';';
                }
            }
            
            let checkList = cmp.get('v.viewPEOChecklist');
            checkList.List_of_Owners__c = ownershipData;
            
            let saveChecklist = cmp.get('c.savePeoOnboardingChecklist');
            
            // These fields need to be removed from the checklsit passed from the UI
            // to the back end. This save updates the cheklist, but the prior save updates
            // the account. The acccount may have a new naics code requiring we update
            // these fields. If these are saved as a part of the checklist we will see
            // bugs where the values may stick after save or may not show as expected.
            // See: https://paychex.sharepoint.com/:x:/t/SSOPEdgeProjectSite/EZJ0A0f5kvBMsfSz5GrcoRoBHWfq93OE_U-C8b6FqCcrDg?e=4%3ADVgClx&at=9&CID=D493F135-4244-46D9-B660-E5B98029086C&wdLOR=c73BCE691-7309-4352-B583-B85F32E5BCF1
            // issue 8
            delete checkList.Industry_Record_Types__c;
            delete checkList.Peo_IndSpecific_formSubmissionTime__c;
            delete checkList.Peo_IndSpecific_formStatus__c;
            saveChecklist.setParams({
                "peoOnbChecklist": checkList,
                formName: 'CommunityAccountEditForm.cmp'
            });
            
            saveChecklist.setCallback(this, function(res) {
                if (res.getState() !== 'SUCCESS') {
                    console.error(res.getError());
                    reject(res.getError());
                    return;
                }
                if (!res.getReturnValue()) {
                    reject(res.getError());
                    return;
                }
                
                cmp.set("v.viewPEOChecklist", checkList);
                
                let parentAcc = cmp.get("v.parentAcc");
                let account = cmp.get("v.currentAccount");
                if(account && parentAcc && account.Id == parentAcc.Id) {
                    console.log("Setting parent checklist to the updated values. cmp.get('v.viewPEOChecklist').Id="+cmp.get('v.viewPEOChecklist').Id);
                    cmp.set("v.PEOChecklist", cmp.get("v.viewPEOChecklist"));
                }
                
                resolve(res.getReturnValue());
            })
            
            $A.enqueueAction(saveChecklist);
        });
    },
    
    fetchPickListVal2: function(component, fieldDetails) {
        return new Promise(function(resolve, reject) {
            var action = component.get("c.getSelectOptions2");
            action.setParam('fieldDetails', fieldDetails);
            action.setCallback(this, function(response) {
                var result = response.getReturnValue();
                if (response.getState() != 'SUCCESS') {
                    console.log(response.getError())
                    let t = 'Error',
                        m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                        ty = 'Error';
                    reject({t: t, m: m, ty: ty});
                }
                for(var key in result){
                    var valueMap = [];
                    if(key == "Corporation_Type__c"){
                        for(var valueRet in result[key]){
                            valueMap.push({key: key, value: valueRet});
                        }
                        component.set("v.businessEnityTypes", valueMap);
                    }
                    if(key == "how_are_you_filing_taxes__c"){
                        for(var valueRet in result[key]){
                            valueMap.push({key: key, value: valueRet});
                        }
                        component.set("v.howAreyouFillingTaxesOptions", valueMap);
                    }
                    if(key == "state_with_most_employees__c"){
                        for(var valueRet in result[key]){
                            valueMap.push({key: key, value: valueRet});
                        }
                        component.set("v.stateMap", valueMap);
                    }
                    if(key == "Health_Benefits_Currently_through_a_PEO__c"){
                        for(var valueRet in result[key]){
                            valueMap.push({key: key, value: valueRet});
                        }
                        component.set("v.yesOrNoMap", valueMap);
                    }
                    console.log('valueMap:'+valueMap);
                }
                resolve(true);	
            });
            $A.enqueueAction(action);
        })
    }, 
	save: function(cmp, e, helper, buttonClicked, skipValidate) {
        	return new Promise(function(resolve, reject) {
            	console.log('peoUwCommunityAccountEditFormhelper.save...');
            	let ownerRecs = cmp.get("v.ownerRecs");
            	let precentageTotal = cmp.get("v.percentageTotal");
            	let dets = {ty: 'success', t: 'Success!', m:  'Your progress has been saved!'};
            	let relatedFieldList = cmp.get('v.relatedFieldList');
            	if (cmp.get('v.valChange')) cmp.set('v.valChange', false);
            	if(cmp.get('v.currentAccount.Corporation_Type__c') != 'Limited Liability Company' ){
        	        cmp.set('v.viewPEOChecklist.how_are_you_filing_taxes__c','');
    	            relatedFieldList.push('how_are_you_filing_taxes__c');
	                helper.relatedFieldChanges(cmp, e, helper,'PEO_Onboarding_Checklist__c',relatedFieldList);
	            }
            
            	let fields;
            	if(cmp.get('v.selectedTab') == 'About Your Business'){
            	    fields = cmp.find('editFormFieldAYB');
        	    }else{
    	            fields = cmp.find('editFormField');
	            }
            
            	if (skipValidate) {
                	helper.switchLoadState(cmp, e)
                	helper.saveRecord(cmp, e, helper)
                		.then(res => helper.runAutoRefresh(cmp, e, helper))
                		.then(res => helper.switchLoadState(cmp, e))
                		.then(res => helper.showUserMsg(cmp, dets))
                		.then(res => {
                    		let indMethod = cmp.get('v.indAttributesRefresh');
                    		if (indMethod)  return indMethod();
                    		else return null;
                		})
            	    	.then(res => resolve(true))
        	        	.catch(err => {
    	                	helper.showUserMsg(cmp, err);
	                    	return reject(false)
                		});       
				} else {
					helper.validateFields(cmp, e, helper, fields, buttonClicked)
                    	.then(res => helper.switchLoadState(cmp, e))
                    	.then(res => helper.saveRecord(cmp, e, helper))
						.then(res => helper.runAutoRefresh(cmp, e, helper))
						.then(res => helper.switchLoadState(cmp, e))
						.then(res => helper.showUserMsg(cmp, dets))
						.then(res => {
							let indMethod = cmp.get('v.indAttributesRefresh');
							if (indMethod)  return indMethod();
							else return null;
						})
						.then(res => resolve(true))
						.catch(err => {
					helper.showUserMsg(cmp, err);
					return reject(false)
				});       
			}
		})
	},
    
	addTabNumbers: function(component, event, helper) {
                    
                    var tabNames = [];
                    var initTabNum = 0;
                    //tabNames.push('BILabel');
                    tabNames.push('AbtYourBsnsLabel');
                    tabNames.push('AddDetLabel');
                    //tabNames.push('ReqdDocsLabel');
                    if(component.get('v.currentAccount.NAICS_Code__c')){
                        tabNames.push('BenchmarkLabel');
                    }
                    if(tabNames.length>0){
                        tabNames.forEach(function (item, index) {
                            initTabNum++;
                            console.log(item, index);
                            if(!component.get(`v.`+item).includes(''+initTabNum+'.')){
                                console.log('Tab doesnt exist, creating new Tab');
                                
                                component.set(`v.`+item, initTabNum+'. '+component.get(`v.`+item));
                            }
                            else{
                                console.log('Tab exists, so not altering the label');
                            }
                        });
                    }
                },
                
                setRecordsOnForms: function(cmp, e, helper, records) {
                    let recIds = {};
                    if (cmp.get('v.viewMedicalQuestionnaire') !== null) recIds.PEO_Onboarding_Medical_Questionnaire__c = cmp.get('v.viewMedicalQuestionnaire').Id; 
                    if (cmp.get('v.viewPEOChecklist') !== null) recIds.PEO_Onboarding_Checklist__c = cmp.get('v.viewPEOChecklist').Id; 
                    for (let soObjectName in records) {
                        let sObjectList = records[soObjectName];
                        let failedList = sObjectList !== null ? sObjectList.Fail : [];
                        let successList = sObjectList !== null ? sObjectList.Success : [];
                        successList.forEach(function(rec) {
                            if (rec.Id == recIds.PEO_Onboarding_Medical_Questionnaire__c) {
                                //cmp.set('v.viewMedicalQuestionnaire', rec);
                                const keys = Object.keys(rec);
                                keys.forEach((key, index) => {
                                    //console.log(`${key}: ${rec[key]}`);
                                    var fieldInfo = 'v.viewMedicalQuestionnaire.'+`${key}`;
                                    //console.log('fieldInfo:'+fieldInfo);
                                    cmp.set(fieldInfo, `${rec[key]}`);
                                });
                            }
                            else if (rec.Id == recIds.PEO_Onboarding_Checklist__c) {
                                //cmp.set('v.viewPEOChecklist', rec);
                                const keys = Object.keys(rec);
                                keys.forEach((key, index) => {
                                //console.log(`${key}: ${rec[key]}`);
                                    var fieldInfo = 'v.viewPEOChecklist.'+`${key}`;
                                	//console.log('fieldInfo:'+fieldInfo);
                                	cmp.set(fieldInfo, `${rec[key]}`);
                                });
                            }
                        })
                    }
                    return true;
                }, 
           
           relatedFieldChanges: function(cmp, e, helper,objectAPINameToSave, relatedFieldListToSave) {
                try {
                    console.log('relatedFieldListToSave:'+relatedFieldListToSave);
                    let objectAPIName = '';
                    let recordId;
                    let Account = cmp.get('v.currentAccount');
                    let fieldName,fieldValue;
                    if(relatedFieldListToSave.length>0){7
                        relatedFieldListToSave.forEach(function (item, index) {
                            console.log(item, index);
                            fieldName = item;
                            if(objectAPINameToSave == 'PEO_Onboarding_Checklist__c'){
                                fieldValue = cmp.get(`v.viewPEOChecklist.`+item);
                                recordId = cmp.get('v.viewPEOChecklist.Id');
                            }
                            else if(objectAPINameToSave == 'Account'){
                                console.log('relatedFieldChanges Account:');
                                console.log('relatedFieldChanges fieldValue:'+fieldValue);
                                console.log('fieldName:'+fieldName);
                                fieldValue = cmp.get(`v.currentAccount.`+item);
                                recordId = cmp.get('v.Account.Id');
                            }
                            objectAPIName = objectAPINameToSave;
                            let autoSaveEvt = cmp.getEvent('autoSave');
                            autoSaveEvt.setParam('objectName', objectAPIName);
                            autoSaveEvt.setParam('accountId', Account.Id);
                            autoSaveEvt.setParam('fieldName', fieldName);
                            autoSaveEvt.setParam('fieldValue', fieldValue);
                            autoSaveEvt.setParam('recordId', recordId);
                            autoSaveEvt.setParam('accountName', Account.Name);
                            console.log('params:objectName-'+objectAPIName+ ' fieldName :'+fieldName+ ' fieldValue :'+fieldValue);
                            autoSaveEvt.fire();
                            
                        });
                    }
                    
                } catch(e) {
                    console.error('Error sendMultiFieldUpdate');
                    console.error(e);
                }
            }, 
                
                checkPermissions : function(cmp, e, helper){
                    console.log('Checklist rep:'+cmp.get('v.PEOChecklist.Sales_Rep__c'));
                    let permissionCheck = cmp.get('c.checkBLSPermissions');
                    permissionCheck.setParams({
                        userId:cmp.get('v.PEOChecklist.Sales_Rep__c'),
                        benchMarkPermission: $A.get("$Label.c.PEOUWBenchmarkPermission")
                    });
                    permissionCheck.setCallback(this, function(res) {
                        if (res.getState() !== 'SUCCESS') {
                            console.error(res.getError());
                            return;
                        }
                        var hasPermissions = res.getReturnValue();
                        console.log('hasPermissions:'+hasPermissions);
                        cmp.set('v.hasBenchmarkPermission',hasPermissions);
                    })
                    $A.enqueueAction(permissionCheck);
                },
                     runAutoRefresh: function(cmp, e, helper) {
                        console.log('Inside helper runAutoRefresh');
                         console.log('refreshForm:'+cmp.get('v.refreshForm'));
                        if(cmp.get('v.refreshForm')){
                            try {
                                let autoRefreshEvt = cmp.getEvent('autoRefresh');
                                autoRefreshEvt.fire();
                            } catch(e) {
                                console.log('err occured:')
                                console.log(e);
                            }
                        }
                    },
                        
                        handleChange: function(cmp, e, helper) {
                            // should update the object storing the reference values to contain the vlaue from the current field
                            // set the boolean to indicate a change occuered to true
                            console.log('JDA Inside handle change');        
                            let field = e.getSource();
                            let fields;
                            let relatedFieldList = cmp.get('v.relatedFieldList');
                            if (!cmp.get('v.valChange')) cmp.set('v.valChange', true);
                            
                            var headquater = cmp.get('v.viewPEOChecklist.Headquarter_State__c');
                            console.log('headquater ::: '+headquater);
                            if ((headquater == 'HI') || (headquater == 'MI') || (headquater == 'NH')) {
                                cmp.set('v.headquaterValue', true);
                                const helpText = 'HI MI and NH require a PEO client to be on the WC master policy, if the risk does not meet WC UW Guidelines and WC is not approved, then this group will not be allowed on the PEO. If you have questions, please refer to your DSM.';
                                cmp.set('v.headquaterHelpText', helpText);
                            }
                            else{
                                cmp.set('v.headquaterValue', false);
                            }
                            
                            var mostEmpSate = cmp.get('v.viewPEOChecklist.state_with_most_employees__c');
                            console.log('mostEmpSate ::: '+mostEmpSate);
                            if ((mostEmpSate == 'HI') || (mostEmpSate == 'MI') || (mostEmpSate == 'NH')) {
                                cmp.set('v.mostEmp', true);
                                const helpText = 'HI MI and NH require a PEO client to be on the WC master policy, if the risk does not meet WC UW Guidelines and WC is not approved, then this group will not be allowed on the PEO. If you have questions, please refer to your DSM.';
                                cmp.set('v.headquaterHelpText', helpText);
                            }
                            else {
                                cmp.set('v.mostEmp', false);
                            }
                            
                            
                            /*var frequencyList = cmp.get('v.frequencyValues');
        if(frequencyList){
            frequencyList = frequencyList.sort().join('; ');
            cmp.set('v.viewPEOChecklist.Payroll_Frequency__c',frequencyList);
        }
        else{
            cmp.set('v.viewPEOChecklist.Payroll_Frequency__c','');
        }        
        relatedFieldList.push('Payroll_Frequency__c');*/
              if(cmp.get('v.selectedTab') == 'About Your Business'){
                  fields = cmp.find('editFormFieldAYB');
              }else{
                  fields = cmp.find('editFormField');
              }
              //PEO SPA
              var refreshForm = false;
              if((field.get('v.name') == 'PEO_Onboarding_Checklist__c.Total_Number_of_Employees__c' && field.get('v.value') > 49) ||
                 (field.get('v.name') == 'PEO_Onboarding_Checklist__c.Is_Your_Plan_Self_Funded_or_Level_Funded__c' && field.get('v.value') == 'Yes') || 
                 (field.get('v.name') == 'PEO_Onboarding_Checklist__c.Currently_using_a_PEO__c' && field.get('v.value') == 'Yes') ||
                 (field.get('v.name') == 'PEO_Onboarding_Checklist__c.Medical_Carriers_currently_in_use__c' && field.get('v.value') != 'None of These')){
                  var pathType = cmp.get('v.viewPEOChecklist.Medical_Underwriting_Path_Type__c');	
                  /*if(pathType != '' && pathType != null && pathType != 'Traditional - Medical'){	
                cmp.set('v.viewPEOChecklist.Medical_Underwriting_Path_Type__c', 'Salesforce Forced - Medical');	
            }else{	
                cmp.set('v.viewPEOChecklist.Medical_Underwriting_Path_Type__c', 'Traditional - Medical');	
            }*/
            console.log('handleChange pathType:'+pathType);
            // Differentiate between Med and WC path here
            if(pathType == 'Quick Quote - Medical'){
                if(cmp.get('v.viewPEOChecklist.Is_Medical_Underwriting_Requested__c')!= 'Currently does not have Medical and not interested in Medical, do not quote'){
                    cmp.set('v.viewPEOChecklist.Medical_Underwriting_Path_Type__c', 'Salesforce Forced - Medical');
                }                
                cmp.set('v.viewPEOChecklist.Workers_Comp_Underwriting_Path_Type__c', 'Salesforce Forced - Workers Comp');
                refreshForm = true;
                if(!cmp.get('v.communityUser')){
                    cmp.set('v.showMsg', true);
                }
                cmp.set('v.knockOutMessage', 'Based on the information provided, the prospect is no longer eligible for a Quick Quote. ' + 
                        'The portal has been updated to a Full Underwriting submission.');
            }
            relatedFieldList.push('Medical_Underwriting_Path_Type__c');
            relatedFieldList.push('Workers_Comp_Underwriting_Path_Type__c');
        }else{
            var peoChkList = cmp.get('v.viewPEOChecklist');
            if((peoChkList.Total_Number_of_Employees__c == undefined || peoChkList.Total_Number_of_Employees__c <= 49) &&
               (peoChkList.Is_Your_Plan_Self_Funded_or_Level_Funded__c == undefined || peoChkList.Is_Your_Plan_Self_Funded_or_Level_Funded__c == 'No') &&
               (peoChkList.Currently_using_a_PEO__c == undefined || peoChkList.Currently_using_a_PEO__c == 'No') &&
               (peoChkList.Medical_Carriers_currently_in_use__c == undefined || peoChkList.Medical_Carriers_currently_in_use__c == 'None of These')){
                if(peoChkList.Do_you_need_full_underwriting_path__c == 'No'){
                    //JDA need to update the code to stop getting refreshed the first time
                    if(peoChkList.Medical_Underwriting_Path_Type__c == 'Salesforce Forced - Medical' || peoChkList.Workers_Comp_Underwriting_Path_Type__c =='Salesforce Forced - Workers Comp'){
                        refreshForm = true;
                    }
                    if(cmp.get('v.viewPEOChecklist.Medical_Underwriting_Path_Type__c') != 'Clientspace Forced - Medical' 
                       //&& cmp.get('v.viewPEOChecklist.Medical_Underwriting_Path_Type__c') != 'Salesforce Forced - Medical'
                       && cmp.get('v.viewPEOChecklist.Is_Medical_Underwriting_Requested__c')!= 'Currently does not have Medical and not interested in Medical, do not quote'){
                        cmp.set('v.viewPEOChecklist.Medical_Underwriting_Path_Type__c', 'Quick Quote - Medical');
                        //cmp.set('v.viewPEOChecklist.Workers_Comp_Underwriting_Path_Type__c', 'Quick Quote - Workers Comp');
                    }
                    if(cmp.get('v.viewPEOChecklist.Workers_Comp_Underwriting_Path_Type__c') != 'Clientspace Forced - Workers Comp' 
                       //&& cmp.get('v.viewPEOChecklist.Workers_Comp_Underwriting_Path_Type__c') != 'Salesforce Forced - Workers Comp'
                      )
                    {
                        cmp.set('v.viewPEOChecklist.Workers_Comp_Underwriting_Path_Type__c', 'Quick Quote - Workers Comp');
                    }
                    
                }/*else if(peoChkList.Do_you_need_full_underwriting_path__c == 'Yes'){
                    cmp.set('v.viewPEOChecklist.Medical_Underwriting_Path_Type__c', 'Traditional - Medical');
                    cmp.set('v.viewPEOChecklist.Workers_Comp_Underwriting_Path_Type__c', 'Traditional - Workers Comp');
                }*/
            }
            relatedFieldList.push('Medical_Underwriting_Path_Type__c');
            relatedFieldList.push('Workers_Comp_Underwriting_Path_Type__c');
        }
              
              if(field.get('v.name') == 'PEO_Onboarding_Checklist__c.Currently_using_a_PEO__c'){
                  if(field.get('v.value') == 'Yes'){
                      cmp.set('v.viewPEOChecklist.Previous_Paychex_PEO_Oasis_HROI_client__c','');
                      relatedFieldList.push('Previous_Paychex_PEO_Oasis_HROI_client__c');
                  }else{
                      cmp.set('v.viewPEOChecklist.Current_PEO_Provider__c','');
                      relatedFieldList.push('Current_PEO_Provider__c');
                  }
              }
              helper.relatedFieldChanges(cmp, e, helper,'PEO_Onboarding_Checklist__c',relatedFieldList);
              helper.validateFields(cmp, e, helper, fields);      
              
              if(field.get("v.type") == 'Date' || field.get("v.type") == 'date') {
                  field.setCustomValidity('') ;
                  let chckvalididty = field.get("v.validity");
                  
                  if(!chckvalididty.valid) field.setCustomValidity('format must be mm/dd/yyyy');
                  else field.setCustomValidity('');
                  
                  field.reportValidity();
              }
              helper.runAutoSave(cmp, e, helper, field); 
              if(refreshForm){
                  cmp.set('v.refreshForm',refreshForm);
              }
          }, 
})