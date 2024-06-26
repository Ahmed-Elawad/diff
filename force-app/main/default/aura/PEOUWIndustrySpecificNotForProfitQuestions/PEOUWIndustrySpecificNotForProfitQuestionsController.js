({
	handleChange : function(component, event, helper) {
        helper.sendAutoSave(component, event, helper);
        var areVolunteersUsed = component.get('v.notForProfitIndustryRec.Are_volunteers_used__c');
        if(areVolunteersUsed == 'No'){
            component.set('v.notForProfitIndustryRec.Num_of_volunteers_if_not_filed_irs_990__c', '');
            helper.sendChangedValuesToAutoSave(component, event, helper, 'Num_of_volunteers_if_not_filed_irs_990__c', '');
            component.set('v.notForProfitIndustryRec.Num_of_volunteers_expected_next_year__c', '');
            helper.sendChangedValuesToAutoSave(component, event, helper, 'Num_of_volunteers_expected_next_year__c', '');
            component.set('v.notForProfitIndustryRec.what_are_volunteer_responsibilities__c', '');
            helper.sendChangedValuesToAutoSave(component, event, helper, 'what_are_volunteer_responsibilities__c', '');
        }
		
	},
    
    validate:  function(component, event, helper) {
        var valid = true;
        var fields = component.find('isqQue');
        if(fields != undefined && fields.length != undefined){
            for(let i = 0; i < fields.length; i++){
                fields[i].set('v.required', true);
            }
            valid = fields.reduce(function(v, f) {
                if (!v) return v;
                return f.checkValidity();
            }, true);
            return valid;
        }
        return false;
    }
})