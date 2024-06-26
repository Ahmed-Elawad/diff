/* 
 * Test methods for the SObjectHelper class
 *
 * History
 * -------
 * 04/27/2011 Dan Carmen   Created
   06/23/2011 Dan Carmen   New tests for globalDescribe functions.
   09/09/2011 Dan Carmen   Additional functionality to the checkField method
   10/26/2018 Dan Carmen   Increment API to version 44

 */
@isTest
private class SObjectHelperTest {

   static testMethod void testUpsertSuccess() {
      // create two objects
      Account a1 = new Account(Name='Test 1');
      insert a1;
      a1.ShippingPostalCode = '14514';
      Account a2 = new Account(Name='Test 2');
      Account[] accts = new Account[]{a1,a2};
      SObjectHelper soh = new SObjectHelper();
      System.assertEquals(true,soh.saveRecords(accts, null, null));
      // verify a2 saved
      System.assertEquals(true,(a2.Id != null));
      
      // save Contacts against a1
      Contact c1 = new Contact(FirstName='James', LastName='Test', AccountId=a1.Id);
      insert c1;
      c1.FirstName='Jimmy';
      Contact c2 = new Contact(FirstName='Timmy', LastName='Test');
      Contact c3 = new Contact(FirstName='Tina', LastName='Test');
      Contact[] ctcts = new Contact[]{c1,c2,c3};
      System.assertEquals(true,soh.saveRecords(ctcts, 'AccountId', a1.Id));
      
      // verify records saved
      System.assertEquals(true,(c2.Id != null));
      System.assertEquals(true,(c3.Id != null));
      // verify records saved with updated data
      c1 = [Select FirstName, LastName, AccountId from Contact where Id=:c1.Id];
      System.assertEquals('Jimmy',c1.FirstName);
      c2 = [Select FirstName, LastName, AccountId from Contact where Id=:c2.Id];
      System.assertEquals(a1.Id,c2.AccountId);
      c3 = [Select FirstName, LastName, AccountId from Contact where Id=:c3.Id];
      System.assertEquals(a1.Id,c3.AccountId);
      
      // test failure - required field missing
      Contact c4 = new Contact(FirstName='Tommy');
      Contact c5 = new Contact(FirstName='Teddy', LastName='Test');
      ctcts = new Contact[]{c4,c5};
      System.assertEquals(false,soh.saveRecords(ctcts, 'AccountId', a1.Id));
   } // testUpsertSuccess
   
   /** Test the SObjectType methods. */ 
   static testMethod void testSObjectType() {
   	  SObjectHelper soHelper = new SObjectHelper();
      System.assertEquals(null,soHelper.getSObjectType('ThisIsNotAnObject'));
      System.assertEquals(Schema.SObjectType.Case.getSobjectType(),soHelper.getSObjectType('Case'));
   } // testSObjectType
   
   static testMethod void testSObjectField() {
   	  SObjectHelper soHelper = new SObjectHelper();
   	  // test with fake object
   	  System.assertEquals(false,soHelper.checkField('ThisIsNotAnObject','ThisIsNotAFieldName'));
   	  // test with real object and fake field name
   	  System.assertEquals(false,soHelper.checkField('Account','ThisIsNotAFieldName'));
   	  // test with real object and real field name
   	  System.assertEquals(true,soHelper.checkField('Account','Name'));
   	  // test different access levels
   	  System.assertEquals(true,soHelper.checkField('Account','Name',null));
   	  System.assertEquals(true,soHelper.checkField('Account','Name','access'));
   	  System.assertEquals(true,soHelper.checkField('Account','Name','update'));
   	  System.assertEquals(true,soHelper.checkField('Account','Name','create'));
   	  System.assertEquals(false,soHelper.checkField('Account','Name','writeRequireMasterRead'));
   	  System.assertEquals(false,soHelper.checkField('Account','Name','thisisnotarealaction'));
   } // testSObjectField
   
   static testMethod void testDoObjectsExist() {
      SObjectHelper soHelper = new SObjectHelper();
      // test will null parameter
      Map<String,Boolean> results = soHelper.doObjectsExist(null);
      // verify empty map is returned
      System.assertEquals(0,results.size());

   	  // object names to test
      String[] objectNames = new String[]{'Account','Lead','BadObjectName1','BadObjectName2','Case'};
      results = soHelper.doObjectsExist(objectNames);
      // verify number of results is correct
      System.assertEquals(5,results.size());
      // check the results
      System.assertEquals(true,results.get(objectNames.get(0)));
      System.assertEquals(true,results.get(objectNames.get(1)));
      System.assertEquals(false,results.get(objectNames.get(2)));
      System.assertEquals(false,results.get(objectNames.get(3)));
      System.assertEquals(true,results.get(objectNames.get(4)));
   } // testDoObjectsExist
   
} // SObjectHelperTest