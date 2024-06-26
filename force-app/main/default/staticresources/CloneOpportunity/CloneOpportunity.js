
function cancel(){

	var closeSubtab = function closeSubtab(result) {
		//Now that we have the tab ID, we can close it
		if(result.id != null){
			var tabId = result.id;
			sforce.console.closeTab(tabId);
		}
	};

	sforce.console.getEnclosingTabId(closeSubtab);
}

function showLoadingIcon(){
	document.getElementById('statusSpinner').style.visibility='visible';
}

function hideLoadingIcon(){
	document.getElementById('statusSpinner').style.visibility='hidden';
}
