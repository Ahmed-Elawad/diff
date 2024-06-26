({
    getInsightsForRecordId : function(component, event, helper){
        component.set('v.columns', [
            {label: 'Name', fieldName: 'linkName', type: 'url', 
            	initialWidth: 100,    
                typeAttributes: {
                        //label: { fieldName: 'Name__c' }, 
                        label: { fieldName: 'Marketing_Action__c' }, 
                        target: '_self'
            }},
            /*{label: 'Description', fieldName: 'Description__c', type: 'text'},
            {label: 'LP URL', fieldName: 'LP_URL__c', type: 'url'},*/
            {label: 'Intent Source', fieldName: 'Intent_Source__c', type: 'text'},
            {label: 'External URL', fieldName: 'External_URL__c', type: 'url'},
            {label: 'Created Date', fieldName: 'CreatedDate', type: 'date', 
                    
                typeAttributes: {  
                    day: 'numeric',  
                    month: 'short',  
                    year: 'numeric',  
                    hour: '2-digit',  
                    minute: '2-digit',  
                    second: '2-digit',  
                    hour12: true
            }}
            ]);
        var recordId = component.get("v.recordId");
        //var action = component.get("c.getInsightsById"); 
        var action = component.get("c.getIntentById"); 
                
        action.setParams({
            recordId: recordId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var records =response.getReturnValue();
                records.forEach(function(record){
                    record.linkName = '/'+record.Id;
                    console.log(record.Id + '::::'+ record.linkName);
                });
                component.set("v.insights", records);
                //var titleInsights = 'Insights'+' ('+records.length+')';
                var titleInsights = 'Customer Intent Signals'+' ('+records.length+')';
                component.set("v.insightsTitle", titleInsights);
                
            }
        });        
        $A.enqueueAction(action);  
    }
})