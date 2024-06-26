/**
 * An apex page controller that exposes the site login functionality

 * History
 * -------
   10/26/2018 Dan Carmen       Separate Test Method and increment API version
 
 
 */
@isTest
private class SiteLoginControllerTest {

    static testMethod void testSiteLoginController () {
        // Instantiate a new controller with all parameters in the page
        SiteLoginController controller = new SiteLoginController ();
        controller.username = 'test@salesforce.com';
        controller.password = '123456'; 
                
        System.assertEquals(controller.login(),null);                           
    }    

} // class SiteLoginControllerTest