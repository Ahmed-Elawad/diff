/* 
  Test for CSSR Segment Batch
   
  History
  -------
   06/20/2018     Jake Hinds  Created

*/
@isTest
private class AccountCurrentClientBatchTest {

   static testMethod void testUpdate() {
      Map<String,Schema.RecordTypeInfo> byNameMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
      Id coreRtId = byNameMap.get(RecordTypeHelper.CORE_ACCOUNT).getRecordTypeId();
      Id mmsRTId = byNameMap.get(RecordTypeHelper.MMS_ACCOUNT).getRecordTypeId();

      Account acct1 = new Account(Name='Test Account1',BIS_Id__c = 1234567,
                           Employees__c = 55,
                           RecordTypeId = mmsRTId);
      Account acct2 = new Account(Name='Test Account2',BIS_Id__c = 1234568,
                           Employees__c = 35,
                           RecordTypeId = coreRtId);
      Account[] accts = new Account[]{acct1,acct2};
      insert accts;
      
      AccountCurrentClientBatch.NUM_DAYS_AS_CLIENT=300;
        
      acct1.First_Run_Date__c = date.today().addDays(-400);
      acct2.First_Run_Date__c = date.today().addDays(-350);
      update accts;
      
      Id[] acctIds = new Id[]{acct1.Id, acct2.Id};
        
      Map<Id,Account> checkAcctMap = new Map<Id,Account>([Select Id, CSSR_Segment__c,Client_Start_Date__c, Lost_Date__c, CurrentClient__c FROM Account WHERE Id in :acctIds]);
      System.assertEquals(acct1.First_Run_Date__c, checkAcctMap.get(acct1.Id).Client_Start_Date__c);
      System.assertEquals(false, checkAcctMap.get(acct1.Id).CSSR_Segment__c);
      System.assertEquals(true, checkAcctMap.get(acct1.Id).CurrentClient__c);
      System.assertEquals(acct2.First_Run_Date__c, checkAcctMap.get(acct2.Id).Client_Start_Date__c);
      System.assertEquals(false, checkAcctMap.get(acct2.Id).CSSR_Segment__c);
      System.assertEquals(true, checkAcctMap.get(acct2.Id).CurrentClient__c);
      //Account uAcct = [SELECT Id,CSSR_Segment__c,Client_Start_Date__c FROM Account WHERE Id = :acct.Id];  
      //system.assertEquals(acct.First_Run_Date__c,uAcct.Client_Start_Date__c);
            
      Test.startTest();
      AccountCurrentClientBatch accb = new AccountCurrentClientBatch();
      Database.executeBatch(accb,10);
      Test.stopTest();

      checkAcctMap = new Map<Id,Account>([Select Id, CSSR_Segment__c,Client_Start_Date__c, Lost_Date__c, CurrentClient__c FROM Account WHERE Id in :acctIds]);
      System.assertEquals(true, checkAcctMap.get(acct1.Id).CSSR_Segment__c);
      System.assertEquals(true, checkAcctMap.get(acct2.Id).CSSR_Segment__c);
        
      //uAcct = [SELECT Id,CSSR_Segment__c,Client_Start_Date__c FROM Account WHERE Id = :acct.Id];
      //system.assertEquals(true,uAcct.CSSR_Segment__c);
        
      acct1.Lost_Date__c = date.today();
      acct2.Lost_Date__c = date.today();
      update accts;
        
      checkAcctMap = new Map<Id,Account>([Select Id, CSSR_Segment__c,Client_Start_Date__c, Lost_Date__c, CurrentClient__c FROM Account WHERE Id in :acctIds]);
      System.assertEquals(false, checkAcctMap.get(acct1.Id).CSSR_Segment__c);
      System.assertEquals(null, checkAcctMap.get(acct1.Id).Client_Start_Date__c);
      System.assertEquals(false, checkAcctMap.get(acct2.Id).CSSR_Segment__c);
      System.assertEquals(null, checkAcctMap.get(acct2.Id).Client_Start_Date__c);

      //uAcct = [SELECT Id,CSSR_Segment__c,Client_Start_Date__c FROM Account WHERE Id = :acct.Id];
      //system.assertEquals(false,uAcct.CSSR_Segment__c);
      //system.assertEquals(null,uAcct.Client_Start_Date__c);

   } // testUpdate
    
   static testMethod void testAccountTeams() {
      User[] reps = [Select Id, Name from User where Job_Name__c=:UserHelper.JOB_REP and IsActive=true limit 2];

      Account acct = new Account(Name='Test Account', OwnerId=reps[1].Id);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
       
      AccountTeamMember atm1 = new AccountTeamMember(UserId=reps[0].Id, AccountId=acct.Id, TeamMemberRole='Test Role1');
      insert atm1;
       
      System.runAs(reps[1]) {
         AccountTeamMember atm2 = new AccountTeamMember(UserId=reps[1].Id, AccountId=acct.Id, TeamMemberRole='Test Role2');
         insert atm2;
      }
       
      System.assertEquals(1,[select count() from AccountTeamMember where CreatedById=:reps[1].Id]);
       
      System.assertEquals(1,[Select count() from AccountTeamMember where CreatorIsSysAdmin__c=false]);
       
      Test.startTest();
      AccountCurrentClientBatch accb = new AccountCurrentClientBatch();
      accb.mode=AccountCurrentClientBatch.MODE_ATM;
      Database.executeBatch(accb,10);
      Test.stopTest();

      System.assertEquals(0,[select count() from AccountTeamMember where CreatedById=:reps[1].Id]);
      System.assertEquals(2,[select count() from AccountTeamMember where CreatedById=:UserInfo.getUserId()]);

   } // testAccountTeams
   
   static testMethod void testScheduler() {
      TestHelper.testScheduler('TestAccountCurrentClientBatch', new AccountCurrentClientBatch());
   } // testScheduler
   
} // class AccountCurrentClientBatchTest