/* -------
*   07/15/2019  Jermaine Stukes Created
    03/01/2021  Dan Carmen      Adjust test user selection so tests pass.
    04/06/20201 Jermaine Stukes Added Auto Email Checkbox to Cadence
    07/02/2021  Dan Carmen      Adjust the code for email insights so it will work off the referral account, assuming emails are sent view the standard contact
    08/01/2021  Dan Carmen      Changes for SMB Channel Expansion
    11/17/2021 Dan Carmen           Add debugging
    05/14/2024 Pratik Das	        APR0159917/APR0169069: Added test for isLastStep
*/

@isTest
public class WorkQueueControllerTest {
   
   @testSetup
   Static void setupData() {
      //Create Account and contacts
      CreateTestData.createSingleAandTwoCtsNoTrigs();
      
      createTestCadence('Test Cadence', 'Payroll');

    } // setupData

   public static Cadence__c createTestCadence(String cadenceName, String cadenceType) {
      Cadence__c[] cads = createCadences(new String[]{cadenceName}, new String[]{cadenceType});
      return cads[0];
   } // createTestCadence

   // the arrays for cadenceNames and cadenceTypes should be the same size
   // create multiple cadences at once - better DML performance
   public static Cadence__c[] createCadences(String[] cadenceNames, String[] cadenceTypes) {
      Cadence__c[] cads = new Cadence__c[]{};
      for (Integer cnt=0; cnt<cadenceNames.size(); cnt++) {
         Cadence__c cad = new Cadence__c(Name=cadenceNames[cnt], Active__c = true, RepAdd__c = true);
         cad.Cadence_Type__c=cadenceTypes[cnt];
         cads.add(cad); 
      } // for (Integer cnt=0
      insert cads;

      // create 3 steps for each cadence      
      Cadence_Step__c[] steps = new Cadence_Step__c[]{};
      EmailTemplate template = [Select Id, Name from EmailTemplate where Folder.Name like 'MKTG%' limit 1];
      for (Cadence__c cad : cads) {
         Cadence_Step__c step1 = new Cadence_Step__c(Name='Step 1', CadenceId__c = cad.Id, Step_Number__c = 1, Wait_Days__c = 1, EmailTemplateIds__c=template.Id);
         WorkQueueController.generateStepList(cad.id);
         step1.Touchpoint_Type__c = 'Email';
         steps.add(step1);
            
         Cadence_Step__c step2 = new Cadence_Step__c(Name='Step 2', CadenceId__c = cad.Id, Step_Number__c = 2, Wait_Days__c = 1);
         step2.Touchpoint_Type__c = 'Call';
         step2.Generate_Activity__c = true;
         step2.Allow_Repeat__c = true;
         steps.add(step2);
        
         Cadence_Step__c step3 = new Cadence_Step__c(Name='Step 3', CadenceId__c = cad.Id, Step_Number__c = 3, Wait_Days__c = 1);
         step3.Touchpoint_Type__c = 'LinkedIn';
         step3.Generate_Activity__c = true;
         step3.Allow_Skip__c = true;
         steps.add(step3);
      } // for (Cadence cad : cads
      insert steps;
      return cads;
   } // createCadences
    
   public static Cadence__c getTestCadence(String cadenceName) {
      Cadence__c cad = [Select Id, Name
                             ,(Select Id, Name, Step_Number__c, Wait_Days__c, Touchpoint_Type__c, Generate_Activity__c, Allow_Skip__c
                                 from Cadence_Steps__r
                                 order by Step_Number__c)
                          From Cadence__c
                         Where Name=:cadenceName];
      return cad;
   } // getTestCadence
   
   Static testMethod void testCarMethods(){
        Cadence__c testCadence = getTestCadence('Test Cadence');
        //Create CAR
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        User uzer = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true and Job_Name__c != :UserHelper.JOB_REP limit 1];
        Account acct1 = CreateTestData.getTestAcct1();
        Contact ct1 = acct1.Contacts[0];
        Contact ct2 = acct1.Contacts[1];

