/* 
 * Test methods for CaseSetAlertTimeStamp
 *
 * History
 * -------
 * 07/15/2015 Dan Carmen   Created from CaseSetAlertTimeStamp class.
   10/26/2018 Dan Carmen   Set API version to 44

 */
@isTest
private class CaseSetAlertTimeStampTest {

   static testMethod void testTimeStamp() {
      // test that the time stamp is set
      // find a user with a manager and a 2nd level manager
      User u = [Select Id, ManagerId, Manager.ManagerId from User where IsActive=true and ManagerId != null and Manager.ManagerId != null limit 1];
      // get the RecordType for 'Service Premier Record Type'
      Schema.RecordTypeInfo rt = RecordTypeHelper.getCaseRecordTypeInfo(CaseSetAlertTimeStamp.SERVICE_PREMIER_RT);
      Id servicePremierRtId = (rt != null ? rt.getRecordTypeId() : null);

      System.runAs(u) {
         Case c = new Case(Subject='Test Case', RecordTypeId = servicePremierRtId);
         insert c;
          c = [Select Id, level1AlertDateTime__c, level2AlertDateTime__c
                     ,User_Level_1_Supervisor__c, User_Level_2_Supervisor__c
                     ,SupervisorAlert__c
                from Case where Id=:c.Id];
          System.assertEquals(true,(c.level1AlertDateTime__c != null));
          System.assertEquals(true,(c.level2AlertDateTime__c == null));
          System.assertEquals(u.ManagerId,c.User_Level_1_Supervisor__c);
          System.assertEquals(u.Manager.ManagerId,c.User_Level_2_Supervisor__c);
      }
   } // testTimeStamp

} // class CaseSetAlertTimeStampTest