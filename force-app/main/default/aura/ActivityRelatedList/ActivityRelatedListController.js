({
	doInit : function(component, event, helper) {
		helper.setRecordId(component, event, helper);
        helper.getActivitiesForRecordId(component, event, helper);
    }
})