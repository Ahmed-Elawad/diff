/* Controller for the Bank Referral form
   
  History
  -------
  09/28/2015 Dan Carmen   Created
  02/05/2016 Dan Carmen   Additional Form Changes
  06/20/2016 Dan Carmen   Added message about Referral Payment
  12/28/2016 Dan Carmen   Change to without sharing.
  05/10/2017 Dan Carmen   Fix for the "Submit Another" button.
  05/25/2017 Dan Carmen   Added check for end date
  07/25/2017 Dan Carmen   Updates to accomodate CPA dashboard form changes
  08/25/2017 Jermaine Stukes  Updates for CPA dashboard display
  12/14/2018 Dan Carmen       Change to display product selection
  06/20/2019 Matt Fritschi  Added method to format products and message about invalid product selection
  08/27/2019 Matt Fritschi  Added Merchant Services to possible products.
  11/01/2021 Pujitha Madamachi  Added Tier I process
  
 */
public without sharing class PartnerReferralController {

/*
   public String pageSubTitle{
      get {
         String subTitle = '';
         if (partner != null) {
            subTitle = partner.Name;
         }
         return subTitle;
      } // get
   } // pageSubTitle
*/

   public String pageTitle{
      get {
         String pageTitle='';
         if (partnerIdEntry) {
            pageTitle = (partner != null ? partner.DisplayName__c : '')+' Request Form';
         } else if (refContactEntry) {
            pageTitle = (refCtct != null ? refCtct.Name : '')+' Referral Request';
         }
         return pageTitle;
      }
   } // pageTitle
   
   public String prospectInfoTitle{
      get {
         String prospectInfoTitle = 'Business Contact Information';
         if (refContactEntry) {
            prospectInfoTitle = 'Referral Information';
         }
         else if(tierI!= null && tierI){
            prospectInfoTitle= 'Referee Information';
         }
         return prospectInfoTitle;
      }
   } // prospectInfoTitle

   public String refereeInfoTitle{
      get {
         String refereeInfoTitle = 'Referring Partner and/or Employee Information';
         if(tierI!= null && tierI){
            refereeInfoTitle= 'Referring partner and/or Employee Info 1';
         }
         return refereeInfoTitle;
      }
   } // refereeInfoTitle
   
    public String parameterPartnerId{get;private set;}
    public Map<String,String> defaultParameters = new Map<String,String>();
    public String refCtctId = null;
    public String contactId = null;
    public Boolean customerForm{get;set;}
    public Boolean inlineForm{get;private set;}
    // is the user of the form a guest user (from a site)?
    public Boolean isGuestUser{get;private set;}
   
   public static String ENTRY_PARTNERID='partnerId';
    
   public static String ENTRY_REF_CTCT='refCtct';
   
   public String entryMethod{get;set;}
   
   public Boolean partnerIdEntry{
      get {return (entryMethod != null && entryMethod==ENTRY_PARTNERID); }
   }
   public Boolean refContactEntry{
      get {return (entryMethod != null && entryMethod==ENTRY_REF_CTCT); }
   }
   public Boolean formEntryOkay{
      get {
         Boolean okay = ((partnerIdEntry && partner != null)
                         || (refContactEntry && refCtct != null)
                        );
         return okay;
      } // get
   } // formEntryOkay
      
   public Boolean showSubmitMsg{get;private set;}
    
   public Boolean cpaDashboardDisplay{get;private set;}
      
   public static final String SUBMIT_MSG='submitmsg';
      
   public static Set<String> excludeParamSet = new Set<String>{SUBMIT_MSG};
   
   public Boolean tierI{get;set;}
   
   public String selectedRefer {get; set;}

   
   public PartnerReferralController() {

       isGuestUser = UserHelper.isRunningUserGuest();
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'name='+userInfo.getName()+' isGuestUser='+isGuestUser));
      inlineForm = false;
      clearForm(false,false);
      showSubmitMsg = false;
      cpaDashboardDisplay = false;
      tierI = false;
      // did this form come from a referral contact record?
      refCtctId = System.currentPageReference().getParameters().get('RefCtctId');
      contactId = System.currentPageReference().getParameters().get('contactId');
      parameterPartnerId = System.currentPageReference().getParameters().get('PartnerId');
      String customerFormStr = System.currentPageReference().getParameters().get('CustomerForm');
      // if this is coming from an existing salesforce record
      String recId = System.currentPageReference().getParameters().get('id');
      // if this is an inline form (for example, a quick action form)
      String inline = System.currentPageReference().getParameters().get('inline');
      String submitMsg = System.currentPageReference().getParameters().get(SUBMIT_MSG);
       showSubmitMsg = (String.isNotBlank(submitMsg) && submitMsg=='Y');
       cpaDashboardDisplay = (contactId == null ? false : true);
      //if (String.isNotBlank(showSubmitMsg) && showSubmitMsg=='Y') {
      //   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Your referral was submitted!'));
      //}
      
      inlineForm = (String.isNotBlank(inline) && inline == '1');
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'inlineForm='+inlineForm+' showSubmitMsg='+showSubmitMsg));
      
      if (String.isNotBlank(recId)) {
         String refCtctPrefix = ObjectHelper.getObjectPrefix(ObjectHelper.OBJECT_REF_CONTACT);
         if (recId.startsWith(refCtctPrefix)) {
            refCtctId = recId;
         }
      } // if (String.isNotBlank(recId
      
      partnerRef.CustomerForm__c = (String.isNotBlank(customerFormStr) ? customerFormStr == 'true' : false);
      customerForm = partnerRef.CustomerForm__c;
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'CustomerForm='+customerFormStr+' partnerRef.CustomerForm__c='+partnerRef.CustomerForm__c));
      
      defaultParameters.clear();
      for (String parameterName : System.currentPageReference().getParameters().keySet()) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'parameter='+parameterName+' value='+System.currentPageReference().getParameters().get(parameterName)));
         if (!excludeParamSet.contains(parameterName)) {
            defaultParameters.put(parameterName,System.currentPageReference().getParameters().get(parameterName));
         }
      } // for
            
      if (String.isNotBlank(parameterPartnerId)) {
         partnerRef.PartnerId__c = parameterPartnerId;
         checkPartnerId();
      } else if (String.isNotBlank(refCtctId) || String.isNotBlank(contactId)) {
         setupReferralContactEntry();
      }
   } // PartnerReferralController

   // extension controller
   public PartnerReferralController(ApexPages.StandardController stdController) {
      this();
   } // PartnerReferralController
   
   // to allow each bank to display a different blurb on the form.
   public String bankDescription {get;private set;}
   
   public PartnerReferral__c partnerRef{get;set;}
   
   public Partner__c partner{get;set;}
   
   // if there's a logo for the partner, set the URL here.
   public String partnerLogoURL{get; private set;}
   
   // is there a partner logo?
   public Boolean hasPartnerLogo{
      get {return String.isNotBlank(partnerLogoURL); }
   }
   
   public String partnerLocationLabel{get;private set;}
   public Boolean partnerIdFound{
      get {return (partner != null); }
   } // partnerIdFound
   
   public Boolean hasMultipleBranches {
      get {return (branchOptions != null && branchOptions.size() > 1); }
   } // hasMultipleBranches
   
   public List<SelectOption> branchOptions{get;private set;}
   
   public String selectedBranch{get;set;}
   
   // check if the entered partner id is valid
   public PageReference checkPartnerId() {
      entryMethod=ENTRY_PARTNERID;
      branchOptions = new List<SelectOption>();
      selectedBranch = null;
      // set the default description
      bankDescription = (customerForm ? Label.ReferralFormCustDescript : Label.ReferralFormDescription);
      partnerLocationLabel = Label.ReferralFormLocationLabel;
      
      if (String.isNotBlank(partnerRef.PartnerId__c)) {
         try {
            partner = [Select Id, Name, DisplayName__c, PartnerId__c, PostalCode__c
                                ,Account__r.Referral_Type__c
                                ,PartnerDetail__r.Id
                                ,PartnerDetail__r.ReferralFormCustDesc__c
                                ,PartnerDetail__r.ReferralFormDescription__c
                                ,PartnerDetail__r.ReferralFormLogoURL__c
                                ,PartnerDetail__r.ReferralFormLocationLabel__c
                                ,PartnerDetail__r.ReferralProducts__c
                                ,(Select Id, Name, DisplayName__c, PostalCode__c from PartnerBranches__r where EndDate__c = null order by DisplayName__c limit 400)
                            From Partner__c
                           Where PartnerId__c = :partnerRef.PartnerId__c
                             and EndDate__c = null
                           order by createdDate desc limit 1 ];
            partnerRef.Partner__c = partner.Id;
            partnerRef.ReferralType__c = partner.Account__r.Referral_Type__c;
            tierI = (String.isNotBlank(partnerRef.ReferralType__c) ? partnerRef.ReferralType__c == '52 Bank Tier 1' : false);
            //checkReferralType(partner.Account__r.Referral_Type__c);

            if (partner.PartnerDetail__r != null) {
               String formDesc = (customerForm ? partner.PartnerDetail__r.ReferralFormCustDesc__c : partner.PartnerDetail__r.ReferralFormDescription__c);
               bankDescription = (String.isNotBlank(formDesc) ? formDesc : bankDescription);
               setAvailableProds(partner.PartnerDetail__r.ReferralProducts__c);
               
            }
            if (partner.PartnerDetail__r != null && String.isNotBlank(partner.PartnerDetail__r.ReferralFormDescription__c)) {
               bankDescription = partner.PartnerDetail__r.ReferralFormDescription__c;
            }
            partnerLogoURL = (partner.PartnerDetail__r != null ? partner.PartnerDetail__r.ReferralFormLogoURL__c : null);
          //  partnerLocationLabel=(partner.PartnerDetail__r != null && String.isNotBlank(partner.PartnerDetail__r.ReferralFormLocationLabel__c) ? partner.PartnerDetail__r.ReferralFormLocationLabel__c : Label.ReferralFormLocationLabel);
          partnerLocationLabel=(tierI==true ? Label.ReferralFormBranchLabel : (partner.PartnerDetail__r != null && String.isNotBlank(partner.PartnerDetail__r.ReferralFormLocationLabel__c) ? partner.PartnerDetail__r.ReferralFormLocationLabel__c :Label.ReferralFormLocationLabel));

            if (partner.PartnerBranches__r.size() == 1) {
               // if only 1, default to this.
               partnerRef.PartnerBranch__c = partner.PartnerBranches__r[0].Id;
            } else if (partner.PartnerBranches__r.size() > 1) {
               branchOptions.add(new SelectOption('','Select A '+partnerLocationLabel));
               for (Partner__c branch : partner.PartnerBranches__r) {
                  branchOptions.add(new SelectOption(branch.Id, branch.DisplayName__c+(String.isNotBlank(branch.PostalCode__c) ? ', '+branch.PostalCode__c : '')));
               } // for (Partner__c branch
            } else {
               // use the partner as the branch?
               partnerRef.PartnerBranch__c = partner.Id;
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'No '+partnerLocationLabel+' was found for '+partner.Name+', Partner Id '+partner.PartnerId__c+'! At least one '+partnerLocationLabel+' must be defined!'));
               //partner = null;
            }
         } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'A referral partner with the Partner Id '+partnerRef.PartnerId__c+' was not found!'));
            System.debug('exception: '+e.getMessage()+'; '+e.getStackTraceString());
         }
      } // if (String.isNotBlank(partnerRef.PartnerId__c
      return null;
   } // checkPartnerId
   
   /*
   public void checkReferralType(String refTypeValue) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkReferralType refTypeValue='+refTypeValue));
      if (String.isNotBlank(refTypeValue)) {
         ReferralType__c refType = ReferralType__c.getInstance(refTypeValue);
         if (refType != null && refType.PartnerReferralForm__c) {
            partnerRef.ReferralType__c = refType.ReferralPartner__c;
         }
      }
      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'checkReferralType partnerRef.ReferralType__c='+partnerRef.ReferralType__c));
   } // checkReferralType
   */
   
   public Referral_Contact__c refCtct{get;set;}
   
   // was the entry to the form by a referral contact?
   public Boolean refCtctEntry{
      get {return (refCtct != null);}
   }
   
   // Do we show the payment message if this is entered from a Referral Contact if we're not within the payment start/end dates?
   public static Boolean SHOW_PAYMENT_MSG=(Label.PartnerReferralShowPaymentMsg!='N');
   
   // when the form is entered from a Referral Contact
   public void setupReferralContactEntry() {
      entryMethod=ENTRY_REF_CTCT;
      try {
          String queryRefCtctId = (String.IsNotBlank(refCtctId) ? refCtctId : 'a07000000000000');
          String queryContactId = (String.IsNotBlank(contactId) ? contactId : 'ThisIsABadId');
          refCtct = [Select Id
                     , Name
                     ,Contact__c
                     ,Contact_ID__c
                     ,First_Name__c
                     ,Last_Name__c
                     ,Phone__c
                     ,Email__c
                     ,Employee_Number__c 
                     ,ReferralPartnerName__c
                     ,Referral_Account__c
                     ,Referral_Account__r.Id
                     ,Referral_Account__r.Name
                     ,Referral_Account__r.Account__c
                     ,Referral_Account__r.Bank_Branch_Number__c
                     ,Referral_Account__r.Referral_Type__c
                     ,Referral_Account__r.ReferralPaymentStart__c
                     ,Referral_Account__r.ReferralPaymentEnd__c
                     ,Referral_Account__r.Zip_Postal_Code__c
                     ,Referral_Account__r.Parent_Referral_Account__c
                     ,Referral_Account__r.Parent_Referral_Account__r.Id
                     ,Referral_Account__r.Parent_Referral_Account__r.Name
                     ,Referral_Account__r.Parent_Referral_Account__r.Account__c
                     ,Referral_Account__r.Parent_Referral_Account__r.ReferralPaymentStart__c
                     ,Referral_Account__r.Parent_Referral_Account__r.ReferralPaymentEnd__c
                     From Referral_Contact__c
                     Where (Id = :queryRefCtctId or Contact_ID__c =:queryContactId)
                     and Referral_Account__c != null];
      } catch (Exception e) {
          string refContactId = (refCtctId != null ? refCtctId : contactId);
          ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Bad Id passed in for Partner Referral! '+refContactId+': '+e.getMessage()));
      }
      setRefCtct();
   } // setupReferralContactEntry
   
   public void setRefCtct() {
      if (refCtct != null) {
          
         partnerRef.ReferralEntry__c=Label.RefEntry_RefCtct;

         partnerRef.PartnerContact__c = refCtct.Contact__c;
         partnerRef.PartnerBranchAcct__c = refCtct.Referral_Account__r.Account__c;
         partnerRef.BranchNumber__c = refCtct.Referral_Account__r.Bank_Branch_Number__c;
         
         partnerRef.ReferralType__c = refCtct.ReferralPartnerName__c;
         
         //checkReferralType(refCtct.Referral_Account__r.Referral_Type__c);

         partnerRef.EmpFirstName__c = refCtct.First_Name__c;
         partnerRef.EmpLastName__c = refCtct.Last_Name__c;
         partnerRef.EmpPhone__c = refCtct.Phone__c;
         partnerRef.EmpEmail__c = refCtct.Email__c;
         partnerRef.EmployeeId__c = refCtct.Employee_Number__c; 
                  
         Referral_Account__c parentRefAcct = (refCtct.Referral_Account__r.Parent_Referral_Account__r != null ? refCtct.Referral_Account__r.Parent_Referral_Account__r : refCtct.Referral_Account__r);
         partnerRef.PartnerName__c = parentRefAcct.Name;
         partnerRef.PartnerAcct__c = parentRefAcct.Account__c;
         
         checkForPaymentMsg();
         
         Set<Id> acctIdSet = new Set<Id>();
         if (refCtct.Referral_Account__r.Account__c != null) {
            acctIdSet.add(refCtct.Referral_Account__r.Account__c);
         }
         if (refCtct.Referral_Account__r.Parent_Referral_Account__c != null && refCtct.Referral_Account__r.Parent_Referral_Account__r.Account__c != null) {
            acctIdSet.add(refCtct.Referral_Account__r.Parent_Referral_Account__r.Account__c);
         }
         
         // look for partner details
         PartnerDetail__c[] partDetails = [Select Id
                                                 ,ReferralProducts__c
                                             From PartnerDetail__c
                                            Where Account__c in :acctIdSet]; 
         // should at max be one returned
         if (!partDetails.isEmpty()) {
            setAvailableProds(partDetails[0].ReferralProducts__c);
         }
      } // if (refCtct != null
   } // setupReferralContactEntry
   
   public void checkForPaymentMsg() {
      if (refCtct != null && String.isBlank(contactId)) {
         Referral_Account__c parentRefAcct = (refCtct.Referral_Account__r.Parent_Referral_Account__r != null ? refCtct.Referral_Account__r.Parent_Referral_Account__r : refCtct.Referral_Account__r);
         checkForPaymentMsg(parentRefAcct);
      }
   } // checkForPaymentMsg
   
   public void checkForPaymentMsg(Referral_Account__c refAcct) {
      if (SHOW_PAYMENT_MSG && !showSubmitMsg && refAcct != null) {
         Boolean paymentOkay = (refAcct.ReferralPaymentStart__c != null && refAcct.ReferralPaymentStart__c <= Date.today()
                      && (refAcct.ReferralPaymentEnd__c == null ||  refAcct.ReferralPaymentEnd__c >= Date.today()));
         if (!paymentOkay) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.PartnerReferralShowPaymentMsg));
         }
      }
   } // checkForPaymentMsg
   
   public Boolean showAvailProdOptions{
       get {return (availProdOptions != null && availProdOptions.size() > 1); }
   }
   
   public List<SelectOption> availProdOptions{get;private set;}
   
   public void setAvailableProds(String availProdStr) {
      String[] availProdTokens = (String.isNotBlank(availProdStr) ? availProdStr.split(';') : new String[]{});
       
      availProdOptions = new List<SelectOption>();
      for (String availProd : availProdTokens) {
            availProdOptions.add(new SelectOption(availProd, availProd));   
      }
      checkDefaultProduct();
   } // setAvailableProds

   
   //get the multi-select pick list values
   public List<SelectOption> getProductsPicklist {
      get {
          List<SelectOption> options = new List<SelectOption>();
          for( Schema.PicklistEntry obj : PartnerDetail__c.ReferralProducts__c.getDescribe().getPicklistValues()) {
              options.add(new SelectOption(obj.getValue(), obj.getLabel()));
          } 
          return options;
      }  
      set;
   }
   
   //get and set the multi-select pick list as checkboxes
   public String[] selectedProducts { 
      get {
          List<String> selected = new List<String>();
          List<SelectOption> options = this.getProductsPicklist;
          for(SelectOption obj : options) {
              if (this.partnerRef.Products__c !=null && this.partnerRef.Products__c.contains(obj.getValue()))
                  selected.add(obj.getValue());
          }
          return selected;
      }
      public set{
          String selectedCheckBox = '';
          for(String s : value){
              if (selectedCheckBox == ''){
                  selectedCheckBox += s;
              } 
              else{
                  selectedCheckBox += ';' + s;
              }
          }
          partnerRef.Products__c = selectedCheckBox;
      }
   } 
   
   public void checkDefaultProduct() {
      if (availProdOptions != null && availProdOptions.size() == 1 && partnerRef != null) {
         partnerRef.Products__c=availProdOptions[0].getValue();
      }
   } // checkDefaultProduct
      

   public void formatProdsOfInterest()
   {
       if(partnerRef.Products__c!= null)
       {          
            Integer length = partnerRef.Products__c.length();
            partnerRef.Products__c = partnerRef.Products__c.substring(1, length-1);
            partnerRef.Products__c = partnerRef.Products__c.replace(',', ';');
            // Checks to make sure Payroll is selected with Freshlime, Paycard, or Merchant Services.
            if ((partnerRef.Products__c.contains('Freshlime') || partnerRef.Products__c.contains('Paycard') || partnerRef.Products__c.contains('Merchant Services')) && !partnerRef.Products__c.contains('Payroll')) {
            partnerRef.Products__c = 'Payroll;' + partnerRef.Products__c;
            }
            // Auto selects Payroll if no Product of Interest was chosen.
            if (partnerRef.Products__c == '' || partnerRef.Products__c == null) {
                partnerRef.Products__c = 'Payroll';
            }
        }
        else
        {
           partnerRef.Products__c = 'Payroll';
        }
   }//formatProdsOfInterest
   
   public PageReference clearForm() {
      return clearForm(true,false);
   } // clearForm
   
   public PageReference clearForm(Boolean redirect, Boolean referralSubmitted) {
      System.debug('clearForm isGuest='+UserHelper.isRunningUserGuest()+' redirect='+redirect+' referralSubmitted='+referralSubmitted);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'clearForm isGuest='+UserHelper.isGuestUser(runningUser)+' redirect='+redirect+' referralSubmitted='+referralSubmitted));
      partnerRef = new PartnerReferral__c(ProcessReferral__c=true, SubmitAsEmail__c=true);
      //setRefCtct();
      checkDefaultProduct();
      //partner = null;
      PageReference partnerPage = null;
      if (redirect) { //(!inlineForm && redirect) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in redirect'));
         partnerPage = (refContactEntry && !UserHelper.isRunningUserGuest() ? Page.PartnerReferralRefCtct : Page.PartnerReferral);
         for (String parameter : defaultParameters.keySet()) { 
            String value = defaultParameters.get(parameter);
            partnerPage.getParameters().put(parameter,value);
         }
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'parameters='+partnerPage.getParameters()));
         if (referralSubmitted) {
            partnerPage.getParameters().put(SUBMIT_MSG,'Y');
         }
      //   if (String.isNotBlank(parameterPartnerId)) {
      //      partnerPage.getParameters().put('PartnerId',parameterPartnerId);
      //   }
         partnerPage.setRedirect(true);
      } else {
         if (UserHelper.isRunningUserGuest()) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'In else clause for guest user'));
            partnerRef.ReferralEntry__c=Label.RefEntry_ExtWeb;
            partnerRef.SubmitAsEmail__c=true;
         } else {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'In else clause int web'));
            partnerRef.ReferralEntry__c=Label.RefEntry_IntWeb;
            partnerRef.SubmitAsEmail__c=false;
         }
      } // if (redirect
      return partnerPage;
   } // clearForm
   
   public PageReference submitReferral() {
      Boolean okay = true;
       System.debug('customerForm:::'+customerForm);
      if (!customerForm && hasMultipleBranches && selectedBranch == null) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'A Branch Name must be selected!'));
         okay = false;
      } // if (hasMultipleBranches
             
      if (String.isNotBlank(selectedBranch)) {
         partnerRef.PartnerBranch__c = selectedBranch;
      }
      // if coming in from a customer form, there will not be a branch selected. Default to the main partner record.
      if (customerForm && partnerRef.PartnerBranch__c == null) {
         partnerRef.PartnerBranch__c = partnerRef.Partner__c;
      }
       if(!tierI){
           formatProdsOfInterest();
       }
       
       System.debug('The products are: ' + partnerRef.Products__c);
       if(partnerRef.Products__c.contains('Payroll') && partnerRef.Products__c.contains('401(k)'))
       {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You cannot select Payroll and 401K (Freshlime, Paycard, and Merchant Services are also Payroll).'));
           okay = false;
       }
       
       //Add CPA Dashboard submission indicator
       if(cpaDashboardDisplay)
       {
           partnerRef.ReferralEntry__c=Label.RefEntry_Contact;
       }
      if (okay) {
         insert partnerRef;
         showSubmitMsg = true;
         System.debug('submitReferral The referral was just submitted.');
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Your referral was submitted!'));
      }
      
      if (okay) {
         return clearForm(true,okay);
      }
      return null;
   } // submitReferral
   
   public Integer textAreaColumns{
      get {
         return (isGuestUser ? 50 : 50);
      }
   } // testAreaColumns
   
   public PageReference submitAnother() {
      showSubmitMsg = false;
      PageReference pr = clearForm(true,false);
      checkForPaymentMsg();
      return pr;
   } // submitAnother
   
} // class PartnerReferralController