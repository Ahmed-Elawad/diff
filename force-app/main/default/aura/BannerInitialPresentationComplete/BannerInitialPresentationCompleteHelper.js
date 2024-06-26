({
    filterCompletePresentations: function(component, relatedEvents) {
        // look for one where where ActivityDate < Today && Outcome__c is not null
        var completePresentation = relatedEvents.filter(event => {
            var activityDate = new Date(event.ActivityDate);
            var today = new Date();

            return activityDate < today && event.Outcome__c;
        });
        component.set("v.showPresentationComplete", completePresentation.length > 0);
    },
    filterScheduledPresentations: function(component, relatedEvents) {
        // look for one where ActivityDate >= Today
        var scheduledPresentation = relatedEvents.filter(event => {
            var activityDate = new Date(event.ActivityDate);
            var today = new Date();

            return activityDate >= today;

        });
        component.set("v.showPresentationScheduled", scheduledPresentation.length > 0);
    },

    navigateToActivityTab : function(component, event, helper){
        var recordId = component.get("v.recordId");
        if(!!recordId){
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": "/lightning/cmp/c__ActivityRelatedList?recordId=" + recordId
            });
            urlEvent.fire();
        }   
    },
})