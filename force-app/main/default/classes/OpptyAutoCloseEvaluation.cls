/* Logic to evaluate auto close date for opportunities
   
  History
  -------
  02/18/2020 Jake Hinds      Created
  10/09/2020 Jake Hinds   Adding without sharing per PMD
  16/13/2023 Lalan Kumar   APR0135718: Auto- Close Opp Process for Termed/Inactive Users
  10/24/2023 Dan Carmen    Rewrote code, moved logic to the oppty before trigger
  12/05/2023 Dan Carmen    Add a filter for selecting the opportunities for activity
  12/15/2023 Dan Carmen    Fix the criteria, add more logging
  01/22/2024 Dan Carmen    Fix code setting the date when it's blank
  01/31/2024 Dan Carmen    Fix code for joint opportunity
  02/26/2024 Lalan Kumar   APR0164336: Update Auto Close timeline for Acquisition opportunities
  03/11/2024 Dan Carmen    Add additional debugging
  04/12/2024 Dan Carmen    Add ability to skip future methods
  05/22/2024 Saif Khan     APR0167020: Request for new Opportunity Status for PEO, HNBF and P&C
*/
public without sharing class OpptyAutoCloseEvaluation implements TriggerInterfaceC {
    public static Boolean SKIP_FUTURE_ACT=(Label.OpptyAutoClose_ActivitySkipFuture=='Y');

    public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        SObject[] recs = TriggerMethods.checkRecs('OpptyAutoCloseEvaluation', p_recs, oldMap, isBefore, isAfter, isDelete, null, null);
        system.debug('OpptyAutoCloseEvaluation.handleTrigger p_recs='+(p_recs != null ? p_recs.size() : -1)+' recs='+(recs != null ? recs.size() : -1)+' objType='+TriggerMethods.objType+' isBefore='+isBefore+' isAfter='+isAfter);
        if (recs == null || recs.isEmpty()) {
           return;
        }
        
        User runningUser = UserHelper.getRunningUser();
        Boolean isSalesRep = (string.IsNotBlank(runningUser.Job_Name__c) && (runningUser.Job_Name__c==UserHelper.JOB_REP 
                                                                             || runningUser.Job_Name__c==UserHelper.JOB_ZSA 
                                                                             || runningUser.Job_Name__c==UserHelper.JOB_AREA));
        Boolean checkActivity = (UserHelper.isRunningUserSystemAdmin() || isSalesRep);
        Map<Id,Id> acctIdByActOwnerId = new Map<Id,Id>();
        
        if (isBefore && TriggerMethods.objType == Opportunity.sObjectType) {
            handleOppsBefore((Opportunity[])recs, (Map<Id,Opportunity>)oldMap);
        } else if (isAfter && TriggerMethods.objType == Opportunity.sObjectType) {
            handleOppsAfter((Opportunity[])recs, (Map<Id,Opportunity>)oldMap);
       } else if (checkActivity && isAfter && TriggerMethods.objType == Task.sObjectType) {
            //only want this to fire for tasks created by sales people
            for (Task tk : (Task[])recs) {
               Task oldTk = (oldMap!=null ? (Task)oldMap.get(tk.Id) : null);
               system.debug('OpptyAutoCloseEvaluation.handleTrigger tk.AccountId:'+tk.AccountId+' tk.Status: '+tk.Status);
               if (tk.Status=='Completed' && tk.AccountId != null 
                       && (oldTk == null || (oldTk.Status != tk.Status || oldTk.ActivityDate != tk.ActivityDate))) {
                 acctIdByActOwnerId.put(tk.AccountId,tk.OwnerId);
               }
            } // for (Task tk : (Task[])recs
        } else if (checkActivity && isAfter && TriggerMethods.objType == Event.sObjectType) {
            //only want this to fire for tasks created by sales people
            for (Event ev : (Event[])recs) {
               Event oldEv = (oldMap!=null ? (Event)oldMap.get(ev.Id) : null);
                if (ev.AccountId != null && (oldEv==null || (oldEv.ActivityDate != ev.ActivityDate))) {
                   acctIdByActOwnerId.put(ev.AccountId,ev.OwnerId);
                }
            } // for (Event ev : (Event[])recs
        } else if (isAfter && TriggerMethods.objType == Referral__c.sObjectType) {
            
            Id[] oppIds = new Id[]{};
            for (Referral__c ref : (Referral__c[])recs) {
                Referral__c oldRef = (oldMap!=null?(Referral__c)oldMap.get(ref.Id):null);
                if(ref.ReferralJoin__c!=null && ref.Selling_Opportunity__c!=null && oldRef!=null && oldRef.ReferralJoin__c != ref.ReferralJoin__c){
                   oppIds.add(ref.Selling_Opportunity__c);
                } 
            } // for (Referral__c ref : (Referral__c[])recs
           checkEvaluateOpps(oppIds, false);
        }//referral trigger
        
        system.debug('OpptyAutoCloseEvaluation.handleTrigger isSalesRep='+isSalesRep+' checkActivity='+checkActivity+' acctIdByActOwnerId='+acctIdByActOwnerId.size());

         if (!acctIdByActOwnerId.isEmpty()) {
             // make sure there are open opps related to the activity before proceeding.
             Integer nbrOpps = [Select count() from Opportunity 
                                 Where IsClosed=false and AccountId in :acctIdByActOwnerId.keySet() 
                                   and Auto_Close_Date__c != null
                                   and OwnerId in :acctIdByActOwnerId.values() limit 1];
             system.debug('OpptyAutoCloseEvaluation.handleTrigger nbrOpps='+nbrOpps);
             if (nbrOpps > 0) {
                if (!SKIP_FUTURE_ACT && Utilities.allowFuture()) {
                    evaluateAutoCloseDateFromActivityFuture(acctIdByActOwnerId);
                } else {
                   evaluateAutoCloseDateFromActivity(acctIdByActOwnerId);
                }
             } // if (nbrOpps > 0
         } // if (!acctIdByActOwnerId.isEmpty())

    } // triggerCheckAllFirst

    // the default maximum probability for an opp in the autoclose process. Can be overwritten by the custom setting.
    public static Decimal defaultMaxProb=80;
    // the lead sources that are not part of the autoclose process
    public static Set<String> excludeLeadSourceSet = new Set<String>(Label.Oppty_Auto_Close_Exclude_Lead_Source.split(';'));
    public static Set<String> excludeOppTypeSet = new Set<String>(Label.ExcludeOpptyType.split(','));

    public static Boolean oppAfterTrigger=false;
    public static Id[] oppsForAfterTrigger=new Id[]{};
     
    public static void handleOppsBefore(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
       Map<Id,Schema.RecordTypeInfo> byIdMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosById();

       for (Opportunity opp : opps) {
          Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
          if (opp.Auto_Close_Date__c != null && opp.IsClosed) {
             opp.Auto_Close_Date__c = null;
             opp.Evaluate_Auto_Close__c = false;
          } else if (!opp.isClosed) {
             if (oldOpp==null || (oldOpp!=null && (oldOpp.RecordTypeId != opp.RecordTypeId 
                                                 || oldOpp.LeadSource != opp.LeadSource 
                                                 || oldOpp.OpportunityType__c != opp.OpportunityType__c 
                                                 || oldOpp.Probability != opp.Probability 
                                                 || oldOpp.StageName != opp.StageName
                                                 || oldOpp.NSS_Source__c!=opp.NSS_Source__c
                                                 || oldOpp.ReferralLookup__c != opp.ReferralLookup__c 
                                                 || oldOpp.ProductGroupsSelected__c != opp.ProductGroupsSelected__c
                                                 || opp.Evaluate_Auto_Close__c))) {
                if (opp.Evaluate_Auto_Close__c) {
                   opp.Evaluate_Auto_Close__c = false;                                     
                }
                Schema.RecordTypeInfo rtInfo = (opp.RecordTypeId != null ? byIdMap.get(opp.RecordTypeId) : null);
                // this should never be null
                if (rtInfo != null) {
                   RecordType__c rts = RecordTypeHelper.getRtSetting(rtInfo.getName());
                   Boolean isInbound = (String.isNotBlank(opp.NSS_Source__c) && opp.NSS_Source__c.startsWith('Inbound'));
                   Decimal maxProb = (rts != null && rts.Opportunity_Auto_Close_Max_Probability__c != null ? rts.Opportunity_Auto_Close_Max_Probability__c 
                                          : (rts != null ? defaultMaxProb : null));
                   Boolean isAutoCloseAvail = (rts != null && ((rts.Non_Inbound_number_of_days__c != null 
                                                                   || (isInbound && rts.Opportunity_Auto_Close_Duration__c != null)
                                                                   || (rts.Extend_Number_of_Days__c!=null && opp.Auto_Close_Date__c != null))
                                                               || (rts.Auto_Close_Joint_Only__c && opp.JointAppointmentId__c != null)
                                                               || (String.isNotBlank(rts.AutoCloseProdGroup__c) && opp.EvaluateProductGroup__c
                                                                       & String.isNotBlank(opp.ProductGroupsSelected__c))));
                   String msg = 'rts='+(rts != null ? rts.Name : 'NotFound')+' inbound='+isInbound+' stage='+opp.StageName+' Prob='+opp.Probability+' maxProb='+maxProb+' isAutoClose='+isAutoCloseAvail;
                   System.debug('handleOppsBefore opp='+opp.Name+' '+msg);
                   isAutoCloseAvail = (isAutoCloseAvail && (String.isBlank(opp.LeadSource) || !excludeLeadSourceSet.contains(opp.LeadSource))
                                                        && (String.isBlank(opp.OpportunityType__c) || !excludeOppTypeSet.contains(opp.OpportunityType__c)));
                   msg += ' isAutoClose2='+isAutoCloseAvail;
                   System.debug('handleOppsBefore isAutoCloseAvail='+isAutoCloseAvail);
                   if (opp.Auto_Close_Date__c != null && (!isAutoCloseAvail || maxProb == null
                                                         || (maxProb != null && opp.Probability >= maxProb))) {
                      // this should not autoclose - clear the date
                      opp.Auto_Close_Date__c = null;
                   } else if (isAutoCloseAvail && opp.Probability < maxProb) {
                      msg += ' evaluate in after trig';
                      if (opp.Id != null) {
                         // would prefer to do it on a case by case basis
                         oppsForAfterTrigger.add(opp.Id);
                      } else {
                         opp.Evaluate_Auto_Close__c = true;
                         oppAfterTrigger = true;
                      }
                   }
                   StringHelper.addToProcessNotes(opp,msg);
                } // if (rtInfo != null
                                                     
             } // if (oldOpp==null
          } // if (opp.Auto_Close_Date__c
          
       } // for (Opportunity opp : opps
       oppAfterTrigger = (oppAfterTrigger || !oppsForAfterTrigger.isEmpty());
    } // handleOppsBefore
    
    public static void handleOppsAfter(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
       System.debug('handleOppsAfter oppAfterTrigger='+oppAfterTrigger+' oppsForAfterTrigger='+oppsForAfterTrigger.size());
       if (oppAfterTrigger) {
          Id[] checkAutoCloseIds = new Id[]{};
          for (Opportunity opp : opps) {
             if (opp.Evaluate_Auto_Close__c || (oppsForAfterTrigger.contains(opp.Id))) {
                checkAutoCloseIds.add(opp.Id);
             }
          } // for (Opportunity opp : opps
          oppAfterTrigger = false;
          oppsForAfterTrigger.clear();
          System.debug('handleOppsAfter checkAutoCloseIds='+checkAutoCloseIds.size());
          checkEvaluateOpps(checkAutoCloseIds, (oldMap==null));
       } // if (oppAfterTrigger
    } // handleOppsAfter
    
    public static Boolean SKIP_FUTURE=(Label.OpptyAutoClose_SkipFuture=='Y');
    
    public static void checkEvaluateOpps(Id[] oppIds, boolean isOppInsert) {
       System.debug('checkEvaluateOpps oppIds='+oppIds.size()+' isOppInsert='+isOppInsert);
       if (!oppIds.isEmpty()){
          if (!SKIP_FUTURE && !isOppInsert && Utilities.allowFuture()) {
              evaluateAutoCloseDateFromOppsFuture(oppIds, isOppInsert);
          } else {
              evaluateAutoCloseDateFromOpps(oppIds, isOppInsert);
          }
       }
    } // checkEvaluateOpps
    
    //methods coming from oppty trigger to get opportunity for eval
    @future
    public static void evaluateAutoCloseDateFromOppsFuture(Id[] oppIds, Boolean isOppInsert) {
         evaluateAutoCloseDateFromOpps(oppIds, isOppInsert);
    } // evaluateAutoCloseDateFromOppsFuture
    
     // APR0135718: Added StageName and Status_Update_Date__c in the opptys query
    public static void evaluateAutoCloseDateFromOpps(Id[] opptyIds, Boolean isOppInsert){
        Opportunity[]opptys  = [SELECT Id,Name,AccountId,OwnerId,Probability,RecordTypeId,RecordType.Name,OpportunityType__c,LeadSource
                                      ,JointAppointmentId__c,NSS_Source__c,Auto_Close_Date__c,CreatedDate,Evaluate_Auto_Close__c 
                                      ,EvaluateProductGroup__c,ProductGroupsSelected__c,StageName,Follow_Up_Date__c,Status_Update_Date__c, ProcessNotes__c
                                      ,ReferralLookup__c, ReferralLookup__r.ReferralJoin__c
                                  FROM Opportunity WHERE Id in:opptyIds];
        checkOpportunityForExpirationEligibility(opptys,isOppInsert);
    } // evaluateAutoCloseDateFromOpps
    
    //methods coming from task trigger to get opportunity for eval
    @future
    public static void evaluateAutoCloseDateFromActivityFuture(Map<Id,Id> acctIdByActivityOwnerId) {
         evaluateAutoCloseDateFromActivity(acctIdByActivityOwnerId);
    } // evaluateAutoCloseDateFromActivityFuture
    
    // APR0135718: Added StageName and Status_Update_Date__c in the opptys query
    public static void evaluateAutoCloseDateFromActivity(Map<Id,Id> acctIdByActivityOwnerId){
        Opportunity[] opptys = [SELECT Id,Name,AccountId,OwnerId,Probability,RecordTypeId,RecordType.Name,OpportunityType__c,LeadSource
                                      ,JointAppointmentId__c,NSS_Source__c,Auto_Close_Date__c ,CreatedDate,Evaluate_Auto_Close__c
                                      ,EvaluateProductGroup__c,ProductGroupsSelected__c,StageName,Follow_Up_Date__c,Status_Update_Date__c, ProcessNotes__c
                                      ,ReferralLookup__c, ReferralLookup__r.ReferralJoin__c
                                FROM Opportunity 
                               WHERE Auto_Close_Date__c != null
                                 AND AccountId in:acctIdByActivityOwnerId.keySet() 
                                 AND OwnerId in:acctIdByActivityOwnerId.values()
                                 AND OpportunityType__c not in :excludeOppTypeSet
                                 AND LeadSource not in :excludeLeadSourceSet];
        checkOpportunityForExpirationEligibility(opptys,false);
    } // evaluateAutoCloseDateFromActivity
    
    public static Map<String,Integer> expirationDurationByRTName = new Map <String,Integer>();
    
    public class OppWrap {
       public OppWrap(Opportunity p_opp) {
          opp = p_opp;
       } // OppWrap
       public Opportunity opp;
       public Opportunity joinOpp;
       public Boolean isJointOpp() {
          Boolean isJoint = (opp != null && String.isNotBlank(opp.JointAppointmentId__c)
                            && joinOpp != null && String.isNotBlank(joinOpp.JointAppointmentId__c)
                            && opp.JointAppointmentId__c == joinOpp.JointAppointmentId__c);
          return isJoint;
       } // isJointOpp
        
       public Date activityDate=null;
        
       public void checkOpp(Opportunity checkOpp) {
          if (opp == null || opp.Id == checkOpp.Id) {
             opp = checkOpp;
          } else {
             joinOpp = checkOpp;
          }
       } // checkOpp
        
       public Boolean isInbound() {
          Boolean isInbound = (opp != null && String.isNotBlank(opp.NSS_Source__c) && opp.NSS_Source__c.startsWith('Inbound'));
          isInbound = isInbound || (joinOpp != null && String.isNotBlank(joinOpp.NSS_Source__c) && joinOpp.NSS_Source__c.startsWith('Inbound'));
          return isInbound;
       } // isInbound
        
       public void checkRefJoin(ReferralJoin__c refJoin, Set<Id> ownerIdSet) {
          // main opp should be payroll (mms or smb)
          // join opp should be the PAS one
          if (refJoin != null) {
             opp = (refJoin.Core_Referral__r != null && refJoin.Core_Referral__r.Selling_Opportunity__c != null ? refJoin.Core_Referral__r.Selling_Opportunity__r
                      : (refJoin.MMS_Referral__r != null && refJoin.MMS_Referral__r.Selling_Opportunity__c != null ? refJoin.MMS_Referral__r.Selling_Opportunity__r : opp));
             joinOpp = (refJoin.PAS_Referral__r != null && refJoin.PAS_Referral__r.Selling_Opportunity__c != null ? refJoin.PAS_Referral__r.Selling_Opportunity__r : joinOpp);
          } // if (refJoin != null
          if (opp != null && opp.OwnerId != null) {
             ownerIdSet.add(opp.OwnerId);
          }
          if (joinOpp != null && joinOpp.OwnerId != null) {
             ownerIdSet.add(joinOpp.OwnerId);
          }
          // make sure the join opp is eligible
          System.debug('checkRefJoin opp='+(opp != null)+' joinOpp='+(joinOpp != null));
          if (joinOpp != null && !oppAutoCloseEligible(joinOpp,opp)) {
             System.debug('checkRefJoin joinOpp='+joinOpp.Name+' is not eligible');
             joinOpp = null;
          }
       } // checkRefJoin
    } // class OppWrap
    
    //check based on record type whether we should evaluate auto close or not
    public static void checkOpportunityForExpirationEligibility(Opportunity[] opptys, Boolean isOppInsert){
        System.debug('checkOpportunityForExpirationEligibility opptys='+opptys.size());
        //Opportunity[] validOpptys = new Opportunity[]{};
        Opportunity[] invalidOpptys = new Opportunity[]{};
        OppWrap[] oppsToProcess = new OppWrap[]{};
        Map<Id,OppWrap> byJoinId = new Map<Id,OppWrap>();
        Map<Id,OppWrap> byAcctId = new Map<Id,OppWrap>();
        // get only the activity related to the opp owner(s)
        Set<Id> ownerIdSet = new Set<Id>();
        
        //Id[] jointIds = new Id[]{};
        //Map<Id,Opportunity> oppByAccountId = new Map<Id,Opportunity>();
        Datetime createdDateCheck = Datetime.now();
            
        for (Opportunity oppty:opptys) {
            RecordType__c rts = RecordTypeHelper.getRtSetting(oppty.RecordType.Name);
            Boolean isInbound = (String.isNotBlank(oppty.NSS_Source__c) && oppty.NSS_Source__c.startsWith('Inbound'));
            //APR0135718: Added Non Inbound No of days and Extend No of Days field check in below condition
            //only look at the extend date if there's already a value.
            System.debug('checkOpportunityForExpirationEligibility oppty='+oppty.Name+' rts='+(rts != null ? rts.Name : 'Not Found'));
            if (rts != null && ((rts.Non_Inbound_number_of_days__c != null || (isInbound && rts.Opportunity_Auto_Close_Duration__c != null)
                                      || (rts.Extend_Number_of_Days__c!=null && oppty.Auto_Close_Date__c != null))
                                || (rts.Auto_Close_Joint_Only__c && oppty.JointAppointmentId__c != null)
                                || (String.isNotBlank(rts.AutoCloseProdGroup__c) && oppty.EvaluateProductGroup__c && String.isNotBlank(oppty.ProductGroupsSelected__c)))) {
                System.debug('checkOpportunityForExpirationEligibility oppty='+oppty.Name+' in the If'+' accountId='+oppty.AccountId);
                if (oppty.AccountId != null) {
                   OppWrap oWrap = (byAcctId.containsKey(oppty.AccountId) ? byAcctId.get(oppty.AccountId) : new OppWrap(oppty));
                   oWrap.checkOpp(oppty);
                   byAcctId.put(oppty.AccountId, oWrap);
                   if (oppty.OwnerId != null) {
                      ownerIdSet.add(oppty.OwnerId);
                   }
                    
                   //validOpptys.add(oppty);
                   //oppByAccountId.put(oppty.AccountId, oppty);
                    
                   System.debug('checkOpportunityForExpirationEligibility oppty.ReferralLookup__c='+oppty.ReferralLookup__c+' ReferralJoin__c='+(oppty.ReferralLookup__c != null ? oppty.ReferralLookup__r.ReferralJoin__c : null));
                   if (oppty.ReferralLookup__c != null && oppty.ReferralLookup__r.ReferralJoin__c != null) {
                      //jointIds.add(oppty.ReferralLookup__r.ReferralJoin__c);                   
                      if (!byJoinId.containsKey(oppty.ReferralLookup__r.ReferralJoin__c )) {
                         byJoinId.put(oppty.ReferralLookup__r.ReferralJoin__c, oWrap);
                      }
                   }

                   // we only want to select activity greater than the created date, so find the oldest created date to limit activity selected
                   createdDateCheck = (oppty.CreatedDate < createdDateCheck ? oppty.CreatedDate : createdDateCheck);                   
                } // if (oppty.AccountId != null
                                    
            } else {
               // shouldn't get any in here because we pre-check now.
               System.debug('checkOpportunityForExpirationEligibility oppty='+oppty.Name+' in the Else');
               if (oppty.Auto_Close_Date__c != null) {
                  //if the opportunity has an auto close date but shouldn't be auto closed, clear the date
                  oppty.Auto_Close_Date__c = null;
                  oppty.Evaluate_Auto_Close__c = false;
                  invalidOpptys.add(oppty);
               }
            }
        } // for(Opportunity oppty:opptys
        System.debug('checkOpportunityForExpirationEligibility byAcctId='+byAcctId.size()+' byJoinId='+byJoinId.size());
        if(!invalidOpptys.isEmpty()){
            OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
            DMLHelper.performDML2(invalidOpptys, DMLHelper.DML_UPDATE, 'OpptyAutoCloseEvaluation', 'checkOpportunityForExpirationEligibility', 'clearing oppty close date', true);
            OpptyMethods.SKIP_OPPTY_TRIGGERS = false;
        }
        if (!byAcctId.isEmpty()) {
           evaluateAutoCloseDate(byAcctId, byJoinId, createdDateCheck, ownerIdSet, isOppInsert);
        }
    } // checkOpportunityForExpirationEligibility
    
    // do we only set the date initially on insert?
    public static Boolean onlySetOnInsert=(Label.OpptyAutoClose_OnlyOnInsert == 'Y');
    
    //evaluate auto close
    public static void evaluateAutoCloseDate(Map<Id,OppWrap> byAcctId, Map<Id,OppWrap> byJoinId, Datetime createdDateCheck, Set<Id> ownerIdSet, Boolean isOppInsert){
        Map<Id,Opportunity> oppUpdateMap = new Map<Id,Opportunity>();

        
        system.debug('evaluateAutoCloseDate byAcctId='+byAcctId.size()+' byJoinId='+byJoinId.size()+' ownerIdSet='+ownerIdSet.size()+' createdDateCheck='+createdDateCheck);
        // these checks don't need to be made on the insert of an opportunity because they won't exist yet. 
        if (!isOppInsert) {
            
        //joint appointment check is only applicable for certain record types
        String[] jointOppRecordTypes = new String[]{Label.RT_Oppty_ASO,Label.RT_Oppty_ASO_FSS,Label.PEO_Opportunity_Record_Type,
                                                    Label.PEO_Opportunity_FSS_Record_Type,Label.MMS_Opportunity_Record_Type,Label.MMS_Opportunity_DSA_Record_Type,
                                                    Label.PAY_Opportunity_Record_Type,Label.PAY_Opportunity_DSA_Record_Type};
        Map<Id,ReferralJoin__c> joinMap = (byJoinId.isEmpty() ? new Map <Id,ReferralJoin__c>() 
                                                   : new Map <Id,ReferralJoin__c>([SELECT Id
                                                                                ,PAS_Referral__r.Selling_Opportunity__c
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.Name
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.AccountId
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.OwnerId
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.Probability
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.RecordTypeId
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.RecordType.Name
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.OpportunityType__c
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.LeadSource
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.JointAppointmentId__c
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.NSS_Source__c
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.Auto_Close_Date__c
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.CreatedDate
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.IsClosed
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.Status_Update_Date__c
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.Evaluate_Auto_Close__c
                                                                                ,PAS_Referral__r.Selling_Opportunity__r.ProcessNotes__c
                                                                                ,MMS_Referral__r.Selling_Opportunity__c
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.Name
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.AccountId
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.OwnerId
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.Probability
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.RecordTypeId
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.RecordType.Name
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.OpportunityType__c
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.LeadSource
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.JointAppointmentId__c
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.NSS_Source__c
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.Auto_Close_Date__c
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.CreatedDate
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.IsClosed
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.Status_Update_Date__c
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.Evaluate_Auto_Close__c
                                                                                ,MMS_Referral__r.Selling_Opportunity__r.ProcessNotes__c
                                                                                ,Core_Referral__r.Selling_Opportunity__c
                                                                                ,Core_Referral__r.Selling_Opportunity__r.Name
                                                                                ,Core_Referral__r.Selling_Opportunity__r.AccountId
                                                                                ,Core_Referral__r.Selling_Opportunity__r.OwnerId
                                                                                ,Core_Referral__r.Selling_Opportunity__r.Probability
                                                                                ,Core_Referral__r.Selling_Opportunity__r.RecordTypeId
                                                                                ,Core_Referral__r.Selling_Opportunity__r.RecordType.Name
                                                                                ,Core_Referral__r.Selling_Opportunity__r.OpportunityType__c
                                                                                ,Core_Referral__r.Selling_Opportunity__r.LeadSource
                                                                                ,Core_Referral__r.Selling_Opportunity__r.JointAppointmentId__c
                                                                                ,Core_Referral__r.Selling_Opportunity__r.NSS_Source__c
                                                                                ,Core_Referral__r.Selling_Opportunity__r.Auto_Close_Date__c
                                                                                ,Core_Referral__r.Selling_Opportunity__r.CreatedDate
                                                                                ,Core_Referral__r.Selling_Opportunity__r.IsClosed
                                                                                ,Core_Referral__r.Selling_Opportunity__r.Status_Update_Date__c
                                                                                ,Core_Referral__r.Selling_Opportunity__r.Evaluate_Auto_Close__c
                                                                                ,Core_Referral__r.Selling_Opportunity__r.ProcessNotes__c
                                                                           FROM ReferralJoin__c WHERE Id in :byJoinId.keySet()]));
        // set the main opp and joined opp
        for (Id joinId : byJoinId.keySet()) {
           OppWrap oWrap = byJoinId.get(joinId);
           ReferralJoin__c refJoin = joinMap.get(joinId);
           System.debug('evaluateAutoCloseDate oWrap='+(oWrap != null)+' refJoin='+(refJoin != null));
           if (oWrap != null && refJoin != null) {
              oWrap.checkRefJoin(refJoin, ownerIdSet);
           }
        } // or (Id joinId

        //tasks returned should be sorted by most recent activity date first
        Task[] completedTasks = [SELECT Id,ActivityDate,AccountId,WhatId,OwnerId,WhoId 
                                   FROM Task 
                                  WHERE ActivityDate != null 
                                    AND AccountId in :byAcctId.keySet() 
                                    AND Status = 'Completed' 
                                    AND ActivityDate >= :createdDateCheck.date()
                                    AND OwnerId in :ownerIdSet
                                  ORDER BY ActivityDate DESC];
        for (Task tk: completedTasks){
            OppWrap oWrap = byAcctId.get(tk.AccountId);
            if (oWrap != null) {
               // keep track of the latest activity date
               if (oWrap.activityDate == null || oWrap.activityDate < tk.ActivityDate) {
                  oWrap.activityDate = tk.ActivityDate;
                  System.debug('evaluateAutoCloseDate taskActivityDate='+tk.ActivityDate);
               }
            } // if (oWrap != null
        } // for (Task tk: completedTasks
        Event[] completedEvents = [SELECT Id,ActivityDate,AccountId,WhatId,OwnerId,WhoId 
                                     FROM Event 
                                    WHERE ActivityDate!= null 
                                      AND AccountId in :byAcctId.keySet() 
                                      AND ActivityDate >= :createdDateCheck.date()
                                      AND OwnerId in :ownerIdSet
                                    ORDER BY ActivityDate DESC];
        for (Event ev: completedEvents){
            OppWrap oWrap = byAcctId.get(ev.AccountId);
            if (oWrap != null) {
               // keep track of the latest activity date
               if (oWrap.activityDate == null || oWrap.activityDate < ev.ActivityDate) {
                  oWrap.activityDate = ev.ActivityDate;
                  System.debug('evaluateAutoCloseDate evtActivityDate='+ev.ActivityDate);
               }
            } // if (oWrap != null
        } // for (Event ev: completedEvents
        } // if (!isOppInsert
        
        for (OppWrap oWrap : byAcctId.values()) {
           Opportunity updateOpp = new Opportunity(Id=oWrap.opp.Id, ProcessNotes__c=oWrap.opp.ProcessNotes__c);
           Opportunity joinOpp = (oWrap.joinOpp != null ? new Opportunity(Id=oWrap.joinOpp.Id, ProcessNotes__c=oWrap.joinOpp.ProcessNotes__c) : null);
           if (oWrap.opp != null && oWrap.opp.Evaluate_Auto_Close__c) {
              updateOpp.Evaluate_Auto_Close__c = false;
              oppUpdateMap.put(updateOpp.Id,updateOpp);
           }
           Boolean oppHasActivity = (oWrap.activityDate != null);
           Boolean isInbound = oWrap.isInbound();
           Boolean isOppEligible = oppAutoCloseEligible(oWrap.opp,oWrap.joinOpp);
           Boolean isJointOppEligible = (oWrap.isJointOpp() && oWrap.joinOpp != null && isOppEligible);
           System.debug('evaluateAutoCloseDate opp='+(oWrap.opp != null)+' oppHasActivity='+oppHasActivity+' Auto_Close_Date__c='+(oWrap.opp != null ? oWrap.opp.Auto_Close_Date__c : null));
           // if we're setting the date initially
           //if (oWrap.opp != null && isOppInsert && oWrap.opp.Auto_Close_Date__c == null) {
           if (oWrap.opp != null && (!onlySetOnInsert || isOppInsert) && oWrap.opp.Auto_Close_Date__c == null) {
              Integer expirationDuration = getExpirationDuration(oWrap.opp.RecordType.Name,oWrap.opp,isInbound);
              Integer jointExpirationDuration = (oWrap.joinOpp !=null ? getExpirationDuration(oWrap.joinOpp.RecordType.Name,oWrap.joinOpp,isInbound) : null);
              Integer maxDuration = ((expirationDuration != null && (jointExpirationDuration == null || expirationDuration >= jointExpirationDuration ))
                                        ? expirationDuration 
                                        : ((jointExpirationDuration != null && (expirationDuration == null || jointExpirationDuration > expirationDuration))
                                             ? jointExpirationDuration : null));
              System.debug('evaluateAutoCloseDate expirationDuration='+expirationDuration+' jointExpirationDuration='+jointExpirationDuration+' maxDuration='+maxDuration);
              if (maxDuration != null) {
                 Date closeDate = oWrap.opp.CreatedDate.date().addDays(maxDuration);
                 // if we're already past the close date, we're not going to set it. 
                 if (oWrap.opp != null && closeDate > Date.today()) {
                    StringHelper.addToProcessNotes(updateOpp,'primary opp expirationDuration='+expirationDuration+' jointExpirationDuration='+jointExpirationDuration+' maxDuration='+maxDuration);
                    updateOpp.Auto_Close_Date__c = oWrap.opp.CreatedDate.date().addDays(maxDuration);
                    oppUpdateMap.put(updateOpp.Id,updateOpp);
                 } 
                 if (isJointOppEligible && closeDate > Date.today()) {
                    StringHelper.addToProcessNotes(joinOpp,'joint opp expirationDuration='+expirationDuration+' jointExpirationDuration='+jointExpirationDuration+' maxDuration='+maxDuration);
                    joinOpp.Auto_Close_Date__c = oWrap.joinOpp.CreatedDate.date().addDays(maxDuration);
                    oppUpdateMap.put(joinOpp.Id,joinOpp);
                 } 
              }
              // we've processed the record, we can skip the rest of this loop
              continue;
           } // if (oWrap.opp
           
           Integer extendDuration = getExtendExpirationDuration(oWrap.opp.RecordType.Name, isInbound);
           Integer extendJoinDuration = (oWrap.joinOpp != null ? getExtendExpirationDuration(oWrap.joinOpp.RecordType.Name, isInbound) : null);
           Integer maxDuration = ((extendDuration != null && (extendJoinDuration == null || extendDuration >= extendJoinDuration ))
                                        ? extendDuration 
                                        : ((extendJoinDuration != null && (extendDuration == null || extendJoinDuration > extendDuration))
                                             ? extendJoinDuration : null));
            
           Date maxChangeDate = oWrap.activityDate;
           if (oWrap.opp != null && oWrap.opp.Status_Update_Date__c != null && (maxChangeDate == null || oWrap.opp.Status_Update_Date__c > maxChangeDate)) {
              //APR0167020
              if(oWrap.opp.StageName == Label.Future_Renewal_Status && oWrap.opp.Follow_Up_Date__c != null  ) {//'Future Renewal'
                   maxChangeDate = oWrap.opp.Follow_Up_Date__c;
                   maxDuration = Integer.valueOf(Label.Future_Renewal_Extend);//30
               } 
              else{ maxChangeDate = oWrap.opp.Status_Update_Date__c;}
           }
           if (isJointOppEligible && oWrap.joinOpp.Status_Update_Date__c != null && (maxChangeDate == null || oWrap.joinOpp.Status_Update_Date__c > maxChangeDate)) {
             //APR0167020
			if(oWrap.joinOpp.StageName == Label.Future_Renewal_Status && oWrap.joinOpp.Follow_Up_Date__c != null  ) {
                   maxChangeDate = oWrap.joinOpp.Follow_Up_Date__c;
                   maxDuration = Integer.valueOf(Label.Future_Renewal_Extend);//30
               }
               else { maxChangeDate = oWrap.joinOpp.Status_Update_Date__c;}  
           }
           System.debug('evaluateAutoCloseDate extendDuration='+extendDuration+' extendJoinDuration='+extendJoinDuration+' maxDuration='+maxDuration+' maxChangeDate='+maxChangeDate+' oWrap.opp='+(oWrap.opp != null));
           if (maxChangeDate != null && maxDuration != null) {
              Date newCloseDate = maxChangeDate.addDays(maxDuration);
              System.debug('evaluateAutoCloseDate newCloseDate='+newCloseDate+' oWrap.opp.Auto_Close_Date__c='+oWrap.opp.Auto_Close_Date__c);
              if (oWrap.opp != null && oWrap.opp.Auto_Close_Date__c != null && newCloseDate > oWrap.opp.Auto_Close_Date__c) {
                 StringHelper.addToProcessNotes(updateOpp,'primary opp extendDuration='+extendDuration+' extendJoinDuration='+extendJoinDuration+' maxDuration='+maxDuration+' maxChangeDate='+maxChangeDate);
                 updateOpp.Auto_Close_Date__c = newCloseDate;
                 oppUpdateMap.put(updateOpp.Id,updateOpp);
              }
              if (isJointOppEligible && (oWrap.joinOpp.Auto_Close_Date__c == null || newCloseDate > oWrap.joinOpp.Auto_Close_Date__c)) {
                 StringHelper.addToProcessNotes(joinOpp,'joint opp extendDuration='+extendDuration+' extendJoinDuration='+extendJoinDuration+' maxDuration='+maxDuration+' maxChangeDate='+maxChangeDate);
                 joinOpp.Auto_Close_Date__c = newCloseDate;
                 oppUpdateMap.put(joinOpp.Id,joinOpp);
              }
           } else if (oWrap.opp != null && oWrap.opp.Auto_Close_Date__c != null && joinOpp != null && oWrap.joinOpp.Auto_Close_Date__c == null) {
              // update the join opp Auto Close Date to match the main opp
              StringHelper.addToProcessNotes(joinOpp,'joint opp updated to match primary '+oWrap.opp.Auto_Close_Date__c);
              joinOpp.Auto_Close_Date__c = oWrap.opp.Auto_Close_Date__c;
              oppUpdateMap.put(joinOpp.Id,joinOpp);
           }
        } // for (OppWrap oWrap : byAcctId.values

        if(!oppUpdateMap.isEmpty()){
            OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
            DMLHelper.performDML2(oppUpdateMap.values(), DMLHelper.DML_UPDATE, 'OpptyAutoCloseEvaluation', 'evaluateAutoCloseDate', 'updating oppty exp dates', true);
            OpptyMethods.SKIP_OPPTY_TRIGGERS = false;
            //update oppUpdateMap.values();
        }
    }//evaluateAutoCloseDate
    
    public static Boolean oppAutoCloseEligible(Opportunity oppty,Opportunity jointOpp) {
        RecordType__c rts = RecordTypeHelper.getRtSetting(oppty.RecordType.Name);
        
        Integer rtsProbability = 0;
        if (rts != null) {
           if (String.isNotBlank(rts.AutoCloseProdGroup__c)) {
              if (oppty.EvaluateProductGroup__c && String.isNotBlank(oppty.ProductGroupsSelected__c) && rts.Opportunity_Auto_Close_Max_Probability__c!=null) {
                 // if the prod group is set for a record type, we're only going to look at the EvaluateProductGroup__c and ProductGroupsSelected__c fields 
                 String[] checkProdGrps = rts.AutoCloseProdGroup__c.split(',');
                 for (String checkProdGrp : checkProdGrps) {
                    if (oppty.ProductGroupsSelected__c.contains(checkProdGrp)) {
                       rtsProbability = Integer.valueOf(rts.Opportunity_Auto_Close_Max_Probability__c);
                       break;
                    }
                 } // for (String checkProdGrp : checkProdGrps
              } // if (String.isNotBlank(oppty.ProductGroupsSelected__c)
           } else if (rts.Opportunity_Auto_Close_Max_Probability__c != null) {
              rtsProbability = Integer.valueOf(rts.Opportunity_Auto_Close_Max_Probability__c);
           } else if (rts.Opportunity_Auto_Close_Max_Probability__c == null && jointOpp != null) {
              RecordType__c rtsJoint = RecordTypeHelper.getRtSetting(jointOpp.RecordType.Name);
              if (rtsJoint!= null && rtsJoint.Opportunity_Auto_Close_Max_Probability__c != null){
                 rtsProbability = Integer.valueOf(rtsJoint.Opportunity_Auto_Close_Max_Probability__c);
              }
           }

        } // if (rts != null

        system.debug('oppAutoCloseEligible rts='+(rts!=null)+' rtsProbability='+rtsProbability+ ' oppty.Probability='+oppty.Probability+' oppty.NSS_Source__c='+oppty.NSS_Source__c+
                    ' oppty.OpportunityType__c='+oppty.OpportunityType__c);
        
        return ((rtsProbability > 0 && oppty.Probability > 0 && Integer.valueOf(oppty.Probability) < rtsProbability));
    } // oppAutoCloseEligible
    
    //leverage the record type list custom setting.  if the duration isn't set per record type, that record type shouldn't auto close
    public static Integer getExpirationDuration(String recordTypeName,Opportunity oppty,Boolean isInbound){
        System.debug('getExpirationDuration recordTypeName='+recordTypeName+' isInbound='+isInbound);
        
        Integer duration;
        
        RecordType__c rts = RecordTypeHelper.getRtSetting(recordTypeName);
        if (rts != null) {
           duration = ((isInbound && rts.Opportunity_Auto_Close_Duration__c != null) ? Integer.valueOf(rts.Opportunity_Auto_Close_Duration__c)
                         : (rts.Non_Inbound_number_of_days__c != null ? Integer.valueOf(rts.Non_Inbound_number_of_days__c) : null));
            /*APR0164336: Update Auto close date as 180 for lead source as Acqisition*/
            if(duration!=null){
                 duration = (oppty.LeadSource== 'Acquisition' ? Integer.valueOf(Label.Auto_Close_Date_Duration): duration);
            }
           
        }
        return duration;
    } // getExpirationDuration
    
    /*APR0135718: Record type list custom setting. If the Extend Number of Days isn't set per record type, that record type shouldn't extend the auto close date */
     public static Integer getExtendExpirationDuration(String recordTypeName, Boolean isInbound){
        Integer duration=null;
        RecordType__c rts = RecordTypeHelper.getRtSetting(recordTypeName);
        if (rts != null) {
           if (isInbound && rts.ExtendDaysInbound__c != null) {
              duration = Integer.valueOf(rts.ExtendDaysInbound__c);
           } else if (rts.Extend_Number_of_Days__c!= null) {
              duration = Integer.valueOf(rts.Extend_Number_of_Days__c);

           }
        } // if (rts != null
        system.debug('getExtendExpirationDuration duration='+duration+' isInbound='+isInbound+' recordTypeName='+recordTypeName);
        
        return duration;
    } //extendExpirationDuration

} // class OpptyAutoCloseEvaluation