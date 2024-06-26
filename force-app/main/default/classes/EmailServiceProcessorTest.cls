/**
 * This is part of several classes that work together to process email attachments and insert records into Salesforce.
 * This is the test class for:
 * EmailServiceInput
 * EmailServiceProcessor
 * EmailServiceProcessorBatch
 * CSVIterator
 * Created Justin Stouffer 8/19/2015

  History
  -------
  08/19/2015 Justin Stouffer Created
  02/10/2016 Dan Carmen      Code modifications for SRR
  02/27/2016 Dan Carmen      Additional changes to handle no matching file setting
  11/02/2016 Justin Stouffer Updated CSVIterator to handle line splitting more efficiently.
  02/24/2020 Dan Carmen        Increment API version
  12/28/2020 Dan Carmen        Increment API to get rid of Missing dependent object: Field: Case.ServiceContractId error

 */
@isTest
private class EmailServiceProcessorTest {

   static testMethod void testNoUploadSettings() {
      User runningUser = UserHelper.getRunningUser();
      messaging.Inboundemail email = new messaging.Inboundemail();
      email.plainTextBody = '9999-99-90';
      email.fromAddress = runningUser.Email;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      EmailServiceInput eSI = new EmailServiceInput();
      Test.startTest();
      eSI.handleInboundEmail(email, env);
      Test.stopTest();
      System.assertEquals('No Email_File_Upload_Settings__c found', EmailServiceProcessor.processResult);
   } // testNoUploadSettings

   static testMethod void testNoFile() {
      User runningUser = UserHelper.getRunningUser();
      createTestData.createTestAandC();
      EmailServiceProcessorTest.createEmailFileUploadCS();
      messaging.Inboundemail email = new messaging.Inboundemail();
      email.plainTextBody = '9999-99-90';
      email.fromAddress = runningUser.Email;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      EmailServiceInput eSI = new EmailServiceInput();
      Test.startTest();
      eSI.handleInboundEmail(email, env);
      Test.stopTest();
      list<case> testCaseList =[select id from case where createdDate = TODAY];
      system.assert(testCaseList.isEmpty());
      System.assertEquals('No files attached', EmailServiceProcessor.processResult);
   } // testNoFile
    
   static testMethod void testNoCSV() {
      User runningUser = UserHelper.getRunningUser();
      createTestData.createTestAandC();
      EmailServiceProcessorTest.createEmailFileUploadCS();
      messaging.Inboundemail email = new messaging.Inboundemail();
      email.plainTextBody = '9999-99-90';
      email.fromAddress = runningUser.Email;
      messaging.Inboundemail.BinaryAttachment attch = new messaging.Inboundemail.BinaryAttachment();
      attch.body = Blob.valueOf(createCSV(FALSE));
      attch.fileName = 'myFile.txt';
      email.BinaryAttachments = new list<messaging.Inboundemail.BinaryAttachment>();
      email.BinaryAttachments.add(attch);
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      EmailServiceInput eSI = new EmailServiceInput();
      Test.startTest();
      eSI.handleInboundEmail(email, env);
      Test.stopTest();
      list<case> testCaseList =[select id from case where createdDate = TODAY];
      system.assert(testCaseList.isEmpty());    
      System.assertEquals('No csv files attached', EmailServiceProcessor.processResult);
   } // testNoCSV
    
