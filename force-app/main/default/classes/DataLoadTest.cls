/* 
   Test methods for the dataload classes

   
  History
  -------
  09/23/2020 Dan Carmen   Created
  11/04/2020 Dan Carmen   Explicitly create campaign members.
  03/26/2021 Dan Carmen   Fix for field accessibility
  06/17/2021 Dan Carmen   Update when we use Data Governance Rules
  07/16/2021 Dan Carmen   Ability to skip triggers on save
  06/20/2022 Dan Carmen   Change insert, update, and upsert to use DmlHelper
  03/13/2023 Dan Carmen   Increment API to 57

 */
@isTest
public class DataLoadTest {

   @testSetup
   public static void setupData() {
      Apex_Batch_Control__c  abc0 = new Apex_Batch_Control__c(Name=DataLoadBatch.CLASSNAME,Active__c=true, NbrOfAttempts__c=1, BatchSize__c=100, Minutes_till_Launch__c=1);
      Apex_Batch_Control__c  abc1 = new Apex_Batch_Control__c(Name=DataLoadBatch2.CLASSNAME,Active__c=true, NbrOfAttempts__c=1, BatchSize__c=100, Minutes_till_Launch__c=1);
      Apex_Batch_Control__c  abc2 = new Apex_Batch_Control__c(Name=DataLoadBatch3.CLASSNAME,Active__c=true, NbrOfAttempts__c=2, BatchSize__c=1, Minutes_till_Launch__c=1);
      Apex_Batch_Control__c  abc3 = new Apex_Batch_Control__c(Name=DataLoadQueueable.CLASSNAME,Active__c=true, NbrOfAttempts__c=2, BatchSize__c=1, Minutes_till_Launch__c=1);
      Apex_Batch_Control__c[] abcs = new Apex_Batch_Control__c[]{abc0,abc1,abc2,abc3};
      insert abcs;
   } // setupData

    public static String badLeadFile = 'This,Is,A,Bad,File'+EmailServiceProcessorBatch.CRLF+'These,Are,Not,Columns,Okay';
   public static String goodLeadFile = 'FirstName,LastName,Phone,Email,Company,Street,City,State,PostalCode,NumberOfEmployees'+EmailServiceProcessorBatch.CRLF
                                      +'John,Doe,5851112222,john@doe.com,john doe enterprises,123 Main St,Rochester, NY, 14624,7'+EmailServiceProcessorBatch.CRLF
                                      +'Jane,Smith,5852223333,jane@smith.com,"Jane Smith, LLC",234 Main St,Rochester,NY,14624,4'+EmailServiceProcessorBatch.CRLF;
   public static String goodRfrlFile = 'FirstName,LastName,Phone,Email,Company,Street,City,State,PostalCode,Referral_Source_Business_Type__c,BadHeader,Referral_Account__c.Sensitivity_401_k__c,Referral_Contact__c.Sensitivity_401_k__c,Referral_Account__c.Sensitivity_FSA__c,Referral_Contact__c.Sensitivity_FSA__c'+EmailServiceProcessorBatch.CRLF
                                      +'John,Doe,5851112222,john@doe.com,john doe enterprises,123 Main St,Rochester, NY, 14624,Accounting Firm,,true,false,true,false'+EmailServiceProcessorBatch.CRLF
                                      +'Jane,Smith,5852223333,jane@smith.com,"Jane Smith, LLC",234 Main St,Rochester,NY,14624,Accounting Firm,,false,true,false,true'+EmailServiceProcessorBatch.CRLF;
    
   public static DataLoad__c getDataLoad(Id dlId) {
      Dataload__c dl = [Select Id, Name
                  ,FileLoaded__c, FileParsed__c, FileType__c
                  ,HeadersAreValid__c, NbrHeaders__c
                  ,NbrInserts__c, NbrLoadRecords__c, NbrSuccess__c, NbrUpdated__c
                  ,NbrValidHeaders__c, NotifyOwner__c, OwnedBy__c
                  ,PctLoadedSuccesfully__c, ProcessDataEnd__c, ProcessDataStart__c
                  ,ProcessNotes__c, Status__c, UpdateAPIObjectName__c
                  ,(Select Id, Account__c, Contact__c, Created__c
                          ,Dataflux_Id__c, DataLoad__c, DataRow__c
                          ,ErrorDetail__c, HasLinkedRecord__c, Lead__c
                          ,Referral_Account__c, Referral_Contact__c, Success__c
                          ,RowNbr__c, Status__c
                      From DataLoadRecords__r
                     order by RowNbr__c)
              From DataLoad__c
             Where Id=:dlId];
      return dl;
   } // getDataLoad

   // test when we don't have all of the required headers
   static testMethod void testMissingRequiredHeaders() {
      DataLoad__c dl = new DataLoad__c(Name='testMissingRequiredHeaders',FileType__c=DataLoadMethods.TYPE_SF_UPDATE, UpdateAPIObjectName__c=ObjectHelper.OBJECT_ACCOUNT,Description__c='Just Because');
      insert dl;
      String outputFileName = dl.Name+'.csv';
      AddFileQueueable afq = new AddFileQueueable(new Id[]{dl.Id}, outputFileName, outputFileName, null, Blob.valueOf(badLeadFile));
      afq.processRecs();
      dl = getDataLoad(dl.Id);
      System.assertEquals(DataLoadMethods.STATUS_ERROR,dl.Status__c);
      System.assertEquals(false,dl.FileLoaded__c);

   } // testMissingRequiredHeaders
    
