/*
 * 12/08/2021 Jidesh     Created
*/
@isTest(SeeAllData=false)
public class PEOUW_HSF_tests {

    @isTest(SeeAllData=true)
    public static void testHSF(){
        Account acc = new Account();
        acc.Name = 'Peo test';
        insert acc;
        User[] chatterUsers = [SELECT FirstName,Full_Name__c,Id,LastName, ManagerId FROM User WHERE Id!=:UserInfo.getUserId() AND Profile.Name = 'System Administrator' AND IsActive = true AND ManagerId != null LIMIT 5];
        System.debug('chatterUsers:'+chatterUsers);
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Name='testHSF',Sales_Rep__c=chatterUsers[0].Id,
                                                                                Sales_Analyst__c=chatterUsers[2].Id, HSF_Submission_Status__c = 'UNFAVORABLE', Prospect_Client__c = acc.Id);
        insert checklist;
        PEOOnboardingChecklist_Handler.sendHSFStatusUpdateChatter('FAIL', checklist);
    }
}