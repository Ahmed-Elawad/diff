({
	doInit : function(component, event, helper) {
		helper.setRecordId(component, event, helper);
        helper.getMutualClientsForRecordId(component, event, helper);
	},
	getNewData : function(component, event, helper){
		console.log('eventFIREDDDD');
		helper.getMutualClientsForRecordId(component, event, helper);
	}
})