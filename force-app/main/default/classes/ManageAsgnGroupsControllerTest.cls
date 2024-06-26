/* 
 * Test methods for the ManageAsgnGroupsController class
 *
 * History
 * -------
 * 08/11/2011 Dan Carmen        Created.
   08/28/2013 Dan Carmen        Added debugging, increased API version to 28
   06/27/2017 Jacob Hinds       Created Role Hierarchy test method
   11/10/2017 Lynn Michels		Changed query to not use CORE SALES since that Role was deleted
   01/15/2018 Jake Hinds		Changing Scheduler fields from text to time.  Adding ability to toggle night/weekend weighting and copy schedule.
   06/08/2020 Dan Carmen        Change to use a Label for the one role name
   11/30/2023 Dan Carmen        Remove unused assignment group fields.
   12/23/2023 Dan Carmen        Clean up code to use the Time field on the VF page instead of picklist

 */
@isTest
private class ManageAsgnGroupsControllerTest {
   @testSetup
   public static void setupData() {
        Group grp1 = new Group(Name='MAGR Queue 1',Type='Queue');
        Group grp2 = new Group(Name='MAGR Queue 2',Type='Queue');
        Group grp3 = new Group(Name='MAGR Queue 3',Type='Queue');
        Group grp4 = new Group(Name='MAGR Queue 4',Type='Queue');
        Group[] grps = new Group[]{grp1,grp2,grp3,grp4};
        insert grps;
   } // setupData
    
    public static Map<String,Group> getTestQueues() {
       Map<String,Group> grpMap = new Map<String,Group>();
       Group[] grps = [Select Id, Name, Type 
                         From Group
                        Where Name like 'MAGR%' and Type='Queue'];
       for (Group grp : grps) {
          grpMap.put(grp.Name, grp);
       }
       return grpMap;
    } // getTestQueues

