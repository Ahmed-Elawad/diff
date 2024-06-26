/* Test Methods for the SfToSfConnectionHelper class

  History
  -------
  04/04/2019 Dan Carmen        Created
  
 */
@isTest
private class SfToSfConnectionHelperTest {
    static testMethod void testNothing() {
       new SfToSfConnectionHelper();
    }
   /*
   // the connection name we'll use in the tests
   public static String SF_TO_SF_TEST_CONNECTION=Label.SfToSfTestConnection;

   static testMethod void testConnection() {
      SfToSfConnectionHelper.PARTNER_CONNECTION_NAME = SF_TO_SF_TEST_CONNECTION;
      Lead ld1 = new Lead(LastName='Lead1',FirstName='Test',Company='Test Company 1');
      Lead ld2 = new Lead(LastName='Lead2',FirstName='Test',Company='Test Company 2');
      Lead ld3 = new Lead(LastName='Lead3',FirstName='Test',Company='Test Company 3');
      Lead[] lds = new Lead[]{ld1,ld2,ld3};
      insert lds;

      Boolean success = SfToSfConnectionHelper.sendToPartner(lds);
      
    } // testConnection
    */
} // class SfToSfConnectionHelperTest