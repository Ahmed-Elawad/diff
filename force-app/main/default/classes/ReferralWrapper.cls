/* 
 * Wrapper for the Referral information. This is a separate class from the ReferralController because this
   has to be defined as global when it implements the Comparable interface and we didn't want to set the whole
   controller to global.
 *
 * History
 * -------
 * 07/23/2012 Dan Carmen   Created
 * 09/25/2015 Cindy Freeman      added methods for Commission Products 
 * 03/28/2016 Cindy Freeman      added check of Send_Email in getReferralType method
   05/24/2017 Dan Carmen         added hasQueueName
   08/14/2018 Cindy Freeman		 added logic to label PEOC and RSR reps
   10/04/2019 Jake Hinds		 added specific queue functionality
   06/08/2021 Eric Porter       Incorporated Referral Contact  
   06/19/2023 Dan Carmen         added meetsSegmentCriteria

 */
global with sharing class ReferralWrapper implements Comparable {

   /** Is this record selected? */
   public Boolean selected{get;set;}
    
   // if this was selected, did we select an integrated partner with it?
   public Boolean selectedWithIntegratedPartner=false;
   
   public Boolean isAncillary{get;set;}
        
   /** Is the title locked for editing? */
   public Boolean lockTitle{get;set;}
   
   public ReferralWrapper() {
      ref = new Referral__c();
      Date tempDate = Date.today();
      displayName = null;
      lockTitle = false;
      selected = false;
      isAncillary = false;
      hasDSA = false;
      hasDSM = false;
      displayName = null;
      hasSingleProduct = false;
      hasMultipleProducts = false;  
   } // ReferralWrapper
        
   public Referral__c ref{get;set;}
   
   /** Does this have a User associated with it? */
   public Boolean hasUser{
      get {return ref.User__c != null;}
   } // hasUser

   /** Does the referral have a contact associated with it? */
   public Boolean hasContact {
      get {return ref.Contact__c != null;}
   }
    
   public Boolean hasQueueName{
      get {return (refPartner != null && String.isNotBlank(refPartner.QueueName__c));}
   } // hasQueueName
   
   // does this have a display name?
   public Boolean hasDisplayName{
      get {return (String.isNotBlank(displayName)); }
   }
   
   public String displayName{get;set;}
     
   /** If there's a zip code, no user or contact, and there is a DSA/DSM - will be an open territory. */
   public Boolean isOpenTerritory {
      get {
         return (refPartner != null && refPartner.Partner_Type__c != ReferralController.REF_EXTERNAL && !hasUser && !hasContact && (hasDSA || hasDSM));
      }
   } // isOpenTerritory
   
   public Boolean isUnknownTerritory {
      get {
         return (refPartner != null && refPartner.Partner_Type__c != ReferralController.REF_EXTERNAL && !hasUser && !hasContact && !hasDSA && !hasDSM && !referToQueue);
      }
   } // isUnknownTerritory
   
   public Boolean ownerIsQueue = false;
     
   /** How this referral will be sent to the user
    */
   public String referralType{
      get {return ((hasUser || ownerIsQueue) && !ref.Send_Email__c ? 'Opportunity' : 'Email'); } // get      
   } // referralType
   
   global Integer compareTo(Object objectToCompareTo) {
      if (objectToCompareTo != null) {
         ReferralWrapper compareRw = (ReferralWrapper)objectToCompareTo;
         String refPartName1 = (refPartner != null ? makeSortKey(refPartner.Sort_Order__c, refPartner.Name) : '');
         String refPartName2 = (compareRw.refPartner != null ? makeSortKey(compareRw.refPartner.Sort_Order__c, compareRw.refPartner.Name) : '');
//         if (ref.Name != null && compareRw.ref.Name != null) {
//            return ref.Name.compareTo(compareRw.ref.Name);
//         }
         System.debug('compareTo refPartName1='+refPartName1+' refPartName2='+refPartName2);
         return refPartName1.compareTo(refPartName2);
      }
      return -1;
   } // compareTo
      
   public String makeSortKey(Decimal sortOrder, String name) {
      String sortOrderStr = (sortOrder != null ? Utilities.leftPad(String.valueOf(sortOrder), '0', 4) : '9999');
      String key = sortOrderStr+name;
      return key;
   }
   // referral notes for this process
   public void addToReferralNotes(String msg) {
      addToRefNotes(ref,msg);
      //ref.ReferralNotes__c = (String.isBlank(ref.ReferralNotes__c) ? '' : ref.ReferralNotes__c+'\n ') + msg;
   } // addToReferralNotes
   
   public static void addToRefNotes(Referral__c p_ref, String p_msg) {
      p_ref.ReferralNotes__c = (String.isBlank(p_ref.ReferralNotes__c) ? '' : p_ref.ReferralNotes__c+'\n ') + p_msg;
   } // addToRefNotes

   //public String saveResult{get;private set;}
   
   //public void addToSaveResult(String msg) {
   //   saveResult = (saveResult != null ? saveResult+'\n '+msg : msg);
   //} // addToSaveResult
   
   /** When adding a row, this is the type the user selected. */
   public String selectedPartnerType{get;set;}
   
   /** temporary holder for this record so we can later get the line item id. */
   public OpportunityLineItem oli{get;set;}
   
   /** The referring rep's opportunity. */
   public Opportunity oppReferring{get;set;}
   /** The selling rep's opportunity. */
   public Opportunity oppSelling{get;set;}
   public Case glCase{get;set;}
   
   // did this opportunity already exist or are we creating it now?
   public Boolean sellingOppWasExisting = false;

   public Referral_Contact__c refCtct{get;set;}
   
   public void setReferralPartner(Referral_Partner__c p_refPartner, List<String> prodList, String defProd, List<String> commprodList) {
      ref.Referral_Partner__c = p_refPartner.Id;
      //ref.Referral_Partner__r = rp;
      refPartner = p_refPartner;

      displayName = (!p_refPartner.UseRefPartnerName__c && String.isNotBlank(p_refPartner.Sales_Org__c) ? new UserHelper().getProdTranslation(p_refPartner.Sales_Org__c) : null);
      if (displayName == null) {
         displayName = p_refPartner.Name;
      }
      
      setReferTo();
      
      System.debug('setReferralPartner name='+refPartner.Name+' displayName='+displayName+' UseContact__c='+refPartner.UseContact__c+' Contact__c='+refPartner.Contact__c+' UseRefContact__c='+refPartner.UseRefContact__c+' Referral_Contact__c='+refPartner.Referral_Contact__c+' UseRefPartnerName__c='+p_refPartner.UseRefPartnerName__c);
      if (refPartner.UseContact__c && refPartner.Contact__c != null) {
         // default the contact record
         ref.Contact__c = refPartner.Contact__c;
      } else if (refPartner.UseRefContact__c  && refPartner.Referral_Contact__c != null) {
         // default the referral contact record
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setReferralPartner setting referral contact'));
         System.debug('setReferralPartner setting referral contact');
         ref.Referral_Contact__c = refPartner.Referral_Contact__c;
      } else if (refPartner.UseUser__c && refPartner.Default_User__c != null) {
         ref.User__c = refPartner.Default_User__c;
      } 
       if(refPartner.UseUser__c && refPartner.Referral_Contact__c != null){
         System.debug('WE set the referral partner to be visible!!');
         ref.Referral_Contact__c = refPartner.Referral_Contact__c;
      }
      setupProducts(prodList, defProd);
      setupCommProducts(commProdList);
   } // setReferralPartner
   
   public Boolean hasSingleProduct{get; private set;}
   public Boolean hasMultipleProducts{get; private set;}
   
   public List<SelectOption> productOptions{get;private set;}
   
   private void setupProducts(List<String> prodList, String defProd) {
      if (prodList != null && !prodList.isEmpty()) {
         hasSingleProduct = (prodList.size() == 1);
         hasMultipleProducts = (prodList.size() > 1);
         if (hasSingleProduct) {
            ref.ProductReferred__c = prodList[0];
         } else if (hasMultipleProducts) {
            ref.ProductReferred__c = defProd;
            productOptions = new List<SelectOption>();
            prodList.sort();
            for (String prod : prodList) {
               if (String.isBlank(ref.ProductReferred__c)) {
                  ref.ProductReferred__c = prod;
               }
               productOptions.add(new SelectOption(prod,prod));
            } // for (String prod
         }
      } // if (prodList != null
   } // setupProducts
   
   public List<SelectOption> commProductOptions{get;private set;}
   public String selectedCommProducts{get; set;}
   public Boolean requiredCommProducts{get; private set;}
    
   private void setupCommProducts(List<String> commProdList) { 
        selectedCommProducts = '';
        requiredCommProducts = false;
        commProductOptions = new List<SelectOption>();
        if (commProdList != null && !commProdList.isEmpty())      
        {   for (String prod: commProdList)
         {  commProductOptions.add(new SelectOption(prod, prod)); }
            requiredCommProducts = true;         
        }        
   } // setupCommProducts
    
   public Referral_Partner__c refPartner{get;set;}
   //public ZipWrapper zipWrapper{get;set;}
   public Boolean meetsSegmentCriteria=false;
   
   public void setZipWrapperAttributes(ZipWrapper zipWrapper) {
      if (zipWrapper != null) {
         // did we select this zip because it actually meets the criteria of the incoming record?
         meetsSegmentCriteria = zipWrapper.meetsSegmentCriteria;
         if (zipWrapper.assistant != null && zipWrapper.assistant.usr != null) {
            ref.DSA__c = zipWrapper.assistant.usr.Id;
         }
                     
         if (zipWrapper.manager != null && zipWrapper.manager.usr != null) {
            ref.DSM__c = zipWrapper.manager.usr.Id;
         }
      } // if (zipWrapper != null
   } // setZipWrapperAttributes

   public void setReferTo() {
      referToContact = (ref != null && refPartner != null && refPartner.UseContact__c);
      referToRefContact = (ref != null && refPartner != null && refPartner.UseRefContact__c);
      referToUser = (ref != null && refPartner != null && refPartner.UseUser__c);
      referToQueue = (ref != null && refPartner != null && refPartner.UseQueue__c);
      allowReferToEnterable = (refPartner == null || !refPartner.LockReferTo__c);
   }
   public Boolean referToContact{get;set;}
   public Boolean referToRefContact{get;set;}
   public Boolean referToUser{get;set;}
   public Boolean referToQueue{get;set;}
       
   /** Is the refer to field enterable? */
   public Boolean referToEnterable{
      get { return (selected && lockTitle && allowReferToEnterable); }
   }

   public Boolean hasDSA{get;set;}
   public Boolean hasDSM{get;set;}
   
   public void setVirtualFlag(User usr) {
      refUserIsPEOC = false;
      refUserIsRSR = false;
      refUserIsVirtual = (usr != null && (usr.HR_Person_Id__c == UserHelper.VIRTUAL_SALES_PERSON_ID
                                                   || usr.HR_Person_Id__c == UserHelper.HRS_VIRTUAL_SALES_PERSON_ID));
      try {
      	if (!refUserIsVirtual && usr != null && String.isNotBlank(usr.NSS_Team__c)) {
         	NSSTeamMap__c ntm = NSSTeamMap__c.getInstance(usr.NSS_Team__c);
         	refUserIsVirtual = (ntm != null && ntm.IsVirtual__c);
         }
         if (usr != null && !String.isBlank(usr.Title)) {
      	 	refUserIsPEOC = (usr.Title.contains('PEO Centric') ? true : false);
      	 	refUserIsRSR = (usr.Title.contains('Regional Sales Representative') ? true : false);
         }
      } catch (Exception e) {
         System.debug('setVirtualFlag or relabel based on Title exception='+e.getMessage()+'; '+e.getStackTraceString());
      }
      
          
   } // setVirtualFlag
   
   public Boolean refUserIsVirtual{get;set;}
   public Boolean refUserIsRSR{get;set;}
   public Boolean refUserIsPEOC{get;set;}
   
   public Boolean allowReferToEnterable=true;
   
   public Prospect_Ownership__c prospectOwnership = null;
   public OpportunityTeamMember otm = null;
   
   public Event evt = null;
   public Task tsk = null;
   
} // class ReferralWrapper