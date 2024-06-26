/* 
 * Test methods for the HRGActivitiesMobilePageController
 *
 * History
 * -------
 * 04/14/2015 Cindy Freeman     Created
 * 01/01/2016 Justin Stouffer   Comprehensive Update
 * 05/11/2016 Lynn Michels      added "if" to take care of new code added in ReferenceHRGController that may result in no Accounts being returned.
 * 05/19/2016 Justin Stouffer   Revised to be a standalone visualforce page and added mass create to client base and openSFActivity functionality.           
   07/30/2019 Dan Carmen        Fix test method so order of picklist values doesn't matter.
   10/12/2020 Jake Hinds        Onsite meeting attendees added
   
 */
@isTest
private class HRGActivitiesMobilePageControllerTest {

    static testMethod void addNewActivitiesTest() {
        //create test data
        CreateTestData.createSingleAandTwoCts ();
        Account acct = [Select Id, Name from Account where Name = 'Test Account1'];
        Account acct2 = new Account (name = 'Test Account2'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '99-7654321'
                                ,ParentId = acct.Id);              
        insert acct2;
        
        String planCode = null;
          for (String tempPlanCode : ReferenceHRGController.PREMIER_PLAN_CODE_SET) {
             planCode = tempPlanCode;
             break;
          }
        Asset asst = new Asset(AccountId=acct.Id, Name='Test Asset', Start_Date__c=Date.today().addDays(-30), Product_Plan_Code__c=planCode);
        insert asst;
        Asset asst2 = new Asset(AccountId=acct2.Id, Name='Test Asset', Start_Date__c=Date.today().addDays(-30), Product_Plan_Code__c=planCode);
        insert asst2;
        
        //User u = [Select Id, Name from User where IsActive=true and Profile.Name = :ZipCheckOwner.AT_HRG limit 1];
        User u = [Select Id, Name from User where IsActive=true and Profile.Name = '2008-09 HRS Premier Support Rep' limit 1];
        
        System.runAs(u) {
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(acct);
            HRGActivitiesMobilePageController hrgMobile = new HRGActivitiesMobilePageController(sc);
            
            List<HRGActivitiesMobilePageController.AccountWrapper> acctList = HRGActivitiesMobilePageController.AdditionalAccounts(acct.Id,'LOG_CONTROLLED');
            
            List<HRGActivitiesMobilePageController.HRGWrapper> hrgWrapList = HRGActivitiesMobilePageController.createHrgActivities(acct.Id, 2);
            System.assertEquals(2, hrgWrapList.size());

            List<String> hrgTypes = HRGActivitiesMobilePageController.gethrgTypes();
            System.assertNotEquals(0, hrgTypes.size());
            String eventType = null;
            String taskType = null;
            for (String hrgType : hrgTypes) {
               if (eventType == null && ReferenceHRGActivityWrapper.EVENT_TYPES.contains(hrgType)) {
                  eventType = hrgType;
               } else if (taskType == null && !ReferenceHRGActivityWrapper.EVENT_TYPES.contains(hrgType)) {
                  taskType = hrgType;
               }
               if (eventType != null && taskType != null) {
                  break;
               }
            } // for (String hrgType : hrgTypes
            System.assertNotEquals(null,eventType);
            System.assertNotEquals(null,taskType);
            hrgTypes = new String[]{eventType,taskType};

            List<String> hrgActivityTypes = HRGActivitiesMobilePageController.gethrgActivityTypes();
            System.assertNotEquals(0, hrgActivityTypes.size());
            Map<String,List<String>> hrgActivities = HRGActivitiesMobilePageController.gethrgActivities();
            System.assertNotEquals(0, hrgActivities.size());
            
            for (Integer i=0; i <2; i++) {
                hrgWrapList.get(i).activity.Activity_Date__c = System.today();
                hrgWrapList.get(i).activity.Type__c = hrgTypes.get(i);
                hrgWrapList.get(i).activity.Activity_Type__c = hrgActivityTypes.get(i);
                List<String> hrgAct = hrgActivities.get(hrgWrapList.get(i).activity.Activity_Type__c);
                hrgWrapList.get(i).activity.Activity__c = hrgAct.get(i);
                hrgWrapList.get(i).activity.Notes__c = 'Notes ' +i;
                hrgWrapList.get(i).activity.Onsite_Meeting_Attendees__c = 'Me+You';
                
            }
            
            Reference_HRG__c refHRG = HRGActivitiesMobilePageController.getRefHRG(acct.id);
            system.assertEquals(refHRG.DateofLastVisit__c, system.today());
            
            List<HRGActivitiesMobilePageController.ActWrapper> actWrapList = HRGActivitiesMobilePageController.processHRGActivities(hrgWrapList, acct.Id);
            System.assertEquals(2, actWrapList.size()); 
            
            for (Integer i=0; i <2; i++) {              
                actWrapList.get(i).javaDate = Date.today().year() + '-' + Date.today().month() + '-' + Date.today().day();
                actWrapList.get(i).javaDateCompl = Date.today().year() + '-' + Date.today().month() + '-' + Date.today().day();
                if (actWrapList.get(i).isEvent)
                {   actWrapList.get(i).evnt.Client_Summary__c = 'Event is completed.';  
                    actWrapList.get(i).selectedTime = '11:30';
                    actWrapList.get(i).evnt.Description = 'Wow, what a party!';
                }
                else
                {   actWrapList.get(i).tsk.Client_Summary__c = 'Task is completed.';    }               
            }
            //LM added if to take care of new code added in ReferenceHRGController that may result in no Accounts being returned.
            if(acctList.size() > 0)
            {
                acctList[0].selected = TRUE;
            
                Boolean ans = HRGActivitiesMobilePageController.processStndActivities(actWrapList, acct.Id, acctList, FALSE,'');
                System.assertEquals(true, ans);
                ans = HRGActivitiesMobilePageController.processStndActivities(actWrapList, acct.Id, acctList, TRUE, 'LOG_CONTROLLED');
                System.assertEquals(true, ans);
            }
            
            
 
        } // runAs
        
    } // addNewActivitiesTest

