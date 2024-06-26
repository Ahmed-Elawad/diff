/** Test methods for the AccountCloneController class
 *
 * History
 * -------
 * 09/28/2012 Dan Carmen   Created
   11/06/2012 Dan Carmen   Added in logic for maintaining existing multi-ids
   01/15/2013 Dan Carmen   Added HRO specific logic (from previous version of account clone)
   10/17/2013 Dan Carmen   Changed to without sharing.
   03/31/2016 Dan Carmen   Added Prospect Ownership information into the clone
   03/27/2017 Cindy Freeman		changed to use Employees__c instead of NumberOfEmployees
   04/04/2017 Cindy Freeman		changed to set SalesParent on cloned accounts
   04/01/2020 Carrie Marciano updated to test for Multi-Id relationships used in Oracle CPQ
   09/03/2021 Josh Cartwright added limit to the number of child accts displayed and a message when the count is over the limit
   08/01/2023 Dan Carmen      Increment API, adjust tests to pass
   09/06/2023 Dan Carmen      Change to always set the SalesParent__c on the children and SalesParentChild__c on the junction
   10/02/2023 Dan Carmen      Fix for saving account junctions - was not accounting for updates

*/
@isTest
private class AccountCloneControllerTest {

   @testSetup
   public static void setupData() {
      populateSettings();
   } // setupData
   
   // Test if no account is passed in.
   static testMethod void testNoAccount() {
      Test.SetCurrentPageReference(Page.AccountClone);
      //System.CurrentPageReference().getParameters().put('id',cgsChild.Id);
      ApexPages.Standardcontroller sc = New ApexPages.StandardController(new Account());
      AccountCloneController acc = new AccountCloneController(sc);
      System.assertEquals(false,acc.okayToProceed);

      acc.runningMode = AccountCloneController.MODE_MMS;
      System.assertEquals(null,acc.changeRunningMode());

      System.assertEquals(true,ApexPages.hasMessages());
      ApexPages.Message msg = ApexPages.getMessages().get(0);
      System.assertEquals('A valid Prospect-Client was not found. Cannot proceed!',msg.getDetail() );
   } // testNoAccount

