({
	handleChange : function(component, event, helper) {
		helper.sendAutoSave(component, event, helper);
	},
    
    validate:  function(component, event, helper) {
        var valid = true;
        var fields = component.find('isqQueChild');
        var val = component.get('v.autoIndustryRec.Has_service_auto_body_repair_department__c');
        if(val != undefined && val != '' && val != null){
            if(val == 'Yes'){
                var childCmp = component.find("childISQQue");
                valid = childCmp.validateFields();
            }else{
                valid = true;
            }
            return valid;
        }
        return false;
    }
})