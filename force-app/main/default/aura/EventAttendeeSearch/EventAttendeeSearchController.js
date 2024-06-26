({
    doInit: function(component, event, helper) {
        var evtId = component.get("v.eventId");
        component.set('v.columns', [
            { label: 'Name', fieldName: 'Name', type: 'text' },
            { label: 'Title', fieldName: 'Title', type: 'text' },
            { label: 'Phone', fieldName: 'Phone', type: 'phone' },
            { label: 'Email', fieldName: 'Email', type: 'email' }
        ]);
    },
    searchForUser: function(component, event, helper) {
        helper.getActiveUsers(component, event, helper);
    },
    selectUser: function(component, event, helper) {
        var attendee = event.getParam("attendee");
        var selectedUsers = component.get("v.selectedUsers");
        selectedUsers.push(attendee);
        component.set("v.selectedUsers", selectedUsers);
    },
    attachUsersToEvent: function(component, event, helper) {
        var attendeesToAdd = component.get("v.selectedUsers");
        helper.attachUsers(component, event, helper);
    }
})