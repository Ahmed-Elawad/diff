({
    doInit : function(component, event, helper) {
        helper.setUpComponent(component, helper);
    },
    processCancelRequest : function(component, event, helper) {
        component.set("v.addException", 'false');
    },
    removeExcep : function(component, event, helper) {
        helper.removeExceptionHelper(component, helper);
        
    },
        showExceptionScreen : function(component, event) {
        component.set("v.showContact", false);
    },
    updateException : function(component, event, helper) {
        var exceptionReason = event.getParam("value");
        if(exceptionReason == 'Other'){
            var isTrue = component.get("v.boolTrue");
            component.set("v.exceptionDetailRequired", isTrue);
        }else{
            var isFalse = component.get("v.boolFalse");
            component.set("v.exceptionDetailRequired", isFalse);
        }
    },
    handleExceptionCancel : function(component, event, helper) {
        component.set("v.addException", component.get("v.boolFalse"));
    },
    displayExceptionScreen : function(component, event, helper) {
        component.set("v.addException", 'true');
    },
    callEZOnboarding : function(component, event, helper) {
        component.set("v.showEZ", 'true');
    },
    callSetupNewClient : function(component, event, helper) {
        var recId = component.get("v.recordId");
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:EnterpriseReg",
            componentAttributes: {
                opptyId : component.get("v.recordId")
            }
        });
        evt.fire();
       /*
        $A.get("e.force:navigateToURL").setParams({ 
            "url": "/lightning/n/OpenEntRegForm" 
       }).fire();
       */
    },
    changePrimaryQuote : function(component, event, helper) {
        helper.changePrimaryQuote(component, event, helper);
    },
    closeModal : function(component, event, helper) {
        helper.setUpComponent(component, helper);
        component.set("v.showEZ", 'false');
    },
    handleSubmit : function(component, event, helper) {
        component.set("v.addException", component.get("v.boolFalse"));
        var showToast = $A.get("e.force:showToast"); 
        showToast.setParams({ 
            'title' : 'Confirmation', 
            'type' : 'success',
            'message' : 'The CSO exception has been recorded.'
        }); 
        showToast.fire();
        //helper.setUpComponent(component, helper);
        window.location.reload();
        //$A.get('e.force:refreshView').fire();
    },
    handleValidationSubmit : function(component, event, helper) {
        var showToast = $A.get("e.force:showToast"); 
        showToast.setParams({ 
            'title' : 'Confirmation', 
            'type' : 'success',
            'message' : 'This client has been re-evaluated'
        }); 
        showToast.fire();
        $A.get('e.force:refreshView').fire();
        helper.setUpComponent(component, helper);
    },
    booleanChanged : function(component, event, helper) {
        var bool = event.getSource().get("v.name");
        var boolVal = event.getSource().get("v.value");
        if(bool=='accEli'){
            component.set("v.accountEligible", boolVal);
        }
        if(bool=='userEli'){
            component.set("v.userEligible", boolVal);
        }
    },
    checkProgress : function(component, event, helper) {
        console.log('checkProgress');
            component.set("v.showProgress", true);
        component.set("v.showEZ", 'false');
        component.set("v.showEZButton", 'false');
        
    },
    changePrimaryQuote : function(component, event, helper) {
        helper.changePrimaryQuote(component, event, helper);
    },
    resendUserRegistration : function(component, event, helper) {
        helper.handleResendUserReg(component, event, helper);
    },
    navigateToQuote : function(component, event, helper) {
        var opp = component.get("v.csoOpportunity");
        var quoteId = opp.Primary_Oracle_Quote__c;
        var quoteUrl = '/apex/cafsl__EmbeddedTransaction?mode=edit&quoteId='+quoteId;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({"url": quoteUrl});
        urlEvent.fire();
    }
})