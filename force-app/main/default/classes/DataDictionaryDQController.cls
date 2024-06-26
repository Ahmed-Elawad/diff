/* 
 * A process to populate the Data Dictionary (Data_Dictionary__c).
 *
 * History
 * -----------
  10/15/2020 Manmeet Vaseer       Created
  11/05/2020 Manmeet Vaseer       Added Field Description along with Help Text
  01/11/2021 Manmeet Vaseer       Added field's Last Modified Date
  03/08/2021 Dan Carmen           Build in messaging to process
  01/06/2022 Dan Carmen           Add NotifyAllChanges__c

 */
public class DataDictionaryDQController {

    public static Integer nbrFieldsFromToolingAPI=0;
    public static Integer nbrDataDictionaryRecs=0;
    public static Integer nbrInserts=0;
    public static Integer nbrUpdates=0;
    public static Integer nbrDeletes=0;
    public static Integer nbrExcluded=0;
    
    // standard fields we don't need to include in the data dictionary
    public static String[] EXCLUDE_FLDS=(Label.DataDictionary_ExcludeFlds.toLowerCase()).split(',');
    
    static public void populateDict(DataDictionaryObject__c ddo) {
        notificationMap.clear();
        nbrDataDictionaryRecs = 0;
        nbrInserts = 0;
        nbrUpdates = 0;
        nbrDeletes = 0;
        String objName = ddo.ObjectAPIName__c;
        log('populateDict', 'Updated Data Dictionary fields for: ' + objName + ' object');
        
        // pull data using the tooling API
        Map<String,FieldDefRecords> fieldsMap = getFieldsMap(objName);
        nbrFieldsFromToolingAPI = fieldsMap.size();
        if(fieldsMap.size() == 0)   {
            System.debug('No mappings of '+objName+' found.');
            return;
        }
            
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        String[] objNames = new String[]{};

        objNames.addAll(globalDescribe.keySet());
        objNames.sort();

        Map<String, Data_Dictionary__c> currentFldsMap = new Map<String, Data_Dictionary__c>();
        Data_Dictionary__c[] currentFlds = [SELECT Id, Name
                                                  ,API_Name__c
                                                  ,Data_Type__c
                                                  ,Definition__c 
                                                  ,Deleted_Date__c
                                                  ,Description__c
                                                  ,Field_Label__c
                                                  ,Field_Last_Modified_Date__c
                                                  ,Help_Text__c
                                                  ,Is_Currently_Used__c
                                                  ,Is_Required__c
                                                  ,Is_System__c
                                                  ,Length__c
                                                  ,NotifyFieldChange__c
                                              from Data_Dictionary__c 
                                             WHERE DataDictionaryObject__c=:ddo.Id];
        nbrDataDictionaryRecs = currentFlds.size();
        for(Data_Dictionary__c dd : currentFlds)  {
            currentFldsMap.put(dd.Name, dd);
        }
        log('populateDict', 'Current Data Dictionary Size: ' + currentFlds.size() + ' fields');

        List<Data_Dictionary__c> upsertDds = new List<Data_Dictionary__c>();
        for (String oName : objNames) { 
            if (oName == objName)   { // check for valid object name
                Schema.SObjectType obj = globalDescribe.get(oName);
                Map<String, Schema.SObjectField> fMap = obj.getDescribe().Fields.getMap();
                for (String fldName : fMap.keySet()) {
                   System.debug('populateDict fldName='+fldName);
                   if (EXCLUDE_FLDS.contains(fldName)) {
                      nbrExcluded++;
                   } else {
                      Schema.SObjectField fld = fMap.get(fldName);
                      Schema.DescribeFieldResult dfr = fld.getDescribe();
                      Schema.DisplayType dType = dfr.getType();

                      String uniqueFieldName = objName + '.' + dfr.getName();
                      // get all the current attributes. Compare them against the existing 
                      Data_Dictionary__c dd = new Data_Dictionary__c();
                      dd.DataDictionaryObject__c = ddo.Id;
                      dd.Name = uniqueFieldName;
                      dd.Domain__c = objName;
                      dd.Field_Label__c = dfr.getLabel();
                      dd.API_Name__c = dfr.getName();
                      dd.Data_Type__c = dType.name();
                      Integer length = dfr.getLength();
                      if (length == 0 && dfr.getPrecision() > 0) {
                         length = dfr.getPrecision();
                      }
                      dd.Length__c = length;
                      dd.Help_Text__c = dfr.getInlineHelpText();
                      dd.Is_System__c = !dfr.getName().endsWith('__c');
                      dd.Is_Required__c = !dfr.isNillable();
                     
                      FieldDefRecords fdr = fieldsMap.get(dfr.getName());                    
                      if (fdr != null) {
                          dd.Field_Last_Modified_Date__c = (fdr.lastModifiedDate != null ? fdr.lastModifiedDate : null);
                          dd.Description__c = (String.isNotBlank(fdr.description) ? fdr.description : null);
                      }
                      Data_Dictionary__c existingDD = currentFldsMap.remove(uniqueFieldName);
                      if (existingDD == null) {
                         upsertDds.add(dd);
                         nbrInserts++;
                         logChanges('<font color="RED">New Field created</font>',ddo.NotifyNewField__c, ddo.NotifyAllChanges__c, ddo.Name, ddo.ObjectAPIName__c, null, dd);
                      } else if (existingDD.Field_Label__c != dd.Field_Label__c
                                || existingDD.Data_Type__c != dd.Data_Type__c
                                || existingDD.Length__c != dd.Length__c
                                || existingDD.Help_Text__c != dd.Help_Text__c
                                || existingDD.Field_Last_Modified_Date__c != dd.Field_Last_Modified_Date__c
                                || existingDD.Description__c != dd.Description__c) {
                         // update to new values
                         nbrUpdates++;
                         logChanges('Field attributes changed',existingDD.NotifyFieldChange__c, ddo.NotifyAllChanges__c, ddo.Name, ddo.ObjectAPIName__c, existingDD, dd);
                         existingDD.Field_Label__c = dd.Field_Label__c;
                         existingDD.Data_Type__c = dd.Data_Type__c;
                         existingDD.Length__c = dd.Length__c;
                         existingDD.Help_Text__c = dd.Help_Text__c;
                         existingDD.Field_Last_Modified_Date__c = dd.Field_Last_Modified_Date__c;
                         existingDD.Description__c = dd.Description__c;
                         upsertDds.add(existingDD);
                      }
                   } // if (!EXCLUDE_FLDS.contains(fldName)
                } // for (String fldName : fMap.keySet()
            }
        } // for (String oName

        log('populateDict', 'Total Data Dictionary fields Inserted/Updated: ' + upsertDds.size());
        
        /*
         * The leftover values in the map are deleted from the objName object.
         * Update its Deleted_Date__c.
        */
        log('populateDict', 'Total Data Dictionary fields will be marked Deleted: ' + currentFldsMap.size());
        if(!currentFldsMap.isEmpty()) {
            List<Data_Dictionary__c> deletedFields = currentFldsMap.values();
            for(Data_Dictionary__c dd : deletedFields)  {
                if(dd.Deleted_Date__c == null)  {
                    nbrDeletes++;
                    dd.Deleted_Date__c = Date.today();
                    dd.Field_Last_Modified_Date__c = Date.today();
                    upsertDds.add(dd);
                    logChanges('<font color="RED">Field Deleted</font>',ddo.NotifyNewField__c, ddo.NotifyAllChanges__c, ddo.Name, ddo.ObjectAPIName__c, null, dd);
                }
            }
        }
        
        log('populateDict', 'Total Data Dictionary fields will be upserted: ' + upsertDds.size());
        if (!upsertDds.isEmpty()) {
           upsert upsertDds;
        }
    } // populateDict

