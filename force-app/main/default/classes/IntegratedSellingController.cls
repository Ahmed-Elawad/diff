/* 
 * Server side controller for LinkOppsFromAccount Aura Bundle
 * and LinkOppsFromOpp Aura Bundle that are located inside IntegratedSelling Aura Component
 *
 * History
 * -------
 * 09/27/2018 Lynn Michels          Created.
 * 04/24/2020 Pujitha M             Update Referral partner only when blank BAU Case: 36449230
 * 07/06/2020  Jacob Hinds         Added without sharing per PMD
 *
 */
 public without sharing class IntegratedSellingController {
    //used by LinkOppsFromAccount
    @AuraEnabled
    public static List<Opportunity> getAcctOpps(Id recordId) {
        system.debug('getAcctOpps recordid: '+recordId);
        Set<String> oppRecordTypes = getOppRecordTypes();
    system.debug('lm oppRecordTypes '+oppRecordTypes);    
            //only display the opps with record types related to integrated selling
       return [Select Id, Name, StageName, CloseDate, OwnerId, Owner.Name, OpportunityType__c, RecordType.Name, AccountId, Account.Name, Owner.ContactId
               From Opportunity Where AccountId = :recordId AND RecordType.Name IN: oppRecordTypes ORDER BY CreatedDate DESC LIMIT 10];  //recordId is set in 
    }
    
    //used by LinkOppsFromOpp
    @AuraEnabled
    public static List<Opportunity> getOpps(Id recordId) {
        system.debug('getOpps recordid: '+recordId);
        //get this opportunitity's accountId
        Opportunity oppResult = [Select Id, AccountId From Opportunity Where Id = :recordId];
        system.debug('lm oppResult '+oppResult);
        Set<String> oppRecordTypes = getOppRecordTypes();  //only display the opps with record types related to integrated selling
        return [Select Id, Name, StageName, CloseDate, OwnerId, Owner.Name, OpportunityType__c, RecordType.Name, AccountId, Account.Name, Owner.ContactId
               From Opportunity Where AccountId = :oppResult.AccountId AND RecordType.Name IN: oppRecordTypes ORDER BY CreatedDate DESC LIMIT 10];
    }
    
    
    //public static can be used in both methods for labels.
    @AuraEnabled
    public static void processOpportunities(List<Opportunity> opps) {
        
        String INTSELL = 'Integrated Selling';
        //create an opp id to opp map to be able to remove opps that are processed
        Map<id,Opportunity> idToOppMap = new Map<id,Opportunity>();
        
        for(Opportunity o : opps){
            idToOppMap.put(o.id,o);
        }//end for 
   system.debug('processOpportunities opps to process '+opps);
        
        //populate a map of Referral Partner Name and Referral Partner record
        Map<String, Referral_Partner__c> nameToReferralPartnerMap = getReferralPartners();
                       
        //search for the referrals that already exist
        //look for referrals with the Selling Opp = to an opp passed in
        List<Referral__c> referrals = new List<Referral__c>();
        referrals = [SELECT Id, Selling_Opportunity__c, Selling_Opportunity__r.RecordType.Name, Referral_Partner__c
                           ,Referral_Partner__r.Partner_Type__c
                           ,PartnerReferral__c
                     FROM Referral__c WHERE Selling_Opportunity__c IN: opps];
        
        List<Referral__c> referralsToUpdate = new List<Referral__c>();
        Id existingPartRefId = null;
        //if referrals already exist, update them
        if(!referrals.isEmpty()){
            for(Referral__c r : referrals){
                if (existingPartRefId == null && r.PartnerReferral__c != null) {
                   existingPartRefId = r.PartnerReferral__c;
                }//end if
            if(r.Referral_Partner__r.Partner_Type__c != INTSELL){ //only process if the type does not equal integrated selling  
                System.debug('r.Selling_Opportunity__r.RecordType.Name:::'+r.Selling_Opportunity__r.RecordType.Name);
                RecordType__c rts = getSalesOrg(r.Selling_Opportunity__r.RecordType.Name);
                if (rts != null) {
                    Referral_Partner__c rp = nameToReferralPartnerMap.get(rts.Sales_Org__c);  //set the referral partner that is related to the opp's record type
                    //Update Referral partner only when blank BAU Case: 36449230
                    if (rp != null && r.Referral_Partner__c == null) { 
                     r.Referral_Partner__c = rp.id; 
                    }//end if rp
                }//end if SalesOrg
            }//end if integrated selling

              //add referral to record list to update
              referralsToUpdate.add(r);
                
                //pull the opportunity related to this referral out of the map so it doesn't get processed any more
                idToOppMap.remove(r.Selling_Opportunity__c);
            
            }//end for
       }//end if isEmpty
              
        if(!referralsToUpdate.isEmpty()){
            DmlHelper.performDML2(referralsToUpdate, DmlHelper.DML_UPDATE, 'IntegratedSellingController', 'processOpportunities', 'find existing referrals and update them', true);
            
        }
       //create referral records for the opps left in the map
       //if neither opp had a referral, they will both still be in the map for creating new referrals 
       createReferrals(idToOppMap.values(), existingPartRefId);  //create referral and populate referral lookup on their opps
       createReferralJoin(opps);  //create referral join, update referrals and then update opps again
   
    }// end processOpportunities
    
    //load the referral partners map
    public static Map<String, Referral_Partner__c> getReferralPartners(){
        String INTSELL = 'Integrated Selling';
        //get referral partners with type "Integrated Selling"
        List<Referral_Partner__c> refPartners = ReferralQueries.selectRefPartnersCache(INTSELL, null);
       
        system.debug('getReferralPartners partner list from ReferralQueries' +refPartners);
        //populate map with referral partner name and referral partner record
        Map<String, Referral_Partner__c> nameToReferralPartnerMap = new Map<String, Referral_Partner__c>();
        for(Referral_Partner__c rp : refPartners){
            nameToReferralPartnerMap.put(rp.Name, rp);
        }//end for
        return nameToReferralPartnerMap;
    }//end getReferralPartners
    
    public static void createReferrals(List<Opportunity> opps, Id existingPartRefId) {
        system.debug('createReferrals ');
        Map<String, Referral_Partner__c> nameToReferralPartnerMap = getReferralPartners();
        Referral__c newReferral;
        List<Referral__c> referralsToCreate = new List<Referral__c>();
    
        for (Opportunity o : opps){
            RecordType__c rts = getSalesOrg(o.RecordType.Name);
            if (rts != null) {
                Referral_Partner__c rp = nameToReferralPartnerMap.get(rts.Sales_Org__c);  //set the referral partner that is related to the opp's record type
                if (rp != null) {
                    newReferral = new Referral__c(Name = CreateOppAndMeeting.getOppName(o.Account.Name, rts.Sales_Org__c,ReferralController.REF_NAME_SIZE)
                                                     ,Referral_Partner__c = rp.id
                                                     ,PartnerReferral__c = existingPartRefId
                                                 );  
                   
                    //populate the 'Refer To' contact field
                    if(o.Owner.ContactId != null){
                        newReferral.Contact__c = o.Owner.ContactId;  //Refer To contact field with filter HR Person Id != null and Account Name starts with Paychex Inc SA
                    }
                    newReferral.Selling_Opportunity__c = o.id;
                    newReferral.Account__c = o.AccountId;
                    newReferral.OwnerId = o.OwnerId;
                    newReferral.User__c = o.OwnerId;
                    newReferral.Status__c = 'Approved';
                    ReferralMethods.addToProcessNotes(newReferral, 'Created from IntegratedSellingController');
                    referralsToCreate.add(newReferral);
                }//end if rp
            }//end if SalesOrg
        }//end for opps
        if(!referralsToCreate.isEmpty()){
            DmlHelper.performDML2(referralsToCreate, DmlHelper.DML_INSERT, 'IntegratedSellingController', 'createReferrals', 'create Referral records', true);
        }   
    }//end createReferrals
    
    public static Set<String> getOppRecordTypes() {
    Map<String, Referral_Partner__c> nameToReferralPartnerMap = getReferralPartners();
        Set<String> recordTypeNames = new Set<String>();
        for(Referral_Partner__c refPartner : nameToReferralPartnerMap.values()){  //holds all of the referral partners
            //SalesOrg__c salesOrg = SalesOrg__c.getInstance(refPartner.Name);
            for(RecordType__c recordTypeSetting : RecordType__c.getAll().values()){
                if(recordTypeSetting.ObjectName__c == 'Opportunity' && recordTypeSetting.Sales_Org__c == refPartner.Name){
                    recordTypeNames.add(recordTypeSetting.RecordTypeName__c);
                }
            }
        }
        system.debug('LM record type names '+recordTypeNames);
        return recordTypeNames;
    }//end getRecordTypeNames
    
    public static RecordType__c getSalesOrg(String rtName) {
        RecordType__c recordTypeSetting = null;
        for (RecordType__c rts : RecordType__c.getAll().values()) {
            if (rts.ObjectName__c == 'Opportunity' && rts.RecordTypeName__c == rtName) {
                recordTypeSetting = rts;
                break;
            } 
        }
        return recordTypeSetting;
    }
    

    public static void createReferralJoin(List<opportunity> opps) {
        system.debug('createReferralJoin ');
        String[] chatterBody = new String[]{};
            chatterBody.add('Your Opportunities have been linked as Integrated Selling leads.');
        List<id> mentionList = new List<id>();
        List<ReferralJoin__c> refJoinList = new List<ReferralJoin__c>();
        ReferralJoin__c refJoin = new ReferralJoin__c();
        List<Referral__c> referrals = [SELECT Id, Selling_Opportunity__c, Selling_Opportunity__r.ownerId, Referral_Partner__r.Name FROM Referral__c WHERE Selling_Opportunity__c In: opps];
        if(!referrals.isEmpty()){
            for (Referral__c r : referrals){
                mentionList.add(r.Selling_Opportunity__r.ownerid);
                if(r.Referral_Partner__r.Name =='PAY'){
                    refJoin.Core_Referral__c = r.id;
                }
                if(r.Referral_Partner__r.Name =='MMS'){
                    refJoin.MMS_Referral__c = r.id;
                }
                if(r.Referral_Partner__r.Name =='PAS'){
                    refJoin.PAS_Referral__c = r.id;
                }
            }//end for
       }//end if
        refJoinList.add(refJoin);
        if(!refJoinList.isEmpty()){
           DmlHelper.performDML2(refJoinList, DmlHelper.DML_INSERT, 'IntegratedSellingController', 'createReferralJoin', 'create referral join', true);
        }
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        //update referral records
        for(Referral__c r : referrals){
            r.ReferralJoin__c = refJoin.id;
        }//end for
        //update referrals;
        DmlHelper.performDML2(referrals, DmlHelper.DML_UPDATE, 'IntegratedSellingController', 'createReferralJoin', 'update Referral records after referral join created', true);
            
        Map<Id, ReferralJoin__c> joinMap = ReferralMethods.retrieveJoins(referrals);
        for (Referral__c rfrl : referrals) {
           Opportunity opp = new Opportunity(id = rfrl.Selling_Opportunity__c);
           ReferralMethods.setJointApptInfo(opp, rfrl, joinMap.get(rfrl.ReferralJoin__c));
           opp.ReferralLookup__c = rfrl.Id;
           oppsToUpdate.add(opp);
           ChatterMentionPost.createChatterMentionPost(opp.Id, mentionList, chatterBody, true,true);
       }
       DmlHelper.performDML2(oppsToUpdate, DmlHelper.DML_UPDATE, 'IntegratedSellingController', 'createReferralJoin', 'update opps', true);
       
    }//end createReferralJoin
    
}//end