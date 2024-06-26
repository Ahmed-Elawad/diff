@IsTest
public with sharing class PowerlinksDAMock implements PowerLinksDAInterface {
    private Boolean causeException = false;

    public Integer GetPowerlinksCallCount { get; private set; }

    public PowerlinksDAMock(Boolean causeException) {
        GetPowerlinksCallCount = 0;
        this.causeException = causeException;
    }

    public List<Powerlinks__c> getPowerlinksByUserSalesOrg(String salesOrg) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        GetPowerlinksCallCount++;
        return new List<Powerlinks__c>();
    }
}