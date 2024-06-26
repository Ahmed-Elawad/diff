/*-- Test Class for WorkQueueController.
 * -------
   07/15/2019 Jermaine Stukes       Created
   08/05/2019 Dan Carmen            Modify to meet filter criteria
   04/23/2021  Dan Carmen          Add code for Referral_Account__c
   11/17/2021 Dan Carmen           Add debugging
   06/01/2022 Pujitha Madamanchi   APR0130779 Remove SignificantLead/SignificantContact
   06/20/2022 Dan Carmen        Update to Send to Partner routing
   02/10/2023 Pujitha Madamanchi   APR0131508 Recycle Lead/Contact when last step is closed with reason cadence completed
   03/14/2023 Pujitha Madamanchi   APR0148879 - Stamp Latest Campaign on Car record upon creation
   04/25/2023 Pujitha Madamanchi   APR0150818 - Update Lead/Contact Recycle reason when reason is Touchpoint Expired.
   09/26/2023 Pujitha Madamanchi   Close TP steps when DNC is set on Lead; Populate override fields while creating new touchpoint
   11/07/2023 Jaipal          Added testTextSkipstep method for APR0148811
   06/04/2024 Dan Carmen           Fixed tests that were failing.

*/

@isTest
public class CadenceUpdateTest {
   @testSetup
   public static void setupData() {
      setupTestCadence();
      CreateTestData.createSingleAandTwoCtsNoTrigs();
   } // setupData
    
    public static void setupTestCadence() {
        EmailTemplate et = [Select Id from EmailTemplate where TemplateType = 'Text' limit 1];
        //Create Cadence Information
        Cadence__c testCadence = new Cadence__c();
        testCadence.Name = 'TestCadence';
        testCadence.Active__c = true;
        testCadence.RepAdd__c = true;
        testCadence.Sales_Org__c = 'MMS';
        testCadence.Cadence_Type__c='Payroll';
        testCadence.DaysUntilExpiration__c=10;
        testCadence.StartsWithTAL__c=true;

        Cadence__c testCadence2 = new Cadence__c();
        testCadence2.Name = 'TestCadence2';
        testCadence2.Active__c = true;
        testCadence2.RepAdd__c = true;
        testCadence2.Sales_Org__c = 'PAY';
        testCadence2.Cadence_Type__c='Payroll';
        testCadence2.DaysUntilExpiration__c=10;
        testCadence2.StartsWithTAL__c=true;
        
        Cadence__c testCadence3 = new Cadence__c();
        testCadence3.Name = 'TestOngoing';
        testCadence3.Active__c = true;
        testCadence3.RepAdd__c = false;
        testCadence3.Sales_Org__c = 'PAY';
        testCadence3.Cadence_Type__c='Payroll';
        testCadence3.StartsWithTAL__c=false;
        testCadence3.TargetType__c='Ongoing Referral Source';
        testCadence3.CPARotation__c='BW - Week 1 & Week 3';
        testCadence3.ReferralSourceBusinessType2__c='Accounting Firm';
        testCadence3.ReferralType__c='Platinum;Gold;Silver;Bronze';
        
        Cadence__c testCadence4 = new Cadence__c();
        testCadence4.Name = 'TestCadence4';
        testCadence4.Active__c = true;
        testCadence4.RepAdd__c = true;
        testCadence4.Sales_Org__c = 'MMS';
        testCadence4.Cadence_Type__c='Inbound-Forms';
        testCadence4.DaysUntilExpiration__c=10;
        testCadence4.StartsWithTAL__c=true;

        Cadence__c testCadence5 = new Cadence__c();
        testCadence5.Name = 'TestCadence5';
        testCadence5.Active__c = true;
        testCadence5.RepAdd__c = true;
        testCadence5.Sales_Org__c = 'MMS';
        testCadence5.Cadence_Type__c='Inbound-Forms';
        testCadence5.DaysUntilExpiration__c=10;
        testCadence5.StartsWithTAL__c=true;
        testCadence5.OverrideOtherCARs__c=true;

        Cadence__c[] cads = new Cadence__c[]{testCadence,testCadence2,testCadence3,testCadence4,testCadence5};
        insert cads;
            
        //Create steps
        Cadence_Step__c cadStep1 = new Cadence_Step__c(Name='Step 1');
        cadStep1.CadenceId__c = testCadence.Id;
        cadStep1.Touchpoint_Type__c = 'Email';
        cadStep1.EmailTemplateIds__c = et.Id;
        cadStep1.Step_Number__c = 1;
        cadStep1.Wait_Days__c = 1;
            
        Cadence_Step__c cadStep2 = new Cadence_Step__c(Name='Step 2');
        cadStep2.CadenceId__c = testCadence.Id;
        cadStep2.Touchpoint_Type__c = 'Call';
        cadStep2.Step_Number__c = 2;
        cadStep2.Generate_Activity__c = true;
        cadStep2.Wait_Days__c = 1;
        cadStep2.Allow_Repeat__c = true;
        
        Cadence_Step__c cadStep3 = new Cadence_Step__c(Name='Step 3');
        cadStep3.CadenceId__c = testCadence.Id;
        cadStep3.Touchpoint_Type__c = 'LinkedIn';
        cadStep3.Step_Number__c = 3;
        cadStep3.Generate_Activity__c = true;
        cadStep3.Wait_Days__c = 1;
        cadStep3.Allow_Skip__c = true;
        
        Cadence_Step__c cadStep1b = new Cadence_Step__c(Name='Step 1');
        cadStep1b.CadenceId__c = testCadence2.Id;
        cadStep1b.Touchpoint_Type__c = 'Call';
        cadStep1b.Step_Number__c = 1;
        cadStep1b.Wait_Days__c = 1;
        cadStep1b.Generate_Activity__c = true;
        cadStep1b.Allow_Repeat__c = true;
            
        Cadence_Step__c cadStep2b = new Cadence_Step__c(Name='Step 2');
        cadStep2b.CadenceId__c = testCadence2.Id;
        cadStep2b.Touchpoint_Type__c = 'Email';
        cadStep2b.Step_Number__c = 2;
        cadStep2b.EmailTemplateIds__c = et.Id;
        cadStep2b.Wait_Days__c = 1;
        
        Cadence_Step__c cadStep1c = new Cadence_Step__c(Name='Step 1');
        cadStep1c.CadenceId__c = testCadence3.Id;
        cadStep1c.Touchpoint_Type__c = 'Call';
        cadStep1c.Step_Number__c = 1;
        cadStep1c.Wait_Days__c = 1;
        cadStep1c.WeekStart__c='1';
        cadStep1c.WeekEnd__c='1';
            
        Cadence_Step__c cadStep2c = new Cadence_Step__c(Name='Step 2');
        cadStep2c.CadenceId__c = testCadence3.Id;
        cadStep2c.Touchpoint_Type__c = 'Call';
        cadStep2c.Step_Number__c = 2;
        cadStep2c.WeekStart__c='3';
        cadStep2c.WeekEnd__c='3';

        Cadence_Step__c cadStep1d = new Cadence_Step__c(Name='Step 1');
        cadStep1d.CadenceId__c = testCadence4.Id;
        cadStep1d.Touchpoint_Type__c = 'Call';
        cadStep1d.Step_Number__c = 2;
        cadStep1d.WeekStart__c='3';
        cadStep1d.WeekEnd__c='3';

        Cadence_Step__c cadStep1e = new Cadence_Step__c(Name='Step 1');
        cadStep1e.CadenceId__c = testCadence5.Id;
        cadStep1e.Touchpoint_Type__c = 'Call';
        cadStep1e.Step_Number__c = 1;
        cadStep1e.WeekStart__c='3';
        cadStep1e.WeekEnd__c='3';

        Cadence_Step__c[] steps = new Cadence_Step__c[]{cadStep1,cadStep2,cadStep3,cadStep1b,cadStep2b,cadStep1c,cadStep2c,cadStep1d,cadStep1e};
        insert steps;
    } // setupTestCadence
    