   static testMethod void testBatchKickOff(){
      User runningUser = UserHelper.getRunningUser();
      createTestData.createTestAandC();
      EmailServiceProcessorTest.createEmailFileUploadCS();
      list<account> testAccountList = [select id, BIS_ID__c, AccountNumber from account where createdDate = TODAY];
      testAccountList[0].BIS_ID__c = 1;
      testAccountList[0].AccountNumber = '11-1111';
      testAccountList[1].BIS_ID__c = 2;
      testAccountList[1].AccountNumber = '22-2222';
      update testAccountList;
      messaging.Inboundemail email = new messaging.Inboundemail();
      email.plainTextBody = '9999-99-90';
      email.fromAddress = runningUser.Email;
      messaging.Inboundemail.BinaryAttachment attch = new messaging.Inboundemail.BinaryAttachment();
      attch.body = Blob.valueOf(createCSV(FALSE));
      attch.fileName = 'myFile.csv';
      email.BinaryAttachments = new list<messaging.Inboundemail.BinaryAttachment>();
      email.BinaryAttachments.add(attch);
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      EmailServiceInput eSI = new EmailServiceInput();
      Test.startTest();
      eSI.handleInboundEmail(email, env);
      emailServiceProcessor.kickOffBatchJob(null);
        list<AsyncApexJob> asyncJobList = [SELECT id
                                                 FROM AsyncApexJob 
                                                WHERE ApexClass.Name='EmailServiceProcessorBatch'];
      Test.stopTest();
      system.AssertEquals(asyncJobList.size(),1);
   } // testBatchKickOff
    
   static testMethod void testGoodCSVSingleMatch() {
      User runningUser = UserHelper.getRunningUser();
      createTestData.createTestAandC();
      EmailServiceProcessorTest.createEmailFileUploadCS();
      list<account> testAccountList = [select id, BIS_ID__c, AccountNumber from account where createdDate = TODAY];
      testAccountList[0].BIS_ID__c = 1;
      testAccountList[0].AccountNumber = '11-1111';
      testAccountList[1].BIS_ID__c = 2;
      testAccountList[1].AccountNumber = '22-2222';
      update testAccountList;
      messaging.Inboundemail email = new messaging.Inboundemail();
      email.plainTextBody = '9999-99-90';
      email.fromAddress = runningUser.Email;
      messaging.Inboundemail.BinaryAttachment attch = new messaging.Inboundemail.BinaryAttachment();
      attch.body = Blob.valueOf(createCSV(FALSE));
      attch.fileName = 'myFile.csv';
      email.BinaryAttachments = new list<messaging.Inboundemail.BinaryAttachment>();
      email.BinaryAttachments.add(attch);
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      EmailServiceInput eSI = new EmailServiceInput();
      Test.startTest();
        eSI.handleInboundEmail(email, env);
        Web_Service_Log__c wsl =[Select Id, Successful__c
                    from Web_Service_Log__c 
                    Where ServiceName__c = :EmailServiceProcessor.SERVICE_NAME 
                    and Successful__c = FALSE
                    order by createdDate ASC limit 1];
        Test.stopTest();
        wsl =[Select Id, Successful__c
                from Web_Service_Log__c 
                Where id=:wsl.id];
      list<case> testCaseList =[select id from case where createdDate = TODAY];
      system.assert(wsl.Successful__c == TRUE);
      system.assertEquals(testCaseList.size(),2);
   } // testGoodCSVSingleMatch

   /* static testMethod void testGoodCSVMultiMatch() {
        createTestData.createTestAandC();
        EmailServiceProcessorTest.createEmailFileUploadCS();
        list<account> testAccountList = [select id, BIS_ID__c, AccountNumber from account where createdDate = TODAY];
        testAccountList[0].BIS_ID__c = 1;
        testAccountList[0].AccountNumber = '11-1111';
        testAccountList[1].BIS_ID__c = 2;
        testAccountList[1].AccountNumber = '22-2222';
        testAccountList[2].BIS_ID__c = 3;
        testAccountList[2].AccountNumber = '22-2222';
        update testAccountList;
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '9999-99-91';
        email.fromAddress = 'jstouffer@paychex.com';
        messaging.Inboundemail.BinaryAttachment attch = new messaging.Inboundemail.BinaryAttachment();
        attch.body = Blob.valueOf(createCSV(FALSE));
        attch.fileName = 'myFile.csv';
        email.BinaryAttachments = new list<messaging.Inboundemail.BinaryAttachment>();
        email.BinaryAttachments.add(attch);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        EmailServiceInput eSI = new EmailServiceInput();
        Test.startTest();
        eSI.handleInboundEmail(email, env);
        Web_Service_Log__c wsl =[Select Id, Successful__c
                    from Web_Service_Log__c 
                    Where ServiceName__c = :EmailServiceProcessor.SERVICE_NAME 
                    and Successful__c = FALSE
                    order by createdDate ASC limit 1];
        Test.stopTest();
        wsl =[Select Id, Successful__c
                    from Web_Service_Log__c 
                    Where id=:wsl.id];
        list<case> testCaseList =[select id from case where createdDate = TODAY];
        system.assert(wsl.Successful__c == TRUE);
        system.assertEquals(testCaseList.size(),3);
    }*/

