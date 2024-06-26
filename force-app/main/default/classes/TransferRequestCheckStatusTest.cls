/* Test the change of ownership of the records when the status is changed.
   
  History
  -------
  10/07/2009 Dan Carmen        Clean up trigger code - moved from Approveemail trigger
  09/29/2016 Dan Carmen        Increased API version
  10/26/2018 Dan Carmen        Change to API version 44
  11/13/2018 Dan Carmen        Clean up test methods.
  06/12/2019 Jacob Hinds       Changes to peo->aso
  10/01/2019 Carrie Marciano   Fixed query to pull back a core rep using the job name, it was only using profile like Core Sales% and bringing back DSA too
  04/12/2021 Michael Karcz	   Added query to pull back account with related account team member records
  05/06/2021 Dan Carmen        Refactor code to make more dynamic
  04/11/2023 Dan Carmen        Removed ZipCheckOwner.SKIP_TRIGGERS when saving the account. INC3289786

 */
@isTest
private class TransferRequestCheckStatusTest {

   @testSetup
   public static void setupData() {
      HoldOutExpirationMethodsTest.populateSetting();
   } // setupData

   // Verify the owner of the account and contacts is the same one passed in.
   private static boolean verifyOwner(Account acct, Id ownerId, Id hrsOwnerId, Id msOwnerId, Id pasOwnerId, Id hnbfOwnerId) {
        acct = [select Id, OwnerId, HRS_Account_Owner__c, Premier_PBS_Account_Owner__c, HNBF_Account_Owner__c,
                             (select Id, OwnerId
                                    ,HRS_Contact_Owner__c,Premier_PBS_Contact_Owner__c,Sales_Contact__c,Hold_Out__c,Hold_Out_Reason__c
                                    ,RecordTypeId, RecordType.Name
                                from Contacts),
                             (Select UserId FROM AccountTeamMembers WHERE TeamMemberRole = :CrossoverRequestController.OWNER_MS)
                  from Account where Id=:acct.Id];
        System.assertEquals(ownerId,acct.OwnerId);
        System.assertEquals((hrsOwnerId != null ? hrsOwnerId : null),acct.HRS_Account_Owner__c);
        if (msOwnerId != null) {
           for(AccountTeamMember atm:acct.AccountTeamMembers){
              System.assertEquals(msOwnerId ,atm.UserId);
           }
        }
        System.assertEquals((pasOwnerId != null ? pasOwnerId : null),acct.Premier_PBS_Account_Owner__c);
        System.assertEquals((hnbfOwnerId != null ? hnbfOwnerId : null),acct.HNBF_Account_Owner__c);
        for (Contact c : acct.Contacts) {
            system.debug('Contact: '+c);
            if(c.Sales_Contact__c == true && msOwnerId != null){
                System.assertEquals(msOwnerId,c.OwnerId);
                System.assertEquals(c.Hold_Out__c,true);
                System.assertEquals(c.Hold_Out_Reason__c,'Account Team Holdout');
                
            }
            else{
                System.assertEquals(ownerId,c.OwnerId);
            }
        }
        return true;
    } // verifyOwner
    
   // Create an account and contacts for testing purposes.
   private static Account createAccount(Id ownerId, Id hrsOwnerId, Id msOwnerId, Id pasOwnerId, Id hnbfOwnerId) {
      // create account and contacts owned by u1
      Account acct = new Account(Name = 'test', OwnerId = ownerId, HRS_Account_Owner__c=hrsOwnerId, Premier_PBS_Account_Owner__c=pasOwnerId, HNBF_Account_Owner__c=hnbfOwnerId);
      insert acct;
      if(msOwnerId!=null){
          AccountTeamMember atm = new AccountTeamMember(AccountId=acct.Id, UserId=msOwnerId, TeamMemberRole=CrossoverRequestController.OWNER_MS );
          insert atm;
      }
       
                
      Contact c1 = new Contact (FirstName='Jimmy', LastName='Test', OwnerId=ownerId, AccountId=acct.Id
                                 ,HRS_Contact_Owner__c = hrsOwnerId ,Premier_PBS_Contact_Owner__c = pasOwnerId,Sales_Contact__c=true);
      Contact c2 = new Contact (FirstName='Jenny', LastName='Test', OwnerId=ownerId, AccountId=acct.Id
                                 ,HRS_Contact_Owner__c = hrsOwnerId ,Premier_PBS_Contact_Owner__c = pasOwnerId);
      Contact[] ctcts = new Contact[]{c1,c2};
      insert ctcts;
      verifyOwner(acct,ownerId, hrsOwnerId, /*msOwnerId*/null,pasOwnerId,hnbfOwnerId);
      acct = [SELECT Name, OwnerId, HRS_Account_Owner__c, Premier_PBS_Account_Owner__c, HNBF_Account_Owner__c, (SELECT AccountId, UserId, TeamMemberRole FROM AccountTeamMembers WHERE AccountId = :acct.Id) FROM Account WHERE Id = :acct.Id];
      return acct;
   } // createAccount
    
