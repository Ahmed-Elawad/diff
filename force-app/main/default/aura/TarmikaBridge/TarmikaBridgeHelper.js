({
    initialValidationCheck : function(component, helper){
        component.set("v.showSpinner", true);
        var sourceObjectId = component.get("v.recordId");
  		var opptyToCheck = null;
        var action = component.get("c.validCheck");
        action.setParams({
            "recordId": sourceObjectId
        });
        action.setCallback(this, function(response) {
            //store state of response
            var oppWrapper = response.getReturnValue();
            var state = response.getState();
            
            if(state === 'SUCCESS'){
                component.set("v.isThisOpptyProbability", oppWrapper.hasOpptyStage);
                component.set("v.isThisRecordType", oppWrapper.hasOpptyRecordType);
                component.set("v.isThisAlreadyQuoted", oppWrapper.hasOpptyQuote);
                component.set("v.isThisPCSalesUser", oppWrapper.hasValidUser);
                component.set("v.isRecCreated", oppWrapper.validRecCreate);
                component.set("v.valid", oppWrapper.validForBridge);
                component.set("v.message", oppWrapper.validForBridgeMsg);      
                component.set("v.isLoaded",true); 
                //component.set("v.showSpinner", false);
                if(oppWrapper.validForBridge && oppWrapper.quoteRec != null && oppWrapper.quoteRec != ''){
                    helper.postToTarmika(component, oppWrapper.quoteRec);
                } else{
                    component.set("v.showSpinner", false);
                }
                                
            }  
            if(state=='ERROR'){
                component.set("v.showSpinner",false);
                console.log(response.getError());                
            }
            console.log('Valid to send to Tarmika '+component.get("v.valid")+' '+component.get("v.message")+' '+component.get("v.showSpinner")); 
            
        });
        $A.enqueueAction(action);   
    },
       
    postToTarmika : function(component, record){
  		var opptyToCheck = null;
        var action = component.get("c.postCall");
        action.setParams({
            "digitalQuoteRec": record
        });
        action.setCallback(this, function(response) {
            //store state of response
            var oppWrapperAPI = response.getReturnValue();
            var state = response.getState();
            //alert(oppWrapperAPI);
            
            if(state === 'SUCCESS'){
                component.set("v.isAPICallSuccess", oppWrapperAPI.validAPICall); 
                component.set("v.message", oppWrapperAPI.validAPICallMsg);   
                component.set("v.isOpptyUpdated", oppWrapperAPI.quoteCreated);
                component.set("v.isLoaded",true);                  
            }  
            if(state=='ERROR'){
                console.log(response.getError());                 
            }
            component.set("v.showSpinner",false);
            console.log('API Call to Tarmika state: '+state+' '+component.get("v.isAPICallSuccess")+' '+component.get("v.message")+' '+component.get("v.showSpinner")); 
            console.log('Opportunity updated with quote state: '+state+' '+component.get("v.isOpptyUpdated")+' '+component.get("v.message")+' '+component.get("v.showSpinner")); 
        });
        $A.enqueueAction(action);   
    },
	
})