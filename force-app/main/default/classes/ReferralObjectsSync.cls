/** This class is to handle the processing required to sync the Referral Accounts to Standard Accounts
 * History
 * -------
 * 02/21/2014 Justin Stouffer   Created
   1/7/2015 Josh Cartwright     added fields Best CPA Score in Firm and Referral Score to feed for Referral Contacts, Best CPA Score in Firm to Referral Account
   02/17/2015 Dan Carmen        Added in PAYX_ID__c field
   03/18/2015 Dan Carmen        Reworked the processReferralAccounts and processReferralContacts methods
   04/27/2015 Dan Carmen        Only check dupe blocker if there's one record to check.
   10/21/2015 Dan Carmen        Change so entire process doesn't fail if a delete fails.
   02/08/2016 Dan Carmen        Add PartnerDetail information
   05/18/2016 Carrie Marciano   Added AKC Registered fields to contact/referral contact code
   06/10/2016 Dan Carmen        Add in linking to referral parent field.
   07/13/2016 Dan Carmen        Don't bring over the other owner fields when copying over fields.
   09/22/2016 Dan Carmen        Fix for updating parent ids.
   09/27/2016 Dan Carmen        Add AccountContactRelation object into the mix
   02/08/2017 Dan Carmen        Small fix to prevent null contact duplicate records from being returned.
   03/16/2017 Dan Carmen        Changed criteria for ReferralObjectsSync call
   10/02/2017 Dan Carmen        Added in save for errors on the account update
   05/16/2018 Cindy Freeman     added query so when Ref Acct is deleted only deletes stnd Acct if stnd Acct is linked to just 1 Ref Acct
                                needed to be able to merge Referral Accounts after standard Accounts have been merged
   10/25/2018 Cindy Freeman    removed if statement that sends you to checkContactLeadLoaderFlds, can go there anytime
   12/19/2018 Dan Carmen        Added SKIP_SYNC to deletedRefAccts
   10/02/2020 Dan Carmen        Added LatestCampaign__c to mapping.
   06/07/2021 Dan Carmen        Do not fire Referral Account triggers during an update in the sync
   06/08/2023 Carrie Marciano	Set ZipCheckOwner.SKIP_TRIGGERS=false; in processReferralAccounts so that AccountAfter would fire, running AccountPartnerSync
   02/02/2024 Carrie Marciano	Deleted Sales_Development_Fee_Amount__c for the Chorus/Groove project, removing references to field in code

*/
public without sharing class ReferralObjectsSync {
   
   // provide the ability to skip the sync code.
   public static Boolean SKIP_SYNC=Test.isRunningTest();

   // the records processed by the code.   
   public static Set<Id> refObjectIdsProcessed = new Set<Id>();
    
   //public static Boolean REFERRAL_ACCOUNTS_ENTERED=false;
   public static Boolean CHECK_DETAIL_BY_FIELDS=(Label.RefObjSyncChkDetailByFlds == 'Y');

   public static String[] refCtctFieldsToCopy = null;
   public static String[] refAcctFieldsToCopy = null;
   
   public static String[] EXCLUDE_CTCT_FLDS=Label.RefObjSyncCtctFldsExclude.toLowerCase().split(',');

   public static void checkRefCtctFields() {
      if (refCtctFieldsToCopy == null) {
         Set<String> excludeFlds = new Set<String>();
         excludeFlds.addAll(EXCLUDE_CTCT_FLDS);
         // This is in the exclude set because it's going to maintained manually in the code. (Contact.Broker_Branch_ID__c from Referral_Contact__c.Branch__c)
         excludeFlds.add('broker_branch_id__c');
         FldCopyWrapper fcw = setupCopyFlds('refCtctFieldsToCopy', ObjectHelper.OBJECT_REF_CONTACT, ObjectHelper.OBJECT_CONTACT, true, excludeFlds);
          System.debug('checkRefCtctFields fcw='+fcw);
          System.debug('checkRefCtctFields - fcw.fldsToCopy:::'+ fcw.fldsToCopy);
         refCtctFieldsToCopy = fcw.fldsToCopy;
      }
   } // checkRefCtctFields

   public static String[] EXCLUDE_ACCT_FLDS=Label.RefObjSyncAcctFldsExclude.toLowerCase().split(',');

   public static void checkRefAcctFields() {
      if (refAcctFieldsToCopy == null) {
         Set<String> excludeFlds = new Set<String>();
         excludeFlds.addAll(EXCLUDE_ACCT_FLDS);
         FldCopyWrapper fcw = setupCopyFlds('refAcctFieldsToCopy', ObjectHelper.OBJECT_REF_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT, true, excludeFlds);
         refAcctFieldsToCopy = fcw.fldsToCopy;
      } // refAcctFieldsToCopy
   } // checkRefAcctFields
   
   public class FldCopyWrapper {
      public String[] fldsToCopy = new String[]{};
      public String[] fldsToCheck = new String[]{};
   } // class FldCopyWrapper
   

   public static FldCopyWrapper setupCopyFlds(String cacheName, String sourceObjectName, String destObjectName, Boolean excludeReference, Set<String> excludeFldSet) {
      FldCopyWrapper fcw = (FldCopyWrapper)CacheManager.getOrg(cacheName);
      System.debug('setupCopyFlds for '+cacheName+' found in cache='+(fcw != null));
      if (fcw == null) {
         fcw = setupCopyFlds(sourceObjectName, destObjectName, excludeReference, excludeFldSet);
         System.debug('setupCopyFlds fcw='+fcw);
         CacheManager.putOrg(cacheName, fcw);
      } // if (copyFlds == null
      return fcw;
   } // setupCopyFlds

   public static FldCopyWrapper setupCopyFlds(String sourceObjectName, String destObjectName, Boolean excludeReference, Set<String> excludeFldSet) {
      System.debug('setupCopyFlds destObjectName='+destObjectName+' excludeFldSet='+excludeFldSet);
      FldCopyWrapper fcw = new FldCopyWrapper();
      ObjectHelper objHelper = new ObjectHelper();
      Map<String, Schema.SObjectField> destfieldMap = objHelper.getFieldMap(destObjectName);
      Map<String, Schema.SObjectField> sourceFieldMap = objHelper.getFieldMap(sourceObjectName);
      // if the source and destination fields have the same name, use those
      for (String fieldName : sourceFieldMap.keySet()) {
         // only use custom fields
         Boolean useFld = (fieldName.endsWith('__c') && destfieldMap.containsKey(fieldName) && (excludeFldSet == null || !excludeFldSet.contains(fieldName)) );
         //System.debug('setupCopyFlds destObjectName='+destObjectName+' fieldName='+fieldName+' useFld='+useFld);
         if (useFld) {
            Schema.DescribeFieldResult fldResult = destfieldMap.get(fieldName).getDescribe();
            Schema.DisplayType fldType = fldResult.getType();
            
            // do not include formulas and reference fields.
            if (!fldResult.isCalculated() && !fldResult.isAutoNumber() // && fldResult.isUpdateable()
                 //&& fldType != Schema.DisplayType.ID
                 && (!excludeReference || (excludeReference && fldType != Schema.DisplayType.Reference)) 
                 ) {
               fcw.fldsToCopy.add(fieldName);
               // don't use a boolean field to know if we're going to create a partner detail
               if (fldType != Schema.DisplayType.Boolean) {
                  fcw.fldsToCheck.add(fieldName);
               }
            } // if (!fldResult.isCalculated()

         } // if (fieldName.endsWith
      } // for (String fieldName
         
      system.debug('setupCopyFlds sourceObjectName='+sourceObjectName+' destObjectName='+destObjectName+' fldsToCopy='+fcw.fldsToCopy.size()+' fldsToCheck='+fcw.fldsToCheck.size());
      return fcw;
   } // setupCopyFlds
    
   public static String ACCOUNT_QUERY='Select Id '
                                          +',Ref_Acct_Id__c'
                                          +',Mirror_Referral_Account__c'
                                          +',ReferralParent__c'
                                          +',Dataflux_Id__c'
                                          +',Name'
                                          +',BillingStreet'
                                          +',BillingCity'
                                          +',BillingState'
                                          +',BillingCountry'
                                          +',BillingPostalCode'
                                          +',ShippingStreet'
                                          +',ShippingCity'
                                          +',ShippingState'
                                          +',ShippingCountry'
                                          +',ShippingPostalCode'
                                          +',Phone'
                                          +',Referral__c'        
                                          +',Bank_Revenue__c'
                                          +',Multi_Year_Contract_Expiration_Date__c'
                                          +',Description'
                                          +',Fax'
                                          +',Permanent_Hold_Out_Description__c'
                                          +',National_Account_Number__c'
                                          +',Reason_for_Delete__c'
                                          //+',Sales_Development_Fee_Amount__c'
                                          +',Frequency__c'
                                          +',Website'
                                          +',(Select Id, Name ,Account__c from PartnerDetails__r) ';
                                          
   private static String accountQuery = null;
   
   public static String getAccountQuery() {
      if (String.isBlank(accountQuery)) {
         checkRefAcctFields();
         accountQuery = ACCOUNT_QUERY;
         // add the fields that are the same name on the referral contact and contact
         for (String fldName : refAcctFieldsToCopy) {
            accountQuery += ','+fldName;
         }
         accountQuery += ' From Account ';
      } // if (String.isBlank(contactQuery
      return accountQuery;
   } // getAccountQuery
    
   public static Map<Id,Account> queryExistingAccounts(String[] accountIds) {
      Map<Id,Account> accountMap = new Map<Id,Account>();
      if (!accountIds.isEmpty()) {
         String[] accountQueryIds = new String[]{};
         accountQueryIds.addAll(accountIds);
         String query = getAccountQuery();
         query += ' Where Id in :accountQueryIds ';
         for (Account acct : Database.query(query)) {
            accountMap.put(acct.Id, acct);
         }
      }
      System.debug('queryExistingAccounts accountMap='+accountMap.size());
      return accountMap;
   } // queryExistingAccounts
   
   public static void processReferralAccounts(list<referral_account__c> p_refAcctList, Map<Id,Referral_Account__c> oldMap){
      if (SKIP_SYNC) {
         return;
      }
      //REFERRAL_ACCOUNTS_ENTERED = true;
      // make sure the fields are setup to copy
      checkRefAcctFields();
      id rDataId = getReferralOwnerId();
      
      Id[] acctIds = new Id[]{};
      // get the parents
      Id[] parentRefAcctIds = new Id[]{};
          
      Referral_Account__c[] refAccts = new Referral_Account__c[]{};
      for (Referral_Account__c refAcct : p_refAcctList) {
         if (!refObjectIdsProcessed.contains(refAcct.Id)) {
            refObjectIdsProcessed.add(refAcct.Id);
            refAccts.add(refAcct);
            // collect the ids of the existing accounts so we can compare
            if (refAcct.Account__c != null) {
               acctIds.add(refAcct.Account__c);
            }
            if (refAcct.Parent_Referral_Account__c != null) {
               parentRefAcctIds.add(refAcct.Parent_Referral_Account__c);
            }
         }
      } // for (Referral_Account__c refAcct
      
      Map<Id,Account> acctMap = queryExistingAccounts(acctIds);
      
      //List<account> acctsToUpsertList = new List<account>();
      Account[] acctsToUpdate = new Account[]{};
      Account[] acctsToInsert = new Account[]{};
      //list<ID> refAcctIDList = new List<ID>();
        
      // keep track of all of the referrals with parents to handle differently
      //Set<Id> refAcctsWithParentSet = new Set<Id>();
      // the referral ids to update from the account
      Set<Id> refAcctsToUpdateFromAcctSet = new Set<Id>();
       
      Map<Id,Referral_Account__c> parentMap = getParentMap(parentRefAcctIds);
       
      // used for partner details
      Map<Id,Referral_Account__c> refAcctPartnerDetailMap = new Map<Id,Referral_Account__c>();
        
      //Process Referral Accounts
      for (referral_account__c refAcct : refAccts){     
         //refAcctIDList.add(refAcct.id);
         
         Account acct = (refAcct.Account__c != null ? acctMap.get(refAcct.Account__c) : null);
         Referral_Account__c oldRefAcct = (oldMap != null ? oldMap.get(refAcct.Id) : null);
         Referral_Account__c parentRefAcct = (refAcct.Parent_Referral_Account__c != null ? parentMap.get(refAcct.Parent_Referral_Account__c) : null);
         System.debug('processReferralAccounts refAcct.Parent_Referral_Account__c='+refAcct.Parent_Referral_Account__c+' parentRefAcct='+(parentRefAcct != null ? parentRefAcct.Id : null));
 
         // if we don't already have an Account, create a new one.
         if (acct == null) {
            String acctRtName = (String.isNotBlank(refAcct.Ref_Record_Type_Name__c) ? refAcct.Ref_Record_Type_Name__c : 'Referral Account Record Type');      
            system.debug('processReferralAccounts acctRtName' + acctRtName);
            
            Schema.RecordTypeInfo acctRTInfo = RecordTypeHelper.getRecordType(acctRtName, ObjectHelper.OBJECT_ACCOUNT); 
            Id acctRtId = (acctRTInfo != null ? acctRTInfo.getRecordTypeId() : null);
            acct = new Account(RecordTypeId=acctRtId, OwnerId = rDataId);
         } // if (acct == null
         
         String refAcctStreet = refAcct.Street_Address_1__c + (String.isNotBlank(refAcct.Street_Address_2__c) ? '\r\n' + refAcct.Street_Address_2__c : '');   
         
         // only save the account if there were changes
         Boolean changed = (acct.Id == null);
         
         if ((parentRefAcct == null && acct.ReferralParent__c != null)
             || (parentRefAcct != null && acct.ReferralParent__c != parentRefAcct.Id)) {
            changed = true;
            acct.ReferralParent__c = (parentRefAcct != null ? parentRefAcct.Account__c : null);
            acct.ParentId = acct.ReferralParent__c;
         }
         
         if (String.isNotBlank(refAcct.Dataflux_Id__c) && String.isBlank(acct.Dataflux_Id__c)) {
            acct.Dataflux_Id__c = refAcct.Dataflux_Id__c;
            changed = true;
         }
         
         // these are all the fields were the names don't match between Account and Referral Account
         changed = checkFldChange(changed, acct, 'Ref_Acct_Id__c', refAcct.id);
         changed = checkFldChange(changed, acct, 'Mirror_Referral_Account__c', refAcct.id);
         changed = checkFldChange(changed, acct, 'Name', refAcct.name);
         changed = checkFldChange(changed, acct, 'BillingStreet', refAcctStreet);
         changed = checkFldChange(changed, acct, 'BillingCity', refAcct.City__c);
         changed = checkFldChange(changed, acct, 'BillingState', refAcct.State_Province__c);
         changed = checkFldChange(changed, acct, 'BillingPostalCode', refAcct.Zip_Postal_Code__c);
         changed = checkFldChange(changed, acct, 'BillingCountry', refAcct.Country__c);

         changed = checkFldChange(changed, acct, 'ShippingStreet', refAcctStreet);
         changed = checkFldChange(changed, acct, 'ShippingCity', refAcct.City__c);
         changed = checkFldChange(changed, acct, 'ShippingState', refAcct.State_Province__c);
         changed = checkFldChange(changed, acct, 'ShippingPostalCode', refAcct.Zip_Postal_Code__c);
         changed = checkFldChange(changed, acct, 'ShippingCountry', refAcct.Country__c);

         changed = checkFldChange(changed, acct, 'Permanent_Hold_Out_Description__c', (refAcct.Hold_Out__c ? 'Referral Owner' : null));
               
         changed = checkFldChange(changed, acct, 'Phone', refAcct, 'Phone__c');
         changed = checkFldChange(changed, acct, 'Referral__c', refAcct, 'Referral_Source_Business_Type__c');
         changed = checkFldChange(changed, acct, 'Bank_Revenue__c', refAcct, 'Bank_Revenue_Percent__c');
         changed = checkFldChange(changed, acct, 'Multi_Year_Contract_Expiration_Date__c', refAcct, 'Contract_Expiration_Date__c');
         changed = checkFldChange(changed, acct, 'Description', refAcct, 'Description__c');
         changed = checkFldChange(changed, acct, 'Fax', refAcct, 'Fax__c');
         changed = checkFldChange(changed, acct, 'National_Account_Number__c', refAcct, 'National_Account_Code__c');
         changed = checkFldChange(changed, acct, 'Reason_for_Delete__c', refAcct, 'Reason_For_Deletion__c');
         //changed = checkFldChange(changed, acct, 'Sales_Development_Fee_Amount__c', refAcct, 'Sales_Development_Fee__c');
         changed = checkFldChange(changed, acct, 'Frequency__c', refAcct, 'Typical_Payroll_Frequency__c');
         changed = checkFldChange(changed, acct, 'Website', refAcct, 'Website__c');
         
         // copy the fields (with the same name) from the ref account to acct.
         for (String fldName : refAcctFieldsToCopy) {
            changed = checkFldChange(changed, acct, fldName, refAcct, fldName);
            //acct.put(fldName,refAcct.get(fldName));
         } // for (String fldName
         
         //acctsToUpsertList.add(acct);
         //system.debug('processReferralAccounts acctsToUpsertList=' + acctsToUpsertList.size());
           
         if (refAcct.Account__c == null || refAcct.Account_ID__c == null
               || String.isBlank(refAcct.Dataflux_Id__c)
             ) {
            refAcctsToUpdateFromAcctSet.add(refAcct.Id);
         }
           
         //System.debug('processReferralAccounts refAcct.Parent_Referral_Account__c='+refAcct.Parent_Referral_Account__c+' oldRefAcct.Parent_Referral_Account__c='+oldRefAcct != null ? oldRefAcct.Parent_Referral_Account__c : null);
         // if there's a parent id on the ref account, keep track so we can update if necessary
         //if ((refAcct.Parent_Referral_Account__c != null && (oldRefAcct == null || acct.ReferralParent__c == null))
         //     || (oldRefAcct != null && refAcct.Parent_Referral_Account__c != oldRefAcct.Parent_Referral_Account__c)) {
         //   System.debug('processReferralAccounts add to check parent account');
         //   refAcctsWithParentSet.add(refAcct.Id);
         //} else if (refAcct.Parent_Referral_Account__c == null) {
         //   System.debug('processReferralAccounts no parent found refAcct.Parent_Referral_Account__c='+refAcct.Parent_Referral_Account__c);
            // set the parent id to null if there's no parent.
         //   acct.ParentId = null;
         //   acct.ReferralParent__c = null;
         //   changed = true;
         //}

         if (changed) {
            if (acct.Id == null) {
               acctsToInsert.add(acct);
            } else {
               acctsToUpdate.add(acct);
            }
         } // if (changed
         

         system.debug(LoggingLevel.FINE,'processReferralAccounts CHECK_DETAIL_BY_FIELDS='+CHECK_DETAIL_BY_FIELDS);

         Boolean createPartnerDetail = false;
         // this is a "parent" record
         if (refAcct.Parent_Referral_Account__c == null && String.isNotBlank(refAcct.Referral_Type__c)) {
            ReferralType__c refType = ReferralType__c.getInstance(refAcct.Referral_Type__c);
            createPartnerDetail = (refType != null && refType.PartnerDetail__c);
            System.debug(LoggingLevel.FINE,'processReferralAccounts checking by ReferralType__c custom setting createPartnerDetail='+createPartnerDetail);
         } // if (refAcct.Parent_Referral_Account__c != null && 

         if (!createPartnerDetail && CHECK_DETAIL_BY_FIELDS) {
            createPartnerDetail = checkForPartnerDetail(refAcct);
         } // if (!foundByRefType && CHECK_DETAIL_BY_FIELDS
         system.debug(LoggingLevel.FINE,'processReferralAccounts createPartnerDetail='+createPartnerDetail);
           
         if (createPartnerDetail) {
            refAcctPartnerDetailMap.put(refAcct.Id, refAcct);
         }

      } // for(referral_account__c refAcct
        
      acctMap.clear(); 
      
      System.debug('processReferralAccounts acctsToInsert='+acctsToInsert.size()+' acctsToUpdate='+acctsToUpdate.size());
      
      // 12/28/2022 do we need the account triggers here? I don't think so? - yes we do!  Need to run accountafter to have accountpartnersync create the partner record
      //ZipCheckOwner.SKIP_TRIGGERS=true;
      ZipCheckOwner.SKIP_TRIGGERS=false; 
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.allowSave = true;
      dml.DuplicateRuleHeader.runAsCurrentUser = true; 
      DmlHelper.performDML2(acctsToInsert, DmlHelper.DML_INSERT, 'ReferralObjectsSync', 'processReferralAccounts', 'Insert Accounts', false, dml);
      DmlHelper.performDML2(acctsToUpdate, DmlHelper.DML_UPDATE, 'ReferralObjectsSync', 'processReferralAccounts', 'Update Accounts', false);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      //database.upsert (acctsToUpsertList,account.fields.Ref_Acct_Id__c,false);
      
      acctsToInsert.clear();
      acctsToUpdate.clear();
      
      Set<Id> queryRefAcctIdSet = new Set<Id>();
      queryRefAcctIdSet.addAll(refAcctPartnerDetailMap.keySet());
      //queryRefAcctIdSet.addAll(refAcctsWithParentSet);
      queryRefAcctIdSet.addAll(refAcctsToUpdateFromAcctSet);
            
      System.debug('processReferralAccounts queryRefAcctIdSet='+queryRefAcctIdSet.size());
      if (!queryRefAcctIdSet.isEmpty()) {
         // reselect all accounts to check for partner detail
         Account[] acctList = [Select Id
                                 ,Account_ID__c
                                 ,Dataflux_Id__c
                                 ,Name
                                 ,ParentId
                                 ,ReferralParent__c
                                 ,Mirror_Referral_Account__r.Id
                                 ,Mirror_Referral_Account__r.Account__c
                                 ,Mirror_Referral_Account__r.Account_ID__c
                                 ,Mirror_Referral_Account__r.Dataflux_Id__c
                                 //,Mirror_Referral_Account__r.SF_Account_ID__c
                                 ,Mirror_Referral_Account__r.Parent_Referral_Account__c
                                 ,Mirror_Referral_Account__r.Parent_Referral_Account__r.Account__c
                                 //,Mirror_Referral_Account__r.Parent_Referral_Account__r.SF_Account_ID__c
                                 ,PartnerDetail__c
                                 ,PartnerDetail__r.Id
                                 ,PartnerDetail__r.Name
                                 ,PartnerDetail__r.Account__c
                                 ,(Select Id, Name
                                         ,Account__c
                                     from PartnerDetails__r)
                             From Account
                            Where Mirror_Referral_Account__c in :queryRefAcctIdSet];
                         
         acctsToUpdate.clear();
         
         // accounts to update. Use a map so we don't add to a list more than once.
         Map<Id, Account> acctsToUpdateMap = new Map<Id,Account>();
         Referral_Account__c[] refAcctsToUpdate = new Referral_Account__c[]{};

         // records to insert
         //PartnerDetail__c[] partDetailInserts = new PartnerDetail__c[]{};
         // records to update
         PartnerDetail__c[] partDetailUpdates = new PartnerDetail__c[]{};
         // keep track of inserts in a map so we can update the accounts after the details are inserted
         Map<Account,PartnerDetail__c> partDetailInsertMap = new Map<Account,PartnerDetail__c>();
        
         for (Account acct : acctList) {
            // check for parent relationship
            //if (refAcctsWithParentSet.contains(acct.Mirror_Referral_Account__c)) {
            //   if (acct.Mirror_Referral_Account__r.Parent_Referral_Account__r != null) {
            //      Id parentAcctId = acct.Mirror_Referral_Account__r.Parent_Referral_Account__r.Account__c;
                  //if (parentAcctId == null && String.isNotBlank(acct.Mirror_Referral_Account__r.Parent_Referral_Account__r.SF_Account_ID__c)) {
                  //   parentAcctId = (Id)acct.Mirror_Referral_Account__r.Parent_Referral_Account__r.SF_Account_ID__c;
                  //}
            //      if ((acct.ParentId != parentAcctId) || (acct.ReferralParent__c != parentAcctId)) {
            //         acct.ParentId = parentAcctId;
            //         acct.ReferralParent__c = parentAcctId;
            //         acctsToUpdateMap.put(acct.Id,acct);
            //      }
            //   } // if (acct.Mirror_Referral_Account__r
            //} // if (refAcctsWithParentSet.contains
         
            // check if we need to update the referral account from the account         
            if (refAcctsToUpdateFromAcctSet.contains(acct.Mirror_Referral_Account__c)) {
               System.debug('processReferralAccounts Setting refAcct information');
               Referral_Account__c refAcct = acct.Mirror_Referral_Account__r;
               refAcct.Account__c = acct.Id;
               refAcct.Account_ID__c = acct.Account_ID__c;
               if (String.isBlank(refAcct.Dataflux_Id__c)) {
                  refAcct.Dataflux_Id__c = acct.Dataflux_Id__c;
               }
               //refAcct.SF_Account_ID__c = acct.Id;
               refAcctsToUpdate.add(refAcct);
            } // if (refAcctsToUpdateFromAcctSet.contains
              
            Referral_Account__c refAcct = refAcctPartnerDetailMap.get(acct.Mirror_Referral_Account__c);
            if (refAcct != null) {
               checkPartnerDetail(refAcct, acct, partDetailInsertMap, partDetailUpdates, acctsToUpdateMap);
            } // if (refAcct != null
         } // for (Account acct

         System.debug('processReferralAccounts partDetailInsertMap='+partDetailInsertMap.size()+' partDetailUpdates='+partDetailUpdates.size());
         if (!partDetailInsertMap.isEmpty()) {
            DmlHelper.performDML(partDetailInsertMap.values(), DmlHelper.DML_INSERT, 'ReferralObjectsSync', 'processReferralAccounts', 'insert partner details', false);
            // set the partner detail id on the account
            for (Account acct : partDetailInsertMap.keySet()) {
               PartnerDetail__c partDetail = partDetailInsertMap.get(acct);
               if (partDetail != null && partDetail.Id != null) {
                  acct.PartnerDetail__c = partDetail.Id;
                  acctsToUpdateMap.put(acct.Id, acct);
               }
            }
            partDetailInsertMap.clear();
         } // if (!partDetailInsertMap

         DmlHelper.performDML(partDetailUpdates, DmlHelper.DML_UPDATE, 'ReferralObjectsSync', 'processReferralAccounts', 'update partner details', false);

         DmlHelper.performDML(acctsToUpdateMap.values(), DmlHelper.DML_UPDATE, 'ReferralObjectsSync', 'processReferralAccounts', 'update accts', false);
         ReferralAccountMethods.SKIP_TRIGGERS=true;
         DmlHelper.performDML(refAcctsToUpdate, DmlHelper.DML_UPDATE, 'ReferralObjectsSync', 'processReferralAccounts', 'update refAccts', false);
         ReferralAccountMethods.SKIP_TRIGGERS=false;

         partDetailUpdates.clear();
         acctsToUpdateMap.clear();
         refAcctsToUpdate.clear();
      } // if (!queryRefAcctIdSet.isEmpty                                     

      ErrorLog.checkSave();                     

   } //processReferralAccounts
    
   public static Map<Id,Referral_Account__c> getParentMap(Id[] parentIds) {
      if (parentIds.isEmpty()) {
         return new Map<Id,Referral_Account__c>();
      }
      Map<Id,Referral_Account__c> refAcctMap = new Map<Id,Referral_Account__c>([Select Id, Account__c
                                                                                  From Referral_Account__c
                                                                                 Where Id in :parentIds
                                                                                   and Account__c != null]);
      return refAcctMap;
   } // getParentMap
    
   public static String[] partnerFieldsToCopy = null;
   public static String[] partnerFieldsToCheck = null;

   public static void checkPartnerDetail(Referral_Account__c refAcct, Account acct, Map<Account,PartnerDetail__c> partDetailInsertMap, PartnerDetail__c[] partDetailUpdates, Map<Id,Account> acctsToUpdateMap) {
      // check for the Partner Detail record - should be at most 1
      PartnerDetail__c partDetail = (acct.PartnerDetails__r != null && !acct.PartnerDetails__r.isEmpty() ? acct.PartnerDetails__r[0] : null);
      if (partDetail != null) {
         // create a record for update
         System.debug('checkPartnerDetail update existing record');
         partDetail = new PartnerDetail__c(Id=partDetail.Id);
         partDetailUpdates.add(partDetail);
         if (acct.PartnerDetail__c != partDetail.Id) {
            acct.PartnerDetail__c = partDetail.Id;
            acctsToUpdateMap.put(acct.Id, acct);
         }
      } else {
         // create a new detail record
         System.debug('checkPartnerDetail create a new detail record Account__c='+acct.Id);
         partDetail = new PartnerDetail__c(Account__c=acct.Id, Name=acct.Name);
         partDetailInsertMap.put(acct,partDetail);
         //partDetailInserts.add(partDetail);
      }
      
      // make sure the fields are setup
      setupPartnerDetailFlds();
      
      // copy the fields from the ref account to the partner detail.
      for (String fldName : partnerFieldsToCopy) {
         partDetail.put(fldName,refAcct.get(fldName));
      }
      
   } // checkPartnerDetail

   // fields to exclude 
   public static String[] EXCLUDE_PARTNER_FLDS = Label.RefObjSyncPartFldsExclude.split(',');
   
   public static void setupPartnerDetailFlds() {
      if (partnerFieldsToCopy == null) {
         Set<String> excludeFldSet = new Set<String>();
         excludeFldSet.addAll(EXCLUDE_PARTNER_FLDS);
         FldCopyWrapper fcw = setupCopyFlds('partnerFieldsToCopy', ObjectHelper.OBJECT_REF_ACCOUNT, 'PartnerDetail__c', false, excludeFldSet);
         partnerFieldsToCopy = fcw.fldsToCopy;
         partnerFieldsToCheck = fcw.fldsToCheck;
      } // if (partnerFieldsToCopy == null
   } // setupPartnerDetailFlds
    
   public static Boolean checkForPartnerDetail(Referral_Account__c refAcct) {
      setupPartnerDetailFlds();
      Boolean createPartnerDetail = false;
      for (String fieldName : partnerFieldsToCheck) {
         if (refAcct.get(fieldName) != null && String.isNotBlank(String.valueOf(refAcct.get(fieldName)))) {
            System.debug('checkForPartnerDetail createPartnerDetail=true because of '+fieldName);
            createPartnerDetail = true;
            break;
         }
      } // for (String fieldName
      return createPartnerDetail;
   } // checkForPartnerDetail
   
   //public static Boolean REFERRAL_CONTACTS_ENTERED=false;
   
   // the fields for the contact we can't determine dynmically
   public static String CONTACT_QUERY = 'Select Id, RecordTypeId'
                                  +',Ref_Contact_Id__c'
                                  +',Mirror_Ref_Ctct__c'
                                  +',LeadSource'
                                  +',OwnerId'
                                  +',LastName'
                                  +',Firstname'
                                  +',MailingStreet'
                                  +',MailingCity'
                                  +',MailingState'
                                  +',MailingPostalCode'
                                  +',MailingCountry'
                                  +',Email'
                                  +',AccountId'
                                  +',Additional_Information__c'
                                  +',AICPA_ID__c'
                                  +',AssistantName'
                                  +',AssistantPhone'
                                  +',Broker_Branch_ID__c'
                                  +',Dataflux_Id__c'
                                  +',Description'
                                  +',HasOptedOutOfEmail'
                                  +',Fax'
                                  +',General_Ledger_Contact__c'
                                  +',Group__c'
                                  +',Master_Tax_Guide__c'
                                  +',Master_Tax_Guide_Recvd_Date__c'
                                  +',MobilePhone'
                                  +',Phone'
                                  +',Reason_for_Delete__c'
                                  +',Target_Field__c'
                                  +',Title'
                                 // +',User_Lookup__c'
                                  +',LatestCampaign__c';
   
   private static String contactQuery = null;
   
   public static String getContactQuery() {
      if (String.isBlank(contactQuery)) {
         checkRefCtctFields();
         contactQuery = CONTACT_QUERY;
         // add the fields that are the same name on the referral contact and contact
         for (String fldName : refCtctFieldsToCopy) {
            contactQuery += ','+fldName;
         }
         contactQuery += ' From Contact ';
      } // if (String.isBlank(contactQuery
      return contactQuery;
   } // getContactQuery
    
   public static Map<Id,Contact> queryExistingContacts(String[] contactIds) {
      Map<Id,Contact> contactMap = new Map<Id,Contact>();
      if (!contactIds.isEmpty()) {
         String[] contactQueryIds = new String[]{};
         contactQueryIds.addAll(contactIds);
         String query = getContactQuery();
         query += ' Where Id in :contactQueryIds ';
         for (Contact ctct : Database.query(query)) {
            contactMap.put(ctct.Id, ctct);
         }
      }
      System.debug('queryExistingContacts contactMap='+contactMap.size());
      return contactMap;
   } // queryExistingContacts
   
   
   public static void processReferralContacts(list<referral_contact__c> p_refCntctList, Map<Id,Referral_Contact__c> oldMap){
      if (SKIP_SYNC) {
         return;
      }
      UserHelper.setRunningUserAttributes();
      Boolean isLeadLoader = UserHelper.runningUserIsLeadLoader;
      // if not already linked to a contact, check for duplicates
      Referral_Contact__c[] checkForDupes = new Referral_Contact__c[]{};
      Set<Id> refAcctIdSet = new Set<Id>();
      // the ids of contacts we know exist - query existing to check for change
      String[] contactIds = new String[]{};

      Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{};        
      for (Referral_Contact__c refCtct : p_refCntctList) {
         if (!refObjectIdsProcessed.contains(refCtct.Id)) {
            refCtcts.add(refCtct);
            refObjectIdsProcessed.add(refCtct.Id);
            if (refCtct.Referral_Account__c != null){
               refAcctIdSet.add(refCtct.Referral_Account__c);
            }

            if (refCtct.Contact__c == null && String.isBlank(refCtct.Contact_Id__c)) {
               checkForDupes.add(refCtct);
            } else if (refCtct.Contact__c != null) {
               contactIds.add(refCtct.Contact__c);
            }

         } // if (!refObjectIdsProcessed         
      } // for (Referral_Contact__c refCtct

      checkRefCtctFields();
      System.debug('**processReferralContacts contactIds='+contactIds);      
      Map<Id, Contact> existingContactMap = queryExistingContacts(contactIds);
      System.debug('**processReferralContacts existingContactMap='+existingContactMap.size()+' keys='+existingContactMap.keySet());        
      Map<Referral_Contact__c, List<Contact>> dupeBlockerMap = null;
      // check if there are existing contacts that match the new ones
      dupeBlockerMap = ReferralObjectsSync.dupeContactChecker(checkForDupes,refAcctIdSet);
        
        
      //REFERRAL_CONTACTS_ENTERED=true;
      //Schema.RecordTypeInfo cntctRefCntctRT;
      //String cntctRT; 
      id rDataId = getReferralOwnerId();
      //list<Contact> cntctsToUpsert = new list<Contact>();
      //list<ID> refCntctIDList = new List<ID>();       
        
      list<Account> matchingAccts = [select Id, Ref_Acct_Id__c, Mirror_Referral_Account__c from Account where Mirror_Referral_Account__c in :refAcctIdSet];   
            
      if (matchingAccts.isEmpty()) {
         // nothing returned - can't continue
         return;
      }

      
      map<Id,Account> matchingAcctsMap = new Map <Id,Account>();              
      for (account acct :matchingAccts){
         matchingAcctsMap.put(acct.Mirror_Referral_Account__c, acct);
      }
      matchingAccts.clear();
      
      Set<Id> refCtctsToUpdateFromCtctSet = new Set<Id>();
      
      Contact[] ctctsToInsert = new Contact[]{};
      Contact[] ctctsToUpdate = new Contact[]{};
      
      for (referral_contact__c refCntct: refCtcts){
         List<Contact> dupeBlockerContactList =  dupeBlockerMap.get(refCntct);
         boolean okToProceed = (dupeBlockerContactList == null || dupeBlockerContactList.isEmpty());
            
         list<id> duplicateRefContactIDs = new list<id>();
         system.debug('JS' + dupeBlockerMap.get(refCntct));
            
         if (!okToProceed) {
            for(contact thisContact: dupeBlockerContactList){
               if(thisContact.Mirror_Ref_Ctct__c == refCntct.id){
                  okToProceed = TRUE;                                         
               } else {
                  duplicateRefContactIDs.add(thisContact.Mirror_Ref_Ctct__c);
               }
            } // for(contact thisContact
         } // if (!okToProceed
            
         if (!okToProceed){                           
            string errorMessage = 'ERROR: There is already an Identical Record:';
            for(id badId: duplicateRefContactIDs){
               errorMessage += '<p><a target="_blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/'+ badId + '">';
               errorMessage +=  'Click Here for the Duplicate Record' + '</a></p><br/>';
            }
            refCntct.addError(errorMessage, FALSE);
         } else {
            // we are okay to copy this record
            
            Account acct = matchingAcctsMap.get(refCntct.Referral_Account__c);
            If (acct != null){
               //refCntctIDList.add(refCntct.id);                        
               String ctctRtName = (String.isNotBlank(refcntct.Ref_Record_Type_Name__c) ? refcntct.Ref_Record_Type_Name__c : 'Sales Partner Referral Contact Record Type');

               Schema.RecordTypeInfo cntctRefCntctRT = RecordTypeHelper.getRecordType(ctctRtName, ObjectHelper.OBJECT_CONTACT);   
               String refStreet;
               String refCity;
               String RefState;
               String RefZip;
               String RefCountry;
               if (refCntct.Mailing_Street__c == null){
                  refStreet = refCntct.Street_Address_1__c;
                  refCity = refCntct.City__c;
                  refState = refCntct.State__c;
                  refZip = refCntct.Zip_Code__c;
                  refCountry = refCntct.Country__c;
               } else {
                  refStreet = refCntct.Mailing_Street__c;
                  refCity = refCntct.Mailing_City__c;
                  refState = refCntct.Mailing_State__c;
                  refZip = refCntct.Mailing_Postal_Code__c;
                  refCountry = refCntct.Mailing_Country__c; 
               }   

               Referral_Contact__c oldRefCtct = (oldMap != null ? oldMap.get(refCntct.id) : null);
               
               Id ctctId = (refCntct.Contact__c != null ? refCntct.Contact__c :  null);
               //System.debug('**processReferralContacts refCntctlContact__c = '+ctctId+' existingContactMap.size='+existingContactMap.size());               
               Contact ctct = (ctctId != null ? existingContactMap.get(ctctId) : null);
               System.debug('processReferralContacts ctct '+(ctct != null ? 'exists' : 'does not exist'));
               
               if (ctct == null) {
                  ctct = new Contact(RecordTypeId = cntctRefCntctRT.getRecordTypeId()
                                  ,Ref_Contact_Id__c = refCntct.id
                                  ,Mirror_Ref_Ctct__c = refCntct.Id
                                  ,ownerId = rDataId);
               }
               
               Boolean changed = false;

               if (String.isNotBlank(refCntct.Dataflux_Id__c) && String.isBlank(ctct.Dataflux_Id__c)) {
                  ctct.Dataflux_Id__c = refCntct.Dataflux_Id__c;
                  changed = true;
               }
               
               changed = checkFldChange(changed, ctct, 'AccountId', acct.Id);
               changed = checkFldChange(changed, ctct, 'MailingStreet', refStreet);
               changed = checkFldChange(changed, ctct, 'MailingCity', refCity);
               changed = checkFldChange(changed, ctct, 'MailingState', refState);
               changed = checkFldChange(changed, ctct, 'MailingPostalCode', refZip);
               changed = checkFldChange(changed, ctct, 'MailingCountry', refCountry);
               
               changed = checkFldChange(changed, ctct, 'LastName', refCntct, 'Last_Name__c');
               changed = checkFldChange(changed, ctct, 'Firstname', refCntct, 'First_Name__c');
               changed = checkFldChange(changed, ctct, 'Email', refCntct, 'Email__c');
               changed = checkFldChange(changed, ctct, 'Broker_Branch_ID__c', refCntct, 'Branch__c');
               changed = checkFldChange(changed, ctct, 'Additional_Information__c', refCntct, 'Additional_Commentary__c');
               changed = checkFldChange(changed, ctct, 'AICPA_ID__c', refCntct, 'AICPA__c');
               changed = checkFldChange(changed, ctct, 'AssistantName', refCntct, 'Assistant__c');
               changed = checkFldChange(changed, ctct, 'AssistantPhone', refCntct, 'Asst_Phone__c');
               changed = checkFldChange(changed, ctct, 'Description', refCntct, 'Description__c');
               changed = checkFldChange(changed, ctct, 'HasOptedOutOfEmail', refCntct, 'Email_Opt_Out__c');
               changed = checkFldChange(changed, ctct, 'Fax', refCntct, 'Fax__c');
               changed = checkFldChange(changed, ctct, 'General_Ledger_Contact__c', refCntct, 'General_Ledger_Contact__c');
               changed = checkFldChange(changed, ctct, 'Group__c', refCntct, 'Group_number__c');
               changed = checkFldChange(changed, ctct, 'Master_Tax_Guide__c', refCntct, 'Master_Tax_Guide_del__c');
               changed = checkFldChange(changed, ctct, 'Master_Tax_Guide_Recvd_Date__c', refCntct, 'Master_Tax_Guide_Recvd_Date_del__c');
               changed = checkFldChange(changed, ctct, 'MobilePhone', refCntct, 'Mobile_Phone__c');
               changed = checkFldChange(changed, ctct, 'Phone', refCntct, 'Phone__c');
               changed = checkFldChange(changed, ctct, 'Reason_for_Delete__c', refCntct, 'Reason_For_Deletion__c');
               changed = checkFldChange(changed, ctct, 'Target_Field__c', refCntct, 'Target_Field_R__c');
               changed = checkFldChange(changed, ctct, 'Title', refCntct, 'Title__c');
               //changed = checkFldChange(changed, ctct, 'User_Lookup__c', refCntct, 'User_Lookup__c');
               changed = checkFldChange(changed, ctct, 'LatestCampaign__c', refCntct, 'LatestCampaign__c');

               // copy the fields (with the same name) from the ref account to acct.
               for (String fldName : refCtctFieldsToCopy) {
                  changed = checkFldChange(changed, ctct, fldName, refCntct, fldName);
               }

               //checks LoadCampaignPrev and LoadLeadSourcePrev fields which are only updated by Lead Loader so shouldnt need criteria
               //if (isLeadLoader) {
                  //changed = checkContactLeadLoaderFlds(changed, refCntct, oldRefCtct, ctct);
               //}

               System.debug('processReferralContacts ctct='+refCntct.First_Name__c+' '+refCntct.Last_Name__c+' changed='+changed);
               
               if (changed) {
                  if (ctct.Id == null) {
                     ctctsToInsert.add(ctct);
                     refCtctsToUpdateFromCtctSet.add(refCntct.Id);
                  } else {
                     ctctsToUpdate.add(ctct);
                  }
               } // if (changed
               
               //cntctsToUpsert.add(ctct);

               if (refCntct.Contact_ID__c == NULL || refCntct.Contact__c == null || String.isBlank(refCntct.Dataflux_Id__c)) {
                  refCtctsToUpdateFromCtctSet.add(refCntct.Id);
               }
           
            } // If(acct != null            
                                                        
         } // if (okayToProceed           
      } // for(referral_contact__c refCntct: refCtcts){
        
      existingContactMap.clear();
      matchingAcctsMap.clear();
        
      System.debug('processReferralContacts ctctsToInsert='+ctctsToInsert.size()+' ctctsToUpdate='+ctctsToUpdate.size());
      
      ZipCheckOwner.SKIP_TRIGGERS=false;
      DmlHelper.performDML2(ctctsToInsert, DmlHelper.DML_INSERT, 'ReferralObjectsSync', 'processReferralContacts', 'Insert Contacts', false);
      If(DmlHelper.performDmlResult != null &&DmlHelper.performDmlResult.nbrError > 0){
        CheckReferralsBatch.kickOffRefBatchJob();  //JC added - kick off CheckReferralsBatch 
      }// if
      DmlHelper.performDML2(ctctsToUpdate, DmlHelper.DML_UPDATE, 'ReferralObjectsSync', 'processReferralContacts', 'Update Contacts', false);
      ZipCheckOwner.SKIP_TRIGGERS=true;
        
      ctctsToInsert.clear();
      ctctsToUpdate.clear();
       /*
      if(!cntctsToUpsert.isEmpty()){  
         Database.Upsertresult[] results = Database.upsert(cntctsToUpsert,Contact.Fields.Ref_Contact_id__c, false);
         for (Database.UpsertResult result : results) {
            if (!result.isSuccess()) {
               String errMsg = result.getErrors()[0].getMessage();
               ErrorLog.logError('ReferralObjectsSync', 'processReferralContacts', 'upsert cntctsToUpsert', result.getId(), errMsg);
            }
         } // for (Database.UpsertResults
         */
         if (!refCtctsToUpdateFromCtctSet.isEmpty()) {
            Contact[] ctctList = [Select Id, Contact_ID__c
                                      ,Dataflux_Id__c
                                      ,Ref_Contact_ID__c
                                      ,Mirror_Ref_Ctct__r.Id
                                      ,Mirror_Ref_Ctct__r.Contact_ID__c
                                      ,Mirror_Ref_Ctct__r.Contact__c
                                      ,Mirror_Ref_Ctct__r.Dataflux_Id__c
                                      ,Mirror_Ref_Ctct__r.SF_Contact_ID__c
                                  From Contact
                                 Where Mirror_Ref_Ctct__c in :refCtctsToUpdateFromCtctSet];
            
            System.debug('processReferralContacts ctctList='+ctctList.size());
            List<Referral_Contact__c> updateRefCtcts = new List<Referral_Contact__c>();
            for (Contact ctct : ctctList) {
               Referral_Contact__c refCtct = ctct.Mirror_Ref_Ctct__r;
               refCtct.Contact_Id__c = ctct.Contact_Id__c;
               refCtct.Contact__c = ctct.Id;
               refCtct.SF_Contact_Id__c = ctct.Id;
               if (String.isBlank(refCtct.Dataflux_Id__c)) {
                  refCtct.Dataflux_Id__c = ctct.Dataflux_Id__c;
               }
               updateRefCtcts.add(refCtct);
            } // for (Contact ctct
         
            DmlHelper.performDML2(updateRefCtcts, DmlHelper.DML_UPDATE, 'ReferralObjectsSync', 'processReferralContacts', 'Update updateRefCtcts', false);
            updateRefCtcts.clear();
            /*
            if (!updateRefCtcts.isEmpty()){
               try {
                  update updateRefCtcts;
               } catch (Exception e) {
                  Referral_Contact__c firstRec = updateRefCtcts[0];
                  ErrorLog.logError('ReferralObjectsSync', 'processReferralContacts', 'update updateRefCtcts', firstRec.Id, e, firstRec);
               } 
            } // if (!updateRefCtcts.isEmpty
            */
         } // if (!refCtctsToUpdateFromCtctSet.isEmpty()
      //} // if(!cntctsToUpsert.isEmpty
      ErrorLog.checkSave();                     
        
   }//processReferralContacts
   
    //JC added for Referral Batch to catch referrals that werent converted to contacts 
 
   
   public static Boolean checkFldChange(Boolean currentChanged, SObject destObject, String destFldName, SObject sourceObject, String sourceFldName) {
      return checkFldChange(currentChanged, destObject, destFldName, sourceObject.get(sourceFldName));
   } // checkFldChange
    
   public static Boolean checkFldChange(Boolean currentChanged, SObject destObject, String destFldName, Object valueToCheck) {
      Boolean changed = currentChanged;
      Object destFldValue = destObject.get(destFldName);
      if ((destObject.Id == null) ||
          (destObject.Id != null
           && (destFldValue != null || valueToCheck != null) 
           && destFldValue != valueToCheck)) {
         // for new records
         System.debug('checkFldChange change '+destObject.get(destFldName)+' to '+valueToCheck+' destObject.Id is '+(destObject.Id == null ? 'null' : 'not null'));
         destObject.put(destFldName, valueToCheck);
         changed = true;
      }
      System.debug('checkFldChange destFldName='+destFldName+' valueToCheck='+valueToCheck+' currentChanged='+currentChanged+' changed='+changed);
      return changed;
   } // checkFldChange
   
   /*
   public static Boolean checkContactLeadLoaderFlds(Boolean currentChanged, Referral_Contact__c refCtct, Referral_Contact__c oldRefCtct, Contact ctct) {
      Boolean changed = currentChanged;
      // if the campaign changes during the load, set it on the contact. Let the existing contact triggers handle the rest.
      if (String.isNotBlank(refCtct.LoadCampaignPrev__c) && refCtct.LoadCampaignPrev__c.startsWith(ObjectHelper.PREFIX_CAMPAIGN)
               && (ctct.Id == null || (oldRefCtct != null && refCtct.LoadCampaignPrev__c != oldRefCtct.LoadCampaignPrev__c))
         ) {
         ctct.LatestCampaign__c = refCtct.LoadCampaignPrev__c;
         changed = true;
      }
      
      if (String.isNotBlank(refCtct.LoadLeadSourcePrev__c) 
               && (ctct.Id == null || String.isBlank(ctct.LeadSource))
         ) {
         ctct.LeadSource = refCtct.LoadLeadSourcePrev__c;
         changed = true;
      }
      
      
      // ***** TODO
      // LoadNotifyRep__c, LoadNotifyRepPrev__c
      // LoadReferralType__c, LoadReferralTypePrev__c
      return changed;
   } // checkContactLeadLoaderFlds
   */
   public static String OWNER_CACHE_KEY = 'ReferralObjectsSyncOwnerId';
   public static Id referralOwnerId = null;
       
   public static id getReferralOwnerId() {
      if (referralOwnerId == null) {
         referralOwnerId = (Id)CacheManager.getOrg(OWNER_CACHE_KEY);
         if (referralOwnerId == null) {
            referralOwnerId = [select id from user where name = 'Referral_Owner' and alias = 'rown' limit 1].id;
            CacheManager.putOrg(OWNER_CACHE_KEY,referralOwnerId);
         }
      } // if (referralOwnerId == null
      return referralOwnerId;
   } // getReferralOwnerId
    
   public static void processRefContactRoles(Referral_Contact_Role__c[] refCtctRoles) {
      Id rDataId = getReferralOwnerId();
      Set<id> refCtctIdSet = new Set<id>();
      Set<id> refAcctIdSet = new Set<id>();
      
      for (Referral_Contact_Role__c rcr : refCtctRoles) {
         refCtctIdSet.add(rcr.Referral_Contact__c);
         refAcctIdSet.add(rcr.Referral_Account__c);
      }
      
      Account[] matchingAccts = [select id, Name, Mirror_Referral_Account__c
                                       ,(Select Id, AccountId, ContactId, Role From AccountContactRoles) 
                                       ,(Select Id, AccountId, ContactId, Roles, StartDate, EndDate, IsActive From AccountContactRelations)
                                   from Account where Mirror_Referral_Account__c in :refAcctIdSet];
      Contact[] matchingCtcts = [select id, Name, Mirror_Ref_Ctct__c
                                       ,(Select Id, AccountId, ContactId, Role From AccountContactRoles)
                                       ,(Select Id, AccountId, ContactId, Roles, StartDate, EndDate, IsActive From AccountContactRelations)
                                   from Contact where Mirror_Ref_Ctct__c in :refCtctIdSet];
      Map<Id, Account> refAcctToAcctMap = new Map<Id, Account>();
      Map<Id, Contact> refCtctToCtctMap = new Map<Id, Contact>();
      
      for (Account acct : matchingAccts) {
         refAcctToAcctMap.put(acct.Mirror_Referral_Account__c, acct);
      }
      for (Contact ctct : matchingCtcts) {
         refCtctToCtctMap.put(ctct.Mirror_Ref_Ctct__c, ctct);
      }
      
      //AccountContactRole[] insertRoles = new AccountContactRole[]{};
      Map<Referral_Contact_Role__c,AccountContactRole> insertRoleMap = new  Map<Referral_Contact_Role__c,AccountContactRole>();
      AccountContactRole[] updateRoles = new AccountContactRole[]{};
      AccountContactRole[] deleteRoles = new AccountContactRole[]{};
      
      //AccountContactRelation[] insertRltns = new AccountContactRelation[]{};
      Map<Referral_Contact_Role__c,AccountContactRelation> insertRltnMap = new  Map<Referral_Contact_Role__c,AccountContactRelation>();
      AccountContactRelation[] updateRltns = new AccountContactRelation[]{};
      
      for (Referral_Contact_Role__c rcr : refCtctRoles) {
         Account acct = refAcctToAcctMap.get(rcr.Referral_Account__c);
         Contact ctct = refCtctToCtctMap.get(rcr.Referral_Contact__c);
         if (acct != null && ctct != null) {
            checkAcctCtctRole(rcr, acct, ctct, insertRoleMap, updateRoles, deleteRoles);
            checkAcctCtctRltn(rcr, acct, ctct, insertRltnMap, updateRltns);
         }
      } // for (Referral_Contact_Role__c rcr

      System.debug('processRefContactRoles insertRoleMap='+insertRoleMap.size()+' insertRltnMap='+insertRltnMap.size());
      
//we received a null pointer exception here, investigate if we see this error again. 
      if (!insertRoleMap.isEmpty()) {
         DmlHelper.performDML2(insertRoleMap.values(), DmlHelper.DML_INSERT, 'ReferralObjectsSync', 'processRefContactRoles', 'Insert AccountContactRoles', false);
         for (Referral_Contact_Role__c rcr : insertRoleMap.keySet()) {
            AccountContactRole acr = insertRoleMap.get(rcr);
            rcr.AccountContactRoleId__c = acr.Id;
         }
      } // if (!insertRoleMap.isEmpty
      
      if (!insertRltnMap.isEmpty()) {
         DmlHelper.performDML2(insertRltnMap.values(), DmlHelper.DML_INSERT, 'ReferralObjectsSync', 'processRefContactRoles', 'Insert AccountContactRelations', false);
         for (Referral_Contact_Role__c rcr : insertRltnMap.keySet()) {
            AccountContactRelation acr = insertRltnMap.get(rcr);
            rcr.AccountContactRelationId__c = acr.Id;
         }
      } // if (!insertRltnMap.isEmpty
      
      DmlHelper.performDML2(updateRoles, DmlHelper.DML_UPDATE, 'ReferralObjectsSync', 'processRefContactRoles', 'Update AccountContactRoles', false);
      DmlHelper.performDML2(deleteRoles, DmlHelper.DML_DELETE, 'ReferralObjectsSync', 'processRefContactRoles', 'Delete AccountContactRoles', false);
      DmlHelper.performDML2(updateRltns, DmlHelper.DML_UPDATE, 'ReferralObjectsSync', 'processRefContactRoles', 'Update AccountContactRelations', false);
      ErrorLog.checkSave();
   } // processRefContactRoles
   
   public static String INACTIVE='Inactive';
   public static void checkAcctCtctRole(Referral_Contact_Role__c rcr, Account acct, Contact ctct
                           ,Map<Referral_Contact_Role__c,AccountContactRole> insertRoleMap
                           ,AccountContactRole[] updateRoles, AccountContactRole[] deleteRoles) {
      AccountContactRole acr = null;
      // look for an existing role
      for (AccountContactRole checkAcr : acct.AccountContactRoles) {
         if (checkAcr.AccountId == acct.Id && checkAcr.ContactId == ctct.Id) {
            acr = checkAcr;
            break;
         }
      } // for (AccountContactRole checkAcr : acct.AccountContactRoles)
      
      // do we need to have a role for this?
      Boolean needRole = (String.IsNotBlank(rcr.Role__c) && rcr.Role__c != INACTIVE);
      System.debug('checkAcctCtctRole acct='+acct.Name+' ctct='+ctct.Name+' needRole='+needRole+' acr='+acr);
      if (!needRole && acr != null) {
         System.debug('checkAcctCtctRole deleting existing role - no longer need');
         deleteRoles.add(acr);
         // remove the role id since we're deleting the record
         rcr.AccountContactRoleId__c = null;
      } else if (needRole && acr != null) {
         System.debug('checkAcctCtctRole checking existing role to make sure we can reuse.');
         // verify the id is correct
         rcr.AccountContactRoleId__c = acr.Id;
         if (acr.Role != rcr.Role__c) {
            acr.Role = rcr.Role__c;
            updateRoles.add(acr);
         }
      } else if (needRole && acr == null) {
         System.debug('checkAcctCtctRole creating a new role.');
         acr = new AccountContactRole(AccountId=acct.Id, ContactId=ctct.Id, Role=rcr.Role__c);
         insertRoleMap.put(rcr,acr);
      }
   } // checkAcctCtctRole
   
   public static void checkAcctCtctRltn(Referral_Contact_Role__c rcr, Account acct, Contact ctct
                                       ,Map<Referral_Contact_Role__c,AccountContactRelation> insertRltnMap
                                       ,AccountContactRelation[] updateRltns) {
      AccountContactRelation acr = null;
      // look for an existing relation
      for (AccountContactRelation checkAcr : acct.AccountContactRelations) {
         if (checkAcr.AccountId == acct.Id && checkAcr.ContactId == ctct.Id) {
            acr = checkAcr;
            break;
         }
      } // for (AccountContactRelation checkAcr
      
      // do we need to have a role for this?
      Boolean needRole = (String.IsNotBlank(rcr.Role__c) && rcr.Role__c != INACTIVE);
      System.debug('checkAcctCtctRltn acct='+acct.Name+' ctct='+ctct.Name+' needRole='+needRole+' acr='+acr);
      if (!needRole && acr != null) {
         // end date the relationship
         acr.EndDate = Date.today();
         acr.IsActive = false;
         /* since the inactive flag is the picklist value, we don't currently know the previous value.
            this might ultimately be overkill.
         // make sure the relation is end dated if this is the only role
         // if there is more than one role, remove the role and leave active
         System.debug('checkAcctCtctRltn end dating existing relation');
         if (acr.Roles == rcr.Role__c) {
            acr.EndDate = Date.today();
            acr.IsActive = false;
         } else if (acr.Roles != null && acr.Roles.contains(rcr.Role__c)) {
            String[] roles = acr.Roles.split(';');
            String newRoles = '';
            
            // rebuild role string without the included role
            for (String role : roles) {
               if (role != rcr.Role__c) {
                  newRoles += (String.isNotBlank(newRoles) ? ';' : '') + role;
               }
            } // for (String role
         }
         */
      } else if (needRole && acr != null) {
         System.debug('checkAcctCtctRltn checking existing role to make sure we can reuse.');
         // see if we need to update the current relation
         if (!acr.IsActive || acr.EndDate != null || acr.StartDate == null || String.isBlank(acr.Roles) || !acr.Roles.contains(rcr.Role__c)) {
            acr.IsActive = true;
            acr.EndDate = null;
            if (acr.StartDate == null) {
               acr.StartDate = Date.today();
            }
            // add role if not already there.
            if (String.isBlank(acr.Roles) || !acr.Roles.contains(rcr.Role__c)) {
               acr.Roles = (String.isNotBlank(acr.Roles) ? acr.Roles+';' : '') + rcr.Role__c;
            }
            
         } // if (!acr.IsActive || acr.EndDate != null
         // make sure the id on the custom role is populate
         rcr.AccountContactRelationId__c = acr.Id;
      } else if (needRole && acr == null) {
         // create a new role
         System.debug('checkAcctCtctRltn creating a new relation.');
         acr = new AccountContactRelation(ContactId=ctct.Id, AccountId=acct.Id, IsActive=true, StartDate=Date.today(), Roles=rcr.Role__c );
      }

      if (acr != null) {
         if (acr.Id != null) {
            updateRltns.add(acr);
         } else {
            insertRltnMap.put(rcr,acr);
         }
      } // if (acr != null
   } // checkAcctCtctRltn
  
  /*
   public static void processReferralContactRoles(list<referral_contact_role__c> refCntctRlList){
        id rDataId = getReferralOwnerId();
        set<id> refCntctIds = new set<id>();
        set<id> refaCctIds = new set<id>();
        list<AccountContactRole> aCRToUpdate = new list<AccountContactRole>();
        map<id,AccountContactRole> aCRToInsert = new map<id,AccountContactRole>();
        map<id,id> refAcctToAcctMap = new map<id,id>();
        map<id,id> refCntctToCntctMap = new map<id,id>();
        
        for(referral_contact_role__c refCntctRl : refCntctRlList){
            refCntctIds.add(refCntctRl.Referral_Contact__c);
            refAcctIds.add(refCntctRl.Referral_Account__c);             
        }
        
        list<account> matchingAccts = [select id, Ref_Acct_Id__c, (Select Id, AccountId, ContactId, Role From AccountContactRoles) 
                                         from account where Ref_Acct_Id__c in :refAcctIds];
        list<contact> matchingCntcts = [select id, Ref_Contact_Id__c,  (Select Id, AccountId, ContactId, Role From AccountContactRoles)
                                         from contact where Ref_Contact_Id__c in :refCntctIds];
        Map<Id, Account> matchingAcctMap = new Map<Id, Account>();        
        //for(referral_contact_role__c refCntctRl: refCntctRlList){
            for(account acct: matchingAccts){
                //if(acct.Ref_Acct_ID__c == refCntctRl.Referral_Account__c)
                    //refAcctToAcctMap.put(refCntctRl.Referral_Account__c, acct.id);
                refAcctToAcctMap.put(acct.Ref_Acct_ID__c,acct.Id);
                matchingAcctMap.put(acct.Ref_Acct_ID__c, acct);
            }
            for(contact cntct: matchingCntcts){
                //if(cntct.Ref_Contact_ID__c == refCntctRl.Referral_Contact__c)
                    //refCntctToCntctMap.put(refCntctRl.Referral_Contact__c, cntct.id);
                refCntctToCntctMap.put(cntct.Ref_Contact_ID__c, cntct.id);
            }
        //}
        
        for(referral_contact_role__c refCntctRl: refCntctRlList){
            if(refCntctRl.AccountContactRoleId__c == NULL 
                && refAcctToAcctMap.containsKey(refCntctRl.Referral_Account__c)
                && refCntctToCntctMap.containsKey(refCntctRl.Referral_Contact__c)){
            aCRToInsert.put(refCntctRl.id,new AccountContactRole(AccountID = refAcctToAcctMap.get(refCntctRl.Referral_Account__c)
                                                        , ContactId = refCntctToCntctMap.get(refCntctRl.Referral_Contact__c)
                                                        , Role = refCntctRL.role__c));      
            }
            else if(refCntctRl.AccountContactRoleId__c != NULL){
                Account acct = matchingAcctMap.get(refCntctRl.Referral_Account__c);
                if (acct != null) {
                //for(account acct: matchingAccts){
                    for(AccountContactRole acRl: acct.AccountContactRoles){
                        if(refCntctRl.AccountContactRoleId__c == acRl.id){
                            //acRl.AccountId = refAcctToAcctMap.get(refCntctRl.Referral_Account__c); 
                            acRl.ContactId = refCntctToCntctMap.get(refCntctRl.Referral_Contact__c);
                            acRl.Role = refCntctRl.Role__c;
                            aCRToUpdate.add(acRL);  
                        }       
                    }                   
                }
            }
        }
        if(!aCRToUpdate.isEmpty()){
            update aCRToUpdate;
        }   
        if(!aCRToInsert.isEmpty()){
            insert aCRToInsert.values();
            list<referral_contact_role__c> refCntctRlToUpdate = new list<referral_contact_role__c>();
            list<referral_contact_role__c> refCntctRlToReCheck = [Select Id, AccountContactRoleId__c 
                                                                from referral_contact_role__c 
                                                                where id in: aCRToInsert.keySet()];
            for(referral_contact_role__c refCntctRl: refCntctRlToReCheck){
                refCntctRl.AccountContactRoleID__c = aCRToInsert.get(refCntctRl.id).id;
                refCntctRlToUpdate.add(refCntctRl); 
            }
            update refCntctRlToUpdate;
        }
            
    }//processReferralContactRoles
    */
    
    /* if referral account is linked to standard account, make standard account's contacts orphans then delete standard account
       only delete standard account if it is linked to just 1 referral account
    */
    public static void deletedRefAccts (list<Referral_Account__c> refAcctList){ 
       if (SKIP_SYNC) {
          return;
       }
       
        list<ID> acctToDelete = new list <ID>();
        
        /* make sure standard account linked to referral account that is being deleted is only linked to the 1 referral account, else dont delete the standard acct */
        Set<ID> stndAcctSet = new set<ID>();        
        For(Referral_Account__c refAcct: refAcctList){
            If(refAcct.Account__c != null){
                stndAcctSet.add(refAcct.Account__c);             
            }
        }        
        List<Referral_Account__c> linkedRefAcctList = [select Id, Account__c from Referral_Account__c where Account__c in :stndAcctSet];
        Map<Id, List<Id>> acctRefAcctMap = new Map<ID, Id[]>();
        for (Referral_Account__c refAcct: linkedRefAcctList)
        {   Id saID = refAcct.Account__c;
            List <Id> tempIDs = acctRefAcctMap.get(saID);
            if (tempIDs == Null)              
            {   tempIDs = new List<Id>();                    
                acctRefAcctMap.put(saID,tempIds);                                       
            }
            tempIds.add(refAcct.Id);
        }
        
        for (Referral_Account__c refA: refAcctList)
        {   List <Id> tempIDs = acctRefAcctMap.get(refA.Account__c);
            if (tempIDs == Null || tempIDs.size() == 1)
            {   acctToDelete.add(refA.Account__c);  }
        }
        
        List<Contact> cntctsToOrphan = [select id, Accountid from Contact where Accountid in :acctToDelete];
        if(!cntctstoOrphan.isEmpty()){
            for(contact ctct: cntctsToOrphan){
                ctct.AccountId = null;
            }
            update cntctsToOrphan;
        }
        List<Account> acctsToDeleteList = [select ID from Account where ID in :acctToDelete];
        if(!acctsToDeleteList.isEmpty()){
            Database.DeleteResult[] results = database.delete(acctsToDeleteList,false);
            for (Integer cnt=0; cnt<results.size(); cnt++) {
               Database.DeleteResult result = results[cnt];
               if (!result.isSuccess()) {
                  refAcctList[cnt].addError('Unable to delete related account!');
                  for (Database.Error err: result.getErrors())
                  { ErrorLog.logError('ReferralObjectsSync', 'deletedRefAccts', 'deleting stnd accts', result.getId(), err.getMessage());   }
                  ErrorLog.checkSave();
               }
            } // for (Integer cnt=0
        }   

    }//delete accounts if ref account is deleted

    public static void deletedRefCntcts (list<Referral_Contact__c> refCntctList){ 
        list<ID> CntctToDelete = new list <ID>();
        
        For(Referral_Contact__c refCntct: refCntctList){
            If(refCntct.Contact__c != null){
                CntctToDelete.add(refCntct.Contact__c);               
            }
        }
        List<Contact> CntctToDeleteList = [select ID from Contact where ID in: CntctToDelete];
        if(!CntctToDeleteList.isEmpty()){
            Database.DeleteResult[] results = database.delete(CntctToDeleteList,false);
            for (Integer cnt=0; cnt<results.size(); cnt++) {
               Database.DeleteResult result = results[cnt];
               if (!result.isSuccess()) {
                  refCntctList[cnt].addError('Unable to delete related contact!');
               }
            } // for (Integer cnt=0
        }   
            
   }//delete contact if ref contact is deleted    
    
   public static Boolean CHECK_FOR_DUPES=true;
   // what's the maximum number of records we'll check for dupes at once?
   public static Integer NUM_TO_CHECK_DUPES=Integer.valueOf(Label.RefObjSyncNbrToCheckDupes);
    
   // this is called from WebBankLeadHelper. Not making changes here at the moment because other changes are being made in the class
   public static Map<Referral_Contact__c,list<Contact>> dupeContactChecker(Referral_Contact__c[] refCntctListToCheck){
      Set<Id> refAcctIdSet = new Set<Id>();
      for (Referral_Contact__c refCtct : refCntctListToCheck) {
         if (refCtct.Referral_Account__c != null) {
            refAcctIdSet.add(refCtct.Referral_Account__c);
         }
      } // for (Referral_Contact__c refCtct
       
      Map<Referral_Contact__c,list<Contact>> mapToReturn = dupeContactChecker(refCntctListToCheck, refAcctIdSet);
      NUM_TO_CHECK_DUPES = 0;
      return mapToReturn;
   } // dupeContactChecker
    
   // use dupeblocker to check for duplicates.
   public static Map<Referral_Contact__c,list<Contact>> dupeContactChecker(Referral_Contact__c[] refCntctListToCheck, Set<Id> refAcctIdSet){
      System.debug('dupeContactChecker refCntctListToCheck='+refCntctListToCheck.size()+' refAcctIdSet='+refAcctIdSet.size());
      map<Referral_Contact__c,list<Contact>> mapToReturn = new map<Referral_Contact__c,list<Contact>>();
      // if there aren't any records than we're not going to do anything
      if (refCntctListToCheck.isEmpty() || refCntctListToCheck.size() > NUM_TO_CHECK_DUPES) {
         return mapToReturn;
      }

      Map<Id,Referral_Account__c> matchingRefAcctMap = new Map<Id,Referral_Account__c>([select Id, Account__c from Referral_Account__c where Id in :refAcctIdSet and Account__c != null]);
      System.debug('dupeContactChecker matchingRefAcctMap='+matchingRefAcctMap.size());

     //    map<Id,Id> matchingAcctsMap = new Map <Id,Id>();              
     //    for (referral_account__c refAcct :matchingRefAccts){
     //       System.debug('dupeContactChecker refAcct.Account__c='+refAcct.Account__c);
     //       if (refAcct.Account__c != NULL){
     //          matchingAcctsMap.put(refAcct.id, refAcct.Account__c);
     //       }
     //    } // for (referral_account__c
      
      Contact[] ctctsToCheck = new Contact[]{};          
      for (Referral_Contact__c refCtct : refCntctListToCheck) {
         Referral_Account__c refAcct = matchingRefAcctMap.get(refCtct.Referral_Account__c);
         if (refAcct != null) {
            Contact ctct = new Contact(AccountId=refAcct.Account__c, FirstName=refCtct.First_Name__c, LastName=refCtct.Last_Name__c, Email=refCtct.Email__c, Phone=refCtct.Phone__c);
            ctctsToCheck.add(ctct);
              
         }
      } // for (Referral_Contact__c refCtct

      Map<Referral_Contact__c,Id[]> mapOfContactIds = new Map<Referral_Contact__c,Id[]>();
      Id[] allCtctIds = new Id[]{};
      //Set<id> contactIds = new Set<id>();

      if (!ctctsToCheck.isEmpty()) {
         DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(ctctsToCheck); 
         System.debug('dupeContactChecker results='+results.size());
         for (Integer cnt=0; cnt<ctctsToCheck.size(); cnt++) {
            Referral_Contact__c refCtct = refCntctListToCheck[cnt];
            Contact ctct = ctctsToCheck[cnt];
            DuplicateHelper.DupeResult result = results[cnt];
            System.debug('dupeContactChecker ctctIds='+result.ctctIds);
            mapOfContactIds.put(refCtct,result.ctctIds);
            if (!result.ctctIds.isEmpty()) {
               allCtctIds.addAll(result.ctctIds);
            }
         } // for (Integer cnt=0
      } // if (!ctctsToCheck.isEmpty
          
      /*
         Boolean isDupeBlockerSetup = Utilities.checkDupeBlocker('Contact');
         System.debug('dupeContactChecker isDupeBlockerSetup='+isDupeBlockerSetup);
         map<Id,Contact> mapOfContacts = new map<Id,Contact>();

         for (Referral_Contact__c refCntct : refCntctListToCheck){
            mapOfContactIds.put(refCntct,new list<id>());
            Id acctId = matchingAcctsMap.get(refCntct.Referral_Account__c);
            System.debug('dupeContactChecker refCntct.Referral_Account__c='+refCntct.Referral_Account__c+' acctId='+acctId);
         
            if (acctId != null && refCntctListToCheck.size() <= 50){          
               if (isDupeBlockerSetup) {
                  for (CRMfusionDBR101.DB_Api.Matches matchSet : CRMfusionDBR101.DB_Api.findMatches(new Contact(FirstName = refCntct.First_Name__c, 
                                                                                                                LastName=refCntct.Last_Name__c, 
                                                                                                                AccountId=acctId)) ){
                     System.debug('dupeContactChecker matchSet.matchedIds='+matchSet.matchedIds.size());
                     for (Id contactId : matchSet.matchedIds ){
                        if (!contactIds.contains(contactId)){
                           contactIds.add(contactId);
                           mapOfContactIds.get(refCntct).add(contactId);
                            
                        } // if (!contactIds  
                     } // for (Id contactId
                  } // for (CRMfusionDBR101.DB_Api.Matches matchSet
               } 
               if (!isDupeBlockerSetup || contactIds.isEmpty()) {
                  Contact[] addToMapList = new Contact[]{};
                  // dupeblocker isn't setup in this environment. Try a basic search instead
                  try {
                     Contact[] searchResults = [Select Id, FirstName, LastName, AccountId
                                                      ,Ref_Contact_ID__c 
                                                      ,Mirror_Ref_Ctct__c
                                                  from Contact
                                                 Where FirstName = :refCntct.First_Name__c
                                                   and LastName = :refCntct.Last_Name__c
                                                   and AccountId = :acctId];
                     System.debug('dupeContactChecker searchResults='+searchResults.size());
                     if (!searchResults.isEmpty()) {
                        addToMapList.addAll(searchResults);
                     }
                  } catch (Exception e) {
                     System.debug('dupeContactChecker exception querying contacts: '+e);
                  }
                  mapToReturn.put(refCntct,addToMapList);
               } // if (isDupeBlockerSetup
            } // if(matchingAcctsMap.keyset()
         } // for(Referral_Contact__c refCntct
       */
      System.debug('dupeContactChecker nbr allCtctIds='+allCtctIds.size());
      if (!allCtctIds.isEmpty()) {
         Map<Id,Contact> mapOfContacts = new map<Id,Contact>([select id,Mirror_Ref_Ctct__c, Ref_Contact_ID__c, AccountID  from contact where id in:allCtctIds]);
         for(Referral_Contact__c refCntct : mapOfContactIds.keySet()){
            Contact[] ctctList = new Contact[]{};
            mapToReturn.put(refCntct,ctctList);
            for(id cntctId : mapOfContactIds.get(refCntct)){
               //System.debug('dupeContactChecker added to ctctList cntctId='+cntctId+' mapOfContacts value='+mapOfContacts.get(cntctId));
               //   if (mapOfContacts.containsKey(cntctId)) {
                     ctctList.add(mapOfContacts.get(cntctId));
               //   }
            }
            System.debug('dupeContactChecker ctctList='+ctctList.size());
        } // for(Referral_Contact__c refCntct
      } // if (!contactIds
      //} // if (CHECK_FOR_DUPES)
      
      // make sure at least an empty list is returned for each passed in record.
      for (Referral_Contact__c refCtct : refCntctListToCheck) {
         if (!mapToReturn.containsKey(refCtct)) {
            System.debug('dupeContactChecker adding empty contact list');
            mapToReturn.put(refCtct,new Contact[]{});
         }
      } // for (Referral_Contact__c
        
      return mapToReturn; 
   } // dupeContactChecker
    
    
} //  class ReferralObjectsSync