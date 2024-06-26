({
    getOpportunityWrapper: function(component, event, helper) {
        var action = component.get("c.getOpportunityWrapperById");
        action.setParams({
            opportunityId: component.get("v.opportunityId")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state === 'SUCCESS') {
                var opportunityWrapper = response.getReturnValue();
                component.set("v.opportunityWrapper", opportunityWrapper);
                var today = new Date(); 
                var dd = String(today.toJSON());
                if(opportunityWrapper.portalUsers.Requested_Invite_Date__c > dd){
                    component.set("v.inviteNotSent", true);
                }
                console.log('AE TRACC');
                console.log(opportunityWrapper);
            } else {
                console.error(response.getError());
            }
        });
        $A.enqueueAction(action);
    },

})