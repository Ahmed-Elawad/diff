/**********************************************************
  Created by: DemandGen, Gram Bischof 10/31/2018
  Last Modified: Gram Bischof 02/18/2018

  Description: 
  Class to create and update demand funnel records. It looks
  at the change in status and updates the demand funnel 
  records in accordance with the lower level records.
  
  When this was set up back in March the DFR was going off the opportunity status.  
  Because of multiple opps getting converted at the same time.  
  So if a webform came in it would create a DFR if one was not created.  
  If it turned in to 2 opps then the primary opp would connect to the created DFR and 
  the non primary would create its own DFR.  From there both DFR’s would be triggered from each opp status.  
  
  If lead, always triggered from Lead_Status__c change
  If Opportunity, always triggered from StageName change
  If Referral, always triggered from Selling_Opportunity__c change 
  If Contact, only triggered if no open opp.

Test Class: DG_DFR_ControllerTest

   History
   --------
   10/22/2019  Cindy Freeman         modified to update Partner Referral lookup on DFR
                                     map:  dfrReferral <Id, Referral>  key is Lead or Contact or Opty id
                                     map:  theRefMap <Id, Referral> key is Selling Opty id
   03/04/2020  Dan Carmen            Add some additional debugging
   03/10/2020  Dan Carmen            Remove ability for opportunities to create a new DFR. Only should be created from referrals.
   05/19/2020  Cindy Freeman         fix bug in getReferralMap method
   05/10/2020  Pujitha Madamanchi    fix DFR for Oasis 
   06/02/2020  Cindy Freeman         look for Lead conversion in checkReferral to create DFR then
   07/06/2020  Pujitha Madamanchi    Fix datatype issue for DFR
   01/13/2020  Dan Carmen            Change to use LeadLoaderConfig__c custom setting when selecting referrals from Lead/Contact
   09/24/2022  Pujitha Madamanchi    Remove DFR Object and populate fields on Referral.                           
   05/19/2023  Dan Carmen            Fix for NPE when processing opps.
   07/18/2023  Pujitha Madamanchi    Add logging for funnel stage.    

/**********************************************************/

