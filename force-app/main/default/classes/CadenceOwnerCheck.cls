/**********************************************************
   If the owner on an account or lead changes, look for any open car records and handle them based on the rules of the cadence.

   Owner Change Actions
   Do Nothing
   End Ownership on CAR Record
   Transfer CAR to New Owner
   

   History
   --------
   01/22/2020 Dan Carmen        Created
   04/30/2020 Dan Carmen        Fix for tests failing
   01/21/2021 Brandon Vidro     Set Cadence_Owner__c=newOwnerId in handleTransferOwner
   08/12/2021 Dan Carmen        Add extra logging
   11/17/2021 Dan Carmen        Fix save error record in list more than once
   02/10/2023 Dan Carmen        Do not update touchpoint if new owner is a queue

                              
/**********************************************************/
public with sharing class CadenceOwnerCheck implements TriggerInterfaceC {
   
   public static final String CLASS_NAME='CadenceOwnerCheck';
   
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs(CLASS_NAME, p_recs, oldMap, isBefore, isAfter, null, null);
      System.debug('CadenceOwnerCheck.triggerCheckAllFirst obj='+TriggerMethods.objectTypeName+' p_recs='+(p_recs != null ? p_recs.size() : -1)+' recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
      if (recs.isEmpty()) {
         return;
      }
      
      if (isAfter) {
         String objectName = TriggerMethods.objectTypeName;
         checkRecs(recs, oldMap);
      } // if (isAfter   

   } // handleTrigger
   
   public class ObjectWrap {
      public ObjectWrap(SObject p_rec, SObject oldRec) {
         rec = p_rec;
         SObjectType objType = p_rec.getSObjectType();
         if (objType == Account.sObjectType )  {
            setAccount((Account)rec, (Account)oldRec);
         } else if (objType == Lead.sObjectType )  {
            setLead((Lead)rec,(Lead)oldRec);
         } else if (objType == Referral_Account__c.sObjectType) {
            setRefAcct((Referral_Account__c)rec, (Referral_Account__c)oldRec);
         }
 
      } // ObjectWrap
      public void setLead(Lead ld, Lead oldLd) {
         if (oldLd != null && ld.OwnerId != oldLd.OwnerId) {
            fldChangedMap.put('OwnerId',oldLd.OwnerId);
            prevFieldChangedMap.put(oldLd.OwnerId,'OwnerId');
            queryOwnerIds.add(oldLd.OwnerId);
         }
      } // ObjectWrap

      public void setRefAcct(Referral_Account__c refAcct, Referral_Account__c oldRefAcct) {
         if (oldRefAcct != null && refAcct.OwnerId != oldRefAcct.OwnerId) {
            fldChangedMap.put('OwnerId',oldRefAcct.OwnerId);
            prevFieldChangedMap.put(oldRefAcct.OwnerId,'OwnerId');
            queryOwnerIds.add(oldRefAcct.OwnerId);
         }
      } // ObjectWrap

      public void setAccount(Account acct, Account oldAcct) {
         if (oldAcct != null) {
            for (HoldOut_ExpirationDates__c hed : HoldOut_ExpirationDates__c.getAll().values()) {
               if (String.isNotBlank(hed.Account_Owner__c) && !fldChangedMap.containsKey(hed.Account_Owner__c)
                     && acct.get(hed.Account_Owner__c) != null && oldAcct.get(hed.Account_Owner__c) != null
                     && acct.get(hed.Account_Owner__c) != oldAcct.get(hed.Account_Owner__c)) {
                  fldChangedMap.put(hed.Account_Owner__c,(Id)oldAcct.get(hed.Account_Owner__c));
                  prevFieldChangedMap.put((Id)oldAcct.get(hed.Account_Owner__c),hed.Account_Owner__c);
                  queryOwnerIds.add((Id)oldAcct.get(hed.Account_Owner__c));
                  System.debug('ObjectWrap change found on account for '+hed.Account_Owner__c);
               }
            }
         } // if (oldAcct != null
      } // ObjectWrap
      
      public Boolean ownerChanged{ get {return !fldChangedMap.isEmpty(); }}
      public SObject rec;
      public Map<String,Id> fldChangedMap = new Map<String,Id>();
      public Map<Id,String> prevFieldChangedMap = new Map<Id,String>();
      public Id[] queryOwnerIds = new Id[]{};
      public Id getId() {
         //return (acct != null ? acct.Id : (ld != null ? ld.Id : (refAcct != null ? refAcct.Id : null)));
         return (rec != null ? rec.Id : null);
      }
   } // class ObjectWrap

   public static void checkRecs(SObject[] recs, Map<Id,SObject> oldMap) {
      Map<Id,ObjectWrap> ownerChangeMap = new Map<Id,ObjectWrap>();
      for (SObject rec : recs) {
         SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         if (oldRec != null) {
            ObjectWrap ow = new ObjectWrap(rec,oldRec);
            if (ow.ownerChanged) {
               ownerChangeMap.put(rec.Id,ow);
            }
            
         } // if (oldAcct != null
      } // for (Account acct : accts
      System.debug('checkRecs recs='+recs.size()+' ownerChangeMap='+ownerChangeMap.size());
      if (!ownerChangeMap.isEmpty()) {
         checkForCadence(ownerChangeMap);
      }
   } // checkRecs

   public static String ACTION_NOTHING='Do Nothing';
   public static String ACTION_END='End Ownership of CAR Record';
   public static String ACTION_TXFER='Transfer CAR to New Owner';
   
   public static void checkForCadence(Map<Id,ObjectWrap> wrapMap) {
      ErrorLog__c log = ErrorLog.getLog(CLASS_NAME);
      log.BatchSize__c = wrapMap.size();
      log.ObjectId__c = wrapMap.values()[0].getId();
      Map<Id,Cadence_Assignment_Record__c> updateCarMap = new Map<Id,Cadence_Assignment_Record__c>();
      Map<Id,Cadence_Touchpoint__c> updateTpMap = new Map<Id,Cadence_Touchpoint__c>();
      Id[] queryOwnerIds = new Id[]{};
      for (ObjectWrap wrap : wrapMap.values()) {
         if (!wrap.prevFieldChangedMap.isEmpty()) {
            queryOwnerIds.addAll(wrap.prevFieldChangedMap.keySet());
         }
      }
      Id[] queryIds = new Id[]{};
      queryIds.addAll(wrapMap.keySet());
      Cadence_Touchpoint__c[] touchpoints = WorkQueueController.getAllOpenTouchpoints(queryIds, queryOwnerIds, new Id[]{});
      System.debug('checkForCadence queryIds='+queryIds.size()+' queryOwnerIds='+queryOwnerIds.size()+' touchpoints='+touchpoints.size());
      ErrorLog.addToDescription(log, 'queryIds='+queryIds.size()+' queryOwnerIds='+queryOwnerIds.size()+' touchpoints='+touchpoints.size());
      log.NbrSuccess__c = touchpoints.size();
      for (Cadence_Touchpoint__c tp : touchpoints) {
         System.debug('checkForCadence tp='+tp.Name+' owner change action='+(tp.Cadence__c != null ? tp.Cadence__r.OwnerChangeAction__c : 'Not found'));
         ErrorLog.addToDescription(log, 'tp='+tp.Name+' id='+tp.Id+' owner change action='+(tp.Cadence__c != null ? tp.Cadence__r.OwnerChangeAction__c : 'Not found'));
         if (tp.Cadence__c != null && String.isNotBlank(tp.Cadence__r.OwnerChangeAction__c) && tp.Cadence__r.OwnerChangeAction__c != ACTION_NOTHING) {
            Id key = (tp.CarRecord__r.AccountId__c != null ? tp.CarRecord__r.AccountId__c 
                        : (tp.CarRecord__r.LeadId__c != null ? tp.CarRecord__r.LeadId__c
                           : (tp.CarRecord__r.ReferralAccount__c != null ? tp.CarRecord__r.ReferralAccount__c : null)));
            ObjectWrap wrap = (key != null ?  wrapMap.get(key) : null);
            //ObjectWrap wrap = (tp.CarRecord__r.AccountId__c != null ? wrapMap.get(tp.CarRecord__r.AccountId__c)
            //                     : (tp.CarRecord__r.LeadId__c != null ? wrapMap.get(tp.CarRecord__r.LeadId__c) 
            //                        : (tp.CarRecord__r.ReferralAccount__c != null ? wrapMap.get(tp.CarRecord__r.ReferralAccount__c) : null));
            System.debug('checkForCadence has wrap='+(wrap != null));
            ErrorLog.addToDescription(log, 'has wrap='+(wrap != null));
            if (wrap != null) {
               // does the owner match
               Boolean ownerChanged = wrap.prevFieldChangedMap.containsKey(tp.OwnerId);
               ErrorLog.addToDescription(log, 'ownerChanged='+ownerChanged);
               if (ownerChanged) {
                  if (wrap != null && tp.Cadence__r.OwnerChangeAction__c == ACTION_END) {
                     handleEndOwnership(wrap, tp, updateCarMap, updateTpMap, log);
                  } else if (wrap != null && tp.Cadence__r.OwnerChangeAction__c == ACTION_TXFER) {
                     handleTransferOwner(wrap, tp, updateCarMap, updateTpMap, log);
                  }
               } // if (wrap.prevFieldChangedMap.containsKey
            } // if (wrap != null
         } // if (tp.Cadence__c != null
      } // for (Cadence_Touchpoint__c tp
      // we just want to save the data. We don't want the triggers to do anything else;
      TriggerMethods.SKIP_TRIGGERS=true;
      CadenceHelper.SKIP_TRIGGERS=true;
      ErrorLog.addToDescription(log, 'updateCars='+updateCarMap.size()+' updateTps='+updateTpMap.size());
      log.MaxRetries__c = updateCarMap.size();
      log.NbrRetries__c = updateTpMap.size();
      DmlHelper.performDML2(updateCarMap.values(), DmlHelper.DML_UPDATE, 'CadenceOwnerCheck', 'checkForCadence', 'Update CAR records', false);
      DmlHelper.performDML2(updateTpMap.values(), DmlHelper.DML_UPDATE, 'CadenceOwnerCheck', 'checkForCadence', 'Update TP records', false);
      ErrorLog.checkSave();
      ErrorLog.saveLog(log);
      TriggerMethods.SKIP_TRIGGERS=false;
   } // checkForCadence
   
   
   public static void handleEndOwnership(ObjectWrap wrap, Cadence_Touchpoint__c tp
                                           ,Map<Id,Cadence_Assignment_Record__c> updateCarMap, Map<Id,Cadence_Touchpoint__c> updateTpMap, ErrorLog__c log) {
      // end the touchpoint and car because of ownership change.
      String procNotes = 'Ending CAR and Touchpoint due to Source record Owner changing';
      //tp.Close_Date__c = Date.today();
      //tp.Status__c = 'Closed';
      Cadence_Touchpoint__c updateTp = new Cadence_Touchpoint__c(Id=tp.Id, Close_Date__c=Date.today(), Status__c='Closed',LastUpdateMethod__c='CadenceOwnerCheck.handleEndOwnership');
      Cadence_Assignment_Record__c updateCar = new Cadence_Assignment_Record__c(Id=tp.CarRecord__r.Id, Activity_Log__c=tp.CarRecord__r.Activity_Log__c);
      updateCar.Closed__c = true; 
      updateCar.Close_Date__c = Date.today(); 
      updateCar.CloseReason__c = 'Closed - Owner Changed'; 
      updateCar.Status__c = 'Closed'; 
      StringHelper.addToProcessNotes(updateCar, Cadence_Assignment_Record__c.Activity_Log__c.getDescribe(), procNotes);
      ErrorLog.addToDescription(log,procNotes);
      updateTpMap.put(updateTp.Id,updateTp);
      updateCarMap.put(updateCar.Id,updateCar);
      
   } // handleEndOwnership
   
   public static void handleTransferOwner(ObjectWrap wrap, Cadence_Touchpoint__c tp
                                           ,Map<Id,Cadence_Assignment_Record__c> updateCarMap, Map<Id,Cadence_Touchpoint__c> updateTpMap, ErrorLog__c log) {
      // set the new owner to be the owner of the touchpoint/car
      String ownerField = wrap.prevFieldChangedMap.get(tp.OwnerId);
      Id newOwnerId = null;
      if (String.isNotBlank(ownerField)) {
         newOwnerId = (wrap.rec != null ? (Id)wrap.rec.get(ownerField) : null);
         //newOwnerId = (wrap.acct != null ? (Id)wrap.acct.get(ownerField) : (wrap.ld != null ? (Id)wrap.ld.get(ownerField) : null));
      }
      System.debug('handleTransferOwner ownerField='+ownerField+' newOwnerId='+newOwnerId);
      Boolean isUser = (newOwnerId != null && newOwnerId.getSobjectType() == User.sObjectType);
      ErrorLog.addToDescription(log,'handleTransferOwner ownerField='+ownerField+' cur tp owner='+tp.OwnerId+' newOwnerId='+newOwnerId+' isUser='+isUser);
      if (newOwnerId != null && isUser) {
         String procNotes = 'Updated ownerId from '+tp.OwnerId+' to '+newOwnerId;
         Cadence_Touchpoint__c updateTp = new Cadence_Touchpoint__c(Id=tp.Id, OwnerId=newOwnerId);
         Cadence_Assignment_Record__c updateCar = new Cadence_Assignment_Record__c(Id=tp.CarRecord__r.Id, OwnerId=newOwnerId, Activity_Log__c=tp.CarRecord__r.Activity_Log__c, Cadence_Owner__c=newOwnerId);
         StringHelper.addToProcessNotes(updateCar, Cadence_Assignment_Record__c.Activity_Log__c.getDescribe(), procNotes);
         updateTpMap.put(updateTp.Id,updateTp);
         updateCarMap.put(updateCar.Id,updateCar);
      }
   } // handleTransferOwner
    
} // class CadenceOwnerCheck