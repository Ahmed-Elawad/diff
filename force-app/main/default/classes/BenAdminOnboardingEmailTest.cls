/**
* Test method for BenAdminOnboardingEmail
* 
* History
* --------
* 06/10/2022  Carrie Marciano  created
* 08/30/2023  Shilpa G		   Added Flock product in ROP records
*/

@isTest
public class BenAdminOnboardingEmailTest {
    
    // test good parsing of plain text
    @isTest(SeeAllData=false)
    static void goodParseTEXT() {
            Id hnbfOppRT = RecordTypeHelper.getRecordType('HNBF Opportunity Record Type','Opportunity').getRecordTypeId();
            
            PaychexSettings__c pxs = new PaychexSettings__c (name='BenAdminOnbErrorEmail',IsActive__c = true , Attribute1__c ='cmarciano@paychex.com'); 
            insert pxs;
            
            User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
            
            Account testAcct = new Account(Name = 'Test Acct', NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId='012300000000hNv');
            insert testAcct;
            
            User salesRep = [SELECT ID, Person_ID_Number__c FROM User WHERE Profile.Name = 'Core Sales - SB' and IsActive = true and Person_ID_Number__c != null LIMIT 1];
            
            Opportunity testOpp = new Opportunity(AccountId=testAcct.Id,OwnerId=salesRep.Id,Name='TestOpp',Type='Flock',StageName='Sold - Submitted',CloseDate=date.today(),RecordTypeId=hnbfOppRT,Send_to_H_B_Implementation__c='No');
            insert testOpp;
            
            Reference_Opportunity_Product__c testRop = new Reference_Opportunity_Product__c(Opportunity__c=testOpp.Id, COBRA_Administration_Services__c=True, BalanceBenefits_Call_Center__c=True, Employer_Shared_Responsibility__c=True,Flock__c=True);
            insert testRop;
            
            System.runAs(runningUser) {        
                Messaging.InboundEmail email = new Messaging.InboundEmail();
                Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
                
                // setup the data for the email
         		email.subject = 'Test BenAdmin Onboarding';
         		email.fromname = 'FirstName LastName';
		        env.fromAddress = 'someaddress@email.com';
                
                String benAdminMsg = '<BenAdminOnb>\r <AccountId>'+testAcct.Id+'</AccountId>\r <CompanyName>'+testAcct.Name+'</CompanyName>\r <OpportunityId>'+testOpp.Id+'</OpportunityId>\r';
                benAdminMsg += '<SalesRepId>'+salesRep.Person_ID_Number__c+'</SalesRepId>\r <Origin>MMS</Origin>\r <BrokerContactforImp>Josh Allen</BrokerContactforImp>\r <ClientContactforImp>Stefon Diggs</ClientContactforImp>\r';
                benAdminMsg += '<OpenEnrollmentDates>6/30/2022</OpenEnrollmentDates>\r <ClientReqDeliveryDate>9/3/2022</ClientReqDeliveryDate>\r <Notes>This is a new Flock onboarding</Notes>\r';
                benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 1</CarrierName>\r <EDIConnection>No</EDIConnection>\r <GroupPolicyNumber>11111</GroupPolicyNumber>\r <CarrierContact>Dion Dawkins</CarrierContact>\r </CarrierInfo>\r';
                benAdminMsg += '</BenAdminOnb>'; 
                email.plainTextBody = benAdminMsg; 
                
                // call Helper class directly to check parsing then process list creating new account and contact       
                BenAdminOnboardingHelper.benAdminOnb bAO = new BenAdminOnboardingHelper.benAdminOnb();
                bAO = BenAdminOnboardingHelper.parseXml(email.plainTextBody);
                
                system.debug('bAO: '+bAO);
                System.assertEquals(bAO.accountId, testAcct.Id);
                System.assertEquals(bAO.opportunityId, testOpp.Id);
                System.assertEquals(bAO.salesRepId, salesRep.Person_ID_Number__c);
                System.assertEquals(bAO.origin,'MMS');
                System.assertEquals(bAO.brokerContactforImp, 'Josh Allen');
                System.assertEquals(bAO.clientContactforImp, 'Stefon Diggs');
                System.assertEquals(bAO.openEnrollmentDates, '6/30/2022');
                System.assertEquals(bAO.clientReqDeliveryDate, '9/3/2022');
                System.assertEquals(bAO.notes, 'This is a new Flock onboarding');
                
                BenAdminOnboardingEmail bAOE = new BenAdminOnboardingEmail();
                bAOE.handleInboundEmail(email, env);
                
        	} // System.runAs(runningUser
    } // goodParseTEXT 
    
