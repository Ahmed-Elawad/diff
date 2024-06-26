/**
 * Test method for RefCorePayrollMPSCChatterUpdate which replaced a process builder
 *
 *	History
 *------------
 *  10/06/2016  Cindy Freeman	created
 *  09/05/2019  Jacob Hinds		query fix to make sure manager exists
 */
 
@isTest
private class RefCorePayrollMPSCChatterUpdateTest {


	static testMethod void unitTest1() {
    	User rcpOwner = [Select Id, Name, UserRole.Name, Email, ManagerId, IsActive from User 
    			where IsActive=true and ManagerId != NULL and manager.isactive = true and Profile.Name like 'MPSC Profile' and UserRole.Name like '%Supervisor%' and IsActive = true limit 1];
    	User rcpOwnerMngr = [Select Id, Name, UserRole.Name, email, IsActive from User
    			where IsActive = true and Id = :rcpOwner.ManagerId limit 1];
    	
    	CreateTestData.createSingleAandTwoCts();
    	
    	
    	Schema.RecordTypeInfo caseRT = RecordTypeHelper.getRecordType('Service Onboarding MPSC Core Payroll Case', 'CASE');
    	Case mpscCase = new Case();
    	mpscCase.RecordTypeId = caseRT.getRecordTypeId();
    	mpscCase.OwnerId = rcpOwner.Id;
    	mpscCase.AccountId = CreateTestData.acct1.Id;    	
    	mpscCase.ContactId = CreateTestData.ctct1.Id;
    	mpscCase.Status = 'New';
    	mpscCase.Current_Step__c = 'Case Creation';
    	insert mpscCase;
    	
    	Date ckDate = System.today().addDays(-1);
    	Schema.RecordTypeInfo rtRCP = RecordTypeHelper.getRecordType('Reference MPSC Onboarding Core Payroll', 'Reference_Core_Payroll__c');
    	Id mpscId = rtRCP.getRecordTypeId(); 	 		    			 
        Reference_Core_Payroll__c rcp = new Reference_Core_Payroll__c();
        rcp.RecordTypeId = mpscId;
        rcp.OwnerId = rcpOwner.Id;
        rcp.Case_Lookup__c = mpscCase.Id;
        rcp.Proposed_Run_Date__c = ckDate;
        rcp.Payroll_Run_Date__c = null;
        rcp.Payroll_Run_Date_Reset__c = false;
        rcp.Current_Step__c = 'Case Creation';
        //rcp.Payroll_Run_Date_Due__c = Friday after Proposed Run Date
        insert rcp;
        System.assertNotEquals(null, rcp.Id);
                
        Test.startTest();
        RefCorePayrollMPSCChatterUpdate rcpChatter = new RefCorePayrollMPSCChatterUpdate();
        // run process        
        Database.executeBatch(rcpChatter,2);
        Test.stopTest();
  
  		Reference_Core_Payroll__c newrcp = [Select Id, Payroll_Run_Date_Reset__c from Reference_Core_Payroll__c where id = :rcp.Id];
  		System.assertEquals(true, newrcp.Payroll_Run_Date_Reset__c);
                
    } // unitTest1
    
} // RefCore PayrollMPSCChatterUpdate