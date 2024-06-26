/** Methods on the Contact object
 *
 * History
 * -------
 * 11/26/2013 Dan Carmen        Created.
 * 07/07/2014 Cindy Freeman     Added 2 methods to check field changes for DataFlux delta trigger
 * 08/24/2014 Cindy Freeman     Added Contact flopper methods to check for Duplicates and clone Contact
   02/12/2015 Dan Carmen        Log changes made to the contact in a related object.
   02/16/2015 Dan Carmen        Changes for Call Disposition
   07/30/2015 Jacob Hinds       Adding in Round Robin calls.
   05/11/2016 Jacob Hinds       Adding in bypass nss code to checkownedby
   05/31/2016 Dan Carmen        Fix for setting the disposition on an account
   10/31/2016 Jacob Hinds       Moving the check for prospect ownership up before virtual and round robin checks in checkOwnedBy.
   02/09/2017 Jacob Hinds       Removing a couple lines from the Master Partner referral section
   05/02/2017 Jacob Hinds       Adding line for Partner Referral Description
   01/12/2018 Jacob Hinds       Commenting out calldisposition stuff
   08/08/2018 Cindy Freeman     changes for PEOC contacts coming in through Lead Loader
   08/23/2018 Dan Carmen        Clean up the checkOwnedBy code - removed unneccessary work.
   12/06/2018 Dan Carmen        Replace qbdialer__LastCallTime__c with LatestCallTime__c
   03/19/2019 Jake Hinds        Changing PEOC to not use campaigns and use product division instead
   08/12/2019 Jake Hinds		Temporary fix for using Products__c alongside product division for PEO
   11/14/2019 Dan Carmen        Remove ISDC Code
   01/23/2020 Jermaine Stukes   Added updateSiginificant method
   06/30/2021 Dan Carmen        Clear email verification when email changes, format phone numbers
   01/07/2022 Dan Carmen        Remove PeoHelper code
   06/01/2022 Pujitha Madamanchi   APR0130779 Remove SignificantLead/SignificantContact

*/
public without sharing class ContactMethods {

   public static Boolean CONTACT_BEFORE_TRIGGER_EXECUTING=false;
   public static Boolean CONTACT_AFTER_TRIGGER_EXECUTING=false;
   public static Boolean CONTACT_WAS_PROCESSED_ROUND_ROBIN = false;

   /** If the NSS Call Disposition changes on the Contact, check if something needs to change.
    */
   public static void handleContactFields(Contact[] callDispositionCtcts, Contact[] lastDialedChangedCtcts, Contact[] latestCampaignChanged
                                          ,Set<Id> latestCampaignIdSet, Set<Id> acctIdSet, Set<Id> userIdSet) {
      System.debug('handleContactFields callDispositionCtcts='+callDispositionCtcts.size()+' lastDialedChangedCtcts='+lastDialedChangedCtcts.size()+' latestCampaignChanged='+latestCampaignChanged.size());
      
      
      // for contacts, update the call disposition on the account and let the account trigger handle it. 
      // get the account ids - map of the contacts by the account id
      Map<Id,Contact> ctctMap = new Map<Id,Contact>();
      
      User runningUser = UserHelper.getRunningUser();
      
      Map<Id,User> userMap = ProspectOwnershipMethods.getNsrUserMap(userIdSet);
    
      // retrieve the accounts
      // select the account (with contacts)
      List<Id> acctIdList = new List<Id>();
      acctIdList.addAll(acctIdSet);
      Map<Id,Account> acctMap = ReferralQueries.selectAcctMap(acctIdList);
      // get the ownership records
      Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(acctIdSet,true,null, null);
      
      ProspectOwnershipMethods.initializeSaveObjects();
      
      // move the call disposition to the Last field
      for (Contact ctct : callDispositionCtcts) {
         if (String.isNotBlank(ctct.NSSCallDisposition__c)) {
            // save the old value and clear the new value so the field can be triggered again.
            ctct.LastNSSCallDisposition__c = ctct.NSSCallDisposition__c;
            ctct.NSSCallDisposition__c = null;
         } // if (String.isNotBlank(
      }

      /* 01/12/18 Jacob Hinds       Commenting out calldisposition stuff, leaving in latest campaign part because they're still using it.
      for (Contact ctct : callDispositionCtcts) {
         if (ctct.Id != null) {
            AccountMethods.callDispositionHandledSet.add(ctct.Id);
         }
         // look for the call disposition setting
         LeadCallDisposition__c lcd = LeadMethods.findCallDisposition(ctct.NSSCallDisposition__c, ctct.NSSStatus__c);
         if (lcd != null) {
            // always clear out the ownership field if a disposition we recognize is set.
            if (String.isNotBlank(ctct.NSSOwnership__c)) {
                system.debug('clearing ownership field');
               ctct.NSSOwnership__c = null;
            }
            if (ctct.NSSStatus__c != lcd.NewLeadStatus__c) {
               System.debug('handleContactFields changing status to '+lcd.NewLeadStatus__c);
               ctct.NSSStatus__c = lcd.NewLeadStatus__c;
            } // if (ld.Status != lcd.NewLeadStatus__c
            
            if (String.isNotBlank(lcd.AssignToQueue__c)) {
               ctct.OwnedBy__c = lcd.AssignToQueue__c;
            }

            // find the account
            Account acct = acctMap.get(ctct.AccountId);
            System.debug('handleContactFields acct='+acct);
            
            // make sure the call disposition wasn't already handled on the account
            //if (acct != null && !AccountMethods.callDispositionHandledSet.contains(acct.Id) // && acct.NSSCallDisposition__c != ctct.NSSCallDisposition__c) {
            if (acct != null && !AccountMethods.callDispositionHandledSet.contains(acct.Id) ) {
               User dialedUser = runningUser;
         
               if (String.isNotBlank(ctct.DialedUserId__c)) {
                  User checkUser = userMap.get((Id)ctct.DialedUserId__c);
                  if (checkUser != null) {
                     dialedUser = checkUser;
                  }
                } // if (String

                acct.NSSCallDisposition__c = ctct.NSSCallDisposition__c;
                AccountMethods.handleCallDispositionChange(lcd, acct, ctct, null, null, acct.RecordType.Name, acctOwnerMap.get(acct.Id), dialedUser);
            // save the old value and clear the new value so the field can be triggered again.
                ctct.LastNSSCallDisposition__c = ctct.NSSCallDisposition__c;
                ctct.NSSCallDisposition__c = null;
            } // if (acct != null
         } // if (lcd != null
         
         if (String.isNotBlank(ctct.NSSCallDisposition__c)) {
            // save the old value and clear the new value so the field can be triggered again.
            ctct.LastNSSCallDisposition__c = ctct.NSSCallDisposition__c;
            ctct.NSSCallDisposition__c = null;
         } // if (String.isNotBlank(

      } // for (Contact ctct : callDispositionCtcts
      
      for (Contact ctct : lastDialedChangedCtcts) {
         if (ctct.Id != null) {
            AccountMethods.callDispositionHandledSet.add(ctct.Id);
         }
         // pull account from ProspectOwnershipMethods - to use the same record if available
         Account acct = ProspectOwnershipMethods.saveAcctMap.get(ctct.AccountId);
         if (acct == null) {
            acct = acctMap.get(ctct.AccountId);
         }
         if (acct != null && acct.LatestCallTime__c != ctct.LatestCallTime__c) {
            acct.LatestCallTime__c = ctct.LatestCallTime__c;
            ProspectOwnershipMethods.saveAcctMap.put(acct.Id, acct);
         }
         
         
      } // for (Contact ctct : lastDialedChangedCtcts
      */
      if (!latestCampaignIdSet.isEmpty()) {
        // get the campaign names
         Map<Id,Campaign> campaignMap = new Map<Id,Campaign>([Select Id, Name from Campaign where Id in :latestCampaignIdSet]);
      
         for (Contact ctct : latestCampaignChanged) {
            if (ctct.Id != null) {
               AccountMethods.callDispositionHandledSet.add(ctct.Id);
            }
            Campaign camp = campaignMap.get(ctct.LatestCampaign__c);
            if (camp != null) {
               // pull account from ProspectOwnershipMethods - to use the same record if available
               Account acct = ProspectOwnershipMethods.saveAcctMap.get(ctct.AccountId);
               if (acct == null) {
                  acct = acctMap.get(ctct.AccountId);
               }
         
               if (acct != null && acct.LatestCampaignName__c != camp.Name) {
                  acct.LatestCampaignName__c = camp.Name;
                  ProspectOwnershipMethods.saveAcctMap.put(acct.Id, acct);
               }
            } // if (camp != null
         } // for (Contact ctct
      } // if (!latestCampaignIdSet.isEmpty
      
      // don't save contacts since we're in the before trigger
      ProspectOwnershipMethods.saveCtctMap.clear();
      
      // we don't want to be processing the triggers again here do we?
      ZipCheckOwner.SKIP_TRIGGERS = true;
      ProspectOwnershipMethods.checkForSaves();
      ZipCheckOwner.SKIP_TRIGGERS = false;
      
   } // handleContactFields

   /** Check the ownership if the dialed checkbox is selected.
    *  Look for an existing ownership record. Should be at most one open record of each source (inbound/outbound).
         If running user is outbound and open outbound exists use that record
         If running user is outbound and only open inbound exists do not proceed
         If running user is outbound and no open records then create a new outbound record
         If running user is inbound and open inbound exists use that record
         If running user is inbound and only open outbound exists
               if outbound is locked out then do not modify it.
               if outbound is not locked out then end it.
               create a new inbound ownership record
    *   
    */
   public static void checkDialed(Contact[] ctcts) {
      // get all of the account ids
      Set<Id> acctIdSet = new Set<Id>();
      List<Id> acctIdList = new List<Id>();
      
      Set<Id> userIdSet = new Set<Id>();
      
      for (Contact ctct : ctcts) {
         acctIdSet.add(ctct.AccountId);
         acctIdList.add(ctct.AccountId);
         if (String.IsNotBlank(ctct.DialedUserId__c)) {
            userIdSet.add((Id)ctct.DialedUserId__c);
         }
      } // for (Contact ctct
      
      Map<Id,User> userMap = ProspectOwnershipMethods.getNsrUserMap(userIdSet);
       
      // right now this is only going to be executed from a trigger - use the running user
      User runningUser = UserHelper.getRunningUser();
                                                
      // the source of the running user
      String runningUserSource = ProspectOwnershipMethods.getNSS_Source(runningUser);
      
      // select the prospect ownership records associated with the account ids
      Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(acctIdSet, true, null, null);
      // select the account (with contacts)
      Map<Id,Account> acctMap = ReferralQueries.selectAcctMap(acctIdList);

      ProspectOwnershipMethods.initializeSaveObjects();

      for (Contact ctct : ctcts) {
         // get the account - should always be here. Do we need to check just in case?
         Account acct = acctMap.get(ctct.AccountId);
         // get any open ownership records
         List<Prospect_Ownership__c> openPOs = acctOwnerMap.get(ctct.AccountId);
        
         User dialedUser = runningUser;
         String dialedSource = runningUserSource;
         String ownershipSource = null;
         
         if (String.isNotBlank(ctct.DialedUserId__c)) {
            User checkUser = userMap.get((Id)ctct.DialedUserId__c);
            if (checkUser != null) {
                ownershipSource = 'DialedUserId';
               dialedUser = checkUser;
               dialedSource = ProspectOwnershipMethods.getNSS_Source(dialedUser);
            }
         } // if (String
        
         //String nssSource = ProspectOwnershipMethods.getNSS_Source(runningUser.Profile.Name);
         String[] nssTeams = ProspectOwnershipMethods.getNSSTeams(dialedUser, ctct.Products__c, acct.RecordType.Name, null,null, acct.NumberOfEmployees);
         String nssTeam = nssTeams[0];
         Prospect_Ownership__c po = ProspectOwnershipMethods.checkAccountOwnership(ProspectOwnershipMethods.STAGE_PROSPECTING, false, acct, ctct, null, null, dialedUser, null, nssTeam, dialedSource, acctOwnerMap.get(ctct.AccountId));
         if (po != null && po.Id == null) {
            po.Source__c = ownershipSource;
         }
        
      } // for (Contact ctct
          
      //if (!upsertPosMap.isEmpty()) {
      //   Database.upsert(upsertPosMap.values(),false);
      //}
    
      // don't save the contacts since they're being updated here from a before trigger
      ProspectOwnershipMethods.saveCtctMap.clear();
      ProspectOwnershipMethods.checkForSaves();
      
      
   } // checkDialed
   
   // Coming from the after trigger. 
   public static void checkOwnedBy(Set<Id> contactIdSet, Set<Id> acctIdSet) {
    
      Id[] acctIds = new Id[]{};
      acctIds.addAll(acctIdSet);
      Set<Id> campaignIdSet = new Set<Id>();
      Boolean logOriginalData = false;
    
      Map<Id,Account> acctMap = ReferralQueries.selectAcctMap(acctIds); 
      
      // a map of the selected contacts by the account id. This will only allow for 1 contact to be popped into a list per account.
      Map<Id, Contact> acctIdCtctMap = new Map<Id, Contact>();
      for (Account acct : acctMap.values()) {
         Contact ctct = findContact(acct.Contacts, contactIdSet);
         if (ctct != null) {
            if (checkContactOwnedByFld(ctct, 'After: ')) {
               logOriginalData = true;
            }

            acctIdCtctMap.put(acct.Id, ctct);
            if (ctct.LatestCampaign__c != null) {
                campaignIdSet.add(ctct.LatestCampaign__c);
            }
         }
      } // for (Account acct
      
      Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(acctIdSet, true, null, null);
            
      checkOwnedBy(acctIdCtctMap,acctMap, acctOwnerMap, true, campaignIdSet, logOriginalData);
   } // checkOwnedBy
   
   // Coming from the before trigger.
   public static void checkOwnedBy(Contact[] checkContacts) {
    
      // get the account ids
      Id[] acctIds = new Id[]{};
      Set<Id> acctIdSet = new Set<Id>();
      Set<Id> campaignIdSet = new Set<Id>();
      Map<Id, Contact> acctIdCtctMap = new Map<Id, Contact>();
      Boolean logOriginalData = false;

      for (Contact ctct: checkContacts) {
         if (checkContactOwnedByFld(ctct, 'Before: ')) {
            logOriginalData = true;
         }

         if (ctct.AccountId != null) {
            acctIds.add(ctct.AccountId);
            acctIdSet.add(ctct.AccountId);
            acctIdCtctMap.put(ctct.AccountId,ctct);
         }
         if (ctct.LatestCampaign__c != null) {
            campaignIdSet.add(ctct.LatestCampaign__c);
         }
      } // for (Contact ctct
      
      Map<Id,Account> acctMap = ReferralQueries.selectAcctMap(acctIds); 
      Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(acctIdSet, true, null, null);
      checkOwnedBy(acctIdCtctMap,acctMap, acctOwnerMap, false, campaignIdSet, logOriginalData);
   } // checkOwnedBy
   
   public static Boolean checkContactOwnedByFld(Contact ctct, String prefix) {
      Boolean logOriginalData = false;
      if (String.isNotBlank(ctct.OwnedBy__c)) {
         String msg = prefix+(String.isNotBlank(ctct.OwnedByPrev__c) ? 'Previous OwnedBy='+ctct.OwnedByPrev__c : '');
         msg += ' New OwnedBy='+ctct.OwnedBy__c;
         StringHelper.addToProcessNotes(ctct,msg);
         ctct.OwnedByPrev__c = ctct.OwnedBy__c;
         // clear out the original
         ctct.OwnedBy__c = null;
         LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(ctct.OwnedByPrev__c);
         logOriginalData = (llc != null && llc.StoreOrginalData__c);
      }
      return logOriginalData;
   } // checkContactOwnedByFld
   
   public class ContactWrapper {
      public Contact ctct;
      public Account acct;
      public Boolean hasVirtualOwnership=false;
      public Boolean hasProspectOwnership=false;
      public PartnerReferral__c mothership;
      public Boolean ctctHandled=false;
   }
   // Check the value of the owned by field on incoming contacts and determine how to set ownership based on that.
   public static void checkOwnedBy(Map<Id, Contact> acctIdCtctMap, Map<Id,Account> acctMap, Map<Id,List<Prospect_Ownership__c>> acctOwnerMap, Boolean updateContacts, Set<Id> campaignIdSet, Boolean logOriginalData) {
       System.debug('ContactMethods.checkOwnedBy updateContacts='+updateContacts+' acctIdCtctMap='+acctIdCtctMap.size()+' acctMap='+acctMap.size()+' acctOwnerMap='+acctOwnerMap.size());
      
      Schema.RecordTypeInfo acctProspectRT = RecordTypeHelper.getRecordType('Prospect', ObjectHelper.OBJECT_ACCOUNT);
  
      ProspectOwnershipMethods.initializeSaveObjects();
      
      List<Contact> virtualContacts = new List<Contact>();
      
      // list of accounts to be updated to Prospect rcd type
      List<Account> peoacctUpdate = new List<Account>();
      
      //get campaigns set to go straight to virtual. Used to determine if lead should go to virtual.  If the amount of campaigns that we're using in this process
      //becomes more than a handful this should be changed to use two queries directly mapped to the maps instead of one query with a for loop to break them out.
      Campaign[] campaigns = [SELECT Id,Name,Send_To_Virtual__c FROM Campaign WHERE Send_To_Virtual__c!=null and Id in :campaignIdSet];
      Map<Id,Campaign> campaignAlwaysSendMap = new Map<Id,Campaign>();     
      Map<Id,Campaign> campaignCheckZipMap = new Map<Id,Campaign>();
      
      //split campaigns into those automatically going to virtual and those only going based on if the territory rep is a virtual user
      for(Campaign c:campaigns){
        if(c.Send_To_Virtual__c == 'Always'){
            campaignAlwaysSendMap.put(c.Id,c);
        }
        else if(c.Send_To_Virtual__c == 'Check Zips'){
            campaignCheckZipMap.put(c.Id,c);
        }
      }
      
      System.debug('ContactMethods.checkOwnedBy campaignIdSet='+campaignIdSet.size()+' campaignAlwaysSendMap='+campaignAlwaysSendMap.size()+' campaignCheckZipMap='+campaignCheckZipMap.size());

       List<Zip_Assignment__c> zipList = new List<Zip_Assignment__c>();
      // allow to group by zip code
      Map<String,ContactWrapper[]> virtualContactByZipMap = new Map<String,ContactWrapper[]>();
      
      ContactWrapper[] contactWraps = new ContactWrapper[]{};
      PartnerReferral__c[] mothers = new PartnerReferral__c[]{};
      Map<Id,List<PartnerReferral__c>> acctPartnerMap = new Map<Id,List<PartnerReferral__c>>();
      String virtualQueue;
      Boolean sendToVirtualActive;
      Integer expirationDuration;
      BypassNSS__c bNSS = BypassNSS__c.getOrgDefaults(); 
      if(bNSS!=null){
         sendToVirtualActive = bNSS.IsActive__c;
         virtualQueue = bNSS.Queue_Name__c;
         expirationDuration = (Integer)bNSS.Holdout_Expiration__c;
         // we only want to do something here if we need to. If we're not logging the orginal data, then do nothing.
         if (logOriginalData) {
            Integer partRefDuration = (Integer)bNSS.Partner_Referral_Expiration_Duration__c * -1;
            Date partRefExpiration = system.today().addDays(partRefDuration);
            PartnerReferral__c[] partnerQueryList = [SELECT Id,Contact__c,Account__c,Contact__r.OwnerId,Destination__c,Source__c FROM PartnerReferral__c WHERE Account__c in :acctMap.values() AND Master_Partner_Referral__c=null AND CreatedDate >= :partRefExpiration order by CreatedDate asc];
            for(PartnerReferral__c partner:partnerQueryList){
               if(acctPartnerMap.containsKey(partner.Account__c)){
                  acctPartnerMap.get(partner.Account__c).add(partner);
               }
               else{
                  PartnerReferral__c[] pAccountList = new PartnerReferral__c[]{partner};
                  acctPartnerMap.put(partner.Account__c,pAccountList);            
               }
            } // for(PartnerReferral__c partner
         } // if (logOriginalData
      } // if(bNSS!=null
          
      
      for (Account acct : acctMap.values()) {
         
         // find the contact that was passed in
         Contact ctct = acctIdCtctMap.get(acct.Id);
         if (ctct != null) {
            // save all contacts. If there isn't an id, we're in the before trigger.
            if (ctct.Id != null) {
               ProspectOwnershipMethods.saveCtctMap.put(ctct.Id, ctct);
            }
            ContactWrapper contactWrap= new ContactWrapper();
            contactWrap.ctct = ctct;
            contactWrap.acct = acct;
            contactWraps.add(contactWrap);
            if (logOriginalData) {
               //PartnerReferral__c mothership = new PartnerReferral__c();
               PartnerReferral__c partRef = TrackRecordEntry.logOriginalData(ctct, acct, null, false);
               //mothership.Contact__c = ctct.Id;
               //mothership.Account__c = acct.Id;
               //partRef.Source__c=ctct.OwnedByPrev__c;
               //mothership.Description__c = ctct.Description;
               //mothership.Campaign__c = ctct.LatestCampaign__c;
            
               PartnerReferral__c[] masterReferrals = acctPartnerMap.get(acct.Id);
               if(masterReferrals!= null && !masterReferrals.isEmpty()){
                  PartnerReferral__c masterReferral = masterReferrals.get(0);
                  partRef.Master_Partner_Referral__c = masterReferral.Id;
               }
               contactWrap.mothership = partRef;
               mothers.add(partRef);
            } // if (logOriginalData
            // check if in the campaigns
            system.debug('acctOwnerMap'+acctOwnerMap);
            contactWrap.ctctHandled = handleContact(contactWrap, acctOwnerMap.get(contactWrap.acct.Id));
            if(contactWrap.hasProspectOwnership && contactWrap.mothership != null){
                contactWrap.mothership.Destination__c = 'NSS Prospect Ownership';
            }
            system.debug('contactWrap hasProspectOwnership: '+contactWrap.hasProspectOwnership);
             
            if (sendToVirtualActive && campaignAlwaysSendMap.containsKey(contactWrap.ctct.LatestCampaign__c)) {
                System.debug('checkOwnedBy ld='+ctct.Name+' hasVirtualOwnership=Always Send');
                contactWrap.hasVirtualOwnership = true;
                contactWrap.ctctHandled = true;
                if (contactWrap.mothership != null) {
                   contactWrap.mothership.Source__c=contactWrap.ctct.OwnedBy__c;
                   contactWrap.mothership.Destination__c = 'Virtual Sales';
                }
                contactWrap.ctct.NSSOwnership__c = virtualQueue;
                if (updateContacts) {
                    virtualContacts.add(contactWrap.ctct);
                }
            
            }//if(campaignAlwaysSendMap
            //check if the lead is set to go to virtual based on zips, then create a map of zipcodes,leads to select.
            else if(contactWrap.ctct.MailingPostalCode!=null && sendToVirtualActive && campaignCheckZipMap.containsKey(contactWrap.ctct.LatestCampaign__c)){
                System.debug('checkOwnedBy ctct='+ctct.Name+' hasVirtualOwnership=CheckZip');
                String zipCode = (contactWrap.ctct.MailingPostalCode.length() > 5) ? contactWrap.ctct.MailingPostalCode.substring(0,4) : contactWrap.ctct.MailingPostalCode;
                
                ContactWrapper[] contactList = (virtualContactByZipMap.containsKey(zipCode) ? virtualContactByZipMap.get(zipCode) : new ContactWrapper[]{});
                contactList.add(contactWrap);
                virtualContactByZipMap.put(zipCode,contactList);
            }//else if(contactWrap
         } // if (ctct != null
      } // for (Account acct   
      
       
      if (updateContacts) {
         ChatterMessageSend.checkAfterProcess();
      }
      //get zip assignments for the incoming contacts, but only if the territory rep is virtual.
      System.debug('ContactMethods.checkOwnedBy virtualContactByZipMap: '+virtualContactByZipMap);
      if(!virtualContactByZipMap.isEmpty()){
        zipList=[SELECT Name,Id,User__c,User__r.Name,User__r.UserRole.Name,User__r.NSS_Team__c FROM Zip_Assignment__c WHERE Name in :virtualContactByZipMap.keySet() 
                   AND Sales_Org__c=:UserHelper.SO_CORE 
                   AND (Segment_Name__c=:ZipQueries.SEGMENT_DEFAULT OR Segment_Name__c='TIER2')
                   AND (( User__r.UserRole.Name like '%Virtual%' AND User__r.NSS_Team__c = :Label.NSS_Team_VS_PAY) or (User__r.Name = 'Virtual Sales'))];
      }

        //Check for VSR
      for(Zip_Assignment__c za:zipList){
          system.debug('za: '+za);
     
          Boolean useQueue = (za.User__r.Name == 'Virtual Sales');
            
          ContactWrapper[] contactList = virtualContactByZipMap.remove(za.Name);
          if (contactList != null) {
             for (ContactWrapper contactWrap : contactList) {
                contactWrap.hasVirtualOwnership = true;
                contactWrap.ctctHandled = true;
                if (contactWrap.mothership != null) {
                   contactWrap.mothership.Source__c=contactWrap.ctct.OwnedBy__c;
                   contactWrap.mothership.Destination__c = 'Virtual Sales';
                }
                if (useQueue) {
                   contactWrap.ctct.NSSOwnership__c = virtualQueue;
                } else {
                   contactWrap.ctct.OwnerId=za.User__c;
                   contactWrap.ctct.Hold_Out__c=true;
                   contactWrap.ctct.Hold_Out_Expiration__c=system.today()+expirationDuration;
                   
                   system.debug('given assignment rules for contact: '+contactWrap.ctct);
                     
                }
                if (updateContacts) {
                  virtualContacts.add(ContactWrap.ctct);
                }
             }
          }
            
      }//for(Zip_Assignment__c

      if(!mothers.isEmpty()){
        System.debug('ContactMethods.checkOwnedBy inserting mothers');
        insert mothers;
      }
      
      Map<Id,Contact> rrContactMap = new Map<Id,Contact>();
      Map<Id,Account> rrAccountMap = new Map<Id,Account>();
      Map<Id,PartnerReferral__c> rrMotherMap = new Map<Id,PartnerReferral__c>();
      List<sObject> updateChatter = new List<sObject>();
      for(ContactWrapper contactWrap : contactWraps){
        if(!contactWrap.hasVirtualOwnership && !contactWrap.hasProspectOwnership && !contactWrap.ctctHandled){  // added !ctctHandled
            rrContactMap.put(contactWrap.ctct.Id,contactWrap.ctct);
            rrAccountMap.put(contactWrap.ctct.Id,contactWrap.acct);
            rrMotherMap.put(contactWrap.ctct.Id,contactWrap.mothership);
            System.debug('ContactMethods.checkOwnedBy rrContactMap: '+rrContactMap);
            System.debug('ContactMethods.checkOwnedBy rrAccountMap: '+rrAccountMap);
            System.debug('ContactMethods.checkOwnedBy rrMotherMap: '+rrMotherMap);
        }
      }
      
      if(!rrContactMap.isEmpty() && !rrMotherMap.isEmpty()){
        RoundRobin.prepareContactRoundRobin(rrContactMap,rrAccountMap,rrMotherMap);
      }
    
      for(ContactWrapper contactWrap : contactWraps){
        
          if(contactWrap.hasVirtualOwnership){
            updateChatter.add(contactWrap.ctct);
          }
          if (contactWrap.ctctHandled) {
              System.debug('ContactMethods.checkOwnedBy contactHandled');
              //contactWrap.ctct.OwnedByPrev__c = contactWrap.ctct.OwnedBy__c;
              //contactWrap.ctct.OwnedBy__c = null;
              // moving this to earlier in the code
              //ProspectOwnershipMethods.saveCtctMap.put(contactWrap.ctct.Id, contactWrap.ctct);
          } 
      }
      if (!updateContacts) {
         ProspectOwnershipMethods.saveCtctMap.clear();
      }
      
      if(!virtualContacts.isEmpty()){
        update virtualContacts;
      }
      
      if(!updateChatter.isEmpty()){
        LeadMethods.sendChatterUpdate(updateChatter);
      }
      
      // we want to skip the data governance check since we'll be performing another update.
      //CheckDataGovernance.SKIP_DATA_GOVERNANCE = true;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ProspectOwnershipMethods.checkForSaves();
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = false;

      // update accounts to be Prospect rcd type
      if (!peoacctUpdate.isEmpty())
      {     System.debug('ContactMethods.checkOwnedBy updating peoacctUpdates size='+peoacctUpdate.size()); 
            ZipCheckOwner.accountIdsProcessedSet.clear();       // do this so acct owners are updated and contact gets correct owner (same as account)                          
            update peoacctUpdate;   
      }
            
   } // checkOwnedBy
   
   /** Find a contact that's in the set of ids.
    */
   public static Contact findContact(Contact[] contacts, Set<Id> contactIdSet) {
    Contact ctct = null;
    
      if (contacts != null && !contacts.isEmpty() && contactIdSet != null && !contactIdSet.isEmpty()) {
         for (Contact checkCtct : contacts) {
            if (contactIdSet.contains(checkCtct.Id)) {
               ctct = checkCtct;
               break;
            } // if (contactIdSet
         } // for (Contact checkCtct
      } // if (contacts != null
      
      return ctct;
   } // findContact
   
   /** Handle the ownership of the contact.
    */
   public static Boolean handleContact(ContactWrapper contactWrap, List<Prospect_Ownership__c> acctOwnerList) {
      Contact ctct = contactWrap.ctct;
      Account acct = contactWrap.acct;
      Boolean ctctHandled = false;
      // if no ownership
      LeadLoaderConfig__c config = LeadLoaderConfig__c.getInstance(ctct.OwnedByPrev__c);
      System.debug('checkOwnedBy processing ctct='+ctct.Name+' config='+config);
      if (config != null && config.IsActive__c) {
         if (config.NotifyOwner__c && ctct.Id != null) {
            ChatterMessageSend.notifyOwnerIdSet.add(ctct.Id);
         }
         Prospect_Ownership__c inboundOwner = ProspectOwnershipMethods.getProspectingOwner(acctOwnerList, null, ProspectOwnershipMethods.NSS_INBOUND);
         Prospect_Ownership__c outboundOwner = ProspectOwnershipMethods.getProspectingOwner(acctOwnerList, null, ProspectOwnershipMethods.NSS_OUTBOUND);
         // if no ownership, set to the queue - doesn't matter if inbound or outbound
         system.debug('ibOwner: '+inboundOwner+' obOwner: '+outboundOwner+' config Queue Name: '+config.QueueName__c);
         if (inboundOwner == null && outboundOwner == null && String.IsNotBlank(config.QueueName__c)) {
            // set this as the significant lead on the company
            if (acct.SignificantContact__c != ctct.Id) {
               acct.SignificantContact__c = ctct.Id;
               ProspectOwnershipMethods.saveAcctMap.put(acct.Id,acct);
            } // if (acct.SignificantContact__c
            StringHelper.addToProcessNotes(ctct,'Setting NSSOwnership to '+config.QueueName__c+' from config '+config.Name);
            ctct.NSSOwnership__c = config.QueueName__c;
            ctctHandled = true;
         }
         else if ((inboundOwner != null || outboundOwner != null) && String.isNotBlank(config.NSSSource__c)) {
            
            // if outbound queue and po is outbound - do nothing
            if (config.NSSSource__c == ProspectOwnershipMethods.NSS_OUTBOUND && outboundOwner != null) {
               // do nothing - already being worked by outbound
               contactWrap.hasProspectOwnership=true;
               if(contactWrap.ctct.OwnerId != outboundOwner.NSR_Name__c){
                 contactWrap.ctct.OwnerId = outboundOwner.NSR_Name__c;
                 StringHelper.addToProcessNotes(ctct,'Outbound Ownership setting Owner to '+outboundOwner.NSR_Name__c);
               }
            } else if (config.NSSSource__c == ProspectOwnershipMethods.NSS_INBOUND && inboundOwner != null) {
               // don't have to modify the existing ownership
               // pop to the NSR
               contactWrap.hasProspectOwnership=true;
               if(contactWrap.ctct.OwnerId != inboundOwner.NSR_Name__c){
                 contactWrap.ctct.OwnerId = inboundOwner.NSR_Name__c;
                 StringHelper.addToProcessNotes(ctct,'Inbound Ownership setting Owner to '+inboundOwner.NSR_Name__c);
               }
            } else if (config.NSSSource__c == ProspectOwnershipMethods.NSS_OUTBOUND && inboundOwner != null) {
               // do nothing - currently being worked by inbound - leave ownership as is
               contactWrap.hasProspectOwnership=true;
               if(contactWrap.ctct.OwnerId != inboundOwner.NSR_Name__c){
                 contactWrap.ctct.OwnerId = inboundOwner.NSR_Name__c;
                 StringHelper.addToProcessNotes(ctct,'Inbound Ownership setting Owner to '+inboundOwner.NSR_Name__c);
               }
            } else if (config.NSSSource__c == ProspectOwnershipMethods.NSS_INBOUND && outboundOwner != null) {
               // end outbound ownership, pop to inbound queue
               ProspectOwnershipMethods.setStageExitInfo(outboundOwner, acct, ctct, null, null, true, true, true);
               ctct.NSSOwnership__c = config.QueueName__c;
               ctctHandled = true;
               StringHelper.addToProcessNotes(ctct,'Ending Outbound Ownership and setting NSSOwnership to '+config.QueueName__c);
            } // if (config.NSSSource__c
         } // if (inboundOwner
         system.debug('inHandleContact hasProspectOwnership: '+contactWrap.hasProspectOwnership);
      } // if (config != null
      
      System.debug('ContactMethods handleContact returning='+ctctHandled);
      
      return ctctHandled;
   } // handleContact
   
   public static Boolean FORMAT_PHONE=!Test.isRunningTest();

   public static void contactBeforeChecks(Contact newC, Contact oldC) {
    if (newC != null) {
         UserHelper.setRunningUserAttributes();

       if (oldC != NULL && newC.Email != oldC.Email) {
           newC.Email_Verification__c = NULL;
           newC.Email_Verification_Date__c = NULL;
       }        
        
      if (FORMAT_PHONE && newC.Phone != null && (oldC == null || (newC.Phone != oldC.Phone ))) {
         newC.Phone = StringHelper.formatPhoneNumber(newC.Phone, true);
      }
       
      if (FORMAT_PHONE && newC.MobilePhone != null && (oldC == null || (newC.MobilePhone != oldC.MobilePhone ))) {
         newC.MobilePhone = StringHelper.formatPhoneNumber(newC.MobilePhone, true);
      }

         if (UserHelper.runningUserIsLeadLoader) {
            if (oldC == null && String.isBlank(newC.LastName)) {
               newC.LastName = UserHelper.UNKNOWN;
            }
            // anything coming in through the lead loader should be marked as a sales contact at this point
            // TODO - not sure if we need more cases around it.
            if (!newC.Sales_Contact__c) {
               newC.Sales_Contact__c = true;
            }
            
            if (oldC != null && newC.MailingPostalCode == '88888' && String.isNotBlank(oldC.MailingPostalCode)) {
               newC.MailingPostalCode = oldC.MailingPostalCode;
            }

         } // if (UserHelper.runningUserIsLeadLoader
         
         if (oldC != null) {
            // someone tries to change the owner with the hold out checked.
            // allow the owner to change at the time the hold out is set.
            if (!newC.BypassHoldout__c && newC.Hold_Out__c && oldC.Hold_Out__c && newC.OwnerId != oldC.OwnerId) {
               System.debug('ContactBefore hold out is set! Changing owner from '+newC.OwnerId+' to '+oldC.OwnerId);
               newC.OwnerId = oldC.OwnerId;
            }

         } // if (oldC != null
         
         // reset this flag if set - only good for one transaction
         if (newC.BypassHoldout__c) {
            newC.BypassHoldout__c = false;
         }

    } // if (newC != null
   } // contactBeforeChecks

   /** NSR wants to Flop a Contact but lets see if new Contact is already in SF
   
   public static Boolean checkForDuplicate(Contact newCtct) {
        Boolean duplicateCtct = false;
        List<Contact> updateCtctList = new List<Contact>();
        Set<Id> matchCtIdSet = new Set<Id>();
        
        List<CRMfusionDBR101.DB_Api.Matches> matchSets = CRMfusionDBR101.DB_Api.findMatches( newCtct );
        if (!matchSets.isEmpty())
        {    for (CRMfusionDBR101.DB_Api.Matches dbm:matchSets)
            {    if (dbm.matchOnInsertAction == 'Do Not Insert' && dbm.blockingMessage.contains('Duplicate Contact'))   
                 {  duplicateCtct = true;
                    matchCtIdSet.addAll(dbm.matchedIds);
                 } // if (dbm.matchOnInsertAction == 'Do Not Insert' &&
            } // for (CRMfusionDBR101.DB_Api.Matches dbm:matchSets)
        } // if (!matchSets.isEmpty())
        
        // check duplicate found to see if we need to set Sales_Contact__c so NSR can see the record
        if (!matchCtIdSet.isEmpty()) 
        {   //Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(RecordTypeHelper.SERVICE_COMPLETE_CONTACT, 'Contact'); 
            updateCtctList = [select Id, recordtypeId, sales_contact__c from Contact 
                                                where Id in :matchCtIdSet and Sales_Contact__c = FALSE]; // and recordTypeId = :rt.getRecordTypeId()];
            if (!updateCtctList.isEmpty())
            {    for (Contact updateCt: updateCtctList)   
                 {    System.debug('**CMF ** matched Ct dup='+updateCt.Id+' rcd type='+updateCt.recordtypeId);
                      updateCt.Sales_Contact__c = true;
                 } // for
                 update updateCtctList;
            } // if
        } // if (!matchCtIdSet.isEmpty()) 
        
        System.debug('**CMF ** duplicateCtct='+duplicateCtct+' updated cts='+updateCtctList.size());
        return duplicateCtct;
    
   } // checkForDuplicate
        
     NSR wants to Flop a Contact so lets save old Contact as a new record
    
    public static Boolean cloneCtct(Contact oldctct) {
        Boolean clonedOK = true;
        
        Contact clonedCtct = oldCtct.clone(false, true, false, false);      // deep clone        
        clonedCtct.NSSStatus__c = 'Contacted';
        clonedCtct.LeadSource = 'Lead Referral';
        clonedCtct.Duplicate_OK__c = true;          // need for Dupe Blocker filter
        clonedCtct.DataFlux_ID__c = null;
        clonedCtct.Copy_Contact__c = false;
        try 
        {   insert clonedCtct;  } 
        catch (Exception ex) 
        {   clonedOk = false;   }
        
        return clonedOK;
    } // cloneCtct        
  **/
   
   public static Boolean CHANGE_TRIGGER_ENABLED=(Label.Contact_Change_Trigger == 'true');
   
   public static Set<Id> contactsCheckedForChangeSet = new Set<Id>();
   
   public static void checkForContactChange(Contact newC, Contact oldC) {
    // make sure we only check records once in a session
    Boolean processed=contactsCheckedForChangeSet.contains(newC.Id);
    System.debug('checkForContactChange CHANGE_TRIGGER_ENABLED='+CHANGE_TRIGGER_ENABLED+' processed='+processed);
      if (CHANGE_TRIGGER_ENABLED && newC != null && oldC != null && !processed) {
        String userType = UserHelper.getRunningUserType();
        contactsCheckedForChangeSet.add(newC.Id);
        Boolean hasChanges = false;
        ContactChange__c change = new ContactChange__c(Contact__c=newC.Id, UserType__c=userType, ChangeExternalId__c=newC.Id+'-'+userType);
        if (String.isNotBlank(newC.Phone) && newC.Phone != oldC.Phone) {
           hasChanges = true;
           change.Phone__c = newC.Phone;
           change.PhonePrev__c = oldC.Phone;
        }
        
        if (String.isNotBlank(newC.Email) && newC.Email != oldC.Email) {
            hasChanges = true;
            change.Email__c = newC.Email;
            change.EmailPrev__c = oldC.Email;
        }
        
         if (String.isNotBlank(newC.MailingStreet) && newC.MailingStreet != oldC.MailingStreet) {
            hasChanges = true;
            change.Street__c = newC.MailingStreet;
            change.StreetPrev__c = oldC.MailingStreet;
         }
         
         if (String.isNotBlank(newC.MailingCity) && newC.MailingCity != oldC.MailingCity) {
            hasChanges = true;
            change.City__c = newC.MailingCity;
            change.CityPrev__c = oldC.MailingCity;
         }
         
         if (String.isNotBlank(newC.MailingState) && newC.MailingState != oldC.MailingState) {
            hasChanges = true;
            change.State__c = newC.MailingState;
            change.StatePrev__c = oldC.MailingState;
         }
         
         if (String.isNotBlank(newC.MailingPostalCode) && newC.MailingPostalCode != oldC.MailingPostalCode) {
            hasChanges = true;
            change.PostalCode__c = newC.MailingPostalCode;
            change.PostalCodePrev__c = oldC.MailingPostalCode;
         }
        
        if (hasChanges) {
           contactChangeMap.put(change.ChangeExternalId__c, change);
        }
      } // if (!contactsCheckedForChangeSet
      System.debug('checkForContactChange contactChangeMap='+contactChangeMap.size());
   } // checkForContactChange
   
   private static Map<String,ContactChange__c> contactChangeMap = new Map<String,ContactChange__c>();
   
   public static void checkForContactChangeSave() {
      if (!contactChangeMap.isEmpty()) {
        try {
           upsert contactChangeMap.values() ChangeExternalId__c;
        } catch (Exception e) {
            ErrorLog.logError('ContactMethods', 'checkForContactChangeSave', 'upsert contactChangeMap', contactChangeMap.values()[0].Contact__c, e, contactChangeMap.values()[0]);
        }
        contactChangeMap.clear();
      } // if (!contactChangeMap.
      ErrorLog.checkSave();
   } // checkForContactChangeSave
    public static void updateSignificant(List<Contact> contactList){
        List<Id> acctIdList = new List<Id>();
        Map<Id,Id> contactMap = new Map<Id,Id>();
        List<Account> acctList = new List<Account>();
        for(Contact con : contactList){
            acctIdList.add(con.AccountId);
            contactMap.put(con.AccountId, con.Id);
        }
         //APR0130779 : Remove Significant Lead/Contact
        List<Cadence_Assignment_Record__c> carList = [Select Id
                                                   ,AccountId__c
                                                   ,AccountId__r.Id
                                                   ,AccountId__r.SignificantContact__c
                                                  /* ,SignificantContact__c*/
                                                  ,ContactId__c
                                               from Cadence_Assignment_Record__c 
                                              where AccountId__c in :acctIdList];
        for(Cadence_Assignment_Record__c carRec : carList){
            //carRec.SignificantContact__c = contactMap.get(carRec.AccountId__c);
            carRec.ContactId__c = contactMap.get(carRec.AccountId__c);
            carRec.AccountId__r.SignificantContact__c = contactMap.get(carRec.AccountId__c);
            if(!acctList.contains(carRec.AccountId__r)){
                acctList.add(carRec.AccountId__r);
            }
            update acctList;
            update carList;
            
        }
    }//updateSignificant
} // class ContactMethods