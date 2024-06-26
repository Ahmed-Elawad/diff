/*
    Attachment Upload Controller (Single)
    Created 5/8/2013 - Justin Stouffer
	10/17/2016 - Updated to allow multiple attachments
*/

public with sharing class AttachmentUploadController {
    public attachment att {get; set;}
    public id parent {get; set;}
    public string savedList {get;set;}
    public string csa {get;set;}
    
    public attachmentUploadController(){
        parent = ApexPages.currentPage().getParameters().get('parent');
        savedList = '';
        savedList += ApexPages.currentPage().getParameters().get('savedList');
        csa = ApexPages.currentPage().getParameters().get('CSA');
        att = new attachment();
    }
    
    public pageReference saveAttachment(){
		insertAttch(); 
        PageReference hmPage = new PageReference('/home/home.jsp');
        if(csa == 'TRUE'){
			hmPage = new PageReference('/'+parent);            
        } 
        hmPage.setRedirect(true);
        return hmPage ; 
    }
    
    public pageReference saveAndAddMore(){
        insertAttch(); 
        PageReference hmPage = new PageReference('/apex/AttachmentUpload?parent=' + parent + '&CSA=' + csa + '&savedList=' + savedList);
        hmPage.setRedirect(true);
        return hmPage ; 
    }
    
    private void insertAttch(){
		If (att.name != '' && att.name != NULL && att.body != NULL && parent != NULL){
            att.parentId = parent;
            insert att;
        } 
        savedList += att.name + ' - Added!\r\n';
    }   
}