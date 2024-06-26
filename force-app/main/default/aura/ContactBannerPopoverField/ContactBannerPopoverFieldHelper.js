({
	navigateToRecord : function(component, event, helper) {
		var fieldLookupId = component.get("v.field.lookupIdValue");
        if(!!fieldLookupId){
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
              "recordId": fieldLookupId,
            });
        	navEvt.fire();
        }
	}
})