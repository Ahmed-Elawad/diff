/* 
 * Test Class for Controller for Docusign redirect to create CSRF Token
 *
 * History
 * -------
   06/2/2021 Justin Stouffer   Created

 */
@isTest
public class SendToDocusignControllerTest {
    static testMethod void testPageRef(){
		PageReference TestRef  =  new PageReference('/apex/SendToDocusign?url=TestURL');
        Test.setCurrentPage(TestRef);
        SendToDocusignController stdc = new SendToDocusignController();
        stdc.Redirect();
        system.assertequals('TestURL',Apexpages.currentpage().getparameters().get('url'));
    }
}