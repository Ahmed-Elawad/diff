/*
* HISTORY: NOTE csTableName changes between dev and qa: gen_zPEOOnboardingChecklist in dev, pkzPEOUnderwritingChecklistID in qa
* -------
* 02/10/2021    Jake Hinds    Created
* 4/20/2021   Ahmed Elawad  Added API Search method to retrieve workspace info
* 4/29/2021   Ahmed Elawad  Added dynamic API calls to append documents to proper workspace
* 5/10/2021   Ahmed Elawad  Added API functionality to append multiple files to attachments sidebar for multi file submission
* 5/19/2021   Ahmed Elawad  Added email send to notify user of failed/succesful transmissions & removed some comments
* 6/22/2021   Ahmed Elawad  Added setClassMembersForWorkspace, updateDocsAndChecklist, and setCSDataformInformation
* 01/10/2022  Jake Hinds    Web Service Log
* 02/24/2022  Jake Hinds    Rewrite of States and Code Sync
* 06/30/2022  Jidesh        Added additional fields for States and Code Sync
* 11/03/2022  Josh Cartwright updated logic to convert string to boolean in state code response 
* 11/21/2022  Josh Cartwright updated code to handle inactive codes, we should not insert them, if we already have them, delete them 
* 12/08/2022  Jidesh        Added createHSFrecordInCs,buildHSFJSON methods and updated others as part of the HSF work
* 11/06/2023  Jidesh  		Code updates for CS API change from v1 to v2. For API documentation refer Story SFDC-23156
* 12/11/2023  Jidesh		Code cleaning- Removed unwanted logs and updated addCallToWSL method to remove body from fullBody
* 05/10/2024  Jidesh		Updated addCallToWSL method to remove response body from fullBody only for certain method calls
*/

