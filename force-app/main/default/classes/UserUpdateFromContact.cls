/* 
 * A batch job for updating User records from the Paychex, Inc SA Contact records that are
 * fed in from the SEND_EMPS process
 *
 * History
 * -------
 * 08/04/2010 Dan Carmen   Created
   12/23/2011 Dan Carmen   Changed comparison to be case sensitive
   06/28/2012 Dan Carmen   Modified to use JobHelper class
   09/12/2013 Dan Carmen   Fix System.NullPointerException
   04/22/2015 Dan Carmen   Change to set user record to inactive if needed.
   09/02/2015 Dan Carmen   Added option to update the email address.
   02/12/2016 Dan Carmen   Ability to stop the contact from updating the user record
   03/02/2016 Dan Carmen   Do a check for the employee number
   10/16/2017 Dan Carmen   Code Cleanup
   01/18/2018 Dan Carmen   Move logic to ContactFormatPaychexEmps
   06/17/2020 Dan Carmen   New logic to make this class a Rest Service
   11/02/2023 Dan Carmen   Comment out code

@RestResource(urlMapping='/UpdateUsrFromCtct/*')
 */
global with sharing class UserUpdateFromContact {
    public UserUpdateFromContact() {}
/*
    
   @HttpPost
   global static void doPost(Id[] ctctIds) {
   	  System.debug('doPost ctctIds='+ctctIds);

      RestRequest req = RestContext.request;
      RestResponse res = RestContext.response;
       
      Set<Id> ctctIdSet = new Set<Id>(ctctIds);
      ContactFormatPaychexEmps.checkUserFromContactNow(ctctIdSet);
       
  } // doPost

*/
} // class UserUpdateFromContact