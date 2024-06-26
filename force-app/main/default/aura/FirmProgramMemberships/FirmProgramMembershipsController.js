({
	initLoad : function(component, event, helper) {
		helper.fethMemberShips(component, event);    
        let allUsrs = component.get("v.memInfo")
        console.log(allUsrs); 
        
	},
    saveChanges : function(component, event, helper) {
        helper.updateMemberShips(component, event);
	},
    handleCPARemoveFirmEvent : function(component, event, helper) {
        let mpJSON = event.getParam("miRecJSON");
        helper.removeFromFirm(component, event,mpJSON);
	},
        handleCPARemoveAdmin : function(component, event, helper) {
        let mpJSON = event.getParam("miRecJSON");
        helper.removeFromFirm(component, event,mpJSON);
	},
        handlecparemoveShared : function(component, event, helper) {
        let mpJSON = event.getParam("miRecJSON");
        helper.removeFromFirm(component, event,mpJSON);
	},
    handlePlatformOptOut : function(component, event, helper) {
    	component.set("v.isModalOpen",true);
    },
    closeModel: function(component, event, helper) {
      // Set isModalOpen attribute to false  
      component.set("v.isModalOpen", false);
    },
    submitDetails: function(component, event, helper) {
    	let reason = component.get("v.OptOutReason");
        if($A.util.isEmpty(reason)){
            var optOutCmp = component.find('optOutRec');//.reduce(function (validSoFar, inputCmp) {
        	optOutCmp.reportValidity();
        }else{
        	helper.firmOptOut(component, event);
            component.set("v.isMOLoading",true);
        }
    }
})