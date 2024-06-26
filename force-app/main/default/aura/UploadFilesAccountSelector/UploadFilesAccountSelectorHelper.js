({
    checkSubmissionPrivileges : function(component, event, helper) {
        var curUser = component.get('v.currentRunningUser');
        //console.log('curUser.Sales_Org__c = '+curUser.Sales_Org__c);
        if(!component.get("v.communityUser") && (curUser.Sales_Org__c == 'PAS' || curUser.Sales_Org__c == 'PEO' || curUser.Profile.Name.includes('System Admin'))) {
            component.set('v.allowSubmit', true);
        }
    },
    
    getChecklistAndMedicalQuestionnaire : function(component, event) {
        component.set("v.loadedChecklist", false);
        if(component.get("v.uploadFilesSelectedAccId") != component.get("v.accountList")[0].Id) {
            
            console.log('UploadFilesAccountSelector Getting PEO Checklist for UploadFiles Component component.get("v.uploadFilesSelectedAccId")='+component.get("v.uploadFilesSelectedAccId"));
            var getPEOChecklist = component.get("c.getPEOOnboardingChecklist");
            
            getPEOChecklist.setCallback(this, function(data) {
                //console.log('data.getReturnValue().Id = '+data.getReturnValue().Id);
                if(data.getReturnValue() != null)
                {
                    component.set("v.currentPEOChecklist", data.getReturnValue());
                    
                    var getMedQuestionnaire = component.get("c.getMedicalQuestionnaireForm");
                    
                    getMedQuestionnaire.setParams({
                        'peoOnboardingChecklistId': data.getReturnValue().Id,
                        formName: 'UploadFilesAccountSelector.cmp'
                    });
                    
                    getMedQuestionnaire.setCallback(this, function(res) {
                        //console.log(res.getReturnValue());
                        if(data.getReturnValue() != null)
                        {
                            component.set("v.currentPEOMedicalChecklist", res.getReturnValue());
                            this.checkWhichFilesNeeded(component, event);
                            
                            component.set("v.loadedChecklist", true);
                        }
                    });
                    $A.enqueueAction(getMedQuestionnaire);
                }
                
            });
            
            getPEOChecklist.setParams({
                'accountId': component.get("v.uploadFilesSelectedAccId"),
                formName: 'UploadFilesAccountSelector.cmp'
            });
            
            $A.enqueueAction(getPEOChecklist);
        }
        else {
            component.set("v.currentPEOChecklist", component.get("v.parentPEOChecklist"));
            component.set("v.currentPEOMedicalChecklist", component.get("v.PEOMedicalChecklist"));
            console.log("UploadFilesAccountSelector Parent Account Checking Which Files Are Needed.");
            this.checkWhichFilesNeeded(component, event);
            
            component.set("v.loadedChecklist", true);
            }
    },
    
    checkWhichFilesNeeded : function(component, event) {
        //Added by Jidesh:Start
        var chklstPar = component.get("v.parentPEOChecklist");
        var chldChklst = component.get("v.currentPEOChecklist");
        //if(component.get("v.medicalRequested")  === true )component.set("v.misMedReqd", true);
        console.log('Claims_Report_required__c reqd:'+chldChklst.Claims_Report_required__c);
        if(chldChklst.CensusRequired__c === true)component.set('v.censusRequired', true)
        else component.set('v.censusRequired', false)
        if(chldChklst.Claims_Report_required__c === true)component.set('v.claimsReportRequired', true)
        else component.set('v.claimsReportRequired', false)
        if(chldChklst.Health_Insurance_Renewal_required__c === true)component.set('v.hlthInsRenwReqd', true)
        else component.set('v.hlthInsRenwReqd', false)
        if(chldChklst.Health_Insurance_Summary_required__c === true)component.set('v.hlthInsSummReqd', true)
        else component.set('v.hlthInsSummReqd', false)
        if(chldChklst.Health_Invoice_required__c === true)component.set('v.hlthInvReqd', true)
        else component.set('v.hlthInvReqd', false)
        if(chldChklst.Loss_Runs_required__c === true)component.set('v.lossRunsReqd', true)
        else component.set('v.lossRunsReqd', false)
        if(chldChklst.Payroll_Register_Required__c === true)component.set('v.payrollRegReqd', true)
        else component.set('v.payrollRegReqd', false)
        if(chldChklst.SUI_Required__c === true)component.set('v.suiReqd', true)
        else component.set('v.suiReqd', false)
        if(chldChklst.WC_Declarations_Required__c === true)component.set('v.wcDecReqd', true)
        else component.set('v.wcDecReqd', false)
        if(chldChklst.WCClassesWages_Required__c === true)component.set('v.wcClsNWgsReqd', true)
        else component.set('v.wcClsNWgsReqd', false)
        console.log('File needed - WCClassesWages_Required__c:'+chklstPar.WCClassesWages_Required__c);
        //Added by Jidesh:End
        
    },
    
    submitAllDocuments : function(component, event, helper) {
        component.set('v.docsAssigned', false);
        var submitDocuments = component.get('c.submitForReview');
        let experience;
        if (component.get("v.commUser")) experience = component.get("v.commUser").Community_Audience__c;
        else if (component.get("v.experienceChosen")) experience = component.get("v.experienceChosen");
        else experience = component.get("v.parentPEOChecklist").Experience__c;
        
        console.log('component.get("v.experienceChosen") = ' + component.get("v.experienceChosen"));
        if(component.get("v.experienceChosen") != null && component.get("v.experienceChosen") != '' && component.get("v.experienceChosen") != undefined) {
            submitDocuments.setParams({  
                "parentOnbChecklist": component.get("v.parentPEOChecklist"),
                "currentUser" : component.get("v.currentRunningUser"),
                "chosenExperience" : experience,
                "strategicAccountPartner" : component.get("v.strategicAccountUser"),
                formName: 'UploadFilesAccountSelector.cmp'
            });
        }
        else {
            submitDocuments.setParams({  
                "parentOnbChecklist": component.get("v.parentPEOChecklist"),
                "currentUser" : component.get("v.currentRunningUser"),
                "strategicAccountPartner" : component.get("v.strategicAccountUser"),
                formName: 'UploadFilesAccountSelector.cmp'
            });
        }
        
        submitDocuments.setCallback(this,function(response){
            component.set('v.docsAssigned', true);
            var state = response.getState();  
            if(state=='SUCCESS'){
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
                console.log('Method unsuccessful');
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
    
    getSubmissionStatus : function(component, event, helper) {
        //console.log('peo id:'+component.get("v.parentPEOChecklist").Id);
        var submissionStatus = component.get('c.getSubmissionStatus');
        submissionStatus.setParams({
            "peoFullChecklistId": component.get("v.parentPEOChecklist").Id
        });
        submissionStatus.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){
                if(response.getReturnValue()[0].PEO_Checklist_submission_status__c == 'Submitted') {
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
    
    //sfdc : sp13
    getPEOchecklistDetails : function(component, event, helper){
        
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
    },
    
    saveFormProgress : function(component, event, helper) {
        //console.log('saveChecklist:'+component.get('v.PEOCheckListData').PEO_Medical_Pre_Qualifier__c);
        try {
            var saveChecklist = component.get("c.savePeoOnboardingChecklist");
            saveChecklist.setParams({
                'peoOnbChecklist': component.get("v.PEOCheckListData"),
                formName: 'UploadFilesAccountSelector.cmp'
            });
            saveChecklist.setCallback(this, function(data) {
                var state = data.getState();
                if (state === "SUCCESS") {
                    //this.displayMsg('Success saving', 'Your progress has been saved', 'success', null);
                    //console.Log('PEO Medical pre qualifier and Sales notes have been saved');
                }
                else if (!data.getReturnValue())
                {
                    //console.Error('PEO Medical pre qualifier and Sales notes have not been saved');
                    //this.displayMsg('Error saving record', 'Record not saved. Please refresh the page and try again.\nIf the error persists reach out to your admin', 'error');                     
                }
                
            });
            $A.enqueueAction(saveChecklist);
        }
        catch(err) {
            // alert('Form answers may not have been saved properly.');
        }
    },
})