/*  
 * Rest service class creates endpoint for UC interaction.  Used to update case records as well as send case data through service.
 * 
 *
 * History
 * -------
 * 06/22/2017 	Jermaine Stukes Created
 * 03/08/2018	Jermaine Stukes	Added logic accounting for leading zeros in the branch-client query
 * 07/23/2018	Jermaine Stukes	refactored code
 * 08/09/2018	Jermaine Stukes	Added File/Attachment logic
 * 08/14/2018	Jermaine Stukes	Added patch method
 * 08/29/2018	Jermaine Stukes	Added web service logging info
 * 10/24/2018	Jermaine Stukes	Shorten Status Description string
 * 12/05/2018	Jermaine Stukes	Add Restricted Phrase logic	
 * 01/22/2019	Jermaine Stukes	Restructured BuildString method	
 * 01/03/2022	Jermaine Stukes	Add file to store case update requests
 */
//custom endpoint: UnifiedCommunications
@RestResource(urlMapping='/UnifiedCommunications/*')
global with sharing class CaseWebService 
{	
    global class ReturnWrapper 
    {
        public Integer TotalCount;
        public List<Case> CaseList;
    }
    
    @HttpGet
    global static void webServiceRequest()
    {
        //Variables
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        RestRequest request = RestContext.request;
        String fileId = request.params.get('fileId');
        //Web service log info
        WebServicesHelper.WebServiceWrapper wsWrapper = new WebServicesHelper.WebServiceWrapper();
        wsWrapper.svcName = 'CaseWebService';

        //Request file or case data
        if(String.isNotBlank(fileId))
        {sendFileToUC(fileId, res, wsWrapper);}
        else
        {sendCaseToUC(request, res, wsWrapper);}             
    }  
    
    @HttpPatch
    global static void updateCaseFields() 
    {
        RestRequest request = RestContext.request;
        RestResponse res = RestContext.response;
        String requestString = request.requestbody.tostring();
        res.addHeader('Content-Type', 'application/json');
        String caseId = request.requestURI.substring(request.requestURI.lastIndexOf('/')+1);
        Web_Service_Log__c wSLog = new Web_Service_Log__c();
        wSLog.ServiceName__c = 'CaseWebService';
        wSLog.UcServiceCaseId__c = caseId;
        wSLog.NamedFunction__c = 'updateCaseFields';
        insert wSLog;
        //Create File to store web service request
        FileWrapper[] fileWrapList = new FileWrapper[]{};
        FileWrapper fw = new FileWrapper(new Id[]{wSLog.Id}, 'Case Update Request.txt', 'Case Update Request.txt', null, Blob.valueOf(requestString));
        fileWrapList.add(fw);
        WebServicesHelper.createLogFile(fileWrapList);

        try{
            Case thisCase = [Select Id, IsClosed, CreatedById, ownerId, Alternate_Contact__c, Alternate_Contact__r.User_Lookup__c, CaseNumber, Account.Name from Case where Id = :caseId];
            String requestLogList;
            
            // Deserialize the JSON string into name-value pairs
            Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
            // Iterate through each parameter field and value
            
            for(String fieldName : params.keySet()) 
            {
                // Set the field and value on the Case sObject
                if(fieldName == 'CaseComments' || test.isRunningTest())
                {
                    String comments = String.valueof(params.get(fieldName));
                    String commentAddOn = ' See Case Comments';
                    //Account for Out of Office chatter issue
                    List<String> restrictList = label.s2s_restricted_list.Split(',');
                    for(String restrictedPhrase : restrictList)
                    {comments = comments.containsIgnoreCase(restrictedPhrase) ? comments.replaceAll(restrictedPhrase, 'out') : comments;}
                    thisCase.put('Status_Description__c', comments.length() > 255 ? comments.substring(0, 235) + commentAddOn : comments);
                    List<CaseComment> commentList = new List<CaseComment>();
                    createMultipleComments(thisCase, commentList, comments);
                    try
                    {
                        insert commentList;
                        requestLogList +='\nCase Comment Created';
                    }
                    catch(exception e)
                    {
                        res.statusCode = 500;
                        res.responseBody =Blob.valueOf('{"message" : "Error: Unhandled exception: '+e.getMessage()+'"}');
                        wSLog.Rest_Response__c += '\nError: Exception on comment insert at line: '+e.getLineNumber()+' Error:'+e.getMessage()+' Cause: '+e.getCause();
                    }           
                }
                else if(fieldName == 'Date_Client_Contacted__c')
                {
                    try
                    {
                        String inputString = String.valueOf(params.get(fieldName));
                        DateTime resultDateTime = DateTime.ValueofGmt(inputString.replace('T', ' ')); 
                        thisCase.put(fieldName, resultDateTime);
                    }
                    catch(exception e)
                    {
                        res.statusCode = 500;
                        res.responseBody =Blob.valueOf('{"message" : "Error: Unhandled exception: '+e.getMessage()+'"}');
                        requestLogList +='\nField Name: '+fieldName+ ' Value: '+String.valueOf(params.get(fieldName));
                        wSLog.Rest_Response__c += '\nError: Exception on date field update at line: '+e.getLineNumber()+' Error:'+e.getMessage()+' Cause: '+e.getCause();
                        
                    }
                }
                else
                {
                    try
                    {
                        thisCase.put(fieldName, params.get(fieldName));
                        requestLogList +='\nField Name: '+fieldName+ '|| Value: '+String.valueOf(params.get(fieldName));
                    }
                    catch(exception e)
                    {
                        res.statusCode = 500;
                        res.responseBody =Blob.valueOf('{"message" : "Error: Unhandled exception: '+e.getMessage()+'"}');
                        requestLogList +='\nField Name: '+fieldName+ ' Value: '+String.valueOf(params.get(fieldName));
                        wSLog.Rest_Response__c += '\nError: Exception on field update at line: '+e.getLineNumber()+' Error:'+e.getMessage()+' Cause: '+e.getCause();
                    }
                }
            }//If comments created, update case
            if(res.statusCode != 500)
            {
                try
                {
                    DMLHelper.performDML2(new Case[]{thisCase}, DmlHelper.DML_UPDATE, 'CaseWebService', 'updateCaseFields', 'Update Case', true);
                    res.statusCode = 201;
                    res.responseBody =Blob.valueOf('{"message" : "Case Updated"}');
                    wSLog.Successful__c = true;
                }
                catch(exception e)
                {
                    res.statusCode = 500;
                    res.responseBody =Blob.valueOf('{"message" : "Error: Unhandled exception: '+e.getMessage()+'"}');
                    wSLog.Successful__c = false;
                    wSLog.Rest_Response__c += '\nError: Exception on case update at line: '+e.getLineNumber()+' Error:'+e.getMessage()+' Cause: '+e.getCause();
                }
            }
            wSLog.JSON_Request__c = requestLogList.removeStart('\n');
            DMLHelper.performDML2(new Web_Service_Log__c[]{wSLog}, DmlHelper.DML_UPDATE, 'CaseWebService', 'updateCaseFields', 'Update Web Service Log', true);
        }
        catch(exception e){
            res.statusCode = 500;
            res.responseBody =Blob.valueOf('{"message" : "Error: Unhandled exception: '+e.getMessage()+'"}');
            wSLog.Successful__c = false;
            wSLog.Rest_Response__c += '\nError: Case Level exception at line: '+e.getLineNumber()+' Error:'+e.getMessage()+' Cause: '+e.getCause();
            DMLHelper.performDML2(new Web_Service_Log__c[]{wSLog}, DmlHelper.DML_UPDATE, 'CaseWebService', 'updateCaseFields', 'Update Web Service Log', true);
        }

    }//updateCaseFields
    
    private static void sendFileToUC(String fileId, RestResponse res, WebServicesHelper.WebServiceWrapper wsWrapper)
    {
        Integer sizeLimit = Integer.valueOf(label.UC_Attachment_Size_Limit);
        String attachType = fileId.startsWith('069') ? 'file' : fileId.startsWith('00P') ? 'attachment' : 'other';
        Blob attachmentBody;
        switch on attachType
        {
            when 'file'  
            {
                List<ContentVersion> fileToSend = [Select ContentSize, VersionData, ContentDocumentId from ContentVersion where ContentDocumentId =: fileId limit 1];
                if(!fileToSend.isEmpty())
                {
                    attachmentBody =  fileToSend[0].VersionData;
                    String afterblob = EncodingUtil.base64Encode(attachmentBody);
                    if(fileToSend[0].ContentSize < sizeLimit )
                    {
                        res.responseBody = Blob.valueOf(JSON.serializePretty(afterblob));
                        res.statusCode = 201;
                        wsWrapper.succes = true;
                        wsWrapper.notes = 'Id of file sent: '+fileToSend[0].ContentDocumentId;
                    }
                    else
                    {
                        res.responseBody =Blob.valueOf('{"message" : "Error: File Size Exceeds Limit"}');
                        res.statusCode = 500; 
                        wsWrapper.succes = false;
                        wsWrapper.errMsg = 'Error: File Size Exceeds Limit';
                    } 
                }
                else
                {
                    res.responseBody = Blob.valueOf('{"message" : "Error: File not found"}');
                    res.statusCode = 404;    
                    wsWrapper.succes = false;
                    wsWrapper.errMsg = 'Error: File not found';
                }
            }
            when 'attachment'
            {
                List<Attachment> attachToSend = [Select Id, Body, BodyLength from Attachment where Id =:fileId limit 1];
                if(!attachToSend.isEmpty())
                {
                    attachmentBody = attachToSend[0].Body;
                    if(attachToSend[0].BodyLength < sizeLimit )
                    {
                        res.responseBody = Blob.valueOf(JSON.serializePretty(attachmentBody));
                        res.statusCode = 201;
                        wsWrapper.succes = true;
                        wsWrapper.notes = 'Id of attachment sent: '+attachToSend[0].Id;
                    }
                    else
                    {
                        res.responseBody = Blob.valueOf('{"message" : "Error: File not found"}');
                        res.statusCode = 404;    
                        wsWrapper.succes = false;
                        wsWrapper.errMsg = 'Error: Attachment Size Exceeded Limit';
                    }  
                }
                else
                {
                    res.responseBody = Blob.valueOf('{"message" : "Error: File not found"}');
                    res.statusCode = 404;   
                    wsWrapper.succes = false;
                    wsWrapper.errMsg = 'Error: Requested attachment not found';
                }
            }
            when else
            {
                res.responseBody = Blob.valueOf('{"message" : "Error: Invalid Request"}');
                res.statusCode = 404;  
                wsWrapper.succes = false;
                wsWrapper.errMsg = 'Error: Invalid Request';
            }           
        }
        wsWrapper.action = 'Send Files to UC';
        wsWrapper.NamedFunction = 'sendFileToUC';
        WebServicesHelper.logServiceCall(wsWrapper);
    }
    private static void sendCaseToUC(RestRequest request, RestResponse res, WebServicesHelper.WebServiceWrapper wsWrapper)
    {
        ReturnWrapper returnList = new ReturnWrapper();
        List<Case> casesToReturn = new List<Case>();
        DateTime dtStartDate = request.params.get('closeDateStart') != Null ? Datetime.valueOfGMT(request.params.get('closeDateStart')+' 00:00:00')
            :request.params.get('rangeStart') != Null ? Datetime.valueOfGMT(request.params.get('rangeStart')+' 00:00:00') : Null;
        DateTime dtEndDate = request.params.get('closeDateEnd') != Null ? Datetime.valueOfGMT(request.params.get('closeDateEnd')+' 23:59:59')
            :request.params.get('rangeEnd') != Null ? Datetime.valueOfGMT(request.params.get('rangeEnd')+' 23:59:59') : Null;
        String pagelimit = (request.params.get('limit') != null ? request.params.get('limit') : '2000');
        String pageoffSet = (request.params.get('offset') != null ? request.params.get('offset') : '0');           
        try
        {
            String casequery = buildString(pagelimit, pageoffSet, request);
            System.debug('CASE QUERY: '+ casequery);
            //NEW QUERY USING STANDARD SET CONTROLLER
            
            ApexPages.StandardSetController selectedController = new ApexPages.StandardSetController(Database.getQueryLocator(casequery));
            
            //SET PAGE SIZE
            Integer pgLimit = integer.valueOf(pagelimit);
            Integer offSetNum = integer.valueOf(pageoffSet);
            //Set controller page size
            selectedController.setPageSize(pgLimit);
            Integer numCasesReturned = selectedController.getResultSize();
            String whereClause = casequery.substringAfter('where');
            returnList.TotalCount = numCasesReturned;
            Integer pgSize = selectedController.getPageSize();
            
            Integer recCount = 0;
            for(Case kase : (List<Case>)selectedController.getRecords())
            {
                recCount++;
                if(recCount > offSetNum && casesToReturn.size() < pgSize)
                {
                    kase.Branch_ID__c = kase.Branch_Client_ID__c != Null ? Decimal.valueOf(kase.Branch_Client_ID__c.substringBefore('-')) : Null;
                    casesToReturn.add(kase);
                }
            }
            returnList.CaseList = casesToReturn;
            
            System.debug('PAGESIZE*****************'+pgSize);
            System.debug('RESULTSIZE*****************'+returnList.TotalCount);
            res.responseBody = Blob.valueOf(JSON.serializePretty(returnList));
            res.statusCode = 201;
            wsWrapper.succes = true;
        }
        catch(Exception e)
        {
            res.statusCode = 500;
            res.responseBody =Blob.valueOf('{"message" : "Error: Unhandled exception: '+e.getMessage()+'"}');
            wsWrapper.succes = false;
            wsWrapper.errMsg = 'Error: Unhandled exception: '+e.getMessage();
        }
        wsWrapper.action = 'Send Cases to UC';
        wsWrapper.NamedFunction = 'sendCaseToUC';
        WebServicesHelper.logServiceCall(wsWrapper);
    }
    private static List<CaseComment> createMultipleComments(Case thisCase, List<CaseComment> commentList, String comments)
    {
        Integer commentSize = comments.length();
        Integer startLength = 0;
        Integer endLength = commentSize > 4000 ? 4000 : commentSize;
        while(commentSize > endLength)
        {
            CaseComment kaseComment = new CaseComment();
            kaseComment.ParentId = thisCase.Id;
            kaseComment.CommentBody = comments.substring(startLength, endLength);
            commentList.add(kaseComment);
            startLength += endLength;
            endLength += 4000;
        }
        CaseComment lastComment = new CaseComment();
        lastComment.ParentId = thisCase.Id;
        lastComment.CommentBody = comments.substring(startLength, comments.length());
        commentList.add(lastComment);
        return commentList;
    }
    //Build case soql statement for sendCaseToUC()
    private static String buildString(String pagelimit, String pageoffSet, RestRequest request)
    {
        //Get parameter options from custom setting
        List<S2S_ViewGadget_Parameters__c> parameterList = S2S_ViewGadget_Parameters__c.getAll().Values();
        String fieldSet = request.params.get('fieldSet');
        String casequery = Null;
        String whereClause;
        //Add Params to map
        Map<String,String> paramsMap = new Map<String,String>();
        for(S2S_ViewGadget_Parameters__c param : parameterList)
        {
            if(!paramsMap.containsKey(param.Name) && request.params.get(param.Name) != null){
                paramsMap.put(param.Name, param.Api_Name__c);
            }
        }
        System.debug('PARAM MAP: '+paramsMap.keySet());
        //Get Branch-Client Number if exists
        String brCltNum = !(paramsMap.containsKey('branchClientNum')) && paramsMap.containsKey('branch') && paramsMap.containsKey('clientNum') ?
          request.params.get('branch') +'-'+ request.params.get('clientNum') : paramsMap.containsKey('branchClientNum') ? request.params.get('branchClientNum') : null;
        //Update Branch-client number
        if(brCltNum != null)
        {	//Remove leading zero's
            while(brCltNum.startsWith('0'))
            {brCltNum = brCltNum.removeStart('0');}
            whereClause = 'Branch_Client_ID__c = \''+brCltNum+'\'';
        }
        String[] ignoreLists = new String[]{'branchClientNum','branch','clientNum','rangeStart','rangeEnd','closeDateStart','closeDateEnd','isClosed'};
        //Add additional criteria to query
		for(String keyName : paramsMap.keySet())
        {
            //Add all except Brclt
            if(!ignoreLists.contains(keyname))
            {
                whereClause = whereClause == null ? paramsMap.get(keyname)+' = \''+request.params.get(keyname)+'\'' : whereClause + 'and '+paramsMap.get(keyname)+' = \''+request.params.get(keyname)+'\'';
            }
            if(keyName == 'isClosed')
            {
                whereClause += 'and '+paramsMap.get(keyname)+' = '+request.params.get(keyname);
            }
        }
        
        //Add ranges if applicable
        if(!paramsMap.containsKey('caseID') && !paramsMap.containsKey('CaseNumber'))
        {
            if(paramsMap.containsKey('rangeStart') && paramsMap.containsKey('rangeEnd'))
            {
                whereClause += ' and '+paramsMap.get('rangeStart')+' >=:dtStartDate and '+paramsMap.get('rangeEnd')+' <=:dtEndDate'; 
            }
            else if(paramsMap.containsKey('closeDateStart') && paramsMap.containsKey('closeDateEnd'))
            {
                whereClause += ' and '+paramsMap.get('closeDateStart')+' >=:dtStartDate and '+paramsMap.get('closeDateEnd')+' <=:dtEndDate'; 
            }
        }
        //Append record type if querying UC agent
        if(paramsMap.containsKey('Assigned_UC_Agent__c'))
        {
            Id recordTypeId = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case').getRecordTypeId();
            whereClause+=' and RecordTypeId = \''+recordTypeId+'\'';
        }
        //Build QueryString
        if(fieldSet!=Null)
        {casequery = 'Select '+fieldSet+' ,(Select ParentId, CommentBody, CreatedBy.Name, CreatedDate,Id from CaseComments ) from Case where '+whereClause+' order by CreatedDate desc limit '+pagelimit+' offset '+pageoffSet;}
        else
        {casequery = 'Select Id, Description,Branch_ID__c,Client_ID__c,CreatedDate,ClosedDate,CreatedBy.Name,Account.Name,Branch_Client_ID__c,Contact.Name, isClosed, CaseNumber,Status, Product__c, Subject, OwnerId, Owner.Name,Assigned_UC_Agent__c, Priority,Initial_Client_Contact_Completed__c,Date_Client_Contacted__c,Status_Description__c,General_Root_Cause__c,Root_Cause_2nd_Level__c,Issue_Type__c,RecordType.Name,(Select ParentId, CommentBody, CreatedBy.Name,CreatedDate,Id from CaseComments ) from Case where '
            +whereClause+' order by CreatedDate desc';}
        System.debug('CASE QUERY: '+ casequery);
        return casequery;
    } 
}