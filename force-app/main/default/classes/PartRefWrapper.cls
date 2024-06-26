/* 
 * Wrapper class for the PartnerReferral__c object
 *
 * History
 * -------
   06/22/2018 Dan Carmen          add additional logging
   09/09/2019 Dan Carmen          Add workable flag
   12/23/2019 Dan Carmen          Add a flag for if it's amplifinity
   04/14/2021 Dan Carmen          Add a 1 argument constructor
   11/11/2022 Pujitha Madamanchi  Populate form fill from Lead
 
 */
public with sharing class PartRefWrapper {
   public PartRefWrapper(PartnerReferral__c p_partRef) {
      partRef = p_partRef;
   }
   
   public PartRefWrapper(PartnerReferral__c p_partRef, Lead p_ld, Contact p_ctct) {
      partRef = p_partRef;
      ld = p_ld;
      ctct = p_ctct;
      partRef.Lead__c = (ld != null ? ld.Id : null);
      partRef.Contact__c = (ctct != null ? ctct.Id : null);
      partRef.Account__c = (ctct != null ? ctct.AccountId : null);
      System.debug('class:PartRefWrapper, ctct :'+ctct );
      String ownedBy = getOwnedBy();
      if (String.isNotBlank(ownedBy)) {
         llc = LeadLoaderConfig__c.getInstance(ownedBy);
      }
       if(ld!=null && ld.Form_Fill_Date__c!= null){
           partRef.Form_Fill_Date__c = ld.Form_Fill_Date__c;
       }
       if(ctct!=null && ctct.Form_Fill_Date__c!= null){
           partRef.Form_Fill_Date__c = ctct.Form_Fill_Date__c;
       }
      setDupeFields();
      StringHelper.addToProcessNotes(partRef,'PartRefWrapper ownedBy='+ownedBy+' llc='+(llc != null ? llc.Name : 'NotFound')+' hasLead='+(ld != null)+' hasCtct='+(ctct != null)+' workable='+workable);
   } // PartRefWrapper
    
   public void setDupeFields() {
      if (ld != null) {
         partRef.DuplicateCheckStatus__c = ld.DuplicateCheckStatus__c;
         partRef.DuplicateNotWorkableReason__c = ld.DuplicateNotWorkableReason__c;
      } else if (ctct != null) {
         partRef.DuplicateCheckStatus__c = ctct.DuplicateCheckStatus__c;
         partRef.DuplicateNotWorkableReason__c = ctct.DuplicateNotWorkableReason__c;
      }
   } // setDupeFields

   // was the routing determined for this wrapper?
   public Boolean routingHandled = false;      
   public PartnerReferral__c partRef = null;
   public Referral__c ref = null;
   public Lead ld;
   public Contact ctct;
   public LeadLoaderConfig__c llc;
   public Boolean workable{
      get {return (partRef != null && partRef.Workable__c == TrackRecordEntry.WORKABLE);}
   }
   public amp_dev__Amp_Referral__c ampReferral;
   public amp_dev__Amp_Advocate__c ampAdvocate;
   public Opportunity oppToUseForRef = null;
   
   public Boolean isOasis{
      get {return (llc != null && llc.IsOasis__c);}
   } // isOasis

   // is this an amplifinity referral?   
   public Boolean isAmplifinity{
      get {return (llc != null && llc.IsAmplifinity__c);}
   } // isAmplifinity
   
   public Boolean checkWorkable{
      get {return (llc != null && llc.CheckWorkable__c);}
   } // checkWorkable
      
   public static Integer REF_NAME_SIZE=Referral__c.Name.getDescribe().getLength();

   public String getName() {
      String name=String.isNotBlank(partRef.FirstName__c) ? partRef.FirstName__c+' ' : ''; 
      name += String.isNotBlank(partRef.LastName__c) ? partRef.LastName__c : '';
      name += String.IsNotBlank(partRef.Company__c) ? (String.isNotBlank(name) ? '-' : '')+partRef.Company__c : '';
      if (String.isBlank(name)) {
         name = 'Lead Created '+DateTime.now().format('M/d/yyyy HH:mm:ss');
      }
      name = name.left(REF_NAME_SIZE);
      return name;
   } // getName
      
   public String getOwnedBy() {
      String ownedBy = (ld != null ? ld.OwnedByPrev__c : (ctct != null ? ctct.OwnedByPrev__c : null));
      if (String.isBlank(ownedBy)) {
         ownedBy = (ld != null ? ld.OwnedBy__c : (ctct != null ? ctct.OwnedBy__c : null));
      }
      if (String.isBlank(ownedBy)) {
         ownedBy = partRef.Source__c;
      }
      return ownedBy;
   } // getOwnedBy

   public void setRouting(Id newOwnerId, LeadRouting__c leadRouting) {
      String destination = (leadRouting != null ? (String.isNotBlank(leadRouting.Destination__c) ? leadRouting.Destination__c : leadRouting.Name) : null);
      setRouting(newOwnerId, destination,null);
   } // setRouting

   public void setRouting(Id newOwnerId, String destination) {
      setRouting(newOwnerId, destination, null);
   } // setRouting
      
   public void setRouting(Id newOwnerId, String destination, String additionalInfo) {
      if (newOwnerId != null) {
         ref.OwnerId = newOwnerId;
         partRef.Destination__c = destination;
         routingHandled = true;
      }
      StringHelper.addToProcessNotes(partRef,'setRouting newOwnerId='+newOwnerId+' destination='+destination+(String.IsNotBlank(additionalInfo) ? '; '+additionalInfo : ''));
   } // setRouting
   
} // class PartRefWrapper&