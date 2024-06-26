/** 
* The test methods for the CaseOwnerChange class and trigger.
*
* History
* -------
* 06/30/2010 Dan Carmen Created
02/21/2011 Dan Carmen Added the Credit Risk object
09/20/2011 Dan Carmen Added PEO
12/30/2011 Carrie Marciano Added HRO BeneTrac Integration
03/27/2012 Carrie Marciano changed HRO NCT to HRO LCT
01/16/2013 Justin Stouffer added the Service Onboarding PEM Case Record Type
04/23/2013 Dan Carmen Add HRE object to class. Rewrite code to be a little more generic.
08/29/2013 Cindy Freeman Added MMS Onboarding
10/16/2013 Josh Cartwright added OSMAM
10/16/2013 Justin Henderson added ASO
02/14/2017 Lynn Michels changed testing for Case:Service Onboarding S125 New Case
09/01/2021 Carrie Marciano   Removed the Credit Risk object due to uninstalling Equifax package
*
*/
@isTest
private class CaseOwnerChangeTest {

   /** Test the ownership for the Reference_Core_Payroll__c records.
   */
   static testMethod void testRefCorePayroll() {
      User u1 = [Select Id from User where Id != :UserInfo.getUserId() and IsActive=true and Profile.Name='System Administrator' limit 1];
      User u2 = [Select Id from User where Id != :UserInfo.getUserId() and Id != :u1.Id and IsActive=true and Profile.Name='System Administrator' limit 1];

      // get all of the case record types
      String[] sObjectNames = new String[]{'Case'};
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      RecordTypeHelper.getRecordTypesMap(sObjectNames, null, byName);

      // make sure there are records to check
      System.assertEquals(false,CaseOwnerChange.recordTypeObjectMap.isEmpty());

      // create a case for each record type that exists
      Case[] cases = new Case[]{};

      // store a map of the record type id and the object name for easy check later
      Map<Id,String> rtObjectNameMap = new Map<Id,String>();
      integer caseControl = 0;
      for (String rtName : CaseOwnerChange.recordTypeObjectMap.keySet()) {
         if(caseControl < 20){
             Schema.RecordTypeInfo rt = byName.get(rtName);
             if (rt != null) {
                cases.add(new Case(OwnerId = u1.Id, RecordTypeId = rt.getRecordTypeId()));
                rtObjectNameMap.put(rt.getRecordTypeId(),CaseOwnerChange.recordTypeObjectMap.get(rtName));
                caseControl++;
             }
         }
         else{
             break;
         }
      } // for

      insert cases;

      // verify reference objects were created for each record type and owner matched the case

      // keep track of the cases that have reference objects. Only update those.
      Case[] updateCases = new Case[]{};

      for (Case c : cases) {
         String objectName = rtObjectNameMap.get(c.RecordTypeId);
         // build SOQL
         String query = 'Select count() from '+objectName+' where '+CaseOwnerChange.caseLookupMap.get(objectName)+'=\''+c.Id+'\' and OwnerId=\''+u1.Id+'\'';
         System.debug('query='+query);
         Integer cnt = Database.countQuery(query);
         // if there's a reference object add to list
         if (cnt == 1) {
            updateCases.add(c);
         }
      } // for (Case

      // should be more than one updateCase
      System.assertEquals(true,updateCases.size()>1);

      // update all of the owner ids
      for (Case c : updateCases) {
         c.OwnerId = u2.Id;
      }

      // perform the update
      Test.startTest();
      update updateCases;
      Test.stopTest();

      // verify the owners were updated on all of the cases with reference objects.
      for (Case c : updateCases) {
         String objectName = rtObjectNameMap.get(c.RecordTypeId);
         // build SOQL
         String query = 'Select count() from '+objectName+' where '+CaseOwnerChange.caseLookupMap.get(objectName)+'=\''+c.Id+'\' and OwnerId=\''+u2.Id+'\'';
         System.debug('query='+query);
         Integer cnt = Database.countQuery(query);
         // if there's a reference object add to list
         System.assertEquals(1,cnt);
      } // for (Case
   } // testRefCorePayroll


