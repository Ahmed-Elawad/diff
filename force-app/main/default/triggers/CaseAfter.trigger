/* 
   Check the Case record type and subject, if case is not closed process pass case to CaseDNCHelper
 *   
 * History
 * -------
 * 11/22/2012 Cindy Freeman     created
 * 03/15/2013 Cindy Freeman     modified to send all cases to CreateRelatedObjects class
 * 09/03/2013 Dan Carmen        Added case for the Service Premier record type   
 * 11/01/2013 Cindy Freeman     modified to send new cases and updated cases to Service Now class
 * 07/15/2014 Carrie Marciano   added code for MMS CSR chatter post notification upon case create with an MMS CSR name populated
 * 01/27/2016 Lynn Michels      added code to filter out Completed, Adoption Agreement Review Cases 
 * 05/26/2016 Lynn Michels      if case status changes for MPSC Client Audit or MPSC Employee Audit cases
 * 11/01/2016 Lynn Michels      updated criteria for chatter post on Adoption Review Cases.
 * 02/12/2017 Jermaine Stukes   Updated DNC process to use new DNCHelper class.
 * 04/06/2017 Jermaine Stukes   Added code for Sales Escalation
 * 07/11/2017 Lynn Michels      Added for MPSC Onboarding Core Payroll cases to create MPSC Cases
 * 08/01/2017 Jermaine Stukes   Updated Sales Escalation logic
 * 08/07/2017 Cindy Freeman     added call to TriggerMethods (for inserted cases to send SF2SF)
 * 08/24/2017 Cindy Freeman     added temporary hack to check instance to get proper case record type name
 * 10/23/2017 Lynn Michels      keep case status and owners in sync for HRS Termination/Transfer cases
 * 03/05/2018 Jermaine Stukes   Commenting out S2S code
   04/20/2018 Dan Carmen        Recursion check by record id
   05/16/2018 Jake Hinds        Adding Case/Idea sync
   06/13/2018 Jermaine Stukes   Removed S2S code Logic (Already commented out)
   06/29/2018 Lynn Michels      Updated to use custom setting value for MPSC Onboarding Core Payroll Cases 
   10/17/2018 Jacob Hinds       Moving dnc check into insert loop, accept case not case id
   04/24/2018 Jermaine Stukes   Added Money Manager update logic
   08/05/2019 Jacob Hinds       Adding onboardingCheckStatus for accounts, moving CaseCreateReference Trigger into this class
   12/24/2019 Carrie Marciano   Added after delete to trigger, along with code to handle when cases are deleted
   07/24/2020 Jacob Hinds       Removing onboardingCheckStatus, after delete
   09/08/2020 Jacob Hinds       Reverting above change
   11/23/2020 Brandon Vidro     added call to TriggerMethods (for updated cases to send SF2SF)
   04/01/2024 Carrie Marciano   removed references to MPSC Employee Audit
 */
 
