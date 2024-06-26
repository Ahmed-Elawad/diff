/*
 * History
 * --------
 *  11/28/2012  Cindy Freeman       created
 *  10/23/2017  Cindy Freeman       modified to work with PACO not just MMS Sales Tool and return additional fields
 *  11/30/2017  Cindy Freeman       modified query for PACO after receiving new requirements for opty Status and LastModifiedBy
 *  12/11/2017  Cindy Freeman       modified to pull all Payroll platforms no matter if MMS or Core rep
 *  12/15/2017  Justin Stouffer     modified to remove and Account.AccountNumber != Null criteria. May need ot be put back in for MMS.
 *  12/16/2017  Cindy Freeman       modified to add AccountNumber != Null back in just for MMS
 *  01/12/2017  Cindy Freeman       took account number filter out of MMS query 
 *  01/19/2018  Cindy Freeman       changed MMS query to use same StageName filter as Core query
 *  03/15/2018  Cindy Freeman       removed Credit Risk and Credit Risk Health from Account query
 *  11/16/2018 Dan Carmen           Removed Benetrac__c and EAO_Check_Date__c from the Account query - fields were deleted.
 *  11/19/2018 Cindy Freeman        removed Last_Check_Date__c, Next_Check_No__c and States__c from opty detail query - fields were deleted
 *  03/18/2020 Matt Fritschi        SBQQ__PrimaryQuote__r.Name and Primary_Oracle_Quote__r.Name were added to the Oppty detail query
 *  04/28/2020  Jermaine Stukes     Modified query removing MMS query
 *  08/03/2020  Brandon Vidro       Added Onboarding Tool fields for SMB New Client Profile, Added Primary Client Admin Checkbox Contact field for NCO, Added PPP Loan Indicator on Acct
 *  01/12/2021 Brandon Vidro        APR0111386 - Added Primary_Oracle_Quote__c to Oppty Detail Query
 *  04/27/2021 Chris Santoro        Added OpportunityType__c to Oppty query and Industry, NAICS_Code__c, and Decision_Maker__c to Account query
 *	06/01/2021 Chris Santoro        Added PEO fields
 *	10/12/2021 Chris Santoro		Added new fields for PEO Underwriting States
 *  04/07/2022 Chris Santoro		Updated code to pull PEO States from PEO_Underwriting_Code__c object
 *  04/13/2022 Chris Santoro		Updated query to include H&B opportunities 
 *  05/18/2022 Chris Santoro		SFDC-13010: Added CSO_Eligible__c to Opportunity query 
 *  05/08/2022 Chris Santoro		SFDC-14577: Added District Name and Sales Org to help determine PEO users
 *  06/23/2022 Chris Santoro		SFDC-10949: Added CTT Name and Email and Mandate Sale fields to query
 *  03/01/2023 Dan Carmen           Add Billing Type
 *  03/20/2023 Chris Santoro		Added Lock in Rate 
 *  05/15/2023 Dan Carmen           Add Additional Signer
 *  05/19/2023 Chris Santoro		Clean up - Removed PEO queries and moved Oracle Quote Line Items into Opportunity query
 *  06/08/2023 Chris Santoro		Added Split_Number_of_Months__c and Split_Implementation_Fees__c
 *  06/22/2023 Chris Santoro		Added IsSubscriptionQuote__c
 *  07/10/2023 Chris Santoro		Added function to provide Quote file for 401k opptys
 *  07/24/2023 Chris Santoro		Updated PDF Quote query to sort by ModDate
 *  10/16/2023 Chris Santoro		Added Account field set in checkForChildren()
 *  01/12/2024 Chris Santoro		Removed PEO fields from query since PEO tool has been retired
 *  01/12/2024 Chris Santoro		Added method to query for OpportunityLineItem records due to subquery not being able to handle 200+ rows 
 *  02/05/2024 Chris Santoro		Removed OpportunityLineItem subquery from OpportunityServicesOppQuery, cleaned up global fields that were no longer needed
 *  02/08/2024 Chris Santoro		Added getHRSDocuments method to retrieve necessary documents for 401k submissions
 *  04/02/2024 Chris Santoro		Added submissionUpdate()
 * TODO - remove getQuote after March 2024. This method is no longer needed with the addition of getHRSDocuments()

sfLoadClientList
loadOpportunities
sfLoadClientList
opportunityLoad
connectOpportunity
*/


