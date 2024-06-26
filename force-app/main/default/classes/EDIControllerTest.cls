/* 
 * History
 * -------
 * 01/11/2023 Pratik Das       Created
 * 12/27/2023 Shilpa G	       APR0149726: Onboarding Complete step with 'Back From New Case' custom label
 * 
*/

@isTest
public with sharing class EDIControllerTest {
    // public EDIControllerTest() {

    // }

    public static String objName='Reference_HNBF__c';
    public static String carrierConnectionEDI='Carrier Connection- EDI';
    public static String eni='ENI';
    public static String cobra='Cobra';
    public static String telehealth='Telehealth';
    public static String hoorayhealth='Hooray Health';

    @testSetup 
    static void setup(){

        //Create Account
        Account acct = new Account(Name='Test Acct');
        insert acct;
        //Create Case
        Case testCase = new Case();
        testCase.Status = 'New';
        testCase.Current_Step__c = 'Case Creation';
        testCase.Type = 'ACT';
        testCase.Description = 'TEST CLONE FUNCTION';
        testCase.accountid=acct.id;
        insert testCase;

        //Create Reference_HNBF__c
        Reference_HNBF__c testReference = new Reference_HNBF__C();
        testReference.Case_Number__c= testCase.Id;
        testReference.Submission_Type__c= 'New Case';
        testReference.Current_Step__c = 'Onboarding in Progress';
        insert testReference; 

        Reference_HNBF__c testReference1 = new Reference_HNBF__C();
        testReference1.Case_Number__c= testCase.Id;
        //testReference1.Submission_Type__c= 'New Case';
        testReference1.Current_Step__c = Label.AllowEDICaseCreation;
        testReference1.Flock__c=true;
        testReference1.Region__c='MA South East';
        testReference1.Current_Step_Details__c='Step1';
        testReference1.Cancel_Reason__c='Declined by Carrier';
        insert testReference1; 

        //Create Policy type
        Reference_HNBF_Policy_Type__c testPolicyType = new Reference_HNBF_Policy_Type__c();
        testPolicyType.Reference_HNBF__c = testReference1.Id;
        testPolicyType.Policy_Type__c = 'Dental';
        testPolicyType.AOR_Effective_Date__c = Date.today();
        testpolicyType.Policy_Effective_Date__c = Date.today();
        testpolicyType.Total_of_EE_s_Actively_Enrolled__c=10;
        insert testPolicyType;

        
    }

    @istest
    static void testfetchDropdownData(){
        List<Reference_HNBF__c> lstreferenceHNBF=[Select id from Reference_HNBF__c where Current_Step__c='Onboarding in Progress' limit 1];
        if(!lstreferenceHNBF.isEmpty()){
            test.starttest();
            EDIController.fetchDropdownData(lstreferenceHNBF[0].id,objName);
            EDIController.validateRecords(lstreferenceHNBF[0].id,objName,carrierConnectionEDI);
            EDIController.validateRecords(lstreferenceHNBF[0].id,objName,eni);
            EDIController.validateRecords(lstreferenceHNBF[0].id,objName,cobra);
            EDIController.validateRecords(lstreferenceHNBF[0].id,objName,telehealth);
            test.stoptest();
        }
    }

    @istest
    static void testvalidateRecords(){
        List<Reference_HNBF__c> lstreferenceHNBF=[Select id from Reference_HNBF__c where Current_Step__c=:Label.AllowEDICaseCreation limit 1];
        if(!lstreferenceHNBF.isEmpty()){
            test.starttest();
            EDIController.validateRecords(lstreferenceHNBF[0].id,objName,eni);
            test.stoptest();
        }
    }



}