public without sharing class ClientspaceAPIQueueable implements Queueable,Database.AllowsCallouts {
    public static String CLASS_NAME='AddFileQueueable';
    public String operation;
    public String csTableName;
    public String csFieldName;
    public String rowGUID;
    public String projectId;
    public PEO_Onboarding_Document__c[] docs;
    public Account[] accounts;
    Map<Id,PEO_Onboarding_Document_Map__c> docMapByDocId;
    String parentAccID;
    public String pkzPEOUnderwritingChecklistID;
    public String UWChecklistGuid;
    public String BenUWGuid;
    public String pkzBenefitsUnderwritingID;
    public String RiskUWGuid;
    public String CMGuid;
    public String pkRFPQuestionnaireID;
    public String pkClientMasterID;
    public String CollateralRowGuid;
    public String pkCollateralID;
    public String wrkSpaceId;
    public Web_Service_Log__c wsl;
    public Attachment[] allFiles;
    //HSF variables
    public String hsfRowGuid;
    public String hsfRecordId;
    public Boolean benBatchRecCreated;
    //QuickQuote variables
    public String QQRowGuid;
    public String QQRecordId;
    public Boolean QQbenBatchRecCreated;
    //Api v2 variables
    public String linkGuid;
    public Boolean fileExistInField;
    public String currentDoc;
    
    public ClientspaceAPIQueueable(Account[] p_accounts, PEO_Onboarding_Document__c[] p_docs, String p_operation,String p_csTableName,String p_csFieldName,String p_rowGUID,String p_projectId,Map<Id,PEO_Onboarding_Document_Map__c> p_docMapByDocId,  String parentId, Web_Service_Log__c p_wsl,Attachment[] p_files){
        accounts = p_accounts;
        docs = p_docs;
        operation = p_operation;
        csTableName = p_csTableName;
        rowGUID = p_rowGUID;
        projectID = p_projectID;
        csFieldName = p_csFieldName;
        docMapByDocId = p_docMapByDocId;
        wsl = p_wsl;
        allFiles = p_files;
        parentAccID = parentId; // 0011b00000wbfqaAAA is edge pb test 3 in full: QA. Use for testing
        if (p_docs != null)  checkStorageForDocumentStatuses(p_docs);
    }
    
    public static Apex_Batch_Control__c getBatchControl() {
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
        return abc;
    } // getBatchControl
    
    public void execute(QueueableContext context) {
        System.debug('MGF ClientspaceAPIQueueable execute operation='+operation+ 'docMapByDocId:'+docMapByDocId);
        Boolean initFileSearch = true;
        if(wsl==null){
            wsl = new Web_Service_Log__c(ServiceName__c='ClientspaceAPIQueueable',CalledBy__c=UserInfo.getUserId(),
                                         CalledDt__c=system.now(),ServiceStart__c=system.now(),SobjName__c='Account');
            if(accounts!=null && !accounts.isEmpty()){
                wsl.SobjId__c=accounts[0].Id;
            }
            else if(docs!=null && !docs.isEmpty()){
                wsl.SobjId__c=docs[0].PEO_Onboarding_Checklist__r.prospect_client__r.Id;
            }
            allFiles = new Attachment[]{};
        }
        //Didnt find it using anymore
        /*if(operation == 'Object Describe'){
            dataformDescribeCallout(csTableName);
            docs.remove(0);//don't think this makes sense
        }*/
        
        //This method fetches the workspace info
        //parentAccID passed from ClientSpaceHelper apex class
        if (operation == 'Get projId') {
            System.debug('Inatialize request to get projId:');
            dataformSearchCallout('gen_ClientMaster', 'x_oas_ClientMaster_SFGUID_list', parentAccID);
        }
        
        //For Api v2 in order to decide between File Add/Put we need to do a search in the Begining
        //File search is done by File Find
        //If File find returns blank/Null => No file present in the particular doument bin => Proceed with File Add
        //If a value is returned for File Find => A file already present => Proceed with File Put
        if (operation == 'File find') {
            System.debug('Request to fetch file info for the field provided:');
            System.debug('wrkSpaceId:'+this.wrkSpaceId);
            System.debug('projectID:'+this.projectID);
            fileFindCallout(docs[0]);
            initFileSearch = false;
        }
        
        //If there are multiple files to be transmitted, proceed with File Put
        //Proceed with File Put until the last doc has been sent to CS
        if (operation == 'Additional File Put') {
            System.debug('Request to add additional file into the document bin in CS');
            Boolean hasAdditionalFiles = filePutCallout(docs[0],linkGuid);
            PEO_Onboarding_Document_Map__c docInfo = docMapByDocId.get(docs[0].Id);
            this.currentDoc = (String.isNotBlank(docInfo.Clientspace_Field__c) ? docInfo.Clientspace_Field__c : '');
            if(!hasAdditionalFiles){
                docs.remove(0);
            }
            else{
                System.debug('Has more files');
                operation = 'Additional File Put';
            }
        }
        
        //Per Api v2 if you are sending the first file, proceed with a File Add
        //If the attribute hasAdditionalFiles is true => More than 1 file to be sent and proceed with File Put
        if(operation == 'Doc Post'){
            System.debug('Doc Post projectId:'+projectId);
            Boolean hasAdditionalFiles = FileAddCallout(docs[0],rowGUID,projectId);
            System.debug('If Doc Post: hasAdditionalFiles:-'+hasAdditionalFiles);
            PEO_Onboarding_Document_Map__c docInfo = docMapByDocId.get(docs[0].Id);
            this.currentDoc = (String.isNotBlank(docInfo.Clientspace_Field__c) ? docInfo.Clientspace_Field__c : '');
            if(!hasAdditionalFiles){
                docs.remove(0);
            }
            else{
                //If there are more files proceed with File Put
                System.debug('Doc Post else:Calling Additional File Put');
                operation = 'Additional File Put';
            }
        }
        if(operation == 'State Code Post'){
            getPEOUnderwritingStateAndCodes(accounts[0],rowGUID,projectId);
            accounts.remove(0);
        }
        
        //System.debug('Execute method operation:'+operation+' docs:'+docs+ '  & size:'+docs.size());
        
        //This section takes care of iteration
        //method makes sure that Queueable is chained properly
        //initFileSearch variable can be used to make sure operation is not called twice
        //In this if initFileSearch is checked to make sure File find is not called twice
        if (operation !=  'Get projId' && docs != null && docs.size() > 0 && initFileSearch) {
            System.debug('this.currentDoc:'+this.currentDoc);
            PEO_Onboarding_Document_Map__c docInfoNext = docMapByDocId.get(docs[0].Id);
            String nextDoc = (String.isNotBlank(docInfoNext.Clientspace_Field__c) ? docInfoNext.Clientspace_Field__c : '');
            String nextTable = (String.isNotBlank(docInfoNext.Clientspace_Table__c) ? docInfoNext.Clientspace_Table__c : '');
            System.debug('nextDoc:'+nextDoc);
            System.debug('nextTable:'+nextTable);
            //If the docs within a bin is completed, i.e. Docs within Payroll register is over and you want to start sending Loss runs
            //Do a file find to make sure csTableName and csFieldName is updated accordingly
            //File find ensures that the Next set of files belonging to different bin is mapped correct. 
            //Checking if the next doc and Current doc matches or not
            if(nextDoc != '' && nextDoc != null && currentDoc != null && nextDoc != currentDoc){
                System.debug('execute method: Next doc and Current doc is different and Proceeding with File find');
                operation = 'File find';
            }
            else if(nextTable != null && nextTable != '' && (nextDoc == '' || nextDoc == null)){
                System.debug('execute method: Next doc and Current doc is blank but has a table name and Proceeding with File find');
                operation = 'File find';
            }
            else{
                System.debug('execute method: Not matching the criteria for Next doc find and Post');
            }
            //Setting the parameters for Queueable call
            ClientspaceAPIQueueable caq = new ClientspaceAPIQueueable(accounts,docs,operation,csTableName,csFieldName,rowGUID,projectID,docMapByDocId,parentAccID,wsl,allFiles);
            caq.UWChecklistGuid = this.UWChecklistGuid;
            caq.BenUWGuid = this.BenUWGuid;
            caq.RiskUWGuid = this.RiskUWGuid;
            caq.CMGuid = this.CMGuid;
            caq.CollateralRowGuid = this.CollateralRowGuid;
            caq.pkzPEOUnderwritingChecklistID = this.pkzPEOUnderwritingChecklistID;
            caq.pkzBenefitsUnderwritingID = this.pkzBenefitsUnderwritingID;
            caq.pkRFPQuestionnaireID = this.pkRFPQuestionnaireID;
            caq.pkClientMasterID = this.pkClientMasterID;
            caq.pkCollateralID = this.pkCollateralID;
            caq.documentFileTransmitStatusesMap = this.documentFileTransmitStatusesMap;
            caq.linkGuid = this.linkGuid;
            System.debug('execute method: Before launchQueueable');
            launchQueueable(caq,accounts,docs,operation,csTableName,csFieldName,rowGUID,projectID,docMapByDocId, parentAccID); 
        } else if((operation!='Get projId' && operation!='File find') || Test.isRunningTest()){
            // Not calling emails for GetProjId and File Find because the docs havent started uploading to CS at this point
            System.debug('Done with all calls continue to email test');
            startEmailProcess();
            completeWSL();
        }
    }
    
    public void dataformSearchCallout(String csTableName, String searchName, Id sfAccGuid){
        System.debug('Starting search build...');
        string calloutType = 'POST';
        string endpoint = 'callout:CS_API/next/api/dataform/v2.0/search/'+csTableName+'/'+searchName;
        String body = '{"AccountGuid":"' + sfAccGuid + '"}';
        HttpRequest req = buildRequest(calloutType,endpoint); // builds a http obj. Nothing dynamic except ep & callout
        req.setBody(body);
        System.debug('dataformSearchCallout req:'+req);
        System.debug('Is running a test: '+ Test.isRunningTest());
        Map<Boolean,String> responseMap = sendRequest(req,Test.isRunningTest());
        System.debug('dataformSearchCallout responseMap:'+responseMap);
        Boolean isQuickQuoteCensus = False;
        for(Boolean succeeded : responseMap.keySet()){
            if(succeeded){
                System.debug('Search request succesful ... ');
                // start to desearlaize: get the keysets
                Map<String, Object> keySets = (Map<String, Object>)JSON.deserializeUntyped(responseMap.get(succeeded));
                // retrieves the dataSet & errors if present
                System.debug(keySets.keySet());
                List<Object> data = (List<Object>)keySets.get('Data');
                List<Object> errors = (List<Object>)keySets.get('Errors');
                
                // if errors found debugs them
                // otherwise continues with returned date
                if (errors != null && data == null) {
                    // deserealize and log each error
                    System.debug('Errors retrieving info');
                } else if (data != null) {
                    System.debug('Starting workspace source ...');
                    // sets all the class variables needed to post to each dataform
                    setClassMembersForWorkspace(data);
                    System.debug('dataformSearchCallout Get Proj Id data returned:'+data);
                    //HSF Path: If table name and status matches, create HSF Benefit batch record
                    PEO_Onboarding_Document_Map__c docInfo = docMapByDocId.get(docs[0].Id);
                    //String TableName = docInfo.Clientspace_Table__c;
                    String TableName;
                    //JDA SPA: If the path is Quick quote, update the TableName to create BenBatch
                    if(docs[0].Routing_Name__c == 'Census' && docs[0].PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical' && docs[0].PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp' && wrkSpaceId != null){
                        TableName = 'gen_BenefitsBatch';
                    }
                    else{
                        TableName = docInfo.Clientspace_Table__c;
                    }
                    System.debug('dataformSearchCallout Current doc docs[0]:'+docs[0]);
                    System.debug('dataformSearchCallout TableName:'+TableName);
                    System.debug('dataformSearchCallout wrkSpaceId :'+wrkSpaceId);
                    // PEO Edge SPA: Checks if the Path matches the criteria for Quick quote
                    // If true create a Benefit batch for Quick quote census
                    if(TableName =='gen_BenefitsBatch' && docs[0].PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical' && docs[0].PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp' && wrkSpaceId != null){
                        System.debug('dataformSearchCallout :Matches the criteria for Quick quote');
                        isQuickQuoteCensus = True;
                        createQuickQuoteBenBatchInCs(TableName,'POST',wrkSpaceId);
                    }
                    ClientspaceAPIQueueable caq;
                    //For Quick Quote we dont need to do a file find since there will always be a single file
                    //If Quick quote, proceed directly with File Add
                    //Else do File Find and process accordingly
                    if(isQuickQuoteCensus){
                        caq = new ClientspaceAPIQueueable(accounts, docs, 'Doc Post',null,null,
                                                                                  null, wrkSpaceId,docMapByDocId, parentAccId,wsl,allFiles);
                    }
                    else{
                        caq = new ClientspaceAPIQueueable(accounts, docs, 'File find',null,null,
                                                                                  null, wrkSpaceId,docMapByDocId, parentAccId,wsl,allFiles);
                    }
                    caq.UWChecklistGuid = this.UWChecklistGuid;
                    caq.BenUWGuid = this.BenUWGuid;
                    caq.RiskUWGuid = this.RiskUWGuid;
                    caq.CMGuid = this.CMGuid;
                    caq.CollateralRowGuid = this.CollateralRowGuid;
                    caq.pkzPEOUnderwritingChecklistID = this.pkzPEOUnderwritingChecklistID;
                    caq.pkzBenefitsUnderwritingID = this.pkzBenefitsUnderwritingID;
                    caq.pkRFPQuestionnaireID = this.pkRFPQuestionnaireID;
                    caq.pkClientMasterID = this.pkClientMasterID;
                    caq.pkCollateralID = this.pkCollateralID;
                    caq.documentFileTransmitStatusesMap = this.documentFileTransmitStatusesMap;
                    if (this.hsfRowGuid != null) caq.hsfRowGuid = this.hsfRowGuid;
                    if (this.hsfRecordId != null) caq.hsfRecordId = this.hsfRecordId;
                    if (this.benBatchRecCreated != null) caq.benBatchRecCreated = this.benBatchRecCreated;
                    if (this.QQRowGuid != null) caq.QQRowGuid = this.QQRowGuid;
                    if (this.QQRecordId != null) caq.QQRecordId = this.QQRecordId;
                    if (this.QQbenBatchRecCreated != null) caq.QQbenBatchRecCreated = this.QQbenBatchRecCreated;    
                    if (!Test.isRunningTest()) {
                        System.enqueueJob(caq);   
                    }
                    
                    // If running a test skip launching a new queueable and continue to post call method
                    //if (Test.isRunningTest()) postFileCallout(docs[0], null, wrkSpaceId);
                    //if (Test.isRunningTest()) FileAddCallout(docs[0], null, wrkSpaceId);
                    if (Test.isRunningTest()) fileFindCallout(docs[0]);
                }
            }
            else{
                System.debug('HTTP ERROR ON SEND CHECK LOGS...>>>\n');
                String emailBody = 'Fatal error submitting documents for account: ' + this.docs[0].Prospect_Client_Name__c;
                sendEmail(emailBody,'');
            }
        }
    }
    
    public void getPEOUnderwritingStateAndCodes(Account acc,String rowGUID,String projectId){
        System.debug('MGF ClientspaceAPIQueueable getPEOUnderwritingStateAndCodes');
        string calloutType = 'POST';
        csTableName = 'gen_PricingCompCode';
        string csSearchName = 'x_oas_PricingState_prismapi_list';
        string endpoint = 'callout:CS_API/next/api/dataform/v1.0/search/'+csTableName+'/'+csSearchName;
        
        HttpRequest req = buildRequest(calloutType,endpoint);
        
        String body = '{';
        body += '"AccountGuid":"'+acc.Id+'"';
        body += '}';
        
        req.setBody(body);
        
        Map<Boolean,String> responseMap = sendRequest(req,Test.isRunningTest());
        
        List<PEO_Underwriting_Code__c> codesToUpsert = new List<PEO_Underwriting_Code__c>();
        List<PEO_Underwriting_Code__c> codesToDelete = new List<PEO_Underwriting_Code__c>();
        
        Map<Id, Map<String, PEO_Underwriting_Code__c>> codesByAccountId = new Map<Id, Map<String, PEO_Underwriting_Code__c>>();
        
        for(Boolean success : responseMap.keySet()){
            if(success){
                System.debug('ClientspaceAPIQueueable getPEOUnderwritingStateAndCodes response: '+responseMap.get(success));    
                
                //Parse the JSON
                Map<String, Object> jsonBody = (Map<String, Object>) JSON.deserializeUntyped(responseMap.get(success));
                //For each entry, parse the results and store them in a wrapper object.
                List<Object> stateCodeList = (List<Object>) jsonBody.get('Data');
                List<stateCodeWrapper> stateCodeWrapperList = new List<stateCodeWrapper>();
                
                for(Object o : stateCodeList) {
                    Map<String, Object> stateCode = (Map<String, Object>) o;
                    stateCodeWrapper scw = buildStateCodeWrapperObject(o);
                    if(String.isBlank(scw.sfAccountGUID) && acc.Id != null) {
                        scw.sfAccountGUID = acc.Id;
                    }
                    System.debug('ClientspaceAPIQueueable getPEOUnderwritingStateAndCodes built statecodewrap: '+ scw);
                    stateCodeWrapperList.add(scw);
                }
                PEO_Onboarding_Checklist__c[] checklists = [SELECT Id, Name, Prospect_Client__c, Pull_Clientspace_States_and_Codes__c, 
                                                              (SELECT Id, Name,IsActive__c,Description__c,FICA__c,FICA_Pricing__c,
                                                                 FUTA__c,FUTA_pricing__c,PB_Code_Id__c,PB_State_Id__c,
                                                                 PEO_Underwriting_Checklist__c,Pricing_Batch_Id__c,State_Disability_TDI_DBL_information__c,
                                                                 State_Name__c,SUI__c,SUI_Pricing__c,Workers_Compensation__c,Workers_Comp_Insurance__c,
                                                               AdminPercent__c,CompCodeStatus__c,FullTimeEmployees__c,GrossPayroll__c,PartTimeEmployees__c,PerHead__c,PerUnit__c,Set_up_fee__c,TotalEmployees__c,
                                                               Payroll_Frequency__c,ClientReport__c 
                                                                 FROM PEO_Underwriting_Codes__r ORDER BY Name DESC) 
                                                           FROM PEO_Onboarding_Checklist__c 
                                        WHERE Prospect_Client__c = :acc.Id OR Parent_PEO_Checklist__r.Prospect_Client__c = :acc.Id 
                                                             ORDER BY CreatedDate DESC];
                Map<Id,PEO_Onboarding_Checklist__c> checklistByAccountId = new Map<Id,PEO_Onboarding_Checklist__c>();
                
                for(PEO_Onboarding_Checklist__c checklist:checklists){
                    if(!checklistByAccountId.containsKey(checklist.Prospect_Client__c)){
                        checklistByAccountId.put(checklist.Prospect_Client__c,checklist);
                    }
                    Map<String, PEO_Underwriting_Code__c> codeMap = new Map<String, PEO_Underwriting_Code__c>();
                    for(PEO_Underwriting_Code__c code : checklist.PEO_Underwriting_Codes__r) {
                        codeMap.put(code.PB_Code_Id__c, code);
                    }
                    System.debug('ClientspaceAPIQueueable getPEOUnderwritingStateAndCodes codeMap: '+ codeMap);
                    if(!codeMap.isEmpty()){
                        codesByAccountId.put(checklist.Prospect_Client__c, codeMap);
                    }
                }
                
        System.debug('ClientspaceAPIQueueable getPEOUnderwritingStateAndCodes codesByAccountId: '+ codesByAccountId);                
                for(stateCodeWrapper scw : stateCodeWrapperList) {
                    string codeKey = scw.pricingCompCodeID;
                    System.debug('ClientspaceAPIQueueable getPEOUnderwritingStateAndCodes iterating through wrapper list codeKey: '+ codeKey);
                    if(checklistByAccountId.containsKey(scw.sfAccountGUID)) {
                        PEO_Onboarding_Checklist__c checklist = checklistByAccountId.get(scw.sfAccountGUID);
                        if(checklist!=null) {
                            PEO_Underwriting_Code__c newCode;
                            Map<String, PEO_Underwriting_Code__c> codeByCodeKey;
                            if(checklist!=null){
                                newCode = buildPEOUnderwritingCode(scw);
                                newCode.PEO_Underwriting_Checklist__c=checklist.Id;
                            }
                            if(newCode!=null){
                                if(codesByAccountId !=null && codesByAccountId.containsKey(scw.sfAccountGUID)) {
                                    codeByCodeKey = codesByAccountId.get(scw.sfAccountGUID);
                                    //if we already have some codes in sf but not this code, add the code
                                    if(codeByCodeKey==null || (codeByCodeKey!=null && !codeByCodeKey.containsKey(codeKey))) {
                                        if(newcode.IsActive__c){
                                          codesToUpsert.add(newCode);
                                        }   
                                        System.debug('ClientspaceAPIQueueable getPEOUnderwritingStateAndCodes code is brand new: '+ codeKey);
                                    }
                                    else{
                                        //if we already have this code in sf, need to check if it has been updated
                                        PEO_Underwriting_Code__c existingCode = codeByCodeKey.get(codeKey);
                                        Boolean codeChanged = checkIfCodeChanged(newCode,existingCode);
                                        if(codeChanged){
                                            newCode.Id = existingCode.Id;
                                            if(newCode.IsActive__c){
                                            codesToUpsert.add(newCode);
                                            }
                                            if(!newCode.IsActive__c){
                                                codesToDelete.add(newCode); 
                                            }
                                            System.debug('ClientspaceAPIQueueable getPEOUnderwritingStateAndCodes code is changed: '+ codeKey);
                                        }
                                        else{
                                            System.debug('ClientspaceAPIQueueable getPEOUnderwritingStateAndCodes code is unchanged: '+ codeKey);
                                        }
                                    }
                                }
                                //if we have no codes for the account, add the code
                                else {
                                    codeByCodeKey = new Map<String, PEO_Underwriting_Code__c>();
                                    if(newcode.IsActive__c){
                                      codesToUpsert.add(newCode);
                                    }
                                    System.debug('ClientspaceAPIQueueable getPEOUnderwritingStateAndCodes code is brand new: '+ codeKey);
                                }
                                codeByCodeKey.put(codeKey, newCode);
                                codesByAccountId.put(scw.sfAccountGUID, codeByCodeKey);
                            }//if(newCode!=null
                        }//if(checklist!=null
                    }//if(checklistByAccountId.containsKey(scw.sfAccountGUID
                }//for(stateCodeWrapper scw : stateCodeWrapperList)
                
                if(!codesToUpsert.isEmpty()) {
                    DmlHelper.performDML2(codesToUpsert, DmlHelper.DML_UPSERT, 'ClientspaceAPIQueueable', 'getStatesandCodes', 'Upsert Codes', true);
                }
                if(!codesToDelete.isEmpty()){
                   DmlHelper.performDML2(codesToDelete, DmlHelper.DML_DELETE, 'ClientspaceAPIQueueable', 'getStatesandCodes', 'Delete Codes', true);
                } 
                
                if(checklistByAccountId.containsKey(acc.Id)) {
                    PEO_Onboarding_Checklist__c parentChecklist = checklistByAccountId.get(acc.Id);
                    System.debug('ClientspaceAPIQueueable getPEOUnderwritingStateAndCodes updating parentChecklist: '+ parentChecklist);
                    if(parentChecklist.Pull_Clientspace_States_and_Codes__c) {
                        parentChecklist.Pull_Clientspace_States_and_Codes__c = false;
                        DmlHelper.performDML2(new PEO_Onboarding_Checklist__c[]{parentChecklist}, DmlHelper.DML_UPDATE, 'ClientspaceAPIQueueable', 'getStatesandCodes', 'Updating Checklist', true);
                    }
                }
                
            }//if success
            else{
                system.debug(responseMap.get(success));
            }
        }//for Bool
    }//getPEOUnderwritingStateAndCodes
    
    
    // needs to set the row guid, table name, and field name for the current file
    public void setCSDataformInformation(Peo_Onboarding_Document__c doc) {
        PEO_Onboarding_Document_Map__c docMapping = docMapByDocId.get(doc.Id);
        if(doc.Routing_Name__c == 'Census' && doc.PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical' && doc.PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp'){
            csTableName = 'gen_BenefitsBatch';
        }
        else{
            csTableName = docMapping.Clientspace_Table__c;
        }
        //csTableName = docMapping.Clientspace_Table__c;
        if(doc.Routing_Name__c == 'Census' && doc.PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical' && doc.PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp'){
            csFieldName = 'fuGAIHealthCensus';
        }
        else{
            csFieldName = (String.isNotBlank(docMapping.Clientspace_Field__c) ? docMapping.Clientspace_Field__c : '');
        }
        if (csTableName == 'gen_zBenefitsUnderwriting') { // medical
            this.rowGUID = this.BenUWGuid;
        } 
        
        if (csTableName == 'gen_BenefitsBatch') { // Quick quote medical
            this.rowGUID = this.QQRowGuid;
        }
        
        if (csTableName == 'gen_RFPQuestionnaire') { // Risk 
            this.rowGUID = this.RiskUWGuid;
        }
        if (csTableName == 'gen_ClientMaster') { // CM 
            this.rowGUID = this.CMGuid;
        }
        if (csTableName == null || csTableName == 'gen_Collateral') { // the checklist guid: everything else goes to the checklist
            this.csTableName = 'gen_zpeounderwritingchecklist';// this is 'gen_zpeounderwritingchecklist' in full
            this.rowGUID = this.UWChecklistGuid;
        }
        System.debug('Document table: ' + csTableName + ' Field map: ' + csFieldName);
        System.debug('Guid after set: ' + this.rowGUID);
    }
    
    public Map<Boolean,String> dataformPatchCallout(String csTableName,String recordId,Map<String,String> fieldMap, Integer versionNumber){
        string calloutType = 'PATCH';
        System.debug('Sending patch...');
        //endpoint and authentication are derived from named credential record
        string endpoint = 'callout:CS_API/next/api/dataform/v2.0/'+csTableName+'/'+recordId;
        HttpRequest req = buildRequest(calloutType,endpoint);
        String patchBody = buildPatchJSON(fieldMap, versionNumber);
        //system.debug('patchBody'+patchBody);
        req.setBody(patchBody);
        system.debug('patch request: \n'+req);
        Map<Boolean,String> responseMap = sendRequest(req,Test.isRunningTest());
        return responseMap;
    }
    
    public HttpRequest buildRequest(string calloutType,string endpoint){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(calloutType);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setHeader('Accept', 'application/json');
        //do I need to compress?
        //req.setCompressed(true);
        return req;
    }
    
    public Map<Boolean,String> sendRequest(HttpRequest req,Boolean isRunningTest){
        addCallToWSL(req,req.getBody(),'request',false);
        Http http = new Http();
        HTTPResponse res = new HttpResponse();
        Map<Boolean,String> responseMap = new Map<Boolean,String>();
        String response;
        Integer code;
        if(!isRunningtest){
            System.debug('not running test');
            try{
                res = http.send(req); 
                response = res.getBody();
                code = res.getStatusCode();
                //System.debug('code:'+code+'\nbody: '+response);
                // handle the error codes provided by the CS API
                if (code == 401) {
                    String errResp = '{"Data": [],"Errors":{"Fatal_Error": "Unable to access CS server"}}';
                    this.sendEmails = true;
                    responseMap.put(false, errResp);
                    addCallToWSL(req,'Cannot Reach Server','response',false);
                } else {
                    responseMap.put(true,response); 
                    addCallToWSL(req,response,'response',true);
                }
            }
            catch(System.CalloutException e){ 
                System.debug('Error in HTTPS');
                response = e.getMessage();
                code = res.getStatusCode();
                System.debug('code:'+code+'\nerror: '+response);
                System.debug(res.toString());
                responseMap.put(false,code+' - '+response);
                addCallToWSL(req,response,'response',false);
            }
        }
        else{
            String fakeResponse;
            if (operation == 'Get projId') {
                fakeResponse = '{"Data": [{"RowNum": 1,\n';
                fakeResponse += '"SourceID": "0010q00000ZTEc2AAH",\n';
                fakeResponse += '"ProjectID": 193436,\n';
                fakeResponse += '"LocationId": 589665,\n';
                fakeResponse += '"SFAccountGUID": "null",\n';
                fakeResponse += '"LocationName": "Main"}],\n';
            }
            if (operation == 'Doc Post') {
                fakeResponse = '{"LinkGuid":"0000-0000-000-00",\n';
            }
            if (operation == 'State Code Post') {
                fakeResponse = '{"Data": [{"RowNum": 1,';
                fakeResponse += '"SourceID": "'+accounts[0].Id+'",\n';
                fakeResponse += '"pkPricingBatchID": 10001,\n';
                fakeResponse += '"PricingBatchActive": true,\n';
                fakeResponse += '"FICA": 5.00,\n';
                fakeResponse += '"FUTA": 5.00,\n';
                fakeResponse += '"PBStateActive": true,\n';
                fakeResponse += '"pkPricingBatchStateID": 10002,\n';
                fakeResponse += '"luState": "NY",\n';
                fakeResponse += '"SUTARate": 5.00,\n';
                fakeResponse += '"TDI": null,\n';
                fakeResponse += '"z_SFAccountGUID": null,\n';
                fakeResponse += '"pkPricingCompCodeID": 10004,\n';
                fakeResponse += '"CompCodeActive": true,\n';
                fakeResponse += '"CompCodeStatus": "Active",\n';
                fakeResponse += '"FullTimeEmployees": 10,\n';
                fakeResponse += '"PartTimeEmployees": 5,\n';
                fakeResponse += '"CompCode": "9876",\n';
                fakeResponse += '"CodeTitle": "Test Comp Code Description",\n';
                fakeResponse += '"ClientReport": false,\n';
                fakeResponse += '"EffectiveCompRate": 5.00},';
                fakeResponse += '{"RowNum": 1,\n';
                fakeResponse += '"SourceID": "'+accounts[0].Id+'",\n';
                fakeResponse += '"pkPricingBatchID": 10001,\n';
                fakeResponse += '"luBatchStatus": "Active",\n';
                fakeResponse += '"FICA": 5.00,\n';
                fakeResponse += '"FUTA": 5.00,\n';
                fakeResponse += '"PricingBatchActive": true,\n';
                fakeResponse += '"pkPricingBatchStateID": 10003,\n';
                fakeResponse += '"luState": "FL",\n';
                fakeResponse += '"SUTARate": 5.00,\n';
                fakeResponse += '"TDI": 5.00,\n';
                fakeResponse += '"z_SFAccountGUID": null,\n';
                fakeResponse += '"pkPricingCompCodeID": 10005,\n';
                fakeResponse += '"CompCodeActive": false,\n';
                fakeResponse += '"CompCodeStatus": "Active",\n';
                fakeResponse += '"FullTimeEmployees": 10,\n';
                fakeResponse += '"PartTimeEmployees": 5,\n';
                fakeResponse += '"CompCode": "8675",\n';
                fakeResponse += '"CodeTitle": "Test Comp Code Description",\n';
                fakeResponse += '"PBStateActive": false,\n';
                fakeResponse += '"WCPremium": 4.00,\n'; 
                fakeResponse += '"GrossPayroll": 1234,\n';
                fakeResponse += '"ClientReport": false,\n';
                fakeResponse += '"EffectiveCompRate": 5.00}],\n';
               // fakeResponse += '"ClientReport": false}],\n';
            }
            fakeResponse += '"Errors":[]}';
            responseMap.put(true,fakeResponse);
        }
        
        return responseMap;
    }
    
    public String buildFileJSON(String fileName,String rowGUID, String workspaceID, String tableName, 
                                string csFieldName, Integer contentLength, String mimeType,
                                String category, String description, string[] metaTags,
                                String versionBatch, Integer docType, Integer version, blob content, PEO_Onboarding_Document__c doc)
    {   
        System.debug('Attempted workspace ID: ' + workspaceID);
        String body = '{"FileName":"'+fileName+'",\n';
        body += '"EntityRowGUID":"'+rowGUID+'",\n';
        body += '"WorkspaceID":"'+workspaceID+'",\n';
        body += '"TableName":"'+tableName+'",\n';
        // if the document looks up to a parent leave the fieldname blank otherwise populate the field name
        // need to include the version in this setup
        // if the file is of version > 1 the field name is blank so that all files
        // for multiple uploads attatch to the sidebar
        
        // if the parent account field is blank then we are either on a child
        // or a parent for the current account:
        Boolean docAccountSalesParentIsntEmpty = docs[0].PEO_Onboarding_Checklist__r.prospect_Client__r.salesParent__c != null;
        Boolean docAccountIsAChild = !docs[0].PEO_Onboarding_Checklist__r.prospect_Client__r.isParent__c && docAccountSalesParentIsntEmpty;
        Id docsParentAccountId = (docAccountIsAChild ? docs[0].PEO_Onboarding_Checklist__r.prospect_Client__r.salesParent__c : null);
        Boolean docIsSingleId = false;
        // if the account isnot a child and it's not a parent assign the single id to the prospect lookup id
        if (!docAccountIsAChild && docsParentAccountId == null) docIsSingleId = true;
        
        Boolean isParent = docs[0].PEO_Onboarding_Checklist__r.prospect_Client__r.isParent__c;
        Boolean isSingleId = !isParent && !docs[0].PEO_Onboarding_Checklist__r.prospect_Client__r.isChild__c;
        Boolean isClientAddOn = docs[0].PEO_Onboarding_Checklist__r.Client_Add_on__c;
        if ((isParent || docIsSingleId || isClientAddOn) && version <= 1) {
            body += '"FieldName":"'+ csFieldName+'",\n';    
        }
        else if ((isParent || docIsSingleId || isClientAddOn) && (version > 1 && docs[0].Routing_Name__c == Label.HSF_Routing_Name)) {
            body += '"FieldName":"'+ csFieldName+'",\n'; 
        }
        else {
            body += '"FieldName":"",\n';
        }
        body += '"ContentLength":'+contentLength+',\n';
        body += '"ContentType":"'+mimeType+'",\n';
        body += '"Category":"'+category+'",\n';
        body += '"Description":"'+description+'",\n';
        body += '"MetaTags":[';
        for(String tag:metaTags){
            body += '"'+tag+'",';                                   
        }
        body = body.removeEnd(',');
        body += '],\n';                     
        //body += '"VersionBatch":"'+versionBatch+'",\n';
        body += '"Type":'+docType+',\n';
        // body += '"Version":' +version+ ',\n';
        try {
          body += '"Content":"'+EncodingUtil.base64Encode(content)+'"}';    
        } catch (System.StringException err) {
            String errMsg = err.getMessage();
            if (errMsg.contains('String length exceeds maximum')) {
                String[] filesTooLargeToEncode = documentFileTransmitStatusesMap.get(doc.PEO_Onboarding_Checklist__c).get(doc.id).get('sizeError');
                filesTooLargeToEncode.add(fileName);
                return null;
            }
        }
        //System.debug(body);
        return body;
    }//buildFileJSON
    
    
    public String buildPatchJSON(Map<String,String>fieldMap, Integer version){
        
        String body = '{';
        for(String csFieldName : fieldMap.keySet()){
            Boolean docAccountSalesParentIsntEmpty = docs[0].PEO_Onboarding_Checklist__r.prospect_Client__r.salesParent__c != null;
            Boolean docAccountIsAChild = !docs[0].PEO_Onboarding_Checklist__r.prospect_Client__r.isParent__c && docAccountSalesParentIsntEmpty;
            Id docsParentAccountId = (docAccountIsAChild ? docs[0].PEO_Onboarding_Checklist__r.prospect_Client__r.salesParent__c : null);
            Boolean docIsSingleId = false;
            // if the account isnot a child and it's not a parent assign the single id to the prospect lookup id
            if (!docAccountIsAChild && docsParentAccountId == null) docIsSingleId = true;
            
            Boolean isParent = docs[0].PEO_Onboarding_Checklist__r.prospect_Client__r.isParent__c;
            Boolean isSingleId = !isParent && !docs[0].PEO_Onboarding_Checklist__r.prospect_Client__r.isChild__c;
            Boolean isClientAddOn = !isParent && docs[0].PEO_Onboarding_Checklist__r.Client_Add_on__c;
            String value = fieldMap.get(csFieldName);
            if (isParent || docIsSingleId || isClientAddOn) {
                body +='"'+csFieldName+'":"'+value+'",\n';
            }
            /*else if ((isParent || docIsSingleId || isClientAddOn) && (version > 1 && docs[0].Routing_Name__c == Label.HSF_Routing_Name)) {
                body +='"'+csFieldName+'":"'+value+'",\n';
            }*/
            else {
                body +='"":"'+value+'",\n';
            }
            
        }
        body = body.removeEnd(',\n');
        body += '}';
        return body;
    }//buildPatchJSON
    
    public static void launchQueueable(ClientspaceAPIQueueable job, Account[] p_accounts, PEO_Onboarding_Document__c[] p_docs, String p_operation,String p_csTableName,String p_csFieldName,String p_rowGUID,String p_projectId,Map<Id,PEO_Onboarding_Document_Map__c> p_docMapByDocId, String parentAccID ) {
        Apex_Batch_Control__c abc = getBatchControl();
        // enqueue this back up if there are more records to process and we're not running a test
        if (!Test.isRunningTest()) {
            if(p_docs != null && !p_docs.isEmpty() && p_operation == 'Object Describe')
            {
                // re-enqueue the job - can't chain the jobs from tests
                System.enqueueJob(job);
            }
            if(p_docs != null && !p_docs.isEmpty() && p_operation == 'Doc Post') {
                System.debug('Posting new J. O. B>');
                System.enqueueJob(job);
            }
            if(p_docs != null && !p_docs.isEmpty() && p_operation == 'Additional File Put') {
                System.debug('Posting new J. O. B> for Additional File Put');
                System.enqueueJob(job);
            }
            if(p_docs != null && !p_docs.isEmpty() && p_operation == 'File find') {
                System.debug('Posting new J. O. B> for '+p_operation);
                System.enqueueJob(job);
            }
            if(p_accounts != null && !p_accounts.isEmpty() && p_operation == 'State Code Post')
            {
                // re-enqueue the job - can't chain the jobs from tests
                System.enqueueJob(job);
            }
            
        }
    } // launchQueueable
    
    // If the patch response contains a succesful state and all documents have been submitted for this PEO_Onboarding_Document__c
    // record update the status to a fail or success state. Then, if there are no more documents to be sent reset the 
    // submit docs to Clientspace field on the checklist to show a blank value:
    // NOTE: The checklist update may need to be delayed until all documents have been sent? As of now once the first document
    // succeeds then the checklist will be updated.
    public void updateDocsAndChecklist(Boolean hasAdditionalFiles, Map<Boolean,String> patchResponseMap, PEO_Onboarding_Document__c doc, ContentDocument cd) {
        System.debug('JDA updateDocsAndChecklist');
        System.debug('JDA doc.Status__c:'+doc.Status__c);
        PEO_Onboarding_Document__c[] docsToUpdate = new PEO_Onboarding_Document__c[]{};
            
            if(patchResponseMap!=null && patchResponseMap.get(true)!=null && !hasAdditionalFiles && doc.Status__c != 'Send to Clientspace Failed'){
                System.debug('Send succesful. Updating doc status...');
                // update the Date_Sent_To_Clientspace__c 
                // if all submission succeed ONLY
                Map<String, String[]> docStatusMapping = documentFileTransmitStatusesMap.get(doc.PEO_Onboarding_Checklist__c).get(doc.Id);
                System.debug('docStatusMapping:'+docStatusMapping);
                if (docStatusMapping != null && docStatusMapping.get('Failures').isEmpty() && !docStatusMapping.get('Successes').isEmpty()) {
                    doc.Date_Sent_To_Clientspace__c = DateTime.now();
                }
                
                doc.Status__c='Submitted to Clientspace';
                docsToUpdate.add(doc);
                //clear the submit doc to clientspace field when all docs are done
            } else if(patchResponseMap!=null && patchResponseMap.get(false)!=null){
                doc.Status__c='Send to Clientspace Failed';
                docsToUpdate.add(doc);
            }
        
        if(docsToUpdate!=null){
            DmlHelper.performDML2(docsToUpdate, DmlHelper.DML_UPDATE, 'ClientspaceAPIQueuable', 'postFileCallout', 'Updating Doc Status', true);
        }  
        if(cd != null && cd.Id != null){
            update cd;
        }
        if(!hasAdditionalFiles){
            system.debug('updating checklist since there are no more docs...');
            System.debug('updateDocsAndChecklist-Doc sent to CS:'+doc);
            PEO_Onboarding_Checklist__c checkListToUpdate = new PEO_Onboarding_Checklist__c(Id = doc.PEO_Onboarding_Checklist__c,Submit_Docs_to_Clientspace__c='');
            if (doc.PEO_Onboarding_Checklist__r.Sent_to_ClientSpace_Status_Date__c == null) {
                checkListToUpdate.Sent_to_ClientSpace_Status_Date__c = system.now();
                checkListToUpdate.Current_Step__c = 'Sent to ClientSpace';
            }
            if (doc.Date_Sent_to_Clientspace__c != null && doc.Routing_Name__c == 'Census' && doc.PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical' && projectId != null) {
                //if(doc.Routing_Name__c == 'Census' && doc.PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical' && doc.PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp'&& projectId != null){
                //checkListToUpdate.HSF_Census_Submit_Date__c = System.now();
                checkListToUpdate.HSF_Submission_Status__c = 'Sent to ClientSpace';
            }
            DmlHelper.performDML2(new List<PEO_Onboarding_Checklist__c>{checkListToUpdate}, DmlHelper.DML_UPDATE, 'ClientspaceAPIQueuable', 'postFileCallout', 'Updating checklist Status', true);
        }
    }
    
    public void addCallToWSL(HttpRequest request,String body,String requestOrResponse,Boolean successful){
        system.debug('ClientspaceAPIQueueable addCallToWSL wsl'+wsl);
        if(wsl!=null){
            wsl.Successful__c = successful;
            Attachment file = new Attachment();
            file.Name = operation+'-'+request.getMethod()+'-'+requestOrResponse;
            file.ContentType = 'text/plain';
            String fullBody;
            if(operation == 'Additional File Put' || operation == 'Doc Post'){
                if(body != null){
                    fullBody = request.getEndpoint()+'\n'+request.getMethod()+'\n File body is not empty, but omitted for this operation since it exceeds heap size';
                }
                else{
                    fullBody = request.getEndpoint()+'\n'+request.getMethod()+'\n File body is null';
                }
            }
            else{
                fullBody = request.getEndpoint()+'\n'+request.getMethod()+'\n'+body;
            }
            file.Body = Blob.valueOf(fullBody);
            allFiles.add(file);
        }
    }
    
    public void completeWSL(){
        system.debug('ClientspaceAPIQueueable completeWSL wsl'+wsl);
        if(wsl!=null){
            wsl.ServiceEnd__c = system.now();
            //take the last operation because it will likely be the most specific name
            wsl.NamedFunction__c=operation;
            DmlHelper.performDML2(new List<Web_Service_Log__c>{wsl}, DmlHelper.DML_INSERT, 'ClientspaceAPIQueuable', 'completeWSL', 'Inserting Web Service Log', true);
        }
        system.debug('ClientspaceAPIQueueable completeWSL allFiles'+allFiles);
        if(allFiles!=null && !allFiles.isEmpty() && wsl!=null && String.isNotBlank(wsl.Id)){
            for(Attachment file:allFiles){
                file.ParentId = wsl.Id;
            }
            DmlHelper.performDML2(allfiles, DmlHelper.DML_INSERT, 'ClientspaceAPIQueuable', 'completeWSL', 'Inserting Web Service Log Attachments', true);
        }
    }
    
     public PEO_Underwriting_Code__c buildPEOUnderwritingCode(StateCodeWrapper scw)
    {
        PEO_Underwriting_Code__c peoUnderwritingCode = new PEO_Underwriting_Code__c();
        peoUnderwritingCode.Name = scw.compCode;
        peoUnderwritingCode.IsActive__c = (scw.batchActive && scw.stateActive && scw.compCodeActive);
        peoUnderwritingCode.State_Name__c = scw.state;
        peoUnderwritingCode.Description__c = scw.codeTitle;
        peoUnderwritingCode.Workers_Compensation__c = scw.billingRate;
        peoUnderwritingCode.FICA__c = scw.fica;
        peoUnderwritingCode.FUTA__c = scw.futa;
        peoUnderwritingCode.SUI_Pricing__c = scw.sutaRate;
        peoUnderwritingCode.State_Disability_TDI_DBL_information__c = scw.tdi;
        peoUnderwritingCode.PB_Code_Id__c = scw.pricingCompCodeID;
        peoUnderwritingCode.Workers_Comp_Insurance__c = scw.WCPremium;
        peoUnderwritingCode.SUI__c = scw.SUTATaxes;
        peoUnderwritingCode.FICA_Pricing__c = scw.FICATaxes;
        peoUnderwritingCode.FUTA_pricing__c = scw.FUTATaxes;
        peoUnderwritingCode.Pricing_Batch_Id__c=scw.pricingBatchID;
        peoUnderwritingCode.PB_State_Id__c=scw.pkPricingBatchStateId;
        //JDA
        peoUnderwritingCode.AdminPercent__c=scw.AdminPercentage;
        peoUnderwritingCode.FullTimeEmployees__c=scw.fullTimeEmployees;
        peoUnderwritingCode.PartTimeEmployees__c=scw.partTimeEmployees;
        peoUnderwritingCode.CompCodeStatus__c=scw.compCodeStatus;
        peoUnderwritingCode.TotalEmployees__c=scw.TotalEmployees;
        peoUnderwritingCode.PricingMethod__c =scw.PricingMethod;
        peoUnderwritingCode.PerHead__c =scw.PerHeadFee;
        peoUnderwritingCode.PerUnit__c =scw.PerUnit;
        peoUnderwritingCode.GrossPayroll__c =scw.GrossPayroll;
        peoUnderwritingCode.Set_up_fee__c =scw.SetupFee;
        peoUnderwritingCode.Payroll_Frequency__c=scw.PayrollFrequency;
        System.debug('scw.ClientReport >>'+scw.ClientReport +'  ?');
        peoUnderwritingCode.ClientReport__c= (scw.ClientReport != null ? scw.ClientReport :false);
        return peoUnderwritingCode;
    }
    public Boolean checkIfCodeChanged(PEO_Underwriting_Code__c newCode, PEO_Underwriting_Code__c existingCode){ 
        if(existingCode.Description__c != newCode.Description__c) return true;
        if(existingCode.IsActive__c != newCode.IsActive__c) return true;
        if(existingCode.Pricing_Batch_Id__c != newCode.Pricing_Batch_Id__c) return true;
        if(existingCode.PB_State_Id__c != newCode.PB_State_Id__c) return true;
        if(existingCode.PB_Code_Id__c != newCode.PB_Code_Id__c) return true; 
        if(existingCode.FICA__c != newCode.FICA__c) return true;
        if(existingCode.FICA_Pricing__c != newCode.FICA_Pricing__c) return true;
        if(existingCode.FUTA__c != newCode.FUTA__c) return true;
        if(existingCode.FUTA_pricing__c != newCode.FUTA_pricing__c) return true;
        if(existingCode.SUI__c != newCode.SUI__c) return true;
        if(existingCode.SUI_Pricing__c != newCode.SUI_Pricing__c) return true;
        if(existingCode.Workers_Compensation__c != newCode.Workers_Compensation__c) return true;
        if(existingCode.Workers_Comp_Insurance__c != newCode.Workers_Comp_Insurance__c) return true;
        if(existingCode.State_Disability_TDI_DBL_information__c != newCode.State_Disability_TDI_DBL_information__c) return true;
        //New fields being added for code sync
        if(existingCode.AdminPercent__c != newCode.AdminPercent__c) return true;
        if(existingCode.CompCodeStatus__c != newCode.CompCodeStatus__c) return true;
        if(existingCode.FullTimeEmployees__c != newCode.FullTimeEmployees__c) return true;
        if(existingCode.GrossPayroll__c != newCode.GrossPayroll__c) return true;
        if(existingCode.PartTimeEmployees__c != newCode.PartTimeEmployees__c) return true;
        if(existingCode.PerHead__c != newCode.PerHead__c) return true;
        if(existingCode.PerUnit__c != newCode.PerUnit__c) return true;
        if(existingCode.Set_up_fee__c != newCode.Set_up_fee__c) return true;
        if(existingCode.TotalEmployees__c != newCode.TotalEmployees__c) return true;
        if(existingCode.Payroll_Frequency__c != newCode.Payroll_Frequency__c) return true;
        if(existingCode.ClientReport__c != newCode.ClientReport__c) return true;
        return false; 
    }
    
    public StateCodeWrapper buildStateCodeWrapperObject(Object javascriptObject)
    {
        Map<String, Object> stateCode = (Map<String, Object>) javascriptObject;
        
        StateCodeWrapper scw = new StateCodeWrapper();
        scw.rowNum = (Integer) stateCode.get('RowNum');
        scw.sourceID = (String) stateCode.get('SourceID');
        scw.pricingBatchID = String.valueOf((Integer)stateCode.get('pkPricingBatchID'));
        scw.batchActive = (Boolean) stateCode.get('PricingBatchActive');
        scw.fica = (Decimal) stateCode.get('FICA');
        scw.futa = (Decimal) stateCode.get('FUTA');
        scw.pkPricingBatchStateId = String.valueOf((Integer)stateCode.get('pkPricingBatchStateID'));
        scw.stateActive = (Boolean) stateCode.get('PBStateActive');
        scw.state = (String) stateCode.get('luState');
        scw.sutaRate = (Decimal) stateCode.get('SUTARate');
        scw.tdi = (Decimal) stateCode.get('TDI');
        scw.sfAccountGUID = (String) stateCode.get('z_SFAccountGUID');
        scw.pricingCompCodeID = String.valueOf((Integer) stateCode.get('pkPricingCompCodeID'));
        scw.compCodeActive = (Boolean) stateCode.get('CompCodeActive');
        scw.compCodeStatus = (String) stateCode.get('CompCodeStatus');
        scw.fullTimeEmployees = (Integer) stateCode.get('FullTimeEmployees');
        scw.partTimeEmployees = (Integer) stateCode.get('PartTimeEmployees');
        scw.compCode = (String) stateCode.get('CompCode');
        scw.codeTitle = (String) stateCode.get('CodeTitle');
        scw.billingRate = (Decimal) stateCode.get('EffectiveCompRate');
        scw.WCPremium = (Decimal) stateCode.get('WCPremium');
        scw.FICATaxes = (Decimal) stateCode.get('FicaTaxes');
        scw.FUTATaxes = (Decimal) stateCode.get('FutaTaxes');
        scw.SUTATaxes = (Decimal) stateCode.get('SutaTaxes');
        //JDA
        scw.AdminPercentage = (Decimal) stateCode.get('AdminPercentage');
        scw.TotalEmployees = (Integer) stateCode.get('TotalEmployees');
        scw.PricingMethod = (String) stateCode.get('PricingMethod');
        scw.PerHeadFee = (Decimal) stateCode.get('PerHeadFee');
        scw.PerUnit = (Decimal) stateCode.get('PerUnit');
        scw.GrossPayroll = (Decimal) stateCode.get('GrossPayroll');
        scw.SetupFee = (Decimal) stateCode.get('SetupFee');
        scw.PayrollFrequency = (String) stateCode.get('PayrollFrequency');
        //
        scw.ClientReport = (Boolean) stateCode.get('ClientReport');
        return scw;
    }
    
    public class StateCodeWrapper {
        
        public Integer rowNum {get;set;}
        public String sourceID {get;set;}
        public String pricingBatchID {get;set;}
        public Boolean batchActive {get;set;}
        public Decimal fica {get;set;}
        public Decimal futa {get;set;}
        public String pkPricingBatchStateId {get;set;}
        public Boolean stateActive {get;set;}
        public String state {get;set;}
        public Decimal sutaRate {get;set;}
        public Decimal tdi {get;set;}
        public String sfAccountGUID {get;set;}
        public String pricingCompCodeID  {get;set;}
        public Boolean compCodeActive {get;set;}
        public String compCodeStatus {get;set;}
        public Integer fullTimeEmployees {get; set;}
        public Integer partTimeEmployees {get; set;}
        public String compCode {get;set;}
        public String codeTitle {get;set;}
        public Decimal billingRate {get;set;}
        public Decimal WCPremium {get;set;}
        public Decimal FICATaxes {get;set;}
        public Decimal FUTATaxes {get;set;}
        public Decimal SUTATaxes {get;set;}
        //JDA
        public Decimal AdminPercentage {get;set;}
        public Integer TotalEmployees {get; set;}
        public String PricingMethod {get;set;}
        public Decimal PerHeadFee {get;set;}
        public Decimal PerUnit {get;set;}
        public Decimal GrossPayroll {get;set;}
        public Decimal SetupFee {get;set;}
        public String PayrollFrequency {get;set;}
       
        public Boolean ClientReport {get;set;}
        
        public StateCodeWrapper() {
            WCPremium = null;
          FICATaxes = null;
            FUTATaxes = null;
            SUTATaxes = null;
            rowNum = null;
            sourceID = null;
            pricingBatchID = null;
            batchActive = null;
            fica = null;
            futa = null;
            pkPricingBatchStateId = null;
            stateActive = null;
            state = null;
            sutaRate = null;
            tdi = null;
            sfAccountGUID = null;
            pricingCompCodeID = null;
            compCodeActive = null;
            compCodeStatus = null;
            fullTimeEmployees = null;
            partTimeEmployees = null;
            compCode = null;
            codeTitle = null;
            billingRate = null;
            //JDA
            AdminPercentage = null;
            TotalEmployees = null;
            PricingMethod = null;
            PerHeadFee = null;
            PerUnit = null;
            GrossPayroll = null;
            SetupFee = null;
            PayrollFrequency = null;
            
            ClientReport = null;
        }
    }
    
    // email send members
    public Boolean CONTINUE_API_CALLS = true;
    public Boolean sendEmails = false;
    public Map<Id, Map<Id, Map<String, String[]>>> documentFileTransmitStatusesMap = new  Map<Id, Map<Id, Map<String, String[]>>>();
    
    public void checkStorageForDocumentStatuses(List<PEO_Onboarding_Document__c> docs) {
        for (PEO_Onboarding_Document__c doc : docs) {
            checkStorageForDocumentStatuses(doc);
        }
    }
    
    // verifies that the documentFileTransmitStatusesMap retains the structs needed to store and
    // reference a documents file send statuses
    public void checkStorageForDocumentStatuses(PEO_Onboarding_Document__c doc) {
        // make sure the current doc has the outer doc and inner doc in the storage instance so that we can
        // add a success state for the successful files
        // add higher level account view
        Map<String, string[]> docMap;
        Map<Id, Map<String, String[]>> fullMap;
        if (!documentFileTransmitStatusesMap.containsKey(doc.PEO_Onboarding_Checklist__c)) {
            documentFileTransmitStatusesMap.put(doc.PEO_Onboarding_Checklist__c, new Map<Id, Map<String, String[]>>());
        }
        fullMap = documentFileTransmitStatusesMap.get(doc.PEO_Onboarding_Checklist__c);
        if (!fullMap.containsKey(doc.id)) {
            docMap = new Map<String, String[]>();
            docMap.put('Document Info', new String[]{doc.Routing_Name__c, doc.Id, doc.Prospect_Client_Name__c, doc.PEO_Onboarding_Checklist__r.Opportunity__r.viewInClientSpace__c});
            docMap.put('Successes',  new String[]{});
            docMap.put('Failures',  new String[]{});
            docMap.put('sizeError',  new String[]{});
            fullMap.put(doc.Id, docMap);
        }
        
        // verify the document info property exists
        docMap = fullMap.get(doc.Id);
        if (!docMap.containsKey('Document Info')) {
            String[] DocumentInfo = new String[]{doc.Routing_Name__c, doc.Id};
                docMap.put('Document Info', DocumentInfo);
        }
        
        if (!docMap.containsKey('Failures')) {
            docMap.put('Failures', new String[]{});
        }
        
        if (!docMap.containsKey('Successes')) {
            docMap.put('Successes', new String[]{});
        }
        
        if (!docMap.containsKey('sizeError')) {
            docMap.put('sizeError', new String[]{});
        }
        return;
    }
    
    // kicks off the email process by building the email body and sending the future request
    public void startEmailProcess() {
        System.debug('In email send procedure...');
        String statusSection = '';
        String viewInCsLink;
        // iterate each of the document statuses as a part of the storage struct
        // add all of the document statusses as a part of the email body
        for (Id peoChecklistId : documentFileTransmitStatusesMap.keySet()) {
            Boolean setProspectName = false;
            // send emails flag is used to circumvent an unpromted email send on compile
            statusSection+= 'Prospect: ';
            for (Id docId : documentFileTransmitStatusesMap.get(peoChecklistId).keySet()) {
                String[] docInfo = documentFileTransmitStatusesMap.get(peoChecklistId).get(docId).get('Document Info');
                String[] successFileNames = documentFileTransmitStatusesMap.get(peoChecklistId).get(docId).get('Successes');
                String[] failedFileNames = documentFileTransmitStatusesMap.get(peoChecklistId).get(docId).get('Failures');
                String[] fileSizeIssues = documentFileTransmitStatusesMap.get(peoChecklistId).get(docId).get('sizeError');
                if (!setProspectName) {
                    statusSection += docInfo[2] + '<br />';
                    setProspectName = true;
                }
        Boolean hasSendStatus = false;
                statusSection+= docInfo[0] + ' files:<br />';
                
                if (viewInCsLink == null && docInfo != null && docInfo[3] != null) {
                    viewInCsLink = '<a href="' + docInfo[3] + '">View In Clientspace</a><Br/><Br/>';
                }
                
                if (successFileNames != null && !successFileNames.isEmpty()) {
                    StatusSection+= String.join(successFileNames, '- Success<br />') +  '- Success<br /><br />';
                    if (!this.sendEmails) this.sendEmails = true;
                    hasSendStatus = true;
                }
                
                if (failedFileNames != null && !failedFileNames.isEmpty()) {
                    StatusSection += String.join(failedFileNames, '- Failed<br />') +  '- Failed<br /><br />';
                    if (!this.sendEmails) this.sendEmails = true;
                    hasSendStatus = true;
                }
                
                if (fileSizeIssues != null && !fileSizeIssues.isEmpty()) {
                    StatusSection += String.join(fileSizeIssues, '- Failed. This file is too large. Please submit manually to Clientspace<br />') +  '- Failed. This file is too large. Please submit manually to Clientspace<br /><br />';
                    if (!this.sendEmails) this.sendEmails = true;
                    hasSendStatus = true;
                }
                if (!hasSendStatus) StatusSection+= '- No files uploaded to send<br /><br />';
            }
        }
        
        User currentUser = UserHelper.getRunningUser();
        sendEmail(statusSection, viewInCsLink);
    }
    
    // only send the email if the sendEmail flag is set to true by the startEmailProcess method
    // sendEmail member avoids unwanted calls to future method
    public void sendEmail(String body, String viewInCsLink) {
        System.debug('Inside sendEmail:');
        Peo_Onboarding_Checklist__c[] userChecklists = [SELECT Id,Sales_Rep__c FROM  Peo_Onboarding_Checklist__c WHERE Id In :documentFileTransmitStatusesMap.keySet()];
        Set<String> emails = new Set<String>();
        for (Peo_Onboarding_Checklist__c chk : userChecklists) {
            System.debug('sendEmail chk:'+chk);
            if (chk.Sales_Rep__c != null) emails.add(chk.Sales_Rep__c);
            //if (chk.PEO_NSC__c != null) emails.add(chk.PEO_NSC__c);
        }
        System.debug('Inside sendEmail:emails-'+emails);
        if (this.sendEmails) sendUserEmail(body, emails, viewInCsLink);
    }
    
    // add header message and send the email
    @future
    public static void sendUserEmail(String body, Set<String> emails, String viewInCsLink) {
        // get the user in the future call
        // set the target object in the future call
        // define the default emails and reply information in the future call
        // send the email
        
        User currentUser = UserHelper.getRunningUser();
        String header = 'Below is the Transmission state for each document requested to be sent to clientspace on ' + system.today().format() + '<br /><br />';
        body = header + viewInCsLink + body;
        List<Messaging.SingleEmailMessage> emailList = new List< Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail1 = new Messaging.SingleEmailMessage();
        mail1.setTargetObjectId(currentUser.Id);
        mail1.setHtmlBody(body);
        mail1.setSubject('Underwriting document submit to client space status');
        mail1.setSaveAsActivity(false);    
        emailList.add(mail1);
        
        for (String userId : emails) {
            Messaging.SingleEmailMessage mail2 = new Messaging.SingleEmailMessage();
            mail2.setTargetObjectId(userId);
            mail2.setHtmlBody(body);
            mail2.setSubject('Underwriting document submit to client space status');
            mail2.setSaveAsActivity(false);    
            emailList.add(mail2);
        }
        if(!Test.isRunningTest()){
            try {
              Messaging.sendEmail(emailList);   
            }catch(DMLException e) {
                ErrorLog.logError('ClientspaceAPIQueueable', 'sendEmail', 'cannot send email', currentUser.id, e.getMessage());
            }
        }
    }
    
    // Takes an unparsed response JSON with location data and sets the class members
    // required to send files to the correct dataforms in client space
    public void setClassMembersForWorkspace(List<Object> data) {
        for (Object loc : data) {
            Boolean haveNullValue = false;
            Map<String, Object> location = (Map<String, Object>)loc;
            Integer projId = (Integer)location.get('ProjectID');
            Integer colatId = (Integer)location.get('pkCollateralID');
            Integer riskId = (Integer)location.get('pkRFPQuestionnaireID');
            Integer clientMasterId = (Integer)location.get('pkClientMasterID');
            Integer medId = (Integer)location.get('pkzBenefitsUnderwritingID');
            Integer checklistID = (Integer)location.get('pkzPEOOnboardingChecklistID'); // this is pkzPEOUnderwritingChecklistID in full
            String colatGuid = (String)location.get('CollateralRowGuid');
            String riskGuid = (String)location.get('RiskUWGuid');
            String medGuid = (String)location.get('BenUWGuid');
            String clientGuid = (String)location.get('CMGuid');
            String checklistGuid = (String)location.get('UWChecklistGuid');
            
            if (projId != null) this.wrkSpaceId = String.valueOf(projId);
            else haveNullValue = true;
            
            if (colatId != null) this.pkCollateralID = String.valueOf(colatId);
            else haveNullValue = true;
            
            if (riskId != null) this.pkRFPQuestionnaireID = String.valueOf(riskId);
            else haveNullValue = true;
            
            if (clientMasterId != null) this.pkClientMasterID = String.valueOf(clientMasterId);
            else haveNullValue = true;
            
            if (medId != null) this.pkzBenefitsUnderwritingID = String.valueOf(medId);
            else haveNullValue = true;
            
            if (checklistID != null) this.pkzPEOUnderwritingChecklistID = String.valueOf(checklistID);
            else haveNullValue = true;
            
            if (colatGuid != null) this.CollateralRowGuid = colatGuid;
            else haveNullValue = true;
            
            if (riskGuid != null) this.RiskUWGuid = riskGuid;
            else haveNullValue = true;
            
            if (medGuid != null) this.BenUWGuid = medGuid; 
            else haveNullValue = true;
            
            if (clientGuid != null) this.CMGuid = clientGuid; 
            else haveNullValue = true;
            
            if (checklistGuid != null) this.UWChecklistGuid = checklistGuid;
            else haveNullValue = true;
            
            if (!haveNullValue) break;
        }
        
        return;
    }
    
    //PEO SPA: Create Benefit batch record for Quick quote submission
    public Boolean createQuickQuoteBenBatchInCs(String csTableName, string calloutType, String workspaceID){
        Boolean QQbenBatchRecCreated = false;
        string endpoint = 'callout:CS_API/next/api/dataform/v2.0/'+csTableName+'/'+workspaceID;
        //Update this with new method
        String postBody = buildQuickQuoteJSON('Pending','RFP',1,null);
        //System.debug('postBody:'+postBody);
        HttpRequest req = buildRequest(calloutType,endpoint);
        req.setBody(postBody);
        System.debug(' createQuickQuoteBenBatchInCs Quick quote req:'+req);
        Map<Boolean,String> responseMap = sendRequest(req,Test.isRunningTest());
        System.debug('createQuickQuoteBenBatchInCs responseMap:'+responseMap);
        for(Boolean succeeded : responseMap.keySet()){
            if(succeeded){
                System.debug('createQuickQuoteBenBatchInCs Quick quote Post request succesful ... ');
                Map<String, Object> keySets = (Map<String, Object>)JSON.deserializeUntyped(responseMap.get(succeeded));
                System.debug('createQuickQuoteBenBatchInCs Keysets... ');
                System.debug(keySets.keySet());
                //Update this line
                if (keySets.get('RowGUID') != null) this.QQRowGuid = String.valueOf(keySets.get('RowGUID'));
                if (keySets.get('ID') != null){
                    //Update this line
                    this.QQRecordId = String.valueOf(keySets.get('ID'));
                    //QQbenBatchRecCreated = true;
                    this.QQbenBatchRecCreated = true;
                } 
                //Update this line
                System.debug('createQuickQuoteBenBatchInCs Quick quote BenBatchRowGuid:'+this.QQRowGuid);
            }
            else{
                System.debug('HTTP ERROR ON SEND CHECK LOGS...>>>\n');
                String emailBody = 'Fatal error submitting documents for account: ' + this.docs[0].Prospect_Client_Name__c;
                sendEmail(emailBody,'');
            }
        }
        System.debug('createQuickQuoteBenBatchInCs QQbenBatchRecCreated:'+QQbenBatchRecCreated);
        return QQbenBatchRecCreated;
    }
    
    
    public String buildQuickQuoteJSON(String luStatus, String luType, Integer z_CreateBenefitsPlan, String fuGAIHealthCensus)
    {  
        //String luStatus = 'Pending';
        //String luType = 'RPF';
        //String EffectiveDate = '10/11/2022';//mm/dd/yyyy
        //Integer z_CreateBenefitsPlan = 1;
        //String fuGAIHealthCensus = null;
        DateTime todaysDate = Date.today();
        String EffectiveDate =  todaysDate.format('MM/dd/yyyy');
        String body = '{"luStatus":"'+luStatus+'",\n';
        body += '"luType":"'+luType+'",\n';
        body += '"EffectiveDate":"'+EffectiveDate+'",\n';
        body += '"z_CreateBenefitsPlan":'+z_CreateBenefitsPlan+',\n';
        body += '"fuGAIHealthCensus":'+fuGAIHealthCensus+'}';    
        //System.debug(body);
        return body;
    }
    
    //Search if a file is already present in the document bin
    public void fileFindCallout(PEO_Onboarding_Document__c doc){
        setCSDataformInformation(doc);
        PEO_Onboarding_Document_Map__c docInfo = docMapByDocId.get(doc.Id);
        csFieldName = (String.isNotBlank(docInfo.Clientspace_Field__c) ? docInfo.Clientspace_Field__c : '');
        csTableName = (String.isNotBlank(docInfo.Clientspace_Table__c) ? docInfo.Clientspace_Table__c : '');
        //Manually setting the Table name and Field name for Quick quote
        if(doc.Routing_Name__c == 'Census' && doc.PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical' && doc.PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp'){
            csTableName = 'gen_BenefitsBatch';
        }
        if(doc.Routing_Name__c == 'Census' && doc.PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical' && doc.PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp'){
            csFieldName = 'fuGAIHealthCensus';
        }
        System.debug('Starting find build...');
        System.debug('fileFindCallout csFieldName:'+csFieldName);
        System.debug('fileFindCallout csTableName:'+csTableName);
        System.debug('fileFindCallout this.rowGUID:'+this.rowGUID);
        string calloutType = 'GET';
        string endpoint = 'callout:CS_API/next/api/file/v2.0/find?criteria.entityRowGUID='+this.rowGUID+'&criteria.tableName='+csTableName+'&criteria.fieldName='+csFieldName;
        //String body = '{"entityRowGUID":"' + this.rowGUID + '"}';
        HttpRequest req = buildRequest(calloutType,endpoint); // builds a http obj. Nothing dynamic except ep & callout
        //req.setBody(body);
        System.debug('Is running a test: '+ Test.isRunningTest());
        System.debug('fileFindCallout req: '+ req);
        //System.debug('fileFindCallout body: '+ body);
        Map<Boolean,String> responseMap = sendRequest(req,Test.isRunningTest());
        System.debug('fileFindCallout responseMap: '+responseMap);
        for(Boolean succeeded : responseMap.keySet()){
            if(succeeded){
                System.debug('Search request succesful ... ');
                // start to desearlaize: get the keysets
                Map<String, Object> keySets = (Map<String, Object>)JSON.deserializeUntyped(responseMap.get(succeeded));
                // retrieves the dataSet & errors if present
                System.debug(keySets.keySet());
                List<Object> data = (List<Object>)keySets.get('Data');
                List<Object> errors = (List<Object>)keySets.get('Errors');
                
                // if errors found debugs them
                // otherwise continues with returned date
                if (errors != null && data == null) {
                    // deserealize and log each error
                    System.debug('Errors retrieving info');
                } else if (data != null) {
                    System.debug('fileFindCallout data:'+data);
                    for (Object fileInfo : data) {
                        Map<String, Object> fileData = (Map<String, Object>)fileInfo;
                        if((String)fileData.get('LinkGuid')!= null){
                            this.linkGuid = (String)fileData.get('LinkGuid');
                            this.fileExistInField = true;
                        }
                        else{
                            this.fileExistInField = false;
                        }
                    }
                }
                System.debug('fileFindCallout fileExistInField :'+this.fileExistInField);
            }
            else{
                System.debug('HTTP ERROR ON SEND CHECK LOGS...>>>\n');
                String emailBody = 'Fatal error submitting documents for account: ' + this.docs[0].Prospect_Client_Name__c;
                sendEmail(emailBody,'');
            }
        }
        if(fileExistInField !=null && fileExistInField == true){
            ClientspaceAPIQueueable caq = new ClientspaceAPIQueueable(accounts, docs, 'Additional File Put',null,null,
                                                                      null, wrkSpaceId,docMapByDocId, parentAccId,wsl,allFiles);
            caq.UWChecklistGuid = this.UWChecklistGuid;
            caq.BenUWGuid = this.BenUWGuid;
            caq.RiskUWGuid = this.RiskUWGuid;
            caq.CMGuid = this.CMGuid;
            caq.CollateralRowGuid = this.CollateralRowGuid;
            caq.pkzPEOUnderwritingChecklistID = this.pkzPEOUnderwritingChecklistID;
            caq.pkzBenefitsUnderwritingID = this.pkzBenefitsUnderwritingID;
            caq.pkRFPQuestionnaireID = this.pkRFPQuestionnaireID;
            caq.pkClientMasterID = this.pkClientMasterID;
            caq.pkCollateralID = this.pkCollateralID;
            caq.documentFileTransmitStatusesMap = this.documentFileTransmitStatusesMap;
            caq.linkGuid = this.linkGuid;
            if (this.hsfRowGuid != null) caq.hsfRowGuid = this.hsfRowGuid;
            if (this.hsfRecordId != null) caq.hsfRecordId = this.hsfRecordId;
            if (this.benBatchRecCreated != null) caq.benBatchRecCreated = this.benBatchRecCreated;
            if (this.QQRowGuid != null) caq.QQRowGuid = this.QQRowGuid;
            if (this.QQRecordId != null) caq.QQRecordId = this.QQRecordId;
            if (this.QQbenBatchRecCreated != null) caq.QQbenBatchRecCreated = this.QQbenBatchRecCreated;    
            if (!Test.isRunningTest()) {
                System.enqueueJob(caq);   
            } 
        }
        else{
            System.debug('fileFindCallout: calling Doc Post');
            System.debug('fileFindCallout: wrkSpaceId-'+wrkSpaceId);
            ClientspaceAPIQueueable caq = new ClientspaceAPIQueueable(accounts, docs, 'Doc Post',null,null,
                                                                      null, wrkSpaceId,docMapByDocId, parentAccId,wsl,allFiles);
            caq.UWChecklistGuid = this.UWChecklistGuid;
            caq.BenUWGuid = this.BenUWGuid;
            caq.RiskUWGuid = this.RiskUWGuid;
            caq.CMGuid = this.CMGuid;
            caq.CollateralRowGuid = this.CollateralRowGuid;
            caq.pkzPEOUnderwritingChecklistID = this.pkzPEOUnderwritingChecklistID;
            caq.pkzBenefitsUnderwritingID = this.pkzBenefitsUnderwritingID;
            caq.pkRFPQuestionnaireID = this.pkRFPQuestionnaireID;
            caq.pkClientMasterID = this.pkClientMasterID;
            caq.pkCollateralID = this.pkCollateralID;
            caq.documentFileTransmitStatusesMap = this.documentFileTransmitStatusesMap;
            caq.linkGuid = this.linkGuid;
            if (this.hsfRowGuid != null) caq.hsfRowGuid = this.hsfRowGuid;
            if (this.hsfRecordId != null) caq.hsfRecordId = this.hsfRecordId;
            if (this.benBatchRecCreated != null) caq.benBatchRecCreated = this.benBatchRecCreated;
            if (this.QQRowGuid != null) caq.QQRowGuid = this.QQRowGuid;
            if (this.QQRecordId != null) caq.QQRecordId = this.QQRecordId;
            if (this.QQbenBatchRecCreated != null) caq.QQbenBatchRecCreated = this.QQbenBatchRecCreated;    
            if (!Test.isRunningTest()) {
                System.debug('fileFindCallout: calling Doc Post enqueueJob');
                System.enqueueJob(caq);   
            }          
            if (Test.isRunningTest()) FileAddCallout(docs[0], null, wrkSpaceId);
        }
        
    }
    
    //For adding additional doc
    public Boolean filePutCallout(PEO_Onboarding_Document__c doc, String linkGuid){
        // setup the row guid, field name and table name for the current document
        // High level document only not files: potentially add some error handling if doc mapping
        // is null
        System.debug('filePutCallout');
        setCSDataformInformation(doc);
        
        // flag used later on for multiple file sends
        Boolean hasAdditionalFiles = false;
        string calloutType = 'PUT';
        string endpoint = 'callout:CS_API/next/api/file/v2.0/'+linkGuid;
        System.debug('filePutCallout endpoint:'+endpoint);
        HttpRequest req = buildRequest(calloutType,endpoint);
        
        ContentDocument cd = new ContentDocument();
        
        // get all the docs we already sent
        Set<Id> docsAlreadySent = new Set<Id>();
        if (doc.Docs_Sent_to_Clientspace__c != null) {
            for(String docId : doc.Docs_Sent_to_Clientspace__c.split(',')) {
                docsAlreadySent.add(docId);
            }   
        }
        //JDA SPA changes
        ContentDocumentLink[] cdls;
        System.debug('filePutCallout doc info: '+doc);
        if(doc.Routing_Name__c == 'Census' && doc.PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical' && doc.PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp'&& projectId != null){
            System.debug('Fetch the last Census doc uploaded for Quick quote');
            cdls = [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.Description,ContentDocument.ContentAssetId,LinkedEntityId  
                    FROM ContentDocumentLink 
                    where LinkedEntityId = :doc.Id AND Id NOT IN :docsAlreadySent
                    ORDER BY ContentDocument.ContentModifiedDate DESC 
                    limit 1];
        }
        else{
            cdls = [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.Description,ContentDocument.ContentAssetId,LinkedEntityId  
                    FROM ContentDocumentLink 
                    where LinkedEntityId = :doc.Id AND Id NOT IN :docsAlreadySent
                    ORDER BY ContentDocument.ContentModifiedDate ASC];
        }
        /*ContentDocumentLink[] cdls = [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.Description,ContentDocument.ContentAssetId,LinkedEntityId  
                                      FROM ContentDocumentLink 
                                      where LinkedEntityId = :doc.Id AND Id NOT IN :docsAlreadySent
                                      ORDER BY ContentDocument.ContentModifiedDate ASC];*/
        System.debug('cdls: '+cdls);
        ContentDocumentLink cdl;
        ContentVersion cv;
        
        // if we are uploading more than one file to the same field, we need to send a 1 
        // into the type field on the post. First doc should get 0, all subsequent 1.
        Integer additionalFileInt = 0;
        Integer versionNumber = 1;
        
        // if there are lings and they aren't empty set the cdl as the first linl
        if(cdls!=null && !cdls.isEmpty()){
            cdl = cdls[0];
        }
        
        // if there are additional files set the flag that there are additional files to true
        if(cdls !=null && cdls.size() > 1){
            hasAdditionalFiles = true;
        }
        
        //this will query the specific version of the document after finding the link
        //will be non null only if the links have not been sent
        if(cdl!=null){
            // get he information for the current link
            cv = [SELECT VersionData,ContentSize,ContentUrl,Description,FileType,FileExtension,Title,PathOnClient
                  FROM ContentVersion WHERE ContentDocumentId = :cdl.ContentDocumentId ORDER BY VersionNumber DESC LIMIT 1];
            // if the current document has a link id in docs to CS
            if(string.isBlank(doc.Docs_Sent_to_Clientspace__c)){
                doc.Docs_Sent_to_Clientspace__c = cdl.Id+',';
            }
            // if the string is blank create the first add the first link Id and set the version number
            // version number is used as the 
            else{
                doc.Docs_Sent_to_Clientspace__c += cdl.Id+',';
                //if we are uploading more than one file to the same field, we need to send a 1 into the type field on the post.  First doc should get 0, all subsequent 1.
                additionalFileInt=1;
                versionNumber = doc.Docs_Sent_to_Clientspace__c.split(',').size();
            }
            
        }
        
        // ON VERSION DATA regarding base64 encoding
        // The content or body of the note, which can include properly formatted HTML or plain text. When a document is uploaded or downloaded via the API, it should be base64 encoded (for upload) or decoded (for download). 
        // Any special characters within plain text in the Content field must be escaped. You can escape special characters by calling content.escapeHtml4().This field can't be set for links.
        // The maximum file size you can upload via the SOAP API is 50 MB. When a document is uploaded or downloaded via the API, it is converted to base64 and stored in VersionData. 
        // This conversion increases the document size by approximately 37%. Account for the base64 conversion increase so that the file you plan to upload is less than 50 MB after conversion.
        // If a custom Apex download handler is active, this field is accessed from the API, and the download is not allowed, Salesforce will return a CONTENT_CUSTOMIZED_DOWNLOAD_EXCEPTION error.
        // Per Dan - the rest api can support files up to 10 MB.
        // https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_contentversion.htm
        Map<Boolean,String> patchResponseMap;
        if(cv!=null){
            String mimeType;
            if(cv.FileExtension == 'png' || cv.FileExtension == 'jpg' || cv.FileExtension == 'jpeg' || cv.FileExtension == 'bmp'){
                mimeType = 'image/'+cv.FileExtension;
            }
            else if(cv.FileExtension == 'zip'){
                mimeType = 'application/zip';
            }
            else if(cv.FileExtension == 'txt'){
                mimeType = 'text/plain';
            }
            System.debug('CV BEfore build: '+cv);
            System.debug('filePutCallout csFieldName: '+csFieldName);
            String title = cv.Title +'.'+ cv.FileExtension;
            String filebody = buildFileJSON(title, null, projectId, csTableName, 
                                            csFieldName, cv.ContentSize, mimeType,
                                            null, cv.Description, new String[]{},
                                            null, additionalFileInt, versionNumber, cv.VersionData, doc);
            //if (filebody == null) return hasAdditionalFiles;
            req.setBody(fileBody);
            System.debug('filePutCallout :req:'+req);
            Map<Boolean,String> responseMap = sendRequest(req,Test.isRunningTest());
            System.debug('filePutCallout :Response after Doc post:'+responseMap);
            for(Boolean success : responseMap.keySet()){
                if(success){
                    // add some error handling and parsing here
                    // include success messages in the error list
                    Map<String, Object> jsonBody = (Map<String, Object>) JSON.deserializeUntyped(responseMap.get(success));
                    String fileGuid = (String)jsonBody.get('LinkGuid');
                    String[] errors = new String[]{};
                        Object[] errorObjs = (Object[])jsonBody.get('Errors');
                    
                    if(!errorObjs.isEmpty()){
                        for(Object obj : errorObjs){
                            //:[{"Message":"Procedure or function 'nw_filemanagement_iu_createfilelink' expects parameter '@EntityRowGUID', which was not supplied.","Code":0}]
                            Map<String, Object> error = (Map<String, Object>)obj;
                            String msg = (String)error.get('Message');
                            Integer code = (Integer)error.get('code');
                            errors.add(msg + code);
                        }
                       String[] errorStorageForDoc = documentFileTransmitStatusesMap.get(doc.PEO_Onboarding_Checklist__c).get(doc.Id).get('Failures');
                        errorStorageForDoc.add(cv.PathOnClient);
                    }
                    
                    String recordId; // > need to have this pulled from the document send so it can be passed into the patch
                    if (csTableName == 'gen_zBenefitsUnderwriting') { // medical
                        recordId = pkzBenefitsUnderwritingID;
                    }
                    
                    if (csTableName == 'gen_BenefitsBatch') { // Quick quote medical
                        System.debug('Setting recordId to QQRowGuid:'+QQRowGuid);
                        recordId = QQRecordId;
                    }
                    
                    if (csTableName == 'gen_RFPQuestionnaire') {  // Risk
                        recordId = pkRFPQuestionnaireID;    
                    }
                    
                    if (csTableName == 'gen_ClientMaster') {  // WC classes and wages
                        recordId = pkClientMasterID;    
                    }
                    
                    if (recordId == null) recordId = pkzPEOUnderwritingChecklistID;
                    
                    if(String.isNotBlank(csTableName) && errors.isEmpty()){
                        Map<String,String> fieldMap = new Map<String,String>();
                        fieldMap.put(csFieldName,fileGuid);
                        System.debug('filePutCallout Version number:'+versionNumber);
                        //file guid should be the that of latest versioned file
                        //Map<Boolean,String> pinResponseMap = filePinCallout((String)jsonBody.get('LinkGuid'), (String)jsonBody.get('LinkGuid'));
                        patchResponseMap = dataformPatchCallout(csTableName,recordId,fieldMap, versionNumber);// table, recordId, fieldMap{z_epli: guid}
                        System.debug('filePutCallout patchResponseMap:'+patchResponseMap);
                        String[] successes = documentFileTransmitStatusesMap.get(doc.PEO_Onboarding_Checklist__c).get(doc.id).get('Successes');
                        successes.add(cv.PathOnClient);
                    }
                }
                else{
                    system.debug(responseMap.get(success));
                    
                    this.CONTINUE_API_CALLS = false;
                    String body = 'Fatal error submitting documents for account: ' + this.docs[0].Prospect_Client_Name__c;
                    this.sendEmails = true;
                    sendEmail(body, '');
                }
            }
        }
        updateDocsAndChecklist(hasAdditionalFiles, patchResponseMap, doc, cd);
        return hasAdditionalFiles;
        //Check if this is the last file and call PIN accordingly
        //else repeat the PUT 
    }
    
    //For pinning the additional doc and make it as the latest file
    //Since we are sending the files individually, its getting posted as latest file
    //So we are not using this method, can be kept for future reference
    /*public Map<Boolean,String> filePinCallout(String linkGuid, String fileGuid){
        // Your File PIN code starts here
        System.debug('filePinCallout');
        string calloutType = 'PUT';
        //endpoint and authentication are derived from named credential record
        string endpoint = 'callout:CS_API/next/api/file/v2.0/pin/'+linkGuid+'/'+fileGuid;
        HttpRequest req = buildRequest(calloutType,endpoint);
        system.debug('req'+req);
        Map<Boolean,String> responseMap = sendRequest(req,Test.isRunningTest());
        System.debug('filePinCallout responseMap:'+responseMap);
        return responseMap;
    }*/
    
    //For adding the first file
    public Boolean FileAddCallout(PEO_Onboarding_Document__c doc,String rowGUID,String  projectId){
        // setup the row guid, field name and table name for the current document
        // High level document only not files: potentially add some error handling if doc mapping
        // is null
        System.debug('FileAddCallout benBatchRecCreated:'+this.benBatchRecCreated);
        Boolean isQuickQuoteCensus = false;
        //PEO SPA updates
        //Update this code
        if(this.QQbenBatchRecCreated == null){
            System.debug('FileAddCallout: check if we need to create the Benefit batch record');
            System.debug('FileAddCallout doc info: '+doc);
            System.debug('FileAddCallout doc info med path: '+doc.PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c);
            System.debug('FileAddCallout doc info WC path: '+doc.PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c);
            System.debug('FileAddCallout projectId: '+projectId);
            if(doc.Routing_Name__c == 'Census' && doc.PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical' && doc.PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp'&& projectId != null){
                System.debug('Create the QQ Benefit batch record');
                createQuickQuoteBenBatchInCs('gen_BenefitsBatch','POST',projectId);
            }
        }
        setCSDataformInformation(doc);
        
        // flag used later on for multiple file sends
        Boolean hasAdditionalFiles = false;
        string calloutType = 'POST';
        string endpoint = 'callout:CS_API/next/api/file/v2.0/add';
        HttpRequest req = buildRequest(calloutType,endpoint);
        
        ContentDocument cd = new ContentDocument();
        
        // get all the docs we already sent
        Set<Id> docsAlreadySent = new Set<Id>();
        if (doc.Docs_Sent_to_Clientspace__c != null) {
            for(String docId : doc.Docs_Sent_to_Clientspace__c.split(',')) {
                docsAlreadySent.add(docId);
            }   
        }
        //JDA SPA changes
        ContentDocumentLink[] cdls;
        System.debug('FileAddCallout Routing name:'+doc.Routing_Name__c);
        System.debug('FileAddCallout Medical_Underwriting_Path_Type__c:'+doc.PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c);
        System.debug('FileAddCallout Workers_Comp_Underwriting_Path_Type__c:'+doc.PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c);
        System.debug('FileAddCallout projectId:'+projectId);
        if(doc.Routing_Name__c == 'Census' && doc.PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical' && doc.PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp'&& projectId != null){
            System.debug('Fetch the last Census doc uploaded for Quick quote');
            isQuickQuoteCensus = True;
            cdls = [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.Description,ContentDocument.ContentAssetId,LinkedEntityId  
                    FROM ContentDocumentLink 
                    where LinkedEntityId = :doc.Id AND Id NOT IN :docsAlreadySent
                    ORDER BY ContentDocument.ContentModifiedDate DESC 
                    limit 1];
        }
        else{
            cdls = [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.Description,ContentDocument.ContentAssetId,LinkedEntityId  
                    FROM ContentDocumentLink 
                    where LinkedEntityId = :doc.Id AND Id NOT IN :docsAlreadySent
                    ORDER BY ContentDocument.ContentModifiedDate ASC];
        }
        System.debug('FileAddCallout cdls: '+cdls);
        ContentDocumentLink cdl;
        ContentVersion cv;
        
        // if we are uploading more than one file to the same field, we need to send a 1 
        // into the type field on the post. First doc should get 0, all subsequent 1.
        Integer additionalFileInt = 0;
        Integer versionNumber = 1;
        
        // if there are links and they aren't empty set the cdl as the first link
        if(cdls!=null && !cdls.isEmpty()){
            cdl = cdls[0];
        }
        
        // if there are additional files set the flag that there are additional files to true
        // For Quick quote, we will be sending only the last census uploaded
        System.debug('FileAddCallout isQuickQuote:'+isQuickQuoteCensus);
        if(cdls !=null && cdls.size() > 1 && !isQuickQuoteCensus){
            hasAdditionalFiles = true;
        }
        
        //this will query the specific version of the document after finding the link
        //will be non null only if the links have not been sent
        if(cdl!=null){
            // get the information for the current link
            cv = [SELECT VersionData,ContentSize,ContentUrl,Description,FileType,FileExtension,Title,PathOnClient
                  FROM ContentVersion WHERE ContentDocumentId = :cdl.ContentDocumentId ORDER BY VersionNumber DESC LIMIT 1];
            // if the current document has a link id in docs to CS
            if(string.isBlank(doc.Docs_Sent_to_Clientspace__c)){
                doc.Docs_Sent_to_Clientspace__c = cdl.Id+',';
            }
            // if the string is blank create the first record, add the first link Id and set the version number
            else{
                doc.Docs_Sent_to_Clientspace__c += cdl.Id+',';
                //if we are uploading more than one file to the same field, we need to send a 1 into the type field on the post.  First doc should get 0, all subsequent 1.
                additionalFileInt=1;
                versionNumber = doc.Docs_Sent_to_Clientspace__c.split(',').size();
            }
            
        }
        
        // ON VERSION DATA regarding base64 encoding
        // The content or body of the note, which can include properly formatted HTML or plain text. When a document is uploaded or downloaded via the API, it should be base64 encoded (for upload) or decoded (for download). 
        // Any special characters within plain text in the Content field must be escaped. You can escape special characters by calling content.escapeHtml4().This field can't be set for links.
        // The maximum file size you can upload via the SOAP API is 50 MB. When a document is uploaded or downloaded via the API, it is converted to base64 and stored in VersionData. 
        // This conversion increases the document size by approximately 37%. Account for the base64 conversion increase so that the file you plan to upload is less than 50 MB after conversion.
        // If a custom Apex download handler is active, this field is accessed from the API, and the download is not allowed, Salesforce will return a CONTENT_CUSTOMIZED_DOWNLOAD_EXCEPTION error.
        // Per Dan - the rest api can support files up to 10 MB.
        // https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_contentversion.htm
        Map<Boolean,String> patchResponseMap;
        if(cv!=null){
            String mimeType;
            if(cv.FileExtension == 'png' || cv.FileExtension == 'jpg' || cv.FileExtension == 'jpeg' || cv.FileExtension == 'bmp'){
                mimeType = 'image/'+cv.FileExtension;
            }
            else if(cv.FileExtension == 'zip'){
                mimeType = 'application/zip';
            }
            else if(cv.FileExtension == 'txt'){
                mimeType = 'text/plain';
            }
            System.debug('CV BEfore build: '+cv);
            String title = cv.Title +'.'+ cv.FileExtension;
            //Passing workspaceId as null since its not required
            String filebody = buildFileJSON(title, this.rowGUID, null, csTableName, 
                                            csFieldName, cv.ContentSize, mimeType,
                                            null, cv.Description, new String[]{},
                                            null, additionalFileInt, versionNumber, cv.VersionData, doc);
            if (filebody == null) return hasAdditionalFiles;
            req.setBody(fileBody);
            Map<Boolean,String> responseMap = sendRequest(req,Test.isRunningTest());
            System.debug('FileAddCallout :Response after Doc post:'+responseMap);
            for(Boolean success : responseMap.keySet()){
                if(success){
                    // add some error handling and parsing here
                    // include success messages in the error list
                    Map<String, Object> jsonBody = (Map<String, Object>) JSON.deserializeUntyped(responseMap.get(success));
                    String fileGuid = (String)jsonBody.get('LinkGuid');
                    //Setting LinkGuid to avoid multiple Find calls
                    this.LinkGuid = fileGuid;
                    String[] errors = new String[]{};
                        Object[] errorObjs = (Object[])jsonBody.get('Errors');
                    
                    if(!errorObjs.isEmpty()){
                        for(Object obj : errorObjs){
                            //:[{"Message":"Procedure or function 'nw_filemanagement_iu_createfilelink' expects parameter '@EntityRowGUID', which was not supplied.","Code":0}]
                            Map<String, Object> error = (Map<String, Object>)obj;
                            String msg = (String)error.get('Message');
                            Integer code = (Integer)error.get('code');
                            errors.add(msg + code);
                        }
                        String[] errorStorageForDoc = documentFileTransmitStatusesMap.get(doc.PEO_Onboarding_Checklist__c).get(doc.Id).get('Failures');
                        errorStorageForDoc.add(cv.PathOnClient);
                    }
                    
                    String recordId; // > need to have this pulled from the document send so it can be passed into the patch
                    if (csTableName == 'gen_zBenefitsUnderwriting') { // medical
                        recordId = pkzBenefitsUnderwritingID;
                    }
                    
                    if (csTableName == 'gen_BenefitsBatch') { // Quick quote medical
                        System.debug('Setting recordId to QQRowGuid:'+QQRowGuid);
                        recordId = QQRecordId;
                    }
                    
                    if (csTableName == 'gen_RFPQuestionnaire') {  // Risk
                        recordId = pkRFPQuestionnaireID;    
                    }
                    
                    if (csTableName == 'gen_ClientMaster') {  // WC classes and wages
                        recordId = pkClientMasterID;    
                    }
                    
                    if (recordId == null) recordId = pkzPEOUnderwritingChecklistID;
                    
                    if(String.isNotBlank(csTableName) && errors.isEmpty()){
                        Map<String,String> fieldMap = new Map<String,String>();
                        fieldMap.put(csFieldName,fileGuid);
                        patchResponseMap = dataformPatchCallout(csTableName,recordId,fieldMap, versionNumber);// table, recordId, fieldMap{z_epli: guid}
                        System.debug('FileAddCallout patchResponseMap:'+patchResponseMap);
                        String[] successes = documentFileTransmitStatusesMap.get(doc.PEO_Onboarding_Checklist__c).get(doc.id).get('Successes');
                        successes.add(cv.PathOnClient);
                    }
                }
                else{
                    system.debug(responseMap.get(success));
                    
                    this.CONTINUE_API_CALLS = false;
                    String body = 'Fatal error submitting documents for account: ' + this.docs[0].Prospect_Client_Name__c;
                    this.sendEmails = true;
                    sendEmail(body, '');
                }
            }
        }
        System.debug('FileAddCallout hasAdditionalFiles:'+hasAdditionalFiles);
        updateDocsAndChecklist(hasAdditionalFiles, patchResponseMap, doc, cd);
        if (Test.isRunningTest()) filePutCallout(docs[0],LinkGuid);
        return hasAdditionalFiles;
    }
}