/* 
*  Written by Christophe Soulet for Salesforce.com Extensions.
    on June 29th 2006 per Tom Muskatevc's instructions:
    
    "Here are the requirements for the Apex Trigger for "Hosted Clients" that
    we would like you to build.

    When an Account (Prospect-Client) record is Inserted or Updated and the
    following condition is true:

    Account.Hosted_Client__c = TRUE (checked)

    Then do the following:

    Change the Account Owner to = SFDC Data (00530000000y8c8)
    Change all the related Contacts Owner = to SFDC Data (00530000000y8c8)
    Change the Account.Hold_Out__c field to = TRUE (checked)"
        

* History
* ------------------
06/29/2006  Christophe Soulet     Created
04/09/2020  Dan Carmen            Changed to use CreateTestData for account/contact record type info

*/
@isTest
public class hostedAccountContactTestClass {
    
   static testMethod void testHostedClient() {
      User sfdcData = UserHelper.getSfdcData();
      
      // run as someone other than sfdc data
      User systemAdmin = [Select Id, Name from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true limit 1];

      System.runAs(systemAdmin) {
      	
         Schema.RecordTypeInfo rtAcct = CreateTestData.getDefaultProspectAcctRT();
         Schema.RecordTypeInfo rtCtct = CreateTestData.getDefaultSalesContactRT();

         Account acct = new Account(Name='Test Hosted', Hosted_Client__c=true, RecordTypeId=rtAcct.getRecordTypeId());
         insert acct;

         acct = getAccount(acct.Id);
      
         System.assertEquals(acct.OwnerId, sfdcData.Id);
         System.assertEquals(acct.Hold_Out__c, true);
         System.assertEquals(acct.Permanent_Hold_Out_Description__c, HostedAccountContact.HOSTED);
      
         // add in some contacts
         Contact[] ctcts = new Contact[]{};
         ctcts.add(new Contact(AccountId=acct.Id, FirstName='Jimmy', LastName='Contact1')); //, Sales_Contact__c=true, RecordTypeId=rtCtct.getRecordTypeId()));
         ctcts.add(new Contact(AccountId=acct.Id, FirstName='Sally', LastName='Contact2')); //, Sales_Contact__c=true, RecordTypeId=rtCtct.getRecordTypeId()));
         insert ctcts;
      
         acct = getAccount(acct.Id);

         System.assertEquals(2,acct.Contacts.size());


         //Test.startTest();
         //update acct;
         //Test.stopTest();
         Account[] accountsToCheck = new Account[]{acct};
         hostedAccountContact.checkHostedOwner(accountsToCheck, true);
         
         acct = getAccount(acct.Id);
      
         System.assertEquals(acct.OwnerId, sfdcData.Id);
         System.assertEquals(acct.Hold_Out__c, true);
         System.assertEquals(acct.Permanent_Hold_Out_Description__c, HostedAccountContact.HOSTED);
         System.assertEquals(acct.Contacts.size(), 2);
      
         for (Contact ctct : acct.Contacts) {
            System.assertEquals(ctct.OwnerId, sfdcData.Id);
            System.assertEquals(ctct.Hold_Out__c, true);
            System.assertEquals(ctct.Hold_Out_Reason__c, HostedAccountContact.HOSTED);
         } // for (Contact ctct
      
      } // System.runAs

   } // testHostedClient
    
   private static Account getAccount(Id acctId) { 
      Account acct = [Select Id, Name, OwnerId, Hosted_Client__c, Hold_Out__c, Permanent_Hold_Out_Description__c
                           ,(Select Id, OwnerId, Hold_Out__c, Hold_Out_Reason__c from Contacts)
                       from Account
                      where Id = :acctId];
      return acct;
   } // getAccount
   
} // hostedAccountContactTestClass