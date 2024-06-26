/* 
 * Test methods for ConsumerPrivacyEmailHandler.
 *
 * History
 * -------
 * 10/07/2022   Chris Santoro Created
*/

@isTest(seeAllData=false)
public class ConsumerPrivacyEmailHandlerTest 
{
    static testMethod void testGoodEmail()
    {
        User guestUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Name='Consumer Privacy Site Guest User' and IsActive=true limit 1];
        User coeAutomatedUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Name='COE Automated User' and IsActive=true limit 1];

        Schema.DescribeFieldResult commType = Reference_Consumer_Privacy__c.Communication_Type__c.getDescribe();
        List<Schema.PicklistEntry> commTypeEntries = commType.getPicklistValues();
        
        Schema.DescribeFieldResult requestType = Reference_Consumer_Privacy__c.Request_Option__c.getDescribe();
        List<Schema.PicklistEntry> requestTypeEntries = requestType.getPicklistValues();
        
        Schema.DescribeFieldResult options = Reference_Consumer_Privacy__c.Options__c.getDescribe();
        List<Schema.PicklistEntry> optionsEntries = options.getPicklistValues();
               
        Reference_Consumer_Privacy__c refCP = new Reference_Consumer_Privacy__c();

        System.runAs(guestUser)
        {
            
            refCP.Submitter_First_Name__c = 'John';
            refCP.Submitter_Last_Name__c = 'Doe';
            refCP.Consumer_Phone__c = '585-111-2222';
            refCP.Email_Address__c = 'jdoe@test.com';
            refCP.Options__c = optionsEntries[0].getValue();
            refCP.Consumer_First_Name__c = 'Jane';
            refCP.Consumer_Last_Name__c = 'Smith';
            refCP.Consumer_Email__c = 'jdoe@test.com';
            refCP.Consumer_Phone__c = '111-222-3333';
            refCP.Address_Line1__c = '123 Test Drive';
            refCP.Address_Line2__c = 'Apt 6';
            refCP.City__c = 'Rochester';
            refCP.State__c = 'CA';
            refCP.Zip_Code__c = '12345';
            refCP.SSN__c = '123121234';
            refCP.Date_of_Birth__c = Date.today();
            refCP.Request_Option__c = requestTypeEntries[0].getValue();
            refCP.Communication_Type__c = commTypeEntries[0].getValue();   
            insert refCP;
        }
        
        system.debug('refCP ID ' + refCP.Id);
        
        System.runAs(coeAutomatedUser) 
        {       
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
            
            email.subject = 'Consumer Privacy Request';
            email.fromname = 'Guest User';
            env.fromAddress = 'sfdc_automation@paychex.com';
            email.plainTextBody = refCP.Id; 
            
            ConsumerPrivacyEmailHandler cpEmailHandler = new ConsumerPrivacyEmailHandler();
            cpEmailHandler.handleInboundEmail(email, env);
        }
        
        Reference_Consumer_Privacy__c refCPTest = [Select Email_Confirm_Sent__c from Reference_Consumer_Privacy__c where Id = :refCP.Id limit 1];
        System.assertEquals(refCPTest.Email_Confirm_Sent__c, true);
    }
}