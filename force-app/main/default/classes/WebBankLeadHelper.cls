/*
 * This class processes bank leads that come in through the WebBankLeadEmailHandler.  
   
   Bank Ownership rules (in order of checking):
       if sales rep name is specified
           - use the specified sales rep (if found)
       if payroll and owner not found, there is a bank centric rep on the branch, and not a phone bank
           - use the bank centric rep
       if 401k, not phone bank
           - use the Small Market rep from the zip assignments. Uses the bank zip code. If there is no bank zip code, will use the pro
       if referral contact is not found and not a phone bank
           - use the owner of the branch (referral account)
       if the referral contact is found (already exists in the database) and not a phone bank
           - use the owner of the referral contact.
       
       if all else fails, use the zip ownership of the lead - would rarely get here unless phone bank is checked on the bank since it’s pulling the owner of the branch.              
       
 *
 * History
 * --------
 * 10/25/2013   Justin Stouffer created 
 * 02/04/2015   Justin Stouffer Updated to add 401k for PNC Bank
   08/19/2015   Dan Carmen      Changes for SRR.
   04/28/2016   Dan Carmen      Make sure all of the lead owners are included in each chatter message.
   05/20/2016   Dan Carmen      Check for why owner isn't being set from the referral account/contact
   09/23/2016   Dan Carmen      Don't send an email if no rep mail passed in.
   09/26/2016   Dan Carmen      Change order of ownership rules (use sales rep name first)
   09/11/2019   Matt Fritschi   Adjustment to assign ownership to Bank Centric Rep or 401k Bank Centric Rep in they exist.
   04/28/2021   Pujitha Madamanchi  Add clover tag
   06/22/2021   Pujitha Madamanchi  APR0119329: Update Referral email from static resource to email template
   08/05/2021   Pujitha Madamanchi  Add MID tag
   11/25/2021   Pujitha Madamanchi  APR0127496: Citibank tags
   06/01/2022   Pujitha Madamanchi  APR0130800 : Assign Lead based on Primary Zip Segment on Parent Referral Account
   05/01/2023   Dan Carmen          Adjustment for Dupechecking
   06/14/2023   Shilpa Govindarajulu    INC3378498: Modified method findPartnerContact to look for duplicate Referral contacts instaed of duplicate contacts
   09/28/2023   Dan Carmen          Clean up code
   12/20/2023   Carrie Marciano     Added phone and email to Default Employee so duplicate check would find and not create a new refContact
   05/30/2024   Pujitha Madamanchi  New bank tags

 */
 