public with sharing class DG_DFR_Controller implements TriggerInterface2 {
   public static String CLASS_NAME='DG_DFR_Controller';
   public static Boolean SKIP_TRIGGER=false;
   // for testing purposes
   public static Boolean SKIP_FUTURE=false;
   //public static Integer counter = 0;
   public static Boolean enteredLeadConversion = false;
 
   // for TriggerInterface2
  public void triggerCheckAllFirst(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
   SObject[] recs = TriggerMethods.checkRecs(CLASS_NAME, p_recs, oldMap, isBefore, isAfter, null, null);
   System.debug('DG_DFR_Controller.triggerCheckAllFirst obj='+TriggerMethods.objectTypeName+' p_recs='+(p_recs != null ? p_recs.size() : -1)+' recs='+(recs != null ? recs.size() : -1));
   if (recs.isEmpty()) {
       return;
   }
   if(isBefore){
      
   }
   if (isAfter) {
       String objectName = TriggerMethods.objectTypeName;
       if (TriggerMethods.objType == Contact.sObjectType )  { 
           checkContactsAfter((Contact[])recs, oldMap);
       } 
       else if (TriggerMethods.objType == Lead.sObjectType) {
           Map<Id, Lead> newMap = new Map<Id, Lead>((List<Lead>)recs);
           checkLeadsAfter((Lead[])recs,oldMap);
           postLeadConversion(newMap);
       } 
       else if (TriggerMethods.objType == Opportunity.sObjectType) {
           Map<Id, Opportunity> newMap = new Map<Id, Opportunity>((List<Opportunity>)recs); 
           checkOppsAfter((Opportunity[])recs,  oldMap);
       }
       else if (TriggerMethods.objType == Referral__c.sObjectType) {
         Map<Id, Referral__c> newMap = new Map<Id, Referral__c>((List<Referral__c>)recs);
         checkReferralsAfter(newMap, (Map<Id,Referral__c>)oldMap);
     } 
   } // if (isAfter
  } // triggerCheckAllFirst


  // for TriggerInterface2 
 public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
 // for TriggerInterface2
 public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}


 public static void checkContactsAfter(Contact[] ctcts,Map<Id,Sobject> oldMap) {
    Map<Id,Contact> toProcessMap = new Map<Id,Contact>();
    for (Contact ctct : ctcts) {
       Contact oldCtct = (Contact)(oldMap != null ? oldMap.get(ctct.Id) : null);
       if (String.isNotBlank(ctct.Contact_Stage__c)) {
          if ((oldCtct == null)
              || (ctct.Contact_Stage__c != oldCtct.Contact_Stage__c
                   && alwaysSetRef(ctct.Contact_Stage__c))
              || (getOrderStatus(ctct.Contact_Stage__c) > getOrderStatus(oldCtct.Contact_Stage__c))) {
             toProcessMap.put(ctct.Id,ctct);
          }
       }
    } // for
    System.debug('checkContactsAfter toProcessMap='+toProcessMap.size());
    if (!toProcessMap.isEmpty()) {
       handleCtctLead(toProcessMap, oldMap);
    }
 } // checkContactsAfter

 // this is due to a problem with being called from DialSource
 public static String PREVIOUS_STAGE = null;
 
 public static void checkLeadsAfter(Lead[] lds,Map<Id,Sobject> oldMap) {
    Map<Id,Lead> toProcessMap = new Map<Id,Lead>();
    for (Lead ld : lds) {
       Lead oldLd = (Lead)(oldMap != null ? oldMap.get(ld.Id) : null);
       String curStage = ld.Lead_Stage__c;
       String prevStage = (oldLd != null ? oldLd.Lead_Stage__c : null);
       System.debug('checkLeadsAfter 1 curStage='+curStage+' prevStage='+prevStage);
       if (String.isNotBlank(curStage) && lds.size() == 1) {
           if (PREVIOUS_STAGE == null) {
              PREVIOUS_STAGE = curStage;
           } else if (curStage == prevStage && curStage != PREVIOUS_STAGE) {
              prevStage = PREVIOUS_STAGE;
           }
       }
       System.debug('checkLeadsAfter 2 curStage='+curStage+' prevStage='+prevStage+' PREVIOUS_STAGE='+PREVIOUS_STAGE);
       if (String.isNotBlank(curStage)) {
          if ((oldLd == null)
              || (curStage != prevStage)) {
             toProcessMap.put(ld.Id,ld);
          }
       }
    } // for
    System.debug('checkLeadsAfter toProcessMap='+toProcessMap.size());
    if (!toProcessMap.isEmpty()) {
       handleCtctLead(toProcessMap, oldMap);
    }
 } // checkLeadsAfter

// opportunities only are triggered on updates. New opps should be linked to 
 // referrals so we're going to trigger off the Selling_Opportunity field
 public static void checkOppsAfter(Opportunity[] opps, Map<Id,SObject> oldMap) {
   Map<Id,Opportunity> toProcessMap = new Map<Id,Opportunity>();
   for (Opportunity opp : opps) {
      Opportunity oldOpp = (Opportunity)(oldMap != null ? oldMap.get(opp.Id) : null);
      if (oldOpp != null && opp.StageName != oldOpp.StageName) {
         toProcessMap.put(opp.Id, opp);
      }
   }
   System.debug('checkOppsAfter toProcessMap='+toProcessMap.size());
   if (!toProcessMap.isEmpty()) {
      handleOpps(toProcessMap);
   }

} // checkOppsAfter

