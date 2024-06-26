({
    getContactWrapper: function(component, event, helper) {
        var action = component.get("c.getContactWrapperById");
        action.setParams({
            contactId: component.get("v.contactId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state === 'SUCCESS') {
                var contactWrapper = response.getReturnValue();
                component.set("v.contactWrapper", contactWrapper);
            } else {
                console.error(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    insightsPilot: function(component, event, helper) {
        var action = component.get("c.insightsPilot");
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state === 'SUCCESS') {
                var isPilot = response.getReturnValue();
                component.set("v.isPilot", isPilot);
            } else {
                console.error(response.getError());
            }
        });
        $A.enqueueAction(action);
    }
})