   // Test adding and removing clone records.
   static testMethod void testAddLimits() {
      // create the source account
      //Account acct = new Account(Name='Test Account0',AccountNumber='1234-TEST0123', NumberOfEmployees=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
      Account acct = new Account(Name='Test Account0',AccountNumber='1234-TEST0123', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
      insert acct;
      
      Test.SetCurrentPageReference(Page.AccountClone);
      System.CurrentPageReference().getParameters().put('Id',acct.Id);
      // make sure set to start with 2 records
      AccountCloneController.NBR_TO_START = 2;
      
      ApexPages.Standardcontroller sc = New ApexPages.StandardController(acct);
      AccountCloneController acc = new AccountCloneController(sc);
      
      acc.runningMode = AccountCloneController.MODE_MMS;
      System.assertEquals(null,acc.changeRunningMode());

      System.assertEquals(true,acc.okayToProceed);
      System.assertEquals(false,ApexPages.hasMessages());
      
      // try to go above the maximum
      acc.nbrCloneRecords = AccountCloneController.MAX_CLONE+2;
      System.assertEquals(null,acc.changeNbrAccounts());

      System.assertEquals(true,ApexPages.hasMessages());
      ApexPages.Message msg = ApexPages.getMessages().get(0);
      System.assertEquals('You are only allowed to clone up to '+AccountCloneController.MAX_CLONE+' Prospect-Clients.',msg.getDetail());
      System.assertEquals(AccountCloneController.MAX_CLONE+1,acc.accts.size());
      
      // drop down to 5 records
      acc.nbrCloneRecords = 5;
      System.assertEquals(null,acc.changeNbrAccounts());
      System.assertEquals(6,acc.accts.size());


      // try to drop down to 0
      acc.nbrCloneRecords = -1;
      System.assertEquals(null,acc.changeNbrAccounts());
      System.assertEquals(1,acc.accts.size());

      System.assertEquals(true,ApexPages.hasMessages());
      msg = ApexPages.getMessages().get(1);
      System.assertEquals('Please enter a number greater than 0.',msg.getDetail());
      
   } // testAddLimits

   static testMethod void testAccountClone() {
      // create the source account
      Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
      //Account acct = new Account(Name='Test Account0',AccountNumber='1234-TEST0123', NumberOfEmployees=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
      Account acct = new Account(Name='Test Account0',recordtypeId = acctCorert.getRecordTypeId(),AccountNumber='1234-TEST0123', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
      // this one will be used for duplicate checking
      Account acctDup = new Account(Name='Test Account',AccountNumber='1234-TESTDUPE');
      Account[] accts = new Account[]{acct,acctDup};
      insert accts;
      
      // get the core record type - have to set the record type because of the Sales_Contact__c flag.
      Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');

      // create contacts
      Contact ctct1 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest1',Email='firstTest1@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
      Contact ctct2 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest2',Email='firstTest2@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
      Contact ctct3 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest3',Email='firstTest3@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
      Contact ctct4 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest4',Email='firstTest4@test.com',Sales_Contact__c=false);
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;
      
      // create account contact roles
      AccountContactRole acr1 = new AccountContactRole(AccountId=acct.Id,ContactId=ctct1.Id,IsPrimary=true,Role='Other');
      AccountContactRole acr2 = new AccountContactRole(AccountId=acct.Id,ContactId=ctct2.Id,IsPrimary=false,Role='Other');
      AccountContactRole acr3 = new AccountContactRole(AccountId=acct.Id,ContactId=ctct3.Id,IsPrimary=false,Role='Other');
      AccountContactRole acr4 = new AccountContactRole(AccountId=acct.Id,ContactId=ctct4.Id,IsPrimary=false,Role='Other');
      AccountContactRole[] acrs = new AccountContactRole[]{acr1,acr2,acr3,acr4};
      insert acrs;
      
      User[] nsrUsers = ProspectOwnershipMethodsTest.getOutboundNSRs(2);
      Prospect_Ownership__c po1 = new Prospect_Ownership__c(Prospect_Client__c=acct.Id, NSR_Name__c=nsrUsers[0].Id, CommissionStart__c=Date.today().addDays(-30), CommissionEnd__c=Date.today().addDays(30)
                                                     ,Decision_Maker__c=ctct1.Id, NSS_Source__c='Outbound',NSS_Team__c=UserHelper.SO_CORE, Ownership_Status__c=ProspectOwnershipMethods.STAGE_COMMISSION);
      // this one should fall outside of the selection range
      Prospect_Ownership__c po2 = new Prospect_Ownership__c(Prospect_Client__c=acct.Id, NSR_Name__c=nsrUsers[1].Id, CommissionStart__c=Date.today().addDays(-100), CommissionEnd__c=Date.today().addDays(-60)
                                                     ,Decision_Maker__c=ctct1.Id, NSS_Source__c='Outbound',NSS_Team__c=UserHelper.SO_CORE, Ownership_Status__c=ProspectOwnershipMethods.STAGE_COMMISSION);
      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{po1,po2};
      insert pos;
      
      // create opportunities
      Opportunity opp1 = new Opportunity(Name='Test Opp1',CloseDate=Date.today().addDays(7),StageName='Sold',Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id); 
      Opportunity opp2 = new Opportunity(Name='Test Opp2',CloseDate=Date.today().addDays(7),StageName='Sold',Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id); 
      Opportunity opp3 = new Opportunity(Name='Test Opp3',CloseDate=Date.today().addDays(7),StageName='Sold',Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id); 
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3};
      insert opps;
      
      // todo - create opportunity products? have to use see all data for this one.
      
      // create opportunity contact roles
      OpportunityContactRole ocr1 = new OpportunityContactRole(OpportunityId=opp1.Id,ContactId=ctct1.Id,IsPrimary=true,Role='Other');
      OpportunityContactRole ocr2 = new OpportunityContactRole(OpportunityId=opp2.Id,ContactId=ctct2.Id,IsPrimary=true,Role='Other');
      OpportunityContactRole ocr3 = new OpportunityContactRole(OpportunityId=opp3.Id,ContactId=ctct3.Id,IsPrimary=true,Role='Other');
      OpportunityContactRole[] ocrs = new OpportunityContactRole[]{ocr1,ocr2,ocr3};
      insert ocrs;
      
      // select users to make team members.
      User[] users = [Select Id, Name from User where IsActive=true and Id != :UserInfo.getUserId() and Sales_Org__c in :UserHelper.DIVISION_LIST limit 3];
      OpportunityTeamMember otm1 = new OpportunityTeamMember(OpportunityId=opp1.Id,UserId=users[0].Id,TeamMemberRole='Test Role');
      OpportunityTeamMember otm2 = new OpportunityTeamMember(OpportunityId=opp2.Id,UserId=users[1].Id,TeamMemberRole='Test Role');
      OpportunityTeamMember otm3 = new OpportunityTeamMember(OpportunityId=opp3.Id,UserId=nsrUsers[0].Id,TeamMemberRole=OpptyMethods.ROLE_NSR,NSS_Source__c=po1.NSS_Source__c,NSS_Team__c=po1.NSS_Team__c, Prospect_Ownership__c=po1.Id);
      OpportunityTeamMember[] otms = new OpportunityTeamMember[]{otm1,otm2,otm3};
      insert otms;
      
      Test.SetCurrentPageReference(Page.AccountClone);
      System.CurrentPageReference().getParameters().put('Id',acct.Id);
      // make sure set to start with 2 records
      AccountCloneController.NBR_TO_START = 2;
      
      ApexPages.Standardcontroller sc = New ApexPages.StandardController(acct);
      AccountCloneController acc = new AccountCloneController(sc);
      
      acc.runningMode = AccountCloneController.MODE_MMS;
      System.assertEquals(null,acc.changeRunningMode());
      System.assertEquals(false,acc.isModeHRO);
      
      System.assertEquals(true,acc.okayToProceed);
      System.assertEquals(false,ApexPages.hasMessages());

      // verify the step
      System.assertEquals(AccountCloneController.STEP1,acc.currentStep);
       
      // verify it sees the accounts and contacts
      System.assertEquals(true,acc.hasOpptys);
      System.assertEquals(true,acc.hasCtcts);
      
      // verify number of records - 2 to start plus parent
      System.assertEquals(3,acc.accts.size());
      System.assertEquals(3,acc.ctcts.size());
      System.assertEquals(3,acc.opptys.size());
      
      // proceed with no accounts entered.
      System.assertEquals(null,acc.nextStep());
      // this next one should trigger an error since a quantity wasn't entered - returned to first page
      System.assertEquals(AccountCloneController.STEP1,acc.currentStep);

      System.assertEquals(true,ApexPages.hasMessages());
      // check the latest message
      ApexPages.Message msg = ApexPages.getMessages()[0];
      System.assertEquals('Enter the Number of Employees',msg.getDetail() );
      

      // enter information for some of the records.
      // check to make sure the first is the primary record.
      AccountCloneController.AccountWrapper aw0 = acc.accts[0];
      System.assertEquals(true,aw0.isParent);
      AccountCloneController.AccountWrapper aw1 = acc.accts[1];
      // enter an invalid account number
      aw1.acct.AccountNumber='Test';
      aw1.acct.Employees__c = 1;
      aw1.acct.Name='Test Account1';
      AccountCloneController.AccountWrapper aw2 = acc.accts[2];
      // enter a valid account number and a blank number of employees
      aw2.acct.AccountNumber='1234-TEST2345';
      aw2.acct.Employees__c = null;
      aw2.acct.Name='Test Account2';
      
      // move to the validate step. Should generate four errors
      System.assertEquals(null,acc.nextStep());
      // should be back at first step
      System.assertEquals(AccountCloneController.STEP1,acc.currentStep);
      // verify 2 distinct messages - new messages are only added if they're different.
      System.assertEquals(2,ApexPages.getMessages().size());

      // verify messages
      msg = ApexPages.getMessages()[1];
      System.assertEquals('The Prospect-Client Number you entered is not in a valid format!',msg.getDetail() );
      msg = ApexPages.getMessages()[0];
      System.assertEquals('Enter the Number of Employees',msg.getDetail() );
      
      // fix the errors, but add in a duplicate client number
      aw1.acct.AccountNumber='1234-TEST2345';
      aw2.acct.Employees__c=2;
      
      // move to the validate step. Should generate an error for a duplicate
      System.assertEquals(null,acc.nextStep());

      // should be back at first step
      System.assertEquals(AccountCloneController.STEP1,acc.currentStep);
      System.assertEquals(3,ApexPages.getMessages().size());
      
      msg = ApexPages.getMessages()[2];
      System.assertEquals('This Prospect-Client Number has already been entered!',msg.getDetail() );

      // change the client number to be a duplicate of a record in the database
      aw1.acct.AccountNumber='1234-TESTDUPE';
      // move to the validate step. Should generate an error for a duplicate
      System.assertEquals(null,acc.nextStep());
      // should be back at first step
      System.assertEquals(AccountCloneController.STEP1,acc.currentStep);
      System.assertEquals(4,ApexPages.getMessages().size());

      msg = ApexPages.getMessages()[ApexPages.getMessages().size()-1];
      System.assertEquals('An existing record was found in the database with this Branch-Client Number!',msg.getDetail() );

      // change the client number to be a unique value
      aw1.acct.AccountNumber='1234-TEST3456';

      // move to the validate step. should be okay now
      System.assertEquals(null,acc.nextStep());
      System.assertEquals(null,acc.nextStep());
      // should be at the verify step
      System.assertEquals(AccountCloneController.STEP_VERIFY,acc.currentStep);

      // move back to the first page
      System.assertEquals(null,acc.previousStep());
      System.assertEquals(null,acc.previousStep());
      // should be back at first step
      System.assertEquals(AccountCloneController.STEP1,acc.currentStep);
      
      // change number of records to clone to 4
      acc.nbrCloneRecords = 4;
      System.assertEquals(null,acc.changeNbrAccounts());
      // should be five records now (including the parent)
      System.assertEquals(5,acc.accts.size());
      
      // add in a couple more records and make them a combo - do not set the primary
      AccountCloneController.AccountWrapper aw3 = acc.accts[3];
      AccountCloneController.AccountWrapper aw4 = acc.accts[4];
      
      aw0.comboIndicator = 'Group 1';
      aw0.acct.Consolidate_Primary__c = false;
      
      aw3.acct.AccountNumber = '1234-TEST4567';
      aw3.acct.Employees__c = 3;
      aw3.comboIndicator = 'Group 1';
      aw3.acct.Name='Test Account3';
      aw3.acct.Consolidate_Primary__c = false;

      aw4.acct.AccountNumber = '1234-TEST5678';
      aw4.acct.Employees__c = 4;
      aw4.comboIndicator = 'Group 1';
      aw4.acct.Name='Test Account4';
      aw4.acct.Consolidate_Primary__c = false;

      // move to the validate step. Should generate an error for a not having a primary in the combo
      System.assertEquals(null,acc.nextStep());
      // should be back at first step
      System.assertEquals(AccountCloneController.STEP1,acc.currentStep);
      System.assertEquals(5,ApexPages.getMessages().size());

      msg = ApexPages.getMessages()[4];
      System.assertEquals('Group 1 does not have a Primary defined!',msg.getDetail() );

      // set all to be the primary - should still be an error
      aw0.acct.Consolidate_Primary__c = true;
      aw3.acct.Consolidate_Primary__c = true;
      aw4.acct.Consolidate_Primary__c = true;
      
      System.assertEquals(null,acc.nextStep());
      // should be back at first step
      System.assertEquals(AccountCloneController.STEP1,acc.currentStep);
      System.assertEquals(6,ApexPages.getMessages().size());

      msg = ApexPages.getMessages()[5];
      System.assertEquals('More than one primary was defined for Group 1! Each combo has to have only 1 primary.',msg.getDetail() );

      // set the parent to be the primary
      aw0.acct.Consolidate_Primary__c = true;
      aw3.acct.Consolidate_Primary__c = false;
      aw4.acct.Consolidate_Primary__c = false;

      // move to the validate step. Should be okay now.
      System.assertEquals(null,acc.nextStep());
      System.assertEquals(null,acc.nextStep());
      // should be at the verify step
      System.assertEquals(AccountCloneController.STEP_VERIFY,acc.currentStep);
      // should be one extra message - to say it had to change the name.
      System.assertEquals(7,ApexPages.getMessages().size());
      
      System.assertEquals(false,acc.hasSelectedCtcts);
      System.assertEquals(false,acc.hasSelectedOpptys);
      
      // go back a step to select contacts
      System.assertEquals(null,acc.previousStep());
      System.assertEquals(AccountCloneController.STEP2,acc.currentStep);
      
      // select two of the contacts
      AccountCloneController.ContactWrapper cw0 = acc.ctcts[0];
      AccountCloneController.ContactWrapper cw1 = acc.ctcts[1];
      cw0.selected = true;
      cw1.selected = true;
      
      // select two opps
      AccountCloneController.OpportunityWrapper ow0 = acc.opptys[0];
      AccountCloneController.OpportunityWrapper ow1 = acc.opptys[1];
      ow0.selected = true;
      ow1.selected = true;
      
      // go to the verify step
      System.assertEquals(null,acc.nextStep());
      // should be at the verify step
      System.assertEquals(AccountCloneController.STEP_VERIFY,acc.currentStep);
      
      // contacts and opportunities are selected
      System.assertEquals(5,acc.accts.size());
      System.assertEquals(2,acc.selectedCtcts.size());
      System.assertEquals(2,acc.selectedOpptys.size());
      System.assertEquals(true,acc.hasSelectedCtcts);
      System.assertEquals(true,acc.hasSelectedOpptys);
      
      // verify that the non-combo and combo records have different colors for display purposes
      System.assertEquals('BLACK',aw1.styleColor);
      System.assertEquals('BLACK',aw2.styleColor);
      System.assertEquals('GREEN',aw3.styleColor);
      System.assertEquals('GREEN',aw4.styleColor);
      
      // go to the save step.
      System.assertEquals(null,acc.nextStep());
      // records should have saved
      System.assertEquals(AccountCloneController.STEP_LAST,acc.currentStep);
      // verify that accounts, contacts and opportunities were created.
      Account[] createdAccts = [Select Id
                                      ,ParentId
                                      ,(Select Id
                                          From AccountContactRoles)
                                      ,(Select Id
                                              ,Name
                                          From Contacts)
                                      ,(Select Id
                                              ,Name
                                          From Opportunities)
                                      ,(Select Id, Name
                                          From Prospect_Ownership__r)
                                  From Account
                                 Where ParentId = :acct.Id];
      System.assertEquals(4,createdAccts.size());
      for (Account checkAcct : createdAccts) {
         System.assertEquals(2,checkAcct.Contacts.size());
         System.assertEquals(2,checkAcct.Opportunities.size());
         System.assertEquals(2,checkAcct.AccountContactRoles.size());
         System.assertEquals(1,checkAcct.Prospect_Ownership__r.size());
      }
      
      // return to the account
      PageReference retUrl = acc.returnToAccount();
      System.assertEquals(true,(retUrl.getUrl().contains(acct.Id)));
      
      // use one of the children and return into the form
      Account acct1 = createdAccts[0];

      System.CurrentPageReference().getParameters().put('Id',acct1.Id);
      
      sc = New ApexPages.StandardController(acct1);
      acc = new AccountCloneController(sc);
      
      acc.runningMode = AccountCloneController.MODE_MMS;
      System.assertEquals(null,acc.changeRunningMode());
      System.assertEquals(false,acc.isModeHRO);
      
      System.assertEquals(true,acc.okayToProceed);
      
      // this will default to 0 since we're entering with a pre-existing structure
      System.assertEquals(0,acc.nbrCloneRecords);
      System.assertEquals(5,acc.accts.size());
      // the process should have found the parent and defaulted to that as the main record.
      System.assertEquals(acct.Id, acc.acct.Id);
      
      System.assertEquals(true,acc.hasExistingChild);
      // we are currently only modifying existing records
      System.assertEquals(true,acc.onlyModifyingExisting);
      System.assertEquals(true,acc.checkAccounts());	
      
      // when we go to the next step, will skip to the verify step since we're not adding records.
      System.assertEquals(null,acc.nextStep());
      // should be at the verify step
      System.assertEquals(AccountCloneController.STEP_VERIFY,acc.currentStep);

      // previous should go back to step 1
      System.assertEquals(null,acc.previousStep());
      // should be at the verify step
      System.assertEquals(AccountCloneController.STEP1,acc.currentStep);
      
      // cancel the current operation - should return to the parent account instead of the account we entered with
      retUrl = acc.returnToAccount();
      System.assertEquals(true,(retUrl.getUrl().contains(acct.Id)));

      // reenter the form.
      System.CurrentPageReference().getParameters().put('Id',acct1.Id);
      
      sc = New ApexPages.StandardController(acct1);
      acc = new AccountCloneController(sc);

      acc.runningMode = AccountCloneController.MODE_MMS;
      System.assertEquals(null,acc.changeRunningMode());
      System.assertEquals(false,acc.isModeHRO);

      System.assertEquals(true,acc.okayToProceed);
   } // testAccountClone

   static testMethod void testHierarchy() {
      // create the source account
      //Account acct = new Account(Name='Test Account0',AccountNumber='1234-TEST0123', NumberOfEmployees=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514', Combo_Client__c='T123',Consolidate_Primary__c=true );
      Account acct = new Account(Name='Test Account0',AccountNumber='1234-TEST0123', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514', Combo_Client__c='T123',Consolidate_Primary__c=true );
      insert acct;
      
      //Account acct1 = new Account(Name='Test Account1',ParentId=acct.Id,AccountNumber='1234-TEST1234', NumberOfEmployees=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514', Combo_Client__c='T123',Consolidate_Primary__c=false);
      //Account acct2 = new Account(Name='Test Account2',ParentId=acct.Id,AccountNumber='1234-TEST2345', NumberOfEmployees=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514', Combo_Client__c='T123',Consolidate_Primary__c=false);
      Account acct1 = new Account(Name='Test Account1',ParentId=acct.Id,AccountNumber='1234-TEST1234', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514', Combo_Client__c='T123',Consolidate_Primary__c=false);
      Account acct2 = new Account(Name='Test Account2',ParentId=acct.Id,AccountNumber='1234-TEST2345', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514', Combo_Client__c='T123',Consolidate_Primary__c=false);      
      Account[] accts = new Account[]{acct1,acct2};
      insert accts;
      
      // get the core record type - have to set the record type because of the Sales_Contact__c flag.
      Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');

      // create contacts
      Contact ctct1 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest1',Email='firstTest1@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
      Contact ctct2 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest2',Email='firstTest2@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      insert ctcts;
      
      // create account contact roles
      AccountContactRole acr1 = new AccountContactRole(AccountId=acct.Id,ContactId=ctct1.Id,IsPrimary=true,Role='Other');
      AccountContactRole acr2 = new AccountContactRole(AccountId=acct.Id,ContactId=ctct2.Id,IsPrimary=false,Role='Other');
      AccountContactRole[] acrs = new AccountContactRole[]{acr1,acr2};
      insert acrs;
      
      // create opportunities
      Opportunity opp1 = new Opportunity(Name='Test Opp1',CloseDate=Date.today().addDays(7),StageName='Sold',Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id); 
      Opportunity[] opps = new Opportunity[]{opp1};
      insert opps;
      
      // todo - create opportunity products? have to use see all data for this one.
      
      // create opportunity contact roles
      OpportunityContactRole ocr1 = new OpportunityContactRole(OpportunityId=opp1.Id,ContactId=ctct1.Id,IsPrimary=true,Role='Other');
      OpportunityContactRole[] ocrs = new OpportunityContactRole[]{ocr1};
      insert ocrs;
      
      Test.SetCurrentPageReference(Page.AccountClone);
      System.CurrentPageReference().getParameters().put('Id',acct1.Id);
      
      ApexPages.Standardcontroller sc = New ApexPages.StandardController(acct1);
      AccountCloneController acc = new AccountCloneController(sc);
      
      acc.runningMode = AccountCloneController.MODE_MMS;
      System.assertEquals(null,acc.changeRunningMode());
      System.assertEquals(false,acc.isModeHRO);

      // this will default to 0 since we're entering with a pre-existing structure
      System.assertEquals(0,acc.nbrCloneRecords);
      System.assertEquals(3,acc.accts.size());
      // the process should have found the parent and defaulted to that as the main record.
      System.assertEquals(acct.Id, acc.acct.Id);
      
      // we are currently only modifying existing records
      System.assertEquals(true,acc.onlyModifyingExisting);
            
      // when we go to the next step, will skip to the verify step since we're not adding records.
      System.assertEquals(null,acc.nextStep());
      // should be at the verify step
      System.assertEquals(AccountCloneController.STEP_VERIFY,acc.currentStep);

      // previous should go back to step 1
      System.assertEquals(null,acc.previousStep());
      // should be at the first step
      System.assertEquals(AccountCloneController.STEP1,acc.currentStep);
      
      // cancel the current operation - should return to the parent account instead of the account we entered with
      PageReference retUrl = acc.cancel();
      System.assertEquals(true,(retUrl.getUrl().contains(acct.Id)));

      // reenter the form.
      System.CurrentPageReference().getParameters().put('Id',acct1.Id);
      
      sc = New ApexPages.StandardController(acct1);
      acc = new AccountCloneController(sc);
      acc.runningMode = AccountCloneController.MODE_MMS;
      System.assertEquals(null,acc.changeRunningMode());
      System.assertEquals(false,acc.isModeHRO);

      System.assertEquals(true,acc.okayToProceed);

      // mark the last record for delete
      AccountCloneController.AccountWrapper aw2 = acc.accts[2];
      acc.delRecNum = aw2.curRecNum;
      System.assertEquals(null,acc.verifyDeleteRec());
      System.assertEquals(AccountCloneController.STEP_DELETE,acc.currentStep);

      // just deleting one record
      System.assertEquals(1,acc.displayAccts.size());
      
      // confirm the delete
      System.assertEquals(null,acc.deleteAccts());
      // there should now be just two records.
      System.assertEquals(2,acc.displayAccts.size());
      
      // should only be 1 child to the parent now
      System.assertEquals(1,[Select count() from Account where ParentId=:acct.Id]);
      
   } // testHierarchy

   static testMethod void testHROClone() {
      // grab a random active user for the HRO_Implementation_Coordinator
      User u1 = [Select Id, Name from User where IsActive=true and UserRoleId != null and Profile.Name != :Utilities.PROF_SYS_ADMIN limit 1];      
   
      // run as a user with an HRO role
      User hroUser = [Select Id, Name from User where IsActive=true and (UserRole.Name like 'HR Online%'
                                                                         or UserRole.Name like 'HROSC%'
                                                                         or UserRole.Name like 'Online%') limit 1];

      // create the source account
      Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
      Account acct = new Account(Name='Test Account0',AccountNumber='1234-TEST0234', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514'
      				   ,recordtypeId = acctCorert.getRecordTypeId()
                       ,HRO_Number__c='A123'
                       ,HRO_Implementation_Coordinator__c=u1.Id
                       ,HRO_NCP_Received_Date__c=Date.today()
                       ,HRO_Service_Agreement_Received__c=true
                       ,HRO_First_Run_or_New_Setup_Date__c=Date.today().addDays(5)
                       ,HRO_Preview_Hosting_Client__c=false
                       ,HRO_Group__c=true
                       ,HRO_Total_ID_s__c=3
                       ,OwnerId=hroUser.Id
                      );
      Account[] accts = new Account[]{acct};
      insert accts;
      
      // get the core record type - have to set the record type because of the Sales_Contact__c flag.
      Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');

      // create contacts
      Contact ctct1 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest1',Email='firstTest1@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
      Contact ctct2 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest2',Email='firstTest2@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      insert ctcts;
      
      // create assets
      Asset asst1 = new Asset(AccountId=acct.Id, Name='Asset 1',Product_Plan_Code__c='Asset1', Start_Date__c=Date.today(), Product_End_Date__c=null, PurchaseDate=Date.today());      
      Asset asst2 = new Asset(AccountId=acct.Id, Name='Asset 2',Product_Plan_Code__c='Asset2', Start_Date__c=Date.today(), Product_End_Date__c=null, PurchaseDate=Date.today());      
      Asset[] assets = new Asset[]{asst1,asst2};
      insert assets;
      
      System.runAs(hroUser) {                                                                    
         System.debug('testHROClone acct.Id='+acct.Id);
         Test.SetCurrentPageReference(Page.AccountClone);
         System.CurrentPageReference().getParameters().put('Id',acct.Id);
         
         // make sure set to start with 2 records
         AccountCloneController.NBR_TO_START = 2;
      
         ApexPages.Standardcontroller sc = New ApexPages.StandardController(acct);
         AccountCloneController acc = new AccountCloneController(sc);
      
         System.assertEquals(true,acc.isModeHRO);
         
         // verify the step
         System.assertEquals(AccountCloneController.STEP1,acc.currentStep);
       
         // verify it sees the contacts and assets
         System.assertEquals(true,acc.hasCtcts);
         System.assertEquals(true,acc.hasAssets);
      
         // verify number of records - 2 to start plus parent
         System.assertEquals(3,acc.accts.size());
         System.assertEquals(2,acc.ctcts.size());
         System.assertEquals(2,acc.assets.size());
      
      
         // enter information for the two records that are there by default.
         // check to make sure the first is the primary record.
         AccountCloneController.AccountWrapper aw0 = acc.accts[0];
         System.assertEquals(true,aw0.isParent);
         AccountCloneController.AccountWrapper aw1 = acc.accts[1];
         // enter info for copy1
         aw1.acct.AccountNumber='1234-TEST1234';
         aw1.acct.Employees__c = 1;
         aw1.acct.Name='Test Account1';
         AccountCloneController.AccountWrapper aw2 = acc.accts[2];
         // enter info for copy2
         aw2.acct.AccountNumber='1234-TEST2234';
         aw2.acct.Employees__c = 2;
         aw2.acct.Name='Test Account2';

         // move to the next step to select contacts and assets
         System.assertEquals(null,acc.nextStep());
         System.assertEquals(AccountCloneController.STEP2,acc.currentStep);
         
         // nothing is currently selected
         System.assertEquals(false,acc.hasSelectedCtcts);
         System.assertEquals(false,acc.hasSelectedAssets);
      
         // select two of the contacts
         AccountCloneController.ContactWrapper cw0 = acc.ctcts[0];
         AccountCloneController.ContactWrapper cw1 = acc.ctcts[1];
         cw0.selected = true;
         cw1.selected = true;
      
         // select two assets
         AccountCloneController.AssetWrapper asstW0 = acc.assets[0];
         AccountCloneController.AssetWrapper asstW1 = acc.assets[1];
         asstW0.selected = true;
         asstW1.selected = true;
      
         // go to the verify step
         System.assertEquals(null,acc.nextStep());
         // should be at the verify step
         System.assertEquals(AccountCloneController.STEP_VERIFY,acc.currentStep);
      
         // contacts and assets are selected
         System.assertEquals(3,acc.accts.size());
         System.assertEquals(2,acc.selectedCtcts.size());
         System.assertEquals(2,acc.selectedAssets.size());
         System.assertEquals(true,acc.hasSelectedCtcts);
         System.assertEquals(true,acc.hasSelectedAssets);
      
         // go to the save step.
         Test.startTest();
         System.assertEquals(null,acc.nextStep());
         Test.stopTest();
         // records should have saved
         System.assertEquals(AccountCloneController.STEP_LAST,acc.currentStep);
         // verify that accounts, contacts and assets were created.
         System.debug('testHROClone checking accounts for HRO Number '+acct.HRO_Number__c);
         
         Integer nbrAccts = [Select count() from Account];
         System.debug('testHROClone checking nbrAccts='+nbrAccts);
         Account[] createdAccts = [Select Id
                                         ,HRO_Number__c
                                         ,HRO_Implementation_Coordinator__c
                                         ,HRO_NCP_Received_Date__c
                                         ,HRO_Service_Agreement_Received__c
                                         ,HRO_First_Run_or_New_Setup_Date__c
                                         ,HRO_Preview_Hosting_Client__c
                                         ,HRO_Group__c
                                         ,HRO_Total_ID_s__c
                                         ,ParentId
                                      ,(Select Id
                                              ,Name
                                          From Contacts)
                                      ,(Select Id
                                              ,Name
                                          From Assets)
                                  From Account
                                 Where Id != :acct.Id
                                   and HRO_Number__c = :acct.HRO_Number__c];
         System.assertEquals(2,createdAccts.size());
         for (Account checkAcct : createdAccts) {
            // verify HRO fields are set.
            System.assertEquals(acct.HRO_Number__c, checkAcct.HRO_Number__c);
            System.assertEquals(acct.HRO_Implementation_Coordinator__c, checkAcct.HRO_Implementation_Coordinator__c);
            System.assertEquals(acct.HRO_NCP_Received_Date__c, checkAcct.HRO_NCP_Received_Date__c);
            System.assertEquals(acct.HRO_Service_Agreement_Received__c, checkAcct.HRO_Service_Agreement_Received__c);
            System.assertEquals(acct.HRO_First_Run_or_New_Setup_Date__c, checkAcct.HRO_First_Run_or_New_Setup_Date__c);
            System.assertEquals(acct.HRO_Preview_Hosting_Client__c, checkAcct.HRO_Preview_Hosting_Client__c);
            System.assertEquals(acct.HRO_Group__c, checkAcct.HRO_Group__c);
            System.assertEquals(acct.HRO_Total_ID_s__c, checkAcct.HRO_Total_ID_s__c);
            // parent id not being set for HRO relationships
            System.assertEquals(null,checkAcct.ParentId);
            System.assertEquals(2,checkAcct.Contacts.size());
            System.assertEquals(2,checkAcct.Assets.size());
         }
      
         // update the main account
         acct.HRO_NCP_Received_Date__c = Date.today().addDays(-1);
         acct.HRO_First_Run_or_New_Setup_Date__c = Date.today().addDays(3);
         update acct;
         
         // reenter the form
         Test.SetCurrentPageReference(Page.AccountClone);
         System.CurrentPageReference().getParameters().put('Id',acct.Id);
         // make sure set to start with 2 records
         AccountCloneController.NBR_TO_START = 2;
      
         sc = New ApexPages.StandardController(acct);
         acc = new AccountCloneController(sc);
      
         System.assertEquals(true,acc.isModeHRO);
         // make sure using all of the existing records
         System.assertEquals(true,acc.hasExistingChild);
         System.assertEquals(2,acc.nbrExistingChildren);
         System.assertEquals(0,acc.nbrCloneRecords);
         
         // add one new record
         acc.nbrCloneRecords = 1;
         System.assertEquals(null,acc.changeNbrAccounts());
         
         // set the account info
         AccountCloneController.AccountWrapper aw3 = acc.accts[3];
         // enter info for copy2
         aw3.acct.AccountNumber='1234-TEST3234';
         aw3.acct.Employees__c = 3;
         aw3.acct.Name='Test Account3';

         // verify the step
         System.assertEquals(AccountCloneController.STEP1,acc.currentStep);
         //go to the next step
         System.assertEquals(null,acc.nextStep());
         // verify it sees the contacts and assets
         System.assertEquals(true,acc.hasCtcts);
         System.assertEquals(true,acc.hasAssets);
      
         // verify number of records
         System.assertEquals(4,acc.accts.size());
         System.assertEquals(2,acc.ctcts.size());
         System.assertEquals(2,acc.assets.size());
         
         
         // select two of the contacts
         cw0 = acc.ctcts[0];
         cw1 = acc.ctcts[1];
         cw0.selected = true;
         cw1.selected = true;
      
         // select two assets
         asstW0 = acc.assets[0];
         asstW1 = acc.assets[1];
         asstW0.selected = true;
         asstW1.selected = true;
      
         // go to the verify step
         System.assertEquals(null,acc.nextStep());
         // should be at the verify step
         System.assertEquals(AccountCloneController.STEP_VERIFY,acc.currentStep);
      
         // contacts and assets are selected
         System.assertEquals(4,acc.accts.size());
         System.assertEquals(2,acc.selectedCtcts.size());
         System.assertEquals(2,acc.selectedAssets.size());
         System.assertEquals(true,acc.hasSelectedCtcts);
         System.assertEquals(true,acc.hasSelectedAssets);
      
         // go to the save step.
         System.assertEquals(null,acc.nextStep());
         // records should have saved
         System.assertEquals(AccountCloneController.STEP_LAST,acc.currentStep);
         // verify that accounts, contacts and assets were created.
         System.debug('checking accounts for HRO Number '+acct.HRO_Number__c);
         // make sure new one is created and the existing two are updated.
         createdAccts = [Select Id
                                         ,HRO_Number__c
                                         ,HRO_Implementation_Coordinator__c
                                         ,HRO_NCP_Received_Date__c
                                         ,HRO_Service_Agreement_Received__c
                                         ,HRO_First_Run_or_New_Setup_Date__c
                                         ,HRO_Preview_Hosting_Client__c
                                         ,HRO_Group__c
                                         ,HRO_Total_ID_s__c
                                         ,ParentId
                                         ,SalesParent__c
                                      ,(Select Id
                                              ,Name
                                          From Contacts)
                                      ,(Select Id
                                              ,Name
                                          From Assets)
                                  From Account
                                 Where Id != :acct.Id
                                   and HRO_Number__c = :acct.HRO_Number__c];
         System.assertEquals(3,createdAccts.size());
         for (Account checkAcct : createdAccts) {
            // verify HRO fields are set.
            System.assertEquals(acct.HRO_Number__c, checkAcct.HRO_Number__c);
            System.assertEquals(acct.HRO_Implementation_Coordinator__c, checkAcct.HRO_Implementation_Coordinator__c);
            System.assertEquals(acct.HRO_NCP_Received_Date__c, checkAcct.HRO_NCP_Received_Date__c);
            System.assertEquals(acct.HRO_Service_Agreement_Received__c, checkAcct.HRO_Service_Agreement_Received__c);
            System.assertEquals(acct.HRO_First_Run_or_New_Setup_Date__c, checkAcct.HRO_First_Run_or_New_Setup_Date__c);
            System.assertEquals(acct.HRO_Preview_Hosting_Client__c, checkAcct.HRO_Preview_Hosting_Client__c);
            System.assertEquals(acct.HRO_Group__c, checkAcct.HRO_Group__c);
            System.assertEquals(acct.HRO_Total_ID_s__c, checkAcct.HRO_Total_ID_s__c);
            // parent id not being set for HRO relationships
            System.assertEquals(null,checkAcct.ParentId);
            System.assertEquals(2,checkAcct.Contacts.size());
            System.assertEquals(2,checkAcct.Assets.size());
         }
      
      } // System.runAs
   } // testHROClone
   
    static testMethod void testMultiId() {
      //get account owner
      User user = [Select Id, Name from User where IsActive=true and Id != :UserInfo.getUserId() and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        
      // create the source account
      Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
      //Account acct = new Account(Name='Test Account0',AccountNumber='1234-TEST0123', NumberOfEmployees=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
      Account acct = new Account(Name='Test AccountParent',OwnerId=user.Id,recordtypeId = acctCorert.getRecordTypeId(),AccountNumber='9999-TEST9999', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
      // this one will be used for duplicate checking
      insert acct;
      
      // get the core record type - have to set the record type because of the Sales_Contact__c flag.
      Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');

      // create contacts
      Contact ctct1 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest1',Email='firstTest1@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
      Contact ctct2 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest2',Email='firstTest2@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
      Contact ctct3 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest3',Email='firstTest3@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
      Contact ctct4 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest4',Email='firstTest4@test.com',Sales_Contact__c=false);
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;
      
      // create account contact roles
      AccountContactRole acr1 = new AccountContactRole(AccountId=acct.Id,ContactId=ctct1.Id,IsPrimary=true,Role='Other');
      AccountContactRole acr2 = new AccountContactRole(AccountId=acct.Id,ContactId=ctct2.Id,IsPrimary=false,Role='Other');
      AccountContactRole acr3 = new AccountContactRole(AccountId=acct.Id,ContactId=ctct3.Id,IsPrimary=false,Role='Other');
      AccountContactRole acr4 = new AccountContactRole(AccountId=acct.Id,ContactId=ctct4.Id,IsPrimary=false,Role='Other');
      AccountContactRole[] acrs = new AccountContactRole[]{acr1,acr2,acr3,acr4};
      insert acrs;
        
      // create opportunities
      Opportunity opp1 = new Opportunity(Name='Test Opp1',CloseDate=Date.today().addDays(7),StageName='Sold',Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id); 
      insert opp1;
        
      User[] nsrUsers = ProspectOwnershipMethodsTest.getOutboundNSRs(2);
      Prospect_Ownership__c po1 = new Prospect_Ownership__c(Prospect_Client__c=acct.Id, NSR_Name__c=nsrUsers[0].Id, CommissionStart__c=Date.today().addDays(-30), CommissionEnd__c=Date.today().addDays(30)
                                                     ,Decision_Maker__c=ctct1.Id, NSS_Source__c='Outbound',NSS_Team__c=UserHelper.SO_CORE, Ownership_Status__c=ProspectOwnershipMethods.STAGE_COMMISSION);
      // this one should fall outside of the selection range
      Prospect_Ownership__c po2 = new Prospect_Ownership__c(Prospect_Client__c=acct.Id, NSR_Name__c=nsrUsers[1].Id, CommissionStart__c=Date.today().addDays(-100), CommissionEnd__c=Date.today().addDays(-60)
                                                     ,Decision_Maker__c=ctct1.Id, NSS_Source__c='Outbound',NSS_Team__c=UserHelper.SO_CORE, Ownership_Status__c=ProspectOwnershipMethods.STAGE_COMMISSION);
      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{po1,po2};
      insert pos;
      
      Test.SetCurrentPageReference(Page.AccountClone);
      System.CurrentPageReference().getParameters().put('Id',acct.Id);
      System.CurrentPageReference().getParameters().put('opptyId',opp1.Id);
      System.CurrentPageReference().getParameters().put('MultiId','True');  
      
      // make sure set to start with 2 records
      AccountCloneController.NBR_TO_START = 2;
      
      ApexPages.Standardcontroller sc = New ApexPages.StandardController(acct);
      AccountCloneController acc = new AccountCloneController(sc);
      
      acc.runningMode = AccountCloneController.MODE_MMS;
      System.assertEquals(null,acc.changeRunningMode());
      System.assertEquals(false,acc.isModeHRO);  
      System.assertEquals(true,acc.isMultiId);
      
      System.assertEquals(true,acc.okayToProceed);
      System.assertEquals(false,ApexPages.hasMessages());

      // verify the step
      System.assertEquals(AccountCloneController.STEP1,acc.currentStep);
       
      // verify it sees the accounts and contacts
      System.assertEquals(true,acc.hasCtcts);
      
      // verify number of records - 2 to start plus parent
      System.assertEquals(3,acc.accts.size());
      System.assertEquals(3,acc.ctcts.size());
      
      // enter information for some of the records.
      // check to make sure the first is the primary record.
      AccountCloneController.AccountWrapper aw0 = acc.accts[0];
      System.assertEquals(true,aw0.isParent);
      AccountCloneController.AccountWrapper aw1 = acc.accts[1];
      // enter an valid relationship type
      aw1.acct.AccountNumber='5678-TEST5678';
      aw1.acct.Employees__c = 1;
      aw1.acct.Name='Test Account2';
      aw1.aj.Type__c='Combo';
      AccountCloneController.AccountWrapper aw2 = acc.accts[2];
      // enter a valid account number 
      aw2.acct.AccountNumber='4321-TEST4321';
      aw2.acct.Employees__c = 6;
      aw2.acct.Name='Test Account3';
      aw2.aj.Type__c='Related/Common';  
      
      // move to the next step to select contacts and assets
      System.assertEquals(null,acc.nextStep()); 
      // nothing is currently selected
      System.assertEquals(false,acc.hasSelectedCtcts);    
      System.assertEquals(AccountCloneController.STEP2,acc.currentStep);  
      System.assertEquals(null,acc.nextStep());     
      // should be at the verify step
      System.assertEquals(AccountCloneController.STEP_VERIFY,acc.currentStep); 
      // go to the save step.
      System.assertEquals(null,acc.nextStep());  
      // records should have saved
      System.assertEquals(AccountCloneController.STEP_LAST,acc.currentStep);
      // verify that accounts and contacts were created.
      Account[] createdAccts = [Select Id
                                      ,ParentId
                                  From Account
                                 Where ParentId = :acct.Id];
      System.assertEquals(2,createdAccts.size());
 
      // return to the opportunity
      PageReference retUrl = acc.returnToOpportunity();
      System.assertEquals(true,(retUrl.getUrl().contains(opp1.Id)));
      
   } // testMultiId

   static testMethod void testAccountSearch() {
      Account acct = new Account(Name='Test Account0',AccountNumber='1234-TEST0123', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514',Federal_ID_Number__c='1234');
      insert acct;
      
      Test.SetCurrentPageReference(Page.AccountClone);
      System.CurrentPageReference().getParameters().put('Id',acct.Id);
       
      // create an Account to search
      Account sacct = new Account(Name='AccountSearchTest Record0',AccountNumber='17-DAN0',ShippingPostalCode='14514',ShippingStreet='123',Federal_ID_Number__c='1234');
      insert sacct;
      
      ApexPages.Standardcontroller sc = New ApexPages.StandardController(new Account());
      AccountCloneController acc = new AccountCloneController(sc);
      acc.setAccount(acct.id);
      
      acc.searchAcct = sacct;    
      acc.performSearch();
            
      System.assertEquals(true, acc.hasSearchResults);
      
      // select from search results
      AccountCloneController.AccountWrapper aw = acc.faccts.get(0);
      acc.faccts.get(0).selectedForRelate = true;
      acc.handleRecordAction();
      //System.assertEquals(1,acc.accts.size());
      System.assertEquals(0,acc.faccts.size());
      System.assertEquals(aw.acct.Id,sacct.Id);
      System.assert(acc.accts.contains(aw));
      
   } // testSearch
    
    
    static testMethod void testAccountSearchByPhone() {
      Account acct = new Account(Name='Test Account0',AccountNumber='1234-TEST0123', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514',Federal_ID_Number__c='1234');
      insert acct;
      
      Test.SetCurrentPageReference(Page.AccountClone);
      System.CurrentPageReference().getParameters().put('Id',acct.Id);
       
      // create an Account to search
      Account sacct = new Account(Name='AccountSearchTest Record0',AccountNumber='17-DAN0',ShippingPostalCode='14514',ShippingStreet='123',Federal_ID_Number__c='1234',Phone='1234567890');
      insert sacct;
      
      Id [] fixedSearchResults= new Id[1];
      fixedSearchResults[0] = sacct.Id;
      Test.setFixedSearchResults(fixedSearchResults);

      ApexPages.Standardcontroller sc = New ApexPages.StandardController(new Account());
      AccountCloneController acc = new AccountCloneController(sc);
      acc.setAccount(acct.id);
      
      acc.searchAcct = sacct;  
      acc.performSearch();

      System.assertEquals(true, acc.hasSearchResults);
      
      // select from search results
      AccountCloneController.AccountWrapper aw = acc.faccts.get(0);
      acc.faccts.get(0).selectedForRelate = true;
      acc.handleRecordAction();
      //System.assertEquals(1,acc.accts.size());
      System.assertEquals(0,acc.faccts.size());
      System.assertEquals(aw.acct.Id,sacct.Id);
      System.assert(acc.accts.contains(aw));
      
   } // testAccountSearchByPhone
   /* */
    static testMethod void testContactSearch() {
      Account acct = new Account(Name='Test Account0',AccountNumber='1234-TEST0123', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514',Federal_ID_Number__c='1234',Phone='1234567890');
      insert acct;
      
      Account sacct = new Account(Name='AccountSearchTest Record0',AccountNumber='17-DAN0',ShippingPostalCode='14514',ShippingStreet='123',Federal_ID_Number__c='1234');
      insert sacct;
        
      Contact ctct = new Contact(FirstName='Test',LastName='Contact123',AccountId=sacct.Id);
      insert ctct;
        
      Test.SetCurrentPageReference(Page.AccountClone);
      System.CurrentPageReference().getParameters().put('Id',acct.Id);
       
      // create an Contact to search      
      Contact sctct = new Contact(FirstName='Test',LastName='Contact123');
      insert sctct;
        
      ApexPages.Standardcontroller sc = New ApexPages.StandardController(new Account());
      AccountCloneController acc = new AccountCloneController(sc);
      acc.setAccount(acct.id);
      acc.selectedValue = 'ctct';
        
      acc.searchCtct = sctct;    
      acc.performSearch();
            
      System.assertEquals(true, acc.hasSearchResults);
      
      // select from search results
      AccountCloneController.AccountWrapper aw = acc.faccts.get(0);
      acc.faccts.get(0).selectedForRelate = true;
      acc.handleRecordAction();
      //System.assertEquals(1,acc.accts.size());
      System.assertEquals(0,acc.faccts.size());
      //System.assertEquals(aw.acct.Id,sacct.Id);
      System.assert(acc.accts.contains(aw));
      
   } // testContactSearch
    
    static testMethod void testContactSearchByPhone() {
      Account acct = new Account(Name='Test Account0',AccountNumber='1234-TEST0123', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514',Federal_ID_Number__c='1234');
      insert acct;
      
      Account sacct = new Account(Name='AccountSearchTest Record0',AccountNumber='17-DAN0',ShippingPostalCode='14514',ShippingStreet='123',Federal_ID_Number__c='1234');
      insert sacct;
        
      Contact ctct = new Contact(FirstName='Test',LastName='Contact123',AccountId=acct.Id);
      insert ctct;
        
      Test.SetCurrentPageReference(Page.AccountClone);
      System.CurrentPageReference().getParameters().put('Id',acct.Id);
       
      // create an Contact to search      
      Contact sctct = new Contact(FirstName='Test',LastName='Contact124',phone='1234567890',AccountId=sacct.Id);
      insert sctct;
        
      Id [] fixedSearchResults= new Id[1];
      fixedSearchResults[0] = sctct.Id;
      Test.setFixedSearchResults(fixedSearchResults);

      ApexPages.Standardcontroller sc = New ApexPages.StandardController(new Account());
      AccountCloneController acc = new AccountCloneController(sc);
      acc.setAccount(acct.id);
      acc.selectedValue = 'ctct';
        
      acc.searchCtct = sctct;    
      acc.performSearch();
            
      System.assertEquals(true, acc.hasSearchResults);
      
      // select from search results
      AccountCloneController.AccountWrapper aw = acc.faccts.get(0);
      acc.faccts.get(0).selectedForRelate = true;
      acc.handleRecordAction();
      //System.assertEquals(1,acc.accts.size());
      System.assertEquals(0,acc.faccts.size());
      //System.assertEquals(aw.acct.Id,sacct.Id);
      System.assert(acc.accts.contains(aw));
      
   } // testContactSearchByPhone
   
    // populated custom settings
   public static void populateSettings() {
      if (HoldOut_ExpirationDates__c.getAll().size() == 0) {
         HoldOut_ExpirationDates__c hoPAY = new HoldOut_ExpirationDates__c(Name='PAY',Sales_Org__c='PAY',Account_Hold_Out__c='Hold_Out__c',Account_Hold_Out_Date__c='Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=30,Account_Date_Field__c='First_Run_Date__c',OptySoldNumberOfDays__c=90,
                                                                          TaskNumberOfDays__c=90,UseForOwnershipChange__c=true,HoldOutReasonFld__c='Permanent_Hold_Out_Description__c',
                                                                          Account_Owner__c='OwnerId');
         HoldOut_ExpirationDates__c hoMMS = new HoldOut_ExpirationDates__c(Name='MMS',Sales_Org__c='MMS',Account_Hold_Out__c='Hold_Out__c',Account_Hold_Out_Date__c='Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=120,Account_Date_Field__c='First_Run_Date__c',OptySoldNumberOfDays__c=120,
                                                                          Account_Owner__c='OwnerId');
         HoldOut_ExpirationDates__c hoHRS = new HoldOut_ExpirationDates__c(Name='HRS',Sales_Org__c='HRS',Account_Hold_Out__c='HRS_Hold_Out__c',Account_Hold_Out_Date__c='HRS_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=180,Opportunity_Date__c='CloseDate',OptySoldNumberOfDays__c=180
                                                                          ,UseForOwnershipChange__c=true,Account_Owner__c='HRS_Account_Owner__c');
         HoldOut_ExpirationDates__c hoHNBF = new HoldOut_ExpirationDates__c(Name='HNBF',Sales_Org__c='HNBF',Account_Hold_Out__c='HNBF_Hold_Out__c',Account_Hold_Out_Date__c='HNBF_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=180,Opportunity_Date__c='CloseDate',OptySoldNumberOfDays__c=180
                                                                          ,UseForOwnershipChange__c=true,Account_Owner__c='HNBF_Account_Owner__c');
         HoldOut_ExpirationDates__c hoPAS = new HoldOut_ExpirationDates__c(Name='PAS',Sales_Org__c='PAS',Account_Hold_Out__c='Premier_PBS_Hold_Out__c',Account_Hold_Out_Date__c='Premier_PBS_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=180,Opportunity_Date__c='CloseDate',OptySoldNumberOfDays__c=180
                                                                          ,UseForOwnershipChange__c=true, Account_Owner__c='Premier_PBS_Account_Owner__c');
         HoldOut_ExpirationDates__c hoMS = new HoldOut_ExpirationDates__c(Name='MS',Sales_Org__c='MS',Account_Hold_Out__c='MS_Hold_Out__c',Account_Hold_Out_Date__c='MS_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=null,Opportunity_Date__c=null,OptySoldNumberOfDays__c=null
                                                                          ,UseForOwnershipChange__c=false);
         HoldOut_ExpirationDates__c[] hoList = new HoldOut_ExpirationDates__c[]{hoPAY,hoMMS, hoHRS, hoHNBF, hoPAS,hoMS};
         insert hoList;
      } 
     
   } // populateSetting
 
} // class AccountCloneControllerTest