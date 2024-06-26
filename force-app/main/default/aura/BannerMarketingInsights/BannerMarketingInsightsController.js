({
    doInit : function(component, event, helper) {
        var objType = component.get("v.objectType");
        if(objType==='Contact'){
            component.set("v.Contact", objType);
            console.log('objType con:::'+objType);
        }
        else if(objType==='Lead'){
            component.set("v.Lead", objType);
            console.log('objType lead:::'+objType);
        }
    }
})