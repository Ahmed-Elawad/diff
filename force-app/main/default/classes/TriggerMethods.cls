/* Methods called by the triggers to see what they need to execute.

  History
  -------
  01/09/2017 Dan Carmen        Created
  02/08/2017 Dan Carmen        Added ability to store data in the cache.
  04/13/2018 Dan Carmen        Update didTriggerRun method. Added a reset for triggerExecutedSet if running tests.
  04/20/2018 Dan Carmen        Added runTrigger method to be able to prevent recursion by id.
  04/19/2019 Dan Carmen        Modified code to handle just in case more than 1 has the same sort order number.
  09/05/2019 Dan Carmen        Change for didTriggerRun method
  11/05/2019 Dan Carmen        Add ability to skip triggers
  11/15/2019 Dan Carmen        Added TriggerInterfaceC
  01/30/2020 Dan Carmen        Functionality for delete
  07/01/2020 Dan Carmen        Remove the need for the "InterfaceVersion__c" field
  10/14/2020 Dan Carmen        Fix checkRecs for delete
  12/15/2021 Dan Carmen        Disable steelbrick triggers
  08/01/2022 Dan Carmen        Add in SKIP_TRIGGERS logic to runTrigger
  09/26/2023 Dan Carmen        Remove DupeBlocker code
    
 */
