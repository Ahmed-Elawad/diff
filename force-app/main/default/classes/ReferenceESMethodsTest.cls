/*
*	Contains test methods pertinent to the Reference Enterprise Service Object
*
*	History
*  ---------
*	04/15/2016	Jacob Hinds		Created
*
*/
@isTest
private class ReferenceESMethodsTest {

    static testMethod void testChildObjectUpdate() {
    	Profile p = [Select Id FROM Profile WHERE Name='System Administrator'];
    	Id uId=UserInfo.getUserId();
    	User newUser = [SELECT Id FROM User WHERE isActive=true AND ProfileId = :p.Id AND Id!=:uId LIMIT 1];
    	
    	Id caseRT = RecordTypeHelper.getRecordType('ERR Account Management', 'Case').getRecordTypeId();
    	Case c = new Case(RecordTypeId=caseRT);
    	insert c;
    	Reference_Enterprise_Service__c ref = new Reference_Enterprise_Service__c(OwnerId=uId,Case_Lookup__c=c.Id);
    	insert ref;
        Reference_ES_ERR_Contact__c contact = new Reference_ES_ERR_Contact__c(OwnerId=uId,Reference_Enterprise_Service__c=ref.Id);
        insert contact;
		Reference_ES_Action_Plan__c action = new Reference_ES_Action_Plan__c(OwnerId=uId,Reference_Enterprise_Service__c=ref.Id);
		insert action;
		Reference_ES_Products_at_Risk__c risk = new Reference_ES_Products_at_Risk__c(OwnerId=uId,Reference_Enterprise_Service__c=ref.Id);
		insert risk;
		Reference_ES_Potential_Products__c product = new Reference_ES_Potential_Products__c(OwnerId=uId,Reference_Enterprise_Service__c=ref.Id);
		insert product;
		Reference_ES_Client_Concern_Projects__c concern = new Reference_ES_Client_Concern_Projects__c(OwnerId=uId,Reference_Enterprise_Service__c=ref.Id);
		insert concern;
		Reference_ES_Preview_to_Flex_Needs__c need = new Reference_ES_Preview_to_Flex_Needs__c(OwnerId=uId,Reference_Enterprise_Service__c=ref.Id);
		insert need;
		
		Test.startTest();
		
		ref.OwnerId = newUser.Id;
		update ref;

		Reference_ES_ERR_Contact__c uContact = [SELECT Id,OwnerId FROM Reference_ES_ERR_Contact__c WHERE Id=:contact.Id];
		System.assertEquals(newUser.Id,uContact.OwnerId);
		
		Reference_ES_Action_Plan__c uAction = [SELECT Id,OwnerId FROM Reference_ES_Action_Plan__c WHERE Id=:action.Id];
		System.assertEquals(newUser.Id,uAction.OwnerId);
		
		Reference_ES_Products_at_Risk__c uRisk = [SELECT Id,OwnerId FROM Reference_ES_Products_at_Risk__c WHERE Id=:risk.Id];
		System.assertEquals(newUser.Id,uRisk.OwnerId);
		
		Reference_ES_Potential_Products__c uProduct = [SELECT Id,OwnerId FROM Reference_ES_Potential_Products__c WHERE Id=:product.Id];
		System.assertEquals(newUser.Id,uProduct.OwnerId);
		
		Reference_ES_Client_Concern_Projects__c uConcern = [SELECT Id,OwnerId FROM Reference_ES_Client_Concern_Projects__c WHERE Id=:concern.Id];
		System.assertEquals(newUser.Id,uConcern.OwnerId);
		
		Reference_ES_Preview_to_Flex_Needs__c uNeed = [SELECT Id,OwnerId FROM Reference_ES_Preview_to_Flex_Needs__c WHERE Id=:need.Id];
		System.assertEquals(newUser.Id,uNeed.OwnerId);
		
		Test.stopTest();
    }
}