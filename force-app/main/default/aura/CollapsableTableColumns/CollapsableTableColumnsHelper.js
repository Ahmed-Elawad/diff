({
    getDocsFromChecklist : function(component, event) {
        //component.set("v.isProcessing",true);
        //debugger;
        console.log('checklist:');
        console.log(component.get("v.peoChecklist"));
        var getDocs = component.get("c.getDocsApex");
        getDocs.setCallback(this, function(data) {
           // debugger;
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
                /*component.set('v.docFileColumnsProspect', [
                    {label: 'File Name', fieldName: 'Name', type: 'text',
                     typeAttributes: {name: 'viewDoc',label: { fieldName: 'Name' }, target: '_blank'}},
                    {label: 'Created Date', fieldName: 'CreatedDate', type: 'date-local',initialWidth: 105},
                    {
                        label: 'Preview File',
                        type: 'button',
                        initialWidth: 120,
                        typeAttributes: { disabled: false, label: 'Preview', name: 'viewFile', title: 'Click to Preview', iconName: 'utility:preview'}
                    }
                    
                ]);*/
                if(docList){
                    console.log('docList:');
                    console.log(docList);
                    docList.forEach(function(doc) { 
                        console.log('status:'+doc.status);
                        /*if(doc.name == 'HSF Census'){
                            component.set('v.status', doc.status);
                        }*/
                        if(doc.name == 'WC Declarations Page/PEO Current Rate'){
                            doc.name = 'Workersʼ Comp Declaration Page';
                        }
                        else if(doc.name=='Benefit Summary'){
                            doc.name='Benefit Summaries';
                        } 
                         else if(doc.name=='WC Classes and Wages'){
                            doc.name='Workersʼ Comp Classes and Wages';
                        } 
                        
                        else if(doc.name == 'Loss Runs' || doc.name == 'WC Loss Runs'){
                            doc.name = 'Workersʼ Comp Loss Runs';
                        }
                        else if(doc.name == 'WC Rates and Pricing'){
                            doc.name = 'Workers’ Compensation Policy / Pricing';
                        }
                        else if(doc.name == 'Payroll Register'){
                            doc.name = 'Payroll Report';
                        }
                        if(doc.status && (doc.status == 'Approved' || doc.status == 'Submitted to Clientspace')){
                            doc.class='summary_approved';
                        	completedList.push(doc);
                            component.set('v.refreshNeeded', true);
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
                    console.log('docList:');
                    console.log(docList);
                    console.log('completedList:');
                    console.log(completedList);
                    console.log('discList:');
                    console.log(discList);
                    console.log('actionList');
                    console.log(actionList);
                    
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
            'checklistId': component.get('v.checklistId')
        });
        $A.enqueueAction(getDocs);                       
    },
    
    /*submitForHSF : function(component, event, helper) {
        console.log('helper submitForHSF');
        component.set('v.waitingForResp', true);	
        //debugger;
        console.log('Checklist:');
        var peoChecklist = component.get('v.peoChecklist.Id');
        
        console.log(peoChecklist);
        //var createREC = component.get('c.submitForHSF');
        var submitForHSF = component.get("c.submitForHSF");
        submitForHSF.setParams({
            peoOnbChecklist: component.get('v.peoChecklist')
        });
        submitForHSF.setCallback(this, function(res) {
            console.log('submitForHSF response:');
            console.log(res);
            if (res.getState() !== 'SUCCESS') {
                reject({
                    t: 'Error',
                    m: 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty: 'error',
                    broke: false
                });
            }
            helper.getUpdatedChecklist(component, event, helper);
            component.set('v.refreshNeeded', true) 
            //refresh after 15 seconds
            window.setTimeout(
                $A.getCallback(function() {
                    helper.getUpdatedChecklist(component, event, helper);
                    //refresh after 15 seconds
                    window.setTimeout(
                        $A.getCallback(function() {
                            helper.getUpdatedChecklist(component, event, helper)
                            component.set('v.refreshNeeded', true) 
                        }), 15000
                    );
                }), 15000
            );
            console.log('Return value:'+res.getReturnValue());
            if(res.getReturnValue()){
                component.set('v.dispHSFmodal', false);	
                component.set('v.waitingForResp', false);	
                resolve(true);
            }
            else{
                console.log('Error in HSF submission');
            }
            
        })
        
        $A.enqueueAction(submitForHSF);
    },*/
    
    getUpdatedChecklist : function(component, event, helper) {
        //debugger;
        console.log('helper getUpdatedChecklist');
        var chklsts = [];
        var currChklst = component.get('v.peoChecklist');
        chklsts.push(currChklst);
        var getUpdatedChecklist = component.get("c.getUpdatedChecklist");
        getUpdatedChecklist.setParams({
            chkLists: chklsts,
            formName: 'peoOnboardingSummary'
        });
        getUpdatedChecklist.setCallback(this, function(res) {
            console.log('getUpdatedChecklist response:');
            console.log(res);
            if (res.getState() !== 'SUCCESS') {
                reject({
                    t: 'Error',
                    m: 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty: 'error',
                    broke: false
                });
            }
            console.log('Return value:'+res.getReturnValue());
            console.log(res.getReturnValue());
            var retChk = res.getReturnValue();
            console.log('retChk:');
            console.log(retChk);
            /*if(retChk[0].HSF_Submission_Status__c != null && retChk[0].HSF_Submission_Status__c != 'undefined'){
                component.set('v.peoChecklist.HSF_Submission_Status__c',retChk[0].HSF_Submission_Status__c);
            }
            if(retChk[0].HSF_Status_Change_Date__c != null && retChk[0].HSF_Status_Change_Date__c != 'undefined')component.set('v.peoChecklist.HSF_Status_Change_Date__c',retChk[0].HSF_Status_Change_Date__c);
            if(retChk[0].pkzPEOUnderwritingChecklistID__c != null && retChk[0].pkzPEOUnderwritingChecklistID__c != 'undefined')component.set('v.peoChecklist.pkzPEOUnderwritingChecklistID__c',retChk[0].pkzPEOUnderwritingChecklistID__c);
        	if(retChk[0].HSF_Submission_Response__c != null && retChk[0].HSF_Submission_Response__c != 'undefined')component.set('v.peoChecklist.HSF_Submission_Response__c',retChk[0].HSF_Submission_Response__c);*/
        	if(retChk[0].PEO_Checklist_submission_status__c != null && retChk[0].PEO_Checklist_submission_status__c != 'undefined')component.set('v.peoChecklist.PEO_Checklist_submission_status__c',retChk[0].PEO_Checklist_submission_status__c);
            component.set('v.refreshInProgress', false);
        })
        $A.enqueueAction(getUpdatedChecklist);
    },
})