/** This class is to house any general referral account methods.
 * History
 * -------
 *  12/31/2015 Jacob Hinds        Created. Added in Sensivity push method from Parent referral account to child referral account to referral contacts
    07/25/2016 Dan Carmen         Change to make code more dynamic.
    08/18/2016 Dan Carmen         Added trigger actions to the class
    11/11/2016 Dan Carmen         Set the referral type on the referral account.
    02/10/2017 Dan Carmen         Change how name is being set when coming in from Lead Loader.
    02/23/2017 Dan Carmen         Add Independent Agent
    02/01/2018 Frank Lurz         Change code to populate Hold Out for referrals coming in from Lead Loader - Case 25931805
    11/02/2018 Dan Carmen         Call the AcctSensitivityQueueable if a referral source changes
    12/03/2018 Cindy Freeman      modified checkEmployeeLoadFields so Lead Loader update of LatestCampaign gets to sync'ed contact record
    04/08/2019 Dan Carmen         Clear the list after launching the queueable. 
    08/02/2019 Dan Carmen         Add SKIP_TRIGGERS variable.
    02/13/2020 Cindy Freeman      set SENSITIVITY_UPDATE_IN_PROGRESS flag in pushSensitivity
    06/03/2020 Jake Hinds     change to processField to set hold out reason when hold out added
    08/10/2020 Jake Hinds         Removing a debug statment per PMD
    05/28/2021 Pujitha Madamanchi Change chatter message based on Hot/Warm leads. 
    06/30/2021 Dan Carmen         Clear email verification when email changes, format phone numbers
    07/16/2021 Dan Carmen         Fix NPE 
    08/25/2021 Dan Carmen         Replace Referral Contact Outcode process builder, Referral Contact - Referral Type process builder
    03/18/2022 Dan Carmen         Fix setting primary referral type
    12/15/2022 Jidesh             Updated refCtctAfterActions to add logic for CPA Program status check
    28/02/2023 Jaipal             Enqueueing UpdateOppFieldsQueueable in method checkTriggerAfterDuring if Hosted Client is true
    08/14/2023 Dan (CPA)          Code refactored to not have many loops/queries
    12/04/2023 Susmitha Somavarapu Commented out the code 654-657 for field removal for cpa profiling work APR0160191.

*/
public with sharing class ReferralAccountMethods implements TriggerInterfaceC {
   // to skip the Referral Account and Referral Contact triggers
   public static Boolean SKIP_TRIGGERS=false;
   
   // make sure it only goes through the trigger once (when it updates child accounts)
   public static Boolean SENSITIVITY_UPDATE_IN_PROGRESS=false;
   
   public static Map<Id, Map<String,Boolean>> sensitivityFldsToUpdateByRefAcctMap = new Map<id,Map<String,Boolean>>();

   public static Set<Id> refAcctSensitivityIdSet = new Set<Id>();
   public static Set<Id> refCtctSensitivityIdSet = new Set<Id>();
   
   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      System.debug('ReferralAccountMethods.handleTrigger recs='+recs.size()+' isBefore='+isBefore+' isAfter='+isAfter);
      if (recs == null || recs.isEmpty()) {
         return;
      }
      if (isBefore && recs[0].getSObjectType() == Referral_Contact__c.sObjectType) {
         handleRefCtctBefore((Referral_Contact__c[])recs, (Map<Id,Referral_Contact__c>)oldMap);
      }
   } //handleTrigger
    
   public static void handleRefCtctBefore(Referral_Contact__c[] refCtcts, Map<Id,Referral_Contact__c>oldMap) {
      Id[] refAcctIds = new Id[]{};
      Referral_Contact__c[] refTypeCtcts = new Referral_Contact__c[]{};
          
      for (Referral_Contact__c refCtct : refCtcts) {
         Referral_Contact__c oldRec = (oldMap != null ? oldMap.get(refCtct.Id) : null);
         if (String.isBlank(refCtct.PrimaryReferralType__c) || String.isBlank(refCtct.Referral_Type__c)) {
            refAcctIds.add(refCtct.Referral_Account__c);
            refTypeCtcts.add(refCtct);
         }
         /**
         // replace the Referral Contact - Referral Type process builder
         if (String.isBlank(refCtct.Referral_Type__c) && refCtct.Referral_Account__c != null) {
            refAcctIds.add(refCtct.Referral_Account__c);
            refTypeCtcts.add(refCtct);
         } else if (String.isNotBlank(refCtct.Referral_Type__c) && (String.isBlank(refCtct.PrimaryReferralType__c) || (oldRec != null && refCtct.Referral_Type__c != oldRec.Referral_Type__c))) {
            ReferralTypeMapping__c rtm = ReferralTypeMapping__c.getInstance(refCtct.Referral_Type__c);
            if (rtm != null && String.IsNotBlank(rtm.ReferralSource__c) && rtm.ReferralSource__c != refCtct.PrimaryReferralType__c) {
               refCtct.PrimaryReferralType__c = rtm.ReferralSource__c;
            }

         }
         */
      } // for (Referral_Contact__c refCtct
      
      if (!refAcctIds.isEmpty()) {
         Map<Id,Referral_Account__c> refAcctMap = new Map<Id,Referral_Account__c>([Select Id, Name, Referral_Source_Business_Type__c
                                                                                         ,DefaultCtctPrimaryType__c, DefaultCtctReferralType__c
                                                                                     From Referral_Account__c 
                                                                                    Where Id in :refAcctIds]);
         for (Referral_Contact__c refCtct : refTypeCtcts) {
            Referral_Account__c refAcct = refAcctMap.get(refCtct.Referral_Account__c);
            if (refAcct != null) {
               refCtct.Referral_Type__c = (String.isBlank(refCtct.Referral_Type__c) ? refAcct.DefaultCtctReferralType__c : refCtct.Referral_Type__c);
               refCtct.PrimaryReferralType__c = (String.isBlank(refCtct.PrimaryReferralType__c) ? refAcct.DefaultCtctPrimaryType__c : refCtct.PrimaryReferralType__c);
            }
         } // for (Referral_Contact__c refCtct : refTypeCtcts
      } // if (!refAcctIds.isEmpty
             
   } // handleRefCtctBefore
    
   public static void checkTriggerAfterDuring(Referral_Account__c refAcct, Referral_Account__c oldRefAcct) {
      System.debug('checkTriggerAfterDuring refAcct='+refAcct.Name);
      if (refAcct != null && oldRefAcct != null) {
         // keep track of what the changed values of the sensitivity fields are.
         Map<String,Boolean> fldValueMap = new Map<String,Boolean>();
         // check for changes in product sensitivity
         for (ProductSensitivityFields__c psf : ProductSensitivityFields__c.getAll().values()) {
            if (psf.RefAcct__c && String.isNotBlank(psf.FieldName__c)) {
               Boolean newValue = (Boolean)refAcct.get(psf.FieldName__c);
               Boolean oldValue = (Boolean)oldRefAcct.get(psf.FieldName__c);
               if (newValue != oldValue) {
                  refAcctSensitivityIdSet.add(refAcct.Id);
                  if (psf.RefCtct__c) {
                     fldValueMap.put(psf.FieldName__c,newValue);
                  }
               }
            } // if (String.isNotBlank
         } // for (ProductSensitivityFields__c psf
         
         System.debug('checkTriggerAfterDuring fldValueMap='+fldValueMap);
         if (!fldValueMap.isEmpty()) {
            sensitivityFldsToUpdateByRefAcctMap.put(refAcct.Id, fldValueMap);
         }
          if(refAcct.Hosted_Client__c == True && refAcct.Hosted_Client__c!= oldRefAcct.Hosted_Client__c){
              ID jobID = System.enqueueJob(new UpdateOppFieldsQueueable(refAcct.Id));

          }//if(refAcct.Hosted_Client__c == True
      } // if (refAcct != null &&
   } // checkTriggerAfterDuring
   
   public static void checkTriggerAfterActions() {
      if (!sensitivityFldsToUpdateByRefAcctMap.isEmpty()) {
         pushSensitivity(sensitivityFldsToUpdateByRefAcctMap);
      }
      if (CHECK_ACCOUNT_SENSITIVITY_LIST && !refAcctSensitivityIdSet.isEmpty()) {
         checkAcctSensitivityList();
      }
      if (!refAcctChatter.isEmpty()) {
          handleChatterMsg(refAcctChatter);
          refAcctChatter.clear();
      }
   } // checkTriggerAfterActions
   
   public static Boolean CHECK_ACCOUNT_SENSITIVITY_LIST = Label.AccountSensitivityList == 'Y';
   
    public static void checkAcctSensitivityList() {
        // find all of the accounts linked to this referral source
        Map<Id, Account> acctMap = new Map<Id, Account>([Select Id, Name from Account where Referral_National_Account__c in :refAcctSensitivityIdSet limit 10000]);
        if (!acctMap.isEmpty()) {
            Id[] acctIds = new Id[]{};
                acctIds.addAll(acctMap.keySet());
            AcctSensitivityQueueable.checkLaunchQueueable(acctIds);
        }
    } // checkAcctSensitivityList
    
    public static void refCtctAfterActions(Referral_Contact__c[] refCtcts, Map<Id,Referral_Contact__c> oldMap) {
       // for when we have to check the programs on the referral account
       Id[] progCheckRefAcctIds = new Id[]{};
       // for if we have to check if there's a community user to end
       Id[] endCommUserCtctIds = new Id[]{};
           
       for (Referral_Contact__c refCtct : refCtcts) {
          Referral_Contact__c oldRefCtct = (oldMap != null ? oldMap.get(refCtct.Id) : null);
          if (CHECK_ACCOUNT_SENSITIVITY_LIST && oldRefCtct != null && !refCtctSensitivityIdSet.contains(refCtct.Id)) {
             for (ProductSensitivityFields__c psf : ProductSensitivityFields__c.getAll().values()) {
                if (psf.RefCtct__c && String.isNotBlank(psf.FieldName__c)) {
                   Boolean newValue = (Boolean)refCtct.get(psf.FieldName__c);
                   Boolean oldValue = (Boolean)oldRefCtct.get(psf.FieldName__c);
                   if (newValue != oldValue) {
                      refCtctSensitivityIdSet.add(refCtct.Id);
                   }
                }
                        
             } // for (ProductSensitivityFields__c psf
          } // if (CHECK_ACCOUNT_SENSITIVITY_LIST
           
          if (refCtct.Referral_Account_Id__c != null 
                && ((oldRefCtct == null && String.isNotBlank(refCtct.CPA_Program_status__c))
                   || (oldRefCtct != null && refCtct.CPA_Program_status__c != oldRefCtct.CPA_Program_status__c))) {
             progCheckRefAcctIds.add(refCtct.Referral_Account_Id__c);
          }
           
          if (oldRefCtct != null && refCtct.Contact__c != null && refCtct.End_Date__c != null && (refCtct.End_Date__c != oldRefCtct.End_Date__c)) {
             endCommUserCtctIds.add(refCtct.Contact__c);
          }
       } // for (Referral_Contact__c refCtct : refCtcts
        
       if (CHECK_ACCOUNT_SENSITIVITY_LIST && !refCtctSensitivityIdSet.isEmpty()) {
          checkCtctSensitivityList();
          refCtctSensitivityIdSet.clear();
       }
       if (!progCheckRefAcctIds.isEmpty()) {
          checkRefAcctProgStatus(progCheckRefAcctIds);
       }
        
       if (!refCtctChatter.isEmpty()) {
          handleChatterMsg(refCtctChatter);
          refCtctChatter.clear();
       }

    } // refCtctAfterActions
    
    public static String ENROLLED='Enrolled';
    public static String INVITED='Invited';
    public static String UNENROLLED='Unenrolled/no longer in Program';
    public static String NO_LONGER='No Longer In Program';
    
    public static void checkRefAcctProgStatus(Id[] refAcctIds) {
       Referral_Account__c[] refAccts = [Select Id, Name, CPA_Program_status__c
                                               ,(Select Id, CPA_Program_status__c
                                                   from Referral_Contacts__r
                                                  Where CPA_Program_status__c != null)
                                           From Referral_Account__c
                                          Where Id in :refAcctIds];
        
       Referral_Account__c[] updateRfrlAccts = new Referral_Account__c[]{};
       for (Referral_Account__c refAcct : refAccts) {
          Boolean hasEnrolled = false;
          Boolean hasInvited = false;
          Boolean hasUnenroll = false;
          for (Referral_Contact__c refCtct : refAcct.Referral_Contacts__r) {
             if (refCtct.CPA_Program_status__c == ENROLLED) {
                // once one of them is enrolled, we don't need to continue
                hasEnrolled = true;
                break;
             } else if (refCtct.CPA_Program_status__c == INVITED) {
                hasInvited = true; 
             } else if (refCtct.CPA_Program_status__c == UNENROLLED) {
                hasUnenroll = true;
             }
          } // for (Referral_Contact__c refCtct : refAcct.Referral_Contacts__r
          String checkStatus = (hasEnrolled ? ENROLLED : (hasInvited ? INVITED : (hasUnenroll ? NO_LONGER : null)));
          System.debug('checkRefAcctProgStatus refAcct='+refAcct.Name+' curStatus='+refAcct.CPA_Program_Status__c+' checkStatus='+checkStatus
                                     +' hasEnrolled='+hasEnrolled+' hasInvited='+hasInvited+' hasUnenroll='+hasUnenroll);
          if (refAcct.CPA_Program_Status__c != checkStatus) {
             refAcct.CPA_Program_Status__c = checkStatus;
             updateRfrlAccts.add(refAcct);
          }
       } // for (Referral_Account__c refAcct : refAccts
        
       System.debug('checkRefAcctProgStatus updateRfrlAccts='+updateRfrlAccts.size());
       if (!updateRfrlAccts.isEmpty()) {
          ReferralAccountMethods.SKIP_TRIGGERS = true;
          DMLHelper.performDML2(updateRfrlAccts, DMLHelper.DML_UPDATE, 'ReferralAccountMethods', 'checkRefAcctProgStatus', 'update Referral Accounts', true);
          ReferralAccountMethods.SKIP_TRIGGERS = false;
       }
       
    } // checkRefAcctProgStatus
    
    public static void endPortalUsers(Id[] endCommUserCtctIds) {
       Contact[] endDateCtcts = [SELECT Id,Name,User_Lookup__c
                                      ,User_Lookup__r.Id, User_Lookup__r.IsActive
                                  FROM Contact WHERE Id IN :endCommUserCtctIds
                                   AND User_Lookup__r.IsActive = true];
       Id[] inactiveUserIds = new Id[]{};
       for (Contact ctct : endDateCtcts) {
          inactiveUserIds.add(ctct.User_Lookup__c);
       }
       if (!inactiveUserIds.isEmpty()) {
          // future because of mixed dml
          deActivateCPAUser(inactiveUserIds);
       }
    } // endPortalUsers

    /*
    public static void refCtctAfterActions2(Referral_Contact__c[] refCtcts, Map<Id,Referral_Contact__c> oldMap) {
        // this is only done on updates
        if (oldMap != null) {
            for (Referral_Contact__c refCtct : refCtcts) {
                Referral_Contact__c oldRefCtct = oldMap.get(refCtct.Id);
                if (oldRefCtct != null) {
                    for (ProductSensitivityFields__c psf : ProductSensitivityFields__c.getAll().values()) {
                        if (psf.RefCtct__c && String.isNotBlank(psf.FieldName__c)) {
                            Boolean newValue = (Boolean)refCtct.get(psf.FieldName__c);
                            Boolean oldValue = (Boolean)oldRefCtct.get(psf.FieldName__c);
                            if (newValue != oldValue) {
                                refCtctSensitivityIdSet.add(refCtct.Id);
                            }
                        }
                        
                    } // for (ProductSensitivityFields__c psf
                } // if (oldRefCtct != null
            } // for (Referral_Contact__c refCtct
            
            if (CHECK_ACCOUNT_SENSITIVITY_LIST && !refCtctSensitivityIdSet.isEmpty()) {
                checkCtctSensitivityList();
                refCtctSensitivityIdSet.clear();
            }
        } // if (oldMap != null)
        //CPA Program status check:start
        //CPA Updating Referral Account CPA Program status based on Ref Contact status
        //Set CPA Program status on Account to invited if any referral contacts is invited
        //Set CPA Program status on Account to unenrolled if all referral contacts are unenrolled
        System.debug('refCtctAfterActions : Before entering CPA RefAcc program status upd');
        Boolean needCPAStatusCheck = false;
        Boolean endDatePortalUser = false;
        Boolean allUnenroll = false;
        Integer unenrollCount = 0;
        List<Id> refAcctIds = new List<Id>();
        Map<Id, Referral_Account__c> refAcctIdsMap = new Map<Id, Referral_Account__c>();
        List <Referral_Account__c> updAccnts = new List <Referral_Account__c>();
        List <Referral_Contact__c> allrefConts = new List <Referral_Contact__c>();
        List <Referral_Contact__c> endDateRefCnts = new List <Referral_Contact__c>();
        for (Referral_Contact__c refCtct : refCtcts) {
            
            if (oldMap != null){
                Referral_Contact__c oldRefCtct = oldMap.get(refCtct.Id);
                if (oldRefCtct != null && (refCtct.CPA_Program_status__c != oldRefCtct.CPA_Program_status__c)) {
                    needCPAStatusCheck = true;
                }
                //If the referral contact is end dated, deactivate the community User
                if (oldRefCtct != null && (refCtct.End_Date__c != oldRefCtct.End_Date__c) && refCtct.End_Date__c != null) {
                    endDatePortalUser = true;
                    endDateRefCnts.add(refCtct);
                }
            }
            else if(oldMap == null){
                if(refCtct.CPA_Program_status__c != null){
                    needCPAStatusCheck = true;
                }
            }
            if(refCtct.Referral_Account__c != null){
                refAcctIds.add(refCtct.Referral_Account__c);
            }
        }
        System.debug('refCtctAfterActions : endDatePortalUser:'+endDatePortalUser);
        System.debug('refCtctAfterActions : needCPAStatusCheck:'+needCPAStatusCheck);
        System.debug('refCtctAfterActions : refAcctIds:'+refAcctIds);
        System.debug('refCtctAfterActions : endDateRefCnts:'+endDateRefCnts);
        //User deactivation logic
        List <Contact> endDateCnts = new List <Contact>();
        List <Id> endDateUsersIds = new List <Id>();
        List <Id> endDateRefCntIds = new List <Id>();
        List <Id> inactiveUsers = new List <Id>();
        if(endDateRefCnts !=null && endDateRefCnts.size()>0){
            for(Referral_Contact__c rCont:endDateRefCnts){
                endDateRefCntIds.add(rCont.Id);
            }
        }
        System.debug('refCtctAfterActions : endDateRefCntIds:'+endDateRefCntIds);
        if(endDatePortalUser && endDateRefCntIds !=null && endDateRefCntIds.size()>0){
            endDateCnts = [SELECT Id,Name,User_Lookup__c FROM Contact WHERE Mirror_Ref_Ctct__r.Id IN :endDateRefCntIds];
            for(User usr: [SELECT ContactId,Id,IsActive FROM User WHERE ContactId IN :endDateCnts]){
                System.debug('refCtctAfterActions cont:'+usr);
                endDateUsersIds.add(usr.Id);
            }
            System.debug('refCtctAfterActions : endDateUsersIds:'+endDateUsersIds);
            if(endDateUsersIds!= null && endDateUsersIds.size()>0){
                for(User usr: [SELECT Id,IsActive FROM User where Id IN :endDateUsersIds]){
                    System.debug('refCtctAfterActions : User:'+usr);
                    if(usr.IsActive == true){
                        usr.IsActive = false;
                        inactiveUsers.add(usr.Id);
                    }
                }
            }
            System.debug('refCtctAfterActions : inactiveUsers:'+inactiveUsers);
            if(inactiveUsers != null && inactiveUsers.size()>0){
                deActivateCPAUser(inactiveUsers);
            }
        }
        List<Referral_Account__c> refAccs = new List<Referral_Account__c>();
        if(refAcctIdsMap.isEmpty()){
            allrefConts =  [Select id, Name, CPA_Program_status__c,Referral_Account__c from Referral_Contact__c where Referral_Account__c IN :refAcctIds];
            refAccs = [Select Id, Name, CPA_Program_Status__c from Referral_Account__c where Id IN :refAcctIds];
            for(Referral_Account__c refacc:refAccs){
                System.debug('Adding value to refAcctIdsMap');
                refAcctIdsMap.put(refacc.Id, refacc);
            }      
        }
        if(allrefConts.size()>0){
            for(Referral_Contact__c refCon: allrefConts){
                if(refCon.CPA_Program_status__c == 'Unenrolled/no longer in Program' || string.isblank(refCon.CPA_Program_status__c)){
                    unenrollCount++;
                }
            }
        }
        System.debug('refCtctAfterActions : unenrollCount:'+unenrollCount);
        if(unenrollCount >0 && allrefConts.size() == unenrollCount){
            allUnenroll = true;
        }
        System.debug('refCtctAfterActions : allUnenroll:'+allUnenroll);
        if(needCPAStatusCheck && !allUnenroll){
            System.debug('refCtctAfterActions : refAcctIdsMap :'+refAcctIdsMap ); 
            if (!refAcctIdsMap.isEmpty()) {
                for(Referral_Contact__c refCtct: refCtcts){
                    if(refCtct.CPA_Program_status__c != null && refCtct.CPA_Program_status__c == 'Invited'){
                        Referral_Account__c refAccForCnt = refAcctIdsMap.get(refCtct.Referral_Account__c);
                        System.debug('refAccForCnt :'+refAccForCnt );
                        // jc removed from if logic :  && refAccForCnt.CPA_Program_Status__c != 'No Longer In Program'
                        if(refAccForCnt != null && refAccForCnt.CPA_Program_Status__c != 'Invited'  && refAccForCnt.CPA_Program_Status__c != 'Enrolled'){
                            refAccForCnt.CPA_Program_Status__c = 'Invited';
                        }
                        System.debug('refAccForCnt after changes :'+refAccForCnt );
                        updAccnts.add(refAccForCnt);
                        System.debug('refCtctAfterActions : Updating to invited:');
                    }
                    else if(refCtct.CPA_Program_status__c != null && refCtct.CPA_Program_status__c == 'Enrolled'){
                        Referral_Account__c refAccForCnt = refAcctIdsMap.get(refCtct.Referral_Account__c);
                        System.debug('refAccForCnt :'+refAccForCnt );
                        //jc removed from if logic:  refAccForCnt.CPA_Program_Status__c != 'No Longer In Program'
                        if(refAccForCnt != null && refAccForCnt.CPA_Program_Status__c != 'Enrolled'){
                            refAccForCnt.CPA_Program_Status__c = 'Enrolled';
                        }
                        System.debug('refAccForCnt after changes :'+refAccForCnt );
                        updAccnts.add(refAccForCnt);
                        System.debug('Updating to Enrolled:');
                    }
                }
            }
        }
        else if(needCPAStatusCheck && allUnenroll){
            for(Referral_Contact__c refCtct: refCtcts){
                Referral_Account__c refAccForCnt = refAcctIdsMap.get(refCtct.Referral_Account__c);
                if(refAccForCnt != null && refAccForCnt.CPA_Program_Status__c != 'No Longer In Program'){
                    refAccForCnt.CPA_Program_Status__c = 'No Longer In Program';
                    updAccnts.add(refAccForCnt);
                }
            } 
        }
        System.debug('updAccnts:'+updAccnts);
        if(updAccnts!= null && updAccnts.size()>0){
            update updAccnts;
        }
        //CPA Program status check:end
        
        if (!refCtctChatter.isEmpty()) {
            handleChatterMsg(refCtctChatter);
            refCtctChatter.clear();
        }
    } // refCtctAfterActions
    */

    //When Referral Contact is End dated, deactivate the CPA User
    @future
    @TestVisible private static void deActivateCPAUser(List<Id> inactiveUserIds){
        System.debug('deActivateCPAUser: Update the user record here');
        User[] updateUsers = new User[]{};
        for (Id userId : inactiveUserIds) {
           updateUsers.add(new User(Id=userId, IsActive=false));    
        }
        
        /*  
        //update inactivUsers;
        List<User> updUsers= [SELECT Id,IsActive FROM User where Id IN :inactivUsers];
        for(User usr: updUsers){
            System.debug('refCtctAfterActions : User:'+usr);
            if(usr.IsActive == true){
                usr.IsActive = false;
            }
        }
        */
        DMLHelper.performDML2(updateUsers, DMLHelper.DML_UPDATE, 'ReferralAccountMethods', 'execute', 'updating users to inactive', true);
    } // deActivateCPAUser

   public static void handleChatterMsg(Referral_Contact__c[] p_refCtcts) {
      // @[{!$Record.OwnerId}] You have been assigned a new lead/referral source: {!$Record.Name}
      // requery to get the name and owner id
      Referral_Contact__c[] refCtcts = [Select Id, Name, OwnerId, LoadNotifyRepPrev__c from Referral_Contact__c where Id in :p_refCtcts];
      
      for (Referral_Contact__c refCtct : refCtcts) {
         String msg;
         if(refCtct.LoadNotifyRepPrev__c.equalsIgnoreCase('HOT')){
            msg = 'You have been assigned a new High Priority lead/referral source: '+refCtct.Name;
         }
         else{
            msg = 'You have been assigned a new lead/referral source: '+refCtct.Name;
         }
          ChatterMentionPost.createChatterMentionPost(refCtct.Id, new Id[]{refCtct.OwnerId}, new String[]{msg}, true, false);
      }
      ChatterMentionPost.checkPostFeedElements();
   } // handleChatterMsg
    
   public static void handleChatterMsg(Referral_Account__c[] p_refAccts) {
      // requery to get the name and owner id
      Referral_Account__c[] refAccts = [Select Id, Name, OwnerId, LoadNotifyRepPrev__c from Referral_Account__c where Id in :p_refAccts];
      
      for (Referral_Account__c refAcct : refAccts) {
         String msg;
         if (String.isNotBlank(refAcct.LoadNotifyRepPrev__c) && refAcct.LoadNotifyRepPrev__c.equalsIgnoreCase('HOT')){
            msg = 'You have been assigned a new High Priority lead/referral source: '+refAcct.Name;
         }
         else{
            msg = 'You have been assigned a new lead/referral source: '+refAcct.Name;
         }
          ChatterMentionPost.createChatterMentionPost(refAcct.Id, new Id[]{refAcct.OwnerId}, new String[]{msg}, true, false);
      }
      ChatterMentionPost.checkPostFeedElements();
   } // handleChatterMsg
   
   public static void checkCtctSensitivityList() {
      Map<Id, Account> acctMap = new Map<Id, Account>([Select Id, Name from Account 
                                                        where Banker_Name_Ref__c in :refCtctSensitivityIdSet 
                                                           or Broker_Name_Ref__c in :refCtctSensitivityIdSet
                                                           or CPA_Name_Ref__c in :refCtctSensitivityIdSet
                                                           or Insurance_Broker_Name_Ref__c in :refCtctSensitivityIdSet
                                                        limit 10000]);
      if (!acctMap.isEmpty()) {
         Id[] acctIds = new Id[]{};
         acctIds.addAll(acctMap.keySet());
         AcctSensitivityQueueable.checkLaunchQueueable(acctIds);
      }

   } // checkCtctSensitivityList
   
   public static String getSensitivityFldsForQuery() {
      String querySensitivityFlds = '';
      for (ProductSensitivityFields__c psf : ProductSensitivityFields__c.getAll().values()) {
         if (String.isNotBlank(psf.FieldName__c) && psf.OnAccount__c && psf.OnContact__c) {
            querySensitivityFlds += ' ,'+psf.FieldName__c;
         }
      } // for (ProductSensitivityFields__c psf
      return querySensitivityFlds;
   } // getSensitivityFldsForQuery
   
   //method pushes sensitivity flags from a Parent Referral Account down to its child referral acount, then to all referral contacts on the child referral account.  A formula field on the
   //account then pulls from the referral contact. Called from ReferralAccountAfter.trigger
   public static void pushSensitivity(Map<Id,Map<String,Boolean>> updateMap){
      SENSITIVITY_UPDATE_IN_PROGRESS = true;
      // do this once
      String querySensitivityFlds = getSensitivityFldsForQuery();

      Set<Id> keySet = new Set<Id>();
      keySet.addAll(updateMap.keySet());
      //System.debug('pushSensitivity 1 keySet='+keySet+' size='+keySet.size()+' updateMap='+updateMap.size());
      
      //get children
      String acctQuery = 'Select Id, Name, Parent_Referral_Account__c ';
      acctQuery += querySensitivityFlds;
      acctQuery += ' from Referral_Account__c where Parent_Referral_Account__c in :keySet ';
      //System.debug('pushSensitivity acctQuery='+acctQuery);
      
      // if we need to update the children referral accounts
      Referral_Account__c[] refAcctsToUpdate = new Referral_Account__c[]{};
      
      List<Referral_Account__c> childList = Database.query(acctQuery);
      //for each child, loop through the parents and grab the fields that were updated.  Then push the values into the child field values
      for (Referral_Account__c child : childList) {
         Map<String,Boolean> updateValues = updateMap.get(child.Parent_Referral_Account__c);
         if (updateValues != null) {
            updateMap.put(child.Id,updateValues);
            Boolean acctChanged = false;
            for (String fldName : updateValues.keySet()) {
               Boolean checkValue = updateValues.get(fldName);
               Boolean acctValue = (Boolean)child.get(fldName);
               if (checkValue != acctValue) {
                  System.debug('pushSensitivity refAcct '+child.Name+' '+fldName+' updated to '+checkValue);
                  child.put(fldName, checkValue);
                  acctChanged = true;
               }
            } // for (String fldName : updateValues
            if (acctChanged) {
               refAcctsToUpdate.add(child);
            }
         } // if (updateValues != null
         
      }//child in childList
      if (!refAcctsToUpdate.isEmpty()) {
         ReferralAccountMethods.SKIP_TRIGGERS=true;
         update refAcctsToUpdate;
      }
      //update childList;
      
      
      //get all referral contacts from the referral account
      String ctctQuery = 'Select Id, Name, Referral_Account__c, Referral_Account__r.Parent_Referral_Account__c ';
      ctctQuery += querySensitivityFlds;
      ctctQuery += ' from Referral_Contact__c where (Referral_Account__c in :keySet or Referral_Account__r.Parent_Referral_Account__c in :keySet ) ';
      //System.debug('pushSensitivity 2 keySet='+keySet+' size='+keySet.size()+' updateMap='+updateMap.size());
      //System.debug('pushSensitivity ctctQuery='+ctctQuery);

      Referral_Contact__c[] refCtctsToUpdate = new Referral_Contact__c[]{};

      //for each referral contact, loop through the referral accounts and grab the fields that were updated.  Then push the values into the referral contact field values.
      for(Referral_Contact__c ctct : Database.query(ctctQuery)){
         //System.debug('pushSensitivity ctct='+ctct);
         Map<String,Boolean> updateValues = updateMap.get(ctct.Referral_Account__c);
         if (updateValues == null && ctct.Referral_Account__r.Parent_Referral_Account__c != null) {
            updateValues = updateMap.get(ctct.Referral_Account__r.Parent_Referral_Account__c);
         }
         //System.debug('pushSensitivity refCtct '+ctct.Name+' updateValues='+(updateValues != null ? updateValues.size() : -1));
         if (updateValues != null) {
            Boolean ctctChanged = false;
            for (String fldName : updateValues.keySet()) {
               Boolean checkValue = updateValues.get(fldName);
               Boolean ctctValue = (Boolean)ctct.get(fldName);
               if (checkValue != ctctValue) {
                  //System.debug('pushSensitivity refCtct '+ctct.Name+' '+fldName+' updated to '+checkValue);
                  ctct.put(fldName, checkValue);
                  ctctChanged = true;
               }
            } // for (String fldName : updateValues
            if (ctctChanged) {
               refCtctsToUpdate.add(ctct);
            }
         } // if (updateValues != null

      }//for(Referral_Contact__c ctct
      //update contactList;
      if (!refCtctsToUpdate.isEmpty()) {
         ReferralAccountMethods.SKIP_TRIGGERS=true;
         update refCtctsToUpdate;
      }
      ReferralAccountMethods.SKIP_TRIGGERS=false;
      
   } // pushSensitivity
   
   public static Set<String> emailSet = new Set<String>();
   public static Map<String,SObject> recsWithEmailMap = new Map<String,SObject>();
   // a map of the contacts by the email address of the users
   public static Map<String,Contact> contactByEmailMap = null;
   
   // this is used for testing purposes to reset values between runs
   public static void resetVariables() {
      emailSet.clear();
      recsWithEmailMap.clear();
      contactByEmailMap = null;
      sensitivityFldsToUpdateByRefAcctMap.clear();
      refCtctsByRefAcctIdMap.clear();
      UserHelper.setRunningUserAttributes();
      isLeadLoader = UserHelper.runningUserIsLeadLoader;
   } // resetVariables

   public static Boolean isLeadLoader = false;

   public static Map<Id, Referral_Contact__c[]> refCtctsByRefAcctIdMap = new Map<Id, Referral_Contact__c[]>();
    
   public static Boolean FORMAT_PHONE=!Test.isRunningTest();

   public static Boolean CHECK_PRIMARY_REF_TYPE=(Label.CheckPrimaryReferralType=='Y');
    
   public static void checkRefCtctBeforeActions(Referral_Contact__c refCtct, Referral_Contact__c oldRefCtct) {
      // when coming from lead loader, always populate the name field from the first and last names.
      if (isLeadLoader && String.isNotBlank(refCtct.Last_Name__c)) {
         refCtct.Name = (String.isNotBlank(refCtct.First_Name__c) ? refCtct.First_Name__c+' ' : '')+refCtct.Last_Name__c;
      } else if (!isLeadLoader) {
         // if the Name field changes, set the first and last name fields
         // last name should always have a value, so if that is null that will fire the logic also.
         if (String.isBlank(refCtct.Last_Name__c) || oldRefCtct == null || (oldRefCtct != null && oldRefCtct.Name != refCtct.Name)) {
            StringHelper.parseFullName(refCtct.Name);
            refCtct.First_Name__c = StringHelper.firstName;
            refCtct.Last_Name__c = StringHelper.lastName;
         }
      }
      if (FORMAT_PHONE && refCtct.Phone__c != null && (oldRefCtct == null || (refCtct.Phone__c != oldRefCtct.Phone__c ))) {
         refCtct.Phone__c = StringHelper.formatPhoneNumber(refCtct.Phone__c, true);
      }
       
      if (FORMAT_PHONE && refCtct.Mobile_Phone__c != null && (oldRefCtct == null || (refCtct.Mobile_Phone__c != oldRefCtct.Mobile_Phone__c ))) {
         refCtct.Mobile_Phone__c = StringHelper.formatPhoneNumber(refCtct.Mobile_Phone__c, true);
      }

      if (oldRefCtct != NULL && refCtct.Email__c != oldRefCtct.Email__c) {
         refCtct.Email_Verification__c = NULL;
         refCtct.Email_Verification_Date__c = NULL;
      }        
 
      // do we need to check the sensitivities on the associated accounts?
      if (refCtct.Id != null && refCtct.CheckSensitivityList__c) {
         refCtct.CheckSensitivityList__c = false;
         refCtctSensitivityIdSet.add(refCtct.Id);
      }
      
      // replace Referral Contact Outcode process builder
    //	  if (oldRefCtct != null && refCtct.Outcome__c != oldRefCtct.Outcome__c) {
        // refCtct.Outcome_Date__c = (String.isNotBlank(refCtct.Outcome__c) ? Date.today() : null);
   //   }
      
      // only on insert, attempt to pull sensitivities from referral account
      if (oldRefCtct == null && refCtct.Referral_Account__c != null) {
         Referral_Contact__c[] refCtcts = refCtctsByRefAcctIdMap.get(refCtct.Referral_Account__c);
         if (refCtcts == null) {
            refCtcts = new Referral_Contact__c[]{};
            refCtctsByRefAcctIdMap.put(refCtct.Referral_Account__c, refCtcts);
         }
         refCtcts.add(refCtct);
      } // if (oldRefCtct == null
      /*
      if (CHECK_PRIMARY_REF_TYPE && ((String.isBlank(refCtct.PrimaryReferralType__c) && String.isNotBlank(refCtct.Referral_Type__c))
                                    || (oldRefCtct != null && String.isNotBlank(refCtct.Referral_Type__c) 
                                                 && refCtct.Referral_Type__c != oldRefCtct.Referral_Type__c))) {
         ReferralTypeMapping__c rtm = ReferralTypeMapping__c.getInstance(refCtct.Referral_Type__c);
         if (rtm != null && String.IsNotBlank(rtm.ReferralSource__c) && rtm.ReferralSource__c != refCtct.PrimaryReferralType__c) {
            refCtct.PrimaryReferralType__c = rtm.ReferralSource__c;
         }
      }
      */
   } // checkRefCtctBeforeActions
   
   public static void checkLeadLoaderBeforeActions(Referral_Contact__c refCtct, Referral_Contact__c oldRefCtct) {
      System.debug('checkEmployeeLoadFields refCtct='+refCtct.Name);
      checkEmployeeLoadFields(refCtct, oldRefCtct, true);
   } // checkLeadLoaderBeforeActions

   
   public static void checkLeadLoaderBeforeActions(Referral_Account__c refAcct, Referral_Account__c oldRefAcct) {
      System.debug('checkEmployeeLoadFields refAcct='+refAcct.Name);
      checkEmployeeLoadFields(refAcct, oldRefAcct, true);
   } // checkLeadLoaderBeforeActions
   
   public static void checkBeforeActions(Referral_Account__c refAcct, Referral_Account__c oldRefAcct) {
      // evaluate the sensitivity on connecting accounts
      if (refAcct.Id != null && refAcct.CheckSensitivityList__c) {
         refAcctSensitivityIdSet.add(refAcct.Id);
         refAcct.CheckSensitivityList__c = false;
      }
      /*
      if (String.isBlank(refAcct.Referral_Type__c)) {
         checkRefAcctReferralType(refAcct, oldRefAcct);
      }
      */
   } // checkBeforeActions
   
   /*
   public static void checkRefAcctReferralType(Referral_Account__c refAcct, Referral_Account__c oldRefAcct) {
      if (String.isNotBlank(refAcct.Referral_Source_Business_Type__c)) {
         ReferralScoreMethods.checkCustomSettings();
         refAcct.Referral_Type__c = ReferralScoreMethods.sourceByBusinessTypeMap.get(refAcct.Referral_Source_Business_Type__c);
      }
   } // checkRefAcctReferralType
   */
   // if we're going to add a chatter message for these records.
   public static Referral_Account__c[] refAcctChatter = new Referral_Account__c[]{};
   public static Referral_Contact__c[] refCtctChatter = new Referral_Contact__c[]{};
   public static String[] notifyRepValues = new String[]{'Hot','Warm','Yes','Y'};
   
   public static void checkEmployeeLoadFields(Referral_Contact__c refCtct, Referral_Contact__c oldRefCtct, Boolean initialPass) {
      
      if (String.isNotBlank(refCtct.LoadCampaign__c)) {
         refCtct.LoadCampaignPrev__c = refCtct.LoadCampaign__c;
         refCtct.LoadCampaign__c = null;
      }
      if (String.isBlank(refCtct.LoadCampaign__c) && String.isNotBlank(refCtct.LatestCampaign__c) 
          && (oldRefCtct==null || refCtct.LatestCampaign__c != oldRefCtct.LatestCampaign__c)) {
         refCtct.LoadCampaignPrev__c = refCtct.LatestCampaign__c;
      }

      // LoadLeadSource__c, LoadLeadSourcePrev__c
      if (String.isNotBlank(refCtct.LoadLeadSource__c)) {
         refCtct.LoadLeadSourcePrev__c = refCtct.LoadLeadSource__c;
         refCtct.LoadLeadSource__c = null;
      }
      
      if (String.isNotBlank(refCtct.LoadNotifyRep__c)) {
         if (notifyRepValues.contains(refCtct.LoadNotifyRep__c)) {
            refCtctChatter.add(refCtct);
         }
         refCtct.LoadNotifyRepPrev__c = refCtct.LoadNotifyRep__c;
         refCtct.LoadNotifyRep__c = null;
      }
       
      if (String.isNotBlank(refCtct.LoadReferralType__c)) {
         if (String.isBlank(refCtct.Referral_Type__c)) {
            refCtct.Referral_Type__c = refCtct.LoadReferralType__c;
         }
         refCtct.LoadReferralTypePrev__c = refCtct.LoadReferralType__c;
         refCtct.LoadReferralType__c = null;
      }
            
   } // checkEmployeeLoadFields
   
   public static void checkEmployeeLoadFields(Referral_Account__c refAcct, Referral_Account__c oldRefAcct, Boolean initialPass) {
      processField(refAcct, oldRefAcct, 'LoadAccountOwner__c', 'LoadAccountOwnerPrev__c', 'OwnerId', ObjectHelper.OBJECT_USER, initialPass);
      processField(refAcct, oldRefAcct, 'LoadBankCentricRep__c', 'LoadBankCentricRepPrev__c', 'Bank_Centric_Rep__c', ObjectHelper.OBJECT_USER, initialPass);
      processField(refAcct, oldRefAcct, 'LoadCPARelationshipMgr__c', 'LoadCPARelationshipMgrPrev__c', 'CPA_Relationship_Manager__c', ObjectHelper.OBJECT_USER, initialPass);
      processField(refAcct, oldRefAcct, 'LoadDedicatedRep__c', 'LoadDedicatedRepPrev__c', 'Dedicated_Rep__c', ObjectHelper.OBJECT_CONTACT, initialPass);
      processField(refAcct, oldRefAcct, 'LoadIARelationshipMgr__c', 'LoadIARelationshipMgrPrev__c', 'Independent_Agent_Relationship_Manager__c', ObjectHelper.OBJECT_USER, initialPass);
      if (String.isNotBlank(refAcct.LoadNotifyRep__c)) {
         if (notifyRepValues.contains(refAcct.LoadNotifyRep__c)) {
            refAcctChatter.add(refAcct);
         }
         refAcct.LoadNotifyRepPrev__c = refAcct.LoadNotifyRep__c;
         refAcct.LoadNotifyRep__c = null;
      }

   } // checkEmployeeLoadFields
   
   public static void processField(SObject rec, SObject oldRec, String fldName, String prevFldName, String idFldName, String lookupType, Boolean initialPass) {
      String newVal = (String)rec.get(fldName);
      String oldVal = (oldRec != null ? (String)oldRec.get(fldName) : null);
      System.debug('processField fldName='+fldName+' newVal='+newVal+' oldVal='+oldVal);
      if (String.isNotBlank(newVal) && newVal != oldVal) {
         String recId = checkForEmployee(rec,newVal, lookupType ,initialPass);
         If (String.isNotBlank(recId)) {
            Boolean holdOut = (Boolean)rec.get('Hold_Out__c');
            rec.put(idFldName, (Id)recId);
             if (fldName == 'LoadAccountOwner__c' ){ 
                rec.put('Hold_Out__c', true);
                rec.put('Hold_Out_Reason__c','Lead Loader');
                System.debug('processField - setting Hold_Out__c = true');
             }
         }
         if (!initialPass) {
            rec.put(prevFldName, rec.get(fldName));
            rec.put(fldName, '');
         }
      } // if (newVal != null &&
   } // processField
   
   public static String checkForEmployee(SObject rec, String empInfo, String lookupType, Boolean initialPass) {
      String retVal = null;
      if (String.isNotBlank(empInfo)) {
         // is this an email address? If so - look up the contact 
         if (empInfo.contains('@')) {
            if (contactByEmailMap == null) {
               System.debug('checkForEmployee added to email check');
               emailSet.add(empInfo);
               String mapKey = (rec.Id != null ? (String)rec.Id : (String)rec.get('Name'));
               recsWithEmailMap.put(mapKey, rec);
            } else if (!initialPass) {
               Contact ctct = contactByEmailMap.get(empInfo);
               System.debug('check after contact query ctct='+ctct);
               if (ctct != null) {
                  retVal = (lookupType == ObjectHelper.OBJECT_CONTACT ? ctct.Id : (lookupType == ObjectHelper.OBJECT_USER ? ctct.User_Lookup__c : null));
               }
            }
         } else if (!initialPass) {
            // if not an email, should be an ID - only need to process through this on the initial pass
            if ((lookupType == ObjectHelper.OBJECT_USER && empInfo.startsWith(ObjectHelper.PREFIX_USER))
                  || (lookupType == ObjectHelper.OBJECT_CONTACT && empInfo.startsWith(ObjectHelper.PREFIX_CONTACT))) {
               retVal = empInfo;    
            }
         }
      } // if (String.isNotBlank(empInfo
      System.debug('checkForEmployee retVal='+retVal);
      return retVal;
   } // checkForEmployee
   
   public static void checkRefAcctTriggerBeforeActions() {
      if (!emailSet.isEmpty()) {
         contactByEmailMap = UserHelper.getContactMapByEmail(emailSet);
         System.debug('checkRefAcctTriggerBeforeActions contactByEmailMap='+contactByEmailMap.size());
         if (!contactByEmailMap.isEmpty()) {
            for (SObject rec : recsWithEmailMap.values()) {
               Referral_Account__c refAcct = (Referral_Account__c)rec;
               checkEmployeeLoadFields(refAcct, null, false);
               System.debug('checkRefAcctTriggerBeforeActions refAcct='+refAcct);
            } // for (Referral_Account__c refAcct
         }
      } // if (!emailSet.isEmpty
   } // checkTriggerBeforeActions

   public static void checkRefCtctTriggerBeforeActions() {
      if (!refCtctsByRefAcctIdMap.isEmpty()) {
         checkForSensitivitiesForNewContacts();
      }
   } // checkRefCtctTriggerBeforeActions
   
   // for new referral contacts, check if there are any sensitivities on the referral account.
   public static void checkForSensitivitiesForNewContacts() {
      String querySensitivityFlds = getSensitivityFldsForQuery();

      Set<Id> keySet = refCtctsByRefAcctIdMap.keySet();

      //find the referral accounts
      String acctQuery = 'Select Id, Name ';
      acctQuery += querySensitivityFlds;
      acctQuery += ' from Referral_Account__c where Id in :keySet ';
      System.debug('checkForSensitivitiesForNewContacts acctQuery='+acctQuery);
      
      for (Referral_Account__c refAcct : Database.query(acctQuery)) {
         Referral_Contact__c[] refCtcts = refCtctsByRefAcctIdMap.get(refAcct.Id);
         if (refCtcts != null) {
            checkForSensitivitiesForNewContacts(refAcct, refCtcts);
         }
      } // for (Referral_Account__c refAcct
      
   } // checkForSensitivitiesForNewContacts

   public static void checkForSensitivitiesForNewContacts(Referral_Account__c refAcct, Referral_Contact__c[] refCtcts) {
      for (Referral_Contact__c refCtct : refCtcts) {
         for (ProductSensitivityFields__c psf : ProductSensitivityFields__c.getAll().values()) {
            if (String.isNotBlank(psf.FieldName__c) && psf.OnAccount__c && psf.OnContact__c) {
               Boolean acctValue = (Boolean)refAcct.get(psf.FieldName__c);
               // only set the true values on the contact
               if (acctValue) {
                  refCtct.put(psf.FieldName__c, refAcct.get(psf.FieldName__c));
               }
            } // if (String.isNotBlank(psf.FieldName__c
         } // for (ProductSensitivityFields__c psf
      } // for (Referral_Contact__c refCtct
   } // checkForSensitivitiesForNewContacts
   
} // class ReferralAccountMethods