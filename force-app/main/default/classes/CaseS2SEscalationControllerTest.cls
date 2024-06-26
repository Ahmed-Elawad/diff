/* Page to escalate s2s cases

   History
   -------
   07/08/2020 Jake Hinds        Created 

*/
@isTest
public class CaseS2SEscalationControllerTest {
    static testMethod void testEscalation(){
        Id acctRT = RecordTypeHelper.getRecordType('System Administration Account', 'Account').getRecordTypeId();
    	Account payx = new Account(Name='Paychex Inc SA',RecordTypeId=acctRT);
        insert payx;
        Id contactRT = RecordTypeHelper.getRecordType('Paychex Employee', 'Contact').getRecordTypeId();
        Contact payxEmp = new Contact(FirstName='test',LastName='emp',email='test123@gmail.com',AccountId=payx.Id,RecordTypeId=contactRT);
        insert payxEmp;
        Id caseRT = RecordTypeHelper.getRecordType('Sales2Service Case', 'Case').getRecordTypeId();
        Case s2sCase = new Case(RecordTypeId=caseRt,Subject='test',Description='test',Assigned_UC_Agent__c=payxEmp.FirstName+' '+payxEmp.LastName,Product__c='Payroll');
        insert s2sCase;
        
        Test.startTest();
        ApexPages.StandardController controller = new ApexPages.StandardController(s2sCase);
        CaseS2SEscalationController cec = new CaseS2SEscalationController(controller);
        system.assert(cec.rec!=null);
        system.assertEquals(payxEmp.Id,cec.rec.Assister__c);
        cec.rec.Reason_for_escalation__c = 'test';
        cec.save();
        Case updatedCase = [SELECT Id,isEscalated FROM Case WHERE Id = :s2sCase.Id LIMIT 1];
        system.assert(true,updatedCase.isEscalated);        
        
        Test.stopTest();
    }
    static testMethod void testNoMatch(){
    	Id acctRT = RecordTypeHelper.getRecordType('System Administration Account', 'Account').getRecordTypeId();
    	Account payx = new Account(Name='Paychex Inc SA',RecordTypeId=acctRT);
        insert payx;
        Id contactRT = RecordTypeHelper.getRecordType('Paychex Employee', 'Contact').getRecordTypeId();
        Contact defaultEmp = new Contact(FirstName='test',LastName='emp',email='s2sfeedback@paychex.com',AccountId=payx.Id,RecordTypeId=contactRT);
        insert defaultEmp;
        Id caseRT = RecordTypeHelper.getRecordType('Sales2Service Case', 'Case').getRecordTypeId();
        Case s2sCase = new Case(RecordTypeId=caseRt,Subject='test',Description='test',Product__c='Payroll');
        insert s2sCase;
        
        Test.startTest();
        ApexPages.StandardController controller = new ApexPages.StandardController(s2sCase);
        CaseS2SEscalationController cec = new CaseS2SEscalationController(controller);
        system.assert(cec.rec!=null);
        system.assertEquals(defaultEmp.Id,cec.rec.Assister__c);
        cec.rec.Assister__c = null;
        cec.rec.Reason_for_escalation__c = 'test';
        cec.save();
        for(ApexPages.Message message: ApexPages.getMessages()){
            system.assertEquals('The assigned specialist could not be automatically determined.  Please enter the assigned specialist before continuing.',message.getDetail());
        }
        
        Test.stopTest();
    }
    static testMethod void testAlreadyEscalated(){
        Id acctRT = RecordTypeHelper.getRecordType('System Administration Account', 'Account').getRecordTypeId();
    	Account payx = new Account(Name='Paychex Inc SA',RecordTypeId=acctRT);
        insert payx;
        Id contactRT = RecordTypeHelper.getRecordType('Paychex Employee', 'Contact').getRecordTypeId();
        Contact payxEmp = new Contact(FirstName='test',LastName='emp',email='test123@gmail.com',AccountId=payx.Id,RecordTypeId=contactRT);
        insert payxEmp;
        Id caseRT = RecordTypeHelper.getRecordType('Sales2Service Case', 'Case').getRecordTypeId();
        Case s2sCase = new Case(RecordTypeId=caseRt,Subject='test',Description='test',Product__c='Payroll',Assigned_UC_Agent__c=payxEmp.email,IsEscalated=true);
        insert s2sCase;
        
        Test.startTest();
        ApexPages.StandardController controller = new ApexPages.StandardController(s2sCase);
        CaseS2SEscalationController cec = new CaseS2SEscalationController(controller);
        system.assert(cec.rec!=null);
        system.assertEquals(payxEmp.Id,cec.rec.Assister__c);
        cec.rec.Reason_for_escalation__c = 'test';
        cec.save();
        for(ApexPages.Message message: ApexPages.getMessages()){
            system.assertEquals('This case has already been escalated.',message.getDetail());
        }
        
        Test.stopTest();
    }
}