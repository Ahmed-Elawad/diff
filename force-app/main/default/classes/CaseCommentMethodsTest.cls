/**
 * History
 * 02/17/2017	Lynn Michels Created
 */
@isTest
private class CaseCommentMethodsTest {

    static testMethod void testCaseComments() {
    	Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
      	User u = new User(Alias = 'abcd', Email='abcd@testorg.com', 
      	EmailEncodingKey='UTF-8', LastName='Abcd', LanguageLocaleKey='en_US', 
      	LocaleSidKey='en_US', ProfileId = p.Id, Sales_Org__c = 'COE',
      	TimeZoneSidKey='America/Los_Angeles', UserName='abcd@testorg.com');

      	
    	Case c = new Case(Status='New',
        				Origin = 'Email');
        insert c;
        CaseCommentMethods ccm = new CaseCommentMethods();
        System.runAs(u) {
        	CaseComment comment = new CaseComment(CommentBody='This is a test comment.',
        											ParentId = c.id);
        	insert comment;
        	ccm.checkBeforeTrigger(comment, null);
        	system.assertEquals(true,comment.CommentBody.contains('Abcd'));
        	
        	ccm.processBeforeTriggerActions();
       		ccm.checkAfterTrigger(comment, null);
       		ccm.processAfterTriggerActions();
        }//end system.runAs	
        
       
       
        
    }
        
}