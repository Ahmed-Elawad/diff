({
	createEventFile : function(component, event, helper){

		var recordId = component.get("v.recordId");
		var action = component.get("c.getEventFields");
		action.setParams({recordId: recordId});

		action.setCallback(this, function(response){
			var state = response.getState();

			if(state === 'SUCCESS'){
				var eventInfo = response.getReturnValue();
				component.set("v.evnt", eventInfo);
				helper.createDownloadableFile(component, event, helper);
			}else{
				console.log(response.getError());
			}
		});

		$A.enqueueAction(action);
	},


	createDownloadableFile : function(component, event, helper) {
		var textFile = null;
		var evnt = component.get("v.evnt");
		var textBlob = 'BEGIN:VCALENDAR\n' +
			'VERSION:2.0\n' +
			'PRODID:-//salesforce.com//Calendar//EN\n' +
			'BEGIN:VEVENT\n' +
			'UID:353d1cb1-14b0-4846-b63d-1ec7bdfaec04\n' +
			'DTSTAMP:' + helper.formatDate(helper.getCurrentDateTime()) + '\n' +
			'SUMMARY:' + evnt.Subject + '\n' +
			'DESCRIPTION:' + helper.formatWithoutNewline(evnt.Description) + '\n' +
			'LOCATION:' + evnt.Location + '\n' +
			'CATEGORIES:salesforce.com\n' +
			'CREATED:' + helper.formatDate(evnt.CreatedDate) + '\n' +
			'LAST-MODIFIED:' + helper.formatDate(evnt.LastModifiedDate) + '\n' +
			'STATUS:CONFIRMED\n' +
			'DTSTART:' + helper.formatDate(evnt.StartDateTime) + '\n' +
			'DURATION:PT' + evnt.DurationInMinutes + 'M\n' +
			'END:VEVENT\n' +
			'END:VCALENDAR';

	    var data = new Blob([textBlob], {type: 'text/plain'});

	    // If we are replacing a previously generated file we need to
	    // manually revoke the object URL to avoid memory leaks.
	    if (textFile !== null) {
			window.URL.revokeObjectURL(textFile);
	    }

	    textFile = window.URL.createObjectURL(data);

		var create = document.getElementById('create');
		var link = document.getElementById('downloadlink');
		link.download = helper.formatDate(evnt.StartDateTime) + '.ics';
		link.href = textFile;
		link.style.display = 'block';
	    document.getElementById("downloadlink").click();
	    var dismissActionPanel = $A.get("e.force:closeQuickAction");
		dismissActionPanel.fire();
	    //component.set("v.downloadFile", textFile);

	},

	onclickLink : function(component, event, helper){
		var create = document.getElementById('create');
		var link = document.getElementById('downloadlink');
		var textFile = component.get("v.downloadFile");
		link.href = textFile;
		link.style.display = 'block';
	},

	formatDate : function(dateString){
		var dateString = dateString.split('.')[0];
		dateString = dateString.replace(/-/g, '').replace(/:/g, '');
		return dateString + 'Z';
	},

	formatWithoutNewline : function(newlineString){
		return newlineString.replace(/(\r\n|\n|\r)/gm,"\\n");
	},

	getCurrentDateTime : function(){
		var e = new Date();
		return e.toISOString();
	}


})