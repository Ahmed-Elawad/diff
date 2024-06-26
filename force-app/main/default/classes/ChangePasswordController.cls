/**
 * An apex page controller that exposes the change password functionality

 * History
 * -------
   10/26/2018 Dan Carmen       Separate Test Method and increment API version
 

 */
public class ChangePasswordController {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}        
    
    public PageReference changePassword() {
        return Site.changePassword(newPassword, verifyNewPassword, oldpassword);    
    }     
    
   	public ChangePasswordController() {}
    
}