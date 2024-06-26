/* Test class for location queueable

  History
  -------
  4/20/2021  Ahmed Elawad  Created
  9/16/2021 Jake Hinds    Updating after rework
 */

@isTest
public class ClientSpaceLocationQueueableTest {
    /*@TestSetup
    private static void setup() {
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ClientSpaceLocationQueueableTest 1', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, ShippingStreet = 'Billling Street', 
                                    ShippingPostalCode='1234', ShippingState='NY', ShippingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='', agentsync__ID_FEIN__c='Test1');
        insert acctA;
        Account acctB = new Account(Name = 'ClientSpaceLocationQueueableTest 2', AccountNumber = '8-12345678',NumberOfEmployees = 60, Federal_Id_Number__c='5678',
                                    DBA__c='TEST', SalesParent__c = acctA.Id, RecordTypeId=rtAcct.getRecordTypeId(),
                                    agentsync__ID_FEIN__c='Test');
        insert acctB;
    }*/
    
    static testMethod void testQueueable(){
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account parent = new Account(Name = 'test Parent', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, ShippingStreet = 'Billling Street', 
                                    ShippingPostalCode='1234', ShippingState='NY', ShippingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='', agentsync__ID_FEIN__c='Test1');
        insert parent;
        Account child1 = new Account(Name = 'test Child 1', AccountNumber = '8-12345678',NumberOfEmployees = 60, Federal_Id_Number__c='5678',
                                    DBA__c='TEST', SalesParent__c = parent.Id, RecordTypeId=rtAcct.getRecordTypeId(),
                                    agentsync__ID_FEIN__c='Test');
        
        Account child2 = new Account(Name = 'test Child 2', AccountNumber = '8-12345678',NumberOfEmployees = 60, Federal_Id_Number__c='5678',
                                    DBA__c='TEST', SalesParent__c = parent.Id, RecordTypeId=rtAcct.getRecordTypeId(),
                                    agentsync__ID_FEIN__c='Test');
        Account child3 = new Account(Name = 'test Child 3', AccountNumber = '8-12345678',NumberOfEmployees = 60, Federal_Id_Number__c='5678',
                                    DBA__c='TEST', SalesParent__c = parent.Id, RecordTypeId=rtAcct.getRecordTypeId(),
                                    agentsync__ID_FEIN__c='Test');
        Account formerChild = new Account(Name = 'test former child', AccountNumber = '8-12345678',NumberOfEmployees = 60, Federal_Id_Number__c='5678',
                                    DBA__c='TEST', RecordTypeId=rtAcct.getRecordTypeId(),
                                    agentsync__ID_FEIN__c='Test');
        Account[] childAccts = new Account[]{child1,child2,child3,formerChild};
        insert childAccts;
        Account[] allAccts = new Account[]{parent,child1,child2,child3};
        ClientSpaceLocationQueueable queuableClass = new ClientSpaceLocationQueueable('gen_ClientMaster','POST','x_oas_ClientMaster_SFGUID_list',parent.id, allAccts,false,null,'Test',null,null,null);       
        queuableClass.testChildId = child1.Id;
        queuableClass.testChildId2 = child2.Id;
        queuableClass.formerChildId = formerChild.Id;
        queuableClass.getLocations(queuableClass.parentId, queuableClass.operation, queuableClass.tableName, queuableClass.searchName);        
    }
    
}