/** Test methods for TestCheckRecordType trigger and class
 *
 * History
 * -------
 * 10/28/2011 Dan Carmen        Created - moved testMethod from TestCheckRecordType class
 * 07/17/2014 Leslie Hogan      Modified test for Call Type of tasks to 'Current Client Call'
   10/26/2018 Dan Carmen        Increment API version - not sure that we actually need this anymore

 */
@isTest
private class TaskCheckRecordTypeTest {

   static testMethod void testTaskCreation() {
      // get a non-PAY user
      User nonPayU = [Select Id from User where Sales_Org__c != 'PAY' and Profile.Name='System Administrator' and IsActive=true limit 1];
      User payU = [Select Id from User where Sales_Org__c = 'PAY' and IsActive=true limit 1];
      
      // create an Opportunity
      Opportunity opp = new Opportunity(Name='Test Opp', CloseDate=Date.today().addMonths(1), StageName='Pending');
      insert opp;

      // create three tasks owned by the PAY user
      Task t1 = new Task(OwnerId=payU.Id, WhatId=opp.Id, Subject='30-Day Follow up', ActivityDate=Date.today().addDays(30));
      Task t2 = new Task(OwnerId=payU.Id, WhatId=opp.Id, Subject='60-Day Follow up', ActivityDate=Date.today().addDays(60));
      Task t3 = new Task(OwnerId=payU.Id, WhatId=opp.Id, Subject='90-Day Follow up', ActivityDate=Date.today().addDays(90));
      Task t4 = new Task(OwnerId=payU.Id, WhatId=opp.Id, Subject='Test Subject', ActivityDate=Date.today().addDays(90));

      // insert as the other user so creator differs
      System.runAs(nonPayU) {
         Task[] tasks = new Task[]{t1,t2,t3,t4};
         insert tasks;
      } // System.runAs
      
      Schema.Recordtypeinfo coreRT = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_TASK, 'Task');
      
      // verify call type and record id
      t1 = [Select Id, RecordTypeId, Lead_Source_WAR_Call_Type__c from Task where Id=:t1.Id];
      System.assertEquals(coreRT.getRecordTypeId(),t1.RecordTypeId);
      System.assertEquals('Current Client Call',t1.Lead_Source_WAR_Call_Type__c);

      t2 = [Select Id, RecordTypeId, Lead_Source_WAR_Call_Type__c from Task where Id=:t2.Id];
      System.assertEquals(coreRT.getRecordTypeId(),t2.RecordTypeId);
      System.assertEquals('Current Client Call',t2.Lead_Source_WAR_Call_Type__c);

      t3 = [Select Id, RecordTypeId, Lead_Source_WAR_Call_Type__c from Task where Id=:t3.Id];
      System.assertEquals(coreRT.getRecordTypeId(),t3.RecordTypeId);
      System.assertEquals('Current Client Call',t3.Lead_Source_WAR_Call_Type__c);
      
      // verify values didn't change for a different subject
      t4 = [Select Id, RecordTypeId, Lead_Source_WAR_Call_Type__c from Task where Id=:t4.Id];
      //System.assertEquals(true,(coreRT.getRecordTypeId()!=t3.RecordTypeId));
      System.assertEquals(true,(t4.Lead_Source_WAR_Call_Type__c == null || (t4.Lead_Source_WAR_Call_Type__c != null && t4.Lead_Source_WAR_Call_Type__c != 'Current Client Call')));
      
   } // testTaskCreation
   
} // class TaskCheckRecordTypeTest