/* 
   Test methods for the ReferenceUpdateCase class and triggers associated with the Reference objects.
   
  History
  -------
  08/05/2010 Dan Carmen     Created.
  02/21/2011 Dan Carmen     Added the Credit Risk object
  09/09/2011 Dan Carmen     Modified trigger to set client unresponsive status. Added test cases for this.
  09/19/2011 Dan Carmen     Added Reference PEO test
  03/27/2012 Carrie Marciano changed HRO NCT to HRO LCT
  01/16/2012 Justin Stouffer    Added Service Onboarding PEM Record Type
  07/03/2012 Justin Stouffer Added verify Ref RecordType Change
  03/06/2013 Josh Cartwright - added Payroll Fulfillment and Terminations/Transfers
  07/02/2013 Josh Cartwright - added MSP Onboarding
  08/02/2013 Justin Henderson - Added RRS/SEBS/ePlan
  09/16/2013 Justin Henderson - Added in new testMethod for Reference ASO 
  10/02/2013 Cindy Freeman     Added MMS Payroll case tests    
  12/31/2013 Josh Cartwright - Added CA HRO Onboarding 
  01/20/2014 Josh Cartwright - Added HNBF Onboarding
  03/10/2014 Justin henderson - Removed call to update opportunity status for MMS
  01/20/2015 Justin Henderson - Added ESR Onboarding
  02/02/2015 Justin Henderson - Updated ESR Current Step Values
  03/31/2015 Justin Stouffer - Added MPSC Onboarding Test
  04/20/2015 Jacob Hinds    Added validation fields to GLUpdateStep
  04/22/2015 Jacob Hinds    Changed Assert from Solved to Follow Up with Client in GLUpdateStep
  07/23/2015 Carrie Marciano Added BeneTrac Operations Onboarding
  08/04/2015 Frank Lurz     Added Reference PEO No Start object - Case Status
  10/01/2015 Jacob Hinds    Added Reference Enterprise Service
  10/29/2015 Jacob Hinds    Added caseOwnerUpdate method and Reference Incoming Funds tests for 401k Operations Support
  2/5/2016 Josh Cartwright per case:20232252 removed 401k steps from updating case to solved
  06/16/2016 Jacob Hinds        Removing ESR from Case Status Update
  08/29/2016 Dan Carmen     Updated testEnterpriseServiceUpdateStep
  02/02/2017 Lynn Michels   Updating test for Service Onboarding S125 New Case/Ref S125 Onboarding and adding missing code coverage
  05/05/2017 Lynn Michels	Adding code coverage for failures
  07/02/2018 Lynn Michels   Update 	testRefCorePayMPSC to use custom setting values 
  09/03/2020 Jake Hinds		Adding owner to refHNBF test
  09/01/2021 Carrie Marciano  Removed the Credit Risk object due to uninstalling Equifax package
  04/11/2023 Chris Santoro	Added Reference Client Retention 
  10/04/2023 Eric Porter/Susmitha Somavarapu Added code for testCorePayUpdateStep
  03/25/2024 Jaipal          APR015314 Changed recordtype of BeneTrac Onboarding' to 'Benefits Administration Onboarding'
  04/10/2024  Carrie Marciano    Removed code related to old MPSC Process
 */
@isTest
private class ReferenceUpdateCaseTest {
    
    static FINAL String SDA_FLOCK_PL_VALUE = 'SDA Flock Net-New';
    static FINAL String AOR_FLOCK_PL_VALUE = 'AOR Flock Pilot';
    static FINAL String AOR_PAYROLL_QUEUE_NAME = 'AOR Payroll Integration Queue';
    static FINAL String NEW_CASE_PAYROLL_QUEUE_NAME = 'New Case Payroll Integration Queue';
    
    /*@testSetup
    static void setup() {
        User runUser = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' limit 1];
        System.runAs(runUser) {
            
            // insert queues
            Group aorPayrollQueue = new Group(name=AOR_PAYROLL_QUEUE_NAME, type='Queue');
            Group newCasePayrollQueue = new Group(name=NEW_CASE_PAYROLL_QUEUE_NAME, type='Queue');
            List<Group> queues = new List<Group>{aorPayrollQueue, newCasePayrollQueue}; 
                INSERT queues;
            
            List<QueueSobject> qSobjects = new List<QueueSobject>();
            qSobjects.add(new QueueSobject(QueueId=aorPayrollQueue.Id,SobjectType='Reference_HNBF__c'));
            qSobjects.add(new QueueSobject(QueueId=newCasePayrollQueue.Id,SobjectType='Reference_HNBF__c'));
            INSERT qSobjects;
        }
    }*/
      static testMethod void testHROUpdateStep() {
      List<Case> cases = new List<Case>();
      // create a case
      cases.add(createCase('Service Onboarding HRO Case Record Type'));
      cases.add(createCase('Service Onboarding EAO Case Record Type'));
      cases.add(createCase('Service Onboarding W2 Only Case Record Type'));
      cases.add(createCase('Service Additional HRO LCT Contact Record Type'));
      cases.add(createCase('Service Onboarding PEM Case Record Type')); 
       
      cases.add(createCase('Service Onboarding MSP Case Record Type'));     
      cases.add(createCase('Service Onboarding MSP Case Record Type'));    
      cases.add(createCase('Service Onboarding CA HRO Record Type'));
             
      insert cases;
      
      // MSP record types are using new (dynamic) code - manually create reference objects 
      Reference_HRO__c[] newRefs = new Reference_HRO__c[]{};
      newRefs.add(new Reference_HRO__c(Case_Number__c=cases[5].Id));
      newRefs.add(new Reference_HRO__c(Case_Number__c=cases[6].Id));
      newRefs.add(new Reference_HRO__c(Case_Number__c=cases[7].Id));      
      insert newRefs;
      
      List<Reference_HRO__c> refs = new List<Reference_HRO__c>();
      // verify reference objects were created.
      refs.add([Select Id, Current_Step__c from Reference_HRO__c where Case_Number__c = :cases[0].Id]);
      refs.add([Select Id, Current_Step__c from Reference_HRO__c where Case_Number__c = :cases[1].Id]);
      refs.add([Select Id, Current_Step__c from Reference_HRO__c where Case_Number__c = :cases[2].Id]);
      refs.add([Select Id, Current_Step__c from Reference_HRO__c where Case_Number__c = :cases[3].Id]);
      refs.add([Select Id, Current_Step__c from Reference_HRO__c where Case_Number__c = :cases[4].Id]); 

      refs.add([Select Id, Current_Step__c from Reference_HRO__c where Case_Number__c = :cases[5].Id]);
      refs.add([Select Id, Current_Step__c from Reference_HRO__c where Case_Number__c = :cases[6].Id]);  
      refs.add([Select Id, Current_Step__c from Reference_HRO__c where Case_Number__c = :cases[7].Id]);                   
      
      // change step, verify step changes on Case
      refs[0].Current_Step__c = 'Onboarding Complete';
      refs[1].Current_Step__c = 'Client Unresponsive';
      refs[2].Current_Step__c = 'Refused';
      refs[3].Current_Step__c = 'LCT Complete';
      refs[4].Current_Step__c = 'Onboarding Complete';
      refs[5].Current_Step__c = 'Onboarding Complete';  
      refs[6].Current_Step__c = 'Lost Client';  
      refs[7].Current_Step__c = 'Onboarding Complete';          
      update refs;
      
      // verify cases
      verifyCase(cases[0].Id, 'Onboarding Complete', 'Completed');
      verifyCase(cases[1].Id, 'Client Unresponsive', 'Client Unresponsive');
      verifyCase(cases[2].Id, 'Refused', 'Refused');
      verifyCase(cases[3].Id, 'LCT Complete', 'LCT Complete');
      verifyCase(cases[4].Id, 'Onboarding Complete', 'Completed');     
      verifyCase(cases[5].Id, 'Onboarding Complete', 'Completed');  
      verifyCase(cases[6].Id, 'Lost Client', 'Lost Client');   
      verifyCase(cases[7].Id, 'Onboarding Complete', 'Completed');               
      
   } // testUpdateStep
    
