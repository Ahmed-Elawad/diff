/*
   If the current step field changes on the Reference Reference Terms/Transfers object, update the current step
   field on the case. 
   
  History
  -------
  03/04/2013 Josh Cartwright   Created
  11/12/2014 Josh Cartwright added QDRO Chatter Post 
  08/05/2019 Matthew Fritschi	Added ability to create a Case when Stable Value Funds is changed.
  09/09/2019 Matthew Fritschi   Case is no longer created if Stable Value Funds is 'N/A'

*/

trigger ReferenceTermTransUpdateCase on Reference_Terms_Transfers__c (after update) {

/* The records to be updated. */
   Map<Id,String> caseStepMap = new Map<Id,String>();
   list<Reference_Terms_Transfers__c> changedStableValueFunds = new list<Reference_Terms_Transfers__c>();
   list<Reference_Terms_Transfers__c> chatterPostToAdd = new list<Reference_Terms_Transfers__c>();
   for (Reference_Terms_Transfers__c newRT: Trigger.new) {
      System.debug('ReferenceTermTransUpdateCase checking record newRT.Current_Step__c='+newRT.Current_Step__c);
      // should be a lookup present and a value in the current step field.
      Reference_Terms_Transfers__c oldRT = Trigger.oldMap.get(newRT.id);
      if ((newRT.Case_Lookup__c != null) && (newRT.Current_Step__c != '')) {
         if (Trigger.isUpdate) {
             System.debug('The New RTT='+newRT);
             System.debug('The OLD RTT='+oldRT);
            // if update, only set if there is a value and step field changes 
            if ((newRt.Current_Step__c != oldRT.Current_Step__c)) {
               caseStepMap.put(newRT.Case_Lookup__c,newRT.Current_Step__c);      
            }
             System.debug('oldRT.Stable_Value_Funds__c='+oldRT.Stable_Value_Funds__c+' newRT.Stable_Value_Funds__c='+newRT.Stable_Value_Funds__c);
             if(String.isBlank(oldRT.Stable_Value_Funds__c) && String.isNotBlank(newRT.Stable_Value_Funds__c) && newRT.Current_Step__c == oldRT.Current_Step__c)
      		{
                System.debug(' Discrepancy='+oldRT.Type_of_Discrepancy__c);
         		changedStableValueFunds.add(newRT);
      		}
         } // if
      } // if ((newRT.Case_Lookup__c
       
      //If stable value funds is set, create a case.
      
       
      Schema.RecordTypeInfo qdroRT = RecordTypeHelper.getRecordType('QDRO', 'Reference_Terms_Transfers__c'); 
      if(newRt.RecordTypeid == qdroRT.getRecordTypeId() && newRT.CAM_Specialist__c !=null && (newRT.CAM_Specialist__c != oldRT.CAM_Specialist__c)){
         chatterPostToAdd.add(newRT);
         system.debug('JGS'+newRT);
      } 
                  
   } // for (Reference_TAA__c
   
   if (!caseStepMap.isEmpty()) {
      System.debug('updateCaseStep');
      ReferenceUpdateCase.updateCaseStep(caseStepMap);
   }
   
   if(!chatterPostToAdd.isEmpty()){
    for(Reference_Terms_Transfers__c rTT:chatterPostToAdd){
        ChatterMentionPost.createChatterMentionPost(rTT.id,new Id[]{rTT.CAM_Specialist__c}, 'A QDRO has been assigned to you');         
    }
   }
    
    if(!changedStableValueFunds.isEmpty()){
        System.debug('changedStableValueFunds='+changedStableValueFunds);
    	for(Reference_Terms_Transfers__c rTT:changedStableValueFunds){
        	String caseSubject = 'Stable Value Fund - ';
        	if(rTT.Stable_Value_Funds__c != null)
        	{
            	caseSubject = caseSubject+rTT.Stable_Value_Funds__c;
        	}
        	System.debug('rTT.Case_Lookup__c='+rTT.Case_Lookup__c+' rTT.Stable_Value_Fund_Rep__c'+rTT.Stable_Value_Funds_Rep_Lookup__c);
            Case[] kase = [SELECT Id, ContactId FROM Case WHERE Id=:rTT.Case_Lookup__c];        
            System.debug('rTT.Case_Lookup__c='+rTT.Case_Lookup__c+' rTT.Stable_Value_Funds_Rep_Lookup__c='+rTT.Stable_Value_Funds_Rep_Lookup__c+' kase[0].ContactId='+kase[0].ContactId);
        	if(rTT.Case_Lookup__c != null && rTT.Stable_Value_Funds_Rep_Lookup__c != null && kase[0].ContactId!=null && String.isNotBlank(rTT.Stable_Value_Funds__c) && rTT.Stable_Value_Funds__c != 'N/A')	
        	{
            	Case parentCase = new Case(OwnerId=rTT.Stable_Value_Funds_Rep_Lookup__c
                                     ,Status='New'
                                     ,Product__c='401K'
                                     ,Subject=caseSubject
                                     ,Reason='Request/Action Needed'
                                     ,Call_Topic__c='Termination/Transfer'
                                     ,Disposition_1__c='Administrator'
                                     ,Disposition_2__c='Self'
                                     ,Follow_Up_Date__c=Date.today().addDays(1)
                                     ,RecordTypeId='012700000001U2zAAE'
                                     ,ParentId=rTT.Case_Lookup__c
                                     ,ContactId = kase[0].ContactId);
                
                insert parentCase;
        	}//end if(rTT.Case_Lookup__c != null && rTT.Stable_Value_Fund_Rep__c != null)
    	} //end For
        changedStableValueFunds.clear();
   }// end if(!changedStableValueFunds.isEmpty())

} // trigger ReferenceTermTransUpdateCase