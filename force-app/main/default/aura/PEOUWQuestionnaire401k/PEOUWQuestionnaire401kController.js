({
	init: function(component, event, helper) {
      if (component.get('v.user')) {
           let user = component.get('v.user');
            let prfName = user.Profile.Name;
            let isAnalyst = prfName == 'HRS Regional Sales Admin SB';
            let isNsc = prfName == 'HRS PEO Centric Sales - SB';
            let isDSM = prfName == 'HRS Sales Manager - SB';
            let isAdmin = prfName == 'System Administrator' || prfName == 'System Administrator - TAF';
          	console.log(prfName);
          
          if (isAnalyst || isNsc || isDSM || isAdmin) {
              component.set('v.allowDiscLog', true);
          }
          if (prfName =='Customer Community Login User Clone') component.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, visit the Need Help section on our homepage, so we can promptly address the issue.');
          else component.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.');
          
          var submissionStatus = component.get('v.PEOChecklist.Peo_401k_formStatus__c');
          if(submissionStatus === 'Completed'){
              component.set('v.formSubmitted', true);
          }
        }  
        console.log(component.get('v.PEOChecklist'))
        component.set('v.saveFunc' , $A.getCallback(() => helper.saveProgress(component, event, helper)));
        
        let tabs = [];
        tabs.push('401k');
        tabs.push('Other');
        component.set("v.selectedTab", '401k');
        component.set('v.tabList', tabs);
        
    },
    saveProgress : function(component, event, helper) {
        /*var buttonLabel = event.getSource().get("v.label");
        component.set('v.buttonLabel',buttonLabel);
        if(buttonLabel != 'Save and Finish Later'){
            component.set('v.PEOChecklist.Peo_401k_formStatus__c','Complete');
        }
        helper.cancelAutoSaveEvents(component, event, helper);
        helper.saveFormProgress(component, event);*/
        helper.saveProgress(component, event, helper);
    },
    
    clearFields : function(component, event, helper) {
        console.log("Clearing fields...");
        helper.clearOutFields(component, event, helper);
        helper.sendAutoSave(component, event, helper);
    },
    
    handleChange : function(component, event, helper) {
		if(component.get("v.answersChanged") == false)
        {
            component.set("v.answersChanged", true);
            console.log("setting  answersChanged to true");
        }
        helper.sendAutoSave(component, event, helper);
	},
    openTab: function(cmp, e, helper) {
        console.log('in controller')
        helper.triggerEvt(cmp, e);
    },    
})