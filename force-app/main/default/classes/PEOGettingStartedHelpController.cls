/* Controller for PEOGettingStartedHelpCenter Lightning Component
* 	HISTORY
* ___________
*
*	10/05/2021	Jake Hinds	Created
*/
public without sharing class PEOGettingStartedHelpController {
	@AuraEnabled
    public static User getSalesRep(){
        User salesRep;
        User u = [SELECT Id,AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if(u!=null && u.AccountId!=null){
            system.debug('accountId'+u.AccountId);
            PEO_Onboarding_Checklist__c checklist = [SELECT Id,Sales_Rep__c,Sales_Rep__r.Name,Sales_Rep__r.FirstName,Sales_Rep__r.LastName,Sales_Rep__r.Phone,Sales_Rep__r.MobilePhone FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :u.AccountId LIMIT 1];
            if(checklist!=null){
                salesRep = checklist.Sales_Rep__r;
                system.debug('checklist.Sales_Rep__r'+checklist.Sales_Rep__r);
                if(string.isblank(salesRep.Phone) && string.isNotBlank(salesRep.MobilePhone)){
                    salesRep.Phone = salesRep.MobilePhone;
                }
                if(string.isNotBlank(salesRep.Phone) && salesRep.Phone.length()>10){
                    salesRep.Phone = salesRep.Phone.replaceAll('\\D','');
                    salesRep.Phone = salesRep.Phone.right(10);
                    salesRep.Phone = '(' + salesRep.Phone.substring(0, 3) + ') ' + salesRep.Phone.substring(3, 6) + '-' + salesRep.Phone.substring(6);
                }
            }
        }//u!=null
        return salesRep;
    }
    @AuraEnabled
    public static Case[] getProspectCases(){
        Case[] caseList = new Case[]{};
        User u = [SELECT Id,AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if(u!=null && u.AccountId!=null){
            Case[] allCases = [SELECT Id,CaseNumber,Status,Subject,Description,CreatedDate FROM Case WHERE AccountId = :u.AccountId AND RecordType.Name = 'Prospect Help Request Case'];
            if(!allCases.isEmpty()){
                caseList = allCases;
            }
        }
        return caseList;
    }
}