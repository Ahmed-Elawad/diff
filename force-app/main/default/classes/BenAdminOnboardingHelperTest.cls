/*
*
* History
* --------
* 06/10/2022  Carrie Marciano  created
* 08/30/2023  Shilpa G		   APR0143763: Added method testAncillaryOnlyCaseRef to test Ancillary Only Sale
*/

@isTest
public class BenAdminOnboardingHelperTest {

    @isTest
    static void testCaseRefCreate(){
        Id hnbfOppRT = RecordTypeHelper.getRecordType('HNBF Opportunity Record Type','Opportunity').getRecordTypeId();
        
        PaychexSettings__c pxs = new PaychexSettings__c (name='BenAdminOnbErrorEmail',IsActive__c = true , Attribute1__c ='cmarciano@paychex.com'); 
        insert pxs;
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
    
        Account testAcct = new Account(Name = 'Test Acct', NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId='012300000000hNv');
        insert testAcct;
        
        User salesRep = [SELECT ID, Person_ID_Number__c FROM User WHERE Profile.Name = 'Core Sales - SB' and IsActive = true and Person_ID_Number__c!= null LIMIT 1];
        
        Opportunity testOpp = new Opportunity(AccountId=testAcct.Id,OwnerId=salesRep.Id,Name='TestOpp',Type='Flock',StageName='Sold - Submitted',CloseDate=date.today(),RecordTypeId=hnbfOppRT,Send_to_H_B_Implementation__c='No');
        insert testOpp;
        
        Reference_Opportunity_Product__c testRop = new Reference_Opportunity_Product__c(Opportunity__c=testOpp.Id, COBRA_Administration_Services__c=True, BalanceBenefits_Call_Center__c=True, Employer_Shared_Responsibility__c=True,Flock__c=True);
        insert testRop;
        
        String benAdminMsg = '<BenAdminONB>\r <AccountId>'+testAcct.Id+'</AccountId>\r <CompanyName>'+testAcct.Name+'</CompanyName>\r <OpportunityId>'+testOpp.Id+'</OpportunityId>\r';
        benAdminMsg += '<SalesRepId>'+salesRep.Person_ID_Number__c+'</SalesRepId>\r <Origin>MMS</Origin>\r <BrokerContactforImp>Josh Allen</BrokerContactforImp>\r <ClientContactforImp>Stefon Diggs</ClientContactforImp>\r';
        benAdminMsg += '<OpenEnrollmentDates>6/30/2022</OpenEnrollmentDates>\r <ClientReqDeliveryDate>9/3/2022</ClientReqDeliveryDate>\r <Notes>This is a new Flock onboarding</Notes>\r';
        benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 1</CarrierName>\r <EDIConnection>No</EDIConnection>\r <GroupPolicyNumber>11111</GroupPolicyNumber>\r <CarrierContact>Dion Dawkins</CarrierContact>\r </CarrierInfo>\r';
        //benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 2</CarrierName>\r <EDIConnection>Yes</EDIConnection>\r <GroupPolicyNumber>22222</GroupPolicyNumber>\r <CarrierContact>Gabe Davis</CarrierContact>\r </CarrierInfo>\r';
        //benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 3</CarrierName>\r <EDIConnection>No</EDIConnection>\r <GroupPolicyNumber>33333</GroupPolicyNumber>\r <CarrierContact>Dawson Knox</CarrierContact>\r </CarrierInfo>\r';
        benAdminMsg += '</BenAdminONB>';         
        
        BenAdminOnboardingHelper.benAdminOnb benAdminO = new BenAdminOnboardingHelper.benAdminOnb();
        benAdminO = BenAdminOnboardingHelper.parseXml(benAdminMsg);
        
        List<BenAdminOnboardingHelper.benAdminOnb> benAdminOList = new List<BenAdminOnboardingHelper.benAdminOnb>();
        benAdminOList.add(benAdminO);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            BenAdminOnboardingHelper.processbenAdminOnb(benAdminOList);
            Test.stopTest();
            
            Case[] caseList = [Select Id, AccountId, Opportunity__c, Sales_Rep__c from Case where Product__c = 'Flock' and Onboarding_Type__c = 'Flock' and Account.Id = :testAcct.Id];
            System.assertEquals(1, caseList.size());
            Reference_BeneTrac_Onboarding__c[] refBTOnbList = [Select id, Case_Number__c, Type__c from Reference_BeneTrac_Onboarding__c 
                                                               where Type__c = 'Flock' and Case_Number__c = :caseList[0].Id];
            System.assertEquals(1, refBTOnbList.size());
        }  
    }
    
    @isTest
    static void testBadAcct(){
    	Id hnbfOppRT = RecordTypeHelper.getRecordType('HNBF Opportunity Record Type','Opportunity').getRecordTypeId();
       
        PaychexSettings__c pxs = new PaychexSettings__c (name='BenAdminOnbErrorEmail',IsActive__c = true , Attribute1__c ='cmarciano@paychex.com'); 
        insert pxs;
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
    
        User salesRep = [SELECT ID FROM User WHERE Profile.Name = 'Core Sales - SB' and IsActive = true LIMIT 1];
        
        String benAdminMsg = '<BenAdminONB>\r <AccountId></AccountId>\r <CompanyName></CompanyName>\r <OpportunityId></OpportunityId>\r';
        benAdminMsg += '<SalesRepId>'+salesRep.Id+'</SalesRepId>\r <Origin>MMS</Origin>\r <BrokerContactforImp>Josh Allen</BrokerContactforImp>\r <ClientContactforImp>Stefon Diggs</ClientContactforImp>\r';
        benAdminMsg += '<OpenEnrollmentDates>6/30/2022</OpenEnrollmentDates>\r <ClientReqDeliveryDate>9/3/2022</ClientReqDeliveryDate>\r <Notes>This is a new Flock onboarding</Notes>\r';
        benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 1</CarrierName>\r <EDIConnection>No</EDIConnection>\r <GroupPolicyNumber>11111</GroupPolicyNumber>\r <CarrierContact>Dion Dawkins</CarrierContact>\r </CarrierInfo>\r';
        //benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 2</CarrierName>\r <EDIConnection>Yes</EDIConnection>\r <GroupPolicyNumber>22222</GroupPolicyNumber>\r <CarrierContact>Gabe Davis</CarrierContact>\r </CarrierInfo>\r';
        //benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 3</CarrierName>\r <EDIConnection>No</EDIConnection>\r <GroupPolicyNumber>33333</GroupPolicyNumber>\r <CarrierContact>Dawson Knox</CarrierContact>\r </CarrierInfo>\r';
        benAdminMsg += '</BenAdminONB>';         
        
        BenAdminOnboardingHelper.benAdminOnb benAdminO = new BenAdminOnboardingHelper.benAdminOnb();
        benAdminO = BenAdminOnboardingHelper.parseXml(benAdminMsg);
        
        List<BenAdminOnboardingHelper.benAdminOnb> benAdminOList = new List<BenAdminOnboardingHelper.benAdminOnb>();
        benAdminOList.add(benAdminO);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            BenAdminOnboardingHelper.processbenAdminOnb(benAdminOList);
            Test.stopTest();
            
            //Case[] caseList = [Select Id, AccountId, Opportunity__c, Sales_Rep__c from Case where Product__c = 'Flock' and Account.Id = :testAcct.Id];
            //System.assertEquals(0, caseList.size());
        }      
    }
    
    @isTest
    static void testBadOppty(){
    	Id hnbfOppRT = RecordTypeHelper.getRecordType('HNBF Opportunity Record Type','Opportunity').getRecordTypeId();
        
        PaychexSettings__c pxs = new PaychexSettings__c (name='BenAdminOnbErrorEmail',IsActive__c = true , Attribute1__c ='cmarciano@paychex.com'); 
        insert pxs;
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
    
        Account testAcct = new Account(Name = 'Test Acct', NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId='012300000000hNv');
        insert testAcct;
        
        User salesRep = [SELECT ID FROM User WHERE Profile.Name = 'Core Sales - SB' and IsActive = true LIMIT 1];
        
        String benAdminMsg = '<BenAdminONB>\r <AccountId>'+testAcct.Id+'</AccountId>\r <CompanyName>'+testAcct.Name+'</CompanyName>\r <OpportunityId></OpportunityId>\r';
        benAdminMsg += '<SalesRepId>'+salesRep.Id+'</SalesRepId>\r <Origin>MMS</Origin>\r <BrokerContactforImp>Josh Allen</BrokerContactforImp>\r <ClientContactforImp>Stefon Diggs</ClientContactforImp>\r';
        benAdminMsg += '<OpenEnrollmentDates>6/30/2022</OpenEnrollmentDates>\r <ClientReqDeliveryDate>9/3/2022</ClientReqDeliveryDate>\r <Notes>This is a new Flock onboarding</Notes>\r';
        benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 1</CarrierName>\r <EDIConnection>No</EDIConnection>\r <GroupPolicyNumber>11111</GroupPolicyNumber>\r <CarrierContact>Dion Dawkins</CarrierContact>\r </CarrierInfo>\r';
        //benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 2</CarrierName>\r <EDIConnection>Yes</EDIConnection>\r <GroupPolicyNumber>22222</GroupPolicyNumber>\r <CarrierContact>Gabe Davis</CarrierContact>\r </CarrierInfo>\r';
        //benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 3</CarrierName>\r <EDIConnection>No</EDIConnection>\r <GroupPolicyNumber>33333</GroupPolicyNumber>\r <CarrierContact>Dawson Knox</CarrierContact>\r </CarrierInfo>\r';
        benAdminMsg += '</BenAdminONB>';         
        
        BenAdminOnboardingHelper.benAdminOnb benAdminO = new BenAdminOnboardingHelper.benAdminOnb();
        benAdminO = BenAdminOnboardingHelper.parseXml(benAdminMsg);
        
        List<BenAdminOnboardingHelper.benAdminOnb> benAdminOList = new List<BenAdminOnboardingHelper.benAdminOnb>();
        benAdminOList.add(benAdminO);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            BenAdminOnboardingHelper.processbenAdminOnb(benAdminOList);
            Test.stopTest();
            
            Case[] caseList = [Select Id, AccountId, Opportunity__c, Sales_Rep__c from Case where Product__c = 'Flock' and Account.Id = :testAcct.Id];
            System.assertEquals(0, caseList.size());
            
        }      
    }
    
    @isTest
    static void testNoSalesRep(){
    Id hnbfOppRT = RecordTypeHelper.getRecordType('HNBF Opportunity Record Type','Opportunity').getRecordTypeId();
        
        PaychexSettings__c pxs = new PaychexSettings__c (name='BenAdminOnbErrorEmail',IsActive__c = true , Attribute1__c ='cmarciano@paychex.com'); 
        insert pxs;
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
    
        Account testAcct = new Account(Name = 'Test Acct', NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId='012300000000hNv');
        insert testAcct;
        
        Opportunity testOpp = new Opportunity(AccountId=testAcct.Id,Name='TestOpp',Type='Flock',StageName='Sold - Submitted',CloseDate=date.today(),RecordTypeId=hnbfOppRT);
        insert testOpp;
        
        Reference_Opportunity_Product__c testRop = new Reference_Opportunity_Product__c(Opportunity__c=testOpp.Id, COBRA_Administration_Services__c=True, BalanceBenefits_Call_Center__c=True, Employer_Shared_Responsibility__c=True,Flock__c=True);
        insert testRop;
        
        String benAdminMsg = '<BenAdminONB>\r <AccountId>'+testAcct.Id+'</AccountId>\r <CompanyName>'+testAcct.Name+'</CompanyName>\r <OpportunityId>'+testOpp.Id+'</OpportunityId>\r';
        benAdminMsg += '<SalesRepId></SalesRepId>\r <Origin>MMS</Origin>\r <BrokerContactforImp>Josh Allen</BrokerContactforImp>\r <ClientContactforImp>Stefon Diggs</ClientContactforImp>\r';
        benAdminMsg += '<OpenEnrollmentDates>6/30/2022</OpenEnrollmentDates>\r <ClientReqDeliveryDate>9/3/2022</ClientReqDeliveryDate>\r <Notes>This is a new Flock onboarding</Notes>\r';
        benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 1</CarrierName>\r <EDIConnection>No</EDIConnection>\r <GroupPolicyNumber>11111</GroupPolicyNumber>\r <CarrierContact>Dion Dawkins</CarrierContact>\r </CarrierInfo>\r';
        //benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 2</CarrierName>\r <EDIConnection>Yes</EDIConnection>\r <GroupPolicyNumber>22222</GroupPolicyNumber>\r <CarrierContact>Gabe Davis</CarrierContact>\r </CarrierInfo>\r';
        //benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 3</CarrierName>\r <EDIConnection>No</EDIConnection>\r <GroupPolicyNumber>33333</GroupPolicyNumber>\r <CarrierContact>Dawson Knox</CarrierContact>\r </CarrierInfo>\r';
        benAdminMsg += '</BenAdminONB>';         
        
        BenAdminOnboardingHelper.benAdminOnb benAdminO = new BenAdminOnboardingHelper.benAdminOnb();
        benAdminO = BenAdminOnboardingHelper.parseXml(benAdminMsg);
        
        List<BenAdminOnboardingHelper.benAdminOnb> benAdminOList = new List<BenAdminOnboardingHelper.benAdminOnb>();
        benAdminOList.add(benAdminO);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            BenAdminOnboardingHelper.processbenAdminOnb(benAdminOList);
            Test.stopTest();
            
            Case[] caseList = [Select Id, AccountId, Opportunity__c, Sales_Rep__c from Case where Product__c = 'Flock' and Account.Id = :testAcct.Id];
            System.assertEquals(1, caseList.size());
            Reference_BeneTrac_Onboarding__c[] refBTOnbList = [Select id, Case_Number__c, Type__c from Reference_BeneTrac_Onboarding__c 
                                                               where Type__c = 'Flock' and Case_Number__c = :caseList[0].Id];
            System.assertEquals(1, refBTOnbList.size());
        }  
    
    }
    
    @isTest
    static void testAncillaryOnlyCaseRef(){
        Id hnbfOppRT = RecordTypeHelper.getRecordType('HNBF Opportunity Record Type','Opportunity').getRecordTypeId();
        
        PaychexSettings__c pxs = new PaychexSettings__c (name='BenAdminOnbErrorEmail',IsActive__c = true , Attribute1__c ='cmarciano@paychex.com'); 
        insert pxs;
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
    
        Account testAcct = new Account(Name = 'Test Acct', NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId='012300000000hNv');
        insert testAcct;
        
        User salesRep = [SELECT ID, Person_ID_Number__c FROM User WHERE Profile.Name = 'Core Sales - SB' and IsActive = true and Person_ID_Number__c!= null LIMIT 1];
        
        Opportunity testOpp = new Opportunity(AccountId=testAcct.Id,OwnerId=salesRep.Id,Name='TestOpp',Type='Flock',StageName='Sold - Submitted',CloseDate=date.today(),RecordTypeId=hnbfOppRT,Send_to_H_B_Implementation__c='No');
        insert testOpp;
        
        Reference_Opportunity_Product__c testRop = new Reference_Opportunity_Product__c(Opportunity__c=testOpp.Id, COBRA_Administration_Services__c=True);
        insert testRop;
        
        String benAdminMsg = '<BenAdminONB>\r <AccountId>'+testAcct.Id+'</AccountId>\r <CompanyName>'+testAcct.Name+'</CompanyName>\r <OpportunityId>'+testOpp.Id+'</OpportunityId>\r';
        benAdminMsg += '<SalesRepId>'+salesRep.Person_ID_Number__c+'</SalesRepId>\r <Origin>MMS</Origin>\r <BrokerContactforImp>Josh Allen</BrokerContactforImp>\r <ClientContactforImp>Stefon Diggs</ClientContactforImp>\r';
        benAdminMsg += '<OpenEnrollmentDates>6/30/2022</OpenEnrollmentDates>\r <ClientReqDeliveryDate>9/3/2022</ClientReqDeliveryDate>\r <Notes>This is a new Flock onboarding</Notes>\r';
        benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 1</CarrierName>\r <EDIConnection>No</EDIConnection>\r <GroupPolicyNumber>11111</GroupPolicyNumber>\r <CarrierContact>Dion Dawkins</CarrierContact>\r </CarrierInfo>\r';
        //benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 2</CarrierName>\r <EDIConnection>Yes</EDIConnection>\r <GroupPolicyNumber>22222</GroupPolicyNumber>\r <CarrierContact>Gabe Davis</CarrierContact>\r </CarrierInfo>\r';
        //benAdminMsg += '<CarrierInfo>\r <CarrierName>Test Carrier 3</CarrierName>\r <EDIConnection>No</EDIConnection>\r <GroupPolicyNumber>33333</GroupPolicyNumber>\r <CarrierContact>Dawson Knox</CarrierContact>\r </CarrierInfo>\r';
        benAdminMsg += '</BenAdminONB>';         
        
        BenAdminOnboardingHelper.benAdminOnb benAdminO = new BenAdminOnboardingHelper.benAdminOnb();
        benAdminO = BenAdminOnboardingHelper.parseXml(benAdminMsg);
        
        List<BenAdminOnboardingHelper.benAdminOnb> benAdminOList = new List<BenAdminOnboardingHelper.benAdminOnb>();
        benAdminOList.add(benAdminO);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            BenAdminOnboardingHelper.processbenAdminOnb(benAdminOList);
            Test.stopTest();
            
            Case[] caseList = [Select Id, AccountId, Opportunity__c, Sales_Rep__c from Case where Onboarding_Type__c = 'Ancillary Only' and Account.Id = :testAcct.Id];
            System.assertEquals(1, caseList.size());
            Reference_BeneTrac_Onboarding__c[] refBTOnbList = [Select id, Case_Number__c, Type__c from Reference_BeneTrac_Onboarding__c 
                                                               where Type__c = 'Ancillary Only' and Case_Number__c = :caseList[0].Id];
            System.assertEquals(1, refBTOnbList.size());
        }  
    }
}