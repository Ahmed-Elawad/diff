({
    /*doInit : function(component, event, helper) {
        var rec = component.get("v.recordId");
        component.set("v.objectId", rec);
    },*/
    handleClick: function(component, event, helper) {
        var recId = component.get("v.recordId");
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:EnterpriseReg",
            componentAttributes: {
                opptyId : component.get("v.recordId")
            }
        });
        evt.fire();
    }
    
})