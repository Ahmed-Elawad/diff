/* Used to clone opportunities with multiple account quote products.  
 * An opportunity is created an associated with each quote product account, and the quote products are split
 * by opportunity
 
On the opportunity you'd want to look for Primary_Oracle_Quote__c - only one quote can be primary and that is the quote that feeds quotelines to opptylines. 
In a multi-id the lines must have a value in the QuoteLineGroupAcct__c or you will not have what you need to split. 
You should also look at Number_of_Ids__c this is calculated in opptylineitem.cls as its looping thru the lines 
and is based on how many QuoteLineGroupAcct__c there are on all the lines. 
So a multi-id quote should have multi-id checked and number of ids >1. 
If multi-id is checked and number of ids is 0 then they haven't added products and you'd have no data to split. 
As for fully approved/not draft that would be the primary quote status. Primary_Oracle_Quote__r.Status__c='approved'
you can get that off the quote itself or there is a Primary_Oracle_Quote_Status__c field on the oppty that is associated to the Primary_Oracle_Quote__c listed on the oppty.

If there are multiple groups in the ProductGroupsSelected__c field, then the code will take the primary Opportunity, pull out one of the product groups, create a new opportunity, 
then move the line items with the other product group to the new opportunity. Delete from one opp and insert for the other.

 * History
 * -------
 * 12/04/2016  Jermaine Stukes   Created
 * 05/15/2017  Sunnish Annu      added code for populating oppsource value
 * 11/21/2017  Jermaine Stukes   Added Handbook Contact Catch 
 * 02/12/2018  Jermaine Stukes   Updated try/catch to include related object logic
 * 03/12/2019  Josh Cartwright   split out opportunity line items select from query 
   06/04/2019  Dan Carmen        Increment API Version
   11/15/2019  Brandon Vidro     Added Submitted Revenue Clone Page Reference    
   02/24/2020  Dan Carmen        Increment API to 48
   03/23/2020  Carrie Marciano   Updated to handle Oracle Quotes 
   04/09/2020  Matt Fritschi     Parent Opportunities are shown on Split Opportunities
   06/08/2020  Jake Hinds        added in without sharing per pmd
   11/30/2020  Matt Fritschi     Creates Onboarding records for the child and parent Opportunities when split.
   03/01/2021  Matt Fritschi     Onboarding record's SubmissionDate set to null on creation.
   05/19/2021  Dan Carmen        Updated to use labels for StageNames
   09/29/2021  Carrie Marciano	 Moved the Opportunity Team Member code out from OpptyLine for loop and fixed issues where not all opportunity team memebers were being added to cloned oppties
   12/14/2021  Dan Carmen        Removed/commented out Steelbrick (Salesforce CPQ) code. Add ability to split out product groups.
   01/13/2022  Dan Carmen        Change for multiple approval statuses
   03/30/2022  Susmitha Somavarapu Request to have Primary Competition copied over when cloning and splitting opportunities
   05/23/2023  Dan Carmen        For multi-ids, ability to split processing into queueable jobs.
   09/04/2023  Reetesh Pandey    Split functionality to add Non Payroll Unit
   12/15/2023  Dan Carmen        Add extra logging

 */
