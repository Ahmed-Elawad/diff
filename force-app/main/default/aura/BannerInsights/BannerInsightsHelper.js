({
	navigate : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var objectType = component.get("v.objectType");
        var openInsights = component.get("v.openInsights");
        if(objectType!='Account'){
            console.log('recordId::'+recordId);
            console.log('objectType::'+objectType);
            var evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
                componentDef : "c:MarketingInsightsDetail",
                componentAttributes: {
                    recordId : recordId,
                    objectType : objectType,
                    openInsights: openInsights
                }
            });
            evt.fire();
        }
    },
    navigateToRelatedList : function(component, event, helper){
		var recordId = component.get("v.recordId");
        var objectType = component.get("v.objectType");
        
        console.log('recordId::'+recordId);
        console.log('objectType::'+objectType);
        
        //var relatedList = 'Marketing_Insights__r';
        var relatedList = 'Customer_Intent_Signals__r';
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/lightning/r/" + recordId + "/related/" + relatedList + "/view"
        });
        urlEvent.fire();
	}
})