   static testMethod void testGoodCSVNoMultiMatch() {
      User runningUser = UserHelper.getRunningUser();
      createTestData.createTestAandC();
      EmailServiceProcessorTest.createEmailFileUploadCS();
      Email_File_Upload_Settings__c eFUS = Email_File_Upload_Settings__c.getInstance('Support Case Upload2');
      eFUS.Allow_Multiple_Matches__c = FALSE;
      update eFUS;
      list<account> testAccountList = [select id, BIS_ID__c, AccountNumber from account where createdDate = TODAY];
      testAccountList[0].BIS_ID__c = 1;
      testAccountList[0].AccountNumber = '11-1111';
      testAccountList[1].BIS_ID__c = 2;
      testAccountList[1].AccountNumber = '22-2222';
      //testAccountList[2].BIS_ID__c = 3;
      //testAccountList[2].AccountNumber = '22-2222';
      update testAccountList;
      messaging.Inboundemail email = new messaging.Inboundemail();
      email.plainTextBody = '9999-99-91';
      email.fromAddress = runningUser.Email;
      messaging.Inboundemail.BinaryAttachment attch = new messaging.Inboundemail.BinaryAttachment();
      attch.body = Blob.valueOf(createCSV(FALSE));
      attch.fileName = 'myFile.csv';
      email.BinaryAttachments = new list<messaging.Inboundemail.BinaryAttachment>();
      email.BinaryAttachments.add(attch);
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      EmailServiceInput eSI = new EmailServiceInput();
      Test.startTest();
        eSI.handleInboundEmail(email, env);
        Web_Service_Log__c wsl =[Select Id, Successful__c
                    from Web_Service_Log__c 
                    Where ServiceName__c = :EmailServiceProcessor.SERVICE_NAME 
                    and Successful__c = FALSE
                    order by createdDate ASC limit 1];
        Test.stopTest();
        wsl =[Select Id, Successful__c
                    from Web_Service_Log__c 
                    Where id=:wsl.id];
      list<case> testCaseList =[select id, accountId, description from case where createdDate = TODAY];
      system.assert(wsl.Successful__c == TRUE);
      system.assertEquals(2,testCaseList.size());
      Boolean acct1Matched = false;
      Boolean acct2Matched = false;
      for (Case cs : testCaseList) {
         if (cs.AccountId == testAccountList[0].Id) {
            acct1Matched = true;
            System.assertEquals(null,cs.Description);
         } else if (cs.AccountId == testAccountList[1].Id) {
            acct2Matched = true;
            System.assertEquals(null,cs.Description);
         }
      } // for (Case cs
      System.assertEquals(true,acct1Matched);
      System.assertEquals(true,acct2Matched);
   } // testGoodCSVNoMultiMatch

