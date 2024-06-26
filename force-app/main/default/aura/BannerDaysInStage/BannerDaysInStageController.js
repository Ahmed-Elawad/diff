({
    doInit: function(component, event, helper) {
        // take lastStatusDate and subtract it from today
        var lastStatusDateString = component.get("v.opportunity");
        var lastStatusDate = new Date(lastStatusDateString);

        var today = new Date();

        var oneDay = 1000 * 60 * 60 * 24;

        var diff = today - lastStatusDate;

        component.set("v.daysInStatus", Math.round(diff / oneDay));
    }
})