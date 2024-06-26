({
    getLeadWrapper: function(component, event, helper) {
        var action = component.get("c.getLeadWrapperById");
        action.setParams({
            leadId: component.get("v.leadId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state === 'SUCCESS') {
                var leadWrapper = response.getReturnValue();
                component.set("v.leadWrapper", leadWrapper);
                component.set("v.sensitivityList", leadWrapper.getSensitivities);
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