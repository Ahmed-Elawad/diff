({
	navigateToCase : function(component) {
		var caseItem = component.get("v.caseItem");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": caseItem.Id,
        });
        navEvt.fire();
	}
})