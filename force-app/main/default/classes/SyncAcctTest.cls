/* 
 * Test methods for the SyncAcct.
 *
 * History
 * -------
 * 11/10/2016 Jermaine Stukes Created
 */
@isTest
public class SyncAcctTest {
    
    static testMethod void testcheckAfterTrigger()
    {
        User u = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS and Sales_Org__c = :UserHelper.SO_CORE Limit 1];
        RecordType__c corert = new RecordType__c(Name = 'Core Account Record Type', ObjectName__c = 'Account',Sales_Org__c='PAY',RecordTypeName__c='Core Account Record Type');
        RecordType__c mmsrt = new RecordType__c(Name = 'MMS Account Record Type',ObjectName__c = 'Account',Sales_Org__c='MMS',RecordTypeName__c='MMS Account Record Type');
        insert corert;
        insert mmsrt;
        Schema.RecordTypeInfo opptyCoreId = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
        String acctMMSRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.RT_MMS_Account).getRecordTypeId();
        String acctCoreRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.RT_Core_Account).getRecordTypeId();
        Account acctMMS = new Account(Name='Test Acct', RecordTypeId = acctMMSRecordTypeId);
        insert acctMMS;
        String rtHold;
        //System.RunAs(u)
        //{
            Opportunity testOpp = new Opportunity(OpportunityType__c = OpptyMethods.Opp_TYPE_PAY
                                                  , NSS_Source__c = 'Inbound'
                                                  , RecordTypeId=opptyCoreId.getRecordTypeId()
                                                  ,AccountId=acctMMS.Id
                                                  , Name='Opp1'
                                                  ,StageName='Pending'
                                                  , CloseDate=Date.today());
                    insert testOpp;
            String oppSalesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(testOpp.RecordType.Name);
            rtHold = SyncAcct.getRecordTypeIdForSalesOrg(oppSalesOrg, ObjectHelper.OBJECT_ACCOUNT);
        	
        //}
		System.assertEquals(false, acctMMS.RecordTypeId == rtHold);
    }
}