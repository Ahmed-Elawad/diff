/* 
   Check if there is at least one contact with an email address for each passed in account
   
  History
  -------
  06/24/2011 Dan Carmen   Created
  08/02/2011 Dan Carmen   Remove sharing.
  05/30/2012 Dan Carmen   Cleaning up code
  02/09/2018 Dan Carmen   Add in check for Do_Not_Sync__c flag
   
 */
global without sharing class AccountCheckContactEmail implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

   /** The total number of accounts selected. */
   global Integer numberAccounts = 0;
   /** The total number of accounts where the flag is set to false. */
   global Integer numberAccountsToFalse = 0;
   /** The total number of accounts where the flag is set to true. */
   global Integer numberAccountsToTrue = 0;
   /** The time the process started. */
   global DateTime startTime;

   /** messages that occur during the process. */
   global String processNotes = '';

   global JobHelper jh = new JobHelper('AccountCheckContactEmail');
   
   // start this January 1, 2006
   global Date batchStartDate = Date.newInstance(2006,1,1);
   global Date batchEndDate = null;

   global AccountCheckContactEmail() {
      startTime = DateTime.now();
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('AccountCheckContactEmail');
      // use the Minutes_till_Launch__c field for the number of months. Default to 6
      Integer nbrMonths = (abc != null && abc.Minutes_till_Launch__c != null ? Integer.valueOf(abc.Minutes_till_Launch__c) : 6);
      batchEndDate = batchStartDate.addMonths(nbrMonths);
   } // AccountCheckContactEmail
   
   // to be able to run the batch for a certain date range
   global AccountCheckContactEmail(Date startDate, Integer nbrMonths) {
      batchStartDate = startDate;
      batchEndDate = batchStartDate.addMonths(nbrMonths);
   }
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      Map<String,Schema.RecordTypeInfo> byNameMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
      Id[] recordTypeIds = new Id[]{};
      for (RecordType__c rt : RecordType__c.getAll().values()) {
         if (rt.ObjectName__c == ObjectHelper.OBJECT_ACCOUNT && rt.UseForSync__c) {
            Schema.RecordTypeInfo rtInfo = byNameMap.get(rt.RecordTypeName__c);
            if (rtInfo != null) {
               recordTypeIds.add(rtInfo.getRecordTypeId());
            }
         }
      } // for
      System.debug('recordTypeIds='+recordTypeIds);
      // get the record types from the custom setting
      
      // save the record - show that the job started
      jh.setStarted();
      // check all accounts in the database - batch by date so that the job can complete
      return Database.getQueryLocator([Select Id, Name, Contact_Email_Available__c
                               ,(select Id, Email
                                   From Contacts
                                  where Email != null
                                    and isDeleted=false
                                    and Sales_Contact__c=true
                                    and Do_Not_Sync__c=false
                                  limit 1)
                           from Account
                          where RecordTypeId in :recordTypeIds
                            and CreatedDate >= :batchStartDate
                            and CreatedDate <= :batchEndDate]);
   } // start

   // In order to schedule a batch run
   global void execute(SchedulableContext sc) {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('AccountCheckContactEmail');
      Integer batchSize = (abc != null ? Integer.valueOf(abc.BatchSize__c) : 1000);
      AccountCheckContactEmail acce = new AccountCheckContactEmail();
      database.executeBatch(acce, batchSize);
   } // execute

   // Execute a batch.
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<Account> accts = (List<Account>)scope;
      Account[] updateAccts = new Account[]{};
      numberAccounts += accts.size();
      System.debug('execute numberAccounts='+numberAccounts);
      
      checkAcctFlag(accts, updateAccts);
      
      if (!updateAccts.isEmpty()) {
         DmlHelper.performDML2(updateAccts, DmlHelper.DML_UPDATE, 'AccountCheckContactEmail', 'execute', 'updating accounts', true);
      }
   } // execute
   
   public void checkAcctFlag(Account[] accts, Account[] updateAccts) {
      // loop through the accounts returned and see if the flag will change on any
      for (Account acct : accts) {
         System.debug('checkAcctFlag acct='+acct.Name+' contacts='+acct.Contacts);
         if ((acct.Contacts == null || acct.Contacts.size() == 0) && acct.Contact_Email_Available__c) {
            System.debug('checkAcctFlag Setting to false');
            acct.Contact_Email_Available__c = false;
            numberAccountsToFalse++;
            updateAccts.add(acct);
         } else if (acct.Contacts.size() > 0 && !acct.Contact_Email_Available__c) {
            System.debug('checkAcctFlag Setting to true');
            acct.Contact_Email_Available__c = true;
            numberAccountsToTrue++;
            updateAccts.add(acct);
         }
      } // for
      
      System.debug('checkAcctFlag updateAccts='+updateAccts.size()+' numberAccountsToFalse='+numberAccountsToFalse+' numberAccountsToTrue='+numberAccountsToTrue);
   } // checkAcctFlag
   
   global void finish(Database.BatchableContext bc){
      String message = '\nTotal Accounts Processed for '+batchStartDate.format()+' to '+batchEndDate.format()+': '+numberAccounts+' '; 
      message += '\nNumber accounts where Contact Email Available was set to false: '+numberAccountsToFalse+' '; 
      message += '\nNumber accounts where Contact Email Available was set to true: '+numberAccountsToTrue+' '; 
      
      message += '\n\n'+processNotes;
      
      jh.completeJob(bc, 'Account Check Contact Email update', message);
      
      if (batchEndDate < Date.today()) {
         Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('AccountCheckContactEmail');
         Integer nbrMonths = (abc != null && abc.Minutes_till_Launch__c != null ? Integer.valueOf(abc.Minutes_till_Launch__c) : 6);
         AccountCheckContactEmail rsb = new AccountCheckContactEmail(batchEndDate, nbrMonths);
         Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 1000);
         if (!Test.isRunningTest() && abc != null && abc.Active__c) {
            database.executeBatch(rsb, batchSize);
         }
      } // if (batchEndDate
   } // finish

   /*
   public static void checkContacts(Set<Id> accountIds) {
   	// only need to select 1 contact that has an email address.
      Account[] accts = [Select Id, Name, Contact_Email_Available__c
                               ,(select Id, Email
                                   From Contacts
                                  where Email != null
                                    and isDeleted=false
                                    and Sales_Contact__c=true
                                  limit 1)
                           from Account
                          where Id in :accountIds
                            and RecordType.Name != :SYSTEM_ADMINISTRATION_ACCOUNT];
      Account[] updateAccts = new Account[]{};
      // loop through the accounts returned and see if the flag will change on any
      for (Account acct : accts) {
      	System.debug('acct='+acct.Name+' contacts='+acct.Contacts);
         if ((acct.Contacts == null || acct.Contacts.size() == 0) && acct.Contact_Email_Available__c) {
         	System.debug('Setting to false');
            acct.Contact_Email_Available__c = false;
            numberAccountsToFalse++;
            updateAccts.add(acct);
         } else if (acct.Contacts.size() > 0 && !acct.Contact_Email_Available__c) {
         	System.debug('Setting to true');
            acct.Contact_Email_Available__c = true;
            numberAccountsToTrue++;
            updateAccts.add(acct);
         }
      } // for
      
      if (!updateAccts.isEmpty()) {
         update updateAccts;
      }
   } // checkContacts
   */
} // class AccountCheckContactEmail