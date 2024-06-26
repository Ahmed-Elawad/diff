/* 
 * A batch job moving closed cases associated with the Paychex Inc SA account to other (backup) accounts
 *
 * History
 * -------
 * 12/09/2015 Dan Carmen     Created
   03/07/2017 Dan Carmen     Change to run for all record types
 *
 */
global with sharing class CaseArchive implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

   // The time the process started. 
   global DateTime startTime;

   // the number of cases processed
   global Integer numberCases = 0;
   global Integer accountsCreated = 0;
   global Integer contactsCreated = 0;
   global Integer casesUpdatedToExistingContacts = 0;
   global Integer casesUpdatedToNewContacts = 0;
   global Map<String,Integer> countByRecordTypeMap = new Map<String,Integer>();
   
   // number of days to check for since last modified
   public static Integer nbrCheckDays = Integer.valueOf(Label.Case_Archive_Days);

   global JobHelper jh = new JobHelper('CaseArchive');

   global CaseArchive() {
      startTime = DateTime.now();
   } // CaseArchive
   
   public static Boolean ALL_RECORDTYPES = (Label.CaseArchiveAllRTs == 'Y');
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      DateTime checkTime = DateTime.now().addDays(-nbrCheckDays);
      
      Map<String,Schema.RecordTypeInfo> rtByName = new Map<String,Schema.RecordTypeInfo>();
      Map<String,Schema.RecordTypeInfo> rtById = new Map<String,Schema.RecordTypeInfo>();
      RecordTypeHelper.getRecordTypesMap(ObjectHelper.OBJECT_CASE,rtById,rtByName);

      String[] recordTypeIds = new String[]{};
      
      if (ALL_RECORDTYPES) {
         recordTypeIds.addAll(rtById.keySet());
      } else {
         // get the valid record types
         for (RecordType__c rt : RecordType__c.getAll().values()) {
            if (rt.UseInCaseArchive__c) {
               Schema.RecordTypeInfo rtInfo = rtByName.get(rt.Name);
               if (rtInfo != null) {
                  recordTypeIds.add(rtInfo.getRecordTypeId());
               }
            }
         } // for (RecordType__c rt
      }
      return Database.getQueryLocator([SELECT Id
                                             ,AccountId
                                             ,ClosedDate
                                             ,Contact.Id
                                             ,Contact.Name
                                             ,Contact.LastName
                                             ,Contact.HR_Person_Id__c
                                             ,ContactId
                                             ,IsClosed
                                             ,LastModifiedDate
                                             ,RecordTypeId
                                             ,RecordType.Name
                                             ,Status
                                         FROM Case 
                                        WHERE ClosedDate <= :checkTime
                                          and Account.Name=:UserHelper.PAYCHEX_COMP
                                          and Contact.HR_Person_Id__c != null
                                          and RecordTypeId in :recordTypeIds
                                          and IsClosed = true]);
   } // start

   public static Integer BATCH_SIZE=100;

   // In order to schedule a batch run
   global void execute(SchedulableContext sc) {
      CaseArchive ca = new CaseArchive();
      database.executeBatch(ca, BATCH_SIZE);
   } // execute

   // Execute a batch.
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<Case> cases = (List<Case>)scope;
      numberCases += cases.size();
      processCases(cases);
   } // execute

   private void processCases(List<Case> cases) {
      System.debug('processCases nbrRecs='+cases.size());
      // collect the contact ids and first letter of last name
      Map<Id,Case[]> caseByContactIdMap = new Map<Id,Case[]>();
      // the account names for the Paychex Inc SA accounts
      Set<String> accountNameSet = new Set<String>();
      for (Case cs : cases) {
         // keep track of how many records by record type name
         Integer checkRtCount = countByRecordTypeMap.get(cs.RecordType.Name);
         Integer rtCount = (checkRtCount == null ? 0 : checkRtCount) + 1;
         countByRecordTypeMap.put(cs.RecordType.Name,rtCount);

         Case[] caseList = caseByContactIdMap.get(cs.ContactId);
         if (caseList == null) {
            caseList = new Case[]{};
            caseByContactIdMap.put(cs.ContactId,caseList);
         }
         caseList.add(cs);
         String accountName = UserHelper.PAYCHEX_COMP+'-'+cs.Contact.LastName.left(1);
         accountNameSet.add(accountname);
      }
      
      checkExistingContacts(caseByContactIdMap);
      if (!caseByContactIdMap.isEmpty()) {
         createNewContacts(caseByContactIdMap,accountNameSet);
      }
      
      // update the cases - should have new values now.
      update cases;
   } // processCases
   
   // if the contact already exists 
   private void checkExistingContacts(Map<Id,Case[]> caseByContactIdMap) {
      // see if related contacts are already created
      Contact[] relatedContacts = [Select Id, AccountId, Name, ReportsToId 
                                     From Contact 
                                    where ReportsToId in :caseByContactIdMap.keySet()
                                      and Account.Name != :UserHelper.PAYCHEX_COMP
                                  ];
      for (Contact ctct : relatedContacts) {
         // remove from the map since it will be processed.
         Case[] caseList = caseByContactIdMap.remove(ctct.ReportsToId);
         if (caseList != null) {
            casesUpdatedToExistingContacts += caseList.size();
            // update the case with the existing contact information
            for (Case cs : caseList) {
               cs.ContactId = ctct.Id;
               cs.AccountId = ctct.AccountId;
            }
         } // if (caseList != null
      } // for (Contact ctct : relatedContacts
   
   } // checkExistingContacts
   
   public static Integer LASTNAME_LENGTH=Contact.LastName.getDescribe().getLength();

   global static Schema.RecordTypeInfo RT_SYS_ADMIN = null;
   global static Schema.RecordTypeInfo RT_PAYX_EMP = null;

   private void createNewContacts(Map<Id,Case[]> caseByContactIdMap, Set<String> accountNameSet) {
      
      Map<String,Account> tempAccountMap = getTempAccountMap(accountNameSet);
      // if we're creating a new Account, a map for easier lookup later 
      Map<Account,Contact[]> newAcctCtctMap = new Map<Account,Contact[]>();
      Map<String,Contact[]> newContactByAcctNameMap = new Map<String,Contact[]>();
      // the accounts we're inserting
      Account[] insertAccts = new Account[]{};

      // a list of the new contacts
      Contact[] newCtcts = new Contact[]{};
            
      if (RT_PAYX_EMP == null) {
         RT_PAYX_EMP = RecordTypeHelper.getRecordType(Label.RT_Paychex_Employee, ObjectHelper.OBJECT_CONTACT);
      }
      
      for (Case[] caseList : caseByContactIdMap.values()) {
         // use the first one (they'll all be the same contact) to create the contact/account
         Contact checkCtct = caseList[0].Contact;
         if (checkCtct != null) {
            // does the account exist?
            String acctName = UserHelper.PAYCHEX_COMP+'-'+checkCtct.LastName.left(1);
            Account acct = tempAccountMap.get(acctName);
            if (acct == null) {
               if (RT_SYS_ADMIN == null) {
                  RT_SYS_ADMIN = RecordTypeHelper.getRecordType(Label.RT_System_Admin_Account, ObjectHelper.OBJECT_ACCOUNT);
               }
               // create a new account record
               acct = new Account(Name=acctName, RecordTypeId=RT_SYS_ADMIN.getRecordTypeId());
               System.debug('createNewContacts new acct='+acct);
               // put in the tempAccountMap
               tempAccountMap.put(acctName,acct);
               insertAccts.add(acct);
            } // if (acct == null
            
            // create a new Contact
            Contact newCtct = new Contact(FirstName='Archive',LastName=checkCtct.Name.left(LASTNAME_LENGTH)
                                         ,ReportsToId=checkCtct.Id
                                         ,RecordTypeId=RT_PAYX_EMP.getRecordTypeId(),AccountId=acct.Id);
            newCtcts.add(newCtct);
            System.debug('createNewContacts new newCtct='+newCtct);
            
            // is this a new account?
            if (acct.Id == null) {
               //Contact[] ctcts = newAcctCtctMap.get(acct);
               Contact[] ctcts = newContactByAcctNameMap.get(acct.Name);
               //System.debug('createNewContacts new acct ctcts='+ctcts);
               if (ctcts == null) {
                  ctcts = new Contact[]{};
                  //newAcctCtctMap.put(acct,ctcts);
                  newContactByAcctNameMap.put(acct.Name,ctcts);
               }
               ctcts.add(newCtct);
               System.debug('createNewContacts new acct ctcts='+ctcts.size());
            } // if (acct.Id == null
         } // if (checkCtct != null
      } // for (Id contactId
      
      // if we had to create new accounts, save the accounts, then update the contacts
      if (!insertAccts.isEmpty()) {
         insert insertAccts;
         System.debug('createNewContacts insertAccts='+insertAccts.size());
         
         accountsCreated += newAcctCtctMap.keySet().size();
         
         for (Account acct : insertAccts) {
            //Contact[] ctcts = newAcctCtctMap.get(acct);
            Contact[] ctcts = newContactByAcctNameMap.get(acct.Name);
            //System.debug('createNewContacts acct='+acct.Name+' setting ctcts='+ctcts);
            if (ctcts != null) {
               for (Contact ctct : ctcts) {
                  ctct.AccountId = acct.Id;
               }
            } // if (ctcts != null
         } // for (Account acct
      } // if (!newAcctCtctMap.isEmpty
      
      // save the contacts
      insert newCtcts;
      contactsCreated += newCtcts.size();
      
      // update the cases
      for (Contact ctct : newCtcts) {
         Case[] cases = caseByContactIdMap.remove(ctct.ReportsToId);
         if (cases != null) {
            casesUpdatedToNewContacts += cases.size();
            for (Case cs : cases) {
               cs.ContactId = ctct.Id;
               cs.AccountId = ctct.AccountId;
            }
         } // if (cases != null
      } // for (Contact ctct
   } // createNewContacts
   
   private Map<String,Account> getTempAccountMap(Set<String> accountNameSet) {
      Map<String,Account> tempAccountMap = new Map<String,Account>();
      for (Account acct : [Select id, Name, RecordTypeId
                             From Account
                            Where Name in :accountNameSet
                              and RecordType.Name = :Label.RT_System_Admin_Account]) {
         tempAccountMap.put(acct.Name, acct);
      } // for (Account acct
      return tempAccountMap;
   } // getTempAccountMap
   
   global void finish(Database.BatchableContext bc){
      String message = '\nTotal Cases Processed: '+numberCases+' ';
      message += '\nNumber of days checking for: '+nbrCheckDays+' '; 
      
      message += '\n\nNumber of Accounts Created: '+accountsCreated+' '; 
      message += '\nNumber of Contacts Created: '+contactsCreated+' '; 

      message += '\n\nNumber of Cases updated to Existing Contacts: '+casesUpdatedToExistingContacts+' '; 
      message += '\nNumber of Cases update to New Contacts: '+casesUpdatedToNewContacts+' '; 
      
      message += '\n\nBreakdown by RecordType: ';
      for (String rtName : countByRecordTypeMap.keySet()) {
         Integer rtCount = countByRecordTypeMap.get(rtName);
         message += '\n    '+rtName+': '+rtCount+' ';
      }
      //message += '\n\n'+processNotes;
      
      System.debug('finish message='+message);
      jh.completeJob(bc, 'Case Archive', message);
   } // finish

} // class CaseArchive