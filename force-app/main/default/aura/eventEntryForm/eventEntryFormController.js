({
    doInit : function(component, event, helper) {
        helper.setPicklistValues(component, helper);
        helper.setNewEvent(component, helper);
        component.set("v.newEvent.IsReminderSet", true);
    },

    handleActivityTypeChange : function(component, event, helper) {
        component.set("v.activityType", event.getParam("activityType"));
        component.set("v.sourceRecordId", event.getParam("sourceRecordId"));
        if(event.getParam("sourceObjectName") == 'Event'){
            helper.setNewEvent(component, helper);
        }
    }, 
    
    handleOptionSelected : function(component, event, helper) {
        var typeSelected = component.get("v.newEvent.Type");
        var hasInitPresentation = component.get("v.hasInitialPresentation");
        if(typeSelected.includes("Presentation - Initial") && hasInitPresentation){
            component.set("v.multipleInitialPresentation", true);
        }else{
            component.set("v.multipleInitialPresentation", false);
        }
    }, 
    
    handleDateValueChange: function(component, event, helper) {
        if(component.get("v.activityDateTime") != null){
            component.set("v.newEvent.ActivityDateTime", component.get("v.activityDateTime"));}
        var reminderSet = component.get("v.newEvent.IsReminderSet");
        if(reminderSet){
            helper.setReminderDate(component);
        }
        else{
            component.set("v.newEvent.ReminderDateTime", null);
        }     
    },

    clickSaveEvent: function(component, event, helper) {       

        var validItem = component.find('taskform').reduce(function (validSoFar, inputCmp) {
            if(typeof inputCmp.showHelpMessageIfInvalid !== "undefined"){
                console.log(inputCmp.showHelpMessageIfInvalid());
                validSoFar = validSoFar && inputCmp.get("v.validity").valid;

            }else{
                if(inputCmp.get("v.required") && inputCmp.get("v.value") == null){
                    validSoFar = false;
                    inputCmp.set("v.errors",[{message:"Complete this field"}])
                }else{
                    inputCmp.set("v.errors",null);
                }
            }

            return validSoFar; 
        }, true);
        
        if(validItem){
            helper.toggleSpinner(component, true);
            component.set("v.recordLoaded", false);
            var newEvent = component.get("v.newEvent");
        	var attendees = component.get("v.attendees");
            helper.performSaveEvent(component, helper, newEvent, attendees);

        }
    },
    
    /* Removed per a request during testing for APR0111608 - Capture Meeting Data; Requiring Attendees for Sales
    onAddAttendees : function(component, event, helper) {
        var contactId = component.find("contactField").get("v.value");
        console.log("contactId: " + contactId);
                
        var rec = component.get("v.recordFields");
        if(rec.Id == contactId)	{
            var valueAlreadyExist = 0;
            var attendees = component.get("v.attendees");
            if (attendees && Array.isArray(attendees) && attendees.length > 0) {
                for (var i = 0; i < attendees.length; i++) { 
                    if(attendees[i].value == rec.Id) valueAlreadyExist = 1;
                }
            }
            
            if(!Boolean(valueAlreadyExist))	{
                attendees.push({value: rec.Id, label: rec.Name });
                component.set("v.attendees", attendees);
            }
            else alert(rec.Name + " already is in Attendees.");
        }
    },    
	*/

    getContact : function(cmp, event, helper) {
        var lookupContactId = event.getSource().get('v.value'); //event.getParam('value')
        console.log("eventEntryFormController::getContact, lookupContactId: " + lookupContactId);     
        
        cmp.set("v.lookupContactId", lookupContactId);
        
        // trigger the recordUpdated event in the force:recordData, which will end up calling handleRecordUpdated()
        if(lookupContactId)	cmp.find('recordLoader').reloadRecord(true); 
    },    
    
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        console.log("eventEntryFormController::handleRecordUpdated, eventParams.changeType: " + eventParams.changeType);
        if(eventParams.changeType === "CHANGED") {
            // get the fields that changed for this record
            var changedFields = eventParams.changedFields;
            console.log('Fields that are changed: ' + JSON.stringify(changedFields));
            // record is changed, so refresh the component (or other component logic)
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title": "Saved",
                "message": "The record was updated."
            });
            resultsToast.fire();
            
        } else if(eventParams.changeType === "LOADED") {
            // record is loaded in the cache
            //var rec = component.get("v.recordFields");
            //console.log("* * * rec name: " + rec.Name);
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted and removed from the cache
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving or deleting the record
        }
    },
})