trigger CaseAfter on Case (after insert, after update, after delete) {
   
   //if (TriggerMethods.didTriggerRun('CaseAfter', Trigger.isBefore, Trigger.isAfter)) {
   if (!TriggerMethods.runTrigger(ObjectHelper.OBJECT_CASE, Trigger.isInsert, Trigger.isUpdate, Trigger.isBefore, Trigger.isAfter, Trigger.new)) {
      return;
   }

    Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
    // edit next line removing old record type name
    String[] recordTypeNames = new String[]{ReferenceHRGMethods.RT_PREMIER_SURVEY,'Sales Support Cases Record Type','Service Support 401k MM Change Case Record','Service Support MMS Case', 'Adoption Agreement Review', 'Sales to Service Communication Case', 'Service Support Sales Ops Case'};
    RecordTypeHelper.getRecordTypesMap(new String[]{'Case'}, recordTypeNames, null, byName);
    Id caseMMSSupportRtId = byName.get('Service Support MMS Case').getRecordTypeId();
    Id caseMoneyManagerId = byName.get('Service Support 401k MM Change Case Record').getRecordTypeId();
    Id caseDNCrtId = byName.get('Sales Support Cases Record Type').getRecordTypeId();
    Id caseAdoptAgreeReview = byName.get('Adoption Agreement Review').getRecordTypeId();
    Id caseServicePremierRtId = byName.get(ReferenceHRGMethods.RT_PREMIER_SURVEY).getRecordTypeId();
    Id caseMPSCClientAudit = Schema.SObjectType.Case.getRecordTypeInfosByName().get('MPSC Client Audit').getRecordTypeId();
    Id caseTermTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HRS Termination Transfer Case Record Type').getRecordTypeId(); 
    
    Id caseOnboardingMPSCCorePayroll = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Onboarding MPSC Core Payroll Case').getRecordTypeId();

    Map<Id,Id> excludeRefIdMap = new Map<Id,Id>();

    if (byName.containsKey('Service Onboarding HRO Case Record Type')) {
      Id recordTypeId = byName.get('Service Onboarding HRO Case Record Type').getRecordTypeId();
      excludeRefIdMap.put(recordTypeId,recordTypeId );
   }

   
    //get account ids from all cases
    //Set<Id> pcIdSet = new Set<Id>();
    //for (Case kase: trigger.new){
    //    pcIdSet.add(kase.AccountId);
    //}
       
    List<Case> casesDNC = new List<Case>();
    List<Id> casesServiceNow = new List<Id>();
    List<Case> casesMMSSupport = new List<Case>();

    // the list of account ids that have a case for new client survey alert created.
    Map<Id,Id> acctCaseIdMapSurveyAlert = new Map<Id,Id>();
    List<Id> closedAdoptAgreementCases = new List<Id>();
    List<Id> mpscCaseIds = new List<Id>();
    List<Id> salesEscList = new List<Id>();
    List<Id> termTransferCaseIds = new List<Id>();
    List<Case> moneyManagerCaseList = new List<Case>();
    //Map<Id,Id> ideaIdByCaseIdMap = new Map<Id,Id>();
    //Set<Id> mpscOnboardingCaseIds = new Set<Id>();
    Map<Id, Case> IdMPSCOnboardingCaseMap = new Map<id,Case>();
    Set<Id> accountsToCheckOnboardingStatus = new Set<Id>();
    Id[] caseRefIds = new Id[]{};
    TriggerMethods.checkBeforeLoop('CaseAfter', Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter);
    
    if (Trigger.isDelete) {
        for (Case dkase : Trigger.old){
           accountsToCheckOnboardingStatus.add(dkase.AccountId);
           system.debug('CaseAfter Trigger.isDelete accountsToCheckOnboardingStatus'+accountsToCheckOnboardingStatus);
        }
    } else {
    
        for (Case kase : Trigger.new){  
            if (Trigger.isInsert) {  
                if (kase.RecordTypeId == caseDNCrtId && kase.IsClosed == false && DNCHelper.isDNCsubject(kase.subject))            
                {   casesDNC.add(kase);      }
               // System.debug('**CLM CaseAfter Trigger inside isInsert **');
                if (kase.RecordTypeId == caseServicePremierRtId && kase.Origin == ReferenceHRGMethods.SURVEY_CASE_ORIGIN && kase.AccountId != null) {
                    acctCaseIdMapSurveyAlert.put(kase.AccountId,kase.Id);
                }
                //System.debug('**CLM CaseAfter Trigger inside isInsert after ServicePremier and before MMS Support rt check. caseMMSSupportRtId: ' + caseMMSSupportRtId + ' kase.RecordTypeId: ' + kase.RecordTypeId + ' kase MMS_CSR__c: ' + kase.MMS_CSR__c);
                //check to see if MMS Support case and MMS CSR is not blank
                if(kase.RecordTypeId == caseMMSSupportRtId && kase.MMS_CSR__c != null && ChatterMentionPost.postedOnce()){
                    casesMMSSupport.add(kase);
                    System.debug('**CLM CaseAfter Trigger isInsert MMS Support case with MMS CSR **');
                }
                /*
                if(kase.Idea__c!=null){
                    ideaIdByCaseIdMap.put(kase.Id,kase.Idea__c);
                } */
                if ((kase.ParentId == null) ||
                      (kase.ParentId != null && !excludeRefIdMap.containsKey(kase.recordTypeId))) {
                     caseRefIds.add(kase.Id);
                } // if (newCase
                
                if(!accountsToCheckOnboardingStatus.contains(kase.AccountId)){
                    accountsToCheckOnboardingStatus.add(kase.AccountId);
                }
                
                TriggerMethods.checkInLoop('CaseAfter', kase, null, Trigger.isBefore, Trigger.isAfter);
                
            } else if (Trigger.isUpdate) {
            
                //check to see if MMS Support case and MMS CSR is not blank and not changed
                System.debug('**CLM CaseAfter Trigger inside isUpdate **');
               Case oldCase = (Case)Trigger.oldMap.get(kase.id);       
               // System.debug('**CLM CaseAfter Trigger inside isUpdate after ServicePremier and before MMS Support rt check. caseMMSSupportRtId: ' + caseMMSSupportRtId + ' kase.RecordTypeId: ' + kase.RecordTypeId + ' kase MMS_CSR__c: ' + kase.MMS_CSR__c);
                if(kase.RecordTypeId == caseMMSSupportRtId && kase.MMS_CSR__c != null && ChatterMentionPost.postedOnce()){
                    casesMMSSupport.add(kase);
                    System.debug('**CLM CaseAfter Trigger isUpdate MMS Support case with MMS CSR **');
                }
                //LM - TEMPORARY CODE UNTIL NEXT PHASE - keep child case statuses and owners in sync with parent case
                if(kase.RecordTypeId == caseTermTransfer && kase.ParentId == null && (oldCase.Status != kase.Status || oldCase.OwnerId != kase.OwnerId))
                {
                    termTransferCaseIds.add(kase.id);
                    system.debug('LM caseAfter changed');
                }
                if(oldCase.RecordTypeId != caseMoneyManagerId && kase.RecordTypeId == caseMoneyManagerId){
                    moneyManagerCaseList.add(kase);
                }
                //Completed, Adoption Agreement Review case
                if(kase.RecordTypeId == caseAdoptAgreeReview && oldCase.Status != 'Completed' && kase.Status == 'Completed')
                {
                    closedAdoptAgreementCases.add(kase.id);
                }
                //If Status Changes on MPSC Client Audit or MPSC Employee Audit cases.
                if(kase.RecordTypeID == caseMPSCClientAudit && kase.Status != oldCase.Status)
                {
                    mpscCaseIds.add(kase.id);
                }
                if(kase.Status != oldCase.Status && kase.isClosed && !accountsToCheckOnboardingStatus.contains(kase.AccountId)){
                    accountsToCheckOnboardingStatus.add(kase.AccountId);
                    system.debug('CaseAfter Trigger.isUpdate accountsToCheckOnboardingStatus'+accountsToCheckOnboardingStatus);
                }
                
                //LM added to ensure only one MPSC Transfer Case is created   
               if (kase.RecordTypeId == caseOnboardingMPSCCorePayroll && kase.Current_Step__c != oldCase.Current_Step__c){
               //get the status that will close this case from the custom settings
                Client_Overview_Configuration__c coc = Client_Overview_Configuration__c.getValues('Core Advance Payroll');
                String completedStatus = coc.Completed_Onboarding_Status__c;
                    if (completedStatus.contains(kase.Current_Step__c))
                    {
                        IdMPSCOnboardingCaseMap.put(kase.Id, kase);         
                    }// end if completedStatus
                }//end if caseOnboardingMPSCCorePayroll  
                TriggerMethods.checkInLoop('CaseAfter', kase, oldCase, Trigger.isBefore, Trigger.isAfter);
            }//end if update
            casesServiceNow.add(kase.Id);
            
        } // for
    } //end else if from Trigger.isDelete
    
    /*
    if(!ideaIdByCaseIdMap.isEmpty()){
        IdeaMethods.processIdeaCaseLink(ideaIdByCaseIdMap);
    }
    */
    //create chatter post on Ref Core Payroll if case status changes
    if(!mpscCaseIds.isEmpty())
   {
        RefCorePayChatterPost.collectInfoForChatterPost(mpscCaseIds);
   }
   if(!termTransferCaseIds.isEmpty()){ 
        CasesInSync.casesInSync(termTransferCaseIds); 
   }   
   if(!closedAdoptAgreementCases.isEmpty())
   {
        caseChatterPost.collectInfoForChatterPost(closedAdoptAgreementCases);
   }
    
   if (casesDNC.size() > 0)      
   {   DNCHelper.ProcessDNCCases(casesDNC); }

   if (!acctCaseIdMapSurveyAlert.isEmpty())
   {   ReferenceHRGMethods.checkPremierSurveyDate(acctCaseIdMapSurveyAlert);}
   
   // send all cases to update Service Now fields
   if (casesServiceNow.size() > 0)
   {   CaseServiceNow.serviceNowUpdates(casesServiceNow);  }

   
  /* if (!casesMMSSupport.isEmpty()){   
        System.debug('**CLM casesMMSSupport is not empty **');
        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> acctIdSet = new Set<Id>();
        for (Case newCase: casesMMSSupport){
           caseIdSet.add(newCase.Id);
           acctIdSet.add(newCase.accountID);
        }
        Map<Id,Account> allAccts = new Map<Id,Account>([select Id, Name, 
                                 (select Id, OwnerID, Owner.Name from Cases where id in: caseIDSet)from Account where Id in :AcctIDSet]);
        if(!allAccts.isEmpty()){
            Map<Id,Case> allCases = new Map<Id,Case>();
            for(Account a : allAccts.values()){
                for (Case c : a.cases){
                    if(!allCases.keyset().contains(c.id)){
                        allCases.put(c.id,c);
                    }
                }
            }
            for(Case MMS : casesMMSSupport){
                if (allCases.get(MMS.ID).owner.name != null){
                    System.debug('**CLM MMS.Account = pc.Id and MMS.Status = ' + MMS.Status);
                    System.debug('**CLM CaseAfter Trigger before call ChatterMentionPost New **');
                    String chatterText = ' A support case with the Status = ' + MMS.Status + ' and MMS Category 1 = ' + MMS.MMS_Category_1__c  + ' for ' + allAccts.get(MMS.AccountId).Name + ' is being worked in Salesforce by ' + allCases.get(MMS.id).owner.Name + '.  Please review and follow up as needed. ';
                    chatterMentionPost.createChatterMentionPost(MMS.id,new Id[]{MMS.MMS_CSR__c},chatterText);
                    System.debug('**CLM CaseAfter Trigger after call ChatterMentionPost New **');
                }
                else
                {
                    System.debug('**CLM CaseAfter Trigger before call ChatterMentionPost New **');
                    String chatterText = ' A support case with the Status = ' + MMS.Status + ' and MMS Category 1 = ' + MMS.MMS_Category_1__c  + ' for ' + allAccts.get(MMS.AccountId).Name + ' is being worked in Salesforce.  Please review and follow up as needed. ';
                    chatterMentionPost.createChatterMentionPost(MMS.id,new Id[]{MMS.MMS_CSR__c},chatterText);
                    System.debug('**CLM CaseAfter Trigger after call ChatterMentionPost New **'); 
                } 
            }
        }
   }*/

   if (Trigger.isInsert)
   {   CreateRelatedObjects2.processSObjects('Case', Trigger.new); }
   if((Trigger.isInsert || Trigger.isUpdate) && Trigger.isAfter)
   {   new CreateCovidRequests().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);}
    if(!moneyManagerCaseList.isEmpty()){
        CreateRelatedObjects2.processSObjects('Case', moneyManagerCaseList); 
    }
   if (!caseRefIds.isEmpty()) {
      system.debug('caseAfter calling CaseCreateReference'+caseRefIds);
      CaseCreateReference.createReference(caseRefIds);
      caseRefIds.clear();
   } // if (!caseIds
   /*
   if(!IdMPSCOnboardingCaseMap.isEmpty()){
       CreateRelatedCase.checkForAlreadyExistingCases(IdMPSCOnboardingCaseMap);   
   }
   */   
   if(!accountsToCheckOnboardingStatus.isEmpty()){
       AccountOnboardingStatus.checkAccountOnboardingStatus(accountsToCheckOnboardingStatus);
   }
    
   TriggerMethods.checkOutsideLoop('CaseAfter',Trigger.isBefore, Trigger.isAfter);
    
} // CaseAfter