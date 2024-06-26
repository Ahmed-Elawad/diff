/* 
 * Methods for the Reference MPSC object.
 *
 * History
 * -------
 * 10/31/2016 Lynn Michels          Created
 * 01/26/2017 Lynn Michels          Edited to use field sets
 * 04/04/2017 Lynn Michels          Change query of what Reference MPSC records to update
 * 03/26/2018 Frank Lurz            Added FBAE related changes per Case 26570011
 * 06/05/2018 Frank Lurz            Added Current Step processing to code from Process Builder flow 
 * 01/23/2019 Dan Carmen            Added TRIGGERS_RAN variable
 * 11/27/2020 Jake Hinds			change to make ID null and not '' when empty
 * 12/17/2020 Brandon Vidro         Removed debug statements
 * 01/04/2021 Brandon Vidro			Modified to work w/ Flow and 2 Formula fields on object
 * 01/11/2021 Brandon Vidro 		Converted Payroll_BSR__c to a forumla field - Payroll_BSR_New__c
   12/11/2023 Dan Carmen            Add to TriggerInterfaceC
 
 */
public with sharing class ReferenceMPSC implements TriggerInterfaceC {
   public static final String CLASSNAME='ReferenceMPSC';
   public static Boolean TRIGGERS_RAN=false;
   
   public static Id mpscTransferRecordTypeId = Schema.SObjectType.Reference_MPSC__c.getRecordTypeInfosByName().get('Reference MPSC Transfer').getRecordTypeId();

   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      System.debug('ReferenceMPSC.handleTrigger p_recs='+(p_recs != null ? p_recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete+' Trigger.old='+(Trigger.old != null ? Trigger.old.size() : -1));
      SObject[] recs = TriggerMethods.checkRecs(CLASSNAME, p_recs, oldMap, isBefore, isAfter, isDelete, null, null);
      if (recs == null || recs.isEmpty()) {
         System.debug('handleTrigger trigger already ran');
         return;
      }
      SObjectType objType = TriggerMethods.objType;
      if (isAfter && oldMap != null && objType == Account.sObjectType ) {
         handleAcctsAfter((Account[])recs,(Map<Id,Account>)oldMap);
      }
   } // handleTrigger
   
   public static void handleAcctsAfter(Account[] accts, Map<Id,Account> oldMap) {
      Map<Id, Account> accountMap = new Map<Id, Account>();
      Set<Id> contactIdSet = new Set<Id>();
      for (Account acct : accts) {
         Account oldA = (oldMap != null ? oldMap.get(acct.Id) : null);
         if (oldA != null &&
                (oldA.HRO_Implementation_Coordinator__c != acct.HRO_Implementation_Coordinator__c ||
                 oldA.TLO_Implementation_Coordinator__c != acct.TLO_Implementation_Coordinator__c ||
                 oldA.Paychex_Payroll_Specialist__c != acct.Paychex_Payroll_Specialist__c ||
                 oldA.OwnerId != acct.OwnerId ||
                 oldA.MMS_MAM_NAM__c != acct.MMS_MAM_NAM__c))  {
            accountMap.put(acct.id, acct); //accounts with changes
            if (acct.Paychex_Payroll_Specialist__c != null) {
               contactIdSet.add(acct.Paychex_Payroll_Specialist__c);  //store the contacts used in the Paychex_Payroll_Specialist__c field on acct
            }//end if
            if (acct.MMS_MAM_NAM__c != null) {
               contactIdSet.add(acct.MMS_MAM_NAM__c);  //store the contacts used in the MMS_MAM_NAM__c field on acct
            }//end if
         }// end if

      } // for (Account acct
      System.debug('handleAcctsAfter accountMap='+accountMap.size());
      if (!accountMap.isEmpty()) {
         updateReferenceMPSC(accountMap, contactIdSet);
      }
   } // handleAcctsAfter
    /*
    //criteria to check for AccountAfter.trigger and populate the accountIds set
    public static void evaluateAccountCriteria(Account acct, Account olda)
    {
        //see if Implementation Specialists or BSRs have changed on the Account
        //check for not null for udpate
        if (olda != null &&
            (olda.HRO_Implementation_Coordinator__c != acct.HRO_Implementation_Coordinator__c ||
            olda.TLO_Implementation_Coordinator__c != acct.TLO_Implementation_Coordinator__c ||
            olda.Paychex_Payroll_Specialist__c != acct.Paychex_Payroll_Specialist__c ||
            //olda.Time_Attendance_AS__c != acct.Time_Attendance_AS__c||
            //olda.HRO_Advisor__c != acct.HRO_Advisor__c ||
            olda.OwnerId != acct.OwnerId ||
            olda.MMS_MAM_NAM__c != acct.MMS_MAM_NAM__c))
            {
                accountMap.put(acct.id, acct); //accounts with changes
                if (acct.Paychex_Payroll_Specialist__c != null) {
                    contactIdSet.add(acct.Paychex_Payroll_Specialist__c);  //store the contacts used in the Paychex_Payroll_Specialist__c field on acct
                }//end if
                if (acct.MMS_MAM_NAM__c != null) {
                    contactIdSet.add(acct.MMS_MAM_NAM__c);  //store the contacts used in the MMS_MAM_NAM__c field on acct
                }//end if
            }// end if
    }// end checkUpdateCriteria
    */
    //use the account ids to find a reference mpsc record with the reference transfer RT and make updates from the account
    public static void updateReferenceMPSC(Map<Id, Account> accountMap, Set<Id> contactIdSet) {
        //find the most recently created reference MPSC on these accounts with the MPSC Transfer RT
        Reference_MPSC__c[] refMPSCs = [SELECT Id, Prospect_Client__c, Payroll_IS__c, Flex_HR_IS__c, TAA_IS__c, Sales_Rep__c, SIPM_IPM__c, Date_Opened__c, RecordTypeId
                FROM Reference_MPSC__c
                WHERE Prospect_Client__c in: accountMap.keyset() AND RecordTypeId =: mpscTransferRecordTypeId
                AND MPSC_Status__c != 'Completed'];
        if (refMPSCs.isEmpty()) {
           return;
        }
    
        //map to hold query results - if the contactIdSet is not empty, use it to get the User_Lookup__c fields for each contact
        Map<Id,Contact> contactMap = null;
        if (!contactIdSet.isEmpty()) {
            contactMap = new Map<Id,Contact>([SELECT Id, User_Lookup__c FROM Contact WHERE Id in :contactIdSet]);
        } else {
            contactMap = new Map<Id,Contact>();
        }

        list<Reference_MPSC__c> mpscsToUpdate = new list<Reference_MPSC__c>();
        //loop through reference mpscs, set values from the account
        for(Reference_MPSC__c mpsc : refMPSCs){
            //find the account in the map using the mpsc.Prospect_Client__c
            //remove it from the map and set the acct to the one removed - this will only process the first mpsc in the list
            Account acct = accountMap.get(mpsc.Prospect_Client__c);
                if(acct != null)
                {
                    //populate IS's
                    mpsc.Flex_HR_IS__c = acct.HRO_Implementation_Coordinator__c; 
                    mpsc.TAA_IS__c = acct.TLO_Implementation_Coordinator__c;
                    //populate BSR's
                    //Contact specialistCtct = (acct.Paychex_Payroll_Specialist__c != null ? contactMap.get(acct.Paychex_Payroll_Specialist__c) : null);
                    //mpsc.Payroll_BSR__c = (specialistCtct != null ? specialistCtct.User_Lookup__c : null);
                    //mpsc.TAA_BSR__c = acct.Time_Attendance_AS__c;
                    //mpsc.Flex_HR_BSR__c = acct.HRO_Advisor__c;
                    //populate SIPM/IPM and Sales Rep
                    Contact sipmCtct = (acct.MMS_MAM_NAM__c != null ? contactMap.get(acct.MMS_MAM_NAM__c) : null);
                    mpsc.SIPM_IPM__c = (sipmCtct != null ? sipmCtct.User_Lookup__c : null);
                    mpsc.Sales_Rep__c = acct.ownerId;
                    mpscsToUpdate.add(mpsc);
                }//end if
        }//end for reference mpsc
    
        if(!mpscsToUpdate.isEmpty()){
            update mpscsToUpdate;   
        }
    }// end updateReferenceMPSC
    
    //check to see that all of the Payroll fields are populated
    //some of the Product fields are not included because they are formula fields and will always have a value.
    public static boolean evaluatePayrollFields(Reference_MPSC__c refmpsc){ 
        Boolean payrollIsPopulated = true;  
        //using field set
        List<Schema.FieldSetMember> payrollFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_Payroll_fields.getFields();
        for (Schema.FieldSetMember pf: payrollFields){
            if (refmpsc.get(pf.getFieldPath()) == null){
                payrollIsPopulated = false;
                break;
            }//end if   
        }//end for
        return payrollIsPopulated;  
    }//end evaluatePayrollFields
    
    //check to see if all TAA fields are populated
    public static boolean evaluateTAAFields(Reference_MPSC__c refmpsc){ 
        Boolean taaIsPopulated = true;  
        //using field set
        List<Schema.FieldSetMember> taaFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_TAA_Fields.getFields();
        for (Schema.FieldSetMember tf: taaFields){
            //if HRIS Coding has been verified does not equal Yes, OR any of the fields are not populated
            if((tf.getFieldPath() == 'HRIS_Coding_has_been_verified__c' && refmpsc.get(tf.getFieldPath()) != 'Yes') || (refmpsc.get(tf.getFieldPath()) == null))
            {
                taaIsPopulated = false;
                break;
            }//end if not Yes   
        }//end for
        return taaIsPopulated;  
    }//end evaluateTAAFields
    
    //check to see if all FLEX HR fields are populated
    public static boolean evaluateFlexHRFields(Reference_MPSC__c refmpsc){ 
        Boolean flexIsPopulated = true; 
        //using field set
        List<Schema.FieldSetMember> flexFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_Flex_fields.getFields();
        for (Schema.FieldSetMember ff: flexFields){
            if (refmpsc.get(ff.getFieldPath()) == null){
                flexIsPopulated = false;
                break;
            }//end if   
        }//end for
            
        return flexIsPopulated; 
    }//end evaluateFlexHRFields

    //check to see if all the necessary fields are populated in order to populate FBAE ready to Transfer Date
    public static boolean evaluateFBAEFields(Reference_MPSC__c refmpsc){ 
        Boolean fBAEIsPopulated = true; 
        //using field set
        List<Schema.FieldSetMember> fBAEFields = SObjectType.Reference_MPSC__c.FieldSets.MPSC_FBAE_fields.getFields();
        for (Schema.FieldSetMember fbaef: fBAEFields){
            if (refmpsc.get(fbaef.getFieldPath()) == null){
                fBAEIsPopulated = false;
                break;
            }//end if   
        }//end for
        return fBAEIsPopulated; 
    }//end evaluateFBAEFields

    //called from ReferenceMPSCTrigger.trigger
    public static void populateReadyToTransferDates(List<Reference_MPSC__c> mpscList){
        for(Reference_MPSC__c refmpsc : mpscList){
            //populate Payroll ready to transfer date
            if (refmpsc.Payroll_IS__c != null && evaluatePayrollFields(refmpsc)){
                if(refmpsc.Payroll_ready_to_Transfer_Date__c == null){
                refmpsc.Payroll_ready_to_Transfer_Date__c = Date.TODAY();
                }
            }
            else {
                refmpsc.Payroll_ready_to_Transfer_Date__c = null;
            }
            //populate TAA ready to transfer date field
            if (refmpsc.TAA_IS__c != null && evaluateTAAFields(refmpsc)){
                if(refmpsc.TAA_ready_to_Transfer_Date__c == null){
                refmpsc.TAA_ready_to_Transfer_Date__c = Date.TODAY();
                }
            }
            else {
                refmpsc.TAA_ready_to_Transfer_Date__c = null;
            }
            //populate Flex HR ready to transfer date field
            if (refmpsc.Flex_HR_IS__c != null && evaluateFlexHRFields(refmpsc)){
                if(refmpsc.Flex_HR_ready_Transfer_Date__c == null){
                refmpsc.Flex_HR_ready_Transfer_Date__c = Date.TODAY();
                }
            }
            else {
                refmpsc.Flex_HR_ready_Transfer_Date__c = null;
            }
            //populate FBAE ready to Transfer Date date field
            if (evaluateFBAEFields(refmpsc)){
                if(refmpsc.FBAE_ready_to_Transfer_Date__c == null){
                refmpsc.FBAE_ready_to_Transfer_Date__c = Date.TODAY();
                }
            }
            else {
                refmpsc.FBAE_ready_to_Transfer_Date__c = null;
            }
            
        }//end for
    }//end populateReadyToTransferDates
    
    
    //called from CaseOwnerChange.trigger 
    //if owner changed on Parent Case, update Payroll IS on Reference MPSC
    public static void updatePayrollIS(Map<Id, Id> CaseIdOwnerMap){
        list<Reference_MPSC__c> mpscsUpdatePayrollIS = new list<Reference_MPSC__c>();
        list<Reference_MPSC__c> refMpscList = new list<Reference_MPSC__c>();
        refMpscList = [SELECT Id, Payroll_IS__c, Case_Lookup__r.ParentId FROM Reference_MPSC__c WHERE Case_Lookup__r.ParentId in: CaseIdOwnerMap.keyset()
        AND MPSC_Status__c != 'Completed'];

        for (Reference_MPSC__c mpsc : refMpscList){
            //only update if the owner that was updated is a user
            String newOwner = CaseIdOwnerMap.get(mpsc.Case_Lookup__r.ParentId);
            if(newOwner.startsWith('005')){
            mpsc.Payroll_IS__c = CaseIdOwnerMap.get(mpsc.Case_Lookup__r.ParentId);
            mpscsUpdatePayrollIS.add(mpsc);
            }
        }
        if(!mpscsUpdatePayrollIS.isEmpty()){
            update mpscsUpdatePayrollIS;
        }
    }//end updatePayrollIS
    
    //update Case current step when the Reference MPSC current step changes
    //called from ReferenceMPSCTrigger.trigger
    public static void updateCase(Map<Id, String> caseCurrentStepMap){
        List<Case> caseList = new List<Case>();
        caseList = [SELECT Id, Current_step__c FROM Case WHERE id IN: caseCurrentStepMap.keySet()];
        for(Case c : caseList){
            c.current_step__c = caseCurrentStepMap.get(c.id);
        }//end for
        if(!caseList.isEmpty()){
            update caseList;
        }
    }//end updateCase
    
    //update the Reference MPSC Current Step
    //called from ReferenceMPSCTrigger.trigger where the record type is checked and Current Step != 'Transferred to Branch'
    public static void updateCurrentStep(List<Reference_MPSC__c> mpscList){
        Set<Id> caseIds = new Set<Id>();
        Id[] refmpscIds = new Id[]{};
        for(Reference_MPSC__c refmpsc: mpscList){
            if(refmpsc.Case_lookup__c!=null && !caseIds.contains(refmpsc.Case_lookup__c)){
                caseIds.add(refmpsc.Case_lookup__c);
            }
            refmpscIds.add(refmpsc.Id);
        }
        Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Id,Account.Name,Account.AccountNumber,Account.Flex_Ben_Admin_Essentials_IC__c FROM Case Where Id in:caseIds]);
        Map<Id,Reference_MPSC__c> refmpscMap = new Map<Id,Reference_MPSC__c>([SELECT Id,SIPM_IPM__c,SIPM_IPM__r.FirstName,SIPM_IPM__r.LastName FROM Reference_MPSC__c Where Id in :refmpscIds]);
        for(Reference_MPSC__c refmpsc : mpscList){            
            //check for potential reset of Current Step
            Case kase = CaseMap.get(refmpsc.Case_Lookup__c);
            String accountNumber = (kase!=null && kase.Account!=null ? kase.Account.AccountNumber:'');
            String accountName = (kase!=null && kase.Account!=null ? kase.Account.Name:'');
            id fbaeId = (kase!=null && kase.Account!=null ? kase.Account.Flex_Ben_Admin_Essentials_IC__c:null);
            Boolean resetCurrentStep1 = false;
            if (refmpsc.Current_Step__c != '(1 of 3) Client in onboarding') {
               if ( (refmpsc.Stand_alone_FBAE__c) || (refmpsc.Stand_alone_Flex_HR__c)  || (refmpsc.Stand_alone_TAA__c) ) {
                  if (refmpsc.Transfer_Call_Type__c == null) {
                     resetCurrentStep1 = true;
                  }
                  else if ( (refmpsc.Stand_alone_FBAE__c) && ( (fbaeId == null) || (refmpsc.FBAE_ready_to_Transfer_Date__c == null) ) ) {
                          resetCurrentStep1 = true;
                     }// end 1st Stand Alone else if
                     else if ( (refmpsc.Stand_alone_Flex_HR__c) && ( (refmpsc.Flex_HR_IS__c == null) || (refmpsc.Flex_HR_ready_Transfer_Date__c == null) ) ) {
                             resetCurrentStep1 = true;
                        }// end 2nd Stand Alone else if
                        else if ( (refmpsc.Stand_alone_TAA__c) && ( (refmpsc.TAA_IS__c == null) || (refmpsc.TAA_ready_to_Transfer_Date__c == null) ) ) {
                                resetCurrentStep1 = true;
                        }// end 3rd Stand Alone else if 
               }//end of Stand Alone check
               
               else if ( (refmpsc.Lost_Product_FBAE__c) || (refmpsc.Lost_Product_Flex_HR__c) || (refmpsc.Lost_Product_TAA__c) ) {
                       if ( (refmpsc.Lost_Product_FBAE__c) && (refmpsc.Lost_Product_Flex_HR__c) && (refmpsc.Lost_Product_TAA__c) &&
                            ( (refmpsc.Payroll_IS__c == null) || (refmpsc.Payroll_ready_to_Transfer_Date__c == null) ||
                              ( (refmpsc.SIPM_IPM__c != null) && !(refmpsc.PM_Approved__c) ) ||
                              (refmpsc.Transfer_Call_Type__c == null) ) ) { 
                          resetCurrentStep1 = true;
                       }//end check all 3 products are Lost
                       else if ( (refmpsc.Payroll_IS__c == null) || (refmpsc.Payroll_ready_to_Transfer_Date__c == null) ||
                                 ( (refmpsc.SIPM_IPM__c != null) && !(refmpsc.PM_Approved__c) ) ||
                                 (refmpsc.Transfer_Call_Type__c == null) )
                                  if ( (refmpsc.Lost_Product_Flex_HR__c)  &&
                                       ( !(refmpsc.Lost_Product_TAA__c) && (refmpsc.TAA_IS__c == null) )  ) {
                                         resetCurrentStep1 = true;
                                  }
                                  else if ( (refmpsc.Lost_Product_TAA__c)  &&    
                                            ( !(refmpsc.Lost_Product_Flex_HR__c) && (refmpsc.Flex_HR_IS__c == null) ) ) {
                                              resetCurrentStep1 = true;
                                     }
                  }//end of Lost check
                  
                  //non-Stand Alone and non-Lost check to reset Current Step to Step1
                  else if ( (refmpsc.Payroll_IS__c != null) && (refmpsc.Payroll_ready_to_Transfer_Date__c == null) ) {
                     resetCurrentStep1 = true;
                  }
                        else if ( (refmpsc.Flex_HR_IS__c != null) && (refmpsc.Flex_HR_ready_Transfer_Date__c == null) ) {
                           resetCurrentStep1 = true;
                        }
                           else if ( (refmpsc.TAA_IS__c != null) && (refmpsc.TAA_ready_to_Transfer_Date__c == null) ) {
                              resetCurrentStep1 = true;
                           }
                              else if ( (refmpsc.SIPM_IPM__c != null) && !(refmpsc.PM_Approved__c) ) {
                                 resetCurrentStep1 = true;
                              }
               
               if (resetCurrentStep1) {
                  refmpsc.Current_Step__c = '(1 of 3) Client in onboarding';
               }
            }//end check for potential reset of Current Step

            //Payroll and NO StandAlone and NO Lost Product evaluation
            if (refmpsc.Payroll_IS__c != null &&
               refmpsc.Payroll_ready_to_Transfer_Date__c != null &&
               (!refmpsc.Stand_alone_Flex_HR__c) &&
               (!refmpsc.Stand_alone_TAA__c) &&
               (!refmpsc.Lost_Product_FBAE__c) &&
               (!refmpsc.Lost_Product_Flex_HR__c) &&
               (!refmpsc.Lost_Product_TAA__c) &&
               (refmpsc.Current_Step__c != 'Transferred to Branch') ) {
                  evaluateCurStepPayrollPlus(refmpsc,caseMap,refmpscMap);
               }
            //Stand Alone evaluation
            else if ( ( (refmpsc.Stand_alone_FBAE__c) || (refmpsc.Stand_alone_Flex_HR__c)  || (refmpsc.Stand_alone_TAA__c) ) &&
                      (!refmpsc.Lost_Product_FBAE__c) &&
                      (!refmpsc.Lost_Product_Flex_HR__c) &&
                      (!refmpsc.Lost_Product_TAA__c) ){
                    evaluateCurStepStandAlone(refmpsc,caseMap);
               }
            //Lost Product evaluation
            else if ( (refmpsc.Lost_Product_FBAE__c) || (refmpsc.Lost_Product_Flex_HR__c) || (refmpsc.Lost_Product_TAA__c) ) {
                    evaluateCurStepLost(refmpsc,caseMap,refmpscMap);
               }
            //TBD evaluation
            else {
                //temp hold spot refmpsc.Current_Step__c = null;
            }
       
        ChatterMentionPost.postBatchFeedElements();
        
        }//end for
        
    }//end updateCurrentStep
    
    //check to see if any fields have been modified to change the Current Step for Payroll Only - Current Steps evaluation
    public static void evaluateCurStepPayrollPlus(Reference_MPSC__c refmpsc,Map<Id,Case> caseMap,Map<Id,Reference_MPSC__c> refmpscMap) {
        Case kase = CaseMap.get(refmpsc.Case_Lookup__c);
        String accountNumber = (kase!=null && kase.Account!=null ? kase.Account.AccountNumber:'');
        String accountName = (kase!=null && kase.Account!=null ? kase.Account.Name:'');
        id fbaeId = (kase!=null && kase.Account!=null ? kase.Account.Flex_Ben_Admin_Essentials_IC__c:'');
        Reference_MPSC__c refMPSCchat = refmpscMap.get(refmpsc.Id);
        String mpscSIPMfirstName = (refMPSCchat!=null && refMPSCchat.SIPM_IPM__c!=null ? refMPSCchat.SIPM_IPM__r.FirstName:'missing First Name');
        String mpscSIPMlastName = (refMPSCchat!=null && refMPSCchat.SIPM_IPM__c!=null ? refMPSCchat.SIPM_IPM__r.LastName:'missing Last Name');
        Boolean noFlexHR = false;
        Boolean isFlexHRGood = false;
        Boolean isFlexHRBSR = false; 
        Boolean noTAA = false;
        Boolean isTAAGood = false;
        Boolean isTAABSR = false;
        List<ID> usersToMention = new List<ID>();
        
        if (refmpsc.Flex_HR_IS__c == null) {      
           noFlexHR = true;
        }
        if ((refmpsc.Flex_HR_IS__c != null) &&
            (refmpsc.Flex_HR_ready_Transfer_Date__c != null)) {
            isFlexHRGood = true;
        }
        if ((refmpsc.Flex_HR_IS__c != null) &&
            (refmpsc.Flex_HR_ready_Transfer_Date__c != null) /*&&
            (String.isNotBlank(refmpsc.Flex_HR_BSR_New__c))*/) {
            isFlexHRBSR = true;
        }

        if (refmpsc.TAA_IS__c == null) {      
           noTAA = true;
        }
        if ((refmpsc.TAA_IS__c != null) &&
            (refmpsc.TAA_ready_to_Transfer_Date__c != null)) {
            isTAAGood = true;
        }
        if ((refmpsc.TAA_IS__c != null) &&
            (refmpsc.TAA_ready_to_Transfer_Date__c != null) &&
            (String.isNotBlank(refmpsc.TAA_BSR_New__c))) {
            isTAABSR = true;
        }

        if ((refmpsc.Transfer_Call_Type__c == null) &&
            (refmpsc.Payroll_IS__c != null) &&
            (refmpsc.Payroll_ready_to_Transfer_Date__c != null) &&
            ( ( (refmpsc.SIPM_IPM__c != null) && (refmpsc.PM_Approved__c) ) || (refmpsc.SIPM_IPM__c == null) ) &&
            ( ( (noFlexHR) || (isFlexHRGood) ) && ( (noTAA) || (isTAAGood) ) ) ) {
              usersToMention.add(refmpsc.Payroll_IS__c);
              if (refmpsc.SIPM_IPM__c != null) {
                 usersToMention.add(refmpsc.SIPM_IPM__c);
              }
              if (refmpsc.SIPM_IP__c != null) {
                 usersToMention.add(refmpsc.SIPM_IP__c);
              }
              
              if (fbaeId != null) {
                    usersToMention.add(fbaeId);
              }
              if ((refmpsc.Flex_HR_IS__c != null) &&
                  (refmpsc.Flex_HR_ready_Transfer_Date__c != null)) {
                    usersToMention.add(refmpsc.Flex_HR_IS__c);
              }
              if ((refmpsc.TAA_IS__c != null) &&
                  (refmpsc.TAA_ready_to_Transfer_Date__c != null)) {
                    usersToMention.add(refmpsc.TAA_IS__c);
              }
              if (refmpsc.Current_Step__c != '(1 of 3) Client in onboarding') {
                    refmpsc.Current_Step__c = '(1 of 3) Client in onboarding';
                      String postText = 'Please complete the Transfer Notification Method field once the contact at '+ accountName + ' has been informed of the pending transition to ongoing service.';
                      ChatterMentionPost.createChatterMentionPost(refmpsc.id, usersToMention, new String[]{postText}, true, false);
              }
        }//END if (refmpsc.Transfer_Call_Type__c == null) && (refmpsc.Payroll_IS__c != null) && (refmpsc.Payroll_ready_to_Transfer_Date__c != null)...
        else {
           //code to send Chatter Post AND set Current_Step = 2
           if ((refmpsc.Transfer_Call_Type__c != null) &&
               (refmpsc.Payroll_IS__c != null) &&
               (refmpsc.Payroll_ready_to_Transfer_Date__c != null) &&
               ( (String.isBlank(refmpsc.Payroll_BSR_New__c)) || (refmpsc.Transfer_Specialist__c == null) ) &&
               ( ( (refmpsc.SIPM_IPM__c != null) && (refmpsc.PM_Approved__c) ) || (refmpsc.SIPM_IPM__c == null) ) &&
               ( ( (noFlexHR) || ((isFlexHRGood) && (isFlexHRBSR == false)) ) && ( (noTAA) || ((isTAAGood) && (isTAABSR == false)) ) ) ) {
                 usersToMention.add(refmpsc.Payroll_IS__c);
                 if (refmpsc.SIPM_IPM__c != null) {
                    usersToMention.add(refmpsc.SIPM_IPM__c);
                    if (refmpsc.SIPM_IP__c != null) {
                       usersToMention.add(refmpsc.SIPM_IP__c);
                    }
                 }//END SIPM_IPM__c != null

                 if (fbaeId != null) {
                       usersToMention.add(fbaeId);
                 }
                 if ((refmpsc.Flex_HR_IS__c != null) &&
                     (refmpsc.Flex_HR_ready_Transfer_Date__c != null)) {
                       usersToMention.add(refmpsc.Flex_HR_IS__c);
                 }
                 if ((refmpsc.TAA_IS__c != null) &&
                     (refmpsc.TAA_ready_to_Transfer_Date__c != null)) {
                       usersToMention.add(refmpsc.TAA_IS__c);
                 }
                 if (refmpsc.Current_Step__c != '(2 of 3) Client ready for transition') {
                       refmpsc.Current_Step__c = '(2 of 3) Client ready for transition';
                         String postText = ' '+ accountName + ' has been assigned to the transfer queue.';
                         ChatterMentionPost.createChatterMentionPost(refmpsc.id, usersToMention, new String[]{postText}, true, false);
                         refmpsc.OwnerID = Label.TransferSpecialistQueue;
                         refmpsc.Date_Ready_for_Transition__c = Date.TODAY();
                 }
            }//END if (refmpsc.Transfer_Call_Type__c != null) && (refmpsc.Payroll_IS__c != null) && (refmpsc.Payroll_ready_to_Transfer_Date__c != null)...

           else  {
               
              //add code to send Chatter Post AND set Current_Step = 3
              if ((refmpsc.Transfer_Call_Type__c != null) &&
                  (refmpsc.Date_Ready_for_Transition__c != null) &&
                  (refmpsc.Payroll_IS__c != null) &&
                  (refmpsc.Payroll_ready_to_Transfer_Date__c != null) &&
                  (String.isNotBlank(refmpsc.Payroll_BSR_New__c)) &&
                  (refmpsc.Transfer_Specialist__c != null) &&
                  (((refmpsc.SIPM_IPM__c != null) && (refmpsc.PM_ready_to_Transfer_Date__c != null)) || (refmpsc.SIPM_IPM__c == null)) &&
                  ( ( (noFlexHR) || (isFlexHRBSR) ) && ( (noTAA) || (isTAABSR) ) ) ) {
                    usersToMention.add(refmpsc.Payroll_IS__c);
                    //usersToMention.add(refmpsc.Payroll_BSR__c);
                    if (refmpsc.Sales_Rep__c != null) {
                       usersToMention.add(refmpsc.Sales_Rep__c);
                    }
              

                 if (fbaeId != null) {
                       usersToMention.add(fbaeId);
                 }
                 if ((refmpsc.Flex_HR_IS__c != null) &&
                     (refmpsc.Flex_HR_ready_Transfer_Date__c != null) /*&&
                     (String.isNotBlank(refmpsc.Flex_HR_BSR_New__c))*/) {
                       usersToMention.add(refmpsc.Flex_HR_IS__c);
                       //usersToMention.add(refmpsc.Flex_HR_BSR__c);
                 }
                 if ((refmpsc.TAA_IS__c != null) &&
                     (refmpsc.TAA_ready_to_Transfer_Date__c != null) &&
                     (String.isNotBlank(refmpsc.TAA_BSR_New__c))) {
                       usersToMention.add(refmpsc.TAA_IS__c);
                       //usersToMention.add(refmpsc.TAA_BSR__c);
                 }


                 if (refmpsc.Current_Step__c != '(3 of 3) Transitioned to support') {
                       refmpsc.Current_Step__c = '(3 of 3) Transitioned to support';
                       if (refmpsc.SIPM_IPM__c != null) {
                          usersToMention.add(refmpsc.SIPM_IPM__c);
                          if (refmpsc.SIPM_IP__c != null) {
                             usersToMention.add(refmpsc.SIPM_IP__c);
                          }
                          String postText = ' - '+ accountName + ', '+ accountNumber + ',  has been assigned. This client has a Project Manager. ' + mpscSIPMfirstName + ' ' + mpscSIPMlastName + ' will coordinate an official hand off call between implementation and ongoing service.  Client contact should not occur until this call is completed.';
                          ChatterMentionPost.createChatterMentionPost(refmpsc.id, usersToMention, new String[]{postText}, true, false);
                       }
                       else {
                          String postText = ' '+ accountName + ', '+ accountNumber + ',  has been successfully transitioned to support.';
                          ChatterMentionPost.createChatterMentionPost(refmpsc.id, usersToMention, new String[]{postText}, true, false);
                       }
                       refmpsc.Send_Survey_Trigger__c = TRUE;
                 }
              }//END  if ((refmpsc.Transfer_Call_Type__c != null) && (refmpsc.Date_Ready_for_Transition__c != null) && (refmpsc.Payroll_IS__c != null) &&... (3rd check)

           }//END 2nd else

        }//END of 1st else

    }//evaluateCurStepPayrollPlus
            
            
    //check to see if any fields have been modified to change the Current Step for Stand Alone - Current Steps evaluation
    public static void evaluateCurStepStandAlone(Reference_MPSC__c refmpsc,Map<Id,Case> caseMap) {
        Case kase = CaseMap.get(refmpsc.Case_Lookup__c);
        String accountNumber = (kase!=null && kase.Account!=null ? kase.Account.AccountNumber:'');
        String accountName = (kase!=null && kase.Account!=null ? kase.Account.Name:'');
        id fbaeId = (kase!=null && kase.Account!=null ? kase.Account.Flex_Ben_Admin_Essentials_IC__c:'');
        List<ID> usersToMention = new List<ID>();
        Boolean fbaeIsStandAlone = (refmpsc.Stand_alone_FBAE__c);
        Boolean flexIsStandAlone = (refmpsc.Stand_alone_Flex_HR__c);
        Boolean taaIsStandAlone  = (refmpsc.Stand_alone_TAA__c);
        Boolean noSAfbae = false;
        Boolean isSAfbaeGood = false;
        Boolean isSAfbaeBSR = false; 
        Boolean noSAFlexHR = false;
        Boolean isSAFlexHRGood = false;
        Boolean isSAFlexHRBSR = false; 
        Boolean noSATAA = false;
        Boolean isSATAAGood = false;
        Boolean isSATAABSR = false;

        if (fbaeId == null) {      
           noSAfbae = true;
        }
        
        if ((fbaeId != null) &&
            (refmpsc.FBAE_ready_to_Transfer_Date__c != null) &&
            (refmpsc.Transfer_Specialist__c == null)) {
            isSAfbaeGood = true;
        }
        
        if ((fbaeId != null) &&
            (refmpsc.FBAE_ready_to_Transfer_Date__c != null) &&
            (refmpsc.Transfer_Specialist__c != null)) {
            isSAfbaeBSR = true;
        }

        if (refmpsc.Flex_HR_IS__c == null) {      
           noSAFlexHR = true;
        }
        
        if ((refmpsc.Flex_HR_IS__c != null) &&
            (refmpsc.Flex_HR_ready_Transfer_Date__c != null) /*&&
            (String.isBlank(refmpsc.Flex_HR_BSR_New__c))*/) {
            isSAFlexHRGood = true;
        }
        
        if ((refmpsc.Flex_HR_IS__c != null) &&
            (refmpsc.Flex_HR_ready_Transfer_Date__c != null) /*&&
            (String.isNotBlank(refmpsc.Flex_HR_BSR_New__c))*/) {
            isSAFlexHRBSR = true;
        }
        

        if (refmpsc.TAA_IS__c == null) {      
           noSATAA = true;
        }
        
        if ((refmpsc.TAA_IS__c != null) &&
            (refmpsc.TAA_ready_to_Transfer_Date__c != null) &&
            (String.isBlank(refmpsc.TAA_BSR_New__c))) {
            isSATAAGood = true;
        }
        
        if ((refmpsc.TAA_IS__c != null) &&
            (refmpsc.TAA_ready_to_Transfer_Date__c != null) &&
            (String.isNotBlank(refmpsc.TAA_BSR_New__c))) {
            isSATAABSR = true;
        }
        
        if ( (refmpsc.Transfer_Call_Type__c == null) &&
             ( ( !(fbaeIsStandAlone) || (isSAfbaeGood) ) && ( !(flexIsStandAlone) || (isSAFlexHRGood) ) && ( !(taaIsStandAlone) || (isSATAAGood) ) )     ) {
                 
           if (fbaeId != null) {
                 usersToMention.add(fbaeId);
           }
           if ((flexIsStandAlone) &&
               (refmpsc.Flex_HR_IS__c != null) &&
               (refmpsc.Flex_HR_ready_Transfer_Date__c != null)) {
                 usersToMention.add(refmpsc.Flex_HR_IS__c);
           }
           if ((taaIsStandAlone) &&
               (refmpsc.TAA_IS__c != null) &&
               (refmpsc.TAA_ready_to_Transfer_Date__c != null)) {
                 usersToMention.add(refmpsc.TAA_IS__c);
           }
           if (refmpsc.Current_Step__c != '(2 of 3) Client ready for transition') {
                   refmpsc.Current_Step__c = '(1 of 3) Client in onboarding';
                   String postText = 'Please complete the Transfer Notification Method field once the contact at '+ accountName + ' has been informed of the pending transition to ongoing service.';
                   ChatterMentionPost.createChatterMentionPost(refmpsc.id, usersToMention, new String[]{postText}, true, false);
              }
        }//END if (refmpsc.Transfer_Call_Type__c == null) aka Step1 processing

        else {
           if ( (refmpsc.Transfer_Call_Type__c != null) &&
                ( ( !(fbaeIsStandAlone) || ( (isSAfbaeGood)   && ( (!isSAfbaeBSR)   || (refmpsc.Transfer_Specialist__c == null) ) ) ) &&
                  ( !(flexIsStandAlone) || ( (isSAFlexHRGood) && ( (!isSAFlexHRBSR) || (refmpsc.Transfer_Specialist__c == null) ) ) ) &&
                  ( !(taaIsStandAlone)  || ( (isSATAAGood)    && ( (!isSATAABSR)    || (refmpsc.Transfer_Specialist__c == null) ) ) )   )  ) {
              if (fbaeId != null) {
                     usersToMention.add(fbaeId);
              }
              if ( (flexIsStandAlone) && (isSAFlexHRGood) && (!isSAFlexHRBSR) ) {
                     usersToMention.add(refmpsc.Flex_HR_IS__c);
              }
              if ( (taaIsStandAlone) && (isSATAAGood) && (!isSATAABSR) ) {
                     usersToMention.add(refmpsc.TAA_IS__c);
              }

              if (refmpsc.SIPM_IPM__c != null) {
                 usersToMention.add(refmpsc.SIPM_IPM__c);
              }
              if (refmpsc.SIPM_IP__c != null) {
                 usersToMention.add(refmpsc.SIPM_IP__c);
              }

              if (refmpsc.Current_Step__c != '(2 of 3) Client ready for transition') {
                    refmpsc.Current_Step__c = '(2 of 3) Client ready for transition';
                    String postText = ' '+ accountName + ' has been assigned to the transfer queue.';
                    ChatterMentionPost.createChatterMentionPost(refmpsc.id, usersToMention, new String[]{postText}, true, false);
                    refmpsc.OwnerID = Label.TransferSpecialistQueue;
                    refmpsc.Date_Ready_for_Transition__c = Date.TODAY();
              }
           }//end Step2 processing
           
           else {
              if ( (refmpsc.Transfer_Call_Type__c != null) && (refmpsc.Transfer_Specialist__c != null) && (refmpsc.Date_Ready_for_Transition__c != null) &&
                   ( ( !(fbaeIsStandAlone) || (isSAfbaeBSR) ) && ( !(flexIsStandAlone) || (isSAFlexHRBSR) ) && ( !(taaIsStandAlone) || (isSATAABSR) ) )  ) {
                 if (fbaeId != null) {
                       usersToMention.add(fbaeId);
                 }
                 if ( (flexIsStandAlone) && (isSAFlexHRBSR) ) {
                        usersToMention.add(refmpsc.Flex_HR_IS__c);
                        //usersToMention.add(refmpsc.Flex_HR_BSR__c);
                 }
                 if ( (taaIsStandAlone) && (isSATAABSR) ) {
                        usersToMention.add(refmpsc.TAA_IS__c);
                        //usersToMention.add(refmpsc.TAA_BSR__c);
                 }
                 if (refmpsc.SIPM_IPM__c != null) {
                    usersToMention.add(refmpsc.SIPM_IPM__c);
                 }
                 if (refmpsc.SIPM_IP__c != null) {
                    usersToMention.add(refmpsc.SIPM_IP__c);
                 }

                 if (refmpsc.Current_Step__c != '(3 of 3) Transitioned to support') {
                       refmpsc.Current_Step__c = '(3 of 3) Transitioned to support';
                       String postText = ' '+ accountName + ', '+ accountNumber + ',  has been successfully transitioned to support.';
                       ChatterMentionPost.createChatterMentionPost(refmpsc.id, usersToMention, new String[]{postText}, true, false);
                       refmpsc.Send_Survey_Trigger__c = TRUE;
                 }
                 
              }//END if (refmpsc.Date_Ready_for_Transition__c != null)  aka Step3 processing
              
           }//END 2nd else
        }//END 1st else of evaluateCurStepStandAlone
        
    }//evaluateCurStepStandAlone



    //check to see if any fields have been modified to change the Current Step for Lost - Current Steps evaluation
    public static void evaluateCurStepLost(Reference_MPSC__c refmpsc,Map<Id,Case> caseMap,Map<Id,Reference_MPSC__c> refmpscMap) {
        Case kase = CaseMap.get(refmpsc.Case_Lookup__c);
        String accountNumber = (kase!=null && kase.Account!=null ? kase.Account.AccountNumber:'');
        String accountName = (kase!=null && kase.Account!=null ? kase.Account.Name:'');
        id fbaeId = (kase!=null && kase.Account!=null ? kase.Account.Flex_Ben_Admin_Essentials_IC__c:'');
        Reference_MPSC__c refMPSCchat = refmpscMap.get(refmpsc.Id);
        String mpscSIPMfirstName = (refMPSCchat!=null && refMPSCchat.SIPM_IPM__c!=null ? refMPSCchat.SIPM_IPM__r.FirstName:'missing First Name');
        String mpscSIPMlastName = (refMPSCchat!=null && refMPSCchat.SIPM_IPM__c!=null ? refMPSCchat.SIPM_IPM__r.LastName:'missing Last Name');
        List<ID> usersToMention = new List<ID>();
        Boolean sendStep1Chatter = false;
        Boolean fbaeIsLost = (refmpsc.Lost_Product_FBAE__c);
        Boolean flexIsLost = (refmpsc.Lost_Product_Flex_HR__c);
        Boolean taaIsLost  = (refmpsc.Lost_Product_TAA__c);

        if ((refmpsc.Transfer_Call_Type__c == null) &&
            (refmpsc.Payroll_IS__c != null) &&
            (refmpsc.Payroll_ready_to_Transfer_Date__c != null) &&
            (((refmpsc.SIPM_IPM__c != null) && (refmpsc.PM_Approved__c)) || (refmpsc.SIPM_IPM__c == null))) {
              usersToMention.add(refmpsc.Payroll_IS__c);
              if (refmpsc.SIPM_IPM__c != null) {
                 usersToMention.add(refmpsc.SIPM_IPM__c);
              }
              sendStep1Chatter = true;
           if (fbaeId != null) {
                 usersToMention.add(fbaeId);
                 sendStep1Chatter = true;
           }
           if ((!refmpsc.Lost_Product_Flex_HR__c) &&
               (refmpsc.Flex_HR_IS__c != null) &&
               (refmpsc.Flex_HR_ready_Transfer_Date__c != null)) {
                 usersToMention.add(refmpsc.Flex_HR_IS__c);
                 sendStep1Chatter = true;
           }
           if ((!refmpsc.Lost_Product_TAA__c) &&
               (refmpsc.TAA_IS__c != null) &&
               (refmpsc.TAA_ready_to_Transfer_Date__c != null)) {
                 usersToMention.add(refmpsc.TAA_IS__c);
                 sendStep1Chatter = true;
           }
           if (refmpsc.Current_Step__c != '(1 of 3) Client in onboarding') {
                   refmpsc.Current_Step__c = '(1 of 3) Client in onboarding';
           }
           if (sendStep1Chatter) {
              String postText = 'Please complete the Transfer Notification Method field once the contact at '+ accountName + ' has been informed of the pending transition to ongoing service.';
              ChatterMentionPost.createChatterMentionPost(refmpsc.id, usersToMention, new String[]{postText}, true, false);
           }
        }//END if (refmpsc.Transfer_Call_Type__c == null) && (refmpsc.Payroll_IS__c != null) && (refmpsc.Payroll_ready_to_Transfer_Date__c != null) && .........
        else {
        
           //code to send Chatter Post AND set Current_Step = 2
           if ((refmpsc.Transfer_Call_Type__c != null) &&
               (refmpsc.Payroll_IS__c != null) &&
               (refmpsc.Payroll_ready_to_Transfer_Date__c != null) &&
               ( (String.isBlank(refmpsc.Payroll_BSR_New__c)) || (refmpsc.Transfer_Specialist__c == null) ) &&
               (((refmpsc.SIPM_IPM__c != null) && (refmpsc.PM_Approved__c)) || (refmpsc.SIPM_IPM__c == null))) {
                 usersToMention.add(refmpsc.Payroll_IS__c);
                 if (refmpsc.SIPM_IPM__c != null) {
                    usersToMention.add(refmpsc.SIPM_IPM__c);
                 }

                 if (fbaeId != null) {
                       usersToMention.add(fbaeId);
                 }
                 if ((!refmpsc.Lost_Product_Flex_HR__c) &&
                     (refmpsc.Flex_HR_IS__c != null) &&
                     (refmpsc.Flex_HR_ready_Transfer_Date__c != null) /*&&
                     (String.isBlank(refmpsc.Flex_HR_BSR_New__c))*/) {
                       usersToMention.add(refmpsc.Flex_HR_IS__c);
                 }
                 if ((!refmpsc.Lost_Product_TAA__c) &&
                     (refmpsc.TAA_IS__c != null) &&
                     (refmpsc.TAA_ready_to_Transfer_Date__c != null) &&
                     (String.isBlank(refmpsc.TAA_BSR_New__c))) {
                       usersToMention.add(refmpsc.TAA_IS__c);
                 }
                 if (refmpsc.Current_Step__c != '(2 of 3) Client ready for transition') {
                         refmpsc.Current_Step__c = '(2 of 3) Client ready for transition';
                         String postText = ' '+ accountName + ' has been assigned to the transfer queue.';
                         ChatterMentionPost.createChatterMentionPost(refmpsc.id, usersToMention, new String[]{postText}, true, false);
                         refmpsc.OwnerID = Label.TransferSpecialistQueue;
                         refmpsc.Date_Ready_for_Transition__c = Date.TODAY();
                 }
           }//END of Step2 Lost checks
           else  {
              if ((refmpsc.Transfer_Call_Type__c != null) &&
                  (refmpsc.Date_Ready_for_Transition__c != null) &&
                  (refmpsc.Payroll_IS__c != null) &&
                  (refmpsc.Payroll_ready_to_Transfer_Date__c != null) &&
                  (String.IsNotBlank(refmpsc.Payroll_BSR_New__c)) &&
                  (refmpsc.Transfer_Specialist__c != null) &&
                  (((refmpsc.SIPM_IPM__c != null) && (refmpsc.PM_Approved__c)) || (refmpsc.SIPM_IPM__c == null))) {
                    usersToMention.add(refmpsc.Payroll_IS__c);
                    //usersToMention.add(refmpsc.Payroll_BSR__c);
                    if (refmpsc.Sales_Rep__c != null) {
                       usersToMention.add(refmpsc.Sales_Rep__c);
                    }

                 if (fbaeId != null) {
                        usersToMention.add(fbaeId);
                 }

                 if ((!refmpsc.Lost_Product_Flex_HR__c) &&
                     (refmpsc.Flex_HR_IS__c != null) &&
                     (refmpsc.Flex_HR_ready_Transfer_Date__c != null) &&
                     (refmpsc.Transfer_Specialist__c != null) /*&&
                     (String.isNotBlank(refmpsc.Flex_HR_BSR_New__c))*/) {
                        usersToMention.add(refmpsc.Flex_HR_IS__c);
                        //usersToMention.add(refmpsc.Flex_HR_BSR__c);
                 }
                 if ((!refmpsc.Lost_Product_TAA__c) &&
                     (refmpsc.TAA_IS__c != null) &&
                     (refmpsc.TAA_ready_to_Transfer_Date__c != null) &&
                     (refmpsc.Transfer_Specialist__c != null) &&
                     (String.isNotBlank(refmpsc.TAA_BSR_New__c))) {
                        usersToMention.add(refmpsc.TAA_IS__c);
                        //usersToMention.add(refmpsc.TAA_BSR__c);
                 }

                 if (refmpsc.Current_Step__c != '(3 of 3) Transitioned to support') {
                       refmpsc.Current_Step__c = '(3 of 3) Transitioned to support';
                       if (refmpsc.SIPM_IPM__c != null) {
                          usersToMention.add(refmpsc.SIPM_IPM__c);
                          if (refmpsc.SIPM_IP__c != null) {
                             usersToMention.add(refmpsc.SIPM_IP__c);
                          }
                          String postText = ' - '+ accountName + ', '+ accountNumber + ',  has been assigned. This client has a Project Manager. ' + mpscSIPMfirstName + ' ' + mpscSIPMlastName + ' will coordinate an official hand off call between implementation and ongoing service.  Client contact should not occur until this call is completed.';
                          ChatterMentionPost.createChatterMentionPost(refmpsc.id, usersToMention, new String[]{postText}, true, false);
                       }
                       else {
                          String postText = ' '+ accountName + ', '+ accountNumber + ',  has been successfully transitioned to support.';
                          ChatterMentionPost.createChatterMentionPost(refmpsc.id, usersToMention, new String[]{postText}, true, false);
                       }
                       refmpsc.Send_Survey_Trigger__c = TRUE;
                 }
              }//END  if ((refmpsc.Transfer_Call_Type__c != null) && (refmpsc.Date_Ready_for_Transition__c != null) && (refmpsc.Payroll_IS__c != null) &&...

           }//END 2nd else

        }//END of 1st else

    }//evaluateCurStepLost
    
    public static void sendChatterOnRefMPSCInsert(Map<Id, Reference_MPSC__c> mpscMap){
        List<Reference_MPSC__c> refs = new List<Reference_MPSC__c>();
        //BAU Changes--removing 'Flex_HR_BSR_New__c' from the query
        refs = [Select Id, Prospect_Client__c, Prospect_Client__r.Name, Prospect_Client__r.AccountNumber, Prospect_Client__r.HRO_Implementation_Coordinator__c,Prospect_Client__r.TLO_Implementation_Coordinator__c,
                Case_Lookup__c, Case_Lookup__r.CaseNumber, TAA_BSR_New__c, RecordTypeId, 
                Stand_alone_Flex_HR__c, Stand_alone_TAA__c, Prospect_Client__r.MMS_AS__r.User_Lookup__c, Prospect_Client__r.Paychex_Payroll_Specialist__r.User_Lookup__c, Prospect_Client__r.MMS_MAM_NAM__r.User_Lookup__c, Prospect_Client__r.OwnerId
                from Reference_MPSC__c where Id IN :mpscMap.keySet()];
        List<ID> usersToMention = new List<ID>();
        String postText = '';
        
        for(Reference_MPSC__c ref: refs){
            if(ref.RecordTypeId == mpscTransferRecordTypeId && ref.Case_Lookup__c != null && ref.Prospect_Client__c != null && ref.Stand_alone_Flex_HR__c == false && ref.Stand_alone_TAA__c == false){
                postText = 'The transfer record and case ' + ref.Case_Lookup__r.CaseNumber + ' for ' + ref.Prospect_Client__r.Name + ', ' + ref.Prospect_Client__r.AccountNumber + ' have been created.';
                if(ref.Prospect_Client__r.OwnerId != null) {
                    usersToMention.add(ref.Prospect_Client__r.OwnerId);
                }
                if(ref.Prospect_Client__r.HRO_Implementation_Coordinator__c != null) {
                    usersToMention.add(ref.Prospect_Client__r.HRO_Implementation_Coordinator__c);
                }
                if(ref.Prospect_Client__r.TLO_Implementation_Coordinator__c != null) {
                    usersToMention.add(ref.Prospect_Client__r.TLO_Implementation_Coordinator__c);
                }
                if(ref.Prospect_Client__r.MMS_AS__r.User_Lookup__c != null) {
                    usersToMention.add(ref.Prospect_Client__r.MMS_AS__r.User_Lookup__c);
                }
                /*if(ref.Prospect_Client__r.Paychex_Payroll_Specialist__r.User_Lookup__c != null) {
                    usersToMention.add(ref.Prospect_Client__r.Paychex_Payroll_Specialist__r.User_Lookup__c);
                }*/
                if(ref.Prospect_Client__r.MMS_MAM_NAM__r.User_Lookup__c != null) {
                    usersToMention.add(ref.Prospect_Client__r.MMS_MAM_NAM__r.User_Lookup__c);
                }
                if(usersToMention != null && !usersToMention.isEmpty()) {
                    ChatterMentionPost.createChatterMentionPost(ref.Id, usersToMention, new String[]{postText}, false); 
                    usersToMention.clear();
                }
                usersToMention.clear();   
            }
        }
            
    }//end sendChatterOnRefMPSCInsert

}