/* Test methods for the ChatterMethods class
   
  History
  -------
  04/11/2012 Dan Carmen   Created
  06/28/2012 Dan Carmen   Modified to use JobHelper class
  10/29/2018 Dan Carmen   Increment API to version 44
  
 */
@isTest
private class ChatterMethodsTest {

   /** Verify the validation works when inserting a record
    */
   static testMethod void testGroupCreation() {
    // the number of groups to create
    Integer nbrGrps = 5;
    // test normal case - create multiple groups
    Chatter_Group_Setup__c[] chatGrps = new Chatter_Group_Setup__c[]{};
      for (Integer cnt=1; cnt<=nbrGrps; cnt++) {
         Chatter_Group_Setup__c cgs = new Chatter_Group_Setup__c();
         cgs.Name = 'Test Group '+cnt;
         cgs.Type__c = 'Private';
         chatGrps.add(cgs);
      } // for (Integer cnt
      
      insert chatGrps;
      // verify id is set on all and groups actually exist
      Id[] chatGrpIds = new Id[]{};
      for (Chatter_Group_Setup__c cgs : chatGrps) {
         chatGrpIds.add(cgs.Id);
      }
      chatGrps = [Select Id, Name
                        ,ChatterGroupId__c
                        ,IsActive__c
                        ,Manager_Profiles__c
                        ,Owner_Profile__c
                        ,Selected_Profiles__c
                        ,Type__c
                    from Chatter_Group_Setup__c
                   Where id in :chatGrpIds];
      // should be same number
      System.assertEquals(chatGrpIds.size(), chatGrps.size());
      for (Chatter_Group_Setup__c cgs : chatGrps) {
        // these ids should be null upon creation
         System.assertEquals(true,(cgs.ChatterGroupId__c == null));
      }
      // verify the number matches what we sent in
      System.assertEquals(nbrGrps,chatGrps.size());
      // verify no CollaborationGroups are created
      System.assertEquals(0,[Select count() from CollaborationGroup /*where Id in :collabGrpIds*/]);
      
      // create a Chatter group to see if the process matches
      CollaborationGroup cg = new CollaborationGroup(Name='Test Already Created', CollaborationType='Private');
      insert cg;
      
      // verify new group is created
      System.assertEquals(1,[Select count() from CollaborationGroup /*where Id in :collabGrpIds*/]);
      
      // try to create two groups with the same name - that was previously used.
      Chatter_Group_Setup__c newCgs1 = new Chatter_Group_Setup__c(Name='Test Group 1', Type__c='Private');
      Chatter_Group_Setup__c newCgs2 = new Chatter_Group_Setup__c(Name='Test Group 1', Type__c='Private');
      Chatter_Group_Setup__c newCgs3 = new Chatter_Group_Setup__c(Name='Test Already Created', Type__c='Private');
      chatGrps = new Chatter_Group_Setup__c[]{newCgs1,newCgs2, newCgs3};
      // both of these should fail
      Database.SaveResult[] results = Database.insert(chatGrps,false);
      // a record already has this name
      checkResult(results.get(0),'A record is already saved with the name');
      // can't have two records with the same name in the grouping
      checkResult(results.get(1),'There is more than one record with the Name');
      // the third should be successful
      Database.SaveResult result3 = results.get(2);
      System.assertEquals(true,result3.isSuccess());
      // check that the CollaborationGroup id is set on the Chatter_Group_Setup__c record
      newCgs3 = [Select Id, Name, ChatterGroupId__c from Chatter_Group_Setup__c where id=:newCgs3.Id];
      System.assertEquals(cg.Id,newCgs3.ChatterGroupId__c);
      
   } // testGroupCreation
   
   private static void checkResult(Database.SaveResult result, String checkStr) {
      System.assertEquals(false,result.isSuccess());
      String errorStr = '';
      for (Database.Error err : result.getErrors()) {
         errorStr += err.getMessage();
      }
      System.debug('checkResult compare checkStr='+checkStr+' errorStr='+errorStr);
      System.assertEquals(true,errorStr.contains(checkStr));
   } // checkResult
   
   /** Verify the validation works when inserting a record
    */
   static testMethod void testOther() {
    Chatter_Group_Setup__c cgs = new Chatter_Group_Setup__c(Name='Test Name',ChatterGroupId__c='BadId');
    ChatterMethods cm = new ChatterMethods();
    //System.assertEquals(false,cm.checkForGroupMembers(cgs));
    //System.assertEquals(true,cm.emailErrors.contains('Could not find a CollaborationGroup with Id=BadId'));
    
    // test bad role name
    cgs.Owner_Role__c = 'BadRoleName';
    cgs.Use_Owner__c = true;
    System.assertEquals(true,cm.checkForGroupMembers(cgs));
    
    // get a User to test with
    User testU = [Select Id, Name, Profile.Name, UserRole.Name from User where IsActive=true and Id != :UserInfo.getUserId() limit 1];
   } // testOther

