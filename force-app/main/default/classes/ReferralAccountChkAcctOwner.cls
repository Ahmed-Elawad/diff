/** Check the owner of the account if an attribute on the referral account changes.

* History
* -------
05/17/2018 Dan Carmen       Created
06/14/2018 Dan Carmen       Fix for the order of ownership
01/24/2019 Dan Carmen       Add criteria for number of employees < 50 for everything except Strategic Accounts
02/28/2019 Dan Carmen       Only apply under 50 criteria to current clients
05/12/2020 Jake Hinds      Referral Account Team
07/01/2020 Dan Carmen       Add fields for Oasis owner fields.
12/07/2020 Jake Hinds    Small changes to try and troubleshoot non-processing.  Changing to without sharing
01/19/2020 Jake Hinds    Adding tracking variables for debugging batch
02/22/2022 Carrie Marciano  Added BenAdmin Holdout fields
03/04/2022 Dan Carmen       Clean up some ownership logic
05/24/2022 Reetesh Pandey     Account Team Member sharing
11/11/2022 Jaipal            Added new methods to mimic the same Evaluate Ref Account Owner functionality from the Account to the Lead
02/14/2023 Eric Porter       Change employeee threshhold to a label
03/01/2023 Dan Carmen        Clean up check to see if it needs to evaluate referral source ownership
03/14/2023 Dan Carmen        Fix for If statment for CPAs to always check employee count
07/04/2023 Shilpa            APR0152866: Updated method 'getReferralSource' to run ownership logic only if Account's Strategic Account Partner's Referral Source Sub Type is not Field
07/25/2023 Eric Porter       added new update to CPA Ownership missing field in query
09/08/2023 Dan Carmen        Do not run the referral ownership immediately if running as sfdc data.

*/
public without sharing class ReferralAccountChkAcctOwner implements TriggerInterfaceC {
    
   public static final String CLASSNAME='ReferralAccountChkAcctOwner';
    
   // check all of the records as a group before cycling through them individually
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs(CLASSNAME, p_recs,oldMap, isBefore, isAfter, isDelete, null, null);
      System.debug('ReferralAccountChkAcctOwner.triggerCheckAllFirst p_recs='+(p_recs != null ? p_recs.size() : -1)+' recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
      if (recs == null || recs.isEmpty()) {
         return;
      }
      if (TriggerMethods.objType == Account.sObjectType) {
         if (isBefore) {
            // check to see if any of the referral sources have changed. If they did, set the EvaluateRefAcctOwner__c flag
            checkAccountReferralSources((Account[])recs, (Map<Id,Account>)oldMap);
         }
         // this has to be done in the after trigger so we have the ids on inserts
         if (isAfter) {
            UserHelper.setRunningUserAttributes();
            if (!UserHelper.runningUserIsSfdcData) {
               Id[] acctIds = new Id[]{};
               for (Account acct : (Account[])recs) {
                  System.debug('ReferralAccountChkAcctOwner acct.EvaluateRefAcctOwner__c='+acct.EvaluateRefAcctOwner__c);
                  if (acct.EvaluateRefAcctOwner__c) {
                     acctIds.add(acct.Id);
                  }
               } // for (Account acct : (Account[])recs
               if (!acctIds.isEmpty()) {
                  // check the ownership of the referral sources for the accounts
                  prepareCheckRfrlSrcOwnership(acctIds);
               }
            } // if (!UserHelper.runningUserIsSfdcData
         }
      } // if (TriggerMethods.objType == Account.sObjectType
       if (TriggerMethods.objType == Lead.sObjectType) {
         if (isBefore) {
            // check to see if any of the referral sources have changed. If they did, set the EvaluateRefAcctOwner__c flag
            //Map<Id,Lead> oldMap1=(Map<Id,Lead>)oldMap;
            //checkAccountReferralSources(null, null, (Lead[])recs, (Map<Id,Lead>) oldMap1);
            checkAccountReferralSources((Lead[])recs, (Map<Id,Lead>)oldMap);
         }
         // this has to be done in the after trigger so we have the ids on inserts
         if (isAfter) {
            Id[] leadIds = new Id[]{};
            for (Lead lead : (Lead[])recs) {
               System.debug('ReferralAccountChkAcctOwner lead.EvaluateRefAcctOwner__c='+lead.EvaluateRefAcctOwner__c);
               if (lead.EvaluateRefAcctOwner__c) {
                  leadIds.add(lead.Id);
               }
            } // for (Lead lead :(Lead[])recs)
            if (!leadIds.isEmpty()) {
               // check the ownership of the referral sources for the accounts
               prepareCheckRfrlSrcOwnership(leadIds);
            }
         }
      } // if (TriggerMethods.objType == Lead.sObjectType
        
      if (TriggerMethods.objType == Referral_Account__c.sObjectType) {
         // if these are referral accounts, check to see if the dedicated reps are changed to add to batch
         if (isBefore) {
            checkReferralAccountsBefore((Referral_Account__c[])recs, (Map<Id,Referral_Account__c>)oldMap);
         }
      } // if (TriggerMethods.objType == Referral_Account__c.sObjectType
        
   } // triggerCheckAllFirst
    
    public static void checkReferralAccountsBefore(Referral_Account__c[] refAccts, Map<Id,Referral_Account__c> oldMap) {
        System.debug('checkReferralAccountsBefore refAccts='+refAccts.size());
        for (Referral_Account__c refAcct : refAccts) {
            System.debug('ReferralAccountChkAcctOwner checkReferralAccountsBefore refAcct.RecordTypeId Start ::'+refAcct.RecordTypeId );
            Referral_Account__c oldRefAcct = (oldMap != null ? (Referral_Account__c)oldMap.get(refAcct.Id) : null);
            // if the dedicated rep changes at all re-evaluate the account owner field (dedicated rep could have been removed or changed)
            if ((oldRefAcct == null && refAcct.DedicatedRep__c != null) 
                || (oldRefAcct != null && (refAcct.DedicatedRep__c != oldRefAcct.DedicatedRep__c || refAcct.ReferralSourceSubType__c!=oldRefAcct.ReferralSourceSubType__c))) {
                    // set this flag to true. The batch job will look for this flag when it runs. 
                    refAcct.DedicatedRepChanged__c = true;
                    StringHelper.addToProcessNotes(refAcct,'Set Dedicated Rep Changed to true');
                }
            System.debug('ReferralAccountChkAcctOwner checkReferralAccountsBefore End ::'+refAcct.RecordTypeId );
        } // for (Referral_Account__c rec
        
        
    } // checkReferralAccountsBefore
    
    // If the user trying to populate the Dedicated Rep field is from more than one location (CPA/Bank/Strategic Rep) 
    // then it will be set in the following order: Strategic, CPA, Bank, Independent Agent, Broker
    public static String HOLD_OUT_BANK='Bank Centric Team';
    public static String HOLD_OUT_CPA='CPA Centric Team';
    public static String HOLD_OUT_SA='Strategic Account Team';
    public static String HOLD_OUT_IA='IA Centric Team';
    public static String HOLD_OUT_BROKER='Financial Advisor Team';
    public static String HOLD_OUT_CENTRIC='Centric Team';
    
    public static Set<String> HOLD_OUT_SET = new Set<String>{HOLD_OUT_BANK,HOLD_OUT_CPA,HOLD_OUT_SA,HOLD_OUT_IA,HOLD_OUT_BROKER};
    // list, in order of priority, of the hold out reasons
    public static String[] HOLD_OUT_LIST=new String[]{HOLD_OUT_SA,HOLD_OUT_CPA,HOLD_OUT_BANK,HOLD_OUT_IA,HOLD_OUT_BROKER};
            
    public static Integer ownerSet=0;
    public static Integer holdoutSet=0;
    public static Integer holdoutRemoved=0;
    public static Integer accountsCorrectlySet=0;
    public static Integer leadsCorrectlySet=0;
    public static Id[] unableToFindHoldout = new Id[]{};
    public static Id[] unableToFindNewOwner = new Id[]{};
    public static Set<Id> notEligibleForDedicatedRep = new Set<Id>();
    
    public static Boolean BYPASS_CURRENT_CLIENT=false;
    
    public static Integer EMP_THRESHHOLD = Integer.valueOf(Label.ReferralAcctChckEmpLimit);
    
   public static Boolean getReferralSource(SObject rec,AcctRATWrap[] wraps, Id[] refAcctIds) {
    Boolean found = false;
    if(rec.getSObjectType() == Account.sObjectType){
      Account acct = (Account)rec;
      System.debug('getReferralSource acct='+acct.Name+' acct.CurrentClient__c='+acct.CurrentClient__c+' BYPASS_CURRENT_CLIENT='+BYPASS_CURRENT_CLIENT);
      AcctRATWrap wrap = new AcctRATWrap();
      wrap.obj = rec;
      wraps.add(wrap);
      if(acct.Referral_National_Account__c!=null && acct.Referral_National_Account__r.ReferralSourceSubType__c!=null && Label.RATOwnership_Exclude_Referral_Subtype.contains(acct.Referral_National_Account__r.ReferralSourceSubType__c)){
            wrap.obj.put('EvaluateRefAcctOwner__c',false);
            if(acct.Hold_Out__c && acct.Permanent_Hold_Out_Description__c=='Strategic Account Team')
                wrap.obj.put('Hold_Out__c',false);
            else
              wrap.obj.put('Use_Zip_Assignment_Rules__c',true);  
            wrap.recUpdated=true;
          StringHelper.addToProcessNotes(wrap.obj, 'Resetting Evaluate Ref Acct Owner to false and evaluating territory ownership');
      }
      else{
          found = checkRefSrc(wrap, HOLD_OUT_SA,null,acct.Referral_National_Account__r);
          // if we don't find anything on the Strategic account, look at the other referral sources.
          if (!found) {
             Boolean empCriteriaMet = (acct.NumberOfEmployees == null || acct.NumberOfEmployees < EMP_THRESHHOLD);
             Boolean curClient = ((acct.CurrentClient__c || BYPASS_CURRENT_CLIENT)&& acct.Type != 'Prospect');
             Boolean lostClient = (!acct.CurrentClient__c && (acct.Type == 'Lost Client' || acct.Lost_Date__c != null));
             //Opportunity opp = (!acct.Opportunities.isEmpty() ? acct.Opportunities[0] : null);
             //Boolean hasPayrollOpp = (opp != null && opp.IsWon && opp.IsClosed 
             //                           && opp.Owner.Sales_Division__c.contains('SMB') && opp.Owner.Sales_Division__c.contains('Channel') && opp.Owner.IsActive);
             System.debug('getReferralSource found='+found+' curClient='+curClient+' lostClient='+lostClient+' empCriteriaMet='+empCriteriaMet);
             // *** ECP APR0152868 fix to allow all reps to populate for all clients not just 0-19 clients
             // APR0155112 for regular accountant firms.
             Boolean isStrategicAccountant = (acct.CPA_Name_Ref__r != null && acct.CPA_Name_Ref__r.Referral_Account__r.Referral_Source_Business_Type__c =='Strategic Accountant Firm');
             if ((isStrategicAccountant || empCriteriaMet) && (curClient || lostClient)) {
                found = checkRefSrc(wrap,HOLD_OUT_CPA,acct.CPA_Name_Ref__r,null);
             }

             if (!found && curClient && empCriteriaMet) {
                found = (found || checkRefSrc(wrap,HOLD_OUT_BANK,acct.Banker_Name_Ref__r,null));
                found = (found || checkRefSrc(wrap,HOLD_OUT_BROKER,acct.Broker_Name_Ref__r,null));
                found = (found || checkRefSrc(wrap,HOLD_OUT_IA,acct.Insurance_Broker_Name_Ref__r,null));
    
             } // if (refSrcId == null &&
          } // if (refSrcId == null
          System.debug('getReferralSource after if found='+found);
          if (found) {
              refAcctIds.add(wrap.refAcctId);
              //refSourceIdByAccountId.put(acct.Id,refSrcId); 
          } else {
             notEligibleForDedicatedRep.add(acct.Id);
          }
      }
        //return found;
    }
    else if(rec.getSObjectType() == Lead.sObjectType){
        Lead lead = (Lead)rec;
        System.debug('getReferralSource1 lead='+lead.Name);
          AcctRATWrap wrap1 = new AcctRATWrap();
          wrap1.obj = rec;
          wraps.add(wrap1);
          found = checkRefSrc(wrap1, HOLD_OUT_SA,null, lead.Referral_National_Account__r);
          // if we don't find anything on the Strategic account, look at the other referral sources.
          if (!found) {
                found = checkRefSrc(wrap1 ,HOLD_OUT_CENTRIC,lead.Referral_Contact__r,null);
             }
          System.debug('getReferralSource after if found='+found);
          if (found) {
              refAcctIds.add(wrap1.refAcctId);
              //refSourceIdByAccountId.put(acct.Id,refSrcId); 
          }
          //return found;
        }
    return found;
   } // getReferralSource   
    
   public static Boolean checkRefSrc(AcctRATWrap wrap, String holdOutType, Referral_Contact__c refCtct, Referral_Account__c refAcct) {
      Id refAcctId = null;
      if (refCtct != null && refCtct.Referral_Account__r != null) {
         refAcct = refCtct.Referral_Account__r;
      }
      if (refAcct != null && refAcct.Has_Referral_Account_Team__c) {
         System.debug('checkRefSrc holdOutType='+holdOutType+' found on refAcct');
         refAcctId = refAcct.Id;
      } else if (refAcct != null && refAcct.Parent_Referral_Account__c != null && refAcct.Parent_Referral_Account__r.Has_Referral_Account_Team__c) {
         System.debug('checkRefSrc holdOutType='+holdOutType+' found on refAcct Parent');
         refAcctId = refAcct.Parent_Referral_Account__c;
      }
      if (refAcctId != null && wrap!= null) {
         wrap.refAcctId = refAcctId;
         wrap.holdOutReason = holdOutType;
      }
      System.debug('checkRefSrc holdOutType='+holdOutType+' refAcctId='+refAcctId);
      return (refAcctId != null);
   } // checkRefSrc
    
   public static AcctRATWrap checkAccountOwners(AcctRATWrap wrap, Map<String,Referral_Account_Team__c> ratMap) {
      system.debug('checkAccountOwners acct='+wrap.obj.get('Name'));
      String holdOutFieldName;
       AccountTeamMember atm1;
      if ((Boolean)wrap.obj.get('EvaluateRefAcctOwner__c')) {
         // reset the flag
         wrap.obj.put('EvaluateRefAcctOwner__c',false);
         wrap.recUpdated=true;
         StringHelper.addToProcessNotes(wrap.obj, 'Resetting Evaluate Ref Acct Owner to false');
      }
       Map<String,AccountTeamMember> atmMap = new Map<String,AccountTeamMember>();
       if(wrap.obj.getSObjectType() == Account.sObjectType){
       Account acct = (Account)wrap.obj;
      // get the existing team members
       for (AccountTeamMember atm : acct.AccountTeamMembers) {
         atmMap.put(atm.TeamMemberRole,atm);
      }
       }
      Set<String> holdOutsChecked = new Set<String>();
      // check the referral account teams first
      if (ratMap != null) {
         for (String salesOrg : ratMap.keySet()) {
            Referral_Account_Team__c rat = ratMap.get(salesOrg);
            HoldOut_ExpirationDates__c hod = HoldOut_ExpirationDates__c.getInstance(salesOrg);
            holdOutFieldName = wrap.obj.getSObjectType() == Account.sObjectType ? hod.Account_Hold_Out__c : hod.Lead_Hold_Out__c;
            if (String.isNotBlank(holdOutFieldName) && rat != null && !holdOutsChecked.contains(holdOutFieldName)) {
               holdOutsChecked.add(holdOutFieldName);
               if(wrap.obj.getSObjectType() == Account.sObjectType){
                 atm1 = (String.isNotBlank(hod.AccountTeamRole__c) ? atmMap.get(hod.AccountTeamRole__c) : null);
               }
               checkAccount(wrap, hod, rat, atm1);
            }
         } // for (String salesOrg : ratMap.keySet
      } // if (ratMap != null
       
      // cycle through everything else to remove holdouts if necessary
      for (HoldOut_ExpirationDates__c hod : HoldOut_ExpirationDates__c.getAll().values()) {
         holdOutFieldName = wrap.obj.getSObjectType() == Account.sObjectType ? hod.Account_Hold_Out__c : hod.Lead_Hold_Out__c;
         Referral_Account_Team__c rat = (ratMap != null ? ratMap.get(hod.Name) : null);
         // if we haven't checked the field or we have a Referral Account Team member for it.
         if (String.isNotBlank(holdOutFieldName) && !holdOutsChecked.contains(holdOutFieldName)) {
            holdOutsChecked.add(holdOutFieldName);
            if(wrap.obj.getSObjectType() == Account.sObjectType){
                 atm1 = (String.isNotBlank(hod.AccountTeamRole__c) ? atmMap.get(hod.AccountTeamRole__c) : null);
            }
            checkAccount(wrap, hod, rat, atm1);
         }
         
      } // for (HoldOut_ExpirationDates__c hod

        return wrap;
   } // checkAccountOwners
    
    
   // if there is currently a hold out with one of these reasons on the account and we don't find one anymore (it was removed)
   //      update the account without the holdout.
   // if there is currently a hold out, but it isn't one of these types, do nothing with the record.
   // if there is currently a hold out with an expiration date - we do nothing with the record 
   // if there is currently a hold out, and the reason matches, and the owner is different, update the owner, leave the holdout. 
   // if there is currently a hold out, and the reason is lower in priority, update to the new holdout reason with the new owner.
   // if there isn't a hold out, set it with the new reason.
   public static void checkAccount(AcctRATWrap wrap, HoldOut_ExpirationDates__c hod, Referral_Account_Team__c rat, AccountTeamMember atm) {
       String holdOutFldName;
       String holdOutReasonFld;
       String holdOutDateFld;
       String ownerFld;
      if (String.isNotBlank(hod.Account_Hold_Out__c) && String.isNotBlank(hod.Account_Hold_Out_Date__c) && String.isNotBlank(hod.HoldOutReasonFld__c)) {
         if(wrap.obj.getSObjectType() == Account.sObjectType){
            holdOutFldName = hod.Account_Hold_Out__c;
            holdOutReasonFld = hod.HoldOutReasonFld__c;
            holdOutDateFld = hod.Account_Hold_Out_Date__c;
            ownerFld = hod.Account_Owner__c;
         }
         else if(wrap.obj.getSObjectType() == Lead.sObjectType){
            holdOutFldName = hod.Lead_Hold_Out__c;
            holdOutReasonFld = hod.Lead_Hold_Out_Reason_Fld__c;
            holdOutDateFld = hod.Lead_Hold_Out_Date__c;
            ownerFld = hod.Lead_Owner__c;
         }
         Boolean holdOut = (Boolean)wrap.obj.get(holdOutFldName);
         Date holdOutDate = (Date)wrap.obj.get(holdOutDateFld);
         String holdOutReason = (String)wrap.obj.get(holdOutReasonFld);
         Boolean curReasonIsRefSrc = (String.isNotBlank(holdOutReason) && HOLD_OUT_SET.contains(holdOutReason));
         Boolean hasAcctOwnerFld = String.isNotBlank(ownerFld);
         Id acctOwner = (hasAcctOwnerFld ? (Id)wrap.obj.get(ownerFld) : null);
         Integer curHoPriority = getHoldoutPriority(holdOutReason, holdOutDate != null);
         Integer newHoPriority = getHoldoutPriority(wrap.holdOutReason, false);
          
         System.debug('checkAccount acct='+wrap.obj.get('Name')+' holdOut='+holdOut+' holdOutReason='+holdOutReason+' curReasonIsRefSrc='+curReasonIsRefSrc);
          
         // if there is a holdout reason but no rat
         
         // if there isn't a holdout reason from a referral source, or we don't have a rat for this field (no ownership), and there is a referral source hold out, remove it.
         if (holdOut && (String.isBlank(wrap.holdOutReason) || rat == null) && curReasonIsRefSrc) {
            wrap.obj.put(holdOutFldName,false);
            wrap.obj.put(holdOutDateFld,null);
            wrap.obj.put(holdOutReasonFld,null);
            StringHelper.addToProcessNotes(wrap.obj, 'Removed '+holdOutFldName+' with Reason '+holdOutReason+' due to no Referral Source holdout');
            if (atm != null) {
               wrap.atmDelete.add(atm);
            }
            wrap.recUpdated=true;
            holdoutRemoved++;
         } else if (rat != null && String.isNotBlank(wrap.holdOutReason) && (curReasonIsRefSrc || !holdOut)) {
            // if there's a referral source hold out reason and their isn't a hold out or the current reason is also a referral source
            System.debug('checkAccount trying to set holdout');
            // if the reason is different and the new one has a higher priority, update it
            if (wrap.holdOutReason != holdOutReason && newHoPriority > curHoPriority) {
               wrap.obj.put(holdOutReasonFld,wrap.holdOutReason);
               // make sure the hold out is set. 
               wrap.obj.put(holdOutFldName,true);
               StringHelper.addToProcessNotes(wrap.obj, 'Changed '+holdOutReasonFld+' to '+wrap.holdOutReason);
               // update this so it will fall into the next 
               holdOutReason = wrap.holdOutReason;
               wrap.recUpdated=true;
               addToCountMap(wrap.holdOutReason);
            }
            // if its the same reason, make sure the owner is the same
            System.debug('checkAccount wrap.holdOutReason='+wrap.holdOutReason+' holdOutReason='+holdOutReason);
            if (wrap.holdOutReason == holdOutReason) {
               System.debug('checkAccount acctOwner='+acctOwner+' rat.Team_Member_Name__c='+rat.Team_Member_Name__c);
               if (hasAcctOwnerFld && acctOwner != rat.Team_Member_Name__c) {
                  wrap.obj.put(ownerFld, rat.Team_Member_Name__c);
                  wrap.recUpdated=true;
               }
               if(wrap.obj.getSObjectType() == Account.sObjectType){
                   // if there's a team member
                   if (String.isNotBlank(hod.AccountTeamRole__c)) {
                      // if there's an existing team member and the users don't match up
                      if (atm != null && atm.UserId != rat.Team_Member_Name__c) {   
                         // delete the current one, create a new one
                         wrap.atmDelete.add(atm);
                         atm = null;
                      }
                      if (atm == null) {
                         atm = new AccountTeamMember(AccountId=wrap.obj.Id, TeamMemberRole = hod.AccountTeamRole__c,UserId=rat.Team_Member_Name__c,AccountAccessLevel='Edit', ContactAccessLevel='Edit',OpportunityAccessLevel='Read');
                         wrap.atmInsert.add(atm);
                      }
                   } // if (String.isNotBlank(hod.AccountTeamRole__c
               }
            } // if (wrap.holdOutReason == holdOutReason
         } // if (holdOut &&
          
      } // if (String.isNotBlank(hod.Account_Hold_Out__c
   } // checkAccount
    
    
    public static Map<String,Integer> holdoutReasonCountMap = new Map<String,Integer>();
    
    public static void addToCountMap(String holdoutReason) {
        holdoutSet++;
        Integer curCount = (holdoutReasonCountMap.containsKey(holdoutReason) ? holdoutReasonCountMap.get(holdoutReason) : 0);
        // increment the count
        curCount++;
        holdoutReasonCountMap.put(holdoutReason,curCount);
    } // addToCountMap
    
    // higher number is a higher priority (this is the one we'll use first)
    public static Integer getHoldoutPriority(String reasonToCheck, Boolean hasDate) {
        // if the reason is blank and no expiration we'll set it to a low priority
        // if there is a date we assume there is a holdout, and we won't overwrite this holdout.
        Integer priority=(hasDate ? HOLD_OUT_LIST.size()+1 : 0);
        // it will only be non-zero if there's a date on it.
        if (priority == 0 && String.isNotBlank(reasonToCheck)) {
            // if it's an unrecognized permanent holdout, we won't change it so set it to a high priority 
            //               (1 larger than the size of the possible choices )
            // if it finds a match, it will overwrite this value
            priority = HOLD_OUT_LIST.size()+1;
            for (Integer cnt=0; cnt<HOLD_OUT_LIST.size(); cnt++) {
                if (reasonToCheck == HOLD_OUT_LIST[cnt]) {
                    // if the list size is 4, and this is the first element (0), priority would be 4-0=4
                    // if this is the second element, priority would be 4-1=3
                    priority = HOLD_OUT_LIST.size()-cnt;
                    break;
                }
            } // for (Integer cnt=0; cnt<HOLD_OUT_LIST.size()
        } // if (String.isNotBlank(reasonToCheck
        return priority;
    } // getHoldoutPriority
    
   // look if any of the linked referral sources change. If they do, mark it to evaluate the ownership of the account.
    public static void checkAccountReferralSources(SObject[] recs, Map<Id,SObject> oldMap)   {
       system.debug('checkAccountReferralSources recs size: '+recs.size());
       for (SObject rec : recs) {
         String strName = (rec.getSObjectType()== Account.sObjectType ? (String)rec.get('Name') : (String)rec.get('FirstName')+ (String)rec.get('LastName'));
         SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         system.debug('checkAccountReferralSources strName='+strName+' oldRec='+(oldRec != null));
         Boolean evaluateRefSource = ((Boolean)rec.get('EvaluateRefAcctOwner__c') || checkAccountReferralSources(rec, oldRec));
         if (evaluateRefSource && rec != null) {
            System.debug('Setting EvaluateRefAcctOwner to be true. rec: '+rec);
            rec.put('EvaluateRefAcctOwner__c', true);
            StringHelper.addToProcessNotes(rec, 'Referral Source changed-set Evaluate Ref Acct Owner to true for '+strName);
         }
      } // for (SObject rec : recs
   } // checkAccountReferralSources
    
   public static Boolean checkAccountReferralSources(SObject rec, SObject oldRec) {
      Boolean evaluateRefSrc= false;
      if(rec.getSObjectType() == Account.sObjectType){ 
          Account acct = (Account)rec;
          Account oldAcct = (Account)oldRec;
          Boolean hasRefSource = (acct.Banker_Name_Ref__c != null
                         || acct.CPA_Name_Ref__c != null
                         || acct.Insurance_Broker_Name_Ref__c != null
                         || acct.Broker_Name_Ref__c != null
                         || acct.Referral_National_Account__c != null);
          Boolean refSourceChanged = (oldAcct == null && hasRefSource)
                 || (oldAcct != null &&
                        (acct.Banker_Name_Ref__c != oldAcct.Banker_Name_Ref__c
                         || acct.CPA_Name_Ref__c != oldAcct.CPA_Name_Ref__c
                         || acct.Insurance_Broker_Name_Ref__c != oldAcct.Insurance_Broker_Name_Ref__c
                         || acct.Broker_Name_Ref__c != oldAcct.Broker_Name_Ref__c
                         || acct.Referral_National_Account__c != oldAcct.Referral_National_Account__c)
                 );
          Boolean crossEmpThreshold = (oldAcct != null && acct.NumberOfEmployees != null
                                       && ((acct.NumberOfEmployees >= EMP_THRESHHOLD && oldAcct.NumberOfEmployees < EMP_THRESHHOLD)
                                           || (acct.NumberOfEmployees < EMP_THRESHHOLD && oldAcct.NumberOfEmployees >= EMP_THRESHHOLD)));
          Boolean curClientChanged = (oldAcct != null && acct.CurrentClient__c != oldAcct.CurrentClient__c);
          System.debug('checkAccountReferralSources hasRefSource='+hasRefSource+' refSourceChanged='+refSourceChanged+' crossEmpThreshold='+crossEmpThreshold+' curClientChanged='+curClientChanged);
          if ((hasRefSource && (curClientChanged || oldAcct == null || crossEmpThreshold))
                   || refSourceChanged) {
             evaluateRefSrc = true;
          } // if ((oldAcct == 
      } else if(rec.getSObjectType() == Lead.sObjectType){
        Lead lead = (Lead)rec;
        Lead oldLead = (Lead)oldRec;
        if ((lead!= null && oldLead == null &&  (lead.Referral_National_Account__c != null || lead.Referral_Contact__c != null)) 
            || (oldLead != null && (lead.Referral_National_Account__c != oldLead.Referral_National_Account__c
                ||  lead.Referral_Contact__c != oldLead.Referral_Contact__c))
             ) {
              evaluateRefSrc = true;
           } 
      }
      System.debug('checkAccountReferralSources evaluateRefSrc='+evaluateRefSrc);
      return evaluateRefSrc;
   } // checkAccountReferralSources
    
    // this is for testing only
    public static Boolean SKIP_RFRL_OWNERSHIP_TRIGGER=false;
    
    public static void prepareCheckRfrlSrcOwnership(Id[] acctIds) {
        if (SKIP_RFRL_OWNERSHIP_TRIGGER) {
            return;
        }
        if (Utilities.allowFuture()) {
            checkRfrlSrcOwnershipFuture(acctIds);
        } else {
            checkRfrlSrcOwnershipNow(acctIds);
        }
    } // prepareCheckRfrlSrcOwnership
    
    @future
    public static void checkRfrlSrcOwnershipFuture(Id[] acctIds) {
        checkRfrlSrcOwnershipNow(acctIds);
    } // checkRfrlSrcOwnershipFuture
    
    public static void checkRfrlSrcOwnershipNow(Id[] acctIds) {
        if(acctIds[0].getSObjectType().getDescribe().getName()== 'Account'){
            System.debug('ReferralAccountChkAcctOwner checkRfrlSrcOwnershipNow acctIds='+acctIds.size());
            // accounts we'll update
            Account[] acctsToUpdate = new Account[]{};
            AccountTeamMember[] atmsToDelete = new AccountTeamMember[]{};
            AccountTeamMember[] atmsToInsert = new AccountTeamMember[]{};
            Map<Id,Id> refSourceIdByAccountId = new Map<Id,Id>();
            // the ids of the referral accounts found as sources
            Id[] refAcctIds = new Id[]{};
            Account[] accts = queryAccts(acctIds);
            // if we have a match for the account, add it here
            AcctRATWrap[] wraps = new AcctRATWrap[]{};
            for (Account acct : accts){
                getReferralSource(acct,wraps, refAcctIds);
                //getReferralSource(acct,refSourceIdByAccountId);
            } // for (Account acct
            // don't need to do anything if nothing is found
            System.debug('checkRfrlSrcOwnershipNow wraps='+wraps.size());
            if (wraps.isEmpty()) {
               return;
            }
            //Map<Id,Map<String,User>> ratsByRefAcctId = queryRat(refSourceIdByAccountId);
            Map<Id,Map<String,Referral_Account_Team__c>> allRatMap = queryRat(refAcctIds);
            for (AcctRATWrap wrap : wraps) {
               Map<String,Referral_Account_Team__c> ratMap = allRatMap.get(wrap.refAcctId);
               if (!wrap.recUpdated) {
                    checkAccountOwners(wrap,ratMap);
               }
                //checkAccountOwners(wrap,ratMap);
               if (wrap.recUpdated) {
                   acctsToUpdate.add((Account)wrap.obj);
               }
               atmsToDelete.addAll(wrap.atmDelete);
               atmsToInsert.addAll(wrap.atmInsert);
            } // for (AcctRATWrap wrap

            DmlHelper.performDML2(atmsToDelete, DmlHelper.DML_DELETE, CLASSNAME, 'checkRfrlSrcOwnershipNow', 'Deleting Old Team Members', false);
            DmlHelper.performDML2(atmsToInsert, DmlHelper.DML_INSERT, CLASSNAME, 'checkRfrlSrcOwnershipNow', 'Inserting New Team Members', false);
            DmlHelper.performDML2(acctsToUpdate, DmlHelper.DML_UPDATE, CLASSNAME, 'checkRfrlSrcOwnershipNow', 'Updating Account Owner', false);
            ErrorLog.checkSave();
        }
        else if(acctIds[0].getSObjectType().getDescribe().getName()== 'Lead'){  
            // leads we'll update
            Lead[] leadsToUpdate = new Lead[]{};
            Lead[] leads = queryLeads(acctIds);         
            // the ids of the referral accounts found as sources
            Id[] refAcctIds = new Id[]{};
            // if we have a match for the account, add it here
            AcctRATWrap[] wraps = new AcctRATWrap[]{};
            for (Lead lead : leads){
                getReferralSource(lead,wraps,refAcctIds);
            }// for (Lead lead
            // don't need to do anything if nothing is found
            System.debug('checkRfrlSrcOwnershipNow wraps='+wraps.size());
            if (wraps.isEmpty()) {
               return;
            }
            //Map<Id,Map<String,User>> ratsByRefAcctId = queryRat(refSourceIdByAccountId);
            Map<Id,Map<String,Referral_Account_Team__c>> allRatMap = queryRat(refAcctIds);
            for (AcctRATWrap wrap : wraps) {
               Map<String,Referral_Account_Team__c> ratMap = allRatMap.get(wrap.refAcctId);
               checkAccountOwners(wrap,ratMap);
               if (wrap.recUpdated) {
                  leadsToUpdate.add((Lead)wrap.obj);
               }
            } // for (AcctRATWrap wrap
            DmlHelper.performDML2(leadsToUpdate, DmlHelper.DML_UPDATE, CLASSNAME, 'checkRfrlSrcOwnershipNow', 'Updating Lead Owner', false);
            ErrorLog.checkSave();
        }
    } // checkRfrlSrcOwnershipNow
    
    public static Lead[] queryLeads(Id[] leadIds) {
        Lead[] leads = [Select Id, Name, OwnerId, Company, Description, EvaluateRefAcctOwner__c,
                        Hold_Out__c, Hold_Out_Reason__c, OwnedBy__c, OwnedByPrev__c, OwnedByUser__c,
                        ProcessNotes__c, Referral_Contact__c, ReferralContact__c, UseZipAssignmentRules__c,
                        Hold_Out_Expiration__c, Referral_National_Account__c
                        ,Referral_Contact__r.Id
                        ,Referral_Contact__r.Referral_Account__r.Id
                        ,Referral_Contact__r.Referral_Account__r.Referral_Source_Business_Type__c
                        ,Referral_Contact__r.Referral_Account__r.Has_Referral_Account_Team__c
                        ,Referral_Contact__r.Referral_Account__r.DedicatedRep__r.Id
                        ,Referral_Contact__r.Referral_Account__r.DedicatedRep__r.IsActive
                        ,Referral_Contact__r.Referral_Account__r.Parent_Referral_Account__r.Id
                        ,Referral_Contact__r.Referral_Account__r.Parent_Referral_Account__r.Referral_Source_Business_Type__c
                        ,Referral_Contact__r.Referral_Account__r.Parent_Referral_Account__r.Has_Referral_Account_Team__c
                        ,Referral_Contact__r.Referral_Account__r.Parent_Referral_Account__r.DedicatedRep__r.Id
                        ,Referral_Contact__r.Referral_Account__r.Parent_Referral_Account__r.DedicatedRep__r.IsActive
                        ,Referral_National_Account__r.Id
                        ,Referral_National_Account__r.Referral_Source_Business_Type__c
                        ,Referral_National_Account__r.Has_Referral_Account_Team__c
                        ,Referral_National_Account__r.DedicatedRep__r.Id
                        ,Referral_National_Account__r.DedicatedRep__r.IsActive
                        ,Referral_National_Account__r.Parent_Referral_Account__r.Id
                        ,Referral_National_Account__r.Parent_Referral_Account__r.Referral_Source_Business_Type__c
                        ,Referral_National_Account__r.Parent_Referral_Account__r.Has_Referral_Account_Team__c
                        ,Referral_National_Account__r.Parent_Referral_Account__r.DedicatedRep__r.Id
                        ,Referral_National_Account__r.Parent_Referral_Account__r.DedicatedRep__r.IsActive
                        From Lead
                           Where Id in :leadIds];
        System.debug('queryLeads leads='+leads.size());
        return leads;
    }
    
    public static Account[] queryAccts(Id[] acctIds) {
        Account[] accts = [Select Id, Name, OwnerId, NumberOfEmployees, Employees__c, Type, Lost_Date__c
                           ,CurrentClient__c
                           ,Hold_Out__c
                           ,Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c,Referral_National_Account__c
                           ,HNBF_Account_Owner__c,HNBF_Hold_Out__c,HNBF_Hold_Out_Expiration__c,HNBF_Permanent_Hold_Out_Description__c
                           ,HRS_Account_Owner__c,HRS_Hold_Out__c,HRS_Hold_Out_Expiration__c,HRS_Permanent_Hold_Out_Description__c
                           ,MS_Hold_Out__c,MS_Hold_Out_Expiration__c,MS_Permanent_Hold_Out_Description__c
                           ,P_C_Hold_Out__c,P_C_Hold_Out_Expiration__c,P_C_Permanent_Hold_Out_Description__c
                           ,TAA_Holdout__c,TAA_Holdout_Expiration__c,TAA_Permanent_Holdout_Description__c
                           ,Premier_PBS_Account_Owner__c,Premier_PBS_Hold_Out__c,Premier_PBS_Hold_Out_Expiration__c,PEO_ASO_Permanent_Hold_Out_Description__c
                           ,OasisPEOAccountOwner__c,OasisPEOHoldOut__c,OasisPEOHoldOutExpiration__c,OasisPEOHoldOutReason__c
                           ,EvaluateRefAcctOwner__c, ProcessNotes__c, BenAdmin_Hold_Out__c, BenAdmin_Hold_Out_Expiration__c, BenAdmin_Hold_Out_Reason__c
                           ,Banker_Name_Ref__r.Referral_Account__r.Id
                           ,Banker_Name_Ref__r.Referral_Account__r.Referral_Source_Business_Type__c
                           ,Banker_Name_Ref__r.Referral_Account__r.Has_Referral_Account_Team__c
                           ,Banker_Name_Ref__r.Referral_Account__r.DedicatedRep__r.Id
                           ,Banker_Name_Ref__r.Referral_Account__r.DedicatedRep__r.IsActive
                           ,Banker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.Id
                           ,Banker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.Referral_Source_Business_Type__c
                           ,Banker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.Has_Referral_Account_Team__c
                           ,Banker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.DedicatedRep__r.Id
                           ,Banker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.DedicatedRep__r.IsActive
                           ,CPA_Name_Ref__r.Referral_Account__r.Id
                           ,CPA_Name_Ref__r.Referral_Account_Business_Type__c
                           ,CPA_Name_Ref__r.Referral_Account__r.Referral_Source_Business_Type__c
                           ,CPA_Name_Ref__r.Referral_Account__r.Has_Referral_Account_Team__c
                           ,CPA_Name_Ref__r.Referral_Account__r.DedicatedRep__r.Id
                           ,CPA_Name_Ref__r.Referral_Account__r.DedicatedRep__r.IsActive
                           ,CPA_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.Id
                           ,CPA_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.Referral_Source_Business_Type__c
                           ,CPA_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.Has_Referral_Account_Team__c
                           ,CPA_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.DedicatedRep__r.Id
                           ,CPA_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.DedicatedRep__r.IsActive
                           ,Insurance_Broker_Name_Ref__r.Referral_Account__r.Id
                           ,Insurance_Broker_Name_Ref__r.Referral_Account__r.Referral_Source_Business_Type__c
                           ,Insurance_Broker_Name_Ref__r.Referral_Account__r.Has_Referral_Account_Team__c
                           ,Insurance_Broker_Name_Ref__r.Referral_Account__r.DedicatedRep__r.Id
                           ,Insurance_Broker_Name_Ref__r.Referral_Account__r.DedicatedRep__r.IsActive
                           ,Insurance_Broker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.Id
                           ,Insurance_Broker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.Referral_Source_Business_Type__c
                           ,Insurance_Broker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.Has_Referral_Account_Team__c
                           ,Insurance_Broker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.DedicatedRep__r.Id
                           ,Insurance_Broker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.DedicatedRep__r.IsActive
                           ,Broker_Name_Ref__r.Referral_Account__r.Id
                           ,Broker_Name_Ref__r.Referral_Account__r.Referral_Source_Business_Type__c
                           ,Broker_Name_Ref__r.Referral_Account__r.Has_Referral_Account_Team__c
                           ,Broker_Name_Ref__r.Referral_Account__r.DedicatedRep__r.Id
                           ,Broker_Name_Ref__r.Referral_Account__r.DedicatedRep__r.IsActive
                           ,Broker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.Id
                           ,Broker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.Referral_Source_Business_Type__c
                           ,Broker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.Has_Referral_Account_Team__c
                           ,Broker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.DedicatedRep__r.Id
                           ,Broker_Name_Ref__r.Referral_Account__r.Parent_Referral_Account__r.DedicatedRep__r.IsActive
                           ,Referral_National_Account__r.Id
                           ,Referral_National_Account__r.Referral_Source_Business_Type__c
                           ,Referral_National_Account__r.ReferralSourceSubType__c
                           ,Referral_National_Account__r.Has_Referral_Account_Team__c
                           ,Referral_National_Account__r.DedicatedRep__r.Id
                           ,Referral_National_Account__r.DedicatedRep__r.IsActive
                           ,Referral_National_Account__r.Parent_Referral_Account__r.Id
                           ,Referral_National_Account__r.Parent_Referral_Account__r.Referral_Source_Business_Type__c
                           ,Referral_National_Account__r.Parent_Referral_Account__r.Has_Referral_Account_Team__c
                           ,Referral_National_Account__r.Parent_Referral_Account__r.DedicatedRep__r.Id
                           ,Referral_National_Account__r.Parent_Referral_Account__r.DedicatedRep__r.IsActive
                          // ,(SELECT Id, Name, Type, OpportunityType__c, IsWon, IsClosed, OwnerId, Owner.Sales_Division__c, Owner.IsActive FROM Opportunities WHERE OpportunityType__c = 'Payroll' ORDER BY CreatedDate DESC LIMIT 1)
                           ,(SELECT Id,UserId,AccountId,TeamMemberRole FROM AccountTeamMembers)
                           From Account
                           Where Id in :acctIds];
        System.debug('queryAccts accts='+accts.size());
        return accts;
    } // queryAccts
    
   // used to assign ownership to the account
   public static Map<Id,Map<String,Referral_Account_Team__c>> queryRat(Id[] refAcctIds) {
      system.debug('queryRat refAcctIds'+refAcctIds.size());
      Map<Id,Map<String,Referral_Account_Team__c>> ratsByRefAcctId = new Map<Id,Map<String,Referral_Account_Team__c>>();
      if (!refAcctIds.isEmpty()) {
         Referral_Account_Team__c[] rats = [SELECT Id,Account_Owner__c, AccountTeamRole__c, Referral_Account__c
                                                 ,Team_Member_Name__c,Team_Member_Name__r.Id,Team_Member_Name__r.Name,Team_Member_Name__r.Sales_Org__c
                                             FROM Referral_Account_Team__c 
                                            WHERE Referral_Account__c in : refAcctIds AND Team_Member_Name__r.IsActive = true];
         system.debug('queryRat='+rats.size());
         for (Referral_Account_Team__c rat:rats) {
            Map<String,Referral_Account_Team__c> ratsForRefAcct = (ratsByRefAcctId.containsKey(rat.Referral_Account__c) ? ratsByRefAcctId.get(rat.Referral_Account__c) : new Map<String,Referral_Account_Team__c>());
            ratsForRefAcct.put(rat.Team_Member_Name__r.Sales_Org__c, rat);
            ratsByRefAcctId.put(rat.Referral_Account__c,ratsForRefAcct);
         } // for (Referral_Account_Team__c rat:rats
      } // if (!refAcctIds.isEmpty()
      return ratsByRefAcctId;
   } // queryRat

    public class AcctRATWrap {
        public Boolean recUpdated=false;
        public SObject obj;
        public Id refAcctId;
        public String holdOutReason;
        public AccountTeamMember[] atmDelete = new AccountTeamMember[]{};
        public AccountTeamMember[] atmInsert = new AccountTeamMember[]{};
      //public Referral_Account__c refAcct;
      //public Referral_Account_Team__c rats;
   } // class AcctRATWrap
    
} // class ReferralAccountChkAcctOwner