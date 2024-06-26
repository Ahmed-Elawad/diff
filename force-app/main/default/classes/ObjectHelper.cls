/* 
 * Helper class to manage SObjects
 *
 * History
 * -------
 * 11/17/2011 Dan Carmen   Created - rewrite of the SObjectHelper class
   12/13/2012 Dan Carmen   Clean up code
   03/08/2013 Cindy Freeman      Added getFieldType and getFieldSoapType methods
   07/09/2013 Dan Carmen   Get object prefix
   12/01/2013 Dan Carmen   Added getSOQLQuery method.
   12/27/2013 Cindy Freeman   Added getLookupFieldMap method to return look-up fields on an object (excludes SF2SF connection fields)
   01/28/2014 Justin Henderson   Added overload method for getFieldLength.
   02/13/2014 Cindy Freeman      Added prefix, getSOQLQuery and getLookupFieldMap methods from config02
   03/01/2014 Dan Carmen   Changes for NSS
   06/12/2014 Dan Carmen   Changes to handle the lead hold out field
   04/13/2015 Dan Carmen   Added referral account/contact fields
   02/10/2016 Dan Carmen   Added formatStringAsObject method
   05/10/16 Jermaine Stukes Added getCreatableFields method
   12/14/2016 Dan Carmen   Additional functionality for the formatStringAsObject method.
   09/26/2017 Dan Carmen   Added getObjectNameFromId and getObjectNameFromPrefix methods
   04/09/2018 Dan Carmen   Add cache to getSOQLQuery
   02/24/2020 Dan Carmen        Increment API version
   04/09/2020 Dan Carmen        Remove getRecordTypeName method
   10/12/2020 Dan Carmen        Changes to formatStringAsObject for an EMAIL field 
   12/22/2020 Dan Carmen        Add a space between fields in getSOQLQuery
   08/04/2021 Dan Carmen        Add getObjectLabelFromId method
   11/08/2021 Jermaine Stukes	Removed references to external wholesaler owner fields
   03/07/2022 Dan Carmen        Fix for formatStringAsObject to handle negative numbers

 */
