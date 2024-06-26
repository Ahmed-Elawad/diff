/* 
  Tests for the AccountCheckShippingAddress trigger. 
   
   History
   -------
   07/07/2009 Dan Carmen   Created
   01/19/2016 Dan Carmen         User Owned Shipping Address checkbox doesn't reset when record type changes.
   
 */
@isTest
private class AccountCheckShippingAddressTest {

   static Account getAccount(ID idValue) {
      return [select name, User_Owned_Shipping_Address__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ownerId, RecordTypeId from Account where Id=:idValue];
   } // getAccount

/*
   static testMethod void testRecordTypeChange() {
   	  RecordType rtCore = [select id, name from RecordType where name=:AccountHelper.CORE_ACCOUNT];
      RecordType rtMms = [select id, name from RecordType where name=:AccountHelper.MMS_ACCOUNT];
      Account a1 = new Account(name='Test a1'
                              ,User_Owned_Shipping_Address__c=true
                              ,RecordTypeId = rtCore.Id);
      insert a1;
      a1 = getAccount(a1.Id);
      System.assertEquals(true,a1.User_Owned_Shipping_Address__c);
      // record type changes, flag should reset back to false
      a1.RecordTypeId = rtMms.Id;
      update a1;
      a1 = getAccount(a1.Id);
      System.assertEquals(false,a1.User_Owned_Shipping_Address__c);
      
   } // testRecordTypeChange
  */ 
   static testMethod void testAddressChange() {
   	
      UserHelperTest.setupGenericUsers();
      // get the sfdc data user
      User sdata = [select id from User where Name = :UserHelper.SFDC_DATA limit 1];
   	
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

           // set the flag and ensure that changes are made
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
        
} // class AccountCheckShippingAddressTest