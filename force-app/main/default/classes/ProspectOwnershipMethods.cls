/* 
 * Methods for the Prospect Ownership object
 *
 * History
 * -------
 * 10/03/2013 Dan Carmen      Created
   12/19/2014 Dan Carmen      Consolidated methods coming from the lead
   07/02/2105 Cindy Freeman   Modified getSetting to use Segment to find Life Of Lead setting
   07/20/2015 Dan Carmen      Changes for Virtual Sales
   08/10/2015 Cindy Freeman   Fix determineSegment, used to set segment on prospect ownership record
   01/08/2016 Dan Carmen      Set the supervisor when the opportunity is set
   02/18/2016 Dan Carmen      additional checking for expired ownership records.
   03/31/2016 Dan Carmen      Created a set of the NSS Sources
   04/12/2016 Dan Carmen      Clean up a little code.
   10/31/2016 Jacob Hinds     Small fix to getProspectingOwner method
   01/28/2016 Jermaine Stukes Removed Product of Interest from NSS Team set
   04/10/2017 Cindy Freeman    changed delete of future tasks to use DmlHelper to catch possible errors
   04/26/2017 Cindy Freeman    Added logging into ProcessTracker field
   07/12/2017 Dan Carmen         Add additional logging
   09/11/2018 Dan Carmen         Added in extra logging
   10/26/2018 Dan Carmen         Move getAllOpenOwnershipByUser to NSSAdministrationController
   12/27/2018 Dan Carmen         Add in changes for qbdialer__Callback_Date_Time__c to move to DialSource
   03/15/2019 Dan Carmen         Change the save method for leads to be able to retry a save
   04/23/2019 Dan Carmen         Don't save errors for AccountTeamMembers
   06/17/2019 Dan Carmen         Check for callbacks on the creation of prospect ownership
   10/22/2019 Dan Carmen         Extra check in checkAccountOwnership to prevent extra PO records getting created.
   11/14/2019 Dan Carmen         Removed ISDC code
   04/11/2020 Dan Carmen         Check save of key value before checking custom setting
   03/07/2022 Dan Carmen         Clean up DialSource Action match logic
   05/24/2022 Reetesh Pandey     Account Team Member sharing
   09/12/2022 Reetesh Pandey     Capture Dialsource DSA on Prospect Ownership When Planted Off Account
 */
