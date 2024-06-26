({
    getAccountWrapper: function(component, event, helper) {
        var action = component.get("c.getAccountWrapperById");
        
        action.setParams({
            accountId: component.get("v.accountId")
            
        });
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state === 'SUCCESS') { 
                var accountWrapper = response.getReturnValue();
                console.dir(accountWrapper);
                component.set("v.accountWrapper", accountWrapper);
            console.log('susss', accountWrapper);

                                
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