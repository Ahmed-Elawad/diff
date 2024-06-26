({
    retrieveRT: function(component, helper) {
        var action = component.get("c.retrieveSalesHelpRT");
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                var salesHelpRt = response.getReturnValue();
                component.set("v.shRecordType", salesHelpRt);
            }
        });
        $A.enqueueAction(action);
    },
    validateCase: function(component) {
        var action = component.get("c.validateForm");
        action.setParams({"caseType": component.get("v.newCaseType"),
                          "caseSubType": component.get("v.newCaseSubType")});
        action.setCallback(this, function(response) {
            //store state of response
            var validateWrapper = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.formValidated", validateWrapper.formValid);
                if(validateWrapper.errorMessage != null){
                    component.find('notifLib').showToast({
                        "variant": validateWrapper.formValid ? "info" : "error",
                        "title": validateWrapper.formValid ? "Please Note" : "Something has gone wrong!",
                        "mode": "sticky",
                        "message": validateWrapper.urlLink != null ? validateWrapper.errorMessage+"\n {0}" : validateWrapper.errorMessage,
                        "messageData": [
                            {
                                url: validateWrapper.urlLink,
                                label: 'Click Here for Form'
                            }]
                            });
                }
                //component.set("v.validationError", validateWrapper.errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    displayToast : function(toastType, title, message){
        var showToast = $A.get("e.force:showToast"); 
        showToast.setParams({ 
            'title' : title, 
            'type' : toastType,
            'message' : message
        }); 
        showToast.fire();
    },
})