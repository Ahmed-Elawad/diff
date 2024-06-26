/* 
 * Mimic some of the workflow behavior in a trigger class using custom metadata types
 
    Things to work on:
    Handle boolean fields
 
 *
 * History
 * -------
   04/13/2018 Dan Carmen       Created
   11/09/2018 Dan Carmen       Added functionality for Lead and Contact
   04/10/2019 Dan Carmen       Add Opportunity and OnlyIfBlank__c
   09/01/2021 Dan Carmen       Add Operation__c field and addition logic

 */
public with sharing class WorkflowHelper implements TriggerInterfaceC {
   
   // to only run once per transaction
   public static Set<String> ALREADY_RAN_SET = new Set<String>();

   //public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      // check what the type of the first record is
      System.debug('WorkflowHelper.checkAllBeforeTrigger recs='+(recs != null ? recs.size() : -1));
      if (isBefore && recs != null && !recs.isEmpty()) {
         SObjectType recType = recs[0].getSObjectType();
         String objectName = recType.getDescribe().getName();
         if (!ALREADY_RAN_SET.contains(objectName)) {
            if (objectName == ObjectHelper.OBJECT_CASE) {
               //checkCases((Case[])recs, (Map<Id,Case>)oldMap);
               checkRecsWithRT(recs, oldMap, objectName, Case.getSobjectType().getDescribe().getRecordTypeInfosById());
            } else if (objectName == ObjectHelper.OBJECT_LEAD) {
               //checkLeads((Lead[])recs, (Map<Id,Lead>)oldMap);
               checkRecsNoRT(recs, oldMap, objectName);
            } else if (objectName == ObjectHelper.OBJECT_CONTACT) {
               //checkContacts((Contact[])recs, (Map<Id,Contact>)oldMap);
               checkRecsNoRT(recs, oldMap, objectName);
            } else if (objectName == ObjectHelper.OBJECT_OPPTY) {
               checkRecsNoRT(recs, oldMap, objectName);
            }
            ALREADY_RAN_SET.add(objectName);
         }
      } // if (recs != null
   } // checkAllBeforeTrigger

   //public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
   
   // see if there are any actions that need to take place at the end of the trigger.
   //public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}
   
   public static void checkRecsNoRT(SObject[] recs, Map<Id,SObject> oldMap, String objectName) {
      System.debug('checkRecsNoRT objectName='+objectName+' recs='+recs.size());
      // not adding record type logic at this point
      ObjectWorkFlow__mdt[] objectFlows = getObjectWorkflows(objectName, new Set<String>{'None'});
      if (objectFlows != null) {
         for (ObjectWorkFlow__mdt objectFlow : objectFlows) {
            processFieldRules(recs, oldMap, objectFlow, objectName);
         } // for (ObjectWorkFlow__mdt objectFlow
      } // if (objectFlows != null
   } // checkRecsNoRT
   
   public static void checkRecsWithRT(SObject[] recs, Map<Id,SObject> oldMap, String objectName, Map<Id, Schema.RecordTypeInfo> rtByIdMap) {
      System.debug('checkRecsWithRT objectName='+objectName+' recs='+recs.size());
      // to be able to determine the record type names of the cases
      Map<String, SObject[]> recByRtNameMap = new Map<String, SObject[]>();
      for (SObject rec : recs) {
         Id recordTypeId = (Id)rec.get('RecordTypeId');
         Schema.RecordTypeInfo rtInfo = (recordTypeId != null ? rtByIdMap.get(recordTypeId) : null);
         //System.debug('checkCases RecordTypeId='+cs.RecordTypeId+' rtInfo='+rtInfo);
         if (rtInfo != null) {
            String rtName = rtInfo.getName();
            //System.debug('checkCases rtName='+rtName);
            SObject[] recsByRt = (recByRtNameMap.containsKey(rtName) ? recByRtNameMap.get(rtName) : new SObject[]{});
            recsByRt.add(rec);
            recByRtNameMap.put(rtName, recsByRt);
         }
      } // for (Case cs
      
      if (!recByRtNameMap.isEmpty()) {
         // pull back the workflows active for all records too
         Set<String> rtNameSet = new Set<String>{'None'};
         rtNameSet.addAll(recByRtNameMap.keySet());
         ObjectWorkFlow__mdt[] objectFlows = getObjectWorkflows(objectName, rtNameSet);
         if (objectFlows != null) {
            for (ObjectWorkFlow__mdt objectFlow : objectFlows) {
               SObject[] recsByRt = (objectFlow.RecordTypeName__c == 'None' ? recs : recByRtNameMap.get(objectFlow.RecordTypeName__c));
               if (recsByRt != null) {
                  processFieldRules(recsByRt, oldMap, objectFlow, objectName);
               }
            } // for (ObjectWorkFlow__mdt objectFlow
         } // if (objectFlows != null
      } // if (!recByRtNameMap.isEmpty
   } // checkRecsWithRT

   public static String NEW_VALUE_BOOLEAN='Boolean';
   public static String NEW_VALUE_LITERAL='Literal';
   public static String NEW_VALUE_DATE='Date';
   public static String NEW_VALUE_DATETIME='DateTime';
   // pulls the value from another field (api name in NewValue__c) and populates the UpdateFldAPIName__c field.
   public static String NEW_VALUE_FIELDVALUE='FieldValue'; 
   public static String NEW_VAL_USER_NAME='Running User Name';
   public static String NEW_VAL_USER_ID='Running User Id';
   
   public static String RECORD_ACTION_INSERT='Insert'; // always perform this action if it's a new record - no additional conditions
   public static String RECORD_ACTION_CHANGED='IsChanged'; // only perform this action if the check field has a value and it's changed (could be an insert)
   public static String RECORD_ACTION_CONDITION='Condition'; // if there's a condition we need to check for on this field.
   
   public static void processFieldRules(SObject[] recs, Map<Id,SObject> oldMap, ObjectWorkFlow__mdt objectFlow, String objectName) {
      for (SObject rec : recs) {
         SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         // TODO - will there be additional criteria eventually?
         processFieldRules(rec, oldRec, objectFlow.FieldWorkflows__r, objectName);
      }
   } // processFieldRules
   
   public static void processFieldRules(SObject rec, SObject oldRec, FieldWorkflow__mdt[] fieldFlows, String objectName) {
      String[] objectNotes = new String[]{};
      for (FieldWorkflow__mdt fwf : fieldFlows) {
         try {
            if (isConditionMet(fwf,rec,oldRec)) {
               if (fwf.RecordAction__c == RECORD_ACTION_INSERT && oldRec == null) {
                  // for an Insert, there are no additional conditions
                  setFieldValue(rec, fwf, objectNotes);
               } else if (fwf.RecordAction__c == RECORD_ACTION_CHANGED && isValueChanged(fwf,rec,oldRec)) {
                  setFieldValue(rec, fwf, objectNotes);
               }
            } // if (isConditionMet(fwf,rec,oldRec
         } catch (Exception e) {
            objectNotes.add('Exception on field action: '+e.getMessage());
            System.debug('processFieldRules exception '+e.getMessage()+'; '+e.getStackTraceString());
         }
      } // for
      
      addToNotes(rec, objectNotes, objectName);
   } // processFieldRules
   
   public static Boolean isValueChanged(FieldWorkflow__mdt fwf, SObject rec, SObject oldRec) {
      // if it's an insert, then there must be a value
      Boolean isChanged = (oldRec == null && rec.get(fwf.CheckFldAPIName__c) != null);
      Boolean isBoolean = (String.isNotBlank(fwf.CheckFldType__c) && fwf.CheckFldType__c == 'Boolean');

      // not an insert, check against the previous value
      if (!isChanged && oldRec != null) {
         // did the value in the field change?
         isChanged = (rec.get(fwf.CheckFldAPIName__c) != oldRec.get(fwf.CheckFldAPIName__c));
      }
      System.debug('isValueChanged isChanged='+isChanged);
      return isChanged;
   } // isValueChanged
    
   public static String OPP_EQUALS='Equals';
   public static String OPP_STARTS='Starts With';
   public static String OPP_CONTAINS='Contains';
    
   public static String CHK_VALUE='Value';
   // if any change occurs to the field
   public static String CHK_ANY='Any Change';
   // check if the current value in the Check Fld is Null
   public static String CHK_NULL='Null';
   // check if the previous value in the Check Fld was Null
   public static String CHK_PREV_NULL='Previous Null';
   
   public static Boolean isConditionMet(FieldWorkflow__mdt fwf, SObject rec, SObject oldRec) {
      Boolean conditionMet = true;
      Boolean isBoolean = (String.isNotBlank(fwf.CheckFldType__c) && fwf.CheckFldType__c == 'Boolean');
      Boolean isDate = (String.isNotBlank(fwf.CheckFldType__c) && fwf.CheckFldType__c == 'Date');
      String valueChangeType = (String.isBlank(fwf.CheckValueType__c) ? CHK_VALUE : fwf.CheckValueType__c);

      // if there's a check field, we'll always check the condition
      if (String.isNotBlank(fwf.CheckFldAPIName__c)) {
         if (isBoolean) {
            Boolean conditionValue = (String.isNotBlank(fwf.CheckValue__c) && fwf.CheckValue__c == 'True');
            conditionMet = (Boolean)rec.get(fwf.CheckFldAPIName__c) == conditionValue;
         } else if (isDate) {
            // only checking for null value is supported right now
            conditionMet = (valueChangeType == CHK_NULL && rec.get(fwf.CheckFldAPIName__c) == null);
         } else if (valueChangeType == CHK_PREV_NULL) {
            // if the previous value has to be null, account for that. 
            conditionMet = (rec.get(fwf.CheckFldAPIName__c) != null && (oldRec == null || oldRec.get(fwf.CheckFldAPIName__c) == null));
         } else {
            String operation = (String.isBlank(fwf.Operation__c) ? OPP_EQUALS : fwf.Operation__c);
            // if CheckFldAPIName__c is not blank, and CheckValue__c is blank, then look for any change to the field.
            // If CheckFldAPIName__c is not blank, and CheckValue__c is not blank, then look to see if the view changed to CheckValue__c based on the operation
            // If the operation is Equals, CheckValue__c has to equal the value in the field.
            // If the operation is Starts With, see if the new value starts with CheckValue__c
            // If the operation is Contains, see if the new value has the value in CheckValue__c
            // if both are blank, then equal, or both non blank and meet the operation condition
            String recValue = (String)rec.get(fwf.CheckFldAPIName__c);
            //conditionMet = ((prevValueCheck && String.isBlank(fwf.CheckValue__c))  // if checkValue__c is blank, then any change from null works
            //                   || (prevValueCheck && fwf.CheckValue__c == recValue)  // if checkValue is not blank, make sure it changed to that value
            conditionMet = ((String.isBlank(fwf.CheckValue__c) && String.isBlank(recValue))
                               || (valueChangeType == CHK_NULL && String.isBlank(recValue))
                               || (valueChangeType == CHK_ANY)
                               || (String.isNotBlank(recValue) && String.isNotBlank(fwf.CheckValue__c)
                                                     && ((operation == OPP_EQUALS && recValue == fwf.CheckValue__c)
                                                         || (operation == OPP_STARTS && recValue.startsWith(fwf.CheckValue__c))
                                                         || (operation == OPP_CONTAINS && recValue.contains(fwf.CheckValue__c)))));
            System.debug('isConditionMet operation='+operation+' conditionMet='+conditionMet);
            //conditionMet = ((String.isBlank(fwf.CheckValue__c) && rec.get(fwf.CheckFldAPIName__c) != null)
            //              || (String.isNotBlank(fwf.CheckValue__c) && (String)rec.get(fwf.CheckFldAPIName__c) == fwf.CheckValue__c));
         }
      } // if (String.isNotBlank
      // check if we're only updating a blank field
      conditionMet = conditionMet && (!fwf.OnlyIfBlank__c 
                                       || (fwf.OnlyIfBlank__c && fwf.UpdateFldAPIName__c != null && rec.get(fwf.UpdateFldAPIName__c) == null));
      System.debug('isConditionMet conditionMet='+conditionMet+' field='+fwf.CheckFldAPIName__c+' value='+fwf.CheckValue__c+' onlyIfBlank='+fwf.OnlyIfBlank__c+' recValue='+(fwf.CheckFldAPIName__c != null ? rec.get(fwf.CheckFldAPIName__c) : 'null'));
      return conditionMet;
   } // isConditionMet
   
   // for testing purposes
   public static String literalValueOverride = null;
    
   public static void setFieldValue(SObject rec, FieldWorkflow__mdt fwf, String[] objectNotes) {
       
      if (fwf.NewValueType__c == NEW_VALUE_BOOLEAN) {
         Boolean newValue = (String.isNotBlank(fwf.NewValue__c) && fwf.NewValue__c == 'True');
         rec.put(fwf.UpdateFldAPIName__c, newValue);
         objectNotes.add(fwf.Label+' updated '+fwf.UpdateFldAPIName__c+' to '+newValue);
      } else if (fwf.NewValueType__c == NEW_VALUE_LITERAL) {
         String newValue = (String.isNotBlank(literalValueOverride) ? literalValueOverride : fwf.NewValue__c);
         rec.put(fwf.UpdateFldAPIName__c, newValue);
         objectNotes.add(fwf.Label+' updated '+fwf.UpdateFldAPIName__c+' to '+newValue);
      } else if (fwf.NewValueType__c == NEW_VALUE_FIELDVALUE) {
         rec.put(fwf.UpdateFldAPIName__c, rec.get(fwf.NewValue__c));
         objectNotes.add((fwf.Label+' updated '+fwf.UpdateFldAPIName__c+' with value from '+fwf.NewValue__c+'('+(String)rec.get(fwf.NewValue__c)+')'));
      } else if (fwf.NewValueType__c == NEW_VALUE_DATE) {
         rec.put(fwf.UpdateFldAPIName__c, Date.today());
         objectNotes.add(fwf.Label+' updated '+fwf.UpdateFldAPIName__c+' with Date.today');
      } else if (fwf.NewValueType__c == NEW_VALUE_DATETIME) {
         rec.put(fwf.UpdateFldAPIName__c, DateTime.now());
         objectNotes.add(fwf.Label+' updated '+fwf.UpdateFldAPIName__c+' with DateTime.now');
      } else if (fwf.NewValueType__c == NEW_VAL_USER_NAME) {
         rec.put(fwf.UpdateFldAPIName__c, UserInfo.getName());
         objectNotes.add(fwf.Label+' updated '+fwf.UpdateFldAPIName__c+' with '+UserInfo.getName());
      } else if (fwf.NewValueType__c == NEW_VAL_USER_ID) {
         rec.put(fwf.UpdateFldAPIName__c, UserInfo.getUserId());
         objectNotes.add(fwf.Label+' updated '+fwf.UpdateFldAPIName__c+' with '+UserInfo.getUserId());
      } // if (fwf.NewValueType__c
   } // setFieldValue
   
   // for testing only - so we can set up tests and not worry if they're active or not
   public static String TEST_SCENARIO='NoTest';
      
   public static ObjectWorkFlow__mdt[] getObjectWorkflows(String objectName, Set<String> recordTypeNameset) {
      ObjectWorkFlow__mdt[] objectFlows = null;
      if (TEST_SCENARIO == 'NoTest') {
         objectFlows = [Select Id, ObjectAPIName__c, RecordTypeName__c, TestScenario__c
                                                ,(Select Id, Label
                                                        ,CheckFldAPIName__c
                                                        ,CheckFldType__c
                                                        ,CheckValue__c
                                                        ,CheckValueType__c
                                                        ,NewValue__c
                                                        ,NewValueType__c
                                                        ,OnlyIfBlank__c
                                                        ,Operation__c
                                                        ,RecordAction__c
                                                        ,UpdateFldAPIName__c
                                                    From FieldWorkflows__r
                                                   Where IsActive__c=true)
                                             From ObjectWorkFlow__mdt
                                            Where IsActive__c=true 
                                              and ObjectAPIName__c = :objectname
                                              and RecordTypeName__c in :recordTypeNameset];
      } else {
         objectFlows = [Select Id, ObjectAPIName__c, RecordTypeName__c
                                                ,(Select Id, Label
                                                        ,CheckFldAPIName__c
                                                        ,CheckFldType__c
                                                        ,CheckValue__c
                                                        ,CheckValueType__c
                                                        ,NewValue__c
                                                        ,NewValueType__c
                                                        ,OnlyIfBlank__c
                                                        ,Operation__c
                                                        ,RecordAction__c
                                                        ,UpdateFldAPIName__c
                                                    From FieldWorkflows__r
                                                   Where IsActive__c=true)
                                             From ObjectWorkFlow__mdt
                                            Where TestScenario__c = :TEST_SCENARIO
                                              and ObjectAPIName__c = :objectname
                                              and RecordTypeName__c in :recordTypeNameset];
      }

      System.debug('getObjectWorkflows recordTypeNameset='+recordTypeNameset.size()+' objectFlows='+objectFlows.size());
      return objectFlows;
   } // getObjectWorkflows
   
   public static void addToNotes(SObject obj, String[] notesToAdd, String objectName) {
      if (!notesToAdd.isEmpty()) {
         String compiledNotes = notesToAdd[0];
         for (Integer cnt=1; cnt<notesToAdd.size(); cnt++) {
            compiledNotes += '\n '+notesToAdd[cnt];
         }
         StringHelper.addToProcessNotes(obj,compiledNotes);
      } // if (!notesToAdd.isEmpty
   } // addToNotes
   
} // class WorkflowHelper