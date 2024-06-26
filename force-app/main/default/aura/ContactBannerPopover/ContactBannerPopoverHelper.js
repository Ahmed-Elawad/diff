({

	navigateToContact : function(component, event, helper) {
		var contact = component.get("v.contact");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": contact.Id,
        });
        navEvt.fire();
	},

	getFields : function(component, event, helper){
		var action = component.get("c.getCompactLayoutFields");

		action.setCallback(this, function(response){
			var state = response.getState();
			if(state === 'SUCCESS'){
				var contact = component.get("v.contact");

				var fields = response.getReturnValue();
				var leftColumnFields = [];
				var rightColumnFields = [];
				for(var i = 0; i < fields.length; i++){
					var developerName = fields[i].DeveloperName__c.split('.');
					fields[i].value = helper.getFieldValue(helper, contact, developerName);
					fields[i].lookupIdValue = '';
					if(fields[i].Type__c == 'Lookup' && !!fields[i].LookupIdField__c){

						var lookupIdDevName = fields[i].LookupIdField__c.split('.');
						fields[i].lookupIdValue = helper.getFieldValue(helper, contact, lookupIdDevName);
					}
					//fields[i].value = contact[fields[i].DeveloperName__c];
					if(i % 2 == 0){
						leftColumnFields.push(fields[i]);
					}else{
						rightColumnFields.push(fields[i]);
					}
				}
				component.set("v.leftColumnFields", leftColumnFields);
				component.set("v.rightColumnFields", rightColumnFields);
			}else{
				var error = response.getError();
				console.log(error);
			}

		});

		$A.enqueueAction(action);
	},

	getFieldValue : function(helper, valueSource, developerName){
		if(developerName.length == 1){
			return valueSource[developerName[0]];
		}else{
			valueSource = valueSource[developerName[0]];
			developerName.shift();
			return helper.getFieldValue(helper, valueSource, developerName);
		}
	}
})