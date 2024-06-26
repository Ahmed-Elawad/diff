/* Test Methods for the ContactTriggerBeforeMethods class
   
  History
  -------
  09/29/2016 Dan Carmen   Created from AccountCheckOwnerTest
  04/18/2017 Cindy Freeman	  Modified for ToBeDeleted test
  09/24/2019 Cindy Freeman	  Modified to cover ProcessNotes change in ContactBefore trigger
  04/09/2020 Dan Carmen       Remove logic for Relational Junction updating contacts
  04/17/2021 Dan Carmen       Increment API
  01/04/2022 Dan Carmen       Setup custom settings
  12/16/2022 Dan Carmen       Add process notes on insert of the contact for checking the sales contact flag.

*/
@isTest 
public class ContactTriggerBeforeMethodsTest {
    
   @testSetup
   public static void setupData() {
      RecordTypeHelperTest.setupRecordType();
   } // setupData

    static testMethod void testBeforeTriggerActions() {
       ZipCheckOwnerTest.setupCustomSettings();
       UserHelperTest.setupGenericUsers();
       
       Account acct = new Account(Name='Test Acct');
       insert acct;
       
       Map<String,Schema.RecordTypeInfo> rtMapByName = Contact.SObjectType.getDescribe().getRecordTypeInfosByName();
       Schema.RecordTypeInfo ctctRtInfo = rtMapByName.get(ZipCheckOwnerTest.rtCoreCtct1.Name);
       System.assertEquals(true, ctctRtInfo != null);
       
       User sfdcUser = [Select Id, Name from User where IsActive=true and Name=:UserHelper.SFDC_DATA limit 1];
       
       System.runAs(sfdcUser) {
       	  Contact ctct3 = new Contact(AccountId=acct.Id, LastName='Contact3', RecordTypeId=ctctRtInfo.getRecordTypeId());
       	  insert ctct3;
       	  ctct3.To_Be_Deleted__c = true;
       	  update ctct3;
       	  
       	  ctct3 = [Select Id, RecordTypeId, Reason_for_Delete__c from Contact where id=:ctct3.Id];
       	  System.assertEquals('HRIS-No longer used', ctct3.Reason_for_Delete__c);
       	  
       	  ctct3.To_Be_Deleted__c = false;
       	  update ctct3;
       	  ctct3 = [Select Id, RecordTypeId, Reason_for_Delete__c from Contact where id=:ctct3.Id];
       	  System.assertEquals(null, ctct3.Reason_for_Delete__c);       	  	  

          ctct3.DoNotCall = true;
       	  ctct3.HasOptedOutOfEmail = true;
       	  update ctct3;
       	  ctct3 = [Select Id, DoNotCall, Consent_to_Text__c, HasOptedOutOfEmail, ProcessNotes__c from Contact where id=:ctct3.Id];
       	  //System.assertEquals(false, ctct3.DoNotCall);
       	  System.assertEquals(false, ctct3.Consent_to_Text__c);
       	  //System.assertEquals(false, ctct3.HasOptedOutOfEmail);
       	  //System.assertEquals(true, ctct3.ProcessNotes__c.contains('no phone numbers'));
       	  //System.assertEquals(true, ctct3.ProcessNotes__c.contains('no email address'));
       	  
       }
    } // testBeforeTriggerActions
} // ContactTriggerBeforeMethodsTest