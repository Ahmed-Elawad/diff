/* Methods for the Opportunity object.
   
  History
  -------
  02/21/2014 Dan Carmen     Created
  09/18/2014 Dan Carmen     Added logic to set the NSR (contact) field
  03/09/2016 Dan Carmen     Add ability to link to the Commission Month object
  05/25/2016 Dan Carmen     Commission month functionality.
  
 */
public with sharing class NSSAuditHelper {

   // add a do not calculate checkbox
   // add a credit date field
   public static NSSAudit__c[] checkProduct = new NSSAudit__c[]{};
   // if the user (NSR Name) changes evaluate the contact 
   public static NSSAudit__c[] v_checkForContact = new NSSAudit__c[]{};
   // the audit records that came from an Opportunity
   public static NSSAudit__c[] fromOpps = new NSSAudit__c[]{};
   // if contact field is populated and user field is not
   public static NSSAudit__c[] checkForUser = new NSSAudit__c[]{};
   // search for the commission month
   public static Map<String,NSSAudit__c[]> nssCommMonthMap = new Map<String,NSSAudit__c[]>();
   public static Date commLowDate = null;
   public static Date commHighDate = null;
   
   public static void checkTriggerBeforeActions(NSSAudit__c nssAudit, NSSAudit__c oldAudit) {

      if (String.isNotBlank(nssAudit.Product__c) && (oldAudit == null
                                                     || (oldAudit != null && nssAudit.Product__c != oldAudit.Product__c))) {
         checkProduct.add(nssAudit);
      } // if (String.isNotBlank
      
      if (nssAudit.NSR_Name__c != null && (Trigger.isInsert
                                            || (Trigger.isUpdate && nssAudit.NSR_Name__c != oldAudit.NSR_Name__c))) {
         v_checkForContact.add(nssAudit);                                 
      } // if (nssAudit.NSR_Name__c != null
      
      if (Trigger.isInsert && nssAudit.Source__c == ObjectHelper.OBJECT_OPPTY) {
         fromOpps.add(nssAudit);
      }
      
      if (nssAudit.NSR_Name__c == null && nssAudit.NSR__c != null) {
         checkForUser.add(nssAudit);
      }
      
      checkCommissionMonth(nssAudit, oldAudit);
   } // checkTriggerBeforeActions
   
   public static void checkCommissionMonth(NSSAudit__c nssAudit, NSSAudit__c oldAudit) {
      Date checkDate = nssAudit.CreditDate__c;
      Date oldCheckDate = (oldAudit != null ? oldAudit.CreditDate__c : null);

      //if (nssAudit.CreditDate__c != null && (oldAudit == null || (oldAudit != null && nssAudit.CreditDate__c != oldAudit.CreditDate__c))) {
      if (checkDate != null && (oldCheckDate == null || checkDate != oldCheckDate || nssAudit.CommissionMonth__c == null )) {
         String dateStr = String.valueOf(checkDate);
         NSSAudit__c[] auditList = nssCommMonthMap.get(dateStr);
         if (auditList == null) {
            auditList = new NSSAudit__c[]{};
            nssCommMonthMap.put(dateStr,auditList);
         }
         auditList.add(nssAudit);
         // capture the low and high dates of the nss audit record
         if (commLowDate == null || checkDate < commLowDate) {
            commLowDate = checkDate;
         }
         if (commHighDate == null || checkDate > commHighDate) {
            commHighDate = checkDate;
         }
      } // if (nssAudit.CreditDate__c != null
   } // checkCommissionMonth
   
   public static void processTriggerBefore() {

      if (!checkProduct.isEmpty()) {
         handleProduct(checkProduct);
      }
   
      if (!v_checkForContact.isEmpty()) {
         handleNSRContacts(v_checkForContact);
      }
   
      if (!checkForUser.isEmpty()) {
         handleNSRUsers(checkForUser);
      }
      if (!fromOpps.isEmpty()) {
         handleFromOpportunity(fromOpps);
      }
      
      if (!nssCommMonthMap.isEmpty()) {
         handleCommissionMonths();
      }
   } // processTriggerBefore
   
   // do we log an error if  the commission month isn't open (basically don't allow them to save)
   public static Boolean LOG_COMM_MONTH_ERROR=Label.NSSLogCommMonthError == 'Y';
   // the status to check on the commission month to see if it's open.
   public static String OPEN_STATUS=Label.NSSCommOpenStatus;
   
   public static Boolean handleCommissionMonths() {
      Boolean allOkay = true;
      CommissionMonth__c[] commMonths = [Select Id, StartDate__c, EndDate__c, NSSStatus__c 
                                           from CommissionMonth__c
                                          Where StartDate__c <= :commHighDate
                                            and EndDate__c >= :commLowDate];
      for (NSSAudit__c[] auditList : nssCommMonthMap.values()) {
         // use the first record for the date to check - all in a list will be the same
         CommissionMonth__c commMonth = findCommissionMonth(auditList[0].CreditDate__c, commMonths);
         if (commMonth != null) {
            for (NSSAudit__c nssAudit : auditList) {
               if (LOG_COMM_MONTH_ERROR && commMonth.NSSStatus__c != OPEN_STATUS) {
                  // what type of error do we log?
                  nssAudit.CreditDate__c.addError('The Commission Month for this Date is not open!');
                  allOkay = false;
               } else {
                  nssAudit.CommissionMonth__c = commMonth.Id;
               }
            } // for (NSSAudit__c nssAudit : auditList
         } // if (commMonth != null
      } // for (NSSAudit__c[] auditList
      return allOkay;
   } // handleCommissionMonths
   
   public static CommissionMonth__c findCommissionMonth(Date checkDate, CommissionMonth__c[] commMonths) {
      CommissionMonth__c foundMonth = null;
      if (commMonths != null) {
         for (CommissionMonth__c commMonth : commMonths) {
            if (checkDate >= commMonth.StartDate__c && checkDate <= commMonth.EndDate__c) {
               foundMonth = commMonth;
               break;
            }
         } // for (CommissionMonth__c commMonth
      } // if (commMonths != null
      System.debug('findCommissionMonth checkDate='+checkDate+' foundMonth='+foundMonth);
      return foundMonth;
   } // findCommissionMonth

   // Retrieve the NSS Audit records for the passed in ids.
   public static Map<Id,List<NSSAudit__c>> getNssAuditListMap(Set<Id> p_acctIdSet, List<Id> p_oppIds, Set<Id> p_ownerIds, Boolean onlyOpen) {
      Map<Id,List<NSSAudit__c>> nssAuditListMap = new Map<Id,List<NSSAudit__c>>();
      // if ownerids are passed in, records will be grouped by the owner
      Boolean byOwner = (p_ownerIds != null && !p_ownerIds.isEmpty());
      Set<Id> ownerIds = (byOwner ? p_ownerIds : new Set<Id>());
      Set<Id> acctIdSet = (p_acctIdSet != null ? p_acctIdSet : new Set<Id>());
      List<Id> oppIds = (p_oppIds != null ? p_oppIds : new List<Id>());
      Integer nbrRecs = 0;
      
      for (NSSAudit__c[] nssAudits : [Select Id
                                            ,Name
                                            ,OwnerId
                                            ,Account__c
                                            ,AuditNotes__c
                                            ,NSS_Source__c
                                            ,NSS_Team__c
                                            ,Opportunity__c
                                            ,Product__c
                                            ,Prospect_Ownership__c
                                            ,RecordTypeId
                                            ,RecordType.Name
                                            ,Revenue__c
                                            ,Status__c
                                            ,SubmitNotes__c
                                            ,Units__c
                                        From NSSAudit__c
                                       Where (Account__c in :acctIdSet or Opportunity__c in :oppIds or OwnerId in :ownerIds)
                                      ]) {
         nbrRecs += nssAudits.size();
         for (NSSAudit__c nssAudit : nssAudits) {
         	Id keyId = (byOwner ? nssAudit.OwnerId : nssAudit.Account__c);
         	// should always be attached to a 
            List<NSSAudit__c> auditList = nssAuditListMap.get(keyId);
            if (auditList == null) {
               auditList = new List<NSSAudit__c>();
               nssAuditListMap.put(keyId,auditList);
            }
            auditList.add(nssAudit);
         } // for (NSSAudit__c nssAudit
         
      } // for (NSSAudit__c[] NSSAudits
      
      System.debug('getNssAuditListMap nbrRecs='+nbrRecs+' nbrKeys='+nssAuditListMap.size());
      return nssAuditListMap;
   } // getNssAuditListMap

   // store in a map so only have to go loop through custom settings at most once
   private static Map<String,String> rtProdMap = null;

   public static void checkRtProdMap() {
      if (rtProdMap == null) {
         rtProdMap = new Map<String,String>();
         for (ProductGroupMapping__c pgm : ProductGroupMapping__c.getAll().values()) {
            if (pgm.MappingType__c == AUDIT_MAPPING_TYPE && String.isNotBlank(pgm.RecordTypeName__c)) {
               rtProdMap.put(pgm.RecordTypeName__c,pgm.Product_of_Interest__c);
               if (String.isNotBlank(pgm.RecordTypeName2__c)) {
                  rtProdMap.put(pgm.RecordTypeName2__c,pgm.Product_of_Interest__c);
               }
            } // if (pgm.MappingType__c
         } // for (ProductGroupMapping__c pgm
      } // if (rtProdMap == null
   } // checkRtProdMap
   
   public static String getDefaultAuditProduct(String recordTypeName) {
      String defaultProd = null;
      if (String.isNotBlank(recordTypeName)) {
         checkRtProdMap();
         defaultProd = rtProdMap.get(recordTypeName);
      } // if (String.isNotBlank
      
      return defaultProd;
   } // getDefaultAuditProduct

   public static String AUDIT_MAPPING_TYPE='NSS Audit';
   
   // handle when the product field changes on the NSS Audit object
   public static void handleProduct(NSSAudit__c[] nssAudits) {
      for (NSSAudit__c nssAudit : nssAudits) {
      	System.debug('handleProduct product='+nssAudit.Product__c);
      	if (String.isNotBlank(nssAudit.Product__c)) {
            ProductGroupMapping__c pgm = null;
            String source = (String.isNotBlank(nssAudit.NSS_Source__c) ? nssAudit.NSS_Source__c : ProspectOwnershipMethods.NSS_OUTBOUND);
            String team = (String.isNotBlank(nssAudit.NSS_Team__c) ? nssAudit.NSS_Team__c : UserHelper.SO_CORE);
            String key = (AUDIT_MAPPING_TYPE+'-'+source+team+nssAudit.Product__c).trim();
            pgm = ProductGroupMapping__c.getInstance(key);
            System.debug('handleProduct key='+key+'. pgm='+pgm);
            if (pgm == null) {
               // in case there isn't an NSS team
               String key2 = (AUDIT_MAPPING_TYPE+'-'+nssAudit.NSS_Source__c+nssAudit.Product__c).trim();
               pgm = ProductGroupMapping__c.getInstance(key2);
               System.debug('handleProduct key2='+key2+'. pgm='+pgm);
            }
            if (pgm != null) {
               nssAudit.Revenue__c = pgm.Revenue__c;
               nssAudit.Units__c = pgm.Units__c;
            }
      	} // if (String.isNotBlank
      } // for (NSSAudit__c nssAudit
   } // handleProduct
   
   // if a user is selected find the associated contact record and put it in the NSR field if it's not already there.
   public static void handleNSRContacts(NSSAudit__c[] nssAudits) {
   	// map by the user id for reference
   	Map<Id,CtctIdWrapper> ctctIdWrapperMap = new Map<Id,CtctIdWrapper>();
      // get the user ids
      for (NSSAudit__c nssAudit : nssAudits) {
         if (!ctctIdWrapperMap.containsKey(nssAudit.NSR_Name__c)) {
            CtctIdWrapper wrapper = new CtctIdWrapper(); 
            wrapper.userId = nssAudit.NSR_Name__c;
            ctctIdWrapperMap.put(wrapper.userId,wrapper);
         }
      } // for
      System.debug('handleNSRContacts ctctIdWrapperMap='+ctctIdWrapperMap.size());
      
      // map by person id - for easy reference after the query
      Map<String,CtctIdWrapper> ctctIdWrapperByPersonIdMap = new Map<String,CtctIdWrapper>();
      
      // select the users to get the person id - only select if they have a person id
      for (User usr : [Select Id, Name, HR_Person_Id__c from User where Id in :ctctIdWrapperMap.keySet() and HR_Person_Id__c != null]) {
         CtctIdWrapper wrapper = ctctIdWrapperMap.get(usr.Id);
         if (wrapper != null) {
            wrapper.personId = usr.HR_Person_Id__c;
            ctctIdWrapperByPersonIdMap.put(wrapper.personId, wrapper);
         }
      } // for (User usr
      System.debug('handleNSRContacts ctctIdWrapperByPersonIdMap='+ctctIdWrapperByPersonIdMap.size());

      // select the contacts by person id
      for (Contact ctct : [Select Id, HR_Person_Id__c from Contact where Account.Name=:UserHelper.PAYCHEX_COMP and HR_Person_Id__c in :ctctIdWrapperByPersonIdMap.keySet()]) {
         CtctIdWrapper wrapper = ctctIdWrapperByPersonIdMap.get(ctct.HR_Person_Id__c);
         if (wrapper != null) {
            wrapper.ctctId = ctct.Id;
         }
      } // for (Contact ctct
      
      // set the contact on the NSSAudit record
      for (NSSAudit__c nssAudit : nssAudits) {
         CtctIdWrapper wrapper = ctctIdWrapperMap.get(nssAudit.NSR_Name__c);
         if (wrapper != null && wrapper.ctctId != null && nssAudit.NSR__c != wrapper.ctctId) {
            nssAudit.NSR__c = wrapper.ctctId;
         }
      } // for (NSSAudit__c
      
   } // handleNSRContacts
   
   public static void handleNSRUsers(NSSAudit__c[] nssAudits) {
   	// map by the contact id
      Map<Id,CtctIdWrapper> ctctIdWrapperMap = new Map<Id,CtctIdWrapper>();
      // get the contact ids
      for (NSSAudit__c nssAudit : nssAudits) {
         if (!ctctIdWrapperMap.containsKey(nssAudit.NSR__c)) {
            CtctIdWrapper wrapper = new CtctIdWrapper(); 
            wrapper.ctctId = nssAudit.NSR__c;
            ctctIdWrapperMap.put(wrapper.ctctId,wrapper);
         }
      } // for
      System.debug('handleNSRContacts ctctIdWrapperMap='+ctctIdWrapperMap.size());
      
      // map by person id - for easy reference after the query
      Map<String,CtctIdWrapper> ctctIdWrapperByPersonIdMap = new Map<String,CtctIdWrapper>();
      
      // select the contacts by id
      for (Contact ctct : [Select Id, HR_Person_Id__c from Contact where Id in :ctctIdWrapperMap.keySet() and HR_Person_Id__c != null]) {
         CtctIdWrapper wrapper = ctctIdWrapperMap.get(ctct.Id);
         if (wrapper != null) {
            wrapper.personId = ctct.HR_Person_Id__c;
            ctctIdWrapperByPersonIdMap.put(ctct.HR_Person_Id__c,wrapper);
         }
      } // for (Contact ctct

      // select the users by the person id
      for (User usr : [Select Id, HR_Person_Id__c from User where Profile.Name like 'NSS%' and HR_Person_Id__c in :ctctIdWrapperByPersonIdMap.keySet() order by LastLoginDate desc nulls last]) {
         CtctIdWrapper wrapper = ctctIdWrapperByPersonIdMap.remove(usr.HR_Person_Id__c);
         if (wrapper != null) {
            wrapper.userId = usr.Id;
         }
      } // for (User usr
      
      // set the contact on the NSSAudit record
      for (NSSAudit__c nssAudit : nssAudits) {
         CtctIdWrapper wrapper = ctctIdWrapperMap.get(nssAudit.NSR__c);
         if (wrapper != null && wrapper.userId != null && nssAudit.NSR_Name__c != wrapper.userId) {
            nssAudit.NSR_Name__c = wrapper.userId;
         }
      } // for (NSSAudit__c

   } // handleNSRUsers
   
   public class CtctIdWrapper {
   	// the id of the user record
      public Id userId;
      // the person id of the user
      public String personId;
      // the contact id of the user
      public Id ctctId;
   } // class CtctIdWrapper
   
   public static void handleFromOpportunity(NSSAudit__c[] nssAudits) {
   	// extract the account ids and opportunity ids
   	Map<Id, NSSAudit__c> auditsToProcessMap = new Map<Id, NSSAudit__c>();
   	Set<Id> oppIdSet = new Set<Id>();
   	Set<Id> ctctIdSet = new Set<Id>();
   	
   	// if we set the user, populate the contact also
   	NSSAudit__c[] checkForContact = new NSSAudit__c[]{};
   	NSSAudit__c[] checkHandleProduct = new NSSAudit__c[]{};
   	
   	// select the prospect ownership records
   	for (NSSAudit__c audit : nssAudits) {
   		// check the NSS Source. If not equal to Inbound, we'll assume it's outbound
   		if (String.isBlank(audit.NSS_Source__c) || (audit.NSS_Source__c != ProspectOwnershipMethods.NSS_INBOUND && audit.NSS_Source__c != ProspectOwnershipMethods.NSS_OUTBOUND)) {
   		   audit.NSS_Source__c = ProspectOwnershipMethods.NSS_OUTBOUND;
   		}
   	   if (audit.Account__c != null) {
   	      auditsToProcessMap.put(audit.Account__c, audit);
   	      if (audit.Opportunity__c != null && audit.Product__c == null) {
               oppIdSet.add(audit.Opportunity__c);
   	      }
   	   } // if
   	   if (audit.NSR__c != null) {
   	      ctctIdSet.add(audit.NSR__c);
   	   }
   	} // for (NSSAudit__c
   	
   	// see if we can find a matching one
   	if (!auditsToProcessMap.isEmpty()) {
   		//Map<Id, List<OpportunityTeamMember>> oppTeamByOppIdMap = OpptyMethods.getTeamMembersByOpptyIdMap(oppIds);
   		Map<Id,Opportunity> oppMap = null;
   		
   		if (oppIdSet.isEmpty()) {
   		   oppMap = new Map<Id,Opportunity>();
   		} else {
            oppMap = OpptyMethods.getOppMapById(null, oppIdSet);
   		}
   		
   		Map<Id,Contact> ctctMap = null;
   		if (ctctIdSet.isEmpty()) {
   		   ctctMap = new Map<Id,Contact>();
   		} else {
   			ctctMap = new Map<Id,Contact>([Select Id, HR_Person_Id__c from Contact where Id in :ctctIdSet]);
   		}
   		 
   		
   		
   	   Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(auditsToProcessMap.keySet(), false, null, null);
   	   for (NSSAudit__c audit : auditsToProcessMap.values()) {
            Boolean otmFound = false;

   	   	if (audit.Opportunity__c != null) {
   	   	   Opportunity opp = oppMap.get(audit.Opportunity__c);
   	   	   if (opp != null) {
   	   	      if (audit.Product__c == null) {
                     audit.Product__c = getDefaultAuditProduct(opp.RecordType.Name);
                     checkHandleProduct.add(audit);
   	   	      }
   	   	      
   	   	      String hrPersonId = null;
   	   	      if (audit.NSR__c != null) {
   	   	         Contact ctct = ctctMap.get(audit.NSR__c);
   	   	         hrPersonId = (ctct != null ? ctct.HR_Person_Id__c : null);
   	   	      }
   	   	      OpportunityTeamMember otm = findTeamMember(opp, audit.NSS_Source__c, hrPersonId);
   	   	      if (otm != null) {
   	   	         otmFound = true;
   	   	         audit.NSR_Name__c = otm.UserId;
   	   	         audit.Prospect_Ownership__c = otm.Prospect_Ownership__c;
   	   	         audit.NSS_Team__c = otm.Prospect_Ownership__r.NSS_Team__c;
   	   	      }
   	   	   } // if (opp != null
   	   	} // if (audit.Opportunity__c
   	   	
   	   	
   	   	if (!otmFound) {
   	         List<Prospect_Ownership__c> acctOwners = acctOwnerMap.get(audit.Account__c);
   	         if (acctOwners != null) {
   	            for (Prospect_Ownership__c po : acctOwners) {
   	               // at this point we'll only match on the source
   	               if (po.NSS_Source__c == audit.NSS_Source__c && po.CommissionStart__c != null) {
   	                  // we'll assume this is a match
   	                  audit.Prospect_Ownership__c = po.Id;
   	                  audit.NSS_Team__c = po.NSS_Team__c;
   	                  if (audit.NSR_Name__c == null) {
                           audit.NSR_Name__c = po.NSR_Name__c;
   	                  }
   	                  if (audit.NSR__c == null) {
                        checkForContact.add(audit);
   	                  }
   	               } // if (po.NSS_Source__c
   	            } // for (Prospect_Ownership__c po
   	         
   	         } // if (acctOwners
   	   	} // if (!otmFound
   	   } // for (NSSAudit__c audit
   	} // if (!acctIds
   	
   	if (!checkForContact.isEmpty()) {
   	   handleNSRContacts(checkForContact);
   	}
   	
   	if (!checkHandleProduct.isEmpty()) {
   	   handleProduct(checkHandleProduct);
   	}
   } // handleFromOpportunity
  
   public static OpportunityTeamMember findTeamMember(Opportunity opp, String nssSource, String hrPersonId) {
      OpportunityTeamMember foundOtm = null;
      if (opp != null && opp.OpportunityTeamMembers != null) {
      	// if find by person id, stop
      	// if source matches, use as match but continue in case we find one by person id
         for (OpportunityTeamMember otm : opp.OpportunityTeamMembers) {
            if (String.isNotBlank(hrPersonId) && otm.User.HR_Person_Id__c == hrPersonId && otm.Prospect_Ownership__r != null) {
               foundOtm = otm;
               break;
            } else if (foundOtm == null && otm.Prospect_Ownership__r != null && otm.Prospect_Ownership__r.NSS_Source__c == nssSource) {
               foundOtm = otm;
            }
         } // for (OpportunityTeamMember otm
      } // if (opp != null
      return foundOtm;
   } // findTeamMember
   
} // class NSSAuditHelper