/* 
   DNC Queueable job
   
  History
  -------
  04/25/2018 Jake Hinds         Created
  11/01/2018 Jake Hinds         Adding ability to reschedule based on limits
  12/23/2018 Dan Carmen         Modified to use StringHelper.addToProcessNotes method
  01/08/2018 Dan Carmen         Modified to add some more flexibility 
  10/30/2019 Cindy Freeman		commented out code in checkForClearingFlags if no match is found so we dont reset flags unnecessarily 
  04/02/2020 Cindy Freeman		fixed hasSearchIds check so will split into batches
  09/15/2020 Dan Carmen         Don't launch queueable if in a batch/future/queueable context
  10/23/2020 Dan Carmen         Catch an exception if the batch fails.

 */

public without sharing class DNCQueueable implements Queueable{

   public class DNCWrapper {
      public DNCWrapper(String p_operation, String p_objectType, string p_searchString, Id p_searchId, Map<String,Date>p_expirationByPhoneMap, Map<String, Reference_Do_Not_Contact__c> p_RefDNCMap) {
         //operation = p_operation;
         addOperation(p_operation);
         objectType = p_objectType;
         searchString = p_searchString;
         addSearchId(p_searchId, p_operation);
         addExpirationByPhoneMap(p_expirationByPhoneMap);
         addemailToDNCMap(p_RefDNCMap);
      } // DNCWrapper
      
      public void addMoreData(String p_operation, String p_searchString, Id p_searchId, Map<String,Date>p_expirationByPhoneMap) {
         addOperation(p_operation);
         addExpirationByPhoneMap(p_expirationByPhoneMap);
         addSearchId(p_searchId, p_operation);
         addSearchString(p_searchString, p_operation);
      } // addMoreData
      
      public void addOperation(String p_operation) {
         if (String.isNotBlank(p_operation)) {
            hasOppCheck = (hasOppCheck || p_operation.startsWith('check'));
            operationSet.add(p_operation);
            if (firstOp == null) {
               firstOp = p_operation;
            }
         }
      } // addOpperation
      
      public void addSearchString(String p_searchString, String p_operation) {
         if (String.isNotBlank(p_searchString)) {
            searchStringMap.put(p_operation, p_searchString);
         }
      }
      
      public void addExpirationByPhoneMap(Map<String,Date> p_expirationByPhoneMap) {
         if (p_expirationByPhoneMap != null && !p_expirationByPhoneMap.isEmpty()) {
            if (expirationByPhoneMap.isEmpty()) {
               expirationByPhoneMap = p_expirationByPhoneMap;
            } else {
               for (String key : p_expirationByPhoneMap.keySet()) {
                  expirationByPhoneMap.put(key,p_expirationByPhoneMap.get(key));
               }
            }
            System.debug('addExpirationByPhoneMap map='+expirationByPhoneMap.size());
         }
      } // addExpirationByPhoneMap
      
      public void addemailToDNCMap(Map<String, Reference_Do_Not_Contact__c> p_RefDNCMap){
         if(p_RefDNCMap!=null){
            emailToDNCMap = p_RefDNCMap;
         }
         System.debug('addemailToDNCMap map='+emailToDNCMap.size());
      }
      public Boolean hasOppCheck = false;
      
      public String firstOp = null;
      
      public Set<String> operationSet = new Set<String>();
      // for search Ids, keep track of the operations by Id so we don't have to do something different
      //public Map<Id,String> searchOpMap = new Map<Id,String>();
      public Map<Id,Set<String>> searchOpMap = new Map<Id,Set<String>>();
      //Map to update the Request Do Not Contact record status
      Map<String, Reference_Do_Not_Contact__c> emailToDNCMap = new Map<String, Reference_Do_Not_Contact__c>();
      
      //public String operation;
      public String objectType;
      public String searchString;
      // One search string per operation
      public Map<String,String> searchStringMap = new Map<String,String>();
      //public Id[] searchIds = new Id[]{};
      public Map<String,Date> expirationByPhoneMap = new Map<String,Date>();
      
      public void addSearchId(Id p_searchId, String p_operation) {
         if (p_searchId != null) {
            // only do this the first time
            if (searchOpMap.isEmpty()) {
               isContact = (p_searchId.getSobjectType() == Schema.Contact.SObjectType);
               isLead = (p_searchId.getSobjectType() == Schema.Lead.SObjectType);
            }
            Set<String> opSet = searchOpMap.containsKey(p_searchId) ? searchOpMap.get(p_searchId) : new Set<String>();
            opSet.add(p_operation);
            searchOpMap.put(p_searchId, opSet);
            //searchOpMap.put(p_searchId, p_operation);
         }
      } // addSearchId
      
      public Boolean isContact = false;
      public Boolean isLead = false;
      
      public Boolean hasSearchIds{
         get {
            return (!searchOpMap.isEmpty());
         }
      }
      
      public Boolean hasSearchString{
         get {
            // has to have a length of greater than 1 to use in a search
            return ((String.isNotBlank(searchString) && searchString.length() > 1) || !searchStringMap.isEmpty());
         }
      } // hasSearchString
      
      public String getSearchString(String p_operation) {
         String returnStr = (searchStringMap.containsKey(p_operation) ? searchStringMap.get(p_operation) : searchString);
         return returnStr;
      } // getSearchString
      
      public Boolean isOppCall(Id recId) {
         return (checkOperation(recId, 'Call'));
      }
      public Boolean isOppEmail(Id recId) {
         return (checkOperation(recId, 'Email'));
      }
      public Boolean isOppText(Id recId) {
         return (checkOperation(recId, 'Text'));
      }
      
      public Boolean isOppChkEmail(Id recId) {
         Boolean isOpp = (checkOperation(recId, 'checkEmail') || checkOperation(recId, 'checkBoth'));
         return isOpp;
      }

      public Boolean isOppChkPhone(Id recId) {
         Boolean isOpp = (checkOperation(recId, 'checkPhone') || checkOperation(recId, 'checkBoth'));
         return isOpp;
      }

      public Boolean isOppChkBoth(Id recId) {
         return (checkOperation(recId, 'checkBoth'));
      }

      public Boolean checkOperation(Id recId, String opName) {
         //System.debug('checkOperation searchOpMap='+searchOpMap.size()+' operationSet='+operationSet);
         Set<String> opSet = ((recId != null && searchOpMap.containsKey(recId)) ? searchOpMap.get(recId) : operationSet);
         System.debug('checkOperation opSet='+opSet);
         return (opSet.contains(opName));
      } // checkOperation
      
      public String getOperations() {
         String opNames = '';
         for (String op : operationSet) {
            if (String.isNotBlank(opNames)) {
               opNames += ';';
            }
            opNames += op;
         }
         return opNames;
      }
      
   } // class DNCWrapper
   
   public DNCQueueable() {
      
   }
   
   // this is used to initially setup the data to run
   public void addToQueue(String p_operation, String p_objectType, string p_searchString, Id p_searchId, Map<String,Date>p_expirationByPhoneMap) {
      // using a key only for ids because those are grouped operations 
      addToQueue(p_operation,p_objectType,p_searchString,p_searchId,p_expirationByPhoneMap,null);
   } // addToQueue
 // this is used to initially setup the data to run (additional parameters)
   public void addToQueue(String p_operation, String p_objectType, string p_searchString, Id p_searchId, Map<String,Date>p_expirationByPhoneMap, Map<String,Reference_Do_Not_Contact__c>p_RefDNCMap){
      // using a key only for ids because those are grouped operations 
      String key = (p_searchId != null ? p_objectType+'SearchId' : 'SearchString');
      DNCWrapper dncWrap = (key != null ? wrappersToProcessMap.get(key) : null);
      System.debug('addToQueue p_operation='+p_operation+' key='+key+' dncWrap='+dncWrap+' p_searchString='+p_searchString);
      // only allow each search operation to be added once to a wrapper. If more than once, create a new wrapper
      if (key == 'SearchString' && dncWrap != null && dncWrap.searchStringMap.containsKey(p_operation)) {
         dncWrap = null;
      }
      if (dncWrap == null) {
         System.debug('addToQueue creating a new wrapper');
         dncWrap = new DNCWrapper(p_operation, p_objectType, p_searchString, p_searchId, p_expirationByPhoneMap, p_RefDNCMap);
         wrappersToProcessList.add(dncWrap);
         if (key != null) {
            wrappersToProcessMap.put(key,dncWrap);
         }
      } else {
         dncWrap.addMoreData(p_operation, p_searchString, p_searchId, p_expirationByPhoneMap);
      } // if (dncWrap == null
      System.debug('addToQueue wrappersToProcessList='+wrappersToProcessList.size()+' searchIds='+(dncWrap != null ? dncWrap.searchOpMap.size() : null));
   }

   
   public Map<String,DNCWrapper> wrappersToProcessMap = new Map<String,DNCWrapper>();
   
   public DNCWrapper[] wrappersToProcessList = new DNCWrapper[]{};
   
   // this is to control relaunching the job during a test run (only can run once in a test)
   public Boolean alreadyRan = false;

   // this is used to actually launch the queueable
   public DNCQueueable(DNCWrapper[] p_wrappersToProcessList) {
      wrappersToProcessList = p_wrappersToProcessList;
   }
   
   public void execute(QueueableContext context) {
      alreadyRan = true;
      processRecs();
   } // execute
   
   public void processRecs() {
      System.debug('processRecs wrappersToProcessList='+wrappersToProcessList.size());
      // remove the first record from the list
      DNCWrapper dncWrap = wrappersToProcessList.remove(0);
      // TODO - do the processing here
      // first check the number of searchIds
      checkSearchIds(dncWrap);
      
      // Types of operations:
      //      1)Call, Text, Email - come from DNCHelper from either case submission or sharepoint
      //      2)checkPhone, checkEmail, checkBoth - come from triggers from records having phone, email, both updated.
      
      System.debug('processRecs operation='+dncWrap.getOperations());
      if (String.IsNotBlank(dncWrap.getOperations()) && dncWrap.objectType != null){
         if(dncWrap.objectType == 'Lead/Contact' 
                 && dncWrap.hasSearchString
                 && (dncWrap.isOppCall(null) || dncWrap.isOppText(null)  || dncWrap.isOppEmail(null))) {
            setLeadContactDNC(dncWrap);
         } else if (dncWrap.objectType == 'Lead/Contact' 
                 && dncWrap.hasSearchIds 
                 && dncWrap.hasOppCheck) {
            checkLeadContactDNC(dncWrap);
         } else if (dncWrap.objectType == 'Account' 
                 && (dncWrap.isOppCall(null) || dncWrap.isOppEmail(null)) 
                 && dncWrap.hasSearchIds) {
            setAcctRefAcctDNC(dncWrap);
         }
         
         //   else if(objectType == 'Referral Account' && operation == 'Call' && searchIds!=null){
         //       setAcctRefAcctDoNotCall();
         //   }
        }//if(searchString != null

      // see if we need to relaunch the queuable
      checkLaunchQueuable();
   } // processRecs
   
   public void checkSearchIds(DNCWrapper dncWrap) {
      // we don't want to process too many at one time. So we'll check how many we have to process and split them out if necessary
      if (dncWrap.hasSearchIds) {
         Apex_Batch_Control__c abc = getBatchControl();
         Integer batchSize = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 100);
         if (dncWrap.searchOpMap.size() > batchSize) {
            // make a copy of the wrapper
            DNCWrapper newWrapper = new DNCWrapper(null, dncWrap.objectType, dncWrap.searchString, null, dncWrap.expirationByPhoneMap, null);
            
            // add to a list for easy manipulation
            Id[] recIds = new Id[]{};
            recIds.addAll(dncWrap.searchOpMap.keySet());
            // remove the extra search ids and put into the other wrapper
            while (recIds.size() > batchSize) {
               Id recId = recIds.remove(0);
               Set<String> operationSet = dncWrap.searchOpMap.get(recId);
               dncWrap.searchOpMap.remove(recId);
               newWrapper.searchOpMap.put(recId, operationSet);
            } // while
            // put back onto the list to process
            wrappersToProcessList.add(newWrapper);
         }
      } // if (!wrapToProcess.searchIds
      
   } // checkSearchIds

   public void setLeadContactDNC(DNCWrapper dncWrap){
      List<List<sObject>> searchList = queryRecords(dncWrap);
      Lead[] searchLeads = new Lead[]{};
      Contact[] searchContacts = new Contact[]{};
      if (searchList!=null && !searchList.isEmpty()){
         searchLeads = (Lead[])searchList[0];
         if (searchList.size() > 1) {
            searchContacts = (Contact[])searchList[1];
         }
      }
      System.debug('setLeadContactDNC searchLeads='+searchLeads.size()+' searchContacts='+searchContacts.size());
      Map<Id,Lead> leadUpdateMap = new Map<Id,Lead>();
      Map<Id,Contact> ctctUpdateMap = new Map<Id,Contact>();
      Map<Id,Reference_Do_Not_Contact__c> dncUpdateMap = new Map<Id,Reference_Do_Not_Contact__c>();
      
      for (Lead ld : searchLeads) {
         //String operation = dncWrap.getOperation(ld.Id);
         system.debug('setLeadContactDNC Search Result Lead Found: '+ld+' operation='+dncWrap.getOperations());
         if (dncWrap.isOppCall(ld.Id)) {
            System.debug('setLeadContactDNC isOppCall');
            if (dncWrap.expirationByPhoneMap!=null && dncWrap.expirationByPhoneMap.containsKey(ld.Phone)) {
               ld.DNC_Expiration__c = dncWrap.expirationByPhoneMap.get(ld.Phone);
            } else if(dncWrap.expirationByPhoneMap != null && dncWrap.expirationByPhoneMap.containsKey(ld.MobilePhone)) {
               ld.DNC_Expiration__c = dncWrap.expirationByPhoneMap.get(ld.MobilePhone);
            }
            ld.DoNotCall = true;
            StringHelper.addToProcessNotes(ld,'Setting Do Not Call from DNC case submission');
            //leadUpdateSet.add(ld);
            leadUpdateMap.put(ld.Id, ld);
         } 
         if (dncWrap.isOppText(ld.Id)){
            System.debug('setLeadContactDNC isOppText');
            ld.Consent_to_Text__c = false;
            ld.Consent_to_Text_Date__c = null;
            ld.Consent_to_Text_reason__c = null;
            StringHelper.addToProcessNotes(ld,'Setting Do Not Text from DNC case submission');
            leadUpdateMap.put(ld.Id, ld);
         } 
         if (dncWrap.isOppEmail(ld.Id)){
            System.debug('setLeadContactDNC isOppEmail');
            ld.HasOptedOutOfEmail = true;
            StringHelper.addToProcessNotes(ld,'Setting Do Not Email from DNC case submission/Unsubscribe page');
            leadUpdateMap.put(ld.Id, ld);
            System.debug('rec details'+dncWrap.emailToDNCMap.get(ld.Email));
            if(dncWrap.emailToDNCMap!=null && dncWrap.emailToDNCMap.containsKey(ld.Email)){
               System.debug('rec details'+dncWrap.emailToDNCMap.get(ld.Email));
               Reference_Do_Not_Contact__c rec = dncWrap.emailToDNCMap.get(ld.Email);
               rec.Status__c = 'Completed';  
               dncUpdateMap.put(rec.Id, rec);
            }
         }
      }//for(Lead ld
      
      for (Contact ctct : searchContacts) {
         //String operation = dncWrap.getOperation(ctct.Id);
         system.debug('setLeadContactDNC Search Result Contact Found: '+ctct+' operation='+dncWrap.getOperations());
         if (dncWrap.isOppCall(ctct.Id)){
            System.debug('setLeadContactDNC isOppCall');
            if (dncWrap.expirationByPhoneMap != null) {
               if(dncWrap.expirationByPhoneMap.containsKey(ctct.Phone)){
                  ctct.DNC_Expiration__c = dncWrap.expirationByPhoneMap.get(ctct.Phone);
               } else if (dncWrap.expirationByPhoneMap.containsKey(ctct.MobilePhone)){
                  ctct.DNC_Expiration__c = dncWrap.expirationByPhoneMap.get(ctct.MobilePhone);
               } else if(dncWrap.expirationByPhoneMap.containsKey(ctct.OtherPhone)){
                    ctct.DNC_Expiration__c = dncWrap.expirationByPhoneMap.get(ctct.OtherPhone);
               }
            } // if (dncWrap.expirationByPhoneMap != null
            ctct.DoNotCall = true;
            StringHelper.addToProcessNotes(ctct,'Setting Do Not Call from DNC case submission');
            ctctUpdateMap.put(ctct.Id,ctct);
         } 
         if (dncWrap.isOppText(ctct.Id)){
            System.debug('setLeadContactDNC isOppText');
            ctct.Consent_to_Text__c = false;
            ctct.Consent_to_Text_Date__c = null;
            ctct.Consent_to_Text_reason__c = null;
            StringHelper.addToProcessNotes(ctct,'Setting Do Not Text from DNC case submission');
            ctctUpdateMap.put(ctct.Id,ctct);
         } 
         if(dncWrap.isOppEmail(ctct.Id)){
            System.debug('setLeadContactDNC isOppEmail');
            ctct.HasOptedOutOfEmail = true;
            ctct.Email_Opt_Out_Requested__c = false;
            StringHelper.addToProcessNotes(ctct,'Setting Do Not Email from DNC case submission');
            ctctUpdateMap.put(ctct.Id,ctct);
            System.debug('rec details'+dncWrap.emailToDNCMap.get(ctct.Email));
            if(dncWrap.emailToDNCMap!=null && dncWrap.emailToDNCMap.containsKey(ctct.Email)){
               System.debug('rec details'+dncWrap.emailToDNCMap.get(ctct.Email));
               Reference_Do_Not_Contact__c rec = dncWrap.emailToDNCMap.get(ctct.Email);
               rec.Status__c = 'Completed';  
               dncUpdateMap.put(rec.Id, rec);
            }
         }
      }// for (Contact ctct
        
      system.debug('setLeadContactDNC leadUpdateMap' + leadUpdateMap.size());
      //update matches
      saveRecords(leadUpdateMap.values(), dncWrap);

      system.debug('setLeadContactDNC ctctUpdateMap' + ctctUpdateMap.size());
      saveRecords(ctctUpdateMap.values(), dncWrap);
      
      system.debug('setLeadContactDNC dncUpdateMap' + dncUpdateMap.size());
      saveRecords(dncUpdateMap.values(), dncWrap);
   }//setLeadContactDNC
   
   public void checkLeadContactDNC(DNCWrapper dncWrap) {
      Map<Id,Lead> leadMap = new Map<Id,Lead>();
      Map<Id,Contact> ctctMap = new Map<Id,Contact>();
      //could be a problem if two records are created at the same time with the same email/phone
      Map<String,Id[]> idByPhoneEmail = new Map<String,Id[]>();
        
      System.debug('checkLeadContactDNC dncWrap.hasSearchIds='+dncWrap.hasSearchIds);
      // set the records from the trigger by their ids
      if (dncWrap.hasSearchIds && dncWrap.isLead) {
         leadMap = new Map<Id,Lead>([SELECT Id,Name,Phone,MobilePhone,DoNotCall,Consent_to_Text__c,Email,HasOptedOutOfEmail,ProcessNotes__c FROM Lead WHERE Id in :dncWrap.searchOpMap.keySet()]);
         System.debug('checkLeadContactDNC leadMap='+leadMap.size());
         for (Lead ld:leadMap.values()) {
            checkAddToMap(ld.Phone, ld.Id, idByPhoneEmail);
            checkAddToMap(ld.MobilePhone, ld.Id, idByPhoneEmail);
            checkAddToMap(ld.Email, ld.Id, idByPhoneEmail);
            System.debug('checkLeadContactDNC ld='+ld.Name+' idByPhoneEmail='+idByPhoneEmail.size());
         } // for (Lead ld
      } else if (dncWrap.hasSearchIds && dncWrap.isContact) {
         ctctMap = new Map<Id,Contact>([SELECT Id,LastName,Name,Phone,MobilePhone,OtherPhone,DoNotCall,Consent_to_Text__c,Email,HasOptedOutOfEmail,ProcessNotes__c FROM Contact WHERE Id in :dncWrap.searchOpMap.keySet()]);
         for (Contact ctct:ctctMap.values()) {
            system.debug('checkLeadContactDNC ctct LastName='+ctct.LastName+' phone: '+ctct.Phone+' mobile: '+ctct.MobilePhone+' other: '+ctct.OtherPhone+' email: '+ctct.Email);
            checkAddToMap(ctct.Phone, ctct.Id, idByPhoneEmail);
            checkAddToMap(ctct.MobilePhone, ctct.Id, idByPhoneEmail);
            checkAddToMap(ctct.OtherPhone, ctct.Id, idByPhoneEmail);
            checkAddToMap(ctct.Email, ctct.Id, idByPhoneEmail);
         } // for (Contact ctct
      }
      
      system.debug('checkLeadContactDNC idByPhoneEmail='+idByPhoneEmail.size()+' leadMap='+(leadMap != null ? leadMap.size() : -1)+' ctctMap='+(ctctMap != null ? ctctMap.size() : -1));
      //build string of email and phone numbers needed to query with
      for (string str : idByPhoneEmail.keySet()) {
         if(!dncWrap.hasSearchString) {
            dncWrap.searchString = '("'+str+'")';
         } else {
            dncWrap.searchString += ' OR ("'+str+'")';
         }
      } // for
      system.debug('checkLeadContactDNC searchString='+dncWrap.searchString);
      List<List<sObject>> searchList;
      if(dncWrap.hasSearchString){
         searchList = queryRecords(dncWrap);
      }
      Sobject[] searchResults = new Sobject[]{};
      // to get a distinct list of results
      Map<Id,SObject> searchResultsMap = new Map<Id,SObject>();
      if(searchList!=null && !searchList.isEmpty()){
         for (List<Sobject> objList : searchList) {
            searchResults.addAll(objList);
            for (SObject rec : objList) {
               searchResultsMap.put(rec.Id,rec);
            }
            
         }
      } // if(searchList!=null
      system.debug('checkLeadContactDNC searchResults='+searchResults.size()+' searchResultsMap='+searchResultsMap.size());
      //loop through results and check our records against them to see if there are matches with dnc/text/email
      //if no matches, remove dnc/text/email
      Map<Id,Sobject> recordsCorrectlyMarked = new Map<Id,Sobject>();//records where matches are found but don't need to be updated get sent here
      Map<Id,Lead> leadUpdateMap = new Map<Id,Lead>();
      Map<Id,Contact> ctctUpdateMap = new Map<Id,Contact>();
      
      for (Sobject searchRec : searchResultsMap.values()){
         Boolean isContact = (searchRec.Id.getSObjectType() == Schema.Contact.SObjectType);
         Boolean isLead = !isContact;
         
         String phone = (String)searchRec.get('Phone');
         String mobilePhone = (String)searchRec.get('MobilePhone');
         //other phone is only on contact, not lead. will error out if we try to retrieve it for lead
         String otherPhone = (isContact ? (String)searchRec.get('OtherPhone') : null);
         String email = (String)searchRec.get('Email');
         String lastName = (String)searchRec.get('LastName');
         Boolean updateRecord = false;
         System.debug('checkLeadContactDNC lastName='+lastName+' phone='+phone+' mobilePhone='+mobilePhone+' otherPhone='+otherPhone+' email='+email+' idByPhoneEmail='+idByPhoneEmail.size());
         //get the id of the original record whose phone/email changed based on what the result record matched on
         Map<Id,SObject> recsFromTriggerMap = new Map<Id,SObject>();
         checkForTriggerRecs(phone, idByPhoneEmail, leadMap, ctctMap, recsFromTriggerMap);
         checkForTriggerRecs(mobilePhone, idByPhoneEmail, leadMap, ctctMap, recsFromTriggerMap);
         checkForTriggerRecs(otherPhone, idByPhoneEmail, leadMap, ctctMap, recsFromTriggerMap);
         checkForTriggerRecs(email, idByPhoneEmail, leadMap, ctctMap, recsFromTriggerMap);

         system.debug('checkLeadContactDNC recsFromTriggerMap='+recsFromTriggerMap.size()+ ' searchRec: '+searchRec);
         //update the record for call or text or email or all if we find a search result that matched on phone/email and has dnc/text/email marked
         for (SObject recFromTrigger : recsFromTriggerMap.values()) {
            checkForRecordUpdate(recFromTrigger, searchRec, dncWrap
                                   ,leadMap ,ctctMap
                                   ,recordsCorrectlyMarked
                                   ,leadUpdateMap
                                   ,ctctUpdateMap);
         } // for (SObject recFromTriger
      }//for searchResults

      system.debug('checkLeadContactDNC leadUpdateMap='+leadUpdateMap.size()+' ctctUpdateMap='+ctctUpdateMap.size()+' recordsCorrectlyMarked='+recordsCorrectlyMarked.size());
      //go through records that didn't have a match and update them to no longer be do not call,text,email
      //we don't want this to happen in test classes unless we are specifically testing for it
      checkForClearingFlags(dncWrap, leadMap, leadUpdateMap, recordsCorrectlyMarked, false);
      checkForClearingFlags(dncWrap, ctctMap, ctctUpdateMap, recordsCorrectlyMarked, true);

      saveRecords(leadUpdateMap.values(), dncWrap);
      saveRecords(ctctUpdateMap.values(), dncWrap);
        
   }//checkLeadContactDNC
   
   public void checkForClearingFlags(DNCWrapper dncWrap, Map<Id,SObject> objectMap, Map<Id,SObject> updateMap, Map<Id,Sobject> recordsCorrectlyMarked, Boolean isCtct) {
      if (objectMap != null && ((Test.isRunningTest() && !DNCHelper.skipUncheck) || !Test.isRunningTest())) {
         for (SObject rec : objectMap.values()) {
            String recName = (String)rec.get('Name');
            System.debug('checkForClearingFlags recName='+recName);
            if (!recordsCorrectlyMarked.containsKey(rec.Id) && !updateMap.containsKey(rec.Id)) {
               Boolean updateRecord = false;
               String processNotes = '';
               /*
               if (dncWrap.isOppChkPhone(rec.Id)){
                  if ((Boolean)rec.get('DoNotCall')) {
                     rec.put('DoNotCall', false);
                     rec.put('DNC_Expiration__c',null);
                     processNotes += 'Clearing DNC because phone changed and no matching DNC records were found. ';
                     updateRecord = true;
                  }
                  if ((Boolean)rec.get('Consent_to_Text__c')) {
                     rec.put('Consent_to_Text__c',false);
                     processNotes += 'Clearing Text Opt In because phone changed and no matching DNC records were found. ';
                     updateRecord = true;
                  }
               } // if (dncWrap.operation == 'checkPhone'
               if ((dncWrap.isOppChkEmail(rec.Id)) && (Boolean)rec.get('HasOptedOutOfEmail')) {
                  rec.put('HasOptedOutOfEmail',false);
                  processNotes += 'Clearing Email Opt Out because email changed and no matching EOO records were found. ';
                  updateRecord = true;
               }
               */
               if (updateRecord){
                  system.debug('no match found, clearing '+dncWrap.getOperations()+' for:'+rec);
                  updateMap.put(rec.Id,rec);
                  if (isCtct) {
                     StringHelper.addToProcessNotes((Contact)rec,processNotes);
                  } else {
                     StringHelper.addToProcessNotes((Lead)rec,processNotes);
                  }
                  
               }
            } // if (!recordsCorrectlyMarked.containsKey           
         } // for (Contact ctct : ctctMap
      } // if (ctctMap!=null &&

   }
   
   public void checkForRecordUpdate(SObject recFromTrigger, SObject searchRec, DNCWrapper dncWrap
                                   ,Map<Id,Lead> leadMap ,Map<Id,Contact> ctctMap
                                   ,Map<Id,Sobject> recordsCorrectlyMarked
                                   ,Map<Id,Lead> leadUpdateMap
                                   ,Map<Id,Contact> ctctUpdateMap) {
      // to only process each record once
      Boolean stillInMaps = (recFromTrigger != null 
                                 && ((leadMap != null && leadMap.containsKey(recFromTrigger.Id)) 
                                     || (ctctMap != null && ctctMap.containsKey(recFromTrigger.Id))));
      System.debug('checkForRecordUpdate stillInMaps='+stillInMaps+' opps='+dncWrap.getOperations()+' leadMap='+(leadMap != null ? String.valueOf(leadMap.keySet()) : 'null')+' ctctMap='+(ctctMap != null ? String.valueOf(ctctMap.keySet()) : 'null'));
      System.debug('checkForRecordUpdate recFromTrigger='+recFromTrigger);
      if (!stillInMaps) {
         return;
      }
      System.debug('checkForRecordUpdate searchRec='+searchRec);
      Boolean updateRecord = false;
      String processNotes = 'Match Found on: '+searchRec.Id;
      if (dncWrap.isOppChkPhone(recFromTrigger.Id)) {
         System.debug('checkForRecordUpdate checkPhone');
         if (recFromTrigger.Id != searchRec.Id && (Boolean)recFromTrigger.get('DoNotCall') == false && (Boolean)searchRec.get('DoNotCall') == true) {
            System.debug('checkForRecordUpdate set DoNotCall');
            recFromTrigger.put('DoNotCall',true);
            if (searchRec.get('DNC_Expiration__c')!= null){
               recFromTrigger.put('DNC_Expiration__c',searchRec.get('DNC_Expiration__c'));
            }
            processNotes += '-Setting DNC';
            updateRecord = true;
         }
         //only set consent to text if the mobile phones match
         if (recFromTrigger.Id != searchRec.Id && (Boolean)recFromTrigger.get('Consent_to_Text__c') == false && (Boolean)searchRec.get('Consent_to_Text__c') == true
                     && recFromTrigger.get('MobilePhone') != null && recFromTrigger.get('MobilePhone')==searchRec.get('MobilePhone')){
            System.debug('checkForRecordUpdate set Consent_to_Text__c');
            recFromTrigger.put('Consent_to_Text__c', true);
            processNotes += '-Setting Consent to Text';
            updateRecord = true;
         }
      } // if (dncWrap.isOppChkPhone(recFromTrigger.Id
         
      if (dncWrap.isOppChkEmail(recFromTrigger.Id)) {
         System.debug('checkForRecordUpdate checkEmail');
         if(recFromTrigger.Id != searchRec.Id && (Boolean)recFromTrigger.get('HasOptedOutOfEmail') == false && (Boolean)searchRec.get('HasOptedOutOfEmail') == true){
            System.debug('checkForRecordUpdate set HasOptedOutOfEmail');
            recFromTrigger.put('HasOptedOutOfEmail', true);
            processNotes += '-Setting EOO';
            updateRecord = true;
         }
      } // if (dncWrap.isOppChkEmail
         
      //if we found a match on the new phone, email and our current record already has do not call/text/email, add to a map of records
      //'correctly marked' so we know not to clear these fields later
      if (dncWrap.isOppChkBoth(recFromTrigger.Id) 
                && (Boolean)recFromTrigger.get('DoNotCall') == (Boolean)searchRec.get('DoNotCall')
                && (Boolean)recFromTrigger.get('Consent_to_Text__c') == (Boolean)searchRec.get('Consent_to_Text__c')
                && (Boolean)recFromTrigger.get('HasOptedOutOfEmail') == (Boolean)searchRec.get('HasOptedOutOfEmail')) {
         recordsCorrectlyMarked.put(recFromTrigger.Id,recFromTrigger);
      } else if (dncWrap.isOppChkPhone(recFromTrigger.Id) 
                && (Boolean)recFromTrigger.get('DoNotCall') == (Boolean)searchRec.get('DoNotCall')
                && (Boolean)recFromTrigger.get('Consent_to_Text__c') == (Boolean)searchRec.get('Consent_to_Text__c')) {
         recordsCorrectlyMarked.put(recFromTrigger.Id,recFromTrigger);
      } else if(dncWrap.isOppChkEmail(recFromTrigger.Id) 
                && (Boolean)recFromTrigger.get('HasOptedOutOfEmail') == (Boolean)searchRec.get('HasOptedOutOfEmail')){
         recordsCorrectlyMarked.put(recFromTrigger.Id,recFromTrigger);
      }
            
      //if we updated the record, remove it from the map of original records.  We'll look at the remaining records later to remove dnc/text/email
      //put the updated record in a map to call update
      if (updateRecord) {
         if(recFromTrigger.Id.getSobjectType() == Schema.Lead.SObjectType) {
            StringHelper.addToProcessNotes((Lead)recFromTrigger,processNotes);
            leadMap.remove(recFromTrigger.Id);
            leadUpdateMap.put(recFromTrigger.Id,(Lead)recFromTrigger);
         } else if (recFromTrigger.getSobjectType() == Schema.Contact.SObjectType){
            StringHelper.addToProcessNotes((Contact)recFromTrigger,processNotes);
            ctctMap.remove(recFromTrigger.Id);
            ctctUpdateMap.put(recFromTrigger.Id,(Contact)recFromTrigger);
         }
      } // if (updateRecord)
   } // checkForRecordUpdate
   
   public void checkForTriggerRecs(String keyToSearch, Map<String,Id[]> idByPhoneEmail
                                    ,Map<Id,Lead> leadMap, Map<Id,Contact> ctctMap
                                    ,Map<Id,SObject> recsFromTriggerMap
                                    ) {

      Id[] recIds =((String.isNotBlank(keyToSearch) && idByPhoneEmail.containsKey(keyToSearch)) ? idByPhoneEmail.get(keyToSearch) : new Id[]{});
      for (Id recFromTriggerId : recIds) {
         SObject recFromTrigger = null;
         if (recFromTriggerId.getSobjectType() == Schema.Lead.SObjectType){
            recFromTrigger = leadMap.get(recFromTriggerId);
         } else if (recFromTriggerId.getSobjectType() == Schema.Contact.SObjectType){
            recFromTrigger = ctctMap.get(recFromTriggerId);
         }
         if (recFromTrigger != null) {
            System.debug('checkForTriggerRecs found a rec='+recFromTrigger);
            recsFromTriggerMap.put(recFromTrigger.Id, recFromTrigger);
         }
      }
      system.debug('checkForTriggerRecs recsFromTriggerMap='+recsFromTriggerMap.size());
   } // checkForTriggerRecs
    
   public void checkAddToMap(String checkValue, Id recId, Map<String,Id[]> idByPhoneEmail) {
      if (String.isNotBlank(checkValue) && recId != null) {
         Id[] ids = (idByPhoneEmail.containsKey(checkValue) ? idByPhoneEmail.get(checkValue) : new Id[]{});
         ids.add(recId);
         System.debug('checkAddToMap checkValue='+checkValue+' ids='+ids.size());
         idByPhoneEmail.put(checkValue, ids);
      }
   } // checkAddToMap
    
   //query records based on what we need to do
   public List<List<sObject>> queryRecords(DNCWrapper dncWrap){
      List<List<sObject>> searchList = new List<List<sObject>>();
      if (dncWrap.isOppCall(null) && dncWrap.hasSearchString){
         System.debug('queryRecords Call: '+dncWrap.getSearchString('Call'));
         List<List<sObject>> thisList = [FIND :dncWrap.getSearchString('Call') IN PHONE FIELDS 
                            RETURNING Lead(FirstName,LastName,Phone,MobilePhone,DNC_Expiration__c,Consent_to_Text__c,ProcessNotes__c,DoNotCall,email,Email_Opt_Out_Submitter__c,Email_Opt_Out_Date__c, HasOptedOutOfEmail WHERE DoNotCall = false),
                                      Contact(FirstName,LastName,Phone,MobilePhone,OtherPhone,DNC_Expiration__c,Consent_to_Text__c,ProcessNotes__c,DoNotCall,email,Email_Opt_Out_Submitter__c,Email_Opt_Out_Date__c, HasOptedOutOfEmail WHERE DoNotCall = false)];
         searchList = addToSearchList(searchList, thisList);
      } 
      if (dncWrap.isOppText(null) && dncWrap.hasSearchString){
         System.debug('queryRecords Text: '+dncWrap.getSearchString('Text'));
         List<List<sObject>> thisList = [FIND :dncWrap.getSearchString('Text') IN PHONE FIELDS 
                            RETURNING Lead(FirstName,LastName,Phone,MobilePhone,DNC_Expiration__c,Consent_to_Text__c,ProcessNotes__c,DoNotCall,email,Email_Opt_Out_Submitter__c,Email_Opt_Out_Date__c, HasOptedOutOfEmail WHERE Consent_to_Text__c = true),
                                      Contact(FirstName,LastName,Phone,MobilePhone,OtherPhone,DNC_Expiration__c,Consent_to_Text__c,ProcessNotes__c,DoNotCall,email,Email_Opt_Out_Submitter__c,Email_Opt_Out_Date__c, HasOptedOutOfEmail WHERE Consent_to_Text__c = true)];
         searchList = addToSearchList(searchList, thisList);
      } 
      if (dncWrap.isOppEmail(null) && dncWrap.hasSearchString){
         System.debug('queryRecords Email: '+dncWrap.getSearchString('Email'));
         List<List<sObject>> thisList = [FIND :dncWrap.getSearchString('Email') IN EMAIL FIELDS 
                            RETURNING Lead (FirstName,LastName,Phone,MobilePhone,DNC_Expiration__c,Consent_to_Text__c,ProcessNotes__c,DoNotCall,email,Email_Opt_Out_Submitter__c,Email_Opt_Out_Date__c, HasOptedOutOfEmail WHERE HasOptedOutOfEmail = false), 
                                      Contact (FirstName,LastName,Phone,MobilePhone,OtherPhone,DNC_Expiration__c,Consent_to_Text__c,ProcessNotes__c,DoNotCall,email,Email_Opt_Out_Submitter__c,Email_Opt_Out_Date__c, HasOptedOutOfEmail WHERE HasOptedOutOfEmail = false)];
         searchList = addToSearchList(searchList, thisList);
      } 
      if(dncWrap.isOppChkPhone(null) || dncWrap.isOppChkEmail(null)){
         if ((dncWrap.isOppChkPhone(null)) && dncWrap.hasSearchString) {
            System.debug('queryRecords checkPhone: '+dncWrap.getSearchString('checkPhone'));
            List<List<Sobject>> phoneSearch = [FIND :dncWrap.getSearchString('checkPhone') IN PHONE FIELDS 
                            RETURNING Lead(FirstName,LastName,Phone,MobilePhone,DNC_Expiration__c,Consent_to_Text__c,ProcessNotes__c,DoNotCall,email,Email_Opt_Out_Submitter__c,Email_Opt_Out_Date__c, HasOptedOutOfEmail WHERE DoNotCall = true OR Consent_to_Text__c = true),
                                      Contact(FirstName,LastName,Phone,MobilePhone,OtherPhone,DNC_Expiration__c,Consent_to_Text__c,ProcessNotes__c,DoNotCall,email,Email_Opt_Out_Submitter__c,Email_Opt_Out_Date__c, HasOptedOutOfEmail WHERE DoNotCall = true  OR Consent_to_Text__c = true)];
            searchList = addToSearchList(searchList, phoneSearch);
         }
         if ((dncWrap.isOppChkEmail(null)) && dncWrap.hasSearchString) {
            System.debug('queryRecords checkEmail: '+dncWrap.getSearchString('checkEmail'));
            List<List<Sobject>> emailSearch = [FIND :dncWrap.getSearchString('checkEmail') IN Email FIELDS 
                            RETURNING Lead(FirstName,LastName,Phone,MobilePhone,DNC_Expiration__c,Consent_to_Text__c,ProcessNotes__c,DoNotCall,email,Email_Opt_Out_Submitter__c,Email_Opt_Out_Date__c, HasOptedOutOfEmail WHERE HasOptedOutOfEmail = true),
                                      Contact(FirstName,LastName,Phone,MobilePhone,OtherPhone,DNC_Expiration__c,Consent_to_Text__c,ProcessNotes__c,DoNotCall,email,Email_Opt_Out_Submitter__c,Email_Opt_Out_Date__c, HasOptedOutOfEmail WHERE HasOptedOutOfEmail = true)];
            searchList = addToSearchList(searchList, emailSearch);
         }
      }
      system.debug('queryRecords searchList='+searchList.size());
      return searchList;
   }//queryRecords
   
   public List<List<sObject>> addToSearchList(List<List<sObject>> searchList, List<List<sObject>> listToAdd) {
      System.debug('addToSearchList searchList='+searchList.size()+' listToAdd='+(listToAdd != null ? listToAdd.size() : -1));
      List<List<sObject>> returnList = null;
      if (searchList.isEmpty() && listToAdd != null && !listToAdd.isEmpty()) {
         returnList = listToAdd;
      } else if (!searchList.isEmpty() && listToAdd != null && !listToAdd.isEmpty()) {
         returnList = new List<List<SObject>>();
         for (Integer cnt=0; cnt<searchList.size(); cnt++) {
            SObject[] retList = searchList[cnt];
            SObject[] addList =  listToAdd[cnt];
            retList.addAll(addList);
            returnList.add(retList);
         }
      }
      System.debug('addToSearchList returnList='+returnList.size());
      return returnList;
   } // addToSearchList

   public void saveRecords(List<Sobject> updateList, DNCWrapper dncWrap){
      if (!updateList.isEmpty()) {
         // skip trigger execution
         LeadMethods.LEAD_BEFORE_EXECUTING = true;
         LeadMethods.LEAD_AFTER_EXECUTING = true;
         ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
         ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
         ZipCheckOwner.SKIP_TRIGGERS = true;
         system.debug('updating records updateList='+updateList.size()+' objectType='+dncWrap.objectType+' '+dncWrap.getOperations());
         DMLHelper.performDML2(updateList,'Update','DNCQueuable','execute','updating '+ dncWrap.objectType +' '+dncWrap.getOperations(),true);
         //if (DmlHelper.performDmlResult != null) {
         //   nbrSuccess += DmlHelper.performDmlResult.nbrSuccess;
         //   nbrFailure += DmlHelper.performDmlResult.nbrError;
         //}
         LeadMethods.LEAD_BEFORE_EXECUTING = false;
         LeadMethods.LEAD_AFTER_EXECUTING = false;
         ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = false;
         ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = false;
         ZipCheckOwner.SKIP_TRIGGERS = false;
      } // if (!updateList
   }//saveRecords
   
   // set account or referral account do not call, referral account is commented out because it was removed from scope.
   public void setAcctRefAcctDNC(DNCWrapper dncWrap){
      // TODO - have to fix this still
      Account[] accountUpdateList = new Account[]{};
      Map<Id,Account> acctUpdateMap = new Map<Id,Account>();
      Contact[] contactUpdateList = new Contact[]{};
      Map<Id,Contact> ctctUpdateMap = new Map<Id,Contact>();
      Account[] acctSearchResults = new Account[]{};
      //Referral_Account__c[] refAcctUpdateList = new Referral_Account__c[]{};
      //Referral_Contact__c[] refCtctUpdateList = new Referral_Contact__c[]{};
      //Referral_Account__c[] refAcctSearchResults;
      if (dncWrap.objectType == 'Account') {
         acctSearchResults = [Select Id,Name,Do_Not_Call__c,DNC_Expiration__c,Email_Opt_Out__c, 
                                    (SELECT Contact.Id,Contact.Phone,Contact.Name,Contact.Email,Contact.DoNotCall,Contact.DNC_Expiration__c,Contact.HasOptedOutOfEmail FROM AccountContactRelations)
                                FROM Account WHERE Id in :dncWrap.searchOpMap.keySet()];
      }
      system.debug('DNCQueueable setAcctRefAcctDNC acctSearchResults: '+acctSearchResults);
      //else if(objectType == 'Referral Account'){
      //    refAcctSearchResults = [Select Id, Do_Not_Call__c,
      //                    (SELECT Id,Phone__c,Name,Email__c,Do_Not_Call__c FROM Referral_Contacts__r WHERE Do_Not_Call__c=false)
      //                    FROM Referral_Account__c WHERE Id in:searchIds];
      //}
      for (Account acct : acctSearchResults){
         acct = (acctUpdateMap.containsKey(acct.Id) ? acctUpdateMap.get(acct.Id) : acct);
         Date dncExpiration;
         if (dncWrap.expirationByPhoneMap != null && dncWrap.expirationByPhoneMap.containsKey(String.valueOf(acct.Id))) {
            dncExpiration = dncWrap.expirationByPhoneMap.get(String.valueOf(acct.Id));
         }
         Boolean isOppCall = dncWrap.isOppCall(acct.Id);
         Boolean isOppEmail = dncWrap.isOppEmail(acct.Id);
         System.debug('setAcctRefAcctDNC acct='+acct.Name+' isOppCall='+isOppCall+' isOppEmail='+isOppEmail);
         if (isOppCall) {
            if (!acct.Do_Not_Call__c){
               if (acct.DNC_Expiration__c==null && dncExpiration!=null){
                  acct.DNC_Expiration__c = dncExpiration;
               }
               acct.Do_Not_Call__c = true;
               acctUpdateMap.put(acct.Id, acct);
            }
         } 
         if (isOppEmail) {
            if (!acct.Email_Opt_Out__c){
               acct.Email_Opt_Out__c = true;
               acctUpdateMap.put(acct.Id, acct);
            }
         }
         System.debug('setAcctRefAcctDNC acct.AccountContactRelations='+acct.AccountContactRelations.size());
         for (AccountContactRelation acr : acct.AccountContactRelations) {
            Contact ctct = acr.Contact;
            ctct = (ctctUpdateMap.containsKey(ctct.Id) ? ctctUpdateMap.get(ctct.Id) : ctct);
            if (isOppCall) {
               if (!ctct.DoNotCall) {
                  if (ctct.DNC_Expiration__c==null && dncExpiration!=null) {
                     ctct.DNC_Expiration__c = dncExpiration;
                  }
                  ctct.DoNotCall = true;
                  ctctUpdateMap.put(ctct.Id, ctct);
               }
            } 
            if (isOppEmail) {
               if (!ctct.HasOptedOutOfEmail) {
                  ctct.HasOptedOutOfEmail = true;
                  ctctUpdateMap.put(ctct.Id, ctct);
               }
            }
         } // for (AccountContactRelation acr
            
      } // for (Account acct
        
      saveRecords(acctUpdateMap.values(), dncWrap);
      saveRecords(ctctUpdateMap.values(), dncWrap);

        //for(Referral_Account__c refAcct:refAcctSearchResults){
        //    if(!refAcct.Do_Not_Call__c){
        //        refAcct.Do_Not_Call__c = true;
        //        refAcctUpdateList.add(refAcct);
        //    }
        //    for(Referral_Contact__c refCtct:refAcct.Referral_Contacts__r){
        //        refCtct.Do_Not_Call__c = true;
        //        refCtctUpdateList.add(refCtct);
        //    }
        //}
        //if(!refAcctUpdateList.isEmpty()){
        //    saveRecords(refAcctUpdateList);
        //}
        //if(!refCtctUpdateList.isEmpty()){
        //    saveRecords(refCtctUpdateList);
        //}

    }//setAcctRefAcctDoNotCall
    
    public static Boolean SKIP_QUEUEABLE=Test.isRunningTest();
    
   public Boolean checkLaunchQueuable() {
      Boolean batchLaunched = false;
      Apex_Batch_Control__c abc = getBatchControl();
      System.debug('checkLaunchQueuable wrappersToProcessList='+wrappersToProcessList.size()+' alreadyRan='+alreadyRan+' abc='+abc);
      // we won't using this command during a test
      if (!wrappersToProcessList.isEmpty() 
             && (!SKIP_QUEUEABLE || !alreadyRan)
             && abc != null && abc.Active__c) {
         try {
            // enqueue the job - can't chain the jobs from tests
            System.debug('checkLaunchQueuable enqueueing job System.isBatch='+System.isBatch()+' System.isFuture='+System.isFuture()+' System.isQueueable='+System.isQueueable());
            DNCQueueable dcq = new DNCQueueable(wrappersToProcessList);
            if (System.isBatch() || System.isFuture() || System.isQueueable()) {
               // TODO - not sure to do this?
               //dcq.processRecs();
               System.debug('Already in an async context - do nothing?');
            } else {
               System.enqueueJob(dcq);
            }
            batchLaunched = true;
         } catch (Exception ex) {
             ErrorLog.logError('DNCQueueuable', 'checkLaunchQueuable', 'Launch the queueable', null, ex, null, true);
         }
      }
      return batchLaunched;
   } // checkLaunchQueuable
    
   public static final String CLASS_NAME='DNCQueueable';
    
   public static Apex_Batch_Control__c getBatchControl() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
      return abc;
   } // getBatchControl

} // class DNCQueueable