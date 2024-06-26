/* 
* Test methods for CommunityMedicalQuestionnaireController.
*
* History
* -------
* 08/19/2021    Ahmed Elawad		Created
* 09/17/2021	Matt Fritschi		Changed testVerifyMedQuestionnairesHaveBeenCompleted to better test med questionnaire verification.
* 11/12/2023    Tej Pothuri			Tech Debt Clean up for SPA
*/

@isTest
public class CommunityMedicalControllerTest {
    
    
    @isTest
    static void testConstructor() {
        CommunityMedicalQuestionnaireController controller = new CommunityMedicalQuestionnaireController();
        
        System.assertNotEquals(null, controller);
    }
    
   /* @testSetup
    Static void setupData() {
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        List<Account> acList = new List<Account>();
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='12345');
        acList.add(acctA);
        //insert acctA;
        Account acctB = new Account(Name = 'ChildTestAccountCommunities', AccountNumber = '8-12345678',NumberOfEmployees = 60, BillingStreet = ' Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='5678', Phone='123-456-7891', DBA__c='TEST',
                                    SalesParent__c = acctA.Id, RecordTypeId=rtAcct.getRecordTypeId());
         acList.add(acctB);//insert acctB;
        
        Account acctC = new Account(Name = 'ChildTestAccountCommunities2', AccountNumber = '8-12345678',NumberOfEmployees = 60, BillingStreet = ' Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='5678', Phone='123-456-7891', DBA__c='TEST',
                                    SalesParent__c = acctA.Id, RecordTypeId=rtAcct.getRecordTypeId());
         acList.add(acctC);//insert acctC;
        insert  acList;
        Account_Junction__c acctJunc = new Account_Junction__c(Child_Account__c=acctB.Id, Parent_Account__c=acctA.Id);
        insert acctJunc;
        
        PEO_Onboarding_Checklist__c peoOnbChecklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctA.Id);
        insert peoOnbChecklist;
        
        PEO_Onboarding_Checklist__c peoOnbChecklistChild = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctB.Id,Parent_PEO_Checklist__c=peoOnbChecklist.Id);
        insert peoOnbChecklistChild;
        
        PEO_Onboarding_Checklist__c peoOnbChecklistChild2 = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctC.Id,Parent_PEO_Checklist__c=peoOnbChecklist.Id);
        insert peoOnbChecklistChild2;
    }
    
     static testMethod void testSaveMedicalQuestionnaire(){
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        
        PEO_Onboarding_Medical_Questionnaire__c medQuestionnaire = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=parentPeoOnbCheck.Id, Years_with_current_carrier__c=10, Past_medical_carrier_if_applicable__c='No', Renewal_date__c=System.today());
        insert medQuestionnaire;
        
        medQuestionnaire.Past_medical_carrier_if_applicable__c = 'No';
        medQuestionnaire.Years_with_current_carrier__c = 11;
        Map<String, String> questionnaireMapValues = new Map<String, String>();
        questionnaireMapValues.put('Id', medQuestionnaire.Id);
        questionnaireMapValues.put('Past_medical_carrier_if_applicable__c', medQuestionnaire.Past_medical_carrier_if_applicable__c);
        questionnaireMapValues.put('Years_with_current_carrier__c', String.valueOf(medQuestionnaire.Years_with_current_carrier__c));
        questionnaireMapValues.put('Name', 'ABCDE');
        questionnaireMapValues.put('Renewal_date__c', String.valueOf(System.today()+1));
        Boolean success = CommunityMedicalQuestionnaireController.commSaveMedicalQuestionnaire(questionnaireMapValues, null);
        
        medQuestionnaire = [SELECT Id, Name, PEO_Onboarding_Checklist__c, Years_with_current_carrier__c,Past_medical_carrier_if_applicable__c, Renewal_date__c,group_medical_offered_past_two_years__c FROM PEO_Onboarding_Medical_Questionnaire__c WHERE Id=:medQuestionnaire.Id LIMIT 1];
        System.assertEquals(true, success);
        System.assertEquals('No', medQuestionnaire.Past_medical_carrier_if_applicable__c);
        System.assertEquals(11, medQuestionnaire.Years_with_current_carrier__c);
        System.assertEquals(System.today()+1, medQuestionnaire.Renewal_date__c);
        
        medQuestionnaire.Past_medical_carrier_if_applicable__c = 'No';
        List<PEO_Onboarding_Medical_Questionnaire__c> questionnaireList = new List<PEO_Onboarding_Medical_Questionnaire__c>();
        questionnaireList.add(medQuestionnaire);
        success = CommunityMedicalQuestionnaireController.saveMedicalQuestionnaires(questionnaireList, null);
        
        medQuestionnaire = [SELECT Id, Name, PEO_Onboarding_Checklist__c, Years_with_current_carrier__c, Past_medical_carrier_if_applicable__c FROM PEO_Onboarding_Medical_Questionnaire__c WHERE Id=:medQuestionnaire.Id LIMIT 1];
        System.assertEquals(true, success);
        System.assertEquals('No', medQuestionnaire.Past_medical_carrier_if_applicable__c);
        success= CommunityMedicalQuestionnaireController.saveMedicalQuestionnaire(questionnaireList.get(0), null);
    }
    
    static testMethod void testGetPEOOnboardingChecklist(){
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];       
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        PEO_Onboarding_Checklist__c peoOnbCheck = CommunityMedicalQuestionnaireController.getPEOOnboardingChecklist(parentAcct.Id,null, null, null);
        System.assertEquals(parentPeoOnbCheck.Id, peoOnbCheck.Id);
        PEO_Onboarding_Medical_Questionnaire__c getMedForm = CommunityMedicalQuestionnaireController.getMedicalQuestionnaireForm(parentPeoOnbCheck.Id,'Test');
        
    }
    
     static testMethod void testVerifyMedQuestionnairesHaveBeenCompleted(){
        
        Account parentAcct = [SELECT Id, Name, ShippingState, BillingState FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        Account childAcct = [SELECT Id, Name, ShippingState, BillingState FROM Account WHERE Name = 'ChildTestAccountCommunities'];
        Account childAcct2 = [SELECT Id, Name, ShippingState, BillingState FROM Account WHERE Name = 'ChildTestAccountCommunities2'];
        
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c, OwnerId,Current_Medical_Coverage_Provided__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        PEO_Onboarding_Checklist__c childPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c, OwnerId FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :childAcct.Id];
        PEO_Onboarding_Checklist__c childPeoOnbCheck2 = [SELECT Id, Name, Prospect_Client__c, OwnerId FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :childAcct2.Id];
        
         //JDA
         parentPeoOnbCheck.Current_Medical_Coverage_Provided__c = 'No';
         
         List<PEO_Onboarding_Medical_Questionnaire__c> medQuestionnaires = new List<PEO_Onboarding_Medical_Questionnaire__c>();
         //PEO_Onboarding_Medical_Questionnaire__c parentQuestionnaire = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=parentPeoOnbCheck.Id, Renewal_date__c=System.today(), Current_PEO_Carrier_if_applicable__c='Test Carrier', Past_medical_carrier_if_applicable__c = 'No',Reason_for_termination__c = '',group_medical_offered_past_two_years__c = 'No',Rate_change_on_last_renewal__c = null);
         //JDA
         PEO_Onboarding_Medical_Questionnaire__c parentQuestionnaire = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=parentPeoOnbCheck.Id, Renewal_date__c=System.today(), Current_PEO_Carrier_if_applicable__c='Test Carrier', Past_Medical_Carrier__c = 'Test Carrier',Reason_for_termination__c = '',group_medical_offered_past_two_years__c = 'No',Rate_change_on_last_renewal__c = 20, Effective_date__c =System.today(), Termination_date__c =System.today(),Years_with_current_carrier__c = 3);
         
         PEO_Onboarding_Medical_Questionnaire__c childQuestionnaire1 = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=childPeoOnbCheck.Id, Renewal_date__c=System.today(), Current_PEO_Carrier_if_applicable__c='Test Carrier', Use_Parent_Questionnaire_Answers__c='Same as Parent');
        PEO_Onboarding_Medical_Questionnaire__c childQuestionnaire2 = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=childPeoOnbCheck2.Id, Renewal_date__c=System.today(), Current_PEO_Carrier_if_applicable__c='Test Carrier', Use_Parent_Questionnaire_Answers__c='Different from Parent');
        medQuestionnaires.add(parentQuestionnaire);
        medQuestionnaires.add(childQuestionnaire1);
         medQuestionnaires.add(childQuestionnaire2);
        insert medQuestionnaires;
        
        List<Account> accts = new List<Account>();
        accts.add(parentAcct);
        accts.add(childAcct);
        accts.add(childAcct2);
         
        List<String> fields = new List<String>();
         fields.add('Renewal_date__c');
         fields.add('Current_PEO_Carrier_if_applicable__c');
         //fields.add('Past_medical_carrier_if_applicable__c');
         //JDA
         fields.add('Past_Medical_Carrier__c');
         fields.add('Effective_date__c');
         fields.add('Termination_date__c');
         fields.add('Years_with_current_carrier__c');
         
         fields.add('Reason_for_termination__c');
         fields.add('group_medical_offered_past_two_years__c');
         fields.add('Rate_change_on_last_renewal__c');
        
        String missingInfo = CommunityMedicalQuestionnaireController.verifyMedQuestionnairesHaveBeenCompleted(accts, fields);
        System.assertEquals(childAcct2.Name+'.', missingInfo);
         CommunityMedicalQuestionnaireController.checkForMissingFields(true,parentQuestionnaire,fields); 
    }*/
}