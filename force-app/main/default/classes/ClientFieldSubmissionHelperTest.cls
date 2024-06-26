/**
 * The test methods for the ClientFieldSubmissionAfter trigger, and the ClientFieldSubmissionHelper class.
 *
 * History
 * ------- 
 * 10/29/2017 Frank Lurz    Created 
  * 
 */
  @isTest(SeeAllData=false)
 private class ClientFieldSubmissionHelperTest {
     static testMethod void myUnitTest() {
     
         
        Schema.RecordTypeInfo CaseRt = RecordTypeHelper.getRecordType('Service Support PAC Case', 'Case');
        Schema.RecordTypeInfo RefPACRt = RecordTypeHelper.getRecordType('Reference PAC Record Type', 'Reference_PAC__c');  
        
 
        //create Account and Contact records via the createTestAandC method in the CreateTestData test class
        CreateTestData.createTestAandC();
        Account testAccount1 = [select Id, Name, AccountNumber from Account where name = 'Test Account1'];
        testAccount1.Federal_ID_Number__c = '12-3456789';
        update testAccount1;
        
        Contact testContact1 = [select Id, Name, Email from Contact where AccountId = :testAccount1.Id and FirstName = 'First'];  
        Contact testContact2 = [select Id, Name, Email from Contact where AccountId = :testAccount1.Id and FirstName = 'Second'];



        //CreateTestData.createTestAandC();
        Account testAccount2 = new Account (name = 'Test Account2'
                                ,Federal_ID_Number__c = '12-3456788'
                                ,AccountNumber = '88-1234ABCE'
                                );
        insert testAccount2;
        

        //create Client Field Submission records
        Client_Field_Submission__c testCFS01 = new Client_Field_Submission__c (Business_Name__c = 'Test CFS01'
                                               ,Federal_ID_Number_Submitted__c = '123456789'
                                               ,Paychex_Client_ID__c = '88-1234ABCD'
                                               ,Government_Tax_Agency__c = 'SSA - Social Security Administration'
                                               ,Tax_Form__c =  'Department of Income/Withholding Tax' 
                                               ,Notice_Type__c = 'Overpayment Issue'
                                               ,Submitters_Name__c = 'Joe Test'
                                               ,Email__c = 'test@test.com'
                                               ,Phone_Number__c = '5855552150'
                                               ,Main_Contact__c = true
                                               );
        insert testCFS01;
        
        testCFS01.Submission_Date__c = System.now(); 
        update testCFS01;
        


        Client_Field_Submission__c testCFS02 = new Client_Field_Submission__c (Business_Name__c = 'Test CFS02'
                                               ,Federal_ID_Number_Submitted__c = '123456788'
                                               ,Paychex_Client_ID__c = '88-1234ABCE'
                                               ,Government_Tax_Agency__c = 'CO - COLORADO'
                                               ,Tax_Form__c =  'Department of Revenue' 
                                               ,Notice_Type__c = 'Overpayment Issue'
                                               ,Submitters_Name__c = 'Joe Test'
                                               ,Email__c = 'test@test.com'
                                               ,Phone_Number__c = '5855552151'
                                               ,Main_Contact__c = false
                                               ,Main_Contact_Name__c = 'Main Contact02'
                                               ,Main_Contact_Email__c = 'm02@test.com'
                                               ,Main_Contact_Phone_Number__c = '5854442151'
                                               ,Main_Contact_Fax_Number__c = '5853332151'
                                               );
        insert testCFS02;
        
        testCFS02.Submission_Date__c = System.now(); 
        update testCFS02;        
        
        // create a case
        //Case casePAC1 = new Case(AccountId=testAccount1.Id, ContactId=testContact1.Id, RecordTypeId=caseRt.getRecordTypeId());
        //insert casePAC1;
        
        Case testCase01 = [Select Id, recordtypeid, accountid, TempOwnerID__c from Case where TempOwnerID__c != NULL limit 1];
        System.assertequals(true,testCase01.accountid == testAccount1.id);

        Case testCase02 = [Select Id, recordtypeid, accountid, TempOwnerID__c from Case where TempOwnerID__c != NULL limit 1];
        System.assertequals(true,testCase02.accountid == testAccount1.id);

             
     } // myUnitTest
 } // ClientFieldSubmissionHelperTest