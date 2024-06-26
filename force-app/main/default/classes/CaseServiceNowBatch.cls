/**
 * Test Case for Service Now integration batch
 *
 * History
 * -------
 * 01/31/2014 Justin Stouffer    Created
   10/25/2016 Dan Carmen         Modified to send the error email to a user id instead of directly to an email address.
   02/15/2017 Justin Stouffer    Modified to create a Web Service Log for troubleshooting issues between SFDC and ServiceNow.
   02/16/2017 Lynn Michels       Added Business_Process__c to the query and body 
   07/11/2017 Lynn Michels		 Added Originator_Email_Address__c to the query and body   
   07/25/2017 Cindy Freeman		 removed 3 Manager fields from message
   06/07/2018 Lynn Michels		 Added Manager_Escalation_Reason__c to the query and body
 *
 */
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
global class CaseServiceNowBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{

global Database.QueryLocator start(Database.BatchableContext BC)
    {
        integer availableCallouts = limits.getLimitCallouts() - limits.getCallouts();
        system.debug('JGS Callouts' + availableCallouts);
        String query = 'Select Id, Assignment_Group__c, Business_Application__c, Business_Critical_Date__c, ';
        query += 'CaseNumber, Description, Employee_ID__c, Impact__c, Originator_Email_Address__c, Manager_Escalation_Comments__c, ';
        query += 'Manager_Escalation_Needed__c, Manager_Escalation_Reason__c, Manager_Escalation_Submitter_Email__c, ';
        query += 'Service_Now_Affected_User__c, Service_Now_Caller__c, Service_Now_Client_ID__c, ';
        query += 'Service_Now_Priority__c, Status, Subject, Urgency__c, Sent_Case_To_Service_Now__c, Business_Process__c ';
        query += 'from Case where LastModifiedDate = TODAY and Send_Case_to_Service_Now__c = TRUE and ';
        query += 'Sent_Case_To_Service_Now__c = FALSE Limit ' + availableCallouts;
     system.debug('query string ' +query);
        return Database.getQueryLocator(query);
    }//start
    
    global void execute(Database.BatchableContext BC, List<case> scope)
    {
        list<case> kasesToUpdateList = new list<case>();
        map<Attachment,Web_Service_Log__c> wslMap = new map<Attachment,Web_Service_Log__c>();
        //list<Messaging.Singleemailmessage> mailToSendList = new list<Messaging.Singleemailmessage>();
        
        String errorMsg = '';

        ServiceNow__c SNCS = ServiceNow__c.getOrgDefaults();                                   
        String username = SNCS.SN_User_Name__c;
        String password = SNCS.SN_User_Password__c;
        String reqEndpoint = SNCS.SN_Endpoint__c;
        Blob headerValue = Blob.valueOf(username + ':' + password);

        for(case kase: scope){
            string description = kase.Description;
            if(description != NULL){
                description = description.replaceAll('%(?![0-9a-fA-F]{2})', '');
                description = description.replaceAll('<', '');
                description = description.replaceAll('>', '');                    
                description = description.replaceAll('\\+', '');
                description = description.replaceAll('\\cK', '\n');
                description = description.replaceAll('&', 'and');
            }
            string subject = kase.subject;
            if(subject != NULL){
                subject = subject.replaceAll('%(?![0-9a-fA-F]{2})', '');
                subject = subject.replaceAll('<', '');
                subject = subject.replaceAll('>', '');
                subject = subject.replaceAll('\\+', '');
                subject = subject.replaceAll('\\cK', '\n');
                subject = subject.replaceAll('&', 'and');
            }
            string mEComments = kase.Manager_Escalation_Comments__c;
            if(mEcomments != NULL){
                mEComments = mEComments.replaceAll('%(?![0-9a-fA-F]{2})', '');
                mEComments = mEComments.replaceAll('<', '');
                mEComments = mEComments.replaceAll('>', '');                      
                mEComments = mEComments.replaceAll('\\+', '');
                mEComments = mEComments.replaceAll('\\cK', '\n');
                mEComments = mEComments.replaceAll('&', 'and');
            }
            string EmployeeID = kase.Employee_ID__c;
            if(EmployeeID != NULL){
                EmployeeID = EmployeeID.replaceAll('%(?![0-9a-fA-F]{2})', '');
                EmployeeID = EmployeeID.replaceAll('<', '');
                EmployeeID = EmployeeID.replaceAll('>', '');                      
                EmployeeID = EmployeeID.replaceAll('\\+', '');
                EmployeeID = EmployeeID.replaceAll('\\cK', '\n');
                EmployeeID = EmployeeID.replaceAll('&', 'and');
            }
                
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            String reqBody = '<?xml version="1.0" encoding="UTF-8"?>\r\n';
            reqBody += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\r\n';
            reqBody += '<soapenv:Body>\r\n';
            reqBody += '<notifications xmlns="http://soap.sforce.com/2005/09/outbound">\r\n';
            reqBody += '<OrganizationId>' + userInfo.getOrganizationId() + '</OrganizationId>\r\n';
            reqBody += '<SessionId xsi:nil="true"/>\r\n';
            reqBody += '<EnterpriseUrl>' + System.URL.getSalesforceBaseURL().toExternalForm() + '/services/Soap/c/28.0</EnterpriseUrl>\r\n';
            reqBody += '<PartnerUrl>' + System.URL.getSalesforceBaseURL().toExternalForm() + '/services/Soap/u/28.0</PartnerUrl>\r\n';
            reqBody += '<Notification>\r\n';
            reqBody += '<sObject xsi:type="sf:Case" xmlns:sf="urn:sobject.enterprise.soap.sforce.com">\r\n';
            reqBody += '<sf:Id>' + kase.Id + '</sf:Id>\r\n';
            reqBody += '<sf:Assignment_Group__c>' + kase.Assignment_Group__c + '</sf:Assignment_Group__c>\r\n';
            reqBody += '<sf:Business_Application__c>' + kase.Business_Application__c + '</sf:Business_Application__c>\r\n';
            reqBody += '<sf:Business_Critical_Date__c>' + kase.Business_Critical_Date__c + '</sf:Business_Critical_Date__c>\r\n';
            reqBody += '<sf:CaseNumber>' + kase.CaseNumber + '</sf:CaseNumber>\r\n';
            reqBody += '<sf:Description>' + description + '</sf:Description>\r\n';
            reqBody += '<sf:Employee_ID__c>' + EmployeeID + '</sf:Employee_ID__c>\r\n';
            reqBody += '<sf:Impact__c>' + kase.Impact__c + '</sf:Impact__c>\r\n';
           //this value no longer used reqBody += '<sf:Manager_Escalation_Comments__c>' + mEComments + '</sf:Manager_Escalation_Comments__c>\r\n';
           // reqBody += '<sf:Manager_Escalation_Needed__c>' + (kase.Manager_Escalation_Needed__c?1:0) + '</sf:Manager_Escalation_Needed__c>\r\n';
            reqBody += '<sf:Manager_Escalation_Needed__c>' + kase.Manager_Escalation_Needed__c + '</sf:Manager_Escalation_Needed__c>\r\n';
            reqBody += '<sf:Manager_Escalation_Reason__c>' + kase.Manager_Escalation_Reason__c + '</sf:Manager_Escalation_Reason__c>\r\n';            
            reqBody += '<sf:Manager_Escalation_Submitter_Email__c>' + kase.Manager_Escalation_Submitter_Email__c + '</sf:Manager_Escalation_Submitter_Email__c>\r\n';            
            //reqBody += '<sf:Originator_Email_Address__c>' + kase.Originator_Email_Address__c + '</sf:Originator_Email_Address__c>\r\n';
            reqBody += '<sf:Service_Now_Affected_User__c>' + kase.Service_Now_Affected_User__c + '</sf:Service_Now_Affected_User__c>\r\n';
            reqBody += '<sf:Service_Now_Caller__c>' + kase.Service_Now_Caller__c + '</sf:Service_Now_Caller__c>\r\n';
            reqBody += '<sf:Service_Now_Client_ID__c>' + kase.Service_Now_Client_ID__c + '</sf:Service_Now_Client_ID__c>\r\n';
            reqBody += '<sf:Status>' + kase.Status + '</sf:Status>\r\n';
            reqBody += '<sf:Subject>' + subject + '</sf:Subject>\r\n';
            reqBody += '<sf:Urgency__c>' + kase.Urgency__c + '</sf:Urgency__c>\r\n';
            reqBody += '<sf:Business_Process__c>' + kase.Business_Process__c + '</sf:Business_Process__c>\r\n';
            reqBody += '</sObject>\r\n';
            reqBody += '</Notification>\r\n';
            reqBody += '</notifications>\r\n';
            reqBody += '</soapenv:Body>\r\n';
            reqBody += '</soapenv:Envelope>\r\n';
            
           //construct an HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(reqEndpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', authorizationHeader);
            req.setHeader('Content-Length', string.valueOf(reqBody.length()));
            req.setHeader('Content-Type', 'text/xml; charset=utf-8');
            req.setHeader('Soapaction', '');//http://www.service-now.com/SFDC_Case/
            req.setHeader('Accept-Encoding', 'gzip');
            req.setHeader('WWW-Authenticate', 'BASIC realm="Service-now"');
            //req.setClientCertificateName('ServiceNow');
            req.setBody(reqBody);
   system.debug('reqBody' + reqBody);          
            //send the request
            Http http = new Http();
            HttpResponse res =  new HttpResponse();
            
            dateTime serviceStart = dateTime.now();
            if (test.isRunningTest()){
                res.setStatusCode(200);
            }
            else{
                res = http.send(req);
            }
            dateTime ServiceEnd = dateTime.now(); 
            
            //check the response
            if (res.getStatusCode() == 200) {
              kase.Sent_Case_To_Service_Now__c = TRUE;
              kasesToUpdateList.add(kase);
            }
            else{
              System.debug('Callout failed: ' + res);
              errorMsg += 'Case '+kase.CaseNumber+' failed: '+res+' \n';
              /*
              Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
              mail.setToAddresses (new String[]{SNCS.SN_Error_Email__c});
              mail.setSubject ('ServiceNow Integration Error');
              mail.setHtmlBody('<body>SalesForce Case - ' + kase.CaseNumber + ' could not be sent to ServiceNow.</body>');
              mailToSendList.add(mail);
              */
            }
            
            Web_Service_Log__c wsl = new Web_Service_Log__c(ServiceName__c='CaseServiceNowBatch',
                                                            SobjName__c='Case',
                                                            successful__c = (res.getStatusCode() == 200),
                                                            action__c = 'Send',
                                                            NamedFunction__c = 'CaseServiceNow',
                                                            Notes__c = 'Case Number: ' + kase.CaseNumber,
                                                            ServiceStart__c = serviceStart,
                                                            ServiceEnd__c = serviceEnd);
            attachment att = new Attachment();
            att.Body =  Blob.valueOf(reqBody);
            att.Name = 'message.txt';
            wslMap.put(att,wsl);
        }
        
        if (String.isNotBlank(errorMsg)) {
           logErrors(errorMsg, SNCS);
        }

        //if (!mailToSendList.isEmpty()){
        //    Messaging.sendEmail(mailToSendList);
        //}
        if (!kasesToUpdateList.isEmpty()){
            update kasesToUpdateList;
        }
        
        if (!wslMap.isEmpty()){
            insert wslMap.values();
            for(attachment att: wslMap.keySet()){
                att.ParentId = wslMap.get(att).id;                
            }
            insert new list<Attachment>(wslMap.keySet());
        }
        
    }//execute
    
   private void logErrors(String errorMsg, ServiceNow__c SNCS) {
      try {
         User errorUser = [Select Id, Email from User where IsActive=true and Email=:SNCS.SN_Error_Email__c limit 1];
         Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
         mail.setTargetObjectId(errorUser.Id);
         mail.setSaveAsActivity(false);
         mail.setSubject ('ServiceNow Integration Error');
         mail.setHtmlBody('<body>'+errorMsg+'</body>');
         Messaging.sendEmail(new Messaging.Singleemailmessage[]{mail});
      } catch (Exception e) {
         // do we need to do anything here?
         errorMsg = ' A User for Email '+SNCS.SN_Error_Email__c+' could not be found for email msg \n'+ errorMsg;
         ErrorLog.logError('CaseServiceNowBatch', 'logErrors', 'Log error due to no email', null, errorMsg, null, null, null, null, null, true);
      }
    } // logErrors
        
    global void finish(Database.BatchableContext BC)
    {
        
        list<case> kaseList = [select id from case 
                               where LastModifiedDate = TODAY 
                               and Send_Case_to_Service_Now__c = 
                               TRUE and Sent_Case_To_Service_Now__c = FALSE Limit 10];
        if (!kaseList.isEmpty()){
            CaseServiceNow.kickOffBatchJob();
        }
    }//finish        
}