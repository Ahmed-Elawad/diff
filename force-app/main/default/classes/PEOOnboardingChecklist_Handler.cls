/*
 * 07/09/2021 Matthew Fritschi  Update to allow assignment of records to specific Queues/Users, and create sharing records for Sales Reps.
 * 07/16/2021 Ahmed Elawad      Uodate to share documents with reps + analysts 
 * 07/27/2021 Matt Fritschi     Update to the Email being sent when discrepancies are logged: Now uses an org-wide email address.
 * 07/29/2021 Jake Hinds        Update to remove shares for document, now controlled through master-detail
 * 08/01/2021 Jidesh Athippatta Update to check the status of each document as Required/Optional
 * 08/12/2021 Jake Hinds        Update to set reference peo medical uw lookup, code cleanup
 * 08/30/2021 Matt Fritschi     Rearranged code into methods to clean up beforeUpdateHandler
 * 09/07/2021 Jake Hinds        Update to sales rep chatter post wording
 * 11/02/2021 Jidesh Athippatta Added the checkMedStatus to send chatter notifications when Medical_Pre_Qualifier_Status__c is Approved
 * 12/13/2021 Jake Hinds        Overhaul how round robin, owner sync, owner change notifications work.
 * 12/14/2021 Jidesh Athippatta updated the beforeUpdateHandler method to include salesnotes in chatter notifications
 * 12/15/2021 Ahmed Elawad      Added create doc logic to updateDocReqdStatus SFDC-10012
 * 12/21/2021 Jake Hinds        Consolidating discrepancy email send, changing to use email template
 * 01/06/2021 Jake Hinds        moving sa notification into owner change sync method
 * 02/07/2022 Jake Hinds		Removing experience
 * 03/05/2022 Ahmed Elawad		SFDC-11426- add discrepancy notest to email send
 * 05/24/2022  Josh Cartwright  INC2995038 added criteria to changing sales analyst 
 * 07/13/2022 Jidesh            Updated beforeUpdateHandler to include call for BLSDataHelper when Sync with BLS is true
 * 09/08/2022 Josh Cartwright   upated sendChecklistCurrentStepValueUpdate to check for null 
 * 09/22/2022 Josh Cartwright   updated sendChecklistCurrentStepValueUpdate to add null checks on fields received back from CS
 * 11/14/2022 Jidesh Athippatta Created sendHSFStatusUpdateChatter method and updated the beforeUpdateHandler method to include HSF_Submission_Status__c check 
 * 11/21/2022 Josh Cartwright updated code to handle inactive codes, we should not insert them, if we already have them, delete them 
 * 08/21/2023 Josh Cartwright 	updated logic that sets path type to evaluate WC and Med independently. 
 * 10/05/2023 Jidesh 			Updated beforeUpdateHandler to modify logic to set HSF_Census_Submit_Date__c 
 * 12/27/2023 Jidesh 			SFDC-24023 Updated beforeInsertHandler & beforeUpdateHandler to modify logic to set Oppty_Linked_to_Checklist_Date__c
 * 03/01/2024 Josh Cartwright   added logic to if statement to allow checklists to go through RR if there is a parent and client add on 

*/ 

