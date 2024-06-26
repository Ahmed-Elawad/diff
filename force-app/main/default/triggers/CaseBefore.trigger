/* 
 *  A trigger to handle before update/insert operations.
 *   
 * History
 * -------
 * 12/10/2012 Cindy Freeman     created 
 * 04/16/2015 Cindy Freeman     modified to resend case to SNow if check Manager Escalation needed or any Snow fields changed (11/19/15 commented out to move HRS Discrepency to production)
 * 11/04/2015 Lynn Michels      add code for HRS Discrepency Record Type
 * 06/16/2016 Justin Stouffer   Updated to include limits for ESR
 * 08/08/2016 Jacob Hinds       Adding in action__c check for ESR.
   09/19/2016 Dan Carmen        Add call to SRRTransitionHelper
   11/27/2016 Cindy Freeman     changed query for mrktoUser to use UserHelper variable
   06/16/2017 Jermaine Stukes   Added Sales to Service
   11/21/2017 Lynn Michels      Added functionality to check if owner changes on a HRS Termination Transfer Case
   11/30/2017 Jacob Hinds       Commenting out esr code
   03/05/2018 Jermaine Stukes	Sales to Service Update
   04/20/2018 Dan Carmen        Recursion check by record id
   08/27/2018 Jermaine Stukes	Update S2S recordtype to use a label rather than hardcode
   09/04/2018 Jermaine Stukes	S2S Update
   04/21/2020 Manmeet Vaseer	SFDC-3072 (US4) Updated Sales Rep information on Case (Service Support PEO Finance Record type) from Sales Rep in the Prospect Client Team Section with an PEO-ASO Partner Role.
   08/14/2020 Jake Hinds		Adding Resubmit Checkbox for S2S
   12/04/2023 Carrie Marciano	moved code from caseRoundRobin trigger here to control when the round robin code was called
   12/20/2023 Carrie Marciano	had to change the recursion check so that when queue is assigned by assignment rules the trigger allows that to flow thru the code and not skip the trigger
   04/30/2024 Omar Hernandez	Adding logic to close Milestones * To be reviewed by Carrie
*/
 

