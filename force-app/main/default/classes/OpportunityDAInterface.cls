public interface OpportunityDAInterface {
    List<Opportunity> getOpenOpportunitiesByContactId(Id contactId);
    List<Opportunity> getOpenOpportunitiesByAccountId(Id accountId);
    List<Opportunity> getOpenOpportunitiesByReferralAccountId(Id referralAccountId);
    List<Opportunity> getOpenOpportunitiesByReferralContactId(Id referralContact);
    List<Opportunity> getOpportunityById(Id oppId);
    User getPortalUsersByOpportunityId(Id accountId);
    Opportunity getOpportunityInfo(Id opportunityId);
}