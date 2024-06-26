/* 
 * Test methods for the WorkflowHelper class
 *
 * History
 * -------
   04/16/2018 Dan Carmen       Created
   11/09/2018 Dan Carmen       Added functionality for Lead and Contact
   10/15/2019 Dan Carmen       Change to use TriggerMethods.clearVariables
   09/01/2021 Dan Carmen       Add Operation__c field and addition logic
   05/17/2024 Carrie Marciano  Commented out testNullValueCheck() because deleted MPSC Service Timecard Case with MPSC Tech Debt clean up 

 */
@isTest
private class WorkflowHelperTest {
   
   @testSetup 
   static void setupData() {
      TriggerMethodsTest.createTriggerSetting('CaseBefore', true, false, false, false, new String[]{'WorkflowHelper'});
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false, new String[]{'WorkflowHelper'});
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false, new String[]{'WorkflowHelper'});
      TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false, new String[]{'WorkflowHelper'});
      TriggerMethodsTest.saveSetupClasses();
   } // setupData
   
   public static ObjectWorkFlow__mdt[] testData = null;

   public static ObjectWorkFlow__mdt[] getTestData(String testName) {
      WorkflowHelper.TEST_SCENARIO = testName;
      testData = [Select Id, ObjectAPIName__c, RecordTypeName__c, TestScenario__c
                        ,(Select Id, Label
                                ,CheckFldAPIName__c
                                ,CheckFldType__c
                                ,CheckValue__c
                                ,NewValue__c
                                ,NewValueType__c
                                ,RecordAction__c
                                ,UpdateFldAPIName__c
                            From FieldWorkflows__r)
                    From ObjectWorkFlow__mdt
                   Where TestScenario__c = :testName];
      System.debug('getTestData testData='+testData.size());

      // verify we get data back
      System.assertEquals(true, testData.size() > 0, 'Test Data for '+testName+' Not found!');
      return testData;
   } // getTestData
   
   public static Id getRecordTypeId(String recordTypeName) {
      Map<String, Schema.RecordTypeInfo> caseRtMap = Case.getSobjectType().getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo rtInfo = caseRtMap.get(recordTypeName);
      return (rtInfo != null ? rtInfo.getRecordTypeId() : null);
   } // getRecordTypeId

   static testMethod void testUpdateFromOtherFldOnInsert() {
      // Test 1
      ObjectWorkFlow__mdt testOwf = getTestData('Test 1')[0];
      // create a case with the appropriate record type
      Id recordTypeId = getRecordTypeId(testOwf.RecordTypeName__c);
      System.assertEquals(true, recordTypeId != null, 'RecordTypeId for '+testOwf.RecordTypeName__c+' was NOT found!');
      // this rule should update from another field - we'll check just to make sure. Assuming 1 field rule.
      System.assertEquals(1, testOwf.FieldWorkflows__r.size());
      FieldWorkFlow__mdt fwf = testOwf.FieldWorkflows__r[0];
      System.assertEquals(fwf.NewValueType__c, WorkflowHelper.NEW_VALUE_FIELDVALUE);
      System.assertEquals(fwf.RecordAction__c, WorkflowHelper.RECORD_ACTION_INSERT);
      
      Account acct = new Account(Name='Test Acct');
      insert acct;
      
      Contact ctct = new Contact(AccountId=acct.Id, LastName='Taylor', FirstName='Jimmy');
      insert ctct;
      
      Opportunity opp = new Opportunity(AccountId=acct.Id, Name='Test Opp', CloseDate=Date.today(), StageName='Pending');
      insert opp;
      
      Case cs = new Case(RecordTypeId=recordTypeId, AccountId=acct.Id, ContactId=ctct.Id, Opportunity__c=opp.Id);
      // In this situation, the api name of the field should be in the NewValue__c field
      cs.put(fwf.NewValue__c, 'Test Value');
      
      WorkflowHelper.ALREADY_RAN_SET.clear();
      Test.startTest();
      insert cs;
      Test.stopTest();
      
      Id caseId = cs.Id;
      
      String query = 'select Id, ProcessNotes__c, '+fwf.UpdateFldAPIName__c+','+fwf.NewValue__c+' from Case where Id=:caseId';
      Case checkCs = Database.query(query);
      System.debug('testUpdateFromOtherFldOnInsert checkCs='+checkCs);
      //Case checkCs = [Select Id, Subject from Case where Id=:cs.Id];
      System.assertEquals((String)checkCs.get(fwf.NewValue__c),(String)checkCs.get(fwf.UpdateFldAPIName__c));
   } // testUpdateFromOtherFldOnInsert

   static testMethod void testUpdateLiteralValueOnInsert() {
      // Test 2
      ObjectWorkFlow__mdt testOwf = getTestData('Test 2')[0];
      // create a case with the appropriate record type
      Id recordTypeId = getRecordTypeId(testOwf.RecordTypeName__c);
      System.assertEquals(true, recordTypeId != null, 'RecordTypeId for '+testOwf.RecordTypeName__c+' was NOT found!');

      // this rule should update a literal value on an insert. Assuming at least 1 field rule.
      System.assertEquals(true, testOwf.FieldWorkflows__r.size() >= 1);
      // find the one for subject.
      FieldWorkFlow__mdt fwf = null;
      for (FieldWorkFlow__mdt checkFwf : testOwf.FieldWorkflows__r) {
         if (checkFwf.UpdateFldAPIName__c == 'Subject') {
            fwf = checkFwf;
            break;
         }
      }
      System.assertNotEquals(null,fwf);
      System.assertEquals(fwf.NewValueType__c, WorkflowHelper.NEW_VALUE_LITERAL);
      System.assertEquals(fwf.RecordAction__c, WorkflowHelper.RECORD_ACTION_INSERT);

      Account acct = new Account(Name='Test Acct');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      Contact ctct = new Contact(AccountId=acct.Id, LastName='Taylor', FirstName='Jimmy');
      insert ctct;
      
      Opportunity opp = new Opportunity(AccountId=acct.Id, Name='Test Opp', CloseDate=Date.today(), StageName='Pending');
      insert opp;
      
      Case cs = new Case(RecordTypeId=recordTypeId, AccountId=acct.Id, ContactId=ctct.Id, Opportunity__c=opp.Id);

      WorkflowHelper.ALREADY_RAN_SET.clear();
      Test.startTest();
      insert cs;
      Test.stopTest();
      
      Case checkCs = [Select Id, Subject from Case where Id=:cs.Id];
      System.assertEquals(fwf.NewValue__c,checkCs.Subject);

   } // testUpdateLiteralValueOnInsert
   
   static testMethod void testLeadDates() {
      ObjectWorkFlow__mdt testOwf = getTestData('Test 3')[0];
      // expecting 2 back - 1 for date, 1 for datetime
      FieldWorkFlow__mdt fwfDate = null;
      FieldWorkFlow__mdt fwfDateTime = null;
      for (FieldWorkFlow__mdt fwf : testOwf.FieldWorkflows__r) {
         if (fwf.NewValueType__c == WorkflowHelper.NEW_VALUE_DATE) {
            fwfDate = fwf;
         } else if (fwf.NewValueType__c == WorkflowHelper.NEW_VALUE_DATETIME) {
            fwfDateTime = fwf;
         }
      } // for (FieldWorkFlow__mdt fwf
      
      System.assertEquals(true, fwfDate != null);
      System.assertEquals(true, fwfDateTime != null);

      Lead ld = new Lead(LastName='TestLast', Company='TestCompany');
      insert ld;
      Id leadId = ld.Id;
      
      String query = 'Select Id, Name, '+fwfDate.UpdateFldAPIName__c+', '+fwfDateTime.UpdateFldAPIName__c+' from Lead where Id=:leadId';
      Lead checkLd = Database.query(query);
      System.debug('testLeadDates 1 checkLd='+checkLd);
      System.assertEquals(null,checkLd.get(fwfDate.UpdateFldAPIName__c));
      System.assertEquals(null,checkLd.get(fwfDateTime.UpdateFldAPIName__c));
      
      WorkflowHelper.ALREADY_RAN_SET.clear();
      checkLd.put(fwfDate.CheckFldAPIName__c, fwfDate.CheckValue__c);
      TriggerMethods.clearVariables();
      update checkLd;
      
      checkLd = Database.query(query);
      System.debug('testLeadDates 2 checkLd='+checkLd);
      System.assertEquals(true,checkLd.get(fwfDate.UpdateFldAPIName__c) != null, fwfDate.UpdateFldAPIName__c+' has a null value!');
      System.assertEquals(true,checkLd.get(fwfDateTime.UpdateFldAPIName__c) != null, fwfDateTime.UpdateFldAPIName__c+' has a null value!');
   } // testLeadDates

   static testMethod void testContact() {
      ObjectWorkFlow__mdt testOwf = getTestData('Test 4')[0];
      // expecting 1 back
      System.assertEquals(1, testOwf.FieldWorkflows__r.size());
      FieldWorkFlow__mdt fwf = testOwf.FieldWorkflows__r[0];
      System.assertEquals(fwf.NewValueType__c, WorkflowHelper.NEW_VALUE_LITERAL);
      System.assertEquals(fwf.RecordAction__c, WorkflowHelper.RECORD_ACTION_CHANGED);
      
      Contact ctct = new Contact(LastName='TestLast');
      insert ctct;
      Id ctctId = ctct.Id;
      
      String query = 'Select Id, Name, '+fwf.UpdateFldAPIName__c+', '+fwf.CheckFldAPIName__c+' from Contact where Id=:ctctId';
      Contact checkCtct = Database.query(query);
      System.debug('testContact 1 checkCtct='+checkCtct);
      System.assertNotEquals(fwf.NewValue__c,(String)checkCtct.get(fwf.UpdateFldAPIName__c));
      
      WorkflowHelper.ALREADY_RAN_SET.clear();
      checkCtct.put(fwf.CheckFldAPIName__c, fwf.CheckValue__c);
      update checkCtct;
      
      checkCtct = Database.query(query);
      System.debug('testContact 2 checkCtct='+checkCtct);
      System.assertEquals(fwf.NewValue__c,(String)checkCtct.get(fwf.UpdateFldAPIName__c));
   } // testContact
   
   static testMethod void testMisc() {
      WorkflowHelper wh = new WorkflowHelper();
      //wh.triggerCheckRec(null,null, true, false);
      //wh.triggerCheckActions(true,false);

   } // testMisc

   static testMethod void testOpp() {
      ObjectWorkFlow__mdt testOwf = getTestData('Test 5')[0];
      // assume this is testing the status date and child unit and HPP delivery date
      Account acct = new Account(Name='Test Account');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acct.Id, StageName='Pending', CloseDate=Date.today());
      insert opp;
      opp = [Select Id, Name, StageName, Child_Unit__c, Payroll_Unit__c, HPP_Status__c, HPP_In_Progress_Date__c, Status_Update_Date__c from Opportunity where Id=:opp.Id];
      System.assertEquals(Date.today(),opp.Status_Update_Date__c);
      
      opp.Child_Unit__c = true;
      opp.Status_Update_Date__c = null;
      opp.HPP_Status__c = 'In Progress';
      opp.StageName = 'Sold';
      WorkflowHelper.ALREADY_RAN_SET.clear();
      update opp;

      opp = [Select Id, Name, StageName, Child_Unit__c, Payroll_Unit__c, HPP_Status__c, HPP_In_Progress_Date__c, Status_Update_Date__c from Opportunity where Id=:opp.Id];
      System.assertEquals(Date.today(),opp.HPP_In_Progress_Date__c);
      System.assertEquals(Date.today(),opp.Status_Update_Date__c);
      System.assertEquals(true, opp.Payroll_Unit__c);
      
   } // testOpp
    
   /* deleted MPSC Service Timecard Case with MPSC Tech Debt clean up
   static testMethod void testNullValueCheck() {
      ObjectWorkFlow__mdt testOwf = getTestData('Test 6')[0];
      Id recordTypeId = getRecordTypeId(testOwf.RecordTypeName__c);
      System.assertEquals(true, recordTypeId != null, 'RecordTypeId for '+testOwf.RecordTypeName__c+' was NOT found!');
      // assume this is testing the status date and child unit and HPP delivery date
      Account acct = new Account(Name='Test Account');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      WorkFlowHelper.literalValueOverride=acct.Id;
       
      Case cs = new Case(RecordTypeId=recordTypeId, Subject='Test Case');
      insert cs;
       
      cs = [Select Id, RecordTypeId, AccountId from Case where Id=:cs.Id];
      System.assertEquals(acct.Id, cs.AccountId);
      
   } // testNullValueCheck
   */
    
   static testMethod void testPrevValueCheck() {
      ObjectWorkFlow__mdt testOwf = getTestData('Test 7')[0];
      Case cs = new Case(Subject='Test Case');
      insert cs;
       
      cs.Project_Training_Issue_Reason__c='Other';
      cs.Return_Reasons__c='Other';
      System.debug('testPrevValueCheck before update1');
      WorkflowHelper.ALREADY_RAN_SET.clear();
      update cs;
      
      cs = [Select Id, Subject, Project_Training_Issue_Reason__c, Return_Reasons__c, Return_Date__c, Returned_By_Lookup__c from Case where Id=:cs.Id];
      System.assertEquals(Date.today(), cs.Return_Date__c);
      System.assertEquals(UserInfo.getUserId(), cs.Returned_By_Lookup__c);
      
      // clear out the values to see if the workflow fires again
      cs.Return_Date__c = null;
      cs.Returned_By_Lookup__c = null;
      update cs;
       
      // shouldn't update the return values just because the value changes
      cs.Project_Training_Issue_Reason__c = 'Changed Value';
      cs.Return_Reasons__c='Other2';
      System.debug('testPrevValueCheck before update2');
      WorkflowHelper.ALREADY_RAN_SET.clear();
      update cs;
      
      cs = [Select Id, Subject, Project_Training_Issue_Reason__c, Return_Reasons__c, Return_Date__c, Returned_By_Lookup__c from Case where Id=:cs.Id];
      System.assertEquals(null, cs.Return_Date__c);
      System.assertEquals(null, cs.Returned_By_Lookup__c);

      cs.Project_Training_Issue_Reason__c = null;
      cs.Return_Reasons__c=null;
      System.debug('testPrevValueCheck before update3');
      WorkflowHelper.ALREADY_RAN_SET.clear();
      update cs;
       
      // making sure stays null
      cs = [Select Id, Subject, Project_Training_Issue_Reason__c, Return_Reasons__c, Return_Date__c, Returned_By_Lookup__c from Case where Id=:cs.Id];
      System.assertEquals(null, cs.Return_Date__c);
      System.assertEquals(null, cs.Returned_By_Lookup__c);
       
      cs.Project_Training_Issue_Reason__c = 'Should Populate Again';
      cs.Return_Reasons__c='Other';
      System.debug('testPrevValueCheck before update4');
      WorkflowHelper.ALREADY_RAN_SET.clear();
      TriggerMethods.clearVariables();
      update cs;

      cs = [Select Id, Subject, Project_Training_Issue_Reason__c, Return_Reasons__c, Return_Date__c, Returned_By_Lookup__c from Case where Id=:cs.Id];
      System.assertEquals(Date.today(), cs.Return_Date__c);
      System.assertEquals(UserInfo.getUserId(), cs.Returned_By_Lookup__c);

   } // testPrevValueCheck
   
} // class WorkflowHelperTest