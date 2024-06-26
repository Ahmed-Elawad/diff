/*
* Conroller for the keyword search component
* Histior
* ---------------------------------------
* 05/30/2022 Reetesh Pandey  Apex code scan resolution
*/

public  without sharing class KeyWordSearchController {
    
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String searchString, String objectApiName, String idFieldApiName, String valueFieldApiName, String extendedWhereClause, Integer maxRecords){
        searchString = String.escapeSingleQuotes(searchString);
        objectApiName = String.escapeSingleQuotes(objectApiName);
        idFieldApiName = String.escapeSingleQuotes(idFieldApiName);
        valueFieldApiName = String.escapeSingleQuotes(valueFieldApiName);
        
        if(extendedWhereClause == null){
            extendedWhereClause = '';
        }
        else{
            extendedWhereClause = String.escapeSingleQuotes(extendedWhereClause);
        }
        
        String query = 'SELECT '+idFieldApiName+', '+valueFieldApiName+' FROM '+objectApiName+' WHERE '+valueFieldApiName+' LIKE \'%'+searchString+'%\' '+extendedWhereClause+' LIMIT '+maxRecords;
        return Database.query(query);
    }
    
    @AuraEnabled
    public static boolean saveAccountNAICSCode(Id accountId, String NAICSCode, String naicsDisc) {
        try {
            Account saveAcc = new Account(Id=accountId, NAICS_Code__c=NAICSCode, NAICS_Description__c=naicsDisc);
            Update saveAcc;
            return true;
        } catch(DmlException err) {
            throw new AuraHandledException('Error Saving the NAICS');
        }
    }
    
    @AuraEnabled
    public static Account getAccNaics(String accId) {
        System.debug('Returning naics for: '+accId);
        Account retValue = [SELECT Id, Naics_Code__c FROM Account WHERE Id=:accId LIMIT 1];
        System.debug(retValue);
        return retValue;
    }
}