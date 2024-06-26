/* 
 * Controller for creating an Opportunity and Event. If the source is a Lead, will also convert the lead.
 *
 * History
 * -------
 * 12/29/2010 Dan Carmen        Created from ContactOpportunityExtension and ConvertLeadWithMeeting.
   03/01/2011 Dan Carmen        Added in logic for the other sales forces. 
   04/15/2011 Dan Carmen        Added check for Location field to make sure not more than 80 characters. 
   09/08/2011 Dan Carmen        Change so all use the same lead source
   10/13/2011 Dan Carmen        Modify so latest active campaign is attached to Opportunity.
   12/09/2011 Carrie Marciano   changed Auto_Create_Follow_up__c to be true only when !isAncilary
   02/16/2011 Dan Carmen        Modify so HRS close date is 90 days.
   08/20/2012 Dan Carmen        Refactored close date and stage fields.
   10/24/2012 Carrie Marciano   Added new Tier 1 Bank fields to be pushed to Opportunity and Prospect-Client on convert.
   01/24/2013 Cindy Freeman     make some variables and handleLeadConvert method public for use by FAReferralController 
   08/21/2013 Dan Carmen        Changes for NSS
   06/07/2014 Cindy Freeman     added stuff for Chatter Post when opty or event is created
   12/09/2014 Dan Carmen        Do not convert extra leads of certain lead sources
   02/03/2015 Justin Henderson  Changed MMS value for initial stage
   07/15/2015 Dan Carmen        Changes for virtual sales
   12/15/2015 Cindy Freeman     use Language__c field on Lead/Account to set opty Spanish Speaking Needs field
   02/29/2016 Cindy Freeman    overload getOppFirstStage so can pass in opty record type to figure out default stagename
   03/16/2016 Dan Carmen        Make isCore the default when checking the sales org.
   03/30/2016 Jacob Hinds       Added in logic so when a vsr converts a lead it fills in the NSS Source.
   04/06/2016 Justin Stouffer   Added in logic to display differently in Salesforce1.
   06/24/2016 Jacob Hinds       Added in a space to the address when creating event.
   12/07/2016 Carrie Marciano   changed Auto_Create_Follow_up__c to be true only when !isAncilary for MMS, Core does not want this auto-populated
   12/15/2016 Cindy Freeman     modified to update Marketing Call Tracking record on lead convert, and get keywords to put onto new opty if created by NSS
   01/26/2017 Jacob Hinds       Re-Adding some code related to PartnerReferral that got overwritten.
   02/24/2017 Jacob Hinds       Adding MSP product name
   03/02/2017 Jacob Hinds       Adding in Duplicate Oppty Code
   03/07/2017 Jacob Hinds       Small adjustment to opportunityJoin code
   03/13/2017 Jermaine Stukes   Update to no longer populate lead source on create.
   03/27/2017 Jacob Hinds       Update to lead source to pull from partner referral if user is virtual sales inbound.
   03/29/2017 Jacob Hinds       Commenting out above line
   04/25/2017 Sunnish Annu      Updated the code to extend the current default Run Effective Date to be set to 30 days from Opportunity Creation Date. For all Core Opportunities.
   05/08/2017 Cindy Freeman     changed saveOpp so only sends opty/contact to MarketTrackingMethods if Inbound NSS was creating opty
   06/22/2017 Lynn Michels       added a new method to set default stageName for referral selling opps
   11/01/2017 Dan Carmen        Additional functionality for tasks and events.
   12/04/2017 Jacob Hinds       Changing partnerReferral query on line 1075+1078
   12/20/2017 Dan Carmen        Added code for duplicate opportunity handling
   01/22/2018 Dan Carmen        Fix for converting a lead
   02/07/2018 Dan Carmen        Fix for NPE
   02/27/2018 Lynn Michels      store employee count on Referral when Opportunity is created.
   07/12/2018 Dan Carmen        Change call for setting the Opportunity Type
   11/08/2018 Dan Carmen        Fix for query selecting partner referrals for contacts   
   03/11/2019 Jacob Hinds       Adding PEO Sales Org
   04/02/2019 Dan Carmen        Add additional error capture on lead convert
   05/31/2019 Dan Carmen        Make initializeContact public
   07/14/2019 Jermaine Stukes   Added close cadence logic
   10/14/2019 Jermaine Stukes   Update Cadence logic
   10/17/2019 Dan Carmen        Only save errors in certain conditions
   12/12/2019 Dan Carmen        Change when the referral is saved in relation to the opp
   02/25/2020 Saketh Mysa       Hide Remove Meeting button on Remove Opportunity & Add New meeting section when Adding Opporunity
   04/30/2020 Saketh Mysa       US 34010746 Updates
   06/20/2020 Dan Carmen        Change to how the account is updated after a lead converts
   08/30/2020 Michael Karcz     Removed setting Event.Type to Initial Presentation in createEvent()
   10/22/2020 Dan Carmen        Simplify setting the event.type
   11/16/2020 Brandon Vidro     APR0109214 - Added Other Competition field
   02/12/2021 Dan Carmen        Set DG_LMF_Service.convertedLeadId = leadToConvert.Id;  (line 1795)
   04/28/2021 Dan Carmen        Changed setupCompanyList to query by zip code for performance (reduced load time from 2 minutes to 20 seconds)
   05/07/2021 Josh Cartwright   APR0118271 - defaulting to PEO opportunitytype and RT when PEOPotential indicator 
   06/16/2021 Josh Cartwright   INC2695441 - moved set defaults() up in the code, RT was not being set early enough to check for dupes
   06/28/2021 Eric Porter       APR0118206 changed CreateEvent Method to include Referral Contacts (line )
   07/26/2021 Jermaine Stukes   APR0111325 - Add PRN logic to SaveOpp
   10/20/2021 Dan Carmen        Added Products of Interest for HRS reps
   12/13/2021 Eric Porter       APR0116379 updated Current_Prior_Method to be autopopulated on Opp for Leads and Contacts
   02/09/2022 Carrie Marciano   Moved sp1 = Database.setSavepoint(); into the Try due to Not Serializable: System.Savepoint errors when Client Referral not populated
   03/02/2022 Dan Carmen        APR0131613 Update setupPricebooks method
   03/09/2022 Carrie Marciano   added check to use the default Opportunity Type from SalesOrg__c if populated, this takes precedence over the Opportunity Type set by the RecordType__c
   11/10/2022 Carrie Marciano   Shortened DoNotConvertLeadSources__c with RecordTypeHelper.cleanRtName as the solution
   04/24/2023 Eric Porter       Commented Out Primary Competition Code for Competitive Intelligence clean up effort
   05/12/2023 Rohit Ranjan APR0148368: Removed Payroll_Unit__c Checkbox Reference
   06/23/2023 Susmitha Somavarapu Upon HR Services Rep creates an Opp on an account tagged with PEO Potential dispaly and send Chatter to remind them to create a Client Referral (APR0152220)
   09/08/2023 Shilpa            APR0150200: Updated method 'createOpp' so when Opp Type equals HR Partner Plus Standalone, Payroll Unit field is uncheck
   12/14/2023 Dan Carmen        Add logging
   01/04/2024 Jaipal            Changed all OpportunityType__c's from 'ASO' to 'Label.HR_Pro_Upgrade' due to the APR Picklist value changes as per APR0152338
   02/16/2024 Pujitha Madamanchi    Add missing query fields based on blob removal and PR mapping update.
   02/26/2024 Dan Carmen        Small change to getConvertStatus - added Label.Lead_ConvertedStatus
   04/30/2024 Dan Carmen        Set ShippingUUID__c on lead convert since we're skipping the triggers
   

 */