public with sharing class TriggerMethods {
   
   // TODO - these need to be removed
   public static String INTERFACE_A='A';
   public static String INTERFACE_B='B';
   public static String INTERFACE_C='C';

   public static void disablePackageTriggers() {
   }
   
   public static void enablePackageTriggers() {
   }

   // this is mainly for testing purposes so we can call classes again and have the triggers fire.
   public static void clearVariables() {
      triggerExecutedSet.clear();
      triggerExecutedMap.clear();
      skipObjectTriggerSet.clear();
      SKIP_TRIGGERS=false;
   } // clearVariables
      
   public static Set<String> triggerExecutedSet = new Set<String>();
   // TODO - be able to provide a set of objects we would skip the triggers on.
   public static Set<String> skipObjectTriggerSet = new Set<String>();
   public static final String BEFORE='Before';
   public static final String AFTER='After';
   public static final String DELETEBEFORE='DeleteBefore';
   public static final String DELETEAFTER='DeleteAfter';
   
   // so this won't break tests that were coded before this functionality.
   public static Boolean TEST_MODE=Test.IsRunningTest();

   // store the ids that have already executed the trigger
   // the assumption for this code is that there is only going to be one update and one insert trigger utilizing
   // this code per object.
   public static Set<Id> recIdsExecutedSet = new Set<Id>();

   // check if it's okay to run the trigger.
   public static Boolean runTrigger(String objectApiName, Boolean isInsert, Boolean isUpdate, Boolean isBefore, Boolean isAfter, SObject[] recs) {
      
      // always run on before and insert - so do nothing for that case - there are no ids at this point
      // if the set is empty, we will run the trigger.
      Boolean okayToRun = (!SKIP_TRIGGERS && ((isBefore && isInsert) || recIdsExecutedSet.isEmpty()));

      // for all other cases the ids should exist, so check the ids to see if they exist in the set
      if (!okayToRun && recs != null && !recIdsExecutedSet.isEmpty()) {
         Boolean allRecordsProcessed = true;
         for (SObject so : recs) {
            if (!recIdsExecutedSet.contains(so.Id)) {
               // once we find 1 record not in the set, we will execute the trigger.
               allRecordsProcessed = false;
               break;
            }
         } // for (SObject so
         okayToRun = !allRecordsProcessed;
      }
      // if we're in the after trigger, make sure all ids are added to the set so we won't trigger the records again.
      if (!TEST_MODE && isAfter && recs != null) {
         for (SObject so : recs) {
            recIdsExecutedSet.add(so.Id);
         }
      }
      return okayToRun;
   } // runTrigger
   
   // this should be temporary - just to make sure things are working and to be able to easily switch off if needed.
   public static Boolean DISABLE_CHECKRECS=(Label.TriggerMethods_DisableCheckRecs == 'Y');
   public static Boolean SKIP_TRIGGERS=false;
   
   public static void addSkipName(String valueToSkip) {
      skipObjectTriggerSet.add(valueToSkip);
   } // addSkipName
   
   public static void clearSkipNames() {
      skipObjectTriggerSet.clear();
   } // clearSkipNames
   
   // do we want to be able to force a trigger to run again even if it already ran?
   public static Set<String> forceTriggerSet = new Set<String>();
   
   public static Map<String,Set<Id>> triggerExecutedMap = new Map<String,Set<Id>>();

   public static SObject[] checkRecs(String triggerName, SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, String beforeTriggerName, Schema.FieldSet fldsChangedSet) {
      return checkRecs(triggerName, recs, oldMap, isBefore, isAfter, Trigger.isDelete, beforeTriggerName, fldsChangedSet);
   } // checkRecs
   // beforeTriggerName is because we don't have ids in a before insert so we can't add those records for recursion check at that time.
   // but in the after we can add those ids to the set to prevent an update in the before trigger.
   // fldsChangedSet - if there are any particular fields that could change where we'd still want to execute the trigger 
   public static SObject[] checkRecs(String triggerName, SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete, String beforeTriggerName, Schema.FieldSet fldsChangedSet) {
      System.debug('checkRecs entry triggerName='+triggerName+' recs='+(recs != null ? recs.size() : -1)+' SKIP_TRIGGERS='+SKIP_TRIGGERS+' DISABLE_CHECKRECS='+DISABLE_CHECKRECS);
      if (SKIP_TRIGGERS || skipObjectTriggerSet.contains(triggerName)) {
         return new SObject[]{};
      }
      if (DISABLE_CHECKRECS || forceTriggerSet.contains(triggerName)) {
         return recs;
      }
      objType = null;
      objectTypeName = null;
      if (recs != null && !recs.isEmpty()) {
         objType = recs[0].getSObjectType();
         objectTypeName = objType.getDescribe().getName();
      } else if (isDelete && Trigger.old != null && !Trigger.old.isEmpty()) {
         objType = Trigger.old[0].getSObjectType();
         objectTypeName = objType.getDescribe().getName();
      } 
      SObject[] runRecs = null;
      // if before insert always run
      if (isBefore && oldMap == null) {
         runRecs = recs;
      } else if (isDelete != null && isDelete) {
         // not sure if we need to do anything here. 
         runRecs = Trigger.old;
      } else if (recs != null && !recs.isEmpty()) {
         String triggerKey = getKey(triggerName, recs[0], isBefore, isAfter, isDelete);
         Set<Id> runIdSet = (triggerExecutedMap.containsKey(triggerKey) ? triggerExecutedMap.get(triggerKey) : new Set<Id>());
         if (runIdSet.isEmpty()) {
            // if no ids previously ran we can just run all the records and all of the records for recursion.
            runRecs = recs;
            Map<Id,SObject> objMap = new Map<Id,SObject>(recs);
            runIdSet.addAll(objMap.keySet());
         } else {
            // check to see if any of the records ran. Only return the ones that are not in the set
            runRecs = new SObject[]{};
            for (SObject rec : recs) {
               if (!runIdSet.contains(rec.Id)) {
                  runRecs.add(rec);
                  runIdSet.add(rec.Id);
               } else if (fldsChangedSet != null) {
                  SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
                  if (oldRec != null) {
                     // this would allow us to define something like the converted field on a lead to always go through the trigger
                     if (checkForFldChange(rec,oldRec,fldsChangedSet)) {
                        runRecs.add(rec);
                        runIdSet.add(rec.Id);
                     }
                  }
               }
            } // for (SObject rec : recs
         }
         triggerExecutedMap.put(triggerKey, runIdSet);
         if (String.isNotBlank(beforeTriggerName)) {
            String triggerKey2 = getKey(beforeTriggerName, recs[0], true, false,false);
            triggerExecutedMap.put(triggerKey2, runIdSet);
         }
         
      } // if (Trigger.IsBefore
      System.debug('checkRecs exit triggerName='+triggerName+' objectTypeName='+objectTypeName+' recs='+(recs != null ? recs.size() : -1)+' runRecs='+(runRecs != null ? runRecs.size() : -1));
      return runRecs;
   } // checkRecs
   
   public static Boolean checkForFldChange(SObject rec, SObject oldRec, Schema.FieldSet fldSet) {
      Boolean changed = (oldRec == null);
      if (oldRec != null) {
         for (Schema.FieldSetMember fsm : fldSet.getFields()) {
            String fldName = fsm.getFieldPath();
            if (rec.get(fldName) != oldRec.get(fldName)) {
               System.debug('checkForFldChange value changed for '+fldName);
               changed = true;
               break;
            }
         } // for (Schema.FieldSetMember
      } // if (oldRec != null
      System.debug('checkForFldChange changed='+changed);
      return changed;
   } // checkForFldChange

   public static Boolean didTriggerRun(String triggerName, SObject[] recs, Boolean isBefore, Boolean isAfter) {
      return didTriggerRun(triggerName, recs, (Map<Id,SObject>)null, isBefore, isAfter, Trigger.isDelete);
   }

   // see if the trigger type already executed - so to ensure it only runs once during a transaction.
   public static Boolean didTriggerRun(String triggerName, SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      Boolean alreadyRan = false;
      objType = null;
      objectTypeName = null;
      if (SKIP_TRIGGERS || skipObjectTriggerSet.contains(triggerName)) {
         return true;
      }
      
      if (forceTriggerSet.contains(triggerName)) {
         return false;
      }

      
      SObject[] checkRecs = (recs != null && !recs.isEmpty() ? recs : (isDelete && Trigger.old != null ? Trigger.old : null));

      if (checkRecs != null && !checkRecs.isEmpty()) {
         // used to store in the map
         String triggerKey = getKey(triggerName, checkRecs[0], isBefore, isAfter, isDelete);
      
         if (!alreadyRan && String.isNotBlank(triggerKey)) {
            alreadyRan = triggerExecutedSet.contains(triggerKey);
            triggerExecutedSet.add(triggerKey);
         }
      }
      System.debug('didTriggerRun triggerName='+triggerName+' objectTypeName='+objectTypeName+' alreadyRan='+alreadyRan+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete+' checkRecs='+(checkRecs != null ? checkRecs.size() : -1));
      return alreadyRan;
   } // didTriggerRun
   
   // static public variables so we can reference them elsewhere if needed
   public static SObjectType objType=null;
   public static String objectTypeName=null;
   
   // generate a key based on the passed in values
   public static String getKey(String triggerName, SObject rec, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      String triggerType = '';
      if (isDelete != null && isDelete) {
          triggerType = (isBefore ? DELETEBEFORE : (isAfter ? DELETEAFTER : ''));
      } else {
          triggerType = (isBefore ? BEFORE : (isAfter ? AFTER : ''));
      }
      if (objType == null) {
         objType = rec.getSObjectType();
         objectTypeName = objType.getDescribe().getName();
      }
      
      // used to store in the map
      String triggerKey = null;
      if (String.isNotBlank(triggerType)) {
         triggerKey = triggerName+objectTypeName+triggerType;
      }
      System.debug('getKey triggerKey='+triggerKey);
      return triggerKey;
   } // getKey
   
   public static void handleTrigger(String triggerName, SObject[] recs, Map<Id,SObject> oldMap, Schema.FieldSet fldsChangedSet) {
      SObject[] checkRecs = (!Trigger.isDelete ? checkRecs(triggerName, recs, oldMap, Trigger.IsBefore, Trigger.IsAfter, triggerName, fldsChangedSet) : Trigger.old);
      if (checkRecs != null && !checkRecs.isEmpty()) {
         checkBeforeLoop(triggerName, checkRecs, oldMap, Trigger.IsBefore, Trigger.IsAfter);
      }  
   } // handleTrigger
   
   // If you only want to run certain classes in a transaction, set them here. 
   public static Set<String> onlyRunTheseClasses = new Set<String>();
      
   // do we check records before entering the loop for all of the rest of the records?
   public static void checkBeforeLoop(String triggerName, SObject[] recs, Map<Id,SObject> oldMap
                                  ,Boolean isBefore, Boolean isAfter) {
      ClassNameWrapper[] classNames = getClassNames2(triggerName, isBefore, isAfter, Trigger.isDelete);
      if (classNames != null && !classNames.isEmpty()) {
         for (ClassNameWrapper className : classNames) {
            if (onlyRunTheseClasses.isEmpty() || onlyRunTheseClasses.contains(className.tsc.ClassName__c)) {
               try {
                  Type t = Type.forName(className.tsc.ClassName__c);
                  if (TriggerInterfaceC.class.isAssignableFrom(t)) {
                     TriggerInterfaceC trigInstance = (TriggerInterfaceC)t.newInstance();
                     System.debug('checkBeforeLoop '+triggerName+' TriggerInterfaceC instance found for '+className.tsc.ClassName__c);
                     trigInstance.handleTrigger(recs, oldMap, isBefore, isAfter, Trigger.isDelete);
                  } else if (TriggerInterface2.class.isAssignableFrom(t)) {
                     TriggerInterface2 trigInstance = (TriggerInterface2)t.newInstance();
                     System.debug('checkBeforeLoop '+triggerName+' TriggerInterface2 instance found for '+className.tsc.ClassName__c);
                     trigInstance.triggerCheckAllFirst(recs, oldMap, isBefore, isAfter);
                  } else if (TriggerInterface.class.isAssignableFrom(t)) {
                     TriggerInterface trigInstance = (TriggerInterface)t.newInstance();
                     System.debug('checkBeforeLoop '+triggerName+' instance found for '+className.tsc.ClassName__c);
                     if (isBefore) {
                        trigInstance.checkAllBeforeTrigger(recs, oldMap);
                     } else if (isAfter) {
                        trigInstance.checkAllAfterTrigger(recs, oldMap);
                     }
                  }
               } catch (Exception e) {
                  System.debug('TriggerMethods checkBeforeLoop className='+className.tsc.ClassName__c+' Exception: '+e.getMessage()+'; '+e.getStackTraceString());
               }
            } // if (onlyRunTheseClasses.isEmpty() || onlyRunTheseClasses.contains(classNam
         } // for (String className
      } // if (classNames != null
   } // checkBeforeLoop
   
   // so we only loop through the records once (for the check) this is called from within a loop
   // of all of the objects.
   public static void checkInLoop(String triggerName, SObject newRec, SObject oldRec
                                  ,Boolean isBefore, Boolean isAfter) {
      ClassNameWrapper[] classNames = getClassNames2(triggerName, isBefore, isAfter, false);
      if (classNames != null && !classNames.isEmpty()) {
         for (ClassNameWrapper className : classNames) {
            if (onlyRunTheseClasses.isEmpty() || onlyRunTheseClasses.contains(className.tsc.ClassName__c)) {
               try {
                  Type t = Type.forName(className.tsc.ClassName__c);
                  if (TriggerInterface2.class.isAssignableFrom(t)) {
                     TriggerInterface2 trigInstance = (TriggerInterface2)t.newInstance();
                     System.debug('checkInLoop '+triggerName+' Interface B instance found for '+className.tsc.ClassName__c);
                     trigInstance.triggerCheckRec(newRec, oldRec, isBefore, isAfter);
                  } else if (TriggerInterface.class.isAssignableFrom(t)) {
                     TriggerInterface trigInstance = (TriggerInterface)t.newInstance();
                     System.debug('checkInLoop '+triggerName+' instance found for '+className.tsc.ClassName__c);
                     if (isBefore) {
                        trigInstance.checkBeforeTrigger(newRec, oldRec);
                     } else if (isAfter) {
                        trigInstance.checkAfterTrigger(newRec, oldRec);
                     }
                  }
               } catch (Exception e) {
                  System.debug('TriggerMethods checkInLoop className='+className.tsc.ClassName__c+' Exception: '+e.getMessage()+'; '+e.getStackTraceString());
               }
            } // if (onlyRunTheseClasses.isEmpty() || onlyRunTheseClasses.contains(className.tsc.ClassName__c)) {
            
         } // for (String className
      } // if (classNames != null
   } // checkInLoop
   
   public static void checkOutsideLoop(String triggerName, Boolean isBefore, Boolean isAfter) {
      ClassNameWrapper[] classNames = getClassNames2(triggerName, isBefore, isAfter, false);
      if (classNames != null && !classNames.isEmpty()) {
         for (ClassNameWrapper className : classNames) {
            if (onlyRunTheseClasses.isEmpty() || onlyRunTheseClasses.contains(className.tsc.ClassName__c)) {
               try {
                  Type t = Type.forName(className.tsc.ClassName__c);
                  if (TriggerInterface2.class.isAssignableFrom(t)) {
                     TriggerInterface2 trigInstance = (TriggerInterface2)t.newInstance();
                     System.debug('checkOutsideLoop '+triggerName+' TriggerInterface2 instance found for '+className.tsc.ClassName__c);
                     trigInstance.triggerCheckActions(isBefore, isAfter);
                  } else if (TriggerInterface.class.isAssignableFrom(t)) {
                     TriggerInterface trigInstance = (TriggerInterface)t.newInstance();
                     System.debug('checkOutsideLoop '+triggerName+' instance found for '+className.tsc.ClassName__c);
                     if (isBefore) {
                        trigInstance.processBeforeTriggerActions();
                     } else if (isAfter) {
                        trigInstance.processAfterTriggerActions();
                     }
                  }
               } catch (Exception e) {
                  System.debug('TriggerMethods checkOutsideLoop className='+className.tsc.ClassName__c+' Exception: '+e.getMessage()+'; '+e.getStackTraceString());
               }
            } // if (onlyRunTheseClasses.isEmpty() || onlyRunTheseClasses.contains(className.tsc.ClassName__c)) {
             
         } // for (String className
      } // if (classNames != null
      if (Test.isRunningTest() && isAfter) {
         // reset this so we don't break all of the other tests.
         triggerExecutedSet.clear(); 
      }
   } // checkOutsideLoop
   
   public static final String CACHE_KEY = 'TriggerMethodsClassesByKeyMap';
   
   public static Map<String,ClassNameWrapper[]> getClassKeyMap() {
      //System.debug('ClassKeyMap building map');
      Map<String,ClassNameWrapper[]> keyMap = new Map<String,ClassNameWrapper[]>();
      // used so we can separate, then sort the keys
      Map<String, Map<Integer, ClassNameWrapper[]>> allSortMap = new Map<String, Map<Integer, ClassNameWrapper[]>>();
      for (TriggerSetupClasses__c trigSetupClass : TriggerSetupClasses__c.getAll().values()) {
         checkAddMap(trigSetupClass, trigSetupClass.IsBefore__c, BEFORE, allSortMap);
         checkAddMap(trigSetupClass, trigSetupClass.IsAfter__c, AFTER, allSortMap);
         checkAddMap(trigSetupClass, trigSetupClass.IsDeleteBefore__c, DELETEBEFORE, allSortMap);
         checkAddMap(trigSetupClass, trigSetupClass.IsDeleteAfter__c, DELETEAFTER, allSortMap);
      } // for (TriggerSetupClasses__c
           
      // sort the map
      for (String triggerKey : allSortMap.keySet()) {
         Map<Integer, ClassNameWrapper[]> sortMap = allSortMap.get(triggerKey);
         Integer[] classSortList = new Integer[]{};
         classSortList.addAll(sortMap.keySet());
         // sort the list in numerical order
         classSortList.sort();
         ClassNameWrapper[] classList = new ClassNameWrapper[]{};
         // add to the list in the correct order
         for (Integer classNbr : classSortList) {
            classList.addAll(sortMap.get(classNbr));
         }
         System.debug('ClassKeyMap triggerKey='+triggerKey+' classList='+classList.size());
         keyMap.put(triggerKey, classList);
      } // for (String triggerKey
      System.debug('ClassKeyMap keyMap='+keyMap.size());
      CacheManager.putOrg(CACHE_KEY, keyMap);
      return keyMap;
   } // getClassKeyMap

   public static void checkAddMap(TriggerSetupClasses__c trigSetupClass, Boolean checkValue, String valueForKey, Map<String, Map<Integer, ClassNameWrapper[]>> allSortMap) {
      if (trigSetupClass.Active__c && checkValue) {
         String key=trigSetupClass.TriggerKey__c + valueForKey;
         Map<Integer,ClassNameWrapper[]> sortMap = allSortMap.containsKey(key) ? allSortMap.get(key) : new Map<Integer, ClassNameWrapper[]>();
         Integer sortOrder = Integer.valueOf(trigSetupClass.SortOrder__c);
         ClassNameWrapper[] wrappers = (sortMap.containsKey(sortOrder) ? sortMap.get(sortOrder) : new ClassNameWrapper[]{});
         wrappers.add(new ClassNameWrapper(trigSetupClass));
         sortMap.put(sortOrder, wrappers);
         allSortMap.put(key, sortMap);
      }
   } // checkAddMap

   public static Map<String,ClassNameWrapper[]> classKeyMap = null;

   public static ClassNameWrapper[] getClassNames2(String triggerName, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      if (classKeyMap == null) {
         classKeyMap = (Map<String,ClassNameWrapper[]>)CacheManager.getOrg(CACHE_KEY);
         if (classKeyMap == null) {
            classKeyMap = getClassKeyMap();
         }
      }
      
      //Map<String,String[]> keyMap = (Map<String,String[]>)Cache.Org.get(ClassKeyMap.class, CACHE_KEY);
      String key = '';
      if (isDelete != null && isDelete) {
         key = triggerName+ (isBefore ? DELETEBEFORE : (isAfter ? DELETEAFTER : ''));
      } else {
         key = triggerName + (isBefore ? BEFORE : (isAfter ? AFTER : ''));
      }
      ClassNameWrapper[] classNames = (classKeyMap != null && classKeyMap.containsKey(key) ? classKeyMap.get(key) : new ClassNameWrapper[]{});
      System.debug('getClassNames2 key='+key+' classNames='+classNames.size());
      return classNames;
   } // getClassNames
   
   public class ClassNameWrapper {
      public ClassNameWrapper(TriggerSetupClasses__c p_tsc) {
         tsc = p_tsc;
      }
      public TriggerSetupClasses__c tsc;
   } // class ClassNameWrapper
   
} // class TriggerMethods