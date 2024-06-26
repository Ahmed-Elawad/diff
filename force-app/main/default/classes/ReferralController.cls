/*  
 * Handle the referrals between divisions.
 * 
 NSS THings to cover
 attach a referral contact
  
 * History
 * -------
 * 12/08/2011 Dan Carmen   Created
 * 01/25/2013 Cindy Freeman     Modified for FA referral process
 * 05/06/2013 Cindy Freeman     Modified so all sales reps can submit referral from referral contact
 *                              Also uses Started_From  and referralUser.Title to make decisions, not just NoRefOptyNeeded 
   07/08/2013 Dan Carmen    NSS changes
   11/06/2014 Dan Carmen        Change to convert extra leads outside this form
   11/19/2014 Dan Carmen        Expire ownership if a referral is created without an opportunity (send email=true)
   12/09/2014 Dan Carmen        Do not convert extra leads of certain lead sources
   09/24/2015 Cindy Freeman             added fields for Commissions auditing of referrals, added functionality for Jessica/Sales
   10/08/2015 Cindy Freeman             if is PEO Leasing only select PEO rep not both HR Solutions reps
   11/30/2015 Cindy Freeman         added code for Hispanic and to include all segments on referral form
   12/1/2015 Cindy Freeman              added code for WAR referral replacement project
   02/29/2016 Cindy Freeman             added Error Logging in saveOpportunities method, commented out savePoint and rollBack
   03/28/2016 Cindy Freeman         added check of Always_Check_Send_Email__c on referral partner to determine Send Email flag on Referral
   04/19/2016 Cindy Freeman             set User_Orverride__c to False on opty line items
   06/09/2016  Cindy Freeman    added code to include Default_Zip from Referral Partner when looks up zip assignments, 
                                then use it in setReferralList if primary zip code does not have assignment for that referral partner
   09/08/2016 Jermaine Stukes/Justin Stouffer Added attachment methods and logic
   09/20/2016 Jacob Hinds       Added Partner Referral code 
   10/03/2016 Justin Stouffer   Added DM and Multiple Locs for NSS Case 21556666
   11/21/2016 Cindy Freeman     Added 1 line so external partners can get a referring opty created
   12/15/2016 Cindy Freeman     added code so when Lead is converted call MarketTrackingMethods
   01/16/2017 Dan Carmen         If a child via the Sales Parent field use the zip code of the parent.
   03/07/2017 Cindy Freeman     adding acd_name to Referral so can pass it to selling opty when created 
   04/10/2017 Jacob Hinds       Adding partner referral linkage
   05/03/2017 Jacob Hinds       Setting owner of referral to queue if selected referral partner has Round Robin Setting Name field filled in
   05/17/2017 Dan Carmen      Additional changes to link partner referral to referrals
   05/24/2017 Jacob Hinds       Adding in transfer reason for transfer tracking
   06/01/2017 Carrie Marciano   Added method isIntSell to be able to not show sections on visualforce page
   06/14/2017 Dan Carmen        Added ability to create partner referral record.
   06/29/2017 Jacob Hinds       Added RR Reassign Deadline
   07/10/2017 Jacob Hinds       Adding Transfer Reason validation
   07/17/2017 Jacob Hinds       Moving RR Reassign Deadline to Process Builder, adding in Recent Activity Indicator
   08/07/2017 Jacob Hinds    Changing rw.ownerisqueue to rw.ref.Original_Owner_was_Queue__c
   08/29/2017 Jacob Hinds    adding campaign check to override referral partner queue
   09/09/2017 Cindy Freeman    added Frequency to screen so user can change frequency on Referring and Selling Optys
                               added method fixPEODisplayNames to tweak display name of PEO segments
                               only check PEO partner if NSS Referral
   12/05/2017 Dan Carmen       Adjustments for adding addtional components to the VF page.
   12/12/2017 Jacob Hinds     adding override functionality for returning ref.partners/segments, can now specify at referral partner to use specific zip segment
   12/26/2017 Dan Carmen       Default the Opportunity Type on Referring Opportunities.
   02/07/2018 Jacob Hinds     Commenting out partner referral update in saveReferrals in the leadSourceDefaultSet logic.
   02/20/2018 Dan Carmen       Add separate query for Partner Referral info.
   05/15/2018 Jacob Hinds     pre-selecting referral partner in list when Referral Partner record has Select Self checked
   05/31/2018 Mike Matonis    Added isMobile to distinguish between mobile and lightning
   07/31/2018 Dan Carmen      Fix for defaulting the activity date
   08/03/2018 Cindy Freeman   added/cleaned up some debug statements, added markSelectedCount to fix bug of ReferringOpty not getting created
   08/24/2018 Jacob Hinds     Fix for rsr ownership when converting a lead
   08/29/2018 Josh Cartwright added ASO_Partner__c  to the checkuser query  
   09/07/2018 Cindy Freeman   commented out all calls to checkDefaultProducts, no partner should be checked by default
   10/02/2018 Cindy Freeman     added check of nbrOfEmployees before using ASO Partner from MMS user
   10/16/2018 Cindy Freeman     changed asoPartner instantiation
   12/11/2018 Dan Carmen            Replace qbdialer__Call_Date_Time__c with CallDateTime__c
   02/11/2019 Dan Carmen          Added TimeZoneAbbrev__c/TimeZoneName__c to queries
   03/14/2019 Dan Carmen          Added retry ability for saving the referring opportunity
   07/30/2019 Dan Carmen       Changes for how referrals save   
   09/23/2019 Jake Hinds       Code for refer to self
   10/07/2019 Cindy Freeman     added check in nextStep method, Step3, if converted a lead to create opty and referral, queue up PartnerReferralSearch   
   10/07/2019 Jake Hinds       Code for queue specific partners
   10/21/2019 Cindy Freeman      modify code to use Apex Batch Control active flag when call PartnerReferralSearch in nextStep method
   10/21/2019 Dan Carmen         Add change for Warm_Transfer__c/Activity so that only 1 checkbox is set.
   11/14/2019 Dan Carmen         Remove ISDC fields
   12/17/2019 Cindy Freeman      move Transfer to Field Reason to referral in saveReferrals, change to display dropdown for Virtual users as well as NSRs
   12/22/2019 Cindy Freeman      let user change campaign on the form and add contact as a campaign member
   12/26/2019 Cindy Freeman      changes to call to PartnerReferralSearch to match on lead or account and contact
   12/31/2019 Cindy Freeman      modified call to PartnerReferralSearch
   01/07/2020 Cindy Freeman      modified contact query after converting PrimaryLead
                                 commented out majority of saveExtraInfo method to boost code coverage
   01/28/2020 Cindy Freeman      call CampaignMethods directly to create campaign member when campaign is updated on the form                                 
   03/21/2020 Cindy Freeman      set renderVForce in constructor
   04/16/2020 Cindy Freeman      catching error when thrown back from CreateOppAndMeeting.HandleLeadConvert
   05/12/2020 Cindy Freeman      catching error when thrown back from convertLead method
   06/01/2020 Pujitha Madamanchi Adding a where condition to checkForExistingPartRefs (Master Partner Referral is null). 
   07/15/2020 Jake Hinds         changes to support multiple referring opportunities
   07/22/2020 Jake Hinds         changes to check product checkboxes based on Referring product in createLineItem
   07/24/2020 Manmeet Vaseer     SFDC-3407 - disable the 'Submit Referral' button for all the profiles in the Sales_Admin_Profiles custom label. 
   08/21/2020 Jake Hinds         Reinstating change to support referral partner sales org field
   08/27/2020 Jake Hinds         Change to referring opp name
   10/19/2020 Brandon Vidro      Added creation of Partner Referrals w/ Source of Chat - APR0108929
   10/22/2020 Dan Carmen         Add Sales_Division__c to user query
   02/12/2021 Manmeet Vaseer       APR0114125 - New Process: NSS to Identify Channel Lead Source (US1-US3)
                                  Requirements: https://wiki.paychex.com/display/CP/APR0114125+-+New+Process%3A+NSS+to+Identify+Channel+Lead+Source
   05/07/2021 Pujitha Madamanchi APR0112504: change source from Partner_Referral_Source__c to Source_Type__c and populate CreatedByProcess__c
   06/28/2021 Eric Porter     Changes made for Referral Contact Inclusion
   08/03/2021 Jermaine Stukes   Update user query to include Hr Service Partner
   09/26/2021 Pujitha Madamanchi Remove Transfer Reason logic
   09/26/2021 Jermaine Stukes   Update HR Service Partner logic, move outside of teamSelling logic
   10/12/2021 Jermaine Stukes   Reverting back to original Team Selling Logic
   11/26/2021 Pujitha Madamanchi APR0124572: Add logic to create partner referral using Check Partner Referral on Referral Partner. 
   12/27/2021 Dan Carmen         Ability to set the Partner Type from Campaign Attributes
   04/08/2022 Jaipal/Dan     APR0122572: Integrated Selling Changes for MMS and PEO: checking for partnertype and assigning to segments based on requirement
   06/01/2022 Pujitha Madamanchi APR0122251 Set Referral Status to approved when case is created.
   06/12/2022 Jaipal APR0129551: Create Internal Referral Partner option for Rep to refer within same segment
   06/15/2022 Susmitha Somavarapu Wholesaler AND PEO - tagging in touchpoint after referral is made(US4 Clearslide)
   06/15/2022 Susmitha Somavarapu Wholesaler-Refer a Referral Contact(US3 Clearslide)
   08/08/2022 Jaipal APR0134678: Added check for !User_Special_Access__c on user for by-passing the logic to select HR Services on Partner Referral page
   11/09/2022 Dan Carmen         Change to allow for more Job Names (using the ReferralController_IntRef_Jobs label) to use internal referrals
   11/16/2022 Dan Carmen         Fix for Non_Paychex_Employee__c in verifyContacts
   01/24/2023 Pujitha Madamanchi APR0134608 Set Funnel Stage details on Second Referral from default Referral. 
   03/15/2023 Pujitha Madamanchi Fix for INC3291595, INC3293268
   04/18/2023 Pujitha Madamanchi  Add how is lead qualified?.
   06/15/2023 Jaipal              Added new routing rules to Integrated Selling for PEO APR0152114
   06/19/2023 Eric   Porter      Added filter for Default Lead Source setting APR0150054
   07/15/2023 Pratik Das         APR0151864: SMB Channel Evolution
   09/07/2023 Vinay  APR0155378  Added new field, Inbound_Integrated_Selling__c in markSelected method.
   09/07/2023 Pratik Das      APR0154201 Add processbutton to P&C Quote Data
   10/05/2023 Pujitha Madamanchi  Add new date check for Latest Campaign
   11/13/2023 Pujitha Madamanchi  Lead conversion uses Selected Acc 
   12/11/2023 Dan Carmen          Remove campaign query (fields added to ReferralQueries_Flds fieldSet) in createPartRefFromRefPart
   01/08/2024 Pujitha Madamanchi  Fix Touchpoint not populating on Referrals
   01/30/2024 Dan Carmen          In saveReferrals, if inserting and updating refs at the same time, don't insert the ref with the queue id, wait for the update
                                  so that the trigger fires properly.
   02/20/2024 Lalan Kumar         APR0159925: To update Referring Employee Selling Opportunity field in Referral
   03/13/2024 Dan Carmen          Fix for Referring Selling Employee logic - had to move where it was   
   03/14/2024 Dan Carmen          Separate MMS and Core referral partners in markSelected(). They were both being treated the same.
   04/23/2024 Jaipal              APR0162545: Disable Integrated Selling for Specific Campaigns(with new field exclude from integrated selling)
   05/30/2024 Dan Carmen          Change how PartnerReferralSearch is being called

   */
  public without sharing class ReferralController {
   
   public static final String CLASSNAME='ReferralController';
   public Id pcQuoteId{get;set;}//APR0154201 Add processbutton to P&C Quote Data
   public Boolean unauthorizedUser{get;set;}

   public Boolean recordFound{get;private set;}
   private Id returnId = null;
   public String returnName{get;private set;}
   public String returnRefOpty{get;private set;}                                                // for Return to Referring Opty button
   public String returnRefOptyName{get;private set;}                                            // for Return to Referring Opty button
   public boolean attachShow {get;set;}
   public Boolean allowActivity{get;private set;}
   public transient blob attachBody{get;set;}
   public string attachName{get;set;}
   // If a referring opportunity is being created for the sales rep. 
   public Opportunity referringOpp{get;set;}
   // If this starts from an Opportunity, the opportunity it starts from. This might become the referring Opportunity.
   public Opportunity startingOpp{get;set;}
   
   public Id accountId{get;set;}
   public Id contactId{get;set;}
   public Id refContactId{get;set;}
   public Id primaryLeadId{get;set;}
   
   public Contact ctct{get;set;}
   
   // If this starts from a Lead, the primary Lead in the grouping. 
   public Lead primaryLead{get;set;}
      
   private Lead[] leads;
    
   // the ids of the referral accounts linked to the entry record. To evaluate the types of referrals linked to see if additional referral options should appear.
   private Id[] referralAccountIds = new Id[]{};
   
   // The main ownership record
   public Prospect_Ownership__c primaryOwnership = null;
   
   /** The person who entered the form. */
   public User runningUser{get;set;}
    
   public boolean renderVForce {get; set;}
    
   public String qualifyType{get;set;}

   // Toggle visualforce display to speed initial load 
   public void toggleVForce(){
       renderVForce=TRUE;
   }
    
   // Is this displaying in Salesforce1?
   public Boolean isSF1 {get; set;}
   // Is this displaying in Salesforce1? 
   public Boolean isMobile {get; set;}
   
   // is the runningUser a DSA or DSM or ZSA or ZSM or System Admin? 
    public Boolean isRunningUserDSA {
        get {return (Utilities.checkDsaZsaProf(runningUser.Id));}            
    }

   public static String INBOUND_OASIS='Inbound-Oasis';
   public static String OUTBOUND_OASIS='Outbound-Oasis';
    
   public Boolean isOasis{get;set;}
    
   // If the referral is submitted on behalf of someone else, like a DSA submitting for the Sales rep, the person
   //    who will be the owner of the referral. Can be the same as the runningUser. 
   public User referralUser{get;set;}
      
   // The type of referral.
   public String partnerType{get;set;}
   public String nssSource{get;set;}
   

   // is this for an inbound NSR?
   public Boolean isNsrInbound {
      get {return (String.isNotBlank(nssSource) && nssSource.startsWith(ProspectOwnershipMethods.NSS_INBOUND)); }
   }
   
   //public static Boolean ALLOW_NSS_ROLE_CHANGE=(Label.ReferralControllerAllowNSSRoleChange=='True');
   
   // do we allow the user to allow the role of the user to change (inbound vs outbound)
   public Boolean allowRoleChange{
      get {
         return (roleOptions != null && !roleOptions.isEmpty());
      }
   } // allowRoleChange
   
   public void roleChanged() {
      System.debug('roleChanged');
      setRecordInfo();
   } // roleChanged
    
   // options needed if the user wants to switch what role they are submitting a referral in.
   public List<SelectOption> roleOptions{get;set;}

    public Boolean isVirtualSales{
     get{
        Boolean isVS = false;
        system.debug('sr:'+selectedRefs);
        if(selectedRefs!=null){
            for (ReferralWrapper rw : selectedRefs){
                system.debug('rp:'+rw.refPartner);
                if(rw.refPartner.IsVirtualSales__c){
                    isVS = true;
                    break;
                }
            }
        }
        return isVS;
     }
   } // isVirtualSales
   
   public Boolean isReasonRequired{
    get{
        Boolean reasonRequired = false;
        if(selectedRefs!=null){
            for (ReferralWrapper rw : selectedRefs){
            system.debug('nbrOfEmployees'+nbrOfEmployees+'isVS: '+isVirtualSales+'nsrIb: '+isNSRInbound);
              if(rw.refPartner.Transfer_Reason_Required__c && rw.refPartner.SellingOpportunityType__c == 'Payroll'
               && rw.refPartner.Emps_Min__c!=null && rw.refPartner.Emps_Max__c!=null && nbrOfEmployees >= rw.refPartner.Emps_Min__c && nbrOfEmployees <= rw.refPartner.Emps_Max__c 
               && !isVirtualSales && isNSRInbound){
                  reasonRequired=true;
              }
            }
        }
        return reasonRequired;
    }
   }
   
   public Boolean hasRecentActivity{
        get{return checkForRecentActivity();}
        set;
   }
      
   /** Referral Contact id that gave the wholesaler the lead */
   public String referralContactId{get; set;}
   public Referral_Contact__c referralContact{get; set;}
   
   /** set to true if Referring Opportunity not needed */
   public Boolean createReferringOpp{get;set;}
     
   public static final String ERROR='ERROR';
   public static final String STEP1='Step 1'; // enter referral
   public static final String STEP2='Step 2'; // verify and save referral
   public static final String STEP3='Step 3'; 
   
   /** Did an error occur? */
   public Boolean isError{
      get {return (String.isNotBlank(currentStep) && currentStep == ERROR); }
   } // isError
   
   /** Is this in Step 1? */
   public Boolean isStep1{
      get {return (String.isNotBlank(currentStep) && currentStep == STEP1); }
   } // isStep1

   /** Is this in Step 2? */
   public Boolean isStep2{
      get {return (String.isNotBlank(currentStep) && currentStep == STEP2); }
   } // isStep2

   /** Is this in Step 3? */
   public Boolean isStep3{
      get {return (String.isNotBlank(currentStep) && currentStep == STEP3); }
   } // isStep3
   
   public static String REF_INTERNAL='Internal Referral';
   public static String REF_EXTERNAL='External Referral';
   public static String REF_INTSELL='Integrated Selling';
   public static Set<String> NON_TELEMARKETING_TYPES=new Set<String>{REF_INTERNAL,REF_EXTERNAL,REF_INTSELL};
       
   public static String REF_NSS='NSS Referral';
   public static String REF_OASIS='Oasis';
   
   public Boolean isIntSell{
        get {return (partnerType == REF_INTSELL); }
   }
   
   public String currentStep{get;set;}
   
   public String referralTableTitle {
      get {
         String title='';
         if (isReferringRefContact) {
            title = 'Select Who This Activity Goes To';
         } else if (isTelemarketing) {
            title = Label.NSS_Create_Referral_Label;
         } else {
           title = (isStep1 ? 'Select Who This '+partnerType+' Goes To' : (isStep2 ? 'Please verify the following' : (isStep3 ? 'Referral Submission Complete' : '')));
         }
         return title;
      } // get
   } // referralTableTitle
    
   public String ctctColumnHeader {
      get {
         String title = (isReferringRefContact ? 'Referral Contact' : 'Prospect-Client Contact');
         return title;
      }
   } // ctctColumnHeader
      
   
   public Boolean showReferralOptions{get;set;}
   // is this a field sales rep?
   public Boolean isSalesRep{get;private set;}
   // is this from Virtual Sales?
   public Boolean isVirtualUser{get;private set;}           //CMFCMF
   // is this from one of the NSS/SDR groups?
    public Boolean isTelemarketing{get {
        return telemarketingUser;}}
    
   // Is this being opened as a popup form? If so, the buttons will change to close the window. 
   public Boolean isPopup{get;private set;}
   
   // If you only want to view the partner information. 
   public Boolean viewPartnersOnly{get;private set;}
   
   // Default referral values for all subsequent referrals created. 
   public Referral__c defReferral{get;set;}
   public Boolean isReferringRefContactLoad = false;
   public Boolean partReferralNeedsUpdate = false;
   public Boolean partnerReferralSource = false;
   public PartnerReferral__c partReferral {get;set;}

   public Integer nbrOfEmployees{get;private set;}
   
   public Boolean isEmbeddedForm{get;set;}
      
   public ReferralController(String salesOrg) {
      attachShow = False;
      isOasis=false;
     
      runningUser = UserHelper.getRunningUser();
    //  setDoWeNeedAPartnerReferral(runningUser);
      referralUser = runningUser;
      //isSF1 = Utilities.isSF1();
      nssSource = ProspectOwnershipMethods.getNSS_Source(runningUser);
      //renderVForce = false;
      renderVForce = true;      // CMFCMF
      defReferral = new Referral__c(ActivityDate__c=Date.today().addDays(7));
      partReferral = null;
      allowActivity = false;
   } // ReferralController
   
   // used to build commProd pick list based on Sales org
   public Map<String, List<String>> commProdMap {get; private set;}
   // used to determine if product selected is commissionable or not  
   public Set<String> commProdCommissionableSet {get; private set;}               // String is 'salesOrg-product'

   public static final String PARAM_EMBEDDED='EmbeddedForm';
   public static final String PARAM_FUNCTION='functionType';   

   private Boolean forcePartnerReferral = false;
   
   private Integer markSelectedCount = 0;
   public Boolean nextDisabled{ 
      get {return (markSelectedCount < 2 && !isTelemarketing);    }
   }
   
   // the job names that we'll use for internal referrals (to allow for more than just sales reps)
   public static Set<String> intRefJobNames = new Set<String>(Label.ReferralController_IntRef_Jobs.split(','));
    
   // Constructor.
   public ReferralController() {
      //APR0154201 Add processbutton to P&C Quote Data
      // System.currentPageReference().getParameters().get('pcQuoteId');
      if(System.currentPageReference().getParameters().get('pcQuoteId')!=null){
         pcQuoteId=System.currentPageReference().getParameters().get('pcQuoteId');
      }
     
      System.debug('ReferralController in the constructor!');
      // default to ERROR - only change it if everything is okay to continue
      currentStep = ERROR;

      // these are things we always do
      attachShow = False;
      allowActivity = false;
      //renderVForce = false;
      renderVForce = true;          // CMFCMF
      isSF1 = Utilities.isSF1();
      isMobile = Utilities.isMobile();
      runningUser = UserHelper.getRunningUser();
      
      // get the id of the object we originated from. If nothing is passed in here this should be an error!
      refObjectId = System.currentPageReference().getParameters().get('Id');
      defReferral = new Referral__c(ActivityDate__c=Date.today().addDays(7));

      if (!refObjectIdIsValid()) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The id passed into this form is not valid! id='+refObjectId));
         return;
      }
      returnId = refObjectId;
      PageReference refPage = new PageReference('/'+returnId);
      redirectUrl =  refPage.getUrl();
      // Did this come directly from a touchpoint?
      String touchpointIdAsString = System.currentPageReference().getParameters().get('TouchpointId');
      System.debug('ReferralController touchpointIdAsString='+touchpointIdAsString);
   
       try {
           if(String.isNotBlank(touchpointIdAsString)){
            Id touchpointId = (String.isNotBlank(touchpointIdAsString) ? (Id)touchpointIdAsString : (Id)null);
            System.debug('ReferralController touchpointId'+touchpointId);
            defReferral.Cadence_Touchpoint__c = touchpointId;
            System.debug('ReferralController defReferral.Cadence_Touchpoint__c='+defReferral.Cadence_Touchpoint__c);  
           }
           
       } catch (Exception e) {
          System.debug('ReferralController TouchpointId is not in the correct format: '+touchpointIdAsString+'; '+e.getMessage());
       } 

      // what type of referral is this?
      // Integrated Selling button passes in Integrated Selling
      // Submit Referral Passes in nothing (only startedFrom parameter)
      // Except for the case of Integrated Selling, we can get partnerType from user
      partnerType = System.currentPageReference().getParameters().get('partnerType');

      // check for the NSS Team value. If this exists 
      // Submit Referral NSS button - functionType=NSS
      // SDR Create Meeting button - functionType=Oasis
      String functionType = ApexPages.currentPage().getParameters().get(PARAM_FUNCTION);
       
      // check for the NSS Team setting of the user
      // if the user is a sales rep, default to Internal Referrals
      isSalesRep = (String.isNotBlank(runningUser.Job_Name__c) && intRefJobNames.contains(runningUser.Job_Name__c)); //==UserHelper.JOB_REP);
      System.debug('ReferralController job='+runningUser.Job_Name__c+' isSalesRep='+isSalesRep);
      //isSalesRep = Utilities.isSalesRep(runningUser.Profile.Name);
      isVirtualUser = runningUser.Profile.Name.contains('Virtual');             //CMFCMF
      // This is so if a rep has access to both buttons, as long as any value is passed in for function type it should work correctly.
      if (String.isNotBlank(functionType) || !isSalesRep) {
         checkNSSTeam(functionType);
      }
      
      // where did this start from? Example, started from the referral contact
      // 2/3/20 - I think we can get rid of this. I'm setting this in the refObjectIdIsValid method now.
      //defReferral.Started_From__c = System.currentPageReference().getParameters().get('startedFrom');                        
      // for NSS only
      // this defaults to event for new records. If it's NSS Inbound, we'll change it to task
      activityOption = (isNsrInbound ? 'Task' : 'Event');
      
      defReferral.CreateSellerTask__c = isNsrInbound;
      
       
      String isPopupCheck = System.currentPageReference().getParameters().get('IsPopup');
      // default to a false value
      isPopup = (String.isNotBlank(isPopupCheck) && isPopupCheck == 'true');
      
      String viewPartnerCheck = System.currentPageReference().getParameters().get('ViewPartnersOnly');
      viewPartnersOnly = (String.isNotBlank(viewPartnerCheck) && viewPartnerCheck == 'true');
      checkForAcdCampaign(System.currentPageReference().getParameters().get('acdname'));
      defReferral.acd_name__c = System.currentPageReference().getParameters().get('acdname');       
      System.debug('**CMF ** set acd_name from parameter='+defReferral.acd_name__c);
      String isEmbedded = System.currentPageReference().getParameters().get(PARAM_EMBEDDED);
      isEmbeddedForm = (String.isNotBlank(isEmbedded) && isEmbedded == 'true');
      
      // is this being entered for the NSS process?
      System.debug('ReferralController functionType='+functionType+' isSalesRep='+isSalesRep+' isVirtualUser='+isVirtualUser);
      
      // extra parameters needed when referral process is starting from Referral Contact    
      referralContactId = System.currentPageReference().getParameters().get('refContact');        // referral contact id
       if (referralContactId != null) {
          defReferral.Started_From__c = 'Referral Contact';
       }
      System.debug('ReferralController Started_From__c='+defReferral.Started_From__c);
      // don't continue if this parameter isn't set
      if (String.isBlank(defReferral.Started_From__c)) {
         return;
      }
      setup();
      System.debug('ReferralController defReferral.Cadence_Touchpoint__c='+defReferral.Cadence_Touchpoint__c);
   } // ReferralController
    
   public Boolean telemarketingUser = false;
  
   public void checkNSSTeam(String functionType) {
      if (String.isNotBlank(runningUser.NSS_Team__c)) {
         NSSTeamMap__c teamMap = NSSTeamMap__c.getInstance(runningUser.NSS_Team__c);
         if (teamMap != null) {
            nssSource = teamMap.NSSSource__c;
            partnerType = (String.isBlank(partnerType) ? teamMap.ReferralPartnerType__c : partnerType);
            if (teamMap.AllowSwitchReferralRole__c && String.isNotBlank(partnerType)) {
               setupRoleOptions(partnerType);
            }
         }
      } // if (String.isNotBlank(runningUser.NSS_Team__c
      telemarketingUser = String.isNotBlank(nssSource);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'nssSource='+nssSource+' telemarketingUser='+telemarketingUser));
      if (!telemarketingUser && String.isNotBlank(functionType)) {
          if (functionType == 'NSS') {
              partnerType = 'NSS Referral';
              nssSource = ProspectOwnershipMethods.getNSS_Source(runningUser);
          } else if (functionType == 'Oasis') {
              partnerType = 'Oasis';
              nssSource = INBOUND_OASIS;
          }
      }
      if(telemarketingUser && isReferringRefContact){
         partnerType = 'NSS Referral Contact';
      }
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkNSSTeam partnerType='+partnerType+' nssSource='+nssSource));
      System.debug('checkNSSTeam nssSource='+nssSource+' partnerType='+partnerType);
   } // checkNSSTeam
    
   public void setupRoleOptions(String partnerType) {
      String[] roleOptionValues = new String[]{};
      // retrieve role options from the NSS Team custom setting
      for (NSSTeamMap__c teamMap : NSSTeamMap__c.getAll().values()) {
         if (teamMap.ReferralPartnerType__c == partnerType && String.isNotBlank(teamMap.NSSSource__c) && !roleOptionValues.contains(teamMap.NSSSource__c)) {
            roleOptionValues.add(teamMap.NSSSource__c);
         }
      }
      roleOptionValues.sort();
      roleOptions = new SelectOption[]{};
      for (String value : roleOptionValues) {
         roleOptions.add(new SelectOption(value,value));
      }
      System.debug('setupRoleOptions roleOptionValues='+roleOptionValues.size());
   } // setupRoleOptions

   
   public void setup() {
      unauthorizedUser = false;
      String salesAdminRoles = Label.Sales_Admin_Profiles;
      List<String> salesAdminList = salesAdminRoles.split(',');
       
      defReferral.FormLoadStart__c=DateTime.now();
      
      referralUser = runningUser;
      defReferral.Referring_User__r = referralUser;
      defReferral.Referring_User__c = referralUser.Id;
             
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'isFunctionNSS='+isFunctionNSS));
      
    //  setDoWeNeedAPartnerReferral(runningUser);
       
      // if we're originating from a referral contact, use that as the return id
      if (!String.isBlank(referralContactId)) {
         // populate referralContact so have data for later
         referralContact = ReferralMethods.getRefCtct(referralContactId);
         if (referralContact != null) {
            defReferral.Referral_Contact__r = referralContact;
            defReferral.Referral_Contact__c = referralContactId;
            returnId = referralContactId;
         }
      } // if (!String.isBlank
    
      SalesOrg__c salesOrgSetting = SalesOrg__c.getInstance(runningUser.Sales_Org__c);
      Boolean validSalesOrg = (salesOrgSetting != null && salesOrgSetting.CanSubmitReferrals__c);
      System.debug('setup validSalesOrg='+validSalesOrg);
      
      // check if user is System Admin or Sales Org not in Sales
      if (isTelemarketing) { // TODO - have to also check if NSS profile?
         
      } else if (viewPartnersOnly) {
        // don't think we need to do anything here.
      } else if (runningUser.Profile.Name == Utilities.PROF_SYS_ADMIN) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'You are logged in as a System Administrator! You will need to select a sales org to continue.'));
         setupSalesOrgOptions();
         //setNonRepOptions();
         return;
      } else if (!validSalesOrg) { //(!UserHelper.DIVISION_LIST_SET.contains(runningUser.Sales_Org__c)) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You do not have a valid Sales Org for this form! Your Sales Org='+runningUser.Sales_Org__c));
         return;
      } else if (!isSalesRep && salesAdminList.contains(runningUser.Profile.Name)) {
         //SFDC-3407 - disable the 'Submit Referral' button for all the profiles in the Sales_Admin_Profiles custom label. 
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please note: You must be a Sales Rep to submit an internal referral.'));
         
          // This will disable nonRepOption picklist in referralForm (in Referral.vfc)
         unauthorizedUser = true; 
         return;
      } else if (!isSalesRep) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'You do not have a Sales Rep profile.'));
         salesOrg = referralUser.Sales_Org__c;
         defReferral.Referral_Source__c = UserHelper.WHOLESALER_TITLES_SET.contains(referralUser.Title) ? 'Wholesaler' : 'Sales Rep';                                                           
         //setNonRepOptions();
         return;
      } else {
         salesOrg = referralUser.Sales_Org__c;
         defReferral.Referral_Source__c = UserHelper.WHOLESALER_TITLES_SET.contains(referralUser.Title) ? 'Wholesaler' : 'Sales Rep';                                                           
      }
      System.debug('in setup calling setRecordInfo');
      setRecordInfo();
      
   } // setup

   // see if there's an acd name passed in and if so, is it attached to a campaign.
   public void checkForAcdCampaign(String acdName) {
      if (String.isNotBlank(acdName)) {
         defReferral.acd_name__c = acdName;
         // search for a campaign containing the acd name
         Campaign[] campaigns = [Select Id, Name, ACD_Name__c, LeadSource__c from Campaign where IsActive=true and ACD_Name__c = :acdName order by ACD_Name__c asc, StartDate desc];
         if (!campaigns.isEmpty()) {
            String msg = 'Campaign '+campaigns[0].Name+' found with LeadSource__c='+campaigns[0].LeadSource__c;
            ReferralWrapper.addToRefNotes(defReferral,msg);
            defReferral.Campaign__c = campaigns[0].Id;
            defReferral.SellingLeadSource__c = campaigns[0].LeadSource__c;
         }
      } // if (String.isNotBlank
   } // checkForAcdCampaign
   
   //check for recent activity, check recent activity indicator on page
   public Boolean checkForRecentActivity(){
        Boolean hasActivity = false;
        Date checkDateTask = system.today().addDays(-30);
        Date checkDateEvent = system.today().addDays(-90);
        if(ctct!=null){
            Integer taskCount = [SELECT count() FROM Task WHERE CreatedBy.NSS_Team__c = NULL AND CreatedDate >= :checkDateTask AND WhoId = :ctct.Id AND (Type='Email' OR Type = 'Call')];
            system.debug('taskCount: '+taskCount);
            Integer eventCount = [SELECT count() FROM Event WHERE CreatedBy.NSS_Team__c = NULL AND CreatedDate >= :checkDateEvent AND WhoId = :ctct.Id AND Type = 'Presentation - Initial'];
            system.debug('eventCount: '+eventCount);
            hasActivity = ((taskCount!=null && taskCount > 0) || (eventCount!=null && eventCount > 0));
        }
        
        return hasActivity;
   }
   
   /** Get the subTitle displayed on the referral page.
    */
   public String sectionHeaderSubTitle{
      get {
        String title = null;
        if (isReferringContact && ctct != null) {
           title=ctct.Name;
        } else if (isReferringAccount && acct != null) {
           title=acct.Name;
           if (ctct != null) {
              title += '-'+ctct.Name;
           }
        } else if (isReferringLead && primaryLead != null) {
           title = primaryLead.Name;
        //} else if (isReferringOpportunity && startingOpp != null) {
        //   title = startingOpp.Name;
        }
        return title;
      }
   } // sectionHeaderSubTitle
   
   /* The Id of the object we are referring - account, lead, contact, opportunity. */
   public String refObjectId{get;set;}
   
   public Boolean idIsValid{get; private set;}
    
   private String refObjectType = null;
   
   // Is the id that was passed in a valid id for this form?
   public Boolean refObjectIdIsValid() {
      idIsValid = false;
      try {
         Id checkId = (Id)refObjectId;
         defReferral.Started_From__c = checkId.getSObjectType().getDescribe().getName();
         refObjectType = defReferral.Started_From__c;
         idIsValid = true;
      } catch (Exception e) {
         System.debug('refObjectIdIsValid refObjectId-'+refObjectId+'-is not valid: '+e.getMessage());
      }
      System.debug('refObjectType='+refObjectType);
      return (idIsValid && (isReferringContact || isReferringAccount || isReferringOpportunity || isReferringLead|| isReferringRefContact));
   } // refObjectIdIsValid
       
   public Boolean isReferringContact {
      get {return isReferringObj(ObjectHelper.OBJECT_CONTACT); } 
   }
   public Boolean isReferringAccount {
      get {return isReferringObj(ObjectHelper.OBJECT_ACCOUNT); } 
   }
   public Boolean isReferringOpportunity {
      get {return isReferringObj(ObjectHelper.OBJECT_OPPTY); } 
   }
   public Boolean isReferringLead {
      get {return isReferringObj(ObjectHelper.OBJECT_LEAD); } 
   }
   public Boolean isReferringRefContact {
      get {return isReferringObj(ObjectHelper.OBJECT_REF_CONTACT); } 
   }

   
   public Boolean isReferringObj(String checkObjName) {
      System.debug('isReferringObj refObjectType='+refObjectType+' checkObjName='+checkObjName);
      return (String.isNotBlank(refObjectType) && refObjectType == checkObjName);
   } // isReferringObj
    
   public Boolean isFunctionNSS{get;set;}
   
   public Boolean isRefExternal {
          get {return (partnerType == REF_EXTERNAL);    }
   }

   public String nonRepOption{get;set;}
   public List<SelectOption> nonRepOptions{
      get {
         SelectOption[] options = new SelectOption[]{};
         options.add(new SelectOption('--Choose an Option--','--Choose an Option--'));
         options.add(new SelectOption('Someone Else','Someone Else'));
         options.add(new SelectOption('Myself','Myself'));
         return options;
      }
   } // nonRepOptions
   
   public PageReference nonRepOptionSelected() {
      if (nonRepOption != null && nonRepOption=='Someone Else') {
         tempRef = new Referral__c();
      } else if (nonRepOption != null && nonRepOption=='Myself') {
         setRecordInfo();
      }
      return null;
   } // nonRepOptionSelected

   public String activityOption{get;set;}
   public SelectOption[] activityOptions{
      get {
         SelectOption[] options = new SelectOption[]{};
         options.add(new SelectOption('Task','Task'));
         options.add(new SelectOption('Event','Event'));
         return options;
      }
   } // activityOption
   
   public Boolean isWarmTransfer{
      get {
         return (String.isNotBlank(activityOption) && activityOption == 'Warm Transfer');
      }
   } // isWarmTransfer
   
   public PageReference activityOptionChanged() {
      if (String.isNotBlank(activityOption) && defReferral != null) {
         defReferral.CreateSellerEvent__c = (activityOption == 'Event');
         defReferral.CreateSellerTask__c = (activityOption == 'Task');
      }
      return null;
   } // activityOptionChanged
   
   // if the warm transfer checkbox is changed on one of the referral records.
   public PageReference warmTransferChanged() {
      // see if it's checked on at least one record.
      Boolean hasWarmTransfer=false;
      for (ReferralWrapper rw : displayList) {
         if (rw.selected && rw.ref.Warm_Transfer__c) {
            hasWarmTransfer = true;
            break;
         }
      } // for (ReferralWrapper rw
      // if checked, activityOption = 'Warm Transfer'
      // if not checked, default the value
      activityOption = (hasWarmTransfer ? 'Warm Transfer' : (isNsrInbound ? 'Task' : 'Event'));
      return activityOptionChanged();
   } // warmTransferChanged
   
   /** The a user has been entered and we need to verify they're a sales rep.
       07/08/2013 - Dan - No NSS changes
    */
   public PageReference setReferralUser() {
    //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'In setReferralUser'));
    
      // verify that a user is set and is a sales rep
      if (tempRef.User__c != null) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'In setReferralUser - user is set'));
         // reselect the user
         User checkUser = [Select Id, Name, HR_Person_Id__c, NSS_Team__c, Sales_Org__c, Profile.Name, ASO_Partner__c, HR_Services_Partner__c, UserRoleId, UserRole.ParentRoleId, Title from User where Id=:tempRef.User__c and IsActive=true];
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'In setReferralUser - checkUser is selected'));
         // make sure the user has a sales sales org
         if (!UserHelper.DIVISION_LIST_SET.contains(checkUser.Sales_Org__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The user you selected does not appear to be a Sales user!'));
            return null;
         }

         // make sure the user is under the running user's control using ManageZipOrgUnits
         List<Id> checkUserIds = new List<Id>{tempRef.User__c};
         if (!UserHelper.areUsersVisible(runningUser, checkUserIds)) {
               ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can only submit Referrals for users that are in your Role Hierarchy!'));
               return null;
         }
         referralUser = checkUser;
         salesOrg = referralUser.Sales_Org__c;
         defReferral.Referral_Source__c = UserHelper.WHOLESALER_TITLES_SET.contains(referralUser.Title) ? 'Wholesaler' : 'Sales Rep';
         setRecordInfo();         
      } // if (tempRef.User__c
      return null;
   } // setReferralUser
   
   public Referral__c tempRef{get;set;}
      
   public void setStartedFrom(String objectName) {
      if (String.isBlank(defReferral.Started_From__c)) {
         defReferral.Started_From__c = ObjectHelper.OBJECT_CONTACT;
      }
   } // setStartedFrom
      
   /** 
      07/08/2013 - Dan - Changes made for NSS
    */
   public void setRecordInfo() {
      System.debug('setRecordInfo');
      // if a value is passed in do not show the picklist - default to that one value. Don't show the picklist for NSS
      showReferralOptions = (!isTelemarketing && partnerType == null);
      
      // default to Internal Referral
      partnerType = (String.isBlank(partnerType) ? REF_INTERNAL : partnerType);
      
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'contactId='+contactId+' opptyId='+opptyId));
      // at least one of the ids has to be passed in
      recordFound = false;
      
      referralSourceLeadSourceToCheck=null;
      attachedReferralSource=null;

      if (isReferringContact) {
        setStartedFrom(ObjectHelper.OBJECT_CONTACT);
         recordFound = handleContactId(refObjectId);
         //returnId = (referralContactId != null ? referralContactId : contactId);
         /*                        
      } else if (isReferringOpportunity) {
         setStartedFrom(ObjectHelper.OBJECT_OPPTY);
         recordFound = handleOpptyId(refObjectId);
         */
         //returnId = (referralContactId != null ? referralContactId : opptyId);
      } else if (isReferringAccount) {
         setStartedFrom(ObjectHelper.OBJECT_ACCOUNT);
         recordFound = retrieveAcct(refObjectId);
      } else if (isReferringLead) {
         setStartedFrom(ObjectHelper.OBJECT_LEAD);
         recordFound = handleLeadId(refObjectId);                
      } else if(isReferringRefContact){
         setStartedFrom(ObjectHelper.OBJECT_REF_CONTACT);
         recordFound = handleRefContactId(refObjectId);  
      }
         else {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A valid Id was not passed into the form!'));
      }
      if (recordFound) {
         System.debug('setRecordInfo has partReferral='+(partReferral != null)+' hasReferral='+(partReferral != null && partReferral.Referral__c != null)+' has Referral Partner='+(partReferral != null && partReferral.Referral__c != null && partReferral.Referral__r.Referral_Partner__c != null));
         // if there's a partner referral, see if there's a referral record.
         if (partReferral != null && partReferral.Referral__c != null && partReferral.Referral__r.Referral_Partner__c == null) {
            checkForExistingReferral(partReferral.Referral__c);
         }
         if (partReferral != null && partReferral.Id != null && defReferral != null && defReferral.PartnerReferral__c == null) {
            defReferral.PartnerReferral__c = partReferral.Id;
            if (partReferral.Campaign__c != null && defReferral.Campaign__c == null) {          //CMFCMF
               defReferral.Campaign__c = partReferral.Campaign__c;
               defReferral.SellingLeadSource__c = partReferral.Campaign__r.LeadSource__c;
            }
         }
         if (String.isBlank(defReferral.acd_name__c) && (isTelemarketing))
         {   defReferral.acd_name__c = findNSSTaskACDName(); }
         System.debug('**CMF ** recordFound defRef.acd_name = '+defReferral.acd_name__c);   
         checkReferralSource();         
         //read custom setting for commission product list               
         fillCommProdMap();
         setReferralOption();
         setZipCode();
      } else {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A valid record was not found for Id '+refObjectId));
      } // if (recordFound
  
      defReferral.FormLoadComplete__c = DateTime.now();
   } // setRecordInfo
   
   // find NSS Task created within last 2 days to get ACD name 
   public String findNSSTaskACDName() {
      DateTime nowDt = System.Now();
      DateTime earlyDt = nowDt.addHours(-24);
      DateTime lateDt = nowDt.addHours(24);
        
      String taskNSSrtId = TaskHelper.getNSSTaskRecordTypeId();
      Task[] taskList = new List<Task>();
      System.debug('**CMF ** defReferral.Started_From__c='+defReferral.Started_From__c);
      Id[] checkIds = new Id[]{};
      if (ctct != null) {
         checkIds.add(ctct.Id);
      }
      if (acct != null) {
         checkIds.add(acct.Id);
      }
      if (primaryLead != null) {
         checkIds.add(primaryLead.Id);
      }
      if (!checkIds.isEmpty()) {
         taskList =  [Select Id, WhoId, WhatId, CreatedDate
                            ,CallDateTime__c 
                            ,DS_Denali__DialSource_Action__c
                            ,DS_Denali__DialSource_Action__r.DS_Denali__Inbound_DNIS_Name__c
                            ,DS_Denali__DialSource_Action__r.DS_Denali__Call_Campaign__c
                        from Task
                       Where RecordtypeId = :taskNSSrtId
                         and (WhoId in :checkIds or AccountId in :checkIds)
                         and CallDateTime__c > :earlyDt and CallDateTime__c < :lateDt
                         order by CallDateTime__c DESC];
      }
      if (!taskList.isEmpty()) {
         for (Task tsk:taskList) {
            String acdName = TaskHelper.getAcdName(tsk,tsk.DS_Denali__DialSource_Action__r);
            if (String.isNotBlank(acdName)) {
               return acdName;
            }
         } // for
      } // if (!taskList.isEmpty())
      return null;
        
   } // findNSSTaskACDName

   // select these fields even though they should be null at this time   
   //Do not include fields from Referral, refresh cache and it would automatically pull all new fields as well in ObjectHelper.getSOQLQuery
   public static String[] REF_FIELDS = new String[]{'Referral_Partner__r.Id'
                                      ,'Referral_Partner__r.Name'
                                      ,'Referral_Partner__r.Partner_Type__c'
                                      ,'User__r.Id'
                                      ,'User__r.Sales_Division__c'
                                      ,'User__r.Sales_Org__c'
                                      ,'Account__r.Id'
                                      ,'Account__r.Frequency__c'
                                      ,'Account__r.Referral_National_Account__r.Id'
                                      ,'Referral_Contact__r.Id'
                                      ,'Referral_Contact__r.Referral_Account__c'
                                      ,'SourceContact__r.Referral_Contact__r.Id'                                      
                                      ,'SourceContact__r.Referral_Contact__r.Referral_Account__c'
                                      ,'SourceContact__r.LatestCampaignDate__c'
                                      ,'SourceContact__r.LatestCampaign__c'
                                      ,'SourceContact__r.LatestCampaign__r.OppNSSSource__c'
                                      ,'SourceContact__r.LatestCampaign__r.DestinationNbrDays__c' 
                                      };

   
   // check to see if there's an existing referral. If there is, use that.
   public void checkForExistingReferral(Id refId) {
      String refQuery = ObjectHelper.getSOQLQuery('Referral__c',REF_FIELDS,true, false, true);
      refQuery += ' where Id=:refId';
      try {
         Referral__c ref = Database.query(refQuery);
         System.debug('checkForExistingReferral found ref='+(ref != null));
         if (ref != null) {
            // if there's an existing referral record, use that as the default referral.
            // fill in the values that were populated earlier in the form.
            ref.Started_From__c = defReferral.Started_From__c;
            ref.CreateSellerTask__c = defReferral.CreateSellerTask__c;
            ref.FormLoadStart__c = defReferral.FormLoadStart__c;
            ref.Referring_User__r = defReferral.Referring_User__r;
            ref.Referring_User__c = defReferral.Referring_User__c;
            ref.Campaign__c = (defReferral.Campaign__c!=null?defReferral.Campaign__c:ref.Campaign__c);          //CMFCMF
            ref.Cadence_Touchpoint__c = defReferral.Cadence_Touchpoint__c;
            defReferral = ref;
            System.debug('checkForExistingReferral using ref as the defReferral');
         }
      } catch (Exception e) {
         System.debug('Could not query Referral__c with Id='+refId+', query='+refQuery+' e='+e.getMessage());
      }
   } // checkForExistingReferral
   
   /** The sales org of the current user. */
   public String salesOrg{get;set;}
   
   /** The options used to select the sales org. */
   public List<SelectOption> salesOrgOptions{get;private set;}
   
   public Boolean hasSalesOrgOptions{
      get {return (salesOrgOptions != null && !salesOrgOptions.isEmpty()); }
   } // hasSalesOrgOptions
   
   public void setupSalesOrgOptions() {
      salesOrgOptions = new List<SelectOption>();
      salesOrgOptions.add(new SelectOption('--Select a Sales Org--','--Select a Sales Org--'));
      for (String salesOrg : UserHelper.DIVISION_LIST) {
         salesOrgOptions.add(new SelectOption(salesOrg,salesOrg));
      }
   } // setupSalesOrgOptions
   
   public PageReference setSalesOrg() {
      System.debug('setSalesOrg');
      if (salesOrg != null && salesOrg != '--Select a Sales Org--') {
        setRecordInfo();
      }
      return null;
   } // setSalesOrg
   
   public static String REFERRAL_CONTACT='Referral Contact';
   
   public String zipCodeToUse{get;private set;}
   //private String currentZipCode=null;
   
   // the zip code from the main records we started on (lead/contact/account)
   private String primaryZipCode=null;
   // the zip code from the referral source (referral account) if it exists
   private String referralZipCode=null;
   
   public PageReference setReferralOption() {
      System.debug('setReferralOption');
      currentStep = ERROR;
      if (setRefPartners(partnerType)) {
  
         currentStep = STEP1;
         // setup the contact options
         setCtctOptions();

         // retrieve the referral record type available for the user. If none exist, we cannot create a referring opportunity
         String[] salesOrgs = new String[]{salesOrg};
         recordTypeMap = RecordTypeHelper.getRecordTypeByMapping(salesOrgs,'Opportunity',MAPPING_TYPES);
         // TODO - this needs to be checked.
         // depending on the type of opportunity, we might want to reuse or create a new one.
         // only create if this is coming from a sales rep opportunity (or if the record type is not a referral record type?), we'd create a new one.
         // if this is on a referral (or wholesaler) opportunity, we dont need it
         
         //markSelected();              // reversed order to be sure we get a referring opty (I hope)
         setZipCode();
         markSelected();
         
      } // if (recordFound
      return null;
   } // setReferralOption

    public void refCtctChanged() {
       // only for internal referrals  partnerType = REF_INTERVAL
        if (referringOpp.Referral_Contact__c != null) {
            // select referral contact with account
            attachedReferralSource = [Select Id, Name
                                           ,Referral_Account__c
                                           ,Referral_Account__r.Zip_Postal_Code__c
                                       From Referral_Contact__c where Id =:referringOpp.Referral_Contact__c];
            FORCE_RFRL_SRC_ZIP=true;
        }
        setZipCode();
    }
    
    public Boolean FORCE_RFRL_SRC_ZIP=false;
   public Boolean setZipCode() {
      Boolean okay = true;
      zipCodeToUse = null;
      
      primaryZipCode = null;
      referralZipCode = null;
      String tempTimeZoneName = null;
      String tempTimeZoneAbbrev = null;
      Set<String> zipsToRetrieveSet = new Set<String>();
      Set<String> overrideSegmentSet = new Set<String>();

      
      // if internal referral
      if (partnerType != REF_EXTERNAL ) {
          if (FORCE_RFRL_SRC_ZIP && attachedReferralSource != null) {
              referralZipCode = attachedReferralSource.Referral_Account__r.Zip_Postal_Code__c;
          } else if (String.isNotBlank(selectedReferralSourceOption) && selectedReferralSourceOption != NOT_REFERRAL 
              && attachedReferralSource != null 
              && String.isNotBlank(attachedReferralSource.Referral_Account__r.Zip_Postal_Code__c)) {
            ReferralLeadSourceMap__c rlsm = foundRecMap.get(selectedReferralSourceOption);
            if (rlsm != null && rlsm.NeedsReferralSource__c) {
               //zipCodeToUse = attachedReferralSource.Referral_Account__r.Zip_Postal_Code__c;
               referralZipCode = attachedReferralSource.Referral_Account__r.Zip_Postal_Code__c;
            }
         } // if (String.isNotBlank(selectedReferralSourceOption)

         if (acct != null) {
            tempTimeZoneName = acct.TimeZoneName__c;
            tempTimeZoneAbbrev = acct.TimeZoneAbbrev__c;
            if (acct.SalesParent__r != null && String.IsNotBlank(acct.SalesParent__r.Owner_Zip_Code__c)) {
               primaryZipCode = acct.SalesParent__r.Owner_Zip_Code__c;
               tempTimeZoneName = acct.SalesParent__r.TimeZoneName__c;
               tempTimeZoneAbbrev = acct.SalesParent__r.TimeZoneAbbrev__c;
            } else {
               primaryZipCode = (String.isNotBlank(acct.Owner_ZipCode__c) ? acct.Owner_ZipCode__c : acct.Owner_Zip_Code__c);
            }
         }       
         
         //primaryZipCode = (acct != null ? (String.isNotBlank(acct.Owner_ZipCode__c) ? acct.Owner_ZipCode__c : acct.Owner_Zip_Code__c) : null);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setZipCode primaryZipCode1='+primaryZipCode+' ctct='+ctct));
         //if (isReferringContact && ctct != null && String.isNotBlank(ctct.MailingPostalCode)) {
         //   primaryZipCode = ctct.MailingPostalCode;
         //} else 
         if (isReferringLead && primaryLead != null) {
            tempTimeZoneName = primaryLead.TimeZoneName__c;
            tempTimeZoneAbbrev = primaryLead.TimeZoneAbbrev__c;
            primaryZipCode = primaryLead.PostalCode;
         }
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setZipCode primaryZipCode2='+primaryZipCode));
         if (refAcct != null) {
            primaryZipCode = refAcct.Zip_Postal_Code__c;
         }
         if (defReferral.Started_From__c == REFERRAL_CONTACT && referralContact != null) {
            referralZipCode = referralContact.Referral_Account__r.Zip_Postal_Code__c;
         }
         system.debug('setZipCode primaryZipCode: '+primaryZipCode);
         // to account for zip+4
         if (String.isNotBlank(primaryZipCode)) {
                primaryZipCode = primaryZipCode.left(5);
            if (!zipsByZipCodeBySalesOrgMap.containsKey(primaryZipCode)) {
               zipsToRetrieveSet.add(primaryZipCode);
               system.debug('setZipCode added to zipsToRetrieveSet'); 
            }
         } // if (String.isNotBlank(primaryZipCode
         
         if (String.isNotBlank(referralZipCode)) {
            referralZipCode = referralZipCode.left(5);
            if (!zipsByZipCodeBySalesOrgMap.containsKey(referralZipCode)) {
               zipsToRetrieveSet.add(referralZipCode);
            }
         } // if (String.isNotBlank(primaryZipCode

         zipCodeToUse = (String.isNotBlank(referralZipCode) ? referralZipCode : primaryZipCode);
         system.debug('setZipCode zipCodeToUse: '+zipCodeToUse);
         // add Default Zip from Referral Partners to retrieve zip assignments      
         for (Referral_Partner__c rp : refPartners) {
             if (String.isNotBlank(rp.Default_Zip__c))
             {  zipsToRetrieveSet.add(rp.Default_Zip__c);   }
             system.debug('setZipCode overrideSegment key'+rp.Override_Segment_Key__c);
             if (String.isNotBlank(rp.Override_Segment_Key__c)){
               Set<String> segKeySet = new Set<String>(rp.Override_Segment_Key__c.split(','));
               overrideSegmentSet.addAll(segKeySet);
               system.debug('setZipCode overrideSegmentSet'+overrideSegmentSet);
             }
         }
          
         if (!referralAccountIds.isEmpty()) {
            Referral_Account__c[] refAccts = [Select Id, Name, ZipSegment2__c from Referral_Account__c where Id in :referralAccountIds and ZipSegment2__c != null];
             for (Referral_Account__c refAcct : refAccts) {
                 overrideSegmentSet.add(refAcct.ZipSegment2__c);
             }
         }
          
         if (!zipsToRetrieveSet.isEmpty()) {
            setZipAssign(zipsToRetrieveSet,overrideSegmentSet);
         }
         // set the time zone
         //checkTimeZone(zipCodeToUse,null);
         checkTimeZone(primaryZipCode,null,tempTimeZoneAbbrev,tempTimeZoneName);
      } // if (partnerType == REF_INTERNAL
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setZipCode zipCodeToUse='+zipCodeToUse+' isReferringAccount='+isReferringAccount+' acct='+acct));

      // create the referral list to display to the user
      setReferralList();
      return okay;
   } // setZipCode
   
   /** Does the incoming record (lead or contact) has an attached referral contact? */
   public Boolean hasAttachedReferralSource{
      get {return (attachedReferralSource != null); }
   } // hasAttachedReferralSource
   
   private String referralSourceLeadSourceToCheck=null;
   private Referral_Contact__c attachedReferralSource=null;
   
   public String referralSourceName{
      get {return (attachedReferralSource != null ? attachedReferralSource.Name : null); }
   }
   
   private String prevSelectedReferralSourceOption = null;
   public String selectedReferralSourceOption{get;set;}
   
   public SelectOption[] referralSourceOptions{get; private set;}
   
   public Boolean hasReferralSource{
      get {return (foundRecMap != null && !foundRecMap.isEmpty()); }
   }
   
   private Map<String,ReferralLeadSourceMap__c> foundRecMap = new Map<String,ReferralLeadSourceMap__c>();
   
   public static final String NOT_REFERRAL='NotAReferral';
   
   /** If there is a referral contact attached to the incoming lead/contact do we ask if this is a referral? 
    */
   public Boolean checkReferralSource() {
      Boolean okay = true;
      foundRecMap.clear();
      
      referralSourceOptions = new SelectOption[]{};

       /*
       * APR0114125 - 
       * Removed the default value for Inbound & Outbound NSS.
       * However, the users still want 'Keep Original Lead Source' value as drop-down menu selection.
       */
      referralSourceOptions.add(new SelectOption('','')); //
      referralSourceOptions.add(new SelectOption(NOT_REFERRAL,'Keep Original Lead Source'));
      selectedReferralSourceOption = '';

      // lead source takes priority in the match process
      Boolean leadSourceMatch = false;
      Boolean sourceTypeMatch = false;
      
      Map<String,ReferralLeadSourceMap__c> checkMap = new Map<String,ReferralLeadSourceMap__c>();
      
      ReferralLeadSourceMap__c referralSourceMatch = null;
      
      for (ReferralLeadSourceMap__c rlsm : ReferralLeadSourceMap__c.getAll().values()) {
        // only check the ones for the current partner type
        // check if it needs a referral source and has one
        // check if the NSS Source matches the NSS Source on the record (if any)
         if (rlsm.IsActive__c && rlsm.Partner_Type__c == partnerType
              && ((rlsm.NeedsReferralSource__c && hasAttachedReferralSource) 
                    || (!rlsm.NeedsReferralSource__c))
              && (String.IsBlank(rlsm.NSS_Source__c) || (String.isNotBlank(rlsm.NSS_Source__c) && rlsm.NSS_Source__c == nssSource))
            ) {
                // always put in the primary if there's not already a record there
                // should only be a record there if we've already matched on type
                if (!checkMap.containsKey(rlsm.SourceType__c) && rlsm.PrimarySourceType__c) {
               checkMap.put(rlsm.SourceType__c, rlsm);
                }
                
                
                
            // check to see if lead source matches
            if (!leadSourceMatch && String.isNotBlank(referralSourceLeadSourceToCheck) && referralSourceLeadSourceToCheck == rlsm.IncomingLeadSource__c) {
               leadSourceMatch = true;
               selectedReferralSourceOption = rlsm.Id;
               checkMap.put(rlsm.SourceType__c, rlsm);
            }
            
            // see if we match on referral type
            if (rlsm.NeedsReferralSource__c && referralSourceMatch == null && attachedReferralSource != null
                 && String.IsNotBlank(rlsm.ReferralBusType__c) 
                 && attachedReferralSource.Referral_Account__r != null 
                 && rlsm.ReferralBusType__c == attachedReferralSource.Referral_Account__r.Referral_Source_Business_Type__c) {
               referralSourceMatch = rlsm;      
            }
         } // if (rlsm.Partner_Type__c
      } // for (ReferralLeadSourceMap__c
      
      // if we didn't find a match by lead source
      if (selectedReferralSourceOption == NOT_REFERRAL && referralSourceMatch != null) {
         selectedReferralSourceOption = referralSourceMatch.Id;
         checkMap.put(referralSourceMatch.SourceType__c, referralSourceMatch);
      } //if (selectedReferralSourceOption
      
      prevSelectedReferralSourceOption = selectedReferralSourceOption;
      
      if (!checkMap.isEmpty()) {
         // create a sorted list to add to picklist
         List<String> keyList = new List<String>();
         keyList.addAll(checkMap.keySet());
         keyList.sort();
         for (String key : keyList) {
                ReferralLeadSourceMap__c rlsm = checkMap.get(key);
            foundRecMap.put(rlsm.Id, rlsm);
            referralSourceOptions.add(new SelectOption(rlsm.Id, rlsm.Label__c));
         }
      } // if (!foundRecMap 
      return okay;
   } // checkReferralSource
   
   public void referralSourceChanged() {
        ReferralLeadSourceMap__c prevRlsm = foundRecMap.get(prevSelectedReferralSourceOption);
      ReferralLeadSourceMap__c curRlsm = foundRecMap.get(selectedReferralSourceOption);
      
      Boolean prevHasRefSource = (prevRlsm != null && prevRlsm.NeedsReferralSource__c);
      Boolean curHasRefSource = (curRlsm != null && curRlsm.NeedsReferralSource__c);
      
      // only reevaluate zip code if changing from/to using a referral source
      if (prevHasRefSource != curHasRefSource) {
      //if ((prevRlsm == null &&  curRlsm != null) || (prevRlsm != null &&  curRlsm == null)) {
         setZipCode();
      } // if ((prevRlsm == null
      
      prevSelectedReferralSourceOption = selectedReferralSourceOption;
      //if (String.isNotBlank(selectedReferralSourceOption) && selectedReferralSourceOption != NOT_REFERRAL && attachedReferralSource != null && String.isNotBlank(attachedReferralSource.Referral_Account__r.Zip_Postal_Code__c)) {
        
      //}
   } // referralSourceChanged
   
   public Boolean checkReferringOpp() {
      Boolean okay = true;
     
      if (createReferringOpp && referringOpp == null && acct != null) {
         // create the opportunity for the running user
         // TODO - add in lead name
         referringOpp = new Opportunity();

         
         
          
         // this is to prevent line items from automatically being created
         referringOpp.OpportunityId__c = 'ReferralOpp';
         referringOpp.AccountId = acct.Id;
         referringOpp.Cadence_Touchpoint__c=defReferral.Cadence_Touchpoint__c;
         
         /* Not sure this is needed - if starting from referral contact won't necessarily create referring opportunity...   
         // CMF if starting at RC, get leadsource from there if possible.
         if (defReferral.Started_From__c == REFERRAL_CONTACT && referralContact != null)
         {   if (referralContact.Referral_Type__c != null && salesOrg != 'HRS')
             {       if (referralContact.Referral_Type__c.indexOf('CPA') > -1)
                     {       referringOpp.LeadSource = 'Referral - CPA';      }
                     else if (referralContact.Referral_Type__c.indexOf('Bank') > -1 && salesOrg != 'HRS')
                     {       referringOpp.LeadSource = 'Referral - Bank';     }
                     else if (referralContact.Referral_Type__c.indexOf('IIA') > -1 && salesOrg != 'HRS')
                     {       referringOpp.LeadSource = 'Referral - Independent Ins. Agent';   }
             }
             else
             {       referringOpp.LeadSource = 'Referral - Financial Advisor';        }               
         }
         else
         {   referringOpp.LeadSource = (ctct != null ? ctct.LeadSource : null);   }  
         */


         // updating opp field campaign US 4
         if(defReferral.Cadence_Touchpoint__c != null){
        Cadence_Touchpoint__c touchpoint = [Select Id, Cadence__r.OngoingCadence__c, Cadence__r.Sales_Campaign_Name__c, CarRecord__r.Sales_Program__c From Cadence_Touchpoint__c where id =: defReferral.Cadence_Touchpoint__c ]; 
        String salesProgram = (touchpoint.Cadence__r.OngoingCadence__c ? touchpoint.Cadence__r.Sales_Campaign_Name__c : touchpoint.CarRecord__r.Sales_Program__c);
        if ( String.isNotBlank(salesProgram)) {
              referringOpp.Field_Campaign__c=salesProgram;
        }
        }
        system.debug('var 1'); 
        if(runningUser.Profile.Name.startsWith(UserHelper.SO_NSS)){
         referringOpp.LeadSource = (ctct != null ? ctct.LeadSource : null);
      }
      ReferralMethods.setOpportunityFields(defReferral,referringOpp,false);
         
         CreateOppAndMeeting coam = new CreateOppAndMeeting(salesOrg);          //CMFCMF
         referringOpp.Frequency__c = (acct.Frequency__c != null ? coam.convertFrequency(acct.Frequency__c) : null);        //CMFCMF
         
         referringOpp.Employees_Paid_Per_Payroll__c = acct.NumberOfEmployees;
         
         if (referralContact != null)                                                                       
         {    referringOpp.Referral_Contact__c = referralContactId;  }
           
         // get the referral record type for the sales org
         String key = salesOrg+RecordTypeHelper.MAPPING_REFERRAL;
         Record_Type_Mapping__c rtm = recordTypeMap.get(key);
         if (rtm != null) {
            System.debug('Using record type from map'+rtm.RecordTypeId__c);
            referringOpp.RecordTypeId = rtm.RecordTypeId__c;
         } else {
            System.debug('Using user default record type');
            // we want to set this before saving so picklist options will display properly on the form
            referringOpp.RecordTypeId = RecordTypeHelper.getDefaultRecordType('Opportunity').getRecordTypeId();
         }
         referringOpp.OpportunityType__c=Label.OppType_Referral;
      } // if (createReferringOpp && referringOpp == null
       
      return okay;
   } // checkReferringOpp
   
   public List<SelectOption> referralOptions {
    get {
         List<SelectOption> options = new List<SelectOption>();
         options.add(new SelectOption(REF_INTERNAL,REF_INTERNAL));
         options.add(new SelectOption(REF_EXTERNAL,REF_EXTERNAL));
         options.add(new SelectOption(REF_INTSELL,REF_INTSELL));
         return options;
    }
   } // referralOptions

   public List<SelectOption> partnerOptions{get;set;}
   
   private List<Referral_Partner__c> refPartners = null;
   
   public static String SELECT_OPTION='--Select an Option--';
   
   public Boolean setRefPartners(String partnerType) {
      System.debug('ReferralController.setRefPartners partnerType='+partnerType);       
      partnerOptions = null;
      if(isReferringRefContact){
         refPartners = ReferralQueries.selectRefPartnersCache(partnerType, null);
      }else{
         refPartners = ReferralQueries.selectRefPartnersCache(partnerType, (isTelemarketing ? nssSource : null));
      }
      allowActivity = false;
      System.debug('ReferralController.setRefPartners refPartners='+refPartners+' nssSourceFilter='+(isTelemarketing ? nssSource : null));     
      // see if any values were returned - can't continue without values.
      Boolean okay = (refPartners != null && !refPartners.isEmpty());
      if (okay) {
        // build the option list for Referral Partners
         partnerOptions = new List<SelectOption>();
         partnerOptions.add(new SelectOption(SELECT_OPTION,SELECT_OPTION));
         for (Referral_Partner__c rp : refPartners) {
            allowActivity = (allowActivity || rp.CreateSellerActivity__c);
            partnerOptions.add(new SelectOption(rp.Id,rp.Name));
            System.debug('ReferralController.setRefPartners adding to partnerOptions='+rp.Name);            
         }
      } else {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, partnerType+' Referral Partner values could not be found! Values must be entered in the Referral Partner object to continue!'));
      } // if (!okay
      if (allowActivity) {
         setupTimePicklist();
      }
      
      setupProductMap(partnerType);
      return okay;
   } // setRefPartners
   
   public Boolean hasProductsByRefPartner{get;private set;}
   
   public static Map<String,List<String>> productByRefPartnerMap = new Map<String,List<String>>();
   
   public static Map<String,String> productDefaultMap = new Map<String,String>();
   
   public void setupProductMap(String partnerType) {
      productByRefPartnerMap.clear();
      String mappingKey = 'Prod-'+partnerType;
      for (ProductGroupMapping__c pgm : ProductGroupMapping__c.getAll().values()) {
         if (pgm.MappingType__c == mappingKey 
                 && String.IsNotBlank(nssSource) 
                 && nssSource == pgm.NSS_Source__c 
                 && String.isNotBlank(pgm.ReferralPartner__c)
                 && String.isNotBlank(pgm.Product_of_Interest__c)) {
            List<String> productList = productByRefPartnerMap.get(pgm.ReferralPartner__c);
            if (productList == null) {
               productList = new List<String>();
               productByRefPartnerMap.put(pgm.ReferralPartner__c,productList);
            }
            productList.add(pgm.Product_of_Interest__c);
            if (pgm.IsDefault__c) {
               productDefaultMap.put(pgm.ReferralPartner__c, pgm.Product_of_Interest__c);
            }
         } // if
      } // for (ProductGroupMapping__c pgm
      hasProductsByRefPartner = !productByRefPartnerMap.isEmpty();
   } // setupProductMap
   
   // is this eligible for ASO team selling?
   public Boolean teamSellingASOEligible=false;
   public Boolean campaignExcludeFromIS=false;
   
   /** The mapping types used to retrieve record type mapping information. */
   public static String[] MAPPING_TYPES = new String[]{RecordTypeHelper.MAPPING_REFERRAL};
   
   /** The map of record types used to create opportunities. */
   private Map<String,Record_Type_Mapping__c> recordTypeMap;
   
   

   public Boolean handleLeadId(Id leadId) {
      System.debug('handleLeadId leadId='+leadId);
      Boolean okay = false;
      prepareForContacts();
      if (leadId != null) {
         Set<Id> leadIdSet = new Set<Id>{leadId};
         // select the lead 
         leads = ReferralQueries.selectLeads(leadIdSet,null);
         
         // Should only be one lead returned - this is the one we'll use as part of this process
         if (!leads.isEmpty()) {
            // requery for the leads passing in the lead company (if it exists)
            if (leads[0].Lead_Company__c != null) {
               leads = ReferralQueries.selectLeads(leadIdSet,leads[0].Lead_Company__c);
            }
            //if (!leads[0].Partner_Referral_Lead__r.isEmpty()){
            //    system.debug('partReferral: '+leads[0].Partner_Referral_Lead__r);
            //   partReferral = leads[0].Partner_Referral_Lead__r;
            //}
         } // if (!leads
         
         Prospect_Ownership__c[] allOwnerRecs = new Prospect_Ownership__c[]{};
         
         for (lead ld : leads) {
            if (ld.Id == leadId) {
               // set the primary lead
               primaryLead = ld;
               primaryLeadId = ld.Id;
               if (ld.Referral_Contact__c != null && ld.Referral_Contact__r.Referral_Account__c != null) {
                  referralAccountIds.add(ld.Referral_Contact__r.Referral_Account__c);
               }
                

            }
            // collect all of the ownership records - not sure which lead the correct 
            if (ld.Prospect_Ownership__r != null) {
               allOwnerRecs.addAll(ld.Prospect_Ownership__r);
            }
            // clear out for view state
            ld.Description = null;
            ld.Prospect_Ownership__r.clear();

            addContact(new CtctWrapper(ld, isTelemarketing));
         } // for
         System.debug('handleLeadId primaryLead found='+(primaryLead != null));
         if (primaryLead != null) {
            // only check on the "primary" lead
            //checkDefaultProducts(primaryLead.Products__c, primaryLead.PEOLeasingDefault__c);
            checkSellingLeadSource(primaryLead.LeadSource, primaryLead.LatestCampaign__r, primaryLead.LatestCampaignDate__c);

            nbrOfEmployees = primaryLead.NumberOfEmployees;
            primaryOwnership = ProspectOwnershipMethods.getProspectingOwner(allOwnerRecs, ProspectOwnershipMethods.STAGE_PROSPECTING, null);

            referralSourceLeadSourceToCheck=primaryLead.LeadSource;
            attachedReferralSource=primaryLead.Referral_Contact__r;
            teamSellingASOEligible=primaryLead.TeamSellingASO__c;
            campaignExcludeFromIS = primaryLead.LatestCampaign__r!= null ? primaryLead.LatestCampaign__r.Exclude_from_Integrated_Selling__c : (defReferral.Campaign__c!=null ? defReferral.Campaign__r.Exclude_from_Integrated_Selling__c : false);
            System.debug('checkExistingPartRefs=');

            partReferral = checkForExistingPartRefs(primaryLead.Id);teamSellingASOEligible=primaryLead.TeamSellingASO__c;
         }
         // need to have at least one retrieved
      } // if (leadId != null
      
      okay = (leads != null && !leads.isEmpty()); 
      return okay;
   } // handleLeadId
   
   // the number of hours where it's okay to use the latest campaign
   public static Integer DATE_RANGE = Integer.valueOf(Label.RefCtrl_Campaign_Check);
   
   //store latestCampaign
   private Campaign v_latestCampaign = null;



   //used later on in saveReferrals if the default lead source is set.
   private Boolean leadSourceDefaultSet;
   
   public void checkSellingLeadSource(String existingLeadSource, Campaign latestCampaign, DateTime latestCampaignDate) {
      v_latestCampaign = latestCampaign;
      
      Boolean nonTelemarketing = (String.isNotBlank(partnerType) && NON_TELEMARKETING_TYPES.contains(partnerType));
      System.debug('checkSellingLeadSource partnerType='+partnerType+' existingLeadSource='+existingLeadSource+' nonTelemarketing='+nonTelemarketing);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'latestCampaignDate='+latestCampaignDate+' v_latestCampaign='+v_latestCampaign));
      if (!nonTelemarketing && v_latestCampaign != null && String.isNotBlank(v_latestCampaign.PartnerType__c) && latestCampaignDate != null) {
         Integer nbrDays = Integer.valueOf(v_latestCampaign.DestinationNbrDays__c);
         Datetime checkTime = Datetime.now().addDays(-nbrDays);
         if (latestCampaignDate > checkTime) { 
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'changing from partnerType='+partnerType+' nssSource='+nssSource));
            partnerType=v_latestCampaign.PartnerType__c;
            nssSource=v_latestCampaign.RefPartnerNSSSource__c;
            // clear the options so locked in what's on the campaign
            roleOptions = new SelectOption[]{};
         }
      } // if (v_latestCampaign != null

      if (isTelemarketing) {
         if (String.isBlank(defReferral.SellingLeadSource__c) && latestCampaign != null && String.isNotBlank(latestCampaign.LeadSource__c)) {
            defReferral.SellingLeadSource__c = latestCampaign.LeadSource__c;
         }
         if (String.isBlank(defReferral.SellingLeadSource__c) && String.isNotBlank(nssSource) && nssSource == ProspectOwnershipMethods.NSS_INBOUND) {
            defReferral.SellingLeadSource__c = Label.LeadSource_Inbound_Default;

            leadSourceDefaultSet = true;
         }
         
         if (isNsrInbound && defReferral.Campaign__c == null && latestCampaign != null && latestCampaignDate != null) {
            // attach the latest campaign to the campaign field on the referral if it latest campaign date falls within the date range
            if (latestCampaignDate.addDays(DATE_RANGE) > DateTime.now()) {
               defReferral.Campaign__c = latestCampaign.Id;
            }
         } // if (isNsrInbound &&
         
      } // if (isTelemarketing
      
      // don't set it if already set
      //if (String.isBlank(defReferral.SellingLeadSource__c) && (runningUser.Profile.Name.startsWith(UserHelper.SO_NSS)||runningUser.UserRole.Name == 'Oasis SDR'||runningUser.UserRole.Name.startsWith('Sales Development Rep') )) {
      if (String.isBlank(defReferral.SellingLeadSource__c) && (String.isNotBlank(runningUser.NSS_Team__c ))) {
         defReferral.SellingLeadSource__c = existingLeadSource;
      } 
       
   } // checkSellingLeadSource
   
   /** For any sales orgs that will be defaulted to selected. */
   private Set<String> defaultRefPartnerSet = new Set<String>();
   
   /** Check the product list and see if we can default on any sales org.
    */
   public void checkDefaultProducts(String productString, Boolean peoLeasing) {
        System.debug('checkDefaultProducts partnerType='+partnerType+' productString='+productString);
      defaultRefPartnerSet = new Set<String>();
      if (peoLeasing && isTelemarketing) {                             // only set default for NSS Referrals
         defaultRefPartnerSet.add(UserHelper.SO_PEO_ASO);
         defaultRefPartnerSet.add(UserHelper.SO_PEO_ASO+'-PEO');                //PEOPEO
      }
      /*
      // if no data do nothing
      if (String.isBlank(productString)) {
         return;
      }
      // should be coming in semi-colon separated
      String[] prodList = productString.split(';');
      for (String prodName : prodList) {
         System.debug('checkDefaultProducts prodName='+prodName);
         for (ProductGroupMapping__c pgm : ProductGroupMapping__c.getAll().values()) {
            if (pgm.MappingType__c == partnerType && pgm.Product_of_Interest__c == prodName) {
               if (String.isNotBlank(pgm.ReferralPartner__c)) {
                  defaultRefPartnerSet.add(pgm.ReferralPartner__c);
               }
               break;
            } // if (pgm.MappingType__c
         } // for
      } // for (String prodName
      System.debug('checkDefaultProducts defaultRefPartnerSet='+defaultRefPartnerSet);
      */   
   } // checkDefaultProducts
   

   private Boolean contactHandled = false;

   /** If a contact id is passed in, handle the contact id. 
    */
   
   public Boolean handleContactId(Id ctctId) {
      Boolean okay = false;
      ctct = ReferralQueries.selectContact(ctctId);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'handleContactId ctct='+ctct)); 
      if (ctct != null) {
         returnName = (referralContactId == null ? ctct.Name : referralContact.Name);
         if (ctct.HR_Person_Id__c != null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The referral process can not be started from this type of contact.')); 
         } else {
            setContactInfo();
            okay = retrieveAcct(ctct.AccountId);
         }
         partReferral = checkForExistingPartRefs(ctct.Id);
      } // if (contactId != null
      
      return okay;
   } // handleContactId
    
   public void setContactInfo() {
      if (ctct != null) {
         contactHandled = true;
         defReferral.SourceContact__c = ctct.Id;
         contactId = ctct.Id;
         returnName = (referralContactId == null ? ctct.Name : referralContact.Name);
         if (ctct.Referral_Contact__c != null && ctct.Referral_Contact__r.Referral_Account__c != null) {
            referralAccountIds.add(ctct.Referral_Contact__r.Referral_Account__c);
         }
         checkSellingLeadSource(ctct.LeadSource, ctct.LatestCampaign__r, ctct.LatestCampaignDate__c);

         referralSourceLeadSourceToCheck=ctct.LeadSource;
         attachedReferralSource=ctct.Referral_Contact__r;
         teamSellingASOEligible=ctct.TeamSellingASO__c;
         campaignExcludeFromIS = ctct.LatestCampaign__r!= null ? ctct.LatestCampaign__r.Exclude_from_Integrated_Selling__c : (defReferral.Campaign__c!=null ? defReferral.Campaign__r.Exclude_from_Integrated_Selling__c : false);
         partReferral = checkForExistingPartRefs(ctct.Id);
      } // if (ctct != null
   } // setContactInfo
   
   //modify so handles refContactId
   private Boolean refContactHandled = false;
   public Referral_Contact__c refCtct {get; set;}

   public Boolean handleRefContactId(Id refContactId){
      System.debug('Handle Ref Contact Id Running');
      activityOption = (isReferringRefContact ? 'Event' : 'Task');
      System.debug('handleRefContactId isReferringRefContact='+isReferringRefContact);
      isReferringRefContactLoad = true;
      System.debug('Is Referring Referral Contact Loaded?: '+ isReferringRefContactLoad);
      Boolean okay = false;
      refCtct = [Select Id,Name,Referral_Account__c,Referral_Account__r.Zip_Postal_Code__c,Email__c from Referral_Contact__c where id = :refContactId];
      System.debug('this is what we get in Handle Ref Contact Id, Ref Contact ='+refCtct);
      if (refCtct != null) {
         defReferral.Referral_Contact__c =refCtct.Id;
         returnName = refCtct.Name;
         referralAccountIds.add(refCtct.Referral_Account__c);
         refContactHandled = true;
         okay = retrieveRefAccount(refCtct.Referral_Account__c);
      } // if (refCtct != null
      return okay;
   } // handleRefContactId
    
   /** If an opportunity id is passed in, select the opportunity information.
    */
    /*
   public Boolean handleOpptyId(Id opptyId) {
      Boolean okay = false;
      startingOpp = ReferralQueries.selectOpp(opptyId);
      if (startingOpp != null) {
         returnName = (referralContact == null ? startingOpp.Name : referralContact.Name);              
         // look for Primary Contact
         if (startingOpp.OpportunityContactRoles != null && !startingOpp.OpportunityContactRoles.isEmpty()) {
            // use the first one
            OpportunityContactRole ocr = startingOpp.OpportunityContactRoles.get(0);
            defReferral.SourceContact__c = ocr.ContactId;
            ctct = ocr.Contact;
            checkDefaultProducts(ctct.Products__c,false);
         }
         okay = retrieveAcct(startingOpp.AccountId);
      } // if (opp != null)
      return okay;
   } // handleOpptyId
   */
   /** Retrieve the account information. 
    */
   public Boolean retrieveAcct(Id acctId) {
      Account acct = ReferralQueries.selectAcct(acctId);
      if (acct != null) {
         if (String.isBlank(returnName)) {
            returnName = acct.Name;
         }
         //checkDefaultProducts(acct.Products__c,acct.PEOLeasingDefault__c);
      } // if
      return setAccount(acct);
   } // retrieveAcct
   
   public Referral_Account__c refAcct = null;
   
   public Boolean retrieveRefAccount(Id refAcctId){
      System.debug('Retreive Referral Account Running');
      try {
         refAcct = [Select Id, Name, Zip_Postal_Code__c // whatever other fields you need
                                          ,(Select Id, Name, Email__c  from Referral_Contacts__r)
                                       From Referral_Account__c where id=: refAcctId];
      } catch (Exception e) {
         System.debug('retrieveRefAccount e='+e.getMessage());
      }
      return setReferralAccount(refAcct);
   } // retrieveRefAccount
      
   /** Set the account object. */
   public Boolean setAccount(Account p_acct) {
      Boolean okay = (p_acct != null);
      if (!okay) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A Prospect-Client record could not be found! Cannot proceed with Referrals'));
      } else {
         acct = p_acct;
         accountId = acct.Id;
         nbrOfEmployees = acct.NumberOfEmployees;
          
         if (acct.Banker_Name_Ref__c != null && acct.Banker_Name_Ref__r.Referral_Account__c != null) {
            referralAccountIds.add(acct.Banker_Name_Ref__r.Referral_Account__c);
         }
         if (acct.Broker_Name_Ref__c != null && acct.Broker_Name_Ref__r.Referral_Account__c != null) {
            referralAccountIds.add(acct.Broker_Name_Ref__r.Referral_Account__c);
         }
         if (acct.CPA_Name_Ref__c != null && acct.CPA_Name_Ref__r.Referral_Account__c != null) {
            referralAccountIds.add(acct.CPA_Name_Ref__r.Referral_Account__c);
         }
         if (acct.Insurance_Broker_Name_Ref__c != null && acct.Insurance_Broker_Name_Ref__r.Referral_Account__c != null) {
            referralAccountIds.add(acct.Insurance_Broker_Name_Ref__r.Referral_Account__c);
         }
         if (acct.Referral_National_Account__c != null) {
            referralAccountIds.add(acct.Referral_National_Account__c);
         }

          
         // need to use an enterable field for the form.
         //acct.Owner_Zip_Code__c = acct.Owner_ZipCode__c;
         // set the Contacts
         prepareForContacts();
         ctct = (!contactHandled ? null : ctct);
         if (ctct != null) {
            addContact(new CtctWrapper(ctct, isTelemarketing));
         }
         
         System.debug('setAccount Contacts='+acct.Contacts.size());
         if (acct.Contacts != null && !acct.Contacts.isEmpty()) {
            for (Contact thisCtct : acct.Contacts) {
                if (ctct == null || (ctct != null && ctct.Id != thisCtct.Id)) {
                  addContact(new CtctWrapper(thisCtct, isTelemarketing));
                }
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setAccount just added a contact-'+thisCtct.Name));
               if (!contactHandled && acct.SignificantContact__c != null && acct.SignificantContact__c == thisCtct.Id) {
                  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setAccount in the if statement-'+thisCtct.Name));
                  ctct = thisCtct;
                  setContactInfo();
               }
               //ctctOptions.add(new SelectOption(thisCtct.Id,thisCtct.Name));
            }
            if (defReferral.SourceContact__c == null && ctct != null) {
               defReferral.SourceContact__c = ctct.Id;
            }
            // remove from the view state
            acct.Contacts.clear();
            acct.Banker_Name_Ref__r = null;
            acct.Broker_Name_Ref__r = null;
            acct.AccountTeamMembers.clear();
         } // if (acct.Contacts
      } // if (!okay
      return okay;
   } // setAccount
   
  // update the fields on the Referral Account objects to match 'setAccount' method 
   public Boolean setReferralAccount(Referral_Account__c p_refAcct) {
      System.debug('Set Referral Account Running');
      Boolean okay = (p_refAcct != null);
      if (!okay) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A Referral Account record could not be found! Cannot proceed with Referrals'));
      } else {
         Referral_Account__c ref_acct = p_refAcct;
         Id accountId = ref_acct.Id;
          
         // set the Contacts
         prepareForContacts();
         refCtct = (!refContactHandled ? null : refCtct);
         if (refCtct != null) {
            addContact(new CtctWrapper(refCtct, isTelemarketing));
         }
         
         System.debug('setRefAccount Contacts='+ref_acct.Referral_Contacts__r.size());
         if (ref_acct.Referral_Contacts__r != null && !ref_acct.Referral_Contacts__r.isEmpty()) {
            for (Referral_Contact__c thisCtct : ref_acct.Referral_Contacts__r) {
                if (refCtct == null || (refCtct != null && refCtct.Id != thisCtct.Id)) {
                  addContact(new CtctWrapper(thisCtct, isTelemarketing));
                }
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setAccount just added a contact-'+thisCtct.Name));
               if (!refContactHandled ) {
                  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setAccount in the if statement-'+thisCtct.Name));
                  refCtct = thisCtct;
                  refContactId = refCtct.Id;

                  refContactHandled = true;
               }
               //ctctOptions.add(new SelectOption(thisCtct.Id,thisCtct.Name));
            }
            if (defReferral.Referral_Contact__c == null && refCtct != null) {
               defReferral.Referral_Contact__c = refCtct.Id;
            }
           
         } // if (ref_acct.Contacts
      } // if (!okay
      return okay;
   } // setReferralAccount
    
   public static PartnerReferral__c checkForExistingPartRefs(Id idToCheck) {
      System.debug('checkForExisting idToCheck='+idToCheck);
      PartnerReferral__c partRef = null;
      if (idToCheck != null) {
         Integer OLD_DAYS = Integer.valueOf(Label.ReferralController_PartRefCheck);
         Date checkDate = System.today().addDays(-OLD_DAYS);
         System.debug('checkForExisting checkDate='+checkDate);
         
         PartnerReferral__c[] existingOlds = [Select Id
                                                    ,Account__c
                                                    ,Campaign__c
                                                    ,Campaign__r.LeadSource__c
                                                    ,Contact__c
                                                    ,Lead__c
                                                    ,ProcessNotes__c
                                                    ,Referral__c
                                                    ,Referral__r.Id
                                                    ,Referral__r.Referral_Partner__c
                                                    ,CreatedDate
                                                    ,Master_Partner_Referral__c
                                                    ,Master_Partner_Referral__r.CreatedDate
                                                From PartnerReferral__c
                                               Where (Contact__c = :idToCheck
                                                       or Lead__c = :idToCheck)
                                                 and CreatedDate >= :checkDate
                                                 and Master_Partner_Referral__c = NULL
                                                 order by CreatedDate DESC
                                              ];
         partRef = !existingOlds.isEmpty() ? existingOlds[0] : null;
         System.debug('checkForExisting partRef='+partRef);
      } // if (idToCheck != null
      return partRef;
   } // checkForExistingPartRefs


   /** Initialize Contact containers. */
   public void prepareForContacts() {
      //ctctOptions = new List<SelectOption>();
      allCtctsMap.clear();
      allCtcts = new List<CtctWrapper>();
   } // prepareForContacts

   public static Integer MAX_CTCTS_TO_ADD=Integer.valueOf(Label.ReferralController_MaxCtcts);

   public void addContact(CtctWrapper p_ctct) {
      //ctctOptions.add(new SelectOption(p_ctct.recId, p_ctct.name));
      if (allCtcts.size() < MAX_CTCTS_TO_ADD) {
         allCtctsMap.put(p_ctct.recId,p_ctct);
         allCtcts.add(p_ctct);
      }
   } // addContact

   public void setCtctOptions() {
      ctctOptions = new List<SelectOption>();
      if (allCtcts != null) {
         for (CtctWrapper cw : allCtcts) {
            ctctOptions.add(new SelectOption(cw.recId, cw.name));
         }
      } // if (allCtcts != null
   } // setCtctOptions
   
   /** For easy access to the contacts. */
   private Map<Id,CtctWrapper> allCtctsMap = new Map<Id,CtctWrapper>();

   public List<CtctWrapper> allCtcts{get;set;}
   
   
   /** Does this have any contact options. */
   public Boolean hasCtctOptions {
      get {return (ctctOptions != null && !ctctOptions.isEmpty()); }
   } // hasCtctOptions
   
   /** Does this have only one contact option? This would mean the user would not have a choice. */
   public Boolean hasOnlyOneCtctOption {
      get {return (ctctOptions != null && ctctOptions.size() == 1); }
   } // hasOnlyOneCtctOption

   public List<SelectOption> ctctOptions{get;set;}
   
   // The account.
   public Account acct{get;private set;}
   
   //private Map<String,List<Zip_Assignment__c>> zipAssigns;
   
   //private Map<String,ZipWrapper> zipWrapperBySalesOrgMap = new Map<String,ZipWrapper>();

   // store the zip assignments for each zip code in a separate map for easy retrieval 
   private Map<String,Map<String,ZipWrapper[]>> zipsByZipCodeBySalesOrgMap = new Map<String,Map<String,ZipWrapper[]>>();
   
   public Boolean setZipAssign(Set<String> zipsToRetrieveSet,Set<String> overrideSegmentSet) {
      //zipAssigns = null;
      //zipWrapperBySalesOrgMap.clear();
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setZipAssign useZip='+useZip));
      //if (String.isNotBlank(useZip)) {
         
         // in case it's longer than 5 characters.
         //useZip = useZip.left(5);
         // which object is being passed in
         SObject recToCheck = (isReferringLead ? (SObject)primaryLead : (SObject)acct);
         Map<String,ZipWrapper[]> zipAssignmentMap = ZipCodeLookupController.getZipAssignmentMap(zipsToRetrieveSet, recToCheck, true, overrideSegmentSet);
         for (String zipCode : zipAssignmentMap.keySet()) {
            system.debug('setZipAssign zipCode: '+zipCode);
            Map<String,ZipWrapper[]> zipWrapperBySalesOrgMap = new Map<String,ZipWrapper[]>();
            for (ZipWrapper zipWrap : zipAssignmentMap.get(zipCode)) { 
                system.debug('setZipAssign each zipWrap zipWrap.za.Sales_Org__c: '+zipWrap.za.Sales_Org__c);
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setZipAssign zipWrap='+zipWrap));
               ZipWrapper[] zipList = zipWrapperBySalesOrgMap.get(zipWrap.za.Sales_Org__c);
               system.debug('setZipAssign zipList: '+zipList);
               if (zipList == null) {
                  zipList = new ZipWrapper[]{};
                  zipWrapperBySalesOrgMap.put(zipWrap.za.Sales_Org__c,zipList);
                  system.debug('setZipAssign added zipWrap.za.Sales_Org__c,zipList to zipWrapperBySalesOrgMap'); 
               }
               
               zipList.add(zipWrap);
               system.debug('setZipAssign added zipWrap to zipList'); 
               //zipWrapperBySalesOrgMap.put(zipWrap.za.Sales_Org__c, zipWrap);
            }
            zipsByZipCodeBySalesOrgMap.put(zipCode,zipWrapperBySalesOrgMap);
            system.debug('setZipAssign zipCode: '+zipCode+' zipWrapperBySalesOrgMap: '+zipWrapperBySalesOrgMap); 

         } // for (String zipCode
         //ZipWrapper[] zipWrappers = zipAssignmentMap.get(useZip);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setZipAssign zipAssignmentMap='+zipAssignmentMap));

         // should be just one record per sales org
         //if (zipWrappers != null) {
         //   for (ZipWrapper zipWrap : zipWrappers) {
         //      zipWrapperBySalesOrgMap.put(zipWrap.za.Sales_Org__c, zipWrap);
         //   }
         //} // if
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setZipAssign number returned='+zipWrapperBySalesOrgMap.size()));
         
         //currentZipCode = useZip;
      //} // if (useZip != null
      
      return (!zipAssignmentMap.isEmpty());
   } // setZipAssign
   
   /** Get the owner from the account record.
    */
   public static User getAcctOwner(String salesOrg, Account acct, Boolean checkAcctType) {
      User acctOwner = null;
      if (String.isNotBlank(salesOrg)) {
         String acctType = (acct != null && acct.RecordType != null && acct.RecordType.Name.equals(RecordTypeHelper.MMS_ACCOUNT) ? UserHelper.SO_MMS : UserHelper.SO_CORE);
         
         if (salesOrg == UserHelper.SO_CORE && (!checkAcctType || (checkAcctType && acctType.equals(UserHelper.SO_CORE)))) {
            acctOwner = acct.Owner;
         } else if (salesOrg == UserHelper.SO_MMS && (!checkAcctType || (checkAcctType && acctType.equals(UserHelper.SO_MMS)))) {
            acctOwner = acct.Owner;
         } else if (salesOrg == UserHelper.SO_401) {
            acctOwner = acct.HRS_Account_Owner__r;
         } else if (salesOrg == UserHelper.SO_PEO_ASO) {
            acctOwner = acct.Premier_PBS_Account_Owner__r;
         } else if (salesOrg == UserHelper.SO_HNB) {
            acctOwner = acct.HNBF_Account_Owner__r;
         }
         system.debug('AA jsh in getAcctOwner salesOrg'+salesOrg+' rt: '+acct.RecordType.Name);
         // check to see if we do not want to use the account owner in certain hold out situations
         if (acctOwner != null && (salesOrg == UserHelper.SO_CORE || salesOrg == UserHelper.SO_MMS)
             && acct.Hold_Out__c && String.isNotBlank(acct.Permanent_Hold_Out_Description__c)) {
               String hoDesc = 'Hold Out-'+acct.Permanent_Hold_Out_Description__c;                      // custom setting name limit of 35 chars
               PaychexSettings__c payxSetting = PaychexSettings__c.getInstance(hoDesc.Left(34));
            if (payxSetting != null && payxSetting.IsActive__c) {
                  acctOwner = null;
            }            
         } // if (acctOwner != null
         if(acctOwner != null && (salesOrg == UserHelper.SO_CORE || salesOrg == UserHelper.SO_MMS) 
               && acct.RecordType.Name != Label.RT_Core_Account && acct.RecordType.Name != Label.RT_MMS_Account){
                  system.debug('jsh in getAcctOwner setting null - RT Mismatch');
                  acctOwner = null;
         } 
           
         // only want to return users with a person id and are active
         if ((acctOwner != null) && (String.IsBlank(acctOwner.HR_Person_Id__c) || !acctOwner.IsActive)) {
            acctOwner = null;
         }
      } // if (za.Sales_Org__c != null
      return acctOwner;
   } // getAcctOwner
   
   
   public void changeRefPartnerDisplay() {
      useShortList = !useShortList;      
      setDisplayList();
   } // changeRefPartnerDisplay
   
   public void setDisplayList() {
      displayList = new List<ReferralWrapper>();   
         
      if (refTo != null) {
         if (!hasExtendedList || !useShortList) {
            displayList = refTo;       
         } else {
            for (ReferralWrapper rw : refTo) {
               if (rw.refPartner != null && !rw.refPartner.UseInExtendedList__c) {
                  displayList.add(rw);
               }
            } // for (ReferralWrapper rw            
         }
      } // if (refTo != null
   } // setDisplayList
   
   public Boolean useShortList{get;set;}
   
   // are there more referal partners not currently displayed?
   public Boolean hasMoreRefPartners {
      get {return (hasExtendedList && (displayList != null && refTo != null && displayList.size() != refTo.size())); }
   }
   
   public List<ReferralWrapper> displayList{get;set;}
   
   private List<ReferralWrapper> refTo = null;
      
   public Boolean hasExtendedList{get;set;}
   
   public void setReferralList() {
      useShortList = true;
      hasExtendedList = false;
      refTo = new List<ReferralWrapper>();

      Set<String> personIds = new Set<String>();

      for (Referral_Partner__c rp : refPartners) {
        //Look at referral partner's include + exclude for sales divisions fields.
        //for include, only have to match on the first word in the sales division field.  for exclude, need to match the full value of sales division.
        //if exclude matches, skip referral partner
        if(String.isNotBlank(runningUser.Sales_Division__c) && String.isNotBlank(rp.Include_for_Sales_Division__c)){
            String salesArea = runningUser.Sales_Division__c.substringBefore(' ');
            if(string.isNotBlank(salesArea) && (!rp.Include_for_Sales_Division__c.contains(salesArea) || 
                (rp.Include_for_Sales_Division__c.contains(salesArea) && string.isNotBlank(rp.Exclude_for_Sales_Division__c) && rp.Exclude_for_Sales_Division__c.contains(runningUser.Sales_Division__c)))){
                continue;
            }
        }
        // if a record is not found for the zip assigns, create one here. If true is returned, it is assumed the 
        // record was created in the checkZipAssigns method
        ZipWrapper zipWrap = null;
        String useZip = primaryZipCode;
        // if there's a referral zip code we'll use that unless the flag is set on the referral partner
        if (String.isNotBlank(referralZipCode) && !rp.UsePrimaryZip__c) {
           useZip = referralZipCode;
        }
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setReferralList rp='+rp.Name+' useZip='+useZip));
        
        Boolean zipWrapFound = false;
        System.debug('setReferralList useZip='+useZip);
        if (String.isNotBlank(useZip)) {
           Map<String,ZipWrapper[]> zipWrapperBySalesOrgMap = zipsByZipCodeBySalesOrgMap.get(useZip);
           System.debug('setReferralList zipsByZipCodeBySalesOrgMap keys='+(zipsByZipCodeBySalesOrgMap != null ? String.valueOf(zipsByZipCodeBySalesOrgMap.keySet()) : 'N/A'));
           if (zipWrapperBySalesOrgMap != null) {
              System.debug('setReferralList zipWrapperBySalesOrgMap='+(zipWrapperBySalesOrgMap != null ? zipWrapperBySalesOrgMap.size() : -1)+' rp.Sales_Org__c:'+rp.Sales_Org__c);
              ZipWrapper[] zipList = (String.isNotblank(rp.Sales_Org__c) && zipWrapperBySalesOrgMap.containsKey(rp.Sales_Org__c)? zipWrapperBySalesOrgMap.get(rp.Sales_Org__c) : null);
              System.debug('setReferralList zipList='+zipList);
              // if referral partner has a default zip may need to use that to get correct zip assignment           //CMF
              if  (zipList == null && String.isNotblank(rp.Sales_Org__c) && String.isNotBlank(rp.Default_Zip__c)) {
                  zipWrapperBySalesOrgMap = zipsByZipCodeBySalesOrgMap.get(rp.Default_Zip__c);
                  zipList = (zipWrapperBySalesOrgMap != null ? zipWrapperBySalesOrgMap.get(rp.Sales_Org__c) : null);
              }
              System.debug('setReferralList rp.Name='+rp.Name+' zipList='+(zipList != null ? zipList.size() : -1));
              if (zipList != null) {
                 zipWrapFound = true;
                 
                 //for (ZipWrapper v_zipWrap : zipList) {
                 //   if (addToList(rp,v_zipWrap,personIds) && !hasExtendedList) {
                 //      hasExtendedList = rp.UseInExtendedList__c;
                 //   }                    
                 //} // for (ZipWrapper v_zipWrap
                 Set<String> refpartAlreadySelected = new Set<String>();    
                 for (Integer idx = zipList.size()-1; idx >= 0; idx --)
                 {      if (addToList(rp,zipList.get(idx),personIds,refpartAlreadySelected) && !hasExtendedList) 
                        {       hasExtendedList = rp.UseInExtendedList__c;      }
                 } // for (Integer idx
              } // if (zipList != null
              //zipWrap = zipWrapperBySalesOrgMap.get(rp.Name);
           }
        } // if (String.isNotBlank

        if (!zipWrapFound) {
            if (addToList(rp,zipWrap,personIds,null) && !hasExtendedList) {
                hasExtendedList = rp.UseInExtendedList__c;
            }
        } // if (!zipWrapFound
        
        /*
         if (!checkZipAssigns(rp, personIds)) {             
            addToList(rp, null, null);
         }
         */
      } // for (Referral_Partner__c
     
      useShortList = hasExtendedList;
      // sort the list
      refTo.sort();
  
      fixPEODisplayNames();         //tweak PEO display names based on which PEO segments are returned from zipcode lookup
      
      setDisplayList();
      //displayList = refTo;

      // get the Contacts
      system.debug('setReferralList get the contacts personIds: '+personIds);
      if (!personIds.isEmpty()) {
         Map<String,Contact> ctctMap = getCtctMap('HR_Person_Id__c',personIds);
         for (ReferralWrapper uw : refTo) {
            system.debug('setReferralList uw.ref.HR_Person_Id__c: '+uw.ref.HR_Person_Id__c);
            if (uw.ref.HR_Person_Id__c != null) {
               Contact ctct = ctctMap.get(uw.ref.HR_Person_Id__c);
               system.debug('setReferralList ctct: '+ctct);
               if (ctct != null) {
                  uw.ref.Contact__c = ctct.Id;
                  uw.ref.Contact__r = ctct;
                }
            } // if (uw.ref.HR_Person_Id__c)
         } // for (ReferralWrapper
      } // if (!personIds.isEmpty
      
      // so if in for NSS - display the calendar
      changeReferTo();
      zipsByZipCodeBySalesOrgMap.clear();
   } // setReferralList

   private UserHelper userH = new UserHelper();
   
   // the minimum number of Employees needed to send PAS opty to RSR listed on MSS user record
   public static Integer RSR_MINIMUM = Integer.valueOf(Label.RSR_Employee_Minimum);
    
   public User asoPartner;
   /* If has a territory, and no rep assigned - open territory.
      As long as we can find a DSA or DSM, list the territory as open and say it will be assigned to the DSA.
    */
   public Boolean addToList(Referral_Partner__c rp, ZipWrapper zipWrap,Set<String> personIds,Set<String> refpartAlreadySelected) {
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'addToList partner='+rp.Name+' zipWrap='+zipWrap));
      Boolean addedToList = false;
      String checkPersonId = null;
      User checkUser = null;      
      
      User territoryUser = null;
      Contact territoryContact = null;
      
      ReferralWrapper rw = new ReferralWrapper();
      
      setReferralPartner(rw,rp);

      if (zipWrap != null && zipWrap.za.ZipTerritory__r != null) {
          system.debug('addToList zipWrap.za.ZipTerritory__r: '+zipWrap.za.ZipTerritory__r+' zipWrap.usr: '+zipWrap.usr);
         checkUser = zipWrap.usr; //zipWrap.za.ZipTerritory__r.TerritoryRep__r;
         // if there's no person associated with a territory (or the unassigned rep), it will be "open"
         if (checkUser != null && checkUser.IsActive) {
            // if the unassigned user treat it as if nobody was selected.
            if (checkUser.HR_Person_Id__c != null && UserHelper.UNASSIGNED_SET.contains(checkUser.HR_Person_Id__c)) {
               checkUser = null;
            } else {
               checkPersonId = checkUser.HR_Person_Id__c;
            }
            rw.ref.AssignedToDSA__c = zipWrap.usingDSA;
         } // if (checkUser != null
         
         rw.hasDSA = (zipWrap.assistant != null && zipWrap.assistant.usr != null && zipWrap.assistant.usr.IsActive);
         rw.hasDSM = (zipWrap.manager != null && zipWrap.manager.usr != null && zipWrap.manager.usr.IsActive);
         // set the segment name
         rw.ref.ZipSegment__c = (zipWrap.zipSeg != null ? zipWrap.zipSeg.Name : null);
         
         rw.ref.User__c = (checkUser != null ? checkUser.Id : null);
         System.debug('addToList rp='+rp.Name+' checkUser='+checkUser);
         if (zipWrap.hasTerritoryContact) {
            rw.referToContact = true;
            rw.referToRefContact = false;
            rw.referToUser = false;
         }
         rw.ref.Contact__c = zipWrap.za.ZipTerritory__r.TerritoryContact__c;
         System.debug('addToList rw.ref.Contact__c: '+rw.ref.Contact__c);
          
         // check for holdouts if account or contact
         if (isReferringAccount || isReferringContact) {
            String holdOutFieldName = ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_ACCOUNT, zipWrap.za.Sales_Org__c);
            if (holdOutFieldName != null) {
               if ((Boolean)acct.get(holdOutFieldName)) {
                  User acctOwner = getAcctOwner(zipWrap.za.Sales_Org__c,acct, true); 
                  if (acctOwner != null && (referralUser == null || referralUser.Id != acctOwner.Id)  //APR0129551 Added check to display all partners within same segment
                       && String.IsNotBlank(acctOwner.HR_Person_Id__c)) {
                     checkUser = acctOwner;
                     checkPersonId = acctOwner.HR_Person_Id__c;
                  } 
               }
            }
         } // if (isReferringAccount
         //janky fix for rsr partner - only stored on mms user record
         //if (isReferringLead && checkUser!=null){               // removed check if Lead, want to use RSR if lead or contact referred
         if (checkUser!=null) {
            if(zipWrap.zipSeg.sales_Org__c == 'MMS' && checkUser.ASO_Partner__c!=null){
                asoPartner = checkUser.ASO_Partner__r;              
            }
            if(zipWrap.zipSeg.sales_Org__c == 'PAS' && asoPartner !=null && nbrOfEmployees != null && nbrOfEmployees >= RSR_MINIMUM) {    // added check of Employee count CMF
                checkUser = asoPartner;
                checkPersonId = asoPartner.HR_Person_Id__c;               
            }
         }
      } // if (zipWrap != null
      
      
      // if there's a zip assignment, does the criteria of the zip match the primary object (lead or account)?
      Boolean zipMatches = zipWrap != null;
      // check if the assigned user is a virtual rep
      rw.setVirtualFlag(checkUser);
      
      // only proceed here if either the zip matches the criteria or there isn't a zip
      // don't show the referral user in the list, set some values for referral wrapper
      
       if (checkPersonId == null || (checkPersonId != null && (checkPersonId != referralUser.HR_Person_Id__c)) || rw.refPartner.Select_Self__c==true) {
           system.debug('rw.refPartner'+rw.refPartner);
           system.debug('rw.refPartner.Select_Self__c'+rw.refPartner.Select_Self__c+'referralUser.HR_Person_Id__c'+ referralUser.HR_Person_Id__c+'checkPersonId'+ checkPersonId );
         rw.ref.Referring_User__c = referralUser.Id;
         
         //if referral partner is the same as the running user and partner is self select, select the partner.
         if(checkPersonId == referralUser.HR_Person_Id__c && rw.refPartner.Select_Self__c==true){
                  rw.selected = true; 
                  refpartAlreadySelected.add(rp.name);  
         }
         if (zipWrap != null && zipWrap.za != null && defaultRefPartnerSet.contains(rp.name+'-'+zipWrap.za.Segment_Name__c))            
         {      rw.selected = true; 
                refpartAlreadySelected.add(rp.name);                                                    
         }                                                                                                                                      
         else                                                                                                                           
         {      if (refpartAlreadySelected!=null && !refpartAlreadySelected.contains(rp.Name))
                {       rw.selected = defaultRefPartnerSet.contains(rp.Name);   }
         }
    
         // if this is coming from a lead, will have to set this after the convert.
         rw.ref.Account__c = (acct != null ? acct.Id : null);
         //rw.ref.No_Referring_Opty_Needed__c = noRefOptyNeeded;  
         rw.ref.Referral_Contact__c = defReferral.Referral_Contact__c;  
         rw.ref.Referral_Contact__c = (referralContactId != null ? referralContactId : rw.ref.Referral_Contact__c);  
         // rw.ref.Referral_Source__c = noRefOptyNeeded ? 'Wholesaler' : 'Sales Rep';  
         rw.ref.Referral_Source__c = defReferral.Referral_Source__c;                                    
         rw.ref.Started_From__c = defReferral.Started_From__c;                                                  
         rw.ref.SellingLeadSource__c = defReferral.SellingLeadSource__c;
         rw.ref.ReferralNotes__c = defReferral.ReferralNotes__c;
         rw.ref.acd_name__c = defReferral.acd_name__c;
         
         rw.ref.SourceContact__c = defReferral.SourceContact__c;
         rw.ref.SourceLead__c = (primaryLead != null ? primaryLead.Id : null);
         
         
         
         
         //rw.zipWrapper = zipWrap;
         rw.setZipWrapperAttributes(zipWrap);
         
         if (zipWrap != null && zipWrap.za != null) {
            // append the segment name if it's not the default segment
            if (zipWrap.zipSeg != null && zipWrap.zipSeg.Name != ZipQueries.SEGMENT_DEFAULT) {
            //   rw.ref.Name += '-'+zipWrap.zipSeg.Name;
                
               rw.displayName += '-'+zipWrap.zipSeg.Name;
               
               
               //if (rw.displayName.Left(3) == rw.displayName.Right(3))     //CMFCMF
               //{  rw.displayName = zipWrap.zipSeg.Name;   }
                    
                              
               
            }
            rw.ref.HR_Person_Id__c = checkPersonId;
            if (checkUser != null) {
               rw.ref.User__c = checkUser.Id;
               rw.ref.User__r = checkUser;
            } // if (checkUser != null
            if (personIds != null && String.isNotBlank(checkPersonId)) {
               personIds.add(checkPersonId);
            }
         } // if (za != null)
                  
         refTo.add(rw);         
         addedToList = true;
      } // if (checkPersonId == null ||

      return addedToList;
   } // addToList

   /** Set the referral partner object on the referral object. Set the name of the referral object.
    */
   public void setReferralPartner(ReferralWrapper rw, Referral_Partner__c rp) {
                 
      rw.setReferralPartner(rp, productByRefPartnerMap.get(rp.Name), productDefaultMap.get(rp.Name), commProdMap.get(rp.Name));
      System.debug('setReferralPartner referral name='+rw.displayName);
      rw.lockTitle = true;
   } // setReferralPartner

   // store in a static variable so records are only retrieved once
   private static Map<Id,CtctUserWrap> foundctctByUserIdMap = new Map<Id,CtctUserWrap>();

   /** Get the contacts based on the user ids passed in. The keys to the map will be the user id for easy lookup later.
    */
   public Map<Id,CtctUserWrap> getCtctIdByUserIdMap(Set<Id> p_userIdSet) {
      //Map<Id,Id> ctctIdByUserIdMap = new Map<Id,Id>();
      Map<Id,CtctUserWrap> ctctByUserIdMap = new Map<Id,CtctUserWrap>();
      Set<Id> userIdSet = new Set<Id>();
      
      // make sure the record wasn't already retrieved
      if (p_userIdSet != null) {
         for (Id userId : p_userIdSet) {
            CtctUserWrap foundWrap = foundctctByUserIdMap.get(userId);
            if (foundWrap != null) {
               ctctByUserIdMap.put(userId, foundWrap);
            } else {
               userIdSet.add(userId);
            }
         } // for (Id userId
      } // if (p_userIdSet != null
      
      if (userIdSet != null && !userIdSet.isEmpty()) {
         // select the users to get the person ids
         Map<Id,User> userMapById = UserHelper.getUserMapById(userIdSet);
         // get the person ids
         Set<String> personIdSet = new Set<String>();
         
         for (User usr : userMapById.values()) {
            if (String.isNotBlank(usr.HR_Person_Id__c)) {
               personIdSet.add(usr.HR_Person_Id__c);
            }
         } // for (User usr
         
         Map<String,Contact> ctctMap = getCtctMap('HR_Person_Id__c',personIdSet);
         
         for (User usr : userMapById.values()) {
            if (String.isNotBlank(usr.HR_Person_Id__c)) {
               Contact ctct = ctctMap.get(usr.HR_Person_Id__c);
               if (ctct != null) {
                  //ctctIdByUserIdMap.put(usr.Id, ctct.Id);
                  CtctUserWrap cuw = new CtctUserWrap();
                  cuw.usr = usr;
                  cuw.ctct = ctct;
                  ctctByUserIdMap.put(usr.Id,cuw);
               }
            }
         } // for (User usr
         
      } // if (userIdSet != null
      
      //return ctctIdByUserIdMap;
      return ctctByUserIdMap;
   } // getCtctsByUserIdMap
   
   public class CtctUserWrap {
      public User usr;
      public Contact ctct;
   } // class CtctUserWrap
   
   /** Retrieve a map of the contacts based on the passed in parameters.
    */
   public Map<String,Contact> getCtctMap(String fieldName, Set<String> tokens) {
      Map<String,Contact> ctctMap = new Map<String,Contact>();
      if (!tokens.isEmpty()) {
         String whereClause = 'where Account.Name=\''+UserHelper.PAYCHEX_COMP+'\' and '+fieldName+' in ';
         whereClause += getInClause(tokens);

         Contact[] ctcts = new UserHelper().getContacts(whereClause);
         for (Contact ctct : ctcts) {
            ctctMap.put((String)ctct.get(fieldName),ctct);
         }
      } // if (!personIds.isEmpty
      return ctctMap;
   } // getCtctMap
   
   /** Retrieve a map of the referral Contacts - to get email and company information
    */
   public Map<Id,Referral_Contact__c> getRefCtctMap(Set<Id> refCtctIds) {
      Map<Id,Referral_Contact__c> ctctMap = new Map<Id,Referral_Contact__c>();
      if (!refCtctIds.isEmpty()) {
         ctctMap = new Map<Id,Referral_Contact__c>([Select Id
                                                 ,Email__c
                                                 ,Name
                                                 ,Referral_Account__c
                                                 ,Referral_Account__r.Name
                                             From Referral_Contact__c
                                            Where Id in :refCtctIds]);
      } // if (!refCtctIds.isEmpty
      
      return ctctMap;
   } // getRefCtctMap
   
   /** Create an in clause.
    */
   public String getInClause(Set<String> tokens) {
      String inClause = '(';
      for (String token : tokens) {
         if (inClause.length() > 1) {
            inClause += ',';
         }
         inClause += '\''+token+'\'';
      } // for
      inClause += ')';
      return inClause;
   } // getInClause
   
   /** Go to the previous step in the process.
    */
   public PageReference previousStep() {
      if (isStep2) {
         displayList = refTo;
         currentStep = STEP1;
      } // if (isStep2
      return null;
   } // previousStep
   
   /** Goto the next step in the process.
    */
   public PageReference nextStep() {
      if (currentStep != null) {
          System.debug('currentStep ----->>>>>> ' + currentStep);
         if (isStep1) {
            // APR0114125 - show error to the user if the Referral Source is not selected.
            Boolean allOkay = true;
            if(isTelemarketing && selectedReferralSourceOption == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'You must select Lead Source to continue!'));
                allOkay = false;           
            }
            
           if (allOkay && verifyContacts()) {    
              // move to step 2
               displayList = selectedRefs;
               if (isTelemarketing) {                  
                  if (verifyAndSaveReferrals()) {
                     // if successful, return to ... where you started from
                     currentStep = STEP3;
                  }
               } else {
                  currentStep = STEP2;
                  System.debug('currentStep ----->>>>>> ' + currentStep);

               } // if (isTelemarketing

            } // if (verifyContacts
         } else if (isStep2) {         
            System.debug('currentStep ----->>>>>> ' + currentStep);

             // make sure they picked some commission products
             if (!checkCommProducts())
             {   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You must select Commission Product(s) if available on each referral.'));   }
             else
             {   // create opps if necessary
                         // save referral objects                                                 
                         if (verifyAndSaveReferrals()) {
                     // if successful, return to ... where you started from
                       currentStep = STEP3;
                 } // if
             } // if (checkCommProducts)
         } else if (isStep3) {
            PageReference pr = new PageReference('/'+returnId);
             //PageReference pr = new PageReference('/apex/referralUpload');
            pr.setRedirect(true); 
            // run code to look for duplicate partner referral and referral records created before Lead convert finished
             if (((primaryLead != null && acct != null) || (ctct != null && acct != null)) && isTelemarketing) {
                 //System.debug('ReferralController.nextStep Step3 queueing up PartnerReferralSearch, acct='+acct.Id+' ctct='+(ctct.Id!=null?ctct.Id:'null')+' converted Lead='+(primaryLead!=null?primaryLead.Id:'null') +' isTelemarketing='+isTelemarketing);
                    PartnerReferralSearch prs;
                    if (primaryLead != null)
                    {  prs = new PartnerReferralSearch(acct.Id, (ctct!=null?ctct.Id:null), null,primaryLead.Id);  }  
                    else if (acct != null && ctct != null)
                    {  prs = new PartnerReferralSearch(acct.Id, ctct.Id, null, null);  }
                    PartnerReferralSearch.launchQueueable(prs);
            } // if (((primaryLead...)))  
            
            return pr;
         }
      } // if (currentStep != null
      return null;
   } // nextStep
  
   /** All done, Goto the referral opportunity 
    */
   public PageReference nextStepOpty() {          
          PageReference pr = new PageReference('/'+(returnRefOpty != null ? returnRefOpty : returnId));
            pr.setRedirect(true);             
            return pr;
   } // nextStepOpty
   
   /** The title for the Next button. */
   public String nextStepButtonTitle {
      get { 
         // default title
         String title='Next Step';
         if (isStep1 && isReferringRefContact) {
             title = 'Create Activity';
         } else if (isStep1 && isTelemarketing) {
               title = 'Create Opportunity';
         } else if (isStep2) {
               title = 'Submit Referral(s)';
         } else if (isStep3) {
             //title = 'Continue to attachment screen';
            title = 'Complete-Return to '+returnName;
            hideAttach();
         }
               
         return title;
      } // get
   } // nextStepButtonTitle
       
   /** The records selected. */
   public List<ReferralWrapper> selectedRefs{get;set;}
   
   /** Show the company name field on the verification page. */
   public Boolean showCompanyName{get;private set;}
   
   public static final Integer NOTES_SIZE = Referral__c.Notes__c.getDescribe().getLength();
   
   // Verify that the contact information is filled out - either the Contact or Referral_Contact__c data.
   public Boolean verifyContacts() {
      Boolean allOkay = true;
      showCompanyName = false;
            
      // there should be at least one contact selected.
      Boolean atLeastOneSelected = false;
      // the records that were selected and valid 
      selectedRefs = new List<ReferralWrapper>();
      // the contact ids to use to re-select the Contacts
      Set<String> contactIds = new Set<String>();
      // the referral contact ids to re-select the Referral Contacts
      Set<Id> refCtctIds = new Set<Id>();
      
      // used to check for duplicates
      Set<Id> dupCheckSet = new Set<Id>();
      // to reselect the users
      Set<Id> userIdSet = new Set<Id>();
      
      // the size of the notes field - subtract 50 from field length just in case - especially for sandbox testing
      Integer noteFieldSize = NOTES_SIZE-50;
      
      if (refTo == null) {
         return false;
      }
      
      // needs to be at least one partner type selected.
      for (ReferralWrapper rw : refTo) {
         if (rw.selected) {
            atLeastOneSelected = true;
            
            // verify title and Contact are populated
            //if (!rw.lockTitle && rw.ref.Name == null) {
            if (!rw.lockTitle && String.isBlank(rw.displayName)) {
               //rw.ref.Name.addError('You have selected a record but not selected a Referral Partner!');
               rw.ref.addError('You have selected a record but not selected a Referral Partner!');
               allOkay = false;
            }
            if (rw.isOpenTerritory) {
               selectedRefs.add(rw);
               // do nothing - this is okay
            } else if (isTelemarketing && rw.isUnknownTerritory) {
               selectedRefs.add(rw);
               // do nothing - this is okay
            } else if (rw.referToContact && rw.ref.Contact__c == null) {
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'You have selected '+uw.ref.Name+' but have not supplied a Contact!'));
               //rw.ref.Contact__c.addError('You have selected '+rw.ref.Name+' but have not supplied a Paychex Contact!');
               rw.ref.Contact__c.addError('You have selected '+rw.displayName+' but have not supplied a Paychex Contact!');
               allOkay = false;
            } else if (rw.referToContact && rw.ref.Contact__c != null) {
               // assume Contact is selected
               selectedRefs.add(rw);
               contactIds.add(rw.ref.Contact__c);
               // check for a duplicate
               if (dupCheckSet.contains(rw.ref.Contact__c)) {
                  rw.ref.Contact__c.addError('This Contact has been selected more than once!');
                  allOkay = false;
               } else {
                  dupCheckSet.add(rw.ref.Contact__c);
               }
            } else if (rw.referToRefContact && rw.ref.Referral_Contact__c == null) {
               //rw.ref.Referral_Contact__c.addError('You have selected '+rw.ref.Name+' but have not supplied a Referral Contact!');
               rw.ref.Referral_Contact__c.addError('You have selected '+rw.displayName+' but have not supplied a Referral Contact!');
               allOkay = false;
            } else if (rw.referToRefContact && rw.ref.Referral_Contact__c != null) {
               selectedRefs.add(rw);
               // check for email address
               refCtctIds.add(rw.ref.Referral_Contact__c);
               // check for a duplicate
               if (dupCheckSet.contains(rw.ref.Referral_Contact__c)) {
                  rw.ref.Referral_Contact__c.addError('This Contact has been selected more than once!');
                  allOkay = false;
               } else {
                  dupCheckSet.add(rw.ref.Referral_Contact__c);
               }
            } else if (rw.referToUser && rw.ref.User__c == null) {
               //rw.ref.User__c.addError('You have selected '+rw.ref.Name+' but have not supplied a User!');
               rw.ref.User__c.addError('You have selected '+rw.displayName+' but have not supplied a User!');
               allOkay = false;
            } else if (rw.referToUser && rw.ref.User__c != null) {
               selectedRefs.add(rw);
               // check for email address
               userIdSet.add(rw.ref.User__c);
               // check for a duplicate
               if (dupCheckSet.contains(rw.ref.User__c)) {
                  rw.ref.User__c.addError('This User has been selected more than once!');
                  allOkay = false;
               } else {
                  dupCheckSet.add(rw.ref.User__c);
               }
            } else if(rw.referToQueue && rw.hasQueueName){
                rw.ownerIsQueue = true;
                selectedRefs.add(rw);
            }
            
            //APR0121163
           /* if(selectedTransferReason == null && isReasonRequired && !Test.isRunningTest()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Please Select a Transfer Reason'));
                allOkay = false;
            }*/
            
            // verify the size of the notes field - subtract 100 from field length just in case - especially for sandbox testing
            if (String.isNotBlank(rw.ref.Notes__c) && rw.ref.Notes__c.length() > noteFieldSize) {
               //rw.ref.Notes__c.addError('For '+rw.ref.Name+', you have entered more than the maximum number of characters allowed ('+rw.ref.Notes__c.length()+' of '+noteFieldSize+' allowed characters)!');
               rw.ref.Notes__c.addError('For '+rw.displayName+', you have entered more than the maximum number of characters allowed ('+rw.ref.Notes__c.length()+' of '+noteFieldSize+' allowed characters)!');
               allOkay = false;
            }
         } // if (uw.selected
 
      } // for (ReferralWrapper uw
        
      if (!atLeastOneSelected) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'You must select at least one Partner to continue!'));
         allOkay = false;
      }
      //Upon any Sales User submitting an Internal Referral then the Lead Source field on the Internal Referral form is required
      if (partnerType == REF_INTERNAL && referringOpp != null && referringOpp.LeadSource == null && !Test.isRunningTest()){
          ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Must populate Lead Source'));
          //referringOpp.LeadSource.addError('Must populate Lead Source');
          allOkay = false;
       }      
       if(referringOpp != null && referringOpp.LeadSource == 'Referral-Bank Referral' && referringOpp.Level_2__c == null){
           referringOpp.Level_2__c.addError('The Level 2 field is required if the Lead Source equals Referral-Bank Referral.');
           allOkay = false;
       }
       
      // verify date is correct
      if (creatingEvent && !defReferral.CreateSellerTask__c) {
         allOkay = checkActivityDate();
      } // if (creatingEvent &&
      
      if (allOkay) {
         Set<String> personIds = new Set<String>();
         // reselect contacts to get person id if User isn't already attached or User is different.
         Map<String,Contact> ctctMap = getCtctMap('Id',contactIds);
         Map<Id,Referral_Contact__c> refCtctMap = getRefCtctMap(refCtctIds);
         //Map<Id,Id> ctctIdByUserIdMap = getCtctIdByUserIdMap(userIdSet);
         Map<Id,CtctUserWrap> ctctByUserIdMap = getCtctIdByUserIdMap(userIdSet);
         
         for (ReferralWrapper rw : selectedRefs) {

            // if a DSA exists in the zip wrapper, use that
            /*
            if (rw.zipWrapper != null) {
               if (rw.zipWrapper.assistant != null && rw.zipWrapper.assistant.usr != null) {
                  rw.ref.DSA__c = rw.zipWrapper.assistant.usr.Id;
               }
                     
               if (rw.zipWrapper.manager != null && rw.zipWrapper.manager.usr != null) {
                  rw.ref.DSM__c = rw.zipWrapper.manager.usr.Id;
               }
            } // if (rw.zipWrapper != null
            */
            if (rw.referToContact && rw.ref.Contact__c != null) {
               // get the contact from the list selected
               rw.ref.Contact__r = ctctMap.get(rw.ref.Contact__c);
               // see if it's the same person id
               if (rw.ref.Contact__r != null && rw.ref.Contact__r.HR_Person_Id__c != null && (rw.ref.User__r == null || (rw.ref.User__r != null && rw.ref.Contact__r.HR_Person_Id__c != rw.ref.User__r.HR_Person_Id__c))) {
                  // clear out the user info and we will reselect it
                  rw.ref.User__c = null;
                  rw.ref.User__r = null;
              
                  personIds.add(rw.ref.Contact__r.HR_Person_Id__c);
               } // if (rw.ref.Contact__r.Contact__r != null
            } else if (rw.referToRefContact && rw.ref.Referral_Contact__c != null) {
               rw.refCtct = refCtctMap.get(rw.ref.Referral_Contact__c);
               if (rw.refCtct != null) {
                  if (rw.refCtct.Email__c == null) {
                     rw.ref.Referral_Contact__c.addError('This Referral Contact does not have an Email Address!');
                     allOkay = false;
                  }
                  if (rw.refCtct.Referral_Account__r != null) {
                    showCompanyName = true;
                  }
               } // if (rc != null
            } else if (rw.referToUser && rw.ref.User__c != null) {
               CtctUserWrap cuw = ctctByUserIdMap.get(rw.ref.User__c);
               if (cuw != null) {
                  rw.ref.Contact__c = cuw.ctct.Id;
                  rw.setVirtualFlag(cuw.usr);
                  if (rw.ref.DSA__c == null || rw.ref.DSM__c == null) {
                     rw.ref.DSA__c = (rw.ref.DSA__c == null ? cuw.usr.DSA_FSS__c : rw.ref.DSA__c);
                     rw.ref.DSM__c = (rw.ref.DSM__c == null ? cuw.usr.ManagerId : rw.ref.DSM__c);
                  }
               }
            }
         } // for
         
         if (personIds != null && !personIds.isEmpty()) {
            // retrieve sales user records 
            User[] users = [Select Id, Name
                                 ,DSA_FSS__c
                                 ,HR_Person_Id__c
                                 ,HR_Services_Partner__c
                                 ,ManagerId
                                 ,Non_Paychex_Employee__c
                                 ,NSS_Team__c
                                 ,Sales_Org__c
                                 ,Sales_Division__c
                                 ,Profile.Name
                                 ,UserRole.ParentRoleId
                                 ,Title
                             from User 
                            where HR_Person_Id__c in :personIds
                              and IsActive = true
                              and Sales_Org__c in :UserHelper.DIVISION_LIST ];
            // put users into a map
            Map<String,User> userMap = new Map<String,User>(); 
            for (User u : users) {
               userMap.put(u.HR_Person_Id__c,u);
            }
            if (!userMap.isEmpty()) {
               // try to match the user to the contact records
               for (ReferralWrapper rw : selectedRefs) {
                  if (rw.ref.Contact__r != null && rw.ref.User__c == null) {
                     User u = userMap.get(rw.ref.Contact__r.HR_Person_Id__c);
                     if (u != null) {
                        rw.refUserIsVirtual = false;
                        rw.ref.User__c = u.Id;
                        rw.ref.User__r = u;
                        rw.setVirtualFlag(u);
                        if (rw.ref.DSA__c == null) {
                           rw.ref.DSA__c = u.DSA_FSS__c;
                        }
                        if (rw.ref.DSM__c == null) {
                           rw.ref.DSM__c = u.ManagerId;
                        }
                     } // if (u != null
                  } // if (rw.ref.Contact__r != null
                  
               } // for (ReferralWrapper rw
            } // if (!userMap.isEmpty
         } // if (!personIds.isEmpty())
         
      } // if (allOkay
      
      return allOkay;
   } // verifyContacts
   
   // verify that the activity date entered is valid
   public Boolean checkActivityDate() {
      Boolean allOkay = true;
      if (defReferral.ActivityDate__c >= Date.today() && defReferral.ActivityDate__c <= Date.today().addMonths(12)) {
         defReferral.ActivityDateTime__c = DateTime.valueOf(defReferral.ActivityDate__c.year()+'-'+
                                                defReferral.ActivityDate__c.month()+'-'+
                                                defReferral.ActivityDate__c.day()+' '+
                                                selectedTime);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'verifyContacts original time='+defReferral.ActivityDateTime__c.format()));
         // get the offset from the running user's time zone to the destination time zone
         DateTime testTime = DateTime.now();
         Integer hourMyTimeZone = testTime.hour();
         Integer hourDestTimeZone = Integer.valueOf(testTime.format('HH',defReferral.TimeZoneName__c));
         Integer timeDifference = hourMyTimeZone - hourDestTimeZone;
         defReferral.TimeZoneOffset__c = hourMyTimeZone - hourDestTimeZone;
         // add the hour difference so the time for the prospect/client meeting is correct
         defReferral.ActivityDateTime__c = defReferral.ActivityDateTime__c.addHours(defReferral.TimeZoneOffset__c.intValue());
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'verifyContacts selectedTime='+selectedTime+' timeDifference='+timeDifference+' defReferral.ActivityDateTime__c='+defReferral.ActivityDateTime__c.format()));
      } else {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'The date you have chosen, '+defReferral.ActivityDate__c.format()+', is not valid for an appointment. Please select a date on or after '+Date.today().format()+' and before '+Date.today().addMonths(12).format()+' to continue.'));
         allOkay = false;
      }
      return allOkay;
   } // checkActivityDate

   /** Verify that referrals are okay to save
    */
   public Boolean verifyAndSaveReferrals() {
      System.debug('verifyAndSaveReferrals, ct on Referral:'+defReferral.Cadence_Touchpoint__c);
      partReferralNeedsUpdate = false;
      ErrorLog__c procLog = ErrorLog.getProcessLog(CLASSNAME);
      procLog.ObjectId__c = refObjectId;
      
      defReferral.SubmitFormStart__c = DateTime.now();
      // Create a savepoint in case we need to rollback the data
      // Savepoint sp = Database.setSavepoint();                //CMF we need to catch an error

      Boolean allOkay = true;

      // if this is coming from a lead - convert the lead(s)
      if (primaryLead != null) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Has a primary lead - heading over to convertLead'));
         allOkay = convertLead();
      }
      if (!allOkay) {
         return allOkay;
      }  // dont continue if Lead convert failed!
      
      // check if campaign was changed      CMFCMF
      verifyAndSaveCampaign();
       
      // create referring opportunities
      allOkay = saveOpportunities();

      // save referral object(s)
      System.debug('verifyAndSaveReferrals allOkay='+allOkay);
      if (allOkay) {
         allOkay = saveReferrals();
      }
      
      if (!allOkay) {
         // rollback all of the changes
         // Database.rollback(sp);                              // CMF we need to catch an error
      } // if (allOkay 
      ErrorLog.saveLog(procLog);
    return allOkay;
   } // verifyAndSaveReferrals
   
   /** The product mapping for referrals. */
   public static String REF_PROD_MAPPING='Oppty-Referral';

   /** Fields added to Opp for NSS */
    public boolean dm {get; set;}
    public boolean multipleLocs {get;set;}
   
   /** Create and save the Referring Opportunity
    */
   public Boolean saveOpportunities() {
       System.debug('In Save Opportunity Method----------------->>>>>>');
             
       Boolean okay = true;
       
      if (referringOpp != null) {
        CreateOppAndMeeting coam = new CreateOppAndMeeting(salesOrg);
        // set default values
        referringOpp.CloseDate = coam.getCloseDate();
        // the first stage on all referral opportunities
        referringOpp.StageName = 'Referred';
        system.debug('referralUser.Id :'  + referralUser.Id);  
        referringOpp.OwnerId = referralUser.Id;
          if(isTelemarketing){  
              referringOpp.DM__c = (dm!=NULL?dm:FALSE);
              referringOpp.Potential_for_Multiple_Locations__c = (multipleLocs!=NULL?multipleLocs:FALSE);
          }

        //String refFrom = getReferralFrom(salesOrg);
        
        // records to upsert - update the existing opportunity
        // add the default here. If we decide on more than one referring opp will have to change this.
         Opportunity[] opps = new Opportunity[]{};
         // the mapping of partner types
         Set<String> partnerTypeSet = new Set<String>();
         
         // keep track of the ones we are creating opportunities for so we can match up the results after
         //ReferralWrapper[] saveRws = new ReferralWrapper[]{};
         
         // The description from the opportunity entered on the main screen
         String description = referringOpp.Description != null ? referringOpp.Description + '\n' : '';
         System.debug(' The selected Referrals: '+selectedRefs);
         for (ReferralWrapper rw : selectedRefs) {
            if (rw.refPartner.CreateRefOpp__c) {
                Opportunity productSpecificOpp = referringOpp.clone(false,false,false,false);
                //productSpecificOpp.Name = acct.Name+'-'+rw.displayName+' Referral';
                productSpecificOpp.Name = CreateOppAndMeeting.getOppName(acct.Name,rw.displayName+' Referral',CreateOppAndMeeting.OPP_NAME_SIZE );
                productSpecificOpp.Cadence_Touchpoint__c = referringOpp.Cadence_Touchpoint__c;
                rw.oppReferring = productSpecificOpp;
                opps.add(productSpecificOpp);
                system.debug('ReferralController saveOpportunities productSpecificOpp:'+productSpecificOpp);
               // add the partner type to find the product for the line item
               partnerTypeSet.add(rw.refPartner.Name);
            } // if (rw.refPartner.CreateRefOpp__c
            
         } // for (ReferralWrapper rw
          List<Database.SaveResult> uResults;
         // only need to continue if there is at least one referring opp
         if (opps.size()>0) {
            // save the referring Opportunities 
            try {
                system.debug(' opps : ' + opps);
              uResults = Database.insert(opps,true);  // false);
                system.debug(' uResults : ' + uResults);
            }
             catch (Exception e) {       
                 okay = false;          
                 ErrorLog.logError('ReferralController','saveOpportunities','saveOpportunities',null,e,referringOpp,true);
             }
            if (uResults != null) {
               ErrorLog__c errLog = null;
               
               // check the results               
               for (Integer cnt=0; cnt < uResults.size(); cnt++) {
                  Database.SaveResult result = uResults.get(cnt);
                  if (!result.isSuccess()) {
                     if (errLog == null) {
                        errLog = ErrorLog.logError('ReferralController','saveOpportunities','saveOpportunities2', null, (Exception)null, null, false);
                     }
                     okay = false;
                     if (uResults.size() == 1) {
                        // if only 1 referring op, let's retry.
                        ErrorLog.saveErrorLog(errLog);
                        if (DmlHelperRetry.canWeRetry(errLog)) {
                           Opportunity[] oppsToRetry = new Opportunity[]{opps[cnt]};
                           
                           DmlHelperRetry dhr = new DmlHelperRetry(errLog, oppsToRetry);
                           dhr.processRetry(System.isFuture() && ReferralMethods.ALLOW_SLEEP_FOR_RETRY);
                           if (DmlHelper.performDmlResult != null 
                                       && DmlHelper.performDmlResult.saveResults != null
                                       && !DmlHelper.performDmlResult.saveResults.isEmpty()) {
                              // pull out the result from the retry attempt
                              result = DmlHelper.performDmlResult.saveResults[0];
                           } 
                        }
                     } // if (uResults.size() == 1
                  } // if (!result.isSuccess
                  String msg = ReferralMethods.getSaveMsg('Referring Opportunity', result.isSuccess(), false, result.getErrors(),'ReferralController','saveOpportunities','upserting refs',returnId,errLog);
               } // for (Integer cnt=0
            } // if (uResults != null
            // only continue if no previous save errors.
            if (okay) {
               // the Opportunity Products,team members,contact roles we are creating
               OpportunityLineItem[] olis = new OpportunityLineItem[]{};
               OpportunityTeamMember[] otms = new OpportunityTeamMember[]{};
               OpportunityContactRole[] ocrs = new OpportunityContactRole[]{};
               // get the product mapping to create the line items
               Product_Mapping__c[] prodMappings = null;
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'partnerTypeSet='+partnerTypeSet));

               // make sure there are partner types retrieved
               if (!partnerTypeSet.isEmpty()) {
                  // get the sales product mapping based on the sales org of the current user
                  String[] salesOrgs = new String[]{salesOrg};
                  // have to convert the set to a list for the getMappings method
                  String[] mappingKeys = new String[]{};
                  mappingKeys.addAll(partnerTypeSet);
                  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'salesOrgs='+salesOrgs+' mappingKeys='+mappingKeys));
                  System.debug('saveOpportunities salesOrgs='+salesOrgs+' mappingKeys='+mappingKeys);
                  prodMappings = ProductMapping.getMappings(mappingKeys, REF_PROD_MAPPING, salesOrgs);
               } // if (!partnerTypeSet.isEmpty

               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'prodMappings='+prodMappings));

               // keep track if the opportunity is updated
               Map<Id,Opportunity> updatedReferringOpps = new Map<Id,Opportunity>();
               ///////////////////JSH CHANGE THIS?
               set<id> cadeTuchopint = new set<id>(); 

               for (ReferralWrapper rw : selectedRefs) {
                  // if the referring opportunity is present and has an id, create a line item 
                  if (rw.oppReferring != null && rw.oppReferring.Id != null) {
                         System.debug('ReferralController.saveOpportunities,rw.oppReferring.Id='+rw.oppReferring.Id);                      
                         // save referring oppid for return button
                         returnRefOpty = rw.oppReferring.Id;
                         returnRefOptyName = rw.oppReferring.Name;
                     // set the opportunity id on the referral object
                     rw.ref.Referring_Opportunity__c = rw.oppReferring.Id;             
                     // make sure referral has referral contact filled in, in case user filled it in on screen    CMF 
                     rw.ref.Referral_Contact__c = rw.oppReferring.Referral_Contact__c;   
                     
                     coam.setDefaults(rw.ref.User__r.Sales_Org__c);
                     if(rw.oppReferring.Cadence_Touchpoint__c != null){
                        cadeTuchopint.add(rw.oppReferring.Cadence_Touchpoint__c);
                     }   
                     if (createLineItem(rw,prodMappings,olis,coam.getCloseDate())) {
                       updatedReferringOpps.put(rw.oppReferring.Id,rw.oppReferring);                        
                     }
                     
                     if (rw.ref.User__c != null && rw.oppReferring != null && rw.oppReferring.Id != null) {
                        OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId=rw.oppReferring.Id,UserId=rw.ref.User__c,TeamMemberRole='Internal Referral');
                        otms.add(otm);                         
                     } // if (rw.ref.User__c
                     if(defReferral.SourceContact__c!=null && rw.oppReferring != null && rw.oppReferring.Id != null){
                        OpportunityContactRole ocr = ReferralMethods.createOppContact(rw.oppReferring.Id, defReferral.SourceContact__c);
                        if (ocr != null) {
                           ocrs.add(ocr);
                        }
                     }

                  }
               } // for (ReferralWrapper


                     // updating opp field campaign US 4
                  Map<ID, Cadence_Touchpoint__c> mapCdance = new Map<ID, Cadence_Touchpoint__c>([Select Id, Cadence__r.OngoingCadence__c, Cadence__r.Sales_Campaign_Name__c, CarRecord__r.Sales_Program__c From Cadence_Touchpoint__c where id in:cadeTuchopint]);
                  for(Opportunity oppRec: updatedReferringOpps.values()){
                     if(oppRec.Cadence_Touchpoint__c != null){
                        Cadence_Touchpoint__c  cad = mapCdance.get(oppRec.Cadence_Touchpoint__c);
                        String salesProgram = (cad.Cadence__r.OngoingCadence__c ? cad.Cadence__r.Sales_Campaign_Name__c : cad.CarRecord__r.Sales_Program__c);
                        if ( String.isNotBlank(salesProgram)) {
                           oppRec.Field_Campaign__c=salesProgram;    
                           updatedReferringOpps.put(oppRec.id , oppRec);
                         }
                         system.debug('var 2'); 
                     }
                  }                        
               if (!updatedReferringOpps.isEmpty()) {
                  update updatedReferringOpps.values();                   
               }
               // save the opportunity contacts
               if (!ocrs.isEmpty()) {                
                  List<Database.SaveResult> results = Database.insert(ocrs,false);
               }
               // save the line items
               if (!olis.isEmpty()) {                  
                  List<Database.SaveResult> results = Database.insert(olis,false);
               } // if (olis.isEmpty

               if (!otms.isEmpty()) {                
                   List<Database.SaveResult> results = Database.insert(otms,false);
               }
                
            } // if (okay)

         } // if (atLeastOneReferringOpp
         
      } // if (opp != null
      return okay;
   } // saveOpportunities
   
   // Create a line item for each referral created assuming the mapping exists.
   public Boolean createLineItem(ReferralWrapper rw, Product_Mapping__c[] prodMappings, OpportunityLineItem[] olis, Date closeDate) {
    Boolean oppUpdated = false;
    // make sure there is a referring opportunity and the prodMappings has data. If either of those conditions
    // are not met no need to continue.
    //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'createLineItem type='+rw.refPartner.Name));
    system.debug('ReferralController createLineItem prodMappings.size()'+prodMappings.size());
    if (rw.ref.Referring_Opportunity__c != null && prodMappings != null && !prodMappings.isEmpty()) {
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'createLineItem met criteria for type='+rw.refPartner.Name));
       // try to find a matching product mapping
       Product_Mapping__c pm = null;
       for (Product_Mapping__c checkPm : prodMappings) {
        if (checkPm.Mapping_Key__c == rw.refPartner.Name) {
           pm = checkPm;
           break;
        } // if
       } // for (Product_Mapping__c checkPm

         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'createLineItem type='+rw.refPartner.Name+' pm='+pm));
       
       // if no mapping is found can't create a line item - display the status to the user
       // we should expect every product to be mapped if an opportunity is to be created
        system.debug('ReferralController createLineItem pm'+pm);
       if (pm != null && pm.PricebookEntryId__c != null) {
            rw.oli = new OpportunityLineItem(OpportunityId=rw.ref.Referring_Opportunity__c);
            rw.oli.PricebookEntryId = pm.PricebookEntryId__c;
            rw.oli.Status__c = 'Pending';
            // 
            if (rw.refPartner.Selling_Opp_RecordTypeId__c != null && rw.ref.User__c != null) {
               rw.oli.Status__c = 'Pending Approval';
            }
            rw.oli.Quantity=1;
            rw.oli.TotalPrice=0;
            rw.oli.ServiceDate = closeDate;
            // we do want the individual line items to follow the opportunity
            rw.oli.User_Override__c = false;
            // add to list to save later.
            olis.add(rw.oli);
            /*if(pm.Product__c!=null && pm.Product__r.Opportunity_Checkbox__c!=null){
              rw.oppReferring.put(pm.Product__r.Opportunity_Checkbox__c,true);
                oppUpdated = true;
            }*/
            if(pm.Product__c!=null && String.isNotBlank(pm.Product__r.Name) && pm.Product__r.Name.startsWith('Referral-')){
                rw.oppReferring.Referral_Product__c = pm.Product__r.Name.substringAfter('Referral-');
                oppUpdated = true;
            }
            if (rw.oli.ServiceDate > referringOpp.CloseDate) {
              rw.oppReferring.CloseDate = rw.oli.ServiceDate;
                oppUpdated = true;
            }
       } else {
          String msg = 'Opportunity Product not created for '+salesOrg+' and '+ rw.refPartner.Name+'! A product mapping could not be found.';      
          rw.addToReferralNotes(msg);
       } // if (pm != null
       
    } // if (rw.ref.Referring_Opportunity__c != null
    return oppUpdated;
   } // createLineItem


   public String getAdditionalReferralPartners() {
      String additionalReferrals = null;
      String products = (primaryLead != null ? primaryLead.Products__c : (ctct != null ? ctct.Products__c : null));
      if (String.isNotBlank(products)) {
      
      }
      return additionalReferrals;
   } // getAdditionalReferralPartners
   
   public static Integer REF_NAME_SIZE=Referral__c.Name.getDescribe().getLength();

   /** The name of the setting value to get the queue name for unassigned records. */
   public static final String NSS_UNASSIGNED='Unassigned Referral Queue Name';

    //APR0121163     
