/*
* Tests for CommunityWorkersCompController methods
* 
* History
* ----------------------------------------
* 08/23/2021	Ahmed	Elawad		Created
*/ 

@isTest
public class CommunityWorkersCompControllerTest {
    
    // Setup requires insertion of various records for testing.
    @testSetup
    Static void setupData() {
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='12345');
        insert acctA;
        
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctA.Id, Medical_Benefits_Underwriting_Reques_del__c='Yes',
                                                                                Peo_401k_formStatus__c='', Peo_EPLI_formStatus__c='',Peo_Covid_formStatus__c='',Peo_WC_formStatus__c='');
        insert checklist;
        
        PEO_Onboarding_Medical_Questionnaire__c medFormA = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=checklist.Id);
        insert medFormA;
    }
    
    // Test for savePeoOnboardingChecklist
    static testMethod void savePeoOnboardingChecklistTest(){
        Account parentAcc = [SELECT Id, Name FROM Account WHERE name='ParentTestAccountCommunities' LIMIT 1];
        PEO_Onboarding_Checklist__c peoOnbChecklist = [SELECT ID, Peo_401k_formStatus__c, Peo_EPLI_formStatus__c, Peo_Covid_formStatus__c,
                                                       Peo_WC_formStatus__c, Peo_401k_SubmissionTime__c, Peo_EPLI_SubmissionTime__c,
                                                       Peo_Covid_formSubmissionTime__c, Peo_WC_SubmissionTime__c, Peo_Medical_formStatus__c
                                                       FROM PEO_Onboarding_Checklist__c
                                                       WHERE Prospect_Client__c=:parentAcc.Id];
        peoOnbChecklist.Peo_401k_formStatus__c = 'Complete';
        peoOnbChecklist.Peo_EPLI_formStatus__c = 'Complete';
        peoOnbChecklist.Peo_Covid_formStatus__c = 'Complete';
        peoOnbChecklist.Peo_WC_formStatus__c = 'Complete';
        
        
        Test.startTest();
        CommunityWorkersCompController.savePeoOnboardingChecklist(peoOnbChecklist, '');
        Test.stopTest();
        
        PEO_Onboarding_Checklist__c updatedCheclist = [SELECT ID, Peo_401k_formStatus__c, Peo_EPLI_formStatus__c, Peo_Covid_formStatus__c,
                                                       Peo_WC_formStatus__c, Peo_401k_SubmissionTime__c, Peo_EPLI_SubmissionTime__c,
                                                       Peo_Covid_formSubmissionTime__c, Peo_WC_SubmissionTime__c, Peo_Medical_formStatus__c
                                                       FROM PEO_Onboarding_Checklist__c
                                                       WHERE Prospect_Client__c=:parentAcc.Id];
        
        System.assertEquals(updatedCheclist.Peo_401k_formStatus__c, 'Complete', 'updatedCheclist status Peo_401k_formStatus__c not updated');
        System.assertEquals(updatedCheclist.Peo_EPLI_formStatus__c, 'Complete', 'updatedCheclist status Peo_EPLI_formStatus__c not updated');
        System.assertEquals(updatedCheclist.Peo_Covid_formStatus__c, 'Complete', 'updatedCheclist status Peo_Covid_formStatus__c not updated');
        System.assertEquals(updatedCheclist.Peo_WC_formStatus__c, 'Complete', 'updatedCheclist status Peo_WC_formStatus__c not updated');
        System.assertNotEquals(updatedCheclist.Peo_401k_SubmissionTime__c,null, 'Failed to update Peo_401k_SubmissionTime__c');
        System.assertNotEquals(updatedCheclist.Peo_EPLI_SubmissionTime__c,null, 'Failed to update Peo_EPLI_SubmissionTime__c');
        System.assertNotEquals(updatedCheclist.Peo_Covid_formSubmissionTime__c,null, 'Failed to update Peo_Covid_formSubmissionTime__c');
        System.assertNotEquals(updatedCheclist.Peo_WC_SubmissionTime__c,null, 'Failed to update Peo_WC_SubmissionTime__c');
    }
    
}