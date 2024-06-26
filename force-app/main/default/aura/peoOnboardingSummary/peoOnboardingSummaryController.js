({
    setup : function(cmp, e, helper) {
        try {
            // make one method on controller to handle these callbacks
            // too many server calls
            console.log(cmp.get('v.runningUserProfile'));
            //helper.getIndustry(cmp, e, helper);
            helper.setProfile(cmp, e)
            .then(res => helper.getChecklist(cmp, e))
            .then( accId => helper.getMedical(cmp, accId))
            //.then( accId => helper.getPeoChecklist(cmp, accId))
            .then(accId => helper.setRequiredDocuments(cmp, cmp.get('v.peoChecklist')))
            .then($A.getCallback((peoId) => helper.getDocs(cmp, peoId)))
            .then($A.getCallback((docData) => helper.getDiscrepencies(cmp, docData)))
            .then($A.getCallback(() => helper.checkMedPrequal(cmp, e, helper)))
            .then($A.getCallback(()  => helper.initRender(cmp, e, helper)))
            .catch(err => console.log('Caught err: ', err))
            // Then set the required documents on the checklist
            // Then get the documents
            // then get and set their discrepencies
            // in an error event use the helper method to show the error      
        } catch(e) {
            console.log(e);
        }
        
    },
    handleSection: function(cmp, e, helper) {
        console.log('should open')
    }
})