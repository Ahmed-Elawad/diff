({
    getCampaignsForRecordId : function(component, event, helper){
        component.set('v.columns', [
            {label: 'Name', fieldName: 'linkName', type: 'url', 
            
            typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}}
            ]);
        var recordId = component.get("v.recordId");
        var action = component.get("c.getOpenCampaigns"); 
                
        action.setParams({
            recordId: recordId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var records =response.getReturnValue();
                records.forEach(function(record){
                    record.linkName = '/'+record.Id;
                });
                component.set("v.campaigns", records);
            }
        });        
        $A.enqueueAction(action);  
    }
   
})