    static testMethod void testRefClientRetentionUpdateStatus() {
        List<Case> cases = new List<Case>();
        
        cases.add(createCase('Service Support Client Retention'));      
        insert cases;
        
        Reference_Client_Retention__c[] newRefs = new Reference_Client_Retention__c[]{};
            newRefs.add(new Reference_Client_Retention__c(Case__c=cases[0].Id));
        insert newRefs;
        
        List<Reference_Client_Retention__c> refs = new List<Reference_Client_Retention__c>();
        // verify reference objects were created.
        refs.add([Select Id, Current_Step__c from Reference_Client_Retention__c where Case__c = :cases[0].Id]);              
        
        // change step, verify step changes on Case
        refs[0].Current_Step__c = 'Field Resolved';
        
        update refs;
    } 
   
   static testMethod void testASOUpdateStep() {
      List<Case> cases = new List<Case>();
      // create a case
         
      cases.add(createCase('Service Onboarding ASO New Business'));      
      insert cases;
      
      // ASO record types are using new (dynamic) code - manually create reference objects 
      Reference_ASO__c[] newRefs = new Reference_ASO__c[]{};
      newRefs.add(new Reference_ASO__c(Case_Number__c=cases[0].Id));
      insert newRefs;
      
      List<Reference_ASO__c> refs = new List<Reference_ASO__c>();
      // verify reference objects were created.
      refs.add([Select Id, Current_Step__c from Reference_ASO__c where Case_Number__c = :cases[0].Id]);              
      
      // change step, verify step changes on Case
      refs[0].Current_Step__c = 'Setup Complete';
         
      update refs;
      
      // verify cases
  // 2-9-16 JC    verifyCase(cases[0].Id, 'Setup Complete', 'Solved');
         
      
   } // testUpdateStep    
   