/*   public List<SelectOption> getTransferReasons() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','-None-'));
        List<Schema.PicklistEntry> fieldValues = Transfer_Tracking__c.Reason__c.getDescribe().getPicklistValues();
        for(Schema.PicklistEntry fv:fieldValues){
            options.add(new SelectOption(fv.getValue(),fv.getValue()));
        }
        return options;
    }
   public static String selectedTransferReason{get;set;}
 */  
   public static String PART_REF_SOURCE_NAME='ReferralController';

   //update ctct.LatestCampaign if campaign was changed on the form     CMFCMF
   public void verifyAndSaveCampaign() {
        System.debug('ReferralController.verifyAndSaveCampaign defRef.cmpgn='+(defReferral != null ? defReferral.Campaign__c : null)+' ctct.LatestCmpgn='+(ctct != null ? ctct.LatestCampaign__c : null));
        if (ctct != null && defReferral != null && ctct.LatestCampaign__c != defReferral.Campaign__c && defReferral.Campaign__c != null)
        {   Ctct.LatestCampaign__c = defReferral.Campaign__c;   
         
            Map<Id, Id> campCtctMap = new Map<Id, Id>();
            campCtctMap.put(ctct.Id, ctct.LatestCampaign__c);
            CampaignMethods.createCampMemberFromRefCntlr(campCtctMap);        
            System.debug('ReferralController.verifyAndSaveCampaign just called createCampMemberFromRefCntlr='+campCtctMap);
          
            ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = false;
            ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = false;
            TriggerMethods.triggerExecutedSet.remove('CampaignMethodsContactBefore');
            TriggerMethods.triggerExecutedSet.remove('CampaignMethodsContactAfter');
            Database.update(ctct);
        } 
        
   } // verifyAndSaveCampaign
      
   public void checkForOtherSellingOpp() {
      //APR0159925
      List<String> excludeOppTypes = Label.Exclude_Opportunty_Types.split(',');
      Date lookBackSalesDate = System.Today() - (Integer.ValueOf(System.Label.Lookback_Sales_Cycle_End_Date));        
      List<Opportunity> opplist=[select id,ownerId,OpportunityType__c,StageName,IsClosed,IsWon,Sales_Cycle_End_Date__c,createdDate
                                        ,Probability,LastModifiedDate 
                                   from Opportunity where AccountId =:acct.Id AND ownerId=:runningUser.Id
                                    AND OpportunityType__c NOT IN: excludeOppTypes 
                                    AND (IsClosed= false  
                                         OR (IsClosed=true AND Sales_Cycle_End_Date__c!= null AND  Sales_Cycle_End_Date__c >= :lookBackSalesDate))
                                        ORDER By IsClosed ASC, Probability DESC,CreatedDate DESC Limit 10];
            
      // first row returned should be the most relevant      
      if (!opplist.isEmpty()) {
         defReferral.Referring_Employee_Selling_Opportunity__c = opplist[0].Id;
      }
//             List<Opportunity> oppClosedLst = new List<Opportunity>();
//             Id oppId;
//             
//             //list is sorted by created Date and probability
//             for(Opportunity op:opplist){
//                 //look for open opp in first 100 records
//                     if(!op.Isclosed){
//                         oppId = op.Id;
//                         break;
//                     }  else{
//                         oppClosedLst.add(op);
//                     }           
//                 }
//                         
//             //first 100 records are closed
//             if(oppId == Null && oppClosedLst.size() != 0){
//                 oppId = oppClosedLst.get(0).Id;
//            }
//             
//             if(oppId != Null){
//                 for(Referral__c ref:insertRefs){
//                     ref.Referring_Employee_Selling_Opportunity__c = oppId;
//                 }
//             }
//             
             // END - APR0159925

   } // checkForOtherSellingOpp
     
   // Save the referral objects.
   public Boolean saveReferrals() {
      ErrorLog.startLog2(ErrorLog.processLog, 'saveReferrals');
      Boolean okay = true;
      
      Referral__c[] saveRecs = new Referral__c[]{};
      Map<Id,Id> userToAccountMap = new Map<Id,Id>(); // User Ids to their Account Ids to check the Account Team Members
      
      Id[] approvedRefIds = new Id[]{};                           // collect referrals that are automatically approved and create selling opportunities
      
      // check activity info
      //defReferral.CreateSellerEvent__c = !defReferral.CreateSellerTask__c;
      
      ReferralLeadSourceMap__c curRlsm = foundRecMap.get(selectedReferralSourceOption);
       
      if (acct != null && (isReferringAccount || isReferringContact)) {
         checkForOtherSellingOpp();
      }

      Id referralJoinId = null;
      // if more than one, join them all together.
      if (selectedRefs.size() > 1) {
         ReferralJoin__c refJoin = new ReferralJoin__c();
         insert refJoin;
         referralJoinId = refJoin.Id;
      } // if (selectedRefs.size() > 1
      
      // the referrals we can't find a user to send to
      Referral_Unknown__c[] unknowns = new Referral_Unknown__c[]{};
      
      // by default, assume to expire ownership if NSS. If a non-send email referral is created, do not close ownership.
      Boolean expireOwnership = isTelemarketing;
      
      // the first one in the list will be the primary based on the sort order of the referral partners
      ReferralWrapper primaryRw = null;
      System.debug('saveReferrals selectedRefs='+selectedRefs.size());
      Boolean hasWarmTransfer=false;
      Boolean partRefNeeded = false;
      //APR0124572
      for (ReferralWrapper rw : selectedRefs) {
         // reset all to false, we'll set it later. This is in case selections change
         rw.ref.Primary__c=false;
         hasWarmTransfer = (hasWarmTransfer || (rw.selected && rw.ref.Warm_Transfer__c));
         // this will be set on the first selected. All other will be set to false
         // unless the selectedWithIntegratedPartner is true
         if (primaryRw == null || rw.selectedWithIntegratedPartner) {
            primaryRw = rw;
         }
         //NSS Ecomm
         partRefNeeded = (partRefNeeded || (rw.refPartner != null && rw.refPartner.CheckPartnerReferral__c));

      } // for (ReferralWrapper rw
      System.debug('saveReferrals primaryRw='+(primaryRw!=null));
      if (primaryRw != null) {
         primaryRw.ref.Primary__c=true;
      }
      //APR0124572 - if Referral Partner's CheckPartnerReferral field is set to true, create a partner referral if one doesn't exist
      if(primaryRw != null && partRefNeeded && partReferral==null){
        createPartRefFromRefPart();     
      }
      
      // check if activity is going to be created
      if (String.isNotBlank(activityOption) && defReferral != null) {
         defReferral.CreateSellerEvent__c = (!hasWarmTransfer && activityOption == 'Event');
         defReferral.CreateSellerTask__c = (!hasWarmTransfer && activityOption == 'Task');
         defReferral.Warm_Transfer__c = (hasWarmTransfer);
      }

      Set<String> selectedRefPartnerSet = new Set<String>();
      Boolean EvaluateProductOfInterest = false;
      // collect the Referral__c objects to be saved
      for (ReferralWrapper rw : selectedRefs) { 
          if(rw.refPartner.Evaluate_Product_Of_Interest__c)
              EvaluateProductOfInterest = true;
         // set the owner to the referral user in case it's not the running user
         
         Id refOwnerId = null;
 ////////        system.debug('jsh campaignQueue: '+v_latestCampaign.Submit_Referral_Queue__c + 'rw.refPartner.QueueName__c: '+rw.refPartner.QueueName__c+' user: '+rw.ref.User__c);
         if (rw.refPartner != null && rw.refPartner.SetReferralOwner__c ) {
            refOwnerId = rw.ref.User__c;
            if (refOwnerId == null && String.isNotBlank(rw.refPartner.QueueName__c)) {
               Group queue;
               if(v_latestCampaign!=null && String.isNotBlank(v_latestCampaign.Submit_Referral_Queue__c)){
                 //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Using the queue from the campaign'));
                   queue = new UserHelper().getQueue(v_latestCampaign.Submit_Referral_Queue__c);
               }
               else{
                    queue = new UserHelper().getQueue(rw.refPartner.QueueName__c);
               }
               system.debug('jsh queue'+queue);
               if (queue != null) {
                    refOwnerId = queue.Id;
                    rw.ref.Original_Owner_was_Queue__c = true;
             }
            //} else {
            //   refOwnerId = rw.ref.User__c;
            }
         }
         rw.ref.OwnerId = (refOwnerId != null ? refOwnerId : referralUser.Id);
         /*
         system.debug('jsh rr: '+rw.refPartner.Round_Robin_Setting_Name__c);
         if(rw.refPartner!= null && rw.refPartner.Round_Robin_Setting_Name__c != null){
             Round_Robin_Settings__c rrs = Round_Robin_Settings__c.getInstance(rw.refPartner.Round_Robin_Setting_Name__c);
             if(rrs!=null && rrs.Queue_Id__c!=null){
                rw.ref.OwnerId = rrs.Queue_Id__c;
             }
             else{
                system.debug('jsh FILL IN THE QUEUE ID ON RR SETTING');
                rw.ref.OwnerId = referralUser.Id;
             }
         }
         else{
            rw.ref.OwnerId = referralUser.Id;
         }
         */
         system.debug('jsh ref owner'+rw.ref.OwnerId);
         rw.ref.Referring_User__c = referralUser.Id;
         rw.ref.Status__c = ((rw.ref.Referral_Source__c == 'Wholesaler' || !rw.refPartner.UseApprovalProcess__c) ? 'Approved' : 'Pending');        
         rw.ref.EmailReminderOptOut__c = defReferral.EmailReminderOptOut__c;
         rw.ref.ReferralJoin__c = referralJoinId;
         rw.ref.IsAncillary__c = rw.isAncillary;
         rw.ref.Started_From__c = defReferral.Started_From__c;
         rw.ref.Cadence_Touchpoint__c = defReferral.Cadence_Touchpoint__c;
         rw.ref.Referring_Employee_Selling_Opportunity__c = defReferral.Referring_Employee_Selling_Opportunity__c;
          
          if(isTelemarketing){
             rw.ref.dm__c = (dm!=NULL?dm:FALSE);
             rw.ref.Potential_for_Multiple_Locations__c = (multipleLocs!=NULL?multipleLocs:FALSE);
          }
         
         // for tracking - not sure how useful this will be.
         rw.ref.FormLoadStart__c = defReferral.FormLoadStart__c;
         rw.ref.FormLoadComplete__c = defReferral.FormLoadComplete__c;
         rw.ref.SubmitFormStart__c = defReferral.SubmitFormStart__c;
         rw.ref.SubmitFormComplete__c = DateTime.now();
         rw.ref.Campaign__c = defReferral.Campaign__c;
         rw.ref.SellingLeadSource__c = defReferral.SellingLeadSource__c;
         rw.ref.PartnerReferral__c = defReferral.PartnerReferral__c;
         rw.ref.Final_Qualification_Method__c = qualifyType;
         rw.ref.Selected_Account__c = defReferral.Selected_Account__c;
         // fillin Transfer to Field Reason from form        CMFCMF
     //APR0121163
     /*     if (String.isNotBlank(selectedTransferReason)) 
         {  rw.ref.Transfer_to_Field_Reason__c = selectedTransferReason;    }
       */  
         // clear out lookups so we don't error
         rw.ref.User__r = null;
         rw.ref.Referring_User__r = null;

        
         String commissionProducts = null;         
         // save selected commission products   
         if (rw.selectedCommProducts != null && rw.selectedCommProducts.length() > 0)
         {              
             String tempProds = rw.selectedCommProducts.replace('[','');
             tempProds = tempProds.replace(']','');
             List<String> prodList = tempProds.split(', ');
             for (String prod: prodList )
             {       if (commProdCommissionableSet.contains(rw.refPartner.Name+'-'+prod))
             {       if (String.isNotBlank(commissionProducts))
             {       commissionProducts += ';' + prod;       }
              else
              {       commissionProducts = prod;      }                        
             } // if (commProdCommissionableSet.contains                   
             } // for                
             rw.ref.Commission_Products__c = commissionProducts;          
             //rw.ref.ProductReferred__c = rw.selectedCommProducts.substring(1,rw.selectedCommProducts.length()-1);                      rw.ref.ProductReferred__c = rw.selectedCommProducts.substring(1,rw.selectedCommProducts.length()-1);    
             Integer prodLength = Referral__c.ProductReferred__c.getDescribe().getLength();     
             prodLength = (rw.selectedCommProducts.length() < prodLength ? rw.selectedCommProducts.length() : prodLength);                  
             rw.ref.ProductReferred__c = rw.selectedCommProducts.substring(1,rw.selectedCommProducts.length()-1); 
         
         } // if
        
         if (rw.refPartner != null) {
            selectedRefPartnerSet.add(rw.refPartner.Name);
         }

         if (curRlsm != null) {
            rw.ref.SellingLeadSource__c = curRlsm.OppLeadSource__c;
            rw.ref.Referral_Contact__c = (attachedReferralSource != null ? attachedReferralSource.Id : rw.ref.Referral_Contact__c);
         }         

         
         rw.ref.CreateSellerEvent__c = (rw.refPartner.CreateSellerActivity__c && defReferral.CreateSellerEvent__c);
         rw.ref.CreateSellerTask__c = (rw.refPartner.CreateSellerActivity__c && defReferral.CreateSellerTask__c);

         rw.ref.ActivityDate__c = defReferral.ActivityDate__c;
         rw.ref.ActivityDateTime__c = defReferral.ActivityDateTime__c;
         rw.ref.TimeZoneName__c = defReferral.TimeZoneName__c;
         rw.ref.TimeZoneAbbrev__c = defReferral.TimeZoneAbbrev__c;
         rw.ref.TimeZoneOffset__c = defReferral.TimeZoneOffset__c;
         // set this string here in case there's a trigger problem
         if (rw.ref.CreateSellerEvent__c && rw.ref.ActivityDateTime__c != null) {
            rw.ref.ActivityDateTimeFormatted__c = Utilities.formatDate('Referral Format Date', rw.ref.ActivityDateTime__c, rw.ref.TimeZoneOffset__c, rw.ref.TimeZoneAbbrev__c);
         }

         String acctName = (acct != null ? acct.Name : null);
         String refPartnerName = rw.displayName;
         // in case there isn't an account name - have something in the name field
         if (acctName == null) {
            acctName = refPartnerName;
            refPartnerName = null;
         }
         // if(rw.ref.Started_From__c ='Referral_Contact__c'){
         //    rw.ref.Name = refPartnerName + ' - '
         // }
         System.debug('Account Name: '+acctName);
         rw.ref.Name = CreateOppAndMeeting.getOppName(acctName, refPartnerName,REF_NAME_SIZE);

         //rw.ref.AssignedToDSA__c = false;
         if (rw.ref.User__c == null && (rw.isOpenTerritory || rw.isUnknownTerritory)) {
            // TODO - not sure if this next if statement is needed
            if (rw.ref.DSA__c != null) {
               rw.ref.AssignedToDSA__c = true;
               rw.ref.User__c = rw.ref.DSA__c;
            } else if (rw.ref.DSM__c != null) {
               //APR0151864: SMB Channel Evolution BAU--Start
               Id queueId=isQueueAvailable(rw.ref.DSM__c);
               system.debug('isQueueAvailable'+queueId);
               if(queueId!=null){
                  rw.ref.OwnerId=queueId;
               }
               else{
                  rw.ref.User__c = rw.ref.DSM__c;
                  rw.ref.AssignedToDSA__c = true;
               }
               //APR0151864: SMB Channel Evolution BAU--End
               
            }
            // if open and not assigned to a user - assign to the unassigned queue unless the ownerid is for a queue
            // if it's going to a queue should be for round robin
            if (isTelemarketing && rw.ref.User__c == null && !rw.ref.Original_Owner_was_Queue__c && rw.refPartner.Case_RecordTypeId__c==null) {
               NSSSettings__c setting = NSSSettings__c.getInstance(NSS_UNASSIGNED);
               if (setting != null) {
                  // get the queue
                  Group nssQueue = new UserHelper().getQueue(setting.Attribute1__c);
                  if (nssQueue != null) {
                     rw.ref.Status__c = 'Assigned to Queue';
                     Referral_Unknown__c unknown = new Referral_Unknown__c(Name=rw.ref.Name, Status__c=rw.ref.Status__c, OwnerId=nssQueue.Id);
                     unknown.Referral__r = rw.ref;
                     unknowns.add(unknown);
                     //rw.ref.OwnerId = nssQueue.Id;
                  }
               } // if (setting != null
            } // if (!rw.ref
         } // if (rw.ref.User__c == null
         //rw.ref.Send_Email__c = (rw.referralType == 'Email');
         if (rw.referralType == 'Email' || rw.refPartner.Always_Check_Send_Email__c)
         {       rw.ref.Send_Email__c = true;   }
         
         // as long as we're not sending an email for at least one referral, do not expire ownership
         if (expireOwnership && !rw.ref.Send_Email__c) {
            expireOwnership = false;
         }
         // if the account is not set this will be an error!
         rw.ref.Account__c = (acct != null ? acct.Id : rw.ref.Account__c);
         // clear out the lead since it should be converted by now.
         if (rw.ref.SourceLead__c != null) {
            // find the contact record
            CtctWrapper foundCw = null;
            for (CtctWrapper cw : allCtcts) {
               if (cw.ld.Id == rw.ref.SourceLead__c) {
                  rw.ref.SourceContact__c = cw.ctctId;
               }
            } // for

            //rw.ref.SourceLead__c = null;
         } // if (rw.ref.SourceLead__c != null
         rw.ref.SourceContact__c = (ctct != null ? ctct.Id : rw.ref.SourceContact__c);
         System.debug('saveReferrals Account__c='+rw.ref.Account__c+' SourceContact__c='+rw.ref.SourceContact__c); 
         // 
         // add the account name to the referral name
         //rw.ref.Name = (acct != null ? acct.Name+'-' : '')+rw.ref.Name;
        
         if (rw.oli != null) {
            rw.ref.ReferringLineItemId__c = rw.oli.Id;
         }
         
         // if there's an account and a user, add them to the map to use later checking for Account Team Members
         if(rw.ref.Account__c != null && rw.ref.User__c != null) {
            userToAccountMap.put(rw.ref.User__c, rw.ref.Account__c);
        }
        
         System.debug('saveReferrals ref='+rw.ref.Name+' user__r='+(rw.ref.User__r != null));
         System.debug('saveReferrals ref='+rw.ref);
         
         // APR0114125 - If a user has manually populated the Referral Contact, & Client Referral values in the Form then 
         // pass on these value to Oppty for saving.
         if(defReferral.Referral_Contact__c != null)    {
            rw.ref.Referral_Contact__c = defReferral.Referral_Contact__c;
            rw.ref.Referral_Account__c = defReferral.Referral_Contact__r.Referral_Account__c;
        }
        if(defReferral.Client_Referral__c != null)  {
            rw.ref.Client_Referral__c = defReferral.Client_Referral__c;
        } 
        rw.ref.Funnel_Stage__c = defReferral.Funnel_Stage__c;         
        rw.ref.MQL_Date_Entered__c = defReferral.MQL_Date_Entered__c;
        rw.ref.MQL_Date_Exited__c = defReferral.MQL_Date_Exited__c;
        rw.ref.MQL_Lead_Source__c = defReferral.MQL_Lead_Source__c;
        rw.ref.MQL_Marketo_Lead_Rating__c = defReferral.MQL_Marketo_Lead_Rating__c;
        rw.ref.TAL_Date_Entered__c = defReferral.TAL_Date_Entered__c;
        rw.ref.TAL_Date_Exited__c = defReferral.TAL_Date_Exited__c;
        rw.ref.TAL_Lead_Source__c = defReferral.TAL_Lead_Source__c ;
        rw.ref.TAL_Marketo_Lead_Rating__c = defReferral.TAL_Marketo_Lead_Rating__c;
         
         saveRecs.add(rw.ref);
      } // for (ReferralWrapper rw
      
      String additionalProdOfInterest = null;

       // Get a usable map of existing AccountTeamMembers with these users tied to these accounts
       List<AccountTeamMember> existingAccountTeamMembers = [SELECT Id, AccountId, UserId FROM AccountTeamMember WHERE UserId IN :userToAccountMap.keySet() AND AccountId IN :userToAccountMap.values()];
       Map<Id, AccountTeamMember> existinguserToAccountMap = new Map<Id, AccountTeamMember>();
       for(AccountTeamMember tempATM : existingAccountTeamMembers) {
           existinguserToAccountMap.put(tempATM.UserId, tempATM);
       }

      if (primaryRw != null && !selectedRefPartnerSet.isEmpty()) {
         String products = (primaryLead != null ? primaryLead.Products__c : (ctct != null ? ctct.Products__c : null));
         if (String.isNotBlank(products)) {
             System.debug('products = '+products);
             System.debug('EvaluateProductOfInterest = '+EvaluateProductOfInterest);
            // split up the product list
            String[] prodList = products.split(';');
            if(EvaluateProductOfInterest) {
               // just pass in the entire list
               additionalProdOfInterest = String.join(prodList,', ');
            } else { 
               for (String prodName : prodList) {
                  System.debug('Product of Interet = '+prodName);
                  // make sure not longer than the field
                  String key = RecordTypehelper.cleanRtName(ReferralController.REF_NSS+'-'+prodName.trim());
                  ProductGroupMapping__c foundPgm = ProductGroupMapping__c.getInstance(key);
                  System.debug('saveReferrals key='+key+' foundPgm='+foundPgm);
                  if (foundPgm != null && (String.isBlank(foundPgm.ReferralPartner__c) || !selectedRefPartnerSet.contains(foundPgm.ReferralPartner__c))) {                 
                     if (String.IsNotBlank(additionalProdOfInterest)) {
                        additionalProdOfInterest += ', '+prodName;
                     } else {
                        additionalProdOfInterest = prodName;
                     }
                  }
               } // for (String prodName
            }
         } // if (String.isNotBlank
      } // if (primaryRw
      system.debug('primaryRw: '+primaryRw);
      system.debug('additionalProdOfInterest: '+additionalProdOfInterest);
      system.debug('defReferral: '+defReferral);
      //APR0159925
      System.debug('defReferral: '+ defReferral.id ); 
       
      primaryRw.ref.AdditionalProductsOfInterest__c = additionalProdOfInterest;
       
      if (primaryRw != null && defReferral.Id != null) {
         // if an existing referral exists, reuse that one rather than creating one. 
         primaryRw.ref.Id = defReferral.Id;
         
         // save all of the other referrals so they'll all do the same operation at the same time.
         Referral__c[] insertRefs = new Referral__c[]{};
         String[] originalStatus = new String[]{};
         String[] originalOwners = new String[]{};
         for (Referral__c ref : saveRecs) {
            if (ref.Id == null) {
               insertRefs.add(ref);
               originalStatus.add(ref.Status__c);
               ref.Status__c='TempStatus';
               String ownerId = (ref.OwnerId != null ? String.valueOf(ref.OwnerId) : 'NoOwner');
               if (ownerId != 'NoOwner') {
                  ref.OwnerId = runningUser.Id;
               }
               originalOwners.add(ownerId);
            }
         }
         
         System.debug('saveReferrals insertRefs='+insertRefs.size());
         if (!insertRefs.isEmpty()) {
             
            // insert the records so all records will be able to do an update
            ReferralTriggerActions.SKIP_TRIGGER = true;
            DmlHelper.performDML2(insertRefs, DmlHelper.DML_INSERT, 'ReferralController', 'saveReferrals', 'Inserting new referral', true);
            ReferralTriggerActions.SKIP_TRIGGER = false;
            for (Integer cnt=0; cnt<insertRefs.size(); cnt++) {
               Referral__c ref = insertRefs[cnt];
               if (ref != null) {
                  System.debug('saveReferrals change status from '+ref.Status__c+' to '+originalStatus[cnt]);
                  ref.Status__c = originalStatus[cnt];
                  if (originalOwners[cnt] != 'NoOwner') {
                     ref.OwnerId = originalOwners[cnt];
                  }
               }
            } // for (Integer cnt=0; cnt<insertRefs.size
         } // if (!insertRefs.isEmpty
      } // if (primaryRw != null && defReferral.Id != null
      
      // make sure sharing is enabled so referring rep can see
      AccountShare[] acctShares = new AccountShare[]{};
      AccountTeamMember[] atms = new AccountTeamMember[]{};
      
      System.debug('saveReferrals saveRecs='+saveRecs.size());
      
      if (!saveRecs.isEmpty()) {
         System.debug('SaveRecs : '+saveRecs);
         ReferralTriggerActions.SKIP_TRIGGER = false;
         Database.UpsertResult[] results = Database.upsert(saveRecs,false);
         
         
         
         if (partReferral != null && partReferral.Referral__c == null && primaryRw != null && primaryRw.ref.Id != null) {
            partReferral.Referral__c = primaryRw.ref.Id;
            partReferralNeedsUpdate = true;
         }
         //Save attachments to referral
         saveAttachments(results,saveRecs);
         
         ErrorLog__c errLog = null;
         Referral__c[] retryRecs = new Referral__c[]{};
          
         for (Integer cnt=0; cnt<selectedRefs.size(); cnt++) {
            ReferralWrapper rw = selectedRefs.get(cnt);
            Database.UpsertResult sr = results.get(cnt);
            System.debug('saveReferrals sr='+sr);
            if (!sr.isSuccess()) {
               errLog = ErrorLog.logError('ReferralMethods', 'processSellingOpps', (rw.ref != null ? rw.ref.Referral_Partner__r.Partner_Type__c+' ' : '')+'saving the Opportunity', (String)null, (Exception)null, rw.oppSelling, false);
               errLog.ObjectAPIName__c = 'Referral__c';
               errLog.DMLType__c = DmlHelper.DML_UPSERT;
            }
            rw.addToReferralNotes(ReferralMethods.getSaveMsg('Referral Record',sr.isSuccess(), false, sr.getErrors(),'ReferralController','saveReferrals','saving referrals',returnId,errLog));
            // set approval process for records going to users.
            if (sr.isSuccess() && rw.ref.User__c != null && rw.ref.Account__c != null) {
               // Make sure the selling rep has visibility
               AccountShare acctShare = new AccountShare();
               acctShare.AccountId = rw.ref.Account__c;
               acctShare.UserOrGroupId = rw.ref.User__c;
               acctShare.AccountAccessLevel = 'Edit' ;
               acctShare.CaseAccessLevel = 'Edit' ;
               acctShare.OpportunityAccessLevel = 'Edit';
               acctShares.add(acctShare);
               
               //check if the atm already exists AND that we're not in a batch process to confirm we're not overwriting ATM records based on ownership
               AccountTeamMember existingATM = null;
               if(existinguserToAccountMap != null && rw.ref.User__c != null) {
                   existingATM = existinguserToAccountMap.get(rw.ref.User__c);
               }
               if((existingATM == null || existingATM.AccountId != rw.ref.Account__c) && !System.isBatch()) {
               AccountTeamMember atm = new AccountTeamMember();
               atm.AccountId = rw.ref.Account__c;
               atm.TeamMemberRole = 'Internal Referral';
               atm.UserId = rw.ref.User__c;
               atm.AccountAccessLevel='Edit';
               atm.ContactAccessLevel='Edit';
               atm.OpportunityAccessLevel='Read';    
               atms.add(atm);
               }
                
               // Create an approval request for the account if not originated from a Wholesaler        
               if (rw.ref.Status__c != 'Approved') {                 
                  Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                  req1.setComments('Submitting request for approval.');
                  req1.setObjectId(rw.ref.id);
                  // Submit the approval request for the account
                  try {
                     Approval.ProcessResult result = Approval.process(req1);
                     deleteAttachments(results, saveRecs);
                  } catch (Exception e) {
                     // log an error - referral wasn't submitted for approval!
                     ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error setting approval: '+e));
                     okay = false;
                  }
               } else {
                  // dont need approval so go ahead and create selling opty
                  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Adding approved referral'));
                  approvedRefIds.add(sr.getId());   
               } // if (rw.ref.Status__c != 'Approved'
            } else if (!sr.isSuccess()) {
               okay = false;
               String errMsg = '';
               for (Database.Error dbError : sr.getErrors()) {
                  errMsg += dbError.getMessage();
               }
               rw.ref.addError(errMsg);
               retryRecs.add(rw.ref);
            } // if (sr.isSuccess()
            
         } // for (Integer cnt=0
         
         if (errLog != null) {
            ErrorLog.saveErrorLog(errLog);
            if (!retryRecs.isEmpty() && DmlHelperRetry.canWeRetry(errLog)) {
               DmlHelperRetry dhr = new DmlHelperRetry(errLog, retryRecs);
               dhr.processRetry(ReferralMethods.ALLOW_SLEEP_FOR_RETRY);
            }
         } // if (errLog != null
      } // if (!saveRecs.isEmpty
      
      if (!unknowns.isEmpty()) {
         for (Referral_Unknown__c unknown : unknowns) {
            if (unknown.Referral__r != null && unknown.Referral__r.Id != null) {
               unknown.Referral__c = unknown.Referral__r.Id;
               unknown.Referral__r = null;
            }
         } // for (Referral_Unknown__c
         Database.insert(unknowns,false);
      }
      
      if (okay && !acctShares.isEmpty()) {
         Database.insert(acctShares,false);
      }
      if (okay && !atms.isEmpty()) {
         Database.insert(atms,false);
      }
      
      if (partReferralNeedsUpdate && partReferral != null){
         system.debug('saveReferrals partReferral Contact: '+partReferral.Contact__c+' Account: '+partReferral.Account__c);
         Database.update(partReferral,false);
      }                                              
    
      if (expireOwnership && acct!= null && acct.Id != null) {
        Set<String> nssTeamSet = new Set<String>();
        nssTeamSet.addAll(ProspectOwnershipMethods.VALID_NSS_TEAMS);
        Map<Id,Id> acctUserMap = new Map<Id,Id>();
        acctUserMap.put(acct.Id,referralUser.Id);
         AccountMethods.checkEndOwner(new Set<Id>{acct.Id}, acctUserMap, nssTeamSet, 'No Opportunities created for Referral',true);
      } // if (expireOwnership
      ErrorLog.endLog2(ErrorLog.processLog);

      return okay;
   } // saveReferrals
   
   
   public PageReference cancel() {
        PageReference returnPr = null;
        try {
         returnPr = new PageReference('/'+(returnId != null ? returnId : ''));
        } catch (Exception e) {
                // in case returnId isn't a valid id.
           returnPr = new PageReference('/');
        }
      returnPr.setRedirect(true);             
      return returnPr;
   } // cancel
   
   /** Add more (blank) rows to the referral list. */
   public PageReference addMore() {
    ReferralWrapper rw = new ReferralWrapper();
    rw.ref.Referring_User__c = referralUser.id;
    rw.ref.Account__c = (acct != null ? acct.Id : null);
    rw.ref.SourceContact__c = defReferral.SourceContact__c;
    rw.ref.SourceLead__c = (primaryLead != null ? primaryLead.Id : null);
    rw.ref.SellingLeadSource__c = defReferral.SellingLeadSource__c;
    
    rw.lockTitle = false;
    //rw.ref.No_Referring_Opty_Needed__c = noRefOptyNeeded;               
    rw.ref.Referral_Contact__c = referralContactId;   
    // rw.ref.Referral_Source__c = noRefOptyNeeded ? 'Wholesaler' : 'Sales Rep';                        ////////////// CMF change?
    rw.ref.Referral_Source__c = defReferral.Referral_Source__c;                                                                                         
    rw.ref.Started_From__c = defReferral.Started_From__c;                                                                                                       
    
    refTo.add(rw);
    displayList = refTo;
      return null;
   } // addMore
   
   public PageReference setPartnerOption() {
    // find a record where the title isn't locked
    for (ReferralWrapper rw : displayList) {
         if (!rw.lockTitle) {
            System.debug('setPartnerOption found record without a locked title! type='+rw.selectedPartnerType);
            Referral_Partner__c rp = getRefPartner(rw.selectedPartnerType);
            if (rp != null) {
                System.debug('setPartnerOption Referral partner found!');
                setReferralPartner(rw, rp);
                rw.selected = true;
            }

         } // if (!rw.lockTitle
    } // for (Referral_Wrapper 
      return null;
   } // setPartnerOption
   
   public Referral_Partner__c getRefPartner(Id recId) {
    Referral_Partner__c foundRp = null;
    if (recId != null) {
         for (Referral_Partner__c rp : refPartners) {
           if (rp.Id == recId) {
            foundRp = rp;
              break;
           }
         } // for (Referral_Partner__c
    } // if (recId != null
      return foundRp;
   } // getRefPartner
   
   
   public Boolean hasOpenTerritory{get;private set;}
   
   public Boolean selectedHasAncillary{get; private set;}
   
   public Boolean teamSellingChecked = false;
   
   /** If a user clicks a checkbox, handle any changes that need to occur.
       07/08/2013 Dan - NSS Changes to display calendar
    */
   public PageReference markSelected() {    
        markSelectedCount +=1;   
        // default to false
        // see if at least one of the referral partner records indicate if to create a referring opportunity
        createReferringOpp = false;
        hasOpenTerritory = false;
        selectedHasAncillary = false;
        Boolean setTeamSelling = false;
        // if the payroll rep has a selling partner, keep track of the id
        Id sellingPartnerId = null;
        // keep track of this wrapper in case of team selling.
        ReferralWrapper asoWrapper = null;
        ReferralWrapper peoWrapper = null;
        ReferralWrapper payrollPartner = null;
        ReferralWrapper mmsPartner = null;
        ReferralWrapper selectedIntSelWrap = null;
        Boolean asoSelected = false;
        Boolean peoSelected = false;
        Boolean payrollSelected = false;
        Boolean mmsSelected = false;
        
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'markSelected teamSellingASOEligible='+teamSellingASOEligible));      
        if (displayList != null) {
            for (ReferralWrapper rw : displayList) {
                Referral__c wrappperRef =  rw.ref;
                // is the current referral partner for payroll (PAY or MMS)?
                Boolean isPayrollPartner = false;
                //StringHelper.addToProcessNotes(wrappperRef,'MarkSelected Partner Name= '+rw.displayName+'- Referral User= '+rw.ref.User__c);
                System.debug('markSelected rw.refPartner.Name: '+rw.refPartner.Name);
                // only select the partners that actually meet the criteria
                if (rw.refPartner.Name == UserHelper.SO_PEO_ASO || rw.refPartner.Sales_Org__c == UserHelper.SO_PEO_ASO) {
                    asoSelected = (asoSelected || rw.selected);
                    if (asoWrapper == null && rw.meetsSegmentCriteria) {
                       System.debug('markSelected PAS meets segment criteria');
                       asoWrapper = rw;
                    }
                } else if (rw.refPartner.Name == UserHelper.SO_PEO || rw.refPartner.Sales_Org__c == UserHelper.SO_PEO) {
                    peoSelected = (peoSelected || rw.selected);
                    if (peoWrapper == null && rw.meetsSegmentCriteria) {
                       System.debug('markSelected PEO meets segment criteria');
                       peoWrapper = rw;
                    }
                } else if (rw.refPartner.Name == UserHelper.SO_MMS || rw.refPartner.Sales_Org__c == UserHelper.SO_MMS) {
                    mmsSelected = (mmsSelected || rw.selected);
                    if (mmsPartner == null && rw.meetsSegmentCriteria) {
                       System.debug('markSelected MMS meets segment criteria');
                       mmsPartner = rw;
                       //payrollPartner = rw;
                       //isPayrollPartner = true;
                    }
                    
                } else if (rw.refPartner.Name == UserHelper.SO_CORE || rw.refPartner.Sales_Org__c == UserHelper.SO_CORE) {
                    payrollSelected = (payrollSelected || rw.selected);
                    if (payrollPartner == null && rw.meetsSegmentCriteria) {
                       System.debug('markSelected PAY meets segment criteria');
                       payrollPartner = rw;
                       isPayrollPartner = true;
                    }
                    
                }
                
                if (rw.selected) {
                   System.debug('markSelected teamSellingASOEligible='+teamSellingASOEligible+' teamSellingChecked='+teamSellingChecked+' rw.refUserIsVirtual='+rw.refUserIsVirtual+' rw.refPartner.CheckTeamSellingASO__c='+rw.refPartner.CheckTeamSellingASO__c);

                    if (teamSellingASOEligible && !teamSellingChecked && !rw.refUserIsVirtual && rw.refPartner.CheckTeamSellingASO__c && !campaignExcludeFromIS) {
                        setTeamSelling = true;
                        selectedIntSelWrap = rw;
                        if (isPayrollPartner) {
                           // check the HR Services Partner
                           if(rw.ref.User__c != null && rw.ref.User__r.HR_Services_Partner__c != null && !(rw.ref.User__r.User_Special_Access__c == 'ASO_for_SMB')) {
                              sellingPartnerId = rw.ref.User__r.HR_Services_Partner__c;   
                              rw.selectedWithIntegratedPartner = true;
                           }
                        } // if (isPayrollPartner
                    } // if (teamSellingASOEligible
                    System.debug('markSelected sellingPartnerId='+sellingPartnerId+' setTeamSelling='+setTeamSelling +' payrollPartner='+(payrollPartner != null ? payrollPartner.displayName : 'NoPartner'));
                    createReferringOpp = createReferringOpp || rw.refPartner.CreateRefOpp__c;
                    hasOpenTerritory = hasOpenTerritory || rw.isOpenTerritory;
                    selectedHasAncillary = selectedHasAncillary || rw.refPartner.UseAncillary__c;
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'markSelected selectedHasAncillary='+selectedHasAncillary));
                } // if (rw.selected
                
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'markSelected rw.refPartner.Name='+rw.refPartner.Name+' setTeamSelling='+setTeamSelling));
            } // for
        } // if (displayList != null
        system.debug('markSelected setTeamSelling='+setTeamSelling);
        if (setTeamSelling) {
            teamSellingChecked = true;
            // default to this value
            partnerSalesOrg = UserHelper.SO_PEO_ASO;
            Boolean curClient = (acct != null && acct.CurrentClient__c);
            system.debug('markSelected payrollSelected='+payrollSelected+' asoSelected='+asoSelected+' peoSelected='+peoSelected+' curClient='+curClient);
            system.debug('markSelected payrollSelected='+payrollSelected+' asoSelected='+asoSelected+' peoSelected='+peoSelected+' mmsSelected='+mmsSelected+' curClient='+curClient);
            if ((payrollSelected && !asoSelected) || (mmsSelected && !peoSelected)
                || (peoSelected && !mmsSelected && !curClient)) {
                ReferralWrapper checkPartner = (peoSelected ? peoWrapper : (mmsSelected ? mmsPartner : payrollPartner));
                // default value
                ReferralWrapper partnerWrap = null; //asoWrapper;
                system.debug('markSelected payrollPartner='+(payrollPartner != null ? payrollPartner.displayName : 'NotFound')
                              +' sellingPartnerId='+sellingPartnerId+' checkPartner='+(checkPartner != null));
                // if a selling partner is not already found, then we're going to use the custom metadata to try to figure out who it should be.
                if (sellingPartnerId == null && checkPartner != null) {
                   sellingPartnerId = checkForPartner(checkPartner);
                   if (String.isBlank(partnerSalesOrg)) {
                      // if nothing is returned, we'll assume that we're not setting a partner
                      partnerWrap = null;
                   } else if (partnerSalesOrg == UserHelper.SO_PEO) {
                      partnerWrap = peoWrapper;
                   } else if (partnerSalesOrg == UserHelper.SO_MMS) {
                      partnerWrap = mmsPartner;
                   } else if (partnerSalesOrg == UserHelper.SO_PEO_ASO) {
                      partnerWrap = asoWrapper;
                   }
                   system.debug('markSelected sellingPartnerId='+sellingPartnerId+' partnerSalesOrg='+partnerSalesOrg+' partnerWrap='+(partnerWrap != null ? partnerWrap.displayName : 'NA'));
                }
                if (partnerWrap != null) {
                   // so we can order the primary field later
                   selectedIntSelWrap.selectedWithIntegratedPartner = true;
                   system.debug('markSelected selectedWithIntegratedPartner='+selectedIntSelWrap.displayName);
                   partnerWrap.selected = true;
                   partnerWrap.ref.Inbound_Integrated_Selling__c = true; // 09/07/2023 - Vinay - APR0155378
                   createReferringOpp = createReferringOpp || partnerWrap.refPartner.CreateRefOpp__c;
                   hasOpenTerritory = hasOpenTerritory || partnerWrap.isOpenTerritory;
                   selectedHasAncillary = selectedHasAncillary || partnerWrap.refPartner.UseAncillary__c;
                   partnerWrap.ref.User__c = sellingPartnerId != null ? sellingPartnerId : partnerWrap.ref.User__c;
                }
                // asoWrapper.ref.User__r = hrServicesPartner   // don't do this first.   
            } // if (asoWrapper != null
        } // if (setTeamSelling   
        checkReferringOpp();
        changeReferTo();
        //APR0154201 Add processbutton to P&C Quote Data
        if(pcQuoteId!=null){
         pcQuoteData();
        }
        
        return null;
    } // markSelected
    
    // we need to know what value is returned based on the custom metadata type
    public String partnerSalesOrg='';
    
    public Id checkForPartner(ReferralWrapper rw) {
        system.debug('checkForPartner rw.ref.User__c'+rw.ref.User__c); 
        // this only needs to be done for a PAY(SMB) rep
        if (rw.ref.User__c != null && (rw.refPartner.Name == UserHelper.SO_CORE || rw.refPartner.Sales_Org__c == UserHelper.SO_CORE)) {
           list<User> users =[Select id, Sales_Level__c, User_Special_Access__c from User where id=:rw.ref.User__c limit 1];
           //  TODO - this shouldn't be hardcoded
           Boolean isASOforSMB = (!users.isEmpty() && String.isNotBlank(users[0].User_Special_Access__c) && users[0].User_Special_Access__c.contains('ASO_for_SMB'));
           system.debug('checkForPartner isASOforSMB='+isASOforSMB);
           // if they have this attribute will not be including an integrated partner.
           if (isASOforSMB) {
              partnerSalesOrg = UserHelper.SO_PEO_ASO;
              return null;
           }
        } // if (rw.ref.User__c != null

        partnerSalesOrg = '';
        Id returnId = null;    
        String state = null;
        String zipCode = null;
        //Jaipal
        Integer empCount = (primaryLead!=null ? primaryLead.NumberOfEmployees : (acct != null ? acct.NumberOfEmployees : 0));
        empCount = (empCount != null ? empCount : 0);
        
        if(primaryLead!=null){
            state =primaryLead.State;
            // make sure only the first 5 digits of zip code
            zipcode=(String.isNotBlank(primaryLead.PostalCode) ? primaryLead.PostalCode.left(5) : null);
        } else if (acct != null) {
            state = (String.isNotBlank(acct.ShippingState) ? acct.ShippingState : acct.BillingState);
            zipCode = acct.Owner_Zip_Code__c;
        }
        if (String.isNotBlank(state) && state.length() > 2) {
            // we use the RecordTypeHelper method to make sure the value passed in isn't too long
            Abbreviations__c abbrev = Abbreviations__c.getInstance(RecordTypeHelper.cleanRtName(state));
            if (abbrev != null) {
                state = abbrev.abbrev__c;
            }
        }
        state = (String.isNotBlank(state) ? state : 'DEFAULT');
        String[] queryStates = new String[]{state,'DEFAULT'};
        String[] salesOrgs = new String[]{rw.refPartner.Name};
        if (String.isNotBlank(rw.refPartner.Sales_Org__c)) {
           salesOrgs.add(rw.refPartner.Sales_Org__c);
        }
        
        system.debug('checkForPartner state='+state+' zipCode='+zipCode+' salesOrgs='+salesOrgs);
        Integrated_Selling__mdt[] intSellingSelectedList = 
              [Select id,SalesOrg__c,Segment_Used__c,State__c
                     ,EE_Count_Max__c,EE_Count_Min__c, SalesOrgPartner__c   
                 from Integrated_Selling__mdt 
                where SalesOrg__c =:salesOrgs 
                  and State__c in :queryStates
                  and EE_Count_Min__c != null 
                  and EE_Count_Max__c != null];
       
        // get the default value and one for the state (if found)
        Integrated_Selling__mdt intSelDefault = null;
        Integrated_Selling__mdt intSelState = null;
        //Jaipal
        Integrated_Selling__mdt intSelEmpCount = null;
        for (Integrated_Selling__mdt intSel : intSellingSelectedList) {
           if (intSel.EE_Count_Min__c <= empCount && intSel.EE_Count_Max__c >= empCount) {
              if (intSel.State__c == 'DEFAULT') {
                 intSelDefault = intSel;
              } else if (intSel.State__c == state) {
                 system.debug('intSelState'+intSelState);
                 intSelState = intSel;
              }
           }
        } // for (Integrated_Selling__mdt intSel

       // system.debug('intSelToUse:'+intSelToUse);
      //  system.debug('isASOforSMB'+isASOforSMB);
        Integrated_Selling__mdt intSelToUse = (intSelState != null ? intSelState : intSelDefault);
        partnerSalesOrg = (intSelToUse != null ? intSelToUse.SalesOrgPartner__c : null);
        system.debug('checkForPartner partnerSalesOrg='+partnerSalesOrg);
        /* Not sure we need this?
        if (String.isNotBlank(partnerSalesOrg)) {//changed from intSelToUse.SalesOrg__c to partnerSalesOrg
           SObject rec = (acct != null ? (SObject)acct : (SObject)primaryLead);
           // get the zip assignment that meets the criteria of the record
           ZipWrapper zw = ZipCodeLookupController.getZipAssignment(zipCode,partnerSalesOrg,rec,intSelToUse.Segment_Used__c);
           returnId = ((zw != null && zw.za.User__c != null) ? zw.za.User__c : null);
        } // if (String.isNotBlank(partnerSalesOrg
        */
        system.debug('checkForPartner returnId:'+returnId);
        return returnId;
        
    } // checkForPartner
   
   
   private List<Id> salesRepIdList = new List<Id>();
   
   /** If a contact "Refer To" record changes, lookup the User record.
    */
   public void changeContactReferTo() {
      if (verifyContacts()) {
         changeReferTo();
      }
   } // changeContactReferTo
   
   /** When the Refer To user changes.
    */
   public void changeReferTo() {
        //salesRepUserList.clear();
      // setup referring opportunity
      
      //String debugKey = Datetime.now().format('mmss');
      system.debug('MA'+allowActivity);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'changeReferTo **DEBUG MESSAGE1-'+debugKey+'** isTelemarketing='+isTelemarketing+' defReferral.CreateSellerTask__c='+defReferral.CreateSellerTask__c));
      if (allowActivity) {
         
         // get the user info - lookup is to contacts, get the person id to find the user
         //Contact[] ctcts = new Contact[]{};
         salesRepIdList.clear();
         activityOptionChanged();

        //APR0151864: SMB Channel Evolution BAU Start
        system.debug('MA1'+defReferral.Client_Referral__c+'--'+defReferral.CreateSellerTask__c);
        //APR0151864: SMB Channel Evolution BAU End

         // don't perform the following if only creating a task
         if (!defReferral.CreateSellerTask__c) {
            if (displayList != null) {
               for (ReferralWrapper rw : displayList) {
                  if (rw.selected && rw.ref.User__c != null) {
                     //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'changeReferTo **DEBUG MESSAGE2-'+debugKey+'** rw.ref.User__c='+rw.ref.User__c));
                     system.debug('MA2'+defReferral.CreateSellerTask__c+'--'+rw.selected+'--'+rw.ref.User__c);
                     if (rw.ref.User__r == null || (rw.ref.User__r != null && !rw.ref.User__r.Non_Paychex_Employee__c)) {
                        salesRepIdList.add(rw.ref.User__c);
                     }
                  }
               } // for
            } // if (displayList != null
            
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'changeReferTo **DEBUG MESSAGE3-'+debugKey+'** salesRepIdList='+salesRepIdList.size()));
            // default an appointment date 
            // TODO - what should this date be?
            calendarDate = Date.today().addDays(7);
            defReferral.ActivityDate__c = calendarDate;
            week = new CalendarWeek(calendarDate,salesRepIdList,defReferral.TimeZoneName__c);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'changeReferTo **DEBUG MESSAGE4-'+debugKey+'** isTelemarketing='+isTelemarketing+' creatingEvent='+creatingEvent));
         } // if (!defReferral.CreateSellerTask__c
         
      } // if (isTelemarketing
      
   } // changeReferTo
   
   /** get the description of the appointment date/time */
   public String apptDescription{
      get {String retVal='';
         if (defReferral != null && defReferral.ActivityDateTime__c != null) {
            retVal = defReferral.ActivityDateTime__c.format('EEEE MMMM d, yyyy  h:mm a') + ' '+defReferral.TimeZoneAbbrev__c;
         }
         return retVal;
      } // get
   } // apptDescription
   
   public Date calendarDate{get;set;}
   
   public void gotoNextWeek() {
      calendarDate = calendarDate.addDays(7);
      week = new CalendarWeek(calendarDate,salesRepIdList,defReferral.TimeZoneName__c);
   } // gotoNextWeek
   
   public void gotoPrevWeek() {
      calendarDate = calendarDate.addDays(-7);
      week = new CalendarWeek(calendarDate,salesRepIdList,defReferral.TimeZoneName__c);
   } // gotoPrevWeek
   
   public CalendarWeek week{get;set;}

   public Boolean creatingEvent{
      get {
         //return (allowActivity && defReferral != null && !defReferral.CreateSellerTask__c);
         return (allowActivity && String.isNotBlank(activityOption) && activityOption == 'Event');
      } // get
   } // creatingEvent
   
   public Boolean creatingTask{
      get {
         //return (allowActivity && defReferral != null && defReferral.CreateSellerTask__c);
         return (allowActivity && String.isNotBlank(activityOption) && activityOption == 'Task');
      } // get
   } // creatingEvent
   
   public Boolean hasCalendar{
      get {
         return (allowActivity && week != null && week.hasDayList);
      } // get
   }
   /** If user clicks checkbox requesting Referring Optys be created, reset NoRefOptyNeeded for all referral wrappers in list  CMF
    */
    /*
   public PageReference editNoRefOptyNeeded() {
//                noRefOptyNeeded = !tempRefOptyNeeded;
      setReferralOption();
      return null;
   } // editNoRefOptyNeeded
   
   /** The picklist of the time options. */
   public List<SelectOption> timeOptions{get;set;}
   
   public String selectedTime{get;set;}
   
   /** Create the picklist for the start times.
    */
   public void setupTimePicklist() {
        timeOptions = new List<SelectOption>();
        // time range from 8am - 5pm
        DateTime startTime = DateTime.newInstance(Date.today(), Time.newInstance(CalendarDay.DAY_START, 0, 0, 0));
        DateTime endTime = DateTime.newInstance(Date.today(), Time.newInstance((CalendarDay.DAY_END+1),0,0,0));
        while (startTime < endTime) {
         if (selectedTime == null) {
            selectedTime = startTime.format('HH:mm:ss');
         }

         timeOptions.add(new SelectOption(startTime.format('HH:mm:ss'),startTime.format('hh:mm a')));
         startTime = startTime.addMinutes(30);
        }
   } // setupTimePicklist
   
   /** Convert the primaryLead. If there are any other leads associated convert those also, attaching them to the account
       from the primaryLead.
    */
   public Boolean convertLead() {
      Boolean okay = true;
      
      LeadCompanyMethods.CALCULATE_SIGNIFICANCE = false;
      AccountMethods.CALCULATE_SIGNIFICANCE = false;
      LeadCheckContactRecordType.SAVE_REFERRALS = false;
      
      // todo - what Sales Org should we use? Does it matter here?
      CreateOppAndMeeting coam = new CreateOppAndMeeting(UserHelper.SO_CORE);
      coam.usr = referralUser;
      coam.leadId = primaryLead.Id;
      coam.initializeLead(false);
      
       // convert the primary lead
      // do a basic search for an account name (assuming there's a zip code)
      Account foundAcct = new Account();
      if(defReferral.Selected_Account__c!=null){
         coam.selectedCompany = defReferral.Selected_Account__c;
      }
      else{
         foundAcct = checkForAccountMatch(primaryLead.Company, primaryLead.PostalCode, (primaryLead.Lead_Company__r != null ? primaryLead.Lead_Company__r.AccountId__c : null));
         coam.selectedCompany = (foundAcct != null ? foundAcct.Id : null);
         
         if (String.isBlank(coam.selectedCompany)) {
            coam.selectedCompany = '000000000000000';
         }
      }
      okay = coam.handleLeadConvert();
      if (!okay)
      {  return okay;   }       // this will give user error message to try again
      acct = coam.accUpd;
      
      Map<Id,Lead> additionalLeadMap = new Map<Id,Lead>();
      Boolean additionalLeadsChanged = false;
      // so we can ensure the sales contact checkbox is set on the newly created contacts 
      List<Contact> ctctsToUpdate = new List<Contact>();
      
      if (foundAcct != null && !foundAcct.CurrentClient__c && primaryLead.NumberOfEmployees != null && primaryLead.NumberOfEmployees != foundAcct.NumberOfEmployees) {
         foundAcct.NumberOfEmployees = primaryLead.NumberOfEmployees;
         Database.update(foundAcct,false);
      }
      
      System.debug('convertLead okay='+okay+' nbr Ctcts='+allCtcts.size());
      // set this to true if there are lead sources that will not be converted
      Boolean updateAcctIdOnLeadCompany = false;
      if (okay) {
         if (primaryOwnership != null && primaryOwnership.Id != null) {
            // reselect the record if it exists to reflect new linkage
            primaryOwnership = ProspectOwnershipMethods.getById(primaryOwnership.Id);
         }
         
         // we need to make sure the sales contact flag is set on all of the contacts created. 
         Id[] ctctIds = new Id[]{};
         
         // if there are more leads, convert those too
         for (CtctWrapper cw : allCtcts) {
            // if this is the primary record set the contact information
            if (cw.ld.Id == primaryLead.Id) {
               cw.ctctId = coam.contactId;
               // retrieve the contact to display the information properly.
               //cw.ctct = [Select Id, Name, Products__c from Contact where Id = :coam.contactId];
               cw.ctct = ReferralQueries.selectContact(coam.contactId);                 //CMFCMF
               ctct = cw.ctct;
               returnName = cw.ctct.Name;
               returnId = cw.ctct.Id;               
               if (partReferral != null) {
                  partReferral.Account__c = acct.Id;
                  partReferral.Contact__c = cw.ctct.Id;
                  partReferralNeedsUpdate = true;
                  
               }
            } else {
               additionalLeadMap.put(cw.ld.Id,cw.ld);
               // check the required fields
               if (String.isBlank(cw.ld.PostalCode)) {
                  cw.ld.PostalCode = primaryLead.PostalCode;
                  //update cw.ld;
                  additionalLeadsChanged = true;
               }
               // TODO - are we setting a different status on these?
               //if (!convertExtraLead(coam,coam.acctId,coam.convertStatus.MasterLabel,cw)) {
               //   okay = false;
               //}
            }
            if (cw.ctctId != null) {
                ctctsToUpdate.add(new Contact(Id=cw.ctctId, Sales_Contact__c=true, Use_Zip_Assignment_Rules__c=true));
               //ctctIds.add(cw.ctctId);
            }
         } // for (CtctWrapper

         // see if there are any contacts that do not have the sales contact flag checked.
         // update them so that they will display on the form after conversion.
         /*
         if (!ctctIds.isEmpty()) {
            Contact[] ctctsToUpdate = [Select Id, Sales_Contact__c from Contact where Sales_Contact__c = false and Id in :ctctIds];
            if (!ctctsToUpdate.isEmpty()) {
               for (Contact ctct : ctctsToUpdate) {
                  ctct.Sales_Contact__c = true;
               }
               update ctctsToUpdate;
            } // if (!ctctsToUpdate)
         } // if (!ctctIds.isEmpty
         */
      } // if (okay
      System.debug('convertLead has acct='+(acct != null)+' has ctct='+(ctct != null));
      
      //if (partReferral != null) {
      //   update partReferral;
      //}
      if (additionalLeadsChanged) {
         Database.update(additionalLeadMap.values(), false);
      }
      
      System.debug('convertLead additionalLeadMap='+additionalLeadMap);
      coam.convertExtraLeads(primaryLead.Lead_Company__c, (acct != null ? acct.Id : null), additionalLeadMap);

      if (!ctctsToUpdate.isEmpty()) {
         Database.update(ctctsToUpdate,false);
      }
      LeadCompanyMethods.CALCULATE_SIGNIFICANCE = true;
      AccountMethods.CALCULATE_SIGNIFICANCE = true;
      LeadCompanyMethods.checkLeadCompany(true);
      AccountMethods.checkSignificantContact();

      // CMFCMF call MarketTrackMethods 
      if (!coam.dbConvertResultMap.isEmpty())
      {  MarketTrackingMethods.addAcctCt(coam.dbConvertResultMap);  }           // CMFCMF add account,contact info to tracking rcd for converted leads


      return okay;
   } // convertLead
   
   public Boolean convertExtraLead(CreateOppAndMeeting coam, Id acctId, String convertStatus, CtctWrapper cw) {
      cw.ctctId = coam.convertExtraLead(acctId, cw.ld);
      return (cw.ctctId != null);

   } // convertExtraLead
   
   /** See if there's one and only one match in the accounts.
    */
   public Account checkForAccountMatch(String p_name, String p_postalCode, Id acctId) {
      Account retAcct = null;
      List<Account> acctList = new List<Account>();
      if (acctId != null) {
         acctList = [SELECT Id, Name, ShippingPostalCode, BillingPostalCode, NumberOfEmployees
                                        ,CurrentClient__c
                                    from Account 
                                   where Id = :acctId];
      }  
      if (acctList.isEmpty() && String.isNotBlank(p_name) && String.isNotBlank(p_postalCode)) {
         // get the account record type ids we will use for lead convert
         ZipBatch zipB = new ZipBatch();
         zipB.setupRecordTypeIds();
         Id[] recordTypeIds = new Id[]{};
         recordTypeIds.addAll(ZipBatch.recordTypeIdMap.values());

         String accName = '%' + p_name + '%';
         String postalCode = p_postalCode.left(5);
         acctList = [SELECT Id, Name, ShippingPostalCode, BillingPostalCode, NumberOfEmployees, Owner_Zip_Code__c
                                            ,CurrentClient__c
                                    from Account 
                                   where Name like :accName
                                     and RecordTypeId in :recordTypeIds
                                     and Owner_Zip_Code__c=:postalCode 
                                     order by LastModifiedDate desc
                                     limit 2];
      } // if (String.isNotBlank
      // only set if one match is returned
      if (acctList.size() == 1) {
         retAcct = acctList[0];
      }
      return retAcct;
   } // checkForAccountMatch
   

   /** Find the time zone based on the zip code. If zip code is blank or does not return a time zone, attempt to use area code.
    */
   public void checkTimeZone(String zipCode, String areaCode, String timeZoneAbbrev, String timeZoneName) {
      defReferral.TimeZoneName__c = timeZoneName;
      defReferral.TimeZoneAbbrev__c = timeZoneAbbrev;
   
      // check the zip code information
      if (String.isNotBlank(zipCode) && (String.isBlank(defReferral.TimeZoneName__c))) {
         try {
            Zip_Code_Information__c zci = [Select Id, Name, TimeZoneName__c, TimeZoneAbbrev__c from Zip_Code_Information__c where Name = :zipCode];
            defReferral.TimeZoneName__c = zci.TimeZoneName__c;
            defReferral.TimeZoneAbbrev__c = zci.TimeZoneAbbrev__c;
         } catch (Exception e) {
            // nothing needs to be done here
         }
      } // if
      
      // if we fail to find a zip code record, attempt to find an area code record.
      if (String.isBlank(defReferral.TimeZoneName__c) && String.isNotBlank(areaCode)) {
         try {
            AreaCode__c ac = [Select Id, Name, TimeZoneName__c, TimeZoneAbbrev__c from AreaCode__c where Name = :areaCode];
            defReferral.TimeZoneName__c = ac.TimeZoneName__c;
            defReferral.TimeZoneAbbrev__c = ac.TimeZoneAbbrev__c;
         } catch (Exception e) {
            // nothing needs to be done here
         }
      }
      
      // if not value found set a default - what should this be?
      if (String.isBlank(defReferral.TimeZoneName__c)) {
         // search in the time zones for the first default
         for (TimeZone__c tz : TimeZone__c.getAll().values()) {
            if (tz.Default__c) {
               defReferral.TimeZoneName__c = tz.Name;
               defReferral.TimeZoneAbbrev__c = tz.Abbrev__c;
               break;
            }
         } // for (TimeZone__c
      } // if (String.isBlank
      
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkTimeZone defReferral.TimeZoneName__c='+defReferral.TimeZoneName__c));
   } // zipCode
 
       
   /** read Commission Referral Products custom setting and build maps
   */
   private void fillCommProdMap() {   
                commProdMap = new Map<String, List<String>>();                              // sales Org, List of products
                commProdCommissionableSet = new Set<String>();                            // salesOrg-product 
                
                for (Commission_Referral_Products__c prod: Commission_Referral_Products__c.getAll().values()) {
                        List<String> prodTemp = commProdMap.get(prod.SalesOrg__c); 
                        if (prodTemp == null)   
                        {       prodTemp = new List<String>();                            
                                commProdMap.put(prod.SalesOrg__c, prodTemp);
                        }
                        prodTemp.add(prod.Product__c);  
                        if (prod.Commissionable__c)
                        {       commProdCommissionableSet.add(prod.SalesOrg__c+'-'+prod.Product__c);    }
                }                                 
   } // fillCOmmProdMap
   
   /** did they select at least 1 Commission Product if they were available for that sales org?
    */
   private Boolean checkCommProducts() {
        Boolean allokay = true; 
        for (ReferralWrapper rw : selectedRefs) {             
                        //if (rw.requiredCommProducts && (rw.selectedCommProducts == null || rw.selectedCommProducts.length() == 0))
                        if (rw.requiredCommProducts && rw.selectedCommProducts=='[]')
            {   allokay = false;             
                break;            
            }
         } // for      
                 return allokay;
   } // checkCommProducts
    
   /** A wrapper so we can treat the contacts and the leads (before conversion) the same.
    */
   public class CtctWrapper {
      public Lead ld {get;set;}
      //including referral contacts 
      public Referral_Contact__c refctct {get;set;}
      public Contact ctct {get;set;}
      public Id ctctId=null;
      public Boolean includeEmailInName = false;
      
      //referral contact instance
      public CtctWrapper(Referral_Contact__c p_refctct, Boolean p_includeEmailInName){
         refctct = p_refctct;
         isContact = false;
         includeEmailInName = p_includeEmailInName;
         name = refctct.Name + ((includeEmailInName && refctct.Email__c != null) ? '-'+refctct.Email__c : '' );
      }
      public CtctWrapper(Contact p_ctct, Boolean p_includeEmailInName) {
         ctct = p_ctct;
         isContact = true;
         includeEmailInName = p_includeEmailInName;
         ctctId = ctct.Id;
         name = ctct.Name + ((includeEmailInName && ctct.Email != null) ? '-'+ctct.Email : '' );
      } // CtctWrapper
      
      public CtctWrapper(Lead p_ld, Boolean p_includeEmailInName) {
         ld = p_ld;
         includeEmailInName = p_includeEmailInName;
         isContact = false;
         name = ld.FirstName+' '+ld.LastName + ((includeEmailInName && ld.Email != null) ? '-'+ld.Email : '' );
      } // CtctWrapper
      
      //Is this an actual contact record? If not we'll assume it's a lead
      public Boolean isContact{get;set;}
      
      // The salesforce id of this contact
      public Id recId {
         get {
            return (ctct != null ? ctct.id : (ld != null ? ld.Id : (refCtct != null ? refCtct.Id : null)));         }
      } // recId
      
      // the name of this contact
      public String name {get;private set;}
   } // class CtctWrapper
    
   /* ---- Attachment Methods--------------*/
    private Void saveAttachments(Database.UpsertResult[] results,Referral__c[] saveRecs)
    {
        list<attachment> attsToInsert = new list<attachment>();
        list<referral__c> refsToUpdate = new list<referral__c>();
        map<id,referral__c> refMap = new map<id,referral__c>();
        //Update hasAttachment field on referral if attachments
        for(referral__c r:saveRecs){
            r.hasAttachment__c = TRUE;
            refMap.put(r.id,r);
        }
        if(attachName != NULL && attachName != ''){
            for(Database.UpsertResult sr: results){
                if(sr.isSuccess()){
                    attsToInsert.add(new attachment(parentId=sr.getId(), body=attachBody, Name=attachName));
                    refsToUpdate.add(refMap.get(sr.getId()));                    
                }                
            }            
        }
        //Insert attachments and update each referral record
        if(!attsToInsert.isEmpty()&&!refsToUpdate.isEmpty()){
            insert attsToInsert;
            update refsToUpdate;
        }
    }
    public void deleteAttachments(Database.UpsertResult[] results, Referral__c[] saveRecs)
    {
        list<referral__c> refsToUpdate = new list<referral__c>();
        if(attachName != NULL && attachName != '')
        {
            list<attachment> attsToDelete = new list<attachment>();
            //Clear hasAttachment field after attachment is deleted
            map<id,referral__c> refMap = new map<id,referral__c>();
            for(referral__c r:saveRecs)
            {
                r.hasAttachment__c = FALSE;
                refMap.put(r.id,r);
            }
            
            for(Database.UpsertResult sr: results)
            {
                if(sr.isSuccess())
                {
                    attachment att = [select id from attachment where parentid = :sr.getId()];
                    attsToDelete.add(att);    
                    refsToUpdate.add(refMap.get(sr.getId())); 
                }                
            }
            if(!attsToDelete.isEmpty())
            {
                delete attsToDelete;
                update refsToUpdate;
            }
        }
    }
    public pageReference hideAttach()
    {
        attachShow = FALSE;
        return Null;
    }
    
    public pageReference showAttach()
    {
        attachShow = TRUE;
        return Null;
    }
    
   public Boolean shouldRedirect {public get; private set;}
   public String redirectUrl {public get; private set;}

   public PageReference cancelFromEmbedded() {
      PageReference refPage = new PageReference('/'+returnId);
      refPage.setRedirect(true);
      refPage.getParameters().put('Id', returnId);
      redirectUrl =  refPage.getUrl();
      shouldRedirect = true;
      return null;
   } // cancelSubmitReferral

   /*  Sales wanted the PEO referral partner display name to be dependent on the segment and if other segments were also available */
   public void fixPEODisplayNames() {         
      Boolean foundPEO = false;
      // looking for PEO Centric partner to change name
      for (ReferralWrapper rw : refTo)
      {  if (rw.displayName == 'PEO-ASO-PEO')
           {     foundPEO = true;
              rw.displayName = 'PEO';  
              break;
           } // if
      } // for
      // looking for HR Services partner to rename
      for (ReferralWrapper rw : refTo)
      {  System.debug('ReferralController.fixPEODisplayNames fixPEO for2-name='+rw.displayName);        
         if (rw.displayName == 'PEO-ASO-UPMARKET' || rw.displayName == 'PEO-ASO')
           {     rw.displayName = (foundPEO ? 'HR Services' : 'HR Services');   }                 
      } // for
            
   } // fixPEODisplayNames
   
   //APR0124572
   public void createPartRefFromRefPart(){
      if (v_latestCampaign != null) {
         if (leadSourceDefaultSet!=null && leadSourceDefaultSet && defReferral.Campaign__c!=null
              && v_latestCampaign.LeadSource__c != null) {
            defReferral.SellingLeadSource__c = v_latestCampaign.LeadSource__c;
         }

      } // if (v_latestCampaign != null
      /*
      Campaign camp = new Campaign();
       if(defReferral.Campaign__c!=null) {
         camp = [SELECT Id,LeadSource__c, Type_2__c, Partner_Referral_Source__c FROM Campaign where Id=:defReferral.Campaign__c];
         if(leadSourceDefaultSet!=null && leadSourceDefaultSet && defReferral.Campaign__c!=null){
            if(camp!=null && camp.LeadSource__c != null){
               defReferral.SellingLeadSource__c = camp.LeadSource__c;
               system.debug('jsh leadsourceDefaultSet setting leadsource: '+defReferral.SellingLeadSource__c);
            }
         }
       }
       */
       // create a new PartnerReferral__c
       partReferral = TrackRecordEntry.logOriginalData(ctct, acct);
       partReferral.Lead__c = (primaryLead != null ? primaryLead.Id : null);
       partReferral.Contact__c = (ctct != null ? ctct.Id : null);
       partReferral.Account__c = (acct != null ? acct.Id : null);
       partReferral.Source__c = ((v_latestCampaign != null && v_latestCampaign.Partner_Referral_Source__c!= null)
                                        ? v_latestCampaign.Partner_Referral_Source__c : PART_REF_SOURCE_NAME);
       partReferral.CampaignId__c = defReferral.Campaign__c;
       partReferral.Campaign__c = defReferral.Campaign__c;
       partReferral.LeadSource__c = defReferral.SellingLeadSource__c;
       partReferral.CreatedByProcess__c = PART_REF_SOURCE_NAME;
       insert partReferral;
       // reselect to get the name field to populate the referrals
       partReferral = [Select Id, Name, Lead__c, Contact__c, Account__c, Referral__c
                       ,Destination__c
                       ,Source__c
                       ,CreatedDate
                       ,Master_Partner_Referral__c
                       From PartnerReferral__c
                       Where Id=:partReferral.Id];
       defReferral.PartnerReferral__c = partReferral.Id;
       // since we just reselected this can reset the flag
       partReferralNeedsUpdate = false;
   } // createPartRefFromRefPart
    
   //APR0151864: SMB Channel Evolution BAU--Start
   public void refClientChanged() {
      // only for internal referrals  partnerType = REF_INTERVAL
      system.debug('MA1--Client Referral');
       if (referringOpp.Client_Referral__c != null) {
          system.debug('MA2--Client Referral'+referringOpp.Client_Referral__c);
          Id accountOwnerUserId=checkAccountOwner(referringOpp.Client_Referral__c);
          system.debug('MA3--Client Referral'+accountOwnerUserId);
          String salesDevision=checkUserSalesDevision(accountOwnerUserId);
          system.debug('MA4--Client Referral'+salesDevision);
          if (displayList != null) {
            for (ReferralWrapper rw : displayList) {
               system.debug('MA5--Client Referral'+rw);
               if (rw.selected  && (salesDevision=='SMB Channel' || salesDevision=='SMB Virtual Channel')) {
                  system.debug('MA6--Client Referral'+rw.ref);
                  system.debug('MA6--Client Referral'+rw.ref.OwnerId);
                  system.debug('MA7--Client Referral'+rw.ref.User__c);
                  system.debug('MA8--Client Referral'+rw.displayName);
                  if(rw.displayName.contains('SMB')){
                     rw.referToUser=true;
                     rw.referToContact=false;
                     rw.ref.User__c=accountOwnerUserId;
                     system.debug('MA8--Client Referral'+rw.ref.User__c);
                  }//End of inner if
                  
                  //rw.ref.Contact__c='0034u00002nbwct';
                  //salesRepIdList.add(accountOwnerUserId);
               }//end of outer if
            }
         }
       }
       //setZipCode();
       allowActivity=true;
       changeReferTo();
   }

