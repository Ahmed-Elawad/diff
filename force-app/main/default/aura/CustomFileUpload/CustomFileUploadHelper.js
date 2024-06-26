({
    
    getPEOOnboardingDocument : function(component, event){
        console.log('component.get("v.accountForUpload.Name") ' + component.get("v.accountForUpload.Name"));
        console.log(component.get("v.documentName"));
        var action = component.get("c.getPEODocument");
        
        console.log('Handling as non parent: ',  component.get('v.accountForUpload.isParent__c'));
        console.log('PEOCheckList:'+component.get("v.PEOCheckList.Id"));
        console.log('documentName:'+component.get("v.documentName"));
        console.log('settingName:'+component.get("v.settingName"));
        console.log('accountForUpload:'+component.get('v.accountForUpload.Id'));
        action.setParams({  
            "recordId": component.get("v.PEOCheckList.Id"),
            "docName" : component.get("v.documentName"),
            "customSettingName" : component.get("v.settingName"),
            accountId: component.get('v.accountForUpload.Id'),
            formName: 'CustomFileUpload.cmp'
        });
      
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){  
                var result = response.getReturnValue();
                console.log("result = "+result);
                component.set("v.attachmentParent",result);
                this.getUploadedFiles(component, event);
                this.getSubmittedFiles(component, event);
            }  
        });  
       	$A.enqueueAction(action);  
    },
    
	getUploadedFiles : function(component, event){
        console.log("Entered getUploadedFiles");
        try{
            var action = component.get("c.getFiles");
            console.log('component.get("v.attachmentParent")='+component.get("v.attachmentParent"));
            action.setParams({  
                "recordId": component.get("v.attachmentParent") 
            });
            
            action.setCallback(this,function(response){  
                var state = response.getState();  
                console.log(response.getError());
                if(state=='SUCCESS'){  
                    var result = response.getReturnValue();
                    console.log('attachedFiles', result);
                    component.set("v.attachedFiles",result);  
                    var filesToUpload = component.get('v.attachedFiles');
                    component.set('v.nmbrOfAttchments',filesToUpload.length);
                }  
            });  
            $A.enqueueAction(action);
        }catch(e) {
            console.log(e);
        }
    },
    
    deleteUploadedFile : function(component, event,helper) {  
        var action = component.get("c.deleteFile");           
        action.setParams({
            "contentDocumentId": event.currentTarget.id,    
            "peoChecklistID": component.get("v.PEOCheckList").Id,
            "settingName": component.get("v.settingName"),
            formName: 'CustomFileUpload.cmp'
        });  
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){  
                this.getUploadedFiles(component);
                component.set("v.showSpinner", false); 
                // show toast on file deleted successfully
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message": "File has been deleted successfully!",
                    "type": "success",
                    "duration" : 2000
                });
                toastEvent.fire();
                helper.FileActionEvent(component, event,'Delete');
            }  
        });  
        $A.enqueueAction(action);  
    },
    
    submitPEODocs : function(component, event){
        var filesToUpload = component.get('v.attachedFiles');
    	if(filesToUpload.length > 0)
    	{
        	var action = component.get("c.saveFiles");
    
    		action.setParams({  
        		"PEOOnboardingDocId": component.get("v.attachmentParent"),
                formName: 'CustomFileUpload.cmp'
    		});
    
    		action.setCallback(this,function(response){
        		var state = response.getState();
        		if(state=='SUCCESS'){  
            		this.getUploadedFiles(component, event);
            		var alreadySubmittedFiles = component.get('v.submittedFiles');
            		var newlySubmittedFiles = component.get('v.attachedFiles');
            		component.set('v.submittedFiles', newlySubmittedFiles.concat(alreadySubmittedFiles));
            
        			var remainingFiles = [];
        			component.set("v.attachedFiles", remainingFiles);
            		var toastEvent = $A.get("e.force:showToast");
            		toastEvent.setParams({
                		"message": "Files have been submitted successfully!",
                		"type": "success",
                		"duration" : 2000
            		});
            		toastEvent.fire();
        		}  
                    
    		});  
    		$A.enqueueAction(action);
    	}
        else {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "message": "No new files have been uploaded. Please attach files, and try submitting again.",
                "type": "warning",
                "duration" : 2000
            });
            toastEvent.fire();
        }
	},
    
    getSubmittedFiles : function(component, event){
        var action = component.get("c.getSubmittedFilesForDoc");
        
        action.setParams({  
            "docId": component.get("v.attachmentParent") 
        });
        
        action.setCallback(this,function(response){  
            var result = response.getReturnValue();
            component.set("v.submittedFiles", result);            
        });  
        
        $A.enqueueAction(action);
    },
    
    getKnowledgeDetailsWrap: function(component, event, helper){
        let docuName = component.get('v.settingName');
        let settingName = component.get('v.settingName');
        var getPEOMap = component.get("c.getKnowledgeDetailsWrap");
        //JDA sfdc-13615
        var isMac = navigator.userAgent.indexOf("Mac") != -1;
        var isWindows = navigator.userAgent.indexOf("Win") != -1;
        console.log('isMac:'+isMac);
        console.log('isWindows:'+isWindows);
        if(isMac && settingName == 'Census'){
            settingName = "Census_Mac";
        }
        getPEOMap.setParams({
            'docName':settingName
        });
        console.log('settingName:'+settingName);
        getPEOMap.setCallback(this, function(data) {
        //    console.log('hey here',JSON.stringify(data.getReturnValue()));
            console.log(data.getState());
            console.log(data.getError());
            console.log('data: ' ,data.getReturnValue());            
            if(data.getReturnValue() != null 
               && data.getReturnValue()['knowledge']!=null 
               && data.getReturnValue()['knowledge'].length>0
              )
            {
                component.set("v.PEO_Map",data.getReturnValue()['knowledge'][0]);
                if(data.getReturnValue()['knowledge'][0].Title==='Census'){
                    console.log('Knowledge article is Census');
                    component.set('v.downloadORshowme','Download');
                    component.set('v.ShowhelpText','Show Me');
                }
                //<!--SFDC-16848-->
                 if(data.getReturnValue()['knowledge'][0].Title==='HSF Census'){
                    component.set('v.downloadORshowme','Download');
                    component.set('v.ShowhelpText','Show Me');
                }
                //<!--SFDC-16848-->
                if(data.getReturnValue()['knowledge'][0].Title==="Workers' Compensation Classes and Wages"){
                    component.set('v.downloadORshowme','Download');
                    component.set('v.ShowhelpText','dontshow');
                }
                if(data.getReturnValue()['knowledge'][0].Title==='WC Rates and Pricing'){
                    component.set('v.downloadORshowme','WCPricingLink');
                }
                component.set("v.knowledgeId",data.getReturnValue()['knowledge'][0].Id);
                console.log("v.knowledgeId:"+component.get("v.knowledgeId"));
                //component.set("v.KnowledgeFilesList",data.getReturnValue()['knowledgeFiles'][component.get("v.knowledgeId")]);
                component.set("v.knowledgeUrl",data.getReturnValue()['knowledgeUrls'][0]);
                //console.log("v.knowledgeUrl:"+component.get("v.knowledgeUrl"));
                //console.log(docuName);
                if (data.getReturnValue()['contentUrl'].length > 0) {
                    component.set('v.showTemplateButton',true);
                    component.set('v.contentUrls',data.getReturnValue()['contentUrl']);
                }
            }
        });
        $A.enqueueAction(getPEOMap); 
    },
    
  	 FileActionEvent : function(component, event, actiontype) {
        var files = component.get("v.attachedFiles");
        var compEvent = component.getEvent("PEOUWCompFileUploadEvent");
        compEvent.setParams({
            "documentName" : component.get("v.TabiconName"),
            "actiontype" : actiontype ,
            "numofattachments" : files.length
        });
        compEvent.fire();
    }
})