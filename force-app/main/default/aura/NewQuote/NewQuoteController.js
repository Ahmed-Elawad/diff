({
	doInit : function(component, event, helper){
        helper.getUserInfo(component);
        helper.getPicklistValues(component);
	},
	cancelNewQuote : function(component, event, helper){
		helper.cancelNewQuote(component, event, helper);
	},
	saveQuote : function(component, event, helper){
		helper.saveQuote(component, event, helper);
	},
	
})