({
	formatSensitivityList : function(component, event, helper) {
    	
        var sensSize = component.get("v.sensitivityList");
        var unformatted = '';

        if(sensSize != null){
            unformatted =  sensSize; 
        }//if 
        var formatted = unformatted.replace (/,/g, "<br>");
        
        component.set("v.display", formatted);

	} 
})