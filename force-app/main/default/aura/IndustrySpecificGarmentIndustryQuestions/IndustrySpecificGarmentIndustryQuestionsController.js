({
    handleChange: function(cmp, e, helper) {
        try {
            let field = e.getSource();
            let fieldName = field.get('v.name');
            let fieldValue = field.get('v.value');
            let objectAPIName = 'WC_Questionnaire_Industry_Specific__c';
            let Account = cmp.get('v.allAccounts')[0];
            if (fieldValue && fieldValue.length) {
                let recordId = cmp.get('v.garmentIndRec.Id');
                let autoSaveEvt = cmp.getEvent('autoSave');
                autoSaveEvt.setParam('objectName', objectAPIName);
                autoSaveEvt.setParam('accountId', Account.Id);
                autoSaveEvt.setParam('fieldName', fieldName);
                autoSaveEvt.setParam('fieldValue', fieldValue);
                autoSaveEvt.setParam('recordId', recordId);
                autoSaveEvt.setParam('accountName', Account.Name);
                autoSaveEvt.fire();
            }
        } catch(e) {
            console.error('Error sendAutoSave');
            console.error(e);
        }
    },
})