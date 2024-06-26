({
	
    navigateToActivityTab : function(component, event, helper){
		var recordId = component.get("v.recordId");
		if(!!recordId){
			var urlEvent = $A.get("e.force:navigateToURL");
	        urlEvent.setParams({
	        	"url": "/lightning/cmp/c__ActivityRelatedList?c__recordId=" + recordId
	            //"url": "/runtime_sales_activities/activityViewAll.app?parentRecordId=" + recordId
	        });
	        urlEvent.fire();
	    }	
    },
})