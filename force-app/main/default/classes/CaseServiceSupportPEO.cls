/*
 *  When a new Case is created with Service Support PEO Finance record type then 
 *  update Case.Sales_Rep__c with Account Team User name (of PEO-ASO Partner Role type).
 *   
 * History
 * -------
 * 04/21/2020 Manmeet Vaseer    Created - SFDC-3072 (US4)
  10/09/2020 Jake Hinds   Adding without sharing per PMD
 * 
 */ 
public without sharing class CaseServiceSupportPEO {

    public static void updateCases(List<Case> caseList)
   {
       System.debug('CaseServiceSupportPEO, new cases (caseList count): ' + caseList.size());
       
       /* Gather all the Account Ids so that they can be used to get all the AccountTeamMembers.*/
       List<Id> accountIds = new List<Id>();
       for(Case kase : caseList)
       {
           accountIds.add(kase.AccountId);
       }
       
       System.debug('CaseServiceSupportPEO, associated account to new case (accountIds): ' + accountIds);
       
       /* Create a map of Account Id and AccountTeamMember object.*/
       Map<Id, AccountTeamMember> acctTeamMap = new Map<Id,AccountTeamMember>();
       AccountTeamMember[] acctTeamMems = [SELECT Id, UserId, AccountId FROM AccountTeamMember WHERE AccountId IN :accountIds AND TeamMemberRole = 'PEO-ASO Partner'];

       System.debug('CaseServiceSupportPEO, associated Account Team Member for the Account (acctTeamMems): ' + acctTeamMems);
       
       for(AccountTeamMember atm : acctTeamMems)    {
           acctTeamMap.put(atm.AccountId, atm);
       }
       
       /* 
        * Update Case Sales Rep field with Account Team Member User with 'PEO-ASO Partner' role type. 
        * Case DSM__c field will automatically be updated with User's Manager as it is a Formula field.
        */
       for(Case kase : caseList)
       {
           AccountTeamMember atm = acctTeamMap.get(kase.AccountId);
           if(atm != null)  {
               System.debug('CaseServiceSupportPEO, found Account Team Member for the Case. atm.UserId: ' + atm.UserId);
               kase.Sales_Rep__c = atm.UserId;
           }
       }        
   }    
}