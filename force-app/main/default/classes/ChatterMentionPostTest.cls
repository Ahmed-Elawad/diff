/**
 * Test Class for ChatterMentionPost Class
 * History
 * -------
  03/17/2014 Justin Stouffer     Created
  03/11/2016  Dan Carmen         Add the sendPostsMentionPublicGroup method
  12/20/2018  Dan Carmen         Add in a counter to check in test methods
  7/15/2019	  Matt Fritchi		 Added products to the lead when testing the buildChatterMessage
  06/19/2023  Susmitha Somavarapu  Creating a chatter post message to peo reps (APR0152220)

 */
@isTest(SeeAllData=false)
private class ChatterMentionPostTest {

   @isTest(SeeAllData=true)
    static void testPostListIDs() {
       User[] users = [Select Id, Name from User where HR_Person_Id__c != null and IsActive = true limit 3];
       User u1 = users[0];
       User u2 = users[1];
       User u3 = users[2];
      CollaborationGroup c1 = new CollaborationGroup(Name='ChatterMentionPostGroup'
                                                        , CollaborationType='Public');
      insert c1;
        
       Account a = new Account(Name = 'Test Account', 
                               NumberOfEmployees = 18,
                               type = 'MMS Client',
                               Frequency__c = '24',
                               Current_Prior_Method__c = 'ADP',
                               BillingPostalCode = '14424',
                               AccountNumber = '83-1234567',
                               Do_Not_Call__c = true,
                               Email_Opt_Out__c = true,
                               AnnualRevenue = 25);
       insert a;
       
       //Test with No @mentions
       list<id> atMentionIdList = new list<id>();
       chatterMentionPost.createChatterMentionPost(a.Id, atMentionIdList, 'This is a test with no @mentions.');  
       list<feedItem> fItemList = [Select Id, Body from feedItem where parentId = :a.id];
       system.assertEquals(fItemList.size(),1);
       //system.assertEquals('This is a test with no @mentions.',fItemList[0].body);
       system.assertEquals(true,fItemList[0].body.contains('This is a test with no @mentions.'));
       delete fItemList;
       
       //Test with one @mention
       atMentionIdList.add(u1.id);
       chatterMentionPost.createChatterMentionPost(a.Id, atMentionIdList, 'This is a test with one @mention.');  
       fItemList = [Select Id, Body from feedItem where parentId = :a.id];
       system.assertEquals(fItemList.size(),1);
       //system.assertEquals('Hello @' + u1.name + '.  This is a test with one @mention.',fItemList[0].body);
       system.debug('Test with one @mention body='+fItemList[0].body);
       system.assertEquals(true,fItemList[0].body.contains('This is a test with one @mention'));
       system.assertEquals(true,fItemList[0].body.contains(u1.name));
       delete fItemList;

       //Test with Group @mention
       chatterMentionPost.createChatterMentionPost(a.Id, new ID[]{C1.ID}, 'This is a test with one @mention.');  
       fItemList = [Select Id, Body from feedItem where parentId = :a.id];
       system.assertEquals(fItemList.size(),1);
       system.debug('Test with Group @mention body='+fItemList[0].body);
       system.assertEquals(true,fItemList[0].body.contains('This is a test with one @mention'));
       system.assertEquals(true,fItemList[0].body.contains(C1.name));
       //system.assertEquals('Hello @' + C1.name + '.  This is a test with one @mention.',fItemList[0].body);
       delete fItemList[0];
       
       //Test with Invalid @mention
       chatterMentionPost.createChatterMentionPost(a.Id, new ID[]{a.Id}, 'This is a test with a bad @mention.');  
       fItemList = [Select Id, Body from feedItem where parentId = :a.id];
       system.assertEquals(fItemList.size(),1);
       system.debug('Test with Invalid @mention body='+fItemList[0].body);
       //system.assertEquals(true,fItemList[0].body.contains('This is a test with a bad @mention'));
       //system.assertEquals(false,fItemList[0].body.contains(C1.name));
       system.assertEquals('Hello. This is a test with a bad @mention.',fItemList[0].body);
       delete fItemList;
       
       //Test with one good, one bad, and one good @mentions
       chatterMentionPost.createChatterMentionPost(a.Id, new ID[]{u1.id, a.Id, u2.id}, 'This is a test with two @mentions.');  
       fItemList = [Select Id, Body from feedItem where parentId = :a.id];
       system.assertEquals(fItemList.size(),1);
       system.debug('Test one good, one bad, and one good @mentions body='+fItemList[0].body);
       system.assertEquals(true,fItemList[0].body.contains('This is a test with two @mentions'));
       system.assertEquals(true,fItemList[0].body.contains(u1.name));
       system.assertEquals(true,fItemList[0].body.contains(u2.name));
       //system.assertEquals('Hello @' + u1.name + ' and @' + u1.name + '.  This is a test with two @mentions.',fItemList[0].body);
       delete fItemList;
        
       //Test with two @mentions
       atMentionIdList.add(u2.id);
       chatterMentionPost.createChatterMentionPost(a.Id, atMentionIdList, 'This is a test with two @mentions.');  
       fItemList = [Select Id, Body from feedItem where parentId = :a.id];
       system.assertEquals(fItemList.size(),1);
       system.debug('Test with Group @mention body='+fItemList[0].body);
       system.assertEquals(true,fItemList[0].body.contains('This is a test with two @mentions'));
       system.assertEquals(true,fItemList[0].body.contains(u1.name));
       system.assertEquals(true,fItemList[0].body.contains(u2.name));
       //system.assertEquals('Hello @' + u1.name + ' and @' + u1.name + '.  This is a test with two @mentions.',fItemList[0].body);
       delete fItemList;
        
       //Test with three @mentions
       atMentionIdList.add(u3.id);
       chatterMentionPost.createChatterMentionPost(a.Id, atMentionIdList, 'This is a test with three @mentions.');  
       fItemList = [Select Id, Body from feedItem where parentId = :a.id];
       system.assertEquals(fItemList.size(),1);
       system.debug('Test with Group @mention body='+fItemList[0].body);
       system.assertEquals(true,fItemList[0].body.contains('This is a test with three @mentions'));
       system.assertEquals(true,fItemList[0].body.contains(u1.name));
       system.assertEquals(true,fItemList[0].body.contains(u2.name));
       system.assertEquals(true,fItemList[0].body.contains(u3.name));
       //system.assertEquals('Hello @' + u1.name + ', @' + u1.name + ', and @' + u1.name + '.  This is a test with three @mentions.',fItemList[0].body);
       delete fItemList;  
       chatterMentionPost.createChatterMentionPost(a.Id, atMentionIdList, New List<String>{'PEO_OPP-Created- HR'},true, true );  

    } // testPostListIDs
    
    
   @isTest(SeeAllData=false)
   static void testBuildMessage() {
      CreateTestData.createTestLead();
      Lead ld = CreateTestData.ld1;
      ld.Products__c = 'Paycard;Freshlime';
      ChatterMentionPost.buildChatterMessage(ld);
      
      CreateTestData.createSingleAandTwoCts();
      ChatterMentionPost.buildChatterMessage(CreateTestData.acct1, CreateTestData.ctct1);
      
   } // testBuildMessage
    
