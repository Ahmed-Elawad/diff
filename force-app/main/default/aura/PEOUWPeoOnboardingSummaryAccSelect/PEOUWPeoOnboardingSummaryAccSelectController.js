({
    init: function(cmp, e, helper) {
        // this gets the reord ID from the URL
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i;

        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            if (sParameterName[0] ==='c__RecordId') {
                cmp.set('v.recordId', sParameterName[1]);
                break;
            }
        }
        
        if (cmp.get('v.ParentAccountId') === undefined || cmp.get('v.ParentAccountId') === null) {
            helper.switchLoadState(cmp, e);
            helper.getUser(cmp, e)
            .then(user => helper.getAccounts(cmp, e, user))
            .then(parentAccount => helper.checkCovid(cmp, e, parentAccount))
            .then(accId => helper.getChecklist(cmp, e, accId))
            .then(peoChecklist => helper.getMedical(cmp, e, peoChecklist))
            .then(res => helper.switchLoadState(cmp, e))
            .catch(data => helper.handleErr(cmp, e, data))
        } else {
            cmp.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.');
        }
        if (!cmp.get('v.portalExperience')) {
            let exp = !cmp.get('v.peoFullChecklist.Experience__c') ? 'Paychex' : cmp.get('v.peoFullChecklist.Experience__c');
            cmp.set('v.portalExperience', exp);
        }
    }
})