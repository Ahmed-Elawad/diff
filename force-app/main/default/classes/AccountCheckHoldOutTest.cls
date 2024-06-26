/* 
  Tests for the AccountCheckHoldOut trigger. 
   
  History
  -------
   07/02/2009 Dan Carmen   Created
   07/17/2018 Dan Carmen         Comment out test due to hold out changes
   
 */
@isTest
private class AccountCheckHoldOutTest {

   static Account getAccount(ID idValue) {
      return [select name, Hold_Out__c, ownerId from Account where Id=:idValue];
   } // getAccount

   static testMethod void testTrigger() {
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
   } // testTrigger
    
} // AccountCheckHoldOutTest