public static void postLeadConversion(Map<Id,Lead> newMap){
   Set<Id> opptyIds = new Set<Id>();
   Boolean hasConvertedLeads = false;
   for (Lead ld: newMap.values()){
      hasConvertedLeads = (hasConvertedLeads || ld.IsConverted);
      if(ld.ConvertedOpportunityId != null) {
         opptyIds.add(ld.ConvertedOpportunityId);
      }
   } // for (Lead ld: newMap

   if (!hasConvertedLeads) {
      return;
   }

   Map<Id,Opportunity> newOpps = (opptyIds.isEmpty() ? new Map<Id,Opportunity>() 
                                    : new Map<Id,Opportunity>([Select id,stageName From Opportunity Where Id IN :opptyIds]));
     
   List<Referral__c> refs = [Select id, Funnel_Stage__c, SourceLead__c
                                    From Referral__c 
                                   Where SourceLead__c IN :newMap.keySet()];

   Referral__c[] refsToUpdate = new Referral__c[]{};
   for (Referral__c ref: refs) {
      Lead ld = newMap.get(ref.SourceLead__c);
      if (ld != null && ld.isConverted) {
         if (ld.ConvertedOpportunityId != null && newOpps.containskey(ld.ConvertedOpportunityId)) {
           ref.Funnel_Stage__c = newOpps.get(ld.ConvertedOpportunityId).stageName;
           StringHelper.addToProcessNotes(ref,'postLeadConversion: set funnel stage='+newOpps.get(ld.ConvertedOpportunityId).stageName);
           refsToUpdate.add(ref);
         }
      } // if (ld != null && ld.isConverted
   } // for (Referral__c ref
   DmlHelper.performDML(refsToUpdate, DmlHelper.DML_UPDATE, CLASS_NAME, 'postLeadConversion', 'update ref with Converted Lead Info', true);
} // postLeadConversion

 public static void handleCtctLead(Map<Id,Sobject> newMap,Map<Id,Sobject> oldMap) {
   String objectName = TriggerMethods.objectTypeName;
  
   Boolean isContact = (objectName == 'Contact');
   System.debug('handleCtctLead objectName='+objectName+' isContact='+isContact+' isUpdate='+Trigger.isUpdate);
   
   if (enteredLeadConversion && isContact) {
      return;
   }
   
   Id[] ctctAndLeadIds = new Id[]{};
   ctctAndLeadIds.addAll(newMap.keyset());
   Map<Id,Referral__c> referralMap = gefReferralMap(ctctAndLeadIds, true, false, false);
   // there shouldn't be any opportunities at this point, so we're going to skip checking for those.
   Map<Id,Referral__c> refUpdate = new Map<Id,Referral__c>();

   for (SObject rec : newMap.values()) {
       Referral__c ref = referralMap.get(rec.Id);
       System.debug('handleCtctLead 1 rec='+rec.Id+' ref='+(ref != null ? 'Found' : 'Not Found'));
         
       String SObjectType = rec.getSObjectType().getDescribe().getName();
       String statusField = (SObjectType == 'Lead' ? 'Lead_Stage__c' 
                                   : (SObjectType == 'Contact' ? 'Contact_Stage__c' : null));

       String status = (statusField != null ? checkStatus((String)rec.get(statusField)) : null);
       if (ref != null) {
           ref.Funnel_Stage__c = status;
           StringHelper.addToProcessNotes(ref,'handleCtctLead: set funnel stage='+status);
           if (isContact) {
               Contact ctct = (Contact)rec;
               setContactFlds(ref,ctct);
           } else {
               Lead ld = (Lead)rec;
               setLeadFlds(ref,ld);
           }
           if(ref.Selling_Opportunity__r!=null){
               setOppFlds(ref,ref.Selling_Opportunity__r);
           }
           System.debug('handleCtctLead updating ref');
            refUpdate.put(ref.id,ref);
       } 
   } // for (SObject rec : newMap.values
   if(!refUpdate.isEmpty()){
      saveRefs(refUpdate,false);
   }
   
   System.debug('updated ref:::'+refUpdate);
} // handleCtctLead

public static void handleOpps(Map<Id,Opportunity> oppMap) {
   System.debug('handleOpps oppMap='+oppMap.size());
   Id[] oppIds = new Id[]{};
   oppIds.addAll(oppMap.keySet());
    // retrieve all of the contacts for the opportunities (through the OpportunityContactRole)
    Map<Id,Contact> ctctMap = getContactByOppId(oppIds);
    // collect the contact ids to search for referrals
    Id[] queryIds = new Id[]{};
    for (Contact ctct : ctctMap.values()) {
       queryIds.add(ctct.Id);
    }
   // all opportunities should have an associated referral
   Map<Id,Referral__c> referralMap = gefReferralMap(oppIds, false, true, false);
   
   Map<Id,Referral__c> refUpdate = new Map<Id,Referral__c>();

   // at this point all Opportunities that get to this point should have a referral. 
   for (Opportunity opp : oppMap.values()) {
       // should we stop if this is null? There should always be a referral.
       Referral__c ref = referralMap.get(opp.Id);
       if (ref == null) {
          continue;
       }
       Contact ctct = ctctMap.get(opp.Id);
       String status = null;
       if (!opp.isClosed) {
           status = DG_LMF_Service.getMarketingStageFromOppStage(opp.StageName);
       } 
       System.debug('handleOpps status='+status);

       if (status == null) {
           System.debug('handleOpps opp.isClosed::'+opp.isClosed);         
           Decimal probability = ((opp.isClosed && !opp.isWon) ? 0 : opp.Probability);
           System.debug('handleOpps probability::'+probability+' opp.NSS_Source__c::'+opp.NSS_Source__c+ ' opp.Reason_Not_Sold__c:::'+opp.Reason_Not_Sold__c); 
           status = DG_LMF_Service.getMarketingStage(probability, (opp.NSS_Source__c != null ? new String[]{opp.NSS_Source__c} : new String[]{}),opp.Reason_Not_Sold__c);
       }
       System.debug('handleOpps opp='+opp.Name+' hasRef='+(ref != null)+' status='+status);

       ref.Funnel_Stage__c = status;
       StringHelper.addToProcessNotes(ref,'handleOpps: set funnel stage='+status);
       setContactFlds(ref,ctct);
       setOppFlds(ref,ref.Selling_Opportunity__r);

       System.debug('handleOpps updating ref');
       refUpdate.put(ref.id,ref);

   } // for (Opportunity opp : oppMap.values
   saveRefs(refUpdate,false);
} // handleOpps

