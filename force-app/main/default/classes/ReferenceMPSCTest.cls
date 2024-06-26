/**
 * 12/02/2016 Lynn Michels  Created
 * 01/30/2017 Lynn Michels  Updated to use Custom Settings
 * 04/05/2017 Lynn Michels  Added criteria for updating multiple MPSC records
 * 09/27/2017 Lynn Michels  Added code because of test failure
 * 05/24/2018 Lynn Michels  changed code for test failure for C2C field
 * 10/07/2018 Frank Lurz    Added code for updating Current Step and sending Chatter Posts
 * 01/23/2019 Dan Carmen    Added TRIGGERS_RAN variable
 * 12/17/2020 Brandon Vidro Removed debug statements
 * 01/04/2021 Brandon Vidro Modified to work w/ Flow and 2 Formula fields on object
   12/11/2023 Dan Carmen            Add to TriggerInterfaceC

 */
@isTest
private class ReferenceMPSCTest {
    @testSetup
    public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'ReferenceMPSC'});
      TriggerMethodsTest.saveSetupClasses();
        
      User[] usrs = [Select Id, FirstName, LastName, Name, HR_Person_Id__c 
                       from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and HR_Person_Id__c != null limit 3];       
      User usr1 = usrs[0];
      User usr2 = usrs[1];
        
      Account acct1 = new Account (name = 'Paychex Inc SA'
                                    ,OwnerId = usr1.id); 
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct1;
   
      Id payEmpRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Paychex Employee').getRecordTypeId();
      Contact con1 = new Contact(Firstname = usr1.FirstName
                                ,Lastname = usr1.LastName
                                ,AccountId = acct1.Id
                                ,RecordTypeId=payEmpRtId
                                ,HR_Person_Id__c = usr1.HR_Person_Id__c
                                ,User_lookup__c = usr1.id);
      Contact con2 = new Contact(Firstname = usr2.FirstName
                                ,Lastname = usr2.LastName
                                ,AccountId = acct1.Id
                                ,RecordTypeId=payEmpRtId
                                ,HR_Person_Id__c = usr2.HR_Person_Id__c
                                ,User_lookup__c = usr2.id);
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert new Contact[]{con1,con2};
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
      ZipCheckOwner.SKIP_TRIGGERS=false;
    } // setupData
    
    public static Contact[] getPayxCtcts() {
       Contact[] ctcts = [Select Id, Name, User_Lookup__c, HR_Person_Id__c
                                ,User_Lookup__r.Id, User_Lookup__r.Name
                            From Contact
                           Where Account.Name = 'Paychex Inc SA' limit 2];
       return ctcts;
    } // getPayxCtcts

    static testMethod void testAccountChanges() {
        Contact[] ctcts = getPayxCtcts();
        Contact con1 = ctcts[0];
        Contact con2 = ctcts[1];
        Id[] userIds = new Id[]{con1.User_Lookup__c, con2.User_Lookup__c};
        
        User[] usrs = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and HR_Person_Id__c != null and Id not in :userIds limit 3];       
        User u1 = con1.User_Lookup__r;
        User u2 = con2.User_Lookup__r;
        User u3 = usrs[0];
        User u4 = usrs[1];
        User u5 = usrs[2];
        
        Account acct2 = new Account (name = 'Test Account'
                                ,OwnerId = u1.id                            //Sales Rep
                                ,HRO_Implementation_Coordinator__c = u1.id  //Flex HR IS
                                ,TLO_Implementation_Coordinator__c = u2.id  //TAA IS
                                ,Paychex_Payroll_Specialist__c = con1.id    //Payroll BSR
                                ,MMS_MAM_NAM__c = con2.id);//contact        //SIPM/IPM
        insert acct2;

        //MPSC Onboarding Case is the parent case of the MPSC Transfer case
        //The owner of this case is the Payroll IS on the Reference MPSC record
        Id mpscOnboardingCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Onboarding MPSC Core Payroll Case').getRecordTypeId();
        Case mpscOnboardingCase = new Case (recordtypeId = mpscOnboardingCaseRT
                                ,AccountId = acct2.id
                                ,OwnerId = u5.id);                  
        insert mpscOnboardingCase;
        
        //MPSC Transfer Case
        Id mpscTransferCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('MPSC Transfer Case').getRecordTypeId();
        Case mpscTransferCase = new Case (recordtypeId = mpscTransferCaseRT
                                ,AccountId = acct2.id
                                ,ParentId = mpscOnboardingCase.id);                 
        insert mpscTransferCase;
        
        Id mpscTransfer = Schema.SObjectType.Reference_MPSC__c.getRecordTypeInfosByName().get('Reference MPSC Transfer').getRecordTypeId();
        Reference_MPSC__c mpsc = new Reference_MPSC__c(recordtypeId = mpscTransfer
                                                        ,Case_Lookup__c = mpscTransferCase.id
                                                        ,Prospect_Client__c = acct2.id);
        insert mpsc;
        //there is a process builder flow that populates the TAA IS, Flex IS and the three BSR fields after creation 
        
        List<Reference_MPSC__c> mpscList = new List<Reference_MPSC__c>();
        mpscList = [SELECT Id, Case_Lookup__c, TAA_IS__c, Flex_HR_IS__c, Payroll_BSR__c, Sales_Rep__c,
                    TAA_BSR__c, Flex_HR_BSR__c, SIPM_IPM__c FROM Reference_MPSC__c WHERE Case_Lookup__c =: mpscTransferCase.id];

        system.assertEquals(acct2.TLO_Implementation_Coordinator__c, mpscList[0].TAA_IS__c);
        system.assertEquals(acct2.HRO_Implementation_Coordinator__c, mpscList[0].Flex_HR_IS__c);
        //system.assertEquals(u1.id, mpscList[0].Payroll_BSR__c);
        system.assertEquals(u2.id, mpscList[0].SIPM_IPM__c); 
        system.assertEquals(acct2.OwnerId, mpscList[0].Sales_Rep__c);
    
        acct2.OwnerId = u5.id;                           //Sales Rep
        acct2.HRO_Implementation_Coordinator__c = u4.id;  //Flex HR IS
        acct2.TLO_Implementation_Coordinator__c = u3.id;  //TAA IS
        acct2.Paychex_Payroll_Specialist__c = con2.id;    //contact -- Payroll BSR
        acct2.MMS_MAM_NAM__c = con1.id;                  //contact -- SIPM/IPM
        
        Test.startTest();
        ZipCheckOwner.SKIP_TRIGGERS=false;
        TriggerMethods.clearVariables();
        update acct2;
        Test.stopTest();
                        
        List<Reference_MPSC__c> mpscUpdatesList = new List<Reference_MPSC__c>();
        mpscUpdatesList = [SELECT Id, Case_Lookup__c, TAA_IS__c, Flex_HR_IS__c, Payroll_BSR__c, Sales_Rep__c,
                    TAA_BSR__c, Flex_HR_BSR__c, SIPM_IPM__c FROM Reference_MPSC__c WHERE Case_Lookup__c =: mpscTransferCase.id];
        
        system.assertEquals(acct2.TLO_Implementation_Coordinator__c, mpscUpdatesList[0].TAA_IS__c);
        system.assertEquals(acct2.HRO_Implementation_Coordinator__c, mpscUpdatesList[0].Flex_HR_IS__c);
        //system.assertEquals(u2.id, mpscUpdatesList[0].Payroll_BSR__c);
        system.assertEquals(u1.id, mpscUpdatesList[0].SIPM_IPM__c); 
        system.assertEquals(acct2.OwnerId, mpscUpdatesList[0].Sales_Rep__c);    
    }//end testAccountChanges

    //test Reference MPSC updates when there are multiple
    static testMethod void testAccountChangesWithMultipleRefMPSC() {
        Contact[] ctcts = getPayxCtcts();
        Contact con1 = ctcts[0];
        Contact con2 = ctcts[1];
        Id[] userIds = new Id[]{con1.User_Lookup__c, con2.User_Lookup__c};
        
        User[] usrs = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and HR_Person_Id__c != null and Id not in :userIds limit 3];       
        User u1 = con1.User_Lookup__r;
        User u2 = con2.User_Lookup__r;
        User u3 = usrs[0];
        User u4 = usrs[1];
        User u5 = usrs[2];
         
         Account acct2 = new Account (name = 'Test Account'
                                ,OwnerId = u1.id                            //Sales Rep
                                ,HRO_Implementation_Coordinator__c = u1.id  //Flex HR IS
                                ,TLO_Implementation_Coordinator__c = u2.id  //TAA IS
                                ,Paychex_Payroll_Specialist__c = con1.id    //Payroll BSR
                                ,MMS_MAM_NAM__c = con2.id);//contact        //SIPM/IPM
        insert acct2;
       
        
        //MPSC Onboarding Case is the parent case of the MPSC Transfer case
        //The owner of this case is the Payroll IS on the Reference MPSC record
        Id mpscOnboardingCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Onboarding MPSC Core Payroll Case').getRecordTypeId();
        Case mpscOnboardingCase = new Case (recordtypeId = mpscOnboardingCaseRT
                                ,AccountId = acct2.id
                                ,OwnerId = u5.id);                  
        insert mpscOnboardingCase;
        
        //MPSC Transfer Case
        Id mpscTransferCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('MPSC Transfer Case').getRecordTypeId();
        Case mpscTransferCase = new Case (recordtypeId = mpscTransferCaseRT
                                ,AccountId = acct2.id
                                ,ParentId = mpscOnboardingCase.id);                 
        insert mpscTransferCase;
        
        Id mpscTransfer = Schema.SObjectType.Reference_MPSC__c.getRecordTypeInfosByName().get('Reference MPSC Transfer').getRecordTypeId();
        Reference_MPSC__c mpsc = new Reference_MPSC__c(recordtypeId = mpscTransfer
                                                        ,Case_Lookup__c = mpscTransferCase.id
                                                        ,Prospect_Client__c = acct2.id);
        insert mpsc;
        //there is a process builder flow that populates the TAA IS, Flex IS and the three BSR fields after creation 
        
        List<Reference_MPSC__c> mpscList = new List<Reference_MPSC__c>();
        mpscList = [SELECT Id, Case_Lookup__c, TAA_IS__c, Flex_HR_IS__c, Payroll_BSR__c, Sales_Rep__c,
                    TAA_BSR__c, Flex_HR_BSR__c, SIPM_IPM__c FROM Reference_MPSC__c WHERE Case_Lookup__c =: mpscTransferCase.id];

        system.assertEquals(acct2.TLO_Implementation_Coordinator__c, mpscList[0].TAA_IS__c);
        system.assertEquals(acct2.HRO_Implementation_Coordinator__c, mpscList[0].Flex_HR_IS__c);
        //system.assertEquals(u1.id, mpscList[0].Payroll_BSR__c);
        system.assertEquals(u2.id, mpscList[0].SIPM_IPM__c); 
        system.assertEquals(acct2.OwnerId, mpscList[0].Sales_Rep__c);
        
        //create more MPSC Transfer Cases
        List<Case> mpscTransferCases = new List<Case>();
        
        Case mpscTransferCase2 = new Case (recordtypeId = mpscTransferCaseRT
                                            ,AccountId = acct2.id
                                            ,Status = 'Completed');                 
        mpscTransferCases.add(mpscTransferCase2);
        Case mpscTransferCase3 = new Case (recordtypeId = mpscTransferCaseRT
                                            ,AccountId = acct2.id);                 
        mpscTransferCases.add(mpscTransferCase3);
        insert mpscTransferCases;
        
        List<Reference_MPSC__c> RefMPSCs = new List<Reference_MPSC__c>();
        
        Reference_MPSC__c mpsc2 = new Reference_MPSC__c(recordtypeId = mpscTransfer
                                                        ,Case_Lookup__c = mpscTransferCase2.id
                                                        ,Prospect_Client__c = acct2.id);
        RefMPSCs.add(mpsc2);        
        
        Reference_MPSC__c mpsc3 = new Reference_MPSC__c(recordtypeId = mpscTransfer
                                                        ,Case_Lookup__c = mpscTransferCase3.id
                                                        ,Prospect_Client__c = acct2.id);
        RefMPSCs.add(mpsc3);
        insert RefMPSCs;
        
        //making updates to the Account
        acct2.OwnerId = u5.id;                           //Sales Rep
        acct2.HRO_Implementation_Coordinator__c = u4.id;  //Flex HR IS
        acct2.TLO_Implementation_Coordinator__c = u3.id;  //TAA IS
        acct2.Paychex_Payroll_Specialist__c = con2.id;    //contact -- Payroll BSR
        acct2.MMS_MAM_NAM__c = con1.id;                  //contact -- SIPM/IPM
        
        Test.startTest();
        ZipCheckOwner.SKIP_TRIGGERS=false;
        TriggerMethods.clearVariables();
        update acct2;
        Test.stopTest();
                        
        List<Reference_MPSC__c> mpscUpdatesList = new List<Reference_MPSC__c>();
        mpscUpdatesList = [SELECT Id, Prospect_Client__c, TAA_IS__c, Flex_HR_IS__c, Payroll_BSR__c, Sales_Rep__c,
                    TAA_BSR__c, Flex_HR_BSR__c, SIPM_IPM__c FROM Reference_MPSC__c WHERE Prospect_Client__c =: acct2.id];
        
        system.assertEquals(acct2.TLO_Implementation_Coordinator__c, mpscUpdatesList[0].TAA_IS__c);
        system.assertEquals(acct2.HRO_Implementation_Coordinator__c, mpscUpdatesList[0].Flex_HR_IS__c);
        //system.assertEquals(u2.id, mpscUpdatesList[0].Payroll_BSR__c);
        system.assertEquals(u1.id, mpscUpdatesList[0].SIPM_IPM__c); 
        system.assertEquals(acct2.OwnerId, mpscUpdatesList[0].Sales_Rep__c);
        
        //This won't update because the status is Completed
        system.assertNotEquals(acct2.TLO_Implementation_Coordinator__c, mpscUpdatesList[1].TAA_IS__c);
        system.assertNotEquals(acct2.HRO_Implementation_Coordinator__c, mpscUpdatesList[1].Flex_HR_IS__c);
        //system.assertNotEquals(u2.id, mpscUpdatesList[1].Payroll_BSR__c);
        system.assertNotEquals(u1.id, mpscUpdatesList[1].SIPM_IPM__c); 
        system.assertNotEquals(acct2.OwnerId, mpscUpdatesList[1].Sales_Rep__c);
        
        //system.assertEquals(expected, actual)
        system.assertEquals(acct2.TLO_Implementation_Coordinator__c, mpscUpdatesList[2].TAA_IS__c);
        system.assertEquals(acct2.HRO_Implementation_Coordinator__c, mpscUpdatesList[2].Flex_HR_IS__c);
        //system.assertEquals(u2.id, mpscUpdatesList[2].Payroll_BSR__c);
        system.assertEquals(u1.id, mpscUpdatesList[2].SIPM_IPM__c); 
        system.assertEquals(acct2.OwnerId, mpscUpdatesList[2].Sales_Rep__c);    

     }//end testing with multiple Reference MPSC and some closed

     static testMethod void testPayrollIS() {
        List<Contact> newContacts = new List<Contact>();
        User[] usrs = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and HR_Person_Id__c != null and Sales_Org__c=:UserHelper.SO_CORE limit 5];       
        User u1 = usrs[0];
        User u2 = usrs[1];
         
        Account acct1 = new Account (name = 'Paychex Inc SA'
                                      ,OwnerId = u1.id
                                      ,HRO_Implementation_Coordinator__c = u1.id  //Flex HR IS
                                      ,TLO_Implementation_Coordinator__c = u2.id);  //TAA IS

        insert acct1;
        
        Contact con1 = new Contact(Firstname = 'Contact1'
                                    ,Lastname = 'Black'
                                    ,AccountId = acct1.Id
                                    ,User_lookup__c = u1.id);
        newContacts.add(con1);
         
        Contact con2 = new Contact(Firstname = 'Contact2'
                                    ,Lastname = 'Smith'
                                    ,AccountId = acct1.Id
                                    ,User_lookup__c = u2.id);
        newContacts.add(con2);
        insert newContacts;
                                     
        acct1.Paychex_Payroll_Specialist__c = con1.id;
        acct1.MMS_MAM_NAM__c = con2.id;
        update acct1;
        
        Id mpscOnboardingCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Onboarding MPSC Core Payroll Case').getRecordTypeId();
        Case mpscOnboardingCase = new Case (recordtypeId = mpscOnboardingCaseRT
                                ,AccountId = acct1.id
                                ,OwnerId = u1.id);                  
        insert mpscOnboardingCase;
        
        //MPSC Transfer Case
        Id mpscTransferCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('MPSC Transfer Case').getRecordTypeId();
        Case mpscTransferCase = new Case (recordtypeId = mpscTransferCaseRT
                                ,AccountId = acct1.id
                                ,ParentId = mpscOnboardingCase.id);                 
        insert mpscTransferCase;
        
        Id mpscTransfer = Schema.SObjectType.Reference_MPSC__c.getRecordTypeInfosByName().get('Reference MPSC Transfer').getRecordTypeId();
        Reference_MPSC__c mpsc = new Reference_MPSC__c(recordtypeId = mpscTransfer
                                                        ,Case_Lookup__c = mpscTransferCase.id
                                                        ,Prospect_Client__c = acct1.id
                                                        ,Stand_alone_Flex_HR__c = false
                                                        ,Stand_alone_TAA__c = false
                                                        ,Current_Step__c = '(1 of 3) Client in onboarding');
        insert mpsc;
        
        List<Reference_MPSC__c> mpscList = new List<Reference_MPSC__c>();
        
        mpscOnboardingCase.OwnerId = u2.id;
        update mpscOnboardingCase;
        
        //after case owner changes, verify that the case Owner is the Payroll IS on the reference mpsc record
        mpscList = [SELECT Id, Payroll_IS__c, Current_Step__c FROM Reference_MPSC__c WHERE id =: mpsc.id LIMIT 1];
        system.assertEquals(mpscOnboardingCase.OwnerId, mpscList[0].Payroll_IS__c);
        
        //verify that current step for case and reference mpsc match
        List<Case> mpscTransferCases = new List<Case>();
        mpscTransferCases = [SELECT Current_Step__c, Id FROM Case WHERE id =: mpscTransferCase.id LIMIT 1];
        system.assertEquals(mpscList[0].Current_Step__c, mpscTransferCases[0].Current_Step__c);
    
        //populate Payroll fields - will change current step and populate transfer date
        //loop through the field set and set the fields
        List<Schema.FieldSetMember> payrollFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_Payroll_fields.getfields();
        for (Schema.FieldSetMember pf: payrollFields) {
            if(pf.getFieldPath() == 'Est_Payroll_Taking_Time_min__c'){
                mpsc.put(pf.getFieldPath(),30);
            }
            else if(pf.getFieldPath() == 'Client_Reporting_Method__c'){
                mpsc.put(pf.getFieldPath(),'Not Online – Email');
            }
            else if(pf.getFieldPath() == 'Client_Time_Zone__c'){
                mpsc.put(pf.getFieldPath(),'EST');
            }
            else if(pf.getFieldPath() == 'C2C__c'){
                mpsc.put(pf.getFieldPath(),'Parent');
            }     
            else{
            mpsc.put(pf.getFieldPath(),'yes'); 
            } 
        }
        
        //populate TAA IS and TAA fields
        acct1.TLO_Implementation_Coordinator__c = u2.id;  //TAA IS
        
        //loop through the field set and set the fields
        List<Schema.FieldSetMember> taaFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_TAA_Fields.getfields();
        for (Schema.FieldSetMember tf: taaFields){
            if (tf.getFieldPath() == 'Clocks__c'){
                mpsc.put(tf.getFieldPath(),'Proximity'); 
            }
            else if (tf.getFieldPath() == 'Additional_Features__c'){
                mpsc.put(tf.getFieldPath(),'Timesheets'); 
            }
            else{
            mpsc.put(tf.getFieldPath(),'yes'); 
            } 
        }
            

        //populate Flex HR IS and Flex HR fields
        acct1.HRO_Implementation_Coordinator__c = u1.id;
        //loop through the field set and set the fields
        List<Schema.FieldSetMember> flexFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_Flex_fields.getfields();
        for (Schema.FieldSetMember ff: flexFields){
        if (ff.getFieldPath() == 'Flex_HR_Trainings_Completed__c'){
                mpsc.put(ff.getFieldPath(),'HR Admin tab'); 
            }
        else
            mpsc.put(ff.getFieldPath(),'yes');  
        }
            
            
        Test.startTest();
        update acct1;
        ReferenceMPSC.TRIGGERS_RAN = false;
        update mpsc;
        Test.stopTest();
                        
            
        mpscList = [SELECT Id, Payroll_IS__c, Current_Step__c, Flex_HR_ready_Transfer_Date__c, TAA_ready_to_Transfer_Date__c, 
                    Payroll_ready_to_Transfer_Date__c  FROM Reference_MPSC__c WHERE id =: mpsc.id];
        mpscTransferCases = [SELECT Current_Step__c, Id FROM Case WHERE id =: mpscTransferCase.id];
        system.assertEquals(mpscList[0].Current_Step__c, mpscTransferCases[0].Current_Step__c);
        system.assertNotEquals(mpscList[0].Payroll_ready_to_Transfer_Date__c, null);
        system.assertNotEquals(mpscList[0].TAA_ready_to_Transfer_Date__c, null);
        system.assertNotEquals(mpscList[0].Flex_HR_ready_Transfer_Date__c, null);
        
        //clear some of the fields and assert that the date fields clear
        mpsc.C2C__c = null;
        mpsc.Integrated__c = null;
        mpsc.Are_Job_Titles_Positions_used__c = null;
        ReferenceMPSC.TRIGGERS_RAN = false;
        update mpsc;
        mpscList = [SELECT Id, Payroll_IS__c, Current_Step__c, Flex_HR_ready_Transfer_Date__c, TAA_ready_to_Transfer_Date__c, 
                    Payroll_ready_to_Transfer_Date__c  FROM Reference_MPSC__c WHERE id =: mpsc.id];
        system.assertEquals(mpscList[0].Payroll_ready_to_Transfer_Date__c, null);
        system.assertEquals(mpscList[0].TAA_ready_to_Transfer_Date__c, null);
        system.assertEquals(mpscList[0].Flex_HR_ready_Transfer_Date__c, null);
     }//end testPayrollIS 

     static testMethod void testCurrentStepPayroll() {
        Contact[] ctcts = getPayxCtcts();
        Contact con1 = ctcts[0];
        Contact con2 = ctcts[1];
        Id[] userIds = new Id[]{con1.User_Lookup__c, con2.User_Lookup__c};
        
        User[] usrs = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and HR_Person_Id__c != null and Id not in :userIds limit 4];       
        User u1 = con1.User_Lookup__r;
        User u2 = con2.User_Lookup__r;
        User u3 = usrs[0];
        User u4 = usrs[1];
        User u5 = usrs[2];
        User u6 = usrs[3];

        List<Reference_MPSC__c> mpscListCurrentStepPayroll = new List<Reference_MPSC__c>();
         
        Account acct2 = new Account (name = 'Test Account'
                                ,OwnerId = u1.id                            //Sales Rep
                                ,HRO_Implementation_Coordinator__c = u1.id  //Flex HR IS
                                ,TLO_Implementation_Coordinator__c = u2.id  //TAA IS
                                //,HRO_Advisor__c = con2.id  //BAU Changes
                                ,Time_Attendance_AS__c = con2.id
                               ,MMS_MAM_NAM__c = con2.id);//contact        //SIPM/IPM
        insert acct2;
        
        //MPSC Transfer Case
        Id mpscTransferCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('MPSC Transfer Case').getRecordTypeId();
        Case mpscTransferCase = new Case (recordtypeId = mpscTransferCaseRT
                                ,AccountId = acct2.id);                 
        insert mpscTransferCase;
        
        Id mpscTransfer = Schema.SObjectType.Reference_MPSC__c.getRecordTypeInfosByName().get('Reference MPSC Transfer').getRecordTypeId();
        Reference_MPSC__c mpsc = new Reference_MPSC__c(recordtypeId = mpscTransfer
                                                        ,Case_Lookup__c = mpscTransferCase.id
                                                        ,Prospect_Client__c = acct2.id
                                                        ,Current_Step__c = null
                                                        ,Stand_alone_FBAE__c = false
                                                        ,Stand_alone_Flex_HR__c = false
                                                        ,Stand_alone_TAA__c = false
                                                        ,Lost_Product_FBAE__c = false
                                                        ,Lost_Product_Flex_HR__c = false
                                                        ,Transfer_Call_Type__c = null
                                                        ,Payroll_IS__c = u1.Id
                                                        ,Payroll_ready_to_Transfer_Date__c = Date.today()
                                                        ,Lost_Product_TAA__c = false);
        insert mpsc;
        
        //populate Payroll fields - will change current step and populate transfer date
        //loop through the field set and set the fields
        List<Schema.FieldSetMember> payrollFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_Payroll_fields.getfields();
        for (Schema.FieldSetMember pf: payrollFields) {
            if(pf.getFieldPath() == 'Est_Payroll_Taking_Time_min__c'){
                mpsc.put(pf.getFieldPath(),30);
            }
            else if(pf.getFieldPath() == 'Client_Reporting_Method__c'){
                mpsc.put(pf.getFieldPath(),'Not Online – Email');
            }
            else if(pf.getFieldPath() == 'Client_Time_Zone__c'){
                mpsc.put(pf.getFieldPath(),'EST');
            }
            else if(pf.getFieldPath() == 'C2C__c'){
                mpsc.put(pf.getFieldPath(),'Parent');
            }     
            else{
            mpsc.put(pf.getFieldPath(),'yes'); 
            } 
        }
         //loop through the field set and set the fields
         List<Schema.FieldSetMember> taaFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_TAA_Fields.getfields();
         for (Schema.FieldSetMember tf: taaFields){
             if (tf.getFieldPath() == 'Clocks__c'){
                 mpsc.put(tf.getFieldPath(),'Proximity'); 
             }
             else if (tf.getFieldPath() == 'Additional_Features__c'){
                 mpsc.put(tf.getFieldPath(),'Timesheets'); 
             }
             else{
                 mpsc.put(tf.getFieldPath(),'yes'); 
             } 
         }
                 
        //attempt to set to Current Step = 1
        mpsc.SIPM_IPM__c = u6.id;
        mpsc.SIPM_IP__c = u6.id;
        mpsc.PM_Approved__c = true;
        mpsc.Transfer_Call_Type__c = null;
        mpsc.TAA_BSR__c = u6.id;
        mpsc.Flex_HR_IS__c = null;
         
        Test.startTest();
        ReferenceMPSC.TRIGGERS_RAN = false;
        update mpsc;
        Test.stopTest();
         
        mpscListCurrentStepPayroll = [SELECT Id, Current_Step__c FROM Reference_MPSC__c WHERE id =: mpsc.id];
        system.assertEquals(mpscListCurrentStepPayroll[0].Current_Step__c, '(1 of 3) Client in onboarding');
         
        //set to Current Step = 2 
        mpsc.Transfer_Call_Type__c = 'Email';
        mpsc.TAA_BSR__c = null;
        mpsc.TAA_IS__c = null;
        acct2.Time_Attendance_AS__c = null;
        ReferenceMPSC.TRIGGERS_RAN = false;
        update acct2;
        ReferenceMPSC.TRIGGERS_RAN = false;
        update mpsc;
        
        mpscListCurrentStepPayroll = [SELECT Id, Current_Step__c FROM Reference_MPSC__c WHERE id =: mpsc.id];
        system.assertEquals(mpscListCurrentStepPayroll[0].Current_Step__c, '(2 of 3) Client ready for transition');
         
        //set to Current Step = 3
        mpsc.Date_Ready_for_Transition__c = Date.today();
        mpsc.Transfer_Specialist__c = u3.id;
        //mpsc.Payroll_BSR__c = u3.id;
        mpsc.TAA_IS__c = u3.id;
        mpsc.TAA_BSR__c = u3.id;
        acct2.Time_Attendance_AS__c = con2.Id;
        acct2.Paychex_Payroll_Specialist__c = con2.Id;
        mpsc.TAA_ready_to_Transfer_Date__c = date.today();
        ReferenceMPSC.TRIGGERS_RAN = false;
        update acct2;
        ReferenceMPSC.TRIGGERS_RAN = false;
        update mpsc;
         
        mpscListCurrentStepPayroll = [SELECT Id, Current_Step__c FROM Reference_MPSC__c WHERE id =: mpsc.id];
        system.assertEquals(mpscListCurrentStepPayroll[0].Current_Step__c, '(3 of 3) Transitioned to support');
        
     }//end testCurrentStepPayroll 


     static testMethod void testCurrentStepStandAlone() {
        Contact[] ctcts = getPayxCtcts();
        Contact con1 = ctcts[0];
        Contact con2 = ctcts[1];
        Id[] userIds = new Id[]{con1.User_Lookup__c, con2.User_Lookup__c};
        
        User[] usrs = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and HR_Person_Id__c != null and Id not in :userIds limit 4];       
        User u1 = con1.User_Lookup__r;
        User u2 = con2.User_Lookup__r;
        User u3 = usrs[0];
        User u4 = usrs[1];
        User u5 = usrs[2];
        User u6 = usrs[3];

        Account acct2 = new Account (name = 'Test Account'
                                ,OwnerId = u1.id                            //Sales Rep
                                ,HRO_Implementation_Coordinator__c = u1.id  //Flex HR IS
                                ,TLO_Implementation_Coordinator__c = u2.id  //TAA IS
                               ,MMS_MAM_NAM__c = con2.id);//contact        //SIPM/IPM
        insert acct2;
         
        List<Reference_MPSC__c> mpscListCurrentStepStandalone = new List<Reference_MPSC__c>();
         
        
        //MPSC Transfer Case
        Id mpscTransferCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('MPSC Transfer Case').getRecordTypeId();
        Case mpscTransferCase = new Case (recordtypeId = mpscTransferCaseRT
                                ,AccountId = acct2.id);                 
        insert mpscTransferCase;
        
        Id mpscTransfer = Schema.SObjectType.Reference_MPSC__c.getRecordTypeInfosByName().get('Reference MPSC Transfer').getRecordTypeId();
        Reference_MPSC__c mpsc = new Reference_MPSC__c(recordtypeId = mpscTransfer
                                                        ,Case_Lookup__c = mpscTransferCase.id
                                                        ,Prospect_Client__c = acct2.id
                                                        ,Current_Step__c = '(1 of 3) Client in onboarding'
                                                        ,Stand_alone_FBAE__c = false
                                                        ,Stand_alone_Flex_HR__c = true
                                                        ,Stand_alone_TAA__c = true
                                                        ,Lost_Product_FBAE__c = false
                                                        ,Lost_Product_Flex_HR__c = false
                                                        ,Lost_Product_TAA__c = false);
        insert mpsc;
         
        //populate Payroll fields - will change current step and populate transfer date
        //loop through the field set and set the fields
        List<Schema.FieldSetMember> payrollFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_Payroll_fields.getfields();
        
         for (Schema.FieldSetMember pf: payrollFields){
            if(pf.getFieldPath() == 'Est_Payroll_Taking_Time_min__c'){
                mpsc.put(pf.getFieldPath(),30);
            }
            else if(pf.getFieldPath() == 'Client_Reporting_Method__c'){
                mpsc.put(pf.getFieldPath(),'Not Online – Email');
            }
            else if(pf.getFieldPath() == 'Client_Time_Zone__c'){
                mpsc.put(pf.getFieldPath(),'EST');
            }
            else if(pf.getFieldPath() == 'C2C__c'){
                mpsc.put(pf.getFieldPath(),'Parent');
            }     
            else{
            mpsc.put(pf.getFieldPath(),'yes'); 
            } 
        }
         
        //populate TAA IS and TAA fields
        //loop through the field set and set the fields
        List<Schema.FieldSetMember> taaFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_TAA_Fields.getfields();
        for (Schema.FieldSetMember tf: taaFields){
            if (tf.getFieldPath() == 'Clocks__c'){
                mpsc.put(tf.getFieldPath(),'Proximity'); 
            }
            else if (tf.getFieldPath() == 'Additional_Features__c'){
                mpsc.put(tf.getFieldPath(),'Timesheets'); 
            }
            else{
            mpsc.put(tf.getFieldPath(),'yes'); 
            } 
        }
         
        //populate Flex HR IS and Flex HR fields
        //loop through the field set and set the fields
        List<Schema.FieldSetMember> flexFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_Flex_fields.getfields();
        for (Schema.FieldSetMember ff: flexFields){
        if (ff.getFieldPath() == 'Flex_HR_Trainings_Completed__c'){
                mpsc.put(ff.getFieldPath(),'HR Admin tab'); 
            }
        else
            mpsc.put(ff.getFieldPath(),'yes');  
        }

        update mpsc;
         
        //attempt to set to Current Step = 2
        mpsc.Transfer_Call_Type__c = 'Email';
        mpsc.SIPM_IPM__c = u6.id;
        mpsc.SIPM_IP__c = u6.id;
        Test.startTest();
        ReferenceMPSC.TRIGGERS_RAN = false;
        update mpsc;
        Test.stopTest();
        mpscListCurrentStepStandalone = [SELECT Id, Current_Step__c FROM Reference_MPSC__c WHERE id =: mpsc.id];
        system.assertEquals(mpscListCurrentStepStandalone[0].Current_Step__c, '(2 of 3) Client ready for transition');
        
        //attempt to set back to Current Step = 1
        mpsc.Transfer_Call_Type__c = null;
        ReferenceMPSC.TRIGGERS_RAN = false;
        update mpsc;
        mpscListCurrentStepStandalone = [SELECT Id, Current_Step__c FROM Reference_MPSC__c WHERE id =: mpsc.id];
        system.assertEquals(mpscListCurrentStepStandalone[0].Current_Step__c, '(1 of 3) Client in onboarding');
        
        //attempt to set back from Current Step = 1 to Current Step2
        mpsc.All_Products_Validated__c = 'Yes';
        mpsc.Transfer_Call_Type__c = 'Email';
        ReferenceMPSC.TRIGGERS_RAN = false; 
        update mpsc;
        mpscListCurrentStepStandalone = [SELECT Id, Current_Step__c FROM Reference_MPSC__c WHERE id =: mpsc.id];
        system.assertEquals(mpscListCurrentStepStandalone[0].Current_Step__c, '(2 of 3) Client ready for transition');

        //attempt to set to Current Step = 3
        acct2.Paychex_Payroll_Specialist__c = con1.id;    //Payroll BSR
        acct2.Flex_Ben_Admin_Essentials_IC__c = u6.id;    //FBAE IC
        //populate FBAE fields
        //loop through the field set and set the fields
        List<Schema.FieldSetMember> fbaeFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_FBAE_fields.getfields();
        for (Schema.FieldSetMember fbf: fbaeFields){
        if (fbf.getFieldPath() == 'Benefit_Renewal_Month__c'){
                mpsc.put(fbf.getFieldPath(),'August'); 
            }
        else
            mpsc.put(fbf.getFieldPath(),'yes');  
        }
        mpsc.Transfer_Call_Type__c = 'Email';
        mpsc.Date_Ready_for_Transition__c = system.today();
        mpsc.Transfer_Specialist__c = u3.id;
        //mpsc.TAA_BSR__c = u3.id;
        mpsc.TAA_ready_to_Transfer_Date__c = date.today();
        mpsc.TAA_IS__c = u3.id;
        //mpsc.Stand_alone_TAA__c = true;
        acct2.Time_Attendance_AS__c = con2.Id;
        //acct2.HRO_Advisor__c = con2.Id; //BAU Changes
        //mpsc.Flex_HR_BSR__c = u3.id;
        mpsc.Flex_HR_ready_Transfer_Date__c = date.today();
        mpsc.Flex_HR_IS__c = u3.id;
        ReferenceMPSC.TRIGGERS_RAN = false;
        update acct2;
        ReferenceMPSC.TRIGGERS_RAN = false; 
        update mpsc;
        mpscListCurrentStepStandalone = [SELECT Id, Current_Step__c FROM Reference_MPSC__c WHERE id =: mpsc.id];
        system.assertEquals(mpscListCurrentStepStandalone[0].Current_Step__c, '(3 of 3) Transitioned to support');
        
     }//end testCurrentStepStandAlone

     static testMethod void testCurrentStepLost() {
        Contact[] ctcts = getPayxCtcts();
        Contact con1 = ctcts[0];
        Contact con2 = ctcts[1];
        Id[] userIds = new Id[]{con1.User_Lookup__c, con2.User_Lookup__c};
        
        User[] usrs = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and HR_Person_Id__c != null and Id not in :userIds limit 4];       
        User u1 = con1.User_Lookup__r;
        User u2 = con2.User_Lookup__r;
        User u3 = usrs[0];
        User u4 = usrs[1];
        User u5 = usrs[2];
        User u6 = usrs[3];

         Account acct2 = new Account (name = 'Test Account'
                                      ,OwnerId = u1.id                            //Sales Rep
                                      ,HRO_Implementation_Coordinator__c = u1.id  //Flex HR IS
                                      ,TLO_Implementation_Coordinator__c = u2.id  //TAA IS
                                      ,Flex_Ben_Admin_Essentials_IC__c = u6.id    //FBAE IC
                                      ,MMS_MAM_NAM__c = con2.id);//contact        //SIPM/IPM
         insert acct2;
         
        List<Reference_MPSC__c> mpscListCurrentStepLost = new List<Reference_MPSC__c>();
        
        //MPSC Transfer Case
        Id mpscTransferCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('MPSC Transfer Case').getRecordTypeId();
        Case mpscTransferCase = new Case (recordtypeId = mpscTransferCaseRT
                                ,AccountId = acct2.id);                 
        insert mpscTransferCase;
        
        Id mpscTransfer = Schema.SObjectType.Reference_MPSC__c.getRecordTypeInfosByName().get('Reference MPSC Transfer').getRecordTypeId();
        Reference_MPSC__c mpsc = new Reference_MPSC__c(recordtypeId = mpscTransfer
                                                        ,Case_Lookup__c = mpscTransferCase.id
                                                        ,Prospect_Client__c = acct2.id
                                                        ,Current_Step__c = null
                                                        ,Payroll_IS__c = u6.id
                                                        ,PM_Approved__c = true
                                                        ,SIPM_IPM__c = u6.id
                                                        ,Stand_alone_FBAE__c = false
                                                        ,Stand_alone_Flex_HR__c = false
                                                        ,Stand_alone_TAA__c = false
                                                        ,Lost_Product_FBAE__c = false
                                                        ,Lost_Product_Flex_HR__c = false
                                                        ,Lost_Product_TAA__c = false);
        insert mpsc;
         
        mpsc.Lost_Product_Flex_HR__c = true;
         
        ReferenceMPSC.TRIGGERS_RAN = false;
        update mpsc;
                 
        //populate Payroll fields - will change current step and populate transfer date
        //loop through the field set and set the fields
        List<Schema.FieldSetMember> payrollFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_Payroll_fields.getfields();
        for (Schema.FieldSetMember pf: payrollFields){
            if(pf.getFieldPath() == 'Est_Payroll_Taking_Time_min__c'){
                mpsc.put(pf.getFieldPath(),30);
            }
            else if(pf.getFieldPath() == 'Client_Reporting_Method__c'){
                mpsc.put(pf.getFieldPath(),'Not Online – Email');
            }
            else if(pf.getFieldPath() == 'Client_Time_Zone__c'){
                mpsc.put(pf.getFieldPath(),'EST');
            }
            else if(pf.getFieldPath() == 'C2C__c'){
                mpsc.put(pf.getFieldPath(),'Parent');
            }     
            else{
            mpsc.put(pf.getFieldPath(),'yes'); 
            } 
        }

        //populate Flex HR IS and Flex HR fields
        mpsc.Flex_HR_IS__c = u1.id;
        
        //loop through the field set and set the fields
        List<Schema.FieldSetMember> flexFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_Flex_fields.getfields();
        for (Schema.FieldSetMember ff: flexFields){
        if (ff.getFieldPath() == 'Flex_HR_Trainings_Completed__c'){
                mpsc.put(ff.getFieldPath(),'HR Admin tab'); 
            }
        else
            mpsc.put(ff.getFieldPath(),'yes');  
        }

        //populate FBAE fields
        //loop through the field set and set the fields
        List<Schema.FieldSetMember> fbaeFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_FBAE_fields.getfields();
        for (Schema.FieldSetMember fbf: fbaeFields){
        if (fbf.getFieldPath() == 'Benefit_Renewal_Month__c'){
                mpsc.put(fbf.getFieldPath(),'August'); 
            }
        else
            mpsc.put(fbf.getFieldPath(),'yes');  
        }
        
        mpsc.PM_Approved__c = true;
        update mpsc;
        
        mpsc.Lost_Product_Flex_HR__c = true;
        mpsc.Lost_Product_TAA__c = false;
        mpsc.Flex_HR_IS__c = null;
        mpsc.Flex_HR_ready_Transfer_Date__c = null;
        mpsc.Flex_HR_Trainings_Completed__c = null;
        mpsc.TAA_IS__c = u2.id;
        mpsc.TAA_ready_to_Transfer_Date__c = system.today();
        
        //populate TAA IS and TAA fields
        //loop through the field set and set the fields
        List<Schema.FieldSetMember> taaFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_TAA_Fields.getfields();
        for (Schema.FieldSetMember tf: taaFields){
            if (tf.getFieldPath() == 'Clocks__c'){
                mpsc.put(tf.getFieldPath(),'Proximity'); 
            }
            else if (tf.getFieldPath() == 'Additional_Features__c'){
                mpsc.put(tf.getFieldPath(),'Timesheets'); 
            }
            else{
            mpsc.put(tf.getFieldPath(),'yes'); 
            } 
        }
        Test.startTest();
        ReferenceMPSC.TRIGGERS_RAN = false;
        update mpsc;
        Test.stopTest();
         
        mpscListCurrentStepLost = [SELECT Id, Current_Step__c FROM Reference_MPSC__c WHERE id =: mpsc.id];
        system.assertEquals(mpscListCurrentStepLost[0].Current_Step__c, '(1 of 3) Client in onboarding');

        mpsc.Transfer_Call_Type__c = 'Email';
        ReferenceMPSC.TRIGGERS_RAN = false;
        update mpsc;
        
        mpsc.Lost_Product_Flex_HR__c = false;
        mpsc.Lost_Product_TAA__c = true;
        mpsc.Flex_HR_IS__c = u1.id;
        
        //loop through the field set and set the fields
        List<Schema.FieldSetMember> flexFields2 = SObjectType.Reference_MPSC__c.FieldSets.MPSC_Flex_fields.getfields();
        for (Schema.FieldSetMember ff2: flexFields2){
        if (ff2.getFieldPath() == 'Flex_HR_Trainings_Completed__c'){
                mpsc.put(ff2.getFieldPath(),'HR Admin tab'); 
            }
        else
            mpsc.put(ff2.getFieldPath(),'yes');  
        }
        mpsc.Flex_HR_ready_Transfer_Date__c = system.today();
        mpsc.TAA_IS__c = null;
        mpsc.Clocks__c = null;
        mpsc.TAA_ready_to_Transfer_Date__c = null;
        ReferenceMPSC.TRIGGERS_RAN = false;
        update mpsc;
        mpscListCurrentStepLost = [SELECT Id, Current_Step__c FROM Reference_MPSC__c WHERE id =: mpsc.id];
        system.assertEquals(mpscListCurrentStepLost[0].Current_Step__c, '(2 of 3) Client ready for transition');
        
        //mpsc.Payroll_BSR__c = u3.id;
        acct2.Paychex_Payroll_Specialist__c = con2.Id;
        //acct2.HRO_Advisor__c = con2.Id;
        //ReferenceMPSC.TRIGGERS_RAN = false;
        //update acct2;
        //mpsc.Flex_HR_BSR__c = u3.id;
        mpsc.Date_Ready_for_Transition__c = system.today();
        mpsc.Transfer_Specialist__c = u3.id;
        mpsc.Sales_Rep__c = u1.id;
        mpsc.SIPM_IP__c = u1.id;
        ReferenceMPSC.TRIGGERS_RAN = false;
        update acct2;
        ReferenceMPSC.TRIGGERS_RAN = false;
        update mpsc;
         
        mpscListCurrentStepLost = [SELECT Id, Current_Step__c FROM Reference_MPSC__c WHERE id =: mpsc.id];
        system.assertEquals(mpscListCurrentStepLost[0].Current_Step__c, '(3 of 3) Transitioned to support');
 
     }//end testCurrentStepLost

} // class ReferenceMPSCTest