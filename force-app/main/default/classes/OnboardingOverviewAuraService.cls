public with sharing class OnboardingOverviewAuraService {
    
    @AuraEnabled
    public static List<Case> getAccountCases(Id accountId){
        Account currentAccount = [
            SELECT At_Risk__c, Potential_Risk__c, Primary_Client_Combined__c, CurrentClient__c,
                Do_Not_Call__c,Email_Opt_Out__c, Is_Referral_Source__c, 
                (SELECT Id, CaseNumber 
                FROM Cases 
                WHERE Priority = 'Critical' AND (Status = 'Waiting on Customer' OR Status = 'Waiting on Client'))
            FROM Account WHERE id = :accountId LIMIT 1
        ];

        return currentAccount.Cases;
    }
}