    static testMethod void ongoingActivitiesTest() {
        //create test data
        CreateTestData.createSingleAandTwoCts ();
        Account acct = [Select Id, Name from Account where Name = 'Test Account1'];
        Account acct2 = new Account (name = 'Test Account2'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '99-7654321'
                                ,ParentId = acct.Id);
        insert acct2;
        
        //User u = [Select Id, Name from User where IsActive=true and Profile.Name = :ZipCheckOwner.AT_HRG limit 1];
        User u = [Select Id, Name from User where IsActive=true and Profile.Name = '2008-09 HRS Premier Support Rep' limit 1];
        
        System.runAs(u) {
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(acct);
            HRGActivitiesMobilePageController hrgMobile = new HRGActivitiesMobilePageController(sc);
            
            List<HRGActivitiesMobilePageController.AccountWrapper> acctList = HRGActivitiesMobilePageController.AdditionalAccounts(acct.Id,'LOG_CONTROLLED');
            
            List<HRGActivitiesMobilePageController.HRGWrapper> hrgWrapList = HRGActivitiesMobilePageController.createHrgActivities(acct.Id, 2);
            System.assertEquals(2, hrgWrapList.size());

            List<String> hrgTypes = HRGActivitiesMobilePageController.gethrgTypes();
            System.assertNotEquals(0, hrgTypes.size());
            List<String> hrgActivityTypes = HRGActivitiesMobilePageController.gethrgActivityTypes();
            System.assertNotEquals(0, hrgActivityTypes.size());
            Map<String,List<String>> hrgActivities = HRGActivitiesMobilePageController.gethrgActivities();
            System.assertNotEquals(0, hrgActivities.size());
            
            for (Integer i=0; i <2; i++) {
                hrgWrapList.get(i).activity.Activity_Date__c = System.today().addDays(i);
                hrgWrapList.get(i).activity.Type__c = hrgTypes.get(i);
                hrgWrapList.get(i).activity.Activity_Type__c = hrgActivityTypes.get(i);
                List<String> hrgAct = hrgActivities.get(hrgWrapList.get(i).activity.Activity_Type__c);
                hrgWrapList.get(i).activity.Activity__c = hrgAct.get(i);
                hrgWrapList.get(i).activity.Notes__c = 'Notes ' +i;
            }
            
            Reference_HRG__c refHRG = HRGActivitiesMobilePageController.getRefHRG(acct.id);
            system.assertEquals(refHRG.DateofLastVisit__c, system.today());
            
            List<HRGActivitiesMobilePageController.ActWrapper> actWrapList = HRGActivitiesMobilePageController.processHRGActivities(hrgWrapList, acct.Id);
            System.assertEquals(2, actWrapList.size()); 

            Boolean ans = HRGActivitiesMobilePageController.processStndActivities(actWrapList, acct.Id, acctList, FALSE, '');
            System.assertEquals(true, ans);

            HRGActivitiesMobilePageController hrgMobile2 = new HRGActivitiesMobilePageController(sc);  
            
            List<HRGActivitiesMobilePageController.HRGWrapper> ongActList = HRGActivitiesMobilePageController.getOngoingActivities(acct.id, 'Ongoing');
            system.assert(ongActList.size() == 2);
            
            actWrapList = HRGActivitiesMobilePageController.processHRGActivities(ongActList, acct.Id);
            System.assertEquals(2, actWrapList.size()); 
            
            for (Integer i=0; i <2; i++) {              
                actWrapList.get(i).javaDate = Date.today().year() + '-' + Date.today().month() + '-' + Date.today().day();
                actWrapList.get(i).javaDateCompl = Date.today().year() + '-' + Date.today().month() + '-' + Date.today().day();
                if (actWrapList.get(i).isEvent)
                {   actWrapList.get(i).evnt.Client_Summary__c = 'Event is completed.';  
                    actWrapList.get(i).selectedTime = '11:30';
                    actWrapList.get(i).evnt.Description = 'Wow, what a party!';
                }
                else
                {   actWrapList.get(i).tsk.Client_Summary__c = 'Task is completed.';    }               
            }
            
            ans = HRGActivitiesMobilePageController.processStndActivities(actWrapList, acct.Id, acctList, FALSE, '');
            System.assertEquals(true, ans);            
   
        } // runAs
        
                
        
    } // ongoingActivitiesTest
    

