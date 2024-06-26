({
	
    navigateToRelatedList : function(component, event, helper){
		var recordId = component.get("v.recordId");
		var objectType = component.get("v.objectType");
		var businessType = component.get("v.businessType");
		if(!!recordId && !!objectType){
			var urlEvent = $A.get("e.force:navigateToURL");
	        urlEvent.setParams({
	        	//"url": "/lightning/cmp/c__MutualClientRelatedList?recordId=" + recordId + "&objectType=" + objectType
                "url": "/lightning/cmp/c__MutualClientRelatedList?c__recordId=" + recordId + "&c__objectType=" + objectType + "&c__businessType=" + businessType
	        });
	        urlEvent.fire();
	    }	
    },
})