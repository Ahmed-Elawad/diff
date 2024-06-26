({
    /////////////Data Retrieval Methods////////////////////
    
    // retrieves an existing checklist if it exists. Sets the values in the cmp
    getExistingChecklist: function(cmp, e) {
        
        let getChecklistAction = cmp.get('c.checkForExistingChecklist');
        getChecklistAction.setParams({AccountID: cmp.get('v.accountID')});
        getChecklistAction.setCallback(this, function(res) {
            
            if (res.getState() != 'SUCCESS') {
                console.log(res.getError());
                return;
            }
            let data = res.getReturnValue();
            if (data) {
                cmp.set('v.WCFastPass', data.Workers_Comp_FastPass__c);
                cmp.set('v.WCInTargetHazardGroup', data.WC_Codes_are_in_Target_Hazard_Group__c);
                cmp.set('v.WCPremiumUnderLimit', data.WC_Premium_is_less_than_10_000__c);
                cmp.set('v.medicalRequestedVal', data.Medical_Benefits_Underwriting_Requested__c);
                cmp.set('v.WCUnderwritingVal', data.Submit_to_Workers_Comp_Underwriting__c);
                if (data.Medical_Benefits_Underwriting_Requested__c == 'Yes') {
                    cmp.set('v.medicalRequestedVal', 'Yes');
                    cmp.set('v.medicalReq', true);
                }
                else if(data.Medical_Benefits_Underwriting_Requested__c == 'No'){
                    cmp.set('v.medicalRequestedVal', 'No');
                    cmp.set('v.medicalReq', false);
                }
                cmp.set('v.existingChecklist', data);
                cmp.set('v.selfRetainReason', data.Self_retain_reason__c);
                cmp.set('v.benEffectiveDate', data.Benefit_Effective_Date__c);
                cmp.set('v.medicalUwPath', data.Medical_Underwriting_Path__c);
                cmp.set('v.experience', data.Experience__c);
                cmp.set('v.opportunity', data.Opportunity__r);
                cmp.set('v.checklist', data);
            }
        });
        $A.enqueueAction(getChecklistAction);
    },
    
    getPermissions: function(cmp,event, helper, resolve, reject){
       
            let getUserPermissions = cmp.get('c.checkPermissions');
            getUserPermissions.setParams({
                currUser: cmp.get("v.runningUser")
            });
            getUserPermissions.setCallback(this, function(res){
                
                let missingPermissions = res.getReturnValue();
                if (res.getState() != 'SUCCESS') {
                    console.log(res.getError())
                    let t = 'User retrieval error',
                        m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                        ty = 'Error';
                    reject({t: t, m: m, ty: ty});
                }
                else if(missingPermissions.includes('BETA Access')){
                    let t = 'Failed Verification',
                        m = 'You do not have permission to use this functionality.  For assistance, please contact Sales Enablement',
                        ty = 'Error';
                    reject({t: t, m: m, ty: ty});
                }
                    else{
                        cmp.set("v.missingPermissionList",missingPermissions);
                        console.log('missingPermissions'+missingPermissions);
                        resolve(true);
                    }
            })
            $A.enqueueAction(getUserPermissions);
        
    },
    
    //////////////Creation Methods//////////////////
   
    createNewUser: function(cmp, e) {
        cmp.set('v.step', 1);
        return new Promise(function(resolve, reject) {
            let create = cmp.get('c.createCommunityUser');
            create.setParams({
                uName: cmp.find("communityUsername").get("v.value"),
                nickName: cmp.find('communityNickName').get('v.value'),
                conId: cmp.get('v.recordId'),
                alias: cmp.find('alias').get('v.value'),
                audience: cmp.get('v.experience'),
                communityMessage: cmp.get('v.community_Welcome_Messsage__c')
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
            let reactivate = component.get('c.reactivateCommunityUser');
            reactivate.setParams({
                u: component.get("v.communityUser")
            });
            
            reactivate.setCallback(this, function(res) {
                let saveResult = res.getReturnValue();
                //TO DO, error while hitting .has
                if (res.getState() !== 'SUCCESS' || !saveResult) {
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
        return new Promise(function(resolve, reject) {
            let missingPermission = component.get('v.missingPermissionList');
            let startingContact = component.get('v.contactRec');
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
    //APR0129807 moved to initialization check to only if checklist doesn't exist
    /*checkOpportunity: function(component,e,helper){
        return new Promise(function(resolve, reject) {
            let missingPermission = component.get('v.missingPermissionList');
            if(missingPermission!= null && missingPermission.length>0 && missingPermission.includes('No Opp')){
                component.set('v.disableContinue',true);
                let t = 'No Opportunity Found';
                let m = 'To initiate portal access you must have an opportunity created within 180 days and you must be the Prospect-Client owner, Payx PEO-ASO Account Owner or Oasis PEO Account Owner.';
                let ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            resolve(true);
        })
    },*/
    /////////////Navigation/Utility Methods/////////////////
    openForm: function(cmp, e, helper) {
        let evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:communityForms",
            componentAttributes: {
                recordId : cmp.get("v.accountID")
            }
        });        
        evt.fire();        
    },
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
    closeAction: function() {
        $A.get("e.force:closeQuickAction").fire();
    },
    updateView : function(cmp, e) {
        cmp.set('v.step', 2);
    },
    loadCmp:function(component, event, helper) {
        //debugger;
        var fieldsMissing = component.get('v.fieldsMissing');
        if(!fieldsMissing){
            var evt = $A.get("event.force:navigateToComponent");
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
    handleError: function(data) {
        var event = $A.get("e.force:showToast");
        event.setParams({
            title: data.t,
            message: data.m,
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
    
    ////////////Form Validation Methods////////////////
    validateAdditionalQuestionFields : function(component, event, helper, resolve, reject) {
        var fieldsMissing = 0;
        var medicalRequested = component.get('v.medicalRequestedVal');
        var submitToWCUnderwriting = component.get('v.WCUnderwritingVal');
        var medicalPath = component.get('v.medicalUwPath');
        if(medicalRequested === undefined || medicalRequested =='default'){
            fieldsMissing+=1;
        } 
        if(medicalRequested === 'Yes'){
           	var medPath = component.get('v.medicalUwPath');
            if(medPath === undefined || medPath == 'default'){
            	console.log('missing med path');
                fieldsMissing+=1;
            }
        }
        if(submitToWCUnderwriting === undefined || submitToWCUnderwriting == 'default') {
            fieldsMissing+=1;
        }
        if(submitToWCUnderwriting == 'Yes - WC to be reviewed') {
            var fastPass = component.get('v.WCFastPass');
            if(fastPass === undefined || fastPass == 'default'){
                fieldsMissing+=1;
            }
            if(fastPass == 'Yes'){
                var targetHazardGroup = component.get('v.WCInTargetHazardGroup');
                var WCPremiumUnderLimit = component.get('v.WCPremiumUnderLimit');
                if(targetHazardGroup == 'default' || WCPremiumUnderLimit == 'default'){
                    fieldsMissing+=1;
                }
            }
        }
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
    
    ////////////Form Validation Methods////////////////
    validateUserCreationFields: function(cmp, e, helper, resolve, reject) {
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
            if (res.getReturnValue() && res.getReturnValue().length) {
                var errorList = res.getReturnValue();
                var errorFields = errorList.length == 2 ? 'Username and Nickname' : errorList[0];
                reject({
                    t: 'Duplicate inputs',
                    m: errorFields+' must be unique',
                    ty:'warning',
                    broke:false
                });
            };
            if (cmp.find('portalExperience').get('v.value') == '' || cmp.find('portalExperience').get('v.value') == 'default' ) {
                reject({
                    t: 'Required fields',
                    m: 'Portal experience selection required',
                    ty: 'warning',
                    broke:false
                });
            }
            else {
                cmp.set("v.experience", cmp.find('portalExperience').get('v.value'));
            }
            resolve(true);
        });
        $A.enqueueAction(verificationAction); 
        
    },
    
    //////////////Creation Methods//////////////////
    updateContactAndAcctWQ: function(cmp, e, helper, resolve, reject) {
        let updateRecsAction = cmp.get('c.updateContactAndAcctWorkqueue');
        updateRecsAction.setParams({contactId: cmp.get('v.recordId'), acctId: cmp.get('v.accountID')});
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
    
    //////////////Creation Methods//////////////////
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
        
        let newPEO = {
            Prospect_Client__c: cmp.get('v.accountID'),
            Medical_Benefits_Underwriting_Requested__c: cmp.get('v.medicalRequestedVal')
        };
        if (cmp.find('WCFastPass_Input')) {
            newPEO.Workers_Comp_FastPass__c = cmp.find('WCFastPass_Input').get('v.value');
        }
        if (cmp.find('Self_retain_reason__c')) {
            newPEO.Self_retain_reason__c = cmp.find('Self_retain_reason__c').get('v.value');
        }
        
        if(createCommUser == 'Yes'){
            newPEO.Experience__c = cmp.find('portalExperience').get('v.value');
        }
        
        if (cmp.get('v.medicalRequestedVal') == 'Yes') {
            newPEO.Benefit_Effective_Date__c = cmp.find('effectiveDate').get('v.value');
            newPEO.Medical_Underwriting_Path__c = cmp.find('medicalUwPath').get('v.value');
            if (newPEO.Medical_Underwriting_Path__c == 'default') newPEO.Medical_Underwriting_Path__c = '';
        }
        
        if (cmp.get('v.WCFastPass') == 'Yes') {
            newPEO.WC_Codes_are_in_Target_Hazard_Group__c = cmp.find('WCInTargetHazardGroup_Input').get('v.value');
            newPEO.WC_Premium_is_less_than_10_000__c = cmp.find('WCPremiumUnderLimit_Input').get('v.value');
        }
        
        newPEO.Submit_to_Workers_Comp_Underwriting__c = cmp.find('submitToWCUnderwriting').get('v.value');
        newPEO.Health_Benefits_Currently_through_a_PEO__c = cmp.find('prspctPeoUltlzn').get('v.value');
        
        //set the value of PEO_NSC__c in underwriting checklist if the logged in user is NSC
        if(cmp.get('v.runningUser').Sales_Division__c == 'NSC'){
            newPEO.PEO_NSC__c = cmp.get('v.runningUser').Id;
        }
        
        if (cmp.get('v.isClientAddON')) {
            newPEO.Client_Add_on__c = true;
        }
        
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
            if (chk.Experience__c && !newPEO.Experience__c) newPEO.Experience__c = chk.Experience__c;
            if (chk.Sales_Rep__c && !newPEO.Sales_Rep__c) newPEO.Sales_Rep__c = chk.Sales_Rep__c;
            if (chk.Id && !newPEO.Id) newPEO.Id = chk.Id;
            if (chk.Opportunity__r && chk.Opportunity__r.OwnerId) newPEO.OwnerId = chk.Opportunity__r.OwnerId;
            if (chk.Submit_to_Workers_Comp_Underwriting__c && !newPEO.Submit_to_Workers_Comp_Underwriting__c) newPEO.Submit_to_Workers_Comp_Underwriting__c = chk.Submit_to_Workers_Comp_Underwriting__c;
            if (chk.Medical_Underwriting_Path__c && !newPEO.Medical_Underwriting_Path__c) newPEO.Medical_Underwriting_Path__c = chk.Medical_Underwriting_Path__c;
        } else if (cmp.get('v.runningUser') && cmp.get('v.runningUser').Id) {
            newPEO.Sales_Rep__c = cmp.get('v.runningUser').Id;
        }
        
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
    
    updateView : function(cmp, e, helper, resolve, reject) {
        cmp.set('v.step', 2);
        resolve(true);	
    },
    
    // recursive method to update UI for the loading spinner.
    updateSpinnerState: function(cmp, e, helper, resolve, reject) {
        // set the spinner view to the oposite of what it is now
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
            updateLoading(cmp, toastHelper.bind(this), true);
        } else {
            cmp.set('v.progressRate', 0);
        }
    },
    
    methodZero : function(cmp, e, helper, resolve, reject) {
        resolve(true);	
    },
    
    getUser: function(cmp, e, helper, resolve, reject) {
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
            if (user.Sales_Org__c == 'PEO' || user.Sales_Org__c == 'COE') {
                cmp.set('v.experienceOptions', [{label: 'default', value: ''},{label: 'Oasis', value: 'Oasis'},{label: 'Paychex', value: 'Paychex'}]);
            } else if (user.Sales_Org__c == 'PAS') {
                cmp.set('v.experienceOptions', [{label: 'Paychex', value: 'Paychex'}]);                   
            } else {
                reject({t: 'Error', m:'User profile doesnt have access. Please contact Sales Enablement for support', ty:'error'});
            }
            resolve(true);	
        })
        
        $A.enqueueAction(getUser);
    },
    
    // get the contact record and assign the account ID the contact is associated to
    // on the component
    getContactInfo: function(cmp, e, helper, resolve, reject) {
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
                cmp.set('v.isClientAddON', true);
            }
            helper.getExistingChecklist(cmp, e, helper)
            resolve(true);
        });
        $A.enqueueAction(contactAction);
    },
    
    checkForAssociatedCommunityUser: function(cmp,event, helper, resolve, reject) {
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
            if (!existingUser) {
                cmp.set('v.hasInactiveUser', false);
            }
            else if (existingUser && !existingUser.IsActive){
                cmp.set('v.hasInactiveUser', true);
                cmp.set('v.communityUser',existingUser);
                cmp.set('v.createCommUser','No');
            }
                else {
                    cmp.set('v.hasInactiveUser', false);
                    cmp.set('v.communityUser',existingUser);
                    cmp.set('v.createCommUser','No');
                    cmp.set('v.experience', existingUser.Community_Audience__c);
                    cmp.set('v.communityUsername', existingUser.Username)
                    cmp.set('v.communityNickName', existingUser.CommunityNickname);
                    cmp.set('v.alias', existingUser.Alias);
                }
            resolve(res.getReturnValue());
        });      	
        $A.enqueueAction(verifyAction);
    },
    
    //////////////Creation Methods//////////////////
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
            cmp.set('v.alias', alias);
            cmp.set('v.communityNickName', nickName);
            cmp.set('v.communityUsername', contactRec.Email);
        }
        resolve(true);
    },
    
    getOppty: function(cmp,event, helper, resolve, reject) {
        // returns a promise resolved or rejected based on srvr resp w/ breaking(force close) err
        // get the opps for the account
        // throw breaking error to handler if no opp returned
        // Testing Err Notes: none as of now
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
                let t = 'No Opportunity Found';
                let m = 'To initiate portal access you must have an opportunity created within 180 days and you must be the Prospect-Client owner, Payx PEO-ASO Account Owner or Oasis PEO Account Owner.';
                let ty = 'Error';
                reject({t: t, m: m, ty: ty, broke:true});
            }
            resolve(true);
        });
        $A.enqueueAction(oppAction);	
    },
})