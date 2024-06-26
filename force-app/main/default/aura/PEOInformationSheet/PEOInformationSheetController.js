({
    doinit: function(component, event, helper){
        let allAccs = component.get("v.allAccounts");
        let ownerDetails = {"nameOfOwner":"", "percentOfOwner":""};
        let existingPEOChecklistData = [];
        let existingPEOChecklistsAccIds = [];
        let allAccIdWithPEOChecklist = {}; 
        let allAccsChecklist = [];
        allAccsChecklist.push(Object.assign({},component.get('v.PEOChecklist')));
        allAccsChecklist.push(...component.get("v.childAccsChecklist"));
        if (component.get('v.user')) {
           let user = component.get('v.user');
            let prfName = user.Profile.Name;
            let isAnalyst = prfName == 'HRS Regional Sales Admin SB';
            let isNsc = prfName == 'HRS PEO Centric Sales - SB';
            let isDSM = prfName == 'HRS Sales Manager - SB';
            let isAdmin = prfName == 'System Administrator' || prfName == 'System Administrator - TAF';
            if (isAnalyst || isNsc || isDSM || isAdmin) {
               component.set('v.allowDiscLog', true);
           }
        }
        if(allAccsChecklist != null && allAccsChecklist.length > 0){
            for(let idx = 0; idx < allAccsChecklist.length; idx++){
                
                allAccIdWithPEOChecklist[allAccsChecklist[idx].Prospect_Client__c] = allAccsChecklist[idx];
                
                if(allAccsChecklist[idx].List_of_Owners__c != null && allAccsChecklist[idx].List_of_Owners__c != ''
                  && allAccsChecklist[idx].List_of_Owners__c != 'undefined'){
                  
                  let accObj = {accId : allAccsChecklist[idx].Prospect_Client__c.toString(),
                                 name:  ""};
                    
                  if(allAccsChecklist[idx].hasOwnProperty('Prospect_Client__r') &&
                     allAccsChecklist[idx].Prospect_Client__r.hasOwnProperty('Name')){
                      accObj.name = allAccsChecklist[idx].Prospect_Client__r.Name;
                  }
                    
                  existingPEOChecklistsAccIds.push(allAccsChecklist[idx].Prospect_Client__c);
                  
                  let ownerRec = [];
                  let existingOwnershipData = allAccsChecklist[idx].List_of_Owners__c;
                  let ownersDataAndPercentArr = existingOwnershipData.split(';');
                  let percentageTotal = 0;
                  for(let cnt = 0; cnt < ownersDataAndPercentArr.length; cnt++){
                  	let ownerNameAndPercentArr = ownersDataAndPercentArr[cnt].split(',');
                   	let ownerObj = Object.assign({},ownerDetails);
                  	ownerObj.nameOfOwner = ownerNameAndPercentArr[0];
                    if(ownerNameAndPercentArr[1] != null && ownerNameAndPercentArr[1] != ''
                       && ownerNameAndPercentArr[1] != 'undefined'){
                     	ownerObj.percentOfOwner = parseInt(ownerNameAndPercentArr[1]);
                        percentageTotal += parseInt(ownerNameAndPercentArr[1]);
                     }
                     ownerRec.push(ownerObj);
                  }
                  accObj.totalOwnershipPercent = percentageTotal;
                  accObj.ownerRec = [...ownerRec];
                  existingPEOChecklistData.push(Object.assign({},accObj));
                }
            }
        }
          
        component.set("v.allAccIdWithPEOChecklist",allAccIdWithPEOChecklist);
        component.set("v.activeAccId", allAccs[0].Id);
        
        let accWithPEOOnbChecklistOwners = [];
        let accIdWithIndex = {};
        
        for(let index = 0; index < allAccs.length; index++){
            let accountId = allAccs[index].Id;
            accIdWithIndex[accountId] = index;
            
            if(existingPEOChecklistsAccIds.includes(accountId)){
                let reqIndex = existingPEOChecklistsAccIds.indexOf(accountId);
                let reqAccData = Object.assign({},existingPEOChecklistData[reqIndex]);
                if(allAccs[0].Id == reqAccData.accId){
                    reqAccData.name = allAccs[0].Name.toString()
                }
                accWithPEOOnbChecklistOwners.push(reqAccData);
            }else{
                let accWithOwnerRecs = {accId:allAccs[index].Id.toString(),
                                        name: allAccs[index].Name.toString(),
                                        totalOwnershipPercent: 0
                                       };
            	accWithOwnerRecs.ownerRec = [];
                accWithOwnerRecs.ownerRec.push(Object.assign({},ownerDetails));
                accWithPEOOnbChecklistOwners.push(accWithOwnerRecs);
            }
        }
       
        component.set("v.accWithPEOOnbChecklistOwners",accWithPEOOnbChecklistOwners);
        component.set("v.accIdWithIndex",accIdWithIndex);
    },
    
    handleSelect : function(component, event, helper){
        component.set('v.activeAccId', event.getParam('id'));
    },
    
     handleChange : function(component, event, helper) {
        if(component.get("v.answersChanged") == false)
        {
            component.set("v.answersChanged", true);
            console.log("setting  answersChanged to true");
        }
    },
    
    handleOwnerChange : function(component, event, helper) {
        	let indexWithOwnerRecIndex = event.getSource().get('v.name');
            let indexArr = indexWithOwnerRecIndex.split('-');
            let accWithPEOOnbChecklistOwners = component.get("v.accWithPEOOnbChecklistOwners");
        	let userInput = event.getSource().get('v.value');
   			accWithPEOOnbChecklistOwners[indexArr[0]].ownerRec[indexArr[1]].nameOfOwner = userInput;
        	component.set("v.accWithPEOOnbChecklistOwners",accWithPEOOnbChecklistOwners);
        	if(component.get("v.answersChanged") == false)
        	{
                component.set("v.answersChanged", true);
                console.log("setting  answersChanged to true");
        	}
     },
    
    saveProgress : function(component, event, helper) {
        helper.saveFormProgress(component, event);
    },
    
    addNewOwner : function(component, event, helper) {
        let index = event.getSource().get('v.value');
        let accWithPEOOnbChecklistOwners = component.get("v.accWithPEOOnbChecklistOwners");
        let ownerDetails = {nameOfOwner:"", percentOfOwner:""};
        accWithPEOOnbChecklistOwners[index].ownerRec.push(Object.assign({},ownerDetails));
        component.set("v.accWithPEOOnbChecklistOwners", accWithPEOOnbChecklistOwners);
        if(component.get("v.answersChanged") == false)
        {
         	component.set("v.answersChanged", true);
            console.log("setting  answersChanged to true");
        }
    },
    
    removeRow : function(component, event, helper) {
        let arrIndex = parseInt(event.target.name);
        let ownerRecIndex = parseInt(event.target.accessKey);
        let accWithPEOOnbChecklistOwners = component.get("v.accWithPEOOnbChecklistOwners");
        let ownerRecs = accWithPEOOnbChecklistOwners[arrIndex].ownerRec;
        ownerRecs.splice(ownerRecIndex, 1);
        accWithPEOOnbChecklistOwners[arrIndex].ownerRec = ownerRecs;
        component.set("v.accWithPEOOnbChecklistOwners", accWithPEOOnbChecklistOwners);
        helper.calcPercentOwnership(component, event, arrIndex)
    },
    
    calculatePercentOwnership : function(component, event, helper) {
        let indexWithOwnerRecIndex = event.getSource().get('v.name');
        let indexArr = indexWithOwnerRecIndex.split('-');
        let accWithPEOOnbChecklistOwners = component.get("v.accWithPEOOnbChecklistOwners");
        accWithPEOOnbChecklistOwners[indexArr[0]].ownerRec[indexArr[1]].percentOfOwner = event.getSource().get('v.value');
        component.set("v.accWithPEOOnbChecklistOwners",accWithPEOOnbChecklistOwners);
        helper.calcPercentOwnership(component, event, indexArr[0]);
        
    },
    openTab: function(cmp, e, helper) {
        console.log('in controller')
        helper.triggerEvt(cmp, e);
    },
    
    /*
	saveAndNext : function(component, event, helper) {
        /*helper.validateFields(component, event);
		helper.saveAndNext(component, event);
	},
    
    submitSuccessful : function(component, event, helper) {
		console.log("Submit Successful!");
	},
    
    saveProgress : function(component, event, helper) {
        if(component.get("v.answersChanged") == true)
        {
            helper.saveProgress(component, event);
        	alert("Your progress has been saved!");
        }        
	},
    /*
    stepBackward : function(component, event, helper) {
        helper.decreaseStep(component, event);
    },
    
    handleAnswersChanged : function(component, event, helper) {
        if(component.get("v.answersChanged") == false)
        {
            component.set("v.answersChanged", true);
        }
		
	},
    
    
    handleChange : function(component, event, helper) {
		component.set("v.answersChanged", true);
        console.log("setting  answersChanged to true");
	},
    
    saveForm : function(component, event, helper) {
        console.log("saving Form...");
        console.log('component.get("v.answersChanged") = '+component.get("v.answersChanged"));
        if(component.get("v.answersChanged") == true)
        {
            component.find("PEOInformationSheet").submit();
            component.set("v.answersChanged", false);
        }
	},
    */
})