    public static Cadence__c getTestCadence2() {
       return getTestCadence('TestCadence2');
    }
    
    public static Cadence__c getTestCadence() {
       return getTestCadence('TestCadence');
    } // getTestCadence

    public static Cadence__c getTestCadence3() {
       return getTestCadence('TestOngoing');
    } // getTestCadence3

    public static Cadence__c getTestCadence4() {
      return getTestCadence('TestCadence4');
   } // getTestCadence4
    
   public static Cadence__c getTestCadence5() {
      return getTestCadence('TestCadence5');
   } // getTestCadence5
    
    public static Cadence__c getTestCadence(String cadName) {
       Map<Id,Cadence__c> cadMap = CadenceHelper.getActiveCadenceMap();
       Cadence__c testCad = null;
       for (Cadence__c cad : cadMap.values()) {
          if (cad.Name==cadName) {
             testCad = cad;
             break;
          }
       } // for (Cadence__c cad : cadMap.values
       return testCad;
    } // getTestCadence
    
    public static Cadence_Touchpoint__c[] getTouchpoints(Id cadenceId) {
       Cadence_Touchpoint__c[] touchpoints = [Select Id
                         , AccountId__c
                         , Cadence__c
                         , Cadence__r.Name
                         , Cadence__r.Cadence_Type__c
                         , Close_Date__c
                         , ContactId__c
                         , LeadId__c
                         , NoEmailEligibleContacts__c
                         , OpportunityId__c
                         , Past_Due_Date__c
                         , Parent_ObjectEmail__c
                         , Parent_ObjectName__c
                         , Parent_ObjectStatus__c
                         , Parent_ObjectTelephone__c
                         , Cadence_Touchpoint_Step__c
                         , Due_Date__c
                         , ExpirationDate__c
                         , Instructions__c
                         , IsLatestTouchpoint__c
                         , Name
                         , ReferralAccount__c
                         , RepeatCount__c
                         , Status__c
                         , StepCounter__c
                         , Step_Number__c
                         , Step_Email_Template__c
                         , TypeFilter__c
                         , TouchpointObject__c
                         , leadId__r.Name
                         , Cadence_Touchpoint_Step__r.Activity_Call_Type__c
                         , Cadence_Touchpoint_Step__r.Activity_Type__c
                         , Cadence_Touchpoint_Step__r.Allow_Skip__c
                         , Cadence_Touchpoint_Step__r.Allow_Repeat__c
                         , Cadence_Touchpoint_Step__r.EmailTemplateIds__c
                         , Cadence_Touchpoint_Step__r.Generate_Activity__c
                         , Cadence_Touchpoint_Step__r.Name
                         , Cadence_Touchpoint_Step__r.Step_Number__c
                         , Cadence_Touchpoint_Step__r.Touchpoint_Type__c
                         , Cadence_Touchpoint_Step__r.EmailTemplateNames__c
                         , CarRecord__c
                         , CarRecord__r.AccountId__c
                         , CarRecord__r.Activity_Log__c
                         , CarRecord__r.CadenceObject__c
                         , CarRecord__r.Cadence__c
                         , CarRecord__r.CloseReason__c
                         , CarRecord__r.Close_Date__c
                         , CarRecord__r.Closed__c
                         , CarRecord__r.Rep_Closed__c
                         , CarRecord__r.ContactId__c
                         , CarRecord__r.Description__c
                         , CarRecord__r.EvaluateTouchpoints__c
                         , CarRecord__r.ExpirationDate__c
                         , CarRecord__r.LatestTouchpoint__c
                         , CarRecord__r.LeadId__c
                         , CarRecord__r.LeadCompanyId__c
                         , CarRecord__r.NbrOfTouchpoints__c
                         , CarRecord__r.OpportunityId__c
                         , CarRecord__r.ParentZip__c 
                         , CarRecord__r.ParentAccountId__c
                         , CarRecord__r.ReferralAccount__c
                         , CarRecord__r.Sales_Program__c
                         , CarRecord__r.Start_Date__c
                         , CarRecord__r.Started__c
                        /* , CarRecord__r.SignificantContact__c */
                         , CarRecord__r.SignificantContactName__c
                         , CarRecord__r.SignificantContactEmail__c
                         , CarRecord__r.SignificantContactPhone__c
                         , CarRecord__r.SignificantContactTitle__c
                        /* , CarRecord__r.SignificantLead__c */
                         , CarRecord__r.Sales_Notes__c
                         , CarRecord__r.Status__c
                         , CarRecord__r.Touchpoint_Created_Successfully__c
                      from Cadence_Touchpoint__c where Cadence__c=:cadenceId
                     order by StepCounter__c desc nulls last, CreatedDate desc]; //IsLatestTouchpoint__c desc,CreatedDate desc];
       return touchpoints;
    } // getTouchpoints

