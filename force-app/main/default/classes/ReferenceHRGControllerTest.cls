/* 
 * Test methods for the ReferenceHRGController class
 *
 * History
 * -------
 * 04/12/2013 Dan Carmen   Created
   10/01/2013 Dan Carmen   Added in check for PREMIER_PLAN_CODE_SET for mass update
 *
 */
@isTest
private class ReferenceHRGControllerTest {

   /** Test standard usage without a Reference object already created. */
   static testMethod void testStandardUsageNoRef() {
    // create an account and contacts to start from
    Account acct1 = new Account(Name='Test Account');
    insert acct1;
    Contact ctct1 = new Contact(AccountId=acct1.Id,FirstName='Test',LastName='One',Email='test.one@testaccount.com');
    Contact ctct2 = new Contact(AccountId=acct1.Id,FirstName='Test',LastName='Two',Email='test.two@testaccount.com');
    Contact[] ctcts = new Contact[]{ctct1,ctct2};
    insert ctcts;
  // add Open Salesforce Activity with no HRG Activity associated to it yet
    String RT_TASK='2008-09 Premier Service Provider Task Record Type';
    Schema.RecordTypeInfo taskRT = RecordTypeHelper.getRecordType(RT_TASK,'Task');
    Task tsk1 = new Task(RecordTypeId=taskRT.getRecordTypeId(),WhatId=acct1.id,ActivityDate=Date.today().addDays(3),Subject='Test Task',Product__c='Premier',Type='Email',Client_Summary__c='This is a test');
    insert tsk1;
      
      Test.SetCurrentPageReference(Page.ReferenceHRG);
      System.CurrentPageReference().getParameters().put('acctId',acct1.Id);
      ReferenceHRGController rhc1 = new ReferenceHRGController();
      System.assertEquals(false,rhc1.promptForAccount);
      // verify there's a new reference object
      System.assertEquals(true,rhc1.refHRG.Id == null);
      System.assertEquals(true,rhc1.okayToProceed);
      // make sure we're at the step to ask for task/event
      System.assertEquals('What Did You Do',rhc1.currentStep);

      // verify we have contacts
      System.assertEquals(true,rhc1.hasContactSelections);
      // should be three elements in the array
      System.assertEquals(3,rhc1.contactSelections.size());
      
      //Show Open Salesforce Activity on the first screen of HRG Activity VFpage 
      rhc1.checkForActivityToConfirm();
        
      // should be open 1 Salesforce activity
      System.assertEquals(1,rhc1.sortedOpenActivityList.size());
      
      rhc1.deleteKey=rhc1.sortedOpenActivityList[0].key;
      rhc1.deleteSalesforceActivity();
      rhc1 = new ReferenceHRGController();
   
      // should be open 0 Salesforce activity
      System.assertEquals(0,rhc1.sortedOpenActivityList.size());
      
      ReferenceHRGController rhc = new ReferenceHRGController();
      
      // should be open no Salesforce activity
      System.assertEquals(0,rhc.sortedOpenActivityList.size());
      
      // should not be any open activities
      System.assertEquals(false,rhc.hasOpenActivityList);
      
      // verify the step
      System.assertEquals('What Did You Do',rhc.currentStep);
      
      // toggle the different sections
      // since this is new, the onboarding section will be open.
      System.assertEquals(true,rhc.showOnboarding);
      // close then open it again
      rhc.toggleOnboarding();
      System.assertEquals(false,rhc.showOnboarding);
      rhc.toggleOnboarding();
      System.assertEquals(true,rhc.showOnboarding);
      
      // client concerns will be closed initially
      System.assertEquals(false,rhc.showClientConcerns);
      rhc.toggleShowClientConcerns();
      System.assertEquals(true,rhc.showClientConcerns);
      rhc.toggleShowClientConcerns();
      System.assertEquals(false,rhc.showClientConcerns);
      
      // setup issues will be closed initially
      System.assertEquals(false,rhc.showSetupIssues);
      rhc.toggleShowSetupIssues();
      System.assertEquals(true,rhc.showSetupIssues);
      rhc.toggleShowSetupIssues();
      System.assertEquals(false,rhc.showSetupIssues);

      // product utilization will be closed
      System.assertEquals(false,rhc.showProductUtilization);
      rhc.toggleShowProductUtilization();
      System.assertEquals(true,rhc.showProductUtilization);
      rhc.toggleShowProductUtilization();
      System.assertEquals(false,rhc.showProductUtilization);

      // log activity against the onboarding activity
      for (ReferenceHrgActivityWrapper rhaw : rhc.onboardingActivityList) {
         rhaw.activity.Type__c = ReferenceHRGActivityWrapper.ONSITE;
         rhaw.activity.Activity_Date__c = Date.today().addDays(7);
      }

      System.assertEquals((rhc.getOnboardingFields().size()/2),rhc.onboardingActivityList.size());

      // make sure there is no ongoing activity
      System.assertEquals(0,rhc.ongoingActivityList.size());
           
      // add ongoing activity
      rhc.nbrNewOngoingActivities = 2;
      System.assertEquals(null,rhc.addOngoingActivity());

      // should be two now
      System.assertEquals(2,rhc.ongoingActivityList.size());

      // log activity against the ongoing activity
      //rhc.ongoingActivityList[0].logActivity=true;
      rhc.ongoingActivityList[0].activity.Type__c = ReferenceHRGActivityWrapper.ONSITE;
      rhc.ongoingActivityList[0].activity.Activity_Type__c = 'TestType';
      rhc.ongoingActivityList[0].activity.Activity__c = 'TestActivity1';
      rhc.ongoingActivityList[0].activity.Activity_Date__c = Date.today().addDays(7);
      
      rhc.ongoingActivityList[1].activity.Type__c = ReferenceHRGActivityWrapper.ONSITE;
      rhc.ongoingActivityList[1].activity.Activity_Type__c = 'TestType';
      rhc.ongoingActivityList[1].activity.Activity__c = 'TestActivity2';
      rhc.ongoingActivityList[1].activity.Activity_Date__c = Date.today().addDays(7);
      
      // goto the next step
      rhc.setVerifyActivityStep();
      System.assertEquals('Verify Activity',rhc.currentStep);
      System.assertEquals((rhc.getOnboardingFields().size()/2)+2,rhc.nbrActivityToConfirm);
      
      // save and enter more activity
      System.assertEquals(null,rhc.saveAndNewActivity());
      
      // should be back at the main form.
      // make sure we're at the step to ask for task/event
      //System.assertEquals('Open Activity List',rhc.currentStep);

      // should be open activity
      System.assertEquals(true,rhc.hasOpenActivityList);
      
      // goto the verify step
      rhc.setVerifyActivityStep();
      System.assertEquals('Verify Activity',rhc.currentStep);

      // set the activity id we are selecting
      //System.currentPageReference().getParameters().put('activityId',rhc.openActivityList[0].activityId);
      //System.assertEquals(null,rhc.useExistingActivity());
      // should bring us to the next step.
      //System.assertEquals('Manage Open Activity',rhc.currentStep);

      // verify it's an event
      //System.assertEquals(true,rhc.selectedActivity.isEvent);
      // verify all of the HRG activity was selected
      //System.assertEquals((rhc.getOnboardingFields().size()/2)+2,rhc.selectedActivity.hrgActivity.size());
      
      // select the second HRG Activity to get the id and remove it.
      
      ReferenceHRGActivity__c hag = [Select Id, Name 
                                       from ReferenceHRGActivity__c 
                                      where Reference_HRG__r.Account__c = :acct1.Id
                                        and Type__c = :ReferenceHRGActivityWrapper.ONSITE
                                        and Activity_Type__c = 'TestType'
                                        and Activity__c = 'TestActivity2' ];

      System.currentPageReference().getParameters().put('activityKey',rhc.openActivityList[0].key);
      System.currentPageReference().getParameters().put('hrgActivityId',hag.Id);
      System.currentPageReference().getParameters().put('actionType','deleteFromVerify');
      
      rhc.selectHrgActivity();
      // verify it is no longer with this activity
      System.assertEquals((rhc.getOnboardingFields().size()/2)+1,rhc.openActivityList[0].hrgActivity.size());
      
      // set the meeting not held flag
      rhc.openActivityList[0].evnt.Meeting_Not_Held__c = true;
      
      // try to save - should fail because no reason
      rhc.saveAndNewActivity();
      // still be on the form.
      System.assertEquals('Verify Activity',rhc.currentStep);
      rhc.openActivityList[0].evnt.Reason_Canceled__c = 'They did not want to meet on this day';

      rhc.saveAndNewActivity();
      
      // activity should be deleted. No more open activity - should go to the enter activity form
      System.assertEquals('What Did You Do',rhc.currentStep);

      // all the activity should be deleted
      System.assertEquals(0,[select count() from ReferenceHRGActivity__c]);
      
      // enter activity as a task
      // log activity against the onboarding activity
      for (ReferenceHrgActivityWrapper rhaw : rhc.onboardingActivityList) {
         rhaw.activity.Type__c = 'Phone';
         rhaw.activity.Notes__c = 'This is a Note';
         rhaw.activity.Activity_Date__c = Date.today().addDays(7);
      }
      
      // goto the next step
      rhc.setVerifyActivityStep();
      System.assertEquals('Verify Activity',rhc.currentStep);
      System.assertEquals((rhc.getOnboardingFields().size()/2),rhc.nbrActivityToConfirm);
      
      // save and enter more activity
      System.assertEquals(null,rhc.saveAndNewActivity());

      // should be one open activity.
      System.assertEquals('What Did You Do',rhc.currentStep);
      System.assertEquals(true,rhc.hasOpenActivityList);
      
      System.assertEquals(true,rhc.pendingHrgActivityList.size() > 0);
      
      // go to enter activity
      //rhc.setAskForWhatTheyDidStep();
      
      // onboarding is still open - haven't closed the activity yet
      System.assertEquals(true,rhc.showOnboarding);

      // enter a new activity with the same date.
      // add ongoing activity
      rhc.nbrNewOngoingActivities = 1;
      System.assertEquals(null,rhc.addOngoingActivity());

      // should be one
      System.assertEquals(1,rhc.ongoingActivityList.size());
      System.assertEquals(true,rhc.hasOngoingActivityList);

      // log activity against the ongoing activity
      //rhc.ongoingActivityList[0].logActivity=true;
      rhc.ongoingActivityList[0].activity.Type__c = 'Phone';
      rhc.ongoingActivityList[0].activity.Activity_Type__c = 'TestType';
      rhc.ongoingActivityList[0].activity.Activity__c = 'TestActivity1';
      rhc.ongoingActivityList[0].activity.Activity_Date__c = Date.today().addDays(7);
      
      // goto the next step
      rhc.setVerifyActivityStep();
      System.assertEquals('Verify Activity',rhc.currentStep);
      // there will be 1 new activity
      System.assertEquals(1,rhc.nbrActivityToConfirm);
      
      ActivityWrapper aw = rhc.activityToSaveList[0];
      System.assertEquals(false,aw.isNew);
      Date awActivityDate = aw.activityDate;
      Integer compareResult = aw.compareTo(aw);
      System.assertEquals(-1,aw.compareTo(null));
      
      aw.removeActivityByRecId('123456');
      
      // all onboarding + the one new HRG activity on the task
      System.assertEquals((rhc.getOnboardingFields().size()/2)+1,aw.hrgActivity.size());
      System.assertEquals(true,aw.isTask);
      
      // add the complete date
      aw.tsk.Date_Activity_Completed__c = Date.today().addDays(7);
      
      
      // save and return to the account
      PageReference retUrl = rhc.saveAndReturnToAcct();
      // will have failed because client summary is required when completed
      System.assertEquals(null,retUrl);

      rhc.logActivitySelection = ReferenceHRGController.LOG_THIS;
      aw.tsk.Client_Summary__c = 'This is a summary';
      retUrl = rhc.saveAndReturnToAcct();
      //System.assertEquals(true,retUrl.getUrl().contains(acct1.Id));
      
      // verify all of the HRG activity is saved and completed
      System.assertEquals((rhc.getOnboardingFields().size()/2)+1,[Select count() from ReferenceHRGActivity__c where Account__c=:acct1.Id and Closed__c=true]);
      
      // reenter the form, make sure onboarding is showing as closed
      System.CurrentPageReference().getParameters().put('acctId',acct1.Id);
      rhc = new ReferenceHRGController();

      System.assertEquals(true,rhc.onboardingIsComplete);

      System.assertEquals(false,rhc.showOnboarding);
      
      // make sure all the onboarding fields have a value

      /*
      
      // close all of the onboarding tasks
      // log activity against the onboarding activity
      for (ReferenceHrgActivityWrapper rhaw : rhc.onboardingActivityList) {
         rhaw.completed = true;
      }

      // goto the next step
      rhc.setVerifyActivityStep();
      System.assertEquals('Verify Activity',rhc.currentStep);
      System.assertEquals(rhc.onboardingActivityList.size(),rhc.nbrActivityToConfirm);
      
      // close the event
      rhc.selectedActivity.evnt.Date_Activity_Completed__c = Date.today();
      
      // save and enter more activity
      System.assertEquals(null,rhc.saveAndNewActivity());
      
      // should not be an open activity
      System.assertEquals(false,rhc.hasOpenActivityList);
      
      // select a task
      rhc.selectedActivity.taskOrEvent = 'Task';
      rhc.selectedActivity.activityContactId = ctct1.Id;
      rhc.refHRG.DateofLastVisit__c = Date.today().addDays(14);
      rhc.setAskForWhatTheyDidStep();
      
      // verify the step
      System.assertEquals('What Did You Do',rhc.currentStep);
      // change values in product utilization
      List<Schema.FieldSetMember> productFields = rhc.getProductFields();
      rhc.refHRG.put(productFields[0].getFieldPath(),'Active');
      rhc.refHRG.put(productFields[1].getFieldPath(),'Active');
      
      // add an ongoing activity
      // there should be one activity from before
      System.assertEquals(1,rhc.ongoingActivityList.size());

      // add an ongoing activity
      rhc.nbrNewOngoingActivities = 1;
      System.assertEquals(null,rhc.addOngoingActivity());

      // should be one now
      System.assertEquals(2,rhc.ongoingActivityList.size());

      // close both activities
      //rhc.ongoingActivityList[0].logActivity=true;
      rhc.ongoingActivityList[0].activity.Type__c = 'Phone';
      rhc.ongoingActivityList[0].activity.Activity_Type__c = 'TestType';
      rhc.ongoingActivityList[0].activity.Activity__c = 'TestActivity1';
      rhc.ongoingActivityList[0].completed = true;

      
      // try to goto the next step - will fail because Type__c will be required for task
      rhc.setVerifyActivityStep();
      System.assertEquals('What Did You Do',rhc.currentStep);

      rhc.ongoingActivityList[0].activity.Type__c = 'Email';

      
      rhc.setVerifyActivityStep();
      System.assertEquals('Verify Activity',rhc.currentStep);

      // save and enter more activity
      System.assertEquals(null,rhc.saveAndNewActivity());
      
      // select the existing task - should be open still
      System.assertEquals(true,rhc.hasOpenActivityList);
      
      // set the activity id we are selecting
      System.currentPageReference().getParameters().put('activityId',rhc.openActivityList[0].activityId);
      System.assertEquals(null,rhc.useExistingActivity());
      // should bring us to the next step.
      System.assertEquals('What Did You Do',rhc.currentStep);
      // goto the next step
      rhc.setVerifyActivityStep();
      System.assertEquals('Verify Activity',rhc.currentStep);
      // close the task
      rhc.selectedActivity.tsk.Date_Activity_Completed__c = Date.today();
      // return to the account
      PageReference returnPr = rhc.saveAndReturnToAcct();
      System.assertEquals(true,returnPr.getUrl().contains(acct1.Id));
      */
   } // testStandardUsageNoRef
    
