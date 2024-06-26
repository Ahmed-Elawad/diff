({
	initialize : function(component, event, helper) {
		helper.formatDisplayFields(component);
		helper.getCasesForAccount(component);
	},

	showSubmitButton : function(component, event, helper){
		helper.showSubmitButton(component);
	},

	onSaveSuccess : function(component, event, helper){
		helper.showSuccessMessage(component);
		helper.hideSpinner(component);
	},
	onRecordSave : function(component, event, helper){
		helper.showSpinner(component);
	}
})