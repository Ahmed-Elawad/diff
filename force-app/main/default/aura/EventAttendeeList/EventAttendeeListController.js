({
    removeAttendee: function(component, event, helper) {
        var clickedAttendee = event.getSource().get("v.value");
        var selectedAttendees = component.get("v.selectedUsers");

        var indexToRemove = selectedAttendees.indexOf(clickedAttendee);

        selectedAttendees.splice(indexToRemove, 1);

        component.set("v.selectedUsers", selectedAttendees);
    }
})