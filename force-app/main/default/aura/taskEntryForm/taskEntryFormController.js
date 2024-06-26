({
    doInit : function(component, event, helper) {
        helper.setPicklistValues(component, helper);
        helper.setNewTask(component, helper);

    },

    handleActivityTypeChange : function(component, event, helper) {
        component.set("v.activityType", event.getParam("activityType"));
        component.set("v.sourceRecordId", event.getParam("sourceRecordId"));
        if(component.get("v.activityType") == 'Follow Up Call' && component.get("v.newTask.Status") != 'Not Started')
        {
            helper.setNewTask(component, helper);
        }
        if(event.getParam("sourceObjectName") == 'Task'){
            helper.setNewTask(component, helper);
            
        }
    }, 
    
    handleDateValueChange: function(component, event, helper) {
        component.set("v.newTask.ActivityDate", component.get("v.activityDate"));
        var reminderSet = component.get("v.newTask.IsReminderSet");
        if(reminderSet){
            helper.setReminderDate(component);
        }
        else{
            component.set("v.newTask.ReminderDateTime", null);
        } 
    },

    clickSaveTask: function(component, event, helper) {     

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
            var newTask = component.get("v.newTask");
            helper.performSaveTask(component, helper, newTask);

        }
    },
})