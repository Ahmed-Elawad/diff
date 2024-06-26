/**
 * This class contains unit tests for validating the ObjectRelationshipsBefore trigger.
 * 
 *
 * History
 * --------
 * 03/20/2013	Cindy Freeman	created
   06/30/2013  Dan Carmen     Made into a public test method to expose a createRelationship method.
 *
 */

@isTest
public class ObjectRelationshipsBeforeTest {

    public static Object_Relationships__c createRelationship(String primaryObjectName, String primaryRecordTypeName
                                          ,String relatedObjectName, String relatedRecordTypeName) {
       Object_Relationships__c orc = new Object_Relationships__c(Primary_Object_API_name__c = primaryObjectName
                                                   , Primary_Object_Rcd_Type__c = primaryRecordTypeName
                                                   , Related_Object_API_name__c = relatedObjectName
                                                   , Related_Object_Rcd_Type__c = relatedRecordTypeName);
       return orc;
    } // createRelationship

    static testMethod void objRelTest1() {
    	
    	Schema.RecordTypeInfo hrsOpptyRt = RecordTypeHelper.getRecordType('HRS 401(k) Opportunity Record Type','Opportunity');
    	Schema.RecordTypeInfo advselCaseRt = RecordTypeHelper.getRecordType('Service Onboarding Advisor Select New Case', 'Case');
    	
    	// insert good record
    	Object_Relationships__c orc1 = createRelationship('Opportunity','HRS 401(k) Opportunity Record Type'
    																,'Case' ,'Service Onboarding Advisor Select New Case');
    	insert orc1;
    	Object_Relationships__c neworc1 = getObjRel(orc1.Id);    	
		System.assertEquals(hrsOpptyRt.getRecordTypeId(), neworc1.Primary_Object_Rcd_Type_Id__c);
		System.assertEquals(advselCaseRt.getRecordTypeId(), neworc1.Related_Object_Rcd_Type_Id__c);
		
		
		// try insert of bad relationship record
    	Object_Relationships__c orc2 = new Object_Relationships__c(Primary_Object_API_name__c = 'Oppor'
    																, Primary_Object_Rcd_Type__c = 'HRS 401(k) Record Type'
    																, Related_Object_API_name__c = 'Kase'
    																, Related_Object_Rcd_Type__c = 'Service Onboarding ');
    	try {
    		insert orc2;
    		System.assertEquals('Should', 'Fail');
    	}
    	catch (Exception e) {
    		System.assertEquals('Good Failure', 'Good Failure');
    	}


		// try insert of bad relationship record2
    	Object_Relationships__c orc3 = new Object_Relationships__c(Primary_Object_API_name__c = 'Oppor'
    																, Related_Object_API_name__c = 'Kase'
    																, Related_Object_Rcd_Type__c = 'Service Onboarding ');
    	try {
    		insert orc3;
    		System.assertEquals('Should', 'Fail');
    	}
    	catch (Exception e) {
    		System.assertEquals('Good Failure', 'Good Failure');
    	}
    	
		// insert using default record type 
		Schema.RecordTypeInfo peoCaseRt = RecordTypeHelper.getRecordType('Service Onboarding PEO New Business','Case');
		Schema.RecordTypeInfo peoRefRt = RecordTypeHelper.getDefaultRecordType('Reference_PEO__c');
     	Object_Relationships__c orc4 = new Object_Relationships__c(Primary_Object_API_name__c = 'Case'
     																, Primary_Object_Rcd_Type__c = 'Service Onboarding PEO New Business'
    																, Related_Object_API_name__c = 'Reference_PEO__c');
    	insert orc4;
    	Object_Relationships__c neworc4 = getObjRel(orc4.Id);    	
		System.assertEquals(peoCaseRt.getRecordTypeId(), neworc4.Primary_Object_Rcd_Type_Id__c);
		System.assertEquals(RecordTypeHelper.getDefaultRecordType('Reference_PEO__c').getName(), neworc4.Related_Object_Rcd_Type__c);
		System.assertEquals(peoRefRt.getRecordTypeId(), neworc4.Related_Object_Rcd_Type_Id__c);
	   	
    	
    }
    
    
    public static Object_Relationships__c getObjRel (Id newObjRelId) {
    	Object_Relationships__c orc = [select Id
											, Primary_Object__c
											, Primary_Object_API_name__c
											, Primary_Object_Rcd_Type_Id__c
											, Primary_Object_Rcd_Type__c
											, Related_Object__c
											, Related_Object_API_name__c
											, Related_Object_Rcd_Type_Id__c
											, Related_Object_Rcd_Type__c
											from Object_Relationships__c where Id = :newObjRelId];
		return orc;
    }
   
}