/* 
 * Class used to save the original lead data
 *
 * History
 * -------
   04/26/2017 Dan Carmen       Created
   07/26/2017 Dan Carmen       Added ability to bypass Data Governance
   12/18/2017 Cindy Freeman    Added consent to text fields to partner referral
   12/28/2017 Dan Carmen       Get the employee count from the contact to pass in with the account.
   01/17/2018 Jacob Hinds      Added emp count criteria to campaign check
   01/25/2018 Dan Carmen       Changes to use the Weblead checkbox
   04/18/2018 Dan Carmen       Add SKIP_TRIGGER
   05/09/2018 Dan Carmen       Fix for setting the employee count on the account when the lead comes in as a contact
   05/14/2018 Dan Carmen       Add consent to text logic for webleads
   06/22/2018 Dan Carmen       Add extra logging
   06/25/2018 Cindy Freeman    Add code for new Lead Routing field to handle PEO Centric campaign assignments
   07/27/2018 Dan Carmen       Change for 
   08/21/2018 Dan Carmen       Added in Marketo_Lead_Rating__c to copy to Partner Referral
   09/05/2018 Dan Carmen       Added in additional logging
   09/20/2018 Dan Carmen       Add additional logging
   10/31/2018 Dan Carmen       Log the Lead/Contact stage on the partner referral
   11/19/2018 Dan Carmen       Comment out Prospect Ownership
   07/02/2019 Matt Fritschi    CheckEmployeeCount now also checks for the Franchise Account Code and Vendor ID.
   07/29/2019 Carrie Marciano  Referral Management (Amplifinity) set owner of AMP lead to Advocate Account Owner, populate AMP related fields on Referral, 
                               link Amplifinity referral to PAYX referral records.
   12/23/2019 Dan Carmen       For Amplifinity, only check workable rules if the API user. 
   03/11/2020 Dan Carmen       Remove calls back to the Oasis SF Instance
   05/19/2020 Cindy Freeman    add to ProcessNotes transactionId and okayToProcess
   06/03/2020 Matthew Fritschi Checks in the Referral has an Amp Referral, and populates the Referring User.
   06/17/2020 Dan Carmen       Remove Oasis account code.
   10/15/2020 Dan Carmen       Add in MktgId__c
   10/19/2020 Brandon Vidro    Change to PRN chatter and added check for Partner Referrals w/ Source of Chat - APR0108929
   01/05/2021 Brandon Vidro    Added checks for ownership of Amplifinity records
   03/12/2021 Brandon Vidro    Added check in handleCampaigns for Drift Campaign - set Partner Referral Source to 'Chat' - APR0114436
   03/23/2021 Brandon Vidro    Set owner for net new Drift Leads to 'Drift Chat' holding queue - APR0114436
   06/14/2021 Pujitha Madamanchi APR0112504: Populate PR Source based on Campaign Source Type instead of name. 
   07/02/2021 Pujitha Madamanchi  Drift Lead routing to follow regular process of Send to Virtual
   10/27/2021 Pujitha Madamanchi APR0109624: Populate Strategic account on Lead and Account from Campaign.
   01/10/2021 Pujitha Madamanchi APR0129320: Lead/Contact State/City Assignment based on zipcode
   08/09/2022 Pujitha Madamanchi APR0135240: Routing by EE segment for WEBLEAD.
   11/08/2022 Pujitha Madamanchi APR0143246: Fix for Routing by EE segment for WEBLEAD for null value
   03/23/2022 Pujitha Madamanchi APR0148464: Parse XeroId from Blob
   04/03/2022 Pujitha Madamanchi : APR0151002  Fix for XeroId text 
   06/19/2023 Pujitha Madamanchi : Added logging for No of Employees 
   08/01/2023 Dan Carmen         Fix logging
   08/08/2023 Lalan Kumar        :APR0143207:added null check as if(zipWrap != null) multiple lines
   01/19/2024 Pujitha Madamanchi : Remove code related to blob and update PR mapping

 */
