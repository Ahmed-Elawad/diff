/*
 * A scheduled job to replace the process builder - Reference Core Payroll MPSC Chatter Update.
 * Posts Chatter msg, sends email, sets Payroll Run Date Reset
 *
 * Payroll_Run_Date_Due__c is formula returning the Friday after the Proposed_Run_Date__c
 * Proposed_Run_Date__c is entered by the user  
 * post the day after Proposed Run Date if the Payroll Run Date is blank (scheduled job runs every day)
 * andProposed Run Date is not more than 6 months old (needed for initial run)
 *  
 * 
 * History
 * -------
 * 09/27/2016 Cindy Freeman     created
 * 11/4/2016  Cindy  Freeman	modified query to exclude RCP records with no Case Lookup
 */
 
 global class RefCorePayrollMPSCChatterUpdate implements Database.Batchable<SObject>, Schedulable {
 	global JobHelper jh = new JobHelper('RefCorePayrollMPSCChatterUpdate');
 	global DateTime startTime;
 	
	global RefCorePayrollMPSCChatterUpdate() {
   		startTime = DateTime.now();
    } // RefCorePayrollMPSCChatterUpdate
     
	global Database.QueryLocator start(Database.BatchableContext BC){
		// save the record - show that the job started
    	jh.setStarted();		
    	Schema.RecordTypeInfo rtRCP = RecordTypeHelper.getRecordType('Reference MPSC Onboarding Core Payroll', 'Reference_Core_Payroll__c'); 	
     	Id mpscId = rtRCP.getRecordTypeId();
     	
     	Date oldDate = System.today().addDays(-180);							// date 6 months ago
 		Date ckDate = System.today();											// returns today at 12am
 		return Database.getQueryLocator([Select Id, Name, Proposed_Run_Date__c, Payroll_Run_Date__c, Payroll_Run_Date_Due__c, Payroll_Run_Date_Reset__c, 
										Current_Step__c, RecordTypeId, OwnerId, Owner.Email, Owner_Manager_Email__c, Owner_Manager__c, Case_Lookup__c
										from Reference_Core_Payroll__c
										where RecordTypeId = :mpscId and Proposed_Run_Date__c!= null and Payroll_Run_Date__c = null 
                                        and Case_Lookup__c != null
										and Payroll_Run_Date_Reset__c = false //and OwnerId like '005%' 
										and Current_Step__c != 'Client Never Ran' and Current_Step__c != 'Lost During Onboarding'
										and Proposed_Run_Date__c < :ckDate and Proposed_Run_Date__c > :oldDate]);
		return null;		
	} // start
 
 	
	/** In order to schedule a batch run
    */
    global void execute(SchedulableContext sc) {
   		RefCorePayrollMPSCChatterUpdate rcpUpdate = new RefCorePayrollMPSCChatterUpdate();
   	  	database.executeBatch(rcpUpdate, 100);
    } // execute
    
    global void execute(Database.BatchableContext BC, List<Sobject> scope){
    	List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    	List<Reference_Core_Payroll__c> rcpUpdateList = new List<Reference_Core_Payroll__c>();
    	
		List<Reference_Core_Payroll__c> rcpList = (List<Reference_Core_Payroll__c>) scope;
System.debug('**CMF ** execute rcpList size='+rcpList.size());
		
		List<Id> userIdList = new List<Id>();					
		for (Reference_Core_Payroll__c rcp : rcpList)
		{	userIdList.add(rcp.OwnerId);
			if (rcp.Owner_Manager__c!= null && rcp.Owner_Manager__c.length() > 0)
			{	userIdList.add((Id)rcp.Owner_Manager__c);	}
		}
		// create map of active users so only post to them, not inactive folks
		Map<Id,User> userMap = new Map<Id, User>([select Id, Name, isActive, Email from User where Id in :userIdList and IsActive = true]);
		
		for (Reference_Core_Payroll__c rcp : rcpList)
		{	if (String.valueOf(rcp.OwnerId).Left(3) == '005')
			{	List<String> addressList = new List<String>();
				List<Id> postIdList = new List<Id>();
				if (userMap.containsKey(rcp.OwnerId))
				{	postIdList.add(rcp.OwnerId);	}
				if (rcp.Owner_Manager__c!= null && rcp.Owner_Manager__c.length() > 0 && userMap.containsKey((Id)rcp.Owner_Manager__c))
				{	postIdList.add((Id)rcp.Owner_Manager__c);	}
        		
        		String body = '\nToday, please update the following Reference Core Payroll record: ' + rcp.Name;
        		body += '\nDo one of the following:'; 
				body += '\n1)Add the client’s first payroll run date to the Payroll Run Date field.'; 
				body += '\n2)Change the Proposed Run Date, update the Original Proposed Run Date if a date doesn’t already exist in that field, ';
				body += 'and indicate the Reschedule Run Reason and any rescheduled notes you might have.';
				body += '\n\nFollow this link to access the record: '; 
				body += Utilities.instanceURL() + '/' + rcp.Id;
				body += '\n\nThis email was generated automatically, please do not reply.';
        		
        		if (!Test.isRunningTest())
        		{	ChatterMentionPost.createChatterMentionPost(rcp.Id, postIdList, body);	}

             	rcp.Payroll_Run_Date_Reset__c = true;
        		rcpUpdateList.add(rcp);
        	} // if (rcp.UserId.Left(3) == '005')        	
		} // for

		if (!rcpUpdateList.isEmpty())
		{	update rcpUpdateList;	}
		
				
    } // execute
    
    global void finish(Database.BatchableContext BC){         			
      	jh.completeJob(bc, 'RefCorePayrollMPSCChatterUpdate', 'All notifications sent.');
      	
    } // finish
 	

}