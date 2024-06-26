({
	navigateToParentOrChildren : function(component, event, helper) {
		var acc = component.get("v.account");
		if(!!acc.isParent__c){
			helper.navigateToChildren(component, acc);
		}else if(!!acc.isChild__c){
			helper.navigateToParent(component, acc);
		}
	},

	navigateToParent : function(component, acc){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": acc.SalesParent__c,
        });
        navEvt.fire();
		

	},

	navigateToChildren : function(component, acc){
		var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/lightning/r/" + acc.Id + "/related/Sales_Parent__r/view"
        });
        urlEvent.fire();
	}
})