public with sharing class TrackRecordEntry implements TriggerInterface {
   
   public static Boolean SKIP_TRIGGER=false;
   // do we allow the code to perform a duplicate check on inserted records?
   public static Boolean ALLOW_DUPE_CHECK = (Label.TrackRecord_AllowDupeCheck == 'Y');
   
   public static String REF_MGMT='Paychex Referral Network';
   
   // if there's only one record, do we want the code to be able to process it inline (instead of as a queueable job)?
   public static Boolean ALLOW_SKIP_QUEUEABLE = (Label.TrackRecord_AllowSkipQueueable == 'Y');
   
   public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {
      System.debug('TrackRecordEntry.checkAllBeforeTrigger SKIP_TRIGGER='+SKIP_TRIGGER);
      if (SKIP_TRIGGER) {
         return;
      }
      System.debug('TrackRecordEntry checkAllBeforeTrigger recs='+recs.size());
      if (!recs.isEmpty()) {
         if (recs[0].getSObjectType() == Lead.sObjectType) {
            checkLeadsBefore((Lead[])recs, (Map<Id,Lead>)oldMap);
         } else if (recs[0].getSObjectType() == Contact.sObjectType) {
            checkContactsBefore((Contact[])recs, (Map<Id,Contact>)oldMap);
         }

      } // if (!recs.isEmpty
      System.debug('TrackRecordEntry checkAllBeforeTrigger partRefMap='+partRefMap.size());
   } // checkAllBeforeTrigger

   public static ErrorLog__c v_runLog = null;
   public String runLog = '';
   
   public static Map<String,String> prevStageMap = new Map<String,String>(); 
    
   public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {
      runLog = 'SKIP_TRIGGER='+SKIP_TRIGGER;
      System.debug('TrackRecordEntry.checkAllAfterTrigger SKIP_TRIGGER='+SKIP_TRIGGER);
      if (SKIP_TRIGGER) {
         return;
      }
      System.debug('TrackRecordEntry.checkAllAfterTrigger recs='+recs.size()+' oldMap='+(oldMap == null ? 'null' : String.valueOf(oldMap.size()))+' partRefMap='+partRefMap.size());
      runLog += '; recs='+recs.size()+' partRefMap='+partRefMap.size();
      if (!recs.isEmpty() && !partRefMap.isEmpty()) {
         if (recs[0].getSObjectType() == Lead.sObjectType) {
            runLog += '; checkLeadsAfter';
            checkLeadsAfter((Lead[])recs, (Map<Id,Lead>)oldMap);
         } else if (recs[0].getSObjectType() == Contact.sObjectType) {
            runLog += checkContactsAfter((Contact[])recs, (Map<Id,Contact>)oldMap);
         }
      }
      ErrorLog.addToDescription(v_runLog, runLog);
      ErrorLog.saveErrorLog(v_runLog);
      System.debug('TrackRecordEntry.checkAllAfterTrigger ALLOW_DUPE_CHECK='+ALLOW_DUPE_CHECK+' ALLOW_SKIP_QUEUEABLE='+ALLOW_SKIP_QUEUEABLE+' dupeObjectList='+dupeObjectList.size()+' dupeCheckMap='+dupeCheckMap.size());
      if (ALLOW_DUPE_CHECK && !dupeObjectList.isEmpty() && !dupeCheckMap.isEmpty()) {
         if (ALLOW_SKIP_QUEUEABLE && dupeObjectList.size() == 1) {
            System.debug('TrackRecordEntry.checkAllAfterTrigger create DuplicateCheckQueueable');
            DuplicateCheckQueueable dcq = new DuplicateCheckQueueable(dupeCheckMap, dupeObjectList);
            dcq.processRecs();
         } else {
            DuplicateCheckQueueable.launchQueueable(dupeCheckMap,dupeObjectList);
         }
      } // if (!recs.isEmpty
      partRefMap.clear();
      System.debug('TrackRecordEntry checkAllAfterTrigger partRefMap='+partRefMap.size());
   } // checkAllAfterTrigger

   public void checkBeforeTrigger(SObject newRec, SObject oldRec) {}
   
   public void processBeforeTriggerActions() {}
   
   public void checkAfterTrigger(SObject newRec, SObject oldRec) {}
   
   public void processAfterTriggerActions() {}

   // store the partner referrals by the transaction id from the lead or contact
   public static Map<String, PartnerReferral__c> partRefMap = new Map<String, PartnerReferral__c>();

   // these are the records we need to check for duplicates
   public static Map<String, PartnerReferral__c> dupeCheckMap = new Map<String, PartnerReferral__c>();
   public static SObject[] dupeObjectList = new SObject[]{};
   
   /*  TODO
    
    
       For a new lead, and the owned by is blank, 
             check the profile of the user creating the lead or lead source to see if we default an owned by value.
       
       Based on the owned by, do we log the original lead data.
   
      If update, look for existing PartnerReferral__c's
      Option for pulling ownership off of the lead to set on referral (after trigger)
   
      Profile based default of owned by field
      Map Lead source to owned by
          Map on Lead and Opportunity
   */
   
   public static void checkLeadsBefore(Lead[] leads, Map<Id,Lead> oldMap) {
      // loop through the leads - look for records with the AMP referral lookup populated, grab AMP advocate information if AMP referral is present
      List<Id> ampRefList = new List<Id>();
      Id[] campIds = new Id[]{};
      Lead[] strategicRecs = new Lead[]{};
      for (Lead ld : Leads){
         Lead oldLd = (oldMap != null ? oldMap.get(ld.Id) : null);
         if (ld.amp_dev__Referral__c != null 
               && (oldLd == null || (ld.amp_dev__Referral__c != oldLd.amp_dev__Referral__c)) ){
             // only need to process if lookup changes
              ampRefList.add(ld.amp_dev__Referral__c);
              // this is if the lead isn't created by Amplifinity (adding an existing lead to Amp)
              if (String.isBlank(ld.OwnedBy__c)) {
                 ld.OwnedBy__c = 'ReferralManagement'; 
                 //ld.Referral_Management__c = REF_MGMT;
              }
              
              if (oldMap == null) {
                 ld.CreatedByProcess__c = 'Amplifinity';
                 System.debug('checkLeadsBefore after AMP APIUser check ld.OwnedBy__c='+ld.OwnedBy__c); 
              }
          }
         //APR0109624 
         if(ld.LatestCampaign__c!= null){
            campIds.add(ld.LatestCampaign__c);
            strategicRecs.add(ld);
         }
      } // for(Lead ld : Leads
       
      Map<Id,amp_dev__Amp_Referral__c> leadAMPRefMap = getAmpReferralMap(ampRefList);
      system.debug('checkLeadsBefore leadAMPRefMap='+leadAMPRefMap.size());
      checkRecordsBefore(leads, oldMap, ObjectHelper.OBJECT_LEAD, null, leadAMPRefMap);
   //   checkFranchiseCodes(null);
      setStrategicAcct(strategicRecs, campIds, null, null);
      updateCityState(leads, oldMap, ObjectHelper.OBJECT_LEAD);
   } // checkLeads
   
   //APR0109624 Populate strategic account on Lead & Account
   public static void setStrategicAcct(Lead[] leads, Id[] campIds,  Map<Id,Id> accIdtoCampIdMap, Map<Id,Account> updateAcctMap){
      Map<Id,Campaign> campaignMap = new Map<Id,Campaign>();
      //check is campaignIds exist and fetch campaigns else, return
       if(!campIds.isEmpty()){
        campaignMap = getCampaignMap(campIds);
         system.debug('checkLeadsBefore campaignMap='+campaignMap.size());
      } 
       else{
           return;
       }//if(campIds!= null
    
      //for Leads, populate Strategic Account on Lead
      if(leads!= null && !leads.isEmpty()){
      //For Strategic Partners 
         for(Lead rec: leads){
            if(rec.LatestCampaign__c != null){
               Campaign camp = campaignMap.get(rec.LatestCampaign__c);
               if(camp!= null && camp.Strategic_Account_Partner__c!= null){
                  rec.Referral_National_Account__c = camp.Strategic_Account_Partner__c;
               }
            } //if(rec.LatestCampaign__c!= null 
         } 
      } // if(leads!= null 
      System.debug('accIdtoCampIdMap::'+(accIdtoCampIdMap != null && !accIdtoCampIdMap.isEmpty()));
      if(accIdtoCampIdMap!=null && !accIdtoCampIdMap.isEmpty()){
         List<Account> accts = getAccounts(accIdtoCampIdMap.keyset());
          System.debug('accIdtoCampIdMap::'+accIdtoCampIdMap);
          System.debug('accts::'+accts.size());
            // APR0109624: For Contact, populate Strategic Account on Accounts
            for(Account acc : accts){
               if(!campaignMap.isEmpty()){
                  Campaign camp = campaignMap.get(accIdtoCampIdMap.get(acc.Id));
                  if(camp!= null){
                     Account updateAcct = (updateAcctMap.containsKey(acc.Id) ? updateAcctMap.get(acc.Id) : new Account(Id=acc.Id));
                     if(updateAcct.Referral_National_Account__c!= camp.Strategic_Account_Partner__c){
                        updateAcct.Referral_National_Account__c = camp.Strategic_Account_Partner__c;
                           updateAcctMap.put(updateAcct.Id, updateAcct);
                     }      
                  }//if(camp!= null
            }//for Account            
         }//if(!campaignMap.isEmpty()
      }//if(!accIdtoCampIdMap.isEmpty()                                             
    }//setStrategicAcct
   
   public static String CAMP_CACHE_KEY='TrackRecordEntryCampaignCache';
    
   public static Map<Id, Campaign> getCampaignMap(Id[] campaignIds){
      Map<Id,Campaign> retMap = new Map<Id,Campaign>();
      if (!campaignIds.isEmpty()) {
         Map<Id,Campaign> campMap = (Map<Id,Campaign>)CacheManager.getOrg(CAMP_CACHE_KEY);
         if (campMap == null) {
            campMap = new Map<Id,Campaign>([Select Id, Strategic_Account_Partner__c 
                                             from Campaign where Strategic_Account_Partner__c != null and IsActive=true]);
            CacheManager.putOrg(CAMP_CACHE_KEY,campMap);
         }
         for (Id campId : campaignIds) {
            if (campMap.containsKey(campId)) {
               retMap.put(campId,campMap.get(campId));
            }
         } // for (Id campId : campaignIds
      } // if (!campaignIds.isEmpty()
      
      System.debug('getCampaignMap retMap='+retMap.size());
       System.debug('getCampaignMap campaignIds='+campaignIds.size());
      ErrorLog.addToDescription(v_runLog,'getCampaignMap campaignIds='+campaignIds.size()+' retMap='+retMap.size());
      return retMap;
   } // getCampaignMap
   
   public static List<Account> getAccounts(Set<Id> acctIds){
      List<Account> accList = (acctIds.isEmpty() ? new List<Account>() : new List<Account>([
                                             select Id, Name, OwnerId
                                             ,Employees__c
                                             ,NumberOfEmployees
                                             ,Owner_Zip_Code__c
                                             ,ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, Referral_National_Account__c, Current_Prior_Method__c
                                                from Account
                                                where Id IN: acctIds]));
      return accList;
   }

   public static Map<Id,amp_dev__Amp_Referral__c> getAmpReferralMap(Id[] ampRefList) {
      Map<Id,amp_dev__Amp_Referral__c> aMPRefMap = (ampRefList.isEmpty() ?  new Map<Id,amp_dev__Amp_Referral__c>()
                                                            : new Map<Id,amp_dev__Amp_Referral__c>([
                                                                               select Id 
                                                                                     ,amp_dev__Lead__c
                                                                                     ,amp_dev__Status__c
                                                                                     ,amp_dev__Advocate__c
                                                                                     ,amp_dev__Advocate__r.Id
                                                                                     ,amp_dev__Advocate__r.amp_dev__Status__c 
                                                                                     ,amp_dev__Advocate__r.amp_dev__Enrollment_Date__c
                                                                                     ,amp_dev__Advocate__r.amp_dev__Company_Name__c
                                                                                     ,amp_dev__Advocate__r.createdDate
                                                                                     ,amp_dev__Advocate__r.ownerid //need to change this to account owner once A
                                                                                     ,amp_dev__Advocate__r.Account__r.OwnerId
                                                                                     ,amp_dev__Advocate__r.account__c
                                                                                 FROM amp_dev__Amp_Referral__c 
                                                                                WHERE Id in :ampRefList]));
      System.debug('getAmpReferralMap ampRefList='+ampRefList.size()+' aMPRefMap='+aMPRefMap.size());
      ErrorLog.addToDescription(v_runLog,'getAmpReferralMap ampRefList='+ampRefList.size()+' aMPRefMap='+aMPRefMap.size());
      return aMPRefMap;
   } // getAmpReferralMap
   
    public static void updateCityState(SObject[] recs, Map<Id, SObject> oldMap, String objectType) {  
      // if a list is being sent in, check the first record only. We'll assume at this point that if the first record doesn't
      // meet the entry criteria then none of them will. We'll also assume that all of the records in the transaction will be similar 
      // so to save processing we won't proceed unless at least the first record meets the entry criteria
      System.debug('updateCityState objectType='+objectType+' recs='+(recs != null ? recs.size() : -1));
      if (recs == null || recs.isEmpty()) {
         System.debug('updateCityState recs is empty');
         return;
      }
      Map<String,SObject[]> zipToRecMap = new Map<String,SObject[]>();
       
      for (Integer recCnt = 0; recCnt < recs.size(); recCnt++) {
         SObject rec = recs[recCnt];  
         SObject recOld = (oldMap != null && rec.Id != null ? oldMap.get(rec.Id) : null);
        
         //APR0129320: Lead/Contact State/City Assignment based on zipcode
         String postalCode = objectType==ObjectHelper.OBJECT_LEAD? (String)rec.get('PostalCode') : (String)rec.get('MailingPostalCode');
         String state = objectType==ObjectHelper.OBJECT_LEAD? (String)rec.get('State') : (String)rec.get('MailingState');
         String city =  objectType==ObjectHelper.OBJECT_LEAD? (String)rec.get('City') : (String)rec.get('MailingCity');
         String oldPostalCode;
         if(recOld!=null){
            oldPostalCode = objectType==ObjectHelper.OBJECT_LEAD ? (String)recOld.get('PostalCode') : (String)rec.get('MailingPostalCode');
         }

         if (String.isNotBlank(postalCode) && ((recOld == null && String.isBlank(state) && String.isBlank(city)) || (recOld!= null && postalCode!= oldPostalCode))) {
            String zipCode = postalCode.left(5); // make sure only the 5 digit zip code 
            SObject[] recsToProcess = zipToRecMap.containsKey(zipCode) ? zipToRecMap.get(zipCode) : new SObject[]{};
            recsToProcess.add(rec);
            zipToRecMap.put(zipCode, recsToProcess);
         }
      }
         
      Map<String,Zip_Code_Information__c> zciMap = ZipCodeInformation.getZciMap(zipToRecMap.keySet());
   
      for (Zip_Code_Information__c zci : zciMap.values()) {
         SObject[] recList = zipToRecMap.get(zci.Name);
         if(!recList.isEmpty()) {
            for (Integer count = 0; count < recList.size(); count++) {
               SObject updaterec = recList[count];
               if(objectType==ObjectHelper.OBJECT_LEAD){
                   System.debug('lead -- zci.City__c/state__c:::'+zci.City__c+','+zci.State__c);
                  updaterec.put('City',zci.City__c);
                  updaterec.put('State',zci.State__c);
               }
               if(objectType==ObjectHelper.OBJECT_CONTACT){
                  System.debug('con -- zci.City__c/state__c:::'+zci.City__c+','+zci.State__c);
                  updaterec.put('MailingCity',zci.City__c);
                  updaterec.put('MailingState',zci.State__c);
               }
               
               StringHelper.addToProcessNotes(updaterec, 'City & State are updated based on zipcode:'+zci.Name);
            }
         }
      } 
   }

   public static String WEBLEAD=Label.LeadRouting_Weblead;
   
   public static Set<String> recordsProcessedSet = new Set<String>();
   
   public static Boolean isProduction = String.isBlank(Utilities.checkForProduction());

   public static void checkRecordsBefore(SObject[] recs, Map<Id, SObject> oldMap, String objectType, Map<Id, Contact[]> ctctsByAcctIdMap, Map<Id,amp_dev__Amp_Referral__c> leadAMPRefMap ) {  
      // if a list is being sent in, check the first record only. We'll assume at this point that if the first record doesn't
      // meet the entry criteria then none of them will. We'll also assume that all of the records in the transaction will be similar 
      // so to save processing we won't proceed unless at least the first record meets the entry criteria
      System.debug('checkRecordsBefore objectType='+objectType+' recs='+(recs != null ? recs.size() : -1));
      if (recs == null || recs.isEmpty()) {
         System.debug('checkRecordsBefore recs is empty');
         return;
      }
      Long transactionTime = DateTime.now().getTime();
      Boolean runningUserIsMarketo = DoNotSyncCheck.checkCreatedByUser(UserInfo.getUserId());
      Map<String,SObject[]> zipToRecMap = new Map<String,SObject[]>();
       
      for (Integer recCnt = 0; recCnt < recs.size(); recCnt++) {
         SObject rec = recs[recCnt];
         String transactionId = (String)rec.get('TransactionId__c');
         //Boolean webleadChk = (Boolean)rec.get('Weblead__c'); 
         String ownedBy = (String)rec.get('OwnedBy__c'); 
         
         SObject recOld = (oldMap != null && rec.Id != null ? oldMap.get(rec.Id) : null);
        
         Boolean okayToProcess = (String.isBlank(transactionId) || !recordsProcessedSet.contains(transactionId));

         if (runningUserIsMarketo) {
            StringHelper.addToProcessNotes(rec, 'New OwnerId='+(Id)rec.get('OwnerId')+' prev='+(recOld != null ? (String)recOld.get('OwnerId') : 'Insert'));
            System.debug('checkRecordsBefore rec='+rec);
         }

         StringHelper.addToProcessNotes(rec, 'TrackRecordEntry transactionId='+transactionId+' okayToProcess='+okayToProcess+' ownedBy='+ownedBy);
          
         // make sure records are only processed once.
         if (okayToProcess) {
            LeadLoaderConfig__c llc = (String.isNotBlank(ownedBy) ? getConfig(ownedBy, (String)(recOld == null ? rec.get('LeadSource') : null), recOld == null) : null);
            // if an incoming form is storing the original data (in the partner referral) we'll assume 
            Boolean webleadChk = (llc != null && llc.IsActive__c && llc.StoreOrginalData__c);
            System.debug('checkRecordsBefore webleadChk='+webleadChk+' ownedBy='+ownedBy);
            // reset the checkbox
            //if (webleadChk) { // || webleadChk2) {
            //   resetWeblead(rec);
            //} 
            // so it will work with or without the checkbox
            //String configName = (String.isNotBlank(ownedBy) ? ownedBy : ((webleadChk) ? WEBLEAD : null));
            String recInfo = 'webleadChk='+webleadChk; //+' configName='+configName;
            //webleadChk = (webleadChk || (String.isNotBlank(configName) && configName.startsWith(WEBLEAD)));
            if (webleadChk) {
               // check the consent to text flag
               checkConsentToText(rec, recOld, webleadChk);
            }
            // if this is not production, set the Marketo_
            // __c flag for testing purposes
            // running for test too for code coverage
            if ((!isProduction || Test.isRunningTest()) 
                  && recOld == null 
                  && (webLeadChk || runningUserIsMarketo)) {
               try {
                  rec.put('Marketo_Sync__c',true);
               } catch (Exception e) {
                  StringHelper.addToProcessNotes(rec, 'Exception setting Marketo_Sync__c: '+e.getMessage());
               }
            } 
            
            // break this out here because we're not going to set the OwnedBy__c field on an insert with the WebLead__c checkbox
            // so we can perform additional checks before it's assigned. 
            System.debug('checkRecordsBefore llc='+llc);
            //if (llc != null && llc.IsActive__c && llc.StoreOrginalData__c) {
            if (webleadChk) {
               recInfo += ' StoreOriginalData__c=true'; 
               // if this is a weblead directly from Marketo we're going to have to reformat the description
               //checkLeadDescription(rec, webleadChk);
               Boolean checkForDupe = (recOld == null && (llc.CheckForDuplicate__c));
               Id ampId = ((leadAMPRefMap != null && objectType == ObjectHelper.OBJECT_LEAD) ? (Id)rec.get('amp_dev__Referral__c')
                                : ((leadAMPRefMap != null && objectType == ObjectHelper.OBJECT_CONTACT) ? (Id)rec.get('AMP_Referral__c') : null));
               amp_dev__Amp_Referral__c ampReferralRec = ((ampId != null && leadAMPRefMap != null) ? leadAMPRefMap.get(ampId) : null);
               checkRecordBefore(rec, recOld, objectType, llc, transactionTime+recCnt, ctctsByAcctIdMap,checkForDupe,ampReferralRec);  
            
            } else {
               // assume the records in the batch will be all of the same type. Once we find one we don't need, we'll stop checking.
               System.debug('checkRecordsBefore StoreOriginalData__c not found for checkRec ownedBy='+rec.get('OwnedBy__c')
                          +' leadSource='+(recOld == null ? rec.get('LeadSource') : '')
                          +' user='+UserInfo.getUserId());
               if (rec.get('OwnedBy__c') != null) {
                  StringHelper.addToProcessNotes(rec, 'Cleared the OwnedBy field: '+(String)rec.get('OwnedBy__c'));
                  rec.put('OwnedBy__c',null);
               }
               return;
            }
            
            StringHelper.addToProcessNotes(rec, recInfo);
         }
      } // for (Integer recCnt = 1
   } // checkRecordsBefore
   
   public static Boolean MARKETO_LEADS_ONLY=false;
   public static String MARKETO_SEPARATOR=Label.Marketo_Separator;
   
   public static String WEBLEAD_START='Web Lead Received';
   public static String WEBLEAD_START_MARKETO='Web Lead Received Marketo';
   public static String WEBLEAD_END='End Web Lead';
   
   public static String CONSENT_CHANGE_REASON_WEB='Web Lead change';
   
   public static void checkConsentToText(SObject rec, SObject oldRec, Boolean isWeblead) {
      Boolean newFlag = (rec.get('Consent_to_Text__c') != null ? (Boolean)rec.get('Consent_to_Text__c') : false);
      Boolean oldFlag = (oldRec != null && oldRec.get('Consent_to_Text__c') != null ? (Boolean)oldRec.get('Consent_to_Text__c') : false);
      // if the flag changes reset the date
      if (newFlag != oldFlag) {
         rec.put('Consent_to_Text_Date__c', DateTime.now());
         if (isWebLead) {
            rec.put('Consent_to_Text_reason__c', CONSENT_CHANGE_REASON_WEB);
         }
      } 
   } // checkConsentToText

   // reformat description field that comes from Marketo.
  /* public static void checkLeadDescription(SObject rec, Boolean isWebLead) {
      String description = (String)rec.get('Description');
      Boolean hasDescription = String.IsNotBlank(description);
      Boolean descStartsWithWEBLEAD_START=(hasDescription && description.startsWith(WEBLEAD_START));
      System.debug('checkLeadDescription hasDescription='+hasDescription+' isWebLead='+isWebLead+' descStartsWithWEBLEAD_START='+descStartsWithWEBLEAD_START);
      if (hasDescription && !descStartsWithWEBLEAD_START) {
         String newDesc = '';
         Boolean hasMarketoSepartor=description.contains(MARKETO_SEPARATOR);
         System.debug('checkLeadDescription hasMarketoSepartor='+hasMarketoSepartor+' MARKETO_SEPARATOR='+MARKETO_SEPARATOR+'.');
         if (isWebLead && hasMarketoSepartor) {
            String[] tokens = description.split(MARKETO_SEPARATOR);
            System.debug('checkLeadDescription tokens='+tokens.size());
            newDesc=WEBLEAD_START_MARKETO+':';
            for (String token : tokens) {
               newDesc += '\n'+token;
            }
            newDesc += '\n'+WEBLEAD_END+' Marketo '+Datetime.now().format('MM/dd/yyyy hh:mm a');
         } else {
            newDesc=WEBLEAD_START+':\n';
            newDesc += description;
            newDesc += '\n'+WEBLEAD_END+' '+Datetime.now().format('MM/dd/yyyy hh:mm a');
         }
         newDesc += '\n---------------------------------------------------\n';
         rec.put('Description',newDesc);
      } // if (String.IsNotBlank
          
   } // checkLeadDescription */
   
   // reset the weblead checkbox and set the owned by field
   public static void resetWeblead(SObject rec) {
      /*
      Boolean curValue = (Boolean)rec.get('Weblead__c');
      // only reset it if it's true
      if (curValue != null && curValue) {
         StringHelper.addToProcessNotes(rec, 'resetting WebLead__c flag');
         // clear out the weblead checkbox to be triggered next time.
         rec.put('Weblead__c',false);
         // if there's already a value don't overwrite it.
         if (rec.get('OwnedBy__c') == null) {
            StringHelper.addToProcessNotes(rec,'setting OwnedBy__c to '+WEBLEAD);
            // set this field so it will fall into the existing lead loader process
            rec.put('OwnedBy__c',WEBLEAD);
         }
      }
   */
   } // resetWeblead
   
   public static void checkRecordBefore(SObject rec, SObject recOld, String objectType, LeadLoaderConfig__c llc, Long transactionTime, Map<Id, Contact[]> ctctsByAcctIdMap, Boolean checkForDupe, amp_dev__Amp_Referral__c ampReferralRec) {
      String transactionId = (String)rec.get('TransactionId__c');
      System.debug('checkRecordBefore 1 transactionId='+transactionId);
      if (String.isBlank(transactionId)) {
         transactionId = (rec.Id != null ? (String)rec.Id : String.valueOf(transactionTime));
         rec.put('TransactionId__c', String.valueOf(transactionId));
      }
      // mark this record as processed
      recordsProcessedSet.add(transactionId);
      System.debug('checkRecordBefore 2 transactionId='+transactionId);
      // do we bypass the data governance?
      rec.put('DGBypass__c',llc.BypassDG__c);
      if (objectType == ObjectHelper.OBJECT_LEAD) {
         logOriginalData((Lead)rec,(Lead)recOld, null,checkForDupe,ampReferralRec);
         // check the record type of the lead
         checkLeadRecordType((Lead)rec, (Lead)recOld, llc);
      } else if (objectType == ObjectHelper.OBJECT_CONTACT) {
         Contact ctct = (Contact)rec;
         Contact[] ctctList = ctctsByAcctIdMap.containsKey(ctct.AccountId) ? ctctsByAcctIdMap.get(ctct.AccountId) : new Contact[]{};
         ctctList.add(ctct);
         ctctsByAcctIdMap.put(ctct.AccountId, ctctList);
      }
      // moved owned by so not triggered elsewhere
      rec.put('OwnedByPrev__c',llc.Name);
      rec.put('OwnedBy__c',null);
      System.debug('checkRecordBefore reset OwnedBy__c');
   } // checkRecordBefore
   
   public static void checkLeadRecordType(Lead ld, Lead oldLd, LeadLoaderConfig__c llc) {
      // right now only check if an insert
      if (oldLd == null && llc != null && String.isNotBlank(llc.Sales_Org__c)) {
         SalesOrg__c salesOrgCs = SalesOrg__c.getInstance(llc.Sales_Org__c);
         if (salesOrgCs != null && String.isNotBlank(salesOrgCs.LeadRecordTypeName__c)) {
            Map<String,Schema.RecordTypeInfo> byNameMap = Lead.SObjectType.getDescribe().getRecordTypeInfosByName();
            Schema.RecordTypeInfo rtInfo = byNameMap.get(salesOrgCs.LeadRecordTypeName__c);
            if (rtInfo != null && rtInfo.getRecordTypeId() != ld.RecordTypeId) {
               ld.RecordTypeId = rtInfo.getRecordTypeId();
               StringHelper.addToProcessNotes(ld,'Set RecordType to '+salesOrgCs.LeadRecordTypeName__c);
            }
         }
      }
   } // checkLeadRecordType
   
   // do we use the employee count from the contact description (if it exists)
   public static Boolean CHECK_CTCT_EMP_CNT = Label.TrackRecord_CtctEmpCnt == 'Y';
   private static Map<Id,Account> updateAcctMap = new Map<Id,Account>();
   public static void checkContactsBefore(Contact[] ctcts, Map<Id,Contact> oldMap) {
      Id[] ampRefIds = new Id[]{};
      Id[] campIds = new Id[]{}; 
      Map<Id,Id> accIdtoCampIdMap = new Map<Id,Id>();
      for (Contact ctct : ctcts) {
         Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);
         if (ctct.AMP_Referral__c != null 
                && (oldCtct == null || (ctct.AMP_Referral__c != oldCtct.AMP_Referral__c))) {
            // only need to process if lookup changes
            ampRefIds.add(ctct.AMP_Referral__c);
            // this is if the lead isn't created by Amplifinity (adding an existing lead to Amp)
            if (String.isBlank(ctct.OwnedBy__c)) {
               ctct.OwnedBy__c = 'ReferralManagement'; 
               //ld.Referral_Management__c = REF_MGMT;
            }
              
         } // if (ctct.AMP_Referral__c != null
         //APR0109624
         if(ctct.LatestCampaign__c!= null){
            campIds.add(ctct.LatestCampaign__c);
            accIdtoCampIdMap.put(ctct.AccountId, ctct.LatestCampaign__c);
         }
      } // for(Lead ld : Leads
      Map<Id,amp_dev__Amp_Referral__c> leadAMPRefMap = getAmpReferralMap(ampRefIds);

      Map<Id, Contact[]> ctctsByAcctIdMap = new Map<Id, Contact[]>();
      checkRecordsBefore(ctcts, oldMap, ObjectHelper.OBJECT_CONTACT, ctctsByAcctIdMap, leadAMPRefMap);
      updateCityState(ctcts, oldMap, ObjectHelper.OBJECT_CONTACT);
        
      System.debug('checkContactsBefore ctctsByAcctIdMap='+ctctsByAcctIdMap.size());
      if (!ctctsByAcctIdMap.isEmpty()) {
         // if we're updating an account due to the employee count
        
       /*  Account[] accts = [Select Id, Name, OwnerId
                                  ,Employees__c
                                  ,NumberOfEmployees
                                  ,Owner_Zip_Code__c
                                  ,ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, Referral_National_Account__c
                              From Account
                             Where Id in :ctctsByAcctIdMap.keySet()]; */
         List<Account> accts = getAccounts(ctctsByAcctIdMap.keyset());
         for (Account acct : accts) {
            Contact[] ctctsByAcct = ctctsByAcctIdMap.get(acct.Id);
            System.debug('checkContactsBefore ctctsByAcct='+ (ctctsByAcct != null ? ctctsByAcct.size() : -1));
            if (ctctsByAcct != null) {
               //String empLog = checkEmployeeCount(acct, ctctsByAcct[0], null, updateAcctMap);
               //System.debug('checkContactsBefore empLog='+empLog);
               String empLog = '';
               for (Contact ctct : ctctsByAcct) {
                  Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);                   
                  amp_dev__Amp_Referral__c ampRef = ((leadAMPRefMap != null && ctct.AMP_Referral__c != null) ? leadAMPRefMap.get(ctct.AMP_Referral__c) : null);
                  logOriginalData(ctct, oldCtct, acct, empLog, false, updateAcctMap, ampRef);
               }
            }
         }  
      //   checkFranchiseCodes(updateAcctMap);
       System.debug('checkContactsBefore updateAcctMap='+updateAcctMap.size());
      } // if (!ctctsByAcctIdMap.isEmpty
      //APR0109624
      setStrategicAcct(null, campIds, accIdtoCampIdMap, updateAcctMap);
       if (!updateAcctMap.isEmpty()) {
           ZipCheckOwner.SKIP_TRIGGERS=true;
           DmlHelper.performDML2(updateAcctMap.values(), DmlHelper.DML_UPDATE, 'TrackRecordEntry', 'checkContacts', 'update accounts emp count/strategic account', true);
           ZipCheckOwner.SKIP_TRIGGERS=false;
       }
      
   } // checkContacts


   /* Execute annonymous test:
   
   String descrip = 'NUMBER_OF_EMPLOYEES: 4\n'
+'FIRSTNAME: Jeffrey\n'
+'LASTNAME: COOP\n'
+'PHONE: (417) 631-6799\n'
+'EMAIL: fryingchicken83@gmail.com\n'
+'COMPANY_NAME: Scil\n'
+'ADDRESS_1: \n'
+'CITY: Springfield\n'
+'STATE: MO\n'
+'POSTAL_CODE: 65803\n'
+'CAMPAIGN: 70170000000VHBN\n'
+'LEAD_SOURCE: Corp Marketing-Web\n'
+'CONSENT: false\n'
+'MOBILE_NUMBER: \n'
+'CONSENT_DATE: 2017-12-27T07:23:52Z\n'
+'----------: \n'
+'\n'
+'Lead Tracking Information\n'
+'PAYROLL_PACKAGE |^| \n'
+'PROCESSING_FREQUENCY |^|\n' 
+'PRICING |^| \n'
+'REFERER |^| MARKETO\n'
+'FIRSTNAME |^| Jeffrey\n'
+'LASTNAME |^| COOP\n'
+'EMAIL |^| fryingchicken83@gmail.com\n'
+'PHONE |^| 4176316799\n'
+'POSTAL_CODE |^| 65803\n'
+'NUMBER_OF_EMPLOYEES |^| 5\n'
+'CAMPAIGN |^| 70170000000VHBN\n'
+'LEAD_SOURCE |^|\n' 
+'COMPANY_NAME |^| Scil\n'
+'ADDRESS_1 |^|\n' 
+'PPCPN |^|\n';
Account acct = new Account(Name='Test', Employees__c=3, NumberOfEmployees=3);
Contact ctct = new Contact(LastName='TestLast', Description = descrip);
Account[] updateAccts = new Account[]{};
TrackRecordEntry.checkEmployeeCount(acct,ctct,updateAccts);
   */