    public static Map<String,String[]> notificationMap = new Map<String,String[]>();
    
    public static void logChanges(String logType, String keyValues, String keyValues2, String objectName, String apiName, Data_Dictionary__c existingDD, Data_Dictionary__c newDD) {
      // use a set in case the same name is in both places
      Set<String> keySet = new Set<String>();
      if (String.isNotBlank(keyValues)) {
         keySet.addAll(keyValues.split(','));
      }
      if (String.isNotBlank(keyValues2)) {
         keySet.addAll(keyValues2.split(','));
      }
      
      if (!keySet.isEmpty()) {
         String fieldTxt = '<br/>'+logType+' on '+objectName+' (API: '+apiName+')';
         fieldTxt += '<br/><b>Label:</b> '+(existingDD != null && existingDD.Field_Label__c != newDD.Field_Label__c ? 'Previous value: '+ existingDD.Field_Label__c+' <font color="RED">Changed To</font> ' : '')+newDD.Field_Label__c;
         fieldTxt += '<br/><b>API Name:</b> '+(existingDD != null && existingDD.API_Name__c != newDD.API_Name__c ? 'Previous value: '+existingDD.API_Name__c+' <font color="RED">Changed To</font> ' : '')+newDD.API_Name__c;
         fieldTxt += '<br/><b>Data Type:</b> '+(existingDD != null && existingDD.Data_Type__c != newDD.Data_Type__c ? 'Previous value: '+existingDD.Data_Type__c+' <font color="RED">Changed To</font> ' : '')+newDD.Data_Type__c;
         fieldTxt += '<br/><b>Length:</b> '+(existingDD != null && existingDD.Length__c != newDD.Length__c ? 'Previous value: '+existingDD.Length__c+' <font color="RED">Changed To</font> ' : '')+newDD.Length__c;
         fieldTxt += '<br/><b>Description:</b> '+(existingDD != null && existingDD.Description__c != newDD.Description__c ? 'Previous value: '+fieldValue(existingDD.Description__c)+' <font color="RED">Changed To</font> ' : '')+fieldValue(newDD.Description__c);
         fieldTxt += '<br/><b>Help Text:</b> '+(existingDD != null && existingDD.Help_Text__c != newDD.Help_Text__c ? 'Previous value: '+fieldValue(existingDD.Help_Text__c)+' <font color="RED">Changed To</font> ' : '')+fieldValue(newDD.Help_Text__c);
         for (String key : keySet) {
            String[] notifies = (notificationMap.containsKey(key) ? notificationMap.get(key) : new String[]{});
            notifies.add(fieldTxt);
            notificationMap.put(key,notifies);
         }
      } // if (String.isNotBlank(keyValues

   } // logChanges
    
