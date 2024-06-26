/**
 * The test methods for the WebServices call for Opportunities and Opportunity Details.
 *
 * History
 * -------
 * 09/24/2012 Cindy Freeman   Created
 * 05/14/2013 Cindy Freeman   Fixed testOppList method so repRole query actually returns a record
 * 10/23/2017 Cindy Freeman	  Modified for new PACO calls
 * 08/13/2018 Cindy Freeman   Lowered number of optys created for testOppDetailList
 * 11/16/2018 Dan Carmen      Removed Benetrac__c and EAO_Check_Date__c from the Account query - fields were deleted.
 * 03/01/2023 Dan Carmen      Add Billing Type
 * 03/28/2023 Dan Carmen      Update tests
 * 07/19/2023 Chris Santoro	  Added HRS User to test Quote Attachment
 * 04/02/2024 Chris Santoro	  Added testSubmissionUpdate()
 */
@isTest 
private class OpportunityServicesTest {
      
   static testmethod void testOppList() {
      
      UserHelperTest.selectDsaAndReps();
      
      User dsm = UserHelperTest.v_dsa;
      
      User[] repUsers = UserHelperTest.v_reps;      
      User outsideUser = UserHelperTest.v_rep6;      
      User hrsUser = UserHelperTest.v_hrs_rep; 
		System.Debug(hrsUser);
      // create accounts
      Account acct1 = new Account(Name='Test Acct1', AccountNumber='11-123456', OwnerId=repUsers.get(0).Id);      
      Account acct2 = new Account(Name='Test Acct2', AccountNumber='55-412365', OwnerId=repUsers.get(1).Id);
      Account acct3 = new Account(Name='Test Acct3', AccountNumber='400-Ab125', OwnerId=outsideUser.Id);
      Account acct4 = new Account(Name='Test Acct4', AccountNumber='400-Ac125', OwnerId=hrsUser.Id);
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      insert accts;
       
      Date closeDate = Date.today().addDays(30);
      
      String payrollPlatform = (dsm.profile.Name.contains('Core')? 'FLEX' : 'MMS');
      // create core opportunities
      Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
       Schema.RecordTypeInfo hrsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_401K,'Opportunity');
      Opportunity oppty1 = new Opportunity(Name='Test Acct1-Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,AccountId=acct1.Id
                                         ,StageName='Sold'
                                         ,CloseDate=closeDate
                                         ,Payroll_Platform__c = payrollPlatform
                                         ,OwnerId=repUsers.get(0).Id);
      Opportunity oppty2 = new Opportunity(Name='Test Acct2-Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,AccountId=acct2.Id
                                         ,StageName='Sold'
                                         ,CloseDate=closeDate
                                         ,Payroll_Platform__c = payrollPlatform
                                         ,OwnerId=repUsers.get(1).Id);
      Opportunity oppty3 = new Opportunity(Name='Test Acct3-Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,AccountId=acct3.Id
                                         ,StageName='Sold'
                                         ,CloseDate=closeDate
                                         ,Payroll_Platform__c = payrollPlatform
                                         ,OwnerId=outsideUser.Id);
       Opportunity oppty4 = new Opportunity(Name='Test Acct4-Opporty', RecordTypeId=hrsOpptyRt.getRecordTypeId()
                                            ,AccountId=acct4.Id
                                            ,StageName='Sold'
                                            ,CloseDate=closeDate
                                            ,Payroll_Platform__c = 'HRS'
                                            ,OwnerId=hrsUser.Id);
      Opportunity[] opps = new Opportunity[]{oppty1,oppty2,oppty3,oppty4};
      insert opps;
       
       OracleQuoteTriggerPayxHelperTest.setupOracleSetting();
       cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
       cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
       quote.cafsl__Account__c = oppty4.AccountId;
       quote.cafsl__Opportunity__c = oppty4.Id;
       quote.Name = 'TestQuote';
       quote.Multi_ID__c = false;
       //quote.cafsl__Pricebook_Id__c = spricebookId;
       quote.cafsl__CPQ_External_Id__c='12345678';
       quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
       insert quote;
       
       oppty4.Primary_Oracle_Quote__c=quote.id;
       update oppty4;
       
       ContentVersion contentVersion = new ContentVersion(Title = 'TestQuote', PathOnClient = 'TestFile.pdf', VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true);
       insert contentVersion;  
       