   // test the parse method
   static testMethod void testFileUpdate1() {
      // test updating 2 accounts
      Account acct1 = new Account(Name='Account 1');
      Account acct2 = new Account(Name='Account 2');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      Account[] accts = new Account[]{acct1,acct2};
      insert accts;
       
      String testFile = 'Id,ShippingState,ShippingPostalCode,BillingState,BillingPostalCode'+EmailServiceProcessorBatch.CRLF;
      testFile += acct1.Id+',NY,14624,NY,14625'+EmailServiceProcessorBatch.CRLF;
      testFile += acct2.Id+',MA,02101,MA,02111'+EmailServiceProcessorBatch.CRLF;
       
      DataLoad__c dl = new DataLoad__c(Name='TestUpdate',FileType__c=DataLoadMethods.TYPE_SF_UPDATE, UpdateAPIObjectName__c=ObjectHelper.OBJECT_ACCOUNT, Description__c='Because I want to');
      insert dl;
      String outputFileName = dl.Name+'.csv';
      AddFileQueueable afq = new AddFileQueueable(new Id[]{dl.Id}, outputFileName, outputFileName, null, Blob.valueOf(testFile));
      afq.processRecs();
       
      dl = getDataLoad(dl.Id);
      System.assertEquals(true,dl.FileLoaded__c);
      System.assertEquals(false,dl.FileParsed__c);
      System.assertEquals(5,dl.NbrHeaders__c);
      System.assertEquals(5,dl.NbrValidHeaders__c);
       
      Test.startTest();
      dl.Status__c = DataLoadMethods.STATUS_PARSE;
      update dl;
      Test.stopTest();
       
      dl = getDataLoad(dl.Id);
      System.assertEquals(DataLoadMethods.STATUS_FILE_PARSED,dl.Status__c);
      System.assertEquals(2,dl.NbrLoadRecords__c);
      System.assertEquals(2,dl.DataLoadRecords__r.size());
      System.assertEquals(1,dl.DataLoadRecords__r[0].RowNbr__c);
      System.assertEquals(2,dl.DataLoadRecords__r[1].RowNbr__c);
       

   } // testFileUpdate1

