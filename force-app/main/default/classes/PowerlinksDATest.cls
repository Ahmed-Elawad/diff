@IsTest
private class PowerlinksDATest {
    @IsTest
    static void getPowerlinksByUserSalesOrg_GivenSalesOrg_ReturnsPowerlinksForGivenSalesOrg() {
        test.startTest();

        Powerlinks__c expectedPowerlink = new Powerlinks__c();
        expectedPowerlink.Name = 'Testing Link';
        expectedPowerlink.Label__c = 'Test Link';
        expectedPowerlink.URL__c = 'test url';
        expectedPowerlink.Is_Internal__c = false;
        expectedPowerlink.Sales_Org__c = 'Expected';
        insert expectedPowerlink;

        Powerlinks__c otherPowerlink = new Powerlinks__c();
        otherPowerlink.Name = 'Testing Link 2';
        otherPowerlink.Label__c = 'Test Link 2';
        otherPowerlink.URL__c = 'test url 2';
        otherPowerlink.Is_Internal__c = false;
        otherPowerlink.Sales_Org__c = 'Not-Expected';
        insert otherPowerlink;

        PowerLinksDAInterface testPowerlinkDA = new PowerlinksDA();
        List<Powerlinks__c> returnedPowerlinks = testPowerlinkDA.getPowerlinksByUserSalesOrg('Expected');

        test.stopTest();

        System.assertEquals(returnedPowerlinks.size(), 1);
        System.assertEquals(returnedPowerlinks[0].Label__c, 'Test Link');
    }
}