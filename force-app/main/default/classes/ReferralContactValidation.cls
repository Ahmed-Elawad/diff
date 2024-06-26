/* 
    Perform any validations needed on Referral Contact object
    validateDeletions called by ReferralContactBefore trigger to see if ok to flag RC for deletion
       
  History
  -------
  04/10/2013 Cindy Freeman   Created
  08/23/2016 Dan Carmen      Update Code
  
 */


public with sharing class ReferralContactValidation {
    private static String tasksTimeFrame = 'ActivityDate > LAST_N_YEARS:3';     // use to pull any task within the last 3 calendar years
    private static String eventsTimeFrame = 'EndDateTime > LAST_N_YEARS:3';     // use to pull any event within the last 3 calendar years
    private static Boolean useTimeFrame;
    
    // pass in Ids of Referral Contacts that have been flagged To Be Deleted
    // add Error to each of the Referral Contacts that shouldn't be deleted because they have related records   
    public static void validateDeletions(Map<Id, Referral_Contact__c> deleteRefCtctMap, Boolean useTimeLimit) {
        useTimeFrame = useTimeLimit;
        
        // set of trigger rcd Ids
        //Set<Id> refCtctIds = new Set<Id>();
        //for (Referral_Contact__c rc: deleteRefCtcts)
        //{   refCtctIds.add(rc.Id);  }
        
        // set of trigger rcd Ids that should not be deleted
        //Set<Id> unDeleteRefCtcts = new Set<Id>();
        
        checkForRelatedRecords(deleteRefCtctMap);
        
        // check if used on Prospect-Client
        //unDeleteRefCtcts.addAll(checkForPCs(refCtctIds));
        //refCtctIds.removeAll(unDeleteRefCtcts);   
  
        // check for Leads linked to this Referral Contact
        //if (!refCtctIds.isEmpty())
        //{   unDeleteRefCtcts.addAll(checkForLeads(refCtctIds));
        //    refCtctIds.removeAll(unDeleteRefCtcts);
        //} // !deleteRefCtcts.IsEmpty    

        // check for Opportunities linked to this Referral Contact
        //if (!refCtctIds.isEmpty())
        //{   unDeleteRefCtcts.addAll(checkForOpptys(refCtctIds));
        //    refCtctIds.removeAll(unDeleteRefCtcts);
        //} // !deleteRefCtcts.IsEmpty    

        // check for Cases linked to this Referral Contact
        //if (!refCtctIds.isEmpty())
        //{   unDeleteRefCtcts.addAll(checkForCases(refCtctIds));
        //     refCtctIds.removeAll(unDeleteRefCtcts);
        //} // !deleteRefCtcts.IsEmpty    

        // check for Referrals linked to this Referral Contact
        //if (!refCtctIds.isEmpty())
        //{   unDeleteRefCtcts.addAll(checkForReferrals(refCtctIds));
        //    refCtctIds.removeAll(unDeleteRefCtcts);
        //} // !deleteRefCtcts.IsEmpty    

        // check for Activities linked to this Referral Account
        //if (!refCtctIds.isEmpty())
        //{   unDeleteRefCtcts.addAll(checkForActivities(refCtctIds));    } 

        // go thru list of trigger rcds to unDelete refAccts with related rcds
        //for (Referral_Contact__c refCtct : deleteRefCtcts)
        //{   if (unDeleteRefCtcts.contains(refCtct.Id))
        //    {   refCtct.To_Be_Deleted__c.addError('Cannot be deleted due to related records');
        //        refCtct.To_Be_Deleted__c = false;
        //    }
        //}
        checkForActivities(deleteRefCtctMap);
    } // validateDeletions
    
   private static void checkForRelatedRecords(Map<Id, Referral_Contact__c> deleteRefCtctMap) {
      System.debug('checkForRelatedRecords deleteRefCtctMap='+deleteRefCtctMap.size());
      if (!deleteRefCtctMap.isEmpty()) {
         // select the referral contacts with related records to get all at one time.
         Referral_Contact__c[] refCtcts = [Select Id
                                                 ,(Select Id, Name from Accounts2__r)   // Banker Full Name Relationship
                                                 ,(Select Id, Name from Accounts3__r)   // Broker Full Name relationship
                                                 ,(Select Id, Name from Accounts__r)  // CPA Funn Name relationship
                                                 ,(Select Id, Name from Lead__r) // Referral Contact on the lead object
                                                 ,(Select Id, Name from OppRCs__r) // Referral Contact on the Opportunity object
                                                 ,(Select Id, Name from Opportunities__r)  // Internal Referral on the Opportunity object
                                                 ,(Select Id from Cases__r) // Referral Contact on the case object
                                                 ,(Select Id, Name from Referrals__r) // Referral Contact on the Referral object
                                             From Referral_Contact__c
                                            Where Id in :deleteRefCtctMap.keySet()];
         System.debug('checkForRelatedRecords refCtcts='+refCtcts.size());
         for (Referral_Contact__c refCtct : refCtcts) {
            System.debug('checkForRelatedRecords refCtct.Accounts2__r='+refCtct.Accounts2__r.size());
            System.debug('checkForRelatedRecords refCtct.Accounts3__r='+refCtct.Accounts3__r.size());
            System.debug('checkForRelatedRecords refCtct.Accounts__r='+refCtct.Accounts__r.size());
            System.debug('checkForRelatedRecords refCtct.Lead__r='+refCtct.Lead__r.size());
            System.debug('checkForRelatedRecords refCtct.OppRCs__r='+refCtct.OppRCs__r.size());
            System.debug('checkForRelatedRecords refCtct.Opportunities__r='+refCtct.Opportunities__r.size());
            System.debug('checkForRelatedRecords refCtct.Cases__r='+refCtct.Cases__r.size());
            System.debug('checkForRelatedRecords refCtct.Referrals__r='+refCtct.Referrals__r.size());
            if (!refCtct.Accounts2__r.isEmpty()
                 || !refCtct.Accounts3__r.isEmpty()
                 || !refCtct.Accounts__r.isEmpty()
                 || !refCtct.Lead__r.isEmpty()
                 || !refCtct.OppRCs__r.isEmpty()
                 || !refCtct.Opportunities__r.isEmpty()
                 || !refCtct.Cases__r.isEmpty()
                 || !refCtct.Referrals__r.isEmpty()
               ) {
               Referral_Contact__c existingRefCtct = deleteRefCtctMap.remove(refCtct.Id);
               System.debug('checkForRelatedRecords existingRefCtct='+existingRefCtct);
               if (existingRefCtct != null) {
                  existingRefCtct.To_Be_Deleted__c.addError('Cannot be deleted due to related records');
                  existingRefCtct.To_Be_Deleted__c = false;
               } // if (existingRefCtct != null
            } // if (!refCtct.Accounts2__r.isEmpty
         } // for (Referral_Contact__c refCtct
      } // if (!deleteRefCtctMap.isEmpty
   } // checkForRelatedRecords
    
/*
    private static void checkForPCs(Map<Id, Referral_Contact__c> deleteRefCtctMap) {
       if (!deleteRefCtctMap.isEmpty()) {
          Set<Id> refCtctIdUsedSet = new Set<Id>();
          for (Account acct : [Select Id, Name, CPA_Name_Ref__c, Broker_Name_ref__c, Banker_Name_ref__c 
                                 from Account
                                where CPA_Name_ref__c in :deleteRefCtctMap.keySet() 
                                   or Broker_Name_ref__c in :deleteRefCtctMap.keySet() 
                                   or Banker_Name_ref__c in :deleteRefCtctMap.keySet()]) {
             
             if (acct.CPA_Name_Ref__c != null) {
                refCtctIdUsedSet.add(acct.CPA_Name_Ref__c);
             }
             if (acct.Broker_Name_ref__c != null) {
                refCtctIdUsedSet.add(acct.Broker_Name_ref__c);
             }
             if (acct.Banker_Name_ref__c != null) {
                refCtctIdUsedSet.add(Banker_Name_ref__c);
             }
          } // for (Account acct
       } // if (!deleteRefCtctMap.isEmpty
    } // checkForPCs
    
    private static Set<Id> checkForPCs(Set<Id> deleteRefCtcts) {        
        // look for any referral contacts linked on Prospect-Client records
        Set<Id> unDeleteRefCtcts = new Set<Id>();
        List<Account> accts = [Select Id, Name, CPA_Name_Ref__c, Broker_Name_ref__c, Banker_Name_ref__c from Account
                                    where CPA_Name_ref__c in :deleteRefCtcts or Broker_Name_ref__c in :deleteRefCtcts or Banker_Name_ref__c in :deleteRefCtcts];                                    
        for (Account acct : accts)
        {   if (deleteREfCtcts.contains(acct.CPA_Name_Ref__c))
            {   unDeleteRefCtcts.add(acct.CPA_Name_Ref__c); }
            if (deleteRefCtcts.contains(acct.Broker_Name_Ref__c))
            {   unDeleteRefCtcts.add(acct.Broker_Name_Ref__c);  }
            if (deleteRefCtcts.contains(acct.Banker_Name_Ref__c))
            {   unDeleteRefCtcts.add(acct.Banker_Name_Ref__c);  }
        }       
        return unDeleteRefCtcts;        
    } // checkForPCs
      
    private static Set<Id> checkForLeads(Set<Id> deleteRefCtcts) {      
        // look for any referral contacts inked to lead records
        Set<Id> unDeleteRefCtcts = new Set<Id>();
        List<Lead> Leads = [Select Id, Referral_Contact__c from Lead where Referral_Contact__c in :deleteRefCtcts];                                 
        for (Lead ld : Leads)
        {   unDeleteRefCtcts.add(ld.Referral_Contact__c);   }       
        return unDeleteRefCtcts;        
    } // checkForLeads

    private static Set<Id> checkForOpptys(Set<Id> deleteRefCtcts) {     
        // look for any referral contacts linked to opportunity records
        Set<Id> unDeleteRefCtcts = new Set<Id>();
        List<Opportunity> Opptys = [Select Id, Internal_Referral__c, Referral_Contact__c from Opportunity 
                                                    where Internal_Referral__c in :deleteRefCtcts or Referral_Contact__c in :deleteRefCtcts];
        for (Opportunity opty : Opptys)
        {   if (deleteRefCtcts.contains(opty.Internal_Referral__c))
            {   unDeleteRefCtcts.add(opty.Internal_Referral__c);    }
            if (deleteRefCtcts.contains(opty.Referral_Contact__c))
            {   unDeleteRefCtcts.add(opty.Referral_Contact__c); }
        }       
        return unDeleteRefCtcts;        
    } // checkForOpptys

    private static Set<Id> checkForCases(Set<Id> deleteRefCtcts) {      
        // look for any referral contacts linked to case records
        Set<Id> unDeleteRefCtcts = new Set<Id>();
        List<Case> kases = [Select Id, Referral_Contact__c from Case where Referral_Contact__c in :deleteRefCtcts];                                 
        for (Case kase : kases)
        {   unDeleteRefCtcts.add(kase.Referral_Contact__c); }       
        return unDeleteRefCtcts;        
    } // checkForCases

    private static Set<Id> checkForReferrals(Set<Id> deleteRefCtcts) {      
        // look for any referrals linked to contact records
        Set<Id> unDeleteRefCtcts = new Set<Id>();
        List<Referral__c> referrls = [Select Id, Referral_Contact__c from Referral__c where Referral_Contact__c in :deleteRefCtcts];                                    
        for (Referral__c ref : referrls)
        {   unDeleteRefCtcts.add(ref.Referral_Contact__c);  }       
        return unDeleteRefCtcts;        
    } // checkForReferrals
*/

   public static void checkForActivities(Map<Id,Referral_Contact__c> deleteRefCtctMap) {
      Set<Id> foundIdSet = ReferralAccountValidation.checkForActivity(ObjectHelper.OBJECT_EVENT, deleteRefCtctMap.keySet(), useTimeFrame);
      markErrors(deleteRefCtctMap, foundIdSet, 'Cannot be deleted due to related Activity');
      foundIdSet = ReferralAccountValidation.checkForActivity(ObjectHelper.OBJECT_TASK, deleteRefCtctMap.keySet(), useTimeFrame);
      markErrors(deleteRefCtctMap, foundIdSet, 'Cannot be deleted due to related Activity');
   } // checkForActivities
   
   private static void markErrors(Map<Id,Referral_Contact__c> deleteRefCtctMap, Set<Id> errorIdSet, String errorMessage) {
      for (Id errorId : errorIdSet) {
         Referral_Contact__c refCtct = deleteRefCtctMap.remove(errorId);
         if (refCtct != null) {
            refCtct.To_Be_Deleted__c.addError(errorMessage);
            refCtct.To_Be_Deleted__c = false;
         }
      } // for
   } // markErrors


    private static Set<Id> checkForActivities(Set<Id> deleteRefCtcts) {
        // look for any events or tasks, if found undelete the ref contact
        Set<Id> unDeleteRefCtcts = new Set<Id>();
        
        String actSOQL = 'SELECT Id, WhatId, WhoId, EndDateTime, Description from event where WhatId in :deleteRefCtcts';
        if (useTimeFrame)
        {   actSOQL = actSOQL + ' AND ' + eventsTimeFrame;  }
        
        List<Event> refEvents = Database.query(actSOQL);
        if (!refEvents.isEmpty())
        {   for (Event refEv : refEvents)
            {   deleteRefCtcts.remove(refEv.WhatId);        // take ref contact out of incoming verification list   
                unDeleteRefCtcts.add(refEv.WhatId);         // add ref contact to undelete list
            }
        }   
        if (!deleteRefCtcts.isEmpty())
        {   String taskSOQL = 'SELECT Id, WhatId, WhoId, ActivityDate, IsClosed from task where whatId in :deleteRefCtcts';
            if (useTimeFrame)
            {   actSOQL = actSOQL + ' AND ' + tasksTimeFrame;   }
            List<Task> refTasks = Database.query(taskSOQL);
            if (!refTasks.isEmpty())
            {   for (Task refTsk: refTasks)
                {   unDeleteRefCtcts.add(refTsk.WhatId);    }
            }               
        }       
        return unDeleteRefCtcts;
    } // checkforActivities


}