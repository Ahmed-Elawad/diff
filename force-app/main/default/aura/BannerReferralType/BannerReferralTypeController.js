({
    doInit: function(component, event, helper) {
        var referralType = component.get("v.referralType");
        var businessType = component.get("v.businessType");
        var display = helper.setDisplayByReferralType(component, event, helper, referralType);
        if (!display) {
           display = helper.setDisplayByReferralSourceBusinessType(component, event, helper, businessType);
        }
        component.set("v.imageName", display.image);
        component.set("v.displayText", businessType);
        component.set("v.color", display.color);
    }
})