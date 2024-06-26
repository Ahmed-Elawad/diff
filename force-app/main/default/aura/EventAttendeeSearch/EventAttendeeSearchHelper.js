({
    getActiveUsers: function(component, event, helper) {
        component.set("v.isSearching", true);
        var action = component.get("c.getAllActiveUsers");
        var searchParams = component.get("v.searchParams");
        if(searchParams) {
            action.setParams({
                "searchParam": searchParams
            });
        }
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state === 'SUCCESS') {
                var activeUsers = response.getReturnValue();
                component.set("v.activeUsers", activeUsers);
                component.set("v.isSearching", false);
            } else {
                console.error(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    attachUsers: function(component, event, helper) {
        var evtId = component.get("v.eventId");
        var attendeeList = component.get("v.selectedUsers");
//        var attendeeList = component.get("v.selectedUsers").map(user => user.Id);

        var action = component.get("c.inviteAttendees");
        action.setParams({
            "evtId": evtId,
            "attendeeUsers": attendeeList
        });
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state === 'SUCCESS') {
                // close modal
                $A.get("e.force:closeQuickAction").fire();
                // throw success toast
                helper.toastSuccess();
            } else {
                console.error(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    toastSuccess: function(component, event) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            message: "Attendees added successfully!",
            type: "success"
        });
        toastEvent.fire();
    }
})