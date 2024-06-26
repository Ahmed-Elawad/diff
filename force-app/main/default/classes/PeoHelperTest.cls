/* 
 * Test Methods for the PEO Centric functionality.
 

 
 *
 * History
 * -------
   06/15/2018 Dan Carmen       Created
   06/20/2018 Cindy Freeman     added test for checkLeadsForPEO
   03/27/2019 Jake Hinds     changes to checkLeadsForPEO
   05/28/2019 Jake Hinds       Oppty Not Sold Method
   01/10/2020 Dan Carmen         Update test, increment API version
   01/07/2022 Dan Carmen         Increment API version

 */
@isTest
private class PeoHelperTest {

   @testSetup 
   public static void setupTestData() {
      
      //TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false, new String[]{'PeoHelper'});
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false, new String[]{'PeoHelper'});
      //TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, new String[]{'PeoHelper'});
      TriggerMethodsTest.saveSetupClasses();
      //AccountJunctionMethodsTest.setupCustomSettings();

      //HoldOutExpirationMethodsTest.populateSetting();
      //ZipCheckOwnerTest.setupSegments();
      //RecordTypeHelperTest.setupRecordType();
   } // setupTestData

   static testMethod void testLeadsForPeo() {
      User runningUser = UserHelper.getRunningUser();
      // set the running user so that the trigger will fire for this
      PeoHelper.PEO_PROFILE_NAME = runningUser.Profile.Name;

      // create as a core lead to make sure it changes
      Schema.RecordTypeInfo coreRtInfo = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);

      Lead ld1 = new Lead(Company='Lead Co1', LastName='TestLast1', RecordTypeId=coreRtInfo.getRecordTypeId());
      insert ld1;
      
      Lead checkLd1 = [Select Id, Name, RecordType.Name, PEOLeasing__c from Lead where Id=:ld1.Id];
      System.assertEquals(PeoHelper.PEO_LEAD_RT_NAME, checkLd1.RecordType.Name);
      System.assertEquals(true, checkLd1.PEOLeasing__c);
      
   } // testLeadsForPeo
   
   static testMethod void testCheckLeadsForPeo() {
       PeoHelper.peoProductSet = new Set<String>{'PEO'};
       // create as a core lead to make sure it changes
      Schema.RecordTypeInfo coreRtInfo = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);

      Lead ld1 = new Lead(Company='Lead Co1', LastName='TestLast1', RecordTypeId=coreRtInfo.getRecordTypeId());
      Lead ld2 = new Lead(Company='Lead Co2', LastName='TestLast2', RecordTypeId=coreRtInfo.getRecordTypeId());
      Lead ld3 = new Lead(Company='Lead Co3', LastName='TestLast3', RecordTypeId=coreRtInfo.getRecordTypeId(), Product_Division__c='PEO');
      insert new Lead[]{ld1,ld2,ld3};     
      Task tsk1 = new Task(Subject='PEOLead Test Task1',ActivityDate=System.today(),Status='Pending',WhoId=ld1.Id);
      Task tsk2 = new Task(Subject='PEOLead Test Task2',ActivityDate=System.today(),Status='Completed',WhoId=ld2.Id);
      insert new Task[]{tsk1,tsk2};
      
      Map<Id,Lead> leadMap = new Map<Id,Lead>([Select Id, Name, RecordType.Name, PEOLeasing__c, ProcessNotes__c from Lead]);
      System.assertEquals(false,leadMap.get(ld1.Id).PEOLeasing__c);
      System.assertEquals(RecordTypeHelper.CORE_LEAD,leadMap.get(ld1.Id).RecordType.Name);
      System.assertEquals(false,leadMap.get(ld2.Id).PEOLeasing__c);
      System.assertEquals(RecordTypeHelper.CORE_LEAD,leadMap.get(ld2.Id).RecordType.Name);
      System.assertEquals(true,leadMap.get(ld3.Id).PEOLeasing__c);
      System.assertEquals(PeoHelper.PEO_LEAD_RT_NAME,leadMap.get(ld3.Id).RecordType.Name);
      System.assertEquals(true,leadMap.get(ld3.Id).ProcessNotes__c.contains('Set to PEO Record Type based on Product Division'));
          
      TriggerMethods.clearVariables();
      ld1.Product_Division__c='PEO';
      ld2.Product_Division__c='PEO';
      update new Lead[]{ld1,ld2};
          
      leadMap = new Map<Id,Lead>([Select Id, Name, RecordType.Name, PEOLeasing__c, ProcessNotes__c from Lead]);
      System.assertEquals(false,leadMap.get(ld1.Id).PEOLeasing__c);
      System.assertEquals(RecordTypeHelper.CORE_LEAD,leadMap.get(ld1.Id).RecordType.Name);
      System.assertEquals(true,leadMap.get(ld1.Id).ProcessNotes__c.contains('Open Activities are present'));
       
      System.assertEquals(true,leadMap.get(ld2.Id).PEOLeasing__c);
      System.assertEquals(PeoHelper.PEO_LEAD_RT_NAME,leadMap.get(ld2.Id).RecordType.Name);
      System.assertEquals(true,leadMap.get(ld2.Id).ProcessNotes__c.contains('Set to PEO Record Type based on Product Division'));
          

   } // testCheckLeadsForPeo

} // class PeoHelperTest