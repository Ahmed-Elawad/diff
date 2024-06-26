/* After Trigger Test class for WC Questionnaire Industry Specific object
*
*   HISTORY
*  ---------
*   08/12/2021  Matt Fritschi     Created
    02/10/2022  Jake Hinds        Status to checklist

*/

@IsTest
public class WCQuestionnaireIndustrySpecificAfterTest {

    @testSetup
    public static void setup(){
        
        TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
        TriggerMethodsTest.createTriggerSetting('WCQuestionnaireIndustrySpecific', false, true, false, true, new String[]{'WCQuestionnaireIndustrySpecificAfter'}, classes, TriggerMethods.INTERFACE_C);
        insert classes;
        
        RecordTypeHelperTest.setupRecordType();
        Id acctRTMMS = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT).getRecordTypeId();
        
        Account acc = new Account();
        acc.Name = 'Peo test';
        acc.RecordTypeId = acctRTMMS;
        insert acc; 
        
        Contact c = new Contact(AccountId=acc.id,
                               FirstName = 'Test1',
                               LastName = 'Contact',
                               Email='testing@testing.com');
        List<Contact> ctctList = new List<Contact>();
        ctctList.add(c);
        insert ctctList;
        
        PEO_Onboarding_Checklist__c peo = new PEO_Onboarding_Checklist__c();
        peo.Prospect_Client__c=acc.id;
        peo.Name='testing Peo';
        insert peo;
        
    }
    
    public static testMethod void setFieldsOnChildren(){
        
        PEO_Onboarding_Checklist__c parentChecklist = [SELECT Id, Name, Industry_Record_Types__c FROM PEO_Onboarding_Checklist__c WHERE Name = 'testing Peo'];
        
        RecordType recType = [SELECT Id, Name from RecordType WHERE sObjectType='WC_Questionnaire_Industry_Specific__c' AND Name != null LIMIT 1];
        
        WC_Questionnaire_Industry_Specific__c indSpecific = new WC_Questionnaire_Industry_Specific__c(PEO_Underwriting_Checklist__c = parentChecklist.Id, RecordTypeId = recType.Id);
        insert indSpecific;
            
        parentChecklist = [SELECT Id, Name, Industry_Record_Types__c FROM PEO_Onboarding_Checklist__c WHERE Id = :parentChecklist.Id];
        System.assertEquals('!.!' + recType.Name + '!.!', parentChecklist.Industry_Record_Types__c);
        
        RecordType recType2 = [SELECT Id, Name from RecordType WHERE sObjectType='WC_Questionnaire_Industry_Specific__c' AND Name != null AND Name != :recType.Name LIMIT 1];
        
        WC_Questionnaire_Industry_Specific__c indSpecific2 = new WC_Questionnaire_Industry_Specific__c(PEO_Underwriting_Checklist__c = parentChecklist.Id, RecordTypeId = recType2.Id);
        insert indSpecific2;
        
        parentChecklist = [SELECT Id, Name, Industry_Record_Types__c FROM PEO_Onboarding_Checklist__c WHERE Id = :parentChecklist.Id];
        System.assertEquals('!.!' + recType.Name + '!.!' + recType2.Name + '!.!', parentChecklist.Industry_Record_Types__c);
    }
    public static testMethod void testChecklistComplete(){
        
        Account acct1 = new Account(Name='test1');
        Account acct2 = new Account(Name='test2');
        insert new Account[]{acct1,acct2};
            
        PEO_Onboarding_Checklist__c checklist1 = new PEO_Onboarding_Checklist__c(Name='testCheck1',Prospect_Client__c = acct1.Id,Industry_Record_Types__c='!.!Test!.!');
        PEO_Onboarding_Checklist__c checklist2 = new PEO_Onboarding_Checklist__c(Name='testCheck2',Prospect_Client__c = acct2.Id,Industry_Record_Types__c='!.!Test!.!');
        insert new PEO_Onboarding_Checklist__c[]{checklist1,checklist2};
            
        WC_Questionnaire_Industry_Specific__c ind1Chk1 = new WC_Questionnaire_Industry_Specific__c(Name='ind1Chk1',PEO_Underwriting_Checklist__c=checklist1.Id);
        WC_Questionnaire_Industry_Specific__c ind2Chk1 = new WC_Questionnaire_Industry_Specific__c(Name='ind2Chk1',PEO_Underwriting_Checklist__c=checklist1.Id);
        WC_Questionnaire_Industry_Specific__c ind1Chk2 = new WC_Questionnaire_Industry_Specific__c(Name='ind2Chk1',PEO_Underwriting_Checklist__c=checklist2.Id);
        insert new WC_Questionnaire_Industry_Specific__c[]{ind1Chk1,ind2Chk1,ind1Chk2};
        
        test.startTest();
        ind1Chk1.Peo_IndSpecific_formStatus__c = 'Complete';
        ind1Chk2.Peo_IndSpecific_formStatus__c = 'Complete';
        update new WC_Questionnaire_Industry_Specific__c[]{ind1Chk1,ind1Chk2};
        
        PEO_Onboarding_Checklist__c uChecklist1 = [SELECT Id,Peo_IndSpecific_formStatus__c FROM PEO_Onboarding_Checklist__c WHERE Id =:checklist1.Id LIMIT 1];
        system.assertEquals(null,uChecklist1.Peo_IndSpecific_formStatus__c);
        PEO_Onboarding_Checklist__c uChecklist2 = [SELECT Id,Peo_IndSpecific_formStatus__c FROM PEO_Onboarding_Checklist__c WHERE Id =:checklist2.Id LIMIT 1];
        system.assertEquals('Complete',uChecklist2.Peo_IndSpecific_formStatus__c);
        
        delete ind1Chk2;
        uChecklist2 = [SELECT Id,Peo_IndSpecific_formStatus__c FROM PEO_Onboarding_Checklist__c WHERE Id =:checklist2.Id LIMIT 1];
        system.assertEquals(null,uChecklist2.Peo_IndSpecific_formStatus__c);
        test.stopTest();
    }
}