   static testMethod void testHNBFUpdateStep() {
      User newUser = [SELECT ID FROM User WHERE isActive = true AND Profile.Name = 'System Administrator' AND Id != :UserInfo.getUserId() LIMIT 1];
      List<Case> cases = new List<Case>();
      // create a case
         
      cases.add(createCase('Service Onboarding HNBF Case Record Type'));      
      insert cases;
      
      // HNBF record types are using new (dynamic) code - manually create reference objects 
      Reference_HNBF__c[] newRefs = new Reference_HNBF__c[]{};
      Id hnbfRT = RecordTypeHelper.getRecordType('HNB Enrollments ATC Record Type', 'Reference_HNBF__c').getRecordTypeId();	
      newRefs.add(new Reference_HNBF__c(Case_Number__c=cases[0].Id, status__c  = 'New', recordtypeid =hnbfRT ));
       insert newRefs;
      
      List<Reference_HNBF__c> refs = new List<Reference_HNBF__c>();
      // verify reference objects were created.
      refs.add([Select Id, Current_Step__c,OwnerId from Reference_HNBF__c where Case_Number__c = :cases[0].Id]);              
      
      // change step, verify step changes on Case
      refs[0].Current_Step__c = 'Onboarding Complete';
      refs[0].OwnerId = newUser.Id;
      refs[0].status__c = 'Closed';	
   
      update refs;
      
      // verify cases
      Case updatedCase = [SELECT Id,Status,Current_Step__c,OwnerId FROM Case WHERE id = :cases[0].Id LIMIT 1];
      system.assertEquals('Onboarding Complete',updatedCase.Current_Step__c);
      system.assertEquals('Closed',updatedCase.Status);
     // system.assertEquals(newUser.Id,updatedCase.OwnerId);
         
      
   } // testUpdateStep
   
    
   /*static testMethod void testESRUpdateStep() {
      List<Case> cases = new List<Case>();
      // create a case
         
      cases.add(createCase('Service Onboarding ESR Case Record Type'));
      cases.add(createCase('Service Onboarding ESR Case Record Type')); 
      cases.add(createCase('Service Onboarding ESR Case Record Type'));
      cases.add(createCase('Service Onboarding ESR Case Record Type'));
      insert cases;
      
      // ESR record types are using new (dynamic) code - manually create reference objects 
      Reference_HNBF__c[] newRefs = new Reference_HNBF__c[]{};
      newRefs.add(new Reference_HNBF__c(Case_Number__c=cases[0].Id));
      newRefs.add(new Reference_HNBF__c(Case_Number__c=cases[1].Id));
      newRefs.add(new Reference_HNBF__c(Case_Number__c=cases[2].Id));
      newRefs.add(new Reference_HNBF__c(Case_Number__c=cases[3].Id));
      insert newRefs;
      
      List<Reference_HNBF__c> refs = new List<Reference_HNBF__c>();
      // verify reference objects were created.
      refs.add([Select Id, Current_Step__c from Reference_HNBF__c where Case_Number__c = :cases[0].Id]);
      refs.add([Select Id, Current_Step__c from Reference_HNBF__c where Case_Number__c = :cases[1].Id]);
      refs.add([Select Id, Current_Step__c from Reference_HNBF__c where Case_Number__c = :cases[2].Id]);
      refs.add([Select Id, Current_Step__c from Reference_HNBF__c where Case_Number__c = :cases[3].Id]);
      
      // change step, verify step changes on Case
      refs[0].Current_Step__c = 'Onboarding Complete';
      refs[1].Current_Step__c = 'Refused';
      refs[2].Current_Step__c = 'Lost Client';
      refs[3].Current_Step__c = '(2 of 5) New Case Submitted';
         
      update refs;
      
      // verify cases
      verifyCase(cases[0].Id, 'Onboarding Complete', 'Completed');
      verifyCase(cases[1].Id, 'Refused', 'Refused');   
      verifyCase(cases[2].Id, 'Lost Client', 'Cancelled');
      verifyCase(cases[3].Id, '(2 of 5) New Case Submitted', 'In Progress');
       
   } // testUpdateStep*/
   
   
   
   

    static testMethod void testTAAUpdateStep() {
      Case c1 = createCase('Service Onboarding TAA Case2');
      insert c1;
      
      // verify reference object was created.
      Reference_TAA__c ref1 = [Select Id, Current_Step__c, RecordType.Name from Reference_TAA__c where Case_Lookup__c = :c1.Id];
      
      // change step, verify step changes on Case
      ref1.Current_Step__c = 'Client Graduated';
      update ref1;
      
      // verify case
      verifyCase(c1.Id, 'Client Graduated', 'Solved');     
      
      // verify new case was created
      Case c2 = [Select Id, RecordType.Name, Subject, Product__c from case where ParentId=:c1.Id];
      System.assertEquals('Service Support TAA Case',c2.RecordType.Name);
      System.assertEquals('TLO Onboarding Complete - Graduate to Support',c2.Subject);
      System.assertEquals('TLO',c2.Product__c);
      
      // verify Ref RecordType Change
      Reference_TAA__c ref2 = [Select Id, RecordType.Name from Reference_TAA__c where Id = :ref1.Id];
      System.assertEquals('Reference TAA Support Record Type',ref2.RecordType.Name);
       
   } // testTAAUpdateStep

    //LM Verify cases current step changes when ref s125 onboarding onboarding status changes.
    static testMethod void testRefS125Onboarding() {
      Case c1 = createCase('Service Onboarding S125 New Case');
      insert c1;
      
      //create Reference S125 Onboarding record
      Reference_S125_Onboarding__c rs125 = new Reference_S125_Onboarding__c(case_lookup__c = c1.id);
      insert rs125; 
      
    //  rs125.onboarding_status__c = 'Onboarding in Process';
     // update rs125;
      
      // verify case current step changes
   //   Case cUpdated = [Select Id, current_step__c from Case where Id = :c1.Id];
    //  Reference_S125_Onboarding__c ref2 = [Select Id, onboarding_status__c from Reference_S125_Onboarding__c where Id = :rs125.Id];
   //   System.assertEquals(cUpdated.current_step__c,ref2.onboarding_status__c);
       
   } // testRefS125Onboarding
   
   static testMethod void test401UpdateStep() {
      List<Case> cases = new List<Case>();
      // create a case
      cases.add(createCase('Service Onboarding 401k Conversion'));
      cases.add(createCase('Service Onboarding 401k New Case'));
      cases.add(createCase('Service Onboarding S125 Conversion'));
      insert cases;
      
      List<Reference_401k_S125__c> refs = new List<Reference_401k_S125__c>();
      // verify reference objects were created.
      refs.add([Select Id, Current_Step__c from Reference_401k_S125__c where Case_Lookup__c = :cases[0].Id]);
      refs.add([Select Id, Current_Step__c from Reference_401k_S125__c where Case_Lookup__c = :cases[1].Id]);
     
      // change step, verify step changes on Case
      refs[0].Current_Step__c = '(4 of 4) Onboarding Complete';
      refs[1].Current_Step__c = 'Lost During Onboarding';
      update refs;
      
      // verify cases
      verifyCase(cases[0].Id, '(4 of 4) Onboarding Complete', 'Solved');
      verifyCase(cases[1].Id, 'Lost During Onboarding', 'Solved');
   } // testTAAUpdateStep 

   static testMethod void testGLUpdateStep() {
      Case c1 = createCase('Service Onboarding GL Case');
      insert c1;
      
      // verify reference object was created.
      Reference_GL__c ref1 = [Select Id, Current_Step__c from Reference_GL__c where Case_Lookup__c = :c1.Id];
      
      // set exporting reporting utilized and complexity (Required to complete setup as per field validation).
      ref1.Exporting_Reporting_Utilized__c = 'DET';
      ref1.Complexity__c = 'Simple';
      
      // change step, verify step changes on Case
      ref1.Current_Step__c = 'Set Up Complete';
      update ref1;
      
      // verify case
      verifyCase(c1.Id, 'Set Up Complete', 'Follow Up With Client');
      
   } // testGLUpdateStep

