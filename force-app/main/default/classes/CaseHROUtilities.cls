/* 
 * Create related HRO cases
 *
 * History
 * -------
 * 07/01/2010 Dan Carmen   Created from HROCaseUtilities
   12/12/2012 Dan Carmen   Clean up some of the code.
   01/09/2014 Josh Cartwright Added CA HRO 
   06/09/2014 Josh Cartwright Added CA HRO 
   10/29/2018 Dan Carmen   Increment API to version 44

 */
public with sharing class CaseHROUtilities {

   public static void insertChildCases(Id[] caseIds){  
    
      // see if any records are set for processing
      Map<Id, Case> casesToProcess = new Map<Id, Case>([Select Id 
                              From Case c 
                             where id in : caseIds
                               and (((c.RecordType.Name ='Service Support HRO Case') and 
                                     (Mass_Create_Indicator__c = 'HRO Number'))
                                     or
                                    (((c.RecordType.Name ='Service Onboarding HRO Case') or
                                      (c.RecordType.Name ='Service Onboarding HRO MAA Case') or
                                      (c.RecordType.Name ='Service Onboarding HRO Case Record Type') or
                                      (c.RecordType.Name ='Service Onboarding W2 Only Case Record Type') or
                                      (c.RecordType.Name ='Service Onboarding EAO Case Record Type')or
                                      (c.RecordType.Name ='Service Onboarding CA HRO Record Type')
                                     ) and
                                     //(Action__c IN ('HRO Onboarding/Setup','EAO Onboarding/Setup','W2 Only Onboarding/Setup','CA HRO Onboarding/Setup')) and
                                    (ParentId = null) and
                                    (Account.HRO_Number__c != null))
                                   )
                                   ]);

      // if no results, don't need to do anything further.
      if (!casesToProcess.isEmpty()) {
      	 processChildCases(casesToProcess.keySet());
      }
      
   } // insertChildCases
   
   @future
   private static void processChildCases(Set<Id> caseIds){
   	
      //savedCases will store cases being processed (all inserts) along with relationship fields
      Map<Id, Case> savedCases = new Map<Id, Case>([Select Id, CaseNumber, OwnerId
                                                          ,createdById, ParentId
                                                          ,c.Subject, c.Status
                                                          ,c.RecordType.Name, c.RecordTypeId
                                                          ,c.Action__c, origin
                                                          ,AccountId
                                                          ,Account.hro_number__c, c.Mass_Create_Indicator__c 
                                                     From Case c 
                                                    where id in :caseIds
                                                    ]);
                                                    /*
                                                      and (((c.RecordType.Name ='Service Support HRO Case') and 
                                                            (Mass_Create_Indicator__c = 'HRO Number'))
                                                           or
                                                           (((c.RecordType.Name ='Service Onboarding HRO Case') or
                                                             (c.RecordType.Name ='Service Onboarding HRO Case Record Type') or
                                                             (c.RecordType.Name ='Service Onboarding W2 Only Case Record Type') or
                                                             (c.RecordType.Name ='Service Onboarding EAO Case Record Type')
                                                            ) and
                                                            //(Action__c IN ('HRO Onboarding/Setup','EAO Onboarding/Setup','W2 Only Onboarding/Setup')) and
                                                            (ParentId = null) and
                                                            (Account.HRO_Number__c != null))
                                                           )
                                                           ]);
                                                           */
  
      //caseMap will be used to store a map of each HRO Number and all cases associated with
      //  the HRO Number though their parent account.
      Map<String, List<Case>> caseMap = new Map<String, List<Case>>();
     
      // save the account ids so they're not selected again.
      List<Id> acctIds = new List<Id>();
     
      //Loop through each case being processed
      for (Case c : savedCases.values()) {

         String hroNumber = c.Account.HRO_Number__c;
         if (hroNumber != null) {
         	acctIds.add(c.AccountId);
         	List<Case> cTemp = caseMap.get(hroNumber);
         	if (cTemp == null) {
               cTemp = new List<Case>();
               caseMap.put(hroNumber,cTemp);
         	}
         	cTemp.add(c);
         } // if (hroNumber
      } // for (Case c
      
      // if no numbers, don't need to do anything.
      if (caseMap.isEmpty()) {
      	 return;
      }

      //Create list to store batch update
      List<Case> relatedCases = new List<Case>();

      // query all accounts with the HRO numbers
      for (List<Account> accts : [Select Id, Name, AccountNumber, HRO_Number__c 
                                    from Account
                                   where hro_number__c IN :caseMap.keySet()
                                     and Id not in :acctIds]) {
         for (Account acct: accts) {
            //Loop through all cases in batch for each parent account HRO Number.  A new child
            //  case for the current account needs to be added to each.
            for (Case currentCase : caseMap.get(acct.HRO_Number__c)) {

               //Add the child case to the batch to be inserted
               if ((currentCase.recordtype.name == 'Service Support HRO Case') && 
                   (currentCase.Mass_Create_Indicator__c == 'HRO Number')) {
                  Case relatedCase = currentCase.clone(false, true);
                  relatedCase.OwnerId = currentCase.createdById;
                  relatedCase.ParentId = currentCase.id;
                  relatedCase.accountid = acct.id;
                                    
                  relatedCases.add (relatedCase);
               } 
                else if (currentCase.recordtype.name == 'Service Onboarding CA HRO Record Type') {
 				 Case relatedCase = new Case(
                                        RecordTypeId = currentCase.RecordTypeId,
                                        OwnerId = currentCase.OwnerId,
                                        Subject = 'CA HRO Onboarding Reference Case - Click on Parent Case for Details',
                                        Product__c = 'CA HRO',
                                        Origin = 'Email',
                                        Status = 'Reference Parent Case',
                                        //relatedCase.ParentId = trigger.new[0].id;
                                        ParentId = currentCase.id,
                                        Current_Owner_Start_Date_Time__c = datetime.now(),
                                        accountid = acct.id);
                  relatedCases.add (relatedCase);                
                }
                else {
                  Case relatedCase = new Case(
                                        RecordTypeId = currentCase.RecordTypeId,
                                        OwnerId = currentCase.OwnerId,
                                        Subject = 'HRO Onboarding Reference Case - Click on Parent Case for Details',
                                        Product__c = 'HR Online',
                                        Origin = 'Order',
                                        Status = 'Reference Parent Case',
                                        //relatedCase.ParentId = trigger.new[0].id;
                                        ParentId = currentCase.id,
                                        Current_Owner_Start_Date_Time__c = datetime.now(),
                                        accountid = acct.id);
                  relatedCases.add (relatedCase);
               } // if ((savedCase.recordtype.name
               if (relatedCases.size() >= 200) {
                  checkRelated(relatedCases);
               }
         	
            } // for (Case currentCase
         } // for (Account acct	
      } // for (List<Account> accts

      checkRelated(relatedCases);
    
   } // insertChildCases

   private static void checkRelated(List<Case> relatedCases) {
      if (relatedCases.size() > 0) {
         checkLimits(relatedCases.size());
         insert relatedCases;
         relatedCases.clear();
      } // if
   } // checkRelated
   
   /** Check to make sure we are not hitting DML limits with this transaction.
    */
   public static boolean checkLimits (Integer numRows) {
   	String errorMsg = Utilities.checkLimits('Create Related Cases',1,numRows);
   	if (errorMsg != null) {
         Throw new HROQuantityException(errorMsg+'! Too many Accounts exist with the same HRO case number, contact your system administrator.  If you are performing a dataload, reduce the size of your data file and re-attempt the load');//Exception
   	}
      return true;
   } // checkLimits
   

   public class HROQuantityException extends Exception{}
   
} // class CaseHROUtilities