   @isTest(SeeAllData=true)
   static void testPostToGroup() {
      Group testGrp = new Group(Name='ChatterMentionPostTest',Type='Regular');
      insert testGrp;
      // get users to add to the group
      User[] users = [Select Id, Name from User where IsActive=true and Profile.Name=:Utilities.PROF_SYS_ADMIN limit 3];
      GroupMember[] grpMembers = new GroupMember[]{};
      for (User usr : users) {
         grpMembers.add(new GroupMember(GroupId=testGrp.Id, UserOrGroupId=usr.Id));
      }
      insert grpMembers;
      
      User runningUser = UserHelper.getRunningUser();
      
      System.runAs(runningUser) {
      PaychexSettings__c payxSetting = new PaychexSettings__c(Name='ThisIsATestPaychexSetting', Attribute1__c=testGrp.Name, IsActive__c=true);
      insert payxSetting;
      
      Account testAcct1 = new Account(Name='Test Acct1');
      Account testAcct2 = new Account(Name='Test Acct2');
      Account testAcct3 = new Account(Name='Test Acct3');
      Account[] accts = new Account[]{testAcct1,testAcct2,testAcct3};
      insert accts;
      
      Map<Id,String> testMap = new Map<Id,String>();
      for (Account acct : accts) {
         testMap.put(acct.Id,'This is a test message to post on '+acct.Name);
      }
      
      ChatterMentionPost.sendPostsMentionPublicGroup(payxSetting.Name, testMap, true);
      }
   } // testPostToGroup
    
} // class ChatterMentionPostTest