    // test good parsing of html
    @isTest(SeeAllData=false)
    static void goodParseHTML() {
            Id hnbfOppRT = RecordTypeHelper.getRecordType('HNBF Opportunity Record Type','Opportunity').getRecordTypeId();
            
            PaychexSettings__c pxs = new PaychexSettings__c (name='BenAdminOnbErrorEmail',IsActive__c = true , Attribute1__c ='cmarciano@paychex.com'); 
            insert pxs;
            
            User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
            
            Account testAcct = new Account(Name = 'Test Acct', NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId='012300000000hNv');
            insert testAcct;
            
            User salesRep = [SELECT ID, Person_ID_Number__c FROM User WHERE Profile.Name = 'Core Sales - SB' and IsActive = true and Person_ID_Number__c != null LIMIT 1];
            
            Opportunity testOpp = new Opportunity(AccountId=testAcct.Id,OwnerId=salesRep.Id,Name='TestOpp',Type='Flock',StageName='Sold - Submitted',CloseDate=date.today(),RecordTypeId=hnbfOppRT,Send_to_H_B_Implementation__c='No');
            insert testOpp;
            
            Reference_Opportunity_Product__c testRop = new Reference_Opportunity_Product__c(Opportunity__c=testOpp.Id, COBRA_Administration_Services__c=True, BalanceBenefits_Call_Center__c=True, Employer_Shared_Responsibility__c=True,Flock__c=True);
            insert testRop;
            
            System.runAs(runningUser) {        
                Messaging.InboundEmail email = new Messaging.InboundEmail();                
                email.htmlBody = '<BenAdminOnb>';
                
                email.htmlBody += addXML('AccountId',testAcct.Id);
                email.htmlBody += addXML('CompanyName',testAcct.Name);
                email.htmlBody += addXML('OpportunityId',testOpp.Id);
                email.htmlBody += addXML('SalesRepId',salesRep.Person_ID_Number__c);
                email.htmlBody += addXML('Origin','MMS');
                email.htmlBody += addXML('BrokerContactforImp','Josh Allen');
                email.htmlBody += addXML('ClientContactforImp','Stefon Diggs');
                email.htmlBody += addXML('OpenEnrollmentDates','6/30/2022');
                email.htmlBody += addXML('ClientReqDeliveryDate','9/3/2022');
                email.htmlBody += addXML('Notes','This is a new Flock onboarding');
                email.htmlBody += '<CarrierInfo>';
                email.htmlBody += addXML('CarrierName','Test Carrier 1');
                email.htmlBody += addXML('EDIConnection','No');
                email.htmlBody += addXML('GroupPolicyNumber','11111');
                email.htmlBody += addXML('CarrierContact','Dion Dawkins');
                email.htmlBody += '</CarrierInfo>';
                email.htmlBody += '</BenAdminOnb>\r\nThe information contained';
                
                Test.startTest();
                	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
                	BenAdminOnboardingEmail bAOE = new BenAdminOnboardingEmail();
                	bAOE.handleInboundEmail(email, env);
                Test.StopTest();
                
                Case[] caseList = [Select Id, AccountId, Opportunity__c, Sales_Rep__c from Case where Product__c = 'Flock' and Account.Id = :testAcct.Id];
                System.assertEquals(1, caseList.size());
                Reference_BeneTrac_Onboarding__c[] refBTOnbList = [Select id, Case_Number__c, Type__c from Reference_BeneTrac_Onboarding__c 
                                                                   where Type__c = 'Flock' and Case_Number__c = :caseList[0].Id];
                System.assertEquals(1, refBTOnbList.size());
                                          
        	} // System.runAs(runningUser
    } // goodParseHTML       
    
    static testMethod void testBadXML(){
        Boolean testPassed = false;
        string except;
        
        PaychexSettings__c pxs = new PaychexSettings__c (name='BenAdminOnbErrorEmail',IsActive__c = true , Attribute1__c ='cmarciano@paychex.com'); 
        insert pxs;
        
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.htmlBody = '<BenAdminOnb><junk></BenAdminOnb>';
        Messaging.InboundEnvelope envBad = new Messaging.InboundEnvelope();
        BenAdminOnboardingEmail bAOE = new BenAdminOnboardingEmail();
        try{
            bAOE.handleInboundEmail(email, envBad);
        }
        catch(BenAdminOnboardingEmail.BenAdminException ba)
        {   testPassed = true;  }     // sends email instead of throwing error coz email body is empty
        System.assertEquals(false, testPassed);
        
    } //testBadXML
    
    static string addXML(string tag, string content){
        return '<' + tag + '>' + content + '</' + tag + '>\r\n';
    }
}