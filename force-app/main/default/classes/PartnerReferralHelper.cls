/* Methods used for processing partner referrals.
   
  History
  -------
  09/28/2015 Dan Carmen   Created
  02/13/2016 Dan Carmen   Additional Changes
  10/19/2016 Dan Carmen   Add additional fields into the query.
  02/01/2017 Cindy Freeman  move trigger after action for partner referral into here instead of being in trigger
  02/16/2017 Cindy Freeman  added to triggerCheckBeforeActions to look at Create_Market_Tracking flag
  05/02/2017 Cindy Freeman   changed to only sent records to MarketTrackingMethods in after trigger actions
  10/29/2018 Dan Carmen     Add ProcessMCT__c field to force the creation of a Marketing Call Tracking record.
  01/31/2019 Dan Carmen     Ability to pop a weblead to a user.
  10/09/2019 Dan Carmen     Check if description is blank instead of running user
  10/18/2019 Matt Fritschi  Added the 401k Bank Centric Rep to the query.
  10/15/2020 Dan Carmen     Clean up code
  03/26/2021 Jacob Hinds       Adding RJMethods call
  04/06/2020 Pujitha Madamanchi  Populate Creted by Timeframe on creation
  08/10/2021 Dan Carmen        Remove check for Master_Partner_Referral__c for the ecom records - problem with Marketo.
  06/01/2020 Pujitha Madamanchi  Fetch Primary zip segment field
   01/19/2024 Pujitha Madamanchi : Remove code related to blob and update PR mapping


 */
