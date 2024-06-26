/*

* History
* -------
08/14/2019 Josh Cartwright      Created
09/05/2019 Dan Carmen           Add methods to update Amplifinity Referrals with Referral info
03/03/2020 Jermaine Stukes      Added Account holdout when Advocate status changed to Active
06/08/2020 Jake Hinds           Added without sharing per PMD
10/08/2020 Brandon Vidro        Moved code from AmpAdvocateBefore and made updates for APR0109682 - PRN for MMS
01/06/2021 Brandon Vidro        Added code to automatically create referring oppty if Advocate owner does not match Account owner when Selling oppty is created
								INC2554313 - Push Paychex Referral Network Enrollment Date to Account even when Advocate gets inserted with status of 'Active'
02/10/2021 Brandon Vidro        APR0112960 - PRN Remove Hold Out Automation
05/18/2021 Dan Carmen           Changed to use OppStage Labels
08/08/2023 Lalan Kumar          APR0143207: FROST to SF connection: No PAYX Ref where are these coming from

*/
public without sharing class AmplifinityHelper implements TriggerInterface2  {
    
    public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
        if (TriggerMethods.didTriggerRun('AmplifinityHelper',recs,isBefore,isAfter)) {
            return;
        }
        SObjectType objType = TriggerMethods.objType;
        if (isBefore) {
            if (objType == amp_dev__Amp_Referral__c.sObjectType) {
                checkAmpReferralStatus((amp_dev__Amp_Referral__c[])recs,(Map<Id,amp_dev__Amp_Referral__c>)oldMap);
            } else if (objType == Referral__c.sObjectType) {
                checkReferralsBefore((Referral__c[])recs,(Map<Id,Referral__c>)oldMap);
            }
            if (objType == amp_dev__Amp_Advocate__c.sObjectType) {
                checkAdvocateBefore((amp_dev__Amp_Advocate__c[])recs);
            }

        } // if (isBefore
        if (isAfter) {
            if (objType == Referral__c.sObjectType) {
                checkReferralsAfter((Referral__c[])recs,(Map<Id,Referral__c>)oldMap);
            }
            if (objType == Opportunity.sObjectType) {
                checkAmpOpptyAfter((Opportunity[])recs,(Map<Id,Opportunity>)oldMap); 
            }
            if (objType == amp_dev__Amp_Advocate__c.sObjectType) {
                checkAdvocateAfter((amp_dev__Amp_Advocate__c[])recs,(Map<Id,amp_dev__Amp_Advocate__c>)oldMap);
            }
           
             
        } // if (isAfter
    } // triggerCheckAllFirst
    
    public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
    
    // see if there are any actions that need to take place at the end of the trigger.
    public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}
    
    // key = ar status, value = amp status
    public static Map<String,String> ampByArStatusMap = null;
    public static Map<String,String> arByAmpStatusMap = null; 
    public static Map<String,Boolean> ampAllowUpdatesMap = null;
    public static Map<String,Amplifinity_AR_Status_Mapping__mdt> statusMap = new Map<String,Amplifinity_AR_Status_Mapping__mdt>();
    public static String notSoldStatus=null;
    public static Boolean CHATTER_SENT = false;
    public static String NOT_SOLD=Label.OppStage_Lost;
    
    public static void checkAmpMaps() {
        if (ampByArStatusMap == null) {
            ampByArStatusMap = new Map<String,String>();
            arByAmpStatusMap = new Map<String,String>(); 
            ampAllowUpdatesMap = new Map<String,Boolean>();
            statusMap = new Map<String,Amplifinity_AR_Status_Mapping__mdt>();
            for (Amplifinity_AR_Status_Mapping__mdt statusMapping : [Select MasterLabel, Label, AR_Status__c, AMP_Status__c, Allow_Updates__c
                                                                     ,IsClosedStatus__c
                                                                     from Amplifinity_AR_Status_Mapping__mdt]) {
                                                                         statusMap.put(statusMapping.AMP_Status__c,statusMapping);
                                                                         ampByArStatusMap.put(statusMapping.AR_Status__c, statusMapping.AMP_Status__c);
                                                                         arByAmpStatusMap.put(statusMapping.AMP_Status__c, statusMapping.AR_Status__c); 
                                                                         ampAllowUpdatesMap.put(statusMapping.AR_Status__c, statusMapping.Allow_Updates__c);
                                                                         if (statusMapping.label == 'Not sold') {
                                                                             notSoldStatus = statusMapping.AMP_Status__c;
                                                                         }//if
                                                                     } // for (Amplifinity_AR_Status_Mapping__mdt statusMapping
        } // if (ampStatusMap == null
    } // checkAmpMaps
    
    public static String STATUS_OPEN='Open';
    public static String STATUS_CLOSED='Closed';
    

    public static void checkAmpReferralStatus(amp_dev__Amp_Referral__c[] recs, Map<Id,amp_dev__Amp_Referral__c> oldMap) {
        /*APR0143207: Added below map on Amplifinity Referral for Paychex Referral */
         Map<Id,amp_dev__Amp_Referral__c> payRefQueryMap = new Map<Id,amp_dev__Amp_Referral__c>();
        checkAmpMaps();
        for (amp_dev__Amp_Referral__c amp :recs){ 
            amp_dev__Amp_Referral__c prevRec = (oldMap != null ? oldMap.get(amp.Id) : null);
            if (String.isNotBlank(amp.amp_dev__Status__c) && (prevRec == null || amp.amp_dev__Status__c != prevRec.amp_dev__Status__c)) {
                Amplifinity_AR_Status_Mapping__mdt ampStatus = statusMap.get(amp.amp_dev__Status__c);
                
                /*APR0143207: Paychex Referral not null in Amp referral then fill the map */
                if(amp.Paychex_Referral__c!= null){
			    payRefQueryMap.put(amp.Paychex_Referral__c,amp);
			  }
                if (ampStatus !=null) {
                    amp.Open_Close_Status__c = (ampStatus.IsClosedStatus__c  ? STATUS_CLOSED : STATUS_OPEN) ; 
                }//if not equal to null 
            }//if 
            
            /*APR0143207: Update the Paychex Referral AMP Status when AMP Referall Status update- START */
            if(!payRefQueryMap.isEmpty()){
			  
				  Referral__c [] payChexRef=[select Id,AMP_Status__c from Referral__c where Id in :payRefQueryMap.keyset()];
				  
				  Map<Id,Referral__c> updatePayRefMap = new Map<Id,Referral__c>();
				  for(Referral__c ref: payChexRef){
					  amp_dev__Amp_Referral__c ampRef = payRefQueryMap.get(ref.Id);
					  if(ampRef!=null&& ref.AMP_Status__c != ampRef.amp_dev__Status__c){
					  ref.AMP_Status__c = ampRef.amp_dev__Status__c;
					  updatePayRefMap.put(ref.id,ref);
					  }

				 }//for(Referral__c ref
				 if(!updatePayRefMap.isEmpty()){
				  DmlHelper.performDML2(updatePayRefMap.values(), DmlHelper.DML_UPDATE, 'AmplifinityHelper', 'checkReferrals', 'Update Paychex Referrals', true);
				}
		   } //if(!payRefQueryMap.isEmpty()
             /*APR0143207: Update the Paychex Referral AMP Status when AMP Referall Status update- END */
        }
    } // checkAmpReferralStatus
    
    public static void checkReferralsBefore(Referral__c[] recs, Map<Id,Referral__c> oldMap) {
        for (Referral__c ref : recs) {
            Referral__c oldRef = (oldMap != null ? oldMap.get(ref.Id) : null);
            if (ref.Amplifinity_Referral__c != null) {
                checkAmpMaps();
                if (oldRef != null && ref.AR_Status__c != null && oldRef.AR_Status__c != ref.AR_Status__c) {
                    ref.AMP_Status__c = (ampByArStatusMap.get(ref.AR_Status__c) != null ? ampByArStatusMap.get(ref.AR_Status__c) : null);
                }
            }// if (ref.Amplifinity_Referral__c != null
        } // for (Referral__c ref
    } // checkReferralsBefore
    
    public static void checkReferralsAfter(Referral__c[] recs, Map<Id,Referral__c> oldMap) {
        Map<Id,Referral__c> ampRefQueryMap = new Map<Id,Referral__c>();
        for (Referral__c ref : recs) {
            Referral__c oldRef = (oldMap != null ? oldMap.get(ref.Id) : null);
            // if there's a linked Amplifinity Referral and the Selling Opportunity is set/changed
            if (ref.Amplifinity_Referral__c != null) {
                checkAmpMaps();
                // we're always going to update the amp referral on an insert
                if (oldRef == null) {
                    ampRefQueryMap.put(ref.Amplifinity_Referral__c,ref);
                    // if any of the fields are populated and a value changes (or it's new)
                } else if ((ref.Selling_Opportunity__c != null
                            || String.isNotBlank(ref.AMP_Status__c)
                            || ref.Term_End_Date__c != null
                            || ref.Reward_Amount__c != null)
                           && (ref.Selling_Opportunity__c != oldRef.Selling_Opportunity__c
                               || ref.AMP_Status__c != oldRef.AMP_Status__c
                               || ref.Term_End_Date__c != oldRef.Term_End_Date__c
                               || ref.Reward_Amount__c != oldRef.Reward_Amount__c
                               || ref.AR_Status__c != oldRef.AR_Status__c)
                          ) {
                              ampRefQueryMap.put(ref.Amplifinity_Referral__c,ref);
                          }
            } // if (ref.Amplifinity_Referral__c != null
        } // for (Referral__c ref
        if (!ampRefQueryMap.isEmpty()) {
            amp_dev__Amp_Referral__c[] ampRefs = [Select Id, amp_dev__Opportunity__c
                                                  ,amp_dev__Status__c
                                                  ,Term_End_Date__c
                                                  ,AR_Reward_Amount__c
                                                  ,Paychex_Referral__c
                                                  from amp_dev__Amp_Referral__c 
                                                  where Id in :ampRefQueryMap.keySet()];
            Map<Id,amp_dev__Amp_Referral__c> updateAmpRefMap = new Map<Id,amp_dev__Amp_Referral__c>();
            for (amp_dev__Amp_Referral__c ampRef : ampRefs) {
                Referral__c ref = ampRefQueryMap.get(ampRef.Id);
                if (ref != null) {
                    Referral__c oldRef = (oldMap != null ? oldMap.get(ref.Id) : null);
                    if (ref.Selling_Opportunity__c != ampRef.amp_dev__Opportunity__c) {
                        ampRef.amp_dev__Opportunity__c = ref.Selling_Opportunity__c;
                        updateAmpRefMap.put(ampRef.Id,ampRef);
                    }
                    if (ampRef.Paychex_Referral__c != ref.Id) {
                        ampRef.Paychex_Referral__c = ref.Id;
                        updateAmpRefMap.put(ampRef.Id,ampRef);
                    }
                    // if the AR Status changes to a value that is not updateable (but previous status was) that's okay to update.
                    // if the AR Status doesn't change and it's not updateable, don't update
                    // if the AR Status changes to a value that is updateable, update.
                    // if the previous AR Status is null just go off the current status
                    Boolean currentStatusUpdateable = arStatusUpdatable(ref.AR_Status__c);
                    Boolean prevStatusUpdateable = (oldRef == null || String.isBlank(oldRef.AR_Status__c) ? true : arStatusUpdatable(oldRef.AR_Status__c));
                    if (String.isNotBlank(ref.AR_Status__c) && (currentStatusUpdateable || prevStatusUpdateable)) {
                        ampRef.amp_dev__Status__c = ref.AMP_Status__c;
                        ampRef.Term_End_Date__c = ref.Term_End_Date__c;
                        ampRef.AR_Reward_Amount__c = ref.Reward_Amount__c;
                        updateAmpRefMap.put(ampRef.Id,ampRef);
                    }
                } // if (ref != null
            } // for (amp_dev__Amp_Referral__c ampRef
            DmlHelper.performDML2(updateAmpRefMap.values(), DmlHelper.DML_UPDATE, 'AmplifinityHelper', 'checkReferrals', 'Update Amplifinity Referrals', true);
            
        } // if (!ampRefQueryMap.isEmpty()
        
    } // checkReferralsAfter
    
    public static void checkAdvocateAfter(amp_dev__Amp_Advocate__c[] recs, Map<Id,amp_dev__Amp_Advocate__c> oldMap) {
        List<Id> advOwnerChange = new List<Id>();
        List<Id> changeToAccountOwner = new List<Id>();
        List<Id> acctIdList = new List<Id>();
        List<Id> acctIdListActiveStatus = new List<Id>();
        List<amp_dev__Amp_Advocate__c> advEnrollChatterList = new List<amp_dev__Amp_Advocate__c>();
        
        for (amp_dev__Amp_Advocate__c advRec : recs)
        {
            amp_dev__Amp_Advocate__c oldRec = (oldMap != null ? oldMap.get(advRec.Id) : null);
            
            if(advRec.OwnerId != null && oldRec.OwnerId != null && oldRec.OwnerId != advRec.OwnerId) {
                advOwnerChange.add(advRec.Id);
            }
            if(advRec.Change_Owner_Date__c == null && oldRec.Change_Owner_Date__c != null && oldRec.Change_Owner_Date__c == System.Date.today() && advRec.amp_dev__Status__c == 'Active')
            {
                changeToAccountOwner.add(advRec.Id);
            }
            if(advRec.amp_dev__Status__c != null && oldRec.amp_dev__Status__c != null && advRec.amp_dev__Status__c != oldRec.amp_dev__Status__c && advRec.amp_dev__Status__c == 'Active')
            {
                acctIdList.add(advRec.Account__c);
                advEnrollChatterList.add(advRec);
            }
            if(advRec.amp_dev__Status__c != null && oldRec.amp_dev__Status__c == null && advRec.amp_dev__Status__c != oldRec.amp_dev__Status__c && advRec.amp_dev__Status__c == 'Active') {
                acctIdListActiveStatus.add(advRec.Account__c);
            }
        }
        if(!acctIdList.isEmpty()){
            advocateAcctHoldoutUpdate(acctIdList);
        }
        if(!acctIdListActiveStatus.isEmpty()){
            advocateAcctHoldoutUpdate(acctIdListActiveStatus);
        }
        if(!advEnrollChatterList.isEmpty()){
            sendAdvocateOwnerChatter(advEnrollChatterList);
        }
        if(!advOwnerChange.isEmpty()){
            changeAdvocateOwner(advOwnerChange);
        }
        if(!changeToAccountOwner.isEmpty())
        {
            changeOwnerToAccountOwner(changeToAccountOwner);
        }
    }// 
    public static void checkAdvocateBefore(amp_dev__Amp_Advocate__c[] recs) {
        User advocateUser = [Select Id from User where name = 'Amplifinity API USER' limit 1];
        List<amp_dev__Amp_Advocate__c> advocateList = new List<amp_dev__Amp_Advocate__c>();
        List<amp_dev__Amp_Advocate__c> changeAmpOwnership = new List<amp_dev__Amp_Advocate__c>();
        List<Id> usersToCheck = new List<Id>();
        List<Id> acctIdList = new List<Id>();
        List<amp_dev__Amp_Advocate__c> advocateOwnerForReportingList = new List<amp_dev__Amp_Advocate__c>();
        
        for (amp_dev__Amp_Advocate__c advRec : recs)
        {
            if(advRec.OwnerId == advocateUser.Id){
                advocateList.add(advRec);
                acctIdList.add(advRec.Account__c);
            }
            if(advRec.amp_dev__Status__c != null && (advRec.amp_dev__Status__c == 'invited' || advRec.amp_dev__Status__c == 'Invited'))
            {
                changeAmpOwnership.add(advRec);
                usersToCheck.add(advRec.OwnerId);
            }   
            if(advRec.Owner_For_Reporting__c == null && advRec.OwnerId != null) {
                advocateOwnerForReportingList.add(advRec);
            }
        }
        if(!advocateList.isEmpty()){
            advocateOwnerUpdate(advocateList, acctIdList);
        }
        if(!changeAmpOwnership.isEmpty())
        {
            setAdvChangeOwnerDate(usersToCheck,changeAmpOwnership);
        }
        if(!advocateOwnerForReportingList.isEmpty()){
            advocateOwnerForReportingUpdate(advocateOwnerForReportingList);
        } 
    }// 
    public static Boolean arStatusUpdatable(String arStatus) {
        Boolean updateable = false;
        if (String.isNotBlank(arStatus)) {
            checkAmpMaps();
            updateable = ((ampAllowUpdatesMap.containsKey(arStatus)) ? ampAllowUpdatesMap.get(arStatus) : false);
        } // if (String.isNotBlank(arStatus
        return updateable;
    } // arStatusUpdatable
    
    public static String AR_SOLD='Sold';
    public static String AR_NOT_SOLD='Not sold';
    
    public static void advocateAcctHoldoutUpdate(List<Id>acctIds){
        List<Account> acctList = [Select Id, Hold_Out__c, Permanent_Hold_Out_Description__c,Paychex_Referral_Network_Enrollment_Date__c from Account where Id in:acctIds];
        for(Account acct : acctList){
            if(acct.Paychex_Referral_Network_Enrollment_Date__c == null){
                acct.Paychex_Referral_Network_Enrollment_Date__c = Date.today();
            }
        }
        DmlHelper.performDML2(acctList, DmlHelper.DML_UPDATE, 'AmplifinityHelper', 'advocateAcctHoldoutUpdate', 'Update Account Paychex Referral Network Enrollment Date', true); 
    }
    
    public static void sendAdvocateOwnerChatter(List<amp_dev__Amp_Advocate__c>advEnrollChatterList) {
        List<Id> usersToMention = new List<Id>();
        String postText = ' has successfully completed their enrollment and is now part of the Paychex Referral Network!';
        for(amp_dev__Amp_Advocate__c user : advEnrollChatterList) {
            usersToMention.add(user.OwnerId);
            ChatterMentionPost.createChatterMentionPost(user.OwnerId, usersToMention, new String[]{user.amp_dev__Company_Name__c, postText}, false);   
            usersToMention.clear();    
            CHATTER_SENT = true; 
        }
    }
    
    public static void advocateOwnerUpdate(List<amp_dev__Amp_Advocate__c>advocates,List<Id>acctIds){
        Map<Id, Account> acctMap = new Map<Id, Account>([Select Id,OwnerId from Account where Id in:acctIds]);
        for(amp_dev__Amp_Advocate__c advRec : advocates){
            advRec.OwnerId = acctmap.get(advRec.Account__c).OwnerId;
        }
    }
    
    public static void advocateOwnerForReportingUpdate(List<amp_dev__Amp_Advocate__c>advocatesForReporting) {
        for(amp_dev__Amp_Advocate__c adv: advocatesForReporting) {
            adv.Owner_For_Reporting__c = adv.OwnerId; 
        }
    }
    
    public static void changeAdvocateOwner(List<Id>advOwnerChange) {
        List<amp_dev__Amp_Advocate__c> advs = [Select Id, OwnerId, Owner_For_Reporting__c from amp_dev__Amp_Advocate__c where Id in :advOwnerChange];
        for(amp_dev__Amp_Advocate__c adv: advs) {
            adv.Owner_For_Reporting__c = adv.OwnerId;
        }
        DmlHelper.performDML2(advs, DmlHelper.DML_UPDATE, 'AmplifinityHelper', 'changeAdvocateOwner', 'Update Owner for Reporting on Advocate wheb Owner changes', true);
    }
    
    public static void changeOwnerToAccountOwner(List<Id> changeToAccountOwner)
    {
        List<amp_dev__Amp_Advocate__c> advs = [Select Id, OwnerId, Owner_For_Reporting__c, Account__c from amp_dev__Amp_Advocate__c where Id in :changeToAccountOwner];
        List<Id> accountsToQuery = new List<Id>();
        for(amp_dev__Amp_Advocate__c adv : advs)
        {
            accountsToQuery.add(adv.Account__c);
        }
        
        Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id, Name, OwnerId FROM Account WHERE Id IN :accountsToQuery]);
        
        for(amp_dev__Amp_Advocate__c adv : advs)
        {
            Account acct = acctMap.get(adv.Account__c);
            if(acct != null && adv.OwnerId != null && acct.OwnerId != null && adv.OwnerId != acct.OwnerId)
            {
                adv.OwnerId = acct.OwnerId;
                adv.Owner_For_Reporting__c = adv.OwnerId;
            }
        }
        DmlHelper.performDML2(advs, DmlHelper.DML_UPDATE, 'AmplifinityHelper', 'changeOwnerToAccountOwner', 'Update Owner for Reporting on Advocate wheb Owner changes', true);
    }
    
     public static List<String> hrsProfiles = new List<String>{Utilities.PROF_HRS_REGIONAL_SALES, Utilities.PROF_HRS_401K, Utilities.PROF_HRS_SALES_MANAGER, Utilities.PROF_HRS_SALES_ADMIN, Utilities.PROF_HRS_REGIONAL_SALES_SB};
             
     public static List<String> pcProfiles = new List<String>{Utilities.PROF_PC_SALES_MANAGER, Utilities.PROF_PC_SALES_ADMINISTRATION_SB, Utilities.PROF_PC_SALES_REP};
         
     public static List<String> coreProfiles = new List<String>{Utilities.PROF_CORE_SALES_SB,
       	Utilities.PROF_CORE_SALES_ADMIN_SB, Utilities.PROF_CORE_SALES_TRAIN, Utilities.PROF_CORE_VIRTUAL_SALES, Utilities.PROF_CORE_ZONE_ADMIN_SB, Utilities.PROF_CORE_MGR_SB};
    
     public static List<String> mmsProfiles = new List<String>{Utilities.PROF_MMS_MGR_SB, Utilities.PROF_MMS_SALES_SB, Utilities.PROF_MMS_SALES_DSA_SB, Utilities.PROF_MMS_SALES_ZSA_SB, Utilities.PROF_MMS_SALES_ZSA};
    
     public static void setAdvChangeOwnerDate(List<Id>usersToCheck,List<amp_dev__Amp_Advocate__c>changeAmpOwnership) {
        List<Id> profileIds = new List<Id>();
        if(usersToCheck.size()>0)
        {
            //Gets all Users for the Ownership Change
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, ProfileId, Sales_Division__c FROM User WHERE Id IN :usersToCheck]);
            
            for(User u : userMap.values())
            {
                if(!profileIds.contains(u.ProfileId))
                {
                    profileIds.Add(u.ProfileId);
                }
            }
            
            //Gets the Profiles of the Users to check if Ownership change needs to happen
            Map<Id, Profile> profileMap = new Map<Id, Profile>([SELECT Id, Name FROM Profile WHERE Id IN :profileIds]);
            
            //Check User Profile/Division and Change Ownership if necessary
            for(amp_dev__Amp_Advocate__c ampAdv : changeAmpOwnership)
            {
                User ampUser = userMap.get(ampAdv.OwnerId);
                if(ampUser != null && ampUser.ProfileId != null)
                {
                    Profile ampUserProfile = profileMap.get(ampUser.ProfileId);
                    if(ampUserProfile != null && ampUserProfile.Name != null && (hrsProfiles.contains(ampUserProfile.Name) || pcProfiles.contains(ampUserProfile.Name)))
                    {
                        ampAdv.Change_Owner_Date__c = Date.today() + 365;
                    }
                } 
            }
        }
    }
    
    public static void checkAmpOpptyAfter(Opportunity[] recs, Map<Id,Opportunity> oldMap) {
        User runningUser = UserHelper.getRunningUser();
        Map<Id,Opportunity> payxRefQueryMap = new Map<Id,Opportunity>();
        for (Opportunity opp : recs) {
            Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
            // if there's a linked Amplifinity Referral and the Selling Opportunity is set/changed
            if (opp.ReferralLookup__c != null){
                checkAmpMaps();
                if (opp.StageName != null && (oldOpp == null || (opp.StageName != oldOpp.StageName))) {
                    if(opp.StageName == NOT_SOLD || opp.StageName.startswith('Sold')){
                        payxRefQueryMap.put(opp.Id,opp);  
                    } 
                }
                
            } // if (opp.ReferralLookup__c  != null  
        } // for (Opportunity opp  
        if (!payxRefQueryMap.isEmpty()) {
            Referral__c[] payxRefs = [Select Id, Selling_Opportunity__c, AR_Status__c, AMP_Status__c from Referral__c where Selling_Opportunity__c in :payxRefQueryMap.keySet()];
            Referral__c[] updatePayxRefs = new Referral__c[]{};
                String arStatus = null;    
            for (Referral__c payxRef : payxRefs) {
                Opportunity opp = payxRefQueryMap.get(payxRef.Selling_Opportunity__c);
                if (opp.StageName == NOT_SOLD) {
                    arStatus = AR_NOT_SOLD ;
                } else if (opp.StageName.startswith('Sold')) {
                    arStatus = AR_SOLD ;
                } 
                if (String.isNotBlank(arStatus)) {
                    string AMPStatus = (ampByArStatusMap.containsKey(arStatus) ? ampByArStatusMap.get(arStatus) : null);
                    payxRef.AMP_Status__c = AMPStatus; 
                    payxRef.AR_Status__c = (arByAmpStatusMap.containsKey(AMPStatus) ? arByAmpStatusMap.get(AMPStatus) : null); 
                    updatePayxRefs.add(payxRef);
                }
            } // for (Referral__c payxRef
            DmlHelper.performDML2(updatePayxRefs, DmlHelper.DML_UPDATE, 'AmplifinityHelper', 'checkAmpOpptyAfter', 'Update Paychex Referrals', true);                      
        } // if (!ampRefQueryMap.isEmpty()
    } // checkAmpOpptyAfter
} // class AmplifinityHelper