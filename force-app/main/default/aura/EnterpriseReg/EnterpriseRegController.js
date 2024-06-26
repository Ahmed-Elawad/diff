({
    doInit : function(component, event, helper) {
        helper.getTrackerRecs(component, helper, true);
    },
    checkUpdates : function(component,  event, helper) {       
        helper.getTrackerRecs(component, helper, false);
    },
    closeFocusedTab : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    sstClicked : function(component, event, helper) {
       component.set("v.sstActive",false);
       component.set("v.leverageSSTButton","Processing Change...");
       component.set("v.sstStatus","Processing Change...");
       helper.changeSST(component,helper);
       //component.set("v.sstStatus","");
    },
    updateCurrentTrackingRec : function(component, event, helper) {
        component.set("v.hideAcctComponent", true);
        var selectedId = event.getParam('name');
        var parentTracker = component.get("v.parentTracker");
        var acct = component.get("v.acct"); 
        //alert("Parent "+parentTracker.Id+" Current "+selectedId);
        if(selectedId == parentTracker.Id){
            component.set("v.currentTracker", parentTracker);
            component.set("v.currentAcctId", acct.Id);
            component.set("v.currentAcctName", acct.Name);
        }else{
            var childWrappers = component.get("v.childWrapperList");
            childWrappers.forEach(function (wrapper) {
                if(selectedId == wrapper.tracker.Id){
                    component.set("v.currentTracker", wrapper.tracker); 
                    component.set("v.currentAcctId", wrapper.acct.Id);
                    component.set("v.currentAcctName", wrapper.acct.Name);
                }
            });
        }
        component.set("v.selectedId", selectedId);
        component.set("v.hideAcctComponent", false);
    },
    submitEntForm : function(component, event, helper) {
        component.set("v.loadSpinner", true);
        var isMulti = component.get("v.isMulti");
        var successfulSubmission = true;
        
        var action = component.get("c.startEntRegRequestNow"); 
        action.setParams(
            {
                "trackerId" : component.get("v.parentTracker").Id,
                "processFirst" : isMulti
            })
        action.setCallback(this, function(response) {           
            var name = response.getState();
            var responseWrapper = response.getReturnValue();
            component.set("v.loadSpinner", false);
            if (name === "SUCCESS") {
                if(responseWrapper.statusCode != 200){
                    var showToast = $A.get("e.force:showToast"); 
                    showToast.setParams({ 
                        'title' : 'Submission Failed', 
                        'type' : 'error',
                        'message' : responseWrapper.message
                    }); 
                    showToast.fire();
                    component.set("v.registrationError", true);
                    component.set("v.regErrorText", responseWrapper.message);
                    successfulSubmission = false;
                }
            }
        });
        $A.enqueueAction(action);
        if(successfulSubmission){
            component.set("v.displayPostSubmitScreen", true);
        }
    },
    submitMMSForm : function(component, event, helper) {
        component.set("v.loadSpinner", true);
        
        var action = component.get("c.submitOnboarding"); 
        action.setParams(
            {
                "trackerId" : component.get("v.parentTracker").Id,
            })
        action.setCallback(this, function(response) { 
            var name = response.getState();
            var responseWrapper = response.getReturnValue();
            component.set("v.loadSpinner", false);
            if (name === "SUCCESS") {
                if(responseWrapper.statusCode != 200){
                    var showToast = $A.get("e.force:showToast"); 
                    showToast.setParams({ 
                        'title' : 'Submission Failed', 
                        'type' : 'error',
                        'message' : responseWrapper.message
                    }); 
                    showToast.fire();
                    successfulSubmission = false;
                }else{
                    var showToast = $A.get("e.force:showToast"); 
                    showToast.setParams({ 
                        'title' : 'Form Submitted Successfully', 
                        'type' : 'success',
                        'message' : 'The New Client Setup form has been submitted successfully.  You may now close the form.'
                    }); 
                    showToast.fire();
                }                
            }
        });
        $A.enqueueAction(action);
    },
    handleOppLoad : function(component, event, helper) {
    },
})