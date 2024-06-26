public with sharing class UtilityBarPowerlinksAuraController {
    private static PowerLinksDAInterface powerlinksDataAccessor = new PowerlinksDA();
    public static PowerLinksDAInterface PowerlinksDADI {
        get {
            return powerlinksDataAccessor;
        }
        set {
            powerlinksDataAccessor = value;
        }
    }

    @AuraEnabled
    public static List<Powerlinks__c> getPowerLinks() {
        try {
            User loggedInUser = [SELECT Id, Sales_Org__c FROM User WHERE Id = :UserInfo.getUserId()];
            List<Powerlinks__c> returnLinks = PowerlinksDADI.getPowerlinksByUserSalesOrg(loggedInUser.Sales_Org__c);

            return returnLinks;
        }
        catch(Exception ex) {
            System.debug(ex.getMessage());
            throw new AuraHandledException('An error occurred while trying to get the power links, please refresh and try again.');
        }
    }
}