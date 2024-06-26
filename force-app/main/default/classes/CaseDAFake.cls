@IsTest
public class CaseDAFake implements CaseDAInterface {
    private Boolean causeException = false;

    public Integer OpenCasesCallCount { get; private set; }

    public CaseDAFake(Boolean causeException) {
        OpenCasesCallCount = 0;
        this.causeException = causeException;
    }

    public List<Case> getOpenCasesByContactId(Id contactId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenCasesCallCount++;
        return new List<Case>();
    }

    public List<Case> getOpenCasesByAccountId(Id accountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenCasesCallCount++;
        return new List<Case>();
    }

    public List<Case> getOpenCasesByReferralAccountId(Id referralAccountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenCasesCallCount++;
        return new List<Case>();
    }

    public List<Case> getOpenCasesByReferralContactId(Id referralContactId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenCasesCallCount++;
        return new List<Case>();
    }
}