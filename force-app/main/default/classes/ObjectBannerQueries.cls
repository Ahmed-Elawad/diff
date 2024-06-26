/* 

  History
  -------
  03/22/2022 Dan Carmen          Created to Consolidate Code
  01/23/2022 Vinay               Added "MutualClientTier__c" field to "getReferralAccountById" method.
  02/27/2023 Vinay               Added "End_Date__c" field to "getReferralContactById" method.
  10/12/2023 Carrie Marciano	 added code to create banner on Reference Client Retention object
 */
public without sharing class ObjectBannerQueries {

    public static List<Case> getOpenCasesByContactId(Id contactId) {
            Contact selectedContact = [SELECT Account.Name FROM Contact WHERE Id = :contactId];
            List<Case> openCases = new List<Case>();
            openCases = [SELECT Id,
                                Description,
                                Status,
                                Status_Description__c
                        FROM Case
                        WHERE Contact.Id = :selectedContact.Id
                        AND IsClosed = false];
            return openCases;
    } // getOpenCasesByContactId

    public static List<Case> getOpenCasesByAccountId(Id accountId) {
            List<Case> openCases = new List<Case>();
            openCases = [SELECT Id,
                                Description,
                                Status,
                                Status_Description__c
                        FROM Case
                        WHERE AccountId = :accountId
                        AND IsClosed = false];

            return openCases;
    } // getOpenCasesByAccountId

    public static List<Case> getOpenCasesByReferralAccountId(Id referralAccountId) {
            List<Case> openCases = new List<Case>();
            openCases = [SELECT Id,
                    Description,
                    Status,
                    Status_Description__c
            FROM Case
            WHERE AccountId = :referralAccountId
            AND IsClosed = false];

            return openCases;
    } // getOpenCasesByReferralAccountId

    public static List<Case> getOpenCasesByReferralContactId(Id referralContactId) {
            Referral_Contact__c referralContact = [SELECT Referral_Account__c FROM Referral_Contact__c WHERE Id = :referralContactId];
            System.debug('actual ref contact: ' + referralContact);
            List<Case> openCases = new List<Case>();
            openCases = [SELECT Id,
                    Description,
                    Status,
                    Status_Description__c
            FROM Case
            WHERE Referral_Account__c = :referralContact.Referral_Account__c
            AND IsClosed = false];

            return openCases;
    } // getOpenCasesByReferralContactId
    
    public static List<Reference_Client_Retention__c> getOpenRCRByRefClientRetAcctId(Id refClientRetId) {
            List<Reference_Client_Retention__c> openRCRs = new List<Reference_Client_Retention__c>();
        	List<String> statusList = label.Client_Retention_Status.split(',');
        
        	Reference_Client_Retention__c rcr = [SELECT Id, Prospect_Client_Name__c FROM Reference_Client_Retention__c WHERE Id = :refClientRetId];
            openRCRs = [SELECT Id,
                    Current_Step__c,
                    OwnerId,
                    Case_Type__c
            FROM Reference_Client_Retention__c
            WHERE Prospect_Client_Name__c = :rcr.Prospect_Client_Name__c         
            AND Current_Step__c != :statusList];
       
            return openRCRs;
    } // getOpenRCRByRefClientRetAcctId
    
    public static List<Reference_Client_Retention__c> getTotalRCRByRefClientRetAcctId(Id refClientRetId) {
            List<Reference_Client_Retention__c> totalRCRs = new List<Reference_Client_Retention__c>();
        
        	Reference_Client_Retention__c rcr = [SELECT Id, Prospect_Client_Name__c FROM Reference_Client_Retention__c WHERE Id = :refClientRetId];
            totalRCRs = [SELECT Id, Name,
                    Current_Step__c,
                    OwnerId,
                    Owner.Name,     
                    Case_Type__c,
                    Case__c, 
                    Case__r.CaseNumber,     
                    Prospect_Client_Contact__c,
                    Prospect_Client_Contact__r.Name,     
                    Prospect_Client_Name__c,
                    Prospect_Client_Name__r.Name,     
                    Prospect_Client_Number__c,
                    CreatedDate,
                    LastModifiedDate     
            FROM Reference_Client_Retention__c
            WHERE Prospect_Client_Name__c = :rcr.Prospect_Client_Name__c];
       
            return totalRCRs;
    } // getTotalRCRByRefClientRetAcctId
    
    public static Lead getLeadById(Id leadId) {
        try {
            Lead lead = [SELECT Id,
                    Referral_Contact__c, 
                    Referral_National_Account__c, CadenceType__c
            FROM Lead
            WHERE Id = :leadId];

            return lead;
        } catch(Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
    }//getLeadById
    
    public static String getSensitivitiesByLeadId(Id leadID) {
        Lead ld = [Select Id, Referral_Contact__c, Referral_National_Account__c From Lead where Id=:leadId];
        Set<String> sensSet = new Set<String>();
        // DemandGen - Added a null check for null exception error
        Referral_Contact__c refCt = null;
        Referral_Account__c refAct = null;
        if(ld.Referral_Contact__c != null){
            refCt = [Select Id, Sensitivity_List__c from Referral_Contact__c where Id=:ld.Referral_Contact__c];
        }
        if(ld.Referral_National_Account__c != null){
            refAct = [Select Id, Sensitivity_List__c from Referral_Account__c where Id=:ld.Referral_National_Account__c];
        }
        
        if (refCt != null && String.isNotBlank(refCt.Sensitivity_List__c)) {
            sensSet.addAll(refCt.Sensitivity_List__c.split(', '));
        }
        if(refAct != null && String.isNotBlank(refAct.Sensitivity_List__c)) {
            sensSet.addAll(refAct.Sensitivity_List__c.split(', '));
        }
        
                
        String[] sensList = new String[]{};
        sensList.addAll(sensSet);
        sensList.sort();
        String returnValue = '';
        for (String sens: sensList) {
            if (String.isNotBlank(returnValue)) {
               returnValue += ',';
            }
            returnValue += sens;
            
        } // for
        return returnValue;
    }//getSensitivitiesByLeadId
    
    public static Account getAccountByOpportunityId(Id opportunityId) {
        try {
            Account returnAccount = [SELECT Id,
                                    Referral_National_Account__c,
                                    Referral_National_Account__r.Name
                            FROM Account
                            WHERE Id IN (SELECT AccountId
                                        FROM Opportunity
                                        WHERE Id = :opportunityId)];

            return returnAccount;
        } catch(Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
    } // getAccountByOpportunityId
    
    public static Referral_Account__c getReferralAccountById(Id referralAccountId) {
        try {
            Referral_Account__c referralAccount = new Referral_Account__c();

            referralAccount = [SELECT Id,
                    Account__c,
                    Account__r.LastActivityDate,
                    Referral_Source_Business_Type__c,
                    Sensitivity_401_k__c,
                    Sensitivity_Credit_Card_Processing__c,
                    Sensitivity_FSA__c,
                    Sensitivity_Health_Ins__c,
                    Sensitivity_PAO__c,
                    Sensitivity_Sales_Tax__c,
                    Sensitivity_Wrks_Comp__c,
                    Has_Sensitivity_Payroll__c,
                    Sensitivity_List__c,
                    CPA_Relationship_Manager__c,
                    Bank_Centric_Rep__c,
                    Dedicated_Rep__c,
                    Independent_Agent_Relationship_Manager__c,
                    Ref_Record_Type_Name__c,
                    Referral_Payment_Program_Name__c,
                    RecordTypeId,
                    Referral_Type__c,
                    CPA_Program_Status__c,
                    MutualClientTier__c
            FROM Referral_Account__c
            WHERE Id = :referralAccountId];

            return referralAccount;
        }
        catch(Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
    } // getReferralAccountById
    
    public static Reference_Client_Retention__c getRefClientRetById(Id refClientRetId) {
        try {
            Reference_Client_Retention__c refClientRet = new Reference_Client_Retention__c();

            refClientRet = [SELECT Id, RecordTypeId, OwnerId, Owner.Name, Name, Current_Step__c, 
                    Prospect_Client_Name__c,
                    Prospect_Client_Name__r.Name,
                    Prospect_Client_Name__r.LastActivityDate,
                    Prospect_Client_Number__c,
                    Case__c,
                    Case__r.Account.Id,
                    Case__r.Current_Step__c,
                    Case__r.Origin,
                    Case__r.Status
            FROM Reference_Client_Retention__c
            WHERE Id = :refClientRetId];

            return refClientRet;
        }
        catch(Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
    } // getRefClientRetById
    
    public static String getSensitivitiesByRefAcctId(Id referralAccountId) {
        Referral_Account__c refAcct = [Select Id, Sensitivity_List__c
                                             ,(Select Id, Sensitivity_List__c
                                                  From Referral_Contacts__r 
                                                 Where Sensitivity_List__c != null)
                                         From Referral_Account__c where Id=:referralAccountId];
        Set<String> sensSet = new Set<String>();
        if (String.IsNotBlank(refAcct.Sensitivity_List__c)) {
            sensSet.addAll(refAcct.Sensitivity_List__c.split(', '));
        }
        for (Referral_Contact__c refCtct : refAcct.Referral_Contacts__r) {
            sensSet.addAll(refCtct.Sensitivity_List__c.split(', '));
        }
        
        String[] sensList = new String[]{};
        sensList.addAll(sensSet);
        sensList.sort();
        String returnValue = String.join(sensList,',');
       return returnValue;
    } // getSensitivitiesByRefAcctId
    
    public static Referral_Contact__c getReferralContactById(Id referralContactId) {
        try {
            Referral_Contact__c referralContact = new Referral_Contact__c();

            referralContact = [
                    SELECT Id,
                            Contact__c,
                            Contact__r.LastActivityDate,
                            Referral_Type__c,
                            Referral_Account__c,
                            Referral_Account__r.Referral_Source_Business_Type__c,
                            Email_Opt_Out__c,
                            Sensitivity_401_k__c,
                            Sensitivity_Credit_Card_Processing__c,
                            Sensitivity_FSA__c,
                            Sensitivity_Health_Ins__c,
                            Sensitivity_PAO__c,
                            Sensitivity_Sales_Tax__c,
                            Sensitivity_Wrks_Comp__c,
                            Has_Sensitivity_Payroll__c,
                            Sensitivity_List__c,
                            ARM_owner__c,
                            CAS_Engaged__c,
                            CPA_Relationship_Manager__c,
                            Independent_Agent_Relationship_Manager__c,
                            Persona__c,
                			CPA_Program_status__c,
                            End_Date__c
                    FROM Referral_Contact__c
                    WHERE Id = :referralContactId
            ];

            return referralContact;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
    } // getReferralContactById

    public static List<Referral_Contact__c> getReferralContactsByReferralAccount(Id referralAccountId) {
            List<Referral_Contact__c> referralContacts = new List<Referral_Contact__c>();

            referralContacts = [
                    SELECT Id,
                            Contact__c,
                            Referral_Type__c,
                            Email_Opt_Out__c,
                            Sensitivity_401_k__c,
                            Sensitivity_Credit_Card_Processing__c,
                            Sensitivity_FSA__c,
                            Sensitivity_Health_Ins__c,
                            Sensitivity_PAO__c,
                            Sensitivity_Sales_Tax__c,
                            Sensitivity_Wrks_Comp__c,
                            Has_Sensitivity_Payroll__c,
                            Sensitivity_List__c,
                            ARM_owner__c,
                            CAS_Engaged__c,
                            CPA_Relationship_Manager__c,
                            Independent_Agent_Relationship_Manager__c,
                            Persona__c
                    FROM Referral_Contact__c
                    WHERE Referral_Account__c = :referralAccountId
            ];

            return referralContacts;
    } // getReferralContactsByReferralAccount
} // class ObjectBannerQueries