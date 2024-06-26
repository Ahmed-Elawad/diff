/* Methods for working with the EmailMessage object

Before trigger: set Template, Number of Opens
After trigger: If has activity id and contact and lead blank, look up activity
After we have contact and lead, check number of opens
If LastOpenedDate changed, check contacts and leads for latest opens


History
-------
04/16/2021 Dan Carmen   Created
01/24/2022 Jaipal Added check for securities license checbox and generates email
02/25/2022 Dan Carmen   Added check if runningUser is null
07/11/2022 Dan Carmen   Change query for checkAcctOpens
05/17/2023 Dan Carmen   Additional logic around the Securities_License__c user field
03/01/2024 Shilpa G		APR0159245: Updated method handleTrigger to add additional filters to avoid FINRA BCC Email to be sent when email is logged from Outlook
03/06/2024 Dan Carmen   Exclude paychex contacts from the ctctMap

*/
public without sharing class EmailMessageMethods {
    public static Boolean SKIP_TRIGGER=false;
    
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        // right now we only need the running user on insert
        User runningUser = (Trigger.isInsert ? UserHelper.getRunningUser() : null);
        system.debug('emailmessagemethods');	
        // List<emailtemplate> emailtemplateidList =[select id,name from EmailTemplate where name ='BccAddress' limit 1];	
        //   system.debug('emailtemplateidList'+emailtemplateidList.get(0));	
        Map<Id, EmailMessage> EmailMessageOldMap = (Map<Id, EmailMessage>) oldMap;	
        System.debug('EmailMessageMethods.handleTrigger recs='+recs.size()+' isBefore='+isBefore+' isAfter='+isAfter);
        EmailMessage[] emails = (EmailMessage[])recs;
        Id[] templateIds = new Id[]{}; 
        Id[] checkActivityIds = new Id[]{};
        Id[] checkEmailMsgIds = new Id[]{};
        EmailMessage[] checkBeforeRecs = new EmailMessage[]{};
        Id[] leadIds = new Id[]{};
        Id[] ctctIds = new Id[]{};
        list<EmailMessage> bccAddressBlankemails = new list<EmailMessage>();
        
        for (EmailMessage email : emails) {
            EmailMessage oldM = (oldMap != null ? (EmailMessage)oldMap.get(email.Id) : null);
            if (isBefore) {
                StringHelper.addToProcessNotes(email,'handleTrigger LastOpenedDate='+email.LastOpenedDate);
            }
            if (isBefore && email.LastOpenedDate != null) {
                System.debug('EmailMessageMethods.handleTrigger email.LastOpenedDate='+email.LastOpenedDate);
                // increment 1 here. We might be able to pull it later from the contacts/leads, but just in case
                if (oldM == null || (oldM.LastOpenedDate == null) || (email.LastOpenedDate > oldM.LastOpenedDate )) {
                    email.NumberOfOpens__c = (email.NumberOfOpens__c == null ? 0 : email.NumberOfOpens__c) + 1;
                    System.debug('EmailMessageMethods.handleTrigger email.NumberOfOpens__c='+email.NumberOfOpens__c);
                }
            }	
            if (isAfter) {
                // check all records after
                checkEmailMsgIds.add(email.Id);
                // if the activity id is populated but the lookups aren't, then try to populate them
                //if (email.ActivityId != null && email.Contact__c == null && email.Lead__c == null) {
                //   Id activityId = (Id)email.ActivityId;
                //   System.debug('EmailMessageMethods.handleTrigger 1 activityId='+activityId);
                //   checkActivityIds.add(activityId);
                //}
                //APR0159245: Updated below if to add filter on Header field to avoid FINRA BCC Email to be sent when email is logged from Outlook
                if (Trigger.isInsert && email.SenderRequiresBCC__c && String.isBlank(email.BccAddress) && (String.isBlank(email.Headers) || (email.Headers != null && !email.Headers.contains(Label.FINRA_Outlook_Activity)))) {
                    bccAddressBlankemails.add(email);
                }
            }
            if (isBefore && Trigger.isInsert) {
                email.SenderRequiresBCC__c = (runningUser != null && runningUser.Securities_License__c);
                if (email.EmailTemplateId != email.EmailTemplateId__c) {
                    email.EmailTemplateId__c = email.EmailTemplateId;
                    if (email.EmailTemplateId != null) {
                        templateIds.add(email.EmailTemplateId);
                    }
                }
            }
            if (isAfter) {
                System.debug('EmailMessageMethods.handleTrigger activityId='+email.ActivityId);
            }
        } // for (EmailMessage email : emails
        if(!bccAddressBlankemails.isEmpty()){
            //User runningUser =UserHelper.getRunningUser();
            if(runningUser != null && runningUser.Securities_License__c){
                //Id ManagerId=runningUser.managerId !=null ? runningUser.managerId:null;
                //User RunningUserManager=[Select id,email from User where id=:ManagerId];
                //String MangerEmail=String.IsNotBlank(RunningUserManager.email)? RunningUserManager.email:'';
                List<emailtemplate> emailtemplateidList =[select id,name from EmailTemplate where name ='BccAddress' limit 1];
                
                list<String>emailIdsToSend =new List<String>((Label.DSM_and_christine_team_email).split(','));
                if (runningUser.Manager != null && runningUser.Manager.Email != null) {
                   emailIdsToSend.add(runningUser.Manager.Email);
                }
                list<Messaging.SingleEmailMessage> sendemails =new list<Messaging.SingleEmailMessage>();
                if (!emailtemplateidList.isEmpty()) {
                    
                   for(EmailMessage email : BccAddressBlankemails){
                       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                       mail.setToAddresses(emailIdsToSend);
                       mail.setTemplateId(emailtemplateidList.get(0).id);
                       //mail.setWhatId(UserInfo.getUserId());
                       mail.setTargetObjectId(UserInfo.getUserId());
                       mail.setSaveAsActivity(false); 
                       sendemails.add(mail); 
                   } // for(EmailMessage email
                } // if (!emailtemplateidList
                if ( !sendemails.isEmpty()) {
                    Messaging.sendEmail(sendemails);
                }
            }
        }
        System.debug('EmailMessageMethods.handleTrigger templateIds='+templateIds.size()+' checkEmailMsgIds='+checkEmailMsgIds.size()+' checkBeforeRecs='+checkBeforeRecs.size());
        if (!templateIds.isEmpty()) {
            Map<Id,EmailTemplate> templateMap = new Map<Id,EmailTemplate>([Select Id, Name, FolderId, FolderName from EmailTemplate where Id in :templateIds]);
            for (EmailMessage email : emails) {
                EmailTemplate template = (email.EmailTemplateId__c != null ? templateMap.get(email.EmailTemplateId__c) : null);
                if (template != null) {
                    email.EmailTemplateName__c = template.Name;
                    email.EmailTemplateFolder__c = template.FolderName;
                    email.EmailTemplateFolderId__c = template.FolderId;
                }
            }
        } // if (!emailTemplateIds.isEmpty
        
        if (!checkEmailMsgIds.isEmpty()) {
            if (Utilities.allowFuture()) {
                System.debug('handleTrigger sending via future checkEmailMsgIds='+checkEmailMsgIds.size());
                checkMsgsFuture(checkEmailMsgIds);
            } else {
                System.debug('handleTrigger sending now checkEmailMsgIds='+checkEmailMsgIds.size());
                checkMsgsNow(checkEmailMsgIds);
            }
        } // if (!checkEmailMsgIds.isEmpty
        
    } // handleTrigger
    
    public static Map<Id,Lead> getLeadMap(Id[] leadIds) {
        Datetime dateForQuery = Datetime.now().addDays(-10);
        Integer emailStatusLimit = 5;
        Map<Id,Lead> leadMap = (leadIds.isEmpty() ? new Map<Id,Lead>()
                                : new Map<Id,Lead>([Select Id, EmailLastSent__c, EmailLastOpened__c, NumberOfOpens__c, IsConverted
                                                    ,(Select Id, TaskId, CreatedDate, LastModifiedDate, TimesOpened, FirstOpenDate, LastOpenDate, EmailTemplateName, WhoId 
                                                      from EmailStatuses 
                                                      where LastModifiedDate >:dateForQuery order by LastModifiedDate desc limit :emailStatusLimit) 
                                                    from Lead where Id in :leadIds]));
        return leadMap;        
    } // getLeadMap
    
    public static Map<Id,Contact> getCtctMap(Id[] ctctIds) {
        Datetime dateForQuery = Datetime.now().addDays(-10);
        Integer emailStatusLimit = 5;
        Map<Id,Contact> ctctMap = (ctctIds.isEmpty() ? new Map<Id,Contact>()
                                   : new Map<Id,Contact>([Select Id, EmailLastSent__c, EmailLastOpened__c, NumberOfOpens__c
                                                          ,AccountId, Account.Id, Account.EmailLastSent__c, Account.EmailLastOpened__c, Account.NumberOfOpens__c
                                                          ,(Select Id, TaskId, CreatedDate, LastModifiedDate, TimesOpened, FirstOpenDate, LastOpenDate, EmailTemplateName, WhoId 
                                                            from EmailStatuses 
                                                            where LastModifiedDate >:dateForQuery order by LastModifiedDate desc limit :emailStatusLimit) 
                                                          from Contact where HR_Person_ID__c = null and Id in :ctctIds]));
        return ctctMap;
    } // getCtctMap
    
    @future
    public static void checkMsgsFuture(Id[] checkEmailMsgIds) {
        checkMsgsNow(checkEmailMsgIds);
    } // checkActivityFuture
    
    public static void checkMsgsNow(Id[] checkEmailMsgIds) {
        EmailMessage[] msgs = [Select Id, ActivityId
                               ,Account__c
                               ,Contact__c
                               ,Lead__c
                               ,NumberOfOpens__c
                               ,CreatedDate, LastOpenedDate, ProcessNotes__c 
                               from EmailMessage where Id in :checkEmailMsgIds];
        Map<Id,EmailMessage> activityMap = new Map<Id,EmailMessage>();
        Id[] leadIds = new Id[]{};
            Id[] ctctIds = new Id[]{};
                
                for (EmailMessage msg : msgs) {
                    if (String.isNotBlank(msg.ActivityId) && msg.Contact__c == null && msg.Lead__c == null) {
                        activityMap.put(msg.ActivityId, msg);
                    }
                    if (msg.Contact__c != null) {
                        ctctIds.add(msg.Contact__c);
                    } else if (msg.Lead__c != null) {
                        leadIds.add(msg.Lead__c);
                    }
                }
        
        
        System.debug('checkMsgsNow checkEmailMsgIds='+checkEmailMsgIds.size()+' msgs='+msgs.size()+' activityMap='+activityMap.size());
        Map<Id,EmailMessage> updateMsgMap = new Map<Id,EmailMessage>();
        checkTasks(activityMap, updateMsgMap, leadIds, ctctIds);
        checkCtctLeads(msgs, updateMsgMap, leadIds, ctctIds);
    } // checkMsgsNow
    
    // use the task to determine the lead/contact for the email message
    public static void checkTasks(Map<Id,EmailMessage> activityMap, Map<Id,EmailMessage> updateMsgMap, Id[] leadIds, Id[] ctctIds) {
        // assume only tasks for activity right now
        Task[] tsks = [Select Id, WhoId, WhatId, AccountId
                       From Task
                       Where Id in :activityMap.keySet()
                       and WhoId != null
                      ];
        for (Task tsk : tsks) {
            EmailMessage msg = activityMap.get(tsk.Id);
            if (msg != null) {
                Id whoId = tsk.WhoId;
                if (whoId.getSObjectType() == Lead.sObjectType) {
                    msg.Lead__c = whoId;
                    updateMsgMap.put(msg.Id,msg);
                    leadIds.add(whoId);
                } else if (whoId.getSobjectType() == Contact.sObjectType) { 
                    msg.Contact__c = whoId;
                    updateMsgMap.put(msg.Id,msg);
                    ctctIds.add(whoId);
                }
            }
        }
    } // checkTasks
    
    public static void checkCtctLeads(EmailMessage[] msgs, Map<Id,EmailMessage> updateMsgMap, Id[] leadIds, Id[] ctctIds) {
        Map<Id,Lead> leadMap = getLeadMap(leadIds);
        Map<Id,Contact> ctctMap = getCtctMap(ctctIds);
        Map<Id,Account> acctMap = new Map<Id,Account>();
        
        System.debug('checkCtctLeads msgs='+msgs.size()+' leadMap='+leadMap.size()+' ctctMap='+ctctMap.size());
        // set the last sent date on the contacts and leads if we match to them
        Map<Id,Contact> updateCtctMap = new Map<Id,Contact>();
        Map<Id,Lead> updateLeadMap = new Map<Id,Lead>();
        Map<Id,Account> updateAcctMap = new Map<Id,Account>();
        Set<Id> acctIdSet = new Set<Id>();
        
        // if matched to a contact, query for the account id
        Map<Id, EmailMessage[]> byContactMap = new Map<Id, EmailMessage[]>();
        // because we need to reference the original email message at the account
        Map<Id,EmailMessage> msgMap = new Map<Id,EmailMessage>();
        
        for (EmailMessage msg : msgs) {
            if (msg.Contact__c != null) {
                Contact ctct = ctctMap.get(msg.Contact__c);
                // make sure the account info is set
                if (ctct != null && ctct.AccountId != null) {
                    Account acct = (acctMap.containsKey(ctct.AccountId) ? acctMap.get(ctct.AccountId) : ctct.Account);
                    // store the account in a map for reference later
                    acctMap.put(acct.Id, acct);
                    if (msg.Account__c != ctct.AccountId) {
                        msg.Account__c = ctct.AccountId;
                        updateMsgMap.put(msg.Id,msg);
                    }
                    checkUpdateCtct(ctct, acct, msg,updateCtctMap, updateAcctMap, updateMsgMap);
                }
            } else if (msg.Lead__c != null) {
                Lead ld = leadMap.get(msg.Lead__c);
                if (ld != null) {
                    checkUpdateLead(ld, msg, updateLeadMap, updateMsgMap);
                }
            }
        } // for (EmailMessage msg
        // save the email messages so we can reselect them to get the number of open counts
        saveData(updateMsgMap.values(), new Lead[]{}, new Contact[]{}, new Account[]{});
        
        checkLeadOpens(leadMap,updateLeadMap);
        checkCtctOpens(ctctMap, updateCtctMap);
        // save any changed contact and lead data
        saveData(new EmailMessage[]{}, updateLeadMap.values(), updateCtctMap.values(), new Account[]{});
        // check the accounts after the contacts were saved
        checkAcctOpens(acctMap, updateAcctMap);
        // save any changed account info
        saveData(new EmailMessage[]{}, new Lead[]{}, new Contact[]{}, updateAcctMap.values());
        
    } // checkCtctLeads
    
    public static void checkLeadOpens(Map<Id,Lead> leadMap, Map<Id,Lead> updateLeadMap) {
        System.debug('checkLeadOpens leadMap='+leadMap.size());
        if (!leadMap.isEmpty()) {
            List<AggregateResult> nbrOpenResults = new List<AggregateResult>( 
                [select SUM(NumberOfOpens__c) nbrOpens, Lead__c recId
                 from EmailMessage
                 where Lead__c in :leadMap.keySet() and NumberOfOpens__c>0
                 group by Lead__c ]);
            System.debug('checkLeadOpens nbrOpenResults='+nbrOpenResults.size());
            for (AggregateResult result : nbrOpenResults) {
                Id recId = (Id)result.get('recId');
                Integer nbrOpens = Integer.valueOf(result.get('nbrOpens'));
                Lead ld = leadMap.get(recId);
                System.debug('checkLeadOpens recId='+recId+' nbrOpens='+nbrOpens+' ld.NumberOfOpens__c='+(ld != null ? ld.NumberOfOpens__c : -1));
                if (ld != null && ld.NumberOfOpens__c != nbrOpens) {
                    ld.NumberOfOpens__c = nbrOpens;
                    updateLeadMap.put(ld.Id, ld);
                }
            }
        } // if (!leadIds.isEmpty
    } // checkLeadOpens
    
    public static void checkCtctOpens(Map<Id,Contact> ctctMap, Map<Id,Contact> updateCtctMap) {
        System.debug('checkCtctOpens ctctMap='+ctctMap.size());
        if (!ctctMap.isEmpty()) {
            Integer totalOpens = 0;
            List<AggregateResult> nbrOpenResults = new List<AggregateResult>( 
                [select SUM(NumberOfOpens__c) nbrOpens, Contact__c recId
                 from EmailMessage
                 where Contact__c in :ctctMap.keySet() and NumberOfOpens__c > 0
                 group by Contact__c ]);
            System.debug('checkCtctOpens nbrOpenResults='+nbrOpenResults.size());
            for (AggregateResult result : nbrOpenResults) {
                Id recId = (Id)result.get('recId');
                Integer nbrOpens = Integer.valueOf(result.get('nbrOpens'));
                Contact ctct = ctctMap.get(recId);
                System.debug('checkCtctOpens recId='+recId+' nbrOpens='+nbrOpens+' ctct.NumberOfOpens__c='+(ctct != null ? ctct.NumberOfOpens__c : -1));
                if (ctct != null && ctct.NumberOfOpens__c != nbrOpens) {
                    ctct.NumberOfOpens__c = nbrOpens;
                    updateCtctMap.put(ctct.Id, ctct);
                }
            }
        } // if (!leadIds.isEmpty
    } // checkLeadOpens
    
    public static void checkAcctOpens(Map<Id,Account> acctMap, Map<Id,Account> updateAcctMap) {
        System.debug('checkAcctOpens acctMap='+acctMap.size());
        if (!acctMap.isEmpty()) {
            List<AggregateResult> nbrOpenResults = new List<AggregateResult>( 
                [select SUM(NumberOfOpens__c) nbrOpens, AccountId recId
                 from Contact
                 where AccountId in :acctMap.keySet() and NumberOfOpens__c > 0
                 group by AccountId ]);

            //List<AggregateResult> nbrOpenResults = new List<AggregateResult>( 
            //    [select SUM(NumberOfOpens__c) nbrOpens, Account__c recId
            //     from EmailMessage
            //     where Account__c in :acctMap.keySet() and NumberOfOpens__c > 0
            //     group by Account__c ]);
            System.debug('checkAcctOpens nbrOpenResults='+nbrOpenResults.size());
            for (AggregateResult result : nbrOpenResults) {
                Id recId = (Id)result.get('recId');
                Integer nbrOpens = Integer.valueOf(result.get('nbrOpens'));
                Account acct = acctMap.get(recId);
                System.debug('checkAcctOpens recId='+recId+' nbrOpens='+nbrOpens+' acct.NumberOfOpens__c='+(acct != null ? acct.NumberOfOpens__c : -1));
                if (acct != null && acct.NumberOfOpens__c != nbrOpens) {
                    acct.NumberOfOpens__c = nbrOpens;
                    updateAcctMap.put(acct.Id, acct);
                }
            }
        } // if (!leadIds.isEmpty
    } // checkLeadOpens
    
    public static void checkUpdateLead(Lead ld, EmailMessage msg, Map<Id,Lead> updateLeadMap, Map<Id,EmailMessage> updateMsgMap) {
        if ((ld.EmailLastSent__c == null || ld.EmailLastSent__c < msg.CreatedDate)
            || (msg.LastOpenedDate != null && (ld.EmailLastOpened__c == null || ld.EmailLastOpened__c < msg.LastOpenedDate))) {
                ld.EmailLastSent__c = ((ld.EmailLastSent__c == null || ld.EmailLastSent__c < msg.CreatedDate) ? msg.CreatedDate : ld.EmailLastSent__c);
                ld.EmailLastOpened__c = ((msg.LastOpenedDate != null && (ld.EmailLastOpened__c == null || ld.EmailLastOpened__c < msg.LastOpenedDate)) ? msg.LastOpenedDate : ld.EmailLastOpened__c);
                updateLeadMap.put(ld.Id, ld);
                System.debug('checkUpdateLead ld='+ld);
            }
        checkEmailStatus(msg, ld.EmailStatuses, updateMsgMap);
    } // checkUpdateLead
    
    public static void checkEmailStatus(EmailMessage msg, EmailStatus[] emailStatuses, Map<Id,EmailMessage> updateMsgMap) {
        System.debug('checkEmailStatus msg.ActivityId='+msg.ActivityId+' emailStatuses='+(emailStatuses != null ? emailStatuses.size() : -1));
        if (msg.ActivityId != null && emailStatuses != null) {
            for (EmailStatus es : emailStatuses) {
                if (es.TaskId == msg.ActivityId) {
                    System.debug('checkEmailStatus msg.NumberOfOpens__c='+msg.NumberOfOpens__c+' es.TimesOpened='+es.TimesOpened);
                    if (msg.NumberOfOpens__c != es.TimesOpened) {
                        msg.NumberOfOpens__c = es.TimesOpened;
                        updateMsgMap.put(msg.Id, msg);
                    }
                    break;
                }
            } // for (EmailStatus es : ld.EmailStatuses
            
        } // if (msg.ActivityId != null && emailStatuses != null
    } // checkEmailStatus
    
    public static void checkUpdateCtct(Contact ctct, Account acct, EmailMessage msg, Map<Id,Contact> updateCtctMap, Map<Id,Account> updateAcctMap, Map<Id,EmailMessage> updateMsgMap) {
        if ((ctct.EmailLastSent__c == null || ctct.EmailLastSent__c < msg.CreatedDate)
            || (msg.LastOpenedDate != null && (ctct.EmailLastOpened__c == null || ctct.EmailLastOpened__c < msg.LastOpenedDate))) {
                ctct.EmailLastSent__c = ((ctct.EmailLastSent__c == null || ctct.EmailLastSent__c < msg.CreatedDate) ? msg.CreatedDate : ctct.EmailLastSent__c);
                ctct.EmailLastOpened__c = ((msg.LastOpenedDate != null && (ctct.EmailLastOpened__c == null || ctct.EmailLastOpened__c < msg.LastOpenedDate)) ? msg.LastOpenedDate : ctct.EmailLastOpened__c);
                updateCtctMap.put(ctct.Id, ctct);
                System.debug('checkUpdateCtct ctct='+ctct);
            }
        checkEmailStatus(msg, ctct.EmailStatuses, updateMsgMap);
        if (acct != null) {
            checkUpdateAcct(acct, msg, updateAcctMap);
        }
    } // checkUpdateCtct
    
    public static void checkUpdateAcct(Account acct, EmailMessage msg, Map<Id,Account> updateAcctMap) {
        if ((acct.EmailLastSent__c == null || acct.EmailLastSent__c < msg.CreatedDate)
            || (msg.LastOpenedDate != null && (acct.EmailLastOpened__c == null || acct.EmailLastOpened__c < msg.LastOpenedDate))) {
                acct.EmailLastSent__c = ((acct.EmailLastSent__c == null || acct.EmailLastSent__c < msg.CreatedDate) ? msg.CreatedDate : acct.EmailLastSent__c);
                acct.EmailLastOpened__c = ((msg.LastOpenedDate != null && (acct.EmailLastOpened__c == null || acct.EmailLastOpened__c < msg.LastOpenedDate)) ? msg.LastOpenedDate : acct.EmailLastOpened__c);
                updateAcctMap.put(acct.Id, acct);
                System.debug('checkUpdateAcct acct='+acct+'  msg.CreatedDate='+msg.CreatedDate);
            }
    } // checkUpdateAcct
    
    public static void saveData(EmailMessage[] updateMsgs,Lead[] updateLeads,Contact[] updateCtcts,Account[] accts) {
        SKIP_TRIGGER=true;
        ZipCheckOwner.SKIP_TRIGGERS=true;
        TriggerMethods.SKIP_TRIGGERS=true;
        ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
        ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
        DmlHelper.performDML2(updateMsgs, DmlHelper.DML_UPDATE, 'EmailMessageMethods', 'saveData', 'Update Email Messages', false);
        DmlHelper.performDML2(updateLeads, DmlHelper.DML_UPDATE, 'EmailMessageMethods', 'saveData', 'Update Lead Last Email Sent', false);
        DmlHelper.performDML2(updateCtcts, DmlHelper.DML_UPDATE, 'EmailMessageMethods', 'saveData', 'Update Contact Last Email Sent', false);
        DmlHelper.performDML2(accts, DmlHelper.DML_UPDATE, 'EmailMessageMethods', 'saveData', 'Update Account Last Email Sent', false);
        TriggerMethods.SKIP_TRIGGERS=false;
        ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
        ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
        TriggerMethods.SKIP_TRIGGERS=false;
        SKIP_TRIGGER=false;
        ErrorLog.checkSave();
    } // saveData
    
    
} // public class