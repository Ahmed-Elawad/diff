/* 
 * Helper for the PEO Centric functionality.
 
 Adding a New Lead to Salesforce
•  If a PEO Centric rep enters the Lead into Salesforce, then it should be considered a PEO account indefinitely, until otherwise indicated.
•  Purchased lead lists will be uploaded through a loading mechanism.
o  A list of Accounts from this list that are Existing in Salesforce is needed as an output, including number of Open Opportunities and number of Open Activities.
•  The PEO Centric rep should be assigned as the Lead Owner.
•  Upon Conversion:
o  The PEO Centric rep should be assigned as the Prospect-Client Owner.
o  Prospect-Client Type should equal ‘PEO Prospect’.
o  PEO/Leasing checkbox should be checked.
 
 PEO Centric Rep Engaging with an Existing Account in Salesforce
1. If the Account is a current Paychex client on any services (including HRS Client (Only))
a. Paychex clients are not eligible for PEO prospecting.

2. If the Account has an Open Activity or Open Opportunity for Paychex reps
a. This prospect is not eligible for PEO prospecting if another Paychex sales rep is engaged with the prospect.

3. If the Account has no Open Activities or Open Opportunities for Paychex reps 
a. If the Account has no Activities or Opportunities within the last 12 months:
i. Purchased lists loaded into Salesforce that identify a match to an existing Account will be automatically assigned to the PEO Centric rep
ii.   If the PEO Centric rep self generates a lead for an existing Account, the PEO Centric rep can crossover to take ownership of the Account.
1. The crossover will automatically be approved.
2. Will there be a notification to the SMB/MMS sales rep?
b. If the Account has Activities or Opportunities within the last 12 months:
i. The PEO Centric rep can crossover to take ownership of the Account.
ii.   The SMB/MMS sales rep can reject the lead if they are working with the prospect.
1. Crossovers are automatically approved after 24 hours.
c. All ownership fields and account team members should be cleared, and only the PEO Centric rep should remain as the Prospect-Client Owner.
d. The Account should be considered a PEO account indefinitely, until otherwise indicated.
e. Prospect-Client Type should equal ‘PEO Prospect’.
f. PEO/Leasing checkbox should be checked.
 
 
 *
 * History
 * -------
   06/13/2018 Dan Carmen         Created
   07/11/2018 Dan Carmen         Added option to not check for closed activity
   03/19/2019 Jake Hinds         Changes for PEO Sales org, changes to audit log tracking
   05/28/2019 Jake Hinds	     Oppty Not Sold Method
   01/07/2022 Dan Carmen         Increment API version, remove unusded code
   
 */
