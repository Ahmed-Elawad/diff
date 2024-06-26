/** Sales to Service class to send data to UC
* 
* History
* -------
* 07/25/2018   Jermaine Stukes Created
* 11/19/2018   Jermaine Stukes Added Advantage Logic
* 12/29/2018   Jermaine Stukes Updated Web Log and Apex Job Indicator
* 04/17/2019   Jermaine Stukes Update support process
* 11/21/2019   Jermaine Stukes Updated
* 03/26/2020   Jacob Hinds     Adding Product to subject line
* 07/06/2020   Jacob Hinds     Adding in additional skill mapping fields to generateJSON
* 02/04/2020   Michael Karcz  Added functionality to generateJSON() to allow matching on just the Service Model Type
* 01/24/2022   Jermaine Stukes  Updated to requeue failed web service logs
* 03/23/2023   Dan Carmen      New retryList variable and increment the counter on the logs to control the retries.
* 11/13/2023   Reetesh Pandey	Added logic for CER,DSCUn,eIMP, eDSC and updated rev location
* 06/18/2024   Jermaine Stukes	Update to retry query for APR0169813 
*/
public class CaseS2SQueueable  implements Queueable, Database.AllowsCallouts{ 
    //Variables
    public List<UCWrapper> ucWrap = new List<UCWrapper>();
    public List<Web_Service_Log__c> caseListToProcess = new List<Web_Service_Log__c>();
    public List<Web_Service_Log__c> retryList = new List<Web_Service_Log__c>();
    public Boolean successfulSubmission;
    public Id apexJobId;
    public class UCWrapper{
        String jsonString;
        String createByUserName;
        Case s2sKase;
        String caseNumber;
        Integer statusCode;
        String statusMessage;
        Id jobId;
        String guid;
        String logRequest;
        String accountName;
        Boolean retry;
        String ucGuid;
        Boolean invalidSkill;
        Web_Service_Log__c ucLog;
    } 
    //Constructors
    public CaseS2SQueueable(List<Web_Service_Log__c>wsLogList) {
        caseListToProcess = wsLogList;
    }
    
    //Executable methods
    public void launchQueueable(){
        
        if (!caseListToProcess.isEmpty()){
            CaseS2SQueueable newS2Sinstance = new CaseS2SQueueable(caseListToProcess);
            System.enqueueJob(newS2Sinstance);
        }
    } // launchQueueable
    
    public void execute(QueueableContext context){
        apexJobId = context.getJobId();
        processJobs();
        Apex_Batch_Control__c abc = getBatchControl();
        System.debug('execute retryList='+retryList.size());
        // always update the logs going through the process
        DmlHelper.performDML2(caseListToProcess, DmlHelper.DML_UPDATE, 'CaseS2SQueueable', 'execute', 'updateWsLog', true);

        if(!retryList.isEmpty() && abc != null && abc.Active__c && !test.isRunningTest()){
            //Relaunch if necessary
            CaseS2SQueueable newS2Sinstance = new CaseS2SQueueable(retryList);
            System.enqueueJob(newS2Sinstance);
        }
    } // execute
    
