/* Class to reassign Accounts owned by inactive users.
   
  History
  -------
  02/08/2021 Matt Fritschi	Created
  02/04/2022 Dan Carmen     Add check for user lookup on contact if status changes
  11/01/2023 Dan Carmen     Change call to checkUserLookups
  
 */

public class InactiveUserAccountQueueable implements Queueable{
    
    public final Map<Id, User> inactiveUsers;    
    public List<Account> acctsToUpdate=null;
    public Set<Id> alreadyUpdatedAccts=null;
    public Set<String> statusChangedPersonIdSet=null;
    
    public InactiveUserAccountQueueable(Map<Id, User> p_inactiveUsers, Set<String> p_statusChangedPersonIdSet) {
        System.debug('InactiveUserAccountQueueable started job.');
        inactiveUsers = p_inactiveUsers;
        statusChangedPersonIdSet = p_statusChangedPersonIdSet;
        alreadyUpdatedAccts = new Set<Id>();
    } // InactiveUserAccountQueueable
    
    public InactiveUserAccountQueueable(Map<Id, User> p_inactiveUsers, Set<Id> skipAccounts) {
        System.debug('InactiveUserAccountQueueable started job.');
        inactiveUsers = p_inactiveUsers;
        alreadyUpdatedAccts = skipAccounts;
    } // InactiveUserAccountQueueable
    
    public void execute(QueueableContext context) {
        checkUsersForStatusChange(); 
        acctsToUpdate = new List<Account>();
        
        if(!inactiveUsers.isEmpty()) {
            //Get info for the inactive users.
            Map<Id, User> inactiveUserMapWithTitle = new Map<Id, User>([SELECT Id, Name, Title, Sales_Division__c,Sales_Org__c FROM User WHERE Id IN :inactiveUsers.keySet()]);
            
            //Find any Lost Accounts that are owned by the Inactive User.
            Map<Id, Account> accountsOwnedByInactiveUsers = new Map<Id, Account>([SELECT Id, Name, Hold_Out__c, Permanent_Hold_Out_Description__c, Hold_Out_Expiration__c, Use_Zip_Assignment_Rules__c, OwnerId, Type, Lost_Date__c, 
                                                                                  (SELECT Id, Name, OpportunityType__c, IsClosed, IsWon FROM Opportunities WHERE OpportunityType__c = 'Payroll' ORDER BY CreatedDate DESC LIMIT 1)
                                                                                  FROM Account WHERE OwnerId IN :inactiveUserMapWithTitle.keySet() and Id not in :alreadyUpdatedAccts limit 200]);
            if(!accountsOwnedByInactiveUsers.isEmpty())
            {
                for(Account acct : accountsOwnedByInactiveUsers.values())
                {
                    User acctOwner = inactiveUserMapWithTitle.get(acct.OwnerId);
                    
                    System.debug('InactiveUserAccountQueueable acct.name='+acct.name+' acct.Lost_Date__c='+acct.Lost_Date__c);
                    //If SMB Channel Lost Client, change acct owner to territory rep.
                    if(acctOwner != null && acctOwner.Sales_Org__c == 'PAY' && acctOwner.Sales_Division__c != null && (acctOwner.Sales_Division__c.contains('SMB') && acctOwner.Sales_Division__c.contains('Channel'))
                       && ((acct.Type != null && acct.Type.contains('Lost')) || acct.Lost_Date__c != null) && acctsToUpdate.size() < 200)
                    {
                        changeAccountOwner(acct);
                        accountsOwnedByInactiveUsers.remove(acct.Id);
                    } 
                    //If the Not Sold Account Owner is an inactive SMB Channel Rep, change acct owner to territory rep.
                    else if(acctOwner != null && acctOwner.Sales_Org__c == 'PAY' &&
                            (acctOwner.Sales_Division__c != null && (acctOwner.Sales_Division__c.contains('SMB') && acctOwner.Sales_Division__c.contains('Channel'))) && 
                            !(acct.Opportunities != null && acct.Opportunities.size() == 1 && acct.Opportunities[0].IsClosed && acct.Opportunities[0].IsWon) && acctsToUpdate.size() < 200)
                    {
                        changeAccountOwner(acct);
                        accountsOwnedByInactiveUsers.remove(acct.Id);
                    }
                    //If the Sold Account Owner is an inactive Payroll Virtual/Micro/Inbound rep, change acct owner to territory rep.
                    else if(acctOwner != null && acctOwner.Sales_Org__c == 'PAY' &&
                            (acctOwner.Title != null && (acctOwner.Title.contains('Inbound') || acctOwner.Title.contains('Micro') || acctOwner.Title.contains('Virtual'))) && 
                            (acct.Opportunities != null && acct.Opportunities.size() == 1 && acct.Opportunities[0].IsClosed && acct.Opportunities[0].IsWon) && acctsToUpdate.size() < 200)
                    {
                        changeAccountOwner(acct);
                        accountsOwnedByInactiveUsers.remove(acct.Id);
                    }
                }
                
            }
        }

        //Update the Accounts.
        if(!acctsToUpdate.isEmpty())
        {
            System.debug('InactiveUserAccountQueueable Updatating Accounts updatedAcctList.size()='+acctsToUpdate.size());
            update acctsToUpdate;
            
            if(acctsToUpdate.size() == 200)
            {
                ID jobID = System.enqueueJob(new InactiveUserAccountQueueable(inactiveUsers, alreadyUpdatedAccts));
            }
        }
    } // execute
    
    //Removes the Payroll Hold Out fields and changes owner to territory rep.
    public void changeAccountOwner(Account acctToUpdate)  {
        System.debug('InactiveUserAccountQueueable Setting UseZipAssignments');
        acctToUpdate.Hold_Out__c = false;
        acctToUpdate.Permanent_Hold_Out_Description__c = null;
        acctToUpdate.Hold_Out_Expiration__c = null;
        acctToUpdate.Use_Zip_Assignment_Rules__c = true;
        acctsToUpdate.add(acctToUpdate);
        alreadyUpdatedAccts.add(acctToUpdate.Id);
    } // changeAccountOwner
    
    public void checkUsersForStatusChange() {
       System.debug('checkUsersForStatusChange statusChangedPersonIdSet='+(statusChangedPersonIdSet != null ? statusChangedPersonIdSet.size() : -1));
       if (statusChangedPersonIdSet == null || statusChangedPersonIdSet.isEmpty()) {
          return;
       }
       Contact[] ctcts = [Select Id, Name, HR_Person_Id__c, User_Lookup__c 
                                ,LastName, Date_of_Employee_Termination__c
                            from Contact where HR_Person_Id__c in :statusChangedPersonIdSet ];
       if (!ctcts.isEmpty()) {
          Map<String,Contact> contactByPersonIdMap = new Map<String,Contact>();
          for (Contact ctct : ctcts) {
              contactByPersonIdMap.put(ctct.HR_Person_Id__c, ctct);
          }
          Map<Id,Contact> ctctByUserIdMap = ContactFormatPaychexEmps.checkUserLookups(contactByPersonIdMap, new Map<String,Contact[]>());
          if (!ctctByUserIdMap.isEmpty()) {
             ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
             ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
             DmlHelper.performDML2(ctctByUserIdMap.values(), DmlHelper.DML_UPDATE, 'InactiveUserAccountQueueable', 'checkUsersForStatusChange', 'Update Contacts', true);
          }
       } // if (!ctcts.isEmpty
    } // checkUsersForStatusChange
    
} // class InactiveUserAccountQueueable