/* 
 * Helper class to manage SObjects
 *
 * History
 * -------
 * 04/27/2011 Dan Carmen   Created
   06/23/2011 Dan Carmen   Added additional describe and checkField functionality.
   09/09/2011 Dan Carmen   Additional functionality to the checkField method
   10/26/2018 Dan Carmen   Increment API to version 44

 */
public with sharing class SObjectHelper {

   public static final String SAVE_INSERT = 'Insert';
   public static final String SAVE_UPDATE = 'Update';

   /** Default constructor.
    */
   public SObjectHelper() {
   	
   } // SObjectHelper
   
   /** Save the records passed in. If inserting the records and there's a parent id,
       will set that value on the records.
    */
   public Boolean saveRecords(SObject[] recs, String parentFieldName, Id parentId) {
      Boolean allOkay = true;
      // only proceed if records are passed in
  	  if (recs != null && recs.size() > 0) {
   	     // if a lookup field is passed in, set the value on the fields that are inserts.
         if (parentFieldName != null && parentId != null) {
            for (SObject rec : recs) {
               if (rec.Id == null) {
                  rec.put(parentFieldName, parentId);
         	   }
            } // for
         } // if (parentFieldName)
         Integer numSuccess=0;
         Integer numFailure=0;
         List<Database.upsertResult> uResults = Database.upsert(recs,false);
         for (Integer cnt=0; cnt<uResults.size(); cnt++) {
            Database.upsertResult result = uResults.get(cnt);
            if (!result.isSuccess()) {
               allOkay = false;
               numFailure++;
               String errorStr = '';
               for (Database.Error err : result.getErrors()) {
                  errorStr += err.getMessage();
               }
               recs.get(cnt).addError(errorStr);
            } else {
               numSuccess++;
            }
         } // for
         System.debug('saveRecords numRec='+recs.size()+' numSuccess='+numSuccess+' numFailure='+numFailure);
  	  } // if (recs != null
      return allOkay;
   } // saveRecords
   
   /** Update a collection of SObjects.
    */
    /*
   public Boolean updateRecs(SObject[] recs) {
      return saveRecs(SAVE_UPDATE,recs);
   } // updateRecs
   
   /** Insert a collection of SObjects.
    */
    /*
   public Boolean insertRecs(SObject[] recs) {
      return saveRecs(SAVE_INSERT,recs);
   } // insertRecs

   /** Save records
    */
    /*
   public Boolean saveRecs(String saveType, SObject[] recs) {
      if (!recs.isEmpty()) {
         try {
            if (saveType == SAVE_UPDATE) {
               update recs;
            } else if (saveType == SAVE_INSERT) {
               insert recs;
            }
         } catch (Exception e) {
            return false;
         }
      } // if (!recs.isEmpty()
      return true;
   } // saveRecs
   */

   private Map<String, Schema.SObjectType> globalDescribe = null;
   
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
      Map<String, Schema.SObjectType> allObjects = getGlobalDescribe();
      Map<String,Boolean> results = new Map<String,Boolean>();
      if (sobjectNames != null) {
         for (String objectName : sobjectNames) {
            results.put(objectName,(allObjects.containsKey(objectName) ? True : False));
         }
      }
      return results;
   } // doObjectsExist
   
   /** Get the SObjectType for the passed in name.
    */
   public Schema.SObjectType getSObjectType(String sObjectName) {
      Map<String, Schema.SObjectType> globalDescribe = getGlobalDescribe();
      return (sObjectName != null ? globalDescribe.get(sObjectName) : null);
   } // getSObjectType
   
   /** Store all of the values so don't have to do additional describes. */
   private Map<String,Map<String, Schema.SObjectField>> objectFieldMap = new Map<String,Map<String, Schema.SObjectField>>();
   
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
   
   /** Check if a field exists on an object.
    */
   public Boolean checkField(String objectApiName, String fieldApiName) {
   	  return checkField(objectApiName, fieldApiName, 'access');
   } // checkField

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
   	     	      if (actionType == null || actionType == 'access') {
   	     	         fldFound = fieldDescribe.isAccessible();
   	     	      } else if (actionType != null && actionType == 'update') {
   	     	         fldFound = fieldDescribe.isUpdateable();
   	     	      } else if (actionType != null && actionType == 'create') {
   	     	         fldFound = fieldDescribe.isCreateable();
   	     	      } else if (actionType != null && actionType == 'writeRequireMasterRead') {
   	     	         fldFound = fieldDescribe.isWriteRequiresMasterRead();
   	     	      }
   	     	   } // if (fieldDescribe != null
   	     	} // if (fld != null
   	     } // if (fieldMap != null
   	  } // if (objectApiName
   	  System.debug('SObjectHelper.checkField objectApiName='+objectApiName+' fieldApiName='+fieldApiName+' actionType='+actionType+' fldFound='+fldFound);
      return fldFound;
   } // checkField

} // class SObjectHelper