/*   public static void checkFranchiseCodes(Map<Id,Account> updateAcctMap) {
      System.debug('checkFranchiseCodes franchiseCodeMap='+franchiseCodeMap.size());
      if (franchiseCodeMap.isEmpty()) {
         return;
      }
      Referral_Account__c[] refAccts = [SELECT Id, Name, National_Account_Code__c 
                                          FROM Referral_Account__c 
                                         WHERE National_Account_Code__c in :franchiseCodeMap.keySet() 
                                           AND Parent_Referral_Account__c = null];
      System.debug('checkFranchiseCodes refAccts='+refAccts);
      for (Referral_Account__c refAcct : refAccts) {
         SObject[] recs = franchiseCodeMap.get(refAcct.National_Account_Code__c);
         if (recs != null) {
            for (SObject rec : recs) {
               Id rfrlNtlAcctId = (Id)rec.get('Referral_National_Account__c');
               if (refAcct.Id != rfrlNtlAcctId) {
                  System.debug('checkFranchiseCodes setting the Referral_National_Account__c field with '+refAcct.Id);
                  rec.put('Referral_National_Account__c', refAcct.Id);
                  // only need to check for the account because for the lead we're in the before trigger.
                  if (updateAcctMap != null && rec.getSObjectType() == Account.sObjectType) {
                     Account updateAcct = (updateAcctMap.containsKey(rec.Id) ? updateAcctMap.get(rec.Id) : new Account(Id=rec.Id));
                     updateAcct.Referral_National_Account__c = refAcct.Id;
                     System.debug('checkFranchiseCodes updateAcct='+updateAcct);
                     updateAcctMap.put(updateAcct.Id,updateAcct);
                  }
               }
            } // for (SObject rec
         } // if (recs != null
      } // for (Referral_Account__c refAcct
      franchiseCodeMap.clear();
   } // checkFranchiseCodes
*/  
   public static Map<String,SObject[]> franchiseCodeMap = new Map<String,SObject[]>();
   
   public static String EMPLOYEES_TAG=Label.TrackRecord_EmployeesTag;
   public static String FRANCHISE_TAG=Label.TrackRecord_FranchiseTag;
   public static String VENDOR_TAG=Label.TrackRecord_VendorTag;
   public static String XEROID_TAG=Label.TrackRecord_XeroID;
   
 /*  public static void checkFormTags(PartnerReferral__c partRef, Lead ld, Account acct) {
      String recentDesc = MarketTrackingMethods.getRecentDescription(partRef.Description__c);
      System.debug('checkFormTags has recentDesc='+String.isNotBlank(recentDesc));
      if (String.isNotBlank(recentDesc)) {
         String empStr = getTagValue(EMPLOYEES_TAG, recentDesc);
          System.debug('TrackRecordEntry.checkFormTags-- empStr:'+empStr);
         if (String.isNotBlank(empStr)) {
              System.debug('TrackRecordEntry.checkFormTags-- inside not blank empStr:');
             system.debug('checkFormTags empStr' + empStr); 
            partRef.EmployeesFromForm__c = Integer.valueOf(empStr);
         }
         String franchiseCode = getTagValue(FRANCHISE_TAG, recentDesc);
          System.debug('TrackRecordEntry.checkFormTags-- franchiseCode:'+franchiseCode);
         if (String.isNotBlank(franchiseCode)) {
             System.debug('TrackRecordEntry.checkFormTags-- inside not blank franchiseCode:');
            partRef.Franchise_Account_Code__c = Integer.valueOf(franchiseCode);
            // group all together so we can do a bulk transaction
            SObject mapObj = (acct != null ? (Sobject)acct : (SObject)ld);
            if (mapObj != null) {
               SObject[] recs = (franchiseCodeMap.containsKey(franchiseCode) ? franchiseCodeMap.get(franchiseCode) : new SObject[]{});
               recs.add(mapObj);
               franchiseCodeMap.put(franchiseCode, recs);
            }
         } // if (String.isNotBlank
         String vendorId = getTagValue(VENDOR_TAG, recentDesc);
         if (String.isNotBlank(vendorId)) {
            partRef.Vendor_ID__c = Integer.valueOf(vendorId);
         }
         String xeroId = getTagText(XEROID_TAG, recentDesc);
         if (String.isNotBlank(xeroId)) {
            partRef.Xero_Id__c= xeroId;
         }
         System.debug('checkFormTags empStr='+empStr+' franchiseCode='+franchiseCode+' vendorId='+vendorId+ 'xeroId='+xeroId);
      } // if (String.isNotBlank(recentDesc
   } // checkFormTags */
   
  /* public static String getTagValue(String tag, String recentDesc) {
      String value = null;
      try {
         Boolean hasTag = recentDesc.contains(tag);
         System.debug('getTagValue tag='+tag+' hasTag='+hasTag);
         if (hasTag) {
            Integer startPos = recentDesc.indexOf(tag)+tag.length();
            Integer endPos = recentDesc.indexOf('\r',startPos);
            if (endPos == -1 || endPos > 20) {
               endPos = recentDesc.indexOf('\n',startPos);
            }
            String tagSubString = recentDesc.subString(startPos, endPos).trim();
            String tagSubStringCleaned = Utilities.removeExtraChars(tagSubString, Utilities.ALL_NUMBERS);
            String debugStr = ' startPos='+startPos+' endPos='+endPos+' tagSubString='+tagSubString+' tagSubStringCleaned='+tagSubStringCleaned;
            value = tagSubstringCleaned;
            System.debug('getTagValue'+debugStr);
         } // if (hasTag
      } catch (Exception e) {
         System.debug('getTagValue exception parsing tag: '+e.getMessage()+'; '+e.getStackTraceString());
      }
      return value;
   } // getTagValue */

