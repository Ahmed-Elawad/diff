/* 
 * Methods to publish a case thru SF2SF to another org
 *
 * History
 * -------
 * 08/03/2017 Cindy Freeman		created
 * 11/02/2020 Brandon Vidro     Moved workflow rule to update MSP Client Type on Case to Ascentis when Origin = 'Email-to-Case MSP Asc'
 * 11/17/2020 Brandon Vidro     Trigger case publish on update as well as insert
 * 
 */ 

public with sharing class CaseSF2SFMethods implements TriggerInterface {

    /* case Ids that have been processed */
    public static Set<Id> caseSF2SFIdsProcessed = new Set<Id>();
    
    /*  case Ids to be sent SF2SF */
    public static Set<Id> caseSF2SFIdsPublish = new Set<Id>();
    
    /* case Ids to update MSP Client Type to Ascentis */
    public static Set<Case> caseSF2SFIdsUpdateMspClientType = new Set<Case>();
    
    /* record type we are looking for */
    public static Id caseRcdTypeId;

	/* counter needed for Test class to get better code coverage */
	public static Integer testcount = 0;
	    
    public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

    public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

    public void checkBeforeTrigger(SObject newRec, SObject oldRec) {      
        if (newRec != null && oldRec == null)
        {	
            Case newKase = (Case)newRec;
            if (newKase.MSP_Client_Type__c != 'Ascentis' && newKase.Origin == 'Email-to-Case MSP Asc' ) {	
                caseSF2SFIdsUpdateMspClientType.add(newKase);
            } 
        }
    }
    
    public void processBeforeTriggerActions() {
        if (!caseSF2SFIdsUpdateMspClientType.isEmpty() && caseSF2SFIdsUpdateMspClientType != null) {
            for(Case caseMsp: caseSF2SFIdsUpdateMspClientType) {
                caseMsp.MSP_Client_Type__c = 'Ascentis';
            }
        }
    }
    
    public void checkAfterTrigger(SObject newRec, SObject oldRec) { 
       
        if (caseRcdTypeId == null)
        {	Schema.RecordTypeInfo caseRt = RecordTypeHelper.getRecordType('Service Support MSP Case', ObjectHelper.OBJECT_CASE); 
         if (caseRt == null)
         {	ErrorLog.logError('CaseSF2SFMethods', 'checkAfterTrigger', 'missing Case Record Type', null, 'missing rcd type-Service Support MSP Case');
          ErrorLog.checkSave();
          return;
         } // if (caseRt == null)   
         
         caseRcdTypeId = caseRt.getRecordTypeId();
        } // if (caseRcdTypeId ==  null) 
        
        if (newRec != null && oldRec == null) {
            Case newKase = (Case)newRec;
            if (!caseSF2SFIdsProcessed.contains(newKase.Id) && newKase.RecordTypeId == caseRcdTypeId && newKase.MSP_Client_Type__c != null && newKase.MSP_Client_Type__c == 'Ascentis' && newKase.AccountId != null) {
                caseSF2SFIdsPublish.add(newKase.Id);
            } 
        }
        if (oldRec != null && newRec != null) {
            Case newKase = (Case)newRec;
            Case oldKase = (Case)oldRec;
            if (!caseSF2SFIdsProcessed.contains(newKase.Id) && newKase.RecordTypeId == caseRcdTypeId && 
                (newKase.MSP_Client_Type__c != null && newKase.MSP_Client_Type__c == 'Ascentis' && newKase.MSP_Client_Type__c != oldKase.MSP_Client_Type__c) || 
                (newKase.MSP_Client_Type__c != null && newKase.MSP_Client_Type__c == 'Ascentis' && oldKase.MSP_Client_Type__c == 'Ascentis' && newKase.AccountId != null && newKase.AccountId != oldKase.AccountId)) {
                caseSF2SFIdsPublish.add(newKase.Id);
            } 
        }
        
    } // checkBeforeSF2SF
       
    public void processAfterTriggerActions() {
    	if (!caseSF2SFIdsPublish.isEmpty())
    	{	caseSF2SFIdsProcessed.addAll(caseSF2SFIdsPublish);
    		publishCases();    	    		
    		caseSF2SFIdsPublish.clear();
    	}
    	
    } // processSF2SF
  
  	public static void publishCases() {
  		if (Test.isRunningTest())
        {	testCount +=1;	}
        
        String connectionLabel = (testCount<2 ? Label.SF2SF_Connection_MSP : 'TestConnection');
       
  		List<PartnerNetworkConnection> connList = new List<PartnerNetworkConnection>(
    			[select Id, ConnectionStatus, ConnectionName, accountId from PartnerNetworkConnection 
    			where ConnectionName = :connectionLabel and ConnectionStatus='Accepted']);
    			
		if (connList.isEmpty())
		{	ErrorLog.logError('CaseSF2SFMethods', 'publishCases', 'missing PartnerNetworkConnection', null, 'missing ConnectionName='+connectionLabel);
            ErrorLog.checkSave();
			return;
		}
		
		for (Id caseId: caseSF2SFIdsPublish)
		{	 PartnerNetworkRecordConnection newrecord = new PartnerNetworkRecordConnection();
			   newrecord.ConnectionId = connList.get(0).Id;
			   newrecord.LocalRecordId = caseId;
			   insert newrecord;			   
		} // for
		
  	} // publishCases
    

}