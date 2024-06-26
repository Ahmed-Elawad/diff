/* 
 * Check records for duplicates before processing them as web leads
 *
 * History
 * -------
   02/07/2018 Dan Carmen       Created
   04/11/2018 Dan Carmen       Modifications for using merge() and convertLead()
   04/27/2018 Dan Carmen       Adjustments for Marketo
   04/25/2019 Dan Carmen       Add additional debugging for prepareFldCopy
   05/06/2019 Dan Carmen       Add additional information when de-duping
   10/24/2019 Dan Carmen       Add additional debugging
   11/12/2019 Dan Carmen       Changes to handle an inactive account user on lead convert
   06/02/2020 Cindy Freeman    set static variable in DG_DFR_Controller when converting Lead to fix DFR bug
   06/29/2020 Cindy Freeman	   added some fancy footwork to run contact trigger methods only when a weblead Lead is auto merged into an existing Contact
   10/18/2022 Dan Carmen       Change excludeCopyFldSet to a Label
   12/06/2022 Dan Carmen       Changed to be able to use SF Duplicate Management
   12/13/2022 Pujitha Madamanchi    Added Form Fill Date to Contact query(line 473).
   09/26/2023 Dan Carmen       Removed Dupeblocker code

*/
public without sharing class DuplicateCheckQueueable implements Queueable {
   
   // do we create a log record of this processing?
   public static Boolean LOG_TRANSACTIONS=Label.DuplicateCheck_LogTransactions=='Y';
   
   // the records remaining to check in the next iteration
   public Map<String, PartnerReferral__c> nextDupeCheckMap = new Map<String, PartnerReferral__c>();
   public SObject[] nextRecsToCheck = new SObject[]{};
   
   // the records that we're going to check in this iteration
   public Map<String, PartnerReferral__c> dupeCheckMap = new Map<String, PartnerReferral__c>();
   public SObject[] recsToCheck = new SObject[]{};
   public SObject[] recsForTrackRecordEntry = new SObject[]{};
   
   public static Apex_Batch_Control__c getBatchControl() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('DuplicateCheckQueueable');
      return abc;
   } // getBatchControl
   
   public static ErrorLog__c runLog = null;
   
   // used for testing purposes
   public Set<Id> DUPE_OVERRIDE_ID_SET = null;

   public DuplicateCheckQueueable(Map<String, PartnerReferral__c> p_dupeCheckMap, SObject[] p_recsToCheck) {
      String recName = 'LOG_DATA';
      if (!p_recsToCheck.isEmpty() && p_recsToCheck[0].getSObjectType() == Lead.sObjectType) {
         Lead ld = (Lead)p_recsToCheck[0];
         recName = ld.FirstName+' '+ld.LastName+'-'+ld.Company;
      }
      if (runLog == null) {
         runLog = ErrorLog.logError('DuplicateCheckQueueable', 'LOG_DATA', recName, '', 'p_recsToCheck='+p_recsToCheck.size()+' p_dupeCheckMap='+p_dupeCheckMap.size());
         runLog.BatchSize__c = p_recsToCheck.size();
         runLog.ObjectId__c = (!p_recsToCheck.isEmpty() ? p_recsToCheck[0].Id : null);
         // so we only save the log if we want to.
         ErrorLog.errorLogList.clear();
      } else {
         addToLog('p_recsToCheck='+p_recsToCheck.size()+' p_dupeCheckMap='+p_dupeCheckMap.size());
      }
      
      // check to see if we can continue
      Apex_Batch_Control__c abc = getBatchControl();
      // get the number of records to process in a batch - default to 2
      Integer nbrRecsToProcess = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 2);
      System.debug('DuplicateCheckQueueable.nbrRecsToProcess='+nbrRecsToProcess);

      String log = '';
      // build the list of records to process, and put anything remaining into the list to process next time.
      for (SObject rec : p_recsToCheck) {
         String transactionId = (String)rec.get('TransactionId__c');
         log += '\n transactionId='+transactionId; 
       
         // this should always have a value at this point, but just in case
         if (String.isNotBlank(transactionId)) {
            TrackRecordEntry.resetWeblead(rec);
            PartnerReferral__c partRef = p_dupeCheckMap.remove(transactionId);
            log += ' partRef found='+partRef != null;
            if (partRef != null) {
               if (recsToCheck.size() < nbrRecsToProcess) {
                  log += ' added to recsToCheck';
                  recsToCheck.add(rec);
                  dupeCheckMap.put(transactionId, partRef);
               } else {
                  log += ' added to nextRecsToCheck';
                  nextRecsToCheck.add(rec);
                  nextDupeCheckMap.put(transactionId, partRef);
               }
            }
         } // if (String.isNotBlank(transactionId
      } // for
      addToLog(log);
   } // DuplicateCheckQueueable
   
   public SObject[] recsToUpdate = new SObject[]{};
   public SObject[] recsToDelete = new SObject[]{};
    
   public void execute(QueueableContext context) {
      // for testing purposes
      if (Test.isRunningTest() && DUPE_OVERRIDE_ID_SET != null) {
         DuplicateCheck.DUPE_OVERRIDE_ID_SET = DUPE_OVERRIDE_ID_SET;
      }
      
      processRecs();

      launchQueueable(nextDupeCheckMap, nextRecsToCheck);
   } // execute
   
   public OasisSyncQueueable oasisSync = null;
   //public AmplifinityHelper ampHelper = null;
   
   public void processRecs() {
      System.debug('processRecs recsToCheck='+recsToCheck.size());
      if (!recsToCheck.isEmpty()) {
         String objectApiName = (recsToCheck[0].getSObjectType() == Lead.sObjectType ? ObjectHelper.OBJECT_LEAD
                                      : (recsToCheck[0].getSObjectType() == Contact.sObjectType ? ObjectHelper.OBJECT_CONTACT : 'Unknown'));
         DuplicateCheck.checkForDuplicates(recsToCheck, objectApiName);
         addToLog('processRecs checkForDuplicates DuplicateCheck.allRecsChecked='+DuplicateCheck.allRecsChecked.size());
         // handle duplicates
         checkDupeResults();

         checkSave();
         
         System.debug('processRecs dupeCheckMap='+dupeCheckMap.size()+' recsForTrackRecordEntry='+recsForTrackRecordEntry.size());
         addToLog('processRecs dupeCheckMap='+dupeCheckMap.size()+' recsForTrackRecordEntry='+recsForTrackRecordEntry.size());
         saveLog();
         if (!recsForTrackRecordEntry.isEmpty()) {
            for (SObject rec : recsForTrackRecordEntry) {
               String transId = (String)rec.get('TransactionId__c');
               addToLog('processRecs transId='+transId+' in dupeCheckMap='+dupeCheckMap.containsKey(transId));
            }
            saveLog();
            // put back into the TrackRecordEntry code.
            TrackRecordEntry.partRefMap = dupeCheckMap;
            TrackRecordEntry.v_runLog = runLog;
            TrackRecordEntry.prevStageMap = prevStageMap; 
            
            
            new TrackRecordEntry().checkAllAfterTrigger(recsForTrackRecordEntry, null);
         }
      } // if (!recsToCheck
   } // processRecs
   
  public void checkDupeResults() {
      // to update the duplicate check status
      Map<Id,SObject> recsToUpdate = new Map<Id,SObject>();
      id[] ampRecIds = new id []{}; 
      addToLog('checkDupeResults allRecsChecked='+DuplicateCheck.allRecsChecked.size());

      // do these separately so we can do a bulk update
      for (DuplicateCheck.DupeWrapper dupeWrap : DuplicateCheck.allRecsChecked) {
         dupeWrap.logMatchType(recsToUpdate);
         //String oasisId = (String)dupeWrap.rec.get('OasisId__c');
         //addToLog('oasisId='+oasisId);
         //if (dupeWrap.rec.get('OasisId__c') != null) {
         //   addToLog('OasisId__c found='+(String)dupeWrap.rec.get('OasisId__c'));
         //   if (oasisSync == null) {
         //      oasisSync = new OasisSyncQueueable();
         //   }
         //   oasisSync.addIdToProcess(dupeWrap.rec.Id, OasisSyncHelper.SYNC_DUPE_RESULT);
         //}

      }

      addToLog('recsToUpdate='+recsToUpdate.size());
      LeadMethods.LEAD_BEFORE_EXECUTING = true;
      LeadMethods.LEAD_AFTER_EXECUTING = true;
      DmlHelper.performDML2(recsToUpdate.values(), DmlHelper.DML_UPDATE, 'DuplicateCheckQueueable', 'checkDupeResults', 'Update Match Types', true);
      LeadMethods.LEAD_BEFORE_EXECUTING = false;
      LeadMethods.LEAD_AFTER_EXECUTING = false;
      
      //Map<Id,Lead> nonWorkableLeadMap = new Map<Id,Lead>();
      //DuplicateCheck.DupeWrapper[] workableRecs = new DuplicateCheck.DupeWrapper[]{}; 
      
      for (DuplicateCheck.DupeWrapper dupeWrap : DuplicateCheck.allRecsChecked) {
         // if there's a contact match, use that
         if (dupeWrap.matchCtct != null) {
            handleCtctMatch(dupeWrap);
            //checkNotWorkable(dupeWrap.rec, nonWorkableLeadMap, workableRecs);
         } else if (dupeWrap.matchAcct != null) {
            // if there's an account match, create a new contact
            handleAcctMatch(dupeWrap);
            //checkNotWorkable(dupeWrap.rec, nonWorkableLeadMap, workableRecs);
         } else if (dupeWrap.matchLead != null) {
         // if there's a lead match, and incoming record is a lead, use that.
              // would marketo ever create a contact? Don't believe so - because they only match on email
            try {
            handleLeadMatch(dupeWrap);
            } catch (Exception e) {
               String errMsg = 'exception: '+e.getMessage()+'; '+e.getStackTraceString();
               ErrorLog.logError('DuplicateCheckQueueable', 'checkDupeResults', 'calling handleLeadMatch', dupeWrap.rec.Id, errMsg, dupeWrap.rec, true);
            }
            //checkNotWorkable(dupeWrap.rec, nonWorkableLeadMap, workableRecs);
         } else {
            // no matches found - continue processing this record
            recsForTrackRecordEntry.add(dupeWrap.rec);
            if (dupeWrap.rec.id.getSobjectType() == Schema.Lead.SObjectType) {
               leadsToUpdate.add((Lead)dupeWrap.rec);
            }
         }
      } // for (DuplicateCheck.DupeWrapper
      for (Lead ld : leadsToUpdate) {
         addToLog('ld='+ld.LastName+' dupeStatus='+ld.DuplicateCheckStatus__c);
      }
      
      //addToLog('nonWorkableLeadMap='+nonWorkableLeadMap.size());
      //if (!nonWorkableLeadMap.isEmpty()) {
      //   AmplifinityHelper.checkNotWorkableLeads(nonWorkableLeadMap,runLog);
      //}
   } // checkDupeResults
   
   // check if a lead is marked as not workable
   /*
   public void checkNotWorkable(SObject rec, Map<Id,Lead> nonWorkableLeadMap, DuplicateCheck.DupeWrapper[] workableRecs) {
      if (rec != null && rec.id.getSobjectType() == Schema.Lead.SObjectType) {
         Lead ld = (Lead)rec;
         Boolean notWorkable = (String.isNotBlank(ld.DuplicateCheckStatus__c) && ld.DuplicateCheckStatus__c.contains(NOT_WORKABLE));
         addToLog('ld='+ld.LastName+' dupeStatus='+ld.DuplicateCheckStatus__c+' notWorkable='+notWorkable);
         if (notWorkable) {
            nonWorkableLeadMap.put(ld.Id,ld);
         }
      } // if (rec != null
      
   } // checkNotWorkable
   */
   public Lead[] leadsToDelete = new Lead[]{};
   public Contact[] ctctsToUpdate = new Contact[]{};
   public Contact[] ctctsToInsert = new Contact[]{};
   public Lead[] leadsToUpdate = new Lead[]{};
   public Map<Id,Lead> leadToUpdateMap = new Map<Id,Lead>();
   
   public void checkSave() {
      // skip after triggers. Before still have to execute to hit the data governance rules
      //LeadMethods.LEAD_BEFORE_EXECUTING = true;
      LeadMethods.LEAD_AFTER_EXECUTING = true;
      //ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      CheckDataGovernance.ONLY_DATA_GOVERNANCE = true;
      DmlHelper.performDML2(leadsToDelete, DmlHelper.DML_DELETE, 'DuplicateCheckQueueable', 'checkSave', 'Delete new leads', false);
      System.debug('checkSave leadsToUpdate='+leadsToUpdate.size());
      addToLog('leadsToUpdate='+leadsToUpdate.size());
      System.debug('checkSave lead='+(!leadsToUpdate.isEmpty() ? leadsToUpdate[0] : null));
      try {
      DmlHelper.performDML2(leadsToUpdate, DmlHelper.DML_UPDATE, 'DuplicateCheckQueueable', 'checkSave', 'Update existing leads', false);
      DmlHelper.performDML2(ctctsToUpdate, DmlHelper.DML_UPDATE, 'DuplicateCheckQueueable', 'checkSave', 'Update existing contacts', false);
      DmlHelper.performDML2(ctctsToInsert, DmlHelper.DML_INSERT, 'DuplicateCheckQueueable', 'checkSave', 'Insert new contacts', false);
      } catch (Exception e) {
         ErrorLog.logError('DuplicateCheckQueueable', 'checkSave', 'Save Exception', null, e);
      }
      ErrorLog.checkSave();
      saveLog();
   } // checkSave
   
   public static String CTCT_COPY_FLDS=Label.DuplicateCheck_CtctCopyFlds;
   
   public void handleCtctMatch(DuplicateCheck.DupeWrapper dupeWrap) {
      if (dupeWrap.rec.id.getSobjectType() == Schema.Lead.SObjectType) {
         // we are going to switch over to the contact. If the contact doesn't have a transaction id we'll use the 
         // one from the lead. If it does, we'll switch out the map to use the one currently on the contact
         Lead ld = (Lead)dupeWrap.rec;
         Contact ctct = dupeWrap.matchCtct;
         Account acct = dupeWrap.matchCtct.Account;
         
         //checkAddtionalAcctCtctCriteria(ld, acct.Id, runLog);
         // to save the process notes on the record.
         LeadMethods.LEAD_BEFORE_EXECUTING = true;
         LeadMethods.LEAD_AFTER_EXECUTING = true;
         update ld;
         LeadMethods.LEAD_BEFORE_EXECUTING = false;
         LeadMethods.LEAD_AFTER_EXECUTING = false;
         System.debug('handleCtctMatch 1 ctct='+ctct);
         
         // update fields from what came in on the form
         Boolean isProfiled = ctct.Profiled__c;
         Set<String> profiledFldSet = (isProfiled ? DuplicateCheck.getDGFieldSet(ObjectHelper.OBJECT_CONTACT) : new Set<String>());
         prepareFldCopy(ctct, ctct, ld, profiledFldSet, CTCT_COPY_FLDS);

         checkDescriptions(ctct, ld);
         checkAcctFlds(acct, ld);

         
         // make a clone of the contact so we have a value for oldMap in the Before trigger			CMFCMF
         Contact oldCtct = ctct.clone(true, false, false, false);         
		 Map<Id, sObject> oldCtctMap = new Map<Id, sObject>();
		 oldCtctMap.put(oldCtct.Id, oldCtct);

         // check the stage Name
         //checkMarketingStage(ctct, ld.Lead_Stage__c);
         checkMarketingStage(ctct, 'Contact_Stage__c', ld.Lead_Stage__c);
         
         StringHelper.addToProcessNotes(ctct,'DuplicateCheckQueueable Merged lead '+ld.Id+' ProcessNotes: '+(String.isNotBlank(ld.ProcessNotes__c) ? ld.ProcessNotes__c : ''));
         System.debug('handleCtctMatch ctct processNotes='+ctct.ProcessNotes__c);
         // skip the triggers
         ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;       
         ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;     
 
         DoNotSyncCheck.checkCreatedByProcess(ctct);
         // update ctct;
         // run the before code we need to set the contact stage date		CMFCMF
         List<sObject> existCtctList = new List<sObject>();
		 existCtctList.add(ctct);
		 DG_LMF_Service.checkRecordStages(existCtctList, oldCtctMap, 'Contact_Stage__c', false, true);
         // now update the contact
		 update existCtctList;
		  
         System.debug('handleCtctMatch 2 ctct='+ctct);
         // convert the lead, into the account id.
         Id ctctId = convertLead(ld, acct, ctct);
         //Contact checkCtct = [Select Id, Name, AccountId, TransactionId__c, ProcessNotes__c from Contact where Id=:ctctId];
         //System.debug('handleCtctMatch ctct='+ctct.Id+' checkCtct='+checkCtct);
         recsForTrackRecordEntry.add(ctct);
         addToLog('matched lead to contact ld='+ld.TransactionId__c+' ctct='+ctct.TransactionId__c+' dupeCheckMap containsKey='+dupeCheckMap.containsKey(ctct.TransactionId__c));
         //leadsToDelete.add(ld);
         
         // run the after code we need to create the stage history record
		 DG_LMF_Service.evaluateStageHistory('Contact', existCtctList, oldCtctMap);
      } // if (dupeWrapper.rec.id.getSobjectType() == Schema.Lead.SObjectType
   } // handleCtctMatch

   public static Map<String,String> prevStageMap = new Map<String,String>(); 
   
   // compare the incoming stage to the existing stage on the matched contact/lead.
   // see which one we keep.
   public static void checkMarketingStage(SObject rec, String stageFldName, String newStage) {
      String existingStage = (String)rec.get(stageFldName);
      String stageMsg = '';
      if (String.isBlank(newStage)) {
         stageMsg = 'No Lead Stage, existingStage='+existingStage;
         // do nothing if there isn't a lead stage - whatever is on the contact will stay.
      } else if (String.isBlank(existingStage)) {
         // there is a lead stage but not a contact stage - use only the lead stage
         stageMsg = 'No existing Marketing Stage - setting stage to '+newStage;
         rec.put(stageFldName,newStage);
      } else if (existingStage != newStage) {
         // there is both a contact and lead stage and they are different - see which one wins.
         Map<String,Integer> rankingMap = getStageRankings(existingStage, newStage);
         Integer existRank = (rankingMap.containsKey(existingStage) ? rankingMap.get(existingStage) : -10);
         Integer leadRank = (rankingMap.containsKey(newStage) ? rankingMap.get(newStage) : -10);
         stageMsg = 'existingStage='+existingStage+' existRank='+existRank+' newStage='+newStage+' leadRank='+leadRank;
         if (leadRank > existRank) {
            stageMsg += '; changing Marketing Stage to '+newStage;
            rec.put(stageFldName,newStage);
         } else {
            stageMsg += '; not changing Marketing Stage';
         }
      }
      StringHelper.addToProcessNotes(rec,stageMsg);
      // store the stage we changed from in a map so we can set it on the partner referral
      if (existingStage != (String)rec.get(stageFldName)) {
         String transactionId = (String)rec.get('TransactionId__c');
         if (transactionId != null) {
            prevStageMap.put(transactionId, existingStage);
         }
      }
      
   } // checkMarketingStage

   public static Map<String,Integer> getStageRankings(String stage1, String stage2) {
      Map<String,Integer> rankingMap = new Map<String,Integer>();
      String[] queryStages = new String[]{stage1,stage2};
      MarketingStage__mdt[] mktgStages = [Select MasterLabel, SortOrder__c from MarketingStage__mdt where MasterLabel in :queryStages];
      for (MarketingStage__mdt mktgStage : mktgStages) {
         rankingMap.put(mktgStage.MasterLabel, Integer.valueOf(mktgStage.SortOrder__c));
      }
      return rankingMap;
   } // getStageRankings
   
   public static void prepareFldCopy(SObject copyTo, SObject copyTo2, SObject copyFrom, Set<String> profiledFldSet, String fldCopySetup) {
      prepareFldCopy(copyTo, copyTo2, copyFrom, profiledFldSet, fldCopySetup, null);
   } // prepareFldCopy
   
   public static void prepareFldCopy(SObject copyTo, SObject copyTo2, SObject copyFrom, Set<String> profiledFldSet, String fldCopySetup, ErrorLog__c log) {
      // divide the tokens into 4 components: copy to fld, copy from fld, is the field boolean, do you only copy if blank
      Boolean exceptionsOccurred = false;
      String[] fldTokens = fldCopySetup.split(':');
      System.debug('prepareFldCopy fldTokens='+fldTokens.size());
      ErrorLog.addToDescription(log,'fldTokens='+fldTokens.size());
      for (String fldToken : fldTokens) {
         String[] fldComponents = fldToken.split(',');
         ErrorLog.addToDescription(log,'fldToken='+fldToken+' fldComponents='+fldComponents.size());
         try {
            String copyToFldName = fldComponents[0];
            String copyFromFldName = fldComponents[1];
            Boolean isBoolean = fldComponents[2] == 'true';
            Boolean onlyCopyIfBlank = fldComponents[3] == 'true';
            checkFldCopy(copyTo, copyTo2, copyToFldName, copyFrom, copyFromFldName, isBoolean, onlyCopyIfBlank, profiledFldSet);
         } catch (Exception e) {
            exceptionsOccurred = true;
            String errMsg = 'fldComponents='+fldComponents+' exception: '+e.getMessage()+'; '+e.getStackTraceString();
            ErrorLog.logError('DuplicateCheckQueueable', 'prepareFldCopy', 'trying to copy fields', copyFrom.Id, errMsg, copyFrom, false);
            //System.debug('prepareFldCopy fldComponents='+fldComponents+' exception: '+e.getMessage()+'; '+e.getStackTraceString());
         }
      } // for (String fldToken
      if (exceptionsOccurred) {
         ErrorLog.checkSave();
      }
   } // prepareFldCopy
   
   // copyTo contains the data, copyTo2 is what we're writing to. They may or may not be the same.
   public static void checkFldCopy(SObject copyTo, SObject copyTo2, String copyToFldName, SObject copyFrom, String copyFromFldName, Boolean isBoolean, Boolean onlyCopyIfBlank, Set<String> profiledFldSet) {
      Boolean profiledFld = profiledFldSet.contains(copyToFldName);
      Boolean copyToHasValue = (copyTo.get(copyToFldName) != null);
      Boolean copyFromHasValue = (copyFrom.get(copyFromFldName) != null);
      if (isBoolean) {
         copyToHasValue = (copyTo.get(copyToFldName) != null && (Boolean)copyTo.get(copyToFldName));
         copyFromHasValue = (copyFrom.get(copyFromFldName) != null && (Boolean)copyFrom.get(copyFromFldName));
      }
      Boolean okayToCopy = (copyFromHasValue && 
                             ((onlyCopyIfBlank && !copyToHasValue)  // if the copy to does not have a value
                              || (onlyCopyIfBlank && profiledFld)  // it doesn't matter if the copy to has a value, in this case we assume the profiled is on the copy from side (lead to lead copy)
                              || (!onlyCopyIfBlank && !profiledFld) // the profiled is on the copy to side, so we won't copy if the field is profiled, even though the general rule is to overwrite everything (lead to account/contact copy)
                           ));
      System.debug('checkFldCopy copyToFldName='+copyToFldName+' okayToCopy='+okayToCopy); 
      if (okayToCopy) {
         copyTo2.put(copyToFldName, copyFrom.get(copyFromFldName));
      }
   } // checkFldCopy
   
   public static String ACCT_COPY_FLDS=Label.DuplicateCheck_AcctCopyFlds;
   //public static String ACCT_COPY_FLDS='Name,Company,false,false:BillingStreet,Street,false,false:BillingCity,City,false,false'
   //                                   +':BillingState,State,false,false:BillingPostalCode,PostalCode,false,false'
   //                                   +':Employees__c,NumberOfEmployees,false,false';
   
   public void checkAcctFlds(Account acct, Lead ld) {
      // copy the values from the lead to the account, check if account is profiled
      Boolean isProfiled = acct.Profiled__c;
      // if the account is profiled, don't overwrite the profiled fields.
      Set<String> profiledFldSet = (isProfiled ? DuplicateCheck.getDGFieldSet(ObjectHelper.OBJECT_ACCOUNT) : new Set<String>());
      prepareFldCopy(acct, acct, ld, profiledFldSet, ACCT_COPY_FLDS);

      ZipCheckOwner.SKIP_TRIGGERS = true;
      update acct;
   } // checkAcctFlds
   
   public void handleAcctMatch(DuplicateCheck.DupeWrapper dupeWrap) {
      if (dupeWrap.rec.id.getSobjectType() == Schema.Lead.SObjectType) {
         Lead ld = (Lead)dupeWrap.rec;

         Account acct = dupeWrap.matchAcct;
         // check for the workable information
         //checkAddtionalAcctCtctCriteria(ld, acct.Id, runLog);

         // to save the process notes on the record.
         LeadMethods.LEAD_BEFORE_EXECUTING = true;
         LeadMethods.LEAD_AFTER_EXECUTING = true;
         update ld;
         LeadMethods.LEAD_BEFORE_EXECUTING = false;
         LeadMethods.LEAD_AFTER_EXECUTING = false;
         
         checkAcctFlds(acct, ld);
         
         // convert the lead, into the account id.
         Id ctctId = convertLead(ld, acct, null);
         if (ctctId != null) {
            Contact ctct = [Select Id, Name, AccountId, OwnerId, TransactionId__c, ProcessNotes__c,OwnedByPrev__c,OwnedBy__c 
                                  ,DuplicateCheckStatus__c
                                  ,DuplicateNotWorkableReason__c,Form_Fill_Date__c
                              from Contact where Id=:ctctId];
            recsForTrackRecordEntry.add(ctct);
         } else {
            System.debug('Error converting lead ctctId='+ctctId);
         }
         
      } // if (dupeWrapper.rec.id.getSobjectType() == Schema.Lead.SObjectType
   } // handleAcctMatch

   public static Boolean LEAD_WAS_CONVERTED=false;
   
   public static Id convertLead(Lead leadToConvert, Account acct, Contact ctct) {
      return convertLead(leadToConvert, acct, ctct, true);
   }

   public static Id overrideOwnerId = null;

   public static Id convertLead(Lead leadToConvert, Account acct, Contact ctct, Boolean skipLeadTriggers) {
      // if the account has an inactive owner it will fail.
      Id ownerIdToReset = null;
      Boolean acctOwnerInActive = (acct != null && acct.Owner != null && !acct.Owner.IsActive);
      System.debug('convertLead acctOwnerInActive='+acctOwnerInActive);
      String convertLog = 'convertLead acctOwnerInActive='+acctOwnerInActive;
      if (acctOwnerInActive) {
         
         ownerIdToReset = acct.OwnerId;
         User sfdcData = UserHelper.getSfdcData(); 
         System.debug('convertLead sfdcData='+sfdcData);
         if (sfdcData != null) {
            acct.OwnerId=sfdcData.Id;
            ZipCheckOwner.SKIP_TRIGGERS=true;
            update acct;
            System.debug('convertLead updated acct');
            convertLog += '; ownerId updated to '+sfdcData.Id;
         }
      }
      
      DG_DFR_Controller.enteredLeadConversion = true;
      Database.LeadConvert lc = new Database.LeadConvert();
       
      lc.setLeadId(leadToConvert.Id);
      lc.setDoNotCreateOpportunity(true);
      System.debug('convertLead acct='+acct);
      Id ownerId = (overrideOwnerId != null ? overrideOwnerId : (acct != null ? acct.OwnerId : (ctct != null ? ctct.OwnerId : null)));
      if (ownerId != null) {
         lc.setOwnerId(ownerId);
      }
      Id acctId = (acct != null ? acct.Id : ctct != null ? ctct.AccountId : null);
      if (acctId != null) {
         lc.setAccountId(acctId);
      }
      if (ctct != null) {
         lc.setContactId(ctct.Id);
      }
      lc.setOverwriteLeadSource(false);
      System.debug('convertLead ld='+leadToConvert.Company+' ownerId='+ownerId+' acctId='+acctId);
       
      CreateOppAndMeeting coam = new CreateOppAndMeeting(UserHelper.SO_CORE);
      lc.setConvertedStatus(coam.getConvertStatus().MasterLabel);
      //LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
      //lc.setConvertedStatus(convertStatus.MasterLabel);
      Database.Leadconvertresult lcr = null;
      LEAD_WAS_CONVERTED = true;       
       
      ErrorLog.addToDescription(runLog,convertLog);
      if (skipLeadTriggers) {
         LeadMethods.LEAD_BEFORE_EXECUTING = true;
         LeadMethods.LEAD_AFTER_EXECUTING = true;
      }
      try {
         lcr = Database.convertLead(lc);
      } catch (Exception e) {
         // return to the main lead page.
         ErrorLog.logError('DuplicateCheckQueueable', 'convertLead', 'Converting the Lead', leadToConvert.Id, e, leadToConvert, true);
         System.debug('convertLead exception: '+e.getMessage()+'; '+e.getStackTraceString());
         return null;
      } // try
      System.debug('Convert Result :'+lcr);
      if (!lcr.isSuccess()) {
         Database.Error err = lcr.getErrors()[0];
         ErrorLog.logError('DuplicateCheckQueueable', 'convertLead', 'Convert Not Successful', leadToConvert.Id, String.valueOf(err), leadToConvert, true);
         System.debug('convertLead error in converting: '+err);
         return null;
      } else if (ownerIdToReset != null) {
         // set the account id back to what it was
         Account updateOwnerAcct = new Account(Id=acct.Id, OwnerId=ownerIdToReset);
         update updateOwnerAcct;
      }
      
      return lcr.getContactId();
   } // convertLead
   
   // the fields we won't copy
   //public static Set<String> excludeCopyFldSet = new Set<String>{'Id','IsUnreadByOwner','LeadGroupId__c','Dataflux_Id__c','Do_Not_Sync__c'};
   public static Set<String> excludeCopyFldSet = new Set<String>(Label.DuplicateCheckQueueable_ExcludeFlds.split(','));
   
   public static void copyFlds(SObject keepRec, SObject deleteRec, SObject newRec, String objectApiName, Boolean isProfiled) {
      //String[] copyFlds = ObjectHelper.fieldNameByObjectNameMap.get(objectApiName);
      DuplicateCheck.DGFieldSetsCache objInfo = DuplicateCheck.getObjectInfo(objectApiName);
      String[] copyFlds = (objInfo != null ? objInfo.flds : new String[]{});
      
      Set<String> profiledFldSet = DuplicateCheck.getDGFieldSet(objectApiName);
      // this call is just to make sure this is set in the cache
      ObjectHelper.getSOQLQuery(objectApiName, null, true, true, true, false);
      Set<String> booleanFldSet = ObjectHelper.booleanFldSetsByObjectMap.get(objectApiName);
      
      if (copyFlds != null && keepRec != null && deleteRec != null) {
         for (String fldName : copyFlds) {
            try {
               System.debug('copyFlds fldName='+fldName);
               if (deleteRec.get(fldName) != null && !excludeCopyFldSet.contains(fldName)) {
                  checkFldCopy(keepRec, newRec, fldName, deleteRec, fldName, booleanFldSet.contains(fldName), true, profiledFldSet);
               }
            } catch (Exception e) {
            //exceptionsOccurred = true;
            String errMsg = 'fldName='+fldName+' exception: '+e.getMessage()+'; '+e.getStackTraceString();
            ErrorLog.logError('DuplicateCheckQueueable', 'copyFlds', 'trying to copy '+fldName, keepRec.Id, errMsg, keepRec, false);
            //System.debug('prepareFldCopy fldComponents='+fldComponents+' exception: '+e.getMessage()+'; '+e.getStackTraceString());
         }
            
         } // for (String fldName
      } // if (copyFlds
      ErrorLog.checkSave(); 
   } // copyFlds
       
   
   public void handleLeadMatch(DuplicateCheck.DupeWrapper dupeWrap) {
      if (dupeWrap.rec.id.getSobjectType() == Schema.Lead.SObjectType) {
         // this will be the surviving lead. 
         Lead ld = (Lead)dupeWrap.rec;
         // this was found existing - we will merge this with the one just created.
         Lead matchLd = dupeWrap.matchLead;
         Lead newLd = new Lead(Id=ld.Id, TransactionId__c=ld.TransactionId__c, OwnerId=matchLd.OwnerId);
         // we need to handle the description up here and save it to the surviving record so it survives the merge
         checkDescriptions(matchLd, ld);
         checkMarketingStage(matchLd, 'Lead_Stage__c', ld.Lead_Stage__c);
         
         ld.Description = matchld.Description;
         //System.debug('handleLeadMatch ld='+ld);
         //System.debug('handleLeadMatch matchLd='+matchLd);
         // any other field updates would happen here.
         copyFlds(ld, matchLd, newLd, ObjectHelper.OBJECT_LEAD, false);
         StringHelper.addToProcessNotes(newLd,'DuplicateCheckQueueable Merged lead '+matchLd.Id+' ProcessNotes: '+(String.isNotBlank(matchLd.ProcessNotes__c) ? matchLd.ProcessNotes__c : ''));

         // check existing record to see if there is any activity against it.
         matchLd.DuplicateCheckStatus__c = ld.DuplicateCheckStatus__c;
         //checkAdditionalLeadCriteria(matchLd, runLog);
         newLd.DuplicateCheckStatus__c = matchLd.DuplicateCheckStatus__c;
         newLd.DuplicateNotWorkableReason__c = matchLd.DuplicateNotWorkableReason__c;
         
                  
         // Using the Apex merge operation, field values on the master record always supersede the 
         // corresponding field values on the records to be merged. To preserve a merged record field value, 
         // simply set this field value on the master sObject before performing the merge.
         // make sure the triggers don't fire.
         LeadMethods.LEAD_BEFORE_EXECUTING = true;
         LeadMethods.LEAD_AFTER_EXECUTING = true;
         System.debug('handleLeadMatch newLd='+newLd);
         update newLd;

         try {
            Database.merge(newLd, matchLd);
         } catch (Exception e) {
            System.debug('handleLeadMatch merge exception: '+e.getMessage()+'; '+e.getStackTraceString());
         }

         System.debug('handleLeadMatch ld.TransactionId__c='+ld.TransactionId__c+' matchLd='+matchLd.TransactionId__c+' newLd='+newLd.TransactionId__c);

         recsForTrackRecordEntry.add(newLd);
         //leadsToDelete.add(ld);
      } // if (dupeWrapper.rec.id.getSobjectType() == Schema.Lead.SObjectType
   } // handleLeadMatch
   
   public static final Integer DESC_SIZE = Contact.Description.getDescribe().getLength();

   // append the descriptions together
   public static void checkDescriptions(SObject keepRec, SObject checkRec) {
      //String appender = '\nEnd Weblead '+Datetime.now().format('MM/dd/yyyy hh:mm a')+'\n';
      String appender = '\n\n';
      StringHelper.appendFields(keepRec, 'Description', checkRec, 'Description', appender, DESC_SIZE);
   } // checkDescriptions

   public static void launchQueueable(Map<String, PartnerReferral__c> p_dupeCheckMap, SObject[] p_recsToCheck) {
      Apex_Batch_Control__c abc = getBatchControl();
      System.debug('launchQueueable p_recsToCheck='+p_recsToCheck.size()+' p_dupeCheckMap='+p_dupeCheckMap.size()+' testing='+Test.isRunningTest()+' abc='+abc);
      // enqueue this back up if there are more records to process and we're not running a test
      if (!Test.isRunningTest() && abc != null && abc.Active__c && !p_recsToCheck.isEmpty()) {
         // re-enqueue the job - can't chain the jobs from tests
         DuplicateCheckQueueable dcq = new DuplicateCheckQueueable(p_dupeCheckMap, p_recsToCheck);
         System.enqueueJob(dcq);
      }
   } // launchQueueable
   
   public void addToLog(String notesToAdd) {
      StringHelper.addNotesToField(runLog, 'Description__c', ErrorLog.DESCRIPTION_SIZE, notesToAdd, true); 
   } // addToLog
   
   public void saveLog() {
      Apex_Batch_Control__c abc = getBatchControl();
      if (abc != null && abc.LogProcess__c && runLog != null) {
         ErrorLog.saveErrorLog(runLog);
      }
   } // saveLog
   
} // class DuplicateCheckQueueable