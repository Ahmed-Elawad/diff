/*
 * History
 * --------
   03/18/2022 Dan Carmen        Increment API version

*/ 

public with sharing class OpportunityDA  {
    public List<Opportunity> getOpenOpportunitiesByContactId(Id contactId) {
            List<Opportunity> openOpportunities = new List<Opportunity>();
            openOpportunities = [
                SELECT Id,
                Name,
                StageName
                FROM Opportunity
                WHERE Contact_Name_TAA__c = :contactId
                AND IsClosed = false
            ];
            
            return openOpportunities;
    } // getOpenOpportunitiesByContactId
    
    public List<Opportunity> getOpenOpportunitiesByAccountId(Id accountId) {
            List<Opportunity> openOpportunities = new List<Opportunity>();
            openOpportunities = [
                SELECT Id,
                Name,
                StageName
                FROM Opportunity
                WHERE AccountId = :accountId
                AND IsClosed = false
            ];
            
            return openOpportunities;
    } // getOpenOpportunitiesByAccountId
    
    public List<Opportunity> getOpenOpportunitiesByReferralAccountId(Id referralAccountId) {
            List<Opportunity> openOpportunities = new List<Opportunity>();
            openOpportunities = [
                SELECT Id,
                Name,
                StageName
                FROM Opportunity
                WHERE Referral_Account__c = :referralAccountId
                AND IsClosed = false
            ];
            
            return openOpportunities;
    } // getOpenOpportunitiesByReferralAccountId
    
    public List<Opportunity> getOpenOpportunitiesByReferralContactId(Id referralContactId) {
            List<Opportunity> openOpportunities = new List<Opportunity>();
            openOpportunities = [
                SELECT Id,
                Name,
                StageName
                FROM Opportunity
                WHERE Referral_Contact__c = :referralContactId
                AND IsClosed = false
            ];
            
            return openOpportunities;
    } // getOpenOpportunitiesByReferralContactId
    
    
    public List<Opportunity> getOpportunityById(Id oppId) {
       List<Opportunity> opportunities = new List<Opportunity>();
       opportunities = [
                SELECT Id, 
                Name, 
                StageName, 
                Probability, 
                RecordTypeId 
                FROM Opportunity 
                WHERE Id = :oppId
            ];
            
        return opportunities;
    } // getOpportunityById
    
    public User getPortalUsersByOpportunityId(Id accountId) {
        // Opportunity Chicklet, if there are more than one related community user, Choose the User that has been invited and logged in to the Portal
        //If no one has logged in then most recently created user is choosen
        try {
            User returnPortalUser = new User();
            List<User> users = [SELECT Id,	
                                ContactId,	
                                Contact.Name,LastLoginDate,IsActive,CreatedDate, Requested_Invite_Date__c 	
                                FROM User	
                                WHERE Profile.Name=: 'Customer Community Login User Clone' 	
                                and AccountId=:accountId 	
                                order by Requested_Invite_Date__c desc nulls last];
            System.debug('getPortalUsersByOpportunityId users size:'+users.size());
            if(users.size() != 0){
                returnPortalUser = users[0];
                System.debug('getPortalUsersByOpportunityId User found logged in ='+(returnPortalUser.Lastlogindate != null));
                 
                //return users[0];
            }
            return returnPortalUser;
            
        } catch(Exception ex) {
            System.debug(ex.getMessage()+' '+ex.getStackTraceString());
            throw ex;
        }

    } // getPortalUsersByOpportunityId
    
    public Opportunity getOpportunityInfo(Id opportunityId) {
        try {
            Opportunity returnOpportunity = new Opportunity();
            
            for(Opportunity opp: [ SELECT AccountId, Has_Community_User__c
                                  FROM Opportunity
                                  WHERE Id = :opportunityId])
                returnOpportunity =opp;
            
            return returnOpportunity;
        }
        catch(Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
    }
} // class OpportunityDA