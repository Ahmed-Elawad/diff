({
	openClientProfile : function(component) {
        var recordId = component.get("v.recordId");
        
		var urlEvent = $A.get("e.force:navigateToURL");
   		urlEvent.setParams({
            "url":"/apex/Onboarding?id=" + recordId
        });
        urlEvent.fire();
	},
    
    newOracleQuote : function(component) {
       var recordId = component.get("v.recordId");
        
		var urlEvent = $A.get("e.force:navigateToURL");
   		urlEvent.setParams({
            "url":"/apex/OracleNewQuote?id=" + recordId
        });
        urlEvent.fire(); 
	}
})