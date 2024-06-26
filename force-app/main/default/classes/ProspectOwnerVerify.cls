/* 
 * Batch process to verify the ownership information
 *
 * History
 * -------
 * 09/09/2014 Dan Carmen   Created
   08/11/2015 Dan Carmen   dont't include inactive users in the verify process.
   12/15/2015 Dan Carmen   Make sure the end date is populated for expired records.
   12/30/2015 Dan Carmen   Change to be able to handle inactive users on end dated records.
   03/18/2016 Dan Carmen   Better handle ended records
   06/30/2016 Dan Carmen   Add a check to verify the number of days in the commission period
   04/26/2017 Cindy Freeman     Added counter so verify will run against Expired records more than once, 
                                trying to fix Account.Assigned to NSR not being unchecked
   05/23/2017 Cindy Freeman Fix processLeads to use VerifyNeeded and not EndDateVerified
   01/10/2020 Dan Carmen      Fix to expire ownership if no account or lead is attached.
 *
 */
global without sharing class ProspectOwnerVerify implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

   /** The number of distinct prospect ownership found. */
   global Integer numOwnershipRecs = 0;
   global ProspectOwnershipBatch.CounterObj totalRecs = new ProspectOwnershipBatch.CounterObj();
   
   /** The number of records at the end of their status cycle. */
   global ProspectOwnershipBatch.CounterObj verifyLeads = new ProspectOwnershipBatch.CounterObj();
   global ProspectOwnershipBatch.CounterObj verifyAccts = new ProspectOwnershipBatch.CounterObj();

   /** The number of records that changed to a new status - not expired. */
   global ProspectOwnershipBatch.CounterObj newStatusLeads = new ProspectOwnershipBatch.CounterObj();
   global ProspectOwnershipBatch.CounterObj newStatusAccts = new ProspectOwnershipBatch.CounterObj();
   global ProspectOwnershipBatch.CounterObj expiredAccts = new ProspectOwnershipBatch.CounterObj();
   global ProspectOwnershipBatch.CounterObj expiredLeads = new ProspectOwnershipBatch.CounterObj();

   /** The number of account team members created. */
   global Integer teamMembersCreated = 0;
   /** The number of account team members deleted. */
   global Integer teamMembersDeleted = 0;
   /** The number of accounts updated. */
   global Integer acctsUpdated = 0;
   /** The number of leads updated. */
   global Integer leadsUpdated = 0;
   
   /** The number of ownership records modified. */
   global Integer numOwnershipModified = 0;
   /** The number of ownership records ended. */
   global Integer numOwnershipRecsEnded = 0;
   /** The number of ownership records changed to workable. */
   global Integer numOwnershipRecsWorkable = 0;
   /** The number of ownership records where commission stage changed to end. */
   global Integer numOwnershipRecsComEnd = 0;
   /** The number of ownership records attached to accounts. */
   global Integer numAccountOwnerships = 0;
   /** The number of ownership records attached to leads. */
   global Integer numLeadOwnerships = 0;
   
   global Date commissionDate = Date.today();
   
   global String processingMsg = '';
   
   global String batchMsg = '';
   
   global JobHelper jh = new JobHelper('ProspectOwnerVerify');
   
   // used to share methods
   global ProspectOwnershipBatch pob = new ProspectOwnershipBatch();
   
   /** Default constructor.
    */
   global ProspectOwnerVerify() {
      //ChangeLog.headerFields = ChangeLog.DEF_HEADER_FIELDS;
   } // ProspectOwnerVerify
   
   
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
   
   
   // Query the batches to be processed.
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      // for normal running
      String query = ProspectOwnershipMethods.getProspectOwnerQuery(); //ObjectHelper.getSOQLQuery('Prospect_Ownership__c',null,true, true);
      // get all non-ended ownership records
      //Integer numDaysBetweenVerify = Integer.valueOf(Label.Prospect_Owner_Verify_Days);
      //DateTime verifyDateTime = DateTime.now().addDays(-numDaysBetweenVerify);
      Datetime rightNow = Datetime.now();
      
      query += ' Where NextVerifyDate__c <= :rightNow ';
      //query += ' Where (LastVerified__c = null or ((LastVerified__c <= :verifyDateTime) ';
      //query += ' Where (VerifyNeeded__c = true or LastVerified__c = null or ((LastVerified__c <= :verifyDateTime) ';
      //query += '    and ((EndDate__c = null) or (EndDateVerified__c = false) or (CommissionEnd__c >= :commissionDate and CommissionStart__c <= :commissionDate)))) ';
      //query += ' and NSR_Name__r.IsActive=true';
      query += ' and NSR_Name__r.UserRoleId != null';
      query += ' and NSR_Name__r.ProfileId != null';
      
      //System.debug('start verifyDateTime='+verifyDateTime+' commissionDate='+commissionDate+' query='+query);
      System.debug('start query='+query);
      
      return Database.getQueryLocator(query);

   } // start
   
   global static Integer BATCH_SIZE=100;
   
   /** In order to schedule a batch run
    */
   global void execute(SchedulableContext sc) {
      ProspectOwnerVerify pov = new ProspectOwnerVerify();
      database.executeBatch(pov, BATCH_SIZE);
   } // execute

   global void execute(Database.BatchableContext BC, List<SObject> scope) {
      List<Prospect_Ownership__c> recs = (List<Prospect_Ownership__c>)scope;
      System.debug('ProspectOwnershipBatch number of recs='+recs.size());
      
      // the records to update
      Prospect_Ownership__c[] updateRecs = new Prospect_Ownership__c[]{};
      
      // the ownership records that are linked to accounts
      Prospect_Ownership__c[] acctRecs = new Prospect_Ownership__c[]{};
      // the account ids
      Id[] acctIds = new Id[]{};
      // the ownership records that are linked to leads
      Prospect_Ownership__c[] leadRecs = new Prospect_Ownership__c[]{};
      // the lead ids
      Id[] leadIds = new Id[]{};
      
      ProspectOwnershipMethods.initializeSaveObjects();
      
      // keep a total count
      numOwnershipRecs += recs.size();

      // a set of the ids (account or lead) that are ended - to look for any open ownership
      Set<Id> endedIdSet = new Set<Id>();
      
      // separate out the leads and the accounts
      for (Prospect_Ownership__c po : recs) {
         // keep track of total number of records found
         pob.addToCounter(totalRecs, po.NSS_Team__c, po.Ownership_Status__c, 1);
         po.LastVerified__c = DateTime.now();
         po.Verified__c = true;
                  
         // see if there's a setting for this value. If not - what do we do with this record?
         LifeOfLeadSettings__c lols = ProspectOwnershipMethods.getSetting(po);
         if (lols != null) {
            // verify the number of days in the stage
            if (po.StatusNbrDays__c != lols.NumOfDays__c) {
               po.StatusNbrDays__c = lols.NumOfDays__c;
            }
         } else {
            // if no setting found clear out the number of days
            po.StatusNbrDays__c = null;
         } // if
         
         // make sure the end date is populated if expired
         if (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_EXPIRED && po.EndDate__c == null) {
            po.EndDate__c = Date.today();
            // TODO - make sure hold out removed from contact!
         } 
         
         // look for orphan prospect ownership records. We just want to end these records with no further processing.
         if (po.EndDate__c == null && po.Lead__c == null && po.Prospect_Client__c == null) {
            // if no lead or account, just end the record.
            ProspectOwnershipMethods.addToProcessTracker(po,'ProspectOwnerVerify.execute force expire with no account or lead.');
            StringHelper.addToProcessNotes(po,'ProspectOwnerVerify.execute force expire with no account or lead.');
            ProspectOwnershipMethods.setStageExitInfo(po, null, null, null, null, true, true, true);
            po.EndDateVerified__c = true;
            // because we don't want it to go through the verify process again.
            po.VerifyCount__c = 77;
         }

         if (po.EndDate__c != null || (po.NSR_Name__r != null && po.NSR_Name__r.IsActive)) {         
            // should always be either an account or a lead.
            if (po.Prospect_Client__c != null) {
               // the number of records attached to accounts
               pob.addToCounter(verifyAccts, po.NSS_Team__c, po.Ownership_Status__c, 1);
               acctRecs.add(po);
               acctIds.add(po.Prospect_Client__c);
               if (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_EXPIRED && po.VerifyNeeded__c) { //&& !po.EndDateVerified__c) {
                  endedIdSet.add(po.Prospect_Client__c);
               }
            } else if (po.Lead__c != null) {
               // the number of records attached to leads
               pob.addToCounter(verifyLeads, po.NSS_Team__c, po.Ownership_Status__c, 1);

               leadRecs.add(po);
               leadIds.add(po.Lead__c);
               if (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_EXPIRED && !po.EndDateVerified__c) {
                  endedIdSet.add(po.Lead__c);
               }
            }
         } // if (po.EndDate__c != null
         
      } // for
      
      if (!recs.isEmpty()) {
         
         // get the ids of the leads and accounts that have open ownership
         Set<Id> openOwnershipIds = getOpenOwnershipIds(endedIdSet);
      
         if (!acctRecs.isEmpty()) {
            processAccounts(acctRecs,acctIds,openOwnershipIds);
         }
      
         if (!leadRecs.isEmpty()) {
            processLeads(leadRecs,leadIds,openOwnershipIds);
         }
         
         Database.SaveResult[] results = Database.update(recs,false);
         
         ProspectOwnershipMethods.checkForSaves();
         
         // update quantity counts
         teamMembersCreated += ProspectOwnershipMethods.newATMMap.size();
         teamMembersDeleted += ProspectOwnershipMethods.delATMMap.size();
         acctsUpdated += ProspectOwnershipMethods.saveAcctMap.size();
         leadsUpdated += ProspectOwnershipMethods.saveLeadMap.size();
      } // if (!updateRecs
   } // execute
   
   global Set<Id> getOpenOwnershipIds(Set<Id> endedIdSet) {
      Set<Id> openIdSet = new Set<Id>(); 
      if (endedIdSet != null && !endedIdSet.isEmpty()) {
         String query = ProspectOwnershipMethods.getProspectOwnerQuery();
   
         if (query != null) {
            query += ' Where EndDate__c = null and (Prospect_Client__c in :endedIdSet or Lead__c in :endedIdSet) ';
            for (Prospect_Ownership__c po : Database.query(query)) {
               if (po.Prospect_Client__c != null) {
                  openIdSet.add(po.Prospect_Client__c);
               } else if (po.Lead__c != null) {
                  openIdSet.add(po.Lead__c);
               }
            } // for (Prospect_Ownership__c po
         } // if (query != null  
      } //  if (acctLeadIdSet != null        
      return openIdSet;
   } // getOpenOwnershipIds
   
   // check account team
   // check opportunity team
   // check owner of contact
   // check assigned to NSR checkboxes
   global Boolean processAccounts(Prospect_Ownership__c[] acctRecs, Id[] acctIds, Set<Id> openOwnershipIds) {
      Boolean okay = true;
      numAccountOwnerships += acctRecs.size();
      // select the accounts
      Map<Id, Account> acctMap = ReferralQueries.selectAcctMap(acctIds);
      Prospect_Ownership__c[] checkOppAccts = new Prospect_Ownership__c[]{};
 
      for (Prospect_Ownership__c po : acctRecs) {
         //if (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_EXPIRED && !po.EndDateVerified__c) {
         if (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_EXPIRED && po.VerifyNeeded__c) {
            if (!openOwnershipIds.contains(po.Prospect_Client__c)) {
               ProspectOwnershipMethods.addToProcessTracker(po,'ProspectOwnerVerify.processAccounts checking Expired');
               ProspectOwnershipMethods.setExpired(po,acctMap.get(po.Prospect_Client__c), null, null, null, true, null);
            }
            po.EndDateVerified__c = true;
            po.VerifyCount__c = (po.VerifyCount__c == null ? 1 : po.VerifyCount__c + 1);
            pob.addToCounter(expiredAccts, po.NSS_Team__c, po.Ownership_Status__c, 1);
         } else {
            //openAcctRecs.add(po);
            // these should be open records - verify the stage
            ProspectOwnershipMethods.addToProcessTracker(po,'ProspectOwnerVerify.processAccounts verifying stage '+po.Ownership_Status__c);
            if (ProspectOwnershipMethods.verifyStage(po, acctMap.get(po.Prospect_Client__c), null, null, null)) {
               pob.addToCounter(newStatusAccts, po.NSS_Team__c, po.Ownership_Status__c, 1);
            }
         }
         
         // verify the number of days in the commission period
         if (po.CommissionStart__c != null && po.CommissionEnd__c != null) {
            LifeOfLeadSettings__c comLols = ProspectOwnershipMethods.getSetting(ProspectOwnershipMethods.STAGE_LOCKOUT,po.NSS_Team__c,po.NSS_Source__c,po.Segment__c);
            if (comLols != null && comLols.NumComDays__c != null) {
               Date checkEndDate = po.CommissionStart__c.addDays(Integer.valueOf(comLols.NumComDays__c));
               if (po.CommissionEnd__c != checkEndDate) {
                  po.CommissionEnd__c = checkEndDate;
               }
            }
         } // if (po.CommissionStart__c != null && po.CommissionEnd__c != null
         
         if (po.CommissionStart__c != null && po.CommissionStart__c <= commissionDate && commissionDate <= po.CommissionEnd__c) {
            checkOppAccts.add(po);
         }

      } // for
      
      if (!checkOppAccts.isEmpty()) {
         OpptyMethods.checkCommissionableOpps(checkOppAccts);
      }
      return okay;
   } // processAccounts
   
   // check owner of lead
   global Boolean processLeads(Prospect_Ownership__c[] leadRecs, Id[] leadIds, Set<Id> openOwnershipIds) {
      Boolean okay = true;
      numLeadOwnerships += leadRecs.size();
      // select the leads
      Map<Id, Lead> leadMap = ReferralQueries.selectLeadMap(leadIds,null);
      for (Prospect_Ownership__c po : leadRecs) {
         //if (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_EXPIRED && !po.EndDateVerified__c) {
         if (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_EXPIRED && po.VerifyNeeded__c) {
            if (!openOwnershipIds.contains(po.Lead__c)) {
               ProspectOwnershipMethods.addToProcessTracker(po,'ProspectOwnerVerify.processLeads checking Expired');
               ProspectOwnershipMethods.setExpired(po, null, null, null, leadMap.get(po.Lead__c), true, null);
            }

            po.EndDateVerified__c = true;
            po.VerifyCount__c = (po.VerifyCount__c == null ? 1 : po.VerifyCount__c + 1);
            pob.addToCounter(expiredLeads, po.NSS_Team__c, po.Ownership_Status__c, 1);
         } else {
            ProspectOwnershipMethods.addToProcessTracker(po,'ProspectOwnerVerify.processLeads verifying stage '+po.Ownership_Status__c);
            if (ProspectOwnershipMethods.verifyStage(po, null, null, null, leadMap.get(po.Lead__c))) {
               pob.addToCounter(newStatusLeads, po.NSS_Team__c, po.Ownership_Status__c, 1);
            }
         }
      } // for
      return okay;
   } // processLeads
   
   global void finish(Database.BatchableContext BC){
      // Get the ID of the AsyncApexJob representing this batch job
      String message = '\nTotal Open Ownership Records Found: '+numOwnershipRecs;
      message += '\n';
      message += pob.outputCounter('Total Records', totalRecs);

      message += '\n';
      message += pob.outputCounter('Leads verified', verifyLeads);
      message += pob.outputCounter('Prospect-Clients verified', verifyAccts);

      message += '\n';
      message += pob.outputCounter('Leads with new Status', newStatusLeads);
      message += pob.outputCounter('Prospect-Clients with new Status', newStatusAccts);
      
      message += '\n';
      message += pob.outputCounter('Leads Expired', expiredLeads);
      message += pob.outputCounter('Prospect-Clients Expired', expiredAccts);

      message += '\n\nNumber of Prospect-Client Team members created='+teamMembersCreated;
      message += '\nNumber of Prospect-Client Team members deleted='+teamMembersCreated;

      message += '\n\nNumber of Prospect-Clients updated='+acctsUpdated;
      message += '\nNumber of Leads updated='+leadsUpdated;

      message += '\n'+batchMsg;
      
      //ChangeLog.logs = changeLogs;
      /*
      Attachment attach = ChangeLog.getAttachment('ProspectOwnerVerify');
      if (attach != null) {
         Attachment[] attachments = new Attachment[]{attach};
         jh.addAttachmentsToJob(attachments);
         message += '\n See Attachment for additional Information';
      }
      */   
      jh.completeJob(bc, 'Prospect Owner Verify', message);
   
   } // finish
   
} // class ProspectOwnerVerify