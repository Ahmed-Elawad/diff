/** Queueable process to update Accounts/Leads based on CAR updates
 * 
 * History
 * -------
   09/23/2019   Jermaine Stukes         Created
   03/30/2019   Dan Carmen              Add Last Cadence Name
   05/08/2020   Dan Carmen              Fix the calculation of latest cadence info.
   02/09/2021   Jermaine Stukes			Added last Close reason
   05/24/2021   Dan Carmen              Add Referral Account
   04/10/2022   Susmitha Somavarapu     Daily job is run to re-evaluate all records to ensure that they are updated
   08/29/2022   Dan Carmen              Add additional debug when running as a queueable
   10/10/2022   Dan Carmen              Fix to set flag correctly with bulk load
   02/03/2023   Dan Carmen              Check for nulls

*/
public class CadenceQueueable implements Queueable {
   public static Boolean queueableLaunched = false;
   public static String CLASSNAME = 'CadenceQueueable';

   //Wrapper returned to work queue component
   public List<String> carQueryList = new List<String>();
   public class ObjectUpdateWrapper {
      public Id objectId;

      public ObjectUpdateWrapper(Id p_objectId) {
         objectId = p_objectId;
         SObjectType objType = objectId.getSObjectType();
         isLead = (objType == Lead.sObjectType);
         isAcct = (objType == Account.sObjectType);
         isRefAcct = (objType == Referral_Account__c.sObjectType);
      } // ObjectUpdateWrapper

      public ObjectUpdateWrapper(Lead p_ld) {
         objectId = p_ld.Id;
         ld=p_ld;
         isLead=true;
         recName=p_ld.Name;
      } // ObjectUpdateWrapper

      public ObjectUpdateWrapper(Account p_acct) {
         objectId = p_acct.Id;
         acct=p_acct;
         isAcct=true;
         recName=p_acct.Name;
      } // ObjectUpdateWrapper

      public ObjectUpdateWrapper(Referral_Account__c p_acct) {
         objectId = p_acct.Id;
         refAcct=p_acct;
         isRefAcct=true;
         recName=p_acct.Name;
      } // ObjectUpdateWrapper

      public String recName=null;
      public Boolean isLead=false;
      public Boolean isAcct=false;
      public Boolean isRefAcct=false;
      public List<String> cadence_types = new List<String>();
      public Boolean inCadence = false;
      public Account acct = null;
      public Lead ld = null;
      public Referral_Account__c refAcct = null;
      // the car record with the latest closed date
      public Cadence_Assignment_Record__c latestClosed = null;
      public Cadence_Assignment_Record__c latestOpen = null;
      public Boolean canSetLatestOwner {
         get {
            Boolean canSet = (latestOpen != null && latestOpen.Cadence__r.SetOwnerHoldout__c != null && latestOpen.Cadence__r.SetOwnerHoldout__c > 0);
            if (canSet) {
               // make sure the owner is a user
               String ownerId = latestOpen.OwnerId;
               canSet = ownerId.startsWith(ObjectHelper.PREFIX_USER);
            } // if (canSet)
            return canSet;
         } // get
      } // canSetLatestOwner
       public DateTime latestCreateDate = null;
       public String latestCadenceName = null;
       public String latestOpenCadenceName = null;
       public String latestCloseReason = null;
   } // class ObjectUpdateWrapper
    
    public CadenceQueueable() {
       
    } // CadenceQueueable
    
    public CadenceQueueable(List<String> queryIds) {
        carQueryList = queryIds;
    } // CadenceQueueable
    
