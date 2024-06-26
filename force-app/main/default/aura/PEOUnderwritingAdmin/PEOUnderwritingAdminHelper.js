({
	gatherStartingInformation : function(component, event) {
        this.getDiscrepancies(component,event);
    	component.set("v.contentLoaded", true);
    },
    getDiscrepancies : function(component, event) {
        var getChecklists = component.get("c.getAllChecklists");
        let checkLists = [];
        let checkListIdList = [];
        getChecklists.setCallback(this, function(data) {
            if (data.getState() === 'SUCCESS') {
                const checklistReturn = data.getReturnValue();
                checkLists = Object.values(checklistReturn);
                var checklistOptions = [];
                checklistOptions.push({ value: '', label: 'Choose a Prospect...' });
                checkLists.forEach(function(checklist) { 
                    console.log('checklistOptions Length'+checklistOptions.length);
                    if(checklistOptions.length == 1){
                        checklistOptions.push({ value: checklist.Id, label: '(Parent) '+checklist.Prospect_Client__r.Name });
                    }
                    else{
                        checklistOptions.push({ value: checklist.Id, label: checklist.Prospect_Client__r.Name});
                    }
                    checkListIdList.push(checklist.Id);
                });
                if(checklistOptions.length > 0){
                    component.set("v.checklistClientOptions", checklistOptions);
                } 
                if(checklistOptions.length == 2){
                    component.set("v.newDiscChecklistId", checklistOptions[1].value);
                }
                console.log('setting newDiscChecklistId to '+checklistOptions[1].value);
                
                var getDiscs = component.get("c.getAllDiscrepancies");
                getDiscs.setCallback(this, function(data) {
                    console.log('Inside getDiscs callback');
                    if (data.getState() === 'SUCCESS') {
                        var discrepancies = data.getReturnValue();
                        if(discrepancies!=null && discrepancies.length>0){
                            component.set("v.hasDiscrepancies", true);
                            component.set('v.discrepancyColumns', [
                                {label: 'Discrepancy Link', fieldName: 'linkName', type: 'url',
                                 	typeAttributes: {label: { fieldName: 'Discrepancy_ID__c' }, target: '_blank'}},
                                {label: 'PC Name', fieldName: 'Prospect_Client_Name__c', type: 'text',wrapText:true,sortable:true},
                                {label: 'Type', fieldName: 'Discrepancy_Type__c', type: 'text',wrapText:true,sortable:true},
                                {label: 'Sub-Type', fieldName: 'Discrepancy_Sub_Type__c', type: 'text',wrapText:true},
                                {label: 'Follow Up Date', fieldName: 'Follow_Up_Date__c', type: 'date-local'},
                                {label: 'Status', fieldName: 'Status__c', type: 'text',wrapText:true,sortable:true},
                                {label: 'Addtl. Info', fieldName: 'additional_information__c', type: 'text',wrapText:true}
                            ]);
                            discrepancies.forEach(function(discrepancy) {
                                discrepancy.linkName = '/' + discrepancy.Id;
                                discrepancy.CheckBool = false;
                            });
                            
                            component.set("v.discrepancyList", discrepancies);
                        }
                    }
                    else{
                        component.find('notifLib').showToast({
            				"variant": "error",
            				"message": "Unable to query discrepancies.  Please contact an administrator"
        				});      
                    }  
            	});
            	getDiscs.setParams({
                	'checklistIds': checkListIdList
            	});
            
            	$A.enqueueAction(getDiscs);
        	}
            else{
                 component.find('notifLib').showToast({
            			"variant": "error",
            			"message": "Unable to query checklists.  Please contact an administrator"
        				});               
            }                   
        });
        getChecklists.setParams({
            'parentChecklistId': component.get("v.recordId")
        });
        $A.enqueueAction(getChecklists);  
    
        
    },
    sortDiscData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.discrepancyList");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortDiscBy(fieldName, reverse))
        cmp.set("v.discrepancyList", data);
    },
    sortDiscBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    showNewDiscrepancy : function(component, event) {
        component.set("v.newDiscrepancyShow", true);
    },
    callUpdateDiscrepancies : function(component, event) {
        component.set("v.isProcessing",true);
        var updateDiscs = component.get("c.updateDiscrepanciesApex");
        updateDiscs.setCallback(this, function(data) {
            console.log('Inside updateDiscs callback');
            if (data.getState() === 'SUCCESS') {
                var saveSuccess = data.getReturnValue();
                console.log('saveSuccess'+saveSuccess);
                if(saveSuccess){
                    component.set("v.updateDiscrepancy.Status__c",null);
                    component.set("v.updateDiscrepancy.Follow_Up_Date__c",null);
                    component.set("v.updateDiscrepancy.additional_information__c",null);
                    //component.set("v.selectedDiscs",null);
                    component.find('notifLib').showToast({
            			"variant": "success",
            			"message": "Update Success"
        				});
                	this.getDiscrepancies(component,event);
                    this.getDocsFromChecklist(component,event);
                }
                else{
                    component.find('notifLib').showToast({
            			"variant": "error",
            			"message": "Update Failed"
        				});
                }
                component.set("v.isProcessing",false);
            }
        });
        updateDiscs.setParams({
            'updateDisc': component.get("v.updateDiscrepancy"),
            'discsToUpdate': component.get("v.selectedDiscs")
        });
        
        $A.enqueueAction(updateDiscs);
    },
    getDocsFromChecklist : function(component, event) {
        component.set("v.isProcessing",true);
        var getDocs = component.get("c.getDocsApex");
        getDocs.setCallback(this, function(data) {
            if (data.getState() === 'SUCCESS') {
                var docList = data.getReturnValue();
                var completedList = [];
                var discList = [];
                var actionList = [];
                component.set('v.docFileColumns', [
                                {label: 'File Name', fieldName: 'fileUrl', type: 'url',
                                 	typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},
                    			{label: 'Created Date', fieldName: 'CreatedDate', type: 'date-local',initialWidth: 105},
                    			{
                                    label: 'Preview File',
                                    type: 'button',
                                    initialWidth: 120,
                                    typeAttributes: { disabled: false, label: 'Preview', name: 'viewFile', title: 'Click to Preview', iconName: 'utility:preview'}
                                }
                                
                            ]);
                if(docList){
                    docList.forEach(function(doc) { 
                        console.log('status:'+doc.status);
                        if(doc.status && (doc.status == 'Approved' || doc.status == 'Submitted to Clientspace')){
                            doc.class='summary_approved';
                        	completedList.push(doc);
                        }
                        else if(doc.status && (doc.status == 'Send to Clientspace Failed')){
                            doc.class='summary_submit_failed';
                        	completedList.push(doc);
                        }
                        else if(doc.status && (doc.status == 'Discrepancy')){
                            doc.class='summary_discrepancy';
                        	discList.push(doc);
                        }
                        else if(doc.status && (doc.status == 'Submitted by Prospect')){
                            doc.class='summary_normal';
                            actionList.push(doc);
                        }
                        else{
                            doc.status='Not Submitted';
                            doc.class='summary_normal';
                            actionList.push(doc);
                        }
                        if(doc.docLinks){
                            doc.docLinks.forEach(function(docLink) { 
                                docLink.fileUrl = '/lightning/r/ContentDocument/'+docLink.ContentDocumentId+'/view';
                                docLink.Name = docLink.ContentDocument.Title;
                                docLink.CreatedDate = docLink.ContentDocument.CreatedDate;
                                docLink.CheckBool = false;
                            });
                        }
                    });
                    component.set("v.docRecordList",docList);
                	component.set("v.completedDocRecordList",completedList);
                	component.set("v.discDocRecordList",discList);
                	component.set("v.actionableDocRecordList",actionList);
                }//if(docList)
            }//if Success
            else if(data.getState() != 'SUCCESS' || !data.getReturnValue()){
                component.find('notifLib').showToast({
                    "variant": "error",
                    "message": "Unable to find docs"
                });
            }  
            component.set("v.isProcessing",false);
        });
        getDocs.setParams({
            'checklistId': component.get("v.getDocChecklistId")
        });
        $A.enqueueAction(getDocs);                       
    },
    submitToCS: function(component, event, docType) {
        component.set("v.isProcessing",true);
        console.log('submit '+docType);
        //parent will always be the second element in this list
        var parentUWChecklistId = component.get("v.checklistClientOptions")[1].value;
        var submitCall = component.get("c.submitToClientSpace");
        submitCall.setCallback(this, function(data) {
            if (data.getState() === 'SUCCESS') {
        		component.find('notifLib').showToast({
                    "variant": "success",
                    "message": "Doc Submission Process Started.  You will receive an email shortly with results of the transmission."
                });
            }
            else{
                component.find('notifLib').showToast({
                    "variant": "error",
                    //"message": "Unable to start Doc Submission. Please reach out to an admin for assistance or please check NBSC Bypass Discrepancy checkbox on the checklist."
                    "message": "All Discrepancies must be resolved prior to submitting to ClientSpace. If you are getting this alert please check to make sure all discrepancies have been resolved.If you want to bypass discrepancy.Please check NBSC Bypass Discrepancy checkbox."
                });
            }
            component.set("v.isProcessing",false);
        });
        submitCall.setParams({
            'parentChecklistId': parentUWChecklistId,
            'whichDocs':docType
        });
        $A.enqueueAction(submitCall);
    },
    approveDoc: function(component, event, docId) {
        component.set("v.isProcessing",true);
        console.log('approve '+docId);
        var approveCall = component.get("c.approveDocRecord");
        approveCall.setCallback(this, function(data) {
            if (data.getState() === 'SUCCESS') {
        		this.getDocsFromChecklist(component,event);
            }
            else{
                component.find('notifLib').showToast({
                    "variant": "error",
                    "message": "Unable to approve the selected document. Please reach out to an admin for assistance."
                });
            }
            component.set("v.isProcessing",false);
        });
        approveCall.setParams({
            'documentId': docId,
        });
        $A.enqueueAction(approveCall);
    },
    saveFiles : function(component,event){
        component.set("v.isProcessing",true);
    	console.log('saveFiles');
        let filesToSave = component.get("v.selectedFiles");
        let newFileLocation = component.get("v.moveFileNewDoc");
        console.table(filesToSave);  
        var reparentCall = component.get("c.reparentFiles");
        reparentCall.setCallback(this, function(data) {
            if (data.getState() === 'SUCCESS') {
        		this.getDocsFromChecklist(component,event);
                var fileDocResetVal = component.get("v.docRecordList")[0];
                component.set("v.moveFileNewDoc",fileDocResetVal);
                component.set("v.selectedFiles",null);
            }
            else{
                component.find('notifLib').showToast({
                    "variant": "error",
                    "message": "Unable to move the selected files. Please reach out to an admin for assistance."
                });
            }
            component.set("v.isProcessing",false);
        });
        reparentCall.setParams({
            'oldLinks': filesToSave,
            'newParent': newFileLocation
        });
        $A.enqueueAction(reparentCall);
    },
    deleteTheseFiles : function(component,event){
        component.set("v.isProcessing",true);
    	console.log('saveFiles');
        let filesToDelete = component.get("v.selectedFiles");
        console.table(filesToDelete);  
        var fileDeleteCall = component.get("c.deleteFiles");
        fileDeleteCall.setCallback(this, function(data) {
            if (data.getState() === 'SUCCESS') {
        		this.getDocsFromChecklist(component,event);
                component.set("v.moveFileNewDoc","")
            }
            else{
                component.find('notifLib').showToast({
                    "variant": "error",
                    "message": "Unable to delete the selected files. Please reach out to an admin for assistance."
                });
            }
            component.set("v.isProcessing",false);
        });
        fileDeleteCall.setParams({
            'oldLinks': filesToDelete
        });
        $A.enqueueAction(fileDeleteCall);
    }
})