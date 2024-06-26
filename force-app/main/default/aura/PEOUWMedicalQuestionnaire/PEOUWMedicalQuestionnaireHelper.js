({
    setup: function(cmp, event) {
        // traverse the fields on the passed in questionnaire form
        // Set the 'show[fieldName]' attributes to true if the values match and lock the akn checkbox if
        // user is internal user
        let oasisUser = cmp.get('v.user').Sales_Org__c === 'PEO';
        let checklist = cmp.get('v.peoChecklist');
        let acctList = cmp.get('v.accList');
        if (oasisUser) cmp.set('v.org', 'Oasis');
        else cmp.set('v.org', 'Paychex PEO');
        console.log('**** cmp.get("v.isParentAccount") = ' + cmp.get("v.isParentAccount"));
        if(cmp.get("v.isParentAccount")) {
            let data = cmp.get('v.questionnaire');
            let chk = cmp.get('v.peoChecklist');
            console.log('**** data !== null = ' + data !== null);
            if (data) console.log('**** data.Client_Id_user_agreement_acknowledgment__c = ' + data.Client_Id_user_agreement_acknowledgment__c);
            if (data !== null && data.Client_Id_user_agreement_acknowledgment__c) {
                cmp.set('v.aknSelected', true);
            }
            console.log(data);
            //commenting as part of sfdc-10686
            /*if (chk.Current_Medical_Coverage_Provided__c =='Yes') {
                data.group_medical_offered_past_two_years__c = 'Yes';
            }*/
            cmp.set('v.genericChildLabel',
                    "If yes, please provide additional information such as name of condition, date of occurrence-diagnosis &/or treatment-medication");          
            for (let fld in data) {
                if (data[fld] === 'Yes') cmp.set(`v.show${fld}`, true); 
            } 
            cmp.set("v.currAcct",acctList[0]);
            cmp.set('v.questionnaire', data);
        }
        else{
            for (let acctIndex in acctList) {
                console.log('forAcct:'+acctIndex);
                if (acctList[acctIndex].Id== checklist.Prospect_Client__c) cmp.set("v.currAcct",acctList[acctIndex]);
            } 
        }
        console.log('MedicalQuestionnaire Setup complete');
        console.log('currAcct:'+cmp.get("v.currAcct").Name);
        console.log('MGF MedicalQuestionnaire Setup cmp.get("v.questionnaire.Total_Number_of_Full_Time_Employees__c") = ' + cmp.get("v.questionnaire.Total_Number_of_Full_Time_Employees__c"));
        console.log('MGF MedicalQuestionnaire Setup cmp.get("v.questionnaire.Total_Number_of_Part_Time_Employees__c") = ' + cmp.get("v.questionnaire.Total_Number_of_Part_Time_Employees__c"));
        //console.log(new Date());
    },
    
    saveForm: function(cmp, evt, helper) {
        return new Promise(function(resolve, reject) {
            try{
                let todayDate = new Date();
                let verified = false;
                var ackNeeded = cmp.get('v.acknowledgementNeeded')
                var communityUser = cmp.get('v.commUser');
                let relatedFieldList = cmp.get('v.relatedFieldList');
                if (communityUser)  {
                    console.log('jsh saving medical');
                    cmp.set('v.peoChecklist.Peo_Medical_formStatus__c','Complete');
                    cmp.set('v.peoChecklist.Peo_Medical_formSubmissionTime__c', todayDate.toJSON());
                    relatedFieldList.push('Peo_Medical_formStatus__c','Peo_Medical_formSubmissionTime__c');
                }
                
                if(cmp.get("v.isParentAccount") && communityUser) {
                    if(ackNeeded){
                        verified = cmp.get("v.aknSelected");
                        if(!verified){
                            helper.displayMsg('Acknowledgement Needed', 'Please accept the acknowledgement to continue', 'error', 10000);
                        }
                    } else {
                        verified = helper.verifyFields(cmp, evt);
                    }
                } else if (communityUser && !ackNeeded) {
                    if(cmp.find("UseParentData").get("v.value") == 'Different from Parent') { 
                        verified = helper.verifyFields(cmp, evt);
                    } else if(cmp.find("UseParentData").get("v.value") == null || cmp.find("UseParentData").get("v.value") == '' || cmp.find("UseParentData").get("v.value") == 'undefined') {
                        if(communityUser){
                            helper.displayMsg('Please complete all required fields:', cmp.find("UseParentData").get("v.label"), 'error', 10000);
                            cmp.find("UseParentData").set('v.validity', false);
                            verified = false;
                        }
                    } else {
                        verified = true;
                    }
                }
                
                // save the questionnaire and surface a message if there's an error
                if(verified || !communityUser) {
                    if(!communityUser){	
                        var medicalCoverageReq = false;	
                        try {	
                            cmp.find("medicalFormField").forEach( function(itemcmp) {	
                                if(itemcmp.get("v.name") == 'PEO_Onboarding_Checklist__c.Current_Medical_Coverage_Provided__c') {	
                                    if(!itemcmp.get("v.disabled")) {	
                                        itemcmp.reportValidity();   	
                                        if(itemcmp.get("v.value") == null || itemcmp.get("v.value").length == 0 || itemcmp.get("v.value") == 'undefined') {	
                                            medicalCoverageReq = true;	
                                            return;	
                                        }	
                                    }	
                                }	
                                
                            } );	
                        } catch(e) {	
                            console.log(e);	
                        }	
                        
                        if(medicalCoverageReq){
                            helper.saveThroughAutoSave(cmp, evt, helper)
                            .then(function(result) {
                                resolve(helper.setRecordsOnForms(cmp, evt, helper, result));
                                
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    title: 'Field error',
                                    message: 'Please complete all required fields:',
                                    type: 'error',
                                    duration: 10000
                                });
                                toastEvent.fire();                                 
                            })
                            toastEvent.fire(); 
                        }	
                    }
                    
                    if(!medicalCoverageReq){
                        
                        helper.AKNUpdateAutoSave(cmp, evt, helper, false);
                        helper.relatedFieldChanges(cmp, evt, helper,'PEO_Onboarding_Checklist__c',relatedFieldList);
                        var saveRec = cmp.get('c.saveMedicalQuestionnaire');
                        let updatedFields = cmp.get('v.questionnaire');	
                        //JDA commenting for 10686
                        /*if(updatedFields.group_medical_offered_past_two_years__c == 'No'){
                        updatedFields.Renewal_date__c = "";
                        updatedFields.Rate_change_on_last_renewal__c = "";
                        updatedFields.Years_with_current_carrier__c = "";
                    }*/
                        
                        // send the auto save request to save the updated recordds: saveThroughAutoSave
                        // set records on forms
                        // resolve or reject on errr or success
                        helper.saveThroughAutoSave(cmp, evt, helper)
                        .then(function(result) {
                            resolve(helper.setRecordsOnForms(cmp, evt, helper, result));
                            //SFDC-14128 Start Rohith
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                title: 'Success!',
                                message: 'Your progress has been saved!',
                                type: 'Success'
                            });
                            toastEvent.fire(); 
                            //SFDC-14128 End Rohith
                        })
                        .catch(function(err) {
                            console.log('medicalForm.saveForm.Err');
                            console.log(err);
                            reject(err);
                        })
                    }
                    
                    /*saveRec.setParams({
                        rec: updatedFields,
                        formName: 'MedicalQuestionnaire.cmp'
                    });	
                    saveRec.setCallback(this, function(res) {	
                        let msg = cmp.get('v.errMsg');
                        if (res.getState() !== 'SUCCESS') {		
                            cmp.set('v.peoChecklist.Peo_Medical_formStatus__c','');
                    		cmp.set('v.peoChecklist.Peo_Medical_formSubmissionTime__c', null);
                            cmp.set('v.formSubmitted', false);
                            helper.displayMsg('Error', msg, 'warning', null);	
                            reject(false);
                        }
                        
                        if (res.getReturnValue()) { 
                            try {
                                var saveChecklist = cmp.get('c.savePeoOnboardingChecklist');
                                saveChecklist.setParams({
                                    peoOnbChecklist: cmp.get('v.peoChecklist'),
                                    formName: 'MedicalQuestionnaire.cmp'
                                });	
                                saveChecklist.setCallback(this, function(res) {	
                                    if (res.getState() !== 'SUCCESS') {
                                        helper.displayMsg('Error', msg, 'warning', null);	
                                        reject(false);
                                    }  
                                    if (res.getReturnValue()) { 
                                        helper.getUpdatedChecklsit(cmp, evt, helper)
                                        .then(function(chk) {
                                            cmp.set('v.peoChecklist', chk);
                                            console.table(cmp.get('v.peoChecklist'));
                                            helper.displayMsg('Success', "Your progress has been saved!", 'success', null);	
                                            resolve(true);
                                        })
                                        .catch(function(err)  {
                                            console.log(err);
                                            helper.displayMsg('Success', "Your progress has been saved!", 'success', null);	
                                            resolve(true);
                                        });
                                    }
                                });
                                $A.enqueueAction(saveChecklist);
                            }catch(e) {
                                console.log(e);
                            }
                        } else {
                            console.log(msg);
                            helper.displayMsg('Error', msg, 'Error', null);
                            reject(false);
                        }
                    });
                    
                    $A.enqueueAction(saveRec);*/
                } else {
                    console.log('not verified');
                    reject(false);
                }
            }catch(e) {
                console.log(e);
                reject(false);
            }
        });
    },
    
    verifyFields: function(cmp, e) { 
        var buttonLabel = cmp.get("v.buttonLabel");
        var missingFields = false;
        var missingFieldList = '';
        try {
            cmp.find("medicalFormField").forEach( function(itemcmp) {
                if(itemcmp != 'undefined') {
                    console.log('itemcmp.get("v.name") = ' + itemcmp.get("v.name"));
                    if(!itemcmp.get("v.disabled")) {
                        itemcmp.reportValidity();   
                        if(itemcmp.get("v.value") == null || itemcmp.get("v.value").length == 0 || itemcmp.get("v.value") == 'undefined') {
                            if(!missingFields) {
                                missingFields = true;
                                cmp.set('v.missingFields',missingFields);
                            }
                            missingFieldList += '- ' + itemcmp.get("v.label") + '\n';
                        }
                        else {
                            console.log('itemcmp.get("v.value") = '+ itemcmp.get("v.value"));
                        }
                    }
                }
                
            } );
            
            if(missingFields) {
                this.displayMsg('Please complete all required fields:', missingFieldList, 'error', 10000);
                return false;
            }
            else {
                console.log('returning true');
                return true;
            }
        } catch(e) {
            console.log(e);
        }
        
    },
    
    displayMsg: function(title, msg, type, duration) {  
        console.log('Display Message - title:'+title+' msg:'+msg+' type:'+type+' duration:'+duration);
        // displays a toast message for the user
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: msg,
            type: type,
            duration: duration
        });
        toastEvent.fire();
    }, 
    subFieldUpdate: function(cmp, e) {
        // updates the flag attr to indicate if the child field should show
        let parentID = e.getSource().get("v.name");
        let valSelect = e.getSource().get('v.value');
        
        cmp.set("v.aknSelected",false);
        if (valSelect === 'Yes') {
            return cmp.set(`v.show${parentID}`, true);
        } else {
            return cmp.set(`v.show${parentID}`, false);
        }
        this.answerHasChanged(cmp, e);
    }, 
    
    answerHasChanged: function(cmp, e) {	
        
        if(cmp.get("v.isParentAccount")) {
            if(!cmp.get("v.parentNeedsSaving")) {
                cmp.set("v.parentNeedsSaving", true);
            }
            cmp.set("v.aknSelected",false);
        }
        else {
            if(!cmp.get("v.needsSaving")) {
                cmp.set("v.needsSaving", true);
            } 
        }
        
    }, 
    
    changeChildrenFields: function(cmp, e, helper) {
        let relatedFieldList = cmp.get('v.relatedFieldList');
        if(cmp.get("v.questionnaire.Use_Parent_Questionnaire_Answers__c") == "Different from Parent") {
            cmp.set("v.questionnaire.Current_PEO_Carrier_if_applicable__c", "");
            relatedFieldList.push('Current_PEO_Carrier_if_applicable__c');
        }
        else if(cmp.get("v.questionnaire.Use_Parent_Questionnaire_Answers__c") == "Same as Parent") {
            cmp.set("v.questionnaire.Current_PEO_Carrier_if_applicable__c", cmp.get("v.parentMedQuestionnaire.Current_PEO_Carrier_if_applicable__c"));
            console.log("Setting Current_PEO_Carrier_if_applicable__c to be " + cmp.get("v.parentMedQuestionnaire.Current_PEO_Carrier_if_applicable__c"));
            relatedFieldList.push('Current_PEO_Carrier_if_applicable__c');
        }
        helper.relatedFieldChanges(cmp, e, helper,'PEO_Onboarding_Medical_Questionnaire__c',relatedFieldList);
    },
    
    checkAkn: function(cmp, e,helper) {
        // updates the flag that the user aknowleged the agreement
        // this first check will make sure they've not just skipped right to the acknowledgement tab, the field used is arbitrary
        var missingParentDetail = false;
        if(!cmp.get('v.peoChecklist.Current_Medical_Coverage_Provided__c')){
            missingParentDetail = true;
        }
        var medQuestionnaireFields = [];
        if(cmp.get('v.questionnaire.group_medical_offered_past_two_years__c')== 'Yes' ){
             medQuestionnaireFields.push('group_medical_Yes');
            //sfdc-10686
         /*   medQuestionnaireFields.push('Past_Medical_Carrier__c');
            medQuestionnaireFields.push('Effective_date__c');
            medQuestionnaireFields.push('Termination_date__c');
            medQuestionnaireFields.push('Reason_for_termination__c');
            */
        }else{
            medQuestionnaireFields.push('group_medical_No');
        }
        if(cmp.get('v.questionnaire.Current_Medical_Coverage_Provided__c')== 'Yes' ){
             
medQuestionnaireFields.push('Current_Medical_Yes');
            //console.log("hasPastMedCarrier");
            //sfdc-10686
       /*     medQuestionnaireFields.push('Current_PEO_Carrier_if_applicable__c');
            medQuestionnaireFields.push('Rate_change_on_last_renewal__c');
            medQuestionnaireFields.push('Renewal_date__c');
            medQuestionnaireFields.push('Years_with_current_carrier__c');
            */
        }else{
            medQuestionnaireFields.push('Current_Medical_No');
        }
        var empCount = cmp.get("v.questionnaire.Total_Number_of_Full_Time_Employees__c");
        var tooFewEmps =  (empCount!=null && empCount <5);
        console.log('tooFewEmps'+tooFewEmps);
        if(tooFewEmps){
            this.setAkn(cmp,e);
        }
        else{
            var verifyChildInformation = cmp.get('c.verifyMedQuestionnairesHaveBeenCompleted');
            verifyChildInformation.setParams({allAccounts : cmp.get("v.accList"),
                                              parentFields : medQuestionnaireFields});
            
            verifyChildInformation.setCallback(this, function(res){	
                console.log("*** In verifyChildInformation callback ");
                if (res.getState() !== 'SUCCESS') {	
                    //console.log(res.getError())	
                    this.displayMsg('Server Error', 'Could not save record. Please try again', 'warning', null);	
                }	
                var accountsMissingInfo = (missingParentDetail?cmp.get('v.currAcct.Name')+', '+res.getReturnValue():res.getReturnValue());
                if(accountsMissingInfo != '') {
                    console.log("*** accountsMissingInfo = " + accountsMissingInfo);
                    cmp.set("v.aknSelected", false);
                    this.displayMsg('You are missing information on the following Accounts:', accountsMissingInfo, 'error', null);	
                }
                else {
                    this.setAkn(cmp,e);
                    helper.AKNUpdateAutoSave(cmp, e, helper,false);
                }
            });	
            console.log("*** Calling verifyChildInformation");
            $A.enqueueAction(verifyChildInformation); 
        } 
    }, 
    setAkn:function(cmp,e){
        let todayDate = new Date();
        let currSet = cmp.get('v.aknSelected');
        let q = cmp.get('v.questionnaire');
        q.Client_Id_user_agreement_acknowledgment__c = cmp.get('v.user').Id;
        q.Acknowledgement_Agreed_Stamp__c=todayDate.toJSON();
        cmp.set('v.questionnaire', q);
        cmp.set('v.aknSelected', !currSet);
        var  missingFields = cmp.get('v.missingFields');
        if(missingFields){
            cmp.set('v.aknSelected',false);
        }else{
            cmp.set('v.aknSelected',true);
        }                                     
    },                                        
    
    triggerEvt: function(cmp, e) {
        try {
            let cmpEvent = cmp.getEvent("discrepancyEvt");
            cmpEvent.setParams({
                formName: cmp.get('v.formName'),
                checklistId: cmp.get('v.peoChecklist').Id,
                type: 'Medical Questionnaire',
                medicalChecklst: cmp.get('v.questionnaire').Id
            });
            cmpEvent.fire(); 
        } catch(e) {
            console.log('Err in evt fire')
            console.log(e);
        }
    },
    
    changeRelatedFieldAccess: function(cmp, e, helper) {
        console.log('MGF changeRelatedFieldAccess');
        let fullTimeCount = cmp.get("v.questionnaire.Total_Number_of_Full_Time_Employees__c");
        let partTimeCount = cmp.get("v.questionnaire.Total_Number_of_Part_Time_Employees__c");
        let isParent = cmp.get('v.isParentAccount');
        //console.log('Counts|| Fulltime:'+fullTimeCount+' Part Time:'+partTimeCount);
        //console.log('Parent:'+isParent);
        if(isParent){
            if(fullTimeCount <5 || fullTimeCount == null)cmp.set("v.fewEmp",true);
            if(fullTimeCount >=5)cmp.set("v.fewEmp",false);
        }
        if(!isParent){
            let relParFlTmCnt = cmp.get("v.parentMedQuestionnaire.Total_Number_of_Full_Time_Employees__c");
            //console.log('Full time count from child:'+relParFlTmCnt);
            if(relParFlTmCnt <5 || relParFlTmCnt == null)cmp.set("v.fewEmp",true);
            if(relParFlTmCnt >=5)cmp.set("v.fewEmp",false);
        }
    },  
    sendAutoSave: function(cmp, e, helper) {
        console.log('in medical auto save');
        try {
            let field = e.getSource();
            let fieldName = field.get('v.name');
            let fieldValue = field.get('v.value');
            console.log('auto save field'+fieldValue);
            console.log('auto save field name:'+fieldName+' val:'+fieldValue);
            let objectAPIName = '';
            let recordId;
            if(fieldName && fieldName.startsWith('PEO_Onboarding_Checklist__c')){
                objectAPIName = 'PEO_Onboarding_Checklist__c';
                var dotIndex = fieldName.lastIndexOf('.');
                fieldName = fieldName.substring(dotIndex + 1);
                console.log('checklist fieldName'+fieldName);
                recordId = cmp.get('v.peoChecklist.Id');
                console.log('checklist save recordId'+recordId);
            }
            else{
                objectAPIName = 'PEO_Onboarding_Medical_Questionnaire__c';
                recordId = cmp.get('v.questionnaire.Id');
            }
            let Account = cmp.get('v.accList')[0];
            if ((fieldValue && fieldValue.length) 
                || fieldName == 'Client_Id_user_agreement_acknowledgment__c' 
                || fieldName == 'Acknowledgement_Agreed_Stamp__c'
                ||(fieldName == 'Number_of_Enrolled_Employees__c' && fieldValue.length == 0)
                ||(fieldName == 'Employer_Contribution_Amount__c' && fieldValue.length == 0)) {
                
                let autoSaveEvt = cmp.getEvent('autoSave');
                autoSaveEvt.setParam('objectName', objectAPIName);
                autoSaveEvt.setParam('accountId', Account.Id);
                autoSaveEvt.setParam('fieldName', fieldName);
                autoSaveEvt.setParam('fieldValue', fieldValue);
                autoSaveEvt.setParam('recordId', recordId);
                autoSaveEvt.setParam('accountName', Account.Name);
                autoSaveEvt.fire();
            }
        } catch(e) {
            console.error('Error sendMultiFieldUpdate');
            console.error(e);
        }
    },
    sendMultiFieldUpdate: function(cmp, e, helper) {
        try {
            let objectAPIName = 'PEO_Onboarding_Medical_Questionnaire__c';
            let Account = cmp.get('v.accList')[0];
            let recordId = cmp.get('v.questionnaire.Id');
            let fields = cmp.get('v.questionnaire');
            
            let multipleFieldsMap = {
                PEO_Onboarding_Medical_Questionnaire__c: {
                    recordId:  recordId,
                    fields: fields,
                    accountName:  Account.Name
                }
            };
            let autoSaveEvt = cmp.getEvent('autoSave');
            autoSaveEvt.setParam('objectName', objectAPIName);
            autoSaveEvt.setParam('objectToFieldsMap', multipleFieldsMap);
            autoSaveEvt.fire();
        } catch(e) {
            console.error('Error sendMultiFieldUpdate');
            console.error(e);            
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
    // build an event like object to populate the 
    // aknowlegemnt and send an autop save for its value
    // If the 'Clear' boolean is passed in as true the akn value
    // is cleared out, otherwise the current users ID is populated
    // for the field
    AKNUpdateAutoSave: function(cmp, e, helper, clear) {   
        if(cmp.get('v.aknSelected')){
            let questionnaire = cmp.get('v.questionnaire');
            let usertAknId;
            let ackTime;
            if(clear == true){
                cmp.set('v.aknSelected',false);
                cmp.set('v.questionnaire.Client_Id_user_agreement_acknowledgment__c','');
                cmp.set('v.questionnaire.Acknowledgement_Agreed_Stamp__c',null);
                usertAknId = '';
                ackTime = null;
            }
            else{
                cmp.set('v.aknSelected',true);
                if(cmp.get('v.commUser')) usertAknId = cmp.get('v.user').Id
                else usertAknId = cmp.get('v.questionnaire.Client_Id_user_agreement_acknowledgment__c');
                
                var prevStamp = cmp.get('v.questionnaire.Acknowledgement_Agreed_Stamp__c');
                //console.log('prevStamp:'+prevStamp);
                if(prevStamp && cmp.get('v.commUser') != true){
                    ackTime = prevStamp;
                }
                else{
                    var todayDate = new Date();
                	ackTime = todayDate.toJSON();
                }
                //console.log('ackTime:'+ackTime);
            }
            
            let lookupFieldEvent = {
                getSource: function() {
                    let obj =  {
                        'v.name': 'Client_Id_user_agreement_acknowledgment__c',
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
                        'v.name': 'Acknowledgement_Agreed_Stamp__c',
                        'v.value': ackTime,
                        get: function(p) {return this[p];}
                    };
                    return obj;
                }
            };
            console.log('dateFieldEvent'+dateFieldEvent);
            helper.sendAutoSave(cmp, dateFieldEvent, helper);
        }//if agreement signed
    },
    getUpdatedChecklsit: function(component, event, helper) {
        return new Promise(function(resovle, reject) {
            console.log('getUpdatedChecklsit');
            let getChkACtion = component.get('c.getPEOOnboardingChecklist');
            let accId = component.get('v.currAcct').Id;
            getChkACtion.setParams({
                'accountId': accId,
                formName: 'MedicalQUestionnaire.cmp'
            });
            
            getChkACtion.setCallback(this, function(res) {
                
                if (res.getState() != 'SUCCESS') {
                    console.log(res.getError());
                    reject(undefined);
                }
                console.table(res.getReturnValue());
                resovle(res.getReturnValue());
            });
            $A.enqueueAction(getChkACtion)
        });
    },
    verifyForms: function(cmp, event, helper) {
        var ackNeeded = cmp.get('v.acknowledgementNeeded')
        var communityUser = cmp.get('v.commUser');
        let res = false;
        
        if(cmp.get("v.isParentAccount") && communityUser) {
            if(ackNeeded){
                res = cmp.get("v.aknSelected");
                if(!res){
                    helper.displayMsg('Acknowledgement Needed', 'Please accept the acknowledgement to continue', 'error', 10000);
                }
            } else {
                res = helper.verifyFields(cmp, evt);
            }
        } else if (communityUser && !ackNeeded) {
            if(cmp.find("UseParentData").get("v.value") == 'Different from Parent') { 
                res = helper.verifyFields(cmp, evt);
            } else if(cmp.find("UseParentData").get("v.value") == null || cmp.find("UseParentData").get("v.value") == '' || cmp.find("UseParentData").get("v.value") == 'undefined') {
                if(communityUser){
                    helper.displayMsg('Please complete all required fields:', cmp.find("UseParentData").get("v.label"), 'error', 10000);
                    cmp.find("UseParentData").set('v.validity', false);
                    res = false;
                }
            } else {
                res = true;
            }
        }
        
        return res;
    },
    
    addTabNumbers: function(component, event, helper) {
        
        var tabNames = [];
        var initTabNum = 0;
        tabNames.push('GILabel');
        if(component.get('v.isParentAccount'))tabNames.push('MedicalInfoLabel');
        if(component.get('v.medPrequal')){
            tabNames.push('CensusLabel');
        }
        else{
            tabNames.push('DocsLabel');
        }
        if(component.get('v.currAcct.NAICS_Code__c')){
            tabNames.push('BenchmarkLabel');
        }
        if(tabNames.length>0){
            tabNames.forEach(function (item, index) {
                initTabNum++;
                console.log(item, index);
                component.set(`v.`+item, initTabNum+'.'+component.get(`v.`+item));
            });
        }
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
        if (cmp.get('v.questionnaire') !== null) recIds.PEO_Onboarding_Medical_Questionnaire__c = cmp.get('v.questionnaire').Id; 
        if (cmp.get('v.peoChecklist') !== null) recIds.PEO_Onboarding_Checklist__c = cmp.get('v.peoChecklist').Id; 
        for (let soObjectName in records) {
            let sObjectList = records[soObjectName];
            let failedList = sObjectList !== null ? sObjectList.Fail : [];
            let successList = sObjectList !== null ? sObjectList.Success : [];
            successList.forEach(function(rec) {
                if (rec.Id == recIds.PEO_Onboarding_Medical_Questionnaire__c) cmp.set('v.viewMedicalQuestionnaire', rec);
                //else if (rec.Id == recIds.PEO_Onboarding_Checklist__c) cmp.set('v.viewPEOChecklist', rec);
                if (rec.Id == recIds.PEO_Onboarding_Checklist__c) {
                    helper.getUpdatedChecklsit(cmp, e, helper)
                    .then(function(chk) {
                        cmp.set('v.peoChecklist', chk);
                    }) 
                }
            })
        }
        return true;
    },
    
    relatedFieldChanges: function(cmp, e, helper,objectAPINameToSave, relatedFieldListToSave) {
        try {
            console.log('relatedFieldListToSave:'+relatedFieldListToSave);
            console.log('objectAPINameToSave:'+objectAPINameToSave);
            let objectAPIName = '';
            let recordId;
            let Account = cmp.get('v.accList')[0];
            let fieldName,fieldValue;
            if(relatedFieldListToSave.length>0){
                relatedFieldListToSave.forEach(function (item, index) {
                    console.log(item, index);
                    fieldName = item;
                    if(objectAPINameToSave == 'PEO_Onboarding_Medical_Questionnaire__c'){
                        fieldValue = cmp.get(`v.questionnaire.`+item);
                        recordId = cmp.get('v.questionnaire.Id');
                    }
                    else if(objectAPINameToSave == 'PEO_Onboarding_Checklist__c'){
                        fieldValue = cmp.get(`v.peoChecklist.`+item);
                        recordId = cmp.get('v.peoChecklist.Id');
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
            console.error('Error sendMultiFieldUpdate');
            console.error(e);
        }
    },
    
    checkPermissions : function(cmp, e, helper){
        console.log('Checklist rep Medical cmp:'+cmp.get('v.peoChecklist.Sales_Rep__c'));
        //debugger;
        let permissionCheck = cmp.get('c.checkBLSPermissions');
        permissionCheck.setParams({
            userId:cmp.get('v.peoChecklist.Sales_Rep__c'),
            benchMarkPermission: $A.get("$Label.c.PEOUWBenchmarkPermission")
        });
        permissionCheck.setCallback(this, function(res) {
            if (res.getState() !== 'SUCCESS') {
                //debugger;
                console.error(res.getError());
                return;
            }
            var hasPermissions = res.getReturnValue();
            debugger;
            console.log('hasPermissions:'+hasPermissions);
            cmp.set('v.hasBenchmarkPermission',hasPermissions);
        })
        $A.enqueueAction(permissionCheck);
    },
})