global with sharing class OpportunityServices 
{
    public static integer NBR_DAYS_TO_CHECK=180;
    public static String CA_MANDATE_USER_TYPE='CA Mandate';
    
    global class OppList 
    {
        webservice Id oppId;
        webservice String oppName;  
    }//OppList

    global class OppDetailList 
    {
        webservice Id oppId;
        webservice Opportunity opp;
        webservice Account acc;
        webservice User cttUser;
        webservice String quoteAttachment; //Remove this after March 2024
        webservice List<ContentVersion> attachments;
        webservice Onboarding_Tool__c[] childInfo = new Onboarding_Tool__c[]{};
        webservice OpportunityLineItem[] products = new OpportunityLineItem[]{};
	}//OppDetailList     

    /* Get the open opportunities for the person logged in and any subordinates' opportunities. */
    static webservice List<OppList> getOppList2(String personId) 
    {
        createWsLog(personId, 'getOppList2');
        List<OppList> oppList = getRepOpportunities(personId);
        return oppList;        
    }//getOppList2
    
   	/* Get the opportunity, account, contact, product, user and asset details for specific opportunities.*/    
    static webservice List<OppDetailList> getOppDetailList(List<Id> oppIdsRequested) 
    {
        List<OppDetailList> finalOppDetailList = new List<OppDetailList>();
        
        if (oppIdsRequested.size() < 200)
        {   
            finalOppDetailList.addAll(createOppDetailList(oppIdsRequested));    
        }
        else
        {   
            List<Id> oppIdGrp = new List<Id>();
            Integer i = 0;
            Integer remainder = 0;
            While (i < oppIdsRequested.size())
            {   
                While (((remainder = math.mod(i, 200))!= 0) && (i < oppIdsRequested.size()))            
                {   
                    oppIdGrp.add(oppIdsRequested.get(i));
                    i++;
                }   
                finalOppDetailList.addall(createOppDetailList(oppIdGrp));
                if (i < oppIdsRequested.size())
                {   
                    oppIdGrp = new List<Id>();
                    oppIdGrp.add(oppIdsRequested.get(i));
                    i++;
                }                   
            }
        }
        return finalOppDetailList;
    }//getOppDetailList
    
    private static void createWsLog(String personId, String namedFunction)
    {
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        wslog.SobjName__c =  'PACO Inquiry';
        wsLog.CalledDT__c = System.now();
        wsLog.ServiceName__c = 'OpportunityServices';
        wsLog.CreateDate__c = Date.Today();
        wsLog.NamedFunction__c = namedFunction;
        wsLog.UC_Service__c = false;
        wsLog.Notes__c = personId != null ? 'PersonId= '+personId : null;
        insert wsLog;
    }//createWsLog
    
    private static List<OppList> getRepOpportunities(String personId)
    {
        UserHelper uh = new UserHelper();
        User curUser = uh.getUserById(UserInfo.getUserId());
        String hrPersonId = String.isNotBlank(personId) ? personId : null;
        if(hrPersonId == null && curUser.Name == 'Paco API User')
        {
            return null;
        }
        else
        {
            curUser = personId == null ? curUser : uh.getUserByPersonId(personId);
            Boolean isSalesRep = Utilities.isSalesRep(curUser.Profile.Name);
            Boolean isCoreSales = (curUser.Profile.Name.contains('Core'));
            Boolean isMMSSales = (curUser.Profile.Name.contains('MMS'));
            Boolean isHRSSales = (curUser.Profile.Name.contains('HRS'));
            Boolean isHnBSales = (curUser.Profile.Name.contains('HNB'));
            List<String> HRSRecordTypes = new List<String>{Label.HRS_Opportunity_Record_Type, Label.HRS_Opportunity_FSS_Record_Type};
            List<String> HnBRecordTypes = new List<String>{Label.HNBF_DSA_Opportunity_Record_Type, Label.HNBF_Opportunity_Record_Type};
            System.debug('**OpportunityServices getOppList isCoreSales='+isCoreSales+' isMMSSales='+isMMSSales+' isHRSSales='+isHRSSales+' isHnBSales='+isHnBSales+' profile='+curUser.Profile.Name+' userId='+curUser.Id);
            
            Set<String> coreStageSet = new Set<String>();
            coreStageSet.addAll(Label.OpptyServicesPACO.split(';'));
            
            Set<Id> ownerIds = new Set<Id>();
            ownerIds.add(curUser.Id);
            if (!isSalesRep && curUser.Profile.Name != 'System Administrator API-Paco')
            {   
                Set<Id> optyUIds = uh.getRoleSubordinateSaleUsers(curUser.Id);
                ownerIds.addAll(optyUIds);
            }
            System.debug('**OpportunityServices getOppList ownerIds size='+ownerIds.size()); 
            
            String query = 'Select Id, Name From Opportunity';
            query += ' Where OwnerId IN :ownerIds '; 
            if(curUser.User_Type__c == CA_MANDATE_USER_TYPE)
            {
                query += 'and (Payroll_Platform__c = \'PAY\' or Payroll_Platform__c = \'HRS\') ';
            }
            else if (isHRSSales)
            { 
                query += 'and (Payroll_Platform__c = \'HRS\') ';
                query += 'and Probability >= 10 and Probability <= 80 ';
                query += 'and RecordType.Name in :HRSRecordTypes ';
            }
            else if(isHnBSales) 
            {
            	query += 'and RecordType.Name in :HnBRecordTypes ';
            }
            else 
            {
              query += 'and (Payroll_Platform__c = \'PAY\' or Payroll_Platform__c = \'FLEX\' or Payroll_Platform__c = \'MMS\') ';
            }
            
            query += 'and StageName in :coreStageSet ';
            query += 'and LASTMODIFIEDDATE = Last_90_DAYS';
            query += ' Order by Owner.Name, Name';
            
            System.debug('** OpportunityServices getOppList query='+query);      
            Opportunity[] opps = Database.query(query);
            System.debug('** OpportunityServices getOppList opps='+opps.size());
            
            List<OppList> oppList = new List<OppList>();
            for (Opportunity opp : opps) 
            {
                OppList ol = new OppList();
                ol.oppId = opp.Id;
                ol.oppName = opp.Name;
                oppList.add(ol);
            }
            return oppList;
        }
    }//getRepOpportunities
    
    public static List<OppDetailList> createOppDetailList(List<Id> oppIds) 
    {
        // save account so only need to query once then link together later
        Set <Id> acctIds = new Set<Id>();
        Map<Id,List<OppDetailList>> oppDetailMap = new Map<Id,List<OppDetailList>>();      // acct id and opty, user, product details
        
        String oppQuery = (String)CacheManager.getOrg('OpportunityServicesOppQuery');
        if (oppQuery == null) 
        {
            Set<String> fldSet = new Set<String>();
            DmlHelper.addFieldsToSet(Schema.SObjectType.Opportunity.fieldSets.OpptyServices, '', fldSet);
            oppQuery = DmlHelper.buildQueryFromSet(fldSet,'');
            fldSet.clear();
            /*DmlHelper.addFieldsToSet(Schema.SObjectType.OpportunityLineItem.fieldSets.OpptyServices, '', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Product2.fieldSets.OpptyServices, 'PricebookEntry.Product2.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Product2.fieldSets.OpptyServices, 'Oracle_Quote_Line__r.cafsl__Product__r.', fldSet);
            String oppLineItemQuery = DmlHelper.buildQueryFromSet(fldSet,'OpportunityLineItems');
            oppQuery += ' ,('+oppLineItemQuery+') ';
            fldSet.clear(); */
            DmlHelper.addFieldsToSet(Schema.SObjectType.Onboarding_Tool__c.fieldSets.OpptyServices, '', fldSet);
            String onboardingQuery = DmlHelper.buildQueryFromSet(fldSet,'Onboarding_Tools__r');
            oppQuery += ' ,('+onboardingQuery+') ';
            /*fldSet.clear();
            DmlHelper.addFieldsToSet(Schema.SObjectType.PEO_Onboarding_Checklist__c.fieldSets.OpptyServices, '', fldSet);
            String peoChecklistQuery = DmlHelper.buildQueryFromSet(fldSet,'PEO_Onboarding_Checklists__r');
            oppQuery += ' ,('+peoChecklistQuery+') ';*/
            oppQuery += ',(Select Opportunity_Eligible__c from CSO_Tracking_Recs__r) ';
            oppQuery += ',(Select OwnerId,TYPEOF Owner WHEN USER THEN Name, Email ELSE Name, Email END, Name, Case__c from Reference_CTT__r order by Name asc limit 1) ';
            oppQuery += ' From Opportunity Where Id in :oppIds';
            CacheManager.putOrg('OpportunityServicesOppQuery',oppQuery);
        }

        String curUserId;
        Map<Id,OppDetailList> oppDetailByOppIdMap = new Map<Id,OppDetailList>();
        Id[] parentOnboardingIds = new Id[]{};
        Map<Id,Onboarding_Tool__c> parentOnboardMap = new Map<Id,Onboarding_Tool__c>();
        Opportunity[] opps = Database.query(oppQuery);        
        for (Opportunity opp : opps) 
        {   
            acctIds.add(opp.AccountId); 
            if (curUserId == null) 
            {
                curUserId = opp.ownerId;
            }
            
            OppDetailList[] odlList = (oppDetailMap.containsKey(opp.AccountId) ? oppDetailMap.get(opp.AccountId) : new OppDetailList[]{});
            oppDetailMap.put(opp.AccountId, odlList);
            
            OppDetailList odl = new OppDetailList();
            odl.oppId = opp.Id;
            odl.opp = opp;
            odl.products = getProducts(oppIds);
            
            odlList.add(odl);
            oppDetailByOppIdMap.put(opp.Id, odl);

            System.debug('createOppDetailList Mandate_Sale__c='+opp.Mandate_Sale__c+' hasRefCtt='+(!opp.Reference_CTT__r.isEmpty())); 
            if(opp.Mandate_Sale__c && !opp.Reference_CTT__r.isEmpty()) 
            {
                Reference_CTT__c refCtt = opp.Reference_CTT__r[0];
                if (String.valueOf(refCtt.OwnerId).startsWith('005')) 
                {
                   odl.cttUser = (User)refCtt.Owner;
                }
                System.debug('createOppDetailList odl.cttUser='+odl.cttUser);
                //String ownerId = opp.Reference_CTT__r[0].OwnerId;
                //odl.cttUser = [SELECT User.Name, User.Email FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE UserOrGroupId = :ownerId )];
                //System.debug('** Reference CTT User = ' + odl.cttUser);            
            }
            
            if(opp.Payroll_Platform__c == 'HRS') 
            {
                //old way - to be removed after March 2024
                odl.quoteAttachment = getQuote(opp.Primary_Oracle_Quote__r.Name, opp.Id); //remove this after March 2024
                System.debug('** Quote Attachment = ' + odl.quoteAttachment);    
				//new way
                odl.attachments = getHRSDocuments(opp.Primary_Oracle_Quote__r.Name, opp.Id);
                System.debug('** HRS Documents Attachment = ' + odl.attachments);   
            }
            
            System.debug('createOppDetailList opp.ClientTracking__r='+opp.ClientTracking__r);
            //check for children that need to be selected
            if (opp.ClientTracking__r != null && opp.ClientTracking__r.IsParentTracker__c && opp.ClientTracking__r.Onboarding_Tool__c != null) 
            {
               parentOnboardingIds.add(opp.ClientTracking__r.Onboarding_Tool__c);
               //get the actual onboarding record so we can check the combo field against the child
               for (Onboarding_Tool__c onboard : opp.Onboarding_Tools__r) {
                  if (onboard.Id == opp.ClientTracking__r.Onboarding_Tool__c) {
                     parentOnboardMap.put(onboard.Id, onboard);
                     break;
                  }
               }//for (Onboarding_Tool__c onboard : opp.Onboarding_Tools__r)
            }
        }//for(Opportunity opp : opps
        
        checkForChildren(parentOnboardingIds, parentOnboardMap, oppDetailByOppIdMap);
        
        String acctQuery = (String)CacheManager.getOrg('OpportunityServicesAcctQuery');
        if (acctQuery == null) 
        {
            Set<String> fldSet = new Set<String>();
            DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.OpptyServices, '', fldSet);
            acctQuery = DmlHelper.buildQueryFromSet(fldSet,'');
            fldSet.clear();
            DmlHelper.addFieldsToSet(Schema.SObjectType.Contact.fieldSets.OpptyServices, '', fldSet);
            acctQuery += ' ,('+DmlHelper.buildQueryFromSet(fldSet,'Contacts')+' Where Sales_Contact__c = true or OwnerId = :curUserId) ';
            fldSet.clear();
            DmlHelper.addFieldsToSet(Schema.SObjectType.Asset.fieldSets.OpptyServices, '', fldSet);
            acctQuery += ' ,('+DmlHelper.buildQueryFromSet(fldSet,'Assets')+' Where UsageEndDate = null) ';
            acctQuery += ' From Account Where Id In :acctIds ';
            CacheManager.putOrg('OpportunityServicesAcctQuery',acctQuery);
        }//if(acctQuery == null
        
        Account[] accts = Database.query(acctQuery);
        // add account, contact, asset details to opportunity details
        List<OppDetailList> retList = new List<OppDetailList>();
        for (Account acct : accts) 
        {
            List<OppDetailList> odlList = oppDetailMap.get(acct.Id); 
            if (odlList != null) 
            {
                for (OppDetailList odl : odlList) 
                {
                    odl.acc = acct;
                }
                retList.addAll(odlList);
            }
        }
        
        return retList;
   }//getOppDetailList
    
   public static void checkForChildren(Id[] parentOnboardingIds, Map<Id,Onboarding_Tool__c> parentOnboardMap, Map<Id,OppDetailList> oppDetailByOppIdMap) 
   {
      System.debug('checkForChildren parentOnboardingIds='+parentOnboardingIds.size()+' parentOnboardMap='+parentOnboardMap.size()+' oppDetailByOppIdMap='+oppDetailByOppIdMap.size());
      if (!parentOnboardingIds.isEmpty()) {
         String onboardingQuery = (String)CacheManager.getOrg('OpportunityServicesCheckForChildren');
         if (onboardingQuery == null) {
            Set<String> fldSet = new Set<String>();
            DmlHelper.addFieldsToSet(Schema.SObjectType.Onboarding_Tool__c.fieldSets.OpptyServices, '', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.OpptyServices, 'AccountId__r.', fldSet);
            onboardingQuery = DmlHelper.buildQueryFromSet(fldSet,'Onboarding_Tool__c')+' Where Parent_Onboarding_Record__c in :parentOnboardingIds';
            CacheManager.putOrg('OpportunityServicesCheckForChildren', onboardingQuery);
         }
         Onboarding_Tool__c[] childOnboards = Database.query(onboardingQuery);
          
         Map<Id,Onboarding_Tool__c> updateOnboardMap = new Map<Id,Onboarding_Tool__c>();
         for (Onboarding_Tool__c child : childOnboards) {
            System.debug('checkForChildren IsSameFEIN__c='+child.ClientTracking__r.IsSameFEIN__c);
            if (child.Combo__c == 'Yes' || (child.ClientTracking__c != null && child.ClientTracking__r.IsSameFEIN__c)) {
               if (child.Combo__c != 'Yes') {
                  System.debug('checkForChildren updateChild');
                  child.Combo__c = 'Yes';
                  Onboarding_Tool__c updateRec = new Onboarding_Tool__c(Id=child.Id, Combo__c='Yes');
                  updateOnboardMap.put(updateRec.Id, updateRec);
               }
               Onboarding_Tool__c parentOnboarding = parentOnboardMap.get(child.Parent_Onboarding_Record__c);
               System.debug('checkForChildren parentOnboarding='+(parentOnboarding != null));
               if (parentOnboarding != null && parentOnboarding.Combo__c != 'Yes') {
                  System.debug('checkForChildren updateParent');
                  parentOnboarding.Combo__c = 'Yes';
                  Onboarding_Tool__c updateRec = new Onboarding_Tool__c(Id=parentOnboarding.Id, Combo__c='Yes');
                  updateOnboardMap.put(updateRec.Id, updateRec);
               }
            }
            OppDetailList odl = oppDetailByOppIdMap.get(child.Parent_Onboarding_Record__r.Opportunity_Id__c);
            if (odl != null) 
            {
               odl.childInfo.add(child);
            }
         }
         if (!updateOnboardMap.isEmpty()) 
         {
            OnboardingToolHelper.SKIP_TRIGGERS = true;
            DmlHelper.performDML2(updateOnboardMap.values(), DmlHelper.DML_UPDATE, 'OpportunityServices', 'checkForChildren', 'Update onboarding recs', true); 
         }
      }//if(!parentOnboardingIds.isEmpty
   }//checkForChildren
    
    public static string getQuote(string quoteName, string oppId) //remove this method after March 2024
    {
        System.debug('Quote Name: ' + quoteName);
        if(String.isNotBlank(quoteName))
        {
            List<ContentDocumentLink> listOfAttachments = new List<ContentDocumentLink>([SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocument.Id, ContentDocument.ContentModifiedDate FROM ContentDocumentLink WHERE LinkedEntityId =:oppId ORDER BY  ContentDocument.ContentModifiedDate DESC]);
            //System.debug('List of attachments: '+listOfAttachments);
            if(listOfAttachments != null)
            {
                for(ContentDocumentLink atta : listOfAttachments)
                {
                    if(atta.ContentDocument.Title.startsWithIgnoreCase(quoteName))
                    {
                        ContentVersion file = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :atta.ContentDocument.Id AND IsLatest = true];
                        System.debug('Quote Attachment: '+file);
                        blob attachmentBody = file.VersionData;
                        String afterblob = EncodingUtil.base64Encode(attachmentBody);
                        System.debug('Attachment: '+afterblob);
                        return afterblob;
                    }
                }  
            }
        }
        return null;
    }
    
    public static List<ContentVersion> getHRSDocuments(string quoteName, string oppId)
    {
        //System.debug('Quote Name: ' + quoteName);
        List<ContentVersion> attachments = new List<ContentVersion>();
        List<ContentDocumentLink> listOfAttachments = new List<ContentDocumentLink>([SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocument.Id, ContentDocument.ContentModifiedDate FROM ContentDocumentLink WHERE LinkedEntityId =:oppId ORDER BY  ContentDocument.ContentModifiedDate DESC]);
        for(ContentDocumentLink atta : listOfAttachments)
        {
            //System.debug('Title: ' + atta.ContentDocument.Title);
            if((String.isNotBlank(quoteName) && atta.ContentDocument.Title.startsWithIgnoreCase(quoteName)) ||
              atta.ContentDocument.Title.Contains('-Data Export') ||
              atta.ContentDocument.Title.Contains('-Mapping Report'))
            {
                ContentVersion file = [SELECT VersionData, Title, FileExtension FROM ContentVersion WHERE ContentDocumentId = :atta.ContentDocument.Id AND IsLatest = true];
                //System.debug('Attachment: '+);
                blob attachmentBody = file.VersionData;
                String afterblob = EncodingUtil.base64Encode(attachmentBody);
                attachments.Add(file);
                //System.debug('Attachment: '+afterblob);
                //return afterblob;
            }
        }  
        System.debug('Attachments: '+attachments);
        return attachments;
    }//getHRSDocuments()
    
    public static OpportunityLineItem[] getProducts(List<Id> oppIds)
    {        
        String prodQuery = (String)CacheManager.getOrg('OpportunityServicesProdQuery');
        System.debug('brefore: ' + prodQuery);
        if (prodQuery == null) {
            Set<String> fldSet = new Set<String>();
            DmlHelper.addFieldsToSet(Schema.SObjectType.OpportunityLineItem.fieldSets.OpptyServices, '', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Product2.fieldSets.OpptyServices, 'PricebookEntry.Product2.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Product2.fieldSets.OpptyServices, 'Oracle_Quote_Line__r.cafsl__Product__r.', fldSet);
            String oppLineItemQuery = DmlHelper.buildQueryFromSet(fldSet,'OpportunityLineItem');
            prodQuery = oppLineItemQuery;
            prodQuery += ' Where OpportunityId in :oppIds';
            System.debug('test: ' + prodQuery);
            CacheManager.putOrg('OpportunityServicesProdQuery',prodQuery);
        }
        
        OpportunityLineItem[] products = new OpportunityLineItem[]{};

        for(OpportunityLineItem item : Database.query(prodQuery))
        {
            products.add(item);
        }
        System.debug(products);
        
        return products;
    }//getProducts()
    
    static webservice void submissionUpdate(List<string> oppId, DateTime submissionTime)
    {
        List<Opportunity> records = [SELECT Id FROM Opportunity WHERE Id IN :oppId];
        for (Opportunity record : records)
        {
            //record.PACO_Submission_Date__c = DateTime.now();
            record.PACO_Submission_Date__c = submissionTime;
            System.debug('Submission time assigned: ' + record.PACO_Submission_Date__c);
        }
        update records;       
        System.debug('Submission time updated: ' + submissionTime);
    }
   
} // OpportunityServices