   /** Test the Client Relations Reference object.
    */
     static testMethod void testCltRltnUpdateStep() {
      // create an Account to test the credit limit
      Account a = new Account(Name='Test Acct');
      insert a;
      
      Case c1 = createCase('Service Support Corporate Concerns');
      // link the account to the case
      c1.AccountId = a.Id;
      insert c1;
      
      // verify reference object was created.
      Reference_Client_Relations__c ref1 = [Select Id, Current_Step__c from Reference_Client_Relations__c where 

Case_Lookup__c = :c1.Id];
      
   } // testCltRltnUpdateStep

   static testMethod void testCorePayUpdateStep() {
      Case c1 = createCase('Service Onboarding Core Payroll Case');
      insert c1;
      Reference_Core_Payroll__c rcp1 = [Select Id, RecordTypeId, Case_Lookup__c, Sales_Rep__c,Proposed_Run_Date__c, Client_Load_Received__c, OwnerId,Payroll_Run_Date__c from Reference_Core_Payroll__c where  Case_Lookup__c =: c1.Id limit 1];
     //System.debug('*** OG RCP ***');
      //System.debug(rcp1);
      CreateTestData.createTestAandC();
      Account a1 = [Select Id, Name from Account where name = 'Test Account1'];
      c1.AccountId = a1.id; 
      update c1; 

      Contact ctct1 = [Select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First' and LastName = 

'Last1'];
      // create the reference object, since this is normally done on a trigger off of the opportunity.
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('Reference Onboarding Core Payroll','Reference_Core_Payroll__c');
      // Reference_Core_Payroll__c rcp = new Reference_Core_Payroll__c(
      //                         Id = rcp1.Id
                            rcp1.RecordTypeId = rt.getRecordTypeId();
                            rcp1.Case_Lookup__c = c1.Id;
                            rcp1.Sales_Rep__c = Userinfo.getUserId();
                            rcp1.Proposed_Run_Date__c = Date.today();
                            rcp1.Client_Load_Received__c = true;
                            rcp1.OwnerId = Userinfo.getUserId();
                            rcp1.Payroll_Run_Date__c= Date.today();
                            rcp1.Date_Is_Assigned__c = Date.today();
                            rcp1.CallerName__c = ctct1.Id;
                            rcp1.Client_Load_Complete__c = true;
                            rcp1.Date_Client_Load_Complete__c = Date.today();
                            rcp1.Date_Client_Load_Received__c = Date.today();
                            rcp1.Client_ready_For_Transition__c = true;
                           //  );
                            
      //insert rcp;
      //05/22/2023 ECP update from 4 of 4 to 6 of 6 for current step 
      rcp1.Current_Step__c = 'Onboarding Complete';
      update rcp1;
      
       verifyCase(c1.Id, 'Onboarding Complete', 'Completed');
      
      rcp1.Current_Step__c = 'Client Never Ran';
      rcp1.Client_ready_For_Transition__c = false;
      rcp1.Client_Never_Ran__c = true;
      rcp1.Client_Never_Ran_Reason__c ='Dual Channel';
      update rcp1;
      
      verifyCase(c1.Id, 'Client Never Ran', 'Completed');
   } // testCorePayUpdateStep
   
    //LM
    static testMethod void testRefCorePayMPSC() {
    	Client_Overview_Configuration__c coc = new Client_Overview_Configuration__c(Name='Core Advance Payroll' 
      																			  ,Product_Name__c='Core Payroll'
                                                                                  ,Reference_Object_Relationship_API_Name__c='Reference_Core_Payroll__r'
                                                                                  ,Completed_Onboarding_Status__c='(7 of 7) Onboarding Complete – Transitioned to support,(6 of 6) Client ready for transition'
                                                                                  ,Case_Record_Type_Name__c='Service Onboarding MPSC Core Payroll Case'
                                                                                  ,Owner_Custom_Label__c='Service Team - New Client Specialist'
                                                                                  ,Case_Only__c=FALSE
                                                                                  ,MPSC__c=TRUE);
  		insert coc;
      Case c1 = createCase('Service Onboarding MPSC Core Payroll Case');
      insert c1;
      
      Id refCoreRT = Schema.SObjectType.Reference_Core_Payroll__c.getRecordTypeInfosByName().get('Reference Onboarding Core Payroll').getRecordTypeId();
      
      //create Reference Core Payroll record
      Reference_Core_Payroll__c refCore = new Reference_Core_Payroll__c(case_lookup__c = c1.id,
                                                                        RecordTypeId = refCoreRT);
      insert refCore;
      
      refCore.current_step__c = 'Client Never Ran';
      update refCore;
      verifyCase(c1.Id, 'Client Never Ran', 'Lost Client');
      
      refCore.current_step__c = 'On Hold';
      update refCore;
      verifyCase(c1.Id, 'On Hold', 'In Progress - Client Delay');
      
      refCore.current_step__c = 'Lost During Onboarding';
      update refCore;
      verifyCase(c1.Id, 'Lost During Onboarding', 'Lost Client');     
   } // testRefCorePayMPSC
   