    private static Transfer_Request__c createRequest(Id acctId, Id ownerId, Id acctOwnerId, String ownerField, String ownerType, Task[] tasks) {
       Transfer_Request__c tr = new Transfer_Request__c (OwnerId = ownerId, Owner_Field__c=ownerField, Owner_Type__c=ownerType, Account__c = acctId, Original_Owner__c = acctOwnerId, Account_Owner__c = acctOwnerId, Comments__c = 'Request for Transfer');
       if (tasks != null) {
          Task t1 = new Task(OwnerId = ownerId, Subject='TEST1', Type='TEST1', WhatId=acctId, ActivityDate=Date.today());
          tasks.add(t1);
       }
       return tr;
    } // createRequest
    
   /** Test the approval for the main owner record.
    */
   static testMethod void testMainApproved() {
      User[] users = [Select Id, Name from user where Profile.Name like 'Core Sales%' and isActive=true and Sales_Org__c='PAY' limit 2];
      User u1 = users[0];
      User u2 = users[1];
      users = [Select Id, Name from user where Profile.Name like 'HRS 401(k) Sales%' and isActive=true and Sales_Org__c='HRS' limit 2];
      User uHRS1 = users[0];
      User uHRS2 = users[1];
      users = [Select Id, Name from user where Profile.Name like 'Payment Processing Sales Rep%' and isActive=true and Sales_Org__c='MS' limit 2];
      User uMS1 = users[0];
      User uMS2 = users[1];
      users = [Select Id, Name from user where Profile.Name like 'HRS PEO-ASO Sales%' and isActive=true and Sales_Org__c='PAS' limit 2];
      User uPAS1 = users[0];
      User uPAS2 = users[1];
      users = [Select Id, Name from user where Profile.Name like 'HNBF Sales Rep%' and isActive=true and Sales_Org__c='HNBF' limit 2];
      User uHNBF1 = users[0];
      User uHNBF2 = users[1];
      
      Account acct = createAccount(u1.Id,uHRS1.Id,uMS1.Id,uPAS1.Id,uHNBF1.Id);

      Task[] tasks = new Task[]{};
      // create a transfer request for core u2
      Transfer_Request__c req1 = createRequest(acct.Id, u2.Id, acct.OwnerId,CrossoverRequestController.OWNER_MAIN,'PAY',tasks);
      // create a transfer request for HRS uHRS2
      Transfer_Request__c req2 = createRequest(acct.Id, uHRS2.Id, acct.HRS_Account_Owner__c, CrossoverRequestController.OWNER_HRS,'HRS',tasks);
        
      // create a transfer request for MS uMS2
      Id msOwner;
      for(AccountTeamMember atm:acct.AccountTeamMembers){
          msOwner = atm.UserId;
      }
      Transfer_Request__c req3 = createRequest(acct.Id, uMS2.Id, msOwner, CrossoverRequestController.OWNER_MS,'MS',tasks);
      // create a transfer request for pas u2

      Transfer_Request__c req4 = createRequest(acct.Id, uPAS2.Id, acct.Premier_PBS_Account_Owner__c, CrossoverRequestController.OWNER_PREMIER,'PAS',tasks);
      // create a transfer request for hnbf u2
      Transfer_Request__c req5 = createRequest(acct.Id, uHNBF2.Id, acct.HNBF_Account_Owner__c, CrossoverRequestController.OWNER_HNB,'HNBF',tasks);
        
      insert tasks;
      Transfer_Request__c[] requests = new Transfer_Request__c[]{req1,req2,req3,req4,req5};
      for (Integer cnt=0; cnt<requests.size(); cnt++) {
         requests[cnt].TaskId__c =  tasks[cnt].Id;
      }
        
      insert requests;
        
      // change the status to Approved
      for (Transfer_Request__c tr : requests) {
         tr.Status__c = CrossoverRequestController.STATUS_APPROVED;
      }
      Test.startTest();
      update requests;
      Test.stopTest();
        
      // check the Account - should have moved to other users
      verifyOwner(acct,u2.Id,uHRS2.Id,uMS2.Id,uPAS2.Id,uHNBF2.Id);
        
      Map<Id,Task> taskMap = new Map<Id,Task>([select Id, Status from Task where Id in :tasks]);
        
      // verify that tasks are now Completed
      for (Transfer_Request__c tr : requests) {
         Task t = taskMap.get((Id)tr.TaskId__c);
         System.assertEquals('Completed',t.Status);
      } // for        

   } // testMainApproved

