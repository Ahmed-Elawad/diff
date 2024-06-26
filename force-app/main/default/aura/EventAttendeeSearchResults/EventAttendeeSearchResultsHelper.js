({
    throwAttendeeSelectedEvent: function(component, event, selectedAttendee) {
        var evt = component.getEvent("attendeeSelected");
        evt.setParams({
            "attendee": selectedAttendee
        });
        evt.fire();
    },
    removeUserFromSearchResults: function(component, event, user) {
        var activeUsers = component.get("v.activeUsers");
        var indexToRemove = activeUsers.indexOf(user);
        activeUsers.splice(indexToRemove, 1);
        component.set("v.activeUsers", activeUsers);
    }
})