trigger CaseBefore on Case (before insert, before update) {

// needed different recursion check because case assignment rules fire after after triggers, we still need an owner update to come into the trigger for round robin    
//   if (TriggerMethods.didTriggerRun('CaseBefore', Trigger.isBefore, Trigger.isAfter)) {
//   if (!TriggerMethods.runTrigger(ObjectHelper.OBJECT_CASE, Trigger.isInsert, Trigger.isUpdate, Trigger.isBefore, Trigger.isAfter, Trigger.new)) {
//      return;
//   }

    SObject[] recs = TriggerMethods.checkRecs('CaseBefore', Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, null, Schema.SObjectType.Case.fieldSets.CaseBeforeFlds);
    if (recs == null || recs.isEmpty()) {
        System.debug('CaseBefore exiting because of recursion2');
        return;
    }
    
    List<Case> cases = new List<Case>();
    List<Case> esrCases = new List<Case>();
    List<Case> s2sNewCases = new List<Case>();
    List<Case> s2sUpdateCases = new List<Case>();
    //List<Case> s2sResubmitCases = new List<Case>();
    List<Case> ssPeoFinanceCases = new List<Case>();
    Case[] rrCases = new Case[]{};
    Map<Id,Id> queueIds = new Map<Id,Id>();   //Trigger index --> Queue ID    
    
    Schema.RecordTypeInfo HRSDiscrepencyRT = RecordTypeHelper.getRecordType('HRS 4S LDPS Discrepancy', 'Case');   
    Schema.RecordTypeInfo caseDNCrt = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case');
    Schema.RecordTypeInfo caseESRrt = RecordTypeHelper.getRecordType('Service Support ESR Case', 'Case');
    Schema.RecordTypeInfo caseS2S = RecordTypeHelper.getRecordType(Label.RT_Case_S2S, 'Case');
    Schema.RecordTypeInfo caseSSPeoFinance = RecordTypeHelper.getRecordType('Service Support PEO Finance', 'Case');        
    Id caseTermTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HRS Termination Transfer Case Record Type').getRecordTypeId(); 
    Map<Id, Case> caseOwnerMap = new Map<Id, Case>();   
    
    // get the prefix of the Queue (Group) object
    Schema.DescribeSObjectResult dor = Group.sObjectType.getDescribe();
    String queuePrefix = dor.getKeyPrefix();
    System.debug('queuePrefix='+queuePrefix);
    
    User mrktoUser = [Select Id, Name, ProfileId from User where Name = :UserHelper.MARKETO];

    TriggerMethods.checkBeforeLoop('CaseBefore', Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter);
   
    for (Case kase : Trigger.new){   
      	Case oldRec = (Trigger.isUpdate ? Trigger.oldMap.get(kase.Id) : null);
      	SRRTransitionHelper.checkBeforeActions(kase,oldRec);      
      	TriggerMethods.checkInLoop('CaseBefore', kase, oldRec, Trigger.isBefore, Trigger.isAfter);

        Boolean isDNCcase = DNCHelper.isDNCsubject(kase.subject);
        if (Trigger.isBefore){
            if(Trigger.isInsert){
                if (kase.RecordTypeId == HRSDiscrepencyRT.getRecordTypeId()) {
                    cases.add(kase); 
                }
                else if (kase.RecordTypeId == caseS2S.getRecordTypeId()){
                    s2sNewCases.add(kase); 
                }
                else if (kase.RecordTypeId == caseSSPeoFinance.getRecordTypeId()){
                    ssPeoFinanceCases.add(kase); 
                }                
                else if(caseESRrt != NULL && kase.RecordTypeId == caseESRrt.getRecordTypeId() && kase.Client_Assigned_Date__c != NULL && kase.Action__c =='Transferred to Outbound Service'){
                    esrCases.add(kase);                    
                }
                
                String ownerId = kase.OwnerId;
                system.debug('CaseBefore isInsert ownerId: '+ownerId); 
                // make sure this is a queue
                if (ownerId.startsWith(queuePrefix)) {
                   queueIds.put(kase.OwnerId, kase.OwnerId);
                   rrCases.add(kase);
                } 
                               
            }//end if isInsert
            else if (Trigger.isUpdate){
                //if the owner changes on a HRS Termination Transfer Case Record Type Case.....
                if(kase.RecordTypeId == caseTermTransfer && kase.ParentId == null && oldRec.OwnerId != kase.OwnerId){
                    caseOwnerMap.put(kase.id, kase);
                }//end if HRS Termination Transfer case owner change
                
                if (kase.RecordTypeId == caseS2S.getRecordTypeId() && 
                    ((oldRec.Product__c != kase.Product__c) || (kase.Product__c == 'Payroll' && oldRec.OwnerId != kase.OwnerId) || (kase.Resubmit_Case__c))){
                    s2sUpdateCases.add(kase); 
                    kase.Resubmit_Case__c = false;
                }
                
                // only proceed if owner changes 
                system.debug('CaseBefore isUpdate kase.OwnerId: '+kase.OwnerId+' old OwnerId: '+Trigger.oldMap.get(kase.id).OwnerId);  
         		if (kase.OwnerId <> Trigger.oldMap.get(kase.id).OwnerId) {           	
                    String ownerId = kase.OwnerId;
                    // make sure this is a queue
                    if (ownerId.startsWith(queuePrefix)) {
                       queueIds.put(kase.OwnerId, kase.OwnerId);
                       rrCases.add(kase);
                    }
         		} // if (cs.OwnerId
            }//end if isUpdate
        }//end if isBefore   
        
        if (kase.RecordTypeId == caseDNCrt.getRecordTypeId() && kase.IsClosed == false && isDNCcase){   
        	if (kase.ownerId == mrktoUser.Id){
                kase.Status = 'Completed';  
            }
            if (kase.subject == 'Do Not Call Request - Contact' || kase.subject == 'Email Opt-Out Request'){   
                kase.Status = 'Closed'; 
            }
        }
        
        if (!cases.isEmpty()){ 
            CaseAccountManager.SetAccountManager(cases);
        }  
        
    }//end for

   TriggerMethods.checkOutsideLoop('CaseBefore',Trigger.isBefore, Trigger.isAfter);

    if(!s2sNewCases.isEmpty()){
        CaseSalesEscalationProcessing.RouteToQueue(s2sNewCases);
        //CaseSalesEscalationProcessing.updateCase(s2sUpdateCases);
    }
    if(!s2sUpdateCases.isEmpty()){
        CaseSalesEscalationProcessing.updateCase(s2sUpdateCases,true);
    }
    if(!caseOwnerMap.isEmpty()){     	
        CasesInSync.checkField(caseOwnerMap); 
   }

   if(!ssPeoFinanceCases.isEmpty()){ 
       System.debug('Service Support PEO Finance cases');
       CaseServiceSupportPEO.updateCases(ssPeoFinanceCases);
   }
   
   if (!queueIds.isEmpty()) {
      RoundRobin.prepareCaseRoundRobin(rrCases, queueIds.values());
   } 
   //OHM Salesforce SOW - Need to verify with Carrie where to implement this
   if (Trigger.isUpdate){
    MilestoneUtils.completeMPSCMilestones(Trigger.new);
   } 
} // CaseBefore