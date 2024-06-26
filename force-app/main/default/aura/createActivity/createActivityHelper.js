({
    initialPresentationCheck : function(component){
        var sourceObjectId = component.get("v.recordId");
        var action = component.get("c.initialPresentationCheck");
        var multInitPresentations = false;
        action.setParams({
            "recordId": sourceObjectId
        });
        action.setCallback(this, function(response){        
            var state = response.getState();
            if(state === 'SUCCESS'){
                multInitPresentations = response.getReturnValue();
            }  
            component.set("v.multipleInitPresentations", multInitPresentations);
            console.log('********INITITIAL PRESENTATION VALUE***********'+component.get("v.multipleInitPresentations")); 
        });
        $A.enqueueAction(action);   
    },
	setUpCreateActivity : function(component){
        var action = component.get("c.getProfileName");
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var profileName = response.getReturnValue();
                component.set("v.profileName", profileName);
                
                this.isPEOSalesUser(component);                
            }else{
                console.log('error retrieving profile name');
            }
        });
        
        $A.enqueueAction(action);
	},

    // SFDC-2592 (US2)
    isPEOSalesUser : function(component){
        var action = component.get("c.isPEOSalesUser");
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var isThisPEOSalesUser = response.getReturnValue();
                component.set("v.isThisPEOSalesUser", isThisPEOSalesUser);
                console.log('*** isPEOSalesUser(), isThisPEOSalesUser: ' + isThisPEOSalesUser);
                this.populatePicklistValues(component);
            }else{
                console.log('error retrieving isPEOSalesUser value');
            }
        });
        
        $A.enqueueAction(action);
    },

    // SFDC-3404 (US3)
    setPicklistNameGroupName : function(component){
        var groupName;
        var picklistName = 'Activity Type';
		if(component.get("v.isFollowUpActivity")){
        	picklistName = 'Follow Up Activity Type';
            groupName = 'Default';
        }        
        else {
            var sobjectType = component.get("v.sobjecttype");
            var profileName = component.get("v.profileName");
            if(profileName === 'Sales Engineer') {
                groupName = 'Sales Engineer';
            }
            else if(sobjectType === 'Opportunity') {
                groupName = 'Opportunity';
            }
            else if(sobjectType === 'Lead')	{
                groupName = 'Lead';
            }
            else if(sobjectType === 'Contact')	{
                groupName = 'Contact';
            }
            else if(sobjectType === 'Referral_Contact__c')	{
                groupName = 'Referral_Contact__c';
            }
            else if(sobjectType === 'Referral_Account__c')	{
                groupName = 'Referral_Account__c';
            }
            else	{
                groupName = 'Default';
            }
        }
        
        component.set("v.picklistName", picklistName);                
        component.set("v.groupName", groupName);                        
    },

    // SFDC-3404 (US3)
    populatePicklistValues : function(component){
        this.setPicklistNameGroupName(component);
        var picklistName = component.get("v.picklistName");
        var groupName = component.get("v.groupName");
        var isThisPEOSalesUser = component.get("v.isThisPEOSalesUser");
        var multipleInitialPresentations = component.get("v.multipleInitPresentations");
        
        console.log("createActivityHelper::populatePicklistValues, calling getPicklistValues() with params - picklistName: " 
                    + picklistName + ", groupName: " + groupName + ", isThisPEOSalesUser: " + isThisPEOSalesUser + ", multipleInitialPresentations: " + multipleInitialPresentations);
        var action = component.get("c.getPicklistValues");
        action.setParams({
            "picklistName": picklistName,
            "groupName": groupName,
            "isPEOUser": isThisPEOSalesUser,
            "isMultipleInitialPresentations": multipleInitialPresentations
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var picklistValues = response.getReturnValue();
                console.log("createActivityHelper::populatePicklistValues, picklistValues: " + picklistValues);
                
                var options = [];
                if(picklistValues != undefined && picklistValues.length != 0)	{
                    for(var i = 0; i < picklistValues.length; i++){
                        options.push({ 	
                            value: picklistValues[i],
                            label: picklistValues[i]
                        });			                    
                    }    
                }
                else {
                        options.push({ 	
                            value: "Error",
                            label: "ERROR: Unable to populate Activity Type picklist."
                        });			                    
                }
                
                component.set("v.activityTypeOptions", options);                
                if(component.get("v.isFollowUpActivity"))	{
                    component.find("selectActivityType").set("v.value", "Follow Up Call");
                    this.updateFormForActivityType(component, picklistName, groupName, "Follow Up Call");
                }
                else {
                    component.set("v.selectedActivityType", options[0].value);
                    this.updateFormForActivityType(component, picklistName, groupName, options[0].value);
                }
            }
            else if (status === "INCOMPLETE") {
                console.log("No response from server or client is offline.")
                // Show offline error
            }
            else if (status === "ERROR") {
                console.log("Error: " + errorMessage);
            }            
            else{
                console.log('createActivityHelper::populatePicklistValues, error retrieving Picklist values');
            }
        });
        
        $A.enqueueAction(action);
    },
    
	handleOptionSelected : function(component, event){
        // reset the value to original as in component
        component.set("v.isReadyToLoadEntryForm", false);
        
        this.setPicklistNameGroupName(component);
        var picklistName = component.get("v.picklistName");
        var groupName = component.get("v.groupName");
        
		var selectedOptionValue = event.getParam("value");
		this.updateFormForActivityType(component, picklistName, groupName, selectedOptionValue);
	},

	updateFormForActivityType : function(component, picklistName, groupName, selectedOptionValue){
        console.log("createActivityHelper::updateFormForActivityType, picklistName: " + picklistName + ", groupName: " + groupName + ", selectedOptionValue: " + selectedOptionValue);
        
        var action = component.get("c.isSelectedLabelValueEvent");
        action.setParams({
            "picklistName": picklistName,
            "groupName": groupName,
            "labelName": selectedOptionValue
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var isSelectedActivityTypeForEvent = response.getReturnValue();
                console.log("createActivityHelper::updateFormForActivityType, selectedOptionValue: " + selectedOptionValue + ", isSelectedActivityTypeForEvent: " + isSelectedActivityTypeForEvent);
                
                var sourceObjectName = "Task";
                if (isSelectedActivityTypeForEvent) {
                    sourceObjectName = "Event";
                } 
                
                console.log("createActivityHelper::updateFormForActivityType, activityType: " + selectedOptionValue + ", sourceObjectName: " + sourceObjectName + ", sourceRecordId: " + component.get("v.recordId"));
                
                component.set("v.selectedActivityType", selectedOptionValue);
                component.set("v.sourceObjectName", sourceObjectName);
                component.set("v.isReadyToLoadEntryForm", true);
                
               var activityTypeChangeEvent = $A.get("e.c:activityTypeChangedEvent");
                                
                activityTypeChangeEvent.setParams({
                    activityType: selectedOptionValue,
                    sourceObjectName: sourceObjectName,
                    sourceRecordId: component.get("v.recordId")
                });
                
                activityTypeChangeEvent.fire();
            }else{
                console.log('createActivityHelper::updateFormForActivityType, error retrieving isSelectedLabelValueEvent call.');
            }
        });
        
        $A.enqueueAction(action);
	}


})