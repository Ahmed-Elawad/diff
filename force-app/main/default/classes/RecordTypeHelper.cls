/* 
 * A Helper class to help with querying Record Type information
 *
 * History
 * -------
 * 03/03/2011 Dan Carmen   Created
   06/23/2011 Dan Carmen   Modified to use SObjectHelper class.
   07/27/2012 Dan Carmen   Added methods for the Record_Type_Mapping__c object
   10/24/2013 Cindy Freeman  Added method to return RecordType info by Id
   06/26/2014 Cindy Freeman  Added set of Common Remitter record types
   07/15/2015 Dan Carmen   Added getCaseRecordTypeInfo method.
   07/30/2015 Dan Carmen   Modify getSalesOrgForRecordTypeName method.
   01/05/2016 Dan Carmen   Change some of the record type variables to go off of labels.
   10/23/2017 Dan Carmen   Added in a check in getSalesOrgForRecordTypeName for the RecordType__c custom setting 
   11/10/2017 Dan Carmen   Add cleanRtName
   06/11/2018 Cindy Freeman     Add PEO Lead recordtype label
   10/16/2020 Dan Carmen    Comment out the BusDev variables.
   12/23/2022 Pujitha Madamanchi  null check in cleanRtName

 */
public with sharing class RecordTypeHelper {

   /* The name of the Account record type for Core. */ 
   public static final String CORE_ACCOUNT = Label.RT_Core_Account;
   /* The name of the Account record type for MMS. */
   public static final String MMS_ACCOUNT = Label.RT_MMS_Account;
   /** the name of the Account record type for Core Referral.*/   
   public static final String CORE_REFERRAL_ACCOUNT = 'Core Referral Source Record Type';
   /** the name of the Account record type for HRS Referral.*/
   public static final String HRS_REFERRAL_ACCOUNT = 'HRS Referral Source Record Type';
   /** the name of the Account record type for Paychex Internal Referral.*/
   public static final String PAYX_INT_REFERRAL_ACCOUNT = 'Paychex Internal Referral Account Record Type';
   /** the name of the Account record type for Referral Account.*/
   public static final String REFERRAL_ACCOUNT = 'Referral Account Record Type';
   /** the name of the Account record type for Sales Channel Referral.*/
   public static final String CHANNEL_REFERRAL_ACCOUNT = 'Sales Channel Referral Account Record Type';
   /** the name of the Account record type for Sales Partner Referral.*/
   public static final String PARTNER_REFERRAL_ACCOUNT = 'Sales Partner Referral Account Record Type';
   public static final String SYSTEM_ADMINISTRATION_ACCOUNT = Label.RT_System_Admin_Account;
   
   /** The name of the Contact record type for Core. */
   public static final String CORE_CONTACT = Label.RT_Core_Contact;
   /** The name of the Contact record type for MMS. */
   public static final String MMS_CONTACT = Label.RT_MMS_Contact;
   /** The name of the Contact record type for Core referral. */
   public static final String CORE_REFERRAL_CONTACT = 'Core Referral Record Type';
   /** The name of the Contact record type for HRS referral. */
   public static final String HRS_REFERRAL_CONTACT = 'HRS Referral Record Type';
   /** The name of the Contact record type for MMS referral. */
   public static final String MMS_REFERRAL_CONTACT = 'MMS Referral Record Type';
   /** The name of the Contact record type for Paychex Internal Referral. */
   public static final String PAYX_INT_REFERRAL_CONTACT = 'Paychex Internal Referral Contact Record Type';
   /** The name of the Contact record type for Referral Contact. */
   public static final String REFERRAL_CONTACT = 'Referral Contact Record Type';
   /** The name of the Contact record type for Partner referral. */
   public static final String PARTNER_REFERRAL_CONTACT = 'Sales Partner Referral Contact Record Type';
   /** The name of the Contact record type for Service Complete. */
   public static final String SERVICE_COMPLETE_CONTACT = 'Service Complete Contact Record Type';

   // The name of the Task record type for Core.
   public static final String CORE_TASK = Label.RT_Core_Task;
   // The name of the Task record type for MMS.
   public static final String MMS_TASK = Label.RT_MMS_Task;
   // The name of the Task record type for HRS.
   public static final String HRS_TASK = Label.RT_HRS_Task;
   // The name of the Task record type for HNBF.
   public static final String HNBF_TASK = Label.RT_HNB_Task; 
   // The name of the Event record type for Core.
   public static final String CORE_EVENT = Label.RT_Core_Event;
   // The name of the Event record type for MMS.
   public static final String MMS_EVENT = Label.RT_MMS_Event;
   // The name of the Event record type for HRS.
   public static final String HRS_EVENT = Label.RT_HRS_Event;
   // The name of the Event record type for HNBF.
   public static final String HNBF_EVENT = Label.RT_HNB_Event;
   // The name of the Lead record type for Core.
   public static final String CORE_LEAD = Label.RT_Core_Lead;
   // The name of the Lead record type for HRS. 
   public static final String HRS_LEAD = Label.RT_HRS_Lead;
   // The name of the Lead record type for MMS.
    public static final String MMS_LEAD = Label.RT_MMS_Lead;
    // The name of the Lead record type for MMS.
    public static final String MSP_LEAD = Label.RT_MSP_Lead;
    // The name of the Lead record type for PEO.
    public static final String PEO_LEAD = Label.RT_PEO_Lead;
    /* TODO - these can be deleted along with the custom labels.
    // The name of the Opportunity record type for BusDev Bank Channel
    public static final String BUSDEV_BANKCHANNEL_OPPORTUNITY = Label.RT_BusDev_BC_Opportunity;
    // The name of the Event record type for BusDev Bank Channel
    public static final String BUSDEV_BANKCHANNEL_EVENT = Label.RT_BusDev_BC_Event;
    // The name of the Task record type for BusDev Bank Channel
    public static final String BUSDEV_BANKCHANNEL_TASK = Label.RT_BusDev_BC_Task;
    // The name of the Opportunity record type for BusDev Strategic Accounts
    public static final String BUSDEV_STRATEGICACCOUNTS_OPPORTUNITY = Label.RT_BusDev_SA_Opportunity;
    // The name of the Event record type for BusDev Strategic Accounts
    public static final String BUSDEV_STRATEGICACCOUNTS_EVENT = Label.RT_BusDev_SA_Event;
    // The name of the Task record type for BusDev Strategic Accounts
    public static final String BUSDEV_STRATEGICACCOUNTS_TASK = Label.RT_BusDev_SA_Task; 
    */

   /** Account common remitter record types **/
   public static final Set<String> COMMON_REMITTER_ACCOUNTS = new Set<String>{CORE_REFERRAL_ACCOUNT,HRS_REFERRAL_ACCOUNT,PAYX_INT_REFERRAL_ACCOUNT,REFERRAL_ACCOUNT,CHANNEL_REFERRAL_ACCOUNT,PARTNER_REFERRAL_ACCOUNT};
   public static final String[] COMMON_REMITTER_ACCOUNT_LIST = new String[]{CORE_REFERRAL_ACCOUNT,HRS_REFERRAL_ACCOUNT,PAYX_INT_REFERRAL_ACCOUNT,REFERRAL_ACCOUNT,CHANNEL_REFERRAL_ACCOUNT,PARTNER_REFERRAL_ACCOUNT};
   /** Contact common remitter record types **/
   public static final Set<String> COMMON_REMITTER_CONTACTS = new Set<String>{CORE_REFERRAL_CONTACT,HRS_REFERRAL_CONTACT,MMS_REFERRAL_CONTACT,PAYX_INT_REFERRAL_CONTACT,REFERRAL_CONTACT,PARTNER_REFERRAL_CONTACT};
   public static final String[] COMMON_REMITTER_CONTACT_LIST = new String[]{CORE_REFERRAL_CONTACT,HRS_REFERRAL_CONTACT,MMS_REFERRAL_CONTACT,PAYX_INT_REFERRAL_CONTACT,REFERRAL_CONTACT,PARTNER_REFERRAL_CONTACT};
   
   //Map <String,Schema.RecordTypeInfo> recordTypes = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
   //Map <Id,Schema.RecordTypeInfo> recordTypes = Account.sObjectType.getDescribe().getRecordTypeInfosById();
  
   /** A map of all record types that have been retrieved. To only retrieve once. */
   private static Map<String,List<Schema.RecordTypeInfo>> allRts = new Map<String,List<Schema.RecordTypeInfo>>();
   
   /** Get all record type information for an object.
    */
   public static List<Schema.RecordTypeInfo> getRecordTypes(String sObjectName) {
      String[] sObjectNames = new String[]{sObjectName};
      return getRecordTypes(sObjectNames);
   } // getRecordTypes
   
   /** Get a List of all record types for the objects passed in.
    */
   public static List<Schema.RecordTypeInfo> getRecordTypes(String[] sObjectNames) {
      String key = 'AllByType';
      for (String so : sObjectNames) {
         key += so;
      }
      List<Schema.RecordTypeInfo> recordTypes = allRts.get(key);
      if (recordTypes == null) {
         SObjectHelper soHelper = new SObjectHelper();
         recordTypes = new List<Schema.RecordTypeInfo>();
         for (String sObjectName : sObjectNames) {
            Schema.SObjectType soType = soHelper.getSObjectType(sObjectName);
            if (soType != null) {
               recordTypes.addAll(soType.getDescribe().getRecordTypeInfos());
            }
         }
         if (!recordTypes.isEmpty()) {
            allRts.put(key,recordTypes);
         }
      } // if (recordTypes
      return recordTypes;
   } // getRecordTypes

   public static void getRecordTypesMap(String sObjectName, Map<String,Schema.RecordTypeInfo> byId, Map<String,Schema.RecordTypeInfo> byName) {
      String[] sObjectNames = new String[]{sObjectName};
      getRecordTypesMap(sObjectNames,(String[])null,byId,byName);
   } // getRecordTypesMap
   
   /** Get all of the record types for the passed in object types. Return the information in the passed in maps.
    */
   public static void getRecordTypesMap(String[] sObjectNames, Map<String,Schema.RecordTypeInfo> byId, Map<String,Schema.RecordTypeInfo> byName) {
      getRecordTypesMap(sObjectNames,(String[])null,byId,byName);
   } // getRecordTypesMap
   
   /** Get all of the record types for the passed in object types. Return the information in the passed in maps.
    */
   public static void getRecordTypesMap(String[] sObjectNames, String[] recordTypeNames, Map<String,Schema.RecordTypeInfo> byId, Map<String,Schema.RecordTypeInfo> byName) {
      // make sure at least one of the hashmaps is not null
      if (byId != null || byName != null) {
         List<Schema.RecordTypeInfo> recordTypes = getRecordTypes(sObjectNames);
           if (!recordTypes.isEmpty()) {
              // add to a set for easy reference
              Set<String> recordTypeNameSet = new Set<String>();
              if (recordTypeNames != null && !recordTypeNames.isEmpty()) {
                 recordTypeNameSet.addAll(recordTypeNames);
              }               
              for (Schema.RecordTypeInfo rt : recordTypes) {
                 // if record type names were passed in, make sure only use those.
                 Boolean useRecord = (recordTypeNameSet.isEmpty() || recordTypeNameSet.contains(rt.getName()));
                 if (useRecord) {
                    if (byId != null) {
                       byId.put(rt.getRecordTypeId(),rt);
                    }
                    if (byName != null) {
                       byName.put(rt.getName(),rt);
                    }
                 } // if (useRecord
              } // for (RecordType)
           } // if (!recordTypes.isEmpty()
      } // if (byId != null
   } // getRecordTypes
   
   public static Map<Id,Schema.RecordTypeInfo> getRecordTypeByIdMap(String sObjectName) {
      Map<Id,Schema.RecordTypeInfo> recordTypeByIdMap = null;
      Schema.SObjectType soType = new SObjectHelper().getSObjectType(sObjectName);
      if (soType != null) {
         recordTypeByIdMap = soType.getDescribe().getRecordTypeInfosById();
      }
      return recordTypeByIdMap;
   } // getRecordTypeByIdMap

   public static Map<String,Schema.RecordTypeInfo> getRecordTypeByNameMap(String sObjectName) {
      Map<String,Schema.RecordTypeInfo> recordTypeByNameMap = null;
      Schema.SObjectType soType = new SObjectHelper().getSObjectType(sObjectName);
      if (soType != null) {
         recordTypeByNameMap = soType.getDescribe().getRecordTypeInfosByName();
      }
      return recordTypeByNameMap;
   } // getRecordTypeByNameMap

   /** Get the record type based on the incoming parameters.
    * @param recordTypeName the name of the record type
    * @param sObjectType the type of object. This assists when the names are not unique. This parameter can be null.
    */
   public static Schema.RecordTypeInfo getRecordType(String recordTypeName, String sObjectName) {
      Schema.RecordTypeInfo rt = null;
      // make sure both parameters are passed in.
      if (recordTypeName != null && sObjectName != null) {
         Map<String,Schema.RecordTypeInfo> recordTypeByNameMap = getRecordTypeByNameMap(sObjectName);
         if (recordTypeByNameMap != null) {
            rt = recordTypeByNameMap.get(recordTypeName);
         }
      } // if (recordTypeName
      return rt;
   } // getRecordType

   /** Get the record type based on the incoming parameters.
    * @param recordTypeId the Id of the record type
    * @param sObjectType the type of object. This assists when the names are not unique. This parameter can be null.
    */
   public static Schema.RecordTypeInfo getRecordTypeById(Id recordTypeId, String sObjectName) {
       Schema.RecordTypeInfo rt = null;
       // make sure both parameters are passed in.
       if (recordTypeId != null && sObjectName != null) {
          Map<Id,Schema.RecordTypeInfo> recordTypeByIdMap = getRecordTypeByIdMap(sObjectName);
          if (recordTypeByIdMap != null) {
             rt = recordTypeByIdMap.get(recordTypeId);
          }
       } // if (recordTypeId
       return rt;
   } // getRecordTypeById

   /** Get the default record type for the passed in object for the running user.
    */
   public static Schema.RecordTypeInfo getDefaultRecordType(String sObjectName) {
      Schema.RecordTypeInfo rt = null;
      if (sObjectName != null) {
         Schema.SObjectType soType = new SObjectHelper().getSObjectType(sObjectName);
         if (soType != null) {
            for (Schema.RecordTypeInfo checkRt : soType.getDescribe().getRecordTypeInfos()) {
               if (checkRt.isDefaultRecordTypeMapping()) {
                  rt = checkRt;
                  break;
               }
            }
         } // if (soType != null
      } // if (sObjectName != null
      return rt;
   } // getDefaultRecordType
   
   
   private static Map<String,String> salesOrgByRtNameMap = new Map<String,String>();

   // Get the sales org associated with a record type name.
   public static String getSalesOrgForRecordTypeName(String checkRTName) {
      String salesOrg = null;
      if (String.isNotBlank(checkRTName)) {
         salesOrg = salesOrgByRtNameMap.get(checkRTName);

         if (String.isBlank(salesOrg)) {
            RecordType__c rtSetting = getRtSetting(checkRTName);
            salesOrg = (rtSetting != null ? rtSetting.Sales_Org__c : null);
         }
         if (String.isBlank(salesOrg)) {
            for (SalesOrg__c v_salesOrg : SalesOrg__c.getAll().values()) {
               if (String.isNotBlank(v_salesOrg.RecordTypeAlias__c)) {
                  if (checkRTName.startsWith(v_salesOrg.RecordTypeAlias__c)) {
                     salesOrg = v_salesOrg.Name;
                     break;
                  }
               }
            } // for (SalesOrg__c salesOrg
        
           if (String.isBlank(salesOrg)) {
               // this is being left in to not break current tests. We will eventually want to remove this.
               if (checkRTName.startsWith('Core ')) {
                  salesOrg = UserHelper.SO_CORE;
               } else if (checkRTName.startsWith('HRS 401(k) ')) {
                  salesOrg = UserHelper.SO_401;
               } else if (checkRTName.startsWith('HRS HNBF ') || checkRTName.startsWith('HNBF ')) {
                  salesOrg = UserHelper.SO_HNB;
               } else if (checkRTName.startsWith('HRS PEO-ASO ') || checkRTName.startsWith('PEO-ASO ')) {
                  salesOrg = UserHelper.SO_PEO_ASO;
               } else if (checkRTName.startsWith('MMS ')) {
                  salesOrg = UserHelper.SO_MMS;
               }
            } // if (String.isBlank
            if (String.isNotBlank(salesOrg)) {
               salesOrgByRtNameMap.put(checkRTName, salesOrg);
            }
         } // if (String.isBlank(salesOrg))
      } // if (checkRTName != null
      return salesOrg;
   } // getSalesOrgForRecordTypeName
   
   /** Is the passed in Opportunity name a DSA/FSS Opportunity (so the rep does not have access to it)?
    */
   public static Boolean isDSAOpptyRT(String checkRTName) {
      if (checkRTName != null) {
         if (checkRTName.contains('DSA') || 
             checkRTName.contains('FSS')) {
            return true;                
         }
      } // if (checkRTName != null
      return false;
   } // isDSAOpptyRT
   
   /** The "Default" record type mapping. */
   public static String MAPPING_DEFAULT='Default';
   /** The referral record type mapping */
   public static String MAPPING_REFERRAL='REF';
   
   /** Get all of the mapping records for the passed in salesOrgs.
    */
   public Static Map<String,Record_Type_Mapping__c> getRecordTypeByMapping(String[] salesOrgs, String objectName, String[] mapTypes) {
    Map<String,Record_Type_Mapping__c> rtMap = new Map<String,Record_Type_Mapping__c>();
    if (salesOrgs != null && objectName != null && mapTypes != null) {
        Record_Type_Mapping__c[] mappings = [Select Id, Name
                                                   ,IsSold__c
                                                    ,Mapping_Type__c  
                                                   ,Object_API_Name__c
                                                   ,RecordTypeId__c
                                                   ,RecordTypeName__c
                                                    ,Sales_Org__c
                                               From Record_Type_Mapping__c
                                              Where Sales_Org__c in :salesOrgs
                                                and Object_API_Name__c = :objectName
                                                and Mapping_Type__c in :mapTypes
                                                order by Sales_Org__c desc, IsSold__c asc];
        // want to put only one per sales org in the map - so we're only putting the first one in (the one that's not marked as
        // for the "Sold" record). We don't just use the flag because if there's only one record type for an object, we want to 
        // return it even if the flag is marked.
         for (Record_Type_Mapping__c rtm : mappings) {
            String key=rtm.Sales_Org__c+rtm.Mapping_Type__c;
            if (!rtMap.containsKey(key)) {
               rtMap.put(key,rtm);
            }
         } // for (Record_Type_Mapping__c
    } // if (salesOrgs != null
    return rtMap;
   } // getRecordTypeByMapping
   
   public static final String[] PROS_CLT_RTS = new String[]{CORE_ACCOUNT,MMS_ACCOUNT,CORE_CONTACT,MMS_CONTACT};
   public static final String[] PROS_CLT_OBJS = new String[]{ObjectHelper.OBJECT_ACCOUNT, ObjectHelper.OBJECT_CONTACT};

   private static Map<String,Schema.RecordTypeInfo> byId = null;
    
   /** Is the passed in id for a prospect-client record? */
   public static Boolean isProspectClientRT(Id recordTypeIdToCheck) {
      Boolean isMatch = false;
      if (byId == null) {
         byId = new Map<String,Schema.RecordTypeInfo>();
         getRecordTypesMap(PROS_CLT_OBJS, PROS_CLT_RTS, byId, null);
      }
      isMatch = byId.containsKey(recordTypeIdToCheck);
      return isMatch;
   } // isProspectClientRT

   public static final Integer NAME_FIELD_LENGTH = RecordType__c.Name.getDescribe().getLength();

    public static RecordType__c getRtSetting(String rtName) {
       RecordType__c rt = null;
       if (String.isNotBlank(rtName)) {
          String checkRtName = cleanRtName(rtName); 
          try {
            rt = RecordType__c.getInstance(checkRtName);
          } catch (Exception e) {
             System.debug('getRtSetting exception: '+e.getMessage()+'; '+e.getStackTraceString());
          }
          System.debug('checkRtName='+checkRtName+'. rt='+rt);
       } // if (String.isNotBlank
       return rt;
    } // getRtSetting
    
   // make sure the name isn't too long - remove some special characters - so it fits in the name field of the custom setting
    public static String cleanRtName(String checkName) {
      String cleanedName = '';
      if(checkName!=null){
         cleanedName = (checkName.replace('(','').replace(')','')).left(NAME_FIELD_LENGTH).trim();
      }
      System.debug('cleanRtName checkName='+checkName+'. cleanedName='+cleanedName+'. NAME_FIELD_LENGTH='+NAME_FIELD_LENGTH);
      return cleanedName;
    } // cleanRtName

   // get the RecordTypeInfo for the Case object.
   public static Schema.RecordTypeInfo getCaseRecordTypeInfo(String recordTypeName) {
      Map<String,Schema.RecordTypeInfo> rtByNameMap = Case.SObjectType.getDescribe().getRecordTypeInfosByName();
      return(rtByNameMap.get(recordTypeName));
   } // getCaseRecordTypeInfo
   
   // get the RecordTypeInfo for the Account object.
   public static Schema.RecordTypeInfo getAccountRecordTypeInfo(String recordTypeName) {
      Map<String,Schema.RecordTypeInfo> rtByNameMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
      return(rtByNameMap.get(recordTypeName));
   } // getAccountRecordTypeInfo
   
   // get the RecordTypeInfo for the Contact object.
   public static Schema.RecordTypeInfo getContactRecordTypeInfo(String recordTypeName) {
      Map<String,Schema.RecordTypeInfo> rtByNameMap = Contact.SObjectType.getDescribe().getRecordTypeInfosByName();
      return(rtByNameMap.get(recordTypeName));
   } // getContactRecordTypeInfo
   
} // RecordTypeHelper