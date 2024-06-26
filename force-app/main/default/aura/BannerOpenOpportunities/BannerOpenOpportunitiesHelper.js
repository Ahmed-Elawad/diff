({
	navigateToRelatedList : function(component, event, helper){
		var recordId = component.get("v.recordId");
		var objectType = component.get("v.objectType");
		if(!!recordId && !!objectType){

			var relatedList = 'Opportunities';
			if(objectType == 'Referral_Contact__c'){
				relatedList = 'OppRCs__r';
			}else if(objectType == 'Referral_Account__c'){
				relatedList = 'Opportunities__r';
			}

			var recordId = component.get("v.recordId");
			var urlEvent = $A.get("e.force:navigateToURL");
	        urlEvent.setParams({
	            "url": "/lightning/r/" + recordId + "/related/" + relatedList + "/view"
	        });
	        urlEvent.fire();
	    }
	}
})