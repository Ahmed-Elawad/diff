/* 
 * Batch process to update ownership on Accounts, Contacts, and Leads
 *
 * History
 * -------
 * 04/24/2012 Dan Carmen   Created
   06/14/2012 Dan Carmen   Fix for hold outs.
   06/27/2012 Dan Carmen   Update for making email more verbose.
   06/28/2012 Dan Carmen   Modified to use JobHelper class
   06/24/2013 Dan Carmen   Use the Emp/Asset on the zip segment instead of zip assignment record
   06/27/2013 Dan Carmen   Fix the max asset value = 12 digit max number is causing SOQL errors.
   03/11/2014 Dan Carmen   Changes for NSS
   06/12/2014 Dan Carmen   Changes to handle the lead hold out field
   12/09/2014 Dan Carmen   Simplify queries to attempt to improve performance.
   06/04/2015 Dan Carmen   Changes to work with Referrals
   07/29/2015 Dan Carmen   Disable lead triggers during batch execution
   01/04/2016 Dan Carmen   Make the Lead query generation more dynamic.
   06/30/2016 Dan Carmen   Ability to assign ownership on referrals based on record type
   07/20/2016 Dan Carmen   Fix for Referral account ownership with the core ownership
   09/22/2016 Dan Carmen   Turn off sync for Referral update.
   10/14/2016 Cindy Freeman     Added Zip_Assignment__r.CriteriaToSkip__c to query
   01/12/2017 Cindy Freeman     Added isChild = false to Account/Contact query so we don't change ownership on children accounts
   02/23/2017 Dan Carmen        Use the Lead RecordTypeId instead of reference through the object.
   03/01/2017 Dan Carmen        Always save the queries on the zip change record instead of error log.
   03/14/2017 Dan Carmen        Additional process tracking
   07/22/2017 Cindy Freeman     Added custom label and code to push Parent account owners down to children
   02/12/2018 Dan Carmen        Configurable limit for contacts.
   06/01/2018 Cindy Freeman    changed getRecordTypeIdString to be able to exclude some record types based on custom setting   
   03/05/2018 Jacob Hinds    Adding in multiple record types for zip segment query for AcctRecordTypeName__c and RfrlRecordTypeName__c
   05/24/2019 Dan Carmen      Replace MAX_BATCH with a value from the custom setting
   06/18/2019 Dan Carmen      Modify logic to handle multiple record type names
   07/10/2019 Dan Carmen      Fix query for getAccountTeamQuery - handling of record type names
   08/13/2019 Dan Carmen      Small change to the query for optimization
   07/09/2020 Dan Carmen      Oasis PEO Owner fields
   07/16/2020 Dan Carmen      Change to fix account team query (query only by user id, not role name)
   12/11/2020 Brandon Vidro   Added call to CadenceOwnerCheck.checkAccounts after records are saved
   02/08/2021 Brandon Vidro   APR0111339 Post-Imp - use ownerFieldName instead of OwnerId in checkAcctOwner
   05/25/2021 Dan Carmen      Added ability to run changes in descending created date order for flexibility
   08/18/2021 Dan Carmen      Changed the method used going into CadenceOwnerCheck, add in Referral Accounts
   11/08/2021 Jermaine Stukes  Removed references to external wholesaler owner fields
   08/19/2022 Shilpa G      Added Lost Client logic
   12/29/2022 Dan Carmen       Added DmlOption to skip Salesforce Duplicate Management
   04/05/2023 Jaipal           BAU APR0147082: PEO Client ownership: US1-US3---Changed the parameter from string to pass the Object and added the query
   05/19/2023 Dan Carmen       Fix Client Type query
   08/02/2023 Dan Carmen       Fix for Attempt to de-reference a null object, Zip Code Information isn't always there
   10/05/2023 Shilpa G         APR0151946: Updated method 'checkObjectOwner' to set Hold Out Reason if available on Zip Segment when owner is changed
   01/02/2024 Dan Carmen       Additional linkage for ZipSegmentCriteriaLink__c for more flexibility
   04/24/2024 Shilpa G       APR0157517: Updated method getAcctQuery to add field Clear_Sales_Team__c to the query
   05/06/2024 Shilpa G       APR0164310: Updated method getAcctSegmentQuery to include query for Client Type Operand Not Equals
 */
