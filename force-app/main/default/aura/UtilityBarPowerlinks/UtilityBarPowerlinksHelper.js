({
    loadPowerLinks: function(component, event, helper) {
        var action = component.get("c.getPowerLinks");
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state === 'SUCCESS') {
                var powerLinks = response.getReturnValue();
                component.set("v.listOfLinks", helper.sortLinksAlphabetically(powerLinks));
            } else {
                console.error(response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    sortLinksAlphabetically: function(links) {
        return links.sort(function(a, b) {
            var labelA = a.Label__c.toUpperCase();
            var labelB = b.Label__c.toUpperCase();

            return labelA > labelB;
        });
    }
})