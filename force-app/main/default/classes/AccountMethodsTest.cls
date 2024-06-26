/** Test methods for the AccountMethods class
 *
 * History
 * -------
 * 01/02/2014 Dan Carmen         Created.
   02/15/2016 Dan Carmen         Add in functionality for EndOnlyRunningUser__c field.
   03/10/2016 Jacob Hinds        Added in testAccountType
   05/02/2016 Dan Carmen         Ability to not trigger on the dialed checkbox
   01/27/2017 Cindy Freeman      added test for updateAssetEmps method
   03/22/2017 Cindy Freeman      modified test for new Account Junction code
   12/12/2017 Dan Carmen              Additional adjustments to asset code
   01/15/2018 Jacob Hinds        Commented out testCallDisposition
   06/04/2018 Jacob Hinds        ASO Partner method
   10/31/2018 Jacob Hinds        Adding HROI to client type method
   03/17/2020 Jacob Hinds       changes for owner partnership
   05/14/2020 Manmeet Vaseer    SFDC-3313 - removed HROi client processing
   07/16/2020 Brandon Vidro     Added test for miEdge
   08/31/2020 Brandon Vidro     Updated miEdge test
   06/17/2021 Dan Carmen        Set Type for Oasis based on CS Contract Status
   06/28/2021 Jermaine Stukes	Update for HR Service Partner
   11/04/2021 Dan Carmen        Don't default clientStatus to I if blank
   01/03/2023 Dan Carmen        Move Time Zone logic to TimeZoneHelper
   05/19/2023 Dan Carmen        Update AccountTeamMember logic
   12/11/2023 Dan Carmen        Remove logic for HR_Services_Partner__c

*/
@isTest
public class AccountMethodsTest {

   public static User testSalesRep;
   public static Account testAcct;
   public static Contact[] testCtcts;
   
   @testSetup
   private static void setupData() {
      AccountJunctionMethodsTest.setupCustomSettings();
      // create the lead call disposition custom setting
      LeadCallDisposition__c[] lcds = LeadMethodsTest.createLeadCallDispositions();
   } // setupData
   
   /** Setup a test account and contact. */
   public static void setupTestAcctCtct(Integer nbrCtcts) {
      // a sales rep to own the records - so NSR has visiblity to the records
      testSalesRep = [Select Id, Name, Profile.Name, UserRole.Name from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and IsActive=true limit 1];

      // create as sales reps so correct record types are being set on the records.
      System.runAs(testSalesRep) {
         // create an account and contact
         testAcct = new Account(Name='Test Acct', OwnerId=testSalesRep.Id, Current_Prior_Method__c = 'Engage-PEO');
         insert testAcct;
      
         testCtcts = new Contact[]{};
         for (Integer cnt=0; cnt<nbrCtcts; cnt++) {
            testCtcts.add(new Contact(AccountId = testAcct.Id, OwnerId=testSalesRep.Id
                                    ,FirstName='TestFirst', LastName='TestLast'+cnt, Phone='(555) 123-4567'
                                    ,Products__c=UserHelper.SO_CORE, Sales_Contact__c=true));
         }
         insert testCtcts;
         Id[] ctctIds = new Id[]{};
         for (Contact ctct : testCtcts) {
            ctctIds.add(ctct.Id);
         }
         // reselect the contacts
         testCtcts = [Select AccountId, FirstName, LastName, Name, NSSStatus__c, NSSCallDisposition__c, Phone, Products__c from Contact where Id=:ctctIds];
      } // System.runAs
      
   } // setupTestAcctCtct

   static testMethod void testCheckLostDateNSS() {
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_SFDC,runningUser.Name);

      // create Accounts
      Account acct1 = new Account(Name='Test 1');
      Account acct2 = new Account(Name='Test 2', Bis_Id__c=122, AssignedToOutboundNSR__c=true);
      Account acct3 = new Account(Name='Test 3', Bis_Id__c=123, AssignedToOutboundNSR__c=true);
      Account acct4 = new Account(Name='Test 4', Bis_Id__c=124, AssignedToOutboundNSR__c=true);
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      insert accts;
      
      LifeOfLeadSettings__c hrsLols = ProspectOwnershipMethodsTest.createProspectingLols(UserHelper.SO_401, ProspectOwnerShipMethods.NSS_OUTBOUND);
      LifeOfLeadSettings__c payLols = ProspectOwnershipMethodsTest.createProspectingLols(UserHelper.SO_CORE, ProspectOwnerShipMethods.NSS_OUTBOUND);

      // create ownership records
      // linked to account without a bis id - should not update
      Prospect_Ownership__c po1 = ProspectOwnershipMethodsTest.createProspectingOwnership(hrsLols,null,acct1);
      // has a bis id, should update
      Prospect_Ownership__c po2 = ProspectOwnershipMethodsTest.createProspectingOwnership(hrsLols,null,acct2);
      // payroll team, should not update
      Prospect_Ownership__c po3 = ProspectOwnershipMethodsTest.createProspectingOwnership(payLols,null,acct3);
      // will not update lost date so should not update
      Prospect_Ownership__c po4 = ProspectOwnershipMethodsTest.createProspectingOwnership(hrsLols,null,acct4);
      
      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{po1,po2,po3,po4};
      insert pos; 
      
      acct1.Lost_Date__c = Date.today();
      acct2.Lost_Date__c = Date.today();
      acct3.Lost_Date__c = Date.today();
      acct4.Lost_Date__c = null;
      
      update accts;
      
      // verify results
      po1 = [Select Id, Prospect_Client__c, Ownership_Status__c, StartDate__c, EndDate__c, NSS_Team__c from Prospect_Ownership__c where Id=:po1.Id];
      System.debug('po1='+po1);
      System.assertEquals(null,po1.EndDate__c);
      System.assertEquals('Prospecting',po1.Ownership_Status__c);

