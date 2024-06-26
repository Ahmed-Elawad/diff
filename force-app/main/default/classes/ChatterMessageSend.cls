/* Class to select records and send chatter messages

  History
  -------
  01/04/2017 Dan Carmen        Created
  06/02/2017 Dan Carmen        Add Referral
  06/26/2017 Jacob Hinds       Adding in additional object support for chatter message
  09/13/2018 Dan Carmen        Add in logic for NotifyOwnerMsg__c
  12/26/2018 Dan Carmen        Added check for converted leads
  07/29/2019 Matt Fritschi		Added Bank_Product_Of_Interest__c into Lead query
  03/13/2020 Dan Carmen        Remove OasisSyncHelper  
  08/24/2021 Dan Carmen        Replace Account Lost Notification process builder
  08/25/2021 Dan Carmen        Replace AICPA Ref Ctct chatter posts process builder
  02/02/2022 Dan Carmen        Fix Lost Client notification
  01/04/2023 Dan Carmen        Modify processChatterMessage
  
 */
public without sharing class ChatterMessageSend implements TriggerInterfaceC {
   
   public ChatterMessageSend() {
   }
    
   public static String[] reasonLostToExclude = Label.AcctChatExcludeReason.split(',');
   public static String[] acctTypePeoAso = Label.AcctChatExcludeType.split(',');
   public static Boolean acctChatActive = (Label.AcctChatActive=='Y');
   public static String[] acctTypeChatPEO = Label.AccountChatPEOType.split(','); // PEO and Oasis Clients

   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      System.debug('ChatterMessageSend.handleTrigger recs='+recs.size()+' isBefore='+isBefore+' isAfter='+isAfter);
      Account[] lostClientAccts = new Account[]{};
      Set<Id> acctOwnerIdSet = new Set<Id>();
      
      UserHelper.setRunningUserAttributes();
      Boolean isCoeUser = UserHelper.runningUserIsCoe;
       
      Date lostDateCheck = Date.today().addDays(-7);
      System.debug('ChatterMessageSend.handleTrigger isCoeUser='+isCoeUser+' lostDateCheck='+lostDateCheck);
       
      for (SObject rec : recs) {
         SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         if (rec.Id != null) {
            // check for the NotifyOwner__c field
            if (rec.getSObjectType() != Referral_Contact__c.sObjectType) {
               try {
                  Boolean notifyOwner = (Boolean)rec.get('NotifyOwner__c');
                  System.debug('ChatterMessageSend.handleTrigger notifyOwner='+notifyOwner);
                  if (notifyOwner && !notifyOwnerIdSet.contains(rec.Id) && !recordIdsProcessed.contains(rec.Id)) {
                     notifyOwnerIdSet.add(rec.Id);
                     if (isBefore) {
                        rec.put('NotifyOwner__c',false);
                     } // if (isBefore
                  }
               } catch (Exception e) {
                  System.debug('checkBeforeTrigger e='+e.getMessage());
               }
                 
            } // if (rec.getSObjectType() != Referral_Contact__c.sObjectType
             
            // check for account lost date is set
            if (isAfter && oldRec != null && rec.getSObjectType() == Account.sObjectType) {
               System.debug('ChatterMessageSend.handleTrigger in account check');
               Account acct = (Account)rec;
               Account oldAcct = (Account)oldRec;
               // filter out accounts that we don't want to chatter to
               if (acctChatActive && acct.Lost_Date__c != null && oldAcct.Lost_Date__c == null && acct.Lost_Date__c > lostDateCheck 
                      && String.isNotBlank(acct.Reason_Lost__c) && !reasonLostToExclude.contains(acct.Reason_Lost__c)) {
                  lostClientAccts.add(acct);
                  // collect the owner ids to do further checking
                  acctOwnerIdSet.add(acct.OwnerId);
                  if (acct.Premier_PBS_Account_Owner__c != null) {
                     acctOwnerIdSet.add(acct.Premier_PBS_Account_Owner__c);
                  }
               }
            }
            // based on the process builder I took these from, 
            if (isAfter && isCoeUser && rec.getSObjectType() == Referral_Contact__c.sObjectType) {
               evaluateRefCtctChatters((Referral_Contact__c)rec, (Referral_Contact__c)oldRec);
            }
         } // if (rec.Id != null
      } // for (SObject rec : recs
      System.debug('ChatterMessageSend.handleTrigger notifyOwnerIdSet='+notifyOwnerIdSet.size()+' lostClientAccts='+lostClientAccts.size()+' recordIdsProcessed='+recordIdsProcessed.size());
      if (isAfter) {
         ChatterMessageSend.checkAfterProcess();
         if(recs.size() > 0){
                SObject rec = recs[0];
                if(rec.getSObjectType() == Account.sObjectType){
                      checkLostClientAccts((Account[])recs, oldMap, acctOwnerIdSet);

                }
            }
         ChatterMentionPost.checkPostFeedElements();
      }
   } // handleTrigger
    
   public static void evaluateRefCtctChatters(Referral_Contact__c refCtct, Referral_Contact__c oldRefCtct) {
      if (String.isNotBlank(refCtct.AICPA_Original_Type__c) && (oldRefCtct == null || refCtct.AICPA_Original_Type__c != oldRefCtct.AICPA_Original_Type__c)) {
         String key = RecordTypeHelper.cleanRtName(refCtct.AICPA_Original_Type__c);
         AICPAChatter__c cpaChat = AICPAChatter__c.getInstance(key);
         System.debug('evaluateRefCtctChatters key='+key+' cpaChat='+cpaChat);
         if (cpaChat != null) {
            Id[] usersToMention = new Id[]{refCtct.OwnerId};
            String postText = cpaChat.ChatterMsg__c+': '+refCtct.Name;
            ChatterMentionPost.createChatterMentionPost(refCtct.Id, usersToMention, new String[]{postText}, true, false);
            recordsNotified.add(refCtct.Id);
         } // if (cpaChat != null
      } // if (String.isNotBlank(refCtct.AICPA_Original_Type__c
   } // evaluateRefCtctChatters

   public static Set<Id> recordIdsProcessed = new Set<Id>();
   // this is used mainly for testing purposes
   public static Set<Id> recordsNotified = new Set<Id>();
   
   public static Set<Id> notifyOwnerIdSet = new Set<Id>();

    
   public static String CHAT_HEADER='\n\n*** LOST CLIENT NOTIFICATION *** '
                                   +'\n\n!THIS IS A SYSTEM GENERATED COMMUNICATION. DO NOT REPLY TO THIS COMMUNICATION, IF YOU HAVE ANY QUESTIONS PLEASE CONTACT YOUR BRANCH PERSONNEL!'
                                   +'\n\nThe following Prospect-Client has been updated to Lost Client.';
    
 	 public static void checkLostClientAccts(Account[] accts, Map<Id, sObject> oldMapAccts, Set<Id> ownerIdSet) {
        // only send a chatter to reps
        String[] jobNames = new String[]{UserHelper.JOB_REP, UserHelper.JOB_DSA, UserHelper.JOB_DSM, UserHelper.JOB_ZSA};
        Map<Id,User> userMap = new Map<Id,User>([Select Id, Name, Job_Name__c, ManagerId, DSA_FSS__c from User where IsActive=true and Job_Name__c in :jobNames ]);
        System.debug('checkLostClientAccts ownerIdSet='+ownerIdSet.size()+' userMap='+userMap.size());
        Id mmsRTID = RecordTypeHelper.getRecordType(Label.RT_MMS_Account,'Account').getRecordTypeId();
        Id smbRTId = RecordTypeHelper.getRecordType(Label.RT_Core_Account,'Account').getRecordTypeId(); 
        Date lostDateCheck = Date.today().addDays(-7);
        System.debug('reasonLostToExclude'+reasonLostToExclude);
        System.debug('acctTypePeoAso'+acctTypePeoAso);
        System.debug('acctTypeChatPEO'+acctTypeChatPEO);
        for (Account acct : accts) {
            if(oldMapAccts.containsKey(acct.Id) && oldMapAccts.get(acct.id) != null){
                Account oldAcct = (Account)oldMapAccts.get(acct.id);
                User owner;
                User peoOwnerRec;
                //                if( acct.Lost_Date__c != null && oldAcct.Lost_Date__c == null && acct.Reason_Lost__c != null){

                //if( acct.Lost_Date__c != null && acct.Lost_Date__c != oldAcct.Lost_Date__c && acct.Reason_Lost__c != null){
               if( acct.Lost_Date__c != null && oldAcct.Lost_Date__c == null && acct.Reason_Lost__c != null){
                    if (acctChatActive && acct.Lost_Date__c != null && oldAcct.Lost_Date__c == null && acct.Lost_Date__c > lostDateCheck 
                    && String.isNotBlank(acct.Reason_Lost__c) && !reasonLostToExclude.contains(acct.Reason_Lost__c)  && acct.RecordTypeId == mmsRTID && acct.Type == 'FLEX Client' ) {
                        owner =  userMap.get(acct.OwnerId);
                        peoOwnerRec = userMap.get(acct.OasisPEOAccountOwner__c);
                		System.debug('new owner send'); 	
                    }
                    else if(oldAcct!=null && acct.Lost_Date__c != null && oldAcct.Lost_Date__c == null && ((acct.RecordTypeId == mmsRTID && (acct.Type == 'Oasis Client' || acct.Type == 'PEO Client')) || (acct.RecordTypeId == smbRTId && (acct.Type == 'Oasis Client' || acct.Type == 'PEO Client')))){
                        owner = userMap.get(oldAcct.OwnerId);
                        peoOwnerRec =  userMap.get(oldAcct.OasisPEOAccountOwner__c);
                        System.debug('old owner send');
                    }
                    else{
                        owner = userMap.get(acct.OwnerId);
                    }
                    
                    System.debug('>>>>owner'+owner);
                 System.debug('>>>>peoOwnerRec'+peoOwnerRec);
                if (owner != null) {
                    Id[] usersToMention = null;
                    User asoOwner = (acct.Premier_PBS_Account_Owner__c != null ? userMap.get(acct.Premier_PBS_Account_Owner__c) : null);
                    User peoOwner = peoOwnerRec;
                    
                    if (asoOwner != null && String.isNotBlank(acct.Type) && acctTypePeoAso.contains(acct.Type)) {
                        usersToMention = getUsersToMention(asoOwner);
                    }
                    else if(peoOwner != null && String.isNotBlank(acct.Type) && acctTypeChatPEO.contains(acct.Type)){
                        usersToMention = getUsersToMention(peoOwner);
                    }
                    else {
                        usersToMention = getUsersToMention(owner);
                    }
                    System.debug('>>>>usersToMention'+usersToMention);
                    String[] postTexts = new String[]{CHAT_HEADER};
                        String acctText = '\nClient Number: '+checkVal(acct.AccountNumber);
                    acctText += '\nCompany: '+checkVal(acct.Name);
                    acctText += '\nShipping-Delivery Address:';
                    acctText += '\n'+checkVal(acct.ShippingStreet);
                    acctText += '\n'+checkVal(acct.ShippingCity)+', '+checkVal(acct.ShippingState)+'  '+checkVal(acct.ShippingPostalCode);
                    acctText += '\n\nBilling Address:';
                    acctText += '\n'+checkVal(acct.BillingStreet);
                    acctText += '\n'+checkVal(acct.BillingCity)+', '+checkVal(acct.BillingState)+'  '+checkVal(acct.BillingPostalCode);
                    acctText += '\n\nPhone: '+checkVal(acct.Phone);
                    acctText += '\n\nLost Date: '+acct.Lost_Date__c.format();
                    acctText += '\nReason Lost: '+checkVal(acct.Reason_Lost__c);
                    acctText += '\n\nClick on the link to access the Prospect-Client directly: '+URL.getSalesforceBaseUrl().toExternalForm()+'/'+acct.Id; 
                    acctText += ' \n\n';
                    postTexts.add(acctText);
                    postTexts.add(Label.AcctChatLostCodeDefs);
                    ChatterMentionPost.createChatterMentionPost(acct.Id, usersToMention, postTexts, true, false);
                    recordsNotified.add(acct.Id);
                }
                }
                
                
                
            }
            
        } // for (Account acct : accts
    } // checkLostClientAccts
    
   // check for null value, return empty string if null
   public static String checkVal(String value) {
      return (String.isNotBlank(value) ? value : '');
   } // checkVal
   
   // do we only send the chat messages if it's lead loader?
   public static Boolean ONLY_CHAT_AS_LEAD_LOADER=(Label.ChatterMsgOnlyLL == 'Y');
   public static void checkAfterProcess() {
      if (notifyOwnerIdSet != null && !notifyOwnerIdSet.isEmpty()) {
         Boolean okayToSend = !ONLY_CHAT_AS_LEAD_LOADER;
         System.debug('checkAfterProcess okayToSend 1='+okayToSend);
         if (!okayToSend) {
            UserHelper.setRunningUserAttributes();
            okayToSend = UserHelper.runningUserIsLeadLoader;
         }
         System.debug('checkAfterProcess okayToSend 2='+okayToSend);
         if (okayToSend) {
            Id[] idList = new Id[]{};
            idList.addAll(notifyOwnerIdSet);
            sendChatterMessage(idList);
         } // if (okayToSend
      }
      notifyOwnerIdSet.clear();
   } // checkAfterProcess
   
   public static void sendChatterMessage(Id[] recordIds) {
      if (recordIds == null || recordIds.isEmpty()) {
         return;
      }
      recordIdsProcessed.addAll(recordIds);
      String[] textPosts = new String[]{'A lead has been entered in Salesforce for you.'};
      
      system.debug('chatter Ids processed1='+ recordIdsProcessed.size());
      if (Utilities.allowFuture()) {
         processChatterMessageFuture(recordIds, textPosts);
      } else {
         processChatterMessage(recordIds, textPosts);
      }
      
   } // sendChatterMessage
   

   @future
   public static void processChatterMessageFuture(Id[] recordIds, String[] textPosts) {
   	  system.debug('chatter FUTURE');
      processChatterMessage(recordIds, textPosts);
   } // processChatterMessageFuture
   
   // select the records. select the owners. Use the standard template for the message. Send to owner and dsa/manager
   public static void processChatterMessage(Id[] recordIds, String[] textPosts) {
      System.debug('processChatterMessage recordIds='+recordIds+'recordIdsSize='+recordIds.size());
      if (!recordIds.isEmpty()) {
           
         // what type of object is it?
         Schema.SObjectType objType = recordIds[0].getSObjectType();
         if (objType == Lead.SObjectType) {
            handleLeads(recordIds, textPosts);
         } else if (objType == Account.SObjectType) {
            handleAccounts(recordIds, textPosts);
         } else if (objType == Contact.SObjectType) {
            handleContacts(recordIds, textPosts);
         } else if (objType == Referral__c.SObjectType) {
            handleReferrals(recordIds);
         }
         if (!Test.isRunningTest()) {
            system.debug('posting feed elements. records processed: '+recordIdsProcessed);
            ChatterMentionPost.postBatchFeedElements();
         }
      } // if (!recordIds.isEmpty
   } // sendChatterMessage
   
   public static void handleReferrals(Id[] recordIds) {
      system.debug('handleReferrals');
      Referral__c[] refs = ReferralMethods.retrieveReferrals(recordIds);
      Id[] acctIds = new Id[]{};
      Id[] leadIds = new Id[]{};
      for (Referral__c ref : refs) {
         if (ref.Account__c != null) {
            acctIds.add(ref.Account__c);
         } else if (ref.SourceLead__c != null && !ref.SourceLead__r.IsConverted) {
            leadIds.add(ref.SourceLead__c);
         }
      } // for (Referral__c ref
      Map<Id,Account> acctMap = (!acctIds.isEmpty() ? ReferralQueries.selectAcctMap(acctIds) : new Map<Id,Account>());
      Map<Id,Lead> leadMap = (!leadIds.isEmpty() ? ReferralQueries.selectLeadMap(leadIds, null) : new Map<Id,Lead>());
      
      ReferralMethods.ChatterWrapper[] chatterPosts = new ReferralMethods.ChatterWrapper[]{};
      
      Referral__c[] updateRefs = new Referral__c[]{};
      
      for (Referral__c ref : refs) {
         ReferralWrapper rw = new ReferralWrapper();
         rw.ref = ref;
         ReferralMethods.ChatterWrapper chatterPost = new ReferralMethods.ChatterWrapper();    
         if(rw.ref.Selling_Opportunity__c!=null){
             rw.oppSelling = ref.Selling_Opportunity__r;           
             chatterPost.objectId = rw.oppSelling.Id;
             chatterPost.addMentionId(rw.ref.Referring_User__c);
             chatterPost.addMentionId(rw.ref.User__c);
            // chatterPost.addMentionId(rw.ref.DSA__c);
             chatterPost.addMentionId(rw.ref.DSM__c);
             if (rw.ref.User__r != null) {
              //  chatterPost.addMentionId(rw.ref.User__r.DSA_FSS__c);
                chatterPost.addMentionId(rw.ref.User__r.ManagerId);
             }
         }
         else if(rw.ref.SourceContact__c!=null){
            chatterPost.objectId = rw.ref.SourceContact__c;
            chatterPost.addMentionId(rw.ref.Referring_User__c);
            chatterPost.addMentionId(rw.ref.OwnerId);
         }
         else if(rw.ref.SourceLead__c!=null && !rw.ref.SourceLead__r.IsConverted){
            chatterPost.objectId = rw.ref.SourceLead__c;
            chatterPost.addMentionId(rw.ref.Referring_User__c);
            chatterPost.addMentionId(rw.ref.OwnerId);
         }
         if(chatterPost.objectId!=null){
            chatterPost.notes = rw.ref.Notes__c;
            ReferralMethods.checkChatterMessage(rw, chatterPost, acctMap, chatterPosts, leadMap);
            if (ref.NotifyOwner__c || String.isNotBlank(ref.NotifyOwnerMsg__c)) {
               ref.NotifyOwner__c=false;
               ref.NotifyOwnerMsg__c=null;
               updateRefs.add(ref);
            }
         }
         else{
            system.debug('something is not right');
         }
      } // for
      
      if (!chatterPosts.isEmpty()) {
         ReferralMethods.chatterPostIt(chatterPosts);
      }
      
      if (!updateRefs.isEmpty()) {
         ReferralTriggerActions.SKIP_TRIGGER=true;
         DmlHelper.performDML2(updateRefs, DmlHelper.DML_UPDATE, 'ChatterMessageSend', 'handleReferrals', 'update Notify Owner', true);
         ReferralTriggerActions.SKIP_TRIGGER=false;
      }
   } // handleReferrals
   
   
   public static void handleLeads(Id[] recordIds, String[] textPosts) {
      // query the leads
      Lead[] leads = [Select Id, Name
                            ,OwnerId
                            ,Company, Street, City, State, PostalCode
                            ,FirstName, LastName, Phone, Email
                            ,NumberOfEmployees, Frequency__c, Current_Prior_Method__c
                            ,NotifyOwner__c, Bank_Product_Of_Interest__c
                        From Lead
                       Where Id in :recordIds];
      Set<Id> ownerIdSet = new Set<Id>();
      for (Lead ld : leads) {
         ownerIdSet.add(ld.OwnerId);
      }
      Map<Id,User> ownerMap = new Map<Id,User>([Select Id, IsActive, Name, ManagerId, DSA_FSS__c from User where Id in :ownerIdSet]);
      Lead[] updateLeads = new Lead[]{};
      for (Lead ld : leads) {
         createChatterPost(ld.Id, ownerMap.get(ld.OwnerId), textPosts, ChatterMentionPost.buildChatterMessage(ld));
         if (ld.NotifyOwner__c) {
            updateLeads.add(new Lead(Id=ld.Id, NotifyOwner__c=false));
         }
      } // for (Lead ld
      if (!updateLeads.isEmpty()) {
         // skip the trigger executing
         LeadMethods.LEAD_BEFORE_EXECUTING = true;
         LeadMethods.LEAD_AFTER_EXECUTING = true;
         DmlHelper.performDML2(updateLeads, DmlHelper.DML_UPDATE, 'ChatterMessageSend', 'handleLeads', 'update Notify Owner', true);
      }
   } // handleLeads
   
   public static void createChatterPost(Id recId, User usr, String[] textPosts, String chatterMessage) {
      String[] posts = new String[]{};
      if (textPosts != null && !textPosts.isEmpty()) {
         posts.addAll(textPosts);
      }
      posts.add(chatterMessage);
      List<Id> userToMentionIdList = getUsersToMention(usr);
      recordsNotified.add(recId);
      ChatterMentionPost.createChatterMentionPost(recId, userToMentionIdList, posts, false, false);
   } // createChatterPost
   
   
   public static void handleContacts(Id[] recordIds, String[] textPosts) {
      Contact[] ctcts = [Select Id, Name
                               ,Phone, Email
                               ,OwnerId
                               ,Owner.Name
                               ,Owner.ManagerId
                               ,Owner.DSA_FSS__c
                               ,NotifyOwner__c
                               ,Account.Id
                               ,Account.Name
                               ,Account.AccountNumber
                               ,Account.BillingStreet
                               ,Account.BillingCity
                               ,Account.BillingState
                               ,Account.BillingPostalCode
                               ,Account.ShippingStreet
                               ,Account.ShippingCity
                               ,Account.ShippingState
                               ,Account.ShippingPostalCode
                               ,Account.NumberOfEmployees
                               ,Account.Current_Prior_Method__c
                               ,Account.Frequency__c
                           From Contact
                          Where Id in :recordIds];
      System.debug('handleContacts ctct='+ctcts.size());
      Contact[] updateCtcts = new Contact[]{};
      for (Contact ctct : ctcts) {
         createChatterPost(ctct.Id, ctct.Owner, textPosts, ChatterMentionPost.buildChatterMessage(ctct.Account, ctct));
         if (ctct.NotifyOwner__c) {
            updateCtcts.add(new Contact(Id=ctct.Id, NotifyOwner__c=false));
         }
      }

      if (!updateCtcts.isEmpty()) {
         // skip trigger execution
         ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
         ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
         DmlHelper.performDML2(updateCtcts, DmlHelper.DML_UPDATE, 'ChatterMessageSend', 'handleContacts', 'update Notify Owner', true);
      }
   } // handleContacts
   
   public static void handleAccounts(Id[] recordIds, String[] textPosts) {
      Account[] accts = [Select Id, Name
                               ,AccountNumber
                               ,BillingStreet
                               ,BillingCity
                               ,BillingState
                               ,BillingPostalCode
                               ,ShippingStreet
                               ,ShippingCity
                               ,ShippingState
                               ,ShippingPostalCode
                               ,NumberOfEmployees
                               ,Current_Prior_Method__c
                               ,Frequency__c
                               ,NotifyOwner__c
                               ,OwnerId
                               ,Owner.Name
                               ,Owner.ManagerId
                               ,Owner.DSA_FSS__c
                               ,SignificantContact__c
                               ,SignificantContact__r.Id
                               ,SignificantContact__r.Name
                               ,SignificantContact__r.Phone
                               ,SignificantContact__r.Email
                           From Account
                          Where Id in :recordIds];
      Account[] updateAccts = new Account[]{};
      for (Account acct : accts) {
         createChatterPost(acct.Id, acct.Owner, textPosts, ChatterMentionPost.buildChatterMessage(acct, acct.SignificantContact__r));
         if (acct.NotifyOwner__c) {
            updateAccts.add(new Account(Id=acct.Id, NotifyOwner__c=false));
         }
      }
      if (!updateAccts.isEmpty()) {
         // skip the trigger firing
         ZipCheckOwner.SKIP_TRIGGERS = true;
         DmlHelper.performDML2(updateAccts, DmlHelper.DML_UPDATE, 'ChatterMessageSend', 'handleAccounts', 'update Notify Owner', true);
      }
   } // handleAccounts
   
   public static List<Id> getUsersToMention(User usr) {
      List<Id> userIdsToMention = new List<Id>();
      if (usr != null) {
         userIdsToMention.add(usr.Id);
         if (usr.ManagerId != null) {
            userIdsToMention.add(usr.ManagerId);
         }
        /* if (usr.DSA_FSS__c != null) {
            userIdsToMention.add(usr.DSA_FSS__c);
         }*/
      }
      return userIdsToMention;
   } // getUsersToMention

   
} // class ChatterMessageSend