public static void saveRefs(Map<Id,Referral__c> refUpdate, Boolean useMappedValues) {
    DmlHelper.performDML2(refUpdate.values(), DmlHelper.DML_UPDATE, CLASS_NAME, 'saveRefs', 'Update Refs', false);
   ErrorLog.checkSave();
} // saveRefs

public static void checkReferralsAfter(Map<Id,Referral__c> newMap, Map<Id,Referral__c> oldMap) {
   Set<Id> refIdSet = new Set<Id>();
    System.debug('**CMF ** enteredLeadConversion='+enteredLeadConversion);
   for (Referral__c ref : newMap.values()) {
      Referral__c oldRef = (oldMap != null ? oldMap.get(ref.Id) : null);
      if (ref.Selling_Opportunity__c != null && (oldRef == null || ref.Selling_Opportunity__c != oldRef.Selling_Opportunity__c)) {
         refIdSet.add(ref.Id);
      }
     
   } // for (Referral__c ref : newMap.values
    
   System.debug('**CMF ** checkReferralsAfter refIdSet='+refIdSet);
   if (!refIdSet.isEmpty()) {
      if (SKIP_FUTURE || System.isFuture() || System.isBatch() || System.isQueueable()) {
         processReferralsNow(refIdSet);
      } else {
         processReferralsFuture(refIdSet);
      }
   }
} // checkReferralsAfter

@future
public static void processReferralsFuture(Set<Id> refIdSet) {
  processReferralsNow(refIdSet);
} // processReferralsFuture

public static void processReferralsNow(Set<Id> refIdSet) {

   Id[] queryIds = new Id[]{};
   queryIds.addAll(refIdSet);
   gefReferralMap(queryIds, false, false, true);
    
   Referral__c[] refs = queriedRefs;
      Map<Id,Referral__c> refUpdate = new Map<Id,Referral__c>();

   System.debug('processReferralsNow refIdSet='+refIdSet.size()+' refs='+refs.size());
   
   Id[] oppIds = new Id[]{};
   for (Referral__c ref : refs) {
      queryIds.add(ref.SourceContact__c);
      if (ref.Selling_Opportunity__c != null) {
         oppIds.add(ref.Selling_Opportunity__c);
      }
   }
   Map<Id,Contact> ctctMap = getContactByOppId(oppIds);
   
   System.debug('processReferralsNow queryIds='+queryIds.size());
     
   try {
      for (Referral__c ref : refs) {
         System.debug('processReferralsNow 1 ref='+ref.Name);
         String nssSource = ref.Selling_Opportunity__r.NSS_Source__c;
         String status = null;
         if (!ref.Selling_Opportunity__r.isClosed) {
            status = DG_LMF_Service.getMarketingStageFromOppStage(ref.Selling_Opportunity__r.StageName);
         } 
         System.debug('processReferralsNow status='+status);
         if (status == null) {
            Decimal probability = (ref.Selling_Opportunity__r.isClosed ? 0 : ref.Selling_Opportunity__r.Probability);
            status = DG_LMF_Service.getMarketingStage(probability, (nssSource != null ? new String[]{nssSource} : new String[]{}),ref.Selling_Opportunity__r.Reason_Not_Sold__c);
         }
         System.debug('processReferralsNow sellingOpp='+ref.Selling_Opportunity__r);
         System.debug('processReferralsNow SourceContact='+ref.SourceContact__r);
         
         ref.Funnel_Stage__c = status;
         StringHelper.addToProcessNotes(ref,'processReferralsNow: set funnel stage='+status);

         setContactFlds(ref,ref.SourceContact__r);
         setOppFlds(ref,ref.Selling_Opportunity__r);
          
         refUpdate.put(ref.id,ref);
      } // for(Referral__c ref : referrals
      saveRefs(refUpdate,false);
      
   } catch(Exception e) {
      System.debug('processReferralsNow exception: ' + e.getMessage()+'; '+e.getStackTraceString());
      Referral__c ref = ((refs != null && !refs.isEmpty()) ? refs[0] : null);        
      Id recId = (ref != null ? ref.Id : null);
      ErrorLog.logError(CLASS_NAME, 'processReferralsNow', 'General Error', recId, e, ref, false);
   }
   ErrorLog.checkSave();
} // processReferralsNow   


