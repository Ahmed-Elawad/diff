({
    getSubmissionStatusJs : function(component, event, helper) {
        //debugger;
        console.log('peo idparentPEOChecklist:'+component.get("v.parentPEOChecklist"));
        console.log('peo id:'+component.get("v.PEOCheckListData"));
        var submissionStatus = component.get('c.getSubmissionStatus');
        submissionStatus.setParams({
            "peoFullChecklistId": component.get("v.parentPEOChecklist").Id
        });
        console.log('this is the print test');
        submissionStatus.setCallback(this,function(response){  
            console.log('this is the set callback test for getSubmissionStatusJs');
            var state = response.getState();  
            if(state=='SUCCESS'){
                console.log('response.getReturnValue'+JSON.stringify(response.getReturnValue()));
                if(response.getReturnValue()[0].PEO_Checklist_submission_status__c == 'Submitted') {
                    
                    //disableFinishButton
                    component.set('v.disableFinishButton',true);
                    component.set('v.submissionStatus',response.getReturnValue()[0].PEO_Checklist_submission_status__c);
                    if(response.getReturnValue()[0].Sales_Analyst__r){
                        component.set('v.submittedAnalyst',response.getReturnValue()[0].Sales_Analyst__r.Name);
                    }
                    
                    if(component.get('v.finishButtonClicked'))$A.util.addClass(component.find("disablebuttonidTag"), "slds-hide");
                    if(component.get('v.finishButtonClicked'))$A.util.addClass(component.find("toggle0"), "slds-hide");
                    //Hiding the button and tag on load if already submitted
                    if(!component.get('v.finishButtonClicked'))$A.util.addClass(component.find("disablebuttonidTag"), "slds-hide");
                    if(!component.get('v.finishButtonClicked'))$A.util.addClass(component.find("toggle0"), "slds-hide");
                    $A.util.removeClass(component.find("toggle1"), "slds-hide");
                    
                }
                else{
                    //console.log('inside success response else owner details:'+response.getReturnValue()[0].Owner.Name);
                    //component.set('v.submittedAnalyst',response.getReturnValue()[0].Sales_Analyst__r.Name);
                    console.log('response.getReturnValue'+response.getReturnValue());
                    /*if(response.getReturnValue()[0].pkzPEOUnderwritingChecklistID__c == null){
                        component.set('v.disableFinishButton',true);
                    }*/
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
                console.log('Analyst retrieved:'+component.get('v.submittedAnalyst'));
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
        //jc remove after
        console.log('Submit for Review ' + submitDocuments);
                
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
        
        helper.saveFormProgress(component, event, helper);

        submitDocuments.setParams({  
            "parentOnbChecklist": component.get("v.PEOCheckListData"),
            "currentUser" : component.get("v.currentRunningUser"),
            "strategicAccountPartner" : component.get("v.strategicAccountUser"),
            formName: 'SubmitForm.cmp'
        });
        
        submitDocuments.setCallback(this,function(response){
            component.set('v.docsAssigned', true);
            var state = response.getState();  
            //jc remove after 
            console.log('state ' + state);

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
                    helper.getSubmissionStatusJs(component, event, helper); 
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
                    helper.getSubmissionStatusJs(component, event, helper); 
                }
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
    
    getAllChecklists : function(component, event, helper){
        var action = component.get("c.getPEOchecklists");
        action.setParams({  
            "allAccounts": component.get('v.accountList')
        });
        
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state == 'SUCCESS'){
                var result = response.getReturnValue();
                 let numberOfAccounts = result.reduce((count, checklist) => count + checklist.Prospect_Client__r ? 1 : 0, 0)
                for(let i = 0; i < result.length; i++){
                    let companyInfoCompleted = helper.checkCompanyInfoTabFields(result[i], result[i].Prospect_Client__r, numberOfAccounts);
                    let additionalInfoCompleted = helper.checkAdditionalDetailsFields(result[i], result[i].Prospect_Client__r, numberOfAccounts);
                    component.set('v.isCompanyInfoAYBFilled', companyInfoCompleted);
                    component.set('v.isCompanyInfoADFilled', additionalInfoCompleted);
                    if (!companyInfoCompleted || !additionalInfoCompleted) break;
                }
                /*
                 *  for(let i = 0; i < result.length; i++){
                    let requireCompanyInfo = result[i].Company_Info_About_Your_Business_Form__c == undefined || result[i].Company_Info_About_Your_Business_Form__c == 'Pending';
                    if(requireCompanyInfo || (!setCompletedCompanyInfoToFalse && !result[i].Prospect_Client__r.Federal_ID_Number__c)){
                        component.set('v.isCompanyInfoAYBFilled', false);
                        setCompletedCompanyInfoToFalse = true;
                    }else if (!setCompletedCompanyInfoToFalse && result[i].Company_Info_About_Your_Business_Form__c == 'Complete'){
                        component.set('v.isCompanyInfoAYBFilled', true);
                    }
                    if(result[i].Company_Info_Addt_Details_Form__c == undefined || result[i].Company_Info_Addt_Details_Form__c == 'Pending'){
                        component.set('v.isCompanyInfoADFilled', false);
                    }else if(result[i].Company_Info_Addt_Details_Form__c == 'Complete'){
                        component.set('v.isCompanyInfoADFilled', true);
                    }
                }
                 */ 
            }
        });
        $A.enqueueAction(action);
    },
     checkAdditionalDetailsFields: function(checklist, Account, numberOfAccounts) {
        let isParent = Account.isParent__c || (!Account.isParent__c && Account.SalesParent__c == undefined),
            isAddOn = checklist.Client_Add_on__c,
            haveMedical = checklist.Is_Medical_Underwriting_Requested__c == 'Currently have Medical, please quote',
            optionalMedical = haveMedical || checklist.Is_Medical_Underwriting_Requested__c == 'Currently does not have Medical, please quote';
        if ( (isParent || isAddOn) && !checklist.Total_Number_of_Employees__c) return false;
        if ( (isParent || isAddOn) && !Account.Website) return false;
        if ( (isParent || isAddOn) && numberOfAccounts > 1 && !checklist.Ownership_Structure__c) return false;
        if ( (isParent || isAddOn) && !checklist.Currently_using_a_PEO__c) return false;
        if ( (isParent || isAddOn) && checklist.Currently_using_a_PEO__c === 'Yes' && !checklist.Current_PEO_Provider__c) return false;
        if ( (isParent || isAddOn) && checklist.Currently_using_a_PEO__c === 'No' && !checklist.Previous_Paychex_PEO_Oasis_HROI_client__c) return false;
        if ( (isParent || isAddOn) && haveMedical && !checklist.Medical_Carriers_currently_in_use__c) return false;
        if ( (isParent || isAddOn) && haveMedical && !checklist.Is_Your_Plan_Self_Funded_or_Level_Funded__c) return false;
        if ( (isParent || isAddOn) && haveMedical && !checklist.medical_coverage_renewal_date__c) return false;
        if ( (isParent || isAddOn) && optionalMedical && !checklist.Benefit_Effective_Date__c) return false;
        if ( (isParent || isAddOn) && optionalMedical && !checklist.Headquarter_State__c) return false;
        if ( (isParent || isAddOn) && !checklist.state_with_most_employees__c) return false;
        if ( (isParent || isAddOn) && !checklist.description_principle_product_business__c) return false;
        if ( (isParent || isAddOn) && !checklist.had_wrkrs_comp_claim_past_3_yrs__c) return false;
        return true;
    },
    checkCompanyInfoTabFields: function(checklist, Account, numberOfAccounts) {
        let isParent = Account.isParent__c || (!Account.isParent__c && Account.SalesParent__c == undefined),
            isAddOn = checklist.Client_Add_on__c,
            haveMedical = checklist.Is_Medical_Underwriting_Requested__c == 'Currently have Medical, please quote',
            optionalMedical = haveMedical || checklist.Is_Medical_Underwriting_Requested__c == 'Currently does not have Medical, please quote';
        if (!Account.Name) return false
        if (checklist.Platform__c === 'Oasis' && !Account.DBA__c) return false
        if (!Account.Federal_ID_Number__c) return false;
        if (!Account.Phone) return false;
        if (!Account.ShippingStreet) return false;
        if (!Account.ShippingCity) return false;
        if (!Account.ShippingState) return false;
        if (!Account.ShippingPostalCode) return false;
        if (!Account.NAICS_Code__c) return false;
        return true;
    },
    getPEOchecklistDetailsJS : function(component, event, helper){
        //debugger;
        console.log('getPEOchecklistDetailsJS');
        let needIndSpecific = component.get('v.noIndustryFound');
        var action = component.get("c.getPEOchecklistDetails");
        action.setParams({  
            "accountId": component.get('v.parentRecId')
        });
        
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){  
                var result = response.getReturnValue();      
                result.Discrepancy_Communication_Method__c=true;
                component.set("v.PEOCheckListData",result); 
                
                /* Commenting out because if  pkzPEOUnderwritingChecklistID__c is null they should never be able to submit
                 * if(result.pkzPEOUnderwritingChecklistID__c == null && component.get("v.QQWCSubmit")){
                 */
                //Change for QQ submit blocker SFDC-23733  
                var isQuickQuote = false;
                var wcquickQuote = false;
                if(result){
                   isQuickQuote  = result.Medical_Underwriting_Path_Type__c != null && result.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical';
                    wcquickQuote = result.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp';
                }
                if(result.pkzPEOUnderwritingChecklistID__c == null && (isQuickQuote || wcquickQuote)) {
                    component.set('v.disableFinishButton',true);
                }
                component.set("v.PEOCheckListData",result); 
                console.log(result);
               var myCmp = component.find("refreshButton");
                var hasClass = $A.util.hasClass(myCmp, "rotate");
                console.log('getPEOchecklistDetailsJS hasClass:'+hasClass);
                if(!hasClass){
                    console.log('removing rotate 1');
                    $A.util.addClass(myCmp, "rotate");
                    //$A.util.removeClass(component.find("refreshButton"), "rotate");
                }
                else{
                    console.log('removing rotate 2');
                    $A.util.removeClass(myCmp, "rotate");
                }
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
    
    getRequiredDocumentsData: function(component, event, helper){
        var action = component.get("c.getPEODocumentDetails");
        action.setParams({  
            "checklistId": component.get('v.parentPEOChecklist').Id
        });
        
        action.setCallback(this,function(response){
            var state = response.getState();  
            if(state=='SUCCESS'){  
                var result = response.getReturnValue();
                component.set('v.allDocumentsUploaded', result);
            }
            component.set('v.init2', true);
        });
        
        
        $A.enqueueAction(action);
    },
    
    checkForRequiredQuestionnaireStatus: function(component, e, helper) {
        //debugger;
        // get the questionnaires/statuses needed to determine success/failure
        let incompleteForms = [];
        let questionnaire = component.get('v.parentPEOChecklist');
        let needCovid = component.get('v.needCovidQuestionnaire');
        let needIndSpecific = component.get('v.noIndustryFound');
        let indStruct = component.get('v.industryStruct');
        let indRec;
        if(indStruct != null) indRec = indStruct.industryRec;
        
        // check for workers comp questionnaire - Medical journey
       // if (questionnaire.Peo_WC_formStatus__c !== 'Complete') incompleteForms.push('Workers Compensation Questionnaire');
        
        // check for industry specific questionnaire
        if (needIndSpecific && indRec && indRec.Peo_IndSpecific_formStatus__c != 'Complete') incompleteForms.push('Industry Specific Questionaire');
        
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
    
    validateWCFields : function (component, event, helper){
        console.log('validateWCFields');
        let questionnaire = component.get('v.parentPEOChecklist');
        return new Promise(function(resolve, reject) {
            let questionnaire = component.get('v.parentPEOChecklist');
         //   console.log(questionnaire);
             let WCFields = [{Name:'has_Union_Employees_on_Payroll__c'},
        {Name:'bid_or_do_government_work__c'},
       	{Name:'employees_employer_rule_subjectivity__c', ParentField:'bid_or_do_government_work__c', ParentValue:'Yes'},
        //{Name:'exposure_to_gvt_rules_or_sovrgn_immunity__c', ParentField:'bid_or_do_government_work__c', ParentValue:'Yes'},
        {Name:'default_gvt_contractor_decision__c', ParentField:'bid_or_do_government_work__c', ParentValue:'Yes'},
        {Name:'use_of_service_disqualifies_emp__c', ParentField:'bid_or_do_government_work__c', ParentValue:'Yes'},  
        {Name:'Assert_sovereign_immunity__c', ParentField:'bid_or_do_government_work__c', ParentValue:'Yes'},  
        {Name:'has_non_w2_wrkrs__c'},
		{Name:'number_of_volunteers__c', ParentField:'has_non_w2_wrkrs__c', ParentValue:'Yes'},
        {Name:'has_sprt_policy_for_donated_labor__c', ParentField:'has_non_w2_wrkrs__c', ParentValue:'Yes'},
        {Name:'number_of_seasonal_wrkrs__c', ParentField:'has_non_w2_wrkrs__c', ParentValue:'Yes'}, 
        {Name:'Has_active_Ohio_WC_Policy__c'},
		{Name:'OH_WC_Policy_number__c', ParentField:'Has_active_Ohio_WC_Policy__c', ParentValue:'Yes'},
        {Name:'Allow_PEO_admin_OH_WC_Policy__c', ParentField:'Has_active_Ohio_WC_Policy__c', ParentValue:'Yes'},
        {Name:'Subcontractors_1099_ind_contractors__c'},                
        {Name:'Percentage_of_subcontracted_work__c', ParentField:'Subcontractors_1099_ind_contractors__c', ParentValue:'Yes'},
        {Name:'How_many_subcontractors__c', ParentField:'Subcontractors_1099_ind_contractors__c', ParentValue:'Yes'},
        {Name:'What_services_are_subcontracted__c', ParentField:'Subcontractors_1099_ind_contractors__c', ParentValue:'Yes'},
        {Name:'subcntractrs_insured_wrkrs_comp__c', ParentField:'Subcontractors_1099_ind_contractors__c', ParentValue:'Yes'},
        {Name:'Subcontractors_req_to_provide_a_foreman__c', ParentField:'subcntractrs_insured_wrkrs_comp__c', ParentValue:'Yes'},
        {Name:'occurance_of_coi_updates__c', ParentField:'subcntractrs_insured_wrkrs_comp__c', ParentValue:'Yes'},
        {Name:'wrk_underground_or_10_ft_above__c'},  
        {Name:'Type_of_work_is_done_at_these_places__c', ParentField:'wrk_underground_or_10_ft_above__c', ParentValue:'Yes'},            
       	{Name:'Maximum_height_applicants_work_from__c', ParentField:'wrk_underground_or_10_ft_above__c', ParentValue:'Yes'},            
      	{Name:'Any_bucket_trucks_or_scaffolding_used__c', ParentField:'wrk_underground_or_10_ft_above__c', ParentValue:'Yes'},            
     	{Name:'info_wrk_underground_or_10_ft_above__c', ParentField:'Any_bucket_trucks_or_scaffolding_used__c', ParentValue:'Yes'},
        {Name:'Safety_Equipment_and_training_provided__c', ParentField:'wrk_underground_or_10_ft_above__c', ParentValue:'Yes'}, 
                        {Name:'emp_drive_for_business_purposes__c'},  
        {Name:'prsnl_driver_record_verification__c', ParentField:'emp_drive_for_business_purposes__c', ParentValue:'Yes'},            
       	{Name:'prsnl_driver_driving_radius__c', ParentField:'emp_drive_for_business_purposes__c', ParentValue:'Yes'},            
      	{Name:'Max_num_of_employees_allowed_per_vehicle__c', ParentField:'emp_drive_for_business_purposes__c', ParentValue:'Yes'}            
     	                       ];
                        let isValid=true;
                        WCFields.every(fld=>{ 
                            console.log(fld);
                            console.log(questionnaire[fld.Name]);
                        if(fld.ParentField==undefined && (questionnaire[fld.Name]==null || questionnaire[fld.Name]=='' || questionnaire[fld.Name]==undefined))
                        {
                            console.log('1');
                            isValid=false;
                            return false;
                        }
        				if(isValid && fld.ParentField!=undefined)
                            {	  
                            console.log('2 parent value: ', questionnaire[fld.ParentField]);
                            if(questionnaire[fld.ParentField]!=undefined)
                            {
                            	if(questionnaire[fld.ParentField].substring(0,3)==fld.ParentValue
                                && (questionnaire[fld.Name]===null || questionnaire[fld.Name]==='' 
                            			|| questionnaire[fld.Name]===undefined)){
                                      isValid=false;
                                    return false;
                                 }
                        	}
                                                           
                        }
        						return true;
                        });
        console.log('validateWCFields: ' , isValid);
        	if (isValid){
                if(!component.get('v.isCommunityUser')){
                	if(component.get('v.noIndustryFound')){
                		resolve(true);
                	}else{
                        if(component.get('v.PEOCheckListData').Peo_IndSpecific_formStatus__c == 'Complete'){
                            resolve(true);
                        }else{
                            reject({t: 'Industry Specific Questionnaire', m:'All fields are Required in Industry Specific Questionnaire', ty:'error'});
                        }
                	}
                }
                resolve(true); 
            } 
            else{
                reject({t: 'Workers Compensation', m:'All fields are Required in Workers Compensation', ty:'error'});
            }        	
        });
    },
    
    //backup method for any medical related validation on submit screen
    //In future if there is any validation required for Medical, add the logic here
    validateFields: function(component, event, helper) {
        return new Promise(function(resolve, reject) {
           // debugger;
            let valid = true;
            console.log('valid: '+valid);
            if (valid){
                console.log('field valid')
                resolve(true); 
            } 
            else{
                console.log('field invalid')
                reject({t: 'Field error', m:'Please provide value for required fields', ty:'error'});
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

    submitCensusflip : function(component, event, helper){
        component.set('v.disableFinishButton',true);  
       var action =  component.get('c.submitDocsToClientSpaceAll');
       var checkListId = component.get("v.parentPEOChecklist.Id");
        var isQQWC =  component.get("v.QQWCSubmit");
        
       action.setParams({
           checkListId : checkListId,
           isQQWC: isQQWC
       });
       action.setCallback(this, function(response){
            var state  = response.getState();
            if(state == 'SUCCESS'){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Submission is done!",
                    "type" : "success"
                });
                toastEvent.fire();
            
                console.log('changed to all');
            }
            else{
                 component.set('v.disableFinishButton',false); 
                console.log('There was an error in Submitting Quick quote census document');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "There was an error",
                    "type" : "error"
                });
                toastEvent.fire();
            }
       });

       $A.enqueueAction(action);
    }
})