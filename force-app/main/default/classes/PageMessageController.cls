/* 
 * The controller for displaying messages on pages.
 *
 * History
 * -------
 * 12/10/2010 Dan Carmen   Created
   10/26/2018 Dan Carmen   Incrementing API version to 44
 
 */
public with sharing class PageMessageController {

   /** The name of the page. */
   public String pageName{get;set;}
      
   /** If at least one of the messages has the opt out flag set. */
   public Boolean hasOptOut{get; private set;}
   
   /** The constructor for the page.
    */
   public PageMessageController() {
   	  setPageName(ApexPages.currentPage().getUrl());
   	  getMessages();
   } // PageMessageController
   
   /** Set the pageName variable based on the URL of the current page.
    */
   public void setPageName(String url) {
   	  pageName = url;
   	  // remove the first page of the URL
   	  if (pageName.startsWith('/apex/')) {
         pageName = pageName.substring(6);
   	  }
   	  if (pageName.indexOf('?') > 0) {
   	  	 pageName = pageName.substring(0,pageName.indexOf('?'));
   	  }
   } // setPageName
   
   /** Does the page have any messages.
    */
   public Boolean hasMsgs{
   	  get{
   	  	 return (msgs != null && msgs.size() > 0);
   	  }
   } // hasMsgs
   
   public List<Page_Message__c> msgs{get; private set;}
   
   /** Retrieve the message for the page.
    */
   private void getMessages() {
   	  if (pageName != null) {
   	  	 // instantiate the list
   	  	 msgs = new List<Page_Message__c>();
   	  	 hasOptOut = false;
   	  	 Date dt = Date.today();
   	  	 // retrieve the list
   	  	 List<Page_Message__c> tempMsgs = [Select Id
   	  	               ,Name
   	  	               ,Start_Date__c
   	  	               ,End_Date__c
   	  	               ,Allow_Opt_Out__c
   	  	               ,Message__c
   	  	               ,(Select Id
   	  	                       ,User__c
   	  	                       ,User_Opted_Out__c
   	  	                   from Page_Message_Users__r
   	  	                  where User__c = :UserInfo.getUserId())
   	  	           from Page_Message__c
   	  	          where Name = :pageName
   	  	            and Start_Date__c <= :dt
   	  	            and End_Date__c >= :dt];
   	     // check if the user opted out
   	     for (Page_Message__c pm : tempMsgs) {
   	     	Boolean optedOut = false;
   	     	for (Page_Message_User__c checkPmu : pm.Page_Message_Users__r) {
   	     	   if (checkPmu.User__c == UserInfo.getUserId() &&
   	     	       checkPmu.User_Opted_Out__c == true) {
   	     	      optedOut = true;
   	     	      break;
   	     	   }
   	     	} // for (Page_Message_User__c
   	     	if (!optedOut) {
   	     	   // check if allows opt out
   	     	   if (pm.Allow_Opt_Out__c) {
   	     	   	  hasOptOut = true;
   	     	   }
   	     	   msgs.add(pm);
   	     	}
   	     } // for (Page_Message__c
   	  } // if (pageName != null
   } // getMessages
   
   /** Process the "Do Not Show" option.
    */
   public PageReference doNotShow() {
   	  Id msgId = ApexPages.currentPage().getParameters().get('MsgId');
   	  Id userId = ApexPages.currentPage().getParameters().get('UserId');
   	  if (msgId != null && userId != null) {
         // search through the messages
   	     for (Page_Message__c pm : msgs) {
   	  	    if (pm.Id == msgId) {
   	  	       // msg is found - see if Page_Message_Users__c object exists
   	  	       Page_Message_User__c pmu = null;
   	  	       for (Page_Message_User__c checkPmu : pm.Page_Message_Users__r) {
   	  	       	  // if matching record
   	  	       	  if (checkPmu.User__c == userId) {
   	  	       	  	 pmu = checkPmu;
   	  	       	  	 pmu.User_Opted_Out__c = true;
   	  	       	  	 update pmu;
   	  	       	  	 break;
   	  	       	  }
   	  	       } // for
   	  	       // if not found, create a new record
   	  	       if (pmu == null) {
   	  	       	  pmu = new Page_Message_User__c(Page_Message__c = pm.Id
   	  	       	                                 ,User__c = userId
   	  	       	                                 ,User_Opted_Out__c = true);
   	  	       	  insert pmu;
   	  	       } // if (pmu == null
   	  	    } // if (pm.Id
   	     } // for (Page_Message__c
   	     getMessages();
   	  } // if (msgId != null
      return null;
   } // doNotShow
   
} // class PageMessageController