/* 
 * Methods for manipulating Referral data
 *
 * History
 * -------
   08/21/2012 Dan Carmen        Created
   01/25/2013 Cindy Freeman     Modified for FA referral process
   05/06/2013 Cindy Freeman     Modified so all sales reps can submit referral from referral contact
                                Also uses Started_From  to make decisions, not just NoRefOptyNeeded
   07/31/2013 Cindy Freeman     Modified to pull call type from task record created by webFAEmailService if
                                referral is coming from a referral contact.  Also set selling opty.zip-Tier__c = Large_Market
                                is referral stated from referral contact and is HRS opty
   06/11/2014 Cindy Freeman     Added chatterPostIt method to notify reps, DSA, DSMs about NSS Tip or NSS appt
   09/12/2014 J Stouffer        Updated chatterPostIt to include more information about the opportunity and P-C.
   11/05/2015 Dan Carmen        Modified chatter methods.
   12/30/2015 Cindy Freeman     Added method to save Referral reject reason.
   01/26/2016 Dan Carmen        Check disposition for commissions
   02/23/2016 Cindy Freeman     Added ErrorLog.checkSave to getSaveMsg method because I think we are losing errors.
   02/29/2016 Cindy Freeman     changed createOpp to use opty rcd type to determine firstStage instead of opty.owner
   06/28/2016 Dan Carmen        Fix for Activity Date/Time in chatter message
   10/03/2016 Justin Stouffer   Added DM and Multiple Locs for NSS Case 21556666
   12/14/2016 Cindy Freeman     modified to link Marketing Call Tracking record (if there is one with keywords) to Selling opportunity
   04/21/2017 Jacob Hinds       Added Owner Sync method
   04/24/2017 Jacob Hinds       Adding RR Prep Method
   05/25/2017 Jacob Hinds       Fixing syncRelatedOwners
   05/30/2017 Jacob Hinds       Adding check for user assignment in syncRelatedOwners
   06/12/2017 Dan Carmen        Add additional fields for notifies.
   06/22/2017 Lynn Michels      Change the default stage for Selling Opportunities Case 24790247
   06/26/2017 Jacob Hinds       Small change to checkChatterMessage + buildChatterMessage
   07/10/2017 Carrie Marciano   Changes for Integrated Selling to push the Referral upto the Referral Join for reporting purposes
   08/07/2017 Jacob Hinds       Small change to check if referral owner was a queue, used in chatter post in processSellingOpps
   09/09/2017 Cindy Freeman     let user set Frequency on opportunities
   10/11/2017 Cindy Freeman     change checkSyncRelatedOwners to really be future, changed updates to use DMLHelper.performDML2 to catch errors
   10/13/2017 Cindy Freeman     removed @future from checkSyncRelatedOwners, it was too confusing for users
   11/06/2017 Dan Carmen        Added logic for checking for duplicate opportunities. If one is found, use that one instead of creating a new one.
   02/16/2018 Lynn Michels      store employee count on Referral when Selling Opportunity is created.
   04/03/2018 Cindy Freeman     added limit to Reject_reason__c   
   06/26/2018 Jake Hinds        Changing condition to only include relevant dsm for chatter post
   07/12/2018 Dan Carmen        Change call for setting the Opportunity Type
   07/19/2018 Dan Carmen        Changes for adding additional message to chatter for opps that need "approval"
   09/13/2018 Dan Carmen        Add in logic for NotifyOwnerMsg__c
   10/10/2018 Dan Carmen        Add additional logging
   10/12/2018 Dan Carmen        Duplicate Opportunity handling
   10/31/2018 Dan Carmen        Change for NSS Source
   12/26/2018 Dan Carmen        Added a check for converted leads on 
   03/14/2019 Dan Carmen        Added retry ability for saving the selling opportunity
   03/19/2019 Dan Carmen        Removed check for Referring_Employee__c against prospect ownership.
   07/29/2019 Dan Carmen        Change save routine for Referral Join to check for errors.
   10/16/2018 Carrie Marciano   Added check to make sure we have a referralId before putting referral into map for manageTransferTrackingAfter
   01/08/2019 Dan Carmen        Change to getNSSSource
   01/23/2020 Dan Carmen        Force code to enter DG_DFR_Controller code.
   04/13/2020 Jake Hinds        commenting out refLinked.Referral_Type__c == 'Integrated Selling')
   05/07/2020 Jake Hinds        Adding in MMS SDR Opp Team Access Level on selling opp creation
   06/03/2020 Matthew Fritschi  New message for Amplifinity Referrals
   08/20/2020 Brandon Vidro     Link Business Profile on Opportunity Creation Case 36995025
   09/11/2020 Manmeet Vaseer    Added Process Notes after creating Event and Task. 
   02/12/2021 Manmeet Vaseer      APR0114125 - New Process: NSS to Identify Channel Lead Source (US1-US3)
                                  Requirements: https://wiki.paychex.com/display/CP/APR0114125+-+New+Process%3A+NSS+to+Identify+Channel+Lead+Source
   03/07/2021 Brandon Vidro     Change to checkChatterMessage for PRN
   03/23/2021 Brandon Vidro     Added logic in synRelatedOwner to set Lead owner when Ref owner is 'Drift Chat' queue
   04/16/2021 Dan Carmen        Update debugs
   05/20/2021 josh cartwright   updated checkOpportunityType to pass acct in /set RT to PEO if opp type is PEO and has PEO Potential on acct 
   05/18/2021 Carrie Marciano   Changed to use OppStage Labels   
   06/08/2021 Eric Porter       Consolidated CreateEvent and CreateTask into createActivity method, added CreateChatterPost method
   10/07/2021 Dan Carmen        Added code to default the Service Location
   02/10/2022 Dan Carmen        Use the Sales Org field on the Referral Partner for Prospect Ownership
   03/02/2022 Dan Carmen        APR0131613 Try to set the Pricebook for the opps
   05/20/2022 Dan Carmen        Change to how the NSS Source could be set on the Opp
   06/01/2022 Pujitha Madamanchi APR0122251 GL Case creation on Lead Conversion. 
   01/30/2023 Pujitha Madamanchi APR0145054 : Populate Marketing Source based on Lastest Campaign else, NSS Source
   04/05/2023 Pujitha Madamanchi Fix for Too many SOQL (Fetch MCT only when needed)
   08/17/2023 Dan Carmen         Commented out updateDSAOpptyRefJoin because it was updating too many records and hitting SOQL limits
   08/28/2023 Jaipal             Changed the parameters for getReferralFromLeadSource method to one parameter to pass in the sales org
   10/11/2023 Pujitha Madamanchi Populate NoofEmployees based on Lead else Account. 
   10/25/2023 Dan Carmen         Update updateDSAOpptyRefJoin method
   11/27/2023 Dan Carmen         Added more logging
   12/11/2023 Dan Carmen         Changed logic for Business_Profile__c to use the acct query

*/
public without sharing class ReferralMethods {

   // callout is so a "sleep" can be performed later
   @future(callout=true)
   public static void handleApprovedFuture(Id[] refIds) {
      handleApproved(refIds);
   } // handleApprovedFuture

   // Handle the approved referral records.
   public static void handleApproved(Id[] refIds) {
    
    Referral__c firstRef = null;
    
    // surround with try/catch to handle any other unhandled exceptions
    try {
         // if a referral is approved, create the selling opportunity if it doesn't already exist
         // or if referral is from wholesaler, no approval process, calling this from ReferralController.saveReferrals
         Referral__c[] refs = retrieveReferrals(refIds);
         System.debug('handleApproved refIds='+refIds.size()+' refs='+refs.size());
         if (!refs.isEmpty()) {
            firstRef = refs[0];
         }
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'handleApproved refs='+refs.size()));
      
    
         // gather tasks for referral contacts
         Map<Id, Task> refCtTskMap = retrieveTasks(refs);                               
         //CMF
         // if there are join records, retrieve all of them
         Map<Id, ReferralJoin__c> refJoinMap = retrieveJoins(refs);
      
         ReferralJoin__c[] refJoinToUpdate = new ReferralJoin__c[]{};
         system.debug('*** CLM *** before For Loop');
         for(ReferralJoin__c refJoin : refJoinMap.values()){
            for(Referral__c refLinked : refJoin.Referrals__r){
                //if(refLinked.Referral_Type__c == 'Integrated Selling'){
                    if(refLinked.Referral_Partner__r.Name == 'PAY'){
                        refJoin.Core_Referral__c = refLinked.Id;
                        system.debug('*** CLM *** set Core Referral ' + refLinked.Referral_Partner__r.Name);
                    }else if(refLinked.Referral_Partner__r.Name == 'MMS'){
                        refJoin.MMS_Referral__c = refLinked.Id;
                        system.debug('*** CLM *** set MMS Referral ' + refLinked.Referral_Partner__r.Name);
                    }else if(refLinked.Referral_Partner__r.Name == 'PAS'){
                        refJoin.PAS_Referral__c = refLinked.Id; 
                        system.debug('*** CLM *** set PAS Referral ' + refLinked.Referral_Partner__r.Name);
                    }
                //}
            }   
            refJoinToUpdate.add(refJoin);
         }   
         
         system.debug('*** CLM *** before update Referral Joins');
         if (!refJoinToUpdate.isEmpty()) {
            //Database.update(refJoinToUpdate,false);
            DmlHelper.performDML2(refJoinToUpdate, DmlHelper.DML_UPDATE, 'ReferralMethods', 'handleApproved', 'Updating Referral Joins', true);
         }
         system.debug('*** CLM *** after update Referral Joins');

         // make sure there are records to process
         if (!refs.isEmpty()) {                    
            processSellingOpps(refs, refCtTskMap, refJoinMap);
         } // if (!refs.isEmpty
    } catch (Exception e) {
         ErrorLog.logError('ReferralMethods', 'handleApproved', 'handleApproved', (refIds != null && !refIds.isEmpty() ? refIds[0] : null), e, firstRef);
         ErrorLog.checkSave();
    }
   } // handleApproved
   
   public static Boolean ALLOW_SLEEP_FOR_RETRY=(Label.ReferralMethods_AllowSleepForRetry == 'Y');
   
   /** Create the selling opportunities.
    */
   public static void processSellingOpps(Referral__c[] refs, Map<Id, Task> refCtTskMap, Map<Id, ReferralJoin__c> refJoinMap) {
      System.debug('processSellingOpps refs='+refs.size());
      // map of source contact id and selling opty ids, used to link Market Call Tracking rcd to opty CMFCMF
      Map<Id, Id> optyCtCtMap = new Map<Id, Id>();
      // the referral wrappers - to keep Opportunity with the Referral record
      ReferralWrapper[] wrappers = new ReferralWrapper[]{};
      // the opportunities to insert
      Opportunity[] oppsToInsert = new Opportunity[]{};
      // opportunities to update
      Opportunity[] oppsToUpdate = new Opportunity[]{};
      
      // get the ids of the line items
      Id[] oliIds = new Id[]{};
      // call type from FAEmailSvc task if referral has a referral contact
      String tskCallType = '';                                                      //CMF
      // any chatter posts we're going to send in this process
      ChatterWrapper[] chatterPosts = new ChatterWrapper[]{};

      // does this have any NSS records?
      Boolean hasNSS = false;
      
      ProspectOwnershipMethods.initializeSaveObjects();
      
      Set<Id> acctIdSet = new Set<Id>();
      // get the opportunity ids
      Id[] opptyIds = new Id[]{};

      // store the opp ids for chatter post    
      Set<Id> theOppIdsSet = new Set<Id>();

      //used to query MCT's
      Referral__c[] mctRefs = new Referral__c[]{};

      // the referral records we will be updating
      Referral__c[] updateRefs = new Referral__c[]{}; 
      for(Referral__c ref : refs){
         if(ref.Referral_Partner__r.Case_RecordTypeId__c!=null){
            mctRefs.add(ref);
         }
      }

      Map<Id,Marketing_Call_Tracking__c> mctMap = new Map<Id,Marketing_Call_Tracking__c>();
      //retrieve MCT if gl case needs to be created
      if(!mctRefs.isEmpty()){
         mctMap = retrieveMCTs(mctRefs);
      }
      Case[] caseToInsert = new Case[]{};
      for (Referral__c ref : refs) {
         if(ref.Referral_Partner__r.Case_RecordTypeId__c!=null && !mctMap.isEmpty()){
            // create case
            Case glCase = createCase(ref, mctMap);
            if(glCase!=null){
               ReferralWrapper rw = new ReferralWrapper();
               rw.ref = ref;
               rw.glCase = glCase;
               wrappers.add(rw);
               caseToInsert.add(glCase);
            }  
         }
         else{
            if (ref.ReferringLineItemId__c != null) {
               oliIds.add((Id)ref.ReferringLineItemId__c);
            }
            if (ref.Started_From__c =='Referral_Contact__c'){
               System.debug('processSellingOpps **SHOW IF ITS A REFERRAL CONTACT**');
               ReferralWrapper rw = new ReferralWrapper();
               rw.ref = ref;
               wrappers.add(rw);
               System.debug('We\'ve added the referral wrapper to wrappers');
               hasNSS = true;
            }
         
            if (ref.Account__c == null) {
               System.debug('processSellingOpps Could not Create Opportunity - no Account found!');
               StringHelper.addToProcessNotes(ref,'Could not Create Opportunity - no Account found!');
               if(ref.Started_From__c!='Referral_Contact__c'){
                  ref.Status__c = 'Account Not Found';
               }
               updateRefs.add(ref);
            } else if (ref.Account__c != null && ref.Selling_Opportunity__c == null) {
               acctIdSet.add(ref.Account__c);

               if (refCtTskMap.get(ref.Referral_Contact__c)!= null)                
               {   Task tsk = refCtTskMap.get(ref.Referral_Contact__c);            
                  tskCallType = tsk.Lead_Source_WAR_Call_Type__c;                 
               }                                                                   
                     
               ReferralJoin__c refJoin = (ref.ReferralJoin__c != null ? refJoinMap.get(ref.ReferralJoin__c) : null);
               
                  
               Opportunity opp = createOpp(ref, tskCallType, refJoin, oppsToUpdate, chatterPosts);
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'processSellingOpps opp='+opp));
               StringHelper.addToProcessNotes(ref,'returned from createOpp have opp='+(opp != null));
               
               System.debug('processSellingOpps opp returned from createOpp='+(opp != null));            
               if (opp != null) {
                  ReferralWrapper rw = new ReferralWrapper();
                  rw.ref = ref;
                  rw.oppSelling = opp;
                  wrappers.add(rw);
                  if (opp.Id == null) {
                     System.debug('processSellingOpps new Opp');
                     StringHelper.addToProcessNotes(ref,'Creating new opp');
                     StringHelper.addToProcessNotes(opp,'Created new opp');

                     // APR0114125 - If a user has manually populated the Referral Contact, & Client Referral values in the Form then 
                     // update these value in Oppty.
                     opp.Referral_Contact__c = ref.Referral_Contact__c;
                     opp.Referral_Account__c = ref.Referral_Account__c;
                     opp.Client_Referral__c = ref.Client_Referral__c;
                     if(ref.Referral_Partner__r.Generate_Lead_Id__c)   {
                        if(ref.PartnerReferral__r != null) opp.Bank_Lead_ID__c = ref.PartnerReferral__r.Name + 'p';
                     }
                        
                     oppsToInsert.add(opp);
                  } else {
                     System.debug('processSellingOpps using an existing Opp');
                     opptyIds.add(opp.Id);
                     rw.sellingOppWasExisting = true;
                     StringHelper.addToProcessNotes(ref,'Using an existing opp');
                  }
                  if (ref.Referral_Partner__r.SetProspectOwnership__c) {
                     hasNSS = true;
                  }
               } // if (opp != null
            } // if (ref.Selling_Opportunity__c
         }
      } // for (Referral__c ref
    
      System.debug('processSellingOpps oppsToInsert='+oppsToInsert.size()+' oppsToUpdate='+oppsToUpdate.size());
      
      if (!oppsToInsert.isEmpty()) {        
         Database.Saveresult[] results = Database.insert(oppsToInsert,false);
         ErrorLog__c errLog = null;
         // if any error, we want to retry them
         Opportunity[] errorOpps = new Opportunity[]{};
         //ErrorLog.logError(ReferralMethods', 'processSellingOpps', (rw.ref != null ? rw.ref.Referral_Partner__r.Partner_Type__c+' ' : '')+'saving the Opportunity', null, null, (SObject)null, false);
         
         for (Integer cnt=0; cnt<results.size(); cnt++) {
            Database.Saveresult sr = results[cnt];
            ReferralWrapper rw = wrappers[cnt];
            // get the id on a successful save
            if (sr.isSuccess()) {
               opptyIds.add(sr.getId());
               theOppIdsSet.add(sr.getId());
               if (rw != null) {
                  StringHelper.addToProcessNotes(rw.ref,'Opp saved successfully');
               }
            } else {

               if (errLog == null) {
                  // only create on error
                  errLog = ErrorLog.logError('ReferralMethods', 'processSellingOpps', (rw.ref != null ? rw.ref.Referral_Partner__r.Partner_Type__c+' ' : '')+'saving the Opportunity', (String)null, (Exception)null, rw.oppSelling, false);
                  errLog.ObjectAPIName__c = ObjectHelper.OBJECT_OPPTY;
                  errLog.DMLType__c = DmlHelper.DML_INSERT;
               } // if (errLog == null
               if (rw != null && rw.oppSelling != null) {
                  errorOpps.add(rw.oppSelling);
               }
            }
            String msg = getSaveMsg('Opportunity',sr.isSuccess(), rw.sellingOppWasExisting,sr.getErrors(), 'ReferralMethods', 'processSellingOpps', (rw.ref != null ? rw.ref.Referral_Partner__r.Partner_Type__c+' ' : '')+'saving the Opportunity', rw.ref.Id, errLog);
            
            rw.addToReferralNotes(msg);
            if (errLog != null) {
               ErrorLog.addToDescription(errLog,msg);
            }
            //rw.ref.ReferralNotes__c = (String.isBlank(rw.ref.ReferralNotes__c) ? '' : rw.ref.ReferralNotes__c+'\n ') + msg;
            System.debug('processSellingOpps msg='+msg);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveResults msg='+msg));
         } // for (Integer cnt=0
         
         if (errLog != null) {
            ErrorLog.saveErrorLog(errLog);
            if (!errorOpps.isEmpty() && DmlHelperRetry.canWeRetry(errLog)) {
               DmlHelperRetry dhr = new DmlHelperRetry(errLog, errorOpps);
               // only allow the delay in an asynchronous context
               dhr.processRetry(System.isFuture() && ALLOW_SLEEP_FOR_RETRY);
            }
         } // if (errLog != null)
      } // if (!oppsToInsert
        
      // the opportunity contact roles we are creating.
      OpportunityContactRole[] ocrs = new OpportunityContactRole[]{};
      // the opportunity team members to add referring user on selling opty team
      OpportunityTeamMember[] otms = new OpportunityTeamMember[]{};

      /**BAU Changes**/
      List<AccountTeamMember> lstAccountTeamMember=new List<AccountTeamMember>();
      Map<Id,Id> mapSalesparentidUserid=new Map<Id,Id>();
      Map<Id,Id> mapOpportunityidAccountid=new Map<Id,Id>();
      /**BAU Changes**/
           
      // retrieve all of the open ownership records.
      Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(acctIdSet, true, null, null);
     // System.debug('processSellingOpps acctOwnerMap='+acctOwnerMap.size());
    
      // reselect the accounts - to get the extra values for accounts used by the NSS processes.
      Id[] acctIdList = new Id[]{};
      acctIdList.addAll(acctIdSet);
      Map<Id,Account> acctMap = (hasNSS ? ReferralQueries.selectAcctMap(acctIdList) : new Map<Id,Account>());
      System.debug('processSellingOpps acctMap='+acctMap.size());
       
      //Business_Profile__c[] bps = new Business_Profile__c[]{};    
      //bps = [Select Id, Name, CreatedDate, Type__c from Business_Profile__c where Type__c = 'SDR' AND Prospect_Client__c IN :acctIdList Order By CreatedDate DESC Limit 1];
      Map<Id,Business_Profile__c> updateBps = new Map<Id,Business_Profile__c>();
      // The prospect ownership records for NSS records - use a map accouselectAcctMapntid-nss team to prevent duplicates
      //Map<String,Prospect_Ownership__c> upsertPosMap = new Map<String,Prospect_Ownership__c>();
      //Prospect_Ownership__c[] upsertPos = new Prospect_Ownership__c[]{};
    
      // list of ownership records grouped by account id
      //Map<Id,List<Prospect_Ownership__c>> savePoListMap = new Map<Id,List<Prospect_Ownership__c>>();
    
      // the activities we are going to create
      Task[] tasksToInsert = new Task[]{};
      Event[] eventsToInsert = new Event[]{};
      
      // select the opportunity team members - so if know if one was already added.
      Map<Id,List<OpportunityTeamMember>> teamMemberMap = OpptyMethods.getTeamMembersByOpptyIdMap(opptyIds);
    
      // we will create 1 ownership record for each distinct ownership team found. We'll keep track here to not duplicate work. 
      Set<String> nssTeamsAlreadyFound = new Set<String>();
      
      Referral__c firstRef = null;
      
      OpptyLog__c[] opptyLogs = new OpptyLog__c[]{};
      //Map<Id,Opportunity> theOppMap = new Map<Id,Opportunity>();
      //for(Opportunity theOpp : [Select Id, StageName,ReferralLookup__c, Referral_Partner_Stage__c,OwnerId from Opportunity where ID IN : theOppIdsSet]) {
      //    theOppMap.put(theOpp.Id,theOpp);
      //}
      System.debug('processSellingOpps wrappers='+wrappers.size());      
      for (ReferralWrapper rw : wrappers) {
          Account acct = acctMap.get(rw.ref.Account__c);
          System.debug('processSellingOpps selling is not null = '+(rw.oppSelling != null)+' has id='+(rw.oppSelling != null && rw.oppSelling.Id != null));
          //code to handle referralContacts situation
          if(rw.ref.Started_From__c =='Referral_Contact__c'){
            System.debug('Made it to Create Activity with no Opportunity');
            Boolean ownerIsQueue = ((String)rw.ref.OwnerId).startsWith(ObjectHelper.PREFIX_GROUP);
            System.debug('Referral Contact Path:Begin createActivity');  
            String actCallType = Label.Call_Type_NSS;
            String actSource='Referral-'+rw.ref.Referral_Partner__r.Partner_Type__c;
            createActivity(rw,tasksToInsert,eventsToInsert,actCallType,actSource);
            System.debug('Referral Contact Path: Begin createChatterPost');  
            createChatterPost(rw,hasNSS,chatterPosts);
            
            }
            
            //Modify CreateEvent method to handle no Opportunity
            // modify event handlers to send chatter Posts  when the owner changes.
                
         // make sure the records exists and was saved
         if (rw.oppSelling != null && rw.oppSelling.Id != null) {
            System.debug('processSellingOpps Setting the Selling Opportunity Id');
            rw.ref.Selling_Opportunity__c = rw.oppSelling.Id;
            rw.ref.Original_Employee_Count__c = rw.oppSelling.Employees_Paid_Per_Payroll__c;
            System.debug('processSellingOpps  rw.ref.Original_Employee_Count__c:'+ rw.ref.Original_Employee_Count__c);
            System.debug('processSellingOpps rw.oppSelling.Employees_Paid_Per_Payroll__c:'+rw.oppSelling.Employees_Paid_Per_Payroll__c);
            updateRefs.add(rw.ref);
            
            if (firstRef == null) {
               firstRef = rw.ref;
            }
             
            // if the selling opp was pre-existing, we don't need to do this
            if (!rw.sellingOppWasExisting) {
               // create the opportunity contact
               OpportunityContactRole ocr = createOppContact(rw.ref.Selling_Opportunity__c, rw.ref.SourceContact__c);
               if (ocr != null) {
                  ocrs.add(ocr);
               }
            }

            if (acct != null && !acct.Business_Profiles__r.isEmpty()) {
               Business_Profile__c bp = acct.Business_Profiles__r[0];
               bp.Opportunity_Name__c = rw.ref.Selling_Opportunity__c;
               updateBps.put(bp.Id, bp);
            }
             
            // change to NSR for an NSS rep
            String teamMemberRole = 'Internal Referral';
            String nssSource = null;
            String nssTeam = null;
            String actSource='Referral-'+rw.ref.Referral_Partner__r.Partner_Type__c;
            String actCallType = null;

            // we will not check prospect-ownership if it's an existing opportunity at this time
            // Set prospect ownership based off a field from the referral partner (rather than the type)
            /**BAU Changes**/
            if (!rw.sellingOppWasExisting && rw.ref.Referring_User__r != null && rw.ref.Referral_Partner__r.SetProspectOwnership__c) { //Partner_Type__c == ReferralController.REF_NSS) {
               if(rw.ref.Referring_User__r.UserRole.Name=='Oasis SDR' && rw.ref.Referring_User__r.Profile.Name=='Oasis Outbound Rep'){
                  teamMemberRole='Oasis SDR';
               }
               else{
                  teamMemberRole = OpptyMethods.ROLE_NSR;
               }
               /**BAU Changes**/
               nssSource = getNSSSource(rw.ref);
               String defValue = null;
               if (rw.ref.Referring_User__r != null && String.isNotBlank(rw.ref.Referring_User__r.NSS_Team__c)) {
                  defValue = rw.ref.Referring_User__r.NSS_Team__c;
               }
               String nssTeamCheck = (String.isNotBlank(rw.ref.Referral_Partner__r.Sales_Org__c) ? rw.ref.Referral_Partner__r.Sales_Org__c : rw.ref.Referral_Partner__r.Name);
               String[] nssTeams = ProspectOwnershipMethods.getNSSTeams(null, null, nssTeamCheck, null,defValue, rw.ref.Account__r.NumberOfEmployees);
               nssTeam = nssTeams[0]; 
               System.debug('processSellingOpps nssSource='+nssSource+' nssTeam='+nssTeam);
               actCallType = Label.Call_Type_NSS;
               //nssTeam = ProspectOwnershipMethods.getOwnershipType(rw.ref.Referral_Partner__r.Name);
               //checkOwnership(rw, nssTeam, nssSource, upsertPosMap, acctOwnerMap.get(rw.ref.Account__c),acctMap.get(rw.ref.Account__c)/*, savePoListMap*/);
               //checkOwnership(acctMap.get(rw.ref.Account__c), rw.ref.SourceContact__r, rw.ref.Referring_User__r, rw.ref.Selling_Opportunity__c, nssTeam, nssSource, acctOwnerMap.get(rw.ref.Account__c), upsertPosMap);
               
               // check that the acctOwnerMap has a value for the account
               List<Prospect_Ownership__c> ownerList = acctOwnerMap.get(rw.ref.Account__c);
               if (ownerList == null) {
                  ownerList = new List<Prospect_Ownership__c>();
                  acctOwnerMap.put(rw.ref.Account__c, ownerList);
               }
               
               rw.prospectOwnership = ((rw.ref.Account__c != null && acctMap.containsKey(rw.ref.Account__c)) ? ProspectOwnershipMethods.checkAccountOwnership(ProspectOwnershipMethods.STAGE_LOCKOUT, true, acctMap.get(rw.ref.Account__c), /*rw.ref.SourceContact__r*/null, rw.ref.SourceContact__c, null, rw.ref.Referring_User__r, rw.ref.Selling_Opportunity__c, nssTeam, nssSource, ownerList) : null);
               if (rw.prospectOwnership != null) {
                 /* Per Denise on 3/19 - we don't need to perform the referring employee check anymore. 
                    We will keep the referring user as the person who submitted the opp.
                if (rw.ref.Referring_User__c != rw.prospectOwnership.NSR_Name__c) {
                     rw.ref.Referring_User__c = rw.prospectOwnership.NSR_Name__c;
                     // get the contact info
                     ReferralController rc = new ReferralController(UserHelper.SO_CORE);
                     Map<Id,ReferralController.CtctUserWrap> ctctByUserIdMap = rc.getCtctIdByUserIdMap(new Set<Id>{rw.prospectOwnership.NSR_Name__c}); 
                     ReferralController.CtctUserWrap ctctWrap = ctctByUserIdMap.get(rw.prospectOwnership.NSR_Name__c);
                     if (ctctWrap != null && ctctWrap.ctct != null) {
                        rw.oppSelling.Referring_Employee__c=ctctWrap.ctct.Id;
                        oppsToUpdate.add(rw.oppSelling);
                        // get the org unit to get DSM/DSA
                        if (ctctWrap.usr != null) {
                            Org_Unit__c[] orgUnits = OrgUnitMethods.getOrgUnits(null, null, null, new User[]{ctctWrap.usr}, null);
                            if (!orgUnits.isEmpty()) {
                               Org_Unit__c dist = orgUnits[0];
                               if (dist.Assistant__c != null) {
                                  rw.ref.DSA__c = dist.Assistant__c;
                               } 
                               if (dist.Manager__c != null) {
                                  rw.ref.DSM__c = dist.Manager__c;
                               }
                            } // if (!orgUnits.isEmpty
                        } // if (ctctWrap.usr != null
                        
                     } // if (ctctWrap != null
                } // if (rw.ref.Referring_User__c
                */
               } else {
                  // prospect ownership wasn't set even though we'd normally expect it to be.
                  OpptyLog__c opptyLog = new OpptyLog__c(Opportunity__c=rw.oppSelling.Id, OwnershipNotSet__c=true);
                  opptyLog.Notes__c = ProspectOwnershipMethods.noPOReason;
                  opptyLogs.add(opptyLog);
            } // if (rw.prospectOwnership != null
               //checkOwnership(rw, upsertPosMap,acctOwnerMap.get(rw.ref.Account__c),acctMap.get(rw.ref.Account__c));
            }



            // make sure they're not already a team member.
            // do not need to check if existing opportunity
            if (!rw.sellingOppWasExisting && rw.ref.Referring_User__c != null && !doesTeamMemberExist(rw.ref.Referring_User__c,teamMemberMap.get(rw.oppSelling.Id))) {
          
               // create selling opty team member of referring rep
               rw.otm = new OpportunityTeamMember(OpportunityId=rw.oppSelling.Id,UserId=rw.ref.Referring_User__c,TeamMemberRole=teamMemberRole);
               rw.otm.NSS_Source__c=nssSource;
               rw.otm.NSS_Team__c=nssTeam;
               if(rw.ref.Referral_Type__c == 'MMS SDR'){
                  rw.otm.OpportunityAccessLevel='Edit';     
               }
               otms.add(rw.otm);
            } // if (

            /*********************BAU Changes************************* */
            if(rw.ref.Account__c!=null  &&  rw.ref.Referring_User__r != null &&rw.ref.Referring_User__r.UserRole.Name=='Oasis SDR' && rw.ref.Referring_User__r.Profile.Name=='Oasis Outbound Rep'){
               mapOpportunityidAccountid.put(rw.oppSelling.Id,rw.ref.Account__c);
            }

            //AccountTeamMember creation
            if(rw.ref.Account__c!=null && rw.ref.Referring_User__r != null &&rw.ref.Referring_User__r.UserRole.Name=='Oasis SDR' && rw.ref.Referring_User__r.Profile.Name=='Oasis Outbound Rep'){
               system.debug('Entering into AccountTeamMember');
               AccountTeamMember atm = new AccountTeamMember();
               if(rw.ref.Account__r.SalesParent__c!=null){
                   system.debug('Entering into AccountTeamMember'+rw.ref.Account__r.SalesParent__c);
                   mapSalesparentidUserid.put(rw.ref.Account__r.SalesParent__c,rw.ref.Referring_User__c);
                   atm = new AccountTeamMember();
                   atm.AccountId =rw.ref.Account__r.SalesParent__c;
               }
               else{
                   atm = new AccountTeamMember();
                   mapSalesparentidUserid.put(rw.ref.Account__c,rw.ref.Referring_User__c);
                   atm.AccountId =rw.ref.Account__c;
               }
               atm.TeamMemberRole = 'Oasis SDR';
               atm.UserId =rw.ref.Referring_User__c;
               atm.Opportunity_Team_Start_Date__c=Datetime.now();
               atm.AccountAccessLevel='Edit';
               atm.ContactAccessLevel='Edit';
               atm.OpportunityAccessLevel='Read';
               lstAccountTeamMember.add(atm);  
           }
            /********************BAU Changes**************************** */
          
            ChatterWrapper chatterPost = null;   

            // don't create a chatter message if the owner of the referral is a queue
            Boolean ownerIsQueue = ((String)rw.ref.OwnerId).startsWith(ObjectHelper.PREFIX_GROUP);
            system.debug('ownerwasQueue: '+rw.ref.Original_Owner_was_Queue__c); 
            System.debug('Original Create Chatter Post sequence');
            createChatterPost(rw,hasNSS,chatterPosts);

            // CMFCMF  if hasNSS gather rw.oppSelling.Id and rw.ref.SourceContact__c
            if (hasNSS)
            {   optyCtCtMap.put(rw.oppSelling.Id, rw.ref.SourceContact__c);     }
            
            //creates activity relevant to situation
            createActivity(rw,tasksToInsert,eventsToInsert,actCallType,actSource);

            system.debug('jsh chatterPost: '+chatterPost);
            if (chatterPost != null) {
               checkChatterMessage(rw, chatterPost, acctMap, chatterPosts, new Map<Id,Lead>());
            }
            //TODO checkChatterMessage happens everytime to validate if there are any messages **see below** 
            //** Will need to refactor checkChatterMessage to handle when there is no accountmap or ID/Lead map */
          
         } // if (rw.oppSelling != null
         
      } // for (ReferralWrapper
    
      /**BAU Changes**/
      //OTM creation--From AccountTeamMember view
      if(mapOpportunityidAccountid!=null && !mapOpportunityidAccountid.isEmpty()){
         List<OpportunityTeamMember> lstOTMs=OpptyMethods.CreateSDROppTeamMmembers(mapOpportunityidAccountid);
         if(lstOTMs!=null && !lstOTMs.isEmpty()){
            for(OpportunityTeamMember otm:lstOTMs){
               otms.add(otm);
            }
         }
      }
      //AccountTeamMember creation
      if(mapSalesparentidUserid!=null && !mapSalesparentidUserid.isEmpty()){
         system.debug('MACheck5');
         List<Account> lstChildAccount=[Select id,SalesParent__c from Account where SalesParent__c In:mapSalesparentidUserid.keyset()];
         if(lstChildAccount!=null && !lstChildAccount.isEmpty()){
            for(Account accChild:lstChildAccount){
               AccountTeamMember atm = new AccountTeamMember();
               atm.AccountId =accChild.id;
               atm.TeamMemberRole = 'Oasis SDR';
               atm.UserId =mapSalesparentidUserid.get(accChild.SalesParent__c);
               atm.Opportunity_Team_Start_Date__c=Datetime.now();
               atm.AccountAccessLevel='Edit';
               atm.ContactAccessLevel='Edit';
               atm.OpportunityAccessLevel='Read';
               lstAccountTeamMember.add(atm);

            }
         }
         
         
      }
      if(lstAccountTeamMember!=null && !lstAccountTeamMember.isEmpty()){
         system.debug('MACheck6 Entering into AccountTeamMember'+lstAccountTeamMember.size());
         //insert lstAccountTeamMember;
         try{
            DmlHelper.performDML2(lstAccountTeamMember, DmlHelper.DML_INSERT, 'ReferralMethods', 'processSellingOpps', 'Insert ATMs', false);
         }
         catch(Exception ex){
            system.debug('AccountTeamMember not inserted:'+ex);
         }
      }
       
      /**BAU Changes**/
      System.debug('processSellingOpps oppsToUpdate='+oppsToUpdate.size());
      DmlHelper.performDML2(oppsToUpdate, DmlHelper.DML_UPDATE, 'ReferralMethods', 'processSellingOpps', 'Updating Opportunities', false);

      DmlHelper.performDML2(opptyLogs, DmlHelper.DML_INSERT, 'ReferralMethods', 'processSellingOpps', 'insert opptyLogs', false);

      DmlHelper.performDML2(tasksToInsert, DmlHelper.DML_INSERT, 'ReferralMethods', 'processSellingOpps', 'Insert tasksToInsert', false);

      DmlHelper.performDML2(eventsToInsert, DmlHelper.DML_INSERT, 'ReferralMethods', 'processSellingOpps', 'Insert eventsToInsert', false);
    
      // post chatter posts (if any exist)
      System.debug('processSellingOpps chatterPosts='+chatterPosts.size());
      if (!chatterPosts.isEmpty()) {
         chatterPostIt(chatterPosts);
      }
      
      DmlHelper.performDML2(ocrs, DmlHelper.DML_INSERT, 'ReferralMethods', 'processSellingOpps', 'Insert ocrs', false);

      DmlHelper.performDML2(updateBps.values(), DmlHelper.DML_UPDATE, 'ReferralMethods', 'processSellingOpps', 'Update bps', false);
    
      //if (!upsertPosMap.isEmpty()) {
      //   Database.upsert(upsertPosMap.values(),false);
      //}
    
      updateOlis(oliIds,'Referral Approved');
    
      ProspectOwnershipMethods.checkForSaves();

      // set the Prospect_Ownership on the Opportunity Team Member (if available)
      for (ReferralWrapper rw : wrappers) {
         if (rw.otm != null && rw.prospectOwnership != null) {
            rw.otm.Prospect_Ownership__c = rw.prospectOwnership.Id;
         }
      } // for (ReferralWrapper
      
      DmlHelper.performDML2(otms, DmlHelper.DML_INSERT, 'ReferralMethods', 'processSellingOpps', 'Insert otms', false);
    
      // save the activity id for verification purposes
      for (ReferralWrapper rw : wrappers) {
        if (rw.otm != null) {
           rw.ref.TeamMemberId__c = rw.otm.Id;
        }
         if (rw.evt != null) {
            rw.ref.ActivityId__c = rw.evt.Id;
         } else if (rw.tsk != null) {
            rw.ref.ActivityId__c = rw.tsk.Id;
         }
      } // for (ReferralWrapper rw
      
      //if case is created
      if(!caseToInsert.isEmpty()){
         DmlHelper.performDML2(caseToInsert, DmlHelper.DML_INSERT, 'ReferralMethods', 'processSellingOpps', 'Create Cases', false);
      }
      for (ReferralWrapper rw : wrappers) {
         if(rw.glCase != null && rw.glCase.Id != null){
            rw.ref.Case__c = rw.glCase.Id;
            StringHelper.addToProcessNotes(rw.ref,'Add Referral to case'+rw.glCase.Id);
            updateRefs.add(rw.ref);
         }
      }

      System.debug('processSellingOpps updateRefs='+updateRefs.size());
      if (!updateRefs.isEmpty()) {
         ReferralTriggerActions.SKIP_TRIGGER = false;
         TriggerMethods.forceTriggerSet.add(DG_DFR_Controller.CLASS_NAME);
         // clear this so it doesn't loop through again.
         ReferralTriggerActions.refApprovedIds.clear();
         DmlHelper.performDML2(updateRefs, DmlHelper.DML_UPDATE, 'ReferralMethods', 'processSellingOpps', 'Updating the Referrals', false);
         TriggerMethods.forceTriggerSet.clear();
      }
    
      // CMFCMF call MTM and send opty and contact ids to link to update opty with latest keywords
      if (!optyCtCtMap.isEmpty())
      { MarketTrackingMethods.linkOpty(optyCtCtMap);    }
      
      ErrorLog.checkSave();
    
   } // processSellingOpps
   
   public static void checkChatterMessage(ReferralWrapper rw, ChatterWrapper chatterPost, Map<Id,Account> acctMap, ChatterWrapper[] chatterPosts, Map<Id,Lead> leadMap) {

      if (chatterPost == null || rw == null) {
         return;
      }
      chatterPost.isEvent = rw.ref.CreateSellerEvent__c;       
      // default to the value in NotifyOwnerMsg - this should usually be blank but if a special message is needed... 
      String msgAdd = (String.isNotBlank(rw.ref.NotifyOwnerMsg__c) ? rw.ref.NotifyOwnerMsg__c : '');
      if (String.isBlank(msgAdd)) {
         if (String.isNotBlank(rw.ref.Referral_Partner__r.Stage_Sales_Rep_needs_Approval__c)
              && rw.OppSelling.StageName == rw.ref.Referral_Partner__r.Stage_Sales_Rep_needs_Approval__c) {
            msgAdd = 'An opportunity has been referred to you. Please accept or disqualify the opportunity.\n';
         }
         String actType = ((rw.ref.Referral_Partner__r != null && rw.ref.Referral_Partner__r.Partner_Type__c=='Oasis') ? 'Oasis' : 'NSS');
         /*if(rw.ref.Amplifinity_Referral__c != null && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__c != null && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.Account__c != null
           && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.OwnerId != rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.Account__r.OwnerId
           && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.Account__r.Name != null && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__First_Name__c != null && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__Last_Name__c != null)
         {
             msgAdd += 'A new referral from ' + rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.Account__r.Name + '/' + rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__First_Name__c + ' ' + rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__Last_Name__c + ' has come in and has been sent to you and one of your internal selling partners. Please reach out to your partner to coordinate the first call.\n';
             //amplifinityChatter = true;
         }*/
         if(rw.ref.Amplifinity_Referral__c != null && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__c != null && rw.ref.Amplifinity_Referral__r.amp_dev__Lead__c != null
           && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.OwnerId != rw.ref.Amplifinity_Referral__r.amp_dev__Lead__r.OwnerId
            && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.Account__r != null && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__First_Name__c != null && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__Last_Name__c != null)
         {
             msgAdd += 'A new referral from ' + rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.Account__r.Name + '/' + rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__First_Name__c + ' ' + rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__Last_Name__c + ' has come in and has been sent to you and one of your internal selling partners. Please reach out to your partner to coordinate the first call.\n';
             //amplifinityChatter = true;
          }
          if(rw.ref.Amplifinity_Referral__c != null && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__c != null && rw.ref.Amplifinity_Referral__r.Contact__c != null
             && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.OwnerId != rw.ref.Amplifinity_Referral__r.Contact__r.OwnerId
             && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.Account__r != null && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__First_Name__c != null && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__Last_Name__c != null)
          {
             msgAdd += 'A new referral from ' + rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.Account__r.Name + '/' + rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__First_Name__c + ' ' + rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__Last_Name__c + ' has come in and has been sent to you and one of your internal selling partners. Please reach out to your partner to coordinate the first call.\n';
             //amplifinityChatter = true;
          }
         else if (chatterPost.isEvent) {
            if(rw.ref.Started_From__c =='Referral_Contact__c'){
               msgAdd += 'You have a new '+actType+' Appointment! Please see the Event for full details.\n';
            } else {
               msgAdd += 'You have a new '+actType+' Appointment! Please see the Opportunity for full details.\n';
            }
         } else if (rw.ref.CreateSellerTask__c) {
            if (UserHelper.isNSSInboundProf(rw.ref.Referring_User__r.Profile.Name)) {
               msgAdd += 'You have a new '+actType+' Inbound Lead. Please see the Opportunity for full details.\n';
            } else {
               msgAdd += 'You have a new '+actType+' Tip. Please see the Opportunity for full details.\n';
            }
         } else{
            msgAdd += 'This record has been assigned to you.\n';
         }
      } // if (String.isBlank(msgAdd))
      System.debug('posting the Chatter message');
      if(rw.ref.Amplifinity_Referral__c != null && rw.ref.Amplifinity_Referral__r.OwnerId != null && rw.ref.Amplifinity_Referral__r.OwnerId != Label.Amplifinity_API_User_Id)
      {
            chatterPost.addMentionId(rw.ref.Amplifinity_Referral__r.OwnerId);
            System.debug('Adding Amp Referral Owner to Chatter mention list');
      }
       
      if (String.isNotBlank(msgAdd)) {
         chatterPost.chatterMsg = buildChatterMessage(msgAdd, rw, acctMap, leadMap);
         chatterPosts.add(chatterPost);
      }
      
   } // checkChatterMessage
   
   public static void logError(String methodName, String codeKey, Referral__c ref, Exception e, SObject rec) {
      ErrorLog.logError('ReferralMethods', methodName, (ref != null ? ref.Referral_Partner__r.Partner_Type__c+' ' : '')+codeKey, (ref != null ? ref.Id : null), e, (rec != null ? rec : ref));
   } // logError
   
   public static string buildChatterMessage(String msgStart, ReferralWrapper rw ,Map<Id,Account> acctMap, Map<Id,Lead> leadMap){  
      string chatterMsg = msgStart;
      try {
         chatterMsg += '\n';
         if (rw.oppSelling != null && String.isNotBlank(rw.oppSelling.JointAppointmentReps__c)) {
            chatterMsg += '*** '+Label.Joint_Appt_Msg+' with '+rw.oppSelling.JointAppointmentReps__c+' ***\n\n';
         }
         //chatterMsg += 'Appointment Date: ' + (string.valueOf(rw.ref.ActivityDateTime__c)  != Null ? string.valueOf(rw.ref.ActivityDateTime__c.format('MM/dd/yyyy hh:mm a', rw.ref.user__r.TimeZoneSidKey)) : 'N/A')  + '\n';
         chatterMsg += (string.IsNotBlank(rw.ref.ActivityDateTimeFormatted__c) ? 'Appointment Date: ' + rw.ref.ActivityDateTimeFormatted__c + '\n' : '')  ;
         // get the standard info we want to put in chatter messages
         if (rw.ref.Account__c != null) {
            Account acct = acctMap.get(rw.ref.Account__c);
            Contact ctct = rw.ref.SourceContact__r;
            chatterMsg += ChatterMentionPost.buildChatterMessage(acct, ctct);
         } else if (rw.ref.SourceLead__c != null) {
            Lead ld = leadMap.get(rw.ref.SourceLead__c);
            chatterMsg += ChatterMentionPost.buildChatterMessage(ld);
         }
         
          if(!(rw.ref.Amplifinity_Referral__c != null && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__c != null && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.Account__c != null
           && rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.OwnerId != rw.ref.Amplifinity_Referral__r.amp_dev__Advocate__r.Account__r.OwnerId))
           {
               chatterMsg += (rw.ref.Referring_User__r.name != Null ? 'NSS Rep: ' + rw.ref.Referring_User__r.name + '\n' : '');
              if(rw.ref.Started_From__c=='Referral_Contact__c'){
               System.debug('buildChatterMessage rw.ref.Referral_Contact__r.Referral_Account__c='+rw.ref.Referral_Contact__r.Referral_Account__c);
               chatterMsg += (rw.ref.Referral_Contact__r.Name !=null ? 'Referral Contact: '+ rw.ref.Referral_Contact__r.Name+ '\n':'');
               chatterMsg += (rw.ref.Referral_Contact__r.Email__c !=null ? 'Referral Contact Email: '+ rw.ref.Referral_Contact__r.Email__c+ '\n':'');
               chatterMsg += (rw.ref.Referral_Contact__r.Number_of_Business_Clients__c !=null ? 'Referral Contact Number of Business Clients: '+ rw.ref.Referral_Contact__r.Number_of_Business_Clients__c+ '\n':'');
               chatterMsg += (rw.ref.Referral_Contact__r.Referral_Account__c !=null ? 'Referral Account Name: '+ rw.ref.Referral_Contact__r.Referral_Account__r.Name+ '\n':'');
            }
               
               
              }
         
         chatterMsg += '\n\n';
         
         if (String.IsNotBlank(rw.ref.AdditionalProductsOfInterest__c)) {
            String msg = Label.Product_Of_Interest_Chatter_Msg.replace('xxxx',rw.ref.AdditionalProductsOfInterest__c);
            chatterMsg += msg;
            chatterMsg += '\n\n';
         }
        } catch (Exception e) {
           // what do we need to do here?
        }
        return chatterMsg;
   } // buildChatterMessage
   
   // Is the passed in user id already a team member on the opportunity? There is a trigger that will create team members
   //    automatically so we want to make sure we don't try to insert them a second time. 
   public static Boolean doesTeamMemberExist(Id userId, List<OpportunityTeamMember> otms) {
      Boolean exists = false;
      if (otms != null && !otms.isEmpty()) {
         for (OpportunityTeamMember otm : otms) {
            if (otm.UserId == userId) {
               exists = true;
               break;
            }
         } // for (OpportunityTeamMember
      } // if (otms != null
      return exists;
   } // doesTeamMemberExist
   
   // Update the line items with the passed in values.
   public static Boolean updateOlis(Id[] oliIds, String newStatus) {
    if (!oliIds.isEmpty() && newStatus != null) {
       OpportunityLineItem[] olis = new OpportunityLineItem[]{};
       for (Id oliId : oliIds) {
          olis.add(new OpportunityLineItem(Id=oliId, Status__c=newStatus));
       }
       update olis;
    } // if (!oliIds.isEmpty
    return true;
   } // updateOlis
   
   public static String getSaveMsg(String prefix, Boolean isSuccess, Boolean reuseOpp, Database.Error[] errors, String className, String methodName, String codeKey, String objectId, ErrorLog__c errLog) {
      String msg = prefix;
      if (reuseOpp) {
         msg += ' Already Existed-Reused!';
      } else if (isSuccess) {
         msg += ' Successfully Saved!';
      } else {
         msg += ' Encountered an Error: ';
         for (Database.Error err : errors) {
            msg += err.getMessage();
         }
         if (errLog != null) {
            errLog.ObjectId__c = objectId;
            ErrorLog.addToDescription(errLog,msg);
            ErrorLog.checkErrorTypes(errLog,msg);
         }
         //if (String.isNotBlank(className)) {
         //   ErrorLog.logError(className, methodName, codeKey, objectId, msg);
         //   ErrorLog.checkSave();
         //}
      } // if
      System.debug('getSaveMsg msg='+msg);
      return msg;
   } // getSaveMsg

   public static Referral__c[] retrieveReferrals(Id[] refIds) {
      Referral__c[] refs = [Select Id, Name
                                ,Account__c
                                ,Account__r.Id
                                ,Account__r.Name
                                //,Account__r.Assigned_To_NSR__c
                                ,Account__r.AssignedToNSR__c
                                ,Account__r.AssignedToInboundNSR__c
                                ,Account__r.AssignedToOutboundNSR__c
                                ,Account__r.Frequency__c
                                ,Account__r.NumberOfEmployees
                                ,Account__r.BillingStreet
                                ,Account__r.BillingCity
                                ,Account__r.BillingState
                                ,Account__r.BillingPostalCode
                                ,Account__r.CSSR_Segment__c
                                ,Account__r.Hold_Out__c
                                ,Account__r.Hold_Out_Expiration__c
                                ,Account__r.OwnerId
                                ,Account__r.Permanent_Hold_Out_Description__c
                                ,Account__r.PEO_Potential_Indicator__c
                                ,Account__r.SegmentationCore1__c
                                ,Account__r.ShippingStreet
                                ,Account__r.ShippingCity
                                ,Account__r.ShippingState
                                ,Account__r.ShippingPostalCode
                                ,Account__r.Referral_National_Account__c
                                ,Account__r.Referral_National_Account__r.Id
                                ,Account__r.Referral_National_Account__r.Name
                                ,Account__r.TimeZoneAbbrev__c
                                ,ActivityDate__c
                                ,ActivityDateTime__c
                                ,ActivityDateTimeFormatted__c
                                ,Activity_Type__c
                                ,AdditionalProductsOfInterest__c
                                ,Amplifinity_Referral__c
                                ,Amplifinity_Referral__r.OwnerId
                                ,Amplifinity_Referral__r.amp_dev__Advocate__c
                                ,Amplifinity_Referral__r.amp_dev__Advocate__r.OwnerId
                                ,Amplifinity_Referral__r.amp_dev__Advocate__r.Name
                                ,Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__First_Name__c
                                ,Amplifinity_Referral__r.amp_dev__Advocate__r.amp_dev__Last_Name__c
                                ,Amplifinity_Referral__r.amp_dev__Advocate__r.Account__c
                                ,Amplifinity_Referral__r.amp_dev__Advocate__r.Account__r.OwnerId
                                ,Amplifinity_Referral__r.amp_dev__Advocate__r.Account__r.Name
                                ,Amplifinity_Referral__r.amp_dev__Lead__c
                                ,Amplifinity_Referral__r.amp_dev__Lead__r.OwnerId
                                ,Amplifinity_Referral__r.Contact__c
                                ,Amplifinity_Referral__r.Contact__r.OwnerId
                                ,Cadence_Touchpoint__c
                                ,Campaign__c
                                ,Client_Referral__c // APR0114125 - new field in Referral added
                                ,Contact__c
                                ,CreatedById
                                ,CreateSellerEvent__c
                                ,CreateSellerTask__c
                                ,DM__c
                                ,DSA__c
                                ,DSA__r.Name
                                ,DSA__r.Email
                                ,DSM__c
                                ,DSM__r.Id
                                ,DSM__r.Name
                                ,DSM__r.Email
                                ,Email__c
                                ,IsAncillary__c
                                ,Notes__c
                                ,NotifyOwner__c
                                ,NotifyOwnerMsg__c
                                ,Original_Owner_was_Queue__c
                                ,OwnerId
                                ,PartnerType__c
                                ,PartnerReferral__r.Id
                                ,PartnerReferral__r.Name    // APR0114125
                                ,PartnerReferral__r.Destination__c
                                ,Potential_for_Multiple_Locations__c
                                ,ProcessNotes__c
                                ,ProductReferred__c
                                ,ReferFromContact__c
                                ,ReferralNotes__c
                                ,Referral_Account__c  // APR0114125
                                ,Referral_Account__r.Name
                                ,Referral_Contact__c
                                ,Referral_Contact__r.Referral_Type__c
                                ,Referral_Contact__r.Name
                                ,Referral_Contact__r.Referral_Account__c
                                ,Referral_Contact__r.Referral_Account__r.Id
                                ,Referral_Contact__r.Referral_Account__r.Name
                                ,Referral_Contact__r.Referral_Account__r.Street_Address_1__c
                                ,Referral_Contact__r.Referral_Account__r.City__c
                                ,Referral_Contact__r.Referral_Account__r.State_Province__c
                                ,Referral_Contact__r.Referral_Account__r.Zip_Postal_Code__c
                                ,Referral_Contact__r.Phone__c
                                ,Referral_Contact__r.Mobile_Phone__c
                                ,Referral_Contact__r.Number_of_Business_Clients__c
                                ,Referral_Contact__r.Email__c
                                ,Referral_Partner__c
                                ,Referral_Partner__r.Name
                                ,Referral_Partner__r.CheckForDuplicates__c
                                ,Referral_Partner__r.Generate_Lead_Id__c    // APR0114125
                                ,Referral_Partner__r.NSS_Source__c
                                ,Referral_Partner__r.Selling_Opp_RecordTypeId__c
                                ,Referral_Partner__r.SellingOppIsReferral__c
                                ,Referral_Partner__r.SellingOpportunityType__c
                                ,Referral_Partner__r.Partner_Type__c
                                ,Referral_Partner__r.Sales_Org__c
                                ,Referral_Partner__r.ServiceLocation__c
                                ,Referral_Partner__r.SetProspectOwnership__c
                                ,Referral_Partner__r.Stage_Sales_Rep_needs_Approval__c
                                ,Referral_Partner__r.Case_RecordTypeId__c
                                ,ReferringLineItemId__c
                                ,Referral_Source__c
                                //,No_Referring_Opty_Needed__c
                                ,Started_From__c
                                ,ReferralJoin__c
                                ,Referral_Type__c
                                ,Referring_Opportunity__c
                                ,Referring_Opportunity__r.Id
                                ,Referring_Opportunity__r.CloseDate
                                ,Referring_Opportunity__r.Description
                                ,Referring_Opportunity__r.Employees_Paid_Per_Payroll__c
                                ,Referring_Opportunity__r.LeadSource
                                ,Referring_Opportunity__r.Frequency__c
                                ,Referring_User__c
                                ,Referring_User__r.Id
                                ,Referring_User__r.HR_Person_Id__c
                                ,Referring_User__r.ManagerId
                                ,Referring_User__r.Name
                                ,Referring_User__r.NSS_Team__c
                                ,Referring_User__r.Profile.Name
                                ,Referring_User__r.Sales_Division__c
                                ,Referring_User__r.Sales_Org__c
                                ,SecondaryLeadSource__c
                                ,SellingLeadSource__c
                                ,SellingOppInfo__c
                                ,Selling_Opportunity__c
                                ,Selling_Opportunity__r.Id
                                ,Selling_Opportunity__r.OwnerId
                                ,Selling_Opportunity__r.JointAppointmentReps__c
                                ,Selling_Opportunity__r.ProcessNotes__c
                                ,Selling_Opportunity__r.StageName
                                ,Send_Email__c
                                ,SetOwnerHoldout__c
                                ,SourceLead__c
                                ,SourceLead__r.Id
                                ,SourceLead__r.NumberOfEmployees //Vinay
                                ,SourceLead__r.OwnerId
                                ,SourceLead__r.IsConverted
                                ,SourceLead__r.Hold_Out__c
                                ,SourceLead__r.Hold_Out_Expiration__c
                                ,SourceLead__r.Hold_Out_Reason__c
                                ,SourceContact__c
                                ,SourceContact__r.Id
                                ,SourceContact__r.Name
                                ,SourceContact__r.Phone
                                ,SourceContact__r.MobilePhone
                                ,SourceContact__r.Email
                                ,SourceContact__r.Contact_Stage__c
                                ,SourceContact__r.Hold_Out__c
                                ,SourceContact__r.Hold_Out_Expiration__c
                                ,SourceContact__r.Hold_Out_Reason__c
                                ,SourceContact__r.LatestCampaign__c
                                ,SourceContact__r.LatestCampaign__r.LeadSource__c
                                ,SourceContact__r.LatestCampaign__r.DestinationNbrDays__c
                                ,SourceContact__r.LatestCampaign__r.OppNSSSource__c
                                ,SourceContact__r.LatestCampaignDate__c 
                                ,SourceContact__r.MailingStreet
                                ,SourceContact__r.MailingState
                                ,SourceContact__r.MailingPostalCode
                                ,SourceContact__r.MailingCity
                                ,SourceContact__r.OwnerId
                                ,SourceContact__r.Referral_Contact__c
                                ,SourceContact__r.Referral_Contact__r.Id
                                ,SourceContact__r.Referral_Contact__r.Name
                                ,SourceContact__r.Referral_Account__c
                                ,SourceContact__r.Referral_Account__r.Id
                                ,SourceContact__r.Referral_Account__r.Name
                                ,Status__c
                                ,TimeZoneAbbrev__c
                                ,User__c
                                ,User__r.Id
                                ,User__r.IsActive
                                ,User__r.Name
                                ,User__r.Profile.Name
                                ,User__r.PilotUser__c
                                ,User__r.Sales_Division__c
                                ,User__r.Sales_Org__c
                                ,User__r.DSA_FSS__c
                                ,User__r.DSA_FSS__r.Name
                                ,User__r.DSA_FSS__r.Email
                                ,User__r.DSA_FSS__r.IsActive
                                ,User__r.ManagerId
                                ,User__r.Manager.Name
                                ,User__r.Manager.Email
                                ,User__r.Manager.IsActive
                                ,User__r.NSS_Team__c
                                ,User__r.TimeZoneSidKey
                                ,ZipSegment__c,
                                Referring_User__r.UserRole.Name,
                                Account__r.SalesParent__c
                            From Referral__c
                           Where Id in :refIds];
    return refs;
   } // retrieveReferrals
   
   // if there are any join records retrieve them and all associated referrals so we can get a list of the sales reps.
   public static Map<Id, ReferralJoin__c> retrieveJoins(Referral__c[] refs) {
    Id[] refJoinIds = new Id[]{};
    for (Referral__c ref : refs) {
       if (ref.ReferralJoin__c != null) {
          refJoinIds.add(ref.ReferralJoin__c);
       }
    } // for (Referral__c ref
    
    Map<Id, ReferralJoin__c> refJoinMap = null;
    if (!refJoinIds.isEmpty()) {
       refJoinMap = new Map<Id, ReferralJoin__c>([select Id, Core_Referral__c
                                                        , MMS_Referral__c
                                                        , PAS_Referral__c
                                                        ,(Select Id, Name, Referral_Type__c
                                                                ,User__r.Id, User__r.Name 
                                                                ,Contact__r.Id, Contact__r.Name
                                                                ,Referral_Partner__r.Name
                                                            from Referrals__r)
                                                    From ReferralJoin__c
                                                   Where Id in :refJoinIds]);
    } else {
        refJoinMap = new Map<Id, ReferralJoin__c>();
    }
      
      return refJoinMap;
   } // retrieveJoins
   
   // gather referral contact activities that came from Web FA Email Service so can store on opty //CMF
   public static Map<Id, Task> retrieveTasks(Referral__c[] refs) {                              //CMF
      Map<Id, Task> tskMap = new Map<Id, Task>();
    
      Set<Id> refCtIds = new Set<Id>();
      // get the referral ids
      for (Referral__c r: refs)
      {   if (r.Started_From__c == ReferralController.REFERRAL_CONTACT && r.Referral_Contact__r.Id != null)
          {   refCtIds.add(r.Referral_Contact__r.Id); }
      }
      if (!refCtIds.isEmpty()) {
        for (Task[] tasks : [Select Id, WhatId, WhoId
                                            , Lead_Source_WAR_Call_Type__c, ActivityDate
                                            , Status, Activity_Source__c
                                            From Task
                                            Where Status = 'Referred'
                                            And Activity_Source__c = 'FAEmailSvc'
                                            And WhatId in :refCtIds
                                            order by ActivityDate desc]) {
            for (Task tsk : tasks) {
                // only keep one task for each referral contact
               if (!tskMap.containsKey(tsk.WhatId)) {
                  tskMap.put(tsk.WhatId, tsk);
               } // if (!tskMap
            } // for (Task tsk                                          
         } // for

      } // if (!refCtIds.isEmpty
      return tskMap;    
   } // retrieveTasks                                                                       //CMF
   
   private static UserHelper userH = new UserHelper();

   private static Map<String,CreateOppAndMeeting> coamMap = new Map<String,CreateOppAndMeeting>();
   
   public static CreateOppAndMeeting getCoam(String salesOrg, String salesDivision) {
    CreateOppAndMeeting coam = coamMap.get(salesOrg);
    if (coam == null) {
       coam = new CreateOppAndMeeting(salesOrg, salesDivision);
       coam.createOpportunity = true;
       coamMap.put(salesOrg,coam);
    } // if (coam == null
      return coam;
   } // getCoam

   public static Boolean CHECK_DUPES_UNDER_70 = Label.ReferralMethods_CheckDupeUnder70 == 'Y';
   public static String CLOSE_OPP_CHATTER = Label.OppDupe_ClosedOpp;
   public static String NOT_SOLD=Label.OppStage_Lost;

   public static Opportunity createOpp(Referral__c ref, String tskCallType, ReferralJoin__c refJoin, Opportunity[] oppsToUpdate, ChatterWrapper[] chatterPosts) {
      Opportunity opp = null;
      System.debug('createOpp recordtypeid='+ref.Referral_Partner__r.Selling_Opp_RecordTypeId__c+' hasUser='+(ref.User__r != null) +
             ' hasReferringUser='+(ref.Referring_User__r != null)+' hasOpp='+(ref.Referring_Opportunity__r != null) +
             ' hasReferralContact='+(ref.Referral_Contact__c != null));
             
      StringHelper.addToProcessNotes(ref,'createOpp recordtypeid='+ref.Referral_Partner__r.Selling_Opp_RecordTypeId__c+' user='+ref.User__c+' refJoin='+(refJoin != null ? String.valueOf(refJoin.Id) : 'null'));
             
      if (ref.Referral_Partner__r.Selling_Opp_RecordTypeId__c != null
           && ref.User__r != null  // the user the new opportunity is going to
           ) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'createOpp in if statement'));

         // was this referral created by an NSR?
         Boolean isNssReferral = (ref.Referral_Partner__r.Partner_Type__c == ReferralController.REF_NSS);          
          
         Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordTypeById(ref.Referral_Partner__r.Selling_Opp_RecordTypeId__c, 'Opportunity');
         String v_salesOrg = (rtInfo != null ? RecordTypeHelper.getSalesOrgForRecordTypeName(rtInfo.getName()) : ref.Referral_Partner__r.Name);
         
         //String v_salesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(RecordTypeHelper.getRecordTypeById(ref.Referral_Partner__r.Selling_Opp_RecordTypeId__c, 'Opportunity').getName());
         //CreateOppAndMeeting coam = getCoam(ref.User__r.Sales_Org__c);
         // default value when creating the opportunity
         ref.SellingOppInfo__c = Label.OppCreatedSuccessfully;
         CreateOppAndMeeting coam = getCoam(v_salesOrg,null);
      
         // TODO - look into creating the opp directly from the CreateOppAndMeeting class. When we try to do that right now
         // tests in other classes fail (like SOAREmailHandlerTest)
         opp = new Opportunity(RecordTypeId = ref.Referral_Partner__r.Selling_Opp_RecordTypeId__c, Amount=0);
               
         //opp.StageName = coam.getReferralOppFirstStageBySalesOrg(v_salesOrg);         
         opp.StageName = coam.refOppFirstStage;  
      //LM3/6       opp.ForecastCategoryName = coam.refOppForecast;
      //LM3/6       opp.Probability = coam.refOppProbability;       
         opp.Name = CreateOppAndMeeting.getOppName(ref.Account__r.Name,userH.getProdTranslation(ref.Referral_Partner__r.Name),CreateOppAndMeeting.OPP_NAME_SIZE, ref.IsAncillary__c);
         
         opp.CloseDate = coam.getCloseDate();
         opp.Level_2__c = ref.SecondaryLeadSource__c;     
         
         opp.OwnerId = ref.User__c;
         opp.AccountId = ref.Account__c;
         // a lookup back to the main referral
         opp.ReferralLookup__c = ref.Id;
         opp.ProductReferred__c = ref.ProductReferred__c;
         opp.DM__c = ref.DM__c;
         opp.Potential_for_Multiple_Locations__c = ref.Potential_for_Multiple_Locations__c;
         // default the Zip Tier field from the ZipSegment on the referral.
         opp.Zip_Tier__c = ref.ZipSegment__c;
         opp.Campaign__c = (ref.Campaign__c != null ? ref.Campaign__c : (ref.SourceContact__r != null ? ref.SourceContact__r.LatestCampaign__c : null));
         opp.OppSource__c = 'ReferralMethods';
         opp.AdditionalProductsOfInterest__c = ref.AdditionalProductsOfInterest__c;
         opp.Cadence_Touchpoint__c = ref.Cadence_Touchpoint__c;
         if (String.isNotBlank(ref.Referral_Partner__r.ServiceLocation__c)) {
            opp.Service_Location__c = ref.Referral_Partner__r.ServiceLocation__c;
         }
         Pricebook2 pricebook = ProductQuery.getPrimaryPricebook(ref.User__r,ref.User__r.Sales_Org__c,ref.User__r.Sales_Division__c);
         opp.Pricebook2Id = (pricebook != null ? pricebook.Id : null);
         StringHelper.addToProcessNotes(ref,'opp.Pricebook2Id='+opp.Pricebook2Id);

         // force this value to be set
         // do a further check of the field - set the type so we can check for duplicates
         if (ref.IsAncillary__c) {
            opp.OpportunityType__c = Label.OppType_Ancillary;
         } else {
            OpptyMethods.checkOpportunityType(opp, ref.Referral_Partner__r.SellingOpportunityType__c, ref.User__r, ref.Account__r); 
         }
         
         if(opp.OpportunityType__c=='PEO' && ref.Account__r.PEO_Potential_Indicator__c !=null){
            Schema.RecordTypeInfo rtInfoPEO = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity');                   
            opp.RecordTypeId = rtInfoPEO.getRecordTypeId();
         }//if
               
         
         System.debug('createOpp check for dupes='+ref.Referral_Partner__r.CheckForDuplicates__c);
         addToProcessNotes(ref,'check for dupes='+ref.Referral_Partner__r.CheckForDuplicates__c);
         if (ref.Referral_Partner__r.CheckForDuplicates__c) {
            // look for existing opportunities if it's not an internal referral
            // if existing opportunity, we don't set the rest of the opp fields.
            Opportunity matchedOpp = checkExistingOpps(opp, ref);
            if (matchedOpp != null && matchedOpp.Probability > 70) {
               System.debug('createOpp matched opp greater than 70');
               addToProcessNotes(ref,'Matched Opp greater than 70');
               opp = matchedOpp;
               ref.SellingOppInfo__c = Label.OppDupeReuse;
               // we shouldn't need to do the following because they're already in the sold stage
               //ref.NotifyOwnerMsg__c = Label.OppDupe_ReuseOver70Msg;
               //ref.NotifyOwner__c = true;
            } else if (CHECK_DUPES_UNDER_70 && matchedOpp != null && matchedOpp.Probability <= 70) {
               System.debug('createOpp matched opp less than or equal to 70');
               if (matchedOpp.OwnerId == opp.OwnerId) {
                  System.debug('createOpp same owner under 70 - reusing the opp');
                  addToProcessNotes(ref,'Matched Opp less than 70 owner is the same. Using Opp');
                  // set the new leadsource to be the value on the existing opp
                  matchedOpp.LeadSource = opp.LeadSource;
                  opp = matchedOpp;
                  ref.SellingOppInfo__c = Label.OppDupeReuseUnder70;
                  ref.NotifyOwnerMsg__c = Label.OppDupe_ReuseUnder70Msg;
                  ref.NotifyOwner__c = true;
                  // need to add campaign influence
               } else {
                  System.debug('createOpp different owner under 70 - checking the activity');
                  // check for activity in the past 90 days
                  Date checkDate = Date.today().addDays(-90);
                  if ((matchedOpp.LastActivityDate != null && matchedOpp.LastActivityDate >= checkDate)
                     // it only makes sense to check the activity on the opportunity
                     // || (matchedOpp.Account != null && matchedOpp.Account.LastActivityDate != null && matchedOpp.Account.LastActivityDate >= checkDate)
                      ) {
                     System.debug('createOpp different owner under 70 - has activity, reuse the existing opp');
                     // if within the past 90 days - do not create a new opp
                     // set the new leadsource to be the value on the existing opp
                     addToProcessNotes(ref,'Matched Opp less than 70 owner is different. Has activity within 90 Days');
                     matchedOpp.LeadSource = opp.LeadSource;
                     opp = matchedOpp;
                     ref.SellingOppInfo__c = Label.OppDupeReuseUnder70;
                     ref.NotifyOwnerMsg__c=Label.OppDupe_ReuseUnder70Msg;
                     ref.NotifyOwner__c = true;
                     // need to add campaign influence
                  } else {
                     System.debug('createOpp different owner under 70 - no activity - create a new opp, close the old one');
                     addToProcessNotes(ref,'Matched Opp less than 70 owner is different. No activity within 90 Days. Closing existing opp.');
                     // no activity - close existing opp - No Sale with a Reason Not Sold as 'Expired Oppty Due to No Activity'
                     // The original Opportunity owner of the Opportunity that is set as a No Sale is notified via chatter by stating chatter notification #2 below
                     // New Opportunity will be created based on normal rule evaluation
                     matchedOpp.StageName = NOT_SOLD;
                     matchedOpp.Reason_Not_Sold__c = Label.OppDupe_ClosedOppReason;
                     oppsToUpdate.add(matchedOpp);
                     // notify owner of opp we're closing
                     ChatterWrapper chatterPost = new ChatterWrapper();               
                     chatterPost.objectId = matchedOpp.Id;
                     chatterPost.addMentionId(matchedOpp.Owner.Id);
                     chatterPost.addMentionId(matchedOpp.Owner.ManagerId);
                     chatterPost.addMentionId(matchedOpp.Owner.DSA_FSS__c);
                     chatterPost.chatterMsg = CLOSE_OPP_CHATTER.replace('-REPNAME-',ref.User__r.Name);
                     chatterPosts.add(chatterPost);
                  }
               } // if (matchedOpp.OwnerId == opp.OwnerId
            } // if (matchedOpp != null
            /*
            Opportunity[] existingOpps = OpptyDupeCheck.dupeOpps(opp); 
            if (existingOpps != null && !existingOpps.isEmpty()) {
               // do we match up to the latest opp?
               Opportunity matchedOpp = existingOpps[0];
               System.debug('createOpp using existing opp');
               opp = matchedOpp;
               ref.SellingOppInfo__c = Label.OppDupeReuse;
            }
            */
         } // if (!ref.Referral_Partner__r.CheckForDuplicates__c
         
         
         setJointApptInfo(opp, ref,refJoin);
         //opp.JointAppointment__c = (String.isNotBlank(opp.JointAppointmentReps__c));
         
         // only set the following if we're creating the opp here (and not reusing an existing one)
         if (opp.Id == null) {
            setOpportunityFields(ref,opp,true);
                
            //opp.Referral_Contact__c = ref.Referral_Contact__c != null ? ref.Referral_Contact__c : null;
            if (ref.Referral_Contact__c != null)                                                   //CMF
            {  opp.Referral_Contact__c = ref.Referral_Contact__c;                                  //CMF
               opp.LeadSource_Detail__c = tskCallType;                                             //CMF
            }                                                                                      //CMF
            else                                                                                   //CMF
            {  opp.Referral_Contact__c = null;}                                                    //CMF
         
            // The description from the opportunity entered on the main screen
            String description;
            if (ref.Referring_Opportunity__r == null)
            {  description = '';   
               //opp.Employees_Paid_Per_Payroll__c = ref.Account__r.NumberOfEmployees;     
               opp.Employees_Paid_Per_Payroll__c = ref.SourceLead__c!=null? ref.SourceLead__r.NumberOfEmployees : ref.Account__r.NumberOfEmployees; //Vinay
               System.debug('RM createOpp  opp.Employees_Paid_Per_Payroll__c:'+opp.Employees_Paid_Per_Payroll__c);
               System.debug('RM createOpp  ref.Account__r.NumberOfEmployees:'+ref.Account__r.NumberOfEmployees);
  
            }
            else
            {  description = ref.Referring_Opportunity__r.Description != null ? ref.Referring_Opportunity__r.Description + '\n' : '';  
               opp.Employees_Paid_Per_Payroll__c = ref.Referring_Opportunity__r.Employees_Paid_Per_Payroll__c;
            }
      
            opp.Description = description + (ref.Notes__c != null ? ref.Notes__c : '');
         
            opp.Referral__c = ref.Referral_Partner__r.SellingOppIsReferral__c;
            //opp.Referral_From__c = getReferralFrom(ref.Referring_User__r.Sales_Org__c);
         
            opp.Frequency__c = (ref.Referring_Opportunity__r != null ? ref.Referring_Opportunity__r.Frequency__c : opp.Frequency__c);  //CMFCMF
         } // if (opp.Id ==
      } // if (ref.Referral_Partner__r
    
      return opp;
   } // createOpp
   
   public static Opportunity checkExistingOpps(Opportunity opp, Referral__c ref) {
      Opportunity matchedOpp = null;
      // look for existing opportunities if it's not an internal referral
      // if existing opportunity, we don't set the rest of the opp fields.
      Opportunity[] existingOpps = OpptyDupeCheck.dupeOpps(opp);
      System.debug('checkExistingOpps existingOpps='+(existingOpps != null ? existingOpps.size() : -1));
      addToProcessNotes(ref, 'DupeCheck existingOpps='+(existingOpps != null ? existingOpps.size() : -1)); 
      if (existingOpps != null && !existingOpps.isEmpty()) {
         Opportunity oppOver70=null;
         Opportunity oppUnder70=null;
         for (Opportunity checkOpp : existingOpps) {
            System.debug('checkExistingOpps opp probability='+checkOpp.Probability);
            if (oppOver70 == null && checkOpp.Probability > 70) {
               oppOver70 = checkOpp;
            } else if (oppUnder70 == null && checkOpp.Probability <= 70) {
               oppUnder70 = checkOpp;
            }
         }
         matchedOpp = (oppUnder70 != null ? oppUnder70 : oppOver70);
      } // if (existingOpps != null &&
      
      /*
      if (matchedOpp.Probability > 70) {
         ref.SellingOppInfo__c = Label.OppDupeReuse;
      }
         // do we match up to the latest opp?
         Opportunity matchedOpp = existingOpps[0];
               System.debug('createOpp using existing opp');
               opp = matchedOpp;
               ref.SellingOppInfo__c = Label.OppDupeReuse;
           */
      System.debug('checkExistingOpp found matchedOpp='+(matchedOpp != null));
      return matchedOpp;
   } // checkExistingOpp
   
   public static void setJointApptInfo(Opportunity opp, Referral__c p_ref, ReferralJoin__c refJoin) {
      String jointRepNames = null;
      String jointRefPartners = null;
      Integer nbrJoins = ((refJoin != null && refJoin.Referrals__r != null) ? refJoin.Referrals__r.size() : -1);
      String notes = 'refJoin='+(refJoin != null ? String.valueOf(refJoin.Id) : 'null')+' nbrJoins='+nbrJoins;
      if (nbrJoins > 0) {
         for (Referral__c ref : refJoin.Referrals__r) {
            if (ref.id != p_ref.Id) {
               String thisName = (ref.User__r != null ? ref.User__r.Name : (ref.Contact__r != null ? ref.Contact__r.Name : null));
               notes +=(' thisName='+thisName);
               if (thisName != null) {
                  if (jointRepNames == null) {
                     jointRepNames = thisName;
                  } else {
                     jointRepNames += ', '+thisName;
                  }
               }
               notes += (' hasRefPart='+ref.Referral_Partner__r != null);
               if (ref.Referral_Partner__r != null) {
                  if (jointRefPartners == null) {
                     jointRefPartners = ref.Referral_Partner__r.Name;
                  } else {
                     jointRefPartners += ','+ref.Referral_Partner__r.Name;
                  }
               }
            } // if (ref.id
         } // for (Referral__c ref
         
      } // if (refJoin != null
      notes += ' jointRefPartners='+jointRefPartners;
      StringHelper.addToProcessNotes(opp,notes);
      opp.JointAppointmentReps__c = jointRepNames;
      opp.JointAppointmentReferralPartners__c = jointRefPartners;
   } // setJointApptInfo
   
   public static String getNSSSource(Referral__c ref) {
      String nssSource = null;
      // only set the NSS Source if there's one on the referral partner
      if (ref.Referral_Partner__c != null && ref.Referral_Partner__r != null
              && String.isNotBlank(ref.Referral_Partner__r.NSS_Source__c)) {
         
         //APR0145054 : NSS Source would not be populated based on Latest Campaign.
        /* if (ref.SourceContact__c != null && ref.SourceContact__r.LatestCampaign__c != null
                && String.isNotBlank(ref.SourceContact__r.LatestCampaign__r.OppNSSSource__c) && ref.SourceContact__r.LatestCampaignDate__c != null) {
            Integer nbrDays = Integer.valueOf(ref.SourceContact__r.LatestCampaign__r.DestinationNbrDays__c);
            Datetime checkTime = Datetime.now().addDays(-nbrDays);
            if (ref.SourceContact__r.LatestCampaignDate__c > checkTime) {
               nssSource = ref.SourceContact__r.LatestCampaign__r.OppNSSSource__c;
            }
         }*/
         if (nssSource == null) {
                      
            if (ref.Referral_Partner__r.NSS_Source__c != ReferralQueries.NSS_SOURCE_BOTH) {
               nssSource = ref.Referral_Partner__r.NSS_Source__c;
            } else if (ref.Referring_User__c != null && ref.Referring_User__r != null) {
               nssSource = ProspectOwnershipMethods.getNSS_Source(ref.Referring_User__r);
            }
         } // if (nssSource == null
      } // if (ref.Referral_Partner__c != null
      return nssSource;
   } // getNSSSource
   
   //APR0145054 : Populate Marketing Source based on Lastest Campaign else, NSS Source
   public static String getMarketingSource(Referral__c ref) {
      String marketingSource = null;
      // only set the NSS Source if there's one on the referral partner
      if (ref.SourceContact__c != null && ref.SourceContact__r.LatestCampaign__c != null
               && String.isNotBlank(ref.SourceContact__r.LatestCampaign__r.OppNSSSource__c) && ref.SourceContact__r.LatestCampaignDate__c != null) {
         Integer nbrDays = Integer.valueOf(ref.SourceContact__r.LatestCampaign__r.DestinationNbrDays__c);
         Datetime checkTime = Datetime.now().addDays(-nbrDays);
         if (ref.SourceContact__r.LatestCampaignDate__c > checkTime) {
            marketingSource = ref.SourceContact__r.LatestCampaign__r.OppNSSSource__c;
         }
      }
      return marketingSource;
   } // getMarketingSource
   
   public static void setOpportunityFields(Referral__c ref, Opportunity opp, Boolean isSellingOpp) {
      // if this is for NSS, set the inbound/outbound field
      opp.Mthd_Lead_Rcvd__c = (ref.Referral_Partner__r != null ? ref.Referral_Partner__r.Partner_Type__c : null);
      opp.NSS_Source__c = getNSSSource(ref);
      //APR0145054 : Populate Marketing Source based on Lastest Campaign else, NSS Source
      String marketingSource= getMarketingSource(ref);
      opp.Marketing_Source__c = marketingSource!=null? marketingSource: opp.NSS_Source__c;
      //if (ref.Referral_Partner__r != null && ref.Referral_Partner__r.Partner_Type__c == ReferralController.REF_NSS) {
      //  opp.Mthd_Lead_Rcvd__c = 'NSS';
      //  opp.NSS_Source__c = getNSSSource(ref);
      //} // if (ref.Referral_Partner__r.Partner_Type__c
      
      // CMF if starting at RC, get leadsource from there if possible.
      if (String.isNotBlank(ref.SellingLeadSource__c)) {
         opp.LeadSource = ref.SellingLeadSource__c;
      } else if (ref.Referral_Partner__r != null && ref.Referral_Partner__r.Partner_Type__c == ReferralController.REF_NSS) {
         // TODO - What should we actually be using here?
         if (ref.SourceContact__r != null && ref.SourceContact__r.LatestCampaign__r != null && String.isNotBlank(ref.SourceContact__r.LatestCampaign__r.LeadSource__c)) {
            opp.LeadSource = ref.SourceContact__r.LatestCampaign__r.LeadSource__c;
         } else {
            opp.LeadSource = Label.LeadSource_ReferralOther;
         }
      } else if (ref.Referral_Source__c == 'Wholesaler') {
         opp.LeadSource = Label.LeadSource_ReferralFA;   
      } else if (ref.Started_From__c == 'Referral Contact' && ref.Referral_Contact__r.Referral_Type__c != null) {     //CMF
         if (ref.Referral_Contact__r.Referral_Type__c.indexOf('CPA') > -1)
         {   opp.LeadSource = Label.LeadSource_ReferralCPA_start;  }
         else if (ref.Referral_Contact__r.Referral_Type__c.indexOf('Bank') > -1)
         {   opp.LeadSource = Label.LeadSource_ReferralBank; }
         else if (ref.Referral_Contact__r.Referral_Type__c.indexOf('IIA') > -1)
         {   opp.LeadSource = Label.LeadSource_InsAgent;   }
      }
         
      if (isSellingOpp && ref.Referral_Partner__r != null && ref.Referral_Partner__r.Partner_Type__c == ReferralController.REF_INTERNAL && ref.Referring_User__r != null) {
         opp.LeadSource = getReferralFromLeadSource(ref);
      }       

      
      if (ref.Referral_Source__c == 'Wholesaler')                                          //CMF
      {    opp.Zip_Tier__c=OpptyCheckFields.LARGE_MARKET;  }                               //CMF
       
         
      System.debug('setOpportunityFields ref.ReferFromContact__c='+ref.ReferFromContact__c+' ref.Referring_User__c='+ref.Referring_User__c+' ref.Referring_User__r='+ref.Referring_User__r);
      
      if (ref.ReferFromContact__c != null) {
         System.debug('setOpportunityFields ref.ReferFromContact__c');
         opp.Referring_Employee__c = ref.ReferFromContact__c;
      } else if (ref.Referring_User__r != null && ref.Referring_User__r.HR_Person_Id__c != null) {
         Contact referringCtct = new UserHelper().getContactByPersonId(ref.Referring_User__r.HR_Person_Id__c,UserHelper.PAYCHEX_COMP);
         System.debug('setOpportunityFields HR_Person_Id__c='+ref.Referring_User__r.HR_Person_Id__c+' referringCtct='+referringCtct);
         if (referringCtct != null) {
            opp.Referring_Employee__c = referringCtct.Id;
         } else {
              
         }
      } // if (opp.Referring_User__r)

      String salesOrg = (ref.User__r != null ? ref.User__r.Sales_Org__c : UserHelper.SO_CORE);
      CreateOppAndMeeting coam = getCoam(salesOrg,ref.User__r.Sales_Division__c);
      Referral_Account__c refAcct = (ref.Account__r != null ? ref.Account__r.Referral_National_Account__r : null);
      Referral_Contact__c refCtct = (ref.SourceContact__r != null ? ref.SourceContact__r.Referral_Contact__r : null);
      Account cltRef = null;
      
      coam.setUnitAndReferrals(opp,ref.IsAncillary__c,refCtct,cltRef,refAcct);
      
      opp.Frequency__c = (ref.Account__r != null ? coam.convertFrequency(ref.Account__r.Frequency__c) : null);        //CMF need freq on referring opp 
   } // setOpportunityFields
   
   /** Create an opportunity contact role record. 
    */
   public static OpportunityContactRole createOppContact(Id oppId, Id contactId) {
      OpportunityContactRole ocr = null;
      if (oppId != null && contactId != null) {
         ocr = new OpportunityContactRole();
         ocr.contactId= contactId;  
         ocr.isPrimary=true;  
         ocr.opportunityId=oppId;
         ocr.Role='Decision Maker';
      } // if (oppId
      return ocr;
   } // createOppContact
       
   /** Get the value for the Referral From field on the Opportunity
    */
   public static String getReferralFrom(String salesOrg) {
      // default value
      String refFrom = salesOrg;
      // handle the values that do not equal the sales org
      if (salesOrg != null) {
         if (salesOrg == UserHelper.SO_CORE) {
            refFrom = 'CORE';
         } else if (salesOrg == UserHelper.SO_PEO_ASO) {
            refFrom = 'PEO-ASO';
         }
      } // if (salesOrg != null)
      return refFrom;
   } // getReferralFrom
   
   /** Get the value for the lead source from a referral based on the sales org.
        If referral is coming from financial advisor force LeadSource to say FA
    */
   public static String getReferralFromLeadSource(Referral__c ref) {   																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																	      
      // default value
      String salesOrg = ref.Referring_User__r.Sales_Org__c;
      String referralSource = ref.Referral_Source__c;
      String leadSource = Label.LeadSource_Ref_Internal_Emp;
      if (referralSource == 'Wholesaler') {
         leadSource = Label.LeadSource_ReferralFA;
      } else if (salesOrg != null) {
         SalesOrg__c salesOrgSetting = SalesOrg__c.getInstance(salesOrg);
         if (salesOrgSetting != null && String.isNotBlank(salesOrgSetting.InternalReferralLeadSource__c)) {
            leadSource = salesOrgSetting.InternalReferralLeadSource__c;
         } else {   
             if (salesOrg == UserHelper.SO_CORE) {
                leadSource = Label.LeadSource_Ref_Internal_Core;
            } else if (salesOrg == UserHelper.SO_MMS) {
                leadSource = Label.LeadSource_Ref_Internal_MMS;
            } if(ref.Referring_User__r.Sales_Division__c == 'CSSR'){
                    leadSource = Label.LeadSource_Ref_Internal_CSSR;
            } else if (salesOrg == UserHelper.SO_401) {
                leadSource = Label.LeadSource_Ref_Internal_HRS;
            } else if (salesOrg == UserHelper.SO_PEO_ASO) {
                leadSource = Label.LeadSource_Ref_Internal_HRSolution   ;
            } else if (salesOrg == UserHelper.SO_HNB) {
                leadSource = Label.LeadSource_Ref_Internal_HB;
            } // if (salesOrg
         } // if (salesOrg != null
      } // else if Wholesaler
      return leadSource;
   } // getReferralFromLeadSource
   
   /** Get the email on the contacts/referral contacts and populate the email field on the referral.
    */
   public static void checkEmail(Referral__c[] refs) {
      // check if we're on production
      String sandboxName = Utilities.checkForProduction();
      Boolean isProduction = (sandboxName == null || sandboxname == '');
      String toEmail = null;
      String addNote = null;
      if (!isProduction) {
         // if not in production, get the running user's email
         User runningUser = UserHelper.getRunningUser();
         //User u = [Select id, Name, Email from User where Id = :UserInfo.getUserId()];
         // if running a test do not change the email
         toEmail = (Test.isRunningTest() ? null : (runningUser != null ? runningUser.Email : 'dcarmen@paychex.com'));
         // add a note that this is from the Sandbox
         addNote = '***** This is running in the '+sandboxName+' Sandbox! Email is set to the running user ('+toEmail+') *****';
      }
    
      Id[] refContactIds = new Id[]{};
      Id[] contactIds = new Id[]{};
      for (Referral__c ref : refs) {
         if (ref.Contact__c != null) {
            contactIds.add(ref.Contact__c);
         } else if (ref.Referral_Contact__c != null) {
            refContactIds.add(ref.Referral_Contact__c);
         }
      } // for (Referral__c
    
      //map of all ids and their email
      Map<Id,String> emailMap = new Map<Id,String>();
      getCtctEmails(contactIds,emailMap);
      getRefCtctEmails(refContactIds,emailMap);
    
      // set the email addresses
      for (Referral__c ref : refs) {
         // set the email to the running user's email if not in production
         // if in production, set it to the Contact or Referral Contact as appropriate
         ref.Email__c = (toEmail != null ? toEmail : 
                           (ref.Contact__c != null ? emailMap.get(ref.Contact__c) :
                             (ref.Referral_Contact__c != null ? emailMap.get(ref.Referral_Contact__c) : null)));
         // add a note 
         if (String.isNotBlank(addNote)) {
           Integer maxNoteSize = ObjectHelper.getFieldLngth(Referral__c.Notes__c);
           // make sure doesn't exceed the field size
           ref.Notes__c = (addNote + (ref.Notes__c != null ? ref.Notes__c : '')).left(maxNoteSize);
         }
      } // for (Referral__c ref : refs
      
   } // checkEmail

   /** Get the email addresses from the Contact records.
    */
   public static void getCtctEmails(Id[] contactIds, Map<Id,String> emailMap) {
      if (!contactIds.isEmpty()) {
         Contact[] ctcts = [Select Id, Name, Email 
                              from Contact
                             Where Id in :contactIds
                               and Email != null]; 
         for (Contact ctct : ctcts) {
            emailMap.put(ctct.Id, ctct.Email);
         }
      } // if (!contactIds.isEmpty
   } // getCtctEmails
   
   /** Get the email addresses from the Referral Contact records.
    */
   public static void getRefCtctEmails(Id[] contactIds, Map<Id,String> emailMap) {
      if (!contactIds.isEmpty()) {
         Referral_Contact__c[] ctcts = [Select Id, Name, Email__c
                              from Referral_Contact__c
                             Where Id in :contactIds
                               and Email__c != null]; 
         for (Referral_Contact__c ctct : ctcts) {
            emailMap.put(ctct.Id, ctct.Email__c);
         }
      } // if (!contactIds.isEmpty
   } // getRefCtctEmails
   
   /** Handle the rejected referral records.
    */
   public static void handleRejected(Id[] refIds) {
    // retrieve the referrals
      Referral__c[] refs = retrieveReferrals(refIds);
      // get the line item ids
      Id[] oliIds = new Id[]{};
      for (Referral__c ref : refs) {
         if (ref.ReferringLineItemId__c != null) {
            oliIds.add((Id)ref.ReferringLineItemId__c);
         }
      }
    // mark as rejected
    updateOlis(oliIds,'Referral Rejected');
   } // handleRejected
   
   /** Get the Referral Contact record if this referral originated from referral contact screen.        
    */
   public static Referral_Contact__c getRefCtct(Id refFAContactId) {
      if (refFAContactId != null) {
         Referral_Contact__c refct = [Select Id, Name, Email__c, Zip_Code__c, Referral_Type__c
                                        , Referral_Account__r.Zip_Postal_Code__c
                                        , Referral_Account__r.Hold_Out__c
                                        , Referral_Account__r.OwnerId
                                        from Referral_Contact__c
                                        Where Id = :refFAContactId];
         return refct;                       
         }
      return null;   
   } // getRefCtct
      

   /** Check the ownership records
       For a referral record, there should only be (at most) one outbound owner and one inbound owner. 
       If an outbound 
       
       // if there is an open ownership record of the same type, use that. Don't change the NSR, but you can change the team.
       // if there is a lockout ownership record of the same type and same NSR, but different NSS Team, create a new one
       // if there is an open outbound record not locked, and inbound opportunity comes in, close the outbound record and create an inbound
       // if there is an open outbound record locked, and inbound opportunity comes in, don't touch the outbound and create an inbound
       // if an open record already exists for the type and you're creating a new one, only set the commission period on the new one.
       // if there is a lockout inbound, and outbound creates an opportunity, do not create an ownership record. 
    */
   
   //if opty is created by NSS, post event or tip to FSR, DSA and DSM
   public static void chatterPostIt(ChatterWrapper[] chatterPosts) {
      chatterFilter.excludeFromFilter = TRUE;
      // if we're going to add an extra mention to the chatter posts, check here.
      Id extraMentionId = null;
      PaychexSettings__c payxSetting = PaychexSettings__c.getInstance('OptyChatterPostMention');
      if (payxSetting != null && payxSetting.IsActive__c && String.isNotBlank(payxSetting.Attribute1__c)) { 
         extraMentionId = payxSetting.Attribute1__c;
      }
              
      for (ChatterWrapper chatterPost: chatterPosts) {
         if (extraMentionId != null) {
            chatterPost.addMentionId(extraMentionId);
         }
         System.debug('Creating Chatter Mention Post');
         String[] postTexts = new String[]{chatterPost.chatterMsg + ' ' + chatterPost.notes};
         ChatterMentionPost.createChatterMentionPost(chatterPost.objectId, chatterPost.mentionIds, postTexts, false, false);
         
      } // for (ChatterWrapper chatterPost
      
      ChatterMentionPost.postBatchFeedElements();
   } // chatterPost
   
   public class ChatterWrapper {
    public Id objectId = null;
    public String chatterMsg = null;
    public Boolean isEvent = false;
    public String notes = null;

    // used to ensure the 
    private Set<Id> mentionIdSet = new Set<Id>();    
    public Id[] mentionIds = new Id[]{};
    public void addMentionId(Id idToCheck) {
       if (idToCheck != null && !mentionIdSet.contains(idToCheck)) {
          mentionIds.add(idToCheck);
          mentionIdSet.add(idToCheck);
       }
    } // addMentionId
    
   } // ChatterWrapper
   
   //public static void checkRefPartnerName(Referral__c[] refsToCheck, Set<Id> refPartnerIdSet) {
   public static void checkRefPartnerName(Map<Id,Referral__c[]> checkRefPartnerMap) {
      Referral_Partner__c[] refPartners = ReferralQueries.selectRefPartners(checkRefPartnerMap.keySet(), null, null);
      for (Referral_Partner__c refPart : refPartners) {
         Referral__c[] refs = checkRefPartnerMap.remove(refPart.Id);
         if (refs != null) {
            for (Referral__c ref : refs) {
               StringHelper.addToProcessNotes(ref,'Set ReferralPartnerName '+refPart.Name);
               ref.ReferralPartnerName__c = refPart.Name;
            }
         }
      } // for (Referral_Partner__c refPart
      
      // if there's anything left, mark in the record.
      for (Referral__c[] refs : checkRefPartnerMap.values()) {
         for (Referral__c ref : refs) {
            StringHelper.addToProcessNotes(ref,'Could not find ReferralPartnerName for '+ref.Referral_Partner__c);
         } // for (Referral__c ref
      } // for (Referral__c[] refs
             
   } // checkRefPartnerName
   
   public static Boolean LOG_NO_REJECT_REASON=Label.ReferralLogReject == 'Y';
   
   /* if Referral is rejected, make sure they put in a comment that can be moved to reject reason field
    */
   public static void moveRejectedReasons(List<Referral__c> refList) {
      ProcessInstance[] piList = [SELECT Id, TargetObjectId, (SELECT Id, StepStatus, Comments FROM Steps) 
                                    FROM ProcessInstance Where targetObjectID in :refList and Status = 'Rejected'];  
      Map<Id, ProcessInstance> piMap = new Map<Id, ProcessInstance>();
      for (ProcessInstance pi:piList) {
         piMap.put(pi.TargetObjectId, pi);
      }
      for (Referral__c ref: refList) {
         ProcessInstance refPI = piMap.get(ref.Id);
         if (refPI != null) {
            for (SObject step: refPI.Steps) {
               if ((String)step.get('StepStatus') == 'Rejected') {
                  if (String.isBlank((String)step.get('Comments'))) {
                     if (LOG_NO_REJECT_REASON) {
                         ref.AddError('You must enter a Reject Reason in the Comments field. Please use the Back arrow to get to the previous screen to fill in a reason.');
                     }
                  } else {
                     ref.Reject_Reason__c = ((String)step.get('Comments')).Left(255);  }
               } // if rejected
            } // for steps  
         } // if (refPI != null
      } // for refList    
                
   } // moveRejectedReasons
    
   public static String LOCK_DISPOSITION = Label.DispositionLock;
   
   // 
   public static Boolean ENFORCE_LOCK_DISPOSITION = false;
   
   // if the disposition is SLD, do not allow any of the commission fields to change
   public static void checkDisposition(Referral__c newRef, Referral__c oldRef) {
      Boolean allowChange = (newRef.CommissionOverride__c 
                             || oldRef == null
                             || (oldRef != null && String.isNotBlank(LOCK_DISPOSITION) && oldRef.Disposition__c != LOCK_DISPOSITION)
                            );
      if (!allowChange && oldRef != null
          && (newRef.ActualRevenue__c != oldRef.ActualRevenue__c
              || newRef.Disposition__c != oldRef.Disposition__c
              || newRef.MonthSaleReported__c != oldRef.MonthSaleReported__c
              || newRef.NbrOfEmployees__c != oldRef.NbrOfEmployees__c
              || newRef.PendingRunOfPayroll__c != oldRef.PendingRunOfPayroll__c
             )
          ) {
         newRef.ActualRevenue__c = oldRef.ActualRevenue__c;
         newRef.Disposition__c = oldRef.Disposition__c;
         newRef.MonthSaleReported__c = oldRef.MonthSaleReported__c;
         newRef.NbrOfEmployees__c = oldRef.NbrOfEmployees__c;
         newRef.PendingRunOfPayroll__c = oldRef.PendingRunOfPayroll__c;
      }
      // reset the flag if set
      if (newRef.CommissionOverride__c) {
         newRef.CommissionOverride__c = false;
      }
   } // checkDisposition
   
   public static Map<String,PartnerReferral__c> getPartnerReferralMap(Referral__c[] refList){
        Map<String,PartnerReferral__c> refTransIdPartReferralMap  = new Map<String,PartnerReferral__c>();
        Id[] partRefIds = new Id[]{};
        for(Referral__c ref: refList){
            partRefIds.add(ref.PartnerReferral__c);
        }
        Map<Id,PartnerReferral__c> partRefMap = new Map<Id,PartnerReferral__c>([SELECT Id,RR_Last_Routed__c,Destination__c,Source__c,Original_Owner__c FROM PartnerReferral__c WHERE Id in :partRefIds]);
        if(partRefMap!= null && !partRefMap.isEmpty()){
           Long transactionTime = DateTime.now().getTime();
           
            for(Referral__c ref: refList){
                if(partRefMap.containsKey(ref.PartnerReferral__c)){
                    if(string.IsBlank(ref.Transaction_Id__c)){
                       ref.Transaction_Id__c = (ref.Id != null ? (String)ref.Id : String.valueOf(transactionTime));
                       transactionTime++;
                        //ref.Transaction_Id__c = ref.Name+String.valueOf(system.now());
                    }
                    refTransIdPartReferralMap.put(ref.Transaction_Id__c,partRefMap.get(ref.PartnerReferral__c));
                }
             }
        }
        return refTransIdPartReferralMap;
   }
   
   public static Map<String,Transfer_Tracking__c> trackerByReferralTransIdMap;
   
   public static void manageTransferTrackingBefore(Referral__c[] refs){
      System.debug('manageTransferTrackingBefore ref='+refs.size());
      trackerByReferralTransIdMap = new Map<String,Transfer_Tracking__c>();
      Id[] refOwnerQueues = new Id[]{};
      Map <Id,Group> queueMap;
      for(Referral__c ref:refs){
         //if owned by a queue, pop into list
         //Boolean isUser = (String.valueOf(ref.OwnerId).startsWith(ObjectHelper.PREFIX_GROUP)); //  User.sObjectType.getDescribe().getKeyPrefix()));
         if ((String.valueOf(ref.OwnerId)).startsWith(ObjectHelper.PREFIX_GROUP)) {
            refOwnerQueues.add(ref.OwnerId);
         }
      } // for(Referral__c ref
      if(!refOwnerQueues.isEmpty()){
         queueMap = UserHelper.getQueueMapById(refOwnerQueues);
         //queueMap = new Map<Id,Group>([SELECT Id,Name FROM Group WHERE Id in :refOwnerQueues]);
      }
      Long transactionTime = DateTime.now().getTime();
            
      for(Referral__c ref:refs){
         // populate the transaction id if not already set
         if(string.IsBlank(ref.Transaction_Id__c)){
            ref.Transaction_Id__c = (ref.Id != null ? (String)ref.Id : String.valueOf(transactionTime));
            transactionTime++;
         }
         Group queue = (queueMap != null ? queueMap.get(ref.OwnerId) : null);
         system.debug('manageTransferTrackingBefore owner: '+ref.OwnerId+' queue: '+queue);

         if(!trackerByReferralTransIdMap.containsKey(ref.Transaction_Id__c)){
             Transfer_Tracking__c newTracker = new Transfer_Tracking__c(
                      Assigned_to_Queue__c = (queue != null ? queue.Name : null)
                     ,Date_of_Assignment__c = Datetime.now());
            //APR0121163
            /* if(ReferralController.selectedTransferReason!=null){
                newTracker.Reason__c = ReferralController.selectedTransferReason;
             }
             else */
             if(RecordReassignmentController.selectedTransferReason!=null){
              newTracker.Reason__c = RecordReassignmentController.selectedTransferReason;
             }
             if(String.isNotBlank(newTracker.Reason__c)){
                ref.Transfer_to_Field_Reason__c = newTracker.Reason__c;
             }
             trackerByReferralTransIdMap.put(ref.Transaction_Id__c,newTracker);
         }
      } // for(Referral__c ref
      system.debug('trackerByReferralTransIdMap: '+trackerByReferralTransIdMap.size());
   } // manageTransferTrackingBefore
   
   public static void manageTransferTrackingAfter(Referral__c[] refs){
      System.debug('manageTransferTrackingAfter refs='+refs.size());
      Transfer_Tracking__c[] trackersToUpsert = new Transfer_Tracking__c[]{};
      Map<Id,Referral__c>refMap = new Map<Id,Referral__c>();
      Id[] refOwnerUsers = new Id[]{};
      Map <Id,User> userMap;
      for(Referral__c ref:refs){
          if(ref.id != null){
              refMap.put(ref.Id,ref);
              System.debug('manageTransferTrackingAfter ref.Id='+ref.Id);
              //if owned by a user, pop into list
              if(String.valueOf(ref.OwnerId).startsWith(ObjectHelper.PREFIX_USER)){
                  refOwnerUsers.add(ref.OwnerId);
              }
          }
         
      } // for(Referral__c ref
      System.debug('manageTransferTrackingAfter refMap='+refMap.size());
       
      if(!refOwnerUsers.isEmpty()){
         userMap = new Map<Id,User>([SELECT FirstName,LastName,NSS_Team__c,Sales_Org__c FROM User WHERE Id in :refOwnerUsers]);
      } 
        
      Transfer_Tracking__c[] trackerList= [SELECT Id,Assigned_to__c,Assignment_End_Date__c,Date_of_Assignment__c,Division__c,Previous_Transfer_Tracking__c,Referral_Lookup__c FROM Transfer_Tracking__c WHERE Referral_Lookup__c in :refMap.keySet() AND Assignment_End_Date__c=NULL];
      System.debug('manageTransferTrackingAfter trackerList='+trackerList.size());
      Map<Id,Transfer_Tracking__c> referralOldTrackerMap = new Map<Id,Transfer_Tracking__c>();
      for(Transfer_Tracking__c oldTracker:trackerList){
         oldTracker.Assignment_End_Date__c = system.now();
         referralOldTrackerMap.put(oldTracker.Referral_Lookup__c,oldTracker);
         trackersToUpsert.add(oldTracker);
      } // for(Transfer_Tracking__c oldTracker
      
      system.debug('manageTransferTrackingAfter before loop trackersToUpsert: '+trackersToUpsert.size());
      for(Referral__c ref:refMap.values()){
         if(trackerByReferralTransIdMap!=null && trackerByReferralTransIdMap.containsKey(ref.Transaction_Id__c)){
            Transfer_Tracking__c newTracker = trackerByReferralTransIdMap.remove(ref.Transaction_Id__c);
            newTracker.Referral_Lookup__c = ref.Id;
            //newTracker.Sales_Org__c = (userMap!=null && userMap.containsKey(ref.OwnerId)?userMap.get(ref.OwnerId).NSS_Team__c:'');
                
            //Owner is a user, set assigned to as the user, set division
            User usr = (userMap != null ? userMap.get(ref.OwnerId) : null);
            if (usr != null) {
               newTracker.Assigned_to__c = ref.OwnerId;
               newTracker.Division__c = (String.isNotBlank(usr.NSS_Team__c) ? usr.NSS_Team__c : usr.Sales_Org__c);
            }
                
            if(referralOldTrackerMap.containsKey(ref.Id)){
               newTracker.Previous_Transfer_Tracking__c = referralOldTrackerMap.get(ref.Id).Id;
            }
            trackersToUpsert.add(newTracker);
            system.debug('manageTransferTrackingAfter in loop trackersToUpsert: '+trackersToUpsert.size());
         } // if(trackerByReferralTransIdMap
      } // for(Referral__c ref

      DmlHelper.performDML2(trackersToUpsert, DmlHelper.DML_UPSERT, 'ReferralMethods', 'manageTransferTrackingAfter', 'Upsert Trackers', true);
   } // manageTransferTrackingAfter
   
   public static void checkSyncRelatedOwners(Id[] refList) {
      if (!refList.isEmpty()) {
         if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
            syncRelatedOwnersNow(refList);
         } else {
            syncRelatedOwnersFuture(refList);
         }
      } // if (!refList.isEmpty    
      
   } // checkSyncRelatedOwners
   
   // dont add @future to make this a real future method.  it confuses the users because they dont see owner changes when they expect it
   public static void syncRelatedOwnersFuture(Id[] refList){
      syncRelatedOwnersNow(refList);
   } // syncRelatedOwnersFuture
   
   public static Set<String> exceptionValues = new set<string>(Label.ReferralOwnerSyncExceptions.split(';'));
   
   // Sync up
   public static void syncRelatedOwnersNow(Id[] refIdList){
        //map <Referral Id, Referral Owner Id>
        //Map <Id,Id> referralOwnerIdMap = new Map <Id,Id>();
        system.debug('syncRelatedOwners in method refIdList='+refIdList.size());
        Referral__c[] refs = retrieveReferrals(refIdList);
        Lead[] leadsToUpdate = new Lead[]{};
        Map<Id,Account> acctsToUpdateMap = new Map<Id,Account>();

        Map<Id,Contact> ctctsToUpdateMap = new Map<Id,Contact>();
        Map<Id,Referral__c> rfrlsToUpdateMap = new Map<Id,Referral__c>();
        
        Opportunity[] opptysToUpdate = new Opportunity[]{};
        Set<Id> ownerIdSet = new Set<Id>();

        // get the current owners
        Boolean hasQueue = false;
        for(Referral__c ref:refs){
            ownerIdSet.add(ref.OwnerId);
            Boolean ownedByUser = (String.valueOf(ref.OwnerId)).startsWith(ObjectHelper.PREFIX_USER);
            hasQueue = (hasQueue || (!ownedByUser));
        }
        Id[] ownerIdList = new Id[]{};
        ownerIdList.addAll(ownerIdSet);
        
        //Map<Id,Group> queueMap = new Map<Id,Group>([SELECT Name FROM Group WHERE Id in :ownerIds]);
        // get all of the owners that are queues
        Map<Id,Group> queueMap = (hasQueue ? UserHelper.getQueueMapById(ownerIdList) : new Map<Id,Group>());
        
        System.debug('syncRelatedOwnersNow exceptionValues='+exceptionValues);
        
        for(Referral__c ref:refs){
            system.debug('syncRelatedOwners ref='+ref.Name);
            //referralOwnerIdMap.put(ref.Id,ref.OwnerId);
            Boolean handled = false;
            Boolean ownedByUser = (String.valueOf(ref.OwnerId)).startsWith(ObjectHelper.PREFIX_USER);
            String refNotes = 'syncRelatedOwners ownedByUser='+ownedByUser+' SetOwnerHoldout__c'+ref.SetOwnerHoldout__c;
            HoldOut_ExpirationDates__c holdOutDates = null;
            if (ref.SetOwnerHoldout__c) {
               String destination = ((ref.PartnerReferral__r != null && String.isNotBlank(ref.PartnerReferral__r.Destination__c)) ? ref.PartnerReferral__r.Destination__c : null);
               refNotes += ' destination='+destination;
               if (String.isNotBlank(destination)) {
                  String key = RecordTypeHelper.cleanRtName(destination);
                  holdOutDates = HoldOut_ExpirationDates__c.getInstance(key);
                  System.debug('syncRelatedOwners key='+key+' holdOutDates='+holdOutDates);
                  refNotes += ' holdOutDates='+(holdOutDates != null ? holdOutDates.Name : 'Not Found');
               }
               ref.SetOwnerHoldout__c = false;
            } // if (ref.SetOwnerHoldout__c
            if(!ownedByUser && queueMap!=null && queueMap.containsKey(ref.OwnerId)){
                //this will only work if there is no round robin on the queue
                if(exceptionValues!=null && exceptionValues.contains(queueMap.get(ref.OwnerId).Name) && ref.Selling_Opportunity__c != null && ref.SourceContact__c!=null){
                    Contact ctct = ref.SourceContact__r;
                    ctct.NSSOwnership__c = queueMap.get(ref.OwnerId).Name;
                    refNotes += ('; set NSSOwnership__c to '+ctct.NSSOwnership__c);
                    ctctsToUpdateMap.put(ctct.Id,ctct);
                    handled = true;
                } else if (ref.SourceLead__c != null && !ref.SourceLead__r.IsConverted && queueMap.get(ref.OwnerId).Name == 'Oasis Inbound Queue' ) {
                   // change this eventually to be more dynamic.
                   ref.SourceLead__r.OwnerId = ref.OwnerId;
                   refNotes += ('; updating lead owner to '+ref.SourceLead__r.OwnerId);
                   leadsToUpdate.add(ref.SourceLead__r);
                } else if (ref.SourceLead__c != null && !ref.SourceLead__r.IsConverted && queueMap.get(ref.OwnerId).Name == 'Drift Chat') {
                   ref.SourceLead__r.OwnerId = ref.OwnerId;
                   refNotes += ('; updating lead owner to '+ref.SourceLead__r.OwnerId);
                   leadsToUpdate.add(ref.SourceLead__r);
                }
                
            }
            if(ownedByUser && ref.Selling_Opportunity__c != null && !handled){
                system.debug('syncRelatedOwners ref='+ref.Name+' updating opp owner from '+ref.Selling_Opportunity__r.OwnerId+' to: '+ref.OwnerId);
                Opportunity oppty = ref.Selling_Opportunity__r;
                oppty.OwnerId = ref.OwnerId;
                StringHelper.addToProcessNotes(oppty,'updating opp owner to '+oppty.OwnerId);
                refNotes += ('; updating opp owner to '+oppty.OwnerId);
                opptysToUpdate.add(oppty);
                handled = true;
            }
            if( ownedByUser && ref.SourceContact__c != null && (!handled || holdOutDates != null)){
                Contact ctct = ref.SourceContact__r;
                if (ctct.OwnerId != ref.OwnerId) {
                    system.debug('syncRelatedOwners ref='+ref.Name+' updating contact owner');
                    ctct.OwnerId = ref.OwnerId;
                    refNotes += ('; updating ctct owner to '+ctct.OwnerId);
                    ctctsToUpdateMap.put(ctct.Id, ctct);
                }
                if (holdOutDates != null && !ctct.Hold_Out__c) {
                   // TODO - if there's already a holdout do we skip?
                   ctct.Hold_Out__c=true;
                   ctct.Hold_Out_Reason__c=holdOutDates.Name;
                   ctct.Hold_Out_Expiration__c=Date.today().addDays(Integer.valueOf(holdOutDates.InitialNumberofDays__c));
                   ctctsToUpdateMap.put(ctct.Id, ctct);
                   // todo - have to set account
                   if (ref.Account__r != null && !ref.Account__r.Hold_Out__c) {
                      ref.Account__r.OwnerId = ref.OwnerId;
                      ref.Account__r.Hold_Out__c=true;
                      ref.Account__r.Permanent_Hold_Out_Description__c=holdOutDates.Name;
                      ref.Account__r.Hold_Out_Expiration__c=Date.today().addDays(Integer.valueOf(holdOutDates.InitialNumberofDays__c));
                      acctsToUpdateMap.put(ref.Account__r.Id,ref.Account__r);
                   }
                }
            } else if (ownedByUser && ref.SourceLead__c != null && !handled && !ref.SourceLead__r.IsConverted) {
                Boolean leadUpdated = false;
                if (ref.OwnerId != ref.SourceLead__r.OwnerId ) {
                   system.debug('syncRelatedOwners ref='+ref.Name+' updating lead owner');
                   ref.SourceLead__r.OwnerId = ref.OwnerId;
                   refNotes += ('; updating lead owner to '+ref.SourceLead__r.OwnerId);
                   leadUpdated = true;
                }
                if (holdOutDates != null && !ref.SourceLead__r.Hold_Out__c) {
                   // TODO - if there's already a holdout do we skip?
                   ref.SourceLead__r.Hold_Out__c=true;
                   ref.SourceLead__r.Hold_Out_Reason__c=holdOutDates.Name;
                   ref.SourceLead__r.Hold_Out_Expiration__c=Date.today().addDays(Integer.valueOf(holdOutDates.InitialNumberofDays__c));
                   leadUpdated = true;
                }
                if (leadUpdated) {
                   leadsToUpdate.add(ref.SourceLead__r);
                }
            }
            addToProcessNotes(ref,refNotes);
            rfrlsToUpdateMap.put(ref.Id, ref);
        }//for
        if(!leadsToUpdate.isEmpty()){
            DmlHelper.performDML2(leadsToUpdate, DmlHelper.DML_UPDATE, 'ReferralMethods', 'syncRelatedOwnersNow', 'Update Leads owners', false);
        }
        if(!ctctsToUpdateMap.isEmpty()){
            DmlHelper.performDML2(ctctsToUpdateMap.values(), DmlHelper.DML_UPDATE, 'ReferralMethods', 'syncRelatedOwnersNow', 'Update Contact owners', false);
        }
        if(!acctsToUpdateMap.isEmpty()){
            DmlHelper.performDML2(acctsToUpdateMap.values(), DmlHelper.DML_UPDATE, 'ReferralMethods', 'syncRelatedOwnersNow', 'Update Account owners', false);
        }
        if(!opptysToUpdate.isEmpty()){
            //OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
            DmlHelper.performDML2(opptysToUpdate, DmlHelper.DML_UPDATE, 'ReferralMethods', 'syncRelatedOwnersNow', 'Update Opptys owners', false);
            //OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
        }

        if(!rfrlsToUpdateMap.isEmpty()){
            System.debug('syncRelatedOwners rfrlsToUpdateMap first ownerId='+rfrlsToUpdateMap.values()[0].OwnerId);
            ReferralTriggerActions.SKIP_TRIGGER=true;
            DmlHelper.performDML2(rfrlsToUpdateMap.values(), DmlHelper.DML_UPDATE, 'ReferralMethods', 'syncRelatedOwnersNow', 'Update referrals', false);
        }
        ErrorLog.checkSave();
        
   } // syncRelatedOwners
   
   public static final Integer REF_NOTES_SIZE = Referral__c.ProcessNotes__c.getDescribe().getLength();

   public static void addToProcessNotes(Referral__c ref, String notesToAdd) {
      StringHelper.addNotesToField(ref, 'ProcessNotes__c', REF_NOTES_SIZE, notesToAdd, true);
   } // addToProcessNotes

   public static void createActivity(ReferralWrapper rw, Task[] tasksToInsert,Event[] eventsToInsert,String actCallType ,String actSource){

      CreateOppAndMeeting coam = getCoam(rw.ref.User__r.Sales_Org__c,rw.ref.User__r.Sales_Division__c);
      String timeZoneAbbrev = (String.isNotBlank(rw.ref.TimeZoneAbbrev__c) ? rw.ref.TimeZoneAbbrev__c : (rw.ref.Account__c != null ? rw.ref.Account__r.TimeZoneAbbrev__c : null));
      System.debug('createActivity isTask='+rw.ref.CreateSellerTask__c+' isEvent='+rw.ref.CreateSellerEvent__c+' hasOpp='+(rw.oppSelling != null)+' timeZoneAbbrev='+timeZoneAbbrev);
       
      if (!rw.sellingOppWasExisting && rw.ref.CreateSellerTask__c) {
         Task tsk = coam.createTask(rw.ref.Account__r, rw.ref.SourceContact__r, actSource, actCallType);
         tsk.OwnerId = rw.ref.User__c;
         tsk.WhatId = (rw.oppSelling != null ? rw.oppSelling.Id : rw.ref.Referral_Contact__c);
         tsk.WhoId = rw.ref.SourceContact__c;
         tsk.ProductReferred__c = rw.ref.ProductReferred__c;
         tsk.TimeZoneAbbrev__c = timeZoneAbbrev;
         // keep track to set the activityId on the referral
         rw.tsk = tsk;
         tsk.ActivityDate = rw.ref.ActivityDate__c;
         tasksToInsert.add(tsk);
         StringHelper.addToProcessNotes(rw.ref,'Created new Task with date '+tsk.ActivityDate);
      } else if (!rw.sellingOppWasExisting && rw.ref.CreateSellerEvent__c && rw.ref.ActivityDate__c != null && rw.ref.ActivityDateTime__c != null) {
         Event evt = coam.createEvent(rw.ref.Account__r, rw.ref.SourceContact__r,rw.ref.Referral_Contact__r, actSource, actCallType);
         evt.OwnerId = rw.ref.User__c;
         evt.WhatId = (rw.oppSelling != null ? rw.oppSelling.Id : rw.ref.Referral_Contact__c);
         evt.WhoId = rw.ref.SourceContact__c;
         evt.ActivityDateTime = rw.ref.ActivityDateTime__c;
         evt.ActivityDate = rw.ref.ActivityDate__c;
         evt.ProductReferred__c = rw.ref.ProductReferred__c;
         evt.TimeZoneAbbrev__c = timeZoneAbbrev;
         // keep track to set the activityId on the referral
         rw.evt = evt;
         eventsToInsert.add(evt);
         StringHelper.addToProcessNotes(rw.ref,'Created new Event with date '+evt.ActivityDateTime);
         //System.debug('createActivity evt='+evt);
         }

   } // createActivity

   //Retreive MCT's
   //retrieve MCT if gl case needs to be created
   public static Map<Id, Marketing_Call_Tracking__c> retrieveMCTs(Referral__c[] refs){
      Id[] ldIds = new Id[]{};
      for(Referral__c ref : refs) {
         if (ref.SourceLead__c != null) {
            ldIds.add(ref.SourceLead__r.Id);
         }
      } // for (Referral__c ref
      
      Map<Id, Marketing_Call_Tracking__c> mctMap = new Map<Id, Marketing_Call_Tracking__c>();
      if (!ldIds.isEmpty()) {
         for(Marketing_Call_Tracking__c mct : [select Id
                                                   , gl_Accounting_Professional__c
                                                   , gl_CPA_Company_Name__c
                                                   , gl_CPA_Email__c
                                                   , gl_CPA_First_Name__c
                                                   , gl_CPA_Last_Name__c
                                                   , gl_CPA_Phone__c
                                                   , gl_CPA_Processing_On_Your_Behalf__c
                                                   , gl_Current_Client__c
                                                   , gl_Submit_on_behalf_of_Client__c
                                                   , gl_CPA_ZIP_Code__c
                                                   , Lead__c
                                                   , Partner_Referral__c
                                             From Marketing_Call_Tracking__c
                                             Where Lead__c in :ldIds]){
            
            mctMap.put(mct.Lead__c, mct);
         }
      }
        return mctMap;
   }
   public static void createChatterPost(ReferralWrapper rw,Boolean hasNSS,ChatterWrapper[] chatterPosts) {
      //System.debug('WE MADE IT INTO CREATE CHATTER POST!');
      //System.debug('hasNSS is set to :'+ hasNSS);
      ChatterWrapper chatterPost = null; 

      Boolean ownerIsQueue = ((String)rw.ref.OwnerId).startsWith(ObjectHelper.PREFIX_GROUP);  
      if (hasNSS && !rw.ref.Original_Owner_was_Queue__c) {
         chatterPost = new ChatterWrapper();
         if (rw.ref.Started_From__c =='Referral_Contact__c'){
            chatterPost.objectId = rw.ref.Referral_Contact__c; 
         } else {
            chatterPost.objectId = rw.oppSelling.Id;
         }               
         chatterPost.addMentionId(rw.ref.Referring_User__c);
         chatterPost.addMentionId(rw.ref.Referring_User__r.ManagerId);

         //chatterPost.referringUserId = rw.ref.Referring_User__c;
         chatterPost.addMentionId(rw.ref.User__c);

         if (rw.ref.User__r != null) {
           /* if(rw.ref.Started_From__c !='Referral_Contact__c'){
               chatterPost.addMentionId(rw.ref.User__r.DSA_FSS__c);
            }*/
            chatterPost.addMentionId(rw.ref.User__r.ManagerId);
         } else {
           // chatterPost.addMentionId(rw.ref.DSA__c);
            chatterPost.addMentionId(rw.ref.DSM__c);
         }
         chatterPost.notes = rw.ref.Notes__c;
      } // if (hasNSS && !rw.ref.Original_Owner_was_Queue__c
      checkChatterMessage(rw, chatterPost, null, chatterPosts,null);
   } // createChatterPost
   
   public static Case createCase(Referral__c ref, Map<Id,Marketing_Call_Tracking__c> mctMap){
      Case glCase = new Case();
     
      Marketing_Call_Tracking__c mct = ref.SourceLead__c!=null ? mctMap.get(ref.SourceLead__c) : null;
      glCase.ContactId = ref.SourceContact__c;
      glCase.RecordTypeId = ref.Referral_Partner__r.Case_RecordTypeId__c;
      glCase.Status = 'New';
      glCase.Reassign_Category_1__c = 'GL Onboarding';
      glCase.OwnerId = Label.GL_Sales_Submission;
    
      StringHelper.addToProcessNotes(ref,'Created new gl Case ');
      return glCase;
   }
    
   public static Integer DSALookupBack = Integer.valueOf(Label.DSALookBack);
   
   public static void updateDSAOpptyRefJoin(Id[] oppIds, Integer attemptNbr) {
      System.debug('updateDSAOpptyRefJoin DSALookupBack='+DSALookupBack);
      // method to turn this off
      if (DSALookupBack == 0 || oppIds.isEmpty()) {
          return;
      }
      ErrorLog__c log = ErrorLog.getLog(QUEUEABLE_NAME);
      log.ObjectId__c = oppIds[0];
      // how far back to we look back for the actions?
      Datetime dateCheck = Datetime.now().adddays(DSALookupBack);
      System.debug('updateDSAOpptyRefJoin dateCheck >> '+dateCheck);
      
      log.NbrRetries__c = attemptNbr;
      String logData = 'DateCheck='+dateCheck+' \noppIds='+oppIds;
      Opportunity[] opps = [Select Id, OwnerId, AccountId, ReferralLookup__c, ReferralLookup__r.ReferralJoin__c, CreatedById
                                  ,Referring_Employee__c, Referring_Employee__r.User_Lookup__c
                              From Opportunity
                             Where Id in :oppIds];
      Set<Id> ownerIdSet = new Set<Id>();
      // should only be one opportunity at a time here since we're only pulling in the primary
      Map<Id,Opportunity> byAcctIdMap = new Map<Id,Opportunity>();
      for (Opportunity opp : opps) {
         if (opp.OwnerId != null) {
            ownerIdSet.add(opp.OwnerId);
         }
         if (opp.Referring_Employee__c != null && opp.Referring_Employee__r.User_Lookup__c != null) {
            ownerIdSet.add(opp.Referring_Employee__r.User_Lookup__c);
         }
         if (opp.CreatedById != null) {
            ownerIdSet.add(opp.CreatedById);
         }
         if (opp.AccountId != null) {
            byAcctIdMap.put(opp.AccountId, opp);
         }
      } // for (Opportunity opp : opps
      System.debug('updateDSAOpptyRefJoin oppIds='+oppIds.size()+' ownerIdSet='+ownerIdSet.size()+' byAcctIdMap='+byAcctIdMap.size());
      log.BatchSize__c = opps.size();
      logData += '\nownerIdSet='+ownerIdSet+' \nbyAcctIdMap='+byAcctIdMap.size();
      //System.debug('updateDSAOpptyRefJoin oppIds='+oppIds+' ownerIdSet='+ownerIdSet+' acctIds='+byAcctIdMap.keySet());
      if (!byAcctIdMap.isEmpty()) {
          Map<Id,DS_Denali__DialSource_Action__c> updateActionMap = new Map<Id,DS_Denali__DialSource_Action__c>(); 
          DS_Denali__DialSource_Action__c[] actions = [Select Id,CreatedDate, DS_Denali__Opportunity__c,Referral_Joins_ID__c
                                                             ,DS_Denali__Owner__c
                                                             ,DS_Denali__Account__c
                                                             ,DS_Denali__Call_Disposition__c 
                                                         from DS_Denali__DialSource_Action__c 
                                                        where createdDate >= :dateCheck 
                                                          AND DS_Denali__Owner__c in :ownerIdSet 
                                                          AND DS_Denali__Opportunity__c = null 
                                                          AND DS_Denali__Account__c in :byAcctIdMap.keySet()
                                                       ORDER BY CreatedDate desc];
         logData += '\nactions='+actions.size();
         for (DS_Denali__DialSource_Action__c action : actions) {
            // we only want the opp to be set once, so remove from the map
            Opportunity opp = byAcctIdMap.remove(action.DS_Denali__Account__c);
            logData += '\naction='+action.Id+' opp found='+(opp != null);
            if (opp != null && (opp.CreatedById == action.DS_Denali__Owner__c
                                || (opp.Referring_Employee__c != null && opp.Referring_Employee__r.User_Lookup__c == action.DS_Denali__Owner__c))) {
               logData += '\naction found for opp '+opp.Id+' with the owner match';
               DS_Denali__DialSource_Action__c updateAction = new DS_Denali__DialSource_Action__c(Id=action.Id, DS_Denali__Opportunity__c=opp.Id);
               if (opp.ReferralLookup__c != null && opp.ReferralLookup__r.ReferralJoin__c != null) {
                  updateAction.Referral_Joins_ID__c = opp.ReferralLookup__r.ReferralJoin__c;
               }
               updateActionMap.put(updateAction.Id, updateAction);
            } else if (opp != null) {
               logData += '\naction found for opp '+opp.Id+', owner does not match';
               // if the owner doesn't match, put the opp back in the map
               byAcctIdMap.put(action.DS_Denali__Account__c,opp);
            }
         } // for (DS_Denali__DialSource_Action__c action
         log.NbrSuccess__c = updateActionMap.size();
         if (!updateActionMap.isEmpty()) {
            DmlHelper.performDML2(updateActionMap.values(), DmlHelper.DML_UPDATE, QUEUEABLE_NAME, 'updateDSAOpptyRefJoin', 'Update DSA from Referral', true);
         }
      } // if (!byAcctIdMap.isEmpty
      System.debug('updateDSAOpptyRefJoin byAcctIdMap='+byAcctIdMap.size());
      logData += '\nUnmatched records left='+byAcctIdMap.size();
      if (!byAcctIdMap.isEmpty() ) {
         Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(QUEUEABLE_NAME);
         Integer nbrAttempts = ((abc != null && abc.Active__c && abc.NbrOfAttempts__c!=null) ? Integer.valueOf(abc.NbrOfAttempts__c) : 0);
         log.MaxRetries__c = nbrAttempts;
         //logData += '\nnbrAttempts='+nbrAttempts+' attemptNbr='+attemptNbr;
         System.debug('updateDSAOpptyRefJoin abc='+abc);
         if (nbrAttempts > attemptNbr) {
            Id[] v_oppIds = new Id[]{};
            for (Opportunity opp : byAcctIdMap.values()) {
               v_oppIds.add(opp.Id);
            }
            Integer delay = (abc.Minutes_till_Launch__c != null ? Integer.valueOf(abc.Minutes_till_Launch__c) : 2);
            logData += '\nRelaunching queueable v_oppIds='+v_oppIds.size()+' delay='+delay;
            System.debug('updateDSAOpptyRefJoin v_oppIds='+v_oppIds.size()+' delay='+delay);
            DsaQueueable dsaQ = new DsaQueueable(v_oppIds,attemptNbr+1);
            System.enqueueJob(dsaQ,delay);
         }
           
      } // if (!byAcctIdMap.isEmpty()
      ErrorLog.addToDescription(log,logData);
      ErrorLog.saveLog(log);
   } // updateDSAOpptyRefJoin

   public static String QUEUEABLE_NAME='ReferralMethodsDsaQueueable';

   public class DsaQueueable implements Queueable {
      public Id[] oppIds;
      public Integer attemptNbr;
      public DsaQueueable(Id[] p_oppIds, Integer p_attemptNbr) {
         oppIds = p_oppIds;
         attemptNbr = p_attemptNbr;
      } // DsaQueueable
       
      public void execute(QueueableContext context) {
         ReferralMethods.updateDSAOpptyRefJoin(oppIds,attemptNbr);
      } // execute

   } // DsaQueueable
       
} // class ReferralMethods