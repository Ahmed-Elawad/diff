/* 
 * The test methods for the PageMessageController class.
 *
 * History
 * -------
 * 12/10/2010 Dan Carmen   Created
   10/26/2018 Dan Carmen   Incrementing API version to 44

 */
@isTest
private class PageMessageControllerTest {

   /** Test with a page message object present and opt out flag set.
    */
   static testMethod void testPageMessageWithOpt() {
      PageReference pageRef = Page.PageMessageTest;
      // add another parameter on the end to test name truncation
      pageRef.getParameters().put('testParam','testvalue');
      Test.setCurrentPage(pageRef);
      Page_Message__c pm = createPageMessage('PageMessageTest','This is a test message',true);
      PageMessageController pmc = new PageMessageController();
      System.assertEquals('PAGEMESSAGETEST',pmc.pageName.toUpperCase());
      System.assertEquals(true,pmc.hasOptOut);
      System.assertEquals(true,pmc.hasMsgs);
      // verify message was selected.
      System.assertEquals(true,checkForPage(pmc.msgs,pm.Id));
      
      // test opting out
      pageRef = Page.PageMessageTest;
      pageRef.getParameters().put('MsgId',pm.Id);
      pageRef.getParameters().put('UserId',UserInfo.getUserId());
      Test.setCurrentPage(pageRef);
      PageReference result = pmc.doNotShow();
      System.assertEquals(null,result);
     
      // verify message no longer present
      System.assertEquals(false,checkForPage(pmc.msgs,pm.Id));
      
      // verify Page_Message_User__c object created.
      Page_Message_User__c pmu = [select Id
                                        ,Page_Message__c 
                                    from Page_Message_User__c
                                   where Page_Message__c = :pm.Id
                                     and User__c = :UserInfo.getUserId()
                                     and User_Opted_Out__c = true];
      System.assertEquals(pm.Id, pmu.Page_Message__c);
   } // testPageMessage
 
   /** Test with a page message object present and opt out flag set, and a Page_Message_User__c object
       present that does not have the opt out flag set.
    */
   static testMethod void testPageMessageWithOptAndPmuPresent() {
      PageReference pageRef = Page.PageMessageTest;
      // add another parameter on the end to test name truncation
      pageRef.getParameters().put('testParam','testvalue');
      Test.setCurrentPage(pageRef);
      Page_Message__c pm = createPageMessage('PageMessageTest','This is a test message',true);
      Page_Message_User__c testPmu = new Page_Message_User__c(Page_Message__c=pm.Id
                                                             ,User__c = UserInfo.getUserId()
                                                             ,User_Opted_Out__c = false);
      insert testPmu;
      PageMessageController pmc = new PageMessageController();
      System.assertEquals('PAGEMESSAGETEST',pmc.pageName.toUpperCase());
      System.assertEquals(true,pmc.hasOptOut);
      System.assertEquals(true,pmc.hasMsgs);
      // verify message was selected.
      System.assertEquals(true,checkForPage(pmc.msgs,pm.Id));
      
      // test opting out
      pageRef = Page.PageMessageTest;
      pageRef.getParameters().put('MsgId',pm.Id);
      pageRef.getParameters().put('UserId',UserInfo.getUserId());
      Test.setCurrentPage(pageRef);
      PageReference result = pmc.doNotShow();
      System.assertEquals(null,result);
     
      // verify message no longer present
      System.assertEquals(false,checkForPage(pmc.msgs,pm.Id));
      
      // verify Page_Message_User__c object created.
      Page_Message_User__c pmu = [select Id
                                        ,Page_Message__c 
                                    from Page_Message_User__c
                                   where Page_Message__c = :pm.Id
                                     and User__c = :UserInfo.getUserId()
                                     and User_Opted_Out__c = true];
      System.assertEquals(pm.Id, pmu.Page_Message__c);
   } // testPageMessage
 
   /** Test with a page message object present and opt out flag is not set.
    */
    /*
   static testMethod void testPageMessageNoOptOut() {
      PageReference pageRef = Page.PageMessageTest;
      // add another parameter on the end to test name truncation
      pageRef.getParameters().put('testParam','testvalue');
      Test.setCurrentPage(pageRef);
      Page_Message__c pm = createPageMessage('PageMessageTest','This is a test message',false);
      PageMessageController pmc = new PageMessageController();
      System.assertEquals('PAGEMESSAGETEST',pmc.pageName.toUpperCase());
      System.assertEquals(false,pmc.hasOptOut);
      System.assertEquals(true,pmc.hasMsgs);
   } // testPageMessageNoOptOut
   */
   
   /** Check for the page in the messages.
    */
   private static Boolean checkForPage(List<Page_Message__c> msgs, Id pmId) {
      Boolean found = false;
      for (Page_Message__c checkPm : msgs) {
      	 if (checkPm.Id == pmId) {
      	    found = true;
      	 }
      } // for (Page_Message__c
      return found;
   } // checkForPage
   
   private static Page_Message__c createPageMessage(String pageName, String message, Boolean allowOptOut) {
   	  Page_Message__c pm = new Page_Message__c(Name=pageName
   	                                          ,Message__c=message
   	                                          ,Allow_Opt_Out__c=allowOptOut
   	                                          ,Start_Date__c = Date.today().addDays(-4)
   	                                          ,End_Date__c = Date.today().addDays(4)
   	                                          );
   	  insert pm;
   	  return pm;
   } // createPageMessage
    
} // class PageMessageControllerTest