    //LM Case and Ref Core Payroll - MPSC Exception
    /*
    static testMethod void testRefCorePayMPSCException() {
      Case c1 = createCase('MPSC Exception');
      insert c1;
      
      Id refCoreRT = Schema.SObjectType.Reference_Core_Payroll__c.getRecordTypeInfosByName().get('MPSC Exception').getRecordTypeId();
      
      //create Reference Core Payroll record
      Reference_Core_Payroll__c refCore = new Reference_Core_Payroll__c(case_lookup__c = c1.id,
                                                                        RecordTypeId = refCoreRT);
      insert refCore;
      
      refCore.current_step__c = '(1 of 3) Submitted - Waiting on DSM';
      update refCore;
      verifyCase(c1.Id, '(1 of 3) Submitted - Waiting on DSM', 'Waiting on Sales');
      
      refCore.current_step__c = '(2 of 3) DSM Approved - Waiting on Ops';
      update refCore;
      verifyCase(c1.Id, '(2 of 3) DSM Approved - Waiting on Ops', 'Waiting on Ops');
      
      refCore.current_step__c = '(3 of 3) Approved';
      update refCore;
      verifyCase(c1.Id, '(3 of 3) Approved', 'Completed');
      
       refCore.current_step__c = 'Rejected';
      update refCore;
      verifyCase(c1.Id, 'Rejected', 'Refused');      
   } // testRefCorePayMPSCException
   */
    
   // The the reference PEO object.
   static testMethod void testRefPEOUpdateStep() {
      // create an Account
      Account a = new Account(Name='Test Acct');
      insert a;
      
      Case c1 = createCase(OpportunityCreateCase.RT_CASE_PEO);
      // link the account to the case
      c1.AccountId = a.Id;
      insert c1;
      
      // verify reference object was created.
      Reference_PEO__c ref1 = [Select Id, Current_Step__c from Reference_PEO__c where Parent_Case__c = :c1.Id];
      
      // populate Contract Received date which will update the current step by process builder flow
      ref1.Contract_Received__c = date.today();
      update ref1;
      
      // verify case
     // verifyCase(c1.Id, '(1 of 7) Contracts Received', null);
   } // testRefPEOUpdateStep
  
    static testMethod void testTermsTransUpdateStep() {
      List<Case> cases = new List<Case>();
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('401k/S125 Operations Support', 'Case');
      Id rtId = (rt != null ? rt.getRecordTypeId() : null);

      // create a case
      cases.add(new Case(RecordTypeId=rtId,Product__c='401K', HRS4SCategory1__c ='Billing 401k', Termination_Transfer_Type__c='Termination'));
      cases.add(new Case(RecordTypeId=rtId,Product__c='401K',HRS4SCategory1__c ='Billing 401k',Termination_Transfer_Type__c='Termination'));
      cases.add(new Case(RecordTypeId=rtId,Product__c='401K',HRS4SCategory1__c ='Billing 401k',Termination_Transfer_Type__c='Termination'));
      cases.add(new Case(RecordTypeId=rtId,Product__c='401K',HRS4SCategory1__c ='Billing 401k',Termination_Transfer_Type__c='Termination'));
      cases.add(new Case(RecordTypeId=rtId,Product__c='401K',HRS4SCategory1__c ='Billing 401k',Termination_Transfer_Type__c='Termination'));
      cases.add(new Case(RecordTypeId=rtId,Product__c='401K',HRS4SCategory1__c ='Billing 401k',Termination_Transfer_Type__c='Termination'));
      cases.add(new Case(RecordTypeId=rtId,Product__c='401K',HRS4SCategory1__c ='Billing 401k',Termination_Transfer_Type__c='Termination'));     
      cases.add(new Case(RecordTypeId=rtId,Product__c='401K',HRS4SCategory1__c ='Billing 401k',Termination_Transfer_Type__c='Termination'));  
      cases.add(new Case(RecordTypeId=rtId,Product__c='401K',HRS4SCategory1__c ='Billing 401k',Termination_Transfer_Type__c='Termination'));                                    
      insert cases;
      
      Reference_Terms_Transfers__c[] refs = [Select Id, Current_Step__c, Case_Lookup__c from Reference_Terms_Transfers__c];
      Map<Id,Reference_Terms_Transfers__c> refMap = new Map<Id,Reference_Terms_Transfers__c>();
      for (Reference_Terms_Transfers__c ref : refs) {
         refMap.put(ref.Case_Lookup__c,ref);
      }

      // change step, verify step changes on Case
      refMap.get(cases[0].Id).Current_Step__c = 'Closed – Paperwork Discrepancy Never Resolved';
      refMap.get(cases[1].Id).Current_Step__c = 'Term/Transfer Stopped';
      refMap.get(cases[2].Id).Current_Step__c = '401(k) Termination Complete';
      refMap.get(cases[3].Id).Current_Step__c = 'S125 FSA Termination Complete' ;
      refMap.get(cases[4].Id).Current_Step__c = 'S125 FSA Termination Complete - POP Downgrade Complete' ;
      refMap.get(cases[5].Id).Current_Step__c = 'S125 FSA Termination Cancelled - Client Saved';
      refMap.get(cases[6].Id).Current_Step__c = 'S125 POP Termination Complete';
      refMap.get(cases[7].Id).Current_Step__c = '401k Transfer Complete';
      refMap.get(cases[8].Id).Current_Step__c = 'NSF Closed';            
      update refMap.values();
      
      Map<Id,Case> caseMap = new Map<Id,Case>([select Id, Current_Step__c, Status, RecordTypeId from case]);
      // verify cases
      verifyCase(caseMap.get(cases[0].Id), 'Closed – Paperwork Discrepancy Never Resolved', 'Solved');
      verifyCase(caseMap.get(cases[1].Id), 'Term/Transfer Stopped', 'Solved');
      verifyCase(caseMap.get(cases[2].Id), '401(k) Termination Complete', 'Solved');
      verifyCase(caseMap.get(cases[3].Id), 'S125 FSA Termination Complete', 'Solved');
      verifyCase(caseMap.get(cases[4].Id), 'S125 FSA Termination Complete - POP Downgrade Complete', 'Solved');
      verifyCase(caseMap.get(cases[5].Id), 'S125 FSA Termination Cancelled - Client Saved', 'Solved');
      verifyCase(caseMap.get(cases[6].Id), 'S125 POP Termination Complete', 'Solved');
      verifyCase(caseMap.get(cases[7].Id), '401k Transfer Complete', 'Solved');
      verifyCase(caseMap.get(cases[8].Id), 'NSF Closed', 'Solved');            

   } // testTermTransUpdateStep 
   