   /** Test creating a group and adding members to it. 
    */
   static testMethod void testAddMembers() {
      // get some test users
      Map<String,User[]> userMap = OrgUnitMethodsTest.getTestUsers(5);
      // create some test cost centers
      Org_Unit__c[] costCenters = OrgUnitMethodsTest.createCostCenters(userMap.keySet());
      
      // create two groups - a parent and child
      Chatter_Group_Setup__c cgsChild = new Chatter_Group_Setup__c(Name='Test Child Group', Type__c='Private',IsActive__c=true);
      Chatter_Group_Setup__c cgsParent = new Chatter_Group_Setup__c(Name='Test Parent Group', Type__c='Private',IsActive__c=true);
      Chatter_Group_Setup__c[] grps = new Chatter_Group_Setup__c[]{cgsChild,cgsParent};
      insert grps;
      
      // update the child with the org units
      // create an org unit string
      String orgUnitStr = '';
      for (Org_Unit__c ou : costCenters) {
        if (orgUnitStr.length() > 0) {
           orgUnitStr += ';';
        }
        orgUnitStr += ou.Name;
      } // for
      
      System.debug('orgUnitStr='+orgUnitStr);
      
      cgsChild.Org_Units__c = orgUnitStr;
      
      // update the parent with the child
      cgsParent.Child_Groups__c = cgsChild.Name;
      
      // links should be created for parent and child.
      update grps;
      
      // verify links are created
      System.assertEquals(1,[select count() from Chatter_Group_Link__c where Child_Group__c=:cgsChild.Id and Parent_Group__c=:cgsParent.Id]);
      
      System.assertEquals(costCenters.size(), [select count() from Chatter_Group_Org_Link__c where Chatter_Group_Setup__c=:cgsChild.Id]);
      

      
      // select profiles using the ChatterGroupSetupController - provides tests for this also
      Test.SetCurrentPageReference(Page.ChatterGroupSetup);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(cgsChild);
      System.CurrentPageReference().getParameters().put('id',cgsChild.Id);
      ChatterGroupSetupController cgsc = new ChatterGroupSetupController(sc1);
      
      System.assertEquals(0,cgsc.selectedProfiles.size());
      System.assertEquals(0,cgsc.managerProfiles.size());
      // should be at least one record to choose from
      System.assertEquals(true,cgsc.profileOptions.size() > 0);

      // used to check the profiles
      String[] profileCheck = new String[]{};      
      // select all of the profiles for selected, and first for manager and owner
      for (Integer cnt=0; cnt<cgsc.profileOptions.size(); cnt++) {
         SelectOption so = cgsc.profileOptions.get(cnt);
         if (cnt == 0) {
            cgsc.managerProfiles.add(so.getValue());
            //cgsc.cgs.Owner_Profile__c = so.getValue();
         }
         cgsc.selectedProfiles.add(so.getValue());
         profileCheck.add(so.getValue());
      } // for (Integer
      
      // save the record
      PageReference pr = cgsc.save();
      System.assertEquals('/'+cgsChild.Id,pr.getUrl());
      
      // verify selected profiles
      cgsChild = [Select Id, Name, Type__c, IsActive__c, Owner_Profile__c, Selected_Profiles__c, Manager_Profiles__c from Chatter_Group_Setup__c where Id = :cgsChild.Id];
      // verify all profiles are included in the String
      for (String prof : profileCheck) {
         System.assertEquals(true,cgsChild.Selected_Profiles__c.contains(prof));
      }
      
      // run the batch process
      ChatterBatch chatBatch = new ChatterBatch();
      Test.startTest();
      // should be only 2 running - but run for 4 to verify only 2 ran
      Database.executeBatch(chatBatch,4);
      Test.stopTest();
      
      // verify the results - should be users attached
      cgsChild = [Select Id, Name, Type__c, IsActive__c, Owner_Profile__c, Selected_Profiles__c, Manager_Profiles__c
                        ,ChatterGroupId__c, Status__c, Do_Not_Include_Child_Profiles__c
                        ,(Select Id, Name 
                                ,Org_Unit__c, Org_Unit__r.Name
                            from Chatter_Group_Org_Links__r) 
                        ,(Select Id, Name, CollaborationGroupMemberId__c
                                ,User__c, User__r.Profile.Name 
                            from Chatter_Group_User_Links__r)
                        ,(Select Id, Name
                                ,Child_Group__c, Child_Group__r.Name
                            from Child_Groups__r)
                    from Chatter_Group_Setup__c 
                   where Id = :cgsChild.Id];
      
      // make sure there are children
      System.assertEquals(true,(cgsChild.Chatter_Group_User_Links__r != null && !cgsChild.Chatter_Group_User_Links__r.isEmpty()));
      // org units should be attached
      System.assertEquals(costCenters.size(), cgsChild.Chatter_Group_Org_Links__r.size());
      
      // perform an update
      cgsChild.Type__c = 'Public';
      cgsChild.Name = 'New Test Child Group';
      
      ChatterMethods.processOneRecord(cgsChild.Id);
      
      //ChatterMethods cm = new ChatterMethods();
      //cm.checkForGroupMembers(cgsChild);
      
   } // testAddMembers
   
   static testMethod void testSelectAllProfiles() {
      // create a group
      Chatter_Group_Setup__c cgs = new Chatter_Group_Setup__c(Name='Test Child Group', Type__c='Private',IsActive__c=true, Select_From_All_Profiles__c=true);
      insert cgs;
      
      // select profiles using the ChatterGroupSetupController - provides tests for this also
      Test.SetCurrentPageReference(Page.ChatterGroupSetup);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(cgs);
      System.CurrentPageReference().getParameters().put('id',cgs.Id);
      ChatterGroupSetupController cgsc = new ChatterGroupSetupController(sc1);
      
      System.assertEquals(0,cgsc.selectedProfiles.size());
      System.assertEquals(0,cgsc.managerProfiles.size());
      // should be at least one record to choose from
      System.assertEquals(true,cgsc.profileOptions.size() > 0);
   } // testSelectAllProfiles
   
   /** Test the scheduler for the batch process.
    */
   static testMethod void testBatchScheduler() {
      ChatterBatch chatBatch = new ChatterBatch();
      TestHelper.testScheduler('ChatterBatchTest', chatBatch);
   } // testBatchScheduler
   
} // class ChatterMethodsTest