public without sharing class ProspectOwnershipMethods {

   public static final String STAGE_PROSPECTING='Prospecting';
   public static final String STAGE_LOCKOUT='Lockout';
   public static final String STAGE_EXPIRED='Expired';
   public static final String STAGE_WORKABLE='Workable';
   public static final String STAGE_COMMISSION='Commission Only';
   public static final String STAGE_NO_INTEREST='Not Interested';
   
   public static Integer TRACKER_LENGTH=Prospect_Ownership__c.ProcessTracker__c.getDescribe().getLength();
   
   public static void addToProcessTracker(Prospect_Ownership__c po, String textToAdd) {
      StringHelper.addNotesToField(po, 'ProcessTracker__c', TRACKER_LENGTH, textToAdd, true);
   } // addToProcessTracker
   
   /** Extra fields queried with the prospect ownership method. */
   public static String prospectOwnershipSelectFields = '';
   
   // select all users who can have prospect ownership
   public static Map<Id,User> getNsrUserMap(Set<Id> userIds) {
      Map<Id,User> userMap = null;
      if (userIds != null && !userIds.isEmpty()) {
         userMap = new Map<Id,User>([Select Id, Name, Job_Name__c, Profile.Name, NSS_Team__c
                                                 from User 
                                                where Id in :userIds 
                                                  and (Job_Name__c in :UserHelper.NSS_JOBS
                                                       or NSS_Team__c != null)
                                               ]);
      } else {
         userMap = new Map<Id,User>();
      }
      System.debug('getNsrUserMap number users='+userMap.size()+' userIds='+userIds);
      return userMap;
   } // getNsrUserMap
   
   
    /** Check the ownership for accounts/contacts
       For a referral record, there should only be (at most) one outbound owner and one inbound owner. 
       If an outbound 
       
       // if there is an open ownership record of the same type, use that. Don't change the NSR, but you can change the team.
       // if there is a lockout ownership record of the same type and same NSR, but different NSS Team, create a new one
       // if there is an open outbound record not locked, and inbound opportunity comes in, close the outbound record and create an inbound
       // if there is an open outbound record locked, and inbound opportunity comes in, don't touch the outbound and create an inbound
       // if an open record already exists for the type and you're creating a new one, only set the commission period on the new one.
       // if there is a lockout inbound, and outbound creates an opportunity, do not create an ownership record. 
       
       
       inbound scenarios
        -- If any inbound, no outbound, continue as normal
        -- If inbound prospecting, open outbound prospecting, not interested, wash exists, end outbound prospecting
        -- if inbound prospecting, open outbound lockout or workable, create inbound don't touch outbound
        -- If inbound lockout, open outbound lockout, create inbound commission only record
        -- If inbound lockout, open outbound workable, end outbound, add to commission period if outbound still commissionable.
       
       outbound scenario
        -- If any outbound, no inbound, continue as normal
        -- If any outbound, open inbound exists, do nothing.
        -- If any outbound, commission only exists, continue as normal

       @param p_stage the status of the ownership record we are checking for/creating.
    */
   public static Prospect_Ownership__c checkAccountOwnership(String p_stage, Boolean changeStage, Account acct, Contact p_ctct, Id ctctId, AccountTeamMember[] atms, User nsrUser, Id oppId, String nssTeam, String nssSource, List<Prospect_Ownership__c> acctOwnerList) {
            
      // is this an inbound NSR? If not, we assume they're outbound 
      Boolean isUserInbound = (nssSource == NSS_INBOUND);
      noPOReason = '';
      System.debug('checkAccountOwnership isUserInbound='+isUserInbound+' nssTeam='+nssTeam+' nssSource='+nssSource+' p_stage='+p_stage);
      String acctLog = ('checkAccountOwnership isUserInbound='+isUserInbound+' nssTeam='+nssTeam+' nssSource='+nssSource+' p_stage='+p_stage+' acctOwnerList='+(acctOwnerList != null ? acctOwnerList.size() : -1));

      // if we want to make sure we don't create a new record
      Boolean doNotCreateNew = false;
      Boolean createNewRecord = false;
      Boolean newRecordIsCommissionOnly = false;
      
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkOwnership nssTeam='+nssTeam+' nssSource='+nssSource+' isUserInbound='+isUserInbound+' acctOwnerList='+acctOwnerList));
      
      Prospect_Ownership__c ownership = null;
      // should be at most 1 inbound and 1 outbound record open - if commission only we 
      Prospect_Ownership__c ownerInbound = null;
      Prospect_Ownership__c ownerOutbound = null;
      
      
      // at time of opportunity creation should at most be one outbound and one inbound ownership open record per nssTeam
      Boolean outboundFound = false;
      Boolean inboundFound = false;
      
      // the id we will use to create a new ownership record
      Id nsrId = nsrUser.Id;
      
      // does this NSR already have a lockout record? If they do, and they get one in for another team, we will create that one.
      //Boolean nsrAlreadyHasLockout = false;
      // if there's a lockout record, is it for the same team that is being passed in?
      Boolean lockoutIsSameTeam = false;
      
      // get the life of lead setting for the next stage  ** assuming segment is blank *** CMF 
      LifeOfLeadSettings__c thisSetting = getSetting(p_stage, nssTeam, nssSource, null);
      acctLog += (thisSetting != null ? thisSetting.Name : 'NoSetting');
      // if we always want to use the current NSR when changing the stage or creating a new PO
      Boolean forceUseCurrentNSROnStageChange = (thisSetting != null ? thisSetting.UseRunningUserForStage__c : false);
      
      Contact ctct = p_ctct;
      if (ctct == null) {
         ctct = AccountMethods.findContact(acct, (acct != null ? acct.Contacts : null), ctctId, null);
      }

      // keep track of other open prospecting records. If we have other open of the same type we are using, we would expire them. 
      Map<Id,Prospect_Ownership__c> allProspectingMap = new Map<id,Prospect_Ownership__c>();

      if (ownership == null && acctOwnerList != null && !acctOwnerList.isEmpty()) {
         
         // break apart the list by nss team
         Map<String,Prospect_Ownership__c> inboundLockoutMap = new Map<String,Prospect_Ownership__c>();
         Map<String,Prospect_Ownership__c> outboundLockoutMap = new Map<String,Prospect_Ownership__c>();

         // should only be at most one non-lockout record (prospecting, workable, not interested, wash)
         //Prospect_Ownership__c notLockedOutPO = null;
         Prospect_Ownership__c sourcePO = null;
         
         // organize the lockout and commission records for easy lookup
         for (Prospect_Ownership__c po : acctOwnerList) {
            if (po.Ownership_Status__c == STAGE_LOCKOUT || po.Ownership_Status__c == STAGE_COMMISSION) {
               
               if (po.NSR_Name__c==nsrUser.Id) {
                  newRecordIsCommissionOnly = true;
                  if (po.NSS_Team__c == nssTeam) {
                     lockoutIsSameTeam = true;
                  }
               } // if (po.NSR_Name__c
               
               if (po.NSS_Source__c == NSS_INBOUND) {
                  addToMap(inboundLockoutMap, po);
               } else if (po.NSS_Source__c == NSS_OUTBOUND) {
                  addToMap(outboundLockoutMap, po);
               }
            //} else if (notLockedOutPO == null && po.EndDate__c == null) {
               
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkOwnership notLockedOutPO:'+po));
               // should only ever be one open non-locked out record.
               //notLockedOutPO = po;
            } // if (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_LOCKOUT
            
            // keep track of the open inbound and outbound owner records.
            if (po.EndDate__c == null) {
               System.debug('checkAccountOwnership EndDate__c==null source='+po.NSS_Source__c);
               if (po.NSS_Source__c == NSS_INBOUND && ownerInbound == null) {
                  ownerInbound = po;
               } else if (po.NSS_Source__c == NSS_OUTBOUND && ownerOutbound == null) {
                  ownerOutbound = po;
               }
            } // if (po.EndDate__c == null
            
            if (po.NSS_Source__c == nssSource && po.Ownership_Status__c == STAGE_PROSPECTING) {
               allProspectingMap.put(po.Id, po);
            }
         } // for
         
         System.debug('checkAccountOwnership check1 outboundFound='+outboundFound+' inboundFound='+inboundFound);
         outboundFound = (!outboundLockoutMap.isEmpty() || ownerOutbound != null);
         inboundFound = (!inboundLockoutMap.isEmpty() || ownerInbound != null);
         System.debug('checkAccountOwnership check2 outboundFound='+outboundFound+' inboundFound='+inboundFound);
         acctLog += '; checkExisting outboundFound='+outboundFound+' inboundFound='+inboundFound;

         // if there isn't a locked out record for the type passed in, use the notLocked record.
         Map<String,Prospect_Ownership__c> lockoutMap = (nssSource == NSS_INBOUND ? inboundLockoutMap : outboundLockoutMap);
         // if a lockout record exists, we're not going to be doing anything with it.
         ownership = lockoutMap.get(nssTeam);
         
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkOwnership nssTeam='+nssTeam+' nsrAlreadyHasLockout='+nsrAlreadyHasLockout+' outboundLockoutMap.size='+outboundLockoutMap.size()+' ownership:'+ownership+' notLockedOutPO='+notLockedOutPO));
         Boolean useThisRecord = false;

         // handle inbound ownership and outbound ownership exists
          if (isUserInbound && ownerOutbound != null) {
              System.debug('checkAccountOwnership handling inbound ownership with existing outbound ownership');
              acctLog += '; handling inbound ownership with existing outbound ownership';
              
              // if outbound is prospecting, not interested, wash we are always ending this
              if (ownerOutbound.Ownership_Status__c != STAGE_LOCKOUT && ownerOutbound.Ownership_Status__c != STAGE_WORKABLE) {
                  System.debug('checkAccountOwnership inbound user, ending outbound ownership');
                  acctLog += '; inbound user, ending outbound ownership';
                  // if inbound user, end the outbound record.
                  setStageExitInfo(ownerOutbound,acct, null, atms, null, true, true, true);
                  addToNotes(ownerOutbound,'Ownership ended due to Inbound NSR taking ownership from Outbound.');
                  
                  addToUpsertMap(ownerOutbound, true);
                  //notLockedOutPO = null;
                  ownerOutbound = null;
              } else if (ownerOutbound.Ownership_Status__c == STAGE_LOCKOUT && p_stage == STAGE_LOCKOUT) {
                  // if existing inbound record exists, we will use that and end it.
                  if (ownerInbound != null) {
                      System.debug('checkAccountOwnership creating commission only record');
                      acctLog += '; creating commission only record';
                      // if not already lockout, end the current stage and enter lockout
                      if (ownerInbound.Ownership_Status__c != STAGE_LOCKOUT) {
                          setStageExitInfo(ownerInbound,acct, null, atms, null, false, true, false);
                          ownerInbound.Ownership_Status__c = STAGE_LOCKOUT;
                          // attach the opportunity/check the nss team
                          ownerInbound.Opportunity__c = oppId;
                          ownerInbound.NSS_Team__c = nssTeam;
                          try {
                              ownerInbound.NSRSupervisor__c = nsrUser.ManagerId;
                          } catch (Exception e) {
                              // just in case ManagerId is not set
                          }
                          setStageEntryInfo(ownerInbound, acct, ctct, atms, null, true, false);
                          setStageExitInfo(ownerInbound,acct, ctct, atms, null, true, true, true);
                      } else if (ownerInbound.Ownership_Status__c == STAGE_LOCKOUT) {
                          // force the closing of the record if already lockout
                          setStageExitInfo(ownerInbound,acct, ctct, atms, null, true, true, true);
                      }
                      // change the status to commission
                      ownerInbound.Ownership_Status__c = STAGE_COMMISSION;
                      addToNotes(ownerInbound,'Commission Only due to existing Outbound Lockout record.');
                      addToUpsertMap(ownerInbound, true);
                      
                      doNotCreateNew = true;
                  } else {
                      // if there's a record in the lockout map, do not create a new record.
                      createNewRecord = inboundLockoutMap.isEmpty();
                      newRecordIsCommissionOnly = true;
                  }
                  // if lockout record exists
              } else if (ownerOutbound.Ownership_Status__c == STAGE_WORKABLE && p_stage == STAGE_LOCKOUT) {
                  System.debug('checkAccountOwnership ending outbound ownership for inbound lockout');
                  acctLog += '; ending outbound ownership for inbound lockout';
                // if outbound is with its commission period, we will add to the commission days then end the ownership.
                LifeOfLeadSettings__c inboundSetting = getSetting(p_stage, nssTeam, NSS_INBOUND, ownerOutbound.Segment__c);
                if (inboundSetting != null && inboundSetting.AddToOutboundComm__c != null &&
                    ownerOutbound.CommissionStart__c != null && ownerOutbound.CommissionStart__c <= Date.today() && ownerOutbound.CommissionEnd__c >= Date.today()) {
                        // add days to the end of the commission period
                        ownerOutbound.CommissionEnd__c = ownerOutbound.CommissionEnd__c.addDays(inboundSetting.AddToOutboundComm__c.intValue());
                    }
                // if inbound user, end the outbound record.
                setStageExitInfo(ownerOutbound,acct, null, atms, null, true, true, true);
                addToNotes(ownerOutbound,'Ownership ended due to Inbound NSR taking ownership from Outbound.');
                addToUpsertMap(ownerOutbound, true);
                ownerOutbound = null;
                
            }
         } // if (isUserInbound && ownerOutbound != null

/*
         if (notLockedOutPO != null && notLockedOutPO.NSS_Source__c != nssSource) {
            if (isUserInbound && notLockedOutPO.NSS_Source__c != NSS_INBOUND) {
               // if inbound user, end the outbound record.
               setStageExitInfo(notLockedOutPO,acct, null, atms, null, true, true, true);
               addToUpsertMap(notLockedOutPO, true);
               notLockedOutPO = null;
            } else if (!isUserInbound && notLockedOutPO.NSS_Source__c == NSS_INBOUND) {
               // if outbound user and inbound ownership, do not proceed
               inboundFound = true;
            }
            
         } // if (notLockedOutPO.NSS_Source__c
         */
         
         //notLockedOutPO = (isUserInbound ? ownerInbound : ownerOutbound);
         // get the owner record based on the source
         sourcePO = (isUserInbound ? ownerInbound : ownerOutbound);
         
         // if there isn't a record already locked out but there is an open record and it's the same source
         //if (ownership == null && notLockedOutPO != null && notLockedOutPO.NSS_Source__c == nssSource) {
         if (ownership == null && sourcePO != null && sourcePO.Ownership_Status__c != STAGE_LOCKOUT) {
            // if we're not going to change stage or
            // check if the stage equals the stage passed in. If they're equal we don't need to check further.
            if (!changeStage || (String.isNotBlank(p_stage) && sourcePO.Ownership_Status__c == p_stage)) {
               useThisRecord = true;
            } else {
               LifeOfLeadSettings__c lols = getSetting(sourcePO);
               if (lols != null) {
               
                  // if the next stage isn't the passed in stage (example: you're on workable and you want to go to lockout) then we'll need to create a new record.
                  Boolean endRecord = (lols.NextAllowedStage__c != p_stage);
                  // end the current stage
                  setStageExitInfo(sourcePO,acct, ctct, atms, null, endRecord, true, false);
                  System.debug('checkAccountOwnership endRecord='+endRecord+' EndDate='+sourcePO.EndDate__c);

                  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkOwnership endRecord='+endRecord+' notLockedOutPO.EndDate__c='+notLockedOutPO.EndDate__c));
                  if (sourcePO.EndDate__c != null) {
                     // set this to false so it will create a new record.
                     outboundFound = false;
                     // save this record, a new one will need to be created.
                     addToUpsertMap(sourcePO, true);
                     // create new one using the same nsr
                     nsrId = (!forceUseCurrentNSROnStageChange ? sourcePO.NSR_Name__c : nsrId);
                     // force creation of a new record
                     createNewRecord = true;
                  } else {
                     // the ownership is not ended, so we can change it to lockout and keep it.
                     sourcePO.Ownership_Status__c = p_stage;
                     sourcePO.Opportunity__c = oppId;
                     // if we're changing the status and the flag is set and the NSR isn't the same, change to the passed in NSR
                     if (forceUseCurrentNSROnStageChange && sourcePO.NSR_Name__c != nsrId) {
                        sourcePO.NSR_Name__c = nsrId;
                     }
                     Id originalDecisionMaker = sourcePO.Decision_Maker__c;
                     // if a contact is passed in, make sure that is set as the decision maker
                     sourcePO.Decision_Maker__c = (ctct != null ? ctct.Id : sourcePO.Decision_Maker__c);
                     if (originalDecisionMaker != sourcePO.Decision_Maker__c && originalDecisionMaker != null) {
                        // the decision maker changed - remove the hold out flag
                        Contact oldCtct = new Contact(Id=originalDecisionMaker, Hold_Out__c=false, Hold_Out_Reason__c=null, Use_Zip_Assignment_Rules__c=true);
                        saveCtctMap.put(oldCtct.id,oldCtct);
                     }
                     // make sure the nss team matches
                     sourcePO.NSS_Team__c = nssTeam;
                     setStageEntryInfo(sourcePO, acct, ctct, atms, null, true, false);
                     useThisRecord = true;
                  }
               } // if (lols != null
            } //  if (notLockedOutPO.Opportunity_Stage__c
         } // if (ownership == null 
         
         acctLog += '; useThisRecord='+useThisRecord;   
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkOwnership ref='+rw.ref.Name+' useThisRecord='+useThisRecord));
         if (useThisRecord) {
            //if (ownerInbound != null) {
            //   inboundFound = true;
            //} else if (ownerOutbound != null) {
            //   outboundFound = true;
            //}
            checkContacts(acct,ctct,sourcePO.Decision_Maker__c,false,nsrId,sourcePO, null);
            addToUpsertMap(sourcePO, false);
            ownership = sourcePO;
            // remove from map if we end up using this
            allProspectingMap.remove(ownership.Id);
         } // if (useThisRecord
                  
      } // if (ownership == null
      
      // do we need to create a new record?
      // if multiple opportunities are being created at once, only one ownership record should 
      // the rule is that a new ownership record can get created for inbound if an outbound exists, but outbound can't get a new
      // ownership record if an inbound exists.
      Boolean createNew = (createNewRecord || (!doNotCreateNew && ownership == null  
                               && (((isUserInbound && !inboundFound) || (!isUserInbound && !outboundFound && !inboundFound))
                                   || (newRecordIsCommissionOnly && !lockoutIsSameTeam)
                                  ))
                          );
      acctLog += '; createNew='+createNew+' createNewRecord='+createNewRecord+' isUserInbound='+isUserInbound+' inboundFound='+inboundFound+' outboundFound='+outboundFound+' ownership='+ownership+' newRecordIsCommissionOnly='+newRecordIsCommissionOnly;
      System.debug('checkAccountOwnership createNew='+createNew+' createNewRecord='+createNewRecord+' isUserInbound='+isUserInbound+' inboundFound='+inboundFound+' outboundFound='+outboundFound+' ownership='+ownership+' newRecordIsCommissionOnly='+newRecordIsCommissionOnly); 
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkOwnership ref='+rw.ref.Name+' createNew='+createNew));
      if (createNew && outboundFound && !isUserInbound && String.isNotBlank(p_stage)) {
         acctLog += '; createNew to false because p_stage=null and outbound';
         createNew = false;
      }

      if (createNew) {
         System.debug('checkAccountOwnership creating a new record');
         String newSegment = ProspectOwnershipMethods.determineSegment(acct.Owner_ZipCode__c, nssTeam, acct);
         ownership = new Prospect_Ownership__c(Prospect_Client__c=acct.Id, NSR_Name__c=nsrId, OwnerId=nsrUser.Id);
         ownership.NSS_Team__c = nssTeam;
         ownership.StartDate__c = Date.today();
         ownership.NSS_Source__c = nssSource;
         ownership.Ownership_Status__c = p_stage;
         ownership.Opportunity__c = oppId;
         ownership.Decision_Maker__c = (ctct != null ? ctct.Id : null);
         ownership.Segment__c = newSegment;
         addToProcessTracker(ownership, 'Created from ProspectOwnershipMethods checkAccountOwnership p_stage='+p_stage);

         if (String.isNotBlank(p_stage)) {
            setStageEntryInfo(ownership, acct, ctct, atms, null, true, newRecordIsCommissionOnly);
         }
         if (newRecordIsCommissionOnly && p_stage == STAGE_LOCKOUT) {
            // TODO - does the Lockout have a start date and no end date at this point?
            ownership.Ownership_Status__c = STAGE_COMMISSION;
            addToNotes(ownership,'Another locked out ownership record exists. This is a commission only record.');
         }
         //upsertPosMap.put(key,ownership);
         if (acctOwnerList != null) {
            acctOwnerList.add(ownership);
         }
      }
      
      // if there's anything left in this map, expire the record.
      if (!allProspectingMap.isEmpty()) {
         for (Prospect_Ownership__c checkPO : allProspectingMap.values()) {
            setStageExitInfo(checkPO,acct, ctct, atms, null, true, false, true);
            addToNotes(checkPO,'Ownership ended due to extra prospecting records.');
         } // for
      } // if (!allProspectingMap
      
      if (ownership == null) {
         setNoPOReason(isUserInbound, inboundFound, outboundFound);
      } // if (ownership == null
      StringHelper.addToProcessNotes(acct,acctLog);
      return ownership;
   } // checkAccountOwnership

   public static String NO_PO_OUT_IN = 'Outbound User and Inbound Ownership found';
   public static String NO_PO_IN_IN = 'Inbound User and Existing Inbound Ownership found';
   public static String NO_PO_OUT_OUT = 'Outbound User and Existing Outbound Ownership found';

   public static void setNoPOReason(Boolean isUserInbound, Boolean inboundFound, Boolean outboundFound) {
      if (!isUserInbound && inboundFound) {
         noPOReason = NO_PO_OUT_IN;
      } else if (isUserInbound && inboundFound) {
         noPOReason = NO_PO_IN_IN;
      } else if (!isUserInbound && outboundFound) {
         noPOReason = NO_PO_OUT_OUT;
      }
   } // setNoPOReason
   
   public static String noPOReason='';
   
   public static void addToUpsertMap(Prospect_Ownership__c po, boolean useCounter) {
      Id recId = po.Prospect_Client__c != null ? po.Prospect_Client__c : po.Lead__c;
      // create the key
      String key = po.Id != null ? (String)po.Id : recId+':'+po.NSS_Source__c+':'+po.NSS_Team__c;
      // if we have the id, do NOT use the counter
      if (useCounter && po.Id != null) {
         useCounter = false;
      }
      // save this record
      if (useCounter) {
         // find a key not being used
         Integer counter=0;
         while (upsertPosMap.containsKey(key+counter)) {
            counter++;
         } // while
         key = key+counter;
      } // if (useCounter
      
      try {
         // If there's a lead company set but the lead was converted, we want to remove the id from the object. 
         // if there's a prospect client we can assume the lead no longer exists.
         if (po.Lead_Company__c != null && po.Prospect_Client__c != null) {
            po.Lead_Company__c = null;
         }
      } catch (Exception e) {
         // the only exception that should occur here is if the Lead_Company__c field wasn't queried. So if an exception happens, we'll ignore it.
      }
      
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkOwnership key='+key+' po='+po));
      System.debug('addToUpsertMap key='+key+' po='+po);
      upsertPosMap.put(key,po);
   
   } // addToUpsertMap
   
   /** Add the passed in ownership record to the map, if appropriate. */
   public static void addToMap(Map<String,Prospect_Ownership__c> ownerMap, Prospect_Ownership__c po) {
      String nssTeam = po.NSS_Team__c;
      if (String.isNotBlank(nssTeam)) {
         // if there's no end date (should only be one non-end dated record per nssTeam) always add it.
         if (po.EndDate__c == null) {
            ownerMap.put(nssTeam,po);
         // else if there is an end date, not one already found, and it's still commissionable, add that.
         // a record without an end date would trump this record.
         } else if (po.EndDate__c != null
                    && !ownerMap.containsKey(nssTeam) 
                    && po.CommissionStart__c <= Date.today() && po.CommissionEnd__c >= Date.today()) {
            ownerMap.put(nssTeam,po);
         }
      } // if
   } // addToMap
   
   private static Map<String,Schema.RecordTypeInfo> byName = null;
   private static Map<String,Schema.RecordTypeInfo> byId = null;
   
   public static Schema.RecordTypeInfo getRecordTypeInfo(String recordTypeName, String recordTypeId) {
      Schema.RecordTypeInfo rt = null;
      if (byName == null) {
         byName = new Map<String,Schema.RecordTypeInfo>();
         byId = new Map<String,Schema.RecordTypeInfo>();
         RecordTypeHelper.getRecordTypesMap(ObjectHelper.OBJECT_LEAD, byId, byName);
      } // if (byName
      if (String.isNotBlank(recordTypeName)) {
         rt = byName.get(recordTypeName);
      }
      if (rt == null && String.isNotBlank(recordTypeId)) {
         rt = byId.get(recordTypeId);
      }
      return rt;
   } // getRecordTypeInfo

   public static Schema.RecordTypeInfo getLeadRecordTypeByNssTeam(String nssTeam) {
      Schema.RecordTypeInfo rt = null;
      if (String.isNotBlank(nssTeam)) {
         NSSTeamMap__c ntm = NSSTeamMap__c.getInstance(nssTeam);
         if (ntm != null) {
            rt = getRecordTypeInfo(ntm.LeadRecordTypeName__c, null);
         }
      } // if (String.isNotBlank
      return rt;
   } // getLeadRecordTypeByNssTeam
   
   /** If the product changes evaluate the NSS Team on the lead to see if that needs to change 
    */
   public static void evaluateLeadNSSTeam(Set<Id> leadIdSet) {
         
      // select the Leads
      Lead[] leads = ReferralQueries.selectLeads(leadIdSet,null);
      
      System.debug('Number of leads='+leads.size());
      initializeSaveObjects();
      
      for (Lead ld : leads) {
         System.debug('Checking lead '+ld.Name);
            
         String nssTeam = evaluateNssTeam(UserHelper.getRunningUser(), ld.Prospect_Ownership__r, ld.Products__c, ld.RecordType.Name, null, ld.NumberOfEmployees);
         // check the record type of the Lead - see if it needs to change
         Schema.RecordTypeInfo rt = getLeadRecordTypeByNssTeam(nssTeam);
         if (rt != null && ld.RecordTypeId != rt.getRecordTypeId()) {
            ld.RecordTypeId = rt.getRecordTypeId();
            // save the change
            saveLeadMap.put(ld.Id, ld);
         }
      } // for (Lead ld
      
      checkForSaves();
      
   } // evaluateLeadNSSTeam
   
   /** If the product changes evaluate the NSS Team on the Contact to see if that needs to change 
    */
   public static void evaluateContactNSSTeam(List<Id> ctctIds) {
         
      // select the Contacts
      Map<Id,Contact> ctctMap = ReferralQueries.selectCtctMap(ctctIds);
      
      System.debug('Number of contacts='+ctctMap.size());
      // the records that will be created/updated
      initializeSaveObjects();
      
      for (Contact ctct : ctctMap.values()) {
         System.debug('Checking ctct '+ctct.Name);
            
         evaluateNssTeam(UserHelper.getRunningUser(), ctct.Prospect_Ownership__r, ctct.Products__c, ctct.RecordType.Name, ctct.Account.RecordType.Name, ctct.Account.NumberOfEmployees);
      } // for (Contact ctct
      
      checkForSaves();
      
   } // evaluateContactNSSTeam
   
   /** If the product changes evaluate the NSS Team on the Account to see if that needs to change 
    */
   public static void evaluateAccountNSSTeam(List<Id> acctIds) {
         
      // select the Contacts
      Map<Id,Account> acctMap = ReferralQueries.selectAcctMap(acctIds);
      Set<Id> acctIdSet = new Set<Id>();
      acctIdSet.addAll(acctIds);
      Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = getAcctOwnerMap(acctIdSet, true, null, null);
      
      System.debug('Number of accounts='+acctMap.size());
      // the records that will be created/updated
      initializeSaveObjects();
      
      for (Account acct : acctMap.values()) {
         System.debug('Checking acct '+acct.Name);
            
         evaluateNssTeam(UserHelper.getRunningUser(), acctOwnerMap.get(acct.Id), acct.Products__c, acct.RecordType.Name, null, acct.NumberOfEmployees);
      } // for (Contact ctct
      
      checkForSaves();
      
   } // evaluateAccountNSSTeam
   
   public static String evaluateNssTeam(User usr, Prospect_Ownership__c[] owners, String products, String recordType1, String recordType2, Integer nbrOfEmps) {
      String nssTeam = null;
      // get the open ownership record - should only be one open record
      Prospect_Ownership__c po = getProspectingOwner(owners, null, null);
      System.debug('evaluateNssTeam po='+po);
      if (po != null) {
         // get the nss team
         String[] nssTeams = getNSSTeams(usr, products,recordType1, recordType2, UserHelper.SO_CORE, nbrOfEmps );
         System.debug('evaluateNssTeam nssTeams='+nssTeams+' status='+po.Ownership_Status__c == STAGE_PROSPECTING+' po.NSS_Team__c='+po.NSS_Team__c);
         
         // use the first one returned in the array - should always be at least one returned
         nssTeam = nssTeams[0];
         // only update the nss team in the prospecting stage
         if (po.Ownership_Status__c == STAGE_PROSPECTING && nssTeam != po.NSS_Team__c) { 
            po.NSS_Team__c = nssTeam;
            // update with the new ownership.
            addToUpsertMap(po, false);
         }
      } // if (po != null
      return nssTeam;
   } // evaluateNssTeam
   
   /** The NSS Teams we're checking for. */
   public static String[] VALID_NSS_TEAMS = Label.POValidNSSTeams.split(','); //new String[]{UserHelper.SO_CORE, UserHelper.SO_401, UserHelper.SO_MMS};
   
   // 'PAY','MMS','HRS','HNB','MSP','NT'
   
   /** The number of valid NSS teams. */
   public static Integer NBR_NSS_TEAMS = NSSTeamMap__c.getAll().size();
   public static final Integer NAME_FIELD_LENGTH = ProductGroupMapping__c.Name.getDescribe().getLength();

   
   /** Get the NSS Team from the passed in values. 
       First check the products of interest. Find the product with the highest "priority". If no records with priority found,
          look at the record types.
       If can't be determined by the record type, and there's a passed in defaultValue, use that.
       If no defaultValue, pass back PAY
    */
   public static String[] getNSSTeams(User usr, String productsOfInterest, String recordTypeName1, String recordTypeName2, String defaultValue, Integer nbrOfEmps) {
      String[] nssTeams = new String[]{};

      NSSTeamMap__c nssTeamMap = null;
      System.debug('getNSSTeams usr='+usr);
      if (usr != null && String.isNotBlank(usr.NSS_Team__c)) {
         nssTeamMap = NSSTeamMap__c.getInstance(usr.NSS_Team__c);
         if (nssTeamMap != null && nssTeamMap.AlwaysUse__c) {
            nssTeams.add(nssTeamMap.Name);
         }
      } // if (usr != null
      
      // if still blank, check the record type name 1
      if (nssTeams.isEmpty() && String.isNotBlank(recordTypeName1)) {
         System.debug('getNSSTeams checkRecordTypeName recordTypeName1');
         checkRecordTypeName(recordTypeName1,nssTeams);
      }
      
      // if still blank, check the record type name 2
      if (nssTeams.isEmpty() && String.isNotBlank(recordTypeName2)) {
         System.debug('getNSSTeams checkRecordTypeName recordTypeName2');
         checkRecordTypeName(recordTypeName2,nssTeams);
      }

      if (nssTeams.isEmpty() && nssTeamMap != null && nssTeamMap.UseForOwnership__c) {
         if (nssTeamMap.isPayroll__c && nbrOfEmps != null) {
            Integer checkEmp = Integer.valueOf(Label.MMS_Emp_Treshhold);
            if (nbrOfEmps >= checkEmp) {
               nssTeams.add(UserHelper.SO_MMS);
            } else {
               nssTeams.add(UserHelper.SO_CORE);
            }
         } else {
            nssTeams.add(nssTeamMap.Name);
         }
      } // if (nssTeams.isEmpty()


      // check the products of interest - multiple teams could be added here
      /*if (nssTeams.isEmpty() && String.isNotBlank(productsOfInterest)) {
         // create an array that is the maximum size of the available NSS Teams
         String[] foundNssTeams = new String[NBR_NSS_TEAMS];
         ProductGroupMapping__c foundPgm = null;
         
         // split up the product list
         String[] prodList = productsOfInterest.split(';');
         for (String prodName : prodList) {
            // make sure not longer than the field
            String key = (ReferralController.REF_NSS+'-'+prodName.trim()).left(NAME_FIELD_LENGTH);
            foundPgm = ProductGroupMapping__c.getInstance(key);
            System.debug('getNSSTeams key='+key+' foundPgm='+foundPgm);
            if (foundPgm != null && String.isNotBlank(foundPgm.NSS_Team__c)) {
               nssTeamMap = NSSTeamMap__c.getInstance(foundPgm.NSS_Team__c);
               System.debug('getNSSTeams nssTeamMap='+nssTeamMap+' NBR_NSS_TEAMS='+NBR_NSS_TEAMS);
               if (nssTeamMap != null && nssTeamMap.Priority__c != null && nssTeamMap.Priority__c < NBR_NSS_TEAMS) {
                  System.debug('getNSSTeams setting foundNssTeams');
                  foundNssTeams[nssTeamMap.Priority__c.intValue()] = nssTeamMap.Name;
               }
            } // if (foundPgm != null
         } // for (String prodName
         
         System.debug('getNSSTeams foundNssTeams='+foundNssTeams);
         for (String checkToken : foundNssTeams) {
            // put them in the order they're found, ignoring empty spaces
            if (checkToken != null) {
               nssTeams.add(checkToken);
            }
         }
      } // if (String.isNotBlank(productsOfInterest
      */
      // if no value set and there's a defaultValue passed in
      if (nssTeams.isEmpty() && String.isNotBlank(defaultValue)) {
         System.debug('getNSSTeams using default value');
         nssTeams.add(defaultValue);
      }
      
      // if no defaultValue is passed in, use PAY
      if (nssTeams.isEmpty()) {
         System.debug('getNSSTeams defaulting to core');
         nssTeams.add(UserHelper.SO_CORE);
      }
      return nssTeams;
   } // getNSSTeams
   
   // Get the "priority" of the passed in NSS Team. Lower number are higher priority - first record.
   public static Integer getPriority(String nssTeam) {
      Integer priority = null;
      
      if (String.isNotBlank(nssTeam)) {
         NSSTeamMap__c nssTeamMap = NSSTeamMap__c.getInstance(nssTeam);
         if (nssTeamMap != null) {
            priority = nssTeamMap.Priority__c.intValue();
         }
      } // if (String.isNotBlank
      
      return priority;
   } // getPriority
   
   /** Get the type of NSS ownership based on the value passed in. */
   public static String getOwnershipType(String nameToCheck) {
      // default the value
      String ownershipType = checkRecordTypeName(nameToCheck);
      return (String.isNotBlank(ownershipType) ? ownershipType : UserHelper.SO_CORE);
   } // ownershipType
   
   public static void checkRecordTypeName(String rtName, String[] nssTeams) {
      String nssTeam = checkRecordTypeName(rtName);
      if (String.isNotBlank(nssTeam)) {
         nssTeams.add(nssTeam);
      }
   } // checkRecordTypeName
   
   public static String checkRecordTypeName(String rtName) {
      String nssTeam = null;
      if (String.isNotBlank(rtName)) {
         // this should pick up Core and MMS being passed in
         for (String thisType : VALID_NSS_TEAMS) {
            if (rtName.contains(thisType)) {
               nssTeam = thisType;
               break;
            }
         } // for (String thisType
         if (String.isBlank(nssTeam)) {
            UserHelper uh = new UserHelper();
            if (uh.isHRS(rtName)) {
               nssTeam = UserHelper.SO_401;
            }
         } // if (String.isBlank
      } // if (String.isNotBlank
      return nssTeam;
   } // checkRecordTypeName
   
   /** Get the first active ownership record for the passed in stage.
       If stage is null, will return first open record
    */
   public static Prospect_Ownership__c getProspectingOwner(Prospect_Ownership__c[] owners, String stageName, String nssSource) {
      Prospect_Ownership__c po = null;
      if (owners != null && !owners.isEmpty()) {
         
         for (Prospect_Ownership__c checkPo : owners) {
            if (checkPo.EndDate__c == null && 
                (String.isBlank(stageName) || (String.isNotBlank(stageName) && checkPo.Ownership_Status__c == stageName)) &&
                (String.isBlank(nssSource) || (String.isNotBlank(nssSource) && checkPo.NSS_Source__c == nssSource))
               ) {
               po = checkPo;
               break;
            }
            
         } // for (Prospect_Ownership__c
      } // if (l.Prospect_Ownership__r
      return po;
   } // getProspectingOwner
   
   /** Get an ownership record by its primary key.
    */
   public static Prospect_Ownership__c getById(Id poId) {

      Prospect_Ownership__c po = null;
      
      String query = getProspectOwnerQuery(); //ObjectHelper.getSOQLQuery('Prospect_Ownership__c',null,true, false);
      try {
         po = Database.query(query + ' Where Id=:poId');
      } catch (Exception e) {
         // what do we need to do here?
      }
      return po;
   } // getById
   
   /** The contact fields for the ownership query */
   public static String[] CTCT_FIELDS = new String[]{'Decision_Maker__r.Id'
                                      ,'Decision_Maker__r.Name'
                                      ,'Decision_Maker__r.LeadSource'
                                      ,'Decision_Maker__r.OwnerId'
                                      ,'Decision_Maker__r.Hold_Out__c'
                                      ,'Decision_Maker__r.Hold_Out_Expiration__c'
                                      ,'Decision_Maker__r.Hold_Out_Reason__c'};
                                      
   public static String[] NSR_FIELDS = new String[]{'NSR_Name__r.Id'
                                      ,'NSR_Name__r.Name'
                                      ,'NSR_Name__r.IsActive'};
                                  
   public static String[] NSS_FIELDS = new String[]{'NSR_Name__r.Id'
                                      ,'NSR_Name__r.Name'
                                      ,'NSR_Name__r.IsActive'
                                      ,'NSR_Name__r.UserRoleId'
                                      ,'NSR_Name__r.ProfileId'
                                      ,'NSRSupervisor__r.Id'
                                      ,'NSRSupervisor__r.IsActive'
                                      ,'NSRSupervisor__r.Name'
                                      ,'Decision_Maker__r.NSSCallDisposition__c'
                                      ,'Decision_Maker__r.NSSStatus__c'
                                      ,'Decision_Maker__r.Hold_Out__c'
                                      ,'Decision_Maker__r.Hold_Out_Reason__c'
                                      ,'Lead__r.NSSCallDisposition__c'
                                      ,'Lead__r.Status'
                                      ,'Prospect_Client__r.NSSCallDisposition__c'
                                      ,'Prospect_Client__r.NSSStatus__c'
                                      };
                                  
   public static String[] NSS_FIELDS_NO_RELATED = new String[]{'NSR_Name__r.Id'
                                      ,'NSR_Name__r.Name'
                                      ,'NSR_Name__r.IsActive'
                                      ,'NSR_Name__r.UserRoleId'
                                      ,'NSR_Name__r.ProfileId'
                                      ,'NSRSupervisor__r.Id'
                                      ,'NSRSupervisor__r.IsActive'
                                      ,'NSRSupervisor__r.Name'
                                      };

   public static String PO_QUERY='Select Id, Name'+
                    ',CommissionEnd__c'+
                    ',CommissionStart__c'+
                    ',DaysLeftInStage__c'+
                    ',Decision_Maker__c'+
                    ',EndDate__c'+
                    ',EndDateVerified__c'+
                    ',LastVerified__c'+
                    ',Lead__c'+
                    ',Lead_Company__c'+
                    ',LockoutEnd__c'+
                    ',LockoutStart__c'+
                    ',NextCallback__c'+
                    ',NextCallbackDate__c'+
                    ',NextVerifyDate__c'+
                    ',NFI_WashEnd__c'+
                    ',NFI_WashStart__c'+
                    ',NSRIsActive__c'+
                    ',NSR_Name__c'+
                    ',NSR_NSS_Team__c'+
                    ',NSR_Role__c'+
                    ',NSRSupervisor__c'+
                    ',NSSAdminInfo__c'+
                    ',NSS_Source__c'+
                    ',NSS_Team__c'+
                    ',Opportunity__c'+
                    ',Opportunity_Stage__c'+
                    ',Ownership_Status__c'+
                    ',ProcessNotes__c'+
                    ',ProcessTracker__c'+
                    ',Prospect_Client__c'+
                    ',ProspectingEnd__c'+
                    ',ProspectingStart__c'+
                    ',Segment__c'+
                    ',Source__c'+
                    ',StartDate__c'+
                    ',StatusEndDate__c'+
                    ',StatusNbrDays__c'+
                    ',StatusStartDate__c'+
                    ',TransferredFrom__c'+
                    ',Verified__c'+
                    ',VerifyCount__c'+
                    ',VerifyNeeded__c'+
                    ',WorkableEnd__c'+
                    ',WorkableStart__c ';
   
   public static Map<Id,List<Prospect_Ownership__c>> getAcctOwnerMap(Set<Id> acctIdSet, Boolean allOpen, Date commissionStartDate, Date commissionEndDate) {
      return getAcctOwnerMap(acctIdSet, allOpen, commissionStartDate, commissionEndDate, null);
   }

   public static Boolean USE_STATIC_QUERY=(Label.ReferralQueries_UseStaticQuery=='Y');

   public static String getProspectOwnerQuery() {
      return getProspectOwnerQuery(false);
   } // getProspectOwnerQuery

   public static String getProspectOwnerQuery(Boolean includeRelatedFields) {
      if (USE_STATIC_QUERY) {
         if (includeRelatedFields) {
            String query = PO_QUERY+','+String.join(NSS_FIELDS,',')+' From Prospect_Ownership__c ';
            return query;
         }
         String query = PO_QUERY+','+String.join(NSS_FIELDS_NO_RELATED,',')+' From Prospect_Ownership__c ';
         return query;
      }
      if (includeRelatedFields) {
         return ObjectHelper.getSOQLQuery('Prospect_Ownership__c',NSS_FIELDS,true, false);
      }
      return ObjectHelper.getSOQLQuery('Prospect_Ownership__c',NSS_FIELDS_NO_RELATED,true, false);
   } // getProspectOwnerQuery

   /** Get all open ownership records that are linked to the passed in account ids.
    */
   public static Map<Id,List<Prospect_Ownership__c>> getAcctOwnerMap(Set<Id> acctIdSet, Boolean allOpen, Date commissionStartDate, Date commissionEndDate, String[] extraFields) {
      Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = new Map<Id,List<Prospect_Ownership__c>>();
      if (acctIdSet != null && !acctIdSet.isEmpty()) {
         String query = getProspectOwnerQuery(); //ObjectHelper.getSOQLQuery('Prospect_Ownership__c',extraFields,true, false);
         if (query != null) {
            query += ' Where Prospect_Client__c in :acctIdSet';
   
            if (allOpen) {
               query += ' and (EndDate__c = null';
            }
            
            if (commissionStartDate != null && commissionEndDate != null) {
               String whereOperator = allOpen ? ' or ' : ' and ';
               query += whereOperator+'(CommissionStart__c != null and CommissionStart__c <= :commissionEndDate and CommissionEnd__c >= :commissionStartDate)';
            }
            if (allOpen) {
               query += ')';
            }
            query += ' order by StartDate__c desc';
            System.debug('getAcctOwnerMap query='+query);
            Prospect_Ownership__c[] posRecs =  Database.query(query);

            for (Prospect_Ownership__c po : posRecs) {
               List<Prospect_Ownership__c> poList = acctOwnerMap.get(po.Prospect_Client__c);
               if (poList == null) {
                  poList = new List<Prospect_Ownership__c>();
                  acctOwnerMap.put(po.Prospect_Client__c,poList);
               }
               poList.add(po);
            } //for (Prospect_Ownership__c po
         } // if (query != null
      } // if (acctIdSet != null 
      return acctOwnerMap;
   } // getAcctOwnerMap
   
   /** Get all ownership records that are linked to an account
    */
   public static Prospect_Ownership__c[] getByAcctId(Id acctId) {
      Prospect_Ownership__c[] posRecs = null;
      if (acctId != null) {
         Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = getAcctOwnerMap(new Set<Id>{acctId}, true, null, null);
         posRecs = acctOwnerMap.get(acctId);
      } // if (acctId != null
      return posRecs;
   } // getByAcctId
   

   public static Integer hoursOffset = Integer.valueOf(System.Label.DialSourceCreatedDate);
      
   public static void MapDialSourceActionToPO(List<Prospect_Ownership__c>POs){
      MapDialSourceActionToPO(POs, null);
   }
   public static void MapDialSourceActionToPO(Prospect_Ownership__c[] pos, Map<Id,Prospect_Ownership__c> updateMap) {
      datetime queryTime = datetime.now(); 
      map<Id,Prospect_Ownership__c> poMap = new map<Id,Prospect_Ownership__c>();
      for (Prospect_Ownership__c po :POs) {
         Datetime dateCheck = null;
         if (po.DialSource_Action_That_Created_PO__c==null) {
            addToProcessTracker(po,'Attempting To Match to DialSource Action');
            if (po.Decision_Maker__c != null) {
               poMap.put(po.Decision_Maker__c,po);
               dateCheck = (po.CreatedDate != null ? po.CreatedDate : Datetime.now()).addhours(hoursOffset);
            }
            if (po.Lead__c != null) {
               poMap.put(po.Lead__c,po);
               dateCheck = (po.CreatedDate != null ? po.CreatedDate : Datetime.now()).addhours(hoursOffset);
            }
            if (po.Prospect_Client__c != null) {
               poMap.put(po.Prospect_Client__c,po);
               dateCheck = (po.CreatedDate != null ? po.CreatedDate : Datetime.now()).addhours(hoursOffset);
            } 
         }
         if (dateCheck != null && dateCheck < queryTime) {
            // find the earliest query time
            queryTime = dateCheck;
         }
      } // for (Prospect_Ownership__c po
      
      if (!poMap.isEmpty()) {
         Long maxMinutes = Math.abs(hoursOffset * 60);
         DS_Denali__DialSource_Action__c[] actions =[Select Id,DS_Denali__Lead__c,DS_Denali__Contact__c,DS_Denali__Account__c,CreatedDate 
                                                       from DS_Denali__DialSource_Action__c 
                                                      where (DS_Denali__Lead__c =:poMap.keyset() or DS_Denali__Contact__c =:poMap.keyset() or DS_Denali__Account__c =:poMap.keyset()) 
                                                        and CreatedDate >= :queryTime Order By CreatedDate DESC];

         for (DS_Denali__DialSource_Action__c action : actions)  {
            String matchBy='Contact';
            Prospect_Ownership__c po = (action.DS_Denali__Contact__c != null ? poMap.get(action.DS_Denali__Contact__c) : null);
            if (po == null) {
               po = (action.DS_Denali__Lead__c != null ? poMap.get(action.DS_Denali__Lead__c) : null);
               matchBy='Lead';
            }
            if (po == null) {
               po = (action.DS_Denali__Account__c != null ? poMap.get(action.DS_Denali__Account__c) : null);
               matchBy='Account';
            }
            if (po != null) {
               // make sure the records are within the specified amount of time
               Long millisecondsBetwen = ((po.CreatedDate != null ? po.CreatedDate : Datetime.now()).getTime() - action.CreatedDate.getTime());
               Long minutesBetween = Math.abs(millisecondsBetwen/60000);
               Long minutesDiff = (maxMinutes - minutesBetween);
               System.debug('MapDialSourceActionToPO minutesBetween='+minutesBetween+' millisecondsBetwen='+millisecondsBetwen+' minutesDiff='+minutesDiff);
               addToProcessTracker(po,'Max minutes='+maxMinutes+' minutes with action '+action.Id+'='+minutesBetween);
               if (minutesDiff >= 0) {
                  po.DialSource_Action_That_Created_PO__c = action.Id;
                  addToProcessTracker(po,'Matched to DialSource Action by '+matchBy);
               
                  if (updateMap != null && !updateMap.containsKey(po.Id)) {
                     updateMap.put(po.Id,po);
                  }
               } // if ((maxMinutes - minutesBetween
            }
         } // for (DS_Denali__DialSource_Action__c

      } // if (!poMap.isEmpty       

    } // MapDialSourceActionToPO
    
   public static Map<Id,Prospect_Ownership__c> getMapByLeadIds(Set<Id> leadIdSet) {
      return getMapByLeadIds(leadIdSet,null);
   }

    /** Get open ownership records that are linked to leads and contacts
    */ 
   public static Map<Id,Prospect_Ownership__c> getMapByLeadIds(Set<Id> leadIdSet, String[] extraFields) {
      Map<Id,Prospect_Ownership__c> leadOwnerMap = new Map<Id,Prospect_Ownership__c>();
      if (leadIdSet != null && !leadIdSet.isEmpty()) {
         String query = getProspectOwnerQuery(); //ObjectHelper.getSOQLQuery('Prospect_Ownership__c',extraFields,true, false);
         if (query != null) {
            query += ' Where Lead__c in :leadIdSet';
            query += ' and EndDate__c = null';
            query += ' order by StartDate__c desc';
            List<Prospect_Ownership__c> recs = (List<Prospect_Ownership__c>)Database.query(query);
            // put results into a map - should only have one active record per lead
            for (Prospect_Ownership__c po : recs) {
               leadOwnerMap.put(po.Lead__c,po);
            }
         } // if (query != null

      } // if (leadIds != null &&
      return leadOwnerMap;
   } // getMapByLeadIds
   
   // get open ownership records that are linked to a lead company
   public static Map<Id,List<Prospect_Ownership__c>> getMapByLeadCompanyIds(Set<Id> leadCompanyIdSet) {
      System.debug('getMapByLeadCompanyIds leadCompanyIdSet='+leadCompanyIdSet);
      Map<Id,List<Prospect_Ownership__c>> ownersByLeadCompanyMap = new Map<Id,List<Prospect_Ownership__c>>();
      if (leadCompanyIdSet != null && !leadCompanyIdSet.isEmpty()) {
         String query = getProspectOwnerQuery(); 
         if (query != null) {
            query += ' Where Lead_Company__c in :leadCompanyIdSet';
            query += ' and EndDate__c = null';
            query += ' order by StartDate__c asc ';
            System.debug('getMapByLeadCompanyIds query='+query);
            List<Prospect_Ownership__c> recs = (List<Prospect_Ownership__c>)Database.query(query);
            System.debug('getMapByLeadCompanyIds nbrRecs='+recs.size()+' query='+query);
            // put results into a map - should only have one active record per lead
            for (Prospect_Ownership__c po : recs) {
               List<Prospect_Ownership__c> ownerList = ownersByLeadCompanyMap.get(po.Lead_Company__c);
               if (ownerList == null) {
                  ownerList = new List<Prospect_Ownership__c>();
                  ownersByLeadCompanyMap.put(po.Lead_Company__c,ownerlist);
               }
               ownerlist.add(po);
            }
         } // if (query != null

      } // if (leadCompanyIdSet != null &&
      return ownersByLeadCompanyMap;
   } // getMapByLeadCompanyIds
   
   /** Get all ownership records that are linked to a user
    */
    /*
   public static Prospect_Ownership__c[] getOpenByUser(Id userId, Integer maxRecs) {
      Prospect_Ownership__c[] posRecs = null;
      if (userId != null) {
         String query = ObjectHelper.getSOQLQuery('Prospect_Ownership__c',null,true, true);
         if (query != null) {
            posRecs =  Database.query(query+' Where NSR_Name__c = :userId and EndDate__c = null order by StartDate__c desc limit :maxRecs');
         }
      } // if (acctId != null
      return posRecs;
   } // getByAcctId
   */
   
   public static String NSS_INBOUND='Inbound';
   public static String NSS_OUTBOUND='Outbound';
   public static Set<String> NSS_SOURCE_SET=new Set<String>{NSS_INBOUND,NSS_OUTBOUND};

   public static String getNSS_Source(User usr) {
      String nssSource = null;
      if (usr != null) {
         // define a source based on the NSS Team Map custom setting
         if (String.isNotBlank(usr.NSS_Team__c)) {
            NSSTeamMap__c ntm = NSSTeamMap__c.getInstance(usr.NSS_Team__c);
            nssSource = (ntm != null ? ntm.NSSSource__c : null);
         }
         // if nothing in team map, use the previous settings
         if (String.isBlank(nssSource)) {
            nssSource = getNSS_Source(usr.Profile.Name);
         }
      } // if (usr != null
      return nssSource;
   } // getNSS_Source
   
   // Get the NSS source based on a profile name. 
   public static String getNSS_Source(String profileName) {
      String source = null;
      if (String.IsNotBlank(profileName)) {
         if (UserHelper.isNSSInboundProf(profileName)) {
            source = NSS_INBOUND;
         } else {
            // if not inbound, default to outbound for now.
         //} else if (UserHelper.isNSSOutboundProf(profileName)) {
            source = NSS_OUTBOUND;
         //} else {
         //   source = 'None';
         }
      } // if (String.IsNotBlank
      System.debug('getNSS_Source source='+source);
      return source;
   } // getNSS_Source
   
   /** Add to the process notes on the ownership record.
    */
   public static void addToNotes(Prospect_Ownership__c po, String notesToAdd) {
      po.ProcessNotes__c = (String.isNotBlank(po.ProcessNotes__c) ? po.ProcessNotes__c+';' : '') + notesToAdd;
   } // addToNotes
   
   /** Initialize any objects we will use for saving changes. */
   public static void initializeSaveObjects() {
      upsertPosMap.clear();
      newATMMap.clear();
      delATMMap.clear();
      saveAcctMap.clear();
      saveLeadMap.clear();
      leadCompanyMap.clear();
      saveCtctMap.clear();
      expiredIds.clear();
   } // initializeSaveObjects
   
   /** Check if any saving needs to occur.
    */
   public static Boolean checkForSaves() {
      Boolean okay = true;
      System.debug('checkForSaves method entry upsertPosMap='+upsertPosMap.size());
      // the ownership records
      checkPoSave();
      
      // the new account team members
      if (!newATMMap.isEmpty()) {
         Database.insert(newATMMap.values(),false);
      }
      //saveRecords(DML_INSERT, newATMMap.values(), 'checkForSaves', 'Insert newATMMap');
      
      // the account team members to delete
      if (!delATMMap.isEmpty()) {
         Database.delete(delATMMap.values(),false);
      }
      //saveRecords(DML_DELETE, delATMMap.values(), 'checkForSaves', 'Delete delATMMap');
      
      System.debug('checkForSaves number of accts='+saveAcctMap.size());
      saveRecords(DML_UPDATE, saveAcctMap.values(), 'checkForSaves', 'Update saveAcctMap');
      
      if (!saveLeadMap.isEmpty()) {
         Database.DMLOptions dlo = new Database.DMLOptions();
         dlo.EmailHeader.triggerAutoResponseEmail = false;
         dlo.EmailHeader.triggerUserEmail = false;
         dlo.EmailHeader.triggerOtherEmail = false;
         dlo.OptAllOrNone = false;
         DmlHelper.performDML2(saveLeadMap.values(), DmlHelper.DML_UPDATE, 'ProspectOwnershipMethods', 'checkForSaves', 'update leads',false,dlo);
         /*
         Database.SaveResult[] results = Database.update(saveLeadMap.values(), dlo);
         for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
               String errorStr = '';
               for(Database.Error err : result.getErrors()) {
                  errorStr += (err.getStatusCode() + ': ' + err.getMessage()+' ');
               }
               ErrorLog.logError('ProspectOwnershipMethods', 'checkForSaves', 'update leads', result.getId(), errorStr);
            }
         } // for (Database.SaveResult result
         */
      } // if (!saveLeadMap
      
      saveRecords(DML_UPDATE, leadCompanyMap.values(), 'checkForSaves', 'Update leadCompanyMap');
      
      saveRecords(DML_UPDATE, saveCtctMap.values(), 'checkForSaves', 'Update saveCtctMap');
      
      if (!expiredIds.isEmpty()) {
          Task[] futureTaskList = [Select Id from Task where IsClosed = false
                              and Type = :TaskHelper.CT_CALLBACK and ReminderDateTime >= :Date.today()
                              and (AccountId in :expiredIds or WhoId in :expiredIds)
                              and OwnerId in :expiredIds];
          if (!futureTaskList.isEmpty())
          { saveRecords(DML_DELETE, futureTaskList, 'checkForSaves', 'Delete futureTaskList');  }                              
      } // if (!expiredIds.isEmpty
      
      ErrorLog.checkSave();
      return okay;
   } // checkForSaves
   
   public static Boolean checkPoSave() {
      Boolean okay = true;
      if (!upsertPosMap.isEmpty()) {
         // if we delete PO records, let's look for any other open ones and clear the last verified date to force them through the
         // verify process again.
         Set<Id> deleteIds = new Set<Id>();
         Prospect_Ownership__c[] deletePOs = new Prospect_Ownership__c[]{};
         Prospect_Ownership__c[] updatePOs = new Prospect_Ownership__c[]{};
         Prospect_Ownership__c[] insertPOs = new Prospect_Ownership__c[]{};
         
         for (Prospect_Ownership__c po : upsertPosMap.values()) {
            if (po.Ownership_Status__c == STAGE_EXPIRED && po.Id != null && po.StartDate__c == po.EndDate__c && po.CommissionStart__c == null) {
               // if the start and end date are the same day, let's delete the ownership.
               // if there's no id, and it's set to expired, we won't insert the record
                  if (po.Prospect_Client__c != null) {
                     deleteIds.add(po.Prospect_Client__c);
                  } else if (po.Lead__c != null) {
                     deleteIds.add(po.Lead__c);
                  }
                  deletePOs.add(po);
            } else if (po.Ownership_Status__c == STAGE_EXPIRED && po.Id == null && po.CommissionStart__c == null) {
               // do nothing if it doesn't already exist?
            } else {
               if (po.Id == null) {
                  insertPOs.add(po);
               } else {
                  updatePOs.add(po);
               }
            } // if (po.Ownership_Status__c == STAGE_EXPIRED
         } // for (Prospect_Ownership__c po
         
         saveRecords(DML_DELETE, deletePOs, 'checkPoSave', 'Delete deletePOs');
         saveRecords(DML_INSERT, insertPOs, 'checkPoSave', 'Insert insertPOs');
         saveRecords(DML_UPDATE, updatePOs, 'checkPoSave', 'Update updatePOs');
         
         if (!deleteIds.isEmpty()) {
            Prospect_Ownership__c[] lastVerifyUpdate = [Select Id, LastVerified__c
                                                          From Prospect_Ownership__c
                                                         Where EndDate__c = null
                                                           and LastVerified__c != null
                                                           and (Prospect_Client__c in :deleteIds
                                                                or Lead__c in :deleteIds)];
            for (Prospect_Ownership__c po : lastVerifyUpdate) {
               po.LastVerified__c = null;
            }
            saveRecords(DML_UPDATE, lastVerifyUpdate, 'checkPoSave', 'Update lastVerified');
         } // if (!deleteIds.isEmpty()
      } // if (!upsertPosMap.isEmpty
      return okay;
   } // checkPoSave
   
   public static final String DML_INSERT=DmlHelper.DML_INSERT;
   public static final String DML_UPDATE=DmlHelper.DML_UPDATE;
   public static final String DML_UPSERT=DmlHelper.DML_UPSERT;
   public static final String DML_DELETE=DmlHelper.DML_DELETE;
   
   public static void saveRecords(String saveType, List<Sobject> recs, String methodName, String codeKey) {
      if (!recs.isEmpty()) {
         DmlHelper.performDML2(recs, saveType, 'ProspectOwnershipMethods', methodName, codeKey,false);
         /*
         System.debug('saveRecords methodName='+methodName+' codeKey='+codeKey+' nbrRecs='+recs.size());
         try {
            if (saveType == DML_INSERT) {
               insert recs;
            } else if (saveType == DML_UPDATE) {
               update recs;
            } else if (saveType == DML_UPSERT) {
               upsert recs;
            } else if (saveType == DML_DELETE) {
               delete recs;
            }
         } catch (Exception e) {
            SObject firstRec = (!recs.isEmpty() ? recs[0] : null);
            Id firstRecId = (firstRec != null ? firstRec.Id : null);
            ErrorLog.logError('ProspectOwnershipMethods', methodName, codeKey, firstRecId, e, firstRec);
         }
         */
      } // if (!recs.isEmpty
   } // saveRecords
   
   // Account team members we are creating.
   public static Map<String,AccountTeamMember> newATMMap = new Map<String,AccountTeamMember>();
   // Account team members we are deleting
   public static Map<Id,AccountTeamMember> delATMMap = new Map<Id,AccountTeamMember>();
   
   // For accounts that get updated - map is used so an account is only added in once
   public static Map<Id,Account> saveAcctMap = new Map<Id,Account>();
   // for leads that get updated - map is used so a lead is only added in once
   public static Map<Id,Lead> saveLeadMap = new Map<Id,Lead>();
   // for the lead companies
   public static Map<Id,Lead_Company__c> leadCompanyMap = new Map<Id,Lead_Company__c>();
   // for contacts that get updated - map is used so a contact is only added in once
   public static Map<Id,Contact> saveCtctMap = new Map<Id,Contact>();
   // for the Prospect_Ownership__c records to save
   public static Map<String,Prospect_Ownership__c> upsertPosMap = new Map<String,Prospect_Ownership__c>();
   
   // the ids of records (leads or accounts) that are expired - we will delete future callbacks.
   public static Set<Id> expiredIds = new Set<Id>();
   
   // verify all of the stage information - all the settings for the stage are correct.
   public static Boolean verifyStage(Prospect_Ownership__c po, Account acct, Contact ctct, AccountTeamMember[] atms, Lead ld) {
      Boolean changed = false;
      // get the setting info
      LifeOfLeadSettings__c lols = getSetting(po);
      System.debug('setStageEntryInfo lols='+lols);
      if (lols != null) {
         changed = true;
         // if there's an end date and we have an active setting, expire the record.
         if (po.EndDate__c != null) {
            setStageExitInfo(po, acct, ctct, atms, ld, true, false, true);
         } else if (acct != null) {
            checkAcctOwner(lols, acct, ctct, atms, po);
         } else if (ld != null) {
            // make sure the owner of the lead matches the ownership
            checkLeadOwner(lols, ld, po);
         }
      } // if (lols != null
      if (changed) {
         addToUpsertMap(po, false);
      }
      return changed;
   } // verifyStage
   
   // if the stage is expired, verify that everything is as it should be
   public static Boolean setExpired(Prospect_Ownership__c po, Account acct, Contact ctct, AccountTeamMember[] atms, Lead ld, Boolean deleteOpenCallbacks, String p_assignToQueue) {
      Boolean changed=false;
      LifeOfLeadSettings__c lols = getSetting(po);
      String assignToQueue = ((lols != null && String.isNotBlank(lols.AssignToQueue__c)) ? lols.AssignToQueue__c : p_assignToQueue);
      
      if (po.Ownership_Status__c == STAGE_EXPIRED) {
         System.debug('verifyExpired handling expired po='+po.Name);
         if (po.EndDate__c == null) {
            po.EndDate__c = Date.today();
         }
         po.StatusNbrDays__c = null;
         // if there's an account team member, remove it
         System.debug('verifyExpired acct='+acct);
         // if we're expiring the ownership, make sure that it actually was created first before modifying any other records
         if (po.Id != null) {
            if (acct != null) {
               AccountTeamMember atm = findATM((atms != null ? atms : acct.AccountTeamMembers),po.NSR_Name__c);
               if (atm != null) {
                  delATMMap.put(atm.Id,atm);
               }
               // the ids we'll check for open callbacks
               if (deleteOpenCallbacks) {
                  expiredIds.add(acct.Id);
                  // include the NSR to only delete their open callbacks
                  expiredIds.add(po.NSR_Name__c);
               }
               
               String textToAdd = (String.isBlank(po.ProcessTracker__c) ? '' : po.ProcessTracker__c+'\n')+String.valueOf(System.Now())+'\n';
               textToAdd += 'verifyExpired po.NSS_Source__c='+po.NSS_Source__c+'.\n';
               System.debug('verifyExpired po.NSS_Source__c='+po.NSS_Source__c+'.');
               if (po.NSS_Source__c == NSS_INBOUND) {
                  textToAdd += 'verifyExpired resetting inbound flag\n';
                  System.debug('verifyExpired resetting inbound flag');
                  acct.AssignedToInboundNSR__c = false;
               } else if (po.NSS_Source__c == NSS_OUTBOUND) {
                  textToAdd += 'verifyExpired resetting outbound flag\n';
                  System.debug('verifyExpired resetting outbound flag');
                  acct.AssignedToOutboundNSR__c = false;
               }
               addToProcessTracker(po, textToAdd);
                  
               //acct.Assigned_to_NSR__c = false;
               saveAcctMap.put(acct.Id,acct);
                  
               Contact checkCtct = checkContacts(acct,ctct,po.Decision_Maker__c,false,null, po, null);
               if (checkCtct != null) {
                  ctct = checkCtct;
               }
            } // if (acct != null
            if (ld != null) {
               // clear out the start date on the lead
               ld.NSS_Ownership_Start_Date__c = null;
               if (lols != null) {
                  // change the ownership to the pending queue
                  LeadMethods.assignQueueToLead(lols.AssignToQueue__c,ld);
               }
               // the ids we'll check for open callbacks
               if (deleteOpenCallbacks) {
                  expiredIds.add(ld.Id);
                  // include the NSR to only delete their open callbacks
                  expiredIds.add(po.NSR_Name__c);
               }
               saveLeadMap.put(ld.Id,ld);
            } // if (ld != null
         } // if (po.Id != null
      } // if (po.Ownership_Status__c
      return changed;
   } // setExpired
   
   /** When entering a stage, set the info based on the custom setting.
    *  @param endStageAndOwnership - end date the stage/ownership immediately.
    */
   public static Boolean setStageEntryInfo(Prospect_Ownership__c po, Account acct, Contact ctct, AccountTeamMember[] atms, Lead ld, Boolean setComIfAvail, Boolean endStageAndOwnership) {
      Boolean changed = false;
      
      // get the setting info
      LifeOfLeadSettings__c lols = getSetting(po);
      System.debug('setStageEntryInfo lols='+lols);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'setStageEntryInfo lols='+lols));
      
      if (lols != null) {
         changed = true;
         // only populate the start date field if it's blank
         if (lols.StageStartDateField__c != null && po.get(lols.StageStartDateField__c) == null) {
            po.LastVerified__c = null;
            po.put(lols.StageStartDateField__c,Date.today());
            addToProcessTracker(po,'setStageEntryInfo Set Start Date Field '+lols.StageStartDateField__c);
            System.debug('setStageEntryInfo startDateField='+lols.StageStartDateField__c);
         }
         // set the number of days to the current status
         po.StatusNbrDays__c = lols.NumOfDays__c;
         
         // check if we're setting the commission period
         if (setComIfAvail && lols.NumComDays__c != null && lols.NumComDays__c > 0) {
            addToProcessTracker(po,'setStageEntryInfo Set Commission Start and End');
            po.CommissionStart__c = Date.today();
            po.CommissionEnd__c = Date.today().addDays(lols.NumComDays__c.intValue());
            System.debug('setStageEntryInfo CommissionStart__c='+po.CommissionStart__c+' CommissionEnd__c='+po.CommissionEnd__c);
         }
         
         if (acct != null) {
            checkAcctOwner(lols, acct, ctct, atms, po);
            if (lols.DeleteCallbacksOnEntry__c) {
               expiredIds.add(acct.Id);
               // include the NSR to only delete their open callbacks
               expiredIds.add(po.NSR_Name__c);
            }
         } else if (ld != null) {
            // make sure the owner of the lead matches the ownership
            checkLeadOwner(lols, ld, po);
            if (lols.DeleteCallbacksOnEntry__c) {
               expiredIds.add(ld.Id);
               // include the NSR to only delete their open callbacks
               expiredIds.add(po.NSR_Name__c);
            }
         }

         // if we're going to end the stage and ownership immediately. This doesn't touch the account or lead
         if (endStageAndOwnership) {
            if (lols.StageEndDateField__c != null) {
               po.put(lols.StageEndDateField__c,Date.today());
               addToProcessTracker(po,'setStageEntryInfo Set End Date Field '+lols.StageEndDateField__c);
            }
            System.debug('setStageEntryInfo setting EndDate__c');
            po.EndDate__c = Date.today();
            po.StatusNbrDays__c = null;
            po.Ownership_Status__c = STAGE_EXPIRED;
         } // if (nsrAlreadyHasLockout
         
      } // if (lols != null
      
      System.debug('setStageEntryInfo changed='+changed);
      if (changed) {
         addToUpsertMap(po, false);
      }
      return changed;
   } // setStageEntryInfo
     
   /** When exiting a stage, set the info based on the custom setting.
    @param allowExpire - do we allow this to expire at the end of the stage? 
    @param deleteOpenCallBacks - do we delete the open call backs if we are expiring this record?
    @param forceExpire - do we force the expiration of this record (even if there's another stage to go to)?
    */
   public static Boolean setStageExitInfo(Prospect_Ownership__c po, Account acct, Contact ctct, AccountTeamMember[] atms, Lead ld, Boolean allowExpire, Boolean deleteOpenCallbacks, Boolean forceExpire) {
      Boolean changed = false;
      
      // get the setting info
      LifeOfLeadSettings__c lols = getSetting(po);
      System.debug('setStageExitInfo lols='+lols);
      
      if (lols != null) {
         changed = true;
         Date stageStartDate = null;
         if (lols.StageStartDateField__c != null) {
            stageStartDate = (Date)po.get(lols.StageStartDateField__c);
         }
         po.StatusNbrDays__c = null;
         
         if (stageStartDate != null) {
            po.LastVerified__c = null;
            if (lols.StageEndDateField__c != null) {
               po.put(lols.StageEndDateField__c,Date.today());
               addToProcessTracker(po,'setStageExitInfo Set End Date Field '+lols.StageEndDateField__c);
            }
         
            if (lols.NextOwnershipStage__c != null) {
               po.Ownership_Status__c = lols.NextOwnershipStage__c;
               addToProcessTracker(po,'setStageExitInfo set next ownership stage '+lols.NextOwnershipStage__c);
            }
         
            System.debug('setStageExitInfo allowExpire='+allowExpire+' lols.IsExpiredAtEnd__c='+lols.IsExpiredAtEnd__c+' deleteOpenCallbacks='+deleteOpenCallbacks);
            if (forceExpire || (allowExpire && lols.IsExpiredAtEnd__c)) {
               System.debug('setStageExitInfo setting EndDate__c');
               po.Ownership_Status__c = STAGE_EXPIRED;
               addToProcessTracker(po,'setStageExitInfo force expire');
               setExpired(po, acct, ctct, atms, ld, deleteOpenCallbacks, lols.AssignToQueue__c);
/*
               po.EndDate__c = Date.today();

               // if there's an account team member, remove it
               System.debug('setStageExitInfo acct='+acct);
               if (acct != null) {
                  AccountTeamMember atm = findATM((atms != null ? atms : acct.AccountTeamMembers),po.NSR_Name__c);
                  if (atm != null) {
                     delATMMap.put(atm.Id,atm);
                  }
                  // the ids we'll check for open callbacks
                  if (deleteOpenCallbacks) {
                     expiredIds.add(acct.Id);
                     // include the NSR to only delete their open callbacks
                     expiredIds.add(po.NSR_Name__c);
                  }
                  System.debug('setStageExitInfo po.NSS_Source__c='+po.NSS_Source__c+'.');
                  if (po.NSS_Source__c == NSS_INBOUND) {
                     System.debug('setStageExitInfo resetting inbound flag');
                     acct.AssignedToInboundNSR__c = false;
                  } else if (po.NSS_Source__c == NSS_OUTBOUND) {
                     System.debug('setStageExitInfo resetting outbound flag');
                     acct.AssignedToOutboundNSR__c = false;
                  }
                  
                  //acct.Assigned_to_NSR__c = false;
                  saveAcctMap.put(acct.Id,acct);
                  
                  Contact checkCtct = checkContacts(acct,ctct,po.Decision_Maker__c,false,null, po, null);
                  if (checkCtct != null) {
                     ctct = checkCtct;
                  }
               }
               if (ld != null) {
                  // clear out the start date on the lead
                  ld.NSS_Ownership_Start_Date__c = null;
                  // change the ownership to the pending queue
                  LeadMethods.assignQueueToLead(lols.AssignToQueue__c,ld);
                  // the ids we'll check for open callbacks
                  if (deleteOpenCallbacks) {
                     expiredIds.add(ld.Id);
                     // include the NSR to only delete their open callbacks
                     expiredIds.add(po.NSR_Name__c);
                  }
                  saveLeadMap.put(ld.Id,ld);
               }
               */
            } // if (lols.IsExpiredAtEnd__c
            
            if (lols.NextLeadStatus__c != null) {
               if (ld != null) {
                  ld.Status = lols.NextLeadStatus__c;
                  saveLeadMap.put(ld.Id,ld);
               }
               if (acct != null) {
                  if (ctct != null && ctct.NSSStatus__c != lols.NextLeadStatus__c) {
                     ctct.NSSStatus__c = lols.NextLeadStatus__c;
                     saveCtctMap.put(ctct.id,ctct);
                  }
                  if (acct.NSSStatus__c != lols.NextLeadStatus__c) {
                     acct.NSSStatus__c = lols.NextLeadStatus__c;
                     saveAcctMap.put(acct.Id,acct);
                  }
               }
            } // if (lols.NextLeadStatus__c != null
            
         } // if (startDate != null
      } // if (lols != null
      if (changed) {
         addToUpsertMap(po, false);
      }
      return changed;
   } // setStageExitInfo
   
   public static Boolean checkLeadOwner(LifeOfLeadSettings__c lols, Lead ld, Prospect_Ownership__c po) {
      Boolean changed = false;
      // make sure the owner of the lead matches the ownership
      if (ld != null && lols.OwnedByNSR__c) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'checkLeadOwner ld.OwnerId='+ld.OwnerId+' po.NSR_Name__c='+po.NSR_Name__c));
         if (lols.OwnedByNSR__c && ld.OwnerId != po.NSR_Name__c) {
            ld.OwnerId = po.NSR_Name__c;
            //ChangeLog.addToLog(ld.Id, 'OwnerId', ld.OwnerId);
            // we don't want the email generated
            Database.DMLOptions dlo = new Database.DMLOptions();
            dlo.EmailHeader.triggerAutoResponseEmail = false;
            dlo.EmailHeader.triggerUserEmail = false;
            dlo.EmailHeader.triggerOtherEmail = false;
            ld.setOptions(dlo);
            changed = true;
         } else if (!lols.OwnedByNSR__c && String.IsNotBlank(lols.QueueOwnerDuringStage__c) && LeadMethods.assignQueueToLead(lols.QueueOwnerDuringStage__c, ld)) {
            changed = true;
         }
         
         // make sure the lead company is set
         if (po.Lead_Company__c != ld.Lead_Company__c) {
            po.Lead_Company__c = ld.Lead_Company__c;
            changed = true;
         }
         
         if (ld.Lead_Company__r != null) {
            if (ld.Lead_Company__r.SignificantLead__c != ld.Id) {
               ld.Lead_Company__r.SignificantLead__c = ld.Id;
               changed = true;
               leadCompanyMap.put(ld.Lead_Company__r.Id, ld.Lead_Company__r);
            }
         } // if (ld.Lead_Company__r
            
         if (ld.NSS_Ownership_Start_Date__c == null) {
            ld.NSS_Ownership_Start_Date__c = (Date)po.get(lols.StageStartDateField__c);
            changed = true;
         }
         
         if (String.isNotBlank(lols.LeadStatusDuringStage__c) && ld.Status != lols.LeadStatusDuringStage__c) {
            ld.Status = lols.LeadStatusDuringStage__c;
            changed = true;
         }
         
         if (changed) {
            saveLeadMap.put(ld.Id,ld);
         }
      } // if (ld != null
      return changed;
   } // checkLeadOwner
   
   public static Boolean checkAcctOwner(LifeOfLeadSettings__c lols, Account acct, Contact ctct, AccountTeamMember[] atms, Prospect_Ownership__c po) {
      Boolean changed = false;   
      if (po.NSS_Source__c == NSS_INBOUND && !acct.AssignedToInboundNSR__c) {
         System.debug('setStageEntryInfo setting inbound flag');
         acct.AssignedToInboundNSR__c = true;//lols.OwnedByNSR__c;
         //ChangeLog.addToLog(acct.Id, 'AssignedToInboundNSR__c', 'true');
         changed = true;
      } else if (po.NSS_Source__c == NSS_OUTBOUND && !acct.AssignedToOutboundNSR__c) {
         System.debug('setStageEntryInfo setting outbound flag');
         acct.AssignedToOutboundNSR__c = true;//lols.OwnedByNSR__c;
         //ChangeLog.addToLog(acct.Id, 'AssignedToOutboundNSR__c', 'true');
         changed = true;
      }
      
      if (String.isNotBlank(lols.LeadStatusDuringStage__c) && acct.NSSStatus__c != lols.LeadStatusDuringStage__c) {
         acct.NSSStatus__c = lols.LeadStatusDuringStage__c;
         changed = true;
      }
      
      if (changed) {
         saveAcctMap.put(acct.Id,acct);
      }
      checkContacts(acct,ctct,po.Decision_Maker__c,lols.SetAccountTeam__c,po.NSR_Name__c,po, lols.LeadStatusDuringStage__c);
            
      // check the account team member
      AccountTeamMember atm = findATM((atms != null ? atms : acct.AccountTeamMembers),po.NSR_Name__c);
      if (lols.SetAccountTeam__c && atm == null) { // && po.NSR_Name__r != null && po.NSR_Name__r.IsActive) {
         atm = new AccountTeamMember(AccountId=acct.Id, UserId=po.NSR_Name__c, TeamMemberRole='NSR',AccountAccessLevel='Edit', ContactAccessLevel='Edit',OpportunityAccessLevel='Read' );
         // make sure only saving one atm per account per user
         newATMMap.put((String)acct.Id+(String)atm.UserId, atm);
         //ChangeLog.addToLog(acct.Id, 'NewTeamMember', po.NSR_Name__c);
      } else if (!lols.SetAccountTeam__c && atm != null) {
         delATMMap.put(atm.Id,atm);
      }            
      return changed;
   } // checkAcctOwner
   
   /** Get the setting for the current stage of the ownership record.
    */
   public static LifeOfLeadSettings__c getSetting(Prospect_Ownership__c po) {
      LifeOfLeadSettings__c lols = null;
      if (po != null) {
         //System.debug('getSetting key='+key+' lols='+lols);
         lols = getSetting(po.Ownership_Status__c,po.NSS_Team__c,po.NSS_Source__c,po.Segment__c);
      }
      return lols;
   } // getSetting
   
   /** We want to try not to use this (to keep the call generic), but it's here just in case. */
   public static LifeOfLeadSettings__c getSetting(String ownerStatus, String nssTeam, String nssSource, String segment) {
      String key = RecordTypeHelper.cleanRtName(ownerStatus+'-'+nssTeam+'-'+nssSource+'-'+segment);
      // get the setting info
      LifeOfLeadSettings__c lols = LifeOfLeadSettings__c.getInstance(key);
      if (lols == null)
      {    key = RecordTypeHelper.cleanRtName(ownerStatus+'-'+nssTeam+'-'+nssSource);
          lols = LifeOfLeadSettings__c.getInstance(key);
      }
      System.debug('getSetting key='+key+' lols='+lols);
      return lols;
   } // getSetting
   
   /** Find an account team member.
    */
   public static AccountTeamMember findATM(List<AccountTeamMember> atms, Id userId) {
      AccountTeamMember foundATM = null;
      if (atms != null && !atms.isEmpty() && userId != null) {
         for (AccountTeamMember atm : atms) {
            if (atm.UserId == userId) {
               foundATM = atm;
               break;
            }
         } // for (AccountTeamMember atm
      } // if (atms != null &&
      return foundATM;
   } // findATM
   
   public static String NSS_HOLDOUT='NSR Working';
   
   //            Contact checkCtct = checkContacts(acct,ctct,po.Decision_Maker__c,false,null, po, null);
   
   /** Check the contacts of an account. If the holdout flag needs to be set, use
       the passed in NSR id for the owner. Otherwise remove the (NSR) holdout if it exists.
    */
   public static Contact checkContacts(Account acct, Contact p_ctct, Id ctctId, Boolean setHoldout, Id nsrId, Prospect_Ownership__c po, String ctctStatus) {
      
      Contact foundCtct = p_ctct;
      
      if (foundCtct == null && acct != null) {
         foundCtct = AccountMethods.findContact(acct, acct.Contacts, ctctId, null);
      }
            
      if (foundCtct != null) {
         Boolean ctctChanged = false;
         
         if (po != null && po.Decision_Maker__c != foundCtct.Id) {
            // if the contact changes, remove the hold out on the previous contact.
            if (po.Decision_Maker__c != null) {
               Contact oldCtct = new Contact(Id=po.Decision_Maker__c, Hold_Out__c=false, Hold_Out_Reason__c=null, Use_Zip_Assignment_Rules__c=true);
               saveCtctMap.put(oldCtct.id,oldCtct);
            }
            po.Decision_Maker__c = foundCtct.Id;
            addToUpsertMap(po,false);
         }
         if (acct != null && acct.SignificantContact__c != foundCtct.Id) {
            acct.SignificantContact__c = foundCtct.Id;
            saveAcctMap.put(acct.Id,acct);
         }
         if (setHoldout && !foundCtct.Hold_Out__c) {
            ctctChanged = true;
            foundCtct.Hold_Out__c = true;
            foundCtct.Hold_Out_Reason__c = NSS_HOLDOUT;
            foundCtct.OwnerId = nsrId;
            foundCtct.BypassHoldout__c = true;
            //ChangeLog.addToLog(foundCtct.Id, 'Hold_Out__c', 'true');

         } else if (!setHoldout && ((foundCtct.Hold_Out__c && foundCtct.Hold_Out_Reason__c == NSS_HOLDOUT)
                                    || (!foundCtct.Hold_Out__c && foundCtct.OwnerId == po.NSR_Name__c))) {
            ctctChanged = true;
            // only remove an NSS holdout
            foundCtct.Hold_Out__c = false;
            foundCtct.Hold_Out_Reason__c = null;
            foundCtct.Use_Zip_Assignment_Rules__c = true;
         }

         if (String.isNotBlank(ctctStatus) && foundCtct.NSSStatus__c != ctctStatus) {
            ctctChanged = true;
            foundCtct.NSSStatus__c = ctctStatus;
         }
         
         if (ctctChanged) {
            CheckDataGovernance.SKIP_DATA_GOVERNANCE=true;
            // to make sure the ownership is processed
            ZipCheckOwner.accountIdsProcessedSet.remove(foundCtct.AccountId);
            // add it to the save map
            saveCtctMap.put(foundCtct.id,foundCtct);
         }
      } // if (foundCtct != null
      
      return foundCtct;
   } // checkContacts
   
   /** looking at lead or account, determine Zip Segment
   */
   public static String determineSegment(String p_zip, String p_nssTeam, SObject p_sobject) {
System.debug('**CMF ** here at determineSegment, p_+zip='+p_zip+' p_nssTeam='+p_nssTeam+' p_sobject.Name='+p_sobject.get('Name'));      
        List<String> salesOrgList = new List<String>();
        salesOrgList.add(p_nssTeam);        
        List<Zip_Segment__c> zipSegmentList = ZipQueries.getSegments(salesOrgList);
        Zip_Assignment__c dummyZip;
        Boolean goodZipSeg;
        String objectName = (ObjectHelper.getObjectName(p_sobject));
        
        // go backwards through ZipSegment to get the one we want (ex. Large Market before Small Market)
        Integer sortOrder = zipSegmentList.size() - 1;          
        for (integer idx = sortOrder; idx > -1; idx--)
        {   dummyZip = new Zip_Assignment__c(OwnerId = UserInfo.getUserId()
                                        ,Name = p_zip
                                        ,Sales_Org__c = p_nssTeam
                                        ,Segment_Name__c = zipSegmentList.get(idx).Name
                                        ,Zip_Segment__r = zipSegmentList.get(idx));
            goodZipSeg = ZipCheckOwner.objectMatchesZip(p_sobject, objectName, dummyZip, zipSegmentList.get(idx), true);
System.debug('**CMF ** determineSeg-goodZipSeg='+goodZipSeg);               
            if (goodZipSeg)
            {   return dummyZip.Segment_Name__c;    }                   
        }
        return null;
            
   } // determineSegment
    
    
   // set the manager of the NSR as the supervisor at the time the opportunity is set
   public static void setNsrSupervisor(Map<Id,Prospect_Ownership__c[]> poByNsrMap) {
      // get the users
      User[] users = [Select Id, ManagerId from User where Id in :poByNsrMap.keySet() and ManagerId != null];
      System.debug('setNsrSupervisor users='+users.size());
      for (User usr : users) {
         Prospect_Ownership__c[] poList = poByNsrMap.get(usr.Id);
         if (poList != null) {
            for (Prospect_Ownership__c po : poList) {
               po.NSRSupervisor__c = usr.ManagerId;
            }
         } // if (poList != null
      } // for (User usr : users
   } // setNsrSupervisor
   
   // this is to account for callbacks being inserted before the prospect ownership record exists.
   public static void checkForCallbacks(Prospect_Ownership__c[] recs, Map<Id,Prospect_Ownership__c> oldMap) {
      Map<Id,Id[]> poIdByRecIdMap = new Map<Id,Id[]>();
      Map<Id,Id> poOwnerIdMap = new Map<Id,Id>();
      for (Prospect_Ownership__c po : recs) {
         // non ended PO record and only prospecting or workable
         if (po.EndDate__c == null && po.NSR_Name__c != null 
               && (po.ProspectingStart__c != null  || po.WorkableStart__c != null)) {
            checkAddToMap(po.Decision_Maker__c, po.Id, poIdByRecIdMap);
            checkAddToMap(po.Lead__c, po.Id, poIdByRecIdMap);
            checkAddToMap(po.Prospect_Client__c, po.Id, poIdByRecIdMap);
            poOwnerIdMap.put(po.Id, po.NSR_Name__c);
         }
      } // for (Prospect_Ownership__c po
      
      if (!poIdByRecIdMap.isEmpty()) {
         checkForCallbackTasks(poIdByRecIdMap, poOwnerIdMap);
      }
   } // checkForCallbacks
   
   public static void checkAddToMap(Id sourceId, Id poId, Map<Id,Id[]> poIdByRecIdMap) {
      if (sourceId != null) {
         Id[] poIds = (poIdByRecIdMap.containsKey(sourceId) ? poIdByRecIdMap.get(sourceId) : new Id[]{});
         poIds.add(poId);
         poIdByRecIdMap.put(sourceId, poIds);
      }
   } // checkAddToMap
   
   public static void checkForCallbackTasks(Map<Id,Id[]> poIdByRecIdMap, Map<Id,Id> poOwnerIdMap) {
      System.debug('checkForCallbackTasks poIdByRecIdMap='+poIdByRecIdMap.size());
      Task[] tsks = [Select Id, OwnerId, AccountId, WhoId, WhatId
                           ,ReminderDateTime
                       From Task
                      Where IsClosed=false
                        and Type = :TaskHelper.CT_CALLBACK
                        and ReminderDateTime != null
                        and ReminderDateTime >= :Datetime.now()
                        and (AccountId in :poIdByRecIdMap.keySet()
                             or WhoId in :poIdByRecIdMap.keySet()
                             or WhatId in :poIdByRecIdMap.keySet())];
                             
      // so we can make sure we only create one record for each task id
      Map<Id,ProspectOwnershipCallback__c> upsertCallbackMap = new Map<Id,ProspectOwnershipCallback__c>();

      for (Task tsk : tsks) {
         Id[] poIds = null;
         if (tsk.AccountId != null) {
            poIds = poIdByRecIdMap.get(tsk.AccountId);
         }
         if (poIds == null && tsk.WhoId != null) {
            poIds = poIdByRecIdMap.get(tsk.WhoId);
         }
         if (poIds == null && tsk.WhatId != null) {
            poIds = poIdByRecIdMap.get(tsk.WhatId);
         }
         if (poIds != null && !poIds.isEmpty()) {
            for (Id poId : poIds) {
               Id poOwnerId = poOwnerIdMap.get(poId);
               if (poOwnerId != null && poOwnerId == tsk.OwnerId) {
                  ProspectOwnershipCallback__c newPoCallback = new ProspectOwnershipCallback__c(Callback_Date_Time__c=tsk.ReminderDateTime
                                                                         ,Prospect_Ownership__c=poId
                                                                         ,TaskId__c=tsk.Id);
                  upsertCallbackMap.put(tsk.Id,newPoCallback);
                  break;   // break out of the inner look - only one record for task id
               }
            } // for (Id poId : poIds
         } // if (poIds != null &&
         
         
      }  // for (Task tsk : tsks

      if (!upsertCallbackMap.isEmpty()) {
         try {
            upsert upsertCallbackMap.values() ProspectOwnershipCallback__c.TaskId__c;
         } catch (Exception e) {
            ProspectOwnershipCallback__c callback = upsertCallbackMap.values()[0];
            ErrorLog.logError('ProspectOwnershipMethods', 'checkForCallbackTasks', 'upserting callbacks', callback.TaskId__c, e, callback);
         }
      }
   } // checkForCallbackTasks
   
   /*
   
Date nextCheckDate = now()+Label.Prospect_Owner_Verify_Days;
     
Set on creation
   if End Date is null then set Next Verify Date to be nextCheckDate
   If End Date is populated on creation and Status=='Expired' Set EndDateVerified__c=true
   
   
Run again if: (Verify Needed checkbox currently)
if has an End Date, Ownership_Status__c = 'Expired' and (VerifyCount__c = null or VerifyCount__c < 2 or !EndDateVerified__c)
   set Next Verify Date to be now() if VerifyCount__c == null or 0, else set to now()+1 day
   
if has commission dates (CommissionEnd__c >= nextCheckDate and CommissionStart__c <= nextCheckDate) then set Next Verify Date to be nextCheckDate
If does not have an end date then set next verify to be nextCheckDate
   

    */
   
   public static Integer VERIFY_DAYS=Integer.valueOf(Label.Prospect_Owner_Verify_Days);
   
   public static void checkNextVerifyDate(Prospect_Ownership__c[] pos, Map<Id,Prospect_Ownership__c> oldMap) {
      for (Prospect_Ownership__c po : pos) {
         Prospect_Ownership__c oldPo = (oldMap != null ? oldMap.get(po.Id) : null);
         // if the status changes, clear out last verified
         if (String.isNotBlank(po.Ownership_Status__c) && oldPo != null && oldPo.Ownership_Status__c != po.Ownership_Status__c) {
            po.LastVerified__c = null;
            // if the status changes, always clear out the NextVerifyDate so it's reevaluated
            po.NextVerifyDate__c = null;
         }
         // only re-evaluate the date if we're already past it. If it's in the future we won't re-evaluate it.
         if (po.NextVerifyDate__c == null || po.NextVerifyDate__c < Datetime.now()) {
            checkNextVerifyDate(po, (oldPo == null));
         }
      }
   } // checkNextVerifyDate

   public static void checkNextVerifyDate(Prospect_Ownership__c po, Boolean isInsert) {
      Datetime rightNow = Datetime.now();
      DateTime nextCheckDate = rightNow.addDays(VERIFY_DAYS);
      // default it to null
      //po.NextVerifyDate__c = null;
      String status='';
      if (isInsert) {
         if (po.EndDate__c == null) {
            status ='checkNextVerifyDate in insert with no end date';
            // we want to get picked up immediately on an insert
            po.NextVerifyDate__c = rightNow;
         } else if (po.EndDate__c != null && po.Ownership_Status__c == STAGE_EXPIRED && !po.EndDateVerified__c) {
            status = 'checkNextVerifyDate in insert and expired';
            po.NextVerifyDate__c = rightNow;
         } else if (po.EndDate__c != null && po.CommissionEnd__c >= nextCheckDate && po.CommissionStart__c <= nextCheckDate) {
            status = 'checkNextVerifyDate in insert commission dates';
            // as long as the nextcheckdate is still in the commission date range set the next check date
            po.NextVerifyDate__c = nextCheckDate;
         }
      } else if (po.EndDate__c != null && po.Ownership_Status__c == STAGE_EXPIRED && !po.EndDateVerified__c) {
         if (po.VerifyCount__c == null || po.VerifyCount__c == 0) {
            status = 'checkNextVerifyDate in Expired Status and no verify count';
            // so it hits the next iteration
            po.NextVerifyDate__c = rightNow;
         } else if (po.VerifyCount__c < 2) {
            status = 'checkNextVerifyDate in verifyCount < 2';
            // set it so it runs one more time - just in case
            po.NextVerifyDate__c = rightNow.addDays(1);
         }
      } else if (po.EndDate__c != null && po.EndDateVerified__c) {
         po.NextVerifyDate__c = null;
      } else if (po.NextVerifyDate__c == null || po.LastVerified__c == null || po.Verified__c) {
         // on an update of a record - set the next verified date if needed
         if (po.EndDate__c == null && po.LastVerified__c == null) {
            status = 'checkNextVerifyDate in no end date and no last verified - verify now';
            // if there isn't a last verified date then set it to verify now.
            po.NextVerifyDate__c = rightNow;
         } else if (po.EndDate__c == null) { // && po.Verified__c) {  not sure if we care it was just verified in this case - it's getting here in very specific conditions
            status = 'checkNextVerifyDate in no end date';
            // if it was just verified push out the nextCheckDate
            po.NextVerifyDate__c = nextCheckDate;
         } else if (po.CommissionEnd__c >= nextCheckDate && po.CommissionStart__c <= nextCheckDate) {
            status = 'checkNextVerifyDate in commission dates';
            // as long as the nextcheckdate is still in the commission date range set the next check date
            po.NextVerifyDate__c = nextCheckDate;
         }
         
      }
      if (String.isNotBlank(status)) {
         System.debug(status);
         StringHelper.addToProcessNotes(po,status);
      }
      po.Verified__c = false;
   } // checkNextVerifyDate
    
} // class ProspectOwnershipMethods