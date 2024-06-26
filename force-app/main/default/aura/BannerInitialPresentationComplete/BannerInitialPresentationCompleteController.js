({
    doInit: function(component, event, helper) {
        var relatedEvents = component.get("v.relatedPresentationEvents");
        helper.filterCompletePresentations(component, relatedEvents);
        helper.filterScheduledPresentations(component, relatedEvents);
    },


    navigateToRelatedList: function(component, event, helper){
        helper.navigateToActivityTab(component, event, helper);
    }
})