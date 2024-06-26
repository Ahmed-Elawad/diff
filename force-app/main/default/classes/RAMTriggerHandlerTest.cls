/* 
 * History
 * -------
  17/10/2022 Rohit Ranjan Created
  

*/


@isTest
public class RAMTriggerHandlerTest {
    
    public static testmethod void setRAMOwnerRRTest(){
        
        Test.startTest();
        Case caseObj = new Case(Subject='Test Case 1');
     	insert caseObj;
        
        Reference_401k_S125__c ref401 = new Reference_401k_S125__c(Case_Lookup__c=caseObj.Id,CAAR_Prepared_Date__c=System.today()); //Financial_Advisor__c=refCtct1.Id);
        insert ref401;
        Id hrsRecordTypeId = Schema.SObjectType.Reference_Account_Management__c.getRecordTypeInfosByName().get('HRS 4S Conversion 5500').getRecordTypeId();
        System.debug('hrsRecordTypeId : ' + hrsRecordTypeId);
        List<Reference_Account_Management__c> ramList = new List<Reference_Account_Management__c>();
        Reference_Account_Management__c ram = new Reference_Account_Management__c();
        ram.RecordTypeId = hrsRecordTypeId;
        ram.Reference_401k_S125__c =  ref401.id;                                                          
        ram.Case_Lookup__c = caseObj.Id;
        ram.Service_Onboarding_401k_Conversions__c = ref401.id;
        ramList.add(ram);
        insert ramList;
        
        Test.stopTest();
        List<Reference_Account_Management__c> rmList = [SELECT Id, OwnerId FROM Reference_Account_Management__c LIMIT 1];
        //system.assert(rmList!=null);
        //System.assertEquals(String.ValueOf(rmList[0].ownerId).startsWith('005'),true);
    }

}