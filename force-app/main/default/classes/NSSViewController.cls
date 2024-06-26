/*  
 * Give the NSRs a high level view of information around a contact/lead/account
 * 
 
 � If that record is tied to a campaign, show that first
�  If they or someone else have open activities, show that next
�  Show the reps listed in that zip code
�  Show the other contacts associated with that company
�  If they or someone else has closed activities, show then next
�  If there are any opportunities (closed or open) show those next
 
 assets also, name with start and end date
 
 Okay please see responses.  For activity history � could we bring back last 18 months of activity history?setSigni

Campaign Fields
�  Name
�  Type
�  Status
�  Product
�  Member Status Updated
Open Activity
�  Due Date
�  Task
�  Type
�  Subject
�  Status
�  Assigned To
Activity History
�  Due Date
�  Task
�  Type
�  Status
�  Assigned To
Contacts
�  Name
�  Title
�  Phone
�  Address
�  Do Not Contact (is there a checkbox not a flag)
�  Sensitivity (is there a checkbox not flag)
�  No Longer with Company
�  Significant
Opportunities
�  Opportunity Name
�  Stage
�  Run Effective Date/Closed Date
�  Product(s) Sold
�  Created Date
�  Owner Name
�  
 
 
 * History
 * -------
   07/21/2014 Dan Carmen        Created
   11/03/2016 Dan Carmen        Changes to the form to make it more usable
   01/17/2017 Dan Carmen        Added Javascript remoting to retrieve referral partners
   02/14/2017 Dan Carmen        Handle a blank start date on a campaign.
   02/21/2017 Cindy Freeman		changed to use Employees__c instead of NumberOfEmployees on account
   10/27/2017 Dan Carmen         Changes for lightning UI
   10/26/2018 Dan Carmen        Add the UITheme parameter for the NSSView component
   12/27/2018 Dan Carmen        Add in changes for qbdialer__Callback_Date_Time__c to move to DialSource
   11/14/2019 Dan Carmen        Remove qbdialer references
   08/16/2022 Josh Cartwright	updated instanceURL=Utilities.getInstanceURL(); due to enhanced domain 

 */
