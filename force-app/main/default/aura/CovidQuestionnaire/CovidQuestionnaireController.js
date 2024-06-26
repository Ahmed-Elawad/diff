({
     init: function(component, event, helper) {
         component.set('v.saveFunc' , $A.getCallback(() => helper.saveProgress(component, event, helper)));
         
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
            if (prfName =='Customer Community Login User Clone') component.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, visit the Need Help section on our homepage, so we can promptly address the issue.');
            else component.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.');
        }
         var submissionStatus = component.get('v.PEOChecklist.Peo_Covid_formStatus__c');
        if(submissionStatus === 'Complete'){
            component.set('v.formSubmitted', true);
        }
    },
    clearFields : function(component, event, helper) {
		console.log("Clearing fields...");
        helper.clearOutFields(component, event);
        helper.sendAutoSave(component, event, helper);
	},
    
    handleChange : function(component, event, helper) {
        if(component.get("v.answersChanged") == false)
        {
            component.set("v.answersChanged", true);
            console.log("setting  answersChanged to true");
        }
        
        var field = event.getSource();
        
        if(field.get("v.type") == 'Date' || field.get("v.type") == 'date') {
           field.setCustomValidity('') ;
        	var chckvalididty = field.get("v.validity");
        	console.log(chckvalididty.valid); // it gives false when 1st enter wrong format then i changed to correct format still shows
        	if(!chckvalididty.valid){
            	console.log("Setting custom validation message...");
            	field.setCustomValidity('format must be mm/dd/yyyy');
        	}else{
            	field.setCustomValidity('') ;
        	}
        	field.reportValidity();
    	}
        helper.sendAutoSave(component, event, helper);
    },
    
    saveProgress : function(component, event, helper) {
        helper.saveProgress(component, event, helper);
    },
    handleNext: function(cmp, e, helper){
        if(cmp.get('v.tabName')==='exposure'){
            cmp.set('v.tabName','prevention');
            cmp.set('v.actionName','Prev');
        }
        else if(cmp.get('v.tabName')==='prevention') {
            cmp.set('v.tabName','exposure');
            cmp.set('v.actionName','Next');
        }
    },
    openTab: function(cmp, e, helper) {
        console.log('in controller')
        helper.triggerEvt(cmp, e);
    },
})