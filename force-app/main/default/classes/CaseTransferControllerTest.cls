/* 
 * Test methods for the CaseTransferController.
 *
 * History
 * -------
 * 03/21/2011 Dan Carmen        Created.
   06/23/2011 Dan Carmen        Additional testing for new copy field functionality.
   09/21/2011 Dan Carmen        Added ability to move attachments if present.
   01/16/2012 Cindy Freeman     Expanded ability to move attachments to reference object instead of to the case
   05/02/2012 John Callan       Added tests for defaulting the user transferred to.
   04/02/2013 Dan Carmen        Added logic to capture an error on newCase save
   08/28/2013 Dan Carmen        Modification to testCaseTransferSafetyRep so it won't fail because of data.
 *
 */
@isTest
private class CaseTransferControllerTest {

   /** Setup routing information to be used in the tests.
    */
   private static void setupTestRouting() {
      Case_Transfer_Routing__c[] routings = new Case_Transfer_Routing__c[]{};
      routings.add(new Case_Transfer_Routing__c(From_Record_Type_Name__c = 'COE Submission Case Record Type'
                                               ,From_Profiles__c = null
                                               ,Department__c= 'Test Dept 1'
                                               ,Sub_Department_Name__c = 'Test Sub Dept 1'
                                               ,Queue_Name__c='Test Queue 1'
                                               ,Allow_Transfer_to_User__c = true
                                               ,Record_Type_Name__c = 'COE Submission Case Record Type'));
      Case_Transfer_Routing__c testCrc = 
                   new Case_Transfer_Routing__c(From_Record_Type_Name__c = 'COE Submission Case Record Type'
                                               ,From_Profiles__c = 'System Administrator'
                                               ,Department__c= 'Test Dept 1'
                                               ,Sub_Department_Name__c = 'Test Sub Dept 2'
                                               ,Queue_Name__c=null
                                               ,Allow_Transfer_to_User__c = true
                                               ,Record_Type_Name__c = 'COE Submission Case Record Type');
      routings.add(testCrc);
      routings.add(new Case_Transfer_Routing__c(From_Record_Type_Name__c = 'COE Submission Case Record Type'
                                               ,From_Profiles__c = null
                                               ,Department__c= 'Test Dept 2'
                                               ,Sub_Department_Name__c = 'Test Sub Dept 3'
                                               ,Queue_Name__c='Test Queue 2'
                                               ,Allow_Transfer_to_User__c = false
                                               ,Record_Type_Name__c = 'COE Submission Case Record Type'));
      routings.add(new Case_Transfer_Routing__c(From_Record_Type_Name__c = 'COE Submission Case Record Type'
                                               ,From_Profiles__c = null
                                               ,Department__c= 'Test Dept 2'
                                               ,Sub_Department_Name__c = 'Test Sub Dept 4'
                                               ,Queue_Name__c=null
                                               ,Allow_Transfer_to_User__c = true
                                               ,Record_Type_Name__c = 'COE Submission Case Record Type'));
      routings.add(new Case_Transfer_Routing__c(From_Record_Type_Name__c = 'COE Submission Case Record Type'
                                               ,From_Profiles__c = 'This is to exclude all Profiles'
                                               ,Department__c= 'Test Dept 2'
                                               ,Sub_Department_Name__c = 'Test Sub Dept 4'
                                               ,Queue_Name__c=null
                                               ,Allow_Transfer_to_User__c = true
                                               ,Record_Type_Name__c = 'COE Submission Case Record Type'));
      routings.add(new Case_Transfer_Routing__c(From_Record_Type_Name__c = 'Sales Support Cases Record Type'
                                               ,From_Profiles__c = null
                                               ,Department__c= 'Test HRS'
                                               ,Sub_Department_Name__c = 'Test Sub Dept HRS'
                                               ,Queue_Name__c=null
                                               ,Allow_Transfer_to_User__c = true
                                               ,Record_Type_Name__c = 'Service Onboarding PEO New Business'
                                               ,Reference_Object_Name__c = 'Reference_PEO__c'
                                               ,Case_Lookup_field_name__c = 'Parent_Case__c'));
      routings.add(new Case_Transfer_Routing__c(From_Record_Type_Name__c = 'Service Premier Record Type'
                                               ,From_Profiles__c = null
                                               ,Department__c= 'Safety Initial Contact'
                                               ,Sub_Department_Name__c = 'Safety Initial Contact'
                                               ,Queue_Name__c=null
                                               ,Allow_Transfer_to_User__c = true
                                               ,Record_Type_Name__c = 'Service Support Premier Safety Case'
                                               ,Reference_Object_Name__c = null
                                               ,Case_Lookup_field_name__c = null
                                               ,Default_User_Transferred_to__c = 'Safety_Rep__c'));
     routings.add(new Case_Transfer_Routing__c(From_Record_Type_Name__c = 'Service Premier Record Type'
                                               ,From_Profiles__c = null
                                               ,Department__c= 'Test Owner Transfer'
                                               ,Sub_Department_Name__c = 'Test Owner Transfer'
                                               ,Queue_Name__c=null
                                               ,Allow_Transfer_to_User__c = true
                                               ,Record_Type_Name__c = 'Test Owner Transfer Rec Type'
                                               ,Reference_Object_Name__c = null
                                               ,Case_Lookup_field_name__c = null
                                               ,Default_User_Transferred_to__c = 'OwnerId'));
      insert routings;
      
      // insert a Queue record
      Group[] grps = new Group[]{};
      grps.add(new Group(Name='Test Queue 1',Type='Queue'));
      grps.add(new Group(Name='Test Queue 2',Type='Queue'));
      insert grps;
      // insert records for field copy
      Case_Transfer_Field_Copy__c[] ctfcs = new Case_Transfer_Field_Copy__c[]{};
      // put in a literal value
      ctfcs.add(new Case_Transfer_Field_Copy__c(Case_Transfer_Routing__c=testCrc.Id
                                               ,Dest_Field_API_Name__c='Justification__c'
                                               ,Dest_Field_Value__c='Test Justification'
                                               ,Source_Field_API_Name__c=null
                                               ,Source_Object_API_Name__c=null
                                                ));
      // copy from the existing case
      ctfcs.add(new Case_Transfer_Field_Copy__c(Case_Transfer_Routing__c=testCrc.Id
                                               ,Dest_Field_API_Name__c='Status_Description__c'
                                               ,Dest_Field_Value__c=null
                                               ,Source_Field_API_Name__c='Status_Description__c'
                                               ,Source_Object_API_Name__c='Case'
                                                ));
      insert ctfcs;
   } // setupTestRouting
   
