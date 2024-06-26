/* Test Class for AttachmentUpload Page
    Created 5/8/2013 Justin Stouffer 
	10/17/2016 - Updated to allow multiple attachments
*/
@isTest
private class AttachmentUploadTest {

    static testMethod void testBasic(){
    
        // Create a case
        case c = new case(Subject='Subject',Description='Description');
        insert c;
        
        // Create AttachmentUpload page and set Parent to case ID
        PageReference pg = Page.AttachmentUpload;
        Test.setCurrentPage(pg);
        pg.getParameters().put('Parent', c.id);

        // Create the controller
        AttachmentUploadController auc = new AttachmentUploadController();
        
        // Create the Test Attachment    
        auc.att.name='Test Attachment';
        auc.att.body=Blob.valueOf('Test Attachment Body');
        
        // Run saveAttachment method
        auc.saveAttachment();

        //Verify attachment parentid is the case id
        System.assertEquals(auc.att.parentid,c.id);
        
          
    }
    
    static testMethod void testAdditional(){
    
        // Create a case
        case c = new case(Subject='Subject',Description='Description');
        insert c;
        
        // Create AttachmentUpload page and set Parent to case ID
        PageReference pg = Page.AttachmentUpload;
        Test.setCurrentPage(pg);
        pg.getParameters().put('Parent', c.id);

        // Create the controller
        AttachmentUploadController auc = new AttachmentUploadController();
        
        // Create the Test Attachment    
        auc.att.name='Test Attachment';
        auc.att.body=Blob.valueOf('Test Attachment Body');
        
        // Run saveAttachment method
        auc.saveAndAddMore();

        //Verify attachment parentid is the case id
        System.assertEquals(auc.att.parentid,c.id);
        
          
    }
    
    
}