   static testMethod void testPRFulfillmentUpdateStep() {
      List<Case> cases = new List<Case>();
      // create a case
      cases.add(createCase('Service Onboarding Payroll Fulfillment'));
      cases.add(createCase('Service Onboarding Payroll Fulfillment'));
      cases.add(createCase('Service Onboarding Payroll Fulfillment'));
      cases.add(createCase('Service Onboarding Payroll Fulfillment'));
      cases.add(createCase('Service Onboarding Payroll Fulfillment'));
      insert cases;
      
      List<Reference_Payroll_Fulfillment__c> refs = new List<Reference_Payroll_Fulfillment__c>();
      // verify reference objects were created.
      refs.add([Select Id, Current_Step__c from Reference_Payroll_Fulfillment__c where Case_Number__c = :cases[0].Id]);
      refs.add([Select Id, Current_Step__c from Reference_Payroll_Fulfillment__c where Case_Number__c = :cases[1].Id]);
      refs.add([Select Id, Current_Step__c from Reference_Payroll_Fulfillment__c where Case_Number__c = :cases[2].Id]);
      refs.add([Select Id, Current_Step__c from Reference_Payroll_Fulfillment__c where Case_Number__c = :cases[3].Id]);
      refs.add([Select Id, Current_Step__c from Reference_Payroll_Fulfillment__c where Case_Number__c = :cases[4].Id]);
      
      // change step, verify step changes on Case
      refs[0].Current_Step__c = '(6 of 6) Final Verification/ Released/ Processed';
      refs[0].Date_Closed__c = datetime.now();
      refs[1].Current_Step__c = 'Lost During Onboarding';
      refs[2].Current_Step__c = 'Closed â€“ Client Never Started';
      refs[3].Current_Step__c = 'Closed â€“ Client NSF';
      refs[4].Current_Step__c = 'Closed â€“ Other';

      update refs;
      
      // verify cases
      verifyCase(cases[0].Id, '(6 of 6) Final Verification/ Released/ Processed', 'Solved');
      verifyCase(cases[1].Id, 'Lost During Onboarding', 'Solved');
      verifyCase(cases[2].Id, 'Closed â€“ Client Never Started', 'Solved');
      verifyCase(cases[3].Id, 'Closed â€“ Client NSF', 'Solved');
      verifyCase(cases[4].Id, 'Closed â€“ Other', 'Solved');

   } // testPRFulfillmentUpdateStep
 
    // The the reference MMS object.
   static testMethod void testRefMMSUpdateStep() {
      
      CreateTestData.createTestAandC();
      Account a1 = [Select Id, Name from Account where name = 'Test Account1'];
      Contact ctct1 = [Select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First' and LastName = 

'Last1'];
      
      Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS,'Opportunity');
      Opportunity oppty1 = new Opportunity(Name='Test MMS Opporty', RecordTypeId=mmsOpptyRt.getRecordTypeId(),AccountId=a1.Id
                                         ,StageName='Qualified'
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId()
                                         ,LeadSource = 'Cold Call'
                                         ,Payroll_Current_Prior_Method__c = 'ADP');
                                         //,Primary_Competition__c = 'ADP Payforce');
      insert oppty1;
              
      Case c1 = createCase('Service Onboarding MMS Payroll Case');
      // link the account to the case
      c1.AccountId = a1.Id;
      c1.Opportunity__c = oppty1.Id;
      insert c1;
      
      Reference_MMS_Payroll__c ref1 = new Reference_MMS_Payroll__c (Case_Number__c = c1.Id,
                                                                    Date_Client_Load_Received__c = null,
                                                                    Current_Step__c = 'Case Creation',
                                                                    Opportunity_Name__c = oppty1.Id);
      insert ref1;
      
      // change step, verify step changes on Case
      ref1.Current_Step__c = '(1 of 5) Client Load Received';
      ref1.Date_Client_Load_Received__c = System.today();
      update ref1;
      
      //verify case
      verifyCase(c1.Id, '(1 of 5) Client Load Received', null);
      
