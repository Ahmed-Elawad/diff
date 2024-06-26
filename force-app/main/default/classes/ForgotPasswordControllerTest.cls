/**
 * An apex page controller that exposes the site forgot password functionality

 * History
 * -------
   10/26/2018 Dan Carmen       Separate Test Method and increment API version

 */
@isTest
private class ForgotPasswordControllerTest {

    public static testMethod void testForgotPasswordController() {
      // Instantiate a new controller with all parameters in the page
      ForgotPasswordController controller = new ForgotPasswordController();
      controller.username = 'test@salesforce.com';       
    
      System.assertEquals(controller.forgotPassword(),null); 
    }
}