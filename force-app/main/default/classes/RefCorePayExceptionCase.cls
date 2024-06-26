/*
 *  This class will create a case from the Reference Core Payroll MPSC Exception.  This
 *  was done so that the sales reps can fill out required fields on the Reference Core Payroll
 *  from the Opportunity's MPSC Exception Quick Action.  Called from RefCorePayBefore.trigger.
 *
 *  History
 * ---------
 *  12/14/2016  Jacob Hinds Created
 *  03/13/2017  Jacob Hinds Adding approval process
 * 3/20/2024  Carrie Marciano    CanBeDeleted old MPSC tech debt
 *
*/
public with sharing class RefCorePayExceptionCase {
    public RefCorePayExceptionCase(){}
   /* 
    public static void createCase(Reference_Core_Payroll__c[] refs){
        Case[] cases = new Case[]{};
        Id exceptionId = RecordTypeHelper.getRecordType('MPSC Exception','Case').getRecordTypeId();
        //Profile runningProfile = [SELECT Name From Profile WHERE Id=:UserInfo.getProfileId() LIMIT 1];
        Group exceptionQueue = [SELECT Id FROM Group WHERE Name='MPSC Exception Team Queue' AND Type = 'Queue' LIMIT 1];
        User runningUser = [SELECT Id,FirstName,LastName,Profile.Name,ManagerId,Manager.ManagerId,Manager.Profile.Name FROM User WHERE Id=:UserInfo.getUserId()];
        
        Id caseOwnerId;
        Boolean dsmApproval = false;
        Id dsmId;
        Id zoneManagerId;
        //if user who created the record is a sales rep, set owner to DSM.  Zone Manager is Manager's Manager
        if(!runningUser.Profile.Name.contains('Core Manager') && !runningUser.Profile.Name.contains('MMS Manager') && 
            (runningUser.Manager.Profile.Name.contains('Core Manager')||runningUser.Manager.Profile.Name.contains('MMS Manager'))){   
            system.debug('IAMA Rep or DSA');         
            caseOwnerId = runningUser.Id;
            dsmId = runningUser.ManagerId;
            zoneManagerId = runningUser.Manager.ManagerId;
        }
        //if user who created the record is a dsm, set owner to exception queue. Zone Manager is current user's Manager
        else{
            system.debug('IAMA DSM');
            caseOwnerId = exceptionQueue.Id;
            dsmApproval = true;
            zoneManagerId = runningUser.ManagerId;
            dsmId = runningUser.Id;
        }
        
        Map<Id,Opportunity> opptyMap = new Map<Id,Opportunity>();
        List<Id> opptyIds = new List<Id>();

        //get opportunity info, need accountId from oppty to put on to the case.
        for(Reference_Core_Payroll__c ref:refs){
            if(ref.Opportunity_Lookup__c != null){
                opptyIds.add(ref.Opportunity_Lookup__c);
            }
        }
        if(!opptyIds.isEmpty()){
            Opportunity[] opptys= [SELECT Id,AccountId FROM Opportunity WHERE Id IN:opptyIds];  
            for(Opportunity o:opptys){
                opptyMap.put(o.Id,o);
            }
        }
        
        Map<Id,Case>refCaseMap = new Map<Id,Case>();
        //create case
        for(Reference_Core_Payroll__c ref:refs){
            Id accountId;
            if(opptyMap!=null && opptyMap.containsKey(ref.Opportunity_Lookup__c)){
                accountId = opptyMap.get(ref.Opportunity_Lookup__c).AccountId;
            } 
            Case c = new Case(RecordTypeId=exceptionId,OwnerId=caseOwnerId,Opportunity__c = ref.Opportunity_Lookup__c,AccountId=accountId,Status='New',Subject='MPSC Exception');
            refCaseMap.put(ref.Id,c);
        }
        if(!refCaseMap.isEmpty()){
            insert refCaseMap.values();
        }
        
        //update rcp.  Coming from before trigger so no update call.
        for(Reference_Core_Payroll__c ref:refs){
            Case c = refCaseMap.get(ref.Id);
            ref.Case_Lookup__c = c.Id;
            ref.DSM__c = dsmId;
            ref.Zone_Manager__c = zoneManagerId;
            ref.OwnerId = caseOwnerId;
            if(dsmApproval){
                ref.DSM_Approval__c = 'Yes';
            }/*
            else{
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Submitting for Approval on behalf of '+runningUser.FirstName+' '+runningUser.LastName);
                req.setObjectId(ref.Id);
                req.setProcessDefinitionNameOrId('MPSC_Exception_Approval');
                req.setSkipEntryCriteria(true);
                req.setNextApproverIds(new Id[]{zoneManagerId});
                Approval.ProcessResult result = Approval.process(req);
            }
        }
    }
    */
}