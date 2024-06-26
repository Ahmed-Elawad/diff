/*
 *  This class will gather input from BenAdminOnboardingSetupInfo.vfp create XML and email to the BenAdminOnboardingEmail email service
 *
 * History
 * --------
 * 07/10/2022  Carrie Marciano  created
 * 
 */ 

@isTest(seeAllData=false) 
public class BenAdminOnbSetupInfoControllerTest {


    static testMethod void goodInfo() {
            Id hnbfOppRT = RecordTypeHelper.getRecordType('HNBF Opportunity Record Type','Opportunity').getRecordTypeId();
            
            PaychexSettings__c pxs = new PaychexSettings__c (name='BenAdminOnbErrorEmail',IsActive__c = true , Attribute1__c ='cmarciano@paychex.com'); 
            insert pxs;
            
            Account testAcct = new Account(Name = 'Test Acct', NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId='012300000000hNv');
            insert testAcct;
            
            User salesRep = [SELECT ID, Person_ID_Number__c FROM User WHERE Profile.Name = 'HNBF Sales Rep' and IsActive = true LIMIT 1];
            
            Opportunity testOpp = new Opportunity(AccountId=testAcct.Id,OwnerId=salesRep.Id,Name='TestOpp',Type='Flock',StageName=label.OppStage_Won,CloseDate=date.today(),RecordTypeId=hnbfOppRT,Send_to_H_B_Implementation__c='No');
            insert testOpp;
            
            Reference_Opportunity_Product__c testRop = new Reference_Opportunity_Product__c(Opportunity__c=testOpp.Id, COBRA_Administration_Services__c=True, BalanceBenefits_Call_Center__c=True, Employer_Shared_Responsibility__c=True);
            insert testRop;
            
            System.runAs(salesRep) {        
                //Set Current Page to new reference
                PageReference pageRef = new PageReference('/apex/BenAdminOnboardingSetupInfo?id='+testOpp.Id);
                test.setCurrentPageReference(pageRef);
                Test.startTest();
                    ApexPages.Standardcontroller sc = New ApexPages.StandardController(testOpp);
                    BenAdminOnboardingSetupInfoController bAOSetInfo = new BenAdminOnboardingSetupInfoController(sc);
                
                    bAOSetInfo.BrokerContactforImp = 'Josh Allen';
                    bAOSetInfo.ClientContactforImp = 'Stefon Diggs';
                    bAOSetInfo.OpenEnrollmentDates = '6/30/2022';
                    bAOSetInfo.ClientReqDeliveryDate = '9/3/2022';
                    bAOSetInfo.Notes = 'This is a new Flock onboarding';
                    bAOSetInfo.nbrCarriers = 2; 
                    PageReference prNumCarriers = bAOSetInfo.changeNbrCarriers();
                    System.assertEquals(2, bAOSetInfo.carriers.size());
                
                    BenAdminOnboardingSetupInfoController.CarrierWrapper cw0 = bAOSetInfo.carriers[0];
                    cw0.carrierName = 'Carrier A';
                    cw0.ediConnection = 'No';
                    cw0.groupPolicyNumber = '123456789';
                    cw0.carrierContact = 'Dion Dawkins';
                    BenAdminOnboardingSetupInfoController.CarrierWrapper cw1 = bAOSetInfo.carriers[1];
                    cw1.carrierName = 'Carrier B';
                    cw1.ediConnection = 'Yes';
                    cw1.groupPolicyNumber = '987654321';
                    cw1.carrierContact = 'Isaiah McKenzie';
                
                    PageReference prSubmit = bAOSetInfo.submit();                   
                Test.stopTest();
                ApexPages.Message msg = ApexPages.getMessages()[0];
                System.assertEquals('Successfully gathered information.  Onboarding case will be created.',msg.getDetail() );
                Opportunity updatedOpp = [Select Id, Onboarding_Info_Sent__c from Opportunity where Id = :testOpp.Id];
                System.assertEquals(true, updatedOpp.Onboarding_Info_Sent__c);
               
            } // System.runAs(runningUser
    } // goodParseTEXT 
    
    static testMethod void cancel() {
            Id hnbfOppRT = RecordTypeHelper.getRecordType('HNBF Opportunity Record Type','Opportunity').getRecordTypeId();
            
            PaychexSettings__c pxs = new PaychexSettings__c (name='BenAdminOnbErrorEmail',IsActive__c = true , Attribute1__c ='cmarciano@paychex.com'); 
            insert pxs;
            
            Account testAcct = new Account(Name = 'Test Acct', NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId='012300000000hNv');
            insert testAcct;
            
            User salesRep = [SELECT ID, Person_ID_Number__c FROM User WHERE Profile.Name = 'HNBF Sales Rep' and IsActive = true LIMIT 1];
            
            Opportunity testOpp = new Opportunity(AccountId=testAcct.Id,OwnerId=salesRep.Id,Name='TestOpp',Type='Flock',StageName=label.OppStage_Won,CloseDate=date.today(),RecordTypeId=hnbfOppRT);
            insert testOpp;
            
            Reference_Opportunity_Product__c testRop = new Reference_Opportunity_Product__c(Opportunity__c=testOpp.Id, COBRA_Administration_Services__c=True, BalanceBenefits_Call_Center__c=True, Employer_Shared_Responsibility__c=True);
            insert testRop;
            
            System.runAs(salesRep) {        
                //Set Current Page to new reference
                PageReference pageRef = new PageReference('/apex/BenAdminOnboardingSetupInfo?id='+testOpp.Id);
                test.setCurrentPageReference(pageRef);
                Test.startTest();
                    ApexPages.Standardcontroller sc = New ApexPages.StandardController(testOpp);
                    BenAdminOnboardingSetupInfoController bAOSetInfo = new BenAdminOnboardingSetupInfoController(sc);
                
                    bAOSetInfo.BrokerContactforImp = 'Josh Allen';
                    bAOSetInfo.ClientContactforImp = 'Stefon Diggs';
                    bAOSetInfo.OpenEnrollmentDates = '6/30/2022';
                    bAOSetInfo.ClientReqDeliveryDate = '9/3/2022';
                    bAOSetInfo.Notes = 'This is a new Flock onboarding';
                    bAOSetInfo.nbrCarriers = 2; 
                    PageReference prNumCarriers = bAOSetInfo.changeNbrCarriers();
                    System.assertEquals(2, bAOSetInfo.carriers.size());
                
                    BenAdminOnboardingSetupInfoController.CarrierWrapper cw0 = bAOSetInfo.carriers[0];
                    cw0.carrierName = 'Carrier A';
                    cw0.ediConnection = 'No';
                    cw0.groupPolicyNumber = '123456789';
                    cw0.carrierContact = 'Dion Dawkins';
                    BenAdminOnboardingSetupInfoController.CarrierWrapper cw1 = bAOSetInfo.carriers[1];
                    cw1.carrierName = 'Carrier B';
                    cw1.ediConnection = 'Yes';
                    cw1.groupPolicyNumber = '987654321';
                    cw1.carrierContact = 'Isaiah McKenzie';
                
                    PageReference prCancel = bAOSetInfo.cancel(); 
                    System.assertEquals(true,(prCancel.getUrl().contains(testOpp.Id)));
                Test.stopTest();
                
            } // System.runAs(runningUser
    } // cancel 
}