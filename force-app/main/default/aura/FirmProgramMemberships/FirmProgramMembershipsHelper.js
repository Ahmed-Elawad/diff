({
	fethMemberShips : function(component, event) {
		var action = component.get("c.fetchMemberInfo");
        
        //action.setParams({});
        console.log('calling...');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('respons===>'+JSON.stringify(response.getReturnValue()));
                let memO = response.getReturnValue();
                component.set("v.isAdminCPA",memO.isAdminCPA);
                component.set("v.memInfo",memO.memsInfo);// Alert the user with the value returned
                component.set("v.memOutInfo",memO);
                component.set("v.memInfoSize",memO.memsInfo.length);

 
                
            }else if (state === "INCOMPLETE") {
                // do something
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        
        $A.enqueueAction(action);
	},
    updateMemberShips : function(component, event) {
		component.set("v.isLoading",true);
        var action = component.get("c.updateMemberShips");
        //let filterRecs = component.get("v.memInfo").filter(item => item.isChanged == true);
        let filterRecs = component.get("v.memInfo");
		let mJSON = JSON.stringify(filterRecs);
        console.log('TEMP JSON TO LOOK FOR: '+mJSON);
        action.setParams({memIJSON : mJSON});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.isLoading",false);
            if(state === "SUCCESS"){
                let resp = response.getReturnValue();
                if(resp === 'SUCCESS'){
					var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type":"success",
                        "message": "Success! Your changes have been saved."
                    });
                    toastEvent.fire();                    
                }
            }else if (state === "INCOMPLETE") {
                // do something
            }else if (state === "ERROR") {
                var errors = response.getError();
                let error_Msg='';
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        console.log("Error message: " + 
                                 errors[0].message);
                        error_Msg = errors[0].message;
                    }
                } else {
                    console.log("Unknown error");
                    error_Msg = 'Unknown error'
                }
				var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                	"title": "Error!",
                    "type":"error",
                    "message": "Unable to save your changes. Eror:"+error_Msg
                });
                toastEvent.fire(); 
            }
        });
        
        
        $A.enqueueAction(action);
	},
    removeFromFirm : function(component, event,recordJSON) {
        component.set("v.isLoading",true);
        var action = component.get("c.createCPAFirmMemRequests");
        let filterRecs = component.get("v.memInfo").filter(item => item.isChanged == true);
        
		action.setParams({mprJSON : recordJSON});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.isLoading",false);
            if(state === "SUCCESS"){
                let resp = response.getReturnValue();
                if(resp === 'SUCCESS'){
					var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type":"success",
                        "message": "Success! Your changes have been saved."
                    });
                    toastEvent.fire();                    
                }
            }else if (state === "INCOMPLETE") {
                // do something
            }else if (state === "ERROR") {
                var errors = response.getError();
                let error_Msg='';
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        console.log("Error message: " + 
                                 errors[0].message);
                        error_Msg = errors[0].message;
                    }
                } else {
                    console.log("Unknown error");
                    error_Msg = 'Unknown error'
                }
				var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                	"title": "Error!",
                    "type":"error",
                    "message": "Unable to save your changes. Eror:"+error_Msg
                });
                toastEvent.fire(); 
            }
        });
        
        
        $A.enqueueAction(action);
    },
    firmOptOut : function(component, event) {
        let memO = component.get("v.memOutInfo");
        let reqRec={
            Name:memO.firstName+' '+memO.lastName,
            Referral_Account__c:memO.refConAccountId,
            Referral_Contact__c:memO.refConId,
           //Request_type__c:'Opt out from platform',
           Event__c : 'Opt out from platform',
           //Opt_Out_Reason__c:component.get("v.OptOutReason"),
           Reason__c : component.get("v.OptOutReason"),
           //Unenroll_Reason__c:''
        }
        
        var action = component.get("c.createOptOutMemRequests");
        
		action.setParams({mprJSON : JSON.stringify(reqRec)});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.isMOLoading",false);
            if(state === "SUCCESS"){
                let resp = response.getReturnValue();
                if(resp === 'SUCCESS'){
                    component.set("v.isModalOpen", false);
                    
					var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type":"success",
                        "message": "Success! Your changes have been saved."
                    });
                    toastEvent.fire();                    
                }
            }else if (state === "INCOMPLETE") {
                // do something
            }else if (state === "ERROR") {
                var errors = response.getError();
                let error_Msg='';
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        console.log("Error message: " + 
                                 errors[0].message);
                        error_Msg = errors[0].message;
                    }
                } else {
                    console.log("Unknown error");
                    error_Msg = 'Unknown error'
                }
				var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                	"title": "Error!",
                    "type":"error",
                    "message": "Unable to save your changes. Eror:"+error_Msg
                });
                toastEvent.fire(); 
            }
        });
        
        
        $A.enqueueAction(action);
    }
})