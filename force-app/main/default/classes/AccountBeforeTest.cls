/* 
  Tests for the AccountBefore trigger. 
   
  History
  -------
   07/27/2011 Dan Carmen   Created
   01/19/2016 Dan Carmen         User Owned Shipping Address checkbox doesn't reset when record type changes.
   01/27/2017 Cindy Freeman      added test for asset employee calc
   03/22/2017 Cindy Freeman      modified test for new Account Junction code
   07/17/2018 Dan Carmen         Comment out test due to hold out changes
   01/10/2024 Dan Carmen      Added a field to Skip the Paychex triggers on the account

 */
@isTest
private class AccountBeforeTest {

   static Account getAccount(ID idValue) {
      return [select Id, Name
                    ,Hold_Out__c
                    ,User_Owned_Shipping_Address__c
                    ,ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                    ,ownerId, RecordTypeId
                    ,AccountNumber, Bis_ID__c 
                from Account where Id=:idValue];
   } // getAccount

   static testMethod void testCheckHoldOut() {
      UserHelperTest.setupGenericUsers();
      // run as the sfdc data user
      User sdata = [select id from User where Name = :UserHelper.SFDC_DATA limit 1];
      Profile p = [select id from profile where name='System Administrator'];
      User u1 = [select id, isActive from User where profileId = :p.Id and isActive=true and Id != :sdata.Id and Id != :UserInfo.getUserId() limit 1];
      User u2 = [select id, isActive from User where profileId = :p.Id and isActive=true and Id != :sdata.Id  and Id != :UserInfo.getUserId() and Id != :u1.Id limit 1];
    
        
      User sa = [select id, isActive from User where Id = :UserInfo.getUserId() limit 1];
      // run as system administrator
      System.RunAs(sa) {
         Account a1 = new Account(name='Test a1',ownerId=u1.Id);
         insert a1;
         a1 = getAccount(a1.Id);
         System.assertEquals(a1.OwnerId,u1.Id);
         a1.Hold_Out__c = true;
         a1.Permanent_Hold_Out_Description__c = 'ADMIN';
         update a1;
         a1 = getAccount(a1.Id);
         // this should allow the owner to change
         a1.OwnerId = u2.Id;
         update a1;
         a1 = getAccount(a1.Id);
         System.assertEquals(a1.OwnerId,u2.Id);
      } // System.RunAs(sa)
        
      // run as sfdc data
      System.RunAs(sdata) {
         Account a1 = new Account(name='Test a1',ownerId=u1.Id);
         insert a1;
         a1 = getAccount(a1.Id);
         System.assertEquals(a1.OwnerId,u1.Id);
         a1.Hold_Out__c = true;
         a1.Permanent_Hold_Out_Description__c = 'ADMIN';
         update a1;
         a1 = getAccount(a1.Id);
         // this should not allow the owner to change
         a1.OwnerId = u2.Id;
         update a1;
         a1 = getAccount(a1.Id);
         //System.assertEquals(a1.OwnerId,u1.Id);
      } // System.RunAs(sdata)
   } // testCheckHoldOut
    
