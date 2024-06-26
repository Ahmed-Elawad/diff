({
    doInit : function(component, event, helper) {
        helper.setUpComponent(component, helper);
    },
    onRecordIdChange : function(component, event, helper) {
        var objectRecordId = component.get("v.recordId");
        var action = component.get('c.getRecordInfo'); 
        action.setParams(
            {
                "recordId": objectRecordId
            })
        action.setCallback(this, function(response) {
            var startObject = response.getReturnValue();
            component.set("v.buttonDisabled", false);
            component.set("v.title", null);
            component.set("v.addAttendeeName1", null);
            component.set("v.addAttendeeName2", null);
            component.set("v.addAttendeeName3", null);
            component.set("v.addAttendeeEmail1", null);
            component.set("v.addAttendeeEmail2", null);
            component.set("v.addAttendeeEmail3", null);

            if(startObject == null){
                component.set("v.showAddAttendees", false);
                component.set("v.addAttendees", true);
            }else{
                component.set("v.showAddAttendees", true);
                component.set("v.addAttendees", false);
                component.set("v.objectRecId", startObject.Id);
                if(startObject.Id.startsWith('001')){
                    var attendeeName = startObject.SignificantContact__r.FirstName+' '+startObject.SignificantContact__r.LastName;
                    component.set("v.attendee", attendeeName);
                    component.set("v.attendeeEmail", startObject.Significant_Contact_Email__c);
                }else{
                    var attendeeName = startObject.FirstName+' '+startObject.LastName;
                    component.set("v.attendee", attendeeName);
                    component.set("v.attendeeEmail", startObject.Email);
                }
            } 
        });
        $A.enqueueAction(action);
    },
    addAttendee : function(component, event, helper) {
        component.set("v.addAttendees", true);
    },
    validateForm : function(component, event, helper) {
        var addAttend = component.get("v.addAttendees");
        var addAttend = component.get("v.addAttendees");
        var meetingTopic = component.get("v.title");
        var attend1Valid = true;
        var attend2Valid = true;
        var attend3Valid = true;
        var showattend = component.get("v.showAddAttendees");
        var title = "Missing Information";
        if(addAttend){
            var attendee1 = component.get("v.addAttendeeName1");
            var attendeeEmail1 = component.get("v.addAttendeeEmail1");
            var attendee2 = component.get("v.addAttendeeName2");
            var attendeeEmail2 = component.get("v.addAttendeeEmail2");
            var attendee3 = component.get("v.addAttendeeName3");
            var attendeeEmail3 = component.get("v.addAttendeeEmail3");
            if(attendee1!=null && attendeeEmail1 == null || attendee1==null && attendeeEmail1 != null)
                attend1Valid = false;
            if(attendee2!=null && attendeeEmail2 == null || attendee2==null && attendeeEmail2 != null)
                attend2Valid = false;
            if(attendee3!=null && attendeeEmail3 == null || attendee3==null && attendeeEmail3 != null)
                attend3Valid = false;
        }
        if(meetingTopic == null){
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({ 
                'title' : title, 
                'type' : 'warning',
                'mode' : 'sticky',
                'message' : 'Please enter meeting topic to proceed'
            });               
            showToast.fire();
        }else if(!showattend && (attendee1==null && attendee2==null && attendee3==null)){
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({ 
                'title' : title, 
                'type' : 'warning',
                'mode' : 'sticky',
                'message' : 'Please enter at least one attendee to proceed'
            });               
            showToast.fire();
        }
        else if(attend1Valid && attend2Valid && attend3Valid){
            helper.callWebexWidget(component, helper);
        }else{
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({ 
                'title' : title, 
                'type' : 'warning',
                'mode' : 'sticky',
                'message' : 'Please enter both the name and email of all attendees'
            });               
            showToast.fire();
        }
    },
})