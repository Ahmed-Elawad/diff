({
    retrieveTouchpoint : function(component) {
        var eventUpdate = component.get("v.eventUpdate");
        var action = component.get("c.retrieveOpenTouchpoint");
        action.setParams({"parentId": component.get("v.recordId")});
        action.setCallback(this, function(response) {
            //store state of response
            var touchpoint = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                if(touchpoint != null){
                    component.set("v.openTouchpoint", touchpoint);
                    component.set("v.recordLoaded", true);
                }
               /* if(eventUpdate){
                    helper.displayToast('success','Confirmation!','Touchpoint Updated.');
                }*/
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