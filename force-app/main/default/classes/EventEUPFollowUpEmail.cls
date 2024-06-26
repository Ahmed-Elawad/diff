/* 
 * Sends marketing email after EUP.  Called from EventCheckData.trigger, workflow Automated HCM Followup Email
 *
 * History
 * -------
 * 12/04/2017 Jake Hinds    Created
 * 12/25/2018 Jake Hinds    Making this work better in bulk
 * 01/31/2018 Jake Hinds    Adding opt out flag on opportunity
 * 02/28/2018 Jake Hinds    Adding task receipt
 */
public with sharing class EventEUPFollowUpEmail {
    //keep track of events by ID that email already was sent for
    public static Map<Id,Messaging.SingleEmailMessage> emailsAlreadySent;
    //for test class
    public static Boolean emailSent;
    
    @InvocableMethod
    public static void sendEUPFollowUp(List<Event> eupEvents){
        //track emails that were sent, meant to prevent recursion
        if(emailsAlreadySent==null){
            emailsAlreadySent = new Map<Id,Messaging.SingleEmailMessage>();
        }
        //hold the emails to be sent out in bulk at the end
        Messaging.SingleEmailMessage[] emailsToSend = new Messaging.SingleEmailMessage[]{};
        emailSent = false;
        
        //check for sandbox, don't send to clients if we're in a sandbox
        String sbxName = Utilities.checkForProduction();
        Boolean isSandbox = (sbxName!=null && String.isNotBlank(sbxName));
        system.debug('EventEUPFollowUpEmail in sendEUPFollowup isSandbox'+isSandbox+' '+sbxName);
        
        //set map of all sales reps who own these events, related contact and opportunity
        Id[] ownerIds = new Id[]{};
        Id[] contactIds = new Id[]{};
        Id[] opptyIds = new Id[]{};
        for(Event e:eupEvents){
            //remove event from events to process if we've already processed this one, used to try and prevent recursion
            if(emailsAlreadySent.containsKey(e.Id)){
                eupEvents.remove(eupEvents.indexOf(e));
            }
            else{
                ownerIds.add(e.OwnerId);
                contactIds.add(e.WhoId);
                opptyIds.add(e.WhatId); 
            }
        }
        if(!eupEvents.isEmpty() && !ownerIds.isEmpty() && !contactIds.isEmpty() && !opptyIds.isEmpty()){
            //is there a way to do this in one query? maybe start query from opportunity, opp.owner, opp(select contact) instead of event stuff?
            Map<Id,User> repMap = new Map<Id,User>([SELECT FirstName,LastName,Email,Phone FROM User where Id in :ownerIds]);
            Map<Id,Contact> ctctMap = new Map<Id,Contact>([SELECT FirstName,LastName,Email,Phone,HasOptedOutOfEmail,CPA_Sensitivities_Flag__c,Account.Type FROM Contact where Id in :contactIds]);
            Map<Id,Opportunity> opptyMap = new Map<Id,Opportunity>([SELECT StageName,isClosed,Type,EUP_Email_Opt_Out__c,OpportunityType__c FROM Opportunity where Id in :opptyIds]);
            
            //the email template is stored as two separate static resources, since we have to manually populate all of the merge fields.
            //Id templateId = [select id, name from EmailTemplate where developername = 'Post_EUP_Email'].id;
            String[] resourceNames = new String[]{'Post_EUP_Email_HTML','Post_EUP_Email_TXT'};
            list<StaticResource> resourceList = [select name,body from StaticResource where name in :resourceNames Limit 2];
            StaticResource eupEmailResourceHTML;
            StaticResource eupEmailResourceTXT;
            for(StaticResource sr:resourceList){
                if(sr.Name=='Post_EUP_Email_HTML'){
                    eupEmailResourceHTML=sr;
                }
                else if(sr.Name=='Post_EUP_Email_TXT'){
                    eupEmailResourceTXT=sr;
                }
            }
            for(Event e:eupEvents){
                String emailBodyHTML;
                String emailBodyTXT;
                User salesRep = repMap.get(e.OwnerId);
                Contact ctct = ctctMap.get(e.WhoId);
                Opportunity oppty = opptyMap.get(e.WhatId);
                system.debug('eupEmail oppty: '+oppty+' ctct: '+ctct+' rep: '+salesRep);
                if(salesRep != null && ctct!=null && oppty!=null && ctct.Email!=null && !ctct.HasOptedOutOfEmail && ctct.CPA_Sensitivities_Flag__c == null 
                    && ctct.Account.Type != 'SurePayroll' && !oppty.isClosed && !oppty.StageName.startsWith('Sold') && (oppty.Type == 'Payroll' || oppty.OpportunityType__c == 'Payroll') 
                    && !oppty.EUP_Email_Opt_Out__c){
                    // prepare email for sending
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    
                    //string parsing will error out if any of these are null when we go to replace them, check if null first
                    String ctctFirstName=(ctct.FirstName!=null?ctct.FirstName:'');
                    String salesRepName=(salesRep.FirstName!=null && salesRep.LastName != null ? salesRep.FirstName+' '+salesRep.LastName:'');
                    String salesRepEmail=(salesRep.Email != null ? salesRep.Email : '');
                    String salesRepPhone=(salesRep.Phone != null ? salesRep.Phone : '');
                    String todayString = date.today().month()+'/'+date.today().day()+'/'+date.today().year();
                    //build html body
                    if (eupEmailResourceHTML != null){
                        try {
                           emailBodyHTML = eupEmailResourceHTML.body.toString();
                           emailBodyHTML = emailBodyHTML.replace('{!Contact.FirstName}',ctctFirstName);
                           emailBodyHTML = emailBodyHTML.replace('{!User.Name}',salesRepName);
                           emailBodyHTML = emailBodyHTML.replace('{!User.Email}',salesRepEmail);
                           emailBodyHTML = emailBodyHTML.replace('{!User.Phone}',salesRepPhone);
                           emailBodyHTML = emailBodyHTML.replace('{!Today}',todayString);
                        } catch (Exception ex) {
                           System.debug('createEmailBody exception: '+ex.getStackTraceString());
                           emailBodyHTML = '';
                        } 
                    } // if(eupEmailResource != null
                    //build txt body
                    if (eupEmailResourceTXT != null){
                        try {
                           emailBodyTXT = eupEmailResourceTXT.body.toString();
                           emailBodyTXT = emailBodyTXT.replace('{!Contact.FirstName}',ctctFirstName);
                           emailBodyTXT = emailBodyTXT.replace('{!User.Name}',salesRepName);
                           emailBodyTXT = emailBodyTXT.replace('{!User.Email}',salesRepEmail);
                           emailBodyTXT = emailBodyTXT.replace('{!User.Phone}',salesRepPhone);
                           emailBodyTXT = emailBodyTXT.replace('{!Today}',todayString);
                        } catch (Exception ex) {
                           System.debug('createEmailBody exception: '+ex.getStackTraceString());
                           emailBodyTXT = '';
                        } 
                    } // if(eupEmailResource != null
                    //if sandbox, send to running user. Can't save activity when sending to user.  Not sure if we can save activity due to high volume 1.25.18
                    if(isSandbox){
                        mail.setTargetObjectId(e.CreatedById);
                        mail.setSaveAsActivity(false);
                    }
                    else{
                        mail.setTargetObjectId(e.WhoId);
                        mail.setSaveAsActivity(true);
                    }
                    mail.setWhatId(e.WhatId);
                    mail.setSubject('Follow-up on Paychex Payroll & HR');
                    mail.setHTMLBody(emailBodyHTML);
                    mail.setPlainTextBody(emailBodyTXT);
                    mail.setSenderDisplayName(salesRep.FirstName+' '+salesRep.LastName);
                    //mail.setTemplateId(templateId);
                    mail.setReplyTo(salesRep.Email);
                    mail.setBccSender(false);
                    mail.setCcAddresses(new String[]{salesRep.email});
                    mail.setUseSignature(false);    
                    if(!Test.isRunningTest()){
                        emailsToSend.add(mail);
                    }//if(!emailsAlreadySent.containsKey
                    else if(Test.isRunningTest()){
                        emailSent = true;
                    }
                }//if(salesRep != null
            }//for(Event e:eupEvents
        }//if(!eupEvents.isempty
        
        if(emailsToSend!=null && !emailsToSend.isEmpty()){
            try {
                Messaging.sendEmail(emailsToSend);
                system.debug('EventEUPFollowUpEmail in sendEUPFollowup message sent');
                /*create task - Commented out because of mail.setSaveAsActivity(true) above
                Task[] tasks = new Task[]{};
                User sfdcData = [SELECT Id FROM User WHERE FirstName = 'SFDC' AND LastName = 'Data' AND Alias = 'sdata' LIMIT 1];
                ID rtID = RecordTypeHelper.getRecordType('Sys Admin Task Record Type','Task').getRecordTypeId(); */
                for(Messaging.SingleEmailMessage mail:emailsToSend){
                    emailsAlreadySent.put(mail.getWhatId(),mail);
                    /*if(sfdcData!=null && rtId!=null){
                        Task t = new Task(OwnerId = sfdcData.Id,WhatId = mail.getWhatId(),RecordTypeId = rtID,Subject='Automated HCM Email Sent',Status='Completed',
                                        Priority='Normal',Description='This task was generated as a sent receipt for the Automatic HCM Email',ActivityDate = system.today());
                        tasks.add(t);
                    }*/
                }
                /*if(!tasks.isEmpty()){
                    //DmlHelper.performDML2(tasks, DmlHelper.DML_INSERT, 'EventEUPFollowUpEmail', 'sendEUPFollowup', 'Insert Task Receipts', false);
                }*/
            }
            catch (EmailException err) {
                ErrorLog.logError('EventEUPFollowUpEmail', 'sendEUPFollowUp', 'sending email to client', null, err);
            }
            ErrorLog.checkSave();
        }   
    }//sendEUPFollowUp
}