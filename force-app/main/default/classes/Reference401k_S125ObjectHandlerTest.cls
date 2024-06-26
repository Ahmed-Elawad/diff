/* History
  -------
  04/20/2023   Lalan Kumar   Created  
*/
@isTest
public class Reference401k_S125ObjectHandlerTest {
 private static Case createCase(String recordTypeName) {
        Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(recordTypeName, 'Case');
        Case c = new Case(RecordTypeId=rt.getRecordTypeId());
        c.HRS4SCategory1__c ='Billing 401k';
        return c;
    } // createCase 
    static testMethod void testnew401kCTTcaseCreate() {
       Id currUser = UserInfo.getUserId();
       User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND Id !=:currUser AND IsActive = true LIMIT 1];

        List<Case> cases = new List<Case>();
        Case c1 = createCase('401k/S125 Operations Support');
        c1.OwnerId = currUser;
        c1.Subject = 'HRS 4S LDPS Checks';
        cases.add(c1);
        insert cases;
        Schema.RecordTypeInfo refOnb401kNewCase = RecordTypeHelper.getRecordType('Service Onboarding 401k New Case', 'Reference_401k_S125__c');
        List<Reference_401k_S125__c> refList = new List<Reference_401k_S125__c>();
        
        Reference_401k_S125__c newRef1 = new Reference_401k_S125__c(RecordTypeId=refOnb401kNewCase.getRecordTypeId(),Case_Lookup__c = c1.Id,CTT_New_Case__c =false);
        refList.add(newRef1);
        insert refList;
        newRef1.CTT_New_Case__c = true;
        update refList; 
        } //testnew401kCTTcaseCreate method End
} //Class End