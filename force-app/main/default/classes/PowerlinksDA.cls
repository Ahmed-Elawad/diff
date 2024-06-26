public with sharing class PowerlinksDA implements PowerLinksDAInterface {
    public List<Powerlinks__c> getPowerlinksByUserSalesOrg(String salesOrg) {
        try {
            List<Powerlinks__c> returnLinks = [SELECT Label__c, Url__c, Is_Internal__c FROM Powerlinks__c WHERE Sales_Org__c = :salesOrg];
            return returnLinks;
        } catch(Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
    }
}