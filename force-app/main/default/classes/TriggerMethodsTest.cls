/* Test methods for TriggerMethods

  History
  -------
  01/09/2017 Dan Carmen        Created
  04/13/2018 Dan Carmen        Update didTriggerRun method. Added a reset for triggerExecutedSet if running tests.
  04/20/2018 Dan Carmen        Added runTrigger method to be able to prevent recursion by id.
  05/21/2018 Dan Carmen        Modify createCustomSetting to remove the TriggerSetup__c parameter.
  09/05/2019 Dan Carmen        Change for didTriggerRun method
  01/30/2020 Dan Carmen        Functionality for delete
  07/01/2020 Dan Carmen        Remove the need for the "IntefaceVersion__c" field
  12/15/2021 Dan Carmen        Disable steelbrick triggers
  08/01/2022 Dan Carmen        Add in SKIP_TRIGGERS logic to runTrigger
  09/26/2023 Dan Carmen        Remove DupeBlocker code
  
 */
@isTest
public class TriggerMethodsTest {
   
   public static void resetTriggers() {
      TriggerMethods.triggerExecutedSet.clear();
   }
   
   // deprecated - start using createTriggerSetting
   public static TriggerSetup__c createCustomSetting(TriggerSetup__c trigSetup, String triggerName, Boolean isBefore, Boolean isAfter, String[] classNames, TriggerSetupClasses__c[] classes) {
      createTriggerSetting(triggerName, isBefore, isAfter, false, false, classNames, classes, null);
      return null;
   } // createCustomSetting

   // deprecated - start using createTriggerSetting
   public static TriggerSetup__c createCustomSetting(TriggerSetup__c trigSetup, String triggerName, Boolean isBefore, Boolean isAfter, String[] classNames, TriggerSetupClasses__c[] classes, String interfaceVersion) {
      createTriggerSetting(triggerName, isBefore, isAfter, false, false, classNames, classes, interfaceVersion);
      return null;
   }
   
   // deprecated - start using createTriggerSetting
   public static TriggerSetup__c createCustomSetting(String triggerName, Boolean isBefore, Boolean isAfter, String[] classNames, TriggerSetupClasses__c[] classes, String interfaceVersion) {
      createTriggerSetting(triggerName, isBefore, isAfter, false, false, classNames, classes, interfaceVersion);
      return null;
   } // createCustomSetting
   
   // deprecated - start using createTriggerSetting
   public static void createTriggerSetting(String triggerName, Boolean isBefore, Boolean isAfter, String[] classNames, TriggerSetupClasses__c[] classes, String interfaceVersion) {
      createTriggerSetting(triggerName, isBefore, isAfter, false, false, classNames, classes, interfaceVersion);
   } // createTriggerSetting  
    
