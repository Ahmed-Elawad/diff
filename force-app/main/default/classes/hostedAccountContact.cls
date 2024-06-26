public without sharing class hostedAccountContact {
    
    
    
    /*Written by Christophe Soulet for Salesforce.com Extensions.
    on June 29th 2006 per Tom Muskatevc's instructions:
    
    "Here are the requirements for the Apex Trigger for "Hosted Clients" that
    we would like you to build.

    When an Account (Prospect-Client) record is Inserted or Updated and the
    following condition is true:

    Account.Hosted_Client__c = TRUE (checked)

    Then do the following:

    Change the Account Owner to = SFDC Data (00530000000y8c8)
    Change all the related Contacts Owner = to SFDC Data (00530000000y8c8)
    Change the Account.Hold_Out__c field to = TRUE (checked)"
        
    */
    
    public static Set<Id> hostedCheckedIds = new Set<Id>();
    
    public static final String HOSTED='Hosted Client';
    
    public static void checkHostedOwner(Account[] accountsToCheck, Boolean checkContacts) {
        System.debug('checkHostedOwner nbrOfAccount='+accountsToCheck.size()+' checkContacts='+checkContacts);
       // get the SFDC Data user
       User sfdcData = UserHelper.getSfdcData();
       Id[] acctIdsToCheckForContacts = new Id[]{};
       for (Account acct : accountsToCheck) {
          if (acct.OwnerId != sfdcData.Id || !acct.Hold_Out__c || acct.Permanent_Hold_Out_Description__c != HOSTED) {
             acct.OwnerId = sfdcData.Id;
             acct.Hold_Out__c = true;
             acct.Permanent_Hold_Out_Description__c = HOSTED;
          }
          if (acct.Id != null) {
            // so we only check this once in a trigger call.
             hostedCheckedIds.add(acct.Id);
            acctIdsToCheckForContacts.add(acct.Id);
          }
       } // for (Account acct
       
       System.debug('checkHostedOwner checkContacts='+checkContacts+' acctIdsToCheckForContacts='+acctIdsToCheckForContacts);
       if (checkContacts && !acctIdsToCheckForContacts.isEmpty()) {
          Contact[] ctcts = [Select Id, Name, OwnerId, Hold_Out__c, Hold_Out_Reason__c 
                               from Contact 
                              where AccountId in :acctIdsToCheckForContacts
                                and (OwnerId != :sfdcData.Id
                                    or Hold_Out__c = false
                                    or Hold_Out_Reason__c != :HOSTED)];
          System.debug('checkHostedOwner number of ctcts='+ctcts.size());
          for (Contact ctct : ctcts) {
               System.debug('checkHostedOwner updating '+ctct.Name);
               ctct.OwnerId = sfdcData.Id;
               ctct.Hold_Out__c = true;
               ctct.Hold_Out_Reason__c = HOSTED;
               //ctctsToUpdate.add(ctct);
          } // for (Contact ctct
          
          if (!ctcts.isEmpty()) {
             Database.update(ctcts,false);
          }
       } // if (checkContacts
       
    } // checkHostedOwner
    
} // hostedAccountContact