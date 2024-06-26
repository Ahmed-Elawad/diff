public with sharing class NewQuoteAuraService {

	/*@AuraEnabled
	public static SBQQ__Quote__c saveNewQuote(SBQQ__Quote__c newQuote){

		insert newQuote;
		return newQuote;
	}*/
    
    @AuraEnabled
    public static Boolean getUserInfo(){
        User u = UserHelper.getRunningUser();
        System.debug('Running User: ' + u.Name + ', Sales Org: ' + u.Sales_Org__c);
        Boolean hasCustomPermission = FeatureManagement.checkPermission('OracleCPQUser');
        if(hasCustomPermission) return true;
        
        return false;
    }
    
    /*@AuraEnabled        
    public static List<String> getPickListValuesIntoList(){
        List<String> pickListValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = SBQQ__Quote__c.Used_Steelbrick__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
            System.debug('Values in Used Steelbrick are: '+pickListValuesList);
        }     
        return pickListValuesList;
    }*/
}