({
    checkSubmissionStatus : function(component, event, helper) {
        helper.getPEOchecklistDetailsJS(component, event, helper);
        helper.getSubmissionStatusJs(component, event, helper);
        helper.getRequiredDocumentsData(component, event, helper);
        helper.getAllChecklists(component, event, helper);

        var checkList = component.get("v.parentPEOChecklist");
        console.log('PEOCheckListData', checkList)
        if(checkList){
            var isQuickQuote = checkList.Medical_Underwriting_Path_Type__c != null && checkList.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical';
            var wcquickQuote = checkList.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp';
           
            var isQQWCSubmit=false;
            if(checkList.Medical_Underwriting_Path_Type__c!='Salesforce Forced - Medical' &&
              checkList.Workers_Comp_Underwriting_Path_Type__c!='Salesforce Forced - Workers Comp' &&
              checkList.Do_you_need_full_underwriting_path__c!='Yes' && 
              checkList.Is_Medical_Underwriting_Requested__c=='Currently does not have Medical and not interested in Medical, do not quote'){
                isQQWCSubmit=true;
            }
            console.log('isQQWCSubmit:'+ isQQWCSubmit);
            component.set("v.QQWCSubmit", isQQWCSubmit);
            
			
            component.set("v.isTraditional", checkList.Medical_Underwriting_Path_Type__c != null && isQuickQuote == false && checkList.Medical_Underwriting_Path_Type__c != 'No Medical Requested');
            component.set("v.wCTraditional", !wcquickQuote);
            console.log('isTraditional:'+component.get("v.isTraditional"));
            console.log('wCTraditional:'+component.get("v.wCTraditional"));
        }
    },

    submitCensus : function(component, event, helper){
         
    },
    
    submitDocuments : function(component, event, helper) {
        if(!component.get('v.isCompanyInfoAYBFilled')){
            let err = [];
            err.t = 'Error';
            err.m = 'Required field(s) missing in Company Information - About Your Business tab';
            err.ty = 'error';
            helper.showUserMsg(component, err);
        } else if(!component.get('v.isCompanyInfoADFilled')){
            let err = [];
            err.t = 'Error';
            err.m = 'Required field(s) missing in Company Information - Additional Details tab';
            err.ty = 'error';
            helper.showUserMsg(component, err);
        }else if(!component.get('v.allDocumentsUploaded')){
            let err = [];
            err.t = 'Error';
            err.m = 'Please upload all required documents!';
            err.ty = 'error';
            helper.showUserMsg(component, err);
        }else{
            
            var custData = component.get('v.accountList');
            var valid = true;            
            if(valid){
                //component.set('v.finishButtonClicked',true);
                console.log(component.get("v.isTraditional"));
                console.log('wCTraditional ' + component.get("v.wCTraditional"));
                if(component.get("v.isTraditional")|| component.get("v.wCTraditional")){
                       if(component.get("v.wCTraditional")){
                        helper.validateWCFields(component, event, helper)
                        .then(function(res) {                        
                            helper.submitAllDocuments(component, event, helper);
                            helper.switchLoadState(component, event, helper);
                        })
                        .catch(function(err) {
                            helper.showUserMsg(component, err)
                        });
                    }
                    else if(component.get("v.isTraditional")){
                        helper.validateFields(component, event, helper)
                        .then(function(res) {                        
                            helper.submitAllDocuments(component, event, helper);
                            helper.switchLoadState(component, event, helper);
                        })
                        .catch(function(err) {
                            helper.showUserMsg(component, err)
                        });
                    }
                }
                else{
                    //helper.submitAllDocuments(component, event, helper);
                    helper.switchLoadState(component, event, helper);
                    helper.submitCensusflip(component, event, helper);
                }
                
            }else{
                //Confirm if this is the correct error?
                let err = [];
                err.t = 'Error';
                err.m = 'Business Entity Type is required in company information.';
                err.ty = 'error';
                helper.showUserMsg(component, err);
            }
        }
    },
    SavesubmitQs : function(component, event, helper) {
          var action = component.get("c.UpdatePEOCheckListData");
        console.log('PEOCheckListData: ' + component.get('v.PEOCheckListData'));
        action.setParams({  
            "accountId": component.get('v.parentRecId'),
            "PEOCheckListData":  component.get('v.PEOCheckListData')
        });
        
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){  
                let err = [];
                err.t = 'Success';
                err.m = 'Successfully Saved!';
                err.ty = 'success';
                helper.showUserMsg(component, err);     
				}  
        });  
        $A.enqueueAction(action);
    },
    
    ShowHideAll: function (component, event) {
        let activeSections = component.get("v.activeSections");
        if (activeSections.length === 0) {
            component.set("v.activeSections",["hsf_error_log"]);
        } else {
            component.set("v.activeSections",[]);
        }
    },
    
    refreshStatus : function(component, event, helper){
        // Fire selfRefreshComp Evt (start)
        // Get the component event by using the name value from aura:registerEvent
        console.log('Inside refresh status');
        // find a component with aura:id="myCmp" in markup
        var myCmp = component.find("refreshButton");
        var hasClass = $A.util.hasClass(myCmp, "rotate");
        console.log('refreshStatus hasClass:'+hasClass);
        if(!hasClass){
            console.log('Adding rotate 1');
            //$A.util.removeClass(component.find("refreshButton"), "rotate");
            $A.util.addClass(myCmp, "rotate");
        }
        else{
            console.log('Adding rotate 2');
            $A.util.removeClass(myCmp, "rotate");
            $A.util.addClass(myCmp, "rotate");
        }
        var selfRefreshEvent = component.getEvent("selfRefreshEvt");      
        selfRefreshEvent.fire(); 
        // Fire selfRefreshComp Evt (end)
    },
    
    getValueFromLwc : function(component, event, helper) {
        //Change for QQ submit Blocker SFDC-23733 
		component.set("v.PEOCheckListData",event.getParam('peoChkData'));
        var checkList = component.get("v.parentPEOChecklist");
        var isQuickQuote = false;
        var wcquickQuote = false;
        if(checkList){
           isQuickQuote  = checkList.Medical_Underwriting_Path_Type__c != null && checkList.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical';
            wcquickQuote = checkList.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp';
        }
        if(component.get("v.PEOCheckListData.pkzPEOUnderwritingChecklistID__c") == null && (isQuickQuote ||  wcquickQuote )){
            component.set('v.disableFinishButton',true);
        }
        else{
            component.set('v.disableFinishButton',false);
        }
	}
})