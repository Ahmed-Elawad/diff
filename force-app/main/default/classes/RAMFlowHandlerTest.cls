/* 
 * History
 * -------
  17/10/2022 Rohit Ranjan Created
  

*/


@isTest
public class RAMFlowHandlerTest {
    
    public static testmethod void setRAMOwnerRRTest(){
        
        Test.startTest();
        Case caseObj = new Case(Subject='Test Case 1');
     	insert caseObj;
        
        Id hrsRecordTypeId = Schema.SObjectType.Reference_Account_Management__c.getRecordTypeInfosByName().get('HRS 4S Conversion 5500').getRecordTypeId();
        System.debug('hrsRecordTypeId : ' + hrsRecordTypeId);
        List<Reference_Account_Management__c> ramList = new List<Reference_Account_Management__c>();
        Reference_Account_Management__c ram = new Reference_Account_Management__c();
        ram.RecordTypeId = hrsRecordTypeId;
        ram.Case_Lookup__c = caseObj.Id;
        ramList.add(ram);
        insert ramList;
        
        RAMFlowHandler.setRAMOwnerRR(ramList);
        Test.stopTest();
        system.assert(ramList!=null);
    }

}