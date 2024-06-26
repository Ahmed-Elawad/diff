({
	formatDisplayFields : function(component){
		var displayFields = component.get('v.formattedDisplayFields');
		var account = component.get('v.account');
		displayFields = {};
		displayFields['BUPrimaryClient'] = this.formatBUPrimaryClient(account.Primary_Client_Combined__c);
		displayFields['DNCEIndicator'] = this.formatDNCEIndicator(account.Do_Not_Call__c, account.Email_Opt_Out__c);
		displayFields['atRisk'] = this.formatAtRisk(account.At_Risk__c);
		displayFields['potentialRisk'] = this.formatPotentialRisk(account.Potential_Risk__c);
		component.set("v.formattedDisplayFields", displayFields);

	},

	formatBUPrimaryClient : function(primaryClient){
		var BUPrimaryClient = '\n';
		if(!!primaryClient){
			BUPrimaryClient = '   ' + primaryClient.replace(';','\n   ');
		}
		return BUPrimaryClient;
	},

	formatDNCEIndicator : function(doNotCall, emailOptOut){
		var DNCEIndicator = '';
		if(doNotCall){
			DNCEIndicator += '   Do Not Call\n';
		}

		if(emailOptOut){
			DNCEIndicator += '   Do Not Email\n';
		}

		return DNCEIndicator;
	},

	formatAtRisk : function(atRisk){
		var atRiskFormatted = '\n';
		if(!!atRisk){
			atRiskFormatted = '   ' + atRisk.replace(';','\n   ');
		}
		return atRiskFormatted;
	},

	formatPotentialRisk : function(potentialRisk){
		var potentialRiskFormatted = '\n';
		if(!!potentialRisk){
			potentialRiskFormatted = potentialRisk.replace(';','\n   ');
		}
		return potentialRiskFormatted;
	},

	removeLastCharacter : function(str, removedString){
		if(str.includes(removedString)){
			return str.substring(0, str.lastIndexOf(removedString));
		}
		return str;
	},

	getCasesForAccount : function(component){
		var recordId = component.get("v.recordId");

		var action = component.get("c.getAccountCases");

		action.setParams({
			accountId: recordId
		});

		action.setCallback(this, function(response){
			var state = response.getState();

			if(state === 'SUCCESS'){
				var cases = response.getReturnValue();
				component.set("v.clientActionNeeded", cases);
			}else{
				console.log('error retrieving cases');
			}
			this.hideSpinner(component);
		});

		$A.enqueueAction(action);
	},

	showSuccessMessage : function(component){
	    var toastEvent = $A.get("e.force:showToast");
	    toastEvent.setParams({
	        "title": "Success!",
	        "message": "The record has been updated successfully."
	    });
	    toastEvent.fire();
	},

	toggleSpinner: function (component) {
        var spinner = component.find("spinner");
        $A.util.toggleClass(spinner, "slds-hide");
    },
	showSpinner: function (component) {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
	hideSpinner: function (component) {
        var spinner = component.find("spinner");
        $A.util.addClass(spinner, "slds-hide");
    }
})