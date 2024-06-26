/**
 * Test Class for ChatterFilter Class
 * History
 * -------
 * 03/17/2014 Justin Stouffer   Created
 */
@isTest
private class ChatterFilterTest {

    static testMethod void testFeedItem() {
    	string exceptMessage = '';
  		
  		//Create Custom Setting
  		ChatterFilter__c cF = new ChatterFilter__c(Name='Check Phrase',
	      											 Check_Phrase__c = 'Check Phrase',
	      											 Warning_Message__c = 'Warning Message.');
    	insert cF;
		
		//Create FeedItem with Phrase to be filtered
    	feedItem fI = new feedItem(body = 'Check Phrase',
    								ParentId = system.userInfo.getUserId(),
    								type = 'TextPost');							
		//Try inserting FeedItem
		try{
			insert fI;
        }
        catch(System.DmlException e){
        	exceptMessage = e.getMessage();		
        }
        
        //Verify FeedItem was not inserted
    	system.assertEquals(fI.id, NULL);
    	//Verify custom warning message was used
    	system.assert(exceptMessage.contains(cF.Warning_Message__c));
        
        //Update Custom Setting to use default warning message
        cF.Warning_Message__c = NULL;
        update cF;
        
        //Try inserting FeedItem again
        try{
			insert fI;
        }
        catch(System.DmlException e){
        	exceptMessage = e.getMessage();		
        }
        
        //Verify FeedItem was not inserted
    	system.assertEquals(fI.id, NULL);
    	//Verify default warning message was used
    	system.assert(exceptMessage.contains(cF.Check_Phrase__c));        
    }
    
    static testMethod void testFeedComment() {
    	string exceptMessage = '';
    	//Create Custom Setting
  		ChatterFilter__c cF = new ChatterFilter__c(Name='Check Phrase',
	      											 Check_Phrase__c = 'Check Phrase',
	      											 Warning_Message__c = 'Warning Message.');
    	insert cF;
    	
    	//Create parent feed item and verify that it is not blocked
    	feedItem fI = new feedItem(body = 'Feed Item',
    								ParentId = system.userInfo.getUserId(),
    								type = 'TextPost');
		insert fI;
		
		//Create FeedComment with Phrase to be filtered	
    	feedComment fC = new feedComment(Commentbody = 'Check Phrase',
    								FeedItemId = fI.id);
    								
		//Try inserting FeedComment							
		try{
			insert fC;
        }
        catch(System.DmlException e){
        	exceptMessage = e.getMessage();		
        }
        //Verify FeedComment was not inserted
    	system.assertEquals(fC.id, NULL);
    	//Verify Custom Warning Message was used
    	system.assert(exceptMessage.contains(cF.Warning_Message__c));
        
        //Update Custom Setting to use default warning message
        cF.Warning_Message__c = NULL;
        update cF;
        
        //Try inserting FeedComment again
        try{
			insert fC;
        }
        catch(System.DmlException e){
        	exceptMessage = e.getMessage();		
        }
        //Verify FeedComment was not inserted
    	system.assertEquals(fC.id, NULL);
    	//Verify default warning message was used
    	system.assert(exceptMessage.contains(cF.Check_Phrase__c));  
    }
}