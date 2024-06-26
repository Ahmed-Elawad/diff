/* 
 * Test methods for cpaServices
 *
 * History
 * -------
   03/04/2019  Dan Carmen        Add more logging to the Web Service Log
   09/28/2023  Dan Carmen        Change for OP_WITH_INVALID_USER_TYPE_EXCEPTION
 
 */
@isTest
public class CpaServicesTest 
{
    static testmethod void testgetRepInfo() {
        
        CreateTestData.createReferralAandC();
        Schema.RecordTypeInfo hrsRefCtctRt = RecordTypeHelper.getRecordType('HRS Referral Record Type', ObjectHelper.OBJECT_REF_CONTACT);
        string contactId = '11223388';
        string boguscontactId = '1111111';
        Referral_Account__c ra1 = [select Id, Name from Referral_Account__c where name = 'Referral Account1'];
        User u1 = [Select Id, Name, Phone, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c != null and Phone != null and Job_Name__c=:UserHelper.JOB_REP limit 1];
        Referral_Contact__c rc1 = new Referral_Contact__c(Name = 'First Ref Ctct1'
                                                          ,RecordTypeId=hrsRefCtctRt.getRecordTypeId()
                                                          ,Phone__c = '585-555-1212'
                                                          ,Email__c = 'fLast1@abc.com'
                                                          ,OwnerId = u1.Id
                                                          ,Contact_ID__c = contactId
                                                          ,Referral_Type__c = '100 Broker'
                                                          ,Referral_Account__c = ra1.Id);//[select Id, Name, Referral_Account__c,OwnerId, Contact_ID__c from Referral_Contact__c where Referral_Account__c = :ra1.Id];

        insert rc1;
        CpaServices.RepInfo cpaList = new CpaServices.RepInfo();
        cpaList = CpaServices.getRepInfo(contactId);
        System.assertEquals(true, rc1.OwnerId != Null);
        CpaServices.RepInfo cpa2 = CpaServices.getRepInfo(boguscontactId);
        //bogus request

   } 

    
}