/* 
 * Test methods for the Round Robin trigger/class
 *
 * History
 * -------
 * 08/11/2011 Dan Carmen        Created.
   09/29/2011 Dan Carmen        Fix for mixed DML exception.
   08/28/2013 Dan Carmen        Fix to make sure users are assigned in correct order.
   08/28/2015 Jacob Hinds    Added Leads and Contacts
   10/31/2016 Jacob Hinds    Adding Opportunity
   04/28/2017 Cindy Freeman    commented out line 363 to get test to pass
 * 01/15/2018 Jake Hinds    Changing Scheduler fields from text to time.  Adding ability to toggle night/weekend weighting. Deleting a bunch of commented out code
 * 10/16/2019 Jake Hinds    Check for internal referral account team member
   12/15/2023 Dan Carmen         Clean up code
   12/23/2023 Dan Carmen         Fix scheduler to handle overnight times

 */
@isTest
public with sharing class RoundRobinTest {
  
   @testSetup 
   static void setupRoundRobin(){
    
      User runUser = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' limit 1];
      System.runAs(runUser) {
      
      // select users
      User[] users = [Select Id, Name from User where Profile.Name='System Administrator' 
                                                and IsActive=true
                                                and Assignment_Group_Active__c=true
                                                and Id != :runUser.Id 
                                                limit 4];
      //only want three round robin users.  pop the fourth to use as the delegate.
      User delegateUser = users.remove(3);                                        
                                                
         // create assignment group  
      Group grp1 = new Group(Name='RoundRobinTest Case Queue',Type='Queue');
      // this queue will not be associated with an assignment group
      Group grp2 = new Group(Name='RoundRobinTest Case Queue 2',Type='Queue');
      Group grp3 = new Group(Name='RoundRobinTest Night/Weekend Queue',Type='Queue');
      Group grp4 = new Group(Name='Virtual Sales Queue',Type='Queue');
      Group grp5 = new Group(Name='RoundRobinTest Generic Queue',Type='Queue');
      Group grp6 = new Group(Name='RoundRobinTest Delegate Queue',Type='Queue');
      Group grp7 = new Group(Name='RoundRobinTest Always On',Type='Queue');
      Group[] grps = new Group[]{grp1,grp2,grp3,grp4,grp5,grp6,grp7};
      insert grps;
      
      // associate the queues with the objects
      //the Sobject type field doesn't actually do anything
      QueueSobject[] qSobjects = new QueueSobject[]{};
      qSobjects.add(new QueueSobject(QueueId=grp1.Id,SobjectType='Case'));
      qSobjects.add(new QueueSobject(QueueId=grp2.Id,SobjectType='Case'));
      qSobjects.add(new QueueSobject(QueueId=grp3.Id,SobjectType='Lead'));
      qSobjects.add(new QueueSobject(QueueId=grp3.Id,SobjectType='Referral__c'));
      qSobjects.add(new QueueSobject(QueueId=grp4.Id,SobjectType='Lead'));
      qSobjects.add(new QueueSobject(QueueId=grp5.Id,SobjectType='Lead'));
      qSobjects.add(new QueueSobject(QueueId=grp6.Id,SobjectType='Lead'));
      qSobjects.add(new QueueSobject(QueueId=grp6.Id,SobjectType='Referral__c'));
      qSobjects.add(new QueueSobject(QueueId=grp7.Id,SobjectType='Case'));
      insert qSobjects;
      
     // set the test time at noon to keep it simple
     DateTime rightNow = Datetime.newInstance(Datetime.now().date(), Time.newInstance(12,0,0,0));
     Decimal currHour = (Decimal)rightNow.hour();
     currHour = currHour.setScale(2,RoundingMode.HALF_UP);
     Decimal currMin = (Decimal)rightNow.minute()/60;
     currMin = currMin.setScale(2,RoundingMode.HALF_UP);
     
     //make sure the current time is during the users' shift.  Used to test when user is on
     Time startTime = Time.newInstance((Integer)currHour-1,(Integer)currMin,0,0);
     Time endTime = Time.newInstance((Integer)currHour+4,(Integer)currMin,0,0);
        
     Time outsideShiftStart = Time.newInstance((Integer)currHour-6,(Integer)currMin,0,0);
     Time outsideShiftEnd = Time.newInstance((Integer)currHour-4,(Integer)currMin,0,0);
         
     Time startTimeNight = Time.newInstance((Integer)currHour-2,(Integer)currMin,0,0);
     Time endTimeNight = Time.newInstance((Integer)currHour-1,(Integer)currMin,0,0);
          
     Time overnightStart = Time.newInstance((Integer)currHour+8,(Integer)currMin,0,0);
     Time overnightEnd = Time.newInstance((Integer)currHour-7,(Integer)currMin,0,0);
         
     Assignment_Group_Name__c cagn = new Assignment_Group_Name__c(Name='RoundRobinTest Case Queue');
     Assignment_Group_Name__c nwagn = new Assignment_Group_Name__c(Name='RoundRobinTest Night/Weekend Queue',Round_Robin_Delegate__c=delegateUser.Id,Use_Scheduler__c=true,Use_Weighting__c=true,Skip_Weighting_Nights_Weekends__c=true,Weekday_Start__c=startTimeNight,Weekday_End__c=endTimeNight,Weekend_Start__c=startTimeNight,Weekend_End__c=endTimeNight);
     Assignment_Group_Name__c gagn = new Assignment_Group_Name__c(Name='RoundRobinTest Generic Queue',Round_Robin_Delegate__c=delegateUser.Id,Use_Scheduler__c=true,Use_Weighting__c=true,Weekday_Start__c=startTime,Weekday_End__c=endTime);
     Assignment_Group_Name__c dagn = new Assignment_Group_Name__c(Name='RoundRobinTest Delegate Queue',Round_Robin_Delegate__c=delegateUser.Id,Use_Scheduler__c=true,Weekday_Start__c=startTime,Weekday_End__c=endTime);
     Assignment_Group_Name__c agn7 = new Assignment_Group_Name__c(Name=grp7.Name,Round_Robin_Delegate__c=delegateUser.Id,Use_Scheduler__c=true,ScheduleAllHours__c=true);
     Assignment_Group_Name__c[] agns = new Assignment_Group_Name__c[]{cagn,nwagn,gagn,dagn,agn7};
     insert agns; 

     // insert a Queue record
     Assignment_Group_Queues__c cagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=cagn.Id, Name='RoundRobinTest Case Queue');
     Assignment_Group_Queues__c nwagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=nwagn.Id, Name='RoundRobinTest Night/Weekend Queue');
     Assignment_Group_Queues__c gagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=gagn.Id, Name='RoundRobinTest Generic Queue');
     Assignment_Group_Queues__c dagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=dagn.Id, Name='RoundRobinTest Delegate Queue');
     Assignment_Group_Queues__c agq7 = new Assignment_Group_Queues__c(Assignment_Group_Name__c=agn7.Id, Name=grp7.Name);
     Assignment_Group_Queues__c[] agqs = new Assignment_Group_Queues__c[]{cagq,nwagq,gagq,dagq,agq7}; 
     insert agqs;
     
     system.debug('testUsers: '+users);                                      
     // add as group members 
     Assignment_Groups__c[] ags = new Assignment_Groups__c[]{};
       Integer millisecond = 1;
       Integer skillSet = 1;
       for (User u : users) {
          Assignment_Groups__c cag = new Assignment_Groups__c(Active__c='True',Group_Name__c=cagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
          ags.add(cag);
          Assignment_Groups__c nwag = new Assignment_Groups__c(Active__c='True',Group_Name__c=nwagn.Id,User__c=u.Id, Millisecond__c=millisecond++,
              Monday_1__c=startTimeNight,Monday_2__c=endTimeNight,Tuesday_1__c=startTimeNight,Tuesday_2__c=endTimeNight,Wednesday_1__c=startTimeNight,Wednesday_2__c=endTimeNight,Thursday_1__c=startTimeNight,Thursday_2__c=endTimeNight,
              Friday_1__c=startTimeNight,Friday_2__c=endTimeNight,Saturday_1__c=startTimeNight,Saturday_2__c=endTimeNight,Sunday_1__c=startTimeNight,Sunday_2__c=endTimeNight,Weighting_Level__c=String.ValueOf(skillSet));
          ags.add(nwag);
           
          // set the last user to be outside of the scheduled time
          Time useStart = (skillSet < 3 ? startTime : outsideShiftStart);
          Time useEnd = (skillSet < 3 ? endTime : outsideShiftEnd);
          Assignment_Groups__c gag = new Assignment_Groups__c(Active__c='True',Group_Name__c=gagn.Id,User__c=u.Id, Millisecond__c=millisecond++, 
            Monday_1__c=useStart,Monday_2__c=useEnd,Tuesday_1__c=useStart,Tuesday_2__c=useEnd,Wednesday_1__c=useStart,Wednesday_2__c=endTime,Thursday_1__c=useStart,Thursday_2__c=useEnd,
            Friday_1__c=useStart,Friday_2__c=useEnd,Saturday_1__c=useStart,Saturday_2__c=useEnd,Sunday_1__c=useStart,Sunday_2__c=endTime,Weighting_Level__c=String.ValueOf(skillSet));
          ags.add(gag);
           
          Assignment_Groups__c dag = new Assignment_Groups__c(Active__c='True',Group_Name__c=dagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
          ags.add(dag);
          if(skillSet == 3){
            skillSet = 0;
          }
          skillSet++;
       }
       Assignment_Groups__c ag7a = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn7.Id,User__c=users[0].Id, Millisecond__c=millisecond++
             ,Monday_1__c=startTime,Monday_2__c=endTime,Monday_3__c=overnightStart,Monday_4__c=overnightEnd
             ,Tuesday_1__c=startTime,Tuesday_2__c=endTime,Weighting_Level__c=String.ValueOf(skillSet));
       ags.add(ag7a);
       insert ags;
    } // runAs
  } // testSetup  
    
   public static Assignment_Group_Name__c getGroup(String grpName) {
      Assignment_Group_Name__c ag =[SELECT Id,Name,Round_Robin_Delegate__c
                         ,(SELECT Id, Name, QueueId__c
                                ,Active__c, Valid_Queue__c
                             FROM Assignment_Group_Queues__r) 
                       ,(SELECT Id,Group_Name__c, User__c, Last_Assignment__c, Millisecond__c, User__r.Id, User__r.FirstName,User__r.LastName, User__r.Email
                              ,Active__c, User_Active__c
                              FROM Assignment_Groups__r
                              WHERE Active__c = 'True' AND User_Active__c = 'True'
                               ORDER BY Last_Assignment__c, Millisecond__c)
                  FROM Assignment_Group_Name__c 
                  WHERE Name=:grpName LIMIT 1 ];
      System.debug('getGroup ag='+ag);
      return ag;
   } // getGroup
  
   static testMethod void testCases(){
     User runUser = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' limit 1];
     Assignment_Group_Name__c ag = getGroup('RoundRobinTest Case Queue');
     User[] users = new User[]{};
     for(Assignment_Groups__c member: ag.Assignment_Groups__r){
       User u = new User(Id = member.User__r.Id,FirstName=member.User__r.FirstName,LastName=member.User__r.LastName,Email = member.User__r.Email);
       system.debug('newUser: '+u);
       users.add(u);
     }
     Id rrGrpId = Id.valueOf(ag.Assignment_Group_Queues__r[0].QueueId__c);
     //Group grp1 = [SELECT Id FROM Group WHERE Name='RoundRobinTest Case Queue' limit 1];
     Group grp2 = [SELECT Id FROM Group WHERE Name='RoundRobinTest Case Queue 2' limit 1];                                              
     system.runAs(runUser){
      
      
      Case c1 = new Case(Subject='Test Case 1',OwnerId=rrGrpId);
     insert c1;
     
     // verify owner is now the first member of the group
     verifyOwner('test Case 1',users[0].Id,c1.Id,'Case');

     // update the owner to the queue again
     c1.OwnerId = rrGrpId;
     update c1;
     verifyOwner('test Case 2',users[1].Id,c1.Id,'Case');

     // create 2 new cases
     Case c2 = new Case(Subject='Test Case 2',OwnerId=rrGrpId);
     Case c3 = new Case(Subject='Test Case 3',OwnerId=rrGrpId);
     Case[] cases = new Case[]{c2,c3};
     
     // save all of the cases
     upsert cases;

     // verify owners is now the next member of the group
     verifyOwner('test Case 3',users[2].Id,c2.Id,'Case');
     verifyOwner('test Case 4',users[0].Id,c3.Id,'Case');
     
          // this case will not go through round robin
     Case c4 = new Case(Subject='Test Case 4',OwnerId=grp2.Id);
     insert c4;
     verifyOwner('test 6',grp2.Id,c4.Id,'Case');
     }
      
   }
   
   
   static testMethod void testNightAndWeekend() { 
     
     Assignment_Group_Name__c ag = getGroup('RoundRobinTest Night/Weekend Queue');
      //User runUser = [SELECT Id FROM User WHERE Name='Lead Loader' AND Alias='Loader1' AND isActive=true LIMIT 1];
     // collect the users for comparison later
     User[] users = new User[]{};
     for(Assignment_Groups__c member: ag.Assignment_Groups__r){
       User u = member.User__r;
       system.debug('newUser: '+u);
       users.add(u);
     }    
     Id rrGrpId = Id.valueOf(ag.Assignment_Group_Queues__r[0].QueueId__c);
     //Group nwQueue = [SELECT Id,Name FROM Group WHERE Name='RoundRobinTest Night/Weekend Queue' limit 1];
     //test weekend night time
     RoundRobin.testDayOfWeek = 'Sunday';
     Referral__c ref = new Referral__c(Name='Test Referral',OwnerId=rrGrpId);
     Referral__c ref2 = new Referral__c(Name='Test Referral',OwnerId=rrGrpId);
     Referral__c ref3 = new Referral__c(Name='Test Referral',OwnerId=rrGrpId);
     Referral__c[] refs = new Referral__c[]{ref,ref2,ref3};
     insert refs; 
     
     verifyOwner('test Referral',users[0].Id,ref.Id,'Referral');
     verifyOwner('test Referral',users[1].Id,ref2.Id,'Referral');
     verifyOwner('test Referral',users[2].Id,ref3.Id,'Referral');
     
     //test weekday night time
     RoundRobin.testDayOfWeek = 'Monday';
     ref.OwnerId=rrGrpId;
     ref2.OwnerId=rrGrpId;
     ref3.OwnerId=rrGrpId;
     ReferralTriggerActions.SKIP_TRIGGER=false;
     update refs;
     
     verifyOwner('test Referral',users[0].Id,ref.Id,'Referral');
     verifyOwner('test Referral',users[1].Id,ref2.Id,'Referral');
     verifyOwner('test Referral',users[2].Id,ref3.Id,'Referral');
   
     //test weekend always on
     
     //test delegate

     
   }
   
   static testMethod void testDelegate() {
      RoundRobin.testRightNow = Datetime.newInstance(Datetime.now().date(), Time.newInstance(14,0,0,0));
      Assignment_Group_Name__c ag = getGroup('RoundRobinTest Delegate Queue');
                    
      Id rrGrpId = Id.valueOf(ag.Assignment_Group_Queues__r[0].QueueId__c);
      //Group dQueue = [SELECT Id,Name FROM Group WHERE Name='RoundRobinTest Delegate Queue' limit 1];    
      
      Referral__c ref = new Referral__c(Name='Test Referral',OwnerId=rrGrpId);
      insert ref;  
      verifyOwner('test Referral',ag.Round_Robin_Delegate__c,ref.Id,'Referral');  
      
      ag.Use_Weighting__c = true;
      update ag;
      ref.OwnerId = rrGrpId;
      ReferralTriggerActions.SKIP_TRIGGER=false;
      update ref;  
      verifyOwner('test Referral',ag.Round_Robin_Delegate__c,ref.Id,'Referral');
   } // testDelegate
   
   static testMethod void testGeneric() {
     Account acct = new Account(Name='testCo',BillingPostalCode='14450');
     ZipCheckOwner.SKIP_TRIGGERS=true;
     insert acct;
     // use 2pm time to account for time zone of denver in the runAs
     RoundRobin.testRightNow = Datetime.newInstance(Datetime.now().date(), Time.newInstance(14,0,0,0));
     
     Assignment_Group_Name__c ag = getGroup('RoundRobinTest Generic Queue');
                    
     Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
     //create referral partners
     Referral_Partner__c rpQueue = new Referral_Partner__c(Name='Test Virtual',Partner_Type__c=ReferralController.REF_INTERNAL,
                                                          Sort_Order__c=21,Ref_To_Type__c='Queue',ReferFromType__c='User',CreateRefOpp__c=true, 
                                                          IsActive__c=true,Selling_Opp_RecordTypeId__c=String.valueOf(coreRT.getRecordTypeId()),
                                                          QueueName__c=ag.Name,SetReferralOwner__c=true);
     insert rpQueue;                
                    
     Id[] userIds = new Id[]{};
      User[] users = new User[]{};
      Assignment_Groups__c[] members = new Assignment_Groups__c[]{};
      Integer i = 1;
      for(Assignment_Groups__c member: ag.Assignment_Groups__r){
        User u = new User(Id = member.User__r.Id,FirstName=member.User__r.FirstName,LastName=member.User__r.LastName,Email = member.User__r.Email);
        users.add(u);
        userIds.add(u.Id);
        member.Weighting_Level__c = String.valueof(i);
        members.add(member);
        if(i==3){
          i=0;
        }
        i++;
      }
      update members;
      
      Id rrGrpId = Id.valueOf(ag.Assignment_Group_Queues__r[0].QueueId__c);
      //Group grp10 = [SELECT Id,Name FROM Group WHERE Name='RoundRobinTest Generic Queue' limit 1];
      User tzUser = [SELECT Id,TimeZoneSidKey FROM User 
                      WHERE Id NOT IN :userIds AND Job_Name__c=:UserHelper.JOB_REP AND isActive=true and TimeZoneSidKey = 'America/Denver' LIMIT 1];
//      tzUser.TimeZoneSidKey = 'America/Denver';
//      update tzUser;
      System.runAs(tzUser){
        Test.startTest();
         RoundRobin.testDayOfWeek = 'Tuesday';
         Referral__c ref = new Referral__c(Name='Test Referral',OwnerId=rrGrpId,Referral_Partner__c=rpQueue.Id,Account__c = acct.Id);
         Referral__c ref2 = new Referral__c(Name='Test Referral',OwnerId=rrGrpId);
         Referral__c ref3 = new Referral__c(Name='Test Referral',OwnerId=rrGrpId);
         Referral__c ref4 = new Referral__c(Name='Test Referral',OwnerId=rrGrpId);
         Referral__c ref5 = new Referral__c(Name='Test Referral',OwnerId=rrGrpId);
         Referral__c ref6 = new Referral__c(Name='Test Referral',OwnerId=rrGrpId);
         Referral__c ref7 = new Referral__c(Name='Test Referral',OwnerId=rrGrpId);
         Referral__c[] refs = new Referral__c[]{ref,ref2,ref3,ref4,ref5,ref6,ref7};
         System.debug('testGeneric before ref insert');
         insert refs;
         System.debug('testGeneric after ref insert');
         verifyOwner('test Referral',users[0].Id,ref.Id,'Referral');
         AccountTeamMember atm = [SELECT Id,TeamMemberRole FROM AccountTeamMember WHERE AccountId = :ref.Account__c AND UserId = :users[0].Id LIMIT 1];
         system.assertEquals(rpQueue.Partner_Type__c,atm.TeamMemberRole);
         verifyOwner('test Referral',users[1].Id,ref2.Id,'Referral');
         verifyOwner('test Referral',users[1].Id,ref3.Id,'Referral');
         verifyOwner('test Referral',users[0].Id,ref4.Id,'Referral');
         verifyOwner('test Referral',users[1].Id,ref5.Id,'Referral');
         verifyOwner('test Referral',users[1].Id,ref6.Id,'Referral');
         verifyOwner('test Referral',users[0].Id,ref7.Id,'Referral');
         
         Test.stopTest();  
      }
   } // testGeneric
    
   private static void verifyOwner(String debugStmt, Id ownerId, Id objId, String objType) {
      
      if(objType=='Case'){
        case c = [Select Id, OwnerId from Case where Id=:objId];
        System.debug('verifyOwner: '+debugStmt+' expected: '+ownerId+' actual: '+c.OwnerId);
        System.assertEquals(ownerId,c.OwnerId);
      }
      else if (objType=='Lead'){
        Lead l = [Select Id, OwnerId from Lead where Id=:objId];
        System.debug('verifyOwner: '+debugStmt+' expected: '+ownerId+' actual: '+l.OwnerId);
        System.assertEquals(ownerId,l.OwnerId);
      }
      else if (objType=='Contact'){
        Contact co = [Select Id, OwnerId from Contact where Id=:objId];
        System.debug('verifyOwner: '+debugStmt+' expected: '+ownerId+' actual: '+co.OwnerId);
        System.assertEquals(ownerId,co.OwnerId);
      }
      else if (objType=='Opportunity'){
        Opportunity oppty = [Select Id, OwnerId from Opportunity where Id=:objId];
        System.debug('verifyOwner: '+debugStmt+' expected: '+ownerId+' actual: '+oppty.OwnerId);
        System.assertEquals(ownerId,oppty.OwnerId);
      }else if (objType=='Referral'){
        Referral__c ref = [Select Id, OwnerId from Referral__c where Id=:objId];
        System.debug('verifyOwner: '+debugStmt+' expected: '+ownerId+' actual: '+ref.OwnerId);
        System.assertEquals(ownerId,ref.OwnerId);
      }
  
   } // verifyOwner
   
   static testMethod void testInactiveUser() {
     Assignment_Group_Name__c ag = getGroup('RoundRobinTest Case Queue');
     /*
     Assignment_Group_Name__c ag =[SELECT Id,Name,
                        (SELECT Id,Group_Name__c, User__c, Last_Assignment__c, Millisecond__c, User__r.Id, User__r.FirstName,User__r.LastName, User__r.Email
                                ,Active__c, User_Active__c
                              FROM Assignment_Groups__r
                              //WHERE Active__c = 'True' AND User_Active__c = 'True'
                               ORDER BY Last_Assignment__c, Millisecond__c)
                  FROM Assignment_Group_Name__c 
                  WHERE Name='RoundRobinTest Case Queue' LIMIT 1 ];
      */
      Assert.areEqual(3,ag.Assignment_Groups__r.size());
      Assignment_Groups__c ag0 = ag.Assignment_Groups__r[0];
      Assignment_Groups__c ag1 = ag.Assignment_Groups__r[1];
      Assignment_Groups__c ag2 = ag.Assignment_Groups__r[2];
       
      Assert.areEqual('True',ag0.Active__c);
      Assert.areEqual('True',ag0.User_Active__c);
      Assert.areEqual('True',ag1.Active__c);
      Assert.areEqual('True',ag1.User_Active__c);
      Assert.areEqual('True',ag2.Active__c);
      Assert.areEqual('True',ag2.User_Active__c);
      
      Id rrGrpId = Id.valueOf(ag.Assignment_Group_Queues__r[0].QueueId__c);
     //Group rrQueue = [SELECT Id,Name FROM Group WHERE Name='RoundRobinTest Case Queue' limit 1];
      Id[] allUsers = new Id[]{ag0.User__c, ag1.User__c, ag2.User__c};
      System.debug('testInactiveUser allUsers='+allUsers);

     // level set with all active
     Case c1a = new Case(Subject='Test Case 1a',OwnerId=rrGrpId);
     Case c2a = new Case(Subject='Test Case 2a',OwnerId=rrGrpId);
     Case c3a = new Case(Subject='Test Case 3a',OwnerId=rrGrpId);
     Case c4a = new Case(Subject='Test Case 4a',OwnerId=rrGrpId);
     Case c5a = new Case(Subject='Test Case 5a',OwnerId=rrGrpId);
     insert new Case[]{c1a,c2a,c3a,c4a,c5a};
         
     Map<Id,Case> caseMap = new Map<Id,Case>([Select Id, Subject, OwnerId from Case]);
     validateUser(caseMap.get(c1a.Id), allUsers);
     validateUser(caseMap.get(c2a.Id), allUsers);
     validateUser(caseMap.get(c3a.Id), allUsers);
     validateUser(caseMap.get(c4a.Id), allUsers);
     validateUser(caseMap.get(c5a.Id), allUsers);
          

     // make one user inactive
     ag2.Active__c = 'False';
     update ag2;
     ag2 = [Select Group_Name__c, User__c, Last_Assignment__c, Millisecond__c, User__r.Id, User__r.FirstName,User__r.LastName, User__r.Email
                                ,Active__c, User_Active__c
                              FROM Assignment_Groups__c
                             Where Id=:ag2.Id];
     Assert.areEqual('False',ag2.Active__c);
     Assert.areEqual('True',ag2.User_Active__c);

      
     Case c1 = new Case(Subject='Test Case 1',OwnerId=rrGrpId);
     Case c2 = new Case(Subject='Test Case 2',OwnerId=rrGrpId);
     Case c3 = new Case(Subject='Test Case 3',OwnerId=rrGrpId);
     Case c4 = new Case(Subject='Test Case 4',OwnerId=rrGrpId);
     Case c5 = new Case(Subject='Test Case 5',OwnerId=rrGrpId);
       
     Case c6 = new Case(Subject='Test Case 6',OwnerId=rrGrpId);
     Case c7 = new Case(Subject='Test Case 7',OwnerId=rrGrpId);
     Case c8 = new Case(Subject='Test Case 8',OwnerId=rrGrpId);
     Case c9 = new Case(Subject='Test Case 9',OwnerId=rrGrpId);

     // there are only 2 active users in the queue. Should not be assigned to user on ag2
     Test.startTest();
     System.debug('testInactiveUser inserting cases');
     insert new Case[]{c1,c2,c3};
     insert new Case[]{c4,c5,c6};
     insert new Case[]{c7,c8,c9};
     Test.stopTest();
       
     Id[] validUsers = new Id[]{ag0.User__c, ag1.User__c};
     System.debug('testInactiveUser validUsers='+validUsers+' inactive user='+ag2.User__c);
     caseMap = new Map<Id,Case>([Select Id, Subject, OwnerId from Case]);
     validateUser(caseMap.get(c1.Id), validUsers);
     validateUser(caseMap.get(c2.Id), validUsers);
     validateUser(caseMap.get(c3.Id), validUsers);
     validateUser(caseMap.get(c4.Id), validUsers);
     validateUser(caseMap.get(c5.Id), validUsers);
     validateUser(caseMap.get(c6.Id), validUsers);
     validateUser(caseMap.get(c7.Id), validUsers);
     validateUser(caseMap.get(c8.Id), validUsers);
     validateUser(caseMap.get(c9.Id), validUsers);

   } // testInactiveUser
    
   public static void validateUser(Case cs, Id[] validUsers) {
     System.debug('testInactiveUser cs='+cs);
     Assert.isTrue(validUsers.contains(cs.OwnerId), 'cs.OwnerId='+cs.OwnerId);
   } // validateUser
   
   static testMethod void testOvernight() {
      Assignment_Group_Name__c ag = getGroup('RoundRobinTest Always On');
      Assert.areEqual(1,ag.Assignment_Groups__r.size());
      Assignment_Groups__c ag0 = ag.Assignment_Groups__r[0];
      Id validUserId = ag0.User__c;
      Id delegateId = ag.Round_Robin_Delegate__c;
      User testUser = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and TimeZoneSidKey=:Label.Default_TimeZone limit 1];
      System.runAs(testUser) {
           
         Id rrGrpId = Id.valueOf(ag.Assignment_Group_Queues__r[0].QueueId__c);
         // insert a record at 3am
         RoundRobin.testRightNow = Datetime.newInstance(Datetime.now().date(), Time.newInstance(3,0,0,0));
         RoundRobin.testDayOfWeek = 'Tuesday';
         RoundRobin.testPrevDay = 'Monday';
         Case c1a = new Case(Subject='Test Case 1a',OwnerId=rrGrpId);
         insert c1a;
         c1a = [Select Id, OwnerId from Case where Id=:c1a.Id];
         Assert.areEqual(validUserId,c1a.OwnerId);

         // should be nobody scheduled here - go to the delegate
         RoundRobin.testRightNow = Datetime.newInstance(Datetime.now().date(), Time.newInstance(23,0,0,0));
         Case c2a = new Case(Subject='Test Case 2a',OwnerId=rrGrpId);
         insert c2a;
         c2a = [Select Id, OwnerId from Case where Id=:c2a.Id];
         Assert.areEqual(delegateId, c2a.OwnerId);
      
         // schedule during normal hours
         RoundRobin.testRightNow = Datetime.newInstance(Datetime.now().date(), Time.newInstance(13,0,0,0));
         Case c3a = new Case(Subject='Test Case 3a',OwnerId=rrGrpId);
         insert c3a;
         c3a = [Select Id, OwnerId from Case where Id=:c3a.Id];
         Assert.areEqual(validUserId,c3a.OwnerId);
          
         RoundRobin.testDayOfWeek = 'Monday';
         RoundRobin.testPrevDay = 'Sunday';
         // Should meet the criteria for the overnight criteria
         RoundRobin.testRightNow = Datetime.newInstance(Datetime.now().date(), Time.newInstance(23,0,0,0));
         Case c4a = new Case(Subject='Test Case 4a',OwnerId=rrGrpId);
         insert c4a;
         c4a = [Select Id, OwnerId from Case where Id=:c4a.Id];
         Assert.areEqual(validUserId, c4a.OwnerId);

      } // System.runAs(testUser

   } // testOvernight
    
} // class RoundRobinTest