({
	refreshChecklist : function(component, event, helper) {
		console.log('Helper refreshChecklist');
        let refreshChecklist = component.get('c.getPEOOnboardingChecklist');
        refreshChecklist.setParams({
            accountId:component.get('v.OnbPEOChecklist.Prospect_Client__c'),
            oldChecklist: component.get('v.OnbPEOChecklist'),
            formName: 'PEOUWAddDocs'
        });
        // on response we need to reject if there's an error
        // otherwise update the Onboarding checklist to latest value
        refreshChecklist.setCallback(this, function(res) {
            console.log('Set callback');
            component.set('v.init', true);
            if (res.getState() !== 'SUCCESS') {
                console.error(res.getError());
                return;
            }
            var updatedChecklist = res.getReturnValue();
            console.log('updatedChecklist:');
            console.log(updatedChecklist);
            component.set('v.OnbPEOChecklist',updatedChecklist);
        })
        $A.enqueueAction(refreshChecklist);
	},
})