global with sharing class ZipBatch implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

   /** The number of change records processed. */
   global Integer numberChangeRecords = 0;
   // new change records created (because we've hit the limit)
   global Integer numberChangeRecordsCreated = 0;
   
   /** Use this object to keep track of counts. This is not saved. */
   global Zip_Assignment_Change__c totalChanges;
   
   /** Keep track of totals by Sales Org and segment name. */
   global Map<String,Map<String,Zip_Assignment_Change__c>> changeByOrgMap = new Map<String,Map<String,Zip_Assignment_Change__c>>();
   
   /** For testing only */
   global String[] testingZips = null;
   
   global String processingMsg = '';
   
   global String batchMsg = '';
   
   global JobHelper jh = new JobHelper('ZipBatch');
   
   // do we want to log the query to the ErrorLogs object?
   //static Boolean LOG_QUERY= (String.isNotBlank(Label.ZipBatchLogAllQueries) && Label.ZipBatchLogAllQueries == 'Y');
   
   //static String SALES_ORG_OVERRIDE=Label.ZipBatchSalesOrgOverride;
   
   global String salesOrgOverride = Label.ZipBatchSalesOrgOverride;
   
   public static Integer QUERY_LENGTH=Zip_Assignment_Change__c.QueryAccount__c.getDescribe().getLength();

   public static Integer TRACKER_LENGTH=Zip_Assignment_Change__c.ProcessTracker__c.getDescribe().getLength();

   public static void addToProcessTracker(Zip_Assignment_Change__c zac, String sectionName, Datetime startTime, DateTime endTime, long p_millisecs, String otherMsg) {
      String textToAdd = (String.isBlank(zac.ProcessTracker__c) ? '' : zac.ProcessTracker__c+'\n')+sectionName;
      long millisecs = p_millisecs;
      if (startTime != null && endTime != null) {
         millisecs = endTime.getTime() - startTime.getTime();
      }
      if (millisecs != null) {
         textToAdd += 'Seconds: '+(Integer.valueOf(millisecs/1000)+'('+millisecs+' milli)');
      }
      
      if (String.isNotBlank(otherMsg)) {
         textToAdd += ', '+otherMsg;
      }
      zac.ProcessTracker__c = textToAdd.left(TRACKER_LENGTH);
   } // addToProcessTracker
   
   /** Default constructor.
    */
   global ZipBatch() {
      setup();
   } // NSSZipBatch
   
   public void setup() {
      totalChanges = new Zip_Assignment_Change__c();
      initializeChange(totalChanges);
   } // setup
   
   global ZipBatch(String p_salesOrgOverride) {
      salesOrgOverride = (String.IsNotBlank(p_salesOrgOverride) ? p_salesOrgOverride : 'N');
      setup();
   } // ZipBatch
   
   public void initializeChange(Zip_Assignment_Change__c change) {
      // set the start time
      change.Process_Start__c = System.now();
      change.Description__c = '';

      // default the counts to 0
      change.Accounts_Updated__c = 0;
      change.Contacts_Updated__c = 0;
      change.Leads_Updated__c = 0;
      change.Referral_Accounts_Updated__c = 0;
      change.Referral_Contacts_Updated__c = 0;
      change.RecordTypeUpdated__c = 0;
      change.AccountTeamsUpdated__c = 0;
      change.Parent_Accounts_Updated__c = 0;                            // parent
   } // initializeChange
   
   public void initializeChanges(Zip_Assignment_Change__c[] changes) {
      for (Zip_Assignment_Change__c change : changes) {
         initializeChange(change);
      } // for
   } // initializeChanges
   
   public void closeChange(Zip_Assignment_Change__c change, Boolean okay) {
      // in case we need to create new records
      //Zip_Assignment_Change__c[] newChanges = new Zip_Assignment_Change__c[]{};
      
      // set the start time
      change.Process_End__c = System.now();
      change.Processed__c = true;
      // if not okay (wasn't able to complete processing) create a new change record to continue trying to
      // process during the next run.
      
      addToProcessTracker(change, 'closeChange okay='+okay, null, null, null, null);

      update change;
      
      if (!okay) {
         numberChangeRecordsCreated = (numberChangeRecordsCreated == null ? 0 : numberChangeRecordsCreated) + 1;
         Set<Id> idSet = new Set<Id>();
         idSet.add(change.Zip_Assignment__c);
         ZipAssignment.createChangeRecords(idSet);
         //newChanges.add(new Zip_Assignment_Change__c(Zip_Assignment__c=change.Zip_Assignment__c, Zip_Code_Information__c = change.Zip_Code_Information__c));
      } // if (!okay

      //if (!newChanges.isEmpty()) {
      //   insert newChanges;
      //   newChanges.clear();
      //}
   } // closeChange
   
   private void addToTotal(Zip_Assignment_Change__c change, Zip_Segment__c segment) {
      //for (Zip_Assignment_Change__c change : changes) {
         totalChanges.Accounts_Updated__c += change.Accounts_Updated__c;
         totalChanges.Contacts_Updated__c += change.Contacts_Updated__c;
         totalChanges.Leads_Updated__c += change.Leads_Updated__c;
         totalChanges.Referral_Accounts_Updated__c += change.Referral_Accounts_Updated__c;
         totalChanges.Referral_Contacts_Updated__c += change.Referral_Contacts_Updated__c;
         totalChanges.AccountTeamsUpdated__c += change.AccountTeamsUpdated__c;
         totalChanges.RecordTypeUpdated__c += change.RecordTypeUpdated__c;
         totalChanges.Parent_Accounts_Updated__c += change.Parent_Accounts_Updated__c;              // parent
         
         // get a map of the segments
         Map<String,Zip_Assignment_Change__c> changeBySegmentMap = changeByOrgMap.get(change.Zip_Assignment__r.Sales_Org__c);
         if (changeBySegmentMap == null) {
            changeBySegmentMap = new Map<String,Zip_Assignment_Change__c>();
            changeByOrgMap.put(change.Zip_Assignment__r.Sales_Org__c,changeBySegmentMap);
         }
         Zip_Assignment_Change__c changeBySegment = changeBySegmentMap.get(segment.Name);
         
         if (changeBySegment == null) {
            // create a change record
            changeBySegment = new Zip_Assignment_Change__c();
            initializeChange(changeBySegment);
            changeBySegmentMap.put(segment.Name,changeBySegment);
         }
         changeBySegment.Accounts_Updated__c += change.Accounts_Updated__c;
         changeBySegment.Contacts_Updated__c += change.Contacts_Updated__c;
         changeBySegment.Leads_Updated__c += change.Leads_Updated__c;
         changeBySegment.Referral_Accounts_Updated__c += change.Referral_Accounts_Updated__c;
         changeBySegment.Referral_Contacts_Updated__c += change.Referral_Contacts_Updated__c;
         changeBySegment.AccountTeamsUpdated__c += change.AccountTeamsUpdated__c;
         changeBySegment.RecordTypeUpdated__c += change.RecordTypeUpdated__c;
         changeBySegment.Parent_Accounts_Updated__c += change.Parent_Accounts_Updated__c;           // parent
         
      //}
   } // addToTotal
   

   /** The maximum number of records to retrieve at once. Use a percentage of what the limits are - just in case. */
   //global Integer MAX_BATCH=(Limits.getLimitDmlRows() / Integer.valueOf(Label.ZipBatchLimitDivisor));
   global Integer MAX_CTCTS=Integer.valueOf(Label.ZipBatchCtctLimit);
   
   global String[] querySalesOrgs = null;

   // used for testing purposes - ability to run batch for specific zip codes
   global String overrideZips = null;
    
   // to allow us to query in descending order in case we want to run two batches on the same sales org.
   global Boolean sortDescending = false;
   
   // Query the batches to be processed.
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      
      querySalesOrgs = null;
      if (salesOrgOverride != 'N') {
         // allow for the ability to run only for certain sales orgs - to be able to run multiple processes and "share the load"
         querySalesOrgs = salesOrgOverride.split(';');
      } else {
         querySalesOrgs = new String[]{};
         // by default pick which sales orgs to run for.
         for (SalesOrg__c salesOrg : SalesOrg__c.getAll().values()) {
            if (salesOrg.HasOwnership__c) {
               querySalesOrgs.add(salesOrg.Name);
            }
         } // for (SalesOrg__c salesOrg
      }
      
      if (String.isNotBlank(overrideZips)) {
         String[] queryZips = overrideZips.split(',');
         return Database.getQueryLocator([SELECT id
                                             ,Accounts_Updated__c
                                             ,AccountTeamsUpdated__c
                                             ,Contacts_Updated__c
                                             ,Description__c
                                             ,Leads_Updated__c
                                             ,OwnershipType__c 
                                             ,Processed__c
                                             ,Process_End__c
                                             ,Process_Start__c
                                             ,ProcessTracker__c
                                             ,QueryAccount__c
                                             ,QueryLead__c
                                             ,QueryRefAcct__c
                                             ,RecordTypeUpdated__c
                                             ,Referral_Accounts_Updated__c
                                             ,Referral_Contacts_Updated__c
                                             ,Parent_Accounts_Updated__c
                                             ,Parent_Process_Start__c
                                             ,Parent_Process_End__c
                                             ,Zip_Assignment__r.Name
                                             ,Zip_Assignment__r.Query_Key__c
                                             ,Zip_Assignment__r.Sales_Org__c
                                             ,Zip_Assignment__r.SkipJoinCriteria__c
                                             ,Zip_Assignment__r.CriteriaToSkip__c
                                             ,Zip_Assignment__r.User__r.Id
                                             ,Zip_Assignment__r.User__r.IsActive
                                             ,Zip_Assignment__r.ZipOkay__c
                                             ,Zip_Assignment__r.Zip_Segment__c
                                             ,Zip_Assignment__r.ZipTerritory__c
                                             ,Zip_Assignment__r.ZipTerritory__r.TerritoryRep__c
                                             ,Zip_Assignment__r.ZipTerritory__r.TerritoryRep__r.Id
                                             ,Zip_Assignment__r.ZipTerritory__r.TerritoryRep__r.IsActive
                                             ,Zip_Code_Information__c
                                             ,Zip_Code_Information__r.Id
                                             ,Zip_Code_Information__r.Name
                                             ,ZipSegment__c
                                         FROM Zip_Assignment_Change__c
                                        WHERE Processed__c = false
                                          AND Zip_Assignment__r.ZipOkay__c = true
                                          AND Zip_Assignment__r.Name in :queryZips
                                        order by CreatedDate ]);
      } // if (String.isNotBlank(overrideZips
      
      if (sortDescending) {
         return Database.getQueryLocator([SELECT id
                                             ,Accounts_Updated__c
                                             ,AccountTeamsUpdated__c
                                             ,Contacts_Updated__c
                                             ,Description__c
                                             ,Leads_Updated__c
                                             ,OwnershipType__c 
                                             ,Processed__c
                                             ,Process_End__c
                                             ,Process_Start__c
                                             ,ProcessTracker__c
                                             ,QueryAccount__c
                                             ,QueryLead__c
                                             ,QueryRefAcct__c
                                             ,RecordTypeUpdated__c
                                             ,Referral_Accounts_Updated__c
                                             ,Referral_Contacts_Updated__c
                                             ,Parent_Accounts_Updated__c
                                             ,Parent_Process_Start__c
                                             ,Parent_Process_End__c
                                             ,Zip_Assignment__r.Name
                                             ,Zip_Assignment__r.Query_Key__c
                                             ,Zip_Assignment__r.Sales_Org__c
                                             ,Zip_Assignment__r.SkipJoinCriteria__c
                                             ,Zip_Assignment__r.CriteriaToSkip__c
                                             ,Zip_Assignment__r.User__r.Id
                                             ,Zip_Assignment__r.User__r.IsActive
                                             ,Zip_Assignment__r.ZipOkay__c
                                             ,Zip_Assignment__r.Zip_Segment__c
                                             ,Zip_Assignment__r.ZipTerritory__c
                                             ,Zip_Assignment__r.ZipTerritory__r.TerritoryRep__c
                                             ,Zip_Assignment__r.ZipTerritory__r.TerritoryRep__r.Id
                                             ,Zip_Assignment__r.ZipTerritory__r.TerritoryRep__r.IsActive
                                             ,Zip_Code_Information__c
                                             ,Zip_Code_Information__r.Id
                                             ,Zip_Code_Information__r.Name
                                             ,ZipSegment__c
                                         FROM Zip_Assignment_Change__c
                                        WHERE Processed__c = false
                                          AND Zip_Assignment__r.ZipOkay__c = true
                                          AND Zip_Assignment__r.Sales_Org__c in :querySalesOrgs
                                        order by CreatedDate desc ]);
      }

      // for normal running - oldest is run first.
      return Database.getQueryLocator([SELECT id
                                             ,Accounts_Updated__c
                                             ,AccountTeamsUpdated__c
                                             ,Contacts_Updated__c
                                             ,Description__c
                                             ,Leads_Updated__c
                                             ,OwnershipType__c 
                                             ,Processed__c
                                             ,Process_End__c
                                             ,Process_Start__c
                                             ,ProcessTracker__c
                                             ,QueryAccount__c
                                             ,QueryLead__c
                                             ,QueryRefAcct__c
                                             ,RecordTypeUpdated__c
                                             ,Referral_Accounts_Updated__c
                                             ,Referral_Contacts_Updated__c
                                             ,Parent_Accounts_Updated__c
                                             ,Parent_Process_Start__c
                                             ,Parent_Process_End__c
                                             ,Zip_Assignment__r.Name
                                             ,Zip_Assignment__r.Query_Key__c
                                             ,Zip_Assignment__r.Sales_Org__c
                                             ,Zip_Assignment__r.SkipJoinCriteria__c
                                             ,Zip_Assignment__r.CriteriaToSkip__c
                                             ,Zip_Assignment__r.User__r.Id
                                             ,Zip_Assignment__r.User__r.IsActive
                                             ,Zip_Assignment__r.ZipOkay__c
                                             ,Zip_Assignment__r.Zip_Segment__c
                                             ,Zip_Assignment__r.ZipTerritory__c
                                             ,Zip_Assignment__r.ZipTerritory__r.TerritoryRep__c
                                             ,Zip_Assignment__r.ZipTerritory__r.TerritoryRep__r.Id
                                             ,Zip_Assignment__r.ZipTerritory__r.TerritoryRep__r.IsActive
                                             ,Zip_Code_Information__c
                                             ,Zip_Code_Information__r.Id
                                             ,Zip_Code_Information__r.Name
                                             ,ZipSegment__c
                                         FROM Zip_Assignment_Change__c
                                        WHERE Processed__c = false
                                          AND Zip_Assignment__r.ZipOkay__c = true
                                          AND Zip_Assignment__r.Sales_Org__c in :querySalesOrgs
                                        order by CreatedDate asc]);

   } // start
   
   /** In order to schedule a batch run
    */
   global void execute(SchedulableContext sc) {
      ZipBatch nzb = new ZipBatch();
      database.executeBatch(nzb, 1);
   } // execute

   global long milliAccts = 0;
   global long milliCtcts = 0;
   global long milliAcctTeams = 0;
   
   global Set<Id> parentAcctIdSet = new Set<Id>();                              // parent

   global void execute(Database.BatchableContext BC, List<SObject> scope) {
      
      // disable trigger code to minimize processing
      LeadCompanyMethods.CALCULATE_SIGNIFICANCE = false;
      AccountMethods.CALCULATE_SIGNIFICANCE = false;
      ZipCheckOwner.SKIP_TRIGGERS = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      LeadMethods.LEAD_BEFORE_EXECUTING = true;
      LeadMethods.LEAD_AFTER_EXECUTING = true;
     // AccountPartnerSync.SKIP_TRIGGER = true;
      TriggerMethods.disablePackageTriggers();

      List<Zip_Assignment_Change__c> zipChanges = (List<Zip_Assignment_Change__c>)scope;
      System.debug('ZipBatch number of zipChanges='+zipChanges.size());
      checkSalesOrgs();

      // so we don't have to maintain the segment fields separately.
      Zip_Segment__c[] segments = ZipQueries.getAllSegments();
      Map<Id,Zip_Segment__c> segMap = new Map<Id,Zip_Segment__c>(segments);
      System.debug('ZipBatch.execute segMap='+segMap.size());

      // loop through the zip codes
      for (Zip_Assignment_Change__c zca : zipChanges) {
         // get the segment for this change
         Zip_Segment__c segment = (zca.ZipSegment__c != null ? segMap.get(zca.ZipSegment__c) : segMap.get(zca.Zip_Assignment__r.Zip_Segment__c));
         System.debug('ZipBatch.execute zip='+zca.Zip_Assignment__r.Name+' segment='+(segment != null ? segment.Name : 'No Segment')+' zaId='+zca.Zip_Assignment__c);
         if (!zca.Processed__c && segment != null) {
         try {
            parentAcctIdSet.clear();                                        // parent
            // keep track of the number of zip codes
            //BAU Changes//Apex Scan Code
            String zipCode = zca.Zip_Code_Information__r != null ? zca.Zip_Code_Information__r.Name : zca.Zip_Assignment__r.Name;
            //zca.Zip_Code_Information__r.Name=zca.Zip_Code_Information__r.Name!=null?String.escapeSingleQuotes(zca.Zip_Code_Information__r.Name):null;
            numberChangeRecords ++;
            processingMsg = '';
            System.debug('Processing changes for zip='+zipCode+' segment='+(segment != null ? segment.Name : 'None')+' sales org='+(segment != null ? segment.Sales_Org__c : 'None'));
            System.debug('ZipBatch numberChangeRecords='+numberChangeRecords);
            // default the counts to 0
            Zip_Assignment_Change__c[] changes = new Zip_Assignment_Change__c[]{zca};
            initializeChanges(changes);
            
            //Boolean okay = checkZipCodeUsers(zca);
            Boolean okay = true;
            // can continue as long as at least one owner we can use
            if (okay) {
               milliAccts = 0;
               milliCtcts = 0;
               milliAcctTeams = 0;
               
               addToProcessTracker(zca, 'Accounts', null, null, null, 'Processing Accounts');

               // search for accounts/contacts where the owner is not equal
               okay = processAcctsCtcts(zipCode,zca,segment);
               // since contacts and account teams are processed within the acct loop, subtract them from the total
               milliAccts = milliAccts - (milliCtcts + milliAcctTeams);
               addToProcessTracker(zca, 'after processAcctsCtcts okay='+okay, null, null, null, null);
               addToProcessTracker(zca, 'Acct Processing', null, null, milliAccts, null);
               addToProcessTracker(zca, 'Ctct Processing', null, null, milliCtcts, null);
               addToProcessTracker(zca, 'AcctTeam Processing', null, null, milliAcctTeams, null);
               
               if (okay && (String.isBlank(zca.OwnershipType__c) || zca.OwnershipType__c == ZipAssignment.CHANGE_OWNER_FIELD)) {
                  addToProcessTracker(zca, 'Accounts', null, null, null, 'Processing Referral Accounts');
                  okay = processReferrals (zipCode,zca,segment);
                  addToProcessTracker(zca, 'after processReferrals okay='+okay, null, null, null, null);
               }
               if (okay && (String.isBlank(zca.OwnershipType__c) || zca.OwnershipType__c == ZipAssignment.CHANGE_OWNER_FIELD)) {
                  addToProcessTracker(zca, 'Accounts', null, null, null, 'Processing Leads');
                  // search for Leads where the owner is not equal
                  okay = processLeads(zipCode,zca, segment);
                  addToProcessTracker(zca, 'after processLeads okay='+okay, null, null, null, null);
               }

               addToTotal(zca,segment); 
          
            } // if (checkZipCodeUsers

            // if any Parents had an owner changed, call method to push new owners down to children         // parent           
            if (Label.ZipBatch_pushParentToChildren == 'Y' && !parentAcctIdSet.isEmpty())
            {   zca.Parent_Accounts_Updated__c = parentAcctIdSet.size();
                zca.Parent_Process_Start__c = System.now();
                List<Id> parentAcctIdList = new List<Id>(parentAcctIdSet);              
                System.debug('**ZipBatch.execute-calling AccountJunctionMethods.pushParenttoChild, parentAcctIdList size='+parentAcctIdList.size());                
                AccountJunctionMethods.pushParenttoChild(null, parentAcctIdList);
                zca.Parent_Process_End__c = System.now();
            }
            
            System.debug('okay='+okay+' acctsUpdated='+totalChanges.Accounts_Updated__c+' ctctsUpdated='+totalChanges.Contacts_Updated__c+' leadsUpdated='+totalChanges.Leads_Updated__c+' parentsUpdated='+totalChanges.Parent_Accounts_Updated__c);
            // set that these rows were processed.
            closeChange(zca,okay);
            // if not okay we don't want to continue - probably hitting limits for this transaction.
            if (!okay) {
               break;
            }
         } catch (Exception ex) {
            zca.Exception__c = true;
            ErrorLog.logError('ZipBatch', 'execute', 'general exception', zca.Id, ex, zca, false);
         }
         } // if (!zca.Processed__c
      } // for (Zip_Code_Information__c

      ErrorLog.checkSave();
   } // execute
   
   public static Integer OWNER_ID_DIVISOR = Integer.valueOf(Label.ZipBatch_OwnerIdLimit);
   
   /** Process the changes for the accounts and contacts.
    */
   public Boolean processAcctsCtcts(String zipCode, Zip_Assignment_Change__c zca, Zip_Segment__c segment) {
      Boolean okay=true;
      zca.AccountsStart__c = DateTime.now();
      // process contacts first
      String acctQuery = getAcctQuery(zipCode,zca,segment);
      if (acctQuery != null) {
         Integer maxBatch = getMaxBatch();
         //Integer maxBatch = MAX_BATCH;
         if (OWNER_ID_DIVISOR > 1 && segment.AcctOwnerFldName__c == 'OwnerId') {
            maxBatch = Integer.valueOf(maxBatch/OWNER_ID_DIVISOR);
         }
         acctQuery += ' Limit '+maxBatch;
         System.debug('processAcctsCtcts acctQuery='+acctQuery);
         zca.QueryAccount__c = (acctQuery != null ? acctQuery.left(QUERY_LENGTH) : null);
         addToProcessTracker(zca, 'Build Acct Query', zca.AccountsStart__c, DateTime.now(), null, null);
        
         okay = executeAcctQuery(ObjectHelper.OBJECT_ACCOUNT,acctQuery,zca,zipCode,segment,maxBatch);
      } // if (acctQuery != null

      zca.AccountsEnd__c = DateTime.now();
      // todo - if we process MAX_BATCH number of accounts, return false.
      return okay;
   } // processAcctsCtcts
   
   /** Process the changes for the referral accounts and contacts.
    */
   public Boolean processReferrals(String zipCode, Zip_Assignment_Change__c zca, Zip_Segment__c segment) {
      ReferralObjectsSync.SKIP_SYNC = true;
      zca.ReferralsStart__c = DateTime.now();
      // process contacts first
      String acctQuery = getRefAcctQuery(zipCode,zca, segment);
      if (acctQuery != null) {
         Integer maxBatch = getMaxBatch();
         acctQuery += ' Limit '+maxBatch;
         System.debug('processReferrals acctQuery='+acctQuery);
         zca.QueryRefAcct__c = (acctQuery != null ? acctQuery.left(QUERY_LENGTH) : null);
        
         if (!executeAcctQuery(ObjectHelper.OBJECT_REF_ACCOUNT,acctQuery,zca,zipCode,segment,maxBatch)) {
            return false;
         }
      } // if (acctQuery != null
      zca.ReferralsEnd__c = DateTime.now();
      ReferralObjectsSync.SKIP_SYNC = false;
      return true;
   } // processReferrals
   
   /** Check the leads to see if the ownership needs to change.
    */
   private boolean processLeads(String zipCode, Zip_Assignment_Change__c zca, Zip_Segment__c segment) {
      zca.LeadsStart__c = DateTime.now();
      String query = getLeadQuery(zipCode, zca, segment);
      System.debug('Lead query='+query);
      zca.QueryLead__c = (query != null ? query.left(QUERY_LENGTH) : null);

      if (query != null) {
         for (SObject[] results : Database.query(query)) {
            // go through results, update owner
            List<Lead> updateLeads = new List<Lead>();
            for (SObject so : results) {
               Lead lead = (Lead)so;
               if (checkLeadOwnerChange(lead, zca)) {
                  updateLeads.add(lead);
               } // if
            } // for (SObject so
            System.debug('number of leads to update='+updateLeads.size());
            if (!checkLimits(zca, zipCode,'leads',updateLeads.size())) {
               return false;
            }
            // update records
            List<Database.SaveResult> uResults = Database.update(updateLeads,false);
            // check to make sure all success
            Integer numSuccess = 0;
            for (Database.SaveResult sr : uResults) {
               if (sr.isSuccess()) { 
                  numSuccess++;
               //} else {
               //   String errorStr = '';
               //   for (Database.Error err : sr.getErrors()) {
               //      errorStr += err.getMessage();
               //   }
               //   System.debug('Error='+errorStr);
               }
            }
            // TODO - do we want to capture the errors??
            System.debug('Number of leads for zip '+zipCode+'='+updateLeads.size()+' numSuccess='+numSuccess);
         } // for (SObject[] results
         
      } // if (query != null)
      zca.LeadsEnd__c = DateTime.now();
      return true;
   } // processLeads
   
   /** Get the query to select the leads.
    */
   private String getLeadQuery(String zipCode, Zip_Assignment_Change__c zac, Zip_Segment__c segment) {
      String query = null; 
      
      Zip_Assignment__c za = zac.Zip_Assignment__r;
      ZipTerritory__c territory = za.ZipTerritory__r;
      
      if (String.IsNotBlank(segment.LeadRecordTypeId__c)
          && !zac.Processed__c && territory != null
          && territory.TerritoryRep__r != null
          && territory.TerritoryRep__r.IsActive) {
             
            // must have a record type to proceed
            query = 'Select Id, Name, NumberOfEmployees, X401K_Assets__c, RecordType.Name, OwnerId ';
            //query += ZipCheckOwner.getLeadSettingQueryFlds();
            //String extraQuery = DmlHelper.buildStringFromSet(ZipQueries.getLeadQueryFields());
            //if (String.isNotBlank(extraQuery)) {
            //   query += (', '+extraQuery);
            //}

            query += ' from Lead where IsConverted=false and PostalCode like \''+zipCode+'%\' ';
            query += getRecordTypeQueryString(segment.LeadRecordTypeId__c);
            query += getOwnerQuery('and',ObjectHelper.OBJECT_LEAD,'OwnerId',territory.TerritoryRep__c,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_LEAD,za.Sales_Org__c),za,segment);
            query += checkOtherCriteria(segment, false, true, false);

      }
      return query;
   } // getLeadQuery
   
   public Boolean checkLeadOwnerChange(Lead l, Zip_Assignment_Change__c zca) {
      System.debug('checkLeadOwnerChange for '+l.Name);
      //for (Zip_Assignment_Change__c zca : changes) {
      Boolean okay = (!zca.Processed__c && checkObjectOwner(ObjectHelper.OBJECT_LEAD, 'OwnerId', null,null,null, l, zca, false, null));
      return okay;
   } // checkLeadOwnerChange
   
   global static Map<String,Id> recordTypeIdMap = new Map<String,Id>();
