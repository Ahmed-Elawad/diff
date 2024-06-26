/*
 * A scheduled job to check if other batch jobs were successful.  Pulls in from custom setting - BatchJobChecker.
 * Sends an email if looks like job didn't complete. 
 * History
 * -------
 * 10/31/2014 Cindy Freeman     created
 * 03/06/2019 Cindy Freeman		modified to catch import jobs that failed to load records
 * 03/18/2019 Cindy Freeman		finished changed to catch import jobs that failed to load any records 
 */

global class BatchJobChecker implements Database.Batchable<SObject>, Schedulable {

	global JobHelper jh = new JobHelper('BatchJobChecker');
 	global DateTime startTime;
 	
	global BatchJobChecker() {
   		startTime = DateTime.now();
    } // BatchJobChecker
 
	global Database.QueryLocator start(Database.BatchableContext BC){
		// save the record - show that the job started
    	jh.setStarted();		
		return Database.getQueryLocator([Select Name, IsActive__c, Sobject__c, WhereClause__c, Soqlstmt__c, MaxCount__c,
										EmailBody__c, EmailAddresses__c from BatchJobChecker__c]);
				
	} // start

	/** In order to schedule a batch run
    */
    global void execute(SchedulableContext sc) {
   		BatchJobChecker bjc = new BatchJobChecker();
   	  	database.executeBatch(bjc, 100);
    } // execute
    
    global void execute(Database.BatchableContext BC, List<Sobject> scope){
    	list<Messaging.SingleEmailMessage> mails = new list<Messaging.SingleEmailMessage>();
    	      
		List<BatchJobChecker__c> bjcList = (List<BatchJobchecker__c>) scope;
		for (BatchJobChecker__c bjc : bjcList)
		{	if (bjc.isActive__c)
			{	Integer rcdCount = runsoql(bjc);
             	String[] addressList = bjc.EmailAddresses__c.split(',');
             	Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
            	mail.setToAddresses(addressList);
            	if (rcdCount == -1)
				{	mail.setSubject ('BatchJobChecker Error: SOQL was bad. ***');
            		String body = 'The BatchJobChecker query was bad.  Check ' + bjc.Name + '.  ';
            		body += (bjc.EmailBody__c != null ? bjc.EmailBody__c : 'You may want to check it out.');            		
            		mail.setPlainTextBody(body);
            		mails.add(mail);
            	} // else if (rcdCount == -1)
				else if (bjc.MaxCount__c != null && rcdCount > bjc.MaxCount__c)
				{	String subj = '';
                    if (bjc.MaxCount__c == -1 && rcdCount == 0)
					{	subj = 'Warning: ' + bjc.Name + ' record count = 0. The process may have failed (EVE? HAL?) ***';	}
					else if (bjc.MaxCount__c > -1)
					{	subj = 'Warning: ' + bjc.Name + ' has a high record count. ***';	}
            		if (String.isNotBlank(subj))	
                    {	mail.setSubject(subj);
                        String body = 'The BatchJobChecker query returned a record count higher than the maximum allowed - ' + rcdCount + '.  ';
            			body += (bjc.EmailBody__c != null ? bjc.EmailBody__c : 'You may want to check it out.');            		
            			mail.setPlainTextBody(body);
            			mails.add(mail);
                    }
            	} // if (bjc.MaxCount__c > 0 && rcdCount > bjc.MaxCount__c)
			} // if (bjc.isActive__c)
		} // for

		if (!mails.isEmpty() && !Test.isRunningTest())
		{	Messaging.sendEmail(mails);	}		
    } // execute
    
    global void finish(Database.BatchableContext BC){         			
      	jh.completeJob(bc, 'BatchJobChecker', 'All Jobs Checked');
      	
    } // finish
    
    public static Integer runsoql(SObject checker) {
    	Integer rcdCount = 0;
    	String queryStmt = null;
    	BatchJobChecker__c bjc = (BatchJobChecker__c)checker;    	
    	try 
    	{	if (bjc.soqlstmt__c != null && bjc.soqlstmt__c.length()>0)
    		{	queryStmt = bjc.soqlstmt__c;	}
    		if (queryStmt == null && bjc.sobject__c != null && bjc.sobject__c.length() > 0)
    		{	queryStmt = 'Select count() from ' + bjc.sobject__c;
	    		if (bjc.whereClause__c != null && bjc.whereClause__c.length() > 0)
    			{	queryStmt += ' Where ' + bjc.whereClause__c;	}
    		} // if (checker.sobject...  	
			System.debug('BatchJobChecker soql='+queryStmt);    			
    		rcdCount = Database.countQuery(queryStmt);
			System.debug('BatchJobChecker rcdCount='+rcdCount);    		   		
      	} // try
    	catch (Exception ex)
    	{	ErrorLog.logError('BatchJobChecker', 'runsoql', bjc.name, bjc.sobject__c, ex);
      		ErrorLog.checkSave();
      		rcdCount = -1;
    	} // catch
    	
    	return rcdCount;
    	
    } // runsoql
    	
}