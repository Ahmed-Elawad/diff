/* 
 * Test methods for the AcctEmployeeBatch Process
 *
 * History
 * -------
 * 03/31/2016 Jacob Hinds       Created
   08/19/2019 Dan Carmen        Allow to set different sales orgs for each month (to split up so don't all run at once)
   06/23/2020 Dan Carmen        Changes due to new zip segment handling

 */
@isTest
public with sharing class AcctEmployeeBatchTest {
   
   @testSetup
   public static void setupData() {
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(name = AcctEmployeeBatch.CLASS_NAME, Active__c = true, BatchSize__c=100);
      insert abc;
      
      String monthNbr = String.valueOf(DateTime.now().Month());
      SalesOrg__c so1 = new SalesOrg__c(Name='PAY', HasOwnership__c=true, BatchMonthNumbers__c=monthNbr);
      SalesOrg__c so2 = new SalesOrg__c(Name='MMS', HasOwnership__c=true, BatchMonthNumbers__c=monthNbr);
      SalesOrg__c[] salesOrgs = new SalesOrg__c[]{so1,so2};
      insert salesOrgs;
   } // setupData
   
    static testMethod void testUpdate(){
        User[] users = [Select Id, Name, UserRoleId, UserRole.ParentRoleId 
                    ,Sales_Org__c, District__c, District_Name__c
                from User 
               where IsActive=true 
                 and Sales_Org__c=:UserHelper.SO_CORE 
                 and Profile.Name in :Utilities.REP_PROFS
               limit 2];
        User user1 = users[0];
        User user2 = users[1];
         
               
        ZipCheckOwnerTest.setupSegments();

        Zip_Assignment__c za1 = new Zip_Assignment__c(Name='11111', HR_Person_Id__c=null,Emps_Min__c=0, Emps_Max__c=99,
                                                   Asset_Min__c=0, Asset_Max__c=100,
                                                   Sales_Org__c='PAY', MC_Id__c='TestPAY',
                                                   Rep_Name__c=user1.Name,User__c=user1.Id,
                                                   Segment_Name__c=ZipCheckOwnerTest.coreSeg1.Name,
                                                   Zip_Segment__c=ZipCheckOwnerTest.coreSeg1.Id);
        Zip_Assignment__c za2 = new Zip_Assignment__c(Name='11111', HR_Person_Id__c=null,Emps_Min__c=100, Emps_Max__c=9999,
                                                   Asset_Min__c=0, Asset_Max__c=100,
                                                   Sales_Org__c='PAY', MC_Id__c='TestPAY',
                                                   Rep_Name__c=user2.Name,User__c=user2.Id,
                                                   Segment_Name__c=ZipCheckOwnerTest.coreSeg2.Name,
                                                   Zip_Segment__c=ZipCheckOwnerTest.coreSeg2.Id);
        Zip_Assignment__c[] zas = new Zip_Assignment__c[]{za1,za2};                                           
        insert zas;
        
        Test.startTest();
        AcctEmployeeBatch aeb = new AcctEmployeeBatch();
        Database.executeBatch(aeb,10);
        Test.stopTest();
        
        Id[] zipIds = new Id[]{za1.Id,za2.Id};
        Zip_Assignment_Change__c[] zipChanges = [SELECT Id,Zip_Assignment__c,Processed__c FROM Zip_Assignment_Change__c WHERE Zip_Assignment__c in :zipIds];
        system.debug('zips:'+zipChanges);   
        system.assertEquals(3,zipChanges.size());
    }

   static testMethod void testScheduler() {
      TestHelper.testScheduler('TestAcctEmployeeBatch', new AcctEmployeeBatch());
   } // testScheduler


}//AcctEmployeeBatchTest