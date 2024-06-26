/* 
 * Test methods for the ClientOverViewController class.
 *
 * History
 * -------
 * 05/30/2012 John Callan        Created.
 * 07/30/2012 Justin Stouffer    Revised.
 * 07/18/2016 Josh Cartwright    revised
 * 10/06/2017 Jacob Hinds        removing testBUPrimaryClientIsTrue so we can delete those fields.
 * 03/08/2018 Jacob Hinds        removing S125 Account Health so we can delete that field
 *
 */
@isTest
public with sharing class ClientOverViewControllerTest {

  static testMethod void testatRisk() {
      // create an Account to search
      Account acct = new Account(Name='ClientOverviewTestClient Record0',X401k_S125_Account_Health__c='At Risk', 
                                 TAA_Account_Health__c='At Risk', 
                                 MMS_Account_Health__c='At Risk', Premier_Account_Health__c='At Risk', 
                                 HRO_Account_Health__c='At Risk',                               
                                 Do_Not_Call__c=true, Email_Opt_Out__c=true);
      insert acct;

      //Set the current page to the account we are testing
      ApexPages.currentPage().getParameters().put('Id',acct.Id);

      //Create the controller
      ClientOverviewController coc = new ClientOverviewController(new ApexPages.StandardController(acct));

      //Test that the output string is what we expect
      System.assertEquals('   401K\n   TAA\n   Preview\n   HR Solutions\n   HRO',coc.atRisk);
      
      //JC tests for new properties 
      system.assert(!coc.isCurrentClient);
      system.assert(!coc.isReferralRecord); 
      
      list <user> usr = [select name from user where Sales_Org__c = 'PAY' limit 1]; 
      system.assert (usr.size()==1);      
      system.assert(!coc.isSalesProfile); 
   } // testAtRisk
   
  static testMethod void testPotentialRisk() {
      // create an Account to search
      Account acct = new Account(Name='ClientOverviewTestClient Record1',X401k_S125_Account_Health__c='Potential Risk', 
                                 TAA_Account_Health__c='Potential Risk', 
                                 MMS_Account_Health__c='Potential Risk', Premier_Account_Health__c='Potential Risk', 
                                 HRO_Account_Health__c='Potential Risk', 
                                 Do_Not_Call__c=true,Email_Opt_Out__c=true);
      insert acct;

      //Set the current page to the account we are testing
      ApexPages.currentPage().getParameters().put('Id',acct.Id);

      //Create the controller
      ClientOverviewController coc = new ClientOverviewController(new ApexPages.StandardController(acct));

      //Test that the output string is what we expect
      System.assertEquals('   401K\n   TAA\n   MMS\n   HR Solutions\n   HRO',coc.PotentialRisk);
   } // testPotentialRisk
   
   static testMethod void testDNCEIndicatorDoNotCallIsTrueEmailOptOutIsFalse() {
      // create an Account to search
      Account acct = new Account(Name='ClientOverviewTestClient Record2',
                                 Do_Not_Call__c=true,Email_Opt_Out__c=false);
      insert acct;

      //Set the current page to the account we are testing
      ApexPages.currentPage().getParameters().put('Id',acct.Id);

      //Create the controller, using the Account ID only to test the constructor
      ClientOverviewController coc = new ClientOverviewController(acct.Id);

      //Test that the output string is what we expect
      System.assertEquals('   Do Not Call',coc.DNCEIndicator);
   } // testDNCEIndicatorDoNotCallIsTrueEmailOptOutIsFalse
   
   static testMethod void testDNCEIndicatorDoNotCallIsFalseEmailOptOutIsTrue() {
      // create an Account to search
      Account acct = new Account(Name='ClientOverviewTestClient Record3', 
                                 Do_Not_Call__c=false, Email_Opt_Out__c=true);
      insert acct;

      //Set the current page to the account we are testing
      ApexPages.currentPage().getParameters().put('Id',acct.Id);

      //Create the controller
      ClientOverviewController coc = new ClientOverviewController(new ApexPages.StandardController(acct));

      //Test that the output string is what we expect
      System.assertEquals('   Do Not Email',coc.DNCEIndicator);
   } // testDNCEIndicatorDoNotCallIsFalseEmailOptOutIsTrue
   
   static testMethod void testDNCEIndicatorDoNotCallIsTrueEmailOptOutIsTrue() {
      // create an Account to search
      Account acct = new Account(Name='ClientOverviewTestClient Record4',
                                 Do_Not_Call__c=true, Email_Opt_Out__c=true);
      insert acct;

      //Set the current page to the account we are testing
      ApexPages.currentPage().getParameters().put('Id',acct.Id);

      //Create the controller
      ClientOverviewController coc = new ClientOverviewController(new ApexPages.StandardController(acct));

      //Test that the output string is what we expect
      System.assertEquals('   Do Not Call\n   Do Not Email',coc.DNCEIndicator);
   } // testDNCEIndicatorDoNotCallIsTrueEmailOptOutIsFalse
  /*
   static testMethod void testBUPrimaryClientIsTrue() {
      // create an Account to search
      Account acct = new Account(Name='ClientOverviewTestClient Record5', Primary_Client_HR_Solutions__c=true,
                                 Primary_Client_401K__c=true, Primary_Client_S125__c=true,
                                 Primary_Client_HRO__c=true, Primary_Client_TLO__c=true,
                                 Primary_Client_Payroll_Core__c=true, Primary_Client_Payroll_MMS__c=false,
                                 Primary_Client_H_B__c=true, Primary_Client_Workers_Comp__c=false, 
                                 Do_Not_Call__c=true, Email_Opt_Out__c=true);
      insert acct;

      //Set the current page to the account we are testing
      ApexPages.currentPage().getParameters().put('Id',acct.Id);

      //Create the controller
      ClientOverviewController coc = new ClientOverviewController(new ApexPages.StandardController(acct));

      //Test that the output string is what we expect
      System.assertEquals('   401K\n   H&B\n   HRO\n   HR Solutions\n   Payroll-Core\n   S125\n   TLO',
                          coc.BUPrimaryClient);
   } // testBUPrimaryClientIsTrue
   */
   static testMethod void testSave() {
      // create an Account to search
      Account acct = new Account(Name='ClientOverviewTestClient Record5');
      insert acct;

      //Set the current page to the account we are testing
      ApexPages.currentPage().getParameters().put('Id',acct.Id);

      //Create the controller
      ClientOverviewController coc = new ClientOverviewController(new ApexPages.StandardController(acct));
      
      //Set a value for the Client Critical Notes field, but do  not update acct
      acct.Critical_Client_Notes__c = 'This is a critical note';
      
      //Save using the Client Overview Controller Save method
      coc.SaveButton();
      
      Account acct2 = [select Critical_Client_Notes__c from Account where ID=:acct.id];
      
      //Test that the save was successful
      System.assertEquals(acct.Critical_Client_Notes__c,
                          acct2.Critical_Client_Notes__c);
   } // testSaveButton

}