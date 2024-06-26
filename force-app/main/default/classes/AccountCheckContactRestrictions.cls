/* 
  check Account of update/inserted contact to see if Related Contact is Do Not Call field is checked
  or if Related Contact is Email Opt Out field is checked.
   
  History
  -------
  02/17/2012 Carrie Marciano   Created
  10/27/2014 Dan Carmen        Changed to without sharing
   
 */

public without sharing class AccountCheckContactRestrictions {

   public static void checkContacts(Set<Id> DNCAccountContactRestrictions, Set<Id> EmailAccountContactRestrictions) {
      
      Account[] accts = [Select Id 
                               ,Related_Contact_has_Do_Not_Call__c
                               , Related_Contact_is_Email_Opt_Out__c
                          from Account
                          where Id in :DNCAccountContactRestrictions or Id in :EmailAccountContactRestrictions
                           ];
      Account[] updateAccts = new Account[]{};
      
      for (Account acct : accts){
      	if (DNCAccountContactRestrictions.contains(acct.Id)){
            	acct.Related_Contact_has_Do_Not_Call__c = true;
      	}
      	if (EmailAccountContactRestrictions.contains(acct.Id)){
            	acct.Related_Contact_is_Email_Opt_Out__c = true;  
      	}	
        updateAccts.add(acct);   	
      } // for           	
            	
          
      if (!updateAccts.isEmpty()) {
         Database.update(updateAccts,false);
      }
      
   } // checkContacts
   
} // AccountCheckContactRestrictions