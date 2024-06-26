/*
 * HISTORY
 * 07/07/2020	Matt Fritschi	Created
 * 07/30/2020	Jake Hinds		Moving logic out of constructor into a method,refactor to bulkify
 * 03/07/2021   Brandon Vidro   Modified logic for creating opp and removed debug logs
 * 
 */
public without sharing class CreateReferringOpp {

    public static void createOpp(List<Referral__c>refs){
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Id> ampReferralIds = new List<Id>();
        List<Id> sellingOppIds = new List<Id>();
        List<Id> refAccountIds = new List<Id>();
        List<Id> ampReferringUserIds = new List<Id>();
        List<Id> ampAdvocateIds = new List<Id>();
        Opportunity[] referringOpps = new Opportunity[]{};
        Map<String,Referral__c> refByOppName = new Map<String,Referral__c>();
        Set<Id> priceBookIds = new Set<Id>();
        Map<Id,Id>priceBookEntryIdByPricebookId = new Map<Id,Id>();
        OpportunityLineItem[] olisToInsert = new OpportunityLineItem[]{};
        
        for(Referral__c ref : refs)
        {
            if(ref.Amplifinity_Referral__c != null)
            {
                ampReferralIds.add(ref.Amplifinity_Referral__c);
            }
            if(ref.Referring_User__c != null)
            {
                ampReferringUserIds.add(ref.Referring_User__c);
            }
            sellingOppIds.add(ref.Selling_Opportunity__c);
            refAccountIds.add(ref.Account__c);
        }
        
        Map<Id, amp_dev__Amp_Referral__c> ampReferrals = new Map<Id, amp_dev__Amp_Referral__c>([SELECT Id, Name, amp_dev__Advocate__c FROM amp_dev__Amp_Referral__c WHERE Id IN :ampReferralIds]);
        Map<Id, Opportunity> sellingOpps = new Map<Id, Opportunity>([SELECT Id, Name, OwnerId, CloseDate, Pricebook2Id, Referring_Employee__c FROM Opportunity WHERE Id IN :sellingOppIds]);
        Map<Id, Account> referralAccounts = new Map<Id, Account>([SELECT Id, Name, OwnerId, NumberOfEmployees, Frequency__c FROM Account WHERE Id IN :refAccountIds]);
        Map<Id, Contact> referringEmployees = new Map<Id, Contact>([SELECT Id, Name, User_Lookup__c FROM Contact WHERE User_Lookup__c IN :ampReferringUserIds and RecordTypeId = '012700000001UNG']);

        for(amp_dev__Amp_Referral__c ampRef : ampReferrals.values())
        {
            ampAdvocateIds.add(ampRef.amp_dev__Advocate__c);
        }
        
        Map<Id, amp_dev__Amp_Advocate__c> ampAdvocates = new Map<Id, amp_dev__Amp_Advocate__c>([SELECT Id, Name, OwnerId, Account__c FROM amp_dev__Amp_Advocate__c WHERE Id IN :ampAdvocateIds]);
        
        list<Id> advocateAccountIds = new List<Id>();
        for(amp_dev__Amp_Advocate__c ampAdv : ampAdvocates.values())
        {
            advocateAccountIds.add(ampAdv.Account__c);
        }
        
        Map<Id, Account> advocateAccounts = new Map<Id, Account>([SELECT Id, Name, OwnerId FROM Account WHERE Id IN :advocateAccountIds]);
        
        for(Referral__c ref : refs)
        {
            Opportunity sellingOpp = sellingOpps.get(ref.Selling_Opportunity__c);
            Opportunity referringOpp;
            Account acct = referralAccounts.get(ref.Account__c);
            
            if(sellingOpp != null && acct != null)
            {
                amp_dev__Amp_Referral__c ampRef = ampReferrals.get(ref.Amplifinity_Referral__c);
                if(ampRef != null)
                {
                    amp_dev__Amp_Advocate__c ampAdv = ampAdvocates.get(ampRef.amp_dev__Advocate__c);
                    if(ampAdv != null && ampAdv.OwnerId != Label.Amplifinity_API_User_Id)
                    {
                        Account advAcct = advocateAccounts.get(ampAdv.Account__c);
                        if(ref.OwnerId != null && ampAdv.OwnerId != ref.OwnerId)
                        {
                            try
                            {
                                referringOpp = new Opportunity(Name=(acct != null ? acct.Name : '')+'-Referral', LeadSource='Referral-Paychex Referral Network', Client_Referral__c=acct.Id, OwnerId = ampAdv.OwnerId,
                                                               AccountId = acct.Id);
                                if(sellingOpp.Referring_Employee__c == null && ref.Referring_User__c != null)
                                {
                                    for(Contact ctct : referringEmployees.values())
                                    {
                                        if(ref.Referring_User__c == ctct.User_Lookup__c)
                                        {
                                            sellingOpp.Referring_Employee__c = ctct.Id;
                                            referringOpp.Referring_Employee__c = ctct.Id;
                                            break;
                                        }
                                    }
                                    
                                    oppsToUpdate.add(sellingOpp);
                                }
                                ReferralMethods.setOpportunityFields(ref,referringOpp,false);
                                referringOpp.AccountId = acct.Id;
                                referringOpp.Employees_Paid_Per_Payroll__c = acct.NumberOfEmployees;
                                referringOpp.OpportunityType__c=Label.OppType_Referral;
                                referringOpp.OpportunityId__c = 'ReferralOpp';
                                referringOpp.LeadSource = 'Referral-Paychex Referral Network';
                                
                                //recordTypeMap = RecordTypeHelper.getRecordTypeByMapping(salesOrgs,'Opportunity',MAPPING_TYPES);
                                // get the referral record type for the sales org
                                UserHelper uh = new UserHelper();
                                User opptyOwner = uh.getUserById(ampAdv.OwnerId);
                                String salesOrg = opptyOwner.Sales_Org__c;
                                String[] salesOrgs = new String[]{salesOrg};
                                String[] MAPPING_TYPES = new String[]{RecordTypeHelper.MAPPING_REFERRAL};
                                Map<String,Record_Type_Mapping__c>
                                recordTypeMap = RecordTypeHelper.getRecordTypeByMapping(salesOrgs,'Opportunity',MAPPING_TYPES);
                                
                                String key = salesOrg+RecordTypeHelper.MAPPING_REFERRAL;
                                Record_Type_Mapping__c rtm = recordTypeMap.get(key);
                                if (rtm != null) {
                                    referringOpp.RecordTypeId = rtm.RecordTypeId__c;
                                } else {
                                    // we want to set this before saving so picklist options will display properly on the form
                                    referringOpp.RecordTypeId = RecordTypeHelper.getDefaultRecordType('Opportunity').getRecordTypeId();
                                }
                                //ReferringOpp.Pricebook2Id = sellingOpp.Pricebook2Id;
                                referringOpp.StageName = 'Referred';
                                
                                CreateOppAndMeeting coam = new CreateOppAndMeeting(salesOrg);
                                referringOpp.Frequency__c = (acct.Frequency__c != null ? coam.convertFrequency(acct.Frequency__c) : null);
                                referringOpp.ReferralLookup__c = ref.Id;
                                referringOpp.Employees_Paid_Per_Payroll__c = acct.NumberOfEmployees;
                                referringOpp.CloseDate = coam.getCloseDate();
                                
                                ProductHelper ph = new ProductHelper();
                                ph.getPricebookBySalesOrg(salesOrg);
                                if(ph.pricebook != null && !Test.isRunningTest())
                                {
                                    referringOpp.Pricebook2Id = ph.pricebook.Id;
                                    if(!priceBookIds.contains(ph.PriceBook.Id)){
                                    	priceBookIds.add(ph.PriceBook.Id);
                                    }
                                }
                                else if(Test.isRunningTest())
                                {
                                    referringOpp.Pricebook2Id = Test.getStandardPricebookId();
                                	if(!priceBookIds.contains(referringOpp.Pricebook2Id)){
                                    	priceBookIds.add(referringOpp.Pricebook2Id);
                                    }
                                }
                                referringOpps.add(referringOpp);
                                refByOppName.put(referringOpp.name,ref);
                            }//try
                            catch(Exception e)
                            {
                                ErrorLog.LogError('CreateReferringOpp','createOpp','in try catch',ref.Id,e);
                            }
                            
                        }//if(advAcct!=null
                    }//if(ampAdv != null
                }//if ampRef!=null
            }//if sellingOpp!=null      
            
        }//for referral ref
        
        if(!referringOpps.isEmpty()){
            DmlHelper.performDML2(referringOpps, DmlHelper.DML_Insert, 'CreateReferringOpp', 'CreateReferringOpp', 'inserting referral opp', true);
            Id[] oppIds = new Id[]{};
            //put opp ids into collection so we can requery
            for(Opportunity opp:referringOpps){
                oppIds.add(opp.Id);
            }
            //organize pricebook entry by pricebook so we can get it later for the opp
            Map<Id,Id> priceBookEntryByPricebookId = new Map<Id,Id>();
            if(!priceBookIds.isEmpty()){
                PricebookEntry[] pricebookEntries = [SELECT Id, Name,Pricebook2Id FROM PricebookEntry WHERE Pricebook2Id in :priceBookIds 
                                    AND Product2Id=:Label.Amplifinity_Referral_Product_Id LIMIT 1];
                for(PricebookEntry pe:pricebookEntries){
                    priceBookEntryIdByPricebookId.put(pe.Pricebook2Id,pe.Id);
                }
            }
            //requery opps to get the pricebook id
            Map<Id,Opportunity> refOppMap = new Map<Id,Opportunity>([SELECT Id, Name, Pricebook2Id,AccountId FROM Opportunity WHERE Id in :oppIds]);
            PricebookEntry testPE;
            //need to use dummy pricebook entry for tests because they won't be setup
            if(Test.isRunningTest()){
                Product2 testProd = [SELECT Id, Name FROM Product2 WHERE Name='Amp Test Product 123' LIMIT 1];
                testPE = [SELECT Id, Name FROM PricebookEntry WHERE Product2Id=:testProd.Id LIMIT 1];
            }
            for(Opportunity opp:refOppMap.values()){
                //set referring opp on corresponding referral. is opp name unique enough? didn't have ID when map was built
                if(refByOppName.containsKey(opp.Name)){
                    Referral__c ref = refByOppName.get(opp.Name);
                    ref.Referring_Opportunity__c = opp.Id;
                }
                //get pricebook entry to create line item
                if(priceBookEntryIdByPricebookId.containsKey(opp.Pricebook2Id)){
                	Id priceBookEntryId = priceBookEntryIdByPricebookId.get(opp.Pricebook2Id);
                    OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp.Id, PricebookEntryId=priceBookEntryId, 
                                                                      Product2Id=Label.Amplifinity_Referral_Product_Id, Quantity=1, TotalPrice=0);
                    olisToInsert.add(oli);
                }
                else if(Test.isRunningTest() && testPE!=null){
                    OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp.Id, PricebookEntryId=testPE.Id, 
                                                                      Product2Id=Label.Amplifinity_Referral_Product_Id, Quantity=1, TotalPrice=0);
                    olisToInsert.add(oli);
                }
            }
            //insert line items
            if(!olisToInsert.isEmpty()){
                DmlHelper.performDML2(olisToInsert, DmlHelper.DML_Insert, 'CreateReferringOpp', 'CreateReferringOpp', 'insert referring line items', true);
            }
        }//if referringOpps not empty
        //update selling opps that had the referring employee set
        if(!oppsToUpdate.isEmpty()){
            DmlHelper.performDML2(oppsToUpdate, DmlHelper.DML_UPDATE, 'CreateReferringOpp', 'CreateReferringOpp', 'update opps referring employee', true);
        }
    }//createOpp
    
}