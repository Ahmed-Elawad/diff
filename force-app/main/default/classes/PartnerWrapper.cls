/* Wrapper class to manage Bank Leads
   
  History
  -------
  10/07/2015 Dan Carmen   Created
  02/13/2016 Dan Carmen   Additional Changes
  03/22/2016 Dan Carmen   Add payroll owner field to include on non-payroll leads.
  05/23/2016 Dan Carmen   Fix problem when setting payroll owner.
  06/20/2019 Matt Fritschi  Payroll, Freshlime, and Paycard products all handled as Payroll.
  08/27/2019 Matt Fritschi  Merchant Services product added. Handled as Payroll.
  04/12/2021 Pujitha Madamanchi  Populate latest campaign on Lead. 
  04/28/2021 Pujitha Madamanchi  Add clover tag
  
 */
public without sharing class PartnerWrapper {

   public static final String PROD_INTEREST_PAYROLL='Payroll';
   // used for the bank product of interest on the lead
   public static final String PROD_INTEREST_401k='401(k)';
   public static final String PROD_INTEREST_Clover='Clover';
   public PartnerWrapper() {
   } // PartnerWrapper

   public PartnerWrapper(PartnerReferral__c p_partRef) {
      partRef = p_partRef;
      isPayroll = (String.isNotBlank(p_partRef.Products__c) ? p_partRef.Products__c.contains(PROD_INTEREST_PAYROLL) : false);
      is401k = (String.isNotBlank(p_partRef.Products__c) ? p_partRef.Products__c.contains(PROD_INTEREST_401k) : false);
      
      totalProds = p_partRef.Products__c; 
      List<String> allProducts = ((p_partRef != null && String.isNotBlank(p_partRef.Products__c)) ? p_partRef.Products__c.split(';') : new String[]{});
      payOr401 = (!allProducts.isEmpty() ? allProducts[0] : 'Payroll');
      if(allProducts.isEmpty())
      {
          totalProds = 'Payroll';
      }
      
      //partnerName = partRef.ReferralType__c;
      fullName = partRef.FirstName__c+' '+partRef.LastName__c;
      setupData();
   } // PartnerWrapper

   public static final String PARTNER_TYPE='Inbound Partner Referral';
   
   public static String DEFAULT_REF_PARTNER = Label.PartnerDefaultRefPartner;
   
   private static Map<String,Referral_Partner__c> refPartnerMap = null;
   
   public static Referral_Partner__c findReferralPartner(String partnerName) {
      if (refPartnerMap == null) {
         Referral_Partner__c[] refPartners = ReferralQueries.selectRefPartnersCache(PARTNER_TYPE, null);
         refPartnerMap = new Map<String,Referral_Partner__c>();
         for (Referral_Partner__c checkRefPartner : refPartners) {
            refPartnerMap.put(checkRefPartner.name, checkRefPartner);
         }
      } // if (refPartnerMap == null

      Referral_Partner__c refPartner = null;
      if (String.isNotBlank(partnerName)) {
         refPartner = refPartnerMap.get(partnerName);
      } // if (String.isNotBlank(partnerName
      
      // get a default value so we can always link a referral
      if (refPartner == null) {
         refPartner = refPartnerMap.get(DEFAULT_REF_PARTNER);
      }
      return refPartner;
   } // findReferralPartner
   
   // include the paroll owner on all other leads generated
   public Id payrollOwnerId = null;

   public void setupData() {
      // default to payroll if neither is selected.
      if (!isPayroll && !is401k) {
         isPayroll = true;
      }
      
      /*
      String refPartnerName = partRef.ReferralType__c;
      // translate it if needed to match the referral partner name
      if (String.isNotBlank(partRef.ReferralType__c)) {
         ReferralType__c refType = ReferralType__c.getInstance(partRef.ReferralType__c);
         if (refType != null && String.isNotBlank(refType.ReferralPartner__c)) {
            refPartnerName = refType.ReferralPartner__c;
         }
      }
      Referral_Partner__c refPartner = findReferralPartner(refPartnerName);
      */
      if (partRef.PartnerBranchAcct__r != null && partRef.PartnerBranchAcct__r.Mirror_Referral_Account__r != null) {
         partnerBranch = partRef.PartnerBranchAcct__r.Mirror_Referral_Account__r;
      }
      
      if (partnerBranch == null && partRef.PartnerBranch__r != null && partRef.PartnerBranch__r.Account__r != null && partRef.PartnerBranch__r.Account__r.Mirror_Referral_Account__r != null) {
         partnerBranch = partRef.PartnerBranch__r.Account__r.Mirror_Referral_Account__r;
      }
      
      if (partRef.PartnerAcct__r != null && partRef.PartnerAcct__r.Mirror_Referral_Account__r != null) {
         partnerHeadquarters = partRef.PartnerAcct__r.Mirror_Referral_Account__r;
      }
      
      if (partnerHeadquarters == null && partRef.Partner__r != null && partRef.Partner__r.Account__r != null && partRef.Partner__r.Account__r.Mirror_Referral_Account__r != null) {
         partnerHeadquarters = partRef.Partner__r.Account__r.Mirror_Referral_Account__r;
      }
      
      if (partnerHeadquarters == null && partnerBranch != null) {
         partnerHeadquarters = partnerBranch.Parent_Referral_Account__r;
      }
      
       if(totalProds.contains('Payroll'))
       {
           String payProdList = totalProds;
           if(totalProds.contains('401(k)'))
           {
                payProdList = totalProds.remove(';401(k)');
           }
           payOr401 = 'Payroll';
           addLead(payProdList);
       }
       
       if(totalProds.contains('401(k)'))
       {
            payOr401 = '401(k)';
            addLead('401(k)');
       }
      //addLead(totalProds/*,refPartner*/);
      //addLead(totalProds/*,refPartner*/);
       
      setPartnerBranch(null);
      if (partRef.PartnerContact__r != null && partRef.PartnerContact__r.Mirror_Ref_Ctct__r != null) {
         setRefCtct(partRef.PartnerContact__r.Mirror_Ref_Ctct__r);
      }
   } // setupData
   
   public static Integer PROCESS_NOTES_LENGTH=PartnerReferral__c.ProcessNotes__c.getDescribe().getLength();
   
   public void addToProcessNotes(String textToAdd) {
      if (String.isNotBlank(textToAdd) && partRef != null) {
         partRef.ProcessNotes__c = ((String.isNotBlank(partRef.ProcessNotes__c) ? partRef.ProcessNotes__c + '\n' : '') + textToAdd).left(PROCESS_NOTES_LENGTH);
      }
   } // addToProcessNotes
   
   public PartnerReferral__c partRef = null;
   public WebBankLeadHelper.BankLead bankLd;
   public Boolean isPayroll;
   public Boolean is401k;
   public Boolean dupeFound = false;
   public String fullName = null;
   public String totalProds = null;
   public String payOr401 = null;
      
   //public String partnerName = WebBankLeadHelper.TIER_1;
   
   // a map of all of the referrals
   public Map<String,Referral__c> referralMap = new Map<String,Referral__c>();
   public Referral__c referralPay {
      get {return referralMap.get(PROD_INTEREST_PAYROLL); }
   }
   public Referral__c referral401 {
      get {return referralMap.get(PROD_INTEREST_401K); }
   }
      
   public Referral_Account__c partnerHeadquarters = null;
   public Referral_Account__c partnerBranch = null;
   
   public void setPartnerBranch(Referral_Account__c p_partnerBranch) {
      if (p_partnerBranch != null) {
         partnerBranch = p_partnerBranch;
         if (partnerBranch != null) {
            partnerHeadquarters = partnerBranch.Parent_Referral_Account__r;
         }
      }
      /*
      if (partnerBranch != null) {
         for (Referral__c ref : referralMap.values()) {
            ref.Referral_Account__c = partnerBranch.Id;
            ref.ReferralSourceAccount__c = partnerBranch.Account__c;
            if (ref.ReferringAccountParent__c == null) {
               ref.ReferringAccountParent__c = partnerBranch.Parent_Referral_Account__r.Account__c;
            }
         } // for (Referral__c ref
      } // if (partnerBranch != null
      */
   } // setPartnerBranch
   
   // using the referral type set the referral partner and the lead source
   public void checkLeadsAndReferrals() {
      String referralType = (refCtct != null ? refCtct.ReferralPartnerName__c : null);
      if (String.isBlank(referralType)) {
         referralType = (partnerHeadquarters != null ? (String.isNotBlank(partnerHeadquarters.Referral_Type__c) ? partnerHeadquarters.Referral_Type__c : partnerHeadquarters.Referral_Source_Business_Type__c) : null);
      }
      //System.debug('checkLeadsAndReferrals referralType 1='+referralType);
      if (String.isBlank(referralType) && partnerBranch != null) {
         referralType = (String.isNotBlank(partnerBranch.Referral_Type__c) ? partnerBranch.Referral_Type__c : partnerBranch.Referral_Source_Business_Type__c);
      }
      //System.debug('checkLeadsAndReferrals referralType 2='+referralType);
      if (String.isBlank(referralType)) {
         referralType = (String.isNotBlank(partRef.ReferralType__c) ? partRef.ReferralType__c : Label.PartnerDefaultReferralType);
      }

      partRef.ReferralType__c = referralType;
      ReferralType__c refType = (String.isNotBlank(referralType) ? ReferralType__c.getInstance(referralType) : null);

      //String refPartnerName = (refType != null && String.isNotBlank(refType.ReferralPartner__c) ? refType.ReferralPartner__c : referralType);
      //System.debug('checkLeadsAndReferrals referralType='+referralType+' refPartnerName='+refPartnerName+' refType='+refType);
      
      String refPartnerName = (refCtct != null ? refCtct.ReferralPartnerName__c : null);
      Referral_Partner__c refPartner = findReferralPartner(refPartnerName);
      System.debug('checkLeadsAndReferrals refPartner='+refPartner);

      String leadSource = (refCtct != null && String.isNotBlank(refCtct.LeadSourceDefault__c) ? refCtct.LeadSourceDefault__c :
                             (refType != null && String.isNotBlank(refType.LeadSource__c) ? refType.LeadSource__c : Label.LeadSource_ReferralBank));
      
      for (Lead ld : leadMap.values()) {
         ld.Referral_Contact__c = (refCtct != null ? refCtct.Id : null);
         ld.LeadSource = leadSource;
      } // for (Lead ld

      for (Referral__c ref : referralMap.values()) {
         ref.Referral_Partner__c = (refPartner != null ? refPartner.Id : null);
         ref.SellingLeadSource__c = leadSource;
         if (partnerBranch != null) {
            ref.Referral_Account__c = partnerBranch.Id;
            ref.ReferralSourceAccount__c = partnerBranch.Account__c;
            if (ref.ReferringAccountParent__c == null && partnerHeadquarters != null) {
               ref.ReferringAccountParent__c = partnerHeadquarters.Account__c;
            }
         } // if (partnerBranch != null

         if (refCtct != null) {
            ref.Referral_Contact__c = refCtct.Id;
            ref.Referral_Account__c = refCtct.Referral_Account__c;
            ref.ReferralSourceContact__c = refCtct.Contact__c;
            ref.ReferralSourceAccount__c = refCtct.Contact__r.AccountId;
         }

      } // for (Referral__c ref


   } // checkLeadsAndReferrals

   // a string containing the detail of the incoming lead information
   public String getLeadDetail() {
      String detail = getValue(true,'Name',partRef.PartnerName__c);
      detail += getValue(false,'Branch No',partRef.BranchNumber__c);
      detail += getValue(false,'Branch Name',partRef.BranchName__c);
      detail += getValue(false,'Ref Contact',partRef.EmpFirstName__c + ' ' + partRef.EmpLastName__c);
      detail += getValue(false,'Emp ID',partRef.EmployeeId__c);
      detail += getValue(false,'Product',partRef.Products__c);
      String repName = (String.isNotBlank(partRef.SalesRepFirstName__c) ? partRef.SalesRepFirstName__c : '');
      repName += (repName != '' ? ' ' : '') + (String.isNotBlank(partRef.SalesRepLastName__c) ? partRef.SalesRepLastName__c : '');
      detail += getValue(false,'Rep Name',repName);
      return detail;
   } // getLeadDetail

   private static String getValue(Boolean isFirst, String label, String value) {
      String retVal = (String.isNotBlank(value) ? (isFirst ? '' : ', ') + label + ': ' + value : '');
      return retVal;
   } // getValue

/*
   public String getLeadDetail(Boolean is401k) {
      String detail = 'Bank Name: ' + bankLd.bankName 
                      + ', Branch No: ' + bankLd.branchNumber 
                      + ', Branch Name: ' + bankLd.branchName 
                      + ', Ref Contact: ' + bankLd.refEmployeeFirstName + ' ' + bankLd.refEmployeeLastName
                      + ', Emp ID: ' + bankLd.EmployeeID
                      + (is401k  ? '' : ', 401k Product')
                      + ', Rep Name: ' + (bankLd.salesRepFirstName != NULL ? bankLd.salesRepFirstName : '')  
                      + ' ' + (bankLd.salesRepLastName != NULL ? bankLd.salesRepLastName : '');
      return detail;
   } // getLeadDetail
*/
   // map of the leads        
   public Map<String,Lead> leadMap = new Map<String,Lead>();

   public void addLead(String prodType) {
      Lead ld = createLead(this,prodType);
      leadMap.put(payOr401,ld);
      if (partRef != null) {
         addReferral(prodType, ld.Bank_Lead_Id__c);
      }
   } // addLead
   
   public static Integer REF_NAME_LENGTH=Referral__c.Name.getDescribe().getLength();

   public void addReferral(String prodType, String referralId) {
      // make sure name isn't too long
      String refName = (partRef.Company__c+':'+partRef.FirstName__c + ' ' + partRef.LastName__c).left(REF_NAME_LENGTH-2-prodType.length())+'-'+prodType;
      Referral__c referral = new Referral__c(Name=refName
                                   // ,Referral_Partner__c=refPartner.Id
                                    ,Referral_Id__c = referralId
                                    ,Campaign__c=partRef.CampaignId__c
                                    ,Status__c='Pending'
                                    ,PartnerReferral__c = partRef.Id
                                    ,ReferralEntry__c = partRef.ReferralEntry__c
                                    );
       System.debug('addReferral The new referral is: ' + referral);
      if (partRef.DateSubmitted__c != null) {
         referral.DateLeadSubmitted__c = partRef.DateSubmitted__c;
      }
      if (partRef.Partner__r != null && partRef.Partner__r.Account__c != null) {
         referral.ReferringAccountParent__c = partRef.Partner__r.Account__c;
      }
      if (partRef.PartnerBranch__r != null && partRef.PartnerBranch__r.Account__r != null) {
         referral.ReferralSourceAccount__c = partRef.PartnerBranch__r.Account__r.Id;
         referral.Referral_Account__c = partRef.PartnerBranch__r.Account__r.Mirror_Referral_Account__c;
      }
      referralMap.put(payOr401,referral);
   } // addReferral

   // keep the record types for the leads
   public static Map<String,Schema.RecordTypeInfo> rtByNameMap = null;

   public static final String RT_LEAD_PENDING=Label.RT_Pending_Leads;

   public static Id getRecordTypeId(String prodType) {
      // default to payroll if coming in blank
      if (rtByNameMap == null) {
         rtByNameMap = Lead.SObjectType.getDescribe().getRecordTypeInfosByName();
      }
      // TODO - setup a mapping of prodType to record type name for flexibility
      // probably use the RecordType__c custom setting
      String rtName = RT_LEAD_PENDING;
      if (prodType.contains(PROD_INTEREST_PAYROLL)) {
         rtName = RecordTypeHelper.CORE_LEAD;
      } else if (prodType == PROD_INTEREST_401k) {
         rtName = RecordTypeHelper.HRS_LEAD;
      }
      Schema.RecordTypeInfo rtInfo = rtByNameMap.get(rtName);
      Id rtId = (rtInfo != null ? rtInfo.getRecordTypeId() : null);
      return rtId;
   } // getRecordTypeId

   public static Id getPendingLeadRecordTypeId() {
      return getRecordTypeId(RT_LEAD_PENDING);
   } // getPendingLeadRecordTypeId
   
   public static Integer LEAD_COMMENTS_LENGTH=Lead.Comment__c.getDescribe().getLength();
   public static Integer LEAD_DETAIL_LENGTH=Lead.Original_Lead_Detail__c.getDescribe().getLength()-1;

   public static Lead createLead(PartnerWrapper partnerWrap, String prodOfInterest) {
       
      PartnerReferral__c partRef = partnerWrap.partRef;
      String products = (prodOfInterest == PartnerWrapper.PROD_INTEREST_401k ? WebBankLeadHelper.PROD_401k : prodOfInterest); 
      Id recordTypeId = getRecordTypeId(prodOfInterest.split(';')[0]);
      String productDivision = (prodOfInterest == PartnerWrapper.PROD_INTEREST_401k ? 'HRS' : 'Core');

      // the default value
      /*
      String leadSource = partRef.ReferralType__c;
      if (String.isNotBlank(partRef.ReferralType__c)) {
         ReferralType__c refType = ReferralType__c.getInstance(partRef.ReferralType__c);
         if (refType != null && String.isNotBlank(refType.LeadSource__c)) {
            leadSource = refType.LeadSource__c;
         }
      } // if (String.isNotBlank(partRef.ReferralType__c

      // default the value to make sure it's populated
      if (String.isBlank(leadSource)) {
         leadSource = Label.LeadSource_ReferralBank;
      }
      */
      String originalLeadDetail = partnerWrap.getLeadDetail().left(LEAD_DETAIL_LENGTH);
      lead ld = new lead(RecordTypeId = recordTypeId
                                    , Bank_Lead_Id__c = partnerWrap.getReferralId(prodOfInterest.split(';')[0])
                                    , Generate_Bank_Lead_Id__c = false // should be able to take this line out
                                    , Bank_Product_of_Interest__c = prodOfInterest
                                    , Product_Division__c = productDivision
                                    , Products__c = prodOfInterest
                                    , Duplicate_OK__c = true
                                    , Hold_Out__c = true
                                    , Hold_Out_Expiration__c = system.today().addDays(90)
                                    , LastName =  partRef.LastName__c 
                                    , FirstName = partRef.FirstName__c
                                    , Company = partRef.Company__c
                                    , Email = partRef.Email__c
                                    , Phone = partRef.Phone__c
                                    , Street = partRef.StreetAddress__c
                                    , City = partRef.City__c
                                    , State = partRef.State__c
                                    , PostalCode = partRef.ZipPostalCode__c
                                    , Promo_Code__c = partRef.PromoCode__c
                                    , Title = partRef.Title__c                                  
                                    , NumberOfEmployees = (partRef.NumberOfEmployees__c != null ? Integer.valueOf(partRef.NumberOfEmployees__c) : null)
                                    , Comment__c = (String.isNotBlank(partRef.Comments__c) ? partRef.Comments__c.left(LEAD_COMMENTS_LENGTH) : null)
                                   // , LeadSource = leadSource
                                    , Additional_Referring_Name__c = partRef.AdditionalReferringName__c
                                    , Additional_Referring_EmpId__c = partRef.AdditionalReferringEmpId__c
                                    , Line_Of_Business__c = partRef.Line_Of_Business__c
                                    , Date_Lead_Submitted__c = system.today()
                                    , Original_Bank_Submitter__c = partRef.EmpFirstName__c+' '+partRef.EmpLastName__c
                                    , Original_Bank_Emp_Number__c = partRef.EmployeeId__c
                                    , Original_Bank_Branch_Name__c = partRef.BranchName__c
                                    , Original_Bank_Branch_Number__c = partRef.BranchNumber__c
                                    , Original_Lead_Detail__c = originalLeadDetail
                                    , DoNotUseBankTriggerChatter__c = true  // so that the trigger code won't generate a chatter message - generated in the code
                                      //APR0115879
                                    , LatestCampaign__c = partRef.Campaign__c);
      return ld;
   } // createLead
   

   
   public Lead leadPay {
      get {return leadMap.get(PROD_INTEREST_PAYROLL); }
   }
   public Lead lead401 {
      get {return leadMap.get(PROD_INTEREST_401k); }
   }
   
   public Boolean hasLead {
      get {return !leadMap.isEmpty(); }
   }
   
   public Lead primaryLead {
      get {return (hasLead ? leadMap.values()[0] : null); }
   } // primaryLead
   
   public Lead[] getLeads() {
      return leadMap.values();
   } // getLeads
   
   public Referral_Contact__c refCtct = null;
   public Boolean refCtctIsNew = false;
   public Boolean leadSourceSetByRefCtct = false;
      
   public void setRefCtct(Referral_Contact__c p_refCtct) {
      System.debug('setRefCtct hasRefCtct='+(p_refCtct != null));
      refCtct = p_refCtct;
      refCtctIsNew = refCtct != null && refCtct.Id == null;
      /*
      leadSourceSetByRefCtct = !refCtctIsNew;
      if (refCtct != null && refCtct.Id != null) {
         for (Lead ld : leadMap.values()) {
            ld.Referral_Contact__c = refCtct.Id;
            if (String.isNotBlank(refCtct.LeadSourceDefault__c)) {
               ld.LeadSource = refCtct.LeadSourceDefault__c;
            }
         }
         for (Referral__c ref : referralMap.values()) {
            ref.Referral_Contact__c = refCtct.Id;
            ref.Referral_Account__c = refCtct.Referral_Account__c;
            
            ref.ReferralSourceContact__c = refCtct.Contact__c;
            ref.ReferralSourceAccount__c = refCtct.Contact__r.AccountId;
            if (String.isNotBlank(refCtct.LeadSourceDefault__c)) {
               ref.SellingLeadSource__c = refCtct.LeadSourceDefault__c;
            }
         } // for (Referral__c ref
         
      } // if (refCtct.Id != null
      */
   } // setRefCtct
      
   public void setOwnerId(Id ownerId, Boolean setPay, Boolean set401) {
      System.debug('setOwnerId ownerId='+ownerId);
      if (ownerId != null) {
         if (setPay && payrollOwnerId == null) {
            payrollOwnerId = ownerId;
            System.debug('setOwnerId payrollOwnerId='+payrollOwnerId);
         } // if (setPay
   
         if (setPay && leadPay != null && leadPay.OwnerId == null) {
            leadPay.OwnerId = ownerId;
         }
         if (set401 && lead401 != null && lead401.OwnerId == null) {
            lead401.OwnerId = ownerId;
         }
      } // if (ownerId != null
   } // setOwnerId
      
   // is there a lead without an owner assigned?
   public Boolean missingOwner() {
      Boolean missing = false;
      for (Lead ld : leadMap.values()) {
         if (ld.OwnerId == null) {
            missing = true;
            break;
         }
      } // for (Lead ld
      return missing;
   } // missingOwner
      
   // if an exception occurs, log it on all of the leads
   public void setExceptionReason(String exceptionReason, Id recordTypeId) {
      System.debug('setExceptionReason exceptionReason='+exceptionReason);
      
      for (Lead ld : leadMap.values()) {
         ld.Exception_Reason__c = exceptionReason;
         ld.RecordTypeId = recordTypeId;
      }
      
      for (Referral__c ref : referralMap.values()) {
         ref.Exception_Reason__c = exceptionReason;
      }
   } // setExceptionReason
      
   public void setDefaultOwnership() {
      Id userId = UserInfo.getUserId();
      for (Lead ld : leadMap.values()) {
         if (ld.OwnerId == null) {
            ld.OwnerId = userId;
            ld.Hold_Out__c = false;
            ld.Hold_Out_Expiration__c = null;
            ld.UseZipAssignmentRules__c = true;
         } // if (ld != null
      
      } // for (Lead ld 
   } // setDefaultOwnership
   
   // Get all of the leads that are not exceptions (pending lead record type)
   public Lead[] getNonExceptionedLeads() {
      Lead[] leads = new Lead[]{};
      Id pendingRtId = getPendingLeadRecordTypeId();
      for (Lead ld : leadMap.values()) {
         if (ld.RecordTypeId != pendingRtId) {
            leads.add(ld);
         }
      } // for (Lead ld
      return leads;
   } // getNonExceptionedLeads
      
   public void checkForCampaignMembers(CampaignMember[] newCampaignMembers) {
      for (Lead ld : getNonExceptionedLeads()) {
         checkLeadForCampaign(ld,newCampaignMembers);
      }
   } // checkForCampaignMembers
      
   private void checkLeadForCampaign(Lead ld, CampaignMember[] newCampaignMembers) {
      if (ld.Id != null && partRef.CampaignId__c != null) {
         newCampaignMembers.add(new CampaignMember(CampaignId=partRef.CampaignId__c, LeadId=ld.id));
      }
   } // checkLeadForCampaign
      
   public void setDuplicate(Boolean hasDupe, Lead dupLead, Account dupAcct) {
      dupeFound = hasDupe;
      if (dupeFound) {
         setDupeReferral(referralPay,dupLead,dupAcct);
         setDupeReferral(referral401,dupLead,dupAcct);
      }
   } // setDuplicate
   
   private void setDupeReferral(Referral__c ref, Lead dupLead, Account dupAcct) {
      if (ref != null) {
         ref.LeadDuplicate__c = (dupLead != null ? dupLead.Id : null);
         ref.Account__c = (dupAcct != null ? dupAcct.Id : null);
      }
   } // setDupeReferral
   
   public ReferralJoin__c refJoin = null;
   public void checkForMultipleReferrals(ReferralJoin__c[] refJoins) {
      if (refJoin == null && referralMap.size() > 1) {
      //if (referralPay != null && referral401 != null && refJoin == null) {
         refJoin = new ReferralJoin__c();
         refJoins.add(refJoin);
      }
   } // checkForMultipleReferrals
   
   public void getReferrals(Referral__c[] newReferrals) {
      for (String key : leadMap.keySet()) {
         checkReferral(referralMap.get(key), leadMap.get(key), newReferrals);
      }
      //checkReferral(referralPay, leadPay, newReferrals);
      //checkReferral(referral401, lead401, newReferrals);

   } // getReferrals
   
   private void checkReferral(Referral__c referral, Lead ld, Referral__c[] newReferrals) {
      if (ld != null && ld.Id != null && referral != null) {
         System.debug('checkReferral referral=' + referral);
         System.debug('checkReferral referral=' + ld);
         referral.SourceLead__c = ld.Id;
         referral.User__c=ld.OwnerId;
         referral.OwnerId = ld.OwnerId;
         referral.SellingLeadSource__c = ld.LeadSource;
         
         if (refJoin != null && refJoin.Id != null) {
            referral.ReferralJoin__c = refJoin.Id;
         }
         newReferrals.add(referral);
      }
   } // checkReferral
   
   // return the leads not matching the passed in record type id - ex get the leads without the pending record type
   public Id[] getLeadIdsNotMatchingRT(Id recordTypeId) {
      Id[] leadIds = new Id[]{};
      for (Lead ld : leadMap.values()) {
         if (ld.Id != null && ld.RecordTypeId != recordTypeId) {
            leadIds.add(ld.Id);
         }
      } // for (Lead ld
      return leadIds;
   } // getLeadIdsNotMatchingRT

   // the referral id will be based off of the PartnerReferral__c name field. A product identifier will be added to each individual lead.   
   public String getReferralId(String prodType) {
      String referralId = partRef.Name;
      if (String.isNotBlank(prodType)) {
         if (prodType == (PROD_INTEREST_PAYROLL)) {
            referralId += 'p';
         } else if (prodType == PROD_INTEREST_401K) {
            referralId += 'k';
         }
      } // if (String.isNotBlank(prodType
      return referralId;
   } // getReferralId
   
} // class PartnerWrapper