public without sharing class WebBankLeadHelper {
   
   public static final String TIER_1='Bank - Tier 1';
   public static final String TIER_2='Bank - Tier 2';

   public class BankLead {
        public string firstName;
        public string lastName;
        public string fullName;
        public string refEmployeeFirstName;
        public string refEmployeeLastName;
        public string refEmployeePhone;
        public string refEmployeeEmail;
        public string refCCEmail;
        public string AdditionalReferringName;
        public string AdditionalReferringEmpId;
        public string EmployeeID;
        public string salesRepFirstName;
        public string salesRepLastName;
        public string company;
        public string email;
        public string phone;
        public string street;
        public string city;
        public string state;
        public string zip;
        public string bankName;
        public string branchNumber;
        public string branchName;
        public string branchZip;
        public string comments;
        public string promocode;
        public string title;
        public string payroll;
        public string x401k;
        public string lineOfBusiness;
        public string profile;
        public integer NumOfEmployees;
        public ID userId;
        public ID campaignId;
        public string expressedInterest;
        public string obtainedConsent;
        public string spokenToPaychexRep;
        public string scheduledAppointment;
        public string Clover;
        public string MID;
        public string VendorId;
        public string Area;
        public string Division;
        public string CustConsent;
        public string ConsentObtainedBy;
        public date ConsentObtainedDateSubmitted;
        public string CustConsentContactMethod;
        public string CustomerConsentName;
        public string CustConsentPhone;
        public date CustConsentDateObtained;
        public string additionalProducts;
        public string SynLineofBusiness;
        public string SynEEDeptCostCenter;
        public string referralBundle;
        
        
        // does this lead have at least the basic information filled out?
        public Boolean hasBasicInformation() {
           if (lastName == null || bankName == null || branchName == null) {
              return false;
           }
           return true;
        } // hasBasicInformation
   } // Update with the correct xml tags

/*
   // a string containing the detail of the incoming lead information
   public static String getLeadDetail(PartnerReferral__c partRef, Boolean product) {
      String detail = getValue(true,'Bank Name',partRef.PartnerName__c);
      detail += getValue(false,'Branch No',partRef.BranchNumber__c);
      detail += getValue(false,'Branch Name',partRef.BranchName__c);
      detail += getValue(false,'Ref Contact',partRef.EmpFirstName__c + ' ' + partRef.EmpLastName__c);
      detail += getValue(false,'Emp ID',partRef.EmployeeId__c);
      detail += getValue(false,'Product',partRef.Products__c);
      String repName = (String.isNotBlank(partRef.SalesRepFirstName__c) ? partRef.SalesRepFirstName__c : '');
      repName += (repName != '' ? ' ' : '') + (String.isNotBlank(partRef.SalesRepLastName__c) ? partRef.SalesRepLastName__c : '');
      detail += getValue(false,'Branch No',repName);
      return detail;
   } // getLeadDetail

   private static String getValue(Boolean isFirst, String label, String value) {
      String retVal = (String.isNotBlank(value) ? (isFirst ? '' : ', ') + label + ': ' + value : '');
      return retVal;
   } // getValue
  */ 
   // used for the products__c field on the lead
   public static final String PROD_401k='401K';
   
   private static Schema.RecordTypeInfo leadPendingRT = null;
   private static Schema.RecordTypeInfo leadHRSRT;
   private static Schema.RecordTypeInfo leadCoreRT;

   // setup the static record type variables
   public static void setupRecordTypes() {
      if (leadPendingRT == null) {
         Map<String,Schema.RecordTypeInfo> byNameMap = Lead.SObjectType.getDescribe().getRecordTypeInfosByName();
         leadPendingRT = byNameMap.get(Label.RT_Pending_Leads); 
         leadHRSRT = byNameMap.get(RecordTypeHelper.HRS_LEAD); 
         leadCoreRT = byNameMap.get(RecordTypeHelper.CORE_LEAD); 
      } // if (leadPendingRT == null
   } // setupRecordTypes
   
   /*
   public static final String PARTNER_TYPE='Inbound Bank Leads';
   
   private static Map<String,Referral_Partner__c> refPartnerMap = null;
   
   public static Referral_Partner__c findReferralPartner(String partnerName) {
      Referral_Partner__c refPartner = null;
      if (String.isNotBlank(partnerName)) {
         if (refPartnerMap == null) {
            refPartnerMap = new Map<String,Referral_Partner__c>();
            Referral_Partner__c[] refPartners = ReferralQueries.selectRefPartners(PARTNER_TYPE, null);
            for (Referral_Partner__c checkRefPartner : refPartners) {
               refPartnerMap.put(checkRefPartner.name, checkRefPartner);
            }
         } // if (refPartnerMap == null
         refPartner = refPartnerMap.get(partnerName);
      } // if (String.isNotBlank(partnerName
      return refPartner;
   } // findReferralPartner
   */
   /*
   // legacy method - the ones coming in through the email (tier 1) will go through here.
   public static void processBanklead(List<BankLead> bankLeadList) {
      List<PartnerWrapper> partnerWraps = new List<PartnerWrapper>();
      for (Banklead bankLd: bankLeadList) {
         PartnerWrapper partnerWrap = new PartnerWrapper(bankLd);
         // default the value for this method of entry.
         partnerWrap.partnerName = TIER_1;
         partnerWraps.add(partnerWrap);
      }
      processReferrals(partnerWraps);
   } // processBanklead
*/
   //public static Boolean processReferrals(List<PartnerWrapper> partnerWraps) {
   //   return true;
   //}

   public static String CORE_DEFAULT_SEG=Label.CoreZipDefault;

   public static Boolean processReferrals(List<PartnerWrapper> partnerWraps) {
      Boolean allOkay = true;
      setupRecordTypes();
  
      Referral_Contact__c[] insertRefCtcts = new Referral_Contact__c[]{};
      Referral_Contact__c[] updateRefCtcts = new Referral_Contact__c[]{};
      Lead[] insertLeadList = new Lead[]{};
      
      System.debug('processReferrals partnerWraps='+partnerWraps.size());

      for (PartnerWrapper partnerWrap: partnerWraps) {
         // for easier local reference
         //BankLead bankLd = partnerWrap.bankLd;
         PartnerReferral__c partRef = partnerWrap.partRef;
         if (partnerWrap.partnerBranch == null) {
            findPartnerBranch(partnerWrap);
         }
                  
         boolean foundRefAcct = (partnerWrap.partnerBranch != null);
         
         boolean phonebank = (partnerWrap.partnerBranch != null ? partnerWrap.partnerBranch.Phone_Bank__c : false);
         
         String zipToCheck = (!phoneBank && partRef.BranchZip__c != NULL ? partRef.BranchZip__c.left(5) : (partRef.ZipPostalCode__c != NULL ? partRef.ZipPostalCode__c.left(5) : ''));
         //System.debug('zipToCheck='+zipToCheck+' has 401k='+(partnerWrap.lead401 != null ? 'true' : 'false') + ' partnerWrap.partnerBranch='+partnerWrap.partnerBranch);
         partnerWrap.addToProcessNotes('zipToCheck='+zipToCheck+' has 401k='+(partnerWrap.lead401 != null ? 'true' : 'false'));
         
          //bankLd.fullName = bankLd.firstName + ' ' + bankLd.lastName;
         System.debug('processReferrals partnerWrap='+partnerWrap.fullName+' foundRefAcct='+foundRefAcct+' isPayroll='+partnerWrap.isPayroll+' is401k='+partnerWrap.is401k);

         //Determine Ownership Section
 
         System.debug('processReferrals partnerWrap.partnerHeadquarters='+partnerWrap.partnerHeadquarters);
          //APR0130800 : if Primary Zip Segment on Parent Referral Account is populated, use zip segment to assign owner
         if(partRef.CustomerForm__c && foundRefAcct && partRef.ZipPostalCode__c!=null && partnerWrap.partnerHeadquarters!= null && partnerWrap.partnerHeadquarters.Primary_Zip_Segment__c!= null){
            partnerWrap.addToProcessNotes('Using Primary Zip Segment'+partnerWrap.partnerHeadquarters.Primary_Zip_Segment__c);
            ZipWrapper zw = zipCodeLookupController.getZipAssignment(partRef.ZipPostalCode__c, UserHelper.SO_CORE, null, partnerWrap.partnerHeadquarters.Primary_Zip_Segment__c);
             partnerWrap.addToProcessNotes('Looking for primary zip segment rep zw='+(zw != null ? String.valueOf(zw.za.User__c) : 'Not Found for '+partnerWrap.partnerHeadquarters.Primary_Zip_Segment__c));
               if (zw != null) {
                    partnerWrap.addToProcessNotes('Using primary zip segment rep by zip code');
                    partnerWrap.setOwnerId(zw.za.user__c, true, false);   
               }
            System.debug('processReferrals partnerWrap.missingOwner()='+partnerWrap.missingOwner());
         }
         else{
            if (partnerWrap.missingOwner() && partRef.SalesRepFirstName__c != NULL && partRef.SalesRepLastName__c != NULL){
               System.debug('processReferrals looking for a sales rep');
               //Look for a Sales Rep if name is specified
               partnerWrap.addToProcessNotes('Using Sales Rep Name');
               partnerWrap.setOwnerId(findRepId(partRef.SalesRepFirstName__c,partRef.SalesRepLastName__c),true,false);
            } // if (partnerWrap.missingOwner
            System.debug('processReferrals after sales rep partnerWrap.missingOwner()='+partnerWrap.missingOwner());

            // if there's a payroll referral and there's a bank centric rep, use that as the owner.
            if (foundRefAcct && partnerWrap.partnerBranch.Bank_Centric_Rep__c != NULL && !phoneBank) {
               partnerWrap.addToProcessNotes('Using Bank Centric Rep');
               partnerWrap.setOwnerId(partnerWrap.partnerBranch.Bank_Centric_Rep__c, true, false);
            } // if (foundRefAcct       

            if (partnerWrap.lead401 != null && String.isNotBlank(zipToCheck) && zipToCheck.length() == 5 && (partnerWrap.partnerBranch == null ||  (partnerWrap.partnerBranch != null && partnerWrap.partnerBranch.Bank_Centric_Rep_401k__c == NULL))) {
               // pass in a null value for the object so it will always return the small market rep.
               ZipWrapper zw = zipCodeLookupController.getZipAssignment(zipToCheck, UserHelper.SO_401, null,Label.HRSSmallMarket);
               partnerWrap.addToProcessNotes('Looking for 401k rep zw='+(zw != null ? String.valueOf(zw.za.User__c) : 'Not Found for '+Label.HRSSmallMarket));
               if (zw != null) {
                  partnerWrap.addToProcessNotes('Using 401k rep by zip code');
                  partnerWrap.setOwnerId(zw.za.user__c, false, true);    
               }
            } // if (x401k
            else if(partnerWrap.lead401 != null && partnerWrap.partnerBranch != null && partnerWrap.partnerBranch.Bank_Centric_Rep_401k__c != NULL){
                  System.debug('Working for 401');
                  partnerWrap.lead401.OwnerId = null;
                  partnerWrap.setOwnerId(partnerWrap.partnerBranch.Bank_Centric_Rep_401k__c, false, true);
                  System.debug('The new Owner is: '+partnerWrap.lead401.OwnerId);
            }// end of getting the owner
          } //else
        // new code
        if (foundRefAcct) {
           if (partnerWrap.refCtct == null) {
                 partnerWrap.setRefCtct(findPartnerContact(partnerWrap, insertRefCtcts, updateRefCtcts));
           }
           System.debug('processReferrals refContact='+partnerWrap.refCtct);
           if (partnerWrap.refCtct != null) {
              Boolean ctctIsNew = partnerWrap.refCtct.Id == null;
              //l.Referral_Contact__c = bankLd.refCtct.Id;
              System.debug('processReferrals ctctIsNew='+ctctIsNew+' phoneBank='+phoneBank);
              if (partnerWrap.leadPay!= null && partnerWrap.leadPay.OwnerId == null && !phoneBank) {
                 Id ownerId = (ctctIsNew ? partnerWrap.partnerBranch.OwnerId : partnerWrap.refCtct.OwnerId);
                 partRef.ReferralOwnerId__c = ownerId;
                 partnerWrap.addToProcessNotes('Using OwnerId from Referral Source');
                 partnerWrap.setOwnerId(ownerId, true, false);
              } // if (partnerWrap.missingOwner()
              
              
              // if we haven't found the payroll rep, select based on the zip code
              if (partnerWrap.payrollOwnerId == null && String.isNotBlank(zipToCheck) && zipToCheck.length() == 5) {
                 ZipWrapper zw = zipCodeLookupController.getZipAssignment(zipToCheck, UserHelper.SO_CORE, partnerWrap.primaryLead,CORE_DEFAULT_SEG);
                 System.debug('processReferrals getPayrollOwner zip='+zipToCheck+' segment='+CORE_DEFAULT_SEG+' zw='+zw);
                 if (zw != null) {
                    partnerWrap.payrollOwnerId = zw.za.user__c;
                 }
              }
           } else {
                 partnerWrap.setExceptionReason('Referral Contact Does Not Exist in Salesforce. ', leadPendingRT.getRecordTypeId());
           }
        } else {
           partnerWrap.setExceptionReason('Unable to find Referral Account. ', leadPendingRT.getRecordTypeId());
        } // if (foundRefAcct)
        
     
         if (partnerWrap.missingOwner()) {
            partnerWrap.addToProcessNotes('Using default zip code ownership');
            partnerWrap.setDefaultOwnership();
         }
         insertLeadList.addAll(partnerWrap.getLeads());       
      } // for (Banklead bankLd
      System.debug('processReferrals insertLeadList='+insertLeadList.size());
        
      // since we already checked for dupes, don't check for dupes again when inserting the contact
      ReferralObjectsSync.CHECK_FOR_DUPES = false;
      DmlHelper.performDML(insertRefCtcts, DmlHelper.DML_INSERT, 'WebBankLeadHelper', 'processReferrals', 'inserting refCtcts', false);
      DmlHelper.performDML(updateRefCtcts, DmlHelper.DML_UPDATE, 'WebBankLeadHelper', 'processReferrals', 'updating refCtcts', false);
      
      Map<Id,Referral_Contact__c> refCtctMap = null;
      if (!insertRefCtcts.isEmpty()) {
         // reselect inserted referral_contacts to get the contact ids
         Id[] reselectRefCtctIds = new Id[]{};
         for (Referral_Contact__c refCtct : insertRefCtcts) {
            if (refCtct.Id != null) {
               reselectRefCtctIds.add(refCtct.Id);
            }
         }
         if (!reselectRefCtctIds.isEmpty()) {
            refCtctMap = new Map<Id,Referral_Contact__c>([Select Id, Name, Contact__c, Contact__r.Id, Contact__r.AccountId
                                               ,LeadSourceDefault__c, ReferralPartnerName__c, PrimaryReferralType__c
                                               ,Referral_Account__c, Referral_Account__r.Account__c
                                           from Referral_Contact__c where Id in :reselectRefCtctIds]);
         }
      }
      if (refCtctMap == null) {
         refCtctMap = new Map<Id,Referral_Contact__c>();
      }
      
      ReferralJoin__c[] newRefJoins = new ReferralJoin__c[]{};

      // get the ownerids and select the owners
      Id[] ownerIds = new Id[]{};
      for (PartnerWrapper partnerWrap : partnerWraps) {
         partnerWrap.checkForMultipleReferrals(newRefJoins);
         if (partnerWrap.refCtctIsNew) {
            if (partnerWrap.refCtct != null && partnerWrap.refCtct.Id != null) {
               Referral_Contact__c refCtct = refCtctMap.get(partnerWrap.refCtct.Id);
               partnerWrap.setRefCtct(refCtct != null ? refCtct : partnerWrap.refCtct);
            } else {
               System.debug('processReferrals refCtct was not created');
            }
         }
         // set the referral partner and leadsource after finding the branch.
         partnerWrap.checkLeadsAndReferrals();

         if (partnerWrap.payrollOwnerId != null) {
            ownerIds.add(partnerWrap.payrollOwnerId);
         }
      } // for (PartnerWrapper partnerWrap
      //Insert Leads and Referral Contacts, Check for Duplicates and Update leads, and Send EMail back to Submitter with Bank Lead ID  
      System.debug('processReferrals insertLeadList='+insertLeadList.size());
        
      if (!insertLeadList.isEmpty()) {
         leadDuplicateCheck(partnerWraps);

         allOkay = DmlHelper.performDML2(insertLeadList, DmlHelper.DML_INSERT, 'WebBankLeadHelper', 'processReferrals', 'insert new leads', true);
         if (!allOkay) {
            // if there's more than one record being processed at once, continue processing.
            if (partnerWraps.size() == 1) {
               Throw new WebBankLeadEmailHandler.BankEmailException('Unable to Insert Lead ' + DmlHelper.errorMsg);
            }   
         } // if (!allOkay
         //Try { 
            //insert leadsToInsert.values();
         //   insert insertLeadList;
         //} catch(Exception ex){
         //   Throw new WebBankLeadEmailHandler.BankEmailException('Unable to Insert Lead ' + ex);    
         //}
            
         // reselect the leads to get the Owner, Bank_Lead_id__c and other information
         Map<Id,Lead> reselectedLeadMap = new Map<Id,Lead>([Select Id, OwnerId
                                                                     ,Bank_Lead_id__c
                                                                     ,Bank_Product_Of_Interest__c
                                                                     ,City
                                                                     ,Company
                                                                     ,Current_Prior_Method__c
                                                                     ,Email
                                                                     ,FirstName
                                                                     ,Frequency__c
                                                                     ,LastName
                                                                     ,NumberOfEmployees
                                                                     ,Phone
                                                                     ,PostalCode
                                                                     ,RecordTypeId
                                                                     ,Referral_Contact__c
                                                                     ,State
                                                                     ,Street
                                                                 from Lead where Id in :insertLeadList]);
         
         for (Lead ld : reselectedLeadMap.values()) {
            ownerIds.add(ld.OwnerId);
         }
         Map<Id,User> ownerMap = new Map<Id,User>([Select Id, Name, DSA_FSS__c, ManagerId from User where Id in :ownerIds ]);
                   
         if (!newRefJoins.isEmpty()) {
            insert newRefJoins;
         }      
         finishBankLeads(partnerWraps, reselectedLeadMap, ownerMap);
      } // if(!leadsToInsert.isEmpty
      return allOkay;
   } // processReferrals
    
   public static Referral__c checkAddReferral(Referral_Partner__c refPartner, PartnerWrapper partnerWrap) {
      Referral__c referral = null;
      if (refPartner != null) {
         referral = new Referral__c(Name=partnerWrap.bankLd.fullName
                                    ,Referral_Partner__c=refPartner.Id
                                    ,Campaign__c=partnerWrap.bankLd.CampaignId
                                    ,Status__c='Pending');
      }
      return referral;
   } // checkAddReferral
   
   // finish the referral process. Generate emails, set campaign members, save referral objects.
   public static Boolean finishBankLeads(PartnerWrapper[] partnerWraps, Map<Id,Lead> reselectedLeadMap, Map<Id,User> ownerMap) {
      Boolean okay = true;
      // get the template for the email
      //APR0119329
      /*
      list<StaticResource> resourceList = [select body from StaticResource where name = 'BankRepEmail' Limit 1];
      StaticResource bankEmailResource = (!resourceList.isEmpty() ? resourceList[0] : null);
      */
      
      EmailTemplate template = [Select Id from EmailTemplate where Name = 'BANK-Referral Thank You' LIMIT 1];
      
      list<Messaging.SingleEmailMessage> emails = new list<Messaging.SingleEmailMessage>();
      
      CampaignMember[] newCampaignMembers = new CampaignMember[]{};
      
      Referral__c[] newReferrals = new Referral__c[]{};
      
      Id pendingRecordTypeId = PartnerWrapper.getPendingLeadRecordTypeId();
      
      for (PartnerWrapper partnerWrap : partnerWraps) {
         System.debug('partnerWrap.partRef before email = '+partnerWrap.partRef);
         //APR0119329
        /* Messaging.SingleEmailMessage email = createMail(partnerWrap.partRef, null);
           System.debug('email='+email); 
         */

         Lead[] reselectedLeads = new Lead[]{};
         for (Lead ld : partnerWrap.getLeads()) {
            Lead selectedLead = (ld.Id != null ? reselectedLeadMap.get(ld.Id) : null);
            if (selectedLead != null) {
               reselectedLeads.add(selectedLead);
            }
         } // for (Lead ld
         
         // use the reselected leads for the chatter messages because we want to make sure we have the correct ownerid.
         Lead leadPay = (partnerWrap.leadPay != null && partnerWrap.leadPay.Id != null ? reselectedLeadMap.get(partnerWrap.leadPay.Id) : null);
         Lead lead401 = (partnerWrap.lead401 != null && partnerWrap.lead401.Id != null ? reselectedLeadMap.get(partnerWrap.lead401.Id) : null);
         
         //APR0119329: Change static resource to email template
         Lead primaryLead = (leadPay != null ? leadPay : lead401);

         Messaging.SingleEmailMessage email = createMail(partnerWrap.partRef, primaryLead);
          System.debug('email='+email);

         if (email != null) {
            //String emailBody = createEmailBody(leadPay, lead401, bankEmailResource);
            //email.setHTMLBody(emailBody);    
            email.setTemplateId(template.Id);        
            emails.add(email);
         }

         partnerWrap.checkForCampaignMembers(newCampaignMembers);
         
         // close the record if coming from the BankReferral__c object
         if (partnerWrap.partRef != null) {
            partnerWrap.partRef.Processed__c = true;
            partnerWrap.partRef.ProcessReferral__c = false;
            partnerWrap.partRef.SubmitAsEmail__c = false;
         }
         
         partnerWrap.getReferrals(newReferrals);
         
         Lead[] chatterLeads = new Lead[]{};
         Set<Id> wrapperOwnerIdSet = new Set<Id>();
         System.debug('finishBankLeads partnerWrap.payrollOwnerId='+partnerWrap.payrollOwnerId);
         
         if (partnerWrap.payrollOwnerId != null) {
            wrapperOwnerIdSet.add(partnerWrap.payrollOwnerId);
         }
         if (leadPay != null && leadPay.RecordTypeId != pendingRecordTypeId) {
            wrapperOwnerIdSet.add(leadPay.OwnerId);
            chatterLeads.add(leadPay);
         }
         if (lead401 != null && lead401.RecordTypeId != pendingRecordTypeId) {
            wrapperOwnerIdSet.add(lead401.OwnerId);
            chatterLeads.add(lead401);
         }
         String leadType = (partnerWrap.refCtct != null ? partnerWrap.refCtct.PrimaryReferralType__c : '');
         system.debug('checking chatter messages chatterLeads='+chatterLeads+' wrapperOwnerIdSet='+wrapperOwnerIdSet+' ownerMap'+ownerMap+' leadType='+leadType);
         checkForChatterMessages(chatterLeads, wrapperOwnerIdSet, ownerMap, leadType);
      } // for (PartnerWrapper partnerWrap
      
      if (!Test.isRunningTest()) {
         ChatterMentionPost.postBatchFeedElements();
      }
      
      if (!newCampaignMembers.isEmpty()) {
         insert newCampaignMembers;
      }
      
      if (!newReferrals.isEmpty()) {
         insert newReferrals;
      }
      if (!emails.isEmpty()){
         try {
            Messaging.sendEmail(emails);
         } catch (Exception e) {
            System.debug('finishBankLeads exception: '+e.getMessage()+'; '+e.getStackTraceString());
            ErrorLog.logError('WebBankLeadHelper', 'finishBankLeads', 'sendEmail', null, e, null, true);
         }
      } // if (!emails.isEmpty
      
      return okay;
   } // finishBankLeads
   
   public static void checkForChatterMessages(Lead[] leads, Set<Id> wrapperOwnerIdSet, Map<Id,User> ownerMap, String p_leadType) {
      if (!leads.isEmpty()) {
         String leadType = (String.isBlank(p_leadType) ? '' : p_leadType);
         String message = '';
         Id[] referralContactIds = new Id[]{};
         if (leads.size() > 1) {
            String[] prods = new String[]{};
            //message = 
            for (Lead ld : leads) {
               prods.add((String.isBlank(ld.Bank_Product_of_interest__c) ? PartnerWrapper.PROD_INTEREST_PAYROLL : ld.Bank_Product_of_interest__c));
            } // for (Lead ld : leads
            message = 'New '+leadType+' Leads were entered in Salesforce for '+String.join(prods,' and' )+'.\n';
         } else {
            message = 'A New '+leadType+' Lead was entered in Salesforce for you. \n';
         } // if (leads.size() > 1
         System.debug('checkForChatterMessages leadType='+leadType+' ld.Referral_Contact__c: '+leads[0].Referral_Contact__c);
         if(leadType == 'CPA' && !leads.isEmpty() && leads[0].Referral_Contact__c != null) {
            Referral_Contact__c refCont = [SELECT Id, Name, Referral_Account__c
                                              , Referral_Account__r.Name, Referral_Account__r.CPA_Relationship_Manager__c, Referral_Account__r.OwnerId,
                                               Referral_Account__r.Account__c 
                                               FROM Referral_Contact__c WHERE Id = :leads[0].Referral_Contact__c AND Referral_Account__c != null LIMIT 1];
            message += '\n Congratulations you have received a referral from '+refCont.Name+' at '+refCont.Referral_Account__r.Name+'!  ***Do not create a new Lead.*** Update this lead through your sales process.';
         } else {
            message += ChatterMentionPost.buildChatterMessage(leads[0]);
         }
         for (lead ld : leads) {
            List<Id> userToMentionIdList = getUsersToMention(ld, wrapperOwnerIdSet, ownerMap.get(ld.OwnerId));
            
            ChatterMentionPost.createChatterMentionPost(ld.Id, userToMentionIdList, new String[]{message}, false, false);
         } // for (Lead ld
      } // if (!leads.isEmpty
   } // checkForChatterMessages

   public static List<Id> getUsersToMention(Lead ld, Set<Id> wrapperOwnerIdSet, User usr) {
      List<Id> userIdsToMention = new List<Id>();
      // all of the ownerids should be in the set.
      userIdsToMention.addAll(wrapperOwnerIdSet);
      if (usr != null) {
         //userIdsToMention.add(usr.Id);
         if (usr.ManagerId != null) {
            userIdsToMention.add(usr.ManagerId);
         }
         if (usr.DSA_FSS__c != null) {
            userIdsToMention.add(usr.DSA_FSS__c);
         }
      }
      return userIdsToMention;
   } // getUsersToMention
   
/*   //APR0119329
   public static String createEmailBody(Lead leadPay, Lead lead401, StaticResource bankEmailResource) {
      Lead primaryLead = (leadPay != null ? leadPay : lead401);
      String emailBody = '';
      if (primaryLead != null) {
      
         String firstName = primaryLead.FirstName;
         String lastName = primaryLead.LastName;
         String companyName =  primaryLead.Company;

         String fullName = (firstName == null ? '' : firstName+' ')+(lastName == null ? '' : lastName+' ')
                          + (companyName == Null?'':' (' +companyName + ')');

         String bankLeadId = (leadPay != null ? leadPay.Bank_Lead_Id__c : '');
         if (lead401 != null) {
            bankLeadId += (leadPay != null ? ' and ' : '');
            bankLeadId += lead401.Bank_Lead_Id__c+' for 401(k)';
         }
         
         if (bankEmailResource != null){
            try {
               emailBody = bankEmailResource.body.toString();
               emailBody = emailBody.replaceFirst('JGSLeadName',fullName+(lead401 != null ? ' for 401(k)' : ''));
               emailBody = emailBody.replaceFirst('JGSBankLeadID',bankLeadId);
            } catch (Exception e) {
               System.debug('createEmailBody exception: '+e.getStackTraceString());
               emailBody = '';
            } 
         } // if (bankEmailResource != null
            
         if (String.isBlank(emailBody)) {
            emailBody = '<body>Thank you for referring ' + fullName;
            emailBody += ' to Paychex.<br/><br/>Please keep the following reference number for your records:<br/>';
            emailBody += bankLeadId;
            emailBody += '<br/><br/>Thank You,<br/>Paychex</body>';
         }
      } // if (primaryLead
      return emailBody;
   } // createEmailBody
*/

/*
   public static Integer COMMENTS_LENGTH=Lead.Comment__c.getDescribe().getLength();

   public static Lead createLead(PartnerWrapper partnerWrap, Boolean is401k) {
      BankLead bankLd = partnerWrap.bankLd;
      PartnerReferral__c partRef = partnerWrap.partRef;
      lead ld = new lead(RecordTypeId = (is401k ? leadHRSRT.getRecordTypeId() : leadCoreRT.getRecordTypeId())
                                    , Bank_Product_of_Interest__c = (is401k ? PartnerWrapper.PROD_INTEREST_401k : NULL)
                                    , Products__c = (is401k ? PROD_401k : NULL)
                                    , Duplicate_OK__c = true
                                    , Generate_Bank_Lead_Id__c = true
                                    , Hold_Out__c = true
                                    , Hold_Out_Expiration__c = system.today().addDays(90)
                                    , LastName =  partRef.LastName__c //bankLd.lastName
                                    , FirstName = partRef.FirstName__c //bankLd.firstName
                                    , Company = partRef.Company__c //bankLd.company
                                    , Email = partRef.Email__c //bankLd.email
                                    , Phone = partRef.Phone__c //bankLd.phone
                                    , Street = partRef.StreetAddress__c //bankLd.street
                                    , City = partRef.City__c // bankLd.city
                                    , State = partRef.State__c // bankLd.state
                                    , PostalCode = partRef.ZipPostalCode__c // bankLd.zip
                                    , Promo_Code__c = partRef.PromoCode__c //bankLd.promocode
                                    , Title = partRef.Title__c //bankLd.title                                  
                                    , NumberOfEmployees = (partRef.NumberOfEmployees__c != null ? Integer.valueOf(partRef.NumberOfEmployees__c) : null) //bankLd.NumOfEmployees
                                    , Comment__c = (String.isNotBlank(partRef.Comments__c) ? partRef.Comments__c.left(COMMENTS_LENGTH) : null)
                                    , LeadSource = Label.LeadSource_ReferralBank
                                    , Additional_Referring_Name__c = partRef.AdditionalReferringName__c //bankLd.AdditionalReferringName
                                    , Additional_Referring_EmpId__c = partRef.AdditionalReferringEmpId__c //bankLd.AdditionalReferringEmpId
                                    , Line_Of_Business__c = bankLd.lineOfBusiness
                                    , Date_Lead_Submitted__c = system.today()
                                    , Original_Bank_Submitter__c = partRef.EmpFirstName__c+' '+partRef.EmpLastName__c //bankLd.refEmployeeFirstName + ' ' + bankLd.refEmployeeLastName
                                    , Original_Bank_Emp_Number__c = partRef.EmployeeId__c //bankLd.EmployeeID
                                    , Original_Bank_Branch_Name__c = partRef.BranchName__c //bankLd.branchName
                                    , Original_Bank_Branch_Number__c = partRef.BranchNumber__c //bankLd.branchNumber
                                    , Original_Lead_Detail__c = partnerWrap.getLeadDetail(is401k)
                                    , DoNotUseBankTriggerChatter__c = true  // so that the trigger code won't generate a chatter message
                                    );
      return ld;
   } // createLead
   */
   public static void findPartnerBranch(PartnerWrapper partnerWrap) {
      PartnerReferral__c partRef = partnerWrap.partRef;
      //Find Ref Account and look for Centric Rep
      //if (String.isNotBlank(partRef.PartnerName__c) && String.isNotBlank(partRef.BranchName__c) && String.isNotBlank(partRef.BranchZip__c)) {
         
      Boolean hasBranchName = (String.isNotBlank(partRef.PartnerName__c) && String.isNotBlank(partRef.BranchName__c));
      Boolean hasHeadquarters = (partnerWrap.partnerHeadquarters != null);
      Boolean hasBranchZip = (String.isNotBlank(partRef.BranchZip__c));
      Boolean hasBranchNbr = (String.isNotBlank(partRef.BranchNumber__c));
      Boolean hasVendorId = (partRef.Vendor_ID__c!= null);
         
      // needs at least the branch name - preferably with at least one other criteria
      Boolean hasEnoughCriteria = ((hasBranchName && (hasBranchZip || hasBranchNbr)) || hasVendorId);
      //Boolean hasEnoughCriteria = ((hasHeadquarters && (hasBranchName || hasBranchZip || hasBranchNbr))
      //                             || (hasBranchName && (hasBranchZip || hasBranchNbr))
      //                            );

      System.debug('findPartnerBranch hasEnoughCriteria='+hasEnoughCriteria+' hasHeadquarters='+hasHeadquarters+' hasBranchName='+hasBranchName+' hasBranchZip='+hasBranchZip+' hasBranchNbr='+hasBranchNbr);
      if (hasEnoughCriteria) {
         String query = 'Select Id, Name, OwnerId, Owner.Id, Bank_Branch_Number__c '+
                       ',Bank_Centric_Rep__c, Bank_Centric_Rep_401k__c, Phone_Bank__c, Zip_Postal_Code__c '+
                       ',Referral_Type__c'+
                       ',Referral_Source_Business_Type__c'+
                       ',Parent_Referral_Account__c'+
                       ',Primary_Zip_Segment__c'+
                       ',Parent_Referral_Account__r.Id, Parent_Referral_Account__r.Account__c'+
                       ',Parent_Referral_Account__r.PartnerId__c'+
                       ',Parent_Referral_Account__r.Referral_Type__c'+
                       ',Parent_Referral_Account__r.Referral_Source_Business_Type__c'+
                       ',Parent_Referral_Account__r.Primary_Zip_Segment__c'+
                       ',Account__c'+
                       ' FROM Referral_Account__c  WHERE ';
         String joinCriteria = '';
         String whereClause = ''; 
         if (hasHeadquarters) {
            whereClause += ' Parent_Referral_Account__c=\''+partnerWrap.partnerHeadquarters.Id+'\' ';
            joinCriteria = ' and ';
         }
         if (hasBranchName) {
            whereClause += (joinCriteria + ' Name=\''+String.escapeSingleQuotes(partRef.PartnerName__c + ' - '+partRef.BranchName__c)+'\' ');
            joinCriteria = ' and ';
            //whereClause += (hasHeadquarters ? ' and ( ' : '') +' Name=\''+String.escapeSingleQuotes(partRef.PartnerName__c + ' - '+partRef.BranchName__c)+'\' ';
            //whereClause += (hasHeadquarters ? '' : ' and (');
            //joinCriteria = (hasHeadquarters ? ' or ' : '');
         //} else {
         //   whereClause += ' and (';
         }
         if (hasBranchZip && !hasVendorId) {
            String zipCode = String.escapeSingleQuotes(partRef.BranchZip__c).left(5)+'%';
            whereClause += (joinCriteria + 'Zip_Postal_Code__c like \''+zipCode+'\' ');
            //joinCriteria = ' or ';
            joinCriteria = ' and ';
         }
         String[] branchNbrList = new String[]{};
         if (hasBranchNbr && !hasVendorId) {
            // some branch numbers are zero padded - try to account for multiple instances
            branchNbrList.add(partRef.BranchNumber__c);
            branchNbrList.add('0'+partRef.BranchNumber__c);
            branchNbrList.add('00'+partRef.BranchNumber__c);
            branchNbrList.add('000'+partRef.BranchNumber__c);
            System.debug('findPartnerBranch branchNbrList='+branchNbrList);
            whereClause += joinCriteria + 'Bank_Branch_Number__c in :branchNbrList ';
            //query += joinCriteria +'Bank_Branch_Number__c = \''+String.escapeSingleQuotes(partRef.BranchNumber__c)+'\' ';
         }
         //whereClause += ')'; //(hasHeadquarters ? '))' : ')');
         if(hasVendorId){
             whereClause += joinCriteria + '( Parent_Referral_Account__r.PartnerId__c=\''+partRef.Vendor_ID__c+'\' or PartnerId__c=\''+partRef.Vendor_ID__c+'\' )';
         }
         
         partnerWrap.addToProcessNotes(whereClause);
         
         query += whereClause;
         query += ' limit 1';
         System.debug('findPartnerBranch query='+query);
         list<Referral_Account__c> refAccountList =  Database.query(query);
         partnerWrap.setPartnerBranch(!refAccountList.isEmpty() ? refAccountList[0] : null);
      } // if (hasEnoughCriteria                       

   } // findPartnerBranch
   
   public static Referral_Contact__c findPartnerContact(PartnerWrapper partnerWrap
                    ,Referral_Contact__c[] insertRefCtcts
                    ,Referral_Contact__c[] updateRefCtcts) {
      PartnerReferral__c partRef = partnerWrap.partRef;
      Referral_Contact__c refCtct = null;
      Id refCtctId = null;
      System.debug('findPartnerContact partRef='+partRef);
      
      String firstName = (partRef.CustomerForm__c ? 'Default' : partRef.EmpFirstName__c);
      String lastName = (partRef.CustomerForm__c ? 'Employee' : partRef.EmpLastName__c);
      String phone = (partRef.CustomerForm__c ? '585-555-5555' : partRef.EmpPhone__c); 
      String email = (partRef.CustomerForm__c ? 'defaultemployee@defaultemployee.com' : partRef.EmpEmail__c); 
                        
      Id acctId = (partRef.CustomerForm__c
                            ? (partnerWrap.partnerHeadquarters != null ? partnerWrap.partnerHeadquarters.Id : null)
                            : (partnerWrap.partnerBranch != null ? partnerWrap.partnerBranch.Id : null));
      
      if (acctId != null && String.isNotBlank(firstName) && String.isNotBlank(lastName)) {
         Referral_Contact__c searchRefContact = new Referral_Contact__c(Referral_Account__c = acctId
                                                  ,Name = firstName + ' ' + lastName
                                                  ,Last_Name__c = lastName
                                                  ,First_Name__c = firstName
                                                  ,Phone__c = phone
                                                  ,Email__c = email
                                                  ,OwnerId = partnerWrap.partnerBranch.OwnerId
                                                  ,Employee_Number__c = partRef.EmployeeId__c); 
                                                                                                      
         list<Referral_Contact__c> rcList = new list<Referral_Contact__c>();
         rcList.add(searchRefContact);
         //Map<Referral_Contact__c, list<Contact>> dupeBlockerMap = ReferralObjectsSync.dupeContactChecker(rcList);
         DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(rcList);
         if(results == null || results.isEmpty() || !results[0].hasResults){
            refCtct = searchRefContact;
            System.debug('findPartnerContact no existing contacts found - creating a new one');
            insertRefCtcts.add(refCtct);
         }
         else{
            DuplicateHelper.DupeResult result = results[0];
            if (result.hasResults && !result.refCtctIds.isEmpty()) {
              refCtctId = result.refCtctIds[0];
                if(refCtctId != null){
                    refCtct = [SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone__c, OwnerId, Contact_ID__c,ReferralPartnerName__c,PrimaryReferralType__c,LeadSourceDefault__c,Referral_Account__c,Contact__c,Contact__r.AccountId,Employee_Number__c,End_Date__c FROM Referral_Contact__c WHERE Id = :refCtctId LIMIT 1];
                }
            }
            if (refCtct != null && (String.isBlank(refCtct.Email__c) || String.isBlank(refCtct.Employee_Number__c) || refCtct.End_Date__c != null)) {
                  updateRefCtcts.add(refCtct);
                  refCtct.Email__c = partRef.EmpEmail__c;  
                  refCtct.Employee_Number__c = partRef.EmployeeId__c;
                  refCtct.End_Date__c = NULL;
               } // if (String.isBlank
         }
                    
         /*if (ctcts == null || ctcts.isEmpty()) {
            //If no Referral Contact is found and the fields are not Null, create a new one
            refCtct = searchRefContact;
            System.debug('findPartnerContact no existing contacts found - creating a new one');
            insertRefCtcts.add(refCtct);

         } else {
            // there are records returned
            set<id> rcIds = new set<id>();
            for (contact cntct : ctcts) {
               System.debug('findPartnerContact cntct='+cntct);
               if(cntct != null && cntct.Ref_Contact_ID__c != null){
                  rcIds.add(cntct.Ref_Contact_ID__c);
               }    
            } // for
            System.debug('findPartnerContact rcIds='+rcIds.size());
            if (!rcIds.isEmpty()) {
               Referral_Contact__c[] refCtcts = [Select Id, OwnerID, Employee_Number__c, Email__c, End_Date__c
                                ,LeadSourceDefault__c, ReferralPartnerName__c, PrimaryReferralType__c
                                ,Referral_Account__c
                                ,Contact__c, Contact__r.AccountId
                            From Referral_Contact__c 
                           where Id in :rcIds Order by CreatedDate DESC limit 5];
               if (refCtcts.size() > 1 && String.isNotBlank(partRef.EmployeeId__c)) {
                  // see if there's a match by employee id
                  for (Referral_Contact__c checkRefCtct : refCtcts) {
                     if (checkRefCtct.Employee_Number__c == partRef.EmployeeId__c) {
                        refCtct = checkRefCtct;
                        break;
                     }
                  } // for (Referral_Contact__c checkRefCtct
               } // if (refCtcts.size
                
               if (refCtct == null) {
                  refCtct = refCtcts[0];
               }
                        
               if (String.isBlank(refCtct.Email__c) || String.isBlank(refCtct.Employee_Number__c) || refCtct.End_Date__c != null) {
                  updateRefCtcts.add(refCtct);
                  refCtct.Email__c = partRef.EmpEmail__c;  
                  refCtct.Employee_Number__c = partRef.EmployeeId__c;
                  refCtct.End_Date__c = NULL;
               } // if (String.isBlank
            } // if (!rcIds.isEmpty
         }*/
      } else {
         System.debug('findPartnerContact not enough criteria to search for contact! EmpFirstName__c='+partRef.EmpFirstName__c+' EmpLastName__c='+partRef.EmpLastName__c+'EmpEmail__c='+partRef.EmpEmail__c+' EmpPhone__c='+partRef.EmpPhone__c+' partnerBranch='+partnerWrap.partnerBranch); 
      } // if (bankLd.refEmployeePhone

      return refCtct;
   } // findPartnerContact

   // Create Basic Email - Used mostly to store the To address so that the email processing can be completed outside of the main for loop.
   private static Messaging.SingleEmailMessage createMail(PartnerReferral__c partRef, lead l){
      Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
      String[] emails = new String[]{};
      
      // if not in production, do not send to the EmpEmail__c - safety measure!
      String sandboxName = Utilities.checkForProduction();
      // this will be blank if we're in production
      if (String.isNotBlank(sandboxName)) {
         // we are in a sandbox - use the custom setting to get the emails to send to - semi colon separated email addresses
         PaychexSettings__c payxSetting = PaychexSettings__c.getInstance('ReferralSandboxEmails');
         if (payxSetting != null && String.isNotBlank(payxSetting.Attribute1__c)) {
            emails.addAll(payxSetting.Attribute1__c.split(';'));
         }
      } else if (String.isNotBlank(partRef.EmpEmail__c)) {
         // we're in production
         emails.add(partRef.EmpEmail__c);
         if (String.isNotBlank(partRef.AdditionalReferringEmail__c)) {
            emails.add(partRef.AdditionalReferringEmail__c);
         }
      } // if (String.isNotBlank
      if (!emails.isEmpty()){
         //APR0119329 
         mail.setToAddresses (emails);
         //mail.setSubject ('Paychex Referral');
         mail.setTargetObjectId(l.Id); 
         mail.setTreatTargetObjectAsRecipient(false);
         Bank_Email__c bankEmail = Bank_Email__c.getOrgDefaults();
         if (String.isNotBlank(bankEmail.Org_Wide_Email__c)){
            mail.setOrgWideEmailAddressId(bankEmail.Org_Wide_Email__c);
         }    
      } else{
         //mail.setToAddresses (new String[]{Label.Bank_Lead_No_Emp_Email});
         //mail.setSubject ('No refEmployeeEmail specified for bank referral');
         // don't send an email if there isn't an email address.
         mail = null;
      }
      return mail;
   } // createMail
    
    // Search for a rep if a First and Last Name is provided
    private static Id findRepId(string firstName, string lastName){
        Id repId = NULL;
        list<user> owners = [select id 
                                From user 
                                Where lastName = :lastName 
                                and firstName = :firstName 
                                and isActive = TRUE
                                and Sales_Org__c in :UserHelper.DIVISION_LIST_SET];
        if (!owners.isEmpty() && owners.size() == 1){
            repId = owners[0].id;
        } 
        return repId;   
    } // findRepId

   // for testing purposes when no data in sandbox
   public static Id DUPE_OVERRIDE_ID = null;
   
   public static void leadDuplicateCheck(List<PartnerWrapper> partnerWraps) {
      // 
      Map<Id,PartnerWrapper> leadIdWrapperMap = new Map<Id,PartnerWrapper>();
      Map<Id,PartnerWrapper> acctIdWrapperMap = new Map<Id,PartnerWrapper>();
      PartnerWrapper[] dupesFound = new PartnerWrapper[]{};
      Boolean isDupeBlockerSetup = Utilities.checkDupeBlocker('Lead');

      System.debug('leadDuplicateCheck partnerWraps='+partnerWraps.size());
      for (PartnerWrapper partnerWrap : partnerWraps) {
         Lead checkLead = partnerWrap.primaryLead;
         System.debug('leadDuplicateCheck checkLead='+checkLead);
         if (checkLead != null) {
            DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(new Lead[]{checkLead}); 
            if (!results.isEmpty()) {
               DuplicateHelper.DupeResult result = results[0];
               if (result.hasResults) {
                  for (Id leadId : result.leadIds) {
                     leadIdWrapperMap.put(leadId,partnerWrap);
                  }
                  for (Id acctId : result.acctIds) {
                     acctIdWrapperMap.put(acctId,partnerWrap);
                  }
               }
            } // if (!results.isEmpty
            /*
            List<CRMfusionDBR101.DB_Api.Matches> matchSets = CRMfusionDBR101.DB_Api.findMatches( checkLead );
            System.debug('leadDuplicateCheck matchSets='+matchSets.size());

            if (matchSets.isEmpty()) {
               // handle running in test where there's no data available - match data not available when seeAllData=false
               if (Test.isRunningTest() && DUPE_OVERRIDE_ID != null) {
                  System.debug('leadDuplicateCheck setting ids for testing');
                  checkMatchId(partnerWrap, new Set<Id>{DUPE_OVERRIDE_ID}, dupesFound, leadIdWrapperMap, acctIdWrapperMap);
               }
            } else {
               for (CRMfusionDBR101.DB_Api.Matches matchSet : matchSets ){
                  System.debug('leadDuplicateCheck matchSet.matchedIds isEmpty='+matchSet.matchedIds.isEmpty());
                  if (!matchSet.matchedIds.isEmpty()) {
                     checkMatchId(partnerWrap, matchSet.matchedIds, dupesFound, leadIdWrapperMap, acctIdWrapperMap);
                  } // if (!matchSet.matchedIds.isEmpty
               } // for (CRMfusionDBR101.DB_Api.Matches matchSet
            }
            */
         } // if (primaryLead != null
      } // for (PartnerWrapper partnerWrap 
      
      System.debug('leadDuplicateCheck leadIdWrapperMap='+leadIdWrapperMap.size());
      if (!leadIdWrapperMap.isEmpty()) {
         list<lead> existingLeads = [Select Date_Lead_Submitted__c,
                                            createdDate,
                                            Id,
                                            Bank_Product_of_Interest__c,
                                            Products__c 
                                       From Lead 
                                      Where Id in :leadIdWrapperMap.keySet() 
                                      Order by createdDate Asc];
         System.debug('leadDuplicateCheck existingLeads='+existingLeads.size());
         for (lead existingLead : existingLeads){
            PartnerWrapper partnerWrap = leadIdWrapperMap.get(existingLead.Id);
            if (partnerWrap != null) {
               checkLeadDupe(partnerWrap, existingLead);
            }
         } // for (lead existingLead
      } // if (!pdLeadIdMap.isEmpty

      System.debug('leadDuplicateCheck acctIdWrapperMap='+acctIdWrapperMap.size());
      if (!acctIdWrapperMap.isEmpty()) {
         list<account> existingAccounts = [Select
                                            Id,
                                            (select Id, recordType.name from opportunities) 
                                            From account 
                                            Where Id in :acctIdWrapperMap.keySet() 
                                            Order by createdDate Asc];
         if(!existingAccounts.isEmpty()){
            for (Account existingAcct: existingAccounts){
               PartnerWrapper partnerWrap = acctIdWrapperMap.get(existingAcct.Id);
               //warningMapAccount.put(existingAcct, leadWrap.newLead.id);
               if (partnerWrap != null && !partnerWrap.dupeFound) {
                  checkAcctDupe(partnerWrap, existingAcct);
               }
            } // or (Account existingAcct
         } // if(!existingAccounts
      } // if (!pdAcctIdMap.isEmpty

   } // leadDuplicateCheck
   /*
   public static void checkMatchId(PartnerWrapper partnerWrap, Set<Id> checkIdSet, PartnerWrapper[] dupesFound
                                  ,Map<Id,PartnerWrapper> leadIdWrapperMap
                                  ,Map<Id,PartnerWrapper> acctIdWrapperMap) {

      dupesFound.add(partnerWrap);
      for (Id id : checkIdSet ){
         if(id.getSobjectType() == Schema.Lead.SObjectType){
            //pdLeadIDMap.put(id,ld);
            System.debug('checkMatchId add lead match');
            leadIdWrapperMap.put(id,partnerWrap);
            //leadWrap.leadMatchIds.add(id);
         } else if(id.getSobjectType() == Schema.Account.SObjectType){
            //pdAcctIDMap.put(id,ld);
            System.debug('checkMatchId add account match');
            acctIdWrapperMap.put(id,partnerWrap);
            //leadWrap.acctMatchIds.add(id);
         }
      } // for (Id i

   } // checkMatchId
   */
   public static Boolean checkLeadDupe(PartnerWrapper partnerWrap, Lead existingLead) {
      Boolean dupeFoundPay = checkLeadDupe(partnerWrap.leadPay,existingLead);
      Boolean dupeFound401 = checkLeadDupe(partnerWrap.lead401,existingLead);
      partnerWrap.setDuplicate((dupeFoundPay || dupeFound401),existingLead, null);
      return true;
   } // checkLeadDupe
   
   public static Boolean checkLeadDupe(Lead newLead, Lead existingLead) {
      
      Boolean dupeFound = (newLead != null && ((newLead.Bank_Product_of_Interest__c == existingLead.Bank_Product_of_Interest__c)
                                  || (newLead.Bank_Product_of_Interest__c == PartnerWrapper.PROD_INTEREST_401k && existingLead.Products__c == '401K')
                                  || (newLead.Bank_Product_of_Interest__c == PartnerWrapper.PROD_INTEREST_PAYROLL && String.isBlank(existingLead.Bank_Product_of_Interest__c))
                           ));
      System.debug('checkLeadDupe dupeFound='+dupeFound);
      if (dupeFound) {
         String exceptionReason = 'Lead Already Exists in Salesforce';
         if (existingLead.createdDate <= system.today().addMonths(-6)) {
            System.debug('checkLeadDup Lead Exists, but more than 6 months old');
            exceptionReason = 'Lead Exists, but more than 6 months old';
         }
         newLead.Exception_Reason__c = exceptionReason;
         newLead.RecordTypeId = leadPendingRT.getRecordTypeId();
         newLead.Original_Lead_Detail__c = (newLead.Original_Lead_Detail__c + ', Pre-Existing Lead Id: ' + existingLead.id).left(PartnerWrapper.LEAD_DETAIL_LENGTH);
         System.debug('checkLeadDupe exception reason='+newLead.Exception_Reason__c);
      } // if (dupeFound
      return dupeFound;
   } // checkLeadDupe

   public static Boolean checkAcctDupe(PartnerWrapper partnerWrap, Account existingAcct) {
      Boolean dupeFoundPay = checkAcctDupe(partnerWrap.leadPay,existingAcct);
      Boolean dupeFound401 = checkAcctDupe(partnerWrap.lead401,existingAcct);
      partnerWrap.setDuplicate((dupeFoundPay || dupeFound401),null, existingAcct);
      return true;
   } // checkAcctDupe
   
   public static Boolean checkAcctDupe(lead newLead, Account existingAcct) {
      Boolean dupeFound = false;
      String exceptionReason = null;
      
      if (newLead != null) {
         if (newLead.Bank_Product_of_Interest__c != PartnerWrapper.PROD_INTEREST_401k){                         
            exceptionReason = 'Contact or P-C Already Exists in Salesforce.';
            dupeFound = true;
         } else {
            Boolean has401kOppty = FALSE;
            for (opportunity o:  existingAcct.opportunities) {
               // does a 401k opportunity exist?
               if (o.recordType.Name == OpportunityCreateCase.RT_OPPTY_401K_FSS 
                    || o.recordType.Name == OpportunityCreateCase.RT_OPPTY_401K_FSS ) {
                  has401kOppty = TRUE;
                  break;
               }
            } // for   
            if (has401kOppty) {
               exceptionReason = 'P-C Already Exists with 401(k) Opportunity.';
               dupeFound = true;
            }
         } // if(leadWrap.newLead.Bank_Product_of_Interest__c
      } // if (newLead != null
      
      if (dupeFound) {
         newLead.Exception_Reason__c = exceptionReason;
         newLead.Original_Lead_Detail__c += ', Existing Prospect-Client Id: ' + existingAcct.id;
         newLead.RecordTypeId = leadPendingRT.getRecordTypeId();
      }
      return dupeFound;
   } // checkAcctDup

/*

            map<lead,list<lead>> additionalChatterMap = new map<lead,list<lead>>();
            list<lead> primaryLeadList = new list<lead>();
            set<id> idSet = new set<id>();
            if(leadsToInsertList.size() > 1){
                for(lead l:leadsToInsertList){
                    idSet.add(l.id);        
                }
                list<lead> insertedLeads= [Select id, ownerId, RecordTypeId, company, Bank_Product_of_interest__c from Lead where id in:idSet];
                for(lead l:insertedLeads){
                    if(l.Bank_Product_of_interest__c == NULL){
                        additionalChatterMap.put(l,new List<lead>());       
                    }
                }
                for(lead pLead: additionalChatterMap.keySet()){
                    list<id> idList = new list<id>();
                    list<lead> leadList = new list<lead>();
                    for(lead l:insertedLeads){
                        if(l.company == pLead.company){
                            idList.add(l.OwnerId);
                            leadList.add(l);    
                        }
                    }
                    for(lead l:leadList){
                        if(l.RecordTypeId != leadPendingRT.getRecordTypeId()){
                            string cText = 'Please note that this ' + (l.Bank_Product_of_interest__c == NULL ? 'Payroll' : l.Bank_Product_of_interest__c) + ' lead was also created for ' + l.company + '.';
                            chatterMentionPost.createChatterMentionPost(l.id, idList, cText);
                        }
                    }
                }
            }
            
            
*/


} // class WebBankLeadHelper