   /** Test the ownership for the Reference_GL__c records.
   */
   static testMethod void testRefGL() {
      User u1 = [Select Id from User where Id != :UserInfo.getUserId() and IsActive=true and Profile.Name='System Administrator' limit 1];
      User u2 = [Select Id from User where Id != :UserInfo.getUserId() and Id != :u1.Id and IsActive=true and Profile.Name='System Administrator' limit 1];

      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('Service Onboarding GL Case', 'Case');
      // create a case - reference object should automatically be created by the trigger
      Case c = new Case(OwnerId = u1.Id, RecordTypeId = rt.getRecordTypeId());
      insert c;

      c.OwnerId = u2.Id;
      Test.startTest();
      update c;
      Test.stopTest();
      Reference_GL__c rcp = [Select Id, OwnerId from Reference_GL__c where Case_Lookup__c = :c.Id];
      System.assertEquals(u2.Id,rcp.OwnerId);
   } // testRefGL

   /** Test the ownership for the Reference_Client_Relations__c records.
   */
   static testMethod void testRefCltRltn() {
      User u1 = [Select Id from User where Id != :UserInfo.getUserId() and IsActive=true and Profile.Name='System Administrator' limit 1];
      User u2 = [Select Id from User where Id != :UserInfo.getUserId() and Id != :u1.Id and IsActive=true and Profile.Name='System Administrator' limit 1];

      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('Service Support Corporate Concerns', 'Case');
      // create a case - reference object should automatically be created by the trigger
      Case c = new Case(OwnerId = u1.Id, RecordTypeId = rt.getRecordTypeId());
      insert c;

      c.OwnerId = u2.Id;
      Test.startTest();
      update c;
      Test.stopTest();
      Reference_Client_Relations__c rcp = [Select Id, OwnerId from Reference_Client_Relations__c where Case_Lookup__c = :c.Id];
      System.assertEquals(u2.Id,rcp.OwnerId);
   } // testRefCltRltn


   /** Test the ownership for the Reference_401k records.
   */
   static testMethod void testRef401() {
      User u1 = [Select Id from User where Id != :UserInfo.getUserId() and IsActive=true and Profile.Name='System Administrator' limit 1];
      User u2 = [Select Id from User where Id != :UserInfo.getUserId() and Id != :u1.Id and IsActive=true and Profile.Name='System Administrator' limit 1];

      String[] sObjectNames = new String[]{'Case'};
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      RecordTypeHelper.getRecordTypesMap(sObjectNames, null, byName);

      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_CASE_CORE, 'Case');

      // all of the cases being created
      List<Case> cases = new List<Case>();
      // create the cases - reference object should automatically be created by the trigger
      Case newC = new Case(OwnerId = u1.Id, RecordTypeId = byName.get('Service Onboarding 401k Conversion').getRecordTypeId());
      cases.add(newC);
      newC = new Case(OwnerId = u1.Id, RecordTypeId = byName.get('Service Onboarding 401k New Case').getRecordTypeId());
      cases.add(newC);
     // newC = new Case(OwnerId = u1.Id, RecordTypeId = byName.get('Service Onboarding S125 New Case').getRecordTypeId());
     // cases.add(newC);
      newC = new Case(OwnerId = u1.Id, RecordTypeId = byName.get('Service Onboarding S125 Conversion').getRecordTypeId());
      cases.add(newC);

      insert cases;

      List<Id> caseIds = new List<Id>();
      // change the owner on all of the records
      for (Case c : cases) {
         c.OwnerId = u2.Id;
         caseIds.add(c.Id);
      } // for

      // verify current owner
      List<Reference_401k_S125__c> refs = new List<Reference_401k_S125__c>([Select Id, OwnerId 
             from Reference_401k_S125__c
             where Case_Lookup__c in :caseIds]);
      // verify correct number returned.
      System.assertEquals(cases.size(), refs.size());
      for (Reference_401k_S125__c ref : refs) {
         System.assertEquals(u1.Id,ref.OwnerId);
      } 

      Test.startTest();
      update cases;
      Test.stopTest();

      // verify new owner
      refs = new List<Reference_401k_S125__c>([Select Id, OwnerId 
           from Reference_401k_S125__c
           where Case_Lookup__c in :caseIds]);
      // verify correct number returned.
      System.assertEquals(cases.size(), refs.size());
      for (Reference_401k_S125__c ref : refs) {
         System.assertEquals(u2.Id,ref.OwnerId);
      } 
   } // testRef401

