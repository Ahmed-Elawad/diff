({
    navigateToSummary : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:peoOnboardingSummary",
            componentAttributes: {
                recordId : component.get("v.recordId")
            }
        });
        
        console.log('component.get("v.recordId") = '+ component.get("v.recordId"));
        
        evt.fire();
    } 
})