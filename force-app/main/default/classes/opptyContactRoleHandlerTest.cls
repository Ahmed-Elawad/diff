/* Test Methods for the opptyContactRoleHandler class
   
  History
  -------
  03/18/2013 Lalan Kumar     Created

*/

@isTest
public class opptyContactRoleHandlerTest {
    
    static testMethod void updateOppPhoneandConsentToTextTest(){
        
        User u1 = [Select Id, Name from User where (District__c='012' or District__c='031' or District__c='033') and IsActive=true limit 1];
        Account acct = new Account(Name='Test Send to HB Acct');
        insert acct;
        Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id,Consent_to_Text__c = true, MobilePhone = '1234567890');
        insert ctct;
        id hnbfOpptyRecTypeId = RecordTypeHelper.getRecordType(Label.HNBF_Opportunity_Record_Type,'Opportunity').getRecordTypeId();
        Opportunity oppty1 = new Opportunity(Name='Test Oppty1', RecordTypeId=hnbfOpptyRecTypeId,AccountId=acct.Id
                                             ,StageName=Label.OppStage_Qualified
                                             ,Send_to_H_B_Implementation__c='Yes'
                                             ,CloseDate=Date.today().addDays(30)
                                             ,OwnerId=u1.id);
        insert oppty1;
        Test.enableChangeDataCapture();
        OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId=ctct.Id, OpportunityId=oppty1.Id, IsPrimary=true);
        insert ocr1;
        Test.getEventBus().deliver(); 
    }
    
        

}