/*    public static String getTagText(String tag, String recentDesc) {
      String value = null;
      try {
         Boolean hasTag = recentDesc.contains(tag);
         System.debug('getTagValue tag='+tag+' hasTag='+hasTag);
         if (hasTag) {
            Integer startPos = recentDesc.indexOf(tag)+tag.length();
            Integer endPos = recentDesc.indexOf('\r',startPos);
            if (endPos == -1 || endPos > 20) {
               endPos = recentDesc.indexOf('\n',startPos);
            }
            String tagSubString = recentDesc.subString(startPos, endPos).trim();
            String tagSubStringCleaned = Utilities.removeExtraChars(tagSubString, Utilities.ALL_APLHA_NUMERIC);
            String debugStr = ' startPos='+startPos+' endPos='+endPos+' tagSubString='+tagSubString+' tagSubStringCleaned='+tagSubStringCleaned;           
            value = tagSubStringCleaned;
            System.debug('getTagValue'+debugStr);
         } // if (hasTag
      } catch (Exception e) {
         System.debug('getTagValue exception parsing tag: '+e.getMessage()+'; '+e.getStackTraceString());
      }
      return value;
   } // getTagValue */

   // get the lead loader config based on the owned by field (or other attributes)
   public static LeadLoaderConfig__c getConfig(String ownedBy, String leadSource, Boolean isInsert) {
      LeadLoaderConfig__c llc = null;
      
      // see if there's a default based on the lead source - only on insert
      if (String.isBlank(ownedBy) && String.isNotBlank(leadSource)) {
         LeadSource__c lsSetting = LeadSource__c.getInstance(leadSource);
         if (lsSetting != null && String.isNotBlank(lsSetting.OwnedByDefault__c)) {
            ownedBy = lsSetting.OwnedByDefault__c;
         }
      } // if (String.isBlank(ownedBy) && String.isNotBlank(leadSource
      
      // see if there's a default owned by based on the user's profile - only on insert
      if (String.isBlank(ownedBy) && isInsert) {
         User usr = UserHelper.getRunningUser();
         Profile_List__c profList = Profile_List__c.getInstance(usr.Profile.Name);
         if (profList != null && String.isNotBlank(profList.OwnedByDefault__c)) {
            ownedBy = profList.OwnedByDefault__c;
         }
      } // if (String.isBlank
            
      if (String.isNotBlank(ownedBy)) {
         llc = LeadLoaderConfig__c.getInstance(ownedBy);
      }
      return llc;
   } // getConfig
   
   public static PartnerReferral__c logOriginalData(Lead ld) {
      return logOriginalData(ld,null,null,false,null);
   } // logOriginalData
   
   public static PartnerReferral__c logOriginalData(Lead ld, String addToNotes) {
      return logOriginalData(ld,null,addToNotes,false,null);
   }

   public static PartnerReferral__c logOriginalData(Lead ld, String addToNotes, Boolean checkForDupes) {
      return logOriginalData(ld,null,addToNotes,checkForDupes,null);
   }

   // log the original detail from the Lead
   public static PartnerReferral__c logOriginalData(Lead ld, Lead oldLd, String addToNotes, Boolean checkForDupes,amp_dev__Amp_Referral__c ampReferralRec) {
      System.debug('logOriginalData for ld='+(ld != null ? String.valueOf(ld.Id) : 'No Lead'));
      PartnerReferral__c partRef = new PartnerReferral__c();
      StringHelper.addToProcessNotes(partRef,'logOriginalData for ld='+(ld != null ? ld.LastName : 'No Lead'));
      if (String.IsNotBlank(addToNotes)) {
         StringHelper.addToProcessNotes(partRef,addToNotes);
      }
      if (ld != null) {
         StringHelper.addToProcessNotes(ld,'LogOriginalData from Lead transactionId='+ld.TransactionId__c);
         partRef.OwnerIdPrevious__c = ld.OwnerId;
         partRef.Company__c = ld.Company;
         partRef.StreetAddress__c = ld.Street;
         partRef.City__c = ld.City;
         partRef.State__c = ld.State;
         partRef.ZipPostalCode__c = ld.PostalCode;
         StringHelper.addToProcessNotes(partRef,'NumberOfEmployees from Lead='+ld.NumberOfEmployees);                                
         partRef.NumberOfEmployees__c = ld.NumberOfEmployees;
         partRef.LastName__c = ld.LastName;
         partRef.FirstName__c = ld.FirstName;
         partRef.Title__c = ld.Title; 
         partRef.Email__c = ld.Email;
         partRef.Phone__c = ld.Phone;
         partRef.MobilePhone__c = ld.MobilePhone;
         partRef.Consent_to_Text__c = ld.Consent_to_Text__c;
         partRef.Consent_to_Text_Date__c = ld.Consent_to_Text_Date__c;
         partRef.Products__c = ld.Products__c;
         partRef.Campaign__c = ld.LatestCampaign__c;
         partRef.CampaignId__c = ld.LatestCampaign__c; 
         partRef.Marketo_Lead_Rating__c = ld.Marketo_Lead_Rating__c;
         partRef.MarketingStage__c = ld.Lead_Stage__c;
         partRef.MarketingStagePrev__c = (oldLd != null ? oldLd.Lead_Stage__c : null);
         partRef.Form_Fill_Date__c = ld.Form_Fill_Date__c;
         partRef.Description__c = ld.Description; 
         StringHelper.addToProcessNotes(partRef,'Lead Source from Lead='+ld.LeadSource);
         partRef.LeadSource__c = ld.LeadSource;
         partRef.BuyerZone_Lead_ID__c = ld.BuyerZone_Lead_ID__c;
         partRef.CurrentPayrollMethod__c = ld.Current_Prior_Method__c;
         partRef.MktgId__c = ld.MktgId__c;
         partRef.PromoCode__c = ld.Promo_Code__c;
         partRef.ProductDivision__c = ld.Product_Division__c; 
         partRef.Amplifinity_Referral__c = ld.amp_dev__Referral__c; 
         if (ampReferralRec != null && ampReferralRec.amp_dev__Advocate__r != null) {
             partRef.Amplifinity_Advocate__c = ampReferralRec.amp_dev__Advocate__r.Id;
             partRef.CreatedByProcess__c = 'Amplifinity';
             partRef.Destination__c=REF_MGMT;
             partRef.OwnerIdNew__c = ampReferralRec.amp_dev__Advocate__r.OwnerId;
         }
         StringHelper.addToProcessNotes(partRef,'Lead Rating from Lead='+ld.Marketo_Lead_Rating__c);
         partRef.Source__c = ld.OwnedBy__c;
         StringHelper.addToProcessNotes(partRef,'OwnedBy on Ld='+ld.OwnedBy__c+' prev='+ld.OwnedByPrev__c);
         System.debug('logOriginalData ALLOW_DUPE_CHECK='+ALLOW_DUPE_CHECK+' checkForDupes='+checkForDupes);
        // checkFormTags(partRef,ld,null);
         if (ALLOW_DUPE_CHECK && checkForDupes) {
            dupeCheckMap.put(ld.TransactionId__c, partRef);
            dupeObjectList.add(ld);
            
         } else {
            partRefMap.put(ld.TransactionId__c, partRef);
         }
      } // if (ld != null)
      System.debug('TrackRecordEntry.logOriginalData ld='+ld.Id+' campaign='+ld.LatestCampaign__c+' partRef.cmpgn='+partRef.Campaign__c);
      return partRef;
   } // logOriginalData
   
   public static PartnerReferral__c logOriginalData(Contact ctct, Account acct) {
      return logOriginalData(ctct,null,acct,null,false,(Map<Id,Account>)null, null);
   }

   public static PartnerReferral__c logOriginalData(Contact ctct, Account acct, String addToNotes) {
      return logOriginalData(ctct,null,acct,null,false,(Map<Id,Account>)null, null);
   }

   public static PartnerReferral__c logOriginalData(Contact ctct, Account acct, String addToNotes, Boolean checkForDupes) {
      return logOriginalData(ctct,null,acct,addToNotes,checkForDupes,(Map<Id,Account>)null, null);
   }
   
   // log the original detail from the Contact/Account
   public static PartnerReferral__c logOriginalData(Contact ctct, Contact oldCtct, Account acct, String addToNotes, Boolean checkForDupes) {
      return logOriginalData(ctct,oldCtct,acct,addToNotes,checkForDupes,(Map<Id,Account>)null, null);
   }
      
   public static PartnerReferral__c logOriginalData(Contact ctct, Contact oldCtct, Account acct, String addToNotes, Boolean checkForDupes,Map<Id,Account> updateAcctMap, amp_dev__Amp_Referral__c ampReferralRec) {
      //System.debug('logOriginalData for ctct='+(ctct != null ? ctct.LastName : 'No Contact'));
      PartnerReferral__c partRef = new PartnerReferral__c();
      StringHelper.addToProcessNotes(partRef,'logOriginalData for ctct='+(ctct != null ? String.valueOf(ctct.Id)  : 'No Contact')+' and acct='+(acct != null ? String.valueOf(acct.Id) : 'No Account'));
      if (String.IsNotBlank(addToNotes)) {
         StringHelper.addToProcessNotes(partRef,addToNotes);
      }
      partRef.Amplifinity_Referral__c = (ampReferralRec != null ? ampReferralRec.Id : null); 
      if (ampReferralRec != null && ampReferralRec.amp_dev__Advocate__r != null) {
          partRef.Amplifinity_Advocate__c = ampReferralRec.amp_dev__Advocate__r.Id;
          partRef.CreatedByProcess__c = 'Amplifinity';
          partRef.Destination__c=REF_MGMT;
          partRef.OwnerIdNew__c = ampReferralRec.amp_dev__Advocate__r.OwnerId;
      }
      if (ctct != null) {
         StringHelper.addToProcessNotes(ctct,'LogOriginalData from Contact transactionId='+ctct.TransactionId__c);
         partRef.LastName__c = ctct.LastName;
         partRef.FirstName__c = ctct.FirstName;
         partRef.Email__c = ctct.Email;
         partRef.Phone__c = ctct.Phone;
         partRef.Title__c = ctct.Title; 
         partRef.MobilePhone__c = ctct.MobilePhone;   
         partRef.Consent_to_Text__c = ctct.Consent_to_Text__c;
         partRef.Consent_to_Text_Date__c = ctct.Consent_to_Text_Date__c;                               
         partRef.Products__c = ctct.Products__c; //String.isNotBlank(ld.Products__c) ? ld.Products__c : PartnerWrapper.PROD_INTEREST_PAYROLL;
         partRef.Campaign__c = ctct.LatestCampaign__c;
         partRef.CampaignId__c = ctct.LatestCampaign__c;
         partRef.Marketo_Lead_Rating__c = ctct.Marketo_Lead_Rating__c;
         partRef.MarketingStage__c = ctct.Contact_Stage__c;
         partRef.MarketingStagePrev__c = (oldCtct != null ? oldCtct.Contact_Stage__c : null);
         partRef.Form_Fill_Date__c = ctct.Form_Fill_Date__c;
         partRef.Description__c = ctct.Description;
         partRef.LeadSource__c = ctct.LeadSource;
         partRef.BuyerZone_Lead_ID__c = ctct.BuyerZone_Lead_ID__c;
         partRef.MktgId__c = ctct.MktgId__c;
         StringHelper.addToProcessNotes(partRef,'Lead Rating from ctct='+ctct.Marketo_Lead_Rating__c);
         partRef.Source__c = ctct.OwnedByPrev__c;
         //checkFormTags(partRef,null,acct);
        
         if (ALLOW_DUPE_CHECK && checkForDupes) {
            dupeCheckMap.put(ctct.TransactionId__c, partRef);
            dupeObjectList.add(ctct);
         } else {
            partRefMap.put(ctct.TransactionId__c, partRef);
         }
      } // if (ctct != null
      if (acct != null) {
         partRef.OwnerIdPrevious__c = acct.OwnerId;
         partRef.Company__c = acct.Name;
         partRef.StreetAddress__c = acct.ShippingStreet;
         partRef.City__c = acct.ShippingCity;
         partRef.State__c = acct.ShippingState;
         partRef.ZipPostalCode__c = acct.Owner_Zip_Code__c;
         System.debug('logOriginalData partRef.EmployeesFromForm__c='+partRef.EmployeesFromForm__c);
         if (partRef.EmployeesFromForm__c != null && partRef.EmployeesFromForm__c != acct.NumberOfEmployees && updateAcctMap != null) {
            Account updateAcct = (updateAcctMap.containsKey(acct.Id) ? updateAcctMap.get(acct.Id) : new Account(Id=acct.Id));
            updateAcct.Employees__c = partRef.EmployeesFromForm__c;
            updateAcct.NumberOfEmployees = Integer.valueOf(partRef.EmployeesFromForm__c);
            updateAcctMap.put(updateAcct.Id,updateAcct);
            partRef.NumberOfEmployees__c = partRef.EmployeesFromForm__c;
         } else {
            partRef.NumberOfEmployees__c = acct.NumberOfEmployees;
         }
         partRef.CurrentPayrollMethod__c = acct.Current_Prior_Method__c;
      } // if (acct != null
      return partRef;
   } // logOriginalData
   
   public static void checkLeadsAfter(Lead[] leads, Map<Id,Lead> oldMap) {
      for (Lead ld : leads) {
         String transactionId = ld.TransactionId__c;
         if (String.isNotBlank(transactionId) && partRefMap.containsKey(transactionId)) {
            Lead oldL = (oldMap != null ? oldMap.get(ld.Id) : null);
            // if the WebLead__c checkbox is still set, we want to check for duplicates
            ///LeadLoaderConfig__c llc = getConfig(ld.OwnedByPrev__c, null, false);
            ///if (llc != null && llc.StoreOrginalData__c) {
            System.debug('TrackRecordEntry.checkLeadsAfter setWrapper ld='+ld.Id);
            setWrapper(ld, null, oldL == null);
         }
      } // for Lead ld
      
      System.debug('checkLeadsAfter wrapperByIdMap='+wrapperByIdMap.size());
      ErrorLog.addToDescription(v_runLog, 'checkLeadsAfter wrapperByIdMap='+wrapperByIdMap.size());
      
      finishAfterProcessing(ObjectHelper.OBJECT_LEAD);
   } // checkLeadsAfter
   
   // check for amplifinity referrals on the incoming partner referrals
   public static Boolean checkForAmpReferral() {
      Boolean isAmplifinity = false;
      Id[] ampReferralIds = new Id[]{};
      for (PartRefWrapper wrap : wrapperByIdMap.values()) {
         if (wrap.partRef.Amplifinity_Referral__c != null) {
            ampReferralIds.add(wrap.partRef.Amplifinity_Referral__c);
            isAmplifinity=true;
         }
      } // for (PartRefWrapper wrap

      Map<Id,amp_dev__Amp_Referral__c> ampRfrlMap = getAmpReferralMap(ampReferralIds);
      System.debug('checkForAmpReferral ampReferralIds='+ampReferralIds.size()+' ampRfrlMap='+ampRfrlMap.size());
      
      for (PartRefWrapper wrap : wrapperByIdMap.values()) {
         if (wrap.partRef.Amplifinity_Referral__c != null) {
            wrap.ampReferral = ampRfrlMap.get(wrap.partRef.Amplifinity_Referral__c);
            if (wrap.ampReferral != null) {
               wrap.ampAdvocate = wrap.ampReferral.amp_dev__Advocate__r;
            }
         }
      } // for (PartRefWrapper wrap
      
      ErrorLog.addToDescription(v_runLog,'ampReferralIds='+ampReferralIds.size()+' ampRfrlMap='+ampRfrlMap.size());
      return isAmplifinity;
   } // checkForAmpReferral

   public static String checkContactsAfter(Contact[] ctcts, Map<Id,Contact> oldMap) {
      String runLog = 'checkContactsAfter ctcts='+ctcts.size();
      System.debug('checkContactsAfter ctcts='+ctcts.size());
      for (Contact ctct : ctcts) {
         String transactionId = ctct.TransactionId__c;
         runLog += '\n transactionId='+transactionId;
         if (String.isNotBlank(transactionId) && partRefMap.containsKey(transactionId)) {
            runLog += ' found in partRefMap';
            Contact oldC = (oldMap != null ? oldMap.get(ctct.Id) : null);
            //LeadLoaderConfig__c llc = getConfig(ld.OwnedByPrev__c, null, false);
            //if (llc != null && llc.StoreOrginalData__c) {
            setWrapper(null, ctct, oldC == null);
         } else {
            runLog += ' not found in partRefMap';
         }
      } // for Lead ld
      runLog += '\n wrapperByIdMap='+wrapperByIdMap.size();
      System.debug('checkContactsAfter wrapperByIdMap='+wrapperByIdMap.size());
      finishAfterProcessing(ObjectHelper.OBJECT_CONTACT);
      return runLog;
   } // checkContactsAfter

  
  
   // all of the wrappers
   public static Map<Id, PartRefWrapper> wrapperByIdMap = new Map<Id, PartRefWrapper>();
   
   // the campaign ids so they can be used for assignment routing
   public static Map<String, PartRefWrapper[]> wrappersByCampaignIdMap = new Map<String, PartRefWrapper[]>();
   //Lead and Contact Ids to use for Amplifinity Lead Routing Rules 
   public static Map<String, PartRefWrapper[]> wrappersByAmpOwnerIdMap = new Map<String, PartRefWrapper[]>();
   // the wrappers by the zip code 
   //public static Map<String, PartRefWrapper[]> wrappersByZipCodeMap = new Map<String, PartRefWrapper[]>();
   // to check for prospect ownership based on the id of the record - don't have to check on insert
   public static Map<String, PartRefWrapper[]> wrappersByIdOwnershipMap = new Map<String, PartRefWrapper[]>();
   
   public static void setWrapper(Lead ld, Contact ctct, Boolean isInsert) {
      String transactionId = (ld != null ? ld.TransactionId__c : (ctct != null ? ctct.TransactionId__c : null));
      Id recId = (ld != null ? ld.Id : (ctct != null ? ctct.Id : null));
      Id ampRefOwnerId = null;
      // don't need to check for ownership if insert
      Id ownershipId = (!isInsert ? (ld != null ? ld.Id : (ctct != null ? ctct.AccountId : null)) : null);
      System.debug('setWrapper transactionId='+transactionId+' recId='+recId);
      if (transactionId != null && recId != null) {
         PartnerReferral__c partRef = partRefMap.remove(transactionId);
         if (partRef != null) {
            // this is coming from DuplicateCheckQueueable so we can use the previous stage for evaluation.
            String prevStage = prevStageMap.get(transactionId);
            if (String.isNotBlank(prevStage)) {
               partRef.MarketingStagePrev__c = prevStage;
            }
            PartRefWrapper oldWrap = new PartRefWrapper(partRef, ld, ctct);
            if (oldWrap.partRef.Campaign__c != null) {
               // collect the campaign ids for later routing
               addToMap(oldWrap, oldWrap.partRef.Campaign__c, wrappersByCampaignIdMap);
            }
            
            if (ownershipId != null) {
               addToMap(oldWrap, ownershipId, wrappersByIdOwnershipMap);
            }
            // used to check if there's already a partner Referral out there
            wrapperByIdMap.put(recId, oldWrap);
            //used to check ownership of amp referrals
            if(oldWrap.partRef.Amplifinity_Advocate__c != null) {
                if(ld != null) {
                    ampRefOwnerId = ld.Id;
                }
                if(ctct != null){
                    ampRefOwnerId = ctct.Id;
                }
                if(ampRefOwnerId != null) {
                    addToMap(oldWrap, ampRefOwnerId, wrappersByAmpOwnerIdMap);
                } 
             } //// if(oldWrap.partRef.Amplifinity_Advocate__c != null)
         } // if (partRef != null
      } // if (transactionId != null
   } // setWrapper
   
   public static void addToMap(PartRefWrapper oldWrap, String key, Map<String,PartRefWrapper[]> checkMap) {
      PartRefWrapper[] wrappers = (checkMap.containsKey(key) ? checkMap.get(key) : new PartRefWrapper[]{});
      wrappers.add(oldWrap);
      checkMap.put(key,wrappers);
   } // addToMap
   
   // the number of hours we'll check for to consider an incoming record a "duplicate"
   public static Integer OLD_HOURS = Integer.valueOf(Label.OLD_DuplicateHours);
   
   public static void finishAfterProcessing(String objectType) {
      System.debug('finishAfterProcessing objectType='+objectType);
      ErrorLog.addToDescription(v_runLog, 'finishAfterProcessing objectType='+objectType);

      // check to see if there's an amplifinity advocate associated with this record
      Boolean isAmpRef = checkForAmpReferral();
      
      checkWorkable();
      
      partRefsToInsert.clear();
      // if there's an existing partner referral just link up to that one.
      checkForExisting();
      // create the referral records
      setupReferrals();
      // Remove prospect ownership check
      // see if there's any open prospect ownership records - ownership would default to them.
      //checkProspectOwnership(objectType);
      // see if there are any campaign rules we need to follow
      handleCampaigns();
      //Check ownership of Amplifinity Referrals
      handleAmpRefOwnership();
      // look at the employee count - see if there are special rules for that.
      PartRefWrapper[] notProcessed = checkLeadFilters();
      
      System.debug('finishAfterProcessing notProcessed='+notProcessed.size());
      // use the default ownership 
      setDefaultOwnership(notProcessed);
      
      checkSave();
      partRefMap.clear();
   } // finishAfterProcessing
   
   public static void checkSave() {
      
      // disable other triggers
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      LeadMethods.LEAD_BEFORE_EXECUTING = true;
      LeadMethods.LEAD_AFTER_EXECUTING = true;
      
      // save the partner referrals
      DmlHelper.performDML2(partRefsToInsert, DmlHelper.DML_INSERT, 'TrackRecordEntry', 'checkSave', 'insert partnerRefs', false);
      
      // query them to get the referral id
      Map<Id, PartnerReferral__c> partRefQueryMap = new Map<Id,PartnerReferral__c>([Select Id, Name, Referral__c
                                                                                 from PartnerReferral__c
                                                                                Where Id in :partRefsToInsert]);
      Referral__c[] insertRefs = new Referral__c[]{};
      
      // link the partner referral to the referral, set the referral id
      for (PartRefWrapper oldWrap : wrapperByIdMap.values()) {
         if (oldWrap.ref != null && oldWrap.partRef.Id != null) {
            PartnerReferral__c partRef = partRefQueryMap.get(oldWrap.partRef.Id);
            if (partRef == null) {
               partRef = oldWrap.partRef;
            }
            oldWrap.ref.PartnerReferral__c = partRef.Id;
            oldWrap.ref.Referral_Id__c = partRef.Name;
            insertRefs.add(oldWrap.ref);
         }
      } // for (PartRefWrapper oldWrap

      DmlHelper.performDML2(insertRefs, DmlHelper.DML_INSERT, 'TrackRecordEntry', 'checkSave', 'insert referrals', false);
      
      // if we have an existing opportunity we're setting on the referral, we're going to update the referral lookup here.
      Opportunity[] updateOpps = new Opportunity[]{};
      
      // link the partner referral back to the referral. Not sure we need to do this.
      PartnerReferral__c[] updatePartRefs = new PartnerReferral__c[]{};
      for (PartRefWrapper oldWrap : wrapperByIdMap.values()) {
         if (oldWrap.ref != null && oldWrap.ref.Id != null && oldWrap.partRef.Id != null) {
            PartnerReferral__c partRef = partRefQueryMap.get(oldWrap.partRef.Id);
            if (partRef != null) {
               partRef.Referral__c = oldWrap.ref.Id;
               updatePartRefs.add(partRef);
            }
         }
         if (oldWrap.ref != null && oldWrap.ref.Id != null && oldWrap.oppToUseForRef != null) {
            oldWrap.oppToUseForRef.ReferralLookup__c = oldWrap.ref.Id;
            updateOpps.add(oldWrap.oppToUseForRef);
         }
      } // for (PartRefWrapper oldWrap
      
      if (!updateOpps.isEmpty()) {
         OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
         DmlHelper.performDML2(updateOpps, DmlHelper.DML_UPDATE, 'TrackRecordEntry', 'checkSave', 'update Opportunities', false);
      }

      DmlHelper.performDML2(updatePartRefs, DmlHelper.DML_UPDATE, 'TrackRecordEntry', 'checkSave', 'update partner referrals', false);
      ErrorLog.checkSave();
   } // checkSave
   
   public static String EXISTING_LEAD_MSG=Label.NotifyOwner_ExistingLead;
   
   public static PartnerReferral__c[] partRefsToInsert = new PartnerReferral__c[]{};
   
   public static Set<String> ALWAYS_NEW_LEADS = new Set<String>(Label.TrackRecord_AlwaysNewLeadPrevStage.split(','));
      
   // check for existing OLD records in the specified time frame. If found, link the new one to the 
   // existing one and stop processing - don't need to do anything else because it should already be worked on.
   public static void checkForExisting() {
      System.debug('checkForExisting wrapperByIdMap='+wrapperByIdMap.size());
      if (!wrapperByIdMap.isEmpty()) {
         PartRefWrapper[] notWorkableRefs = new PartRefWrapper[]{};
         
         DateTime checkTime = DateTime.now().addHours(-OLD_HOURS);
         
         
         PartnerReferral__c[] existingOlds = [Select Id, Contact__c, Lead__c
                                                    ,Referral__c
                                                    ,Referral__r.Id
                                                    ,Referral__r.ReferralNotes__c
                                                    ,Campaign__c
                                                  ,Campaign__r.Type_2__c
                                                  ,Campaign__r.Partner_Referral_Source__c
                                                From PartnerReferral__c
                                               Where (Contact__c in :wrapperByIdMap.keySet()
                                                       or Lead__c in :wrapperByIdMap.keySet())
                                                 and Master_Partner_Referral__c=null 
                                                 and CreatedDate >= :checkTime
                                              ];
                                              
         Map<Id,Referral__c> updateRefMap = new Map<Id,Referral__c>();
         for (PartnerReferral__c existingPartRef : existingOlds) {
            // get the id used in the map
            Id recId = existingPartRef.Contact__c != null ? existingPartRef.Contact__c : existingPartRef.Lead__c;
            // remove from the map because we won't need to process this record anymore.
            PartRefWrapper oldWrap = wrapperByIdMap.get(recId);
            if (oldWrap != null) {
               // TODO - check the stage of the record, so we match up? 
               // existing stage is TAL, MQL - link to existing partner referral if within the timeframe.
               // previous stage was Reject, Recycle, Client - do not link to existing partner referral.
               if (String.isNotBlank(oldWrap.partRef.MarketingStagePrev__c) && ALWAYS_NEW_LEADS.contains(oldWrap.partRef.MarketingStagePrev__c)) {
                  StringHelper.addToProcessNotes(oldWrap.partRef, 'Previous stage was '+oldWrap.partRef.MarketingStagePrev__c+'. Not linking to existing PartRef.');
                  // we want it to process as normal so we will do nothing with it here.
                  System.debug('checkForExisting connecting to existing partner referral');
                  oldWrap = null;
               } else {
                  // we'll remove it from the map so it's not processed elsewhere
                  wrapperByIdMap.remove(recId);
               }
            }
            if (oldWrap != null) {
               // mark it as not workable
               oldWrap.partRef.Workable__c=NOT_WORKABLE;
               oldWrap.partRef.DuplicateNotWorkableReason__c = (String.isNotBlank(oldWrap.partRef.DuplicateNotWorkableReason__c) ? oldWrap.partRef.DuplicateNotWorkableReason__c+'; ' : '')+'Matched to existing Partner Referral';
               // TODO - have to update referrals.
               if (oldWrap.ampReferral != null) {
                  notWorkableRefs.add(oldWrap);
               }
               
               // link this partner referral to the existing one.
               oldWrap.partRef.Master_Partner_Referral__c = existingPartRef.Id;
               oldWrap.partRef.Referral__c = existingPartRef.Referral__c;
               oldWrap.routingHandled = true;
               StringHelper.addToProcessNotes(oldWrap.partRef,'TrackRecordEntry linked to existing PartnerReferral checkTime='+checkTime.format('M/d/yyyy H:m:s'));
               if (oldWrap.partRef.Id == null && (existingPartRef.Campaign__c == null || existingPartRef.Campaign__r.Partner_Referral_Source__c == null)) {
                  partRefsToInsert.add(oldWrap.partRef);
               }
               // TODO - notify owner that the record came in again.
               if (existingPartRef.Referral__c != null && String.isNotBlank(EXISTING_LEAD_MSG) && EXISTING_LEAD_MSG != 'NoMsg') {
                  Referral__c updateRef = new Referral__c(Id=existingPartRef.Referral__c, NotifyOwner__c=true, NotifyOwnerMsg__c=EXISTING_LEAD_MSG, ReferralNotes__c=existingPartRef.Referral__r.ReferralNotes__c);
                  StringHelper.addToProcessNotes(updateRef,'New notification of a weblead coming in: '+EXISTING_LEAD_MSG);
                  updateRefMap.put(updateRef.Id, updateRef);
               }
            }
         } // for (PartnerReferral__c partRef
         
         if (!notWorkableRefs.isEmpty()) {
            checkAmpWorkable(notWorkableRefs);
            //checkOasisWorkable(notWorkableRefs);
         }
         
         DmlHelper.performDML2(updateRefMap.values(), DmlHelper.DML_UPDATE, 'TrackRecordEntry', 'checkForExisting', 'Resend the chatter message', false);
      } // if (!wrapperByIdMap.isEmpty
      
      System.debug('checkForExisting end partRefsToInsert='+partRefsToInsert.size());
   } // checkForExisting

    // setup the referral records, including ownership   
    public static void setupReferrals() {
        if (wrapperByIdMap.isEmpty()) {
            return;
        }
        for (PartRefWrapper oldWrap : wrapperByIdMap.values()) {
            oldWrap.ref = new Referral__c(Name=oldWrap.getName());
            oldWrap.ref.Account__c = oldWrap.partRef.Account__c;
            oldWrap.ref.NbrOfEmployees__c = oldWrap.partRef.NumberOfEmployees__c;
            oldWrap.ref.Campaign__c = oldWrap.partRef.Campaign__c;
            oldWrap.ref.SourceContact__c = oldWrap.partRef.Contact__c;
            oldWrap.ref.SourceLead__c = oldWrap.partRef.Lead__c;
            oldWrap.ref.ReferralEntry__c = oldWrap.partRef.Source__c;
            oldWrap.ref.SellingLeadSource__c = oldWrap.partRef.LeadSource__c; // TODO - get from campaign
            // for a fringe case where we'd have the opportunity at referral creation
            if (oldWrap.oppToUseForRef != null) {
                oldWrap.ref.Selling_Opportunity__c = oldWrap.oppToUseForRef.Id;
            }
            //adding Amplifinity data to Payx referral record
            String key='Default-'+oldWrap.llc.Name;
            LeadRouting__c leadRouting = LeadRouting__c.getInstance(key);
            oldWrap.ref.Amplifinity_Referral__c = oldWrap.partRef.Amplifinity_Referral__c;
            if (oldWrap.ref.Amplifinity_Referral__c != null) {
                oldWrap.ref.CreatedByProcess__c = 'Amplifinity';
                oldWrap.ref.NotifyOwnerMsg__c = 'A new referral from ' + oldWrap.ampAdvocate.amp_dev__Company_Name__c + ' has come in. ';
                Referral_Partner__c refPartner = findReferralPartner(REF_PART_NETWORK); 
                if (refPartner != null) {
                    oldWrap.ref.Referral_Partner__c = refPartner.Id; 
                } // if (refPartner != null            
                if (oldWrap.ampReferral != null && String.isNotBlank(oldWrap.ampReferral.amp_dev__Status__c)) {
                    // set the initial AR Status based on the status of the amplifinity referral
                    oldWrap.ref.AMP_Status__c=oldWrap.ampReferral.amp_dev__Status__c;
                    AmplifinityHelper.checkAmpMaps();
                    String arStatus = AmplifinityHelper.arByAmpStatusMap.get(oldWrap.ampReferral.amp_dev__Status__c);
                    if (arStatus != null) {
                        oldWrap.ref.AR_Status__c=arStatus;
                    }
                } // if (oldWrap.ampReferral
                if (oldWrap.ampAdvocate != null) {
                    Id newOwnerId = null;
                    oldWrap.ref.Referring_User__c = oldWrap.ampAdvocate.OwnerId;
                    Date termStart = (oldWrap.ampAdvocate.amp_dev__Enrollment_Date__c != null ? oldWrap.ampAdvocate.amp_dev__Enrollment_Date__c.date() : Date.today());
                    // so if the start date is 1/1/2019, the end date will be 12/31/2019 instead of 1/1/2020
                    Date termEnd = termStart.addYears(1).addDays(-1);
                    while (Date.today() > termEnd) {
                        termStart = termStart.addYears(1);
                        termEnd = termStart.addYears(1).addDays(-1);
                    }
                    oldWrap.ref.Term_Start_Date__c = termStart;
                    oldWrap.ref.Term_End_Date__c = termEnd;
                    if (oldWrap.workable && newOwnerId != null) {
                        oldWrap.setRouting(newOwnerId, leadRouting);
                        oldWrap.ref.SetOwnerHoldout__c=true;
                    }
                } // if (ampAdvocate != null
            } // if (oldWrap.ref.Amplifinity_Referral__c != null
            StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry setupReferrals created referral');
            if (oldWrap.llc != null) {
                oldWrap.ref.NotifyOwner__c = oldWrap.llc.NotifyOwner__c;
            }
            if (oldWrap.partRef.Id == null) {
                partRefsToInsert.add(oldWrap.partRef);
            }
        } // for (PartRefWrapper oldWrap
    } // setupReferrals
   
   public static final String AMP_PARTNER_TYPE='Amplifinity';
   public static final String REF_PART_NETWORK='Paychex Referral Network';
   // store in a static map in case we have to execute this multiple times in a transaction
   private static Map<String,Referral_Partner__c> refPartnerMap = null;

   public static Referral_Partner__c findReferralPartner(String partnerName) {
      if (refPartnerMap == null) {
         Referral_Partner__c[] refPartners = ReferralQueries.selectRefPartnersCache(AMP_PARTNER_TYPE, null);
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
      //if (refPartner == null) {
      //   refPartner = refPartnerMap.get(DEFAULT_REF_PARTNER);
      //}
      return refPartner;
   } // findReferralPartner
    
   public static void handleAmpRefOwnership() {
        if (wrappersByAmpOwnerIdMap.isEmpty()) {
            return;
        }
        String zipDestination = null;
        Map<String,PartRefWrapper[]> zipCheckMap = new Map<String,PartRefWrapper[]>();
        Map<String,PartRefWrapper[]> advocateOwnerIdsMap = new Map<String, PartRefWrapper[]>();
        Lead[] leads = [Select Id, OwnerId, PostalCode, NumberOfEmployees from Lead where Id in :wrappersByAmpOwnerIdMap.keySet()];
        Contact[] contacts = [Select Id, OwnerId, MailingPostalCode from Contact where Id in :wrappersByAmpOwnerIdMap.keySet()];
        if(!leads.isEmpty() && leads != null) {
            for(Lead ld: leads){ 
                PartRefWrapper[] wraps = wrappersByAmpOwnerIdMap.get(ld.Id);
                if (wraps != null) {
                    Id newOwnerId = null;
                    String destination = null;
                    LeadRouting__c leadRouting;
                    String key='Default-ReferralManagement';
                    leadRouting = LeadRouting__c.getInstance(key);
                    if (leadRouting != null) {
                        destination = (String.isNotBlank(LeadRouting.Destination__c) ? leadRouting.Destination__c : '');
                    } //if (leadRouting != null)
                    for (PartRefWrapper oldWrap : wraps) {
                        if (String.isNotBlank(oldWrap.partRef.ZipPostalCode__c) && oldWrap.partRef.ZipPostalCode__c.length() >= 5) {
                            addToMap(oldWrap, oldWrap.partRef.ZipPostalCode__c.left(5), zipCheckMap);
                            addToMap(oldWrap, oldWrap.ampAdvocate.OwnerId, advocateOwnerIdsMap);
                        } //if (String.isNotBlank(oldWrap.partRef.ZipPostalCode__c)
                        zipDestination = destination;
                    } //for (PartRefWrapper oldWrap : wraps)
                } //if (wraps != null)
            } //for(Lead ld: leads)
        } //if(!leads.isEmpty() && leads != null)
        if(!contacts.isEmpty() && contacts != null) {
            for(Contact ct: contacts){
                PartRefWrapper[] wraps = wrappersByAmpOwnerIdMap.get(ct.Id);
                if (wraps != null) {
                    Id newOwnerId = null;
                    String destination = null;
                    LeadRouting__c leadRouting;
                    String key='Default-ReferralManagement';
                    leadRouting = LeadRouting__c.getInstance(key);
                    if (leadRouting != null) {
                        destination = (String.isNotBlank(LeadRouting.Destination__c) ? leadRouting.Destination__c : '');
                    } //if (leadRouting != null)
                    for (PartRefWrapper oldWrap : wraps) {
                        if (String.isNotBlank(oldWrap.partRef.ZipPostalCode__c) && oldWrap.partRef.ZipPostalCode__c.length() >= 5) {
                            addToMap(oldWrap, oldWrap.partRef.ZipPostalCode__c.left(5), zipCheckMap);
                            addToMap(oldWrap, oldWrap.ampAdvocate.OwnerId, advocateOwnerIdsMap);
                        } //if (String.isNotBlank(oldWrap.partRef.ZipPostalCode__c)
                        zipDestination = destination;
                    } //for (PartRefWrapper oldWrap : wraps)
                } //if (wraps != null)
            } //for(Contact ct: contacts)
        } //if(!contacts.isEmpty() && contacts != null)
        if (!zipCheckMap.isEmpty() && !advocateOwnerIdsMap.isEmpty() && zipDestination != null) {
            handleAmpOwnerZips(zipCheckMap, advocateOwnerIdsMap, zipDestination);
        } //if (!zipCheckMap.isEmpty()
    } //handleAmpRefOwnership
    
    public static void handleAmpOwnerZips(Map<String,PartRefWrapper[]> zipCheckMap, Map<String,PartRefWrapper[]> advocateOwnerIdsMap, String destination) {
        Set<Id> advsOwnerIds = new Set<Id>();
        List<amp_dev__Amp_Advocate__c> advs = new List<amp_dev__Amp_Advocate__c>();
        List<Id> userIds = new List<Id>();
        List<Id> profileIds = new List<Id>(); 
        ZipWrapper zipWrap = null;
        ZipWrapper zipWrapSmb = null;
        Amp_Lead_Routing__mdt[] ampLeadRouting = [Select MasterLabel, Label, District_Name__c, District_Name_Two__c, Number_Of_Employees_Max__c, Number_Of_Employees_Min__c, Tier__c, Zone__c from Amp_Lead_Routing__mdt];
        Map<String,String> districtNames = new Map<String, String>();
        Map<String,String> tiers = new Map<String,String>();
        Map<String,String> zones = new Map<String,String>();
        Map<String,String> otherDistricts = new Map<String,String>();
        Map<String,Decimal> numEmpMin = new Map<String,Decimal>();
        Map<String,Decimal> numEmpMax = new Map<String,Decimal>();
        
        for(Amp_Lead_Routing__mdt record:ampLeadRouting) {
            districtNames.put(record.label,record.District_Name__c);
            tiers.put(record.label,record.Tier__c);
            zones.put(record.label,record.Zone__c);
            otherDistricts.put(record.label,record.District_Name_Two__c);
            numEmpMin.put(record.label,record.Number_Of_Employees_Min__c);
            numEmpMax.put(record.label,record.Number_Of_Employees_Max__c);
        } //for(Amp_Lead_Routing__mdt record:ampLeadRouting)
        
        Zip_Assignment__c[] zipList=[SELECT Id,Name
                                     ,User__c,User__r.Name, User__r.SMB_Certified__c, Zip_Segment__c, Segment_Name__c, Sales_Org__c, Zip_Segment__r.Name 
                                     FROM Zip_Assignment__c 
                                     WHERE Name in :zipCheckMap.keySet()];
        
        for(Id advId: advocateOwnerIdsMap.keySet()) {
            advsOwnerIds.add(advId);
        } //for(Id advId: advocateOwnerIdsMap.keySet())
        advs = [Select Id, OwnerId from amp_dev__Amp_Advocate__c where OwnerId in :advsOwnerIds];
        if(!advs.isEmpty() && advs != null) {
            for(amp_dev__Amp_Advocate__c adv: advs) {
                userIds.add(adv.OwnerId);
            } //for(amp_dev__Amp_Advocate__c adv: advs)
            if(userIds.size()>0) {
                Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, ProfileId, Sales_Division__c, Zonetxt__c, Division_Level__c, District_Name__c FROM User WHERE Id IN :userIds]);
                for(User u : userMap.values())
                {
                    if(!profileIds.contains(u.ProfileId))
                    {
                        profileIds.Add(u.ProfileId);
                    }
                } //for(User u : userMap.values())
                Map<Id, Profile> profileMap = new Map<Id, Profile>([SELECT Id, Name FROM Profile WHERE Id IN :profileIds]);
                for (Zip_Assignment__c zas : zipList) {
                    PartRefWrapper[] wrappers = zipCheckMap.remove(zas.Name);
                    if (wrappers != null) {
                        for (PartRefWrapper oldWrap : wrappers) {
                            User ampUser = userMap.get(oldWrap.ampAdvocate.OwnerId);
                            if(ampUser != null && ampUser.ProfileId != null) {
                                Profile ampUserProfile = profileMap.get(ampUser.ProfileId);
                                id newOwnerId = null;
                                if(oldWrap.ld.OwnerId != null) {
                                    newOwnerId = oldWrap.ld.OwnerId;
                                } //if(oldWrap.ld.OwnerId != null)
                                if(oldWrap.ctct.OwnerId != null) {
                                    newOwnerId = oldWrap.ctct.OwnerId;
                                } //if(oldWrap.ctct.OwnerId != null)
                                //unknown emp count
                                if(oldWrap.partRef.NumberOfEmployees__c == null && (!(AmplifinityHelper.mmsProfiles.contains(ampUserProfile.Name)) && !(AmplifinityHelper.coreProfiles.contains(ampUserProfile.Name)) || ampUser.Zonetxt__c.contains(zones.get('Unknown Emp Count')))) {
                                    if(oldWrap.ld != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_CORE, oldWrap.ld, tiers.get('Unknown Emp Count'));
                                         if(zipWrap != null){
                                        newOwnerId = zipWrap.usr.Id; 
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips unknown employee count setting Owner to SMB Channel Rep newOwnerId: ' + newOwnerId);
                                         }
                                    } //if(oldWrap.ld != null)
                                    if(oldWrap.ctct != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_CORE, null, tiers.get('Unknown Emp Count'));
                                        if(zipWrap != null){
                                        newOwnerId = zipWrap.usr.Id;
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips unknown employee count setting Owner to SMB Channel Rep newOwnerId: ' + newOwnerId);  
                                        }
                                    } //if(oldWrap.ctct != null)
                                } else if(((AmplifinityHelper.coreProfiles.contains(ampUserProfile.Name)) || AmplifinityHelper.mmsProfiles.contains(ampUserProfile.Name)) && (!ampUser.Zonetxt__c.contains(zones.get('Unknown Emp Count'))) && oldWrap.partRef.NumberOfEmployees__c == null) {
                                    newOwnerId = oldWrap.ampAdvocate.OwnerId;
                                    StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips unknown employee count setting Owner to Advocate Owner: ' + newOwnerId);
                                } //if(oldWrap.partRef.NumberOfEmployees__c == null
                                
                                //0-19 emp count
                                if(oldWrap.partRef.NumberOfEmployees__c != null && (oldWrap.partRef.NumberOfEmployees__c >= numEmpMin.get('ZeroToNineteenEmpCount') && oldWrap.partRef.NumberOfEmployees__c <= numEmpMax.get('ZeroToNineteenEmpCount')) && !(AmplifinityHelper.coreProfiles.contains(ampUserProfile.Name))) {
                                    if(oldWrap.ld != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_CORE, oldWrap.ld, tiers.get('ZeroToNineteenEmpCount'));
                                        if(zipWrap != null){
                                        newOwnerId = zipWrap.usr.Id;
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips EmployeeCount 0-19 EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to SMB Channel Rep newOwnerId: ' + newOwnerId);
                                        }
                                    } //if(oldWrap.ld != null)
                                    if(oldWrap.ctct != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_CORE, null, tiers.get('ZeroToNineteenEmpCount'));
                                        if(zipWrap != null){
                                        newOwnerId = zipWrap.usr.Id;
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips EmployeeCount 0-19 EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to SMB Channel Rep newOwnerId: ' + newOwnerId); 
                                        }
                                    } //if(oldWrap.ctct != null)
                                } else if(oldWrap.partRef.NumberOfEmployees__c != null && (oldWrap.partRef.NumberOfEmployees__c >= numEmpMin.get('ZeroToNineteenEmpCount') && oldWrap.partRef.NumberOfEmployees__c <= numEmpMax.get('ZeroToNineteenEmpCount')) && (AmplifinityHelper.coreProfiles.contains(ampUserProfile.Name))) {
                                    newOwnerId = oldWrap.ampAdvocate.OwnerId;
                                    StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips EmployeeCount 0-19 EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to Advocate Owner newOwnerId: ' + newOwnerId);
                                } //if(oldWrap.partRef.NumberOfEmployees__c != null
                                
                                //20-49 emp count
                                if(oldWrap.partRef.NumberOfEmployees__c != null && (oldWrap.partRef.NumberOfEmployees__c >= numEmpMin.get('TwentyToFortyNineEmpCount') && oldWrap.partRef.NumberOfEmployees__c <= numEmpMax.get('TwentyToFortyNineEmpCount')) && (!AmplifinityHelper.coreProfiles.contains(ampUserProfile.Name) && (!ampUser.District_Name__c.contains(districtNames.get('TwentyToFortyNineEmpCount')) && ampUser.District_Name__c != null) || ampUser.Zonetxt__c.contains(zones.get('TwentyToFortyNineEmpCount')))) {
                                    if(oldWrap.ld != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_MMS, oldWrap.ld, tiers.get('TwentyToFortyNineEmpCount'));
                                        if(zipWrap != null){
                                        newOwnerId = zipWrap.usr.Id;
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips employee count 20-49 EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to MMS Level 1 Rep newOwnerId: ' + newOwnerId);
                                        }
                                    } //if(oldWrap.ld != null)
                                    if(oldWrap.ctct != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_MMS, null, tiers.get('TwentyToFortyNineEmpCount'));
                                        if(zipWrap != null){
                                        newOwnerId = zipWrap.usr.Id;
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips: employee count 20-49 EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to MMS Level 1 Rep newOwnerId: ' + newOwnerId);   
                                        }
                                    } //if(oldWrap.ctct != null)
                                } else if(oldWrap.partRef.NumberOfEmployees__c != null && (oldWrap.partRef.NumberOfEmployees__c >= numEmpMin.get('TwentyToFortyNineEmpCount') && oldWrap.partRef.NumberOfEmployees__c <= numEmpMax.get('TwentyToFortyNineEmpCount')) && (AmplifinityHelper.coreProfiles.contains(ampUserProfile.Name) || ampUser.District_Name__c.contains(districtNames.get('TwentyToFortyNineEmpCount')))) {
                                    newOwnerId = oldWrap.ampAdvocate.OwnerId;
                                    StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips: employee count 20-49 EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to Advocate Owner newOwnerId: ' + newOwnerId);
                                } //if(oldWrap.partRef.NumberOfEmployees__c != null
                                
                                //50+ emp count SMB
                                if(oldWrap.partRef.NumberOfEmployees__c != null && oldWrap.partRef.NumberOfEmployees__c >= numEmpMin.get('FiftyPlusEmps') && AmplifinityHelper.coreProfiles.contains(ampUserProfile.Name)) {
                                    if(oldWrap.ld != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_MMS, oldWrap.ld, tiers.get('FiftyPlusEmps'));
                                        zipWrapSmb = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_CORE, oldWrap.ld, tiers.get('Unknown Emp Count'));
                                        if(zipWrapSmb!= null && zipWrapSmb.usr.Id != null && zipWrapSmb.usr.SMB_Certified__c != null) {
                                            newOwnerId = zipWrapSmb.usr.Id;
                                            StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips SMB employee count 50+ EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to SMB Channel Rep because SMB Certified newOwnerId: ' + newOwnerId);
                                        } else {  
                                            if(zipWrap != null){
                                            newOwnerId = zipWrap.usr.Id;
                                            StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips SMB employee count 50+ EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to MMS Level 2 Rep newOwnerId: ' + newOwnerId);
                                            }
                                        } //if(zipWrapSmb.usr.Id
                                    } // if(oldWrap.ld != null)
                                    if(oldWrap.ctct != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_MMS, null, tiers.get('FiftyPlusEmps'));
                                        zipWrapSmb = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_CORE, oldWrap.ld, tiers.get('Unknown Emp Count'));
                                        if(zipWrapSmb!= null && zipWrapSmb.usr.Id != null && zipWrapSmb.usr.SMB_Certified__c != null) {
                                            newOwnerId = zipWrapSmb.usr.Id;
                                            StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips SMB employee count 50+ EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to SMB Channel Rep because SMB Certified newOwnerId: ' + newOwnerId);
                                        } else {     
                                            if(zipWrap != null){
                                            newOwnerId = zipWrap.usr.Id;
                                            StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips SMB employee count 50+ EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to MMS Level 2 Rep newOwnerId: ' + newOwnerId);
                                            }
                                        } //if(zipWrapSmb.usr.Id != null
                                    } //if(oldWrap.ctct != null)
                                }
                                //50+ emp count P&C/401k
                                if(oldWrap.partRef.NumberOfEmployees__c != null && oldWrap.partRef.NumberOfEmployees__c >= numEmpMin.get('FiftyPlusEmps') && (!AmplifinityHelper.coreProfiles.contains(ampUserProfile.Name) && !AmplifinityHelper.mmsProfiles.contains(ampUserProfile.Name))) {
                                    if(oldWrap.ld != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_MMS, oldWrap.ld, tiers.get('FiftyPlusEmps'));
                                        if(zipWrap != null){
                                        newOwnerId = zipWrap.usr.Id;
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips 401k - P&C employee count 50+ EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to MMS Level 2 Rep newOwnerId: ' + newOwnerId);
                                        }
                                    } // if(oldWrap.ld != null)
                                    if(oldWrap.ctct != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_MMS, null, tiers.get('FiftyPlusEmps'));
                                        if(zipWrap != null){
                                        newOwnerId = zipWrap.usr.Id;
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips 401k - P&C employee count 50+ EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to MMS Level 2 Rep newOwnerId: ' + newOwnerId);
                                        }
                                    } //if(oldWrap.ctct != null)
                                }
                                //50+ emp count CSSR
                                if(oldWrap.partRef.NumberOfEmployees__c != null && oldWrap.partRef.NumberOfEmployees__c >= numEmpMin.get('FiftyPlusEmps') && (AmplifinityHelper.coreProfiles.contains(ampUserProfile.Name) || AmplifinityHelper.mmsProfiles.contains(ampUserProfile.Name)) && ampUser.Zonetxt__c.contains(zones.get('FiftyPlusEmps'))) {
                                    if(oldWrap.ld != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_MMS, oldWrap.ld, tiers.get('FiftyPlusEmps'));
                                        if(zipWrap != null){
                                        newOwnerId = zipWrap.usr.Id;
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips CSSR employee count 50+ EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to MMS Level 2 Rep newOwnerId: ' + newOwnerId);
                                        }
                                    } // if(oldWrap.ld != null)
                                    if(oldWrap.ctct != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_MMS, null, tiers.get('FiftyPlusEmps'));
                                       if(zipWrap != null){
                                        newOwnerId = zipWrap.usr.Id;
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips CSSR employee count 50+ EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to MMS Level 2 Rep newOwnerId: ' + newOwnerId);
                                       }
                                    } //if(oldWrap.ctct != null)
                                }
                                //50+ emp count MMS L1
                                if(oldWrap.partRef.NumberOfEmployees__c != null && oldWrap.partRef.NumberOfEmployees__c >= numEmpMin.get('FiftyPlusEmps') && AmplifinityHelper.mmsProfiles.contains(ampUserProfile.Name) && ampUser.District_Name__c.contains(districtNames.get('TwentyToFortyNineEmpCount'))) {
                                    if(oldWrap.ld != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_MMS, oldWrap.ld, tiers.get('FiftyPlusEmps'));
                                       if(zipWrap != null){
                                        newOwnerId = zipWrap.usr.Id;
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips MMS L1 employee count 50+ EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to MMS Level 2 Rep newOwnerId: ' + newOwnerId);
                                       }
                                    } // if(oldWrap.ld != null)
                                    if(oldWrap.ctct != null){
                                        zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_MMS, null, tiers.get('FiftyPlusEmps'));
                                        if(zipWrap != null){
                                        newOwnerId = zipWrap.usr.Id;
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips MMS L1 employee count 50+ EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to MMS Level 2 Rep newOwnerId: ' + newOwnerId);
                                        }
                                    } //if(oldWrap.ctct != null)
                                }
                                //50+ emp count MMS L2 & L3
                                if(oldWrap.partRef.NumberOfEmployees__c != null && oldWrap.partRef.NumberOfEmployees__c >= numEmpMin.get('FiftyPlusEmps') && AmplifinityHelper.mmsProfiles.contains(ampUserProfile.Name) && (ampUser.District_Name__c.contains(districtNames.get('FiftyPlusEmps')) || (ampUser.District_Name__c.contains(otherDistricts.get('FiftyPlusEmps'))))) {
                                    if(oldWrap.ld != null){
                                        //zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_MMS, oldWrap.ld, tiers.get('FiftyPlusEmps'));
                                        newOwnerId = oldWrap.ampAdvocate.OwnerId;
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips MMS L2-L3 employee count 50+ EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to Advocate OwnerId newOwnerId: ' + newOwnerId);
                                    } // if(oldWrap.ld != null)
                                    if(oldWrap.ctct != null){
                                        //zipWrap = ZipCodeLookupController.getZipAssignment(zas.Name, UserHelper.SO_MMS, null, tiers.get('FiftyPlusEmps'));
                                        newOwnerId = oldWrap.ampAdvocate.OwnerId;
                                        StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry handleAmpOwnerZips MMS L2-L3 employee count 50+ EmpCount=' + oldWrap.partRef.NumberOfEmployees__c + ' setting Owner to Advocate OwnerId newOwnerId: ' + newOwnerId);
                                    } //if(oldWrap.ctct != null)
                                }
                                if(newOwnerId != null && destination != null) {
                                    if(newOwnerId != oldWrap.ampAdvocate.OwnerId) {
                                        oldWrap.ref.NotifyOwnerMsg__c = null;
                                    }
                                    oldWrap.setRouting(newOwnerId, destination);
                                } //if(newOwnerId != null && destination != null)
                            } //if(ampUser != null && ampUser.ProfileId != null)
                        } //for (PartRefWrapper oldWrap : wrappers) 
                    } // if (wrappers != null
                } //for (Zip_Assignment__c zas : zipList)
            } //if(userIds.size()>0)
        } //if(!advs.isEmpty() && advs != null)
        
    } // handleAmpOwnerZips
    
  public static void handleCampaigns() {
      System.debug('handleCampaigns wrapperByIdMap='+wrapperByIdMap.size()+' wrappersByCampaignIdMap='+wrappersByCampaignIdMap.size());
      if (wrappersByCampaignIdMap.isEmpty()) {
         return;
      }
      
      // based on the campaign, check the zip codes and see if they're owned by virtual sales
      Map<String,PartRefWrapper[]> zipCheckMap = new Map<String,PartRefWrapper[]>();
      // lead updates that need to go through LeadMethods.checkOwnedBy
      Set<Id> checkOwnedByIdSet = new Set<Id>();
      Id zipQueueId = null;
      Id zipDestination = null;
      
      Campaign[] camps = [Select Id, Name, LeadSource__c, Send_To_Virtual__c, Source_Type__c from Campaign where Id in :wrappersByCampaignIdMap.keySet()];
      for (Campaign camp : camps) {
         PartRefWrapper[] wraps = wrappersByCampaignIdMap.get(camp.Id);
         if (wraps != null) {
            Id newOwnerId = null;
            Boolean addToZipCheck = false;
            Boolean addToOtherZipCheck = false;
            Boolean alwaysUse = false;
            String destination = null;
            LeadRouting__c leadRouting;
            
            String key='SendToVirtual-'+camp.Send_To_Virtual__c;
            if (String.isNotBlank(camp.Send_To_Virtual__c)) {
               leadRouting = LeadRouting__c.getInstance(key);               
               if (leadRouting != null) {
                  newOwnerId = leadRouting.QueueId__c;
                  alwaysUse = newOwnerId != null && leadRouting.AlwaysUse__c;
                  addToZipCheck = newOwnerId != null && leadRouting.CheckForVirtualZips__c;  
                  addToOtherZipCheck = leadRouting.CheckForOtherZips__c;        // && newOwnerId != null    PEO Centric
                  destination = (String.isNotBlank(LeadRouting.Destination__c) ? leadRouting.Destination__c : leadRouting.Name);
               }
            } // if (String.isNotBlank
            
            for (PartRefWrapper oldWrap : wraps) {
               // set the lead source on the partner referral - overwrite whatever is there.
               if (String.IsNotBlank(camp.LeadSource__c) && oldWrap.partRef != null) {
                  StringHelper.addToProcessNotes(oldWrap.partRef,'handleCampaigns setting Lead Source from Campaign: '+camp.LeadSource__c);
                  oldWrap.partRef.LeadSource__c = camp.LeadSource__c;
               }
               if(oldWrap.partRef != null && camp.Source_Type__c!= null){
                  oldWrap.partRef.Source__c = camp.Source_Type__c;
               }
               
               //APR0112504: Changing to look at campaign spource type instead of looking at campiagn name and populating Chat as Source
              // if (String.IsNotBlank(camp.Name) && oldWrap.partRef != null && camp.Name.contains(Label.TrackRecord_Drift)) 
             /*  if(oldWrap.partRef != null){
                   StringHelper.addToProcessNotes(oldWrap.partRef,'TrackRecordEntry: handleCampaigns setting Source to Chat because originated from Drift');
                   //setting Source to 'Chat'
                   oldWrap.partRef.Source__c = camp.Source_Type__c;
                   String driftKey='Drift-Chat';
                   leadRouting = LeadRouting__c.getInstance(driftKey);               
                   if (leadRouting != null) {
                       newOwnerId = leadRouting.QueueId__c;
                       destination = (String.isNotBlank(LeadRouting.Destination__c) ? leadRouting.Destination__c : leadRouting.Name);
                       oldWrap.setRouting((Id)leadRouting.QueueId__c, leadRouting);
                       StringHelper.addToProcessNotes(oldWrap.ref,'TrackRecordEntry: handleCampaigns setting newOwnerId to Drift-Chat Queue: ' + newOwnerId);
                   }
               } */
               // always set the selling lead source from the campaign on the referral record.
               if (String.IsNotBlank(camp.LeadSource__c) && oldWrap.ref != null) {
                  oldWrap.ref.SellingLeadSource__c = camp.LeadSource__c;
               }
              
               if (!oldWrap.routingHandled) {       // && newOwnerId != null)  PEO Centric
                  if (addToOtherZipCheck) {
                        checkOwnedByIdSet.add(oldWrap.ld.Id); 
                  }
                  if (newOwnerId != null) {
                      if (alwaysUse) {                  
                         if (leadRouting != null && leadRouting.UseAsFilter__c) {
                             Integer nbrEmps = (oldWrap.partRef.NumberOfEmployees__c != null ? Integer.valueOf(oldWrap.partRef.NumberOfEmployees__c) : null);
                             if (nbrEmps != null) {
                                if (leadRouting.EmpsMin__c <= nbrEmps && nbrEmps <= leadRouting.EmpsMax__c) {
                                   oldWrap.setRouting((Id)leadRouting.QueueId__c, leadRouting);
                                }
                             }
                         } // if (leadRouting != null 
                         else {
                            oldWrap.setRouting(newOwnerId, destination);
                         }
                      } // if (alwaysUse)
                      else if (addToZipCheck) {                 
                         if (zipQueueId == null) {
                            zipQueueId = newOwnerId;
                            zipDestination = destination;
                         }
                         if (String.isNotBlank(oldWrap.partRef.ZipPostalCode__c) && oldWrap.partRef.ZipPostalCode__c.length() >= 5) {
                            addToMap(oldWrap, oldWrap.partRef.ZipPostalCode__c.left(5), zipCheckMap);
                         }
                      } // else if (addToZipCheck)
                  } // if (newOwnerId != null)
               } // if (!oldWrap.routingHandled) 
            } // for (PartRefWrapper wrap
         } // if (wraps != null
      } // for (Campaign camp : camps
      
      System.debug('handleCampaigns zipCheckMap='+zipCheckMap.size()+' checkOwnedByIdSet='+checkOwnedByIdSet.size());
      if (!zipCheckMap.isEmpty()) {
         handleVirtualZips(zipCheckMap,zipQueueId, zipDestination);
      }
      if (!checkOwnedByIdSet.isEmpty()) {
          System.debug('TrackRecordEntry calling LeadMethods.checkOwnedBy size='+checkOwnedByIdSet.size());
         LeadMethods.checkOwnedBy(checkOwnedByIdSet);
      }
   } // handleCampaigns
   
   public static void handleVirtualZips(Map<String,PartRefWrapper[]> zipCheckMap, Id zipQueueId, String destination) {
      System.debug('handleVirtualZips zipCheckMap='+zipCheckMap.size());
      String[] coreSegments = new String[]{ZipQueries.SEGMENT_DEFAULT, 'TIER2'};
      Zip_Assignment__c[] zipList=[SELECT Id,Name
                                         ,User__c,User__r.Name,User__r.UserRole.Name,User__r.NSS_Team__c 
                                     FROM Zip_Assignment__c 
                                    WHERE Name in :zipCheckMap.keySet() 
                                      AND Sales_Org__c=:UserHelper.SO_CORE 
                                      AND Segment_Name__c in :coreSegments
                                      AND (( User__r.UserRole.Name like '%Virtual%' 
                                             AND User__r.NSS_Team__c = :Label.NSS_Team_VS_PAY) 
                                          or (User__r.Name = 'Virtual Sales'))];
      for (Zip_Assignment__c za : zipList) {
         PartRefWrapper[] wrappers = zipCheckMap.remove(za.Name);
         Id newOwnerId = (za.User__r.Name == 'Virtual Sales' ? zipQueueId : za.User__c);
         if (wrappers != null && newOwnerId != null) {
            for (PartRefWrapper oldWrap : wrappers) {
               if (!oldWrap.routingHandled) {
                  oldWrap.setRouting(newOwnerId, destination);
               }
            } // 
         } // if (wrappers != null
      } // for (Zip_Assignment__c za
      
   } // handleVirtualZips
   
   
   public static PartRefWrapper[] checkLeadFilters() {
      PartRefWrapper[] notProcessedWrappers = new PartRefWrapper[]{};
      setupFilters();
      for (PartRefWrapper oldWrap : wrapperByIdMap.values()) {
         Integer nbrEmps = (oldWrap.partRef.NumberOfEmployees__c != null ? Integer.valueOf(oldWrap.partRef.NumberOfEmployees__c) : null);
         if (!oldWrap.routingHandled && nbrEmps != null && nbrEmps <= maxEmpCnt) {
            for (LeadRouting__c leadRouting : routings) {
               if (leadRouting.EmpsMin__c <= nbrEmps && nbrEmps <= leadRouting.EmpsMax__c) {
                  oldWrap.setRouting((Id)leadRouting.QueueId__c, leadRouting);
                  break;
               }
            } // for (LeadRouting__c leadRouting
         }
         if (!oldWrap.routingHandled) {
            notProcessedWrappers.add(oldWrap);
         }
      } // for (PartRefWrapper oldWrap
      return notProcessedWrappers;
   } // checkLeadFilters
   
   public static Integer maxEmpCnt = null;
   public static LeadRouting__c[] routings = null;
   
   public static void setupFilters() {
      maxEmpCnt = 0;
      routings = new LeadRouting__c[]{};
      for (LeadRouting__c leadRouting : LeadRouting__c.getAll().values()) {
         if (leadRouting.UseAsFilter__c && !leadRouting.CampaignOnly__c && leadRouting.EmpsMin__c != null && leadRouting.EmpsMax__c != null) {
            routings.add(leadRouting);
            if (leadRouting.EmpsMax__c > maxEmpCnt) {
               maxEmpCnt = Integer.valueOf(leadRouting.EmpsMax__c);
            }
         } // if (leadRouting.UseAsFilter__c &&
      } // for (LeadRouting__c leadRouting
      System.debug('setupFilters routings='+routings.size());
   } // setupFilters
   
   public static void setDefaultOwnership(PartRefWrapper[] wrappers) {
      for (PartRefWrapper oldWrap : wrappers) {
         if (!oldWrap.routingHandled) {
            String key='Default-'+oldWrap.llc.Name;
            // APR0135240: Routing by EE segment for WEBLEAD.
            //List<LeadRouting__c> leadRouting = LeadRouting__c.getInstance(key);
            Integer nbrEmps = (oldWrap.partRef.NumberOfEmployees__c != null ? Integer.valueOf(oldWrap.partRef.NumberOfEmployees__c) : 0); 
            for(LeadRouting__c leadRouting : LeadRouting__c.getall().values()){
              if(leadRouting.Source__c == key){
                  if(leadRouting.EmpsMin__c!=null && nbrEmps != null && nbrEmps >= leadRouting.EmpsMin__c && nbrEmps <= leadRouting.EmpsMax__c){
                      StringHelper.addToProcessNotes(oldWrap.partRef, 'setDefaultOwnership key='+key+', leadRouting='+(leadRouting != null ? leadRouting.Name : 'NotFound'));
                      oldWrap.setRouting((Id)leadRouting.QueueId__c, leadRouting);
                      break;
                  }
                  else{
                     StringHelper.addToProcessNotes(oldWrap.partRef, 'setDefaultOwnership key='+key+', leadRouting='+(leadRouting != null ? leadRouting.Name : 'NotFound'));
                     oldWrap.setRouting((Id)leadRouting.QueueId__c, leadRouting);
                  }
              }
            }
         } // if (!oldWrap.routingHandled
      } // for (PartRefWrapper oldWrap
   } // setDefaultOwnership

   public static Boolean checkWorkable() {
      Boolean okay=true;
      Map<Id,PartRefWrapper> leadCheckMap = new Map<Id,PartRefWrapper>();
      // PartRefWrapper is a list in case multiple contacts from one account
      Map<Id,PartRefWrapper[]> acctCheckMap = new Map<Id,PartRefWrapper[]>();
      String chkLog = 'wrapperByIdMap='+wrapperByIdMap.size();
      
      Boolean isAmplifinity = false;
      for (PartRefWrapper wrap : wrapperByIdMap.values()) {
         
         chkLog += ' checkWorkable='+wrap.checkWorkable;
         if (wrap.checkWorkable) {
            isAmplifinity = (isAmplifinity || wrap.isAmplifinity);
            if (wrap.ctct != null && wrap.ctct.AccountId != null) {
               chkLog += '; has AccountId';
               PartRefWrapper[] wraps = (acctCheckMap.containsKey(wrap.ctct.AccountId) ? acctCheckMap.get(wrap.ctct.AccountId) : new PartRefWrapper[]{});
               wraps.add(wrap);
               acctCheckMap.put(wrap.ctct.AccountId,wraps);
            } else if (wrap.ld != null) {
               chkLog += '; has lead Id';
               leadCheckMap.put(wrap.ld.Id, wrap);
            }
         }
      } // for (PartRefWrapper wrap
      
      chkLog += '; leadCheckMap='+leadCheckMap.size()+' acctCheckMap='+acctCheckMap.size();
      ErrorLog.addToDescription(v_runLog, chkLog);
      
      if (!leadCheckMap.isEmpty()) {
         checkLeadWorkable(leadCheckMap,v_runLog);
      }
      if (!acctCheckMap.isEmpty()) {
         checkAcctCtctWorkable(acctCheckMap, v_runLog);
      }
      if (isAmplifinity) {
         checkAmpWorkable(wrapperByIdMap.values());
      }
      //checkOasisWorkable(wrapperByIdMap.values());
      return okay;
   } // checkWorkable
   /*
   public static OasisSyncQueueable oasisSync = null;
   
   public static void checkOasisWorkable(PartRefWrapper[] partRefToCheck) {
      oasisSync = null;
      String thisLog = 'checkOasisWorkable partRefToCheck='+partRefToCheck.size();
      for (PartRefWrapper wrap : partRefToCheck) {
         if (wrap.isOasis && wrap.partRef.Lead__c != null) {
            thisLog += '; adding id '+wrap.partRef.Lead__c;
            if (oasisSync == null) {
               oasisSync = new OasisSyncQueueable();
            }
            oasisSync.addIdToProcess(wrap.partRef.Lead__c, OasisSyncHelper.SYNC_DUPE_RESULT);
         }

      } // for (PartRefWrapper wrap

      thisLog += ' oasisSync exists='+(oasisSync != null);
      ErrorLog.addToDescription(v_runLog,thisLog);
   } // checkOasisWorkable
   */
   public static Boolean ONLY_AMP_API_ELIGIBILITY=(Label.TrackRecord_CheckAmpEligibility == 'Y');
   
   public static void checkAmpWorkable(PartRefWrapper[] partRefToCheck) {
      amp_dev__Amp_Referral__c[] notWorkableRefs = new amp_dev__Amp_Referral__c[]{};
      // if the record is set to not workable, and then there could be an opportunity.
      PartRefWrapper[] notWorkableWraps = new PartRefWrapper[]{};
      Map<Id,PartRefWrapper[]> searchForOppMap = new Map<Id,PartRefWrapper[]>();
      
      UserHelper.setRunningUserAttributes();
      Boolean userIsAmpApi = UserHelper.runningUserIsAmplifinity;
      for (PartRefWrapper wrap : partRefToCheck) {
         System.debug('checkAmpWorkable has ampReferral='+(wrap.ampReferral != null)+' Workable='+wrap.partRef.Workable__c);
         if (wrap.ampReferral != null && wrap.isAmplifinity && wrap.partRef.Workable__c == NOT_WORKABLE) {
            notWorkableRefs.add(wrap.ampReferral);
            if (wrap.partRef.Account__c != null && wrap.partRef.DuplicateNotWorkableReason__c.contains('Has Open Opportunities')) {
               PartRefWrapper[] searchWraps = (searchForOppMap.containsKey(wrap.partRef.Account__c) ? searchForOppMap.get(wrap.partRef.Account__c) : new PartRefWrapper[]{});
               searchWraps.add(wrap);
               searchForOppMap.put(wrap.partRef.Account__c,searchWraps);
            }
         } // if (wrap.ampReferral
      } // for (PartRefWrapper wrap : wrapperByIdMap
      String thisLog = 'checkAmpWorkable partRefToCheck='+partRefToCheck.size()+' userIsAmpApi='+userIsAmpApi+' notWorkableRefs='+notWorkableRefs.size();
      
      Boolean checkEligibility = (!ONLY_AMP_API_ELIGIBILITY || (ONLY_AMP_API_ELIGIBILITY && userIsAmpApi));
      if (checkEligibility && !notWorkableRefs.isEmpty()) {
         AmplifinityHelper.checkAmpMaps();
         //Map<String,Amplifinity_AR_Status_Mapping__mdt> statusMap = AmplifinityHelper.statusMap; //get meta data 
         String ineligible = null;
         for (Amplifinity_AR_Status_Mapping__mdt statusMdt : AmplifinityHelper.statusMap.values()) {
            if (statusMdt.Label == 'Ineligible') {
               ineligible = statusMdt.AMP_Status__c;
               break;
            }
         } // for (Amplifinity_AR_Status_Mapping__mdt statusMdt
         if (String.isNotBlank(ineligible)) {
            for (amp_dev__Amp_Referral__c ampRef : notWorkableRefs) {
               ampRef.amp_dev__Status__c = ineligible;
               ampRef.Open_Close_Status__c = 'Closed';
            }
            // save the ineligible status to the referrals
            DmlHelper.performDML2(notWorkableRefs, DmlHelper.DML_UPDATE, 'TrackRecordEntry', 'checkAmpWorkable', 'Update Amplifinity Referrals to ineligible', true);
         } // if (String.isNotBlank(ineligible
         thisLog += '; ineligible='+ineligible;
      } // if (!notWorkableRefs.isEmpty
      
      if (!userIsAmpApi && !searchForOppMap.isEmpty()) {
         // check for existing opportunities to link
         checkForMatchingOpps(searchForOppMap);
      }
      System.debug(thisLog);
      ErrorLog.addToDescription(v_runLog,thisLog);
   } // checkAmpWorkable

   public static Integer hoursForOppCheck=Integer.valueOf(Label.TrackRecord_HoursForOppChk);   
   
   public static void checkForMatchingOpps(Map<Id,PartRefWrapper[]> searchForOppMap) {
      // This is a fringe case where the user did an amplifinity "verbal referral" which means then process is running as them.
      // We are looking to see if there is a recent payroll opportunity created by them and we will set that on the referral.
      // only perform the check if hours > 0
      if (hoursForOppCheck > 0) {
         Datetime checkDateTime = Datetime.now().addHours(-hoursForOppCheck);
         Opportunity[] opps = [Select Id,Name,AccountId
                                     ,OpportunityType__c
                                     ,ReferralLookup__c
                                 From Opportunity
                                Where IsClosed=false
                                  and CreatedDate > :checkDateTime
                                  and OwnerId=:UserInfo.getUserId()
                                  and OpportunityType__c=:OpptyMethods.OPP_TYPE_PAY
                                  and ReferralLookup__c = null    // we don't want to use an opportunity if already linked to another referral?
                                  and AccountId in :searchForOppMap.keySet()
                                 order by CreatedDate desc];
         for (Opportunity opp : opps) {
            PartRefWrapper[] wraps = searchForOppMap.remove(opp.AccountId);
            if (wraps != null && !wraps.isEmpty()) {
               wraps[0].oppToUseForRef = opp;
            }
         } // for (Opportunity opp : opps
      } // if (hoursForOppCheck > 0
   } // checkForMatchingOpps

   public static final String NOT_WORKABLE='Not Workable';
   public static final String WORKABLE='Workable';

   // check if a lead is workable
   public static Boolean checkLeadWorkable(Map<Id,PartRefWrapper> leadCheckMap, ErrorLog__c log) {
      Boolean okay = true;
      Date activityDate = Date.today().addDays(-30);
      
      Map<Id,Lead> leadMap = new Map<Id,Lead>([Select Id, OwnerId, LastName
                                                     ,Hold_Out__c, Hold_Out_Expiration__c
                                                     ,Hold_Out_Reason__c
                                                     ,(Select Id, OwnerId, WhoId, ActivityDate, IsClosed 
                                                         from Tasks
                                                        Where ActivityDate >= :activityDate order by ActivityDate desc limit 5)
                                                     ,(Select Id, OwnerId, WhoId, ActivityDate
                                                         from Events
                                                        Where ActivityDate >= :activityDate order by ActivityDate desc limit 5)
                                                 from Lead
                                                Where Id in :leadCheckMap.keySet()]);
      for (PartRefWrapper wrap : leadCheckMap.values()) {
         Lead ld = leadMap.get(wrap.ld.Id);
         String ldLog = ''; 
         if (ld != null) {
            wrap.partRef.DuplicateNotWorkableReason__c = null;
            // check open activities
            //Task[] tasks = [Select Id, ActivityDate, IsClosed from Task where WhoId=:wrap.ld.Id and ActivityDate >= :activityDate order by ActivityDate limit 5];
            Boolean activityFound = (!ld.tasks.isEmpty());
            
            ldLog = 'checkLeadWorkable ld='+ld.LastName+' activityFound='+activityFound+' hold out='+(ld.Hold_Out__c);
            if (ld.Hold_Out__c) {
               wrap.partRef.DuplicateNotWorkableReason__c = 'Existing Hold Out Found';
               wrap.partRef.OwnerIdNotWorkable__c = ld.OwnerId;
            }
            if (!activityFound) {
               //Event[] events = [Select Id, ActivityDate from Event where WhoId=:wrap.ld.Id and ActivityDate >= :activityDate order by ActivityDate limit 5];
               activityFound = (!ld.events.isEmpty());
               ldLog += '; event check activityFound='+activityFound;
               //ErrorLog.addToDescription(log,'events='+events.size());
               if (activityFound) {
                  wrap.partRef.DuplicateNotWorkableReason__c = 'Open Events found';
                  wrap.partRef.OwnerIdNotWorkable__c = ld.events[0].OwnerId;
               }
            } else {
               wrap.partRef.DuplicateNotWorkableReason__c = 'Open Tasks found';
               wrap.partRef.OwnerIdNotWorkable__c = ld.tasks[0].OwnerId;
            }
            wrap.partRef.Workable__c = ((!activityFound && !ld.Hold_Out__c) ? WORKABLE : NOT_WORKABLE);
            System.debug('checkLeadWorkable activityFound='+activityFound+' Workable__c='+wrap.partRef.Workable__c+' DuplicateNotWorkableReason__c='+wrap.partRef.DuplicateNotWorkableReason__c);
            ldLog += '; Workable__c='+wrap.partRef.Workable__c+' NotWorkableReason='+wrap.partRef.DuplicateNotWorkableReason__c;
         } else {
            ldLog += 'Lead was not found for id='+wrap.ld.Id;
         } // if (ld != null
         ErrorLog.addToDescription(log,ldLog);
      } // for (PartRefWrapper wrap : leadCheckMap.values
      return okay;
   } // checkLeadWorkable
   
