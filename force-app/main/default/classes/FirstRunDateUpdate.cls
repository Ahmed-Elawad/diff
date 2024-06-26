/*
 * 
 * This class will update the Payroll Run Date on the Reference Core Payroll that is assoicated with the Account from the integrated First Run/Core Start Date field.
 * 
 * 03/10/2015  Justin Henderson  Create Class & Method to update the RCP from Account First Run Date Field
 * 04/16/2015  Justin Henderson  Added update for the method to only run when Current Step is Creation, Step 1 or Step 2.
 * 08/14/2015  Jacob Hinds - added in a flag so the first run update doesn't cause an opportunity update when the Reference Core Payroll is updated
 * 02/06/2017  Cindy Freeman - fixed bug if there are 2 RCP records for 1 account, it was updating the 2nd, older RCP record when it shouldnt have updated either
 * 07/06/2020  Jacob Hinds         Added without sharing per PMD
 */

public without sharing class FirstRunDateUpdate {
    public static boolean HASBEENUPDATED = false;
    public static void updatePayrollRunDate(List<Id> firstRunDateAcctIds) {
        
        // map where the key is the account id
        Map<Id,Reference_Core_Payroll__c> refCoreMapToUpdate = new Map<Id,Reference_Core_Payroll__c>();
        Set<Id> acctIdsFoundSet = new Set<Id>();
        
        for(Reference_Core_Payroll__c refCore : [Select Id, Current_Step__c, Payroll_Run_Date__c, Case_Lookup__r.Account.First_Run_Date__c, Case_Lookup__r.Account.Id
                                   From Reference_Core_Payroll__c
                                   where Case_Lookup__r.AccountId in :firstRunDateAcctIds
                                                order by createdDate desc]) {
                  
           if (!acctIdsFoundSet.contains(refCore.Case_Lookup__r.Account.Id) && !refCoreMapToUpdate.containsKey(refCore.Case_Lookup__r.Account.Id) && (refCore.Current_Step__c == '(2 of 4) Client Load Complete' || refCore.Current_Step__c == '(1 of 4) Client Load Received' || refCore.Current_Step__c == 'Case Creation')) {
              refCore.Payroll_Run_Date__c = refCore.Case_Lookup__r.Account.First_Run_Date__c;
              refCoreMapToUpdate.put(refCore.Case_Lookup__r.Account.Id, refCore);
           }
           acctIdsFoundSet.add(refCore.Case_Lookup__r.Account.Id);
        } // for
        
        if (!refCoreMapToUpdate.isEmpty()) {
           HASBEENUPDATED = true;
           update refCoreMapToUpdate.values();
        }
    }
    
}