     Static testMethod void testCarCreationAcct(){
        CadenceUpdate.PERFORM_EXTRA_CHECK=false;
                 //Create Account and contacts
        //CreateTestData.createTestAandC();
        //EmailTemplate et = [Select Id from EmailTemplate where Name=:'Test Template For Cad'];
        //Create Cadence Information
        Cadence__c testCadence = getTestCadence();
        //Create CAR
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        User uzer = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
        Account acct1 = CreateTestData.getTestAcct1();
        Contact ct1 = acct1.Contacts[0];
        Contact ct2 = acct1.Contacts[1];

        acct1.OwnerId = uzer.Id;
        acct1.SignificantContact__c = ct1.Id;
        update acct1;
        testCar.CadenceObject__c = acct1.Id;
        testCar.Cadence__c = testCadence.Id;
        //testCar.ParentAccountId__c = acct1.Id;
        ct1.OwnerId = uzer.Id;
        test.startTest();
        System.runAs(uzer)
        {
            insert testCar;
            Cadence_Touchpoint__c[] touchpoints = getTouchpoints(testCadence.Id);

            System.debug('testCarCreationAcct touchpoints='+touchpoints.size());
            System.assert(!touchpoints.isEmpty());
            //WorkQueueController wqc = new WorkQueueController();

            WorkQueueController.TouchpointWrapper rw = new WorkQueueController.TouchpointWrapper();
            rw = WorkQueueController.getTouchpointsList('All Open Touchpoints',null);
            System.assert(rw!=null);
            //Update Due Date
            Datetime newDueDate = Datetime.now().addDays(2);
            WorkQueueController.logStep(touchpoints[0], 'Repeat Step', null, newDueDate, 'test reason', null, '');
            //WorkQueueController.updateDD(touchpoints[0], newDueDate, 'test reason');
            // a new touchpoint will be created, reselect
            touchpoints = getTouchpoints(testCadence.Id);
            System.debug('testCarCreationAcct after Repeat Step touchpoints='+touchpoints.size());
            for (Cadence_Touchpoint__c tp : touchpoints) {
                System.debug('testCarCreationAcct StepCounter__c='+tp.StepCounter__c+' due date='+tp.Due_Date__c);
            }
            System.assertEquals(newDueDate, touchpoints[0].Due_Date__c);
            //Skip Touchpoint
            WorkQueueController.skipThisTouchpoint(touchpoints[0],'test reason');
            System.assertNotEquals('Open', touchpoints[0].Status__c);   
            //Close Cadence
            WorkQueueController.removeFromCadence(touchpoints[0], 'test reason');
            System.assertEquals('Canceled By Rep', touchpoints[0].status__c);
            test.stopTest();            
        } 
    } // testCarCreationAcct
    
   Static testMethod void testCarCreationCtct(){
        CadenceUpdate.PERFORM_EXTRA_CHECK=false;
      Cadence__c testCadence = getTestCadence();
      User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      Account acct1 = CreateTestData.getTestAcct1();
      Contact ct1 = acct1.Contacts[0];
      Contact ct2 = acct1.Contacts[1];

      acct1.OwnerId = usr.Id;
      acct1.SignificantContact__c = ct1.Id;
      update acct1;
      Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
      testCar.CadenceObject__c = ct1.Id;
      testCar.Cadence__c = testCadence.Id;
      ct1.OwnerId = usr.Id;
      test.startTest();
      System.runAs(usr) {
         insert testCar;
         Cadence_Touchpoint__c[] touchpoints = getTouchpoints(testCadence.Id);
         System.assertEquals(1,touchpoints.size());
         Cadence_Assignment_Record__c car = touchpoints[0].CarRecord__r;
         System.assertEquals(acct1.Id, car.AccountId__c);
         System.assertEquals(ct1.Id, car.ContactId__c);
      } // System.runAs
   } // testCarCreationCtct
    
   static testMethod void testCarCreationLead() {
      CadenceUpdate.PERFORM_EXTRA_CHECK=false;
      Cadence__c testCadence = getTestCadence();
      Campaign camp1 = new Campaign(Name='Campaign1', IsActive=true);
      insert camp1;
      User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      Lead ld = new Lead(LastName='Lead1', FirstName='Test', Company='Test Company', PostalCode='12345', OwnerId=usr.Id, LatestCampaign__c=camp1.Id);
      insert ld;
      Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
      testCar.CadenceObject__c = ld.Id;
      testCar.Cadence__c = testCadence.Id;
      System.runAs(usr) {
         insert testCar;
         Cadence_Touchpoint__c[] touchpoints = getTouchpoints(testCadence.Id);
         System.assertEquals(1,touchpoints.size());
         Cadence_Assignment_Record__c car = touchpoints[0].CarRecord__r;
         System.assertEquals(ld.Id, car.LeadId__c);
       //  System.assertEquals(ld.Id, car.SignificantLead__c);
      } // System.runAs
   } // testCarCreationLead
    static testMethod void testCarCreationOpportunity() {
        CadenceUpdate.PERFORM_EXTRA_CHECK=false;
        Cadence__c testCadence = getTestCadence();
        testCadence.Cadence_Type__c = 'NSS';
        Account acct1 = CreateTestData.getTestAcct1();
        User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
        Opportunity oppty = new Opportunity(Name='test opportunity', StageName='Pending', AccountId=acct1.Id, CloseDate = System.Today().addDays(7));
        insert oppty;
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        
        testCar.CadenceObject__c = oppty.Id;
        testCar.Cadence__c = testCadence.Id; 
        System.runAs(usr) {
            insert testCar;
            Cadence_Touchpoint__c[] touchpoints = getTouchpoints(testCadence.Id);
            System.assertEquals(1,touchpoints.size());
            Cadence_Assignment_Record__c car = touchpoints[0].CarRecord__r;
            System.assertEquals(acct1.Id, car.AccountId__c);
        } // System.runAs
    } // testCarCreationLead
    static testMethod void testFailedCarCreation() {
        CadenceUpdate.PERFORM_EXTRA_CHECK=false;
        Cadence__c testCadence = getTestCadence();
        User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
        Lead ld = new Lead(LastName='Lead1', FirstName='Test', Company='Test Company', PostalCode='12345', OwnerId=usr.Id);
        insert ld;
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        testCar.CadenceObject__c = ld.Id;
        System.runAs(usr) {
            insert testCar;
            Cadence_Touchpoint__c[] touchpoints = getTouchpoints(testCadence.Id);
            System.assertEquals(0,touchpoints.size());
            Cadence_Assignment_Record__c car = [Select Id,Touchpoint_Created_Successfully__c,Description__c from Cadence_Assignment_Record__c where Id=:testCar.Id];
            System.assertEquals(false, car.Touchpoint_Created_Successfully__c);
            System.assertEquals('Exception Caught: No cadence selected for CAR record', car.Description__c);
        } // System.runAs
    } // testCarCreationLead
    static testMethod void testFailedCarCreation2() {
        CadenceUpdate.PERFORM_EXTRA_CHECK=false;
        Cadence__c testCadence = getTestCadence();
        //Create CAR
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
        Schema.RecordTypeInfo acctRt = CreateTestData.getDefaultProspectAcctRT();
        Account acct1 =  new Account (name = 'Cadence Account'
                                ,recordtypeId = acctRt.getRecordTypeId()
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,AnnualRevenue = 25);
        insert acct1;
        testCar.CadenceObject__c = acct1.Id;
        testCar.Cadence__c = testCadence.Id;
        test.startTest();
        insert testCar;
        test.stopTest();
        Cadence_Touchpoint__c[] touchpoints = getTouchpoints(testCadence.Id);
        Cadence_Assignment_Record__c car = [Select Id,AccountId__c, AccountId__r.Do_Not_Call__c,Touchpoint_Created_Successfully__c,Description__c from Cadence_Assignment_Record__c where Id=:testCar.Id];
        System.assertEquals(0,touchpoints.size());
        System.assertEquals(false, car.Touchpoint_Created_Successfully__c);
        System.assertEquals('Exception Caught: Do Not Contact Company. Touchpoint not created', car.Description__c);
    } 

