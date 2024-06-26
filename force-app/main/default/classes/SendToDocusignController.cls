/* 
 * Controller for Docusign redirect to create CSRF Token
 *
 * History
 * -------
   06/2/2021 Justin Stouffer   Created

 */
public class SendToDocusignController {
    public PageReference Redirect() 
    { 
        string url = Apexpages.currentpage().getparameters().get('url');
        return new PageReference(url); 
    } 
}