/* Methods for interacting with ClientSpace

  History
  -------
  07/12/2019 Dan Carmen        Created
  09/10/2019 Dan Carmen        Add methods for Task,Event,Opportunity
  10/28/2019 Dan Carmen        Change to mainly use account attributes
  01/30/2020 Dan Carmen        If a record is deleted, mark the work queue as completed and deleted.
  05/13/2020 Dan Carmen        Changed for the new Oasis PEO owner field.
  05/19/2020 Dan Carmen        Updates to the Opportunity and Asset based on the ClientSpace updates
  08/21/2020 Dan Carmen        Don't update the closeDate on the Opportunity
  11/30/2020 Dan Carmen        Update delete method to not use DmlHelper
  03/09/2020 Jake Hinds        Adding doc send method to account after
  03/23/2021 Manmeet Vaseer     APR0116511 - do not update Account & Contact when an Opportunity is updated.
  04/19/2021 Bharat Potli      Added methods to create Work Queues for PEO_Onboarding_Checklist__c & PEO_Onboarding_Medical_Questionnaire__c
  05/18/2021 Dan Carmen        Update to not use "Not Sold" in the code - added another field on the Metadate Type to indicate lost - OpptyLost__c.
  07/01/2021 Jake Hinds        Check if runningUser is null
  07/02/2021 Jake Hinds        Change to ownerMatchesAcct to prioritize nsc
  07/12/2021 Eric Porter       Added field to Owner.Sales_Division__c to getOppCsIds query
  07/27/2021 Matt Fritschi     Changed the logic for whene to gather CS States and Codes. It now uses the ClientSpace Mapping metadata.
  01/24/2022 Jake Hinds         New Arguments for api queueables
  02/07/2022 Ahmed Elawad    Comment out logic sycning Child acc to CS on salesParent__c update: lines - 1082-1091, & 1125-1127
  03/07/2022 Jake Hinds      additional changes for above line
  05/03/2022 Jidesh 			Added method to prevent work queue timestamp getting changed after multiple updates on an object if work queue completed = false 
  09/02/2022 Rohit Ranjan    Added method to to update workqueue from Broker commission records
  12/08/2022 Jidesh            Updated checkOnboardingChecklistAfter & sendDocumentsToClientspaceFromChecklist as part of HSF work 
  04/05/2023 Jaipal           Commented out the method(checkCsContractChanged) and the code where it is being called from as per APR US3: APR0147082
  04/07/2023 Jidesh           Created resetWorkQueues method to reset the related workqueues to false when an account workqueue is created
  04/26/2023 Jidesh           Updated checkAccountsAfter & resetWorkQueues method to fix the issue where workqueues were resetting on account update
  11/06/2023 Jidesh			sendDocumentsToClientspaceFromChecklist Code updates for CS API change from v1 to v2. For API documentation refer Story SFDC-23156
  01/08/2024 Priyanka			SFDC-23985: NewMethod PEOAccountOwnerChangeUpdates added for PEO Account Owner Change	
  12/28/2023 Jaipal          Uncommented out the method(checkCsContractChanged) the Business want it back & also added extra condition to update client status to 'I' to move the account type to lost 
  04/26/2024 Reetesh Pandey  APR0169308 Oasis Revenue field to populate on oli if totalPrice is 0.0 
*/


