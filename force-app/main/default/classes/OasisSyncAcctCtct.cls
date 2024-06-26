/* Methods to process on the Oasis Sync object with the Account and Contact

  History
  -------
  05/15/2019 Dan Carmen        Created
  03/10/2020 Dan Carmen        Comment out all code
  
 */
public without sharing class OasisSyncAcctCtct {
 
   // we are not ending accounts on insert
   public static Boolean sendAccounts(Account[] recs, Map<Id,Account> oldMap, ErrorLog__c runLog) {
      /*
      Boolean recordsSent = false;
      System.debug('sendAccounts recs='+recs.size());
      
      Map<Id,User> userMap = OasisSyncHelper.getUserMap(recs);
      Boolean hasRecsToProcess = false;
      for (Account acct : recs) {
         User usr = userMap.get(acct.OwnerId);
         if (String.isNotBlank(acct.OasisId__c) 
                || (usr != null && usr.CSUserId__c != null)
             ) {
            hasRecsToProcess = true;
            break;
         } 
      } // for
      
      if (!hasRecsToProcess) {
         return false;
      }
      
      OasisSync__c[] insertSyncs = new OasisSync__c[]{};
      OasisSync__c[] updateSyncs = new OasisSync__c[]{};

      Map<String,OasisSync__c> syncMap = OasisSyncHelper.getExistingSyncMap(recs);
      // we'll use these to send accounts if we don't already have an Oasis Id for the Contact
      Map<Id, Contact> ctctByAcctIdMap = getLatestContactMap(recs);

      ErrorLog.addToDescription(runLog,'sendAccounts recs='+recs.size()+' userMap='+userMap.size()+' syncMap='+syncMap.size());
      for (Account acct : recs) {
         if (runLog != null && String.isBlank(runLog.ObjectId__c)) {
            runLog.ObjectId__c = acct.Id;
            ErrorLog.addToObjectInfo(runLog,String.valueOf(acct));
         }
         
         Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
         OasisSync__c sync = OasisSyncHelper.getSync(acct,syncMap);
         Contact ctct = ctctByAcctIdMap.get(acct.Id);

         // this is a new record if there isn't an old record or if there isn't a sync record and this was recently created
         //Boolean isNew = (oldAcct == null || (sync == null && acct.CreatedDate > Datetime.now().addMinutes(-10)));
         Boolean isNew = (oldAcct == null || ctct == null);
         System.debug('sendAccounts has ctct='+(ctct != null)+' isNew='+isNew);
                  
         String syncType = OasisSyncHelper.getSyncType(!isNew);
         User usr = userMap.get(acct.OwnerId);
         Boolean clientSpaceUser = (usr != null && usr.CSUserId__c != null);
         if (String.isNotBlank(syncType) && (clientSpaceUser || String.isNotBlank(acct.OasisId__c))) {
            recordsSent = true;
            buildSync(syncType, syncMap.get(acct.Id), acct, ctct, usr
                               ,insertSyncs, updateSyncs);
         }
      } // for (Account acct

      ErrorLog.addToDescription(runLog,'insertSyncs='+insertSyncs.size()+' updateSyncs='+updateSyncs.size());
      OasisSyncHelper.checkSave(insertSyncs,updateSyncs);
      return recordsSent;
      */
      return false;
   } // sendAccounts
   
   public static Boolean sendContacts(Contact[] recs, Map<Id,Contact> oldMap, ErrorLog__c runLog) {
      /*
      Boolean recordsSent = false;
      System.debug('sendContacts recs='+recs.size());
      OasisSync__c[] insertSyncs = new OasisSync__c[]{};
      OasisSync__c[] updateSyncs = new OasisSync__c[]{};
      Map<Id,User> userMap = OasisSyncHelper.getUserMap(recs);
      
      Id[] acctIds = new Id[]{};
      Boolean hasRecsToProcess = false;
      for (Contact ctct : recs) {
         if (ctct.AccountId != null) {
            acctIds.add(ctct.AccountId);
            User usr = userMap.get(ctct.OwnerId);
            if (String.isNotBlank(ctct.OasisId__c) 
                  || (usr != null && usr.CSUserId__c != null)
               ) {
               hasRecsToProcess = true;
            }
         }
      } // for
      
      if (!hasRecsToProcess) {
         return false;
      }
      
      //Boolean isConnectionUser = OasisSyncHelper.isRunningUserConnectionUser();
      
      Map<String,OasisSync__c> syncMap = OasisSyncHelper.getExistingSyncMap(recs);
      Map<Id,Account> acctMap = (!acctIds.isEmpty() ? getAcctMap(acctIds) : new Map<Id,Account>());
      // reselect this to get the owners based on the account instead of contact
      userMap = OasisSyncHelper.getUserMap(acctMap.values());
      
      for (Contact ctct : recs) {
         if (runLog != null && String.isBlank(runLog.ObjectId__c)) {
            runLog.ObjectId__c = ctct.Id;
            ErrorLog.addToObjectInfo(runLog,String.valueOf(ctct));
         }
         Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);
         OasisSync__c sync = OasisSyncHelper.getSync(ctct,syncMap);

         String syncType = OasisSyncHelper.getSyncType((oldCtct != null));
         Account acct = (ctct.AccountId != null ? acctMap.get(ctct.AccountId) : null);
         User usr = userMap.get((acct != null ? acct.OwnerId : ctct.OwnerId));
         Boolean clientSpaceUser = (usr != null && usr.CSUserId__c != null);
         ErrorLog.addToDescription(runLog,'syncType='+syncType+' clientSpaceUser='+clientSpaceUser+' OasisId__c='+acct.OasisId__c+' LEAD_WAS_CONVERTED='+DuplicateCheckQueueable.LEAD_WAS_CONVERTED);
         if (String.isNotBlank(syncType) && acct != null && (clientSpaceUser || String.isNotBlank(acct.OasisId__c) || DuplicateCheckQueueable.LEAD_WAS_CONVERTED)) {
            recordsSent = true;
            buildSync(syncType, sync, acct, ctct, usr
                               ,insertSyncs, updateSyncs);
         }
      } // for (Contact ctct 
      
      ErrorLog.addToDescription(runLog,'insertSyncs='+insertSyncs.size()+' updateSyncs='+updateSyncs.size());
      OasisSyncHelper.checkSave(insertSyncs,updateSyncs);
      return recordsSent;
      */
      return false;
   } // sendContacts

   /*
   public static void buildSync(String syncType, OasisSync__c sync, Account acct, Contact ctct, User usr
                               ,OasisSync__c[] insertSyncs, OasisSync__c[] updateSyncs) {
      sync = OasisSyncHelper.prepareSync(sync, (ctct != null ? (ctct.FirstName+' '+ctct.LastName) : (acct != null ? acct.Name : 'NoName')));
      if (usr != null && usr.HR_Person_Id__c != null) {
         sync.OwnerHRPersonID__c = usr.HR_Person_Id__c;
      }
      sync.SyncType__c = syncType;
      
      setAcctFlds(sync, acct);
      
      if (ctct != null) {
         sync.FirstName__c = ctct.FirstName;
         sync.LastName__c = ctct.LastName;
         sync.ContactIdPayx__c = ctct.Id;
         sync.ContactIdOasis__c = ctct.OasisId__c;
         sync.Email__c = ctct.Email;
         sync.MobilePhone__c = ctct.MobilePhone;
         sync.Phone__c = ctct.Phone;
         sync.Title__c = ctct.Title;
         sync.CSContactID__c = ctct.CSContactID__c;
         sync.MailingStreet__c = ctct.MailingStreet;
         sync.MailingCity__c = ctct.MailingCity;
         sync.MailingState__c = ctct.MailingState;
         sync.MailingPostalCode__c = ctct.MailingPostalCode;
         sync.CSOrgID__C = ctct.CSOrgID__c;
         sync.Contact__c = ctct.Id;
         
      } // if (ctct != null
      
      if (sync.Id == null) {
         insertSyncs.add(sync);
      } else {
         updateSyncs.add(sync);
      }

   } // buildSync
   
   public static void setAcctFlds(OasisSync__c sync, Account acct) {
      if (acct != null) {
         sync.AccountIdPayx__c = acct.Id;
         sync.AccountIdOasis__c = acct.OasisId__c;
         sync.Address__c=acct.BillingStreet;
         sync.City__c = acct.BillingCity;
         sync.Company__c = acct.Name;
         sync.CSImportID__c = acct.CSImportID__c;
         sync.CSOrgCategory__c = acct.CSOrgCategory__c;
         sync.CSOrgID__c = acct.CSOrgID__c;
         sync.CSOrgStatus__c = acct.CSOrgStatus__c;
         sync.CSCMContractStatus__c = acct.CSCMContractStatus__c;
         sync.CSPrimaryClientNumber__c = acct.CSPrimaryClientNumber__c;
         sync.CSServiceType__c = acct.CSServiceType__c;
         sync.CS_Client_Number__c = acct.Other_PEO_Client_Number__c;
         sync.DBA__c = acct.DBA__c;
         sync.DoNotCall__c = acct.Do_Not_Call__c;
         sync.Fax__c = acct.Fax;
         sync.Federal_ID_Number__c = acct.Federal_ID_Number__c;
         sync.Industry__c = acct.Industry;
         sync.LeadSource__c = acct.Lead_Source__c;
         sync.NAICSCode__c = acct.NAICS_Code__c;
         sync.NumberOfEmployees__c = acct.NumberOfEmployees;
         sync.Phone2__c = acct.Phone;
         sync.PostalCode__c = acct.BillingPostalCode;
         sync.SICCode__c = acct.SIC_Code__c;
         sync.State__c = acct.BillingState;
         sync.Website__c = acct.Website;
         sync.Account__c = acct.Id;
         
         if (sync.SyncType__c == OasisSyncHelper.SYNC_NEW && String.isBlank(acct.CSOrgStatus__c)) {
            sync.CSOrgStatus__c = 'Prospect';
            sync.CSCMContractStatus__c = 'Prospect';
            sync.CSOrgCategory__c = 'Prospect';
         }
         
      //acct.Frequency__c = rec.Frequency__c;

      } // if (acct != null
      
   } // setAcctFlds
   
   public static Map<Id,Contact> getLatestContactMap(Account[] accts) {
      // get a map of contacts by Account Id - so we can send accounts that already exist
      Id[] acctIds = new Id[]{};
      for (Account acct : accts) {
         acctIds.add(acct.Id);
      }
      
      Map<Id,Contact> ctctByAcctIdMap = new Map<Id,Contact>();
      for (Contact[] ctcts : [Select Id, AccountId, OwnerId, FirstName, LastName
                                    ,Email
                                    ,MobilePhone
                                    ,Phone
                                    ,Title
                                    ,CSContactID__c
                                    ,CSOrgID__c
                                    ,MailingStreet
                                    ,MailingCity
                                    ,MailingState
                                    ,MailingPostalCode
                                    ,OasisId__c
                                From Contact
                               Where AccountId in :acctIds
                                Order by LastModifiedDate desc]) {
         for (Contact ctct : ctcts) {
            if (!ctctByAcctIdMap.containsKey(ctct.AccountId)) {
               ctctByAcctIdMap.put(ctct.AccountId, ctct);
            }
         }
      } // for (Contact[] ctcts
      return ctctByAcctIdMap;
   } // getLatestContactMap
   
   public static Map<Id,Account> getAcctMap(Id[] acctIds) {
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, OwnerId
                                                           ,BillingStreet
                                                           ,BillingCity
                                                           ,Name
                                                           ,CSImportID__c
                                                           ,CSOrgCategory__c
                                                           ,CSOrgID__c
                                                           ,CSOrgStatus__c
                                                           ,CSCMContractStatus__c
                                                           ,CSPrimaryClientNumber__c
                                                           ,CSServiceType__c
                                                           ,Other_PEO_Client_Number__c
                                                           ,DBA__c
                                                           ,Do_Not_Call__c
                                                           ,Fax
                                                           ,Federal_ID_Number__c
                                                           ,Industry
                                                           ,Lead_Source__c
                                                           ,NAICS_Code__c
                                                           ,NumberOfEmployees
                                                           ,OasisId__c
                                                           ,Phone
                                                           ,BillingPostalCode
                                                           ,SIC_Code__c
                                                           ,BillingState
                                                           ,Website
                                                       From Account
                                                      Where Id in :acctIds]);
      return acctMap;
   } // getAcctMap
   */

} // class OasisSyncAcctCtct