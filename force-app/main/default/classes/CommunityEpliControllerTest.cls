/*
* Tests for CommunityEpliController methods
* 
* History
* ----------------------------------------
* 08/23/2021	Ahmed	Elawad		Created
*/

@isTest
public class CommunityEpliControllerTest {
    
    @isTest
    static void testConstructor() {
        CommunityEpliController controller = new CommunityEpliController();
        
        System.assertNotEquals(null, controller);
    }
    
    // Setup requires insertion of various records for testing: UW Medical record, PEO UW Checklist Record, Account Record
   /* @testSetup
    Static void setupData() {
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='12345');
        insert acctA;
        
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctA.Id, Medical_Benefits_Underwriting_Reques_del__c='Yes',
                                                                                Peo_401k_formStatus__c='', Peo_EPLI_formStatus__c='',Peo_Covid_formStatus__c='',Peo_WC_formStatus__c='');
        insert checklist;
        
        Policy_Period__c polPeriod = new Policy_Period__c(PEO_Onboarding_Checklist__c = checklist.Id);
        insert polPeriod;
        
        PEO_Onboarding_Medical_Questionnaire__c medFormA = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=checklist.Id);
        insert medFormA;
    }
    
    // tests to get an EPLI policy period
    static testMethod void testGetPolicyPeriods(){
    	Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        List<Policy_Period__c> polPeriods = CommunityEpliController.getEPLIPolicyPeriods(parentPeoOnbCheck.Id,'Test');
        
        System.assertEquals(1, polPeriods.size());
        delete polPeriods;
        List<Policy_Period__c> polPeriodsnew = CommunityEpliController.getEPLIPolicyPeriods(parentPeoOnbCheck.Id,'Test');
    }
    
    // tests to insert an EPLI policy period against a checklist
    static testMethod void testSavePolicyPeriods(){
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        List<Policy_Period__c> polPeriods = new List<Policy_Period__c>([SELECT Id, Name, Policy_Period__c, Insurance_Carrier__c, Premium__c, Limit__c, Deductible_Retention__c, 
                                                                        PEO_Onboarding_Checklist__c FROM Policy_Period__c WHERE PEO_Onboarding_Checklist__c = :parentPeoOnbCheck.Id]);
        
        polPeriods[0].Policy_Period__c = 'Testing Update';
        polPeriods = CommunityEpliController.saveEPLIPolicyPeriods(polPeriods,'Test');
        System.assertEquals(1, polPeriods.size());
        System.assertEquals('Testing Update', polPeriods[0].Policy_Period__c);
        
        polPeriods.add(new Policy_Period__c(PEO_Onboarding_Checklist__c = parentPeoOnbCheck.Id, Policy_Period__c = 'Testing New EPLI Pol Period'));
        polPeriods.remove(0);
        polPeriods = CommunityEpliController.saveEPLIPolicyPeriods(polPeriods,'Test');
        
        System.assertEquals(1, polPeriods.size());
        System.assertEquals('Testing New EPLI Pol Period', polPeriods[0].Policy_Period__c);
    }
    
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
        CommunityEpliController.savePeoOnboardingChecklist(peoOnbChecklist,'Test');
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
*/
}