public without sharing class PeoHelper implements TriggerInterfaceC {
   public static String PEO_PROFILE_NAME=Label.Profile_PEO_Centric;
   public static String PEO_LEAD_RT_NAME=Label.RT_PEO_Lead;
   public static String RT_PROSPECT=Label.RT_Prospect_Acct;
   /*
   // labels for Type field: Prospect, PEO Prospect
   public static String TYPE_PROSPECT=Label.AccountTypeProspect;
   public static String TYPE_PEO_PROSP=Label.AccountTypePeoProspect;
   public static String ZIP_SEGMENT_PEO=Label.ZipSegment_PEO_C;
   
   public static Boolean SKIP_ACCT_TRIGGER=false;
   public static Boolean SKIP_LEAD_TRIGGER=false;
   public static Boolean SKIP_OPPTY_TRIGGER=false;
   
   public static Set<Id> opptyResetAccount = new Set<Id>();
   
   //when this runs on lead insert it won't be able to create an audit log because there's no Id to attach it to.
   //store these in a map to fix them in the lead after insert trigger.
   public static Map<String,Audit_Log__c> orphanedLeadAuditLogs = new Map<String,Audit_Log__c>();
   */

   // the number of months we'll check back for activity
   public static Integer NUM_MONTHS_CHECK=12;
   // check all of the records as a group before cycling through them individually
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      System.debug('PeoHelper.handleTrigger recs='+(recs != null ? recs.size() : -1));
      if (recs != null && !recs.isEmpty()) {
         //if (!SKIP_ACCT_TRIGGER && isBefore && recs[0].getSObjectType() == Account.sObjectType) {
            // check if the payroll start date changes
            //checkAccountChange((Account[])recs, (Map<Id,Account>)oldMap);
         //} else 
         if (isBefore && recs[0].getSObjectType() == Lead.sObjectType) {
            checkLeads((Lead[])recs, (Map<Id,Lead>)oldMap);
         //} else if (!SKIP_LEAD_TRIGGER && isAfter && recs[0].getSObjectType() == Lead.sObjectType) {
            //checkForOrphans((Lead[])recs, (Map<Id,Lead>)oldMap);
         //} else if (!SKIP_OPPTY_TRIGGER && isAfter && recs[0].getSObjectType() == Opportunity.sObjectType) {
         //   checkOpportunityStage((Opportunity[])recs, (Map<Id,Opportunity>)oldMap);
         }
      } // if (recs != null && !recs.isEmpty
      
   } // handleTrigger

   public static Set<String> peoProductSet = new Set<String>(Label.Product_Division_PEO.split(';'));
    
   public static void checkLeads(Lead[] leads, Map<Id,Lead> oldMap) {
      User runningUser = UserHelper.getRunningUser();
      Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType(PEO_LEAD_RT_NAME, ObjectHelper.OBJECT_LEAD);

      Map<Id,Lead> checkLeadForPeoMap = new Map<Id,Lead>();
      for (Lead ld : leads) {
         Lead oldLd = (oldMap != null ? oldMap.get(ld.Id) : null);
         // if new leads are being created by PEO-Centric reps, make sure that the record is setup correctly.
         if (oldLd == null && runningUser.Profile.Name == PEO_PROFILE_NAME) {
            ld.RecordTypeId = (rtInfo != null ? rtInfo.getRecordTypeId() : ld.RecordTypeId);
            ld.PEOLeasing__c = true;
            StringHelper.addToProcessNotes(ld,'Set to PEO Record Type based on PEO Rep Creating the lead');
         }
         if (String.isNotBlank(ld.Product_Division__c) && (oldLd == null || ld.Product_Division__c != oldLd.Product_Division__c)) {
            String productDivision = ld.Product_Division__c.trim();
            if (peoProductSet != null && peoProductSet.contains(productDivision)) {
               if (oldLd == null) {
                  ld.PeoLeasing__c = true;
                  ld.RecordTypeId = (rtInfo != null ? rtInfo.getRecordTypeId() : ld.RecordTypeId);
                  StringHelper.addToProcessNotes(ld,'Set to PEO Record Type based on Product Division');
               } else {
                  // if already exists, check for existing activity
                  checkLeadForPeoMap.put(ld.Id,ld);
               }
            }
         }
      }
       
      if (!checkLeadForPeoMap.isEmpty()) {
         checkLeadsForPeo(checkLeadForPeoMap, rtInfo);
      }
   } // checkLeads
    
   public static void checkLeadsForPeo(Map<Id,Lead> checkLeadForPeoMap, Schema.RecordTypeInfo rtInfo) {
      Date compareDate = Date.today().addMonths(-NUM_MONTHS_CHECK);
      Lead[] queryLeads = 
           [Select Id, Name, OwnerId, RecordTypeId, PostalCode
                  ,(Select Id, ActivityDate, IsClosed, OwnerId from OpenActivities
                      order by ActivityDate Asc, LastModifiedDate Desc
                      limit 1)
                  //,(Select Id, ActivityDate, IsClosed, OwnerId from ActivityHistories where ActivityDate > :compareDate)
              From Lead
             Where Id in :checkLeadForPeoMap.keySet()];
      for (Lead chkLd : queryLeads) {
         Lead ld = checkLeadForPeoMap.get(chkLd.Id);
         if (ld != null) {
            if (chkLd.OpenActivities.isEmpty()) {
               ld.PeoLeasing__c = true;
               ld.RecordTypeId = (rtInfo != null ? rtInfo.getRecordTypeId() : ld.RecordTypeId);
               StringHelper.addToProcessNotes(ld,'Set to PEO Record Type based on Product Division Change');
            } else {
               StringHelper.addToProcessNotes(ld,'Open Activities are present - not eligible for PEO-Centric Ownership');
            }
         } // if (ld != null
      } // for
            
   } // checkLeadsForPeo

      /*

   public static void removeAcctTeamMembers(Id[] acctIds) {
      Set<String> teamMemberSet = getTeamMembersToClear();
      if (!acctIds.isEmpty() && !teamMemberSet.isEmpty()) {
         try {
            delete [Select Id from AccountTeamMember where AccountId in :acctIds and TeamMemberRole in :teamMemberSet];
         } catch (Exception e) {
            System.debug('removeAcctTeamMembers deleting AccountTeamMember failed: '+e.getMessage()+'; '+e.getStackTraceString());
         }
      } // if (!acctIds.isEmpty
   } // removeAcctTeamMembers
   public static Set<String> teamMemberNameSet = null;
   
   public static Set<String> getTeamMembersToClear() {
      if (teamMemberNameSet == null) {
         teamMemberNameSet = new Set<String>();
         Zip_Segment__c[] segments = ZipQueries.getAllSegments();
         for (Zip_Segment__c segment : segments) {
            if (String.isNotBlank(segment.TeamRole__c)) {
               teamMemberNameSet.add(segment.TeamRole__c);
            }
         }
      } // if (teamMemberNameSet
      return teamMemberNameSet;
   } // checkOwnerFldsAndTeamMembers
   */
   //when all of this peo code fires on lead insert, we can't link the audit logs to the lead
   //try and link them up after the fact using the after trigger
   /*
   public static void checkForOrphans(Lead[] leads, Map<Id,Lead> oldMap){
      Id leadPEORT = RecordTypeHelper.getRecordType(Label.RT_PEO_Lead, 'Lead').getRecordTypeId();
      if(orphanedLeadAuditLogs!=null && !orphanedLeadAuditLogs.isEmpty()){
      	 system.debug('in orphan method orphanedLeadAuditLogs: '+orphanedLeadAuditLogs);
      	 for(Lead ld:leads){
      	 	String transactionKey = ld.FirstName+ld.LastName+ld.Company; 
      	 	system.debug('in orphan method ldRT: '+ ld.RecordTypeId+' leadPEORT:'+leadPEORT+' transactionKey'+transactionKey);
      	 	if(ld.RecordTypeId == leadPEORT && orphanedLeadAuditLogs.containsKey(transactionKey)){
      	 		Audit_Log__c audit = orphanedLeadAuditLogs.get(transactionKey);
      	 		audit.Lead__c = ld.Id;
      	 		auditsToInsert.add(audit);
      	 		system.debug('adding audit to save');
      	 	}
      	 }
      	 saveAuditLogs();
      }
   }
   
   public static Audit_Log__c[] auditsToInsert = new Audit_Log__c[]{};
   
   public static Boolean saveAuditLogs() {
      if (!auditsToInsert.isEmpty()) {
         DmlHelper.performDML2(auditsToInsert, DmlHelper.DML_INSERT, 'PeoHelper', 'saveAuditLogs', 'insert new Audit_Log__c records', true);
         system.debug('PEOHelper saving audit logs');
         auditsToInsert.clear();
      }
      return true;
   } // saveAuditLogs
   
   // write record to Audit object 
   public static Audit_Log__c peoAuditLog(SObject sobj, PeoWrapper wrap) {
   	  system.debug('audit log '+sobj+ ' wrap: '+wrap);
      Audit_Log__c audit = new Audit_Log__c();
      String transactionKey;
      if (sobj.getSObjectType() == Lead.sObjectType)
      {     Lead ld = (Lead)sobj;
      		transactionKey = ld.FirstName+ld.LastName+ld.Company;
            audit.Lead__c = ld.Id;
            audit.Campaign__c = ld.LatestCampaign__c;
      }
      if (sobj.getSObjectType() == Account.sObjectType)
      {     
      		Account acct = (Account)sobj;
      		audit.Account__c = acct.Id;
      }
      if (sobj.getSobjectType() == Contact.sObjectType){
          Contact ctct = (Contact)sobj;
          audit.Contact__c = ctct.Id;
          audit.Account__c = ctct.AccountId;
          audit.Campaign__c = ctct.LatestCampaign__c;
      }
      audit.Type__c = 'PEO Centric';
      if(wrap!=null && String.isNotBlank(wrap.notOkayReason)){
        audit.Message__c = wrap.notOkayReason;
        audit.Description__c = 'Not PEO Eligible';
      }
      else{
        audit.Message__c = 'Success';
        audit.Description__c = 'PEO Eligible';
      }  
      system.debug('orphanedLeadAuditLogs contains: '+(!orphanedLeadAuditLogs.containsKey(transactionKey))+' Id: '+Audit.Lead__c);
      if((orphanedLeadAuditLogs!=null && !orphanedLeadAuditLogs.containsKey(transactionKey) || orphanedLeadAuditLogs == null)
      		&& (audit.Lead__c !=null || audit.Account__c !=null || audit.Contact__c !=null )){
        auditsToInsert.add(audit);
      }
      else if(sobj.getSObjectType() == Lead.sObjectType && audit.Lead__c ==null){
      	orphanedLeadAuditLogs.put(transactionKey,audit);
      }
      
      system.debug('orphanedLeadAuditLogs'+orphanedLeadAuditLogs);
      return audit;
      //insert audit;
      
   } // peoAuditLog
   

   // are the passed in leads eligible for PEO centric ownership?
   public static Map<Id,PeoWrapper> checkLeadsForPeo(Id[] leadIds) {
      Map<Id,PeoWrapper> resultMap = new Map<Id,PeoWrapper>();
        
      Date compareDate = Date.today().addMonths(-NUM_MONTHS_CHECK);
      Lead[] queryLeads = 
           [Select Id, Name, OwnerId, RecordTypeId, PostalCode
                  ,(Select Id, ActivityDate, IsClosed, OwnerId from OpenActivities
                      order by ActivityDate Asc, LastModifiedDate Desc
                      limit 500)
                  ,(Select Id, ActivityDate, IsClosed, OwnerId from ActivityHistories where ActivityDate > :compareDate)
              From Lead
             Where Id in :leadIds];
    
      for (Lead ld : queryLeads) {
         PeoWrapper wrap = new PeoWrapper(ld);
         resultMap.put(ld.Id, wrap);
         if (!ld.OpenActivities.isEmpty()) {
            wrap.setNotOkay(ld.OpenActivities.size()+' Open Activities are present - not eligible for PEO-Centric Ownership');
         }   
      } // for
            
      return resultMap;
   } // checkLeadsForPeo

   public static Map<Id,PeoWrapper> checkAccountsForPeo(Id[] acctIds) {
      return checkAccountsForPeo(acctIds, false);
   } // checkAccountsForPeo

   public static Map<Id,PeoWrapper> checkAccountsForPeo(Id[] acctIds, Boolean checkForZip) {
      return checkAccountsForPeo(acctIds, checkForZip, true);
   }

   // are the passed in accounts eligible for PEO centric ownership?
   public static Map<Id,PeoWrapper> checkAccountsForPeo(Id[] acctIds, Boolean checkForZip, Boolean checkClosedActivity) {
      Date compareDate = Date.today().addMonths(-NUM_MONTHS_CHECK);
      Account[] queryAccts = 
           [Select Id, Name, OwnerId, RecordTypeId, CurrentClient__c, Owner_Zip_Code__c
                  ,(Select Id, ActivityDate, IsClosed, OwnerId from OpenActivities
                      order by ActivityDate Asc, LastModifiedDate Desc
                      limit 500)
                  ,(Select Id, ActivityDate, IsClosed, OwnerId from ActivityHistories where ActivityDate > :compareDate)
                  ,(Select Id, Name, CloseDate, IsClosed, IsWon from Opportunities 
                     where IsClosed = false
                        or CloseDate > :compareDate)
              From Account
             Where Id in :acctIds];
      Map<String,Boolean> zipExistsMap = getZipExistsMap(checkForZip ? queryAccts : null);

      Map<Id,PeoWrapper> resultMap = new Map<Id,PeoWrapper>();
      for (Account acct : queryAccts) {
         PeoWrapper wrap = new PeoWrapper(acct);
         resultMap.put(acct.Id, wrap);
         if (acct.CurrentClient__c) {
            wrap.setNotOkay('Current Clients are not eligible for Ownership Change');
         } else if (!acct.OpenActivities.isEmpty()) {
            wrap.setNotOkay(acct.OpenActivities.size()+' Open Activities are present - not eligible for Ownership Change');
         } else if (checkClosedActivity && !acct.ActivityHistories.isEmpty()) {
            wrap.setNotOkay(acct.ActivityHistories.size()+' Activities exist within the last '+NUM_MONTHS_CHECK+' months - not eligible for Ownership Change');
         } else {
            Integer openOpps = 0;
            Integer closedOpps = 0;
            for (Opportunity opp : acct.Opportunities) {
               if (!opp.isClosed) {
                  openOpps++;
               } else {
                  closedOpps++;
               }
            }
            if (openOpps > 0) {
               wrap.setNotOkay(openOpps+' Open Opportunities exist! Not eligible for Ownership Change');
            } else if (checkClosedActivity && closedOpps > 0) {
               wrap.setNotOkay(openOpps+' Closed Opportunities within the last '+NUM_MONTHS_CHECK+' months exist! Not eligible for Ownership Change');
            }
         }
         // do a final zip code check - make sure there's an available rep
         if (checkForZip && wrap.okayForPeo) {
            Boolean zipExists = zipExistsMap.get(acct.Owner_Zip_Code__c);
            if (zipExists == null || zipExists == false) {
               wrap.setNotOkay(acct.Owner_Zip_Code__c+' does not appear to have a PEO-Centric Zip Assignment! Could not change ownership!');
            }
         }
      } // for (Account acct
      return resultMap;
   } // checkAccountsForPeo
   
   public static Map<String,Boolean> getZipExistsMap(Account[] accts) {
      Map<String,Boolean> zipExistsMap = new Map<String,Boolean>();
      if (accts != null && !accts.isEmpty()) {
         Set<String> zipSet = new Set<String>();
         for (Account acct : accts) {
            if (String.isNotBlank(acct.Owner_Zip_Code__c)) {
               zipSet.add(acct.Owner_Zip_Code__c);
            }
         } // for (Account acct
         if (!zipSet.isEmpty()) {
            Zip_Assignment__c[] assigns = [Select Id, Name, User__r.Id, User__r.IsActive
                                                From Zip_Assignment__c
                                               Where Name in :zipSet
                                                 and Zip_Segment__r.Sales_Org__c=:UserHelper.SO_PEO
                                                 and Zip_Segment__r.Name = :ZIP_SEGMENT_PEO];
            for (Zip_Assignment__c za : assigns) {
               if (za.User__r != null && za.User__r.IsActive) {
                  zipExistsMap.put(za.Name, true);
               }
            } // for (Zip_Assignment__c za
         } // if (!zipSet.isEmpty
      } // if (accts != null
      return zipExistsMap;
   } // getZipExistsMap
   
   public class PeoWrapper {
      public PeoWrapper(Account p_acct) {
         acctId=p_acct.Id;
      }
      public PeoWrapper(Lead p_ld) {
         ldId=p_ld.Id;
      }      
      public Id ldId;
      public Id acctId;
      public Boolean okayForPeo=true;
      public String notOkayReason;
      
      public void setNotOkay(String p_notOkayReason) {
         okayForPeo = String.isBlank(p_notOkayReason);
         notOkayReason = p_notOkayReason;
      }
   } // class PeoWrapper
   
   public static final Integer PROCESS_NOTES_SIZE = Account.ProcessNotes__c.getDescribe().getLength();
   
   public static void addToAcctNotes(SObject obj, String notesToAdd) {
      StringHelper.addNotesToField(obj, 'ProcessNotes__c', PROCESS_NOTES_SIZE, notesToAdd, true);
   } // addToCtctLeadNotes
   */
} // class PeoHelper