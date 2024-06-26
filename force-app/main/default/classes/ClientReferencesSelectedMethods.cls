/* 
 * Methods to process new Client References Selected to updated Client Reference
 *
 * History
 * -------
 * 08/21/2017 Cindy Freeman    created
 * 03/13/2018 Cindy Freeman		add methods to handle Accounts that go lost while out for reference 
 * 08/20/2018 Cindy Freeman		limit reject reason to 255 chanracters so it fits in the field
 */ 

public with sharing class ClientReferencesSelectedMethods implements TriggerInterface {
  
  /* clientRefSelected Ids that have been processed */
    public static Set<Id> clientRefSelIdsProcessed = new Set<Id>();
    
    /* clientRefSelected Ids to be processed */
    public static Set<Id> clientRefSelIdsToBeProcessed = new Set<Id>();
    
    /* clientRefSelected rejected that have been processed */
    public static Set<Id> crsRejectedProcessed = new Set<Id>();
    
    /* clientRefSelected rejected */
    public static Map<Id, Client_References_Selected__c> rejectedIdCRSMap = new Map<Id, Client_References_Selected__c>();
    
  /* counter needed for Test class to get better code coverage */
  public static Integer testcount = 0;
      
    public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

    public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

  /* called from inside For loop in before trigger
  */
    public void checkBeforeTrigger(SObject newRec, SObject oldRec) {
	  System.debug('** ClientReferencesSelectedMethods checkBeforeTrigger');    
      if (newRec != null && oldRec != null)
        {   Client_References_Selected__c newCRS = (Client_References_Selected__c)newRec;
            Client_References_Selected__c oldCRS = (Client_References_Selected__c)oldRec;
			System.debug('** ClientReferencesSelectedMethods checkBeforeTrigger new='+newCRS.Status__c+' newCRS reason='+newCRS.Rejected_Reason__c);          
            if (newCRS.Status__c == 'Rejected' && String.isBlank(oldCRS.Rejected_Reason__c))  
            {  rejectedIdCRSMap.put(newCRS.Id, newCRS);    }  
        }
    } // checkBeforeTrigger
   
    /* called from outside of For loop in before trigger
    */
    public void processBeforeTriggerActions() {
      if (!rejectedIdCRSMap.isEmpty()) 
        {  crsRejectedProcessed.addAll(rejectedIdCRSMap.keySet());
			System.debug('** ClientReferencesSelectedMethods processBeforeTriggerActions calling move');          
          	moveRejectedReasons();  
          	rejectedIdCRSMap.clear();
        }
      
    } // processBeforeTriggerActions
   
   
    /* called from inside For loop in after trigger
    */
    public void checkAfterTrigger(SObject newRec, SObject oldRec) {    
		System.debug('** ClientReferencesSelectedMethods checkAfterTrigger');      
    	if (newRec != null && oldRec != null)
        {  	Client_References_Selected__c newCRS = (Client_References_Selected__c)newRec;
          	Client_References_Selected__c oldCRS = (Client_References_Selected__c)oldRec;
			System.debug('** ClientReferencesSelectedMethods checkAfterTrigger new='+newCRS.Status__c+' oldCRS='+oldCRS.Status__c);         
          	if ((newCRS.Status__c == 'Approved' || newCRS.Status__c == 'Rejected' || newCRS.Status__c == 'Recalled' || newCRS.Status__c == 'Completed') 
            	&& (String.isBlank(oldCRS.Status__c) || oldCRS.Status__c != newCRS.Status__c))
          	{  clientRefSelIdsToBeProcessed.add(newCRS.Id);  }
        }   
  
    } // checkAfterTrigger

  /* called outside of For loop in after trigger */
    public void processAfterTriggerActions() {
      System.debug('ClientReferencesSelectedMethods, here at processAfterTriggerActions, Ids to be processed size='+clientRefSelIdsToBeProcessed.size());
      if (!clientRefSelIdsToBeProcessed.isEmpty())
      {  clientRefSelIdsProcessed.addAll(clientRefSelIdsToBeProcessed);        
         processClientRefSel();                      
         clientRefSelIdsToBeProcessed.clear();
      }     
      
    } // processAfterTriggerActions
  
    /* update Client Reference from Client Reference Selected */
    public static void processClientRefSel() {
		System.debug('**ClientReferencesSelectedMethods processClientRefSel clientRefSelIdsToBeProcessed'+clientRefSelIdsToBeProcessed.size());    
    	List<Client_Reference__c> updateCRList = new List<Client_Reference__c>();
      	List<Client_References_Selected__c> crsList = [Select Id, Status__c, Client_Reference__c,  Client_Reference__r.VoC_Indicator__c 
                        from Client_References_Selected__c where Id in :clientRefSelIdsToBeProcessed];

    	for (Client_References_Selected__c crs: crsList)                        
    	{   if (crs.Status__c == 'Approved' && (String.isBlank(crs.Client_Reference__r.VoC_Indicator__c) || crs.Client_Reference__r.VoC_Indicator__c != 'Available'))
      		{   Client_Reference__c cr = new Client_Reference__c();
	        	cr.Id = crs.Client_Reference__c;
	        	cr.VoC_Indicator__c = 'Out for reference';
	        	updateCRList.add(cr);
	      	}
      		else if ((crs.Status__c == 'Rejected' || crs.Status__c == 'Recalled' || crs.Status__c == 'Completed') 
          		&& (String.isBlank(crs.Client_Reference__r.VoC_Indicator__c) || crs.Client_Reference__r.VoC_Indicator__c != 'Available'))
        	{   Client_Reference__c cr = new Client_Reference__c();
        		cr.Id = crs.Client_Reference__c;
        		cr.VoC_Indicator__c = 'Available';
        		updateCRList.add(cr);
      		}
    	} // for
    
    	if (!updateCRList.isEmpty())
    	{  update updateCRList;  }
    
  } // processClientRefSel
  
  public static Boolean LOG_REJECT_REASON=Label.Client_Reference_Selected_Log_Reject == 'Y';
   
    /* if Client Reference Selected is rejected, make sure they put in a comment that can be moved to reject reason field
    */
    public static void moveRejectedReasons() {
		System.debug('**ClientReferencesSelectedMethods moveRejectedReasons rejectedIdCrsMap keySet='+rejectedIdCRSMap.keySet());
        ProcessInstance[] piList = [SELECT Id, TargetObjectId, 
                        (SELECT Id, StepStatus, Comments FROM Steps) 
                                  FROM ProcessInstance Where targetObjectID in :rejectedIdCRSMap.keySet() and Status = 'Rejected'
                                  ORDER BY ElapsedTimeInMinutes Desc];  
		System.debug('**ClientReferencesSelectedMethods moveRejectedReasons piList='+piList.size());   
        
        Map<Id, ProcessInstance> piMap = new Map<Id, ProcessInstance>();
        for (ProcessInstance pi:piList)
        {   piMap.put(pi.TargetObjectId, pi);   }
        
		System.debug('**ClientReferencesSelectedMethods moveRejectedReasons piMap='+piMap.size()); 
        for (Client_References_Selected__c crs: rejectedIdCRSMap.Values()) 
        {   ProcessInstance crsPI = piMap.get(crs.Id);
            for (SObject step: crsPI.Steps)
            {  
			  System.debug('**ClientReferencesSelectedMethods step='+crs);              
              if ((String)step.get('StepStatus') == 'Rejected')
               {   if (String.isBlank((String)step.get('Comments')))
                   {  if (LOG_REJECT_REASON) {
                         crs.AddError('You must enter a Reject Reason in the Comments field. Please use the Back arrow to get to the previous screen to fill in a reason.');
                      }
                   } // if (String.isBlank
                   else
                   {  //crs.Rejected_Reason__c = (String)step.get('Comments');
                   	  String reeson = (String)step.get('Comments');
                   	  crs.Rejected_Reason__c = (reeson.length() > 255 ? reeson.left(255): reeson);
                   }

               } // if rejected
            } // for steps            
        } // for refList    
                
    } // moveRejectedReasons
    
    /* if Prospect-Client goes Lost while there is a Client Reference Selected active for it, change status on CR Selected */
    public static void referenceWentLost(Set<Id> lostAcctSet) {
    	
        Set<Id> crIdSet = new Set<Id>();
        List<Client_Reference__c> crUpdateList = new List<Client_Reference__c>();
        
        List<Client_References_Selected__c> crsList = [Select Id, Status__c, Client_Reference__c,  Client_Reference__r.VoC_Indicator__c 
                        from Client_References_Selected__c where Account__c in :lostAcctSet and VoC_Indicator__c = 'Out for reference'];
                                
        for (Client_References_Selected__c crs:crsList)
        {	clientRefSelIdsProcessed.add(crs.Id);			// so trigger doesnt try to update record again 
        	crs.Status__c = 'No Longer an Active Client';
        	crIdSet.add(crs.Client_Reference__c);	
        }
        for (id crId: crIdSet)
        {	Client_Reference__c cr = new Client_Reference__c();
        	cr.Id = crId;
        	cr.VoC_Indicator__c = 'No Longer an Active Client';
        	crUpdateList.add(cr);
        }
        
		System.debug('**ClientReferencesSelectedMethods.referenceWentLost, crs udpates='+crsList.size()+' cr updates='+crUpdateList.size());        
        DmlHelper.performDML2(crsList, DmlHelper.DML_UPDATE, 'ClientReferencesSelectedMethods', 'referenceWentLost', 'Update Client Ref Selected when Account Lost', false);              
		DmlHelper.performDML2(crUpdateList, DmlHelper.DML_UPDATE, 'ClientReferencesSelectedMethods', 'crUpdateList', 'Update Client Ref when Account Lost', false);                        
    	
    } // referenceWentLost
    
} // ClientReferenceSelectedMethods