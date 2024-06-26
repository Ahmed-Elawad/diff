/* 
 *
 * History
 * -------
 * 10/06/2017 Lynn Michels        Created
 * 11/21/2017 Lynn Michels		  Added code for owner changing and client Ids field blank
 *
 */
@isTest
public with sharing class CasesInSyncTest {
	
	static testMethod void testOwnerChange() {
      	List<User> u = new List<User>([Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :UserInfo.getUserId() limit 2]);
      	
      	Id caseTermTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HRS Termination Transfer Case Record Type').getRecordTypeId(); 
  		List<Case> newCases = new List<Case>();
    	Case parentCase = new Case(	OwnerId = u[0].id,
    						Status='New',
        					Origin = 'Email',
        					RecordTypeId = caseTermTransfer);
        insert parentCase;
        Case child1 = new Case(	OwnerId = u[0].id,
        					ParentId = parentCase.Id,
    						Status='New',
        					Origin = 'Email',
        					RecordTypeId = caseTermTransfer);
        newCases.add(child1);
        Case child2 = new Case(	OwnerId = u[0].id,
        					ParentId = parentCase.Id,
    						Status='New',
        					Origin = 'Email',
        					RecordTypeId = caseTermTransfer);
        newCases.add(child2);
        insert newCases;
        
        parentCase.OwnerId = u[1].id;
        update parentCase;
        
        List<Case> cases = [SELECT OwnerId FROM Case WHERE parentId =: parentCase.id];
        system.assertEquals(2,cases.size());
        system.assertEquals(parentCase.OwnerId, cases[0].OwnerId);
        system.assertEquals(parentCase.OwnerId, cases[1].OwnerId); 
        
	}
	
	static testMethod void testOwnerChangeWithBlankClientIDs() {
      	List<User> u = new List<User>([Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :UserInfo.getUserId() limit 2]);
      	
      	Id caseTermTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HRS Termination Transfer Case Record Type').getRecordTypeId(); 
  		Id termTransferRtId = Schema.SObjectType.Reference_HRS_Termination_Transfer__c.getRecordTypeInfosByName().get('Reference HRS Termination/Transfer').getRecordTypeId();
 		
    	Case parentCase = new Case(	OwnerId = u[0].id,
    						Status='New',
        					Origin = 'Email',
        					RecordTypeId = caseTermTransfer);
        insert parentCase;
        
        
        Reference_HRS_Termination_Transfer__c ref = new Reference_HRS_Termination_Transfer__c(
    												Case_Lookup__c = parentCase.id,
    												RecordTypeId = TermTransferRtId);
        insert ref; 
      
        parentCase.OwnerId = u[1].id;
        
        String errorMessage = 'You must use the "Select Clients" button on the Reference HRS Termination/Transfer record to populate the "Client IDs to be Coded Lost" field before you can change the owner.';
        try
         {
             update parentCase;
         }
         catch (Exception e) 
         {
             Boolean expectedExceptionThrown =  e.getMessage().contains(errorMessage) ? true : false;
             System.assertEquals(expectedExceptionThrown, true);
         }
        
	}
	
	static testMethod void testStatusChange() {
		
      	List<User> u = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :UserInfo.getUserId() limit 1];
      	
      	Id caseTermTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HRS Termination Transfer Case Record Type').getRecordTypeId(); 
  		List<Case> newCases = new List<Case>();
    	Case parentCase = new Case(	OwnerId = u[0].id,
    						Status='New',
        					Origin = 'Email',
        					RecordTypeId = caseTermTransfer);
        insert parentCase;
        
        Case child1 = new Case(	OwnerId = u[0].id,
       						ParentId = parentCase.Id,
    						Status='New',
        					Origin = 'Email',
        					RecordTypeId = caseTermTransfer);
        newCases.add(child1);
        Case child2 = new Case(	OwnerId = u[0].id,
        					ParentId = parentCase.Id,
    						Status='New',
        					Origin = 'Email',
        					RecordTypeId = caseTermTransfer);
        newCases.add(child2);
        insert newCases;
        
        parentCase.Status = 'Waiting on Ops';
        update parentCase;
        
        List<Case> cases = [SELECT Status FROM Case WHERE parentId =: parentCase.id];
        system.assertEquals(2,cases.size());
        system.assertEquals(parentCase.Status, cases[0].Status);
        system.assertEquals(parentCase.Status, cases[1].Status);
	}
}