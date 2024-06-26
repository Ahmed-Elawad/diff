({
	setRecordId : function(component, event, helper) {
        var recordId = component.get("v.pageReference.state.c__recordId");
        var objectType = component.get("v.pageReference.state.c__objectType");
        component.set("v.recordId", recordId);
        component.set("v.objectType", objectType);
	},
     
    getRCRForRecordId : function(component, event, helper){
        var recordId = component.get("v.recordId");
        var objectType = component.get("v.objectType");
        var action = null;
        console.log('getRCRForRecordId objectType: ', component.get("v.objectType"));
        var action = component.get("c.getReferenceClientRetentionForRCRAcctId");
     	
        if(!!action){
            action.setParams({recordId: recordId});
            
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state==='SUCCESS'){
                    
                    var envelope = response.getReturnValue();
                    console.log('envelope', envelope);
                    var refClientRets = envelope.refClientRets; 
                    component.set("v.refClientRets", refClientRets);
                    helper.formatRCRsForDisplay(component, event, helper, refClientRets);
                    helper.setUpDisplayColumns(component, event, helper);
                    helper.setTab(component, event, helper);
                    
                    
                }else{
                    var errors = response.getError();
                    console.log('errors', errors);
                    console.log(errors);
                }
            });
            
            $A.enqueueAction(action);
        }        
    },
    
    formatRCRsForDisplay : function(component, event, helper, refClientRets){
        for(var i = 0; i < refClientRets.length; i++){
            refClientRets[i].url = '/' + refClientRets[i].Id;
            if(refClientRets[i].Owner.Name){
            	refClientRets[i].name = refClientRets[i].Owner.Name;    
            }
            if(refClientRets[i].Prospect_Client_Name__c){
            	refClientRets[i].pcURL = '/' + refClientRets[i].Prospect_Client_Name__c;    
            }
            if(refClientRets[i].Prospect_Client_Name__r){
            	refClientRets[i].pcName = refClientRets[i].Prospect_Client_Name__r.Name;    
            }
            if(refClientRets[i].Prospect_Client_Contact__c){
            	refClientRets[i].ctctURL = '/' + refClientRets[i].Prospect_Client_Contact__c;    
            }
            if(refClientRets[i].Prospect_Client_Contact__r){
            	refClientRets[i].ctctName = refClientRets[i].Prospect_Client_Contact__r.Name;    
            }
            if(refClientRets[i].Case__c){
            	refClientRets[i].caseURL = '/' + refClientRets[i].Case__c;    
            }
            if(refClientRets[i].Case__r){
            	refClientRets[i].CaseNumber = refClientRets[i].Case__r.CaseNumber;    
            }
            
        }
	},
    
    setUpDisplayColumns : function(component, event, helper){
        var columns = [     
            {label: 'Reference Client Retention Number', fieldName: 'url', type: 'url', typeAttributes: { label:{fieldName: 'Name'}, target: '_blank'}},
            {label: 'Owner Name', fieldName: 'name', type: 'text', sortable: true},
            {label: 'Case Type', fieldName: 'Case_Type__c', type: 'text', sortable: true},           
            {label: 'Prospect-Client Name', fieldName: 'pcURL', type: 'url', typeAttributes: { label:{fieldName: 'pcName'}, target: '_blank'}},
            {label: 'Prospect-Client Number', fieldName: 'Prospect_Client_Number__c', type: 'text'},
            {label: 'Prospect-Client Contact', fieldName: 'ctctURL', type: 'url', typeAttributes: { label:{fieldName: 'ctctName'}, target: '_blank'}},
            {label: 'Current Step', fieldName: 'Current_Step__c', type: 'text', sortable: true},
            {label: 'Case', fieldName: 'caseURL', type: 'url', typeAttributes: { label:{fieldName: 'CaseNumber'}, target: '_blank'}},
            {label: 'Created Date', fieldName: 'CreatedDate', type: 'date', sortable: true},
            {label: 'Last Modified Date', fieldName: 'LastModifiedDate', type: 'date', sortable: true},
        ];
        component.set("v.columns", columns);
       
    },
            
    setTab : function(component, event, helper ){
    	var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: "Total Reference Client Retentions"
            });
		
            workspaceAPI.setTabIcon({
            tabId: focusedTabId,
            icon: "standard:list", //set icon you want to set      
    
         });             
        })
        .catch(function(error) {
            console.log(error);
        });  

     },
            
     sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.refClientRets");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse));
        cmp.set("v.refClientRets", data);
     },
            
     sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b)-(b > a));
        }
    }
})