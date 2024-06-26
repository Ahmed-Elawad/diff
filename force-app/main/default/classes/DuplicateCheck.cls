/* 
 * Check records for duplicates before processing them as web leads
 *
 * History
 * -------
   02/07/2018 Dan Carmen       Created
   04/11/2018 Dan Carmen       Modifications for using merge() and convertLead()
   04/27/2018 Dan Carmen       Adjustments for Marketo
   09/07/2018 Dan Carmen       Change the field selection to pull from a label for flexibility
   05/06/2019 Dan Carmen       Add additional information when de-duping
   11/12/2019 Dan Carmen       Changes to handle an inactive account user on lead convert
   12/06/2022 Dan Carmen       Changed to be able to use SF Duplicate Management
   09/26/2023 Dan Carmen       Removed Dupeblocker code

*/
public with sharing class DuplicateCheck {

   // for testing purposes when no data in sandbox
   public static Set<Id> DUPE_OVERRIDE_ID_SET = null;
   
   public static Map<Id,DupeWrapper> leadIdWrapperMap = new Map<Id,DupeWrapper>();
   public static Map<Id,DupeWrapper> ctctIdWrapperMap = new Map<Id,DupeWrapper>();
   public static Map<Id,DupeWrapper> acctIdWrapperMap = new Map<Id,DupeWrapper>();
   public static DupeWrapper[] allRecsChecked = new DupeWrapper[]{};
   
   public static Integer matchesByCtct = 0;
   public static Integer matchesByAcct = 0;
   public static Integer matchesByLead = 0;
    
   public static Boolean checkForDuplicates(SObject[] recsToCheck, String objectApiName) {
      return checkForDuplicatesSF(recsToCheck, objectApiName);
   } // checkForDuplicates
    
   // salesforce's duplicate checking
   public static Boolean checkForDuplicatesSF(SObject[] recsToCheck, String objectApiName) {
      Boolean hasDuplicates = false; 
      DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(recsToCheck); 
      System.debug('checkForDuplicatesSF results='+results.size());
      for (Integer cnt=0; cnt<recsToCheck.size(); cnt++) {
         SObject rec = recsToCheck[cnt];
         DuplicateHelper.DupeResult result = results[cnt];
         StringHelper.addToProcessNotes(rec, 'checkForDuplicatesSF hasResults='+result.hasResults+' nbrResults='+result.nbrResults);
          
         DupeWrapper dupeWrap = new DupeWrapper(rec);
         dupeWrap.hasSearchResults = result.hasResults;
         allRecsChecked.add(dupeWrap);
         if (result.hasResults) {
            hasDuplicates=true;
            if (!result.leadIds.isEmpty()) {
               leadIdWrapperMap.put(result.leadIds[0],dupeWrap);
            }
            if (!result.ctctIds.isEmpty()) {
               ctctIdWrapperMap.put(result.ctctIds[0],dupeWrap);
            }
            if (!result.acctIds.isEmpty()) {
               acctIdWrapperMap.put(result.acctIds[0],dupeWrap);
            }
             
         }
      } // for (Integer cnt; cnt<recsToCheck.size
       
      checkContacts();
      checkAccounts();
      checkLeads();
      
      System.debug('checkForDuplicatesSF hasDuplicates='+hasDuplicates);
      return hasDuplicates;
   } // checkForDuplicatesSF
   
   // have all of the duplicates been handled - so we don't query more than we need to
   public static Boolean areAllDupesHandled() {
      for (DupeWrapper dupeWrap : allRecsChecked) {
         if (!dupeWrap.isHandled()) {
            return false;
         }
      }
      return true;
   } // areAllDupesHandled
   
   // store in the cache so we don't have to keep on compiling the list
   public class DgFieldCache implements Cache.CacheBuilder {
      public Object doLoad(String cacheKey) {
         Map<String,Set<String>> returnMap = new Map<String,Set<String>>();
         for (DataGovernance__c dg : DataGovernance__c.getAll().values()) {
            if (dg.UserType__c == CheckDataGovernance.LEAD_LOADER && dg.Type__c == CheckDataGovernance.IS_PROFILED) {
               Set<String> fldSet = (returnMap.containsKey(dg.ObjectName__c) ? returnMap.get(dg.ObjectName__c) : new Set<String>());
               fldSet.add(dg.FieldName__c);
               returnMap.put(dg.ObjectName__c,fldSet);
            }
         } // for (DataGovernance__c dg
         return returnMap;
      }
   } // class DgFieldCache

   public static String getObjectQuery(String objectName) {
      DGFieldSetsCache objInfo = getObjectInfo(objectName);
      String query = (objInfo != null ? objInfo.query : null);
      return query;
   } // getObjectQuery
   
   public class DGFieldSetsCache {
      public String query = '';
      public Set<String> fldSet = new Set<String>();
      public String[] flds = new String[]{};
   } // DGFieldSetsCache
   
   public static DGFieldSetsCache getObjectInfo(String objectName) {
      String cacheKey = 'DuplicateCheckgetObjectInfo'+objectName;
      DGFieldSetsCache objInfo = (DGFieldSetsCache)CacheManager.getOrg(cacheKey);
      if (objInfo == null) {
         objInfo = null;
         if (objectName == ObjectHelper.OBJECT_ACCOUNT) {
            objInfo = buildAcctInfo();
         } else if (objectName == ObjectHelper.OBJECT_CONTACT) {
            objInfo = buildCtctInfo();
         } else if (objectName == ObjectHelper.OBJECT_LEAD) {
            objInfo = buildLeadInfo();
         }
         if (objInfo != null) {
            CacheManager.putOrg(cacheKey,objInfo);
         }
      }
      return objInfo;
   } // getObjectInfo
   
   public static Set<String> getQueryFlds(String objectName, String prefix, Schema.FieldSet fldSet) {
      System.debug('getQueryFlds objectName='+objectName+' prefix='+prefix);
      Set<String> queryFldSet = new Set<String>();
      Set<String> dgFldSet = getDgFlds(objectName);
      for (String dgFld : dgFldSet) {
         queryFldSet.add(prefix+dgFld);
         System.debug('getQueryFlds fldName='+(prefix+dgFld));
      }
      System.debug('getQueryFlds after dgFldSet queryFldSet='+queryFldSet.size());
      for (Schema.FieldSetMember fsm : fldSet.getFields()) {
         String fldName = prefix+fsm.getFieldPath();
         System.debug('getQueryFlds fldName='+fldName);
         queryFldSet.add(fldName);
      } // for (Schema.FieldSetMember
      System.debug('getQueryFlds end queryFldSet='+queryFldSet.size());
      return queryFldSet;
   } // getQueryFlds
   
   public static DGFieldSetsCache buildAcctInfo() {
      DGFieldSetsCache objInfo = new DGFieldSetsCache();
      objInfo.fldSet = getQueryFlds(ObjectHelper.OBJECT_ACCOUNT,'', Schema.SObjectType.Account.fieldSets.DuplicateQueryAcctFlds);
      objInfo.flds.addAll(objInfo.fldSet);
      System.debug('buildAcctInfo flds='+objInfo.flds);
      objInfo.query = 'Select '+String.join(objInfo.flds,',')+' From Account';
      return objInfo;
   } // buildAcctInfo
   
   public static DGFieldSetsCache buildCtctInfo() {
      DGFieldSetsCache objInfo = new DGFieldSetsCache();
      objInfo.fldSet = getQueryFlds(ObjectHelper.OBJECT_CONTACT,'', Schema.SObjectType.Contact.fieldSets.DuplicateQueryCtctFlds);
      Set<String> acctQueryFldSet = getQueryFlds(ObjectHelper.OBJECT_ACCOUNT,'Account.', Schema.SObjectType.Account.fieldSets.DuplicateQueryAcctFlds);
      objInfo.fldSet.addAll(acctQueryFldSet);
      objInfo.flds.addAll(objInfo.fldSet);
      System.debug('buildCtctInfo flds='+objInfo.flds);
      objInfo.query = 'Select '+String.join(objInfo.flds,',')+' From Contact';
      return objInfo;
   } // buildCtctInfo
   
   public static DGFieldSetsCache buildLeadInfo() {
      DGFieldSetsCache objInfo = new DGFieldSetsCache();
      objInfo.fldSet = getQueryFlds(ObjectHelper.OBJECT_LEAD,'', Schema.SObjectType.Lead.fieldSets.DuplicateCheck_Flds);
      String[] flds = new String[]{};
      objInfo.flds.addAll(objInfo.fldSet);
      System.debug('buildLeadInfo flds='+objInfo.flds);
      objInfo.query = 'Select '+String.join(objInfo.flds,',')+' From Lead';
      return objInfo;
   } // buildLeadInfo

   public static Set<String> getDgFlds(String objectName) {
      Set<String> dgFldSet = new Set<String>();
      for (DataGovernance__c dg : DataGovernance__c.getAll().values()) {
         if (dg.UserType__c == CheckDataGovernance.LEAD_LOADER && dg.Type__c == CheckDataGovernance.IS_PROFILED
                        && dg.ObjectName__c == objectName) {
            dgFldSet.add(dg.FieldName__c);
         } // for (DataGovernance__c dg
      } // or (DataGovernance__c dg : DataGovernance__c
      return dgFldSet;
   } // getDgFlds

   public static String DG_FLDS_CACHE_KEY = 'DuplicateCheckDataGovernanceFlds';
   
   public static Set<String> getDGFieldSet(String objectName) {
      Map<String,Set<String>> dgFieldsMap = (Map<String,Set<String>>)Cache.Org.get(DgFieldCache.class, DG_FLDS_CACHE_KEY);
      Set<String> returnSet = (dgFieldsMap != null ? dgFieldsMap.get(objectName) : null);
      // make sure we're always returning a non-null value
      return (returnSet != null ? returnSet : new Set<String>());
   } // getDGFieldSet

/*
   public static String buildQuery(String queryStart, String prefix, Set<String> fldSet, String objectName) {
      Set<String> dgFldSet = getDGFieldSet(objectName);
      if (dgFldSet != null) {
         fldSet.addAll(dgFldSet);
      }
      String query = queryStart;
      for (String fldName : fldSet) {
         query += ','+prefix+fldName;
      }
      return query;
   } // buildQuery
   public static String buildQuery(String[] flds) {
      String query = 'select '+flds[0];
      for (Integer cnt=1; cnt<flds.size(); cnt++) {
         query += ','+flds[cnt];
      }
      return query;
   } // buildQuery
   */
   
   //public static Set<String> ctctFldSet = new Set<String>{'AccountId','OwnerId','Description','Email','FirstName','LastName','LatestCampaign__c'
   //                                        ,'MailingCity','MailingState','MailingStreet','MailingPostalCode','MailingCountry'
   //                                        ,'Profiled__c','Profiled_Date__c','Profiled_Expiration_Date__c', 'ProcessNotes__c'
   //                                        ,'Phone','TransactionId__c','Weblead__c','CreatedByProcess__c', 'OwnedBy__c','Contact_Stage__c'};
   //public static Set<String> ctctFldSet = new Set<String>(Label.DuplicateCheck_CtctQueryFlds.split(','));
   
   public static void checkContacts() {
      System.debug('checkContacts ctctIdWrapperMap='+ctctIdWrapperMap.size()+' areAllDupesHandled='+areAllDupesHandled());
      if (ctctIdWrapperMap.isEmpty() || areAllDupesHandled()) {
         return;
      }
      String query = getObjectQuery(ObjectHelper.OBJECT_CONTACT);
      //String query = buildQuery('Select Id','',ctctFldSet, ObjectHelper.OBJECT_CONTACT);
      // query the account with the contact
      //query += buildQuery(',Account.Id','Account.',acctFldSet, ObjectHelper.OBJECT_ACCOUNT);
      Set<Id> keySet = ctctIdWrapperMap.keySet();
      //query += ' From Contact Where Id in :keySet order by CreatedDate desc';
      query += ' Where Id in :keySet order by CreatedDate desc';
      System.debug('checkContacts query='+query);
      Contact[] ctcts = Database.query(query);

      for (Contact ctct : ctcts) {
         DupeWrapper dupeWrap = ctctIdWrapperMap.get(ctct.Id);
         if (dupeWrap != null && !dupeWrap.isHandled()) {
            dupeWrap.matchCtct = ctct;
            matchesByCtct++;
         }
      } // for (Contact ctct
   } // checkContacts

   //public static Set<String> acctFldSet = new Set<String>{'Name','OwnerId','NumberOfEmployees','Employees__c'
   //                                             ,'ShippingStreet','ShippingCity','ShippingState','ShippingPostalCode'
   //                                             ,'BillingStreet','BillingCity','BillingState','BillingPostalCode'
   //                                             ,'Profiled__c','Profiled_Date__c','Profiled_Expiration_Date__c'};
   //public static Set<String> acctFldSet = new Set<String>(Label.DuplicateCheck_AcctQueryFlds.split(','));
   
   public static void checkAccounts() {
      System.debug('checkAccounts acctIdWrapperMap='+acctIdWrapperMap.size()+' areAllDupesHandled='+areAllDupesHandled());
      if (acctIdWrapperMap.isEmpty() || areAllDupesHandled()) {
         return;
      }
      String query = getObjectQuery(ObjectHelper.OBJECT_ACCOUNT);
      //String query = buildQuery('Select Id','',acctFldSet, ObjectHelper.OBJECT_ACCOUNT);
      Set<Id> keySet = acctIdWrapperMap.keySet();
      //query += ' From Account Where Id in :keySet order by CreatedDate desc';
      query += ' Where Id in :keySet order by CreatedDate desc';
      System.debug('checkAccounts query='+query);
      Account[] accts = Database.query(query);

      for (Account acct : accts) {
         DupeWrapper dupeWrap = acctIdWrapperMap.get(acct.Id);
         if (dupeWrap != null && !dupeWrap.isHandled()) {
            dupeWrap.matchAcct = acct;
            matchesByAcct++;
         }
      } // for (Account acct
      
   } // checkContacts


   // the merge command does not update the survivor with the data from the record(s) we are merging out. So to 
   // compensate for that, we need to select all of the fields to save the data.
   public static void checkLeads() {
      System.debug('checkLeads leadIdWrapperMap='+leadIdWrapperMap.size()+' areAllDupesHandled='+areAllDupesHandled());
      if (leadIdWrapperMap.isEmpty() || areAllDupesHandled()) {
         return;
      }
      // to create a list all of the fields
      //ObjectHelper.getSOQLQuery(ObjectHelper.OBJECT_LEAD, null, true, true, true, false);
      //String[] leadFlds = ObjectHelper.fieldNameByObjectNameMap.get(ObjectHelper.OBJECT_LEAD);
      //Set<String> leadFldSet = new Set<String>(leadFlds);
      //if (!leadFldSet.contains('ProcessNotes__c')) {
      //   leadFlds.add('ProcessNotes__c');
      //}
      //String query = buildQuery(leadFlds);
      String query = getObjectQuery(ObjectHelper.OBJECT_LEAD);
      
      
      Set<Id> keySet = leadIdWrapperMap.keySet();
      query += ' Where IsConverted=false and Id in :keySet order by CreatedDate desc';
      System.debug('checkLeads query='+query);
      Lead[] leads = Database.Query(query);
      for (Lead ld : leads) {
         DupeWrapper dupeWrap = leadIdWrapperMap.get(ld.Id);
         if (dupeWrap != null && !dupeWrap.isHandled()) {
            dupeWrap.matchLead = ld.clone(true,true);
            matchesByLead++;
         }
      } // for (lead ld
   } // checkLeads
   
   public static Boolean checkMatchIds(DupeWrapper dupeWrap, Set<Id> checkIdSet) {
      System.debug('checkMatchIds checkIdSet='+checkIdSet.size());
      dupeWrap.hasSearchResults = !checkIdSet.isEmpty();
      for (Id id : checkIdSet ){
         if(id.getSobjectType() == Schema.Lead.SObjectType){
            System.debug('checkMatchIds add lead match id='+id);
            leadIdWrapperMap.put(id,dupeWrap);
         } else if(id.getSobjectType() == Schema.Contact.SObjectType){
            System.debug('checkMatchIds add contact match id='+id);
            ctctIdWrapperMap.put(id,dupeWrap);
         } else if(id.getSobjectType() == Schema.Account.SObjectType){
            System.debug('checkMatchIds add account match id='+id);
            acctIdWrapperMap.put(id,dupeWrap);
         }
      } // for (Id i
      return true;
   } // checkMatchIds
   
   public static String MATCH_CONTACT='Contact Match';
   public static String MATCH_ACCOUNT='Account Match';
   public static String MATCH_LEAD='Lead Match';
   public static String MATCH_NONE='No Match Found';
   
   
   public class DupeWrapper {
      public SObject rec = null;
      public DupeWrapper(SObject p_rec) {
         rec = p_rec;
      }
      
      public Boolean hasSearchResults = false;

      public Boolean isHandled() {
         // if any of these have a value then it's been handled.
         return (!hasSearchResults || (hasSearchResults && (matchCtct != null || matchAcct != null || matchLead != null)));
      } // isHandled
      
      // if we find matches, find the best ones
      public Contact matchCtct;
      public Account matchAcct;
      public Lead matchLead;
      
      public void logMatchType(Map<Id,SObject> recsToUpdate) {
         String matchType = (matchCtct != null ? MATCH_CONTACT 
                                                  : matchAcct != null ? MATCH_ACCOUNT
                                                  : matchLead != null ? MATCH_LEAD : MATCH_NONE);

         String matchInfo = 'MatchType found: '+matchType;
         // this field exists on both the lead and contact
         rec.put('DuplicateCheckStatus__c',matchType);
         if (rec.Id != null && rec.Id.getSobjectType() == Schema.Lead.SObjectType) {
            Lead ld = new Lead(Id=rec.Id, ProcessNotes__c=(String)rec.get('ProcessNotes__c'));
            ld.DuplicateCheckStatus__c=matchType;
            StringHelper.addToProcessNotes(ld, matchInfo);
            recsToUpdate.put(ld.Id,ld);
         }
         
         StringHelper.addToProcessNotes(rec, matchInfo);

      } // logMatchType

   } // classDupeWrapper


} // class DuplicateCheck