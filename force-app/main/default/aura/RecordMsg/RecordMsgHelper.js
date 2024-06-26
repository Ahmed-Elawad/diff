({
    recordMessageCheck : function(component){
        var sourceObjectId = component.get("v.recordId");
        console.log('recordMessageCheck sourceObjectId='+sourceObjectId);
        var action = component.get("c.getRecordMsgs2");
        action.setParams({
            "recId": sourceObjectId
        });
        
        action.setCallback(this, function(response){        
            var state = response.getState();
            if(state === 'SUCCESS')
            {
                var returnValue = response.getReturnValue();
            }  
            console.log('messages returnValue='+returnValue); 
            component.set("v.messages", returnValue);
        });
        $A.enqueueAction(action);   
    },
})