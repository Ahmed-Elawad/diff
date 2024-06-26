({
    navigate: function(component, event, helper) {
        var linkUrl = component.get("v.linkItem.link");
        var urlEvent = $A.get("e.force.navigateToURL");
        urlEvent.setParams({
            "url": linkUrl
        });
        urlEvent.fire();
    }
})