public without sharing class PartnerReferralHelper {

   public static Boolean TRIGGER_ALREADY_RAN=false;
    
   // list of Partner Referral inserts that need to be checked for Marketing Call Trackers
   public static Set<Id> v_idsToProcessMCTSet = new Set<Id>();
   public static Set<Id> idsProcessedMCT = new Set<Id>();
   public static Set<Id> v_popWebLeadSet = new Set<Id>();

   // for testing purposes
   public static Boolean SKIP_FUTURE=false;

   public static void checkBeforeActions(PartnerReferral__c[] partRefs, Map<Id,PartnerReferral__c> oldMap) {
      if (TRIGGER_ALREADY_RAN) {
         return;
      }
       
      // if we have the partner id, but not the partner, use this to look up the partner
      Map<String,PartnerReferral__c[]> checkForPartnerMap = new Map<String,PartnerReferral__c[]>();
      // check for city and state if only zip code entered   
      Map<String,PartnerReferral__c[]> checkForZipMap = new Map<String,PartnerReferral__c[]>();
   
      for (PartnerReferral__c partRef : partRefs) {
         PartnerReferral__c oldPartRef = (oldMap != null ? oldMap.get(partRef.Id) : null);
          
         // clear it out in on entry
         partRef.ProcessReferralSystem__c = null;
         if (partRef.ProcessReferral__c) {
            partRef.ProcessReferralSystem__c = Datetime.now();
            partRef.ProcessReferral__c=false;
         }
 
         // if this is an insert
         if (oldPartRef == null) {
            checkInsertBeforeActions(partRef, checkForPartnerMap, checkForZipMap);
         } else {
            // allow to force the manual creation of a Marketing Call Tracking record.
            if (partRef.ProcessMCT__c) {
               v_idsToProcessMCTSet.add(partRef.Id);
               partRef.ProcessMCT__c = false;
            }
            // we won't do this on a brand new record - only on updates.
            if (partRef.ForceRTPQ__c) {
               partRef.ForceRTPQ__c = false;
               v_popWebLeadSet.add(partRef.Id);
            }
         } // if (oldPartRef == null

      } // for (PartnerReferral__c
      
      //Populate Created Timeframe
      updateTimeframe(partRefs);

      if (!checkForPartnerMap.isEmpty()) {
         findPartnerRecords(checkForPartnerMap);
      }
      if (!checkForZipMap.isEmpty()) {
         checkReferralsForZips(checkForZipMap);
      }
      RJMethods.checkOACFieldChange(Trigger.new,Trigger.oldMap);

    } // checkBeforeActions
   
   //To populate Created by Timeframe field on Partner Referral creation
   public static void updateTimeframe(List<PartnerReferral__c> partRef) {
      for(PartnerReferral__c newRec:partRef){
         if(newRec.Created_by_Timeframe__c == null){
            newRec.Created_by_Timeframe__c = newRec.CreatedDate!=null ? newRec.CreatedDate.format(Label.CallTime_format,Label.CallTime_TimeZone):DateTime.now().format(Label.CallTime_format,Label.CallTime_TimeZone);
         }
      } 
   }

   public static Boolean WEB_LEAD_RAN=false;
   
   public static void checkAfterActions(PartnerReferral__c[] partRefs, Map<Id,PartnerReferral__c> oldMap) {
      if (TRIGGER_ALREADY_RAN) {
         return;
      }
      TRIGGER_ALREADY_RAN = true;
      Boolean submitAsEmail = false;
       
      Set<Id> popWebLeadSet = new Set<Id>();
      popWebLeadSet.addAll(v_popWebLeadSet);
      v_popWebLeadSet.clear();
       
      // we want to use local variables instead of global here, so we can clear out the global ones.
      Set<Id> idsToProcessSet = new Set<Id>();
      idsToProcessSet.addAll(v_idsToProcessSet);
      v_idsToProcessSet.clear();
       
    /*  Set<Id> idsToProcessMCTSet = new Set<Id>();
      idsToProcessMCTSet.addAll(v_idsToProcessMCTSet);
      v_idsToProcessMCTSet.clear(); */
      
      // if this is an ecom partner referral that was created, check if there's already an ecom record for it.
      Id[] checkForEcomRecs = new Id[]{};
      String[] mktgIds = new String[]{};
       
      for (PartnerReferral__c partRef : partRefs) {
         PartnerReferral__c oldPartRef = (oldMap != null ? oldMap.get(partRef.Id) : null);
         if (!idsProcessed.contains(partRef.Id)) {
            System.debug('checkAfterActions ProcessReferral__c='+partRef.ProcessReferral__c);
            if (partRef.ProcessReferralSystem__c != null) {
               submitAsEmail = (submitAsEmail || partRef.SubmitAsEmail__c);
               System.debug('checkAfterActions adding to v_idsToProcessSet');
               idsToProcessSet.add(partRef.Id);
            } 

         /*   if (oldPartRef == null && String.isNotBlank(partRef.Description__c)) {
               idsToProcessMCTSet.add(partRef.Id);
            }
         */
          
            // on insert of an ecom partner referral, see if there are already ecom records out there.
            if (oldPartRef == null && String.isNotBlank(partRef.Source__c)) {
               LeadLoaderConfig__c llc = TrackRecordEntry.getConfig(partRef.Source__c,null,(oldPartRef == null));
               //if (llc != null && llc.IsEcom__c && partRef.MktgId__c != null && partRef.Master_Partner_Referral__c == null) {
               if (llc != null && llc.IsEcom__c && partRef.MktgId__c != null) {
                  // check if there's already an ecom record out there.
                  checkForEcomRecs.add(partRef.Id);
                  mktgIds.add(partRef.MktgId__c);
               }
            }
         } // if (!idsProcessed.contains
         
         // only do this on the first population of a weblead
         if (oldPartRef != null && String.isNotBlank(partRef.Original_Owner__c) && String.isBlank(oldPartRef.Original_Owner__c)
                 && partRef.RTPQDateTime__c == null     
                 && partRef.Source__c == TrackRecordEntry.WEBLEAD) {
            System.debug('checkAfterActions add to popWebLeadSet');
            popWebLeadSet.add(partRef.Id);
         }

      } // for (PartnerReferral__c partRef
       
      System.debug('checkAfterActions v_idsToProcessSet='+v_idsToProcessSet.size());
      if (!idsToProcessSet.isEmpty()) {
         idsProcessed.addAll(v_idsToProcessSet);
         if (!submitAsEmail) {
            // double check if it's running as a guest user - all guest user submissions should be as email.
            UserHelper.SKIP_CACHE = true;
            submitAsEmail = UserHelper.isRunningUserGuest();
         }
         System.debug('checkAfterActions submitAsEmail='+submitAsEmail);
         if (submitAsEmail) {
            // send an email with the ids in it.
            sendPartReferralEmail(idsToProcessSet);
         } else {
            processReferrals(idsToProcessSet);            
         }
      } // if (!v_idsToProcessSet.isEmpty
        
/*      if (!idsToProcessMCTSet.isEmpty()) {
         idsProcessedMCT.addAll(idsToProcessMCTSet);  
         MarketTrackingMethods.createTrackingfromHub(idsToProcessMCTSet);
      } */
          
      System.debug('checkAfterActions WEB_LEAD_RAN='+WEB_LEAD_RAN+' popWebLeadSet='+popWebLeadSet.size());
      if (!WEB_LEAD_RAN && !popWebLeadSet.isEmpty()) {
         // use a separate set so we can clear out the main set for recursion purposes.
         if (SKIP_FUTURE || System.isFuture() || System.isBatch()) {
            popUpWebleadNow(popWebLeadSet);
         } else {
            popUpWebleadFuture(popWebLeadSet);
         }

         // so we don't call this again
         WEB_LEAD_RAN = true;
      } // if (!WEB_LEAD_RAN &&

      if (!checkForEcomRecs.isEmpty()) {
         EcomMethods.checkFromPartRef(checkForEcomRecs, mktgIds);
      }
   } // checkAfterActions

   @future
   public static void popUpWebleadFuture(Set<Id> p_popWebLeadSet) {
      popUpWebleadNow(p_popWebLeadSet);
   } // popUpWebleadFuture

   public static void popUpWebleadNow(Set<Id> p_popWebLeadSet) {
      Referral__c[] refs = [Select Id
                                  ,Account__c
                                  ,PartnerReferral__c
                                  ,PartnerReferral__r.Id
                                  ,PartnerReferral__r.FirstName__c
                                  ,PartnerReferral__r.LastName__c
                                  ,PartnerReferral__r.Company__c
                                  ,PartnerReferral__r.Phone__c
                                  ,PartnerReferral__r.RTPQDateTime__c
                                  ,SourceContact__c
                                  ,SourceLead__c
                                  ,SourceLead__r.Id
                                  ,SourceLead__r.IsConverted
                                  ,User__c
                              From Referral__c
                             Where PartnerReferral__c in :p_popWebLeadSet];
                             
      PartnerReferral__c[] updatePartRefs = new PartnerReferral__c[]{};
      for (Referral__c ref : refs) {
         String name=ref.PartnerReferral__r.FirstName__c+' '+ref.PartnerReferral__r.LastName__c+'-'+ref.PartnerReferral__r.Company__c;
         // only pop from the contact or lead
         Id objId = ref.SourceContact__c != null ? ref.SourceContact__c
                          : (ref.SourceLead__c != null && ref.SourceLead__r.IsConverted==false ? ref.SourceLead__c : null);
         if (objId != null) {
            DialSourceActionHelper.addPopToUser(objId, name, ref.PartnerReferral__r.Phone__c, ref.User__c);
            updatePartRefs.add(new PartnerReferral__c(Id=ref.PartnerReferral__r.Id, RTPQDateTime__c=Datetime.now()));
         }
      } // for (Referral__c ref
      
      DialSourceActionHelper.checkPopToUser();
      DmlHelper.performDML2(updatePartRefs, DmlHelper.DML_UPDATE, 'PartnerReferralHelper', 'popUpWebleadNow', 'Update RTPQ Datetime', true);
   } // popUpWebleadNow
   
   public static void findPartnerRecords(Map<String,PartnerReferral__c[]> checkForPartnerMap) {
      Partner__c[] partners = [Select Id, Name, Account__c, PartnerId__c from Partner__c where ParentPartner__c = null and PartnerId__c in :checkForPartnerMap.keySet()];
      for (Partner__c partner : partners) {
         PartnerReferral__c[] partRefs = checkForPartnerMap.get(partner.PartnerId__c);
         if (partRefs != null) {
            for (PartnerReferral__c partRef : partRefs) {
               partRef.Partner__c = partner.Id;
               partRef.PartnerAcct__c = partner.Account__c; 
            } // for (PartnerReferral__c partRef
         } // if (partRefs != null
      } // for (Partner__c partner : partners
   } // findPartnerRecords

   // things to check before inserting a record
   public static void checkInsertBeforeActions(PartnerReferral__c partRef, Map<String,PartnerReferral__c[]> checkForPartnerMap, Map<String,PartnerReferral__c[]> checkForZipMap) {
      if (String.isBlank(partRef.AdditionalReferringName__c) 
             && (String.isNotBlank(partRef.AdditionalReferringFirstName__c) || String.IsNotBlank(partRef.AdditionalReferringLastName__c))) {
         partRef.AdditionalReferringName__c = String.isNotBlank(partRef.AdditionalReferringFirstName__c) ? partRef.AdditionalReferringFirstName__c+' ' : '';
         partRef.AdditionalReferringName__c += String.isNotBlank(partRef.AdditionalReferringLastName__c) ? partRef.AdditionalReferringLastName__c : '';
      } // AdditionalReferringLastName__c
      
      if (String.isBlank(partRef.EmpFirstName__c)) {
         partRef.EmpFirstName__c = partRef.AdditionalReferringFirstName__c;
      }
      if (String.isBlank(partRef.EmpLastName__c)) {
         partRef.EmpLastName__c = partRef.AdditionalReferringLastName__c;
      }
      
      if (String.isNotBlank(partRef.PartnerId__c) && partRef.Partner__c == null) {
         PartnerReferral__c[] partnerList = checkForPartnerMap.get(partRef.PartnerId__c);
         if (partnerList == null) {
            partnerList = new PartnerReferral__c[]{};
            checkForPartnerMap.put(partRef.PartnerId__c, partnerList);
         }
         partnerList.add(partRef);
      } // if (String.isNotBlank(partRef.PartnerId__c
      
      if (String.isNotBlank(partRef.ZipPostalCode__c) && String.isBlank(partRef.State__c) && String.isBlank(partRef.City__c)) {
         String zipCode = partRef.ZipPostalCode__c.left(5); // make sure only the 5 digit zip code 
         PartnerReferral__c[] refList = checkForZipMap.get(zipCode);
         if (refList == null) {
            refList = new PartnerReferral__c[]{};
            checkForZipMap.put(zipCode,refList);
         }
         refList.add(partRef);
      }
   } // checkInsertBeforeActions
   
   // set the city and state on referrals that have a zip code only
   public static void checkReferralsForZips(Map<String,PartnerReferral__c[]> checkForZipMap) {
      Map<String,Zip_Code_Information__c> zciMap = ZipCodeInformation.getZciMap(checkForZipMap.keySet());
      for (Zip_Code_Information__c zci : zciMap.values()) {
         PartnerReferral__c[] refList = checkForZipMap.get(zci.Name);
         if (refList != null) {
            for (PartnerReferral__c partRef : refList) {
               partRef.City__c = zci.City__c;
               partRef.State__c = zci.State__c;
            }
         } // if (refList != null
      } // for (Zip_Code_Information__c zci
   } // checkReferralsForZips
   
   public static final String REF_EMAIL_MESSAGE='Partner Referral Submitted:';
   public static final String ID_SEPARATOR=';';
   // used for testing purposes
   public static Boolean emailSent=false;
   
   public static void sendPartReferralEmail(Set<Id> refIdsToProcessSet) {
      emailSent = false;
      System.debug('sendPartReferralEmail Label.BankReferralEmail='+Label.BankReferralEmail);
      if (String.isNotBlank(Label.BankReferralEmail)) {
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         String[] toAddresses = new String[] {Label.BankReferralEmail};
         mail.setToAddresses(toAddresses);
         mail.setSaveAsActivity(false);
      
         mail.setSubject('Partner Referral Submission');

         String body = '';
         for (Id refId : refIdsToProcessSet) {
            if (String.isBlank(body)) {
               body = REF_EMAIL_MESSAGE;
            } else {
               body += ID_SEPARATOR;
            }
            body += refId;
         } // for (Id refId
         System.debug('sendPartReferralEmail body='+body);
         mail.setPlainTextBody (body);
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
         emailSent=true;
      } // if (String.isNotBlank(Label
      System.debug('sendPartReferralEmail emailSent='+emailSent);
   } // sendPartReferralEmail
   
   public static Set<Id> v_idsToProcessSet = new Set<Id>();
   
   public static Set<Id> idsProcessed = new Set<Id>();
      
   public static String[] QUERY_EXTRA_FIELDS = new String[]{
                              'PartnerBranch__r.Account__c'
                             ,'PartnerBranch__r.Account__r.Id'
                             ,'PartnerBranch__r.Account__r.Name'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Id'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Name'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Account__c'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Bank_Centric_Rep__c'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Bank_Centric_Rep_401k__c'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Bank_Branch_Number__c'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.OwnerId'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.PartnerId__c'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Phone_Bank__c'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Referral_Source_Business_Type__c'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Referral_Type__c'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Zip_Postal_Code__c'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Parent_Referral_Account__c'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Parent_Referral_Account__r.Id'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Parent_Referral_Account__r.Account__c'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Parent_Referral_Account__r.Referral_Source_Business_Type__c'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Parent_Referral_Account__r.Referral_Type__c'
                             ,'PartnerBranch__r.Account__r.Mirror_Referral_Account__r.Parent_Referral_Account__r.Primary_Zip_Segment__c'
                             ,'Partner__r.Account__c'
                             ,'Partner__r.Account__r.Id'
                             ,'Partner__r.Account__r.Name'
                             ,'Partner__r.Account__r.Mirror_Referral_Account__r.Id'
                             ,'Partner__r.Account__r.Mirror_Referral_Account__r.Name'
                             ,'Partner__r.Account__r.Mirror_Referral_Account__r.Account__c'
                             ,'Partner__r.Account__r.Mirror_Referral_Account__r.Bank_Centric_Rep__c'
                             ,'Partner__r.Account__r.Mirror_Referral_Account__r.Bank_Centric_Rep_401k__c'
                             ,'Partner__r.Account__r.Mirror_Referral_Account__r.Bank_Branch_Number__c'
                             ,'Partner__r.Account__r.Mirror_Referral_Account__r.OwnerId'
                             ,'Partner__r.Account__r.Mirror_Referral_Account__r.PartnerId__c'
                             ,'Partner__r.Account__r.Mirror_Referral_Account__r.Phone_Bank__c'
                             ,'Partner__r.Account__r.Mirror_Referral_Account__r.Referral_Source_Business_Type__c'
                             ,'Partner__r.Account__r.Mirror_Referral_Account__r.Referral_Type__c'
                             ,'Partner__r.Account__r.Mirror_Referral_Account__r.Zip_Postal_Code__c'
                             ,'Partner__r.Account__r.Mirror_Referral_Account__r.Primary_Zip_Segment__c'
                             ,'PartnerAcct__r.Id'
                             ,'PartnerAcct__r.Name'
                             ,'PartnerAcct__r.Mirror_Referral_Account__r.Id'
                             ,'PartnerAcct__r.Mirror_Referral_Account__r.Name'
                             ,'PartnerAcct__r.Mirror_Referral_Account__r.Account__c'
                             ,'PartnerAcct__r.Mirror_Referral_Account__r.Bank_Centric_Rep__c'
                             ,'PartnerAcct__r.Mirror_Referral_Account__r.Bank_Centric_Rep_401k__c'
                             ,'PartnerAcct__r.Mirror_Referral_Account__r.Bank_Branch_Number__c'
                             ,'PartnerAcct__r.Mirror_Referral_Account__r.OwnerId'
                             ,'PartnerAcct__r.Mirror_Referral_Account__r.PartnerId__c'
                             ,'PartnerAcct__r.Mirror_Referral_Account__r.Phone_Bank__c'
                             ,'PartnerAcct__r.Mirror_Referral_Account__r.Referral_Source_Business_Type__c'
                             ,'PartnerAcct__r.Mirror_Referral_Account__r.Referral_Type__c'
                             ,'PartnerAcct__r.Mirror_Referral_Account__r.Zip_Postal_Code__c'
                             ,'PartnerAcct__r.Mirror_Referral_Account__r.Primary_Zip_Segment__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Id'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Name'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Account__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Bank_Centric_Rep__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Bank_Centric_Rep_401k__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Bank_Branch_Number__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.OwnerId'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.PartnerId__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Phone_Bank__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Referral_Source_Business_Type__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Referral_Type__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Zip_Postal_Code__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Parent_Referral_Account__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Parent_Referral_Account__r.Id'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Parent_Referral_Account__r.Account__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Parent_Referral_Account__r.Referral_Source_Business_Type__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Parent_Referral_Account__r.Referral_Type__c'
                             ,'PartnerBranchAcct__r.Mirror_Referral_Account__r.Parent_Referral_Account__r.Primary_Zip_Segment__c'
                             ,'PartnerContact__r.FirstName'
                             ,'PartnerContact__r.LastName'
                             ,'PartnerContact__r.LeadSourceDefault__c'
                             ,'PartnerContact__r.Mirror_Ref_Ctct__r.Id'
                             ,'PartnerContact__r.Mirror_Ref_Ctct__r.OwnerID'
                             ,'PartnerContact__r.Mirror_Ref_Ctct__r.Employee_Number__c'
                             ,'PartnerContact__r.Mirror_Ref_Ctct__r.Email__c'
                             ,'PartnerContact__r.Mirror_Ref_Ctct__r.End_Date__c'
                             ,'PartnerContact__r.Mirror_Ref_Ctct__r.LeadSourceDefault__c'
                             ,'PartnerContact__r.Mirror_Ref_Ctct__r.PrimaryReferralType__c'
                             ,'PartnerContact__r.Mirror_Ref_Ctct__r.ReferralPartnerName__c'
                             ,'PartnerContact__r.Mirror_Ref_Ctct__r.Referral_Account__c'
                             ,'PartnerContact__r.Mirror_Ref_Ctct__r.Contact__c'
                             ,'PartnerContact__r.Mirror_Ref_Ctct__r.Contact__r.AccountId'
                        };
   
   // select any unprocessed bank referrals
   public static PartnerReferral__c[] getReferralsToProcess(Set<Id> idsToProcessSet) {
      if (idsToProcessSet == null) {
         idsToProcessSet = new Set<Id>();
      }
      String query = ObjectHelper.getSOQLQuery('PartnerReferral__c', QUERY_EXTRA_FIELDS, true, false);
      query += ' where Id in :idsToProcessSet';
      PartnerReferral__c[] referrals = Database.query(query);
      System.debug('getReferralsToProcess referrals='+referrals.size());
      System.debug('getReferralsToProcess referrals[0]='+(referrals.size() > 0 ? referrals[0] : null));
      return referrals;
   } // getReferralsToProcess
   
   public static void processReferrals(Set<Id> idsToProcessSet) {
      PartnerReferral__c[] referrals = getReferralsToProcess(idsToProcessSet);
      v_idsToProcessSet.clear();
      if (!referrals.isEmpty()) {
         PartnerWrapper[] wrappers = new PartnerWrapper[]{}; 
         for (PartnerReferral__c partRef : referrals) {
            wrappers.add(createWrapper(partRef));
         }
         if (WebBankLeadHelper.processReferrals(wrappers)) {
            // link the referral to the bank referral
            for (PartnerWrapper partnerWrap : wrappers) {
               if (partnerWrap.referralPay != null) {
                  partnerWrap.partRef.Referral__c = partnerWrap.referralPay.Id;
               } else if (partnerWrap.referral401 != null) {
                  partnerWrap.partRef.Referral__c = partnerWrap.referral401.Id;
               }
            } // for (PartnerWrapper bankLeadWrap
            update referrals;
         }
      } // if (!referrals
   } // processReferral
   
   public static PartnerWrapper createWrapper(PartnerReferral__c partRef) {
      PartnerWrapper partnerWrapper = new PartnerWrapper(partRef);
      //partnerWrapper.partnerHeadquarters = String.isNotBlank(partRef.ReferralType__c) ? partRef.ReferralType__c : WebBankLeadHelper.TIER_2;
      
//      partnerWrapper.partnerHeadquarters = (partRef.Partner__r != null && partRef.Partner__r.Account__r != null ? partRef.Partner__r.Account__r.Mirror_Referral_Account__r : null);
//      partnerWrapper.partnerBranch = (partRef.PartnerBranch__r != null && partRef.PartnerBranch__r.Account__r != null ? partRef.PartnerBranch__r.Account__r.Mirror_Referral_Account__r : null);

      if (partnerWrapper.partnerBranch != null && String.isBlank(partRef.BranchName__c)) {
         partRef.BranchZip__c = partnerWrapper.partnerBranch.Zip_Postal_Code__c;
         partRef.BranchName__c = partnerWrapper.partnerBranch.Name;
         partRef.BranchNumber__c = partnerWrapper.partnerBranch.Bank_Branch_Number__c;
      }

      if (partnerWrapper.partnerHeadquarters != null && String.isBlank(partRef.PartnerName__c)) {
         partRef.PartnerName__c = partnerWrapper.partnerHeadquarters.Name;
      }

      return partnerWrapper;
   } // createWrapper
   
} // class PartnerReferralHelper