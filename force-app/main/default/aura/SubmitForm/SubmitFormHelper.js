({
    getSubmissionStatus : function(component, event, helper) {
        //debugger;
        //console.log('peo id:'+component.get("v.parentPEOChecklist").Id);
        var submissionStatus = component.get('c.getSubmissionStatus');
        submissionStatus.setParams({
            "peoFullChecklistId": component.get("v.parentPEOChecklist").Id
        });
        submissionStatus.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){
                if(response.getReturnValue()[0].PEO_Checklist_submission_status__c == 'Submitted') {
                    //disableFinishButton
                    component.set('v.disableFinishButton',true);
                    
                    component.set('v.submissionStatus',response.getReturnValue()[0].PEO_Checklist_submission_status__c);
                    component.set('v.submittedAnalyst',response.getReturnValue()[0].Owner.Name);
                    if(component.get('v.finishButtonClicked'))$A.util.addClass(component.find("disablebuttonidTag"), "slds-hide");
                    if(component.get('v.finishButtonClicked'))$A.util.addClass(component.find("toggle0"), "slds-hide");
                    //Hiding the button and tag on load if already submitted
                    if(!component.get('v.finishButtonClicked'))$A.util.addClass(component.find("disablebuttonidTag"), "slds-hide");
                    if(!component.get('v.finishButtonClicked'))$A.util.addClass(component.find("toggle0"), "slds-hide");
                    $A.util.removeClass(component.find("toggle1"), "slds-hide");
                    
                }
                else{
                    //console.log('inside success response else owner details:'+response.getReturnValue()[0].Owner.Name);
                    component.set('v.submittedAnalyst',response.getReturnValue()[0].Owner.Name);
                    
                    if(component.get("v.accountList")[0].Referral_National_Account__c != null) {
                        var strategicAccountPartner = component.get('c.getStrategicAccountPartner');
                        strategicAccountPartner.setParams({
                            "parentAccount": component.get("v.accountList")[0]
                        });
                        
                        strategicAccountPartner.setCallback(this,function(response){
                            console.log('In strategicAccountPartner callback: response.getReturnValue() = ' + response.getReturnValue());
                            var state = response.getState();  
                            if(state=='SUCCESS'){
                                if(response.getReturnValue() != null) {
                                    component.set("v.strategicAccountUser", response.getReturnValue());
                                    component.set("v.routeToStrategicAccount", true);
                                }
                            }
                            else {
                                toastEvent.setParams({
                                    "message": "Unable to find the Strategic Account Partner. Please refresh the page and try again.",
                                    "type": "error",
                                    "duration" : 2000
                                });
                                toastEvent.fire();
                            }
                        });
                        
                        $A.enqueueAction(strategicAccountPartner);
                    }
                }
                //console.log('Analyst retrieved:'+component.get('v.submittedAnalyst'));
            }
            else {
                //console.log('Method unsuccessful');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message": "Unable to fetch submission status.Please try again later.",
                    "type": "error",
                    "duration" : 2000
                });
                toastEvent.fire();
            }
        });  
        
        $A.enqueueAction(submissionStatus); 
    },
    
    submitAllDocuments : function(component, event, helper) {
        //debugger;
        component.set('v.finishButtonClicked',true);
        component.set('v.submitOperationInProgress',true);
        component.set('v.disableFinishButton',true);
        
        component.set('v.docsAssigned', false);
        var submitDocuments = component.get('c.submitForReview');
        // if the method call returns a non empty array indicating a form/questionnaire
        // is not complete throw a failure message to the user
        let incompleteForms = helper.checkForRequiredQuestionnaireStatus(component, event, helper);
        if (incompleteForms.length) {
            var toastEvent = $A.get("e.force:showToast");
            let msg = "There are missing answers on the following questionnaires.  Please ensure that these are answered prior to submitting:\n";
            msg += incompleteForms.reduce((str, frm) => str += '\n' + frm, '');
            toastEvent.setParams({
                "title": "Forms Missing",
                "message": msg,
                "type": "error",
                "duration" : 2000
            });
            toastEvent.fire();
            component.set('v.docsAssigned', true);
            return;
        }
        
        submitDocuments.setParams({  
            "parentOnbChecklist": component.get("v.PEOCheckListData"),
            "currentUser" : component.get("v.currentRunningUser"),
            "strategicAccountPartner" : component.get("v.strategicAccountUser"),
            formName: 'SubmitForm.cmp'
        });
        
        submitDocuments.setCallback(this,function(response){
            component.set('v.docsAssigned', true);
            var state = response.getState();  
            if(state=='SUCCESS'){
                component.set("v.saveOperationInProgress", false);
                component.set("v.submitOperationInProgress", false);
                
                if(response.getReturnValue() == true) {
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "message": "Documents have been reassigned to be reviewed.",
                        "type": "success",
                        "duration" : 2000
                    });
                    toastEvent.fire();
                    //Make the button Disabled on analyst assignment: start
                    helper.getSubmissionStatus(component, event, helper); 
                    //Make the button Disabled :end
                }
                else {
                    console.log('Method successful, but no reassignment occurred');
                    component.set('v.submitOperationInProgress',false);
                    component.set('v.disableFinishButton',false);
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "message": "We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.",
                        "type": "error",
                        "duration" : 2000
                    });
                    toastEvent.fire();
                    helper.getSubmissionStatus(component, event, helper); 
                }
                helper.saveFormProgress(component, event, helper);
            }
            else {
                console.log(response.getError())
                console.log('Method unsuccessful');
                
                component.set('v.submitOperationInProgress',false);
                component.set('v.disableFinishButton',false);
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message": "We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.",
                    "type": "error",
                    "duration" : 2000
                });
                toastEvent.fire();
            }
        });  
        $A.enqueueAction(submitDocuments);  
    },
    
    getPEOchecklistDetails : function(component, event, helper){
        //debugger;
        let needIndSpecific = component.get('v.hasIndustrySpecific');
        var action = component.get("c.getPEOchecklistDetails");
        action.setParams({  
            "accountId": component.get('v.parentRecId')
        });
        
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){  
                var result = response.getReturnValue();      
                //console.log('Response for getPEOchecklistDetails:'+result);//component.set("v.checkedStatus",result.PEO_Medical_Pre_Qualifier__c);  
                component.set("v.PEOCheckListData",result); 
                //console.log('Response for PEOCheckList checklist status:'+component.get("v.PEOCheckList").PEO_Medical_Pre_Qualifier__c);
            }  
        });  
        $A.enqueueAction(action);
        if (needIndSpecific) {
            var industryObject = component.get('c.getIndDetails');
            industryObject.setParams({
                PEOchecklist: component.get('v.parentPEOChecklist').Id,
                AccountId :component.get('v.parentPEOChecklist').Prospect_Client__c,
                formName: 'SubmitForm.cmp'
            });
            console.log( component.get('v.parentPEOChecklist'))
            industryObject.setCallback(this, function(res){
                var state = res.getState(); 
                var data = res.getReturnValue();
                if (state != 'SUCCESS' || !data) {
                    console.log('err')
                    console.log(state);
                    console.log(res.getError());
                }
                component.set('v.industryStruct', data);
                console.log(data);
                // resolve(true);                
            });
            $A.enqueueAction(industryObject);   
        }
    },
    
    checkForRequiredQuestionnaireStatus: function(component, e, helper) {
        //debugger;
        // get the questionnaires/statuses needed to determine success/failure
        let incompleteForms = [];
        let questionnaire = component.get('v.parentPEOChecklist');
        let needCovid = component.get('v.needCovidQuestionnaire');
        let needIndSpecific = component.get('v.hasIndustrySpecific');
        let indStruct = component.get('v.industryStruct');
        let indRec;
        if(indStruct != null) indRec = indStruct.industryRec;
        
        // check for workers comp questionnaire - Medical journey
       // if (questionnaire.Peo_WC_formStatus__c !== 'Complete') incompleteForms.push('Workers Compensation Questionnaire');
        
        // check for industry specific questionnaire
        //if (needIndSpecific && indRec && indRec.Peo_IndSpecific_formStatus__c != 'Complete') incompleteForms.push('Industry Specific Questionaire');
        
        // if covid is requred for industry specific check for covid questionnaire
        //if (needCovid && questionnaire.Peo_Covid_formStatus__c != 'Complete') incompleteForms.push('COVID-19 Questionnaire');
        
        return incompleteForms;
    },
    
    saveFormProgress : function(component, event, helper) {
        //console.log('saveChecklist:'+component.get('v.PEOCheckListData').PEO_Medical_Pre_Qualifier__c);
        try {
            var saveChecklist = component.get("c.savePeoOnboardingChecklist");
            saveChecklist.setParams({
                'peoOnbChecklist': component.get("v.PEOCheckListData"),
                formName: 'SubmitForm.cmp'
            });
            saveChecklist.setCallback(this, function(data) {
                var state = data.getState();
                if (state != 'SUCCESS' || !data.getReturnValue()) {
                    console.error('Error saving checklist: uploadFilesAccSelector.cmp @ saveFormProgress');
                } else {
                    console.log('PEO Medical pre qualifier and Sales notes have been saved');
                }    
            });
            $A.enqueueAction(saveChecklist);
        }
        catch(err) {
            // alert('Form answers may not have been saved properly.');
        }
    },
    
    validateFields: function(cmp, e, flds) {
        return new Promise(function(resolve, reject) {
           // debugger;
            console.log('field:'+flds);
            // valid is set to a boolean, which is the result of the reduce call
           /* let valid = flds.reduce(function(v, f) {
                // if the current field is the Account.Federal_ID_Number__c
                // verify the number is in the xx-xxxxxxx format. If it isn't
                // set the UI flag to true to show the message specific to the
                // field and continure to the next field. Otherwise verify the input
                // type for the field and continue
                // Returns false if any previous field returned false for its
                // validity or the current field isn't false
                // if any previous return was false then consider the entire form invalid
                // and return false. 
                // Otherwise return if the current field is valid
                if (!v) return v;
                return f.checkValidity();
            }, true); */
            let valid = flds.checkValidity();
            console.log('valid: '+valid);
            if (valid){
                console.log('field valid')
                resolve(true); 
            } 
            else{
                console.log('field invalid')
                reject({t: 'Field error', m:'Please provide value for required fields', ty:'error'});
            } 
            //else reject({t: 'Invalid fields', m:'Please review errors below', ty:'error'});
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
        // Continously update the spinner for 5 seconds
        let updateLoading = function(cmp, cb, stillLoading) {
            console.log("stillLoading:"+stillLoading);
            if (cmp.get('v.progressRate') < 100 && stillLoading) {
                let newval = cmp.get('v.progressRate');
                newval+=10;
                console.log(newval);
                cmp.set('v.progressRate', newval);
                window.setTimeout(
                    $A.getCallback(updateLoading.bind(this, cmp, cb, cmp.get('v.saveOperationInProgress'))
                                  ),1000
                );
                // this function calls itself again
            } else if (stillLoading) {
                cmp.set('v.progressRate', 0);
                window.setTimeout(
                    $A.getCallback(updateLoading.bind(this, cmp, cb, cmp.get('v.saveOperationInProgress'))
                                  ),1000);
            } else {
                clearTimeout(updateLoading);
            }
        }
        
        let showSpinner = cmp.get("v.saveOperationInProgress");
        console.log("showSpinner:"+showSpinner);
        cmp.set("v.saveOperationInProgress", !showSpinner);
        
        if (!showSpinner) {
            let toastHelper = function(dets){
                this.showUserMsg(null, dets);
            };
            updateLoading(cmp, toastHelper.bind(this), true);
        } else {
            cmp.set('v.progressRate', 0);
        }
    },
})