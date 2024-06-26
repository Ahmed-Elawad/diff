({
    getUserInfo : function(component, event, helper){
        var action = component.get("c.getUserInfo");
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var isThisCPQUser = response.getReturnValue();
                component.set("v.isThisCPQUser", isThisCPQUser);
                console.log('*** isCPQUser(), isThisCPQUser: ' + isThisCPQUser);
            }else{
                console.log('error retrieving isCPQUser value');
            }
        });
        $A.enqueueAction(action);
    },
    
    getPicklistValues : function(component, event, helper){
        var action = component.get("c.getPickListValuesIntoList");
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('*** state: ' + state);
            if(state === 'SUCCESS'){
                var list = response.getReturnValue();
                component.set("v.picvalue", list);
                console.log('*** picvalue, list: ' + list);
            }
            else if(state === 'ERROR'){
                console.log('error retrieving picklist values');
            }
        });
        $A.enqueueAction(action);                
    },
    
    validateForm : function(component, event, helper) {

        var validItem = component.find('quoteField').reduce(function (validSoFar, inputCmp) {
            if(typeof inputCmp.showHelpMessageIfInvalid !== "undefined"){
                console.log(inputCmp.showHelpMessageIfInvalid());
                validSoFar = validSoFar && inputCmp.get("v.validity").valid;

            }else{
                if(inputCmp.get("v.required") && inputCmp.get("v.value") == null){
                    validSoFar = false;
                    inputCmp.set("v.errors",[{message:"Complete this field"}])
                }else{
                    inputCmp.set("v.errors",null);
                }
            }

            return validSoFar; 
        }, true);


        return validItem;
		
	},

	cancelNewQuote : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
    },

    saveQuote : function(component, event, helper){
        if(helper.validateForm(component)) {
        	var opportunity = component.get('v.opportunity');
            var probability = opportunity.Probability;
           
            
            if(probability <  90){
    		var quote = helper.setQuoteDefaults(component);
        	helper.showSpinner(component);

        	var action = component.get("c.saveNewQuote");

        	action.setParams({
        		newQuote: quote
        	});

        	action.setCallback(this, function(response){
        		var state = response.getState();
        		if(state === 'SUCCESS'){
        			var newQuote = response.getReturnValue();
        			helper.navigateToNewQuote(component, newQuote);

        		}else{
        			console.log(response.getError());
        		}

	        	helper.hideSpinner(component);
        	});

        	$A.enqueueAction(action);
           }else{
            helper.showError(component); 
            }
        }
    },

    setQuoteDefaults : function(component){

    	var quote = component.get("v.simpleQuote");
    	var opportunity = component.get("v.opportunity");
    	quote.SBQQ__Account__c = opportunity.AccountId;
    	quote.SBQQ__PriceBook__c = opportunity.Pricebook2Id;
    	quote.SBQQ__PricebookId__c = opportunity.Pricebook2Id;
    	quote.SBQQ__SalesRep__c = opportunity.OwnerId;
    	quote.SBQQ__Status__c = 'Draft';
    	quote.SBQQ__WatermarkShown__c = true;
    	return quote;
    	
    },

    navigateToNewQuote : function(component, newQuote){

        var workspaceAPI = component.find("workspace");

        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
			workspaceAPI.closeTab({tabId: focusedTabId});

        }).then(function(response){

			workspaceAPI.openTab({
	            url: '/lightning/r/SBQQ__Quote__c/' + newQuote.Id + '/view'
	        }).then(function(newQuoteTab){
	            workspaceAPI.focusTab({tabId : newQuoteTab});
	        });

        }).catch(function(error) {
			var navEvt = $A.get("e.force:navigateToSObject");
	        navEvt.setParams({
	          "recordId": newQuote.Id,
	        });
	        navEvt.fire();
        });

    },

	showSpinner : function(component){
		var spinner = component.find('spinner');
		$A.util.removeClass(spinner, 'slds-hide');
		$A.util.addClass(spinner, 'slds-show');

	},

	hideSpinner : function(component){
		var spinner = component.find('spinner');
		$A.util.removeClass(spinner, 'slds-show');
		$A.util.addClass(spinner, 'slds-hide');

	},
    
     showError : function(component) {
        var toastEvent = $A.get("e.force:showToast");
        var Opportunity = component.get("v.opportunity");
        var oppStage = Opportunity.StageName;
        toastEvent.setParams({
            title : 'Error',
            message:'Quote cannot be created for Opportunity status '+oppStage+' or higher',
            duration:'20000',
            key: 'info_alt',
            type: 'error',
            mode: 'pester'
        });
        toastEvent.fire();
    }

})