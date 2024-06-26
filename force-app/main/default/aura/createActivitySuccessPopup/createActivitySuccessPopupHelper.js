({
	returnToFollowUpActivityCreation : function(component) {
		component.set("v.isFollowUpActivity", true);
		component.set("v.isVisible", false);
	},

	closeQuickAction2 : function(component) {
		component.set("v.isVisible", false);
		$A.get("e.force:closeQuickAction").fire() 
	},
})