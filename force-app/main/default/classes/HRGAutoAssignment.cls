/*
History
-------
06/01/2022 Eric Porter       Created
 */

public without sharing class HRGAutoAssignment implements TriggerInterfaceC{

    public static String[] VALID_PRODS=Label.HRG_Prods.split(',');
    private  UserHelper userHelper = new UserHelper();

    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        System.debug('HRGAutoAssignment.handleTrigger recs='+(recs != null ? recs.size() : -1)+' obj='+(recs != null && recs.size() > 0 ? recs[0].getSObjectType().getDescribe().getName() : 'NoObject')+' isBefore='+isBefore+' isAfter='+isAfter ); 

        if (recs == null || recs.isEmpty()) {
           return;
         }
         if (isAfter && recs[0].getSObjectType() == Opportunity.sObjectType) {
             System.debug('running HRG Trigger');
             Map<Id,Opportunity> validOpps = new Map<Id,Opportunity>();
             Map<Id,Opportunity> meetsCriteria = new Map<Id,Opportunity>();
             for(Opportunity opp: (Opportunity[]) recs){
                 Opportunity oldOpp =(oldMap != null ? (Opportunity) oldMap.get(opp.Id) : null);
                //  if(oldOpp != null && opp.AccountId != null && opp.StageName != oldOpp.StageName && opp.Probability == 90){
                    if(oldOpp != null && opp.AccountId != null && opp.Assign_HRG__c != oldOpp.Assign_HRG__c && opp.Assign_HRG__c && opp.Probability >= 90){
                    //if(meetsCriteria.get(opp.Id)==null){
                        meetsCriteria.put(opp.Id, opp);
                    //} 
                 }
             }
             if (meetsCriteria.isEmpty()) {
                return;
             }
             Set<Id> acctIdSet = new Set<Id>();
             System.debug('meetCriteria Value: '+meetsCriteria.keyset());
             Set<OpportunityLineItem> checkOlis = new Set<OpportunityLineItem>([Select Id, Name, Product2Id, Product2.Name,OpportunityId  
                                                  from OpportunityLineItem  where OpportunityId in :meetsCriteria.keySet() and Product2.Name in :VALID_PRODS]);
             System.debug('CheckOLIS: '+ checkOlis.size());
             for (OpportunityLineItem oli : checkOlis) {
                Opportunity opp = meetsCriteria.get(oli.OpportunityId);
                if (opp != null) {
                    //deduping logic
                    if(validOpps.get(opp.Id)==null){
                        validOpps.put(opp.Id, opp);
                    }
                    acctIdSet.add(opp.AccountId);
                }
             }
             System.debug('ValidOps:  ' + validOpps.size());
             if (!validOpps.isEmpty()) {
                HRGAutoAssignmentQueueable HRGAssignmentJob = new HRGAutoAssignmentQueueable(validOpps,acctIdSet);
                ID jobID = System.enqueueJob(HRGAssignmentJob);
                System.debug('starting HRG Auto-Assignment Job');
             }
             List<Opportunity> updatedOps = new List<Opportunity>();
         for(Opportunity op: validOpps.values()){
            Opportunity updatedOpp = new Opportunity(id= op.Id, Assign_HRG__c = false);
            updatedOps.add(updatedOpp);
         }
         upsert updatedOps;
 
 
     }
     if(isBefore && recs[0].getSObjectType() == HRG_Assignment__c.sObjectType){
        HRG_Assignment__c[] roundRobinList = new HRG_Assignment__c[]{};
        for(HRG_Assignment__c hao: (HRG_Assignment__c[])recs){
            if(String.valueOf(hao.OwnerId).startsWith('00G')){
                roundRobinList.add(hao);
            }
        }
        //if owner is queue
         
         //
         if(!roundRobinList.isEmpty()){
            System.debug('Round Robin Has been prepared for HRGAssignment');
            RoundRobin.prepareGenericRoundRobin(roundRobinList,null);
         }
         

     }
     // handle HRG's when they are auto approved
     if(isAfter && recs[0].getSObjectType() == HRG_Assignment__c.sObjectType){
         // TODO - this logic should be refactored out to another method
         // check if status is approved or override 
        // and HRPSelect... is populated
        Set<Id> accountIds = new Set<Id>();
        Set<Id> newManagerIds = new Set<Id>();
        Set<Id> oldOppIds = new Set<Id>();
        Set<Id> selectedHrpIds = new Set<Id>(); 
        Map<Id,HRG_Assignment__c> hrgMap = new Map<Id,HRG_Assignment__c>();
        Map<Id,Contact> managerMap = new Map<Id,Contact>();
        for(HRG_Assignment__c hao:(HRG_Assignment__c[]) recs){
             System.debug('HRGAutoAssignment.handleTrigger status='+hao.Status__c);
             if((hao.Status__c == 'Approved'||hao.Status__c =='Manager Override')&& hao.SelectedHRP__c !=null){
                accountIds.add(hao.Account__c);
                hrgMap.put(hao.Account__c,hao);
                newManagerIds.add(hao.Manager__c);
                HRG_Assignment__c oldHao = (oldMap != null ? (HRG_Assignment__c)oldMap.get(hao.Id) : null);
                if(oldHao!=null){
                    oldOppIds.add(oldHao.Opportunity__c);
                }
                selectedHrpIds.add(hao.SelectedHRP__c);
             }
            }
            if(!oldOppIds.isEmpty()){
                // TODO - SHOULD NOT BE DELETING INSIDE A LOOP FROM A TRIGGER
                for(Id oppId:oldOppIds){
                    deleteOldOTMS(oppId);
                }
            }
      if (!accountIds.isEmpty()) {
        // get manager map from contacts
        List<Contact> managerCtcts = [Select Id, User_Lookup__c from Contact where User_Lookup__c in:newManagerIds];
        for(Contact manager: managerCtcts){
            managerMap.put(manager.User_Lookup__c,manager);
        }
        System.debug('ManagerMap: '+managerMap);
        // get hrps contacts from hrpId
        Map<Id,Contact> hrpContactMap = new Map<Id,Contact>([Select Id,User_Lookup__c from Contact where Id in:selectedHrpIds]);


         Map<Id,Account> acctsMap = new Map<Id,Account>([select Id,Name,ShippingAddress,BillingAddress
         ,Language__c
         ,HR_Generalist__c,IsParent__c,IsChild__c
         ,ShippingState, BillingState, NumberOfEmployees
         ,SalesParent__c, SalesParent__r.Id, SalesParent__r.Name
         ,SalesParent__r.HR_Generalist__c
         ,SalesParent__r.HR_Generalist__r.User_Lookup__r.ManagerId
         ,SalesParent__r.HR_Generalist__r.User_Lookup__r.Manager.Name
     from Account where Id in :accountIds]);
     List<Account> acctUpdates = new List<Account>();
     List<OpportunityTeamMember> otmHRG_and_Manager = new List<OpportunityTeamMember>();

         for(Account acct:acctsMap.values()){
             HRG_Assignment__c hao= hrgMap.get(acct.Id);
             //Todo grab opp and change new boolean to false if true
             Opportunity updatedOpp = new Opportunity(id= hao.Opportunity__c,Assign_HRG__c = false);
             upsert updatedOpp;
             Contact hrpCtct = hrpContactMap.get(hao.SelectedHRP__c);
             Contact manCtct= managerMap.get(hao.Manager__c);
             System.debug('Found HRP Contact with User Helper: '+hrpCtct);
             System.debug('Found Manager Contact with User Helper: '+manCtct);

             acct.HR_Generalist__c = hao.SelectedHRP__c;
             acct.HR_Manager__c = manCtct.Id;
             //remove old opp team members
             
             
             
             OpportunityTeamMember otmMan = new OpportunityTeamMember(UserId = hao.Manager__c, OpportunityId = hao.Opportunity__c,TeamMemberRole= 'PHRS HR Manager');
             otmHRG_and_Manager.add(otmMan);
             System.debug('otmMan: '+otmMan);
             OpportunityTeamMember otmHRG = new OpportunityTeamMember(UserId = hrpCtct.User_Lookup__c, OpportunityId = hao.Opportunity__c,TeamMemberRole= 'PHRS HR Generalist');
             otmHRG_and_Manager.add(otmHRG);
             
             System.debug('otmHRG: '+otmHRG);

             acctUpdates.add(acct);
         }
         insert otmHRG_and_Manager;

         update acctUpdates;

         // find the account associated 
         // populate account with HRG selected on HRGeneralist__c on account with HRG_Assignment__r.HRP... (contact record)
      }

     }
     if(isAfter && recs[0].getSObjectType() == HRG_Assignment__c.sObjectType){
        Set<Id> accountIds = new Set<Id>();
        Map<Id,HRG_Assignment__c> hrgMap = new Map<Id,HRG_Assignment__c>();
        HRG_Assignment__c[] hrgUpdates = new HRG_Assignment__c[]{}; 
        Assignment_Groups__c[] groupMemberUpdates = new Assignment_Groups__c[]{}; 
        if(oldMap!=null){
            for(HRG_Assignment__c hao: (HRG_Assignment__c[]) recs){
                System.debug('old Hao: '+oldMap.get(hao.Id));
                HRG_Assignment__c oldHao = (oldMap != null ? (HRG_Assignment__c) oldMap.get(hao.Id) : null);
                System.debug('oldHao.OverrideHRGUser: '+oldHao.Override_HRG_User__c+'hao.OverrideHRGUser: '+hao.Override_HRG_User__c +'hao.Status__c: '+hao.Status__c);
                if((oldHao.Override_HRG_User__c == null && hao.Override_HRG_User__c!= null && hao.Status__c=='Manager Override')){
                    System.debug('MANAGER OVERRIDE Section');
                    Contact hrp_ctct = new UserHelper().getContactById(hao.Override_HRG_User__c);
                    User hrp_User = new UserHelper().getUserById(hrp_ctct.User_Lookup__c);
                    User hrp_man = new UserHelper().getUserById(hrp_User.ManagerId);
                    System.debug('HRG User: '+hao.Override_HRG_User__c+'HRG Manager: '+hrp_man);
                    // find the queue 
                    String queueName = hao.ProcessNotes__c.substringAfter('matchedAssign=').trim();
                    System.debug('queueName: '+queueName);
                    //Grab all the assignment groups and use all the group members to update for all the 
                    List<Assignment_Group_Name__c> agroups = [Select Id,Name from Assignment_Group_Name__c where Name like 'HRGAUTO%'];
                    System.debug(agroups);
                    Map<Id,Assignment_Group_Name__c> ags = new Map<Id,Assignment_Group_Name__c>(agroups); 
                    Set<Id> agIds = ags.keyset();
                    List<Assignment_Group_Queues__c> agQueues = [Select Id, Name,QueueId__c,Assignment_Group_Name__c from Assignment_Group_Queues__c where Assignment_Group_Name__c in :agIds];
                    System.debug('agQueues: '+agQueues);
                    System.debug('Hao.SelectedHRP__c :'+hao.SelectedHRP__c);
                    Contact selectedHRPContact = [Select Id,Name,User_Lookup__c from Contact where Id = :hrp_ctct.Id limit 1];
                    User selectedHRP = [Select Id,Name from User where Id = :selectedHRPContact.User_Lookup__c];
                    //System.debug('selectedHRP: '+selectedHRP);
                    List<Assignment_Groups__c> groupMembers = [Select Id,Name,User__c,User__r.Name,Group_Name__c from Assignment_Groups__c where Group_Name__c in :agIds AND User__c=:selectedHRP.Id];
                    System.debug('groupMembers: '+groupMembers);
                    for(Assignment_Groups__c groupMember:groupMembers){
                        groupMember.Last_Assignment__c = datetime.now();
                        Assignment_Groups__c updatedGroupMember = new Assignment_Groups__c(Id = groupMember.Id,Last_Assignment__c= datetime.now());
                        groupMemberUpdates.add(updatedGroupMember);
                    }
                    

                    //find the group member(assignmentGroup__c)
                    // modify the Last_Assignment__c to be Now
                    // update the Group Member
                    // remove the group member from the queue 
                    // add the group member back to the queue 
                    //

                    HRG_Assignment__c tempHao = new HRG_Assignment__c(Id = hao.Id,SelectedHRP__c = hao.Override_HRG_User__c,Manager__c = hrp_User.ManagerId);
                    hrgUpdates.add(tempHao);
                }
            }
            if(!hrgUpdates.IsEmpty()){
                update hrgUpdates;
    
            }
            if(!groupMemberUpdates.IsEmpty()){
                update groupMemberUpdates;
            }
            
        }
        

    
       
    }

 } 
 public static void deleteOldOTMS(Id oppId){
    
     List<OpportunityTeamMember> oldOTMs = [Select Id, Name from OpportunityTeamMember where OpportunityId = :oppId and TeamMemberRole in('PHRS HR Manager','PHRS HR Generalist')];
     if(!oldOTMs.IsEmpty()){
        delete oldOTMs;

     }
 }
}// class HRGAutoAssignment