   /** Test as a System Administrator User. */
   static testMethod void testSystemAdmin() {
      Integer numberUsers = 4;
      // create queue
      Map<String,Group> grpMap = getTestQueues();
      Group grp1 = grpMap.get('MAGR Queue 1');
      Group grp2 = grpMap.get('MAGR Queue 2');
      
      // set up 2 assignment groups
      Assignment_Group_Name__c agn1 = new Assignment_Group_Name__c(Name=grp1.Name,Use_Scheduler__c=true,Use_Weighting__c=true);
      Assignment_Group_Name__c agn2 = new Assignment_Group_Name__c(Name=grp2.Name,Use_Scheduler__c=true,Use_Weighting__c=true);
      Assignment_Group_Name__c[] agns = new Assignment_Group_Name__c[]{agn1,agn2};
      insert agns;
      
      Assignment_Group_Queues__c agq1 = new Assignment_Group_Queues__c(Name=grp1.Name, Assignment_Group_Name__c=agn1.Id); 
      Assignment_Group_Queues__c agq2 = new Assignment_Group_Queues__c(Name=grp2.Name, Assignment_Group_Name__c=agn2.Id);
      Assignment_Group_Queues__c[] agqs = new Assignment_Group_Queues__c[]{agq1,agq2};
      insert agqs;
      
      // add a couple of users to each queue
      User[] users = [Select Id, Name, Email from User where IsActive=true and Assignment_Group_Active__c=true limit :numberUsers];
      Assignment_Groups__c[] assignGrps = new Assignment_Groups__c[]{};
      for (User u : users) {
         Assignment_Groups__c ag1 = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn1.Id,User__c=u.Id);
         assignGrps.add(ag1);
         Assignment_Groups__c ag2 = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn2.Id,User__c=u.Id);
         assignGrps.add(ag2);
      } // for (User u
      insert assignGrps;
            
      User u1 = [Select Id, Name from User where Profile.Name='System Administrator' and IsActive=true limit 1];
      System.runAs(u1) {
         ManageAsgnGroupsController magc = new ManageAsgnGroupsController();
         System.assertEquals(true,magc.isSystemAdmin);
         // makes sure the user has groups
         System.assertEquals(true,magc.hasGroups);
         List<SelectOption> options = magc.groupOptions;
         // make sure at least two in the list
         System.assertEquals(true,options.size()>=2);
         // select one of our groups we created
         magc.selectedGroupId = agn2.Id;
         // make the selection
         System.assertEquals(null,magc.changeGroup());
         // make sure the selected group is set
         System.assertEquals(agn2.Id,magc.selectedGroup.Id);
         System.assertEquals(true,magc.hasMembers);
         System.assertEquals(true,magc.hasQueue);
         // verify the number of members
         System.assertEquals(numberUsers,magc.memberList.size());
         
         //give user a schedule but the user is inactive so a warning message should appear
         magc.memberList[0].groupMember.Active__c = 'False';
         magc.memberList[0].groupMember.Monday_1__c = Time.newInstance(8,15,0,0);
         magc.memberList[0].groupMember.Monday_2__c = Time.newInstance(12,0,0,0);
         magc.memberList[0].groupMember.Tuesday_1__c = Time.newInstance(9,0,0,0);
         magc.memberList[0].groupMember.Tuesday_2__c = Time.newInstance(12,45,0,0);
         magc.memberList[0].groupMember.Wednesday_1__c = Time.newInstance(7,30,0,0);
         magc.memberList[0].groupMember.Wednesday_2__c = Time.newInstance(16,15,0,0);
         magc.memberList[0].groupMember.Thursday_1__c = Time.newInstance(8,15,0,0);
         magc.memberList[0].groupMember.Thursday_2__c = Time.newInstance(18,45,0,0);
         magc.memberList[0].groupMember.Friday_1__c = Time.newInstance(8,0,0,0);
         magc.memberList[0].groupMember.Friday_2__c = Time.newInstance(12,15,0,0);
         magc.memberList[0].groupMember.Saturday_1__c = Time.newInstance(6,30,0,0);
         magc.memberList[0].groupMember.Saturday_2__c = Time.newInstance(18,15,0,0);
         magc.memberList[0].groupMember.Sunday_1__c = Time.newInstance(9,45,0,0);
         magc.memberList[0].groupMember.Sunday_2__c = Time.newInstance(12,15,0,0);   
         
         magc.saveSchedule();
         
         List<Apexpages.Message> msgs = ApexPages.getMessages();
         boolean saveWarning = false;
         Integer latestMsg = msgs.size()-1;
         //if (msgs[latestMsg].getDetail().contains('Schedule saved, but one or more users are inactive')) saveWarning = true;
         //system.debug('message: '+msgs);
         //system.assert(saveWarning);
         
         //update start times to be before end times.  Should save with the confirm message
         magc.memberList[0].groupMember.Active__c = 'True';
         magc.memberList[0].groupMember.Monday_1__c = Time.newInstance(9,15,0,0);
         magc.memberList[0].groupMember.Monday_2__c = Time.newInstance(16,0,0,0);
         magc.memberList[0].groupMember.Tuesday_1__c = Time.newInstance(8,0,0,0);
         magc.memberList[0].groupMember.Tuesday_2__c = Time.newInstance(13,45,0,0);
         magc.memberList[0].groupMember.Wednesday_1__c = Time.newInstance(6,30,0,0);
         magc.memberList[0].groupMember.Wednesday_2__c = Time.newInstance(15,15,0,0);
         magc.memberList[0].groupMember.Thursday_1__c = Time.newInstance(9,15,0,0);
         magc.memberList[0].groupMember.Thursday_2__c = Time.newInstance(17,45,0,0);
         magc.memberList[0].groupMember.Friday_1__c = Time.newInstance(9,0,0,0);
         magc.memberList[0].groupMember.Friday_2__c = Time.newInstance(13,15,0,0);
         magc.memberList[0].groupMember.Saturday_1__c = Time.newInstance(5,30,0,0);
         magc.memberList[0].groupMember.Saturday_2__c = Time.newInstance(17,15,0,0);
         magc.memberList[0].groupMember.Sunday_1__c = Time.newInstance(10,45,0,0);
         magc.memberList[0].groupMember.Sunday_2__c = Time.newInstance(13,15,0,0);   
         
          magc.saveSchedule();
         
         msgs = ApexPages.getMessages();
         boolean saveSuccess = false;
         latestMsg = msgs.size()-1;
         if (msgs[latestMsg].getDetail().contains('Schedule Saved')) saveSuccess = true;
         system.debug('message: '+msgs);
         system.assert(saveSuccess);

         //List<SelectOption> weightingOptions = ;
         system.assert(magc.weightingOptions!=null);
         system.assertEquals(true,magc.isWeighted);
         
         
         
         system.assertEquals(true,magc.useScheduler);
         //List<SelectOption> times = magc.getTimes();
         //system.assert(times!=null);
         
         // select all of the records
         magc.selectAll = true;
         System.assertEquals(null,magc.selectAllMembers());
         // verify all are selected
         for (ManageAsgnGroupsController.SelectorWrap sw : magc.memberList) {
            System.assertEquals(true,sw.selected);
         }
         // deselect all of the records
         magc.selectAll = false;
         System.assertEquals(null,magc.selectAllMembers());
         // verify all are selected
         for (ManageAsgnGroupsController.SelectorWrap sw : magc.memberList) {
            System.assertEquals(false,sw.selected);
         }
         // select all of the records again
         magc.selectAll = true;
         System.assertEquals(null,magc.selectAllMembers());
         // verify all are selected
         for (ManageAsgnGroupsController.SelectorWrap sw : magc.memberList) {
            System.assertEquals(true,sw.selected);
         }

         // verify all are currently active
         for (ManageAsgnGroupsController.SelectorWrap sw : magc.memberList) {
            System.assertEquals('True',sw.groupMember.Active__c);
         }
         // set all to inactive
         System.CurrentPageReference().getParameters().put('actionType','active');
         System.assertEquals(null,magc.processAllSelected());
         // verify all are set to inactive
         for (ManageAsgnGroupsController.SelectorWrap sw : magc.memberList) {
            System.assertEquals('False',sw.groupMember.Active__c);
         }
         
         // set all people to manage group
         // select all of the records again
         magc.selectAll = true;
         System.assertEquals(null,magc.selectAllMembers());
         System.CurrentPageReference().getParameters().put('actionType','manageGroup');
         System.assertEquals(null,magc.processAllSelected());
         // verify all are set to manage
         for (ManageAsgnGroupsController.SelectorWrap sw : magc.memberList) {
            System.assertEquals(true,sw.groupMember.Manage_Group__c);
         }
         
         // delete all records
         // select all of the records again
         magc.selectAll = true;
         System.assertEquals(null,magc.selectAllMembers());
         System.CurrentPageReference().getParameters().put('actionType','delete');
         System.assertEquals(null,magc.processAllSelected());
         
         // there should now be no group members
         System.assertEquals(false,magc.hasMembers);
         
      } // System.runAs
   } // testSystemAdmin
   
   /** Test as a Non System Administrator User. */
   static testMethod void testNonSystemAdmin() {
      Integer numberUsers = 4;
      // create queue
      Map<String,Group> grpMap = getTestQueues();
      Group grp1 = grpMap.get('MAGR Queue 1');
      Group grp2 = grpMap.get('MAGR Queue 2');
      
      // set up 2 assignment groups
      Assignment_Group_Name__c agn1 = new Assignment_Group_Name__c(Name=grp1.Name);
      Assignment_Group_Name__c agn2 = new Assignment_Group_Name__c(Name=grp2.Name);
      Assignment_Group_Name__c[] agns = new Assignment_Group_Name__c[]{agn1,agn2};
      insert agns;
      
      Assignment_Group_Queues__c agq1 = new Assignment_Group_Queues__c(Name=grp1.Name, Assignment_Group_Name__c=agn1.Id); 
      Assignment_Group_Queues__c agq2 = new Assignment_Group_Queues__c(Name=grp2.Name, Assignment_Group_Name__c=agn2.Id);
      Assignment_Group_Queues__c[] agqs = new Assignment_Group_Queues__c[]{agq1,agq2};
      insert agqs;
      
      // the user we'll be running as
      //User u1 = [Select Id, Name from User where Profile.Name = '2008-09 Operations Administration' and IsActive=true and Assignment_Group_Active__c=true limit 1];
      User u1 = [Select Id, Name from User where Profile.Name = 'System Administrator' and IsActive=true and Assignment_Group_Active__c=true limit 1];

      // add a couple of users to each queue
      User[] users = [Select Id, Name from User where IsActive=true and Assignment_Group_Active__c=true and Id != :u1.Id limit :numberUsers];
      Assignment_Groups__c[] assignGrps = new Assignment_Groups__c[]{};
      for (User u : users) {
         Assignment_Groups__c ag1 = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn1.Id,User__c=u.Id);
         assignGrps.add(ag1);
         Assignment_Groups__c ag2 = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn2.Id,User__c=u.Id);
         assignGrps.add(ag2);
      } // for (User u
      insert assignGrps;
      assignGrps.clear();
      
      System.runAs(u1) {
         ManageAsgnGroupsController magc = new ManageAsgnGroupsController();
         System.assertEquals(true,magc.isSystemAdmin);
         // makes sure the user has groups
         //System.assertEquals(false,magc.hasGroups);
      }
      // add the user to both groups
      Assignment_Groups__c ag1 = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn1.Id,User__c=u1.Id,Manage_Group__c=true);
      assignGrps.add(ag1);
      Assignment_Groups__c ag2 = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn2.Id,User__c=u1.Id,Manage_Group__c=true);
      assignGrps.add(ag2);

      insert assignGrps;
      // add 1 to account for our running user
      numberUsers++;
      
      System.runAs(u1) {
         ManageAsgnGroupsController magc = new ManageAsgnGroupsController();
         System.assertEquals(true,magc.isSystemAdmin);
         // makes sure the user has groups
         System.assertEquals(true,magc.hasGroups);
         List<SelectOption> options = magc.groupOptions;
         // make sure at least two in the list
         System.assertEquals(true,options.size()>=2);
         // select one of our groups we created
         magc.selectedGroupId = agn2.Id;
         // make the selection
         System.assertEquals(null,magc.changeGroup());
         // make sure the selected group is set
         System.assertEquals(agn2.Id,magc.selectedGroup.Id);
         System.assertEquals(true,magc.hasMembers);
         System.assertEquals(true,magc.hasQueue);
         // verify the number of members
         System.assertEquals(numberUsers,magc.memberList.size());
         
         // set one to inactive
         System.CurrentPageReference().getParameters().put('actionType','active');
         System.CurrentPageReference().getParameters().put('memberId',magc.memberList.get(0).groupMember.Id);
         System.assertEquals(null,magc.processOneRecord());
         // verify the record is inactive
         System.assertEquals('False',magc.memberList.get(0).groupMember.Active__c);
         
         Id delUserId = magc.memberList.get(0).groupMember.User__c;
         
         // delete one record
         System.CurrentPageReference().getParameters().put('actionType','delete');
         System.CurrentPageReference().getParameters().put('memberId',magc.memberList.get(0).groupMember.Id);

         System.assertEquals(null,magc.processOneRecord());
         
         // the list should be one less
         System.assertEquals((numberUsers-1),magc.memberList.size());
         
         // add with no value
         magc.newMember.User__c = null;
         System.assertEquals(null,magc.addNewMember());
         System.assertEquals(true,ApexPages.hasMessages());
         
         // add a user back in
         magc.newMember.User__c = delUserId;
         System.assertEquals(null,magc.addNewMember());
         // should be back to the same number.
         System.assertEquals(numberUsers,magc.memberList.size());
         
      } // System.runAs
   } // testNonSystemAdmin
   static testMethod void testRoleHierarchy(){
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User parentUser;
        system.runAs(runningUser){
            UserRole sysAdminRole = [SELECT Id FROM UserRole WHERE Name = 'System Administrator' LIMIT 1];
            Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
            
            /*UserRole parentRole = new UserRole(Name='ParentRole',ParentRoleId = sysAdminRole.Id);
            insert parentRole;
            UserRole childRole = new UserRole(Name='ChildRole',ParentRoleId = parentRole.Id);
            UserRole miscRole = new UserRole(Name='MiscRole');
            UserRole[]roles = new UserRole[]{childRole,miscRole};
            insert roles;
            UserRole miscRole = [SELECT Id FROM UserRole WHERE Name = 'Virtual Sales And NSS'];
            UserRole childRole = [SELECT Id,ParentRoleId FROM UserRole WHERE Name = 'Core Sales'];
            Id parentRoleId = childRole.ParentRoleId;*/
            parentUser = [SELECT Id FROM User WHERE IsActive=true AND ProfileId != :sysAdminProfile.Id AND UserRole.Name = 'Senior VP Sales' LIMIT 1];
            User childUser = [SELECT Id FROM User WHERE IsActive=true AND ProfileId != :sysAdminProfile.Id AND UserRole.Name = :Label.UserHelperTest_RoleMapTest limit 1]; //'CORE AVP - WEST' LIMIT 1];
            User miscUser = [SELECT Id FROM User WHERE IsActive=true AND ProfileId != :sysAdminProfile.Id AND UserRole.Name = 'SVP Operations' LIMIT 1];
            User[] users = new User[]{parentUser,childUser,miscUser}; 
            
            /*users = [SELECT Id FROM User WHERE IsActive=true AND Assignment_Group_Active__c=true LIMIT 4];
            users[0].UserRoleId=parentRoleId;
            users[1].UserRoleId=childRole.Id;
            users[2].UserRoleId=childRole.Id;
            users[3].UserRoleId=miscRole.Id; 
            update users;*/
    
            Map<String,Group> grpMap = getTestQueues();
            Group grp = grpMap.get('MAGR Queue 1');
            
            Assignment_Group_Name__c agn = new Assignment_Group_Name__c(Name=grp.Name,Use_Role_Hierarchy__c = true);
            insert agn;
                    
            Assignment_Group_Queues__c agq = new Assignment_Group_Queues__c(Name=grp.Name, Assignment_Group_Name__c=agn.Id); 
            insert agq;
            
            Assignment_Groups__c[] grpMembers = new Assignment_Groups__c[]{};
            for(User u:users){
                Assignment_Groups__c grpMember = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn.Id,User__c=u.Id,Manage_Group__c=true);
                grpMembers.add(grpMember);
            }
            insert grpMembers;
        }
        Test.startTest();
        system.runAs(parentUser){
            ManageAsgnGroupsController magc = new ManageAsgnGroupsController();
            system.assertEquals(true,magc.hasMembers);
            system.assertEquals(2,magc.memberList.size());
        }
        Test.stopTest();
   }
   static testMethod void testCopySchedule(){
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User[] extraUsers = [SELECT Id,ManagerId FROM User WHERE Profile.Name = 'System Administrator' AND Id != :runningUser.Id AND IsActive=true LIMIT 2];
        Map<String,Group> grpMap = getTestQueues();
        Group grp1 = grpMap.get('MAGR Queue 1');
        Group grp2 = grpMap.get('MAGR Queue 2');
        Group grp3 = grpMap.get('MAGR Queue 3');
        Group grp4 = grpMap.get('MAGR Queue 4');
        
        Assignment_Group_Name__c agn1 = new Assignment_Group_Name__c(Name=grp1.Name,Use_Scheduler__c=true);
        Assignment_Group_Name__c agn2 = new Assignment_Group_Name__c(Name=grp2.Name,Use_Scheduler__c=true);
        Assignment_Group_Name__c agn3 = new Assignment_Group_Name__c(Name=grp3.Name,Use_Scheduler__c=true);
        Assignment_Group_Name__c agn4 = new Assignment_Group_Name__c(Name=grp4.Name,Use_Scheduler__c=true);
        Assignment_Group_Name__c[] agns = new Assignment_Group_Name__c[]{agn1,agn2,agn3,agn4};
        insert agns;
                
        Assignment_Group_Queues__c agq1 = new Assignment_Group_Queues__c(Name=grp1.Name, Assignment_Group_Name__c=agn1.Id); 
        Assignment_Group_Queues__c agq2 = new Assignment_Group_Queues__c(Name=grp2.Name, Assignment_Group_Name__c=agn2.Id);
        Assignment_Group_Queues__c agq3 = new Assignment_Group_Queues__c(Name=grp3.Name, Assignment_Group_Name__c=agn3.Id);
        Assignment_Group_Queues__c agq4 = new Assignment_Group_Queues__c(Name=grp4.Name, Assignment_Group_Name__c=agn4.Id);
        Assignment_Group_Queues__c[] agqs = new Assignment_Group_Queues__c[]{agq1,agq2,agq3,agq4};
        insert agqs;
        
        Assignment_Groups__c ag1 = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn1.Id,User__c=runningUser.Id,Monday_1__c=Time.newInstance(9,15,0,0),Monday_2__c=Time.newInstance(12,15,0,0));
     	Assignment_Groups__c ag2 = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn2.Id,User__c=runningUser.Id);
     	Assignment_Groups__c ag3a = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn3.Id,User__c=extraUsers[0].Id,Tuesday_1__c=Time.newInstance(9,15,0,0),Tuesday_2__c=Time.newInstance(12,15,0,0));
     	Assignment_Groups__c ag3b = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn3.Id,User__c=extraUsers[1].Id);
     	Assignment_Groups__c ag4a = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn4.Id,User__c=extraUsers[0].Id,Tuesday_1__c=Time.newInstance(9,15,0,0),Tuesday_2__c=Time.newInstance(12,15,0,0));
     	Assignment_Groups__c ag4b = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn4.Id,User__c=extraUsers[1].Id);
        Assignment_Groups__c[] grpMembers = new Assignment_Groups__c[]{ag1,ag2,ag3a,ag3b,ag4a,ag4b};
        insert grpMembers;
        
        Test.startTest();
        ManageAsgnGroupsController magc = new ManageAsgnGroupsController();
        //should be none, all, runningUser
        system.assertEquals(3,magc.memberCopyList.size());
        //select running user to copy
        magc.selectedCopyMember = magc.memberCopyList[2].getValue();
        magc.copySchedule();
        Assignment_Groups__c uAg2 = [SELECT Id,Monday_1__c,Monday_2__c FROM Assignment_Groups__c WHERE Id = :ag2.Id];
        system.assertEquals(ag1.Monday_1__c,uAg2.Monday_1__c);
        system.assertEquals(ag1.Monday_2__c,uAg2.Monday_2__c);
        magc.selectedGroupId = agn3.Id;
        magc.changeGroup();
        //should be none, all, extraUser1, extraUser2
        system.assertEquals(4,magc.memberCopyList.size());
        //select ALL to copy
        magc.selectedCopyMember = magc.memberCopyList[1].getValue();
        magc.copySchedule();
        Assignment_Groups__c uAg4a = [SELECT Id,Tuesday_1__c,Tuesday_2__c FROM Assignment_Groups__c WHERE Id = :ag4a.Id];
        Assignment_Groups__c uAg4b = [SELECT Id,Tuesday_1__c,Tuesday_2__c FROM Assignment_Groups__c WHERE Id = :ag4b.Id];
        system.assertEquals(ag3a.Tuesday_1__c,uAg4a.Tuesday_1__c);
        system.assertEquals(ag3a.Tuesday_2__c,uAg4a.Tuesday_2__c);
        system.assertEquals(ag3b.Tuesday_1__c,uAg4b.Tuesday_1__c);
        system.assertEquals(ag3b.Tuesday_2__c,uAg4b.Tuesday_2__c);
        Test.stopTest();
   }
   static testMethod void testManagerFilter(){
        User runningUser = [SELECT Id,ManagerId FROM User WHERE Id = :UserInfo.getUserId()];
        User secondUser = [SELECT Id,ManagerId FROM User WHERE Profile.Name = 'System Administrator' AND Id != :runningUser.Id AND IsActive=true AND ManagerId!= null AND ManagerId!= :runningUser.ManagerId LIMIT 1];
        Map<Id,Id> userByManagerId = new Map<Id,Id>{runningUser.managerId => runningUser.Id,secondUser.managerId => secondUser.Id};
        Map<String,Group> grpMap = getTestQueues();
        Group grp1 = grpMap.get('MAGR Queue 1');
        
        Assignment_Group_Name__c agn1 = new Assignment_Group_Name__c(Name='MAGR 1',Use_Scheduler__c=true,Use_Manager_Filter__c=true);
        insert agn1;
                
        Assignment_Group_Queues__c agq1 = new Assignment_Group_Queues__c(Name='MAGR Queue 1', Assignment_Group_Name__c=agn1.Id); 
        insert agq1;
        
        Assignment_Groups__c ag1 = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn1.Id,User__c=runningUser.Id);
     	Assignment_Groups__c ag2 = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn1.Id,User__c=secondUser.Id);
        Assignment_Groups__c[] grpMembers = new Assignment_Groups__c[]{ag1,ag2};
        insert grpMembers;
        
        Test.startTest();
        ManageAsgnGroupsController magc = new ManageAsgnGroupsController();
        //filter should be none, user1 mgr, user2 mgr. user list should be user1,user2
        system.assertEquals(3,magc.managerIdList.size());
        system.assertEquals(2,magc.memberList.size());
        //set filter to manager 1, list should be user1
        magc.managerFilterId = magc.managerIdList[1].getValue();
        system.debug('magc.managerIdList'+magc.managerIdList);
        system.debug('manager1 '+magc.memberList[0].groupMember.User__r.ManagerId+' manager2 '+magc.memberList[1].groupMember.User__r.ManagerId);
        magc.changeManager();
        system.assertEquals(1,magc.memberList.size());
        system.assertEquals(userByManagerId.get(magc.managerFilterId),magc.memberList[0].groupMember.User__c);
        //set filter to manager 2, list should be user2
        magc.managerFilterId = magc.managerIdList[2].getValue();
        magc.changeManager();
        system.assertEquals(1,magc.memberList.size());
        system.assertEquals(userByManagerId.get(magc.managerFilterId),magc.memberList[0].groupMember.User__c);
        //set filter to none, list should be back to both users
        magc.managerFilterId = magc.managerIdList[0].getValue();
        magc.changeManager();
        system.assertEquals(2,magc.memberList.size());
        Test.stopTest();
   }
} // class ManageAsgnGroupsControllerTest