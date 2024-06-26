/* 
 * Test method for checking if the HR Person Id field is getting populated.
 *
 * History
 * -------
 * 07/13/2010 Dan Carmen   Created
   11/15/2017 Dan Carmen   Update test and API version
 *
 */
@isTest
private class UserCheckPersonIdTest {

   public static String testUsername='jjoffer@paychex.com.testing';

   @testSetup
   private static void setupData() {
      Profile p = [Select Id from Profile where Name='Standard User'];
      UserRole ur = [Select Id from UserRole where Name='System Administrator'];
      // create a new user
      User u1 = new User(FirstName = 'Jaffe'
                        ,LastName = 'Joffer'
                        ,Title = 'King'
                        ,Username = testUsername
                        ,Email = testUsername
                        ,IsActive = true
                        ,Sales_Org__c = 'PAY'
                        // person id
                        ,EmployeeNumber = null
                        ,Hire_Date__c = Date.today()
                        ,Termination_Date__c = null
                        ,ManagerId = null
                        ,Department = 'Test Dept'
                        ,Alias = 'jjoffer'
                        ,CommunityNickname = 'jjoffer'
                        ,MobilePhone = '585-123-6544'
                        ,Phone = '585-123-6543'
                        ,Street = '123 Some St'
                        ,City = 'Somewhere'
                        ,PostalCode = '14514'
                        ,State = 'NY'
                        ,UserRoleId = ur.Id
                        ,ProfileId = p.Id
                        ,Cost_Center__c = '0017'
                        ,District__c = '0017'
                        );
      User curUser = [Select Id, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey from User where Id = :UserInfo.getUserId()];
      u1.TimeZoneSidKey = curUser.TimeZoneSidKey;
      u1.LocaleSidKey = curUser.LocaleSidKey;
      u1.EmailEncodingKey = curUser.EmailEncodingKey;
      u1.LanguageLocaleKey = curUser.LanguageLocaleKey;
      insert u1;
   } // setupData

   /** Test that upon initial insert the HR Person Id is populated if a good value. It is not updated
       on subsequent updates.
    */
   static testMethod void testOnInsert() {
      //User u = createUser('12345');
      User u = [Select Id, EmployeeNumber, HR_Person_Id__c from User where Username=:testUsername];
      u.EmployeeNumber = '12345';
      update u;
      u = [Select Id, EmployeeNumber, HR_Person_Id__c from User where Id = :u.Id];
      System.assertEquals('12345',u.HR_Person_Id__c);
      // test that updating the employee number doesn't change the value
      u.EmployeeNumber = '98765';
      update u;
      u = [Select Id, EmployeeNumber, HR_Person_Id__c from User where Id = :u.Id];
      System.assertEquals('12345',u.HR_Person_Id__c);
   } // testOnInsert
   
   /** The HR Person Id is null on initial insert if no EmployeeNumber. HR Person Id is updated in subsequent updates.
    */
   static testMethod void testOnUpdate() {
      //User u = createUser(null);
      User u = [Select Id, EmployeeNumber, HR_Person_Id__c from User where Username=:testUsername];
      u = [Select Id, EmployeeNumber, HR_Person_Id__c from User where Id = :u.Id];
      System.assertEquals(null,u.HR_Person_Id__c);
      // test that updating the employee number updates the HR Person Id
      u.EmployeeNumber = '98765';
      update u;
      u = [Select Id, EmployeeNumber, HR_Person_Id__c from User where Id = :u.Id];
      System.assertEquals('98765',u.HR_Person_Id__c);
      
      // make sure not updated again.
      u.EmployeeNumber = '12345';
      update u;
      u = [Select Id, EmployeeNumber, HR_Person_Id__c from User where Id = :u.Id];
      System.assertEquals('98765',u.HR_Person_Id__c);
      
   } // testOnUpdate
   
   /** The HR Person Id is null on initial insert if bad EmployeeNumber. HR Person Id is updated in subsequent updates.
    */
   static testMethod void testOnUpdateBadFirst() {
      User u = [Select Id, EmployeeNumber, HR_Person_Id__c from User where Username=:testUsername];
      u.EmployeeNumber='ABCD';
      update u;
      //User u = createUser('ABCD');
      u = [Select Id, EmployeeNumber, HR_Person_Id__c from User where Id = :u.Id];
      System.assertEquals(null,u.HR_Person_Id__c);
      // test that updating the employee number updates the HR Person Id
      u.EmployeeNumber = '98765';
      TriggerMethods.clearVariables();
      update u;
      u = [Select Id, EmployeeNumber, HR_Person_Id__c from User where Id = :u.Id];
      System.assertEquals('98765',u.HR_Person_Id__c);
   	
      // make sure not updated again.
      u.EmployeeNumber = '12345';
      update u;
      TriggerMethods.clearVariables();
      u = [Select Id, EmployeeNumber, HR_Person_Id__c from User where Id = :u.Id];
      System.assertEquals('98765',u.HR_Person_Id__c);
      
   } // testOnUpdateBadFirst

} // UserCheckPersonIdTest