    static testMethod void onboardingTest() {
        //create test data
        CreateTestData.createSingleAandTwoCts ();
        Account acct = [Select Id, Name from Account where Name = 'Test Account1'];
        
        //User u = [Select Id, Name from User where IsActive=true and Profile.Name = :ZipCheckOwner.AT_HRG limit 1];
        User u = [Select Id, Name from User where IsActive=true and Profile.Name = '2008-09 HRS Premier Support Rep' limit 1]; 
        
        List<HRGActivitiesMobilePageController.AccountWrapper> acctList = HRGActivitiesMobilePageController.AdditionalAccounts(acct.Id,'LOG_CONTROLLED');
        
        List<ReferenceHrgActivityWrapper> onbActs = HRGActivitiesMobilePageController.getOnboardingActivities(acct.id, 'Onboarding');
        List<ReferenceHrgActivityWrapper> onbSetupActs = HRGActivitiesMobilePageController.getOnboardingActivities(acct.id, 'Onboarding Setup');
        List<ReferenceHrgActivityWrapper> onbConcernActs = HRGActivitiesMobilePageController.getOnboardingActivities(acct.id, 'Onboarding Concerns');
        
        system.assert(!onbActs.isEmpty());
        system.assert(!onbSetupActs.isEmpty());
        system.assert(!onbConcernActs.isEmpty());
        
        List<HRGActivitiesMobilePageController.HRGWrapper> HRGWrapList = New List<HRGActivitiesMobilePageController.HRGWrapper>();
        HRGActivitiesMobilePageController.HRGWrapper onbHRGWrap = new HRGActivitiesMobilePageController.HRGWrapper();
        HRGActivitiesMobilePageController.HRGWrapper onbSetupHRGWrap = new HRGActivitiesMobilePageController.HRGWrapper();
        HRGActivitiesMobilePageController.HRGWrapper onbConcernHRGWrap = new HRGActivitiesMobilePageController.HRGWrapper();
        
        onbActs[0].activity.Type__c = 'OnSite';
        onbSetupActs[0].activity.Type__c = 'OnSite'; 
        onbConcernActs[0].activity.Type__c = 'OnSite';
        
        onbHRGWrap.activity = onbActs[0].activity;
        onbSetupHRGWrap.activity = onbSetupActs[0].activity;
        onbConcernHRGWrap.activity = onbConcernActs[0].activity;
        
        HRGWrapList.add(onbHRGWrap);
        HRGWrapList.add(onbSetupHRGWrap);
        HRGWrapList.add(onbConcernHRGWrap);
        
        List<HRGActivitiesMobilePageController.ActWrapper> actWrapList = HRGActivitiesMobilePageController.processHRGActivities(HRGWrapList, acct.id);          
        
        Boolean ans = HRGActivitiesMobilePageController.processStndActivities(actWrapList, acct.id, acctList, FALSE,'');
        System.assertEquals(true, ans);
    } //onboardingTest
    
