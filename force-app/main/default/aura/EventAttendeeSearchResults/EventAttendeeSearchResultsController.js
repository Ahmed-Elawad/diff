({
    selectUser: function(component, event, helper) {
        var selectedRow = event.getSource().get("v.value");
        helper.throwAttendeeSelectedEvent(component, event, selectedRow);
        helper.removeUserFromSearchResults(component, event, selectedRow);
    }
})