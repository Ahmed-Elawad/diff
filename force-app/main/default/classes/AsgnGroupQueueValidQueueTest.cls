/* 
 * Test methods for the AsgnGroupQueueValidQueue class.
 *
 * History
 * -------
   08/19/2011 Dan Carmen        Created
   10/26/2018 Dan Carmen        Increment API to version 44

 */
@isTest
private class AsgnGroupQueueValidQueueTest {

   static testMethod void testQueueCreate() {
      // create queue
      Group[] grps = new Group[]{};
      grps.add(new Group(Name='AsgnGroupQueueValidQueue Queue 1',Type='Queue'));
      grps.add(new Group(Name='AsgnGroupQueueValidQueue Queue 2',Type='Queue'));
      insert grps;
      
      // create assignment group name
      Assignment_Group_Name__c agn = new Assignment_Group_Name__c(Name='AsgnGroupQueueValidQueue Queue 1');
      insert agn;

      // create an assignment group queue record - invalid queue name
      Assignment_Group_Queues__c agq1 = new Assignment_Group_Queues__c(Assignment_Group_Name__c=agn.Id, Name='ThisIsABadName');
      try {
         insert agq1;
      } catch (Exception e) {
      	 System.assertEquals(true,e.getMessage().contains('Invalid Queue name'));
      }
      System.assertEquals(null,agq1.Id);
   	
      // set to valid name and insert
      agq1.Name='AsgnGroupQueueValidQueue Queue 1';
      insert agq1;
      System.assertEquals(true,(agq1.Id != null));

      // create an assignment group queue record - same name - duplicate
      Assignment_Group_Queues__c agq2 = new Assignment_Group_Queues__c(Assignment_Group_Name__c=agn.Id, Name='AsgnGroupQueueValidQueue Queue 1');
      try {
         insert agq2;
      } catch (Exception e) {
      	 System.assertEquals(true,e.getMessage().contains('already assigned to another Assignment Group'));
      }
      System.assertEquals(null,agq2.Id);
      
      // update to different queue
      agq1.Name='AsgnGroupQueueValidQueue Queue 2';
      update agq1;

   } // testQueueCreate
   
} // class AsgnGroupQueueValidQueueTest