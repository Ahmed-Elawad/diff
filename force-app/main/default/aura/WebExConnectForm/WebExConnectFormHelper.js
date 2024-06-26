({
    setUpComponent : function(component, helper) {
        var idList = ["0054u000006qLhsAAE", 
                      "0054u000006mzlrAAA", 
                      "00570000004olzvAAA",
                      "0050g000005MIFNAA4",
                      "0054u000006nMqfAAE",
                      "0054u0000071tVyAAI",
                      "0054u0000071tbIAAQ",
                      "0054u000008kmHsAAI",
                      "0054u000008tWbEAAU",
                      "0054u000008tcQHAAY",
                      "00570000003Abe9AAC",
                      "00570000003QPvBAAW",
                      "00570000004oUMmAAM",
                      "0050g000004x11iAAA",
                      "0050g000005fcYcAAI",
                      "0050g000006SQxdAAG",
                      "0054u000007223AAAQ",
                      "00570000002CKqnAAG",
                      "00570000003y5hvAAA",
                      "00570000004olzgAAA",
                      "005700000051lFZAAY",
                      "0050g000006S4VwAAK",
                      "0054u000005ovUNAAY",
                      "0054u0000072yHFAAY",
                      "0054u00000733hhAAA",
                      "00570000001bpIvAAI",
                      "00570000004of2EAAQ",
                      "00570000004olwmAAA",
                      "00570000004olzqAAA",
                      "005700000051u2AAAQ",
                      "00570000005QhGEAA0",
                      "00570000005QwHbAAK"];
        var profileList = [ "00e70000001JszNAAS", "00e30000000mTjPAAU"];
        var action = component.get('c.getCurrentUserInfo'); 
        
        action.setCallback(this, function(response) {
            var webexHost = response.getReturnValue();
            component.set("v.host", webexHost);
            //alert(webexHost.ProfileId);
            if(webexHost.FirstName!= null){
                component.set("v.hostName", webexHost.FirstName+' '+webexHost.LastName);              
            }
            if(idList.includes(webexHost.Id) || profileList.includes(webexHost.ProfileId)){
                component.set("v.hasFormAccess", true);
            }
          
        });
        $A.enqueueAction(action);
    },
	callWebexWidget : function(component, helper) {
        component.set("v.showSpinner", true);
        var attendees;
        var attendeesEmails;
        var hostRec = component.get("v.host");
        var primaryAttendee = component.get("v.attendee");
        var primaryAttendeeEmail = component.get("v.attendeeEmail");
        var meetingTitle = component.get("v.title");
        var additionalAttendees = component.get("v.addAttendees");
        var objectId = component.get("v.objectRecId");
        if(primaryAttendee != null){
            attendees = primaryAttendee;
            attendeesEmails = primaryAttendeeEmail;
        }
        if(additionalAttendees){
            if(component.get("v.addAttendeeName1") !=null){
                attendees = attendees != null ? attendees +','+component.get("v.addAttendeeName1") : component.get("v.addAttendeeName1");
                attendeesEmails = attendeesEmails != null ? attendeesEmails +','+component.get("v.addAttendeeEmail1"):component.get("v.addAttendeeEmail1");
            }
            if(component.get("v.addAttendeeName2") !=null){
                attendees = attendees != null ? attendees +','+component.get("v.addAttendeeName2") : component.get("v.addAttendeeName2");
                attendeesEmails = attendeesEmails != null ? attendeesEmails +','+component.get("v.addAttendeeEmail2"):component.get("v.addAttendeeEmail2");
            }
            if(component.get("v.addAttendeeName3") !=null){
                attendees = attendees != null ? attendees +','+component.get("v.addAttendeeName3") : component.get("v.addAttendeeName3");
                attendeesEmails = attendeesEmails != null ? attendeesEmails +','+component.get("v.addAttendeeEmail3"):component.get("v.addAttendeeEmail3");
            }
        }
        var action = component.get('c.initiateWidget'); 
        action.setParams(
            {
                host: hostRec,
                attendeeNames:attendees,
                attendeeEmails:attendeesEmails,
                contactname:primaryAttendee,
                title:meetingTitle,
                objectRecordId:objectId
            })
        action.setCallback(this, function(response){ 
            component.set("v.showSpinner", false);
            var name = response.getState();
            var emailSuccessfullySent = response.getReturnValue();
            if (name === "SUCCESS" && emailSuccessfullySent == true) {
                component.set("v.buttonDisabled", true);
                var showToast = $A.get("e.force:showToast");
                showToast.setParams({ 
                    'title' : 'An email has been sent on your behalf to the attendee(s) listed below to a Webex meeting space', 
                    'type' : 'success',
                    'mode' : 'sticky',
                    'message' : 'Please note the following:' 
                    +'\n1. You should receive an email shortly containing a link to the Webex meeting space.'
                    +'\n2. You will be listed as the host of the meeting.'
                    +'\n3. Only the attendee(s) provided in this form will have access to the meeting space.'
                });               
                showToast.fire();
            }});
        $A.enqueueAction(action);
    },
})