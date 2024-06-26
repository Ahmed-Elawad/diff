({
    /////////////Data Retrieval Methods////////////////////
    
    createNewUser: function(cmp, e) {
        cmp.set('v.step', 1);
        return new Promise(function(resolve, reject) {
            let create = cmp.get('c.createCommunityUserNew');
            create.setParams({
                uName: cmp.find("communityUsername").get("v.value"),
                nickName: cmp.find('communityNickName').get('v.value'),
                conId: cmp.get('v.recordId'),
                alias: cmp.find('alias').get('v.value'),
                communityMessage: cmp.get('v.community_Welcome_Messsage__c'),
                inviteDate:cmp.get('v.welcomeEmailDate')
            });
            
            create.setCallback(this, function(res) {
                if (res.getState() !== 'SUCCESS' || !res.getReturnValue() || res.getReturnValue().length < 18) {
                    console.log(res.getError())
                    reject({
                        t: 'User creation error',
                        m: 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                        ty: 'error',
                        broke: false 
                    });
                }
                resolve(true);
            });
            
            $A.enqueueAction(create);
        });
    },
    reactivateUser: function(component, e, helper) {
        component.set('v.step', 1);
        return new Promise(function(resolve, reject) {
            console.log('callReactivateUser in promise');
            let reactivate = component.get('c.reactivateCommunityUser');
            reactivate.setParams({
                u: component.get("v.communityUser")
            });
            
            reactivate.setCallback(this, function(res) {
                let saveResult = res.getReturnValue();
                //TO DO, error while hitting .has
                if (res.getState() !== 'SUCCESS' || !saveResult) {
                    console.log('callReactivateUser js error'+res.getError());
                    reject({
                        t: 'User reactivation error',
                        m: 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                        ty: 'error',
                        broke: false 
                    });
                }
                resolve(true);
            });
            
            $A.enqueueAction(reactivate);
        });
    },
    
    checkPayxEmail: function(component, e,helper){
        console.log('checkPayxEmail');
        return new Promise(function(resolve, reject) {
            let missingPermission = component.get('v.missingPermissionList');
            console.log('missingPermission'+missingPermission);
            let startingContact = component.get('v.contactRec');
            console.log('startingContact'+startingContact);            
            console.log('missingPermission: '+missingPermission+ 'startingContact.email: '+startingContact.Email);
            if(missingPermission!= null && missingPermission.length>0 && missingPermission.includes('Paychex Email') 
               && (startingContact.Email.toLowerCase().includes('paychex') || startingContact.Email.toLowerCase().includes('oasis'))){
                component.set('v.disableContinue',true);
                let t = 'Validation Error';
                let m = 'You cannot create a community user with a paychex or oasisadvantage email address';
                let ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            resolve(true);
        })
    },
    /////////////Navigation/Utility Methods/////////////////
    /*openForm: function(cmp, e, helper) {
        let evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:PEOUWcommunityForms",
            componentAttributes: {
                recordId : cmp.get("v.accountID")
            }
        });        
        evt.fire();        
    },*
    displayMsg: function(title, msg, type, duration) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: msg,
            type: type
        });
        toastEvent.fire();
    },
    updateViewToStep1 : function(cmp, e) {
        cmp.set('v.step', 1);
    },
    clearForm: function(component, event, helper) {
        component.set('v.WCUnderwritingVal', '');
        component.set('v.WCFastPass', '');
        component.set('v.WCInTargetHazardGroup', '');
        component.set('v.v.WCPremiumUnderLimit', '');
    },
    /*closeAction: function() {
        $A.get("e.force:closeQuickAction").fire();
    },*/
    closeModal: function(cmp, e, helper) {
        //debugger;
        cmp.set('v.closeModal',true); 
    },
    closeAction: function(cmp, e, helper) {
        //debugger;
        console.log('inside closeAction');
        
        $A.get('e.force:refreshView').fire();
        $A.get('e.force:closeQuickAction').fire();
    },
    updateView : function(cmp, e) {
        cmp.set('v.step', 2);
    },
    loadCmp:function(component, event, helper) {
        //debugger;
        var fieldsMissing = component.get('v.fieldsMissing');
        if(!fieldsMissing){
            var evt = $A.get("event.force:navigateToComponent");
            //console.log('Event '+evt);
            var accountFromId = component.get("v.recordId");
            evt.setParams({
                componentDef  : "c:communityForms" ,
                componentAttributes : {
                    recordId : component.get("v.recordId"),
                    requestedMedical :component.get("v.medicalRequestedVal"),
                    WCFastPass :component.get("v.FastPass")
                }
                
            });
            evt.fire();
        }
    },
    handleError: function(data, cmp) {
        var event = $A.get("e.force:showToast");
        let toastParams = {
            title: data.t,
            message: data.m,
            type: data.ty
        }
        if (cmp && (cmp.get('v.toastMode') !== undefined)) toastParams.mode = cmp.get('v.toastMode');
        
        event.setParams(toastParams);
        event.fire();
        
        if (data.broke) $A.get("e.force:closeQuickAction").fire();
    },
    handleInitialError: function(data,cmp) {
        var event = $A.get("e.force:showToast");
        event.setParams({
            title: data.t,
            message: data.m,
            mode: cmp.get('v.toastMode'),
            type: data.ty
        });
        event.fire();
        
        if (data.broke) $A.get("e.force:closeQuickAction").fire();
    },
    loadSpinner: function(cmp) {
        let shown = cmp.get("v.waitingForResp");
        cmp.set("v.waitingForResp", !shown);
    },
    
    showUserMsg: function(cmp, err) {
        console.log('Should show msg')
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: err.t,
            message: err.m,
            type: err.ty
        });
        toastEvent.fire(); 
    },
    
    //JS promises 9953
    helperFunctionAsPromise : function(component, event, helper, helperFunction) {
        return new Promise($A.getCallback(function(resolve, reject) {
            helperFunction(component, event, helper, resolve, reject);
        }));
    },
    
    validateAdditionalQuestionFields : function(component, event, helper, resolve, reject) {
        
        console.log('Inside validateAdditionalQuestionFields');
        var fieldsMissing = 0;
        var medicalRequested = component.get('v.medicalRequestedVal');
        var submitToWCUnderwriting = component.get('v.WCUnderwritingVal');
        var medicalPath = component.get('v.medicalUwPath');
        var platformVal = component.get('v.platformVal');
        var currentAffiliationVal = component.get('v.currentAffiliationVal');
        var clientNumberVal = component.get('v.clientNumberVal');
        var paychexAgencyClientVal = component.get('v.paychexAgencyClientVal');
        var parentCompanyLegalNameVal = component.get('v.parentCompanyLegalNameVal');
        var parentCompanyPaychexVal = component.get('v.parentCompanyPaychexVal');
        var parentCurrentlyHaveApprovalVal = component.get('v.parentCurrentlyHaveApprovalVal');
        var isMedicalRequestedVal = component.get('v.isMedicalRequestedVal');
        var fullUnderwritingPathVal = component.get('v.fullUnderwritingPathVal');
        var WhyareyouchoosingVal = component.get('v.WhyareyouchoosingVal');
        //console.log('validateAdditionalQuestionFields medicalRequested: '+medicalRequested+' fastpass: '+fastPass);
        /*if(medicalRequested === undefined || medicalRequested =='default'){
            console.log('missing med');
            fieldsMissing+=1;
        }*/ 
        //No longer needed as part of HSF submission
        /*if(medicalRequested === 'Yes'){
           	var medPath = component.get('v.medicalUwPath');
            if(medPath === undefined || medPath == 'default' || medPath == ''){
            	console.log('missing med path');
                fieldsMissing+=1;
            }
        }
        if(submitToWCUnderwriting === undefined || submitToWCUnderwriting == 'default') {
            console.log('missing WC Underwriting');
            fieldsMissing+=1;
        }
        if(submitToWCUnderwriting == 'Yes - WC to be reviewed') {
            var fastPass = component.get('v.WCFastPass');
            if(fastPass === undefined || fastPass == 'default'){
                console.log('missing fast pass');
                fieldsMissing+=1;
            }
            if(fastPass == 'Yes'){
                var targetHazardGroup = component.get('v.WCInTargetHazardGroup');
                var WCPremiumUnderLimit = component.get('v.WCPremiumUnderLimit');
                if(targetHazardGroup == 'default' || WCPremiumUnderLimit == 'default'){
                    console.log('missing hazard');
                    console.log('targetHazardGroup: '+targetHazardGroup);
                    console.log('WCPremiumUnderLimit: '+WCPremiumUnderLimit);
                    fieldsMissing+=1;
                }
            }
        }*/
        if(platformVal == 'default' || platformVal === undefined){
            console.log('missing platformval');
            fieldsMissing+=1;
        }
        if(currentAffiliationVal == 'default' || currentAffiliationVal == '' || currentAffiliationVal === undefined){
            fieldsMissing+=1;
        }
        if(currentAffiliationVal != 'default' && currentAffiliationVal == 'Paychex Payroll/ASO Client'){
            if(clientNumberVal == null || clientNumberVal == ''){
                fieldsMissing+=1;
            }
            if(paychexAgencyClientVal == 'default' || paychexAgencyClientVal === undefined){
                fieldsMissing+=1;
            }
        }
        if(currentAffiliationVal != 'default' && currentAffiliationVal == 'Paychex PEO/Oasis PEO, Child Add-On'){
            if(parentCompanyLegalNameVal == null || parentCompanyLegalNameVal == ''){
                fieldsMissing+=1;
            }
            if(parentCompanyPaychexVal == null || parentCompanyPaychexVal == ''){
                fieldsMissing+=1;
            }
            if(parentCurrentlyHaveApprovalVal == 'default' || parentCurrentlyHaveApprovalVal === undefined){
                fieldsMissing+=1;
            }
        }
        if(isMedicalRequestedVal == 'default' || isMedicalRequestedVal === undefined){
            fieldsMissing+=1;
        }
        
        if(fullUnderwritingPathVal == 'default' || fullUnderwritingPathVal === undefined){
            fieldsMissing+=1;
        }
        if(fullUnderwritingPathVal != 'default' && fullUnderwritingPathVal == 'Yes'){
            if(WhyareyouchoosingVal == 'default' || WhyareyouchoosingVal === undefined){
                fieldsMissing+=1;
            }
        }
        console.log('validateAdditionalQuestionFields missingFieldCount'+fieldsMissing);
        if(fieldsMissing>0){
            component.set('v.fieldsMissing',true);
            let t = 'Failed to Proceed';
            let m = 'Please complete all required fields';
            let ty = 'Error';
            reject({t: t, m: m, ty: ty});
        }
        else{
            component.set('v.fieldsMissing',false);
        }
        resolve(true);
    },
    
    validateUserCreationFields: function(cmp, e, helper, resolve, reject) {
        console.log('Inside validateUserCreationFields');
        let verificationAction = cmp.get('c.verifyFields');
        let userName = cmp.find("communityUsername");
        let nickName = cmp.find('communityNickName');
        if(!userName || !nickName){
            reject({ 
                t:'Required Fields',
                m: 'Please enter a username and nickname to proceed',
                ty:'Error'
            });
        }
        verificationAction.setParams({
            uName: userName.get("v.value"),
            nickName: nickName.get('v.value')
        });
        verificationAction.setCallback(this, function(res){
            if (res.getState() !== 'SUCCESS') {
                console.log(res.getError())
                reject({ 
                    t:'Failed verification',
                    m: 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty:'Error',
                    broke:false
                });
            }
            console.log('validateUserCreationFields return val'+res.getReturnValue());
            if (res.getReturnValue() && res.getReturnValue().length) {
                var errorList = res.getReturnValue();
                var errorFields = errorList.length == 2 ? 'Username and Nickname' : errorList[0];
                console.log('validateUserCreationFields errorFields '+errorFields);
                reject({
                    t: 'Duplicate inputs',
                    m: errorFields+' must be unique',
                    ty:'warning',
                    broke:false
                });
            };
            
            resolve(true);
        });
        $A.enqueueAction(verificationAction); 
        
    },
    
    updateContactAndAcctWQ: function(cmp, e, helper, resolve, reject) {
        console.log('Inside updateContactAndAcctWQ');
        let updateRecsAction = cmp.get('c.updateContactAndAcctWorkqueue');
        var childAccountIdsForQueues = [];
        var childAccountSelection = cmp.get('v.childAccountSelection');
        var childAccountIds = [];
        if(childAccountSelection == 'No'){
            if(Array.isArray(cmp.get('v.childAccountId')) && cmp.get('v.childAccountId').length > 0){
                childAccountIds = cmp.get('v.childAccountId');		
            }else{		
                if(cmp.get('v.childAccountId') != 'None'){
                    childAccountIds = cmp.get('v.childAccountId').split(';');	
                }
            }
        }
        
        updateRecsAction.setParams({contactId: cmp.get('v.recordId'), 
                                    acctId: cmp.get('v.accountID'), 
                                    childAccountIdsForQueues: childAccountIds,
                                    childAccountSelection : childAccountSelection});
        updateRecsAction.setCallback(this, function(res) {
            let state = res.getState(), 
                err = res.getError(), 
                result = res.getReturnValue();
            if (state != 'SUCCESS') {
                let msg = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.';
                return reject({t: 'Error', m: msg, ty: 'Error'});
            }
            resolve(true);
        });
        $A.enqueueAction(updateRecsAction);
    },
    
    createQuestionnaire: function(cmp, e, helper, resolve, reject) {
        // Returns a promise the resolves on a checklist[& medical] being created
        // @Attributes: v.accountID(attaches to checklist), v.medicalReq(used to create medical if true)
        // Error: returns creation error if either medical or checklist fails
        // Notes: To early to create the record?
        // Should all creations be rolled back? or just the failed form?
        // Testing Err Notes: 
        //debugger;
        
        let createREC = cmp.get('c.createQuestionnaire');
        var createCommUser = cmp.get('v.createCommUser');
        var opp = cmp.get('v.opportunity');
        let chk = cmp.get('v.checklist');
        let contact = cmp.get('v.contactRec');
        var currentAffiliationVal = cmp.get('v.currentAffiliationVal');
        var fullUnderwritingPathVal = cmp.get('v.fullUnderwritingPathVal');
        var OldPathType;
        if(chk)
        {
           OldPathType=chk.Do_you_need_full_underwriting_path__c;
        }
        
        
        if(OldPathType=='Yes' && fullUnderwritingPathVal=='No'){
            var ChkDocs=cmp.get('v.checklistDocs');
            if(ChkDocs){
                let isdocsupdate=false;
            	ChkDocs.forEach(doc => {
                    if(doc.PEO_Doc_Required__c=='Needed' 
                    	&& (doc.Name=='Census' || doc.Name=='Medical Invoice') 
                    	&& (doc.Status__c!='Approved' && !$A.util.isUndefinedOrNull(doc.Status__c))){
                    		doc.Status__c='Approved';
                    		isdocsupdate=true;
                		}
                    });
                if(isdocsupdate){
                    console.log('Updated Checklist Docs' ,ChkDocs);
                    let updatechdocs = cmp.get('c.UpdatePEOOnboardingDocs');
                    updatechdocs.setParams({
                            peoonchkdocuments: ChkDocs
                        });
                        
                        updatechdocs.setCallback(this, function(res) {
                            });        
                        $A.enqueueAction(updatechdocs) ;
                }
            }            
        }
        
        let newPEO = {
            Prospect_Client__c: cmp.get('v.accountID'),
            Is_Medical_Underwriting_Requested__c: cmp.get('v.isMedicalRequestedVal')
        };
        var oldmed;
        var medAns = cmp.get('v.isMedicalRequestedVal');
        if(medAns == 'Currently have Medical, please quote' || medAns == 'Currently does not have Medical, please quote')
            oldmed = 'Yes';
        else
            oldmed = 'No'
         //Benchmark
         
        console.log('Display Benchmark tab:'+cmp.get('v.display_Benchmark_tab__c'));
        newPEO.Medical_Benefits_Underwriting_Requested__c = oldmed;
        newPEO.display_Benchmark_tab__c = cmp.get('v.display_Benchmark_tab__c');
        
        
         if (cmp.find('platform')) {
            newPEO.Platform__c = cmp.find('platform').get('v.value');
        }  
        if (cmp.find('currentAffiliation')) {
            newPEO.Current_Aff_with_Paychex_PEO_Oasis__c = cmp.find('currentAffiliation').get('v.value');
        }
        if(currentAffiliationVal != 'default' && currentAffiliationVal == 'Paychex Payroll/ASO Client'){
            if (cmp.find('clientNumber')) {
                newPEO.Client_Number__c = cmp.find('clientNumber').get('v.value');
            } 
            if (cmp.find('paychexAgencyClient')) {
                newPEO.Is_this_a_current_Paychex_Agency_Client__c = cmp.find('paychexAgencyClient').get('v.value');
            }
        }
        if(currentAffiliationVal != 'default' && currentAffiliationVal == 'Paychex PEO/Oasis PEO, Child Add-On'){
            if (cmp.find('parentCompanyLegalName')) {
                newPEO.Parent_Company_Legal_Name__c = cmp.find('parentCompanyLegalName').get('v.value');
            }
            if (cmp.find('parentCompanyPaychex')) {
                newPEO.Parent_Paychex_oasis_Num__c = cmp.find('parentCompanyPaychex').get('v.value');
            }
            if (cmp.find('parentCurrentlyHaveApproval')) {
                newPEO.Parent_appro_self_retain_workers_comp__c = cmp.find('parentCurrentlyHaveApproval').get('v.value');
            }
        }
        if (cmp.find('isMedicalRequested')) {
            newPEO.Is_Medical_Underwriting_Requested__c = cmp.find('isMedicalRequested').get('v.value');
        }
        if (cmp.find('fullUnderwritingPath')) {	
            
            newPEO.Do_you_need_full_underwriting_path__c = cmp.get('v.fullUnderwritingPathVal');
            if(cmp.get('v.medicalUWPathType') == '' || cmp.get('v.medicalUWPathType') == null || cmp.get('v.medicalUWPathType') == undefined){
                if(cmp.get('v.isMedicalRequestedVal') == 'Currently does not have Medical and not interested in Medical, do not quote'){
                    newPEO.Medical_Underwriting_Path_Type__c = 'No Medical Requested';	
                }else{
                    if(newPEO.Do_you_need_full_underwriting_path__c == 'Yes'){
                        newPEO.Medical_Underwriting_Path_Type__c = 'Traditional - Medical';
                    }else{
                        newPEO.Medical_Underwriting_Path_Type__c = 'Quick Quote - Medical';
                    }
                }
            }else{
                if(cmp.get('v.medicalUWPathType') == 'Salesforce Forced - Medical' || cmp.get('v.medicalUWPathType') == 'Clientspace Forced - Medical'){
                    if(cmp.get('v.isMedicalRequestedVal') == 'Currently does not have Medical and not interested in Medical, do not quote'){
                        newPEO.Medical_Underwriting_Path_Type__c = 'No Medical Requested';	
                    }else{
                        newPEO.Medical_Underwriting_Path_Type__c = cmp.get('v.medicalUWPathType');
                    }
                }else{
                    if(cmp.get('v.isMedicalRequestedVal') == 'Currently does not have Medical and not interested in Medical, do not quote'){
                        newPEO.Medical_Underwriting_Path_Type__c = 'No Medical Requested';	
                    }else{
                        if(newPEO.Do_you_need_full_underwriting_path__c == 'Yes'){
                            newPEO.Medical_Underwriting_Path_Type__c = 'Traditional - Medical';
                        }else{
                            newPEO.Medical_Underwriting_Path_Type__c = 'Quick Quote - Medical';
                        }
                    }
                }
            }
            if(cmp.get('v.workersCompUWPathType') == '' || cmp.get('v.workersCompUWPathType') == null || cmp.get('v.workersCompUWPathType') == undefined){
                if(newPEO.Do_you_need_full_underwriting_path__c == 'Yes'){
                    newPEO.Workers_Comp_Underwriting_Path_Type__c = 'Traditional - Workers Comp';
                }else{
                    newPEO.Workers_Comp_Underwriting_Path_Type__c = 'Quick Quote - Workers Comp';
                }
            }else{
                if(cmp.get('v.workersCompUWPathType') == 'Salesforce Forced - Workers Comp' || cmp.get('v.workersCompUWPathType') == 'Clientspace Forced - Workers Comp'){
                    newPEO.Workers_Comp_Underwriting_Path_Type__c = cmp.get('v.workersCompUWPathType');
                }else{
                    if(newPEO.Do_you_need_full_underwriting_path__c == 'Yes'){
                        newPEO.Workers_Comp_Underwriting_Path_Type__c = 'Traditional - Workers Comp';
                    }else{
                        newPEO.Workers_Comp_Underwriting_Path_Type__c = 'Quick Quote - Workers Comp';
                    }
                }
            }
            
            /*if(cmp.get('v.medicalUWPathType') != 'Salesforce Forced - Medical' 
               && cmp.get('v.medicalUWPathType') != 'Clientspace Forced - Medical'){	
                if(cmp.get('v.isMedicalRequestedVal')== 'Currently does not have Medical and not interested in Medical, do not quote'){
                    // Setting the path type to No Medical based on isMedicalRequestedVal value
                    console.log('Not interested in Medical: Setting to No medical requested');
                    newPEO.Medical_Underwriting_Path_Type__c = 'No Medical Requested';	
                }
                else if(cmp.get('v.medicalUWPathType') != 'Quick Quote - Medical'){
                    console.log('Has Medical: Setting to QQ Medial');
                    newPEO.Medical_Underwriting_Path_Type__c = 'Quick Quote - Medical';
                }
                    else{
                        console.log('No change needed in the path type');
                    }
            }	*/
            //Adding the below :if: to make sure Path type is not reverted back to Quick quote WC Upon a rep entering the grey screen
            /*if(cmp.get('v.workersCompUWPathType') != 'Clientspace Forced - Workers Comp' && cmp.get('v.workersCompUWPathType') != 'Salesforce Forced - Workers Comp'){
                newPEO.Workers_Comp_Underwriting_Path_Type__c = 'Quick Quote - Workers Comp';
            }*/
        }
        if(fullUnderwritingPathVal != 'default' && fullUnderwritingPathVal == 'Yes'){
            if (cmp.find('Whyareyouchoosing')) {
                newPEO.why_choose_full_underwriting_path__c = cmp.get('v.WhyareyouchoosingVal');
                /*if(cmp.get('v.medicalUWPathType') != 'Traditional - Medical'){	
                    if(cmp.get('v.isMedicalRequestedVal') == 'Currently does not have Medical and not interested in Medical, do not quote'){
                        // Setting the path type to No Medical based on isMedicalRequestedVal value
                        console.log('Not interested in Medical Traditional: Setting to No medical requested');
                        newPEO.Medical_Underwriting_Path_Type__c = 'No Medical Requested';	
                    }
                    else if(cmp.get('v.medicalUWPathType') != 'Traditional - Medical'){
                        console.log('Has Medical: Setting to Traditional Medial');
                        newPEO.Medical_Underwriting_Path_Type__c = 'Traditional - Medical';
                    }
                        else{
                            console.log('Traditional: No change needed in the path type');
                        }
                }	
                newPEO.Workers_Comp_Underwriting_Path_Type__c = 'Traditional - Workers Comp';*/
            }
        }
        /*if (cmp.find('WCFastPass_Input')) {
            newPEO.Workers_Comp_FastPass__c = cmp.find('WCFastPass_Input').get('v.value');
        }
        if (cmp.find('Self_retain_reason__c')) {
            console.log(cmp.get('v.selfRetainReason'));
            newPEO.Self_retain_reason__c = cmp.find('Self_retain_reason__c').get('v.value');
        }*/
        //set these values if yes or no in case the value changes.     
        /*if (cmp.get('v.medicalRequestedVal') == 'Yes') {
            newPEO.Benefit_Effective_Date__c = cmp.find('effectiveDate').get('v.value');
            //newPEO.Medical_Underwriting_Path__c = cmp.find('medicalUwPath').get('v.value');
            //"Full Master Medical Submission"
            //Defaulting to Full master medical as part of HSF work
            //Custom label PEOUW_HSF_Med_UW_Path
            newPEO.Medical_Underwriting_Path__c = $A.get("$Label.c.PEOUW_HSF_Med_UW_Path");
            if (newPEO.Medical_Underwriting_Path__c == 'default') newPEO.Medical_Underwriting_Path__c = '';
        }
        else{
            newPEO.Benefit_Effective_Date__c=null;
            newPEO.Medical_Underwriting_Path__c='';
        }*/
        
        newPEO.Select_Child_Accounts__c = cmp.get('v.childAccountSelection');		
        if(Array.isArray(cmp.get('v.childAccountId')) && cmp.get('v.childAccountId').length > 0){		
            newPEO.Child_Account_Ids__c = cmp.get('v.childAccountId').join(';');		
        }else{		
            newPEO.Child_Account_Ids__c = cmp.get('v.childAccountId');		
        }		
        		
        if(newPEO.Select_Child_Accounts__c == 'Yes'){		
            newPEO.Child_Account_Ids__c = '';		
        }
        
        /*if (cmp.get('v.WCFastPass') == 'Yes') {
            newPEO.WC_Codes_are_in_Target_Hazard_Group__c = cmp.find('WCInTargetHazardGroup_Input').get('v.value');
            newPEO.WC_Premium_is_less_than_10_000__c = cmp.find('WCPremiumUnderLimit_Input').get('v.value');
        }*/
        
        if(cmp.get('v.createCommUser') == 'No'){
            newPEO.Reason_Why_You_Are_Not_Inviting_Prospect__c = cmp.get('v.reasonNotInvitingPro');
            newPEO.Please_Explain__c = cmp.get('v.pleaseExplain');
        }
        
        //newPEO.Submit_to_Workers_Comp_Underwriting__c = cmp.find('submitToWCUnderwriting').get('v.value');
        //newPEO.Health_Benefits_Currently_through_a_PEO__c = cmp.find('prspctPeoUltlzn').get('v.value');
        //newPEO.Medical_Underwriting_Path_Option__c = cmp.get('v.medicalUnderwritingPathVal');
        //debugger;
        //set the value of PEO_NSC__c in underwriting checklist if the logged in user is NSC
        if(cmp.get('v.runningUser').Sales_Division__c == 'NSC'){
            newPEO.PEO_NSC__c = cmp.get('v.runningUser').Id;
        }
        
       	newPEO.Client_Add_on__c = cmp.get('v.isClientAddON');
        
        if (contact && contact.Account && contact.Account.Name) newPEO.Name = contact.Account.Name;
        if (opp){
            newPEO.Opportunity__c = opp.Id;
            if($A.util.isUndefinedOrNull(newPEO.Payroll_Frequency__c)){
                switch(opp.Frequency__c) {
                    case '12':
                        newPEO.Payroll_Frequency__c = '12 - Monthly';
                        break;
                    case '24':
                        newPEO.Payroll_Frequency__c = '24 - Semi-Monthly';
                        break;
                    case '26':
                        newPEO.Payroll_Frequency__c = '26 - Bi-Weekly';
                        break;
                    case '52':
                        newPEO.Payroll_Frequency__c = '52 - Weekly';
                        break;
                    default:
                        newPEO.Payroll_Frequency__c = '';
                }
			}
        } 
        
        if (chk) {
            if(newPEO.display_Benchmark_tab__c == true && (chk.display_Benchmark_tab__c == 'undefined'|| !chk.display_Benchmark_tab__c)){
                newPEO.display_Benchmark_tab__c = true;
            }
            if(newPEO.display_Benchmark_tab__c == false && chk.display_Benchmark_tab__c != newPEO.display_Benchmark_tab__c){
                newPEO.display_Benchmark_tab__c = false;
            }
            if (chk.Sales_Rep__c && !newPEO.Sales_Rep__c) newPEO.Sales_Rep__c = chk.Sales_Rep__c;
            if (chk.Id && !newPEO.Id) newPEO.Id = chk.Id;
            
            if (chk.Opportunity__r && chk.Opportunity__r.OwnerId 
                && chk.PEO_Checklist_submission_status__c!='Submitted') 
                	newPEO.OwnerId = chk.Opportunity__r.OwnerId;
            
            if (chk.Submit_to_Workers_Comp_Underwriting__c && !newPEO.Submit_to_Workers_Comp_Underwriting__c) newPEO.Submit_to_Workers_Comp_Underwriting__c = chk.Submit_to_Workers_Comp_Underwriting__c;
            //if (chk.Medical_Underwriting_Path__c && !newPEO.Medical_Underwriting_Path__c) newPEO.Medical_Underwriting_Path__c = chk.Medical_Underwriting_Path__c;
        } else if (cmp.get('v.runningUser') && cmp.get('v.runningUser').Id) {
            newPEO.Sales_Rep__c = (opp && opp.OwnerId ? opp.OwnerId : cmp.get('v.runningUser').Id);
            newPEO.OwnerId = (opp && opp.OwnerId ? opp.OwnerId : cmp.get('v.runningUser').Id);
        }
        console.log("newPEO:")
        console.log(newPEO)
        createREC.setParams({
            peoOnbChecklist: newPEO,
            formName: 'ConvertContactToCommunityUser.cmp',
            oppty: opp
        });
        
        createREC.setCallback(this, function(res) {
            if (res.getState() !== 'SUCCESS') {
                reject({
                    t: 'Error',
                    m: 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty: 'error',
                    broke: false
                });
            }
            resolve(true);
        })
        
        $A.enqueueAction(createREC)  
    },
    
    
      /*getChecklistDocs: function(cmp, e, helper,resolve, reject) {
		var checklist=cmp.get('v.checklist');
        console.log('CKL-' + checklist);
        if(checklist){
            let DocsAction = cmp.get('c.getPEOOnboardingDocs');
            DocsAction.setParams({
                recordId: checklist.Id
                });
            DocsAction.setCallback(this, function(res) {				
                    if (res.getState() != 'SUCCESS') {
                        console.log(res.getError());
                        }
                    else{
                        console.log('getChecklistDocs:' ,res.getReturnValue());
                        cmp.set('v.checklistDocs', res.getReturnValue());
                    }	
                		resolve(true);
                    });
            $A.enqueueAction(DocsAction);       
        }
        else{
            resolve(true);
        }        
    },*/
    
    
    updateView : function(cmp, e, helper, resolve, reject) {
        cmp.set('v.step', 2);
        console.log('Inside updateView');
        resolve(true);	
    },
    
    updateSpinnerState: function(cmp, e, helper, resolve, reject) {
        // set the spinner view to the oposite of what it is now
        console.log('Inside updateSpinnerState');
        // Continously update the spinner for 5 seconds
        let updateLoading = function(cmp, cb, stillLoading) {
            
            console.log("cmp.get('v.progressRate')="+cmp.get('v.progressRate')+' stillLoading='+stillLoading);
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
                console.log('clearTimeout 628');
                clearTimeout(updateLoading);
            }
        }
        
        let showSpinner = cmp.get("v.waitingForResp");
        
        cmp.set("v.waitingForResp", !showSpinner);
        
        console.log('showSpinner='+showSpinner);
        if (!showSpinner) {
            let toastHelper = function(dets){
                helper.showUserMsg(null, dets);
            };
            console.log('Calling updateLoading 642');
            updateLoading(cmp, toastHelper.bind(this), true);
        } else {
            cmp.set('v.progressRate', 0);
        }
    },
    
    /*methodZero : function(cmp, e, helper, resolve, reject) {
        console.log('Inside methodZero');
        resolve(true);	
    },
    
    getUser: function(cmp, e, helper, resolve, reject) {
        console.log('Inside getUser');
        let getUser = cmp.get('c.getRunningUser');
        getUser.setCallback(this, function(res){
            let user = res.getReturnValue();
            if (res.getState() != 'SUCCESS') {
                console.log(res.getError())
                let t = 'Error',
                    m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            cmp.set('v.lockAccess', false);
            cmp.set('v.runningUser', user);
            if (user.Sales_Org__c != 'PEO' && user.Sales_Org__c != 'COE' && user.Sales_Org__c != 'PAS') {
                reject({t: 'Error', m:'User profile doesnt have access. Please contact Sales Enablement for support', ty:'error'});
        	} 
            resolve(true);	
        })
        
        $A.enqueueAction(getUser);
    },
    
    getContactInfo: function(cmp, e, helper, resolve, reject) {
        //debugger;
        console.log('Inside getContactInfo');
        let contactAction = cmp.get('c.getContactForId');
        contactAction.setParams({conId: cmp.get('v.recordId')});
        contactAction.setCallback(this, function(res) {
            if (res.getState() != 'SUCCESS') {
                let t = 'Error';
                let m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.';
                let ty = 'error';                  
                reject({t: t,m: m,ty: ty});
            }
            const contactData = res.getReturnValue();
            cmp.set('v.contactRec', contactData);
            console.log('Inside getContactInfo contactRec:');
            console.log(contactData);
            console.log(cmp.get('v.contactRec'));
            if (!contactData) {
                let t = 'Error';
                let m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.';
                let ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            // the account ID will always be the account this contact is directly associated with
            cmp.set('v.accountID', contactData.AccountId);
            // if the contact is on a child account the submission will be processed as an add on
            // this sets a boolean to be true which is checked to display a UI message and at the time
            // of portal creation
            if (contactData.Account.SalesParent__c) {
                console.log('<--Client Add on-->');
                cmp.set('v.isClientAddON', true);
                cmp.set('v.fullUnderwritingPathVal', 'Yes');    
                cmp.set('v.WhyareyouchoosingVal', 'Client Add-on');
            }
            //To get all child accounts		
            helper.getAllChildAccounts(cmp, e, helper);
            helper.getClientNumber(cmp, e, helper);
            helper.getExistingChecklist(cmp, e, helper)
            resolve(true);
        });
        $A.enqueueAction(contactAction);
    },
    
    getAllChildAccounts: function(cmp, e, helper){		
        let contactAction = cmp.get('c.getChildAccounts');		
        contactAction.setParams({accId: cmp.get('v.accountID')});		
        contactAction.setCallback(this, function(res) {		
            if (res.getState() == 'SUCCESS') {		
                const childAccountData = res.getReturnValue().childAccounts;		
                if(childAccountData != undefined && childAccountData.length > 0){		
                    var childAccs = [];		
                    childAccs.push({label: 'Parent Account Submission Only', value:'None'});
                    for(let i=0; i<childAccountData.length; i++){		
                        childAccs.push({label:childAccountData[i].Name, value:childAccountData[i].Id}); 		
                    }		
                    cmp.set('v.childAccs', childAccs);		
                    const childAccChecklists = res.getReturnValue().childAccChecklists;		
                    cmp.set('v.childAccChecklists', childAccChecklists);
                    if(childAccChecklists != undefined && childAccChecklists.length > 0){		
                        var childAccChklist = '';		
                        for(let i=0; i<childAccChecklists.length; i++){		
                            if(childAccChklist != ''){		
                                childAccChklist = childAccChklist + ';' + childAccChecklists[i].Prospect_Client__c;		
                            }else{		
                                childAccChklist = childAccChecklists[i].Prospect_Client__c;		
                            }		
                        }		
                        cmp.set('v.existingChildAccChecklists', childAccChklist);		
                        cmp.set('v.childAccountId', childAccChklist);		
                    }else{	
                        cmp.set('v.childAccountId', 'None');	
                        cmp.set('v.childAccsOldValue', 'None');	
                    }	
                }else{		
                    cmp.set('v.noChildAccount', true);		
                }		
            }		
        });		
        $A.enqueueAction(contactAction);		
    },
    
    checkForAssociatedCommunityUser: function(cmp,event, helper, resolve, reject) {
        console.log('Inside checkForAssociatedCommunityUser');
        let verifyAction = cmp.get('c.verifyExistingUserForContact');
        verifyAction.setParams({conId: cmp.get('v.recordId')});
        verifyAction.setCallback(this, function(res) {
            if (res.getState() !== 'SUCCESS') {
                console.log(res.getError())
                reject({
                    t:'Error',
                    m: 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty:'warning', 
                    broke: false
                });
            }
            let existingUser = res.getReturnValue();
            console.log('existingUser'+existingUser);
            if (!existingUser) {
                cmp.set('v.hasInactiveUser', false);
            }
            else if (existingUser && !existingUser.IsActive){
                cmp.set('v.hasInactiveUser', true);
                cmp.set('v.communityUser',existingUser);
                cmp.set('v.createCommUser','No');
                cmp.set('v.welcomeEmailCheck','No');
                console.log('inactive user true');
            }
                else {
                    cmp.set('v.hasInactiveUser', false);
                    cmp.set('v.communityUser',existingUser);
                    cmp.set('v.createCommUser','No');
                    cmp.set('v.welcomeEmailCheck','No');
                    cmp.set('v.communityUsername', existingUser.Username)
                    cmp.set('v.communityNickName', existingUser.CommunityNickname);
                    cmp.set('v.alias', existingUser.Alias);
                }
            resolve(res.getReturnValue());
        });      	
        $A.enqueueAction(verifyAction);
    },
    
    assignCreationValues: function(cmp,event, helper, resolve, reject) {
        //debugger;
        if(!cmp.get('v.communityUser')){
            let contactRec = cmp.get('v.contactRec');
            let alias = '',
                nickName = '',
                flatName = contactRec.Name.replace(/\s+/g, '');
            if(flatName.length < 6){
                alias = flatName;
                nickName = flatName;
            }
            else if(flatName.length < 13){
                alias = flatName.substring(0,6);
                nickName = flatName;
            }
                else{
                    alias = flatName.substring(0,6);
                    nickName = flatName.substring(0,13);       
                }
            console.log('setting alias'+alias);
            cmp.set('v.alias', alias);
            cmp.set('v.communityNickName', nickName);
            let env = cmp.get('v.environment');
            console.log('environment:'+env);
            if(env && env!=''){
                cmp.set('v.communityUsername', contactRec.Email+'.'+env);
            }
            else{
                cmp.set('v.communityUsername', contactRec.Email);
            }
        }
        resolve(true);
    },
    
    getOppty: function(cmp,event, helper, resolve, reject) {
        // returns a promise resolved or rejected based on srvr resp w/ breaking(force close) err
        // get the opps for the account
        // throw breaking error to handler if no opp returned
        // Testing Err Notes: none as of now
        console.log('Inside getOppty');
        var checklist = cmp.get('v.checklist');
        if(!checklist){
            let oppAction = cmp.get('c.getOpp');
            
            oppAction.setParams({accId: cmp.get('v.accountID')});
            oppAction.setCallback(this, function(res) {
                if (res.getState() != 'SUCCESS') {
                    console.log(res.getError())
                    let t = 'Error';
                    let m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.';
                    let ty = 'error';                  
                    reject({
                        t: t,
                        m: m,
                        ty: ty
                    });
                }
                let opp =  res.getReturnValue();
                cmp.set('v.opportunity',opp);
                console.log('getOpp opp'+opp);
                //leaving this here just in case, likely don't need anymore 1/4/21
                if (!opp) {
                    let permissionList = cmp.get('v.missingPermissionList');
                    permissionList.push('No Opp');
                    cmp.set("v.missingPermissionList",permissionList);
                    console.log('missingPermissions from Opp Call'+permissionList);
                }
                //APR0129807 fire only if checklist doesn't exist
                var checklist = cmp.get('v.checklist');
                if(!checklist && !opp){
                    let t = 'Portal Creation Error - Please Read and Verify the Listed Items';
                    // SFDC-13614  APR0134709 - Rohith - Start
                    //let m = 'To initiate portal access you must have an opportunity created within 180 days and you must be the Prospect-Client owner, Payx PEO-ASO Account Owner or Oasis PEO Account Owner.';
                    let m = '1. Are you the PEO Account Owner of the Prospect Client? If not, submit a Crossover.'+'\n'+'2. Is your PEO Opportunity created within the past 180 days? If not, create a new Opportunity or use a more recent Opportunity.'+
                        //'\n'+'3.Is the Opportunity Record Type = PEO'+'\n'+'4.If your Prospect Client record has a CS CM Contract Status of Client,Terminated,UnderContract,PendingTermination,PendingActivation, please create a new Prospect Client record';
                        '\n'+'3. Confirm your Opportunity Record Type is one of the following - PEO, Prism PEO, PEO Referral Revenue, ASO Referral Revenue.'+'\n'+'4. If your Prospect Client Record has a "CS CM Contract Status" of Terminated, Client, UnderContract, PendingTermination, PendingActivation, you must create a NEW Prospect Client Record.'; // SFDC-14127 Rohith
                    // SFDC-13614  APR0134709 - Rohith - End
                    let ty = 'Error';
                    cmp.set('v.toastMode','sticky');
                    reject({t: t, m: m, ty: ty, broke:true});
                }
                resolve(true);
            });
            $A.enqueueAction(oppAction);	
        }
    },
    
    checkQQSPATesterAccess: function(cmp,event, helper, resolve, reject) {
        console.log('Inside checkQQSPATesterAccess');
        console.log('label='+ $A.get("$Label.c.PEOUW_QQSPATesting"));
        if($A.get("$Label.c.PEOUW_QQSPATesting") == 'false'){
            console.log('QQ SPA testing is Off');
            resolve(true);
        }
        else{
            var getQQPrimeAccess = cmp.get("c.checkEdgeQQUserPermissions");
            
            getQQPrimeAccess.setCallback(this, function(data) {
                if (data.getState() != 'SUCCESS') {
                    console.log(data.getError())
                    let t = 'Error',
                        m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                        ty = 'Error';
                    reject({t: t, m: m, ty: ty});
                }else {
                    var hasAccess = data.getReturnValue();
                    console.log('has QQSPATesterAccess:'+hasAccess);
                    // If the user has QQ SPA tester access set disabled to false for FULL UW reqd field
                    // has access => disabled is false
                    //cmp.set("v.QQSPATesting", !hasAccess);
                    cmp.set("v.disableSPAQQFields", !hasAccess);
                    
                }
                resolve(true);
            });
            $A.enqueueAction(getQQPrimeAccess);
        }
    },*/
    getInitializationAttributes: function(component, event, helper, resolve, reject) {
        console.log('getInitializationAttributes')
        try {
            let getAttributeAction = component.get('c.getInitializationAttributes');
            getAttributeAction.setParams({
                contactId: component.get('v.recordId')
            })
            
            getAttributeAction.setCallback(this, function(resp) {
                debugger;
                let {env, runningUser, contactRecord, communityUserRecord, missingPermissionsList} = resp.getReturnValue();
                
                /*************************************
             	* handle errors: no server response or no contact record found
             	*************************************/
                if (resp.getState() != 'SUCCESS' || !contactRecord) {
                    return reject({
                        t: 'Error', 
                        m: 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.', 
                        ty: 'Error'
                    });
                }
                
                /*************************************
             	* Set env attributes
             	*************************************/
                if(env) {
                    component.set('v.environment', env);
                }
                
                /*************************************
             	* Set running user attributes
             	*************************************/
                component.set('v.lockAccess', false);
                component.set('v.runningUser', runningUser);
                let userOrgIsNotAllowed = runningUser.Sales_Org__c != 'PEO' && runningUser.Sales_Org__c != 'COE' && runningUser.Sales_Org__c != 'PAS';
                if (userOrgIsNotAllowed) {
                    return reject({t: 'Error', m:'User profile doesnt have access. Please contact Sales Enablement for support', ty:'error'});
                }
                
                // handle permissions
                // !? AE: Can we remove this?
                if(missingPermissionsList.includes('BETA Access')){
                    return reject({
                        t: 'Failed Verification', 
                        m: 'You do not have permission to use this functionality.  For assistance, please contact Sales Enablement', 
                        ty: 'Error'
                    });
                } else {
                    component.set("v.missingPermissionList",missingPermissionsList);
                    console.log('missingPermissionsList'+missingPermissionsList);
                }
                
                /*************************************
             	* Set current viewed record attributes
             	*************************************/
                component.set('v.contactRec', contactRecord);
                
                // the account ID will always be the account this contact is directly associated with
                component.set('v.accountID', contactRecord.AccountId);
                component.set('v.clientNumberVal', contactRecord.Account.AccountNumber);
                component.set('v.isDisabled', true);
                if (contactRecord.Account.AccountNumber != null) {
                    component.set('v.isDisabled', true);
                } else {
                    component.set('v.isDisabled', false);
                }
                
                // if the contact is on a child account the submission will be processed as an add on
                // this sets a boolean to be true which is checked to display a UI message and at the time
                // of portal creation
                if (contactRecord.Account.SalesParent__c) {
                    component.set('v.isClientAddON', true);
                    component.set('v.fullUnderwritingPathVal', 'Yes');    
                    component.set('v.WhyareyouchoosingVal', 'Client Add-on');
                }
                else{
                    component.set('v.isClientAddON', false);
                }
                console.log('isClientAddON? ' ,component.get('v.isClientAddON'));
                
                // handle community user
                if (!communityUserRecord) {
                    component.set('v.hasInactiveUser', false);
                } else if (communityUserRecord && !communityUserRecord.IsActive){
                    component.set('v.hasInactiveUser', true);
                    component.set('v.communityUser',communityUserRecord);
                    component.set('v.createCommUser','No');
                    component.set('v.welcomeEmailCheck','No');
                    console.log('inactive user true');
                } else {
                    component.set('v.hasInactiveUser', false);
                    component.set('v.communityUser',communityUserRecord);
                    component.set('v.createCommUser','No');
                    component.set('v.welcomeEmailCheck','No');
                    component.set('v.communityUsername', communityUserRecord.Username)
                    component.set('v.communityNickName', communityUserRecord.CommunityNickname);
                    component.set('v.alias', communityUserRecord.Alias);
                }
                
                if(!component.get('v.communityUser')){
                    let alias = '',
                        nickName = '',
                        flatName = contactRecord.Name.replace(/\s+/g, '');
                    if(flatName.length < 6){
                        alias = flatName;
                        nickName = flatName;
                    } else if(flatName.length < 13){
                        alias = flatName.substring(0,6);
                        nickName = flatName;
                    } else{
                        alias = flatName.substring(0,6);
                        nickName = flatName.substring(0,13);       
                    }
                    
                    component.set('v.alias', alias);
                    component.set('v.communityNickName', nickName);
                    
                    if(env && env!=''){
                        component.set('v.communityUsername', contactRecord.Email+'.'+env);
                    }
                    else{
                        component.set('v.communityUsername', contactRecord.Email);
                    }
                }
                resolve(true)
            })
            $A.enqueueAction(getAttributeAction);
        }
        catch(e) {
            component.set('v.toastMode','sticky');
            let rejectParams = {};
            rejectParams.t = 'Error';
            rejectParams.m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.';
            rejectParams.ty = 'error';
            rejectParams.broke = true;
            return reject(rejectParams);
        }
    },
    /*************************************
	* calls getOpportunityAndChecklistDocuments to 
    * retieve records used for setting UI input values.
    * Expects to be invoked from a promise and passed 
    * resolve and reject attributes as params.
    * @Params: Component, event, helper, resolve, reject
    * @Returns: 
    * 	- Resolve(true) on success
    * 	- Reject(Object) on errors
    *************************************/
    getInitializationRecord: function(component, event, helper, resolve, reject) {
        try {
            console.log('getInitializationRecord')
            debugger;
            // need to ensure getAllChildAccounts, getClientNumber, getExistingChecklist are done
            let getInitializationRecords = component.get('c.getOpportunityAndChecklistDocuments')
            getInitializationRecords.setParams({
                accountId: component.get('v.accountID')
            });
            
            getInitializationRecords.setCallback(this, function(resp) {
                debugger;
                let { opportunityForAccount, existingChecklist, childAccountMap } = resp.getReturnValue();
                
                /*************************************
             	* handle initial errors
             	*************************************/
                if (resp.getState() != 'SUCCESS') {
                    let rejectParams = {};
                    rejectParams.t = 'Error';
                    rejectParams.m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.';
                    rejectParams.ty = 'error';
                    return reject(rejectParams);
                }
                
                // Users might return to a contact some time after the opportunity goes stale to work the account
                // if there's an existing checklist they should be able to proceed without a valid oppty
                // There's logic on the oppty trigger to update it's state. If we get here and there is
                // not an existing checklist AND there is also no valid opportunity, then the user needs 
                // to initiate the portal using the defined process. Throw an error and make them check their records
                if( !opportunityForAccount && !existingChecklist) {
                    component.set('v.portalCreationError', true);
                    return resolve(true);
                    /*let t = 'Portal Creation Error - Please Read and Verify the Listed Items';
                    let m = '1. Are you the PEO Account Owner of the Prospect Client? If not, submit a Crossover.'
                    m += '\n' + '2. Is your PEO Opportunity created within the past 180 days? If not, create a new Opportunity or use a more recent Opportunity.';
                    m += '\n' + '3. Confirm your Opportunity Record Type is one of the following - PEO, Prism PEO, PEO Referral Revenue, ASO Referral Revenue.';
                    m += '\n' + '4. If your Prospect Client Record has a "CS CM Contract Status" of Terminated, Client, UnderContract, PendingTermination, PendingActivation, you must create a NEW Prospect Client Record.';
                    let ty = 'Error';
                    component.set('v.toastMode','sticky');
                    return reject({t: t, m: m, ty: ty});*/
                }
                
                /*************************************
             	* handle the opportunity attributes
             	*************************************/
                component.set('v.opportunity',opportunityForAccount);
                
                /************************
             	* Handle the checklist
             	************************/
                if (existingChecklist) {
                    component.set('v.WCFastPass', existingChecklist.Workers_Comp_FastPass__c);
                    component.set('v.WCInTargetHazardGroup', existingChecklist.WC_Codes_are_in_Target_Hazard_Group__c);
                    component.set('v.WCPremiumUnderLimit', existingChecklist.WC_Premium_is_less_than_10_000__c);
                    component.set('v.medicalRequestedVal', existingChecklist.Medical_Benefits_Underwriting_Requested__c);
                    component.set('v.WCUnderwritingVal', existingChecklist.Submit_to_Workers_Comp_Underwriting__c);
                    component.set('v.currentlyHasPeoVal', existingChecklist.Health_Benefits_Currently_through_a_PEO__c);
                    component.set('v.medicalUnderwritingPathVal', existingChecklist.Medical_Underwriting_Path_Option__c);
                    component.set('v.platformVal', existingChecklist.Platform__c);
                    component.set('v.currentAffiliationVal', existingChecklist.Current_Aff_with_Paychex_PEO_Oasis__c);
                    
                    if(existingChecklist.Prospect_Client__r.AccountNumber != null){
                        component.set('v.clientNumberVal', existingChecklist.Prospect_Client__r.AccountNumber);
                        component.set('v.isDisabled' , true);
                    }else{
                        component.set('v.clientNumberVal', existingChecklist.Client_Number__c);
                        component.set('v.isDisabled' , false);
                    }
                    //US36
                    let CSCMStatusLockCodes = ['Prospect'];
                    
                    if (!$A.util.isUndefinedOrNull(existingChecklist.CS_CM_Contract_Status__c) &&
                        !CSCMStatusLockCodes.includes(existingChecklist.CS_CM_Contract_Status__c)) {                    
                        component.set('v.readOnly' ,true);
                    }
                    
                    component.set('v.paychexAgencyClientVal', existingChecklist.Is_this_a_current_Paychex_Agency_Client__c);
                    component.set('v.parentCompanyLegalNameVal', existingChecklist.Parent_Company_Legal_Name__c);
                    component.set('v.parentCompanyPaychexVal', existingChecklist.Parent_Paychex_oasis_Num__c);
                    component.set('v.parentCurrentlyHaveApprovalVal', existingChecklist.Parent_appro_self_retain_workers_comp__c);
                    component.set('v.isMedicalRequestedVal', existingChecklist.Is_Medical_Underwriting_Requested__c);
                    
                    component.set('v.medicalUWPathType', existingChecklist.Medical_Underwriting_Path_Type__c);	
                    component.set('v.workersCompUWPathType', existingChecklist.Workers_Comp_Underwriting_Path_Type__c);
                    
                    if (existingChecklist.Medical_Benefits_Underwriting_Requested__c == 'Yes') {
                        component.set('v.medicalRequestedVal', 'Yes');
                        component.set('v.medicalReq', true);
                    }
                    else if(existingChecklist.Medical_Benefits_Underwriting_Requested__c == 'No'){
                        component.set('v.medicalRequestedVal', 'No');
                        component.set('v.medicalReq', false);
                    }
                    if(component.get('v.isClientAddON') ){
                        component.set('v.fullUnderwritingPathVal', 'Yes');    
                        component.set('v.WhyareyouchoosingVal', 'Client Add-on');                    
                    }
                    else
                    {
                        if(existingChecklist.Do_you_need_full_underwriting_path__c == undefined 
                           || existingChecklist.Do_you_need_full_underwriting_path__c == '' 
                           || existingChecklist.Do_you_need_full_underwriting_path__c == null){
                            component.set('v.fullUnderwritingPathVal', 'No');
                        }else{
                            component.set('v.fullUnderwritingPathVal', existingChecklist.Do_you_need_full_underwriting_path__c);
                        }
                        component.set('v.WhyareyouchoosingVal', existingChecklist.why_choose_full_underwriting_path__c);
                    }
                    if(existingChecklist.QQ_Medical_Submit_Date__c || existingChecklist.QQ_WC_Submit_Date__c){
                        if(existingChecklist.Prospect_Client__r.CSCMContractStatus__c == 'Prospect' || 
                           existingChecklist.Prospect_Client__r.CSCMContractStatus__c == '' ||
                           existingChecklist.Prospect_Client__r.CSCMContractStatus__c == null){
                            component.set('v.showMsg', true);
                            component.set('v.fullUnderwritingPathVal', 'Yes');
                            //component.set('v.WhyareyouchoosingVal', 'QQ within 90 days');
                            var currentDate = new Date();
                            currentDate = currentDate.toISOString();
                            if(currentDate > existingChecklist.QQ_Reset_Eligible_Date__c){
                                component.set('v.qqBanner', 'This prospect is eligible for a new Quick Quote submission. Please submit a Sales Help case to ' + 
                                              'have the prospect reprocessed and allow for a new Quick Quote submission.');
                            }else{
                                component.set('v.qqBanner', 'This prospect has been submitted for a Quick Quote within the past 90 days and is not eligible ' + 
                                              'for a new Quick Quote review. You must proceed with a Full Underwriting Submission. If needed, please submit ' + 
                                              'a Sales Help case to reprocess the CS CM Contract Status and ensure proper portal use.' + 
                                              ' If your prospect is in “Prospect” status, the portal is ready for use.');
                            }
                        }
                    }
                    /* 
                console.log('Client_Add_on__c' ,data.Client_Add_on__c);
                 console.log('WhyareyouchoosingVal' ,cmp.get('v.WhyareyouchoosingVal'));*/
                    //Benchmark
                    /*if (data.display_Benchmark_tab__c) {
                    cmp.set('v.display_Benchmark_tab__c', data.display_Benchmark_tab__c);
                }
                else{
                    cmp.set('v.display_Benchmark_tab__c', data.display_Benchmark_tab__c);
                }*/
                    component.set('v.reasonNotInvitingPro',existingChecklist.Reason_Why_You_Are_Not_Inviting_Prospect__c);
                    component.set('v.pleaseExplain',existingChecklist.Please_Explain__c);
                    component.set('v.existingChecklist', existingChecklist);
                    component.set('v.selfRetainReason', existingChecklist.Self_retain_reason__c);
                    component.set('v.benEffectiveDate', existingChecklist.Benefit_Effective_Date__c);
                    component.set('v.medicalUwPath', existingChecklist.Medical_Underwriting_Path__c);
                    component.set('v.opportunity', existingChecklist.Opportunity__r);
                    component.set('v.checklist', existingChecklist);
                }
                else{
                    if(component.get('v.isClientAddON') ){
                        component.set('v.fullUnderwritingPathVal', 'Yes');    
                        component.set('v.WhyareyouchoosingVal', 'Client Add-on');                    
                    }
                    else{
                        component.set('v.fullUnderwritingPathVal', 'No');
                    }                
                }
                
                /*************************************
             	* handle childAccounts
             	*************************************/
                if (childAccountMap) {
                    let { childAccounts, childAccChecklists } = childAccountMap;
                    debugger;
                    // if there are child accounts
                    // set the list of child accounts on the component
                    // then set the checklist prospect clients on the component
                    if(childAccounts && childAccounts.length){		
                        var childAccs = [];		
                        childAccs.push({label: 'Parent Account Submission Only', value:'None'});
                        for(let i=0; i<childAccounts.length; i++){		
                            childAccs.push({label:childAccounts[i].Name, value:childAccounts[i].Id}); 		
                        }		
                        component.set('v.childAccs', childAccs);		
                        
                        component.set('v.childAccChecklists', childAccChecklists);
                        if(childAccChecklists && childAccChecklists.length){		
                            var childAccChklist = ''; // => parent Account;child account 1; child account 2
                            // !AE: Why are we doing this? 
                            // could use childAccChecklists.join(';')
                            for(let i=0; i<childAccChecklists.length; i++){		
                                if(childAccChklist != ''){
                                    childAccChklist = childAccChklist + ';' + childAccChecklists[i].Prospect_Client__c;		
                                }else{		
                                    childAccChklist = childAccChecklists[i].Prospect_Client__c;		
                                }		
                            }		
                            component.set('v.existingChildAccChecklists', childAccChklist);		
                            component.set('v.childAccountId', childAccChklist);		
                        }else{	
                            component.set('v.childAccountId', 'None');	
                            component.set('v.childAccsOldValue', 'None');	
                        }	
                    }else{		
                        component.set('v.noChildAccount', true);		
                    }
                    
                    // after setting the child accounts we check some values on the checklist
                    if(component.get('v.noChildAccount')){	
                        component.set('v.childAccountSelection', 'Yes');	
                    }else if (existingChecklist) {	
                        component.set('v.childAccountSelection', existingChecklist.Select_Child_Accounts__c);		
                    }
                }
                else {
                    component.set('v.noChildAccount', true);
                }
                
                // Needs to happen after child accounts are retrieved
                // if select child accounts == yes on the checklist then
                if(existingChecklist && existingChecklist.Select_Child_Accounts__c == 'Yes'){
                    var childAccs = component.get('v.childAccs');
                    var accMap = new Map();
                    for(let i=0; childAccs.length > i ; i++){
                        accMap.set(childAccs[i].value, childAccs[i].label);
                    }
                    accMap.delete('None');
                    var accList = '';
                    var newAccountNames = '';
                    // if there are more child accounts than checklists
                    // !? WHy would there be an extra checklist? childAccChecklists.length + 1
                    let childAccChecklists = childAccountMap ? childAccountMap. childAccChecklists : undefined;
                    if( childAccs && childAccChecklists && (childAccs.length >childAccChecklists.length + 1) ) {
                        component.set('v.showInfoMessage', true);
                        var childAccId = component.get('v.childAccountId');
                        const childAccArray = childAccId.split(';');
                        for(let i=0; childAccArray.length > i ; i++){
                            if(accMap.has(childAccArray[i])){
                                accMap.delete(childAccArray[i]);
                            }
                        }
                        if(accMap.size > 0){
                            for (let [key, value] of accMap) {
                                if(newAccountNames != ''){
                                    newAccountNames = newAccountNames + '; ' + value;
                                }else{
                                    newAccountNames = value;
                                }
                            }
                            component.set('v.unCheckedProspectNames', newAccountNames);
                        }
                    }
                }
                
                return resolve(true);
            })
            
            $A.enqueueAction(getInitializationRecords);
        }catch(e) {
            component.set('v.toastMode','sticky');
            let rejectParams = {};
            rejectParams.t = 'Error';
            rejectParams.m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.';
            rejectParams.ty = 'error';
            rejectParams.broke = true;
            return reject(rejectParams);
        }
    }
})