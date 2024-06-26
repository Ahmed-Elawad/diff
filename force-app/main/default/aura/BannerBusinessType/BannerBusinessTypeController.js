({
    doInit: function(component, event, helper) {
        var businessType = component.get("v.referralBusinessType");

        var display = helper.setDisplayByReferralSourceBusinessType(component, event, helper, businessType);

        component.set("v.imageName", display.image);
        component.set("v.color", display.color);
    }
})