/**
 * An apex page controller that exposes the change password functionality

 * History
 * -------
   10/26/2018 Dan Carmen       Separate Test Method and increment API version
 

 */
@isTest
private class ChangePasswordControllerTest {

      public static testMethod void testChangePasswordController() {
        // Instantiate a new controller with all parameters in the page
        ChangePasswordController controller = new ChangePasswordController();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1'; 
        controller.verifyNewPassword = 'qwerty1';                
        
        System.assertEquals(controller.changePassword(),null);                           
    }    
}