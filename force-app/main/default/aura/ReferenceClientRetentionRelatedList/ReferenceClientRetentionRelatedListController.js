({
	doInit : function(component, event, helper) {
		helper.setRecordId(component, event, helper);
        helper.getRCRForRecordId(component, event, helper);
	},
    
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    }
})