({
    doInit : function(component, event, helper) {
        var device = $A.get("$Browser.formFactor");
        component.set("v.device", device);
        helper.retrieveTouchpoint(component);
    },
    handleComponentEvent : function(component, event, helper){
        component.set("v.recordLoaded", false);
        component.set("v.eventUpdate", true); 
        helper.retrieveTouchpoint(component);
    },
})