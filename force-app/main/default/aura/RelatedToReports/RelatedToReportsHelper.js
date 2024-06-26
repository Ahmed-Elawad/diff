({
	openReports : function(component, event) {

		var action = component.get("c.allRelatedReports");

		action.setParams({
			recordId : component.get("v.recordId")
		});

		action.setCallback(this, function(response){
							 
			var state = response.getState();   
		
			if(state === 'SUCCESS') {
				var relatedReports = response.getReturnValue(); 
				component.set("v.listOfReports", relatedReports);

			}else{
				console.error(response.getError()); 
			}
		});

		$A.enqueueAction(action); 


	},

})