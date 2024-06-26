/*-- Sales to Service Quick Action page.
 * -------
 *  01/30/2018  Jermaine Stukes Created
 *  06/06/2018  Jermaine Stukes Added Chatter Messages
 *  07/20/2018  Jermaine Stukes Added File logic
 *  08/20/2018  Jermaine Stukes Call Queueable
 *  10/29/2018  Jake Hinds      Removing Email Opt out from DNC Account
 *  10/30/2018  Jermaine Stukes Added Transient tag to Blob variables
 *  10/31/2018  Jermaine Stukes Added Reload
 *  11/01/2018  Jermaine Stukes Updated updateInfo method
 *  11/01/2018  Lynn Michels    Added Sales2Support
 *  11/13/2018  Lynn Michels    changed the way the code is finding the queues for ownership 
 *  11/14/2018  Jermaine Stukes Added checkS2SObject Method
 *  11/15/2018  Lynn Michels    Adding in permissions for Sales2Support option
 *  11/19/2018  Lynn Michels    Post-imp changes for Sales2Support
 *  03/29/2019  Jermaine Stukes Added Web Sevice Log logic
 *  11/26/2019  Jermaine Stukes Removed UC Queueable logic, placed in Web Service Helper
 *  03/26/2020  Jake Hinds      Removing DMLHelper from save
	6/29/2020	Jake Hinds		Adding product multi-select
	08/20/2020  Jake Hinds		Moving chatter post to the case
	03/09/2021	Michael Karcz	Added DML Options to allow emailing on case creation
*/
public  with sharing class CaseS2SController 
{  
    public Contact s2sContact{get;set;}
    public Referral_Contact__c s2sRefContact{get;set;}
   // public Referral_Account__c refAccount{get;set;}
    public Case s2sCase {get;set;}
    public static String incomingId = ApexPages.CurrentPage().getParameters().get('id') != Null ? ApexPages.CurrentPage().getParameters().get('id') : '0037000001IaX6S'; 
    public static Schema.RecordTypeInfo refContactRT = RecordTypeHelper.getRecordType(label.RT_Case_RefContact, 'Case');
    public static Schema.RecordTypeInfo s2sRT = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case');
    public static Schema.RecordTypeInfo dncRT = RecordTypeHelper.getRecordType(label.RT_Case_DNC, 'Case');
    public static Schema.RecordTypeInfo s2supportRT = RecordTypeHelper.getRecordType(label.RT_Case_Sales2Support, 'Case');
    public string headerInfo1 {get;set;}
    public string headerInfo2 {get;set;}
    Public String headerDisplay{get;set;}
    public string redirectUrl {get;set;}
    public string buttonStyle {get;set;}
    Public String attachName{get;set;}
    Public String attachName2{get;set;}
    Public String attachName3{get;set;}
    Public String errorMessages{get;set;}
    Public String feedbackMessage{get;set;}
    Public String sldsBox{get;set;}
    //Public String styleDisplay{get;set;}
    Transient Public Blob attachBody{get;set;}
    Transient Public Blob attachBody2{get;set;}
    Transient Public Blob attachBody3{get;set;}
    Public Boolean disableButton{get;set;}
    Public Boolean displayMessages{get;set;}
    Public Boolean displayFields{get;set;}
    Public Boolean displayAttachments{get;set;}
    Public String objectName{get;set;}
    Public List<SelectOption> typeOptions{get;set;}
    Public String[] availableSubTypes; 
    Public List<SelectOption> subTypeOptions {
        get{
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('','--None--'));
            for(String subType:availableSubTypes){
                options.add(new SelectOption(subType,subType));
            }
            return options;
        }
    } 
    Public boolean displaySales2Support = false;
    Public boolean showMultiProduct{get;set;}
    
    public CaseS2SController()
    {   initialize();}
    
    public void initialize()
    {
        User runningUser = UserHelper.getRunningUser();
        String profileName = runningUser.Profile.Name;
                     
        Profile_List__c profileDataSet = Profile_List__c.getValues(profileName);
        system.debug('CaseS2SController initialize profileDataSet -' +  profileDataSet);
        if(profileDataSet != null && profileDataSet.Sales2Support__c == true){
            displaySales2Support = true; 
        }
        objectName = ObjectHelper.getObjectNameFromId(incomingId);
        buttonStyle = 'slds-button_success';
        disableButton = false;
        displayFields = true;
        s2sCase = new Case();
        redirectUrl = '/'+incomingId;
        
        List<String> multiProfileList = Label.S2SMultiProduct.split(';');
        Set<String> multiProfileSet = new Set<String>();
        multiProfileSet.addAll(multiProfileList);
        if((runningUser!=null && multiProfileSet.contains(runningUser.Profile.Name)) || FeatureManagement.checkPermission('S2SMultiProduct')){
            showMultiProduct = true;
            s2sCase.Product__c = 'Multi';
            system.debug('S2SController permission via label');  
        }
        
        updateInfo();
        checkMobile();
        
        
    }//Initialize
    public void reload()
    {
        initialize();
    }
   //Update the VF page header based on object accessing page
    public void updateInfo()
    {
        s2sCase.RecordTypeId = s2sRT.getRecordTypeId();
        typeOptions = new List<SelectOption>();
        switch on objectName
        {
            when 'Contact'
            {
                s2sContact = [Select id, Name, Account.Id, Account.Name, Account.Type, Account.HR_Generalist__r.User_Lookup__c, Email from Contact where id=:incomingId limit 1];
                s2sCase.ContactId = s2sContact.Id;
                s2sCase.AccountId = s2sContact.Account.Id;
                typeOptions.add(new SelectOption('--None--','--None--'));
                typeOptions.add(new SelectOption('Sales2Service','Sales2Service'));
                if (displaySales2Support == true){
                    typeOptions.add(new SelectOption('Sales2Support','Sales2Support'));
                }
                typeOptions.add(new SelectOption('Do Not Contact','Do Not Contact'));
                availableSubTypes = new String[]{'Do Not Call','Email Opt Out'};
                    
                //s2sCase.Type = 'Sales2Service';
                headerInfo1 = 'Contact Name: '+s2sContact.Name;
                headerInfo2 = 'Prospect-Client: '+s2sContact.Account.Name;
            }
            when 'Referral_Contact__c'
            {
                s2sRefContact = [Select Id, Name, Email__c, Referral_Account__r.Id, Referral_Account__r.Name from Referral_Contact__c where id=:incomingId limit 1];
                s2sCase.Referral_Contact__c = s2sRefContact.Id;
                s2sCase.Referral_Account__c = s2sRefContact.Referral_Account__r.Id;
                typeOptions.add(new SelectOption('Act Support','Act Support'));
                s2sCase.Type = 'Act Support';
               // s2sCase.Origin = 'S2S App';
               // s2sCase.OwnerId = label.s2s_Act_Queue;
               // s2sCase.RecordTypeId = refContactRT.getRecordTypeId();
                headerInfo1 = 'Referral Contact Name: '+s2sRefContact.Name;
                headerInfo2= s2sRefContact.Referral_Account__c != Null ? 'Referral Account: '+s2sRefContact.Referral_Account__r.Name : ''; 
            }
            when 'Account'
            {
                typeOptions.add(new SelectOption('--None--','--None--'));
                typeOptions.add(new SelectOption('Sales2Service','Sales2Service'));
                if (displaySales2Support == true){
                    typeOptions.add(new SelectOption('Sales2Support','Sales2Support'));
                }
                typeOptions.add(new SelectOption('Do Not Contact','Do Not Contact'));
                //s2sCase.Type = 'Do Not Contact';
                availableSubTypes = new String[]{'Do Not Call'};
                s2sCase.Sub_Type__c = 'Do Not Call';
                Account acct = [Select id, Name from Account where id=:incomingId limit 1];
                headerInfo1 = 'Prospect-Client Name: '+acct.Name;
                headerInfo2= ''; 
                s2sCase.AccountId = acct.Id;
            }
            when 'Lead'
            {
                typeOptions.add(new SelectOption('--None--','--None--'));
                typeOptions.add(new SelectOption('Sales2Service','Sales2Service'));
                if (displaySales2Support == true){
                    typeOptions.add(new SelectOption('Sales2Support','Sales2Support'));
                }
                typeOptions.add(new SelectOption('Do Not Contact','Do Not Contact'));
                availableSubTypes = new String[]{'Do Not Call','Email Opt Out'};
                //s2sCase.Type = 'Do Not Contact';
                Lead ld = [Select id, Name, Company from 
                              Lead where id=:incomingId limit 1];
                headerInfo1 = 'Lead Name: '+ld.Name;
                headerInfo2= '';       
                s2sCase.Lead__c = ld.Id;
            }
        }
    }//Update Info
    
    public void checkS2SObject()
    {
        displayFields = true;
        if(s2sCase.Type == 'Sales2Service' && objectName !='Contact')
        {
            String message = Label.S2S_NonContact_Message;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, message)); 
            displayMessages = true;
            displayFields = false;
        }
    }
    //Check Environment
    public void checkMobile()
    {
        boolean mobile = Utilities.isSF1();
        //styleDisplay = (mobile ? 'slds-size_1-of-1' : 'slds-p-right_xx-small slds-size_1-of-2');
        displayAttachments = (mobile ? false : true);
        feedbackMessage = (mobile ? 'Feedback: ' : 'Send feedback on Sales2Service tool to: ');
        sldsBox = (mobile ? 'slds-box slds-theme_default' : 'slds-p-top_medium');
        headerDisplay = (mobile ? 'slds-text-body_medium' : 'slds-text-heading_medium');
    }//Check Mobile
    
    //Verify required fields complete based on Case Type 
    public boolean validateCase()
    {
        Boolean caseValid = true;
        S2S_Case_Types__c caseType = S2S_Case_Types__c.getValues(s2sCase.Type);
        if(caseType!=Null)
        {
            List<String> fieldValues = caseType.Field_List__c.split(',');
            for(String caseField : fieldValues)
            {
                system.debug('CaseS2SController validateCase '+caseField+' : '+s2sCase.get(caseField));
                if(String.isBlank(String.valueOf(s2sCase.get(caseField))))
                {caseValid = false;}
            }
        }
        else
        {caseValid = false;}
        return caseValid;
    }//Validate Case
    
    //Send Chatter messages after case is saved
    public void sendChatterConfirmations()
    {
        Case kase = [Select Id,ownerId, Alternate_Contact__c, Alternate_Contact__r.User_Lookup__c, CaseNumber, Account.Name from Case where id=:s2sCase.Id limit 1];
        List<String> userList = new List<String>();

            String chatterMessage = kase.Account.Name !=Null ? 'Your ' +s2sCase.Type+ ' case #'+kase.CaseNumber+' for '+kase.Account.Name+' has been successfully received. ' :
                                                            'Your ' +s2sCase.Type+ ' case #'+kase.CaseNumber+' has been successfully received.';
            //String successMessage = 'A New ' +s2sCase.Type+ 'Case Created: ';

            /*String chatterMessage = kase.Account.Name !=Null ? 'Your Sales2Service case #'+kase.CaseNumber+' for '+kase.Account.Name+' has been successfully received. ' :
                                                            'Your Sales2Service case #'+kase.CaseNumber+' has been successfully received.';
            String successMessage = 'A New Sales2Service Case Created: ';
*/
        //String caseLink = '<a href="/'+s2sCase.Id+'" target="_blank"><b><font face="verdana" color="blue">Click to go to case</font></b></a>';
        if(kase.Alternate_Contact__c!=Null && kase.Alternate_Contact__r.User_Lookup__c != Null)
        {userList.add(kase.Alternate_Contact__r.User_Lookup__c);}
        //Create Chatter messages
        //ChatterMentionPost.createChatterMentionPost(s2sContact != Null ? s2sContact.Id : s2sCase.Referral_Contact__c,userList,chatterMessage);
        ChatterMentionPost.createChatterMentionPost(kase.Id,userList,chatterMessage);
        //Send HRG chattermessage
        if(s2sContact != Null && s2sContact.Account.HR_Generalist__r.User_Lookup__c != Null)
        {
            List<String> hrgList = new List<String>();
            hrgList.add(s2sContact.Account.HR_Generalist__r.User_Lookup__c);
            ChatterMentionPost.createChatterMentionPost(s2sCase.Id,hrgList,'A new Sales2Service '+s2sCase.Product__c+' Case has been created for Client: '+s2sContact.Account.Name);
        }
        if(!String.valueOf(kase.OwnerId).startsWith('00G'))
        {
            userList.add(kase.ownerId);
            ChatterMentionPost.createChatterMentionPost(s2sCase.Id,userList,'This Sales2Service Case has been assigned to you:');
        }
        ChatterMentionPost.checkPostFeedElements();
        createConfirmationMessage();
        //Create confirmation message
        //LM ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, successMessage+caseLink)); 
    }//sendChatterConfirmations
    
    public void createConfirmationMessage(){
        Case updatedCase = [SELECT Id,CaseNumber FROM Case WHERE Id=:s2sCase.Id LIMIT 1];
        if(updatedCase!=null){
            String caseLink = '<a href="/'+s2sCase.Id+'" target="_blank"><b><font face="verdana" color="blue">Case '+updatedCase.CaseNumber+'</font></b></a>';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'A new ' +s2sCase.Type+ ' case has been created. Please follow the link to view your case: '+caseLink));
        }//end if
    }//end createConfirmationMessage   

    public void saveKase()
    {
        system.debug('CaseS2SController saveKase');
        if(validateCase())
        {
            s2sCase.ProcessNotes__c = 'Submitted through S2S QA';
            switch on s2sCase.Type
            {
                when 'Sales2Service'
                {saveS2SCase();}
                when 'Sales2Support'
                {saveCase();}
                when 'Do Not Contact'
                {saveCase();}
                when 'Act Support'
                {saveActCase();}
            }
        
        }else{
            system.debug('CaseS2SController validate failed');
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Please enter all required information prior to saving case.')); }
        displayMessages = true;
    }
    //Save Case
    public void saveActCase()
    {
        try
        {
            if(!s2sCase.Notify_Owner__c ||(s2sCase.Notify_Owner__c && s2sRefContact.Email__c != Null))
            {   
                s2sCase.Origin = 'S2S App';
                //s2sCase.OwnerId = label.s2s_Act_Queue;
                s2sCase.OwnerId = new UserHelper().getQueue('ACT Service').id;
                s2sCase.RecordTypeId = refContactRT.getRecordTypeId();
                insert s2sCase;
                saveAtt(null);
                sendChatterConfirmations();
                disableButton = true;
            }
            else
            {ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING,'Referral Contact does not have an email address. Unable to send confirmation email. Please uncheck the Send confirmation email to contact checkbox or update the Referral Contact\' s email address to save the case.')); }              
        }
        catch(Exception ex)
        {ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, ex.getMessage())); }
    }
    public void saveS2SCase()
    {   
        try
        {
            if(!s2sCase.Notify_Owner__c ||(s2sCase.Notify_Owner__c && s2sContact.Email != Null))
            {
                //DMLOptions used to allow email notifications on cases being submitted
                Database.DMLOptions dlo = new Database.DMLOptions();
                dlo.EmailHeader.triggerAutoResponseEmail = true;
                //Save S2S Case
                //DmlHelper.performDML2(new Case[]{s2sCase}, DmlHelper.DML_INSERT, 'CaseS2SController', 'saveS2SCase', 'saveS2SCase', true);
                if(String.IsNotBlank(s2sCase.Products_Multi__c)){
                    String[] multiProducts = s2sCase.Products_Multi__c.split(';');
                    if(multiProducts.size() == 1){
                        s2sCase.Product__c = multiProducts[0];
                        s2sCase.Products_Multi__c = null;
                    }
                }
                
                //insert s2sCase;
                if(s2sCase.ownerId != null && ((String)s2sCase.ownerId).startsWith('00G')) Database.insert(s2sCase, dlo); //if it's a queue, use the DMLOptions to allow email notification on case assignment
                else insert s2sCase;
                //Save Attachments
                list<String> bigFiles = new list<String>();
                saveAtt(bigFiles);
                sendChatterConfirmations();
                disableButton = true;
                Case kase = [Select Id, OwnerId from Case where Id=:s2sCase.Id];
                if(String.valueOf(kase.OwnerId) == label.UC_Queue)
                {
                    WebServicesHelper whHelper = new WebServicesHelper();
                    whHelper.createWsLog(kase.Id);
                    //processUcJob(kase.Id, false, false);
                    if(!bigFiles.isEmpty())
                    {
                        String fileToBigMessage = 'The following Attachment(s) may be too large to send to the service rep. Please email the attachment(s) to the assigned service rep: \n' + bigFiles;                        
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, fileToBigMessage));}
                }
            }
            else
            {ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING,'Contact does not have an email address. Unable to send confirmation email. Please uncheck the Send confirmation email to contact checkbox or update the contact\' s email address to save the case.')); }              
        }
        catch(Exception ex)
        {
            String validationException = 'FIELD_CUSTOM_VALIDATION_EXCEPTION, ';
            System.debug('***EXCEPTION***'+ex.getMessage());
            /*if(ex.getMessage().contains('Escalations for non multi product clients cannot be submitted using this case') && 
               (s2sContact.Account.Type =='FLEX Client' || s2sContact.Account.Type =='HR Solutions FLEX Client'))
            {
                string errorLink = '<a href="https://sp13-teams.paychex.com/sites/payx-mobile-apps/_layouts/15/payx-sales-escalation/default.aspx" target="_blank"><b><font face="verdana" color="blue">S2S SharePoint App</font></b></a>';
                errorMessages ='Error: Unable to submit this case through Salesforce. This is an SMB Payroll client, please submit the case through the '+errorLink;
            }
            else */
            if(ex.getMessage().contains(validationException))
            {errorMessages = ex.getMessage().substringAfter(validationException);}
            else
            {
                errorMessages = ex.getMessage();
                ErrorLog.logError('CaseS2SController','saveS2SCase','saving s2s case',null,ex,s2sCase,true);            
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, errorMessages)); 
        }
    }//saveS2SCase
   /* Public Web_Service_Log__c createWsLog(Id caseId){
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        wslog.SobjName__c =  'Case';
        wsLog.CalledBy__c = UserInfo.getUserId();
        wsLog.CalledDT__c = System.now();
        wsLog.ServiceName__c = 'CaseS2SQueuable';
        wsLog.NbrAttempts__c = 1;
        wsLog.CreateDate__c = Date.Today();
        wsLog.Action__c = 'Create case in UC';
        wsLog.NamedFunction__c = 'createUcCase';
        wsLog.Rest_Response__c = null;
        wsLog.UC_Service__c = true;
        wsLog.UcServiceCaseId__c = caseId;
        DmlHelper.performDML2(new Web_Service_Log__c[]{wsLog}, DmlHelper.DML_INSERT, 'CaseS2SController', 'createWsLog', 'createWsLog', true);
        return wsLog;
    }
    Public void processUcJob(Id kaseId, Boolean reassignSkill, Boolean caseUpdated)
    {
        //Create Web Service Log
        WebServiceHelper.createWsLog(kaseId);
       /* Web_Service_Log__c ucLog = createWsLog(kaseId);
        //Run Queueable Job
        CaseS2SQueueable cS2S = new CaseS2SQueueable(kaseId, ucLog);
        //cS2S.routeToUC(kaseId, reassignSkill, false, caseUpdated, ucLog);
        cS2S.launchQueueable(cS2S);
    }
    /*public void updateWsLog(CaseS2SQueueable cS2S,Web_Service_Log__c UC_Log ){
        if(cS2S.apexJobId != null){
            UC_Log.UC_Apex_Job_Id__c = cS2S.apexJobId;
            //Verify Job completed
        }
        else{
            UC_Log.ErrorMsg__c='No APEX Job Created';
            UC_Log.Successful__c = false;
            UC_Log.UC_Retry__c = true;
        }
        DmlHelper.performDML2(new Web_Service_Log__c[]{UC_Log}, DmlHelper.DML_UPDATE, 'CaseS2SController', 'updateWsLog', 'updateWsLog', true);
        //update UC_Log;
    }*/
    Public void saveAtt(list<String> bigFiles)
    {
        Integer sizeLimit = test.isRunningTest() ? 30 : Integer.valueOf(label.UC_Attachment_Size_Limit);
        Id[]  fileParent= new Id[]{s2sCase.id};
        AddFileQueueable afq = new AddFileQueueable();
        if(attachBody!=Null){
            afq.addAnotherFile(fileParent, attachName, attachName,Null , attachBody);
            if(bigFiles != null && attachBody.size() > sizeLimit){
                bigFiles.add(attachName);
            }
        }
        if(attachBody2!=Null){
            afq.addAnotherFile(fileParent, attachName2, attachName2,Null , attachBody2);
            if(bigFiles != null && attachBody2.size() > sizeLimit){
                bigFiles.add(attachName2);
            }
        }
        if(attachBody3!=Null){
            afq.addAnotherFile(fileParent, attachName3, attachName3,Null , attachBody3);
            if(bigFiles != null && attachBody3.size() > sizeLimit){
                bigFiles.add(attachName3);
            }
        }
        try
        {
            afq.processRecs();
            attachBody = Null;
            attachBody2 = Null;
            attachBody3 = Null;
            attachName = Null;
            attachName2 = Null;
            attachName3 = Null;
        }
        catch(Exception ex)
        {
            errorMessages = ex.getMessage();
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'APEX Line Num: '+ ex.getlineNumber()+' Error: '+ex.getMessage()));
        }
    }//saveAtt
    public void saveCase(){
       if(s2sCase.Type == 'Do Not Contact'){
            s2sCase.RecordTypeId = dncRT.getRecordTypeId();
            s2sCase.Subject = s2sCase.Sub_Type__c+' Request';
            s2sCase.Origin = 'S2S Submission';
        }
        else if (s2sCase.Type =='Sales2Support'){
            s2sCase.Origin = 'Salesforce Case';
            s2sCase.OwnerId = new UserHelper().getQueue('Sales Support - HR Services').id;
            s2sCase.RecordTypeId = s2supportRT.getRecordTypeId();
        }
        
        try{
            insert s2sCase; 
            disableButton = true;
            saveAtt(null);
            if (s2sCase.Type =='Sales2Support'){
                sendChatterConfirmations();
            }
            else{
                createConfirmationMessage();
            }
            
        }
        catch(Exception ex){
        system.debug('CaseS2SController saveCase catch');
            String validationException = 'FIELD_CUSTOM_VALIDATION_EXCEPTION, ';
            if(ex.getMessage().contains(validationException))
            {
                errorMessages = ex.getMessage().substringAfter(validationException);
                }
            else
            {
                errorMessages = ex.getMessage();
                }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, errorMessages));
        }
    }
}