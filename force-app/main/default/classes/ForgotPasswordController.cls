/**
 * An apex page controller that exposes the site forgot password functionality

 * History
 * -------
   10/26/2018 Dan Carmen       Separate Test Method and increment API version

 */
public class ForgotPasswordController {
    public String username {get; set;}   
       
    public ForgotPasswordController() {}
	
  	public PageReference forgotPassword() {
  		boolean success = Site.forgotPassword(username);
  		PageReference pr = Page.ForgotPasswordConfirm;
  		pr.setRedirect(true);
  		
  		if (success) {  			
  			return pr;
  		}
  		return null;
  	}
  	
}