/*public static void checkReferralsAfter(Referral__c[] refs, Map<Id,Referral__c> oldMap) {
   Map<Id,Referral__c> toProcessMap = new Map<Id,Referral__c>();
   Id[] oppIds = new Id[]{};
   Id[] conIds = new Id[]{};
   for (Referral__c ref : refs) {
      Referral__c oldRef = (Referral__c)(oldMap != null ? oldMap.get(ref.Id) : null);
      if (ref.Selling_Opportunity__c != null && (oldRef == null || ref.Selling_Opportunity__c != oldRef.Selling_Opportunity__c)) {
         System.debug('checkReferralsAfter NSS_Source__c='+ref.Selling_Opportunity__r.NSS_Source__c);
         toProcessMap.put(ref.Id, ref);
         oppIds.add(ref.Selling_Opportunity__c);
         conIds.add(ref.SourceContact__c);
      }
   }
   System.debug('checkReferralsAfter toProcessMap='+toProcessMap.size());
   if (!toProcessMap.isEmpty()) {
      handleRefs(toProcessMap, oppIds, conIds);
   }
}

public static void handleRefs(Map<Id,Referral__c> refMap, Id[] oppIds, Id[] conIds) {   
  
   Map<Id,Referral__c> refUpdate = new Map<Id,Referral__c>();
   System.debug('**CMF ** enteredLeadConversion='+enteredLeadConversion);

   Map<Id, Opportunity> oppMap = new Map<ID, Opportunity>([Select Id, NSS_Source__c, isClosed, StageName, Probability, Reason_Not_Sold__c, LeadSource, IsWon
                                                            from Opportunity where Id in:oppIds]);
   Map<Id, Contact> conMap = new Map<ID, Contact>([Select Id, Marketo_Lead_Rating__c, mkto2__Lead_Score__c, Recycle_Reason__c, LeadSource, Reject_Reason__c, AccountId 
                                                            from Contact where Id in:conIds]);
   System.debug('**Pujitha ** handleRefs oppMap='+oppMap);

   try {
      for (Referral__c ref : refMap.values()) {
         Contact ctct = conMap.get(ref.SourceContact__c);
         Opportunity opp = oppMap.get(ref.Selling_Opportunity__c);
         if(ref.Selling_Opportunity__c!=null && opp!=null && opp.NSS_Source__c != null){
            String nssSource = opp.NSS_Source__c;
            String status = null;            
            if (!opp.isClosed) {
               status = DG_LMF_Service.getMarketingStageFromOppStage(opp.StageName);
            } 
            System.debug('handleRefs status='+status);
            if (status == null) {
               Decimal probability = (opp.isClosed ? 0 : opp.Probability);
               status = DG_LMF_Service.getMarketingStage(probability, (nssSource != null ? new String[]{nssSource} : new String[]{}),opp.Reason_Not_Sold__c);
            }
            ref.Funnel_Stage__c = status;
             System.debug('DG_DFR_Controller:: handleRefs:::  ref.Funnel_Stage__c'+ ref.Funnel_Stage__c);
            System.debug('handleRefs sellingOpp='+opp);
            setContactFlds(ref,ctct);
            setOppFlds(ref,opp);
            System.debug('handleRefs update refs');
         }
         
      } // for(Referral__c ref : processRefs
   } catch(Exception e) {
   System.debug('handleRefs exception: ' + e.getMessage()+'; '+e.getStackTraceString());
   Referral__c ref = ((refMap.values() != null && !refMap.values().isEmpty()) ? refMap.values()[0] : null);        
   Id recId = (ref != null ? ref.Id : null);
   ErrorLog.logError(CLASS_NAME, 'handleRefs', 'General Error', recId, e, ref, false);
   }  
   ErrorLog.checkSave();     
} // checkReferralsBefore */

