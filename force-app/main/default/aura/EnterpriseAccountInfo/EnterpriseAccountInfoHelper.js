({
    updateAddressDisplay : function(component, event, helper) {
        component.set("v.legalIsBill", false);  
        component.set("v.legalIsShip", false);  
        component.set("v.LegalIsParent", false);  
        component.set("v.billIsShip", false);  
        component.set("v.billIsParent", false);  
        component.set("v.shipIsBill", false);  
        component.set("v.ShipIsParent", false); 
        component.set("v.updateShip", false);        
        component.set("v.updateBill", false);
        component.set("v.updateAddress", false);
        component.set("v.updateLegal", false);
        component.set("v.loadSpinner", false);
    },
    closeFocusedTab : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    validateAcct : function(component, event, helper, closeForm) {
        component.set("v.acctLoaded", true);
        //Validate Form
        var acctValid  = true;
        var isMMSStandalone = component.get("v.isMMSStandalone");
        var dateTimeNow = new Date();
        component.set("v.loadSpinner", true);
        event.preventDefault();
        var fields = event.getParam('fields');
        var formFields = component.find("AcctFormField");
        formFields.forEach(function (field) {
            if(field.get("v.fieldName") != null){
                if($A.util.isEmpty(field.get("v.value"))){
                    //alert('field='+field.get("v.fieldName"));
                    acctValid = false;
                }
            }
        });
        //alert('setting acctValid='+acctValid);
        component.set("v.acctComplete", acctValid);
        //alert('after setting acctValid');
        //component.find('OnboardingForm').submit();  
        if(!isMMSStandalone){
            var revalidateDateTime = component.find("revalidationDate");
            revalidateDateTime.set("v.value", dateTimeNow.toISOString());
        }
        //alert('after isMMSStandalone check');
        component.find('TrackerForm').submit(); 
        //alert('after TrackerForm submit');
        component.find('AccountUpdateForm').submit(fields);   
        //alert('after AccountUpdateForm submit closeForm='+closeForm);
    	if(closeForm){
            var showToast = $A.get("e.force:showToast"); 
        	showToast.setParams({ 
            'title' : 'Confirmation', 
            'type' : 'success',
            'message' : 'The Sales Submission Team Form information has been saved'
        	}); 
        	showToast.fire();
            helper.closeFocusedTab(component, event, helper);
    	}
        //alert('end of validateAcct function');
    },
    closeAcct : function(component, event, helper) {
        helper.closeFocusedTab(component, event, helper);
    },
    reValidateForm : function(component){
        var cmpEvent = component.getEvent("validateEnterpriseForm");
        cmpEvent.fire();
    },
    selectTab : function(component, event, helper) { 
        component.find("tabs").set("v.selectedTabId",'Account');
    },
})