//   global static String acctRecordIdString = null;
   global static Map<String,String> recordTypeIdStringMap = new Map<String,String>(); 
   
   // this is here so it doesn't break other code (CreateOppAndMeeting and ReferralController)
   public void setupRecordTypeIds() {
      getRecordTypeIdString(ObjectHelper.OBJECT_ACCOUNT);
   } // setupRecordTypeIds
   /*
   public String getRecordTypeIdString(String objectName, String[] recordTypeNames) {
      String recordIdString = '';
      if (recordTypeNames != null && !recordTypeNames.isEmpty()) {
         Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
         RecordTypeHelper.getRecordTypesMap(new String[]{objectName}, recordTypeNames, null, byName);
         if (!byName.isEmpty()) {
            for (Schema.RecordTypeInfo rtInfo : byName.values()) {
               if (String.isBlank(recordIdString)) {
                  recordIdString = ' and RecordTypeId in (\''+rtInfo.getRecordTypeId()+'\'';
               } else {
                  recordIdString += ',\''+rtInfo.getRecordTypeId()+'\'';
               } 
            }
            if (String.isNotBlank(recordIdString)) {
               recordIdString += ') ';
            }
         }
      } else {
         recordIdString = getRecordTypeIdString(objectName);
      }
      return recordIdString;
   } // getRecordTypeIdString
   */
   public static String getRecordTypeQueryString(String idString) {
      String retVal = '';
      if (String.isNotBlank(idString)) {
         String[] idTokens = idString.split(ZipAssignment.ID_SEPARATOR);
         retVal = makeQueryInClause('RecordTypeId',idTokens,true);
      }
      return retVal;
   } // getRecordTypeQueryString

   /**  UseforDefault on RecordType custom setting  will only include recordtypes that should be used for  
    **  ownership if Zip Segment doesnt specify record type 
  **/   
   public String getRecordTypeIdString(String objectName) {
      String recordIdString = recordTypeIdStringMap.get(objectName);
      if (recordIdString == null) {
         System.debug('ZipBatch.getRecordTypeIdString building recordIdString');
         recordIdString = ' ';
         for (RecordType__c rtSetting : RecordType__c.getAll().values()) {
            if (rtSetting.ObjectName__c == objectName && rtSetting.UsedInOwnership__c) {
               Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType(rtSetting.Name, objectName);
               if (rtInfo != null) {
                  recordTypeIdMap.put(rtSetting.Name,rtInfo.getRecordTypeId());
                  if (rtSetting.UseforDefault__c)
                  {    if (String.isBlank(recordIdString)) {
                        recordIdString = ' and RecordTypeId in (\''+rtInfo.getRecordTypeId()+'\'';
                      } else {
                        recordIdString += ',\''+rtInfo.getRecordTypeId()+'\'';
                      } // else
                  }  // if (rtSetting.UseforDefault__c
               } // if(rtInfo)
            }
         } // for (RecordType__c
         if (String.isNotBlank(recordIdString)) {
            recordIdString += ') ';
         }
         recordTypeIdStringMap.put(objectName, recordIdString);
      } // if (recordIdString == null
      System.debug('getRecordTypeIdString objectName='+objectName+' recordIdString='+recordIdString);
      return recordIdString;
      
   } // getRecordTypeIdString


   // Get the account query for the zip code changes.
   public String getAcctQuery(String zipCode, Zip_Assignment_Change__c zca, Zip_Segment__c segment) {
      if (zca.Processed__c) {
          System.debug('getAcctQuery '+zca.Zip_Assignment__r.Name+' already processed!');
          return null;
      }

      // TODO - change to use record type ids when selecting the account/contact, take out the referral owner
      //setupAcctRecordTypeIds();
      Zip_Assignment__c za = zca.Zip_Assignment__r;
      
      User referralOwner = UserHelper.getReferralOwner();

      String query = 'SELECT Id, Name, RecordTypeId, RecordType.Name, NumberOfEmployees, isParent__c '+            // parent
                ',OwnerId, HRS_Account_Owner__c, Premier_PBS_Account_Owner__c,HNBF_Account_Owner__c '+
                ',Hold_Out__c, HRS_Hold_Out__c,Premier_PBS_Hold_Out__c,HNBF_Hold_Out__c '+
                ',OasisPEOAccountOwner__c, OasisPEOHoldOut__c, TAA_Holdout__c '+
                ',X401K_Assets__c, Clear_Sales_Team__c';
      //query += ZipCheckOwner.getAccountSettingQueryFlds();
      //String extraQuery = DmlHelper.buildStringFromSet(ZipQueries.getAccountQueryFields());
      //if (String.isNotBlank(extraQuery)) {
      //   query += (', '+extraQuery);
      //}
	
      //APR0151946: Added segment.AcctHoldOutReasonFld__c to query
      if(String.isNotBlank(segment.AcctHoldOutReasonFld__c)){
      	query += ','+segment.AcctHoldOutReasonFld__c;
      }
      query +=  ',(SELECT Id,AccountId,UserId,User.IsActive,TeamMemberRole from AccountTeamMembers ) '+
                ',(SELECT Id ,Name ,RecordTypeId, RecordType.Name ,OwnerId ,HRS_Contact_Owner__c ,Premier_PBS_Contact_Owner__c,HNBF_Contact_Owner__c, OasisPEOOwner__c '+ 
                ',Hold_Out__c '+
                ' from Contacts '+
                //' Where RecordType.Name in (\''+RecordTypeHelper.CORE_CONTACT+'\',\''+RecordTypeHelper.MMS_CONTACT+'\') '+
                ' Where Sales_Contact__c=true ';
      query += ' order by lastModifiedDate desc limit '+MAX_CTCTS+') '+
                ' from Account '; 
      query += ' where isChild__c = false and Owner_Zip_Code__c = \''+zipCode+'\' ';                     //CMF
       
      query += getAcctSegmentQuery(segment);

      query += getRecordTypeQueryString(segment.AccountRecordTypeIds__c);
      query += checkOtherCriteria(segment, true, false, false);
       
      String[] salesOrgs = (String.isNotBlank(segment.AccountSalesOrg__c) ? segment.AccountSalesOrg__c.split(';') : null);
      if (salesOrgs != null && !salesOrgs.isEmpty()) {
         query += ' and AccountSalesOrg__c in (';
         boolean first = true;
         for (String so : salesOrgs) {
            query += (first ? '' : ',')+'\''+so+'\'';
            first = false;
         }
         query += ') ';
      } // if (salesOrgs != null

      Boolean queryComplete = false;

         ZipTerritory__c territory = za.ZipTerritory__r;
            
         String ownerFieldName = segment.AcctOwnerFldName__c;
         String holdOutFieldName = segment.AcctHoldOutFldName__c;
         String teamRoleName = segment.TeamRole__c;
         User zipUser = ((territory != null && territory.TerritoryRep__r != null && territory.TerritoryRep__r.IsActive) ? territory.TerritoryRep__r
                                 : (za.User__r != null && za.User__r.IsActive ? za.User__r : null));
            
         System.debug('getAcctQuery salesOrg='+za.Sales_Org__c+' recordTypeId='+segment.AccountRecordTypeIds__c+' ownerFieldName='+ownerFieldName+' holdOutFieldName='+holdOutFieldName+' teamRoleName='+teamRoleName+' zipUser='+(zipUser != null ? zipUser.Id : null));

         // if the main owner field, make sure there's a user
         if ((String.isBlank(zca.OwnershipType__c) || zca.OwnershipType__c == ZipAssignment.CHANGE_OWNER_FIELD) &&
              String.isNotBlank(ownerFieldName) && ((ownerFieldName == 'OwnerId' && zipUser != null) || (ownerFieldName != 'OwnerId'))) {
            query += getOwnerQuery('and',ObjectHelper.OBJECT_ACCOUNT,ownerFieldName,(zipUser != null ? zipUser.Id : null),holdOutFieldName,za,segment);
            queryComplete = true;
         } else if (String.IsNotBlank(teamRoleName) && zipUser != null && (zca.OwnershipType__c == ZipAssignment.CHANGE_TEAM_MEMBER || (String.isBlank(zca.OwnershipType__c) && String.isBlank(ownerFieldName)) )) {
            query += getAccountTeamQuery(zipUser.Id, holdOutFieldName, teamRoleName, za, segment );
            queryComplete = true;
         }

      // if we didn't add to the where clause, don't continue
      if (!queryComplete) {
         query = null;
      }
        
      return query;
   } // getAcctQuery
   // BAU APR0147082: PEO Client ownership: US1-US3---Changed the parameter from string to pass the Object and added the query
  public String getAcctSegmentQuery(Zip_Segment__c zipSeg) {
        String segment = zipSeg.Account_Segmentation_Type_Multi__c;
        Boolean clientType = String.isNotBlank(zipSeg.ClientType__c) && String.isNotBlank(zipSeg.ClientTypeOperand__c);
        //String[] clientTypes = clientType ?  zipSeg.ClientType__c.Split(',') : null;
        String clientTypeQuery = '';
        String clientTypeInOp = ' in ';
      
        if(clientType) {   
            
            if(zipSeg.ClientTypeOperand__c.contains('OR')){
            	clientTypeQuery = ' or ';
            }
            else if(zipSeg.ClientTypeOperand__c.contains('AND') || zipSeg.ClientTypeOperand__c.contains('NOT EQUALS')){
                clientTypeQuery = ' and ';
                if(zipSeg.ClientTypeOperand__c.contains('NOT EQUALS')){
                	clientTypeInOp = ' not in ';
                }
            }
            String[] cltTypes = new String[]{};
            for (String cltType : zipSeg.ClientType__c.Split(',')) {
                String value = '\''+cltType+'\'';
                cltTypes.add(value);
            }
            //clientTypeQuery = clientTypeQuery+'Type in ('+String.join(cltTypes,',')+')';
            clientTypeQuery = clientTypeQuery+'Type'+clientTypeInOp+'('+String.join(cltTypes,',')+')';
         } // if(clientType
            String query = '';
            if (String.isNotBlank(segment) && !segment.contains('All')) {
                String[] types = segment.split(';');
                String[] queryAdds = new String[]{};
                    for (String acctType : types) {
                   /*     if (acctType == ZipCheckOwner.TYPE_CLIENT && !clientType) {
                            queryAdds.add(' (CurrentClient__c=true and LostClient__c=false)');
                        } else if (acctType == ZipCheckOwner.TYPE_PROSPECT && !clientType) {
                            queryAdds.add(' (CurrentClient__c=false and LostClient__c=false) ');  
                        } else if (acctType == ZipCheckOwner.TYPE_LOSTCLIENT && !clientType) {
                            queryAdds.add(' LostClient__c=true ');
                        }*/
                          if (acctType == ZipCheckOwner.TYPE_CLIENT) {
                            queryAdds.add(' ((CurrentClient__c=true and LostClient__c=false)'+clientTypeQuery+') ');
                        } else if (acctType == ZipCheckOwner.TYPE_PROSPECT) {
                            queryAdds.add(' ((CurrentClient__c=false and LostClient__c=false)'+clientTypeQuery+') ');  
                        } else if (acctType == ZipCheckOwner.TYPE_LOSTCLIENT) {
                            queryAdds.add(' (LostClient__c=true'+clientTypeQuery+') ');
                        }
                    } // for (String acctType
                if (!queryAdds.isEmpty()) {
                    query += ' and ('+String.join(queryAdds,' or ')+') ';
                }
            } // if (String.isNotBlank
            return query;
        } // getAcctSegmentQuery
   private String getAccountTeamQuery(Id newUserId, String holdoutName, String teamRoleName, Zip_Assignment__c za, Zip_Segment__c segment ) {
      String query = ''; 
      if (String.isNotBlank(holdoutName)) {
         query += ' and '+holdoutName+'=false ';
      }
      query += ' and Id not in (Select AccountId from AccountTeamMember where UserId=\''+newUserId+'\') ';
      query += getAccountJoinCriteria(za, segment);
      return query;
   } // getAccountTeamQuery
   
   /** Get the query string for the owner field.
    */
   private String getOwnerQuery(String whereType, String objectName, String ownerField, Id newUserId, String holdoutName, Zip_Assignment__c za, Zip_Segment__c segment) {
      String query = ' '+whereType+' '+ownerField;
      if (newUserId != null) {
         query += ' != \''+newUserId+'\' ';
      } else {
         query += ' != null';
      }
      if (String.isNotBlank(holdoutName)) {
         query += ' and '+holdoutName+'=false ';
      }
     if (objectName == ObjectHelper.OBJECT_ACCOUNT || objectName == ObjectHelper.OBJECT_LEAD) {
         query += getAccountJoinCriteria(za, segment);
      } // if (objectName == ObjectHelper.OBJECT_ACCOUNT
      
      query += ' ';
      return query;
   } // getOwnerQuery
   
   public String getAccountJoinCriteria(Zip_Assignment__c za, Zip_Segment__c segment) {
      System.debug('getAccountJoinCriteria za='+za.Name+' segment='+(segment != null ? segment.Name : 'None'));
      String query = '';
      Boolean hasCriteria = false;
      String joinCriteria = ZipCheckOwner.getJoinCriteria(za, segment);
      // if this is a default record (there is only one Zip Assignment for this zip code/sales org) we don't need these checks.
      if (!joinCriteria.contains(ZipCheckOwner.JOIN_NONE)) {
         query += ' and (';
         String queryJoin = (ZipCheckOwner.isAnd ? ' and ' : (ZipCheckOwner.isOr ? ' or ' : ''));
         if (ZipCheckOwner.hasEmps) {
            String fieldName = ObjectHelper.getEmpCntFieldName(ObjectHelper.OBJECT_ACCOUNT);
            if (String.isNotBlank(fieldName)) {
               System.debug('getAccountJoinCriteria Emps_Min__c='+segment.Emps_Min__c+' Emps_Max__c='+segment.Emps_Max__c);
               hasCriteria = true;
               query += ' (';
               // lowest range is zero - check for null value if the low range is that
               if (segment.Emps_Min__c < 1) {
                  query += fieldName+' = null or ';
               }
               query += '('+fieldName+'>='+segment.Emps_Min__c.intValue()+' and '+fieldName+'<='+segment.Emps_Max__c.intValue()+'))';
            
            } // if (String.isNotBlank(fieldName))
            
            // check to make sure there is join criteria if there are subsequent criteria
            queryJoin = ((ZipCheckOwner.hasAssets || ZipCheckOwner.hasBoolean1 || ZipCheckOwner.hasBoolean2)
                            && String.IsBlank(queryJoin) ? ' and ' : queryJoin);
         } // if (ZipCheckOwner.hasEmps
 
         // check for asset range - only add in if not covering the full range
         if (ZipCheckOwner.hasAssets) {
            hasCriteria = true;
            // if we are combining both criteria, we need to include an "and" or an "or"
            query += (queryJoin+' ( ');

            // lowest range is zero check if null value
            if (segment.Asset_Min__c < 1) {
               query += 'X401K_Assets__c = null or ';
            }
            // have to make sure the Asset_Max__c <= 999999999
            Decimal assetMax = (segment.Asset_Max__c != null ? (segment.Asset_Max__c > 999999999 ? 999999999 : segment.Asset_Max__c) : 0);
            query += '(X401K_Assets__c>='+segment.Asset_Min__c+' and X401K_Assets__c<='+assetMax+'))';
         } // if (ZipCheckOwner.hasAssets
          
         if (ZipCheckOwner.hasBoolean1) {
            hasCriteria = true;
            query += (queryJoin+' ( '+segment.Boolean1Field__c+'='+segment.Boolean1True__c+')');
         } // if (ZipCheckOwner.hasBoolean1

         if (ZipCheckOwner.hasBoolean2) {
            hasCriteria = true;
            query += (queryJoin+' ( '+segment.Boolean2Field__c+'='+segment.Boolean2True__c+')');
         } // if (ZipCheckOwner.hasBoolean1

         query += ')';
      } // if (za.IsDefault__c != 'Y'
      return (hasCriteria ? query : '');
   } // getAccountJoinCriteria
    
   public String checkOtherCriteria(Zip_Segment__c zipSeg, Boolean isAccount, Boolean isLead, Boolean isRefAcct) {
      Map<Id,ZipCheckOwner.CriteriaWrap> criteriaMap = ZipCheckOwner.checkOtherCriteria(null, zipSeg, isAccount, isLead, isRefAcct);
      System.debug('checkOtherCriteria zipSeg='+zipSeg.Name+' criteriaMap='+criteriaMap.size());
      String otherCriteriaQuery = '';
      if (!criteriaMap.isEmpty()) {
         // all the segment joins should in theory be the same. 
         String segmentJoinValue = null;
         String[] segmentCriteria = new String[]{};
         for (ZipCheckOwner.CriteriaWrap wrap : criteriaMap.values()) {
            String[] linkedCriteria = new String[]{};
            for (ZipSegmentCriteria__c criteria : wrap.allCriteria) {
               linkedCriteria.add(addCriteria(criteria));
            } // for (ZipSegmentCriteria__c criteria
            String linkJoinValue = ' '+(wrap.linkJoinIsAnd ? ZipCheckOwner.JOINTYPE_AND : ZipCheckOwner.JOINTYPE_OR)+' ';
            // should only be set once. This is only used if there's more than one grouping in the other criteria
            segmentJoinValue = (segmentJoinValue == null ? ' '+(wrap.segmentJoinIsAnd ? ZipCheckOwner.JOINTYPE_AND : ZipCheckOwner.JOINTYPE_OR)+' ' : segmentJoinValue);
            if (!linkedCriteria.isEmpty()) {
               String linkedQuery = '('+String.join(linkedCriteria,linkJoinValue)+')';
               segmentCriteria.add(linkedQuery);
            }
         } // for (ZipCheckOwner.CriteriaWrap wrap
         if (!segmentCriteria.isEmpty()) {
            otherCriteriaQuery = ' '+ZipCheckOwner.JOINTYPE_AND+' ('+String.join(segmentCriteria,segmentJoinValue)+')';
         }
      } // if (!criteriaMap.isEmpty()
      System.debug('checkOtherCriteria otherCriteriaQuery='+otherCriteriaQuery);
      return otherCriteriaQuery;
   } // checkOtherCriteria
    
   public String addOtherCriteria(Zip_Segment__c zipSeg, Boolean isAccount, Boolean isLead, Boolean isRefAcct) {
      String otherCriteria = '';
      System.debug('addOtherCriteria links='+(zipSeg.ZipSegmentCriteriaLinks__r != null ? zipSeg.ZipSegmentCriteriaLinks__r.size() : -1));
      if (zipSeg.ZipSegmentCriteriaLinks__r != null && !zipSeg.ZipSegmentCriteriaLinks__r.isEmpty()) {
         for (ZipSegmentCriteriaLink__c link : zipSeg.ZipSegmentCriteriaLinks__r) {
            ZipSegmentCriteria__c criteria = link.ZipSegmentCriteria__r;
            if ((criteria.Account__c && isAccount) || (criteria.Lead__c && isLead) || (criteria.ReferralAccount__c && isRefAcct)) {
               try {
                   otherCriteria += addCriteria(criteria);
               } catch (Exception e) {
                  System.debug('addOtherCriteria Exception evaluating criteria: '+e.getMessage()+'; '+e.getStackTraceString());
               }
            } // if ((criteria.Account__c && isAccount
         } // for (ZipSegmentCriteriaLink__c link
      } // if (zipSeg.ZipSegmentCriteriaLinks__r != null
       
      return otherCriteria;
   } // addOtherCriteria

   public String addCriteria(ZipSegmentCriteria__c criteria) {
      String query = '';
      if (criteria.FieldType__c == ZipCheckOwner.CRI_BOOLEAN) {
         // if it's a boolean, we're going to assume the operator is always equals.
         Boolean expectedValue = (criteria.Values__c == 'True');
         System.debug('evaluateCriteria checking '+criteria.FieldAPIName__c+' for '+expectedValue);
         //query = ' and '+criteria.FieldAPIName__c+'='+(expectedValue ? 'true' : 'false')+' ';
         query = criteria.FieldAPIName__c+'='+(expectedValue ? 'true' : 'false');
      } else if (criteria.FieldType__c == ZipCheckOwner.CRI_TEXT) {
         // we'll assume it's equals unless it's not equals
         // if they're both blank, or the value on the record is one of the values on the criteria.
         // For example, Ethnicity could have values HA1,HA2,HA3,HA4
         // Criteria says Ethnicity__c Equals HA1,HA2,HA3,HA4
         // Account has a blank value in Ethnicity, hasValue=false. Account has HA2 in Ethnicity, hasValue=true. Account has Hobbit, hasValue=false
         Boolean checkEquals = (criteria.Operator__c != ZipCheckOwner.OP_NOT_EQUALS);
         //query = ' and '+criteria.FieldAPIName__c;
         query = criteria.FieldAPIName__c;
         // if there's more than one value, use IN/NOT IN instead of =/!=
         if (String.isBlank(criteria.Values__c)) {
            query += ((checkEquals ? '=' : '!=')+'null ');
         } else if (criteria.Values__c.contains(',')) {
            // if there are multiple values
            query += ((checkEquals ? ' IN ' : ' NOT IN '));
            String[] tokens = new String[]{};
            for (String token : criteria.Values__c.split(',')) {
               tokens.add('\''+token+'\'');
            }
            query += ('('+String.join(tokens,',')+')');
         } else {
            // there is one value
            query += ((checkEquals ? '=' : '!=') + '\''+criteria.Values__c+'\' ');
         }
     } else if (criteria.FieldType__c == ZipCheckOwner.CRI_NBR) {
         Boolean isInteger = (String.isBlank(criteria.NumberFormat__c) || criteria.NumberFormat__c == 'Integer');
         if (isInteger) {
            Integer intValue = Integer.valueOf(criteria.Number1__c);
            //query = ' and ('+criteria.FieldAPIName__c+criteria.SOQLOperator__c+intValue;
            query = '('+criteria.FieldAPIName__c+criteria.SOQLOperator__c+intValue;
         } else {
            Double dblValue = (isInteger ? null : Double.valueOf(criteria.Number1__c));
            //query = ' and ('+criteria.FieldAPIName__c+criteria.SOQLOperator__c+dblValue;
            query = '('+criteria.FieldAPIName__c+criteria.SOQLOperator__c+dblValue;
         }
         if (criteria.SOQLNullOkay__c) {
            query += ' or '+criteria.FieldAPIName__c+'=null';
         }
         query += ') ';
      } else if (criteria.FieldType__c == ZipCheckOwner.CRI_NBR_RANGE) {
         Boolean isInteger = (String.isBlank(criteria.NumberFormat__c) || criteria.NumberFormat__c == 'Integer');
         if (isInteger) {
            Integer intValueLow = Integer.valueOf(criteria.Number1__c);
            Integer intValueHigh = Integer.valueOf(criteria.Number2__c);
            //query = ' and (('+criteria.FieldAPIName__c+'>='+intValueLow+' and '+criteria.FieldAPIName__c+'<='+intValueHigh+')';
            query = '(('+criteria.FieldAPIName__c+'>='+intValueLow+' and '+criteria.FieldAPIName__c+'<='+intValueHigh+')';
         } else {
            Double dblValueLow = Double.valueOf(criteria.Number1__c);
            Double dblValueHigh = Double.valueOf(criteria.Number2__c);
            //query = ' and (('+criteria.FieldAPIName__c+'>='+dblValueLow+' and '+criteria.FieldAPIName__c+'<='+dblValueHigh+')';
            query = '(('+criteria.FieldAPIName__c+'>='+dblValueLow+' and '+criteria.FieldAPIName__c+'<='+dblValueHigh+')';
         }
         // we'll assume a blank value is zero
         if (criteria.SOQLNullOkay__c) {
            query += ' or '+criteria.FieldAPIName__c+'=null';
         }
         query += ') ';
      }
      System.debug('addCriteria query='+query);
      return query;
   } // addCriteria
      
   /** Check to see if the object owner is going to be changed. If so, change it and return true.
      @objectName the object type being checked
      @ownerFieldName the name of the owner field for this object
      @holdOutFieldName the name of the hold out field, if it exists
      @rec the record being checked

      @recordTypeName the name of the record type name (if it needs to be checked)
      @useCheckId pass in true to use the values of p_checkOwnerId
      @p_checkOwnerId if none of the other checks need to be made the ownerId to check can just be passed in.
    */
   public boolean checkObjectOwner(String objectName, String ownerFieldName, String holdOutFieldName, String holdOutReasonFldName, String holdOutReasonFldValue, SObject rec, Zip_Assignment_Change__c zca, Boolean useCheckId, Id p_checkOwnerId) {
      System.debug('checkObjectOwner objectName='+objectName+' ownerFieldName='+ownerFieldName+' useCheckId='+useCheckId+' p_checkOwnerId='+p_checkOwnerId);

      if (String.isBlank(ownerFieldName)) {
         return false;
      }

      // check the holdout flag if it exists
      if (holdOutFieldName != null) {
         Boolean holdOut = (Boolean)rec.get(holdOutFieldName);
         // do not continue if there is a true value for the hold out flag.
         if (holdOut != null && holdOut) {
            return false;
         }
      } // if (holdOutFieldName != null

      Zip_Assignment__c za = zca.Zip_Assignment__r;
      ZipTerritory__c territory = za.ZipTerritory__r;
      //APR0151946: Added to fetch segment and hold out reason field & value
      /*Zip_Segment__c segment = (zca.ZipSegment__c != null ? segMap.get(zca.ZipSegment__c) : segMap.get(zca.Zip_Assignment__r.Zip_Segment__c));
      String holdOutReasonFldName = segment != null ? segment.AcctHoldOutReasonFld__c : '';
      String holdOutReasonFldValue = segment != null ? segment.AcctHoldOutReasonValue__c : '';*/
      
      // only check these if a specific owner id was not passed in
      // if doesn't meet the criteria for the zip assignment
      
      // the records being selected already meet the criteria - don't believe we need to do this!
      
      // don't check the record type for contacts - process all contacts retrieved
      //if ((objectName == ObjectHelper.OBJECT_ACCOUNT || objectName == ObjectHelper.OBJECT_LEAD) 
      //     && !useCheckId && !ZipCheckOwner.objectMatchesZip(rec,objectName,za,(objectName != ObjectHelper.OBJECT_CONTACT))) {
      //   return false;
      //} // if (!useCheckId
      Id curOwnerId = (Id)rec.get(ownerFieldName);
      Id checkOwnerId = (useCheckId ? p_checkOwnerId : (territory != null ? territory.TerritoryRep__c : null));
      
      // main owner field can't be set to null
      if (ownerFieldName == ObjectHelper.OWNER_FIELD && checkOwnerId == null) {
         return false;
      }
      // was one of the owners changed?
      Boolean changeFound = (curOwnerId != checkOwnerId);
      
      System.debug('checkObjectOwner changeFound='+changeFound+' curOwnerId='+curOwnerId+' checkOwnerId='+checkOwnerId);
      if (changeFound) {
         rec.put(ownerFieldName,checkOwnerId);
		 //APR0151946: Set Hold Out Reason if maintained on the segment
		 if(holdOutFieldName!=null && String.isNotBlank(holdOutFieldName) && holdOutReasonFldName!=null && String.isNotBlank(holdOutReasonFldName) && holdOutReasonFldValue!=null && String.isNotBlank(holdOutReasonFldValue)){
			 rec.put(holdOutFieldName,true);
			 rec.put(holdOutReasonFldName,holdOutReasonFldValue);
		 }
         if (objectName == ObjectHelper.OBJECT_CONTACT) {
            zca.Contacts_Updated__c++;
         } else if (objectName == ObjectHelper.OBJECT_LEAD) {
            zca.Leads_Updated__c++;
         } else if (objectName == ObjectHelper.OBJECT_ACCOUNT) {
            zca.Accounts_Updated__c++;
         } else if (objectName == ObjectHelper.OBJECT_REF_ACCOUNT) {
            zca.Referral_Accounts_Updated__c++;
         } else if (objectName == ObjectHelper.OBJECT_REF_CONTACT) {
            zca.Referral_Contacts_Updated__c++;
         }
      } // if

      return changeFound;
   } // checkObjectOwner
   
   public static Boolean USE_ORIGINAL=Label.ZipBatchUseOriginal=='Y';
   
   // Execute the account query for ownership. 
   public boolean executeAcctQuery(String objectName, String query, Zip_Assignment_Change__c zca, String zipCode, Zip_Segment__c segment, Integer maxBatch) {
      // execute the query
      Integer resultCount = 0;
    
      try {
         
         Map<Id,SObject> updateAcctMap = new Map<Id,SObject>();
         Map<Id,SObject> updateCtctMap = new Map<Id,SObject>();
          
         Map<Id,SObject> oldMap = new Map<Id,SObject>();

         List<AccountTeamMember> insertAcctTeams = new List<AccountTeamMember>();
         List<AccountTeamMember> deleteAcctTeams = new List<AccountTeamMember>();
         
         if (objectName == ObjectHelper.OBJECT_ACCOUNT) {
            zca.AccountQueryStart__c = Datetime.now();
         }
         SObject[] recs = Database.query(query);
         resultCount = recs.size();
         
         if (objectName == ObjectHelper.OBJECT_ACCOUNT) {
            zca.AccountQueryEnd__c = Datetime.now();
         }
         DateTime checkOwnerStart = DateTime.now();
         //for (SObject so : Database.query(query)) {
         for (SObject so : recs) {
            //resultCount ++;
            // go through results, update owner
            // store in a map so record doesn't get added multiple times

            //for (SObject so : results) {
               if (objectName == ObjectHelper.OBJECT_ACCOUNT) {
                  checkAcctOwner((Account)so,zca,segment,updateAcctMap,updateCtctMap,oldMap, insertAcctTeams, deleteAcctTeams);
               } else if (objectName == ObjectHelper.OBJECT_REF_ACCOUNT) {
                  checkRefAcctOwner((Referral_Account__c)so,zca,segment,updateAcctMap,updateCtctMap,oldMap);
               }
            //}
         } // for

         recs.clear();
         addToProcessTracker(zca, 'process checkAcctOwner', checkOwnerStart, DateTime.now(), null, null);

         zca.AccountTeamsUpdated__c += insertAcctTeams.size() + deleteAcctTeams.size();
         Database.DMLOptions dml = DuplicateHelper.getDmlSkipCheck();

         // update records
         if (!updateCtctMap.isEmpty()) {
            if (!checkLimits(zca,zipCode,'contacts',updateCtctMap.size())) {
               return false;
            }
            DateTime ctctStartTime = DateTime.now();
            DmlHelper.performDML2(updateCtctMap.values(), DmlHelper.DML_UPDATE, 'ZipBatch', 'executeAcctQuery', 'Update contacts '+objectName, false, dml);
            addToProcessTracker(zca, 'Update Contacts', ctctStartTime, DateTime.now(), null, DmlHelper.errorMsg);
            
         } // if (!updateCtctMap.isEmpty
         
         if (!updateAcctMap.isEmpty()) {
            // add extra rows for the accounts to take the account team DML rows into consideration
            if (!checkLimits(zca,zipCode,'accounts',updateAcctMap.size()*3)) {
               return false;
            }
            DateTime acctStartTime = DateTime.now();
            DmlHelper.performDML2(updateAcctMap.values(), DmlHelper.DML_UPDATE, 'ZipBatch', 'executeAcctQuery', 'Update accounts '+objectName, false, dml);
            //Call Cadence
            addToProcessTracker(zca, 'Update Accounts', acctStartTime, DateTime.now(), null, DmlHelper.errorMsg);
         } // if (!updateAcctMap.isEmpty
           
         if (!oldMap.isEmpty()) {
            CadenceOwnerCheck.checkRecs(updateAcctMap.values(),oldMap);
         }

         if (!deleteAcctTeams.isEmpty()) {
            DateTime startTime = DateTime.now();
            DmlHelper.performDML2(deleteAcctTeams, DmlHelper.DML_DELETE, 'ZipBatch', 'executeAcctQuery', 'Delete AccountTeamMembers', false);
            addToProcessTracker(zca, 'Delete AccountTeams', startTime, DateTime.now(), null, DmlHelper.errorMsg);
         }
         if (!insertAcctTeams.isEmpty()) {
            DateTime startTime = DateTime.now();
            DmlHelper.performDML2(insertAcctTeams, DmlHelper.DML_INSERT, 'ZipBatch', 'executeAcctQuery', 'inserting AccountTeamMembers', false);
            addToProcessTracker(zca, 'Insert AccountTeams', startTime, DateTime.now(), null, DmlHelper.errorMsg);
         }

      } catch (Exception ex) {
         addToProcessTracker(zca, 'executeAcctQuery QueryException='+ex.getMessage(), null, null, null, null);
         ErrorLog.logError('ZipBatch', 'executeAcctQuery', 'QueryException-'+objectName, zipCode, 'query='+query+' exception='+ex.getMessage()+': '+ex.getStackTraceString(), null, true);
      }
      ErrorLog.checkSave();
      
      System.debug('executeAcctQuery resultCount='+resultCount+' maxBatch='+maxBatch);
      addToProcessTracker(zca, 'executeAcctQuery resultCount='+resultCount+' maxBatch='+maxBatch, null, null, null, null);
      
      return (resultCount < maxBatch);
   } // executeAcctQuery

   public static String REF_ACCT_CTCT_QUERY = 'SELECT Id, Name, RecordTypeId, RecordType.Name '+
                ',OwnerId, '+ObjectHelper.OWNER_ACCOUNT_401+','+ObjectHelper.OWNER_ACCOUNT_ASO+','+ObjectHelper.OWNER_ACCOUNT_HNBF+
                ',MMS_Account_Owner__c,Hold_Out__c '+
                ','+ObjectHelper.OWNER_ACCOUNT_WHOLE_INT+
                ',(SELECT Id ,Name ,RecordTypeId, RecordType.Name ,OwnerId, Hold_Out__c'+
                ','+ObjectHelper.OWNER_CONTACT_401+','+ObjectHelper.OWNER_CONTACT_ASO+','+ObjectHelper.OWNER_CONTACT_HNBF+',MMS_Contact_Owner__c '+ 
                ','+ObjectHelper.OWNER_CONTACT_WHOLE_INT+
                ' from Referral_Contacts__r order by LastModifiedDate desc limit 30) '+
                ' from Referral_Account__c ';

   // Build the query for the referral accounts.
   public String getRefAcctQuery(String zipCode, Zip_Assignment_Change__c zca, Zip_Segment__c segment) {
      
      String query = REF_ACCT_CTCT_QUERY+ ' where Zip_Postal_Code__c like \''+zipCode+'%\' '; 

      Boolean queryComplete = false;
      System.debug('getRefAcctQuery zipCode='+zipCode+' segment='+segment.Name+' SalesOrg='+zca.Zip_Assignment__r.Sales_Org__c
                    +' rfrlSalesOrg='+(rfrlSalesOrgs.contains(zca.Zip_Assignment__r.Sales_Org__c))+' RfrlRecordTypeIds__c='+segment.RfrlRecordTypeIds__c);
       
      if (!zca.Processed__c && rfrlSalesOrgs.contains(zca.Zip_Assignment__r.Sales_Org__c) && String.isNotBlank(segment.RfrlAcctOwnerFldName__c)
                && (String.isNotBlank(segment.RfrlRecordTypeIds__c))
                && (segment.RfrlAcctDefault__c || zca.Zip_Assignment__r.SkipJoinCriteria__c)) {
         Zip_Assignment__c za = zca.Zip_Assignment__r;
         query += getRecordTypeQueryString(segment.RfrlRecordTypeIds__c);
         query += checkOtherCriteria(segment, false, false, true);

         if (String.isNotBlank(segment.ReferralSourceType__c)) {
            String[] refTypes = segment.ReferralSourceType__c.split(';');
            query += makeQueryInClause('Referral_Source_Business_Type__c', refTypes, true);
         }
         if (String.isNotBlank(segment.RfrlSourceSubTypes__c)) {
            String[] refTypes = segment.RfrlSourceSubTypes__c.split(';');
            query += makeQueryInClause('ReferralSourceSubType__c', refTypes, true);
         }
         if (String.isNotBlank(segment.RfrlSubTypesExcluded__c)) {
            String[] refTypes = segment.RfrlSubTypesExcluded__c.split(',');
            query += makeQueryInClause('ReferralSourceSubType__c', refTypes, false);
         }
         
         ZipTerritory__c territory = za.ZipTerritory__r;
            
         Id recordTypeId = null; 
         String ownerFieldName = segment.RfrlAcctOwnerFldName__c; 
         String holdOutFieldName = segment.RfrlAcctHoldOutFldName__c; 
         System.debug('getRefAcctQuery salesOrg='+za.Sales_Org__c+' ownerFieldName='+ownerFieldName+' holdOutFieldName='+holdOutFieldName);
         User zipUser = (territory != null 
                            ? (territory.TerritoryRep__r != null && territory.TerritoryRep__r.IsActive ? territory.TerritoryRep__r : null)
                            : (za.User__r != null && za.User__r.IsActive ? za.User__r : null));

         //if (String.isNotBlank(ownerFieldName) && ((String.isNotBlank(recordTypeName) && territory.TerritoryRep__c == null) || (territory.TerritoryRep__c != null && territory.TerritoryRep__r.IsActive))) {
         if (String.isNotBlank(ownerFieldName) && ((ownerFieldName == 'OwnerId' && zipUser != null) || (ownerFieldName != 'OwnerId'))) {
            query += getOwnerQuery('and',ObjectHelper.OBJECT_REF_ACCOUNT,ownerFieldName,(zipUser != null ? zipUser.Id : null),holdOutFieldName,za,segment);
            queryComplete = true;
         }
      } // if (!zca.Processed__c

      // if we don't add to the where clause don't continue
      if (!queryComplete) {
         query = null;
      }
        
      System.debug('getRefAcctQuery query is null='+(query == null));
      return query;
   } // getRefAcctQuery
    
   public static String makeQueryInClause(String fldName, String[] values, Boolean checkEquals) {
      String opOne = (checkEquals ? '=' : '!=');
      String opMany = (checkEquals ? ' in ' : ' not in ');
      String clause = '';
      if (values != null && !values.isEmpty()) {
         String[] quotedValues = new String[]{};
         for (String val : values) {
            quotedValues.add('\''+val+'\'');
         }
         clause = ' and '+fldName+ (values.size() == 1 ? opOne+quotedValues[0] : opMany+'('+String.join(quotedValues,',')+')')+' ';
      } // if (values != null && !values.isEmpty
      return clause;
   } // makeQueryInClause

   public static Set<String> rfrlSalesOrgs = null;
   public static Set<String> acctSalesOrgs = null;
      
   // allow us to define specific sales orgs to process. The set will be empty if all sales orgs can be processed.
   public static void checkSalesOrgs() {
      if (rfrlSalesOrgs == null) {
         rfrlSalesOrgs = new Set<String>();
         acctSalesOrgs = new Set<String>();
         for (SalesOrg__c salesOrg : SalesOrg__c.getAll().values()) {
            if (salesOrg.ProcessAcctOwnership__c) {
               acctSalesOrgs.add(salesOrg.Name);
            }
            if (salesOrg.ProcessRfrlOwnership__c) {
               rfrlSalesOrgs.add(salesOrg.Name);
            }
         }
      } // if (rfrlSalesOrgs
   } // checkRfrlSalesOrgs
   

   private Boolean checkAcctOwner(Account acct,Zip_Assignment_Change__c zca, Zip_Segment__c segment
                                 ,Map<Id,SObject> updateAcctMap,Map<id,SObject> updateCtctMap, Map<Id,SObject> oldMap
                                 ,List<AccountTeamMember> insertAcctTeams, List<AccountTeamMember> deleteAcctTeams
                                 ) {
      System.debug('checkAcctOwner for '+acct.Name);
      DateTime acctStart = DateTime.now();
      Map<String,AccountTeamMember> atmMap = ZipCheckOwner.getAtmMap(acct, deleteAcctTeams);                              
      if (!zca.Processed__c) {
         String holdOutFieldName = segment.AcctHoldOutFldName__c;
         String ownerFieldName = segment.AcctOwnerFldName__c;
         String teamRoleName = segment.TeamRole__c;
         String holdOutReasonFldName = segment.AcctHoldOutReasonFld__c != null && String.isNotBlank(segment.AcctHoldOutReasonFld__c) ? segment.AcctHoldOutReasonFld__c : '';	//APR0151946: Fetch Hold Out Reason field if available on segment
		 String holdOutReasonFldValue = segment.AcctHoldOutReasonValue__c != null && String.isNotBlank(segment.AcctHoldOutReasonValue__c) ? segment.AcctHoldOutReasonValue__c : '';
         //Account oldMapAcct = new Account(Id=acct.Id);
         if ((String.isBlank(zca.OwnershipType__c) || zca.OwnershipType__c == ZipAssignment.CHANGE_OWNER_FIELD) && String.isNotBlank(ownerFieldName)) {
            Id origOwnerId = (Id)acct.get(ownerFieldName);
            if (checkObjectOwner(ObjectHelper.OBJECT_ACCOUNT, ownerFieldName, holdOutFieldName,holdOutReasonFldName,holdOutReasonFldValue,acct, zca, false,null)) {               
               Account oldAcct = (oldMap.containsKey(acct.Id) ? (Account)oldMap.get(acct.Id) : new Account(Id=acct.Id));
               oldAcct.put(ownerFieldName, origOwnerId);
               oldMap.put(oldAcct.Id,oldAcct);
                
               // if  isParent, save Id to process children                     // parent
               //System.debug('**ZipBatch.checkAcctOwner acct id='+acct.Id+' isParent='+acct.isParent__c);
               if (acct.isParent__c || Test.isRunningTest())
               {  parentAcctIdSet.add(acct.Id); }
               // save in a new instance so only the fields we're concerned about will be saved.
               Account saveAcct = (USE_ORIGINAL ? acct : (Account)updateAcctMap.get(acct.Id));
               if (saveAcct == null) {
                  saveAcct = new Account(Id=acct.Id);
                  saveAcct.put(ownerFieldName,acct.get(ownerFieldName));
                  //APR0151946: Save hold out if maintained
				  if(String.isNotBlank(holdOutReasonFldName) && saveAcct.get(holdOutReasonFldName) != acct.get(holdOutReasonFldName) && saveAcct.get(holdOutFieldName) != acct.get(holdOutFieldName)){
					saveAcct.put(holdOutFieldName,acct.get(holdOutFieldName));
					saveAcct.put(holdOutReasonFldName,acct.get(holdOutReasonFldName));
				  }
               }
               updateAcctMap.put(acct.Id,saveAcct);
               Id ownerId = (Id)acct.get(ownerFieldName);
               
               if (acct.Contacts != null && !acct.Contacts.isEmpty()) {
                  DateTime ctctStart = DateTime.now();
                  String ctctOwnerFieldName = segment.CtctOwnerFldName__c; //ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_CONTACT,zca.Zip_Assignment__r.Sales_Org__c);
                  String ctctHoldOutFieldName = segment.CtctHoldOutFldName__c;
                  for (Contact ctct : acct.Contacts) {
                     if (checkObjectOwner(ObjectHelper.OBJECT_CONTACT, ctctOwnerFieldName, ctctHoldOutFieldName,null,null, ctct, zca,true,ownerId)) {
                        Contact saveCtct = (USE_ORIGINAL ? ctct : (Contact)updateCtctMap.get(ctct.Id));
                        if (saveCtct == null) {
                           saveCtct = new Contact(Id=ctct.Id);
                           saveCtct.put(ctctOwnerFieldName, ownerId);
                        }
                        updateCtctMap.put(ctct.Id,saveCtct);
                     }
                  } // for (Contact ctct
                  milliCtcts = milliCtcts + (DateTime.now().getTime() - ctctStart.getTime());
               } // if (acct.Contacts != null
            } // if (checkObjectOwner
         }
         if (zca.Zip_Assignment__r.ZipTerritory__r != null && (String.isBlank(zca.OwnershipType__c) || zca.OwnershipType__c == ZipAssignment.CHANGE_TEAM_MEMBER) && String.isNotBlank(teamRoleName)) {
            DateTime teamStart = DateTime.now();
            ZipCheckOwner.checkAccountTeam(acct,zca.Zip_Assignment__r.ZipTerritory__r.TerritoryRep__c, null,teamRoleName, insertAcctTeams, deleteAcctTeams, atmMap);
            milliAcctTeams = milliAcctTeams + (DateTime.now().getTime() - teamStart.getTime());
         }
      } // if (!zca.Processed__c
      milliAccts = milliAccts + (DateTime.now().getTime() - acctStart.getTime());

      return true;
   } // checkAcctOwner
   
   // all records returned should meet the criteria so we don't need to check that. 
   private Boolean checkRefAcctOwner(Referral_Account__c acct,Zip_Assignment_Change__c zca,Zip_Segment__c segment, Map<Id,SObject> updateAcctMap,Map<id,SObject> updateCtctMap, Map<Id,SObject> oldMap) {
      System.debug('checkRefAcctOwner for '+acct.Name+' zca='+(zca != null));
            String acctOwnerFieldName = segment.RfrlAcctOwnerFldName__c;
            String holdOutFieldName = segment.RfrlAcctHoldOutFldName__c;
            System.debug('checkRefAcctOwner acctOwnerFieldName='+acctOwnerFieldName+' holdOutFieldName='+holdOutFieldName);
            Id origOwnerId = (Id)acct.get(acctOwnerFieldName);
            if (checkObjectOwner(ObjectHelper.OBJECT_REF_ACCOUNT, acctOwnerFieldName, holdOutFieldName,null,null,acct, zca, false,null)) {
               Referral_Account__c oldAcct = (oldMap.containsKey(acct.Id) ? (Referral_Account__c)oldMap.get(acct.Id) : new Referral_Account__c(Id=acct.Id));
               oldMap.put(oldAcct.Id,oldAcct);
               oldAcct.put(acctOwnerFieldName,origOwnerId);
                
               updateAcctMap.put(acct.Id,acct);
               Id ownerId = (Id)acct.get(acctOwnerFieldName);
               if (acct.Referral_Contacts__r != null && !acct.Referral_Contacts__r.isEmpty()) {
                  String ctctOwnerFieldName = segment.RfrlCtctOwnerFldName__c;
                  String ctctHoldOutFieldName = segment.RfrlCtctHoldOutFldName__c;
                  System.debug('checkRefAcctOwner ctctOwnerFieldName='+ctctOwnerFieldName+' ctctHoldOutFieldName='+ctctHoldOutFieldName);
                  for (Referral_Contact__c ctct : acct.Referral_Contacts__r) {
                     if (checkObjectOwner(ObjectHelper.OBJECT_REF_CONTACT, ctctOwnerFieldName, ctctHoldOutFieldName,null,null, ctct, zca,true,ownerId)) {
                        updateCtctMap.put(ctct.Id,ctct);
                     }
                  } // for (Contact ctct
               } // if (acct.Contacts != null
            } // if (checkObjectOwner
         //} // if (!zca.Processed__c
      //} // for (Zip_Assignment_Change__c
      return true;
   } // checkRefAcctOwner
   

   /** Check to make sure we are not hitting DML limits with this transaction.
    */
   public Boolean checkLimits (Zip_Assignment_Change__c zca, String zipCode, String processType, Integer numRows) {
      String msg = processType+' for zip_code='+zipCode;
      System.debug(msg);
      String errorMsg = Utilities.checkLimits(msg, 4, numRows+4);
      if (errorMsg != null) {
         addToProcessTracker(zca, errorMsg, null, null, null, null);
         processingMsg += ' '+errorMsg;
         batchMsg += processingMsg;
         // limits reached - stop processing.
         return false;
      }

      return true;
   } // checkLimits
   
   public static Boolean ALLOW_RESTART=Label.ZipBatch_AllowRestart == 'Y';

   global void finish(Database.BatchableContext BC){
      ErrorLog.checkSave();
      
      // Get the ID of the AsyncApexJob representing this batch job
      String message = '\nTotal Changes Processed: '+numberChangeRecords;
      message += ' \n Query Sales Orgs: '+querySalesOrgs;
      message += ' \n Change records created (because of hitting limits): '+numberChangeRecordsCreated;
      
      message += ' \n\n Total Accounts updated='+totalChanges.Accounts_Updated__c;
      message += ' \n Total Contacts updated='+totalChanges.Contacts_Updated__c;
      message += ' \n Total Leads updated='+totalChanges.Leads_Updated__c;
      message += ' \n Total Referral Accounts updated='+totalChanges.Referral_Accounts_Updated__c;
      message += ' \n Total Referral Contacts updated='+totalChanges.Referral_Contacts_Updated__c;
      message += ' \n Total Account Teams updated='+totalChanges.AccountTeamsUpdated__c;
      message += ' \n Total Record Types updated='+totalChanges.RecordTypeUpdated__c+'\n';

      for (String salesOrg : changeByOrgMap.keySet()) {
         Map<String,Zip_Assignment_Change__c> changeBySegmentMap = changeByOrgMap.get(salesOrg);
         for (String segmentName : changeBySegmentMap.keySet()) {
            Zip_Assignment_Change__c change = changeBySegmentMap.get(segmentName);
            message += ' \n For Sales Org '+salesOrg+' Segment '+segmentName+': ';
            message += ' \n       Accounts updated='+change.Accounts_Updated__c;
            message += ' \n       Contacts updated='+change.Contacts_Updated__c;
            message += ' \n       Leads updated='+change.Leads_Updated__c;
            message += ' \n       Referral Accounts updated='+change.Referral_Accounts_Updated__c;
            message += ' \n       Referral Contacts updated='+change.Referral_Contacts_Updated__c;
            message += ' \n       Account Teams updated='+change.AccountTeamsUpdated__c;
            message += ' \n       Record Types updated='+change.RecordTypeUpdated__c+'\n';
         } // for (String segmentName
      } // for (String salesOrg
      
      // check for additional zip assignments and relaunch if found
      Integer additionalRecs = (ALLOW_RESTART ? [select count() 
                            FROM Zip_Assignment_Change__c
                           WHERE Processed__c = false
                             AND Zip_Assignment__r.ZipOkay__c = true
                             AND ZipSegment__c != null
                             AND ZipSegment__r.Sales_Org__c in :querySalesOrgs
                            limit 10] : 0);

      if (additionalRecs > 0) {
         message += '\n\n More change records exist - relaunching batch process';
      }

      message += '\n'+batchMsg;
      
      jh.completeJob(bc, 'Prospect-Client ownership update', message);
      
      if (additionalRecs > 0) {
         Apex_Batch_Control__c abc = getBatchControl();
         if (abc != null && abc.Active__c) {
            Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 1);
            ZipBatch zb = new ZipBatch(salesOrgOverride);
            database.executeBatch(zb, batchSize);
         }
      } // if (addtionalRecs > 0

   } // finish
   
   public static Integer getMaxBatch() {
      Apex_Batch_Control__c abc = getBatchControl();
      // use minutes till launch because batch size is used elsewhere
      Integer maxBatch = Integer.valueOf((abc != null && abc.Minutes_till_Launch__c != null ? abc.Minutes_till_Launch__c : 1000));
      return maxBatch;
   } // getMaxBatch
   
   public static Apex_Batch_Control__c getBatchControl() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('ZipBatch');
      return abc;
   } // getBatchControl
   
} // class ZipBatch