public static String checkStatus(String checkStatus) {
   String retStatus = checkStatus;
   if (String.isNotBlank(retStatus)) {
      retStatus = (retStatus == 'Auto MQL' ? 'MQL' : retStatus);
   } // if (String.isNotBlank(retStatus
   return retStatus;
} // checkStatus

public static Map<String,Decimal> stageOrderMap = null; 
 
public static Map<String,MarketingStage__mdt> stageMap = null;

public static void checkStageMap() {
   if (stageMap == null) {
      stageMap = new Map<String,MarketingStage__mdt>();
      MarketingStage__mdt[] stages = [Select Id, MasterLabel, DFRFunnelOrder__c, DFRAlwaysSet__c
                                        From MarketingStage__mdt];
      for (MarketingStage__mdt stage : stages) {
         stageMap.put(stage.MasterLabel, stage);
      }
   } // if (stageMap == null
} // checkStageMap

public static Decimal getOrderStatus(String status) {
   checkStageMap();
   MarketingStage__mdt stage = (String.isNotBlank(status) ? stageMap.get(status) : null);
   Decimal returnOrder = (stage != null ? stage.DFRFunnelOrder__c : -1);
   return returnOrder;
} // getOrderStatus

public static Boolean alwaysSetRef(String status) {
   checkStageMap();
   MarketingStage__mdt stage = (String.isNotBlank(status) ? stageMap.get(status) : null);
   Boolean alwaysSet = (stage != null ? stage.DFRAlwaysSet__c : false);
   return alwaysSet;
} // alwaysSetRef
 
public static Set<String> allRefFldSet = null;
 
public static Set<String> getAllRefFields() {
   if (allRefFldSet == null) {
       allRefFldSet = new Set<String>();
      ObjectHelper.getSOQLQuery('Referral__c', null, true, true, false, false);
      String[] allFlds = ObjectHelper.latestSoqlWrapper.flds;
      for (String fld : allFlds) {
         // set to all lower case so we don't worry about case.
         allRefFldSet.add(fld.toLowerCase());
      }
   } // if (allRefFldSet == null
   return allRefFldSet;
} // getAllRefFields

public static Map<String,DG_DFR_Field_Mapping__mdt[]> fldsByObjectMap = null;
  
public static DG_DFR_Field_Mapping__mdt[] getFieldsForObject(String objName) {
   if (fldsByObjectMap == null) {
      fldsByObjectMap = new Map<String,DG_DFR_Field_Mapping__mdt[]>();
      
      DG_DFR_Field_Mapping__mdt[] fldsMdt = [Select Id, DFR_field__c, Original_field__c, Object__c, Stage__c
                                              From DG_DFR_Field_Mapping__mdt
                                             Where DFRVersion__c='Version 2'];
      for (DG_DFR_Field_Mapping__mdt fldMdt : fldsMdt) {
         DG_DFR_Field_Mapping__mdt[] fldsByObj = (fldsByObjectMap.containsKey(fldMdt.Object__c) ? fldsByObjectMap.get(fldMdt.Object__c) : new DG_DFR_Field_Mapping__mdt[]{});
         fldsByObj.add(fldMdt);
         fldsByObjectMap.put(fldMdt.Object__c,fldsByObj);
      }
   } // if (fldsByObjectMap == null
   return fldsByObjectMap.get(objName);
} // getFieldsForObject

public static Map<Id,Contact> getContactByOppId(Id[] oppIds) {
   Map<Id,Contact> ctctMap = new Map<Id,Contact>();
   if (!oppIds.isEmpty()) {
      String query = 'Select Id, OpportunityId, ContactId';
      query += getQueryFields('Contact', 'Contact.');
      query += ' From OpportunityContactRole Where IsPrimary = true and OpportunityId in :oppIds';
      System.debug('getContactByOppId query='+query);
      OpportunityContactRole[] ocrs = Database.query(String.escapeSingleQuotes(query));
      System.debug('getContactByOppId oppIds='+oppIds.size()+' ocrs='+ocrs.size());
      for (OpportunityContactRole ocr : ocrs) {
         if (!ctctMap.containsKey(ocr.OpportunityId)) {
            ctctMap.put(ocr.OpportunityId,ocr.Contact);
         }
      }
   } // if (!oppIds.isEmpty()
   System.debug('getContactByOppId oppIds='+oppIds.size()+' ctctMap='+ctctMap.size());
   return ctctMap;
} // getContactByOppId

