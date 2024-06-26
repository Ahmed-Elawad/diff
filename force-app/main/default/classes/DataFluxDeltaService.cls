/* 
 *  A class to send requests and receive responses from OSB Delta Service which handle update/insert 
 *  operations to Data Flux.  Also must handle when Account, Contact or Lead is deleted.
 *  must be @future to be async when called from trigger   
 * History
 * -------
 * 04/01/2014 Cindy Freeman     created
 * 05/27/2015 Cindy Freeman     set LeadMethods.LEAD_AFTER_EXECUTING to true to stop recursive Lead triggers
 * 02/04/2016 Cindy Freeman     add static list of Account Ids processed to stop recursive Account trigger creating 2 Web Svc Logs
 * 08/22/2016 Josh Cartwright   added new methods to build a message that can be sent directly to dataflux *
 * 03/22/2017 Cindy Freeman     added field to getContactMapbyAccountId query
   10/23/2017 Dan Carmen        Fix for Duplicate id in list error.
   05/23/2019 Dan Carmen        Add in code to skip the triggers on save
   06/10/2019 Dan Carmen        Disable steelbrick when saving results back from dataflux
   10/09/2020 Jake Hinds   Adding without sharing per PMD
   07/20/2021 Dan Carmen        Streamline update code, add dataflux fields to ref acct/ctct.
   02/10/2022 Josh Cartwright   add variable for timeout value to be used in the request. 
   02/21/2022 Josh Cartwright   changed update lists to maps to avoid dupelicates 
   03/08/2022 Dan Carmen        Set the Lead Dataflux Id to remove a workflow.
   01/30/2022 Dan Carmen        Update to allow future calls
   03/17/2024 Dan Carmen        Update to create the message only when it's actually sending it
   
 */
  
