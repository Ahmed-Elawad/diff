/*Test methods for the OnboardingOverViewController class.
 
  History
  -------
  08/19/2019 Jacob Hinds              Created
  07/24/2020 Jacob Hinds              Retired in place of service ○model type on account
  09/08/2020 Jacob Hinds      commenting back in
  04/29/2024 Dan Carmen       Make sure the onboarding status is not empty before clearing and saving it.

*/
@isTest
private class AccountOnboardingStatusTest {
    static testMethod void testMultipleAccounts() {
          
      Client_Overview_Configuration__c coc1 = new Client_Overview_Configuration__c(Name='HRO' 
                                              ,Product_Name__c='HRO'
                                                                                  ,Reference_Object_Relationship_API_Name__c='Reference_HROs__r'
                                                                                  ,Completed_Onboarding_Status__c='Completed'
                                                                                  ,Case_Record_Type_Name__c='Service Onboarding HRO Case Record Type'
                                                                                  ,Owner_Custom_Label__c='HRO Specialist'
                                                                                  ,Case_Only__c=FALSE);
      
      Client_Overview_Configuration__c coc2 = new Client_Overview_Configuration__c(Name='MSP' 
                                              ,Product_Name__c='MSP'
                                                                                  ,Reference_Object_Relationship_API_Name__c='Reference_HROs__r'
                                                                                  ,Completed_Onboarding_Status__c='Onboarding Complete'
                                                                                  ,Case_Record_Type_Name__c='Service Onboarding MSP Case Record Type'
                                                                                  ,Owner_Custom_Label__c='Service Team - MSP Specialist'
                                                                                  ,Reference_Object_Exp_Run_Date_api__c='Estimated_Go_Live_Date__c'
                                                                                  ,Case_Only__c=FALSE);
      Client_Overview_Configuration__c[] cocs = new Client_Overview_Configuration__c[]{coc1,coc2};
      insert cocs;                                                                            
      
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
      Client_Overview_Status_Info__c cosi3= new Client_Overview_Status_Info__c(Name='MSP 1'
                                                                         ,Key__c='MSP'
                                                                         ,Number__c=5
                                                                         ,DisplayText__c='Step 1'
                                                                         ,Status__c='(1 of 6) Welcome Call');
      Client_Overview_Status_Info__c cosi4= new Client_Overview_Status_Info__c(Name='MSP 2'
                                                                         ,Key__c='MSP'
                                                                         ,Number__c=10
                                                                         ,DisplayText__c='Step2'
                                                                         ,Status__c='Onboarding Complete');                                                                   
                                                                         
      Client_Overview_Status_Info__c[] cosis = new Client_Overview_Status_Info__c[]{cosi,cosi2,cosi3,cosi4};
      insert cosis;
      
      Object_Relationships__c objr = new Object_Relationships__c(Primary_Object_API_name__c='Case',
                                     Primary_Object_Rcd_Type__c=coc2.Case_Record_Type_Name__c,
                                     Related_Object_API_name__c='Reference_HRO__c',
                                     Related_Object_Rcd_Type__c='Service Onboarding MSP Ref Object',
                                     IsActive__c=true);
      insert objr;
                                     
      Object_Relationships_Fields__c field1 = new Object_Relationships_Fields__c(Object_Relationships__c=objr.Id,
                                             Primary_Field_API_name__c='Id',
                                             Primary_Object_API_name__c='Case',
                                             Related_Field_API_name__c='Case_Number__c',
                                             Related_Object_API_name__c='Reference_HRO__c');
      Object_Relationships_Fields__c field2 = new Object_Relationships_Fields__c(Object_Relationships__c=objr.Id,
                                             Primary_Field_API_name__c='Current_Step__c',
                                             Primary_Object_API_name__c='Case',
                                             Related_Field_API_name__c='Current_Step__c',
                                             Related_Object_API_name__c='Reference_HRO__c');    
      Object_Relationships_Fields__c field3 = new Object_Relationships_Fields__c(Object_Relationships__c=objr.Id,
                                             Primary_Field_API_name__c='Product__c',
                                             Primary_Object_API_name__c='Case',
                                             Related_Object_API_name__c='Reference_HRO__c',
                                             IsFilter__c=true,
                                             FilterCriteria__c='MSP');
      Object_Relationships_Fields__c[] objFields = new Object_Relationships_Fields__c[]{field1,field2,field3};
      insert objFields;                                                                          
      
      Account a1 = new Account(Name='Test Account');
      Account a2 = new Account(Name='Test Account2');
      Account[] accts = new Account[]{a1,a2};
      insert accts;
      
      Set<Id> acctIds = new Set<Id>();
      acctIds.add(a1.Id);
      acctIds.add(a2.Id);
      
      Test.StartTest();
      Case HRO = new Case(RecordTypeId=RecordTypeHelper.getRecordType(coc1.Case_Record_Type_Name__c,'Case').getRecordTypeId(),
                  AccountId=a1.Id,
                  OwnerId=UserInfo.getUserId());
      Case MSP = new Case(RecordTypeId=RecordTypeHelper.getRecordType(coc2.Case_Record_Type_Name__c,'Case').getRecordTypeId(),
                  AccountId=a2.Id,
                  OwnerId=UserInfo.getUserId(),
                  Product__c='MSP');
      Case[] cases = new Case[]{HRO,MSP};
      insert cases;
      //insert HRO;

      Reference_HRO__c[] rfHROs =  [Select Id, Current_Step__c, Name, Owner.Name, Owner.Phone,Case_Number__c,Case_Number__r.AccountId,Case_Number__r.Account.Client_Onboarding_Status__c 
                      from Reference_HRO__c where Case_Number__r.AccountId in :acctIds];
      Reference_HRO__c mspRef;                
      //system.assertEquals(2,rfHROs.size());
      for(Reference_HRO__c refHRO : rfHROs){
        system.assertEquals('In Progress',refHRO.Case_Number__r.Account.Client_Onboarding_Status__c);
        if(refHRO.Case_Number__c == MSP.Id){
          mspRef = refHRO;
        }
      }
      mspRef.Current_Step__c = 'Onboarding Complete';
      update mspRef;
      
      Account uAcct = [SELECT Id,Client_Onboarding_Status__c FROM Account WHERE Id =:mspRef.Case_Number__r.AccountId];
      system.assertEquals('Completed',uAcct.Client_Onboarding_Status__c);
      BannerDoNotProspectController bdnpc1 = new BannerDoNotProspectController(uAcct.Id);
      system.assertEquals(false,bdnpc1.onboardingInProgress);
      system.assertEquals(true,bdnpc1.onboardingComplete);
      BannerDoNotProspectController bdnpc2 = new BannerDoNotProspectController(a1.Id);
      system.assertEquals(true,bdnpc2.onboardingInProgress);
      system.assertEquals(false,bdnpc2.onboardingComplete);
      
      delete HRO;
      Account acctHro = [SELECT Id,Client_Onboarding_Status__c FROM Account where Id=:a1.Id];
      Assert.isNull(acctHro.Client_Onboarding_Status__c);
      Test.stopTest();
  } // testMultipleAccounts
    
} // class AccountOnboardingStatusTest