/* 

  History
  -------
  07/29/2020 Dan Carmen          Change to without sharing and add additional debugging
  08/10/2020 Pujitha Madamanchi  DemandGen changes
  08/27/2021 Jake Hinds          ADDED PORTAL USERS FOR OPPORTUNITY BANNER AGAIN, DO DIFFS BEFORE YOU SAVE
  03/23/2022 Dan Carmen          Clean up Code
  03/08/2023 Lalan Kumar        getAllContactsForAccount added in getAccountWrapperById method to fetch all Contacts of an Account
  10/12/2023 Carrie Marciano	added code to create banner on Reference Client Retention object
  12/14/2023 Shilpa G			 APR0155814: added method call to getIntentById
*/
public without sharing class ObjectBannerAuraService {

     // For DemandGen Pilot
    @AuraEnabled
    public static Boolean insightsPilot(){
        Boolean isPilot = FeatureManagement.checkPermission('DemandGen_Pilot_Group');
        return isPilot;
    } 

    @AuraEnabled
    public static Boolean hasCustomPermission(){
        return FeatureManagement.checkPermission('Accountant_Program_Rep');
    }
        
    @AuraEnabled
    public static Lightning_Banner_Settings__mdt getLightningBannerSettings() {
        try {
            Lightning_Banner_Settings__mdt bannerSettings = [
                    SELECT Account_Show_Activities_If_None__c,
                            Account_Show_Cases_If_Zero__c,
                            Account_Show_Employee_Count_If_Zero__c,
                            Account_Show_Opportunities_If_Zero__c,
                            Contact_Show_Activities_If_None__c,
                            Contact_Show_Cases_If_Zero__c,
                            Contact_Show_Opportunities_If_Zero__c,
                            Lead_Show_Activities_If_None__c,
                            Opportunity_Show_Activities_If_None__c,
                            Opportunity_Show_Revenue_If_Zero__c,
                            Ref_Acct_Show_Activities_If_None__c,
                            Ref_Acct_Cases_If_Zero__c,
                            Ref_Acct_Mutual_Clients_If_Zero__c,
                            Ref_Acct_Opps_If_Zero__c,
                			RefCltRet_Show_Cases_If_Zero__c,
                            Referral_Contact_Mutual_Clients_If_Zero__c,
                            Referral_Contact_Show_Cases_If_Zero__c,
                            Referral_Contact_Show_Opps_If_Zero__c
                    FROM Lightning_Banner_Settings__mdt
                    WHERE QualifiedApiName = 'Lightning_Banner_Settings'
                    LIMIT 1
            ];
            return bannerSettings;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw new AuraHandledException('An error occurred while trying to get banner settings, please refresh and try again');
        }
    } // getLightningBannerSettings

    @AuraEnabled
    public static ContactWrapper getContactWrapperById(Id contactId) {
        try {
            ContactWrapper returnContactWrapper = new ContactWrapper();
            returnContactWrapper.OpenActivities = ActivityDA.getOpenActivities(contactId);
            returnContactWrapper.OpenCases = ObjectBannerQueries.getOpenCasesByContactId(contactId);
            returnContactWrapper.OpenOpportunities = new OpportunityDA().getOpenOpportunitiesByContactId(contactId);
             //DemandGen - get Insights
            returnContactWrapper.marketingInsights = InsightsDA.getInsightsById(contactId);
            returnContactWrapper.customerIntentSignals = InsightsDA.getIntentById(contactId);

            return returnContactWrapper;
        } catch (Exception ex) {
            System.debug('Exception for contactId='+contactId+'; '+ex.getMessage());
            throw new AuraHandledException('An error occurred while trying to get Contact Information, please refresh and try again');
        }
    } // getContactWrapperById

    @AuraEnabled
    public static OpportunityWrapper getOpportunityWrapperById(Id opportunityId) {
        try {
            OpportunityWrapper returnOpportunityWrapper = new OpportunityWrapper();
            returnOpportunityWrapper.StrategicAccount = ObjectBannerQueries.getAccountByOpportunityId(opportunityId);
            ActivityDA activity = new ActivityDA();
            returnOpportunityWrapper.RelatedEvents = activity.getInitialPresentationEventsByOpportunityId(opportunityId);
            returnOpportunityWrapper.OpenActivities = ActivityDA.getOpenActivities(opportunityId);
            returnOpportunityWrapper.ContactRoles = activity.getContactRolesByOpportunityId(opportunityId);
            returnOpportunityWrapper.setUserInformation();
            returnOpportunityWrapper.opp = new OpportunityDA().getOpportunityInfo(opportunityId);   
            returnOpportunityWrapper.portalUsers = new OpportunityDA().getPortalUsersByOpportunityId(returnOpportunityWrapper.opp.AccountId);

            return returnOpportunityWrapper;
        } catch (Exception ex) {
            System.debug(ex.getMessage()+' '+ex.getStackTraceString());
            throw new AuraHandledException('An error occurred while trying to get Opportunity Information, please refresh and try again');
        }
    } // getOpportunityWrapperById
    
    @AuraEnabled
    public static LeadWrapper getLeadWrapperById(Id leadId) {
        try {
            LeadWrapper returnLeadWrapper = new LeadWrapper();
            returnLeadWrapper.Lead = ObjectBannerQueries.getLeadById(leadId);
            returnLeadWrapper.OpenActivities = ActivityDA.getOpenActivities(leadId);
            //DemandGen - get Insights
            returnLeadWrapper.marketingInsights = InsightsDA.getInsightsById(leadId);
            returnLeadWrapper.customerIntentSignals = InsightsDA.getIntentById(leadId);
            returnLeadWrapper.getSensitivities = ObjectBannerQueries.getSensitivitiesByLeadId(leadId);
            return returnLeadWrapper;
        } catch (Exception ex) {
            System.debug(ex.getMessage() + ex.getLineNumber());
            throw new AuraHandledException('An error occurred while trying to get Lead Information, please refresh and try again');
        }
    } // getLeadWrapperById

    @AuraEnabled
    public static AccountWrapper getAccountWrapperById(Id accountId) {
        try {
            AccountWrapper returnAccountWrapper = new AccountWrapper();
            returnAccountWrapper.OpenOpportunities = new OpportunityDA().getOpenOpportunitiesByAccountId(accountId);
            returnAccountWrapper.OpenActivities = ActivityDA.getOpenActivities(accountId);
            returnAccountWrapper.OpenCases = ObjectBannerQueries.getOpenCasesByAccountId(accountId);
            ContactDA ctctDa = new ContactDA();
            /*Below query (getAllContactsForAccount) is to fetch all Contacts of an Account- APR0133627*/
            returnAccountWrapper.AllContacts = ctctDa.getAllContactsForAccount(accountId);
            returnAccountWrapper.DNCContacts = ctctDa.getDoNotCallContactsForAccount(accountId);
            returnAccountWrapper.EmailOptOutContacts = ctctDa.getEmailOptOutContactsForAccount(accountId);
            returnAccountWrapper.MarketingOwnedContact = ctctDa.getMarketingOwnedContact(accountID);
            //DemandGen - get Insights
            returnAccountWrapper.marketingInsights = InsightsDA.getInsightsById(accountID);
            returnAccountWrapper.customerIntentSignals = InsightsDA.getIntentById(accountID);

            return returnAccountWrapper;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw new AuraHandledException('An error occurred while trying to get Account information, please refresh and try again');
        }
    } // getAccountWrapperById

    @AuraEnabled
    public static ReferralContactWrapper getReferralContactWrapperById(Id referralContactId) {
        try {
            ReferralContactWrapper wrapper = new ReferralContactWrapper();
            wrapper.ReferralContact = ObjectBannerQueries.getReferralContactById(referralContactId);
            wrapper.OpenActivities = ActivityDA.getOpenActivities(wrapper.ReferralContact.Contact__c);
            wrapper.OpenCases = ObjectBannerQueries.getOpenCasesByReferralContactId(wrapper.ReferralContact.Id);
            wrapper.OpenOpportunities = new OpportunityDA().getOpenOpportunitiesByReferralAccountId(wrapper.ReferralContact.Referral_Account__c);
            wrapper.MutualClientCount = new MutualClientDA().getMutualClientsByReferralContactId(referralContactId);
            wrapper.MutualClients = new MutualClientDA().getMutualClientFieldsByByReferralContactId(referralContactId);
			wrapper.refConData = ReferralContacts.fetchRefConUserData(referralContactId);
            System.debug('fetchPPUD result:'+ReferralContacts.fetchPPUD(referralContactId));
            if(ReferralContacts.fetchPPUD(referralContactId) != null){
                Wrapper.pPUDData = ReferralContacts.fetchPPUD(referralContactId);
            }

            return wrapper;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw new AuraHandledException('An error occurred while trying to get Referral Contact information, please refresh and try again');
        }
    } // getReferralContactWrapperById
    
    @AuraEnabled
    public static List<Account> getMutualClients(List<Referral_Contact__c> refCtctIds){
        return new MutualClientDA().getMutualClientFieldsByByReferralContacts(refCtctIds);
    } // getMutualClients

    @AuraEnabled
    public static ReferralAccountWrapper getReferralAccountWrapperById(Id referralAccountId) {
        try {
            ReferralAccountWrapper wrapper = new ReferralAccountWrapper();

            wrapper.ReferralAccount = ObjectBannerQueries.getReferralAccountById(referralAccountId);
            wrapper.RelatedReferralContacts = ObjectBannerQueries.getReferralContactsByReferralAccount(referralAccountId);
            wrapper.OpenOpportunities = new OpportunityDA().getOpenOpportunitiesByReferralAccountId(wrapper.ReferralAccount.Id);
            wrapper.OpenActivities = ActivityDA.getOpenActivities(wrapper.ReferralAccount.Account__c);
            wrapper.OpenCases = ObjectBannerQueries.getOpenCasesByReferralAccountId(wrapper.ReferralAccount.Id);
            wrapper.MutualClientCount = new MutualClientDA().getMutualClientsByReferralContacts(wrapper.RelatedReferralContacts);
            wrapper.getSensitivities = ObjectBannerQueries.getSensitivitiesByRefAcctId (wrapper.ReferralAccount.Id) ; 


            return wrapper;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw new AuraHandledException('An error occurred while trying to get Referral Account information, please refresh and try again');
        }
    } // getReferralAccountWrapperById
    
    @AuraEnabled
    public static ReferenceClientRetentionWrapper getRefClientRetWrapperById(Id refClientRetId) {
        System.debug('getRefClientRetWrapperById begin');
        try {
            ReferenceClientRetentionWrapper wrapper = new ReferenceClientRetentionWrapper();

            wrapper.refClientRet = ObjectBannerQueries.getRefClientRetById(refClientRetId);
            System.debug('getRefClientRetWrapperById wrapper.RefClientRet: '+wrapper.refClientRet);
            wrapper.openRCRs = ObjectBannerQueries.getOpenRCRByRefClientRetAcctId(refClientRetId);
            System.debug('getRefClientRetWrapperById wrapper.OpenRCRs: '+wrapper.OpenRCRs.size());
            wrapper.totalRCRs = ObjectBannerQueries.getTotalRCRByRefClientRetAcctId(refClientRetId);
            System.debug('getRefClientRetWrapperById wrapper.totalRCRs: '+wrapper.totalRCRs.size());
            return wrapper;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw new AuraHandledException('An error occurred while trying to get Reference Client Retention information, please refresh and try again');
        }
    } // getRefClientRetWrapperById
    
} // class ObjectBannerAuraService