/*History
-------
11/26/2013 	Josh Cartwright 		created for HNBF
09/03/2020 	Jake Hinds		 		adding owner change
1/12/2023  	Susmitha Somavarapu  	APR0143795 ATC Case to allow for HNBF Enrollments
12/28/2023	Ahmed Elawad			Modified trigger to do before insert/update group assignment for SFDC-24351 fast-track: new payroll integration queues w/ round robin 
*/
trigger ReferenceHNBFUpdateCase on Reference_HNBF__c (before insert, before update, after update) {
    
    static FINAL String AOR_PAYROLL_QUEUE_NAME = 'AOR Payroll Integration Queue';
    static FINAL String NEW_CASE_PAYROLL_QUEUE_NAME = 'New Case Payroll Integration Queue';
    
    // records are added to this list for round robin assignments
    List<Reference_HNBF__c> RRReferenceHnbfRecords = new List<Reference_HNBF__c>();
    
    // before insert or update
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {        
        
        Map<String, List<Reference_HNBF__c>> recordsToAssignToAORQueue = new Map<String, List<Reference_HNBF__c>>();
        
        for (Reference_HNBF__c referenceHNBFRecord : Trigger.new) {
            
            String targetQueueName;
            Boolean isSentToPayroll = referenceHNBFRecord.current_Step__c != null && referenceHNBFRecord.current_Step__c == 'Sent to Payroll Integration';
            if (isSentToPayroll && referenceHNBFRecord.Submission_type__c == 'AOR Flock Pilot') {
                targetQueueName = AOR_PAYROLL_QUEUE_NAME;
            } else if (isSentToPayroll && referenceHNBFRecord.Submission_type__c == 'SDA Flock Net-New') {
                targetQueueName = NEW_CASE_PAYROLL_QUEUE_NAME;
            }
            
            if (targetQueueName != null) {
                referenceHNBFRecord.current_Step__c = 'NC Processing: Payroll Integration';
                List<Reference_HNBF__c> listOfrecordsForQueue = recordsToAssignToAORQueue.get(targetQueueName);
                if (listOfrecordsForQueue == null) {
                    listOfrecordsForQueue = new List<Reference_HNBF__c>();
                    recordsToAssignToAORQueue.put(targetQueueName, listOfrecordsForQueue);
                }
                listOfrecordsForQueue.add(referenceHNBFRecord);
            }
            
        } // end Trigger.new loop
        
        // start update owner to be queue
        if (!recordsToAssignToAORQueue.keySet().isEmpty()) {
            Map<String,Group> integrationQueues = UserHelper.getQueueMapByName(new List<String>(recordsToAssignToAORQueue.keySet()));
            // set the owner for each record as the queue
            for (String queueName : recordsToAssignToAORQueue.keySet()) {
                List<Reference_HNBF__c> recordsToAssignQueueAsOwnder =  recordsToAssignToAORQueue.get(queueName);
                Group newOwnerQueue = integrationQueues.get(queueName);
                if (newOwnerQueue != null && recordsToAssignQueueAsOwnder != null && !recordsToAssignQueueAsOwnder.isEmpty()) {
                    for (Reference_HNBF__c hnbfRecord : recordsToAssignQueueAsOwnder) {
                        hnbfRecord.ownerId = newOwnerQueue.Id;
                        RRReferenceHnbfRecords.add(hnbfRecord);
                    }
                }
            }
            
            // prepare round robin for all records with new queue owner
            if(!RRReferenceHnbfRecords.isEmpty()){
                RoundRobin.prepareGenericRoundRobin(RRReferenceHnbfRecords,null);
            }
        } // end update owner to be queue
        
    } // end before insert && before update
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        /* The records to be updated. */
        Map<Id,String> caseStepMap = new Map<Id,String>();
        Map<Id,String> caseOwnerMap = new Map<Id,String>();
        Id hnbfRT = RecordTypeHelper.getRecordType('HNB Enrollments ATC Record Type', 'Reference_HNBF__c').getRecordTypeId();
        //APR0143795	
        List<Case> asetoUpdate = new List<Case>();		
        Date todayDate = System.today(); //new Date.today(); //APR0143795
        for ( Reference_HNBF__c newRT: Trigger.new) {
            System.debug('ReferenceHNBFUpdateCase checking record newRT.Current_Step__c='+newRT.Current_Step__c);
            // should be a lookup present and a value in the current step field.
            if (Trigger.isUpdate) {
                Reference_HNBF__c oldRT = Trigger.oldMap.get(newRT.id);
                if (newRT.Case_Number__c != null && newRT.Current_Step__c != '' && (newRt.Current_Step__c != oldRT.Current_Step__c)) {
                    // if update, only set if there is a value and step field changes 
                    caseStepMap.put(newRT.Case_Number__c,newRT.Current_Step__c);
                }
                if (newRt.OwnerId != oldRT.OwnerId && newRt.RecordTypeId == hnbfRT) {
                    caseOwnerMap.put(newRT.Case_Number__c,newRt.OwnerId);
                }
                // APR0143795-ATC Case to allow for HNBF Enrollments	
                // Checking Case Status when record type = HNB ENrollemts ATC Record Type	
                if (newRT.Status__c != oldRT.Status__c && newRt.RecordTypeId == hnbfRT) {		
                    //   newRT.Status_Date__c = todayDate;	 	
                    // Collecting case values to update the case status when HNB Record status is changed	
                    Case rtnCase =  ReferenceupdateCase.updateCaseStatus(newRT); 	                                	      	
                    asetoUpdate.add(rtnCase); 	                                		
                } // APR0143795
            } // if (Trigger.isUpdate)
            
        } // for (Reference_HNBF__c
        
        if (!caseStepMap.isEmpty()) {
            ReferenceUpdateCase.updateCaseStep(caseStepMap);
        }
        if (!caseOwnerMap.isEmpty()) {
            ReferenceUpdateCase.updateCaseOwner(caseOwnerMap);
        }	//APR0143795	
        if(!asetoUpdate.isEmpty()){		
            update asetoUpdate; //APR0143795
        }
    }
}