    public Map<Id, ObjectUpdateWrapper> setupWrappers() {
       Map<Id, ObjectUpdateWrapper> parentObjectMap = new Map<Id, ObjectUpdateWrapper>();
       Id[] acctQueryIds = new Id[]{};
       Id[] leadQueryIds = new Id[]{};
       Id[] refAcctQueryIds = new Id[]{};
       debugLog.ObjectId__c = carQueryList[0];
       for (Id chkId : carQueryList) {
          if (chkId != null) {
             ObjectUpdateWrapper ouw = new ObjectUpdateWrapper(chkId);
             if (ouw.isAcct) {
                acctQueryIds.add(chkId);
             } else if (ouw.isLead) {
                leadQueryIds.add(chkId);
             } else if (ouw.isRefAcct) {
                refAcctQueryIds.add(chkId);
             }
             parentObjectMap.put(chkId, ouw);
               
          } // if (chkId != null
       } // for (Id chkId
       System.debug('setupWrappers acctQueryIds='+acctQueryIds.size()+' leadQueryIds='+leadQueryIds.size()+' refAcctQueryIds='+refAcctQueryIds.size());
       debugLog.BatchSize__c = parentObjectMap.size();
       ErrorLog.addToDescription(debugLog,'acctQueryIds='+acctQueryIds.size()+' leadQueryIds='+leadQueryIds.size()+' refAcctQueryIds='+refAcctQueryIds.size());
       Account[] accts = (acctQueryIds.isEmpty() ? new Account[]{}
                                     : [Select Id, Name,In_Cadence__c, CadenceType__c, ProcessNotes__c
                                              ,LastCadenceClosedDate__c, LastCadenceClosedType__c, LastCadenceName__c,LastCadenceClosedReason__c
                                              ,OwnerId, Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c
                                          from Account where Id in :acctQueryIds]);
       Lead[] leads = (leadQueryIds.isEmpty() ? new Lead[]{}
                                     : [Select Id, Name, LastName, In_Cadence__c, CadenceType__c, ProcessNotes__c 
                                              ,LastCadenceClosedDate__c, LastCadenceClosedType__c, LastCadenceName__c, LastCadenceClosedReason__c
                                              ,OwnerId, Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c
                                          from Lead where Id in :leadQueryIds]);
       Referral_Account__c[] refAccts = (refAcctQueryIds.isEmpty() ? new Referral_Account__c[]{}
                                      : [Select Id, Name, CadenceType__c, In_Cadence__c, ProcessNotes__c
                                              ,LastCadenceClosedDate__c, LastCadenceClosedType__c, LastCadenceName__c,LastCadenceClosedReason__c
                                          from Referral_Account__c where Id in :refAcctQueryIds]);
       for (Account acct : accts) {
          ObjectUpdateWrapper ouw = parentObjectMap.get(acct.Id);
          if (ouw != null) {
             ouw.acct = acct;
          }
       } // for (Account acct : accts                                  
       
       for (Lead ld : leads) {
          ObjectUpdateWrapper ouw = parentObjectMap.get(ld.Id);
          if (ouw != null) {
             ouw.ld = ld;
          }
       } // for (Lead ld : leads
        
       for (Referral_Account__c refAcct : refAccts) {
          ObjectUpdateWrapper ouw = parentObjectMap.get(refAcct.Id);
          if (ouw != null) {
             ouw.refAcct = refAcct;
          }
       } // for (Referral_Account__c refAcct : refAccts
       return parentObjectMap;
    } // setupWrappers
    
