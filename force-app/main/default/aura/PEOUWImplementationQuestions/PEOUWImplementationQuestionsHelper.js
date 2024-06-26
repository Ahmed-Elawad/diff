({
	getImplementationChecklistData : function(component, event, helper) {
        var getImplChecklist = component.get('c.getPEOImplementationChecklist');
        getImplChecklist.setParams({
            checkList: component.get('v.peoFullChecklist'),
            allAccounts: component.get('v.allAccounts'),
            parentAccountId: component.get('v.ParentAccountId')
        });
        
        getImplChecklist.setCallback(this, function(res) {
            console.log('>>>>response:::'+JSON.stringify(res.getReturnValue()));
             console.log('>>>>getstate:::'+JSON.stringify(res.getState()));
            if (res.getState() != 'SUCCESS') {
                console.log('>>>error:::'+res.getError());
            }else{
                
                let data = res.getReturnValue();
                 console.log('>>>data:::'+data);
                component.set('v.isInit', true);
                if(data != null){
                    console.log(">>>data::" +JSON.stringify(data));
                    component.set('v.communityUser',data.communityUser);
                    component.set('v.parentImplChklist', data.parentImplChklist);
                    if(data.parentImplChklist.Status__c == 'Completed'){
                        component.set('v.disableQuestions', true);
                        component.set('v.isFinalized', true);
                        //component.set('v.buttonText', 'Resend Notification');
                    }/*else{
                        component.set('v.buttonText', 'Confirm without notifying the client');
                    }*/
                    /*if(data.communityUser != undefined){
                        component.set('v.communityUser', data.communityUser);
                    }else{
                        component.set('v.buttonText', 'Confirm without notifying the client');
                    }
                    if(data.implChecklist != undefined){
                        component.set('v.implementationChecklist', data.implChecklist);
                        if(data.implChecklist.Last_client_email_date__c != null){
                            component.set('v.disableQuestions', true);
                            component.set('v.buttonText', 'Resend Notification');
                        }
                    }*/
                }
            }
        })
        $A.enqueueAction(getImplChecklist);
	},
    
    /*saveImplementationQuestions: function(component, event, helper) {
        var saveImplChecklist = component.get('c.savePEOImplementationChecklist');
        var implChecklist = component.get('v.implementationChecklist');
        implChecklist.PEO_Underwriting_Checklist__c = component.get('v.peoFullChecklist.Id');
        implChecklist.Prospect_Client__c = component.get('v.ParentAccountId');
        var updateChecklist = true;
        saveImplChecklist.setParams({
            implChecklist: implChecklist,
            updateDates : false,
            updateFinalizeDate : false
        });
        
        saveImplChecklist.setCallback(this, function(res) {
            if (res.getState() != 'SUCCESS') {
                console.log(res.getError());
            }else{
                let data = res.getReturnValue();
                var toastEvent = $A.get("e.force:showToast");
                if(data.isSuccessful){
                    component.set('v.implementationChecklist', data.implChecklist);
                    toastEvent.setParams({
                        title: 'Success',
                        message: 'Implementation Checklist saved successfully!',
                        type: 'SUCCESS'
                    });
                }else{
                    toastEvent.setParams({
                        title: 'Error',
                        message: 'Failed to save Implementation Checklist!',
                        type: 'ERROR'
                    });
                }
                toastEvent.fire();
            }
        })
        $A.enqueueAction(saveImplChecklist);
    },*/
    
    sendEmailtoCommunityUser: function(component, event, helper) {
        var implementationChecklist = component.get('v.implementationChecklist');
        implementationChecklist.Id = component.get('v.parentImplChklist').Id;
        //var button = component.get('v.buttonText');
        var updateImplChecklist = component.get('c.savePEOImplementationChecklist');
        //var updateDates = false;
        /*var updateFinalizeDate = false;
        var email = '';
        if(button == 'Send Notification' || button == 'Resend Notification'){
            updateDates = true;
            email = component.get('v.communityUser.Email');
        }else if(button == 'Confirm without notifying the client'){
            updateFinalizeDate = true;
        }*/
        component.set('v.isInit', false);
        updateImplChecklist.setParams({
            implChecklist: implementationChecklist,
            updateDates : true,
            updateFinalizeDate : false,
            email : ''
        });
        updateImplChecklist.setCallback(this, function(res) {
            component.set('v.isInit', true);
            if (res.getState() != 'SUCCESS') {
                console.log(res.getError());
            }else{
                let data = res.getReturnValue();
                var toastEvent = $A.get("e.force:showToast");
                if(data.isSuccessful){
                    component.set('v.isFinalized', true);
                    component.set('v.disableQuestions', true);
                    toastEvent.setParams({
                        title: 'Success',
                        message: 'Implementation questions are finalized!',
                        type: 'SUCCESS'
                    });
                    toastEvent.fire();
                    /*if(updateDates){
                        //component.set('v.disableQuestions', true);
                        component.set('v.buttonText', 'Resend Notification');
                        if(data.isEmailSent){
                            toastEvent.setParams({
                                title: 'Success',
                                message: 'Email sent successfully!',
                                type: 'SUCCESS'
                            });
                        }else{
                            toastEvent.setParams({
                                title: 'Error',
                                message: 'Failed to send an email',
                                type: 'ERROR'
                            });
                        }
                    }else{
                        toastEvent.setParams({
                            title: 'Success',
                            message: 'Internal questions are finalized!',
                            type: 'SUCCESS'
                        });
                    }*/
                    /*try {
                        let tabNavigateEVt = component.getEvent('communityFormsTabNavigate');
                        tabNavigateEVt.setParam('direction', 1);
                        tabNavigateEVt.fire();   
                    }catch(e){
                        console.error(e);
                    }*/
                }else{
                    toastEvent.setParams({
                        title: 'Error',
                        message: 'Failed to save the Implementation data!',
                        type: 'ERROR'
                    });
                    toastEvent.fire();
                }
            }
        })
        $A.enqueueAction(updateImplChecklist);
    },
    fetchImplMsngFields: function(component, event, helper) {
        console.log('>>>>fetchImplMsngFields');
        console.log('allAccounts:'+component.get("v.allAccounts"));
        console.log('parentAccountId:'+component.get("v.ParentAccountId"));
        var action = component.get("c.returnImplChecklist");
        action.setParams({
            allAccounts: component.get("v.allAccounts"),
            parentAccountId: component.get("v.ParentAccountId")
        });
        action.setCallback(this, function(res) {
            console.log('>>>>fetchImplMsngFields:response:::'+JSON.stringify(res.getReturnValue()));
             console.log('>>>>fetchImplMsngFields:getstate:::'+JSON.stringify(res.getState()));
             var returnVal = res.getReturnValue();
            // alert('>>returnVal:: '+returnVal);
            if (res.getState() != 'SUCCESS') {
               // alert('>>error');
                console.log('>>>error:::'+JSON.stringify(res.getError()));
                //component.set("v.isFinalizeDisable",returnVal); 

            }
            else{
                var newItems=[];
                var missingAccs = '';
                var message = "All fields within the Implementation section are required. Please review for missing information prior to Finalizing.\n"
                for (var i=0; i< returnVal.length; i++)
                {
                    var record = returnVal[i];
                    console.log('record-> ' + JSON.stringify(record));
                    
                    //var Item = {PEOUW_Msng_Sec__c: record.PEOUW_Msng_Sec__c};
                    var Item = record.PEOUW_Msng_Sec__c;
                    console.log('Item-> ' + JSON.stringify(Item));
                    if(Item != undefined || Item != null){
                        message = message +JSON.stringify(Item);
                        if(i<returnVal.length-1)message = message+',\n';
                        newItems.push(Item);
                        console.log('newItems-> ' + JSON.stringify(newItems));
                    }
                }
                console.log('missingAccs:'+message);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "mode": "sticky",
                    "title": "Error!",
                    "type":"error",
                    "message": message
                });
                toastEvent.fire();
                this.checkFlexOnboarding(component, event, helper, returnVal);
                //component.set("v.isFinalizeDisable",returnVal); 
            }
        })
        $A.enqueueAction(action);
    },
    
    fetchImplChklistData: function(component, event, helper){
        var action = component.get("c.returnImplChecklist");
        action.setParams({
            allAccounts: component.get("v.allAccounts"),
            parentAccountId: component.get("v.ParentAccountId")
        });
        action.setCallback(this, function(res) {
            var returnVal = res.getReturnValue();
            if (res.getState() != 'SUCCESS') {
                console.log('>>>error:::'+JSON.stringify(res.getError()));
            }else{
                var isValid = this.checkFlexOnboarding(component, event, helper, returnVal);
                if(isValid){
                    console.log('component.get(v.peoFullChecklist)', component.get('v.peoFullChecklist'));
                    if(component.get('v.peoFullChecklist').CSCMContractStatus__c == undefined ||
                       (component.get('v.peoFullChecklist').CSCMContractStatus__c != 'Approved' &&
                        component.get('v.peoFullChecklist').CSCMContractStatus__c != 'ContractPending')){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title: 'Error',
                            message: 'CS CM Contract Status needs to be Approved/ContractPending in order to finalize the questions!',
                            type: 'ERROR'
                        });
                        toastEvent.fire();
                    }
                    else{
                        helper.sendEmailtoCommunityUser(component, event, helper);
                        //component.set('v.showCommunityUserInfo', true);
                    }
                }
            }
        })
        $A.enqueueAction(action);
    },
    
    checkFlexOnboarding: function(component, event, helper, returnVal){
        for (var i=0; i< returnVal.length; i++){
            if(returnVal[i].PEO_Underwriting_Checklist__r.Platform__c == 'Flex' && 
               (returnVal[i].PEO_Underwriting_Checklist__r.Client_Add_on__c || 
                returnVal[i].PEO_Underwriting_Checklist__r.Current_Aff_with_Paychex_PEO_Oasis__c == 'Paychex PEO/Oasis PEO, Child Add-On') && 
               !returnVal[i].Flex_Onboarding__c && !returnVal[i].MyStaffingPro__c){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "mode": "sticky",
                    "title": "Error!",
                    "type":"error",
                    "message": "Setup Information: You must select the appropriate employee onboarding solution (Flex Onboarding or myStaffingPro) " 
                    + "in order to Finalize.  Please see the product(s) help text for more information"
                });
                toastEvent.fire();
                return false;
            }
        }
        return true;
    },
    
    /*runAutoSave: function(component, event, helper, field) {
        let fieldName = field.get('v.name');
        let fieldAPIName, objectAPIName, fieldValue;
        
        if (fieldName) {
            let splitName =  fieldName.split('.');
            objectAPIName = splitName[0];
            fieldAPIName = splitName[1];
        }
        fieldValue = field.get('v.value');
        if(fieldValue && fieldValue.length){
            try {
                let recordId;
                recordId = component.get('v.implementationChecklist.Id');
                console.log(field);
                let autoSaveEvt = component.getEvent('autoSave');
                autoSaveEvt.setParam('objectName', objectAPIName);
                autoSaveEvt.setParam('fieldName', fieldAPIName);
                autoSaveEvt.setParam('fieldValue', fieldValue);
                autoSaveEvt.setParam('recordId', recordId);
                autoSaveEvt.fire();
            } catch(e) {
                console.log('err occured:')
                console.log(e);
            }
        }
    },*/
})