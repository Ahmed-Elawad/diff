({
    doInit : function(component, event, helper) {
        var action = component.get('c.getTracking');
        console.log('component.get("v.recId")',component.get("v.recId"));
        action.setParams(
            {
                "recordId":component.get("v.recId")
            })
        action.setCallback(this, function(response){           
            var name = response.getState();
            if (name === "SUCCESS") {
                var progressCalc = response.getReturnValue();
                component.set("v.CSOTrackingObj", response.getReturnValue());
                console.log('CSO-Tracking ->',response.getReturnValue());
                if(progressCalc.FirstStepsCompleted!=''){
                    component.set("v.progress", 10); 
                }
                if(progressCalc.PriorPayrollCompleted!=''){
                    component.set("v.progress", 20); 
                }
                if(progressCalc.BusinessInfoCompleted!=''){
                    component.set("v.progress", 30); 
                }
                if(progressCalc.BankingInfoCompleted!=''){
                    component.set("v.progress", 40); 
                }
                if(progressCalc.PayScheduleCompleted!=''){
                    component.set("v.progress", 50); 
                }
                if(progressCalc.TaxInfoCompleted!=''){
                    component.set("v.progress", 60); 
                }
                if(progressCalc.AddEmpsCompleted!=''){
                    component.set("v.progress", 70); 
                }
                if(progressCalc.QuoteSignedDate!=''){
                    component.set("v.progress", 80); 
                }
                if(progressCalc.DocsCompleted!=''){
                    component.set("v.progress", 90); 
                }
                if(progressCalc.SubmitCompleted!=''){
                    component.set("v.progress", 100); 
                }
                console.log(response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    showDetails : function(component, event, helper){
        component.set("v.showDetails", true); 
    },
    hideDetails : function(component, event, helper){
        component.set("v.showDetails", false); 
    },
    resendRegistration : function(component, event, helper){
        component.set("v.showDetails", false); 
        var cso = component.get("v.CSOTrackingObj");
        
        /*var showToast = $A.get("e.force:showToast"); 
                    showToast.setParams({ 
                        'title' : 'Confirmation', 
                        'type' : 'success',
                        'message' : 'Resend Registration Successful'
                    }); 
                    showToast.fire();*/
        
        var urlEvent = $A.get("e.force:navigateToURL");
        
        urlEvent.setParams({
            "url": "/apex/FlexNewClientOnboarding?id="+cso.contactId+'&oppId='+component.get("v.recId")
        });
        urlEvent.fire();
    },
})