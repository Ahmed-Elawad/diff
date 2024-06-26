({
    doInit : function(component, event, helper) {
        component.set('v.loading', true);
        helper.retrieveRT(component,helper);
    },
    handleLoad : function(component, event, helper) {
        component.set('v.loading', false);
    },
    handleOnError : function(component, event, helper) {
        component.set('v.loading', false);
    },
    checkMessages : function(component, event, helper) {
        component.set("v.newCaseType", component.find("caseType").get("v.value"));
        component.set("v.newCaseSubType", component.find("caseSubType").get("v.value"));
        helper.validateCase(component);
    },
    handleSubmit : function(component, event, helper) {
        component.set('v.loading', true);
        var currentURL = decodeURIComponent(window.location);
        var descript =  '\n\n Page the user was on when submitting the case: \n' + currentURL; // modify a field
        var eventFields = event.getParam("fields");
        eventFields["Description"] += descript;
    },
    handleSuccess : function(component, event, helper) {
        /*component.find('field').forEach(function(f) {
            f.reset();
        });*/
        component.set('v.loading', false);
        var param = event.getParams();
        var recordId = param.response.id;
        

        component.set("v.newCaseRecordId", recordId);
        component.set("v.newCaseCreated", true);
        /*component.find("notifLib").showToast({
            "title": "Case Saved",
            "message": "Sales Help Case Saved Successfully "
        });*/
        //Create chatter message
    },
    minimizeUtility : function(component, event, helper) {
        var utilityAPI = component.find("utilitybar");
        utilityAPI.minimizeUtility();
        component.set("v.newCaseRecordId", null);
        component.set("v.newCaseCreated", false);
    },
    handleUploadFinished : function(component, event, helper) {
        component.set("v.filesAttached", true);
        var caseFiles =  component.get("v.attachedFiles");
        var uploadedFiles = event.getParam("files");
        uploadedFiles.forEach(file => caseFiles.push(file.name));
        component.set("v.attachedFiles", caseFiles);
    },
})