   /** Test standard usage without a Reference object already created. */
   static testMethod void testNoAccountOnEntry() {
      // create an account and contacts to start from
      Account acct1 = new Account(Name='Test Account');
      insert acct1;
      Contact ctct1 = new Contact(AccountId=acct1.Id,FirstName='Test',LastName='One',Email='test.one@testaccount.com');
      Contact ctct2 = new Contact(AccountId=acct1.Id,FirstName='Test',LastName='Two',Email='test.two@testaccount.com');
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      insert ctcts;
      
      Test.SetCurrentPageReference(Page.ReferenceHRG);

      ReferenceHRGController rhc = new ReferenceHRGController();
      System.assertEquals(true,rhc.promptForAccount);
      
      System.assertEquals(rhc.currentStep,'Prompt For Account');
      
      // set the account
      rhc.refHRG.Account__c = acct1.Id;
      
      rhc.setAccount();

      System.assertEquals(rhc.currentStep,'What Did You Do');
      
      // change the account health
      rhc.changeAccountHealth();
      System.assertEquals(rhc.currentStep,'Account Health');
      
      rhc.acct.Premier_Account_Health__c = 'Low';
      
      // try to save - no notes entered so should fail
      rhc.setAccountHealth();
      System.assertEquals(rhc.currentStep,'Account Health');

      rhc.acctHealthActivity.Notes__c = 'Because I felt like it';      
      rhc.setAccountHealth();
      System.assertEquals(rhc.currentStep,'What Did You Do');
      System.assertEquals(true, rhc.hasHealthUpdate);
      
      // verify the value was saved
      System.assertEquals(1,[select count() from Account where Id=:acct1.Id and Premier_Account_Health__c='Low']);	  

   } // testNoAccountOnEntry

