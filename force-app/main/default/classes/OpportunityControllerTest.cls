/* 
   Test methods for the OpportunityController 
   
  History
  -------
  05/18/2021 	Carrie Marciano updated StageNames with OppStage labels

 */

@isTest
public class OpportunityControllerTest {

    public static testMethod void TestOpportunityControllerApprove() {
        User testSalesRep = [Select Id, Name, Profile.Name, UserRole.Name from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and IsActive=true limit 1];      
        Account testAccount = new Account(Name='TestAccount',OwnerId=testSalesRep.Id);
        insert testAccount;
        LeadLoaderConfig__c config = new LeadLoaderConfig__c(Name='Test Inbound', IsActive__c=true, NSSSource__c=ProspectOwnershipMethods.NSS_INBOUND, QueueName__c='Test Inbound', UseAssignmentRules__c=false);
        insert config;
        Contact testContact = new Contact(LastName='NewLast', AccountId=testAccount.Id, Contact_Stage__c='MQL',OwnedBy__c=config.QueueName__c);
        insert testContact;
        
        Test.StartTest();   
        Opportunity testOpp = new Opportunity(AccountId=testAccount.Id, Name='Test Opp1',StageName='Pending', CloseDate=Date.today().addDays(7), OpportunityId__c=testcontact.Id);
        insert testOpp;
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        OpportunityController Opp = new OpportunityController(sc);
        PageReference pageRef = Page.UpdateOpportunityStatus;
        pageRef.getParameters().put('id', String.valueOf(testOpp.Id));
        Test.setCurrentPage(pageRef);
        Opp.Status = '';
        Opp.approve();
        Test.stopTest(); 
        
        Opportunity assertOpp = [SELECT Id,StageName FROM Opportunity Where ID = :testOpp.id];
        system.assertEquals(Label.OppStage_Gained_Access,assertOpp.stageName);    
    }
    
    public static testMethod void TestOpportunityControllerReject() {
        User testSalesRep = [Select Id, Name, Profile.Name, UserRole.Name from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and IsActive=true limit 1];      
        Account testAccount = new Account(Name='TestAccount',OwnerId=testSalesRep.Id);
        insert testAccount;
        LeadLoaderConfig__c config = new LeadLoaderConfig__c(Name='Test Inbound', IsActive__c=true, NSSSource__c=ProspectOwnershipMethods.NSS_INBOUND, QueueName__c='Test Inbound', UseAssignmentRules__c=false);
        insert config;
        Contact testContact = new Contact(LastName='NewLast', AccountId=testAccount.Id, Contact_Stage__c='MQL',OwnedBy__c=config.QueueName__c);
        insert testContact;
        
        Test.StartTest();   
        Opportunity testOpp = new Opportunity(AccountId=testAccount.Id, Name='Test Opp1',StageName='Pending', CloseDate=Date.today().addDays(7), OpportunityId__c=testcontact.Id);
        insert testOpp;
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        OpportunityController Opp = new OpportunityController(sc);
        PageReference pageRef = Page.UpdateOpportunityStatus;
        pageRef.getParameters().put('id', String.valueOf(testOpp.Id));
        Test.setCurrentPage(pageRef);
        Opp.reject();
        Opp.Status = 'Duplicate Opportunity';
        Opp.save();
        Test.stopTest(); 
        
        Opportunity assertOpp = [SELECT Id,StageName,Reason_Not_Sold__c FROM Opportunity Where ID = :testOpp.id];
        System.assertEquals(Label.OppStage_Lost,assertOpp.stageName); 
        System.assertEquals('Duplicate Opportunity',assertOpp.Reason_Not_Sold__c);
    }

}