public without sharing class OpptySplitController {
    public static final String CLASSNAME='OpptySplitController';
    
    public Boolean opptySplittable{get;set;}
    public Boolean opptyOkay{get {return(entryOpp != null);}}
    public Boolean startOkay{get;set;}
    public Boolean finishOkay{get;set;}
    public Boolean splitSuccess{get;set;}
    public List<Opportunity> clonedOpptyList{get;set;}
    // the opportunity we entered the form with
    public Opportunity entryOpp{get;set;}
    private String opptyId;
    public List <String> handbookProdNames{get;set;}
    public Boolean handbookError {get;set;}
    public Boolean cloneHandbookContact {get; set;}
    public Boolean selectedSplit {get; set;}
    public String errorMsg{get;set;}
    // if this is a larger multi-id, we'll process some of the records asynchronously
    public Boolean processingSplitAsync{get;set;}
    
    public static String HTML_YES='<font color="green"><b>YES</b></font>';
    public static String HTML_NO='<font color="red"><b>NO</b></font>';
    
    public String blockTitle{
        get {return (entryOpp != null ? 'for '+entryOpp.Name : 'Opportunity');}
    }
    
    public static Set<String> APPROVED_STATUS = new Set<String>(Label.OpptySplit_ApprovedStatus.split(','));
    
    public Boolean quoteFound{ get {return (entryOpp != null && entryOpp.Primary_Oracle_Quote__c != null); }}
    public String quoteFoundText{get {return (quoteFound ? HTML_YES : HTML_NO);}}
    
    public Boolean multiIdQuote{get{return (entryOpp != null && !entryOpp.cafsl__Oracle_Quotes__r.isEmpty());}}
    public String multiIdText{get {return (multiIdQuote ? HTML_YES : HTML_NO);}}
    
    public Boolean multipleQuoteGroups{get{return(entryOpp != null && entryOpp.Number_of_Ids__c != null && entryOpp.Number_of_Ids__c > 1);}}
    public String multipleQuoteText{get {return (multipleQuoteGroups ? HTML_YES : HTML_NO);}}
    
    public String quoteStatus{get{ return (entryOpp != null && entryOpp.Primary_Oracle_Quote__c != null ? entryOpp.Primary_Oracle_Quote__r.Status__c : '');}}
    public Boolean quoteApproved{get{return(String.isNotBlank(quoteStatus) && APPROVED_STATUS.contains(quoteStatus));}}
    public String quoteApprovedText{get {return (quoteApproved ? HTML_YES : HTML_NO);}}

    public Boolean splitByProdGroupOkay{
        get {
           String[] prodGroups = ((entryOpp != null && entryOpp.EvaluateProductGroup__c && String.isNotBlank(entryOpp.ProductGroupsSelected__c)) 
                                               ? entryOpp.ProductGroupsSelected__c.split(',') : new String[]{});
           return (prodGroups.size() > 1);
        } // get
    } // splitByProdGroupOkay
    public String prodGroupText{get {return (splitByProdGroupOkay ? HTML_YES : HTML_NO);}}
    
    public Boolean splitOkay{
        get {
           // have to have multi id quote lines in order to split
           return (quoteFound && multiIdQuote && multipleQuoteGroups && quoteApproved);
        }
    } // splitOkay
    
    public String statusMsg{
        get {
           String msg='';
           if (splitOkay && !splitByProdGroupOkay) {
              msg = '<font color="green" size="3px"><b>The Split Opportunity button will separate this Opportunity into separate ids.</b></font>';
           } else if (!splitOkay && splitByProdGroupOkay) {
              msg = '<font color="green" size="3px"><b>No Multi-Id was found. The Split Opportunity button will only separate the Product Groups.</b></font>';
           } else if (!splitOkay && !splitByProdGroupOkay) {
              msg = '<font color="red" size="3px"><b>No Multi-Ids or Product Groups were found to use the Split Opportunity button!</b></font>';
           } else if (splitOkay && splitByProdGroupOkay) {
              msg = '<font color="green" size="3px"><b>The Split Opportunity button will separate the ids and the Product Groups.</b></font>';
           }
           return msg;
        }
    }
    
    public OpptySplitController(Id p_opptyId, Boolean p_cloneHandbookContact, Boolean p_processingSplitAsync) {
       opptyId = p_opptyId;
       setEntryOpp();
       cloneHandbookContact = p_cloneHandbookContact;
       processingSplitAsync = p_processingSplitAsync;
       clonedOpptyList = new List<Opportunity>();
    } // OpptySplitController

    public OpptySplitController() {
        opptyId = ApexPages.CurrentPage().getParameters().get('id');
        // get information from the Opportunity so we know if we can proceed
        setEntryOpp();
        /*
        entryOpp = (opptyId != null ? [Select Id, AccountId, Name, Handbook_Contact__c, EvaluateProductGroup__c, ProductGroupsSelected__c 
                                       ,Number_of_Ids__c
                                       ,Primary_Oracle_Quote__c
                                       ,Primary_Oracle_Quote__r.Status__c
                                       ,(Select Id, Product2.Product_Group__c from OpportunityLineItems where Product2.Product_Group__c != null)
                                       ,(select Id from cafsl__Oracle_Quotes__r where Multi_ID__c=true limit 1)
                                    from Opportunity where Id=:opptyId ] 
                               : null);
        */
        cloneHandbookContact = (entryOpp != null && entryOpp.Handbook_Contact__c != null);
        checkProductGroups();
        startOkay=true;
        finishOkay=false;
        opptySplittable=true;
        splitSuccess = false;

        selectedSplit = false;
        handbookProdNames  = new List <String>(Label.Handbook_Product_Code.split(','));
        clonedOpptyList = new List<Opportunity>();
        processingSplitAsync = false;
    } // OpptySplitController
    
    public void setEntryOpp() {
        // get information from the Opportunity so we know if we can proceed
        entryOpp = (opptyId != null ? [Select Id, AccountId, Name, Handbook_Contact__c, EvaluateProductGroup__c, ProductGroupsSelected__c 
                                       ,Number_of_Ids__c
                                       ,Primary_Oracle_Quote__c
                                       ,Primary_Oracle_Quote__r.Status__c
                                       ,(Select Id, Product2.Product_Group__c from OpportunityLineItems where Product2.Product_Group__c != null)
                                       ,(select Id from cafsl__Oracle_Quotes__r where Multi_ID__c=true limit 1)
                                    from Opportunity where Id=:opptyId ] 
                               : null);

    } // setEntryOpp
    
   public void checkProductGroups() {
      if (entryOpp != null) {
         Set<String> prodGroupSet = new Set<String>();
         for (OpportunityLineItem oli : entryOpp.OpportunityLineItems) {
            if (oli.Product2 != null && String.isNotBlank(oli.Product2.Product_Group__c)) {
               prodGroupSet.add(oli.Product2.Product_Group__c);
            }
         }
         if (!prodGroupSet.isEmpty()) {
            String[] sortList = new String[]{};
            sortList.addAll(prodGroupSet);
            sortList.sort();
            String groupsFound = String.join(sortList,',');
            if (entryOpp.ProductGroupsSelected__c != groupsFound) {
               // do we need to save this?
               entryOpp.ProductGroupsSelected__c = groupsFound;
            } // if (opp.ProductGroupsSelected__c
         }
      } // if (entryOpp != null
   } // checkProductGroups


    public void initialize() {
    } // initialize
    
    // get all of the account ids for the primary quote on the opp
    public static String[] getMultiIds(Id oppId, Id quoteId, Id acctId) {
       AggregateResult[] results = [Select count(Id) nbrRecs, Oracle_Quote_Line__r.Prospect_Client__c acctId
                                      From OpportunityLineItem
                                     Where OpportunityId=:oppId
                                       and Oracle_Quote_Line__r.cafsl__Oracle_Quote__c = :quoteId
                                       and Oracle_Quote_Line__r.Prospect_Client__c != null
                                       and Oracle_Quote_Line__r.Prospect_Client__c != :acctId
                                     Group by Oracle_Quote_Line__r.Prospect_Client__c];
       Id[] acctIds = new Id[]{};
       for (AggregateResult result : results) {
           Id recId = (Id)result.get('acctId');
           acctIds.add(recId);
       }
       System.debug('getMultiIds oppId='+oppId+' acctId='+acctId+' acctIds='+acctIds.size());
       return acctIds;
    } // getMultiIds

    public static String getOppQuery() {
        String[] fldList = new String[]{};
        Schema.FieldSet oppFldSet = Schema.SObjectType.Opportunity.fieldSets.OpptyQueryFldSet;
        for (Schema.FieldSetMember fsm : oppFldSet.getFields()) {
            String fldName = fsm.getFieldPath();
            fldList.add(fldName);
        }
        // get the information from the referral partner for the product groups
        fldList.add('ReferralLookup__r.Referral_Partner__r.NSS_Source__c');
        fldList.add('ReferralLookup__r.Referral_Partner__r.Partner_Type__c'); 
        String queryString = 'Select '+String.join(fldList,',')
            +',(Select Id , OpportunityId, UserId, Name, PhotoUrl, Title, TeamMemberRole, OpportunityAccessLevel, NSS_Source__c, NSS_Team__c, CommissionEnd__c, CommissionStart__c, Prospect_Ownership__c from OpportunityTeamMembers)'       
            +',(Select Id, ContactId, IsPrimary, OpportunityId, Role from OpportunityContactRoles)'
            +' from Opportunity ';
            //+' from Opportunity where Id=:OpptyId limit 1';
        System.debug('getOppQuery queryString='+queryString);
        return queryString;
     } // getOppQuery
    
   public static String[] onboardingOppTypes = Label.OpptySplitOnboardingOppTypes.split(',');
    
   public class OppWrapper {
      public Opportunity opp;
      public OppWrapper(Opportunity p_opp) {
         opp = p_opp;
         original = (opp.Id != null);
      }
      public Boolean original=false;
      public OpportunityLineItem[] olis = new OpportunityLineItem[]{};
      public OpportunityContactRole[] ocrs = new OpportunityContactRole[]{};
      public Boolean createOnboarding{get{return (!original && opp != null && onboardingOppTypes.contains(opp.OpportunityType__c));}}
   } // class OppWrapper
    
   public class ResultWrapper {
      public Id parentOppId;
      public ResultWrapper(Id p_parentOppId) {
         parentOppId = p_parentOppId;
      }
      public Opportunity[] opps = new Opportunity[]{};
      public Boolean finishOkay=true;
      public Boolean splitSuccess=true;
   } // ResultWrapper
    
   public void splitOpportunity() {
      Id[] acctIds = new Id[]{};
      // only add the main account if we're splitting the product group
      boolean splitProdGroup = splitByProdGroupOkay;
      System.debug('splitOpportunity splitProdGroup='+splitProdGroup+' entryOpp.AccountId='+entryOpp.AccountId);
      if (splitProdGroup) {
         acctIds.add(entryOpp.AccountId);    
      }
      acctIds.addAll(getMultiIds(entryOpp.Id, entryOpp.Primary_Oracle_Quote__c, entryOpp.AccountId)); 
      handleSplitOpp(entryOpp.Id,  entryOpp.Primary_Oracle_Quote__c, acctIds, new ResultWrapper(entryOpp.Id));
   } // splitOpportunity
    
   public void handleSplitOpp(Id oppId, Id quoteId, Id[] acctIds, ResultWrapper results) {
      ErrorLog__c procLog = ErrorLog.getProcessLog(CLASSNAME);
      procLog.ObjectId__c = oppId;
      String logInfo = 'AcctIds='+acctIds;
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      // number of ids to process at once
      Integer nbrToProcess = (abc != null && abc.Active__c && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 5);
      String msg = 'oppId='+oppId+' quoteId='+quoteId+' acctIds='+acctIds.size()+' nbrToProcess='+nbrToProcess+' abc='+(abc != null);
      logInfo += '\n'+msg;
      System.debug('handleSplitOpp '+msg);
      // pull out the acctIds we're going to process this time
      Id[] acctIdsToProcess = new Id[]{};
      for (Integer cnt=0; (cnt<nbrToProcess && !acctIds.isEmpty()); cnt++) {
         acctIdsToProcess.add(acctIds.remove(0));
      }
      logInfo += '\nacctIdsToProcess='+acctIdsToProcess;
      // process inline however many ids we decide are allowed
      if (!acctIdsToProcess.isEmpty()) {
         ErrorLog.startLog1(procLog, 'processSplitOpp');
         processSplitOpp(oppId, quoteId, acctIdsToProcess);
         ErrorLog.endLog1(procLog);
      }
      // if there are other ids, we'll process those asynchronously
      logInfo += '\nsplitSuccess='+splitSuccess+' finishOkay='+finishOkay+' acctIds='+acctIds.size();
      System.debug('handleSplitOpp splitSuccess='+splitSuccess+' finishOkay='+finishOkay+' acctIds='+acctIds.size());
      results.finishOkay = (finishOkay && results.finishOkay);
      results.splitSuccess = (splitSuccess && results.splitSuccess);
      for (Opportunity opp : clonedOpptyList) {
         Opportunity newOpp = new Opportunity(Id=opp.Id, Name=opp.Name);
         results.opps.add(newOpp);
      }
      if (splitSuccess && finishOkay && !acctIds.isEmpty()) {
         logInfo += '\nLaunching Queueable';
         processingSplitAsync = true;
         OpptySplitQueueable.launchQueueable(new OpptySplitQueueable(oppId, quoteId, acctIds, cloneHandbookContact, results));
      } else if (processingSplitAsync) {
         logInfo += '\nSent Summary';
         // if this flag is true, we're in the async process
         // post a summary (email or chatter?) of the transaction
         sendSummary(results);
      }
      ErrorLog.addToDescription(procLog, logInfo);
      ErrorLog.saveLog(procLog);
   } // handleSplitOpp
    
   // for testing purposes
   public static Boolean summarySent=false;
    
   public void sendSummary(ResultWrapper results) {
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      String host = Utilities.getInstanceURL()+'/';
      String htmlBody = 'Summary of Opportunity Split:<br/>';
      String textBody = 'Summary of Opportunity Split: \n';
      for (Opportunity opp : results.opps) {
         String oppUrl = '<a href="'+host + '/lightning/r/'+String.valueOf(opp.Id)+'/view">'+opp.Name+'</a>';
         htmlBody += '<br/>'+oppUrl;
         textBody += '\n  '+opp.Name+': '+host + '/lightning/r/'+String.valueOf(opp.Id)+'/view ';
      }
      
      mail.setTargetObjectId(UserInfo.getUserId());
      mail.setSaveAsActivity(false);
      mail.setSubject('Opportunity Split Completed');
      mail.setHtmlBody(htmlBody);
      //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      ChatterMentionPost.createChatterMentionPost(results.parentOppId, new Id[]{UserInfo.getUserId()}, new String[]{textBody}, true, true);
      System.debug('sendSummary completed');
      summarySent = true;
   } // sendSummary
    
   public void processSplitOpp(Id oppId, Id quoteId, Id[] acctIds) {
      System.debug('processSplitOpp oppId='+oppId+' quoteId='+quoteId+' acctIds='+acctIds);
      //Query opportunity, Team members, and Line Items for cloning       
      String oppQuery = getOppQuery()+' where Id=:oppId limit 1';
      Opportunity originalOpp = Database.query(oppQuery);
      System.debug('splitOpportunity originalOpp='+originalOpp.Id);
       
      OpportunityLineItem[] originalOlis= (quoteId == null ?
                                           [Select Quantity, Payroll_Unit__c, Non_Payroll_Unit__c, Setup_Fee__c, Total_Calced__c, Setup_Fee_Original__c, PricebookEntryId, QuoteLineGroupAcct__c, ListPrice, UnitPrice
                                                    ,QuoteLineGroupAcctName__c
                                                  ,Product2.Product_Group__c
                                                  ,Oracle_Quote_Line__r.Prospect_Client__c,  Oracle_Quote_Line__r.Prospect_Client__r.Name
                                              from OpportunityLineItem 
                                             where OpportunityId =:oppId]
                                           : [Select Quantity, Payroll_Unit__c, Non_Payroll_Unit__c, Setup_Fee__c, Total_Calced__c, Setup_Fee_Original__c, PricebookEntryId, QuoteLineGroupAcct__c, ListPrice, UnitPrice
                                                 ,QuoteLineGroupAcctName__c
                                                 ,Product2.Product_Group__c
                                                 ,Oracle_Quote_Line__r.Prospect_Client__c,  Oracle_Quote_Line__r.Prospect_Client__r.Name
                                             from OpportunityLineItem 
                                            where OpportunityId =:oppId
                                              and Oracle_Quote_Line__r.cafsl__Oracle_Quote__c = :quoteId
                                              and Oracle_Quote_Line__r.Prospect_Client__c in :acctIds]);
      System.debug('processSplitOpp originalOlis='+originalOlis.size());
      // key is either the <account id> or the <account id><product group>
      Map<String,OppWrapper> oppSplitMap = new Map<String,OppWrapper>();
      // the original opp key will be based off the record type if we're splitting by product group
      OppProductGroup__c opg = getOpgByRecordTypeName(originalOpp.RecordType.Name);
      String defProdGroup = ((splitByProdGroupOkay && opg != null) ? opg.ProductGroup__c : '');
      System.debug('processSplitOpp splitByProdGroupOkay='+splitByProdGroupOkay+' defProdGroup='+defProdGroup+' originalOpp.RecordType.Name='+originalOpp.RecordType.Name);
      originalOpp.ProductGroupsSelected__c = defProdGroup;
      String origKey = originalOpp.AccountId+defProdGroup;
      oppSplitMap.put(origKey,new OppWrapper(originalOpp));
      
      Opportunity[] soldTriggerRcds = new Opportunity[]{};
      Id[] soldOpptyIds = new Id[]{};
          
      // go through the line items, moving them to the appropriate OppWrapper 
      for (OpportunityLineItem oli : originalOlis) {
         checkLineItem(originalOpp, oli, oppSplitMap, defProdGroup, soldTriggerRcds, soldOpptyIds);       
      } // for (OpportunityLineItem oli : originalOliList
      
      // if this list is empty, nothing was done. Exit here.
      if (clonedOpptyList.isEmpty()) {
         opptySplittable = false;
         handbookError = false;
         splitSuccess = false;
         return;
      }

      // make sure the sales parents are set on the associated accounts
      updateAccountSalesParents(originalOpp.AccountId);

      // at this point the line items should be split among the various cloned opps.  
      try {
         insert clonedOpptyList;
        // Primary Competition copied over from Old(Actual) Opp to New Opp when cloning and splitting the opportunities(APR0131946)
        List<Competitor__c> oppcomtToadd = new List<Competitor__c>() ;
         Competitor__c neRec; 
         for (Competitor__c compRec  : [select Id,Name,Primary__c, PickListValue__c from Competitor__c where Opportunity__c = :originalOpp.id]) {
            for (Opportunity rec : clonedOpptyList) {
               neRec = compRec.clone(false , false , false , false ) ; 
               neRec.Opportunity__c = rec.id; 
               oppcomtToadd.add(neRec); 
             }
         }
         insert oppcomtToadd; 
         handleRelatedObjects(originalOpp, oppSplitMap);
         update originalOpp;
         // check if we need to create a case thru OpportunityCreateCase process
         if (!soldOpptyIds.isEmpty()) {
            System.debug('soldOpptyIds=Not Empty');
            OpportunityCreateCase.processOpptysSold(soldOpptyIds);
         }
                
         // check if we need to create a case thru CreateRelatedObjects process
         if (!soldTriggerRcds.isEmpty()) {
            CreateRelatedObjects2.processSObjects('Opportunity',soldTriggerRcds);
         }
         finishOkay=true;
         splitSuccess=true;
      } catch (Exception e) {
         System.debug('Exception='+e);
         errorMsg = e.getMessage();
         if (e.getMessage().contains('FIELD_FILTER_VALIDATION_EXCEPTION')) {
            System.debug('opptySplittable=false, handbookError=true');
            opptySplittable = false;
            handbookError = true;
            splitSuccess = false;
         }
      } // try
      
   } // processSplitOpp
   /*
   public void splitOpportunity2() {
      //Query opportunity, Team members, and Line Items for cloning       
      String oppQuery = getOppQuery()+' where Id=:OpptyId limit 1';
      Opportunity originalOpp = Database.query(oppQuery);
      System.debug('splitOpportunity originalOpp='+originalOpp);
       
      // not sure if we still need this
      //Double originalIdNumber = originalOpp.Number_of_Ids__c;
      //tring originalIdList = originalOpp.List_of_Ids__c;
        
      OpportunityLineItem[] originalOliList= [Select Quantity, Payroll_Unit__c, Setup_Fee__c, Total_Calced__c, Setup_Fee_Original__c, PricebookEntryId, QuoteLineGroupAcct__c, ListPrice, UnitPrice
                                                    ,QuoteLineGroupAcctName__c
                                ,Product2.Product_Group__c
                                ,Oracle_Quote_Line__r.Prospect_Client__c,  Oracle_Quote_Line__r.Prospect_Client__r.Name
                            from OpportunityLineItem 
                           where OpportunityId =:originalOpp.id];
      // key is either the <account id> or the <account id><product group>
      Map<String,OppWrapper> oppSplitMap = new Map<String,OppWrapper>();
      // the original opp key will be based off the record type if we're splitting by product group
      OppProductGroup__c opg = getOpgByRecordTypeName(originalOpp.RecordType.Name);
      String defProdGroup = ((splitByProdGroupOkay && opg != null) ? opg.ProductGroup__c : '');
      System.debug('splitOpportunity defProdGroup='+defProdGroup);
      originalOpp.ProductGroupsSelected__c = defProdGroup;
      String origKey = originalOpp.AccountId+defProdGroup;
      oppSplitMap.put(origKey,new OppWrapper(originalOpp));
      
      Opportunity[] soldTriggerRcds = new Opportunity[]{};
      Id[] soldOpptyIds = new Id[]{};
      //Opportunity[] 
      // go through the line items, moving them to the appropriate OppWrapper 
      for (OpportunityLineItem oli : originalOliList) {
              checkLineItem(originalOpp, oli, oppSplitMap, defProdGroup, soldTriggerRcds, soldOpptyIds);       
      } // for (OpportunityLineItem oli : originalOliList
      
      // if this list is empty, nothing was done. Exit here.
      if (clonedOpptyList.isEmpty()) {
         opptySplittable = false;
         handbookError = false;
         splitSuccess = false;
         return;
      }
     
      // make sure the sales parents are set on the associated accounts
      updateAccountSalesParents(originalOpp.AccountId);

      // at this point the line items should be split among the various cloned opps.  
      try {
         insert clonedOpptyList;
        // Primary Competition copied over from Old(Actual) Opp to New Opp when cloning and splitting the opportunities(APR0131946)
        List<Competitor__c> oppcomtToadd = new List<Competitor__c>() ;
         Competitor__c neRec; 
         for (Competitor__c compRec  : [select Id,Name,Primary__c, PickListValue__c from Competitor__c where Opportunity__c = :originalOpp.id]) {
            for (Opportunity rec : clonedOpptyList) {
               neRec = compRec.clone(false , false , false , false ) ; 
               neRec.Opportunity__c = rec.id; 
               oppcomtToadd.add(neRec); 
             }
         }
         insert oppcomtToadd; 
         handleRelatedObjects(originalOpp, oppSplitMap);
         update originalOpp;
         // check if we need to create a case thru OpportunityCreateCase process
         if (!soldOpptyIds.isEmpty()) {
            System.debug('soldOpptyIds=Not Empty');
            OpportunityCreateCase.processOpptysSold(soldOpptyIds);
         }
                
         // check if we need to create a case thru CreateRelatedObjects process
         if (!soldTriggerRcds.isEmpty()) {
            CreateRelatedObjects2.processSObjects('Opportunity',soldTriggerRcds);
         }
         finishOkay=true;
         splitSuccess=true;
      } catch (Exception e) {
         System.debug('Exception='+e);
         errorMsg = e.getMessage();
         if (e.getMessage().contains('FIELD_FILTER_VALIDATION_EXCEPTION')) {
            System.debug('opptySplittable=false, handbookError=true');
            opptySplittable = false;
            handbookError = true;
            splitSuccess = false;
         }
      } // try
      

   } // splitOpportunity
    */
   public static Map<String,String> oppTypeByProdGroupMap = null;
    
   public String getOppType(String prodGroup, String defOppType) {
      String retVal = defOppType;
      if (String.isNotBlank(prodGroup)) {
         if (oppTypeByProdGroupMap == null) {
            oppTypeByProdGroupMap = new Map<String,String>();
            for (OppProductGroup__c opg : OppProductGroup__c.getAll().values()) {
               if (!oppTypeByProdGroupMap.containsKey(opg.ProductGroup__c)) {
                  oppTypeByProdGroupMap.put(opg.ProductGroup__c, opg.OpportunityType__c);
               }
            }
         } // if (oppTypeByProdGroupMap == null
         retVal = oppTypeByProdGroupMap.containsKey(prodGroup) ? oppTypeByProdGroupMap.get(prodGroup) : defOppType;
      } // if (String.isNotBlank(prodGroup
      return retVal;
   } // getOppType
    
   public OppProductGroup__c getOpgByRecordTypeName(String recordTypeName) {
      OppProductGroup__c foundOpg = null;  
      for (OppProductGroup__c opg : OppProductGroup__c.getAll().values()) {
         if (recordTypeName == opg.RecordTypeName__c) {
             foundOpg = opg;
             break;
         }
      } // for (OppProductGroup__c opg : OppProductGroup__c
      return foundOpg;
   } // getOpgByRecordTypeName

   public Opportunity cloneOpp(Opportunity opp, Opportunity[] soldTriggerRcds, Id[] soldOpptyIds) {
      Opportunity clonedOpp = opp.clone(false, true);
      //clonedOpp.Name = opptyProduct.Oracle_Quote_Line__r.Prospect_Client__r.Name +'_'+opp.Payroll_Platform__c;
      clonedOpp.Primary_Oracle_Quote__c = null;
      //clonedOpp.AccountId = opptyProduct.Oracle_Quote_Line__r.Prospect_Client__c;
      clonedOpp.OppSource__c='Opportunity Split';
      clonedOpp.Primary_Opportunity__c = (opp.Primary_Opportunity__c == null ? opp.Id : opp.Primary_Opportunity__c);

      if (!cloneHandbookContact) {
         clonedOpp.Handbook_Contact__c = null;
      }                  
      clonedOpp.Payroll_Unit__c = false;
      clonedOpp.Child_Unit__c = true;
      clonedOpp.Number_of_Ids__c = 1;
      clonedOpp.List_of_Ids__c = '';
      clonedOpp.New_or_Existing_Business__c = null;
      clonedOpp.Employees_Paid_Per_Payroll__c = null;
      // not sure if we should be populating this on the multi-ids. Clearing it out for now.
      clonedOpp.ReferralLookup__c = null;
      // make sure the stageName is the same. Not sure why they'd be different?
      if (clonedOpp.StageName != opp.StageName) {
         clonedOpp.StageName = opp.StageName;
      }
      //To verify related objects
      if (soldTriggerRcds != null && clonedOpp.Service_Location__c != null && (clonedOpp.Probability >= 80 && clonedOpp.Probability < 100)) {                    
         if (CreateRelatedObjects2.getObjRelOptyRcdTypes().contains(clonedOpp.RecordTypeId)) {
            soldTriggerRcds.add(clonedOpp);  
         } else {
            soldOpptyIds.add(clonedOpp.Id);  
         } 
      }
      //Add to cloned opportunity list
      clonedOpptyList.add(clonedOpp);
      return clonedOpp;
   } // cloneOpp
    
   public Boolean checkLineItem(Opportunity opp, OpportunityLineItem oli, Map<String,OppWrapper> oppSplitMap, String defProdGroup, Opportunity[] soldTriggerRcds, Id[] soldOpptyIds) {
      Boolean okay = true;
      // use the account id from the oli if there is one, otherwise default to the opp account id
      Id acctId = (oli.Oracle_Quote_Line__r != null && oli.Oracle_Quote_Line__r.Prospect_Client__c != null ? oli.Oracle_Quote_Line__r.Prospect_Client__c : opp.AccountId);
      // if product groups are being used and the product group is blank, use the default, otherwise use a blank value
      String prodGroup = (String.isNotBlank(defProdGroup) ? (String.isNotBlank(oli.Product2.Product_Group__c) ? oli.Product2.Product_Group__c : defProdGroup) : '');
      String key = acctId+prodGroup;
      System.debug('checkLineItem key='+key); 
      OppWrapper oppWrap = oppSplitMap.get(key);
      if (oppWrap == null) {
         System.debug('checkLineItem create a new clone opp');
         Opportunity clonedOpp = cloneOpp(opp,soldTriggerRcds,soldOpptyIds);
         String acctName = (oli.Oracle_Quote_Line__r != null && oli.Oracle_Quote_Line__r.Prospect_Client__r != null ? oli.Oracle_Quote_Line__r.Prospect_Client__r.Name : opp.Account.Name);
         clonedOpp.Name = acctName +'-'+(String.isNotBlank(prodGroup) ? prodGroup : opp.Payroll_Platform__c); // do we use product group also?
         clonedOpp.AccountId = (oli.Oracle_Quote_Line__r != null && oli.Oracle_Quote_Line__r.Prospect_Client__c != null ? oli.Oracle_Quote_Line__r.Prospect_Client__c : opp.AccountId);
         clonedOpp.OpportunityType__c = getOppType(prodGroup, opp.OpportunityType__c);
         clonedOpp.ProductGroupsSelected__c = (String.isNotBlank(prodGroup) ? prodGroup : null);
          
         oppWrap = new OppWrapper(clonedOpp);
         oppSplitMap.put(key,oppWrap);
      }
      // group the olis with the ending opportunity. We will clone/delete them later if we're not on the original opp.
      oppWrap.olis.add(oli);
       
       
      return okay;
   } // checkLineItem

    
   public void handleRelatedObjects(Opportunity originalOpp, Map<String,OppWrapper> oppSplitMap) {
      OpportunityLineItem[] oliInserts = new OpportunityLineItem[]{};
      OpportunityLineItem[] oliDeletes = new OpportunityLineItem[]{};
      OpportunityTeamMember[] otmInserts = new OpportunityTeamMember[]{};
      OpportunityContactRole[] ocrInserts = new OpportunityContactRole[]{};
      Map<Id,Opportunity> oppUpdateMap = new Map<Id,Opportunity>();
      Map<Id,Referral__c> refUpdateMap = new Map<Id,Referral__c>();
      System.debug('handleRelatedObjects oppSplitMap='+oppSplitMap.size());
      // if there are existing referral attached to the account for product group mapping, store in a map for easy reference
      Map<String,Referral__c> refMap = new Map<String,Referral__c>();
      if (splitByProdGroupOkay && originalOpp.ReferralLookup__c != null && originalOpp.ReferralLookup__r.Referral_Partner__r != null) {
         Referral__c[] refs = [Select Id, Selling_Opportunity__c
                                     ,Referral_Partner__r.Product_Of_Interest_Product_Group__c
                                     ,Referral_Partner__r.NSS_Source__c, Referral_Partner__r.Partner_Type__c
                                 From Referral__c
                                Where Account__c=:originalOpp.AccountId
                                  and Referral_Partner__r.Partner_Type__c = :originalOpp.ReferralLookup__r.Referral_Partner__r.Partner_Type__c
                                  and Referral_Partner__r.NSS_Source__c = :originalOpp.ReferralLookup__r.Referral_Partner__r.NSS_Source__c
                                  and Referral_Partner__r.Product_Of_Interest_Product_Group__c != null];
         System.debug('handleRelatedObjects ref='+refs.size());
         for (Referral__c ref : refs) {
            System.debug('handleRelatedObjects adding '+ref.Referral_Partner__r.Product_Of_Interest_Product_Group__c+' to refMap');
            refMap.put(ref.Referral_Partner__r.Product_Of_Interest_Product_Group__c,ref);
         }
      } // if (splitByProdGroupOkay
       
      for (OppWrapper oppWrap : oppSplitMap.values()) {
         // we don't need to do anything for the original opp
         Boolean sameAcct = (oppWrap.opp.AccountId == originalOpp.AccountId);
         System.debug('handleRelatedObjects opp='+oppWrap.opp.Name+' original='+oppWrap.original+' id='+oppWrap.opp.Id+' sameAcct='+sameAcct+' ProductGroupsSelected__c='+oppWrap.opp.ProductGroupsSelected__c);
         // if there are referrals, move them to the correct opportunity if this is a product group split
         if (sameAcct && String.isNotBlank(oppWrap.opp.ProductGroupsSelected__c) && refMap.containsKey(oppWrap.opp.ProductGroupsSelected__c)) {
            System.debug('handleRelatedObjects setting ref');
            Referral__c ref = refMap.get(oppWrap.opp.ProductGroupsSelected__c);
            System.debug('handleRelatedObjects setting ref id='+ref.Id);
            if (ref.Selling_Opportunity__c != oppWrap.opp.Id) {
               ref.Selling_Opportunity__c = oppWrap.opp.Id;
               refUpdateMap.put(ref.Id, ref);
               System.debug('handleRelatedObjects add to refUpdateMap');
            }
            if (oppWrap.opp.ReferralLookup__c != ref.Id) {
               oppWrap.opp.ReferralLookup__c = ref.Id;
               oppUpdateMap.put(oppWrap.opp.Id, oppWrap.opp);
               System.debug('handleRelatedObjects add to oppUpdateMap');
            }
         }
         if (sameAcct && !oppWrap.original && oppWrap.opp.Id != null) {
            for (OpportunityContactRole ocr : originalOpp.OpportunityContactRoles) {
               OpportunityContactRole newOcr = ocr.clone(false,true);
               newOcr.OpportunityId = oppWrap.opp.Id;
               ocrInserts.add(newOcr);
            }
         }
         if (!oppWrap.original && oppWrap.opp.Id != null) {
            // clone the team members for the new opp
            for (OpportunityTeamMember otm : originalOpp.OpportunityTeamMembers) {
               OpportunityTeamMember newOtm = otm.clone(false, true);
               newOtm.OpportunityId = oppWrap.opp.Id;
               otmInserts.add(newOtm);
            }
             
            Double unitCount = 0.0;
            Double setupFee = 0.0;
            Double unitCountNP = 0.0;
            for (OpportunityLineItem oli : oppWrap.olis) {
               unitCount = unitCount + (oli.Payroll_Unit__c != null ? oli.Payroll_Unit__c : 0);
               setupFee = setupFee + (oli.Setup_Fee__c != null ? oli.Setup_Fee__c : 0);
               unitCountNP = unitCountNP + (oli.Non_Payroll_Unit__c != null ? oli.Non_Payroll_Unit__c : 0);
               OpportunityLineItem cloneOLI = oli.clone(false, true);
               cloneOLI.OpportunityId = oppWrap.opp.Id;
               oliInserts.add(cloneOLI);
               oliDeletes.add(oli);
            } // for (OpportunityLineItem oli
            if (unitCount != oppWrap.opp.Payroll_Units__c && oppWrap.opp.Service_Location__c!='') {
               oppWrap.opp.Payroll_Units__c = unitCount;
               oppUpdateMap.put(oppWrap.opp.Id, oppWrap.opp);
            }
            if (setUpFee != oppWrap.opp.Setup_Fee__c) {
               oppWrap.opp.Setup_Fee__c = setUpFee;
               oppUpdateMap.put(oppWrap.opp.Id, oppWrap.opp);
            }
            if (unitCountNP != oppWrap.opp.Non_Payroll_Units__c && oppWrap.opp.Service_Location__c!='') {
               oppWrap.opp.Non_Payroll_Units__c = unitCountNP;
               oppUpdateMap.put(oppWrap.opp.Id, oppWrap.opp);
            }
         } // if (!oppWrap.original
      } // for (Opportunity opp

      System.debug('handleRelatedObjects otmInserts='+otmInserts.size()+' oliDeletes='+oliDeletes.size()+' oliInserts='+oliInserts.size()+' oppUpdateMap='+oppUpdateMap.size()+' refUpdateMap='+refUpdateMap.size());
      if (!otmInserts.isEmpty()) {
         insert otmInserts;
      }
      if (!oliDeletes.isEmpty()) {
         delete oliDeletes;
      }
      if (!oliInserts.isEmpty()) {
         insert oliInserts;
      }
      if (!ocrInserts.isEmpty()) {
         insert ocrInserts;
      }
      if (!oppUpdateMap.isEmpty()) {
         OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
         update oppUpdateMap.values();
         OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
      }
      if (!refUpdateMap.isEmpty()) {
         ReferralTriggerActions.SKIP_TRIGGER=true;
         update refUpdateMap.values();
         ReferralTriggerActions.SKIP_TRIGGER=false;
      }      
      setupOnboardingRecords(originalOpp, oppSplitMap);

   } // handleRelatedObjects

   //Setup Onboarding records for the child opportunities. Copy over most of the parent data.
   public void setupOnboardingRecords(Opportunity originalOpp, Map<String,OppWrapper> oppSplitMap) {
      System.debug('OpptySplitController setupOnboardingRecords originalOpp='+originalOpp.Name);
      System.debug('OpptySplitController setupOnboardingRecords oppSplitMap='+oppSplitMap.size());
      List<Onboarding_Tool__c> NCPToInsert = new List<Onboarding_Tool__c>();
      Map<Id,Onboarding_Tool__c> updateOnboardingMap = new Map<Id,Onboarding_Tool__c>();
      Map<Id,Reference_CTT__c> cttUpdateMap = new Map<Id,Reference_CTT__c>();
      List<Onboarding_Tool__c> parentNCPList = new List<Onboarding_Tool__c>();
      parentNCPList = [SELECT Id
                            ,Accidental_Death__c
                            ,Accounts_Payable_Contact__c
                            ,Add_Onboarding__c
                            ,Alternative_Email__c
                            ,Anticipated_Start_Date__c
                            ,Authorize_Officer__c
                            ,Authorized_Officer_Title__c
                            ,Authorized_Officer_Email__c
                            ,Authorized_Officer_Phone__c
                            ,Authorized_Officer_Name__c
                            ,BankDocumentation__c
                            ,Branch_Number__c
                            ,Best_Call_Time__c
                            ,Business_Structure__c
                            ,changeFSS__c
                            ,ChangeOfEntity__c
                            ,Client_Loss_Risk__c
                            ,Client_Number__c
                            ,Client_Require_Instructions__c
                            ,Combo__c 
                            ,Company_Contact__c
                            ,Company_Contact__r.Email
                            ,Company_Contact_Name__c
                            ,Contact_Email__c
                            ,Contact_is_HRAdmin__c
                            ,Core_Medical__c
                            ,Date_Business_Formed__c
                            ,Decision_Factors_Other__c
                            ,Dental__c
                            ,DiscountOffered__c
                            ,EmpsToLoad__c
                            ,ESR_educationInstitution__c
                            ,ESR_PriorMedRenewalDate__c
                            ,ESR_selfInsuredPlan__c
                            ,ESR_UnionEmps__c
                            ,First_Check_Date__c
                            ,Flex_Multi_Debit__c
                            ,Flex_Selling_Division__c
                            ,Flextime_Date__c
                            ,Flextime_ImpDate__c
                            ,Flextime_TAA__c
                            ,Flextime_Timeclock__c
                            ,FSS_Name__c
                            ,GL__c
                            ,Group_Term_Life__c
                            ,Handbook_Format__c
                            ,HR_Administrator__c
                            ,HR_Admin__c
                            ,HRE_Decision_Factors__c
                            ,HRE_Decision_Factors_2__c
                            ,HRE_Decision_Factors_3__c
                            ,HRE_Existing__c
                            ,HRE_Existing_Safety_Manual__c
                            ,HRE_Paychex_created_existing__c
                            ,HRE_Paychex_created_existing_safety__c
                            ,HRE_Reason_Selected__c
                            ,HRE_Num_of_Locations__c
                            ,HR_Genralist__c
                            ,HRG_Name__c
                            ,HRS_Sales_Rep__c
                            ,HRS_Sales_Rep_Name__c
                            ,Insurance_Carrier__c
                            ,Irs_Address__c
                            ,IrsIsDelivery__c
                            ,IsCompanyContact__c
                            ,Is_Parent__c
                            ,Large_Market_Sales_Rep__c
                            ,Long_Term_Disability__c
                            ,LostClientRisk__c
                            ,Migrating_from_preview_to_flex__c
                            ,MigrateToFlex__c
                            ,Multi_ID__c
                            ,Multi_Id_Billing__c
                            ,Multi_Id_Submission__c
                            ,MultiBillingOption__c
                            ,MultiProdServiceCenter__c
                            ,New_Branch__c
                            ,New_Client__c
                            ,New_Existing__c
                            ,NumComboIds__c
                            ,NumEeToLoad__c
                            ,NumOf1099s__c
                            ,NumFlexId__c
                            ,Num_Management_EE__c
                            ,NumMultiIds__c
                            ,NumYearsWagesToLoad__c
                            ,Onboarding_Contact__c
                            ,OnboardingType__c
                            ,Ongoing_Pay_Period_End_Date__c
                            ,Ongoing_Call_Day_of_the_Week__c
                            ,Ongoing_Check_Day_of_the_Week__c
                            ,Opportunity_Id__c
                            ,Owner_Manager__c
                            ,Pay_Demand__c
                            ,PayrollContact__c 
                            ,PayrollContact_Title__c
                            ,PayrollContact_Phone__c
                            ,PayrollContact_Email__c
                            ,Payroll_Contact_Name__c
                            ,PayrollContact__r.Title
                            ,PayrollRep__c
                            ,Payroll_Rep__c
                            ,Payroll_Rep_Name__c
                            ,PayrollProcessed__c
                            ,PeriodEndDate__c
                            ,PESS__c
                            ,PESS_Background_Screening__c
                            ,PESS_Drug_Testing__c
                            ,PESS_I9_Verification__c
                            ,PESS_Motor_Vehicle_Report__c
                            ,Pop__c
                            ,PreAssignedClientNum__c 
                            ,PreAssignedId__c
                            ,Preferred_Contact_Method__c
                            ,Previous_Platform__c
                            ,PriceLock3Year__c
                            ,PriorWagesLoaded__c 
                            ,Product__c
                            ,ProductList__c
                            ,Promotions__c
                            ,ReadyChex__c
                            ,RecruitingLiveDate__c
                            ,RecruitingStartDate__c
                            ,RelatedAccountId__c
                            ,RelationWithAddAccount__c
                            ,Run_Date__c
                            ,Short_Term_Disability__c
                            ,Spanish__c
                            ,Spanish_Speaking_Needs__c
                            ,StateProcessedIn__c
                            ,Submitter__c
                            ,SubmissionDate__c
                            ,NCP_Submitted__c
                            ,Supporting_Documentation__c
                            ,Skylight__c
                            ,Taxpay__c
                            ,Tax_Exempt__c
                            ,Tax_Exempt_Id__c
                            ,Total_Num_EE__c
                            ,Vision__c
                            ,Workers_Compensation__c
                            ,Workers_Comp_Policy__c
                            ,Workers_Comp_Expiration_Date__c
                            ,Client_Key_Own_Payroll__c
                            ,Training__c
                            ,Type_Of_Employer__c
                            ,Has_Client_Applied_For_State_SUI_IDS__c
                            ,Form_Type__c
                            ,(SELECT Id, Name, Number_of_Ids__c FROM Reference_CTT__r) FROM Onboarding_Tool__c WHERE Opportunity_Id__c = :originalOpp.Id];
        
      //Id there is already an existing NCP on the parent, copy data to the child.
      Onboarding_Tool__c parentNCP = (parentNCPList.size() == 1 ? parentNCPList[0] : null);
      for (OppWrapper oppWrap : oppSplitMap.values()) {
         if (oppWrap.createOnboarding) {
            if (parentNCP != null && parentNCP.Id != null) {
               System.debug('OpptySplitController Creating Child Onboarding Records');
               Onboarding_Tool__c childOnboardingRecord = parentNCP.clone(false, true, false, false);
               childOnboardingRecord.Name = oppWrap.opp.Name;
               childOnboardingRecord.Opportunity_Id__c = oppWrap.opp.Id;
               childOnboardingRecord.Is_Child__c = true;
                
               childOnboardingRecord.ReadyChex__c = null;
               childOnboardingRecord.GL__c = null;
               childOnboardingRecord.Accounting_Software__c = null;
               childOnboardingRecord.Other_Accounting_Software__c = null;
               childOnboardingRecord.Skylight__c = null;
               childOnboardingRecord.Pay_Demand__c = null;
               childOnboardingRecord.Workers_Compensation__c = null;
                
               childOnboardingRecord.Authorize_Officer__c = null;
               //childOnboardingRecord.Authorize_Officer_Title__c = null;
               childOnboardingRecord.Authorized_Officer_Phone__c = null;
               childOnboardingRecord.Authorized_Officer_Email__c = null;
               childOnboardingRecord.Authorized_Off_is_Payroll_Contact__c = null;
                   
               childOnboardingRecord.PayrollContact__c = null;
               childOnboardingRecord.PayrollContact_Title__c = null;
               childOnboardingRecord.PayrollContact_Phone__c = null;
               childOnboardingRecord.PayrollContact_Email__c = null;
               
               childOnboardingRecord.Run_Date__c = null;
               childOnboardingRecord.First_Check_Date__c = null;
               childOnboardingRecord.PeriodEndDate__c = null;
                
               childOnboardingRecord.PriorWagesLoaded__c = null; 
               childOnboardingRecord.IrsIsDelivery__c = null;
               childOnboardingRecord.Irs_Address__c = null;
               childOnboardingRecord.Business_Structure__c = null;
               childOnboardingRecord.Taxed_as_S_Corp__c = false;
               childOnboardingRecord.PreAssignedClientNum__c = 'No';
               childOnboardingRecord.PreAssignedId__c = null;
                
               childOnboardingRecord.StateProcessedIn__c = null;
               childOnboardingRecord.NumOf1099s__c = null; 
               childOnboardingRecord.EmpsToLoad__c = null;
               childOnboardingRecord.Combo__c = null;
               childOnboardingRecord.NumComboIds__c = null;
 
               childOnboardingRecord.NCP_Submitted__c = false;
               childOnboardingRecord.Submitter__c = null;
               childOnboardingRecord.SubmissionDate__c = null;
               childOnboardingRecord.Parent_Onboarding_Record__c = parentNCP.Id;
               childOnboardingRecord.Is_Parent__c=false;
               System.debug('OpptySplitController childOnboardingRecord='+childOnboardingRecord);
               if (!parentNCP.Is_Parent__c) {
                  parentNCP.Is_Parent__c=true;
                  Onboarding_Tool__c updateParent = new Onboarding_Tool__c(Id=parentNCP.Id, Is_Parent__c=true);
                  updateOnboardingMap.put(parentNCP.Id, updateParent);
               }
               NCPToInsert.add(childOnboardingRecord);
                
               if (parentNCP.Reference_CTT__r != null && parentNCP.Reference_CTT__r.size() == 1) {
                  parentNCP.Reference_CTT__r[0].Number_of_Ids__c += 1;
                  cttUpdateMap.put(parentNCP.Reference_CTT__r[0].Id, parentNCP.Reference_CTT__r[0]);
               } // if (parentNCP.Reference_CTT__r != null
            } else {
               //If there is not a currently existing NCP on the parent, create the child NCPs anyways. 
               if (parentNCP == null) {
                  parentNCP = new Onboarding_Tool__c();
                  parentNCP.Opportunity_Id__c = originalOpp.Id;
                  parentNCP.AccountId__c = originalOpp.AccountId;
                  parentNCP.Is_Parent__c = true;
                  NCPToInsert.add(parentNCP);
               }
                
               Onboarding_Tool__c childOnboardingRecord = new Onboarding_Tool__c();
               childOnboardingRecord.Name = oppWrap.opp.Name;
               childOnboardingRecord.Opportunity_Id__c = oppWrap.opp.Id;
               childOnboardingRecord.Is_Child__c = true;
               childOnboardingRecord.NCP_Submitted__c = false;
               NCPToInsert.add(childOnboardingRecord);
               oppWrap.opp.Employees_Paid_Per_Payroll__c = null;
            } // if (parentNCP != null
         } // if (oppWrap.createOnboarding
      } // for (OppWrapper oppWrap : oppSplitMap.values
       
      System.debug('setupOnboardingRecords NCPToInsert='+NCPToInsert.size()+' updateOnboardingMap='+updateOnboardingMap.size()+' cttUpdateMap='+cttUpdateMap.size());
      if (!NCPToInsert.isEmpty()) {
         insert NCPToInsert;
      }
      if (!updateOnboardingMap.isEmpty()) {
         update updateOnboardingMap.values();
      }
      if (!cttUpdateMap.isEmpty()) {
         update cttUpdateMap.values();
      }
   } // setupOnboardingRecords
    
   public PageReference cloneOpportunity() {
      PageReference pageref = new PageReference('/apex/CloneOpportunity');
      pageref.getParameters().put('id', OpptyId);
      pageref.setRedirect(true); // If you want a redirect. Do not set anything if you want a forward.
      return pageref;
   } // cloneOpportunity

   public PageReference submittedRevenueClone() {   
      PageReference pageref = new PageReference('/apex/SubmittedRevenueClone');   
      pageref.getParameters().put('id', OpptyId); 
      pageref.setRedirect(true);  
      return pageref; 
   } // submittedRevenueClone
    
   public PageReference returnToOpportunity() {   
      PageReference pageref = new PageReference('/'+OpptyId);
      pageref.setRedirect(true);
      return pageref; 
   } // returnToOpportunity

   private void updateAccountSalesParents(Id salesParentId){
      System.debug('updateAccountSalesParents salesParentId='+salesParentId);
      if (salesParentId != null) {
         Id[] acctIds = new Id[]{};
         for (Opportunity opp : clonedOpptyList) {
            if (opp.AccountId != null && opp.AccountId != salesParentId) {
               acctIds.add(opp.AccountId);
            }
         } // for (Opportunity opp : opps

         Account[] accts = (acctIds.isEmpty() ? new Account[]{} : [Select Id, SalesParent__c from Account where Id in :acctIds and SalesParent__c != :salesParentId]);
         Account[] acctsToUpdate = new Account[]{};
             
         for (Account acct : accts) {
            if (acct.SalesParent__c != salesParentId) {
               acct.SalesParent__c = salesParentId;
               acctsToUpdate.add(acct);
            }
         } // for (Account acct : accounts      
         System.debug('updateAccountSalesParents acctIds='+acctIds.size()+' accts='+accts.size()+' acctsToUpdate='+acctsToUpdate.size());
         if (!acctsToUpdate.isEmpty()) {
            update acctsToUpdate;
         }
      } // if (salesParent != null 
    } // updateAccountSalesParents
    
} // class OpptySplitController