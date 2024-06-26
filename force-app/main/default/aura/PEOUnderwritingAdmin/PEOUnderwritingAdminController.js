({
	onLoad : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: "PEO Getting Started Administration"
            });
        })
        .catch(function(error) {
            console.log(error);
        });
		var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i;
		
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            if (sParameterName[0] ==='c__RecordId') {
                component.set('v.recordId', sParameterName[1]);
                break;
            }
        }
        helper.gatherStartingInformation(component, event);
    },
    handlePageMenuSelect : function(component, event, helper) {
    	var selectedMenuItemValue = event.getParam("value");
        if (selectedMenuItemValue == 'New Discrepancy'){
            helper.showNewDiscrepancy(component,event);
        }
    },
    
    /////Controls for Discrepancy Management
    //https://www.infallibletechie.com/2018/08/how-to-handle-selectedrows-in.html
    handleDiscSelect : function(component, event, helper) {
        var selectedRows = event.getParam('selectedRows'); 
        var setRows = [];
        if(selectedRows){
            for ( var i = 0; i < selectedRows.length; i++ ) {
                
                setRows.push(selectedRows[i]);
    
            }
        }
        component.set("v.selectedDiscs", setRows);
        
    },
    //https://developer.salesforce.com/docs/component-library/bundle/lightning:datatable/documentation
    updateDiscSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        console.log('updateDiscSorting fieldName: '+fieldName+' sortDirection: '+sortDirection);
        // assign the latest attribute with the sorted column fieldName and sorted direction
        cmp.set("v.discTableSortedBy", fieldName);
        cmp.set("v.discTableSortedDirection", sortDirection);
        helper.sortDiscData(cmp, fieldName, sortDirection);
    },
    insertDiscrepancySubmit : function(component, event, helper) {
        component.set("v.isProcessing",true);
        /*var form = component.find('newDiscrepancyForm'); with custom buttons, the fields attribute no longer works
        console.log('form'+form);
        var fields = form.getParam("fields"); 
        console.log('fields'+fields);
        fields["PEO_Underwriting_Checklist__c"] = component.get("v.newDiscChecklistId");*/
        component.find('newDiscrepancyForm').submit();
        console.log('insert submit');
        console.log('button pressed:'+event.getSource().getLocalId());
        component.set('v.discButtonChosen',event.getSource().getLocalId());
    },
    insertDiscrepancySuccess : function(component, event, helper) {
        console.log('insert success');
        helper.getDiscrepancies(component, event);
        var hideAction = component.get('c.hideNewDiscrepancy');
        var buttonChosen = component.get('v.discButtonChosen')
        if(buttonChosen && buttonChosen == 'discSubmit'){
            $A.enqueueAction(hideAction);
        }
        component.set("v.newDiscStatus",'Open');
        component.set("v.newDiscType",null);
        component.set("v.newDiscSubType",null);
        component.set("v.newDiscDate",null);
        component.set("v.newDiscInfo",null);
        var checklistOptions = component.get("v.checklistClientOptions");
        if(checklistOptions.length == 2){
            component.set("v.newDiscChecklistId", checklistOptions[1].value);
        }
        component.find('notifLib').showToast({
            "variant": "success",
            //"title": "Discrepancy Created",
            "message": "Discrepancy Created"
        });  
        helper.getDocsFromChecklist(component,event);
        component.set("v.isProcessing",false);
    },
    insertDiscrepancyError : function(component, event, helper) {
        console.log(event.getParam("message"));
        component.find('notifLib').showToast({
            "variant": "error",
            "title": "Discrepancy Not Created",
            "message": "There was a problem: " +  event.getParam("message")
        });
        helper.getDiscrepancies(component, event);
        component.set("v.isProcessing",false);
    },   
    updateDiscrepancies : function(component, event, helper) {
        helper.callUpdateDiscrepancies(component, event);
    },
    hideNewDiscrepancy : function(component, event, helper) {
        component.set("v.newDiscrepancyShow",false);
    },
    
    //////Controls for Doc Management
    handleDocMenuSelect : function(component, event, helper) {
    	var selectedMenuItemValue = event.getParam("value");
        if (selectedMenuItemValue.startsWith('Submit')){
            var docType = selectedMenuItemValue.split('-')[1]; 
            helper.submitToCS(component,event,docType);
        }
    },
    changeProspect : function(component, event, helper) {
        helper.getDocsFromChecklist(component, event);
    },
    handleFileMenuSelect : function(component, event, helper) {
    	var selectedMenuItemValue = event.getParam("value");
        if (selectedMenuItemValue.startsWith('Approve')){
            var docId = selectedMenuItemValue.split('-')[1]; 
            helper.approveDoc(component,event,docId);
        }
    },
    handleFileSelect : function(component, event, helper) {
        
        var selectedRows = event.getParam('selectedRows'); 
        var setRows = [];
        for ( var i = 0; i < selectedRows.length; i++ ) {
            
            setRows.push(selectedRows[i]);

        }
        component.set("v.selectedFiles", setRows);
    },
    handleFileAction : function(component, event, helper) {
        console.log('handleFileAction');
        var action = event.getParam('action');
        var row = event.getParam('row');
        console.log(row.ContentDocumentId);
        switch (action.name) {
            case 'viewFile':
                $A.get('e.lightning:openFiles').fire({
                    recordIds: [row.ContentDocumentId]
                }); 
                break;
        }
        
    },
    moveSelectedFiles: function(component, event, helper) {
        helper.saveFiles(component,event);
    },
    deleteSelectedFiles: function(component, event, helper) {
        helper.deleteTheseFiles(component,event);
    }
})