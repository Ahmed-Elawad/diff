public class DMLQueueable implements Queueable{
			
    public String description = null;
	public list<SObject> recsToUpdate; 
 	public id usrID = null; 
 	public integer recordCount = null; 
 	
	public DMLQueueable(String p_desc, sObject[] recs){
		recsToUpdate = recs; 
		usrID = UserInfo.getUserId(); 
	    description = p_desc; 
	}//dmqueueable  


	public void execute(QueueableContext context) {
		
		If (recsToUpdate != null && !recsToUpdate.isEmpty()){
			
		recordCount = recsToUpdate.size(); 
		system.debug('JC size' + recstoUpdate.size()); 
		
		update recsToUpdate; 
		}
		
		Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
		msg.setTargetObjectId(usrID); 
	  	msg.setSubject('Holdout Manager Changes Complete');
		
     	msg.setHtmlBody(description);
     	msg.setBccSender (false);
      	msg.setUseSignature(false);
      	msg.setSaveAsActivity(false);
	  	Messaging.sendEmail (new Messaging.SingleEmailMessage[] { msg });
		
		
    
	}//execute
	
	


}//DMLQueable