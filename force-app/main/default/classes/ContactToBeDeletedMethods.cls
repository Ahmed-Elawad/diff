/* 
 * Things to do when a Contact is marked To Be Deleted or No Longer with Company
 *
 * History
 * -------
   01/12/2018 Cindy Freeman     Created
   02/20/2018 Cindy Freeman		moved ErrorLog.checkSave to avoid Too Many DML statements error
   02/24/2018 Cindy Freeman		modified to look for Service Contracts linked to contacts
   02/24/2018 Matt Fritschi		modified to not check for No_Longer_With_Company field. Hides contact from sales reps if to be deleted.
   10/28/2019 Dan Carmen         Fix NPE (on insert of a contact)
 *
 *
 */
public without sharing class ContactToBeDeletedMethods implements TriggerInterface {

    public static Set<Id> idsProcessedSet = new Set<Id>();
   
    /** contact Ids that were marked To Be Deleted or No Longer with Company **/
    public static Set<Id> v_idsToProcessSet = new set<Id>();
    
      
    public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {
    } // checkAllBeforeTrigger

    public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {
            
        System.debug('ContactToBeDeletedMethods.checkAllAfterTrigger recs='+recs.size());
        if (recs.size() > 0)
        {   for (SObject sobj : recs)
            {   if (!idsProcessedSet.contains(sobj.Id)) 
                {   Contact newCtct = (Contact)sobj;
                    Contact oldCtct = (oldMap != null ? (Contact)oldMap.get(newCtct.Id) : null);
                    if (newCtct.To_Be_Deleted__c && oldCtct != null && !oldCtct.To_Be_Deleted__c)
                    {   v_idsToProcessSet.add(newCtct.Id);  }                   
                } // if (!idProcessedSet
            } // for    
         } // if (recs.size > 0) 
        
    } // checkAllAfterTrigger

    public void checkBeforeTrigger(SObject newRec, SObject oldRec) {}
   
    public void processBeforeTriggerActions() {}
   
    public void checkAfterTrigger(SObject newRec, SObject oldRec) {}
   
    public void processAfterTriggerActions() {
        if (!v_idsToProcessSet.isEmpty())
        {   processToBeDeleted(v_idsToProcessSet);
            idsProcessedSet.addAll(v_idsToProcessSet);
        }    
        
    } // processAfterTriggerActions
    
    // for testing purposes
    public static Boolean SKIP_FUTURE=Test.isRunningTest();
    
    /*  call method to process Contacts flagged 
    */
    public static void processToBeDeleted(Set<Id> p_idsToProcessSet) {          
        if (System.isFuture() || System.isBatch() || SKIP_FUTURE) 
        {   checkToBeDeleted(p_idsToProcessSet);    }
        else 
        {  checkToBeDeletedFuture(p_idsToProcessSet);   }
        
    } // processToBeDeleted
   
     
    @future
    public static void checkToBeDeletedFuture(Set<Id> v_idsToProcessSet) {
         checkToBeDeleted(v_idsToProcessSet);
    }     
      
    public static void checkToBeDeleted (Set<Id> v_idsToProcessSet) {
        List<Contact> updateCtctList = new List<Contact>();
        System.debug('**ContactToBeDeletedMethods.checkToBeDeleted idsToProcess size='+v_idsToProcessSet.size());   
        
        // find Service Contracts for these contracts
        List<ServiceContract> serviceList = [Select Id, AccountId, ContactId from ServiceContract
        										where ContactId in :v_idsToProcessSet];
		Set<Id> ctctServiceSet = new Set<id>();
		for (ServiceContract svc: serviceList)
		{	ctctServiceSet.add(svc.ContactId);	}
		       										    
        Contact[] queryCtctList = [Select Id, DoNotCall,HasOptedOutOfEmail, HasOptedOutOfFax, CreatedDate
                                    ,To_Be_Deleted_Date__c, Purge_Exception__c, Sales_Contact__c, SignificantContact__c
                                    ,CreatedBy.Name, OwnerId
                                    ,(Select Id, Status from Cases limit 1)
                                    //,(Select Id, Stagename from Opportunities limit 1)
                                    ,(Select Id, ContactId, OpportunityId from OpportunityContactRoles limit 1)
                                    ,(Select Id, WhoId, Status from Tasks limit 1)
                                    ,(Select Id, WhatId, ActivityDateTime from Events limit 1)
                                    from Contact where Id in :v_idsToProcessSet];
        System.debug('**ContactToBeDeletedMethods.checkToBeDeleted queryCtctList size='+queryCtctList.size());
        System.debug('**ContactToBeDeletedMethods.checkToBeDeleted Contact Returned='+queryCtctList[0]);
        //User[] newOwner = [SELECT Id, Name FROM User WHERE Name = 'SFDC Data' LIMIT 1];
        for (Contact ctct: queryCtctList) {
            String[] purgeReasons = new String[]{};
            if (ctct.DoNotCall || ctct.HasOptedOutOfEmail || ctct.HasOptedOutOfFax) {
               purgeReasons.add('has DNC');
            }   
            if (ctct.Cases.size() > 0) {   
               purgeReasons.add('has Case');
            }
            if (ctct.OpportunityContactRoles.size() > 0) {   
               purgeReasons.add('has Opportunity');
            }
            if (ctct.Tasks.size() > 0) {   
               purgeReasons.add('has Task');
            }
            if (ctct.Events.size() > 0) {   
               purgeReasons.add('has Event');  
            }
            if (ctctServiceSet.contains(ctct.Id)) {	
               purgeReasons.add('has Service Contract');
            }
            Contact newCtct = new Contact();
            newCtct = ctct;
            newCtct.Id = ctct.Id;
            
            if (purgeReasons.isEmpty()) {
               newCtct.To_Be_Deleted_Date__c = Date.today().addDays(90);
            } else {
               newCtct.Purge_Exception__c = String.join(purgeReasons,';');
            }
            
            //newCtct.Sales_Contact__c = false;
     
            //newCtct.OwnerId = newOwner[0].Id;
            
           // System.debug('checkToBeDeleted The User ID for new contact owner is: ' + newOwner[0].Id);
            //System.debug('checkToBeDeleted The Name of the new owner is: ' + newOwner[0].Name);
                               
            // if SFDC Data created this contact, allow it to be removed as a Sales Contact
            if (ctct.CreatedBy != null && UserHelper.isSfdcData(ctct.CreatedBy.Name)) {
               newCtct.Sales_Contact__c = false;
            }               
            updateCtctList.add(newCtct);
        } // for
        
        System.debug('checkToBeDeleted updateCtctList.isEmpty=' + updateCtctList.isEmpty());
        if (!updateCtctList.isEmpty()) {
           System.debug('The New Contact Is: ' + updateCtctList[0]);
           DmlHelper.performDML2(updateCtctList, DmlHelper.DML_UPDATE, 'ContactToBeDeletedMethods', 'checkToBeDeleted', 'updating updateCtctList', true);
        }
        
    } // checkToBeDeleted


} // class ContactToBeDeletedMethods