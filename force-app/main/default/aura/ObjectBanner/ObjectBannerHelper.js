({
    getBannerDisplaySettings: function(component, event, helper) {
        var action = component.get("c.getLightningBannerSettings");
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state === 'SUCCESS') {
                var bannerSettings = response.getReturnValue();
                component.set("v.bannerSettings", bannerSettings);
            } else {
                console.error(response.getError());
            }
        });
        $A.enqueueAction(action);
    }
})