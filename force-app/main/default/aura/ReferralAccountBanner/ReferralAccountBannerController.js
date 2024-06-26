({
    doInit: function(component, event, helper) {
        helper.getReferralAccountWrapper(component, event, helper);
        helper.checkAccessPerm(component, event, helper);
    }
})