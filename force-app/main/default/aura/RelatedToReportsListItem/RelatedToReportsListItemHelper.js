({
	navigateToReport : function(component, event, helper) {

		console.log('the record id is: ---> '+component.get("v.recordId"));
        var recId = component.get("v.recordId");
        recId = recId.substring(0, 15);
        console.log('the recId is: ---> '+recId);
		
        var reportBase = "/lightning/r/Report/";
		var reportId = component.get("v.reportItem.ReportID__c");
		//var filter = "/view?fv0=" + component.get("v.recordId");
		var filter = "/view?fv0=" + recId;
		var url = reportBase + reportId + filter;
		//var filter = "/view?queryScope=userFolders";
        //var url = reportBase + reportId + filter;
		console.log('navigateToReport url: ' + url);
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
			"url": url
		});

		urlEvent.fire();
	}
})