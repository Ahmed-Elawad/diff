/**
* ----------------------------------------------------------------------- 
* The Refer Client functionality for CPA Program
* History
* ------------------------------------------------------------------------
* 03/20/2023 Vinay               Cleaned up the code to avoid logic which
                                 is noy needed in the contrsuctor. Added code
                                 to handle the creation of Partner Referal when
                                 the code is executed by guest site.
* -------------------------------------------------------------------------
*
*/
public without sharing class ReferClientCtrl {
  public String FirstName { get; set; }
  public String LastName { get; set; }
  public String Email { get; set; }
  public String Phone { get; set; }
  public String Company { get; set; }
  public String PostalCode { get; set; }
  public boolean isShowModelPopup1 { get; set; }
  public boolean isShowModelPopup2 { get; set; }
  public boolean DisplayPopup { get; set; }
  public boolean isShowModelError { get; set; }
  public boolean isDisplayedOnCPAPortal {get; set;}
  public Boolean showPersonalURLPopup {get; set;}
  public String customURL {get; set;}
  public boolean showLinkIcon {get;set;}
  public boolean isAdminCPA {get;set;}
  public boolean showInviteCPAPopup {get; set;}
  public String cpaInviteFirstName { get; set; }
  public String cpaInviteLastName { get; set; }
  public String cpaInviteEmail { get; set; }
  public String cpaInvitePhone { get; set; }
  public String cpaInviteNotes {get; set; }

  public ReferClientCtrl() {
    if(String.isBlank(ApexPages.currentPage().getParameters().get('ContactId'))) {
      this.isDisplayedOnCPAPortal = true;
      Site mySite = [SELECT Id FROM Site WHERE Name = 'CPA_Referrals' LIMIT 1];
      SiteDetail mySiteDetail = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :mySite.Id LIMIT 1];
      System.debug(mySiteDetail.SecureURL);
      String uniqueContactId;
      Boolean adminCPA;
      if (!Test.isRunningTest()) {
        uniqueContactId = [SELECT Contact_ID__c FROM Contact where Id =: UserHelper.getRunningUser().ContactId limit 1].Contact_ID__c;
        adminCPA = [SELECT Mirror_Ref_Ctct__r.Admin_CPA__c FROM Contact where Id =: UserHelper.getRunningUser().ContactId limit 1].Mirror_Ref_Ctct__r.Admin_CPA__c;
        if(adminCPA == true) {
          this.isAdminCPA = true;
        } else {
          this.isAdminCPA = false;
        }
      }
      this.customURL = mySiteDetail.SecureURL+'?ContactId='+uniqueContactId;
    } else {
      this.isDisplayedOnCPAPortal = false;
    }

    this.isShowModelPopup1 = true;
    this.isShowModelPopup2 = false;
    this.showPersonalURLPopup = false;
  }

  public void save() {
    if (!String.isBlank(ApexPages.currentPage().getParameters().get('ContactId'))) {
      createReferralAsGuest(ApexPages.currentPage().getParameters().get('ContactId'));
    } else {
      createReferralAsClient();
    }
  }

  public void inviteCPAWindow() {
    this.isShowModelPopup1 = false;
    this.isShowModelPopup2 = false;
    this.showPersonalURLPopup = false;
    this.showInviteCPAPopup = true;
  }

  public Pagereference redirectToCustomURL() {
    PageReference pageRef = new PageReference(this.customURL);
    pageRef.setRedirect(true);
    return pageRef;
  }

  public void handlePersonalLink() {
    this.showPersonalURLPopup = true;
    this.isShowModelPopup1 = false;
    this.isShowModelPopup2 = false;
  }
  public void showLinkIcon(){
      this.showLinkIcon = true;
  }
  public void handleInviteCPA() {
    //Contact ReferralContact = [Select Name, Id, AccountId, Contact_ID__c from Contact where Id =: UserHelper.getRunningUser().ContactId limit 1];
    List<Id> usersToMentionInChatter = new List<Id>();
    Contact loggedInContact = [SELECT
      Mirror_Ref_Ctct__c, Mirror_Ref_Ctct__r.Referral_Account__c, Mirror_Ref_Ctct__r.Referral_Account__r.OwnerId FROM Contact where Id =: UserHelper.getRunningUser().ContactId limit 1
    ];
    usersToMentionInChatter.add(loggedInContact.Mirror_Ref_Ctct__r.Referral_Account__r.OwnerId);

    // Id refAccId = [SELECT
    //   Mirror_Ref_Ctct__r.Referral_Account__c FROM Contact where Id =: UserHelper.getRunningUser().ContactId limit 1
    // ].Mirror_Ref_Ctct__r.Referral_Account__c;

    //Referral_Account__c refAcc = [SELECT Id FROM Referral_Account__c WHERE Id =: refAccId];
    //ContactId = ReferralContact.Contact_ID__c != null? ReferralContact.Contact_ID__c: null;
    //String refContactId = ReferralContact.Id;
    //String AccountId = ReferralContact.AccountId;
    try {
      Partner_Portal_User_Details__c prfobj = new Partner_Portal_User_Details__c();
      prfobj.First_Name__c = cpaInviteFirstName;
      prfobj.Last_Name__c = cpaInviteLastName;
      prfobj.Email__c = cpaInviteEmail;
      prfobj.Phone__c = cpaInvitePhone;
      prfobj.Notes__c = cpaInviteNotes;
      
      prfobj.Event__c = 'Admin Invite';
      prfobj.Referral_Account__c = loggedInContact.Mirror_Ref_Ctct__r.Referral_Account__c;
      prfobj.Referral_Contact__c = loggedInContact.Mirror_Ref_Ctct__c;
      prfobj.Request_Date__c = System.now();

      insert prfobj;

      this.showInviteCPAPopup = false;
      this.showPersonalURLPopup = false;
      this.isShowModelPopup1 = true;
      this.isShowModelPopup2 = false;

      String notesForChatter = '';
      if(cpaInviteNotes != null && cpaInviteNotes != '') {
        notesForChatter = cpaInviteNotes;
      }
      List<String> postText = new List<String>{
        '\n New CPA is requesting to be enrolled into the CPA Referral Program. Please review and invite: \n',
        '\n First Name: '+ cpaInviteFirstName,
        '\n Last Name: '+ cpaInviteLastName,
        '\n Email: ' + cpaInviteEmail,
        '\n Phone: ' + cpaInvitePhone,
        '\n Notes: ' + cpaInviteNotes
      };
      ChatterMentionPost.createChatterMentionPost(
        loggedInContact.Mirror_Ref_Ctct__r.Referral_Account__c,
        usersToMentionInChatter,
        postText,
        true,
        true
      );
      ChatterMentionPost.postBatchFeedElements();
      //return null;
    } catch (Exception e) {
      ApexPages.Message myMsg = new ApexPages.Message(
        ApexPages.Severity.ERROR,
        'Something went wrong:' + e.getMessage()
      );
      System.debug('Error creating ==>' + e.getMessage());
      ApexPages.addMessage(myMsg);
    }
  }
  public void createReferralAsGuest(String contactId) {
    String AccountId = [
      SELECT Referral_Account__r.Account__c
      FROM Referral_Contact__c
      WHERE Contact_ID__c = :contactId
      LIMIT 1
    ].Referral_Account__r.Account__c;
    String ContactId2 = [SELECT Contact__c FROM Referral_Contact__c WHERE Contact_ID__c = :contactId LIMIT 1].Contact__c;
    createPartnerReferral(AccountId, ContactId2);
  }

  public void createReferralAsClient () {
    String ContactId = UserHelper.getRunningUser().ContactId;
    Contact ReferralContact = [Select Name, Id, AccountId, Contact_ID__c from Contact where Id =: ContactId limit 1];
    ContactId = ReferralContact.Contact_ID__c != null? ReferralContact.Contact_ID__c: null;
    String ContactId2 = ReferralContact.Id;
    String AccountId = ReferralContact.AccountId;
    createPartnerReferral(AccountId, ContactId2);
  }

  public void createPartnerReferral(String AccountId, String ContactId) {
    try {
      // TODO Grab the RC so we can snag RC>RA>PartnerId and place it on PartnerReferral__r.PartnerId;
      PartnerReferral__c prfobj = new PartnerReferral__c();
      prfobj.FirstName__c = FirstName;
      prfobj.LastName__c = LastName;
      prfobj.Email__c = Email;
      prfobj.Phone__c = Phone;
      prfobj.Company__c = Company;
      prfobj.ZipPostalCode__c = PostalCode;
      //prfobj.PartnerId__c=ContactId;// Update to be Account
      prfobj.PartnerBranchAcct__c = AccountId.trim();
      prfobj.PartnerAcct__c = AccountId.trim();
      prfobj.PartnerContact__c = ContactId;
      prfobj.ReferralType__c = 'Accountant Program';
      prfobj.SubmitAsEmail__c = true;
      prfobj.ProcessReferral__c = true;

      insert prfobj;
      this.isShowModelPopup1 = false;
      this.isShowModelPopup2 = true;
      this.showPersonalURLPopup = false;
      //return null;
    } catch (Exception e) {
      ApexPages.Message myMsg = new ApexPages.Message(
        ApexPages.Severity.ERROR,
        'Something went wrong:' + e.getMessage()
      );
      System.debug('Error creating ==>' + e.getMessage());
      ApexPages.addMessage(myMsg);
    }
  }
}