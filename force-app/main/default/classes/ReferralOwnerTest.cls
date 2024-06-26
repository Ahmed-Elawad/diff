/** The test methods for ReferralAccountCheckOwner and ReferralContactCheckOwner triggers - checks hold out flags.
 *
 * History
 * -------
 * 09/03/2009 Dan Carmen   Created
   11/15/2017 Dan Carmen   Update version
   04/12/2022 Dan Carmen   Logic was moved elsewhere - commented out code. 
*/
@isTest
private class ReferralOwnerTest {

   static testMethod void testOwners() {
      User user1 = [select id, isActive from User where Id = :UserInfo.getUserId() limit 1];
      User user2 = [select id, isActive from User where profile.Name = 'System Administrator' and isActive=true and Id != :UserInfo.getUserId() limit 1];
/*     

      Referral_Contact__c rc1 = new Referral_Contact__c(name='Contact 1'
                          , ownerId=user1.id);
      insert rc1;
      rc1 = [select name,ownerId,User_Lookup__c,Number_of_Payroll_Clients__c,Hold_Out__c from Referral_Contact__c where id=:rc1.id];
      System.assertEquals(rc1.ownerId,user1.id);
      System.assertEquals(rc1.ownerId,rc1.User_Lookup__c);
      rc1.Hold_Out__c = true;
      update rc1;
      System.assertEquals(rc1.Hold_Out__c,true);
      rc1.ownerId=user2.id;
      rc1.Number_of_Payroll_Clients__c=10;
      update rc1;
      rc1 = [select name,ownerId,User_Lookup__c,Number_of_Payroll_Clients__c,Hold_Out__c from Referral_Contact__c where id=:rc1.id];
      System.assertEquals(rc1.ownerId,user1.id);
      System.assertEquals(rc1.Number_of_Payroll_Clients__c,10);
      rc1.Hold_Out__c = false;
      rc1.ownerId=user2.id;
      rc1.Number_of_Payroll_Clients__c=12;
      update rc1;
      rc1 = [select name,ownerId,Number_of_Payroll_Clients__c,Hold_Out__c from Referral_Contact__c where id=:rc1.id];
      System.assertEquals(rc1.ownerId,user2.id);
      System.assertEquals(rc1.Number_of_Payroll_Clients__c,12);
        
      Referral_Account__c ra1 = new Referral_Account__c(name='Test Account1', ownerId=user1.id);
      insert ra1;
      System.assertEquals(ra1.ownerId,user1.id);
      ra1.Hold_Out__c = true;
      update ra1;
      System.assertEquals(ra1.Hold_Out__c,true);
      ra1.ownerId=user2.id;
      update ra1;
      ra1 = [select name,ownerId,Hold_Out__c from Referral_Account__c where id=:ra1.id];
      System.assertEquals(ra1.ownerId,user1.id);
      ra1.Hold_Out__c = false;
      ra1.ownerId=user2.id;
      update ra1;
      ra1 = [select name,ownerId,Hold_Out__c from Referral_Account__c where id=:ra1.id];
      System.assertEquals(ra1.ownerId,user2.id);
*/        
        
   } // testOwners
    
} // class ReferralOwnerTest