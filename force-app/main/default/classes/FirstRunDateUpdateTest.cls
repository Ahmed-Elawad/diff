/*

03/10/2015  Justin Henderson  Created
04/16/2015  Justin Henderson  Added new test method to test for No Update due to Current Step.
07/03/2023  Carrie Marciano Added criteria to testNoChange so process builder wouldnt reset current step

*/

@isTest(SeeAllData = False)
public class FirstRunDateUpdateTest {
    
    static testmethod void testDateChangeBasic(){
        Schema.RecordTypeInfo caseCorert = RecordTypeHelper.getRecordType('Service Onboarding Core Payroll Case', 'Case');
        CreateTestData.createTestAandC();
        Account acct1 = [Select Id, First_Run_Date__c,(Select Id from Contacts limit 1) from Account where createddate = Today limit 1];
        Case c1 = new Case (AccountId = acct1.Id, 
                            ContactID = acct1.Contacts[0].Id,
                            Subject = 'Test',
                            RecordTypeID = caseCorert.getRecordTypeId());
        
        insert c1;
                   
        acct1.First_Run_Date__c = date.Today();
        update acct1;
        
        Reference_Core_Payroll__c ref1 = [Select Id, Payroll_Run_Date__c from Reference_Core_Payroll__c where Case_Lookup__c =: c1.Id];
        
        system.assertEquals(system.today(), ref1.Payroll_Run_Date__c);
        
    }

   static testmethod void testNoChange(){
        Schema.RecordTypeInfo caseCorert = RecordTypeHelper.getRecordType('Service Onboarding Core Payroll Case', 'Case');
        CreateTestData.createTestAandC();
        Account acct1 = [Select Id, First_Run_Date__c,(Select Id from Contacts limit 1) from Account where createddate = Today limit 1];
        Case c1 = new Case (AccountId = acct1.Id, 
                            ContactID = acct1.Contacts[0].Id,
                            Subject = 'Test',
                            RecordTypeID = caseCorert.getRecordTypeId());
        
        insert c1;
       
        Reference_Core_Payroll__c ref1 = [Select Id, Current_Step__c, Payroll_Run_Date__c, Client_Load_Received__c, Date_IS_Assigned__c from Reference_Core_Payroll__c where Case_Lookup__c =: c1.Id];
        date r1date = ref1.Payroll_Run_Date__c;
        ref1.Current_Step__c = '(3 of 4) First Payroll Ran';
        ref1.Client_Load_Received__c = True;
        ref1.Date_IS_Assigned__c = date.Today();
                               
        update ref1;
       
        acct1.First_Run_Date__c = date.Today();
        update acct1;
        
        ref1 = [Select Id, Current_Step__c, Payroll_Run_Date__c from Reference_Core_Payroll__c where Case_Lookup__c =: c1.Id];
       
        system.assertEquals(r1date, ref1.Payroll_Run_Date__c);
        system.assertEquals('(3 of 4) First Payroll Ran', ref1.Current_Step__c);
        
    }
}