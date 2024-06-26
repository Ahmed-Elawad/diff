({
    doInit: function(component, event, helper) {
        console.log(component.get('v.OnbPEOChecklist'));
        console.log('Account ID:'+component.get('v.OnbPEOChecklist.Prospect_Client__c'));
        if(component.get('v.OnbPEOChecklist')!= null && component.get('v.OnbPEOChecklist')!= 'undefined'){
            console.log('OnbPEOChecklist not null. Ready for checklist refresh')
            helper.refreshChecklist(component, event, helper);
        }
        
    },
    
	setActiveTab: function(component, event, helper) {
        //update the code here
    },
})