/** Test the ownership for the Reference_S125_Onboarding__c records.
   */
    static testMethod void testRefS125Onboarding() {
      User u1 = [Select Id from User where Id != :UserInfo.getUserId() and IsActive=true and Profile.Name='System Administrator' limit 1];
      User u2 = [Select Id from User where Id != :UserInfo.getUserId() and Id != :u1.Id and IsActive=true and Profile.Name='System Administrator' limit 1];

      Id casert = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Onboarding S125 New Case').getRecordTypeId();
   
      // create the cases - reference object should automatically be created by the trigger
      Case c = new Case(OwnerId = u1.Id, RecordTypeId = casert);
      insert c;
      
	  //create Reference S125 Onboarding record
	  Reference_S125_Onboarding__c rs125 = new Reference_S125_Onboarding__c(case_lookup__c = c.id);
	  insert rs125;
	  
	  
      c.OwnerId = u2.Id;
      Test.startTest();
      update c;
      Test.stopTest();
      Reference_S125_Onboarding__c rcp = [Select Id, OwnerId from Reference_S125_Onboarding__c where Case_Lookup__c = :c.Id];
      System.assertEquals(u2.Id,rcp.OwnerId);
   } // testRefS125Onboarding
   
/** Test the ownership for the Reference_MMS_Payroll__c records.
*/
/*
   static testMethod void testRefMMS() {
      Object_Relationships__c orc = CreateTestData.createRelatedObjectsCase();
      User u1 = [Select Id from User where Id != :UserInfo.getUserId() and IsActive=true and Profile.Name='System Administrator' limit 1];
      Group g1 = [Select Id from Group where Group.Name like 'MMS % - New Load Queue' limit 1];

      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('Service Onboarding MMS Payroll Case', 'Case');
      // create a case - reference object should automatically be created by the trigger
      Case c = new Case(OwnerId = u1.Id, RecordTypeId = rt.getRecordTypeId());
      insert c; 
      Reference_MMS_Payroll__c refmms = [Select Id, OwnerId from Reference_MMS_Payroll__c where Case_Number__c = :c.Id];
      System.assertEquals(u1.Id,refmms.OwnerId);

      // change case owner from user to queue, reference owner should also change
      c.OwnerId = g1.Id;
      Test.startTest();
      update c; 
      refmms = [Select Id, OwnerId from Reference_MMS_Payroll__c where Case_Number__c = :c.Id];
      System.assertEquals(g1.Id,refmms.OwnerId);

      // change case owner from queue to user, reference owner should Not change
      c.OwnerId = g1.Id; 
      update c;
      Test.stopTest(); 
      refmms = [Select Id, OwnerId from Reference_MMS_Payroll__c where Case_Number__c = :c.Id];
      System.assertEquals(g1.Id,refmms.OwnerId);

   } // testRefMMS
*/

   /** Test the ownership for the Reference_ASO__c records.
   */
   static testMethod void testRefASO() {

      User u1 = [Select Id from User where Id != :UserInfo.getUserId() and IsActive=true and Profile.Name='System Administrator' limit 1];
      User u2 = [Select Id from User where Id != :UserInfo.getUserId() and Id != :u1.Id and IsActive=true and Profile.Name='System Administrator' limit 1];

      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('Service Onboarding ASO New Business', 'Case');
      // create a case - reference object should automatically be created by the trigger
      Case c = new Case(OwnerId = u1.Id, RecordTypeId = rt.getRecordTypeId());
      insert c; 
      Reference_ASO__c refASO = new Reference_ASO__c(Case_Number__c=c.id, OwnerId = c.OwnerId);

      insert refASO;


      // change case owner from user to queue, reference owner should also change
      c.OwnerId  = u2.Id;
      Test.startTest();
      update c; 
      Test.stopTest(); 
      refASO = [Select Id, OwnerId from Reference_ASO__c where Case_Number__c = :c.Id];
      System.assertEquals(u2.Id,refASO.OwnerId);

   } // testRefASO


} // class CaseOwnerChangeTest