global without sharing class DataFluxDeltaService implements TriggerInterfaceC  {
   public static final String CLASSNAME='DataFluxDeltaService';
    
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs(CLASSNAME, p_recs, oldMap, isBefore, isAfter, null, null);
      System.debug('DataFluxDeltaService.handleTrigger recs='+(recs != null ? recs.size() : -1));
      if (recs == null || recs.isEmpty()) {
         return;
      }
      SObjectType objType = TriggerMethods.objType;
      System.debug('DataFluxDeltaService.handleTrigger objType='+objType);
      if (isBefore && isDelete && oldMap != null) {
         handleDeleteBefore(objType, oldMap.values());
      } else if (isAfter && isDelete) {
         handleDeleteAfter(objType, oldMap.values());
      } else if (isBefore) {
         if (objType == Account.sObjectType) {
            handleAcctsBefore((Account[])recs, (Map<Id,Account>)oldMap);
         } else if (objType == Contact.sObjectType) {
            handleCtctsBefore((Contact[])recs, (Map<Id,Contact>)oldMap);
         } else if (objType == Lead.sObjectType) {
            handleleadsBefore((Lead[])recs, (Map<Id,Lead>)oldMap);
         }
      }

   } // handleTrigger
    
   public void handleUndelete(String objectApiName, Map<Id,SObject> newMap) {
      System.debug('handleUndelete objectApiName='+objectApiName+' newMap='+(newMap != null ? newMap.size() : -1));
      // if records are undeleted, mark them to be picked up in the job
      if (objectApiName == ObjectHelper.OBJECT_ACCOUNT) {
         handleUndeleteAcct((Map<Id,Account>)newMap);
      } else if (objectApiName == ObjectHelper.OBJECT_CONTACT) {
         handleUndeleteCtct((Map<Id,Contact>)newMap);
      }
   } // handleUndelete
    
   public static void handleUndeleteCtct(Map<Id,Contact> newMap) {
      Contact[] updateCtcts = new Contact[]{};
      for (Contact ctct : newMap.values()) {
         if (!ctct.Dataflux_Force_Delta__c || String.isBlank(ctct.DatafluxSyncOperation__c)) {
            Contact updateCtct = new Contact(Id=ctct.Id, Dataflux_Force_Delta__c = true, DatafluxSyncOperation__c = ACTION_MODIFY
                                             ,DatafluxSyncTime__c = Datetime.now());
            updateCtcts.add(updateCtct);
         }
      } // for (Contact ctct : newMap
      saveRecordsSkipTrigs(updateCtcts);
   } // handleUndeleteCtct
    
   public static void handleUndeleteAcct(Map<Id,Account> newMap) {
      Account[] updateAccts = new Account[]{};
      for (Account acct : newMap.values()) {
         if (!acct.Dataflux_Force_Delta__c || String.isBlank(acct.DatafluxSyncOperation__c)) {
            Account updateAcct = new Account(Id=acct.Id, Dataflux_Force_Delta__c = true, DatafluxSyncOperation__c = ACTION_MODIFY
                                             ,DatafluxSyncTime__c = Datetime.now());
            updateAccts.add(updateAcct);
         }
      } // for (Account acct : newMap
      saveRecordsSkipTrigs(updateAccts);
      // check for any contacts associated with the accounts, make sure they get marked too.
      for (Contact[] ctcts : [Select Id, Dataflux_Force_Delta__c,DatafluxSyncOperation__c,DatafluxSyncTime__c
                                From Contact
                               Where AccountId in :newMap.keySet()]) {
         for (Contact ctct : ctcts) {
            ctct.Dataflux_Force_Delta__c = true;
            ctct.DatafluxSyncOperation__c = ACTION_MODIFY;
            ctct.DatafluxSyncTime__c = Datetime.now();
         } // for (Contact ctct : ctcts
         saveRecordsSkipTrigs(ctcts);

      } // for (Contact[] ctcts

   } // handleUndeleteAcct
    
   public static void handleDeleteAfter(SObjectType objType, SObject[] recs) {
      if (objType == Account.sObjectType) {
         Account[] accts = (Account[])recs;
         Id[] mergedAcctIds = new Id[]{};
         for (Account acct : accts) {
            if (acct.MasterRecordId != null) {     
               mergedAcctIds.add(acct.MasterRecordId);
            }
         }
         if (!deleteCtctMap.isEmpty()) {
            DatafluxSync__c[] upsertRecs = new DatafluxSync__c[]{};
            Map<Id,Contact> ctctUpdateMap = new Map<Id,Contact>();
            Map<Id,Contact> ctctMap = (!mergedAcctIds.isEmpty() ? getContactMapByAccountId(mergedAcctIds) : new Map<Id,Contact>());
            for (Contact ctctBefore : deleteCtctMap.values()) {
               Contact ctctAfter = ctctMap.get(ctctBefore.Id);
               if (ctctAfter == null) {
                  // the contact doesn't exist
                  DatafluxSync__c dfs = new DatafluxSync__c(ObjectId__c=ctctBefore.Id, OperationType__c=ACTION_DELETE
                                                      ,ReadyToSync__c=true, ReadyToSyncTime__c=Datetime.now(), ObjectAPIName__c=ObjectHelper.OBJECT_CONTACT
                                                      ,MirrorId__c=ctctBefore.Mirror_Ref_Ctct__c);
                  upsertRecs.add(dfs);
               } else {
                  // needs to be updated
                  if (ctctAfter.Dataflux_Force_Delta__c == false || ctctAfter.DatafluxSyncOperation__c!=ACTION_MODIFY) {
                     ctctAfter.Dataflux_Force_Delta__c=true;
                     ctctAfter.DatafluxSyncTime__c=Datetime.now();
                     ctctAfter.DatafluxSyncOperation__c=ACTION_MODIFY;
                     ctctUpdateMap.put(ctctAfter.Id,ctctAfter);
                  }
               }
            }
            saveSyncRecs(upsertRecs,'handleDeleteAfter');
            saveRecordsSkipTrigs(ctctUpdateMap.values());
         } // if (!deleteCtctMap.isEmpty
      } // if (objType == Account.sObjectType
   } // handleDeleteAfter
    
   // the contacts linked to the accounts that were deleted
   public static Map<Id,Contact> deleteCtctMap = new Map<Id,Contact>();
    
   public static void handleDeleteBefore(SObjectType objType, SObject[] recs) {
      deleteCtctMap.clear();
      Boolean isAcct = (objType == Account.sObjectType);
      Boolean isCtct = (objType == Contact.sObjectType);
      Boolean isLead = (objType == Lead.sObjectType);
      String mirrorFld = (isAcct ? 'Ref_Acct_Id__c' : (isCtct ? 'Mirror_Ref_Ctct__c' : null));
      String objName = (isAcct ? ObjectHelper.OBJECT_ACCOUNT : (isCtct ? ObjectHelper.OBJECT_CONTACT : (isLead ? ObjectHelper.OBJECT_LEAD : null)));
      DatafluxSync__c[] upsertRecs = new DatafluxSync__c[]{};
      Id[] acctIds = new Id[]{};
      for (SObject rec : recs) {
         if (isAcct) {
            acctIds.add(rec.Id);
         }
         DatafluxSync__c dfs = new DatafluxSync__c(ObjectId__c=rec.Id, OperationType__c=ACTION_DELETE
                                                      ,ReadyToSync__c=true, ReadyToSyncTime__c=Datetime.now(), ObjectAPIName__c=objName
                                                      ,MirrorId__c=(mirrorFld != null ? (String)rec.get(mirrorFld) : null));
         upsertRecs.add(dfs);
      }
      saveSyncRecs(upsertRecs,'handleDeleteBefore');
      if (!acctIds.isEmpty()) {
         // get the contacts linked to the accounts that were deleted.
         deleteCtctMap = getContactMapByAccountId(acctIds);
      }
   } // handleDeleteBefore
    
   public static void handleCtctsBefore(Contact[] ctcts, Map<Id,Contact> oldMap) {
      UserHelper.setRunningUserAttributes();
      Boolean isReferralSource = (ctcts != null && !ctcts.isEmpty() ? ctcts[0].Mirror_Ref_Ctct__c != null : false);
      Boolean isInsert = (oldMap == null);
      Boolean okayToSend = (!UserHelper.runningUserIsLeadLoader || (UserHelper.runningUserIsLeadLoader && isInsert && isReferralSource));

      System.debug('handleCtctsBefore okayToSend='+okayToSend+' isReferralSource='+isReferralSource+' isInsert='+isInsert);
      if (!okayToSend) {
         return;
      }
      
      for (Contact ctct : ctcts) {
         Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);
         if (oldCtct == null 
                || ctct.FirstName != oldCtct.FirstName
                || ctct.LastName != oldCtct.LastName
                || ctct.Email != oldCtct.Email
                || ctct.Phone != oldCtct.Phone
                || ctct.AccountId != oldCtct.AccountId
                || ctct.MailingStreet != oldCtct.MailingStreet
                || ctct.MailingCity != oldCtct.MailingCity
                || ctct.MailingState != oldCtct.MailingState
                || ctct.MailingPostalCode != oldCtct.MailingPostalCode
         ) {
            String opType = (oldCtct == null ? ACTION_INSERT
                               : (ctct.DatafluxSyncOperation__c != ACTION_INSERT ? ACTION_MODIFY : ctct.DatafluxSyncOperation__c));
            ctct.DatafluxSyncOperation__c = opType;
            ctct.Dataflux_Force_Delta__c = true;
            ctct.DatafluxSyncTime__c = Datetime.now();
         }
      } // for (Contact ctct : ctcts
    
   } // handleCtctsBefore

   public static void handleAcctsBefore(Account[] accts, Map<Id,Account> oldMap) {
      UserHelper.setRunningUserAttributes();
      Boolean isReferralSource = (accts != null && !accts.isEmpty() ? accts[0].Mirror_Referral_Account__c != null : false);
      Boolean isInsert = (oldMap == null);
      Boolean okayToSend = (!UserHelper.runningUserIsLeadLoader || (UserHelper.runningUserIsLeadLoader && isInsert && isReferralSource));
      System.debug('handleAcctsBefore okayToSend='+okayToSend+' isReferralSource='+isReferralSource+' isInsert='+isInsert);
      if (!okayToSend) {
         return;
      }
      for (Account acct : accts) {
         Account oldA = (oldMap != null ? oldMap.get(acct.Id) : null);
         if (oldA == null 
              || acct.Name != olda.Name
              || acct.BillingStreet != olda.BillingStreet
              || acct.BillingCity != olda.BillingCity
              || acct.BillingState != olda.BillingState
              || acct.BillingPostalCode != olda.BillingPostalCode
              || acct.Phone != olda.Phone
              || acct.ShippingStreet != olda.ShippingStreet
              || acct.ShippingCity != olda.ShippingCity
              || acct.ShippingState != olda.ShippingState
              || acct.ShippingPostalCode != olda.ShippingPostalCode) {
            String opType = (oldA == null ? ACTION_INSERT
                               : (acct.DatafluxSyncOperation__c != ACTION_INSERT ? ACTION_MODIFY : acct.DatafluxSyncOperation__c));
            acct.DatafluxSyncOperation__c = opType;
            acct.Dataflux_Force_Delta__c = true;
            acct.DatafluxSyncTime__c = Datetime.now();
         }

      } // for (Account acct : accts
   } // handleAcctsBefore
    
   public static void handleleadsBefore(Lead[] lds, Map<Id,Lead> oldMap) {
      System.debug('handleleadsBefore lds='+lds.size());
      for (Lead ld : lds) {
         Lead oldLd = (oldMap != null ? oldMap.get(ld.Id) : null);
         if (oldLd == null 
                || (ld.Lead_Company__c != null && ld.Lead_Company__c != oldLd.Lead_Company__c)
                || ld.FirstName != oldLd.FirstName
                || ld.LastName != oldLd.LastName
                || ld.Company != oldLd.Company
                || ld.Street != oldLd.Street
                || ld.City != oldLd.City
                || ld.State != oldLd.State
                || ld.PostalCode != oldLd.PostalCode
                || ld.Phone != oldLd.Phone
                || ld.Email != oldLd.Email) {
            System.debug('handleleadsBefore Name='+ld.Name+' df flds updated');
            String opType = (oldLd == null ? ACTION_INSERT
                               : (ld.DatafluxSyncOperation__c != ACTION_INSERT ? ACTION_MODIFY : ld.DatafluxSyncOperation__c));
            ld.DatafluxSyncOperation__c = opType;
            ld.Dataflux_Force_Delta__c = true;
            ld.DatafluxSyncTime__c = Datetime.now();

         } // if (oldLd == null
      } // for (Lead ld : lds
   } // handleleadsBefore
    
   public static void handleLeadsAfter(Lead[] lds, Map<Id,Lead> oldMap) {
      // only need to check on update
      if (oldMap != null) {
         DatafluxSync__c[] upsertRecs = new DatafluxSync__c[]{};
         for (Lead ld : lds) {
            Lead oldLd = (oldMap != null ? oldMap.get(ld.Id) : null);
            // if a lead is converted, mark as delete
            if (oldLd != null && ld.IsConverted && !oldLd.IsConverted) {
               DatafluxSync__c dfs = new DatafluxSync__c(ObjectId__c=ld.Id, OperationType__c=ACTION_DELETE
                                                      ,ReadyToSync__c=true, ReadyToSyncTime__c=Datetime.now(), ObjectAPIName__c=ObjectHelper.OBJECT_LEAD
                                                      ,MirrorId__c=null);
               upsertRecs.add(dfs);
            }
         } // for (Lead ld : lds
         saveSyncRecs(upsertRecs,'handleLeadsAfter');
      } // if (oldMap != null
   } // handleLeadsAfter
              
   public static void saveSyncRecs(DatafluxSync__c[] upsertRecs, String fromLocation) {
      if (!upsertRecs.isEmpty()) {
         DmlHelper.DmlResult dmlResult = DmlHelper.initializeDmlResult(upsertRecs, DmlHelper.DML_UPSERT, CLASSNAME, 'saveSyncRecs', 'upserting DatafluxSync__c '+fromLocation);
         Database.UpsertResult[] results = Database.upsert(upsertRecs,DatafluxSync__c.Fields.ObjectId__c,false);
         System.debug('saveSyncRecs results:'+results);
         DmlHelper.handleUpsertResults(upsertRecs, results, dmlResult);
      }

   } // saveSyncRecs

   public static final String ACTION_DELETE='DELETE';
   public static final String ACTION_MODIFY='UPDATE';
    //JC Added string for insert 
   public static final string ACTION_INSERT = 'INSERT';    
   
   public static string action = ''; 
           
   public Map<Id, dfResponse> dfResponseMap;  // parsed response
   public class dfResponse {
      public map <string, string> valueMap = new map <string, string>();
      public String sfdc_id {get; set;}                             // sfdc record id, could be lead, contact, acct
      public String df_id {get; set;}                               // dataflux id
      public String df_lg_id {get; set;}                            // lead group Id (company)
      public String completed {get; set;}                           // operation completed (true or false) 
      public String logId {get; set;}                               // web service log record that goes with this response
      public String reasoncode { get; set;}                         // reason code
   } // class dfResponse
   

   
   public static WebServiceSettings__c wss; 
   public static WebServicesHelper.WebServiceWrapper wsWrap;
   
   //JC new booleans for message 
   
   public static boolean matchIND; 
   public static boolean leadMatchIND;    
   public static boolean syncIND; 
   
   //JC string for results returned 
   
   public static string retMatches; 

   public static void setRequestValues() {
      wss = WebServicesHelper.getWebSvcSetting(WEBSERVICE_SETTING);
      matchIND = wss.Match_IND__c;
      leadMatchIND = wss.Lead_Match_IND__c; 
      syncIND = wss.Sync_IND__c; 
      retMatches = wss.Return_Matches__c;
   } // setRequestValues
   
   public static final String SERVICE_NAME='DFDeltaSvc';
   public static final String WEBSERVICE_SETTING='DataFlux Delta';
     
    // build request  
   public static HttpRequest buildRequest(String requestxml) {
        wss = WebServicesHelper.getWebSvcSetting(WEBSERVICE_SETTING);

        String username = '';
        String password = '';
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);  
        Integer timeoutValue = wss != null && wss.Timeout__c != null? integer.valueOf(wss.Timeout__c): 12000; 
     
        //construct an HTTP request
        HttpRequest req = new HttpRequest();
        if (wss!=null && wss.Endpoint__c!=null) {
           req.setEndpoint(wss.Endpoint__c);
        }
        req.setMethod('POST');        
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Length', string.valueOf(requestxml.length()));
        req.setHeader('Content-Type', 'text/xml; charset=utf-8');
        req.setHeader('SOAPAction', '"http://xml.paychex.com/paychex/corp/leadmanagementactivityorchestration/v1/ws/Change"');
        req.setHeader('Accept-Encoding', 'gzip');
        req.setHeader('WWW-Authenticate', 'BASIC realm=""');
        req.setTimeout(timeoutValue);          // cumulative max of 120,000 for all callouts in transaction
        //req.setClientCertificateName(wss.certificate__c);
        if (wss!=null && wss.Certificate__c!= null) {   
           system.debug('*****JC '+wss.Certificate__c);
           req.setClientCertificateName(wss.certificate__c);
        }
        req.setBody(requestxml);

        //System.debug('buildRequest request='+req);        
        return req;
    } // buildRequest
    
    // send Request 
    public static HttpResponse sendRequest(HttpRequest req) {
        Http http = new Http();
        HttpResponse resp =  new HttpResponse();
       try 
            {   resp = http.send(req);   
                System.debug('**CMF ** response status='+resp.getStatusCode());
                System.debug('**CMF ** response body='+resp.getBody());
            }                
            catch (CalloutException coEx)
            {   resp.setStatusCode(999);    
                resp.setStatus(coEx.getMessage());
                System.debug('**CMF ** DFDeltaSvc failed: ' + coEx);                     
            } // catch
            catch (Exception ex)
            {   resp.setStatusCode(999);    
                resp.setStatus(ex.getMessage());
                System.debug('**CMF ** DFDeltaSvc failed: ' + ex);                     
            } // catch
        //} // else (test.isRunningTest())
         
        return resp;
    } // sendRequest 
    
    
   public static List<String> processLeads(List<Id> leadIds, List<Lead> leads) {
      List<String> xmlList = new List<String>();
      
      system.debug('processLeads leads='+leads.size()); 
      if (leads != null && !leads.isempty()) {
         xmlList.add(createLeadFieldDefinitions());
        
         for (Lead ld : leads) {
            String xml = CreateLeadRequest(ld);            // JC *** Replaced createLeadXml(ld);
            xmlList.add(xml);
         } // for (Lead ld
         string endT = endTag(); 
         xmlList.add(endT); //jc adding end tag to message
      } // if (leads != null
      return xmlList;
      
   } // processLeads
       
   public static Map<Id,Contact> getContactMapByAccountId(Id[] acctIds) {
      Map<Id,Contact> ctctMap = new Map<Id,Contact>([Select Id, AccountId, FirstName, LastName, DatafluxSyncOperation__c, DatafluxSyncTime__c
                                                           ,Mirror_Ref_Ctct__c, Ref_Contact_ID__c, DataFlux_Id__c, DataFlux_Force_Delta__c 
                                                       from Contact where AccountId in :acctIds]);
      return ctctMap;
   } // getContactMapByAccountId
   
   public static List<String> processContacts(Id[] ctctIds, List<Contact> ctcts) {
      List<String> xmlList = new List<String>();
      
      if (ctcts != null && !ctcts.isEmpty()) {
         xmlList.add(createCntctFieldDefinitions());  
        
         for (Contact ctct : ctcts) {
            String xml =  createCntctRequest(ctct); // JC **replaced createContactXml(ctct);
            xmlList.add(xml);
         }
         string endT = endTag(); 
         xmlList.add(endT);  //jc adding end tag to message
      } // if (ctcts != null
      return xmlList;
   } // processContacts
    
   public static List<String> processAccounts(List<Id> acctIds, List<Account> accts) {
      List<String> xmlList = new List<String>();
            
      if (accts != null && !accts.isEmpty()) {
         xmlList.add(createAcctFieldDefinitions());   //JC added to build the datatable 
          
        for (Account acct : accts) {
            String xml = CreateAcctRequest(acct);   //JC **replaced createAccountXml(acct);
            xmlList.add(xml);
         }
         string endT = endTag(); 
         xmlList.add(endT);  //jc adding end tag to message 
      } // if (accts != null
      return xmlList;
   } // processAccounts
   

    private static String checkValue(String valueToCheck) {
       String newValue = (String.IsBlank(valueToCheck) ? '' : valueToCheck.replaceAll('&', '&amp;'));   
       newValue = (String.IsBlank(newValue) ? '' : newValue.replaceAll('<image004.jpg>',''));
       return newValue;
       
    }

          
   //JC handle the new response 
   public static Map<id, dfResponse> processResponse2(String xmlResponse, String akshun, Id logId, Web_Service_Log__c log) {
      String[] fieldNames = parseFieldDef(xmlResponse); // list to add all field names to 
      if (!fieldNames.isEmpty()) {
         return (getResponseValueMap (xmlResponse, fieldNames, logid, log)); //will store fieldnames as key, and data row as value  
                    
      }//!empty fieldNames 
            
      return new Map<id, dfResponse>();
       
   } //processResponse2 
    
   public static string [] parseFieldDef (string xmlResponse) {
      Integer startIdx = xmlResponse.indexOf('<fieldDefinitions>');
      string [] fieldNames = new string []{}; //define array to return
      system.debug ('JC first Start Index' +startIdx); 
      
      if (startIdx <> -1) {    
         While (startIdx <> -1) {
            integer endIdx = xmlResponse.indexOf('</fieldDefinitions>', startIdx);         
            string partialXML = xmlResponse.substring(startIdx, endIdx);
                
            Integer FNStartIdx = partialXML.indexOF('<fieldName>')+11; 
            Integer FNEndIDX = partialXML.indexOf('</fieldName>');
            string FNXML = partialXML.substring(FNStartIdx, FNEndIDX ); 
                
            if (string.isNotBlank (FNXML)){
               fieldNames.add(FNXML);
            } else {
               fieldNames.add ('NoHeader'); 
            }//else
                
            // within the partialXml, find <fieldName> and </fieldName> and pull out the substring between them
            // this substring would go into your list fieldNames.add(fieldName);
            // before adding to the list, make sure it's a non-blank value - if it is an empty string, add "NOHEADER"
            //system.debug('JC FNXML' + FNXML);
            //system.debug('JC endIdx: ' + endIdx);
            startIdx = xmlResponse.indexOf('<fieldDefinitions>', endIdx);
            //system.debug ('JC Second Start Index' +startIdx); 
                
         }//While
                       
      }//if    
        
      return fieldNames; 
   }//parseFieldDef    


   public static map <id, dfResponse> getResponseValueMap (String xmlResponse, String[] fieldNames, Id logId, Web_Service_Log__c log) {    
 
      map<id, dfresponse> responseMap = new map <id, dfResponse>(); 
           
      //separate methods 
      //parse dataRows 
      integer startIdx = xmlResponse.indexOf('<dataRows>'); 
      // valueMap 
      if (startIdx <> -1) {  
         while (startIdx <> -1) {
            Integer endIdx = xmlResponse.indexOf('</dataRows>', startIdx);         
            string partialXML = xmlResponse.substring(startIdx, endIdx); // removed prefixXML + 
        
            Map<String,String> valueMap = new map <string, string>(); 
                
            Integer positionCounter = 0;
            // new stuff to try
            String[] values = partialXML.split('</value>');
            system.debug ('JC values size ' + values.size());
                
            for (String value : values) {
               Integer valueStrtIdx = value.indexOf('<value>');
               system.debug('JC Value = '+ value + '  valuestring index = ' + valueStrtIdx );
                   
               IF (valueStrtIdx != -1) {
                  String valueSubstr = value.subString(valueStrtIdx+7);
                  system.debug ('JC valuemap entries ' + fieldNames[positionCounter]  +'  ' + valueSubstr);                       
                      
                  if(String.isNotBlank(valueSubstr)) {
                     valuemap.put(fieldNames[positionCounter], valueSubstr); 
           //        System.debug('getResponseValueMap add to map key='+fieldNames[positionCounter]+' valueSubStr='+valueSubStr);
                  }//if   
                  positionCounter++;
               }
            } // for
            //JC populate the Web Service Log information 
            //system.debug('JC value of valuemap.getid: ' +valuemap.get('SFDC_ID'));                
                
            try{
               id sfdcid = (id)valuemap.get('SFDC_ID');
               dfResponse resp = new dfResponse();
               resp.valueMap = valueMap;
               resp.sfdc_id = sfdcid; 
               resp.df_id = valuemap.get('DF_UID');     
               resp.df_lg_id = valuemap.get('DF_LG_ID');
               resp.completed = valuemap.get('RECORD_PROCESSED');
               resp.logid = logId; 
               resp.reasoncode = valuemap.get('ERROR_MESSAGE'); 
               if(sfdcID != null){
                  responseMap.put(sfdcId,resp);
               } else {
                  log.ErrorMsg__c = 'NO SFDC ID FOUND IN RESPONSE'; 
                  return new Map<id, dfResponse>(); 
               }//else 
            } catch (Exception e){
               System.debug('getResponseValueMap exception: '+e.getMessage()+'; '+e.getStackTraceString());
            }//catch 
                
            startIdx = xmlResponse.indexOf('<dataRows>',endIdx);
         }//while
      }//if 
      // eventually add in a check for the number of headers to equal the number of values.
      system.debug('getResponseValueMap responseMap='+responseMap.size());
      return responseMap; 
   }//getResponseValueMap
    

    
    /* take dataflux responses and update dataflux_id and leadgroup_id fields on leads and contacts and companies
       only for records where operationcompleted = true
     */
    public static Boolean updateRecs(Map<Id, dfResponse> dfMap, String objectName, SObject[] recs) {
       Boolean okay = true;
       System.debug('updateRecs objectName='+objectName+' recs='+recs.size()+' dfMap='+dfMap.size());
       if (objectName == ObjectHelper.OBJECT_ACCOUNT) {
          updateAccts((Account[])recs,dfMap);
       } else if (objectName == ObjectHelper.OBJECT_CONTACT) {
          updateCtcts((Contact[])recs,dfMap);
       } else if (objectName == ObjectHelper.OBJECT_LEAD) {
          updateLeads((Lead[])recs, dfMap);
       }
       return okay;
    } // updateRecs
    
    public static Boolean updateAccts(Account[] recs, Map<Id, dfResponse> dfMap) {
       Map<Id,Account> updateMap = new Map<Id,Account>();
       Map<Id,Referral_Account__c> updateRefMap = new Map<Id,Referral_Account__c>();
       Boolean okay = true;
       for (Account acct : recs) {
          dfResponse resp = dfMap.get(acct.Id);
          if (resp != null) {
             Account updateAcct = new Account(Id=acct.Id);
             if (checkObjectForUpdate(acct, updateAcct, resp, false)) {
                updateMap.put(updateAcct.id, updateAcct); 
             }
             if (acct.Mirror_Referral_Account__r != null) {
                Referral_Account__c updateRefAcct = new Referral_Account__c(Id=acct.Mirror_Referral_Account__r.Id);
                if (checkObjectForUpdate(acct.Mirror_Referral_Account__r, updateRefAcct, resp, true)) {
                   updateRefMap.put(updateRefAcct.Id,updateRefAcct); 
                }
             }

          }
       } // for (Account acct : recs
       System.debug('updateAccts updateMap='+updateMap.size()+' updateRefMap='+updateRefMap.size());
       saveRecordsSkipTrigs(updateMap.values());
       saveRecordsSkipTrigs(updateRefMap.values());

       return okay;
    } // updateAccts
    
    public static void saveRecordsSkipTrigs(SObject[] recs) {
       if (!recs.isEmpty()) {
          ZipCheckOwner.SKIP_TRIGGERS=true;
          ReferralAccountMethods.SKIP_TRIGGERS = true;
          ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
          ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
          LeadMethods.LEAD_BEFORE_EXECUTING=true;
          LeadMethods.LEAD_AFTER_EXECUTING = true;
          Database.update(recs,false);
          ZipCheckOwner.SKIP_TRIGGERS=false;
          ReferralAccountMethods.SKIP_TRIGGERS = false;
          ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = false;
          ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = false;
          LeadMethods.LEAD_BEFORE_EXECUTING=false;
          LeadMethods.LEAD_AFTER_EXECUTING = false;
       }
    } // saveRecordsSkipTrigs
     
    public static Boolean updateCtcts(Contact[] recs, Map<Id, dfResponse> dfMap) {
       Map<Id,Contact> updateMap = new Map<Id,Contact>();
       Map<Id,Referral_Contact__c> updateRefMap = new Map<Id,Referral_Contact__c>();
       Boolean okay = true;
       for (Contact ctct : recs) {
          dfResponse resp = dfMap.get(ctct.Id);
          if (resp != null) {
             Contact updateCtct = new Contact(Id=ctct.Id);
             if (checkObjectForUpdate(ctct, updateCtct, resp, false)) {
                updateMap.put(updateCtct.id, updateCtct); 
             }
             if (ctct.Mirror_Ref_Ctct__r != null) {
                Referral_Contact__c updateRefCtct = new Referral_Contact__c(Id=ctct.Mirror_Ref_Ctct__r.Id);
                if (checkObjectForUpdate(ctct.Mirror_Ref_Ctct__r, updateRefCtct, resp, true)) {
                   updateRefMap.put(updateRefCtct.Id,updateRefCtct); 
                }
             }

          }
       } // for (Contact ctct : recs
       System.debug('updateCtcts updateMap='+updateMap.size()+' updateRefMap='+updateRefMap.size());
       saveRecordsSkipTrigs(updateMap.values());
       saveRecordsSkipTrigs(updateRefMap.values());
       return okay;
    } // updateCtcts
    
    public static Boolean updateLeads(Lead[] lds, Map<Id, dfResponse> dfMap) {
       Map<Id,Lead> updateMap = new Map<Id,Lead>();
       Boolean okay = true;
       for (Lead ld : lds) {
          dfResponse resp = dfMap.get(ld.Id);
          if (resp != null) {
             Lead updateLead = new Lead(Id=ld.Id);
             if (checkObjectForUpdate(ld, updateLead, resp, false)) {
                updateMap.put(updateLead.id, updateLead); 
             }
          } // if (resp != null
       } // for (Lead ld : lds
       System.debug('updateCtcts updateMap='+updateMap.size());
       saveRecordsSkipTrigs(updateMap.values());

       return okay;
    } // updateLeads

   public static Boolean checkObjectForUpdate(SObject sourceObject, SObject updateObject, dfResponse dfResp, Boolean isRefSource) {
      Boolean needsUpdate = false; 
      if (dfResp != null) {
         try {
            Boolean forceDelta = (Boolean)sourceObject.get('Dataflux_Force_Delta__c');
            String dfId = dfResp.df_id;
            String objDfId = (String)sourceObject.get('DataFlux_Id__c');
            String dfShipStreet = dfResp.valueMap.get('SHIPPING_ADDR_MATCHCODE1_STREET1');
            String dfBillStreet = dfResp.valueMap.get('BILLING_ADDR_MATCHCODE1_STREET1'); 
            String dfName = dfResp.valueMap.get('NAME_MATCHCODE1'); 
            String objShipStreet = (String)sourceObject.get('Dataflux_Shipping_Address_MatchCode__c');
            String objBillStreet = (String)sourceObject.get('Dataflux_Billing_Address_MatchCode__c');
            String objName = (String)sourceObject.get('Dataflux_Name_MatchCode__c');
            if (forceDelta
                || (dfId != objDfId)
                || (dfShipStreet != objShipStreet)
                || (dfBillStreet != objBillStreet)
                || (dfName != objName)) {
               needsUpdate=true;
               updateObject.put('Dataflux_Force_Delta__c',false);
               updateObject.put('DataFlux_Id__c',dfId);
               updateObject.put('Dataflux_Shipping_Address_MatchCode__c',objShipStreet);
               updateObject.put('Dataflux_Billing_Address_MatchCode__c',objBillStreet);
               updateObject.put('Dataflux_Name_MatchCode__c',objName);
               if (!isRefSource) {
                  updateObject.put('DatafluxSyncTime__c',null);
                  updateObject.put('DatafluxLastSyncTime__c',Datetime.now());
                  updateObject.put('DatafluxSyncOperation__c',null);
               }     
            }
         } catch (Exception e) {
            System.debug('checkObjectForUpdate e='+e.getMessage()+'; '+e.getStackTraceString());
         }

      } // if (dfResp != null
      System.debug('checkObjectForUpdate needsUpdate='+needsUpdate);
      return needsUpdate;
   } // checkObjectForUpdate

    
           
    // if DataFluxDeltaBatch apex job isnt already scheduled or running, kick it off 
    public static void kickOffBatchJob() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(DataFluxDeltaBatch.CLASSNAME);
      if (abc != null && abc.Active__c) {
         scheduleBatchJob();
      }
    } // kickOffBatchJob
   
   public static void scheduleBatchJob() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(DataFluxDeltaBatch.CLASSNAME);
      Integer nbrMinutes = (abc != null && abc.Minutes_till_Launch__c != null ? abc.Minutes_till_Launch__c.intValue() : 5);
      //Integer nbrMinutes = (wss != null && wss.IntervalMinutes__c != null ? wss.IntervalMinutes__c.intValue() : 5);
      Datetime nextLaunchTime = Datetime.now().addMinutes(nbrMinutes);
      JobHelper.launchBatchWithSchedule(new DataFluxDeltaBatch(), DataFluxDeltaBatch.CLASSNAME, nextLaunchTime, 1);
   } // scheduleBatchJob


            
   public static Map<String,Schema.RecordTypeInfo> byId = null; 
   
   public static List<Id> datafluxCtctIdList = new List<Id>();
   public static List<Contact> dataFluxCtObjList = new List<Contact>();
   
   public static List<Id> datafluxIdList = new List<Id>();
   public static List<Account> dataFluxObjList = new List<Account>();     
    
  
   /** check if field values changed 
   */ 
   public static Boolean checkFldsChanged(String newFld, String oldFld) {
      Boolean changed = (newFld != oldFld);
      return changed;
   } // checkFldschanged
   
   //******JC new Code starts here******* 
   
 //create the column field definitions for the account request 
   public static String createAcctFieldDefinitions(){
    string acctFieldDefMessage = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:arc="archserver.xsd.dataflux.com">';
    acctFieldDefMessage+= '<soapenv:Header/>';
    acctFieldDefMessage+= '<soapenv:Body>';     
    acctFieldDefMessage+='<arc:SendArchitectServiceRequest>';  
    acctFieldDefMessage+='<serviceName>';
    acctFieldDefMessage+= 'SFDC_Account_Wrapper.ddf';
//    acctFieldDefMessage+= 'SFDC_Account_Wrapper_SPEED.ddf';
    acctFieldDefMessage+='</serviceName>';
    
    acctFieldDefMessage+= '<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>REQUESTID</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>RECORD_OPERATION</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>15</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
    //JC Added Sync indicator 
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>SYNCH_IND</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>15</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
    //JC added Match indicator 
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>MATCH_IND</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>15</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
        //JC added return matches indicator 
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>RETURN_MATCHES</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';

    acctFieldDefMessage+='<fieldDefinitions>';  
    acctFieldDefMessage+='<fieldName>ACCT_SFDCID</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';

    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>COMPANY</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>'; 
    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>Phone</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>'; 
        
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>STREET</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>CITY</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>STATE</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>POSTALCODE</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
    acctFieldDefMessage+='<fieldDefinitions>';  
    acctFieldDefMessage+='<fieldName>PROSPECT_CLIENT_NUMBER</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    /*
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>ACCOUNT_TYPE</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
*/
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>BIS_ID</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>'; 
    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>FED_ID</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>'; 
    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>shipping_address</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>shipping_city</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>shipping_state</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>shipping_postal_code</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>REF_BUSINESS_TYPE_PAR</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>REF_ACCT_ID</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';
    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>REF_ORG_ID</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>'; 
/*    
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>LAST_UPDATED_DT</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>';     
*/
    acctFieldDefMessage+='<fieldDefinitions>';
    acctFieldDefMessage+='<fieldName>DF_UID</fieldName>';
    acctFieldDefMessage+='<fieldType>STRING</fieldType>';
    acctFieldDefMessage+='<fieldLength>255</fieldLength>';
    acctFieldDefMessage+='</fieldDefinitions>'; 

        
    return acctFieldDefMessage; 
   }//createAcctFieldDefinitions
   
   
   //** add in checkvalue to all datarows 
   public static string CreateAcctRequest(Account acct){
    string acctRequest = '<dataRows>';
    acctRequest += '<value>' +acct.Id+ '</value>'; //request id 
    acctRequest += '<value>' +acct.DatafluxSyncOperation__c+ '</value>'; //record operation 
    acctRequest += '<value>' +syncIND + '</value>'; // run sync?
    acctRequest += '<value>' +matchIND + '</value>'; // run match? 
    acctRequest += '<value>' +checkValue(retMatches) + '</value>'; // return Matches -
    acctRequest += '<value>' +acct.Id + '</value>'; 
    acctRequest +='<value>' +checkValue(acct.Name) + '</value>'; 
    acctRequest +='<value>' +checkValue(acct.Phone) + '</value>'; 
    acctRequest +='<value>' +checkValue(acct.BillingStreet) + '</value>'; 
    acctRequest +='<value>' +checkValue(acct.BillingCity) + '</value>'; 
    acctRequest +='<value>' +checkValue(acct.BillingState) + '</value>'; 
    acctRequest +='<value>' +checkValue(acct.BillingPostalCode) + '</value>';
    acctRequest +='<value>' +checkValue(acct.AccountNumber) + '</value>'; 
   // acctRequest +='<value>' +checkValue(acct.Type) + '</value>';   
    acctRequest +='<value>' +(acct.Bis_ID__c==null?'':String.valueOf(acct.Bis_ID__c))+ '</value>'; 
    acctRequest +='<value>' +checkValue(acct.Federal_ID_Number__c) + '</value>';    
    acctRequest +='<value>' +checkValue(acct.ShippingStreet) + '</value>'; 
    acctRequest +='<value>' +checkValue(acct.ShippingCity) + '</value>'; 
    acctRequest +='<value>' +checkValue(acct.ShippingState) + '</value>'; 
    acctRequest +='<value>' +checkValue(acct.ShippingPostalCode) + '</value>'; 
    acctRequest +='<value>' +checkValue(acct.Referral__c) + '</value>'; 
    acctRequest +='<value>' +checkValue(acct.Ref_Acct_ID__c) + '</value>'; 
    acctRequest +='<value>' +checkValue(acct.Referral_ORG_ID__c) + '</value>'; 
    System.debug('CreateAcctRequest Dataflux_Id__c='+acct.Dataflux_Id__c+'. acct.Id='+acct.Id+'.');
    acctRequest += '<value>' + (String.isBlank(acct.Dataflux_Id__c) ? string.ValueOF(acct.Id) : checkValue(acct.Dataflux_Id__c)) + '</value>';  
          

   
    acctRequest += '</dataRows>'; 
   
//remove from each, make static variable attach at the end 

    return acctRequest;     

   }//createAcctRequest
    
   //create the column field definitions for the contact request 
   private static String createCntctFieldDefinitions(){
    string cntctFieldDefMessage = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:arc="archserver.xsd.dataflux.com">';
    cntctFieldDefMessage+= '<soapenv:Header/>';
    cntctFieldDefMessage+= '<soapenv:Body>';        
    cntctFieldDefMessage+='<arc:SendArchitectServiceRequest>';  
    cntctFieldDefMessage += '<serviceName>';
    cntctFieldDefMessage += 'SFDC_Contact_Wrapper.ddf'; 
    cntctFieldDefMessage += '</serviceName>';
        
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>REQUESTID</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';

    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>SFDC_ID</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>RECORD_OPERATION</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>15</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>SYNCH_IND</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>15</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>MATCH_IND</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>15</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';

    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>RETURN_MATCHES</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>15</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>ACCT_SFDCID</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
   
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>FIRSTNAME</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>LASTNAME</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>Email</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>Phone</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>Street</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>City</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>State</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>PostalCode</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>REF_CONTACT_ID</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
        
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>REF_ACCT_ID</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
 /*   
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>LAST_UPDATED_DT</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>18</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';    
   */  
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>DF_UID</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';
    
    cntctFieldDefMessage += '<fieldDefinitions>';
    cntctFieldDefMessage += '<fieldName>ONLINE_USERNAME</fieldName>';
    cntctFieldDefMessage += '<fieldType>STRING</fieldType>';
    cntctFieldDefMessage += '<fieldLength>255</fieldLength>';
    cntctFieldDefMessage += '</fieldDefinitions>';    
    
    
    

    
    return cntctFieldDefMessage; 
    
   }//createCntctFieldDefinitions
   
   private static string createCntctRequest(Contact ct){
    string cntctRequest = '<dataRows>';     
    cntctRequest += '<value>' +ct.Id+'</value>'; //req id 
    cntctRequest += '<value>' + ct.Id+ '</value>'; //SFDC ID     
    cntctRequest += '<value>' + ct.DatafluxSyncOperation__c+ '</value>'; //operation 
    cntctRequest += '<value>' +syncIND + '</value>'; // run sync?
    cntctRequest += '<value>' +matchIND + '</value>'; // run match? 
    cntctRequest += '<value>' +checkValue(retMatches) + '</value>'; // return Matches -
    cntctRequest += '<value>' +checkValue(ct.AccountId)+'</value>'; 
    cntctRequest += '<value>' +checkValue(ct.FirstName)+'</value>';
    cntctRequest += '<value>' +checkValue(ct.LastName)+'</value>';
    cntctRequest += '<value>' +checkValue(ct.Email)+'</value>';
    cntctRequest += '<value>' +checkValue(ct.Phone)+'</value>'; 
    cntctRequest += '<value>' +checkValue(ct.MailingStreet)+'</value>'; 
    cntctRequest += '<value>' +checkValue(ct.MailingCity)+'</value>';   
    cntctRequest += '<value>' +checkValue(ct.MailingState)+'</value>';  
    cntctRequest += '<value>' +checkValue(ct.MailingPostalcode)+'</value>'; 
    cntctRequest += '<value>' +checkValue(ct.Ref_Contact_ID__c)+'</value>';
     
    //if (acctMap != null && acctMap.containsKey(ct.AccountId)) {
    //   cntctRequest += '<value>' +checkValue(acctMap.get(ct.AccountId).Mirror_Referral_Account__c)+'</value>';
    //} else {
       cntctRequest += '<value>' +checkValue((ct.Mirror_Ref_Ctct__c != null ? String.valueOf(ct.Mirror_Ref_Ctct__r.Referral_Account__c) : ''))+'</value>';
    //}

    cntctRequest += '<value>' + (String.isBlank(ct.Dataflux_ID__c) ? String.valueOf(ct.Id) : checkValue(ct.Dataflux_Id__c)) + '</value>';
    cntctRequest += '<value>' + (ct.UsernameDate__c !=null? string.valueof(ct.UsernameDate__c): '' )+'</value>';
    cntctRequest += '</dataRows>'; 
    
    //system.debug ('createCntctRequest cntctRequest=' + cntctRequest); 
    
    return cntctRequest; 
    
   }//createCntctRequest
   

    //create the column field definitions for the Lead request 
   private static String createLeadFieldDefinitions(){
    string LeadFieldDefMessage = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:arc="archserver.xsd.dataflux.com">';
    LeadFieldDefMessage+= '<soapenv:Header/>';
    LeadFieldDefMessage+= '<soapenv:Body>';         
    LeadFieldDefMessage += '<arc:SendArchitectServiceRequest>';
    LeadFieldDefMessage +='<serviceName>';
    LeadFieldDefMessage += 'SFDC_Lead_Wrapper.ddf';
    LeadFieldDefMessage += '</serviceName>';
    
    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>REQUESTID</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';

    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>SFDC_ID</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';
    
    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>RECORD_OPERATION</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>15</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';
    
    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>SYNCH_IND</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>15</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';
    
    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>MATCH_IND</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>15</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';

    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>RETURN_MATCHES</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';    
    
    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>COMPANY_NAME</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';        

    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>FIRSTNAME</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';   
    
    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>LASTNAME</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';       

    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>Phone</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>'; 

    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>Email</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';
   
    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>Street</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';

    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>City</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';

    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>State</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';
    
    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>PostalCode</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';           
    
    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>DF_LG_ID</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';       
    
  /*  LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>LAST_UPDATED_DT</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';  
*/
    LeadFieldDefMessage += '<fieldDefinitions>';
    LeadFieldDefMessage += '<fieldName>DF_UID</fieldName>';
    LeadFieldDefMessage += '<fieldType>STRING</fieldType>';
    LeadFieldDefMessage += '<fieldLength>255</fieldLength>';
    LeadFieldDefMessage += '</fieldDefinitions>';       

    return LeadFieldDefMessage; 
   }//createLeadFieldDefinitions
   
    private static string CreateLeadRequest(Lead ld){
    string LeadRequest = '<dataRows>';      
    LeadRequest += '<value>' +ld.Id+'</value>'; //requestid 
    LeadRequest += '<value>' +ld.Id+'</value>'; //sfdc id 
    LeadRequest += '<value>' + ld.DatafluxSyncOperation__c+ '</value>'; // operation
    LeadRequest += '<value>' +syncIND + '</value>'; // run sync?
    LeadRequest += '<value>' +leadMatchIND + '</value>'; // run match? 
    LeadRequest += '<value>' +checkValue(retMatches) + '</value>'; // return Matches -   
    LeadRequest += '<value>' +checkValue(ld.Company)+'</value>'; 
    LeadRequest += '<value>' +checkValue(ld.FirstName)+'</value>';
    LeadRequest += '<value>' +checkValue(ld.LastName)+'</value>';
    LeadRequest += '<value>' +checkValue(ld.Phone)+'</value>';   
    LeadRequest += '<value>' +checkValue(ld.Email)+'</value>';
    LeadRequest += '<value>' +checkValue(ld.Street)+'</value>';  
    LeadRequest += '<value>' +checkValue(ld.City)+'</value>';    
    LeadRequest += '<value>' +checkValue(ld.State)+'</value>';   
    LeadRequest += '<value>' +checkValue(ld.Postalcode)+'</value>';  
    LeadRequest += '<value>' +checkValue(ld.LeadGroupId__c)+'</value>';      
  //  LeadRequest += '<value>' +Leads.LastModifiedDate+'</value>';      
    LeadRequest += '<value>' + (String.isBlank(ld.Dataflux_ID__c) ? String.valueOf(ld.Id) : checkValue(ld.Dataflux_Id__c)) + '</value>';
  //  LeadRequest += '<value>' +checkValue(Leads.Dataflux_ID__c)+'</value>';  
    
    LeadRequest += '</dataRows>'; 
 
    //LeadRequest += '</ns0:SendArchitectServiceRequest>';
    
    return LeadRequest; 
    
   }//CreateLeadRequest
   
   private static string endTag(){
//    string endReq  = '</dataRows>';
    string endReq ='</arc:SendArchitectServiceRequest>';
    endReq += '</soapenv:Body>';
    endReq +='</soapenv:Envelope>'; 
    
    return endReq;    
    
   }//endtag
   


} // DataFluxDeltaService