public without sharing class ClientSpaceHelper implements TriggerInterfaceC {
   
   public static String PREFIX_CS='CS-';
   
   public static Boolean csUser=null;
   
   public static Boolean isClientSpaceUser() {
      if (csUser == null) {
         User runningUser = UserHelper.getRunningUser();
         if(runningUser!=null){
             csUser = UserHelper.hasActiveProcessName(PREFIX_CS+runningUser.Name);
         }
         else{
             csUser = false;
         }
      }
      return csUser;
   } // isClientSpaceUser

   //public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs('ClientSpaceHelper', p_recs, oldMap, isBefore, isAfter, isDelete, 'ClientSpaceHelper', null);
      if (!isDelete && (recs == null || recs.isEmpty()) ) {
         return;
      }

      SObjectType objType = TriggerMethods.objType;
      String objTypeName = TriggerMethods.objectTypeName;
      System.debug('ClientSpaceHelper objTypeName='+objTypeName+' recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete);

      if (isBefore) {
         if (objType == Contact.sObjectType) {
            checkContactsBefore((Contact[])recs,(Map<Id,Contact>)oldMap);
         } else if (objType == Account.sObjectType) {
            checkAccountsBefore((Account[])recs,(Map<Id,Account>)oldMap);
         //} else if (objType == Task.sObjectType) {
         //   checkTasksBefore((Task[])recs,(Map<Id,Task>)oldMap);
        
         }  else if (objType == PEO_Onboarding_Checklist__c.sObjectType) { //Added by Bharat - Start of change
            checkOnboardingChecklistBefore((PEO_Onboarding_Checklist__c[])recs, (Map<Id,PEO_Onboarding_Checklist__c>)oldMap);
         } else if(objType == PEO_Onboarding_Medical_Questionnaire__c.sObjectType){
            checkPeoMedicalQuestionnaireBefore((PEO_Onboarding_Medical_Questionnaire__c[]) recs, (Map<Id,PEO_Onboarding_Medical_Questionnaire__c>)oldMap);
         }//Added by Bharat - End of change
      // do not process the after triggers if the client space user is running.
      } else if (isAfter && !isClientSpaceUser()) {
         if (isDelete) {
            // if any records are deleted, delete associated work queue records
            handleDeletedRecs(oldMap);
         } else {
            if (objType == Contact.sObjectType) {
               checkContactsAfter((Contact[])recs,(Map<Id,Contact>)oldMap);
            } else if (objType == Account.sObjectType) {
               checkAccountsAfter((Account[])recs,(Map<Id,Account>)oldMap);
            } else if ((objType == Task.sObjectType) || (objType == Event.sObjectType)) {
               checkActivityAfter(recs,oldMap,objTypeName);
            } else if ((objType == Opportunity.sObjectType)) {
               checkOppsAfter((Opportunity[])recs,(Map<Id,Opportunity>)oldMap);
            } else if (objType == Reference_PEO_Medical_UW__c.sObjectType) {
                checkRefPeoMedAfter((Reference_PEO_Medical_UW__c[])recs, (Map<Id,Reference_PEO_Medical_UW__c>)oldMap);
            } else if (objType == Reference_PEO__c.sObjectType) {
                checkRefPeoAfter((Reference_PEO__c[])recs, (Map<Id,Reference_PEO__c>)oldMap);
                
            } else if (objType == PEO_Onboarding_Checklist__c.sObjectType) { //Added by Bharat - Start of change
                system.debug('handleTrigger detected peouw checklist change');
                checkOnboardingChecklistAfter((PEO_Onboarding_Checklist__c[])recs, (Map<Id,PEO_Onboarding_Checklist__c>)oldMap);
            } else if(objType == PEO_Onboarding_Medical_Questionnaire__c.sObjectType){//Added by Bharat to send data to clientspace
              checkPeoMedicalQuestionnaireAfter((PEO_Onboarding_Medical_Questionnaire__c[]) recs,  (Map<Id,PEO_Onboarding_Medical_Questionnaire__c>)oldMap);    
            }  //Added by Bharat - End of change
             //APR0163741: Broker commission work queues added by Tej
             else if(objType == Broker_Commission__c.sObjectType && !isClientSpaceUser()){
                	workQueuesForBrokenCommissions((Broker_Commission__c[]) recs);
             }
         } // if (isDelete
      } else if (isAfter && isClientSpaceUser()) {
       /*  if (objType == Reference_PEO_Medical_UW__c.sObjectType) {
             checkRefPeoMedAfter((Reference_PEO_Medical_UW__c[])recs, (Map<Id,Reference_PEO_Medical_UW__c>)oldMap);
         } else */
             if (objType == Account.sObjectType) {
             checkAcctAfterFromCS((Account[])recs,(Map<Id,Account>)oldMap);
         }
         else if (objType == PEO_Onboarding_Checklist__c.sObjectType) {  
             checkChecklistAfterFromCS((PEO_Onboarding_Checklist__c[])recs,(Map<Id,PEO_Onboarding_Checklist__c>)oldMap);  
         }       
      }
   } // checkAllBeforeTrigger
    
   public static void handleDeletedRecs(Map<Id,SObject> oldMap) {
      System.debug('handleDeletedRecs oldMap='+oldMap.size());
      Work_Queue__c[] recs = [Select Id, Completed__c, ProcessNotes__c, RecordIsDeleted__c
                                from Work_Queue__c
                               Where Object_Record_ID__c in :oldMap.keySet()
                                ];
      System.debug('handleDeletedRecs recs='+recs.size());
      // make sure they're all marked as completed and deleted
      for (Work_Queue__c rec : recs) {
         rec.Completed__c=true;
         rec.RecordIsDeleted__c=true;
         StringHelper.addToProcessNotes(rec,'Source Record Deleted - Set Record Is Deleted flag');
      }
      if (!recs.isEmpty()) {
         Database.update(recs,false);
      }
      //DmlHelper.performDML2(recs, DmlHelper.DML_UPDATE, 'ClientSpaceHelper', 'handleDeletedRecs', 'Update Work Queues to Deleted', true);

   } // handleDeletedRecs
    
    //Added by Bharat - start of change
   public static void checkOnboardingChecklistBefore(PEO_Onboarding_Checklist__c[] onboardingChecklists, Map<Id,PEO_Onboarding_Checklist__c> oldMap) {
       Set<Id> accountIds = new Set<Id>();
       for (PEO_Onboarding_Checklist__c checklist : onboardingChecklists) {
           /*if (checklist.Id != null) {
			forceCSIdSet.add(checklist.Id);
			}*/
           PEO_Onboarding_Checklist__c oldRec = oldMap.get(checklist.Id);
           if(oldRec!=null && !oldRec.Med_pre_qual_submission__c && checklist.Med_pre_qual_submission__c){
               checklist.PEO_Med_prequal_sub_time_stamp__c = dateTime.now();
           }
           //only do this on a single record update where the field is set
           if(oldRec!=null && !oldRec.Sync_Locations_to_CS__c && checklist.Sync_Locations_to_CS__c && checklist.Parent_PEO_Checklist__c==null && onboardingChecklists.size() == 1){
               accountIds.add(checklist.Prospect_Client__c);
               checklist.Sync_Locations_to_CS__c = false;
           }
       } 
       if (!accountIds.isEmpty()) {
           checkLocationsForAccount(accountIds);   
       }
   } //checkOnboardingChecklistBefore
   //Added by Bharat - end of change
    public static void checkOnboardingChecklistAfter(PEO_Onboarding_Checklist__c[] onboardingChecklists, Map<Id,PEO_Onboarding_Checklist__c> oldMap) {
        system.debug('checkOnboardingChecklistAfter');
        Map<Id,PEO_Onboarding_Checklist__c> checklistsForStateCodeUpdate = new Map<Id,PEO_Onboarding_Checklist__c>();
        Work_Queue__c[] upsertWorkQueues = new Work_Queue__c[]{};
            Schema.FieldSet checkListFldSet = Schema.SObjectType.PEO_Onboarding_Checklist__c.fieldSets.Questionnaire_Fields;
        
        // document send members
        Map<Id, Id> accountToChecklsitMap = new Map<Id, Id>(); // maps the account id to the checklist it's related to
        Map<Id, PEO_Onboarding_Checklist__c> parentAccIdsToChecklistMap = new Map<Id, PEO_Onboarding_Checklist__c>(); // maps a parent account to its checklist
        Map<Id,PEO_Onboarding_Checklist__c> checklistsforDocSubmit = new Map<Id,PEO_Onboarding_Checklist__c>(); // maps the checklist id to its checklist
          //     Map<id,PEO_Onboarding_Checklist__c> opptunityChangedMap=new Map<id,PEO_Onboarding_Checklist__c>();
        
        for(PEO_Onboarding_Checklist__c checklist : onboardingChecklists){
            
            PEO_Onboarding_Checklist__c oldChecklist = (oldMap != null ? oldMap.get(checklist.Id) : null);
            // Added by Bharat check if we're forcing it through or additional field change criteria
            if (forceCSIdSet.contains(checklist.Id) || recFldsChanged(checklist,oldChecklist,checkListFldSet,false)) {
                system.debug('checkOnboardingChecklistAfter calling addPeoOnboardingChecklistWorkQueue');
                addPeoOnboardingChecklistWorkQueue(checklist, upsertWorkQueues);
            }
             
            // if the checklist has a value populated in the submit to client space field
            // add the checklist id to the map of its Id to the checklist record
            // map the prospect for the checklist to its checklist
            if(!String.isBlank(checklist.Submit_Docs_to_Clientspace__c) && checklist.HSF_Submission_Status__c != 'Submitted'){
                checklistsforDocSubmit.put(checklist.Id,checklist);
                // add the account ID to the set
                accountToChecklsitMap.put(checklist.Prospect_Client__c, checklist.Id);
            }
            else if(checklist.ISQ_Last_Change_Made__c !=null && (oldMap.get(checklist.Id).ISQ_Last_Change_Made__c != checklist.ISQ_Last_Change_Made__c)){
                checklistsforDocSubmit.put(checklist.Id,checklist);
                // add the account ID to the set
                accountToChecklsitMap.put(checklist.Prospect_Client__c, checklist.Id);
            }
            else if(checklist.HSF_Submission_Status__c == 'Submitted'){
                System.debug('Clientspace Helper HSF Submission');
                checklistsforDocSubmit.put(checklist.Id,checklist);
                accountToChecklsitMap.put(checklist.Prospect_Client__c, checklist.Id);
            }
            if(checklist.Pull_Clientspace_States_and_Codes__c){
                checklistsForStateCodeUpdate.put(checklist.Id,checklist);
            }
        }
        
        // get all accounts that are mapped in the account checklist map
        Account[] checklistAccs = [SELECT id, isParent__c, SalesParent__c FROM Account where Id IN :accountToChecklsitMap.keySet()];
        
        // for each account
            // if the account is a parent account
            // Map the parent account ID to the checklist it's related too
                // retrieve the checklist by using the accountToChecklsitMap value for the current account
        for (Account acc: checklistAccs) {
            if (acc.isParent__c) { 
                parentAccIdsToChecklistMap.put(acc.Id, checklistsforDocSubmit.get(accountToChecklsitMap.get(acc.Id)));
            }
        } 
        
        //Added by Bharat
        saveWorkQueues(null,null,upsertWorkQueues,'PEO_Onboarding_Checklist__c');
        
        // if there are documents that need to be submitted
        // send them to the queuable initiator method
        // and also check the industry specific: this is needed here because the checklist would only be added
        // to checklistsforDocSubmit if the Submit docs to client space field was altered
        System.debug('checklistsforDocSubmit: '+checklistsforDocSubmit);
        if(!checklistsforDocSubmit.isEmpty()){
            System.debug('Sending document submit request');
            checkIndustrySpecificAfterChecklist(checklistsforDocSubmit);
            sendDocumentsToClientspaceFromChecklist(checklistsforDocSubmit, parentAccIdsToChecklistMap);            
        }
        
        if(!checklistsForStateCodeUpdate.isEmpty()){
            pullStatesAndCodesFromClientspace(checklistsForStateCodeUpdate, new Account[]{});            
        }
    } // checkOnboardingChecklistAfter
       //Added by Susmitha 9212021   

    public static void checkChecklistAfterFromCS(PEO_Onboarding_Checklist__c[] onboardingChecklists, Map<Id,PEO_Onboarding_Checklist__c> oldMap) {
       
       Map<id,PEO_Onboarding_Checklist__c> onboardingCheckListMap=new Map<id,PEO_Onboarding_Checklist__c>();

        for(PEO_Onboarding_Checklist__c checklist : onboardingChecklists){
            system.debug('new records '+checklist);
            PEO_Onboarding_Checklist__c oldChecklist = (oldMap != null ? oldMap.get(checklist.Id) : null);
            system.debug('old records '+oldChecklist);
            // Added by Susmitha
            if(checklist.opportunity__c!=null)
      {
         if(checklist.CS_CM_Med_UW_Submit_Date__c!=oldChecklist.CS_CM_Med_UW_Submit_Date__c
                ||checklist.CS_CM_Contract_Status__c!=oldChecklist.CS_CM_Contract_Status__c
        ||checklist.CS_CM_Status_Date__c!=oldChecklist.CS_CM_Status_Date__c
        ||checklist.CS_CM_Kill_Reason__c!=oldChecklist.CS_CM_Kill_Reason__c
        ||checklist.CS_CM_Contract_Received_Date__c!=oldChecklist.CS_CM_Contract_Received_Date__c
        ||checklist.CS_CM_Implementation_Date__c!=oldChecklist.CS_CM_Implementation_Date__c
        ||checklist.CS_CM_Med_UW_Accept_Date__c!=oldChecklist.CS_CM_Med_UW_Accept_Date__c
        ||checklist.CS_CM_Med_UW_Decision_Date__c!=oldChecklist.CS_CM_Med_UW_Decision_Date__c
        ||checklist.CS_CM_WC_UW_Status__c!=oldChecklist.CS_CM_WC_UW_Status__c
        ||checklist.CS_CM_WC_UW_Accept_Date__c!=oldChecklist.CS_CM_WC_UW_Accept_Date__c
        ||checklist.CS_CM_WC_UW_Decision_Date__c!=oldChecklist.CS_CM_WC_UW_Decision_Date__c
                ||checklist.CS_CM_Medical_UW_Status__c!=oldChecklist.CS_CM_Medical_UW_Status__c
                ||checklist.CS_CM_WC_UW_Submit_Date__c!=oldChecklist.CS_CM_WC_UW_Submit_Date__c
                ||checklist.Oasis_Revenue__c!=oldChecklist.Oasis_Revenue__c)
        {
          onboardingCheckListMap.put(checklist.opportunity__c,checklist);
        }      
        
      }

            // ended by susmitha 9212021
            
        }system.debug('records map '+onboardingCheckListMap);
        
        if(onboardingCheckListMap.size()>0 && !System.isFuture())
    {
      updateOpportunityFromChecklist(json.serialize(onboardingCheckListMap));
    }

        
    } // checkChecklistAfterFromCS
    @future 
    public static void updateOpportunityFromChecklist(String jsonMap){
        Map<String,ClientSpaceMapping__mdt> csStatusMap = getCSMapping(); //Susmitha added
        List<OpportunityLineItem> updateOlis = new List<OpportunityLineItem>(); //Susmitha added
        Map<id,PEO_Onboarding_Checklist__c> onboardingCheckListMap=new Map<id,PEO_Onboarding_Checklist__c>();
        onboardingCheckListMap =(Map<id,PEO_Onboarding_Checklist__c>)Json.deserialize(jsonMap,Map<id,PEO_Onboarding_Checklist__c>.class);
        if(onboardingCheckListMap.size()>0){
            List<Opportunity> oppList=new List<Opportunity>();
            //Id fssRecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('PEO_Opportunity_FSS_Record_Type').getRecordTypeId();
            //Susmitha added opportunity line items sub query
            Map<String, OpportunityStage> mapStatusToStage = OpptyMethods.getOppStageMap();
            for(Opportunity opp:[SELECT id,Name,StageName,Reason_Not_Sold__c,CS_CM_Med_UW_Submit_Date__c,CS_CM_Kill_Reason__c,
                CS_CM_Implementation_Date__c,CS_CM_Medical_UW_Status__c,CS_CM_Contract_Received_Date__c,
                CS_CM_Status_Date__c,CS_CM_Contract_Status__c,CS_CM_Med_UW_Accept_Date__c,
                CS_CM_Med_UW_Decision_Date__c,CS_CM_WC_UW_Status__c,CS_CM_WC_UW_Submit_Date__c,
                Oasis_Revenue__c,CS_CM_WC_UW_Accept_Date__c,CS_CM_WC_UW_Decision_Date__c,RecordTypeId,RecordType.Name,
                (Select Id, Name, Product2Id, TotalPrice,Product2.Name, Product2.ProductCode, 
                Product2.CreateAssetWhenSold__c, Product2.Sales_Org__c From OpportunityLineItems 
                Where Product2.ClientSpaceProduct__c= true order by CreatedDate desc) from Opportunity 
                WHERE Id=:onboardingCheckListMap.keySet()]){
                    opp.CS_CM_Contract_Status__c = onboardingCheckListMap.get(opp.id).CS_CM_Contract_Status__c;
                    opp.CS_CM_Status_Date__c = onboardingCheckListMap.get(opp.id).CS_CM_Status_Date__c;
                    opp.CS_CM_Contract_Received_Date__c = onboardingCheckListMap.get(opp.id).CS_CM_Contract_Received_Date__c;
                    opp.CS_CM_Implementation_Date__c = onboardingCheckListMap.get(opp.id).CS_CM_Implementation_Date__c;
                    opp.CS_CM_Kill_Reason__c = onboardingCheckListMap.get(opp.id).CS_CM_Kill_Reason__c;
                    opp.CS_CM_Med_UW_Submit_Date__c = onboardingCheckListMap.get(opp.id).CS_CM_Med_UW_Submit_Date__c;
                    opp.CS_CM_Med_UW_Accept_Date__c = onboardingCheckListMap.get(opp.id).CS_CM_Med_UW_Accept_Date__c;
                    opp.CS_CM_Med_UW_Decision_Date__c = onboardingCheckListMap.get(opp.id).CS_CM_Med_UW_Decision_Date__c;
                    opp.CS_CM_WC_UW_Status__c = onboardingCheckListMap.get(opp.id).CS_CM_WC_UW_Status__c;
                    opp.CS_CM_WC_UW_Accept_Date__c = onboardingCheckListMap.get(opp.id).CS_CM_WC_UW_Accept_Date__c;
                    opp.CS_CM_WC_UW_Decision_Date__c = onboardingCheckListMap.get(opp.id).CS_CM_WC_UW_Decision_Date__c;
                    opp.CS_CM_Medical_UW_Status__c = onboardingCheckListMap.get(opp.id).CS_CM_Medical_UW_Status__c;
                    opp.CS_CM_WC_UW_Submit_Date__c = onboardingCheckListMap.get(opp.id).CS_CM_WC_UW_Submit_Date__c;
                    opp.Oasis_Revenue__c = onboardingCheckListMap.get(opp.id).Oasis_Revenue__c;
                    //oppList.add(opp);
                //Susmitha changes started here
                RecordType__c rtSetting = RecordTypeHelper.getRtSetting(opp.RecordType.Name);
                    system.debug('rtsetting '+rtSetting);
                if (rtSetting != null && rtSetting.UseForClientSpace__c) {
                    Boolean oppUpdated = false;
                    if(rtSetting.CSStatusUpdate__c) {
                        ClientSpaceMapping__mdt csm = (String.isNotBlank(onboardingCheckListMap.get(opp.id).CS_CM_Contract_Status__c) ? csStatusMap.get(onboardingCheckListMap.get(opp.id).CS_CM_Contract_Status__c) : null);
                        system.debug('csm details '+csm);
                        Boolean isLost = (csm != null && csm.OpptyLost__c);
                        if (csm != null && csm.OpptyStatus__c != opp.StageName) {
                               System.debug('opp.StageName before stage logic execution'+ opp.StageName);
                             //APRO158132 Tej : Adding this code below to make sure that status only changes to discovery if the current status is qualified  or gained access or IEUP
                            String stageName = csm != null ? csm.OpptyStatus__c : opp.StageName;
                            if(stageName == 'Discovery'){
                                if(opp.StageName == 'Qualified' || opp.StageName == 'Gained Access' || opp.StageName == 'IEUP'){
                                   opp.StageName = stageName;                                
                                }
                            }else{
                                  Boolean letStageUpdate = true;
                                  if(mapStatusToStage.containsKey(csm.OpptyStatus__c) && mapStatusToStage.containsKey(opp.StageName) && (opp.StageName == 'Verbal Commit' || opp.StageName == 'Sold' || opp.StageName == 'Sold – Submitted' || opp.StageName == 'Sold - Submitted' )){
                                      if(mapStatusToStage.get(csm.OpptyStatus__c).DefaultProbability < mapStatusToStage.get(opp.StageName).DefaultProbability) {
                                          letStageUpdate = false;
                                      }
                                  }

                                 if((opp.RecordType.Name == 'PEO Opportunity Record Type' || opp.RecordType.Name == 'Prism PEO Opportunity Record Type') && (opp.StageName == 'Lost' || opp.StageName == 'No Decision' || opp.StageName == 'Disqualified')){
                                    letStageUpdate = false;
                                }
                                
                                if(letStageUpdate){
                                	opp.StageName = stageName;
                                }

                           }
                            	System.debug('opp.StageName after stage logic execution'+ opp.StageName);
                           // opp.StageName = (csm != null ? csm.OpptyStatus__c : opp.StageName);
                            //if (opp.StageName == 'Not Sold') {
                            if (isLost) {
                                System.debug('checkCSOpps Reason_Not_Sold__c='+onboardingCheckListMap.get(opp.id).CS_CM_Kill_Reason__c);
                                opp.Reason_Not_Sold__c = onboardingCheckListMap.get(opp.id).CS_CM_Kill_Reason__c;
                            }
                            oppUpdated = true;
                        }
                        System.debug('checkCSOpps opp='+opp.Name+' OasisRevenue__c='+onboardingCheckListMap.get(opp.id).Oasis_Revenue__c+' lineItems='+opp.OpportunityLineItems.size()+' CSOtherInfoUpdate__c='+rtSetting.CSOtherInfoUpdate__c);
                        // if there's corresponding revenue, just take the latest one
                        
                        //if (rtSetting.CSOtherInfoUpdate__c && opp.StageName != 'Not Sold' && acct.OasisRevenue__c != null && !opp.OpportunityLineItems.isEmpty()) {
                        if (rtSetting.CSOtherInfoUpdate__c && !isLost && onboardingCheckListMap.get(opp.id).Oasis_Revenue__c!=null && !opp.OpportunityLineItems.isEmpty()) {
                            OpportunityLineItem oli = opp.OpportunityLineItems[0];
                            oli.TotalPrice = (oli.TotalPrice != 0.0 && (opp.RecordType.Name == 'PEO Opportunity Record Type' || opp.RecordType.Name == 'Prism PEO Opportunity Record Type'))?oli.TotalPrice : onboardingCheckListMap.get(opp.id).Oasis_Revenue__c;
                            System.debug('checkCSOpps updating TotalPrice to '+onboardingCheckListMap.get(opp.id).Oasis_Revenue__c);
                            updateOlis.add(oli);
                        }  
                    }
                    /*if (rtSetting.CSOtherInfoUpdate__c && (
                    //(acct.First_Run_Date__c != null && acct.First_Run_Date__c != opp.CloseDate)
                    // ||
                    (acct.Employees__c != null && acct.Employees__c != opp.Employees_Paid_Per_Payroll__c))) {
                    //opp.CloseDate = (acct.First_Run_Date__c != null ? acct.First_Run_Date__c : opp.CloseDate);
                    opp.Employees_Paid_Per_Payroll__c = (acct.Employees__c != null ? acct.Employees__c : opp.Employees_Paid_Per_Payroll__c);
                    oppUpdated = true;
                    }
                   
                    if (oppUpdated && opp.RecordType.Name != 'Prism PEO Opportunity FSS Record Type'){
                      oppList.add(opp);
                    } */
                }
                //Susmitha changes ends here
                //
                oppList.add(opp);
            }
            if(!oppList.isEmpty()){
                try{
                                    DmlHelper.performDML2(oppList, DmlHelper.DML_UPDATE, 'ClientSpaceHelper', 'updateOpportunityFromChecklist', 'Updating opportunity', false);

                }
                catch(Exception e){
                  
                    System.debug('error updating opportunity status from ClientSpaceHelper.updateOpportunityFromChecklist'+ e.getMessage() +'stacktrace'+ e.getStackTraceString());
                    ErrorLog__c objEL = new ErrorLog__c();
                    objEL.ClassName__c = 'ClientSpaceHelper';
                    objEL.DMLType__c = 'UPDATE';
                    objEL.MethodName__c = 'updateOpportunityFromChecklist';
                    objEL.Description__c = e.getMessage() +'stacktrace'+ e.getStackTraceString();
                    ErrorLog.saveErrorLog(objEL);
                }
            }
            if(!updateOlis.isEmpty()){
                DmlHelper.performDML2(updateOlis, DmlHelper.DML_UPDATE, 'ClientSpaceHelper', 'updateOpportunityFromChecklist', 'Updating OpportunityLineItems', false); //Susmitha added
            }
            
        }
    }
   
    
    // retrieves the indusrty specific quesionnaire and creates a workqueue if needed
    public static void checkIndustrySpecificAfterChecklist(Map<Id,PEO_Onboarding_Checklist__c> checklistMap) {
        // need to veruify if I need the parent account ID for the creation of the qorekqueue records
        System.debug('Starting to create industry specific workqueues...');
        System.debug('Checklistmap.keySet()' + checklistMap.keySet());
        Work_Queue__c[] industrySpecificWorkQueues = new Work_Queue__c[]{};
            
        // get all industry specific records for the attatched checklists
        WC_Questionnaire_Industry_Specific__c[] questionnaires = [SELECT Id,Record_Type_Name__c,PEO_Underwriting_Checklist__c 
                                                                      FROM WC_Questionnaire_Industry_Specific__c
                                                                      WHERE PEO_Underwriting_Checklist__c IN :checklistMap.keySet()];
        
        // for industry questionnaire create the workqueue record
        for (WC_Questionnaire_Industry_Specific__c rec : questionnaires) {
            // attempt to filer out the fields
            System.debug('Adding workqueue...');
            PEO_Onboarding_Checklist__c checklist = checklistMap.get(rec.PEO_Underwriting_Checklist__c);
            Boolean workQueueExists = checkExistingWorkQueue(checklist.Prospect_Client__c, checklist,'WC_Questionnaire_Industry_Specific__c',rec.Id);
            if(workQueueExists == false){
                Work_Queue__c wq = new Work_Queue__c(Account_ID__c=checklist.Prospect_Client__c, Object_Record_ID__c=rec.Id, Object__c='WC_Questionnaire_Industry_Specific__c');
                wq.Completed__c=false;
                System.debug('Workqueue account: ' + wq.Account_ID__c + '\nWOrkqueue Object_Record_ID__c: ' + wq.Object_Record_ID__c);
                industrySpecificWorkQueues.add(wq);
            }
            else{
                system.debug('ClientSpaceHelper checkIndustrySpecificAfterChecklist: ISQ WQ already exists. Hence preventing WQ updation');
            }
        }
        
        // create a new workqueue populating the generic fields 
        if (!industrySpecificWorkQueues.isEmpty()) {
            System.debug('Sending workqueue: '+industrySpecificWorkQueues.size());
            saveWorkQueues(null,null,industrySpecificWorkQueues,'WC_Questionnaire_Industry_Specific__c');
        }
    }
    
    public static void checkImplementationAfterChecklist(List<PEO_Implementation_Checklist__c> checklistData){
        List<Work_Queue__c> implementationChecklistWorkQueues = new List<Work_Queue__c>();
        Set<Id> accId = new Set<Id>();
        Map<Id, Work_Queue__c> clientQueueMap = new Map<Id, Work_Queue__c>();
        for(PEO_Implementation_Checklist__c checklistRec : checklistData){
            accId.add(checklistRec.Prospect_Client__c);
        }
        List<Work_Queue__c> queues = [SELECT Account_ID__c,Completed__c,Id,Name,Object_Record_ID__c,Object__c FROM Work_Queue__c WHERE Account_ID__c IN: accId];
        if(queues.size() > 0){
            for(Work_Queue__c queue : queues){
                clientQueueMap.put(queue.Account_ID__c, queue);
            }
        }
        for(PEO_Implementation_Checklist__c checklistRec : checklistData){ 
            Work_Queue__c wq = new Work_Queue__c();
            wq = clientQueueMap.get(checklistRec.Prospect_Client__c);
            system.debug(wq);
            if(wq != null && wq.Object__c == 'PEO_Implementation_Checklist__c' && 
               wq.Object_Record_ID__c == checklistRec.Id && wq.Completed__c == false){
                   system.debug('Implementation checlist WQ already exists. hence preventing WQ updation');
               }else{
                   Work_Queue__c workQueue = new Work_Queue__c(Account_ID__c=checklistRec.Prospect_Client__c, Object_Record_ID__c=checklistRec.Id, Object__c='PEO_Implementation_Checklist__c');
                   workQueue.Completed__c = false;
                   implementationChecklistWorkQueues.add(workQueue);
               }
        }
        if (!implementationChecklistWorkQueues.isEmpty()) {
            saveWorkQueues(null,null,implementationChecklistWorkQueues,'PEO_Implementation_Checklist__c');
        }
    }
    
    //Added by Jidesh for Compliance Info tabs
    //Called from PEO_Compliance_Info__c trigger
    public static void complianceInfoAfter(List<PEO_Compliance_Info__c> complianceData){
        System.debug('complianceInfoAfter: Compliance after');
        List<Work_Queue__c> complianceWorkQueues = new List<Work_Queue__c>();
        Set<Id> accId = new Set<Id>();
        Map<Id, Work_Queue__c> clientQueueMap = new Map<Id, Work_Queue__c>();
        for(PEO_Compliance_Info__c complianceRec : complianceData){
            accId.add(complianceRec.Prospect_Client__c);
        }
        List<Work_Queue__c> queues = [SELECT Account_ID__c,Completed__c,Id,Name,Object_Record_ID__c,Object__c FROM Work_Queue__c WHERE Account_ID__c IN: accId];
        if(queues.size() > 0){
            for(Work_Queue__c queue : queues){
                clientQueueMap.put(queue.Account_ID__c, queue);
            }
        }
        for(PEO_Compliance_Info__c complianceRec : complianceData){ 
            Work_Queue__c wq = new Work_Queue__c();
            wq = clientQueueMap.get(complianceRec.Prospect_Client__c);
            system.debug(wq);
            if(wq != null && wq.Object__c == 'PEO_Compliance_Info__c' && 
               wq.Object_Record_ID__c == complianceRec.Id && wq.Completed__c == false){
                   system.debug('Compliance Info WQ already exists. Hence preventing WQ updation');
               }else{
                   Work_Queue__c workQueue = new Work_Queue__c(Account_ID__c=complianceRec.Prospect_Client__c, Object_Record_ID__c=complianceRec.Id, Object__c='PEO_Compliance_Info__c');
                   workQueue.Completed__c = false;
                   complianceWorkQueues.add(workQueue);
               }
        }
        if (!complianceWorkQueues.isEmpty()) {
            saveWorkQueues(null,null,complianceWorkQueues,'PEO_Compliance_Info__c');
        }
    }
    
   public static void addPeoOnboardingChecklistWorkQueue(PEO_Onboarding_Checklist__c checklist, Work_Queue__c[] upsertWorkQueues) {
      System.debug('addPeoOnboardingChecklistWorkQueue creating Work_Queue__c record='+(checklist != null));
      if (checklist != null) {
         //TODO: Create lookup to peo onboaridng checklist on work queue? If yes, then associate here
         Boolean workQueueExists = checkExistingWorkQueue(checklist.Prospect_Client__c, checklist,'PEO_Onboarding_Checklist__c',checklist.Id);
          system.debug('addPeoOnboardingChecklistWorkQueue workQueueExists:'+workQueueExists);
           if(workQueueExists == false){
               Work_Queue__c wq = new Work_Queue__c(Account_ID__c=checklist.Prospect_Client__c, Object_Record_ID__c=checklist.Id, Object__c='PEO_Onboarding_Checklist__c');
               wq.Completed__c=false;
               upsertWorkQueues.add(wq);
           }
           else{
               system.debug('ClientSpaceHelper addPeoOnboardingChecklistWorkQueue: Checklist WQ already exists. hence preventing WQ updation');
           }
      }
   } // addPeoOnboardingChecklistWorkQueue
   //Added by Bharat - end of change
    
    public static void checkRefPeoMedAfter(Reference_PEO_Medical_UW__c[] refPeoMeds, Map<Id,Reference_PEO_Medical_UW__c> oldMap) {
       Schema.FieldSet fldSet = Schema.SObjectType.Reference_PEO_Medical_UW__c.fieldSets.ClientSpace_ChangeFlds;
       checkRecordForAccount(refPeoMeds, oldMap, 'Prospect_Client_Name__c', 'Opportunity__c', 'Reference_PEO_Medical_UW__c', fldSet);
    } // checkRefPeoMedAfter
    
    public static void checkRefPeoAfter(Reference_PEO__c[] refPeos, Map<Id,Reference_PEO__c> oldMap) {
       Schema.FieldSet fldSet = Schema.SObjectType.Reference_PEO__c.fieldSets.ClientSpace_ChangeFlds;
       checkRecordForAccount(refPeos, oldMap, 'Account_Lookup__c', 'Opportunity__c','Reference_PEO__c', fldSet);
    } // checkRefPeoAfter

    public static void checkRecordForAccount(SObject[] recs, Map<Id,SObject> oldMap, String acctFldName, String oppFldName, String objectName, Schema.FieldSet fldSet) {
       System.debug('checkRecordForAccount objectName='+objectName+' recs='+recs.size());
       Map<Id,SObject> byOppId = new Map<Id,SObject>();
       // if there's an opportunity id but no account id
       for (Sobject rec : recs) {
          Id acctId = (Id)rec.get(acctFldName);
          Id oppId = (Id)rec.get(oppFldName);
          if (acctId == null && oppId != null) {
             byOppId.put(oppId, rec);
          }
       } // for (Sobject rec : recs
       // key is the opportunity id, value is the account id
       Map<Id,Id> oppToAcctIdMap = new Map<Id,Id>();
       if (!byOppId.isEmpty()) {
          Opportunity[] opps = [Select Id, AccountId from Opportunity where Id in :byOppId.keySet() and AccountId != null];
          for (Opportunity opp : opps) {
             oppToAcctIdMap.put(opp.Id, opp.AccountId);
          }
       } // if (!byOppId.isEmpty()
       // collect the account ids of new or changed records
       Map<Id,Sobject[]> byAcctId = new Map<Id,Sobject[]>();
       for (Sobject rec : recs) {
          Sobject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
          Id acctId = (Id)rec.get(acctFldName);
          // if the account id isn't set 
          if (acctId == null) {
             Id oppId = (Id)rec.get(oppFldName);
             acctId = (oppId != null ? oppToAcctIdMap.get(oppId) : null);
          }
          
          if (acctId != null
                  && (oldRec == null || recFldsChanged(rec, oldRec, fldSet, false))) {
             SObject[] byAcctRecs = (byAcctId.containsKey(acctId) ? byAcctId.get(acctId) : new SObject[]{});
             byAcctRecs.add(rec);
             byAcctId.put(acctId,byAcctRecs);
              
          }
       } // for (Sobject rec : recs
       
       System.debug('checkRecordForAccount byAcctId='+byAcctId.size());
       if (!byAcctId.isEmpty()) {
         Map<Id,Account> acctMap = getAcctMap(byAcctId.keySet());
         Work_Queue__c[] upsertWorkQueues = new Work_Queue__c[]{};
         Account[] updateAccts = new Account[]{};

         for (Id acctId : byAcctId.keySet()) {
            Account acct = acctMap.get(acctId);
            SObject[] byAcctRecs = byAcctId.get(acctId);
            //if (acct != null && acct.UseClientSpace__c) {
            for (SObject rec : byAcctRecs) {
               //String csId = ownerMatchesAcct(acct, (Id)rec.get('OwnerId'));
               //if (csId != null) {
               //    if (!acct.UseClientSpace__c || acct.CSOwnerId__c != csId) {
               //       updateAccts.add(new Account(Id=acct.Id, UseClientSpace__c=true, CSOwnerId__c = csId));
               //    }
                if (acct != null && (acct.UseClientSpace__c || objectName == 'Reference_PEO_Medical_UW__c')) {
                   addAccountWorkQueue(acct, upsertWorkQueues);
                    if(objectName!='Opportunity')
                   {
                       Work_Queue__c wq = new Work_Queue__c(Object_Record_ID__c=rec.Id, Object__c=objectName
                                                       ,Account_ID__c=acct.Id);
                       wq.Completed__c=false;
                       upsertWorkQueues.add(wq);
                   }
               } // if (acct != null &&
            } // for (SObject rec : byAcctRecs
         } // for (Opportunity opp
         saveWorkQueues(updateAccts,null,upsertWorkQueues,objectName);
       }
    } // checkRecordForAccount

   public static void checkOppsAfter(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
      
      Map<Id,Schema.RecordTypeInfo> byIdMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosById();
      Schema.FieldSet fldSet = Schema.SObjectType.Opportunity.fieldSets.ClientSpace_OppChangeFlds;
                                     
      // get clientspace record type names
      Set<String> csRecordTypeNameSet = getClientSpaceRecordTypeNames();

      Set<Id> accountIdSet = new Set<Id>();
      Id[] oppIds = new Id[]{};
      // the opportunities that pass the initial check
      Opportunity[] oppsToCheck = new Opportunity[]{};
      Id[] oppOwnerIds = new Id[]{};
      
      // check if the opp is of the correct record type and if one of the tracked fields changed
      for (Opportunity opp : opps) {
         Schema.RecordTypeInfo rtInfo = byIdMap.get(opp.RecordTypeId);
         System.debug('checkOppsAfter rtInfo='+rtInfo);
         if (rtInfo != null && csRecordTypeNameSet.contains(rtInfo.getName())) {
            Opportunity oldRec = (oldMap != null ? oldMap.get(opp.Id) : null);
            if (recFldsChanged(opp, oldRec, fldSet, false) && opp.AccountId != null) {
               oppsToCheck.add(opp);
               accountIdSet.add(opp.AccountId);
               oppIds.add(opp.Id);
               oppOwnerIds.add(opp.OwnerId);
            }
         } // if (rtInfo != null
         
      } // for (Opportunity opp
      system.debug('oppIds'+oppIds);
      
      System.debug('checkOppsAfter oppsToCheck='+oppsToCheck.size()+' accountIdSet='+accountIdSet.size());
      // check owner names - owner should equal one of the owners on the account.
      if (!oppsToCheck.isEmpty()) {
         // get the opportunity contact roles
         OpportunityContactRole[] ocrs = [Select Id, ContactId, IsPrimary, OpportunityId, Role
                                                ,Contact.Id
                                                ,Contact.Name
                                            From OpportunityContactRole
                                           Where OpportunityId in :oppIds
                                             order by IsPrimary desc];
         // map of the contacts based on opportunityContactRole. Only take the first per OpportunityId
         Map<Id,Contact> ctctByOppIdMap = new Map<Id,Contact>();
         for (OpportunityContactRole ocr : ocrs) {
             if (!ctctByOppIdMap.containsKey(ocr.OpportunityId) && ocr.ContactId != null) {
                 ctctByOppIdMap.put(ocr.OpportunityId, ocr.Contact);
             }
         } // for
         Map<Id,Account> acctMap = getAcctMap(accountIdSet);
         Work_Queue__c[] upsertWorkQueues = new Work_Queue__c[]{};
         // update accounts to make sure they're set for ClientSpace
         Account[] updateAccts = new Account[]{};
         Contact[] updateCtcts = new Contact[]{};
         
         Map<Id,User> ownerMap = new Map<Id,User>([Select Id,UserRole.Name,Sales_Division__c,IsActive,CSUserId__c FROM User WHERE Id in:oppOwnerIds]);            
          
         PEO_Onboarding_Checklist__c[] checklists = [SELECT id,Prospect_Client__c,Opportunity__c FROM PEO_Onboarding_Checklist__c 
                                                      WHERE Prospect_Client__c in :accountIdSet //AND Opportunity__c != null
                                                      ORDER BY CreatedDate DESC];
         Map<Id,PEO_Onboarding_Checklist__c> checklistByAccountId = new Map<Id,PEO_Onboarding_Checklist__c>();
         for(PEO_Onboarding_Checklist__c checklist:checklists){
             if(!checklistByAccountId.containsKey(checklist.Prospect_Client__c)){
                 checklistByAccountId.put(checklist.Prospect_Client__c,checklist);
             }
         }

         for (Opportunity opp : oppsToCheck) {
            Account acct = acctMap.get(opp.AccountId);
            PEO_Onboarding_Checklist__c checklist = checklistByAccountId.get(opp.AccountId);
            String ownerCsId = ownerMatchesAcct(opp.Id,acct,ownerMap.get(opp.OwnerId),checklist);
            if (ownerCsId != null) {
                Boolean isAcctUpdated = false; //APR0116511
               if (!acct.UseClientSpace__c || acct.CSOwnerId__c != ownerCsId) {
                  updateAccts.add(new Account(Id=acct.Id, SendToClientSpace__c=true, UseClientSpace__c=true, CSOwnerId__c = ownerCsId));
                  //APR0116511 - do not update Account & Contact when an Opportunity is updated.
                  addAccountWorkQueue(acct, upsertWorkQueues);
                  isAcctUpdated = true;
               }
               //addAccountWorkQueue(acct, upsertWorkQueues);
               // get the contact for the opp
               Contact ctct = ctctByOppIdMap.get(opp.Id);
               if (ctct == null && acct.SignificantContact__c != null) {
                  ctct = acct.SignificantContact__r;
               }
               if (ctct == null && !acct.Contacts.isEmpty()) {
                  ctct = acct.Contacts[0];
               }
               if (ctct != null) {
                  updateCtcts.add(new Contact(Id=ctct.Id, SendToClientSpace__c=true));
                   //APR0116511 - do not update Account & Contact when an Opportunity is updated.
                  if(isAcctUpdated) addContactWorkQueue(acct, ctct, upsertWorkQueues);
               }
              // addOppWorkQueue(acct, ctct, opp.Id, upsertWorkQueues);
            } // if (acct != null &&
         } // for (Opportunity opp
         saveWorkQueues(updateAccts,updateCtcts,upsertWorkQueues,ObjectHelper.OBJECT_OPPTY);
      } // if (!oppsToCheck.isEmpty
   } // checkOppsAfter
    
   public static void addOppWorkQueue(Account acct, Contact ctct, Id oppId, Work_Queue__c[] upsertWorkQueues) {
      if (oppId != null) {
           Work_Queue__c wq = new Work_Queue__c(Object_Record_ID__c=oppId, Object__c=ObjectHelper.OBJECT_OPPTY
                                                   ,Account_ID__c=(acct != null ? acct.Id : null), Contact_ID__c=(ctct != null ? ctct.Id : null));
           wq.Completed__c=false;
           upsertWorkQueues.add(wq);
      }
   } // addOppWorkQueue
                      
   public static String ownerMatchesAcct(Id oppId,Account acct, User ownerToCheck, PEO_Onboarding_Checklist__c checklist) {
        String matchCsId = null;
        system.debug(acct.Name+' checklist'+checklist);
        if (acct != null && oppId != null && (checklist==null || (checklist!=null && (checklist.Opportunity__c == null || checklist.Opportunity__c == oppId)))) {
            if((ownerToCheck.Sales_Division__c == 'NSC' && String.isNotBlank(ownerToCheck.CSUserId__c))){
                matchCsId = ownerToCheck.CSUserId__c;
            }
            else if ((acct.OasisPEOAccountOwner__c == ownerToCheck.Id && acct.OasisPEOAccountOwner__r.IsActive 
                      && String.isNotBlank(acct.OasisPEOAccountOwner__r.CSUserId__c))) {
                matchCsId = acct.OasisPEOAccountOwner__r.CSUserId__c;
            } else if ((acct.OwnerId == ownerToCheck.Id && acct.Owner.IsActive && String.isNotBlank(acct.Owner.CSUserId__c))) {
                matchCsId = acct.Owner.CSUserId__c;
             } else if ((acct.Premier_PBS_Account_Owner__c == ownerToCheck.Id && acct.Premier_PBS_Account_Owner__r.IsActive 
                        && String.isNotBlank(acct.Premier_PBS_Account_Owner__r.CSUserId__c))) {
                matchCsId = acct.Premier_PBS_Account_Owner__r.CSUserId__c;
              }
        }
        System.debug('ownerMatchesAcct matchCsId='+matchCsId+' acct='+(acct != null ? acct.Name : 'None'));
        return matchCsId;
    } // ownerMatchesAcct
   
   public static Map<Id,User> getUserMap(Account[] recs) {
        Set<Id> userIdSet = new Set<Id>();
        Set<String> userCSIdSet = new Set<String>();
        for (Account acct : recs) {
            if (acct.OwnerId != null) {
                userIdSet.add(acct.OwnerId);
            }
            if (acct.Premier_PBS_Account_Owner__c != null) {
                userIdSet.add(acct.Premier_PBS_Account_Owner__c);
            }
            if (acct.OasisPEOAccountOwner__c != null) {
                userIdSet.add(acct.OasisPEOAccountOwner__c);
            }
            if (acct.CSOwnerId__c != null) {
                userCSIdSet.add(acct.CSOwnerId__c);
            }
        } // for (SObject rec
        Map<Id,User> userMap = getUserMap(userIdSet,userCSIdSet);
        System.debug('getUserMap recs='+recs.size()+' userIdSet='+userIdSet.size()+' userCSIdSet='+userCSIdSet.size()+' userMap='+userMap.size());
        return userMap;
    } // getUserMap
    
    public static Map<Id,User> getUserMap(Set<Id> userIdSet,Set<String> userCSIdSet) {
        Map<Id,User> userMap = null;
        if (userIdSet.isEmpty()) {
            userMap = new Map<Id,User>();
        } else {
            userMap = new Map<Id,User>([Select Id, Name, HR_Person_Id__c, Sales_Org__c, Sales_Division__c
                                        ,Profile.Name, NSS_Team__c
                                        ,CSUserId__c // the client space user id
                                        From User
                                        Where isActive=true AND (Id in :userIdSet OR CSUserId__c in: userCSIdSet)]);
        }
        return userMap;
    } // getUserMap
    
    public class OppCsWrap {
       public Id oppId = null;
       public String oppName = null;
       public Account acct = null;
       public Contact ctct = null;
       public String csUserId = null;
       public PEO_Onboarding_Checklist__c checklist = null;
    } // class OppCsWrap
    
   // check if there are opportunities that are owned by users with a CS User Id
   public static Map<Id,OppCsWrap> getOppCsIds(Id[] acctIds) {
      Map<Id,OppCsWrap> csIdMap = new Map<Id,OppCsWrap>();
      if (!acctIds.isEmpty()) {
         Opportunity[] opps = [Select Id, Name, AccountId, Account.Id
                                     ,OwnerId, Owner.Id, Owner.Name, Owner.CSUserId__c, Owner.Sales_Division__c
                                     ,(Select Id, Contactid, Contact.Id, Contact.Name, IsPrimary, Role From OpportunityContactRoles where IsPrimary=true)
                                 From Opportunity
                                Where AccountId in :acctIds
                                  and IsClosed = false
                                  and Owner.CSUserId__c != null
                                 order by CreatedDate desc];
         PEO_Onboarding_Checklist__c[] checklists = [SELECT Id,Prospect_Client__c,Opportunity__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c in :acctIds AND Opportunity__c!=null];
         Map<Id,PEO_Onboarding_Checklist__c> checklistByAccountId = new Map<Id,PEO_Onboarding_Checklist__c>();
         for(PEO_Onboarding_Checklist__c checklist:checklists){
            checklistByAccountId.put(checklist.Prospect_Client__c,checklist);
         }
         for (Opportunity opp : opps) {
            PEO_Onboarding_Checklist__c checklist = checklistByAccountId.get(opp.AccountId);
            if ((!csIdMap.containsKey(opp.AccountId) || opp.Owner.Sales_Division__c == 'NSC') && (checklist == null ||(checklist!=null && checklist.Opportunity__c == opp.Id))) {
               OppCsWrap csWrap = new OppCsWrap();
               csWrap.oppId = opp.Id;
               csWrap.oppName = opp.Name;
               csWrap.csUserId = opp.Owner.CSUserId__c;
               csWrap.acct = opp.Account;
               csWrap.ctct = (!opp.OpportunityContactRoles.isEmpty() ? opp.OpportunityContactRoles[0].Contact : null);
               csWrap.checklist = checklist;
               csIdMap.put(opp.AccountId, csWrap);
            }
         }
      } // if (!acctIds.isEmpty
      return csIdMap;
   } // getOppCsIds

   // if we want to force a record to client space, set the id here.
   public static Set<Id> forceCSIdSet = new Set<Id>();

   // if there's a CS Org Id on the account, that will be a client space account.
   // if the Send To Client Space is set, Use Client Space will be set as long as at least one of the owners has a CS Id
    
   public static void checkAccountsBefore(Account[] accts, Map<Id,Account> oldMap) {
      System.debug('checkAccountsBefore accts='+accts.size());
      Account[] acctsToProcess = new Account[]{};
      Id[] acctIds = new Id[]{};
      // do we care? I'm not sure that we do. 
      //Boolean isCsUser = isClientSpaceUser();
      // if the CS Owner Id changes, verify it against existing owners and see if we need to change the owner
      Account[] csOwnerChanged = new Account[]{};
      // if the contract status changes, check to see if we have to do anything on the account.
      Account[] csContractChanged = new Account[]{};
      Set<String> csIds = new Set<String>();
      Set<Id> ownerIds = new Set<Id>();
      // the ids of the accounts that have send to ClientSpace checked.
      Set<Id> sendToCsIdSet = new Set<Id>();
      // the ids of the accounts where the oasis owner changed and we're checking for an open opportunity owned by the same
      Set<Id> checkForOppSet = new Set<Id>();
      // only enter here if the SendToClientSpace__c is checked or the CS Org Id changes
      // if the Oasis PEO owner changes and there's an open opportunity owned by the same rep, add the acct to client space
      for (Account acct : accts) {
         Account oldAcct = (oldMap != null ? oldMap.get(acct.Id ) : null);
         System.debug('checkAccountsBefore acct='+acct.Name+' hasOld='+(oldAcct != null)+' SendToClientSpace__c='+acct.SendToClientSpace__c);
         if (oldAcct != null && ((acct.SendToClientSpace__c || (acct.CSOrgID__c != oldAcct.CSOrgID__c))
                                 || (acct.UseClientSpace__c && (acct.OwnerId != oldAcct.OwnerId
                                                         || acct.Premier_PBS_Account_Owner__c != oldAcct.Premier_PBS_Account_Owner__c
                                                         || acct.OasisPEOAccountOwner__c != oldAcct.OasisPEOAccountOwner__c
                                                         || acct.CSCMContractStatus__c != oldAcct.CSCMContractStatus__c)
                                 ))) {
            acctsToProcess.add(acct);
            // if UseClientSpace is not already true, these are the ones we can set to true
            if (acct.SendToClientSpace__c || (acct.CSOrgID__c != oldAcct.CSOrgID__c)) {
               sendToCsIdSet.add(acct.Id);                      
            }
            if (acct.Id != null) {
               acctIds.add(acct.Id);
            }
            if (acct.SendToClientSpace__c && acct.Id != null) {
               // reset the flag
               System.debug('checkAccountsBefore resetting SendToClientSpace__c flag');
               acct.SendToClientSpace__c = false;
               forceCSIdSet.add(acct.Id);
            }
         } else if (oldAcct != null && !acct.UseClientSpace__c && acct.OasisPEOAccountOwner__c != null && acct.OasisPEOAccountOwner__c != oldAcct.OasisPEOAccountOwner__c && acct.Id != null) {
            acctsToProcess.add(acct);
            checkForOppSet.add(acct.Id);
            acctIds.add(acct.Id);
         } // if (oldAcct != null
         if (oldAcct != null && String.isNotBlank(acct.CSOwnerId__c) && (acct.CSOwnerId__c != oldAcct.CSOwnerId__c)) {
            csOwnerChanged.add(acct);
            csIds.add(acct.CSOwnerId__c);
            ownerIds.add(acct.OwnerId);
            if (oldAcct.CSOwnerId__c != null) {
               csIds.add(oldAcct.CSOwnerId__c);
            }
            if (acct.Premier_PBS_Account_Owner__c != null) {
               ownerIds.add(acct.Premier_PBS_Account_Owner__c);
            }
            if (acct.OasisPEOAccountOwner__c != null) {
               ownerIds.add(acct.OasisPEOAccountOwner__c);
            }
         }
          
         if (String.isNotBlank(acct.CSCMContractStatus__c) 
                 && oldAcct != null && acct.CSCMContractStatus__c != oldAcct.CSCMContractStatus__c) {
            csContractChanged.add(acct);
         }
      } // for (Account acct
      System.debug('checkAccountsBefore acctsToProcess='+acctsToProcess.size()+' csOwnerChanged='+csOwnerChanged.size()+' csContractChanged='+csContractChanged.size());
      if (!csOwnerChanged.isEmpty()) {
         checkCSOwnerChanged(csOwnerChanged,oldMap,csIds,ownerIds);
      }
     // Commented out as part of the APR: APR0147082
       if (!csContractChanged.isEmpty()) {
         checkCsContractChanged(csContractChanged);
      }
      // if there's nothing here exist
      if (acctsToProcess.isEmpty()) {
         return;
      }
      Map<Id,User> userMap = getUserMap(acctsToProcess);
      Map<Id,OppCsWrap> csIdMap = getOppCsIds(acctIds);
      Work_Queue__c[] upsertWorkQueues = new Work_Queue__c[]{};
       
      for (Account acct : acctsToProcess) {
         // this record isn't already in CS. We're going to check the opp to see if the owner matches one of the account owners.
         // Only if there's an opp will we set the CS flag.
         Boolean onlyCheckOppForCs = checkForOppSet.contains(acct.Id);
         // 
         Boolean setUseCs = sendToCsIdSet.contains(acct.Id);
         User usr = userMap.get(acct.OwnerId);
         User usr2 = (acct.Premier_PBS_Account_Owner__c != null ? userMap.get(acct.Premier_PBS_Account_Owner__c) : null);
         User usr3 = (acct.OasisPEOAccountOwner__c != null ? userMap.get(acct.OasisPEOAccountOwner__c) : null);
         User csOwner;
         for(User u:userMap.values()){
             if(u.CSUserId__c == acct.CSOwnerId__c){
                 csOwner = u;
             }
         }
         String csId1 = (usr != null ? usr.CSUserId__c : null);
         String csId2 = (usr2 != null ? usr2.CSUserId__c : null);
         String csId3 = (usr3 != null ? usr3.CSUserId__c : null);
         String nscId = (csOwner!=null && csOwner.Sales_Division__c == 'NSC' ? csOwner.CSUserId__c : null);
         
         // UseClientSpace is set to true if the CSOrgId has a value or one of the owners has a CSUserId
         // If there's an open opp, and that CSOrgId is one of the owners, that CSUserId will be set as the User
         Boolean useClientSpace = (String.isNotBlank(acct.CSOrgID__c) || String.isNotBlank(csId3) || String.isNotBlank(csId1) || String.isNotBlank(csId2) || String.isNotBlank(nscId)); 
         OppCsWrap csWrap = csIdMap.get(acct.Id);
         System.debug('checkAccountsBefore acct='+acct.Name+' useClientSpace='+useClientSpace+' has csWrap='+(csWrap != null));
         String oppCsId = (csWrap != null ? csWrap.csUserId : null);
         String csIdToUse = ((String.isNotBlank(oppCsId) && (oppCsId == csId1 || oppCsId == csId2 || oppCsId == csId3 || oppCsId == nscId)) ? oppCsId : null);
         if (!onlyCheckOppForCs && String.isBlank(csIdToUse)) {
            csIdToUse = (String.isNotBlank(csId3) ? csId3 : (String.isNotBlank(csId2) ? csId2 : csId1));
         }
         if (onlyCheckOppForCs) {
            useClientSpace = String.isNotBlank(csIdToUse);
            addAccountWorkQueue(csWrap.acct, upsertWorkQueues);
            addContactWorkQueue(csWrap.acct, csWrap.ctct, upsertWorkQueues);
           // addOppWorkQueue(csWrap.acct, csWrap.ctct, csWrap.oppId, upsertWorkQueues);
         }
          
         // check if an account is eligible for being sent to client space.
         if (useClientSpace != acct.UseClientSpace__c) {
            acct.UseClientSpace__c = useClientSpace;
            StringHelper.addToProcessNotes(acct,'Set UseClientSpace__c to '+useClientSpace);
         }
         // if we have a new one then change it. If we don't have a new one, don't change anything.
         if (String.isNotBlank(csIdToUse) && acct.CSOwnerId__c != csIdToUse) {
            acct.CSOwnerId__c = csIdToUse;
            StringHelper.addToProcessNotes(acct,'Set CSOwnerId__c to '+csIdToUse);
         }
      } // for (Account acct : acctsToProcess
      saveWorkQueues(null,null,upsertWorkQueues,ObjectHelper.OBJECT_ACCOUNT);

   } // checkAccountsBefore
    
   //BAU Jaipal-Commented out as part of the APR: APR0147082 US3
   //  public static String HoldOut_LostClient='Oasis Lost Client';
    //Uncommented out the method(checkCsContractChanged) the Business want it back
    
   public static void checkCsContractChanged(Account[] accts) {
      Map<String,ClientSpaceMapping__mdt> csStatusMap = getCSMapping();
      for (Account acct : accts) {
         ClientSpaceMapping__mdt csm = csStatusMap.get(acct.CSCMContractStatus__c);
         System.debug('checkCsContractChanged acct='+acct.Name+' csm='+csm);
         if (csm != null && csm.AcctType__c == Label.AccountTypeLost) {
             // if the status changes to lost client, set the account to be a lost client
             System.debug('checkCsContractChanged in the lost client section');
             if (acct.Lost_Date__c == null) {
                 acct.Lost_Date__c = acct.CSCMStatusDate__c;
                 acct.Reason_Lost__c = acct.CSCMContractStatus__c;
                 acct.Client_Status__c = 'I';
                 acct.Type = Label.AccountTypeLost;
                 
                 /*
                 if (!acct.OasisPEOHoldOut__c && acct.OasisPEOAccountOwner__c != null) {
                    acct.OasisPEOHoldOut__c = true;
                    acct.OasisPEOHoldOutReason__c = HoldOut_LostClient;
                 } */
             }
         } // if (csm != null && csm.AcctType__c == 'Lost Client'
      } // for (Account acct : accts
   } // checkCsContractChanged */
    
   private static Map<String,ClientSpaceMapping__mdt> v_csStatusMap =null;
   public static Map<String,ClientSpaceMapping__mdt> getCSMapping() {
      if (v_csStatusMap == null) {
         v_csStatusMap = new Map<String,ClientSpaceMapping__mdt>();
         //for (ClientSpaceMapping__mdt csm : [Select Label, MasterLabel, AcctType__c, OpptyStatus__c from ClientSpaceMapping__mdt]) {
         for (ClientSpaceMapping__mdt csm : [Select Label, MasterLabel, AcctType__c, OpptyStatus__c, OpptyLost__c, Pull_Clientspace_States_and_Codes__c from ClientSpaceMapping__mdt]) {
             v_csStatusMap.put(csm.Label, csm);
         }
      }
      return v_csStatusMap;
   } // getCSMapping
   
   // the actions we perform when client space updates a record
   public static void checkAcctAfterFromCS(Account[] accts, Map<Id,Account> oldMap) {
      // map the clientSpace contract status to the opportunity stage
      Map<String,ClientSpaceMapping__mdt> csStatusMap = getCSMapping();

      Map<Id,Account> checkOppsMap = new Map<Id,Account>();
      Map<Id,Account> checkAssetsMap = new Map<Id,Account>();
       Map<Id,Account> csPEOCheclkistMap = new Map<Id,Account>();
      Account[] pullPEOStateAndCodeFromClientspace = new Account[]{};
          
      for (Account acct : accts) {
         Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
           if (oldAcct != null && String.isNotBlank(acct.CSCMContractStatus__c)    
                             && (acct.CSCMContractStatus__c != oldAcct.CSCMContractStatus__c    
                                 
                                ||  acct.CSCMStatusDate__c!= oldAcct.CSCMStatusDate__c    
                                 || acct.CSCMKillReason__c!= oldAcct.CSCMKillReason__c))    
              {    
                  system.debug('UpdateCSCMStatusDate');    
           csPEOCheclkistMap.put(acct.Id, Acct) ;     
          }
         if (oldAcct != null && String.isNotBlank(acct.CSCMContractStatus__c)
                             && (acct.CSCMContractStatus__c != oldAcct.CSCMContractStatus__c
                              //   || acct.First_Run_Date__c != oldAcct.First_Run_Date__c
                                 || acct.Employees__c != oldAcct.Employees__c)) {
            // depending on the status will have to either update the opportunity or the asset. 
            ClientSpaceMapping__mdt csm = csStatusMap.get(acct.CSCMContractStatus__c);
            if (csm != null) {
               if (csm.AcctType__c == Label.AccountTypeLost) {
                  // if a status goes to lost, we're going to update the Asset also so it reflects properly.
                  checkAssetsMap.put(acct.Id, acct);
               } else {
                  // if not a lost client look for an open opportunity to update
                  checkOppsMap.put(acct.Id, acct);
               }
            }
         }
          if(oldAcct != null && oldAcct.CSCMContractStatus__c != null && acct.CSCMContractStatus__c != null && oldAcct.CSCMContractStatus__c != acct.CSCMContractStatus__c) {
              ClientSpaceMapping__mdt oldAcctCSM = csStatusMap.get(oldAcct.CSCMContractStatus__c);
              ClientSpaceMapping__mdt newAcctCSM = csStatusMap.get(acct.CSCMContractStatus__c);
              if(newAcctCSM != null && newAcctCSM.Pull_Clientspace_States_and_Codes__c && (Label.CS_API_ON == 'Y' || Test.isRunningTest())) {
                  System.debug('MGF ClientSpaceHelper checkAccountsAfter adding to list.');
                  pullPEOStateAndCodeFromClientspace.add(acct);
              }
          }
          /*
          if((oldAcct != null && oldAcct.CSCMContractStatus__c != null && oldAcct.CSCMContractStatus__c != 'Underwriting' && oldAcct.CSCMContractStatus__c != 'Approved') 
             && (acct.CSCMContractStatus__c != null && acct.CSCMContractStatus__c == 'Underwriting' || acct.CSCMContractStatus__c == 'Approved')
            && (Label.CS_API_ON == 'Y' || Test.isRunningTest()))
          {
              System.debug('MGF ClientSpaceHelper checkAccountsAfter adding to list.');
              pullPEOStateAndCodeFromClientspace.add(acct);
          }*/
      } // for (Account acct
      if (!checkOppsMap.isEmpty()) {
         checkCSOpps(checkOppsMap, csStatusMap);
      }
      if (!checkAssetsMap.isEmpty()) {
         checkCSAssets(checkAssetsMap, csStatusMap);
      }
         if (!csPEOCheclkistMap.isEmpty()) {    
         system.debug('UpdateCSCMStatusDate');    
         checkPEOChecklist(csPEOCheclkistMap);    
      }
       if(!pullPEOStateAndCodeFromClientspace.isEmpty())
       {
           pullStatesAndCodesFromClientspace(null, pullPEOStateAndCodeFromClientspace);
       }
   } // checkAcctAfterFromCS
    
   public static void checkCSOpps(Map<Id,Account> acctMap, Map<String,ClientSpaceMapping__mdt> csStatusMap) {
        //    PEO_Onboarding_Checklist__c[] peoCheck = [SELECT Id, Prospect_Client__c, Opportunity__c From PEO_Onboarding_Checklist__c   
                              //                WHERE Prospect_Client__c in: acctMap.keySet()];  
      
    //  Set<Id> oppId = new Set<Id>();  
    //  for(PEO_Onboarding_Checklist__c peo : peoCheck){  
    //       oppId.add(peo.Opportunity__c);  
   //   } 
       
      Opportunity[] opps = [Select Id, Name, AccountId, RecordType.Name, CloseDate, StageName, Employees_Paid_Per_Payroll__c, Reason_Not_Sold__c
                                       // only select the line items where we might update the products. 
                                       ,(Select Id, Name, Product2Id, TotalPrice
                                               ,Product2.Name, Product2.ProductCode, Product2.CreateAssetWhenSold__c, Product2.Sales_Org__c
                                           From OpportunityLineItems
                                          Where Product2.ClientSpaceProduct__c=true
                                          order by CreatedDate desc)
                                   From Opportunity
                                  Where IsClosed = false
                                    and AccountId in :acctMap.keySet()
                              //       and Id in :oppId
                                   order by CreatedDate desc];
       
      Opportunity[] updateOpps = new Opportunity[]{};
      OpportunityLineItem[] updateOlis = new OpportunityLineItem[]{};
      Map<String, OpportunityStage> mapStatusToStage = OpptyMethods.getOppStageMap();
      for (Opportunity opp : opps) {
          System.debug('checkCSOpps opp='+opp);
         RecordType__c rtSetting = RecordTypeHelper.getRtSetting(opp.RecordType.Name);
          System.debug('checkCSOpps rtSetting='+rtSetting);
         if (rtSetting != null && rtSetting.UseForClientSpace__c) {
            // remove it so we only process one for each account
            Account acct = acctMap.remove(opp.AccountId);
            if (acct != null) {
               Boolean oppUpdated = false;
                System.debug('checkCSOpps acct='+acct);
                System.debug('checkCSOpps rtSetting.CSStatusUpdate__c='+rtSetting.CSStatusUpdate__c);
                System.debug('checkCSOpps acct.CSCMContractStatus__c='+acct.CSCMContractStatus__c);
                System.debug('checkCSOpps csStatusMap='+csStatusMap);
               if (rtSetting.CSStatusUpdate__c) {
                  ClientSpaceMapping__mdt csm = (String.isNotBlank(acct.CSCMContractStatus__c) ? csStatusMap.get(acct.CSCMContractStatus__c) : null);
                   System.debug('checkCSOpps csm='+csm);
                   System.debug('checkCSOpps csm.OpptyStatus__c='+csm.OpptyStatus__c);
                   System.debug('checkCSOpps opp.StageName='+opp.StageName);
                  Boolean isLost = (csm != null && csm.OpptyLost__c); 
                   System.debug('checkCSOpps isLost='+isLost);
                  if (csm != null && csm.OpptyStatus__c != opp.StageName) {
                          System.debug('checkCSOpps Inside if');
                          Boolean letStageUpdate = true;
                          if(mapStatusToStage.containsKey(csm.OpptyStatus__c) && mapStatusToStage.containsKey(opp.StageName) && (opp.StageName == 'Verbal Commit' || opp.StageName == 'Sold' || opp.StageName == 'Sold – Submitted' || opp.StageName == 'Sold - Submitted' )){
                              if(mapStatusToStage.get(csm.OpptyStatus__c).DefaultProbability < mapStatusToStage.get(opp.StageName).DefaultProbability) {
                                  letStageUpdate = false;
                              }
                          }
                          if(letStageUpdate){
                              opp.StageName = (csm != null ? csm.OpptyStatus__c : opp.StageName);
                          }
                    
                         System.debug('checkCSOpps opp.StageName='+opp.StageName);
                         //if (opp.StageName == 'Not Sold') {
                          if (isLost) {
                            System.debug('checkCSOpps Reason_Not_Sold__c='+acct.CSCMKillReason__c);
                            opp.Reason_Not_Sold__c = acct.CSCMKillReason__c;
                         }
                         oppUpdated = true;
                 }
                   System.debug('checkCSOpps opp final='+opp);
                   //System.debug('checkCSOpps opp='+opp.Name+' OasisRevenue__c='+acct.OasisRevenue__c+' lineItems='+opp.OpportunityLineItems.size()+' CSOtherInfoUpdate__c='+rtSetting.CSOtherInfoUpdate__c);
                  // if there's corresponding revenue, just take the latest one
                  //if (rtSetting.CSOtherInfoUpdate__c && opp.StageName != 'Not Sold' && acct.OasisRevenue__c != null && !opp.OpportunityLineItems.isEmpty()) {
                  /*if (rtSetting.CSOtherInfoUpdate__c && !isLost && acct.OasisRevenue__c != null && !opp.OpportunityLineItems.isEmpty()) {
                     OpportunityLineItem oli = opp.OpportunityLineItems[0];
                     oli.TotalPrice = acct.OasisRevenue__c;
                     System.debug('checkCSOpps updating TotalPrice to '+acct.OasisRevenue__c);
                     updateOlis.add(oli);
                  }*/  
               }
               if (rtSetting.CSOtherInfoUpdate__c && (
                                                       //(acct.First_Run_Date__c != null && acct.First_Run_Date__c != opp.CloseDate) 
                                                      // || 
                                                      (acct.Employees__c != null && acct.Employees__c != opp.Employees_Paid_Per_Payroll__c))) {
                  //opp.CloseDate = (acct.First_Run_Date__c != null ? acct.First_Run_Date__c : opp.CloseDate);
                  opp.Employees_Paid_Per_Payroll__c = (acct.Employees__c != null ? acct.Employees__c : opp.Employees_Paid_Per_Payroll__c);
                  oppUpdated = true;
               }
               if (oppUpdated) {
                          
                  updateOpps.add(opp);
               }
               
            } // if (acct != null
         } // if (rtSetting != null && rtSetting.UseForClientSpace__c
      } // for (Opportunity opp
      DmlHelper.performDML2(updateOpps, DmlHelper.DML_UPDATE, 'ClientSpaceHelper', 'checkCSOpps', 'Updating Opportunities', false);
      DmlHelper.performDML2(updateOlis, DmlHelper.DML_UPDATE, 'ClientSpaceHelper', 'checkCSOpps', 'Updating OpportunityLineItems', false);
      ErrorLog.checkSave();

   } // checkCSOpps
    
   public static void checkCSAssets(Map<Id,Account> acctMap, Map<String,ClientSpaceMapping__mdt> csStatusMap) {
      Asset[] updateAssets = new Asset[]{};
      // only select the assets relevant to PEO
      Asset[] assets = [Select Id, Name, AccountId, Plan_Cancel_Date__c, Product_End_Date__c, ProductCode, Plan_Lost_Reason__c
                                   From Asset
                                  Where Plan_Cancel_Date__c = null
                                    and Paychex_Asset_Id__c = null
                                    and Product2Id != null
                                    and AccountId in :acctMap.keySet()
                                    and Product2.ClientSpaceProduct__c=true];
      for (Asset asst : assets) {
         Account acct = acctMap.remove(asst.AccountId);
         if (acct != null) {
            asst.Plan_Cancel_Date__c = acct.CSCMStatusDate__c;
            asst.Product_End_Date__c = acct.CSCMStatusDate__c;
            asst.Plan_Lost_Reason__c = 'Ended from ClientSpace';
            updateAssets.add(asst);
         } // if (acct != null
      } // for (Asset asst : assets
      DmlHelper.performDML2(updateAssets, DmlHelper.DML_UPDATE, 'ClientSpaceHelper', 'checkCSAssets', 'Updating Assets', true);
   } // checkCSAssets
     public static void checkPEOChecklist(Map<Id,Account> acctMap) {    
      PEO_Onboarding_Checklist__c[] updatePEOs = new PEO_Onboarding_Checklist__c[]{};    
      // only select the assets relevant to PEO    
      PEO_Onboarding_Checklist__c[] PEOs = [Select Id, Name, Prospect_Client__c  , CS_CM_Contract_Status__c  ,CS_CM_Status_Date__c, CS_CM_Kill_Reason__c      
                                   From PEO_Onboarding_Checklist__c    
                                  Where  Prospect_Client__c in :acctMap.keySet()    
                                    ];    
        system.debug('CheckacctMap'+ acctMap+ 'PEOList'+ PEOs);    
      for (PEO_Onboarding_Checklist__c peo : PEOs) {    
         Account acct = acctMap.get(peo.Prospect_Client__c);    
         if (acct != null) {    
            peo.CS_CM_Status_Date__c = acct.CSCMStatusDate__c;    
            peo.CS_CM_Contract_Status__c   = acct.CSCMContractStatus__c;    
            peo.CS_CM_Kill_Reason__c = acct.CSCMKillReason__c;    
            updatePEOs.add(peo);    
         } // if (acct != null    
      } // for (Asset asst : assets    
      DmlHelper.performDML2(updatePEOs, DmlHelper.DML_UPDATE, 'ClientSpaceHelper', 'checkPEOChecklist', 'Updating PEOChecklist', true);    
   } // checkCSAssets
   public static void checkAccountsAfter(Account[] accts, Map<Id,Account> oldMap) {
      Work_Queue__c[] upsertWorkQueues = new Work_Queue__c[]{};
      Id[] wqIdsInserted = new Id[]{};
      Map<String,ClientSpaceMapping__mdt> csStatusMap = getCSMapping();
      Account[] pullPEOStateAndCodeFromClientspace = new Account[]{};
      Account[] salesParentChanged = new Account[]{};
      Account[] PEOAccountOwnerChange = new Account[]{};
      Schema.FieldSet acctFldSet = Schema.SObjectType.Account.fieldSets.ClientSpace_AcctChangeFlds;
      // only send the account down if the main owner has the cs user id or the cs org id is populated

       for (Account acct : accts) {
           Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
           System.debug('checkAccountsAfter acct='+acct.Name+' UseClientSpace__c='+acct.UseClientSpace__c);
           
           if(oldAcct != null) {
               if(oldAcct.SalesParent__c == null && acct.SalesParent__c != null) {
                   salesParentChanged.add(acct);
               }
               else if(oldAcct.SalesParent__c != null && acct.SalesParent__c == null) {
                   salesParentChanged.add(acct);
               }
           }
           
           if (acct.UseClientSpace__c) {
               // check if we're forcing it through or additional field change criteria
               if (forceCSIdSet.contains(acct.Id) || recFldsChanged(acct,OldAcct,acctFldSet,true)) {
                   addAccountWorkQueue(acct, upsertWorkQueues);
               }
           }
           if(oldAcct != null && oldAcct.CSCMContractStatus__c != null && acct.CSCMContractStatus__c != null && oldAcct.CSCMContractStatus__c != acct.CSCMContractStatus__c) {
               ClientSpaceMapping__mdt oldAcctCSM = csStatusMap.get(oldAcct.CSCMContractStatus__c);
               ClientSpaceMapping__mdt newAcctCSM = csStatusMap.get(acct.CSCMContractStatus__c);
               if(newAcctCSM != null && newAcctCSM.Pull_Clientspace_States_and_Codes__c && (Label.CS_API_ON == 'Y' || Test.isRunningTest())) {
                   System.debug('MGF ClientSpaceHelper checkAccountsAfter adding to list.');
                   pullPEOStateAndCodeFromClientspace.add(acct);
               }
           }
           
           if(oldAcct != null && oldAcct.OasisPEOAccountOwner__c!=acct.OasisPEOAccountOwner__c
                    && (acct.CSCMContractStatus__c=='Prospect' || String.isEmpty(acct.CSCMContractStatus__c))){
                        PEOAccountOwnerChange.add(acct);
           }
           
           /*
if((oldAcct != null && oldAcct.CSCMContractStatus__c != null && oldAcct.CSCMContractStatus__c != 'Underwriting' && oldAcct.CSCMContractStatus__c != 'Approved') 
&& (acct.CSCMContractStatus__c != null && acct.CSCMContractStatus__c == 'Underwriting' || acct.CSCMContractStatus__c == 'Approved')
&& (Label.CS_API_ON == 'Y' || Test.isRunningTest()))
{
System.debug('MGF ClientSpaceHelper checkAccountsAfter adding to list.');
pullPEOStateAndCodeFromClientspace.add(acct);
}*/
       } // for (Contact ctct
       if(!pullPEOStateAndCodeFromClientspace.isEmpty())
       {
           pullStatesAndCodesFromClientspace(null, pullPEOStateAndCodeFromClientspace);
       }
       
       if(!salesParentChanged.isEmpty()) {
           updateParentChecklistLookups(salesParentChanged);
       }
       
       if(!PEOAccountOwnerChange.isEmpty())
       {
        PEOAccountOwnerChangeUpdates(PEOAccountOwnerChange);
       }
       
      //saveWorkQueues(null,null,upsertWorkQueues,ObjectHelper.OBJECT_ACCOUNT);
       //Added by Jidesh
       if (!upsertWorkQueues.isEmpty()) {
           DmlHelper.prepareForSave();
           DmlHelper.DmlResult dmlResult = DmlHelper.initializeDmlResult(upsertWorkQueues, DmlHelper.DML_UPSERT, 'ClientSpaceHelper', 'saveWorkQueues', 'upserting work queues from Account');
           Database.UpsertResult[] results = Database.upsert(upsertWorkQueues,Work_Queue__c.Fields.Object_Record_ID__c,false);
           System.debug('results:'+results);
           DmlHelper.handleUpsertResults(upsertWorkQueues, results, dmlResult);
           for(Integer index = 0, size = results.size(); index < size; index++) {
               if(results[index].isSuccess()) {
                   if(results[index].isCreated()) {
                       System.debug('WQ was Inserted');
                       wqIdsInserted.add(results[index].getId());
                   } else {
                       System.debug('WQ was updated');
                   }
               }
           }
           System.debug('wqIdsInserted:'+wqIdsInserted);
           if (!wqIdsInserted.isEmpty()){
               resetWorkQueues(upsertWorkQueues,wqIdsInserted);
           }
       }
   } // checkAccountsAfter
   
   public static void PEOAccountOwnerChangeUpdates(Account[] AccountList){
        List<Id> PEOOwnerIds =new List<Id>();
        List<PEO_Onboarding_Checklist__c> checklistsToUpdate = new List<PEO_Onboarding_Checklist__c>();

        Id recordTypeId1 = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('PEO Opportunity Record Type').getRecordTypeId();
        Id recordTypeId2 = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Prism PEO Opportunity Record Type').getRecordTypeId();
       
        PEO_Onboarding_Checklist__c[] PEOChecklist = [SELECT Id, Name, OwnerId, RecordType.Name, Sales_Rep__c,Prospect_Client__c,Opportunity__c,Sales_Analyst__c,
                                Prospect_Client__r.OasisPEOAccountOwner__c,CSCMContractStatus__c,RecordTypeId
                                FROM PEO_Onboarding_Checklist__c
                                WHERE Prospect_Client__c in :AccountList];
        
        for(Account Acc: AccountList){
            PEOOwnerIds.add(Acc.OasisPEOAccountOwner__c);
        }
        Opportunity[] PEOOpties = [Select Id,OwnerId,AccountId from Opportunity 
                                    where OwnerId In : PEOOwnerIds
                                    AND AccountId in : AccountList
                                    AND (RecordTypeId=:recordTypeId1 OR RecordTypeId=:recordTypeId2)
                                    ORDER BY  CreatedDate ASC];
        if(PEOChecklist.size()>0 && PEOOpties.Size()>0){
            for(PEO_Onboarding_Checklist__c ch : PEOChecklist){
                if(ch.Sales_Rep__c!=ch.Prospect_Client__r.OasisPEOAccountOwner__c){
                    for(Opportunity op: PEOOpties ){
                        if(op.OwnerId==ch.Prospect_Client__r.OasisPEOAccountOwner__c 
                                && ch.Prospect_Client__c==op.AccountId){
                                    ch.Opportunity__c=op.Id;
                                    ch.Sales_Rep__c=ch.Prospect_Client__r.OasisPEOAccountOwner__c;
                                    if(ch.Sales_Analyst__c==null){  
                                        ch.OwnerId=ch.Prospect_Client__r.OasisPEOAccountOwner__c;
                                    }//jc fix for cs updading checklist owner when there is an nbsc
                                    checklistsToUpdate.add(ch);
                                }
                    }
                }
            }
            if(!checklistsToUpdate.isEmpty()) {
                DmlHelper.performDML2(checklistsToUpdate, DmlHelper.DML_UPDATE, 'ClientSpaceHelper', 'PEOAccountOwnerChangeUpdates', 'Updating Checklists', false);
            }
        }
   }
    
   public static void updateParentChecklistLookups(Account[] salesParentChanged) {
        List<Id> accountIds = new List<Id>();
        List<Id> parentAccountIds = new List<Id>();
        List<PEO_Onboarding_Checklist__c> checklistsToUpdate = new List<PEO_Onboarding_Checklist__c>();
        
        
        for(Account acct : salesParentChanged) {
            if(!accountIds.contains(acct.Id)) {
                accountIds.add(acct.Id);
            }
            if(acct.SalesParent__c != null && !parentAccountIds.contains(acct.SalesParent__c)) {
                parentAccountIds.add(acct.SalesParent__c);
            }
        }
        
        //Get checklists for all parent and child accounts
        Map<Id, Account> childAccounts = new Map<Id, Account>([SELECT Id, Name, SalesParent__c, (SELECT Id, Name, Parent_PEO_Checklist__c FROM PEO_Onboarding_Checklists__r ORDER BY CreatedDate DESC LIMIT 1) FROM Account WHERE Id IN :accountIds]);
        Map<Id, Account> parentAccounts = new Map<Id, Account>([SELECT Id, Name, SalesParent__c, (SELECT Id, Name, Parent_PEO_Checklist__c FROM PEO_Onboarding_Checklists__r ORDER BY CreatedDate DESC LIMIT 1) FROM Account WHERE Id IN :parentAccountIds]);
        
        for(Account acc : childAccounts.values()) {
            
            //If sales parent field has been populated, fill in the checklists Parent lookup as well.
            if(acc.SalesParent__c != null && parentAccounts.containsKey(acc.SalesParent__c)) {
                Account parentAccount = parentAccounts.get(acc.SalesParent__c);
                if(acc.PEO_Onboarding_Checklists__r != null && acc.PEO_Onboarding_Checklists__r.size() == 1 && parentAccount.PEO_Onboarding_Checklists__r != null && parentAccount.PEO_Onboarding_Checklists__r.size() == 1) {
                    PEO_Onboarding_Checklist__c childChecklist = acc.PEO_Onboarding_Checklists__r[0];
                    PEO_Onboarding_Checklist__c parentChecklist = parentAccount.PEO_Onboarding_Checklists__r[0];
                    
                    if(childChecklist.Parent_PEO_Checklist__c != parentChecklist.Id) {
                        childChecklist.Parent_PEO_Checklist__c = parentChecklist.Id;
                        checklistsToUpdate.add(childChecklist);
                    }
                }
            }
            //If SalesParent has been cleared out, clear out the Checklists parent.
            else if(acc.SalesParent__c == null) {
                if(acc.PEO_Onboarding_Checklists__r != null && acc.PEO_Onboarding_Checklists__r.size() == 1) {
                    PEO_Onboarding_Checklist__c checklist = acc.PEO_Onboarding_Checklists__r[0];
                    
                    if(checklist.Parent_PEO_Checklist__c != null) {
                        checklist.Parent_PEO_Checklist__c = null;
                        checklistsToUpdate.add(checklist);
                    }
                }
            }
        }
        
        //Use DML here instead of normal update call.
        if(!checklistsToUpdate.isEmpty()) {
            DmlHelper.performDML2(checklistsToUpdate, DmlHelper.DML_UPDATE, 'ClientSpaceHelper', 'updateParentChecklistLookups', 'Updating Checklists', false);
        }
    }
    
   public static void addAccountWorkQueue(Account acct, Work_Queue__c[] upsertWorkQueues) {
      System.debug('addAccountWorkQueue creating Work_Queue__c record hasAcct='+(acct != null));
      if (acct != null) {
         Boolean workQueueExists = checkExistingWorkQueue(acct.Id, null,'Account',acct.Id);
          if(workQueueExists == false){
              Work_Queue__c wq = new Work_Queue__c(Object_Record_ID__c=acct.Id, Account_ID__c=acct.Id, Object__c=ObjectHelper.OBJECT_ACCOUNT);
              wq.Completed__c=false;
              upsertWorkQueues.add(wq);
          }
          else{
              system.debug('ClientSpaceHelper addAccountWorkQueue: Acc WQ already exists. hence preventing WQ updation');
          }
      }
   } // addAccountWorkQueue

    public static void checkLocationsForAccount(Set<Id> AccountIds) {
        System.debug('In locations check');
        // for the account list retrieve the parent account
        Map<Id, Account[]> accountResult = communityMethods.getAccountInformation(AccountIds, 'checkLocationsForAccount', 'ClientSpaceHelper');
        for (Id acctId : accountResult.keySet()) {
            list<Account> accountsForParent = accountResult.get(acctId);
            for (Account acc: accountsForParent) {
                if (acc.isParent__c && acc.UseClientSpace__c && acc.CSOrgID__c != null) {
                    ClientSpaceLocationQueueable csLocQueueable = new ClientSpaceLocationQueueable('gen_ClientMaster', 'POST',
                                                                                                   'x_oas_ClientMaster_SFGUID_list',
                                                                                                   acctId, accountsForParent, false, null, null, null,null,null);
                    System.enqueueJob(csLocQueueable);
                }
            }
        }
    }
    
    /*public static void checkLocationsForAccount(Id parentId) {
        System.debug('In locations check');
        // for the account list retrieve the parent account
        Account[] accts = communityMethods.getAccountInformation(parentId, 'checkLocationsForAccount', 'ClientSpaceHelper');
        Account ParentAcc;
        for (Account acc: accts) {
            if (acc.isParent__c && acc.UseClientSpace__c) {
                ParentAcc = acc;
                break;
            }
        }
        if (ParentAcc != null && ParentAcc.CSOrgID__c != null) {
            // send a request to get a list of locations: pass set of IDs into method
            ClientSpaceLocationQueueable csLocQueueable = new ClientSpaceLocationQueueable('gen_ClientMaster', 'POST',
                                                                                           'x_oas_ClientMaster_SFGUID_list',
                                                                                           parentAcc.Id, accts, false, null, null, null,null,null);
            System.enqueueJob(csLocQueueable);
        }
        // send location list to location create call
    }*/
    
    //Added by Bharat to create Work Queue record for Medical Questionnaire- Start of change
   public static void checkPeoMedicalQuestionnaireBefore(PEO_Onboarding_Medical_Questionnaire__c [] medicalQuestionnaire, Map<Id,PEO_Onboarding_Medical_Questionnaire__c> oldMap) {
      for (PEO_Onboarding_Medical_Questionnaire__c questn : medicalQuestionnaire) {
          if (questn.Id != null) {
              forceCSIdSet.add(questn.Id);
          }    
      } 
   } //checkPeoMedicalQuestionnaireBefore

   public static void checkPeoMedicalQuestionnaireAfter(PEO_Onboarding_Medical_Questionnaire__c [] medicalQuestionnaire, Map<Id,PEO_Onboarding_Medical_Questionnaire__c> oldMap) {
      Work_Queue__c[] upsertWorkQueues = new Work_Queue__c[]{};
      Schema.FieldSet medQuestnFldSet = Schema.SObjectType.PEO_Onboarding_Medical_Questionnaire__c.fieldSets.questions;
       Map<Id, PEO_Onboarding_Medical_Questionnaire__c> medQuestnRecById = new Map<Id, PEO_Onboarding_Medical_Questionnaire__c>([SELECT Id, PEO_Onboarding_Checklist__r.Prospect_Client__c, 
                                                                                                                                 PEO_Onboarding_Checklist__r.Prospect_Client__r.isParent__c, 
                                                                                                                                 PEO_Onboarding_Checklist__r.Prospect_Client__r.salesParent__c,
                                                                                                                                 PEO_Onboarding_Checklist__r.Prospect_Client__r.isChild__c,
                                                                                                                                 PEO_Onboarding_Checklist__r.Client_Add_on__c
                                                                                                                                 FROM PEO_Onboarding_Medical_Questionnaire__c WHERE Id IN:medicalQuestionnaire]);
       
       for (PEO_Onboarding_Medical_Questionnaire__c questn : medicalQuestionnaire) {
           System.debug('checkPeoMedicalQuestionnaireAfter questn='+questn.Name);
           PEO_Onboarding_Medical_Questionnaire__c oldMedQuestn = (oldMap != null ? oldMap.get(questn.Id) : null);
           // check if we're forcing it through or additional field change criteria
           if(forceCSIdSet.contains(questn.Id) || recFldsChanged(questn,oldMedQuestn,medQuestnFldSet,false)) {
               Id accToAppndId;
               // if the accoount is not a parent account, get the parent account ID
               // Account is not parent and is a child
               Id accountToAppend;
               PEO_Onboarding_Medical_Questionnaire__c questionnnaireWthLookups = medQuestnRecById.get(questn.Id);
               Boolean prospectIsNotParent = !questionnnaireWthLookups.PEO_Onboarding_Checklist__r.Prospect_Client__r.isParent__c;
               Boolean prospectIsChild = questionnnaireWthLookups.PEO_Onboarding_Checklist__r.Prospect_Client__r.isChild__c;
               Boolean prospectIsSingleID = !questionnnaireWthLookups.PEO_Onboarding_Checklist__r.Prospect_Client__r.isParent__c && !questionnnaireWthLookups.PEO_Onboarding_Checklist__r.Prospect_Client__r.isChild__c;
               Boolean isclientAddOn = questionnnaireWthLookups.PEO_Onboarding_Checklist__r.Client_Add_on__c;
               if (prospectIsNotParent && (prospectIsChild && !isclientAddOn)) {
                   accountToAppend = questionnnaireWthLookups.PEO_Onboarding_Checklist__r.Prospect_Client__r.salesParent__c;
               } else {
                   accountToAppend = questionnnaireWthLookups.PEO_Onboarding_Checklist__r.Prospect_Client__c;
               }
               //addPeoMedicalQuestionnaireWorkQueue(questn, upsertWorkQueues, accountToAppend);
           }
       }
      // saveWorkQueues(null,null,upsertWorkQueues,'PEO_Onboarding_Medical_Questionnaire__c');
   } // checkPeoMedicalQuestionnaireAfter
    
    
   public static void addPeoMedicalQuestionnaireWorkQueue(PEO_Onboarding_Medical_Questionnaire__c questn, Work_Queue__c[] upsertWorkQueues, String accId) {
      System.debug('accId in medQuestion: '+accId);
      System.debug('addPeoMedicalQuestionnaireWorkQueue creating Work_Queue__c record='+(questn != null));
      if (questn != null) {
            Boolean workQueueExists = checkExistingWorkQueue(accId, null,'PEO_Onboarding_Medical_Questionnaire__c',questn.Id);
            if(workQueueExists == false){
                Work_Queue__c wq = new Work_Queue__c(Account_ID__c=accId, Object_Record_ID__c=questn.Id, Object__c='PEO_Onboarding_Medical_Questionnaire__c');
                wq.Completed__c=false;
                upsertWorkQueues.add(wq);
            }
            else{
                system.debug('ClientSpaceHelper addPeoMedicalQuestionnaireWorkQueue:  MedQ WQ already exists,Hence preventing WQ updation');
            }
        }
   } // addPeoMedicalQuestionnaireWorkQueue
   //Added by Bharat to create Work Queue record for Medical Questionnaire - End of change 

    public static void pullStatesAndCodesFromClientspace(Map<Id,PEO_Onboarding_Checklist__c> checklistMap,  Account[] pullPEOStateAndCodeFromClientspace) {
        
        List<Id> accountIds = new List<Id>();
        if(checklistMap != null && !checklistMap.isEmpty()) {
            for(PEO_Onboarding_Checklist__c checklist : checklistMap.values()) {
                accountIds.add(checklist.Prospect_Client__c);
            }
            
            pullPEOStateAndCodeFromClientspace = [SELECT Id, Name FROM Account WHERE Id IN :accountIds];
        }
        
        if(pullPEOStateAndCodeFromClientspace != null && !pullPEOStateAndCodeFromClientspace.isEmpty()) {
            System.debug('MGF ClientSpaceHelper checkAccountsAfter calling ClientspaceAPIQueueable pullPEOStateAndCodeFromClientspace.size()='+pullPEOStateAndCodeFromClientspace.size());
            ClientspaceAPIQueueable caq = new ClientspaceAPIQueueable(pullPEOStateAndCodeFromClientspace, null, 'State Code Post', null,null,'f4e8c3d6-63e4-42df-90e0-c95b7285a92e','193428',null, null,null,null);
            System.enqueueJob(caq);
        }
    }
    
    //this will take documents related to the checklist and send them into a queueable per doc.  Need each doc to be in a separate queuable to allow for the maximum
    //heap size per doc.  Added wait in because if we try to patch the same record back to back at the same time, CS gets a row lock.  Would a batch be a better way?
    //TO DO: Make cs project ID and GUID dynamic.  What happens when we need to send multiple files from the same doc at the same time?
    public static void sendDocumentsToClientspaceFromChecklist(Map<Id,PEO_Onboarding_Checklist__c> checklistMap,  Map<Id,PEO_Onboarding_Checklist__c>  parentAccToChecklistMap){
        System.debug('Starting doc send process...');
        System.debug('checklistMap: ' + checklistMap);
        System.debug('parentAccToChecklistMap: '+parentAccToChecklistMap);
        PEO_Onboarding_Document__c[] docsForQueuable = new PEO_Onboarding_Document__c[]{};
            Map<Id,PEO_Onboarding_Document_Map__c> docMapByDocId = new Map<Id,PEO_Onboarding_Document_Map__c>();
        Map<Id, List<PEO_Onboarding_Document__c>> parentAccToDocsMap = new Map<Id, List<PEO_Onboarding_Document__c>>();
        String parentAccId;
        // grab all the documents that are approved and related to a checklist in our checklist map
        // this also gets the documents where the parent account field is found in the map we pass in
        // change this so that it checks to see if the prospects salesparent field is in that map we have
        PEO_Onboarding_Document__c[] allDocs = [Select Id,status__c,Routing_Name__c ,Docs_Sent_to_Clientspace__c,Parent_Account__c,
                                                PEO_Onboarding_Checklist__c,PEO_Onboarding_Checklist__r.Submit_Docs_to_Clientspace__c,
                                                PEO_Onboarding_Checklist__r.HSF_Submission_Status__c,PEO_Onboarding_Checklist__r.HSF_Status_Change_Date__c,
                                                Date_Uploaded__c, Date_Sent_to_Clientspace__c, PEO_Onboarding_Checklist__r.prospect_client__r.isParent__c,
                                                PEO_Onboarding_Checklist__r.prospect_client__r.salesParent__c, PEO_Onboarding_Checklist__r.prospect_client__r.isChild__c, 
                                                PEO_Onboarding_Checklist__r.prospect_client__r.Id, Prospect_Client_Name__c,
                                                PEO_Onboarding_Checklist__r.Parent_PEO_Checklist__c,
                                                PEO_Onboarding_Checklist__r.Opportunity__r.viewInClientSpace__c,
                                                PEO_Onboarding_Checklist__r.Current_Step__c, PEO_Onboarding_Checklist__r.Sent_to_ClientSpace_Status_Date__c,
                                                PEO_Onboarding_Checklist__r.Client_Add_on__c, PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c, 
                                                PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c
                                                FROM PEO_Onboarding_Document__c WHERE Status__c = 'Approved' 
                                                AND (PEO_Onboarding_Checklist__c in :checklistMap.keySet()   
                                                     OR PEO_Onboarding_Checklist__r.prospect_client__r.salesParent__c in :parentAccToChecklistMap.keySet())];
        // AND PEO_Onboarding_Checklist__r.Prospect_Client__r.CSCMContractStatus__c = 'Prospect'];
        for(PEO_Onboarding_Document__c doc : allDocs){
            Boolean documentPartOfSubmitRequest = false;
            Boolean documentPartOfHsfSubmission = false;
            System.debug('sendDocumentsToClientspaceFromChecklist doc:'+doc);
            // get the checklsit that the document is related to
            // any documents being submitted for a child will not have their checklist as a part of the map
            PEO_Onboarding_Checklist__c checklist = checklistMap.get(doc.PEO_Onboarding_Checklist__c);
            // get the document cs map for the document
            PEO_Onboarding_Document_Map__c docMapping = PEO_Onboarding_Document_Map__c.getInstance(doc.Routing_Name__c);
            System.debug('sendDocumentsToClientspaceFromChecklist docMapping:'+docMapping);
            System.debug('sendDocumentsToClientspaceFromChecklist docMapping:'+docMapping);
            System.debug('sendDocumentsToClientspaceFromChecklist checklist:'+checklist);
            System.debug('sendDocumentsToClientspaceFromChecklist checklist Medical_Underwriting_Path_Type__c:'+checklist.Medical_Underwriting_Path_Type__c);
            if(docMapping != null && docMapping.Name == 'Census' && checklist.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical'){
                docMapping = PEO_Onboarding_Document_Map__c.getInstance('HSF Census');
                System.debug('Updated the Doc mapping for Census since its a QQ - new docmapping:'+docMapping);
            }
            // if the checklist is null use the documents checklist lookups to determine if the submission includes this doc
            // this effects documents that should be included for submission when the submission is initiated off a parent
            // checklist
            if (checklist == null) {
                checklist = checklistMap.get(doc.PEO_Onboarding_Checklist__r.Parent_PEO_Checklist__c);    
            } 
            Boolean checklistIsClientAddOn = checklist.Client_Add_on__c;
            System.debug('sendDocumentsToClientspaceFromChecklist checklist:'+checklist);
            if (docMapping != null && checklist != null) {
                System.debug('sendDocumentsToClientspaceFromChecklist Doc mapping:'+docMapping);
                System.debug('sendDocumentsToClientspaceFromChecklist Doc routing name:'+doc.Routing_Name__c);
                documentPartOfSubmitRequest =  (((checklist.Submit_Docs_to_Clientspace__c == 'All') || (checklist.Submit_Docs_to_Clientspace__c == docMapping.Document_Category__c))&& (doc.Routing_Name__c != Label.HSF_Routing_Name));   
            	documentPartOfHsfSubmission = (checklist.HSF_Submission_Status__c == 'Submitted' && (doc.Routing_Name__c == Label.HSF_Routing_Name));
                System.debug('sendDocumentsToClientspaceFromChecklist documentPartOfSubmitRequest:'+documentPartOfSubmitRequest);
                System.debug('sendDocumentsToClientspaceFromChecklist documentPartOfHsfSubmission:'+documentPartOfHsfSubmission);
            }
            System.debug('sendDocumentsToClientspaceFromChecklist documentPartOfSubmitRequest:'+documentPartOfSubmitRequest);
            System.debug('sendDocumentsToClientspaceFromChecklist documentPartOfHsfSubmission:'+documentPartOfHsfSubmission);
            // verify if the document should be added to the document map to be submitted
            // Store the documents related to it's parent id or single ID
            if(docMapping!=null && documentPartOfSubmitRequest) {
                System.debug('sendDocumentsToClientspaceFromChecklist : Document part of Submit request');
                // if the prospect client for the document has a value in the salesParent__c field this will be true
                Boolean docAccountSalesParentIsntEmpty = doc.PEO_Onboarding_Checklist__r.prospect_Client__r.salesParent__c != null;
                // if the Prospect client for this doc has a false isParent__c value and docAccountSalesParentIsntEmpty is false this will be true
                Boolean docAccountIsAChild = !doc.PEO_Onboarding_Checklist__r.prospect_Client__r.isParent__c && docAccountSalesParentIsntEmpty;
                // if docAccountIsAChild is true this will set the ID to the Sales Parent ID of the prospect client this document is attached to
                // otherwise it will be null
                Id docsParentAccountId = (docAccountIsAChild ? doc.PEO_Onboarding_Checklist__r.prospect_Client__r.salesParent__c : null);
                Boolean docIsSingleId = false;
                
                // if the account isnot a child and it's not a parent assign the single id to the prospect lookup id
                // // then set the flag docIsSingleId to true
                if (!docAccountIsAChild && docsParentAccountId == null) docIsSingleId = true;
                
                // if the document is attached to a child then use the parent account ID list in the parentAccToDocsMap
                // to store this document
                if (!checklistIsClientAddOn && docAccountIsAChild && docAccountSalesParentIsntEmpty) {
                    List<PEO_Onboarding_Document__c> docList = parentAccToDocsMap.get(docsParentAccountId);
                    if (docList == null) {
                        docList = new List<PEO_Onboarding_Document__c>{doc};
                            } else {
                                docList.add(doc);
                            }
                    parentAccToDocsMap.put(docsParentAccountId, docList);
                }
                
                // if the document is attached to a single ID use the prospect ID to save the doc in the parentAccToDocsMap
                if (checklistIsClientAddOn || docIsSingleId) {
                    Id prospectId =  doc.PEO_Onboarding_Checklist__r.prospect_client__r.Id;
                    List<PEO_Onboarding_Document__c> docList = parentAccToDocsMap.get(prospectId);
                    if (docList == null) {
                        docList = new List<PEO_Onboarding_Document__c>{doc};
                            } else {
                                docList.add(doc);
                            }
                    parentAccToDocsMap.put(prospectId, docList);
                }
                // add the document map to the map for later reference
                docMapByDocId.put(doc.Id,docMapping);
            }
            //HSF
            if(docMapping!=null && documentPartOfHsfSubmission) {
                System.debug('sendDocumentsToClientspaceFromChecklist : Document part of HSF submission');
                // if the prospect client for the document has a value in the salesParent__c field this will be true
                Boolean docAccountSalesParentIsntEmpty = doc.PEO_Onboarding_Checklist__r.prospect_Client__r.salesParent__c != null;
                // if the Prospect client for this doc has a false isParent__c value and docAccountSalesParentIsntEmpty is false this will be true
                Boolean docAccountIsAChild = !doc.PEO_Onboarding_Checklist__r.prospect_Client__r.isParent__c && docAccountSalesParentIsntEmpty;
                // if docAccountIsAChild is true this will set the ID to the Sales Parent ID of the prospect client this document is attached to
                // otherwise it will be null
                Id docsParentAccountId = (docAccountIsAChild ? doc.PEO_Onboarding_Checklist__r.prospect_Client__r.salesParent__c : null);
                Boolean docIsSingleId = false;
                
                // if the account isnot a child and it's not a parent assign the single id to the prospect lookup id
                // // then set the flag docIsSingleId to true
                if (!docAccountIsAChild && docsParentAccountId == null) docIsSingleId = true;
                
                // if the document is attached to a child then use the parent account ID list in the parentAccToDocsMap
                // to store this document
                if (!checklistIsClientAddOn && docAccountIsAChild && docAccountSalesParentIsntEmpty) {
                    List<PEO_Onboarding_Document__c> docList = parentAccToDocsMap.get(docsParentAccountId);
                    if (docList == null) {
                        docList = new List<PEO_Onboarding_Document__c>{doc};
                            } else {
                                docList.add(doc);
                            }
                    parentAccToDocsMap.put(docsParentAccountId, docList);
                }
                
                // if the document is attached to a single ID use the prospect ID to save the doc in the parentAccToDocsMap
                if (checklistIsClientAddOn || docIsSingleId) {
                    Id prospectId =  doc.PEO_Onboarding_Checklist__r.prospect_client__r.Id;
                    List<PEO_Onboarding_Document__c> docList = parentAccToDocsMap.get(prospectId);
                    if (docList == null) {
                        docList = new List<PEO_Onboarding_Document__c>{doc};
                            } else {
                                docList.add(doc);
                            }
                    parentAccToDocsMap.put(prospectId, docList);
                }
                // add the document map to the map for later reference
                docMapByDocId.put(doc.Id,docMapping);
            }
        }
        
        if(!parentAccToDocsMap.isEmpty()) {
            // iterate over each document as a part of the key set and pass in that specific document list
            for (Id workspaceId : parentAccToDocsMap.keySet()) {
                List<PEO_Onboarding_Document__c> docList = parentAccToDocsMap.get(workspaceId);    
                System.debug('sendDocumentsToClientspaceFromChecklist Doclist:'+docList);
                // row guid should not be passed in prematurely. Needs to be retrieved off result of patch or query to client documents
                ClientspaceAPIQueueable caq = new ClientspaceAPIQueueable(null, docList, 'Get projId',
                                                                          null,null,
                                                                          null,null,docMapByDocId, workspaceId,null,null);
                System.enqueueJob(caq);
            }
        }
    }
    
   public static void checkCSOwnerChanged(Account[] accts, Map<Id,Account> oldMap,Set<String> csIds,Set<Id> ownerIds) {
      // get the user records
      User[] users = [Select Id, Name, CSUserId__c, IsActive, Sales_Org__c,Sales_Division__c
                        from User
                       Where IsActive=true 
                          and (Id in :ownerIds
                            or CSUserId__c in :csIds)];
      Map<String,User> userMap = new Map<String,User>();
      for (User usr : users) {
         userMap.put(usr.Id, usr);
         if (usr.CSUserId__c != null) {
            userMap.put(usr.CSUserId__c, usr);
         }
      } // for (User usr
      for (Account acct : accts) {
         Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
         User newUsr = userMap.get(acct.CSOwnerId__c);
          if (newUsr != null && newUsr.Sales_Division__c!='NSC') {
            User oldUsr = (oldAcct != null && String.isNotBlank(oldAcct.CSOwnerId__c) ? userMap.get(oldAcct.CSOwnerId__c) : null);
            String ownerFld = null;
            if (oldUsr != null) {
               // See which owner field matches to the old user, then set the new user to that.
               ownerFld = (acct.OwnerId == oldUsr.Id ? 'OwnerId' : (acct.Premier_PBS_Account_Owner__c == oldUsr.Id ? 'Premier_PBS_Account_Owner__c' : null));
            }
            if (ownerFld == null) {
               ownerFld = (newUsr.Sales_Org__c == 'PAS' ? 'Premier_PBS_Account_Owner__c' : 'OwnerId');
            }
            if (ownerFld != null) {
               String holdOutFld = (ownerFld == 'Premier_PBS_Account_Owner__c' ? 'Premier_PBS_Hold_Out__c' : 'Hold_Out__c');
               Boolean hasHoldOut = (Boolean)acct.get(holdOutFld);
               System.debug('checkCSOwnerChanged holdOutFld='+holdOutFld+' holdOutFld='+holdOutFld+' hasHoldOut='+hasHoldOut);
               if (hasHoldOut == null || !hasHoldOut) {
                  String msg = 'Change '+ownerFld+' from '+(Id)acct.get(ownerFld)+' to '+newUsr.Id;
                  StringHelper.addToProcessNotes(acct,msg);
                  acct.put(ownerFld, newUsr.Id);
                  acct.UseClientSpace__c=true;
               }
            }
         } // if (newUsr != null
      } // for (Account acct : accts
   } // checkCSOwnerChanged
   
   public static void checkContactsBefore(Contact[] ctcts, Map<Id,Contact> oldMap) {
      for (Contact ctct : ctcts) {
          if (ctct.Id != null && ctct.SendToClientSpace__c) {
              forceCSIdSet.add(ctct.Id);
              ctct.SendToClientSpace__c = false;
          }    
      } // for (Contact ctct : ctcts
   } // checkContactsBefore
    
   public static void checkContactsAfter(Contact[] ctcts, Map<Id,Contact> oldMap) {
      Work_Queue__c[] upsertWorkQueues = new Work_Queue__c[]{};
      Schema.FieldSet ctctFldSet = Schema.SObjectType.Contact.fieldSets.ClientSpace_CtctChangeFlds;
      
      Set<Id> acctIdSet = new Set<Id>();
      Contact[] ctctsToCheckAcct = new Contact[]{};
      
      // see if the contact meets any of the first criteria before querying for more data.
      for (Contact ctct : ctcts) {
         Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);
         if (ctct.AccountId != null && (forceCSIdSet.contains(ctct.Id) || recFldsChanged(ctct,oldCtct,ctctFldSet,true))) {
            acctIdSet.add(ctct.AccountId);
            ctctsToCheckAcct.add(ctct);
         }
      } // for (Contact ctct : ctcts
      
      System.debug('checkContactsAfter ctcts='+ctcts.size()+' ctctsToCheckAcct='+ctctsToCheckAcct.size()+' acctIdSet='+acctIdSet.size());
      if (!ctctsToCheckAcct.isEmpty()) {
         // only accounts that are in client space will be returned in the map
         Map<Id,Account> acctMap = getAcctMap(acctIdSet);
         for (Contact ctct : ctctsToCheckAcct) {
            Account acct = acctMap.get(ctct.AccountId);
            if (acct != null && acct.UseClientSpace__c) {
               addContactWorkQueue(acct, ctct, upsertWorkQueues);
            }
         }
      } // if (!ctctsToCheckAcct.isEmpty

      saveWorkQueues(null,null,upsertWorkQueues,ObjectHelper.OBJECT_CONTACT);
   } // checkContactsAfter
    
    public static void addContactWorkQueue(Account acct, Contact ctct, Work_Queue__c[] upsertWorkQueues) {
        System.debug('addContactWorkQueue adding work queue hasCtct='+(ctct != null));
        if (ctct != null) {
           Work_Queue__c wq = new Work_Queue__c(Object_Record_ID__c=ctct.Id, Contact_ID__c=ctct.Id, Account_ID__c=(acct != null ? acct.Id : null), Object__c=ObjectHelper.OBJECT_CONTACT);
           wq.Completed__c=false;
           upsertWorkQueues.add(wq);
        }
    } // addContactWorkQueue
   
   public static Map<Id,Account> getAcctMap(Set<Id> accountIdSet) {
      Map<Id,Account> acctMap = (accountIdSet.isEmpty() ? new Map<Id,Account>()  
                                    : new Map<Id,Account>([Select Id, Name, OwnerId, Owner.Id, Owner.CSUserId__c, Owner.IsActive
                                                                 ,Hold_Out__c, Premier_PBS_Hold_Out__c
                                                                 ,Premier_PBS_Account_Owner__c, Premier_PBS_Account_Owner__r.Id
                                                                 ,Premier_PBS_Account_Owner__r.CSUserId__c, Premier_PBS_Account_Owner__r.IsActive
                                                                 ,OasisPEOAccountOwner__c, OasisPEOAccountOwner__r.Id
                                                                 ,OasisPEOAccountOwner__r.CSUserId__c, OasisPEOAccountOwner__r.IsActive
                                                                 ,CSOwnerId__c
                                                                 ,UseClientSpace__c
                                                                 ,SignificantContact__c
                                                                 ,SignificantContact__r.Id
                                                                 ,SignificantContact__r.CSContactID__c
                                                                 ,SignificantContact__r.UseClientSpace__c
                                                                 ,(Select Id, Name, CSContactID__c, UseClientSpace__c 
                                                                     from Contacts where Sales_Contact__c=true 
                                                                    order by LastModifiedDate desc limit 1)
                                                             From Account
                                                            Where Id in :accountIdSet
                                                              //and UseClientSpace__c = true
                                                              //and Owner.IsActive=true
                                                              //and SignificantContact__r.CSContactID__c != null
                                                              ]));
      System.debug('getAcctMap accountIdSet='+accountIdSet.size()+' acctMap='+acctMap.size());
      return acctMap;
   } // getAcctMap
   
   public static Map<Id,Contact> getCtctMap(Set<Id> contactIdSet) {
      Map<Id,Contact> ctctMap = (contactIdSet.isEmpty() ? new Map<Id,Contact>() 
                                    : new Map<Id,Contact>([Select Id, Name, UseClientSpace__c, CSContactId__c, AccountId
                                                                 ,Account.Id
                                                                 ,Account.Name
                                                                 ,Account.Hold_Out__c, Account.Premier_PBS_Hold_Out__c
                                                                 ,Account.CSOwnerId__c
                                                                 ,Account.UseClientSpace__c
                                                                 ,Account.OwnerId
                                                                 ,Account.Owner.IsActive
                                                                 ,Account.Owner.CSUserId__c
                                                                 ,Account.Premier_PBS_Account_Owner__c, Account.Premier_PBS_Account_Owner__r.Id
                                                                 ,Account.Premier_PBS_Account_Owner__r.CSUserId__c, Account.Premier_PBS_Account_Owner__r.IsActive
                                                                 ,Account.OasisPEOAccountOwner__c, Account.OasisPEOAccountOwner__r.Id
                                                                 ,Account.OasisPEOAccountOwner__r.CSUserId__c, Account.OasisPEOAccountOwner__r.IsActive
                                                             From Contact
                                                            Where Id in :contactIdSet
                                                              and Account.UseClientSpace__c = true]));
      System.debug('getCtctMap contactIdSet='+contactIdSet.size()+' ctctMap='+ctctMap.size());
      return ctctMap;
   } // getCtctMap
   
   // for testing purposes
   public static Boolean SKIP_FUTURE=false;
   
   // if any changes occur to tasks or events, 
   public static void checkActivityAfter(SObject[] recs, Map<Id,SObject> oldMap, String objTypeName) {
      System.debug('checkActivityAfter objTypeName='+objTypeName+' recs='+recs.size());
      Set<Id> ctctIdSet = new Set<Id>();
      Set<Id> acctIdSet = new Set<Id>();
      Set<Id> activityIdSet = new Set<Id>();
      
      Map<Id,Schema.RecordTypeInfo> byIdMap = (objTypeName == ObjectHelper.OBJECT_TASK
                                     ? Task.SObjectType.getDescribe().getRecordTypeInfosById()
                                     : Event.SObjectType.getDescribe().getRecordTypeInfosById());
      System.debug('checkActivityAfter byIdMap='+byIdMap.keySet());
      
      Schema.FieldSet fldSet = (objTypeName == ObjectHelper.OBJECT_TASK
                                     ? Schema.SObjectType.Task.fieldSets.ClientSpace_TaskChangeFlds
                                     : Schema.SObjectType.Event.fieldSets.ClientSpace_EventChangeFlds);
                                     
      // get record type names for client space
      Set<String> csRecordTypeNameSet = getClientSpaceRecordTypeNames();
      System.debug('checkActivityAfter csRecordTypeNameSet='+csRecordTypeNameSet);
      
      for (SObject rec : recs) {
         // only for PEO record type names
         Id recTypeId = (Id)rec.get('RecordTypeId'); 
         Schema.RecordTypeInfo rtInfo = byIdMap.get(recTypeId);
         System.debug('checkActivityAfter recTypeId='+recTypeId+' rtInfo='+rtInfo);
         if (rtInfo != null && csRecordTypeNameSet.contains(rtInfo.getName())) {
            SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
            if (recFldsChanged(rec, oldRec, fldSet, false)) {
               Id whoId = (Id)rec.get('WhoId');
               if (whoId != null && ((String)whoId).startsWith('003')) {
                  ctctIdSet.add(whoId);
                  activityIdSet.add(rec.Id);
               }
               Id whatId = (Id)rec.get('WhatId');
               if (whatId != null && ((String)whatId).startsWith('001')) {
                  acctIdSet.add(whatId);
                  activityIdSet.add(rec.Id);
               }
         
               Id acctId = (Id)rec.get('AccountId');
               if (acctId != null) {
                  acctIdSet.add(acctId);
                  activityIdSet.add(rec.Id);
               }
            } // if (recFldsChanged(rec, oldRec
         }
      } // for (SObject rec
      
      System.debug('activityIdSet='+activityIdSet.size());
      
      if (!activityIdSet.isEmpty()) {
         if (SKIP_FUTURE || System.isBatch() || System.isFuture() || System.isQueueable()) {
            processActivityNow(objTypeName, activityIdSet, ctctIdSet, acctIdSet);
         } else {
            processActivityFuture(objTypeName, activityIdSet, ctctIdSet, acctIdSet);
         }
      } // if (!activityIdSet.isEmpty
      
   } // checkActivityAfter
   
   public static Set<String> getClientSpaceRecordTypeNames() {
      Set<String> recordTypeNameSet = new Set<String>();
      for (RecordType__c rt : RecordType__c.getAll().values()) {
         if (rt.UseForClientSpace__c && String.isNotBlank(rt.RecordTypeName__c)) {
            recordTypeNameSet.add(rt.RecordTypeName__c);
         }
      } // for (RecordType__c rt
      System.debug('getClientSpaceRecordTypeNames recordTypeNameSet='+recordTypeNameSet.size());
      return recordTypeNameSet;
   } // getClientSpaceRecordTypeNames
   
   public static void processActivityFuture(String objTypeName, Set<Id> activityIdSet, Set<Id> ctctIdSet, Set<Id> acctIdSet) {
      processActivityNow(objTypeName, activityIdSet, ctctIdSet, acctIdSet);
   } // processActivityFuture
   
   public static void processActivityNow(String objTypeName, Set<Id> activityIdSet, Set<Id> ctctIdSet, Set<Id> acctIdSet) {
      System.debug('processActivityNow objTypeName='+objTypeName+' activityIdSet='+activityIdSet.size()+' ctctIdSet='+ctctIdSet.size()+' acctIdSet='+acctIdSet.size());
      Map<Id,Account> acctMap = getAcctMap(acctIdSet);
      Map<Id,Contact> ctctMap = getCtctMap(ctctIdSet);
      SObject[] activities = getActivity(objTypeName,activityIdSet);
      System.debug('processActivityNow activities='+activities.size());

      Work_Queue__c[] upsertWorkQueues = new Work_Queue__c[]{};
      for (SObject activity : activities) {
         Id whoId = (Id)activity.get('WhoId');
         Id whatId = (Id)activity.get('WhatId');
         Id acctId = (Id)activity.get('AccountId');
         String subject = (String)activity.get('Subject');
         
         Contact ctct = (whoId != null ? ctctMap.get(whoId) : null);
         Account acct = (whatId != null ? acctMap.get(whatId) : null);
         if (acct == null) {
            acct = (acctId != null ? acctMap.get(acctId) : null);
         }
         if (acct == null && ctct != null) {
            acct = ctct.Account;
         }
         System.debug('processActivityNow subject='+subject+' hasAcct='+(acct != null)+' ctct='+(ctct != null));
         Boolean sendToCS = (ctct != null && ctct.Account != null && ctct.Account.UseClientSpace__c);
         //System.debug('processActivityNow 1 sendToCS='+sendToCS);
         if (!sendToCS) {
            sendToCS = (acct != null && acct.UseClientSpace__c);
         }
         //System.debug('processActivityNow 2 sendToCS='+sendToCS);
         
         if (sendToCS) {
            Work_Queue__c wq = new Work_Queue__c(Object_Record_ID__c=activity.Id, Account_ID__c=(acct != null ? acct.Id : null)
                                              , Object__c=objTypeName, Contact_ID__c=(ctct != null ? ctct.Id : null));
            wq.Completed__c=false;
            upsertWorkQueues.add(wq);
         } // if (sendToCS
      } // for (SObject activity
      saveWorkQueues(null,null,upsertWorkQueues,objTypeName);
   } // processActivityNow
   
   public static SObject[] getActivity(String objTypeName, Set<Id> activityIdSet) {
      SObject[] retActivity = null;
      if (objTypeName == ObjectHelper.OBJECT_TASK) {
         Task[] tasks = [Select Id, WhoId, WhatId, AccountId, Subject from Task where Id in :activityIdSet];
         retActivity = tasks;
      } else if (objTypeName == ObjectHelper.OBJECT_EVENT) {
         Event[] events = [Select Id, WhoId, WhatId, AccountId, Subject from Event where Id in :activityIdSet];
         retActivity = events;
      }
      return retActivity;
   } // getActivity
   
   public static Boolean recFldsChanged(SObject rec, SObject oldRec, Schema.FieldSet fldSet, Boolean hasClientSpaceFld) {
      // if it's a new record we'll always send
      System.debug('recFldsChanged');
      if (oldRec == null) {
         System.debug('recFldsChanged returning true because new record');
         return true;
      } 
      // if this flag has changed we'll always trigger a change
      if (hasClientSpaceFld && (Boolean)rec.get('UseClientSpace__c') && (rec.get('UseClientSpace__c') != oldRec.get('UseClientSpace__c'))) {
         System.debug('recFldsChanged UseClientSpace__c changed - returning true');
         return true;
      }
      for (Schema.FieldSetMember fsm : fldSet.getFields()) {
         String fldName = fsm.getFieldPath();
         if (rec.get(fldName) != null && rec.get(fldName) != oldRec.get(fldName)) {
            System.debug('recFldsChanged value changed for '+fldName);
            return true;
         }
      }
      System.debug('recFldsChanged no changes found');
      return false;
   } // recFldsChanged

   public static void saveWorkQueues(Account[] accts, Contact[] ctcts, Work_Queue__c[] upsertWorkQueues, String source) {
      System.debug('saveWorkQueues accts='+(accts != null ? accts.size() : -1)+' ctcts='+(ctcts != null ? ctcts.size() : -1)+' upsertWorkQueues='+(upsertWorkQueues != null ? upsertWorkQueues.size() : -1));
      TriggerMethods.SKIP_TRIGGERS=true;
      ZipCheckOwner.SKIP_TRIGGERS=true;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      if (accts != null && !accts.IsEmpty()) {
         DmlHelper.performDML2(accts, DmlHelper.DML_UPDATE, 'ClientSpaceHelper', 'saveWorkQueues', 'Updating Accounts', true);
      }
      if (ctcts != null && !ctcts.IsEmpty()) {
         DmlHelper.performDML2(ctcts, DmlHelper.DML_UPDATE, 'ClientSpaceHelper', 'saveWorkQueues', 'Updating Contacts', true);
      }
      TriggerMethods.SKIP_TRIGGERS=false;
      ZipCheckOwner.SKIP_TRIGGERS=false;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
       
      if (!upsertWorkQueues.isEmpty()) {
         DmlHelper.prepareForSave();
         DmlHelper.DmlResult dmlResult = DmlHelper.initializeDmlResult(upsertWorkQueues, DmlHelper.DML_UPSERT, 'ClientSpaceHelper', 'saveWorkQueues', 'upserting work queues from '+source);
         Database.UpsertResult[] results = Database.upsert(upsertWorkQueues,Work_Queue__c.Fields.Object_Record_ID__c,false);
         //ErrorLog.addToDescription(log,'upsertResults='+results);
         DmlHelper.handleUpsertResults(upsertWorkQueues, results, dmlResult);
      }
   } // saveWorkQueues
    
    //sfdc-13127
    //Always the WQ's are updated in the order of last modified date with the first created WQ's executed first
    //This method prevents a work queue timestamp getting changed after multiple updates on an object if completed = false
    public static Boolean checkExistingWorkQueue(Id accId, PEO_Onboarding_Checklist__c checklist, String objName, Id objRecId) {
        List<Work_Queue__c> queues;
        Boolean workQueueExists = false;
        //fetch the Workqueues within an Account
        if(accId != null ){
            queues  = [SELECT Account_ID__c,Completed__c,Id,Name,Object_Record_ID__c,Object__c FROM Work_Queue__c WHERE Account_ID__c =: accId]; 
        }
        system.debug('ClientSpaceHelper checkExistingWorkQueue queues:'+queues);
        if(queues.size()!=0){
            for(Work_Queue__c wq: queues){
                system.debug('ClientSpaceHelper checkExistingWorkQueue wq Object__c:'+wq.Object__c); 
                Boolean isChecked=wq.Completed__c;
                //If Work queue Object name and record id matches with that of Object being updated return false
                //If false is returned WQ update is prevented and vice versa
                if(wq.Object__c == objName){
                    if(wq.Object_Record_ID__c == objRecId && isChecked == false){
                        workQueueExists = true;
                    }
                }
            }
        }
        system.debug('ClientSpaceHelper checkExistingWorkQueue workQueueExists:'+workQueueExists);
        return workQueueExists;
    }
   
     //Rohit Ranjan code starts, to update workqueue from Broker commission records
     
   public static void workQueuesForBrokenCommissions(Broker_Commission__c[] arrayBrokerCommision){
       Set<Id> setBrokerComissionIds = new Set<Id>();
       for(Broker_Commission__c bc : arrayBrokerCommision) {
           setBrokerComissionIds.add(bc.Id);
       } 
       Map<String,Work_Queue__c> idWQMap = new Map<String,Work_Queue__c>();
       List<Work_Queue__c> upsertWQList = new List<Work_Queue__c>();
       
       Broker_Commission__c[] brokercomms = [SELECT id ,Opportunity__r.OwnerContact__c,Opportunity__r.AccountId FROM     
                                             Broker_Commission__c WHERE id in:setBrokerComissionIds]; 
       for(Broker_Commission__c bc : brokercomms) {
           setBrokerComissionIds.add(bc.Opportunity__r.AccountId);//adding accountIds
       } 
       List<Work_Queue__c> wrkQueList = [Select id,Object_Record_ID__c from Work_Queue__c where Object_Record_ID__c IN :setBrokerComissionIds];
       for(Work_Queue__c wq :wrkQueList){
           idWQMap.put(wq.Object_Record_ID__c,wq);
       }       
       for(Broker_Commission__c bc: brokercomms){
           
           Work_Queue__c wq = new Work_Queue__c();
           wq.Object__c = 'Broker_Commission__c';
           wq.Completed__c = !idWQMap.containskey(bc.Opportunity__r.accountid);
           wq.Object_Record_ID__c = bc.Id;
           //wq.Contact_ID__c = bc.Opportunity__r.OwnerContact__c;
           wq.Account_ID__c = bc.Opportunity__r.AccountId;                                    
           if(idWQMap.size() > 0 && idWQMap.containskey(String.ValueOf(bc.Id))){
               wq.id= idWQMap.get(String.ValueOf(bc.Id)).id;
           }
           upsertWQList.add(wq);
       }									   
	if(upsertWQList.size() >0){
      
     saveWorkQueues(null,null,upsertWQList,'Broker_Commission__c');
	}
    }
    //Rohit code ends
    //
    //This method sets all the workqueue completed status to false when an account Worqueue is created.
    public static void resetWorkQueues(Work_Queue__c[] upsertWorkQueues, Id[] wqIdsInserted) {
        System.debug('Inside resetWorkQueues');
        System.debug('upsertWorkQueues:'+upsertWorkQueues);
        System.debug('wqIdsInserted:'+wqIdsInserted);
        Work_Queue__c[] refreshWorkQueues = new Work_Queue__c[]{};
        List<Id> accIdList = new List<Id>();
        for(Work_Queue__c wqi: upsertWorkQueues){
            System.debug('WQ Id:'+wqi.Id); 
            if(wqIdsInserted.contains(wqi.Id)){
                System.debug('wqIdsInserted list contains Id');
                accIdList.add(wqi.Account_ID__c);
            }
        }
        System.debug('accIdList:'+accIdList);    
        if(accIdList.size()>0){
            List<Work_Queue__c> queues = [SELECT Account_ID__c,Completed__c,Id,Name,Object_Record_ID__c,Object__c FROM Work_Queue__c WHERE Account_ID__c IN: accIdList AND Object__c != 'Account']; 
             System.debug('queues:'+queues);    
            if(queues.size()>0){
                for(Work_Queue__c wqs: queues){
                    wqs.Completed__c = false;
                    refreshWorkQueues.add(wqs);
                }
                System.debug('refreshWorkQueues:'+refreshWorkQueues);    
                saveWorkQueues(null,null,refreshWorkQueues,ObjectHelper.OBJECT_ACCOUNT);
            }
        }
    }
} // class ClientSpaceHelper