   // Test when the request is declined.
   static testMethod void testDeclined() {
      User[] users = [Select Id, Name from user where Profile.Name like 'Core Sales%' and isActive=true and Sales_Org__c='PAY' limit 2];
      User u1 = users[0];
      User u2 = users[1];

      Account acct = createAccount(u1.Id,null,null,null,null);
        
      Task[] tasks = new Task[]{};
      // create a transfer request for u2
      Transfer_Request__c tr = createRequest(acct.Id, u2.Id, acct.OwnerId, CrossoverRequestController.OWNER_MAIN,'PAY',tasks);
      insert tasks;
      tr.TaskId__c = tasks[0].Id;
      insert tr;
        
      // change the status to Approved
      tr.Status__c = 'Declined';
      tr.Reason_For_Rejection__c='Just because';
      Test.startTest();
      update tr;
      Test.stopTest();
        
      // check the Account - Verify owner hasn't changed
      verifyOwner(acct,u1.Id,null,null,null,null);
        
        
      // verify that task is now Completed
      Task t1 = [select Id, Status from Task where Id = :tr.TaskId__c ];
      System.assertEquals('Completed',t1.Status);
        
   } // testDeclined
    
   // If it's a DSA status record, and the user who changes the status is not a DSA, make sure that
   //    the status isn't actually updated.
   static testMethod void testStatusChange() {
      User[] users = [Select Id, Name from user where Profile.Name like 'Core Sales%' and Job_Name__c='Sales Representative' and isActive=true and Sales_Org__c='PAY' limit 2];
      User u1 = users[0];
      User u2 = users[1];

      Account acct1 = createAccount(u1.Id,null,null,null,null);

      Transfer_Request__c TRb = new Transfer_Request__c (OwnerId = u2.Id,Account__c = acct1.Id, Owner_Field__c=CrossoverRequestController.OWNER_MAIN, Account_Owner__c = acct1.OwnerId, Status__c=CrossoverRequestController.DSA_STATUS, Comments__c = 'test this');
      insert TRb;
      System.runAs(u2) {
         TRb.Status__c = 'Approved';
         update TRb;
      } // System.runAs
      // verify status is the same
      TRb = [Select Status__c from Transfer_Request__c where Id=:TRb.Id];
      System.assertEquals(CrossoverRequestController.DSA_STATUS,TRb.Status__c);

      // verify account ownership hasn't changed
      verifyOwner(acct1,u1.Id,null,null,null,null);
        
   } // testStatusChange
        
   // Test when the autoapprove occurs. This will only check the checkbox. The trigger will actually change the status to Approved.
   static testMethod void testAutoApprove() {
      User[] users = [Select Id, Name from user where Profile.Name like 'Core Sales%' and isActive=true and Sales_Org__c='PAY' limit 2];
      User u1 = users[0];
      User u2 = users[1];
      Account acct1 = createAccount(u1.Id,null,null,null,null);
        
      Transfer_Request__c TRb = new Transfer_Request__c (OwnerId = u2.Id,Account__c = acct1.Id, Owner_Field__c=CrossoverRequestController.OWNER_MAIN, Owner_Type__c='PAY', Original_Owner__c = acct1.OwnerId, Account_Owner__c = acct1.OwnerId, Status__c=CrossoverRequestController.DSA_STATUS, Comments__c = 'test this');
      insert TRb;
      TRb.Auto_Approved__c = true;
      update TRb;
      TRb = [Select Status__c from Transfer_Request__c where Id=:TRb.Id];
      System.assertEquals('Approved',TRb.Status__c);
      // verify ownership changed.
      verifyOwner(acct1,u2.Id,null,null,null,null);
   } // testAutoApprove
        
   // Test when the request is in a transfer status on create.
   static testMethod void testTxferOnCreate() {
      User[] users = [Select Id, Name from user where Profile.Name like 'Core Sales%' and isActive=true and Sales_Org__c='PAY' limit 2];
      User u1 = users[0];
      User u2 = users[1];
      Account acct = createAccount(u1.Id,null,null,null,null);
        
      Transfer_Request__c tr = new Transfer_Request__c (OwnerId = u2.Id,Account__c = acct.Id, Owner_Field__c=CrossoverRequestController.OWNER_MAIN, Owner_Type__c='PAY', Original_Owner__c = acct.OwnerId, Account_Owner__c = acct.OwnerId, Status__c=CrossoverRequestController.STATUS_TXFER+'-Testing', Comments__c = 'test this');
      insert tr;
      // verify ownership changed.
      verifyOwner(acct,u2.Id,null,null,null,null);
   } // testAutoApprove

} // class TransferRequestCheckStatusTest