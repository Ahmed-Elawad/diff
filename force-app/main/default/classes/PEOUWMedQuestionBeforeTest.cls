@IsTest
public class PEOUWMedQuestionBeforeTest {
    
    @testSetup
    public static void setup(){
        
        TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
            TriggerMethodsTest.createTriggerSetting('PEOOnboardingMedicalQuestionnaire', true, false, false, false, new String[]{'PEOUWMedQuestionBefore'}, classes, TriggerMethods.INTERFACE_C);
        insert classes;
        
        RecordTypeHelperTest.setupRecordType();
        Id acctRTMMS = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT).getRecordTypeId();
        
        Account acc = new Account();
        acc.Name = 'Peo test';
        acc.RecordTypeId = acctRTMMS;
        insert acc;
        
        Account childAcc1 = new Account();
        childAcc1.Name = 'Peo test 2';
        childAcc1.SalesParent__c = acc.Id;
        childAcc1.RecordTypeId = acctRTMMS;
        insert childAcc1;       
        
        Contact c = new Contact(AccountId=acc.id,
                                FirstName = 'Test1',
                                LastName = 'Contact',
                                Email='testing@testing.com');
        Contact c2 = new Contact(AccountId=childAcc1.id,
                                 FirstName = 'Test2',
                                 LastName = 'Contact',
                                 Email='testing2@testing2.com');
        List<Contact> ctctList = new List<Contact>();
        ctctList.add(c);
        ctctList.add(c2);
        insert ctctList;
        
        PEO_Onboarding_Checklist__c peo = new PEO_Onboarding_Checklist__c();
        peo.Prospect_Client__c=acc.id;
        peo.Name='testing Peo';
        insert peo;
        
        PEO_Onboarding_Checklist__c peo2 = new PEO_Onboarding_Checklist__c(Parent_PEO_Checklist__c=peo.Id);
        peo2.Prospect_Client__c=acc.id;
        peo2.Name='testing Peo2';
        insert peo2;
        
        List<PEO_Onboarding_Medical_Questionnaire__c> medQuestionnaires = new List<PEO_Onboarding_Medical_Questionnaire__c>();
        PEO_Onboarding_Medical_Questionnaire__c parentQuestionnaire = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=peo.Id, Renewal_date__c=System.today(), Current_PEO_Carrier_if_applicable__c='Test Carrier');
        PEO_Onboarding_Medical_Questionnaire__c childQuestionnaire = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=peo2.Id);
        medQuestionnaires.add(parentQuestionnaire);
        medQuestionnaires.add(childQuestionnaire);
        insert medQuestionnaires;
    }
    
    public static testMethod void testSetParentData(){
        
        PEO_Onboarding_Checklist__c parentChecklist = [SELECT Id, Name FROM PEO_Onboarding_Checklist__c WHERE Name = 'testing Peo'];
        PEO_Onboarding_Checklist__c childChecklist = [SELECT Id, Name FROM PEO_Onboarding_Checklist__c WHERE Name = 'testing Peo2'];
        
        PEO_Onboarding_Medical_Questionnaire__c parentMQ = [SELECT Id, Name, Renewal_date__c, Current_PEO_Carrier_if_applicable__c FROM PEO_Onboarding_Medical_Questionnaire__c WHERE PEO_Onboarding_Checklist__c = :parentChecklist.Id];
        PEO_Onboarding_Medical_Questionnaire__c childMQ = [SELECT Id, Name, Renewal_date__c, Current_PEO_Carrier_if_applicable__c, Use_Parent_Questionnaire_Answers__c FROM PEO_Onboarding_Medical_Questionnaire__c WHERE PEO_Onboarding_Checklist__c = :childChecklist.Id];
        
        childMQ.Use_Parent_Questionnaire_Answers__c = 'Same as Parent';
        update childMQ;
        
        childMQ = [SELECT Id, Name, Renewal_date__c, Current_PEO_Carrier_if_applicable__c, Use_Parent_Questionnaire_Answers__c FROM PEO_Onboarding_Medical_Questionnaire__c WHERE Id = :childMQ.Id];
        
        System.assertEquals('Same as Parent', childMQ.Use_Parent_Questionnaire_Answers__c);
        //System.assertEquals(parentMQ.Renewal_date__c, childMQ.Renewal_date__c);
        //System.assertEquals(parentMQ.Current_PEO_Carrier_if_applicable__c, childMQ.Current_PEO_Carrier_if_applicable__c);
        
    }
}