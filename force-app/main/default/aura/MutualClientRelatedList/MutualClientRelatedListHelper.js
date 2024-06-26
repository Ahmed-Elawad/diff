({
	setRecordId : function(component, event, helper) {
        var recordId = component.get("v.pageReference.state.c__recordId");
        var objectType = component.get("v.pageReference.state.c__objectType");
        var businessType = component.get("v.pageReference.state.c__businessType");
        component.set("v.recordId", recordId);
        component.set("v.objectType", objectType);
        if(businessType === 'Accounting Firm' || businessType === 'Strategic Accountant Firm') {
            component.set("v.isAccountingFirm", true); 
        } else {
            component.set("v.isAccountingFirm", false); 
        }
	},
     
    getMutualClientsForRecordId : function(component, event, helper){
        var recordId = component.get("v.recordId");
        var objectType = component.get("v.objectType");
        var action = null;
        console.log('sus', component.get("v.objectType"));

        if(objectType === 'Referral_Contact__c'){
        	var action = component.get("c.getMutualClientsForReferralContact");
          
    	}else if(objectType === 'Referral_Account__c'){
    		var action = component.get("c.getMutualClientsForReferralAccount")
    	}
        
        if(!!action){

	        action.setParams({recordId: recordId});
	        
	        action.setCallback(this, function(response){
	            var state = response.getState();
	            if (state==='SUCCESS'){
                   
	                var envelope = response.getReturnValue();
                    console.log('envelope', envelope);
	                var mutualClients = envelope.mutualClients;
	                helper.formatMutualClientsForDisplay(component, event, helper, mutualClients);
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

    formatMutualClientsForDisplay : function(component, event, helper, mutualClients){
    // console.log(Integer.valueOf(mutualClients[0].X401K_Assets__c));
        for(var i = 0; i < mutualClients.length; i++){
      // console.log('Payx401K: '+mutualClients[i].Paychex_401K_Assets__c);
       //console.log('Aggregate401K: '+mutualClients[i].X401K_Assets__c);
            mutualClients[i].url = '/' + mutualClients[i].Id;
            if(mutualClients[i].CPA_Name_Ref__r)
                mutualClients[i].cpaFullName = mutualClients[i].CPA_Name_Ref__r.Name;
            else
                mutualClients[i].cpaFullName = "";
            if(mutualClients[i].MutualClientRelations__r){
                if(mutualClients[i].MutualClientRelations__r.length > 0){
                    mutualClients[i].verificationType = mutualClients[i].MutualClientRelations__r[0].ReferralSourceVerification__c;
                    mutualClients[i].verifiedBy = mutualClients[i].MutualClientRelations__r[0].CreatedBy.Name;
                    mutualClients[i].verificationDate = mutualClients[i].MutualClientRelations__r[0].ReferralSourceVerificationDate__c;
                }
            }else{
                mutualClients[i].verificationDate = "";
                mutualClients[i].verificationType = "";
                mutualClients[i].verifiedBy = "";
            }
            if(!!mutualClients[i].NumberOfEmployees){
                mutualClients[i].NumberOfEmployees = mutualClients[i].NumberOfEmployees + '';
            }
            if(!!mutualClients[i].Owner.LastName){
                mutualClients[i].lastname = mutualClients[i].Owner.LastName;
            }
            if(!!mutualClients[i].BillingAddress){
                mutualClients[i].state = mutualClients[i].BillingAddress.state;
            }
            if(!!mutualClients[i].BillingAddress){
                mutualClients[i].postalcode = mutualClients[i].BillingAddress.postalCode;
            }
            
        }

        component.set("v.mutualClients", mutualClients);
    },

    setUpDisplayColumns : function(component, event, helper){
        var columns = [     
            {label: 'Prospect-Client Name', fieldName: 'url', type: 'url', typeAttributes: { label:{fieldName: 'Name'}, target: '_blank'} },
            // {label: 'CPA Full Name', fieldName: 'CPA_Name_Ref__c', type: 'text',
            //     typeAttributes: {
            //         object: 'Account',
            //         fieldName: 'CPA_Name_Ref__c',
            //         value: { fieldName: 'CPA_Name_Ref__c' },
            //         context: { fieldName: 'Id' },
            //         name: 'Referral_Contact__c',
            //         fields: ['Referral_Contact__c.Name'],
            //         target: '_self'
            //     },
            // editable: true},
            {label: 'Fed Id Name', fieldName: 'Fed_ID_Name__c', type: 'text'},
            {label: 'Bis ID', fieldName: 'Bis_ID__c', type: 'number'},
            {label: 'Created Date', fieldName: 'CreatedDate', type: 'date'},
            {label: 'Prospect-Client Number', fieldName: 'AccountNumber', type: 'text'},
            {label: 'Type', fieldName: 'Type', type: 'text' },
            {label: 'Billing State/Province', fieldName: 'state', type: 'text'},
            {label: 'Billing ZIP/Postal Code', fieldName: 'postalcode', type: 'text'},
            {label: 'Employees', fieldName: 'NumberOfEmployees', type: 'text'},
            {label: 'Owner Last Name', fieldName: 'lastname', type: 'text'},
            {label: 'Paychex 401K Assets', fieldName: 'Paychex_401K_Assets__c', type: 'currency'},
            {label: 'Aggregate 401K Assets', fieldName: 'X401K_Assets__c', type: 'currency'},
        ];
        component.set("v.columns", columns);
       
    },
            
    setTab : function(component, event, helper ){
    	var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: "Mutual Clients"
            });
		
            workspaceAPI.setTabIcon({
            tabId: focusedTabId,
            icon: "standard:client", //set icon you want to set      
    
         });             
        })
        .catch(function(error) {
            console.log(error);
        });  

     }
})