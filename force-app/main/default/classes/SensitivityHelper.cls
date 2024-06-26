/* 
 * Methods to help with managing sensitivity
 *
 * History
 * -------
   09/20/2016 Dan Carmen   Created

 */
public without sharing class SensitivityHelper {

   private static Set<String> sensitivityFldSet = null;
   
   // check that the field set is setup.
   public static void checkSensitivityFldSetSetup() {
      if (sensitivityFldSet == null) {
         sensitivityFldSet = new Set<String>();
         for (ProductSensitivityFields__c psf : ProductSensitivityFields__c.getAll().values()) {
            if (psf.OnContact__c && String.isNotBlank(psf.AccountRollupField__c)) {
               sensitivityFldSet.add(psf.FieldName__c);
            }
         } // for (ProductSensitivityFields__c psf
      }
   } // checkSensitivityFldSetSetup

   // check if any actions need to occur on the contact in the after trigger.
   public static void checkAfterTrigger(Contact ctct, Contact oldCtct) {
      // check if the sensitivities changed on the contact - has to have a primary referral type to qualify
      if (String.isNotBlank(ctct.PrimaryReferralType__c) || (oldCtct != null && String.isNotBlank(oldCtct.PrimaryReferralType__c))) {
         checkSensitivityFldSetSetup();
         Boolean hasChange = false;
         for (String fldName : sensitivityFldSet) {
            Boolean curValue = (Boolean)ctct.get(fldName);
            Boolean oldValue = (oldCtct != null ? (Boolean)oldCtct.get(fldName) : null);
            if ((curValue && oldValue == null)
                || (oldValue != null && curValue != oldValue)) {
               hasChange = true;
               break;
            } // if ((curValue &&
         } // for (String fldName
         if (hasChange) {
            ctctIdEvaluateSensitivitySet.add(ctct.Id);
         }
      }
   } // checkAfterTrigger
   
   // check if there are any actions that will happen in the after trigger
   public static void checkAfterActions() {
      
      if (!ctctIdEvaluateSensitivitySet.isEmpty()) {
         checkAccountSensitivity();
      }
   } // checkAfterActions

   // the contacts that have changed sensitivities - we need to evaluate accounts that are linked to these.
   public static Set<Id> ctctIdEvaluateSensitivitySet = new Set<Id>();

   public static void checkAccountSensitivity() {
      Account[] accts = queryAccountRecords();
      Map<Id,Account> acctUpdateMap = new Map<Id,Account>();
      
      for (Account acct : accts) {
         processAccount(acct, acctUpdateMap);
         System.debug('checkAccountSensitivity acct='+acct.Name+' acctUpdateMap='+acctUpdateMap.size());
      }
      
      if (!acctUpdateMap.isEmpty()) {
         update acctUpdateMap.values();
      }
   } // checkAccountSensitivity

   public static void processAccount(Account acct, Map<Id,Account> acctUpdateMap) {
      Map<String,Boolean> sensitivityMap = new Map<String,Boolean>();
      // by default all fields will be set to false. 
      // if we find a true false for a field, we can skip it going forward and move on. If all the fields are set to true, nothing else needs to be done.

      // default all account fields to false
      for (String fldName : SensitivityHelper.acctFldMap.keySet()) {
         sensitivityMap.put(fldName, false);
      }
      // keep a local set so we know which fields have been handled.
      Set<String> fldsToCheckSet = new Set<String>();
      fldsToCheckSet.addAll(SensitivityHelper.acctFldMap.keySet());
      
      Account acctToUpdate = new Account(Id=acct.Id);
      
      Boolean acctUpdated = false;
      
      System.debug('processAccount acct='+acct.Name+' relations='+acct.AccountContactRelations.size());
      
      // loop through all of the data. We can stop as soon as we find a single positive sensitivity for each account field.
      for (String acctFldName : fldsToCheckSet) {
         Boolean hasSensitivity = false;
         // get the current field value
         Boolean currValue = (Boolean)acct.get(acctFldName);
         if (acct.AccountContactRelations.size() > 0) {
            String[] ctctFldsToCheck = SensitivityHelper.acctFldMap.get(acctFldName);
            if (ctctFldsToCheck != null) {
               for (AccountContactRelation acr : acct.AccountContactRelations) {
                  Contact ctct = acr.Contact;
                  for (String ctctFldName : ctctFldsToCheck) {
                     if ((Boolean)ctct.get(ctctFldName)) {
                        System.debug('processAccount sensitivity found for '+ctctFldName);
                        hasSensitivity = true;
                        break;
                     }
                  } // for (String ctctFldName
                  // break out of this loop if a sensitivity was found.
                  if (hasSensitivity) {
                     break;
                  }
               } // for (AccountContactRelation acr

            } // if (ctctFldsToCheck != null

         } // if (acct.AccountContactRelations.size
         System.debug('processAccount acct='+acct.Name+' acctFldName='+acctFldName+' currValue='+currValue+' hasSensitivity='+hasSensitivity);          
         if (currValue != hasSensitivity) {
            acctUpdated = true;
            acctToUpdate.put(acctFldName, hasSensitivity);
         }
      } // for (String acctFldName
      
      if (acctUpdated) {
         acctUpdateMap.put(acctToUpdate.Id, acctToUpdate);
      }
      
   } // processAccount
   

   public static String ACCT_QUERY = 'Select Id, Name ';

   // map between the contact sensitivity fields and the account fields that map to
   public static Map<String,String> sensFldMap = null;
   // map between the field on the account and all of the contact fields that roll into it.
   public static Map<String,String[]> acctFldMap = null;
   
   // map the sensitivity fields to the field on the account
   public static void checkSetup() {
      if (acctFldMap == null) {
         sensFldMap = new Map<String,String>();
         acctFldMap = new Map<String,String[]>();
         String contactFldsToSelect = '';
         String accountFldsToSelect = '';
         for (ProductSensitivityFields__c psf : ProductSensitivityFields__c.getAll().values()) {
            if (psf.OnContact__c && String.isNotBlank(psf.FieldName__c) && String.isNotBlank(psf.AccountRollupField__c)) {
               contactFldsToSelect += ' ,Contact.'+psf.FieldName__c;
               sensFldMap.put(psf.FieldName__c, psf.AccountRollupField__c);
               String[] flds = acctFldMap.get(psf.AccountRollupField__c);
               if (flds == null) {
                  flds = new String[]{};
                  acctFldMap.put(psf.AccountRollupField__c, flds);
                  accountFldsToSelect += ','+psf.AccountRollupField__c;
               }
               flds.add(psf.FieldName__c);
            } // if (psf.OnContact__c
         } // for (ProductSensitivityFields__c psf
         
         ACCT_QUERY = 'Select Id, Name ';
         // add the account fields to the query
         ACCT_QUERY += accountFldsToSelect;
         
         ACCT_QUERY += ',(Select Id, AccountId, ContactId, EndDate ,IsActive, IsDirect ,LastModifiedDate ,Roles  ,StartDate ,InheritSensitivities__c';
         ACCT_QUERY += contactFldsToSelect;
         ACCT_QUERY += ' From AccountContactRelations Where InheritSensitivities__c = true) ';
         ACCT_QUERY += ' From Account ';
         System.debug('checkSetup ACCT_QUERY='+ACCT_QUERY);
      } // if (acctFldMap == null
      
      
   } // checkSetup

   public static Account[] queryAccountRecords() {
      if (ctctIdEvaluateSensitivitySet.isEmpty()) {
         return new Account[]{};
      }
      
      Set<Id> acctIdSet = new Set<Id>();
      //for (AccountContactRelation acr : [Select Id, AccountId, ContactId from AccountContactRelation where ContactId in :ctctIdEvaluateSensitivitySet]) {
      //   acctIdSet.add(acr.AccountId);
      //}
      
      Set<Id> ctctIdSet = new Set<Id>();
      ctctIdSet.addAll(ctctIdEvaluateSensitivitySet);
      
      checkSetup();
      String query = ACCT_QUERY;
      query += ' Where Id in (Select AccountId from AccountContactRelation where ContactId in :ctctIdSet)';
      Account[] accts = Database.query(query);
      return accts;
   } // queryAccountRecords

} // class SensitivityHelper