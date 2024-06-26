/* 
 * Queries used for setting referrals
 * 

FieldSets used
--------------
Schema.SObjectType.Account.fieldSets.ReferralQueries_Flds
Schema.SObjectType.Account.fieldSets.ReferralQueries_SalesParent
Schema.SObjectType.Campaign.fieldSets.ReferralQueries_Flds
Schema.SObjectType.Contact.fieldSets.ReferralQueries_Flds
Schema.SObjectType.Contact.fieldSets.ReferralQueries_ShortList
Schema.SObjectType.Lead.fieldSets.ReferralQueries_Flds
Schema.SObjectType.PartnerReferral__c.fieldSets.ReferralQueries_Flds
Schema.SObjectType.Prospect_Ownership__c.fieldSets.ReferralQueries_Flds
Schema.SObjectType.Referral_Contact__c.fieldSets.ReferralQueries_Flds
Schema.SObjectType.User.fieldSets.ReferralQueries_Flds

queries were commented out 12/23/2021 and could be deleted the next time we release this to prod if there are no side effects.

 *
 * History
 * -------
 * 10/09/2013 Dan Carmen   Created
   12/19/2014 Dan Carmen        Consolidated methods coming from the lead
   07/23/2015 Dan Carmen        Add fields to the lead query
   02/23/2016 Cindy Freeman     added Hold Out expiration dates to Account query
   02/25/2016 Cindy Freeman     added MS Hold Out and expiration date to Account query
   03/28/2016 Cindy Freeman     added Always_Check_Send_Email__c to Referral Partner query
   05/23/2016 Dan Carmen        Added Product_Division__c to lead query
   06/09/2016 Cindy Freeman     Added Default Zip to Referral Partner query
   10/20/2016 Dan Carmen        Add additional debug statements
   01/18/2017 Dan Carmen        Add additional fields to the queries.
   02/21/2017 Cindy Freeman     Add Employees__c to queries.
   05/17/2017 Dan Carmen        Add additional fields to Referral_Partner__c query and additional criteria to Partner_Referral subqueries.
   09/12/2017 Cindy Freeman      Add permanent hold put description fields to Account queries
   12/20/2017 Cindy Freeman      Add consent to text fields to Lead and Contact queries
   03/05/2018 Dan Carmen         Removed Partner Referral from the queries - they'll be queried separately when needed
   03/07/2018 Frank Lurz         Add additional Account.SalesParent__r fields
   08/14/2018 Cindy Freeman       Added Title to selectAcctMap query
   08/22/2018 Dan Carmen         Add Marketo_Lead_Rating__c to queries
   10/03/2018 Cindy Freeman       added ASO_Partner__c to selectAcctMap
   10/04/2018 Cindy Freeman       added several ASO_Partner__r fields to selectAcctMap query
   10/08/2018 Cindy Freeman       adding more fields for ASO_Partner__r in selectAcctMap query
   11/07/2018 Dan Carmen          Added in CreatedDate for Lead query.
   12/06/2018 Dan Carmen          Replace qbdialer__LastCallTime__c with LatestCallTime__c
   02/11/2019 Dan Carmen          Added TimeZoneAbbrev__c/TimeZoneName__c to queries
   05/13/2019 Jake Hinds          Adding product division
   11/08/2019 Cindy Freeman       Added Bank_Product_Of_Interest__c to Lead query for chatter posts
   02/05/2020 Dan Carmen          Clean up groupPartners method
   04/09/2020 Manmeet Vaseer      Added Account.SalesParent__r.Type and SalesParent__r.Owner.HR_Person_Id__c fields.
   05/21/2020 Brandon Vidro       Removed instances of Has_Sensitivity_HRS__c per Case #35267794
   05/26/2020 Dan Carmen          Change to use FieldSet for Referral_Partner__c query
   07/06/2020 Dan Carmen          Add fields to account/contact queries 
   10/16/2020 Dan Carmen          Add MktgId__c to contact and lead queries
   05/07/2021 Josh Cartwright     Add PEO_Potential_Indicator__c to accountmap()  
   07/19/2021 Jermaine Stukes     Add Hr Service Partner to selectAcctMap()
   12/22/2021 Dan Carmen          Add additional Latest Campaign fields to the query
   04/11/2022 Carrie Marciano	  Added fldSet.add('SalesParent__r.RecordType.Name')
   05/10/2023 Dan Carmen          Added calls to ZipQueries for extra query fields
   
 */
