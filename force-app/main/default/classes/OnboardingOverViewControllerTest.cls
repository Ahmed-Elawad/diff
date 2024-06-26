/*Test methods for the OnboardingOverViewController class.
 
  History
  -------
  05/30/2012 Carrie Marciano and Justin Stouffer   Created.
  06/25/2013 Justin Stouffer 						Complete Redesign to Use Custom Setting
  11/08/2013 Cindy Freeman							fix timezone issue when creating user
  08/19/2019 Jacob Hinds							Changes to correspond to controller change
 */
@isTest
public with sharing class OnboardingOverViewControllerTest {

  static testMethod void testRefObject() {
          
      Client_Overview_Configuration__c coc = new Client_Overview_Configuration__c(Name='HRO' 
      																			  ,Product_Name__c='HRO'
                                                                                  ,Reference_Object_Relationship_API_Name__c='Reference_HROs__r'
                                                                                  ,Completed_Onboarding_Status__c='Completed'
                                                                                  ,Case_Record_Type_Name__c='Service Onboarding HRO Case Record Type'
                                                                                  ,Owner_Custom_Label__c='HRO Specialist'
                                                                                  ,Case_Only__c=FALSE);
      
      Client_Overview_Configuration__c coc1 = new Client_Overview_Configuration__c(Name='HRO1' 
      																			  ,Product_Name__c='HRO'
                                                                                  ,Reference_Object_Relationship_API_Name__c='Reference_HROs__r'
                                                                                  ,Completed_Onboarding_Status__c='Completed'
                                                                                  ,Case_Record_Type_Name__c='Service Onboarding MSP Ref Object'
                                                                                  ,Owner_Custom_Label__c='HRO Specialist'
                                                                                  ,OnboardingPOC_api__c='Implementation_Coordinator__r'
                                                                                  ,Reference_Object_Exp_Run_Date_api__c='HRO_1st_Payroll_New_Setup_Date__c'
                                                                                  ,Current_Step_API_Name__c='Integration_Status__c'
                                                                                  ,Case_Only__c=FALSE);
      
      Client_Overview_Status_Info__c cosi= new Client_Overview_Status_Info__c(Name='HRO 1'
                                                                         ,Key__c='HRO'
                                                                         ,Number__c=1
                                                                         ,DisplayText__c='Step 1'
                                                                         ,Status__c='(1 of 6) Introductory Call');
      Client_Overview_Status_Info__c cosi2= new Client_Overview_Status_Info__c(Name='HRO 2'
                                                                         ,Key__c='HRO'
                                                                         ,Number__c=5
                                                                         ,DisplayText__c=''
                                                                         ,Status__c='Step2');
      
      insert coc;
      insert coc1;
      insert cosi;
      insert cosi2;
      
      Account a1 = new Account(Name='Test Account');
      insert a1;
            
      User u1 = createUser();
      insert u1;
      
      Case HRO = createCase(RecordTypeHelper.getRecordType('Service Onboarding HRO Case Record Type','Case').getRecordTypeId(), a1.Id,u1.Id);
      insert HRO;
         
      //Set the current page to the account we are testing
      ApexPages.currentPage().getParameters().put('Id',a1.Id);   

      //Create the controller
      OnboardingOverViewController oov = new OnboardingOverViewController(new ApexPages.StandardController(a1));
      
      Reference_HRO__c rfHRO =  [Select Id, Current_Step__c, Name, Owner.Name, Owner.Phone from Reference_HRO__c where Case_Number__c=:HRO.Id];
      System.assertEquals(rfHRO.Current_Step__c, oov.singleRefCollection[0].status);
      System.assertEquals(rfHRO.Id, oov.singleRefCollection[0].id);
      System.assertEquals(rfHRO.Name, oov.singleRefCollection[0].refName);
      System.assertEquals(rfHRO.Owner.Name, oov.singleRefCollection[0].ownerName);
      System.assertEquals(rfHRO.Owner.Phone, oov.singleRefCollection[0].ownerPhone);
     
      oov.singleRefCollection[0].openTimeline();
      system.assert(oov.singleRefCollection[0].showTimeLine);
      
      //Change the current step or status of the reference object or case
      rfHRO.Current_Step__c = 'Completed'; 
      update rfHRO;

      //Create a second controller
      OnboardingOverViewController oov2 = new OnboardingOverViewController(a1.Id);

      //Assert the boolean values for the render attributes are correct for the new controller
      System.assertEquals(rfHRO.Current_Step__c, oov2.singleRefGradCollection[0].status);
      System.assertEquals(rfHRO.Id, oov2.singleRefGradCollection[0].id);
      System.assertEquals(rfHRO.Name, oov2.singleRefGradCollection[0].refName);
      System.assertEquals(rfHRO.Owner.Name, oov2.singleRefGradCollection[0].ownerName);
      System.assertEquals(rfHRO.Owner.Phone, oov2.singleRefGradCollection[0].ownerPhone);

  }

 static testMethod void testCaseOnly() {
      Client_Overview_Configuration__c coc = new Client_Overview_Configuration__c(Name='Preview' 
      																			  ,Product_Name__c='Preview'
                                                                                  ,Reference_Object_Relationship_API_Name__c=''
                                                                                  ,Completed_Onboarding_Status__c='Completed'
                                                                                  ,Case_Record_Type_Name__c='Service Onboarding MMS Payroll Case'
                                                                                  ,Owner_Custom_Label__c='Preview Specialist'
                                                                                  ,OnboardingPOC_api__c='Owner'
                                                                                  ,Case_Only__c=TRUE);
      insert coc;
           
      Account a1 = new Account(Name='Test Account');
      insert a1;
           
      User u1 = createUser();
      insert u1;
     Case Preview = createCase(RecordTypeHelper.getRecordType('Service Onboarding MMS Payroll Case','Case').getRecordTypeId(), a1.Id, u1.Id);
     insert Preview;     

      
      //Set the current page to the account we are testing
      ApexPages.currentPage().getParameters().put('Id',a1.Id);   
      //Create the controller
      OnboardingOverViewController oov = new OnboardingOverViewController(new ApexPages.StandardController(a1));

      Case rfPreview =  [Select Id, Status, CaseNumber, Owner.Name, Owner.Phone from Case where ID=:Preview.Id];
      System.assertEquals(rfPreview.Status, oov.singleRefCollection[0].status);
      System.assertEquals(rfPreview.Id, oov.singleRefCollection[0].id);
      System.assertEquals(rfPreview.CaseNumber, oov.singleRefCollection[0].refName);
      System.assertEquals(rfPreview.Owner.Name, oov.singleRefCollection[0].ownerName);
      System.assertEquals(rfPreview.Owner.Phone, oov.singleRefCollection[0].ownerPhone);

      //Change the current step or status of the reference object or case
      rfPreview.Status = 'Completed';     
      update rfPreview;
 
      //Create a second controller
      OnboardingOverViewController oov2 = new OnboardingOverViewController(a1.Id);

      //Assert the boolean values for the render attributes are correct for the new controller
      System.assertEquals(rfPreview.Status, oov2.singleRefGradCollection[0].status);
      System.assertEquals(rfPreview.Id, oov2.singleRefGradCollection[0].id);
      System.assertEquals(rfPreview.CaseNumber, oov2.singleRefGradCollection[0].refName);
      System.assertEquals(rfPreview.Owner.Name, oov2.singleRefGradCollection[0].ownerName);
      System.assertEquals(rfPreview.Owner.Phone, oov2.singleRefGradCollection[0].ownerPhone);    
  }
  private static Case createCase(Id recordTypeId, Id accountId, Id owner_Id) {
       Case c = new Case(RecordTypeId=recordTypeId, AccountId=accountId,OwnerId=owner_Id);
       return c;
    } // createCase
    
  private static User createUser(){
       Profile stdUsrProfile = [select id from profile where name='Standard User'];  
       User u1 = new User (lastName='Test1', firstName='Test', Phone='(555)555-5555',Sales_Org__c='Core',
         alias = 'stdUser9', email='stdUser999229@stdUser992299.com',   
         emailencodingkey='UTF-8', languagelocalekey='en_US',   
         localesidkey='en_US', profileid = stdUsrProfile.Id,   
         timezonesidkey='America/Indiana/Indianapolis', username='stdUser999922@stdUser999922.com');
       return u1;
    } //createUser
   
}