({
	init : function (component,event,helper) {
        console.log('init');
        var flow = component.find("supportFlow");
        flow.startFlow("PEO_Getting_Started_Case_Submission");
        helper.getRunningUser(component,event,helper)
        .then(res =>  helper.getOpenCases(component,event,helper))
        .catch(function(err) {
            console.log('ERROR: '+err);
        });
    }
})