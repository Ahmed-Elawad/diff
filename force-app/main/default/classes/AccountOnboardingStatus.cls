/* Uses the onboarding overview to determine if a client is in onboarding
History
-------
08/05/2019 Jacob Hinds      Created 
12/24/2019 Carrie Marciano    Added code to set the Client_Onboarding_Status__c = '' if the case/reference object has been deleted, changed Update to use DMLHelper
07/24/2020 Jacob Hinds      Retired in place of service model type on account
09/08/2020 Jacob Hinds      commenting back in
04/29/2024 Dan Carmen       Make sure the onboarding status is not empty before clearing and saving it.

*/
public without sharing class AccountOnboardingStatus {
    public static void checkAccountOnboardingStatus(Set<Id> accountIds){
        if (!accountIds.isEmpty()) {
         if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
            handleAccountOnboardingStatus(accountIds);
         } else {
            handleAccountOnboardingStatusFuture(accountIds);
         }
      } // if (!accountIds
    }
    @future
    public static void handleAccountOnboardingStatusFuture(Set<Id> accountIds) {
      handleAccountOnboardingStatus(accountIds);
    }
    public static void handleAccountOnboardingStatus(Set<Id>accountIds){
      Map<Id,Account> acctMap = new Map<Id,Account>([SELECT Id,Client_Onboarding_Status__c FROM Account WHERE Id in: accountIds]);
      Account[] acctsToUpdate = new Account[]{};
      OnboardingOverviewController ooc = new OnboardingOverviewController(accountIds);
      system.debug('AccountOnboardingStatus handleAccountOnboardingStatus ooc.refCollection'+ooc.refCollection);
      system.debug('AccountOnboardingStatus handleAccountOnboardingStatus ooc.refGradCollection'+ooc.refGradCollection);
      if(!ooc.refCollection.isEmpty()){
        system.debug('AccountOnboardingStatus handleAccountOnboardingStatus ooc.refCollectionKeySet'+ooc.refCollection.KeySet());  
      }
      
      //if(!ooc.refCollection.isEmpty() || !ooc.refGradCollection.isEmpty()){
        for(Account acct:acctMap.values()){
          if(ooc.refCollection.containsKey(acct.Id) && acct.Client_Onboarding_Status__c != 'In Progress'){
            acct.Client_Onboarding_Status__c = 'In Progress';
            acctsToUpdate.add(acct);
          } else if(!ooc.refCollection.containsKey(acct.Id) && ooc.refGradCollection.containsKey(acct.Id) && acct.Client_Onboarding_Status__c != 'Completed'){
            acct.Client_Onboarding_Status__c = 'Completed';
            acctsToUpdate.add(acct);
          } else if(ooc.refCollection.isEmpty() && ooc.refGradCollection.isEmpty() && String.isNotBlank(acct.Client_Onboarding_Status__c)){
              acct.Client_Onboarding_Status__c = null;
              acctsToUpdate.add(acct);
              system.debug('AccountOnboardingStatus handleAccountOnboardingStatus acct.Client_Onboarding_Status__c'+acct.Client_Onboarding_Status__c+' acct: '+acct);
           }
        }  
      //}//if(!ooc.refCollection
      
      if(!acctsToUpdate.isEmpty()){
        ZipCheckOwner.SKIP_TRIGGERS=true;
        DmlHelper.performDML2(acctsToUpdate, DmlHelper.DML_UPDATE, 'AccountOnboardingStatus', 'handleAccountOnboardingStatus', 'update Client Onboarding Status', false);
      }
      
    }//handleAccountOnboardingStatus
}//AccountOnboardingStatus