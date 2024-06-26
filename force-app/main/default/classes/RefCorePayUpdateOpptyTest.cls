/** 
 * The test methods for the RefCorePayUpdateOppty class and trigger.
 *
 * History
 * -------
 * 06/28/2010 Dan Carmen   Created
 * 10/07/2010 Dan Carmen   Removed code checking for load complete flag.
 * 05/29/2015 Jacob Hinds    Added Reason Won/Lost to test oppty to pass validation rule
 * 01/12/2016 Jacob Hinds    Adding in NCS_Name__c to OtherValues test.
   02/11/2016 Dan Carmen     Removed NCS_Name__c from the test, adjust test that is failing.
   03/06/2016 Cindy Freeman  Removed Returning Lost Client from tests
   10/29/2018 Dan Carmen     Changed the StageName exclusions to be a label.
   07/08/2019 Dan Carmen     Change for Core Sales profile move
   05/17/2023 Dan Carmen     Add check for CEID and CAID
   10/16/2023 Dan Carmen     Add getOpsUser query since profile changed.
   12/1/2023 Susmitha Somavarapu Added a new logic to create a new contact CallerName NotFound when it doesn't find the CallerName field value(APR0162106)

 */
@isTest
public class RefCorePayUpdateOpptyTest {
    
   public static User getOpsUser() {
      User[] users = [Select Id from User where IsActive=true and Profile.Name=:Label.Profile_TestOppsUser limit 1];
      User oppsUser = (!users.isEmpty() ? users[0] : null);
       
      if (oppsUser == null) {
         System.debug('getOpsUser could NOT find a user with Profile name of '+Label.Profile_TestOppsUser);
         oppsUser = [Select Id from User where IsActive=true and UserType='Standard' and Job_Name__c=null limit 1];
      }
      return oppsUser;
   } // getOpsUser
    
   public static Id createSoldOppty() {
      // create an account
      Account acct = new Account(Name='Test Acct');
      insert acct;
      // create a contact
      Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id);
      insert ctct;
      Contact ctct1 = new Contact(FirstName='CallerName', LastName='NotFound', AccountId=acct.Id);
      insert ctct1;
      // create a core opportunity
      RecordType coreOpptyRt = AccountHelper.getRecordType('Core Opportunity Record Type','Opportunity');
      Opportunity oppty = new Opportunity(Name='Test Opporty', RecordTypeId=coreOpptyRt.Id,AccountId=acct.Id
                                         ,Prod_Payroll__c=true
                                         ,StageName='Pending'
                                         ,CloseDate=Date.today().addDays(30));
      insert oppty;
      // link the contact to the opportunity
      OpportunityContactRole ocr = new OpportunityContactRole(ContactId=ctct.Id, OpportunityId=oppty.Id, IsPrimary=true);
      insert ocr;
       
