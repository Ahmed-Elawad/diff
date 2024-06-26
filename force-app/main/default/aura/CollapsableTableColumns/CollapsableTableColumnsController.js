({
    //Added by Bharat to show toast message after uploading the files
    uploadFinished: function(cmp, event, helper){
        var toastEvent = $A.get("e.force:showToast");
        // show toast on file uploaded successfully 
        toastEvent.setParams({
            "message": "Files have been uploaded successfully!",
            "type": "success",
            "duration" : 2000
        });
        toastEvent.fire();
        console.log('Collapsable table columns: Upload finished refresh the cmp here');
        helper.getDocsFromChecklist(cmp, event);
        helper.getUpdatedChecklist(cmp, event, helper);
    },
    //Added by Bharat to open PEO Onboarding Document in subtab
    openTab: function(cmp, event, helper){
        var workspaceAPI = cmp.find("workspace");
        workspaceAPI.openTab({
            url:'/lightning/r/PEO_Onboarding_Document__c/'+ cmp.get("v.documentId") +'/view',
            focus:true
        }).then(function(response){
            workspaceAPI.getTabInfo({
                tabId:response
            }).then(function(tabInfo){
                console.log('Record ID for this tab is: '+tabInfo.recordId);
            });
        }).catch(function(error){
            console.log('Error occured while navigation: '+error);
        });
    },
    
    onLoad: function(cmp, event, helper){
        console.log('checklistId:'+cmp.get('v.checklistId'));
        console.log('HSF checklist status:');
        console.log(cmp.get('v.peoChecklist.HSF_Submission_Status__c'));
        helper.getDocsFromChecklist(cmp, event);
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
    
   /*updateModal : function(component, event, helper) {
        console.log('Controller updateModal');
        component.set('v.dispHSFmodal',true);
        
    },
    
    cancelModal: function(component, event, helper){	
        component.set('v.dispHSFmodal', false);	
    },	
    
    confirmModal: function(component, event, helper){	
        helper.submitForHSF(component, event, helper);
    },	*/
    
    refresh: function(component, event, helper){	
        component.set('v.refreshInProgress', true);
        helper.getUpdatedChecklist(component, event, helper);
    },	
})