   public void updateCarParentObjects(Map<Id, ObjectUpdateWrapper> parentObjectMap, Boolean updateRecords){
      //Grab CAR list based on carQueryList
       List<Cadence_Assignment_Record__c> carList = [Select Id, Name, OwnerId, AccountId__c,Cadence__c, Cadence__r.Cadence_Type__c
                                                     , Cadence__r.Name, Cadence__r.SetOwnerHoldout__c,Cadence__r.Priority__c
                                                     , CloseReason__c
                                                     , LeadId__c, ReferralAccount__c, Start_Date__c
                                                     , LastModifiedDate, Status__c, Touchpoint_Created_Successfully__c  
                                                     , Closed__c, Close_Date__c, RepClosed__c, CreatedDate
                                                     , (Select Id from Cadence_Touchpoints__r )
                                                     from Cadence_Assignment_Record__c 
                                                     where (AccountId__c in :parentObjectMap.keySet()
                                                            or LeadId__c in :parentObjectMap.keySet()
                                                            or ReferralAccount__c in :parentObjectMap.keySet()) 
                                                     order by Cadence__r.Priority__c DESC NULLS LAST, CreatedDate DESC];
      
      System.debug('updateCarParentObjects parentObjectMap='+parentObjectMap.size()+' carList='+carList.size());
      ErrorLog.addToDescription(debugLog,'updateCarParentObjects parentObjectMap='+parentObjectMap.size()+' carList='+carList.size());
      //Update Map 
      //Boolean hasopen = false;
      for (Cadence_Assignment_Record__c carRec : carList){
         String cadenceType = carRec.Cadence__r.Cadence_Type__c;
         // don't use CAR records that don't have touchpoints
         System.debug('updateCarParentObjects carRec='+carRec.Name+' touchpoints='+carRec.Cadence_Touchpoints__r.size()+' cadenceType='+cadenceType);
         if (!carRec.Cadence_Touchpoints__r.isEmpty() && String.isNotBlank(cadenceType)) {
            Id parentObjectId = (carRec.AccountId__c != null ? carRec.AccountId__c 
                               : (carRec.LeadId__c != null ? carRec.LeadId__c : carRec.ReferralAccount__c));
            System.debug('updateCarParentObjects car='+carRec.Name+' parentObjectId='+parentObjectId);
            if (parentObjectId != null) {
               Boolean isOpen = carRec.Status__c == 'Open' ? true : false;
               //hasopen = (isOpen == true && hasopen == false ?  true:  hasopen );
               System.debug('updateCarParentObjects car='+carRec.Name+' isOpen='+isOpen);
               //Parent Object in multiple cadences
               // all wrappers should already exist at this point
               ObjectUpdateWrapper ouw = parentObjectMap.get(parentObjectId);
               if (ouw != null) {
                 //  ouw.inCadence = (ouw.inCadence && isOpen ? true : );
                 // updated logice to make only indacence true while is open. else false
                 ouw.inCadence = (ouw.inCadence || isOpen);
                 System.debug('updateCarParentObjects ouw.inCadence='+ouw.inCadence);
                   if (isOpen && ouw.latestOpenCadenceName == null) {
                       ouw.latestOpen = carRec;
                       ouw.latestOpenCadenceName = carRec.Cadence__r.Name;
                       ouw.latestCloseReason = carRec.CloseReason__c;
                   }
                   if (isOpen && !ouw.cadence_types.contains(cadenceType)){
                       ouw.cadence_types.add(cadenceType);
                   } else if (carRec.Closed__c && carRec.RepClosed__c && carRec.Close_Date__c != null) {
                       if (ouw.latestClosed == null || carRec.Close_Date__c > ouw.latestClosed.Close_Date__c) {
                           ouw.latestClosed = carRec;
                       }
                       if (ouw.latestCadenceName == null) {
                           ouw.latestCadenceName = carRec.Cadence__r.Name;
                       }
                       if(ouw.latestCloseReason == null){
                           ouw.latestCloseReason = carRec.CloseReason__c;
                       }
                   }
               } // if (ouw != null         
            } // if (parentObjectId != null
         } // if (!carRec.Cadence_Touchpoints__r.isEmpty()
      } // for (Cadence_Assignment_Record__c carRec
      if (!parentObjectMap.isEmpty()){
         updateParentRecords(parentObjectMap,updateRecords);
      }
   } // updateCarParentObjects
   
   public void updateParentRecords(Map<Id, ObjectUpdateWrapper> parentObjectMap, Boolean updateRecords) {
      Map<Id,Account> updateAccts = new Map<Id,Account>();
      Map<Id,Lead> updateLeads = new Map<Id,Lead>();
      Map<Id,Referral_Account__c> updateRefAccts = new Map<Id,Referral_Account__c>();

      for (ObjectUpdateWrapper ouw : parentObjectMap.values()) {
         ouw.cadence_types.sort();
         String cadenceTypes = String.join(ouw.cadence_types,','); //.removeEnd(',');
         
         if (ouw.acct != null) {
            if (checkForFieldChanges(ouw.acct,ouw, ObjectHelper.OBJECT_ACCOUNT)) {
               updateAccts.put(ouw.acct.Id,ouw.acct);
            }
         } else if (ouw.ld != null) {
            if (checkForFieldChanges(ouw.ld,ouw, ObjectHelper.OBJECT_LEAD)) {
               updateLeads.put(ouw.ld.Id,ouw.ld);
            }
         } else if (ouw.refAcct != null) {
            if (checkForFieldChanges(ouw.refAcct,ouw, ObjectHelper.OBJECT_REF_ACCOUNT)) {
               updateRefAccts.put(ouw.refAcct.Id,ouw.refAcct);
            }
         }
      } // for (ObjectUpdateWrapper ouw
      
      System.debug('updateParentRecords updateRecords='+updateRecords+' updateAccts='+updateAccts.size()+' updateLeads='+updateLeads.size());
      ErrorLog.addToDescription(debugLog,'updateParentRecords updateRecords='+updateRecords+' updateAccts='+updateAccts.size()+' updateLeads='+updateLeads.size()+' updateRefAccts='+updateRefAccts.size());
      if (updateRecords) {
         // we don't need any of the triggers to fire.
         ZipCheckOwner.SKIP_TRIGGERS=true;
         TriggerMethods.SKIP_TRIGGERS=true;
         ReferralAccountMethods.SKIP_TRIGGERS=true;
         DmlHelper.performDML2(updateAccts.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'updateParentRecords', 'Update Account Records', false);
         DmlHelper.performDML2(updateLeads.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'updateParentRecords', 'Update Lead Records', false);
         ReferralAccountMethods.SKIP_TRIGGERS=true;
         DmlHelper.performDML2(updateRefAccts.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'updateParentRecords', 'Update Referral Account Records', false);
         ReferralAccountMethods.SKIP_TRIGGERS=false;
         ErrorLog.checkSave();
      } // if (updateRecords
   } // updateParentRecords
    
