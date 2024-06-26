/* 
 *  Update a user based on the passed in information
 
 * History
 * -------
 * 12/17/2014 Dan Carmen     created
 * 
 */
@RestResource(urlMapping='/userUpdate/*')
global without sharing class UserUpdateRest {

   /*
   @HttpPost
   global static String doPost(Id userId, String lastName, String username
                              ,String alias, String employeeNumber, String nickName
                              ,Date terminationDate
                              ,Boolean isActive, String comments) {
      String result = 'OK';
      User updateUser = new User(Id=userId);
      checkAddValue(updateUser,'LastName',lastName);
      checkAddValue(updateUser,'Username',username);
      checkAddValue(updateUser,'Alias',alias);
      checkAddValue(updateUser,'EmployeeNumber',employeeNumber);
      checkAddValue(updateUser,'CommunityNickname',nickName);
      if (terminationDate != null) {
         updateUser.Termination_Date__c = terminationDate;
      }
      if (isActive != null) {
         updateUser.IsActive = isActive;
      }


      try {
         // if there are comments, select the existing value and append on to it.
         if (String.isNotBlank(comments)) {
            User usr = [Select Id, Comments__c from User where Id=:userId]; 
            updateUser.Comments__c = (String.isNotBlank(usr.Comments__c) ? usr.Comments__c + '\n'+comments : comments );
         }
         update updateUser;
      } catch (Exception e) {
         result = e.getMessage()+': '+e.getStackTraceString();
         System.debug('UserUpdateRest update failed: '+result);
      }
      
      return result;
   } // doPost 

   // only add fields that have a value
   private static void checkAddValue(User usr, String fieldName, String value) {
      if (String.isNotBlank(value)) {
         usr.put(fieldName, value);
      }
   } // checkAddValue
   */
} // UserUpdateRest