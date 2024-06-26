({
    handleLoad : function(component, event, helper) {
        component.set('v.loading', true);
        $A.util.addClass(component.find("spinner"), "slds-hide");
    },
    handleOnError : function(component, event, helper) {
        component.set('v.loading', false);
    },
    handleSave : function(component, event, helper){
        component.set('v.loading', true);   
    },
    handleSubmit : function(component, event, helper) {    
        helper.showSpinner(component);
        event.preventDefault();
        var fields = event.getParam('fields');
        //var eventFields = event.getParam("fields");
        var action = component.get("c.createCase");
        action.setParams({ FARF : fields });
        
        action.setCallback(this, function(response) {
            var CaseId = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                event.preventDefault();
                var eventFields1 = event.getParam("fields");
                eventFields1["Case__c"] = CaseId;
                component.find("faRequestForm").submit(eventFields1);
                var utilityAPI = component.find("utilitybar");
                utilityAPI.minimizeUtility();
            }
            helper.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },
    handleSuccess : function(component, event, helper) {
        component.set('v.loading', false);
        let record = event.getParams();
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type" : 'success',
            "message": "The record has been created successfully."
        });
        toastEvent.fire();
        $A.get("e.force:navigateToSObject").setParams({
            "recordId": record.response.id,
            "slideDevName": "details"
        }).fire();
    },
    handleCancel : function(component, event, helper) {
        var utilityAPI = component.find("utilitybar");
        utilityAPI.minimizeUtility();
    },
    onChangeAdvisorType : function(component, event, helper) {
        //alert(component.find("advisorType").get("v.value"));
        if(component.find("advisorType").get("v.value") == 'Financial Advisor'){
            component.set("v.BrokerDealer", false);
            component.set("v.FinancialAdvisor", true);
        }
        else if(component.find("advisorType").get("v.value") == 'Broker Dealer'){
            component.set("v.FinancialAdvisor", false);
            component.set("v.BrokerDealer", true);
            component.set("v.BrokerDealerBranch", false);
        }
        else if(component.find("advisorType").get("v.value") == 'Broker Dealer Branch'){
            component.set("v.FinancialAdvisor", false);
            component.set("v.BrokerDealerBranch", true);
            component.set("v.BrokerDealer", false);
        }
        else{
            component.set("v.FinancialAdvisor", false);
            component.set("v.BrokerDealer", false);
        }
        
    },
})