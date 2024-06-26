/* Methods for the AccountMatch__c object

 * History
 * -------
  07/27/2022 Dan Carmen           Created

*/
public without sharing class AccountMatch implements TriggerInterfaceC {
   public static final String CLASSNAME='AccountMatch';
   public static Boolean SKIP_TRIGGER=false;
   public static Integer MAX_ATTEMPTS=666;
    
   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      System.debug('AccountMatch.handleTrigger SKIP_TRIGGER='+SKIP_TRIGGER+' recs='+recs.size()+' isBefore='+isBefore+' isAfter='+isAfter);
      if (SKIP_TRIGGER) {
         return;
      }
      SObjectType objType = null;
      if (recs != null && !recs.isEmpty()) {
         objType = recs[0].getSObjectType();
      }
      System.debug('AccountMatch.handleTrigger objType='+objType);

      if (isBefore) {
         System.debug('AccountMatch.handleTrigger isBefore');
         if (objType == AccountMatch__c.sObjectType) {
             System.debug('AccountMatch.handleTrigger AccountMatch__c');
             handleAccountMatchBefore((AccountMatch__c[])recs, (Map<Id,AccountMatch__c>)oldMap);
         } else if (objType == Account.sObjectType) {
             handleAccountsBefore((Account[])recs, (Map<Id,Account>)oldMap);
         }
      } // if (isBefore
   } // handleTrigger
    
   public static void handleAccountsBefore(Account[] recs, Map<Id,Account> oldMap) {
      Map<String,Account> searchMap = new Map<String,Account>();
      for (Account acct : recs) {
         Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
         // if the bis id or account number change, look for the AccountMatch record
         if (String.isNotBlank(acct.AccountNumber) && (oldMap == null || acct.AccountNumber != oldAcct.AccountNumber)) {
             searchMap.put(acct.AccountNumber, acct);
         }
      } // for (Account acct : recs
      System.debug('handleAccountsBefore recs='+recs.size()+' searchMap='+searchMap.size());
      if (!searchMap.isEmpty()) {
         checkForAccountMatches(searchMap);
      }
   } // handleAccountsBefore
    
   public static void checkForAccountMatches(Map<String,Account> searchMap) {
      AccountMatch__c[] matches = [Select Id, Name, AccountName__c, BisId__c
                                         ,Finished__c, LastMatchAttempt__c, NbrMatchAttempts__c
                                     From AccountMatch__c
                                    Where Name in :searchMap.keySet()
                                      and Account__c = null
                                      and Finished__c = false];
      AccountMatch__c[] updateMatches = new AccountMatch__c[]{};
      for (AccountMatch__c am : matches) {
          Account acct = searchMap.get(am.Name);
          if (acct != null) {
             am.BisIdUpdated__c = (acct.Bis_ID__c == null);
             if (acct.Bis_ID__c == null) {
                acct.Bis_ID__c = Integer.valueOf(am.BisId__c);
             }
             am.Account__c = acct.Id;
             am.Finished__c = true;
             am.LastMatchAttempt__c = Date.today();
             am.NbrMatchAttempts__c = (am.NbrMatchAttempts__c != null ? am.NbrMatchAttempts__c : 0) + 1;
             am.MatchBy__c = 'Account';
             updateMatches.add(am);
          }
      } // for (AccountMatch__c am
       
      if (!updateMatches.isEmpty()) {
         SKIP_TRIGGER=true;
         DmlHelper.performDML2(updateMatches, DmlHelper.DML_UPDATE, CLASSNAME, 'checkForAccountMatches', 'Update match record', true);
         SKIP_TRIGGER=false;
      }
   } // checkForAccountMatches
    
   public static void handleAccountMatchBefore(AccountMatch__c[] recs, Map<Id,AccountMatch__c> oldMap) {
      Map<String,AccountMatch__c> matchMap = new Map<String,AccountMatch__c>();
      for (AccountMatch__c am : recs) {
         // search every time the record is updated, up until we hit the max. 
         if (!am.Finished__c && am.NbrMatchAttempts__c != null && am.NbrMatchAttempts__c >= MAX_ATTEMPTS) {
            am.Finished__c = true;
         } else if (!am.Finished__c && (am.NbrMatchAttempts__c == null || am.NbrMatchAttempts__c < MAX_ATTEMPTS)) {
             am.NbrMatchAttempts__c = (am.NbrMatchAttempts__c != null ? am.NbrMatchAttempts__c : 0) + 1;
             am.LastMatchAttempt__c = Date.today();
             matchMap.put(am.Name, am);
         } // if (!am.Finished__c
      } // for (AccountMatch__c am
      System.debug('handleAccountMatchBefore matchMap='+matchMap.size());
      if (!matchMap.isEmpty()) {
         searchForAccounts(matchMap);
      }

   } // handleAccountMatchBefore
    
   public static void searchForAccounts(Map<String,AccountMatch__c> matchMap) {
      Account[] accts = [Select Id, Name, Bis_Id__c, AccountNumber, ProcessNotes__c
                           From Account
                          Where AccountNumber in :matchMap.keySet()];
      Account[] updateAccts = new Account[]{};
      for (Account acct : accts) {
         AccountMatch__c am = matchMap.get(acct.AccountNumber);
         if (am != null) {
            am.Account__c = acct.Id;
            am.Finished__c = true;
            am.MatchBy__c = 'AccountMatch__c';
             
            String acctBisId = String.valueOf(acct.Bis_Id__c);
            // only set if there isn't one already there
            if (acct.Bis_Id__c == null) {
               am.BisIdUpdated__c = true;
               acct.Bis_Id__c = Integer.valueOf(am.BisId__c);
               StringHelper.addToProcessNotes(acct,'Set Bis Id '+am.BisId__c+' from AccountMatch');
               updateAccts.add(acct);
            }
         } // f (am != null
      } // for (Account acct : accts
      
      if (!updateAccts.isEmpty()) {
         ZipCheckOwner.SKIP_TRIGGERS=true;
         DmlHelper.performDML2(updateAccts, DmlHelper.DML_UPDATE, CLASSNAME, 'searchForAccounts', 'Update Bis Id', true);
         ZipCheckOwner.SKIP_TRIGGERS=false;
      }
   } // searchForAccounts
    
} // class AccountMatch