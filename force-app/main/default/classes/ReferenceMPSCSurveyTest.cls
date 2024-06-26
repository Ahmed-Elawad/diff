/* 
 * 01/24/2018 Frank Lurz            Created
   01/23/2019 Dan Carmen            Added TRIGGERS_RAN variable

 */
 @isTest
private class ReferenceMPSCSurveyTest {

    static testMethod void testMPSCsurvey() {
       List<user> newUsers = new List<User>(); 
       List<Contact> newContacts = new List<Contact>();
        
       Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
       User u1 = new User(Alias = 'mickey', Email='mickeymouse@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Mouse', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Sales_Org__c = 'PAY',
            TimeZoneSidKey='America/Los_Angeles', UserName='mickeymouse@testorg.com');
       newUsers.add(u1);
       User u2 = new User(Alias = 'donald', Email='donaldduck@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Duck', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Sales_Org__c = 'PAY',
            TimeZoneSidKey='America/Los_Angeles', UserName='donaldduck@testorg.com');
       newUsers.add(u2);
       User u3 = new User(Alias = 'goofy', Email='goofy@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Goofy', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Sales_Org__c = 'PAY',
            TimeZoneSidKey='America/Los_Angeles', UserName='goofy@testorg.com');
       newUsers.add(u3);
       User u4 = new User(Alias = 'daisy', Email='daisyduck@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Duck', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Sales_Org__c = 'PAY',
            TimeZoneSidKey='America/Los_Angeles', UserName='daisyduck@testorg.com');
       newUsers.add(u4);
       User u5 = new User(Alias = 'pluto', Email='pluto@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Pluto', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Sales_Org__c = 'PAY',
            TimeZoneSidKey='America/Los_Angeles', UserName='pluto@testorg.com');
       newUsers.add(u5);
       insert newUsers;
        
       Account acct1 = new Account (name = 'Paychex Inc SA'
                                   ,OwnerId = u1.id); 
       insert acct1;
   
       Contact con1 = new Contact(Firstname = 'Contact1'
                               ,Lastname = 'Black'
                               ,AccountId = acct1.Id
                               ,User_lookup__c = u1.id);
       newContacts.add(con1);
       Contact con2 = new Contact(Firstname = 'Contact2'
                               ,Lastname = 'Smith'
                               ,AccountId = acct1.Id
                               ,User_lookup__c = u2.id);
       newContacts.add(con2);
       insert newContacts;
       Account acct2 = new Account (name = 'Test Account'
                               ,OwnerId = u1.id                            //Sales Rep
                               ,HRO_Implementation_Coordinator__c = u1.id  //Flex HR IS
                               ,TLO_Implementation_Coordinator__c = u2.id  //TAA IS
                               ,Paychex_Payroll_Specialist__c = con1.id    //Payroll BSR
                               //,Time_Attendance_AS__c = u4.id              //TAA BSR
                               //,HRO_Advisor__c = u5.id                     //Flex HR BSR
                               ,MMS_MAM_NAM__c = con2.id);//contact        //SIPM/IPM
       insert acct2;

       //MPSC Onboarding Case is the parent case of the MPSC Transfer case
       //The owner of this case is the Payroll IS on the Reference MPSC record
       Id mpscOnboardingCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Onboarding MPSC Core Payroll Case').getRecordTypeId();
       Case mpscOnboardingCase = new Case (recordtypeId = mpscOnboardingCaseRT
                                ,AccountId = acct2.id
                                ,OwnerId = u5.id);                  
       insert mpscOnboardingCase;
        
       //MPSC Transfer Case
       Id mpscTransferCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('MPSC Transfer Case').getRecordTypeId();
       Case mpscTransferCase = new Case (recordtypeId = mpscTransferCaseRT
                               ,AccountId = acct2.id
                               ,Status = 'Completed'
                               ,Origin = 'Manual Entry'
                               ,Subject = 'MPSC Transfer TEST Case'
                               ,ParentId = mpscOnboardingCase.id);                 
       insert mpscTransferCase;
        
       Id mpscTransfer = Schema.SObjectType.Reference_MPSC__c.getRecordTypeInfosByName().get('Reference MPSC Transfer').getRecordTypeId();
       Reference_MPSC__c mpsc = new Reference_MPSC__c(recordtypeId = mpscTransfer
                                                     ,Case_Lookup__c = mpscTransferCase.id
                                                     ,Prospect_Client__c = acct2.id
                                                     ,C2C__c = 'No');
       insert mpsc;    

       ReferenceMPSC.TRIGGERS_RAN = false;
       //Test.startTest();
       mpsc.Send_Survey__c = true;
       update mpsc;
       //Test.stopTest();
       
       ////list<feedItem> refMFIList = [Select Id, Body from feedItem where parentId = :mpsc.id];
       ////system.assert(!refMFIList.isEmpty());

       Reference_MPSC__c mpscT1 = new Reference_MPSC__c (recordtypeId = mpscTransfer);
       mpscT1 = [Select Id, Name, Survey_Status__c from Reference_MPSC__c where Id = :mpsc.id];
       System.assertEquals('Survey Sent', mpscT1.Survey_Status__c);


       //checking the code that prevents a sent survey from a child Reference MPSC record
       Test.startTest();
       Reference_MPSC__c mpsc2 = new Reference_MPSC__c(recordtypeId = mpscTransfer
                                                     ,Case_Lookup__c = mpscTransferCase.id
                                                     ,Prospect_Client__c = acct2.id);
       insert mpsc2;    

       Case mpscTransferCase3 = new Case (recordtypeId = mpscTransferCaseRT
                               ,AccountId = acct2.id
                               ,Status = 'In Progress'
                               ,Origin = 'Manual Entry'
                               ,Subject = 'MPSC Transfer TEST Case'
                               ,ParentId = mpscOnboardingCase.id);                 
       insert mpscTransferCase3;

       Reference_MPSC__c mpsc3 = new Reference_MPSC__c(recordtypeId = mpscTransfer
                                                     ,Case_Lookup__c = mpscTransferCase3.id
                                                     ,Reference_MPSC_Parent__c = mpsc2.id
                                                     ,Prospect_Client__c = acct2.id);
       insert mpsc3; 
       
       mpsc3.Send_Survey__c = true;
       update mpsc3;

       Reference_MPSC__c mpscT2 = new Reference_MPSC__c (recordtypeId = mpscTransfer);
       mpscT2 = [Select Id, Name, Survey_Status__c from Reference_MPSC__c where Id = :mpsc3.id];
       System.assertEquals(null, mpscT2.Survey_Status__c);
       Test.stopTest();


       /***
       try {
           mpsc2.Send_Survey__c = true;
           update mpsc2;
           System.assert(false, 'Exception expected');
       } catch (DMLException e) {
           System.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, You cannot submit a Survey for this record. There are related Reference MPSC records that are not Completed.: []'), 'message=' + e.getMessage());
       }     
       ***/



    
    }//end testMethod

}