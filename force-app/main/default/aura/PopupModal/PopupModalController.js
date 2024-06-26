({
	onIsVisibleChange : function(component, event, helper) {
		helper.toggleModalDisplay(component);
	},
	
	closeError : function(component, event, helper) {
		helper.closeModal(component);
	},

})