       contentVersion = new ContentVersion(Title = 'Some File -Data Export', PathOnClient = 'Some File -Data Export.pdf', VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true);
       insert contentVersion;  
       
       contentVersion = new ContentVersion(Title = 'Some File -Mapping Report', PathOnClient = 'Some File -Mapping Report.xlsx', VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true);
       insert contentVersion;  
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink(LinkedEntityId = oppty4.Id, ContentDocumentId = documents[0].Id, shareType = 'V');
        insert cdl;    
       
        cdl = New ContentDocumentLink(LinkedEntityId = oppty4.Id, ContentDocumentId = documents[1].Id, shareType = 'V');
        insert cdl;         
       
        cdl = New ContentDocumentLink(LinkedEntityId = oppty4.Id, ContentDocumentId = documents[2].Id, shareType = 'V');
        insert cdl;  
                             
      // test as DSM to get opptys for users under him
      System.RunAs(dsm) {
        List <OpportunityServices.OppList> oppList = new List<OpportunityServices.OppList>();
                       
        //oppList = OpportunityServices.getOppList();
        oppList = OpportunityServices.getOppList2(dsm.HR_Person_Id__c);
        System.assertEquals(2, oppList.size());
          List<Web_Service_Log__c> wsLog = [Select Id from Web_Service_Log__c where SobjName__c = 'PACO Inquiry'];
          System.assert(!wsLog.isEmpty());

        Map <Id, OpportunityServices.OppList> oppMap = new Map<Id, OpportunityServices.OppList>();
        for (OpportunityServices.OppList ol: oppList)
        {   oppMap.put(ol.oppId, ol);   }
        System.assertEquals(True, oppMap.containsKey(oppty1.Id));
        System.assertEquals(oppty1.Name, oppMap.get(oppty1.Id).oppName);
        System.assertEquals(True, oppMap.containsKey(oppty2.Id));
        //System.assertEquals(acct2.Name, oppMap.get(oppty2.Id).prospectName);              
 
      } // runAs dsm
      
