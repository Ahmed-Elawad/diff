/* 
 * Test Methods for GroupMemberHelper
 *
 * History
 * -------
   07/19/2019 Dan Carmen        Created.
   10/21/2022 Dan Carmen        Add getActiveUserIds method
 
 */
@isTest
private class GroupMemberHelperTest {

   static testMethod void testGroupMembers() {
      Group[] queues = [Select Id, Name from Group where Type = 'Queue' limit 3];
      
      // create assignment group name
      Assignment_Group_Name__c agn1 = new Assignment_Group_Name__c(Name=queues[0].Name);
      Assignment_Group_Name__c agn2 = new Assignment_Group_Name__c(Name=queues[1].Name);
      Assignment_Group_Name__c agn3 = new Assignment_Group_Name__c(Name=queues[2].Name);
      Assignment_Group_Name__c[] grps = new Assignment_Group_Name__c[]{agn1,agn2,agn3};
      insert grps;
      GroupMemberHelper.SKIP_FUTURE=true;
       
      Assignment_Group_Queues__c agq1 = new Assignment_Group_Queues__c(Name=queues[0].Name, QueueId__c=queues[0].Id, Active__c='True', Assignment_Group_Name__c=agn1.Id);
      Assignment_Group_Queues__c agq2 = new Assignment_Group_Queues__c(Name=queues[1].Name, QueueId__c=queues[1].Id, Active__c='True', Assignment_Group_Name__c=agn2.Id);
      Assignment_Group_Queues__c agq3 = new Assignment_Group_Queues__c(Name=queues[2].Name, QueueId__c=queues[2].Id, Active__c='True', Assignment_Group_Name__c=agn3.Id);
      insert new Assignment_Group_Queues__c[]{agq1,agq2,agq3};
      
      User[] usrs = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 6];
      Assignment_Groups__c gm1 = new Assignment_Groups__c(Group_Name__c=agn1.Id, User__c=usrs[0].Id, Active__c='True');
      Assignment_Groups__c gm2 = new Assignment_Groups__c(Group_Name__c=agn1.Id, User__c=usrs[1].Id, Active__c='False');
      Assignment_Groups__c gm3 = new Assignment_Groups__c(Group_Name__c=agn1.Id, User__c=usrs[2].Id, Active__c='False');
      Assignment_Groups__c gm4 = new Assignment_Groups__c(Group_Name__c=agn2.Id, User__c=usrs[3].Id, Active__c='False');
      Assignment_Groups__c gm5 = new Assignment_Groups__c(Group_Name__c=agn3.Id, User__c=usrs[4].Id, Active__c='True');
      Assignment_Groups__c gm6 = new Assignment_Groups__c(Group_Name__c=agn3.Id, User__c=usrs[5].Id, Active__c='True');
      Assignment_Groups__c[] grpMembers = new Assignment_Groups__c[]{gm1,gm2,gm3,gm4,gm5,gm6};
      insert grpMembers;
      
      Map<Id,Assignment_Group_Name__c> grpMap = new Map<Id,Assignment_Group_Name__c>([Select Id, Name, ActiveUsers__c, TotalUsers__c from Assignment_Group_Name__c]);
      System.assertEquals(3,grpMap.size());
      agn1=grpMap.get(agn1.Id);
      System.assertEquals(3,agn1.TotalUsers__c);
      System.assertEquals(1,agn1.ActiveUsers__c);

      GroupMemberHelper.USE_CACHE=true;
      Set<Id> userIds = GroupMemberHelper.getActiveUserIds(queues[0].Id);
      System.assertEquals(1,userIds.size());

      agn2=grpMap.get(agn2.Id);
      System.assertEquals(1,agn2.TotalUsers__c);
      System.assertEquals(0,agn2.ActiveUsers__c);
      userIds = GroupMemberHelper.getActiveUserIds(queues[1].Id);
      System.assertEquals(0,userIds.size());
       
      agn3=grpMap.get(agn3.Id);
      System.assertEquals(2,agn3.TotalUsers__c);
      System.assertEquals(2,agn3.ActiveUsers__c);
      userIds = GroupMemberHelper.getActiveUserIds(queues[2].Id);
      System.assertEquals(2,userIds.size());
      
      delete gm4;
      grpMap = new Map<Id,Assignment_Group_Name__c>([Select Id, Name, ActiveUsers__c, TotalUsers__c from Assignment_Group_Name__c]);
      
      agn2=grpMap.get(agn2.Id);
      System.assertEquals(0,agn2.TotalUsers__c);
      System.assertEquals(0,agn2.ActiveUsers__c);

      undelete gm4;
      grpMap = new Map<Id,Assignment_Group_Name__c>([Select Id, Name, ActiveUsers__c, TotalUsers__c from Assignment_Group_Name__c]);
      
      agn2=grpMap.get(agn2.Id);
      System.assertEquals(1,agn2.TotalUsers__c);
      System.assertEquals(0,agn2.ActiveUsers__c);
      
      gm4.Active__c='True';
      
      GroupMemberHelper.SKIP_FUTURE=false;
      Test.startTest();
      update gm4;
      Test.stopTest();
      grpMap = new Map<Id,Assignment_Group_Name__c>([Select Id, Name, ActiveUsers__c, TotalUsers__c from Assignment_Group_Name__c]);
      
      agn2=grpMap.get(agn2.Id);
      System.assertEquals(1,agn2.TotalUsers__c);
      System.assertEquals(1,agn2.ActiveUsers__c);
      // this will test if it's using the cache
      userIds = GroupMemberHelper.getActiveUserIds(queues[1].Id);
      System.assertEquals(0,userIds.size());
      GroupMemberHelper.USE_CACHE=false;
      userIds = GroupMemberHelper.getActiveUserIds(queues[1].Id);
      System.assertEquals(1,userIds.size());

   } // testGroupMembers
} // class GroupMemberHelperTest