   public static TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};

   // moving away from this method
   public static void createTriggerSetting(String triggerName, Boolean isBefore, Boolean isAfter, Boolean isDeleteBefore, Boolean isDeleteAfter, String[] classNames, TriggerSetupClasses__c[] classes, String interfaceVersion) {
      setupClasses.clear();
      createTriggerSetting(triggerName, isBefore, isAfter, isDeleteBefore, isDeleteAfter, classNames);
      classes.addAll(setupClasses);
   } // createTriggerSetting
       
   public static Integer NAME_SIZE = TriggerSetupClasses__c.Name.getDescribe().getLength();

   public static void createTriggerSetting(String triggerName, Boolean isBefore, Boolean isAfter, Boolean isDeleteBefore, Boolean isDeleteAfter, String[] classNames) {
      if (classNames != null) {
         for (String className : classNames) {
            // to get a unique name
            String recName = (triggerName+className).left(NAME_SIZE);
            setupClasses.add(new TriggerSetupClasses__c(Name=recName,TriggerKey__c=triggerName, SortOrder__c=setupClasses.size(), Active__c=true, ClassName__c=className
                                                   ,IsAfter__c=isAfter, IsBefore__c=isBefore, IsDeleteBefore__c=isDeleteBefore, IsDeleteAfter__c=isDeleteAfter));
         }
      } // if (classNames != null
   } // createTriggerSetting
    
   public static void saveSetupClasses() {
      if (!setupClasses.isEmpty()) {
          upsert setupClasses;
          setupClasses.clear();
      }
   } // saveSetupClasses
   
   public class Face1 implements TriggerInterface {
      public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {}
      public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {}
      public void checkBeforeTrigger(SObject newRec, SObject oldRec) {}
      public void processBeforeTriggerActions() {}   
      public void checkAfterTrigger(SObject newRec, SObject oldRec) {}
      public void processAfterTriggerActions() {}
   } // Interface1Class
    
   public class Face2 implements TriggerInterface2 {
      // check all of the records as a group before cycling through them individually
      public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {}
      // check each record individually
      public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
      // see if there are any actions that need to take place at the end of the trigger.
      public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}
   } // class Interface2Class
   
   public class Face3 implements TriggerInterfaceC {
      // check all of the records as a group before cycling through them individually
      public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {}

   } // class Interface2Class
   

   static testMethod void checkDidRun() {
      Account acct = new Account(Name='Test Account');
      Account[] accts = new Account[]{acct};
      
      System.assertEquals(false,TriggerMethods.didTriggerRun('TestTrigger', accts, true, false));        
      System.assertEquals(true,TriggerMethods.didTriggerRun('TestTrigger', accts, true, false));        

      System.assertEquals(false,TriggerMethods.didTriggerRun('TestTrigger', accts, false, true));        
      System.assertEquals(true,TriggerMethods.didTriggerRun('TestTrigger', accts, false, true));        

      System.assertEquals(false,TriggerMethods.didTriggerRun('TestTrigger', accts, false, false));        
      System.assertEquals(false,TriggerMethods.didTriggerRun('TestTrigger', accts, false, false));        
   } // checkDidRun
   
   static testMethod void testGetClassNames() {
      createTriggerSetting('TestTrigger', true, true, false, false, new String[]{'ChatterMessageSend'});
      createTriggerSetting('TestTrigger', true, false, false, false, new String[]{'TestClassName1'});
      createTriggerSetting('TestTrigger', false, true, false, false, new String[]{'TestClassName2'});
      saveSetupClasses();
       
      TriggerMethods.ClassNameWrapper[] classes = TriggerMethods.getClassNames2('badTriggerName',false,true,false);
      System.assertEquals(0, classes.size());
      
      classes = TriggerMethods.getClassNames2('TestTrigger',false,true,false);
      System.assertEquals(2, classes.size());
      System.assertEquals('ChatterMessageSend', classes[0].tsc.ClassName__c);
      System.assertEquals('TestClassName2', classes[1].tsc.ClassName__c);
      
      classes = TriggerMethods.getClassNames2('TestTrigger2',true,false,false);
   } // testGetClassNames
   
   static testMethod void testExecutionMultipleClasses() {
      createTriggerSetting('AccountBefore', true, false, false, false, new String[]{'TriggerMethodsTest.Face1','TriggerMethodsTest.Face2','TriggerMethodsTest.Face3'});
      createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'TriggerMethodsTest.Face1','TriggerMethodsTest.Face2','TriggerMethodsTest.Face3'});
      saveSetupClasses();
      
      Account acct = new Account(Name='Test Name');
      insert acct;
      
      TriggerMethods.checkInLoop('AccountBefore', acct, null ,true, false);
      TriggerMethods.checkOutsideLoop('AccountBefore', true, false);
      
      TriggerMethods.checkInLoop('AccountBefore', acct, null ,false, true);
      TriggerMethods.checkOutsideLoop('AccountBefore', false, true);
   } // testExecutionMultipleClasses
   
   static testMethod void testExecutionOneClass() {
      createTriggerSetting('TestTrigger', true, true, false, false, new String[]{'ChatterMessageSend'});
      saveSetupClasses();
      
      Account acct = new Account(Name='Test Name');
      insert acct;
      
      TriggerMethods.checkInLoop('TestTrigger', acct, null ,true, false);
      TriggerMethods.checkOutsideLoop('TestTrigger', true, false);
      
      TriggerMethods.checkInLoop('TestTrigger', acct, null ,false, true);
      TriggerMethods.checkOutsideLoop('TestTrigger', false, true);
   } // testExecutionOneClass
   
   static testMethod void testMisc() {
      TriggerMethods.disablePackageTriggers();
      TriggerMethods.enablePackageTriggers();
      TriggerMethods.clearVariables();
      TriggerMethods.addSkipName('NameToSkip');
      System.assertEquals(true, TriggerMethods.skipObjectTriggerSet.contains('NameToSkip'));
      TriggerMethods.clearSkipNames();
      System.assertEquals(true, TriggerMethods.skipObjectTriggerSet.isEmpty());

   } // testMisc

   static testMethod void testRunTrigger() {
      Lead ld1 = new Lead(Company='Company1', LastName='Last1');
      Lead ld2 = new Lead(Company='Company2', LastName='Last2');
      Lead[] lds = new Lead[]{ld1,ld2};
      insert lds;
      
      // so the triggers will function as normal.
      TriggerMethods.TEST_MODE = false;
      // make sure this is empty to start
      TriggerMethods.recIdsExecutedSet.clear();

// runTrigger(String objectApiName, Boolean isInsert, Boolean isUpdate, Boolean isBefore, Boolean isAfter, SObject[] recs)
      // the before trigger on an insert
      System.assertEquals(true,TriggerMethods.runTrigger(ObjectHelper.OBJECT_LEAD, true, false, true, false, lds));
      // should not put ids in the set in the before trigger
      System.assertEquals(0,TriggerMethods.recIdsExecutedSet.size() );
      
      // the after trigger on an insert.
      System.assertEquals(true,TriggerMethods.runTrigger(ObjectHelper.OBJECT_LEAD, true, false, false, true, lds));
      // should have added both of the ids into the set
      System.assertEquals(2,TriggerMethods.recIdsExecutedSet.size() );

      // the before trigger on an update
      System.assertEquals(false,TriggerMethods.runTrigger(ObjectHelper.OBJECT_LEAD, false, true, true, false, lds));
      // the after trigger on an update
      System.assertEquals(false,TriggerMethods.runTrigger(ObjectHelper.OBJECT_LEAD, false, true, false, true, lds));

      // new transaction
      TriggerMethods.recIdsExecutedSet.clear();
      // the before trigger on an update
      System.assertEquals(true,TriggerMethods.runTrigger(ObjectHelper.OBJECT_LEAD, false, true, true, false, lds));
      // should not put ids in the set in the before trigger
      System.assertEquals(0,TriggerMethods.recIdsExecutedSet.size() );
      // the after trigger on an update
      System.assertEquals(true,TriggerMethods.runTrigger(ObjectHelper.OBJECT_LEAD, false, true, false, true, lds));
      // should have added both of the ids into the set
      System.assertEquals(2,TriggerMethods.recIdsExecutedSet.size() );
      // try another update in the same transaction, should fail.
      System.assertEquals(false,TriggerMethods.runTrigger(ObjectHelper.OBJECT_LEAD, false, true, true, false, lds));
      
   } // testRunTrigger
   
   
   static testMethod void testTriggerInterface2() {
      createTriggerSetting('TestTrigger', true, true, false, false, new String[]{'TriggerMethodsTest.Face2'});
      saveSetupClasses();
      
      Lead ld1 = new Lead(Company='Company1', LastName='Last1');
      Lead ld2 = new Lead(Company='Company2', LastName='Last2');
      Lead[] lds = new Lead[]{ld1,ld2};
      //insert lds;
      
      
      TriggerMethods.checkBeforeLoop('TestTrigger', lds,null, true, false);
      
      Face2 thisTest = new Face2();
      
      
   } // testTriggerInterface2

   static testMethod void testCheckRecs() {
      TriggerMethods.DISABLE_CHECKRECS = false;
      Schema.FieldSet leadAfterFldSet = Schema.SObjectType.Lead.fieldSets.LeadAfterFlds;
      
      Lead ld1 = new Lead(LastName='Lead1',Company='Lead Company1', PostalCode='12345');
      Lead ld2 = new Lead(LastName='Lead2',Company='Lead Company2', PostalCode='12345');
      Lead ld3 = new Lead(LastName='Lead3',Company='Lead Company3', PostalCode='12345');
      Lead ld4 = new Lead(LastName='Lead4',Company='Lead Company4', PostalCode='12345');
      Lead[] lds = new Lead[]{ld1,ld2,ld3,ld4};
      
      SObject[] checkRecs = TriggerMethods.checkRecs('LeadBefore', lds, null, true, false, null, null);
      System.assertEquals(4,checkRecs.size());
      TriggerMethods.DISABLE_CHECKRECS=true;
      // insert so we can get IDs for the leads. Disable the code so that it won't skew the test
      insert lds;
      TriggerMethods.DISABLE_CHECKRECS=false;
      
      checkRecs = TriggerMethods.checkRecs('LeadAfter', lds, null, false, true, 'LeadBefore', leadAfterFldSet);
      System.assertEquals(4,checkRecs.size());

      checkRecs = TriggerMethods.checkRecs('LeadAfter', lds, null, false, true, 'LeadBefore', leadAfterFldSet);
      System.assertEquals(0,checkRecs.size());
      
      //lds = [Select Id, LastName, Company, PostalCode, IsConverted from Lead where Id in :lds];
      ld1 = new Lead(Id=ld1.Id, LastName='Lead1', Company='Lead Company1', PostalCode='12345', IsConverted=false);
      
      Lead ld1a = new Lead(Id=ld1.Id, IsConverted=true);
      Map<Id,Lead> oldMap = new Map<Id,Lead>();
      oldMap.put(ld1a.Id, ld1a);
      oldMap.put(ld2.Id, ld2);
      
      lds = new Lead[]{ld1,ld2};
      checkRecs = TriggerMethods.checkRecs('LeadAfter', lds, oldMap, false, true, 'LeadBefore', leadAfterFldSet);
      System.assertEquals(1,checkRecs.size());
      
      
   } // testCheckRecs
   
   static testMethod void testTriggerInterfaceC() {
      createTriggerSetting('TestTrigger', true, true, false, false, new String[]{'TriggerMethodsTest.Face3'});
      saveSetupClasses();
        
      Lead ld1 = new Lead(Company='Company1', LastName='Last1');
      Lead ld2 = new Lead(Company='Company2', LastName='Last2');
      Lead[] lds = new Lead[]{ld1,ld2};
      //insert lds;
      
      
      TriggerMethods.checkBeforeLoop('TestTrigger', lds,null, true, false);
      TriggerMethods.checkInLoop('TestTrigger',ld1, ld2, true, false);
      TriggerMethods.checkOutsideLoop('TestTrigger', true, false);

   } // testTriggerInterfaceC

} // class TriggerMethodsTest