   public static String OWNER_HOLD_OUT_REASON=Label.CadenceQueueable_HoldOutReason;
   
   // LastCadenceClosedDate__c, LastCadenceClosedType__c
   public Boolean checkForFieldChanges(SObject rec, ObjectUpdateWrapper ouw, String objectType) {
       Boolean recChanged = false;
       ouw.cadence_types.sort();
       String cadenceTypes = String.join(ouw.cadence_types,','); //.removeEnd(',');
       Date latestClosedDate = (ouw.latestClosed != null ? ouw.latestClosed.Close_Date__c : null);
       String latestType = (ouw.latestClosed != null ? ouw.latestClosed.Cadence__r.Cadence_Type__c : null);
       String latestCadenceName = (ouw.latestOpenCadenceName != null ? ouw.latestOpenCadenceName : ouw.latestCadenceName);
       String latestCloseReason = (ouw.latestCloseReason != null ? ouw.latestCloseReason : null);
       
       Boolean recInCadence = (Boolean)rec.get('In_Cadence__c');
       String recCadTypes = (String)rec.get('CadenceType__c');
       Date recLatestClosedDate = (Date)rec.get('LastCadenceClosedDate__c');
       String recLatestCloseType = (String)rec.get('LastCadenceClosedType__c');
       String recLatestName = (String)rec.get('LastCadenceName__c');
       String recLatestCloseReason = (String)rec.get('LastCadenceClosedReason__c');
       
       if (ouw.inCadence != recInCadence 
           || cadenceTypes != recCadTypes 
           || latestClosedDate != recLatestClosedDate
           || latestType != recLatestCloseType
           || latestCadenceName != recLatestName
           || latestCloseReason != recLatestCloseReason) {
               recChanged = true;
               rec.put('LastCadenceClosedType__c',latestType);
               rec.put('LastCadenceName__c',latestCadenceName);
               rec.put('CadenceType__c',cadenceTypes);
               rec.put('In_Cadence__c',ouw.inCadence);
               rec.put('LastCadenceClosedDate__c',latestClosedDate);
               rec.put('LastCadenceClosedReason__c',latestCloseReason);
               String info='In_Cadence='+ouw.inCadence+' CadenceType='+cadenceTypes+' latestClosedDate='+latestClosedDate+' latestType='+latestType+' latestCadence='+ouw.latestCadenceName+' lastCadenceReason='+ouw.latestCloseReason;
               System.debug('checkForFieldChanges acct='+ouw.recName+' '+info);
               StringHelper.addToProcessNotes(rec,'CadenceQueueable updated '+info);
           }
       // do we need to set a holdout on the account/lead if 1) there isn't already a holdout and 2) the owners are different
       if (ouw.canSetLatestOwner) {
         // right now we're only using the main owner field on the account - but this could change in the future
         HoldOut_ExpirationDates__c hed = HoldOut_ExpirationDates__c.getInstance(UserHelper.SO_CORE);
         String holdOutFld = (objectType == ObjectHelper.OBJECT_ACCOUNt ? (hed != null ? hed.Account_Hold_Out__c : ObjectHelper.HOLD_OUT) : ObjectHelper.HOLD_OUT);
         String holdOutExpirationFld = (objectType == ObjectHelper.OBJECT_ACCOUNt ? (hed != null ? hed.Account_Hold_Out_Date__c : 'Hold_Out_Expiration__c') : 'Hold_Out_Expiration__c');
         String holdOutReasonFld = (objectType == ObjectHelper.OBJECT_ACCOUNt ? (hed != null ? hed.HoldOutReasonFld__c : 'Permanent_Hold_Out_Description__c') : 'Hold_Out_Reason__c');
         String ownerFld = (objectType == ObjectHelper.OBJECT_ACCOUNt ? (hed != null ? hed.Account_Owner__c : 'OwnerId') : 'OwnerId');
         Boolean holdOut = (Boolean)rec.get(holdOutFld);
         Date hoExpireDate = (Date)rec.get(holdOutExpirationFld);
         String hoReason = (String)rec.get(holdOutReasonFld);
         String info = '';
         // if there's an existing hold out, do we change owner? right now, no.
         Id curOwnerId = (Id)rec.get(ownerFld);
         if (!holdOut && curOwnerId != ouw.latestOpen.OwnerId) {
            rec.put(ownerFld,ouw.latestOpen.OwnerId);
            Integer holdoutDays = Integer.valueOf(ouw.latestOpen.Cadence__r.SetOwnerHoldout__c);
            Date startDate = (ouw.latestOpen.Start_Date__c != null ? ouw.latestOpen.Start_Date__c : Date.today());
            Date hoDate = startDate.addDays(holdoutDays);
            rec.put(holdOutFld,true);
            rec.put(holdOutExpirationFld,hoDate);
            rec.put(holdOutReasonFld,OWNER_HOLD_OUT_REASON);
            info = 'Set Holdout from Cadence expiration='+hoDate+' reason='+OWNER_HOLD_OUT_REASON;
         } else if (holdOut) {
            info = 'Holdout from Cadence not set. Current reason='+hoReason;
         } // if (!holdOut
         if (String.isNotBlank(info)) {
            recChanged = true;
            StringHelper.addToProcessNotes(rec,info);
         }
      } // if (ouw.latestOpen

      return recChanged;
   } // checkForFieldChanges
   
