({
    
    setNewTask : function(component, helper) {

        component.set("v.recordLoaded","false");
        helper.toggleSpinner(component,true);

        var action = component.get("c.getNewTask");
        var test = component.get("v.activityType");
        console.log("THIS IS THE ACTIVITY TYPE SET: "+JSON.stringify(test));
                // console.log()
        action.setParams({
            "activityType": component.get("v.activityType"),
            "recordId": component.get("v.sourceRecordId"),
            "p_desc": component.get("v.descriptionAddOn"),
            "p_attendees": component.get("v.attendeesAddOn")
        });

        action.setCallback(this, function(response) {
            
            var state = response.getState();
            //if(response.getReturnValue())
            if (state === "SUCCESS") {
                var newTask = response.getReturnValue();
                newTask.CAR__c=component.get("v.carId");
                helper.addDefaultsToPicklistOptions(component, helper, newTask);
                if(component.get("v.isFollowUpActivity") || newTask.Status == 'Not Started'){
                    newTask.ActivityDate = null;
                }
                /*if(component.get("v.activityType") == 'Follow Up Call' && newTask.Status != 'Not Started')
                {newTask.Status = 'Not Started';
                newTask.Subject = 'Follow up - '+newTask.Subject}*/
                component.set("v.activityDate", newTask.ActivityDate);
                component.set("v.newTask", newTask);

            } else {
                console.log("SET NEW TASK Failed with state: " + state);
            }
            component.set("v.recordLoaded","true");
            helper.toggleSpinner(component,false);

        });

        $A.enqueueAction(action);
    },

    addDefaultsToPicklistOptions : function(component, helper, newTask){
        var statusOptions = component.get("v.statusOptions");
        //newTask.Status = "Not Started";
        if(!helper.picklistOptionsContainsValue(statusOptions, newTask.Status) && newTask.Status){
            statusOptions.unshift({value: newTask.Status, label: newTask.Status });
        }
        if(component.get("v.profileName") === 'Sales Engineer'){
            var appointmentTypeOptions = component.get("v.appointmentTypeOptions");
            if(!helper.picklistOptionsContainsValue(appointmentTypeOptions, newTask.Appointment_Type__c) && newTask.Appointment_Type__c){
                appointmentTypeOptions.unshift({value: newTask.Appointment_Type__c, label: newTask.Appointment_Type__c });
                component.set("v.appointmentTypeOptions", appointmentTypeOptions);
            }

            newTask.Outcome__c = "";
            newTask.Lead_Source_WAR_Call_Type__c = "";
            newTask.Type = "";

        }else{

            var callTypeOptions = component.get("v.callTypeOptions");
            if(!helper.picklistOptionsContainsValue(callTypeOptions, newTask.Lead_Source_WAR_Call_Type__c) && newTask.Lead_Source_WAR_Call_Type__c){
                callTypeOptions.unshift({value: newTask.Lead_Source_WAR_Call_Type__c, label: newTask.Lead_Source_WAR_Call_Type__c });
                component.set("v.callTypeOptions", callTypeOptions);
            }

            var typeOptions = component.get("v.typeOptions");
            if(!helper.picklistOptionsContainsValue(typeOptions, newTask.Type) && newTask.Type){
                typeOptions.unshift({value: newTask.Type, label: newTask.Type });
                component.set("v.typeOptions", typeOptions);
            }
        /*    
            var tapTopicOptions = component.get("v.tapTopicOptions");
            if(!helper.picklistOptionsContainsValue(tapTopicOptions, newTask.TAP_Topic__c) && newTask.TAP_Topic__c){
                tapTopicOptions.unshift({value: newTask.TAP_Topic__c, label: newTask.TAP_Topic__c });
                component.set("v.tapTopicOptions", tapTopicOptions);
            }
            
           */
            newTask.Appointment_Type__c = "";
            var refctct = component.get('v.refctctid');
            console.log("Referral Contact in Tast Entry Form"+JSON.stringify(refctct));

            //newTask.Description += refctct.Name;
        }
    },

    setPicklistValues: function(component, helper) {

        var action = component.get("c.getDataEnvelope");
        action.setParams({
            "sourceObjectName": "Task"
        });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                var envelope = response.getReturnValue();
                console.log(envelope);
                var options = envelope.options;
                var profileName = envelope.profileName;
                component.set("v.profileName", profileName);
                helper.setPicklistOptionAttributes(component, options);
            } else {
                console.log("SET PICKLIST VALUES Failed with state: " + state);
            }

        });

        $A.enqueueAction(action);

    }, 

    setPicklistOptionAttributes : function(component, picklistOptionWrappers){
        var statusOptions = [];
        var callTypeOptions = [];
        var typeOptions = [];
        var outcomeOptions = [];
        var priorityOptions = [];
        var appointmentTypeOptions = [];
        var tapTopicOptions = []; 

        for (var i=0; i<picklistOptionWrappers.length; i++) {

            var picklistOption = picklistOptionWrappers[i];
            console.log(picklistOption.picklistName); 

            if (picklistOption.picklistName == $A.get("$Label.c.Activity_Status_API_Name")) {
                statusOptions.push({value: picklistOption.value, label: picklistOption.label });
            } else if (picklistOption.picklistName == $A.get("$Label.c.Activity_Call_Type_API_Name")) {
                callTypeOptions.push({value: picklistOption.value, label: picklistOption.label });
            } else if (picklistOption.picklistName == $A.get("$Label.c.Activity_Type_API_Name")) {
                typeOptions.push({value: picklistOption.value, label: picklistOption.label });
            } else if (picklistOption.picklistName == $A.get("$Label.c.Activity_Outcome_API_Name")) {
                outcomeOptions.push({value: picklistOption.value, label: picklistOption.label });
            } else if (picklistOption.picklistName == 'Priority') {
                priorityOptions.push({value: picklistOption.value, label: picklistOption.label });
            } else if (picklistOption.picklistName == $A.get("$Label.c.Activity_Appointment_Type_API_Name")) {
                appointmentTypeOptions.push({value: picklistOption.value, label: picklistOption.label });
            } else if (picklistOption.picklistName == ($A.get("$Label.c.Activity_Tap_Topic_API_Name"))) {
                tapTopicOptions.push({value: picklistOption.value, label: picklistOption.label });                
            } 
            
        }

        component.set("v.priorityOptions",priorityOptions);
        component.set("v.outcomeOptions",outcomeOptions);
        component.set("v.statusOptions",statusOptions);
        component.set("v.callTypeOptions",callTypeOptions);
        component.set("v.typeOptions",typeOptions);
        component.set("v.appointmentTypeOptions",appointmentTypeOptions);
        component.set("v.tapTopicOptions", tapTopicOptions); 

    },

    performSaveTask: function(component, helper, tsk) {
        var carId = component.get("v.carId");
        console.log('THE CAR ID: '+carId);
        if(tsk.ActivityDate == null){
            component.set("v.errors", [{message:"You must complete all required fields"}]);
        }else{
            tsk = helper.clearWhoWhatFields(component, tsk);
            tsk.CAR__c = carId;
            var action = component.get("c.saveTask");
            action.setParams({
                "tsk": JSON.stringify(tsk)
            });

            action.setCallback(this, function(response){
                var state = response.getState();

                if (state === "SUCCESS") {
                    helper.setNewTask(component, helper);
                    if(component.get("v.profileName") === 'Sales Engineer'){
                        component.set("v.shouldCloseModal", true);
                    }
                    console.log(carId);                   
                    if(carId===''){
                        //location.reload();
                        $A.get('e.force:refreshView').fire(); 
                    }
                    component.set("v.popupVisible", true);
                    component.set("v.recordLoaded", false);

                    //  


                } else {
                    var displayedError = "There was an error creating the Task!";
                    var err = response.getError()[0];
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
                    }

                    component.set("v.tskStatus",displayedError);
                }
                helper.toggleSpinner(component, false);

            });

            $A.enqueueAction(action);
        }

    }, 

    clearWhoWhatFields: function(component, tsk){
        var sobjectType = component.get('v.sobjecttype');
        // if(sobjectType == 'Contact' || sobjectType == 'Lead'){
        //     tsk.WhatId = '';
        // }else{
        //     tsk.WhoId = '';
        // }
        return tsk;
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
        var action = component.get("c.getTaskReminderDate");
        action.setParams({"tsk": component.get("v.newTask")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS")
            {
                var updatedTask = response.getReturnValue();
                component.set("v.newTask.IsReminderSet", updatedTask.IsReminderSet);
                component.set("v.newTask.ReminderDateTime", updatedTask.ReminderDateTime);
            }
        });
        $A.enqueueAction(action);
    },
})