   static testMethod void testBigCSVSingleMatch() {
      User runningUser = UserHelper.getRunningUser();
      createTestData.createTestAandC();
      EmailServiceProcessorTest.createEmailFileUploadCS();
      EmailServiceProcessor.runningBigTest = TRUE;
      list<account> testAccountList = [select id, BIS_ID__c, AccountNumber from account where createdDate = TODAY];
      testAccountList[0].BIS_ID__c = 1;
      testAccountList[0].AccountNumber = '11-1111';
      testAccountList[1].BIS_ID__c = 2;
      testAccountList[1].AccountNumber = '22-2222';
      update testAccountList;
      messaging.Inboundemail email = new messaging.Inboundemail();
      email.plainTextBody = '9999-99-90';
      email.fromAddress = runningUser.Email;
      messaging.Inboundemail.BinaryAttachment attch = new messaging.Inboundemail.BinaryAttachment();
      attch.body = Blob.valueOf(createCSV(TRUE));
      attch.fileName = 'myFile.csv';
      email.BinaryAttachments = new list<messaging.Inboundemail.BinaryAttachment>();
      email.BinaryAttachments.add(attch);
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      EmailServiceInput eSI = new EmailServiceInput();
      eSI.handleInboundEmail(email, env);
      list<Web_Service_Log__c> wsl =[Select Id, Successful__c
                    from Web_Service_Log__c 
                    Where ServiceName__c = :EmailServiceProcessor.SERVICE_NAME 
                    and Successful__c = FALSE
                    order by createdDate ASC];
      system.assertEquals(wsl.size(),2);            
   } // testBigCSVSingleMatch
    
   static testMethod void testException() {
      User runningUser = UserHelper.getRunningUser();
      createTestData.createTestAandC();
      EmailServiceProcessorTest.createEmailFileUploadCS();
      list<account> testAccountList = [select id, BIS_ID__c, AccountNumber from account where createdDate = TODAY];
      testAccountList[0].BIS_ID__c = 1;
      testAccountList[0].AccountNumber = '11-1111';
      update testAccountList;
      Email_File_Upload_Settings__c eFUS = Email_File_Upload_Settings__c.getInstance('Support Case Upload2');
      eFUS.Require_Field_To_Update__c = FALSE;
      update eFUS;
      messaging.Inboundemail email = new messaging.Inboundemail();
      email.plainTextBody = '9999-99-90';
      email.fromAddress = runningUser.Email;
      messaging.Inboundemail.BinaryAttachment attch = new messaging.Inboundemail.BinaryAttachment();
      string body = createCSV(FALSE)+'"this, is test blank",,\r\n';
      body += 'This is a long string that is greater than 255 characters. This should be long enough to cause an error and break the case insert.';
      body += 'It will repeat until it exceeds the character limit. This is a long string that is greater than 255 characters. This should be long enough to cause an error.';
      body += ',2,22-2222\r\n';
      attch.body = Blob.valueOf(body);
      attch.fileName = 'myFile.csv';
      email.BinaryAttachments = new list<messaging.Inboundemail.BinaryAttachment>();
      email.BinaryAttachments.add(attch);
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      EmailServiceInput eSI = new EmailServiceInput();
      Test.startTest();
      eSI.handleInboundEmail(email, env);
      Web_Service_Log__c wsl =[Select Id, Successful__c
                    from Web_Service_Log__c 
                    Where ServiceName__c = :EmailServiceProcessor.SERVICE_NAME
                    and Successful__c = FALSE
                    order by createdDate ASC limit 1];
        Test.stopTest();
        wsl =[Select Id, Successful__c
                from Web_Service_Log__c 
                Where id=:wsl.id];
      list<case> testCaseList =[select id, Description from case where createdDate = TODAY];
      system.assert(wsl.Successful__c == FALSE);
      system.assertEquals(3,testCaseList.size());
      System.assertEquals('Description',testCaseList[0].Description);
   } // testException