      // test as rep to get just their opptys
      System.RunAs(repUsers.get(1)) {      	
        List <OpportunityServices.OppList> oppList = new List<OpportunityServices.OppList>();
        //oppList = OpportunityServices.getOppList();
        oppList = OpportunityServices.getOppList2(repUsers.get(1).HR_Person_Id__c);
        System.assertEquals(1, oppList.size());
        Map <Id, OpportunityServices.OppList> oppMap = new Map<Id, OpportunityServices.OppList>();
        for (OpportunityServices.OppList ol: oppList)
        {   oppMap.put(ol.oppId, ol);   }
        System.assertEquals(True, oppMap.containsKey(oppty2.Id));
        System.assertEquals(oppty2.Name, oppMap.get(oppty2.Id).oppName);
        //System.assertEquals(closeDate, oppMap.get(oppty2.Id).runDate);   
        
        List<Id> oppIdList = new List<Id>();
        oppIdList.add(oppty2.Id);
        List <OpportunityServices.OppDetailList> oppDtlList = new List <OpportunityServices.OppDetailList>();
        oppDtlList = OpportunityServices.getOppDetailList(oppIdList);
        System.assertEquals(1, oppDtlList.size());
                          
/*
        oppList = OpportunityServices.getOppList2(repUsers.get(1).HR_Person_Id__c);
        System.assertEquals(1, oppList.size());
        oppMap = new Map<Id, OpportunityServices.OppList>();
        for (OpportunityServices.OppList ol: oppList)
        {   oppMap.put(ol.oppId, ol);   }
        System.assertEquals(True, oppMap.containsKey(oppty2.Id));
        System.assertEquals(Date.today().addDays(30), oppMap.get(oppty2.Id).runDate);   */
          
      } // runAs(repUser1)
       
        
      System.RunAs(hrsUser) {
        List <OpportunityServices.OppList> oppList = new List<OpportunityServices.OppList>();
        //oppList = OpportunityServices.getOppList();
        oppList = OpportunityServices.getOppList2(hrsUser.HR_Person_Id__c);
        System.assertEquals(1, oppList.size());
        Map <Id, OpportunityServices.OppList> oppMap = new Map<Id, OpportunityServices.OppList>();
        for (OpportunityServices.OppList ol: oppList)
        {   oppMap.put(ol.oppId, ol);   }
        System.assertEquals(True, oppMap.containsKey(oppty4.Id));
        System.assertEquals(oppty4.Name, oppMap.get(oppty4.Id).oppName);
        //System.assertEquals(closeDate, oppMap.get(oppty4.Id).runDate);   
        
        List<Id> oppIdList = new List<Id>();
        oppIdList.add(oppty4.Id);
        List <OpportunityServices.OppDetailList> oppDtlList = new List <OpportunityServices.OppDetailList>();
        oppDtlList = OpportunityServices.getOppDetailList(oppIdList);
        System.assertEquals(1, oppDtlList.size());
      } 
      
   }  // testOppList

    static testmethod void testOppList2() {
      
      UserHelperTest.selectDsaAndReps();
      
      User dsm = UserHelperTest.v_dsa;
      
      User[] repUsers = UserHelperTest.v_reps;      
      User outsideUser = UserHelperTest.v_rep6;   
      User caMandateUser = repUsers[4];
      caMandateUser.User_Type__c = OpportunityServices.CA_MANDATE_USER_TYPE;
      UserHelper.SKIP_USER_TRIGGERS=true;
      update caMandateUser;
      //User[] caMandateUsers = UserHelperTest.ca_mandate_reps;

      // create accounts
      Account acct1 = new Account(Name='Test Acct1', AccountNumber='11-123456', OwnerId=repUsers.get(0).Id);      
      Account acct2 = new Account(Name='Test Acct2', AccountNumber='55-412365', OwnerId=repUsers.get(1).Id);
      Account acct3 = new Account(Name='Test Acct3', AccountNumber='400-Ab125', OwnerId=outsideUser.Id);
      Account acct4 = new Account(Name='Test Acct4', AccountNumber='400-Ab196', OwnerId=caMandateUser.Id);
      Account[] accts = new Account[]{acct1,acct2,acct3, acct4};
      insert accts;
      
      Date closeDate = Date.today().addDays(30);
        
      String payrollPlatform = (dsm.profile.Name.contains('Core')? 'FLEX' : 'MMS');
      // create core opportunities
      Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
      Opportunity oppty1 = new Opportunity(Name='Test Acct1-Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,AccountId=acct1.Id
                                         ,StageName='Sold'
                                         ,CloseDate=closeDate
                                         ,Payroll_Platform__c = payrollPlatform
                                         ,OwnerId=repUsers.get(0).Id);
      Opportunity oppty2 = new Opportunity(Name='Test Acct2-Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,AccountId=acct2.Id
                                         ,StageName='Sold'
                                         ,CloseDate=closeDate
                                         ,Payroll_Platform__c = payrollPlatform
                                         ,OwnerId=repUsers.get(1).Id);
      Opportunity oppty3 = new Opportunity(Name='Test Acct3-Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,AccountId=acct3.Id
                                         ,StageName='Sold'
                                         ,CloseDate=closeDate
                                         ,Payroll_Platform__c = payrollPlatform
                                         ,OwnerId=outsideUser.Id);
      Opportunity oppty4 = new Opportunity(Name='Test Acct4-Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,AccountId=acct4.Id
                                         ,StageName='Sold'
                                         ,CloseDate=closeDate
                                         ,Payroll_Platform__c = 'PAY'
                                         ,OwnerId=caMandateUser.Id
                                          ,Mandate_Sale__c = true);
      Opportunity[] opps = new Opportunity[]{oppty1,oppty2,oppty3,oppty4};
      insert opps;
        
      Onboarding_Tool__c onbTool1 = new Onboarding_Tool__c(Opportunity_Id__c = oppty4.Id
                                                         ,All_Children_Submitted__c =false);
        
      insert new Onboarding_Tool__c[]{onbTool1};
        
      Reference_CTT__c refCTT1 = new Reference_CTT__c(OwnerId=caMandateUser.Id
                                           ,Opportunity__c = oppty4.Id);
        
      insert new Reference_CTT__c[]{refCTT1};
        
      // test as DSM to get opptys for users under him
      System.RunAs(dsm) {
        List <OpportunityServices.OppList> oppList = new List<OpportunityServices.OppList>();
                       
        oppList = OpportunityServices.getOppList2(dsm.HR_Person_Id__c);
        System.assertEquals(3, oppList.size());
          List<Web_Service_Log__c> wsLog = [Select Id from Web_Service_Log__c where SobjName__c = 'PACO Inquiry'];
          System.assert(!wsLog.isEmpty());

        Map <Id, OpportunityServices.OppList> oppMap = new Map<Id, OpportunityServices.OppList>();
        for (OpportunityServices.OppList ol: oppList)
        {   oppMap.put(ol.oppId, ol);   }
        System.assertEquals(True, oppMap.containsKey(oppty1.Id));
        System.assertEquals(oppty1.Name, oppMap.get(oppty1.Id).oppName);
        System.assertEquals(True, oppMap.containsKey(oppty2.Id));
        //System.assertEquals(acct2.Name, oppMap.get(oppty2.Id).prospectName);              
 	        
      } // runAs dsm
      
      // test as rep to get just their opptys
      System.RunAs(repUsers.get(1)) {      	
        List <OpportunityServices.OppList> oppList = new List<OpportunityServices.OppList>();
        oppList = OpportunityServices.getOppList2(repUsers.get(1).HR_Person_Id__c);
        System.assertEquals(1, oppList.size());
        Map <Id, OpportunityServices.OppList> oppMap = new Map<Id, OpportunityServices.OppList>();
        for (OpportunityServices.OppList ol: oppList)
        {   oppMap.put(ol.oppId, ol);   }
        System.assertEquals(True, oppMap.containsKey(oppty2.Id));
        System.assertEquals(oppty2.Name, oppMap.get(oppty2.Id).oppName); 
        //System.assertEquals(closeDate, oppMap.get(oppty2.Id).runDate);   
        
        List<Id> oppIdList = new List<Id>();
        oppIdList.add(oppty2.Id);
        List <OpportunityServices.OppDetailList> oppDtlList = new List <OpportunityServices.OppDetailList>();
        oppDtlList = OpportunityServices.getOppDetailList(oppIdList);
        System.assertEquals(1, oppDtlList.size());
        
         //test with more than 200 opps
        List<Id> oppIdList200 = new List<Id>();
          for(Integer x = 0;x <= 200;x++){
        		oppIdList200.add(oppty2.Id);
          }
        List <OpportunityServices.OppDetailList> oppDtlList200 = new List <OpportunityServices.OppDetailList>();
        oppDtlList200 = OpportunityServices.getOppDetailList(oppIdList200);
        System.assertEquals(201, oppIdList200.size());
          
        oppList = OpportunityServices.getOppList2(repUsers.get(1).HR_Person_Id__c);
        System.assertEquals(1, oppList.size());
        oppMap = new Map<Id, OpportunityServices.OppList>();
        for (OpportunityServices.OppList ol: oppList)
        {   oppMap.put(ol.oppId, ol);   }
        System.assertEquals(True, oppMap.containsKey(oppty2.Id));
        System.assertEquals(oppty2.Name, oppMap.get(oppty2.Id).oppName);
        //System.assertEquals(closeDate, oppMap.get(oppty2.Id).runDate);  
          
      } // runAs(repUser1)
        
              // test as rep to get just their opptys
      System.RunAs(caMandateUser) {      	
        List <OpportunityServices.OppList> oppList = new List<OpportunityServices.OppList>();
        oppList = OpportunityServices.getOppList2(caMandateUser.HR_Person_Id__c);
        System.assertEquals(1, oppList.size());
        Map <Id, OpportunityServices.OppList> oppMap = new Map<Id, OpportunityServices.OppList>();
        for (OpportunityServices.OppList ol: oppList)
        {   oppMap.put(ol.oppId, ol);   }
        System.assertEquals(True, oppMap.containsKey(oppty4.Id));
        System.assertEquals(oppty4.Name, oppMap.get(oppty4.Id).oppName);  
        //System.assertEquals(closeDate, oppMap.get(oppty4.Id).runDate);   
        
        List<Id> oppIdList = new List<Id>();
        oppIdList.add(oppty4.Id);
        List <OpportunityServices.OppDetailList> oppDtlList = new List <OpportunityServices.OppDetailList>();
        oppDtlList = OpportunityServices.getOppDetailList(oppIdList);
        System.assertEquals(1, oppDtlList.size());
          
        oppList = OpportunityServices.getOppList2(caMandateUser.HR_Person_Id__c);
        System.assertEquals(1, oppList.size());
        oppMap = new Map<Id, OpportunityServices.OppList>();
        for (OpportunityServices.OppList ol: oppList)
        {   oppMap.put(ol.oppId, ol);   }
        System.assertEquals(True, oppMap.containsKey(oppty4.Id));
        System.assertEquals(oppty4.Name, oppMap.get(oppty4.Id).oppName);  
        //System.assertEquals(closeDate, oppMap.get(oppty4.Id).runDate);
          
      } // runAs(ca_mandate_rep)
        
   }  // testOppList
     
   static testmethod void testOppDetailList() {
      // number of optys to check 
      Integer numRecs = 25;
      
      // create an account
      Account acct1 = new Account(Name='Test Acct1', AccountNumber='10-123456');
      insert acct1;
      // create a contact
      Schema.RecordTypeInfo coreCtctRt = RecordTypeHelper.getRecordType('Core Contact Record Type','Contact');
      Contact ctct1 = new Contact(FirstName='Test', LastName='Contact1' 
                ,AccountId=acct1.Id
                ,Sales_Contact__c = false
                ,RecordTypeId=coreCtctRt.getRecordTypeId());
      Contact ctct2 = new Contact(FirstName='Test', LastName='Contact2'
                ,AccountId=acct1.Id
                ,Sales_Contact__c = true
                ,RecordTypeId=coreCtctRt.getRecordTypeId());
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      insert ctcts;
      	  
      // create a core opportunity
      Opportunity[] testOpps = new Opportunity[]{};
      Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
      for (Integer cnt = 0; cnt < numRecs; cnt++)  {
           Opportunity oppty1 = new Opportunity(Name='Test Opporty_' + cnt, RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=acct1.Id
                                         ,StageName='Sold'
                                         ,CloseDate=Date.today().addDays(30)
                                         ,Payroll_Platform__c = 'MMS'
                                         ,OwnerId=UserInfo.getUserId());
           testOpps.add(oppty1);
      }
      insert testOpps;
      
      Id[] testOppIds = new Id[]{};
      for (Opportunity opp : testOpps) {
          testOppIds.add(opp.Id);
      }    
      List <OpportunityServices.OppDetailList> oppDtlList = new List <OpportunityServices.OppDetailList>();
      oppDtlList = OpportunityServices.getOppDetailList(testOppIds);
      System.assertEquals(numRecs, oppDtlList.size());
            
      OpportunityServices.OppDetailList odl = oppDtlList.get(0);
      System.assertNotEquals(null, odl.oppId);
      System.assertEquals('Test Acct1',odl.acc.Name);
      System.assertEquals(2, odl.acc.Contacts.size());      // make sure got sales_contact back plus any I owned
      Opportunity o = [Select Id, Name, Owner.Name from Opportunity 
                        where Id = :odl.oppId];
      System.assertEquals(o.Name, odl.opp.Name);
        
      
   } // testOppDetailList
 
 static testmethod void testOppDetailListSingle() {
      // number of optys to check 
      Integer numRecs = 1;
 
 	  User u = [Select Id, Name from User where IsActive=true and Profile.Name = :Utilities.PROF_MMS_SALES_SB and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
 	       
      // create an account
      Schema.RecordTypeInfo mmsAcctRt = RecordTypeHelper.getRecordType('MMS Account Record Type','Account');
      Account acct1 = new Account(Name='Test Acct1',RecordTypeId=mmsAcctRt.getRecordTypeId(), OwnerId=u.Id);
      insert acct1;
      // create a contact
      Schema.RecordTypeInfo mmsCtctRt = RecordTypeHelper.getRecordType('MMS Contact Record Type','Contact');
      Contact ctct1 = new Contact(FirstName='Test', LastName='Contact1' 
                ,AccountId=acct1.Id
                ,Sales_Contact__c = false
                ,RecordTypeId=mmsCtctRt.getRecordTypeId()
                ,OwnerId=u.Id);
      Contact ctct2 = new Contact(FirstName='Test', LastName='Contact2'
                ,AccountId=acct1.Id
                ,Sales_Contact__c = true
                ,RecordTypeId=mmsCtctRt.getRecordTypeId()
                ,OwnerId=u.Id);
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      insert ctcts;
      	  
      // create a core opportunity
      Opportunity[] testOpps = new Opportunity[]{};
      Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS,'Opportunity');
      for (Integer cnt = 0; cnt < numRecs; cnt++)  {
           Opportunity oppty1 = new Opportunity(Name='Test Opporty_' + cnt, RecordTypeId=mmsOpptyRt.getRecordTypeId(),AccountId=acct1.Id
                                         ,StageName='Sold'
                                         ,CloseDate=Date.today().addDays(30)
                                         ,Payroll_Platform__c = 'MMS'
                                         ,OwnerId=u.Id);
                                         //,OwnerId=UserInfo.getUserId());
           testOpps.add(oppty1);
      }
      insert testOpps;
      
      Id[] testOppIds = new Id[]{};
      for (Opportunity opp : testOpps) {
          testOppIds.add(opp.Id);
      }
      
      System.runAs(u)
      {		List <OpportunityServices.OppDetailList> oppDtlList = new List <OpportunityServices.OppDetailList>();
		      oppDtlList = OpportunityServices.getOppDetailList(testOppIds);
		      System.assertEquals(numRecs, oppDtlList.size());
		            
		      OpportunityServices.OppDetailList odl = oppDtlList.get(0);
		      System.assertNotEquals(null, odl.oppId);
		      System.assertEquals('Test Acct1',odl.acc.Name);
		      System.assertEquals(2, odl.acc.Contacts.size());      // make sure got sales_contact back plus any I owned
		      Opportunity o = [Select Id, Name, Owner.Name from Opportunity 
		                        where Id = :odl.oppId];
		      System.assertEquals(o.Name, odl.opp.Name);
      }
                   
   } // testOppDetailListSingle
    
   static testmethod void testMultiId() {
      // check without using the CSO_Tracking__c objects
      User rep = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
      Schema.RecordTypeInfo mmsAcctRt = RecordTypeHelper.getRecordType('MMS Account Record Type','Account');
      Account acct1 = new Account(Name='Test Acct1',RecordTypeId=mmsAcctRt.getRecordTypeId(), OwnerId=rep.Id, Paychex_CEID__c='TestCeid1', Paychex_CAID__c='TestParentCAID');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct1;
      Account child1 = new Account(Name='Child1',RecordTypeId=mmsAcctRt.getRecordTypeId(), OwnerId=rep.Id, SalesParent__c=acct1.Id, Paychex_CEID__c='TestCeid1', Paychex_CAID__c='TestChild1CAID');
      Account child2 = new Account(Name='Child2',RecordTypeId=mmsAcctRt.getRecordTypeId(), OwnerId=rep.Id, SalesParent__c=acct1.Id, Paychex_CEID__c='TestCeid1', Paychex_CAID__c='TestChild2CAID');
      Account child3 = new Account(Name='Child3',RecordTypeId=mmsAcctRt.getRecordTypeId(), OwnerId=rep.Id, SalesParent__c=acct1.Id, Paychex_CEID__c='TestCeid1', Paychex_CAID__c='TestChild3CAID');
      insert new Account[]{child1,child2,child3};
      
      Map<String,Schema.RecordTypeInfo> rtMap = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo oppRtInfo = rtMap.get('MMS Opportunity Record Type');
      Opportunity opp = new Opportunity(AccountId=acct1.Id, Name='Test Opportunity', RecordTypeId=oppRtInfo.getRecordTypeId(), OpportunityType__c='Payroll', StageName='Gained Access', CloseDate=Date.today().addDays(7), Frequency__c='26', Employees_Paid_Per_Payroll__c=13);
      insert opp;
       
      Onboarding_Tool__c onbTool1 = new Onboarding_Tool__c(Opportunity_Id__c = opp.Id ,All_Children_Submitted__c =false, AccountId__c=acct1.Id);
      insert onbTool1;
       
      Onboarding_Tool__c childTool1 = new Onboarding_Tool__c(AccountId__c=child1.Id, Parent_Onboarding_Record__c=onbTool1.Id, Combo__c='Yes');
      Onboarding_Tool__c childTool2 = new Onboarding_Tool__c(AccountId__c=child2.Id, Parent_Onboarding_Record__c=onbTool1.Id);
      Onboarding_Tool__c childTool3 = new Onboarding_Tool__c(AccountId__c=child3.Id, Parent_Onboarding_Record__c=onbTool1.Id);
      // skip the trigger so it doesn't set the parent attributes
      OnboardingToolHelper.SKIP_TRIGGERS=true;
      insert new Onboarding_Tool__c[]{childTool1,childTool2,childTool3};

      CSO_Tracking__c csoRec = new CSO_Tracking__c(Name = opp.Name, AccountId__c = opp.AccountId, Opportunity__c = opp.Id, IsParentTracker__c=true, Onboarding_Tool__c=onbTool1.Id);
      insert csoRec;
      
      opp.ClientTracking__c = csoRec.Id;
      OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
      update opp;
       
      // make sure it's not set
      Onboarding_Tool__c checkTool = [Select Id, Combo__c from Onboarding_Tool__c where Id=:onbTool1.Id];
      Assert.isNull(checkTool.Combo__c);

      OpportunityServices.OppDetailList[] results = OpportunityServices.getOppDetailList(new Id[]{opp.Id});
      Assert.areEqual(1,results.size());
      OpportunityServices.OppDetailList oppDetail = results[0];
      Assert.areEqual(3,oppDetail.childInfo.size());
       
      Assert.areEqual(1,oppDetail.opp.Onboarding_Tools__r.size());
      Assert.areEqual('Yes',oppDetail.opp.Onboarding_Tools__r[0].Combo__c);
       
      // make sure it saved
      checkTool = [Select Id, Combo__c from Onboarding_Tool__c where Id=:onbTool1.Id];
      Assert.areEqual('Yes',checkTool.Combo__c);

   } // testMultiId
    
   static testmethod void testMultiId2() {
      // check using the CSO_Tracking__c objects
      User rep = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
      Schema.RecordTypeInfo mmsAcctRt = RecordTypeHelper.getRecordType('MMS Account Record Type','Account');
      Account acct1 = new Account(Name='Test Acct1',RecordTypeId=mmsAcctRt.getRecordTypeId(), OwnerId=rep.Id, Paychex_CEID__c='TestCeid1', Paychex_CAID__c='TestParentCAID');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct1;
      Account child1 = new Account(Name='Child1',RecordTypeId=mmsAcctRt.getRecordTypeId(), OwnerId=rep.Id, SalesParent__c=acct1.Id, Paychex_CEID__c='TestCeid1', Paychex_CAID__c='TestChild1CAID');
      Account child2 = new Account(Name='Child2',RecordTypeId=mmsAcctRt.getRecordTypeId(), OwnerId=rep.Id, SalesParent__c=acct1.Id, Paychex_CEID__c='TestCeid1', Paychex_CAID__c='TestChild2CAID');
      Account child3 = new Account(Name='Child3',RecordTypeId=mmsAcctRt.getRecordTypeId(), OwnerId=rep.Id, SalesParent__c=acct1.Id, Paychex_CEID__c='TestCeid1', Paychex_CAID__c='TestChild3CAID');
      insert new Account[]{child1,child2,child3};
      
      Map<String,Schema.RecordTypeInfo> rtMap = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo oppRtInfo = rtMap.get('MMS Opportunity Record Type');
      Opportunity opp = new Opportunity(AccountId=acct1.Id, Name='Test Opportunity', RecordTypeId=oppRtInfo.getRecordTypeId(), OpportunityType__c='Payroll', StageName='Gained Access', CloseDate=Date.today().addDays(7), Frequency__c='26', Employees_Paid_Per_Payroll__c=13);
      insert opp;
       
      Onboarding_Tool__c onbTool1 = new Onboarding_Tool__c(Opportunity_Id__c = opp.Id ,All_Children_Submitted__c =false, AccountId__c=acct1.Id);
      insert onbTool1;
       
      Onboarding_Tool__c childTool1 = new Onboarding_Tool__c(AccountId__c=child1.Id, Parent_Onboarding_Record__c=onbTool1.Id);
      Onboarding_Tool__c childTool2 = new Onboarding_Tool__c(AccountId__c=child2.Id, Parent_Onboarding_Record__c=onbTool1.Id);
      Onboarding_Tool__c childTool3 = new Onboarding_Tool__c(AccountId__c=child3.Id, Parent_Onboarding_Record__c=onbTool1.Id);
      // skip the trigger so it doesn't set the parent attributes
      OnboardingToolHelper.SKIP_TRIGGERS=true;
      insert new Onboarding_Tool__c[]{childTool1,childTool2,childTool3};
          
      Assert.areEqual(0,[select count() from CSO_Tracking__c]);

      CSO_Tracking__c csoRec = new CSO_Tracking__c(Name = opp.Name, AccountId__c = opp.AccountId, Opportunity__c = opp.Id, IsParentTracker__c=true, Onboarding_Tool__c=onbTool1.Id);
      CsoMethods.SKIP_TRIGGERS=true;
      insert csoRec;
      Assert.areEqual(1,[select count() from CSO_Tracking__c]);

      CSO_Tracking__c csoRec2 = new CSO_Tracking__c(Name = opp.Name, AccountId__c = child1.Id, ParentTracker__c=csoRec.Id, ParentAccount__c=acct1.Id, Onboarding_Tool__c=childTool1.Id, ChildType__c='Combo');
      CSO_Tracking__c csoRec3 = new CSO_Tracking__c(Name = opp.Name, AccountId__c = child2.Id, ParentTracker__c=csoRec.Id, ParentAccount__c=acct1.Id, Onboarding_Tool__c=childTool2.Id, ChildType__c='Sales Parent-Child');
      CSO_Tracking__c csoRec4 = new CSO_Tracking__c(Name = opp.Name, AccountId__c = child3.Id, ParentTracker__c=csoRec.Id, ParentAccount__c=acct1.Id, Onboarding_Tool__c=childTool3.Id, ChildType__c='Sales Parent-Child');
      insert new CSO_Tracking__c[]{csoRec2,csoRec3,csoRec4};
      Assert.areEqual(4,[select count() from CSO_Tracking__c]);
      Assert.areEqual(1,[Select count() from CSO_Tracking__c where IsSameFEIN__c=true]);
      
      childTool1.ClientTracking__c = csoRec2.Id;
      childTool2.ClientTracking__c = csoRec3.Id;
      childTool3.ClientTracking__c = csoRec4.Id;
      update new Onboarding_Tool__c[]{childTool1,childTool2,childTool3};
      
      opp.ClientTracking__c = csoRec.Id;
      OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
      update opp;
       
      // make sure it's not set
      Onboarding_Tool__c checkTool = [Select Id, Combo__c from Onboarding_Tool__c where Id=:onbTool1.Id];
      Assert.isNull(checkTool.Combo__c);

      OpportunityServices.OppDetailList[] results = OpportunityServices.getOppDetailList(new Id[]{opp.Id});
      Assert.areEqual(1,results.size());
      OpportunityServices.OppDetailList oppDetail = results[0];
      Assert.areEqual(3,oppDetail.childInfo.size());
       
      Assert.areEqual(1,oppDetail.opp.Onboarding_Tools__r.size());
      Assert.areEqual('Yes',oppDetail.opp.Onboarding_Tools__r[0].Combo__c);
      
      // make sure it saved
      checkTool = [Select Id, Combo__c from Onboarding_Tool__c where Id=:onbTool1.Id];
      Assert.areEqual('Yes',checkTool.Combo__c);
   } // testMultiId2
    
    static testmethod void testSubmissionUpdate() {
        UserHelperTest.selectDsaAndReps();
        User[] repUsers = UserHelperTest.v_reps;   
        // create accounts
        Account acct1 = new Account(Name='Test Acct1', AccountNumber='11-123456', OwnerId=repUsers.get(0).Id);      
        insert acct1;
        
        Date closeDate = Date.today().addDays(30);
        
        // create core opportunities
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        Opportunity oppty1 = new Opportunity(Name='Test Acct1-Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                             ,AccountId=acct1.Id
                                             ,StageName='Pending'
                                             ,CloseDate=closeDate
                                             ,Payroll_Platform__c = 'PAY'
                                             ,OwnerId=repUsers.get(0).Id);
        insert oppty1; 
        
        DateTime submitDate = DateTime.now();
        string[] oppIds = new string[] { oppty1.Id };
        OpportunityServices.submissionUpdate(oppIds, submitDate);
        List<Opportunity> records = [SELECT Id, PACO_Submission_Date__c FROM Opportunity WHERE Id IN :oppIds];       
        for (Opportunity record : records)
        {
            System.assertEquals(submitDate, record.PACO_Submission_Date__c); 
        }
    }
    
} // class OpportunityServicesTest