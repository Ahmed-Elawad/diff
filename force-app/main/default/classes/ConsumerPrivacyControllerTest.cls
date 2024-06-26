/* 
 * Test methods for ConsumerPrivacyController.
 *
 * History
 * -------
 * 09/24/2022   Chris Santoro Created
*/

@isTest(seeAllData=false)
public class ConsumerPrivacyControllerTest 
{
    static testMethod void testSubmit()
    {
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Name='Consumer Privacy Site Guest User' and IsActive=true limit 1];

        System.runAs(runningUser) 
        {  
            ConsumerPrivacyController cpc = new ConsumerPrivacyController();
            cpc.refCP.Submitter_First_Name__c = 'John';
            cpc.refCP.Submitter_Last_Name__c = 'Doe';
            cpc.refCP.Email_Address__c = 'jdoe@test.com';
            System.debug('phone number ' + cpc.refCP.Phone_Number__c);
            cpc.getSelectOptions();
            cpc.requestOptionSelection = cpc.requestOptions[1].getValue();
            
            Attachment attach = new Attachment();   	
            attach.Name='Unit Test Attachment';
            Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
            attach.body = bodyBlob;
            cpc.authAgentAttachment = attach;
            
            cpc.refCP.Consumer_First_Name__c = 'Jane';
            cpc.refCP.Consumer_Last_Name__c = 'Smith';
            cpc.refCP.Consumer_Email__c = 'jdoe@test.com';
            cpc.refCP.Consumer_Phone__c = '585-111-2222';
            cpc.refCP.Address_Line1__c = '123 Test Drive';
            cpc.refCP.Address_Line2__c = 'Apt 6';
            cpc.refCP.City__c = 'Rochester';
            cpc.refCP.State__c = 'CA';
            cpc.refCP.Zip_Code__c = '12345';
            cpc.ssn = '123-12-1234';
            cpc.ssnRekey = '123-12-1234';
            cpc.dateOfBirth = '8/22/1991';
            cpc.refCP.PI_Categories__c = true;
            cpc.refCP.Communication_Type__c = cpc.communicationOptions[0].getValue(); 
            cpc.validateForm();
            System.assertEquals(true, cpc.validateForm());
            cpc.submitForm();
            System.assertEquals(true, cpc.submitted);
        }
    }
    
    static testMethod void testBadValidateForm()
    {
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Name='Consumer Privacy Site Guest User' and IsActive=true limit 1];
        
        System.runAs(runningUser) 
        {  
            ConsumerPrivacyController cpc = new ConsumerPrivacyController();
            cpc.refCP.Submitter_First_Name__c = '';
            cpc.refCP.Submitter_Last_Name__c = '';
            cpc.refCP.Email_Address__c = 'jdoeinvalidemailtest.com';
            cpc.getSelectOptions();
            cpc.refCP.Consumer_First_Name__c = '';
            cpc.refCP.Consumer_Last_Name__c = '';
            cpc.refCP.Consumer_Phone__c = '582222';
            cpc.refCP.Consumer_Email__c = 'jdoeinvalidemailtest.com';
            cpc.refCP.Address_Line1__c = '';
            cpc.refCP.Address_Line2__c = '';
            cpc.refCP.City__c = '';
            cpc.refCP.State__c = 'CA';
            cpc.refCP.Zip_Code__c = '1245';
            cpc.ssn = '123-1-1234';
            cpc.ssnRekey = '123-1234';
            cpc.dateOfBirth = '8/22/191';
            cpc.validateForm();
            System.assertEquals(false, cpc.validateForm());
            
            cpc.refCP.Phone_Number__c = '';
            cpc.refCP.Email_Address__c = '';
            cpc.refCP.Zip_Code__c = '';
            cpc.refCP.State__c = '';
            cpc.ssn = '';
            cpc.ssnRekey = '';
            cpc.dateOfBirth = '';
            cpc.validateForm();
            System.assertEquals(false, cpc.validateForm());
            
            //Mailing Address fields (only required if user selects mail)
            
            cpc.requestOptionSelection = cpc.requestOptions[1].getValue();
            cpc.authAgentAttachment = null;
            cpc.refCP.Communication_Type__c = 'By mail at the following address:'; 
            cpc.refCP.Mailing_Address_Line1__c = '';
            cpc.refCP.Mailing_Address_Line2__c = '';
            cpc.refCP.Mailing_State__c = '';
            cpc.refCP.Mailing_City__c = '';
            cpc.refCP.Mailing_Zip_Code__c = '';
            cpc.validateForm();
            System.assertEquals(false, cpc.validateForm());
            
            //Test Mailing Zip Code validation
            cpc.refCP.Mailing_Zip_Code__c = '1234';
            cpc.validateForm();
            System.assertEquals(false, cpc.validateForm());
            cpc.submitForm();
            System.assertEquals(false, cpc.submitted);
        }
    }
}