public without sharing class CreateOppAndMeeting extends PageControllerBase {

   public static final String CLASSNAME='CreateOppAndMeeting';
   
   public static final String CREATE_NEW_ACCT='000000000000000';
   
   /** For the PageControllerBase virtual class.
    */
   public MeetingController myComponentController { get; set; }
    
   /** For the PageControllerBase virtual class.
    */
   public override void setComponentController(ComponentControllerBase compController) {
      myComponentController = (MeetingController)compController;
   } // setComponentController

   /** For the PageControllerBase virtual class.
    */
   public override ComponentControllerBase getMyComponentController() {
      return myComponentController;
   } // getMyComponentController
    
   public boolean renderVForce {get; set;}
    
   /* Toggle visualforce display to speed initial load */
   public void setRenderTrue() {
       renderVForce=true;
   }
   public void setRenderFalse() {
       renderVForce=true;
   }
   public void toggleVForce(){
       renderVForce=true;
   }
   
   /* Is this displaying in Salesforce1? */
   public Boolean isSF1 {get; set;}

   /** The payroll product. */
   public static final String PROD_PAYROLL='Payroll';
   /** The Ancillary product. */
   public static final String PROD_ANCILLARY='Ancillary';
 
   /** The running user. */
   public User usr;
   /** for the Contact Id if that is passed in. */
   public String contactId {get; set;}
   /** for the Lead Id if that is passed in. */ 
   public String leadId {get; set;}
   public String acctId=null; 
    /**for Cadence touchPointId*/
    public String touchPointId {get; set;}
    public String fieldCampaign {get; set;}
   /** The Account */     
   public Account acct{get; set;}
   /** The Contact */
   public Contact ctct{get; set;}
   // used only for the product of interest right now
   public Contact tempCtct{get;set;}
   /** The lead to Convert if applicable. */
   public Lead leadToConvert{get; set;}
   /** The Event. */
   public Event evnt{get; set;}
   // used to query on the form to get the type of opportunity 
   public Opportunity oppTemp{get;set;}
   /** The Opportunity. */
   public Opportunity opp {get; set;}

   /** Is this converting a lead?
    */
   public Boolean isLeadConvert{
      get{
         return leadId != null;
      }
   } // isLeadConvert
   
   /** Is this a Core record? */
   public Boolean isCore{get;private set;}
   
   /** Is this an MMS record? */
   public Boolean isMMS{get;private set;}
   
   /** Is this an HRS record? */
   public Boolean isHRS{get;private set;}
   
   /** Is this an HNB record? */
   public Boolean isHNB{get;private set;}
   
   /** Is this an PEO record? */
   public Boolean isPEO{get;private set;}
   
   /** Is this for an MSP product? */  
   public Boolean isMSP{get;private set;} // Updated For myStaffingPro 
   
   /** Is this a TAA record? */
   public Boolean isTAA{get;private set;}
    
   /* Added by Saketh*/
   /** Is this an PNC record? */
   public Boolean isPNC{get;private set;}
    public Boolean isPC{get;private set;}
   
   /** Is this an MerchantService record? */
   public Boolean isMS{get;private set;}
    public Boolean isMerchantService{get;private set;}
   
   /** Is this an ESR record? */
   public Boolean isESR{get;private set;}
   
   /** Is this an PBA record? */
   public Boolean isPBA{get;private set;}
   
   /* End Added by Saketh */
   
   // do we allow a meeting to be created?
   public Boolean allowCreateMeeting{get;private set;}
   /** Is an event going to be created? */
   public Boolean createMeeting{get;set;}
    
   // do we allow an opportunity to be created?
   public Boolean allowCreateOpp{get;private set;}
   // Is an opportunity going to be created? 
   public Boolean createOpportunity{get;set;}
   
   /** Is this for an ancillary product? */
   public Boolean isAncillary{get;set;}
    
   // Does the account have peo potential?
   public Boolean hasPeoPotential{
       get {
          return (acct != null && String.isNotBlank(acct.PEO_Potential_Indicator__c) && usr != null && usr.Sales_Org__c == UserHelper.SO_PEO_ASO);
       }
   } // hasPeoPotential

   private Id campaignId = null;
   // the latest campaign that was added as a campaign member to the lead/contact
   private Campaign latestCampaign = null;
   
   /** for the lead convert, the company list. */
   public List<SelectOption> companyList{get; set;}
   public String selectedCompany{get; set;} 

   public String salesOrg{get; set;}
   public String salesDivision{get; set;}

   public ProductHelper ph {get; set;}

   public List<ExistingOpptyWrapper> existingOpps{get;set;}
   
   public Boolean hasExistingOpps{
      get{
         return (existingOpps!=null && !existingOpps.isEmpty());
      }
   } // companySelected
   
   public ExistingOpptyWrapper selectedOppWrap{get;set;}
   
   public String eventSubject{get;set;}
   
   public String eventDescription{get;set;}
   
   public Boolean companySelected{
      get{
         return selectedCompany != null;
      }
   } // companySelected

   // if a parameter is passed in to not create a meeting, keep track of it here.
   private Boolean doNotCreateMeetingParameterSet = false;
      
   // Constructor
   public CreateOppAndMeeting() {
      // instantiate this record
      ph = new ProductHelper();
      // check if sales org is passed in
      salesOrg = ApexPages.currentPage().getParameters().get('salesOrg');
      isSF1 = Utilities.isSF1();
      allowCreateMeeting = true;
      allowCreateOpp = true;
      setRenderTrue();
      createOpportunity=TRUE;
      System.debug('check1 salesOrg='+salesOrg);
                      
      String ancCheck = (ApexPages.currentPage().getParameters().containsKey('Ancillary') ? ApexPages.currentPage().getParameters().get('Ancillary').escapeHtml4() : null);
      isAncillary = (String.isNotBlank(ancCheck) && ancCheck == 'Y');

      usr = UserHelper.getRunningUser();
      if (salesOrg == null) {
         salesOrg = usr.Sales_Org__c;
         salesDivision = usr.Sales_Division__c;
      }
       contactId = ApexPages.currentPage().getParameters().get('contactId');
       leadId = ApexPages.currentPage().getParameters().get('leadId');
       touchPointId = ApexPages.currentPage().getParameters().get('touchPointId');
       fieldCampaign = ApexPages.currentPage().getParameters().get('salesProgram');
       // check for event creation - default is on
      String meetingCheck = ApexPages.currentPage().getParameters().get('createMeeting');
      doNotCreateMeetingParameterSet = (meetingCheck != null && meetingCheck == 'N');
      System.debug('doNotCreateMeetingParameterSet :'+doNotCreateMeetingParameterSet + 'MeetingCheck:'+meetingCheck);
      //if (meetingCheck != null) {
      //   createMeeting = (meetingCheck != 'N');
      //}
      
      
      // setup pkg options
      // Use the product mapping to check for the pilot user pricebook
      ph.getPricebookBySalesOrg(ProductMapping.getSalesOrg(null,usr));
      setDefaults(salesOrg);  

      // determine which type of Id is passed in
      if (contactId != null) {
         initializeContact();
         if(acctId!=null){
            selectedCompany=String.valueOf(acctId);
            queryExistingOppty(acctId,salesOrg);
         }
      } else {
         // if no contactId found, check for lead
         if (leadId != null) {
            initializeLead();
         }
      }      
      //jc moving up setDefaults(salesOrg);       
      if (contactId == null && leadId == null) {
         // unrecognized Id - cannot proceed.
         logError(null,'No Id was passed in - unable to proceed!');
         return;
      }

      finishSetup();
      
   } // CreateOppAndMeeting

   public void selectOppType() {
      setRenderFalse();
      if (String.isBlank(oppTemp.OpportunityType__c)) {
         oppTemp.OpportunityType__c.addError('Must Select a Value to Proceed');
         return;
      }
      isAncillary = (oppTemp.OpportunityType__c == Label.OppType_Ancillary);
      finishSetup();
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'selectOppType oppType='+opp.OpportunityType__c));
   } // selectOppType

   public void finishSetup() {
      // this has to be done after we've selected the account information. This is not ideal yet, but to force it through...
      system.debug('JC hasPeoPotential ' +hasPeoPotential );
      system.debug('ECP hasPeoPotential code commented out');
      // if (hasPeoPotential) {
      //    // default the Opportunity Type to PEO
      //    oppTemp.OpportunityType__c = 'PEO';
      //    // I don't like this hardcoded! 
      //    Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity');
      //    Id rtId = rtInfo != null ? rtInfo.getRecordTypeId() : null; 
      //    opptyrtname= 'PEO Opportunity Record Type';
      //     system.debug( 'rtId '+ rtId  );
      //    if (rtId == null) {
      //       System.debug('finishSetup recordType not found for PEO Opportunity Record Type');
      //    } else {
      //       oppTemp.RecordTypeId = rtId;
      //    }
      // } // if (hasPeoPotential
       
       // check for event creation - default is on
      createMeeting = (!doNotCreateMeetingParameterSet && !(isCore && isAncillary));
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'finishSetup createMeeting='+createMeeting+' isAncillary='+isAncillary+' oppType='+oppTemp.OpportunityType__c));
      
      if (contactId != null && acct != null) {
         checkExistingOpps();
         if (opp == null) {
            setOppForContact();
         } else {
            updateOpp();
         }
      } else if (leadId != null && leadToconvert != null) {
         // set up the opportunity record
         if (opp == null) {
            setupLeadOpp();
         } else {
            updateOpp();
         }
         // create an event
         setupLeadEvent();
      }
      
   } // finishSetup

   public CreateOppAndMeeting(String p_salesOrg, String p_salesDivision) {
      usr = UserHelper.getRunningUser();
      salesOrg = p_salesOrg;
      salesDivision = p_salesDivision;
      isAncillary = false;
      setDefaults(salesOrg);
   } // CreateOppAndMeeting

   /** Used to get CloseDate calculation. */
   public CreateOppAndMeeting(String p_salesOrg) {
      usr = UserHelper.getRunningUser();
      salesOrg = p_salesOrg;
      isAncillary = false;
      setDefaults(salesOrg);
   } // CreateOppAndMeeting
   
   /** Add the meeting.
    */
   public PageReference addMeeting() {
      setRenderFalse();
      createMeeting = true;
      return null;
   } // addMeeting
   
   /** Remove the meeting.
    */
   public PageReference removeMeeting() {
      setRenderFalse();
      createMeeting = false;
      return null;
   } // removeMeeting
    
    
   /** Add the meeting.
    */
   public PageReference addOppty() {
      setRenderFalse();
      createOpportunity = true;
      createMeeting = true;
      allowCreateMeeting = true;
      storeSelectedOppty();
       // Sush APR0152220
         if(oppTemp.OpportunityType__c == Label.HR_Pro_Upgrade && hasPeoPotential  == true){
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Alert: This Account is identified as having PEO potential. You must submit a Referral to the PEO-Virtual Direct Rep.'));
      } // APR0152220
      return null;
   } // addOppty
   
   /** Remove the meeting.
    */
   public PageReference removeOppty() {
      setRenderFalse();
      createOpportunity = false;
      createMeeting = false;
      allowCreateMeeting = false;
      return null;
   } // removeOppty
   
   public void findExistingOpps(){
      setRenderFalse();
      system.debug('jsh findingOpps companySelected: '+companySelected+' selectedCompany: '+selectedCompany);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'findExistingOpps selectedCompany='+selectedCompany));


      if(companySelected && selectedCompany!=CREATE_NEW_ACCT){
         Id aId = Id.valueOf(selectedCompany);
         queryExistingOppty(aId,salesOrg);
         checkExistingOpps();
      }
   } // findExistingOpps
   
   private String phone = null;
      
   public void initializeLead() {
      initializeLead(true);
   }

   /** Set up the environment for the Lead.
       Any changes made to this leadToConvert query also need to be made in the FAReferralMethods class leadToConvert query *** CMF
    */
   public void initializeLead(Boolean performAllSetup) {
    Set<Id> leadIdSet = new Set<Id>();
    try {
         leadIdSet.add((Id)leadId);
    } catch (Exception e) {
         logError(null,'Bad leadId: '+leadId+' - can not proceed! If the problem continues, contact Support.');
         return;
    }
    Lead[] leads = ReferralQueries.selectLeads(leadIdSet, null);
    if (leads.isEmpty()) {
       logError(null,'No Lead record was found - can not proceed! Please try again. If the problem continues, contact Support.');
         return;
    } // if (leads.isEmpty
      initializeLead(leads[0], performAllSetup);
   } // initializeLead

   public static Integer CAMP_MEMBER_DAYS = 120;
      
   public void checkCampaigns(CampaignMember[] campMembers) {
      if (campMembers != null && !campMembers.isEmpty()) {
         // check the age of the first one to make sure it is in the required range
         // the first in the list should be the newest
         if (campMembers[0].CreatedDate > Date.today().addDays(-CAMP_MEMBER_DAYS)) {
            latestCampaign = campMembers[0].Campaign;
            // we shouldn't need this anymore, but just in case...
            campaignId = campMembers[0].CampaignId;
         }
      }
   }
      
   public void initializeLead(Lead p_leadToConvert, Boolean performAllSetup) {
      leadToConvert = p_leadToConvert;
      System.debug('**CMF ** here at initializeLead, id='+leadToConvert.Id);      
      checkCampaigns(leadToConvert.CampaignMembers);
      //if (leadToConvert.CampaignMembers != null && leadToConvert.CampaignMembers.size() > 0) {
      //   campaignId = leadToConvert.CampaignMembers.get(0).CampaignId;
      //   latestCampaign = leadToConvert.CampaignMembers[0].Campaign;
      //}
      
      phone = leadToConvert.Phone;
      // set up a temp account with the correct record type to get the picklist.
      String acctRTName = AccountHelper.getSalesAccountType(usr.Sales_Org__c,leadToconvert.NumberOfEmployees,RecordTypeHelper.CORE_ACCOUNT);    
      
      Id rtId = RecordTypeHelper.getRecordType(acctRTName,'Account').getRecordTypeId(); 

      // used for setting values on the opportunity
      acct = new Account(RecordTypeId = rtId );
      acct.Current_Prior_Method__c = leadToConvert.Current_Prior_Method__c;
      acct.Hold_Out__c = leadToConvert.Hold_Out__c;
      acct.Hold_Out_Expiration__c = leadToConvert.Hold_Out_Expiration__c;
      acct.Local_Competitors__c = leadToConvert.Local_Competitors__c;
      acct.SicDesc = leadToConvert.SIC_Description__c;
      acct.Language__c = leadToConvert.Language__c;
       
      RecordType__c rtAcct = RecordType__c.getInstance(acctRTName);
      tempCtct = new Contact(FirstName = leadToConvert.Firstname, LastName = leadToConvert.LastName);
      if (rtAcct != null && String.isNotBlank(rtAcct.ContactRecordTypeName__c)) {
         rtId = RecordTypeHelper.getRecordType(rtAcct.ContactRecordTypeName__c,'Contact').getRecordTypeId(); 
         tempCtct.RecordTypeId=rtId;
      }

      
      // do we need to perform all of the setup options?
      if (performAllSetup) {
         // set up the opportunity record
         //setupLeadOpp();
         // create an event
         //setupLeadEvent();
         setupCompanyList(leadToconvert.Company,leadToConvert.PostalCode,(leadToConvert.Lead_Company__r != null ? leadToConvert.Lead_Company__r.AccountId__c : null));
      } // if
   } // initializeLead
   
   // Setup the opportunity based on the lead information.
   public void setupLeadOpp() {
      // set up the opportunity record
System.debug('**CMF ** here at setupLeadOpp');      
      opp = createOpp(leadToConvert.Company
                     ,leadToConvert.Frequency__c,leadToConvert.NumberOfEmployees,'',''
                     ,leadToConvert.Local_Competitors__c,leadToConvert.Bank_Lead_ID__c
                     ,leadToConvert.Additional_Referring_Name__c
                     ,leadToConvert.Referral_Contact__r,leadToConvert.Client_Referral__r, leadToConvert.Referral_National_Account__r
                     ,leadToConvert.SurePayroll_Id__c, leadToConvert.Referring_Employee__c, LeadToConvert.Language__c);

      // if a value is passed in on the lead, use that value
      if (leadToconvert.Mthd_Lead_Rcvd__c != null) {
         opp.Mthd_Lead_Rcvd__c=leadToconvert.Mthd_Lead_Rcvd__c;
      }
      //04/17/2023 ECP Remove need for Primary Competition 
      //opp.Primary_Competition__c = leadToconvert.Primary_Competition__c;
      opp.Other_Competition__c = '';
      opp.Campaign__c = leadToConvert.LatestCampaign__c;
      //auto populate opp fields for APR0116379
      opp.Payroll_Current_Prior_Method__c = leadToconvert.Current_Prior_Method__c;
       
      if(isHRS && salesOrg != UserHelper.SO_PBS && salesOrg != UserHelper.SO_PEO_ASO){
         opp.Payroll_Platform__c = 'HRS';
      } else if(isHNB){
         opp.Payroll_Platform__c = 'HNBF';
      }

   } // setupLeadOpp
   
   // Setup the event based on the lead information.
   public void setupLeadEvent() {
      evnt = createEvent(leadToConvert.Company, opp.Name
                        ,leadToConvert.Name
                        ,leadToConvert.Phone,leadToConvert.MobilePhone
                        ,leadToConvert.Street, leadToConvert.City, leadToConvert.State, leadToConvert.PostalCode
                        ,leadToConvert.Email, CLASSNAME, null);
   } // setupLeadEvent
   
   // Set up the environment for the Contact.
   public void initializeContact() {
      try {
         ctct=[select Id,Name,FirstName,LastName,Phone,MobilePhone,AccountId,RecordTypeId
                     ,LeadSource,HRS_Call_Type__c
                     ,Email
                     ,LatestCampaign__c
                     ,MailingStreet, MailingState, MailingPostalCode, MailingCountry, MailingCity, Home_Zip__c, Home_Street_Address__c 
                     ,Products__c
                     ,Referral_Contact__c
                     ,Referral_Contact__r.Id
                     ,Referral_Contact__r.Name
                     ,Referral_Contact__r.Referral_Account__r.Name
                     ,Referral_Contact__r.Referral_Account__r.Referral_Source_Business_Type__c
                     ,Referral_Contact__r.Referral_Account__r.Zip_Postal_Code__c
                     ,Referral_Contact__r.Referral_Account__r.Street_Address_1__c
                     ,Referral_Contact__r.Referral_Account__r.City__c
                     ,Referral_Contact__r.Referral_Account__r.State_Province__c
                     ,Referral_Account__c
                     ,Referral_Account__r.Id
                     ,Referral_Account__r.Name
                     ,(Select Id, CampaignId, CreatedDate
                             ,Campaign.Id
                             ,Campaign.LeadSource__c
                             ,Campaign.StartDate
                         from CampaignMembers
                        where Campaign.IsActive=true
                        order by CreatedDate desc
                        limit 5)
                 from Contact where id =:contactId];
      } catch (QueryException qe) {
         logError(null,'No Contact record was found - can not proceed! Please try again. If the problem continues, contact SFDC Support.');
         return;
      }
      tempCtct = new Contact(RecordTypeId=ctct.RecordTypeId, FirstName=ctct.FirstName, LastName=ctct.LastName);
      checkCampaigns(ctct.CampaignMembers);
      
      acctId = ctct.AccountId;
      phone = ctct.Phone;
      
      acct = ReferralQueries.selectAcct(ctct.AccountId);
            
      //setAddressFields(acct,ctct);
    
   } // initializeContact
   
   public void setOppForContact() {
      String leadSource = '';
      String primComp = '';
      /*String leadSource;
      Boolean isVSR = (usr.NSS_Team__c == Label.NSS_Team_VS_PAY);
      PartnerReferral__c[] partRefs =[SELECT Id,Campaign__c,Campaign__r.LeadSource__c FROM PartnerReferral__c WHERE Contact__c = :contactId AND Destination__c ='Virtual Sales' AND Source__c !=null order by CreatedDate desc];        
     
      if(!partRefs.isEmpty() && isVSR && partRefs[0].Campaign__c!=null){
      system.debug('jsh test isVSR:'+isVSR+' leadSource: '+leadSource+' campaignLeadSource: '+partRefs[0].Campaign__r.LeadSource__c);
        PartnerReferral__c partRef = partRefs[0];
        if(partRef.Campaign__c != null){
            leadSource = (partRef.Campaign__r.LeadSource__c!=null?partRef.Campaign__r.LeadSource__c:'');
        }
      }
      else{
        leadSource = '';
      }*/
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setOppForContact'));
      
      String localCom = (isMMS ? acct.Local_Payroll_Vendor__c : (isCore ? acct.Local_Competitors__c : null));
      opp = createOpp(acct.Name
                     ,acct.Frequency__c,acct.NumberOfEmployees,leadSource, null/* old PrimComp field */
                     ,localCom /* local competitor */,null /* Bank Lead Id */
                     ,null /* Additional Referring Name */
                     ,ctct.Referral_Contact__r,null /* account - client referral */, ctct.Referral_Account__r
                     ,null /* Surepayroll id*/, null /*Referring_Employee__c */, acct.Language__c);
      opp.accountid = acct.Id;
      opp.Campaign__c = ctct.LatestCampaign__c;
      //auto populate opp fields for APR0116379
      opp.Payroll_Current_Prior_Method__c = acct.Current_Prior_Method__c;

      if(isHRS && salesOrg != UserHelper.SO_PBS && salesOrg != UserHelper.SO_PEO_ASO){
         opp.Payroll_Platform__c = 'HRS';
      } else if(isHNB){
         opp.Payroll_Platform__c = 'HNBF';
      }
      
      // for MMS, default lead source to 68 Current Core Client if MMS rep and account type = Core and not lost
      if (isMMS && acct.RecordType.Name == RecordTypeHelper.CORE_ACCOUNT
                && acct.Bis_ID__c != null 
                && acct.Lost_Date__c == null 
                && acct.First_Run_Date__c != null) {
         opp.LeadSource = 'Transfer - Core to MMS';
         opp.Core_Branch_Client_Number__c = acct.AccountNumber;
      }
      evnt = createEvent(acct,ctct,null, CLASSNAME, null);

   } // setOppForContact
   
   public PageReference logError(Exception e, String errorMsg) {
      return logError(e,errorMsg,false);
   }

   /** Log an error message.
    */
   public PageReference logError(Exception e, String errorMsg, Boolean saveError) {
      if (!NON_VISUAL_CONTEXT && sp1 != null) {
         Database.rollback(sp1);
         sp1 = null;
      }
      if (e != null) {
         if (saveError) {
            ErrorLog.logError('CreateOppAndMeeting', 'logError', 'General Error', contactId, e, ctct, true);
         }
         if (!NON_VISUAL_CONTEXT) {
            ApexPages.addMessages(e);
         }
      }
      if (errorMsg != null) {
         if (saveError) {
            ErrorLog.logError('CreateOppAndMeeting', 'logError', 'General Error', contactId, errorMsg, ctct, true);
         }
         if (!NON_VISUAL_CONTEXT) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg));
         }
      }
      // reset this variable just in case an exception occurs while attempting to save and the 
      // user changes their mind with the end point.
      gotoMeeting = false;
      return null;
   } // logError
   
   /** Search for accounts that match the name of the lead.
    */
    public void setupCompanyList(String p_accName, String zipCode, Id acctId){
      companyList = new List<SelectOption>();
      List<Account> acctList = new List<Account>();
      if (acctId != null) {
         acctList.addAll([SELECT Id, Name, Owner_Zip_Code__c, ShippingPostalCode, BillingPostalCode from Account where Id=:acctId]);
         if (!acctList.isEmpty()) {
            selectedCompany = acctId;
         }
      }
      System.debug('setupCompanyList acctList='+acctList.size());
      // get the account record type ids we will use for lead convert
      String queryZip = (String.isNotBlank(zipCode) ? zipCode.left(5) : '');
      String accName = (String.isNotBlank(p_accName) && p_accName.length()>5 ? '%' + p_accName + '%' : '');
      if (String.isNotBlank(queryZip) && String.isNotBlank(accName)) {
         ZipBatch zipB = new ZipBatch();
         zipB.setupRecordTypeIds();
         Id[] recordTypeIds = new Id[]{};
         recordTypeIds.addAll(ZipBatch.recordTypeIdMap.values());
         Account[] accts = [SELECT Id, Name, Owner_Zip_Code__c from Account where Name like :accName and Owner_Zip_Code__c=:zipCode and RecordTypeId in :recordTypeIds limit 100];
         acctList.addAll(accts);
      }
      System.debug('setupCompanyList accName='+accName+' queryZip='+queryZip+' acctList='+acctList.size());

      companyList.add(new SelectOption('','--None--'));
      companyList.add(new SelectOption(CREATE_NEW_ACCT,'Create New Account '+p_accName)); 
 
      for (Account acc : acctList) {
         String compName=acc.Name;
         if (acc.Owner_Zip_Code__c != null) {
            compName+=', zip='+acc.Owner_Zip_Code__c;
         }
         companyList.add(new SelectOption(acc.Id, compName)); 
      } // for 
    
   } // setupCompanyList

   public static Integer OPP_NAME_SIZE=Opportunity.Name.getDescribe().getLength();

   public static String getOppName(String p_acctName, String p_prodName, Integer nameFieldSize) {
      return getOppName(p_acctName, p_prodName, nameFieldSize, false);
   } // getOppName

   public static String getOppName(String p_acctName, String p_prodName, Integer nameFieldSize, Boolean p_isAncillary) {
      String acctName = p_acctName;
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getOppName acctName='+p_acctName+' prodName='+p_prodName+' nameFieldSize='+nameFieldSize+' datasize='+(p_acctName.length() + 1 + p_prodName.length())));
      p_prodName=((p_isAncillary != null && p_isAncillary) ? 'Ancillary' : p_prodName);

      if (String.isNotBlank(acctName) && String.isNotBlank(p_prodName) 
           && (acctName.length() + 1 + p_prodName.length() > nameFieldSize)) {
         Integer charsRemaining = nameFieldSize - 1 - p_prodName.length();
         acctName = acctName.left(charsRemaining);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getOppName charsRemaining='+charsRemaining+' acctName='+acctName));
      }
      String oppName = acctName + '-' + p_prodName;
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getOppName oppName='+oppName));
      return oppName;
   } // getOppName
   
   public void updateOpp() {
      if (opp != null) {
         String acctName = (leadToConvert != null ? leadToConvert.Company : (acct != null ? acct.Name :  'NoName'));
         opp.Name = getOppName(acctName,prodName,OPP_NAME_SIZE, isAncillary);
         opp.OpportunityType__c = oppTemp.OpportunityType__c;
         setUnit(opp,isAncillary);
      }
   } // updateOpp
   
   public Opportunity createOpp(String acctName, String p_prodName) {
System.debug('**CMF ** here at createOpp1');    
      Id rtId = RecordTypeHelper.getRecordType(opptyRtName,'Opportunity').getRecordTypeId(); 
      
      Opportunity v_opp = new Opportunity(RecordTypeId = rtId, Amount=0);
      //opp.Name = accName+' - '+prodName;
      v_opp.Name = getOppName(acctName,p_prodName,OPP_NAME_SIZE, isAncillary);
      v_opp.CloseDate = getCloseDate();
      v_opp.StageName=oppFirstStage;
  //LM3/6    v_opp.ForecastCategoryName = oppForecast;
  //LM3/6    v_opp.Probability = oppProbability;
      v_opp.Created_in_Salesforce1__c=(isSF1 != null ? isSF1 : false);
      if (String.isNotBlank(payrollPlatform)) {
         v_opp.Payroll_Platform__c=payrollPlatform;
      }
      if(oppTemp== null || oppTemp.OpportunityType__c == null ){    
         OpptyMethods.checkOpportunityType(v_opp, null, usr, acct);
      }//if
      else{
         v_opp.OpportunityType__c=oppTemp.OpportunityType__c;
         }      //v_opp.OpportunityType__c = oppTemp.OpportunityType__c;
         return v_opp;
   } // createOpp
   
   public Opportunity createOpp(String accName
                                      ,String freq, Decimal nbrEmps, String leadSource, String primComp
                                      ,String localComp, String BankLeadID, String AddRefName
                                      ,Referral_Contact__c cpa, Account cltRef, Referral_Account__c refAcct
                                      ,String surePayrollId, Id referringEmployeeCtctId, String language) {
System.debug('**CMF ** here at createOpp2');    
      opp = createOpp(accName,prodName);
      
      opp.OppSource__c='CreateOppAndMeeting';

      opp.Frequency__c = convertFrequency(freq);
      opp.OwnerId= (usr != null ? usr.Id : null);
      
      opp.Bank_Lead_ID__c = BankLeadID;
      opp.Additional_Referring_Name__c = AddRefName;
      opp.Employees_Paid_Per_Payroll__c=nbrEmps;
      opp.TotalOpportunityQuantity = 0;

      //opp.Auto_Create_Follow_up__c = (isMMS && !isAncillary);
      opp.Auto_Create_Follow_up__c = false;
      opp.Spanish_Speaking_Needs__c = (language != null && language == 'Spanish'? TRUE : FALSE);
      setUnitAndReferrals(opp, isAncillary, cpa, cltRef, refAcct);
      
      opp.Mthd_Lead_Rcvd__c='Sales Rep Effort';
      opp.LeadSource = '';
      opp.Local_Competitors__c = localComp;
      opp.SurePayroll_ID__c = surePayrollId;
      opp.Referring_Employee__c = referringEmployeeCtctId;
      opp.Created_in_Salesforce1__c=(isSF1 != null ? isSF1 : false);
      return opp;
   } // createOpp
   
   public void setUnit(Opportunity opp, Boolean p_isAncillary) {
      opp.Payroll_Unit__c = opp.OpportunityType__c != 'HR Partner Plus Standalone' && (!p_isAncillary && (isCore || isMMS));
      opp.TotalOpportunityQuantity = (!p_isAncillary && isCore ? 1 : null);
      //Removing References to Primary Competition
      //opp.Primary_Competition__c = (p_isAncillary ? 'No Competition/Ancillary' : null);
      // Competitor__c comp =  new Competitor__c();
      // PickListValue__c noComp = [Select Id, Name from PickListValue__c where Name ='no competitor' Limit 1];
      // comp.PickListValue__c = noComp.Id;
      // comp.Opportunity__c = opp.Id;
      //insert comp;
   } // setUnit
   
   public void setUnitAndReferrals(Opportunity opp, Boolean p_isAncillary, Referral_Contact__c cpa, Account cltRef, Referral_Account__c refAcct) {
      setUnit(opp,p_isAncillary);
      /*
      if (!p_isAncillary) {
         if (isCore) {
            opp.TotalOpportunityQuantity=1;
            opp.Payroll_Unit__c = true;
         } else if (isMMS) {
            opp.Payroll_Unit__c = true;
         }
      } else {
         opp.Primary_Competition__c = 'No Competition/Ancillary';
      } // if (!isAncillary)
      */
      if (cpa != null) {
         opp.Referral_Contact__c = cpa.Id;
         opp.Referral_Contact__r = cpa;
      }
      if (cltRef != null) {
         opp.Client_Referral__c = cltRef.Id;
         opp.Client_Referral__r = cltRef;
      } 
      if (refAcct != null) {
         opp.Referral_Account__c = refAcct.Id;
         opp.Referral_Account__r = refAcct;
      }
   } // setUnitAndReferrals
   
   /** Get the close date based on the sales org
    */
   public Date getCloseDate() {
    Date closeDate = null;
      if (salesOrg == null) {
        salesOrg = usr.Sales_Org__c;
      }
      System.debug('salesOrg in getCloseDate : ' + salesOrg);
      
      Integer defaultRunEffectiveDate;
      
      if(SalesOrg__c.getInstance(salesOrg) != null && SalesOrg__c.getInstance(salesOrg).Default_Run_Effective_Date__c != null) {
         System.debug('SalesOrg__c.getInstance(salesOrg).Default_Run_Effective_Date__c : ' + SalesOrg__c.getInstance(salesOrg).Default_Run_Effective_Date__c);
         defaultRunEffectiveDate = Integer.valueOf(SalesOrg__c.getInstance(salesOrg).Default_Run_Effective_Date__c);
      } else {
          defaultRunEffectiveDate = 30;
      }
      closedate = Utilities.getNextBusinessDay(defaultRunEffectiveDate);
      
      return closeDate;
   } // getCloseDate
   
   // The name of the Record Type for the Opportunity Object.
   public String opptyRtName{get;private set;}
   // The name of the Record Type for the Event object.
   public String eventRtName{get;private set;}
   // The name of the Record Type for the Task object. 
   public String taskRtName{get;private set;}
   // The name of the product for the Opportunity name.
   public String prodName{get;private set;}
   public String oppFirstStage{get;private set;}
   public Decimal oppProbability{get;private set;}
   public String oppForecast{get;private set;}
   public String refOppFirstStage{get;private set;}
   public Decimal refOppProbability{get;private set;}
   public String refOppForecast{get;private set;}
   public String oppTypeDefault{get; private set;}
   public String payrollPlatform=null;
   
   private Map<Id,Pricebook2> pricebookByIdMap = new Map<Id,Pricebook2>();
   
   public Boolean hasPricebookOptions{
      get {return (pricebookOptions != null && pricebookOptions.size() > 1); }
   } // hasPricebookOptions
   
   public List<SelectOption> pricebookOptions{get;set;}
   
   public String selectedPricebookId{get;set;}
   
   public void setupPricebooks() {
      Pricebook2 pricebook = ProductQuery.getPrimaryPricebook(usr,salesOrg,salesDivision);
      selectedPricebookId = (pricebook != null ? pricebook.Id : null);
      System.debug('setupPricebooks selectedPricebookId: '+selectedPricebookId); 
   } // setupPricebooks
   
   /** Set the Opportunity Record Type Name.
    * @param salesOrg - the sales org User
    */
   public void setDefaults(String salesOrg) {
      // these will be the default values
      opptyRtName = OpportunityCreateCase.RT_OPPTY_CORE;
      eventRtName = RecordTypeHelper.CORE_EVENT;
      taskRtName = RecordTypeHelper.CORE_TASK;
      isCore = true;
      isHRS = false;
      isHNB = false;
      isMMS = false;
      isMSP = false;
      isPEO = false;
      isTAA = false;
       
       /*Added by Saketh*/
      isPC = false;
      isMS = false;
      isESR = false;
      isPBA = false;
       /*Added by Saketh*/
       
       System.debug('salesOrg in setDefaults:---------->>>>>> :  ' + salesOrg);
       
      oppFirstStage = Label.OpptyPendingDefault;
      refOppFirstStage = Label.OpptyPendingDefault;
      oppTypeDefault = 'Payroll';
      prodName=((isAncillary != null && isAncillary) ? 'Ancillary' : 'Payroll');
      
      SalesOrg__c salesOrgSetting;
       
      if (String.isNotBlank(salesOrg)) {
         salesOrg = (salesOrg == 'Merchant Services' ? 'MS' : (salesOrg == 'Time & Attendance' ? 'TAA' : salesOrg));
         salesOrgSetting = SalesOrg__c.getInstance(salesOrg);
         System.debug('salesOrgSetting  for '+salesOrg+': ' + salesOrgSetting);
         if (salesOrgSetting != null && String.isNotBlank(salesOrgSetting.OpptyRecordTypeName__c)) {
            setupPricebooks();
            if (salesOrg == 'BusDev' && String.isNotBlank(salesDivision)) {
               // We will need user information passed in from the referral form to handle this.
               SalesOrg__c salesOrg2 = SalesOrg__c.getInstance(salesDivision);
               // if one is retrieved, use that. Otherwise use the bus dev one.
               salesOrg2 = (salesOrg2 != null ? salesOrg2 : salesOrgSetting);
               opptyRtName = (String.isNotBlank(salesOrg2.OpptyRecordTypeName__c) ? salesOrg2.OpptyRecordTypeName__c : opptyRtName);
               eventRtName = (String.isNotBlank(salesOrg2.EventRecordTypeName__c) ? salesOrg2.EventRecordTypeName__c : eventRtName);
               taskRtName = (String.isNotBlank(salesOrg2.TaskRecordTypeName__c) ? salesOrg2.TaskRecordTypeName__c : taskRtName);

            }
            else {
               opptyRtName = (String.isNotBlank(salesOrgSetting.OpptyRecordTypeName__c) ? salesOrgSetting.OpptyRecordTypeName__c : opptyRtName);
               eventRtName = (String.isNotBlank(salesOrgSetting.EventRecordTypeName__c) ? salesOrgSetting.EventRecordTypeName__c : eventRtName);
               taskRtName = (String.isNotBlank(salesOrgSetting.TaskRecordTypeName__c) ? salesOrgSetting.TaskRecordTypeName__c : taskRtName);
            }
            oppFirstStage = (String.isNotBlank(salesOrgSetting.OppFirstStage__c) ? salesOrgSetting.OppFirstStage__c : oppFirstStage);
            refOppFirstStage = (String.isNotBlank(salesOrgSetting.ReferralOppFirstStage__c) ? salesOrgSetting.ReferralOppFirstStage__c : refOppFirstStage);
            prodName = (String.isNotBlank(salesOrgSetting.ProductName__c) ? salesOrgSetting.ProductName__c : prodName);
            payrollPlatform = salesOrgSetting.PayrollPlatform__c;
            UserHelper uh = new UserHelper();
             
            isMMS = uh.isMMS(salesOrg);
            isHNB = (!isMMS ? uh.isHNB(salesOrg) : isHNB);
            isHRS = ((!isMMS && !isHNB) ? uh.isHRS(salesOrg) : isHRS);
            isPEO = ((!isMMS && !isHNB && !isHRS) ? uh.isPEO(salesOrg) : isPEO);
            isMSP = ((!isMMS && !isHNB && !isHRS && !isPEO) ? uh.isMSP(salesOrg) : isMSP);
            isTAA = ((!isMMS && !isHNB && !isHRS && !isPEO && !isMSP) ? uh.isTAA(salesOrg) : isTAA);
             /*Added by Saketh*/
            isPC = ((!isMMS && !isHNB && !isHRS && !isPEO && !isMSP && !isTAA) ? uh.isPC(salesOrg) : isPC);
            isMS = ((!isMMS && !isHNB && !isHRS && !isPEO && !isMSP && !isTAA && !isPC) ? uh.isMS(salesOrg) : isMS);
            isESR = ((!isMMS && !isHNB && !isHRS && !isPEO && !isMSP && !isTAA && !isPC && !isMS) ? uh.isESR(salesOrg) : isESR);
            isPBA = ((!isMMS && !isHNB && !isHRS && !isPEO && !isMSP && !isTAA && !isPC && !isMS && !isESR) ? uh.isPBA(salesOrg) : isPBA);
             /*Added by Saketh*/
            // default to core if not one of the other sales orgs
            isCore = (!isMMS && !isHNB && !isHRS && !isPEO && !isMSP && !isTAA && !isPC && !isMS && !isESR && !isPBA);
             
             System.debug('+isMMS :+ ' + isMMS + ' +isHNB :+ ' + isHNB + ' +isHRS :+ ' + isHRS + ' +isPEO :+ ' + isPEO + ' +isMSP :+ ' + isMSP + ' +isTAA :+ ' + isTAA + ' +isPC :+ ' + isPC + ' +isMS :+ ' + isMS + ' +isESR :+ ' + isESR + ' +isPBA :+ ' + isPBA);
         }
      } // if (String.isNotBlank(salesOrg
      Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType(opptyRtName,'Opportunity');
      Id rtId = rtInfo != null ? rtInfo.getRecordTypeId() : null; 
      if (rtId == null) {
         System.debug('setDefaults recordType not found for '+opptyRtName);
      }
      oppTemp = new Opportunity(RecordTypeId=rtId);     
      // shouldn't need this because we should be able to use the default from whatever record type we're setting.
      // the default Opportunity Type from SalesOrg__c takes precedence over the default Opportunity Type set by the RecordType__c custom setting  
      String oppTypeDefault = (Test.isRunningTest() ? 'Payroll' : ((salesOrgSetting!=null && String.isNotBlank(salesOrgSetting.Opportunity_Type__c)) ? salesOrgSetting.Opportunity_Type__c : null));
      OpptyMethods.checkOpportunityType(oppTemp, oppTypeDefault, null, acct);   
      System.debug('setDefaults salesOrg='+salesOrg+' isCore='+isCore+' isMMS='+isMMS+' isHRS='+isHRS+' isHNB='+isHNB+' isAncillary='+isAncillary+' isMSP='+isMSP+' isPEO='+isPEO+' createMeeting='+createMeeting+' rtId='+rtId);
       // Sush APR0152220
          if(oppTemp.OpportunityType__c == Label.HR_Pro_Upgrade  && hasPeoPotential == true ){
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Alert: This Account is identified as having PEO potential. You must submit a Referral to the PEO-Virtual Direct Rep.'));
      } // APR0152220
   } // setDefaults

   /** Convert the frequency to the correct format for the opportunity.
    */    
   public String convertFrequency(String pFrequency) {
      String retFreq = '0';
      if (pFrequency=='1 Weekly'){
         retFreq = '52';
      } else if (pFrequency=='2 Bi-weekly'){
         retFreq = '26';
      } else if (pFrequency=='3 Semi-monthly'){
          retFreq = '24';
      } else if (pFrequency=='4 Monthly'){
         retFreq = '12';
      } else if (pFrequency=='5 Quarterly'){
         retFreq = '4';
      } else if (pFrequency=='6 Semi-annually'){
         retFreq = '2';
      } else if (pFrequency=='7 Annually'){
         retFreq = '1';
      }
      return retFreq;
   } // convertFrequency

   private String v_street = null;
   private String v_city = null;
   private String v_state = null;
   private String v_postalCode = null;

   /** setup the address fields based on the account and contact
    */
   public void setupAddress(Account acct, Contact ctct) {
      // default address to the shipping address
      v_street = acct.ShippingStreet;
      v_city = acct.ShippingCity;
      v_state = acct.ShippingState;
      v_postalCode = acct.ShippingPostalCode;
      // if no shipping address try the billing address next. If no billing address, try the contact address.
      if (String.IsBlank(v_street) && String.IsNotBlank(acct.BillingStreet)) {
         v_street = acct.BillingStreet;
         v_city = acct.BillingCity;
         v_state = acct.BillingState;
         v_postalCode = acct.BillingPostalCode;
      } else if (String.IsBlank(v_street) && ctct != null && String.IsNotBlank(ctct.MailingStreet)) {
         v_street = ctct.MailingStreet;
         v_city = ctct.MailingCity;
         v_state = ctct.MailingState;
         v_postalCode = ctct.MailingPostalCode;
      }
   } // setupAddress

   /** create the event based on the account and contact
    */
    public Event createEvent(Account acct, Contact ctct, String source, String callType) {
      setupAddress(acct,ctct);

      return(createEvent(acct.Name, acct.Name+' - '+prodName, getCtctName(ctct)
                        ,(ctct != null ? ctct.Phone : null) ,(ctct != null ? ctct.MobilePhone : null)
                        ,v_street, v_city, v_state, v_postalCode
                        ,(ctct != null ? ctct.Email : null), source, callType));

   } // createEvent
   
   public Event createEvent(Account acct, Contact ctct, Referral_Contact__c refctct, String source, String callType) {
      Event e = new Event();
      if(acct!= null && ctct!=null){
         setupAddress(acct,ctct);

          e= createEvent(acct.Name, acct.Name+' - '+prodName, getCtctName(ctct)
                           ,(ctct != null ? ctct.Phone : null) ,(ctct != null ? ctct.MobilePhone : null)
                           ,v_street, v_city, v_state, v_postalCode
                           ,(ctct != null ? ctct.Email : null), source, callType);
      }

      if(refctct!=null){
       //Referral_Account__c jimmy = refctct.Referral_Account__c;
         v_street = refctct.Referral_Account__r.Street_Address_1__c;
         v_city = refctct.Referral_Account__r.City__c;
         v_state = refctct.Referral_Account__r.State_Province__c;
         v_postalCode = refctct.Referral_Account__r.Zip_Postal_Code__c;
         
          e = createEvent(refctct.Referral_Account__r.Name, refctct.Referral_Account__r.Name+' - '+prodName, refctct.Name
                           ,(refctct != null ? refctct.Phone__c : null) ,(refctct != null ? refctct.Mobile_Phone__c : null)
                           ,v_street, v_city, v_state, v_postalCode
                           ,(refctct != null ? refctct.Email__c : null), source, callType);//what happens to source and calltype 
      }
     return e;

   } // createEvent
   
     
   public void updateEventInfo(String acctName, String oppName
                           ,String ctctName, String phone, String mobilePhone
                           ,String street , String city, String state, String postalCode
                           ,String email
                          ) {
      if (evnt != null) {
         evnt.Subject = getSubject(oppName, phone);
         evnt.Description = compileDescription(acctName, oppName
                               ,ctctName,phone,mobilePhone
                               ,street, city, state, postalCode,email);
      }
   } // updateEventInfo

   // Create an event.
   public Event createEvent(String acctName, String oppName
                           ,String ctctName,String phone,String mobilePhone
                           ,String street , String city, String state, String postalCode
                           ,String email, String source, String callType) {
                                            
      Event evnt = new Event();
      Id rtId = RecordTypeHelper.getRecordType(eventRtName,'Event').getRecordTypeId(); 
      
      evnt.RecordTypeId = rtId;
      
      if (isMMS && isAncillary) {
         evnt.Type='Presentation - Current Client';
      } else if(isAncillary != null && isAncillary) {
         evnt.Type='Meeting';
      } else {
         SalesOrg__c socs = SalesOrg__c.getValues(salesOrg);
         evnt.Type = (socs != null && String.isNotBlank(socs.IEUP_Type__c) ? socs.IEUP_Type__c : 'Presentation - Initial');

      }
      
      String tempLocation = compileAddress('',street,city,state,postalCode);
      Integer locationLength =  Event.Location.getDescribe().getLength();
      // make sure the location does not exceed the length of the field
      evnt.Location = tempLocation.left(locationLength);

      evnt.Subject = getSubject(oppName, phone);
            
      evnt.Description = compileDescription(acctName, oppName
                           ,ctctName,phone,mobilePhone
                           ,street, city, state, postalCode,email);

      // default date values
      evnt.DurationInMinutes = 60;
      evnt.ActivityDate=Date.today();
      // set the time to the next full hour
      DateTime now = DateTime.now();
      evnt.ActivityDateTime=now; //DateTime.newInstance(now.year(),now.month(),now.day(),now.hour(),0,0);
      evnt.Activity_Source__c=source;
      evnt.Lead_Source_WAR_Call_Type__c=callType;
      return evnt;
   } // createEvent
   
   public String getSubject(String oppName, String phone) {
      return oppName+(String.isNotBlank(phone) ? ' - '+phone : '');
   } // setSubject
   
   public String getCtctName(Contact ctct) {
      String ctctName = '';
      if (ctct != null) {
         if (ctct.Id != null) {
            // if the record hasn't been saved we can't reference the name field
            ctctName = ctct.Name;
         } else {
            ctctName += (String.isNotBlank(ctct.FirstName) ? ctct.FirstName+' ': '');
            ctctName += (String.isNotBlank(ctct.LastName) ? ctct.LastName+' ': '');
         }
      }
      return ctctName;
   } // getCtctName
   
   /** create the task based on the account and contact
    */
   public Task createTask(Account acct, Contact ctct, String source, String callType) {
      setupAddress(acct,ctct);

      return(createTask(acct.Name, acct.Name+' - '+prodName, getCtctName(ctct)
                        ,(ctct != null ? ctct.Phone : null) ,(ctct != null ? ctct.MobilePhone : null)
                        ,v_street, v_city, v_state, v_postalCode
                        ,(ctct != null ? ctct.Email : null), source, callType));

   } // createTask
   

   /** Create a task.
    */
   public Task createTask(String acctName, String oppName
                           ,String ctctName,String phone,String mobilePhone
                           ,String street , String city, String state, String postalCode
                           ,String email, String source, String callType) {
                                            
      Task tsk = new Task();
      Id rtId = RecordTypeHelper.getRecordType(taskRtName,'Task').getRecordTypeId(); 
      
      tsk.RecordTypeId = rtId;
      tsk.Type = 'To Do';
      
      //tsk.Subject = 'To Do-NSS Tip-'+acctName+(String.isNotBlank(phone) ? ' - '+phone : '');
      tsk.Subject = getSubject(oppName, phone);// oppName+(String.isNotBlank(phone) ? ' - '+phone : '');
      tsk.Status = 'Not Started';
            
      tsk.Description = compileDescription(acctName, oppName
                           ,ctctName,phone,mobilePhone
                           ,street, city, state, postalCode,email);

      // default date to the next business day
      tsk.ActivityDate=Utilities.getNextBusinessDay(1);
      tsk.Activity_Source__c=source;
      tsk.Lead_Source_WAR_Call_Type__c=callType;
      
      return tsk;
   } // createTask
   
   private String compileDescription(String acctName, String oppName
                           ,String ctctName,String phone,String mobilePhone
                           ,String street , String city, String state, String postalCode
                           ,String email) {
      String description = acctName;
      description += (String.isNotBlank(ctctName) ? '\nContact: '+ctctName : '');
      description += (String.isNotBlank(phone) ? '\nPhone: '+phone : '');
      description += (String.isNotBlank(mobilePhone) ? '\nMobile: '+mobilePhone : '');

      description += compileAddress('\n',street,city,state,postalCode);

      description += (String.isNotBlank(email) ? '\nEmail: '+email : '');
      return description;
   } // compileDescription
   
   private String compileAddress(String lineDivider, String street
                                ,String city, String state, String postalCode) {
                                    
      String address = (String.isNotBlank(street) ? lineDivider+street+' ' : '');
      // see if at least one component is present.
      // check to format nicer.
      if (String.isNotBlank(city) || String.isNotBlank(state) || String.isNotBlank(postalCode)) {
         address += lineDivider;
         address += (String.isNotBlank(city) ? city : '');
         address += (String.isNotBlank(state) ? (String.isNotBlank(city) ? ', ' : '')+state : '');
         address += (String.isNotBlank(postalCode) ? ' '+postalCode : '');
      }
      return address;
   } // compileAddress
   
   // Update and save an Event object
   public Boolean saveEvent(Event evnt, String leadSource
                                 ,String oppName, String phone
                                 ,Id whoId, Id whatId) {

      // get the event from the component controller if it exists
      if (myComponentController != null) {
         evnt = myComponentController.evnt;
      }

      evnt.Subject = oppName+((phone != null && phone.length() > 0) ? ' - '+phone : '');
      evnt.Lead_Source_WAR_Call_Type__c=leadSource;
      evnt.WhoId = whoId;
      evnt.WhatId = whatId;
      if(Test.isRunningTest()){
        evnt.DurationInMinutes = 60;
        evnt.ActivityDateTime = system.now();
      }
      insert evnt;
      return true;
   } // saveEvent
   
   private System.SavePoint sp1 = null;
   
   // Will the used be redirected to the Event after the save? 
   private Boolean gotoMeeting = false;

   // Save the Opportunity and go to the Event (for further editing).
   public PageReference saveOppGotoMeeting() {
      gotoMeeting = true;
      return saveOpp();
   } // saveOppGotoMeeting
   
   public Boolean showSaveOppButton {
      get {return ((allowCreateMeeting || allowCreateOpp) && (isLeadConvert || createOpportunity || createMeeting));}
   } // showSaveOppButton

   public String saveOppText{
      get {
         String buttonTxt = 'Save';
         if (!isLeadConvert && createOpportunity && createMeeting) {
            buttonTxt = 'Save Opportunity and Meeting';
         } else if (!isLeadConvert && !createOpportunity && createMeeting) {
            buttonTxt = 'Create Meeting with Existing Opp';
         } else if (!isLeadConvert && createOpportunity  && !createMeeting) {
            buttonTxt = 'Save Opportunity';
         } else if (isLeadConvert && createOpportunity  && createMeeting) {
            buttonTxt = 'Convert and Save Opportunity and Meeting';
         } else if (isLeadConvert && !createOpportunity  && !createMeeting) {
            buttonTxt = 'Convert';
         } else if (isLeadConvert && !createOpportunity  && createMeeting) {
            buttonTxt = 'Convert and Create Meeting with Existing Opp';
          } else if (isLeadConvert && createOpportunity  && !createMeeting) {
            buttonTxt = 'Convert and Save Opportunity';
         }
         return buttonTxt;
      }
   } // saveOppText
   
   public static Boolean NON_VISUAL_CONTEXT=false;
   
   // Save the Opportunity
   public PageReference saveOpp() {
      ErrorLog__c procLog = ErrorLog.getProcessLog(CLASSNAME);
      procLog.ObjectId__c = contactId;
      if(!verifyPRN()){
         String errorMessage = opp.Client_Referral__c != null ? 'The Lead Source cannot be Paychex Referral Network because the Referring Client is not enrolled as an Advocate.  One of the following actions must be taken: Adjust Lead Source or Referring client must be enrolled in Paychex Referral Network'
                : 'Please add a Client Referral to continue';
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorMessage)); 
         return null;
      }
      try{
         if (isLeadConvert) {
            // set the SavePoint in order to rollback if necessary
            sp1 = Database.setSavepoint();
             
            LeadCompanyMethods.CALCULATE_SIGNIFICANCE = false;
            AccountMethods.CALCULATE_SIGNIFICANCE = false;
            
            if (!handleLeadConvert()) {
               return null;
            } else if (leadToConvert.Lead_Company__c != null) {
               // look for extra leads attached to the lead company
               Lead[] extraLeads = ReferralQueries.selectLeads(new Set<Id>(), leadToConvert.Lead_Company__c);
               if (!extraLeads.isEmpty()) {
                  // the original lead should not be returned since it should already be converted.
                  Map<Id,Lead> additionalLeadMap = new Map<Id,Lead>();
                  for (Lead ld : extraLeads) {
                     additionalLeadMap.put(ld.Id,ld);
                     //convertExtraLead(acctId, ld);
                  }
                  convertExtraLeads(leadToConvert.Lead_Company__c, acct.Id, additionalLeadMap);
               } // if (!extraLeads
            } // if (!handleLeadConvert
            LeadCompanyMethods.CALCULATE_SIGNIFICANCE = true;
            AccountMethods.CALCULATE_SIGNIFICANCE = true;
            LeadCompanyMethods.checkLeadCompany(true);
            AccountMethods.checkSignificantContact();
         } // if (isLeadConvert
         
         //if (isMMS && acct != null) {
         //   opp.Payroll_Current_Prior_Method__c = acct.Current_Prior_Method__c;

         //}
         // set the pricebook on the Opportunity
         System.debug('CreateOppAndMeeting ph.pricebook='+(ph != null ? String.valueOf(ph.pricebook) : 'No Pricebook'));
         if (String.isNotBlank(selectedPricebookId)) { 
            Pricebook2 pricebook = pricebookByIdMap.get(selectedPricebookId);
            if (pricebook != null) { 
               opp.Pricebook2Id = pricebook.Id;
               System.debug('CreateOppAndMeeting opp.Pricebook2Id: '+opp.Pricebook2Id);
            }
         } // if (String.isNotBlank
         
         if (opp.Pricebook2Id == null && ph.pricebook != null) {
            opp.Pricebook2Id = ph.pricebook.Id;
            System.debug('CreateOppAndMeeting opp.Pricebook2Id was null using ph.pricebook: '+ph.pricebook.Id); 
         }
         // auto populate opp fields for APR0116379
         //String primComp = opp.Primary_Competition__c;
         //System.debug('ECP** primary competition based on selection** == '+primComp);
         //System.debug('** Primary competition On Opp to be saved** : '+opp.Primary_Competition__c);
         System.debug('** ECP account is : '+ acct +' and account.Current_Prior_Method__c : '+ acct.Current_Prior_Method__c+'  **');
         if(acct!=null && acct.Current_Prior_Method__c!=null){
            opp.Payroll_Current_Prior_Method__c = acct.Current_Prior_Method__c;
         }

         // set CampaignId
         opp.CampaignId = campaignId;
         if (String.isNotBlank(touchPointId)) {
            opp.Cadence_Touchpoint__c = touchPointId;
         }
         if (tempCtct != null && String.isNotBlank(tempCtct.Products__c)) {
            // other code formats it with a comma so handle that
            opp.AdditionalProductsOfInterest__c = tempCtct.Products__c.replace(';',', ');
            opp.EvaluateProductGroupOverride__c = true;
         }
         
         PartnerReferral__c partRef;        
         PartnerReferral__c[] partRefs = new PartnerReferral__c[]{};        
         system.debug('******lead Id:'+leadId+' contactId:'+contactId);     
         Id checkId = (leadId != null ? leadId : contactId);
         if (checkId != null) {      
           partRefs = [SELECT Id, Name
                            ,Amplifinity_Referral__c, Amplifinity_Referral__r.amp_dev__Advocate__c, Amplifinity_Referral__r.amp_dev__Advocate__r.ownerId
                            ,Opportunity__c,Lead__c,Contact__c,Destination__c,Source__c,Campaign__c
                            ,Referral__c
                            ,Referral__r.Id 
                            ,Referral__r.Amplifinity_Referral__c                               
                            ,Referral__r.Selling_Opportunity__c
                            ,Referral__r.PartnerReferral__c
                            ,Referral__r.User__c
                            ,Referral__r.Original_Employee_Count__c
                        FROM PartnerReferral__c 
                       WHERE (Lead__c = :checkId or Contact__c = :checkId)
                         AND Destination__c != null AND (NOT Destination__c LIKE 'NSS%') AND Source__c !=null order by CreatedDate desc];      
         } // if (checkId != null
         if(!partRefs.isEmpty()){       
             partRef = partRefs[0];     
             if(partRef!=null){     
                LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(partRef.Source__c);        
                if(llc!=null){      
                    opp.NSS_Source__c= llc.NSSSource__c;        
                }       
             }      
         } // if(!partRefs.isEmpty())
         
             // insert the opportunity
          if (createOpportunity){
             ErrorLog.startLog2(procLog, 'createOpp');
             system.debug('partref:'+partRef);
             Referral__c ref = null;
             if (partRef!=null) {
                if (partRef.Referral__r == null) {
                   ref = new Referral__c(Name=opp.Name);       
                   ref.PartnerReferral__c=partRef.Id;     
                   if (acct!=null) {        
                      ref.Account__c = acct.Id;        
                      partRef.Account__c = acct.id;        
                   }      
                   ref.SourceContact__c = contactId;      
                   partRef.Contact__c = contactId;        
                   ref.SourceLead__c = leadId;        
                   ref.Campaign__c = partRef.Campaign__c;     
                   ref.Status__c = 'Pending';     
                   //ref.Selling_Opportunity__c = opp.Id;       
                   ref.User__c = usr != null ? usr.Id : null;      
                   ref.Started_From__c = (leadId!=null?ObjectHelper.OBJECT_LEAD:ObjectHelper.OBJECT_CONTACT);     
                   ref.Original_Employee_Count__c = opp.Employees_Paid_Per_Payroll__c;
                   ref.CreatedByProcess__c='CreateOppAndMeeting';
                   insert ref;        
                        
                   partRef.Referral__c=ref.Id;
                   opp.ReferralLookup__c = ref.Id;
                   //updateOpp = true;
                   update partRef;
                } else if (partRef.Referral__r != null && partRef.Referral__r.Selling_Opportunity__c == null) {
                   // referral exists - update
                   ref = partRef.Referral__r;
                   //ref.Selling_Opportunity__c = opp.Id;       
                   ref.User__c = usr != null ? usr.Id : null;      
                   ref.Original_Employee_Count__c = opp.Employees_Paid_Per_Payroll__c;
                   //update ref;

                   opp.ReferralLookup__c = ref.Id;
                   //updateOpp = true;
                }        
             } // if(partRef!=null

              //Update Field Campaign with Sales Program if populated
              if(fieldCampaign!=null){
                  opp.Field_Campaign__c = fieldCampaign;
              }
             if (opp.Id == null) {
                insert opp;
             } else {
                update opp;
             }
             // Sush   APR0152220 
             System.debug('sus chatter test log before ' + opp);
             System.debug('sus chatter test log before ' + hasPeoPotential);
             Id asoOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('ASO Opportunity Record Type').getRecordTypeId();
             If(opp.OpportunityType__c == Label.HR_Pro_Upgrade && opp.RecordTypeId == asoOppRecordTypeId && hasPeoPotential  == true ){               
               System.debug('sus chatter test log etnry '); 
               Account accountdata = [Select id , OasisPEOAccountOwner__c from account where id =: opp.AccountId];                      
               map<id, User> userVsManagermap =new  Map<id, user>([Select id, ManagerId from User where (id = : opp.OwnerId or id = : accountdata.OasisPEOAccountOwner__c) ]); 
               List<id> userToMentionIdList = new List<id>();               
               userToMentionIdList.add(accountdata.OasisPEOAccountOwner__c);
               userToMentionIdList.add( opp.OwnerId);
               userToMentionIdList.add(userVsManagermap.get(opp.OwnerId).ManagerId);
               if (userVsManagermap.get(accountdata.OasisPEOAccountOwner__c) != null ) {
               userToMentionIdList.add( userVsManagermap.get(accountdata.OasisPEOAccountOwner__c).ManagerId);                  
               }
               String postTexts = 'PEO_OPP-Created-HR Services Created an Opportunity on this account identified as having PEO Potential. Please reach out to your HR Services partner to coordinate.';
               ChatterMentionPost.createChatterMentionPost( opp.id , userToMentionIdList, new String[]{postTexts},  false,  true );
                
            } // Sush APR0152220

             if (ref != null) {
                ref.Selling_Opportunity__c=opp.Id;
                //Add PRN info to referral
                system.debug('saveOpp Add PRN info to referral partRef.Amplifinity_Referral__c: '+partRef.Amplifinity_Referral__c);    
                if(partRef.Destination__c == 'Paychex Referral Network' && partRef.Amplifinity_Referral__c != null){
                    Referral_Partner__c refPartPRN = getRefPartPRN();
                    ref.Referral_Partner__c = (refPartPRN != null ? refPartPRN.Id : null);
                    //ref.Referral_Partner__c = Label.Amplifinity_RefPartnerId;
                    ref.ReferralPartnerName__c = 'Paychex Referral Network';
                    ref.SellingLeadSource__c = 'Referral-Paychex Referral Network';
                    ref.Referral_Id__c = partRef.Name;
                    ref.Amplifinity_Referral__c = partRef.Amplifinity_Referral__c;
                    ref.Referring_User__c = partRef.Amplifinity_Referral__r.amp_dev__Advocate__r.ownerId;
                    //add Opportunity to Amplifinity Referral
                            
                    if(partRef.Amplifinity_Referral__c!=null){
                        amp_dev__Amp_Referral__c ampRef = new amp_dev__Amp_Referral__c();
                        system.debug('saveOpp update amp_dev__Amp_Referral__c ampRef.Paychex_Referral__c: '+ampRef.Paychex_Referral__c);
                        ampRef.Id = partRef.Amplifinity_Referral__c;
                        ampRef.amp_dev__Opportunity__c = opp.Id;
                        ampRef.Paychex_Referral__c = partRef.Referral__c;
                        update ampRef;
                    }
                } // if(partRef.Destination__c == 'Paychex Referral Network'

                ReferralTriggerActions.SKIP_TRIGGER=false;
                update ref;
             } // if (ref != null
             //Boolean updateOpp = false;

              // CMFCMF save optyId and contactId for MarketTrackingMethods ** only for Inbound NSS optys
             If (usr != null && usr.NSS_Team__c == 'Inbound')
             {  optyCtctMap.put(opp.Id,contactId);  } 
             
             //update oppty joins that are created from inserting the opportunity that were also identified by existing opp component.  Mark these joins as existing opps.
             if(existingOpps!=null && !existingOpps.isEmpty()){
                Id[] oppIds = new Id[]{};
                for(ExistingOpptyWrapper eow:existingOpps){
                    oppIds.add(eow.opp.Id);
                }
                OpportunityJoin__c[] oJoins = [SELECT Id,JoinType__c, OpportunityParent__c,OpportunityChild__c FROM OpportunityJoin__c WHERE OpportunityParent__c IN :oppIds AND OpportunityChild__c = :opp.Id];
                if(oJoins!=null && !oJoins.isEmpty()){
                    for(OpportunityJoin__c oJoin : oJoins){
                        oJoin.JoinType__c='Existing Opportunity Duplicate';
                    }
                    update oJoins;
                }
             }
             //opportunity contact role
             OpportunityContactRole oppContactRole= new OpportunityContactRole();   
             oppContactRole.contactId= contactId;   
             oppContactRole.isPrimary=true; 
             oppContactRole.opportunityId=opp.Id;
             insert oppContactRole;
             system.debug('saveOpp after insert ContactRole: '+oppContactRole.contactId); 
            
             // this is handled already for a lead conversion scenario
             if (acct.Id != null && (isCore || isMMS) && String.isNotBlank(opp.Local_Competitors__c)) {
                acct.Local_Competitors__c=opp.Local_Competitors__c;
                Account tempAcct = new Account(Id=acct.Id, Local_Competitors__c=opp.Local_Competitors__c);
                if (isMMS) {
                   // not sure if we can get rid of this field - so continuing to populate
                   tempAcct.Local_Payroll_Vendor__c = opp.Local_Competitors__c;
                } // if (isMMS
                ZipCheckOwner.SKIP_TRIGGERS=true;
                update tempAcct;
                ZipCheckOwner.SKIP_TRIGGERS=false;
             } // if (!isLeadConvert
             ErrorLog.endLog2(procLog);
          } // if (createOpportunity
         // do we check ownership?
         if (usr != null && String.isNotBlank(usr.NSS_Team__c)) {
            NSSTeamMap__c ntm = NSSTeamMap__c.getInstance(usr.NSS_Team__c);
            if (ntm != null && ntm.CreateOwnership__c) {
               checkOwnership();
            } // if (ntm != null && ntm
            
         } // if (String.isNotBlank       
         if (createMeeting) {
            // if the save fails, will fall to the exception so don't need to handle it otherwise
            if(createOpportunity){
                system.debug('jsh event new');
                saveEvent(evnt,opp.LeadSource,opp.Name, phone, contactId,opp.Id);
           }
            else if(!createOpportunity && selectedOppWrap != null){
                system.debug('jsh event existing');
                saveEvent(evnt,selectedOppWrap.opp.LeadSource,selectedOppWrap.opp.Name, phone, contactId,selectedOppWrap.opp.Id);
            }
            else if(!createOpportunity && hasExistingOpps && selectedOppWrap == null){
                logError(null,'You must either select an existing opportunity, or choose the "Add Opportunity" button to create an opportunity');
                return null;
            }
            //CMF possibly put Chatter Post here if posting on event 
            if (gotoMeeting) {
               PageReference eventPr = new PageReference('/00U/e?id='+evnt.Id+'&retURL=%2F'+(createOpportunity ? opp.Id: contactId)+'&cancelURL=%2F'+(createOpportunity ? opp.Id: contactId));
               //eventPr.getParameters().put('id',evnt.Id);
               //eventPr.getParameters().put('retURL','%2F'+whatId);
               //eventPr.getParameters().put('cancelURL','%2F'+whatId);
               ErrorLog.saveLog(procLog);
               eventPr.setRedirect(true);               
               return eventPr;
            } // if (gotoMeeting
         } // if (createMeeting
         
         //CMF possibly put Chatter Post here if posting on opty
      // CMFCMF call MarketTrackMethods
      System.debug('**CMF ** calling MTM from COAM, dbConvertResultMap='+dbConvertResultMap+' optyCtCtMap='+optyCtCtMap);      
      if (dbConvertResultMap != null && !dbConvertResultMap.isEmpty())
      {  MarketTrackingMethods.addAcctCt(dbConvertResultMap);   }           // CMFCMF add account,contact info to tracking rcd for converted leads
      if (optyCtCtMap != null && !optyCtCtMap.isEmpty())
      { MarketTrackingMethods.linkOpty(optyCtCtMap);    }                   // CMFCMF find latest tracking rcd and put keywords on opty
      System.debug('**CMF ** end of saveOpp');      
         
         if (!NON_VISUAL_CONTEXT) {
            // by default go to the Opportunity
            PageReference finalPr = new PageReference('/'+(createOpportunity ? opp.Id: contactId));
            finalPr.setRedirect(true);             
            return finalPr;
         }
      } catch (Exception e) {
         logError(e,null,true);
      } 
      
      ErrorLog.saveLog(procLog);
      return null;
   } // saveOpp
    
   private Referral_Partner__c refPartPRN = null;
   public Referral_Partner__c getRefPartPRN() {
      if (refPartPRN == null) {
          try {
              // todo - these shouldn't be hardcoded
              refPartPRN = [Select Id, Name from Referral_Partner__c where Partner_Type__c='Amplifinity' and Name='Paychex Referral Network'];
          } catch (Exception e) {
              System.debug('getRefPartPRN e='+e.getMessage());
          }
      }
      return refPartPRN;
   } // getRefPartPRN
 
  
    public Boolean verifyPRN(){
        Boolean canSaveOpportunity = true;
        //check if PRN Oppty
        List<String> payrollOpptypes = Label.Amplifinity_Payroll_Types.split(',');
        if(opp.LeadSource == Label.Amplifinity_LeadSource && payrollOpptypes.contains(opp.OpportunityType__c)){
            if(opp.Client_Referral__c != null){
                Id acctId = opp.Client_Referral__c;
                Id incomingId = ContactId != null ? ContactId : leadId;
                Account acct = [Select Id, Amplifinity_Advocate__c, Amplifinity_Advocate__r.OwnerId, Name, NumberOfEmployees, OwnerId, Owner_Zip_Code__c, ShippingStreet, ShippingCity, ShippingState, Current_Prior_Method__c from Account where Id=:acctId];
                if(acct.Amplifinity_Advocate__c !=null){
                    //Update Referring Employee
                    if(opp.OwnerId != acct.Amplifinity_Advocate__r.OwnerId){
                        List<Contact> referringEmployee = [Select Id from Contact where User_Lookup__c =:acct.Amplifinity_Advocate__r.OwnerId and HR_Person_Id__c !=null limit 1];
                        if(!referringEmployee.isEmpty()){
                            opp.Referring_Employee__c = referringEmployee[0].Id;
                        }
                    }
                    //Update Amplifinity Submit Referral VF Page
                    List<amp_dev__Amp_Referral__c> ampRefs = [Select Id, amp_dev__Advocate__c, amp_dev__Status__c, amp_dev__Opportunity__c from amp_dev__Amp_Referral__c where amp_dev__Advocate__c=:acct.Amplifinity_Advocate__c 
                                                              and (Contact__c =:incomingId or amp_dev__Lead__c =:incomingId) limit 1];
                    if(!ampRefs.isEmpty()){
                        amp_dev__Amp_Referral__c ampRef = ampRefs[0];
                        //Look at custom metadata Amplifinity AR Status Mappings
                        String[] ampOpenStatuses = Label.Amplifinity_OpenStatuses.split(',');//new String[]{'Submitted', 'Accepted'};
                            if(ampOpenStatuses.Contains(ampRef.amp_dev__Status__c)){
                                opp.amp_dev__Referral__c = ampRef.Id;
                            }else{
                                //Call Amplifinity API using amp referral advocate
                                getAmpReferral(ampRef.amp_dev__Advocate__c, acct);
                            }
                        update ampRef;
                    }else{
                        //Call Amplifinity API using account advocate
                        getAmpReferral(acct.Amplifinity_Advocate__c, acct);
                    }
                }else{
                    canSaveOpportunity = false;
                }
            }else{
                canSaveOpportunity = false;
            }
                                    
        }
        return canSaveOpportunity;
        
    }//verifyPRN
    
    public void getAmpReferral(Id advocateId, Account acct){
        String vrFirstName;
        String vrLastName;
        String vrEmail;
        String vrPhone;
        String vrAccountName;
        Contact vrContact;
        Lead vrLead;
        Id accountId;
        if(contactId!=null){  
            vrContact = [Select Id, FirstName, LastName, Consent_to_Text__c, Consent_to_Text_Date__c, Contact_Stage__c, Description
                        , LatestCampaign__c, LeadSource, MktgId__c, Email, Marketo_Lead_Rating__c, OwnedByPrev__c, Phone, Products__c
                        , ProcessNotes__c, Title, AccountId, Account.Name, TransactionId__c
                        , MobilePhone ,Form_Fill_Date__c, BuyerZone_Lead_ID__c from Contact where Id=:contactId limit 1];
            if(vrContact!=null){
                vrFirstName=vrContact.FirstName;
                vrLastName=vrContact.LastName;
                vrEmail=vrContact.Email;
                vrPhone=vrContact.Phone;
                vrAccountName=vrContact.Account.Name;
                accountId = vrContact.AccountId;
            }
        }else{
            vrLead = [Select Id, amp_dev__Referral__c, City, Company, Consent_to_Text__c, Consent_to_Text_Date__c, Description
                     , Email, FirstName, LastName, LatestCampaign__c, Lead_Stage__c, LeadSource, Marketo_Lead_Rating__c, MktgId__c
                     , NumberOfEmployees, OwnedBy__c, OwnerId, Phone, PostalCode, Products__c, Product_Division__c, Promo_Code__c
                     , ProcessNotes__c, State, Street,OwnedByPrev__c, Title,TransactionId__c
                     , MobilePhone ,Form_Fill_Date__c, BuyerZone_Lead_ID__c, Current_Prior_Method__c from Lead where Id=:leadId limit 1];
            if(vrLead!=null){
                vrFirstName=vrLead.FirstName;
                vrLastName=vrLead.LastName;
                vrEmail=vrLead.Email;
                vrPhone=vrLead.Phone;
                vrAccountName=vrLead.Company;
            }
        }
        //submit verbal referral on contact for opportunity that has Leadsource PRN and Client Referral account that is an Advocate
        amp_dev.AmplifinityIntegrationHelper ampHelper = new amp_dev.AmplifinityIntegrationHelper();
        amp_dev.AmplifinityIntegrationModels.NewReferralModel[] referralModelsToUpdate = new amp_dev.AmplifinityIntegrationModels.NewReferralModel[]{};
            if(!test.isRunningTest()){
                Date referralDate = system.today();
                amp_dev__Amp_Program__c myProgram = ampHelper.GetAmplifinityPrograms()[0];
                amp_dev.AmplifinityIntegrationModels.NewReferralModel[] referralModels = new amp_dev.AmplifinityIntegrationModels.NewReferralModel[]{
                    // Create a new NewAdvocateReferralModel
                    new amp_dev.AmplifinityIntegrationModels.NewAdvocateReferralModel(
                        myProgram.Id,
                        advocateId,
                        'Suggested',
                        referralDate,    
                        vrFirstName,
                        vrLastName,
                        vrEmail,
                        vrPhone,
                        vrAccountName,
                        new amp_dev.AmplifinityIntegrationModels.AddressModel('','','','',''),
                        new amp_dev.AmplifinityIntegrationModels.ReferralRevenueModel(0),
                        0,
                        new Map<String, Object>())
                        };
                            referralModelsToUpdate.addAll(referralModels);
                system.debug('submitVRbeforeOppty referralModelsToUpdate: '+referralModelsToUpdate[0]);
                
            }
        
        //submit referral to Amplifinity
        try{
            amp_dev.AmplifinityIntegrationModels.SaveResult[] results = ampHelper.SubmitNewReferrals(referralModelsToUpdate);
            if(results != null || test.isRunningTest()){
                Id ampReferralId;
                if(test.isRunningTest()){
                    amp_dev__Amp_Referral__c testAmpRef = new amp_dev__Amp_Referral__c(amp_dev__Advocate__c=acct.Amplifinity_Advocate__c);
                    insert testAmpRef;
                    ampReferralId = testAmpRef.Id;
                }else{
                   ampReferralId =  results[0].GetId();
                }
                PartnerReferral__c ampPartRef;
                opp.amp_dev__Referral__c = ampReferralId;
                if(contactId!= null){
                    ampPartRef = TrackRecordEntry.logOriginalData(vrContact, acct);
                    //ampPartRef.Contact__c = contactId;
                }else{
                   // ampPartRef.Lead__c = leadId;
                    ampPartRef = TrackRecordEntry.logOriginalData(vrLead);
                }
                ampPartRef.LeadSource__c = 'Referral-Paychex Referral Network';
                ampPartRef.CreatedByProcess__c = 'Amplifinity';
                ampPartRef.Account__c = accountId;
                ampPartRef.Amplifinity_Referral__c = ampReferralId;
                ampPartRef.Amplifinity_Advocate__c = advocateId;
                ampPartRef.Destination__c = 'Paychex Referral Network';
                ampPartRef.Source__c = 'ReferralManagement';

                                       
                                                                                                                                                                         
                if(contactId!= null){
                    ampPartRef.Contact__c = contactId;
                }else{
                    ampPartRef.Lead__c = leadId;
                }
                insert ampPartRef;
            }
        }
        catch (amp_dev.AmplifinityIntegrationModels.AmpIntegrationException aiEx){
            system.debug('submitVRbeforeOppty fell into Catch aiEx: '+aiEx);
                           
        }
    }//getAmpReferral

   public void checkOwnership() {
      System.debug('checkOwnership acct.Id='+acct.Id);
      // check for existing ownership records
      Set<Id> acctIdSet = new Set<Id>{acct.Id};
      Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(acctIdSet, true, null, null);
      System.debug('checkOwnership acctOwnerMap is null='+(acctOwnerMap == null));
      // reselect the account - to get the extra values for accounts used by the NSS processes.
      //Id[] acctIdList = new Id[]{acct.Id};
      //Map<Id,Account> acctMap = ReferralQueries.selectAcctMap(acctIdList);
      //Account thisAcct = acctMap.get(acct.Id);
      
      String nssSource = ProspectOwnershipMethods.getNSS_Source(usr);
      Schema.RecordTypeInfo oppRtInfo = RecordTypeHelper.getRecordTypeById(opp.RecordTypeId, ObjectHelper.OBJECT_OPPTY);
      String oppRtName = (oppRtInfo != null ? oppRtInfo.getName() : null);
      //User usr, String productsOfInterest, String recordTypeName1, String recordTypeName2, String defaultValue, Integer nbrOfEmps
      System.debug('checkOwnership usr='+usr);
      System.debug('checkOwnership thisAcct='+acct);

      String[] nssTeams = ProspectOwnershipMethods.getNSSTeams(usr, null, oppRtName, null,null, acct.NumberOfEmployees);
      String nssTeam = nssTeams[0]; 
      System.debug('checkOwnership nssSource='+nssSource+' nssTeam='+nssTeam+' opp='+opp);
      
      ProspectOwnershipMethods.initializeSaveObjects();
      System.debug('checkOwnership before checkAccountOwnership');
      Prospect_Ownership__c po = ProspectOwnershipMethods.checkAccountOwnership(ProspectOwnershipMethods.STAGE_LOCKOUT, true, acct, null, (ctct != null ? ctct.Id : null), null, usr, opp.Id, nssTeam, nssSource, acctOwnerMap.get(acct.Id));
      System.debug('checkOwnership after checkAccountOwnership');
      ProspectOwnershipMethods.checkForSaves();

   } // checkOwnership
   
   
   public static String CONVERT_CACHE_KEY='CreateOppAndMeetingconvertStatus';
   public static String statusValue = Label.Lead_ConvertedStatus;
   public static LeadStatus convertStatus = null;
   
   public LeadStatus getConvertStatus() {
      if (convertStatus==null) {
         convertStatus = (!Utilities.SKIP_CACHE ? (LeadStatus)Cache.Org.get(CONVERT_CACHE_KEY) : null);
         if (convertStatus == null) {
            convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true and MasterLabel=:statusValue order by SortOrder ASC limit 1];
         }
         if (convertStatus != null && !Utilities.SKIP_CACHE && Utilities.CACHE_IN_USE) {
            Cache.Org.put(CONVERT_CACHE_KEY,convertStatus);
         }

      } // if (convertStatus==null 
      return convertStatus;
   } // getConvertStatus
   
   public Account accUpd;

   // CMFCMF list of results of lead converts
   public Map<Id, List<Id>> dbConvertResultMap;                 //  Map<LeadId, List<AccountId, ContactId>>
   // CMFCMF map of source contact id and selling opty ids, used to link Market Call Tracking rcd to opty 
   public Map<Id, Id> optyCtCtMap = new Map<Id, Id>();
      
   /** Process the Lead Convert.
    */
   public Boolean handleLeadConvert() {    
      if (leadToConvert == null) {
         return false;
      }
      //check if Company is empty   
      if(selectedCompany=='--None--'||selectedCompany==null){
         logError(null,'Prospect-Client Name: You must select a value');
         return false;
      }
      if (ErrorLog.processLog != null) {
         ErrorLog.processLog.ObjectId__c=leadToConvert.Id;
      }
      ErrorLog.startLog1(ErrorLog.processLog, 'ConvertLead');
      DG_DFR_Controller.enteredLeadConversion = true; 
      DG_LMF_Service.convertedLeadId = leadToConvert.Id;
     
      Database.LeadConvert lc = new Database.LeadConvert();
      dbConvertResultMap = new Map<Id, List<Id>>();
       
      lc.setLeadId(leadToConvert.Id);
      //lc.setOpportunityName(oppName); 
      lc.setDoNotCreateOpportunity(true);
      lc.setOwnerId(UserInfo.getUserId());
      if (selectedCompany!=null && selectedCompany!=CREATE_NEW_ACCT){
         lc.setAccountId(selectedCompany);
      }
      lc.setOverwriteLeadSource(false);
        
      //convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
      lc.setConvertedStatus(getConvertStatus().MasterLabel);
      Database.Leadconvertresult lcr = null;
      
      try {
         TrackRecordEntry.SKIP_TRIGGER=true;
          Database.DMLOptions dmo = DuplicateHelper.getDmlSkipCheck();
         lcr = Database.convertLead(lc, dmo);
         TrackRecordEntry.SKIP_TRIGGER=false;
      } catch (DmlException de) {
         System.debug('Error converting the lead: '+de.getMessage()+'; '+de.getStackTraceString());
         // return to the main lead page.
         logError(de,'An error occurred while attempting to convert the lead - can not proceed! Please try again. If the problem continues, contact SFDC Support.');
         ErrorLog.logError('CreateOppAndMeeting', 'handleLeadConvert', 'Exception Converting the Lead', leadToConvert.Id, de, leadToConvert, true);
         return false;
      } // try
      System.debug('Convert Result :'+lcr);
      if (!lcr.isSuccess()) {
         Database.Error err = lcr.getErrors()[0];
         logError(null,'Error converting Lead: '+err);
         ErrorLog.logError('CreateOppAndMeeting', 'handleLeadConvert', 'Error Converting the Lead', leadToConvert.Id, ('Error converting Lead: '+err), leadToConvert, true);
         return false;
      }
      //CMFCMF converted lead ok, save the details for Marketing Call Tracking rcd 
      List<Id> tempList = new List<Id>();
      tempList.add(lcr.getAccountId());
      tempList.add(lcr.getContactId());
      dbConvertResultMap.put(lcr.getLeadId(),tempList);
            
      acctId = lcr.getAccountId();
      accUpd = new Account(Id=acctId);
      // this doesn't do anything since we just created a new instance...
      //for (Contact checkCtct : accUpd.Contacts) {
      //   if (checkCtct.SignificantContact__c) {
      //      ctct = checkCtct;
      //   }
      //} // for (Contact checkCtct

      accUpd.Local_Competitors__c=leadToconvert.Local_Competitors__c;
      if (opp != null) {   
         opp.AccountId=lcr.getAccountId();
         accUpd.Local_Competitors__c=opp.Local_Competitors__c;
         if (isMMS) {
            // not sure if we can get rid of this field - so continuing to populate
            accUpd.Local_Payroll_Vendor__c = opp.Local_Competitors__c;
         }
      } // if (opp != null
     
      //accUpd=[select Id, Name, Current_Prior_Method__c,Local_Competitors__c from Account where Id=:lcr.getAccountId()];
      if (acct == null) { 
         accUpd.Current_Prior_Method__c=leadToConvert.Current_Prior_Method__c;
      } else {
         accUpd.Current_Prior_Method__c=acct.Current_Prior_Method__c;
      }
      Account checkAcct = [Select Id, BillingUUID__c from Account where Id=:acctId];
      accUpd.Employees__c = leadToConvert.NumberOfEmployees;
      accUpd.ShippingStreet = leadToConvert.Street;
      accUpd.ShippingCity = leadToConvert.City;
      accUpd.ShippingState = leadToConvert.State;
      accUpd.ShippingPostalCode = leadToConvert.PostalCode;
      // need to set this since we're skipping the trigger on save
      accUpd.ShippingUUID__c = checkAcct.BillingUUID__c;
      accUpd.SignificantContact__c = lcr.getContactId();
      accUpd.Language__c = leadToConvert.Language__c;
      ZipCheckOwner.SKIP_TRIGGERS=true;
      update accUpd;
      ZipCheckOwner.SKIP_TRIGGERS=false;
      contactId = lcr.getContactId();
      acct = ReferralQueries.selectAcct(lcr.getAccountId());
      accUpd = acct;
      ErrorLog.endLog1(ErrorLog.processLog);
      return true;
   } // handleLeadConvert

   // pass in extra leads to convert in a map.
   public Boolean convertExtraLeads(Id leadCompanyId, Id acctId, Map<Id,Lead> additionalLeadMap) {
      System.debug('convertExtraLeads additionalLeadMap='+additionalLeadMap);
      List<Contact> ctctsToUpdate = new List<Contact>();
      
      // if only a couple of leads convert immediately
      if (additionalLeadMap.size() <= 2) {
         Set<Id> keySet = additionalLeadMap.keySet();
         for (Id leadId : keySet) {
            Lead ld = additionalLeadMap.get(leadId);
            DoNotConvertLeadSources__c dncls = DoNotConvertLeadSources__c.getInstance(RecordTypeHelper.cleanRtName(ld.LeadSource));            
            if (dncls == null) {
               // remove from the map and convert if not one of the "protected" lead sources
               additionalLeadMap.remove(leadId);
               Id ctctId = convertExtraLead(acctId, ld);
               if (ctctId != null) {
                // make sure the sales contact flag is set
                  ctctsToUpdate.add(new Contact(Id=ctctId, Sales_Contact__c=true, Use_Zip_Assignment_Rules__c=true));
               }
            }
         }
      } // if (additionalLeadMap.size() <= 2
      
      // if there are any leads in the map, set the values on the lead company
      if (!additionalLeadMap.isEmpty()) {
         System.debug('convertLead leadCompanyId='+leadCompanyId+' acctId='+acctId);
         Lead_Company__c leadComp = new Lead_Company__c(Id=leadCompanyId, AccountId__c=acctId, EvaluateAccountId__c=true);
         try {
            update leadComp;
         } catch (Exception ex) {
            ErrorLog.logError('CreateOppAndMeeting', 'convertExtraLeads', 'updating lead company', acct.Id, ex);
            ErrorLog.checkSave();
         }
      }
      
      if (!ctctsToUpdate.isEmpty()) {
         Database.update(ctctsToUpdate,false);
      }

    return true;
   } // convertExtraLeads
   
   public Id convertExtraLead(Id acctId, Lead ld) {
      return convertExtraLead(acctId, ld.Id);
   } // convertExtraLead

   public Id convertExtraLead(Id acctId, Id leadId) {
      Boolean okay = true;
      Database.LeadConvert lc = new Database.LeadConvert();
        
      lc.setLeadId(leadId);
      lc.setDoNotCreateOpportunity(true);
      lc.setOwnerId(UserInfo.getUserId());
      lc.setAccountId(acctId);  
      lc.setOverwriteLeadSource(false);
        
      lc.setConvertedStatus(getConvertStatus().MasterLabel);
      Database.Leadconvertresult lcr = null;
      
      Id contactId = null;
      try {
         TrackRecordEntry.SKIP_TRIGGER=true;
         lcr = Database.convertLead(lc);
         contactId = lcr.getContactId();
         TrackRecordEntry.SKIP_TRIGGER=false;
         
          //CMFCMF converted lead ok, save the details for Marketing Call Tracking rcd 
          List<Id> tempList = new List<Id>();
          tempList.add(lcr.getAccountId());
          tempList.add(lcr.getContactId());
          dbConvertResultMap.put(lcr.getLeadId(),tempList);
         
      } catch (DmlException de) {
         // convert failed - what do we do here?
      } // try
      return contactId;
   } // convertExtraLead
   
   public ExistingOpptyWrapper[] queriedOpps = new ExistingOpptyWrapper[]{};
   
   // check for existing opportunities
   public void queryExistingOppty(Id acctId,String uSalesOrg){
      allowCreateOpp = true;

      if (oppTemp != null && oppTemp.RecordTypeId != null && acctId != null) {
         oppTemp.AccountId = acctId;
         // set this to false because cannot perform DML in the constructor
         OpptyDupeCheck.LOG_DATA=false;
         //Id[] rtIdsToCheck = OpptyDupeCheck.getRecordTypesToCheckAgainst(oppTemp.RecordTypeId);
         Opportunity[] matchingOpps = OpptyDupeCheck.dupeOpps(oppTemp);
         //Opportunity[] matchingOpps = OpptyDupeCheck.queryOpps(acctId, rtIdsToCheck, null);
         existingOpps = new ExistingOpptyWrapper[]{};
         for (Opportunity opp : matchingOpps) {
            queriedOpps.add(new ExistingOpptyWrapper(opp,(selectedOppWrap!=null && opp.Id == selectedOppWrap.opp.Id)));
         } // for (Opportunity opp
         
      } // if (opptyRtId != null
      System.debug('queryExistingOppty queriedOpps='+queriedOpps.size());
       // APR0152220
          if(oppTemp.OpportunityType__c == Label.HR_Pro_Upgrade && hasPeoPotential  == true){
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Alert: This Account is identified as having PEO potential. You must submit a Referral to the PEO-Virtual Direct Rep.'));
      } // APR0152220

   } // queryExistingOppty
   
   public String existingOppMsg{get;set;}
   
   // is the opportunity blocked and the running user is the owner?
   public static String OPP_BLOCKED_IS_OWNER = Label.OppBlocked_Owner;
   // is the opportunity blocked and the running user is not the owner?
   public static String OPP_BLOCKED_NOT_OWNER = Label.OppBlocked_NotOwner;
   
   public void checkExistingOpps() {
      System.debug('checkExistingOpps');
      existingOppMsg = 'Do You Want to Log Your EUP Against an Existing Opportunity?';
      allowCreateOpp = true;
      allowCreateMeeting = true;
      selectedOppWrap = null;
      existingOpps = new ExistingOpptyWrapper[]{};
      
      createOpportunity = (queriedOpps == null || queriedOpps.isEmpty());
      for (ExistingOpptyWrapper eow : queriedOpps) {
         System.debug('checkExistingOpps opp='+eow.opp.Name+' curValue='+eow.selected+' changing to false');
         eow.selected = false;
         if (String.isNotBlank(oppTemp.OpportunityType__c) && oppTemp.OpportunityType__c == eow.opp.OpportunityType__c && eow.opp.Probability >= 70) {
            // if we find one where the type matches and probability is greater than 70, can't proceed.
            allowCreateOpp = false;
            // if the owner is not the running user, do not allow them to create a meeting.
            if (eow.opp.OwnerId == usr.Id) {
               existingOppMsg = OPP_BLOCKED_IS_OWNER;
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, OPP_BLOCKED_IS_OWNER));
            } else {
               existingOppMsg = OPP_BLOCKED_NOT_OWNER;
               ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, OPP_BLOCKED_NOT_OWNER));
               allowCreateMeeting = false;
            }
            selectedOppWrap = eow;
            eow.selected = true;
            existingOpps.clear();
            existingOpps.add(eow);
            break;
         }
         existingOpps.add(eow);
      } // for (Opportunity opp
      System.debug('checkExistingOpps existingOpps='+existingOpps);
   } // checkExistingOpps
   
   public void storeSelectedOppty(){
      setRenderFalse();
      String v_oppId = ApexPages.currentPage().getParameters().get('oppId');
      String v_prevValue = ApexPages.currentPage().getParameters().get('prevValue');
      System.debug('storeSelectedOppty v_oppId='+v_oppId+' prevValue='+v_prevValue);
      //Boolean processed = false;
      String ctctName='';
      String ctctPhone='';
      String ctctMobile='';
      String ctctEmail='';
      String acctName='';
      if(ctct!=null && acct!=null){
         ctctName=ctct.Name;
         ctctPhone=ctct.Phone;
         ctctMobile=ctct.MobilePhone;
         ctctEmail=ctct.Email;
         acctName=acct.Name;
      }
      else if (leadToConvert != null){
         ctctName = leadToConvert.Name;
         ctctPhone = leadToConvert.Phone;
         ctctMobile = leadToConvert.MobilePhone;
         ctctEmail = leadToConvert.Email;
         acctName = leadToConvert.Company;
      }
      system.debug('storeSelectedOppty ctctName:'+ctctName+' ctctPhone: '+ctctPhone+' ctctMobile: '+ctctMobile+' ctctEmail: '+ctctEmail+' acctName: '+acctName);
      selectedOppWrap = null;
      
      if(existingOpps != null){
         for (ExistingOpptyWrapper eow:existingOpps){
            System.debug('storeSelectedOppty 1 opp='+eow.opp.Name+' selected='+eow.selected);
            eow.selected = (eow.opp.Id == v_oppId && v_prevValue == 'false');
            System.debug('storeSelectedOppty 2 opp='+eow.opp.Name+' selected='+eow.selected);
            if (eow.selected) {
               selectedOppWrap = eow;
               createOpportunity = false;
               if(createMeeting && evnt!=null){
                  updateEventInfo(selectedOppWrap.opp.Account.Name, selectedOppWrap.opp.Name
                                 ,ctctName, ctctPhone,ctctMobile
                                 ,v_street, v_city, v_state, v_postalCode,ctctEmail);
               }
            } // if (eow.selected


         } // for(ExistingOpptyWrapper
      }
      System.debug('storeSelectedOppty selectedOppWrap='+(selectedOppWrap != null));
      createOpportunity = (selectedOppWrap == null);
      if (selectedOppWrap == null && opp != null) {
         //createOpportunity = true;
         updateEventInfo(acctName, opp.Name
                           ,ctctName, ctctPhone,ctctMobile
                           ,v_street, v_city, v_state, v_postalCode,ctctEmail);
      }
      if(evnt != null){
         eventSubject = '"'+evnt.Subject+'"';
         eventDescription = '"'+evnt.Description+'"';
         //break;
      }
      system.debug('storeSelectedOppty selectedOppWrap: '+selectedOppWrap+' createOpp:'+createOpportunity+' event: '+evnt);
   } // storeSelectedOppty
   
   /** Cancel the operation - return to original record.
    */
   public PageReference cancel() {
      PageReference pr= new PageReference('/'+(contactId != null ? contactId : leadId));
      return pr;
   } // cancel

   
} // CreateOppAndMeeting