      oppty.TotalOpportunityQuantity = 1;      
      oppty.Employees_Paid_Per_Payroll__c = 2;      
      oppty.Frequency__c = '1';      
      oppty.Amount = 100;
      oppty.StageName = 'Sold';
      oppty.Service_Location__c = 'Foxboro Branch 0008';
      oppty.Payroll_Units__c = 1;
      oppty.Reason_Not_Sold__c = 'API';
      Test.startTest();
      update oppty;
      Test.stopTest();
      oppty = [Select Id, StageName, RecordType.Name
                             from Opportunity
                            where Id = :oppty.Id];
      System.assertEquals('Sold',oppty.StageName);
      System.assertEquals('Core Opportunity Record Type',oppty.RecordType.Name);
      // update the owner on the case to a Field Ops owner
      User opsUser = getOpsUser();
      Case c = null;
      try {
         c = [Select Id, ContactId ,AccountId 
                         ,Service_Location__c
                         ,RecordType.Name
                         ,OwnerId
                         ,Owner.Name
                     from case
                    where AccountId = :acct.Id];
         System.debug('createSoldOppty c='+c);
      } catch (Exception e) {
         Schema.RecordTypeInfo coreCaseRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_CASE_CORE,'Case');
         /*
                  Case thisCase = new Case(ContactId = ctctId //opptyCtctMap.get(oppty.Id)
                             ,AccountId = oppty.AccountId
                             ,Service_Location__c = oppty.Service_Location__c
                             ,User__c = oppty.OwnerId
                             ,Opportunity__c = oppty.Id
                             );
         */
         c = new Case(ContactId = ctct.Id, OwnerId=opsUser.Id, AccountId=acct.Id, RecordTypeId=coreCaseRt.getRecordTypeId()
                     ,Opportunity__c = oppty.Id, Service_Location__c=oppty.Service_Location__c, Origin = 'New Business'
                      );
         Group que = new UserHelper().getQueue('Core Payroll NCS Queue');
         if (que != null) {
            c.OwnerId = que.Id;
         }
         insert c;
      }
      //System.runAs(opsUser) {
         
         c.OwnerId = opsUser.Id;
         update c;
      //} // System.runAs
      return oppty.Id;
   } // createSoldOppty

   static Reference_Core_Payroll__c getRcp(Id opptyId) {
      Reference_Core_Payroll__c rcp = [Select Id
                                             ,OwnerId
                                             ,Add_l_ID_Added__c
                                             ,Case_Lookup__c
                                             ,Change_of_Ownership__c
                                             ,Client_Load_Received__c
                                             ,Discount_Percentage__c
                                             ,Discount_Period__c
                                             ,Discount_Type__c
                                             ,Discount2_Period__c
                                             ,Discount2_Percentage__c
                                             ,Discount2_Type__c
                                             ,Frequency__c
                                             ,Multi_Frequency__c
                                             ,NCS_Verified__c
                                             ,New_Prospect_Client_Number__c
                                             ,Number_of_Employees__c
                                             ,Opportunity_Lookup__c
                                             ,Opportunity_Lookup__r.AccountId
                                             ,Other_Credit__c
                                             ,Other_Credit_Reason__c
                                             ,Returning_Lost_Client__c
                                             ,Payroll_Run_Date__c
                                         from Reference_Core_Payroll__c
                                        where Opportunity_Lookup__c = :opptyId];
      return rcp;
   } // getRcp
   
   static testMethod void testLoadReceived() {
      Id opptyId = createSoldOppty();
      Reference_Core_Payroll__c rcp = getRcp(opptyId);

      // verify current values
      System.assertEquals(false,rcp.Client_Load_Received__c);
      // set to true
      rcp.Client_Load_Received__c = true;
      update rcp;
      Opportunity oppty = [Select Id, StageName, RecordType.Name
                             from Opportunity
                            where Id = :opptyId];
      System.assertEquals('Sold - Submitted',oppty.StageName);
      System.assertEquals('Core Opportunity DSA Record Type',oppty.RecordType.Name);
   } // testLoadReceived
   
    /*
   static testMethod void testReturnLost() {
      Id opptyId = createSoldOppty();
      Reference_Core_Payroll__c rcp = getRcp(opptyId);

      // verify current values
      System.assertEquals(false,rcp.Returning_Lost_Client__c);
      // set to true
      rcp.Returning_Lost_Client__c = true;
      update rcp;
      Opportunity oppty = [Select Id, StageName, RecordType.Name
                                 ,Returning_Lost_Client__c
                             from Opportunity
                            where Id = :opptyId];
      System.assertEquals(true,oppty.Returning_Lost_Client__c);
   } // testReturnLost
   */
    
   static testMethod void testRunDate() {
      Id opptyId = createSoldOppty();
      Reference_Core_Payroll__c rcp = getRcp(opptyId);
       Opportunity oppty = [Select Id, StageName, RecordType.Name, OpportunityType__c, CloseDate
                            from Opportunity
                            where Id = :opptyId];
       oppty.OpportunityType__c = 'Payroll';
       oppty.CloseDate = Date.today().addDays(-30);
       update oppty;
       
      // verify current values
      System.assertEquals(null,rcp.Payroll_Run_Date__c);
      // set to true
      rcp.Payroll_Run_Date__c = Date.today().addDays(10);
      rcp.Date_Client_Load_Complete__c = Date.today().addDays(1);
      rcp.Client_Load_Complete__c = true;
      rcp.Date_Client_Load_Received__c = Date.today();
      rcp.Client_Load_Received__c = true;
      rcp.Caller_Name__c ='Test Contacts';
      update rcp;
      Opportunity oppty1 = [Select Id, StageName, RecordType.Name
                                 ,CloseDate
                             from Opportunity
                            where Id = :opptyId];
      System.assertEquals('Sold - Started',oppty1.StageName);
      System.assertEquals(rcp.Payroll_Run_Date__c,oppty1.CloseDate);
   } // testRunDate
   
   static testMethod void testOtherValues() {
      Id opptyId = createSoldOppty();
      Reference_Core_Payroll__c rcp = getRcp(opptyId);

      // verify current values
      System.assertEquals(false,rcp.Returning_Lost_Client__c);
      System.assertEquals(null,rcp.Number_of_Employees__c);
      System.assertEquals(null,rcp.Frequency__c);
      System.assertEquals(null,rcp.Discount_Type__c);
      System.assertEquals(null,rcp.Discount_Percentage__c);
      System.assertEquals(null,rcp.Discount_Period__c);
      System.assertEquals(null,rcp.Discount2_Type__c);
      System.assertEquals(null,rcp.Discount2_Period__c);
      System.assertEquals(null,rcp.Discount2_Percentage__c);
      System.assertEquals(false,rcp.Multi_Frequency__c);
      System.assertEquals(false,rcp.Change_of_Ownership__c);
      System.assertEquals(false,rcp.Add_l_ID_Added__c);
      System.assertEquals(false,rcp.Other_Credit__c);
      System.assertEquals(null,rcp.Other_Credit_Reason__c);
      System.assertEquals(false,rcp.NCS_Verified__c);

      // update values
      rcp.Returning_Lost_Client__c = true;
      rcp.Number_of_Employees__c = 10;
      rcp.Frequency__c = '1';
      rcp.Discount_Type__c = 'WIN';
      rcp.Discount_Percentage__c = 50;
      rcp.Discount_Period__c = '6';
      rcp.Discount2_Type__c = 'WIN';
      rcp.Discount2_Period__c = '3';
      rcp.Discount2_Percentage__c = 25;
      rcp.Multi_Frequency__c = true;
      rcp.Change_of_Ownership__c = true;
      rcp.Add_l_ID_Added__c = true;
      rcp.Other_Credit__c = true;
      rcp.Other_Credit_Reason__c = 'For a Test'; 
      rcp.NCS_Verified__c = true;
      update rcp;
      Opportunity oppty = [Select Id, StageName, RecordType.Name
                                 ,Returning_Lost_Client__c
                                 ,Employees_Paid_Per_Payroll__c
                                 ,Frequency__c
                                 ,WIN_Check__c
                                 ,WIN__c
                                 ,Discount_Period__c
                                 ,Discount2_Type__c
                                 ,Discount2_Period__c
                                 ,Discount2_Percentage__c
                                 ,Multi_Frequency__c
                                 ,Change_of_Ownership__c
                                 ,Add_l_ID_added__c
                                 ,Other_credit__c
                                 ,Other_credit_reason__c
                                 ,NCS_Approved__c
                             from Opportunity
                            where Id = :opptyId];

      // test values.
      System.assertEquals(false,oppty.Returning_Lost_Client__c);
      System.assertEquals(10,oppty.Employees_Paid_Per_Payroll__c);
      System.assertEquals('1',oppty.Frequency__c);
      System.assertEquals('WIN',oppty.WIN_Check__c);
      System.assertEquals(50,oppty.WIN__c);
      System.assertEquals('6',oppty.Discount_Period__c);
      System.assertEquals('WIN',oppty.Discount2_Type__c);
      System.assertEquals('3',oppty.Discount2_Period__c);
      System.assertEquals(25,oppty.Discount2_Percentage__c);
      System.assertEquals(true,oppty.Multi_Frequency__c);
      System.assertEquals(true,oppty.Change_of_Ownership__c);
      System.assertEquals(true,oppty.Add_l_ID_added__c);
      System.assertEquals(true,oppty.Other_Credit__c);
      System.assertEquals('For a Test',oppty.Other_credit_reason__c);
      System.assertEquals(true,oppty.NCS_Approved__c);
      

   } // testRunDate
   
   static testMethod void testCltNbr() {
      Id opptyId = createSoldOppty();
      Reference_Core_Payroll__c rcp = getRcp(opptyId);

      // verify current values
      Assert.isNull(rcp.New_Prospect_Client_Number__c);
      // set to true
      rcp.New_Prospect_Client_Number__c = '17-TEST1234';
      rcp.CEID__c='00H2A1IULFS7P13O006M';
      rcp.CAID__c='00HWYNTDLFS7P1RU4W56';
      update rcp;
      Account acct = [Select Id, AccountNumber, Paychex_CEID__c, Paychex_CAID__c
                        from Account
                       where Id = :rcp.Opportunity_Lookup__r.AccountId];
                       
      Assert.areEqual('17-TEST1234',acct.AccountNumber);
      Assert.areEqual('00H2A1IULFS7P13O006M',acct.Paychex_CEID__c);
      Assert.areEqual('00HWYNTDLFS7P1RU4W56',acct.Paychex_CAID__c);
       
   } // testCltNbr
   
   /** Test a failure as a result of a validation rule.
    */
   static testMethod void testFailure() {
      // create record as system administrator
      User sysAdmin = [Select Id from User where Profile.Name='System Administrator' and IsActive=true limit 1];
      User coreUser = [Select Id from User where Profile.Name in :Utilities.CORE_PROFS and IsActive=true limit 1];
      Id opptyId = null;
      //System.runAs(coreUser) {
      System.runAs(sysAdmin) {
         opptyId = createSoldOppty();
      }
      System.runAs(sysAdmin) {
         // update opportunity so discount fails validation rule.
         Opportunity oppty = [Select Id, WIN__c from Opportunity where Id = :opptyId];
         oppty.WIN__c = 150;
         update oppty;
      } // System.runAs
      
      User opsUser = getOpsUser();
          //[Select Id from User where IsActive=true and Profile.Name='Field Ops New Load Specialist' limit 1];
      //Reference_Core_Payroll__c rcp = getRcp(opptyId);
      
      System.runAs(opsUser) {
         Reference_Core_Payroll__c rcp = getRcp(opptyId);
         // update a value - validation rule should fire causing the update to fail.
         rcp.Client_Load_Received__c = true;
         try {
            update rcp;
         } catch (DmlException de) {
            System.assertEquals(true,de.getMessage().contains('Error while attempting to update the Opportunity:'));
         }
         
      }
   } // testFailure
   
} // class RefCorePayUpdateOpptyTest