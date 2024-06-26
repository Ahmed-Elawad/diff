({
    checkSubmissionStatus : function(component, event, helper) {
        helper.getPEOchecklistDetails(component, event, helper);
        helper.getSubmissionStatus(component, event, helper);
        
    },
    
	submitDocuments : function(component, event, helper) {
        //component.set('v.finishButtonClicked',true);
        let fields = component.find('Platform');
        helper.validateFields(component, event, fields)
        .then(function(res) {
            helper.submitAllDocuments(component, event, helper)
            helper.switchLoadState(component, event, helper)
        })
        .catch(function(err) {
            helper.showUserMsg(component, err)
        });
    },
    
    
})