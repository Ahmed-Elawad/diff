({
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
    initialize : function(component, event, helper) {
        var tracker = component.get("v.tracker");
        var parentTracker = component.get("v.parentTracker");
        var productList = component.get("v.productList");
        var isParent = tracker.Id == parentTracker.Id ? true :false;
        component.set("v.isParent", isParent);
        if(productList!=null){
            productList.forEach((product)=>{
                if(product.toUpperCase().includes("ESR")){
                component.set("v.hasESR", true);
            	}
                else if(product.toUpperCase().includes("FLEX TIME")){
                	component.set("v.hasFlexTime", true);
            	}
            	else if(product.toUpperCase().includes("FLOCK")){
                	component.set("v.hasBenAdmin", true);
            	}
        	});
   		}
	},
	validateSST : function(component, event, helper, closeForm) {
        component.set("v.onboardingLoaded", true);
        component.set("v.loadSpinner", true);
        //Validate Form
        event.preventDefault();
        var fields = event.getParam('fields');
        var ignoreRelationshipManager = component.get("v.ignoreRelationManager");
        component.find('SSTForm').submit(fields);
        var formFields = component.find("sstFormField");
        var sstValid = true;
                
        formFields.forEach(function (field) {
            if(field.get("v.fieldName") != null){
                var currentFieldName = field.get("v.fieldName");
                if(currentFieldName != "RelationshipManager__c" || !ignoreRelationshipManager){
                    if($A.util.isEmpty(field.get("v.value"))){
                        //alert(field.get("v.fieldName"));
                        sstValid = false;
                    }
                }
            }
        });
        component.set("v.sstValid", sstValid);
        component.find('TrackerForm').submit();
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
    },
	closeSST : function(component, event, helper) {
        helper.closeFocusedTab(component, event, helper);
    },
    updateDisplay : function(component, event, helper) {
        component.set("v.displayUpdateScreen", false);
        component.set("v.displayAuthOfficerScreen", false);
        component.set("v.displayPayrollContactScreen", false);
    },
    reValidateForm : function(component){
        var cmpEvent = component.getEvent("validateEnterpriseForm");
        cmpEvent.fire();
    },
})