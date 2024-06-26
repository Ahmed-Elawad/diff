/* Batch process to find expired hold outs on accounts and remove them
   
  History
  -------
  04/24/2015 Dan Carmen      Created
  07/17/2019 Dan Carmen      Modify to tune up SQL
  10/17/2019 Josh Cartwright added Lead Expirations 
  
 */
global without sharing class HoldOutAcctBatch implements Database.Batchable<SObject>, Database.Stateful , Schedulable {
   
   public static String CLASS_NAME='HoldOutAcctBatch';

   public static String MODE_ACCTS='Accounts';
   public static String MODE_CTCTS='Contacts';
   public static string MODE_LEADS='Leads';  
   
   
   global String currentMode = null;

   // The number of days in the past to check for changes.
   global Integer checkDays = 3;
   // The total number of account records found.
   global Integer numberAccounts = 0;
   // The total number of user records found matching the contacts.
   global Integer numberUsers = 0;
   // The total number of user records updated.
   global Integer nbrUsersUpdated = 0;
   
   global Integer nbrPayrollHoldouts=0;
   global Integer nbrHrsHoldouts=0;
   global Integer nbrPasHoldouts=0;
   global Integer nbrHnbfHoldouts=0;
   global Integer nbrMSHoldouts=0;
   global Integer nbrCtctHoldouts=0;
   global integer nbrLeadHoldouts=0; 
   
   global Map<String,Integer> holdOutFldCntMap = new Map<String,Integer>();
   
   global Date checkDate = Date.today();
   
   /** messages that occur during the process. */
   global String processNotes = '';
   
   global JobHelper jh = new JobHelper(CLASS_NAME);
   
   global HoldOutAcctBatch(String p_currentMode) {
      currentMode = p_currentMode;
   }

   global HoldOutAcctBatch() {
   } // UserUpdateFromContact
   
   public static Boolean USE_CONTACTS_IN_BATCH=(Label.HoldOutAcctBatch_UseContacts == 'Y');
   // Map of the hold out field to hold out expiration date fields
   global Map<String,String> holdOutFldMap = new Map<String,String>();
   // Map of the hold out field to hold out reason field
   global Map<String,String> holdOutReasonFldMap = new Map<String,String>();
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      if (currentMode == null) {
         currentMode = MODE_ACCTS;
      }
      // save the record - show that the job started
      jh.tracker.Job_Name__c += currentMode;
      jh.setStarted();
      /*
      // check for contacts that have hold outs - we can't do a sub-select with an OR, so pulling it out here
      Set<Id> accountIdSet = new Set<Id>();
      if (USE_CONTACTS_IN_BATCH) {
         for (Contact[] ctcts : [Select AccountId from Contact where Hold_Out__c = true AND Hold_Out_Expiration__c <= :checkDate limit 10000]) {
            for (Contact ctct : ctcts) {
               accountIdSet.add(ctct.AccountId);
            }
         } // for
      } // if (USE_CONTACTS_IN_BATCH
      */
      String query = 'Select Id, Name, OwnerId, Use_Zip_Assignment_Rules__c ';
      
      holdOutFldMap.clear();
      holdOutReasonFldMap.clear();
      holdOutFldCntMap.clear();
      
      Date queryDate = Date.today();
      
      for (HoldOut_ExpirationDates__c holdOut : HoldOut_ExpirationDates__c.getAll().values()) {
         // only select each field name once
         if (!holdOutFldMap.containsKey(holdOut.Account_Hold_Out__c) && holdOut.Account_Hold_Out_Date__c != null) {
            // initialize the counter for this field
            holdOutFldCntMap.put(holdOut.Account_Hold_Out__c,0);
            holdOutFldMap.put(holdOut.Account_Hold_Out__c, holdOut.Account_Hold_Out_Date__c);
            query += ','+holdOut.Account_Hold_Out__c+' ,'+holdOut.Account_Hold_Out_Date__c;
            if (String.isNotBlank(holdOut.HoldOutReasonFld__c)) {
               query += ','+holdOut.HoldOutReasonFld__c;
               holdOutReasonFldMap.put(holdOut.Account_Hold_Out__c,holdOut.HoldOutReasonFld__c);
            }
         }
      } // for (HoldOut_ExpirationDates__c holdOut
       
      System.debug('HoldOutAcctBatch.start holdOutFldMap='+holdOutFldMap.size()+' holdOutReasonFldMap='+holdOutReasonFldMap.size());
      
      if (currentMode == MODE_ACCTS) {
         //query += ' ,(Select Id, OwnerId, Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c From Contacts Where Hold_Out__c = true)';
         query += ' from Account where HoldOutCheckDate__c < today ';
      } else if (currentMode == MODE_CTCTS) {
         query = 'Select Id, OwnerId, Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c, Account.OwnerId From Contact where Hold_Out__c = true and Hold_Out_Expiration__c < :queryDate';
      } else if (currentMode ==MODE_LEADS){
         query = 'select id, ownerID, Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c from Lead where Hold_Out__c =true and isConverted =false and Hold_Out_Expiration__c <:queryDate';           
      }
       
      
      System.debug('start currentMode='+currentMode+' query='+query);
      return Database.getQueryLocator(query);
      /*      
      return Database.getQueryLocator([SELECT id
                                             ,Name
                                             ,OwnerId
                                             ,Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c
                                             ,HNBF_Hold_Out__c,HNBF_Hold_Out_Expiration__c
                                             ,HRS_Hold_Out__c, HRS_Hold_Out_Expiration__c
                                             ,Premier_PBS_Hold_Out__c,Premier_PBS_Hold_Out_Expiration__c
                                             ,MS_Hold_Out__c,MS_Hold_Out_Expiration__c
                                             ,Use_Zip_Assignment_Rules__c
                                             ,(Select Id, OwnerId, Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c
                                                 From Contacts
                                                Where Hold_Out__c = true AND Hold_Out_Expiration__c <= :checkDate)
                                         FROM Account 
                                        WHERE (Hold_Out__c = true AND Hold_Out_Expiration__c <= :checkDate)
                                           OR (HNBF_Hold_Out__c = true AND HNBF_Hold_Out_Expiration__c <= :checkDate)
                                           OR (HRS_Hold_Out__c = true AND HRS_Hold_Out_Expiration__c <= :checkDate)
                                           OR (Premier_PBS_Hold_Out__c = true AND Premier_PBS_Hold_Out_Expiration__c <= :checkDate)
                                           OR (MS_Hold_Out__c = true AND MS_Hold_Out_Expiration__c <= :checkDate)
                                           OR Id in :accountIdSet
                                       ]);
       */
   } // start

   global static Integer BATCH_SIZE=500;

   /** In order to schedule a batch run
    */
   global void execute(SchedulableContext sc) {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
      // pull from the custom setting, otherwise use a default value.
      Integer batchSize = (abc != null ? Integer.valueOf(abc.BatchSize__c) : 500);
      HoldOutAcctBatch hoab = new HoldOutAcctBatch();
      database.executeBatch(hoab, batchSize);
   } // execute

   /** Execute a batch.
    */
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<Account> updateAccts = new List<Account>();
      List<Contact> updateCtcts = new List<Contact>();
      List<Lead> updateLeads = new List<Lead>();  
      System.debug('execute currentMode='+currentMode+' scope='+scope.size());

      if (currentMode == MODE_ACCTS) {
         Account[] accts = (Account[])scope;
         numberAccounts += accts.size();
         Id[] acctIds = new Id[]{};
         for (Account acct : accts) {
            acctIds.add(acct.Id);
            processAccount(acct, updateAccts);
         }
      
         checkForContacts(acctIds, updateCtcts);
      } else if (currentMode == MODE_CTCTS) {
         Contact[] ctcts = (Contact[])scope;
         processContacts(ctcts,updateCtcts);
      } else if(currentMode== MODE_LEADS){
          Lead[] lds = (Lead[])scope; 
          processLeads(lds, updateLeads); 
      }
      
      System.debug('execute updateAccts='+updateAccts.size()+' updateCtcts='+updateCtcts.size()+' updateLeads='+updateLeads.size());
      if (!updateAccts.isEmpty()) {
         try {
            update updateAccts;
         } catch (Exception e) {
            ErrorLog.logError('HoldOutAcctBatch', 'execute', 'updateAccts', updateAccts[0].Id, e, updateAccts[0],true);
         }
      }
      if (!updateCtcts.isEmpty()) {
         try {
            update updateCtcts;
         } catch (Exception e) {
            ErrorLog.logError('HoldOutAcctBatch', 'execute', 'updateCtcts', updateCtcts[0].Id, e, updateCtcts[0],true);
         }
         
      }
       if(!updateLeads.isEmpty()){
          try {
            update updateLeads;
         } catch (Exception e) {
            ErrorLog.logError('HoldOutAcctBatch', 'execute', 'updateLeads', updateLeads[0].Id, e, updateLeads[0],true);
         }
       } 
   } // execute
   
   global void processAccount(Account acct, List<Account> updateAccts) {
      Boolean updateAcct = false;
      
      for (String holdOutFld : holdOutFldMap.keySet()) {
         String dateFld = holdOutFldMap.get(holdOutFld);
         Boolean holdOut = (Boolean)acct.get(holdOutFld);
         Date holdOutExpiration = (Date)acct.get(dateFld);
         system.debug('jc if statement holdOutExpiration '+ holdOutExpiration + 'checkDate '+checkDate); 
         if (holdOutExpiration != null && holdOutExpiration <= checkDate ) {
            Integer recCnt = holdOutFldCntMap.get(holdOutFld);
            recCnt = (recCnt != null ? recCnt+1 : 1);
            holdOutFldCntMap.put(holdOutFld,recCnt);
            acct.put(holdOutFld,false);
            acct.put(dateFld,null);
            updateAcct = true;
            String holdOutReasonFld = holdOutReasonFldMap.get(holdOutFld);
            if (String.isNotBlank(holdOutReasonFld)) {
               acct.put(holdOutReasonFld,null);
            }
         }
      } // for (String holdOutFld : holdOutFldMap.keySet

      if (updateAcct) {
         acct.Use_Zip_Assignment_Rules__c = true;
         updateAccts.add(acct);
      }
   } // processAccount
   
   public void checkForContacts(Id[] acctIds, List<Contact> updateCtcts) {
      System.debug('checkForContacts acctIds='+acctIds.size());
      for (Contact[] ctcts : [Select Id, OwnerId, Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c
                                    ,Account.OwnerId
                                From Contact
                               Where Hold_Out__c = true
                                 and Hold_Out_Expiration__c < :Date.today()
                                 and AccountId in :acctIds]) {
         processContacts(ctcts,updateCtcts);
      } // for (Contact[] ctcts
   } // checkForContacts
   
   public void processContacts(Contact[] ctcts, List<Contact> updateCtcts) {
      for (Contact ctct : ctcts) {
         nbrCtctHoldouts++;
         ctct.Hold_Out__c=false;
         ctct.Hold_Out_Expiration__c=null;
         ctct.Hold_Out_Reason__c=null;
         if (ctct.Account != null && ctct.Account.OwnerId != null) {
            ctct.OwnerId = ctct.Account.OwnerId;
         }
         updateCtcts.add(ctct); 
      }
   } // processContacts
    
    public void processLeads(Lead[] leads, List<lead> updateLeads ) {
        for(Lead ld: leads){
            nbrLeadHoldouts++;  
            ld.Hold_Out__c = false; 
            ld.Hold_Out_Expiration__c=null; 
            ld.Hold_Out_Reason__c = null; 
            ld.UseZipAssignmentRules__c =true; 
            
            updateLeads.add(ld); 
            
        }//for
    }
   
   global void finish(Database.BatchableContext bc){
      String message = '\nMode='+currentMode;
      message += '\nTotal Accounts Processed: '+numberAccounts+' '; 
      for (String holdOutFld : holdOutFldCntMap.keySet()) {
         message += '\nNumber of Account '+holdOutFld+' remove: '+holdOutFldCntMap.get(holdOutFld);
      }
      message += '\nNumber of Contact Hold Outs removed: '+nbrCtctHoldouts;
      message += '\nNumber of Lead Hold Outs removed:' +nbrLeadHoldouts; 
      message += '\n\n'+processNotes;
      
      jh.completeJob(bc, 'User Update From Contact update', message);

      // can't run a batch job more than once in a test
      if (!Test.isRunningTest()) {
         if (currentMode == MODE_ACCTS) {
            Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
            if (abc != null && abc.Active__c) {
               Integer batchSize = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 500);
               HoldOutAcctBatch hoab = new HoldOutAcctBatch(MODE_CTCTS);
               database.executeBatch(hoab, batchSize);
            }
         }
          if(currentMode == MODE_CTCTS){
            Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
            if (abc != null && abc.Active__c) {
               Integer batchSize = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 500);
               HoldOutAcctBatch hoab = new HoldOutAcctBatch(MODE_LEADS);
               database.executeBatch(hoab, batchSize);
            }              
          }//if MODE_CTCTS 
      } // if (!Test.isRunningTest
   } // finish
   
} // class HoldOutAcctBatch