public static id checkAccountOwner(Id accountId){
   List<Account> lstAccount=[Select id,Ownerid  from Account where id=:accountId limit 1];
   return lstAccount[0].Ownerid;
}

public static String checkUserSalesDevision(id accountOwnerUserId){
   List<User> lstuser=[Select id,Sales_Division__c from user where id=:accountOwnerUserId limit 1];
   return lstuser[0].Sales_Division__c;
}

public static id isQueueAvailable(Id userId){
   List<User> lstUserDistrict=[Select id,District__c,District_Name__c from User where Id=:userId limit 1];
   system.debug('MA'+lstUserDistrict[0].District_Name__c);
   List<Group> lstGroup=[select Id,DeveloperName,Email,DoesIncludeBosses,Name,DoesSendEmailToMembers,Type from Group where Name=:lstUserDistrict[0].District_Name__c];
   system.debug('MA'+lstGroup[0].Name);
   return lstGroup[0].Id;
}

//APR0151864: SMB Channel Evolution BAU--End

//APR0154201 Add processbutton to P&C Quote Data--Start
public void pcQuoteData(){
   List<PC_Quote_Data__c> lstPCQuoteData=new List<PC_Quote_Data__c>();
   if(pcQuoteId!=null){
      lstPCQuoteData=[Select id,Opportunity__c,Opportunity__r.Account.Id,Do_you_have_Workers_Comp__c,Workers_Comp_Carrier_Name__c,Renewal_Date__c,Notes__c  from PC_Quote_Data__c where Id=:pcQuoteId limit 1];
   }
   if(displayList != null && lstPCQuoteData.size()>0){
      for (ReferralWrapper rw : displayList) {
         if (rw.selected){
            //String renewalDate=lstPCQuoteData[0].Renewal_Date__c.format('MM/dd/YYYY');
            String renewalDate=String.valueOf(lstPCQuoteData[0].Renewal_Date__c);
            rw.ref.Notes__c='Do you have Workers Comp? '+lstPCQuoteData[0].Do_you_have_Workers_Comp__c+' ,Workers Comp Carrier Name: '+lstPCQuoteData[0].Workers_Comp_Carrier_Name__c+' ,Renewal Date:'+renewalDate+' ,Notes: '+lstPCQuoteData[0].Notes__c;
         }   
      }//End of for
   }//End of if
}
////APR0154201 Add processbutton to P&C Quote Data--End


} // class ReferralController