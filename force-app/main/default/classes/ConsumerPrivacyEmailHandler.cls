/*
 * This class will process emails coming in from the Consumer Privacy request form.
 * 
 * 
 *  10/3/2022 Chris Santoro		Created.
 * 	
 * 
 */

global without sharing class ConsumerPrivacyEmailHandler implements Messaging.InboundEmailHandler
{
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        System.debug('Email received');
        
        Id refCPId;
        string body = email.plainTextBody; 
        string subject = email.subject;
        
        if(body != null && subject != null)
        {
            if(subject.contains('Undeliverable'))
            {
                /*
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setReplyTo('cnsantoro@paychex.com');
                message.setBccSender(false); 
                message.setUseSignature(false); 
                message.setSaveAsActivity(false);
                message.subject = 'bounce back received by email service'; 
                message.setHtmlBody('bounce back received by email service - check case 43704817'); 
                message.toAddresses = new String[] { 'cnsantoro@paychex.com' };
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> { message };
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                
                closeCase(); //test */
            }
            else if(subject.contains('Consumer Privacy Request'))
            {
                refCPId = Id.valueOf(body);
                system.debug('ConsumerPrivacyEmailHandler: refCPId: ' + refCPId);
                createCase(refCPId);               
            }
        }
        
        return result;
    }

/*    
    //test to see if bounce back works
    private void closeCase()
    {
        List<Reference_Consumer_Privacy__c> refList = [select Case_Lookup__r.Id from Reference_Consumer_Privacy__c where Email_Address__c = 'chris.n.santoroinvalidemail@gmail.com' ORDER BY CreatedDate DESC LIMIT 1];
        Case c = [select Id, Status from Case where Id = :refList[0].Case_Lookup__c];
        c.Status = 'Closed';
        update c;
        //System.debug(c.Status);
    }
*/    
    private void createCase(Id refCPId) 
    {
        string[] queueNames = new string[]{ Label.Consumer_Privacy_Queue };
        Map<string,Group> queueMap = UserHelper.getQueueMapByName(queueNames);
        string caseQueueName = Label.Consumer_Privacy_Queue;            
        Group queue = queueMap.get(caseQueueName);
        
        system.debug('Case being created.');
        
        Schema.RecordTypeInfo cpRT = RecordTypeHelper.getRecordType('Consumer Privacy', 'Case');
        Case cpCase = new Case(RecordTypeId = cpRT.getRecordTypeId()
                               , OwnerId = queue.Id
                               , Subject = 'Consumer Protection - Client Research Request'
                               , Description = 'Consumer Privacy Request for ' + refCPId
                               , Origin = 'Email'
                               , Priority = 'Medium'
                               , Status = 'New');
        Database.DMLOptions dmo = new Database.DMLOptions();
        Database.SaveResult sr = database.insert(cpCase, dmo);
        if (sr.isSuccess()) 
        {
            system.debug('Case being created.');
            Reference_Consumer_Privacy__c refCP = [SELECT Case_Lookup__c, Email_Address__c, CreatedDate FROM Reference_Consumer_Privacy__c WHERE Id = :refCPId];
            refCP.Case_Lookup__c = sr.getId();            
            update refCP;
            system.debug('ConsumerPrivacyEmailHandler: Ref CP updated with Case Lookup: ' + refCP.Case_Lookup__c);
            sendConfirmationEmail(refCP, refCP.Case_Lookup__c);
        }
        else
        {
            string errorMsg = 'Error Saving Case: ';
            for (Database.Error err : sr.getErrors()) 
            {
                errorMsg += err.getMessage();
            }
            ErrorLog.logError('ConsumerPrivacyController', 'createCase', 'error creating Consumer Privacy case', refCPId, errorMsg);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorMsg));           
        }
    }
    
    private void sendConfirmationEmail(Reference_Consumer_Privacy__c refCP, Id caseId)
    {        
        Case caseObj = [SELECT CaseNumber FROM Case WHERE Id = :caseId];
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setSenderDisplayName('Consumer Privacy'); 
        message.setReplyTo('ccpa@paychex.com');
        message.setBccSender(false); 
        message.setUseSignature(false); 
        message.setSaveAsActivity(false);
        string caseNumber = caseObj.CaseNumber; 
    	string createdDate = refCP.CreatedDate.format('MM/dd/YYYY');
        message.subject = 'Confirming Your CA Privacy Request'; 
        //string body = '<img src="https://paychex--fullsandbx.sandbox.file.force.com/servlet/servlet.FileDownload?file=015700000022qMy"><br/><br/>' +
        string body = 'Hello,<br/><br/>'+
            'We received your request regarding the California Consumer Privacy Act (CCPA) on ' + createdDate + ' and have assigned it Request ID # ' + caseNumber + '. <b>Important Note:</b> Please keep a record of your Request ID number until your request is completed.<br/><br/>' +            
            'We’ll use the personal information you provided in your request to verify your identity. If we’re unable to verify your identity, we’ll notify you.<br/><br/>' +        
            'Otherwise, we’ll review your request and respond within 45 days. If we require more time to respond (up to another 45 days per the CCPA), we will follow-up with you.<br/><br/>' +        
            'As required by the CCPA, we will maintain a record of your request for at least 24 months.<br/><br/>' +         
            'For more information about our data collection and use practices or our processes for California consumers, please see our <a href="https://www.paychex.com/corporate/security/privacy/CCPA">Privacy Policy</a>.<br/><br/>' +           
            'Sincerely,<br/>' +           
            'Your Paychex Team';
        
        message.setHtmlBody(body); 
        message.toAddresses = new String[] { refCP.Email_Address__c };
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> { message };
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        for(integer x = 0;x < results.size();x++)
        {
            Messaging.SendEmailResult result = results[x];
            if (result.isSuccess()) 
            {
                System.debug('The email was sent successfully.');
                refCP.Email_Confirm_Sent__c = true;
                refCP.Email_Confirm_Date__c = DateTime.now();
                update refCP;
            } 
            else 
            {
                System.debug('ConsumerPrivacyEmailHandler: The email failed to send: ' +  results[0].errors[0].message);
                //String bounceerrorMsg = 'bad email';
                // update the error message field to say bad email
                //refCP.Email_Error_Message__c = ('bad email');
                //update refCP;
                //  then update the case status to Close
                //   cpCase.Status = ('Closed');
                //    update cpCase;
            }
        }
    }       
}