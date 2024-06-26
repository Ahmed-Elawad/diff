({
	fetchReferralCons : function(component, event) {
		var action = component.get("c.fetchActiveReferralContacts");
        
        action.setParams({ refAcId : component.get("v.recordId") });

        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('fetchReferralCons Response:');
                console.log(response);
                console.log('Referral Contact Helper response===>'+JSON.stringify(response.getReturnValue()));
                component.set("v.data",response.getReturnValue());// Alert the user with the value returned
            }else if (state === "INCOMPLETE") {
                // do something
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        // optionally set storable, abortable, background flag here

        // A client-side action could cause multiple events, 
        // which could trigger other events and 
        // other server-side action calls.
        // $A.enqueueAction adds the server-side action to the queue.
        $A.enqueueAction(action);
	},
    checkAccessPerm : function(component, event, helper){
        var action2 = component.get("c.hasCustomPermission");
        action2.setCallback(this, function(response){
            console.log('v.hasPermissionv.hasPermissionv.hasPermissionv.hasPermission'+response.getReturnValue());
            component.set("v.hasPermission", response.getReturnValue())
        });
        $A.enqueueAction(action2);
    }
})