public static String getQueryFields(String objectName, String queryPrefix) {
   String query='';
   DG_DFR_Field_Mapping__mdt[] fldsMdt = getFieldsForObject(objectName);
   // keep track of fields used so we only add them to the query once
   Set<String> fldsUsedSet = new Set<String>();
   for (DG_DFR_Field_Mapping__mdt fld : fldsMdt) {
      if (!fldsUsedSet.contains(fld.Original_field__c)) {
         query += ' ,'+(String.isNotBlank(queryPrefix) ? queryPrefix : '')+fld.Original_field__c;
         fldsUsedSet.add(fld.Original_field__c);
      }
   }
   return query;
 } // getQueryFields

public static void setContactFlds(Referral__c ref, Contact ctct) {
   if (ctct != null) {
      setFldsFromObject(ref,'Contact',ctct,false);
   } // if (camp != null
} // setCampaignFlds

public static void setLeadFlds(Referral__c ref, Lead ld) {
   if (ld != null) {
      setFldsFromObject(ref,'Lead',ld,false);
   } // if (camp != null
} // setCampaignFlds

public static void setOppFlds(Referral__c ref, Opportunity opp) {
   if (opp != null) {
      Boolean isLost = (opp.IsClosed && !opp.IsWon);
      setFldsFromObject(ref,'Opportunity',opp,isLost);
   }
} // setOppFlds
public static void setFldsFromObject(Referral__c ref, String objectName, SObject rec, Boolean oppIsLost) {
   Set<String> allFldSet = getAllRefFields();
   DG_DFR_Field_Mapping__mdt[] fldsMdt = getFieldsForObject(objectName);
   String curStatus = ref.Funnel_Stage__c;
   String recNotes = 'setFldsFromObject='+objectName+' curStatus='+curStatus+' oppIsLost='+oppIsLost;
   for (DG_DFR_Field_Mapping__mdt fldMdt : fldsMdt) {
      Boolean hasValue = (rec.get(fldMdt.Original_field__c) != null);
      System.debug('setFldsFromObject hasValue='+hasValue+' DFR_field__c='+fldMdt.DFR_field__c);
      if (hasValue && String.isNotBlank(fldMdt.DFR_field__c)) {
         if (fldMdt.DFR_field__c.startsWith('_')) {
            // the field names start with the status
            String fldName = (curStatus+fldMdt.DFR_field__c).toLowerCase();
            Boolean fldExists = allFldSet.contains(fldName);
            System.debug('setFldsFromObject objectName='+objectName+' fldName='+fldName+' fldExists='+fldExists);
            if(fldExists) {
               ref.put(fldName,rec.get(fldMdt.Original_field__c));                 
               recNotes += '; set1 '+fldName+'='+String.valueOf(rec.get(fldMdt.Original_field__c)+'('+String.valueOf(rec.get(fldMdt.Original_field__c))+')');
            }
         } else if ((String.isBlank(fldMdt.Stage__c) || (String.isNotBlank(fldMdt.Stage__c) && fldMdt.Stage__c == curStatus)) 
                         && String.isNotBlank(fldMdt.DFR_field__c) && allFldSet.contains(fldMdt.DFR_field__c.toLowerCase())) {
            System.debug('setFldsFromObject setFieldBasedOnStage='+fldMdt.Stage__c+' fld='+fldMdt.DFR_field__c);
            String value=String.valueOf(rec.get(fldMdt.Original_field__c));
            if (oppIsLost && String.isBlank(value) && objectName == ObjectHelper.OBJECT_OPPTY && fldMdt.DFR_field__c == 'EOL_Reason__c') {
               // if we're in a reject or recycle on the opp and there isn't a lost reason on the opp then we'll just use the opp status.
               value = String.valueOf(rec.get('StageName'));
            }
            //String param=' dynamic ';
            //if (fldMdt.DFR_field__c == 'EOL_Reason__c') {
            //   dfr.EOL_Reason__c = value;
            //   param=' static ';
            //} else {
               ref.put(fldMdt.DFR_field__c,value);
            //}
            recNotes += ', set2 '+fldMdt.DFR_field__c+' from '+fldMdt.Original_field__c+' value='+value;
         }
      }
   } // for (DG_DFR_Field_Mapping__mdt fldMdt
   StringHelper.addToProcessNotes(ref,recNotes);
} // setFldsFromObject