   static testMethod void testAddressChange() {
      // get the sfdc data user
      User sdata = [select id from User where Name = :UserHelper.SFDC_DATA limit 1];
      UserHelperTest.setupGenericUsers();
    
      Profile p = [select id from profile where name='System Administrator'];
      User sa = [select id, isActive from User where profileId = :p.Id and isActive=true and Id != :sdata.Id limit 1];
        // run as a generic system administrator
        System.RunAs(sa) {
           // create an account
           Account a1 = new Account(name='Test a1'
                                   ,User_Owned_Shipping_Address__c=false
                                   ,ShippingStreet='123 Any Street'
                                   ,ShippingCity='Somewhere'
                                   ,ShippingState='NY'
                                   ,ShippingPostalCode='12345'
                                   ,ShippingCountry='USA'
                                   ,ownerId=sa.Id);
           insert a1;
           a1 = getAccount(a1.Id);
           // make sure changes can still be made if the flag is false
           a1.ShippingStreet = '987 This Ave';
           a1.ShippingCity = 'This Place';
           a1.ShippingState = 'MI';
           a1.ShippingPostalCode = '32456';
           a1.ShippingCountry = 'CA';
           update a1;
           a1 = getAccount(a1.Id);
           System.assertEquals('987 This Ave',a1.ShippingStreet);
           System.assertEquals('This Place',a1.ShippingCity);
           System.assertEquals('MI',a1.ShippingState);
           System.assertEquals('32456',a1.ShippingPostalCode);
           System.assertEquals('CA',a1.ShippingCountry);

           // set the flag and ensure that changes will still occur
           a1.User_Owned_Shipping_Address__c = true;
           a1.ShippingStreet = '456 That Place';
           a1.ShippingCity = 'Some City';
           a1.ShippingState = 'NY';
           a1.ShippingPostalCode = '12345';
           a1.ShippingCountry = 'USA';
           update a1;
           a1 = getAccount(a1.Id);
           System.assertEquals('456 That Place',a1.ShippingStreet);
           System.assertEquals('Some City',a1.ShippingCity);
           System.assertEquals('NY',a1.ShippingState);
           System.assertEquals('12345',a1.ShippingPostalCode);
           System.assertEquals('USA',a1.ShippingCountry);
        } // System.RunAs(sa)
        
        // run as sfdc data
        System.RunAs(sdata) {
           // create an account
           Account a1 = new Account(name='Test a1'
                                   ,User_Owned_Shipping_Address__c=false
                                   ,ShippingStreet='123 Any Street'
                                   ,ShippingCity='Somewhere'
                                   ,ShippingState='NY'
                                   ,ShippingPostalCode='12345'
                                   ,ShippingCountry='USA'
                                   ,ownerId=sa.Id);
           insert a1;
           a1 = getAccount(a1.Id);
           // make sure changes can still be made if the flag is false
           a1.ShippingStreet = '987 This Ave';
           a1.ShippingCity = 'This Place';
           a1.ShippingState = 'MI';
           a1.ShippingPostalCode = '32456';
           a1.ShippingCountry = 'CA';
           update a1;
           a1 = getAccount(a1.Id);
           System.assertEquals('987 This Ave',a1.ShippingStreet);
           System.assertEquals('This Place',a1.ShippingCity);
           System.assertEquals('MI',a1.ShippingState);
           System.assertEquals('32456',a1.ShippingPostalCode);
           System.assertEquals('CA',a1.ShippingCountry);

           // set the flag and ensure that changes will are made
           a1.User_Owned_Shipping_Address__c = true;
           a1.ShippingStreet = '456 That Place';
           a1.ShippingCity = 'Some City';
           a1.ShippingState = 'NY';
           a1.ShippingPostalCode = '12345';
           a1.ShippingCountry = 'USA';
           update a1;
           a1 = getAccount(a1.Id);
           System.assertEquals('987 This Ave',a1.ShippingStreet);
           System.assertEquals('This Place',a1.ShippingCity);
           System.assertEquals('MI',a1.ShippingState);
           System.assertEquals('32456',a1.ShippingPostalCode);
           System.assertEquals('CA',a1.ShippingCountry);
        } // System.RunAs(sdata)
    } // testAddressChange
        
   static testMethod void testAccountNumber() {
      // create 2 Accounts
      Account a1 = new Account(name='Test a1');
      Account a2 = new Account(name='Test a2',Bis_ID__c=7);
      Account[] accts = new Account[]{a1,a2};
      insert accts;
      
      //update the Account number on both
      a1.AccountNumber = '123-test1234';
      a2.AccountNumber = '123-test4567';
      // update 
      update accts;
      
      a1 = getAccount(a1.Id);
      System.assertEquals('123-TEST1234',a1.AccountNumber);
      a2 = getAccount(a2.Id);
      System.assertEquals('123-test4567',a2.AccountNumber);
   } // testAccountNumber
  
  static testMethod void testupdateAssetEmps(){
     AccountJunctionMethodsTest.setupCustomSettings();
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14514'
                                ,AccountNumber = '83-1234567'
                                ,Employees__c = 9
                                ,Paychex_401k_Assets__c = null
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
                                ,Larkspur_401k_Assets__c = 10000
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
    
    static testMethod void testSkipTriggers() {
       Account acct1 = new Account(Name='Account1', SkipTriggers__c=true);
       Account acct2 = new Account(Name='Account2', SkipTriggers__c=true);
       Account acct3 = new Account(Name='Account3', SkipTriggers__c=true);
       Account acct4 = new Account(Name='Account4', SkipTriggers__c=true);
       insert new Account[]{acct1,acct2,acct3,acct4};
       Assert.areEqual(0,[Select count() from Account where SkipTriggers__c=true]);
    } // testSkipTriggers

} // class AccountBeforeTest