    static testMethod void openSFActivitiesTest() {
        //create test data
        CreateTestData.createSingleAandTwoCts ();
        Schema.Recordtypeinfo taskRT = RecordTypeHelper.getRecordType(referenceHRGController.RT_TASK, 'Task');
        Schema.Recordtypeinfo eventRT = RecordTypeHelper.getRecordType(referenceHRGController.RT_EVENT, 'Event');
        Account acct = [Select Id, Name from Account where Name = 'Test Account1'];
        Task t1 = new Task(recordTypeID = taskRT.getRecordTypeId(), whatId = acct.id, Client_Summary__c = 'Test T1', Subject='30-Day Follow up', ActivityDate=Date.today().addDays(30));
        insert t1;
        Event e1 = new event(recordTypeID = eventRT.getRecordTypeId(), whatId = acct.id, Client_Summary__c = 'Test T1', Subject='30-Day Follow up', ActivityDateTime=DateTime.now().addDays(30),DurationInMinutes=60 );
        insert e1;
        List<HRGActivitiesMobilePageController.ActWrapper> openSFActivities = HRGActivitiesMobilePageController.getOpenSFActivities(acct.id);
        system.assertEquals(openSFActivities.size(),2);
        HRGActivitiesMobilePageController.deleteActivity(acct.Id, openSFActivities[0].key);
        openSFActivities = HRGActivitiesMobilePageController.getOpenSFActivities(acct.id);
        system.assertEquals(openSFActivities.size(),1);
    } //productTest
    
    static testMethod void productTest() {
        //create test data
        CreateTestData.createSingleAandTwoCts ();
        Account acct = [Select Id, Name from Account where Name = 'Test Account1'];
        List<map<string,string>> productList = HRGActivitiesMobilePageController.getProductFields(acct.id);
        system.assert(!productList.isEmpty());
    } //productTest
    
    static testMethod void healthTest() {
        //create test data
        CreateTestData.createSingleAandTwoCts ();
        Account acct = [Select Id, Name from Account where Name = 'Test Account1'];
        string currHealth =  HRGActivitiesMobilePageController.getAcctHealth(acct.Id);
        system.assert(currHealth != 'At Risk');
        HRGActivitiesMobilePageController.processAcctHealth('At Risk', 'Setting to At Risk', acct.Id);
        currHealth =  HRGActivitiesMobilePageController.getAcctHealth(acct.Id);
        system.assert(currHealth == 'At Risk');
    } //healthTest
    
    static testMethod void refHRGTest() {
        //create test data
        CreateTestData.createSingleAandTwoCts ();
        Account acct = [Select Id, Name from Account where Name = 'Test Account1'];
        Reference_HRG__c refHRG = HRGActivitiesMobilePageController.getRefHRG(acct.id);
        system.assertNotEquals(refHRG.Sales_Rep_Attended_CC_Meeting__c, 'Yes');
        refHRG.Sales_Rep_Attended_CC_Meeting__c = 'Yes';
        HRGActivitiesMobilePageController.saveRefHRG(acct.id, refHRG);
        Reference_HRG__c refHRGAfter = HRGActivitiesMobilePageController.getRefHRG(acct.id);
        system.assertEquals(refHRGAfter.Sales_Rep_Attended_CC_Meeting__c, 'Yes');
    } //productTest

} // class HRGActivitiesMobilePageControllerTest