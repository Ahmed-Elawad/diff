({
    setNewEvent : function(component, helper) {
        component.set("v.recordLoaded","false");
        helper.toggleSpinner(component,true);

        var action = component.get("c.getNewEvent");
        
        action.setParams({
            "activityType": component.get("v.activityType"),
            "recordId": component.get("v.sourceRecordId"),
            "p_desc": component.get("v.descriptionAddOn"),
            "p_attendees": component.get("v.attendeesAddOn")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var newEvent = response.getReturnValue();
                newEvent.CarId__c=component.get("v.carId");
                helper.addDefaultsToPicklistOptions(component, helper, newEvent);

                if(component.get("v.isFollowUpActivity") || component.get("v.activityType") == $A.get("$Label.c.Activity_Type_Follow_Up_Meeting")){
                    newEvent.ActivityDateTime = null;
                }
                component.set("v.newEvent", newEvent);
                component.set("v.activityDateTime", component.get("v.newEvent.ActivityDateTime"));

            } else {
                console.log("Failed with state: " + state);
            }

            helper.toggleSpinner(component,false);
            component.set("v.recordLoaded","true");

        });

        $A.enqueueAction(action);
    }, 

    addDefaultsToPicklistOptions : function(component, helper, newEvent){
        if(component.get("v.profileName") === 'Sales Engineer'){

            var callTypeOptions = component.get("v.callTypeOptions");
            if(!helper.picklistOptionsContainsValue(callTypeOptions, newEvent.Lead_Source_WAR_Call_Type__c) && newEvent.Lead_Source_WAR_Call_Type__c){
                callTypeOptions.unshift({value: newEvent.Lead_Source_WAR_Call_Type__c, label: newEvent.Lead_Source_WAR_Call_Type__c });
                component.set("v.callTypeOptions", callTypeOptions);
            }

            var typeOptions = component.get("v.typeOptions");
            if(!helper.picklistOptionsContainsValue(typeOptions, newEvent.Type) && newEvent.Type){
                typeOptions.unshift({value: newEvent.Type, label: newEvent.Type });
                component.set("v.typeOptions", typeOptions);
            }

            newEvent.Outcome__c = "";
            newEvent.Lead_Source_WAR_Call_Type__c = "";
            newEvent.Type = "";

        }else{

            var callTypeOptions = component.get("v.callTypeOptions");
            if(!helper.picklistOptionsContainsValue(callTypeOptions, newEvent.Lead_Source_WAR_Call_Type__c) && newEvent.Lead_Source_WAR_Call_Type__c){
                callTypeOptions.unshift({value: newEvent.Lead_Source_WAR_Call_Type__c, label: newEvent.Lead_Source_WAR_Call_Type__c });
                component.set("v.callTypeOptions", callTypeOptions);
            }

            var typeOptions = component.get("v.typeOptions");
            if(!helper.picklistOptionsContainsValue(typeOptions, newEvent.Type) && newEvent.Type){
                typeOptions.unshift({value: newEvent.Type, label: newEvent.Type });
                component.set("v.typeOptions", typeOptions);
            }

            /*
             * Do not set the default value of Type dropdown if the Activity Type is Meeting 
             * and it is PEO user.
             */            
            if(component.get("v.activityType") == 'Meeting' && component.get("v.isThisPEOSalesUser"))	{
            	newEvent.Type = "";
        	}
            newEvent.Appointment_Type__c = "";
            newEvent.Onsite_or_Virtual__c = "";
            var refctct = component.get('v.refctct');
            console.log("Referral Contact in Event Entry Form"+refctct);
            //newEvent.Description += refctct.Name;
        }

        component.set("v.newEvent", newEvent);
    },

    setPicklistValues: function(component, helper) {

        var action = component.get("c.getDataEnvelope");
        action.setParams({
            "sourceObjectName": "Event"
        });

        action.setCallback(this, function(response) {
            
            var state = response.getState();
            if (state === "SUCCESS") {
                var envelope = response.getReturnValue();
                var options = envelope.options;
                var profileName = envelope.profileName;
                component.set("v.profileName", profileName);
                helper.setPicklistOptionAttributes(component, options);
                
            } else {
                console.log("Failed with state: " + state);
            }

        });

        $A.enqueueAction(action);
    }, 

    setPicklistOptionAttributes : function(component, picklistOptionWrappers){
        var callTypeOptions = [];
        var typeOptions = [];
        var outcomeOptions = [];
        var appointmentTypeOptions = [];
        var onsiteOrVirtualOptions = [];
        var CPETypeOptions = [];
        var tapTopicOptions = [];

        for (var i=0; i<picklistOptionWrappers.length; i++) {
            
            var picklistOption = picklistOptionWrappers[i];
            if (picklistOption.picklistName == $A.get("$Label.c.Activity_Call_Type_API_Name")) {
                callTypeOptions.push({value: picklistOption.value, label: picklistOption.label });
            } else if (picklistOption.picklistName ==  $A.get("$Label.c.Activity_Type_API_Name")) {
                if(component.get("v.activityType") == 'Meeting' && component.get("v.isThisPEOSalesUser"))	{
                    /*
                     * Only set the following Type dropdown values if the Activity Type is Meeting 
                     * and it is PEO user.
                     */            
                    if(picklistOption.value == "Presentation - Initial"
                       || picklistOption.value == "Presentation - Demo"
                       || picklistOption.value == "Presentation - Proposal"
                       || picklistOption.value == "Presentation - Pickup"
                       || picklistOption.value == "Presentation - GTM"
                       || picklistOption.value == "Expense/Mileage"  
                       ||  picklistOption.value == "Shared Free Payroll with 401k Promotion")
                     	{
                		typeOptions.push({value: picklistOption.value, label: picklistOption.label });                
                    }
                }
                else if(component.get("v.activityType") == 'Marketing' && component.get("v.isThisPEOSalesUser"))	{
                    /*
                     * Only set the following Type dropdown values if the Activity Type is Marketing 
                     * and it is PEO user.
                     */            
                    if(picklistOption.value == "Drop"
                       || picklistOption.value == "Networking"
                       || picklistOption.value == "Seminar"
                       || picklistOption.value == "Presentation - Follow-up")	{
                		typeOptions.push({value: picklistOption.value, label: picklistOption.label });                
                    }
                }
                else {                
                	typeOptions.push({value: picklistOption.value, label: picklistOption.label });                
                }
            } else if (picklistOption.picklistName == $A.get("$Label.c.Activity_Outcome_API_Name")) {
                outcomeOptions.push({value: picklistOption.value, label: picklistOption.label });
            } else if (picklistOption.picklistName == $A.get("$Label.c.Activity_Appointment_Type_API_Name")) {
                appointmentTypeOptions.push({value: picklistOption.value, label: picklistOption.label });
            } else if (picklistOption.picklistName == $A.get("$Label.c.Activity_Onsite_Or_Virtual_API_Name")) {
                onsiteOrVirtualOptions.push({value: picklistOption.value, label: picklistOption.label });
            } else if (picklistOption.picklistName == $A.get("$Label.c.Activity_CPE_Topic_API_Name")) {
                CPETypeOptions.push({value: picklistOption.value, label: picklistOption.label });
            } else if (picklistOption.picklistName == ($A.get("$Label.c.Activity_Tap_Topic_API_Name"))) {
                tapTopicOptions.push({value: picklistOption.value, label: picklistOption.label });
            } 
        }

        component.set("v.callTypeOptions", callTypeOptions);
        component.set("v.typeOptions", typeOptions);
        component.set("v.outcomeOptions", outcomeOptions);
        component.set("v.appointmentTypeOptions", appointmentTypeOptions);
        component.set("v.onsiteOrVirtualOptions", onsiteOrVirtualOptions);
    	component.set("v.CPETypeOptions", CPETypeOptions); 
        component.set("v.tapTopicOptions", tapTopicOptions);
    },

    performSaveEvent: function(component, helper, evnt, attendees) {
        if(evnt.ActivityDateTime == null){
            component.set("v.errors", [{message:"You must complete all required fields"}]);
        }
        /*else if((evnt.Outcome__c != null && Boolean(evnt.Outcome__c.trim()) && evnt.Onsite_or_Virtual__c === 'Onsite' && 
				(evnt.Meeting_Attendees__c == null || !(Boolean(evnt.Meeting_Attendees__c.trim())) || !evnt.Meeting_Attendees__c.includes(' ')))){
            component.set("v.errors", [{message:"Before saving your changes, you must enter the names of ALL meeting attendees in the Meeting Attendees field. This information will be audited. Make sure to include first and last names and to separate each attendee with a comma."}]);
        	helper.toggleSpinner(component, false);
            component.set("v.recordLoaded", true);
        }*/else{
            evnt = helper.clearWhoWhatFields(component, evnt);
            evnt.ActivityDate = evnt.ActivityDateTime.substring(0, 10);
            evnt.CAR__c = component.get("v.carId");
            component.set("v.evntStatus",' ');
            var action = component.get("c.saveEvent");
            action.setParams({
                "evnt": JSON.stringify(evnt),
                "attendees": JSON.stringify(attendees)
            });

            action.setCallback(this, function(response){
                var state = response.getState();
                
                if (state === "SUCCESS") {
                    helper.setNewEvent(component, helper);
                    if(component.get("v.profileName") === 'Sales Engineer'){
                        component.set("v.shouldCloseModal", true);
                    }
                    component.set("v.popupVisible", true);
                    var carID = component.get('v.carId');
                    console.log('THIS IS THE CARID: '+carID);
                    console.log('type of CARID: '+typeof(carID));
                    if(carID===''){
                       $A.get('e.force:refreshView').fire(); 
                       //location.reload();
                        console.log('the test conditional worked for carID');
                    }

                } else {
                    let errors = response.getError();
                    let message = 'There was an error creating the Event! \n'; // Default error message
                    // Retrieve the error message sent by the server
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        for (var i = 0; i < errors.length; i++) { 
                            message = message +' \nError '+ (i+1) + ': ' + errors[i].message;
                        }
                    }
					console.error(message);
                    
                    var displayedError = message;
                    /*var err = response.getError()[0];
                    var errorLocation = null;
                    if(!!err.fieldErrors[0]){
                        errorLocation = err.fieldErrors[0];

                    }else if(!!err.pageErrors[0]){
                        errorLocation = err.pageErrors[0];
                    }

                    if(!!errorLocation){
                        var statusCode = errorLocation.statusCode;
                        if(statusCode.toUpperCase().includes('VALIDATION')){
                            displayedError = errorLocation.message
                        }
                    }*/

                    component.set("v.evntStatus",displayedError);
                    component.set("v.recordLoaded", true);
                }
                helper.toggleSpinner(component, false);
            });
            $A.enqueueAction(action);
        }
    }, 
    
    clearWhoWhatFields: function(component, evnt){
        var sobjectType = component.get('v.sobjecttype');
        // if(sobjectType == 'Contact' || sobjectType == 'Lead'){
        //     evnt.WhatId = '';
        // }else{
        //     evnt.WhoId = '';
        // }
        return evnt;
    },

    picklistOptionsContainsValue : function(picklistOptions, value){
        for(var i = 0; i < picklistOptions.length; i++){
            if(picklistOptions[i].value === value){
                return true;
            }
        }
        return false;
    },


    toggleSpinner: function(component, trueOrFalse) {
        var spinner = component.find("spinner");
        var evt = spinner.get("e.toggle");

        evt.setParams({ isVisible : trueOrFalse });
        evt.fire();
    }, 
        
    setReminderDate : function(component)
    {
        var action = component.get("c.getEventReminderDate");
        action.setParams({"evt": component.get("v.newEvent")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS")
            {
                var updatedEvent = response.getReturnValue();
                component.set("v.newEvent.ReminderDateTime", updatedEvent.ReminderDateTime);
            }
        });
        $A.enqueueAction(action);
    },
})