public without sharing class ObjectHelper {

   /** Default constructor.
    */
   public ObjectHelper() {
      
   } // SObjectHelper

   private static Map<String, Schema.SObjectType> globalDescribe = null;
   
   /** Get the global describe of all of the objects.
    */
   public Map<String, Schema.SObjectType> getGlobalDescribe() {
      if (globalDescribe == null) {
         globalDescribe = Schema.getGlobalDescribe();
      }
      return globalDescribe;
   } // getGlobalDescribe
   
   /** Do the passed in object names exist as real objects? Returns a map with the results.
    */
   public Map<String,Boolean> doObjectsExist(String[] sobjectNames) {
      getGlobalDescribe();
      Map<String,Boolean> results = new Map<String,Boolean>();
      if (sobjectNames != null) {
         for (String objectName : sobjectNames) {
            results.put(objectName,(globalDescribe.containsKey(objectName) ? True : False));
         }
      } // if (sobjectnames != null
      return results;
   } // doObjectsExist
   
   /** Get the SObjectType for the passed in name.
    */
   public Schema.SObjectType getSObjectType(String sObjectName) {
      getGlobalDescribe();
      return (sObjectName != null ? globalDescribe.get(sObjectName) : null);
   } // getSObjectType
   
   /** Store all of the values so don't have to do additional describes. */
   private static Map<String,Map<String, Schema.SObjectField>> objectFieldMap = new Map<String,Map<String, Schema.SObjectField>>();

    // Returns a dynamic SOQL statement for the whole object, includes only creatable fields since we will be inserting a cloned result of this query
    public static string getCreatableFields(String objectName, String whereClause)
    {      
        String selects = '';
        
        if (whereClause == null || whereClause == ''){ return null; }
        
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();    
        
        if (fMap != null)
        {
            for (Schema.SObjectField ft : fMap.values())
            { // loop through all field tokens (ft)
                if(ft != null)
                {
                    Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                    if (fd.isCreateable())
                    { // field is creatable
                        selectFields.add(fd.getName());
                    }
                }
            }
        }
        
        if (!selectFields.isEmpty())
        {
            for (string s:selectFields)
            {
                selects += s + ',';
            }
            if (selects.endsWith(','))
            {
                selects = selects.substring(0,selects.lastIndexOf(','));
            }           
        }        
        return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;       
    } 
   public Map<String, Schema.SObjectField> getFieldMap(String objectApiName) {
      Map<String, Schema.SObjectField> fieldMap = objectFieldMap.get(objectApiName);
      // map is not already retrieved
      if (fieldMap == null) {
         // find object and get field mapping if it exists
         Schema.SObjectType sObjectType = getSObjectType(objectApiName);
         if (sObjectType != null) {
            fieldMap = sObjectType.getDescribe().fields.getMap();
            if (fieldMap != null) {
               objectFieldMap.put(objectApiName,fieldMap);
            }
         } // if (sObjectType != null
      } // if (fieldMap == null
      return fieldMap;
   } // getFieldMap
   
   /** Store all lookup fields on an object so don't have to do additional describes. */
   private static Map<String, Map<String, String>> lookupFieldMap = new Map<String, Map<String, String>>();
   
   public Map<String,String> getLookupFieldMap(String objectApiName) {
         Map<String, String> lookupMap = lookupFieldMap.get(objectApiName);         
         // map is not already retrieved
         if (lookupMap == null) {
            // find object and get fields if it exists
            lookupMap = new Map<String, String>();
            Schema.SObjectType sObjectType = getSObjectType(objectApiName);
            if (sObjectType != null) {
               Map<String, Schema.SObjectField> objFldMap = sObjectType.getDescribe().fields.getMap();
               // loop thru all fields looking for Lookup fields not related to SF2SF connections
            for (String fldName : objFldMap.keyset())
            {  Schema.sObjectField fld = objFldMap.get(fldName);              
               Schema.DescribeFieldResult fldDesc = fld.getDescribe();
               if (fldDesc.getReferenceTo().size() > 0 && !fldDesc.getName().contains('Connection'))
               {  lookupMap.put(fldName,fldDesc.getReferenceTo().get(0).getDescribe().getName());  }
            } // for
            } // if sObjectType!=null
      } // if lookupMap==null   
      
      lookupFieldMap.put(objectApiName,lookupMap);    // save results in case needed later
      return lookupMap;    
   } // getLookupFieldMap
   
   /** Check for access on an object.
    */
   public Boolean checkObject(String objectApiName, String actionType) {
      Boolean canDoAction = false;
      Schema.SObjectType sot = getSObjectType(objectApiName);
      if (sot != null) {
         Schema.DescribeSobjectResult dsr = sot.getDescribe();
         if (dsr != null) {
            if (actionType == null || actionType == ACTION_ACCESS) {
               canDoAction = dsr.isAccessible();
            } else if (actionType != null && actionType == ACTION_UPDATE) {
               canDoAction = dsr.isUpdateable();
            } else if (actionType != null && actionType == ACTION_CREATE) {
               canDoAction = dsr.isCreateable();
            }
         } // if (dsr != null
      } // if (sot != null
      return canDoAction;
   } // checkObject
   
   /** Check if a field exists on an object.
    */
   public Boolean checkField(String objectApiName, String fieldApiName) {
      return checkField(objectApiName, fieldApiName, 'access');
   } // checkField

   public static final String ACTION_ACCESS='access';
   public static final String ACTION_UPDATE='update';
   public static final String ACTION_CREATE='create';
   public static final String ACTION_WRITE_READ='writeRequireMasterRead';
   /** Check if a field exists on an object.
    */
   public Boolean checkField(String objectApiName, String fieldApiName, String actionType) {
      Boolean fldFound = false;
      if (objectApiName != null && fieldApiName != null) {
         Map<String, Schema.SObjectField> fieldMap = getFieldMap(objectApiName);
         if (fieldMap != null) {
            Schema.SObjectField fld = fieldMap.get(fieldApiName);
            if (fld != null) {
               Schema.DescribeFieldResult fieldDescribe = fld.getDescribe();
               if (fieldDescribe != null) {
                  if (actionType == null || actionType == ACTION_ACCESS) {
                     fldFound = fieldDescribe.isAccessible();
                  } else if (actionType != null && actionType == ACTION_UPDATE) {
                     fldFound = fieldDescribe.isUpdateable();
                  } else if (actionType != null && actionType == ACTION_CREATE) {
                     fldFound = fieldDescribe.isCreateable();
                  } else if (actionType != null && actionType == ACTION_WRITE_READ) {
                     fldFound = fieldDescribe.isWriteRequiresMasterRead();
                  }
               } // if (fieldDescribe != null
            } // if (fld != null
         } // if (fieldMap != null
      } // if (objectApiName
      System.debug('SObjectHelper.checkField objectApiName='+objectApiName+' fieldApiName='+fieldApiName+' actionType='+actionType+' fldFound='+fldFound);
      return fldFound;
   } // checkField

   public String getFieldLabel(String objectApiName, String fieldApiName) {
      String label ='';  
      if (objectApiName != null && fieldApiName != null) {
         Map<String, Schema.SObjectField> fieldMap = getFieldMap(objectApiName);
         if (fieldMap != null) {
            Schema.SObjectField fldInfo = fieldMap.get(fieldApiName);
            if (fldInfo != null) {
               label = fldInfo.getDescribe().getLabel();
            }
         } // if (fieldMap != null
      } // if (objectApiName
      return label;
   } // getFieldLabel
   
   /** Keep a map of the values so only have to do describe once. */
   private static Map<Schema.SObjectField,Integer> fieldLengthMap = new Map<Schema.SObjectField,Integer>();
   
   public static Integer getFieldLngth(Schema.SObjectField field) {
      Integer fieldLength = 0;
      if (field != null) {
         fieldLength = fieldLengthMap.get(field);
         if (fieldLength == null) {
            Schema.DescribeFieldResult dfr = field.getDescribe();
            fieldLength = dfr.getLength();
            fieldLengthMap.put(field, fieldLength);
         }
      } // if (field != null
      return fieldLength;
   } // getFieldLngth
   
   /* Don't think we need this anymore
   public Integer getFieldLength(Schema.SObjectField field) {
      Integer fieldLength = 0;
      if (field != null) {
         // make sure the notes aren't too long for the field. If they are, substring.
         Schema.DescribeFieldResult dfr = field.getDescribe();
         fieldLength = dfr.getLength();
      }
      return fieldLength;
   } // getFieldLength
   */
   // CMF added to get length of field (for example: 128)
   public Integer getFieldLength(String objectApiName, String fieldApiName) {
      integer fieldLength = 0;
      if (objectApiName != null && fieldApiName != null) {
         Map<String, Schema.SObjectField> fieldMap = getFieldMap(objectApiName);
         if (fieldMap != null) {
            Schema.SObjectField fldInfo = fieldMap.get(fieldApiName);
            if (fldInfo != null) {
               fieldLength = fldInfo.getDescribe().getLength();
            }
         } // if (fieldMap != null)
      } // if (objectAPIname
      return fieldLength;
   } // getFieldLength

   
   // CMF added to get type of field (for example: Double, Text, TextArea, Picklist)
   public String getFieldType(String objectApiName, String fieldApiName) {
      String fieldType = '';
      if (objectApiName != null && fieldApiName != null) {
         Map<String, Schema.SObjectField> fieldMap = getFieldMap(objectApiName);
         if (fieldMap != null) {
            Schema.SObjectField fldInfo = fieldMap.get(fieldApiName);
            if (fldInfo != null) {
               fieldType = fldInfo.getDescribe().getType().name();
            }
         } // if (fieldMap != null)
      } // if (objectAPIname
      return fieldType;
   } // getFieldType
   
   // CMF added to get SOAP type of field which is more generic (for example: String instead of TextArea, String instead of PiokList, ID instead of Reference)
   public String getFieldSoapType(String objectApiName, String fieldApiName) {
      String fieldType = '';
      if (objectApiName != null && fieldApiName != null) {
         Map<String, Schema.SObjectField> fieldMap = getFieldMap(objectApiName);
         if (fieldMap != null) {
            Schema.SObjectField fldInfo = fieldMap.get(fieldApiName);
            if (fldInfo != null) {
               //fieldType = fldInfo.getDescribe().getType().name();
               fieldType = fldInfo.getDescribe().getSoapType().name();
            }
         } // if (fieldMap != null)
      } // if (objectAPIname
      return fieldType;
   } // getFieldSoapType
   
   // the map of the prefixes - so only selected once
   private static Map<String,String> prefixMap = new Map<String,String>();
   
   public static String getObjectPrefix(String sObjectName) {
      String prefix = prefixMap.get(sObjectName);
      if (prefix == null) {
         Schema.SObjectType rec = new ObjectHelper().getSObjectType(sObjectName);
         if (rec != null) {
            Schema.DescribeSObjectResult dor = rec.getDescribe();
            prefix = dor.getKeyPrefix();
            prefixMap.put(sObjectName,prefix);
         } // if (sObject
      } // if (prefix == null
      return prefix;
   } // getObjectPrefix

   public static String getObjectNameFromId(Id recId) {
      String objectName = (recId != null ? recId.getSObjectType().getDescribe().getName() : null);
      return objectName;
   } // getObjectNameFromId
    
   public static String getObjectLabelFromId(Id recId) {
      String objectLabel = (recId != null ? recId.getSObjectType().getDescribe().getLabel() : null);
      return objectLabel;
   } // getObjectLabelFromId
   
   /** For standard objects shouldn't be an issue hardcoding the prefixes. */
   public static final String PREFIX_ACCOUNT='001';
   public static final String PREFIX_CONTACT='003';
   public static final String PREFIX_LEAD='00Q';
   public static final String PREFIX_OPPTY='006';
   public static final String PREFIX_USER='005';
   public static final String PREFIX_GROUP='00G';
   public static final String PREFIX_CAMPAIGN='701';
   
   
   public static final String OBJECT_ACCOUNT='Account';
   public static final String OBJECT_CONTACT='Contact';
   public static final String OBJECT_LEAD='Lead';
   public static final String OBJECT_OPPTY='Opportunity';
   public static final String OBJECT_REF_ACCOUNT='Referral_Account__c';
   public static final String OBJECT_REF_CONTACT='Referral_Contact__c';
   public static final String OBJECT_EVENT='Event';
   public static final String OBJECT_TASK='Task';
   public static final String OBJECT_CASE='Case';
   public static final String OBJECT_USER='User';
   //Added by Bharat
   public static final String OBJECT_MED_QUESTIONNAIRE = 'PEO_Onboarding_Medical_Questionnaire__c';
   public static final String OBJECT_ONBOARDING_CHECKLIST = 'PEO_Onboarding_Checklist__c';
   
   /** Get the object name.
    */
   public static String getObjectName(SObject recToCheck) {
      String objectName = null;
      if (recToCheck != null) {
         SObjectType objectType = recToCheck.getSObjectType();
         if (objectType == Account.sObjectType) {
            objectName = OBJECT_ACCOUNT;
         } else if (objectType == Contact.sObjectType) {
            objectName = OBJECT_CONTACT;
         } else if (objectType == Lead.sObjectType) {
            objectName = OBJECT_LEAD;
         } else if (objectType == Opportunity.sObjectType) {
            objectName = OBJECT_OPPTY;
         } else if (objectType == Referral_Account__c.sObjectType) {
            objectName = OBJECT_REF_ACCOUNT;
         } else if (objectType == Referral_Contact__c.sObjectType) {
            objectName = OBJECT_REF_CONTACT;
         }
      } // if (recToCheck
      return objectName;
   } // getObjectName
   
   public static final String HOLD_OUT='Hold_Out__c';
   public static final String HOLD_OUT_401='HRS_Hold_Out__c';
   public static final String HOLD_OUT_ASO='Premier_PBS_Hold_Out__c';
   public static final String HOLD_OUT_HNBF='HNBF_Hold_Out__c';
   public static final String HOLD_OUT_PEO='OasisPEOHoldOut__c';
   
   /** Get the name of the holdout field for the passed in parameters.
    */
   public static String getHoldOutFieldName(String objectName, String salesOrg) {
      String fieldName = null;
      if (objectName != null && salesOrg != null) {
         if (objectName == OBJECT_ACCOUNT) {
             fieldName = (salesOrg == UserHelper.SO_401 ? HOLD_OUT_401 :
                          (salesOrg == UserHelper.SO_PEO_ASO ? HOLD_OUT_ASO :
                             (salesOrg == UserHelper.SO_HNB ? HOLD_OUT_HNBF :
                               (salesOrg == UserHelper.SO_PEO ? HOLD_OUT_PEO :
                                HOLD_OUT))));
         } else if (objectName == OBJECT_CONTACT) {
            fieldName = (salesOrg == UserHelper.SO_CORE ? HOLD_OUT :
                          (salesOrg == UserHelper.SO_MMS ? HOLD_OUT : 
                             null));
         } else if (objectName == OBJECT_LEAD) {
            fieldName = HOLD_OUT;
         } else if ((objectName == OBJECT_REF_ACCOUNT || objectName == OBJECT_REF_CONTACT) && salesOrg == UserHelper.SO_CORE) {
            fieldName = HOLD_OUT;
         } // if (objectName == OBJECT_ACCOUNT
      } // if (objectName != null
      System.debug('getHoldOutFieldName objectName='+objectName+' salesOrg='+salesOrg+' fieldName='+fieldName);
      return fieldName;
   } // getHoldOutFieldName
   
   public static final String FIELD_NUMBER_EMPS = 'NumberOfEmployees';
   public static final String FIELD_ASSET = 'X401k_Assets__c';
   
   /** Get the name of the employee count field. */
   public static String getEmpCntFieldName(String objectName) {
      String fieldName = ((objectName == OBJECT_ACCOUNT || objectName == OBJECT_LEAD) ? FIELD_NUMBER_EMPS : null);
      return fieldName;
   } // getEmpCntFieldName
   
   /** Get the name of the asset field. */
   public static String getAssetFieldName(String objectName) {
      String fieldName = ((objectName == OBJECT_ACCOUNT || objectName == OBJECT_LEAD) ? FIELD_ASSET : null);
      return fieldName;
   } // getAssetFieldName
   
   public static final String OWNER_FIELD='OwnerId';
   public static final String OWNER_ACCOUNT_MMS='MMS_Account_Owner__c';
   public static final String OWNER_CONTACT_MMS='MMS_Contact_Owner__c';
   public static final String OWNER_ACCOUNT_401='HRS_Account_Owner__c';
   public static final String OWNER_CONTACT_401='HRS_Contact_Owner__c';
   public static final String OWNER_ACCOUNT_ASO='Premier_PBS_Account_Owner__c';
   public static final String OWNER_CONTACT_ASO='Premier_PBS_Contact_Owner__c';
   public static final String OWNER_ACCOUNT_HNBF='HNBF_Account_Owner__c';
   public static final String OWNER_CONTACT_HNBF='HNBF_Contact_Owner__c';
   public static final String OWNER_ACCOUNT_WHOLE_INT='Internal_Wholesaler_Account_Owner__c';
   public static final String OWNER_CONTACT_WHOLE_INT='Internal_Wholesaler_Contact_Owner__c';
   //public static final String OWNER_ACCOUNT_WHOLE_EXT='External_Wholesaler_Account_Owner__c';
   //public static final String OWNER_CONTACT_WHOLE_EXT='External_Wholesaler_Contact_Owner__c';
   public static final String OWNER_ACCOUNT_PEO='OasisPEOAccountOwner__c';
   public static final String OWNER_CONTACT_PEO='OasisPEOOwner__c';

   /** Get the name of the owner field for the passed in parameters
    */ 
   public static String getOwnerFieldName(String objectName, String salesOrg) {
      return getOwnerFieldName(objectName,salesOrg,null);
   } // getOwnerFieldName
   
   /** Get the name of the owner field for the passed in parameters
    */ 
   public static String getOwnerFieldName(String objectName, String salesOrg, String segmentName) {
      // default value
      String fieldName = null;
      if (String.IsNotBlank(objectName) && String.isNotBlank(salesOrg)) {
         if (salesOrg == UserHelper.SO_CORE) {
            fieldName = OWNER_FIELD;
         } else if (salesOrg == UserHelper.SO_MMS && objectName == OBJECT_REF_ACCOUNT) {
            fieldName = OWNER_ACCOUNT_MMS;
         } else if (salesOrg == UserHelper.SO_MMS && objectName == OBJECT_REF_CONTACT) {
            fieldName = OWNER_CONTACT_MMS;
         } else if (salesOrg == UserHelper.SO_MMS && (objectName == OBJECT_ACCOUNT || objectName == OBJECT_CONTACT || objectName == OBJECT_LEAD)) {
            fieldName = OWNER_FIELD;
         } else if (salesOrg == UserHelper.SO_PEO) {
            fieldName = (objectName == OBJECT_ACCOUNT ? OWNER_ACCOUNT_PEO : (objectName == OBJECT_CONTACT ? OWNER_CONTACT_PEO : OWNER_FIELD));
         } else if (salesOrg == UserHelper.SO_401) {
            fieldName = ((objectName == OBJECT_CONTACT || objectName == OBJECT_REF_CONTACT) 
                          ? OWNER_CONTACT_401 : ((objectName == OBJECT_ACCOUNT || objectName == OBJECT_REF_ACCOUNT) ? OWNER_ACCOUNT_401 : null));
         } else if (salesOrg == UserHelper.SO_PEO_ASO) {
            fieldName = ((objectName == OBJECT_CONTACT || objectName == OBJECT_REF_CONTACT) 
                          ? OWNER_CONTACT_ASO : ((objectName == OBJECT_ACCOUNT || objectName == OBJECT_REF_ACCOUNT) ? OWNER_ACCOUNT_ASO : null));
         } else if (salesOrg == UserHelper.SO_HNB) {
            fieldName = ((objectName == OBJECT_CONTACT || objectName == OBJECT_REF_CONTACT) 
                          ? OWNER_CONTACT_HNBF : ((objectName == OBJECT_ACCOUNT || objectName == OBJECT_REF_ACCOUNT) ? OWNER_ACCOUNT_HNBF : null));
         /*} else if (salesOrg == UserHelper.SO_WHOLESALER && segmentName != null && segmentName == UserHelper.WHOLESALER_EXTERNAL) {
            fieldName = ((objectName == OBJECT_REF_CONTACT) 
                          ? OWNER_CONTACT_WHOLE_EXT : ((objectName == OBJECT_REF_ACCOUNT) ? OWNER_ACCOUNT_WHOLE_EXT : null));*/
         } else if (salesOrg == UserHelper.SO_WHOLESALER && segmentName != null && segmentName == UserHelper.WHOLESALER_INTERNAL) {
            fieldName = ((objectName == OBJECT_REF_CONTACT) 
                          ? OWNER_CONTACT_WHOLE_INT : ((objectName == OBJECT_REF_ACCOUNT) ? OWNER_ACCOUNT_WHOLE_INT : null));
         }
      } // if (objectName != null
      System.debug('getOwnerFieldName objectName='+objectName+' salesOrg='+salesOrg+' segmentName='+segmentName+' fieldName='+fieldName);
      return fieldName;
   }  // getOwnerFieldName
   
   // field names to typically exclude from the queries. */
   public static Set<String> excludeFieldNames = new Set<String>{'ConnectionReceivedId','ConnectionSentId','CreatedById','CreatedDate','LastModifiedById','LastModifiedDate','SystemModstamp'
                                                                ,'IsDeleted','LastViewedDate','LastReferencedDate'};
   
   // wraps up the query and list of fields together
   public class SoqlWrapper {
      public String objectApiName=null;
      // default to having the ID field
      public String[] flds = new String[]{'Id'};
      public String query = null;
      public Set<String> booleanFlds = new Set<String>();
   } // class SoqlWrapper
   
   
   
   // formula fields - isCalculated()
   public static Map<String,String[]> fieldNameByObjectNameMap = new Map<String,String[]>();
   public static Map<String,Set<String>> booleanFldSetsByObjectMap = new Map<String,Set<String>>();
   
   //public static Map<String,String> SOQLQueryMap = new Map<String,String>();
   
   public static String getSOQLQuery(String objectApiName, String[] extraFields, Boolean doNotIncludeExcludeFields, Boolean doNotIncludeFormulas) {
      return (getSOQLQuery(objectApiName, extraFields, doNotIncludeExcludeFields, doNotIncludeFormulas, true, false));
   } // getSOQLQuery

   public static String latestKey = null; 
   public static SoqlWrapper latestSoqlWrapper = null;

   //Generate a SOQL query based on the fields that exist for the object using the describe.
   // @param extraFields if you want to add extra fields in the query that are not at the first level of the object.
   // @param doNotIncludeLookupObjects do not include the fields from any any lookup records. Will include the field itself with the ids
   public static String getSOQLQuery(String objectApiName, String[] extraFields, Boolean doNotIncludeExcludeFields, Boolean doNotIncludeFormulas, Boolean doNotIncludeLookupObjects) {
      return (getSOQLQuery(objectApiName, extraFields, doNotIncludeExcludeFields, doNotIncludeFormulas, doNotIncludeLookupObjects, false, false));
   }
      
   public static String getSOQLQuery(String objectApiName, String[] extraFields, Boolean doNotIncludeExcludeFields, Boolean doNotIncludeFormulas, Boolean doNotIncludeLookupObjects, Boolean onlyUpdateable) {
      return (getSOQLQuery(objectApiName, extraFields, doNotIncludeExcludeFields, doNotIncludeFormulas, doNotIncludeLookupObjects, onlyUpdateable, false));
   }

   public static String getSOQLQuery(String objectApiName, String[] extraFields, Boolean doNotIncludeExcludeFields, Boolean doNotIncludeFormulas, Boolean doNotIncludeLookupObjects, Boolean onlyUpdateable, Boolean skipCache) {
       //String query = null;
      latestSoqlWrapper = null;
      if (String.IsNotBlank(objectApiName)) {
         latestKey = objectApiName+(extraFields != null ? extraFields.size() : 0)+doNotIncludeExcludeFields+doNotIncludeFormulas+doNotIncludeLookupObjects;
         // remove the underscores from the object names
         latestKey = latestKey.replace('_','');

         latestSoqlWrapper = (!skipCache ? (SoqlWrapper)CacheManager.getOrg(latestKey) : null); 
         if (latestSoqlWrapper == null) {
            latestSoqlWrapper = new SoqlWrapper();
            latestSoqlWrapper.objectApiName = objectApiName;
         //}
         // try to retrieve the query
         //query = SOQLQueryMap.get(objectApiName);
         //if (query == null) {
            Map<String, Schema.SObjectField> fieldMap = new ObjectHelper().getFieldMap(objectApiName);
            if (fieldMap != null) {
               //String[] fieldNames = new String[]{'Id'};
               //latestSoqlWrapper.flds = new String[]{'Id'};
               
               System.debug('getSOQLQuery building query');
               latestSoqlWrapper.query = 'Select Id';
               for (Schema.SObjectField fld : fieldMap.values()) {
                  Schema.DescribeFieldResult dfr = fld.getDescribe();
                  String fieldName = dfr.getName();
                  // the id is already included by default so don't include it again
                  Boolean useField = fieldName != 'Id';
                  
                  if (useField && doNotIncludeExcludeFields && excludeFieldNames.contains(fieldName)) {
                     useField = false;
                  }
                  
                  if (useField && doNotIncludeFormulas && dfr.isCalculated()) {
                     useField = false;
                  }
                  
                  // only include fields directly on the object - do not use fields from a relationship
                  if (useField && doNotIncludeLookupObjects && fieldName.contains('.')) {
                     useField = false;
                  }
                  
                  if (useField && onlyUpdateable && !(dfr.isUpdateable() && dfr.isCreateable())) {
                     useField = false;
                  }
                  
                  System.debug('getSOQLQuery useField='+useField+' fieldName='+fieldName);
                  if (useField) {
                     latestSoqlWrapper.query += ', '+fieldName;
                     //fieldNames.add(fieldName);
                     latestSoqlWrapper.flds.add(fieldName);
                     if (dfr.getType() == Schema.DisplayType.Boolean) {
                        latestSoqlWrapper.booleanFlds.add(fieldName);
                     }
                  }
               } // for (Schema.SObjectField
               
               if (extraFields != null && !extraFields.isEmpty()) {
                  for (String fldName : extraFields) {
                     latestSoqlWrapper.query += ','+fldName;
                     //fieldNames.add(fldName);
                     latestSoqlWrapper.flds.add(fldName);
                  }
               } // if (extraFields != null
               
               latestSoqlWrapper.query += ' From '+objectApiName;
               try {
                  CacheManager.putOrg(latestKey,latestSoqlWrapper);
               } catch (Exception e) {
                  System.debug('getSOQLQuery exception: '+e.getMessage()+'; '+e.getStackTraceString());
               }
               //SOQLQueryMap.put(objectApiName,query);
               //fieldNameByObjectNameMap.put(objectApiName,fieldNames);
            } // if (fieldMap != null
         } // if (query != null
         if (latestSoqlWrapper != null) {
            fieldNameByObjectNameMap.put(objectApiName,latestSoqlWrapper.flds);
            booleanFldSetsByObjectMap.put(objectApiName,latestSoqlWrapper.booleanFlds);
            System.debug('getSOQLQuery flds='+latestSoqlWrapper.flds.size()+' booleanFlds='+latestSoqlWrapper.booleanFlds.size());
         }
      } // if (String.IsNotBlank
      String query = (latestSoqlWrapper != null ? latestSoqlWrapper.query : null);
      System.debug('getSOQLQuery query='+query);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getSOQLQuery query='+query));
      return query;
   } // getSOQLQuery
   
   // check the passed in value - format based on the fld passed in
   public static Object formatStringAsObject(Schema.SObjectField fld, String checkValue) {
      Object returnObj = null;
      if (fld != null && String.isNotBlank(checkValue)) {
         returnObj = null;
         Schema.DisplayType fldType = fld.getDescribe().getType();
         System.debug('formatStringAsObject fld='+fld+' fldType='+fldType+' checkValue='+checkValue);
         // remove beginning and ending quotes
         checkValue = checkValue.removeStart('"').removeEnd('"').trim();
         try {
            if (fldType == Schema.DisplayType.Boolean) {
               Boolean value = (checkValue.toLowerCase() == 'true');
               returnObj = value;
            } else if (fldType == Schema.DisplayType.DateTime) {
               Integer spacePos = checkValue.indexOf(' ');
               //System.debug('formatStringAsObject spacePos='+spacePos);
               // check for the format 2016-07-19 14:31:47
               if (spacePos > -1 && checkValue.indexOf('-') < spacePos && checkValue.indexOf(':') > spacePos) {
                  String datePortion = checkValue.subString(0,spacePos).trim();
                  String timePortion = checkValue.subString(spacePos).trim();
                  String[] dateTokens = datePortion.split('-');
                  String[] timeTokens = timePortion.split(':');
                  //System.debug('formatStringAsObject datePortion='+datePortion+' dateTokens='+dateTokens.size()+' timePortion='+timePortion+' timeTokens='+timeTokens.size());
                  if (dateTokens.size() == 3 && timeTokens.size() == 3) {
                     Integer year = Integer.valueOf(dateTokens[0]);
                     Integer month = Integer.valueOf(dateTokens[1]);
                     Integer day = Integer.valueOf(dateTokens[2]);
                     
                     Integer hour = Integer.valueOf(timeTokens[0]);
                     Integer minute = Integer.valueOf(timeTokens[1]);
                     Integer second = Integer.valueOf(timeTokens[2]);
                     
                     DateTime newDateTime = DateTime.newInstance(year, month, day, hour, minute, second);
                     returnObj = newDateTime;
                  }
               } // if (spacePos > -1

            } else if (fldType == Schema.DisplayType.Date) {
               // strip off any time component
               if (checkValue.contains(' ')) {
                  checkValue = checkValue.subString(0,checkValue.indexOf(' ')).trim();
                  System.debug('formatStringAsObject trimmed date checkValue='+checkValue);
               }
               // assume in the format mm/dd/yyyy
               String[] tokens = checkValue.split('/');
               //System.debug('formatStringAsObject date tokens='+tokens);
               if (tokens.size() == 3) {
                  Integer month = Integer.valueOf(tokens[0]);
                  Integer day = Integer.valueOf(tokens[1]);
                  Integer year = Integer.valueOf(tokens[2]);
                  Date newDate = Date.newInstance(year,month,day);
                  returnObj = newDate;
                  //System.debug('formatStringAsObject date returnObj='+returnObj+' day='+day+' month='+month+' year='+year);
               } else {
                  // check for tokens using '-' - 'yyyy-mm-dd'
                  tokens = checkValue.split('-');
                  Integer year = Integer.valueOf(tokens[0]);
                  Integer month = Integer.valueOf(tokens[1]);
                  Integer day = Integer.valueOf(tokens[2]);
                  Date newDate = Date.newInstance(year,month,day);
                  returnObj = newDate;
               } // if (tokens.size() == 3
               // todo - do we need to do anything else here?
            } else if (fldType == Schema.DisplayType.Currency
                       || fldType == Schema.DisplayType.Double
                       || fldType == Schema.DisplayType.Percent) {
               // remove the obvious special characters - not sure if we want to be more aggresive about this?
               Boolean isNeg = (String.isNotBlank(checkValue) && (checkValue.startsWith('-') || checkValue.startsWith('(')));
               String cleansedCheckValue = Utilities.removeExtraChars(checkValue,'0123456789.');
               //String cleansedCheckValue = checkValue.remove('$').remove('%');
               Double dblValue = Double.valueOf(cleansedCheckValue) * (isNeg ? -1 : 1);
               returnObj = dblValue;
            } else if (fldType == Schema.DisplayType.Integer) {
               Boolean isNeg = (String.isNotBlank(checkValue) && (checkValue.startsWith('-') || checkValue.startsWith('(')));
               Integer intValue = Integer.valueOf(checkValue) * (isNeg ? -1 : 1);
               returnObj = intValue;
            } else if (fldType == Schema.DisplayType.Phone) {
               String phoneNum = StringHelper.formatPhoneNumber(checkValue,true);
               //String phoneNum = '('+checkValue.left(3)+') '+checkValue.mid(3,3)+'-'+checkValue.right(4);
               returnObj = phoneNum;
            } else if (fldType == Schema.DisplayType.EMAIL) {
               // make sure there is at least an '@' in the email.
               String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; // source: http://www.regular-expressions.info/email.html
               //String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
	           Pattern myPattern = Pattern.compile(emailRegex);
	           Matcher myMatcher = myPattern.matcher(checkValue);
               System.debug('formatStringAsObject myMatcher='+myMatcher.matches());
               if (!myMatcher.matches()) {
                  System.debug('formatStringAsObject Not a valid email: '+checkValue);
                  returnObj = null;
               } else {
                  returnObj = checkValue;
               }
            } else {
               // assume string values at the end
               returnObj = checkValue;
            }
         } catch (Exception e) {
            System.debug('formatStringAsObject error formating '+checkValue+' for '+fldType+': '+e.getStackTraceString());
         }

      } // if (fld != null
      return returnObj;
   } // formatStringAsObject

} // class ObjectHelper