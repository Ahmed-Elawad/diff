/*
*  Contains test methods pertinent to the Reference Operations Support Object
*
*  History
*  ---------
*  08/05/2016  Jacob Hinds    Created
*  08/10/2016  Jacob Hinds    Using Cancellations Queue now.
*
*/
@isTest
private class   ReferenceOperationsSupportTest {

    static testMethod void testOwnerUpdate() {
        String[] queueNames = new String[]{'HRS 4S Cancellations','HRS 4S Level 1 Approvers','HRS 4S Level 2 Approvers'};
	    Group[] queues = [select Id,Name from Group where Name in: queueNames and Type = 'Queue'];
	    Id cancellation;
	    Id level1;
	    Id level2;
	    if(!queues.isEmpty()){
	        for(Group g:queues){
	            if(g.Name == 'HRS 4S Cancellations'){
	                cancellation = g.Id;
	            }
	            else if(g.Name == 'HRS 4S Level 1 Approvers'){
	                level1 = g.Id;
	            }
	            else if(g.Name == 'HRS 4S Level 2 Approvers'){
	                level2 = g.Id;
	            }
	        }
	    }
        Schema.RecordTypeInfo cRT = RecordTypeHelper.getRecordType('401k/S125 Operations Support','Case');
        Schema.RecordTypeInfo refRT = RecordTypeHelper.getRecordType('401k Transfer','Reference_Terms_Transfers__c');
        
        Case c = new Case(RecordTypeId = cRT.getRecordTypeId());
        insert c;
        Reference_Terms_Transfers__c ref1 = new Reference_Terms_Transfers__c(RecordTypeId = refRT.getRecordTypeId(),Case_Lookup__c = c.Id);
        Reference_Terms_Transfers__c ref2 = new Reference_Terms_Transfers__c(RecordTypeId = refRT.getRecordTypeId(),Case_Lookup__c = c.Id);
        Reference_Terms_Transfers__c ref3 = new Reference_Terms_Transfers__c(RecordTypeId = refRT.getRecordTypeId(),Case_Lookup__c = c.Id);
        Reference_Terms_Transfers__c[] refs = new Reference_Terms_Transfers__c[]{ref1,ref2,ref3};
        insert refs;
        
        Test.startTest();
        
        ref1.OwnerId = cancellation;
        update ref1;
        
        Case newCase = [SELECT Id,OwnerId FROM Case WHERE Id = :c.Id];
        system.assertEquals(cancellation,newCase.OwnerId);
        
        //ref.OwnerId = level1;
        ref1.Wire_Amount__c = 1000000;
        ref1.Ready_for_Approval__c = true;
        update ref1;
        
        newCase = [SELECT Id,OwnerId FROM Case WHERE Id = :c.Id];
        system.assertEquals(level1,newCase.OwnerId);
        
        ref1.OwnerId = UserInfo.getUserId();
        update ref1;
        ProcessInstance pi1 = [SELECT TargetObjectId, CreatedDate FROM ProcessInstance WHERE TargetObjectId = :ref1.Id];
    	System.assert(pi1!=null);
        
        ref2.Wire_Amount__c = 1000000;
        ref2.Ready_for_Approval__c = true;
        ref2.Ready_for_Approval_2__c = true;
        update ref2;
        
        newCase = [SELECT Id,OwnerId FROM Case WHERE Id = :c.Id];
        system.assertEquals(level1,newCase.OwnerId);
        
        ref2.OwnerId = UserInfo.getUserId();
        update ref2;
        ProcessInstance pi2 = [SELECT TargetObjectId, CreatedDate FROM ProcessInstance WHERE TargetObjectId = :ref2.Id];
    	System.assert(pi2!=null);
        
        ref3.Wire_Amount__c = 1000000;
        ref3.Ready_for_Approval__c = true;
        ref3.Ready_for_Approval_2__c = true;
        ref3.Ready_for_Approval_3__c = true;
        update ref3;
        
        newCase = [SELECT Id,OwnerId FROM Case WHERE Id = :c.Id];
        system.assertEquals(level2,newCase.OwnerId);
        
        ref3.OwnerId = UserInfo.getUserId();
        update ref3;
        ProcessInstance pi3 = [SELECT TargetObjectId, CreatedDate FROM ProcessInstance WHERE TargetObjectId = :ref3.Id];
    	System.assert(pi3!=null);
        
        Test.stopTest();
    }
    
    static testMethod void testCaseCreation()
    {
        Schema.RecordTypeInfo cRT = RecordTypeHelper.getRecordType('401k/S125 Operations Support','Case');
        Schema.RecordTypeInfo refRT = RecordTypeHelper.getRecordType('401k Transfer','Reference_Terms_Transfers__c');
        
        User u = [Select Id, Name, ContactId FROM User WHERE Name='SFDC Data' LIMIT 1];
        Contact con = new Contact(FirstName='Test', LastName='Contact');
        insert con;
        Case c = new Case(RecordTypeId = cRT.getRecordTypeId(), ContactId=con.Id);
        insert c;
        
        Reference_Terms_Transfers__c ref1 = new Reference_Terms_Transfers__c(RecordTypeId = refRT.getRecordTypeId(),Case_Lookup__c = c.Id,Stable_value_Funds__c = null, Stable_Value_Funds_Rep_Lookup__c=u.Id, Current_Step__c ='In Process');
        insert ref1;
        ref1.Stable_Value_Funds__c = 'FED CAP';
        update ref1;
        
        Case[] createdCase = [Select Id, OwnerId FROM Case WHERE OwnerId =:u.Id];
        System.assertEquals(1, createdCase.size());
    }
}