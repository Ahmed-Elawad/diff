({
	getRefClientRetWrapper: function(component, event, helper) {
        var action = component.get("c.getRefClientRetWrapperById");
        var refClientRetId = component.get("v.refClientRetId");
        action.setParams({
            refClientRetId: refClientRetId
        });
        console.log('refClientRetId' + refClientRetId); 
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state === 'SUCCESS') {
                var refClientRetWrapper = response.getReturnValue();
		        console.log('refClientRetWrapper success' + JSON.stringify(refClientRetWrapper)); 
                component.set("v.ReferenceClientRetentionWrapper", refClientRetWrapper);
                
            } else {
                console.log('refClientRetWrapper error ' + response.getError());
                console.error(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
})