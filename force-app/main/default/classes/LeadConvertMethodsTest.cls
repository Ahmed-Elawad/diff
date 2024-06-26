/** Test methods for the LeadConvertMethods class (and associated triggers)
 *
 * History
 * -------
  04/04/2017 Cindy Freeman        Created.
  05/14/2018 Dan Carmen           This will all be handled in the AccountCheckFlds class

 */
@isTest
public class LeadConvertMethodsTest {
   
   @testSetup
   static void setupData() {
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerSetup__c trigSetup = TriggerMethodsTest.createCustomSetting(null, 'AccountBefore', true, false, new String[]{'AccountCheckFlds'}, setupClasses);
      insert setupClasses;
   }

    static testMethod void testLeadConvert() {
        Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
		
		Lead ld1 = new Lead(Firstname = 'First'
								,Lastname = 'Last Lead1'
								,Company = 'Test Lead Company1'
								,recordtypeId = leadCorert.getRecordTypeId()
                       			,NumberOfEmployees = 10
								,DataFlux_Id__c = null
                                ,LeadGroupId__c = null);
		insert ld1;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        //dbConvertResultMap = new Map<Id, List<Id>>();
        lc.setLeadId(ld1.Id);
        lc.setDoNotCreateOpportunity(true);
        lc.setOwnerId(UserInfo.getUserId());
        lc.setOverwriteLeadSource(false);
        
        LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.Leadconvertresult lcr = null;
        lcr = Database.convertLead(lc);
        
        Id acctId = lcr.getAccountId();        
        Account convertedAcct= [Select Id, Name, Employees__c, NumberOfEmployees from Account where Id = :acctId];
        
        System.assertEquals(ld1.NumberOfEmployees, convertedAcct.NumberOfEmployees);
        System.assertEquals(ld1.NumberOfEmployees, convertedAcct.Employees__c);
        
    }
}