({
    navigateToeDiscoverySearchCmp : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:communityForms",
            componentAttributes: {
                recordId : component.get("v.recordId")
            }
        });
        
        console.log('component.get("v.recordId") = '+ component.get("v.recordId"));
        
        evt.fire();
    } 
})