       /** Test standard usage without a Reference object already created. */
   static testMethod void testStandardController() {
      // create an account and contacts to start from
      Account acct1 = new Account(Name='Test Account');
      apexPages.StandardController acct1StandardController = new apexPages.StandardController(acct1);
      insert acct1;
      Contact ctct1 = new Contact(AccountId=acct1.Id,FirstName='Test',LastName='One',Email='test.one@testaccount.com');
      Contact ctct2 = new Contact(AccountId=acct1.Id,FirstName='Test',LastName='Two',Email='test.two@testaccount.com');
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      insert ctcts;
      
      Test.SetCurrentPageReference(Page.ReferenceHRG);

      ReferenceHRGController rhc = new ReferenceHRGController(acct1StandardController);
      System.assertEquals(false,rhc.promptForAccount);
       
      System.assertEquals(rhc.currentStep,'What Did You Do');
      
      // change the account health
      rhc.changeAccountHealth();
      System.assertEquals(rhc.currentStep,'Account Health');
      
      rhc.acct.Premier_Account_Health__c = 'Low';
      
      // try to save - no notes entered so should fail
      rhc.setAccountHealth();
      System.assertEquals(rhc.currentStep,'Account Health');

      rhc.acctHealthActivity.Notes__c = 'Because I felt like it';      
      rhc.setAccountHealth();
      System.assertEquals(rhc.currentStep,'What Did You Do');
      
      // verify the value was saved
      System.assertEquals(1,[select count() from Account where Id=:acct1.Id and Premier_Account_Health__c='Low']);


   } // testSCNoAccountOnEntry
   