   static testMethod void testRejectRecycle() {
        CadenceUpdate.PERFORM_EXTRA_CHECK=false;
      CadenceUpdate.RejectRecycleReasons reasons = CadenceUpdate.getReasons();
      
      String[] rejectReasons = new String[]{};
      rejectReasons.addAll(reasons.rejectReasons);
      String rejectReason = rejectReasons[0];
      
      String[] recycleReasons = new String[]{};
      recycleReasons.addAll(reasons.recycleReasons);
      String recycleReason = recycleReasons[0];
      
      Cadence__c testCadence = getTestCadence();
      Cadence__c testCadence4 = getTestCadence4();
      User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      Lead ld1 = new Lead(LastName='Lead1', FirstName='Test', Company='Test Company1', PostalCode='12345', OwnerId=usr.Id, Lead_Stage__c='TAL');
      Lead ld2 = new Lead(LastName='Lead2', FirstName='Test', Company='Test Company2', PostalCode='12345', OwnerId=usr.Id, Lead_Stage__c='TAL');
      Lead ld3 = new Lead(LastName='Lead3', FirstName='Test', Company='Test Company3', PostalCode='12345', OwnerId=usr.Id, Lead_Stage__c='TAL');
      Lead ld4 = new Lead(LastName='Lead4', FirstName='Test', Company='Test Company4', PostalCode='12345', OwnerId=usr.Id, Lead_Stage__c='TAL');
      Lead[] lds = new Lead[]{ld1,ld2,ld3,ld4};
      insert lds;
      Account acct1 = CreateTestData.getTestAcct1();
      Contact ctct1 = acct1.Contacts[0];

      acct1.OwnerId = usr.Id;
      acct1.SignificantContact__c = ctct1.Id;
      update acct1;
      
      Contact updateCtct = new Contact(Id=ctct1.Id, Contact_Stage__c='TAL');
      update updateCtct;
      
      Cadence_Assignment_Record__c testCar1 = new Cadence_Assignment_Record__c(CadenceObject__c=ld1.Id, Cadence__c = testCadence.Id);
      Cadence_Assignment_Record__c testCar2 = new Cadence_Assignment_Record__c(CadenceObject__c=ld2.Id, Cadence__c = testCadence.Id);
      Cadence_Assignment_Record__c testCar3 = new Cadence_Assignment_Record__c(CadenceObject__c=ld3.Id, Cadence__c = testCadence.Id);
      Cadence_Assignment_Record__c testCar4 = new Cadence_Assignment_Record__c(CadenceObject__c=ctct1.Id, Cadence__c = testCadence.Id);
      Cadence_Assignment_Record__c testCar5 = new Cadence_Assignment_Record__c(CadenceObject__c=ld4.Id, Cadence__c = testCadence4.Id);
      Cadence_Assignment_Record__c[] cars = new Cadence_Assignment_Record__c[]{testCar1,testCar2,testCar3,testCar4,testCar5};
      System.runAs(usr) {
         insert cars;
         testCar1.Closed__c=true;
         testCar1.Status__c='Closed';
         testCar1.CloseReason__c=rejectReason;
         
         testCar2.Closed__c=true;
         testCar2.Status__c='Closed';
         testCar2.CloseReason__c=recycleReason;

         testCar3.Closed__c=true;
         testCar3.Status__c='Closed';
         testCar3.CloseReason__c='Because I feel like it';

         testCar4.Closed__c=true;
         testCar4.Status__c='Closed';
         testCar4.CloseReason__c=recycleReason;

         testCar5.Closed__c=true;
         testCar5.Status__c='Closed';
         testCar5.CloseReason__c='Cadence Completed';
         
         update cars;
      } // System.runAs
      
      Map<Id,Lead> leadMap = new Map<Id,Lead>([Select Id, Name, Lead_Stage__c, Reject_Reason__c, Reject_Stage_Date__c, Recycle_Reason__c, Recycle_Stage_Date__c from Lead]);
      Lead checkLd1 = leadMap.get(ld1.Id);
      System.assertEquals('Reject',checkLd1.Lead_Stage__c);
      System.assertEquals(rejectReason, checkLd1.Reject_Reason__c);
      System.assertEquals(Date.today(),checkLd1.Reject_Stage_Date__c.date());
      System.assertEquals(null, checkLd1.Recycle_Reason__c);
      System.assertEquals(null,checkLd1.Recycle_Stage_Date__c);
      
      Lead checkLd2 = leadMap.get(ld2.Id);
      System.assertEquals('Recycle',checkLd2.Lead_Stage__c);
      System.assertEquals(null, checkLd2.Reject_Reason__c);
      System.assertEquals(null,checkLd2.Reject_Stage_Date__c);
      System.assertEquals(recycleReason, checkLd2.Recycle_Reason__c);
      System.assertEquals(Date.today(),checkLd2.Recycle_Stage_Date__c.date());
    
      Lead checkLd3 = leadMap.get(ld3.Id);
      System.assertEquals('TAL',checkLd3.Lead_Stage__c);
      System.assertEquals(null, checkLd3.Reject_Reason__c);
      System.assertEquals(null,checkLd3.Reject_Stage_Date__c);
      System.assertEquals(null, checkLd3.Recycle_Reason__c);
      System.assertEquals(null,checkLd3.Recycle_Stage_Date__c);
      
      Contact checkCtct1 = [Select Id, Name, Contact_Stage__c, Reject_Reason__c, Reject_Stage_Date__c, Recycle_Reason__c, Recycle_Stage_Date__c from Contact where Id=:ctct1.Id];
      System.assertEquals('Recycle',checkCtct1.Contact_Stage__c);
      System.assertEquals(null, checkCtct1.Reject_Reason__c);
      System.assertEquals(null,checkCtct1.Reject_Stage_Date__c);
      System.assertEquals(recycleReason, checkCtct1.Recycle_Reason__c);
      System.assertEquals(Date.today(),checkCtct1.Recycle_Stage_Date__c.date());

      Lead checkLd4 = leadMap.get(ld4.Id);
      System.assertEquals('Recycle', checkLd4.Lead_Stage__c);
      System.assertEquals('Cadence Completed',checkLd4.Recycle_Reason__c);
   } // testRejectRecycle

