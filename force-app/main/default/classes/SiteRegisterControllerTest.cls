/**
 * An apex class that creates a portal user

 * History
 * -------
   10/26/2018 Dan Carmen       Separate Test Method and increment API version

 */
@isTest
private class SiteRegisterControllerTest {

    // Test method to bring this class's test coverage over the required 75%
    static testMethod void testRegistration() {
        SiteRegisterController controller = new SiteRegisterController();
        controller.username = 'test@force.com';
        controller.email = 'test@force.com';
        controller.communityNickname = 'test';
        // registerUser will always return null when the page isn't accessed as a guest user
        System.assert(controller.registerUser() == null);    
        
        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd123';
        System.assert(controller.registerUser() == null);  
    }
    
} // class SiteRegisterControllerTest