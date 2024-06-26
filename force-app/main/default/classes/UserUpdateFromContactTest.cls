/* 
 * The test methods for the UserUpdateFromContact class.
 *
 * History
 * -------
 * 09/22/2010 Dan Carmen   Created
 * 12/30/2010 Dan Carmen   Added in check for using Preferred Name from Contact.
   06/28/2012 Dan Carmen   Modified to use JobHelper class
   09/12/2013 Dan Carmen   Fix System.NullPointerException
   04/22/2015 Dan Carmen   Change to set user record to inactive if needed.
   10/16/2017 Dan Carmen   Code Cleanup
   01/18/2018 Dan Carmen   Move logic to ContactFormatPaychexEmps
   06/17/2020 Dan Carmen   New logic to make this class a Rest Service
   11/02/2023 Dan Carmen   Comment out code

*/
@isTest
private class UserUpdateFromContactTest {

   static testMethod void testPost() {
      new UserUpdateFromContact();
      /*
      Account acct = new Account(Name='Account');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      Contact ctct = new Contact(AccountId=acct.Id, LastName='ContactLast');
      insert ctct;
      Id[] ctctIds = new Id[]{ctct.Id};
      UserUpdateFromContact.doPost(ctctIds);
      */
   } // testPost

} // class UserUpdateFromContactTest