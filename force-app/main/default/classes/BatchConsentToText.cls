/*
 * A scheduled job to reset Consent to Text if it was checked more than 6 months ago.  Looks at field on Lead and Contact.
 * Uses custom labe - Label.ConsentToTextTimeframe
 * History
 * -------
 * 12/21/2017 Cindy Freeman     created
 *  
 */

global class BatchConsentToText implements Database.Batchable<Reference_Do_Not_Contact__c>, Database.Stateful, Schedulable {

	global JobHelper jh = new JobHelper('BatchConsentToText');
 	global DateTime startTime;
 	global Integer ctctCount = 0;
 	global Integer leadCount = 0;
 	
	global BatchConsentToText() {
   		startTime = DateTime.now();
    } // BatchJobChecker
 
	global class consentIds implements iterable<Reference_Do_Not_Contact__c> {
		global Iterator<Reference_Do_Not_Contact__c> Iterator() {
			return new CustomIterable();
		}
	} 
	
	global Iterable<Reference_Do_Not_Contact__c> start(Database.BatchableContext info){
		// save the record - show that the job started
    	jh.setStarted();	
    	return new consentIds();
				
	} // start

	/** In order to schedule a batch run
    */
    global void execute(SchedulableContext sc) {
   		BatchJobChecker bjc = new BatchJobChecker();
   	  	database.executeBatch(bjc, 100);
    } // execute
    
    global void execute(Database.BatchableContext info, List<Reference_Do_Not_Contact__c> scope){
		if (!scope.isEmpty())
		{	List<Lead> updateLeadList = new List<Lead>();
			List<Contact> updateCtctList = new List<Contact>();
			Lead ld;
			Contact ctct;
System.debug('** BatchConsentToText.execute scope='+scope.size());			
			for (Reference_Do_Not_Contact__c refDNC: scope)
			{	if (refDNC.Lead__c != null)
				{	ld = new Lead(id=refDNC.Lead__c,Consent_to_Text__c = false, Consent_to_Text_Reason__c = 'Expired auto reset'
								,Consent_to_Text_Date__c = System.now());
					updateLeadList.add(ld);
					leadCount++;
				}
				if (refDNC.Contact__c != null)
				{	ctct = new Contact(id=refDNC.Contact__c,Consent_to_Text__c = false, Consent_to_Text_Reason__c = 'Expired auto reset'
										,Consent_to_Text_Date__c = System.now());
					updateCtctList.add(ctct);
					ctctCount++;
				}				
			} // for
System.debug('** BatchConsentToText update Leads='+leadCount+' ctcts='+ctctCount);			
			if (!updateLeadList.isEmpty())
			{	update updateLeadList;	}
			if (!updateCtctList.isEmpty())
			{	update updateCtctList;	}
				    	
		} // if (!scope.isEmpty)
		
    } // execute
    
    global void finish(Database.BatchableContext BC){    
    	String msg = 'Consent to Text cleared, Leads='+leadCount+' Contacts='+ctctCount;
      	jh.completeJob(bc, 'BatchConsentToText', msg);
      	
    } // finish
    
    /* define custom iterable to pass to execute portion of batch job
       it contains ids of Leads and Contacts that need Consent to Text cleared
     */
 	global class CustomIterable implements Iterator<Reference_Do_Not_Contact__c> {    	
 		List<Reference_Do_Not_Contact__c> refDNCList {get; set;}
 		Integer i {get; set;} 		 		
 		
 		public CustomIterable() {
 			refDNCList = new List<Reference_Do_Not_Contact__c>();
 			Set<Id> processIdSet = new Set<Id>();
 			integer limitDays = Integer.valueOf(Label.ConsentToTextTimeframe);
	 		Date cutoffDate = Date.today().addDays(-limitDays);
System.debug('** BatchConsentToText.Iterator cutoffDate='+cutoffDate); 		
	 		List<Reference_Do_Not_Contact__c> refDNCQuery = [Select id, lead__c, Lead__r.Consent_to_Text__c, Lead__r.Consent_to_Text_Date__c,Lead__r.isConverted,
							Contact__c, Contact__r.Consent_to_Text__c, Contact__r.Consent_to_Text_Date__c, 
							Consent_to_text__c, Consent_to_Text_Date__c from Reference_Do_Not_Contact__c
							where Consent_to_Text_date__c != null
							and ((Lead__r.Consent_to_Text__c = true and Lead__r.Consent_to_Text_Date__c < :cutoffDate and Lead__r.isConverted = false) 
    							or (Contact__r.Consent_to_text__c = true and Contact__r.Consent_to_Text_Date__c < :cutOffDate) )];
			    							
			for (Reference_Do_Not_Contact__c refDNC: refDNCQuery)
			{	if (refDNC.Lead__c != null && !processIdSet.contains(refDNC.Lead__c))
				{	refDNCList.add(refDNC);
					processIdSet.add(refDNC.Lead__c);
				} // if
				else if (refDNC.Contact__c != null && !processIdSet.contains(refDNC.Contact__c))
				{	refDNCList.add(refDNC);
					processIdSet.add(refDNC.Contact__c);
				} // else
			} // for
System.debug('** BatchConsentToText.Iterator size='+refDNCList.size());			
	    	i = 0;	    		
 		} // CustomIterable
 		
 		global boolean hasNext() {
 			if (i >= refDNCList.size()) 
 			{	return false;	}
 			else 
 			{	return true;	}
 		} // hasNext
 		
 		global Reference_Do_Not_Contact__c next() {
 			if (i == refDNCList.size())
 			{	return null;	}
 			i++;
 			return refDNCList[i-1]; 			
 		} // next	
 		
 	} // CustomIterable
 	
}