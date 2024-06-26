({
	
    navigateToRelatedList : function(component, event, helper){
		var recordId = component.get("v.recordId");
        var objectType = component.get("v.objectType");
        console.log('navigateToRelatedList recordId: ', recordId);
		if(!!recordId && !!objectType){
            console.log('navigateToRelatedList inside if');
			var urlEvent = $A.get("e.force:navigateToURL");
	        urlEvent.setParams({
                "url": "/lightning/cmp/c__ReferenceClientRetentionRelatedList?c__recordId=" + recordId + "&c__objectType=" + objectType
	        });
	        urlEvent.fire();
            console.log('navigateToRelatedList after urlEvent.fire(): ', urlEvent);
	    }	
        console.log('navigateToRelatedList end');
    },
})