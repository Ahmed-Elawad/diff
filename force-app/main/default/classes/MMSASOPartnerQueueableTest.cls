/* 
 * Test for MMSASOPartnerQueueable
 *
 * History
 * -------
 * 05/21/2018 Jake Hinds    Created
   06/08/2020 Dan Carmen    Added in TriggerMethods.clearVariables();
   06/28/2021 Jermaine Stukes   Replace RSR Partner tests with HR Service Partner
   08/09/2021 Dan Carmen        Rewrite for efficiency

*/
@isTest
private class MMSASOPartnerQueueableTest {

    static testMethod void testAddHrPartner() {
        String coreRt = Label.RT_Core_Account;
        Id acctRTId = RecordTypeHelper.getRecordType(coreRt,'Account').getRecordTypeId();
        //doesn't actually need to be an aso rep in the field
        User payRep = [SELECT Id,HR_Services_Partner__c FROM User WHERE Profile.Name = 'Core Sales - SB' and IsActive = true LIMIT 1];
        User hrRep = [SELECT Id FROM User WHERE Profile.Name = 'HRS PEO-ASO Sales - SB' and IsActive = true LIMIT 1];
        system.debug('PAYREP = '+payRep+' HRREP= '+hrRep);
        Account acct = new Account(RecordTypeId=acctRTId,Name='Test Account',Type='Prospect',Employees__c=100,OwnerId=payRep.Id);
        insert acct;
        
        Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
        Opportunity opp1 = new Opportunity(Name='Opp 1',RecordTypeId=rtCore.getRecordTypeId(), AccountId=acct.Id, StageName=Label.OppStage_Qualified, OwnerId = acct.OwnerId, CloseDate=Date.today() + 1);
        insert opp1;
        Test.startTest();
        payRep.HR_Services_Partner__c = hrRep.Id;
        update payRep;
        Test.stopTest();
        Account updatedAcct = [SELECT ID,OwnerId,Premier_PBS_Account_Owner__c,Premier_PBS_Hold_Out__c,Premier_PBS_Hold_Out_Expiration__c,PEO_ASO_Permanent_Hold_Out_Description__c
                                 FROM Account WHERE Id =:acct.Id];
        system.assertEquals(hrRep.Id, updatedAcct.Premier_PBS_Account_Owner__c);
        system.assertEquals(true, updatedAcct.Premier_PBS_Hold_Out__c);
        system.assertEquals(Label.Account_HR_Partnership_Holdout_Reason, updatedAcct.PEO_ASO_Permanent_Hold_Out_Description__c);
        
        //Test Removal
        
    }
    static testMethod void testPartnerRemove() {
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(Label.RT_Core_Account, ObjectHelper.OBJECT_ACCOUNT);
        User[] payReps = [SELECT Id,HR_Services_Partner__c FROM User WHERE Profile.Name = 'Core Sales - SB' and IsActive = true LIMIT 2];
        User hrRep = [SELECT Id FROM User WHERE Profile.Name = 'HRS PEO-ASO Sales - SB' and IsActive = true LIMIT 1];
        payReps[1].HR_Services_Partner__c = hrRep.Id;
        update payReps;          
        Account acct1 = new Account (name = 'Test Account1'
                                     ,recordtypeId = coreRt.getRecordTypeId()
                                     ,ownerId = payReps[0].Id
                                     ,BillingPostalCode = '14514'
                                     ,AccountNumber = '83-1234567'
                                     ,Employees__c = 60
                                     ,Larkspur_401k_Assets__c = 10000
                                     ,Do_Not_Call__c = true
                                     ,Phone = '555-1212');
        insert acct1;
        Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
        Opportunity opp1 = new Opportunity(Name='Opp 1',RecordTypeId=rtCore.getRecordTypeId(), AccountId=acct1.Id, StageName=Label.OppStage_Qualified, OwnerId = payReps[1].Id, CloseDate=Date.today() + 1);
        insert opp1;
        acct1.OwnerId = payReps[1].Id;
        acct1.Premier_PBS_Account_Owner__c = hrRep.Id;
        update acct1;
        Account uAcct1 = [SELECT Id,Premier_PBS_Account_Owner__c,Premier_PBS_Hold_Out__c,Premier_PBS_Hold_Out_Expiration__c,PEO_ASO_Permanent_Hold_Out_Description__c
                          FROM Account WHERE Id = :acct1.Id LIMIT 1];
        system.assertEquals(hrRep.Id,uAcct1.Premier_PBS_Account_Owner__c);
        payReps[1].HR_Services_Partner__c = null;
        payReps.remove(0);
        MMSASOPartnerQueueable queueableJob = new MMSASOPartnerQueueable(payReps);
        test.startTest();
        System.enqueueJob(queueableJob); 
        test.stopTest();
        Account uAcct2 = [SELECT Id,Premier_PBS_Account_Owner__c,Premier_PBS_Hold_Out__c,Premier_PBS_Hold_Out_Expiration__c,PEO_ASO_Permanent_Hold_Out_Description__c
                          FROM Account WHERE Id = :acct1.Id LIMIT 1];
        system.assertEquals(null,uAcct2.Premier_PBS_Account_Owner__c);
        system.assertEquals(false, uAcct2.Premier_PBS_Hold_Out__c);
        system.assertEquals(null, uAcct2.Premier_PBS_Account_Owner__c);
        system.assertEquals(null, uAcct2.PEO_ASO_Permanent_Hold_Out_Description__c);
        
    }
}