    public void processJobs(){
        List<UCWrapper> wrapperProcessList = new List<UCWrapper>();
        List<Web_Service_Log__c> updateLogList = new List<Web_Service_Log__c>();
        createUcWrappers();
        Apex_Batch_Control__c abc = getBatchControl();
        Integer maxAttempts = (abc != null && abc.NbrOfAttempts__c != null ? Integer.valueOf(abc.NbrOfAttempts__c) : 5);
        for(UCWrapper ucw : ucWrap){
            if(ucw.ucLog.NbrAttempts__c < maxAttempts && (ucw.s2sKase.UC_Task_Id__c == null || ucw.ucLog.UC_Retry__c || ucw.invalidSkill)) {
                wrapperProcessList.add(ucw);
            } else if (ucw.ucLog.NbrAttempts__c >= maxAttempts) {
                ucw.ucLog.UcRetryFailed__c = true;
            }
        }
        if(!wrapperProcessList.isEmpty()){
            try{
                createUcCase(wrapperProcessList);
                updateWsLog(wrapperProcessList);
                if(verifyJobStatus(wrapperProcessList)){
                    //Update Case with log information
                    updateCase(wrapperProcessList);
                    //Update Retry list if applicable
                    retryList = [Select Id, UcServiceCaseId__c, Invalid_Skill__c, UC_Retry__c, NbrAttempts__c, Rest_Response__c, UcRetryFailed__c from Web_Service_Log__c 
                                                           where (CreatedDate = TODAY or CreatedDate = YESTERDAY) and UC_Retry__c = true and UcRetryFailed__c != true and Invalid_Skill__c != true limit 10];
                }
                
                sendChatterMessage(wrapperProcessList);
            }
            catch(Exception ex){
                for(UCWrapper unsuccessfulWrapper : wrapperProcessList){
                    Web_Service_Log__c logRec = unsuccessfulWrapper.ucLog;
                    logRec.Rest_Response__c = 'UC Submission Unknown Exception Thrown: '+ex.getMessage()+' Detail: '+ex.getCause()+' line: '+ex.getLineNumber();
                    updateLogList.add(logRec);
                }
            }
            //if(!updateLogList.isEmpty()){
            //    DmlHelper.performDML2(updateLogList, DmlHelper.DML_UPDATE, 'CaseS2SQueueable', 'processJobs', 'updateWsLog', true);
            //}
        } // if(!wrapperProcessList.isEmpty
    } // processJobs
    
    public static Apex_Batch_Control__c getBatchControl() {
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('CaseS2SQueueable');
        return abc;
    } // getBatchControl
    
    private void createUcWrappers(){
        List<Id> kaseIdList = new List<Id>();
        for(Web_Service_Log__c log : caseListToProcess){
            // increment the counter so we know how many times we process a record
            log.NbrAttempts__c = (log.NbrAttempts__c != null ? log.NbrAttempts__c : 0) + 1;
            kaseIdList.add(log.UcServiceCaseId__c);
        }
        Map<Id, Case> caseMap = new Map<Id,Case>([Select Id
                                                  ,Account.name
                                                  ,Account.Paychex_Payroll_Specialist__c
                                                  ,Account.Paychex_Payroll_Specialist__r.Email
                                                  ,Account.Paychex_Payroll_Specialist__r.Phone
                                                  ,Account.TLO_Implementation_Coordinator__c
                                                  ,Account.TLO_Implementation_Coordinator__r.Email
                                                  ,Account.TLO_Implementation_Coordinator__r.Phone
                                                  ,Account.HRO_Implementation_Coordinator__c
                                                  ,Account.HRO_Implementation_Coordinator__r.Email
                                                  ,Account.HRO_Implementation_Coordinator__r.Phone
                                                  ,Account.MMS_AS__c
                                                  ,Account.MMS_AS__r.Email
                                                  ,Account.MMS_AS__r.Phone
                                                  ,Account.MMS_CSR_Name__c
                                                  ,Account.Revenue_Location__c
                                                  ,Account.Service_Model_Type__c
                                                  ,Account.Type
                                                  ,AccountId
                                                  ,Alternate_Contact__r.Name
                                                  ,Branch_Client_ID__c
                                                  ,CaseNumber
                                                  ,Client_ID__c
                                                  ,Contact.Name
                                                  ,Contact.Email
                                                  ,Contact.Phone
                                                  ,CreatedBy.Name
                                                  ,CreatedBy.CommunityNickname
                                                  ,Description
                                                  ,IsEscalated
                                                  ,Issue_Type__c
                                                  ,Priority
                                                  ,Product__c
                                                  ,ProcessNotes__c
                                                  ,Reason_for_escalation__c
                                                  ,RecordType.Name
                                                  ,Revenue_Location__c
                                                  ,Send_Case_to_Service_Now__c
                                                  ,Status
                                                  ,Subject
                                                  ,Type
                                                  ,UC_Task_Id__c
                                                  ,(Select Id, ParentId, Name from Attachments)
                                                  ,(Select ParentId, CommentBody, CreatedBy.Name, CreatedDate,Id from CaseComments )
                                                  ,(Select ContentDocument.Id, ContentDocument.Title, ContentDocument.ContentSize from ContentDocumentLinks)
                                                  from Case where id in :kaseIdList]);
        
        //Map Case to WSL
        for(Web_Service_Log__c log : caseListToProcess){
            Case logCase = caseMap.get(log.UcServiceCaseId__c);
            UCWrapper kaseWrapper = new UCWrapper();
            kaseWrapper.s2sKase = logCase;
            kaseWrapper.caseNumber = logCase.CaseNumber;
            kaseWrapper.accountName = logCase.Account.name;
            kaseWrapper.retry = log.UC_Retry__c;
            kaseWrapper.ucLog = log;
            kaseWrapper.invalidSkill = log.Invalid_Skill__c;
            kaseWrapper.jsonString = generateJSON(logCase, kaseWrapper);
            ucWrap.add(kaseWrapper);
        }
    } // createUcWrappers
    