   // test the batch to perform the actual update
   static testMethod void testFileUpdate2() {
      // test updating 2 accounts
      Account acct1 = new Account(Name='Account 1');
      Account acct2 = new Account(Name='Account 2');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      Account[] accts = new Account[]{acct1,acct2};
      insert accts;
       
      String testFile = 'Id,Name,ShippingState,ShippingPostalCode,BillingState,BillingPostalCode'+EmailServiceProcessorBatch.CRLF;
      testFile += acct1.Id+',Account One,NY,14624,NY,14625'+EmailServiceProcessorBatch.CRLF;
      testFile += acct2.Id+',Account Two,MA,02101,MA,02111'+EmailServiceProcessorBatch.CRLF;
       
      DataLoad__c dl = new DataLoad__c(Name='TestUpdate',FileType__c=DataLoadMethods.TYPE_SF_UPDATE, UpdateAPIObjectName__c=ObjectHelper.OBJECT_ACCOUNT, Description__c='Because I want to too');
      insert dl;
      String outputFileName = dl.Name+'.csv';
      AddFileQueueable afq = new AddFileQueueable(new Id[]{dl.Id}, outputFileName, outputFileName, null, Blob.valueOf(testFile));
      afq.processRecs();
       
      dl = getDataLoad(dl.Id);
      System.assertEquals(true,dl.FileLoaded__c);
      System.assertEquals(false,dl.FileParsed__c);
      System.assertEquals(6,dl.NbrHeaders__c);
      System.assertEquals(6,dl.NbrValidHeaders__c);
       
      DataLoadRecord__c dlr1 = new DataLoadRecord__c(DataLoad__c=dl.Id, RowNbr__c=1, DataRow__c=acct1.Id+',Account One,NY,14624,NY,14625');
      DataLoadRecord__c dlr2 = new DataLoadRecord__c(DataLoad__c=dl.Id, RowNbr__c=2, DataRow__c=acct2.Id+',Account Two,MA,02101,MA,02111');
      DataLoadRecord__c[] dlrs = new DataLoadRecord__c[]{dlr1,dlr2};
      insert dlrs;  
        
      Test.startTest();
      dl.FileParsed__c = true;
      dl.Status__c = DataLoadMethods.STATUS_PROCESS;
      update dl;
      Test.stopTest();
       
      dl = getDataLoad(dl.Id);
      System.assertEquals(DataLoadMethods.STATUS_COMPLETE,dl.Status__c);

      System.assertEquals(2,dl.NbrLoadRecords__c);
      System.assertEquals(2,dl.DataLoadRecords__r.size());
      System.assertEquals(1,dl.DataLoadRecords__r[0].RowNbr__c);
      System.assertEquals(2,dl.DataLoadRecords__r[1].RowNbr__c);
       

      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, ShippingState, ShippingPostalCode,BillingState,BillingPostalCode from Account]);
      acct1 = acctMap.get(acct1.Id);
      System.assertEquals('Account One',acct1.Name);
      System.assertEquals('NY',acct1.ShippingState);
      System.assertEquals('14624',acct1.ShippingPostalCode);
      System.assertEquals('NY',acct1.BillingState);
      System.assertEquals('14625',acct1.BillingPostalCode);
       
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals('Account Two',acct2.Name);
      System.assertEquals('MA',acct2.ShippingState);
      System.assertEquals('02101',acct2.ShippingPostalCode);
      System.assertEquals('MA',acct2.BillingState);
      System.assertEquals('02111',acct2.BillingPostalCode);
       
   } // testFileUpdate2
    
   static testMethod void testLeadLoad1() {
      DataLoadApproval__c dla = new DataLoadApproval__c(Name='Lead Load', Active__c=true, FileTypes__c=DataLoadMethods.TYPE_LEAD_LIST);
      insert dla;
      
      Campaign camp = new Campaign(Name='Cool Campaign', IsActive=true, StartDate=Date.today() );
      insert camp;
       
      DataLoad__c dl = new DataLoad__c(Name='testLeadLoad1',FileType__c=DataLoadMethods.TYPE_LEAD_LIST, Campaign__c=camp.Id);
      insert dl;
      String outputFileName = dl.Name+'.csv';
      AddFileQueueable afq = new AddFileQueueable(new Id[]{dl.Id}, outputFileName, outputFileName, null, Blob.valueOf(goodLeadFile));
      afq.processRecs();
      dl = getDataLoad(dl.Id);
      System.assertEquals(DataLoadMethods.STATUS_READY,dl.Status__c);
      System.assertEquals(true,dl.FileLoaded__c);
       
      DataLoadRecord__c dlr1 = new DataLoadRecord__c(DataLoad__c=dl.Id, RowNbr__c=1, DataRow__c='John,Doe,5851112222,john@doe.com,john doe enterprises,123 Main St,Rochester, NY, 14624,7');
      DataLoadRecord__c dlr2 = new DataLoadRecord__c(DataLoad__c=dl.Id, RowNbr__c=2, DataRow__c='Jane,Smith,5852223333,jane@smith.com,"Jane Smith, LLC",234 Main St,Rochester,NY,14624,4');
      DataLoadRecord__c[] dlrs = new DataLoadRecord__c[]{dlr1,dlr2};
      insert dlrs;  

      // create a return validation message. Set the tags so the process builds the message.
      DataLoadMethods.DlrWrap wrap1 = new DataLoadMethods.DlrWrap(dlr1);
      wrap1.dataMap.put('SALES_LEAD_ID',dlr1.Id);
      wrap1.dataMap.put('LEAD_SALES_LEAD_ID',dlr1.Id);
      wrap1.dataMap.put('LEAD_DF_UID',dlr1.Id);
      wrap1.dataMap.put('EMAIL','john@doe.com');
      wrap1.dataMap.put('EMAIL_UPDATED','john@doe.com');
      wrap1.dataMap.put('LEAD_EMAIL_UPDATED','john@doe.com');
      wrap1.dataMap.put('COMPANY','john doe enterprises');
      wrap1.dataMap.put('COMPANY_UPDATED','john doe enterprises');
      wrap1.dataMap.put('LEAD_COMPANY_UPDATED','john doe enterprises');
      wrap1.dataMap.put('FIRSTNAME','John');
      wrap1.dataMap.put('LASTNAME','Doe');
      wrap1.dataMap.put('FIRSTNAME_UPDATED','John');
      wrap1.dataMap.put('LASTNAME_UPDATED','Doe');
      wrap1.dataMap.put('LEAD_FIRSTNAME_UPDATED','John');
      wrap1.dataMap.put('LEAD_LASTNAME_UPDATED','Doe');
      wrap1.dataMap.put('STREET','123 Main St');
      wrap1.dataMap.put('CITY','Rochester');
      wrap1.dataMap.put('STATE','NY');
      wrap1.dataMap.put('POSTALCODE','14624');
      wrap1.dataMap.put('ADDRESS_UPDATED','123 Main St');
      wrap1.dataMap.put('POSTALCODE_UPDATED','14624');
      wrap1.dataMap.put('CITY_UPDATED','Rochesterm');
      wrap1.dataMap.put('STATE_UPDATED','NY');
      wrap1.dataMap.put('LEAD_ADDRESS_UPDATED','123 Main St');
      wrap1.dataMap.put('LEAD_POSTALCODE_UPDATED','14624');
      wrap1.dataMap.put('LEAD_CITY_UPDATED','Rochesterm');
      wrap1.dataMap.put('LEAD_STATE_UPDATED','NY');
      wrap1.dataMap.put('PHONE','5851112222');
      wrap1.dataMap.put('PHONE_UPDATED','5851112222');
      wrap1.dataMap.put('LEAD_PHONE_UPDATED','5851112222');

      DataLoadMethods.DlrWrap wrap2 = new DataLoadMethods.DlrWrap(dlr2);
      wrap2.dataMap.put('SALES_LEAD_ID',dlr2.Id);
      wrap2.dataMap.put('LEAD_SALES_LEAD_ID',dlr2.Id);
      wrap2.dataMap.put('LEAD_DF_UID',dlr2.Id);
      wrap2.dataMap.put('EMAIL','jane@smith.com');
      wrap2.dataMap.put('EMAIL_UPDATED','jane@smith.com');
      wrap2.dataMap.put('LEAD_EMAIL_UPDATED','jane@smith.com');
      wrap2.dataMap.put('COMPANY','Jane Smith, LLC');
      wrap2.dataMap.put('COMPANY_UPDATED','Jane Smith, LLC');
      wrap2.dataMap.put('LEAD_COMPANY_UPDATED','Jane Smith, LLC');
      wrap2.dataMap.put('FIRSTNAME','Jane');
      wrap2.dataMap.put('LASTNAME','Smith');
      wrap2.dataMap.put('FIRSTNAME_UPDATED','Jane');
      wrap2.dataMap.put('LASTNAME_UPDATED','Smith');
      wrap2.dataMap.put('LEAD_FIRSTNAME_UPDATED','Jane');
      wrap2.dataMap.put('LEAD_LASTNAME_UPDATED','Smith');
      wrap2.dataMap.put('STREET','234 Main St');
      wrap2.dataMap.put('CITY','Rochester');
      wrap2.dataMap.put('STATE','NY');
      wrap2.dataMap.put('POSTALCODE','14624');
      wrap2.dataMap.put('ADDRESS_UPDATED','234 Main St');
      wrap2.dataMap.put('POSTALCODE_UPDATED','14624');
      wrap2.dataMap.put('CITY_UPDATED','Rochester');
      wrap2.dataMap.put('STATE_UPDATED','NY');
      wrap2.dataMap.put('LEAD_ADDRESS_UPDATED','234 Main St');
      wrap2.dataMap.put('LEAD_POSTALCODE_UPDATED','14624');
      wrap2.dataMap.put('LEAD_CITY_UPDATED','Rochester');
      wrap2.dataMap.put('LEAD_STATE_UPDATED','NY');
      wrap2.dataMap.put('PHONE','5852223333');
      wrap2.dataMap.put('PHONE_UPDATED','5852223333');
      wrap2.dataMap.put('LEAD_PHONE_UPDATED','5852223333');
       
      DataLoadMethods.DlrWrap[] wraps = new DataLoadMethods.DlrWrap[]{wrap1,wrap2};
       
      DataLoadMethods.getValueUseOtherMode = true;
      // create a message because we can't call the service 
      String returnValMsg = DataLoadMethods.buildMsg2(DataLoadMethods.VALIDATION_RESPONSE, DataLoadMethods.SERV_VALIDATION ,wraps);
      HttpResponse resp1 = new HttpResponse();
      resp1.setStatusCode(200);
      resp1.setBody(returnValMsg);
      resp1.setStatus('OK');
       
      // create a return match message.
      String returnLeadMsg = DataLoadMethods.buildMsg2(DataLoadMethods.LEAD_RESPONSE, DataLoadMethods.SERV_LEAD ,wraps);
      HttpResponse resp2 = new HttpResponse();
      resp2.setStatusCode(200);
      resp2.setBody(returnLeadMsg);
      resp2.setStatus('OK');

      System.debug('returnValMsg='+returnValMsg);
      System.debug('returnLeadMsg='+returnLeadMsg);

      DataLoadMethods.getValueUseOtherMode = false;
      // setup the test return messages
      DataLoadBatch2.testResp1 = resp1;
      DataLoadBatch2.testResp2 = resp2;
      
      Test.startTest();
      dl.FileParsed__c = true;
      dl.Status__c = DataLoadMethods.STATUS_PROCESS;
      update dl;
      Test.stopTest();
       
      dl = getDataLoad(dl.Id);
       
      Lead[] leads = [Select Id, Name, FirstName, Lastname, Company, Street, City, State, PostalCode, Dataflux_Id__c from Lead];
      System.assertEquals(2,leads.size());

      
   } // testLeadLoad1

   static testMethod void testRfrlLoad1() {
      DataLoadApproval__c dla = new DataLoadApproval__c(Name='Referral Load', Active__c=true, FileTypes__c=DataLoadMethods.TYPE_REF_SOURCE);
      insert dla;

      Campaign camp = new Campaign(Name='Cool Campaign', IsActive=true, StartDate=Date.today() );
      insert camp;

      DataLoad__c dl = new DataLoad__c(Name='testRfrlFile1',FileType__c=DataLoadMethods.TYPE_REF_SOURCE, Campaign__c=camp.Id);
      insert dl;
      String outputFileName = dl.Name+'.csv';
      AddFileQueueable afq = new AddFileQueueable(new Id[]{dl.Id}, outputFileName, outputFileName, null, Blob.valueOf(goodRfrlFile));
      afq.processRecs();
      dl = getDataLoad(dl.Id);
      System.assertEquals(DataLoadMethods.STATUS_READY,dl.Status__c);
      System.assertEquals(true,dl.FileLoaded__c);
      System.assertEquals(15,dl.NbrHeaders__c);
      System.assertEquals(14,dl.NbrValidHeaders__c);
       
      DataLoadRecord__c dlr1 = new DataLoadRecord__c(DataLoad__c=dl.Id, RowNbr__c=1, DataRow__c='John,Doe,5851112222,john@doe.com,john doe enterprises,123 Main St,Rochester, NY, 14624,Accounting Firm,,true,false,true,false');
      DataLoadRecord__c dlr2 = new DataLoadRecord__c(DataLoad__c=dl.Id, RowNbr__c=2, DataRow__c='Jane,Smith,5852223333,jane@smith.com,"Jane Smith, LLC",234 Main St,Rochester,NY,14624,Accounting Firm,,false,true,false,true');
      DataLoadRecord__c[] dlrs = new DataLoadRecord__c[]{dlr1,dlr2};
      insert dlrs;  

      // create a return validation message. Set the tags so the process builds the message.
      DataLoadMethods.DlrWrap wrap1 = new DataLoadMethods.DlrWrap(dlr1);
      wrap1.dataMap.put('ACCOUNT_SALES_LEAD_ID',dlr1.Id);
      wrap1.dataMap.put('CONTACT_SALES_LEAD_ID',dlr1.Id);
      wrap1.dataMap.put('ACCOUNT_DF_UID','ac'+dlr1.Id);
      wrap1.dataMap.put('CONTACT_DF_UID','ct'+dlr1.Id);
      wrap1.dataMap.put('CONTACT_EMAIL_UPDATED','john@doe.com');
      wrap1.dataMap.put('ACCOUNT_COMPANY_UPDATED','john doe enterprises');
      wrap1.dataMap.put('CONTACT_FIRSTNAME_UPDATED','John');
      wrap1.dataMap.put('CONTACT_LASTNAME_UPDATED','Doe');
      wrap1.dataMap.put('ACCOUNT_ADDRESS_UPDATED','123 Main St');
      wrap1.dataMap.put('ACCOUNT_POSTALCODE_UPDATED','14624');
      wrap1.dataMap.put('ACCOUNT_CITY_UPDATED','Rochester');
      wrap1.dataMap.put('ACCOUNT_STATE_UPDATED','NY');
      wrap1.dataMap.put('ACCOUNT_PHONE_UPDATED','5851112222');
      wrap1.dataMap.put('CONTACT_PHONE_UPDATED','5851112222');

      DataLoadMethods.DlrWrap wrap2 = new DataLoadMethods.DlrWrap(dlr2);
      wrap2.dataMap.put('ACCOUNT_SALES_LEAD_ID',dlr2.Id);
      wrap2.dataMap.put('CONTACT_SALES_LEAD_ID',dlr2.Id);
      wrap2.dataMap.put('ACCOUNT_DF_UID','ac'+dlr2.Id);
      wrap2.dataMap.put('CONTACT_DF_UID','ct'+dlr2.Id);
      wrap2.dataMap.put('CONTACT_EMAIL_UPDATED','jane@smith.com');
      wrap2.dataMap.put('ACCOUNT_COMPANY_UPDATED','Jane Smith, LLC');
      wrap2.dataMap.put('CONTACT_FIRSTNAME_UPDATED','Jane');
      wrap2.dataMap.put('CONTACT_LASTNAME_UPDATED','Smith');
      wrap2.dataMap.put('ACCOUNT_ADDRESS_UPDATED','234 Main St');
      wrap2.dataMap.put('ACCOUNT_POSTALCODE_UPDATED','14624');
      wrap2.dataMap.put('ACCOUNT_CITY_UPDATED','Rochester');
      wrap2.dataMap.put('ACCOUNT_STATE_UPDATED','NY');
      wrap2.dataMap.put('ACCOUNT_PHONE_UPDATED','5852223333');
      wrap2.dataMap.put('CONTACT_PHONE_UPDATED','5852223333');
       
      DataLoadMethods.DlrWrap[] wraps = new DataLoadMethods.DlrWrap[]{wrap1,wrap2};

      DataLoadMethods.getValueUseOtherMode = true;
      // create a message because we can't call the service 
      String returnValMsg = DataLoadMethods.buildMsg2(DataLoadMethods.REFERRAL_RESPONSE, DataLoadMethods.SERV_REF_SRC ,wraps);
      HttpResponse resp1 = new HttpResponse();
      resp1.setStatusCode(200);
      resp1.setBody(returnValMsg);
      resp1.setStatus('OK');

      DataLoadMethods.getValueUseOtherMode = false;
      // setup the test return messages
      DataLoadBatch2.testResp1 = resp1;
      //DataLoadBatch2.testResp2 = resp2;
      
      Test.startTest();
      dl.FileParsed__c = true;
      dl.Status__c = DataLoadMethods.STATUS_PROCESS;
      update dl;
      Test.stopTest();
       
      dl = getDataLoad(dl.Id);
       
      Referral_Account__c[] refAccts = [select Id, Name, Street_Address_1__c,City__c, State_Province__c, Zip_Postal_Code__c, Referral_Source_Business_Type__c, Dataflux_Id__c, Sensitivity_401_k__c, Sensitivity_FSA__c 
                                          from Referral_Account__c ];
      System.assertEquals(2,refAccts.size());
      Referral_Account__c refAcct1 = null;
      Referral_Account__c refAcct2 = null;
      for (Referral_Account__c refAcct : refAccts) {
          if (refAcct.Dataflux_Id__c == 'ac'+String.valueOf(dlr1.Id)) {
             refAcct1 = refAcct;
          } else if (refAcct.Dataflux_Id__c == 'ac'+String.valueOf(dlr2.Id)) {
             refAcct2 = refAcct;
          }
      } // for
      System.assertNotEquals(null,refAcct1);
      //John,Doe,5851112222,john@doe.com,john doe enterprises,123 Main St,Rochester, NY, 14624,Accounting Firm
      System.assertEquals('john doe enterprises',refAcct1.Name);
      System.assertEquals('123 Main St',refAcct1.Street_Address_1__c);
      System.assertEquals('Rochester',refAcct1.City__c);
      System.assertEquals('NY',refAcct1.State_Province__c);
      System.assertEquals('14624',refAcct1.Zip_Postal_Code__c);
      System.assertEquals('Accounting Firm',refAcct1.Referral_Source_Business_Type__c);
      System.assertEquals(true,refAcct1.Sensitivity_401_k__c);
      System.assertEquals(true,refAcct1.Sensitivity_FSA__c);

      System.assertNotEquals(null,refAcct2);
      //Jane,Smith,5852223333,jane@smith.com,"Jane Smith, LLC",234 Main St,Rochester,NY,14624,Accounting Firm
      System.assertEquals('Jane Smith, LLC',refAcct2.Name);
      System.assertEquals('234 Main St',refAcct2.Street_Address_1__c);
      System.assertEquals('Rochester',refAcct2.City__c);
      System.assertEquals('NY',refAcct2.State_Province__c);
      System.assertEquals('14624',refAcct2.Zip_Postal_Code__c);
      System.assertEquals('Accounting Firm',refAcct2.Referral_Source_Business_Type__c);
      System.assertEquals(false,refAcct2.Sensitivity_401_k__c);
      System.assertEquals(false,refAcct2.Sensitivity_FSA__c);

      Referral_Contact__c[] refCtcts = [Select Id, Name, First_Name__c, Last_Name__c, Email__c, Referral_Account__c, Dataflux_Id__c, Phone__c, Sensitivity_401_k__c, Sensitivity_FSA__c 
                                          from Referral_Contact__c];
      System.assertEquals(2,refCtcts.size());
      Referral_Contact__c refCtct1 = null;
      Referral_Contact__c refCtct2 = null;
      for (Referral_Contact__c refCtct : refCtcts) {
         if (refCtct.Dataflux_Id__c == 'ct'+dlr1.Id) {
            refCtct1 = refCtct;
         } else if (refCtct.Dataflux_Id__c == 'ct'+dlr2.Id) {
            refCtct2 = refCtct;
         }
      }
      System.assertNotEquals(null,refCtct1);
      //John,Doe,5851112222,john@doe.com,john doe enterprises,123 Main St,Rochester, NY, 14624,Accounting Firm
      System.assertEquals('John Doe',refCtct1.Name);
      System.assertEquals('John',refCtct1.First_Name__c);
      System.assertEquals('Doe',refCtct1.Last_Name__c);
      System.assertEquals('john@doe.com',refCtct1.Email__c);
      System.assertEquals('(585) 111-2222',refCtct1.Phone__c);
      System.assertEquals(false,refCtct1.Sensitivity_401_k__c);
      System.assertEquals(false,refCtct1.Sensitivity_FSA__c);
       
      System.assertNotEquals(null,refCtct2);
      //Jane,Smith,5852223333,jane@smith.com,"Jane Smith, LLC",234 Main St,Rochester,NY,14624,Accounting Firm
      System.assertEquals('Jane Smith',refCtct2.Name);
      System.assertEquals('Jane',refCtct2.First_Name__c);
      System.assertEquals('Smith',refCtct2.Last_Name__c);
      System.assertEquals('jane@smith.com',refCtct2.Email__c);
      System.assertEquals('(585) 222-3333',refCtct2.Phone__c);
      System.assertEquals(true,refCtct2.Sensitivity_401_k__c);
      System.assertEquals(true,refCtct2.Sensitivity_FSA__c);
      
      
   } // testRfrlLoad1
    
   static testMethod void testInlineInsert() {
      // insert 1 account to link the contacts to
      Account acct1 = new Account(Name='Account 1');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      Account[] accts = new Account[]{acct1};
      insert accts;
       
      String testFile = 'FirstName,LastName,AccountId,Title'+EmailServiceProcessorBatch.CRLF;
      testFile += 'Billy,Joel,'+acct1.Id+',Singer'+EmailServiceProcessorBatch.CRLF;
      testFile += 'Elton,John,'+acct1.Id+',Singer'+EmailServiceProcessorBatch.CRLF;
      testFile += 'Billy,Crystal,'+acct1.Id+',Actor'+EmailServiceProcessorBatch.CRLF;
       
      DataLoad__c dl = new DataLoad__c(Name='TestUpdate',FileType__c=DataLoadMethods.TYPE_SF_INSERT, UpdateAPIObjectName__c=ObjectHelper.OBJECT_CONTACT, Description__c='I need to add some contacts');
      insert dl;
      String outputFileName = dl.Name+'.csv';
      AddFileQueueable afq = new AddFileQueueable(new Id[]{dl.Id}, outputFileName, outputFileName, null, Blob.valueOf(testFile));
      afq.processRecs();
       
      dl = getDataLoad(dl.Id);
      System.assertEquals(true,dl.FileLoaded__c);
      System.assertEquals(false,dl.FileParsed__c);
      System.assertEquals(4,dl.NbrHeaders__c);
      System.assertEquals(4,dl.NbrValidHeaders__c);
       
      DataLoadRecord__c dlr1 = new DataLoadRecord__c(DataLoad__c=dl.Id, RowNbr__c=1, DataRow__c='Billy,Joel,'+acct1.Id+',Singer');
      DataLoadRecord__c dlr2 = new DataLoadRecord__c(DataLoad__c=dl.Id, RowNbr__c=2, DataRow__c='Elton,John,'+acct1.Id+',Singer');
      DataLoadRecord__c dlr3 = new DataLoadRecord__c(DataLoad__c=dl.Id, RowNbr__c=3, DataRow__c='Tom,Hanks,'+acct1.Id+',Actor');
      DataLoadRecord__c[] dlrs = new DataLoadRecord__c[]{dlr1,dlr2,dlr3};
      insert dlrs;  
        
      Test.startTest();
      dl.FileParsed__c = true;
      dl.Status__c = DataLoadMethods.STATUS_PROCESS;
      update dl;
      Test.stopTest();
       
      dl = getDataLoad(dl.Id);
      System.assertEquals(DataLoadMethods.STATUS_COMPLETE,dl.Status__c);

      System.assertEquals(3,dl.NbrLoadRecords__c);
      System.assertEquals(3,dl.DataLoadRecords__r.size());
      System.assertEquals(1,dl.DataLoadRecords__r[0].RowNbr__c);
      System.assertEquals(2,dl.DataLoadRecords__r[1].RowNbr__c);
      System.assertEquals(3,dl.DataLoadRecords__r[2].RowNbr__c);
       
      Contact[] ctcts = [Select id, FirstName, LastName, Title, AccountId from Contact where AccountId=:acct1.Id];
      System.assertEquals(3,ctcts.size());
      Contact ctct1=null;
      Contact ctct2=null;
      Contact ctct3=null;
      for (Contact ctct : ctcts) {
         if (ctct.FirstName == 'Billy') {
            ctct1 = ctct;
            System.assertEquals('Joel',ctct.LastName);
            System.assertEquals('Singer',ctct.Title);
         } else if (ctct.FirstName == 'Elton') {
            ctct2 = ctct;
            System.assertEquals('John',ctct.LastName);
            System.assertEquals('Singer',ctct.Title);
         } else if (ctct.FirstName == 'Tom') {
            ctct3 = ctct;
            System.assertEquals('Hanks',ctct.LastName);
            System.assertEquals('Actor',ctct.Title);
         } else {
            System.assertEquals(1,2,'Should never get here');
         }
      } // for (Contact ctct
      System.assertNotEquals(null,ctct1);
      System.assertNotEquals(null,ctct2);
      System.assertNotEquals(null,ctct3);

       
   } // testInlineInsert
    
   static testMethod void testBulkSubmit() {
      Datetime nextRunTime = Datetime.now().addMinutes(-1);
      // create 3 DataLoad__c records to represent the three different stages - submit, check, retrieve results
      DataLoad__c dl1 = new DataLoad__c(Name='DataLoad1', FileType__c=DataLoadMethods.TYPE_SF_INSERT_BULK, UpdateAPIObjectName__c=ObjectHelper.OBJECT_LEAD, Status__c=DataLoadMethods.STATUS_PROCESS_BULK, Description__c='DataLoad1', BulkNextRunTime__c=nextRunTime);
      DataLoad__c[] dataLoads = new DataLoad__c[]{dl1};
      // insert the records, but skip the triggers for now. I need to insert a file against one of the records.
      DataLoadMethods.SKIP_TRIGGER = true;
      insert dataLoads;
      
      ContentDocumentUtilities.SKIP_TRIGGER=true;
      String outputFileName = dl1.Name+'.csv';
      AddFileQueueable afq = new AddFileQueueable(new Id[]{dl1.Id}, outputFileName, outputFileName, null, Blob.valueOf(goodLeadFile));
      afq.processRecs();

      BulkAPIMock.MOCK_VERSION = BulkAPIMock.MOCK1;
      User runningUser = UserHelper.getRunningUser();
      System.runAs(runningUser) {
         Test.startTest();
         Test.setMock(HttpCalloutMock.class, new BulkAPIMock()); 
         DataLoadBatch3.launchBatch(); 
       
         Test.stopTest();
      }
      dl1 = [select Id, Status__c from DataLoad__c where Id=:dl1.Id];
      System.assertEquals(DataLoadMethods.STATUS_BULK_SUBMITTED, dl1.Status__c);
   } // testBulkSubmit
    
   static testMethod void testBulkSubmitQueueable() {
      Datetime nextRunTime = Datetime.now().addMinutes(-1);
      // create 3 DataLoad__c records to represent the three different stages - submit, check, retrieve results
      DataLoad__c dl1 = new DataLoad__c(Name='DataLoad1', FileType__c=DataLoadMethods.TYPE_SF_INSERT_BULK, UpdateAPIObjectName__c=ObjectHelper.OBJECT_LEAD, Status__c=DataLoadMethods.STATUS_PROCESS_BULK, Description__c='DataLoad1', BulkNextRunTime__c=nextRunTime);
      DataLoad__c[] dataLoads = new DataLoad__c[]{dl1};
      // insert the records, but skip the triggers for now. I need to insert a file against one of the records.
      DataLoadMethods.SKIP_TRIGGER = true;
      insert dataLoads;
      
      ContentDocumentUtilities.SKIP_TRIGGER=true;
      String outputFileName = dl1.Name+'.csv';
      AddFileQueueable afq = new AddFileQueueable(new Id[]{dl1.Id}, outputFileName, outputFileName, null, Blob.valueOf(goodLeadFile));
      afq.processRecs();

      BulkAPIMock.MOCK_VERSION = BulkAPIMock.MOCK1;
      User runningUser = UserHelper.getRunningUser();
      System.runAs(runningUser) {
         Test.startTest();
         Test.setMock(HttpCalloutMock.class, new BulkAPIMock()); 
         DataLoadQueueable.checkLaunchQueuable(dl1.Id); 
         Test.stopTest();
      }
      dl1 = [select Id, Status__c from DataLoad__c where Id=:dl1.Id];
      System.assertEquals(DataLoadMethods.STATUS_BULK_SUBMITTED, dl1.Status__c);
   } // testBulkSubmitQueueable
    
   static testMethod void testBulkCheckStatus() {
      Datetime nextRunTime = Datetime.now().addMinutes(-1);
      // create 3 DataLoad__c records to represent the three different stages - submit, check, retrieve results
      DataLoad__c dl2 = new DataLoad__c(Name='DataLoad2', FileType__c=DataLoadMethods.TYPE_SF_INSERT_BULK, UpdateAPIObjectName__c=ObjectHelper.OBJECT_LEAD, Status__c=DataLoadMethods.STATUS_BULK_SUBMITTED, Description__c='DataLoad1', BulkNextRunTime__c=nextRunTime);
      DataLoad__c[] dataLoads = new DataLoad__c[]{dl2};
      // insert the records, but skip the triggers for now. I need to insert a file against one of the records.
      DataLoadMethods.SKIP_TRIGGER = true;
      insert dataLoads;
       
      BulkAPIMock.MOCK_VERSION = BulkAPIMock.MOCK2;
      Test.setMock(HttpCalloutMock.class, new BulkAPIMock()); 

      Test.startTest();
      DataLoadBatch3.launchBatch(); 
       
      Test.stopTest();
          
   } // testBulkCheckStatus
    
   static testMethod void testBulkCheckFailure() {
      Datetime nextRunTime = Datetime.now().addMinutes(-1);
      // create 3 DataLoad__c records to represent the three different stages - submit, check, retrieve results
      DataLoad__c dl2 = new DataLoad__c(Name='DataLoad2', FileType__c=DataLoadMethods.TYPE_SF_INSERT_BULK, UpdateAPIObjectName__c=ObjectHelper.OBJECT_LEAD, Status__c=DataLoadMethods.STATUS_BULK_SUBMITTED, Description__c='DataLoad1', BulkNextRunTime__c=nextRunTime);
      DataLoad__c[] dataLoads = new DataLoad__c[]{dl2};
      // insert the records, but skip the triggers for now. I need to insert a file against one of the records.
      DataLoadMethods.SKIP_TRIGGER = true;
      insert dataLoads;
       
      BulkAPIMock.MOCK_VERSION = BulkAPIMock.MOCK2a;
      Test.setMock(HttpCalloutMock.class, new BulkAPIMock()); 

      Test.startTest();
      DataLoadBatch3.launchBatch(); 
       
      Test.stopTest();
          
      dl2 = [Select id, BulkJobStatus__c from DataLoad__c where Id=:dl2.Id];
      System.assertEquals(BulkApiHelper.STATE_FAILED,dl2.BulkJobStatus__c);
   } // testBulkCheckStatus
    
   static testMethod void testBulkCheckComplete() {
      Datetime nextRunTime = Datetime.now().addMinutes(-1);
      // create 3 DataLoad__c records to represent the three different stages - submit, check, retrieve results
      DataLoad__c dl2 = new DataLoad__c(Name='DataLoad2', FileType__c=DataLoadMethods.TYPE_SF_INSERT_BULK, UpdateAPIObjectName__c=ObjectHelper.OBJECT_LEAD, Status__c=DataLoadMethods.STATUS_BULK_SUBMITTED, Description__c='DataLoad1', BulkNextRunTime__c=nextRunTime);
      DataLoad__c[] dataLoads = new DataLoad__c[]{dl2};
      // insert the records, but skip the triggers for now. I need to insert a file against one of the records.
      DataLoadMethods.SKIP_TRIGGER = true;
      insert dataLoads;
       
      BulkAPIMock.MOCK_VERSION = BulkAPIMock.MOCK2b;
      Test.setMock(HttpCalloutMock.class, new BulkAPIMock()); 

      Test.startTest();
      DataLoadBatch3.launchBatch(); 
       
      Test.stopTest();
          
      dl2 = [Select id, BulkJobStatus__c from DataLoad__c where Id=:dl2.Id];
      System.assertEquals(BulkApiHelper.STATE_COMPLETE,dl2.BulkJobStatus__c);
   } // testBulkCheckStatus
    
   static testMethod void testBulkGetResults() {
      Datetime nextRunTime = Datetime.now();
      // create 3 DataLoad__c records to represent the three different stages - submit, check, retrieve results
      DataLoad__c dl3 = new DataLoad__c(Name='DataLoad3', FileType__c=DataLoadMethods.TYPE_SF_UPDATE_BULK, UpdateAPIObjectName__c=ObjectHelper.OBJECT_LEAD, Status__c=DataLoadMethods.STATUS_BULK_COMPLETE, Description__c='DataLoad1', BulkNextRunTime__c=nextRunTime);
      DataLoad__c[] dataLoads = new DataLoad__c[]{dl3};
      // insert the records, but skip the triggers for now. I need to insert a file against one of the records.
      DataLoadMethods.SKIP_TRIGGER = true;
      insert dataLoads;
       
      BulkAPIMock.MOCK_VERSION = BulkAPIMock.MOCK3;
      Test.setMock(HttpCalloutMock.class, new BulkAPIMock()); 

      Test.startTest();
      DataLoadBatch3.launchBatch(); 
       
      Test.stopTest();
          
   } // testBulkGetResults
    
   static testMethod void testScheduleBatch2() {
      TestHelper.testScheduler(DataLoadBatch2.CLASSNAME, new DataLoadBatch2());
   }

   static testMethod void testScheduleBatch3() {
      TestHelper.testScheduler(DataLoadBatch3.CLASSNAME, new DataLoadBatch3());
   }

} // class DataLoadTest