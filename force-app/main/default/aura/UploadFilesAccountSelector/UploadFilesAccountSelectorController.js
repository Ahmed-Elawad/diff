({
    checkAllowSubmission : function(component, event, helper) {
        helper.checkSubmissionPrivileges(component, event, helper);
        helper.getPEOchecklistDetails(component, event, helper);
    },
    
    submitDocuments : function(component, event, helper) {
        component.set('v.finishButtonClicked',true);
        helper.submitAllDocuments(component, event, helper);
    },
    
    checkFilesNeeded : function(component, event, helper) {
        helper.getChecklistAndMedicalQuestionnaire(component, event);
    },
    
    checkSubmissionStatus : function(component, event, helper) {
        helper.getSubmissionStatus(component, event, helper);
    },
})