public without sharing class ReferralQueries {
  
   public static Lead[] selectLeads(Set<Id> leadIdSet, Id leadCompanyId) {
     Id[] leadIds = new Id[]{};
     leadIds.addAll(leadIdSet);
      Map<Id,Lead> leadMap = selectLeadMap(leadIds, leadCompanyId);
      return leadMap.values();      
   } // selectLead

   public static Integer PART_REF_DAYS=Integer.valueOf(Label.PartnerReferralExpiration);
   
   public static Map<Id,Lead> selectLeadMap(Id[] leadIds, Id leadCompanyId) {
      Map<Id,Lead> leadMap = null;
      if (leadIds != null) {
         DateTime checkTime = Datetime.now().addDays(-30);
         String query = (String)CacheManager.getOrg('ReferralQueriesLeadQuery');
         if (query == null) {
            Set<String> fldSet = new Set<String>();
            DmlHelper.addFieldsToSet(Schema.SObjectType.Lead.fieldSets.ReferralQueries_Flds, '', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Campaign.fieldSets.ReferralQueries_Flds, 'LatestCampaign__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Referral_Contact__c.fieldSets.ReferralQueries_Flds, 'Referral_Contact__r.', fldSet);
            fldSet.addAll(ZipQueries.getLeadQueryFields());
            query = DmlHelper.buildQueryFromSet(fldSet, null);
            query += ',(Select Id,CampaignId,CreatedDate,Campaign.Id,Campaign.LeadSource__c,Campaign.StartDate from CampaignMembers'+
                     ' where Campaign.IsActive=true order by Campaign.StartDate desc limit 1) ';
            fldSet.clear();
            DmlHelper.addFieldsToSet(Schema.SObjectType.Prospect_Ownership__c.fieldSets.ReferralQueries_Flds, '', fldSet);
            String subQuery = ',('+DmlHelper.buildQueryFromSet(fldSet, 'Prospect_Ownership__r')+' Where EndDate__c = null order by StartDate__c desc)';
            query += subQuery;
            fldSet.clear();
            DmlHelper.addFieldsToSet(Schema.SObjectType.PartnerReferral__c.fieldSets.ReferralQueries_Flds, '', fldSet);
            subQuery = ',('+DmlHelper.buildQueryFromSet(fldSet, 'Partner_Referral_Lead__r')+' Where CreatedDate >= :checkTime order by CreatedDate DESC limit 1)';
            query += subQuery;
            query += ' From Lead Where IsConverted=false and (id in :leadIds or Lead_Company__c = :leadCompanyId) ';
            CacheManager.putOrg('ReferralQueriesLeadQuery',query);
        }
        if (leadCompanyId == null) {
          // use a fake id
           leadCompanyId = '001000000000000';
        }
        Lead[] leads = Database.query(query);
        leadMap = new Map<Id,Lead>(leads);
         /* 
         leadMap = new Map<Id,Lead>([Select Id, Name
                            ,Additional_Referring_Name__c
                            ,Bank_Lead_ID__c
                            ,Bank_Product_Of_Interest__c
                            ,City
                            ,Client_Referral__c
                            ,Client_Referral__r.Id
                            ,Client_Referral__r.Name
                            ,Company
                            ,Consent_to_Text__c
                            ,Consent_to_Text_Date__c
                            ,CSSR_Segment__c
                            ,Current_Prior_Method__c
                            ,Description
                            ,Dialed__c
                            ,DialedUserId__c
                            ,DialedLastUsed__c
                            ,DoNotCall
                            ,Email
                            ,FirstName
                            ,Frequency__c
                            ,HasOptedOutOfEmail
                            ,Hispanic_Ownership__c
                            ,Hold_Out__c
                            ,Hold_Out_Expiration__c
                            ,Language__c
                            ,LastName
                            ,LatestCampaign__c
                            ,LatestCampaign__r.Id
                            ,LatestCampaign__r.LeadSource__c
                            ,LatestCampaign__r.EndDate
                            ,LatestCampaign__r.IsActive
                            ,LatestCampaign__r.Name
                            ,LatestCampaign__r.StartDate
                            ,LatestCampaign__r.Submit_Referral_Queue__c
                            ,LatestCampaign__r.DestinationNbrDays__c
                            ,LatestCampaign__r.PartnerType__c
                            ,LatestCampaign__r.RefPartnerNSSSource__c
                            ,LatestCampaignDate__c
                            ,LeadSource
                            ,Lead_Stage__c
                            ,Local_Competitors__c
                            ,Marketo_Lead_Rating__c
                            ,MktgId__c
                            ,Mthd_Lead_Rcvd__c
                            ,MobilePhone
                            ,No_Longer_With_Company__c
                            ,NSSCallDisposition__c
                            ,NSS_Ownership_Start_Date__c
                            ,NumberOfEmployees
                            ,OwnedBy__c
                            ,OwnedByPrev__c
                            ,OwnedByUser__c
                            ,OwnerId
                            ,Owner.Name
                            ,PEOLeasing__c
                            ,PEOLeasingDefault__c
                            ,Phone
                            ,PostalCode
                            ,Primary_Competition__c
                            //,Primary_Lead__c
                            ,Primary_Lead__r.IsConverted
                            ,ProcessNotes__c
                            ,Product_Division__c
                            ,Products__c // product(s) of interest
                            ,Promo_Code__c
                            ,RecordType.Name
                            ,Referral_Contact__c
                            ,Referral_Contact__r.Id
                            ,Referral_Contact__r.Name
                            ,Referral_Contact__r.Referral_Account__c
                            ,Referral_Contact__r.Referral_Account__r.Id
                            ,Referral_Contact__r.Referral_Account__r.Name
                            ,Referral_Contact__r.Referral_Account__r.Referral_Source_Business_Type__c
                            ,Referral_Contact__r.Referral_Account__r.Zip_Postal_Code__c
                            ,Referral_Contact__r.Referral_Account__r.ZipSegment__c
                            ,Referral_Contact__r.Has_Sensitivity_Payroll__c
                            ,Referral_Contact__r.Sensitivity_401_k__c
                            ,Referral_Contact__r.Sensitivity_FSA__c
                            ,Referral_Contact__r.Sensitivity_Health_Ins__c
                            ,Referral_Contact__r.Sensitivity_Sales_Tax__c
                            ,Referral_Contact__r.Sensitivity_Verified__c
                            ,Referral_Contact__r.Sensitivity_Wrks_Comp__c
                            ,Referral_Contact__r.Sensitivity_List__c
                            ,Referral_National_Account__c
                            ,Referral_National_Account__r.Id
                            ,Referral_National_Account__r.Name
                            ,Referring_Employee__c
                            ,Salutation
                            ,SegmentationCore1__c
                            ,SIC_Description__c
                            ,SignificantLead__c
                            ,State
                            ,Status
                            ,Street
                            ,SurePayroll_ID__c
                            ,TeamSellingASO__c
                            ,TimeZoneAbbrev__c
                            ,TimeZoneName__c
                            ,TransactionId__c
                            ,Title
                            ,UseZipAssignmentRules__c
                            ,X401K_Assets__c
                            ,Lead_Company__c
                            ,Lead_Company__r.Id
                            ,Lead_Company__r.AccountId__c
                            ,Lead_Company__r.Name
                            ,Lead_Company__r.Address__c
                            ,Lead_Company__r.City__c
                            ,Lead_Company__r.Postal_Code__c
                            ,Lead_Company__r.SignificantLead__c
                            ,Lead_Company__r.State__c
                            // only select the latest campaign member
                            ,(Select Id, CampaignId, CreatedDate
                                    ,Campaign.Id
                                    ,Campaign.LeadSource__c
                                    ,Campaign.StartDate
                                from CampaignMembers
                               where Campaign.IsActive=true
                               order by Campaign.StartDate desc
                               limit 1)
                            ,(Select Id, Name
                                    ,EndDate__c
                                    ,Lead__c
                                    ,Lead_Company__c
                                    ,LockoutEnd__c
                                    ,LockoutStart__c
                                    ,NFI_WashEnd__c
                                    ,NFI_WashStart__c
                                    ,NSR_Name__c
                                    ,NSR_Name__r.Id
                                    ,NSR_Name__r.IsActive
                                    ,NSS_Source__c
                                    ,NSS_Team__c
                                    ,Ownership_Status__c
                                    ,Prospect_Client__c
                                    ,ProcessNotes__c
                                    ,ProcessTracker__c
                                    ,ProspectingEnd__c
                                    ,ProspectingStart__c
                                    ,StartDate__c
                                    ,TransferredFrom__c
                                    //,WorkableEnd__c
                                    //,WorkableStart__c
                                From Prospect_Ownership__r
                               order by StartDate__c desc)
                               ,(Select Id
                                       ,Account__c
                                       ,Campaign__c
                                       ,Campaign__r.LeadSource__c
                                       ,Contact__c
                                       ,Lead__c
                                       ,ProcessNotes__c
                                       ,Referral__c
                                       ,Referral__r.Referral_Partner__c
                                       ,Referral__r.ProcessNotes__c
                                       ,CreatedDate
                                       ,Master_Partner_Referral__c
                                       ,Master_Partner_Referral__r.CreatedDate
                                   From Partner_Referral_Lead__r
                                  Where CreatedDate >= :checkTime
                                  order by CreatedDate DESC
                                  limit 1) 
                        From Lead
                       Where IsConverted=false
                         and (id in :leadIds
                          or Lead_Company__c = :leadCompanyId)
                        ]);
          */
      } else {
         leadMap = new Map<Id,Lead>();
      } // if (leadIds != null
      return leadMap;
   } // selectLeadMap
    
   public static String CTCT_QUERY1='SingleContact';
   public static String CTCT_QUERY2='MultipleContacts';
   public static String CTCT_NO_SUB='NoSubQuery';
    
   public static String getCtctQuery(String whichQuery) {
      String cacheKey = 'ReferralQueriesContactQuery'+whichQuery;
      String query = (String)CacheManager.getOrg(cacheKey);
      if (query == null) {
         Set<String> fldSet = new Set<String>();
         // was hard to fit in the field sets
         fldSet.add('Account.RecordType.Name');
         DmlHelper.addFieldsToSet(Schema.SObjectType.Contact.fieldSets.ReferralQueries_Flds, '', fldSet);
         DmlHelper.addFieldsToSet(Schema.SObjectType.Campaign.fieldSets.ReferralQueries_Flds, 'LatestCampaign__r.', fldSet);
         DmlHelper.addFieldsToSet(Schema.SObjectType.Referral_Contact__c.fieldSets.ReferralQueries_Flds, 'Referral_Contact__r.', fldSet);
         query = DmlHelper.buildQueryFromSet(fldSet, null);
         fldSet.clear();
         if (whichQuery == CTCT_QUERY1) {
            DmlHelper.addFieldsToSet(Schema.SObjectType.PartnerReferral__c.fieldSets.ReferralQueries_Flds, '', fldSet);
            String subQuery = ',('+DmlHelper.buildQueryFromSet(fldSet, 'Partner_Referral_Contact__r')+' Where CreatedDate >= :checkTime order by CreatedDate DESC limit 1)';
            query += subQuery;
         } else if (whichQuery == CTCT_QUERY2) {
            DmlHelper.addFieldsToSet(Schema.SObjectType.Prospect_Ownership__c.fieldSets.ReferralQueries_Flds, '', fldSet);
            String subQuery = ',('+DmlHelper.buildQueryFromSet(fldSet, 'Prospect_Ownership__r')+' order by StartDate__c desc)';
            query += subQuery;
         }
         query += ' From Contact ';
         CacheManager.putOrg(cacheKey,query);
      }
      return query;
   } // getCtctQuery

   public static Contact selectContact(Id contactId) {
      Contact ctct = null;
      if (contactId != null) {
         DateTime checkTime = Datetime.now().addDays(-30);
         String query = getCtctQuery(CTCT_QUERY1);
         query += ' Where Id = :contactId ';
         try {
           ctct = Database.query(query);
           /*
           ctct = [Select Id, Name
                          ,AccountId
                          ,Assigned_Round_Robin__c
                          ,BypassHoldout__c
                          ,Consent_to_Text__c
                          ,Consent_to_Text_Date__c
                          ,Contact_Stage__c
                          ,Description
                          ,DoNotCall
                          ,Email
                          ,FirstName
                          ,HasOptedOutOfEmail
                          ,Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c
                          ,HR_Person_Id__c
                          ,LastName
                          ,LastNSSCallDisposition__c
                          ,LatestCampaign__c
                          ,LatestCampaign__r.Id
                          ,LatestCampaign__r.LeadSource__c
                          ,LatestCampaign__r.EndDate
                          ,LatestCampaign__r.IsActive
                          ,LatestCampaign__r.Name
                          ,LatestCampaign__r.StartDate
                          ,LatestCampaign__r.Submit_Referral_Queue__c
                          ,LatestCampaign__r.DestinationNbrDays__c
                          ,LatestCampaign__r.PartnerType__c
                          ,LatestCampaign__r.RefPartnerNSSSource__c
                          ,LatestCampaignDate__c
                          ,LeadSource
                          ,MailingPostalCode
                          ,Marketo_Lead_Rating__c
                          ,MktgId__c
                          ,No_Longer_With_Company__c
                          ,NSSCallDisposition__c
                          ,NSSOwnership__c
                          ,NSSStatus__c
                          ,OwnedBy__c
                          ,OwnedByPrev__c
                          ,OwnerId
                          ,Phone
                          ,ProcessNotes__c
                          ,Products__c // product(s) of interest
                          ,Product_Division__c
                          ,LatestCallTime__c
                          ,Referral_Contact__c
                          ,Referral_Contact__r.Id
                          ,Referral_Contact__r.Name
                          ,Referral_Contact__r.Referral_Account__c
                          ,Referral_Contact__r.Referral_Account__r.Id
                          ,Referral_Contact__r.Referral_Account__r.Name
                          ,Referral_Contact__r.Referral_Account__r.Referral_Source_Business_Type__c
                          ,Referral_Contact__r.Referral_Account__r.Zip_Postal_Code__c
                          ,Referral_Contact__r.Has_Sensitivity_Payroll__c
                          ,Referral_Contact__r.Sensitivity_401_k__c
                          ,Referral_Contact__r.Sensitivity_FSA__c
                          ,Referral_Contact__r.Sensitivity_Health_Ins__c
                          ,Referral_Contact__r.Sensitivity_Sales_Tax__c
                          ,Referral_Contact__r.Sensitivity_Verified__c
                          ,Referral_Contact__r.Sensitivity_Wrks_Comp__c
                          ,Referral_Contact__r.Sensitivity_List__c
                          ,Referral_Account__c
                          ,Salutation
                          ,SignificantContact__c
                          ,TeamSellingASO__c
                          ,Title
                          ,TransactionId__c
                          ,(Select Id
                                  ,Account__c
                                  ,Campaign__c
                                  ,Campaign__r.LeadSource__c
                                  ,Contact__c
                                  ,Lead__c
                                  ,ProcessNotes__c
                                  ,Referral__c
                                  ,Referral__r.Referral_Partner__c
                                  ,Referral__r.ProcessNotes__c
                                  ,Destination__c
                                  ,Source__c
                                  ,CreatedDate
                                  ,Master_Partner_Referral__c
                                  ,Master_Partner_Referral__r.CreatedDate
                              From Partner_Referral_Contact__r
                             Where CreatedDate >= :checkTime
                            order by CreatedDate DESC
                            limit 1)
                      from Contact
                     where Id = :contactId];
            */
         } catch (Exception e) {
            // nothing is returned - don't need to do anything
         }
      } // if (contactId != null)
      return ctct;
   } // selectContact
   
   public static Map<Id,Contact> selectCtctMap(Id[] ctctIds) {
      Map<Id,Contact> ctctMap = null;
      if (ctctIds != null) {
         String query = getCtctQuery(CTCT_QUERY2);
         query += ' Where Id in :ctctIds ';
         Contact[] ctcts = Database.query(query);
         ctctMap = new Map<Id,Contact>(ctcts);
         /*
         ctctMap = new Map<Id,Contact>([Select Id, Name
                          ,AccountId
                          ,Account.RecordType.Name
                          ,Account.NumberOfEmployees
                          ,Account.Employees__c
                          ,Account.TimeZoneAbbrev__c
                          ,Account.TimeZoneName__c
                          ,Assigned_Round_Robin__c
                          ,BypassHoldout__c
                          ,Consent_to_Text__c
                          ,Consent_to_Text_Date__c
                          ,Contact_Stage__c
                          ,Description
                          ,DoNotCall
                          ,Email
                          ,FirstName
                          ,HasOptedOutOfEmail
                          ,Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c
                          ,HR_Person_Id__c
                          ,LastName
                          ,LastNSSCallDisposition__c
                          ,LatestCampaign__c
                          ,LatestCampaign__r.Id
                          ,LatestCampaign__r.LeadSource__c
                          ,LatestCampaign__r.EndDate
                          ,LatestCampaign__r.IsActive
                          ,LatestCampaign__r.Name
                          ,LatestCampaign__r.StartDate
                          ,LatestCampaign__r.Submit_Referral_Queue__c
                          ,LatestCampaign__r.DestinationNbrDays__c
                          ,LatestCampaign__r.PartnerType__c
                          ,LatestCampaign__r.RefPartnerNSSSource__c
                          ,LatestCampaignDate__c
                          ,LeadSource
                          ,MailingPostalCode
                          ,Marketo_Lead_Rating__c
                          ,MktgId__c
                          ,No_Longer_With_Company__c
                          ,NSSCallDisposition__c
                          ,NSSOwnership__c
                          ,NSSStatus__c
                          ,OwnedBy__c
                          ,OwnedByPrev__c
                          ,OwnerId
                          ,Phone
                          ,Products__c // product(s) of interest
                          ,Product_Division__c
                          ,LatestCallTime__c
                          ,RecordType.Name
                          ,Referral_Contact__c
                          ,Referral_Contact__r.Id
                          ,Referral_Contact__r.Name
                          ,Referral_Contact__r.Referral_Account__c
                          ,Referral_Contact__r.Referral_Account__r.Id
                          ,Referral_Contact__r.Referral_Account__r.Name
                          ,Referral_Contact__r.Referral_Account__r.Referral_Source_Business_Type__c
                          ,Referral_Contact__r.Referral_Account__r.Zip_Postal_Code__c
                          ,Referral_Contact__r.Has_Sensitivity_Payroll__c
                          ,Referral_Contact__r.Sensitivity_401_k__c
                          ,Referral_Contact__r.Sensitivity_FSA__c
                          ,Referral_Contact__r.Sensitivity_Health_Ins__c
                          ,Referral_Contact__r.Sensitivity_Sales_Tax__c
                          ,Referral_Contact__r.Sensitivity_Verified__c
                          ,Referral_Contact__r.Sensitivity_Wrks_Comp__c
                          ,Referral_Contact__r.Sensitivity_List__c
                          ,Referral_Account__c
                          ,Salutation
                          ,SignificantContact__c
                          ,TeamSellingASO__c
                          ,Title
                          ,TransactionId__c
                            ,(Select Id, Name
                                    ,CommissionEnd__c
                                    ,CommissionStart__c
                                    ,Decision_Maker__c
                                    ,EndDate__c
                                    ,Lead__c
                                    ,Lead_Company__c
                                    ,LockoutEnd__c
                                    ,LockoutStart__c
                                    ,NSR_Name__c
                                    ,NSR_Name__r.Id
                                    ,NSR_Name__r.IsActive
                                    ,NSS_Source__c
                                    ,NSS_Team__c
                                    ,Ownership_Status__c
                                    ,ProcessNotes__c
                                    ,ProcessTracker__c
                                    ,Prospect_Client__c
                                    ,ProspectingEnd__c
                                    ,ProspectingStart__c
                                    ,StartDate__c
                                 //   ,WorkabilityEnd__c
                                 //   ,WorkabilityStart__c
                                From Prospect_Ownership__r
                               order by StartDate__c desc)
                        From Contact
                       Where Id in :ctctIds
                        ]);
          */
      } else {
         ctctMap = new Map<Id,Contact>();
      } // if (ctctIds != null
      
      return ctctMap;
   } // selectCtctMap
   
   public static Opportunity selectOpp(Id opptyId) {
     Opportunity opp = null;
      if (opptyId != null) {
         try {
            opp = [Select Id
                         ,Name
                         ,AccountId
                         ,CloseDate
                         ,Employees_Paid_Per_Payroll__c
                         ,(Select Id
                                 ,ContactId
                                 ,Contact.Id
                                 ,Contact.Name
                                 ,Contact.Assigned_Round_Robin__c
                                 ,Contact.BypassHoldout__c
                                 ,Contact.FirstName
                                 ,Contact.Hold_Out__c, Contact.Hold_Out_Expiration__c, Contact.Hold_Out_Reason__c
                                 ,Contact.LastName
                                 ,Contact.LeadSource
                                 ,Contact.MailingPostalCode
                                 ,Contact.NSSCallDisposition__c
                                 ,Contact.NSSOwnership__c
                                 ,Contact.NSSStatus__c
                                 ,Contact.Phone
                                 ,Contact.Products__c
                                 ,Contact.Email
                                 ,IsPrimary
                             from OpportunityContactRoles
                            order by IsPrimary desc) 
                     from Opportunity
                    where Id = :opptyId];
         } catch (Exception e) {
            // nothing is returned - don't need to do anything
         }
      } // if (opptyId != null)
      return opp;
   } // selectOpp
   
   public static Account selectAcct(Id acctId) {
     Account acct = null;
     if (acctId != null) {
         Map<Id,Account> acctMap = selectAcctMap(new Id[]{acctId});
         // should only be one returned
         acct = acctMap.get(acctId);
     } // if (acctId != null
     return acct;
   } // selectAcct

   // Retrieve the account information. 
   public static Map<Id,Account> selectAcctMap(Id[] acctIds) {
      Map<Id,Account> acctMap = null;
      if (acctIds != null) {
         String query = (String)CacheManager.getOrg('ReferralQueriesAccountQuery');
         if (query == null) {
            Set<String> fldSet = new Set<String>();
            // was hard to fit in the field sets
            fldSet.add('SalesParent__r.RecordType.Name');
            DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.ReferralQueries_Flds, '', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ReferralQueries_Flds, 'Owner.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ReferralQueries_Flds, 'Owner.ASO_Partner__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ReferralQueries_Flds, 'Owner.HR_Services_Partner__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ReferralQueries_Flds, 'HRS_Account_Owner__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ReferralQueries_Flds, 'HNBF_Account_Owner__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ReferralQueries_Flds, 'Premier_PBS_Account_Owner__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.ReferralQueries_Flds, 'OasisPEOAccountOwner__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Referral_Contact__c.fieldSets.ReferralQueries_Flds, 'Banker_Name_Ref__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Referral_Contact__c.fieldSets.ReferralQueries_Flds, 'Broker_Name_Ref__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Referral_Contact__c.fieldSets.ReferralQueries_Flds, 'CPA_Name_Ref__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Referral_Contact__c.fieldSets.ReferralQueries_Flds, 'Insurance_Broker_Name_Ref__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.ReferralQueries_SalesParent, 'SalesParent__r.', fldSet);
            fldSet.addAll(ZipQueries.getAccountQueryFields());

            query = DmlHelper.buildQueryFromSet(fldSet, null);
            String ctctQuery = getCtctQuery(CTCT_NO_SUB);
            ctctQuery = ctctQuery.replace('From Contact','From Contacts');
            query += ' ,('+ctctQuery+' Where Sales_Contact__c = true Order by SignificantContact__c desc, LastName, FirstName limit 50)';

            fldSet.clear();
            DmlHelper.addFieldsToSet(Schema.SObjectType.Prospect_Ownership__c.fieldSets.ReferralQueries_Flds, '', fldSet);
            String subQuery = ' ,('+DmlHelper.buildQueryFromSet(fldSet, 'Prospect_Ownership__r')+' Where EndDate__c = null order by StartDate__c desc)';
            query += subQuery;
             
            query += ' ,(Select Id, TeamMemberRole, UserId From AccountTeamMembers) ';
            query += ' ,(Select Id, Name, CreatedDate, Opportunity_Name__c, Type__c from Business_Profiles__r where Type__c = \'SDR\' Order By CreatedDate DESC) ';
            query += ' FROM Account WHERE Id in :acctIds ';
            CacheManager.putOrg('ReferralQueriesAccountQuery',query);
         } // if (query == null   
         
         Account[] accts = Database.query(query);
         acctMap = (accts.isEmpty() ? new Map<Id,Account>() : new Map<Id,Account>(accts));
         /*
         acctMap = new Map<Id, Account>([SELECT Id
                        ,AccountNumber
                        ,Bis_Id__c
                        ,Type
                        ,Name
                        ,RecordType.Name
                        ,RecordType.Id
                        ,AssignedToNSR__c
                        ,AssignedToInboundNSR__c
                        ,AssignedToOutboundNSR__c
                        ,BillingStreet
                        ,BillingCity
                        ,BillingState
                        ,BillingPostalCode
                        ,CSSR_Segment__c
                        ,CurrentClient__c
                        ,Current_Prior_Method__c
                        ,Do_Not_Call__c
                        ,Email_Opt_Out__c
                        ,Employees__c
                        ,Federal_ID_Number__c
                        ,First_Run_Date__c
                        ,Frequency__c
                        ,Hispanic_Ownership__c
                        ,Hold_Out__c
                        ,Hold_Out_Expiration__c
                        ,isChild__c
                        ,isParent__c
                        ,Language__c
                        ,LastPayrollOppCreated__c
                        ,LatestCampaignName__c
                        ,Local_Competitors__c
                        ,Local_Payroll_Vendor__c
                        ,Lost_Date__c
                        ,NSSCallDisposition__c
                        ,NSSContactName__c
                        ,NSSContactPhone__c
                        ,NSSStatus__c
                        ,NumberOfEmployees
                        ,Other_Contact_Phone__c
                        ,Permanent_Hold_Out_Description__c
                        ,PEO_Potential_Indicator__c
                        ,Reason_Lost__c
                        ,Owner_ZipCode__c
                        ,Owner_Zip_Code__c
                        ,OwnerId
                        ,Owner.Id
                        ,Owner.IsActive
                        ,Owner.ManagerId
                        ,Owner.Name
                        ,Owner.HR_Person_Id__c
                        ,Owner.Non_Paychex_Employee__c
                        ,Owner.Non_Paychex_Employee_User_Type__c
                        ,Owner.NSS_Team__c
                        ,Owner.Sales_Org__c
                        ,Owner.Profile.Name
                        ,Owner.Title
                        ,Owner.ASO_Partner__c
                        ,Owner.ASO_Partner__r.Id               
                        ,Owner.ASO_Partner__r.IsActive            
                        ,Owner.ASO_Partner__r.ManagerId           
                        ,Owner.ASO_Partner__r.Name             
                        ,Owner.ASO_Partner__r.HR_Person_Id__c  
                        ,Owner.ASO_Partner__r.Non_Paychex_Employee__c
                        ,Owner.ASO_Partner__r.Non_Paychex_Employee_User_Type__c
                        ,Owner.ASO_Partner__r.NSS_Team__c
                        ,Owner.ASO_Partner__r.Sales_Org__c
                        ,Owner.ASO_Partner__r.Profile.Name
                        ,Owner.ASO_Partner__r.Title
                        ,Owner.HR_Services_Partner__c
                        ,Owner.HR_Services_Partner__r.Id               
                        ,Owner.HR_Services_Partner__r.IsActive            
                        ,Owner.HR_Services_Partner__r.ManagerId           
                        ,Owner.HR_Services_Partner__r.Name             
                        ,Owner.HR_Services_Partner__r.HR_Person_Id__c  
                        ,Owner.HR_Services_Partner__r.Non_Paychex_Employee__c
                        ,Owner.HR_Services_Partner__r.Non_Paychex_Employee_User_Type__c
                        ,Owner.HR_Services_Partner__r.NSS_Team__c
                        ,Owner.HR_Services_Partner__r.Sales_Org__c
                        ,Owner.HR_Services_Partner__r.Profile.Name
                        ,Owner.HR_Services_Partner__r.Title             
                        ,Patrick_Indicator__c
                        ,PEOLeasing__c
                        ,PEOLeasingDefault__c
                        ,Phone
                        ,ProcessNotes__c
                        ,LatestCallTime__c
                        ,HRS_Account_Owner__c
                        ,HRS_Account_Owner__r.Id
                        ,HRS_Account_Owner__r.IsActive
                        ,HRS_Account_Owner__r.ManagerId
                        ,HRS_Account_Owner__r.Name
                        ,HRS_Account_Owner__r.HR_Person_Id__c
                        ,HRS_Account_Owner__r.Non_Paychex_Employee__c
                        ,HRS_Account_Owner__r.Non_Paychex_Employee_User_Type__c
                        ,HRS_Account_Owner__r.NSS_Team__c
                        ,HRS_Account_Owner__r.Sales_Org__c
                        ,HRS_Account_Owner__r.Profile.Name
                        ,HRS_Account_Owner__r.Title
                        ,HRS_Hold_Out__c
                        ,HRS_Hold_Out_Expiration__c                        
                        ,HNBF_Account_Owner__c
                        ,HNBF_Account_Owner__r.Id
                        ,HNBF_Account_Owner__r.IsActive
                        ,HNBF_Account_Owner__r.ManagerId
                        ,HNBF_Account_Owner__r.Name
                        ,HNBF_Account_Owner__r.HR_Person_Id__c
                        ,HNBF_Account_Owner__r.Non_Paychex_Employee__c
                        ,HNBF_Account_Owner__r.Non_Paychex_Employee_User_Type__c
                        ,HNBF_Account_Owner__r.NSS_Team__c
                        ,HNBF_Account_Owner__r.Sales_Org__c
                        ,HNBF_Account_Owner__r.Profile.Name
                        ,HNBF_Account_Owner__r.Title
                        ,HNBF_Hold_Out__c
                        ,HNBF_Hold_Out_Expiration__c
                        ,HNBF_Permanent_Hold_Out_Description__c
                        ,Premier_PBS_Account_Owner__c
                        ,Premier_PBS_Account_Owner__r.Id
                        ,Premier_PBS_Account_Owner__r.IsActive
                        ,Premier_PBS_Account_Owner__r.ManagerId
                        ,Premier_PBS_Account_Owner__r.Name
                        ,Premier_PBS_Account_Owner__r.HR_Person_Id__c
                        ,Premier_PBS_Account_Owner__r.Non_Paychex_Employee__c
                        ,Premier_PBS_Account_Owner__r.Non_Paychex_Employee_User_Type__c
                        ,Premier_PBS_Account_Owner__r.NSS_Team__c
                        ,Premier_PBS_Account_Owner__r.Sales_Org__c
                        ,Premier_PBS_Account_Owner__r.Profile.Name
                        ,Premier_PBS_Account_Owner__r.Title
                        ,Premier_PBS_Hold_Out__c
                        ,Premier_PBS_Hold_Out_Expiration__c
                        ,PEO_ASO_Permanent_Hold_Out_Description__c
                        ,OasisPEOAccountOwner__c
                        ,OasisPEOAccountOwner__r.Id
                        ,OasisPEOAccountOwner__r.IsActive
                        ,OasisPEOAccountOwner__r.ManagerId
                        ,OasisPEOAccountOwner__r.Name
                        ,OasisPEOAccountOwner__r.HR_Person_Id__c
                        ,OasisPEOAccountOwner__r.Non_Paychex_Employee__c
                        ,OasisPEOAccountOwner__r.Non_Paychex_Employee_User_Type__c
                        ,OasisPEOAccountOwner__r.NSS_Team__c
                        ,OasisPEOAccountOwner__r.Sales_Org__c
                        ,OasisPEOAccountOwner__r.Profile.Name
                        ,OasisPEOAccountOwner__r.Title
                        ,OasisPEOHoldOut__c
                        ,OasisPEOHoldOutExpiration__c
                        ,MS_Hold_Out__c
                        ,MS_Hold_Out_Expiration__c
                        ,Products__c // product(s) of interest
                        ,Related_Contact_has_Do_Not_Call__c
                        ,Related_Contact_is_Email_Opt_Out__c
                        ,SalesParent__r.Id
                        ,SalesParent__r.RecordType.Name
                        ,SalesParent__r.NumberOfEmployees
                        ,SalesParent__r.Owner.HR_Person_Id__c
                        ,SalesParent__r.Owner.Profile.Name
                        ,SalesParent__r.Owner.Sales_Org__c
                        ,SalesParent__r.Owner_Zip_Code__c
                        ,SalesParent__r.ShippingPostalCode
                        ,SalesParent__r.TAA_Holdout__c
                        ,SalesParent__r.TAA_Holdout_Expiration__c
                        ,SalesParent__r.TimeZoneAbbrev__c
                        ,SalesParent__r.TimeZoneName__c
                        ,SalesParent__r.Type
                        ,SalesParent__r.Hold_Out__c
                        ,SalesParent__r.HNBF_Hold_Out__c
                        ,SalesParent__r.HRS_Hold_Out__c
                        ,SalesParent__r.MS_Hold_Out__c
                        ,SalesParent__r.Premier_PBS_Hold_Out__c
                        ,SalesParent__r.OasisPEOHoldOut__c
                        ,SalesParent__r.OasisPEOHoldOutExpiration__c
                        ,SalesParent__r.OasisPEOAccountOwner__c
                        ,SalesParent__r.OwnerId
                        ,SalesParent__r.HRS_Account_Owner__c
                        ,SalesParent__r.HNBF_Account_Owner__c
                        ,SalesParent__r.Premier_PBS_Account_Owner__c
                        ,SegmentationCore1__c
                        ,ShippingStreet
                        ,ShippingCity
                        ,ShippingState
                        ,ShippingPostalCode
                        ,SignificantContact__c
                        ,TAA_Holdout__c
                        ,TAA_Holdout_Expiration__c
                        ,TeamSellingASO__c
                        ,Time_Zone__c
                        ,TimeZoneAbbrev__c
                        ,TimeZoneName__c
                        ,X401k_Assets__c
                        ,Banker_Name_Ref__c
                        ,Banker_Name_Ref__r.Id
                        ,Banker_Name_Ref__r.Name
                        ,Banker_Name_Ref__r.Sensitivity_List__c
                        ,Banker_Name_Ref__r.Referral_Account__c
                        ,Banker_Name_Ref__r.Referral_Account__r.Id
                        ,Banker_Name_Ref__r.Referral_Account__r.Name
                        ,Banker_Name_Ref__r.Referral_Account__r.Referral_Source_Business_Type__c
                        ,Banker_Name_Ref__r.Referral_Account__r.Zip_Postal_Code__c
                        ,Banker_Name_Ref__r.Referral_Account__r.ZipSegment__c
                        ,Broker_Name_Ref__c
                        ,Broker_Name_Ref__r.Id
                        ,Broker_Name_Ref__r.Name
                        ,Broker_Name_Ref__r.Sensitivity_List__c
                        ,Broker_Name_Ref__r.Referral_Account__r.Id
                        ,Broker_Name_Ref__r.Referral_Account__r.Name
                        ,Broker_Name_Ref__r.Referral_Account__r.Referral_Source_Business_Type__c
                        ,Broker_Name_Ref__r.Referral_Account__r.Zip_Postal_Code__c
                        ,Broker_Name_Ref__r.Referral_Account__r.ZipSegment__c
                        ,CPA_Name_Ref__c
                        ,CPA_Name_Ref__r.Id
                        ,CPA_Name_Ref__r.Name
                        ,CPA_Name_Ref__r.Referral_Account__c
                        ,CPA_Name_Ref__r.Referral_Account__r.Id
                        ,CPA_Name_Ref__r.Referral_Account__r.Name
                        ,CPA_Name_Ref__r.Referral_Account__r.Referral_Source_Business_Type__c
                        ,CPA_Name_Ref__r.Referral_Account__r.Zip_Postal_Code__c
                        ,CPA_Name_Ref__r.Referral_Account__r.ZipSegment__c
                        ,CPA_Name_Ref__r.Has_Sensitivity_Payroll__c
                        ,CPA_Name_Ref__r.Sensitivity_401_k__c
                        ,CPA_Name_Ref__r.Sensitivity_FSA__c
                        ,CPA_Name_Ref__r.Sensitivity_Health_Ins__c
                        ,CPA_Name_Ref__r.Sensitivity_Sales_Tax__c
                        ,CPA_Name_Ref__r.Sensitivity_Verified__c
                        ,CPA_Name_Ref__r.Sensitivity_Wrks_Comp__c
                        ,CPA_Name_Ref__r.Sensitivity_List__c
                        ,Insurance_Broker_Name_Ref__c
                        ,Insurance_Broker_Name_Ref__r.Id
                        ,Insurance_Broker_Name_Ref__r.Name
                        ,Insurance_Broker_Name_Ref__r.Sensitivity_List__c
                        ,Insurance_Broker_Name_Ref__r.Referral_Account__c
                        ,Insurance_Broker_Name_Ref__r.Referral_Account__r.Id
                        ,Insurance_Broker_Name_Ref__r.Referral_Account__r.Name
                        ,Insurance_Broker_Name_Ref__r.Referral_Account__r.Referral_Source_Business_Type__c
                        ,Insurance_Broker_Name_Ref__r.Referral_Account__r.Zip_Postal_Code__c
                        ,Insurance_Broker_Name_Ref__r.Referral_Account__r.ZipSegment__c
                        ,Referral_National_Account__c
                        ,Referral_National_Account__r.Id
                        ,Referral_National_Account__r.Name
                        ,Referral_National_Account__r.Referral_Source_Business_Type__c
                        ,Referral_National_Account__r.Sensitivity_List__c
                        ,Referral_National_Account__r.Zip_Postal_Code__c
                        ,Referral_National_Account__r.ZipSegment__c
                        ,(Select Id, AccountId
                                ,Name, FirstName, LastName, Title 
                                ,Phone, Email, LeadSource, OwnerId
                                ,Assigned_Round_Robin__c
                                ,BypassHoldout__c
                                ,Consent_to_Text__c
                                ,Consent_to_Text_Date__c
                                ,Contact_Stage__c
                                ,Description
                                ,DoNotCall
                                ,HasOptedOutOfEmail
                                ,Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c
                                ,LastActivityDate
                                ,LastModifiedDate
                                ,LastNSSCallDisposition__c
                                ,LatestCampaign__c
                                ,LatestCampaign__r.LeadSource__c
                                ,LatestCampaign__r.Id
                                ,LatestCampaign__r.EndDate
                                ,LatestCampaign__r.IsActive
                                ,LatestCampaign__r.Name
                                ,LatestCampaign__r.StartDate
                                ,LatestCampaign__r.Submit_Referral_Queue__c
                                ,LatestCampaign__r.DestinationNbrDays__c
                                ,LatestCampaign__r.PartnerType__c
                                ,LatestCampaign__r.RefPartnerNSSSource__c
                                ,LatestCampaignDate__c
                                ,MailingPostalCode
                                ,Marketo_Lead_Rating__c
                                ,MktgId__c
                                ,No_Longer_With_Company__c
                                ,NSSCallDisposition__c
                                ,NSSOwnership__c
                                ,NSSStatus__c
                                ,OwnedBy__c
                                ,OwnedByPrev__c
                                ,ProcessNotes__c
                                ,Products__c // product(s) of interest
                                ,Product_Division__c
                                ,Referral_Contact__c
                                ,Referral_Contact__r.Id
                                ,Referral_Contact__r.Name
                                ,Referral_Contact__r.Sensitivity_List__c
                                ,Referral_Contact__r.Referral_Account__c
                                ,Referral_Contact__r.Referral_Account__r.Id
                                ,Referral_Contact__r.Referral_Account__r.Name
                                ,Referral_Contact__r.Referral_Account__r.Referral_Source_Business_Type__c
                                ,Referral_Contact__r.Referral_Account__r.Zip_Postal_Code__c
                                ,Sales_Contact__c
                                ,Salutation
                                ,SignificantContact__c
                                ,TeamSellingASO__c
                                ,TransactionId__c
                            From Contacts
                           Where Sales_Contact__c = true
                           Order by SignificantContact__c desc, LastName, FirstName limit 50)
                            ,(Select Id, Name
                                    ,CommissionEnd__c
                                    ,CommissionStart__c
                                    ,EndDate__c
                                    ,Lead__c
                                    ,Lead_Company__c
                                    ,LockoutEnd__c
                                    ,LockoutStart__c
                                    ,NSR_Name__c
                                    ,NSR_Name__r.Id
                                    ,NSR_Name__r.IsActive
                                    ,NSS_Source__c
                                    ,NSS_Team__c
                                    ,Ownership_Status__c
                                    ,Prospect_Client__c
                                    ,ProcessNotes__c
                                    ,ProcessTracker__c
                                    ,ProspectingEnd__c
                                    ,ProspectingStart__c
                                    ,StartDate__c
                                 //   ,WorkabilityEnd__c
                                 //   ,WorkabilityStart__c
                                From Prospect_Ownership__r
                               Where EndDate__c = null
                               order by StartDate__c desc)
                        ,(Select Id, TeamMemberRole, UserId
                            From AccountTeamMembers)
                    FROM Account
                   WHERE Id in :acctIds]);
          */
      } else {
         acctMap = new Map<Id,Account>();
      } // if (acctId != null
      return acctMap;
   } // selectAcctMap
      
   /** Get a map of all of the account team members attached to an account.
    */   
   public static Map<Id,List<AccountTeamMember>> getAtmListMap(Set<Id> acctIdSet) {
     Map<Id,List<AccountTeamMember>> atmListMap = new Map<Id,List<AccountTeamMember>>();
     for (AccountTeamMember[] atms : [Select Id, TeamMemberRole, UserId, AccountId
                                        From AccountTeamMember
                                       Where AccountId in :acctIdSet]) {
        for (AccountTeamMember atm : atms) {
           List<AccountTeamMember> atmList = atmListMap.get(atm.AccountId);
           if (atmList == null) {
              atmList = new List<AccountTeamMember>();
              atmListMap.put(atm.AccountId, atmList);
           } // if (atmList
           atmList.add(atm);
        } // for (AccountTeamMember
        
     } // for (AccountTeamMember
     return atmListMap;
   } // getAtmListMap
   
   /** Return the contacts associated with the account ids passed in.
    */
   public static Map<Id,List<Contact>> getContactListMap(Set<Id> acctIdSet) {
      Map<Id,List<Contact>> contactListMap = new Map<Id,List<Contact>>();
      String ctctQuery = (String)CacheManager.getOrg('ReferralQueriesContactListQuery');
      if (ctctQuery == null) {
         Set<String> fldSet = new Set<String>();
         // was hard to fit in the field sets
         DmlHelper.addFieldsToSet(Schema.SObjectType.Contact.fieldSets.ReferralQueries_ShortList, '', fldSet);
         ctctQuery = DmlHelper.buildQueryFromSet(fldSet, 'Contact');
         ctctQuery += ' Where Sales_Contact__c = true and AccountId in :acctIdSet order by LastActivityDate desc ';
         CacheManager.putOrg('ReferralQueriesContactListQuery',ctctQuery);
      } // if (ctctQuery == null
      
      for (Contact[] ctcts : Database.query(ctctQuery)) {
      /*
      for (Contact[] ctcts : [Select Id, AccountId, Name, FirstName, LastName, Title 
                                ,Phone, Email, LeadSource, OwnerId
                                ,Assigned_Round_Robin__c
                                ,BypassHoldout__c
                                ,Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c
                                ,LastNSSCallDisposition__c
                                ,MailingPostalCode
                                ,Products__c // product(s) of interest
                                ,LastActivityDate
                                ,NSSStatus__c
                                ,NSSOwnership__c
                                ,NSSCallDisposition__c
                            From Contact
                           Where Sales_Contact__c = true
                             and AccountId in :acctIdSet
                            order by LastActivityDate desc]) {
        */                    
         for (Contact ctct : ctcts) {
            List<Contact> ctctList = contactListMap.get(ctct.AccountId);
            if (ctctList == null) {
               ctctList = new List<Contact>();
               contactListMap.put(ctct.AccountId, ctctList);
            }
            ctctList.add(ctct);
         } // for (Contact ctct
      } // for (Contact[] ctcts
      return contactListMap;
   } // getContactListMap
   
   public static final String NSS_SOURCE_BOTH='Both';
   public static final String CACHE_KEY='ReferralQueriesReferralPartners';
   public static Boolean USED_CACHE = false;
   
   // select the referral partners using the cache
   public static Referral_Partner__c[] selectRefPartnersCache(String partnerType, String nssSourceFilter) {
      String key = (partnerType + (String.isNotBlank(nssSourceFilter) ? nssSourceFilter : '' ));
      Map<String, Referral_Partner__c[]> partnersMap = (Map<String, Referral_Partner__c[]>)CacheManager.getOrg(CACHE_KEY);
      if (partnersMap == null) {
         //Referral_Partner__c[] refPartners = selectRefPartners(null, partnerType, nssSourceFilter, true);
         Referral_Partner__c[] refPartners = selectRefPartners(null, partnerType, null, true);
         partnersMap = groupPartners(refPartners);
         CacheManager.putOrg(CACHE_KEY,partnersMap);
      } else {
         USED_CACHE = true;
      }
      Referral_Partner__c[] partners = partnersMap.get(key);
      if (partners == null) {
         partners = new Referral_Partner__c[]{};
      }
      System.debug('selectRefPartnersCache key='+key+' partnersMap='+partnersMap.size()+' partners='+(partners != null ? partners.size() : -1));
      return partners;
   } // selectRefPartnersCache
   
   // remove the referral partners from the cache
   public static void clearReferralPartnerCache() {
      CacheManager.removeOrg(CACHE_KEY);
   } // clearReferralPartnerCache
   
   // put all of the referral partners into a single map - one object in the cache.
   public static Map<String, Referral_Partner__c[]> groupPartners(Referral_Partner__c[] refParts) {
      Map<String, Referral_Partner__c[]> partnersMap = new Map<String, Referral_Partner__c[]>();
      for (Referral_Partner__c refPartner : refParts) {
         checkAddToMap(refPartner.Partner_Type__c, refPartner, partnersMap);
         // special grouping for NSS
         System.debug('groupPartners refPart='+refPartner.Partner_Type__c+' NSS_Source__c='+refPartner.NSS_Source__c);
         if (String.isNotBlank(refPartner.NSS_Source__c)) {
            if (refPartner.NSS_Source__c == NSS_SOURCE_BOTH) {
               // add to both inbound and outbound
               String key=refPartner.Partner_Type__c+ProspectOwnershipMethods.NSS_INBOUND;
               checkAddToMap(key, refPartner, partnersMap);
               key=refPartner.Partner_Type__c+ProspectOwnershipMethods.NSS_OUTBOUND;
               checkAddToMap(key, refPartner, partnersMap);
            } else {
               // just add them as is
               String key=refPartner.Partner_Type__c+refPartner.NSS_Source__c;
               System.debug('groupPartners key='+key+' refPartner='+refPartner.Name);
               checkAddToMap(key, refPartner, partnersMap);
            }
         }
          /*
         if (refPartner.Partner_Type__c == ReferralController.REF_NSS) {
            // for both
            if (String.isBlank(refPartner.NSS_Source__c) || refPartner.NSS_Source__c == NSS_SOURCE_BOTH) {
               // add to both inbound and outbound
               String key=refPartner.Partner_Type__c+ProspectOwnershipMethods.NSS_INBOUND;
               checkAddToMap(key, refPartner, partnersMap);
               key=refPartner.Partner_Type__c+ProspectOwnershipMethods.NSS_OUTBOUND;
               checkAddToMap(key, refPartner, partnersMap);
            } else {
               // just add to the source that's on the record
               String nssSource = (refPartner.NSS_Source__c.startsWith(ProspectOwnershipMethods.NSS_INBOUND) ? ProspectOwnershipMethods.NSS_INBOUND
                                       : refPartner.NSS_Source__c.startsWith(ProspectOwnershipMethods.NSS_OUTBOUND) ? ProspectOwnershipMethods.NSS_OUTBOUND : refPartner.NSS_Source__c);
               String key=refPartner.Partner_Type__c+nssSource;
               System.debug('groupPartners key='+key+' refPartner='+refPartner.Name);
               checkAddToMap(key, refPartner, partnersMap);
            }
         } else if (refPartner.Partner_Type__c == ReferralController.REF_OASIS) {
               String key=refPartner.Partner_Type__c+refPartner.NSS_Source__c;
               System.debug('groupPartners key='+key+' refPartner='+refPartner.Name);
               checkAddToMap(key, refPartner, partnersMap);
         }
         */
      } // for (Referral_Partner__c refPart
      return partnersMap;
   } // groupPartners
   
   public static void checkAddToMap(String key, Referral_Partner__c refPart, Map<String, Referral_Partner__c[]> partnersMap) {
      System.debug('checkAddToMap key='+key+' refPart='+refPart.Name);
      Referral_Partner__c[] theseParts = (partnersMap.containsKey(key) ? partnersMap.get(key) : new Referral_Partner__c[]{});
      theseParts.add(refPart);
      partnersMap.put(key, theseParts);
   } // checkAddToMap
   
   public static Referral_Partner__c[] selectRefPartners(String partnerType, String nssSourceFilter) {
      return selectRefPartners(null,partnerType,nssSourceFilter,false);

   } // selectRefPartners

   public static Referral_Partner__c[] selectRefPartners(Set<Id> refPartnerIdSet, String partnerType, String nssSourceFilter) {
      return selectRefPartners(refPartnerIdSet,partnerType,nssSourceFilter,false);
   }
   
   public static Boolean USE_STATIC_QUERY=(Label.ReferralQueries_UseStaticQuery=='Y');
       
   public static Referral_Partner__c[] selectRefPartners(Set<Id> refPartnerIdSet, String partnerType, String nssSourceFilter, Boolean selectAll) {
      String query = null;
      if (USE_STATIC_QUERY) {
         Set<String> fldSet = new Set<String>();
         DmlHelper.addFieldsToSet(Schema.SObjectType.Referral_Partner__c.fieldSets.ReferralQueries_Query, '', fldSet);
         query = DmlHelper.buildQueryFromSet(fldSet,'Referral_Partner__c');
      } else {
         query = ObjectHelper.getSOQLQuery('Referral_Partner__c',null,false, false);
      }
      query += ' where IsActive__c=true ';
      if (!selectAll) {
         if (String.isNotBlank(partnerType)) {
            query += ' and Partner_Type__c = :partnerType ';
         } else if (refPartnerIdSet != null && !refPartnerIdSet.isEmpty()) {
            query += ' and Id in :refPartnerIdSet ';
         } else {
            query = null;
         }
      } // if (!selectAll)
      if (query != null) {
         query += ' order by Sort_Order__c asc, Name asc';
      }
      System.debug('selectRefPartners query='+query);
      Referral_Partner__c[] refPartners = (query != null ? Database.query(query) : new Referral_Partner__c[]{});  
      System.debug('selectRefPartners refPartners='+refPartners.size()+' partnerType='+partnerType+' nssSourceFilter='+nssSourceFilter);
      if (String.isNotBlank(nssSourceFilter)) {
         Referral_Partner__c[] filteredPartners = new Referral_Partner__c[]{};
         for (Referral_Partner__c refPartner : refPartners) {
            if (String.isBlank(refPartner.NSS_Source__c)
                || refPartner.NSS_Source__c == NSS_SOURCE_BOTH
                || (String.isNotBlank(refPartner.NSS_Source__c) && refPartner.NSS_Source__c.startsWith(nssSourceFilter))) {
               filteredPartners.add(refPartner);
               System.debug('selectRefPartners add to filteredPartners nssSourceFilter='+nssSourceFilter+' refPartner='+refPartner.Name);
            }
         } // for (Referral_Partner__c
         
         refPartners = filteredPartners;
      } // if (String.isNotBlank
      return refPartners;
   } // selectRefPartners


} // class ReferralQueries