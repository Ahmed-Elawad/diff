/* 
  Methods used to help test User and associated objects.
   
  History
  -------
  01/28/2011 Dan Carmen   Created
  10/11/2012 Dan Carmen   Added in a few more join fields.
  04/24/2013 Dan Carmen   Cleaning up code for User License maintenance
  01/05/2024 Dan Carmen   Removed User License code.
   
 */
 @isTest
public class UserTestHelper {

   /** Create a user record and add to the passed in list.
    */
   public void createUser(List<User> users, Integer userNum, Profile p, UserRole ur, User curUser) {
   	  users.add(createUser(userNum,p,ur,curUser));
   } // createUser
   
   /** Create a user record.
    */	
   public User createUser(Integer userNum, Profile p, UserRole ur, User curUser) {
      // create a new user
      User u = new User(FirstName = 'Jaffe'
                        ,LastName = 'Joffer'+userNum
                        ,Title = 'King'
                        ,Username = 'jjoffer'+userNum+'@paychex.com.test'+userNum
                        ,Email = 'jjoffer'+userNum+'@paychex.com.test'+userNum
                        ,Sales_Org__c = 'PAY'
                        ,IsActive = true
                        // person id
                        ,EmployeeNumber = 'TestEmp-'+userNum
                        ,HR_Person_ID__c = 'TestId'+userNum
                        ,Hire_Date__c = Date.today()
                        ,Termination_Date__c = null
                        ,ManagerId = null
                        ,Department = 'Test Dept'
                        ,Alias = 'alias'+userNum
                        ,CommunityNickname = 'nickname'+userNum
                        ,MobilePhone = '585-123-6544'
                        ,Phone = '585-123-6543'
                        // rep code
                        ,Person_ID_Number__c = 'A123'
                        ,Street = '123 Some St'
                        ,City = 'Somewhere'
                        ,PostalCode = '14514'
                        ,State = 'NY'
                        ,UserRoleId = ur.Id
                        ,UserRole = ur
                        ,ProfileId = p.Id
                        ,Profile = p
                        ,Cost_Center__c = '0017'
                        ,District__c = '0017'
                        ,Creation_Type__c = 'NewUser'
                        );
      u.TimeZoneSidKey = curUser.TimeZoneSidKey;
      u.LocaleSidKey = curUser.LocaleSidKey;
      u.EmailEncodingKey = curUser.EmailEncodingKey;
      u.LanguageLocaleKey = curUser.LanguageLocaleKey;
      return u;
   } // createUser

   /** Get a User record by the Id.
    */
   public User getUserById(Id userId) {
      User u = [Select Id, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey
                      ,ProfileId, Profile.Id, Profile.Name
                      ,UserRoleId, UserRole.Id, UserRole.Name, UserRole.ParentRoleId
                      ,EmployeeNumber, HR_Person_ID__c
                      ,Termination_Date__c,Department,FirstName
                      ,LastName,Hire_Date__c,Street
                      ,City,State,PostalCode,Cost_Center__c
                      ,Person_ID_Number__c,Phone,Title
                  from User 
                 where Id = :userId];
      return u;
   } // getUserById
   
   /** Default constructor.
    */
   public UserTestHelper() {
   	  
   } // UserTestHelper


} // class UserTestHelper