      po2 = [Select Id, Prospect_Client__c, Ownership_Status__c, StartDate__c, EndDate__c, NSS_Team__c from Prospect_Ownership__c where Id=:po2.Id];
      System.debug('po2='+po2);
      System.assertEquals(Date.today(),po2.EndDate__c);
      System.assertEquals('Expired',po2.Ownership_Status__c);

      po3 = [Select Id, Prospect_Client__c, Ownership_Status__c, StartDate__c, EndDate__c, NSS_Team__c from Prospect_Ownership__c where Id=:po3.Id];
      System.debug('po3='+po3);
      System.assertEquals(null,po3.EndDate__c);
      System.assertEquals('Prospecting',po3.Ownership_Status__c);

      po4 = [Select Id, Prospect_Client__c, Ownership_Status__c, StartDate__c, EndDate__c, NSS_Team__c from Prospect_Ownership__c where Id=:po4.Id];
      System.debug('po4='+po4);
      System.assertEquals(null,po4.EndDate__c);
      System.assertEquals('Prospecting',po4.Ownership_Status__c);
      
      // create an account with no ownership record
      // this is to handle the case where it gets through the trigger into the method, but there are no records in the methods to process.
      Account acct5 = new Account(Name='Test 5', Bis_Id__c=125, AssignedToOutboundNSR__c=true);
      insert acct5;
      acct5.Lost_Date__c = Date.today();
      update acct5;
      
   } // testCheckLostDateNSS
    
     //  related Commission Broker Records are set to 'Terminated' in the Status field upon update, upon the Account | CS CM Contract Status field being set to Terminated
   static testMethod void testUpdateAccountMethods() {
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_SFDC,runningUser.Name);

      // create Accounts
      Account acct1 = new Account(Name='Test 1',CSCMContractStatus__c = 'Approved');
      Account acct2 = new Account(Name='Test 2', Bis_Id__c=122, AssignedToOutboundNSR__c=true,CSCMContractStatus__c = 'Approved');
      Account acct3 = new Account(Name='Test 3', Bis_Id__c=123, AssignedToOutboundNSR__c=true,CSCMContractStatus__c = 'Approved');
      Account acct4 = new Account(Name='Test 4', Bis_Id__c=124, AssignedToOutboundNSR__c=true,CSCMContractStatus__c = 'Approved');
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      insert accts;
      
      Referral_Account__c refAcc = new Referral_Account__c(Name='TestRA', Account__c = acct1.id);
      insert refAcc;
      List<Broker_Commission__c> lstBC = new List<Broker_Commission__c>(); 
      Broker_Commission__c bc1 = new Broker_Commission__c( Status__c='Active', Referral_Account__c = refAcc.id);
      Broker_Commission__c bc2 = new Broker_Commission__c( Status__c='Active', Referral_Account__c = refAcc.id);
      Broker_Commission__c bc3 = new Broker_Commission__c( Status__c='Active', Referral_Account__c = refAcc.id);
      Broker_Commission__c bc4 = new Broker_Commission__c( Status__c='Active', Referral_Account__c = refAcc.id);
      lstBC.add(bc1);
      lstBC.add(bc2);
      lstBC.add(bc3);
      lstBC.add(bc4);
      insert lstBC;
      
      acct1.CSCMContractStatus__c = 'Terminated';
      acct2.CSCMContractStatus__c = 'Terminated';
      acct3.CSCMContractStatus__c = 'Terminated';
      acct4.CSCMContractStatus__c = 'Terminated';
      
      update accts;
   }
   //  ended

   static testMethod void testCallDisposition() {
    // create the lead call disposition custom setting
      //LeadCallDisposition__c[] lcds = LeadMethodsTest.createLeadCallDispositions();
      LifeOfLeadSettings__c lols = ProspectOwnershipMethodsTest.createNotInterestedLols(UserHelper.SO_CORE, ProspectOwnerShipMethods.NSS_OUTBOUND);
      LeadCallDisposition__c lcd = LeadCallDisposition__c.getInstance('ContactedNotInterestedDisqualified');
      
      setupTestAcctCtct(1);

      // reselect the contact to get the name field
      Contact ctct = [Select AccountId, FirstName, LastName, Name, Phone, Products__c from Contact where Id=:testCtcts[0].Id];
      
      testAcct.NSSStatus__c = lcd.CurrentLeadStatus__c;
      testAcct.NSSCallDisposition__c = lcd.CallDisposition__c;
      //testAcct.NSSContactName__c = ctct.Name;
      //testAcct.NSSContactPhone__c = ctct.Phone;
      update testAcct;
      
      // verify ownership record was created with the status
      Prospect_Ownership__c[] pos = ProspectOwnershipMethods.getByAcctId(testAcct.Id);
      Prospect_Ownership__c po = pos[0];
      System.assertEquals(po.Ownership_Status__c, lcd.NewOwnershipStatus__c);
      
   } // testCallDisposition

   static testMethod void testDialed() {
      LeadMethods.DISABLE_DIAL_CHECKBOX = false;
      // create the lead call disposition custom setting
      //LeadCallDisposition__c[] lcds = LeadMethodsTest.createLeadCallDispositions();
      LifeOfLeadSettings__c lols = ProspectOwnershipMethodsTest.createProspectingLols(UserHelper.SO_CORE, ProspectOwnerShipMethods.NSS_OUTBOUND);

      setupTestAcctCtct(1);
            
      // select an outbound NSR
      User nsrOutbound1 = ProspectOwnershipMethodsTest.getOutboundNSRs(1)[0];
      
      System.runAs(nsrOutbound1) {
         testAcct.Dialed__c = true;
         update testAcct;
      
      }
      // verify ownership record was created with the status
      Prospect_Ownership__c[] pos = ProspectOwnershipMethods.getByAcctId(testAcct.Id);
      Prospect_Ownership__c po = pos[0];
      System.assertEquals(po.Decision_Maker__c, testCtcts[0].Id);
   } // testDialed

   static testMethod void testFindContact() {
      setupTestAcctCtct(4);

    Contact check1 = AccountMethods.findContact(testAcct, testCtcts, testCtcts[1].Id, null);
    System.assertEquals(check1.Id, testCtcts[1].Id);
    
    Contact check2 = AccountMethods.findContact(testAcct,testCtcts, null, null);
    System.assertEquals(check2.Id, testCtcts[0].Id);
    
    testAcct.NSSContactName__c = 'Bad Name';
      Contact check3 = AccountMethods.findContact(testAcct,testCtcts, null, null);
      System.assertEquals(check3.Id, testCtcts[0].Id);
      
      // reselect the contact
      testCtcts[3] = [Select AccountId, FirstName, LastName, Name, Phone, Products__c from Contact where Id=:testCtcts[3].Id];

      //testAcct.NSSContactName__c = testCtcts[3].Name;
      //testAcct.NSSContactPhone__c = testCtcts[3].Phone;
      Contact check4 = AccountMethods.findContact(testAcct,testCtcts, null, null);
      //System.assertEquals(check4.Id, testCtcts[3].Id);
      
   } // testFindContact

   static testMethod void testCheckOwnerZip() {
      UserHelper.setRunningUserAttributes();
      Account acct = new Account(ShippingPostalCode='12345', Owner_Zip_Code__c=null);
      System.assertEquals(null,acct.Owner_Zip_Code__c);
      AccountMethods.checkZipFields(acct,null);
      System.assertEquals('12345',acct.Owner_Zip_Code__c);
      acct.ShippingPostalCode='123';
      acct.BillingPostalCode='23456-7890';
      AccountMethods.checkZipFields(acct,null);
      System.assertEquals('23456',acct.Owner_Zip_Code__c);
   } // testCheckOwnerZip
   
   static testMethod void testUserOwnerShipping() {
    Account acct1 = new Account();
    acct1.ShippingStreet = '123 Any St';
      acct1.ShippingCity = 'SomeCity';
      acct1.ShippingState = 'NY';
      acct1.ShippingPostalCode = '12345';
      acct1.ShippingCountry = 'USA';
      acct1.User_Owned_Shipping_Address__c = true;
      
      Account acct2 = new Account();
      acct2.ShippingStreet = '234 Any St';
      acct2.ShippingCity = 'SomeOtherCity';
      acct2.ShippingState = 'FL';
      acct2.ShippingPostalCode = '34567';
      acct2.ShippingCountry = 'Canada';
      
      AccountMethods.checkUserOwnedShipping(acct1, acct2);
      
      System.assertEquals(acct1.ShippingStreet,acct2.ShippingStreet);
      System.assertEquals(acct1.ShippingCity,acct2.ShippingCity);
      System.assertEquals(acct1.ShippingState,acct2.ShippingState);
      System.assertEquals(acct1.ShippingPostalCode,acct2.ShippingPostalCode);
      System.assertEquals(acct1.ShippingCountry,acct2.ShippingCountry);
      
   } // testUserOwnerShipping

   static testMethod void testCheckForSignificanceRecalc() {
    Account acct = new Account(Name='Test Account');
    insert acct;
    
      Contact ctct1 = new Contact(AccountId=acct.Id,LastName='Test1',Hold_Out_Reason__c=LeadCompanyMethods.HOLD_OUT_DEFAULT, NSSStatus__c=LeadCompanyMethods.STATUS_DEFAULT);
      Contact ctct2 = new Contact(AccountId=acct.Id,LastName='Test2',Hold_Out_Reason__c='Test Reason', NSSStatus__c='Test Status');
      
      System.assertEquals(true,AccountMethods.checkForSignificanceRecalc(ctct1,null));
      AccountMethods.accountIdsToCheckSignificantSet.clear();
      System.assertEquals(false,AccountMethods.checkForSignificanceRecalc(ctct1,ctct1));
      AccountMethods.accountIdsToCheckSignificantSet.clear();
      System.assertEquals(true,AccountMethods.checkForSignificanceRecalc(ctct1,ctct2));
            
      
   } // testCheckForSignificanceRecalc

   static testMethod void testSettingSignificantContact() {
      Account acct = new Account(Name='Test Account');
      insert acct;
      
      Schema.RecordTypeInfo ctctRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
      
      Contact ctct1 = new Contact(AccountId=acct.Id,RecordTypeId=ctctRt.getRecordTypeId(),FirstName='One',LastName='Test1',Hold_Out_Reason__c=null, Phone='5852345678', NSSStatus__c=null, Sales_Contact__c=true);
      insert ctct1;
      
      verifyContact(ctct1.Id);
      acct = [Select Id, SignificantContact__c from Account where Id=:acct.Id];
      System.assertEquals(ctct1.Id, acct.SignificantContact__c);
      
      // to make sure it checks again
      AccountMethods.accountIdsChecked.clear();
      
      ctct1.Sales_Contact__c = false;
      Contact ctct2 = new Contact(AccountId=acct.Id,RecordTypeId=ctctRt.getRecordTypeId(),FirstName='Second',LastName='Test2',Hold_Out_Reason__c=null, Phone='5851234567', NSSStatus__c=null, Sales_Contact__c=true);
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      //Database.DMLOptions dmo = DuplicateHelper.getDmlSkipCheck();
      Database.upsert(ctcts);
      //insert ctct2;
      //verifyContact(ctct2.Id);
      
      System.assertEquals(2,[select count() from Contact where AccountId=:acct.Id]);
      
      // should update to the second one because it's the most recent.
      acct = [Select Id, SignificantContact__c from Account where Id=:acct.Id];
      //System.assertEquals(ctct2.Id, acct.SignificantContact__c);
      
      // to make sure it checks again
      AccountMethods.accountIdsChecked.clear();

      ctct1.Sales_Contact__c = true;
      // set the hold out reason on ctct2
      ctct2.FirstName='Two';
      ctct2.Hold_Out_Reason__c = LeadCompanyMethods.HOLD_OUT_DEFAULT;
      //Contact[] ctcts = new Contact[]{ctct1,ctct2};
      update ctcts;
      //update ctct2;
      verifyContact(ctct2.Id);

      LeadCompanyMethods.setQueryParameters();
      System.assertEquals(1,[Select count() From Contact 
                                     Where AccountId = :acct.Id
                                       and Sales_Contact__c=true
                                       and DoNotCall=false
                                       and Hold_Out_Reason__c not in :LeadCompanyMethods.holdOutReasonSet
                                       and NSSStatus__c not in :LeadCompanyMethods.statusSet]);

      // should update back to the first one.
      acct = [Select Id, SignificantContact__c from Account where Id=:acct.Id];
      System.assertEquals(ctct1.Id, acct.SignificantContact__c);
      
      ctct1.NSSStatus__c = LeadCompanyMethods.STATUS_DEFAULT;
      ctct2.FirstName='Three';
      ctct2.Hold_Out_Reason__c = null;
      AccountMethods.accountIdsChecked.clear();
      update ctcts;
      //update ctct2;
      verifyContact(ctct2.Id);
      
      
      acct = [Select Id, SignificantContact__c from Account where Id=:acct.Id];
      System.assertEquals(ctct2.Id, acct.SignificantContact__c);

      ctct1.NSSStatus__c = null;
      update ctct1;
      
      // create a prospect ownership record on contact 1 - should switch ownership there.
      Prospect_Ownership__c po = new Prospect_Ownership__c(Prospect_Client__c=acct.Id, Decision_Maker__c=ctct1.Id, StartDate__c=Date.today());
      insert po;
      
      acct.EvaluateSignificant__c = true;
      AccountMethods.accountIdsChecked.clear();
      update acct;

      acct = [Select Id, SignificantContact__c from Account where Id=:acct.Id];
      System.assertEquals(ctct1.Id, acct.SignificantContact__c);
      
   } // testSettingSignificantContact

   public static void verifyContact(Id ctctId) {
      Contact ctct = [Select Id, Name, Sales_Contact__c, DoNotCall, Hold_Out_Reason__c, NSSStatus__c from Contact where Id=:ctctId];
      System.debug('verifyContact ctct='+ctct);
   }

   static testMethod void testAccountType(){
      User sfdcData = [SELECT Name,Id FROM User where Name='SFDC Data' LIMIT 1];
      
      Date yday = System.today().addDays(-1);
      
      ProcessNameMap__c pnm = new ProcessNameMap__c(Name=UserHelper.PREFIX_SFDC+sfdcData.Name,IsActive__c=true);
      insert pnm;
      Test.startTest();
      System.runAs(sfdcData){
        
        Account acct1 = new Account(Name='Test AT 01',Bis_ID__c=100001, Client_Status__c='A');
        Account acct2 = new Account(Name='Test AT 02',Bis_ID__c=100002);
        Account acct3 = new Account(Name='Test AT 03',Bis_ID__c=100003);
        Account acct4 = new Account(Name='Test AT 04',Bis_ID__c=100004);
        Account acct5 = new Account(Name='Test AT 05',Bis_ID__c=100005);
        Account acct6 = new Account(Name='Test AT 06',Bis_ID__c=100006);
        Account acct7 = new Account(Name='Test AT 07',Bis_ID__c=100007);
        Account acct8 = new Account(Name='Test AT 08',Bis_ID__c=100008);
        Account acct9 = new Account(Name='Test AT 09',Bis_ID__c=100009);
        Account acct10 = new Account(Name='Test AT 10',Bis_ID__c=100010, Client_Status__c='A');
        Account acct11 = new Account(Name='Test AT 11',Bis_ID__c=100011);
        Account acct12 = new Account(Name='Test AT 12',Bis_ID__c=100012, Client_Status__c='A');
        Account acct13 = new Account(Name='Test AT 13',Bis_ID__c=100013);
        Account acct14 = new Account(Name='Test AT 14',Bis_ID__c=100014);
        Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5,acct6,acct7,acct8,acct9,acct10,acct11,acct12,acct13,acct14};
        insert accts;
        
        Contact hrg = new Contact(FirstName='Joe',LastName='HRG',AccountId=acct6.Id);
        insert hrg;
        
        Asset[]products = new Asset[]{};
        
        //Skip Account1, should default to FLEX Client
        
        //Prospect
        acct2.Client_Status__c = 'P';
        
        //Sample
        acct3.Client_Status__c = 'S';
        
        //Paychex
        acct4.Client_Status__c = 'D';
        
        //Lost Client
        acct5.Client_Status__c = 'A';
        acct5.Lost_Date__c = yday;
        Asset a100 = new Asset(Name='100',Product_Plan_Code__c='100', Paychex_Asset_Id__c='100',Start_Date__c=Date.today(),Plan_Cancel_Date__c=yday,AccountId=acct5.Id);
        Asset a101 = new Asset(Name='101',Product_Plan_Code__c='101', Paychex_Asset_Id__c='101',Start_Date__c=Date.today(),Plan_Cancel_Date__c=yday,AccountId=acct5.Id);
        products.add(a100);
        products.add(a101);
        
        //PEO Client
        Asset a1029 = new Asset(Name='1029',Product_Plan_Code__c='1029', Paychex_Asset_Id__c='1029',Start_Date__c=Date.today(),Plan_Cancel_Date__c=null,AccountId=acct6.Id);
        products.add(a1029);
        acct6.HR_Generalist__c = hrg.id;
        
        //HR Solutions Advantage Client
        Asset a1005 = new Asset(Name='1005',Product_Plan_Code__c='1005', Paychex_Asset_Id__c='1005',Start_Date__c=Date.today(),Plan_Cancel_Date__c=null,AccountId=acct7.Id);
        products.add(a1005);
        //HR Solutions NPR Client
        Asset a1010 = new Asset(Name='1010',Product_Plan_Code__c='1010', Paychex_Asset_Id__c='1010',Start_Date__c=Date.today(),Plan_Cancel_Date__c=null,AccountId=acct8.Id);
        products.add(a1010);
        //HR Solutions FLEX Client
        Asset a884 = new Asset(Name='884',Product_Plan_Code__c='884', Paychex_Asset_Id__c='884',Start_Date__c=Date.today(),Plan_Cancel_Date__c=null,AccountId=acct9.Id);
        products.add(a884);
        //Advantage Client
        acct10.AccountNumber ='601-XXXX';
        
        //HRS Client Only
        acct11.Client_Status__c = 'A';
        acct11.Lost_Date__c = yDay;
        Asset a200 = new Asset(Name='200',Product_Plan_Code__c='200', Paychex_Asset_Id__c='200',Start_Date__c=Date.today(),Plan_Cancel_Date__c=yday,AccountId=acct11.Id);
        Asset a201 = new Asset(Name='201',Product_Plan_Code__c='201', Paychex_Asset_Id__c='201',Start_Date__c=Date.today(),Plan_Cancel_Date__c=null,AccountId=acct11.Id);
        products.add(a200);
        products.add(a201);
        
        //Preview Client
        acct12.AccountNumber ='401-XXXX';
        
        //HROi Client
        Asset aHROi = new Asset(Name='test',Product_Plan_Code__c='HROI Test', Start_Date__c=Date.today(),Plan_Cancel_Date__c=null,AccountId=acct13.Id);
        products.add(aHROi);
        acct13.HR_Generalist__c = hrg.id;
        
        //Oasis Client
        Asset aOasis = new Asset(Name='test',Product_Plan_Code__c='Oasis Test', Start_Date__c=Date.today(),Plan_Cancel_Date__c=null,AccountId=acct14.Id);
        products.add(aOasis);        
        
        update accts;
        
        insert products;
        system.debug('inserting products');
        //accts = new Account[]{acct1,acct2,acct3,acct4,acct5,acct6,acct10,acct11,acct12};
        
        Map<Id,Account> acctMap = new Map<Id,Account>([SELECT Id,Name,Type,HR_Generalist__c From Account WHERE Id in :accts]);

        System.assertEquals('FLEX Client',acctMap.get(acct1.Id).Type);
        System.assertEquals('Prospect',acctMap.get(acct2.Id).Type);
        System.assertEquals('Sample',acctMap.get(acct3.Id).Type);
        System.assertEquals('Paychex',acctMap.get(acct4.Id).Type);
        System.assertEquals(Label.AccountTypeLost,acctMap.get(acct5.Id).Type);
        System.assertEquals('PEO Client',acctMap.get(acct6.Id).Type);
        System.assertEquals('HR Solutions Advantage Client',acctMap.get(acct7.Id).Type);
        System.assertEquals('HR Solutions NPR Client',acctMap.get(acct8.Id).Type);
        System.assertEquals('HR Solutions FLEX Client',acctMap.get(acct9.Id).Type);
        System.assertEquals('Advantage Client',acctMap.get(acct10.Id).Type);
        System.assertEquals(Label.AccountTypeHRSOnly,acctMap.get(acct11.Id).Type);
        System.assertEquals('Preview Client',acctMap.get(acct12.Id).Type);
        System.assertEquals('HROi Client',acctMap.get(acct13.Id).Type);
        System.assertEquals('Oasis Client',acctMap.get(acct14.Id).Type);
      }
      Test.stopTest();
   } // testAccountType

   static testMethod void testupdateAssetEmps(){
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14514'
                                ,AccountNumber = '83-1234567'
                                ,Employees__c = 9
                                ,Larkspur_401k_Assets__c = 10000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct1;
        // insert new account with Sales Parent populated
        Account acct2 = new Account (name = 'Test Account3'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14515'
                                ,AccountNumber = '94-1234567'
                                ,SalesParent__c = acct1.Id
                                ,Employees__c = 5
                                ,Paychex_401k_Assets__c = null
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct2; 
        Account_Junction__c acctJuncBefore = [Select Id, Child_Account__c, Assets__c, Employees__c, Parent_Account__c 
                                                from Account_Junction__c where Child_Account__c = :acct2.Id];  
        Set<Id> juncIdSet = new Set<Id>();
        juncIdSet.add(acctJuncBefore.Id);
        AccountJunctionMethods.processParentAggregates(juncIdSet);
        
        acct1 = [select Id, Larkspur_401k_Assets__c, X401K_Assets__c, Paychex_401k_Assets__c, Child_Assets__c,
                    Employees__c, NumberOfEmployees, Child_Employees__c from Account where id = :acct1.Id];
        System.assertEquals(10000, acct1.X401K_Assets__c);
        System.assertEquals(14, acct1.NumberOfEmployees);
        
    } //testupdateAssetEmps
    

    static testMethod void testUpdateAccountFieldsMiEdge() {
        Schema.RecordTypeInfo mmsRT = RecordTypeHelper.getRecordType(Label.RT_MMS_Account, ObjectHelper.OBJECT_ACCOUNT);
        miedge_crm__Master_MSID__c msid = new miedge_crm__Master_MSID__c(Name = 'Test MSID'
                                                                         ,miedge_crm__WC_Carrier__c = 'Test WC Carrier' 
                                                                         ,miedge_crm__WC_Renewal_Date__c = Date.today()
                                                                         ,miedge_crm__Ben_Broker__c = 'Test Broker'
                                                                         ,miedge_crm__Exmod__c = 10.0
                                                                         ,miedge_crm__Ret_Plan_Assets__c = 2000
                                                                         ,miedge_crm__Ben_Renewal_Date__c = Date.today()
                                                                         ,Dental_Carrier__c = ''
                                                                         ,Vision_Carrier__c = ''
                                                                         ,miedge_crm__Ben_Lead_Carrier__c = 'Test Ben Lead Carrier');
        miedge_crm__Master_MSID__c msid2 = new miedge_crm__Master_MSID__c(Name = 'Test MSID 2'
                                                                         ,miedge_crm__WC_Carrier__c = 'Test WC Carrier 2' 
                                                                         ,miedge_crm__WC_Renewal_Date__c = Date.today()
                                                                         ,miedge_crm__Ben_Broker__c = 'Test Broker 2'
                                                                         ,miedge_crm__Exmod__c = 10.0
                                                                         ,miedge_crm__Ret_Plan_Assets__c = 3000
                                                                         ,miedge_crm__Ben_Renewal_Date__c = Date.today()
                                                                         ,Dental_Carrier__c = ''
                                                                         ,Vision_Carrier__c = ''
                                                                         ,miedge_crm__Ben_Lead_Carrier__c = 'Test Ben Lead Carrier 2');
        insert new miedge_crm__Master_MSID__c[]{msid,msid2};
        Account acct1 = new Account (name = 'Test Account1'
                                     ,recordtypeId = mmsRT.getRecordTypeId()
                                     ,ownerId = UserInfo.getUserId()
                                     ,BillingPostalCode = '14514'
                                     ,AccountNumber = '83-1234567'
                                     ,Employees__c = 60
                                     ,Larkspur_401k_Assets__c = 10000
                                     ,Do_Not_Call__c = true
                                     ,Workers_Comp_Carrier__c = ''
                                     ,H_B_Brokerage_Firm__c = ''
                                     ,H_B_Carrier__c = ''
                                     ,Workers_Comp_Ex_Mod__c = 0
                                     ,Work_Comp_Renewal_Date__c = ''
                                     ,H_B_Renewal_Date__c = ''
                                     ,miedge_crm__master_msid__c = msid.id
                                     ,miedge_crm__sync_date__c = Date.today() - 5
                                     ,Phone = '555-1212');
        Account acct2 = new Account (name = 'Test Account2'
                                     ,recordtypeId = mmsRT.getRecordTypeId()
                                     ,ownerId = UserInfo.getUserId()
                                     ,BillingPostalCode = '14514'
                                     ,AccountNumber = '83-1234568'
                                     ,Employees__c = 60
                                     ,Larkspur_401k_Assets__c = 10000
                                     ,Do_Not_Call__c = true
                                     ,Workers_Comp_Carrier__c = ''
                                     ,H_B_Brokerage_Firm__c = ''
                                     ,H_B_Carrier__c = ''
                                     ,Workers_Comp_Ex_Mod__c = 0
                                     ,Work_Comp_Renewal_Date__c = ''
                                     ,H_B_Renewal_Date__c = ''
                                     ,miedge_crm__master_msid__c = msid2.id
                                     ,miedge_crm__sync_date__c = Date.today() - 5
                                     ,Phone = '555-1212');
        Account[] accts = new Account[]{acct1,acct2};
        insert accts;
        
        miedge_crm__EB_Detail__c msidEb1 = new miedge_crm__EB_Detail__c(Name = 'Dental 1'
                                                                       ,miedge_crm__Enrolled_Employees__c = 1	
                                                                       ,miedge_crm__Master_MSID__c = msid.id
                                                                       ,miedge_crm__Carrier__c = 'Test Dental 1');
        miedge_crm__EB_Detail__c msidEb2 = new miedge_crm__EB_Detail__c(Name = 'Dental 100'
                                                                        ,miedge_crm__Enrolled_Employees__c = 100	
                                                                        ,miedge_crm__Master_MSID__c = msid.id
                                                                        ,miedge_crm__Carrier__c = 'Test Dental 100');
        miedge_crm__EB_Detail__c msidEb3 = new miedge_crm__EB_Detail__c(Name = 'Vision 1'
                                                                       ,miedge_crm__Enrolled_Employees__c = 1	 
                                                                       ,miedge_crm__Master_MSID__c = msid.id
                                                                       ,miedge_crm__Carrier__c = 'Test Vision 1');
        miedge_crm__EB_Detail__c msidEb4 = new miedge_crm__EB_Detail__c(Name = 'Vision 100'
                                                                        ,miedge_crm__Enrolled_Employees__c = 100	 
                                                                        ,miedge_crm__Master_MSID__c = msid.id
                                                                        ,miedge_crm__Carrier__c = 'Test Vision 100');
        miedge_crm__EB_Detail__c msidEb5 = new miedge_crm__EB_Detail__c(Name = 'Health 1'
                                                                       ,miedge_crm__Master_MSID__c = msid.id
                                                                       ,miedge_crm__Enrolled_Employees__c = 1	
                                                                       ,miedge_crm__Carrier__c = 'Test Health 1'
                                                                       ,miedge_crm__Renewal_Date__c = Date.newInstance(2020, 7, 31));
        miedge_crm__EB_Detail__c msidEb6 = new miedge_crm__EB_Detail__c(Name = 'Health 100'
                                                                       ,miedge_crm__Master_MSID__c = msid.id
                                                                       ,miedge_crm__Enrolled_Employees__c = 100	
                                                                       ,miedge_crm__Carrier__c = 'Test Health 100'
                                                                       ,miedge_crm__Renewal_Date__c = Date.newInstance(2020, 7, 31));
        miedge_crm__EB_Detail__c msidEb7 = new miedge_crm__EB_Detail__c(Name = 'Dental 2'
                                                                       ,miedge_crm__Enrolled_Employees__c = 2 
                                                                       ,miedge_crm__Master_MSID__c = msid2.id
                                                                       ,miedge_crm__Carrier__c = 'Test Dental 2');
        miedge_crm__EB_Detail__c msidEb8 = new miedge_crm__EB_Detail__c(Name = 'Vision 2'
                                                                       ,miedge_crm__Enrolled_Employees__c = 2 
                                                                       ,miedge_crm__Master_MSID__c = msid2.id
                                                                       ,miedge_crm__Carrier__c = 'Test Vision 2');
        miedge_crm__EB_Detail__c msidEb9 = new miedge_crm__EB_Detail__c(Name = 'Health 2'
                                                                       ,miedge_crm__Enrolled_Employees__c = 2 
                                                                       ,miedge_crm__Master_MSID__c = msid2.id
                                                                       ,miedge_crm__Carrier__c = 'Test Health 2'
                                                                       ,miedge_crm__Renewal_Date__c = Date.newInstance(2020, 8, 31));   
        miedge_crm__EB_Detail__c msidEb10 = new miedge_crm__EB_Detail__c(Name = 'Dental 200'
                                                                       ,miedge_crm__Enrolled_Employees__c = 200 
                                                                       ,miedge_crm__Master_MSID__c = msid2.id
                                                                       ,miedge_crm__Carrier__c = 'Test Dental 200');
        miedge_crm__EB_Detail__c msidEb11 = new miedge_crm__EB_Detail__c(Name = 'Vision 200'
                                                                       ,miedge_crm__Enrolled_Employees__c = 200 
                                                                       ,miedge_crm__Master_MSID__c = msid2.id
                                                                       ,miedge_crm__Carrier__c = 'Test Vision 200');
        miedge_crm__EB_Detail__c msidEb12 = new miedge_crm__EB_Detail__c(Name = 'Health 200'
                                                                       ,miedge_crm__Enrolled_Employees__c = 200 
                                                                       ,miedge_crm__Master_MSID__c = msid2.id
                                                                       ,miedge_crm__Carrier__c = 'Test Health 200'
                                                                       ,miedge_crm__Renewal_Date__c = Date.newInstance(2020, 8, 31)); 
        
        insert new miedge_crm__EB_Detail__c[]{msidEb1,msidEb2,msidEb3,msidEb4,msidEb5,msidEb6,msidEb7,msidEb8,msidEb9,msidEb10,msidEb11,msidEb12};
            
        Test.startTest();
        acct1.miedge_crm__Sync_Date__c = date.today();
        acct2.miedge_crm__Sync_Date__c = date.today();
        update accts;
        
        Account acct = [Select Id, Name, Larkspur_401k_Assets__c, Workers_Comp_Carrier__c, H_B_Brokerage_Firm__c, H_B_Carrier__c, Workers_Comp_Ex_Mod__c, Work_Comp_Renewal_Date__c, H_B_Renewal_Date__c, Dental_Carrier__c, Vision_Carrier__c, miedge_crm__master_msid__c 
                        from Account where id = :acct1.id limit 1];
        Account acctTwo = [Select Id, Name, Larkspur_401k_Assets__c, Workers_Comp_Carrier__c, H_B_Brokerage_Firm__c, H_B_Carrier__c, Workers_Comp_Ex_Mod__c, Work_Comp_Renewal_Date__c, H_B_Renewal_Date__c, Dental_Carrier__c, Vision_Carrier__c, miedge_crm__master_msid__c 
                        from Account where id = :acct2.id limit 1];        
                
        system.assertEquals(acct.Larkspur_401K_Assets__c, 2000);
        system.assertEquals(acct.Workers_Comp_Carrier__c, msid.miedge_crm__WC_Carrier__c);
        system.assertEquals(acct.H_B_Renewal_Date__c, 'July');
        system.assertEquals(acct.Dental_Carrier__c, 'Test Dental 100');
        system.assertEquals(acctTwo.Larkspur_401K_Assets__c, 3000);
        system.assertEquals(acctTwo.Workers_Comp_Carrier__c, msid2.miedge_crm__WC_Carrier__c);
        system.assertEquals(acctTwo.H_B_Renewal_Date__c, 'August');
        system.assertEquals(acctTwo.Dental_Carrier__c, 'Test Dental 200');
        
        Test.stopTest();
        
    }
    
    static testMethod void testSendCssrSegmentChatterNotifications() {
        Schema.RecordTypeInfo mmsRT = RecordTypeHelper.getRecordType(Label.RT_MMS_Account, ObjectHelper.OBJECT_ACCOUNT);
        Account acct1 = new Account (name = 'Test Account1'
                                     ,recordtypeId = mmsRT.getRecordTypeId()
                                     ,ownerId = UserInfo.getUserId()
                                     ,BillingPostalCode = '14514'
                                     ,AccountNumber = '83-1234567'
                                     ,Employees__c = 60
                                     ,Current_Owner_Id__c = UserInfo.getUserId()
                                     ,CSSR_Segment__c = true
                                     ,Client_Start_Date__c = Date.today() - 366
                                     ,Phone = '555-1212');
        insert acct1;
        
        User sfdcData = [SELECT Name,Id FROM User where Name='SFDC Data' LIMIT 1];
        User mmsRep = [SELECT Id FROM User WHERE Profile.Name = 'MMS Sales - SB' AND Sales_Org__c = 'MMS' AND IsActive = true LIMIT 1];
        ProcessNameMap__c pnm = new ProcessNameMap__c(Name=UserHelper.PREFIX_SFDC+sfdcData.Name,IsActive__c=true);
        insert pnm;
        Test.startTest();
        System.runAs(sfdcData){
            
            acct1.Current_Owner_ID__c = mmsRep.Id;
            update acct1;
        }
        //system.assertEquals(AccountMethods.sendCssrSegmentChatterNotifications().CHATTER_SENT, true);
        Test.stopTest();
    }

        /*BAU Changes*/
    static testMethod void testCreateAccountTeamMember(){

         User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 4];
         //Create Account
         Account a1 = new Account(Name='Account1', Relationship_Manager_PEO_Client_Advocate__c=users[0].Id);
         Account a2 = new Account(Name='Account2');
            // Id recid=Schema.SObjectType.Account.getRecordTypeInfosByName().get('MMS Account Record Type').getRecordTypeId();
            // a1.RecordtypeId=recid;
            //a1.Relationship_Manager_PEO_Client_Advocate__c=uCore.Id;
         insert new Account[]{a1,a2};
             
         Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, Relationship_Manager_PEO_Client_Advocate__c
                                                               ,(Select Id, UserId, TeamMemberRole from AccountTeamMembers)
                                                           From Account]);
         Account acct1 = acctMap.get(a1.Id);
         Assert.areEqual(1,acct1.AccountTeamMembers.size());
         Assert.areEqual(users[0].Id, acct1.AccountTeamMembers[0].UserId);
         Assert.areEqual(AccountMethods.ATM_REL_MGR, acct1.AccountTeamMembers[0].TeamMemberRole);
        
         
         Account acct2 = acctMap.get(a2.Id);
         Assert.areEqual(0,acct2.AccountTeamMembers.size());
        
         acct1.Relationship_Manager_PEO_Client_Advocate__c = users[1].Id;
         acct2.Relationship_Manager_PEO_Client_Advocate__c = users[2].Id;
         update new Account[]{acct1,acct2};
            
         acctMap = new Map<Id,Account>([Select Id, Name, Relationship_Manager_PEO_Client_Advocate__c
                                                               ,(Select Id, UserId, TeamMemberRole from AccountTeamMembers)
                                                           From Account]);
         acct1 = acctMap.get(a1.Id);
         Assert.areEqual(1,acct1.AccountTeamMembers.size());
         Assert.areEqual(users[1].Id, acct1.AccountTeamMembers[0].UserId);
         Assert.areEqual(AccountMethods.ATM_REL_MGR, acct1.AccountTeamMembers[0].TeamMemberRole);
         
         acct2 = acctMap.get(a2.Id);
         Assert.areEqual(1,acct2.AccountTeamMembers.size());
         Assert.areEqual(users[2].Id, acct2.AccountTeamMembers[0].UserId);
         Assert.areEqual(AccountMethods.ATM_REL_MGR, acct2.AccountTeamMembers[0].TeamMemberRole);
        
         acct1.Relationship_Manager_PEO_Client_Advocate__c = null;
         update new Account[]{acct1,acct2};
            
         acctMap = new Map<Id,Account>([Select Id, Name, Relationship_Manager_PEO_Client_Advocate__c
                                                               ,(Select Id, UserId, TeamMemberRole from AccountTeamMembers)
                                                           From Account]);
         acct1 = acctMap.get(a1.Id);
         Assert.areEqual(0,acct1.AccountTeamMembers.size());
         
         acct2 = acctMap.get(a2.Id);
         Assert.areEqual(1,acct2.AccountTeamMembers.size());
         Assert.areEqual(users[2].Id, acct2.AccountTeamMembers[0].UserId);
         Assert.areEqual(AccountMethods.ATM_REL_MGR, acct2.AccountTeamMembers[0].TeamMemberRole);
   
       } // testCreateAccountTeamMember
   
    static testMethod void testUpsertAccountProductSensitvities1(){
        test.startTest();
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14514'
                                ,AccountNumber = '83-1234567'
                                ,Employees__c = 9
                                ,Restricted_Industry__c = 'CRB'     
                                ,Larkspur_401k_Assets__c = 10000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct1;
        
        Account_Product_Sensitivities__c apsObj = [Select Id,Oasis_401k_Sensitivity__c,X401k_Sensitivity_Reason__c from Account_Product_Sensitivities__c where Prospect_Client__c =: acct1.Id LIMIT 1];
        
        System.assert(apsObj!=null);
        System.assertEquals(True, apsObj.Oasis_401k_Sensitivity__c);
        System.assertEquals('672249', apsObj.X401k_Sensitivity_Reason__c);
        test.stopTest();
    }
    
    static testMethod void testUpsertAccountProductSensitvities2(){
        test.startTest();
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        // insert new account with Sales Parent populated
        Account acct2 = new Account (name = 'Test Account3'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14515'
                                ,AccountNumber = '94-1234567'
                                ,Employees__c = 5
                                ,Paychex_401k_Assets__c = null
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct2;
        
        Account_Product_Sensitivities__c newAPS = new Account_Product_Sensitivities__c(); 
        newAPS.Prospect_Client__c = acct2.Id;
        newAPS.Oasis_401k_Sensitivity__c = false;
        newAPS.X401k_Sensitivity_Reason__c = 'Oasis';
        insert newAPS;
        
        acct2.Restricted_Industry__c = 'CRB';
        update acct2;
        
        Account_Product_Sensitivities__c apsObj = [Select Id,Oasis_401k_Sensitivity__c,X401k_Sensitivity_Reason__c from Account_Product_Sensitivities__c where Prospect_Client__c =: acct2.Id LIMIT 1];
        
        System.assert(apsObj!=null);
        System.assertEquals(True, apsObj.Oasis_401k_Sensitivity__c);
        System.assertEquals('672249', apsObj.X401k_Sensitivity_Reason__c);
        test.stopTest();
    }
       /*BAU Changes*/
    
} // class AccountMethodsTest