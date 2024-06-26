/* 
 * The test methods for the RefDiscrepancyHelper and associated controller classes.
 *
 * History
 * -------
 * 04/19/2013 Dan Carmen        Created from RefPEODiscrepancyControllerTest
   10/22/2013 Dan Carmen        Added ASO discrepancies.
   11/06/2015 Frank Lurz        Added PEO discrepancies test for HRG and/or Sales Rep
   05/08/2018 Dan Carmen        Adjust test to account for additional users (FSS) on a user record when testing discrepancies
   07/08/2019 Dan Carmen        Change for Core Sales profile move
   09/03/2019 Dan Carmen        Fix query to select core sales reps
   10/28/2019 Brandon Vidro     Added fields to testGetFieldLabel 
 
 */
@isTest
private class RefDiscrepancyHelperTest {

   // Test without a reference object id passed in.
   static testMethod void testNoRefPeoObject() {
      Test.SetCurrentPageReference(Page.ReferencePEODiscrepancy);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new Reference_PEO__c());
      RefPEODiscrepancyController rpdc = new RefPEODiscrepancyController(sc1);
      // verify an error message was returned
      System.assertEquals(true,ApexPages.hasMessages());
      System.assertEquals(false,rpdc.hasRef);
   } // testNoRefPeoObject

   // Test with a reference object, but no discrepancies. 
   static testMethod void testNoRefPeoDiscrepencies() {
        // create reference
      Reference_PEO__c refPEO = new Reference_PEO__c();
      insert refPEO;
      Test.SetCurrentPageReference(Page.ReferencePEODiscrepancy);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(refPEO);
      System.CurrentPageReference().getParameters().put('id',refPEO.Id);
      RefPEODiscrepancyController rpdc = new RefPEODiscrepancyController(sc1);
      // verify an error message was returned
      System.assertEquals(true,ApexPages.hasMessages());
      System.assertEquals(false,rpdc.hasRef);
   } // testNoRefPeoDiscrepencies
   
   // Test with a reference object deleted - to get the exception. 
   static testMethod void testRefPeoDeleted() {
        // create reference
      Reference_PEO__c refPEO = new Reference_PEO__c();
      insert refPEO;
      Id refPeoId = refPEO.Id;
      delete refPEO;
      Test.SetCurrentPageReference(Page.ReferencePEODiscrepancy);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(refPEO);
      System.CurrentPageReference().getParameters().put('id',refPeoId);
      RefPEODiscrepancyController rpdc = new RefPEODiscrepancyController(sc1);
      // verify an error message was returned
      System.assertEquals(true,ApexPages.hasMessages());
      System.assertEquals(false,rpdc.hasRef);
   } // testRefPeoDeleted
  
   // Test with a reference object with open discrepancies. Attach to Account/Contact.
   static testMethod void testOpenRefPeoDiscrepencies() {
        // select a user that has a manager
        User rep = [Select Id, Name from User where ManagerId != null and IsActive=true and Manager.IsActive=true limit 1];
      Account a1 = new Account(Name='Test Account', ownerId=rep.Id,AccountNumber='17-A123');
      // create one of these accounts just in case
      Account a2 = new Account(Name='Paychex Inc SA');
      Account[] accts = new Account[]{a1,a2};
      insert accts;
      
      Contact c1 = new Contact(FirstName='Test',LastName='Contact',AccountId=a1.Id, OwnerId=rep.Id);
      Contact c2 = new Contact(FirstName='Test',LastName='Employee',Email='test@test.com', AccountId=a2.Id);
      Contact[] ctcts = new Contact[]{c1,c2};
      insert ctcts;
      
      // select a user that is an HRG
      User userHRG1 = [Select Id, Name, Email from User where Profile.Name = '2008-09 HRS Premier Support Rep' and IsActive=true and Email != null limit 1];
      
        Opportunity o1 = new Opportunity(CloseDate=Date.today().addDays(7), StageName='Pending', AccountId = a1.Id, OwnerId=rep.Id, Name='Test Opportunity');
        Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO, 'Opportunity');
        o1.RecordTypeId = rt.getRecordTypeId();
        insert o1;
        OpportunityContactRole ocr = new OpportunityContactRole(ContactId = c1.Id, OpportunityId=o1.Id, isPrimary=true);
        insert ocr;
        
        o1.HR_Solutions_PEO__c = true;
        o1.StageName = 'Sold';
        o1.Service_Location__c = OpportunityCreateCase.PEO_SERVICE_CENTER;
        update o1;
        // case and reference object should be created.
        Reference_PEO__c refPEO = [Select Id, Name from Reference_PEO__c where Opportunity__c = :o1.Id];
        // put an account number on the reference object for the email
        refPEO.Branch_Client_Number__c='17-A234';
       refPEO.Onbrdg_Spreadsheet_Rec_Target__c = date.today();
        update refPEO;
        
      // create discrepancies
      Reference_PEO_Discrepancy__c disc1 = new Reference_PEO_Discrepancy__c();
      disc1.Reference_PEO__c = refPEO.Id;
      disc1.Discrepancy_Area__c = 'Test1';
      disc1.Discrepancy_Type__c = 'Test Type 1';
      disc1.Discrepancy_Sub_Type__c = 'Test Sub Type 1';
      disc1.HoldPayrollWillNotRun__c = true;
      disc1.NonHoldPayrollWillRun__c = true;
      disc1.Additional_Information__c = 'This is additional information';

      Reference_PEO_Discrepancy__c disc2 = new Reference_PEO_Discrepancy__c();
      disc2.Reference_PEO__c = refPEO.Id;
      disc2.Discrepancy_Area__c = 'Test2';
      disc2.Discrepancy_Type__c = 'Test Type 2';
      disc2.Discrepancy_Sub_Type__c = 'Test Sub Type 2';
      disc2.HoldPayrollWillNotRun__c = false;
      disc2.NonHoldPayrollWillRun__c = false;
      disc2.Additional_Information__c = 'This is more additional information';
      Reference_PEO_Discrepancy__c[] discs = new Reference_PEO_Discrepancy__c[]{disc1,disc2};
      insert discs;
      
      Test.SetCurrentPageReference(Page.ReferencePEODiscrepancy);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(refPEO);
      System.CurrentPageReference().getParameters().put('id',refPEO.Id);
      RefPEODiscrepancyController rpdc = new RefPEODiscrepancyController(sc1);
      // verify no errors
      System.assertEquals(false,ApexPages.hasMessages());
      System.assertEquals(true,rpdc.hasRef);
      
      System.assertEquals(false,rpdc.onlyOneDiscRecord);
      System.assertEquals(false,rpdc.onlyOneUserRecord);
      
      // should be at least two users - rep and dsm
      System.assertEquals(true,rpdc.users.size() >= 2);
      
      // deselect the users
      for (Integer cnt=0; cnt<rpdc.users.size(); cnt++) {
         rpdc.users[cnt].selected=false;
      }
      
      // attempt to send mail - will error
      PageReference pr = rpdc.sendEmail();
      System.assertEquals(null,pr);
      
      // select users again
      for (Integer cnt=0; cnt<rpdc.users.size(); cnt++) {
         rpdc.users[cnt].selected=true;
      }
      
      // add a Contact
      rpdc.addlNames[0].Contact_Paychex_Emp__c = c2.Id;
      
      pr = rpdc.sendEmail();
      System.assertEquals(true,pr.getUrl().contains(refPEO.Id));
      
   } // testOpenRefPeoDiscrepencies

   // Test with a reference object with open discrepancies and has an assigned HRG and Sales Rep
   static testMethod void testOpenRefPeoDiscrepHRGandSR() { 

      User rep = [Select Id, Name from User where ManagerId != null and IsActive=true and Manager.IsActive=true limit 1];
      Account a1 = new Account(Name='Test Account', ownerId=rep.Id,AccountNumber='17-A123');
      Account a2 = new Account(Name='Paychex Inc SA');
      Account[] accts = new Account[]{a1};
      insert accts;
      
      Contact c2 = new Contact(FirstName='Test',LastName='Employee',Email='test@test.com', AccountId=a2.Id);
      Contact[] ctcts = new Contact[]{c2};
      insert ctcts;
      
      Reference_PEO__c refPEO2 = new Reference_PEO__c();
      refPEO2.Onbrdg_Spreadsheet_Rec_Target__c = date.today();
      insert refPEO2;
      Id refPeoId2 = refPEO2.Id;

      User userHRG2 = [Select Id, Name, Email from User where Profile.Name = '2008-09 HRS Premier Support Rep' and IsActive=true and Email != null limit 1];
      User userSalesRep2 = [Select Id, Name, Email from User where Profile.Name in :Utilities.CORE_PROFS and IsActive=true and Email != null limit 1];

      refPEO2.HRG__c = userHRG2.Id;
      refPEO2.Sales_Rep__c = userSalesRep2.Id;
      refPEO2.Account_Lookup__c = a1.Id;
      update refPEO2;


      // create discrepancies
      Reference_PEO_Discrepancy__c disc11 = new Reference_PEO_Discrepancy__c();
      disc11.Reference_PEO__c = refPEO2.Id;
      disc11.Discrepancy_Area__c = 'Test11';
      disc11.Discrepancy_Type__c = 'Test Type 11';
      disc11.Discrepancy_Sub_Type__c = 'Test Sub Type 11';
      disc11.HoldPayrollWillNotRun__c = true;
      disc11.NonHoldPayrollWillRun__c = true;
      disc11.Additional_Information__c = 'This is additional information';

      Reference_PEO_Discrepancy__c disc12 = new Reference_PEO_Discrepancy__c();
      disc12.Reference_PEO__c = refPEO2.Id;
      disc12.Discrepancy_Area__c = 'Test12';
      disc12.Discrepancy_Type__c = 'Test Type 12';
      disc12.Discrepancy_Sub_Type__c = 'Test Sub Type 12';
      disc12.HoldPayrollWillNotRun__c = false;
      disc12.NonHoldPayrollWillRun__c = false;
      disc12.Additional_Information__c = 'This is more additional information';
      Reference_PEO_Discrepancy__c[] discs = new Reference_PEO_Discrepancy__c[]{disc11,disc12};
      insert discs;
     
      Test.SetCurrentPageReference(Page.ReferencePEODiscrepancy);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(refPEO2);
      System.CurrentPageReference().getParameters().put('id',refPEO2.Id);
      RefPEODiscrepancyController rpdc = new RefPEODiscrepancyController(sc1);
     
      PageReference pr1 = rpdc.sendEmail();
      
      // select both users
      rpdc.users[0].selected=true;
      //rpdc.users[1].selected=true;
      
      // add a Contact
      rpdc.addlNames[0].Contact_Paychex_Emp__c = c2.Id;
      
      pr1 = rpdc.sendEmail();
      System.assertEquals(true,pr1.getUrl().contains(refPEO2.Id));

    } // testOpenRefPeoDiscrepHRGandSR


    // Test with a reference object with open discrepancies and has an assigned HRG and Sales Rep
    // commented out this test as they dont want to show HRG on descrepancy page anylonger
   /*static testMethod void testOpenRefPeoDiscrepJustHRG() { 

      User rep = [Select Id, Name from User where ManagerId != null and IsActive=true and Manager.IsActive=true limit 1];
      Account a3 = new Account(Name='Test Account', ownerId=rep.Id,AccountNumber='17-A123');
      Account[] accts = new Account[]{a3};
      insert accts;
      
      Contact c3 = new Contact(FirstName='Test',LastName='Employee',Email='test@test.com', AccountId=a3.Id);
      Contact[] ctcts = new Contact[]{c3};
      insert ctcts;
      
      Reference_PEO__c refPEO3 = new Reference_PEO__c();
       refPEO3.Onbrdg_Spreadsheet_Rec_Target__c = date.today();
      insert refPEO3;
      Id refPeoId3 = refPEO3.Id;

      User userHRG3 = [Select Id, Name, Email from User where Profile.Name = '2008-09 HRS Premier Support Rep' and IsActive=true and Email != null limit 1];
      User userAM3 = [Select Id, Name, Email from User where Profile.Name = '2008-09 HRS Premier Support Manager' and IsActive=true and Email != null limit 1];

      refPEO3.HRG__c = userHRG3.Id;
      refPEO3.Area_Manager__c = userAM3.Id;
      refPEO3.Account_Lookup__c = a3.Id;
      update refPEO3;


      // create discrepancies
      Reference_PEO_Discrepancy__c disc31 = new Reference_PEO_Discrepancy__c();
      disc31.Reference_PEO__c = refPEO3.Id;
      disc31.Discrepancy_Area__c = 'Test31';
      disc31.Discrepancy_Type__c = 'Test Type 31';
      disc31.Discrepancy_Sub_Type__c = 'Test Sub Type 31';
      disc31.HoldPayrollWillNotRun__c = true;
      disc31.NonHoldPayrollWillRun__c = true;
      disc31.Additional_Information__c = 'This is additional information';

      Reference_PEO_Discrepancy__c disc32 = new Reference_PEO_Discrepancy__c();
      disc32.Reference_PEO__c = refPEO3.Id;
      disc32.Discrepancy_Area__c = 'Test32';
      disc32.Discrepancy_Type__c = 'Test Type 32';
      disc32.Discrepancy_Sub_Type__c = 'Test Sub Type 32';
      disc32.HoldPayrollWillNotRun__c = false;
      disc32.NonHoldPayrollWillRun__c = false;
      disc32.Additional_Information__c = 'This is more additional information';
      Reference_PEO_Discrepancy__c[] discs = new Reference_PEO_Discrepancy__c[]{disc31,disc32};
      insert discs;
     
      Test.SetCurrentPageReference(Page.ReferencePEODiscrepancy);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(refPEO3);
      System.CurrentPageReference().getParameters().put('id',refPEO3.Id);
      RefPEODiscrepancyController rpdc = new RefPEODiscrepancyController(sc1);
     
      PageReference pr1 = rpdc.sendEmail();
      
      // select both users
      rpdc.users[0].selected=true;
      rpdc.users[1].selected=true;
      
      // add a Contact
      rpdc.addlNames[0].Contact_Paychex_Emp__c = c3.Id;
      
      pr1 = rpdc.sendEmail();
      System.assertEquals(true,pr1.getUrl().contains(refPEO3.Id));

    } // testOpenRefPeoDiscrepJustHRG*/



    // Test with a reference object with open discrepancies and has an assigned HRG and Sales Rep
    // commented out this test as they dont want to show HRG or AM on descrepancy page anylonger
   /*static testMethod void testOpenRefPeoDiscrepNoHRGorSalesRep() { 

      User rep = [Select Id, Name from User where ManagerId != null and IsActive=true and Manager.IsActive=true limit 1];
      Account a4 = new Account(Name='Test Account', ownerId=rep.Id,AccountNumber='17-A123');
      Account[] accts = new Account[]{a4};
      insert accts;
      
      Contact c4 = new Contact(FirstName='Test',LastName='Employee',Email='test@test.com', AccountId=a4.Id);
      Contact[] ctcts = new Contact[]{c4};
      insert ctcts;
      
      Reference_PEO__c refPEO4 = new Reference_PEO__c();
       refPEO4.Onbrdg_Spreadsheet_Rec_Target__c = date.today();
      insert refPEO4;
      Id refPeoId3 = refPEO4.Id;

      //User userHRG3 = [Select Id, Name, Email from User where Profile.Name = '2008-09 HRS Premier Support Rep' and IsActive=true and Email != null limit 1];
      //User userAM4 = [Select Id, Name, Email from User where Profile.Name = '2008-09 HRS Premier Support Manager' and IsActive=true and Email != null limit 1];

      //refPEO4.HRG__c = userHRG3.Id;
      //refPEO4.Area_Manager__c = userAM4.Id;
      refPEO4.Account_Lookup__c = a4.Id;
      update refPEO4;


      // create discrepancies
      Reference_PEO_Discrepancy__c disc41 = new Reference_PEO_Discrepancy__c();
      disc41.Reference_PEO__c = refPEO4.Id;
      disc41.Discrepancy_Area__c = 'Test41';
      disc41.Discrepancy_Type__c = 'Test Type 41';
      disc41.Discrepancy_Sub_Type__c = 'Test Sub Type 41';
      disc41.HoldPayrollWillNotRun__c = true;
      disc41.NonHoldPayrollWillRun__c = true;
      disc41.Additional_Information__c = 'This is additional information';

      Reference_PEO_Discrepancy__c disc42 = new Reference_PEO_Discrepancy__c();
      disc42.Reference_PEO__c = refPEO4.Id;
      disc42.Discrepancy_Area__c = 'Test42';
      disc42.Discrepancy_Type__c = 'Test Type 42';
      disc42.Discrepancy_Sub_Type__c = 'Test Sub Type 42';
      disc42.HoldPayrollWillNotRun__c = false;
      disc42.NonHoldPayrollWillRun__c = false;
      disc42.Additional_Information__c = 'This is more additional information';
      Reference_PEO_Discrepancy__c[] discs = new Reference_PEO_Discrepancy__c[]{disc41,disc42};
      insert discs;
     
      Test.SetCurrentPageReference(Page.ReferencePEODiscrepancy);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(refPEO4);
      System.CurrentPageReference().getParameters().put('id',refPEO4.Id);
      RefPEODiscrepancyController rpdc = new RefPEODiscrepancyController(sc1);
     
      PageReference pr1 = rpdc.sendEmail();
      
      // select both users
      rpdc.users[0].selected=true;
      //rpdc.users[1].selected=true;
      
      // add a Contact
      rpdc.addlNames[0].Contact_Paychex_Emp__c = c4.Id;
      
      pr1 = rpdc.sendEmail();
      System.assertEquals(true,pr1.getUrl().contains(refPEO4.Id));

    } // testOpenRefPeoDiscrepNoHRGorSalesRep*/



   static testMethod void testGetFieldLabel() {
      Test.SetCurrentPageReference(Page.ReferencePEODiscrepancy);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new Reference_PEO__c());
      //System.CurrentPageReference().getParameters().put('id',refPEO.Id);
      RefPEODiscrepancyController rpdc = new RefPEODiscrepancyController(sc1);
      System.assertEquals(rpdc.getFieldLabel('Area_Manager__c'),'Area Manager');
      System.assertEquals(rpdc.getFieldLabel('Benefits_Specialist__c'),'Benefits Specialist');
      System.assertEquals(rpdc.getFieldLabel('Contractual_Specialist__c'),'Contractual Specialist');
      System.assertEquals(rpdc.getFieldLabel('Onboarding_Specialist__c'), 'Onboarding Specialist');
      System.assertEquals(rpdc.getFieldLabel('PEO_Sales_Analyst__c'), 'PEO Sales Analyst');
      System.assertEquals(rpdc.getFieldLabel('Sales_Analyst_1__c'), 'Sales Analyst');
      System.assertEquals(rpdc.getFieldLabel('PEO_HRC__c'), 'PEO+ HRBP');
      System.assertEquals(rpdc.getFieldLabel('Onboarding_HRG__c'), 'Onboarding HRG');
      System.assertEquals(rpdc.getFieldLabel('Implementation_Project_Manager__c'), 'Implementation Project Manager');
      System.assertEquals(rpdc.getFieldLabel('DSM__c'),'DSM');
      System.assertEquals(rpdc.getFieldLabel('FSS__c'),'FSS');
      System.assertEquals(rpdc.getFieldLabel('HRG__c'),'HRG');
      System.assertEquals(rpdc.getFieldLabel('National_HRG__c'),'National HRG');
      System.assertEquals(rpdc.getFieldLabel('National_Sales_Rep__c'),'National Sales Consultant');
      System.assertEquals(rpdc.getFieldLabel('NCS_Benefits_Specialist__c'),'Benefits NCS');
      System.assertEquals(rpdc.getFieldLabel('NCS_Payroll_Specialist__c'),'Payroll NCS');
      System.assertEquals(rpdc.getFieldLabel('Payroll_Specialist__c'),'Payroll Specialist');
      System.assertEquals(rpdc.getFieldLabel('Sales_Rep__c'),'Sales Rep');
      System.assertEquals(rpdc.getFieldLabel('Handbook_Setup_Specialist__c'),'Handbook Setup Specialist');
      System.assertEquals(rpdc.getFieldLabel('HR_Specialist__c'),'HR Specialist');
      System.assertEquals(rpdc.getFieldLabel('Responsible_HRG__c'),'Responsible HRG');
      
   } // testGetFieldLabel
   
   // Test without a reference object id passed in.
   static testMethod void testNoRefHreObject() {
      Test.SetCurrentPageReference(Page.ReferenceHREDiscrepancy);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new Reference_HRE_CHB_Onboarding__c());
      //System.CurrentPageReference().getParameters().put('licenseId',ul3.Id);
      RefHreDiscrepancyController rpdc = new RefHreDiscrepancyController(sc1);
      // verify an error message was returned
      System.assertEquals(true,ApexPages.hasMessages());
      System.assertEquals(false,rpdc.hasRef);
   } // testNoRefHreObject

   // Test with a reference object, but no discrepancies.
   static testMethod void testNoRefHreDiscrepencies() {
        // create reference
      Reference_HRE_CHB_Onboarding__c refHre = new Reference_HRE_CHB_Onboarding__c();
      insert refHre;
      Test.SetCurrentPageReference(Page.ReferenceHREDiscrepancy);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(refHre);
      System.CurrentPageReference().getParameters().put('id',refHre.Id);
      RefHreDiscrepancyController rpdc = new RefHreDiscrepancyController(sc1);
      // verify an error message was returned
      System.assertEquals(true,ApexPages.hasMessages());
      System.assertEquals(false,rpdc.hasRef);
   } // testNoRefHreDiscrepencies
   
   // Test with a reference object deleted - to get the exception.
   static testMethod void testRefHreDeleted() {
        // create reference
      Reference_HRE_CHB_Onboarding__c refHre = new Reference_HRE_CHB_Onboarding__c();
      insert refHre;
      Id refHreId = refHre.Id;
      delete refHre;
      Test.SetCurrentPageReference(Page.ReferenceHREDiscrepancy);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(refHre);
      System.CurrentPageReference().getParameters().put('id',refHreId);
      RefHreDiscrepancyController rpdc = new RefHreDiscrepancyController(sc1);
      // verify an error message was returned
      System.assertEquals(true,ApexPages.hasMessages());
      System.assertEquals(false,rpdc.hasRef);
   } // testRefHreDeleted
   
   // Test with a reference object with open discrepancies. Attach to Account/Contact.
   static testMethod void testOpenRefHreDiscrepencies() {
        // select a user that has a manager
        User rep = [Select Id, Name from User where ManagerId != null and IsActive=true and Manager.IsActive=true limit 1];
      Account a1 = new Account(Name='Test Account', ownerId=rep.Id,AccountNumber='17-A123');
      // create one of these accounts just in case
      Account a2 = new Account(Name='Paychex Inc SA');
      Account[] accts = new Account[]{a1,a2};
      insert accts;
      
      Contact c1 = new Contact(FirstName='Test',LastName='Contact',AccountId=a1.Id, OwnerId=rep.Id);
      Contact c2 = new Contact(FirstName='Test',LastName='Employee',Email='test@test.com', AccountId=a2.Id);
      Contact[] ctcts = new Contact[]{c1,c2};
      insert ctcts;
      
      // select users to attach to reference object
      User[] users = [Select Id, Name from User where IsActive=true limit 2];
      
      Reference_HRE_CHB_Onboarding__c refHre = new Reference_HRE_CHB_Onboarding__c(Account_Lookup__c=a1.Id);
      refHre.Sales_Rep__c = users[0].Id;
      refHre.FSS__c = users[1].Id;
      insert refHre;
        
      // create discrepancies
      Reference_HRE_CHB_Discrepancy__c disc1 = new Reference_HRE_CHB_Discrepancy__c();
      disc1.Reference_HR_Essentials__c = refHre.Id;
      disc1.Discrepancy_Type__c = 'Test Type 1';
      disc1.Discrepancy_Sub_Type__c = 'Test Sub Type 1';
      disc1.Additional_Information__c = 'This is additional information';

      Reference_HRE_CHB_Discrepancy__c disc2 = new Reference_HRE_CHB_Discrepancy__c();
      disc2.Reference_HR_Essentials__c = refHre.Id;
      disc2.Discrepancy_Type__c = 'Test Type 2';
      disc2.Discrepancy_Sub_Type__c = 'Test Sub Type 2';
      disc2.Additional_Information__c = 'This is more additional information';
      Reference_HRE_CHB_Discrepancy__c[] discs = new Reference_HRE_CHB_Discrepancy__c[]{disc1,disc2};
      insert discs;
      
      Test.SetCurrentPageReference(Page.ReferenceHreDiscrepancy);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(refHre);
      System.CurrentPageReference().getParameters().put('id',refHre.Id);
      RefHREDiscrepancyController rpdc = new RefHREDiscrepancyController(sc1);
      // verify no errors
      System.assertEquals(false,ApexPages.hasMessages());
      System.assertEquals(true,rpdc.hasRef);
      
      System.assertEquals(false,rpdc.onlyOneDiscRecord);
      System.assertEquals(false,rpdc.onlyOneUserRecord);
      
      // should be two users - rep and dsm
      System.assertEquals(2,rpdc.users.size());
      
      // deselect both users
      rpdc.users[0].selected=false;
      rpdc.users[1].selected=false;
      
      // attempt to send mail - will error
      PageReference pr = rpdc.sendEmail();
      System.assertEquals(null,pr);
      
      // select both users again
      rpdc.users[0].selected=true;
      rpdc.users[1].selected=true;
      
      // add a Contact
      rpdc.addlNames[0].Contact_Paychex_Emp__c = c2.Id;
      
      pr = rpdc.sendEmail();
      System.assertEquals(true,pr.getUrl().contains(refHre.Id));
      
   } // testOpenRefHreDiscrepencies

   // Test with a reference object with open discrepancies. Attach to Account/Contact.
   static testMethod void testOpenASODiscrepencies() {
      // select a user that has a manager
      User rep = [Select Id, Name from User where ManagerId != null and IsActive=true and Manager.IsActive=true limit 1];
      Account a1 = new Account(Name='Test Account', ownerId=rep.Id,AccountNumber='17-A123');
      // create one of these accounts just in case
      Account a2 = new Account(Name='Paychex Inc SA');
      Account[] accts = new Account[]{a1,a2};
      insert accts;
      
      Contact c1 = new Contact(FirstName='Test',LastName='Contact',AccountId=a1.Id, OwnerId=rep.Id);
      Contact c2 = new Contact(FirstName='Test',LastName='Employee',Email='test@test.com', AccountId=a2.Id);
      Contact[] ctcts = new Contact[]{c1,c2};
      insert ctcts;
      
      // select users to attach to reference object
      User[] users = [Select Id, Name from User where IsActive=true limit 2];
      
      Reference_ASO__c refAso = new Reference_ASO__c(Prospect_Client_Name__c=a1.Id);
      refAso.Sales_Rep__c = users[0].Id;
      refAso.FSS__c = users[1].Id;
      insert refAso;
      System.assertEquals(true,refAso.Id != null);
        
      // create discrepancies
      Reference_ASO_Discrepancy__c disc1 = new Reference_ASO_Discrepancy__c();
      disc1.Reference_ASO__c = refAso.Id;
      disc1.Discrepancy_Type__c = 'Test Type 1';
      disc1.Additional_Information__c = 'This is additional information';

      Reference_ASO_Discrepancy__c disc2 = new Reference_ASO_Discrepancy__c();
      disc2.Reference_ASO__c = refAso.Id;
      disc2.Discrepancy_Type__c = 'Test Type 2';
      disc2.Additional_Information__c = 'This is more additional information';
      Reference_ASO_Discrepancy__c[] discs = new Reference_ASO_Discrepancy__c[]{disc1,disc2};
      insert discs;
      
      Test.SetCurrentPageReference(Page.ReferenceASODiscrepancy);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(refAso);
      System.CurrentPageReference().getParameters().put('id',refAso.Id);
      RefASODiscrepancyController rpdc = new RefASODiscrepancyController(sc1);
      // verify no errors
      System.assertEquals(false,ApexPages.hasMessages());
      System.assertEquals(true,rpdc.hasRef);
      
      System.assertEquals(false,rpdc.onlyOneDiscRecord);
      System.assertEquals(false,rpdc.onlyOneUserRecord);
      
      // should be two users - rep and dsm
      System.assertEquals(2,rpdc.users.size());
      
      // deselect both users
      rpdc.users[0].selected=false;
      rpdc.users[1].selected=false;
      
      // attempt to send mail - will error
      PageReference pr = rpdc.sendEmail();
      System.assertEquals(null,pr);
      
      // select both users again
      rpdc.users[0].selected=true;
      rpdc.users[1].selected=true;
      
      // add a Contact
      rpdc.addlNames[0].Contact_Paychex_Emp__c = c2.Id;
      
      pr = rpdc.sendEmail();
      System.assertEquals(true,pr.getUrl().contains(refAso.Id));
      
   } // testOpenASODiscrepencies

} // class RefDiscrepancyHelperTest