/* 
   Check the User.If the specific user is Lead Loader then the record has a value and the update value is a null value, 
    then we are updating with the old value.
   
  History
  -------
  04/24/2014 Swarna Mohan     Created
  11/17/2016 Jacob Hinds       Adding in Prospect Profiled for Account
  04/05/2017 J. Stukes         Add Profiled for Contact
  07/26/2017 Dan Carmen       Additional changes for profiling.
  10/27/2017 Dan Carmen       Add additional testing.
  03/05/2018 Dan Carmen       Add additional debugging
  05/06/2019 Dan Carmen       Add check for null runningUser
  10/12/2020 Dan Carmen       Add DGType__c field for ability to override the user settings
  12/14/2020 Dan Carmen       Fix for not handling ONLY_IF_NULL for accounts
  01/05/2021 Michael Karcz	  Add check for Protected Date on account to block LeadLoader and HRIS feed
  05/10/2024 Dan Carmen       Add check for not updating fields to null on the account
  05/31/2024 Dan Carmen       Add check for PEO Clients - set to only update if null
  
 */

public without sharing class CheckDataGovernance {
   
   // do we only run the data governance in the triggers?
   public static Boolean ONLY_DATA_GOVERNANCE=false;
    
    public static Set<Id> idsProcessed = new Set<Id>();
    
   // in case we need a way to not run this during a trigger operation.
   public static Boolean SKIP_DATA_GOVERNANCE = false;
  
   /** Get a set of field names we want to check for the particular situation. 
    */
   public static Set<String> getCheckFieldSet(String userType, String checkType, String objectName) {
    Set<String> checkFieldSet = null;
    if (String.isNotBlank(userType)) {
         String key=userType+checkType+objectName;
        checkFieldSet = getWrapper().checkFieldSetMap.get(key);
    } // if (String.isNotBlank
      return checkFieldSet;
   } // getCheckFieldSet
   
   public static final String LEAD_LOADER='LeadLoader';
   public static final String SFDC_DATA='SfdcData';
   
   // don't allow a value to be updated to a null 
   public static final String NO_NULL='NoNull';
   // to not allow a change to occur in the field by the specified user
   public static final String NO_CHANGE='NoChange';
   // if the user updates the field to append the new data on it instead of overwriting.
   public static final String FIELD_APPEND='FieldAppnd';
   // only allow the update if the existing field is null
   public static final String ONLY_IF_NULL='OnlyIfNull';
   public static final String PEO_CLIENT='PEOClt';
   
   public static final String DATE_FIELD='DGLastChecked__c';
   public static final String NOTES_FIELD='DGProcessNotes__c';
   public static final String PROFILED_FIELD='Profiled__c';
   public static final String PROTECTED_FIELD='Account_Protected__c';
   public static final String BYPASS_FIELD='DGBypass__c';
   public static final String DG_TYPE='DGType__c';
   
   //block lead loader updates is Account is Profiled
   public static final String IS_PROFILED = 'isProfiled';
   
   //block lead loader and HRIS Feed updates if Account is Protected
   public static final String IS_PROTECTED = 'isProtectd';
   
   private static Boolean isLeadLoader = false;
   private static Boolean isSfdcData = false;
   private static Boolean hasJobName = false;
   private static String loadName = null;
   
   private static List<SObject> getRecordsToProcess(List<SObject> objectList) {
      List<SObject> recordsToProcess = new List<SObject>();
      for (SObject objectToCheck : objectList) {
         // ability to bypass the data governance check
         Boolean byPass = (Boolean)objectToCheck.get(BYPASS_FIELD);
         if (bypass) {
            // reset the bypass field
            objectToCheck.put(BYPASS_FIELD,false);
            idsProcessed.add(objectToCheck.Id);
         } else if (!idsProcessed.contains(objectToCheck.Id)) {
            recordsToProcess.add(objectToCheck);
            idsProcessed.add(objectToCheck.Id);
         }
      } // for (SObject objectToCheck
      return recordsToProcess;
   } // getRecordsToProcess
   
   public static void checkData(List<SObject> objectList, Map<Id, SOBject> oldMap) {
    
      System.debug('CheckDataGovernance.checkData SKIP_DATA_GOVERNANCE='+SKIP_DATA_GOVERNANCE);
      if (SKIP_DATA_GOVERNANCE || objectList == null || objectList.IsEmpty()) {
         return;
      }
      
      List<SObject> recordsToProcess = getRecordsToProcess(objectList);
      if (recordsToProcess.isEmpty()) {
         return;
      }
      UserHelper.setRunningUserAttributes();

      // see if the DGType__c field is set - use that value if it is to set the user type
      String dgType = (String)recordsToProcess[0].get(DG_TYPE);
      if (String.isNotBlank(dgType)) {
         isLeadLoader = (dgType == LEAD_LOADER);
         isSfdcData = (dgType == SFDC_DATA);
      } else {
         isLeadLoader = UserHelper.runningUserIsLeadLoader;
         isSfdcData = UserHelper.runningUserIsSfdcData;
      }
      
      if (!isLeadLoader && !isSfdcData) {
         User runningUser = UserHelper.getRunningUser();
         loadName = (runningUser != null ? runningUser.Job_Name__c : null);
         DataGovernanceJobs__c dgJob = (String.isNotBlank(loadName) ? DataGovernanceJobs__c.getInstance(loadName) : null);
         hasJobName = dgJob != null && dgJob.IsActive__c;
      } else {
         loadName = (isLeadLoader ? LEAD_LOADER : (isSfdcData ? SFDC_DATA : null));
      } // if (!isLeadLoader
      
      System.debug('CheckDataGovernance.checkData loadName='+loadName+' isLeadLoader='+isLeadLoader+' isSfdcData='+isSfdcData+' hasJobName='+hasJobName);
      if (!isLeadLoader && !isSfdcData && !hasJobName) {
         return;
      }
      
      // all records in the list will be of the same type
      String checkPrefix = ((String)recordsToProcess[0].Id).left(3);
       
      if (checkPrefix == ObjectHelper.PREFIX_LEAD) {
         checkLeadContact(ObjectHelper.OBJECT_LEAD,recordsToProcess, oldMap);
      } else if (checkPrefix == ObjectHelper.PREFIX_CONTACT) {
         checkLeadContact(ObjectHelper.OBJECT_CONTACT,recordsToProcess, oldMap);
      } else if (checkPrefix == ObjectHelper.PREFIX_ACCOUNT) {
         checkAccount(recordsToProcess, oldMap);
      }
      // so it doesn't get into the trigger again
      //SKIP_DATA_GOVERNANCE = true;
   } // checkData
    
    public static void checkAddSet(String[] fldSetsUsed, String fldsName, Set<String> setToCheck) {
       if (setToCheck != null && !setToCheck.isEmpty()) {
          fldSetsUsed.add(fldsName+'='+setToCheck.size());
       }
    } // checkAddSet
   
    private static void checkLeadContact(String objectName, list<SObject> recs,Map<Id, SObject> oldMap) {
        
        Set<String> leadLoaderFlds = (isLeadLoader ? getCheckFieldSet(loadName,NO_NULL,objectName) : null);
        Set<String> noChangeFlds = getCheckFieldSet(loadName,NO_CHANGE,objectName);
        Set<String> appendFlds = getCheckFieldSet(loadName,FIELD_APPEND,objectName);
        Set<String> onlyIfNullFlds = getCheckFieldSet(loadName,ONLY_IF_NULL,objectName);
        Set<String> ctctProfFldSet = (isLeadLoader ? getCheckFieldSet(loadName,IS_PROFILED,ObjectHelper.OBJECT_CONTACT) : null);
        Set<String> ctctProtFldSet = getCheckFieldSet(loadName,IS_PROTECTED,ObjectHelper.OBJECT_CONTACT);
        String[] fldSetsUsed = new String[]{'loadName='+loadName};
        checkAddSet(fldSetsUsed, 'leadLoaderFlds', leadLoaderFlds);
        checkAddSet(fldSetsUsed, 'noChangeFlds', noChangeFlds);
        checkAddSet(fldSetsUsed, 'appendFlds', appendFlds);
        checkAddSet(fldSetsUsed, 'ctctProfFldSet', ctctProfFldSet);
        checkAddSet(fldSetsUsed, 'onlyIfNullFlds', onlyIfNullFlds);
        checkAddSet(fldSetsUsed, 'ctctProtFldSet', ctctProtFldSet);
        String fieldsInfo = String.join(fldSetsUsed,' ');
        System.debug('CheckDataGovernance.checkLeadContact processing records for '+objectName + fieldsInfo);
        
        for (SObject chkRec : recs) {
            SObject oldRec = oldMap.get(chkRec.Id);
            String[] notes = new String[]{fieldsInfo};
            checkFieldValues(objectName, chkRec, oldRec, leadLoaderFlds, NO_NULL, notes);
            checkFieldValues(objectName, chkRec, oldRec, noChangeFlds, NO_CHANGE, notes);
            checkFieldValues(objectName, chkRec, oldRec, appendFlds, FIELD_APPEND, notes);
            checkFieldValues(objectName, chkRec, oldRec, onlyIfNullFlds, ONLY_IF_NULL, notes);
            // the profiled checkbox only exists on the contact
            if (objectName == ObjectHelper.OBJECT_CONTACT) {
               Boolean profiled = (Boolean)chkRec.get(PROFILED_FIELD);
               Boolean acctProtected = (Boolean)chkRec.get(PROTECTED_FIELD);
               if (profiled) {
                  checkFieldValues(objectName, chkRec, oldRec, ctctProfFldSet, ONLY_IF_NULL, notes);
               }
               if (acctProtected) {
                   checkFieldValues(objectName, chkRec, oldRec, ctctProtFldSet, IS_PROTECTED, notes);
               }
            } // if (objectName == ObjectHelper.CONTACT
            markProcessed(chkRec,String.join(notes,','));
        } // for (SObject chkRec
        
    } // checkLeadContact
   
   // should be same field length on all objects
   //public static final Integer NOTES_FIELD_LENGTH = Lead.DGNotes__c.getDescribe().getLength();

   private static void checkFieldValues(String objectName, SObject objectToChk, SObject oldObjectToChk, Set<String> checkFields
                                          , String changeType, String[] notes) {
       System.debug('CheckDataGovernance.checkFieldValues changeType='+changeType+' checkFields='+checkFields);
       if (checkFields != null && String.isNotBlank(changeType)) {
           String[] fldsChanged = new String[]{};
           for (String fieldName : checkFields) {
               try {
                   //System.debug('CheckDataGovernance.checkFieldValues fieldName='+fieldName+' newVal='+objectToChk.get(fieldName)+' oldVal='+oldObjectToChk.get(fieldName));
                   if (changeType == NO_NULL) {
                       // don't let the lead loader update a non-null value to null
                       if(objectToChk.get(fieldName) == null && oldObjectToChk.get(fieldName) != null) {
                           //System.debug('CheckDataGovernance.checkFieldValues noNull reverting '+fieldName);
                           objectToChk.put(fieldName,oldObjectToChk.get(fieldName));
                           fldsChanged.add(fieldName);
                       }
                   } else if (changeType == NO_CHANGE) {
                       if (objectToChk.get(fieldName) != oldObjectToChk.get(fieldName)) {
                           //System.debug('CheckDataGovernance.checkFieldValues noChange reverting '+fieldName);
                           objectToChk.put(fieldName,oldObjectToChk.get(fieldName));
                           fldsChanged.add(fieldName);
                       }
                   } else if (changeType == ONLY_IF_NULL || changeType == IS_PROTECTED) {
                       //System.debug('CheckDataGovernance.checkFieldValues ONLY_IF_NULL check');
                       if (oldObjectToChk.get(fieldName) != null && (objectToChk.get(fieldName) != oldObjectToChk.get(fieldName))) {
                           //System.debug('CheckDataGovernance.checkFieldValues ONLY_IF_NULL reverting '+fieldName);
                           objectToChk.put(fieldName,oldObjectToChk.get(fieldName));
                           fldsChanged.add(fieldName);
                       }
                   } else if (changeType == FIELD_APPEND) {
                       String oldValue = oldObjectToChk.get(fieldName) != null ? (String)oldObjectToChk.get(fieldName) : '';
                       String newValue = objectToChk.get(fieldName) != null ? (String)objectToChk.get(fieldName) : '';
                       //System.debug('CheckDataGovernance.checkFieldValues FIELD_APPEND oldValue='+oldValue+' newValue='+newValue);
                       if (oldValue != newValue && !oldValue.contains(newValue)) {
                           Integer fldLength = getWrapper().getFieldLength(objectName, fieldName);
                           //String concatenatedValue = oldValue + (String.isNotBlank(oldValue) ? ';' : '') + newValue;
                           String concatenatedValue = (newValue + (String.isNotBlank(newValue) ? '\n' : '') + oldValue).left(fldLength);
                           if (String.isNotBlank(concatenatedValue)) {
                               objectToChk.put(fieldName, concatenatedValue);
                               fldsChanged.add(fieldName);
                           }
                           //System.debug('CheckDataGovernance.checkFieldValues FIELD_APPEND concatenatedValue='+concatenatedValue+' fieldName='+fieldName+' value='+objectToChk.get(fieldName));
                       } else if (oldValue != newValue && oldValue.contains(newValue)) {
                           // put the old value back in the field.
                           objectToChk.put(fieldName,oldObjectToChk.get(fieldName));
                       }
                   }
               } catch (Exception e) {
                   // do nothing here - exceptions should only happen if invalid fields
                   System.debug('CheckDataGovernance.checkFieldValues exception for '+fieldName+': '+e);
               }
           } // for (String fieldName
           if (!fldsChanged.isEmpty()) {
              String note = changeType+':'+String.join(fldsChanged,',');
              notes.add(note);
           }
       } // if (checkFields != null
   } // checkForNullValues
   
   private static void markProcessed(SObject objectToChk, String notes) {
      objectToChk.put(DATE_FIELD,DateTime.now());
      // clear out the DGType__c field
      objectToChk.put(DG_TYPE,null);
      System.debug('markProcessed notes='+notes);
      addToNotes(objectToChk, notes);
   } // markProcessed
   
   public static final String ACCT_LOST_NO_CHNG='LostNoChng';
   public static final String ACCT_CUR_NO_CHNG='CurNoChng';
   public static final String ACCT_PROS_NO_CHNG='ProsNoChng';
   public static final String ACCT_ENT_CLT='EntNoChg';
    
   //Account
   private static void checkAccount(list<SObject> accounts,Map<Id, SObject> oldMap) {
      
      // the fields that we do not allow to change if a client is lost
      Set<String> lostCltFlds = ((isSfdcData || isLeadLoader) ? getCheckFieldSet(loadName,ACCT_LOST_NO_CHNG,ObjectHelper.OBJECT_ACCOUNT) : null);
      // the fields that we do not allow to change if a client is current
      Set<String> curCltFlds = (isLeadLoader ? getCheckFieldSet(loadName,ACCT_CUR_NO_CHNG,ObjectHelper.OBJECT_ACCOUNT) : null);
      // the fields that we do not allow to change if a prospect
      Set<String> prospFlds = (isLeadLoader ? getCheckFieldSet(loadName,ACCT_PROS_NO_CHNG,ObjectHelper.OBJECT_ACCOUNT) : null);
      
      Set<String> profFlds = (isLeadLoader ? getCheckFieldSet(loadName,IS_PROFILED,ObjectHelper.OBJECT_ACCOUNT) : null);
      Set<String> peoFlds = (isSfdcData ? getCheckFieldSet(loadName,PEO_CLIENT,ObjectHelper.OBJECT_ACCOUNT) : null);

      Set<String> noChgFlds = getCheckFieldSet(loadName,NO_CHANGE,ObjectHelper.OBJECT_ACCOUNT);
      Set<String> appendFlds = getCheckFieldSet(loadName,FIELD_APPEND,ObjectHelper.OBJECT_ACCOUNT);
      Set<String> onlyIfNullFlds = getCheckFieldSet(loadName,ONLY_IF_NULL,ObjectHelper.OBJECT_ACCOUNT);
      Set<String> protFlds = getCheckFieldSet(loadName,IS_PROTECTED,ObjectHelper.OBJECT_ACCOUNT);
      Set<String> entCltFlds = getCheckFieldSet(loadName,ACCT_ENT_CLT,ObjectHelper.OBJECT_ACCOUNT);
      Set<String> noNullFlds = getCheckFieldSet(loadName,NO_NULL,ObjectHelper.OBJECT_ACCOUNT);
      /*
      String[] fldSetsUsed = new String[]{'loadName='+loadName};
      checkAddSet(fldSetsUsed, 'lostCltFlds', lostCltFlds);
      checkAddSet(fldSetsUsed, 'curCltFlds', curCltFlds);
      checkAddSet(fldSetsUsed, 'prospFlds', prospFlds);
      checkAddSet(fldSetsUsed, 'profFlds', profFlds);
      checkAddSet(fldSetsUsed, 'noChgFlds', noChgFlds);
      checkAddSet(fldSetsUsed, 'appendFlds', appendFlds);
      checkAddSet(fldSetsUsed, 'onlyIfNullFlds', onlyIfNullFlds);
      checkAddSet(fldSetsUsed, 'protFlds', protFlds);
      checkAddSet(fldSetsUsed, 'entCltFlds', entCltFlds);
      checkAddSet(fldSetsUsed, 'noNullFlds', noNullFlds);
      String fieldsInfo = String.join(fldSetsUsed,' ');
  
      System.debug('CheckDataGovernance.checkAccount processing records '+fieldsInfo);
      */
      for (Account acct : (List<Account>)accounts) {
         Account oldAcct  = (Account)oldMap.get(acct.Id);
         Set<String> fieldSetToUse = null;
         String updateType = NO_CHANGE;
         
         String[] fldsUsed = new String[]{};

         String[] notes=new String[]{};
         String fieldSetToUseName='';
         if (profFlds != null && acct.Profiled__c == true) {
            //System.debug('CheckDataGovernance.checkAccount prospect acct='+acct.Name);
            fieldSetToUseName = 'profFlds';
            fieldSetToUse = profFlds;
            updateType = ONLY_IF_NULL;
         } else if (acct.ClientRegistrationStatus__c == CsoMethods.TYPE_CLIENT) {
            checkAddSet(fldsUsed, 'entCltFlds', entCltFlds);
            checkFieldValues(ObjectHelper.OBJECT_ACCOUNT, acct, oldAcct, entCltFlds, NO_CHANGE, notes);
         } else if (acct.Bis_ID__c != null && acct.Lost_Date__c == null) {
            //System.debug('CheckDataGovernance.checkAccount current client acct='+acct.Name);
            fieldSetToUseName = 'curCltFlds';
            fieldSetToUse = curCltFlds;
         } else if (acct.Bis_ID__c != null && acct.Lost_Date__c != null) {
            //System.debug('CheckDataGovernance.checkAccount lost client acct='+acct.Name);
            fieldSetToUseName = 'lostCltFlds';
            fieldSetToUse = lostCltFlds;
         } else if (acct.Bis_ID__c == null) {
            fieldSetToUseName = 'prospFlds';
            //System.debug('CheckDataGovernance.checkAccount prospect acct='+acct.Name);
            fieldSetToUse = prospFlds;
         }
         checkAddSet(fldsUsed, fieldSetToUseName, fieldSetToUse);
         if (String.isNotBlank(acct.Type) && acct.Type == 'PEO Client') {
            checkAddSet(fldsUsed, 'peoFlds', peoFlds);
            checkFieldValues(ObjectHelper.OBJECT_ACCOUNT, acct, oldAcct, peoFlds, ONLY_IF_NULL, notes);
         }

         checkFieldValues(ObjectHelper.OBJECT_ACCOUNT, acct, oldAcct, fieldSetToUse, updateType, notes);
         checkFieldValues(ObjectHelper.OBJECT_ACCOUNT, acct, oldAcct, noChgFlds, NO_CHANGE, notes);
         checkFieldValues(ObjectHelper.OBJECT_ACCOUNT, acct, oldAcct, appendFlds, FIELD_APPEND, notes);
         checkFieldValues(ObjectHelper.OBJECT_ACCOUNT, acct, oldAcct, onlyIfNullFlds, ONLY_IF_NULL, notes);
         checkFieldValues(ObjectHelper.OBJECT_ACCOUNT, acct, oldAcct, noNullFlds, NO_NULL, notes);
         checkAddSet(fldsUsed, 'noChgFlds', noChgFlds);
         checkAddSet(fldsUsed, 'appendFlds', appendFlds);
         checkAddSet(fldsUsed, 'onlyIfNullFlds', onlyIfNullFlds);
         checkAddSet(fldsUsed, 'noNullFlds', noNullFlds);
          
         if(acct.Protected_Date__c != null && acct.Protected_Date__c >= Date.today()) {
            checkAddSet(fldsUsed, 'protFlds', protFlds);
            checkFieldValues(ObjectHelper.OBJECT_ACCOUNT, acct, oldAcct, protFlds, IS_PROTECTED, notes);
         }
         else if(acct.Protected_Date__c != null && acct.Protected_Date__c < Date.today()) {
             acct.Protected_Date__c = null;
         }
         String allNotes = 'loadName='+loadName+(!fldsUsed.isEmpty() ? ',using '+String.join(fldsUsed,',') : '')
                                +(!notes.isEmpty() ? '; '+String.join(notes,',') : '');
         markProcessed(acct, allNotes);
      } // for (Account acct
      
   } // checkAccount
   
   //public static final Integer NOTES_SIZE = Account.DGProcessNotes__c.getDescribe().getLength();
   
   public static void addToNotes(SObject rec, String notesToAdd) {
     //StringHelper.addNotesToField(rec, NOTES_FIELD, NOTES_SIZE, notesToAdd, true);
     StringHelper.addToProcessNotes(rec, Account.DGProcessNotes__c.getDescribe(), notesToAdd, true);
   } // addToNotes
   
   private static DGWrapper v_dgWrap = null;
   
   public static String CACHE_KEY='CheckDataGovernanceDGWrapperCacheKey';
   
   public static DGWrapper getWrapper() {
      if (v_dgWrap == null) {
         v_dgWrap = (DGWrapper)CacheManager.getOrg(CACHE_KEY);
         if (v_dgWrap == null) {
            v_dgWrap = new DGWrapper();
            v_dgWrap.checkSetup();
            CacheManager.putOrg(CACHE_KEY, v_dgWrap);
         }
      } // if (v_dgWrap == null
      return v_dgWrap;
   } // getWrapper
   
   // wrapper for Data Governance variables
   public class DGWrapper {
      private Map<String,Integer> fieldLengthMap = new Map<String,Integer>();

      public Map<String,Set<String>> checkFieldSetMap = null;
   
      public void checkSetup() {
         if (checkFieldSetMap == null) {
            checkFieldSetMap = new Map<String,Set<String>>();
            for (DataGovernance__c dataGov : DataGovernance__c.getAll().values()) {
               if (dataGov.IsActive__c){
                  String thisKey = dataGov.UserType__c+dataGov.Type__c+dataGov.ObjectName__c;
                  Set<String> fieldSet = checkFieldSetMap.get(thisKey);
                  if (fieldSet == null) {
                     fieldSet = new Set<String>();
                     checkFieldSetMap.put(thisKey,fieldSet);
                  }
                  fieldSet.add(dataGov.FieldName__c);
                  // for append fields we need to know the length of the fields - store once so we don't have to do again.
                  if (dataGov.Type__c == FIELD_APPEND) {
                     getFieldLength(dataGov.ObjectName__c, dataGov.FieldName__c);
                  }
               } // if (dataGov.IsActive__c
               
            } // for (DataGovernance__c dataGov
         } // if (checkFieldSetMap == null
      } // checkSetup
      
      public Integer getFieldLength(String objectName, String fieldName) {
         String key = objectName+'-'+fieldName;
         Integer lngth = fieldLengthMap.get(key);
         if (lngth == null) {
            lngth = new ObjectHelper().getFieldLength(objectName, fieldName);
            if (lngth == null) {
               lngth = 0;
            }
            fieldLengthMap.put(key,lngth);
         } // if (lngth == null
      
         return lngth;
      } // getFieldLength
         
   } // class DGWrapper
    
} // class CheckDataGovernance