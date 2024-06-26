/**
 * This is part of several classes that work together to process email attachments and insert records into Salesforce.
 * This is a helper class that manages the creates web service logs to be processed, fires off the batch process, and has utilities used in the process.

  History
  -------
  08/19/2015 Justin Stouffer Created
  02/10/2016 Dan Carmen      Code modifications for SRR
  02/27/2016 Dan Carmen      Additional changes to handle no matching file setting
  09/12/2016 Dan Carmen      Capture exception if csv file is corrupt or unreadable.
  10/24/2016 Dan Carmen      Change to send the response to a user id versus an email address.
  11/02/2016 Justin Stouffer Updated CSVIterator to handle line splitting more efficiently.  
  02/24/2020 Dan Carmen        Increment API version
  10/19/2020 Jake Hinds     Commenting out old code.  Trying to fix a bug around ".
  12/28/2020 Dan Carmen        Increment API to get rid of Missing dependent object: Field: Case.ServiceContractId error

 */
public with sharing class EmailServiceProcessor {
    
    public static boolean runningBigTest = FALSE;//Set this to true if running a test that will create more than one Batch Iteration
    
    public static integer MAXSIZE = 2000000;//Maximum Number of Character before file is split
    
    public static final String SERVICE_NAME='EmailFileInsert';
    
    public static void processEmailWithAttachment(Messaging.InboundEmail email){
        list<sObject> attchmntList = new list<sObject>();

      Email_File_Upload_Settings__c eFUS = null;
      for(Email_File_Upload_Settings__c e: Email_File_Upload_Settings__c.getall().values()){
            if(email.plainTextBody.contains(e.ID_Key__c) && e.Active__c){
                eFUS = e;
                break;
            }   
      }//verify that the body of the email contains a key that matches one of the active Email File Upload Custom Settings.

      boolean okToProceed = (eFUS != null);

      string fromAddress = email.fromAddress;//Store the from address to be used later
      
      User fromUser = null;
      
      try {
         fromUser = [Select Id, Name, Email from User where Email=:fromAddress and IsActive=true and HR_Person_Id__c != null limit 1];
      } catch (Exception e) {
         // no exception
      }
      
      Boolean fromUserFound = (fromUser != null);
      
      
      if (fromUser == null && eFUS != null && String.isNotBlank(eFUS.Notification_Email__c)) {
         try {
            String[] emails = eFUS.Notification_Email__c.split(';');
            // only select the first email address if multiple
            fromUser = [Select Id, Name, Email from User where Email=:emails[0] and IsActive=true and HR_Person_Id__c != null limit 1];
         } catch (Exception e) {
            // default to the running user
            fromUser = [Select Id, Name, Email from User where Id=:UserInfo.getUserId()];
         }
      } // if (fromUser == null

      String emailErrorMsg = (!fromUserFound ? 'Warning! A User with the email address '+fromAddress+' could not be found! \n\n' : '');
      
      if(okToProceed){
            string txtBody = 'Your email with attached CSV files to upload into Salesforce has been received and will be processed shortly. '
                                + 'A completion email will be sent to notify you when each file upload is finished. '
                                + 'Please be patient, as this process may take a while, depending on how many records there are and what other processes are occurring in Salesforce.com.';
            string txtSubj = 'Your File Upload Email to Salesforce has been received.';
            if(email.binaryAttachments != NULL && !email.binaryAttachments.isEmpty()){
                map<Attachment,Web_Service_Log__c> wslToInsertMap = new map<Attachment,Web_Service_Log__c>();//This map is used to keep attachments and WSLs in sync
                try {
                for (Messaging.Inboundemail.BinaryAttachment file : email.binaryAttachments){
                    if(file.fileName.endsWith('.csv')){
                        string body = file.body.toString();
                        if(body.Length() > EmailServiceProcessor.MAXSIZE){//Split the attchment body if it's larger than MAXSIZE.
                            boolean endOfFile = FALSE;
                            string startRow = body.substring(0,body.indexOf(EmailServiceProcessorBatch.CRLF,0));//Set the first row (Column Headers) based on the first \r\n int he file.
                            integer endIndex = MAXSIZE;
                            integer startIndex = 0;
                            integer filePart = 1;
                            
                            While(!endOfFile){//Loop through the file and break it into smaller files if it exceeds MAXSIZE.
                                string tempBody = '';
                                if(endIndex != maxSize){
                                    tempBody = startRow + EmailServiceProcessorBatch.CRLF;
                                }
                                endIndex = body.indexOf(EmailServiceProcessorBatch.CRLF,endIndex) + EmailServiceProcessorBatch.CRLF.length();
                                If(endIndex - EmailServiceProcessorBatch.CRLF.length() != -1 && body.length() - startIndex > endIndex - startIndex){
                                    tempBody += body.substring(startIndex,endIndex);
                                    startIndex = endIndex;
                                    endIndex =endIndex + maxSize;
                                }
                                else{
                                    tempBody += body.substring(startIndex,body.length());
                                    endOfFile = TRUE;
                                }
                                Web_Service_Log__c wsl = new Web_Service_Log__c();
                                wsl.ServiceName__c = SERVICE_NAME;
                                wsl.ServiceStart__c = DateTime.Now();
                                wsl.Notes__c = fromAddress;
                                wsl.NamedFunction__c = eFUS.ID_Key__c;
                                wsl.Action__c = 'Insert';
                                wsl.NBRAttempts__c = 0;
                                Attachment attach = new Attachment();
                                attach.Body =  Blob.valueOf(tempBody);
                                attach.Name = file.fileName.substring(0,file.fileName.Length()-4) + '-Part-' + filePart + '.csv' ; 
                                filePart++;         
                                wslToInsertMap.put(attach,wsl);     
                            }   
                        } // if(body.Length() > EmailServiceProcessor.MAXSIZE
                        else{
                            // we're within the file size - no need to split
                            Web_Service_Log__c wsl = new Web_Service_Log__c();
                            wsl.ServiceName__c = SERVICE_NAME;
                            wsl.ServiceStart__c = DateTime.Now();
                            wsl.Notes__c = fromAddress;
                            wsl.NamedFunction__c = eFUS.ID_Key__c;
                            wsl.Action__c = 'Insert';
                            wsl.NBRAttempts__c = 0;
                            Attachment attach = new Attachment();
                            attach.Body = file.body;  
                            attach.Name = file.fileName;            
                            wslToInsertMap.put(attach,wsl);
                        }
                    } // if(file.fileName.endsWith('.csv
              } // for (Messaging.Inboundemail.BinaryAttachment file    
                if(!wslToInsertMap.isEmpty()){
               insert wslToInsertMap.values();
                    for(attachment attch:wslToInsertMap.keySet()){
                        attachment attchmnt = attch;
                        attchmnt.ParentID = wslToInsertMap.get(attch).id;
                        attchmntList.add(attchmnt); 
                    } // for(attachment attch
               insert attchmntList;
               EmailServiceProcessor.kickOffBatchJob(eFUS != null && eFUS.MaxRecsPerBatch__c != null ? (Integer)eFUS.MaxRecsPerBatch__c : 200);
            } else{
               processResult = 'No csv files attached';
               txtBody = 'There were no CSV files attached to your email to upload into Salesforce.com.';
               txtSubj = 'Warning! Your File Upload Email to Salesforce has been received, but there was a problem.';
            }
                } catch (Exception e) {
               processResult = 'Error reading csv file!';
               txtSubj = 'Warning! Your File Upload Email to Salesforce has been received, but there was a problem.';
               txtBody = 'There was an error trying to read the csv file!';
               txtBody += '\n'+e.getMessage()+'. '+e.getStackTraceString();
                }
         } else{
               processResult = 'No files attached';
            txtBody = 'There were no files attached to your email to upload into Salesforce.com.';
            txtSubj = 'Warning! Your File Upload Email to Salesforce has been received, but there was a problem.';  
         }
            Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
            mail.setSubject(txtSubj);
            mail.setTargetObjectId(fromUser.Id);
            mail.setSaveAsActivity(false);
            //mail.setToAddresses(new String[]{fromAddress});
            mail.setPlainTextBody(emailErrorMsg+txtBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      } else {
         // we could not find a matching email setup record
         processResult = 'No Email_File_Upload_Settings__c found';
         Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
         mail.setSubject('Warning! Your File Upload Email to Salesforce has been received, but there was a problem.');
         mail.setTargetObjectId(fromUser.Id);
         mail.setSaveAsActivity(false);
         //mail.setToAddresses(new String[]{fromAddress});
         mail.setPlainTextBody(emailErrorMsg+'An active email key was not found in the email body! The email was not processed.');
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      } // if(okToProceed
   }//processEmailWithAttachment
   
   public static String processResult=null;
    
    public static final String BATCH_CONTROL_NAME='EmailServiceProcessorBatch';
   public static void kickOffBatchJob(Integer batchSize){
      System.debug('kickOffBatchJob batchSize='+batchSize);
      Apex_Batch_Control__c apexCS = Apex_Batch_Control__c.getInstance(BATCH_CONTROL_NAME);
      if (apexCS != NULL && apexCS.Active__c && !runningBigTest){
         EmailServiceProcessorBatch sc = new EmailServiceProcessorBatch();
         boolean jobScheduled = FALSE;
         //check if there are 5 active batch jobs
         list<AsyncApexJob> asyncJobList = [SELECT ApexClass.Name
                                                 FROM AsyncApexJob 
                                                WHERE JobType='BatchApex' 
                                                AND (Status = 'Processing' 
                                                OR Status = 'Preparing'
                                                OR Status = 'Queued'
                                                or Status = 'Holding')];
         if(!asyncJobList.isEmpty()){
            For(AsyncApexJob a: asyncJobList){
               if (a.ApexClass.Name == 'EmailServiceProcessorBatch'){
                  jobScheduled = TRUE;
               }    
            }
         }
         If(!jobScheduled){
            if (asyncJobList.size() < 5){//5 is maximum number of concurrent batch job limit.
               try{
                  Database.executeBatch(sc, batchSize);    
               } 
               catch(AsyncException e) {
                  System.debug('The following exception has occurred: ' + e.getMessage());
               } //Don't do anything if there is an exception when kicking off the batch
            } // if (asyncJobList.size()
            else {
               try{
                  System.scheduleBatch(sc, BATCH_CONTROL_NAME, 15, batchSize);// Schedule to start in 15 minutes to stay below concurrent Batch job limit.
               } 
               catch(AsyncException e) {
                  System.debug('The following exception has occurred: ' + e.getMessage());
               } //Don't do anything if there is an exception when kicking off the batch
            }
         } // If(!jobScheduled
        } // if (apexCS != NULL
   }//kickOffBatchJob

    
    public static map<integer,map<string,Object>> parseCSVToMap(String contents, Boolean batchPreChecked, Map<Integer,String> headerFieldMap, Map<String, Schema.SObjectField> fieldMap) {
       System.debug('parseCSVToMap contents='+(String.IsNotBlank(contents) ? contents.length() : -1));
        map<integer,map<string,Object>> allFields = new map<integer,map<string,Object>>();
        
        contents = contents.replaceAll('\r\n','\n');
        contents = contents.replaceAll('""','DBLQT');
        // replace instances where a double quote begins a field containing a comma
        // in this case you get a double quote followed by a doubled double quote
        // do this for beginning and end of a field
        //contents = contents.replaceAll(',"""',',"DBLQT');
        //JSH 10/19
        //contents = contents.replaceAll(',"',',"DBLQT');
        system.debug('Contents 1' + contents);
        //contents = contents.replaceAll('""",','DBLQT",');
        contents = contents.replaceAll('",','DBLQT",');
        system.debug('Contents 2' + contents);
        // now replace all remaining double quotes - we do this so that we can reconstruct
        // fields with commas inside assuming they begin and end with a double quote
        //contents = contents.replaceAll('""','DBLQT');
        system.debug('Contents 3' + contents);
        List<String> lines = new List<String>();
        try {
            lines = contents.split('EndOfLine');
        } catch (System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        // map of the header field names
        //map<Integer, String> fieldMap = new map<Integer, String>();
        //Integer rowNum = -1;
        // if there is nothing to process
        if (lines.size() <= 1) {
           return allFields;
        }
        // skip the header row
        for (Integer rowNum = 1; rowNum< lines.size(); rowNum++) {
           String line = lines[rowNum];
           System.debug('parseCSVToMap line='+line);
        //for (String line : lines) {
            Integer colNum = 0;
            // check for blank CSV lines (only commas)
            map<string,Object> tmpMAP = new map<string,Object>();
            if (line.replaceAll(',','').trim().length() == 0) break;
            
            List<String> dataFlds = line.split(',');    
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;

         for (String field : dataFlds) {
             system.debug('Email Service Processor makeComposite:'+makeCompositeField+' Field:'+field);
                if (field.startsWith('"') && field.endsWith('"')) {
                   // only add the value if there's a valid header for it
                   checkAddToRow(tmpMAP, colNum, field.replaceAll('DBLQT','"'), headerFieldMap, fieldMap);

                    colNum++;
                } else if (field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                } else if (field.endsWith('"')) {
                    compositeField += ',' + field;
                   // only add the value if there's a valid header for it
                   checkAddToRow(tmpMAP, colNum, compositeField.replaceAll('DBLQT','"'), headerFieldMap, fieldMap);
                    colNum++;
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField +=  ',' + field;
                } else {
                   checkAddToRow(tmpMAP, colNum, field.replaceAll('DBLQT','"'), headerFieldMap, fieldMap);
                    colNum++;
                }
            } // for (String field : fields
            //if(rowNum>-1){
                allFields.put(rowNum-1,tmpMap);
            //}
            //rowNum++;
        } // for (String line : lines
        return allFields;       
    } //parseCSVToMap
    
    public static void checkAddToRow(map<String,Object> rowMap, Integer colNum, String fldValue, Map<Integer,String> headerFieldMap, Map<String, Schema.SObjectField> fieldMap) {
      String headerName = headerFieldMap.get(colNum);
      if (headerName != null && String.isNotBlank(fldValue)) {
         Schema.SObjectField fldObject = fieldMap.get(headerName);
         if (fldObject != null) {
            Object valueAsObject = ObjectHelper.formatStringAsObject(fldObject, fldValue);
            rowMap.put(headerName,valueAsObject);
         } else {
            rowMap.put(headerName,fldValue);
         }
         system.debug('EmailServiceProcessor checkAddToRow rowMap'+rowMap);
      } // if (headerName != null
       
    } // checkAddToRow

} // class EmailServiceProcessor