        acct1.OwnerId = uzer.Id;
        acct1.SignificantContact__c = ct1.Id;
        update acct1;
        testCar.CadenceObject__c = acct1.Id;
        testCar.Cadence__c = testCadence.Id;
        ct1.OwnerId = uzer.Id;
        test.startTest();
        System.runAs(uzer)
        {
            insert testCar;
            Cadence_Touchpoint__c[] touchpoints = WorkQueueController.getOpenTouchpoints(uzer.Id);
            
            test.stopTest();
            WorkQueueController.getActivity(touchpoints[0]);
            WorkQueueController.getPastDueEmailTps(touchpoints);
            System.debug('TOUCHPOINT SIZE'+touchpoints.size());
            System.assertEquals(1,touchpoints.size());
            //WorkQueueController wqc = new WorkQueueController();
            WorkQueueController.TouchpointWrapper rw = new WorkQueueController.TouchpointWrapper();
            WorkQueueController.getEmailResponse('st');
            rw = WorkQueueController.getTouchpointsList('All Open Touchpoints',null);
            System.assert(rw!=null);
            //Generate Parent Info
            Account acctInfo = (Account)WorkQueueController.generateParentData(touchpoints[0]);
            System.assert(acctInfo!=null);
            //Generate Contact List
            WorkQueueController.ObjectInsightsWrapper oiw = WorkQueueController.getInsightList(touchpoints[0], true);
            System.assert(oiw.contactList[0].id == ct2.Id);
            //Update Significant Contact
            WorkQueueController.updateSigContact(touchpoints[0], ct2.Id);
            touchpoints = WorkQueueController.getOpenTouchpoints(uzer.Id);
            Cadence_Touchpoint__c touchpoint = touchpoints[0];
            //Cadence_Touchpoint__c touchpoint = [Select Id, CarRecord__r.SignificantContact__c, RepeatCount__c, Due_Date__c from Cadence_Touchpoint__c where Cadence__c=:testCadence.Id];
           // System.assertEquals(ct2.Id, touchpoint.CarRecord__r.SignificantContact__c);
            //Update Due Date
            Datetime newDueDate = Datetime.now().addDays(2);
            WorkQueueController.logStep(touchpoints[0], 'Repeat Step', null, newDueDate, 'test reason', null,'');
            //WorkQueueController.updateDD(touchpoints[0], Date.today() + 2, 'test reason');
            touchpoints = WorkQueueController.getOpenTouchpoints(uzer.Id);
            System.assertEquals(newDueDate, touchpoints[0].Due_Date__c);
            //Create Activity
            WorkQueueController.createTouchpointActivity(touchpoints[0],'test');
            List<Task> testTaskList = [Select id from Task where WhatId =: touchpoints[0].CarRecord__r.CadenceObject__c];
            System.assert(!testTaskList.isEmpty());
            //Skip Touchpoint
            WorkQueueController.skipThisTouchpoint(touchpoints[0],'test reason');
            System.assertNotEquals('Open', touchpoints[0].Status__c);     
            
        } 
    } // testCarMethods

    Static testMethod void testCloseCadence(){
        Cadence__c testCadence = getTestCadence('Test Cadence');
        //Create CAR
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        User uzer = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true and Job_Name__c != :UserHelper.JOB_REP limit 1];
        Account acct1 = CreateTestData.getTestAcct1();
        Contact ct1 = acct1.Contacts[0];
        Contact ct2 = acct1.Contacts[1];
        acct1.OwnerId = uzer.Id;
        acct1.SignificantContact__c = ct1.Id;
        update acct1;
        testCar.CadenceObject__c = acct1.Id;
        testCar.Cadence__c = testCadence.Id;
        ct1.OwnerId = uzer.Id;
        System.runAs(uzer)
        {
            insert testCar;
            Cadence_Touchpoint__c[] touchpoints = WorkQueueController.getOpenTouchpoints(uzer.Id);
            System.assertEquals(1,touchpoints.size());
            System.assertEquals(testCadence.Id, touchpoints[0].Cadence__c);
            Cadence_Touchpoint__c tp = touchpoints[0];
            test.startTest();
            WorkQueueController.removeFromCadence(touchpoints[0], 'test reason');
            test.stopTest();
            tp = [Select Id, Status__c, CarRecord__c 
                        ,CarRecord__r.Id
                        ,CarRecord__r.Closed__c
                        ,CarRecord__r.Close_Date__c
                        ,CarRecord__r.CloseReason__c
                        ,CarRecord__r.Status__c
                    from Cadence_Touchpoint__c where Id=:tp.Id];
            System.assertEquals('Canceled By Rep', tp.status__c);
            System.assertEquals(true,tp.CarRecord__r.Closed__c);
            System.assertEquals(Date.today(),tp.CarRecord__r.Close_Date__c);
            System.assertEquals('Closed',tp.CarRecord__r.Status__c);
            System.assertEquals('test reason',tp.CarRecord__r.CloseReason__c);
        } // System.runAs
    } // testCloseCadence

    Static testMethod void testProcessTouchpoint(){
        Cadence__c testCadence = getTestCadence('Test Cadence');
        //Create CAR
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        User uzer = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true and Job_Name__c != :UserHelper.JOB_REP limit 1];
        Account acct1 = CreateTestData.getTestAcct1();
        Contact ct1 = acct1.Contacts[0];
        Contact ct2 = acct1.Contacts[1];
        acct1.OwnerId = uzer.Id;
        acct1.SignificantContact__c = ct1.Id;
        update acct1;
        testCar.CadenceObject__c = acct1.Id;
        testCar.Cadence__c = testCadence.Id;
        ct1.OwnerId = uzer.Id;
        test.startTest();
        System.runAs(uzer)
        {
            insert testCar;
            Cadence_Touchpoint__c[] touchpoints = WorkQueueController.getOpenTouchpoints(uzer.Id);

            System.assertEquals(1, touchpoints.size());
            System.assertEquals(testCadence.Id, touchpoints[0].Cadence__c);
            WorkQueueController.logStep(touchpoints[0], 'Complete Step', 'TestNotes', null, null, null,'');
            //WorkQueueController.processTouchpoint(touchpoints[0], 'TestNotes');
            System.assertEquals('Closed', touchpoints[0].status__c);

            Cadence_Touchpoint__c tp = WorkQueueController.retrieveOpenTouchpoint(acct1.Id);
            System.assertNotEquals(null,tp);
            
            tp=WorkQueueController.retrieveOpenTouchpoint(tp.Id);
            WorkQueueController.updateCar(tp,'These are some cool notes');
        } 
        test.stopTest();
    } // testProcessTouchpoint
    
    static testMethod void testSkipTouchpoint() {
        Cadence__c testCadence = getTestCadence('Test Cadence');
        //Create CAR
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        User uzer = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true and Job_Name__c != :UserHelper.JOB_REP limit 1];
        Account acct1 = CreateTestData.getTestAcct1();
        Contact ct1 = acct1.Contacts[0];
        Contact ct2 = acct1.Contacts[1];
        acct1.OwnerId = uzer.Id;
        acct1.SignificantContact__c = ct1.Id;
        update acct1;
        testCar.CadenceObject__c = acct1.Id;
        testCar.Cadence__c = testCadence.Id;
        ct1.OwnerId = uzer.Id;
        test.startTest();
        System.runAs(uzer)
        {
            insert testCar;
            Cadence_Touchpoint__c[] touchpoints = WorkQueueController.getOpenTouchpoints(uzer.Id);
            WorkQueueController.skipThisTouchpoint(touchpoints, 'Test Auto Skipped', false);
            System.assertEquals('Auto Skipped', touchpoints[0].Status__c);
            System.assertEquals('Test Auto Skipped', touchpoints[0].Skip_Reason__c);
            System.assertEquals(Date.today(), touchpoints[0].Close_Date__c);
        } 
        test.stopTest();
        
    } // testSkipTouchpoint
    
    static testMethod void testAutoSkipLog() {
        Cadence__c testCadence = getTestCadence('Test Cadence');
        //Create CAR
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        User uzer = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true and Job_Name__c != :UserHelper.JOB_REP limit 1];
        Account acct1 = CreateTestData.getTestAcct1();
        Contact ct1 = acct1.Contacts[0];
        Contact ct2 = acct1.Contacts[1];
        acct1.OwnerId = uzer.Id;
        acct1.SignificantContact__c = ct1.Id;
        update acct1;
        testCar.CadenceObject__c = acct1.Id;
        testCar.Cadence__c = testCadence.Id;
        ct1.OwnerId = uzer.Id;
        test.startTest();
        System.runAs(uzer)
        {
            insert testCar;
            String activityString = 'Test Auto Skip Log';
            WorkQueueController.addAutoSkipLog(new Id[]{testCar.Id}, activityString);
            Cadence_Assignment_Record__c car = [Select Id, Activity_Log__c from Cadence_Assignment_Record__c where id =:testCar.Id];
            System.assert(car.Activity_Log__c.contains(activityString));
        } 
        test.stopTest();
       
        
    } // testAutoSkipLog
    
    Static testMethod void testSendEmailList(){
        Cadence__c testCadence = getTestCadence('Test Cadence');
        EmailTemplate template = [Select Id, Name from EmailTemplate where Folder.Name like 'MKTG%' limit 1];
        //Create CAR
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        User uzer = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true and Job_Name__c != :UserHelper.JOB_REP limit 1];
        Account acct1 = CreateTestData.getTestAcct1();
        Contact ct1 = acct1.Contacts[0];
        acct1.OwnerId = uzer.Id;
        acct1.SignificantContact__c = ct1.Id;
        update acct1;
        testCar.CadenceObject__c = acct1.Id;
        testCar.Cadence__c = testCadence.Id;
        testCar.Cadence_Owner__c=uzer.Id;
        ct1.OwnerId = uzer.Id;
        test.startTest();
        insert testCar;
        Cadence_Touchpoint__c[] touchpoints = WorkQueueController.getOpenTouchpoints(uzer.Id);
        WorkQueueController.EmailResponseWrapper testResponse = WorkQueueController.sendEmailList(touchpoints);
        System.assertEquals('Closed', touchpoints[0].Status__c);
        System.assertEquals('sendEmailList', touchpoints[0].EmailSentMethod__c);
        System.assertEquals('success', testResponse.toastType);
        test.stopTest();
    } // testSendEmailList
    
    Static testMethod void testSendEmail(){
        Cadence__c testCadence = getTestCadence('Test Cadence');
        //Create CAR
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        User uzer = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true and Job_Name__c != :UserHelper.JOB_REP limit 1];
        Account acct1 = CreateTestData.getTestAcct1();
        Contact ct1 = acct1.Contacts[0];
        Contact ct2 = acct1.Contacts[1];
        acct1.OwnerId = uzer.Id;
        acct1.SignificantContact__c = ct1.Id;
        update acct1;
        testCar.CadenceObject__c = acct1.Id;
        testCar.Cadence__c = testCadence.Id;
        ct1.OwnerId = uzer.Id; 
        test.startTest();
        System.runAs(uzer)
        {
            insert testCar;
            Cadence_Touchpoint__c[] touchpoints = WorkQueueController.getOpenTouchpoints(uzer.Id);
            WorkQueueController.sendMailMethod(touchpoints[0].CarRecord__r.SignificantContactEmail__c, 'testSubject','testbody',touchpoints[0],null,null,null );
            System.assertEquals('Closed', touchpoints[0].Status__c);
        } 
        test.stopTest(); 
    } // testSendEmail
    
    Static testMethod void testSendEmailTemplate(){
        Cadence__c testCadence = getTestCadence('Test Cadence');
        EmailTemplate template = [Select Id, Name from EmailTemplate where Folder.Name like 'MKTG%' limit 1];
        //Create CAR
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        User uzer = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true and Job_Name__c != :UserHelper.JOB_REP limit 1];
        Account acct1 = CreateTestData.getTestAcct1();
        Contact ct1 = acct1.Contacts[0];
        acct1.OwnerId = uzer.Id;
        acct1.SignificantContact__c = ct1.Id;
        update acct1;
        testCar.CadenceObject__c = acct1.Id;
        testCar.Cadence__c = testCadence.Id;
        //testCar.ParentAccountId__c = acct1.Id;
        testCar.Cadence_Owner__c=uzer.Id;
        ct1.OwnerId = uzer.Id;
        test.startTest();
        //System.runAs(uzer)
        //{
        insert testCar;
        Cadence_Touchpoint__c[] touchpoints = WorkQueueController.getOpenTouchpoints(uzer.Id);
        WorkQueueController.previewEmail(touchpoints[0].CarRecord__r.SignificantContactEmail__c ,touchpoints[0], template.Id, 'Just a little extra');
        WorkQueueController.sendMailMethod(touchpoints[0].CarRecord__r.SignificantContactEmail__c, 'testSubject','testbody',touchpoints[0],template.Id,template.Name,'Just something to say' );
        System.assertEquals('Closed', touchpoints[0].Status__c);
        WorkQueueController.ObjectInsightsWrapper oiw = WorkQueueController.getInsightList(touchpoints[0], false);
        System.assertEquals(1, oiw.contactList.size());
        //} 
        test.stopTest();
    } // testSendEmailTemplate

   static testMethod void testLeads() {
      Lead_Company__c leadComp = new Lead_Company__c(Name='Hogwarts', Address__c='123 Castle Rock', City__c='Hogwartsville', State__c='UK', Postal_Code__c='90340');
      insert leadComp;
       
      Lead ld1 = new Lead(FirstName='Harry', LastName='Potter', Company='Hogwarts', Title='Wizard', Street=leadComp.Address__c, City=leadComp.City__c);
      ld1.Phone='(555) 123-1111';
      ld1.Email='harry@hogwarts.com';
      ld1.State=leadComp.State__c;
      ld1.PostalCode=leadComp.Postal_Code__c;
      ld1.Lead_Company__c=leadComp.Id;
      Lead ld2 = new Lead(FirstName='Ron', LastName='Weasley', Company='Hogwarts', Title='Wizard', Street=leadComp.Address__c, City=leadComp.City__c);
      ld2.Phone='(555) 123-2222';
      ld2.Email='ron@hogwarts.com';
      ld2.State=leadComp.State__c;
      ld2.PostalCode=leadComp.Postal_Code__c;
      ld2.Lead_Company__c=leadComp.Id;
      Lead ld3 = new Lead(FirstName='Hermione', LastName='Grander', Company='Hogwarts', Title='Witch', Street=leadComp.Address__c, City=leadComp.City__c);
      ld3.Phone='(555) 123-3333';
      ld3.Email='hermione@hogwarts.com';
      ld3.State=leadComp.State__c;
      ld3.PostalCode=leadComp.Postal_Code__c;
      ld3.Lead_Company__c=leadComp.Id;
      Lead[] lds = new Lead[]{ld1,ld2,ld3};
      insert lds;
      
      Cadence__c testCadence = getTestCadence('Test Cadence');
      //Create CAR
      Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
      User usr = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true and Job_Name__c != :UserHelper.JOB_REP limit 1];
      testCar.CadenceObject__c = ld1.Id;
      testCar.Cadence__c = testCadence.Id;
      testCar.Cadence_Owner__c = usr.Id;

      test.startTest();
       System.runAs(usr) {
           insert testCar;
           Cadence_Touchpoint__c[] touchpoints = WorkQueueController.getOpenTouchpoints(usr.Id);
           System.assertEquals(1, touchpoints.size());
           System.assertEquals(testCadence.Id, touchpoints[0].Cadence__c);
           Lead checkLd = (Lead)WorkQueueController.generateParentData(touchpoints[0]);
           System.assert(checkLd!=null);
           
           
           WorkQueueController.ObjectInsightsWrapper oiw = WorkQueueController.getInsightList(touchpoints[0], true);
           Lead[] checkLeads = oiw.leadList;
           System.assertEquals(2,checkLeads.size());
           WorkQueueController.apexUpdateSignificant(touchpoints[0],ld3.Id);
           WorkQueueController.ObjectInsightsWrapper oiw2 = WorkQueueController.getInsightList(touchpoints[0], false);
           Lead[] checkLeads2 = oiw2.leadList;
           System.assertEquals(2,checkLeads2.size());
           Cadence_Touchpoint__c tp = WorkQueueController.retrieveOpenTouchpoint(ld1.Id);
       } // System.runAs
       
   } // testLeads

   static testMethod void testFilterSettings() {
      User testUser = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
      //WorkQueueController.SKIP_LIST_CHECK=true;
       System.runAs(testUser) {
           WorkQueueController.updateFilterSettings('CadenceName', 'TouchPoint', 'Program', '12345','List','1','ET','Client');
           WorkQueueController.TouchpointWrapper retWrapper = new WorkQueueController.TouchpointWrapper();
           WorkQueueController.getUserDefaults(retWrapper);
           System.assertEquals('CadenceName',retWrapper.lastFilterCadence);
           System.assertEquals('TouchPoint',retWrapper.lastFilterTouchpoint);
           System.assertEquals('Program',retWrapper.lastFilterSalesProgram);
           System.assertEquals('12345',retWrapper.lastFilterZip);
           System.assertEquals('List',retWrapper.lastFilterTarget);
           System.assertEquals('1',retWrapper.lastFilterStep);
           System.assertEquals('ET',retWrapper.lastFilterTimeZone);
         
      } // System.runAs(testUser
   } // testFilterSettings
    
    static testMethod void testOpportunity() {
       Account acct1 = CreateTestData.getTestAcct1();
       Contact ct1 = acct1.Contacts[0];
       Contact ct2 = acct1.Contacts[1];
       
       Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct1.Id, StageName='Pending', CloseDate=Date.today().addDays(7));
       Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct1.Id, StageName='Pending', CloseDate=Date.today().addDays(7));
       Opportunity[] opps = new Opportunity[]{opp1,opp2};
       OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
       insert opps;
        
       Cadence__c testCadence = getTestCadence('Test Cadence');
       //Create CAR
       Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
       testCar.CadenceObject__c = acct1.Id;
       testCar.Cadence__c = testCadence.Id;
       testCar.Cadence_Owner__c = UserInfo.getUserId();
       insert testCar;
        
       Cadence_Touchpoint__c[] touchpoints = WorkQueueController.getOpenTouchpoints(UserInfo.getUserId());
       System.assertEquals(1, touchpoints.size());
       
       WorkQueueController.OppWrap[] oppWraps = WorkQueueController.generateOpptyList(touchpoints[0]);
       System.assertEquals(2,oppWraps.size());
        
       WorkQueueController.OppWrap oppWrap1 = oppWraps[0];
       System.assertEquals(true,oppWrap1.oppName.startsWith('Opp'));
       System.assertEquals('Pending',oppWrap1.status);
       System.assertEquals(Date.today().addDays(7),oppWrap1.closeDate);
       System.assertEquals(UserInfo.getName(),oppWrap1.owner);
    } // testOpportunity

   static testMethod void testCloseReasons() {
      Cadence__c cad1 = new Cadence__c(Name='Cadence1', Cadence_Type__c='Type1', CloseReasons__c=null, OnlyUseCustomCloseReasons__c=false,Active__c=true);
      Cadence__c cad2 = new Cadence__c(Name='Cadence2', Cadence_Type__c='Type2', CloseReasons__c='Close1,Close2', OnlyUseCustomCloseReasons__c=false,Active__c=true);
      Cadence__c cad3a = new Cadence__c(Name='Cadence3a', Cadence_Type__c='Type3', CloseReasons__c='Close3,Close4', OnlyUseCustomCloseReasons__c=true,Active__c=true);
      Cadence__c cad3b = new Cadence__c(Name='Cadence3b', Cadence_Type__c='Type3', CloseReasons__c=null, OnlyUseCustomCloseReasons__c=true,Active__c=true);
      Cadence__c cad3c = new Cadence__c(Name='Cadence3c', Cadence_Type__c='Type3', CloseReasons__c='Close5,Close6', OnlyUseCustomCloseReasons__c=false,Active__c=true);
      Cadence__c[] cads = new Cadence__c[]{cad1,cad2,cad3a,cad3b,cad3c};
      insert cads;
      
      Cadence_Close_Reasons__c ccrDefault = new Cadence_Close_Reasons__c(Name='Default', Cadence_Type__c='Default', Active__c=true, CloseReason__c='Default1,Default2,Default3');
      Cadence_Close_Reasons__c ccrType1 = new Cadence_Close_Reasons__c(Name='Type1', Cadence_Type__c='Type1', Active__c=true, CloseReason__c='Type1a,Type1b', OnlyUseCustomCloseReasons__c=true);
      Cadence_Close_Reasons__c ccrType2 = new Cadence_Close_Reasons__c(Name='Type2', Cadence_Type__c='Type2', Active__c=true, CloseReason__c='Type2a,Type2b', OnlyUseCustomCloseReasons__c=false);
      Cadence_Close_Reasons__c ccrType3a = new Cadence_Close_Reasons__c(Name='Type3', Cadence_Type__c='Type3', Active__c=true, CloseReason__c='Type3a,Type3b,Type3c', OnlyUseCustomCloseReasons__c=false);
      Cadence_Close_Reasons__c ccrType3b = new Cadence_Close_Reasons__c(Name='Type3', Cadence_Type__c='Type3', Active__c=false, CloseReason__c='Type3d,Type3e', OnlyUseCustomCloseReasons__c=false);
      Cadence_Close_Reasons__c ccrType3c = new Cadence_Close_Reasons__c(Name='Type3', Cadence_Type__c='Type3', Active__c=true, CloseReason__c='Type3f,Type3g', OnlyUseCustomCloseReasons__c=true);
      Cadence_Close_Reasons__c[] ccrs = new Cadence_Close_Reasons__c[]{ccrDefault,ccrType1,ccrType2,ccrType3a,ccrType3b,ccrType3c};
      insert ccrs;

      Cadence_Touchpoint__c tp = new Cadence_Touchpoint__c(Cadence__c=cad1.Id);      
      String[] reasons = WorkQueueController.generateCloseReasonList(tp);
      System.assertEquals(1,WorkQueueController.REASONS_QUERY_CNT);
      System.assertEquals(2,reasons.size());
      System.assertEquals(true,reasons.contains('Type1a'));
      System.assertEquals(true,reasons.contains('Type1b'));
      
      tp.Cadence__c=cad2.Id;
      reasons = WorkQueueController.generateCloseReasonList(tp);
      System.assertEquals(1,WorkQueueController.REASONS_QUERY_CNT);
      System.assertEquals(7,reasons.size());
      System.assertEquals(true,reasons.contains('Close1'));
      System.assertEquals(true,reasons.contains('Close2'));      
      System.assertEquals(true,reasons.contains('Type2a'));      
      System.assertEquals(true,reasons.contains('Type2b'));
      System.assertEquals(true,reasons.contains('Default1'));
      System.assertEquals(true,reasons.contains('Default2'));
      System.assertEquals(true,reasons.contains('Default3'));
      
      tp.Cadence__c=cad3a.Id;
      reasons = WorkQueueController.generateCloseReasonList(tp);
      System.assertEquals(1,WorkQueueController.REASONS_QUERY_CNT);
      System.assertEquals(2,reasons.size());
      System.assertEquals(true,reasons.contains('Close3'));
      System.assertEquals(true,reasons.contains('Close4'));      

      tp.Cadence__c=cad3b.Id;
      reasons = WorkQueueController.generateCloseReasonList(tp);
      System.debug('3b reasons='+reasons);
      System.assertEquals(1,WorkQueueController.REASONS_QUERY_CNT);
      System.assertEquals(8,reasons.size());
      System.assertEquals(true,reasons.contains('Type3a'));
      System.assertEquals(true,reasons.contains('Type3b'));      
      System.assertEquals(true,reasons.contains('Type3c'));      
      System.assertEquals(true,reasons.contains('Type3f'));
      System.assertEquals(true,reasons.contains('Type3g'));      
      System.assertEquals(true,reasons.contains('Default1'));
      System.assertEquals(true,reasons.contains('Default2'));
      System.assertEquals(true,reasons.contains('Default3'));

      tp.Cadence__c=cad3c.Id;
      reasons = WorkQueueController.generateCloseReasonList(tp);
      System.debug('3b reasons='+reasons);
      System.assertEquals(1,WorkQueueController.REASONS_QUERY_CNT);
      System.assertEquals(10,reasons.size());
      System.assertEquals(true,reasons.contains('Close5'));
      System.assertEquals(true,reasons.contains('Close6'));
      System.assertEquals(true,reasons.contains('Type3a'));
      System.assertEquals(true,reasons.contains('Type3b'));      
      System.assertEquals(true,reasons.contains('Type3c'));      
      System.assertEquals(true,reasons.contains('Type3f'));
      System.assertEquals(true,reasons.contains('Type3g'));      
      System.assertEquals(true,reasons.contains('Default1'));
      System.assertEquals(true,reasons.contains('Default2'));
      System.assertEquals(true,reasons.contains('Default3'));

   } // testCloseReasons
   
   static testMethod void testGetAssets() {
      Account acct = CreateTestData.getTestAcct1();
      Asset asst1 = new Asset(AccountId=acct.Id, Name='Pizza', Start_Date__c=Date.today().addDays(-7));
      Asset asst2 = new Asset(AccountId=acct.Id, Name='Baked Beans', Start_Date__c=Date.today().addDays(-8));
      Asset asst3 = new Asset(AccountId=acct.Id, Name='Liver', Start_Date__c=Date.today().addDays(-9), Plan_Cancel_Date__c=Date.today().addDays(-6), Plan_Lost_Reason__c='Yuck!');
      Asset asst4 = new Asset(AccountId=acct.Id, Name='Chocolate', Start_Date__c=Date.today().addDays(-10));
      Asset[] assts = new Asset[]{asst1,asst2,asst3,asst4};
      insert assts;
      
      WorkQueueController.AssetWrap[] wraps = WorkQueueController.getAssets(acct.Id);
      System.assertEquals(asst2.Name, wraps[0].assetName);
      System.assertEquals(asst2.Start_Date__c, wraps[0].startDate);
      System.assertEquals(asst2.Plan_Cancel_Date__c, wraps[0].endDate);
      System.assertEquals(asst2.Plan_Lost_Reason__c, wraps[0].lostReason);

      System.assertEquals(asst4.Name, wraps[1].assetName);
      System.assertEquals(asst4.Start_Date__c, wraps[1].startDate);
      System.assertEquals(asst4.Plan_Cancel_Date__c, wraps[1].endDate);
      System.assertEquals(asst4.Plan_Lost_Reason__c, wraps[1].lostReason);
   

      System.assertEquals(asst1.Name, wraps[2].assetName);
      System.assertEquals(asst1.Start_Date__c, wraps[2].startDate);
      System.assertEquals(asst1.Plan_Cancel_Date__c, wraps[2].endDate);
      System.assertEquals(asst1.Plan_Lost_Reason__c, wraps[2].lostReason);

      System.assertEquals(asst3.Name, wraps[3].assetName);
      System.assertEquals(asst3.Start_Date__c, wraps[3].startDate);
      System.assertEquals(asst3.Plan_Cancel_Date__c, wraps[3].endDate);
      System.assertEquals(asst3.Plan_Lost_Reason__c, wraps[3].lostReason);

   } // testGetAssets

    static testMethod void testUpdateTouchpointOwner(){
        Cadence__c testCadence = getTestCadence('Test Cadence');
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        Id currentUserId = UserInfo.getUserId();
        User uzer = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true and Job_Name__c != :UserHelper.JOB_REP limit 1];
        Account acct1 = CreateTestData.getTestAcct1();
        testCar.CadenceObject__c = acct1.Id;
        testCar.Cadence__c = testCadence.Id;
        testCar.OwnerId = currentUserId;
        insert testCar;
        test.startTest();
        System.runAs(uzer)
        {
            Cadence_Touchpoint__c tp = [Select Id, CarRecord__c, CarRecord__r.OwnerId, OwnerId, Cadence_Touchpoint_Step__r.Name, Status__c from Cadence_Touchpoint__c where CarRecord__r.AccountId__c =:acct1.Id limit 1];
            System.assertNotEquals(uzer.Id, tp.OwnerId);
            WorkQueueController.updateOwner(tp, false);
            System.assertEquals(uzer.Id, tp.OwnerId);
            System.assertNotEquals(uzer.Id, tp.CarRecord__r.OwnerId);
        } 
        test.stopTest();
    }//testUpdateTouchpointOwner
    static testMethod void testUpdateCadenceOwner() {
        Cadence__c testCadence = getTestCadence('Test Cadence');
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        Id currentUserId = UserInfo.getUserId();
        User uzer = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true and Job_Name__c != :UserHelper.JOB_REP limit 1];
        Account acct1 = CreateTestData.getTestAcct1();
        testCar.CadenceObject__c = acct1.Id;
        testCar.Cadence__c = testCadence.Id;
        testCar.OwnerId = currentUserId;
        insert testCar;
        test.startTest();
        System.runAs(uzer)
        {
            Cadence_Touchpoint__c tp = [Select Id, CarRecord__c, CarRecord__r.OwnerId, OwnerId, Status__c from Cadence_Touchpoint__c where CarRecord__r.AccountId__c =:acct1.Id limit 1];
            System.assertNotEquals(uzer.Id, tp.OwnerId);
            System.assertNotEquals(uzer.Id, tp.CarRecord__r.OwnerId);
            WorkQueueController.updateOwner(tp, true);
            System.assertEquals(uzer.Id, tp.OwnerId);
            System.assertEquals(uzer.Id, tp.CarRecord__r.OwnerId);
        } 
        test.stopTest();
    }//testUpdateCadenceOwner
    
   static testMethod void testOther() {
      Account acct = new Account(Name='Test Account');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id);
      insert ctct;
      acct.SignificantContact__c = ctct.Id;
      update acct;
       
      Lead ld = new Lead(FirstName='Test', LastName='Lead', Company='Test Lead Inc', PostalCode='14624');
      insert ld;
       
      Lead checkLd = WorkQueueController.queryLead(ld.Id);
      System.assertEquals(ld.Id, checkLd.Id);
       
      Contact checkCtct = WorkQueueController.queryContact(ctct.Id);
      System.assertEquals(ctct.Id, checkCtct.Id);
       
   } // testOther

   static testMethod void testSendMailMethod2() {
      Cadence__c testCadence = getTestCadence('Test Cadence');
      EmailTemplate template = [Select Id, Name from EmailTemplate where Folder.Name like 'MKTG%' limit 1];
      Account acct = new Account(Name='Test Account');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      Contact ctct1 = new Contact(FirstName='Test', LastName='Contact1', AccountId=acct.Id, Email='test1@dancontact.com');
      Contact ctct2 = new Contact(FirstName='Test', LastName='Contact2', AccountId=acct.Id, Email='test2@dancontact.com');
      Contact ctct3 = new Contact(FirstName='Test', LastName='Contact3', AccountId=acct.Id, Email='test3@dancontact.com');
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3};
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert ctcts;
     
      Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c(CadenceObject__c = acct.Id, Cadence__c = testCadence.Id, OwnerId = UserInfo.getUserId());
      insert testCar;
       
      Cadence_Touchpoint__c[] touchpoints = WorkQueueController.getOpenTouchpoints(UserInfo.getUserId());
      // should be one touchpoint returned
      System.assertEquals(1,touchpoints.size());
       
      String[] targetIds = new String[]{ctct1.Id,ctct2.Id,ctct3.Id};
      WorkQueueController.sendMailWithTargetIds(touchpoints[0], targetIds, template.Id, 'This is just a bit of extra text'); 
      System.assertEquals(3,WorkQueueController.nbrSuccess);
   } // testSendMailMethod2
    
    static testMethod void testCheckQueueOwner() {
      Group[] queues = [Select Id, Name from Group where Type = 'Queue' limit 1];
      
      // create assignment group name
      Assignment_Group_Name__c agn1 = new Assignment_Group_Name__c(Name=queues[0].Name);
      insert agn1;
      GroupMemberHelper.SKIP_FUTURE=true;
       
      Assignment_Group_Queues__c agq1 = new Assignment_Group_Queues__c(Name=queues[0].Name, QueueId__c=queues[0].Id, Active__c='True', Assignment_Group_Name__c=agn1.Id);
      insert agq1;
      
      User[] usrs = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 6];
      Assignment_Groups__c gm1 = new Assignment_Groups__c(Group_Name__c=agn1.Id, User__c=usrs[0].Id, Active__c='True');
      Assignment_Groups__c gm2 = new Assignment_Groups__c(Group_Name__c=agn1.Id, User__c=usrs[1].Id, Active__c='True');
      Assignment_Groups__c gm3 = new Assignment_Groups__c(Group_Name__c=agn1.Id, User__c=usrs[2].Id, Active__c='False');
      Assignment_Groups__c gm4 = new Assignment_Groups__c(Group_Name__c=agn1.Id, User__c=usrs[3].Id, Active__c='True');
      insert new Assignment_Groups__c[]{gm1,gm2,gm3,gm4};
          
      GroupMemberHelper.USE_CACHE=true;
      System.assertEquals(true,WorkQueueController.checkQueueOwner(queues[0].Id, new Id[]{usrs[0].Id}));
      System.assertEquals(true,WorkQueueController.checkQueueOwner(queues[0].Id, new Id[]{usrs[1].Id}));
      System.assertEquals(false,WorkQueueController.checkQueueOwner(queues[0].Id, new Id[]{usrs[2].Id}));
      System.assertEquals(true,WorkQueueController.checkQueueOwner(queues[0].Id, new Id[]{usrs[3].Id}));
      System.assertEquals(false,WorkQueueController.checkQueueOwner(queues[0].Id, new Id[]{usrs[4].Id}));
      System.assertEquals(false,WorkQueueController.checkQueueOwner(queues[0].Id, new Id[]{usrs[5].Id}));
      
   } // testCheckQueueOwner
    
    //APR0159917--Change Start
    Static testMethod void testIsLastStep(){
	
	Cadence__c testCadence = getTestCadence('Test Cadence');
	testCadence.Outcome_Required__c=true;
	update testCadence;
        //Create CAR
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        User uzer = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true and Job_Name__c != :UserHelper.JOB_REP limit 1];
        Account acct1 = CreateTestData.getTestAcct1();
        Contact ct1 = acct1.Contacts[0];
        Contact ct2 = acct1.Contacts[1];
        acct1.OwnerId = uzer.Id;
        acct1.SignificantContact__c = ct1.Id;
        update acct1;
        testCar.CadenceObject__c = acct1.Id;
        testCar.Cadence__c = testCadence.Id;
        ct1.OwnerId = uzer.Id;
        test.startTest();
        System.runAs(uzer)
        {
            insert testCar;
            Cadence_Touchpoint__c[] touchpoints = WorkQueueController.getOpenTouchpoints(uzer.Id);

            System.assertEquals(1, touchpoints.size());
            System.assertEquals(testCadence.Id, touchpoints[0].Cadence__c);
            WorkQueueController.logStep(touchpoints[0], 'Complete Step', 'TestNotes', null, null, null,'');
            //WorkQueueController.processTouchpoint(touchpoints[0], 'TestNotes');
            System.assertEquals('Closed', touchpoints[0].status__c);

            Cadence_Touchpoint__c tp = WorkQueueController.retrieveOpenTouchpoint(acct1.Id);
            System.assertNotEquals(null,tp);
            
            tp=WorkQueueController.retrieveOpenTouchpoint(tp.Id);
            WorkQueueController.isLastStep(tp.Cadence__c,Integer.valueOf(tp.Step_Number__c));
        } 
        test.stopTest();
}//APR0159917--Change End
    
} // class WorkQueueControllerTest