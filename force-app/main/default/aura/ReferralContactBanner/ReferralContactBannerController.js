({
    doInit: function(component, event, helper) {
        helper.getReferralContactWrapper(component, event, helper);
        helper.checkAccessPerm(component, event, helper);

    },
    
    ini: function(component, event, helper) {
        var tmp= component.get("v.referralContact");
        console.log('----------->',JSON.stringify(tmp));
    }
})