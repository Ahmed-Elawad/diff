/* 
 * Test Methods for the PlatformTrackingHelper class
 *
 * History
 * -------
   08/21/2017 Dan Carmen       Created
   10/15/2019 Dan Carmen       Change to use TriggerMethods.clearVariables
   03/08/2021  Dan Carmen          Added ability to not save tracker
   11/10/2023 Dan Carmen       Comment out code

 */
@isTest
private class PlatformTrackingHelperTest {
    static testMethod void testNothing() {
       new PlatformTrackingHelper();
    }
   /*
   static testMethod void testLead() {
      PlatformTrackingHelper.TRACK_ANY_USER = false;
      // setup triggers
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerSetup__c trigSetup1 = TriggerMethodsTest.createCustomSetting(null, 'LeadAfter', false, true, new String[]{'PlatformTrackingHelper'},setupClasses);
      TriggerSetup__c trigSetup2 = TriggerMethodsTest.createCustomSetting(null, 'AccountAfter', false, true, new String[]{'PlatformTrackingHelper'},setupClasses);
      TriggerSetup__c trigSetup3 = TriggerMethodsTest.createCustomSetting(null, 'ContactAfter', false, true, new String[]{'PlatformTrackingHelper'},setupClasses);
      insert setupClasses;
      
      // run as a sales rep
      String profName = Utilities.PROF_CORE_SALES+'%';
      User runningUser = [Select Id, Name from User where IsActive=true and Profile.Name like :profName limit 1 ];

      Lead ld1 = new Lead(Company='Test Company1', FirstName='First', LastName='Last1', PostalCode='12345');

      System.runAs(runningUser) {
         insert ld1;
      }

      // should only be one record
      PlatformTracker__c platTrack = [Select Id, Name, RecordId__c, ObjectType__c, UsageType__c from PlatformTracker__c where RecordId__c=:ld1.Id];
      System.assertEquals(ObjectHelper.OBJECT_LEAD, platTrack.ObjectType__c);
      System.assertEquals('Insert', platTrack.UsageType__c);
      
      // clear to perform another transaction
      PlatformTrackingHelper.idProcessedSet.clear();
      
      TriggerMethods.clearVariables();
      System.runAs(runningUser) {
         ld1.State='NY';
         update ld1;
      }
      
      PlatformTracker__c[] platTracks = [Select Id, Name, RecordId__c, ObjectType__c, UsageType__c from PlatformTracker__c where RecordId__c=:ld1.Id order by CreatedDate asc];
      System.assertEquals(2, platTracks.size());
      System.assertEquals(ObjectHelper.OBJECT_LEAD, platTracks[0].ObjectType__c);
      System.assertEquals('Insert', platTracks[0].UsageType__c);

      System.assertEquals(ObjectHelper.OBJECT_LEAD, platTracks[1].ObjectType__c);
      System.assertEquals('Update', platTracks[1].UsageType__c);

      // clear to perform another transaction
      PlatformTrackingHelper.idProcessedSet.clear();
      
      // when it converts a lead, shouldn't create a new lead tracking record
      
      // create a LeadConvert object       
      Database.LeadConvert lc = new database.LeadConvert();
      lc.setLeadId(ld1.id);

      LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
      // set the status
      lc.setConvertedStatus(convertStatus.MasterLabel);
      
      Database.LeadConvertResult lcr = null;
      TriggerMethods.clearVariables();
      System.runAs(runningUser) {
         // convert the lead
         lcr = Database.convertLead(lc);
      
         System.assert(lcr.isSuccess());
      } // System.runAs

      // should still be 2 of these
      platTracks = [Select Id, Name, RecordId__c, ObjectType__c, UsageType__c from PlatformTracker__c where RecordId__c=:ld1.Id order by CreatedDate asc];
      System.assertEquals(2, platTracks.size());

      // one for the contact record      
      platTrack = [Select Id, Name, RecordId__c, ObjectType__c, UsageType__c from PlatformTracker__c where RecordId__c=:lcr.getContactId()];
      System.assertEquals(ObjectHelper.OBJECT_CONTACT, platTrack.ObjectType__c);
      System.assertEquals('Insert', platTrack.UsageType__c);

      // one for the account record      
      platTrack = [Select Id, Name, RecordId__c, ObjectType__c, UsageType__c from PlatformTracker__c where RecordId__c=:lcr.getAccountId()];
      System.assertEquals(ObjectHelper.OBJECT_ACCOUNT, platTrack.ObjectType__c);
      System.assertEquals('Insert', platTrack.UsageType__c);

   } // testLead
   
   static testMethod void testMisc() {
      PlatformTrackingHelper pth = new PlatformTrackingHelper();
      pth.checkAllBeforeTrigger((SObject[])null, (Map<Id,Object>)null);
      pth.checkBeforeTrigger((SObject)null, (SObject)null);
      pth.processBeforeTriggerActions();
      pth.checkAfterTrigger((SObject)null, (SObject)null);
      pth.processAfterTriggerActions();
   } // testMisc
*/   
    
   static testMethod void testController() {
      PlatformTrackingComponentController.SAVE_TRACKER=true;
      Lead ld1 = new Lead(Company='Test Company1', FirstName='First', LastName='Last1', PostalCode='12345');
      insert ld1;
      PlatformTrackingComponentController.save(ld1.Id, ObjectHelper.OBJECT_LEAD,null);
      
      PlatformTracker__c platTrack = [Select Id, Name, RecordId__c, ObjectType__c, UsageType__c from PlatformTracker__c where RecordId__c=:ld1.Id];
      System.assertEquals(ObjectHelper.OBJECT_LEAD, platTrack.ObjectType__c);
      System.assertEquals('Read', platTrack.UsageType__c);

      PlatformTrackingComponentController ptcc = new PlatformTrackingComponentController();
      ptcc.recId = ld1.Id;
      ptcc.objType = ObjectHelper.OBJECT_LEAD;
   } // testController
    
} // class PlatformTrackingHelperTest