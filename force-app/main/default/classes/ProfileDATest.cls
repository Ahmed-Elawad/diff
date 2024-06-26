/* 
 * Test Methods for the ProfileDA class
 *
 * History 
 * -------
   09/10/2018 Dan Carmen        Change to handle bulk activity
   
 */
@isTest
private class ProfileDATest {
    
    @isTest static void getCurrentProfile() {
        Test.startTest();
        Profile p = ProfileDA.getCurrentProfile();
        Test.stopTest();

        System.assertEquals(p != null, true, 'The profile was retrieved');
    }
    
    
} // class ProfileDATest