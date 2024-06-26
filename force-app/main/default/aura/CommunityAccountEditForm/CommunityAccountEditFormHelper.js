({
    // takes in a list of fields
    // for each field the function iterates the field then 
    // adds a error message if the field input types don't match
    // what is expected
    validateFields: function(cmp, e, flds) {
        return new Promise(function(resolve, reject) {
            // valid is set to a boolean, which is the result of the reduce call
            let valid = flds.reduce(function(v, f) {
                // if the current field is the Account.Federal_ID_Number__c
                // verify the number is in the xx-xxxxxxx format. If it isn't
                // set the UI flag to true to show the message specific to the
                // field and continure to the next field. Otherwise verify the input
                // type for the field and continue
                // Returns false if any previous field returned false for its
                // validity or the current field isn't false
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
                        return false;
                    } else {
                        cmp.set('v.invalidFedID', false);
                    }
                }
                
                // if any previous return was false then consider the entire form invalid
                // and return false. 
                // Otherwise return if the current field is valud
                if (!v) return v;
                return f.checkValidity();
            }, true);
            
            if (valid) resolve(true); 
            else reject({t: 'Field error', m:'Please enter valid data and provide value for required fields', ty:'error'});
            //else reject({t: 'Invalid fields', m:'Please review errors below', ty:'error'});
        });
    },
    // save the records on the current view in a syncornys fashion
    // Save account, then checklist, then medical form(if there is one)
    // Catch any errors and reject the save request if there is one
    // Each save function rejects with the error provided by the server
   saveRecord: function(cmp, e, helper) {
       
       console.log("Saving record...");
        return new Promise(function(resolve, reject) {
           try {
               helper.saveAccAsync(cmp, e, helper)
                 	.then(function(AccSaveResult) {
                	console.log('account save result');
                	cmp.set('v.currentAccount', AccSaveResult);
                	return helper.saveChecklistAsync(cmp, e, helper);
            	})
            	.then(function(checklistSaveResult) {
                	console.log('checklist save result');
                	if(cmp.get("v.medQuestionnaireNeedsSaving")) {
                    	return helper.saveMedicalAsyn(cmp, e, helper);
                	} else return;
            	})
               .then(function(medicalSaveResult) {
                   //kick off ind refresh
                   let indMethod = cmp.get('v.indAttributesRefresh');
                   if (indMethod)  return indMethod();
                   else return null;
           		})
            	.then(function(medicalSaveResult) {
                	console.log('medical save result');
                	resolve(medicalSaveResult);
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
            let existingOwnershipData = checklistData.List_of_Owners__c;
            let ownersDataAndPercentArr = existingOwnershipData.split(';');
            for(let cnt = 0; cnt < ownersDataAndPercentArr.length; cnt++){
                let ownerNameAndPercentArr = ownersDataAndPercentArr[cnt].split(',');
                let ownerObj = Object.assign({},ownerDetails);
                ownerObj.nameOfOwner = ownerNameAndPercentArr[0];
                if(ownerNameAndPercentArr[1] != null && ownerNameAndPercentArr[1] != '' && ownerNameAndPercentArr[1] != 'undefined'){
                    ownerObj.percentOfOwner = parseInt(ownerNameAndPercentArr[1]);
                    percentageTotal += parseInt(ownerNameAndPercentArr[1]);
                }
                ownerRecs.push(ownerObj);
            }
        }else{
            let ownerObj = Object.assign({},ownerDetails);
            ownerRecs.push(ownerObj);
        }
        cmp.set("v.ownerRecs",ownerRecs);
        cmp.set("v.percentageTotal",percentageTotal);
    },
    
    calcPercentOwnership : function(cmp, e, helper) {
        let ownerRecs = cmp.get("v.ownerRecs");
        let percentageTotal = 0;
        if(ownerRecs != null && ownerRecs != 'undefined' && ownerRecs.length > 0){
            for(let index= 0;  index < ownerRecs.length; index++)
            {
                if(ownerRecs[index].percentOfOwner != null && ownerRecs[index].percentOfOwner != '' && ownerRecs[index].percentOfOwner != 'undefined')
                {
                    percentageTotal += parseInt(ownerRecs[index].percentOfOwner);
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
        
        // only send the request to log this field on the auto save storage if there is
        // actually a value to be save. 
        // This may need to be set to check if the other params exist if some fields
        // need to be saved as blank.
        if (fieldValue && fieldValue.length) {
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
         try {
             let recordsToIgnore = {};
             let currentAccountBeingSaved = cmp.get('v.currentAccount');
             let checklistBeingSaved = cmp.get('v.viewPEOChecklist');
             if (currentAccountBeingSaved) recordsToIgnore.Account = currentAccountBeingSaved.Id;
             if (checklistBeingSaved) recordsToIgnore.PEO_Onboarding_Checklist__c = checklistBeingSaved.Id;
             
             // console.log('clearing for');
             // console.table(recordsToIgnore);
             
             let autoSaveEvt = cmp.getEvent('autoSave');
             autoSaveEvt.setParam('sendImmediete', true);
             autoSaveEvt.setParam('recordsBeingManuallySaved', recordsToIgnore);
             autoSaveEvt.fire();
         } catch(e) {
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
                   	reject(res.getError());
                    return;
                }
                
                let parentAcc = cmp.get("v.parentAcc");
                let account = cmp.get("v.currentAccount");
                if(account && parentAcc && account.Id == parentAcc.Id) {
                    console.log("Setting parent MedQ to the updated values. cmp.get('v.viewMedicalQuestionnaire').Id="+cmp.get('v.viewMedicalQuestionnaire').Id);
                }
                
                resolve(res.getReturnValue());
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
    save: function(cmp, e, helper) {
        return new Promise(function(resolve, reject) {
            //debugger;
            let ownerRecs = cmp.get("v.ownerRecs");
            let precentageTotal = cmp.get("v.percentageTotal");
            let dets = {ty: 'success', t: 'Success!', m:  'Your progress has been saved!'};
            if (cmp.get('v.valChange')) cmp.set('v.valChange', false);
            if(cmp.get('v.currentAccount.Corporation_Type__c') != 'Limited Liability Company' )cmp.set('v.viewPEOChecklist.how_are_you_filing_taxes__c','');
            let fields = cmp.find('editFormField');
            helper.cancelAutoSaveEvents(cmp, e, helper);
            helper.validateFields(cmp, e, fields)
            .then(res => helper.switchLoadState(cmp, e))
            .then(res => helper.saveRecord(cmp, e, helper))
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
                reject(false)
            });    
        })
    },
    
                addTabNumbers: function(component, event, helper) {
                    
                    var tabNames = [];
                    var initTabNum = 0;
                    tabNames.push('BILabel');
                    tabNames.push('AbtYourBsnsLabel');
                    tabNames.push('ReqdDocsLabel');
                    if(tabNames.length>0){
                        tabNames.forEach(function (item, index) {
                            initTabNum++;
                            console.log(item, index);
                            component.set(`v.`+item, initTabNum+'.'+component.get(`v.`+item));
                        });
                    }
                },
                
})