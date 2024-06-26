({
	navigateToNewQuotePage : function(component) {
		var opportunityId = component.get("v.recordId");


		var url = "/lightning/n/New_Quote?c__opportunityId=" + opportunityId;

		var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": url
        });
        urlEvent.fire();
	},



})