/*
o  If the incoming Oasis Lead is matched to a Prospect Client (Current Client? Is False) within the Paychex Salesforce instance AND has no Open Opportunity AND has no activity in the last 6 months, then the Lead is considered workable by the BDR
  Workable information is sent back to Oasis instance
•  This will be worked as usual by the BDR
  Partner Referral is created with the incoming information
  Record type is updated to Prospect Record Type
  Type is set to Oasis Prospect
  Hold Out – True
  Hold Out Description – Oasis Prospect
  Owner – New Oasis Generic User for placeholder. Upon the BDR working and converting they will send the Account record which should match to this one and then the owner will be updated then

If there are Open Opps with activity in the last 6 months – not workable by Oasis BDR
If there are no Open Opps but activity in the last 90 days – not workable by the Oasis BDR
If there are no Open Opps but future activity in the next 90 days – not workable by the Oasis BDR
All else is workable.
if they have an open opportunity and no activity for three months, it can be worked.

*/
   // a match occurred on an account or contact. Check if there is any activity attached to it.   
   public static Boolean checkAcctCtctWorkable(Map<Id,PartRefWrapper[]> acctCheckMap, ErrorLog__c log) {
      Boolean okay = true;
      Date oppCheckDate = Date.today().addMonths(-6);
      Date activityQueryDate = Date.today().addMonths(-6);
      // check if activity in this range
      Date activityCheckDate = Date.today().addDays(-90);
      Date activityFutureDate = Date.today().addDays(90);
      Boolean isWorkable = true;
      //Account[] updateAccts = new Account[]{};

      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, OwnerId, CurrentClient__c
                       ,RecordTypeId, RecordType.Id, RecordType.Name, Type
                       ,Hold_Out__c, Hold_Out_Expiration__c
                       ,Permanent_Hold_Out_Description__c
                       ,(Select Id, Name, OwnerId, CloseDate 
                           from Opportunities 
                          where IsClosed = false and CreatedDate >= :oppCheckDate 
                          order by CreatedDate desc limit 5)
                    From Account
                   Where Id in :acctCheckMap.keySet()]);
      Map<Id,Task> taskMap = getTaskMap(acctCheckMap.keySet(), activityQueryDate, activityFutureDate);
      Map<Id,Event> eventMap = getEventMap(acctCheckMap.keySet(), activityQueryDate, activityFutureDate);

      for (Id acctId : acctCheckMap.keySet()) {
         String acctLog = 'acctId='+acctId;
         PartRefWrapper[] acctWraps = acctCheckMap.get(acctId);
         Account acct = acctMap.get(acctId);
         Id notWorkableOwnerId = null;
         if (acctWraps != null && !acctWraps.isEmpty() && acct != null) {
            String notWorkableReason = '';
            if (acct.CurrentClient__c) {
               notWorkableReason = 'Current Paychex Client';
               notWorkableOwnerId = acct.OwnerId;
               isWorkable=false;
            } else {
               Boolean openOpps = (!acct.Opportunities.isEmpty());
               Task tsk = taskMap.get(acctId);
               Event evt = eventMap.get(acctId);
               Boolean hasTasks = (tsk != null);
               Boolean hasEvents = (evt != null);
               System.debug('checkAcctCtctWorkable openOpps='+openOpps+' hasTasks='+hasTasks+' hasEvents='+hasEvents);
               acctLog += ('; openOpps='+openOpps+' hasTasks='+hasTasks+' hasEvents='+hasEvents);
               if (openOpps && (hasTasks || hasEvents)) {
                  //has an Open Opportunity AND has any activity in the last 6 months, then the Lead is considered not workable
                  isWorkable = false;
                  notWorkableReason = 'Has Open Opportunities and Activity';
                  notWorkableOwnerId = acct.Opportunities[0].OwnerId;
               } else { 
                  // check if any of the activity is recent - just have to check the first one in the list since sorted by newest date
                  Boolean hasRecentActivity = (tsk != null && tsk.ActivityDate >= activityCheckDate);
                  if (hasRecentActivity) {
                     notWorkableOwnerId = tsk.OwnerId;
                  }
                  if (!hasRecentActivity) {
                     hasRecentActivity = (evt != null && evt.ActivityDate >= activityCheckDate);
                     if (hasRecentActivity) {
                        notWorkableOwnerId = evt.OwnerId;
                     }
                  }
                  isWorkable = !hasRecentActivity;
                  if (hasRecentActivity) {
                     notWorkableReason = 'Has Recent Activity';
                  }
               }
            }
            acctLog += '; isWorkable='+isWorkable+' notWorkableReason='+notWorkableReason;
            Map<String,Schema.RecordTypeInfo> byNameMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
            for (PartRefWrapper wrap : acctWraps) {
               wrap.partRef.Workable__c = (isWorkable ? WORKABLE : NOT_WORKABLE);
               wrap.partRef.DuplicateNotWorkableReason__c = notWorkableReason;
               wrap.partRef.OwnerIdNotWorkable__c = notWorkableOwnerId;
               /*
               if (isWorkable && wrap.isOasis) {
                  Account updateAcct = new Account(Id=acct.Id);
                  Schema.RecordTypeInfo prospectRtInfo = byNameMap.get(Label.RT_Prospect_Acct);
                  if (prospectRtInfo != null) {
                     updateAcct.RecordTypeId = prospectRtInfo.getRecordTypeId();
                  }
                  updateAcct.PEOLeasing__c = true;
                  updateAcct.Type = 'Oasis Prospect';
                  updateAcct.Hold_Out__c=true;
                  updateAcct.Permanent_Hold_Out_Description__c='Oasis Prospect';
                  updateAccts.add(updateAcct);
               } // if (workable
               */
            } // for (PartRefWrapper wrap : acctWraps
         } else {
            acctLog += ' Could not find Account record!';
         } // if (acctWraps != null && acct != null
         ErrorLog.addToDescription(log,acctLog);
      } // for (Id acctId : acctCheckMap.keySet
      /*
      if (!updateAccts.isEmpty()) {
         ZipCheckOwner.SKIP_TRIGGERS=true;
         DmlHelper.performDML2(updateAccts, DmlHelper.DML_UPDATE, 'TrackRecordEntry', 'checkAcctCtctWorkable', 'Update hold out info on Account', true);
      }
      */
      return okay;
   } // checkAcctCtctWorkable
   
   public static Map<Id,Task> getTaskMap(Set<Id> acctIdSet, Date activityQueryDate, Date activityFutureDate) {
      Task[] tasks = [Select Id, OwnerId, ActivityDate, IsClosed, AccountId, WhatId
                           from Task
                          where (AccountId in :acctIdSet
                                 or WhatId in :acctIdSet)
                            and ActivityDate >= :activityQueryDate
                            and ActivityDate <= :activityFutureDate
                           order by ActivityDate desc
                           limit 100 ];
      Map<Id,Task> taskMap = new Map<Id,Task>();
      for (Task tsk : tasks) {
         Id key = (tsk.AccountId != null ? tsk.AccountId : tsk.WhatId);
         if (key != null && !taskMap.containsKey(key)) {
            taskMap.put(key,tsk);
         }
      }
      return taskMap;
   } // getTaskMap

   public static Map<Id,Event> getEventMap(Set<Id> acctIdSet, Date activityQueryDate, Date activityFutureDate) {
      Event[] events = [Select Id, OwnerId, ActivityDate, AccountId, WhatId
                           from Event
                          where (AccountId in :acctIdSet
                                 or WhatId in :acctIdSet)
                            and ActivityDate >= :activityQueryDate
                            and ActivityDate <= :activityFutureDate
                           order by ActivityDate desc
                           limit 100 ];
      Map<Id,Event> eventMap = new Map<Id,Event>();
      for (Event evt : events) {
         Id key = (evt.AccountId != null ? evt.AccountId : evt.WhatId);
         // only put one record in per Id. 
         if (key != null && !eventMap.containsKey(key)) {
            eventMap.put(key,evt);
         }
      }
      return eventMap;
   } // getEventMap


} // class TrackRecordEntry