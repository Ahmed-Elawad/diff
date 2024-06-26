({
	createRequests : function(component, event) {
        let miRc = component.get("v.miRec");
        let reqRec = {
            //Name:'Test',
            Referral_Account__c:miRc.refConAccountId,
            Referral_Contact__c:miRc.refConId,
            Event__c:'Remove from Firm Account',
            Reason__c:miRc.unenrollReason
            //Opt_Out_Reason__c:''
        };
        //console.log('rec===>'+ JSON.stringify(JSON.parse(reqRec)));
        //var compEvent = component.getEvent("cparemovefirm");
        //compEvent.setParams({"miRecJSON" :JSON.stringify(reqRec)});
       // compEvent.fire();
	    //},
        //    removeFromFirm : function(component, event,recordJSON) {
        component.set("v.isLoading",true);
                    var remButton = component.find('removeMemberButton');  
                    remButton.set('v.label', 'Removed');
                    remButton.set('v.disabled', true);
                    //$A.util.removeClass(remButton, "RemoveButton");
                    //$A.util.addClass(remButton, "RemoveInProgressButton");
                           
        var action = component.get("c.createCPAFirmMemRequests");
        //let filterRecs = component.get("v.memInfo").filter(item => item.isChanged == true);
        //console.log('apex param==>', JSON.stringify(reqRec));
		action.setParams({mprJSON : JSON.stringify(reqRec)});
        
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
                        "message": "Your changes have been saved."
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
    
    updateMemberShips : function(component, event) {
        debugger;
        console.log('mirec:'+component.get("v.miRec"));
         console.log(component.get("v.miRec"));     
        let miRc = component.get("v.miRec");

        component.set("v.isLoading",true);
        var action = component.get("c.updateMemberShips");  
        console.log (miRc.refConId);
        console.log (miRc.adminCPA);
        console.log (miRc.cpaPortalShared);
        
       
        action.setParams({RCT : miRc.refConId,
                          shrd : miRc.cpaPortalShared,
                          admn : miRc.adminCPA 
                         });
        
        
        action.setCallback(this, function(response) {
            console.log('JC res '); 
            console.log(response);             
            var state = response.getState();
            component.set("v.isLoading",false);
            if(state === "SUCCESS"){
                let resp = response.getReturnValue();
                if(resp === 'SUCCESS'){
					var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type":"success",
                        "message": "Your changes have been saved."
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