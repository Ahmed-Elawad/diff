/* 
 *  A batch job to send requests and receive responses from OSB Delta Service which handle update/insert 
 *  operations to Data Flux.  
 *  changed DataFluxDeltaService from future callouts to this so dont hit callout limits especially on lead converts   
 * History
 * -------
 * 06/16/2014 Cindy Freeman     created
 * 10/21/2014 Cindy Freeman     modified to use custom label for batch size, Winter 15 default of 100 was too big
 * 12/01/2017 Josh Cartwright   updated to call new Dataflux methods 
   08/17/2021 Dan Carmen        Increment API, allow email to be sent on first run.
   03/17/2024 Dan Carmen        Update to create the message only when it's actually sending it

*/

global class DataFluxDeltaBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Schedulable {
   
    public static String CLASSNAME='DataFluxDeltaBatch';
    
    //public static String fromWhereClause = 'from Web_Service_Log__c where ServiceName__c = \''+DataFluxDeltaService.SERVICE_NAME+'\' and SendMsg__c = true';
    //public static String logQuery = 'Select Id, Name, NbrAttempts__c, ServiceStart__c, ServiceEnd__c, ServiceName__c, SobjName__c, NamedFunction__c, SendMsg__c, Successful__c, Notes__c, Action__c '+fromWhereClause+' order by CreatedDate';
    //public static String logExistsQuery = 'Select count() '+fromWhereClause+' limit 1';
    
    global Integer nbrRecs = 0;
    global Integer nbrUpdates = 0;
    global Integer nbrDeletes = 0;
    
    global JobHelper jh = new JobHelper(CLASSNAME);
    
    // default value
    global String curMode=ObjectHelper.OBJECT_ACCOUNT;

    global DataFluxDeltaBatch() {
    } // DataFluxDeltaBatch
    
    global DataFluxDeltaBatch(String p_curMode) {
       curMode = p_curMode;
    } // DataFluxDeltaBatch
    
    global Database.queryLocator start(Database.BatchableContext BC) {
       jh.tracker.Job_Name__c = CLASSNAME+'-'+curMode;
       jh.setStarted();
       Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
       // how many days should we check for changes?
       Integer nbrDays = (abc != null && abc.Check_Days__c != null ? Integer.valueOf(abc.Check_Days__c) : 5); 
       Datetime modDaysCheck = Datetime.now().addDays(-nbrDays);

       Datetime curTime = Datetime.now();
       if (curMode == ObjectHelper.OBJECT_ACCOUNT) {
          return Database.getQueryLocator([Select Id, Name, Phone, Mirror_Referral_Account__c, Mirror_Referral_Account__r.Id, Mirror_Referral_Account__r.Dataflux_Id__c
                                                 ,AccountNumber, Bis_ID__c, Federal_ID_Number__c, Referral__c, Ref_Acct_ID__c, Referral_ORG_ID__c
                                                 ,BillingStreet, BillingCity, BillingState, BillingPostalCode
                                                 ,ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode
                                                 ,Mirror_Referral_Account__r.Dataflux_Force_Delta__c
                                                 ,Mirror_Referral_Account__r.Dataflux_Shipping_Address_MatchCode__c, Mirror_Referral_Account__r.Dataflux_Billing_Address_MatchCode__c
                                                 ,Mirror_Referral_Account__r.Dataflux_Name_MatchCode__c
                                                 ,Dataflux_Id__c, Dataflux_Force_Delta__c, Dataflux_Shipping_Address_MatchCode__c, Dataflux_Billing_Address_MatchCode__c, Dataflux_Name_MatchCode__c
                                                 ,DatafluxLastSyncTime__c, DatafluxSyncTime__c, DatafluxSyncOperation__c
                                             From Account
                                            Where Dataflux_Force_Delta__c=true
                                              and DatafluxSyncTime__c <= :curTime
                                              and DatafluxSyncOperation__c != null
                                              and LastModifiedDate >= :modDaysCheck]);
       } else if (curMode == ObjectHelper.OBJECT_CONTACT) {
          return Database.getQueryLocator([Select Id, FirstName, LastName, AccountId, Email, Phone, UsernameDate__c
                                                 ,MailingStreet, MailingCity, MailingState, MailingPostalcode, Ref_Contact_ID__c
                                                 ,Account.Mirror_Referral_Account__c
                                                 ,Mirror_Ref_Ctct__r.id, Mirror_Ref_Ctct__r.Dataflux_Id__c, Mirror_Ref_Ctct__r.Dataflux_Force_Delta__c
                                                 ,Mirror_Ref_Ctct__r.Dataflux_Shipping_Address_MatchCode__c,Mirror_Ref_Ctct__r.Dataflux_Billing_Address_MatchCode__c
                                                 ,Mirror_Ref_Ctct__r.Dataflux_Name_MatchCode__c, Mirror_Ref_Ctct__r.Referral_Account__c
                                                 ,Dataflux_Id__c, Dataflux_Force_Delta__c,Dataflux_Shipping_Address_MatchCode__c,Dataflux_Billing_Address_MatchCode__c,Dataflux_Name_MatchCode__c 
                                                 ,DatafluxLastSyncTime__c, DatafluxSyncTime__c, DatafluxSyncOperation__c
                                             From Contact
                                            Where Dataflux_Force_Delta__c=true
                                              and DatafluxSyncTime__c <= :curTime
                                              and DatafluxSyncOperation__c != null
                                              and LastModifiedDate >= :modDaysCheck]);
           
       } else if (curMode == ObjectHelper.OBJECT_LEAD) {
          return Database.getQueryLocator([Select Id, FirstName, LastName, Company, Street, City, State, Dataflux_Id__c, Postalcode, Phone, Email
                                                 ,LeadGroupId__c, Lead_Company__c
                                                 ,Dataflux_Force_Delta__c,Dataflux_Shipping_Address_MatchCode__c,Dataflux_Billing_Address_MatchCode__c,Dataflux_Name_MatchCode__c
                                                 ,DatafluxLastSyncTime__c, DatafluxSyncTime__c, DatafluxSyncOperation__c
                                             From Lead
                                            Where Dataflux_Force_Delta__c=true
                                              and DatafluxSyncTime__c <= :curTime
                                              and IsConverted=false
                                              and DatafluxSyncOperation__c != null
                                              and LastModifiedDate >= :modDaysCheck]);
       }
       return null;
        
       // return Database.getQueryLocator(logQuery);
    } // start
    
   global void execute(SchedulableContext sc) {
      DataFluxDeltaBatch dfdb = new DataFluxDeltaBatch();
      Integer batchSize = getBatchSize();
      database.executeBatch(dfdb, batchSize);
   } // execute
    
   global Integer getBatchSize() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      Integer batchSize = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 40);
      return batchSize;
   } // getBatchSize
    
   global void execute(Database.BatchableContext BC, List<SObject> scope) {
       System.debug('execute curMode='+curMode+' scope='+scope.size());
       nbrRecs+=scope.size();
       DataFluxDeltaService.setRequestValues();
       if (curMode == ObjectHelper.OBJECT_ACCOUNT) {
          handleAccounts((Account[])scope);
       } else if (curMode == ObjectHelper.OBJECT_CONTACT) {
          handleContacts((Contact[])scope);
       } else if (curMode == ObjectHelper.OBJECT_LEAD) {
          handleLeads((Lead[])scope);
       }
       checkSettingForEmail();
    } // execute
    
    global void handleAccounts(Account[] accts) {
       DatafluxSync__c[] deletes = checkForDeletes();
       for (DatafluxSync__c dfs : deletes) {
          Account acct = new Account(Id=dfs.ObjectId__c, Ref_Acct_ID__c=dfs.MirrorId__c,DatafluxSyncOperation__c=DataFluxDeltaService.ACTION_DELETE);
          accts.add(acct);
       }
       System.debug('handleAccounts deletes='+deletes.size()+' accts='+accts.size());
       String[] xmlList = DataFluxDeltaService.processAccounts(null,accts);
       String requestXml = String.join(xmlList,'');
       sendXml(accts, 'DELTA_JOB_ACCOUNT', ObjectHelper.OBJECT_ACCOUNT, requestXml, deletes);
    } // handleAccounts

    global void handleContacts(Contact[] ctcts) {
       DatafluxSync__c[] deletes = checkForDeletes();
       for (DatafluxSync__c dfs : deletes) {
          Contact ctct = new Contact(Id=dfs.ObjectId__c, Ref_Contact_ID__c=dfs.MirrorId__c,DatafluxSyncOperation__c=DataFluxDeltaService.ACTION_DELETE);
          ctcts.add(ctct);
       }
       System.debug('handleContacts deletes='+deletes.size()+' ctcts='+ctcts.size());
       String[] xmlList = DataFluxDeltaService.processContacts(null,ctcts);
       String requestXml = String.join(xmlList,'');
       sendXml(ctcts, 'DELTA_JOB_CONTACT', ObjectHelper.OBJECT_CONTACT, requestXml, deletes);
    } // handleContacts

    global void handleLeads(Lead[] lds) {
       DatafluxSync__c[] deletes = checkForDeletes();
       for (DatafluxSync__c dfs : deletes) {
          Lead ld = new Lead(Id=dfs.ObjectId__c,DatafluxSyncOperation__c=DataFluxDeltaService.ACTION_DELETE);
          lds.add(ld);
       }
       System.debug('handleLeads deletes='+deletes.size()+' lds='+lds.size());
       String[] xmlList = DataFluxDeltaService.processLeads(null,lds);
       String requestXml = String.join(xmlList,'');
       sendXml(lds, 'DELTA_JOB_LEAD', ObjectHelper.OBJECT_LEAD, requestXml, deletes);
    } // handleLeads

   global DatafluxSync__c[] checkForDeletes() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      Integer batchSize = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 40);

      Datetime curTime = Datetime.now();
      DatafluxSync__c[] syncs = [Select Id
                                        ,LastSyncTime__c, MirrorId__c
                                        ,ObjectAPIName__c, ObjectId__c, OperationType__c
                                        ,ReadyToSync__c, ReadyToSyncTime__c
                                    From DatafluxSync__c
                                   Where ReadyToSync__c=true
                                     and ReadyToSyncTime__c > :curTime
                                     and ObjectAPIName__c=:curMode limit :batchSize];
      nbrDeletes += syncs.size();
      return syncs;
   } // checkForDeletes
    
   global void sendXml(SObject[] recs, String namedFunc, String objApiName, String requestXml, DatafluxSync__c[] deletes) {
      WebServiceSettings__c webSetting = WebServicesHelper.getWebSvcSetting(DataFluxDeltaService.WEBSERVICE_SETTING);
      if (webSetting == null) {
         WebServicesHelper.logServiceCall(CLASSNAME, false, 'An active WebServiceSettings__c record was not found for '+DataFluxDeltaService.WEBSERVICE_SETTING+'-batch did NOT run!' , null);
         System.debug('An active WebServiceSettings__c record was not found!');
         return;
      }
      Integer nbrRecs = recs.size();
      Web_Service_Log__c wsl = new Web_Service_Log__c(ServiceName__c=DataFluxDeltaService.SERVICE_NAME, NamedFunction__c=namedFunc
                                                      ,NbrRecs__c=nbrRecs, NbrAttempts__c=1, SobjName__c=objApiName, Action__c=DataFluxDeltaService.ACTION_MODIFY);
      wsl.ServiceStart__c = DateTime.now();
      
      HttpRequest req = DataFluxDeltaService.buildRequest(requestXml);
      HttpResponse resp = null; 
      Integer nbrAttempts=1;
      try {
         resp = DataFluxDeltaService.sendRequest(req);
         System.debug('sendXml resp='+(resp != null ? resp.getBody() : 'No Response'));
      } catch (Exception e) {
         System.debug('sendXml exception='+e);
      }
      
      if (resp != null && resp.getStatusCode() == 200) { 
         //success++;
         map<id, DataFluxDeltaService.dfResponse> dfMap = DataFluxDeltaService.processResponse2(resp.getBody(), wsl.Action__c, wsl.Id, wsl); 
         DataFluxDeltaService.updateRecs(dfMap, objApiName, recs);
         updateLog(wsl, true, null, nbrAttempts, false);
      } else { 
         updateLog(wsl, false, 'Failed '+(resp.getStatus()==null?'':resp.getStatus()), nbrAttempts, false);
         //failure++;
      }
      // update the delete records as processed.
      if (!deletes.isEmpty()) {
         for (DatafluxSync__c dfs : deletes) {
            dfs.LastSyncTime__c = Datetime.now();
            dfs.ReadyToSync__c = false;
            dfs.ReadyToSyncTime__c = null;
         }
         database.update(deletes,false);
      } // if (!deletes.isEmpty
       
      Database.upsert(wsl,false);
      String timeStamp = Datetime.now().format('yyyyMMddhhmmssSS');
      String fileName=''+wsl.Id+timeStamp+'-request';
      AddFileQueueable afq = new AddFileQueueable(new Id[]{wsl.Id},fileName,fileName,null,Blob.valueOf(requestXml)); 
      String respBody = (resp != null ? resp.getBody() : null);
      if (String.isNotBlank(respBody)) {
         fileName=''+wsl.Id+timeStamp+'-response';
         afq.addAnotherFile(new Id[]{wsl.Id}, fileName, fileName, null, Blob.valueOf(respBody));
      }
      // to save the files
      afq.processRecs();
      
   } // sendXml
    
   global void checkSettingForEmail() {
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
        if (abc != null && abc.EmailTest__c != null) {
           String[] emails = new String[]{abc.EmailTest__c};
           if (String.isNotBlank(abc.AdditionalEmails__c)) {
              emails.addAll(abc.AdditionalEmails__c.split(','));
           }
           Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
           mail.setToAddresses(emails);
           mail.setSaveAsActivity(false);
           mail.setSubject('DataFluxDeltaBatch Completed Nbr Recs='+nbrRecs+' nbrDeletes='+nbrDeletes);
           String body = 'DataFluxDeltaBatch Completed Nbr Recs='+nbrRecs+' nbrDeletes='+nbrDeletes;
           mail.setPlainTextBody(body);
           Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
           abc.EmailTest__c = null;
           update abc;
        }
    } // checkSettingForEmail
    
    global void finish(Database.BatchableContext BC) {
      System.debug('finish');
        
      String message = '\nNumber recs='+nbrRecs+' ';
      message += '\nNumber deletes='+nbrDeletes;
      
      jh.completeJob(bc, 'DataFlux Delta Job', message);
            
      Integer batchSize = getBatchSize();
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      if (abc != null && abc.Active__c) {
         if (curMode == ObjectHelper.OBJECT_ACCOUNT) {
            DataFluxDeltaBatch dfdb = new DataFluxDeltaBatch(ObjectHelper.OBJECT_CONTACT);
            if (!Test.isRunningTest()) {
               Database.executeBatch(dfdb,batchSize);
            }
         } else if (curMode == ObjectHelper.OBJECT_CONTACT) {
            DataFluxDeltaBatch dfdb = new DataFluxDeltaBatch(ObjectHelper.OBJECT_LEAD);
            if (!Test.isRunningTest()) {
               Database.executeBatch(dfdb,batchSize);
            }
         } else if (curMode == ObjectHelper.OBJECT_LEAD && !Test.isRunningTest()) {
            // kick off the batch job again
            DataFluxDeltaService.kickOffBatchJob();
         }
      } // if (abc != null &&
    
    } // finish

   //JC for test coverage on batch:
   private void updateLog (Web_Service_Log__c log, Boolean successful, String errorMsg, Integer nbrAttempts, Boolean sendMsg) {
    
      log.Successful__c = successful;
      log.ErrorMsg__c = errorMsg;
      log.ServiceEnd__c = DateTime.now();
      log.NbrAttempts__c = (nbrAttempts != null ? nbrAttempts : log.NbrAttempts__c);
      // allow it to resend if it failed and the setting allows for it.
      log.SendMsg__c = sendMsg;
    
   }//updateLog 
     
} // DataFluxDeltaBatch