   static testMethod void testExpiration() {
        CadenceUpdate.PERFORM_EXTRA_CHECK=false;
      Cadence__c cad = getTestCadence();

      User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      Lead ld1 = new Lead(LastName='Lead1', FirstName='Test', Company='Test Company1', PostalCode='12345', OwnerId=usr.Id, Lead_Stage__c='TAL', TAL_Stage_Date__c=Datetime.now().addDays(-3));
      Lead ld2 = new Lead(LastName='Lead2', FirstName='Test', Company='Test Company2', PostalCode='12345', OwnerId=usr.Id, Lead_Stage__c='TAL', TAL_Stage_Date__c=Datetime.now().addDays(-2));
      Lead ld3 = new Lead(LastName='Lead3', FirstName='Test', Company='Test Company3', PostalCode='12345', OwnerId=usr.Id, Lead_Stage__c='TAL', TAL_Stage_Date__c=null);
      Lead[] lds = new Lead[]{ld1,ld2,ld3};
      insert lds;
      Account acct1 = CreateTestData.getTestAcct1();
      Contact ctct1 = acct1.Contacts[0];

      acct1.OwnerId = usr.Id;
      acct1.SignificantContact__c = ctct1.Id;
      update acct1;
      
      Contact updateCtct = new Contact(Id=ctct1.Id, Contact_Stage__c='TAL', TAL_Stage_Date__c=Datetime.now().addDays(-1));
      update updateCtct;
      
      Datetime expireDate = Datetime.now().addDays(3);
      Stage_History__c histLd1 = new Stage_History__c(Expiration_Deadline__c=expireDate,Lead__c=ld1.Id,New_Stage__c='TAL');
      Stage_History__c histLd2 = new Stage_History__c(Expiration_Deadline__c=expireDate,Lead__c=ld2.Id,New_Stage__c='TAL');
      Stage_History__c histLd3 = new Stage_History__c(Expiration_Deadline__c=expireDate,Lead__c=ld3.Id,New_Stage__c='TAL');
      Stage_History__c histCtct1 = new Stage_History__c(Expiration_Deadline__c=expireDate,Contact__c=ctct1.Id,New_Stage__c='TAL');
      Stage_History__c[] histories = new Stage_History__c[]{histLd1,histLd2,histLd3,histCtct1};
      insert histories;
       
      Lead[] queryLeads = [Select Id, LastName, Lead_stage__c, TAL_Stage_Date__c, TimeZoneAbbrev__c
                                                          ,(Select Id, CreatedDate
                                                                  ,Exited_Date_Time__c
                                                                  ,Expiration_Deadline__c
                                                                  ,ExpirationMinutes__c
                                                                  ,ExpirationProcessed__c
                                                                  ,ProcessNotes__c
                                                              From Stage_History__r
                                                             Where New_Stage__c='TAL'
                                                               and StageIsCurrent__c=true
                                                               and Expired__c=false)
                                                      from Lead];
       for (Lead ld : queryLeads) {
           System.debug('testExpiration ld='+ld.LastName+' history='+ld.Stage_History__r.size());
       }

       
      Cadence_Assignment_Record__c testCar1 = new Cadence_Assignment_Record__c(CadenceObject__c=ld1.Id, Cadence__c = cad.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c testCar2 = new Cadence_Assignment_Record__c(CadenceObject__c=ld2.Id, Cadence__c = cad.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c testCar3 = new Cadence_Assignment_Record__c(CadenceObject__c=ld3.Id, Cadence__c = cad.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c testCar4 = new Cadence_Assignment_Record__c(CadenceObject__c=ctct1.Id, Cadence__c = cad.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c[] cars = new Cadence_Assignment_Record__c[]{testCar1,testCar2,testCar3,testCar4};
      
      Test.startTest();
      //System.runAs(usr) {
         insert cars;
      //} // System.runAs
      Test.stopTest();
      
      Map<Id,Cadence_Assignment_Record__c> carMap = new Map<Id,Cadence_Assignment_Record__c>([Select Id
                                                                                                    ,ExpirationDate__c
                                                                                                From Cadence_Assignment_Record__c]);
                                                                                                
      Map<Id,Stage_History__c> histMap = new Map<Id,Stage_History__c>([Select Id, Expiration_Deadline__c, New_Stage__c, StageIsCurrent__c, Expired__c
                                                                         From Stage_History__c]);
                                                                         

      Cadence_Assignment_Record__c chkCar1 = carMap.get(testCar1.Id);
      Stage_History__c checkHistLd1 = histMap.get(histLd1.Id);
      System.debug('testExpiration chkCar1='+chkCar1+' checkHistLd1='+checkHistLd1);
      System.assertNotEquals(null, chkCar1.ExpirationDate__c);
      System.assertEquals(checkHistLd1.Expiration_Deadline__c, chkCar1.ExpirationDate__c);
      System.assertEquals(true, checkHistLd1.Expiration_Deadline__c > expireDate);
     
      Cadence_Assignment_Record__c chkCar2 = carMap.get(testCar2.Id);
      Stage_History__c checkHistLd2 = histMap.get(histLd2.Id);
      System.debug('testExpiration chkCar2='+chkCar2+' checkHistLd2='+checkHistLd2);
      System.assertNotEquals(null, chkCar2.ExpirationDate__c);
      System.assertEquals(checkHistLd2.Expiration_Deadline__c, chkCar2.ExpirationDate__c);
      System.assertEquals(true, checkHistLd2.Expiration_Deadline__c > expireDate);
     
      Cadence_Assignment_Record__c chkCar3 = carMap.get(testCar3.Id);
      Stage_History__c checkHistLd3 = histMap.get(histLd3.Id);
      System.debug('testExpiration chkCar3='+chkCar3+' checkHistLd3='+checkHistLd3);
      System.assertNotEquals(null, chkCar3.ExpirationDate__c);
      System.assertEquals(checkHistLd3.Expiration_Deadline__c, chkCar3.ExpirationDate__c);
      System.assertEquals(true, checkHistLd3.Expiration_Deadline__c > expireDate);
     
      Cadence_Assignment_Record__c chkCar4 = carMap.get(testCar4.Id);
      Stage_History__c checkHistCtct1 = histMap.get(histCtct1.Id);
      System.debug('testExpiration chkCar4='+chkCar4+' checkHistCtct1='+checkHistCtct1);
      System.assertNotEquals(null, chkCar4.ExpirationDate__c);
      System.assertEquals(checkHistCtct1.Expiration_Deadline__c, chkCar4.ExpirationDate__c);
      System.assertEquals(true, checkHistCtct1.Expiration_Deadline__c > expireDate);
     
     
   } // testExpiration
    
   Static testMethod void testCarCreationMultipleCtct(){
      CadenceUpdate.PERFORM_EXTRA_CHECK=false;
      Cadence__c testCadence = getTestCadence();
      User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      Account acct1 = CreateTestData.getTestAcct1();
      Contact ct1 = acct1.Contacts[0];
      Contact ct2 = acct1.Contacts[1];
      Contact ct3 = new Contact(AccountId=acct1.Id, LastName='Contact3');
      Contact ct4 = new Contact(AccountId=acct1.Id, LastName='Contact4');
      Contact ct5 = new Contact(AccountId=acct1.Id, LastName='Contact5');
      Contact ct6 = new Contact(AccountId=acct1.Id, LastName='Contact6');
      Contact ct7 = new Contact(AccountId=acct1.Id, LastName='Contact7');
      Contact[] ctcts = new Contact[]{ct3,ct4,ct5,ct6,ct7};
      insert ctcts;

      acct1.OwnerId = usr.Id;
      acct1.SignificantContact__c = ct1.Id;
      update acct1;
      Cadence_Assignment_Record__c testCar1 = new Cadence_Assignment_Record__c(Name='testCar1',CadenceObject__c = ct1.Id,Cadence__c = testCadence.Id, Cadence_Owner__c=usr.Id );
      Cadence_Assignment_Record__c testCar2 = new Cadence_Assignment_Record__c(Name='testCar2',CadenceObject__c = ct2.Id,Cadence__c = testCadence.Id, Cadence_Owner__c=usr.Id );
      Cadence_Assignment_Record__c testCar3 = new Cadence_Assignment_Record__c(Name='testCar3',CadenceObject__c = ct3.Id,Cadence__c = testCadence.Id, Cadence_Owner__c=usr.Id );
      Cadence_Assignment_Record__c testCar4 = new Cadence_Assignment_Record__c(Name='testCar4',CadenceObject__c = ct4.Id,Cadence__c = testCadence.Id, Cadence_Owner__c=usr.Id );
      Cadence_Assignment_Record__c testCar5 = new Cadence_Assignment_Record__c(Name='testCar5',CadenceObject__c = ct5.Id,Cadence__c = testCadence.Id, Cadence_Owner__c=usr.Id );
      Cadence_Assignment_Record__c testCar6 = new Cadence_Assignment_Record__c(Name='testCar6',CadenceObject__c = ct6.Id,Cadence__c = testCadence.Id, Cadence_Owner__c=usr.Id );
      Cadence_Assignment_Record__c testCar7 = new Cadence_Assignment_Record__c(Name='testCar7',CadenceObject__c = ct7.Id,Cadence__c = testCadence.Id, Cadence_Owner__c=usr.Id );
      Cadence_Assignment_Record__c[] cars = new Cadence_Assignment_Record__c[]{testCar1,testCar2,testCar3,testCar4,testCar5,testCar6,testCar7};
       
      test.startTest();
      System.runAs(usr) {
         insert cars;
         Cadence_Touchpoint__c[] touchpoints = getTouchpoints(testCadence.Id);
         System.assertEquals(1,touchpoints.size());
         Cadence_Assignment_Record__c car = touchpoints[0].CarRecord__r;
         System.assertEquals(acct1.Id, car.AccountId__c);
         System.assertEquals(ct1.Id, car.ContactId__c);
      } // System.runAs
   } // testCarCreationMultipleCtct
    
   static testMethod void testCarOverride() {
      Cadence__c testCadence = getTestCadence();
      User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      Account acct1 = CreateTestData.getTestAcct1();
      Contact ct1 = acct1.Contacts[0];
      acct1.OwnerId = usr.Id;
      acct1.SignificantContact__c = ct1.Id;
      update acct1;
      Cadence_Assignment_Record__c testCar1 = new Cadence_Assignment_Record__c(Name='testCar1',CadenceObject__c = ct1.Id,Cadence__c = testCadence.Id, Cadence_Owner__c=usr.Id );
      insert testCar1;
      Cadence_Touchpoint__c[] touchpoints = getTouchpoints(testCadence.Id);
      System.assertEquals(1,touchpoints.size());
      System.assertEquals(testCar1.Id,touchpoints[0].CarRecord__c);
      // the second car should not open because we're not using the override
      Cadence_Assignment_Record__c testCar2 = new Cadence_Assignment_Record__c(Name='testCar2',CadenceObject__c = ct1.Id,Cadence__c = testCadence.Id, Cadence_Owner__c=usr.Id );
      TriggerMethods.clearVariables();
      insert testCar2;
       
      touchpoints = getTouchpoints(testCadence.Id);
      System.assertEquals(1,touchpoints.size());
      System.assertEquals(testCar1.Id,touchpoints[0].CarRecord__c);

      // the first car should close and this one should be open because of the override. 
      Cadence_Assignment_Record__c testCar3 = new Cadence_Assignment_Record__c(Name='testCar2',CadenceObject__c = ct1.Id,Cadence__c = testCadence.Id, Cadence_Owner__c=usr.Id,OverrideOtherCARs__c=true );
      TriggerMethods.clearVariables();
      insert testCar3;
       
      touchpoints = getTouchpoints(testCadence.Id);
      System.assertEquals(2,touchpoints.size());
      Boolean car1Found = false;
      Boolean car3Found = false;
      for (Cadence_Touchpoint__c tp : touchpoints) {
         if (tp.CarRecord__c == testCar1.Id) {
            Assert.areEqual('Closed',tp.Status__c);
            car1Found = true;
         } else if (tp.CarRecord__c == testCar3.Id) {
            Assert.areEqual('Open',tp.Status__c);
            car3Found = true;
         }
      }
      Assert.isTrue(car1Found);
      Assert.isTrue(car3Found);

   } // testCarOverride

   static testMethod void testRefAcct() {
      CadenceUpdate.PERFORM_EXTRA_CHECK=false;
      Cadence__c testCadence = getTestCadence();
      User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      
      Referral_Account__c refAcct1 = new Referral_Account__c(Name='Test Ref Acct1', Referral_Source_Business_Type__c='Accounting Firm', OwnerId=usr.Id, End_Date__c=null);
      Referral_Account__c refAcct2 = new Referral_Account__c(Name='Test Ref Acct1', Referral_Source_Business_Type__c='Accounting Firm', OwnerId=usr.Id, End_Date__c=Date.today());
      ReferralAccountMethods.SKIP_TRIGGERS=true;      
      Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2};
      insert refAccts;
       
      Cadence_Assignment_Record__c car1 = new Cadence_Assignment_Record__c(CadenceObject__c=refAcct1.Id, Cadence__c=testCadence.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c car2 = new Cadence_Assignment_Record__c(CadenceObject__c=refAcct2.Id, Cadence__c=testCadence.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c[] testCars = new Cadence_Assignment_Record__c[]{car1,car2};

      test.startTest();
      System.runAs(usr) {
         insert testCars;
         Cadence_Touchpoint__c[] touchpoints = getTouchpoints(testCadence.Id);
         // should only be one touchpoint since the second has an end date
         System.assertEquals(1,touchpoints.size());
         Cadence_Touchpoint__c tp = touchpoints[0];
         System.assertEquals(tp.ReferralAccount__c, refAcct1.Id);
         Cadence_Assignment_Record__c car = touchpoints[0].CarRecord__r;
         System.assertEquals(car.ReferralAccount__c, refAcct1.Id);
         System.assertEquals(null,car.CloseReason__c);
         System.assertEquals(true,car.Touchpoint_Created_Successfully__c);
         System.assertEquals(false,car.Closed__c);
         System.assertEquals('Open',car.Status__c);
         //System.assertEquals(true,car.Started__c);
         System.assertEquals(null,car.Close_Date__c);

      } // System.runAs

      Cadence_Assignment_Record__c testCar2 = [Select Id, ReferralAccount__c, CadenceObject__c, Closed__c, Status__c, Started__c, Close_Date__c, CloseReason__c
                                                     ,Touchpoint_Created_Successfully__c
                                                 from Cadence_Assignment_Record__c where CadenceObject__c=:refAcct2.Id];
      System.assertEquals('Firm End Dated',testCar2.CloseReason__c);
      System.assertEquals(false,testCar2.Touchpoint_Created_Successfully__c);
      System.assertEquals(true,testCar2.Closed__c);
      System.assertEquals('Closed',testCar2.Status__c);
      System.assertEquals(false,testCar2.Started__c);
      System.assertEquals(Date.today(),testCar2.Close_Date__c);
   } // testRefAcct
    
   static testMethod void testRefAcctMultipleCadences() {
      CadenceUpdate.PERFORM_EXTRA_CHECK=false;
      Cadence__c testCadence = getTestCadence();
      Cadence__c testCadence2 = getTestCadence2();
      User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];

      Referral_Account__c refAcct1 = new Referral_Account__c(Name='Test Ref Acct1', Referral_Source_Business_Type__c='Accounting Firm', OwnerId=usr.Id, End_Date__c=null);
      ReferralAccountMethods.SKIP_TRIGGERS=true;      
      Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1};
      insert refAccts;
       
      Cadence_Assignment_Record__c car1 = new Cadence_Assignment_Record__c(CadenceObject__c=refAcct1.Id, Cadence__c=testCadence.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c car2 = new Cadence_Assignment_Record__c(CadenceObject__c=refAcct1.Id, Cadence__c=testCadence2.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c[] testCars = new Cadence_Assignment_Record__c[]{car1,car2};

      test.startTest();
      System.runAs(usr) {
         insert testCars;
         Cadence_Touchpoint__c[] touchpoints = getTouchpoints(testCadence.Id);
         // should be one touchpoint for each cadence
         System.assertEquals(1,touchpoints.size());
         Cadence_Touchpoint__c tp = touchpoints[0];
         System.assertEquals(tp.ReferralAccount__c, refAcct1.Id);
         Cadence_Assignment_Record__c car = touchpoints[0].CarRecord__r;
         System.assertEquals(car.ReferralAccount__c, refAcct1.Id);
         System.assertEquals(null,car.CloseReason__c);
         System.assertEquals(true,car.Touchpoint_Created_Successfully__c);
         System.assertEquals(false,car.Closed__c);
         System.assertEquals('Open',car.Status__c);
         //System.assertEquals(true,car.Started__c);
         System.assertEquals(null,car.Close_Date__c);

         touchpoints = getTouchpoints(testCadence2.Id);
         // should be one touchpoint for each cadence
         System.assertEquals(1,touchpoints.size());
         tp = touchpoints[0];
         System.assertEquals(tp.ReferralAccount__c, refAcct1.Id);
         car = touchpoints[0].CarRecord__r;
         System.assertEquals(car.ReferralAccount__c, refAcct1.Id);
         System.assertEquals(null,car.CloseReason__c);
         System.assertEquals(true,car.Touchpoint_Created_Successfully__c);
         System.assertEquals(false,car.Closed__c);
         System.assertEquals('Open',car.Status__c);
         //System.assertEquals(true,car.Started__c);
         System.assertEquals(null,car.Close_Date__c);

      } // System.runAs

   } // testRefAcctMultipleCadences

   static testMethod void testFYDates() {
      // test getting the week numbers - we're going to test using a day in the second week of FY22
      Date testDate = Date.newInstance(2021, 6, 5);
      // default the date so we can control the results
      CadenceUpdate.CUR_DATE = testDate;
      System.assertEquals(2,CadenceUpdate.getWeekNbr(testDate));
      CadenceUpdate.Week wk = CadenceUpdate.getWeek(0);
      System.assertEquals(null,wk);
      wk = CadenceUpdate.getWeek(6);
      System.assertEquals(null,wk);
      wk = CadenceUpdate.getWeek(2);
      System.assertNotEquals(null,wk);
      // get the current week dates
      System.assertEquals(Date.newInstance(2021,6,4), wk.startDate);
      System.assertEquals(Date.newInstance(2021,6,10), wk.endDate);
      wk = CadenceUpdate.getWeek(3);
      // get next week
      System.assertEquals(Date.newInstance(2021,6,11), wk.startDate);
      System.assertEquals(Date.newInstance(2021,6,17), wk.endDate);
      wk = CadenceUpdate.getWeek(1);
      // get the first week of the next month
      System.assertEquals(Date.newInstance(2021,7,2), wk.startDate);
      System.assertEquals(Date.newInstance(2021,7,8), wk.endDate);
      
   } // testFYDates
    
    Static testMethod void testTextSkipstep() {
      CadenceUpdate.PERFORM_EXTRA_CHECK=false;
      Cadence__c testCadence = getTestCadence();
      Campaign camp1 = new Campaign(Name='Campaign1', IsActive=true);
      insert camp1;
      User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      Lead ld = new Lead(LastName='Lead1', FirstName='Test', Company='Test Company' 
             ,PostalCode='12345', Phone='1234567890', email='testLead1@paychextest.com', OwnerId=usr.Id, LatestCampaign__c=camp1.Id
                         ,DoNotCall=false,HasOptedOutOfEmail=false );
      insert ld;
      Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
      testCar.CadenceObject__c = ld.Id;
      testCar.Cadence__c = testCadence.Id;
      insert testCar;
      Cadence_Step__c step1 = testCadence.Cadence_Steps__r[0];
        step1.Touchpoint_Type__c = 'Email';
        update step1;
        Cadence_Step__c step2 = testCadence.Cadence_Steps__r[0];
        step1.Touchpoint_Type__c = 'Text';
        update step2;
      Cadence_Touchpoint__c tp = new Cadence_Touchpoint__c(Name='test touchpoint', Cadence_Touchpoint_Step__c=step1.Id, CarRecord__c=testCar.Id,LeadId__c=ld.Id, Status__c = 'Auto Skipped');
      insert tp;
        Cadence_Touchpoint__c tp1 = new Cadence_Touchpoint__c(Name='test touchpoint1', Cadence_Touchpoint_Step__c=step2.Id, CarRecord__c=testCar.Id,LeadId__c=ld.Id, Status__c = 'Open');
      insert tp1;
        tp.Status__c = 'Open';
        update tp;
      Lead checkLead = [Select Id, DoNotCall, Consent_To_Text__c, HasOptedOutOfEmail from Lead where Id=:ld.Id LIMIT 1];
      checkLead.Consent_To_Text__c = false;
      TriggerMethods.clearvariables();
      update checkLead;  
        
      Account acct1 = CreateTestData.getTestAcct1();
      Contact ct1 = acct1.Contacts[0];
      ct1.Current_SMS_Owner__c = '0123456789';
      acct1.OwnerId = usr.Id;
      acct1.SignificantContact__c = ct1.Id;
      update acct1;
     tp.AccountId__c = acct1.Id;
      tp.ContactId__c = ct1.Id;
     //   tp.ContactId__r.Current_SMS_Owner__c = '0123456789';
        update tp;
   } // testTextSkipstep
    
   static testMethod void testEmailCloseTp() {
      CadenceUpdate.PERFORM_EXTRA_CHECK=false;
      Cadence__c testCadence = getTestCadence();
      Campaign camp1 = new Campaign(Name='Campaign1', IsActive=true);
      insert camp1;
      User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      Lead ld = new Lead(LastName='Lead1', FirstName='Test', Company='Test Company' 
             ,PostalCode='12345', Phone='1234567890', email='testLead1@paychextest.com', OwnerId=usr.Id, LatestCampaign__c=camp1.Id
                         ,DoNotCall=false,HasOptedOutOfEmail=false );
      insert ld;
      Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
      testCar.CadenceObject__c = ld.Id;
      testCar.Cadence__c = testCadence.Id;
      insert testCar;
      Cadence_Step__c step1 = testCadence.Cadence_Steps__r[0];
      Cadence_Touchpoint__c tp = new Cadence_Touchpoint__c(Name='test touchpoint', Cadence_Touchpoint_Step__c=step1.Id, CarRecord__c=testCar.Id,LeadId__c=ld.Id );
      insert tp;
      Lead checkLead = [Select Id, DoNotCall, HasOptedOutOfEmail from Lead where Id=:ld.Id LIMIT 1];
      checkLead.HasOptedOutOfEmail = true;
      TriggerMethods.clearvariables();
      update checkLead;  
      Cadence_Touchpoint__c checkTp = [Select Id, Override_Email__c, Override_Call__c from Cadence_Touchpoint__c WHERE Id=:tp.Id LIMIT 1];
      System.debug('checkTp::'+checkTp);  
      Assert.areEqual(true, checkTp.Override_Email__c);
      Assert.areEqual(false, checkTp.Override_Call__c);
   } // testEmailCloseTp
    
   static testMethod void testCallCloseTp() {
      CadenceUpdate.PERFORM_EXTRA_CHECK=false;
      Cadence__c testCadence = getTestCadence2();
      Campaign camp1 = new Campaign(Name='Campaign1', IsActive=true);
      insert camp1;
      User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      Lead ld = new Lead(LastName='Lead1', FirstName='Test', Company='Test Company' 
             ,PostalCode='12345', Phone='1234567890', email='testLead1@paychextest.com', OwnerId=usr.Id, LatestCampaign__c=camp1.Id
                         ,DoNotCall=false,HasOptedOutOfEmail=false );
      insert ld;
      Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
      testCar.CadenceObject__c = ld.Id;
      testCar.Cadence__c = testCadence.Id;
      insert testCar;
      Cadence_Step__c step1 = testCadence.Cadence_Steps__r[0];
      Cadence_Touchpoint__c tp = new Cadence_Touchpoint__c(Name='test touchpoint', Cadence_Touchpoint_Step__c=step1.Id, CarRecord__c=testCar.Id,LeadId__c=ld.Id );
      insert tp;
      Lead checkLead = [Select Id, DoNotCall, HasOptedOutOfEmail from Lead where Id=:ld.Id LIMIT 1];
      checkLead.DoNotCall = true;
      TriggerMethods.clearvariables();
      update checkLead;  
      Cadence_Touchpoint__c checkTp = [Select Id, Override_Email__c, Override_Call__c from Cadence_Touchpoint__c WHERE Id=:tp.Id LIMIT 1];
      System.debug('checkTp::'+checkTp);  
      Assert.areEqual(false, checkTp.Override_Email__c);
      Assert.areEqual(true, checkTp.Override_Call__c);
   } // testCallCloseTp 
    
    static testMethod void testBothCloseTp() {
      CadenceUpdate.PERFORM_EXTRA_CHECK=false;
      Cadence__c testCadence = getTestCadence();
      Campaign camp1 = new Campaign(Name='Campaign1', IsActive=true);
      insert camp1;
      User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      Lead ld = new Lead(LastName='Lead1', FirstName='Test', Company='Test Company' 
             ,PostalCode='12345', Phone='1234567890', email='testLead1@paychextest.com', OwnerId=usr.Id, LatestCampaign__c=camp1.Id
                         ,DoNotCall=false,HasOptedOutOfEmail=false );
      insert ld;
      Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
      testCar.CadenceObject__c = ld.Id;
      testCar.Cadence__c = testCadence.Id;
      insert testCar;
      Cadence_Step__c step1 = testCadence.Cadence_Steps__r[0];
      Cadence_Touchpoint__c tp = new Cadence_Touchpoint__c(Name='test touchpoint', Cadence_Touchpoint_Step__c=step1.Id, CarRecord__c=testCar.Id,LeadId__c=ld.Id );
      insert tp;
      Lead checkLead = [Select Id, DoNotCall, HasOptedOutOfEmail from Lead where Id=:ld.Id LIMIT 1];
      checkLead.DoNotCall = true;
      checkLead.HasOptedOutOfEmail = true;
      TriggerMethods.clearvariables();
      update checkLead;  
      Cadence_Assignment_Record__c checkCar = [Select Id, Override_Email__c, Override_Call__c from Cadence_Assignment_Record__c WHERE Id=:testCar.Id LIMIT 1];
      System.debug('checkCar ::'+checkCar );  
      Assert.areEqual(true, checkCar.Override_Email__c);
      Assert.areEqual(true, checkCar.Override_Call__c);
   } // testBothCloseTp
    
    static testMethod void testOverrideCar1() {
       //Use cadence which has override car as true
      Cadence__c testCadence = getTestCadence5();
      User usr = [Select Id, name, profile.Name, email, IsActive from User where Job_Name__c=:UserHelper.JOB_REP and IsActive = true limit 1];
      Account acct1 = CreateTestData.getTestAcct1();
      Contact ct1 = acct1.Contacts[0];
      acct1.OwnerId = usr.Id;
      acct1.SignificantContact__c = ct1.Id;
      update acct1;
      Cadence_Assignment_Record__c testCar1 = new Cadence_Assignment_Record__c(Name='testCar1',CadenceObject__c = ct1.Id,Cadence__c = testCadence.Id
                                                                                 , Cadence_Owner__c=usr.Id, OverrideOtherCARs__c = true);
      insert testCar1;
      Cadence_Touchpoint__c[] touchpoints = getTouchpoints(testCadence.Id);
      System.assertEquals(1,touchpoints.size());
      System.assertEquals(testCar1.Id,touchpoints[0].CarRecord__c);

      // the first car should close and this one should be open because of the override. 
      Cadence_Assignment_Record__c testCar2 = new Cadence_Assignment_Record__c(Name='testCar2',CadenceObject__c = ct1.Id,Cadence__c = testCadence.Id, Cadence_Owner__c=usr.Id,OverrideOtherCARs__c=true );
      TriggerMethods.clearVariables();
      insert testCar2;
       
      touchpoints = getTouchpoints(testCadence.Id);
      System.assertEquals(2,touchpoints.size());
      Boolean car1Found = false;
      Boolean car2Found = false;
      for (Cadence_Touchpoint__c tp : touchpoints) {
         if (tp.CarRecord__c == testCar1.Id) {
            Assert.areEqual('Closed',tp.Status__c);
            car1Found = true;
         } else if (tp.CarRecord__c == testCar2.Id) {
            Assert.areEqual('Open',tp.Status__c);
            car2Found = true;
         }
      }
      Assert.isTrue(car1Found);
      Assert.isTrue(car2Found);
   } // testOverrideCar1 

} // class CadenceUpdateTest