    //Generate the JSON string to send to UC
    public String generateJSON(Case kase, UCWrapper kaseWrapper){
        System.debug('GENERATE JSON STARTED');
        //Variables
        List<S2S_Skill_Mapping__c> skillAssignmentList = S2S_Skill_Mapping__c.getAll().Values();
        String skill;// = 'Admin Group';
        S2S_Skill_Mapping__c skillMappingMatch;
        String revLocation = String.valueOf(kase.Account.Revenue_Location__c);
        String caseProduct = kase.Product__c;
        Boolean hasPRS = (kase.Account.Paychex_Payroll_Specialist__c != null);
        String serviceModelType = kase.Account.Service_Model_Type__c;
        String assigneeEmail = '';
        String assigneeExtension = '';
        String clientId = '';
        //manual fix for preview clients.  UC needs an 8 digit client number, we are faking it 
        if(String.isNotBlank(kase.Branch_Client_ID__c) && kase.Branch_Client_ID__c.contains('-') && (kase.Branch_Client_Id__c.startsWith('4') || kase.Branch_Client_ID__c.startsWith('04'))){
            clientId = kase.Branch_Client_ID__c.remove('-');
        }
        else{
            clientId = kase.Client_ID__c;
        }
        
        clientId = (String.isNotBlank(clientId)?clientId.leftPad(8,'0'):'');
        String kaseBranch = (String.isNotBlank(kase.Branch_Client_Id__c) && kase.Branch_Client_Id__c.contains('-')?kase.Branch_Client_ID__c.substringBefore('-'):'');
        kaseBranch = (String.isNotBlank(kase.Branch_Client_Id__c)?kaseBranch.leftPad(4, '0'):'');
        List<ContentDocumentLink> caseFiles = kase.ContentDocumentLinks;
        kaseWrapper.createByUserName = kase.CreatedBy.CommunityNickname;
       
        //Update UC Skill based on custom setting
        if(kaseWrapper.invalidSkill){
            skill = 'Admin';
        }        
        else{
            
            Boolean fldMatch = false;
            Boolean productMatch = false;
            Boolean smtMatch = false;            
            for(S2S_Skill_Mapping__c skillMapping : [Select Assign_To_Field__c,Condition1_Field__c,Condition1_Value__c,Id,Name,Payroll_Specialist__c,Product__c,Revenue_Location__c,Service_Model_Type__c,Skill__c from S2S_Skill_Mapping__c where Condition1_Field__c!= '' OR Service_Model_Type__c != ''])
            {
                fldMatch = String.isNotBlank(skillMapping.Condition1_Field__c)? (kase.get(skillMapping.Condition1_Field__c) == skillMapping.Condition1_Value__c): false;
                productMatch = String.isNotBlank(skillMapping.Product__c)?(caseProduct == skillMapping.Product__c):false;
				smtMatch = (String.isNotBlank(skillMapping.Service_Model_Type__c) && serviceModelType == skillMapping.Service_Model_Type__c);                  
                System.debug('Skill >'+skill +'fldMatch>'+fldMatch+'productMatch>'+productMatch+'smtMatch>'+smtMatch);                   
                if(String.isBlank(skill) && fldMatch && productMatch && String.isBlank(skillMapping.Revenue_Location__c)){
                    skill = skillMapping.Skill__c;
                    skillMappingMatch = skillMapping; 
                    if(string.IsNotBlank(skillMapping.Assign_To_Field__c) && (Id)kase.Account.get(skillMapping.Assign_To_Field__c)!=null){
                            String relationshipField = skillMapping.Assign_To_Field__c.replace('__c','__r');
                            //casting to sobject because it could be either a user or contact lookup
                            Sobject assignee = (SObject)kase.Account.getSobject(relationshipField);
                            assigneeEmail = (String)assignee.get('Email');
                            String assigneePhone = (String)assignee.get('Phone');
                            if(String.isNotBlank(assigneePhone) && assigneePhone.contains('ext')){
                                assigneeExtension = assigneePhone.substringAfter('ext').trim();
                            }
                        }
                    break;
                } 
                //CER
                
                if(String.isBlank(skill) && smtMatch && productMatch && String.isBlank(skillMapping.Revenue_Location__c)){
                    skill = skillMapping.Skill__c;
                    skillMappingMatch = skillMapping;
					if(string.IsNotBlank(skillMapping.Assign_To_Field__c) && (Id)kase.Account.get(skillMapping.Assign_To_Field__c)!=null){
                            String relationshipField = skillMapping.Assign_To_Field__c.replace('__c','__r');
                            //casting to sobject because it could be either a user or contact lookup
                            Sobject assignee = (SObject)kase.Account.getSobject(relationshipField);
                            assigneeEmail = (String)assignee.get('Email');
                            String assigneePhone = (String)assignee.get('Phone');
                            if(String.isNotBlank(assigneePhone) && assigneePhone.contains('ext')){
                                assigneeExtension = assigneePhone.substringAfter('ext').trim();
                            }
                        }             
                    break;
                } 
                
            }
            if(String.isBlank(skill)){
                List<String> skillRevLocList = new List<String>();  
                Boolean locationMatch = false;
                Boolean prsMatch = false;
                                
                for(S2S_Skill_Mapping__c skillMapping : [Select Assign_To_Field__c,Condition1_Field__c,Condition1_Value__c,Id,Name,Payroll_Specialist__c,Product__c,Revenue_Location__c,Service_Model_Type__c,Skill__c from S2S_Skill_Mapping__c where Condition1_Field__c = ''])
                {
                    //try to match on the location, product and whether or not prs is listed for each of the custom setting values.
                    skillRevLocList = String.isNotBlank(skillMapping.Revenue_Location__c)? skillMapping.Revenue_Location__c.Split(',') : new List<String>();
                    locationMatch = skillRevLocList.size()>0? skillRevLocList.contains(revLocation): false;
                    productMatch = String.isNotBlank(skillMapping.Product__c)?(caseProduct == skillMapping.Product__c):false;
                    prsMatch =  (hasPRS == skillMapping.Payroll_Specialist__c);
                    smtMatch = (String.isNotBlank(skillMapping.Service_Model_Type__c) && serviceModelType == skillMapping.Service_Model_Type__c);
                    
                    //Check if we've matched location/product/prs OR check if there's a product/service model type matching
                    //APR0149777--Added || (productMatch && caseProduct == 'PEO') condition
                    if((locationMatch && productMatch && prsMatch) || (productMatch && smtMatch)|| (productMatch && caseProduct == 'PEO'))
                    {
                        skill = skillMapping.Skill__c;
                        skillMappingMatch = skillMapping;
                        if(string.IsNotBlank(skillMapping.Assign_To_Field__c) && (Id)kase.Account.get(skillMapping.Assign_To_Field__c)!=null){
                            String relationshipField = skillMapping.Assign_To_Field__c.replace('__c','__r');
                            //casting to sobject because it could be either a user or contact lookup
                            Sobject assignee = (SObject)kase.Account.getSobject(relationshipField);
                            assigneeEmail = (String)assignee.get('Email');
                            String assigneePhone = (String)assignee.get('Phone');
                            if(String.isNotBlank(assigneePhone) && assigneePhone.contains('ext')){
                                assigneeExtension = assigneePhone.substringAfter('ext').trim();
                            }
                        }
                        break;
                    }
                } 
            }
            system.debug('CaseS2SQueueable generateJSON skill:'+skill+' assigneeEmail:'+assigneeEmail);
            //set defaults.  If advantage, use advantage skill.  If not advantage, default to branch and try to assign to payroll specialist
            if(String.isBlank(skill))
            {
                //APR0170877--Commented out --Start 
                //List<String> advantageList = label.S2S_AdvantageList.Split(',');
                //skill = advantageList.contains(kase.Account.Type) ? 'Advantage' : kaseBranch;
                if(String.isNotBlank(kaseBranch)){
                    skill=kaseBranch;
                }
                //APR0170877--Commented out --End 
                if(kase.Account.Paychex_Payroll_Specialist__c != null){
                    assigneeEmail = kase.Account.Paychex_Payroll_Specialist__r.Email;
                    String assigneePhone = kase.Account.Paychex_Payroll_Specialist__r.Phone;
                    if(String.isNotBlank(assigneePhone) && assigneePhone.contains('ext')){
                        assigneeExtension = assigneePhone.substringAfter('ext').trim();
                    }
                }
            }
        }
        
        //Start JSON String
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('data');
        gen.writeStartObject();
        gen.writeStringField('type','interactions');
        gen.writeFieldName('attributes');
        gen.writeStartObject();
        //Add Files
        if(!caseFiles.isEmpty())
        {
            Integer sizeLimit = Integer.valueOf(label.UC_Attachment_Size_Limit);
            gen.writeFieldName('attachments');
            gen.writeStartArray();
            for(ContentDocumentLink file : caseFiles )
            {
                gen.writeStartObject();
                gen.writeStringField('id', file.ContentDocument.Id);
                gen.writeStringField('name', file.ContentDocument.ContentSize < sizeLimit ? file.ContentDocument.Title
                                     :'File too large to download.  Ask case creator to email the following file: '+file.ContentDocument.Title);
                gen.writeEndObject();
            }
            gen.writeEndArray();
        }
        
        if(assigneeEmail != Null)
        {gen.writeStringField('assignee', assigneeEmail);}
        gen.writeStringField('queue', skill);
        gen.writeStringField('externalId', kase.Id);
        gen.writeStringField('createdBy', kase.CreatedBy.Name);
        gen.writeStringField('interactionNumber', kase.CaseNumber);
        gen.writeStringField('issueType', kase.Issue_Type__c);
        gen.writeStringField('summary', kase.Product__c+', '+kase.Subject);
        gen.writeStringField('description', kase.Description);
        gen.writeStringField('priority', kase.Priority);
        gen.writeFieldName('attributesClients');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('contactName', kase.Contact.Name);
        if(kase.Contact.Phone != Null)
        {gen.writeStringField('contactPhone', kase.Contact.Phone);}
        if(kase.Contact.Email != Null)
        {gen.writeStringField('contactEmail', kase.Contact.Email);}
        gen.writeStringField('name', kase.Account.Name);
        gen.writeStringField('branch', kaseBranch);
        gen.writeStringField('clientId', clientId);
        //gen.writeStringField('PayrollAgentId', assigneeExtension);
        gen.writeEndObject();
        gen.writeEndArray();
        if(kase.Alternate_Contact__r.Name != Null)
        {gen.writeStringField('alternateContact', kase.Alternate_Contact__r.Name);}
        gen.writeStringField('systemOfRecord','Salesforce');
        gen.writeStringField('recordType', kase.RecordType.Name);
        gen.writeStringField('product', kase.Product__c);
        //Add Case Comments
        if(!kase.CaseComments.isEmpty())
        {            
            gen.writeFieldName('comments');
            gen.writeStartArray();
            for(CaseComment cc : kase.CaseComments)
            {
                if(cc.CommentBody!=null){
                    //String formattedDate = String.valueOf(cc.CreatedDate)
                    gen.writeStartObject();
                    cc.CommentBody.Remove('|');
                    gen.writeStringField('createdByName', cc.CreatedBy.Name);
                    gen.writeStringField('createdDate', cc.CreatedDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.sss\'Z\''));
                    gen.writeStringField('commentBody', cc.CommentBody);
                    gen.writeEndObject();
                }
            }
            gen.writeEndArray();
        }
        gen.writeEndObject();
        return gen.getAsString();
    }//generateJSON
    
    //Create HTTP Request and send data to UC Endpoint
    public void createUcCase(List<UCWrapper> wrapperList){// kaseWrapper){
        WebServiceSettings__c wss = WebServicesHelper.getWebSvcSetting('S2S_UC_Service');
        for(UCWrapper kaseWrapper : wrapperList){
            //Create GUID for UC
            Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            kaseWrapper.guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
            //Create HTTP Request
            HttpRequest request = new HttpRequest();
            request.setEndpoint(wss.Endpoint__c);
            request.setMethod('POST');
            request.setClientCertificateName(wss.Certificate__c);
            request.setHeader('Content-Type', 'application/vnd.api+json');
            request.setHeader('X-payx-txid', kaseWrapper.guid);
            request.setHeader('X-payx-user-untrusted', kaseWrapper.createByUserName);
            request.setHeader('X-payx-bizpn', 'S2S case escalation');
            request.setHeader('X-payx-cnsmr', 'Salesforce');
            request.setbody(kaseWrapper.jsonString);
            request.setTimeout(Integer.valueOf(wss.Timeout__c));
            Http http = new Http();
            System.debug('kaseWrapper.guid >> '+kaseWrapper.guid+'-kaseWrapper.createByUserName-'+kaseWrapper.createByUserName+'-kaseWrapper.jsonString-'+kaseWrapper.jsonString);
            HTTPResponse response;
            //Send to UC
            try
            {
                if(!test.isRunningTest())
                {
                    response = http.send(request);            
                    kaseWrapper.statusCode = response.getStatusCode();
                    kaseWrapper.statusMessage = response.getBody();
                }
                else
                {
                    kaseWrapper.statusCode = 201;
                    kaseWrapper.statusMessage = 'Created';
                }
                if(kaseWrapper.statusMessage.contains('id'))
                {
                    kaseWrapper.ucGuid = kaseWrapper.statusMessage.substringBetween('"id":"', '","');
                }
            }
            catch(Exception e)
            {
                kaseWrapper.statusCode = 404;
                kaseWrapper.statusMessage = e.getMessage();
            }
            kaseWrapper.logRequest = kaseWrapper.jsonString;           
        }
    }//createUcCase
    public void sendChatterMessage(List<UCWrapper> wrapperList){// kaseWrapper){
        List<Id> userList = new List<Id>();
        for(UCWrapper kaseWrapper : wrapperList){
            String chatterMessage = kaseWrapper.statusCode == 201 ? 'Your case #'+kaseWrapper.caseNumber+' for '+kaseWrapper.accountName+' has been successfully received by upstream.' 
                :!kaseWrapper.statusMessage.contains('SkillAddress is not valid') ? 'Oh no, Salesforce is having an issue communicating with Service.  Support has been notified and is working the issue!  We will continue to automatically resend your request until it is received.  In the event this is an emergency, please reach out to the assigned Payroll Specialist or branch directly.  Case #'+kaseWrapper.caseNumber+' for '+kaseWrapper.accountName
                    :Null;
            //Send only if first try or successfully hit endpoint on retry
            if(chatterMessage!=Null  && (!kaseWrapper.retry || kaseWrapper.statusCode == 201))
            {
                ChatterMentionPost.createChatterMentionPost(kaseWrapper.s2sKase.Id,userList,chatterMessage);
                ChatterMentionPost.checkPostFeedElements();
            }
        }
    }
    
    //Update Web Log
    public void updateWsLog(List<UCWrapper> kaseWrapperList){//UCWrapper kaseWrapper){
        //List<WebServicesHelper.WebServiceWrapper> wsWrapperList = new List<WebServicesHelper.WebServiceWrapper>();
        //Map<String, Web_Service_Log__c> webLogMap = new Map<String, Web_Service_Log__c>();
        List<Web_Service_Log__c> wsLogList = new List<Web_Service_Log__c>();
        FileWrapper[] fileWrapList = new FileWrapper[]{};
            for(UCWrapper kaseWrapper : kaseWrapperList){
                Boolean successful = kaseWrapper.statusCode == 201 ? true : false;
                String errorMessage;
                String LogInfo;
                
                switch on kaseWrapper.statusCode
                {
                    when 201{
                        LogInfo = kaseWrapper.statusMessage;
                    }
                    when 401{
                        if(kaseWrapper.statusMessage.contains('SkillAddress is not valid')){
                            LogInfo = 'SkillAddress is not valid';
                            errorMessage = 'SkillAddress is not valid';
                        }
                        else if(kaseWrapper.statusMessage.contains('UC Submission Unknown Exception Thrown')){
                            LogInfo = 'Unknown Exception during submission: Error Message: '+ kaseWrapper.statusMessage ;
                            errorMessage = 'UC Submission Unknown Exception';
                        }
                        else{
                            LogInfo = 'ABSTRACTION LAYER ISSUE: Error Message: '+ kaseWrapper.statusMessage ;
                            errorMessage = 'Abstraction layer issue';
                        }
                    }
                    when 404{
                        LogInfo = 'APEX Job Failure: '+ kaseWrapper.statusMessage ;
                        errorMessage = 'APEX job failed';
                    }
                    when 500{
                        LogInfo = 'UC TRANSPORT ISSUE: Error Message: '+ kaseWrapper.statusMessage ;
                        errorMessage = 'UC transport issue';
                    }
                }
                if(kaseWrapper.jsonString != null && !kaseWrapper.ucLog.UC_Retry__c){
                    FileWrapper fw = new FileWrapper(new Id[]{kaseWrapper.ucLog.Id}, 'CaseS2SQueueable-JSON Request.txt', 'CaseS2SQueueable-JSON Request.txt', null, Blob.valueOf(kaseWrapper.jsonString));
                    fileWrapList.add(fw);
                }
                
                if(kaseWrapper.ucLog.UC_Retry__c){
                    String updateNote = successful ? '\nSUCCESSFUL RETRY AT: ' : '\nUNSUCCESSFUL RETRY ATTEMPTED AT: ';
                    kaseWrapper.ucLog.UC_Notes__c = updateNote + String.valueOf(DateTime.now());
                    kaseWrapper.ucLog.UcRetryFailed__c = successful ? false : true;
                    kaseWrapper.ucLog.UC_Retry__c = successful ? false : true;
                }
                Web_Service_Log__c ucLog = kaseWrapper.ucLog;
                ucLog.UC_Retry__c = kaseWrapper.statusCode == 201 ? false : true;
                ucLog.UC_Apex_Job_Id__c = apexJobId;
                ucLog.Successful__c = successful;
                ucLog.ErrorMsg__c = errorMessage;
                ucLog.UC_Guid__c = kaseWrapper.guid;
                ucLog.Rest_Response__c = ucLog.Rest_Response__c != null ? ucLog.Rest_Response__c +'\n'+ LogInfo : LogInfo;
                wsLogList.add(ucLog);
            } // for(UCWrapper kaseWrapper
        //DMLHelper.performDML2(wsLogList, DmlHelper.DML_UPDATE, 'CaseS2SQueueable', 'updateWsLog', 'Update Web Service Log', true);
        WebServicesHelper.createLogFile(fileWrapList);
    } // updateWsLog
    
    public void updateCase(List<UCWrapper> kaseWrapperList){
        List<Case> caseList = new List<Case>();
        for(UCWrapper kaseWrapper : kaseWrapperList){
            //Update Case
            Case cs = [Select Id, ProcessNotes__c, UC_Task_Id__c from Case where id =: kaseWrapper.s2sKase.Id];
            cs.ProcessNotes__c  += '\nApex job processed successfully\nWeb Log Id: '+kaseWrapper.ucLog.Id;
            cs.UC_Task_Id__c = kaseWrapper.ucGuid != null ? kaseWrapper.ucGuid : null;
            caseList.add(cs);
        }
        DMLHelper.performDML2(caseList, DmlHelper.DML_UPDATE, 'CaseS2SQueuable', 'createUcCase', 'S2S Update UC Job Indicator', true);
    } // updateCase
    
    public Boolean verifyJobStatus(List<UCWrapper> ucwList){
        Boolean jobRanSuccessfully = true;
        List<AsyncApexJob> jobStatus = [SELECT Id,ExtendedStatus, Status, CompletedDate FROM AsyncApexJob WHERE ID =:apexJobId limit 1];
        if(!jobStatus.isEmpty()){
            if(jobStatus[0].Status == 'Failed' || jobStatus[0].Status == 'Aborted'){
                jobRanSuccessfully = false;
                for(UCWrapper ucw : ucwList){
                    ucw.statusMessage = 'APEX job failed.  Status: '+jobStatus[0].ExtendedStatus;
                    ucw.statusCode = 404;
                }
            }
        }
        return jobRanSuccessfully;
    } // verifyJobStatus
    
    
    //private List<Web_Service_Log__c> updateLogList = new List<Web_Service_Log__c>();
    
    //public String endpoint = label.s2s_UC_Endpoint;
    
} // class CaseS2SQueueable