   static testMethod void testNoCase() {
      Test.SetCurrentPageReference(Page.CaseTransfer);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new Case());
      //System.CurrentPageReference().getParameters().put('id',opp1.Id);
      CaseTransferController ctc = new CaseTransferController(sc1);
      System.assertEquals(null,ctc.curCase);
      System.assertEquals(false,ctc.hasCurCase);
      System.assertEquals(false,ctc.okayToTransfer);
      // should be an error message
      System.assertEquals(true,ApexPages.hasMessages());
      System.assertEquals(true,ApexPages.getMessages().get(0).getSummary().contains('No Case record was found!'));
   } // testNoCase
   
   static testMethod void testBadCaseId() {
      // create a case to obtain a valid id
      Case c = new Case(Subject='Test Case'
                          ,Description = 'This is the description for the test case');
      insert c;
      Id caseId = c.Id;
      // delete the case so it's not found and an exception occurs.
      delete c;
      
      Test.SetCurrentPageReference(Page.CaseTransfer);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new Case());
      System.CurrentPageReference().getParameters().put('id',caseId);
      CaseTransferController ctc = new CaseTransferController(sc1);
      System.assertEquals(null,ctc.curCase);
      System.assertEquals(false,ctc.hasCurCase);
      System.assertEquals(false,ctc.okayToTransfer);
      // should be an error message
      System.assertEquals(true,ApexPages.hasMessages());
      System.assertEquals(true,ApexPages.getMessages().get(0).getSummary().contains('No Case record was found!'));
   } // testNoCase
   
   
   static testMethod void testCaseNoRouting() {
      // get all of the record types for Case
      List<Schema.RecordTypeInfo> rts = RecordTypeHelper.getRecordTypes('Case');
      // get all of the existing routings
      Case_Transfer_Routing__c[] routings = [Select Id, From_Record_Type_Name__c from Case_Transfer_Routing__c];
      
      Schema.RecordTypeInfo notUsedRt = null;
      
      // find a record type not in the routing tables
      for (Schema.RecordTypeInfo rt : rts) {
         notUsedRt = rt;
         for (Case_Transfer_Routing__c ctr : routings) {
            if (ctr.From_Record_Type_Name__c == rt.getName()) {
               notUsedRt = null;
               break;
            }
         }
         if (notUsedRt != null) {
            break;
         }
      } // for
      
      // create a case using this record type
      Case c = new Case(RecordTypeId = notUsedRt.getRecordTypeId(), Subject='Test Case'
                          ,Description = 'This is the description for the test case');
      insert c;
      Test.SetCurrentPageReference(Page.CaseTransfer);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(c);
      System.CurrentPageReference().getParameters().put('id',c.Id);
      CaseTransferController ctc = new CaseTransferController(sc1);
      System.assertEquals(null,ctc.curCase);
      System.assertEquals(false,ctc.hasCurCase);
      System.assertEquals(false,ctc.okayToTransfer);
      // should be an error message
      System.assertEquals(true,ApexPages.hasMessages());
      System.assertEquals(true,ApexPages.getMessages().get(0).getSummary().contains('No Transfer options were setup'));
      
   } // testCaseNoRouting
   
   static testMethod void testCase1() {
      setupTestRouting();
      User u = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' limit 1];
      User u2 = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :u.Id limit 1];
      System.runAs(u) {
         Account a = new Account(Name = 'Test Account');
         insert a;
         Contact ctct = new Contact(FirstName = 'Jimmy', LastName = 'Test', AccountId = a.Id);
         insert ctct;
         Referral_Contact__c rc = new Referral_Contact__c(Name='Johnny Referral');
         insert rc;
         
         Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('COE Submission Case Record Type','Case');
         Case c = new Case(RecordTypeId = rt.getRecordTypeId(), Subject='Test Case'
                          ,Description = 'This is the description for the test case'
                          ,Status_Description__c = 'This is a status description'
                          ,AccountId = a.Id, ContactId = ctct.Id, Referral_Contact__c = rc.Id);
         insert c;
         // add an attachment
         Blob b = Blob.valueOf('This is a test');
         Attachment att = new Attachment(ParentId=c.Id, Name='Test.txt', Body=b);
         insert att;
         
         Test.SetCurrentPageReference(Page.CaseTransfer);
         ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(c);
         System.CurrentPageReference().getParameters().put('id',c.Id);
         CaseTransferController ctc = new CaseTransferController(sc1);
         
         // check for attachments
         System.assertEquals(true,ctc.hasAttachments);
         
         // should be at least 2 department transfers
         System.assertEquals(true,(ctc.departmentOptions.size() >= 2));
         // set to different group.
         ctc.departmentOption = 'Test Dept 1';
         PageReference pr = ctc.selectDepartment();
         System.assertEquals(null,pr);
         ctc.groupOption = 'Test Sub Dept 1';
         pr = ctc.selectGroup();
         System.assertEquals(null,pr);
         // this should have two transfer options
         System.assertEquals(true,ctc.hasMultipleXferOptions);

         ctc.groupOption = 'Test Sub Dept 2';
         pr = ctc.selectGroup();
         System.assertEquals(null,pr);
         System.assertEquals(true,ctc.okayToTransfer);
         System.assertEquals(true,ctc.recordTypeOkay);
         // this should have one transfer option
         System.assertEquals(false,ctc.hasMultipleXferOptions);
         // should be transfer to user only
         System.assertEquals('user',ctc.xferToOption);
         // attempt to transfer to a User without a user selected
         pr = ctc.transferCase();
         // should be an error message
         System.assertEquals(true,ApexPages.hasMessages());
         // check the latest message
         System.assertEquals(true,ApexPages.getMessages().get(ApexPages.getMessages().size()-1).getSummary().contains('A user must be entered to proceed!'));
         
         // select the attachment
         ctc.attaches.get(0).selected=true;
         
         // set a user and transfer again
         ctc.newCase.User__c = u2.Id;
         pr = ctc.transferCase();
         
         System.assertEquals(ctc.newCase.External_Department_Transfer__c,ctc.selectedRouting.Department__c);
         // transfer should be successful.
         System.assertEquals('This is a status description',ctc.newCase.Status_Description__c);
         
         // verify attachment moved to new case
         System.assertEquals(0,[select count() from Attachment where ParentId=:c.Id]); 
         System.assertEquals(1,[select count() from Attachment where ParentId=:ctc.newCase.Id]);
      } // System.runAs
   } // testCase1
    
   static testMethod void testSafetyTransfer() {
      Case_Transfer_Routing__c ctr = new Case_Transfer_Routing__c(From_Record_Type_Name__c = 'COE Submission Case Record Type'
                                               ,From_Profiles__c = null
                                               ,Department__c= 'Test Dept 2'
                                               ,Sub_Department_Name__c = 'Test Sub Dept 3'
                                               ,Queue_Name__c='Test Queue 2'
                                               ,Allow_Transfer_to_User__c = false
                                               ,Record_Type_Name__c = 'COE Submission Case Record Type'
                                               ,Field_Set_Name__c=null);
      Test.SetCurrentPageReference(Page.CaseTransfer);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new Case());
      //System.CurrentPageReference().getParameters().put('id',caseId);
      CaseTransferController ctc = new CaseTransferController(sc1);
      // no routing selected
      ctc.selectedRouting = null;
      System.assertEquals(false,ctc.showSafetyTransferFields);
      // a routing without the field set
      ctc.selectedRouting = ctr;
      System.assertEquals(false,ctc.showSafetyTransferFields);
      // add in the field set
      ctr.Field_Set_Name__c='Safety_Transfer_Fields';
      System.assertEquals(true,ctc.showSafetyTransferFields);

   } // testSafetyTransfer
   
   static testMethod void testBadFieldCopy() {
      Case_Transfer_Routing__c ctr = new Case_Transfer_Routing__c(From_Record_Type_Name__c = 'COE Submission Case Record Type'
                                               ,From_Profiles__c = null
                                               ,Department__c= 'Test Dept 2'
                                               ,Sub_Department_Name__c = 'Test Sub Dept 3'
                                               ,Queue_Name__c='Test Queue 2'
                                               ,Allow_Transfer_to_User__c = false
                                               ,Record_Type_Name__c = 'COE Submission Case Record Type'
                                               ,Field_Set_Name__c=null);
      insert ctr;
      // insert records for field copy
      Case_Transfer_Field_Copy__c[] ctfcs = new Case_Transfer_Field_Copy__c[]{};
      // put in a literal value
      ctfcs.add(new Case_Transfer_Field_Copy__c(Case_Transfer_Routing__c=ctr.Id
                                               ,Dest_Field_API_Name__c='BadFieldApiName'
                                               ,Dest_Field_Value__c='Test Justification'
                                               ,Source_Field_API_Name__c=null
                                               ,Source_Object_API_Name__c=null
                                                ));
      // copy from the existing case
      ctfcs.add(new Case_Transfer_Field_Copy__c(Case_Transfer_Routing__c=ctr.Id
                                               ,Dest_Field_API_Name__c='Status_Description__c'
                                               ,Dest_Field_Value__c=null
                                               ,Source_Field_API_Name__c='BadSourceFieldName'
                                               ,Source_Object_API_Name__c='Case'
                                                ));
      insert ctfcs;
      ctr = [Select Id
                        ,From_Record_Type_Name__c
                        ,From_Profiles__c
                        ,Department__c, Sub_Department_Name__c
                        ,Queue_Name__c, Record_Type_Name__c, Allow_Transfer_to_User__c
                        ,Field_Set_Name__c
                        ,(Select Id, Dest_Field_API_Name__c
                                ,Dest_Field_Value__c
                                ,Source_Field_API_Name__c
                                ,Source_Object_API_Name__c
                            from Case_Transfer_Field_Copies__r)
                    from Case_Transfer_Routing__c
                   where Id = :ctr.Id];
      Test.SetCurrentPageReference(Page.CaseTransfer);
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new Case());
      //System.CurrentPageReference().getParameters().put('id',caseId);
      CaseTransferController ctc = new CaseTransferController(sc1);
      ctc.selectedRouting = ctr;
      ctc.curCase = new Case();
      ctc.newCase = new Case();
      System.assertEquals(false,ctc.checkCopyFieldValues());
   } // testBadFieldCopy

   static testMethod void testCase2() {
      setupTestRouting();
      User u = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' limit 1];
      User u2 = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :u.Id limit 1];
      System.runAs(u) {
         Account a = new Account(Name = 'Test Account2');
         insert a;
         Contact ctct = new Contact(FirstName = 'Jimmy', LastName = 'Test2', AccountId = a.Id);
         insert ctct;
         Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('Sales Support Cases Record Type','Case');
         
         Case c = new Case(RecordTypeId = rt.getRecordTypeId(), Subject='Test Case2'
                          ,Description = 'This is the description for the test case'
                          ,Status_Description__c = 'This is a status description'
                          ,AccountId = a.Id, ContactId = ctct.Id);
         insert c;
         // add an attachment
         Blob b = Blob.valueOf('This is a test attachment');
         Attachment att = new Attachment(ParentId=c.Id, Name='Test.txt', Body=b);
         insert att;    
         
         Test.SetCurrentPageReference(Page.CaseTransfer);
         ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(c);
         System.CurrentPageReference().getParameters().put('id',c.Id);
         CaseTransferController ctc = new CaseTransferController(sc1);
         
         // check for attachments
         System.assertEquals(true,ctc.hasAttachments);
         
         ctc.departmentOption = 'Test HRS';
         PageReference pr = ctc.selectDepartment();
         ctc.groupOption = 'Test Sub Dept HRS';
         pr = ctc.selectGroup();
         // select the attachment
         ctc.attaches.get(0).selected=true;         
         // set a user and transfer
         ctc.newCase.User__c = u2.Id;
         pr = ctc.transferCase();
         
         // verify attachment moved to new reference object
         Reference_PEO__c refobj = [Select Id from Reference_PEO__c where Parent_Case__c = :ctc.newCase.Id];
         
         System.assertEquals(0,[select count() from Attachment where ParentId=:c.Id]); 
         System.assertEquals(1,[select count() from Attachment where ParentId=:refobj.Id]);
         
      }//System.runAs(u)           
   }// testCase2

   static testMethod void testCaseTransferSafetyRep() {
      setupTestRouting();
      User u = [Select Id, Name, HR_Person_Id__c from User where IsActive=true and Profile.Name='System Administrator' and HR_Person_Id__c != null limit 1];
      User u2 = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :u.Id limit 1];
      System.debug('testCaseTransferSafetyRep u='+u.Id+' HR_Person_Id__c='+u.HR_Person_Id__c+' u2='+u2.Id);
      
      System.runAs(u) {
         Contact ctct = new Contact(FirstName = 'Jimmy', LastName = 'TestCaseTransfer', HR_Person_Id__c = u.HR_Person_Id__c);
         insert ctct;
         Account a = new Account(Name = 'Test Account Case Transfer', Safety_Rep__C = ctct.Id);
         insert a;
         Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('Service Premier Record Type','Case');
         
         Case c = new Case(RecordTypeId = rt.getRecordTypeId(), Subject='Test Transfer Safety Rep'
                          ,Description = 'This is the description for the test case'
                          ,Status_Description__c = 'This is a status description'
                          ,AccountId = a.Id, ContactId = ctct.Id);
         insert c;
         
         
         Test.SetCurrentPageReference(Page.CaseTransfer);
         ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(c);
         System.CurrentPageReference().getParameters().put('id',c.Id);
         CaseTransferController ctc = new CaseTransferController(sc1);

         ctc.departmentOption = 'Safety Initial Contact';
         PageReference pr = ctc.selectDepartment();
         ctc.groupOption = 'Safety Initial Contact';
         pr = ctc.selectGroup();
         
         System.debug('testCaseTransferSafetyRep u.Id='+u.Id+' User='+ctc.newCase.User__c);
         System.assertEquals(ctc.newCase.User__c, u.Id);
         
      }//System.runAs(u)           
   }// testCaseTransferSafetyRep()

   static testMethod void testCaseTransferAccountOwner() {
      setupTestRouting();
      User u = [Select Id, Name, HR_Person_Id__c from User where IsActive=true and Profile.Name='System Administrator' limit 1];
      User u2 = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :u.Id limit 1];
      System.runAs(u) {
         Contact ctct = new Contact(FirstName = 'Jimmy', LastName = 'TestCaseTransferOwner', HR_Person_Id__c = u.HR_Person_Id__c);
         insert ctct;
         Account a = new Account(Name = 'Test Account Case Transfer Owner', OwnerId = u2.Id);
         insert a;
         Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('Service Premier Record Type','Case');
         
         Case c = new Case(RecordTypeId = rt.getRecordTypeId(), Subject='Test Transfer Safety Rep'
                          ,Description = 'This is the description for the test case'
                          ,Status_Description__c = 'This is a status description'
                          ,AccountId = a.Id, ContactId = ctct.Id);
         insert c;
         
         
         Test.SetCurrentPageReference(Page.CaseTransfer);
         ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(c);
         System.CurrentPageReference().getParameters().put('id',c.Id);
         CaseTransferController ctc = new CaseTransferController(sc1);

         ctc.departmentOption = 'Test Owner Transfer';
         PageReference pr = ctc.selectDepartment();
         ctc.groupOption = 'Test Owner Transfer';
         pr = ctc.selectGroup();
         
         System.assertEquals(ctc.newCase.User__c, u2.Id);
         
      }//System.runAs(u)           
   }// testCaseTransferSafetyRep()

} // class CaseTransferControllerTest