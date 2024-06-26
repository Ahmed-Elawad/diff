public with sharing class UnsubscribeEmailController {
 
    @AuraEnabled
    public static Boolean updateRecord(String emailString) {
        System.debug('Entered Apex'+emailString);
        Boolean flag = false;
        if(emailString!=null){
            Reference_Do_Not_Contact__c refDNC = new Reference_Do_Not_Contact__c();
            refDNC.Contact_Email__c = emailString;
            refDNC.Status__c = 'New';
            refDNC.Requestor__c = 'UnsubscribeEmail';
            insert refDNC;
            System.debug('created rec'+refDNC);
            flag= true;
        } 
        return flag;
	}
}