   static testMethod void testControlledOwnerhip() {
      Account a1 = new Account(Name='Account 1');   
      Account a2 = new Account(Name='Account 2');  
      Account a3 = new Account(Name='Account 3');
      Account[] accts = new Account[]{a1,a2,a3};
      insert accts;
      
      // create children of one of them
      Account a4 = new Account(Name='Account 4',ParentId=a1.Id);
      Account a5 = new Account(Name='Account 5',ParentId=a1.Id);
      Account[] accts2 = new Account[]{a4,a5};
      insert accts2;
      
      accts.addAll(accts2);
      
      // get a plan code from the set
      String planCode = null;
      for (String tempPlanCode : ReferenceHRGController.PREMIER_PLAN_CODE_SET) {
         planCode = tempPlanCode;
         break;
      }
      // create premier products for each one - this is a criteria for selection
      Asset[] assets = new Asset[]{};
      for (Account acct : accts) {
         Asset asst = new Asset(AccountId=acct.Id, Name='Test Asset', Start_Date__c=Date.today().addDays(-30), Product_Plan_Code__c=planCode);
         assets.add(asst);
      }
      insert assets;
      
      // add running user as account team member on all
      AccountTeamMember[] teamMembers = new AccountTeamMember[]{};
      for (Account acct: accts) {
        AccountTeamMember atm = new AccountTeamMember(AccountId=acct.Id, UserId=UserInfo.getUserId(), TeamMemberRole =ZipCheckOwner.AT_HRG);
        teamMembers.add(atm);
      } // for
      insert teamMembers;
     
      Test.SetCurrentPageReference(Page.ReferenceHRG);
      System.CurrentPageReference().getParameters().put('acctId',a1.Id);
      ReferenceHRGController rhc = new ReferenceHRGController();

      // add ongoing activity
      rhc.nbrNewOngoingActivities = 2;
      System.assertEquals(null,rhc.addOngoingActivity());

      // should be two now
      System.assertEquals(2,rhc.ongoingActivityList.size());

      // log activity against the ongoing activity
      //rhc.ongoingActivityList[0].logActivity=true;
      rhc.ongoingActivityList[0].activity.Type__c = ReferenceHRGActivityWrapper.ONSITE;
      rhc.ongoingActivityList[0].activity.Activity_Type__c = 'TestType';
      rhc.ongoingActivityList[0].activity.Activity__c = 'TestActivity1';
      rhc.ongoingActivityList[0].activity.Activity_Date__c = Date.today().addDays(7);
      
      rhc.ongoingActivityList[1].activity.Type__c = 'Phone';
      rhc.ongoingActivityList[1].activity.Activity_Type__c = 'TestType';
      rhc.ongoingActivityList[1].activity.Activity__c = 'TestActivity2';
      rhc.ongoingActivityList[1].activity.Activity_Date__c = Date.today().addDays(7);
      
      // goto the next step
      rhc.setVerifyActivityStep();
      System.assertEquals('Verify Activity',rhc.currentStep);

      // verify there are 3 options - because we're on the parent of a controlled ownership
      System.assertEquals(3,rhc.logActivityOptions.size());
      
      // complete both of the activities - task should always be first
      ActivityWrapper awEvent = rhc.activityToSaveList[1];
      ActivityWrapper awTask = rhc.activityToSaveList[0];

      System.assertEquals(true,awEvent.isEvent);
      System.assertEquals(true,awTask.isTask);
      
      // add the complete date
      awEvent.evnt.Date_Activity_Completed__c = Date.today().addDays(7);
      awEvent.evnt.Client_Summary__c = 'This is a summary';
      awTask.tsk.Date_Activity_Completed__c = Date.today().addDays(7);
      awTask.tsk.Client_Summary__c = 'This is a summary';
      
      rhc.logActivitySelection = ReferenceHRGController.LOG_CLIENTS;
      // save and return to the account
      PageReference retUrl = rhc.saveAndReturnToAcct();

      // 1 task, 1 event, 2 hrg activities should be created
      System.assertEquals(1,[select count() from Task where createdById=:UserInfo.getUserId()]);
      System.assertEquals(1,[select count() from Event where createdById=:UserInfo.getUserId()]);
      System.assertEquals(2,[select count() from ReferenceHRGActivity__c where createdById=:UserInfo.getUserId()]);

      // should be brought to the screen for additional clients
      System.assertEquals('Additional Logging',rhc.currentStep);
      System.assertEquals(4,rhc.extraAcctsList.size());
      // select all of them
      rhc.selectAllOption = true;
      rhc.changeSelectAllOption();
      
      rhc.saveAdditionalActivity();
      // 5 tasks, 5 event, 10 hrg activities should be created
      System.assertEquals(5,[select count() from Task where createdById=:UserInfo.getUserId()]);
      System.assertEquals(5,[select count() from Event where createdById=:UserInfo.getUserId()]);
      System.assertEquals(10,[select count() from ReferenceHRGActivity__c where createdById=:UserInfo.getUserId()]);
     
   } // testControlledOwnerhip
   

} // class ReferenceHRGControllerTest