    // for testing purposes
    public static Boolean RUN_INLINE = false;
    
    public static void launchQueueable(CadenceQueueable cqable){
        System.debug('launchQueueable RUN_INLINE='+RUN_INLINE+' queueableLaunched='+queueableLaunched);
        if (!queueableLaunched) {
           queueableLaunched = true;
           if (RUN_INLINE || !Utilities.allowFuture()) {
              Map<Id, ObjectUpdateWrapper> parentObjectMap = cqable.setupWrappers();
              if (!parentObjectMap.isEmpty()) {
                 cqable.updateCarParentObjects(parentObjectMap,true);
              }
           } else {
              System.enqueueJob(cqable);
           }
        }
    } // launchQueueable
    
   public ErrorLog__c debugLog = ErrorLog.getLog(CLASSNAME);

   public void execute(QueueableContext context) {
      Integer nbrRecs = (carQueryList != null ? carQueryList.size() : -1);
      try {
         Map<Id, ObjectUpdateWrapper> parentObjectMap = setupWrappers(); 
         updateCarParentObjects(parentObjectMap, true);
         debugLog.NbrSuccess__c = nbrRecs;
      } catch (Exception e) {
         ErrorLog.addToDescription(debugLog, 'Exception occurred: '+e.getMessage()+'; '+e.getStackTraceString());
         debugLog.NbrFailure__c = nbrRecs;
      }
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      if (abc != null && abc.BatchSize__c != null && nbrRecs >= abc.BatchSize__c) {
         ErrorLog.saveErrorLog(debugLog);
      }
   } // execute
   
   public void checkLeads(Lead[] leads) {
      Map<Id, ObjectUpdateWrapper> parentObjectMap = new Map<Id, ObjectUpdateWrapper>();
      for (Lead ld : leads) {
         ObjectUpdateWrapper ouw = new ObjectUpdateWrapper(ld);
         parentObjectMap.put(ld.Id,ouw);
      }
      updateCarParentObjects(parentObjectMap, false);
   } // checkLeads
   
   public void checkAccts(Account[] accts) {
      Map<Id, ObjectUpdateWrapper> parentObjectMap = new Map<Id, ObjectUpdateWrapper>();
      for (Account acct : accts) {
         ObjectUpdateWrapper ouw = new ObjectUpdateWrapper(acct);
         parentObjectMap.put(acct.Id,ouw);
      }
      updateCarParentObjects(parentObjectMap, false);
   } // checkAccts
   
   public void checkRefAccts(Referral_Account__c[] accts) {
      Map<Id, ObjectUpdateWrapper> parentObjectMap = new Map<Id, ObjectUpdateWrapper>();
      for (Referral_Account__c acct : accts) {
         ObjectUpdateWrapper ouw = new ObjectUpdateWrapper(acct);
         parentObjectMap.put(acct.Id,ouw);
      }
      updateCarParentObjects(parentObjectMap, false);
   } // checkAccts
    
} // class CadenceQueueable