public without sharing class NSSViewController {
   
   public static Boolean SHOW_NEW_FORM=(Label.NSSViewShowNewForm == 'Y');

   public String recId{get;set;}
   
   public Boolean isPopup{get;set;}
    
   // the ID of the source record
   public String objectId{get;set;}
   
   public Boolean showNewForm{
      get {return SHOW_NEW_FORM;}
   }

   public String userTheme{get;set;}
   
   public Boolean oldForm{get;set;}
   
   public String instanceURL{get;set;}
      
   public NSSViewController() {
      objectId = System.currentPageReference().getParameters().get('Id');
      String oldFormStr = System.currentPageReference().getParameters().get('OldForm');
      oldForm = (String.isNotBlank(oldFormStr) && oldFormStr=='Y');
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'oldForm='+oldForm));
  //changing due to issue with enhanced domains - JC   instanceURL=Utilities.instanceURL();
      instanceURL=Utilities.getInstanceURL();
      PageReference refPage = new PageReference('/'+objectId);
      redirectUrl =  refPage.getUrl();
      
      setup();
   } // NSSViewController
      
   public void setAccess() {
      // If NSS Team HNB, keep red but remove read only.
      //If yellow and "my lockout", remove submit opportunity, but still allow for edit.
      //If inbound, always allow to save and submit - but still show colors.
      Boolean isInbound = UserHelper.isNSSInboundProf(runningUser.Profile.Name);
      Boolean isHNB = runningUser.NSS_Team__c == 'HNB' ; // how do we determine HNB?
      readOnly = (!isInbound || addingNewContact || showSubmitReferralForm);
      allowSubmit = (isInbound && !addingNewContact);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setAccess 1 isInbound='+isInbound+' isHNB='+isHNB+' readOnly='+readOnly+' allowSubmit='+allowSubmit));
      if (addingNewContact || isInbound || showSubmitReferralForm) {
         return;
      }
      readOnly = ((!isHNB && ownershipColor == colorRed) || addingNewContact);
      allowSubmit = !readOnly;
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setAccess 2 isInbound='+isInbound+' isHNB='+isHNB+' readOnly='+readOnly+' allowSubmit='+allowSubmit));
      if (ownershipColor == COLOR_YELLOW && lockoutOwnership && ownershipIsRunningUser) {
         allowSubmit = false;
      }

   } // setAccess
   
   // is there only readOnly access to the form? 
   public Boolean readOnly{get;set;}
      //get {return (showSubmitReferralForm || ownershipColor == colorRed || addingNewContact); }
   
   public Boolean allowSubmit{get;set;}
   
   public User runningUser;
   
   private void setup() {
      companySectionExpanded = true;
      ctctSectionExpanded = false;
      shouldRedirect = false;
      timeZone = null;
      ctctObjectType = '';
      nbrOtherCtcts = 0;
      
      runningUser = UserHelper.getRunningUser();
      // default the type to Prospect
      companyType = 'Prospect';
      
      String showSubmitReferral = ApexPages.currentPage().getParameters().get('nssViewSubmitRfrl');
      showSubmitReferralForm = (String.isNotBlank(showSubmitReferral) && showSubmitReferral == 'true');
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'showSubmitReferral='+showSubmitReferral));
      
   	//addingNewContact = false;
      if (!setObjectIdIsValid()) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The id passed in is not valid for this form! id='+objectId));
         return;
      }
      if (!populateIds()) {
         return;
      }
      populateData();
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'submitReferralURL='+submitReferralURL));
   } // setup
   
   public Boolean setObjectIdIsValid() {
      isObjContact = (!String.isBlank(objectId) && objectId.startsWith(ObjectHelper.PREFIX_CONTACT));
      isObjAccount = (!String.isBlank(objectId) && objectId.startsWith(ObjectHelper.PREFIX_ACCOUNT));
      isObjLead = (!String.isBlank(objectId) && objectId.startsWith(ObjectHelper.PREFIX_LEAD));
      try {
      	// verify that it's a real id
         Id recObjectId = (Id)objectId;
         objectIdIsValid = (isObjContact || isObjAccount || isObjLead);
         System.debug('setObjectIdIsValid objectIdIsValid='+objectIdIsValid+' isObjContact='+isObjContact+' isObjAccount='+isObjAccount+' isObjLead='+isObjLead);
      } catch (Exception e) {
         objectIdIsValid = false;
         System.debug('setObjectIdIsValid exception='+e.getMessage()+' '+e.getStackTraceString());
      }
      return objectIdIsValid;
   }
   
   public PageReference submitReferralURL {
      get {
         PageReference refPage = Page.Referral;
         String startedFrom = (isObjContact ? 'Contact' : (isObjLead ? 'Lead' : (isObjAccount ? 'Account' : 'Unknown')));
         refPage.getParameters().put('Id', objectId);
         refPage.getParameters().put('startedFrom', startedFrom);
         refPage.getParameters().put('IsPopup','true');
         refPage.getParameters().put('functionType','NSS');
         return refPage;
      }
   } // submitReferralURL
   
   public Boolean showSubmitReferralForm{get;set;}
   
   public PageReference toggleSubmitReferral() {
      showSubmitReferralForm = !showSubmitReferralForm;
      return null;
   } // toggleSubmitReferral
   
   
   
   /** Is the id that was passed in a valid id for this form? */
   public Boolean objectIdIsValid{get;private set;}
   
   public Boolean isObjContact {get;private set;}
   public Boolean isObjAccount {get;private set;}
   public Boolean isObjLead {get;private set;}
   
   public Boolean hasContact{get{return ctct != null;}}
   public Boolean hasAccount{get{return acct != null;}}
   public Boolean hasLead{get{return ld != null;}}
   
   private Id ctctId = null;
   private Id leadId = null;
   private Id acctId = null;
   
   public Contact ctct{get;set;}
   public Account acct{get;set;}
   public Lead ld{get;set;}
   
   public Boolean companySectionExpanded{get;set;}
   public Boolean ctctSectionExpanded{get;set;}
   
   public PageReference changeAcctSection() {
      companySectionExpanded = !companySectionExpanded;
      return null;
   } // changeAcctSection
   
   public PageReference changeCtctSection() {
      ctctSectionExpanded = !ctctSectionExpanded;
      return null;
   } // changeCtctSection
   
   // keep track of the original values to see if they change
   public OriginalValues recordOriginalValues = new OriginalValues();
   
   public Boolean isLostClient{
      get {return (acct != null && (acct.Type == Label.AccountTypeLost || acct.Lost_Date__c != null)); }
   }
   
   public String lostInfo{
      get {
         String info = (isLostClient
                           ? (((acct.Lost_Date__c != null ? acct.Lost_Date__c.format() : '')+(String.isNotBlank(acct.Reason_Lost__c) ? '-'+acct.Reason_Lost__c : '')))
                          : '');
         return info;
      }
   } // lostInfo

   public Boolean populateIds() {
      Boolean okay = true;
      recordOriginalValues = new OriginalValues();

      if (isObjLead) {
         leadId = (Id)objectId;
         setLead();
      } else if (isObjAccount) {
         acctId = (Id)objectId;
         setAccount();
      } else if (isObjContact) {
         ctctId = (Id)objectId;
         ctct = ReferralQueries.selectContact(ctctId);
         if (ctct == null) {
            okay = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error determining the Account Id from the Contact! id='+objectId));
         } else {
            setLatestCampaign(ctct.LatestCampaign__r);
         	acctId = ctct.AccountId;
         	setAccount();
         }
      }
      return okay;
   } // populateIds
   
   public String ctctObjectType{get;set;}
   public String primaryId{
      get {return (ld != null ? (String)ld.Id : (ctct != null ? (String)ctct.Id : '')); }
   }
   public String ctctRootId{ 
      get {return (ld != null ? (String)ld.Lead_Company__c : (ctct != null ? (String)ctct.AccountId : (acct != null ? (String)acct.Id : ''))); }
   }
   public Integer nbrOtherCtcts{get;set;}
   
   public Boolean setAccount() {
      acct = ReferralQueries.selectAcct(acctId);
      if (acct != null) {
         ctctObjectType = ObjectHelper.OBJECT_ACCOUNT;
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setAccount acct lost='+acct.Reason_Lost__c));
         // reduce the view state
         
         recordOriginalValues.setOriginalValues(acct);
         
         // set the other contacts
         //contactHelper = new NSSViewHelper();
         //contactHelper.allRecords = new NSSViewWrapper[]{};
         if (isLostClient) {
            companyType = Label.AccountTypeLost;
         } else if (acct.Type == Label.AccountTypeHRSOnly) {
            companyType = acct.Type;
         } else {
            Set<String> clientTypeSet = new Set<String>();
            clientTypeSet.addAll(Label.AccountTypeClient.split(';'));
            if (clientTypeSet.contains(acct.Type)) {
               companyType = 'Current Client';
            }
         }
         
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setAccount contacts='+acct.Contacts.size()));
         
         nbrOtherCtcts = 0;
         for (Contact thisCtct : acct.Contacts) {
            // if coming from the account, the first contact should be the significant contact - we'll use this as the main contact.
            // if we came from the contact, this should already be set.
            if (!thisCtct.No_Longer_With_Company__c) {
               if (ctct == null) {
                  ctct = thisCtct;
                  setLatestCampaign(ctct.LatestCampaign__r);
               } else if (ctct.Id != thisCtct.Id) {
               	// add any other contact retrieved
               //   contactHelper.allRecords.add(new NSSViewWrapper(thisCtct));
                  nbrOtherCtcts++;
               }
            } // if (!thisCtct.No_Longer_With_Company__c
         } // for (Contact thisCtct
         
         checkForSensitivities();

         // to reduce the view state
         acct.Contacts.clear();
         acct.HRS_Account_Owner__r = null;
         acct.HNBF_Account_Owner__r = null;
         acct.Premier_PBS_Account_Owner__r = null;
         acct.Banker_Name_Ref__r = null;
         acct.Broker_Name_Ref__r = null;
         //acct.CPA_Name_Ref__r = null;
         
         zipCodeToUse = (acct.SalesParent__r != null ? acct.SalesParent__r.Owner_Zip_Code__c : acct.Owner_Zip_Code__c);
         
         timeZone = (String.IsNotBlank(acct.TimeZoneAbbrev__c) ? acct.TimeZoneAbbrev__c : acct.Time_Zone__c);
         if (String.isBlank(timeZone)) {
            String phone = (ctct != null && ctct.Phone != null ? ctct.Phone : acct.Phone);
            findTimeZone(phone, acct.Owner_Zip_Code__c);
         }
         
      } // if (acct != null
      return (acct != null);
   } // setAccount
   
   public void findTimeZone(String phone, String zip) {
      if (String.isBlank(timeZone) && String.isNotBlank(phone)) {
         // strip out all non-numeric characters
         String phoneNbrsOnly = Utilities.removeExtraChars(phone,Utilities.ALL_NUMBERS);
         // as long as there are at least 10 number (area code + phone number), assume the first 3 are the area code.
         if (phoneNbrsOnly.length() >= 10) {
            String areaCode = phoneNbrsOnly.left(3);
            try {
               AreaCode__c ac = [Select Id, Name, TimeZoneName__c, TimeZoneAbbrev__c from AreaCode__c where Name = :areaCode];
               timeZone = ac.TimeZoneAbbrev__c;
            } catch (Exception e) {
               // don't need to do anything here
            }
         }
         
      } // if (String.isBlank(timeZone) && String.isNotBlank(phone
      
      if (String.isBlank(timeZone) && String.isNotBlank(zip)) {
         // make sure 5 digit zip
         String zipCheck = ZipCodeInformation.format5DigitZip(zip);
         try {
            Zip_Code_Information__c zci = [Select Id, Name, TimeZoneAbbrev__c, TimeZoneName__c from Zip_Code_Information__c where Name = :zipCheck];
            timeZone = zci.TimeZoneAbbrev__c;
         } catch (Exception e) {
            // don't need to do anything here
         }
      }
   } // findTimeZone
   
   public Boolean setLead()  {
      NSSViewHelper contactHelper = new NSSViewHelper();
      contactHelper.allRecords = NSSViewHelper.getLeads(leadId);
      ld = NSSViewHelper.primaryLead;
      nbrOtherCtcts = contactHelper.allRecords.size();
      // clear out view state
      contactHelper.allRecords.clear();
      
      if (ld != null) {
         ctctObjectType = ObjectHelper.OBJECT_LEAD;
         recordOriginalValues.setOriginalValues(ld);
         setLatestCampaign(ld.LatestCampaign__r);
         findTimeZone(ld.Phone, ld.PostalCode);
         zipCodeToUse = ZipCodeInformation.format5DigitZip(ld.PostalCode);
      } // if (ld != null
      return (ld != null);
   } // setLead
   
   public String zipCodeToUse{get;set;}
   
   public Boolean populateData() {
   	Boolean okay = true;
   	handleOwnership();
   	checkForSensitivities();
   	
   	if (!oldForm) {
      	//if (!showSubmitReferralForm) {
         //   handleReferralPartners();
   	   //}
         if (Test.isRunningTest()) {
            handleCampaigns();   //Temporarily comment this out. Users aren't sure they need/want this.
   	   }
         handleActivity();
         //handleContacts();
         handleOpportunities();
         handleAssets();
         setAccess();
   	} // if (!oldForm
   	return okay;
   } // populateData

   public Boolean showErrorSection{
      get {return (!objectIdIsValid); }
   }

   public void setLatestCampaign(Campaign camp) {
      if (camp != null && latestCampaign == null && camp.IsActive) {
         // if outbound rep, only show campaign if start date is within 90 days
         Boolean isOutbound = (runningUser == null || !UserHelper.isNSSOutboundProf(runningUser.Profile.Name));
         if (!isOutbound || (camp.StartDate != null && camp.StartDate >= Date.today().addDays(-90))) {
            latestCampaign = camp;
         }
      }
   } // setLatestCampaign
   
   public Boolean hasDoNotCall{
      get {
         return ((ld != null && ld.DoNotCall)
                   || (acct != null && acct.Do_Not_Call__c)
                   || (ctct != null && ctct.DoNotCall)
                );
      } // get
   } // hasDoNotCall
   
   public Boolean hasOptOut{
      get {
         Boolean optOut = ((ld != null && (ld.DoNotCall || ld.HasOptedOutOfEmail))
                           || (acct != null && (acct.Do_Not_Call__c || acct.Email_Opt_Out__c))
                           || (ctct != null && (ctct.DoNotCall || ctct.HasOptedOutOfEmail))
                          );
         return optOut;
      }
   } // hasOptOut
   
   public String optOutMsg {
      get {
         String msg = '';
         if (ld != null) {
            msg = buildOptOutMsg(ld.Name, ld.DoNotCall, ld.HasOptedOutOfEmail);
         } else if (acct != null && (acct.Do_Not_Call__c || acct.Email_Opt_Out__c)) {
            msg = buildOptOutMsg(acct.Name, acct.Do_Not_Call__c, acct.Email_Opt_Out__c);
         } else if (ctct != null) {
            msg = buildOptOutMsg(ctct.Name, ctct.DoNotCall, ctct.HasOptedOutOfEmail);
         }
         return msg;
      }
   } // optOutMsg
   
   public String buildOptOutMsg(String name, Boolean doNotCall, Boolean doNotEmail) {
      String msg = '';
      if (doNotCall) {
         msg += 'Do Not Call';
      }
      if (doNotEmail) {
         if (String.isNotBlank(msg)) {
            msg +=' and ';
         }
         msg += 'Do Not Email';
      }
      return name+': '+msg;      
   } // buildOptOutMsg
   
   public Campaign latestCampaign = null;

   public Boolean hasLatestCampaign{
      get { return (latestCampaign != null); }
   }
   
   public String campaignMsg{
      get { return latestCampaign.Name+(latestCampaign.StartDate != null ? ', Start Date: '+latestCampaign.StartDate.format() : ''); }
   }
   public static Integer NBR_MONTHS=Integer.valueOf(Label.NSS_View_Nbr_Months);
      
   public String companyType {get;set;}
   
   public Boolean hasOwnershipMsg{
      get {return String.isNotBlank(ownershipMsg); }
   }
   
   public String controllerTheme{
      get {return UserInfo.getUIThemeDisplayed();}
   }
   
   public Boolean showMainForm {
      get {
         Boolean displayOnRedirect = (!shouldRedirect || (shouldRedirect && String.isNotBlank(userTheme) && userTheme == 'Theme4u'));
        return (displayOnRedirect && objectIdIsValid && showNewForm && !addingNewContact);
   //     return (objectIdIsValid && showNewForm && !addingNewContact);
   //     return !shouldRedirect && objectIdIsValid && showNewForm && !addingNewContact;
     }
   }
   
   public Boolean showAddContactForm {
      get {return objectIdIsValid && showNewForm && addingNewContact; }
   }
   
   public String timeZone{get;set;}
      
   public Boolean hasTimeZone{
      get {return String.IsNotBlank(timeZone);}
   }
   
   public String ownershipMsg{get; set;}
   
   public Boolean showKeyInfo{
      get {return showMainForm && (hasOwnershipMsg || hasSensitivities || hasCallbacks || hasLatestCampaign || hasOptOut || hasTimeZone || isLostClient || showLatestPayOpp);}
   } // showKeyInfo
   
   public Boolean showLatestPayOpp {
      get {
         return (acct != null && acct.LastPayrollOppCreated__c != null && acct.LastPayrollOppCreated__c >= Date.today().addDays(-90));
      }
   } // showLatestPayOpp
   
   public String lastestPayOppDate {
      get { return (acct != null && acct.LastPayrollOppCreated__c != null ? acct.LastPayrollOppCreated__c.format('M/d/yyyy hh:mm a') : ''); }
   } // lastestPayOppDate
   
   public Boolean ownershipIsRunningUser{get;set;}
   public Boolean prospectingOwnership{get;set;}
   public Boolean lockoutOwnership{get;set;}
   public Boolean notInterestedOwnership{get;set;}
   
   public static String COLOR_GREEN=Label.NSSView_Green;
   public static String COLOR_YELLOW=Label.NSSView_Yellow;
   public static String COLOR_RED=Label.NSSView_Red;
   
   public String colorRed{
      get {return COLOR_RED;}
   }
   
   public String ownershipColor{
      get {
         String color='';
         if (hasOwnershipMsg) {
            if (ownershipIsRunningUser && prospectingOwnership) {
               color=COLOR_GREEN;
            } else if ((!ownershipIsRunningUser && prospectingOwnership) 
                       || (ownershipIsRunningUser && lockoutOwnership)
                       || notInterestedOwnership) {
               color=COLOR_YELLOW;
            } else if (hasDoNotCall || (!ownershipIsRunningUser && lockoutOwnership)) {
               color=COLOR_RED;
            }
         } // if (hasOwnershipMsg
         return color;
      } // get
   } // ownershipColor
   
   public static String FONT_NORMAL='10pt';
   public static String FONT_YELLOW_RED='12pt';
   
   public String ownershipFontSize{
      get {
         String fontSize=FONT_NORMAL;
         String color = ownershipColor;
         if (String.isNotBlank(color) && (color == COLOR_YELLOW || color == COLOR_RED)) {
            fontSize = FONT_YELLOW_RED;
         }
         return fontSize;
      }
   } // ownershipFontSize
   
   // are there open prospect ownership records?
   public Boolean handleOwnership() {
      Boolean okay = true;
      ownershipIsRunningUser = false;
      prospectingOwnership = false;
      lockoutOwnership = false;
      notInterestedOwnership = false;
      
      Prospect_Ownership__c[] owners = null;
      if (isObjLead) {
         Map<Id,Prospect_Ownership__c> leadIdMap = ProspectOwnershipMethods.getMapByLeadIds(new Set<Id>{leadId},ProspectOwnershipMethods.NSR_FIELDS);
         if (!leadIdMap.isEmpty()) {
            owners = new Prospect_Ownership__c[]{leadIdMap.get(leadId)};
         }
      } else if (isObjAccount || isObjContact) {
         Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(new Set<Id>{acctId}, true, null, null,ProspectOwnershipMethods.NSR_FIELDS);
         owners = acctOwnerMap.get(acctId);
      }
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'handleOwnership owners='+owners));
      ownershipMsg = '';
      if (owners != null) {
         Set<String> nsrNameSet = new Set<String>();
         for (Prospect_Ownership__c po : owners) {
            nsrNameSet.add(po.NSR_Name__r.Name+' ('+po.NSS_Source__c+'-'+po.Ownership_Status__c+', '+po.DaysLeftInStage__c+' days remaining)');
            if (po.NSR_Name__c == runningUser.Id) {
               ownershipIsRunningUser = true;
            }
            if (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_PROSPECTING) {
               prospectingOwnership = true;
            } else if (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_LOCKOUT) {
               lockoutOwnership = true;
            } else if (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_NO_INTEREST) {
               notInterestedOwnership = true;
            }
            
         } // for (Prospect_Ownership__c po
         
         ownershipMsg = '';
         for (String nsrName : nsrNameSet) {
            if (String.isNotBlank(ownershipMsg)) {
               ownershipMsg += ' \n';
            }
         	
         	ownershipMsg += Label.NSS_View_Owner_Msg+' '+nsrName;
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'handleOwnership ownershipMsg='+ownershipMsg));
         }
      } // if (owners
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'handleOwnership hasOwnershipMsg='+hasOwnershipMsg));
      return okay;
   } // handleOwnership
   
   public Boolean handleCampaigns() {
   	Boolean okay = true;
   	campaignHelper = new NSSViewHelper();
   	campaignHelper.allRecords = NSSViewHelper.getCampaigns((leadId != null ? leadId : ctctId), acctId);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Number of campaigns='+(campWrappers != null ? campWrappers.size() : -1)));
      return okay;
   } // handleCampaigns

   public NSSViewHelper campaignHelper{get;set;}
   
   // is there campaign data for the page
   public Boolean hasCampaignData{
      get {return (campaignHelper != null && campaignHelper.hasRecords); }
//      get {return (campWrappers != null && !campWrappers.isEmpty()); }
   } // hasCampaignData
   
   public Boolean hasCallbacks{
      get {return callbacks != null && !callbacks.isEmpty(); }
   } // hasCallbacks
   public CallbackWrapper[] callbacks {get;set;}
   
   public PageReference closeCallback() {
      String tskId = System.currentPageReference().getParameters().get('tskId');
      String closeStatus = System.currentPageReference().getParameters().get('closeStatus');
      System.debug('closeCallback tskId='+tskId+' closeStatus='+closeStatus);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'closeCallback tskId='+tskId+' closeStatus='+closeStatus));
      try {
         Task tsk = new Task(Id=tskId, Status=closeStatus);
         update tsk;
         handleActivity();
      } catch (Exception e) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Error Updating Callback! '+e.getMessage()));
      }
      return null;
   } // closeCallback
   
   public Boolean handleActivity() {
      Boolean okay = true;

      myActivityHelper = new NSSViewHelper();
      otherActivityHelper = new NSSViewHelper();
      
      Id[] whoIds = new Id[]{};
      Id[] acctIds = new Id[]{};
      if (isObjLead) {
      	whoIds.add(leadId);
      } else if (isObjAccount || isObjContact) {
         acctIds.add(acctId);
      }
      Map<String,List<NSSViewWrapper>> activityMap = NSSViewHelper.getActivity(whoIds,acctIds,runningUser.Id,NBR_MONTHS, 20);
      
      callbacks = null;
      if (!NSSViewHelper.callbackTasks.isEmpty()) {
         callbacks = new CallbackWrapper[]{};
         for (Task tsk : NSSViewHelper.callbackTasks) {
            callbacks.add(new CallbackWrapper(tsk, runningUser.Id));
         }
      } // if (!NSSViewHelper.callbackTasks

      myActivityHelper.allRecords = activityMap.get(NSSViewHelper.MY_ACTIVITY);
      otherActivityHelper.allRecords = activityMap.get(NSSViewHelper.OTHER_ACTIVITY);
      return okay;
   } // handleActivity
   
   public NSSViewHelper myActivityHelper{get;set;}
   public NSSViewHelper otherActivityHelper{get;set;}
   
   // is there my activity?
   public Boolean hasMyActivity{
      get {return (myActivityHelper != null && myActivityHelper.hasRecords); }
   }

   // is there other activity?
   public Boolean hasOtherActivity{
      get {return (otherActivityHelper != null && otherActivityHelper.hasRecords); }
   }

