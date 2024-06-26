@IsTest
private class UtilityBarPowerlinksAuraControllerTest {
    @IsTest
    static void getPowerLinks_givenSalesOrgForUser_callsPowerlinksDAOnceToGetLinks() {
        PowerlinksDAMock fakePowerlinksDA = new PowerlinksDAMock(false);

        Test.startTest();
            UtilityBarPowerlinksAuraController.PowerlinksDADI = fakePowerlinksDA;

            List<Powerlinks__c> powerlinks = UtilityBarPowerlinksAuraController.getPowerLinks();

            System.assert(fakePowerlinksDA.GetPowerlinksCallCount == 1, 'should have called the da method once');
        Test.stopTest();
    }

    @IsTest
    static void getPowerLinks_givenException_returnsAuraExceptionError() {
        PowerlinksDAMock fakePowerlinksDA = new PowerlinksDAMock(true);

        Test.startTest();
            UtilityBarPowerlinksAuraController.PowerlinksDADI = fakePowerlinksDA;

            try {
                List<Powerlinks__c> powerlinks = UtilityBarPowerlinksAuraController.getPowerLinks();
                System.assert(false, 'Should have thrown AuraHandledException but did not');
            } catch (AuraHandledException ex) {
                System.assert(true);
            }
        Test.stopTest();
    }
}