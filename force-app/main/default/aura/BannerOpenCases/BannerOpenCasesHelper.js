({
	navigateToRelatedList : function(component, event, helper) {
		var recordId = component.get("v.recordId");
		var objectType = component.get("v.objectType");

		if(!!recordId && !!objectType){

			var relatedList = 'Cases';

			if(objectType.includes('__c')){
				relatedList = 'Cases__r';
			}

			var urlEvent = $A.get("e.force:navigateToURL");
	        urlEvent.setParams({
	            "url": "/lightning/r/" + recordId + "/related/" + relatedList + "/view"
	        });
	        urlEvent.fire();
	    }		
	}
})