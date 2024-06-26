/*
 *  This is a test class for RefCorePayExceptionCase
 *
 *  History
 * ---------
 *  01/09/2016  Jacob Hinds Created
 * 3/20/2024  Carrie Marciano    CanBeDeleted old MPSC tech debt
 *
*/
@isTest
private class RefCorePayExceptionCaseTest {
    static testMethod void myUnitTest() {
        new RefCorePayExceptionCase();
    }
/*
    static testMethod void caseCreationTest() {
        Id rcpRT = RecordTypeHelper.getRecordType('MPSC Exception','Reference_Core_Payroll__c').getRecordTypeId();
        Id oppRT = RecordTypeHelper.getRecordType('MMS Opportunity Record Type','Opportunity').getRecordTypeId();
        Id acctRT = RecordTypeHelper.getRecordType('MMS Account Record Type','Account').getRecordTypeId();

        //get MMS rep
        User salesRep = [Select Id, FirstName, LastName, Sales_Org__c,ManagerId FROM User WHERE isActive=true AND Profile.Name = 'MMS Sales - SB' AND Manager.Profile.Name = 'MMS Manager - SB' AND Sales_Org__c ='MMS' LIMIT 1];
        Account acct = new Account(RecordTypeId=acctRT,Name='test acct',OwnerId = salesRep.Id);
        insert acct;
        Opportunity opp = new Opportunity(RecordTypeId = oppRT,Name='test opp',AccountId=acct.Id,OwnerId = salesRep.Id,StageName='Pending',CloseDate = system.today());
        insert opp;
        
        System.runAs(salesRep){
            Reference_Core_Payroll__c rcp = new Reference_Core_Payroll__c(RecordTypeId = rcpRT,Opportunity_Lookup__c = opp.Id);
            insert rcp;
            Reference_Core_Payroll__c newRCP = [SELECT Id,Case_Lookup__c,Case_Lookup__r.Subject,OwnerId FROM Reference_Core_Payroll__c WHERE Id = :rcp.Id];
            system.assert(newRcp.Case_Lookup__c!=null);
            system.assertEquals(salesRep.Id,newRCP.OwnerId);
        }

        //get MMS DSM
        User dsm = [Select Id, FirstName, LastName, Sales_Org__c,ManagerId FROM User WHERE isActive=true AND Profile.Name = 'MMS Manager - SB' AND Manager.Id != null AND Sales_Org__c ='MMS' LIMIT 1];
        Group exceptionQueue = [SELECT Id FROM Group WHERE Name = 'MPSC Exception Team Queue' and Type ='Queue'];
        System.runAs(dsm){
            Reference_Core_Payroll__c rcp = new Reference_Core_Payroll__c(RecordTypeId = rcpRT,Opportunity_Lookup__c = opp.Id);
            insert rcp;
            Reference_Core_Payroll__c newRcp = [SELECT Id,Case_Lookup__c,Case_Lookup__r.Subject,OwnerId FROM Reference_Core_Payroll__c WHERE Id = :rcp.Id];
            system.assert(newRcp.Case_Lookup__c!=null);
            system.assertEquals(exceptionQueue.Id,newRCP.OwnerId);
        }
        
    }
 */   
}