({
    getFieldInfoForAcc: function(cmp, e) {
        // add a delay if info isn't loaded
        let data = cmp.get('v.PEOChecklist');
        for (let fld in data) {
            if (data[fld] === 'Yes') cmp.set(`v.show${fld}`, true);
            if (fld === 'emp_drive_for_business_purposes__c' && data[fld].includes('company')) {
                cmp.set(`v.show${fld}`, true);
            } else if (fld === 'emp_drive_for_business_purposes__c' && data[fld].includes('personal')) {
                cmp.set(`v.showPersonal${fld}`, true);
            }
        }
    },
    saveForm: function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            let todayDate = new Date();
            helper.cancelAutoSaveEvents(component, event, helper);
            let isCommUser = component.get('v.user').Profile.Name =='Customer Community Login User Clone';
            if(isCommUser){
                component.set('v.PEOChecklist.Peo_WC_formStatus__c','Complete');
                component.set('v.PEOChecklist.Peo_WC_SubmissionTime__c', todayDate.toJSON());
            }
            helper.saveRecord(component, event, helper)
            .then(() => resolve(true))
            .catch(() => reject(false));
        });
    },
    saveRecord: function(cmp, evt, helper) {
        return new Promise(function(resolve, reject) {
            let saveRec = cmp.get('c.savePeoOnboardingChecklist');
            try {
                var buttonLabel = cmp.get('v.buttonLabel');
                // let updatedFields = this.getFields(cmp);
                let peo = cmp.get('v.PEOChecklist');
                peo.nature_of_business__c = peo.description_principle_product_business__c;
                saveRec.setParams({
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
                
                $A.enqueueAction(saveRec);
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
    updateChildView: function(cmp, e) {
        // add some field clearning
        // maybe use an update obj to only send the objs that need to be updated
        let parentID = e.getSource().get("v.name");
        let valSelect = e.getSource().get('v.value');
        
        if (parentID === 'emp_drive_for_business_purposes__c' && valSelect.includes('company')) {
            cmp.set(`v.show${parentID}`, true);
            cmp.set(`v.showPersonal${parentID}`, false);
        } else if (parentID === 'emp_drive_for_business_purposes__c' && valSelect.includes('personal')) {
            cmp.set(`v.show${parentID}`, false);
            cmp.set(`v.showPersonal${parentID}`, true);
        } else if (parentID === 'emp_drive_for_business_purposes__c') {
            cmp.set(`v.show${parentID}`, false);
            cmp.set(`v.showPersonal${parentID}`, false);
        } else {
            if (valSelect === 'Yes') {
                cmp.set(`v.show${parentID}`, true);
            } else {
                cmp.set(`v.show${parentID}`, false);
            }    
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
    sendAutoSaveEvent: function(cmp, e, helper) {
        let field = e.getSource();
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
    
})