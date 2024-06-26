({ 
	calcPercentOwnership : function(component, event, accArrIndex) {
        
        var accWithPEOOnbChecklistOwners = component.get("v.accWithPEOOnbChecklistOwners");
        var percentageTotal = 0;
        if(accWithPEOOnbChecklistOwners != null && accWithPEOOnbChecklistOwners != 'undefined' 
           && accWithPEOOnbChecklistOwners[accArrIndex].ownerRec.length > 0)
        {
            let ownerRecArr = accWithPEOOnbChecklistOwners[accArrIndex].ownerRec;
            for(var index= 0;  index < ownerRecArr.length; index++)
            {
                if(ownerRecArr[index].percentOfOwner != null && ownerRecArr[index].percentOfOwner != '' && ownerRecArr[index].percentOfOwner != 'undefined')
                {
                    percentageTotal += parseInt(ownerRecArr[index].percentOfOwner);
                    console.log(percentageTotal);
                }
            }
            accWithPEOOnbChecklistOwners[accArrIndex].totalOwnershipPercent = percentageTotal;
        }
        component.set("v.accWithPEOOnbChecklistOwners", accWithPEOOnbChecklistOwners);
        
        if(component.get("v.answersChanged") == false)
        {
            component.set("v.answersChanged", true);
            console.log("setting  answersChanged to true");
        }
	},
    
    saveFormProgress : function(component, event) {
        
        try {
            console.log('component.get("v.answersChanged") = ' + component.get("v.answersChanged"));
            if(component.get("v.answersChanged") == true)
            {
                let activeAccId = component.get("v.activeAccId");
                let accIdWithIndex = component.get("v.accIdWithIndex");
                let accIndex = accIdWithIndex[activeAccId]; 
                let accWithPEOOnbChecklistOwners = component.get("v.accWithPEOOnbChecklistOwners");
               
                if(accWithPEOOnbChecklistOwners[accIndex].totalOwnershipPercent != 100){
                    this.displayMsg('Error saving record', 'Record not saved. Ownership Percentages must add up to 100%.', 'error');
                	return;
                }
                
                let accId = accWithPEOOnbChecklistOwners[accIndex].accId;
                let reqOwnershipArr = accWithPEOOnbChecklistOwners[accIndex].ownerRec;
                let ownershipData = '';
                
                for(let index = 0; index < reqOwnershipArr.length; index++){
                    ownershipData += reqOwnershipArr[index].nameOfOwner + ',' + reqOwnershipArr[index].percentOfOwner;
                     if(index != reqOwnershipArr.length-1){
                            ownershipData += ';';
                     }
                }
                
                let reqPEOChecklist;
                if(accIndex == 0){
                    component.set("v.PEOChecklist.List_of_Owners__c",ownershipData);
                    reqPEOChecklist = component.get("v.PEOChecklist");   
                }else{
                    let allAccIdWithPEOChecklist = component.get('v.allAccIdWithPEOChecklist');
                    reqPEOChecklist = allAccIdWithPEOChecklist[accId];
                    reqPEOChecklist.List_of_Owners__c = ownershipData;
                }
                var saveChecklist = component.get("c.savePeoOnboardingChecklist");
                saveChecklist.setParams({
                    "peoOnbChecklist":reqPEOChecklist
                });
                saveChecklist.setCallback(this, function(data) {
                    var state = data.getState();
            		if (state === "SUCCESS") {
                		component.set("v.answersChanged", false);
                        this.displayMsg('Success saving', 'Your progress has been saved', 'success', null);
            		}
                    else
                    {
                        this.displayMsg('Error saving record', 'Record not saved. Please refresh the page and try again.\nIf the error persists reach out to your admin', 'error');
                    }
                });
                $A.enqueueAction(saveChecklist);
            }
        }
        catch(err) {
            this.displayMsg('Error saving record', 'Record not saved. Please refresh the page and try again.\nIf the error persists reach out to your admin', 'error');
        }
        
    },
    
    displayMsg: function(title, msg, type, duration) {    
		var toastEvent = $A.get("e.force:showToast");
    	toastEvent.setParams({
        	title: title,
            message: msg,
			type: type
    	});
    	toastEvent.fire();
	}, // displays a toast message for the user
     triggerEvt: function(cmp, e) {
        try {
            let cmpEvent = cmp.getEvent("discrepancyEvt");
            cmpEvent.setParams({
                formName: cmp.get('v.formName'),
                checklistId: cmp.get('v.PEOChecklist').Id,
                type: 'PEO Information Sheet'
            });
			console.log('here');
            cmpEvent.fire(); 
        } catch(e) {
            console.log('Err in evt fire')
            console.log(e);
        }
    }
    /*
    
    saveProgress : function(component, event) {
        if(component.get("v.answersChanged") == true)
        {
            component.find("PEOInformationSheet").submit();
        	alert("Your progress has been saved!");
        }
	},
    /*
    decreaseStep : function(component, event) {
        if(component.get("v.answersChanged") == true)
        {
            component.find("PEOInformationSheet").submit();
        }
        
        var step = component.get("v.childStep");
        step = step - 1;
        component.set("v.childStep", step);
        console.log("v.childStep = "+step);
    },
    */
})