   public static String fieldValue(String value) {
      return (String.isNotBlank(value) ? value : '');
   }
    
    // Schema does not have any method to get the Field Description & LastModifiedDate of that field.
    static public Map<String,FieldDefRecords> getFieldsMap(String objName)  {
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        
        /*
        Select EntityDefinition.DurableId, Label, DeveloperName, DurableId, QualifiedApiName, DataType,  Description, LastModifiedDate from FieldDefinition Where EntityDefinition.QualifiedApiName='Account' 
        */
        String path = '/services/data/v50.0/tooling/query/?q=Select+QualifiedApiName,Description,LastModifiedDate+from+FieldDefinition+Where+EntityDefinition.QualifiedApiName=\''+objName+'\'';
        String domain = URL.getSalesforceBaseUrl().getHost();
        req.setEndpoint('https://' + domain + path); 
        req.setMethod('GET');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        //System.debug(res.getBody());   

        // Parse entire JSON response.
        System.JSONParser parser = JSON.createParser(res.getBody());

        FieldDef obj;
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                obj = (FieldDef)parser.readValueAs(FieldDef.class);
            }
        }        
        
        Map<String,FieldDefRecords> apiMap = new Map<String,FieldDefRecords>();
        if(obj != null) {
            List<FieldDefRecords> records = obj.records;
            for(FieldDefRecords r : records)    {
                apiMap.put(r.qualifiedApiName, r);
            }
        }
        
        System.debug('Map Size: ' + apiMap.size());
        return apiMap;
    } // getFieldsMap


    public class FieldDef   {
        public Long size;
        public Long totalSize;
        public Boolean done;
        public String queryLocator;
        public String entityTypeName;
        
        public List<FieldDefRecords> records;    
    }
    
    public class FieldDefRecords {
        public FieldDefRecordsAttrs attributes;
        public String qualifiedApiName;
        public String description;
        public Datetime lastModifiedDate;
    }
    
    public class FieldDefRecordsAttrs {
        public String type;
        public String url;
    }
    
    static private void log(String method, String msg)  {
        System.debug('DataDictionaryDQ::' + method  + ': ' + msg);
    }
} //class