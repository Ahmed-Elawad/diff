({
	init : function(component, event, helper) {
        if(component.get('v.readonly'))
        	component.set('v.disableQuestions', true);
        
        var temAcc = component.get("v.allAccounts");
        console.log('>>>>>acc::'+temAcc);
        var temTotal = temAcc.length;
        component.set("v.totalAccount",temTotal);

        let allTabs = component.get('v.allAccounts').reduce(function(s, a) {
            s.push(a.Id);
            return s;
        }, []);
        allTabs.push('Finalize');
        component.set('v.possibleTabs', allTabs);
        let parentAcc = component.get('v.ParentAccountId');
        component.set('v.selectedAccountId', parentAcc);
        console.log('allTabsallTabsallTabs', allTabs);
        console.log(' component.set(v.selectedAccountId',parentAcc);

		helper.getImplementationChecklistData(component, event, helper);
	},

    save: function(component, event, helper){
        component.set('v.isInit', false);
        var action = component.get("c.saveNotes");
        action.setParams({
            peoFullChecklist: component.get("v.peoFullChecklist"),
        });
        action.setCallback(this, function(res) {
            var returnVal = res.getReturnValue();
            component.set('v.isInit', true);
            var toastEvent = $A.get("e.force:showToast");
            if (res.getState() != 'SUCCESS') {
                toastEvent.setParams({
                    "title": "Error!",
                    "type":"error",
                    "message": "There is an error while saving the data!"
                });
            }
            else{
                toastEvent.setParams({
                    "title": "Success!",
                    "type":"success",
                    "message": "Your progress has been saved!"
                });
            }
            toastEvent.fire();
        })
        $A.enqueueAction(action);
    },
    
    getToggleButtonValue : function(component, event, helper) {
        var checked = component.get("v.checked");
        console.log("checked is now = " + checked);
        if(checked){
            component.set('v.buttonText', 'Send Notification');
        }else{
            component.set('v.buttonText', 'Confirm without notifying the client');
        }
    },
    handleCopyToChildrenEvent :function(cmp, event, helper) {
        /*var parentImpCheckList = event.getParam("implementationChecklist");
        console.log('event handled', JSON.stringify(parentImpCheckList));
        component.set("v.copyfromParent", true);
        console.log('parentAccountId', cmp.get('v.ParentAccountId'));*/
         var parentImpCheckList = event.getParam("implementationChecklist");
         cmp.set("v.parentImplChklist", parentImpCheckList);
       /* cmp.set("v.copyfromParent", true);
        cmp.set("v.mirrorParentInfo", true);
       
        
		var compEvent = cmp.getEvent("cmpEventToCopyParentData");
        
        compEvent.setParams({"implementationChecklist" : parentImpCheckList });
        compEvent.fire(); */
        /*console.log('event handled', JSON.stringify(parentImpCheckList));
        var parentImpCheckList = event.getParam("implementationChecklist");
        cmp.set("v.parentImplChklist", parentImpCheckList);
        console.log('event handled', JSON.stringify(parentImpCheckList));
        event.pause(); */
        
       
        
    },
     checkFinalize:function(component, event, helper) {
        
      //  alert('>>>>checkFinalize');//
        console.log('>>>>>component.get("v.allAccounts"):: '+JSON.stringify(component.get("v.allAccounts")));
        console.log('>>>>>component.get("v.ParentAccountId"):: '+JSON.stringify(component.get("v.ParentAccountId")));
        var action = component.get("c.isPeoUwImplementationReadyForFinalize");
        action.setParams({
            allAccounts: component.get("v.allAccounts"),
            parentAccountId: component.get("v.ParentAccountId")
        });
        action.setCallback(this, function(res) {
            console.log('>>>>checkFinalize:response:::'+JSON.stringify(res.getReturnValue()));
             console.log('>>>>checkFinalize:getstate:::'+JSON.stringify(res.getState()));
             var returnVal = res.getReturnValue();
            // alert('>>returnVal:: '+returnVal);
            if (res.getState() != 'SUCCESS') {
               // alert('>>error');
                console.log('>>>error:::'+JSON.stringify(res.getError()));
                component.set("v.isFinalizeDisable",returnVal); 

            }
            else{
               
                component.set("v.isFinalizeDisable",returnVal); 
            }
        })
        $A.enqueueAction(action);
        
    },

   finalize:function(component, event, helper) {
         var isValidData = component.get("v.isFinalizeDisable");
         if(isValidData == false){
             helper.fetchImplMsngFields(component, event, helper);
            /*var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "type":"error",
                "message": "All fields within the Implementation section are required. Please review for missing information prior to Finalizing."
            });
            toastEvent.fire();*/
         }else{
             var isValid = helper.fetchImplChklistData(component, event, helper);
             //var childCmp = component.find("internalQuestionCmp");
             //childCmp.callInternalQuestionFinalize();
         }
    },
    
    cancelModal: function(component, event, helper) {
        component.set('v.showCommunityUserInfo', false);
    },
    
    /*sendEmail: function(component, event, helper) {
        helper.sendEmailtoCommunityUser(component, event, helper);
        component.set('v.showCommunityUserInfo', false);
    },*/
    checkFinalize:function(component, event, helper) {
      //  alert('>>>>checkFinalize');//
        console.log('>>>>>component allAccounts:: '+JSON.stringify(component.get("v.allAccounts")));
        console.log('>>>>>component ParentAccountId":: '+JSON.stringify(component.get("v.ParentAccountId")));
        var action = component.get("c.isPeoUwImplementationReadyForFinalize");
        action.setParams({
            allAccounts: component.get("v.allAccounts"),
            parentAccountId: component.get("v.ParentAccountId")
        });
        action.setCallback(this, function(res) {
            console.log('>>>>checkFinalize:response:::'+JSON.stringify(res.getReturnValue()));
             console.log('>>>>checkFinalize:getstate:::'+JSON.stringify(res.getState()));
             var returnVal = res.getReturnValue();
            // alert('>>returnVal:: '+returnVal);
            if (res.getState() != 'SUCCESS') {
               // alert('>>error');
                console.log('>>>error:::'+JSON.stringify(res.getError()));
                component.set("v.isFinalizeDisable",returnVal); 

            }
            else{
               
                component.set("v.isFinalizeDisable",returnVal); 
            }
        })
        $A.enqueueAction(action);
        
    },

 
    /*getToggleButtonValue: function(component, event, helper) {
        var checkToggle = component.find("tglbtn").get("v.checked");
        if(checkToggle){
            component.set('v.buttonText', 'Send Notification');
        }else{
            component.set('v.buttonText', 'Confirm without notifying the client');
        }
    }*/
    
    /*handleChange: function(component, event, helper) {
        //helper.runAutoSave(component, event, helper, event.getSource()); 
    },
    
    save: function(component, event, helper) {
        helper.saveImplementationQuestions(component, event, helper); 
    },   
    cancelModal: function(component, event, helper) {
        component.set('v.showCommunityUserInfo', false);
    },
    
    sendEmail: function(component, event, helper) {
        helper.sendEmailtoCommunityUser(component, event, helper);
        component.set('v.showCommunityUserInfo', false);
    },
    
    finalize: function(component, event, helper) {
        if(component.get('v.peoFullChecklist').CS_CM_Contract_Status__c == undefined ||
           component.get('v.peoFullChecklist').CS_CM_Contract_Status__c != 'Approved'){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: 'Error',
                message: 'CS CM Contract Status needs to be Approved in order to finalize the questions!',
                type: 'ERROR'
            });
            toastEvent.fire();
        }else{
            component.set('v.showCommunityUserInfo', true);
        }
    },*/
})