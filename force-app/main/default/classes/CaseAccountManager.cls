/* 
 * A class to populate the Account Manager field on the Case for the
 * HRS 4S LDPS Discrepancy and HRS 4S Client Support Discrepancy Record Type
 *   
 * History
 * -------
 * 11/04/2015 Lynn Michels created
 */
 
 public with sharing class CaseAccountManager 
 {
    //cases are of record type HRS 4S LDPS Discrepancy and HRS 4S Client Support Discrepancy
    public static void SetAccountManager(List<Case> cases)
    {
        Set<ID> AccountIds = new Set<ID>();
        Map<Id, List<Case>> accountToCasesMap = new Map<Id, List<Case>>();
        
        //populate the map of accounts and cases
        for (Case c : cases)
        {
            AccountIds.add(c.AccountId);
            //if the map already contains this accountId
            if (accountToCasesMap.containsKey(c.AccountId))
            {
                List<Case> casesOnAccount = accountToCasesMap.get(c.AccountId);  // get the values associated with that accountId from the map
                casesOnAccount.add(c);
                accountToCasesMap.put(c.AccountId, casesOnAccount); //populate the map 
            }
            //if the map does not contain this accountId     
            else
            {
                List<Case> casesNotInMap = new List<Case>();
                casesNotInMap.add(c);
                accountToCasesMap.put(c.AccountId, casesNotInMap); //populate the map  
            }
    
        }
            
       List<Account> accts = [SELECT id, Platinum_Rep_401K__r.Email, Platinum_Rep_401K__r.Name, 
                             (SELECT UserId, User.Email, User.Name, AccountId FROM AccountTeamMembers Where TeamMemberRole = 'HRS Client Relationship Account Manager' order by createdDate DESC Limit 1) 
                              FROM Account WHERE Id IN: AccountIds];
        for(Account acct : accts){
            if (accountToCasesMap.containsKey(acct.Id))
            {
                for (Case c : accountToCasesMap.get(acct.id))
                {
                    //if Platinum Rep is populated on the case's Account, use that person for the Account Manager
                    if(acct.Platinum_Rep_401K__c != null)
                    {
                        c.Account_Manager__c = acct.Platinum_Rep_401K__r.Name;
                        c.Account_Manager_Email__c = acct.Platinum_Rep_401K__r.Email;
                    } 
                    //if no Platinum Rep on the Account, use the Account Team Member with the specified Role.
                    //First check that AccountTeamMembers exist for this account
                    else if (!acct.AccountTeamMembers.isEmpty())
                    { 
                    	if(acct.AccountTeamMembers[0].User.Name != null)
	                    {
	                        c.Account_Manager__c = acct.AccountTeamMembers[0].User.Name;
	                        c.Account_Manager_Email__c = acct.AccountTeamMembers[0].User.Email;
	                    }   
                    }
                    
                    else
                    {
                    	c.Account_Manager__c = null;
                    }
                }
            }
        }   
    }
 }