public static Referral__c[] queriedRefs = new Referral__c[]{};

public static Map<Id,Referral__c> gefReferralMap(Id[] recIds, Boolean byLeadCtctId, Boolean byOppId, Boolean byRefId) {
   System.debug('gefReferralMap recIds='+recIds.size()+' byLeadCtctId='+byLeadCtctId+' byOppId='+byOppId+' byRefId='+byRefId);
   Map<Id,Referral__c> refMap = new Map<Id,Referral__c>();
   queriedRefs.clear();

   if (!recIds.isEmpty()) {
      // get all of the owned by values available
      Set<String> ownedByValueSet = new Set<String>();
      //Set<String> nssSourceSet = new Set<String>();
      for (LeadLoaderConfig__c llc : LeadLoaderConfig__c.getAll().values()) {
         if (llc.IsActive__c && llc.StoreOrginalData__c) {
            ownedByValueSet.add(llc.Name);
            //if (String.isNotBlank(llc.NSSSource__c)) {
            //   System.debug('gefReferralMap NSSSource__c='+llc.NSSSource__c);
            //   nssSourceSet.add(llc.NSSSource__c);
            //}
         }
      } // for
      System.debug('gefReferralMap ownedByValueSet='+ownedByValueSet.size());
      String inboundValue = 'Inbound%';
      DFRSettings__c dfrSetting = DFRSettings__c.getInstance('DFR Settings');
      Date queryStartDate = dfrSetting.DFR_Start_Date__c;
      String query = 'Select Id,Name,Account__c,SourceLead__c,SourceContact__c,PartnerReferral__c,Selling_Opportunity__c,Primary__c,Funnel_Stage__c,ProcessNotes__c ';
      query += getQueryFields('Contact', 'SourceContact__r.');
      query += getQueryFields('Lead', 'SourceLead__r.');
      query += getQueryFields('Opportunity', 'Selling_Opportunity__r.');
      query += ' From Referral__c ';
      query += ' Where DateLeadSubmitted__c >= :queryStartDate ';
      System.debug('gefReferralMap recIds='+recIds+' byRefId='+byRefId);
       if (byLeadCtctId) {
         query += ' and ((SourceLead__c IN :recIds '+
                                   ' and SourceLead__r.OwnedByPrev__c in :ownedByValueSet) '+
                                   ' or (SourceContact__c IN :recIds '+
                                    '  and SourceContact__r.OwnedByPrev__c in :ownedByValueSet)) ';
      }
      if (byOppId) {
         query += ' and (Selling_Opportunity__c IN :recIds '+
                  'and Selling_Opportunity__r.NSS_Source__c like :inboundValue ) ';
      }
      if (byRefId) {
         query += ' and (Id in :recIds and Selling_Opportunity__r.NSS_Source__c like :inboundValue) ';
      }

      query += ' Order By CreatedDate desc ';
      
      System.debug('gefReferralMap query='+query);
      queriedRefs = Database.query(String.escapeSingleQuotes(query));
      System.debug('gefReferralMap queriedRefs='+queriedRefs.size());
      for (Referral__c ref : queriedRefs) {
         refMap.put(ref.Id, ref);
         // should not be an opportunity if retrieving for lead or contact
         if (ref.SourceLead__c != null && ref.Selling_Opportunity__c == null && !refMap.containsKey(ref.SourceLead__c)) {
            refMap.put(ref.SourceLead__c,ref);
         }
         if (ref.SourceContact__c != null && ref.Selling_Opportunity__c == null && !refMap.containsKey(ref.SourceContact__c)) {        // CMF
            refMap.put(ref.SourceContact__c,ref);
         }
         if (ref.Selling_Opportunity__c != null) {
            refMap.put(ref.Selling_Opportunity__c,ref);
         }
      }
   } // if (!recIds.isEmpty
   System.debug('gefReferralMap recIds='+recIds.size()+' refMap='+refMap.size());
   return refMap;
} // gefReferralMap

}