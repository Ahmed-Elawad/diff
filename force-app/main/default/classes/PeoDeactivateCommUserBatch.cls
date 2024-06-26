/*
* History
* -------------------------------
* 10/11/2021    Jidesh          Created
* 10/11/2021    Matt Fritschi   Added Email/Chatter notifications for prospects who haven't logged.
* 11/01/2021    Matt Fritschi   Added Email/Chatter notifications for prospects who haven't made progess in a certain amount of time.
* 11/08/2021    Matt Fritschi   Added Email/Chatter notifications for prospects who have un-resolved discrepancies.
* 11/19/2021    Matt Fritschi   Include CloseDate in Opportunity query to fix error.
* 02/07/2022	Jake Hinds		Removing audience
* 11/08/2023	Priyanka		Added for remianders 
* 03/19/2024    Josh Cartwright added conditions in if satement to check for prospect portal complete and CSCM contract satus before sending notifications 
* 03/19/2024    Srujan Kumar    Added a new batch to create chatterpost/send email for open descepancies which will be called after communityuser deactivate/activate logic
* 04/26/2024    Josh Cartwright modified getworkingdays for reminder emails from -2 to -1 

*/

global class PeoDeactivateCommUserBatch implements Database.Batchable<sObject>,Database.Stateful, Schedulable{
    
    @TestVisible static Integer emailLimits;
    @TestVisible static Boolean chatterSent;
    public static final String CLASS_NAME='PeoDeactivateCommUserBatch';
    
    private User[] commUsers;
    private Apex_Batch_Control__c abc;
    private Date checkDate;
    private List<User> deactvtUsers;
    private boolean chattersToPost;
    private static final List<Boolean> isWorkingDay;
    private static final Integer workingDaysInWeek;
    private Map<Id, Id> UserChecklistId= new Map<Id, Id>();
    
    global JobHelper jh = new JobHelper(CLASS_NAME);
    /** messages that occur during the process. */
    global String processNotes = '';
    
    global String currentMode = null;
    
    public static String MODE_COMMUNITY_USER = 'CommunityUser';
    public static String MODE_PEO_UNDERWRITING_CHECKLIST = 'PEOUnderwritingChecklist';
    
    //Array of working days Mon-Sat
    static {
        isWorkingDay = new List<Boolean> { true, true, true, true, true, false, false };
            workingDaysInWeek = 5;
    }
    
    global PeoDeactivateCommUserBatch() {
        abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
        checkDate = (abc!=null && abc.Check_Days__c != null? date.today().addDays(-((Integer)abc.Check_Days__c)):date.today().addDays(-365));
    } // PeoDeactivateCommUserBatch 
    
    global PeoDeactivateCommUserBatch(String p_currentMode) {
      system.debug('in constructor p_currentMode='+p_currentMode);
      currentMode = p_currentMode;
   }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        if (String.isBlank(currentMode)) {
            currentMode = MODE_COMMUNITY_USER;
        }
        
        // save the record - show that the job started
        jh.setStarted();
        //fetch all the community users first
        System.debug('++Inside start');
        String query = '';
        if(currentMode == MODE_COMMUNITY_USER){
            query = 'Select Id,IsActive,AccountId,contactid,LastLoginDate,Name,ProfileName__c,Username,Email,CreatedDate,Community_User_First_Login__c,FirstName,Deactivated_due_to_Inactivity__c ';
            query += 'from User ' ;
            query += 'where ProfileName__c = \'Customer Community Login User Clone\' ';
            query += 'AND IsActive= true ' + (Test.isRunningTest() ? ' AND FirstName = \'deactivateUserBatchTest Test User\' LIMIT 200' : '');
        }else if(currentMode == MODE_PEO_UNDERWRITING_CHECKLIST){
            Date d1 = Date.today();
            Date d2 = Date.today()-10;
            query = 'SELECT Id, Sales_Rep__c, Sales_Rep__r.Name, Sales_Rep__r.Email, Prospect_Client__c,Most_Recent_Open_Discrepancy__c,Discrepancy_Communication_Method__c, Prospect_Client__r.Name from PEO_Onboarding_Checklist__c';
            query += ' WHERE Most_Recent_Open_Discrepancy__c != null AND Most_Recent_Open_Discrepancy__c <: d1 AND Most_Recent_Open_Discrepancy__c  >: d2';
        }
        
        system.debug('++query'+query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(SchedulableContext sc) {
        system.debug('++Batch Process scheduled');
        launchBatch(abc);
    } // execute
    
    global static void launchBatch(Apex_Batch_Control__c abc) {
        if (abc != null && abc.Active__c) {
            system.debug('++found setting, calling execute');
            PeoDeactivateCommUserBatch pdcb = new PeoDeactivateCommUserBatch();
            Integer batchSize = (abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 500);
            system.debug('++found setting, batchSize'+batchSize);
            database.executeBatch(pdcb, batchSize);
        }
        else {
            System.debug('++NO APEX BATCH CONTROL SETTING');
        }
    } // launchBatch
    
    global void handleCommunityUserRecords(User[] recs) {
        system.debug('++in comm');
        System.debug('++recs:-'+recs);
        List<Id> accIds = new List<Id>();
        deactvtUsers = new List<User>();
        Map<Id, Account> accounts;
        List<PEO_Onboarding_Checklist__c> checkLists = new List<PEO_Onboarding_Checklist__c>();
        Map<Id,Opportunity> oppByAccountId = new Map<Id,Opportunity>();
        Date todaysDate = Date.today();
        Date deactivationDate = Date.today().addDays(-89);
        Map<User, integer> userHasntLogged = new Map<User, integer>();
        Map<User, integer> userHasntProgressed = new Map<User, integer>();
        
        commUsers = (List<User>)recs;
        
        System.debug('++commUsers.size() = '+commUsers.size());
        //Possibly find a way to combine all the loops below.
        for(User commuser:commUsers){
            accIds.add(commuser.AccountId);
        }
        
        //Query all Accounts and checklists for the community users
        if(accIds.size()>0){
            accounts = new Map<Id, Account>([SELECT Id, Name, CSCMContractStatus__c,
                                             (SELECT Id, Name, Sales_Rep__c,Prospect_Client__c,Last_Change_Made__c,Prospect_Portal_Complete_Date__c,Prospect_Email_Opt_Out__c,Most_Recent_Open_Discrepancy__c,Discrepancy_Communication_Method__c,
                                              Opportunity__c,Opportunity__r.IsClosed, Opportunity__r.Name,Analyst_Queue__c,Opportunity__r.AccountId, Opportunity__r.CloseDate FROM PEO_Onboarding_Checklists__r ORDER BY CreatedDate DESC LIMIT 1) FROM Account WHERE Id IN :accIds]);
        }
        
        if(accounts.size()>0){
            for(Account acc: accounts.values()){
                For(PEO_Onboarding_Checklist__c checkList : acc.PEO_Onboarding_Checklists__r){
                    UserChecklistId.put(acc.id, checkList.Id);
                    if(checkList.Opportunity__c!=null){
                        oppByAccountId.put(checkList.Prospect_Client__c,checkList.Opportunity__r);
                    }
                }
            }
        }
        
        Date endDate = Date.today();
        for(User commuser : commUsers) {
            if(commuser.AccountId != null && accounts.containsKey(commuser.AccountId)) {
                Account acc = accounts.get(commUser.AccountId);
                if(acc.PEO_Onboarding_Checklists__r != null && acc.PEO_Onboarding_Checklists__r.size() == 1) {
                    PEO_Onboarding_Checklist__c checklist = acc.PEO_Onboarding_Checklists__r[0];
                    if(!checklist.Prospect_Email_Opt_Out__c && checklist.Prospect_Portal_Complete_Date__c ==null && (acc.CSCMContractStatus__c=='' || acc.CSCMContractStatus__c=='Prospect')) {
                        if(commuser.Community_User_First_Login__c == null) {
                            Date startDate = date.newinstance(commuser.CreatedDate.year(), commuser.CreatedDate.month(), commuser.CreatedDate.day());
                            Integer noOfDays = getWorkingDays(startDate, endDate)-1;
                            //System.debug('MGF noOfDays='+noOfDays+' startDate='+startDate+' endDate='+endDate);
                           
                            if(noOfDays == 3 || noOfDays == 7 || noOfDays == 14){
                                 userHasntLogged.put(commuser, noOfDays);
                            }
                        }
                        
                        else if(commuser.Community_User_First_Login__c != null && checklist.Last_Change_Made__c != null) {
                            Date startDate = date.newinstance(checklist.Last_Change_Made__c.year(), checklist.Last_Change_Made__c.month(), checklist.Last_Change_Made__c.day());
                            Integer noOfDays = getWorkingDays(startDate, endDate)-1;
                            //JC changed -2 to -1 to match the cadence above 
                            //System.debug('Number Of Days = ' + noOfDays);
                          
                            if(noOfDays == 3 || noOfDays == 7 || noOfDays == 14){
                                 userHasntProgressed.put(commuser, noOfDays);
                            }
                        }
                    }
                }
            }
        }
        
        //Send emails and create chatter posts.
        chattersToPost = false;
        List<String> templates = new List<String>();
        //        templates.add('User registered and has not logged in'); 
        //        templates.add('User Has No Activity');
		templates.add('PEOUW Edge Email Login Reminder Day%'); 
        templates.add('PEOUW Edge Email Keep Going Reminder%');
        templates.add('Discrepancy Logged/Not Resolved');
        List<EmailTemplate> emailTemplates = new List<EmailTemplate>([Select Id,Name,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name like :templates]);
        Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
        for(EmailTemplate template : emailTemplates) {
            emailTemplateMap.put(template.Name, template);
        }
        
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{};
            system.debug('++userHasntLogged: ' + userHasntLogged.values());
            //Send notifications for users who have not logged in
          if(!userHasntLogged.isEmpty()){
                for(User commUser :userHasntLogged.keyset()){
                    Account acc = accounts.get(commUser.AccountId);
                    if(acc.PEO_Onboarding_Checklists__r != null) {
                        PEO_Onboarding_Checklist__c checklist = acc.PEO_Onboarding_Checklists__r[0];
                        if(emailTemplateMap.containsKey('PEOUW Edge Email Login Reminder Day '+ userHasntLogged.get(commUser))){
                            EmailTemplate loginReminderEmailTemplate 
                                = emailTemplateMap.get('PEOUW Edge Email Login Reminder Day '+ userHasntLogged.get(commUser));
                           	sendEmailwithTargetId(commUser, messages, loginReminderEmailTemplate, checklist.Id );
                            createChatterPost(commUser, acc, checklist, false, 'No Login');
                        }
                    }
                }
            }
          
        
        //Send notifications for users who haven't progressed within a certain amount of time
        if(!userHasntProgressed.isEmpty()){
            for(User commUser :userHasntProgressed.keyset()){                
                if(commUser.AccountId != null && accounts.keySet().contains(commUser.AccountId)) {
                Account acc = accounts.get(commUser.AccountId);
                    if(acc.PEO_Onboarding_Checklists__r != null) {
                        PEO_Onboarding_Checklist__c checklist = acc.PEO_Onboarding_Checklists__r[0];
                        if(emailTemplateMap.containsKey('PEOUW Edge Email Keep Going Reminder ' + userHasntProgressed.get(commUser))
                           && checklist.Analyst_Queue__c==null){ //SFDC-13195
                            EmailTemplate noProgressEmailTemplate = emailTemplateMap.get('PEOUW Edge Email Keep Going Reminder ' + userHasntProgressed.get(commUser));
                           // sendEmail(commUser, messages, noProgressEmailTemplate);
                            sendEmailwithTargetId(commUser, messages, noProgressEmailTemplate, checklist.Id );
                            createChatterPost(commUser, acc, checklist, false, 'No Progress');
                   }
                 }
               }
            } 
        }        
        try {
            if(!messages.isEmpty()) {
                ErrorLog__c log = null;
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                
                for(Messaging.SendEmailResult result : results) {
                    if (result.success) 
                    {
                        System.debug('++The email was sent successfully.');
                    } else {
                        //Include error log here.
                        System.debug('++The email failed to send: ' +  result.errors[0].message);
                        if(log == null) {
                            log = ErrorLog.logError('PeoDeactivateCommUserBatch', 'execute', 'LOG_DATA', null, result.errors[0].message);
                        }
                        else {
                            ErrorLog.addToDescription(log, result.errors[0].message);
                        }
                    }
                }
                if(log != null) {
                    ErrorLog.checkSave();
                }
            }
            if(chattersToPost) {
                ChatterMentionPost.postBatchFeedElements();
                if(Test.isRunningTest()) {
                    PeoDeactivateCommUserBatch.chatterSent = true;
                }
            }
        }
        catch (Exception e) {
            ErrorLog.logError('PeoDeactivateCommUserBatch','execute','Error sending email notifications.',null,e,null,true);
        }
        
        
        //When opportunity is open or closed:start
        //if open check if the user has logged in within last 120 days
        //if the opportunity is closed deactivate all the comm users
        if(!oppByAccountId.isEmpty()){
            system.debug('++Open opportunity loop');
            for(User usr: commUsers){
                if(!Test.isRunningTest()){
                    if(oppByAccountId.containsKey(usr.AccountId)) {
                        Opportunity opp = oppByAccountId.get(usr.AccountId);
                        //system.debug('after opp');
                        
                       if(usr.LastLoginDate<deactivationDate || (opp!=null && opp.IsClosed && opp.CloseDate<deactivationDate)){
                             //system.debug('open opportunity user check');
                            usr.IsActive = false;
                            usr.Deactivated_due_to_Inactivity__c = System.today();
                            deactvtUsers.add(usr);
                        }
                    }
                }
                else{
                    deactvtUsers.add(usr);
                }
            }
        }
        
        //When opportunity is closed: end
        DMLHelper.performDML2(deactvtUsers, DMLHelper.DML_UPDATE, CLASS_NAME, 'execute', 'updating users to inactive', true);
        
    }
    
    global void handlePEOUnderwritingChecklistRecords(PEO_Onboarding_Checklist__c[] recs){
        System.debug('++recs:-'+recs);
        List<PEO_Onboarding_Checklist__c> userHasOpenDiscrepanciesDay1Or3 = new List<PEO_Onboarding_Checklist__c>();
        List<PEO_Onboarding_Checklist__c> userHasOpenDiscrepanciesDay4 = new List<PEO_Onboarding_Checklist__c>();
        
        List<PEO_Onboarding_Checklist__c> checklists = (List<PEO_Onboarding_Checklist__c>)recs;

        Date endDate = Date.today();
        for(PEO_Onboarding_Checklist__c chklist : checklists) {
            //Checks to see if there are open discrepancies that require a notification
            if(chklist.Most_Recent_Open_Discrepancy__c != null) {
                Date startDate = date.newinstance(chklist.Most_Recent_Open_Discrepancy__c.year(), chklist.Most_Recent_Open_Discrepancy__c.month(), chklist.Most_Recent_Open_Discrepancy__c.day());
                Integer noOfDays = getWorkingDays(startDate, endDate)-2;
                System.debug('Number Of Days = ' + noOfDays);
                if(noOfDays == 1 || noOfDays == 3) {
                    userHasOpenDiscrepanciesDay1Or3.add(chklist);
                }
                if(noOfDays == 4) {
                    userHasOpenDiscrepanciesDay4.add(chklist);
                }
            }
        }
        
        //Send emails and create chatter posts.
        chattersToPost = false;
        List<String> templates = new List<String>();
        templates.add('Discrepancy Logged/Not Resolved');
        List<EmailTemplate> emailTemplates = new List<EmailTemplate>([Select Id,Name,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name like :templates]);
        Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
        for(EmailTemplate template : emailTemplates) {
            emailTemplateMap.put(template.Name, template);
        }
        
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{};
        //Send notification is the user has an open discrepancy that requires attention
        for(PEO_Onboarding_Checklist__c chklist : userHasOpenDiscrepanciesDay1Or3) {
            if(emailTemplateMap.containsKey('Discrepancy Logged/Not Resolved')){
                if(!chklist.Discrepancy_Communication_Method__c) {
                    EmailTemplate openDiscrepanciesEmailTemplate = emailTemplateMap.get('Discrepancy Logged/Not Resolved');
                    sendEmail(null, chklist, messages, openDiscrepanciesEmailTemplate);
                }
                createChatterPost(null, null, chklist, false, 'Open Disc');
            }
        }
        for(PEO_Onboarding_Checklist__c chklist : userHasOpenDiscrepanciesDay4) {
            createChatterPost(null, null, chklist, true, 'Open Disc');
        }
        
        try {
            system.debug('++'+messages);
            if(!messages.isEmpty()) {
                ErrorLog__c log = null;
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                
                for(Messaging.SendEmailResult result : results) {
                    if (result.success) 
                    {
                        System.debug('++The email was sent successfully.');
                    } else {
                        //Include error log here.
                        System.debug('++The email failed to send: ' +  result.errors[0].message);
                        if(log == null) {
                            log = ErrorLog.logError('PeoDeactivateCommUserBatch', 'execute', 'LOG_DATA', null, result.errors[0].message);
                        }
                        else {
                            ErrorLog.addToDescription(log, result.errors[0].message);
                        }
                    }
                }
                if(log != null) {
                    ErrorLog.checkSave();
                }
            }
            if(chattersToPost) {
                ChatterMentionPost.postBatchFeedElements();
                if(Test.isRunningTest()) {
                    PeoDeactivateCommUserBatch.chatterSent = true;
                }
            }
        }
        catch (Exception e) {
            ErrorLog.logError('PeoDeactivateCommUserBatch','execute','Error sending email notifications.',null,e,null,true);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope){
        system.debug('++execute'+scope.size());
        if (scope[0].getSObjectType() == User.sObjectType) {
            handleCommunityUserRecords((User[])scope);
        }else if(scope[0].getSObjectType() == PEO_Onboarding_Checklist__c.sObjectType){
            system.debug('++finally here');
            handlePEOUnderwritingChecklistRecords((PEO_Onboarding_Checklist__c[])scope);
        }
    }
    
    global void finish(Database.BatchableContext BC){
        if (currentMode == MODE_COMMUNITY_USER) {
            String message = '\nUsers deactivated';
            message += '\n\n'+processNotes;
            system.debug('++message:'+message);
            jh.completeJob(BC, CLASS_NAME+' process', message);
            AsyncApexJob aaj = null;
            aaj = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
                   TotalJobItems, CreatedById
                   from AsyncApexJob where Id = :BC.getJobId()];
            //If Batch Job is completed send email to the deactivated users
            if(aaj.Status == 'Completed'){
                List<Messaging.SingleEmailMessage> mailList =  new List<Messaging.SingleEmailMessage>();
                //Fetch the user deactivation email template
                EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body 
                                               from EmailTemplate where name = 'Deactivation Email' limit 1];
                if(deactvtUsers != null && deactvtUsers.size()>0){
                    for (User usr : deactvtUsers) {
                        if(!string.isEmpty(usr.contactid)){
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            mail.setTargetObjectId(usr.contactid); 
                            mail.setSenderDisplayName('PEOSUPPORT_noreply@paychex.com'); 
                            mail.setReplyTo('sfdc_automation@paychex.com');
                            mail.setUseSignature(false); 
                            mail.setBccSender(false); 
                            mail.setSaveAsActivity(false); 
                            mail.setTemplateID(emailTemplate.Id);
                            mail.setWhatId(UserChecklistId.get(usr.AccountId));
                            //mail.toAddresses = new String[] {usr.email};
                            mailList.add(mail);
                        }
                    }
                    Messaging.sendEmail(mailList);
                }
            }
            
        }
        if (!Test.isRunningTest()) {
            if (currentMode == MODE_COMMUNITY_USER) {
                scheduleBatch(MODE_PEO_UNDERWRITING_CHECKLIST, true);
            }
        }
        system.debug('++In Finish');
        if(Test.isRunningTest()) {
            system.debug('++'+Limits.getEmailInvocations());
            PeoDeactivateCommUserBatch.emailLimits = Limits.getEmailInvocations();
        }
    }
    
    public static PeoDeactivateCommUserBatch dcb = null;
    
    public static void scheduleBatch(String nextMode, Boolean scheduleImmediate) {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
      System.debug('++scheduleBatch nextMode='+nextMode+' abc='+abc+' scheduleImmediate='+scheduleImmediate);
      if (abc != null && abc.Active__c) {
         Integer batchSize = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 500);
         dcb = new PeoDeactivateCommUserBatch(nextMode);
         if (scheduleImmediate) {
            database.executeBatch(dcb, batchSize);
            
         }
      }
   }
    
    //Created the email to send to the prospect who hasn't logged in.
    public void sendEmail(User commUser,PEO_Onboarding_Checklist__c chklist, Messaging.SingleEmailMessage[] messages, EmailTemplate emailTemplate) {
        system.debug('++chklist'+chklist);
            system.debug('++chklist'+chklist.sales_rep__r.email);
        if(commUser != null && commUser.email != null) {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setTargetObjectId(commUser.id); 
            message.setSenderDisplayName('PEOSUPPORT_noreply@paychex.com'); 
            message.setReplyTo('sfdc_automation@paychex.com');
            message.setUseSignature(false); 
            message.setBccSender(false); 
            message.setSaveAsActivity(false); 
            message.setTemplateID(emailTemplate.Id);
            message.toAddresses = new String[] {commUser.email};
                
            messages.add(message);
        }else if(chklist != null && chklist.sales_rep__r.email != null){
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            system.debug('++'+chklist.sales_rep__c);
            message.setTargetObjectId(chklist.sales_rep__c); 
            message.setSenderDisplayName('PEOSUPPORT_noreply@paychex.com'); 
            message.setReplyTo('sfdc_automation@paychex.com');
            message.setUseSignature(false); 
            message.setBccSender(false); 
            message.setSaveAsActivity(false); 
            system.debug('++'+emailTemplate.Id);
            message.setTemplateID(emailTemplate.Id);
            system.debug('++'+chklist.sales_rep__r.email);
            message.toAddresses = new String[] {chklist.sales_rep__r.email};
                system.debug('++here');
            messages.add(message);
        }
    }
    
    public void sendEmailwithTargetId(User commUser, Messaging.SingleEmailMessage[] messages, EmailTemplate emailTemplate, Id TargetObjId) {
        if(commUser.email != null) {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            
            message.setTargetObjectId(commUser.contactid); 
            message.setSenderDisplayName('PEOSUPPORT_noreply@paychex.com'); 
            message.setReplyTo('sfdc_automation@paychex.com');
            message.setUseSignature(false); 
            message.setBccSender(false); 
            message.setSaveAsActivity(false); 
            message.setTemplateID(emailTemplate.Id);
            //message.toAddresses = new String[] {commUser.email};
            message.setWhatId(TargetObjId);
            messages.add(message);
        }
    }
    
    //Created the chatter post to send to the rep and NSC
    public void createChatterPost(User commUser, Account acc, PEO_Onboarding_Checklist__c checklist, boolean dayFour, String chatterReason) {
        Set<Id> mentionList = new Set<Id>();
        String postText;
        
        //Build the chatter message
        if(chatterReason == 'No Login') {
            if(dayfour) {
                postText = commUser.Name + ' from ' + acc.Name + ' has not logged into the PEO Getting Started portal yet. Portal invites expire after 7 days. Please reach out to '+ commUser.Name + ' today to follow up.You can resend their Welcome Email via their Contact Record in Salesforce if they have not logged in'; //SFDC-16673
            }
            else {
                postText = commUser.Name + ' from ' + acc.Name + ' has been sent an email reminder to login to the portal.';
            }  
        }
        else if(chatterReason == 'No Progress') {
            if(dayfour) {
                postText = commUser.Name + ' from ' + acc.Name + ' has logged into the PEO Getting Started portal but does not have recent activity. Please reach out to '+ commUser.Name + ' today to follow up.';
            }
            else {
                postText = commUser.Name + ' from ' + acc.Name + ' has been sent an email reminder to continue entering information in the portal.';
            }
        }
        else if(chatterReason == 'Open Disc') {
            if(dayfour) {
                
                postText = 'Hello '+ checklist.Prospect_Client__r.name + ' has unresolved discrepancies that require your attention. Please navigate to the Getting Started Questionnaires Summary Tab from one of the contacts related to this client to view these discrepancies.';
            }
            else {
                if(checklist.Discrepancy_Communication_method__c){
                    postText = 'Hello '+ checklist.Prospect_Client__r.name + ' has unresolved discrepancies that require your attention. Please navigate to the Getting Started Questionnaires Summary Tab from one of the contacts related to this client to view these discrepancies.';
                }
                if(!checklist.Discrepancy_Communication_method__c){
                    postText = 'Hello '+ checklist.Prospect_Client__r.name + ' has been sent an email reminder to handle their open discrepancies';
                }
            }
        }
        
        //Set the chatter recipients
        if(checklist.Sales_Rep__c != null) {
            mentionList.add(checklist.Sales_Rep__c);
        }
        /*if(checklist.PEO_NSC__c != null) {
            mentionList.add(checklist.PEO_NSC__c);
        }*/
        if(mentionList.size() > 0) {
            List<Id> mentList = new List<Id>();
            for (Id m : mentionList ) mentList.add(m);
            system.debug('++sent');
            ChatterMentionPost.createChatterMentionPost(checklist.Id, mentList, new String[]{postText},true,false);
            if(!chattersToPost) {
                chattersToPost = true;
            }
        }
    }
    
    private static final Date monday = Date.newInstance(1900, 1, 1);
    private static Integer getDayOfWeek(Date value) {
        return Math.mod(monday.daysBetween(value), 7);
    }
    
    public static Integer getWorkingDays(Date startDate, Date endDate) {
        //save some calculations when the number of working days is 0
        if(workingDaysInWeek == 0 || startDate == null || endDate == null) {
            return 0;
        } else {
            Integer difference = startDate.daysBetween(endDate);
            if(difference == 0) {
                //If the 2 dates are the same day check if the day is a working day or not
                return isWorkingDay[getDayOfWeek(startDate)] ? 1 : 0;
            } else if(workingDaysInWeek == 7) {
                //when every day is a working day return the difference
                return difference;
            } else {
                //The guts of the solution
                Integer wholeWeeks = Math.floor(difference / 7).intValue();
                Integer workingDays = wholeWeeks * workingDaysInWeek;
                Integer dayOfWeek = getDayOfWeek(endDate);
                for(Integer remainder = Math.mod(difference, 7); remainder >= 0; remainder--) {
                    if(isWorkingDay[dayOfWeek]) {
                        workingDays++;
                    }
                    dayOfWeek--;
                    if(dayOfWeek < 0) {
                        dayOfWeek = 6;
                    }
                }
                return workingDays;
            }
        }
    }
}