/*
   public Boolean handleContacts() {
      Boolean okay = true;
      //contactHelper = new NSSViewHelper();
      if (isObjLead) {
//         contactHelper = new NSSViewHelper();
//         contactHelper.allRecords = NSSViewHelper.getOtherLeads(leadId);
      } else if (isObjContact || isObjAccount) {
         //contactHelper.allRecords = NSSViewHelper.getOtherContacts(acctId,ctctId);
      }
      return okay;
   } // handleContacts
*/
   //public NSSViewHelper contactHelper{get;set;}
      
   // does this have extra contacts/leads
   //public Boolean hasContacts {
   //   get {return (contactHelper != null && contactHelper.hasRecords); }
   //}
   
   public Boolean hasOtherCtcts{
      get {return nbrOtherCtcts != null && nbrOtherCtcts > 0;}
   }
   
   public Boolean handleOpportunities() {
      hasOpps = false;
      if (acctId != null) {
         // see if there are any opportunities in the time period to display the section.
         Date selectDate = Date.today().addMonths(-NBR_MONTHS);
         hasOpps = ([Select count() from Opportunity where AccountId = :acctId and CloseDate >= :selectDate limit 1] > 0);
      }
      Boolean okay = true;
      //opportunityHelper = new NSSViewHelper();
      //if (isObjContact || isObjAccount) {
      //	opportunityHelper.allRecords = NSSViewHelper.getOpportunities(acctId);
      //}
      return okay;
   } // handleOpportunities

   //public NSSViewHelper opportunityHelper{get;set;}
   
   //public Boolean hasOpportunities {
   //   get {return (opportunityHelper != null && opportunityHelper.hasRecords); }
   //}
   
   public Boolean hasOpps{get;set;}
   

   //public NSSViewHelper assetHelper{get;set;}
   /*
   public NSSViewHelper activeAssets{get;set;}
   public NSSViewHelper inactiveAssets{get;set;}

   public Boolean hasActiveAssets{
      get {return (activeAssets != null && activeAssets.hasRecords); }
   }
   
   public Boolean hasInactiveAssets{
      get {return (inactiveAssets != null && inactiveAssets.hasRecords); }
   }
   
   public Boolean showActiveAssets{get;set;}
   public Boolean showInactiveAssets{get;set;}
   
   public PageReference toggleActiveAssets() {
      showActiveAssets = !showActiveAssets;
      return null;
   } // toggleActiveAssets
   
   public PageReference toggleInactiveAssets() {
      showInactiveAssets = !showInactiveAssets;
      return null;
   } // toggleInactiveAssets
   
   public Boolean hasAssets {
      get {return (hasActiveAssets || hasInactiveAssets); }
   }
   */
   public Boolean hasAssets2{get;set;}
   
   public Integer activeProdCnt{get;set;}
   public Integer inactiveProdCnt{get;set;}

   public Boolean handleAssets() {
      Boolean okay = true;
      //showActiveAssets = false;
      //showInactiveAssets = false;
      hasAssets2 = false;
      
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'handleAssets acctId='+acctId));
      //assetHelper = new NSSViewHelper();
      if (acctId != null) {
         hasAssets2 = NSSViewHelper.hasAssets(acctId);
         if (hasAssets2) {
            activeProdCnt = [select count() from Asset where AccountId = :acctId and Plan_Cancel_Date__c = null];
            inactiveProdCnt = [select count() from Asset where AccountId = :acctId and Plan_Cancel_Date__c != null];
         }
         //assetHelper = new NSSViewHelper();
         //activeAssets = new NSSViewHelper();
         //inactiveAssets = new NSSViewHelper();
         /*
         NSSViewWrapper[] records = NSSViewHelper.getAssets(acctId,30);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'handleAssets records='+records.size()));
         for (NSSViewWrapper nvw : records) {
            if (nvw.asst.Plan_Cancel_Date__c == null) {
               activeAssets.allRecords.add(nvw);
            } else {
               inactiveAssets.allRecords.add(nvw);
            }
         }*/
      } // if (acctId != null
      return okay;
   } // handleAssets
   
   public static String ACTIVE='Active';
   public static String INACTIVE='Inactive';
   

   public void checkForSensitivities() {
      sensitivityList = '';
      if (ld != null) {
         if (ld.Referral_Contact__r != null && String.isNotBlank(ld.Referral_Contact__r.Sensitivity_List__c)) {
            sensitivityList = ld.Referral_Contact__r.Sensitivity_List__c;
         }
         if (ld.Referral_National_Account__r != null && String.isNotBlank(ld.Referral_National_Account__r.Sensitivity_List__c)) {
            sensitivityList += ld.Referral_National_Account__r.Sensitivity_List__c;
         }
      } else if (acct != null) {
         if (acct.CPA_Name_Ref__r != null && String.isNotBlank(acct.CPA_Name_Ref__r.Sensitivity_List__c)) {
            sensitivityList = acct.CPA_Name_Ref__r.Sensitivity_List__c;
         }
      } else if (ctct != null && ctct.Referral_Contact__r != null) {
         sensitivityList = ctct.Referral_Contact__r.Sensitivity_List__c;
      }
   } // checkForSensitivities

   /*
   public void checkForCpaSensitivities() {
      Referral_Contact__c refContact = null;
      cpaSensitivityList = null;
      if (ld != null && ld.Referral_Contact__r != null) {
         cpaSensitivityList = ld.Referral_Contact__r.Sensitivity_List__c;
      } else if (acct != null && acct.CPA_Name_Ref__r != null) {
         cpaSensitivityList = acct.CPA_Name_Ref__r.Sensitivity_List__c;
      } else if (ctct != null && ctct.Referral_Contact__r != null) {
         cpaSensitivityList = ctct.Referral_Contact__r.Sensitivity_List__c;
      }
   } // checkForCpaSensitivities
   */
   public Boolean hasSensitivities{
      get { return String.isNotBlank(sensitivityList);}
   }
   
   public String sensitivityList{get; private set;}
   
   public String significantId{get; set;}
   
   public PageReference changeSignificance() {
      Id recordId = (Id)System.currentPageReference().getParameters().get('SignificantId');
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'changeSignificance! param significantId='+recordId));
      System.debug('changeSignificance recordId='+recordId);
      return processChangeSignificance(recordId);
      //return null;
      
   } // changeSignificance
   
   public PageReference processChangeSignificance(Id recordId) {
      System.debug('processChangeSignificance recordId='+recordId);
      if (recordId != null) {
         if (isObjLead) {
      	   // change significance on the lead company
      	   Lead_Company__c leadCompany = new Lead_Company__c(Id=ld.Lead_Company__c, SignificantLead__c=recordId);
      	   // save the record, then requery the form to reflect the new significant lead
      	   try {
      	   	LeadCompanyMethods.CALCULATE_SIGNIFICANCE = false;
      	   	System.debug('processChangeSignificance updating lead significance ld.Lead_Company__c='+ld.Lead_Company__c);
      	      update leadCompany;
      	      objectId = recordId;
      	      setup();
      	   } catch (Exception e) {
               ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error changing Significant Lead: '+e));
      	   }
         } else {
            Account updateAcct = new Account(Id=acctId, SignificantContact__c=recordId);
            // save the record, then requery the form to reflect the new significant contact
            try {
               AccountMethods.CALCULATE_SIGNIFICANCE = false;
               System.debug('processChangeSignificance updating account significance acctId='+acctId);
               update updateAcct;
               objectId = recordId;
               setup();
            } catch (Exception e) {
               ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error changing Significant Contact: '+e));
            }
         }
      } // if (recordId != null
      return null;
   } // processChangeSignificance
   
   public PageReference saveRecordChanges() {
      saveRecordChanges(true);
      return null;
   } // saveRecordChanges
   
   // save the changes to the lead or contact/account 
   public Boolean saveRecordChanges(Boolean requeryPartners) {
   	// if pertinent information changes (i.e. NumberOfEmployees, zip) we'll requery the 
   	Boolean okay = true;
   	if (isObjLead) {
   		// check if the values changed
   		recordOriginalValues.setNewValues(ld);
   		
   	   try {
            LeadCompanyMethods.CALCULATE_SIGNIFICANCE = false;
            update ld;
   	   } catch (Exception e) {
   	   	okay = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error saving the lead record: '+e));
   	   }
   	} else {
   	   // reset the owner zip code field to se if there's a change.
   	   AccountMethods.checkZipFields(acct,null);
   	   // this is a contact/account combination
         recordOriginalValues.setNewValues(acct);
         try {
            AccountMethods.CALCULATE_SIGNIFICANCE = false;
            update acct;
            update ctct;
         } catch (Exception e) {
         	okay = false;
         	System.debug('saveRecordChanges exception: '+e.getMessage()+'; '+e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error saving the account and contact record: '+e));
         }
   	} // if (isObjLead
   	
   	//if (okay && requeryPartners && recordOriginalValues.valuesChanged()) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Requeried Referral Partners'));
   		// requery the referral partners if the pertinent information changes.
   	//   handleReferralPartners();
   	//}
   	recordOriginalValues.resetOriginalValues();
   	
      return okay;
   } // saveRecordChanges
   
   // keep track of the original values to see if they change
   public class OriginalValues {
      public Integer numberOfEmployees = null;
      public Integer newNumberOfEmployees = null;
      
      public void setOriginalValues(Lead ld) {
         numberOfEmployees = ld.NumberOfEmployees;
         postalCode = ld.PostalCode;
      } // setOriginalValues

      public void setOriginalValues(Account acct) {
         //numberOfEmployees = acct.NumberOfEmployees;
         numberOfEmployees = (Integer)acct.Employees__c;
         postalCode = acct.Owner_Zip_Code__c;
      } // setOriginalValues

      public void setNewValues(Lead ld) {
         newNumberOfEmployees = ld.NumberOfEmployees;
         newPostalCode = ld.PostalCode;
      } // setNewValues
      
      public void setNewValues(Account acct) {
         //newNumberOfEmployees = acct.NumberOfEmployees;
         newNumberOfEmployees = (Integer)acct.Employees__c;
         newPostalCode = acct.Owner_Zip_Code__c;
      } // setNewValues

      public String postalCode = null;
      public String newPostalCode = null;
      
      public Boolean valuesChanged() {
         return ((numberOfEmployees != newNumberOfEmployees)
                  || (postalCode != newPostalCode));
      } // valuesChanged
      
      // after a save of the record use the new values
      public void resetOriginalValues() {
         numberOfEmployees = newNumberOfEmployees;
         newNumberOfEmployees = null;
         
         postalCode = newPostalCode;
         newPostalCode = null;
      } // resetOriginalValues
   } // OriginalValues
   
   public Boolean addingNewContact{
      get {return (newLead != null || newContact != null); }
   }
   
   public Boolean addingSignificantContact{get;set;}
   
   public Lead newLead{get;set;}
   public Contact newContact{get;set;}
   
   public PageReference addNewContact() {
   	addingSignificantContact = false;
   	if (isObjLead) {
   	   newLead = ld.clone(false,false);
   	   newLead.Title = null;
   	   newLead.Salutation = null;
   	   newLead.FirstName = null;
   	   newLead.LastName = null;
   	   newLead.Phone = null;
   	   newLead.Email = null;
   	} else {
   	   if (ctct != null) {
            newContact = ctct.clone(false,false);
   	   } else {
   	      // default to the core contact record type
   	      // TODO - set to match the record type of the account
   	      Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
   	      newContact = new Contact(AccountId=acctId, RecordTypeId=(rtInfo != null ? rtInfo.getRecordTypeId() : null), Use_Zip_Assignment_Rules__c=true);
   	   }
   	   newContact.Title = null;
         newContact.Salutation = null;
         newContact.FirstName = null;
         newContact.LastName = null;
         newContact.Phone = null;
         newContact.Email = null;
   	}
      return null;
   } // addNewContact
   
   public PageReference saveNewContact() {
      Boolean okay = true;
      Id newRecId = null;
      if (newLead != null) {
         try {
            insert newLead;
            newRecId = newLead.Id;
            if (addingSignificantContact) {
               processChangeSignificance(newLead.Id);
            } else {
            	// requery the main data for the additional contact to show in the list.
               populateIds();
            }
         } catch (Exception e) {
         	okay = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error creating a new contact: '+e));
         }
      } else if (newContact != null) {
         try {
            insert newContact;
            newRecId = newContact.Id;
            if (addingSignificantContact) {
               processChangeSignificance(newContact.Id);
            } else {
               // requery the main data for the additional contact to show in the list.
               populateIds();
            }
         } catch (Exception e) {
            okay = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error creating a new contact: '+e+'; '+e.getStackTraceString()));
         }
      }

      if (okay) {
         newLead = null;
         newContact = null;
      }
      if (newRecId != null) {
         shouldRedirect = true;
         PageReference refPage = new PageReference('/'+newRecId);
         redirectUrl =  refPage.getUrl();
      }
      return null;
   } // saveNewContact
   
   public PageReference cancelNewContact() {
      newLead = null;
      newContact = null;
      return null;
   } // cancelNewContact

/*
   public PageReference submitReferral() {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'submitReferral entered'));
      if (saveRecordChanges(false)) {
         PageReference refPage = Page.Referral;
         refPage.setRedirect(true);
         String startedFrom = (isObjContact ? 'Contact' : (isObjLead ? 'Lead' : (isObjAccount ? 'Account' : 'Unknown')));
         refPage.getParameters().put('Id', objectId);
         refPage.getParameters().put('startedFrom', startedFrom);
         String popupValue = (isPopup != null || isPopup ? 'true' : 'false');
         refPage.getParameters().put('IsPopup','false');
         refPage.getParameters().put(ReferralController.PARAM_FUNCTION,'NSS');
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'submitReferral refPage='+refPage));
         return refPage;
      }
      return null;
   } // submitReferral
*/
   public PageReference submitReferral2() {
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'submitReferral entered'));
      if (saveRecordChanges(false)) {
         PageReference refPage = setPageParameters(new PageReference('/'+objectId));
         //refPage.setRedirect(true);
         //String startedFrom = (isObjContact ? 'Contact' : (isObjLead ? 'Lead' : (isObjAccount ? 'Account' : 'Unknown')));
         //refPage.getParameters().put('Id', objectId);
         //refPage.getParameters().put('startedFrom', startedFrom);
         //String popupValue = (isPopup != null || isPopup ? 'true' : 'false');
         //refPage.getParameters().put('IsPopup','false');
         //refPage.getParameters().put(ReferralController.PARAM_FUNCTION,'NSS');
         //refPage.getParameters().put('nssViewSubmitRfrl','true');
         refPage.getParameters().put(ReferralController.PARAM_EMBEDDED,'true');
         refPage.getParameters().put('inline','1');
         redirectUrl =  refPage.getUrl();
         shouldRedirect = true;
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'submitReferral refPage='+refPage));
         //return refPage;
      }
      return null;
   } // submitReferral

   public PageReference submitReferralLightning() {
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'submitReferral entered'));
      if (saveRecordChanges(false)) {
         PageReference refPage = setPageParameters(Page.Referral);
         //refPage.setRedirect(true);
         //String startedFrom = (isObjContact ? 'Contact' : (isObjLead ? 'Lead' : (isObjAccount ? 'Account' : 'Unknown')));
         //refPage.getParameters().put('Id', objectId);
         //refPage.getParameters().put('startedFrom', startedFrom);
         //String popupValue = (isPopup != null || isPopup ? 'true' : 'false');
         //refPage.getParameters().put('IsPopup','false');
         //refPage.getParameters().put(ReferralController.PARAM_FUNCTION,'NSS');
         //refPage.getParameters().put('nssViewSubmitRfrl','true');
         //refPage.getParameters().put(ReferralController.PARAM_EMBEDDED,'true');
         //refPage.getParameters().put('inline','1');
         redirectUrl =  refPage.getUrl();
         shouldRedirect = true;
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'submitReferral refPage='+refPage));
         //return refPage;
      }
      return null;
   } // submitReferral
   
   public PageReference setPageParameters(PageReference refPage) {
      refPage.setRedirect(true);
      String startedFrom = (isObjContact ? 'Contact' : (isObjLead ? 'Lead' : (isObjAccount ? 'Account' : 'Unknown')));
      refPage.getParameters().put('Id', objectId);
      refPage.getParameters().put('startedFrom', startedFrom);
      String popupValue = (isPopup != null || isPopup ? 'true' : 'false');
      refPage.getParameters().put('IsPopup','false');
      refPage.getParameters().put(ReferralController.PARAM_FUNCTION,'NSS');
      refPage.getParameters().put('nssViewSubmitRfrl','true');
      return refPage;
   } // setPageParameters

   public Boolean shouldRedirect {public get; private set;}
   public String redirectUrl {public get; private set;}

   public PageReference cancelSubmitReferral() {
      PageReference refPage = new PageReference('/'+objectId);
      refPage.setRedirect(true);
      refPage.getParameters().put('Id', objectId);
      redirectUrl =  refPage.getUrl();
      shouldRedirect = true;
      return null;
   } // cancelSubmitReferral


   public class CallbackWrapper {
      public CallbackWrapper(Task p_tsk, Id runningUserId) {
         tsk = p_tsk;
         ownedByRunningUser = (runningUserId == tsk.OwnerId);
      }
      public Task tsk{get;set;}
      public Boolean ownedByRunningUser{get;set;}
      public String callbackInfo{
         get {
            Datetime cbTime = tsk.ReminderDateTime;
            if (cbTime == null) {
               // default to 8am on the activity date if datetime field isn't set
               cbTime = Datetime.newInstance(tsk.ActivityDate, Time.newInstance(8,0,0,0));
            }
            return 'Open Callback for '+tsk.Owner.Name+': '+cbTime.format('M/d/yyyy @h:mm a');
         }
      } // callbackInfo
      
   } // class CallbackWrapper
   
} // class NSSViewController