public without sharing class PEOOnboardingChecklist_Handler {
    public static Map<Id,PEO_Onboarding_Checklist__c> medUWCreateMap = new Map<Id,PEO_Onboarding_Checklist__c>();
    public static Map<Id, User> repUsersMap = new Map<Id, User>();
    
    public static void beforeInsertHandler(List<PEO_Onboarding_Checklist__c> newMap){
        //Check and set if ISQ status is Not required or Not
        setISQnotRequired(newMap);
        //end
        Map<id,PEO_Onboarding_Checklist__c> checklistMapNew = new Map<id,PEO_Onboarding_Checklist__c>();
        Map<id,PEO_Onboarding_Checklist__c> checklistMapOld = new Map<id,PEO_Onboarding_Checklist__c>();
        updateDocReqdStatus(newMap, checklistMapNew, checklistMapOld);
            for(PEO_Onboarding_Checklist__c newRec : newMap){
                /*if(newRec.Parent_PEO_Checklist__c==null && newRec.Opportunity__c != null 
                   && newRec.Medical_Benefits_Underwriting_Requested__c == 'Yes' && newRec.Prospect_Client__c!=null 
                   && !medUWCreateMap.containsKey(newRec.Prospect_Client__c)){
                    medUWCreateMap.put(newRec.Opportunity__c,newRec);
                }*/
                System.debug('PEOOnboardingChecklist_Handler beforeInsertHandler Is_Medical_Underwriting_Requested__c:'+newRec.Is_Medical_Underwriting_Requested__c);
                if(newRec.Parent_PEO_Checklist__c==null && newRec.Opportunity__c != null 
                   && (newRec.Is_Medical_Underwriting_Requested__c == 'Currently have Medical, please quote'|| newRec.Is_Medical_Underwriting_Requested__c == 'Currently does not have Medical, please quote') 
                   && newRec.Prospect_Client__c!=null 
                   && !medUWCreateMap.containsKey(newRec.Prospect_Client__c)){
                       medUWCreateMap.put(newRec.Opportunity__c,newRec);
                   }
                if(newRec.Opportunity__c != null){
                    newRec.Oppty_Linked_to_Checklist_Date__c = System.now();
                }
            }
        System.debug('beforeInsertHandler medUWCreateMap:'+medUWCreateMap);
        if(!medUWCreateMap.isEmpty()){
            checkForMedUW(medUWCreateMap);
        }
    }
    
    public static void afterInsertHandler(Map<id,PEO_Onboarding_Checklist__c> oldMap ,Map<id,PEO_Onboarding_Checklist__c> newMap){
        Id[] parentChecklistsIds = new Id[]{};
        Boolean hasNBSCVerticalPermission = FeatureManagement.checkPermission('PEO_Getting_Started_NBSC_Vertical');
        Set<Id> setOppIds = new Set<Id>();
        for(PEO_Onboarding_Checklist__c newRec : newMap.values()){
            if(newRec.Opportunity__c != null){
                setOppIds.add(newRec.Opportunity__c);
            }
			
            if(newRec.Parent_PEO_Checklist__c !=null){
                //if a child checklist is added on, need to make sure the rep and everybody gets access
                parentChecklistsIds.add(newRec.Parent_PEO_Checklist__c);
            }
            //if the nbsc vertical rep creates the checklist, we need to be sure the sales rep gets a sharing record
            else if(hasNBSCVerticalPermission && newRec.Parent_PEO_Checklist__c == null){
                parentChecklistsIds.add(newRec.Id);
            }
        }
        if(setOppIds != null && setOppIds.size() > 0){
            	updateNewOpportyStageAfterUpdate(setOppIds);
        }
        if(parentChecklistsIds!=null && !parentChecklistsIds.isEmpty()){
            if (Test.isRunningTest() || System.isBatch() || System.isFuture() || System.isQueueable()) {
                handleOwnershipChangeNow(parentChecklistsIds,false); 
            }
            else{
                handleOwnershipChangeFuture(parentChecklistsIds,false); 
            } 
        } 
    }
    
    //MGF - The test class for the Round Robin code can be found in the CommuinitiesAccountUpdateControllerTest class. Method name: testSubmitChecklistsForReview
    public static void beforeUpdateHandler(Map<id,PEO_Onboarding_Checklist__c> oldMap ,Map<id,PEO_Onboarding_Checklist__c> newMap){
        //ISQ not required check
        system.debug( oldMap.values()[0].ownerId);
        system.debug( newMap.values()[0].ownerId);
        setISQnotRequired(newMap.values());
        //
        medicalPreqSubmissionCheck(newMap);
        checkMedStatus(oldMap,newMap);
        //Check fields document required statuses:start
        List<PEO_Onboarding_Checklist__c> checklistBlank = new List<PEO_Onboarding_Checklist__c>();
        List<PEO_Onboarding_Checklist__c> chklstsForNBSCassignmentQQ = new List<PEO_Onboarding_Checklist__c>();
        //test
        for (PEO_Onboarding_Checklist__c onbChecklist : newMap.values()) 
        {
            //if the CS_CM_Contract_Status__c is changed and meets the criteria for CS submission, change the Last_Change_Made__c to null
            PEO_Onboarding_Checklist__c oldChecklist2 = oldMap.get(onbChecklist.Id);
            system.debug('oldChecklist:'+oldChecklist2);
            system.debug('beforeUpdateHandler: new onbChecklist:'+onbChecklist);
            
            //JC SFDC-22571 - splitting out logic to evaluate paths independently 
            if(onbChecklist.Do_you_need_full_underwriting_path__c !='Yes'){
                if(onbChecklist.HSF_Submission_Status__c != oldChecklist2.HSF_Submission_Status__c  && onbChecklist.HSF_Submission_Status__c == 'SUCCESS') {
                    onbChecklist.HSF_Census_Submit_Date__c =System.now();                         
                }
                System.debug('beforeUpdateHandler: Setting fields to CS forced');
                if(onbChecklist.Workers_Comp_Quick_Quote_Eligibility__c=='Full Underwriting Required'	
                   && onbChecklist.Workers_Comp_Quick_Quote_Eligibility__c!=oldChecklist2.Workers_Comp_Quick_Quote_Eligibility__c) {
                       onbChecklist.Workers_Comp_Underwriting_Path_Type__c='Clientspace Forced - Workers Comp';
                       onbChecklist.PEO_Checklist_submission_status__c= 'Not Submitted';                         
                   } //if
                if(onbChecklist.Medical_Quick_Quote_Eligibility__c=='Full Underwriting Required'
                   && onbChecklist.Medical_Quick_Quote_Eligibility__c!=oldChecklist2.Medical_Quick_Quote_Eligibility__c) {
                       if(onbChecklist.Is_Medical_Underwriting_Requested__c != 'Currently does not have Medical and not interested in Medical, do not quote'){
                           onbChecklist.Medical_Underwriting_Path_Type__c='Clientspace Forced - Medical';
                       }
                       onbChecklist.PEO_Checklist_submission_status__c= 'Not Submitted';                         
                   } //if
            } //(onbChecklist.Do_you_need_full_underwriting_path__c !='Yes') 
            //If the opportunity is changed on the checklist, update the Oppty_Linked_to_Checklist_Date field
            if(onbChecklist.Opportunity__c != null && oldChecklist2.Opportunity__c != null && onbChecklist.Opportunity__c != oldChecklist2.Opportunity__c){
                onbChecklist.Oppty_Linked_to_Checklist_Date__c = System.now();
            }
        }
        //test: end
        updateDocReqdStatus(checklistBlank, newMap, oldMap);
        //end
        //Added by Srujan (To reset the quick quote documents)
        resetQQDocuments(newMap, oldMap);
        PEO_Onboarding_Checklist__c[] checklistsToRoundRobin = new PEO_Onboarding_Checklist__c[]{};
        Map<Id,Id> queueIdByChecklistId = new Map<Id,Id>();
        Map<Id,PEO_Onboarding_Checklist__c> nscChecklistByAccountId = new Map<Id,PEO_Onboarding_Checklist__c>();
        Map<Id, PEO_Onboarding_Checklist__c> checklistForStatusUpdates = new Map<Id, PEO_Onboarding_Checklist__c>();
        //List of values at which doc submission to CS is successful
        List<string> clientSpaceValues = new List<string> {'Approved','Client','Terminated','Dead','Implementation','Accepted','Underwriting','Contract Pending Approval','Acquisition Implementation','Expired','HR Onboarding','FlexClient','FlexTerm'};
            
        for (PEO_Onboarding_Checklist__c onbChecklist : newMap.values()) 
        {
            //if the CS_CM_Contract_Status__c is changed and meets the criteria for CS submission, change the Last_Change_Made__c to null
            PEO_Onboarding_Checklist__c oldChecklist = oldMap.get(onbChecklist.Id);
            system.debug('oldChecklist:'+oldChecklist);
            system.debug('beforeUpdateHandler: new onbChecklist:'+onbChecklist);
            
            //JC SFDC-22571 - splitting out logic to evaluate paths independently 
            /*if(onbChecklist.Do_you_need_full_underwriting_path__c !='Yes'){
                System.debug('beforeUpdateHandler: Setting fields to CS forced');
                if(onbChecklist.Workers_Comp_Quick_Quote_Eligibility__c=='Full Underwriting Required'	
                     && onbChecklist.Workers_Comp_Quick_Quote_Eligibility__c!=oldChecklist.Workers_Comp_Quick_Quote_Eligibility__c) {
                        onbChecklist.Workers_Comp_Underwriting_Path_Type__c='Clientspace Forced - Workers Comp';
                         onbChecklist.PEO_Checklist_submission_status__c= 'Not Submitted';                         
                     } //if
                if(onbChecklist.Medical_Quick_Quote_Eligibility__c=='Full Underwriting Required'
                   && onbChecklist.Medical_Quick_Quote_Eligibility__c!=oldChecklist.Medical_Quick_Quote_Eligibility__c) {
                        onbChecklist.Medical_Underwriting_Path_Type__c='Clientspace Forced - Medical';
                        onbChecklist.PEO_Checklist_submission_status__c= 'Not Submitted';                         
                   } //if
            }*/ //(onbChecklist.Do_you_need_full_underwriting_path__c !='Yes') 
			
            //Check if the checklist is approved: Released on S15
            //If approved submit and QQ auto submit the record to NBSC
            //update logic to check QQ ln 109
            if(onbChecklist.CS_CM_Contract_Status__c == 'Approved' 
               && oldChecklist.CS_CM_Contract_Status__c != onbChecklist.CS_CM_Contract_Status__c 
               && onbChecklist.Sales_Analyst__c == null && onbChecklist.Do_you_need_full_underwriting_path__c !='Yes'
              )
            {
                System.debug('beforeUpdateHandler: calling NBSC assignment and Round robin');
                chklstsForNBSCassignmentQQ.add(onbChecklist);
                checklistsToRoundRobin.add(onbChecklist);
            }
            //SPA: latest update - end
            
            if(oldChecklist.CS_CM_Contract_Status__c != onbChecklist.CS_CM_Contract_Status__c){
                if(onbChecklist.CS_CM_Contract_Status__c != null && clientSpaceValues.contains(onbChecklist.CS_CM_Contract_Status__c))onbChecklist.Last_Change_Made__c = null;
            }
            
            PEO_Onboarding_Checklist__c oldRec = oldMap.get(onbChecklist.Id);
            if(oldRec!=null && oldRec.OwnerId!=onbChecklist.OwnerId && String.valueOf(onbChecklist.OwnerId).startsWith('00G') && 
               (onbChecklist.Parent_PEO_Checklist__c == null || onbChecklist.Parent_PEO_Checklist__c !=null && onbChecklist.Client_Add_on__c )) {
                System.debug('beforeUpdateHandler: OwnerId change');
                checklistsToRoundRobin.add(onbChecklist);
                queueIdByChecklistId.put(onbChecklist.Id,onbChecklist.OwnerId);
            }
            //trying to cover a situation where they manually assign an analyst as the owner
            //JC  added && onbChecklist.owner.title !='New Business Sales Consultant' && onbChecklist.owner.title !='Sales Analyst - PEO' 
            else if(oldRec!=null && oldRec.OwnerId!=onbChecklist.OwnerId && !String.valueOf(onbChecklist.OwnerId).startsWith('00G') && onbChecklist.Parent_PEO_Checklist__c == null
                   && onbChecklist.Sales_Analyst__c!=null && onbChecklist.Sales_Analyst__c!=onbChecklist.OwnerId 
                   && (onbChecklist.owner.title =='New Business Sales Consultant' || onbChecklist.owner.title =='Sales Analyst - PEO')) {
                       System.debug('beforeUpdateHandler: updating Sales_Analyst__c');
                onbChecklist.Sales_Analyst__c=onbChecklist.OwnerId;               
            }
            /*if(oldRec!=null && onbChecklist.Parent_PEO_Checklist__c == null && onbChecklist.Prospect_Client__c!=null && !medUWCreateMap.containsKey(onbChecklist.Prospect_Client__c) 
               && onbChecklist.Opportunity__c != null && onbChecklist.Medical_Benefits_Underwriting_Requested__c == 'Yes' && onbChecklist.Reference_PEO_Medical_UW__c == null &&
               (oldRec.Opportunity__c != onbChecklist.Opportunity__c || oldRec.Medical_Benefits_Underwriting_Requested__c != onbChecklist.Medical_Benefits_Underwriting_Requested__c)){
              medUWCreateMap.put(onbChecklist.Opportunity__c,onbChecklist);
            }*/
            
            if(oldRec!=null && onbChecklist.Parent_PEO_Checklist__c == null && onbChecklist.Prospect_Client__c!=null && !medUWCreateMap.containsKey(onbChecklist.Prospect_Client__c) 
               && onbChecklist.Opportunity__c != null && (onbChecklist.Is_Medical_Underwriting_Requested__c == 'Currently have Medical, please quote'|| onbChecklist.Is_Medical_Underwriting_Requested__c == 'Currently does not have Medical, please quote') && onbChecklist.Reference_PEO_Medical_UW__c == null &&
               (oldRec.Opportunity__c != onbChecklist.Opportunity__c || oldRec.Is_Medical_Underwriting_Requested__c != onbChecklist.Is_Medical_Underwriting_Requested__c)){
                   System.debug('beforeUpdateHandler: Adding to medUWCreateMap');
                   medUWCreateMap.put(onbChecklist.Opportunity__c,onbChecklist);
               }
            
            if(onbChecklist.Prospect_Client__c!=null){
                System.debug('beforeUpdateHandler: Adding to nscChecklistByAccountId');
                nscChecklistByAccountId.put(onbChecklist.Prospect_Client__c,onbChecklist);
            }
            
            // if either the cs cm contract status or cs cm medical uw status is changed add the checklist
            // to the map of checklists that require a status update
            if (oldRec != null && 
                (onbChecklist.CS_CM_Medical_UW_Status__c != oldRec.CS_CM_Medical_UW_Status__c || onbChecklist.CS_CM_Contract_Status__c != oldRec.CS_CM_Contract_Status__c)) {
                    System.debug('beforeUpdateHandler: Adding to checklistForStatusUpdates');   
                    checklistForStatusUpdates.put(onbChecklist.Id, onbChecklist);
                }
            if(onbChecklist.Parent_PEO_Checklist__c == null && oldRec!=null && (onbChecklist.Number_of_Open_Medical_Discrepancies__c!=oldRec.Number_of_Open_Medical_Discrepancies__c
                                ||onbChecklist.Number_of_Open_Risk_Discrepancies__c!=oldRec.Number_of_Open_Risk_Discrepancies__c)){
                System.debug('beforeUpdateHandler:Calling setDiscrepancyCounts');   
                setDiscrepancyCounts(onbChecklist,oldRec);
            }
            if(onbChecklist.Sync_with_BLS__c == true){
                System.debug('beforeUpdateHandler:Sync_with_BLS__c is true');
                Account dataPointAcc = [Select id, Name, BillingState,ShippingState, NAICS_Code__c from Account where id=:onbChecklist.Prospect_Client__c];
                List<Account> dataPointAccs = new List<Account>();
                dataPointAccs.add(dataPointAcc);
                List<PEO_Onboarding_Checklist__c> dataPointChecklists = new List<PEO_Onboarding_Checklist__c>();
                dataPointChecklists.add(onbChecklist);
                BlsDataHelper.fetchTheDatapoints(dataPointAccs, dataPointChecklists,'PEOOnboardingChecklist_Handler');
                for(PEO_Onboarding_Checklist__c chk: dataPointChecklists ){
                    chk.Sync_with_BLS__c = false;
                }
            }
            
            if(onbChecklist.HSF_Submission_Status__c != oldChecklist.HSF_Submission_Status__c){
                System.debug('beforeUpdateHandler:Update time stamp for HSF');
                System.debug('beforeUpdateHandler onbChecklist.HSF_Submission_Status__c:'+onbChecklist.HSF_Submission_Status__c);
                if(onbChecklist.HSF_Submission_Status__c != null){
                    onbChecklist.HSF_Status_Change_Date__c = System.now();
                    System.debug('beforeUpdateHandler Update time stamp completed');
                    //Check if HSF Status meets the criteria to send chatter notifications
                    //Boolean chatterStatus = onbChecklist.HSF_Submission_Status__c == 'UNFAVORABLE' || onbChecklist.HSF_Submission_Status__c == 'FAVORABLE' || onbChecklist.HSF_Submission_Status__c == 'RESULTS INCONCLUSIVE' || onbChecklist.HSF_Submission_Status__c == 'FAIL';
                    Boolean chatterStatus = onbChecklist.HSF_Submission_Status__c == 'Success' || onbChecklist.HSF_Submission_Status__c == 'FAIL';

                    if(chatterStatus){
                        //HSF is not used anymore. So commenting the notifications
                    sendHSFStatusUpdateChatter(onbChecklist.HSF_Submission_Status__c,onbChecklist);
                    }
                }
            }
        }
        
        
        if(!medUWCreateMap.isEmpty()){
            System.debug('beforeUpdateHandler:Calling checkForMedUW');
            checkForMedUW(medUWCreateMap);
        }
        
        System.debug('beforeUpdateHandler:nscChecklistByAccountId:'+nscChecklistByAccountId);
        if(!nscChecklistByAccountId.isEmpty()){
            System.debug('beforeUpdateHandler:Calling checkForNSC');
            checkForNSC(nscChecklistByAccountId);
        }
        
        // send the call to update checklist statuses if the checklistForStatusUpdates is not empty
        if (!checklistForStatusUpdates.isEmpty() ) {
            System.debug('beforeUpdateHandler:Calling sendChecklistCurrentStepValueUpdate');
            sendChecklistCurrentStepValueUpdate(checklistForStatusUpdates);
        }
        
        if (!chklstsForNBSCassignmentQQ.isEmpty() ) {
            //S15 : Uncomment this code
            System.debug('beforeUpdateHandler:Calling QuickQuoteNBSCAssignment');
            QuickQuoteNBSCAssignment(chklstsForNBSCassignmentQQ);
        }
        if(!checklistsToRoundRobin.isEmpty()){
            System.debug('beforeUpdateHandler:Calling handleRoundRobin');
            handleRoundRobin(checklistsToRoundRobin,queueIdByChecklistId);
        }
        if (!chklstsForNBSCassignmentQQ.isEmpty() && !repUsersMap.isEmpty()) {
            //S15 : Uncomment this code
            System.debug('beforeUpdateHandler:Calling qqApprovedNotification');
            qqApprovedNotification(chklstsForNBSCassignmentQQ,repUsersMap);
        }
        
        
        for (PEO_Onboarding_Checklist__c chk : newMap.values()) system.debug('PEOOnboardingChecklist_Handler.beforeUpdateHandler - updated chk before save: '+ chk);
    }
    
    public static void afterUpdateHandler(Map<id,PEO_Onboarding_Checklist__c> oldMap ,Map<id,PEO_Onboarding_Checklist__c> newMap){
        List<Id> listOfDiscrepancy = new List<Id>();
        Map<id,PEO_Onboarding_Checklist__c> opptunityChangedMap=new Map<id,PEO_Onboarding_Checklist__c>();
        Set<Id> checklistsForRejectChatterNotif = new Set<Id>();
        Set<Id> idsToSyncWithCS  = new Set<Id>();
      //  List<PEO_Onboarding_Checklist__c> lstPEOOBQQE = new List<PEO_Onboarding_Checklist__c>();
      //  List<PEO_Onboarding_Checklist__c> lstPEOOBMPM = new List<PEO_Onboarding_Checklist__c>();
        List<PEO_Onboarding_Checklist__c> QQtoTraditionalChecklists = new List<PEO_Onboarding_Checklist__c>();
        List<PEO_Onboarding_Checklist__c> lstHsaStatusFail = new List<PEO_Onboarding_Checklist__c>();
       
        Id[] parentOwnerChangeIds = new Id[]{};
        Set<Id> UpdatedOppIds = new Set<Id>();
        
        for(PEO_Onboarding_Checklist__c newRec : newMap.values()){
             PEO_Onboarding_Checklist__c oldRec = oldMap.get(newRec.Id);
             if(newRec.HSF_Submission_Status__c != oldRec.HSF_Submission_Status__c && (newRec.HSF_Submission_Status__c == 'Fail' || newRec.HSF_Submission_Status__c == 'Failure' || newRec.HSF_Submission_Status__c == 'SUCCESS')){
                lstHsaStatusFail.add(newRec);
             }
            
             if(newRec.Opportunity__c != null && newRec.Opportunity__c != oldMap.get(newRec.Id).Opportunity__c){
                UpdatedOppIds.add(newRec.Opportunity__c);
             }
            /* if(newRec.Workers_Comp_Quick_Quote_Eligibility__c == 'Unfavorable for Masterplan WC' 
                && oldMap.get(newRec.Id).Workers_Comp_Quick_Quote_Eligibility__c == null)
                lstPEOOBQQE.add(newRec);
             if(newRec.Medical_Quick_Quote_Eligibility__c == 'Unfavorable for Masterplan Medical' 
                && oldMap.get(newRec.Id).Medical_Quick_Quote_Eligibility__c == null)
                lstPEOOBMPM.add(newRec);*/
                                    
            if(newRec.Send_Discrepancy_Email__c!=null && oldMap.get(newRec.Id).Send_Discrepancy_Email__c!=newRec.Send_Discrepancy_Email__c)
                listOfDiscrepancy.add(newRec.id);
            System.debug('PEOOnboardingChecklist_Handler.afterUpdateHandler: newRec - '+newRec.Industry_Record_Types__c+ ' - Peo_IndSpecific_formStatus__c - ' + newRec.Peo_IndSpecific_formStatus__c );
            if(newRec.Send_Discrepancy_Email__c!=null && oldMap.get(newRec.Id).Send_Discrepancy_Email__c!=newRec.Send_Discrepancy_Email__c)
                listOfDiscrepancy.add(newRec.id);
            
            // if the status has been updated to a reject status add the checklist ID to the set used for chatter notifications
            if (oldRec != null && newRec.Reject_Sent_back_to_Sales_Status_Date__c == null && newRec.Current_Step__c =='Reject/Sent back to Sales') {
                System.debug(newRec.Reject_Sent_back_to_Sales_Status_Date__c);
                checklistsForRejectChatterNotif.add(newRec.Id);
            }
            if((oldRec!=null && oldRec.OwnerId!=newRec.ownerId && newRec.Parent_PEO_Checklist__c == null && newRec.Sales_Analyst__c == null)  || ( newRec.Current_Step__c == 'New Submission' && newRec.Current_Step__c != oldRec.Current_Step__c) ){ 
                parentOwnerChangeIds.add(newRec.Id);
            }
            //JDA S2:10448 updated to sync if Current step is not Lost as this was giving error with too many queueable calls
            
            if (newRec.Completed_Step__c == 'addtlInfo' && newRec.Current_Step__c != 'Lost' && (oldRec == null || newRec.Completed_Step__c != oldRec.Completed_Step__c)) {
                idsToSyncWithCS.add(newRec.Prospect_Client__c);
            }
            
            //JDA SPA changes to clear the Doc details send to CS when Status is switched from QQ to traditional
            if(newRec.Medical_Underwriting_Path_Type__c != null && newRec.Medical_Underwriting_Path_Type__c != oldMap.get(newRec.Id).Medical_Underwriting_Path_Type__c && newRec.Medical_Underwriting_Path_Type__c != 'Quick Quote - Medical'){
                QQtoTraditionalChecklists.add(newRec);
            }
        }
        if(UpdatedOppIds != null && UpdatedOppIds.size() > 0){
            updateNewOpportyStageAfterUpdate(UpdatedOppIds);
        }
        if(listOfDiscrepancy!=null && listOfDiscrepancy.size()>0 ){
            if (Test.isRunningTest() || System.isBatch() || System.isFuture() || System.isQueueable()) {
                sendDiscrepancyEmailNow(listOfDiscrepancy);
            }
            else{
                sendDiscrepancyEmailFuture(listOfDiscrepancy);
            } 
        }
        if(!parentOwnerChangeIds.isEmpty()) {
            if (Test.isRunningTest() || System.isBatch() || System.isFuture() || System.isQueueable()) {
                handleOwnershipChangeNow(parentOwnerChangeIds,true); 
            }
            else{
                handleOwnershipChangeFuture(parentOwnerChangeIds,true); 
            } 
           
        }
        
        if (!idsToSyncWithCS.isEmpty()) {
            ClientSpaceHelper.checkLocationsForAccount(idsToSyncWithCS);
        }
        
        // send the future call to the chatter post method for the checklist IDs
        if (!checklistsForRejectChatterNotif.isEmpty()) {
            sendChatterForRejectedChecklist(checklistsForRejectChatterNotif);
        }
      /*  if (!lstPEOOBQQE.isEmpty()) {
            createChatterPost(lstPEOOBQQE, 'WC');
        }
        if (!lstPEOOBMPM.isEmpty()) {
             createChatterPost(lstPEOOBMPM, 'MED');
        }*/
        if(!QQtoTraditionalChecklists.isEmpty()){
            clearPrevCensusInfo(QQtoTraditionalChecklists);
        }
        if(!lstHsaStatusFail.isEmpty()){
         //   postHSACensusFailChatter(lstHsaStatusFail);
        }
    }//afterUpdateHandler

    //Created by Jidesh as part of SPA
    public static void QuickQuoteNBSCAssignment(List<PEO_Onboarding_Checklist__c> qqApprovedChecklists){
        //Code for Quick quote NBSC submission
        //Bulkifying the SubmitForReview method
        System.debug('QuickQuoteNBSCAssignment qqApprovedChecklists:'+qqApprovedChecklists);
        List<Id> chkSalesReps = new List<Id>();
        List<User> repUsers = new List<User>();
        //Map<Id, User> repUsersMap = new Map<Id, User>();
        List<Group> foundQueue;
        List<Group> foundQueueQualifier;
        List<Group> foundQueueQQ;
        PEO_Onboarding_Checklist__c qqChecklist;
        String queueName = '';
        List<PEO_Onboarding_Checklist__c> parentChecklists = new List<PEO_Onboarding_Checklist__c>();
        List<Account> parentAccounts = new List<Account>();
        List<Id> parentAccountIds = new List<Id>();
        List<Id> refNationalAccIds = new List<Id>();
        List<Id> strPrtnrsSA = new List<Id>();
        List<PEO_Edge_Queue_Districts__c> possibleQueues = PEO_Edge_Queue_Districts__c.getAll().values();
        PEO_Edge_Queue_Districts__c testingQueue = PEO_Edge_Queue_Districts__c.getValues('Testing');
        PEO_Edge_Queue_Districts__c qualifierQueue = PEO_Edge_Queue_Districts__c.getValues('Qualifier');
        List<Referral_Account__c> strategicAccounts = new List<Referral_Account__c>();
        Map<Id, Id> accntStrategicPartnerMap = new Map<Id, Id>();
        //Account Id and Strategic Account partner map
        Map<Id, User> accntStrategicPartnerMapFinal = new Map<Id, User>();
        for(PEO_Onboarding_Checklist__c chk : qqApprovedChecklists){
            if(chk.Parent_PEO_Checklist__c != Null){
                System.debug(chk.Name+'not a parent');
            }
            else{
                parentChecklists.add(chk);
                parentAccountIds.add(chk.Prospect_Client__c);
            }
        }
        System.debug('QuickQuoteNBSCAssignment parentAccountIds:'+parentAccountIds);
        if(parentAccountIds.size()>0){
            for(Account accnt : [Select Id, Name, Referral_National_Account__c from Account where Id IN: parentAccountIds]){
                if(accnt.Referral_National_Account__c != Null){
                    refNationalAccIds.add(accnt.Referral_National_Account__c);
                }
            }
            System.debug('QuickQuoteNBSCAssignment refNationalAccIds:'+refNationalAccIds);
            if(refNationalAccIds.size()>0){
                for(Referral_Account__c strategicAccount: [SELECT Id, Name, Account__c, NBSC_SA_Partner__c, Parent_Referral_Account__c,
                                                           Parent_Referral_Account__r.NBSC_SA_Partner__c FROM Referral_Account__c 
                                                           WHERE Id IN: refNationalAccIds]){
                    if(strategicAccount.Parent_Referral_Account__c != null && 
                       strategicAccount.Parent_Referral_Account__r.NBSC_SA_Partner__c != null) {
                        strPrtnrsSA.add(strategicAccount.Parent_Referral_Account__r.NBSC_SA_Partner__c);
                        accntStrategicPartnerMap.put(strategicAccount.Parent_Referral_Account__r.NBSC_SA_Partner__c, 
                                                     strategicAccount.Account__c);
                    }
                    else if(strategicAccount.NBSC_SA_Partner__c != null) {
                        strPrtnrsSA.add(strategicAccount.NBSC_SA_Partner__c);
                        accntStrategicPartnerMap.put(strategicAccount.NBSC_SA_Partner__c, strategicAccount.Account__c);
                    }
                }
                System.debug('QuickQuoteNBSCAssignment strPrtnrsSA:'+strPrtnrsSA);
                if(strPrtnrsSA.size()>0){
                    for(User usr : [SELECT Id, Name FROM User WHERE Id IN :strPrtnrsSA]){
                        accntStrategicPartnerMapFinal.put(accntStrategicPartnerMap.get(usr.Id), usr);
                    }
                }
            }
        }
        System.debug('QuickQuoteNBSCAssignment accntStrategicPartnerMapFinal:'+accntStrategicPartnerMapFinal);
        //
        //Running Clientspace location queueable
        //We may need to bulkify
        System.debug('QuickQuoteNBSCAssignment parentChecklists:'+parentChecklists);
        if(parentChecklists.size()>0){
            Set<Id> accountIds = new Set<Id>();
            for(PEO_Onboarding_Checklist__c parChk : parentChecklists){
                accountIds.add(parChk.Prospect_Client__c);
            }
            ClientSpaceHelper.checkLocationsForAccount(accountIds);
        }
        
        if(testingQueue.Name != null){
            foundQueue = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND NAME = :testingQueue.Name LIMIT 1];
            System.debug('Queue found '+foundQueue);
        }
        if(qualifierQueue.Name != null){
            foundQueueQualifier = [SELECT Id,  Name FROM Group WHERE Type = 'Queue' AND NAME = :qualifierQueue.Quick_Quote_Queue__c LIMIT 1];
            System.debug('Queue found '+foundQueueQualifier);
        }
        for(PEO_Onboarding_Checklist__c qqChk : qqApprovedChecklists){
            if(qqChk.Sales_Rep__c != null){
                chkSalesReps.add(qqChk.Sales_Rep__c);
            }
            for(Id accId: accntStrategicPartnerMapFinal.keySet()){
                if(qqChk.Prospect_Client__c == accId){
                    qqChk.OwnerId = accntStrategicPartnerMapFinal.get(accId).Id;
                    qqChk.PEO_Checklist_submission_status__c = 'Submitted';
                    qqChk.Sales_Analyst__c = accntStrategicPartnerMapFinal.get(accId).Id;
                    qqChk.Analyst_Queue__c = system.now();
                    qqChk.Analyst_Queue_Name__c = 'Strategic Account'; 
                }
            }
        }
        System.debug('QuickQuoteNBSCAssignment chkSalesReps:'+chkSalesReps);
        if(chkSalesReps.size()>0){
           repUsers = [SELECT Id,Full_Name__c,District__c,Sales_Org__c,Rep_Type__c FROM User WHERE Id IN :chkSalesReps AND IsActive = true];
        }
        for(User rep: [SELECT Id,Full_Name__c,District__c,Sales_Org__c,Rep_Type__c FROM User WHERE Id IN :chkSalesReps AND IsActive = true]){
            repUsersMap.put(rep.Id,rep);
        }
        
        System.debug('QuickQuoteNBSCAssignment repUsers:'+repUsers);
        System.debug('QuickQuoteNBSCAssignment repUsersMap:'+repUsersMap);
        if(repUsersMap.keySet().size()>0){
            for(PEO_Onboarding_Checklist__c chk : qqApprovedChecklists){
                List<Id> strPrtnrsAccntIds = new List<Id>();
                //Routing to testing queue
                System.debug('chk.Sales_Rep__c:'+ chk.Sales_Rep__c);
                System.debug('chk.Sales_Rep__r.Rep_Type__c:'+ repUsersMap.get(chk.Sales_Rep__c).Rep_Type__c);
                Boolean isNotStrategicPartner = true;
                for(Id accId: accntStrategicPartnerMapFinal.keySet()){
                    If(chk.Prospect_Client__c == accId){
                        isNotStrategicPartner = false;
                    }
                }
                if(isNotStrategicPartner == true){
                    if(chk.Route_to_Testing_Queue__c && foundQueue != null && !foundQueue.isEmpty() && foundQueue.size() == 1){
                        chk.OwnerId = foundQueue[0].Id;
                        chk.PEO_Checklist_submission_status__c = 'Submitted';
                   	chk.Analyst_Queue_Name__c =foundQueue[0].Name;
                    chk.Analyst_Queue__c = system.now();                        
                    }
                    else if(repUsersMap.get(chk.Sales_Rep__c).Rep_Type__c == 'High Velocity Rep' && foundQueueQualifier != null && !foundQueueQualifier.isEmpty() && foundQueueQualifier.size() == 1) {
                        chk.OwnerId = foundQueueQualifier[0].Id;
                        chk.PEO_Checklist_submission_status__c = 'Submitted';
                   	chk.Analyst_Queue_Name__c =foundQueueQualifier[0].name;
                    chk.Analyst_Queue__c = system.now();                            
                    }
                    else{ 
                        List<PEO_Edge_Queue_Districts__c> defaultQueue = new List<PEO_Edge_Queue_Districts__c>();
                        for(PEO_Edge_Queue_Districts__c queue: possibleQueues){
                            if(queue.Default_Queue__c){
                                defaultQueue.add(queue);
                            }
                        }
                        Boolean queueAssigned = false;
                        for(PEO_Edge_Queue_Districts__c queue : possibleQueues) {
                            if(queue.Districts__c != null) {
                                System.debug('JDA QuickQuoteNBSCAssignment queue='+queue);
                                List<String> possibleDistricts = queue.Districts__c.split(',');
                                System.debug('JDA QuickQuoteNBSCAssignment chk.Sales_Rep__r.District__c='+chk.Sales_Rep__r.District__c);
                                System.debug('JDA QuickQuoteNBSCAssignment possibleDistricts='+possibleDistricts);
                                if(!String.isEmpty(repUsersMap.get(chk.Sales_Rep__c).District__c) && possibleDistricts.contains(String.valueOf(integer.valueOf(repUsersMap.get(chk.Sales_Rep__c).District__c)))) {
                                    //Uncomment for S15
                                    queueName = queue.Quick_Quote_Queue__c;
                                    //Comment this for S15
                                    //queueName = queue.Name;
                                    queueAssigned = true;
                                    qqChecklist = chk;
                                    System.debug('Successfully found Queue: ' + queueName);
                                    break;
                                }
                                //}
                                
                            }
                        }
                        if(!queueAssigned && defaultQueue.size() > 0){
                            for(PEO_Edge_Queue_Districts__c myQueue: defaultQueue){
                                queueName = myQueue.Name;
                            }
                        }
                    }
                }
                else{
                    System.debug('If didnt execute since it had a strategicAccountPartner');
                }
            }
            //If a queue name has been found for this account, query for it.
            if(String.isNotBlank(queueName)) {
                //assign to the found queue.
                foundQueueQQ = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND NAME = :queueName LIMIT 1];
            }                    
            System.debug('Successfully found foundQueueQQ: ' + foundQueueQQ);
            //Set the owner of all Documents to be the retrieved queue and update the documents.
            if(foundQueueQQ != null && !foundQueueQQ.isEmpty() && foundQueueQQ.size() == 1 && qqChecklist != Null) {
                qqChecklist.OwnerId = foundQueueQQ[0].Id;
                qqChecklist.Analyst_Queue_Name__c =foundQueueQQ[0].Name;
                qqChecklist.Analyst_Queue__c = system.now();
                
                System.debug('Successfully routed to Queue: ' + foundQueueQQ[0].Name);
                //Update the submission status* || Needs to update as Approved status
                qqChecklist.PEO_Checklist_submission_status__c = 'Submitted';
            }
        }
        
    }
    
    public static void qqApprovedNotification(PEO_Onboarding_Checklist__c[] qqApprovedChecklists, Map<Id, User>repUsersMap){
        System.debug('qqApprovedNotification: ' + qqApprovedChecklists);
        List<Id> accIds = new List<Id>();
        Map<Id,Account> accMap = new Map<Id,Account>();
        for(PEO_Onboarding_Checklist__c checklist:qqApprovedChecklists){
            accIds.add(checklist.Prospect_Client__c);
        }
        for(Account acc: [Select Id, Name from Account where Id IN: accIds]){
            accMap.put(acc.Id, acc);
        }
        
        for(PEO_Onboarding_Checklist__c checklist:qqApprovedChecklists){
            Set<Id> mentionList = new Set<Id>();
            String header;
            System.debug('checklist.Sales_Analyst__c: ' + checklist.Sales_Analyst__c);
            System.debug('checklist.Sales_Rep__c: ' + checklist.Sales_Rep__c);
            
            if(checklist.Sales_Analyst__c != null && checklist.Sales_Rep__c != null && repUsersMap.get(checklist.Sales_Rep__c)!= null){
                mentionList.add(checklist.Sales_Rep__c);
                mentionList.add(checklist.Sales_Analyst__c);
                header = '';
                String postText = 'This quick quote submission for '+accMap.get(checklist.Prospect_Client__c).Name+' has been Approved by Underwriting.';
               	postText = postText + ' Please review the workspace for contingencies. If contracts are needed, please assist where applicable.';
                //postText = postText+ 'Please aid '+repUsersMap.get(checklist.Sales_Rep__c).Full_Name__c+' where appropriate to finalize the required information.';
                header = header + postText;
            }
            System.debug('mentionList: ' + mentionList);
            if(mentionList.size() > 0) {
                List<Id> mentList = new List<Id>();
                for (Id m : mentionList ) mentList.add(m);
                ChatterMentionPost.createChatterMentionPost(checklist.Id, mentList, new String[]{header},true,true);
                //saNotificationPosted=true;
            }
        }
    }

    
    @AuraEnabled
    public static void postHSACensusFailChatter(List<PEO_Onboarding_Checklist__c> lstChecList){
        try {
                // obc = [Select Id, HSF_Submission_Status__c, HSF_Submission_Response__c, Prospect_Client__c, Sales_Rep__c from PEO_Onboarding_Checklist__c where id =: checkListId];
                for(PEO_Onboarding_Checklist__c obc : lstChecList){
                    ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
                    ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                    messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                    feedItemInput.subjectId = obc.Id;
                    ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
                    textSegmentInput.text = 'Hello';
                    messageBodyInput.messageSegments.add(textSegmentInput);
                    List<id> userId = new List<Id>();
                    userId.add(obc.Sales_Rep__c);
                    ChatterMentionPost.getMentions(messageBodyInput, userId);
                    ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
                   
                    if(obc.HSF_Submission_Status__c == 'Fail' || obc.HSF_Submission_Status__c == 'Failure')
                    textSegmentInput2.text = ' An error was found for ';
                    else
                    textSegmentInput2.text = ' The Medical Census for ';
                    messageBodyInput.messageSegments.add(textSegmentInput2);

                   /* ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputProspect = new ConnectApi.EntityLinkSegmentInput();
                    entityLinkSegmentInputProspect.entityId = obc.Prospect_Client__c;  
                    messageBodyInput.messageSegments.add(entityLinkSegmentInputProspect); */
                    ConnectApi.TextSegmentInput textSegmentInput3 = new ConnectApi.TextSegmentInput();
                    if(obc.HSF_Submission_Status__c == 'Fail' || obc.HSF_Submission_Status__c == 'Failure'){
                        textSegmentInput3.text = ' within the Census Submission to Clientspace. Please review the below Error Message and update the Census accordingly. Once Updated, Please resubmit the the Census within the portal via the Submit tab. You may review this Error within the PEO Underwriting checklist at any time. \n';
                        messageBodyInput.messageSegments.add(textSegmentInput3);
                        if(obc.HSF_Submission_Response__c != null){
                            ConnectApi.TextSegmentInput errorLog = new ConnectApi.TextSegmentInput();
                            errorLog.text = 'Error: '+obc.HSF_Submission_Response__c;
                            messageBodyInput.messageSegments.add(errorLog);
                        }
                    }
                    else{
                        textSegmentInput3.text = ' was SUCCESSFULLY sent to Clientspace. Please navigate to Prospect workspace within Clientspace via the link below. You must now complete the pricing Console and fully submit the information for a Quick Quote review. The result from a medical and/or Workers Compensation Quick Quote review will be sent separately.  ';
                        messageBodyInput.messageSegments.add(textSegmentInput3);
                    }
                  

               
                    feedItemInput.body = messageBodyInput;
                    if(!test.isRunningTest()){
                        ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
                    }
                    //ChatterMentionPost.addToFeedBatch(feedItemInput);
                }
            
                
                //ChatterMentionPost.postBatchFeedElements();


        } catch (Exception e) {
            System.debug('e.getMessage()'+e.getMessage()+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static void clearPrevCensusInfo(List<PEO_Onboarding_Checklist__c> QQtoTraditionalChecklists){ 
        System.debug('clearPrevCensusInfo: Medical UW path type updated from QuickQuote to Traditional');
        List<Id> requiredChecklistIds = new List<Id>();
        for(PEO_Onboarding_Checklist__c checklist: QQtoTraditionalChecklists){
            requiredChecklistIds.add(checklist.Id);
        }
        List<PEO_Onboarding_Document__c> CensusDocs = [SELECT Date_Sent_to_Clientspace__c,Docs_Sent_to_Clientspace__c,Id,Name,Status__c 
                                                       FROM PEO_Onboarding_Document__c 
                                                       WHERE PEO_Onboarding_Checklist__r.Id IN :requiredChecklistIds 
                                                       AND Routing_Name__c ='Census' 
                                                       AND Status__c = 'Submitted to Clientspace'
                                                       AND Docs_Sent_to_Clientspace__c != Null];
        if(CensusDocs.size()>0){
            for(PEO_Onboarding_Document__c censusDoc: CensusDocs){
                censusDoc.Status__c = 'Approved';
                censusDoc.Docs_Sent_to_Clientspace__c = '';
                censusDoc.Date_Sent_to_Clientspace__c = Null;
            }
        }
        DmlHelper.performDML2(CensusDocs, DmlHelper.DML_UPDATE, 'PEOOnboardingChecklist_Handler', 'clearPrevCensusInfo', 'Updating PEO Underwriting Document', true);

    }
    
  /*  public static void createChatterPost(List<PEO_Onboarding_Checklist__c> lstPeoOB, String medOrWC){
        Set<Id> accIds = new Set<Id>();
        Set<Id> salesRepIds = new Set<Id>();
        for(PEO_Onboarding_Checklist__c objOC : lstPeoOB){
            accIds.add(objOC.Prospect_Client__c);
            salesRepIds.add(objOC.Sales_Rep__c);
        }
        Map<Id, String> mapIdToName = new Map<Id, String>();
        for(Account objAcc : [Select Id, Name from Account where Id IN : accIds]){
            mapIdToName.put(objAcc.Id, objAcc.Name);
        }
        Map<Id, Id> mapUserIdToManagerid= new Map<Id, Id>();
        for(User objU : [Select Id, ManagerId  from User where Id IN : salesRepIds]){
            mapUserIdToManagerid.put(objU.Id, objU.ManagerId );
        }
        for(PEO_Onboarding_Checklist__c objOC : lstPeoOB){
            
            List<Id> lstMentionId = new List<Id>();
            if(objOC.Sales_Rep__c != null)
            	lstMentionId.add(objOC.Sales_Rep__c);
            if(objOC.Sales_Analyst__c != null)
            	lstMentionId.add(objOC.Sales_Analyst__c);
            if(mapUserIdToManagerid.containsKey(objOC.Sales_Rep__c) && mapUserIdToManagerid.get(objOC.Sales_Rep__c) != null)
            	lstMentionId.add(mapUserIdToManagerid.get(objOC.Sales_Rep__c));
            String prospectName = mapIdToName.containsKey(objOC.Prospect_Client__c) ? mapIdToName.get(objOC.Prospect_Client__c) : '';
            String message ;
            if(medOrWC == 'WC')
                createChatterMentionPostWithProspectMention(objOC.Id, objOC.Prospect_Client__c, lstMentionId, true, true, 'WC', objOC.Workers_Comp_Quick_Quote_Eligibility__c);
            	//message = 'Based on the Worker\'s Compensation risk analysis for ' + prospectName+', we are unable to offer WC coverage through a PEO Master WC policy. To offer a Paychex integrated solution the prospect has been referred to PIA for a possible outside WC option.  To avoid duplication of efforts, please do not reach out to the agency directly.';
            if(medOrWC == 'MED')
                  createChatterMentionPostWithProspectMention(objOC.Id, objOC.Prospect_Client__c, lstMentionId, true, true, 'MED', objOC.Medical_Quick_Quote_Eligibility__c);
               // message = 'Based on '  + prospectName+', Medical Risk Analysis, we are unable to offer them Medical through the PEO Master Health policy. However, they are Approved to Self-Retain Medical so they can take advantage of alternative offerings. Since they are now Approved to Self-Retain medical, the HPP team will pursue open-market medical options and engage the appropriate H&B Sales Rep or ISR to work with you.  To avoid duplication of efforts, do not engage an H&B Sales Rep at this time.';
				
            //lstMentionId.add(objOC.Prospect_Client__c);
            	system.debug('lstMentionId'+lstMentionId);
            
                //ChatterMentionPost.createChatterMentionPost(objOC.Id, lstMentionId, new String[]{message}, true );
            
             if(medOrWC == 'MED')
                 sendChatterPostEmail(lstPeoOB);
        }
    }*/

    public static void createChatterMentionPostWithProspectMention(Id parentId, Id prospectId, List<Id> userToMentionIdList, 
                                                                        Boolean mentionsFirst, Boolean postImmediately, String wcOrMEd, String qqType) {
                ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
                ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                feedItemInput.subjectId = parentId;
                ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
                textSegmentInput.text = 'Hello';
                messageBodyInput.messageSegments.add(textSegmentInput);
                ChatterMentionPost.getMentions(messageBodyInput, userToMentionIdList);
                
                //messageBodyInput.messageSegments.add(textSegmentInput);

                //textSegmentInput.text = '. ';
                ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
                if(wcOrMEd == 'WC'){                     
                     textSegmentInput2.text = '. Based on the Workers\' Compensation risk analysis for ';
                }else{                     
                     textSegmentInput2.text = '. Based on ';
                }
                messageBodyInput.messageSegments.add(textSegmentInput2);

                ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputProspect = new ConnectApi.EntityLinkSegmentInput();
                entityLinkSegmentInputProspect.entityId = prospectId;  
                messageBodyInput.messageSegments.add(entityLinkSegmentInputProspect);
                ConnectApi.TextSegmentInput textSegmentInput3 = new ConnectApi.TextSegmentInput();
                if(wcOrMEd == 'WC'){                   
                     textSegmentInput3.text = ', we are unable to offer WC coverage through a PEO Master WC policy. To offer a Paychex integrated solution the prospect has been referred to PIA for a possible outside WC option.  To avoid duplication of efforts, please do not reach out to the agency directly.';
                }else{                      
                     textSegmentInput3.text = ' Medical Risk Analysis, we are unable to offer them Medical through the PEO Master Health policy. However, they are Approved to Self-Retain Medical so they can take advantage of alternative offerings. Since they are now Approved to Self-Retain medical, the HPP team will pursue open-market medical options and engage the appropriate H&B Sales Rep or ISR to work with you.  To avoid duplication of efforts, do not engage an H&B Sales Rep at this time.';
                }
                messageBodyInput.messageSegments.add(textSegmentInput3);

                feedItemInput.body = messageBodyInput;
          
                if (!mentionsFirst) {
                    ChatterMentionPost.getMentions(messageBodyInput, userToMentionIdList);
                } // if (!mentionsFirst)
        
                ChatterMentionPost.addToFeedBatch(feedItemInput);
                if (postImmediately) {
                    ChatterMentionPost.postBatchFeedElements();
                }              
        } 
    
    public static void sendChatterPostEmail(List<PEO_Onboarding_Checklist__c> lstPeoOB){
        Set<Id> accIds = new Set<Id>();
        for(PEO_Onboarding_Checklist__c objOC : lstPeoOB){
            accIds.add(objOC.Prospect_Client__c);
        }
        Map<Id, String> mapIdToName = new Map<Id, String>();
        for(Account objAcc : [Select Id, Name from Account where Id IN : accIds]){
            mapIdToName.put(objAcc.Id, objAcc.Name);
        }
        for(PEO_Onboarding_Checklist__c objOC : lstPeoOB){
            
            
            String prospectName = mapIdToName.containsKey(objOC.Prospect_Client__c) ? mapIdToName.get(objOC.Prospect_Client__c) : '';
            String  message = 'Based on ' + prospectName+', Medical Risk Analysis, we are unable to offer them Medical through the PEO Master Health policy. However, they are Approved to Self-Retain Medical so they can take advantage of alternative offerings. Since they are now Approved to Self-Retain medical, the HPP team will pursue open-market medical options and engage the appropriate H&B Sales Rep or ISR to work with you.  To avoid duplication of efforts, do not engage an H&B Sales Rep at this time.';
			// ChatterMentionPost.createChatterMentionPost(objOC.Id, lstMentionId, new String[]{message}, true );
            Messaging.SingleEmailMessage mymail = new Messaging.SingleEmailMessage();
            String[] toaddresses = new String[] {'HPP@paychex.com'}; 
            mymail.setToAddresses(toAddresses);
            mymail.setSubject('Unfavorable for Masterplan Medical');
            mymail.setPlainTextBody(message);
            //mymail.setHtmlBody(‘<p> This email has been sent through Apex</p>`);
            if(!test.isRunningTest()){
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mymail });
            }
  		}
            
            
            
        }
    
    
    public static void handleRoundRobin(PEO_Onboarding_Checklist__c[] checklistsToRR,Map<Id,Id>queueIdByChecklistId){
        Map<Id,Group> groupMap = new Map<Id,Group>([select id,name from group where id in:queueIdByChecklistId.values()]);
    
        //Pass the parent PEO Onboarding Checklists into the Round Robin handler to assign them anew owner
        if(!checklistsToRR.isEmpty()) {
            RoundRobin.prepareGenericRoundRobin(checklistsToRR, null);
        }
        //need to update checklist post round robin
       
        for(PEO_Onboarding_Checklist__c checklist : checklistsToRR) {
            Id queueId = queueIdByChecklistId.get(checklist.Id);
            if(queueId!=null){
                Group queue = groupMap.get(queueId);
                if(queue!=null){
                    checklist.Analyst_Queue__c = system.now();
                    checklist.Analyst_Queue_Name__c = queue.Name;
                }
            }

            System.debug('MGF PEOUnderwritingDocumentBefore String.valueOf(checklist.OwnerId)=' + String.valueOf(checklist.OwnerId));
            if(String.valueOf(checklist.OwnerId).startsWith('005')){
                checklist.Sales_Analyst__c = checklist.OwnerId;
            }
        }
    }
    //THIS IS TESTED BY CommunityFileUploadControllerTest.testSubmitChecklistsForReview
    //This method will make sure all child checklists have the same owner as the parent, make sure the sales team has access to all records and notify analysts when owner changes.
    @future
    public static void handleOwnershipChangeFuture(Id[] parentIds,Boolean postChatter){
        handleOwnershipChangeNow(parentIds,postChatter);
    }
    public static void handleOwnershipChangeNow(Id[] parentIds,Boolean postChatter){
        List<PEO_Onboarding_Checklist__c> checklistsToUpdate = new List<PEO_Onboarding_Checklist__c>();
        // Create a new list of sharing objects for Checklists and Documents
        List<PEO_Onboarding_Checklist__Share> checklistShrs  = new List<PEO_Onboarding_Checklist__Share>();
        List<PEO_Onboarding_Checklist__c> notificationList = new List<PEO_Onboarding_Checklist__c>();
        
        Map<Id,PEO_Onboarding_Checklist__c> parentChecklistMap = new Map<Id,PEO_Onboarding_Checklist__c>([SELECT Id,OwnerId,Sales_Rep__c,
                                                                                                          Sales_Analyst__c,Sales_Analyst__r.ManagerId,
                                                                                                          Prospect_Client__r.Name,PEO_Sales_Notes__c,
                                                                                                          Pricing_Console_Notes__c, Financial_Underwriting_Sales_Notes__c,
                                                                                                          Workers_Comp_Sales_Notes__c, Medical_Underwriting_Path_Type__c, Workers_Comp_Underwriting_Path_Type__c
                                                                                                          FROM PEO_Onboarding_Checklist__c
                                                                                                          WHERE Id in :parentIds]);
        
        for(PEO_Onboarding_Checklist__c checklist : parentChecklistMap.values()) {
            if(checklist.Sales_Rep__c != null) {
                checklistShrs.add(new PEO_Onboarding_Checklist__Share(ParentId=checklist.Id, UserOrGroupId=checklist.Sales_Rep__c, 
                                                                      AccessLevel='edit', RowCause=Schema.PEO_Onboarding_Checklist__Share.RowCause.Account_Owner__c));
            }
            if(postChatter && checklist.Workers_Comp_Underwriting_Path_Type__c != null && checklist.Medical_Underwriting_Path_Type__c  != null && (checklist.Workers_Comp_Underwriting_Path_Type__c != 'Quick Quote - Workers Comp' || checklist.Medical_Underwriting_Path_Type__c != 'Quick Quote - Medical')){
                notificationList.add(checklist);
            }
        }
        
        //Get all children checklists for the parents who have been added to the round robin queues
        Map<Id,PEO_Onboarding_Checklist__c> childrenChecklistsToReassign = new Map<Id,PEO_Onboarding_Checklist__c>([SELECT Id, Name, Parent_PEO_Checklist__c,Sales_Rep__c, 
                                                                                                                    Prospect_Client__c, OwnerId, Sales_Analyst__c
                                                                                                                    FROM PEO_Onboarding_Checklist__c 
                                                                                                                    WHERE Parent_PEO_Checklist__c IN :parentChecklistMap.keySet()]);
        //Assign any child checklists the same owner as the parent checklist
        for(PEO_Onboarding_Checklist__c onbChecklist : childrenChecklistsToReassign.values()) {
            PEO_Onboarding_Checklist__c parentOnbChecklist = parentChecklistMap.get(onbChecklist.Parent_PEO_Checklist__c);
            if(parentOnbChecklist != null) {
                Boolean updated=false;
                if(onbChecklist.OwnerId != parentOnbChecklist.OwnerId){
                    onbChecklist.OwnerId = parentOnbChecklist.OwnerId;
                    updated = true;
                }
                if(onbChecklist.Sales_Analyst__c != parentOnbChecklist.Sales_Analyst__c && parentOnbChecklist.Sales_Analyst__c!=null){
                    onbChecklist.Sales_Analyst__c = parentOnbChecklist.Sales_Analyst__c;
                    updated = true;
                    checklistShrs.add(new PEO_Onboarding_Checklist__Share(ParentId=onbChecklist.Id, UserOrGroupId=parentOnbChecklist.Sales_Analyst__c, 
                                                                          AccessLevel='read', RowCause=Schema.PEO_Onboarding_Checklist__Share.RowCause.Account_Owner__c));
                }
                if(onbChecklist.Sales_Rep__c != parentOnbChecklist.Sales_Rep__c){
                    onbChecklist.Sales_Rep__c = parentOnbChecklist.Sales_Rep__c;
                    updated = true;
                    checklistShrs.add(new PEO_Onboarding_Checklist__Share(ParentId=onbChecklist.Id, UserOrGroupId=parentOnbChecklist.Sales_Rep__c, 
                                                                          AccessLevel='read', RowCause=Schema.PEO_Onboarding_Checklist__Share.RowCause.Account_Owner__c));
                }
                /*if(onbChecklist.PEO_NSC__c != parentOnbChecklist.PEO_NSC__c){
                    onbChecklist.PEO_NSC__c = parentOnbChecklist.PEO_NSC__c;
                    updated = true;
                    checklistShrs.add(new PEO_Onboarding_Checklist__Share(ParentId=onbChecklist.Id, UserOrGroupId=parentOnbChecklist.PEO_NSC__c, 
                                                              AccessLevel='read', RowCause=Schema.PEO_Onboarding_Checklist__Share.RowCause.Account_Owner__c));
                }*/
                if(updated){
                    checklistsToUpdate.add(onbChecklist);
                }
            }//if(parentOnbChecklist != null
        }//for
        
        System.debug('PEOOnboardingChecklistHander reassignChildrenToHaveSameOwnerNow checklistsToUpdate.size()=' + checklistsToUpdate.size());
        //Update any checklists that have had their owner changed
        if(!checklistsToUpdate.isEmpty()) {
            DmlHelper.performDML2(checklistsToUpdate, DmlHelper.DML_UPDATE, 'PEOOnboardingChecklist_Handler', 'reassignChildrenToHaveSameOwner', 'Updating PEO Underwriting Checklists', true);
        }
        
        if(!checklistShrs.isEmpty()) {
            Database.SaveResult[] lsr = Database.insert(checklistShrs,false);
            // Create counter
            Integer i=0;
            // Process the save results
            for(Database.SaveResult sr : lsr){
                if(!sr.isSuccess()){
                    // Get the first save result error
                    Database.Error err = sr.getErrors()[0];
                    // Check if the error is related to a trivial access level
                    // Access levels equal or more permissive than the object's default 
                    // access level are not allowed. 
                    // These sharing records are not required and thus an insert exception is 
                    // acceptable. 
                    if(!(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  
                         &&  err.getMessage().contains('AccessLevel'))){
                             // Throw an error when the error is not related to trivial access level.
                             trigger.newMap.get(checklistShrs[i].ParentId).
                                 addError(
                                     'Unable to grant sharing access due to following exception: '
                                     + err.getMessage());
                         }
                }//if(!sr.isSuccess
                i++;
            }//for
        }//if(!checklistShrs.isEmpty
        if(!notificationList.isEmpty()){
            salesAnalystNotification(notificationList);
        }
    }//reassignChildrenToHaveSameOwnerNow
    
    public static void setDiscrepancyCounts(PEO_Onboarding_Checklist__c checklist,PEO_Onboarding_Checklist__c oldRec){
        if(checklist.Parent_PEO_Checklist__c == null && oldRec != null) {
            Decimal numMedDisc = (checklist.Number_of_Open_Medical_Discrepancies__c!=null ? checklist.Number_of_Open_Medical_Discrepancies__c:0);
            Decimal numRiskDisc = (checklist.Number_of_Open_Risk_Discrepancies__c!=null ? checklist.Number_of_Open_Risk_Discrepancies__c:0);
            Decimal numOfDiscrepancies = numMedDisc + numRiskDisc;
            
            Decimal oldNumMedDisc = (oldRec.Number_of_Open_Medical_Discrepancies__c!=null ? oldRec.Number_of_Open_Medical_Discrepancies__c:0);
            Decimal oldNumRiskDisc = (oldRec.Number_of_Open_Risk_Discrepancies__c!=null ? oldRec.Number_of_Open_Risk_Discrepancies__c:0);
            Decimal oldNumOfDiscrepancies = oldNumMedDisc + oldNumRiskDisc;
            
            if(numOfDiscrepancies > 0  && oldNumOfDiscrepancies == 0) {
                checklist.Most_Recent_Open_Discrepancy__c = DateTime.now();
            }
            else if(oldNumOfDiscrepancies > 0 && numOfDiscrepancies == 0) {
                checklist.Most_Recent_Open_Discrepancy__c = null;
            }
        }
    }//setDiscrepancyCounts
    
    public static Boolean saNotificationPosted = false;
    
    public static void salesAnalystNotification(PEO_Onboarding_Checklist__c[] checklists){        
        for(PEO_Onboarding_Checklist__c checklist:checklists){
            //Send chatters for each parent checklist
            Set<Id> mentionList = new Set<Id>();
            String header = 'Prospect '+checklist.Prospect_Client__r.Name+' is now ready for review.';
            String postText = '';
            if(String.isNotBlank(checklist.PEO_Sales_Notes__c)){
                postText = postText+ '\nSales Notes : '+checklist.PEO_Sales_Notes__c;
            }
            /*Start of changes by Srujan*/
            if(String.isNotBlank(checklist.Workers_Comp_Sales_Notes__c)){
                postText = postText+ '\nWorkers Comp Sales Notes : '+checklist.Workers_Comp_Sales_Notes__c;
            }
            if(String.isNotBlank(checklist.Financial_Underwriting_Sales_Notes__c)){
                postText = postText+ '\nFinancial Underwriting Sales Notes : '+checklist.Financial_Underwriting_Sales_Notes__c;
            }
            if(String.isNotBlank(checklist.Pricing_Console_Notes__c)){
                postText = postText+ '\nPricing Notes : '+checklist.Pricing_Console_Notes__c;
            }
            
            header = header + postText;
            /*End of changes by Srujan*/

            if(checklist.Sales_Rep__c != null) {
                mentionList.add(checklist.Sales_Rep__c);
            }
            if(checklist.Sales_Analyst__c != null) {
                mentionList.add(checklist.Sales_Analyst__c);
            }
            if(checklist.Sales_Analyst__c!=null && checklist.Sales_Analyst__r.ManagerId != null) {
                mentionList.add(checklist.Sales_Analyst__r.ManagerId);
            }
            /*if(checklist.PEO_NSC__c!=null){
                mentionList.add(checklist.PEO_NSC__c);
            }*/
            if(mentionList.size() > 0) {
                List<Id> mentList = new List<Id>();
                for (Id m : mentionList ) mentList.add(m);
                ChatterMentionPost.createChatterMentionPost(checklist.Id, mentList, new String[]{header},true,false);
                saNotificationPosted=true;
            }
        }
        ChatterMentionPost.postBatchFeedElements();
    }//salesAnalystNotification
    
    @future
    public static void sendDiscrepancyEmailFuture(List<Id> checklistIds){
        try {
            sendDiscrepancyEmailNow(checklistIds);    
        }Catch(Exception e) {
            communityMethods.logCommunityError(e, 'sendDiscrepancyEmailFuture', 'PEOOnboardingChecklist_Handler', '', null);
        }
    }
    
    @future
    public static void updateNewOpportyStageAfterUpdate(Set<id> oppIds){
        //Map<Id, Opportunity> mapIdToOpportunity = new Map<ID, Opportunity>([Select Id,Name,RecordType.Name, StageName from Opportunity where Id IN : oppIds AND (RecordType.DeveloperName = 'Prism_PEO_Opportunity_Record_Type' OR RecordType.DeveloperName = 'PEO_Opportunity_Record_Type') ]);
        Map<Id, Opportunity> mapIdToOpportunity = new Map<ID, Opportunity>([Select Id,Name,RecordType.Name, StageName from Opportunity where Id IN : oppIds AND (RecordType.DeveloperName = 'PEO_Opportunity_Record_Type') ]);
        for(Opportunity opp : mapIdToOpportunity.values()){
            if(opp.StageName == 'Qualified' || opp.StageName == 'Gained Access' || opp.StageName == 'IEUP'){
                opp.StageName = 'Discovery';                                
            }
            System.debug('opportunity update '+ opp.Name+ '---'+opp.StageName);
        }
        try{
            update mapIdToOpportunity.values();
        }
        catch(Exception e){
            System.debug('Error Updating opportunity stage from PEOOnboardingChecklist_Handler.updateNewOpportyStageAfterUpdate()'+e.getMessage() + '--'+e.getStackTraceString());
        }
    }
    
    public static void sendDiscrepancyEmailNow(List<Id> checklistIds){
        system.debug('MGF sendDiscrepancyEmail');
        if(checklistIds==null || checklistIds.size()==0)
            return ;
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Map<Id,PEO_Onboarding_Checklist__c> peoChecklistMap = new Map<Id,PEO_Onboarding_Checklist__c>
            ([SELECT Id, Name, OwnerId,Owner.Email, Owner.Name, RecordType.Name, Send_Discrepancy_Email__c, Sales_Rep__c, Sales_Rep__r.name, Sales_Rep__r.Email, 
              Prospect_Client__c,Prospect_Client__r.Name,Parent_PEO_Checklist__r.Prospect_Client__c,
              Current_Step__c, Abandoned_Status_Date__c, Completed_Status_Date__c, Discrepancies_Sent_Status_Date__c, In_Progress_Status_Date__c, 
              New_Submission_Status_Date__c, Reject_Sent_back_to_Sales_Status_Date__c, Sent_to_ClientSpace_Status_Date__c,Community_User__c,
              (SELECT Id, Discrepancy_Type__c, Discrepancy_Sub_Type__c, additional_information__c FROM PEO_Underwriting_Document_Discrepencies__r WHERE Status__c != 'Resolved')
              FROM PEO_Onboarding_Checklist__c
              WHERE id in : checklistIds]);
        
        EmailTemplate emailTemplate = [Select Id,Name,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where DeveloperName = 'Discrepancy_Email' LIMIT 1];
        OrgWideEmailAddress owea = [Select Id FROM OrgWideEmailAddress WHERE DisplayName = 'PEOSUPPORT_noreply@paychex.com' LIMIT 1];
        
        for(PEO_Onboarding_Checklist__c peoRec : peoChecklistMap.values()){
            
            if(peoRec.Sales_Rep__c!=null){
                //create chatter post
                Set<Id> mentionSet = new Set<Id>();
                String postText = 'One or more discrepancies have been posted for '+peoRec.Prospect_Client__r.Name+' for you';
             /*   if(peoRec.Send_Discrepancy_Email__c == 'Prospect'){
                    postText+=' and the prospect';
                    //send email to the prospect because they do not have chatter
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    message.setTargetObjectId(peoRec.Community_User__c);
                    message.setReplyTo(peoRec.Sales_Rep__r.Email);
                    message.setUseSignature(false); 
                    message.setBccSender(false); 
                    message.setSaveAsActivity(false); 
                    message.setTemplateID(emailTemplate.Id);
                    message.setOrgWideEmailAddressId(owea.Id);
                    mails.add(message);
                }   */ 
                postText+=' to review. Please navigate to the Getting Started Questionnaires Summary Tab from one of the contacts related to this client to view these discrepancies.';
                postText = addDiscrepancyDetailsToString(postText, peoRec.PEO_Underwriting_Document_Discrepencies__r);
                mentionSet.add(peoRec.Sales_Rep__c);
                /*if(String.isNotBlank(peoRec.PEO_NSC__c)){
                    mentionSet.add(peoRec.PEO_NSC__c);
                }*/
                List<Id> listMention = new List<Id>();
                for (Id i : mentionSet) listMention.add(i);
                postText += URL.getOrgDomainUrl().toExternalForm()+'/lightning/r/'+peoRec.Id+'/related/PEO_Underwriting_Document_Discrepencies__r/view';
                ChatterMentionPost.createChatterMentionPost(peoRec.Id, listMention, new String[]{postText},true,false);
            }
        }
        if(!test.isRunningTest()){
            try{
                system.debug('MGF Sending email');
                Messaging.sendEmail(mails);
                ChatterMentionPost.postBatchFeedElements();
            }
            catch(Exception e){
                System.debug('Error when sending out discrepancy emails. Expection: ' + e);
            }
        }
        List<Task> tskList = new List<Task>();
        for(PEO_Onboarding_Checklist__c peoRec : peoChecklistMap.values()){
            //Assigning as Task under the The checl=klist record's Sales Rep user about the alert.
            peoRec.Send_Discrepancy_Email__c = null; // nullifying the Discrepancy, as an alert has been sent.
            // if the discrepancy status date is null then we never set the status to discrepancy and             
            if (peoRec.Discrepancies_Sent_Status_Date__c == null) peoRec.Current_Step__c = 'Discrepancies Sent';
            if (peoRec.Discrepancies_Sent_Status_Date__c == null) peoRec.Discrepancies_Sent_Status_Date__c = system.now();
            Task tsk = new Task();
            tsk.Subject = 'Discrepancy Email Sent to prospect - ' +peoRec.Name;
            tsk.Status = 'Completed';
            tsk.Priority = 'Normal';
            tsk.WhatId = peoRec.ID;
            tsk.OwnerId = peoRec.Sales_Rep__c;
            tskList.add(tsk);
        }
        Try{
            system.debug('reset discrepancy and task creation');
            update peoChecklistMap.values();
            insert tskList;
        }
        catch(Exception e){
            System.debug('Error when updating checklists and inserting tasks. Expection: ' + e);
            CommunityMethods.logCommunityError(e, 'sendDiscrepancyEmailNow','PEOOnboardingChecklist_Handler', '', null);
        }
        
    }
    
    public static boolean medicalPreqSubmissionCheck(Map<id,PEO_Onboarding_Checklist__c> checklistIds){
        String peoDocPrefix = String.valueOf(PEO_Onboarding_Document__c.sobjecttype.getdescribe().getkeyprefix());
        List<Id> checklistNewMapIDs = new List<Id>();
        List<PEO_Onboarding_Checklist__c> checklistWithAck = new List<PEO_Onboarding_Checklist__c>();
        List<PEO_Onboarding_Checklist__c> checklistWithoutAck = new List<PEO_Onboarding_Checklist__c>();
        List<Id> questWithAck = new List<Id>();
        List<Id> questWithoutAck = new List<Id>();
        
        List<Id> checklistForAckIds = new List<Id>();
        List<PEO_Onboarding_Checklist__c> finalChecklistForAck = new List<PEO_Onboarding_Checklist__c>();
        List<PEO_Onboarding_Checklist__c> finalChecklistForError = new List<PEO_Onboarding_Checklist__c>();
        
        List<Id> peoDocIds = new List<Id>();
        Map<id,id> documentIds = new  Map<id,id>();
        List<Id> peoDocWithRecords = new List<Id>();
        for(PEO_Onboarding_Checklist__c checklist : checklistIds.values()) {
            checklistNewMapIDs.add(checklist.Id);
        }
        List<PEO_Onboarding_Medical_Questionnaire__c> medQuestionnaires = [SELECT Client_Id_user_agreement_acknowledgment__c,Id,Name,PEO_Onboarding_Checklist__c,PEO_Onboarding_Checklist__r.Id 
                                                                           FROM PEO_Onboarding_Medical_Questionnaire__c WHERE PEO_Onboarding_Checklist__r.ID IN:checklistNewMapIDs ];
        for(PEO_Onboarding_Medical_Questionnaire__c medQues : medQuestionnaires) {
            if(medQues.Client_Id_user_agreement_acknowledgment__c != null){
                questWithAck.add(medQues.PEO_Onboarding_Checklist__r.Id);
            }
            else{
                questWithoutAck.add(medQues.PEO_Onboarding_Checklist__r.Id);
            }
        }
        for(PEO_Onboarding_Checklist__c checklist : checklistIds.values()) {
            
            if(questWithAck.contains(checklist.Id)){
                checklistWithAck.add(checklist);
            }
            else{
                checklistWithoutAck.add(checklist);
            }
        }
        if(checklistWithoutAck.size()>0){
            for(PEO_Onboarding_Checklist__c checklist : checklistWithoutAck) {
                finalChecklistForError.add(checklist);
            }
        }
        system.debug('status:checklistWithAck'+checklistWithAck);
        system.debug('status:checklistWithoutAck'+checklistWithoutAck);
        if(checklistWithAck.size()>0){
            List<PEO_Onboarding_Document__c> peoList = [SELECT Id,PEO_Onboarding_Checklist__r.Id, Name,Parent_Account__c,PEO_Onboarding_Checklist__c,Prospect_Client_Name__c,Routing_Name__c,Status__c 
                                                        FROM PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c IN :checklistWithAck AND Status__c = 'Submitted to Clientspace'];
            system.debug('status:peoList'+peoList);
            for(PEO_Onboarding_Document__c peoDoc:peoList){
                if(peoDoc.Name == 'Census')peoDocIds.add(peoDoc.Id);
            }
            system.debug('status:peoDocIds'+peoDocIds);
            List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
            
            if(!peoDocIds.isEmpty()){
                cdLinkList = [SELECT ContentDocumentId,Id,IsDeleted,LinkedEntityId,ShareType,SystemModstamp,Visibility 
                                                    FROM ContentDocumentLink where LinkedEntityId IN :peoDocIds];
            }
            system.debug('status:cdLinkList'+cdLinkList);
            if(!cdLinkList.isEmpty()){
                for(ContentDocumentLink cdl:cdLinkList){  
                    String entityId = string.valueOf(cdl.LinkedEntityId);
                    system.debug('status:entityId:'+entityId);
                    if(entityId.startsWith(peoDocPrefix) && cdl.ContentDocumentId != null)documentIds.put(cdl.ContentDocumentId,cdl.LinkedEntityId);  
                }
                for(Id docId : documentIds.values()) {
                    for(PEO_Onboarding_Document__c peoDoc:peoList){
                        if(peoDoc.Id == docId){
                            checklistForAckIds.add(peoDoc.PEO_Onboarding_Checklist__r.Id);
                        }
                    }
                }
            }
            system.debug('status:checklistForAckIds:'+checklistForAckIds);
            for(PEO_Onboarding_Checklist__c checklist : checklistWithAck) {
                if(checklistForAckIds.contains(checklist.Id)){
                    finalChecklistForAck.add(checklist);
                }
                else{
                    finalChecklistForError.add(checklist);
                }
            }
        }
        
        system.debug('status:finalChecklistForAck:'+finalChecklistForAck);
        if(finalChecklistForAck.size()>0){
            for(PEO_Onboarding_Checklist__c checklist : finalChecklistForAck) {
                return true;
            }
        }
        if(finalChecklistForError.size()>0){
            for(PEO_Onboarding_Checklist__c checklist : finalChecklistForError) {
                if(checklist.Med_pre_qual_submission__c == true){
                    checklist.Med_pre_qual_submission__c = false;
                    checklist.Med_pre_qual_submission__c.addError('the medical questionnaire must be acknowledged, and the census submitted to clientspace prior to this box being checked');
                }
                return true;
            }
        }
        return null;
        
    }
    
    public static PEO_Onboarding_Checklist__c setAllRequiredDocuments(PEO_Onboarding_Checklist__c checklist,
                                                                      PEO_Medical_Workers_Comp_UW_Path__c reqDocs, Boolean flag,
                                                                      Map<Id, Boolean> docsMap){
        if(flag){
            if(checklist.Medical_Underwriting_Path_Type__c == 'Clientspace Forced - Medical'){
                //if(checklist.Workers_Comp_Quick_Quote_Eligibility__c == 'Full Underwriting Required'){
                	checklist.WCClassesWages_Required__c = reqDocs.WC_Classes_And_Wages_Required__c;
                    checklist.WC_RatesAndPricing_Required__c = reqDocs.WC_RatesAndPricing_Required__c;
                    checklist.Loss_Runs_Required__c = reqDocs.Loss_Runs_Required__c;
                    checklist.Miscellaneous_Docs_Required_WC__c = reqDocs.Miscellaneous_Docs_Required_WC__c;
                	checklist.Additional_Misc_Documents_Required__c = reqDocs.Additional_Misc_Documents_Required__c;
                	checklist.Miscellaneous_Docs_Required__c = reqDocs.Miscellaneous_Docs_Required_Medical__c;
                	checklist.Payroll_Register_Required__c = reqDocs.Payroll_Register_Required__c;
                	checklist.Additional_Misc_Documents_Required__c = reqDocs.Additional_Misc_Documents_Required__c;
                /*}else{
                    checklist.WCClassesWages_Required__c = false;
                    checklist.WC_RatesAndPricing_Required__c = false;
                    checklist.Loss_Runs_Required__c = false;
                    checklist.Miscellaneous_Docs_Required_WC__c = false;
                }*/
                //if(checklist.Medical_Quick_Quote_Eligibility__c == 'Full Underwriting Required'){
                    //checklist.WCClassesWages_Required__c = reqDocs.WC_Classes_And_Wages_Required__c;
                    if(checklist.CS_Benefits_Summaries_Required__c){
                        checklist.Benefit_Summaries_Required__c = true;
                    }else{
                        checklist.Benefit_Summaries_Required__c = false;
                    }
                    if(checklist.CS_Census_Required__c){
                        checklist.CensusRequired__c = true;
                    }else{
                        checklist.CensusRequired__c = false;
                    }
                    if(checklist.CS_Health_Insurance_Summary_Required__c){
                        checklist.Health_Insurance_Summary_required__c = true;
                    }else{
                        checklist.Health_Insurance_Summary_required__c = false;
                    }
                    if(checklist.CS_Health_Insurance_Renewal_Required__c){
                        checklist.Health_Insurance_Renewal_required__c = true;
                    }else{
                        checklist.Health_Insurance_Renewal_required__c = false;
                    }
                    if(checklist.CS_Claims_Report_Required__c){
                        checklist.Claims_Report_required__c = true;
                    }else{
                        checklist.Claims_Report_required__c = false;
                    }
                    if(checklist.CS_Medical_Invoice_Required__c){
                        checklist.Medical_Invoice_Required__c = true;
                    }else{
                        checklist.Medical_Invoice_Required__c = false;
                    }
                /*}else{
                    checklist.Benefit_Summaries_Required__c = false;
                    checklist.CensusRequired__c = false;
                    checklist.Health_Insurance_Summary_required__c = false;
                    checklist.Health_Insurance_Renewal_required__c = false;
                    checklist.Claims_Report_required__c = false;
                    checklist.Medical_Invoice_Required__c = false;
                }*/
            }else{
                //checklist.Additional_Misc_Documents_Required__c = isDocumentRequired(reqDocs.Additional_Misc_Documents_Required__c);
                checklist.Additional_Misc_Documents_Required__c = reqDocs.Additional_Misc_Documents_Required__c;
                checklist.Benefit_Summaries_Required__c = reqDocs.Benefit_Summaries_Required__c;
                checklist.CensusRequired__c = reqDocs.Census_Required__c;
                checklist.Miscellaneous_Docs_Required__c = reqDocs.Miscellaneous_Docs_Required_Medical__c;
                checklist.Claims_Report_Required__c = reqDocs.Claims_Report_Required__c;
                checklist.Health_Insurance_Renewal_Required__c = reqDocs.Health_Insurance_Renewal_Required__c;
                //checklist.Health_Insurance_Summary_Required__c = reqDocs.Health_Insurance_Summary_Required__c;
                checklist.Health_Invoice_Required__c = reqDocs.Health_Invoice_Required__c;
                checklist.Loss_Runs_Required__c = reqDocs.Loss_Runs_Required__c;
                checklist.Medical_Invoice_Required__c = reqDocs.Medical_Invoice_Required__c;
                checklist.Miscellaneous_Docs_Required_WC__c = reqDocs.Miscellaneous_Docs_Required_WC__c;
                checklist.Payroll_Register_Required__c = reqDocs.Payroll_Register_Required__c;
                //checklist.Payroll_Report_Required__c = reqDocs.Payroll_Report_Required__c;
                checklist.SUI_Required__c = reqDocs.SUI_Required__c;
                checklist.WCClassesWages_Required__c = reqDocs.WC_Classes_And_Wages_Required__c;
                checklist.WC_Declarations_Required__c = reqDocs.WC_Declarations_Required__c;
                checklist.WC_RatesAndPricing_Required__c = reqDocs.WC_RatesAndPricing_Required__c;
            }
        }else{
            if(!checklist.Additional_Misc_Documents_Required__c) checklist.Additional_Misc_Documents_Required__c = reqDocs.Additional_Misc_Documents_Required__c;
            if(!checklist.Benefit_Summaries_Required__c) checklist.Benefit_Summaries_Required__c = reqDocs.Benefit_Summaries_Required__c;
            if(!checklist.CensusRequired__c) checklist.CensusRequired__c = reqDocs.Census_Required__c;
            if(!checklist.Miscellaneous_Docs_Required__c) checklist.Miscellaneous_Docs_Required__c = reqDocs.Miscellaneous_Docs_Required_Medical__c;
            if(!checklist.Claims_Report_Required__c) checklist.Claims_Report_Required__c = reqDocs.Claims_Report_Required__c;
            if(!checklist.Health_Insurance_Renewal_Required__c) checklist.Health_Insurance_Renewal_Required__c = reqDocs.Health_Insurance_Renewal_Required__c;
            //if(!checklist.Health_Insurance_Summary_Required__c) checklist.Health_Insurance_Summary_Required__c = reqDocs.Health_Insurance_Summary_Required__c;
            if(!checklist.Health_Invoice_Required__c) checklist.Health_Invoice_Required__c = reqDocs.Health_Invoice_Required__c;
            if(!checklist.Loss_Runs_Required__c) checklist.Loss_Runs_Required__c = reqDocs.Loss_Runs_Required__c;
            if(!checklist.Medical_Invoice_Required__c) checklist.Medical_Invoice_Required__c = reqDocs.Medical_Invoice_Required__c;
            if(!checklist.Miscellaneous_Docs_Required_WC__c) checklist.Miscellaneous_Docs_Required_WC__c = reqDocs.Miscellaneous_Docs_Required_WC__c;
            if(!checklist.Payroll_Register_Required__c) checklist.Payroll_Register_Required__c = reqDocs.Payroll_Register_Required__c;
            //if(!checklist.Payroll_Report_Required__c) checklist.Payroll_Report_Required__c = reqDocs.Payroll_Report_Required__c;
            if(!checklist.SUI_Required__c) checklist.SUI_Required__c = reqDocs.SUI_Required__c;
            if(!checklist.WCClassesWages_Required__c){
                if(checklist.Workers_Comp_Quick_Quote_Eligibility__c != '' && checklist.Workers_Comp_Quick_Quote_Eligibility__c != null){
                    if(!docsMap.isEmpty()){
                        if(docsMap.get(checklist.Id)){
                            checklist.WCClassesWages_Required__c = true;
                        }else{
                            checklist.WCClassesWages_Required__c = false;
                        }
                    }else{
                        checklist.WCClassesWages_Required__c = false;
                    }
                }else{
                    checklist.WCClassesWages_Required__c = reqDocs.WC_Classes_And_Wages_Required__c;
                }
            }
            //if(!checklist.WCClassesWages_Required__c) checklist.WCClassesWages_Required__c = reqDocs.WC_Classes_And_Wages_Required__c;
            if(!checklist.WC_Declarations_Required__c) checklist.WC_Declarations_Required__c = reqDocs.WC_Declarations_Required__c;
            if(!checklist.WC_RatesAndPricing_Required__c) checklist.WC_RatesAndPricing_Required__c = reqDocs.WC_RatesAndPricing_Required__c;
        }
        
        if(checklist.medical_coverage_renewal_date__c != null){
            Date renDate = checklist.medical_coverage_renewal_date__c;
            Date currentDate = Date.today();
            Integer diffDays;
            diffDays = currentDate.daysBetween(renDate);
            if(checklist.Currently_using_a_PEO__c == 'Yes'){
                if(checklist.Health_Insurance_Renewal_required__c && diffDays < 90 && diffDays >= -90){
                    checklist.Health_Insurance_Renewal_required__c = true;
                }else{
                    checklist.Health_Insurance_Renewal_required__c = false;
                }
            }else if(checklist.Currently_using_a_PEO__c == 'No'){
                if(checklist.Health_Insurance_Renewal_required__c && diffDays < 60 && diffDays >= -60){
                    checklist.Health_Insurance_Renewal_required__c = true;
                }else{
                    checklist.Health_Insurance_Renewal_required__c = false;
                }
            }
            
        }else{
            checklist.Health_Insurance_Renewal_required__c = false;
        }
        
        return checklist;
    }
    
    
    
    public static PEO_Onboarding_Checklist__c setRequiredDocumentsMedical(PEO_Onboarding_Checklist__c checklist, PEO_Medical_Workers_Comp_UW_Path__c reqDocs){
        
        setAllRequiredDocuments(checklist, reqDocs, true, null);
        
        switch on checklist.Medical_Underwriting_Path_Type__c{
            when 'Clientspace Forced - Medical'{
                /*if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote' && 
                   checklist.Is_Medical_Underwriting_Requested__c != 'Currently does not have Medical, please quote'){
                    checklist.CensusRequired__c = false;                    
                }
                if(checklist.Is_Your_Plan_Self_Funded_or_Level_Funded__c != 'Yes' || checklist.Parent_PEO_Checklist__c != null){
                    checklist.Claims_Report_Required__c = false;
                }
                if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote'){
                	checklist.Medical_Invoice_Required__c = false;
                    checklist.Benefit_Summaries_Required__c = false;
                }*/
            }
            when 'Quick Quote - Medical'{
                if((checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote' && 
                    checklist.Is_Medical_Underwriting_Requested__c != 'Currently does not have Medical, please quote') || checklist.Parent_PEO_Checklist__c != null){	
                    checklist.CensusRequired__c = false;	
                }	
                if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote' || checklist.Parent_PEO_Checklist__c != null){	
                    checklist.Medical_Invoice_Required__c = false;	
                }	
                if(checklist.Parent_PEO_Checklist__c != null){	
                    checklist.WCClassesWages_Required__c = false;	
                }
            }
            when 'Salesforce Forced - Medical'{
                if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote' && 
                   checklist.Is_Medical_Underwriting_Requested__c != 'Currently does not have Medical, please quote'){
                    checklist.CensusRequired__c = false;
                    checklist.Miscellaneous_Docs_Required__c = false;
                }
                if(checklist.Is_Your_Plan_Self_Funded_or_Level_Funded__c != 'Yes' || checklist.Parent_PEO_Checklist__c != null){
                    checklist.Claims_Report_Required__c = false;
                }
                if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote'){
                	checklist.Medical_Invoice_Required__c = false;
                    checklist.Benefit_Summaries_Required__c = false;
                }
            }
            when 'Traditional - Medical'{
                if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote' && 
                   checklist.Is_Medical_Underwriting_Requested__c != 'Currently does not have Medical, please quote'){
                    checklist.CensusRequired__c = false;
                    checklist.Miscellaneous_Docs_Required__c = false;
                }
                if(checklist.Is_Your_Plan_Self_Funded_or_Level_Funded__c != 'Yes' || checklist.Parent_PEO_Checklist__c != null){
                    checklist.Claims_Report_Required__c = false;
                }
                if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote'){
                	checklist.Medical_Invoice_Required__c = false;
                    checklist.Benefit_Summaries_Required__c = false;
                }
            }
            
        }	//end Switch
        
        return checklist;
    }
    
    public static PEO_Onboarding_Checklist__c setRequiredDocumentsWorkersComp(PEO_Onboarding_Checklist__c checklist, PEO_Medical_Workers_Comp_UW_Path__c reqDocs,
                                                                              Map<Id, Boolean> docsMap){
        /*
        if(checklist.Medical_Underwriting_Path_Type__c == null || checklist.Medical_Underwriting_Path_Type__c == ''){
            setAllRequiredDocuments(checklist, reqDocs, true);
        }else{
            setAllRequiredDocuments(checklist, reqDocs, false);
        }
        */
        setAllRequiredDocuments(checklist, reqDocs, false, docsMap);
        system.debug('WC Path: ' +checklist.Workers_Comp_Underwriting_Path_Type__c);
                                                                                  
        switch on checklist.Workers_Comp_Underwriting_Path_Type__c{
            when 'Clientspace Forced - Workers Comp'{
             
                if(reqDocs.Additional_Misc_Documents_Required__c )
                    	checklist.Additional_Misc_Documents_Required__c=true;
                
                if(reqDocs.Benefit_Summaries_Required__c)
                {
                    if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote'){
                	
                    }
                    else 
                        checklist.Benefit_Summaries_Required__c=true;
                }
                
                
                if(reqDocs.Census_Required__c){
                    	if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote' && 
                   			checklist.Is_Medical_Underwriting_Requested__c != 'Currently does not have Medical, please quote'){                   
                			
                         	}
                    	else
                			checklist.CensusRequired__c = true ;	
                }
                if(reqDocs.Miscellaneous_Docs_Required_Medical__c){
                	if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote' && 
                   			checklist.Is_Medical_Underwriting_Requested__c != 'Currently does not have Medical, please quote'){                   
                			
                         	}
                    	else    	                
                			checklist.Miscellaneous_Docs_Required__c=true;               
                }
                if(reqDocs.Claims_Report_Required__c){
                    if(checklist.Is_Your_Plan_Self_Funded_or_Level_Funded__c != 'Yes' || checklist.Parent_PEO_Checklist__c != null){
                        
                    } 
                    else
                        checklist.Claims_Report_Required__c = true;
                }
                	
                
                if(reqDocs.Health_Insurance_Renewal_Required__c)
                	checklist.Health_Insurance_Renewal_Required__c = true;
                
                if(reqDocs.Health_Invoice_Required__c)
                	checklist.Health_Invoice_Required__c = true;
                
                if(reqDocs.Loss_Runs_Required__c)
                	checklist.Loss_Runs_Required__c = true;
                
                if(reqDocs.Medical_Invoice_Required__c)
                {
					if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote'){
                	                }
                    else 
                        checklist.Medical_Invoice_Required__c=true;
                    }
                
                if(reqDocs.Miscellaneous_Docs_Required_WC__c)
                	checklist.Miscellaneous_Docs_Required_WC__c = true;
                
                if(reqDocs.Payroll_Register_Required__c)
                	checklist.Payroll_Register_Required__c = true;
                
                if(reqDocs.SUI_Required__c)
                	checklist.SUI_Required__c =true ;
                
                if(reqDocs.WC_Classes_And_Wages_Required__c)
               	 	checklist.WCClassesWages_Required__c = true;
                
                if(reqDocs.WC_Declarations_Required__c)
                	checklist.WC_Declarations_Required__c = true;
                
                if(reqDocs.WC_RatesAndPricing_Required__c)
                	checklist.WC_RatesAndPricing_Required__c = true;
            }
            when 'Quick Quote - Workers Comp'{
            }
            when 'Salesforce Forced - Workers Comp'{
                if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote' && 
                   checklist.Is_Medical_Underwriting_Requested__c != 'Currently does not have Medical, please quote'){
                    checklist.CensusRequired__c = false;
                    checklist.Miscellaneous_Docs_Required__c = false;
                }
                if(checklist.Is_Your_Plan_Self_Funded_or_Level_Funded__c != 'Yes' || checklist.Parent_PEO_Checklist__c != null){
                    checklist.Claims_Report_Required__c = false;
                }
                if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote'){
                	checklist.Medical_Invoice_Required__c = false;
                    checklist.Benefit_Summaries_Required__c = false;
                }
            }
            when 'Traditional - Workers Comp'{
                if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote' && 
                   checklist.Is_Medical_Underwriting_Requested__c != 'Currently does not have Medical, please quote'){
                    checklist.CensusRequired__c = false;
                    checklist.Miscellaneous_Docs_Required__c = false;
                }
                if(checklist.Is_Your_Plan_Self_Funded_or_Level_Funded__c != 'Yes' || checklist.Parent_PEO_Checklist__c != null){
                    checklist.Claims_Report_Required__c = false;
                }
                if(checklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote'){
                	checklist.Medical_Invoice_Required__c = false;
                    checklist.Benefit_Summaries_Required__c = false;
                }
            }
        }
        return checklist;
    }
    
    //Added by Srujan
    public static Map<Id, Boolean> getUploadedDocs(Set<Id> checkListIds){
        List<PEO_Onboarding_Document__c> docs = new List<PEO_Onboarding_Document__c>();
        Map<Id, Boolean> docsMap = new Map<Id, Boolean>();
        docs = [SELECT Id, Name, PEO_Onboarding_Checklist__c FROM PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c =: checkListIds AND
                Name = 'WC Classes and Wages'];
        if(docs.size() > 0){
            Set<Id> docId = new Set<Id>();
            for(PEO_Onboarding_Document__c doc : docs){
                docId.add(doc.Id);
            }
            Map<String, ContentDocumentLink> mapCDL = new Map<String, ContentDocumentLink>();
            List<ContentDocumentLink> contentDocLink = new List<ContentDocumentLink>();
            contentDocLink = [SELECT id, LinkedEntityId, LinkedEntity.name FROM ContentDocumentLink  WHERE LinkedEntityId IN : docId];
            if(contentDocLink.size() > 0){
                for(ContentDocumentLink cdl : contentDocLink){
                    mapCDL.put(cdl.LinkedEntityId, cdl);
                }
                for(PEO_Onboarding_Document__c doc : docs){
                    if(mapCDL.get(doc.Id) == NULL){
                        docsMap.put(doc.PEO_Onboarding_Checklist__c, false);
                    }else{
                        docsMap.put(doc.PEO_Onboarding_Checklist__c, true);
                    }
                }
            }
        }
        return docsMap;
    }
    
    @AuraEnabled  
    public static void updateDocReqdStatus(List<PEO_Onboarding_Checklist__c> checkListBeforeInsert, Map<id,PEO_Onboarding_Checklist__c> checkListBeforeUpdate, Map<id,PEO_Onboarding_Checklist__c> checkListBeforeUpdateOld){ 
        
        
        // SFDC-10012: checklsit ID to doc names list to store all docs to be inserted/verified
        // as existing for eacch cheklist
        List<PEO_Onboarding_Document__c> docToInsert = new List<PEO_Onboarding_Document__c>();
        /*Map<Id, Map<String,PEO_Onboarding_Document__c>> chkID_to_documentListMap = new Map<Id, Map<String,PEO_Onboarding_Document__c>>();
        // create the flags to track whih docs are required
        // also create the map to store the doc names to be inserted/verified
        Boolean censusRequired = false;
        Boolean medBenUnderwritingRequested = false;
        Boolean curMedCoverageProvided = false;
        Boolean hasSelfOrLevelFundedPlans= false;
        Boolean inRenewalTimeframe = false;
        Boolean numberOfEmployeesLessThanVerified= false;
        Boolean numberOfEmployeesGreaterThanVerified = false;
        Boolean hasClaims= false;
        Map<id,PEO_Onboarding_Medical_Questionnaire__c> medqMap = new Map<id,PEO_Onboarding_Medical_Questionnaire__c>();
        List<Id> accIds = new List<Id>();
        List<Id> cListIds = new List<Id>();
        // if there are no checklists to be inserted and there are checklists to be updated
        // iterate the checklist to be updated and add their IDs to checkLists id list
        // otherwise assign the checklists list to the passed in checkListBeforeInsert
        */
        
        List<PEO_Onboarding_Checklist__c> checkLists = new List<PEO_Onboarding_Checklist__c>();
        List<String> pathType = new List<String>();
        Boolean isInsert = false;
        Set<Id> checkListIds = new Set<Id>();
        if(checkListBeforeInsert.size() == 0 && checkListBeforeUpdate.size() >0){
            for(PEO_Onboarding_Checklist__c cl : checkListBeforeUpdate.values()) {
                //JDA SPA add the logic to prevent checkbox update here:start
                //Need to be handled only during an update operation
                System.debug('JDA SPA updateDocReqdStatus cl:'+cl);
               // if(cl.Medical_Quick_Quote_Eligibility__c != 'Full Underwriting Required' 
               //    && cl.Workers_Comp_Quick_Quote_Eligibility__c != 'Full Underwriting Required'){
               
                System.debug('Update the required checkboxes based on custom settings here');
                checkLists.add(cl);
                system.debug('++ med path ' + cl.Medical_Underwriting_Path_Type__c);
                system.debug('++ wc path ' + cl.Workers_Comp_Underwriting_Path_Type__c);
                if(cl.Medical_Underwriting_Path_Type__c != null && cl.Medical_Underwriting_Path_Type__c != ''){
                       pathType.add(cl.Medical_Underwriting_Path_Type__c);
                   }
                if(cl.Workers_Comp_Underwriting_Path_Type__c != null && cl.Workers_Comp_Underwriting_Path_Type__c != ''){
                    pathType.add(cl.Workers_Comp_Underwriting_Path_Type__c);
                    checkListIds.add(cl.Id);
                }
               // }
               /* if(cl.Medical_Quick_Quote_Eligibility__c == 'Full Underwriting Required' 
                   || cl.Workers_Comp_Quick_Quote_Eligibility__c == 'Full Underwriting Required'){
                    	cl.Additional_Misc_Documents_Required__c=true;
                    	cl.Miscellaneous_Docs_Required_WC__c=true;
                    	cl.Miscellaneous_Docs_Required__c=true;                      	
                }*/
                //JDA SPA add the logic to prevent checkbox update here:end
            }
        }
        else{
            isInsert = true;
            for(PEO_Onboarding_Checklist__c cl : checkListBeforeInsert) {
                system.debug('++path ' + cl.Medical_Underwriting_Path_Type__c);
                if(cl.Medical_Underwriting_Path_Type__c != null && cl.Medical_Underwriting_Path_Type__c != ''){
                    pathType.add(cl.Medical_Underwriting_Path_Type__c);
                }
                if(cl.Workers_Comp_Underwriting_Path_Type__c != null && cl.Workers_Comp_Underwriting_Path_Type__c != ''){
                    pathType.add(cl.Workers_Comp_Underwriting_Path_Type__c);
                }
                
            }
            checkLists = checkListBeforeInsert;
        }
        system.debug('++ pathType'+pathType);
        if(pathType.size() > 0){
            Map<Id, Boolean> docsMap = new Map<Id, Boolean>();
            if(checkListIds.size() > 0){
                docsMap = getUploadedDocs(checkListIds);
            }
            List<PEO_Medical_Workers_Comp_UW_Path__c> reqDocuments = new List <PEO_Medical_Workers_Comp_UW_Path__c>();
            reqDocuments = [SELECT Id, Name, Additional_Misc_Documents_Required__c, Benefit_Summaries_Required__c, Census_Required__c, Claims_Report_Required__c, Health_Insurance_Renewal_Required__c, 
                           Health_Invoice_Required__c, Loss_Runs_Required__c, Medical_Invoice_Required__c, Miscellaneous_Docs_Required_Medical__c, 
                           Miscellaneous_Docs_Required_WC__c, Payroll_Register_Required__c, SUI_Required__c, WC_Classes_And_Wages_Required__c, WC_Declarations_Required__c, 
                           WC_RatesAndPricing_Required__c FROM PEO_Medical_Workers_Comp_UW_Path__c WHERE Name IN: pathType];
            if(reqDocuments.size() > 0){
                system.debug('req');
                Map<String, PEO_Medical_Workers_Comp_UW_Path__c> reqDocsMap = new Map<String, PEO_Medical_Workers_Comp_UW_Path__c>();
                for(PEO_Medical_Workers_Comp_UW_Path__c docs : reqDocuments){
                    reqDocsMap.put(docs.Name, docs);
                }
                system.debug('++'+reqDocsMap);
                for(PEO_Onboarding_Checklist__c checklist:checkLists){
                    if(isInsert){
                        system.debug('++if');
                        if(reqDocsMap.get(checklist.Medical_Underwriting_Path_Type__c) != null){
                            checklist = setRequiredDocumentsMedical(checklist, reqDocsMap.get(checklist.Medical_Underwriting_Path_Type__c));
                        }
                        if(reqDocsMap.get(checklist.Workers_Comp_Underwriting_Path_Type__c) != null){
                           // checklist = setRequiredDocumentsWorkersComp(checklist, reqDocsMap.get(checklist.Workers_Comp_Underwriting_Path_Type__c));
                            checklist = setRequiredDocumentsWorkersComp(checklist, reqDocsMap.get(checklist.Workers_Comp_Underwriting_Path_Type__c), docsMap);
                        }
                        
                        
                    }else if(checkListBeforeUpdateOld.get(checklist.Id) != checkListBeforeUpdate.get(checklist.Id)){
                        system.debug('++else');
                        system.debug('++ final check'+reqDocsMap.get(checklist.Medical_Underwriting_Path_Type__c));
                        if(reqDocsMap.get(checklist.Medical_Underwriting_Path_Type__c) != null){
                            checklist = setRequiredDocumentsMedical(checklist, reqDocsMap.get(checklist.Medical_Underwriting_Path_Type__c));
                        }
                        if(reqDocsMap.get(checklist.Workers_Comp_Underwriting_Path_Type__c) != null){
                            checklist = setRequiredDocumentsWorkersComp(checklist, reqDocsMap.get(checklist.Workers_Comp_Underwriting_Path_Type__c), docsMap);
                        }
                    }
                }
                //createUnderwritingDocuments(checkLists, reqDocsMap);
            }
        }
        /*
        // if the cheklist list has been populated with some records
        // iterate them and add each checklist ID to the cListIds list
        if(checkLists.size()>0){
            for(PEO_Onboarding_Checklist__c checklist:checkLists){
                if(checklist.Id != Null){
                    cListIds.add(checklist.Id);
                }
                if(checklist.Prospect_Client__c!=null){
                    accIds.add(checklist.Prospect_Client__c );
                }
            }
        }
        
        // Query the accounts using the accIds list
        // map of acc ID to account
        Map<id,Account> accMap = new Map<id,Account>([SELECT Id, isChild__c,ShippingState, isParent__c, SalesParent__c FROM Account WHERE Id IN:accIds]);
        List<PEO_Onboarding_Medical_Questionnaire__c> medQuestnrs = new List<PEO_Onboarding_Medical_Questionnaire__c>();
        
        // if the checklist ids are not blank get the medical questionnaires
        if(cListIds.size()>0){
            medQuestnrs = [SELECT claims_exp_available__c,Id,Name,PEO_Onboarding_Checklist__c FROM PEO_Onboarding_Medical_Questionnaire__c WHERE PEO_Onboarding_Checklist__c IN: cListIds];
        }
        
        // the med questionnairs retrieved aren't empty add the id to questionnaire map to medqMap
        if(medQuestnrs.size()>0){
            for(PEO_Onboarding_Medical_Questionnaire__c medq: medQuestnrs){
                medqMap.put(medq.Id, medq);
            }
        }
        
        // iterate all of the  in checkLists
        for(PEO_Onboarding_Checklist__c cList:checkLists){
            Map<String, PEO_Onboarding_Document__c> docMapForChk = chkID_to_documentListMap.get(cList.Id);
            if (docMapForChk == null) {
                docMapForChk = new Map<String, PEO_Onboarding_Document__c>();
            }
            
            // set the census & medBenUnderwritingRequested to true if medical is requested
            // otherwise if the experience is oasis always require the census
            // otherwise set both to false
            if(cList.Medical_Benefits_Underwriting_Requested__c == 'Yes'){
                medBenUnderwritingRequested = true;
                censusRequired = true;
            }
            //*else if(cList.Experience__c != null && cList.Experience__c == 'Oasis') {
             //   censusRequired = true;  
            //}
            else{
                censusRequired = false;
                medBenUnderwritingRequested = false;
            }
            
            // set curMedCoverageProvided to true if they say so
            if(cList.Current_Medical_Coverage_Provided__c == 'Yes') {
                curMedCoverageProvided = true;
            }
            
            // set hasSelfOrLevelFundedPlans if they say so
            if(cList.Has_Self_or_Level_Funded_Plan__c == 'Yes') {
                hasSelfOrLevelFundedPlans = true;
            }
            // create a shipping state tracker
            String accountShippingState = '';
            // iterate the acccount ids in accIds
            // if the cheklist has a prospect lient & the ac id matches the chk prospect ID
            // get the account. 
            // if the shipping state is populated on the account then set the shippingstatetraccker to the saved value
            Account acct = (cList.Prospect_Client__c!= null && accMap!=null && accMap.containsKey(cList.Prospect_Client__c) ? accMap.get(cList.Prospect_Client__c) : null);
            if(acct!=null && acct.ShippingState!=null){
                accountShippingState = acct.ShippingState;
            }
            
            Integer numEmployees = (Integer)cList.Number_of_Enrolled_Employees__c;
            
            // if the shipping is texas and they've got more than 49 employees set the numberOfEmployeesGreaterThanVerified to true
            // otherwise if they're in California and they've got more than 299 emps set the numberOfEmployeesGreaterThanVerified to true
            // otherwise if they're not in ccalifornia and not in texas and they've got more than 99 emps set the numberOfEmployeesGreaterThanVerified to true
            if((accountShippingState == 'Texas' || accountShippingState == 'TX') &&  numEmployees >= 50) {
                numberOfEmployeesGreaterThanVerified = true;
            } else if((accountShippingState == 'California' || accountShippingState == 'CA') &&  numEmployees >= 300) {
                numberOfEmployeesGreaterThanVerified = true;
            } else if(accountShippingState != 'California' && accountShippingState != 'CA' && accountShippingState != 'Texas' && accountShippingState != 'TX' && numEmployees >= 100) {
                numberOfEmployeesGreaterThanVerified = true;
            }
            
            // if there are medical questionnaires iterate them
            // if they indicate they've got claims on medical set hasclaims to true
            if(medqMap.size() >0){
                for(PEO_Onboarding_Medical_Questionnaire__c mqs: medqMap.values()){
                    if(mqs.PEO_Onboarding_Checklist__c == cList.Id && mqs.claims_exp_available__c == 'Yes'){
                        hasClaims = true;
                    }
                }
            }
            
            String healthBenThroughPEO = cList.Health_Benefits_Currently_through_a_PEO__c;
            Date renewalDate = cList.medical_coverage_renewal_date__c;
            
            Integer diffDays;
            if(renewalDate != null){
                Date renDate = renewalDate;
                Date currentDate = Date.today();
                diffDays = currentDate.daysBetween(renDate);
            }
            System.debug('cList.Health_Benefits_Currently_through_a_PEO__c:'+cList.Health_Benefits_Currently_through_a_PEO__c);
            System.debug('diffDays:'+diffDays);
            // if their Health_Benefits_Currently_through_a_PEO__c == yes && the renewal date is less than 90 days in the future set inRenewalTimeframe to true
            if(cList.Health_Benefits_Currently_through_a_PEO__c != null && cList.Health_Benefits_Currently_through_a_PEO__c == 'Yes' && diffDays < 90 && diffDays >= 0){
                System.debug('Updating inRenewalTimeframe to true: not through peo but within 90 days');
                inRenewalTimeframe = true;
            }
            
            // if theur health benefits are not through PEO and the renewal date is less than t60 days in the future set inRenewalTimeframe to true
            if(cList.Health_Benefits_Currently_through_a_PEO__c != null && cList.Health_Benefits_Currently_through_a_PEO__c == 'No' && diffDays < 60 && diffDays >= 0){
                System.debug('Updating inRenewalTimeframe to true: not through peo but within 60 days');
                inRenewalTimeframe = true;
            }
            
            // if the census is required
            // set the census required field to false
            // if the cchecklist is the parent checklist set the census required to true\
            // Add the census to the list of docs to be created for this cheklist
            // otherwise set the census required to false
            if(censusRequired){
                cList.CensusRequired__c = false;
                if(cList.Parent_PEO_Checklist__c == Null){
                    cList.CensusRequired__c = true;
                    docMapForChk.put('Census', new PEO_Onboarding_Document__c(name='Census', PEO_Onboarding_Checklist__c=cList.Id, Routing_Name__c='Census'));
                }
            }
            else{
                cList.CensusRequired__c = false;
            }
            
            //if they've requested medical and indicated they've got current coverage
            //set the health invoice to be required and the health insurancce summary to be required
            //also add each do names to the list for this checklist
            //otherwise set them to false
            if(medBenUnderwritingRequested && curMedCoverageProvided){
                cList.Health_Invoice_required__c = true;
                cList.Health_Insurance_Summary_required__c = true;
                docMapForChk.put('Health Invoice', new PEO_Onboarding_Document__c(name='Health Invoice', PEO_Onboarding_Checklist__c=cList.Id, Routing_Name__c='Health Invoice'));
                docMapForChk.put('Health Insurance Summary', new PEO_Onboarding_Document__c(name='Health Insurance Summary', PEO_Onboarding_Checklist__c=cList.Id, Routing_Name__c='Health Insurance Summary'));
            }
            else{
                cList.Health_Invoice_required__c = false;
                cList.Health_Insurance_Summary_required__c = false;
            }
            
            // if medical is requested and they've got current coverage and they're within the renewal time freame
            // set Health_Insurance_Renewal_required__c to true and add the renewal doc to the list of docs
            // to insert/berify existence
            if(medBenUnderwritingRequested && (curMedCoverageProvided && inRenewalTimeframe)){
                docMapForChk.put('Health Insurance Renewal', new PEO_Onboarding_Document__c(name='Health Insurance Renewal', PEO_Onboarding_Checklist__c=cList.Id, Routing_Name__c='Health Insurance Renewal'));
                cList.Health_Insurance_Renewal_required__c = true;
            }
            else{
                cList.Health_Insurance_Renewal_required__c = false;
            }
            
            // if they're not requesting fastpass set loss runs to be required and add loss runs to the list of doccs to verify existencec
            // otherwise set it to false
            if(cList.Workers_Comp_FastPass__c == 'No' || cList.Workers_Comp_FastPass__c == Null){
                docMapForChk.put('WC Loss Runs', new PEO_Onboarding_Document__c(name='Loss Runs', PEO_Onboarding_Checklist__c=cList.Id, Routing_Name__c='WC Loss Runs'));
                cList.Loss_Runs_required__c = true;
            }
            else{
                cList.Loss_Runs_required__c = false;
            }
            
            // if they've got self/level funded or they've requested medical while having overage that is in the renewal timeframe with either the right number of employees or has claims
            // set cclaims required to true and add laims to the list of docs to be verified
            // otherwise set cclaims required to false
            if(hasSelfOrLevelFundedPlans||(medBenUnderwritingRequested &&(curMedCoverageProvided&&(inRenewalTimeframe &&(numberOfEmployeesGreaterThanVerified || hasClaims))))){
                cList.Claims_Report_required__c = true;
                docMapForChk.put('Claims Information', new PEO_Onboarding_Document__c(name='Claims Report', PEO_Onboarding_Checklist__c=cList.Id, Routing_Name__c='Claims Information'));
            }
            else{
                cList.Claims_Report_required__c = false;
            }
            
            //if the user selects YES to the Health_Benefits_Currently_through_a_PEO__c then WC Pricing is true and WC Decl is False and vice versa
            if(cList.Health_Benefits_Currently_through_a_PEO__c != null && cList.Health_Benefits_Currently_through_a_PEO__c == 'Yes'){
                cList.WC_RatesAndPricing_Required__c = true;
                cList.WC_Declarations_Required__c = false;
            }
            else{
                cList.WC_Declarations_Required__c = true;
                cList.WC_RatesAndPricing_Required__c = false;
            }
            // these dos are always either required or not
            // They should always be created so add each doc to the list of docs to verify for this checklist
            cList.WCClassesWages_Required__c = true;
            cList.SUI_Required__c = true;
            cList.Payroll_Register_Required__c = false;
            cList.Miscellaneous_Docs_Required__c = false;
            cList.Miscellaneous_Docs_Required_WC__c = false;
            docMapForChk.put('WC Declarations Page', new PEO_Onboarding_Document__c(name='WC Declarations Page/PEO Current Rate', PEO_Onboarding_Checklist__c=cList.Id, Routing_Name__c='WC Declarations Page'));
            docMapForChk.put('WC Classes and Wages', new PEO_Onboarding_Document__c(name='WC Classes and Wages', PEO_Onboarding_Checklist__c=cList.Id, Routing_Name__c='WC Classes and Wages'));
            docMapForChk.put('WC Rates and Pricing', new PEO_Onboarding_Document__c(name='WC Rates and Pricing', PEO_Onboarding_Checklist__c=cList.Id, Routing_Name__c='WC Rates and Pricing'));
            docMapForChk.put('SUI Rate Forms', new PEO_Onboarding_Document__c(name='SUI Rate Forms', PEO_Onboarding_Checklist__c=cList.Id, Routing_Name__c='SUI Rate Forms'));
            docMapForChk.put('Payroll Register', new PEO_Onboarding_Document__c(name='Payroll Register', PEO_Onboarding_Checklist__c=cList.Id, Routing_Name__c='Payroll Register'));
            docMapForChk.put('Other Med', new PEO_Onboarding_Document__c(name='Misc Files - Medical', PEO_Onboarding_Checklist__c=cList.Id, Routing_Name__c='Other Med'));
            docMapForChk.put('Other WC', new PEO_Onboarding_Document__c(name='Misc Files - Workers\' Comp', PEO_Onboarding_Checklist__c=cList.Id, Routing_Name__c='Other WC'));
        }
        
        // get all the doument records for the checklists in the chkID_to_documentListMap key set
        List<PEO_Onboarding_Document__c> existingPeoDocs = [Select Id, routing_Name__c, Name, PEO_Onboarding_Checklist__c FROM PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c IN :chkID_to_documentListMap.keySet()];

        // traverse the returned doc & remove all docs from the chkID_to_documentListMap that already exist
        for (PEO_Onboarding_Document__c doc : existingPeoDocs) {
            Map<String, PEO_Onboarding_Document__c> docMapForCHK = chkID_to_documentListMap.get(doc.PEO_Onboarding_Checklist__c);
            // get the checklist map using the checklist ID on the returned map
            // remove the already existing doc from the map
            if (docMapForCHK != null && docMapForCHK.get(doc.Routing_Name__c) != null) {
                System.debug('Removing doc from add list: ' + doc.Routing_Name__c);
                docMapForCHK.remove(doc.Routing_Name__c);
            }
        }
            
        // iterate every single map left in chkID_to_documentListMap
        // add each doc into the docToInsert list
        for (Map<String, PEO_Onboarding_Document__c> docMap : chkID_to_documentListMap.values()) {
            System.debug('Adding doc to insert list: ');
            for(PEO_Onboarding_Document__c doc : docMap.values()) {
                System.debug(Doc.Routing_Name__c);
            }
            docToInsert.add(docMap.values());
        }*/
        
        // if the list isn't empty
        /*if (!docToInsert.isEmpty()) {
            System.debug('Inserting docs: '+docToInsert.size());
            String codeKey = 'By '+ user.name + ' on insert new docs for checlist after checking required statuses';
            DMLHelper.performDML2(docToInsert,DmlHelper.DML_INSERT,'PEOOnboardingChecklist_Handler','updateDocReqdStatus',codeKey,true);
        }*/
    }
    
    //Added by Srujan
    public static void resetQQDocuments(Map<id,PEO_Onboarding_Checklist__c> newMap ,Map<id,PEO_Onboarding_Checklist__c> oldMap){
        List<PEO_Onboarding_Checklist__c> checkLists = new List<PEO_Onboarding_Checklist__c>();
        Set<Id> checkListIds = new Set<Id>();
        for(PEO_Onboarding_Checklist__c newRec : newMap.values()) {
            PEO_Onboarding_Checklist__c oldRec = oldMap.get(newRec.Id);
            if(newRec.QQ_Reset_Date__c != oldRec.QQ_Reset_Date__c){
                checkLists.add(newRec);
                checkListIds.add(newRec.Id);
            }
        }
        if(checkLists.size() > 0){
            List<PEO_Onboarding_Checklist__c> updateChkList = new List<PEO_Onboarding_Checklist__c>();
            List<PEO_Onboarding_Document__c> updateChkListDocs = new List<PEO_Onboarding_Document__c>();
            List<PEO_Onboarding_Document_Discrepency__c> updateChkListDisc = new List<PEO_Onboarding_Document_Discrepency__c>();
            Set<Id> chkIds = new Set<Id>();
            List<PEO_Onboarding_Checklist__c> childChkLists = new List<PEO_Onboarding_Checklist__c>();
            childChkLists = [SELECT Id, HSF_Submission_Response__c, HSF_Submission_Status__c, HSF_Status_Change_Date__c, Medical_Underwriting_Path_Type__c,
                             Workers_Comp_Underwriting_Path_Type__c, Medical_Quick_Quote_Eligibility__c, Workers_Comp_Quick_Quote_Eligibility__c,
                             Medical_Docs_to_CS__c, Risk_Docs_to_CS__c, ownerId, Sales_Rep__c FROM PEO_Onboarding_Checklist__c WHERE Parent_PEO_Checklist__c =: checkListIds];
            for(PEO_Onboarding_Checklist__c chk : checkLists){
                chkIds.add(chk.Id);
                chk = resetQQFields(chk, false);
            }
            for(PEO_Onboarding_Checklist__c chk : childChkLists){
                chkIds.add(chk.Id);
                updateChkList.add(resetQQFields(chk, true));
            }
            if(chkIds.size() > 0){
                List<PEO_Onboarding_Document__c> peoDocs = new List<PEO_Onboarding_Document__c>();
                peoDocs = [SELECT Id, Status__c, Date_Uploaded__c FROM PEO_Onboarding_Document__c 
                           WHERE PEO_Onboarding_Checklist__c IN: chkIds 
                           AND Name IN ('Census', 'Medical Invoice', 'WC Classes and Wages')];
                for(PEO_Onboarding_Document__c doc : peoDocs){
                    if(doc.Date_Uploaded__c != null){
                        doc.Status__c = 'Approved';
                        doc.Docs_Sent_to_Clientspace__c = null;
                        doc.Date_Sent_to_Clientspace__c = null;
                        updateChkListDocs.add(doc);
                    }
                }
                
                List<PEO_Onboarding_Document_Discrepency__c> peoDisc = new List<PEO_Onboarding_Document_Discrepency__c>();
                peoDisc = [SELECT Id, Status__c FROM PEO_Onboarding_Document_Discrepency__c WHERE PEO_Underwriting_Checklist__c IN: chkIds];
                for(PEO_Onboarding_Document_Discrepency__c disc : peoDisc){
                    disc.Status__c = 'Resolved';
                    updateChkListDisc.add(disc);
                }
            }
            if(updateChkList.size() > 0){
                try {
                    DMLHelper.performDML2(updateChkList,DmlHelper.DML_UPSERT,'ConvertContactToCommunityUser','resetQQDocuments','By '+ UserInfo.getUserId(),true);
                }catch(Exception e) {
                    CommunityMethods.logCommunityError(e, 'resetQQDocuments','ConvertContactToCommunityUser', 'ConvertContactToCommunityUser',updateChkList);
                }
            }
            if(updateChkListDocs.size() > 0){
                try {
                    DMLHelper.performDML2(updateChkListDocs,DmlHelper.DML_UPSERT,'ConvertContactToCommunityUser','resetQQDocuments','By '+ UserInfo.getUserId(),true);
                }catch(Exception e) {
                    CommunityMethods.logCommunityError(e, 'resetQQDocuments','ConvertContactToCommunityUser', 'ConvertContactToCommunityUser',updateChkListDocs);
                }
            }
            if(updateChkListDisc.size() > 0){
                try {
                    DMLHelper.performDML2(updateChkListDisc,DmlHelper.DML_UPSERT,'ConvertContactToCommunityUser','resetQQDocuments','By '+ UserInfo.getUserId(),true);
                }catch(Exception e) {
                    CommunityMethods.logCommunityError(e, 'resetQQDocuments','ConvertContactToCommunityUser', 'ConvertContactToCommunityUser',updateChkListDisc);
                }
            }
        }
    }
    
    public static PEO_Onboarding_Checklist__c resetQQFields(PEO_Onboarding_Checklist__c chkList, Boolean isChild){
        chkList.Do_you_need_full_underwriting_path__c = '';
        chkList.why_choose_full_underwriting_path__c = '';
        chkList.HSF_Submission_Response__c = null;
        chkList.HSF_Submission_Status__c = null;
        chkList.HSF_Status_Change_Date__c = null;
        chkList.HSF_Census_Submit_Date__c = null;
        chkList.Medical_Underwriting_Path_Type__c = 'Quick Quote - Medical';
        chkList.Workers_Comp_Underwriting_Path_Type__c = 'Quick Quote - Workers Comp';
        chkList.Medical_Quick_Quote_Eligibility__c = null;
        chkList.Workers_Comp_Quick_Quote_Eligibility__c = null;
        chkList.Medical_Docs_to_CS__c = null;
        chkList.Risk_Docs_to_CS__c = null;
        chkList.Sales_Analyst__c = null;
        chkList.OwnerId = chkList.Sales_Rep__c;
        chkList.PEO_Checklist_submission_status__c = null;
        chkList.Sent_to_ClientSpace_Status_Date__c = null;
        if(isChild){
            chkList.QQ_Reset_Date__c = system.now();
        }
        return chkList;
    }
    
    public static void checkForMedUW(Map<Id,PEO_Onboarding_Checklist__c> checklistByOppId){
        System.debug('checkForMedUW');
        Reference_PEO_Medical_UW__c[] uwToInsert = new Reference_PEO_Medical_UW__c[]{};
        
        Map<Id,Id> uwIdByOppId = new Map<Id,Id>();
        //find existing uw records so we don't create duplicates
        for(Reference_PEO_Medical_UW__c  existingUW : [SELECT ID,Opportunity__c FROM Reference_PEO_Medical_UW__c WHERE Opportunity__c in :checklistByOppId.keySet()]){
            System.debug('existingUW:'+existingUW);
            if(!uwIdByOppId.containsKey(existingUW.Opportunity__c)){
              uwIdByOppId.put(existingUW.Opportunity__c,existingUW.Id);
            }
        }
        System.debug('uwIdByOppId:'+uwIdByOppId);
        //create the ones that are missing
        for(PEO_Onboarding_Checklist__c checklist :  checklistByOppId.values()){
            System.debug('checklist.Opportunity__c:'+checklist.Opportunity__c);
            if(!uwIdByOppId.containsKey(checklist.Opportunity__c)){
                System.debug('Adding to insert list');
                uwToInsert.add(new Reference_PEO_Medical_UW__c(Opportunity__c=checklist.Opportunity__c));
                
            }
        }
        System.debug('uwToInsert:'+uwToInsert);
        if(!uwToInsert.isEmpty()){
            insert uwToInsert;
        }
        //loop through what was created, add to what was already there to update the checklist
        for(Reference_PEO_Medical_UW__c  newUW : uwToInsert){
            if(!uwIdByOppId.containsKey(newUW.Opportunity__c)){
              uwIdByOppId.put(newUW.Opportunity__c,newUW.Id);
            }
        }
        for(PEO_Onboarding_Checklist__c checklist :  checklistByOppId.values()){
            if(uwIdByOppId.containsKey(checklist.Opportunity__c)){
                checklist.Reference_PEO_Medical_UW__c = uwIdByOppId.get(checklist.Opportunity__c);
            }
        }
    }//checkforMedUW
    public static void checkForNSC(Map<Id,PEO_Onboarding_Checklist__c> checklistByAccountId){
        Opportunity[] opptyWithOpptyTeamMembers = [SELECT Id, Name, AccountId,
                                                            (SELECT Id, Name, TeamMemberRole, UserId FROM OpportunityTeamMembers WHERE TeamMemberRole = 'PEO NSC' ORDER BY CreatedDate DESC LIMIT 1)
                                                            FROM Opportunity WHERE (RecordType.Name = 'PEO Opportunity Record Type' OR RecordType.Name = 'Prism PEO Opportunity Record Type')
                                                                                   AND AccountId IN :checklistByAccountId.keySet() ORDER BY CreatedDate DESC];
        Map<Id,Opportunity> oppByAccountId = new Map<Id,Opportunity>();
        for(Opportunity opp: opptyWithOpptyTeamMembers){
            if(!oppByAccountId.containsKey(opp.AccountId)){
                oppByAccountId.put(opp.AccountId,opp);
            }
        }

        for(PEO_Onboarding_Checklist__c checklist : checklistByAccountId.values()){
            Opportunity oppty = oppByAccountId.get(checklist.Prospect_Client__c);
            if(oppty!=null){
                if(checklist.Opportunity__c == null)checklist.Opportunity__c = oppty.Id;
                /*if(oppty.OpportunityTeamMembers != null && oppty.OpportunityTeamMembers.size() == 1 && oppty.OpportunityTeamMembers[0].UserId != null) {
                    checklist.PEO_NSC__c = oppty.OpportunityTeamMembers[0].UserId;
                }*/
                System.debug('checkForNSC checklist:'+checklist);
            }
        }
    }
    
    public static void sendChecklistCurrentStepValueUpdate(Map<Id, PEO_Onboarding_Checklist__c> checklistMap) {
        Set<Id> checklistToCompleteIdSet = new Set<Id>();
        for (PEO_Onboarding_Checklist__c chk : checklistMap.values()) {
            //System.debug('Condition 1 '+chk.Medical_Benefits_Underwriting_Requested__c + ' Condition 2 '+chk.CS_CM_WC_UW_Status__c.contains('Approved') +' Contion 3 '+chk.CS_CM_Medical_UW_Status__c.contains('Approved')+' Condtion 4 '+chk.CS_CM_Contract_Status__c);
           
            If(String.isNotBlank(chk.CS_CM_WC_UW_Status__c) && string.isNotBlank(chk.CS_CM_Contract_Status__c ) && string.isNotBlank(chk.Medical_Benefits_Underwriting_Requested__c)){ 
                if (chk.Medical_Benefits_Underwriting_Requested__c == 'Yes' && 
                     chk.CS_CM_WC_UW_Status__c.startsWith('Approved') && 
                    string.isNotBlank(chk.CS_CM_Medical_UW_Status__c) && chk.CS_CM_Medical_UW_Status__c.contains('Approved') && 
                    chk.CS_CM_Contract_Status__c == 'Approved') { // startsWith Added by Rohith
                    checklistToCompleteIdSet.add(chk.Id);
                } else if (chk.Medical_Benefits_Underwriting_Requested__c == 'No' && 
                           chk.CS_CM_WC_UW_Status__c.startsWith('Approved') && chk.CS_CM_Contract_Status__c == 'Approved') {// Contains Added by Rohith
                    checklistToCompleteIdSet.add(chk.Id);
                  }
               }
            }
        if (!checklistToCompleteIdSet.isEmpty()) {
            updateChecklistStatusToComplete(checklistToCompleteIdSet);
        }
    }
     
     
    @future
    public static void updateChecklistStatusToComplete(Set<Id> checklsitIds) {
        List<PEO_Onboarding_Checklist__c> checklists = [SELECT Id, Current_Step__c, Completed_Status_Date__c FROM PEO_Onboarding_Checklist__c WHERE Id in :checklsitIds];
        for (PEO_Onboarding_Checklist__c chk : checklists) {
            chk.Current_Step__c ='Completed';
            if (chk.Completed_Status_Date__c == null) chk.Completed_Status_Date__c  = System.now();
        }
        String codeKey = 'By '+ user.name + ' on CS CM Status update';
        DMLHelper.performDML2(checklists,DmlHelper.DML_UPDATE,'PEOOnboardingChecklist_Handler','updateChecklistStatusToComplete',codeKey,true);
    }
    
    @future
    public static void sendChatterForRejectedChecklist(Set<Id> checklistIds) {
        List<PEO_Onboarding_Checklist__c> checklsits = [SELECT Id, Sales_Rep__c FROM PEO_Onboarding_Checklist__c WHERE Id IN :checklistIds];
        sendChatterForRejectedChecklist(checklsits);
    }
    
    public static void sendChatterForRejectedChecklist(List<PEO_Onboarding_Checklist__c> checklists) {
        // build the chatter message
        for (PEO_Onboarding_Checklist__c chk : checklists) {
            List<Id> mentionList = new List<Id>();
            if (chk.Sales_Rep__c != null) mentionList.add(chk.Sales_Rep__c);
            //if (chk.PEO_NSC__c != null) mentionList.add(chk.PEO_NSC__c);
            String postText = 'There is not enough information and/or correct information submitted in order proceed. Please review and resubmit';
            ChatterMentionPost.createChatterMentionPost(chk.Id, mentionList, new String[]{postText},true,false);
        }
        // build the list of notification recipients
        // send the chatter notif
        try {
            ChatterMentionPost.postBatchFeedElements();
        } Catch(Exception e) {
            communityMethods.logCommunityError(e, 'sendChatterForRejectedChecklist', 'PEOOnboardingChecklist_Handler', '', checklists);
        }
    }
    
    public static void checkMedStatus(Map<Id, PEO_Onboarding_Checklist__c> oldChecklistMap, Map<Id, PEO_Onboarding_Checklist__c> newChecklistMap) {
        List<Id> accountIds = new List<Id>();
        List<Id> userIds = new List<Id>();
        List<Id> mentionList = new List<Id>();
        List<Id> mentionCommUser = new List<Id>();
        // Map of {} id to user record
        Map<Id, User> checkListUsers = new Map<Id, User>();
        
        // iterate checklists being updated
        // store the: account ID, salesRep UD, and commuity user ID
        for(PEO_Onboarding_Checklist__c checklist : newChecklistMap.values()) {
            accountIds.add(checklist.Prospect_Client__c);
            userIds.add(checklist.Sales_Rep__c);
            if(checklist.Community_User__c != null)userIds.add(checklist.Community_User__c);
        }
        
        // Select and iterate all the users that were added to the userIDS list
        for(User usr : [SELECT Id,FirstName,AccountId,Email,Name,ProfileName__c,ManagerId,Sales_Division__c,Sales_Org__c,Username,UserRoleName__c FROM User WHERE Id in :userIds]) {
            checkListUsers.put(usr.Id, usr);
        }
        // get all the Accounts that are related to checklists and map the to acctMap ID to Checklist
        system.debug('Mentionlist size:'+mentionList.size());
        Map<Id,Account> acctMap = new Map<Id,Account>([SELECT Id,Name FROM Account WHERE id in:accountIds]);
        
       
        // if the prequal status is changed AND both checklist IDs match AND the new status is approved
        // add: community user ID, sales rep id, manager id, analyst id, nsc id to mentionOwner then construct
        // a post text with those users mentioned
        for (PEO_Onboarding_Checklist__c oldOnbChecklist : oldChecklistMap.values()) {
            for (PEO_Onboarding_Checklist__c newOnbChecklist : newChecklistMap.values()) {
                if(oldOnbChecklist.Medical_Pre_Qualifier_Status__c != newOnbChecklist.Medical_Pre_Qualifier_Status__c && oldOnbChecklist.Id == newOnbChecklist.Id && newOnbChecklist.Medical_Pre_Qualifier_Status__c == 'Approved'){
                    if(newOnbChecklist.Community_User__c!=null)mentionCommUser.add(newOnbChecklist.Community_User__c); 
                    if(newOnbChecklist.Sales_Rep__c != null)mentionList.add(newOnbChecklist.Sales_Rep__c);
                    if(checkListUsers.get(newOnbChecklist.Sales_Rep__c).ManagerId != null)mentionList.add(checkListUsers.get(newOnbChecklist.Sales_Rep__c).ManagerId);
                    if(newOnbChecklist.Sales_Analyst__c != null)mentionList.add(newOnbChecklist.Sales_Analyst__c);
                    //if(newOnbChecklist.PEO_NSC__c != null)mentionList.add(newOnbChecklist.PEO_NSC__c);
                    String postText = 'Great News! The HSF Census Review submission for '+acctMap.get(newOnbChecklist.Prospect_Client__c).Name+' has been approved!  At this time the next steps of the portal have opened up and a notification has been sent to the Prospect.'; //SFDC-15719
                    postText = postText +' Please stay engaged with the prospect on next steps. ';
                    ChatterMentionPost.createChatterMentionPost(newOnbChecklist.Id, mentionList, new String[]{postText},true,false);
                }
            }
        }
        
        //Send email message to the account owner
       /* List<Messaging.SingleEmailMessage> mailList =  new List<Messaging.SingleEmailMessage>();
        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body 
                                       from EmailTemplate where name = 'Communities Prequalification mail' limit 1];
        if(!mentionCommUser.isEmpty() && emailTemplate!=null){
            for (Id usrid : mentionCommUser ) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(usrid); 
                mail.setSenderDisplayName('PEOSUPPORT_noreply@paychex.com'); 
                mail.setReplyTo('sfdc_automation@paychex.com');
                mail.setUseSignature(false); 
                mail.setBccSender(false); 
                mail.setSaveAsActivity(false); 
                mail.setTemplateID(emailTemplate.Id);
                mailList.add(mail);
            }
            Messaging.sendEmail(mailList);
        } */  //SFDC-16857
        
        // send the chatter notification
        try {
            ChatterMentionPost.postBatchFeedElements();
        } Catch(Exception e) {
            communityMethods.logCommunityError(e, 'sendChatterForRejectedChecklist', 'PEOOnboardingChecklist_Handler', '', newChecklistMap.values());
        }
    }
    
    public static String addDiscrepancyDetailsToString(String originalText, List<PEO_Onboarding_Document_Discrepency__c> discrepancyList) {
        // add values to new string
        originalText += '\n Discrepancy Information\n';
        originalText += '\n Type -- Subtype -- Info\n';
        Boolean addedDiscs = false;
        Integer count = 1;
        for (PEO_Onboarding_Document_Discrepency__c dics : discrepancyList) {
            if (!addedDiscs) addedDiscs = true;
            originalText += count + ') : ' + dics.Discrepancy_Type__c+ ' -- ';
            originalText += dics.Discrepancy_Sub_Type__c+ '\n';
            originalText += dics.additional_information__c + '\n\n';
            count+= 1;
        }
        if (!addedDiscs) originalText += 'Error loading discrepancy details. Please contact admin for support.';
        // return new string
        return originalText;
        
    }
    
    public static void setISQnotRequired(List<PEO_Onboarding_Checklist__c> checklists) {
        System.debug('setISQnotRequired checklists ='+checklists);
        // check the ISQ and make sure status is set to Not required when Record types are blank
        for (PEO_Onboarding_Checklist__c chk : checklists) {
            String indRecordTypes = chk.Industry_Record_Types__c;
            System.debug('setISQnotRequired indRecordTypes ='+indRecordTypes);
            if(indRecordTypes!=null && indRecordTypes.length() != 0 && indRecordTypes.contains('!.!') == true){
                indRecordTypes = indRecordTypes.replace('!.!', '');
                System.debug('setISQnotRequired indRecordTypes ='+indRecordTypes);
                if(indRecordTypes.length() == 0){
                    chk.Peo_IndSpecific_formStatus__c = 'Not Required';
                }
            }
            else if(indRecordTypes == null){
                chk.Peo_IndSpecific_formStatus__c = 'Not Required';
            }
        }
    }
    
    
    public static void sendHSFStatusUpdateChatter(String status, PEO_Onboarding_Checklist__c onbChecklist) {
        if(onbChecklist != null){
            List<User> salesReps = new List<User>();
            List<Id> userToMentionIdList = new List<Id>();
            String statusUpd = status;
            System.debug('sendHSFStatusUpdateChatter Sales_Rep__c:'+onbChecklist.Sales_Rep__c);
            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();            
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();   
            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
            textSegmentInput.text = 'Hello ';
            messageBodyInput.messageSegments.add(textSegmentInput);
            if(onbChecklist.Sales_Rep__c != null){
                //salesReps = [SELECT FirstName,Full_Name__c,Id,LastName, ManagerId FROM User WHERE Id =: onbChecklist.Sales_Rep__c limit 1]; 
                userToMentionIdList.add(onbChecklist.Sales_Rep__c);
                ///userToMentionIdList.add(salesReps[0].ManagerId);
            }
            
            Account salesRepAcc = [Select Id, Name from Account where id=:onbChecklist.Prospect_Client__c];
            
            if(userToMentionIdList.size() > 0){
               
               
                ChatterMentionPost.getMentions(messageBodyInput, userToMentionIdList);
                
            }
            if(status != null && status != 'FAIL'){
                ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
                textSegmentInput2.text = '. The Medical Census for ';
                messageBodyInput.messageSegments.add(textSegmentInput2);
            }
            else{
                ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
                textSegmentInput2.text = '. An ERROR was found for ';
                messageBodyInput.messageSegments.add(textSegmentInput2);
            }
            if(salesRepAcc != null){
                //Creating the link for Account
                ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputAccount = new ConnectApi.EntityLinkSegmentInput();
                entityLinkSegmentInputAccount.entityId = salesRepAcc.Id;   
                messageBodyInput.messageSegments.add(entityLinkSegmentInputAccount);
            }
            if(status != null && status == 'FAIL'){
                //FAIL
                ConnectApi.TextSegmentInput textSegmentInput3 = new ConnectApi.TextSegmentInput();
                textSegmentInput3.text = ' within the Census Submission to Clientspace. Please review the below Error Message and update the Census accordingly. Once updated, please resubmit the Census within the portal via the Submit Tab. You may review this Error within the PEO Underwriting Checklist at any time. \n \n';
                messageBodyInput.messageSegments.add(textSegmentInput3);
                if(onbChecklist.HSF_Submission_Response__c != null){
                    ConnectApi.TextSegmentInput errorLog = new ConnectApi.TextSegmentInput();
                    errorLog.text = 'Error: '+onbChecklist.HSF_Submission_Response__c;
                    messageBodyInput.messageSegments.add(errorLog);
                }
                
            }
            if(status != null && status == 'Success'){
                ConnectApi.TextSegmentInput textSegmentInput3 = new ConnectApi.TextSegmentInput();
                textSegmentInput3.text = ' was SUCCESSFULLY sent to Clientspace. Please navigate to the Prospects workspace within Clientspace via the link below. You must now complete the Pricing Console and fully submit the information for a Quick Quote review. The results from a Medical and/or Workers’ Compensation Quick Quote review will be sent separately.\n';
                messageBodyInput.messageSegments.add(textSegmentInput3);
                ConnectApi.LinkSegmentInput link = new  ConnectApi.LinkSegmentInput();
                link.url = onbChecklist.View_in_Clientspace__c;
                
                messageBodyInput.messageSegments.add(link);
            }
            /*if(status != null && status == 'UNFAVORABLE'){
                //UNFAVORABLE
                ConnectApi.TextSegmentInput textSegmentInput3 = new ConnectApi.TextSegmentInput();
                textSegmentInput3.text = ' is complete. Based on the census provided, the HSF score came back UNFAVORABLE and '+salesRepAcc.Name+' has been approved to Self-Retain. Please continue the Getting Started Portal and submit all applicable information.';
                messageBodyInput.messageSegments.add(textSegmentInput3);
            }
            else if(status != null && status == 'FAVORABLE'){
                //FAVORABLE
                ConnectApi.TextSegmentInput textSegmentInput4 = new ConnectApi.TextSegmentInput();
                textSegmentInput4.text = ' is complete. Based on the census provided,the HSF score came back FAVORABLE and its recommended to move forward with Full Medical Underwriting. Please reach out to your contact and proceed as necessary with the Getting Started Portal. Once prepared, please fully submit the portal to the NBSC assignment queue.';
                messageBodyInput.messageSegments.add(textSegmentInput4);
            }
            else if(status != null && status == 'RESULTS INCONCLUSIVE'){
                //INCONCLUSIVE
                ConnectApi.TextSegmentInput textSegmentInput5 = new ConnectApi.TextSegmentInput();
                textSegmentInput5.text = ' is complete. Based on the census provided, the results are INCONCLUSIVE and its recommended to move forward with Full Medical Underwriting. Please reach out to your contact and proceed as necessary with the Getting Started Portal. Once prepared, please fully submit the portal to the NBSC assignment queue.';
                messageBodyInput.messageSegments.add(textSegmentInput5);
            }*/
            
            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = onbChecklist.Id; 
            if(!test.isRunningTest()){
                ConnectApi.FeedElement feedElement =
                    ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
            }
        }
    }
}