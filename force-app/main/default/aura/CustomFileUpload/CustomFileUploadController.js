({
    doInit : function(component, event, helper){
        console.log('customFileUpload uploadTargetId'+component.get('v.uploadTargetId'))
        console.log(component.get('v.checkList'));
        //console.log('isStatusBlank: '+component.get('v.isStatusBlank'));
        let checklist = component.get("v.PEOCheckList");
        console.log('uploadFilesController checklist'+checklist);
        if(checklist && !$A.util.isUndefinedOrNull(checklist.Parent_PEO_Checklist__c)){
            component.set("v.uploadTargetId",checklist.Parent_PEO_Checklist__c);
        }
        else if(checklist){
            component.set("v.uploadTargetId",checklist.Id);
        }
        if(component.get('v.DocumentLabel')==null)
        {
            //component.set('v.DocumentLabel', component.get('v.documentName'));
            console.log('PEO SPA doInit DocLabel check'+component.get('v.documentName'));
            if(component.get('v.documentName') == 'Census Quick quote'){
                component.set('v.DocumentLabel', 'Census');
            }
            else{
               component.set('v.DocumentLabel', component.get('v.documentName')); 
            }
        }
        console.log('uploadFilesController targetId'+component.get("v.uploadTargetId"));
        helper.getPEOOnboardingDocument(component, event);
        component.set("v.knowledgeId");
        helper.getKnowledgeDetailsWrap(component, event, helper);
    },
    
    uploadFinished : function(component, event, helper) {  
        console.log("component.get('v.attachmentParent') = " + component.get('v.attachmentParent'));
        var validity = event.getSource().get("v.validity");
        //console.log('validity:'+validity)
        helper.getUploadedFiles(component, event); 
        console.log('upload finish');
        var toastEvent = $A.get("e.force:showToast");
        // show toast on file uploaded successfully 
        toastEvent.setParams({
            "message": "Files have been uploaded successfully!",
            "type": "success",
            "duration" : 2000
        });
        toastEvent.fire();
        helper.FileActionEvent(component, event, 'Add');
    },
    
    handleSubmit : function(component, event, helper) {
        helper.submitPEODocs(component, event);
    },
    
    deleteSelectedFile : function(component, event, helper){
        if( confirm("Confirm deleting this file?")){
            component.set("v.showSpinner", true); 
             helper.deleteUploadedFile(component, event,helper);                              
        }
    },
    
    handleHelpMe: function(component, event, helper){
        let docuName = component.get(' v.settingName');
        console.log(docuName);
        var getPEOMap = component.get("c.getKnowledgeDetailsWrap");
        getPEOMap.setParams({
            'docName':docuName
        });
        getPEOMap.setCallback(this, function(data) {
            //console.log('hey here',data.getReturnValue());
            console.log(data.getState());
            if(data.getReturnValue() != null 
               && data.getReturnValue()['knowledge']!=null 
               && data.getReturnValue()['knowledge'].length>0
              )
            {
                console.log(data.getReturnValue());
                component.set("v.PEO_Map",data.getReturnValue()['knowledge'][0]);
               
                if(data.getReturnValue()['knowledge'][0].Title==='Census'){
                    component.set('v.downloadORshowme','Download');
                }
                
                component.set("v.contentUrl",data.getReturnValue()['contentUrl']);
                component.set("v.knowledgeId",data.getReturnValue()['knowledge'][0].Id);
                component.set("v.KnowledgeFilesList",data.getReturnValue()['knowledgeFiles'][component.get("v.knowledgeId")]);
                //console.log(docuName);
            }
        });
        $A.enqueueAction(getPEOMap);  
    },
    handleShowMe: function(component, event, helper){
       /* let urllink = '/sfc/servlet.shepherd/document/download';
        var recordId = component.get('v.recordId');
        var KnowledgeId = component.get(' v.PEO_Map').Id;
        var fileids ='';
        for(var i=0; i<component.get("v.KnowledgeFilesList").length; i++){
            fileids += '/'+component.get("v.KnowledgeFilesList")[i];
        }
        urllink+=fileids+'?operationContext=S1';*/
        //http://sfc/servlet.shepherd/document/download/0690q000000dk7aAAA?operationContext=S1
        //let urllink = component.get('v.knowledgeUrl');
        //window.open(urllink,'_blank');
        //window.open('/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&contentId=0690q000000dk7aAAA','_blank'); //?asPDF=true&operationContext=S1
        //console.log(urllink)
        //component.set("v.downloadClick",true);
        var listLength = component.get('v.contentUrls').length;
        if (listLength != 0) {
            for (var i=0; i < listLength; i++) {
              console.log('URL:'+i+'-'+component.get('v.contentUrls')[i].ContentDownloadUrl);
                window.open(component.get('v.contentUrls')[i].ContentDownloadUrl,'_blank');
            }
        }
    },
    resetModal : function(cmp,event,helper){
        cmp.set("v.downloadClick",false);
    },
    filePreviewhandler : function(component, event, helper) {  
        var idFile = event.getSource().get("v.value");
        $A.get('e.lightning:openFiles').fire({
                    recordIds: [idFile]
                }); 
    },
    
    openURL : function(component, event, helper){
        window.open('https://paychex.sharepoint.com/teams/PEOGettingStartedResources/Shared%20Documents/Forms/AllItems.aspx?id=%2Fteams%2FPEOGettingStartedResources%2FShared%20Documents%2FGSP%20and%20Clientspace%20%2D%20Resources%2FGSP%20Quick%20Quote%20Census%20Process%2Epdf&parent=%2Fteams%2FPEOGettingStartedResources%2FShared%20Documents%2FGSP%20and%20Clientspace%20%2D%20Resources', '_blank');
    }
})