      /* verify opty **removing call to change status check
      Opportunity mmsOpty = [Select Id, StageName, RecordTypeId from Opportunity where id = :oppty1.Id];
      System.assertEquals(mmsOpty.StageName, 'Sold-Submitted');
      Schema.RecordTypeInfo mmsdsaOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS_DSA,'Opportunity');
      System.assertEquals(mmsOpty.RecordTypeId, mmsdsaOpptyRt.getRecordTypeId());
    
      verify opty again
      ref1.First_Payroll_has_Run__c = true;
      */
    update ref1;
      //mmsOpty = [Select Id, StageName, RecordTypeId from Opportunity where id = :oppty1.Id];
      //System.assertEquals(mmsOpty.StageName, 'Sold - Started');

   } // testRefMMSUpdateStep 
     //APR015314 changed record type: BeneTrac Onboarding' to 'Benefits Administration Onboarding'
   static testMethod void testBeneTracUpdateStep() {
      Case c1 = createCase('Benefits Administration Onboarding');
      insert c1;
      
      // verify reference object was created.
      Reference_BeneTrac_Onboarding__c ref1 = new Reference_BeneTrac_Onboarding__c(Case_Number__c = c1.Id, Current_Step__c = 'New');
      insert ref1;
          
      // change step, verify step changes on Case
      ref1.Current_Step__c = '(1 of 9) BIO Requested';
      update ref1;

      // verify case
      verifyCase(c1.Id, '(1 of 9) BIO Requested', null);
      
   } // testBeneTracUpdateStep

  static testMethod void testPEONoStartUpdateStatus() {
      List<Case> cases = new List<Case>();
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('Service Support PEO No Start', 'Case');

      // create a case
      cases.add(new Case(RecordTypeId=rt.getRecordTypeId(),Origin='Product Maintenance'));
      insert cases;
      
      // PEO No Start record types are using new (dynamic) code - manually create reference objects 
      Reference_PEO_No_Start__c[] newRefs = new Reference_PEO_No_Start__c[]{};
      newRefs.add(new Reference_PEO_No_Start__c(Salesforce_Case__c=cases[0].Id));
      insert newRefs;
      
      List<Reference_PEO_No_Start__c> refs = new List<Reference_PEO_No_Start__c>();
      // verify reference objects were created.
      refs.add([Select Id, Status__c from Reference_PEO_No_Start__c where Salesforce_Case__c = :cases[0].Id]);              
      
      // change Status, verify Status changes on Case
      refs[0].Status__c = 'Completed';
         
      update refs;
      
      // verify cases
      System.assertEquals(cases[0].Status,null);
                        
   } // testPEONoStartUpdateStatus
   
   static testMethod void testRefIncomingFunds(){
      Id currUser = UserInfo.getUserId();
      User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND Id !=:currUser AND IsActive = true LIMIT 1];
      Case c1 = createCase('401k/S125 Operations Support');
      c1.OwnerId = currUser;
      c1.Subject = 'HRS 4S LDPS Checks';
      Case c2 = createCase('401k/S125 Operations Support');
      c2.OwnerId = currUser;
      c2.Subject = 'HRS 4S CAM Checks and ACH';
      Case c3 = createCase('401k/S125 Operations Support');
      c3.OwnerId = currUser;
      c3.Subject = 'HRS 4S CAM Trade Import';
      Case c4 = createCase('401k/S125 Operations Support');
      c4.OwnerId = currUser;
      c4.Subject = 'HRS 4S LDPS ROE V&R';
      Case c5 = createCase('401k/S125 Operations Support');
      c5.OwnerId = currUser;
      c5.Subject = 'HRS 4S CAT ACH';
      Case c6 = createCase('401k/S125 Operations Support');
      c6.OwnerId = currUser;
      c6.Subject = 'CAM Specialist';
      
      List<Case> cases = new List<Case>();
      cases.add(c1);
      cases.add(c2);
      cases.add(c3);
      cases.add(c4);
      cases.add(c5);
      cases.add(c6);
      insert cases;
      
      Reference_401k_S125__c reference = new Reference_401k_S125__c(Case_Lookup__c=c3.id);
      insert reference;
      
      Reference_Incoming_Funds__c ref1 = new Reference_Incoming_Funds__c(Case_Lookup__c = c1.Id,OwnerId = currUser);
      Reference_Incoming_Funds__c ref2 = new Reference_Incoming_Funds__c(Case_Lookup__c = c2.Id,OwnerId = currUser);
      Reference_Incoming_Funds__c ref3 = new Reference_Incoming_Funds__c(Case_Lookup__c = c3.Id,OwnerId = currUser,Conversions_Reference__c=reference.id);
      Reference_Incoming_Funds__c ref4 = new Reference_Incoming_Funds__c(Case_Lookup__c = c4.Id,OwnerId = currUser);
      Reference_Incoming_Funds__c ref5 = new Reference_Incoming_Funds__c(Case_Lookup__c = c5.Id,OwnerId = currUser);
      Reference_Incoming_Funds__c ref6 = new Reference_Incoming_Funds__c(Case_Lookup__c = c6.Id,OwnerId = currUser);
      
      List<Reference_Incoming_Funds__c> refs = new List<Reference_Incoming_Funds__c>();
      refs.add(ref1);
      refs.add(ref2);
      refs.add(ref3);
      refs.add(ref4);
      refs.add(ref5);
      refs.add(ref6);
      insert refs;
      
      HRS_4S_Clt_Support_Discrepancy__c disc = new HRS_4S_Clt_Support_Discrepancy__c(Reference_Incoming_Funds__c=ref1.Id,OwnerId = currUser);
      insert disc;
      
      Group g1 = [SELECT Id,Name FROM Group Where Name = 'HRS 4S LDPS Checks'];
      Group g2 = [SELECT Id,Name FROM Group Where Name = 'HRS 4S CAM Checks and ACH'];
      Group g3 = [SELECT Id,Name FROM Group Where Name = 'HRS 4S CAM Trade Import'];
      Group g4 = [SELECT Id,Name FROM Group Where Name = 'HRS 4S LDPS ROE V&R'];
      Group g5 = [SELECT Id,Name FROM Group Where Name = 'HRS 4S CAT ACH'];
      
      Test.startTest();
         
      ref1.Check_Type__c = 'Misc Check';
      ref1.RC1_Posted__c = date.today();
      ref1.Check_Amount__c = 3.00;
      ref1.Check_Payable_To__c='me';
      ref1.Address__c='Client';
      ref1.Contribution_Type__c = 'Rollover' ; 	
      ref1.Broker_Email__c = 'abc@Paycheck.com';
       
      ref2.Check_Type__c = '';
      ref2.Transmission_Method__c='Chase 401k';
      ref2.Ready_For_Trade__c=date.today();
      ref2.Contribution_Type__c='Branch Funding';
      ref2.Broker_Email__c = 'abc@Paycheck.com';
       
      ref3.Transmission_Method__c='Chase 401k';
      ref3.Ready_For_Trade__c=date.today();
      ref3.Contribution_Type__c='Conversion';
      ref3.Broker_Email__c = 'abc@Paycheck.com';
      
      ref4.Check_Type__c='ROE';
      ref4.Contribution_Type__c='';
      ref4.RC1_Posted__c=date.today();
      ref4.Broker_Email__c = 'abc@Paycheck.com';
      
      ref5.Check_Type__c = '';
      ref5.ACH_Type__c = 'Need CAT Approval';
      ref5.ACH_Entered_by_CAM__c =date.today();
      ref5.Broker_Email__c = 'abc@Paycheck.com';
       
      ref6.Transmission_Method__c='ACH 401k';
      ref6.ACH_Approved_Date__c=date.today();
      ref6.CAM_Specialist__c=admin.Id;
      ref6.Broker_Email__c = 'abc@Paycheck.com';
      
      update refs;
            
      Case ca1 = [SELECT Id,OwnerId FROM Case WHERE Id = :c1.Id];
      system.assertEquals(g1.Id,ca1.OwnerId);
      Case ca2 = [SELECT Id,OwnerId FROM Case WHERE Id = :c2.Id];
      system.assertEquals(g2.Id,ca2.OwnerId);
      Case ca3 = [SELECT Id,OwnerId FROM Case WHERE Id = :c3.Id];
      system.assertEquals(g3.Id,ca3.OwnerId);
      Case ca4 = [SELECT Id,OwnerId FROM Case WHERE Id = :c4.Id];
      system.assertEquals(g4.Id,ca4.OwnerId);
      Case ca5 = [SELECT Id,OwnerId FROM Case WHERE Id = :c5.Id];
      system.assertEquals(g5.Id,ca5.OwnerId);
      Case ca6 = [SELECT Id,OwnerId FROM Case WHERE Id = :c6.Id];
      system.assertEquals(admin.Id,ca6.OwnerId);

      //there was a discrepancy inserted with no resolution date, so the current step should be Open Discrepancy
      verifyCase(c1.Id, 'Open Discrepancy', 'Unresolved Research');
          
      //update the discrepancy resolution date so we can modify the current step
      disc.Resolution_Date__c = date.today();
      update disc;
      ref1.Current_Step__c = 'In Process';
      update ref1;
      verifyCase(c1.Id, 'In Process','New');

      Test.stopTest();
   }

   
    private static Case createCase(String recordTypeName) {
       Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(recordTypeName, 'Case');
       Case c = new Case(RecordTypeId=rt.getRecordTypeId());
       c.HRS4SCategory1__c ='Billing 401k';
       return c;
    } // createCase
   
   /** Verify the current step and status.
    */
   private static void verifyCase(Id caseId, String step, String status) {
      System.debug('verifying step='+step+' status='+status);
      Case c = [select Id, Current_Step__c, Status, RecordTypeId from case where Id = :caseId];
      verifyCase(c,step,status);
   } // verifyCase

   private static void verifyCase(Case c, String step, String status) {
      System.assertEquals(step,c.Current_Step__c);
      if (status != null) {
         System.assertEquals(status,c.Status);
      }
   } // verifyCase

   static testMethod void testSTMCaseCreate() {
      Case c1 = createCase('Service Onboarding STM Record Type');
      insert c1;
      
      //create Reference TAA object
      Reference_TAA__c refTAA = new Reference_TAA__c(Case_Lookup__c = c1.id);
      insert refTAA;
      
/*
      //Check the Client Graduated box
       refTAA.Client_Graduated__c = true;
      update refTAA;
      
      // verify case
      verifyCase(c1.Id, 'Client Graduated', 'Solved');   */  
      
      // verify new case was created
     /* Case c2 = [Select Id, RecordType.Name, Status, Product__c, Call_Out_Required__c from case where ParentId=:c1.Id];
      System.assertEquals('Service Support STM Case',c2.RecordType.Name);
      System.assertEquals('STM',c2.Product__c);
      System.assertEquals('Yes',c2.Call_Out_Required__c);
      System.assertEquals('New',c2.Status);*/
      
  
   } //end testSTMCaseCreate
   
   @isTest
    static void testAssignToAorFlockQueueOnInsert() {
        List<Reference_HNBF__c> referenceRecordsToInsert = new List<Reference_HNBF__c>();
        Reference_HNBF__c referenceHnbfForNewCaseQueue = new Reference_HNBF__c();
        referenceHnbfForNewCaseQueue.Current_Step__c = 'Sent to Payroll Integration';
        referenceHnbfForNewCaseQueue.Submission_type__c = SDA_FLOCK_PL_VALUE;
        referenceRecordsToInsert.add(referenceHnbfForNewCaseQueue);
        
        Reference_HNBF__c referenceHnbfForPayrollQueue = new Reference_HNBF__c();
        referenceHnbfForPayrollQueue.Current_Step__c = 'Sent to Payroll Integration';
        referenceHnbfForPayrollQueue.Submission_type__c = AOR_FLOCK_PL_VALUE;
        referenceRecordsToInsert.add(referenceHnbfForPayrollQueue);
        
        Test.startTest();
        INSERT referenceRecordsToInsert;
        Test.stopTest();
        
        Group aorPayrollQueue = [SELECT Id from Group WHERE Name = :AOR_PAYROLL_QUEUE_NAME AND Type = 'Queue' LIMIT 1];
        Group newCasePayrollQueue = [SELECT Id from Group WHERE Name = :NEW_CASE_PAYROLL_QUEUE_NAME AND Type = 'Queue' LIMIT 1];
        // verify update step and owner
        referenceHnbfForPayrollQueue = [SELECT ID, Current_step__c, ownerId FROM Reference_HNBF__c WHERE id = :referenceHnbfForPayrollQueue.Id];
        referenceHnbfForNewCaseQueue = [SELECT ID, Current_step__c, ownerId FROM Reference_HNBF__c WHERE id = :referenceHnbfForNewCaseQueue.Id];
        
        String expectedStatusForUpdate = 'NC Processing: Payroll Integration';
        
        Assert.areEqual(referenceHnbfForNewCaseQueue.Current_Step__c, expectedStatusForUpdate, 'Current step not updated for Reference_HNBF__c');
        Assert.areEqual(referenceHnbfForPayrollQueue.Current_Step__c, expectedStatusForUpdate, 'Current step not updated for Reference_HNBF__c');
        Assert.areEqual(referenceHnbfForNewCaseQueue.OwnerId, newCasePayrollQueue.Id, 'Owner not updated to be ' + NEW_CASE_PAYROLL_QUEUE_NAME + ' queue');
        Assert.areEqual(referenceHnbfForPayrollQueue.OwnerId, aorPayrollQueue.Id, 'Owner not updated to be ' + AOR_PAYROLL_QUEUE_NAME + ' queue');
    }
    
} // class ReferenceUpdateCaseTest/*