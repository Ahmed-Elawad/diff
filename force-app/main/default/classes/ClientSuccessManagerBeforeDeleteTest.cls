/** 
 * The test methods for the ClientSuccessManagerBeforeDelete trigger
 *
 * History
 * -------
 * 01/29/2018 Frank Lurz     Created
 *
 */
@isTest
private class ClientSuccessManagerBeforeDeleteTest {

   static testMethod void testDelete() {


      // create Account
      Account testAccount = new Account();
      testAccount.Name = 'Test Deleted Account';
      insert(testAccount);
        
      // create Client Success Manager record
      Client_Success_Manager__c testCSM = new Client_Success_Manager__c();
      testCSM.Prospect_Client_Name__c = testAccount.Id;
      testCSM.Do_Not_Delete__c = TRUE;
      insert(testCSM);

      // attempt to delete Client Success Manager record
      try
      {
      delete testCSM;
      }
      catch(Exception err)
      {}

   } // testDelete
   
} // class ClientSuccessManagerBeforeDeleteTest