({
	doInit : function(component, event, helper){
        helper.initialPresentationCheck(component);
        helper.setUpCreateActivity(component);
	},
    loadOptions: function (component, event, helper) {

        helper.populatePicklistValues(component);
        
    },
    handleOptionSelected: function (component, event, helper) { 
        helper.handleOptionSelected(component, event);

    },

})