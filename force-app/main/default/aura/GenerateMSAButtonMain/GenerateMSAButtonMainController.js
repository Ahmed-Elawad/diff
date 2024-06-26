({
	doInit : function(component, event, helper) {
        var action = component.get('c.getTracking');
        action.setParams(
            {
                "recordId":component.get("v.recordId")
            })
        action.setCallback(this, function(response){           
            var name = response.getState();
            if (name === "SUCCESS") {
                component.set("v.csoTracking", response.getReturnValue());
                console.log(response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        //console.log('handleClick',event.target.id);
    }
})