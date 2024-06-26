/* 
* Test methods for CommunityAccountEditFormController.
*
* History
* -------
* 08/19/2021    Ahmed Elawad        Created
* 02/11/2022    Jake Hinds          Moving medical and isq status to checklistx
* 09/16/2022	Jidesh				Added method to test BLS methods
*/

@isTest
public class CommunityAccountEditFormControllerTest {
    
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
    
    // Test for saveThisAccountMethod
    static testMethod void saveThisAccountTest(){
        Account acc = [select id,NumberOfEmployees, Naics_Code__c, salesParent__c from Account where name ='ParentTestAccountCommunities'];
        String oldNaics = acc.Naics_Code__c;
        acc.Naics_Code__c = '1234567';
        Account retAcc = CommunityAccountEditFormController.saveThisAccount(acc,'Test');
        
        System.assertNotEquals(oldNaics, retAcc.NAICS_Code__c);
        System.assertEquals('1234567', retAcc.NAICS_Code__c);
    }
    
    // Test for savePeoOnboardingChecklist
    static testMethod void savePeoOnboardingChecklistTest(){
        Account parentAcc = [SELECT Id, Name FROM Account WHERE name='ParentTestAccountCommunities' LIMIT 1];
        PEO_Onboarding_Checklist__c peoOnbChecklist = [SELECT ID, Peo_401k_formStatus__c, Peo_EPLI_formStatus__c, Peo_Covid_formStatus__c,
                                                       Peo_WC_formStatus__c, Peo_401k_SubmissionTime__c, Peo_EPLI_SubmissionTime__c,
                                                       Peo_Covid_formSubmissionTime__c, Peo_WC_SubmissionTime__c,Peo_Medical_formSubmissionTime__c
                                                       FROM PEO_Onboarding_Checklist__c
                                                       WHERE Prospect_Client__c=:parentAcc.Id];
        peoOnbChecklist.Peo_401k_formStatus__c = 'Complete';
        peoOnbChecklist.Peo_EPLI_formStatus__c = 'Complete';
        peoOnbChecklist.Peo_Covid_formStatus__c = 'Complete';
        peoOnbChecklist.Peo_WC_formStatus__c = 'Complete';
        peoOnbChecklist.Peo_Medical_formStatus__c = 'Complete';
        peoOnbChecklist.Peo_IndSpecific_formStatus__c = 'Complete';
        
        
        Test.startTest();
        CommunityAccountEditFormController.savePeoOnboardingChecklist(peoOnbChecklist,'Test');
        Test.stopTest();
        
        PEO_Onboarding_Checklist__c updatedCheclist = [SELECT ID, Peo_401k_formStatus__c, Peo_EPLI_formStatus__c, Peo_Covid_formStatus__c,
                                                       Peo_WC_formStatus__c, Peo_401k_SubmissionTime__c, Peo_EPLI_SubmissionTime__c,
                                                       Peo_Covid_formSubmissionTime__c, Peo_WC_SubmissionTime__c,Peo_Medical_formSubmissionTime__c
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
    
    // test updating the medical questionnaire for a checklist
    @TestVisible static testMethod void saveMedicalQuestionnaireTest() {
        
        PEO_Onboarding_Medical_Questionnaire__c medForm;
        PEO_Onboarding_Medical_Questionnaire__c medFormWithoutCompleteStatus;
        PEO_Onboarding_Medical_Questionnaire__c medFormWithCompleteStatus;
        medForm = [SELECT Id, Group_cvrg_denied_past_three_yrs__c, info_Participant_under_treatment__c,
                   info_Substance_dependency__c FROM PEO_Onboarding_Medical_Questionnaire__c LIMIT 1];
        
        medForm.Group_cvrg_denied_past_three_yrs__c = 'Yes';
        medForm.info_Participant_under_treatment__c = 'Yes';
        medForm.info_Substance_dependency__c = 'Yes';
        
        Test.startTest();
        // Send two save requests. The first has a blank value for the medical form status so the submission time
        // should be blank. The second has a 'Complete' value for the form status so the submission time should be updated
        
        // send the first save.
        Boolean saveSucceded = CommunityAccountEditFormController.saveMedicalQuestionnaire(medForm,'Test');
        medFormWithoutCompleteStatus = [SELECT Id, Group_cvrg_denied_past_three_yrs__c, info_Participant_under_treatment__c,
                                        info_Substance_dependency__c
                                        FROM PEO_Onboarding_Medical_Questionnaire__c
                                        LIMIT 1];
        Test.stopTest();
        
        // test save requests
        System.assert(saveSucceded, 'Failed to save record with null status');
        // test checklist values
        System.assertEquals(medForm.Group_cvrg_denied_past_three_yrs__c,'Yes', 'Failed to update Group_cvrg_denied_past_three_yrs__c');
        System.assertEquals(medForm.info_Participant_under_treatment__c,'Yes', 'Failed to update info_Participant_under_treatment__c');
        System.assertEquals(medForm.info_Substance_dependency__c,'Yes', 'Failed to update info_Substance_dependency__c');

    }
    
    // test updating multiple medical questionnaires for a checklist
    @TestVisible static testMethod void saveMedicalQuestionnairesTest() {
        
        PEO_Onboarding_Medical_Questionnaire__c[] medForms;
        PEO_Onboarding_Medical_Questionnaire__c[] medFormsWithoutCompleteStatus;
        PEO_Onboarding_Medical_Questionnaire__c[] medFormsWithCompleteStatus;
        medForms = [SELECT Id, Group_cvrg_denied_past_three_yrs__c, info_Participant_under_treatment__c,
                   info_Substance_dependency__c
                   FROM PEO_Onboarding_Medical_Questionnaire__c ];
        for (PEO_Onboarding_Medical_Questionnaire__c rec : medForms) {
            rec.Group_cvrg_denied_past_three_yrs__c = 'Yes';
            rec.info_Participant_under_treatment__c = 'Yes';
            rec.info_Substance_dependency__c = 'Yes';
        }
        
        Test.startTest();
        // Send two save requests. The first has a blank value for the medical form status so the submission time
        // should be blank. The second has a 'Complete' value for the form status so the submission time should be updated
        
        // send the first save.
        Boolean saveSucceded = CommunityAccountEditFormController.saveMedicalQuestionnaires(medForms,'Test');
        medFormsWithoutCompleteStatus = [SELECT Id, Group_cvrg_denied_past_three_yrs__c, info_Participant_under_treatment__c,
                                        info_Substance_dependency__c
                                        FROM PEO_Onboarding_Medical_Questionnaire__c ];

        Test.stopTest();
        
        // test save requests
        System.assert(saveSucceded, 'Failed to save record with null status');
        // test checklist values
        PEO_Onboarding_Medical_Questionnaire__c formWithoutUdpatedField;
        for (PEO_Onboarding_Medical_Questionnaire__c rec : medFormsWithoutCompleteStatus) {
            if (rec.Group_cvrg_denied_past_three_yrs__c != 'Yes' || rec.info_Participant_under_treatment__c != 'Yes' || rec.info_Substance_dependency__c != 'Yes') {
                formWithoutUdpatedField = rec;
                break;
            }
        }
    }
    
    static testMethod void GetPEOOnboardingChecklistTest(){
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c 
                                                         FROM PEO_Onboarding_Checklist__c 
                                                         WHERE Prospect_Client__c = :parentAcct.Id];
        
        PEO_Onboarding_Checklist__c peoOnbCheck = CommunityAccountEditFormController.getPEOOnboardingChecklist(parentAcct.Id, null,'Test');
        
        System.assertEquals(parentPeoOnbCheck.Id, peoOnbCheck.Id);
    }
    
    static testMethod void getselectOptionsTest() {
        Map<String, String> res = CommunityAccountEditFormController.getSelectOptions('Test');
        System.debug('Res: '+ res);
        System.assertEquals(res.isEmpty(), false);
        System.assertEquals(res.size(), 54, 'Returned state map is too ' + (res.size() < 54 ? 'small' : 'large'));
    }
    
    static testMethod void testBlsMethods(){
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', AccountNumber = '8-00081234', NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='561720');
        insert acctA;
        Contact ctct = new Contact(FirstName='test',LastName='test',AccountId=acctA.Id,email='test@test.test');  
        insert ctct;
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctA.Id, Medical_Benefits_Underwriting_Reques_del__c='Yes',
                                                                               Peo_401k_formStatus__c='', Peo_EPLI_formStatus__c='',Peo_Covid_formStatus__c='',Peo_WC_formStatus__c='');
        insert checklist;
        Profile prof = [SELECT Id FROM Profile where name='Customer Community Login User Clone'];
        User u1 = new User(
            UserName = 'testOppCommUser1@test.testtesttest',
            FirstName = 'Test',
            LastName = 'Test',
            Alias = 'tOPPest',
            email = 'testOppCommUser1@test.com',
            ContactId = ctct.Id,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'tesOP2343Pt',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'Community');
        User[] users = new User[]{u1};
            insert users;
        BLS_Med_Partcptn__c blsMedData = new BLS_Med_Partcptn__c();
        blsMedData.Name = 'Default';
        blsMedData.Prefix__c = 'NB';
        blsMedData.datatype_code__c ='26';
        blsMedData.estimate_code__c = '15';
        blsMedData.industry_code__c = '0000';
        blsMedData.ocupational_code__c = '000000';
        blsMedData.ownership_code__c = '2';
        blsMedData.provision_code__c = '179';
        blsMedData.seasonal__c = 'U';
        blsMedData.subcell_code__c = '00';
        Insert blsMedData;
        
        BLS_Average_Wage__c blsAvgWageData = new BLS_Average_Wage__c();
        blsAvgWageData.Name = 'Default';
        blsAvgWageData.seasonal__c = 'U';
        blsAvgWageData.area_code__c = '000';
        blsAvgWageData.industry_code__c = '10';
        blsAvgWageData.owner_code__c = '5';
        blsAvgWageData.Prefix__c = 'EN';
        blsAvgWageData.size_code__c = '0';
        blsAvgWageData.type_code__c = '5';
        Insert blsAvgWageData;
        
        BLS_Turnover_Rate__c blsTurnOverData = new BLS_Turnover_Rate__c();
        blsTurnOverData.Name = 'Default';
        blsTurnOverData.area_code__c = '00000';
        blsTurnOverData.dataelement_code__c = 'QU';
        blsTurnOverData.industry_code__c = '000000';
        blsTurnOverData.Prefix__c = 'JT';
        blsTurnOverData.ratelevel_code__c = 'R';
        blsTurnOverData.seasonal__c = 'U';
        blsTurnOverData.sizeclass_code__c = '00';
        blsTurnOverData.state_code__c = '00';
        Insert blsTurnOverData;
        
        PEOUW_BLS_Data__c blsRecord = new PEOUW_BLS_Data__c(PEO_Underwriting_Checklist__c = checklist.Id);
        insert blsRecord;
        Boolean valueExist = CommunityAccountEditFormController.checkIfBenchmarkValuesExist(acctA,checklist);
        Map<String, Decimal> valueRetrieved = CommunityAccountEditFormController.retrieveBenchmarkValues(checklist);
        Boolean hasPermissions = CommunityAccountEditFormController.checkBLSPermissions(users[0].Id,'Test');
        System.debug('valueExist:'+valueExist);
        System.debug('valueRetrieved:'+valueRetrieved);
        System.debug('hasPermissions:'+hasPermissions);
        System.assertEquals(true, valueExist);
        System.assert(valueRetrieved.size()> 0,'List should return records');
        System.assertEquals(false, hasPermissions);
    }
}