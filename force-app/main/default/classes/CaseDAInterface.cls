public interface CaseDAInterface {
    List<Case> getOpenCasesByContactId(Id contactId);
    List<Case> getOpenCasesByAccountId(Id accountId);
    List<Case> getOpenCasesByReferralAccountId(Id referralAccountId);
    List<Case> getOpenCasesByReferralContactId(Id referralContactId);
}