   public static void createEmailFileUploadCS(){
      insert new Apex_Batch_Control__c(Name = EmailServiceProcessor.BATCH_CONTROL_NAME, Active__c = TRUE);
      Email_File_Upload_Settings__c efus1 = new Email_File_Upload_Settings__c(Name='Support Case Upload',
                                                        Active__c = TRUE,
                                                        ID_Key__c = '9999-99-90',
                                                        NbrAttempts__c = 3,
                                                        //Query_Field_1__c = 'BIS_ID__c',
                                                        //Query__c = 'Select Id, BIS_ID__c, AccountNumber from Account where ',
                                                        //Field_To_Update__c = 'AccountId',
                                                        Object_Type__c = 'Case',
                                                        //Query_Field_1_Type__c = 'Decimal',
                                                        //Query_Object__c = 'Account',
                                                        //Query_Return_Field__c = 'Id',
                                                        Require_Field_To_Update__c = TRUE,
                                                        Allow_Multiple_Matches__c = FALSE,
                                                        Notification_Email__c = 'jstouffer@paychex.com,justin.g.stouffer@gmail.com'
                                                      ,ReturnRecordResultsToSubmitter__c = true
                                                        );
                            
      Email_File_Upload_Settings__c efus2 = new Email_File_Upload_Settings__c(Name='Support Case Upload2',
                                                        Active__c = TRUE,
                                                        ID_Key__c = '9999-99-91',
                                                        NbrAttempts__c = 3,
                                                        //Query_Field_1__c = 'AccountNumber',
                                                        //Query__c = 'Select Id, BIS_ID__c, AccountNumber from Account where ',
                                                        //Field_To_Update__c = 'AccountId',
                                                        Object_Type__c = 'Case',
                                                        //Query_Field_1_Type__c = 'String',
                                                        //Query_Object__c = 'Account',
                                                        //Query_Return_Field__c = 'Id',
                                                        Require_Field_To_Update__c = TRUE,
                                                        Allow_Multiple_Matches__c = TRUE,
                                                        Notification_Email__c = 'jstouffer@paychex.com'
                                                        );
      Email_File_Upload_Settings__c[] eFUSList = new Email_File_Upload_Settings__c[]{efus1,efus2};
      insert eFUSList;
         
      EmailFileQuery__c[] fileQueries = new EmailFileQuery__c[]{};
      filequeries.add(new EmailFileQuery__c(Name=efus1.ID_Key__c+'test1'
                                           ,DataFileColumnName__c='Bis_Id__c'
                                           //,ID_Key__c=efus1.ID_Key__c
                                           ,NewObjectRelatedField__c='AccountId'
                                           ,QueryObject__c='Account'
                                           ,SelectField__c='Id'
                                           ,WhereField__c='Bis_Id__c'
                                           ,RequiredRelationship__c=true
                                           ));
      filequeries.add(new EmailFileQuery__c(Name=efus2.ID_Key__c+'test1'
                                           ,DataFileColumnName__c='AccountNumber'
                                           //,ID_Key__c=efus2.ID_Key__c
                                           ,NewObjectRelatedField__c='AccountId'
                                           ,QueryObject__c='Account'
                                           ,SelectField__c='Id'
                                           ,WhereField__c='AccountNumber'
                                           ));
      insert filequeries;
      
      EmailFileValuePairs__c[] efvps = new EmailFileValuePairs__c[]{};
      efvps.add(new EmailFileValuePairs__c(Name=efus1.ID_Key__c+'test1'
                                           ,APIFieldName__c='Description'
                                           //,ID_Key__c=efus1.ID_Key__c
                                           ,Value__c='Description'));
      insert efvps;
   } // createEmailFileUploadCS
    
    
   static string createCSV(boolean makeItBig){
      string CRLF = '\r\n';
      string csv = 'subject,BIS_ID__c,AccountNumber' + CRLF;
      csv += '"this, is test 1",1,11-1111' + CRLF;
      csv += '"this' + CRLF + ' is test 2",2,22-2222' + CRLF;
      if(makeItBig){
            do{
                csv += '"this, is test 1",1,11-1111' + CRLF;    
            }while(csv.Length() <= EmailServiceProcessor.MAXSIZE + 30); 
      }
      return csv;
   } // createCSV
   
} // class EmailServiceProcessorTest