/**
 * An apex page controller that exposes the site login functionality

 * History
 * -------
   10/26/2018 Dan Carmen       Separate Test Method and increment API version
 
 
 */
global class SiteLoginController {
    global String username {get; set;}
    global String password {get; set;}

    global PageReference login() {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        return Site.login(username, password, startUrl);
    }
    
    global SiteLoginController () {}
    
} // class SiteLoginController