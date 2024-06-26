/*  
 * Class to hold the remote actions for the NSS View page.
 * 
 * History
 * -------
   01/24/2017 Dan Carmen   Created

   
 */
global without sharing class NSSViewRemoteActions {
    
   // constructor to use this as an extension.
   public NSSViewRemoteActions(NSSViewController nvc) {
      
   } // NSSViewRemoteActions
   
   global class OppWrapper {
      public OppWrapper(Opportunity opp) {
         Time thisTime = Time.newInstance(12, 0, 0, 0);
         id = opp.Id;
         name = opp.Name;
         stage = opp.StageName;
         runDate = opp.CloseDate != null ? DateTime.newInstance(opp.CloseDate,thisTime).format('M/d/yyyy') : '';
         owner = opp.Owner.Name;
         createDate = opp.CreatedDate.format('M/d/yyyy HH:mm a');
         createBy = opp.CreatedBy.Name;
         source = String.isNotBlank(opp.NSS_Source__c) ? opp.NSS_Source__c : ''; 
      } // OppWrapper
      public String id{get;set;}
      public String name{get;set;}
      public String stage{get;set;}
      public String runDate{get;set;}
      public String owner{get;set;}
      public String createDate{get;set;}
      public String createBy{get;set;}
      public String source{get;set;}
      
   } // class OppWrapper

   @RemoteAction 
   global static OppWrapper[] getOpps(String objectId) {
      Opportunity[] allOpps = OpptyMethods.getOpportunities(objectId,NSSViewController.NBR_MONTHS, 50);
      OppWrapper[] wraps = new OppWrapper[]{};
      for (Opportunity opp : allOpps) {
         wraps.add(new OppWrapper(opp));
      }
      return wraps;
   } // getOpps
   
   global class ReferralPartner {
      public String partnerType{get;set;}
      public String referTo{get;set;}
      public String referToId{get;set;}
      public Boolean assignedToDsa{get;set;}
      public String phone{get;set;}
      public String email{get;set;}
   } // ReferralPartner
   
   @RemoteAction 
   global static ReferralPartner[] getReferralPartners(String objectId, String fullList) {
      ReferralPartner[] referralPartners = new ReferralPartner[]{};
      System.debug('getReferralPartners objectId='+objectId+' fullList='+fullList);
      if (String.isNotBlank(objectId)) {
         ReferralController refControl = new ReferralController(UserHelper.SO_CORE);
         refControl.isFunctionNSS = true;
         refControl.refObjectId = objectId;
         refControl.refObjectIdIsValid();
         refControl.setRecordInfo();
         if (refControl.hasExtendedList) {
            Boolean useShortList = (fullList == 'false');
            if (refControl.useShortList != useShortList) {
               refControl.useShortList = useShortList;
               refControl.setDisplayList();
            }
         } // if (refControl.hasExtendedList
         refControl.useShortList = (fullList == 'false');
         
         Map<Id,ReferralPartner[]> idLookupMap = new Map<Id,ReferralPartner[]>();
         for (ReferralWrapper refWrap : refControl.displayList) {
            ReferralPartner refPart = new ReferralPartner();
            refPart.partnerType = refWrap.displayName;
            refPart.referTo = '';
            refPart.phone = '';
            refPart.email = '';
            refPart.referToId = '';
            if (refWrap.isOpenTerritory) {
               refPart.referTo = 'Open Territory';
            } else if (refWrap.isUnknownTerritory) {
               refPart.referTo = 'Unknown Territory';
            } else {
               if (refWrap.ref.User__c != null) {
                  ReferralPartner[] refPartners = idLookupMap.get(refWrap.ref.User__c);
                  if (refPartners == null) {
                     refPartners = new ReferralPartner[]{};
                     idLookupMap.put(refWrap.ref.User__c,refPartners);
                  }
                  refPartners.add(refPart);
               }
               //refPart.referTo = refWrap.referToName;
            }
            refPart.assignedToDsa = refWrap.ref.AssignedToDSA__c;
            /*
                           <apex:outputText rendered="{!rec.isOpenTerritory}" value="Open Territory" />
               <apex:outputText rendered="{!rec.isUnknownTerritory}" value="Unknown Territory" />

               <apex:outputField rendered="{!rec.referToUser}" style="white-space:nowrap;" value="{!rec.ref.User__c}" />
               <apex:outputField rendered="{!rec.referToContact}" style="white-space:nowrap;" value="{!rec.ref.Contact__c}" />
               <apex:outputField rendered="{!rec.referToRefContact}" style="white-space:nowrap;" value="{!rec.ref.Referral_Contact__c}" />
               <apex:outputText rendered="{!rec.ref.AssignedToDSA__c}" value="(DSA)" />
             */
            referralPartners.add(refPart);
         } // for (ReferralWrapper refWrap
         if (!idLookupMap.isEmpty()) {
            Map<Id,User> userMap = new Map<Id,User>([Select Id, Name, Email, Phone, MobilePhone from User where Id in :idLookupMap.keySet()]);
            for (Id userId : idLookupMap.keySet()) {
               User usr = userMap.get(userId);
               if (usr != null) {
                  for (ReferralPartner refPart : idLookupMap.get(userId)) {
                     refPart.referToId = usr.Id;
                     refPart.referTo = usr.Name + (refPart.assignedToDsa ? '(DSA)' : '');
                     refPart.email = usr.Email;
                     if (usr.MobilePhone != null) {
                        refPart.phone += usr.MobilePhone+' (Mobile)  ';
                     } 
                     if (usr.Phone != null) {
                        refPart.phone += usr.Phone+' (Work)';
                     }
                  } // for (ReferralPartner refPart
               } // if (usr != null
            } // for (Id userId
         }
      } // if (String.isNotBlank
      return referralPartners;
   } // getReferralPartners
   
   global class AssetWrapper {
      public AssetWrapper(Asset asst) {
         Time thisTime = Time.newInstance(12, 0, 0, 0);
         id = asst.Id;
         name = asst.Name;
         planCode = String.IsNotBlank(asst.Product_Plan_Code__c) ? asst.Product_Plan_Code__c : '';
         startDate = asst.Start_Date__c != null ? DateTime.newInstance(asst.Start_Date__c,thisTime).format('M/d/yyyy') : '';
         nbrParticipants = asst.Nbr_Participants__c != null ? String.valueOf((Integer)asst.Nbr_Participants__c) : '';
         bundle = String.isNotBlank(asst.Bundle_Code__c) ? asst.Bundle_Code__c : '';
         lostDate = asst.Plan_Cancel_Date__c != null ? DateTime.newInstance(asst.Plan_Cancel_Date__c,thisTime).format('M/d/yyyy') : '';
         lostReason = String.isNotBlank(asst.Plan_Lost_Reason__c) ? asst.Plan_Lost_Reason__c : '';
         System.debug('AssetWrapper name='+name+' planCode='+planCode+' startDate='+startDate); 
      } // AssetWrapper
      
      public String id{get;set;}
      public String name{get;set;}
      public String planCode{get;set;}
      public String startDate{get;set;}
      public String nbrParticipants{get;set;}
      public String bundle{get;set;}
      public String lostDate{get;set;}
      public String lostReason{get;set;}
   } // classAssetWrapper
   
   @RemoteAction
   global static AssetWrapper[] getAssets(Id acctId, String activeOrInactive) {
      Asset[] assets = NSSViewHelper.getAssets(acctId, activeOrInactive);
      AssetWrapper[] wraps = new AssetWrapper[]{};
      for (Asset asst : assets) {
         wraps.add(new AssetWrapper(asst));
      }
      return wraps;
   } // getAssets

   global class CtctWrapper {
      public CtctWrapper(Lead ld) {
         Time thisTime = Time.newInstance(12, 0, 0, 0);
         id = ld.Id;
         name = (String.isNotBlank(ld.FirstName) ? ld.FirstName+' ' : '') + ld.LastName;
         title = (String.isNotBlank(ld.Title) ? ld.Title : '');
         phone = ld.phone != null ? ld.phone : '';
         doNotCall = String.valueOf(ld.DoNotCall);
         significant = String.valueOf(ld.SignificantLead__c);
         lastModified = ld.LastModifiedDate.format('M/d/yyyy HH:mm a');
         lastActivity = ld.LastActivityDate != null ? DateTime.newInstance(ld.LastActivityDate,thisTime).format('M/d/yyyy') : '';
      } // CtctWrapper
      
      public CtctWrapper(Contact ctct) {
         Time thisTime = Time.newInstance(12, 0, 0, 0);
         id = ctct.Id;
         name = ctct.Name;
         title = (String.isNotBlank(ctct.Title) ? ctct.Title : '');
         phone = ctct.phone != null ? ctct.phone : '';
         doNotCall = String.valueOf(ctct.DoNotCall);
         significant = String.valueOf(ctct.SignificantContact__c);
         lastModified = ctct.LastModifiedDate.format('M/d/yyyy HH:mm a');
         lastActivity = ctct.LastActivityDate != null ? DateTime.newInstance(ctct.LastActivityDate,thisTime).format('M/d/yyyy') : '';
      } // CtctWrapper
      
      public String id{get;set;}
      public String name{get;set;}
      public String title{get;set;}
      public String phone{get;set;}
      public String doNotCall{get;set;}
      public String significant{get;set;}
      public String lastModified{get;set;}
      public String lastActivity{get;set;}
      
   } // class CtctWrapper
   
   // when the user asks for more records, how many more are we giving them?
   public static Integer MORE_VALUE=10;
   
   // get the other contacts
   // objectType - basically if we're sourced from the account(contact) or lead
   // the objectId the source account or if a lead the lead company we're starting with
   // significantId - if this is a lead, it will be the same as the lead we started on.
   // the number of records we started with - this will return that number plus
   // the max number of records we will retrieve
   @RemoteAction  
   global static CtctWrapper[] getOtherCtcts(String objectType, String objectId, String selectedId, String p_nbrRecs, String p_maxRecs) {
      CtctWrapper[] wraps = new CtctWrapper[]{};
      Integer maxRecs = (String.isNotBlank(p_maxRecs) ? Integer.valueOf(p_maxRecs) : 0);
      Integer curCount = (String.isNotBlank(p_nbrRecs) ? Integer.valueOf(p_nbrRecs) : 0);
      System.debug('getOtherCtcts objectType='+objectType+' objectId='+objectId+' selectedId='+selectedId+' p_nbrRecs='+p_nbrRecs+' curCount='+curCount+' p_maxRecs='+p_maxRecs+' maxRecs='+maxRecs);
      // make sure we don't return more than we need to
      Integer nbrToReturn = (curCount + MORE_VALUE > maxRecs ? maxRecs : curCount + MORE_VALUE);
      if (objectType == ObjectHelper.OBJECT_LEAD) {
         wraps = checkLeads(objectId, selectedId, nbrToReturn);
      } else if (objectType == ObjectHelper.OBJECT_ACCOUNT) {
         wraps = checkCtcts(objectId, selectedId, nbrToReturn);
      }
      System.debug('getOtherCtcts wraps='+wraps.size());
      return wraps;
   } // getOtherCtcts
   
   global static CtctWrapper[] checkLeads(String objectId, String selectedId, Integer nbrToReturn) {
      CtctWrapper[] wraps = new CtctWrapper[]{};
      try {
         for (Lead ld : [Select Id
                            ,Name
                            ,City
                            ,Company
                            ,Current_Prior_Method__c
                            ,DoNotCall
                            ,Email
                            ,FirstName
                            ,HasOptedOutOfEmail
                            ,LastActivityDate
                            ,LastModifiedDate
                            ,LastName
                            ,Lead_Company__c
                            ,LeadGroupId__c
                            ,No_Longer_With_Company__c
                            ,Phone
                            ,PostalCode
                            ,Salutation
                            ,SignificantLead__c
                            ,State
                            ,Street
                            ,Title
                        From Lead
                       Where Lead_Company__c = :objectId
                         and Id != :selectedId
                         and No_Longer_With_Company__c = false
                       order by SignificantLead__c desc, LastModifiedDate desc
                        limit :nbrToReturn]) {
            wraps.add(new CtctWrapper(ld));
         } // for (Lead ld
      } catch (Exception e) {
         System.debug('checkLeads e='+e.getMessage());
      }
      return wraps;
   } // checkLeads
   
   global static CtctWrapper[] checkCtcts(String objectId, String selectedId, Integer nbrToReturn) {
      CtctWrapper[] wraps = new CtctWrapper[]{};
      try {
         for (Contact ctct : [Select Id
                                    ,AccountId
                                    ,Name
                                    ,Phone
                                    ,DoNotCall
                                    ,SignificantContact__c
                                    ,LastModifiedDate
                                    ,LastActivityDate
                                    ,Title
                                From Contact
                               Where AccountId = :objectId
                                 and Id != :selectedId
                                 and Sales_Contact__c = true
                                 and No_Longer_With_Company__c = false
                               order by SignificantContact__c desc, LastModifiedDate desc
                               limit :nbrToReturn]) {
            wraps.add(new CtctWrapper(ctct));          
         } // for (Contact ctct
      } catch (Exception e) {
         System.debug('checkCtcts e='+e.getMessage());
      }
      return wraps;
   } // checkCtcts
   
} // class NSSViewRemoteActions