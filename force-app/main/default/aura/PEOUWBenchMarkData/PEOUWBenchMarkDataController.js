({
	fetchBenchmarkValues : function(component, event, helper) {
        console.log('controller fetchBenchmarkValues');
        component.set('v.oldNaics',component.get('v.currentAccount.NAICS_Code__c'));
        console.log('fetchBenchmarkValues oldNaics:'+component.get('v.oldNaics'));
        //Benchmark
        component.set('v.benchMarkPos','');
        if(component.get('v.currentAccount.NAICS_Code__c').length == 6){
            helper.helperFunctionAsPromise(component, event, helper, helper.buildDatainSF)
            .then($A.getCallback(function(res) {
                return helper.fetchDataFromSF(component, event, helper)}
                                ))
            .catch(err => helper.handleError(err));
        }
	},
    
    naicsChange : function(component, event, helper) {
        console.log('Naics change');
        console.log('oldNaics:'+component.get('v.oldNaics'));
        console.log('currentAccount NAICS_Code__c:'+component.get('v.currentAccount.NAICS_Code__c'));
        if(component.get('v.currentAccount.NAICS_Code__c') != component.get('v.oldNaics')){
             helper.helperFunctionAsPromise(component, event, helper, helper.buildDatainSF)
            .then($A.getCallback(function(res) {
                return helper.fetchDataFromSF(component, event, helper)}
                                ))
            .catch(err => helper.handleError(err));
            component.set('v.oldNaics',component.get('v.currentAccount.NAICS_Code__c'));
            console.log('oldNaics after refresh:'+component.get('v.oldNaics'));
        }
    },
})