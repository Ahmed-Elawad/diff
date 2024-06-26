/**
 * An apex page controller that exposes the site login functionality
 * 09/14/22   lines 7-9, 20-42   Added by Varun for CPA login custom Page
 */
global with sharing class CommunitiesLoginController {
    
    public String username {get; set;}
	public String password {get; set;}
    public String acceptCheckbox {get; set;}
    
    global CommunitiesLoginController () {
        
    }
    
    // Code we will invoke on page load.
    
    global PageReference forwardToAuthPage() {
    	String startUrl = System.currentPageReference().getParameters().get('startURL');
    	String displayType = System.currentPageReference().getParameters().get('display');
        //return Network.forwardToAuthPage(startUrl, displayType);
        return null;
    }
    
    global PageReference forwardToCustomAuthPage() {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        //return new PageReference(Site.getPathPrefix() + '/cpaLoginVF?startURL=' + EncodingUtil.urlEncode(startURL, 'UTF-8'));
        return null;
    }
	
    
    public PageReference Login() {
    	System.debug('acceptCheckbox='+acceptCheckbox);
        System.debug('username='+username);
        System.debug('password='+password);
        if(String.isBlank(username)) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please enter username'));
            return null;
        }
        if(String.isBlank(password)) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please enter password'));
            return null;
        }
        /*
        if(acceptCheckbox != 'true') {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Select Accept the Terms and Condtitions checkbox'));
            return null;
        }
		*/
      	return Site.login(username, password, null);
   }
   /*
    public PageReference rediredtToResetPage() {
        String username = System.currentPageReference().getParameters().get('username');
        List<User> userLst = [SELECT Id, ContactId, Community_User_First_Login__c, Contact.Mirror_Ref_Ctct__c, Contact.Mirror_Ref_Ctct__r.Admin_CPA__c, Contact.Mirror_Ref_Ctct__r.CPA_portal_shared__c  FROM User WHERE Username = :username LIMIT 1];
        system.debug(userLst); 
        if(!userLst.isEmpty()) {
            if(userLst[0].Community_User_First_Login__c == null) {
                PageReference pageRef = new PageReference('/FirstTimeResetPwd?username='+username);
                pageRef.setRedirect(true);
                return pageRef;
            }
        }
        return null;
    }*/
}