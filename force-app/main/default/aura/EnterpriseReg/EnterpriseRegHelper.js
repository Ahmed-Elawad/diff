({
    getTrackerRecs : function(component, helper, initialize) {
        var action = component.get("c.getRegInfo");
        action.setParams(
            {
                "recordId":component.get("v.opptyId")
            })
        action.setCallback(this, function(response) { 
            var name = response.getState();
            if (name === "SUCCESS") {
                var wrap = response.getReturnValue();
                component.set("v.sstActive",true);

                var isMMSStandalone = wrap.tracker.IsOppEnterprise__c ? false : true;
                component.set("v.isMMSStandalone", isMMSStandalone);
                //Add Tracker
                component.set("v.parentTracker", wrap.tracker);
                component.set("v.showCttButton", wrap.showCTTBtn);
                var isMulti = wrap.childWraps.length > 0 ? true : false;
                component.set("v.isMulti", isMulti);
                //Add Children
                if(isMulti){
                    component.set("v.childWrapperList", wrap.childWraps);
                }
                if(initialize){
                    var accountLabel = isMulti ? 'Parent Prospect Client' : 'Prospect Client Name';
                    component.set("v.productList", wrap.salesSubProds);
                    component.set("v.acct", wrap.acct);
                    component.set("v.currentAcctId", wrap.acct.Id);
                    component.set("v.opportunity", wrap.opp);
                    component.set("v.currentAcctName", wrap.acct.Name);
                    component.set("v.parentAccountLabel", accountLabel);
                    component.set("v.currentTracker", wrap.tracker);
                    component.set("v.selectedId", wrap.tracker.Id);
                    helper.setFocusedTabLabel(component, event, helper, wrap.opp.Name);
                    component.set("v.formLoaded",true);
                }
                if (wrap.opp != null && wrap.opp.LeverageSST__c==true) {
                    component.set("v.leverageSSTValue",false);
                    component.set("v.leverageSSTButton","Click to not use SST");
                    component.set("v.sstVariant","brand");
                    component.set("v.submitBtnLabel","Create Client and Submit New Client Profile");
                } else if (wrap.opp != null && wrap.opp.LeverageSST__c==false) {
                    component.set("v.leverageSSTValue",true);
                    component.set("v.leverageSSTButton","Click to use SST");
                    component.set("v.sstVariant","brand-outline");
                    component.set("v.submitBtnLabel","Create Client");
                }
            } 
            helper.validate(component, helper);
            });
        $A.enqueueAction(action);
    },
    setFocusedTabLabel : function(component, event, helper, tabName) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: tabName
            });
        })
        .catch(function(error) {
            console.log('setFocusedTabLabel error' + error);
        });
    },
    validate : function(component, helper) {
        var parentOnboardingRec = component.get("v.parentOnboardingRec");
        var parentTracker = component.get("v.parentTracker");
        var isMulti = component.get("v.isMulti");
        var isMMSStandalone = component.get("v.isMMSStandalone");
        var isComplete = true;
        var isRevalidated = true;
        if(!parentTracker.AcctValidated__c || !parentTracker.SSTValidated__c){
            isComplete = false;
        }else if(!isMMSStandalone && parentTracker.RegistrationDetail__c !=null){
            component.set("v.registrationError", true);
            if(parentTracker.RevalidationNeeded__c){
                isRevalidated = false;
            }           
        }
        if(isMulti){
            var childWrapperList = component.get("v.childWrapperList");
            childWrapperList.forEach((childWrapper)=>{
                if(!childWrapper.tracker.AcctValidated__c || !childWrapper.tracker.SSTValidated__c){
                	isComplete = false;                	
            	}else if(!isMMSStandalone){
                	if(childWrapper.tracker.RegistrationDetail__c !=null){
                   		component.set("v.registrationError", true);
                    	if(childWrapper.tracker.RevalidationNeeded__c){
                        	isRevalidated = false;
                    	}
                	}
            	}
            });    
        }
    	if(!isMMSStandalone && parentTracker.RegistrationStart__c){
    		component.set("v.isComplete", false);
		}
 		component.set("v.isComplete", isComplete);
		component.set("v.revalidated", isRevalidated); 
    },
    changeSST : function(component, helper) {
        var opp = component.get("v.opportunity");
        var action = component.get("c.updateSSTOption");
        component.set("v.sstStatus","Changing SST Option...");
        action.setParams(
            {
                "oppId":opp.Id,
                "curValue":opp.LeverageSST__c
            })
        action.setCallback(this, function(response) { 
            var name = response.getState();
            component.set("v.sstStatus","");
            if (name === "SUCCESS") {
               //helper.getTrackerRecs(component,helper,true);
            }
            $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);
    },
})