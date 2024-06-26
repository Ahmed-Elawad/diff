/**
 * The test methods for the ReferencePACBefore & ReferencePACAfter triggers, and the ReferencePACHelper class.
 *
 * History
 * ------- 
 * 10/29/2017 Frank Lurz    Created 
   09/11/2019 Dan Carmen    Bulkify Test class
  * 
 */
  @isTest(SeeAllData=false)
 private class ReferencePACHelperTest {
     static testMethod void myUnitTest() {
    
        //List<Reference_PAC_Queues__c> rpqList = new List<Reference_PAC_Queues__c>();
        //Reference_PAC_Queues__c rpq = new Reference_PAC_Queues__c(Name='Prod01',Queue_ID__c='PAY');
        //rpqList.add(rpq);
    
        //create a test User
        User testUser = new user(ID = UserInfo.getUserID());
        
        //create a test Contact
        Contact testPayrollSpec = new Contact(FirstName = 'Jane', LastName = 'Doe', Title = 'Senior Payroll Specialist');
        
        //CreateTestData.createTestAandC();
        Account testAccount01 = new Account (name = 'Test Account01'
                                ,Federal_ID_Number__c = '12-3456789'
                                ,AccountNumber = '11-1234ABCD'
                                ,Paychex_Payroll_Specialist__c = testPayrollSpec.Id
                                );
        insert testAccount01;
        system.debug('FRL after insert of testAccount01 -- testAccount01.Payroll_Branch_Nbr__c = ' + testAccount01.Payroll_Branch_Nbr__c);
        testAccount01.Bank_Region_Name__c = 'Bank Region Name'; 
        update testAccount01;    
        system.debug('FRL after update of testAccount01 -- testAccount01.Payroll_Branch_Nbr__c = ' + testAccount01.Payroll_Branch_Nbr__c);
        
        //create test Account Team member
        AccountTeamMember atm = new AccountTeamMember(AccountId=testAccount01.Id, UserId=testUser.Id, TeamMemberRole='Relationship Manager');
        insert atm;

        //create Client Field Submission records
        Client_Field_Submission__c testCFS01 = new Client_Field_Submission__c (Business_Name__c = 'Test CFS01'
                                               ,Federal_ID_Number_Submitted__c = '123456789'
                                               ,Paychex_Client_ID__c = '11-1234ABCD'
                                               ,Government_Tax_Agency__c = 'SSA - Social Security Administration'
                                               ,Tax_Form__c =  'Department of Income/Withholding Tax' 
                                               ,Notice_Type__c = 'Overpayment Issue'
                                               ,Submitters_Name__c = 'Joey Paychex'
                                               ,Email__c = 'test@paychex.com'
                                               ,Phone_Number__c = '5855552150'
                                               ,Main_Contact__c = true
                                               );
        //insert testCFS01;
        
        Client_Field_Submission__c testCFS02 = new Client_Field_Submission__c (Business_Name__c = 'Test CFS01'
                                               ,Federal_ID_Number_Submitted__c = '123456789'
                                               ,Paychex_Client_ID__c = '11-1234ABCD'
                                               ,Government_Tax_Agency__c = 'IRS - INTERNAL REVENUE SERVICE'
                                               ,Tax_Form__c =  'Department of Revenue' 
                                               ,Notice_Type__c = 'Overpayment Issue'
                                               ,Submitters_Name__c = 'Joe Test'
                                               ,Email__c = 'test@test.com'
                                               ,Phone_Number__c = '5855552150'
                                               ,Main_Contact__c = false
                                               ,Main_Contact_Name__c = 'Joe Test'
                                               ,Main_Contact_Email__c = 'test@testing.com'
                                               ,Main_Contact_Phone_Number__c = '5855552150'
                                               ,Main_Contact_Fax_Number__c = '5855552151'
                                               ,Additional_Notes__c = 'notes'
                                               );
        //insert testCFS02;        
        
        Client_Field_Submission__c testCFS03 = new Client_Field_Submission__c (Business_Name__c = 'Test CFS01'
                                               ,Federal_ID_Number_Submitted__c = '987654321'
                                               ,Government_Tax_Agency__c = 'AL - ALABAMA'
                                               ,Tax_Form__c =  'Department of Tax/Taxation/Finance' 
                                               ,Notice_Type__c = 'Overpayment Issue'
                                               ,Submitters_Name__c = 'Joe Test'
                                               ,Email__c = 'test@test.com'
                                               ,Phone_Number__c = '5855552150'
                                               ,Main_Contact__c = true
                                               );
         Client_Field_Submission__c[] CFSs = new Client_Field_Submission__c[]{testCFS01,testCFS02,testCFS03};
         insert CFSs;
        //insert testCFS03;        
        

        
        // add an attachment to the CFS record
        Attachment Att01 = new Attachment(parentid = testCFS01.id, Name='Unit Test 1', Description='Unit Test 1', Body=Blob.valueOf('Unit Test 1') );
        insert Att01;


        testCFS01.Submission_Done__c = TRUE; 
        testCFS02.Submission_Done__c = TRUE; 
        testCFS03.Submission_Done__c = TRUE;
        update CFSs;
        
        testCFS01.Submission_Date__c = System.now(); 
        testCFS02.Submission_Date__c = System.now(); 
        testCFS03.Submission_Date__c = System.now(); 
        update CFSs;
         
     
        // create a case
        Case testCase01 = [Select Id, recordtypeid, accountid, TempOwnerID__c from Case where TempOwnerID__c = :testCFS01.id];
        System.assertequals(TRUE,testCase01.accountid == testAccount01.id);

        Case testCase02 = [Select Id, recordtypeid, accountid, TempOwnerID__c from Case where TempOwnerID__c = :testCFS02.id];
        System.assertequals(TRUE,testCase02.accountid == testAccount01.id);

        Case testCase03 = [Select Id, recordtypeid, accountid, TempOwnerID__c from Case where TempOwnerID__c = :testCFS03.id];
        System.assertequals(FALSE,testCase03.accountid == testAccount01.id);

        
        //Reference_PAC__c testPAC01 = [Select Id, recordtypeid, ClientFieldSubmissionId__c from Reference_PAC__c where ClientFieldSubmissionId__c = :testCFS01.id]; 
        //Reference_PAC__c testPAC01 = [Select Id, recordtypeid, ClientFieldSubmissionId__c from Reference_PAC__c where ClientFieldSubmissionId__c != NULL limit 1];
        //Reference_PAC__c testPAC01 = [Select Id, recordtypeid, ClientFieldSubmissionId__c from Reference_PAC__c where Salesforce_Case__c = :testCase01.id];
        Reference_PAC__c testPAC01 = new Reference_PAC__c (Salesforce_Case__c = testCase01.id
                                                  ,ClientFieldSubmissionId__c = testCase01.TempOwnerID__c
                                                                   ,Status__c = 'Pending PAC Review - New Notice Received'
                                                                     ,Ownerid = UserInfo.getUserID()
                                                           ,Account_Lookup__c = testAccount01.Id
                                               );
        //insert testPAC01;


        Reference_PAC__c testPAC02 = new Reference_PAC__c (Salesforce_Case__c = testCase02.id
                                                  ,ClientFieldSubmissionId__c = testCase02.TempOwnerID__c
                                                                   ,Status__c = 'Pending PAC Review - New Notice Received'
                                                                   ,Ownerid = UserInfo.getUserID()
                                               );
        //insert testPAC02;

        Reference_PAC__c testPAC03 = new Reference_PAC__c (Salesforce_Case__c = testCase03.id
                                                  ,ClientFieldSubmissionId__c = testCase03.TempOwnerID__c
                                                                   ,Status__c = 'Pending PAC Review - New Notice Received'
                                                                   ,Ownerid = UserInfo.getUserID()
                                               );
         Reference_PAC__c[] refPacs = new Reference_PAC__c[]{testPAC01,testPAC02,testPAC03};
         insert refPacs;
        //insert testPAC03;



     
     } // myUnitTest
     

     static testMethod void myUnitTest2() {
    
        //List<Reference_PAC_Queues__c> rpqList = new List<Reference_PAC_Queues__c>();
        //Reference_PAC_Queues__c rpq = new Reference_PAC_Queues__c(Name='Prod01',Queue_ID__c='PAY');
        //rpqList.add(rpq);
    
        //create a test User
        User testUser = new user(ID = UserInfo.getUserID());
        
        //CreateTestData.createTestAandC();
        Account testAccount01 = new Account (name = 'Test Account01'
                                ,Federal_ID_Number__c = '12-3456789'
                                ,AccountNumber = '11-1234ABCD'
                                );
        insert testAccount01;
        
       Client_Field_Submission__c testCFS04 = new Client_Field_Submission__c (Business_Name__c = 'Test CFS01'
                                               ,Federal_ID_Number_Submitted__c = '987654321'
                                               ,Government_Tax_Agency__c = 'AL - ALABAMA'
                                               ,Tax_Form__c =  'Department of Unemployment Assistance/Insurance' 
                                               ,Notice_Type__c = 'Overpayment Issue'
                                               ,Submitters_Name__c = 'Joe Test'
                                               ,Email__c = 'test@test.com'
                                               ,Phone_Number__c = '5855552150'
                                               ,Main_Contact__c = true
                                               );
        //insert testCFS04;  
        
        
        Client_Field_Submission__c testCFS05 = new Client_Field_Submission__c (Business_Name__c = 'Test CFS01'
                                               ,Federal_ID_Number_Submitted__c = '987654321'
                                               ,Government_Tax_Agency__c = 'AL - ALABAMA'
                                               ,Tax_Form__c =  'Department of Jobs/Training/Workforce' 
                                               ,Notice_Type__c = 'Overpayment Issue'
                                               ,Submitters_Name__c = 'Joe Test'
                                               ,Email__c = 'test@test.com'
                                               ,Phone_Number__c = '5855552150'
                                               ,Main_Contact__c = true
                                               );
        //insert testCFS05;  


        Client_Field_Submission__c testCFS06 = new Client_Field_Submission__c (Business_Name__c = 'Test CFS01'
                                               ,Federal_ID_Number_Submitted__c = '987654321'
                                               ,Government_Tax_Agency__c = 'AL - ALABAMA'
                                               ,Tax_Form__c =  'Department of Labor/Industries/Employment Services' 
                                               ,Notice_Type__c = 'Overpayment Issue'
                                               ,Submitters_Name__c = 'Joe Test'
                                               ,Email__c = 'test@test.com'
                                               ,Phone_Number__c = '5855552150'
                                               ,Main_Contact__c = true
                                               );
        //insert testCFS06;  

        Client_Field_Submission__c testCFS07 = new Client_Field_Submission__c (Business_Name__c = 'Test CFS01'
                                               ,Federal_ID_Number_Submitted__c = '987654321'
                                               ,Government_Tax_Agency__c = 'AL - ALABAMA'
                                               ,Tax_Form__c =  'Other' 
                                               ,Notice_Type__c = 'Overpayment Issue'
                                               ,Submitters_Name__c = 'Joe Test'
                                               ,Email__c = 'test@test.com'
                                               ,Phone_Number__c = '5855552150'
                                               ,Main_Contact__c = true
                                               );
        //insert testCFS07;                  

        Client_Field_Submission__c testCFS08 = new Client_Field_Submission__c (Business_Name__c = 'Test CFS01'
                                               ,Federal_ID_Number_Submitted__c = '987654321'
                                               ,Government_Tax_Agency__c = 'AL - ALABAMA'
                                               ,Tax_Form__c =  'Department of Employer Tax/Employment Security' 
                                               ,Notice_Type__c = 'Overpayment Issue'
                                               ,Submitters_Name__c = 'Joe Test'
                                               ,Email__c = 'test@test.com'
                                               ,Phone_Number__c = '5855552150'
                                               ,Main_Contact__c = true
                                               );
        //insert testCFS08;                  

        Client_Field_Submission__c testCFS09 = new Client_Field_Submission__c (Business_Name__c = 'Test CFS01'
                                               ,Federal_ID_Number_Submitted__c = '987654321'
                                               ,Government_Tax_Agency__c = 'AL - ALABAMA'
                                               ,Tax_Form__c =  '1040 - Individual Income Tax' 
                                               ,Notice_Type__c = 'Overpayment Issue'
                                               ,Submitters_Name__c = 'Joe Test'
                                               ,Email__c = 'test@test.com'
                                               ,Phone_Number__c = '5855552150'
                                               ,Main_Contact__c = true
                                               );
        //insert testCFS09; 
         Client_Field_Submission__c[] CFSs = new Client_Field_Submission__c[]{testCFS04,testCFS05,testCFS06,testCFS07,testCFS08,testCFS09};
         insert CFSs;
     
        // add an attachment to the CFS record
        Attachment Att01 = new Attachment(parentid = testCFS04.id, Name='Unit Test 4', Description='Unit Test 4', Body=Blob.valueOf('Unit Test 4') );
        insert Att01;
     
        testCFS04.Submission_Done__c = TRUE; 
        testCFS05.Submission_Done__c = TRUE; 
        testCFS06.Submission_Done__c = TRUE; 
        testCFS07.Submission_Done__c = TRUE; 
        testCFS09.Submission_Done__c = TRUE; 
        update CFSs;

        testCFS04.Submission_Date__c = System.now(); 
        testCFS05.Submission_Date__c = System.now(); 
        testCFS06.Submission_Date__c = System.now(); 
        testCFS07.Submission_Date__c = System.now(); 
        testCFS09.Submission_Date__c = System.now(); 
        update CFSs;

        Case[] cases = [Select Id, recordtypeid, accountid, TempOwnerID__c from Case];
        Case testCase04 = null;
        Case testCase05 = null;
        Case testCase06 = null;
        Case testCase07 = null;
        Case testCase09 = null;
         for (Case cs : cases) {
             if (cs.TempOwnerID__c == testCFS04.id) {
                testCase04 = cs;
             } else if (cs.TempOwnerID__c == testCFS05.id) {
                testCase05 = cs;
             } else if (cs.TempOwnerID__c == testCFS06.id) {
                testCase06 = cs;
             } else if (cs.TempOwnerID__c == testCFS07.id) {
                testCase07 = cs;
             } else if (cs.TempOwnerID__c == testCFS09.id) {
                testCase09 = cs;
             }
         } // for (Case cs : cases
        
        //Case testCase04 = [Select Id, recordtypeid, accountid, TempOwnerID__c from Case where TempOwnerID__c = :testCFS04.id];
        //System.assertequals(true,testCase04.accountid == testAccount01.id);

        //Case testCase05 = [Select Id, recordtypeid, accountid, TempOwnerID__c from Case where TempOwnerID__c = :testCFS05.id];
        //System.assertequals(true,testCase05.accountid == testAccount01.id);

        //Case testCase06 = [Select Id, recordtypeid, accountid, TempOwnerID__c from Case where TempOwnerID__c = :testCFS06.id];
        //System.assertequals(true,testCase06.accountid == testAccount01.id);

        //Case testCase07 = [Select Id, recordtypeid, accountid, TempOwnerID__c from Case where TempOwnerID__c = :testCFS07.id];
        //System.assertequals(true,testCase07.accountid == testAccount01.id);
        
        //Case testCase09 = [Select Id, recordtypeid, accountid, TempOwnerID__c from Case where TempOwnerID__c = :testCFS09.id];
        //System.assertequals(true,testCase09.accountid == testAccount01.id);
        
        Reference_PAC__c testPAC04 = new Reference_PAC__c (Salesforce_Case__c = testCase04.id
                                                  ,ClientFieldSubmissionId__c = testCase04.TempOwnerID__c
                                                                   ,Status__c = 'Pending PAC Review - New Notice Received'
                                                                   ,Ownerid = UserInfo.getUserID()
                                               );
        //insert testPAC04;


        Reference_PAC__c testPAC05 = new Reference_PAC__c (Salesforce_Case__c = testCase05.id
                                                  ,ClientFieldSubmissionId__c = testCase05.TempOwnerID__c
                                                                   ,Status__c = 'Pending PAC Review - New Notice Received'
                                                                   ,Ownerid = UserInfo.getUserID()
                                               );
        //insert testPAC05;


        Reference_PAC__c testPAC06 = new Reference_PAC__c (Salesforce_Case__c = testCase06.id
                                                  ,ClientFieldSubmissionId__c = testCase06.TempOwnerID__c
                                                                   ,Status__c = 'Pending PAC Review - New Notice Received'
                                                                   ,Ownerid = UserInfo.getUserID()
                                               );
        //insert testPAC06;
        
        Reference_PAC__c testPAC07 = new Reference_PAC__c (Salesforce_Case__c = testCase07.id
                                                  ,ClientFieldSubmissionId__c = testCase07.TempOwnerID__c
                                                                   ,Status__c = 'Pending PAC Review - New Notice Received'
                                                                   ,Ownerid = UserInfo.getUserID()
                                               );
        //insert testPAC07;        
        //System.assertEquals('IRS - INTERNAL REVENUE SERVICE', testPAC01.Tax_Agency__c);
        //System.assertEquals(system.today(), testPAC01.Date_1st_Notice_Received_in_PAC__c);
        
        Reference_PAC__c testPAC09 = new Reference_PAC__c (Salesforce_Case__c = testCase09.id
                                                  ,ClientFieldSubmissionId__c = testCase09.TempOwnerID__c
                                                                   ,Status__c = 'Pending PAC Review - New Notice Received'
                                                                   ,Ownerid = UserInfo.getUserID()
                                               );
        //insert testPAC09;  
        Reference_PAC__c[] insertPacs = new Reference_PAC__c[]{testPAC04,testPAC05,testPAC06,testPAC07,testPAC09};
        insert insertPacs;
     } // myUnitTest02          
    
 } // ReferencePACHelperTest