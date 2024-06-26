/* 
   Batch job for working with Data in a batch.
   
  DataLoadBatch2 dlb = new DataLoadBatch2();
  Database.executeBatch(dlb, 200);

  History
  -------
  07/30/2020 Dan Carmen   Created
  11/02/2020 Dan Carmen   A couple of small updates - error on timeout, set use zip assignment for referral accounts.
  11/04/2020 Dan Carmen   Explicitly create campaign members.
  11/25/2020 Dan Carmen   Don't create referral contacts if no referral account.
  12/14/2020 Dan Carmen   Change to without sharing
  03/12/2021 Dan Carmen   Fix for updating null values
  03/23/2021 Dan Carmen   Fix for logging insert vs update
  06/17/2021 Dan Carmen   Update when we use Data Governance Rules
  07/16/2021 Dan Carmen   Ability to skip triggers on save
  06/20/2022 Dan Carmen   Change insert, update, and upsert to use DmlHelper
  09/27/2022 Dan Carmen   Allow to set timeout dynamically
  03/13/2023 Dan Carmen   Increment API to 57

 */
global without sharing class DataLoadBatch2 implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable  {

   public static String CLASSNAME='DataLoadBatch2';

   global String currentMode='';
   global DataLoad__c dataLoad = null;
   global Boolean fileSuccess = true;
    
   // the map of the fields for the object being inserted into
   global Map<String, Schema.SObjectField> fieldMap = null;
   global String[] headers=null;
   global Boolean[] validHeaders=new Boolean[]{};
    
   global Boolean isLeadList { get {return (dataLoad != null && dataLoad.FileType__c == DataLoadMethods.TYPE_LEAD_LIST );}}
   global Boolean isRefSource { get {return (dataLoad != null && dataLoad.FileType__c == DataLoadMethods.TYPE_REF_SOURCE );}}
   global Boolean isSfUpdate { get {return (dataLoad != null && dataLoad.FileType__c == DataLoadMethods.TYPE_SF_UPDATE );}}
   global Boolean isSfInsert { get {return (dataLoad != null && dataLoad.FileType__c == DataLoadMethods.TYPE_SF_INSERT );}}
   global Boolean isSfDelete { get {return (dataLoad != null && dataLoad.FileType__c == DataLoadMethods.TYPE_SF_DELETE );}}

   global void execute(SchedulableContext SC) {
      launchBatch();
   } // execute

   global Database.QueryLocator start(Database.BatchableContext BC){
      DataLoad__c[] dls = DataLoadMethods.getDataLoad(null, DataLoadMethods.STATUS_PROCESS, true);
      System.debug('DataLoadBatch2 start dls='+dls.size());
      if (!dls.isEmpty()) {
         dataLoad=dls[0];
      }
      /*
      // find a record to process. This should only be called if one is available. Only grab one at a time.
      try {
         dataLoad = [Select Id, Name, CreatedById, Exceptions__c
                           ,Campaign__c, FileType__c, HeaderRow__c
                           ,HeadersAreValid__c, NbrHeaders__c, NbrValidHeaders__c, NotifyOwner__c, OwnedBy__c
                           ,ProcessDataStart__c, ProcessDataEnd__c
                           ,ProcessNotes__c, Status__c, UpdateAPIObjectName__c
                       From DataLoad__c
                      Where Status__c = :DataLoadMethods.STATUS_PROCESS
                      Order by CreatedDate desc
                      limit 1];
      } catch (Exception e) {
         System.debug('Could not find a record to process.');
      }
      */
      Id dataLoadId = null;
      if (dataLoad != null) {
         dataLoadId = dataLoad.Id;
         dataLoad.ProcessDataStart__c = Datetime.now();
         dataLoad.ProcessDataEnd__c = null;
         dataLoad.Status__c=DataLoadMethods.STATUS_PROCESSSING;
         // so the status shows that it's processing when the user looks.
         DataLoadMethods.SKIP_TRIGGER=true;
         update dataLoad;
         DataLoadMethods.SKIP_TRIGGER=false;
       
         String[] tempHeaders = dataLoad.HeaderRow__c.split(',');
         headers = new String[]{};
         for (String tempHead : tempHeaders) {
            if (tempHead != null) {
               headers.add(tempHead.trim());
            } else {
               headers.add('');
            }
         }
         String[] headerValues = dataLoad.HeadersAreValid__c.split(','); 
         for (String val : headerValues) {
            validHeaders.add((val == 'Y'));
         }
         System.debug('DataLoadBatch2.start headers='+headers.size()+' validHeaders='+validHeaders.size());
       
         fieldMap = new Map<String, Schema.SObjectField>();
      
         // parse out the headers and prepare the data
         if (dataLoad.FileType__c == DataLoadMethods.TYPE_SF_UPDATE || dataLoad.FileType__c == DataLoadMethods.TYPE_SF_INSERT) {
            dataLoad.Status__c = DataLoadMethods.STATUS_UPDATE_SF;
            fieldMap = new ObjectHelper().getFieldMap(dataLoad.UpdateAPIObjectName__c);
         } else if (dataLoad.FileType__c == DataLoadMethods.TYPE_SF_DELETE) {
            dataLoad.Status__c = DataLoadMethods.STATUS_UPDATE_SF;
            Map<String, Schema.SObjectField> tempFieldMap = new ObjectHelper().getFieldMap(dataLoad.UpdateAPIObjectName__c);
            fieldMap = new Map<String, Schema.SObjectField>();
            if (tempFieldMap.containsKey('id')) {
               fieldMap.put('id',tempFieldMap.get('id'));
            }
            if (tempFieldMap.containsKey('Id')) {
               fieldMap.put('Id',tempFieldMap.get('Id'));
            }
         }
      } // if (dataLoad != null

      return Database.getQueryLocator([Select Id, Account__c, Contact__c, DataLoad__c, DataRow__c
                                             ,ErrorDetail__c, Lead__c, Referral_Account__c, Referral_Contact__c
                                             ,RowNbr__c, Status__c
                                         From DataLoadRecord__c
                                        Where DataLoad__c=:dataLoadId
                                          and Status__c=:DataLoadMethods.STATUS_PENDING
                                         Order by RowNbr__c ASC]);
   } // start
   
   global void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
      try {
         System.debug('execute currentMode='+currentMode+' scope='+scope.size());
         DataLoadRecord__c[] recs = (DataLoadRecord__c[])scope;
         if (isSfUpdate || isSfInsert || isSfDelete) {
            handleSfUpdate(recs);
         } else if (isLeadList) {
            handleLeadList(recs);
         } else if (isRefSource) {
            handleRefSource(recs);
         }
      } catch (Exception e) {
         fileSuccess = false;
         DataLoadMethods.addToExceptions(dataLoad,'execute exception: '+e.getMessage()+'; '+e.getStackTraceString());
      }
      // clear the variables between batches.
      clearVars();
   } // execute
    
   public void handleRefSource(DataLoadRecord__c[] recs) {
      Map<String,String> keyValueOverride = new Map<String,String>();
      // to call the accounts first
      keyValueOverride.put('OBJECT_TYPE','ALL');
      //handleCallout(recs, DataLoadMethods.REFERRAL_REQUEST, DataLoadMethods.SERV_REF_SRC, ObjectHelper.OBJECT_REF_ACCOUNT, keyValueOverride, false);
      handleCallout(recs, DataLoadMethods.REFERRAL_REQUEST, DataLoadMethods.SERV_REF_SRC, null, keyValueOverride, true);
      // check the responses. 
      // 
      System.debug('handleRefSource wrapsByDfId='+wrapsByDfId.size()+' wrapsBySfId='+wrapsBySfId.size());

   } // handleRefSource
    
   public void handleLeadList(DataLoadRecord__c[] recs) {
      handleCallout(recs, DataLoadMethods.VALIDATION_REQUEST, DataLoadMethods.SERV_VALIDATION, null, new Map<String,String>(), true);
   } // handleLeadList
    
   public AddFileQueueable afq = null;

   // for testing purposes
   public static HttpResponse testResp1 = null;
   public static HttpResponse testResp2 = null;
        
   // objFldsToUse - if we only want to send the fields for a certain ObjectName__c (in the custom metadata type)
   // keyValueOverride - if you want to override values (based on what's in the object or the custom metadata type) for certain keys
   public void handleCallout(DataLoadRecord__c[] recs, String msgType, String servType, String objFldsToUse, Map<String,String> keyValueOverride, Boolean saveRecs) {
      String filePref = (msgType == DataLoadMethods.REFERRAL_REQUEST ? 'RefSrc' : 'LeadVal');
      String noteType = (msgType == DataLoadMethods.REFERRAL_REQUEST ? 'Ref Src' : 'Validation');
       
      String firstRow=String.valueOf(Integer.valueOf(recs[0].RowNbr__c));
      String lastRow=String.valueOf(Integer.valueOf(recs[recs.size()-1].RowNbr__c));
      String rowString='_'+firstRow+'_'+lastRow+'_';
      String reqBody = DataLoadMethods.buildMsg(msgType, servType,headers,validHeaders, recs, objFldsToUse, keyValueOverride);
      String notes = noteType+' rows '+firstRow+'-'+lastRow+(String.isNotBlank(objFldsToUse) ? ' for '+objFldsToUse : '')+' Created, reqBody='+reqBody.length();
      //StringHelper.addToProcessNotes(dataLoad, noteType+' Request for '+firstRow+' to '+lastRow+(String.isNotBlank(objFldsToUse) ? ' for '+objFldsToUse : '')+' Created, reqBody='+reqBody.length());
       
      Boolean calloutSuccess = true;
      HttpResponse resp = null;
      if (String.isNotBlank(reqBody)) {
           
         String fileName = filePref+rowString+datetime.now().format('MMddyyyyHHmmss')+'.txt';
         // save the request to the parent record
         //if (afq == null) {
         //   afq = new AddFileQueueable(new Id[]{dataLoad.Id}, reqFileName, reqFileName, null, Blob.valueOf(reqBody));
         //} else {
         //   afq.addAnotherFile(new Id[]{dataLoad.Id}, reqFileName, reqFileName, null, Blob.valueOf(reqBody));
         //}

         //System.debug('handleCallout reqBody='+reqBody);
         HttpRequest req = DataFluxDeltaService.buildRequest(reqBody);
         Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
         Integer timeout = (abc != null && abc.Minutes_till_Launch__c != null ? Integer.valueOf(abc.Minutes_till_Launch__c * 1000) : 60000);
         req.setTimeout(timeout);
         Http ht = new Http();
         try {
            System.debug('handleCallout Test.IsRunningTest='+Test.isRunningTest());
            resp = (Test.isRunningTest() ? resp = testResp1 : ht.send(req));
         } catch (Exception e) {
            DataLoadMethods.addToExceptions(dataLoad,'handleCallout exception: '+e.getMessage()+'; '+e.getStackTraceString());
            System.debug('handleCallout exception: '+e);
         }
         calloutSuccess = (resp != null && resp.getStatusCode() == 200);
         String status=(resp != null ? 'Status='+resp.getStatus()+'; code='+resp.getStatusCode() : 'No Response!');
         notes += ', Response status='+status;
         System.debug('handleCallout status='+status);
         //StringHelper.addToProcessNotes(dataLoad, noteType+' Response for '+firstRow+' to '+lastRow+' Received, status='+status);
         StringHelper.addToProcessNotes(dataLoad, notes);
       
         if (calloutSuccess) {
            System.debug('handleCallout response='+status);
            //String respFileName = filePref+'Resp'+rowString+datetime.now().format('MMddyyyyHHmmss')+'.txt';
            //afq.addAnotherFile(new Id[]{dataLoad.Id}, respFileName, respFileName, null, resp.getBodyAsBlob());
            reqBody += '\n\n'+resp.getBody();
         }

         if (afq == null) {
            afq = new AddFileQueueable(new Id[]{dataLoad.Id}, fileName, fileName, null, Blob.valueOf(reqBody));
         } else {
            afq.addAnotherFile(new Id[]{dataLoad.Id}, fileName, fileName, null, Blob.valueOf(reqBody));
         }

         // success response - only process for the validation message
         if (calloutSuccess && msgType == DataLoadMethods.VALIDATION_REQUEST) {
            DataLoadMethods.DlrWrap[] wraps = DataLoadMethods.parseMsgResp(resp.getBody(), null, false);
            System.debug('handleCallout wraps='+wraps.size());
            // take the response of the previous message, and make a request for the next message.
            String nextMsg = DataLoadMethods.buildMsg2(DataLoadMethods.LEAD_REQUEST, DataLoadMethods.SERV_LEAD, wraps);
            notes = 'Lead Request for '+firstRow+' to '+lastRow+' Created reqBody='+nextMsg.length();
            //StringHelper.addToProcessNotes(dataLoad, 'Lead Request for '+firstRow+' to '+lastRow+' Created');
            String nextFileName = 'LeadMsg'+rowString+datetime.now().format('MMddyyyyHHmmss')+'.txt';
            //afq.addAnotherFile(new Id[]{dataLoad.Id}, req2FileName, req2FileName, null, Blob.valueOf(nextMsg));
            req = DataFluxDeltaService.buildRequest(nextMsg);
            req.setTimeout(60000);
            resp = null;
            try {
               resp = (Test.isRunningTest() ? resp = testResp2 : ht.send(req));
            } catch (Exception e) {
               System.debug('handleCallout exception: '+e);
               DataLoadMethods.addToExceptions(dataLoad,'handleCallout exception: '+e.getMessage()+'; '+e.getStackTraceString());
            }
            status=(resp != null ? 'Status='+resp.getStatus()+'; code='+resp.getStatusCode() : 'No Response!');
            calloutSuccess = (resp != null && resp.getStatusCode() == 200);
            notes += ', Response status='+status;
            //StringHelper.addToProcessNotes(dataLoad, 'Lead Response for '+firstRow+' to '+lastRow+' Received, status='+status);
            StringHelper.addToProcessNotes(dataLoad,notes);
            System.debug('handleCallout 2 response='+status);
            nextMsg += (resp != null ? '\n\n'+resp.getBody() : '');
            //String resp2FileName = 'LeadResp'+rowString+datetime.now().format('MMddyyyyHHmmss')+'.txt';
            afq.addAnotherFile(new Id[]{dataLoad.Id}, nextFileName, nextFileName, null, Blob.valueOf(nextMsg));
         }
      } // if (String.isNotBlank(reqBody)
       
      if (saveRecs) {
         afq.processRecs();
      }

      System.debug('handleCallout calloutSuccess='+calloutSuccess);
      if (calloutSuccess) {
         if (msgType == DataLoadMethods.REFERRAL_REQUEST) {
            handleRefSrcResponse(recs, resp, objFldsToUse);
         } else {
            handleLeadResponse(recs, resp);
         }
         if (saveRecs) {
            update recs;
         }
      } else {
         fileSuccess = false;
      }

   } // handleCallout
    
   public void clearVars() {
      afq = null;
      refAcctWraps.clear();
      upsertRefAccts.clear();
      upsertRefAcctMap.clear();
      updateRefAccts.clear();
      refAcctWraps2.clear();
      wrapsByDfId.clear();
      wrapsBySfId.clear();
   } // clearVars

   // public variables because we're going to 
   public DataLoadMethods.DlrWrap[] refAcctWraps = new DataLoadMethods.DlrWrap[]{};
   public Referral_Account__c[] upsertRefAccts = new Referral_Account__c[]{};
   // for easy access later - a map of only the referral accounts we're saving.
   public Map<String,DataLoadMethods.DlrWrap> upsertRefAcctMap = new Map<String,DataLoadMethods.DlrWrap>();

   public Referral_Account__c[] updateRefAccts = new Referral_Account__c[]{};
   public DataLoadMethods.DlrWrap[] refAcctWraps2 = new DataLoadMethods.DlrWrap[]{};
   public Map<Id,CampaignMember> insertCampMap = new Map<Id,CampaignMember>();

   // store the referral accounts by the dataflux id - this is used to requery the ref accts and set the ref acct id for the contacts 
   public Map<String,DataLoadMethods.DlrWrap[]> wrapsByDfId = new Map<String,DataLoadMethods.DlrWrap[]>();
   public Map<Id,DataLoadMethods.DlrWrap[]> wrapsBySfId = new Map<Id,DataLoadMethods.DlrWrap[]>();
    
   public void handleRefSrcResponse(DataLoadRecord__c[] recs, HttpResponse resp, String objName) {
      System.debug('handleRefSrcResponse Response='+resp.getBody());
      DataLoadMethods.DlrWrap[] wraps = DataLoadMethods.parseMsgResp(resp.getBody(), recs, true);
      Map<String,DataLoadMapping__mdt[]> mappingMap = DataLoadMethods.getDataMappingsByObject(DataLoadMethods.REFERRAL_RESPONSE);

      Map<String, Schema.SObjectField> refCtctFieldMap = Referral_Contact__c.sObjectType.getDescribe().fields.getMap();
      Map<String, Schema.SObjectField> refAcctFieldMap = Referral_Account__c.sObjectType.getDescribe().fields.getMap();
       
      // keep track of which records we're updating/upserting
      Set<String> updateUpsertKeys = new Set<String>();

      // store these in lists so they have a direct relation to each other and we can update
      // the wrappers from the save
      DataLoadMethods.DlrWrap[] ctctWraps = new DataLoadMethods.DlrWrap[]{};
      Referral_Contact__c[] upsertCtcts = new Referral_Contact__c[]{};
      DataLoadMethods.DlrWrap[] ctctWraps2 = new DataLoadMethods.DlrWrap[]{};
      Referral_Contact__c[] updateCtcts = new Referral_Contact__c[]{};
          
      for (DataLoadMethods.DlrWrap wrap : wraps) {
         processRfrlSrcResp(wrap, objName, mappingMap,refAcctFieldMap, refCtctFieldMap, updateUpsertKeys //, acctWraps,upsertAccts
                            //  ,ctctWraps, upsertCtcts, ctctWraps2, updateCtcts 
                            );
      }
      System.debug('handleRefSrcResponse upsertRefAccts='+upsertRefAccts.size()+' updateRefAccts='+updateRefAccts.size()+' upsertCtcts='+upsertCtcts.size()+' updateCtcts='+updateCtcts.size());
      // we don't want to save on the first pass because we can't have a DML transaction before another callout.
      //if (objName == ObjectHelper.OBJECT_REF_CONTACT) {
         // update records with Ids
         saveRecords(ObjectHelper.OBJECT_REF_ACCOUNT, refAcctWraps2, updateRefAccts);
         // upsert the records with dataflux ids.
         saveRecords(ObjectHelper.OBJECT_REF_ACCOUNT, refAcctWraps, upsertRefAccts, Referral_Account__c.Fields.Dataflux_Id__c);
         // after the account save, set the ids on the contact before save.
         for (DataLoadMethods.DlrWrap wrap : wraps) {
            if (wrap.refAcct != null && wrap.refAcct.Id != null && wrap.refCtct != null && wrap.refCtct.Referral_Account__c == null) {
               System.debug('handleRefSrcResponse setting the Referral_Account__c.Id');
               wrap.refCtct.Referral_Account__c = wrap.refAcct.Id;
            }
            if (wrap.refCtct != null && wrap.refCtct.Referral_Account__c == null) {
               // have to have a Referral Account in order to save the contact
               wrap.status='Account Not Found';
               wrap.dlr.Status__c='Error';
               wrap.dlr.ErrorDetail__c='Referral Account Not Found';
               DataLoadMethods.addToExceptions(dataLoad,'Row '+wrap.dlr.RowNbr__c+' Referral Account Not Found');
            } else if (wrap.refCtct != null) {
               if (wrap.refCtct.Id != null) {
                  ctctWraps2.add(wrap);
                  updateCtcts.add(wrap.refCtct);
               } else {
                  ctctWraps.add(wrap);
                  upsertCtcts.add(wrap.refCtct);
               } // if (wrap.refCtct.Id != null
            } // if (wrap.refCtct != null
         } // for (DataLoadMethods.DlrWrap wrap
         // update records with Ids
         Id[] refCtctIds1 = saveRecords(ObjectHelper.OBJECT_REF_ACCOUNT, ctctWraps2, updateCtcts);
         // upsert the record of the records
         Id[] refCtctIds = saveRecords(ObjectHelper.OBJECT_REF_CONTACT, ctctWraps, upsertCtcts, Referral_Contact__c.Fields.Dataflux_Id__c);
         refCtctIds.addAll(refCtctIds1);
         if (refCtctIds != null) {
            Referral_Contact__c[] reselectCtcts = [Select Id, Contact__c from Referral_Contact__c where Id in :refCtctIds and Contact__c != null];
            Id[] ctctIds = new Id[]{};
            for (Referral_Contact__c refCtct : reselectCtcts) {
               ctctIds.add(refCtct.Contact__c);
            }
            StringHelper.addToProcessNotes(dataLoad, 'refCtctIds='+refCtctIds.size()+' ctctIds='+ctctIds.size());
            createCampaignMembers(new Id[]{}, ctctIds);
         }
      //}
   } // handleRefSrcResponse
    
   public void handleLeadResponse(DataLoadRecord__c[] recs, HttpResponse resp) {
      DataLoadMethods.DlrWrap[] wraps = DataLoadMethods.parseMsgResp(resp.getBody(), recs, true);
      Map<String,DataLoadMapping__mdt[]> mappingMap = DataLoadMethods.getDataMappingsByObject(DataLoadMethods.LEAD_RESPONSE);

      Map<String, Schema.SObjectField> leadFieldMap = Lead.sObjectType.getDescribe().fields.getMap();
      Map<String, Schema.SObjectField> accountFieldMap = Account.sObjectType.getDescribe().fields.getMap();
      Map<String, Schema.SObjectField> ctctFieldMap = Contact.sObjectType.getDescribe().fields.getMap();
      
      // keep track of which records we're updating/upserting
      Set<String> updateUpsertKeys = new Set<String>();
       
      // store these in lists so they have a direct relation to each other and we can update
      // the wrappers from the save
      DataLoadMethods.DlrWrap[] leadWraps = new DataLoadMethods.DlrWrap[]{};
      Lead[] upsertLeads = new Lead[]{};
      DataLoadMethods.DlrWrap[] acctWraps = new DataLoadMethods.DlrWrap[]{};
      Account[] updateAccts = new Account[]{};
      DataLoadMethods.DlrWrap[] ctctWraps = new DataLoadMethods.DlrWrap[]{};
      Contact[] upsertCtcts = new Contact[]{};
      
      String errorMsg = '';
      for (DataLoadMethods.DlrWrap wrap : wraps) {
         if (wrap.respIsLead ) {
            processLeadResp(wrap, mappingMap.get(ObjectHelper.OBJECT_LEAD), leadFieldMap, updateUpsertKeys, leadWraps, upsertLeads);
         } else if (wrap.respIsCtct) {
            processCtctResp(wrap, mappingMap,accountFieldMap, ctctFieldMap, updateUpsertKeys, acctWraps,updateAccts, ctctWraps, upsertCtcts );
         } else {
            wrap.status='No Dataflux Id returned';
            errorMsg += '\nRow '+wrap.dlr.RowNbr__c+' No Dataflux Id returned';
         }
      } // for (DataLoadMethods.DlrWrap wrap
      if (String.isNotBlank(errorMsg)) {
         DataLoadMethods.addToExceptions(dataLoad,errorMsg);
      }
      
      Id[] leadIds = saveRecords(ObjectHelper.OBJECT_LEAD, leadWraps, upsertLeads, Lead.Fields.Dataflux_Id__c);
      Id[] ctctids = saveRecords(ObjectHelper.OBJECT_CONTACT, ctctWraps, upsertCtcts, Contact.Fields.Dataflux_Id__c);
      saveRecords(ObjectHelper.OBJECT_ACCOUNT, acctWraps, updateAccts);
      createCampaignMembers(leadIds, ctctIds);
   } // handleLeadResponse
    
   public void createCampaignMembers(Id[] leadIds, Id[] ctctids) {
      // if there's campaign associated with this
      if (dataLoad.Campaign__c != null && (!leadIds.isEmpty() || !ctctids.isEmpty())) {
         CampaignMember[] newCampMems = new CampaignMember[]{};
         for (Id leadId : leadIds) {
            CampaignMember newCM = new CampaignMember(LeadId=leadId, CampaignId=dataLoad.Campaign__c);
            newCampMems.add(newCM);
         }
         for (Id ctctId : ctctids) {
            CampaignMember newCM = new CampaignMember(ContactId=ctctId, CampaignId=dataLoad.Campaign__c);
            newCampMems.add(newCM);
         }
         if (!newCampMems.isEmpty()) {
            // we don't care if this fails because they might have already been inserted.
            //Database.insert(newCampMems,false);
            DmlHelper.performDML2(newCampMems, DmlHelper.DML_INSERT, CLASSNAME, 'createCampaignMembers', 'Insert Campaign Members', true);
         }
      } // if (dataLoad.Campaign__c != null
   } // createCampaignMembers
   /*
   public void saveRecords(DataLoadMethods.DlrWrap[] wraps, Lead[] upsertLeads) {
      System.debug('saveRecords wraps='+wraps.size()+' upsertLeads='+upsertLeads.size());
      if (!wraps.isEmpty() && !upsertLeads.isEmpty()) {
         Database.UpsertResult[] results = Database.Upsert(upsertLeads,Lead.Fields.Dataflux_Id__c, false);
         checkSaveResults(wraps, results);
      }
   } // saveRecords
   */

   // for just updating records
   public Id[] saveRecords(String objectName, DataLoadMethods.DlrWrap[] wraps, SObject[] updateRecs) {
      // to get the Salesforce ids of the records in case they need to be used
      Id[] recIds = new Id[]{};
      System.debug('saveRecords objectName='+objectName+' wraps='+wraps.size()+' updateRecs='+updateRecs.size());
      if (!wraps.isEmpty() && !updateRecs.isEmpty()) {
         // trying to speed up processing
         checkSkipTriggers();
         ChatterMessageSend.ONLY_CHAT_AS_LEAD_LOADER=false;
         Database.SaveResult[] results = DmlHelper.simpleUpdate(updateRecs);
         resetSaveTriggers();
         for (Integer cnt=0; cnt<results.size(); cnt++) {
            Database.SaveResult result = results[cnt];
            DataLoadMethods.DlrWrap wrap = wraps[cnt];
            if (result != null) {
               if (result.isSuccess()) {
                  recIds.add(result.getId());
               }
               logSaveResult(wrap,result.isSuccess(), false, result.getErrors(), updateRecs[cnt]);
            }
         } // for (Integer cnt=0
      }
      return recIds;
   } // saveRecords
    
   public void checkSkipTriggers() {
      if (dataLoad.SkipSaveTriggers__c) {
         ZipCheckOwner.SKIP_TRIGGERS=true;
         ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
         ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
         ReferralAccountMethods.SKIP_TRIGGERS=true;
         OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
         ReferralTriggerActions.SKIP_TRIGGER=true;
         OpptyLineItem.SKIP_TRIGGER=true;
         CadenceHelper.SKIP_TRIGGERS=true;
         TriggerMethods.SKIP_TRIGGERS=true;
      }
   } // checkSkipTriggers
    
   public void resetSaveTriggers() {
      ZipCheckOwner.SKIP_TRIGGERS=false;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
      ReferralAccountMethods.SKIP_TRIGGERS=false;
      OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
      ReferralTriggerActions.SKIP_TRIGGER=false;
      OpptyLineItem.SKIP_TRIGGER=false;
      CadenceHelper.SKIP_TRIGGERS=false;
      TriggerMethods.SKIP_TRIGGERS=false;
   } // resetSaveTriggers
    
   // for upserting records
   public Id[] saveRecords(String objectName, DataLoadMethods.DlrWrap[] wraps, SObject[] upsertRecs, Schema.sObjectField upsertFld) {
      System.debug('saveRecords objectName='+objectName+' wraps='+wraps.size()+' upsertRecs='+upsertRecs.size());
      if (!wraps.isEmpty() && !upsertRecs.isEmpty()) {
         ChatterMessageSend.ONLY_CHAT_AS_LEAD_LOADER=false;
         checkSkipTriggers();
         Database.UpsertResult[] results = DmlHelper.simpleUpsert(upsertRecs,upsertFld);
         resetSaveTriggers();
         return checkSaveResults(wraps, results, upsertRecs);
      }
      return new Id[]{};
   } // saveRecords

   public Id[] checkSaveResults(DataLoadMethods.DlrWrap[] wraps, Database.UpsertResult[] results, SObject[] upsertRecs) {
      // to get the Salesforce ids of the records in case they need to be used
      Id[] recIds = new Id[]{};
      for (Integer cnt=0; cnt<results.size(); cnt++) {
         Database.UpsertResult result = results[cnt];
         DataLoadMethods.DlrWrap wrap = wraps[cnt];
         if (result != null) {
            if (result.isSuccess()) {
               recIds.add(result.getId());
            }
            logSaveResult(wrap,result.isSuccess(), result.isCreated(), result.getErrors(), upsertRecs[cnt]);
         }
      } // for (Integer cnt=0
      return recIds;
   } // checkSaveResults
    
   public void processLeadResp(DataLoadMethods.DlrWrap wrap, DataLoadMapping__mdt[] mappings, Map<String, Schema.SObjectField> leadFieldMap, Set<String> updateUpsertKeys
                                  ,DataLoadMethods.DlrWrap[] leadWraps, Lead[] upsertLeads) {
      //String dfId = wrap.dataMap.get('LEAD_DF_UID');
      Lead ld = new Lead();
      setObjectData(ld, ObjectHelper.OBJECT_LEAD, wrap, mappings, leadFieldMap);
      // make sure the dataflux id is set
      if (ld.Dataflux_Id__c != null) {
         // last name cannot be blank on a save
         if (String.isBlank(ld.LastName)) {
            ld.LastName = UserHelper.UNKNOWN;
         }
         wrap.dlr.Dataflux_Id__c = ld.Dataflux_Id__c;
         if (updateUpsertKeys.contains(ld.Dataflux_Id__c)) {
            wrap.status='Duplicate In File';
            wrap.dlr.Status__c='Duplicate';
            wrap.dlr.ErrorDetail__c='Duplicate In File';
            DataLoadMethods.addToExceptions(dataLoad,'Row '+wrap.dlr.RowNbr__c+' Duplicate in File');
         } else {
            wrap.ld = ld;
            updateUpsertKeys.add(ld.Dataflux_Id__c);
            leadWraps.add(wrap);
            upsertLeads.add(ld);
         }
      } // if (ld.Dataflux_Id__c != null
   } // processLeadResp
    
   public void checkStandardFields(SObject rec, Map<String, Schema.SObjectField> fldMap) {
      // set the latest campaign if available on the object.
      if (fldMap.containsKey('LatestCampaign__c') && dataLoad.Campaign__c != null) {
         rec.put('LatestCampaign__c',dataLoad.Campaign__c);
      }
      if (fldMap.containsKey('LoadCampaign__c') && dataLoad.Campaign__c != null) {
          rec.put('LoadCampaign__c',dataLoad.Campaign__c);
      }
      if (fldMap.containsKey('OwnedBy__c') && dataLoad.OwnedBy__c != null) {
         rec.put('OwnedBy__c', dataLoad.OwnedBy__c);
      }
      if (fldMap.containsKey('NotifyOwner__c') && dataLoad.NotifyOwner__c) {
         rec.put('NotifyOwner__c',true);
      }
      if (fldMap.containsKey('LoadNotifyRep__c') && dataLoad.NotifyOwner__c) {
          rec.put('LoadNotifyRep__c','Yes');
      }
      if (fldMap.containsKey(CheckDataGovernance.DG_TYPE) && String.isNotBlank(dataLoad.UseDataGovernance__c)) {
          rec.put(CheckDataGovernance.DG_TYPE, dataLoad.UseDataGovernance__c);
      }
   } // checkStandardFields
    
   public void setObjectData(SObject rec, String objectName, DataLoadMethods.DlrWrap wrap, DataLoadMapping__mdt[] mappings, Map<String, Schema.SObjectField> fldMap) {
      checkStandardFields(rec, fldMap);

      // first, set the object on the fields passed in on the header
      for (Integer headerCnt=0; headerCnt < headers.size(); headerCnt++) {
         if (validHeaders[headerCnt]) {
            String headerName = headers[headerCnt].trim();
            String fldKey = headerName;
            // todo - change mapping on this
            // this is because the headernames don't match up to the field names and if the account isn't found then the contact fields aren't returned.
            if (objectName == ObjectHelper.OBJECT_REF_CONTACT) {
               fldKey = (headerName == 'FirstName' ? 'First_Name__c'
                            : (headerName == 'LastName' ? 'Last_Name__c'
                            : (headerName == 'Email' ? 'Email__c'
                            : (headerName == 'Phone' ? 'Phone__c'
                            : (headerName == 'Street' ? 'Mailing_Street__c'
                            : (headerName == 'City' ? 'Mailing_City__c'
                            : (headerName == 'State' ? 'Mailing_State__c'
                            : (headerName == 'PostalCode' ? 'Mailing_Postal_Code__c' : headerName))))))));
            }
            Schema.SObjectField fld = fldMap.get(fldKey);
            //System.debug('setObjectData headerName='+headerName+' fld='+fld);
            // look for the case of header containing object and field.   Contact.LeadSource
            if (fld == null && headerName.contains('.')) {
               Integer periodPos = headerName.indexOf('.');
               String checkObjectName = headerName.substring(0,periodPos);
               String checkFieldName = headerName.substring(periodPos+1);
               fld = ((fldMap.containsKey(checkFieldName) && checkObjectName == objectName) ? fldMap.get(checkFieldName) : null);
               //System.debug('setObjectData checkObjectName='+checkObjectName+' objectName='+objectName+' checkFieldName='+checkFieldName+' fld='+fld);
            } // if (fld == null && headerName.contains
            //String fldKey = (fld != null ? headerName.toLowerCase() : null); //fld.getDescribe().getName().toLowerCase() : null);
            //System.debug('setObjectData fldKey='+fldKey+' hasValue='+(fldKey != null && wrap.dataMap.containsKey(fldKey))+' hasValue='+wrap.dataMap.containsKey(headerName.toLowerCase()));
            if (fldKey != null) {
               Object valueAsObject = (wrap.dataMap.containsKey(headerName) ? ObjectHelper.formatStringAsObject(fld, wrap.dataMap.get(headerName)) : null);
               if (valueAsObject != null && fldKey == 'id') {
                  // make sure this is the id of the object we are saving. If not, clear the value.
                  String prefix = ObjectHelper.getObjectPrefix(objectName);
                  if (prefix != null && !((String)valueAsObject).startsWith(prefix)) {
                      System.debug('setObjectData clearing id field');
                      valueAsObject = null;
                  }
               } // if (valueAsObject
               System.debug('setObjectData 1 fldKey='+fldKey+' value='+valueAsObject);
               if (valueAsObject != null || dataLoad.UpdateNullValuesInline__c) {
                  System.debug('setObjectData 1 setting value');
                  rec.put(fld.getDescribe().getName(), valueAsObject);
               }

            } // if (fldKey != null
         } // if (validHeaders[headerCnt
      } // for (Integer headerCnt=0; headerCnt
          
      // set values returned from the response.
      for (DataLoadMapping__mdt mapping : mappings) {
         
         if (mapping.SFFieldName__c != null) {
            String fldData = wrap.dataMap.get(mapping.TagName__c);
            if (fldData != null) {
               Schema.SObjectField fld = fldMap.get(mapping.SFFieldName__c);
               Object valueAsObject = ObjectHelper.formatStringAsObject(fld, fldData);
               if (valueAsObject != null || dataLoad.UpdateNullValuesInline__c) {
                  System.debug('setObjectData 2 fld='+mapping.SFFieldName__c+' tag='+mapping.TagName__c+' value='+valueAsObject);
                  rec.put(mapping.SFFieldName__c, valueAsObject);
               }
            } // if (fldData != null
         } // if (mapping.SFFieldName__c != null
      } // for (DataLoadMapping__mdt mapping
   } // setObjectData
    
   public void processCtctResp(DataLoadMethods.DlrWrap wrap, Map<String,DataLoadMapping__mdt[]> mappingMap,Map<String, Schema.SObjectField> accountFieldMap, Map<String, Schema.SObjectField> ctctFieldMap
                                 ,Set<String> updateUpsertKeys
                                 ,DataLoadMethods.DlrWrap[] acctWraps, Account[] updateAccts
                                 ,DataLoadMethods.DlrWrap[] ctctWraps, Contact[] upsertCtcts) {
      Contact ctct = new Contact();  
      Account acct = new Account();
      setObjectData(ctct, ObjectHelper.OBJECT_CONTACT, wrap, mappingMap.get(ObjectHelper.OBJECT_CONTACT), ctctFieldMap);
      setObjectData(acct, ObjectHelper.OBJECT_ACCOUNT, wrap, mappingMap.get(ObjectHelper.OBJECT_ACCOUNT), accountFieldMap);
      if (ctct.Dataflux_Id__c != null) {
         if (String.isBlank(ctct.LastName)) {
            ctct.LastName = UserHelper.UNKNOWN;
         }
         wrap.dlr.Dataflux_Id__c = ctct.Dataflux_Id__c;
         if (updateUpsertKeys.contains(ctct.Dataflux_Id__c)) {
            wrap.status='Duplicate In File';
            wrap.dlr.Status__c='Duplicate';
            wrap.dlr.ErrorDetail__c='Duplicate In File';
            DataLoadMethods.addToExceptions(dataLoad,'Row '+wrap.dlr.RowNbr__c+' Duplicate in File');
         } else {
            wrap.ctct = ctct;
            updateUpsertKeys.add(ctct.Dataflux_Id__c);
            ctctWraps.add(wrap);
            upsertCtcts.add(ctct);
         }
      } // if (ctct.Dataflux_Id__c != null
      if (acct.Id != null && !updateUpsertKeys.contains(acct.Id)) {
         updateUpsertKeys.add(acct.Id);
         wrap.acct = acct;
         updateAccts.add(acct);
         acctWraps.add(wrap);
      }

   } // processCtctResp
    
   public void processRfrlSrcResp(DataLoadMethods.DlrWrap wrap, String objectName, Map<String,DataLoadMapping__mdt[]> mappingMap,Map<String, Schema.SObjectField> accountFieldMap, Map<String, Schema.SObjectField> ctctFieldMap
                                 ,Set<String> updateUpsertKeys
                                 //,DataLoadMethods.DlrWrap[] acctWraps, Referral_Account__c[] upsertAccts
                                 //,DataLoadMethods.DlrWrap[] ctctWraps, Referral_Contact__c[] upsertCtcts, DataLoadMethods.DlrWrap[] ctctWraps2, Referral_Contact__c[] updateCtcts
                                 ) {
      Referral_Contact__c ctct = new Referral_Contact__c();  
      Referral_Account__c acct = new Referral_Account__c();
      //if (objectName == ObjectHelper.OBJECT_REF_CONTACT) {
         setObjectData(ctct, ObjectHelper.OBJECT_REF_CONTACT, wrap, mappingMap.get(ObjectHelper.OBJECT_REF_CONTACT), ctctFieldMap);

      //} else if (objectName == ObjectHelper.OBJECT_REF_ACCOUNT) {
         setObjectData(acct, ObjectHelper.OBJECT_REF_ACCOUNT, wrap, mappingMap.get(ObjectHelper.OBJECT_REF_ACCOUNT), accountFieldMap);
      //}

      System.debug('processRfrlSrcResp acct='+acct);
      if (acct.Dataflux_Id__c != null) {
         acct.Use_Zip_Assignment_Rules__c=true;
         wrap.refAcct = acct;
         DataLoadMethods.DlrWrap[] wraps = (wrapsByDfId.containsKey(acct.Dataflux_Id__c) ? wrapsByDfId.get(acct.Dataflux_Id__c) : new DataLoadMethods.DlrWrap[]{});
         wraps.add(wrap);
         wrapsByDfId.put(acct.Dataflux_Id__c,wraps);
         
         // if the salesforce id is returned from dataflux, handle that differently because the dataflux id could be different.
         if (acct.Id != null) {
            System.debug('Setting id returned from DF: '+acct.Id);
            if (!updateUpsertKeys.contains(acct.Id)) {
               wraps = (wrapsBySfId.containsKey(acct.Id) ? wrapsBySfId.get(acct.Id) : new DataLoadMethods.DlrWrap[]{});
               wraps.add(wrap);
               wrapsBySfId.put(acct.Id,wraps);
               updateUpsertKeys.add(acct.Id);
                
               wrap.refAcct = acct;
               updateRefAccts.add(acct);
               refAcctWraps2.add(wrap);
               upsertRefAcctMap.put(acct.Id,wrap);
            } else {
               // set the referral account to be the first one with the same Id - so we can get it later after the save.
               DataLoadMethods.DlrWrap otherWrap = upsertRefAcctMap.get(acct.Id);
               wrap.refAcct = (otherWrap != null ? otherWrap.refAcct : acct);
            }
         } else if (!updateUpsertKeys.contains(acct.Dataflux_Id__c)) {
            System.debug('Setting Referral_Account__c info for '+acct.Dataflux_Id__c);
            updateUpsertKeys.add(acct.Dataflux_Id__c);
            wrap.refAcct = acct;
            upsertRefAccts.add(acct);
            refAcctWraps.add(wrap);
            upsertRefAcctMap.put(acct.Dataflux_Id__c,wrap);
         } else {
            // set the referral account to be the original one with the same Dataflux Id - so we can get it later after the save.
            DataLoadMethods.DlrWrap otherWrap = upsertRefAcctMap.get(acct.Dataflux_Id__c);
            wrap.refAcct = (otherWrap != null ? otherWrap.refAcct : acct);
         }
      }

      // see if we have any contact data
      Boolean hasCtct = (String.isNotBlank(ctct.Dataflux_Id__c) || String.isNotBlank(ctct.First_Name__c) || String.isNotBlank(ctct.Email__c) || String.isNotBlank(ctct.Phone__c));
      System.debug('processRfrlSrcResp hasCtct='+hasCtct+' ctct='+ctct);
      // if no dataflux id, we're just going to insert the record.
      if (hasCtct && ctct.Dataflux_Id__c != null && updateUpsertKeys.contains(ctct.Dataflux_Id__c)) {
         wrap.status='Duplicate In File';
         wrap.dlr.Status__c='Duplicate';
         wrap.dlr.ErrorDetail__c='Duplicate In File';
         DataLoadMethods.addToExceptions(dataLoad,'Row '+wrap.dlr.RowNbr__c+' Duplicate in File');
      //} else if (hasCtct && ctct.Referral_Account__c == null)
         // has to have Referral_Account__c set in order to save the contact
      } else if (hasCtct) {
         wrap.refCtct = ctct;
         String firstName = ctct.First_Name__c;
         String lastName = ctct.Last_Name__c;
         if (String.isBlank(lastName)) {
            lastName = UserHelper.UNKNOWN;
            ctct.Last_Name__c = UserHelper.UNKNOWN;
         }
         String fullName = (String.isNotBlank(firstName) ? firstName+' ' : '')+(String.isNotBlank(lastName) ? lastName : '');
         if (String.isNotBlank(fullName)) {
            ctct.Name = fullName;
         }
         if (ctct.Id != null) {
            updateUpsertKeys.add(ctct.Id);
            //ctctWraps2.add(wrap);
            //updateCtcts.add(ctct);
         } else {
            // if one doesn't return, default the id from the dlr record so we don't fail the upsert.
            if (ctct.Dataflux_Id__c == null) {
               ctct.Dataflux_Id__c = wrap.dlr.Id;
            }
            updateUpsertKeys.add(ctct.Dataflux_Id__c);
            //ctctWraps.add(wrap);
            //upsertCtcts.add(ctct);
         }
      }

   } // processRfrlSrcResp
    
   public void handleSfUpdate(DataLoadRecord__c[] recs) {
      String objectName = dataLoad.UpdateAPIObjectName__c;
      Schema.sObjectType objectDef = Schema.getGlobalDescribe().get(objectName).getDescribe().getSObjectType();
       
      SObject[] saveRecs = new SObject[]{};
      DataLoadMethods.DlrWrap[] allDwWraps = new DataLoadMethods.DlrWrap[]{};
      for (DataLoadRecord__c dlr : recs) {
          DataLoadMethods.DlrWrap dw = new DataLoadMethods.DlrWrap(dlr);
          dw.saveRec = parseData(dw,objectDef);
          System.debug('handleSfUpdate saveRec='+dw.saveRec);
          if (dw.saveRec != null) {
             saveRecs.add(dw.saveRec);
             allDwWraps.add(dw);
          } else {
             // log an error on the DataLoadRecord
             dw.dlr.Status__c=DataLoadMethods.STATUS_ERROR;
          }
      } // for
       
      if (!saveRecs.isEmpty()) {
         checkSkipTriggers();
         if (isSfUpdate || isSfInsert) {
            Database.SaveResult[] results = null;
            if (isSfUpdate) {
               results = DmlHelper.simpleUpdate(saveRecs);
            } else if (isSfInsert) {
               results = DmlHelper.simpleInsert(saveRecs);
            }
            // parse the results, mark dataload records
            for (Integer cnt=0; cnt<results.size(); cnt++) {
               Database.SaveResult result = results[cnt];
               DataLoadMethods.DlrWrap dw = allDwWraps[cnt];
               if (result != null) {
                  logSaveResult(dw,result.isSuccess(), (result.isSuccess() && isSfInsert), result.getErrors(),saveRecs[cnt]);
               }
            }
         } else if (isSfDelete) {
            Database.DeleteResult[] results = Database.delete(saveRecs,false);
            // parse the results, mark dataload records
            for (Integer cnt=0; cnt<results.size(); cnt++) {
               Database.DeleteResult result = results[cnt];
               DataLoadMethods.DlrWrap dw = allDwWraps[cnt];
               if (result != null) {
                  logSaveResult(dw,result.isSuccess(), false, result.getErrors(),saveRecs[cnt]);
               }
            }
         } // if (isSfUpdate || isSfInsert
         resetSaveTriggers();
      } // if (!saveRecs.isEmpty

      update recs;

   } // handleSfUpdate
   
   public static final Integer ERROR_DETAIL_LENGTH = DataLoadRecord__c.ErrorDetail__c.getDescribe().getLength();

   public void logSaveResult(DataLoadMethods.DlrWrap dw, Boolean isSuccess, Boolean isCreated, Database.Error[] errs, SObject rec) {
      if (dw != null) {
         dw.dlr.Success__c=isSuccess;
         dw.dlr.Created__c=isCreated;
         if (isSuccess) {
            dw.dlr.Status__c = DataLoadMethods.STATUS_SUCCESS;
            if (!isSfDelete) {
               setLoadRecordLookups(dw);
            }
         } else {
            dw.dlr.Status__c=DataLoadMethods.STATUS_ERROR;
            String errorStr = '';
            for (Database.Error err : errs) {
               errorStr += err.getMessage();
            }
            System.debug('logSaveResult errorStr='+errorStr+' rec='+rec);
            dw.dlr.ErrorDetail__c = errorStr.left(ERROR_DETAIL_LENGTH);
            DataLoadMethods.addToExceptions(dataLoad,'Row '+dw.dlr.RowNbr__c+' '+errorStr);
         }
      } // if (dw != null && result != null
   } // logSaveResult
    
   public void setLoadRecordLookups(DataLoadMethods.DlrWrap dw) {
      setLoadRecordLookup(dw,dw.saveRec);
      setLoadRecordLookup(dw,dw.ld);
      setLoadRecordLookup(dw,dw.acct);
      setLoadRecordLookup(dw,dw.ctct);
      setLoadRecordLookup(dw,dw.refAcct);
      setLoadRecordLookup(dw,dw.refCtct);
   } // setLoadRecordLookups
    
   public void setLoadRecordLookup(DataLoadMethods.DlrWrap dw, SObject checkRec) {
      if (checkRec != null && checkRec.Id != null) {
         SObjectType objType = checkRec.Id.getSObjectType();
         if (objType == Account.sObjectType) {
            dw.dlr.Account__c = checkRec.Id;
         } else if (objType == Contact.sObjectType) {
            dw.dlr.Contact__c = checkRec.Id;
         } else if (objType == Lead.sObjectType) {
            dw.dlr.Lead__c = checkRec.Id;
         } else if (objType == Referral_Account__c.sObjectType) {
            dw.dlr.Referral_Account__c = checkRec.Id;
         } else if (objType == Referral_Contact__c.sObjectType) {
            dw.dlr.Referral_Contact__c = checkRec.Id;
         }
      }
   } // setLoadRecordLookup
    
    
   private SObject parseData(DataLoadMethods.DlrWrap dw, Schema.sObjectType objectDef) {
      SObject newRec = objectDef.newSobject();
      String[] dataValues = DataLoadMethods.splitRow(dw.dlr.DataRow__c);
      // which columns are good and bad
      String[] validColumns = dataLoad.HeadersAreValid__c.split(',');

      // these should be equal - need to add a check here.
      System.debug('parseData headers='+headers.size()+' dataValues='+dataValues.size());
      // set the latest campaign if available on the object
      checkStandardFields(newRec, fieldMap);

      for (Integer colCnt=0; colCnt < headers.size(); colCnt++) {
          Boolean validHeader = (validColumns[colCnt] == 'Y');
          if (validHeader) {
             String header=headers[colCnt].trim();
             String data=dataValues[colCnt];
             if (String.isNotBlank(data)) {
                // if leading/trailing '"' remove
                if (data.startswith('"') && data.endsWith('"')) {
                   data = data.substring(1,data.length()-1);
                }
             } // if (String.isNotBlank
             Schema.SObjectField fldInfo = fieldMap.get(header);
             System.debug('parseData header='+header+' fldInfo='+(fldInfo != null ? 'Found' : 'Not Found'));
             if (fldInfo != null) {
                Object valueAsObject = ObjectHelper.formatStringAsObject(fldInfo, data);
                if (valueAsObject != null || dataLoad.UpdateNullValuesInline__c) {
                   System.debug('parseData header='+header+' valueAsObject='+valueAsObject);
                   newRec.put(header,valueAsObject);
                   dw.valuesFound++;
                }
             } // if (fldInfo != null
          } // if (validHeader
      } // for (String header
      return newRec;
   } // parseData
    
    
   global void finish(Database.BatchableContext batchableContext){
      // if no errors
      dataLoad.Status__c=(fileSuccess ? DataLoadMethods.STATUS_COMPLETE : DataLoadMethods.STATUS_ERROR);
      dataLoad.ProcessDataEnd__c = Datetime.now();
      dataLoad.InlineProcessed__c = [Select count() from DataLoadRecord__c where DataLoad__c=:dataLoad.Id and Status__c in ('Success','Error')];
      dataLoad.InlineNbrInserts__c = [Select count() from DataLoadRecord__c where DataLoad__c=:dataLoad.Id and Status__c = 'Success' and Created__c=true];
      dataLoad.InlineNbrUpdates__c = [Select count() from DataLoadRecord__c where DataLoad__c=:dataLoad.Id and Status__c = 'Success' and Created__c=false];
      dataLoad.InlineNbrSuccess__c = dataLoad.InlineNbrInserts__c + dataLoad.InlineNbrUpdates__c;

      update dataLoad;
      System.debug('DataloadBatch2 finish dataLoad status='+dataLoad.Status__c);
       
      // create an output file
      createOutputFile();
       
      // see if any other records are pending. Relaunch if there are. 
      //Integer nbrPending = [Select count() 
      //                        From DataLoad__c
      //                       Where Status__c=:DataLoadMethods.STATUS_PROCESS];
      //System.debug('DataLoadBatch2.finish nbrPending='+nbrPending);
      //if (nbrPending > 0) {
         launchBatch();
      //}   
   } // finish
    
   public static void launchBatch() {
      // retrieve the data load record with the earliest start time
      DataLoad__c[] dataLoads = [select Id, RequestStartTime__c from DataLoad__c Where Status__c = :DataLoadMethods.STATUS_PROCESS  order by RequestStartTime__c ASC nulls first limit 1 ];
      System.debug('DataLoadBatch2 launchBatch dataLoads='+dataLoads.size());
      if (!dataLoads.isEmpty()) {
         Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
         Integer nbrAllowedRunning = (abc != null  ? Integer.valueOf(abc.NbrOfAttempts__c) : 0);
         Datetime nextRunTime = (dataLoads[0].RequestStartTime__c != null ? dataLoads[0].RequestStartTime__c : Datetime.now());
         JobHelper.launchBatchWithSchedule(new DataLoadBatch2(), CLASSNAME, nextRunTime, nbrAllowedRunning);

      }
   } // launchBatch
    
   global void createOutputFile() {
      String headerRow = 'Status,'+dataLoad.HeaderRow__c+',Lead,Account,Contact,Referral Account,Referral Contact,Error Detail\n';
      String data = headerRow;
      for (DataLoadRecord__c[] dlrs : [Select Id, Account__c, Contact__c, DataLoad__c, DataRow__c
                                             ,ErrorDetail__c, Lead__c, Referral_Account__c, Referral_Contact__c
                                             ,RowNbr__c, Status__c
                                         From DataLoadRecord__c
                                        Where DataLoad__c=:dataLoad.Id
                                       Order by RowNbr__c]) {
         for (DataLoadRecord__c dlr : dlrs) {
            String dataRow = dlr.Status__c+','+dlr.DataRow__c+',';
            dataRow += (dlr.Lead__c != null ? String.valueOf(dlr.Lead__c) : '')+',';
            dataRow += (dlr.Account__c != null ? String.valueOf(dlr.Account__c) : '')+',';
            dataRow += (dlr.Contact__c != null ? String.valueOf(dlr.Contact__c) : '')+',';
            dataRow += (dlr.Referral_Account__c != null ? String.valueOf(dlr.Referral_Account__c) : '')+',';
            dataRow += (dlr.Referral_Contact__c != null ? String.valueOf(dlr.Referral_Contact__c) : '')+',';
            dataRow += (dlr.ErrorDetail__c != null ? '"'+dlr.ErrorDetail__c+'"' : '')+'\n';
            data += dataRow;
         }
      } // for (DataLoadRecord__c[] dlrs
      String outputFileName = dataLoad.Name+'_output_'+datetime.now().format('MMddyyyyHHmmss')+'.csv';
      AddFileQueueable afq = new AddFileQueueable(new Id[]{dataLoad.Id}, outputFileName, outputFileName, null, Blob.valueOf(data));
      ContentDocumentUtilities.SKIP_TRIGGER=true;
      afq.processRecs();
       
      try {
         dataLoad = [Select Id, Name, CreatedById
                           ,Campaign__c, FileType__c, HeaderRow__c
                           ,HeadersAreValid__c, NbrHeaders__c, NbrValidHeaders__c
                           ,NbrLoadRecords__c, NbrSuccess__c, NbrInserts__c, NbrUpdated__c
                           ,ProcessNotes__c, Status__c, UpdateAPIObjectName__c
                       From DataLoad__c
                      Where Id = :dataLoad.Id];
         String subject='File Processing for '+dataLoad.FileType__c+' '+dataLoad.Name+' Complete with '+dataLoad.NbrLoadRecords__c+' records';
         Integer nbrErrors = Integer.valueOf(dataLoad.NbrLoadRecords__c - dataLoad.NbrSuccess__c);
         String body = 'Total Records: '+dataLoad.NbrLoadRecords__c;
         body += '\nNumber Success: '+dataLoad.NbrSuccess__c;
         body += '\nNumber Errors: '+nbrErrors;
         body += '\nNumber Inserted: '+dataLoad.NbrInserts__c;
         body += '\nNumber Updated: '+dataLoad.NbrUpdated__c;
          
         String host = Utilities.getInstanceURL()+'/';
         String dataLoadUrl = host + '/lightning/r/' +  String.valueOf(dataLoad.Id) + '/view';
         body += '\n\nData Load record: '+dataLoadUrl;

         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         if (!afq.wrappersToProcess.isEmpty()) {
            mail.setEntityAttachments(new Id[]{afq.wrappersToProcess[0].conVersion.Id});
         }
         //mail.setTargetObjectId(UserInfo.getUserId());
         mail.setTargetObjectId(dataLoad.CreatedById);
         mail.setSaveAsActivity(false);
         mail.setSubject(subject);
         mail.setPlainTextBody(body);
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });       
      } catch (Exception e) {
         System.debug('createOutputFile exception: '+e.getMessage());
      }
   } // createOutputFile

} // class DataLoadBatch2