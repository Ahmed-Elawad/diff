/* Change the ownership of the records when the status is changed. Called from the before trigger.

History
-------
10/07/2009 Dan Carmen   Clean up trigger code - moved from Approveemail trigger
10/22/2010 Dan Carmen   Update HNB hold out to be 180 days.
09/11/2015 Cindy Freeman    added logic to set hold out expiration dates using custom setting
03/10/2016 Jacob Hinds  Allow crossover to account team, allow for multiple crossover choices.  Major rewrite of code.
06/18/2018 Carrie Marciano   Set record type and type for PEOC crossover 
10/26/2018 Dan Carmen        Change to API version 44
06/12/2019 Jacob Hinds       Changes to PEO
04/09/2021 Michael Karcz	 Quick fix to updateOwner() to find old AccountTeamMembers based on their name rather than Team Member Role
05/06/2021 Dan Carmen        Refactor code to make more dynamic
02/22/2022 Carrie Marciano   Added BenAdmin Holdout fields
04/11/2023 Dan Carmen        Removed ZipCheckOwner.SKIP_TRIGGERS when saving the account. INC3289786

*/
public without sharing class TransferRequestCheckStatus {
    
    /** Process the approved requests.
*/
    public static void processApproved(Transfer_Request__c[] requests) {
        System.debug('TransferRequestCheckStatus processApproved');
        // the list of account ids with transfer requests
        Map<Id,Id> accountIds = new Map<Id,Id>();
        // tasks Ids to update to completed
        Id[] taskIds = new Id[]{};
            // get all account ids
            for (Transfer_Request__c tr : requests) {
                accountIds.put(tr.Account__c,tr.Account__c);
                if (tr.TaskId__c != null) {
                    taskIds.add(tr.TaskId__c);
                }
            } // for (Transfer_Request__c
        System.debug('Number accountIds = '+accountIds.size());
        
        closeTasks(taskIds);
        
        // retrieve all of the accounts
        Map<Id,Account> allAccts = new Map<Id,Account>([
            Select Id 
            ,Name
            ,RecordType.Name
            ,OwnerId
            ,Hold_Out__c
            ,Hold_Out_Expiration__c
            ,Permanent_Hold_Out_Description__c
            ,HRS_Account_Owner__c
            ,HRS_Hold_Out__c
            ,HRS_Hold_Out_Expiration__c
            ,HRS_Permanent_Hold_Out_Description__c
            ,OasisPEOAccountOwner__c
            ,OasisPEOHoldOut__c
            ,OasisPEOHoldOutExpiration__c
            ,OasisPEOHoldOutReason__c
            ,Premier_PBS_Account_Owner__c
            ,Premier_PBS_Hold_Out__c
            ,Premier_PBS_Hold_Out_Expiration__c
            ,PEO_ASO_Permanent_Hold_Out_Description__c
            ,HNBF_Account_Owner__c
            ,HNBF_Hold_Out__c
            ,HNBF_Hold_Out_Expiration__c
            ,HNBF_Permanent_Hold_Out_Description__c
            ,BenAdmin_Hold_Out__c
            ,BenAdmin_Hold_Out_Expiration__c
            ,BenAdmin_Hold_Out_Reason__c
            ,Previous_Owner_Id__c
            ,(Select TeamMemberRole, UserId FROM AccountTeamMembers)
            ,(SELECT Id
              ,Name
              ,OwnerId
              ,HRS_Contact_Owner__c
              ,MMS_Contact_Owner__c
              ,OasisPEOOwner__c
              ,Premier_PBS_Contact_Owner__c
              ,HNBF_Contact_Owner__c
              ,Sales_Contact__c
              from Contacts
              Where Sales_Contact__c=true order by LastModifiedDate desc limit 10)
            from Account where Id in :accountIds.keySet() ]);
        
        System.debug('TransferRequestCheckStatus processApproved allAccts.size()='+allAccts.size());
        // The list of accounts that need to be updated
        Map<Id,Account> updateAccts = new Map<Id,Account>();
        // The list of contacts that need to be updated.
        Map<Id,Contact> updateCtcts = new Map<Id,Contact>();
        // The list of AccountTeamMembers that need to be added
        Map<Id,AccountTeamMember> addATMMap = new Map<Id,AccountTeamMember>();
        // The list of AccountTeamMembers that need to be deleted.
        Map<Id,AccountTeamMember> delATMMap = new Map<Id,AccountTeamMember>();
        
        // Loop through the requests, change the ownership of the accounts
        for (Transfer_Request__c tr : requests) {
            Account acct = allAccts.get(tr.Account__c);
            if (acct != null) {
                System.debug('TransferRequestCheckStatus processApproved acct.Name='+acct.Name);
                if(tr.Crossover_Extension__c) extendHoldOut(tr, acct, updateAccts);
                else {
                    System.debug('TransferRequestCheckStatus processApproved calling updateOwner');
                    updateOwner(tr,acct,updateAccts,updateCtcts,addATMMap,delATMMap);
                    //updateOwner(tr.Owner_Field__c,tr.Owner_Type__c,tr.OwnerId,tr.Original_Owner__c,tr.Team_Member_Role__c,acct,updateAccts,updateCtcts,addATMMap,delATMMap);
                    // remove so it will not update again (in case there's more than one request)
                    //allAccts.remove(tr.Account__c);
                }
            } // if (acct != null)
        } // for (Transfer_Request__c
        
        system.debug(delATMMap);
        system.debug(addATMMap);
        // update the records
        DmlHelper.performDML2(delATMMap.values(), DmlHelper.DML_DELETE, 'TransferRequestCheckStatus', 'processApproved', 'Delete AccountTeamMembers', false);
        DmlHelper.performDML2(addATMMap.values(), DmlHelper.DML_INSERT, 'TransferRequestCheckStatus', 'processApproved', 'Insert AccountTeamMembers', false);
        DmlHelper.performDML2(updateAccts.values(), DmlHelper.DML_UPDATE, 'TransferRequestCheckStatus', 'processApproved', 'Update Accounts', false);
        ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
        ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
        DmlHelper.performDML2(updateCtcts.values(), DmlHelper.DML_UPDATE, 'TransferRequestCheckStatus', 'processApproved', 'Update Accounts', false);
        ErrorLog.checkSave();
    } // processApproved
    
    private static void extendHoldOut(Transfer_Request__c tr, Account acct, Map<Id,Account> updateAccts) {
        for(HoldOut_ExpirationDates__c hoed : HoldOut_ExpirationDates__c.getAll().values()) {
            if (hoed.Sales_Org__c == tr.Owner_Type__c && acct.Hold_Out_Expiration__c!=null && hoed.Extension_Number_of_Days__c!=null) {
                Date hoDate = acct.Hold_Out_Expiration__c;
                acct.Hold_Out_Expiration__c = hoDate.addDays((Integer)hoed.Extension_Number_of_Days__c);
                updateAccts.put(acct.Id,acct);
            }
        }
    } // extendHoldOut
    
    private static void updateOwner(Transfer_Request__c tr, Account acct
                                    ,Map<Id,Account> updateAccts, Map<Id,Contact> updateCtcts,Map<Id,AccountTeamMember> addATMMap, Map<Id,AccountTeamMember> delATMMap) {
       HoldOut_ExpirationDates__c hed = HoldOut_ExpirationDates__c.getInstance(tr.Owner_Type__c);
                                      
       if (hed == null) {
          StringHelper.addToProcessNotes(tr,'Could not find field definitions for '+tr.Owner_Type__c);
          return;
       }
       String contactField = null;
       Date expirationDate = HoldOutExpirationMethods.calcHODate(Date.today(), tr.Owner_Type__c);
       Account updateAcct = (updateAccts.containsKey(tr.Account__c) ? updateAccts.get(tr.Account__c) : new Account(Id=tr.Account__c));
       System.debug('updateOwner updateAcct='+updateAcct);                                  
       updateAccts.put(updateAcct.Id,updateAcct);
       contactField = hed.ContactOwner__c;
       if (String.isNotBlank(hed.Account_Owner__c)) {
          StringHelper.addToProcessNotes(tr,'Setting owner field '+hed.Account_Owner__c+' to '+tr.OwnerId);
          if (tr.Owner_Field__c == CrossoverRequestController.OWNER_MAIN) {
             updateAcct.Previous_Owner_Id__c = (Id)acct.get(hed.Account_Owner__c);
          }
          updateAcct.put(hed.Account_Owner__c,tr.OwnerId);
       }
       if (String.isNotBlank(hed.AccountTeamRole__c)) {
          // look for existing role based on user or role name - delete any found
          for (AccountTeamMember atm: acct.AccountTeamMembers) {
             if (atm.UserId == tr.Original_Owner__c || atm.TeamMemberRole == hed.AccountTeamRole__c) {
                 StringHelper.addToProcessNotes(tr, 'Deleting ATM  id='+atm.Id+' user='+atm.UserId+' role='+atm.TeamMemberRole);
                 delATMMap.put(atm.Id,atm);
             }
          } // for (AccountTeamMember atm
          // create a team member
          AccountTeamMember newATM = new AccountTeamMember(AccountId=acct.Id, UserId=tr.OwnerId, TeamMemberRole=hed.AccountTeamRole__c, AccountAccessLevel='Edit', ContactAccessLevel='Edit');
          StringHelper.addToProcessNotes(tr, 'Adding ATM userId='+newAtm.UserId+' role='+newAtm.TeamMemberRole);
          addATMMap.put(acct.Id,newATM);
       }
       // as long as either a main owner or account team member is set, set the holdout.
       if (String.isNotBlank(hed.Account_Owner__c) || String.isNotBlank(hed.AccountTeamRole__c)) {
          if (hed.Account_Hold_Out__c != null) {
             updateAcct.put(hed.Account_Hold_Out__c,true);
             System.debug('updateOwner hed.Account_Hold_Out__c='+hed.Account_Hold_Out__c); 
          }
          if (hed.Account_Hold_Out_Date__c != null) {
             updateAcct.put(hed.Account_Hold_Out_Date__c,expirationDate);
             System.debug('updateOwner hed.Account_Hold_Out_Date__c='+hed.Account_Hold_Out_Date__c); 
          }
          if (hed.HoldOutReasonFld__c != null) {
             updateAcct.put(hed.HoldOutReasonFld__c,'Crossover Request');
             System.debug('updateOwner hed.HoldOutReasonFld__c='+hed.HoldOutReasonFld__c); 
          }
       }                                 
         
       StringHelper.addToProcessNotes(tr,'contactField='+contactField);
       if (String.isNotBlank(contactField)) {
           Integer nbrCtcts = 0;
           System.debug('TransferRequestCheckStatus checking for Account Team Holdout contactField='+contactField);
           for (Contact ctct : acct.Contacts) {
                System.debug('TransferRequestCheckStatus ctct.get(contactField)='+ctct.get(contactField)+' originalOwner='+updateAcct.Previous_Owner_Id__c+' ctct.Sales_Contact__c='+ctct.Sales_Contact__c);
                if (ctct.get(contactField) == updateAcct.Previous_Owner_Id__c) {
                    ctct.put(contactField,tr.OwnerId);
                    updateCtcts.put(ctct.Id,ctct);
                    nbrCtcts++;
                } else if (String.isBlank(hed.Account_Owner__c)) {
                    //take ownership of sales contacts if crossing over on the account team
                    System.debug('TransferRequestCheckStatus setting Account Team Holdout');
                    ctct.put(contactField,tr.OwnerId);
                    ctct.put('Hold_Out__c',true);
                    ctct.put('Hold_Out_Expiration__c',expirationDate);
                    ctct.put('Hold_Out_Reason__c','Account Team Holdout');
                    updateCtcts.put(ctct.Id,ctct);
                    nbrCtcts++;
                }
            } // for (Contact ctct : acct.Contacts
            StringHelper.addToProcessNotes(tr,'Update owner on '+nbrCtcts+' contacts');
        } // if (String.isNotBlank(contactField

    } // updateOwner
    // Determine whether there was a previous transfer request and if so, extend the hold out on the acct
    
    // Process the declined records.
    public static void processDeclined(Transfer_Request__c[] requests) {
        // tasks Ids to update to completed
        Id[] taskIds = new Id[]{};
            // get all account ids
            for (Transfer_Request__c tr : requests) {
                if (tr.TaskId__c != null) {
                    taskIds.add(tr.TaskId__c);
                }
            } // for (Transfer_Request__c
        closeTasks(taskIds);
    } // processDeclined
    
    // Select the tasks. If they are not already closed, close them.
    private static void closeTasks(Id[] taskIds) {
        if (taskIds.size() > 0) {
            List<Task> tasks = new List<Task>([Select Id, Status from Task where Id in :taskIds]);
            for (Task t : tasks) {
                if (t.Status != 'Completed') {
                    t.Status = 'Completed';
                }
            } // for (Task
            update tasks;
        } // if (taskIds)
    } // closeTasks
    
} // class TransferRequestCheckStatus