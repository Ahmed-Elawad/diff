/*
 *  This class will process the parsed messages received from Marketo ESR web form.  It will search for the account based on branch-client # 
 *  and the contact, creating contact if needed.  Then it will add contact to campaign and create a case for ESR queue to contact.
 *
 * History
 * --------
 * 05/20/2015  Cindy Freeman    created
 * 06/10/2015  Cindy Freeman    modified to Case Assignment rules to set owner instead of setting it in code
   12/29/2022  Dan Carmen       Commented out code. If no repurcussion delete the ESRtracking_settings__c custom setting

 */

public with sharing class WebESREmailHelper {
    
    public WebESREmailHelper() {
       // do nothing
    }
    /* 
    public class ESRemail {
        public String firstname;
        public String lastname;
        public String branchclientid;
        public String acctnbr;
        public String bisid;
        public String email;
        public String phone;
        public String reasonsfordecliningesrservices1;
        public String reasonsfordecliningesrservices2;     
        public String myPlainText;   
        public ID acctId;
        public ID ctctId;
        public ID userId;
        public Boolean isError;
    }
    
    public static ESRtracking_settings__c esrSettings;
    
    public static void processESRemail(List<ESRemail> esrList) {
                
        esrSettings = getESRSettings('ESR settings');
            
        Schema.RecordTypeInfo caseESRrt = RecordTypeHelper.getRecordType(esrSettings.Case_Record_Type__c, 'Case');
        List<Campaign> esrCampaignList = [Select Id, Name, IsActive from Campaign where Name = :esrSettings.Campaign_Name__c and IsActive = TRUE];
        if (esrCampaignList.size() > 1)
        {   logError('multiple ESR Campaigns, stopping process', null);
            Throw new WebESREmailHelperException('multiple ESR campaigns');     
        }       
        Id campaignId = esrCampaignList.get(0).Id;                           
        Contact foundCtCt;
        Account foundAcct;             
                
        List<Case> newCaseList = new List<Case>();
        List<Account> updateAcctList = new List<Account>();
        List<Contact> updateCtctList = new List<Contact>();
        List<CampaignMember> updateCampMmbrList = new List<CampaignMember>();
        Map<Id, CampaignMember> memberMap = getCampaignMemberSet(campaignId);       
        
        for (ESRemail esr: esrList)     
        {   foundAcct = findAcct(esr);
            if (foundAcct == null)
            {   logError('ESR bad branch-client number', esr.myPlainText);  
                forwardEmail(esr.myPlainText, 'bad Bis-id and Branch-Client number');           
                break;
            }           
            foundCtct = findCtct(foundAcct, esr);
            if (foundCtct == null)
            {   logError('ESR contact not found and not created', esr.myPlainText);
                forwardEmail(esr.myPlainText, 'Contact not found and not created');             
                break;
            }

            Case kase = new Case(RecordTypeId = caseESRrt.getRecordTypeId()
                                , ContactId = foundCtct.Id
                                , AccountId = foundAcct.Id
                                , Origin = 'Web'
                                , Priority = 'High'
                                , Status = 'New'
                                , Product__c = 'ESR');/*
                                , ESRService__c = 'Virtual - Opt Out Received'
                                , ESRservice_Declined_Reason_Level1__c = esr.reasonsfordecliningesrservices1
                                , ESRservice_Declined_Reason_Level2__c = esr.reasonsfordecliningesrservices2
                                , Subject = 'Declined ESR - conversation needed'
                                , OwnerId = esrSettings.OwnerID__c
                                , ESRservice_Last_Updated__c = Date.valueOf(System.now()));      */                           
      /*
            newCaseList.add(kase);
            
            foundAcct.ESRservice_Declined_Reason_Level1__c = esr.reasonsfordecliningesrservices1;
            foundAcct.ESRservice_Declined_Reason_Level2__c = esr.reasonsfordecliningesrservices2;
            foundAcct.ESRService__c = 'Virtual - Opt Out Received';
            updateAcctList.add(foundAcct);
            foundCtct.LatestCampaign__c = campaignId;
            updateCtctList.add(foundCtct);     
            if (!memberMap.containsKey(foundCtct.Id))
            {   CampaignMember newMember = new CampaignMember (CampaignId = campaignId, ContactId = foundCtct.Id);
                updateCampMmbrList.add(newMember);              
            }
                                                        
        } // for esrList 
       
        if (!newCaseList.isEmpty())
        {   insert newCaseList; }       
                    
        if (!updateAcctList.isEmpty())
        {   update updateAcctList;  }
            
        if (!updateCtctList.isEmpty())
        {   update updateCtctList;  }
        
        if (!updateCampMmbrList.isEmpty())
        {   try {
                insert updateCampMmbrList;  }
            catch (Exception cmex) {
                forwardEmail(cmex.getMessage(),'Exception adding contact to campaign');
            }
        } // if
    } // processESRemail

    
    // try to find the account using branch-client number
    private static Account findAcct (ESRemail esr)
    {   Account foundAcct;
        if (esr.bisid != null)
        {   List<Account> foundList = new List<Account>();
            foundList = [Select Id, Name, AccountNumber, Bis_ID__c, RecordType.Name from Account where Bis_ID__c= :Integer.valueOf(esr.bisid)];        
            if (foundList.size() >= 1)
            {   foundAcct = foundList.get(0);   }
        } // if bisid != null
        if (foundAcct == null && esr.acctnbr != null)
        {   List<Account> foundList = new List<Account>();
            foundList = [Select Id, Name, AccountNumber, Bis_ID__c, RecordType.Name from Account where AccountNumber = :esr.acctnbr];        
            if (foundList.size() >= 1)
            {   foundAcct = foundList.get(0);   }
        } // if acctnbr != null
        
        return foundAcct;
                   
    } // findRefAcct

    // try to find the contact on foundAcct, create one if no match
    // upsert contact so can set latest campaign on new/existing ctct and add to campaign!!
    private static Contact findCtct (Account foundAcct, ESRemail esr)
    {   Id rcdTypeId;
        if (foundAcct.RecordType.Name.containsIgnoreCase('Core'))
        {   Schema.RecordTypeInfo corert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
            rcdTypeId = corert.getRecordTypeId();
        }
        else
        {   Schema.RecordTypeInfo mmsrt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_CONTACT, ObjectHelper.OBJECT_CONTACT); 
            rcdTypeId = mmsrt.getRecordTypeId();
        }
        Contact tempCtct = new Contact(recordtypeId = rcdTypeId, FirstName = esr.firstName, LastName = esr.lastName, 
                                        AccountId = foundAcct.Id,email = esr.email, phone = esr.phone);
        List<Id> matchedIdList = new List<Id>();  
        if (Test.isRunningTest())
        {   List<Contact> tempctctList = [Select Id from Contact where CreatedDate = TODAY];
            for (Contact ct:tempctctList)
            {   matchedIdList.add(ct.Id);   }
        }
        else
        {   for (CRMfusionDBR101.DB_Api.Matches matchSet : CRMfusionDBR101.DB_Api.findMatches(tempCtct) )
            {   for (Id i : matchSet.matchedIds )
                {   if(i.getSobjectType() == Schema.Contact.SObjectType)
                    {   matchedIdList.add(i);   }
                }               
            } // for
        } // else       
        if ( matchedIdList.isEmpty() )
        {   insert tempCtct;            
            return tempCtct;
        }
        else
        {   List<Contact> matchedCtctList = [Select Id, FirstName, LastName, Email, Phone, Account.Id 
                                                from Contact where Id in :matchedIdList and AccountId = :foundAcct.Id];                                             
            if (matchedCtctList.size() > 0)
            {   return matchedCtctList.get(0);  }               
        } // else
            
        return null;
                           
    } // findCtct

    // get ESR custom setting
    public static ESRtracking_settings__c getESRSettings(String esrName) {
        ESRtracking_settings__c esr = ESRtracking_settings__c.getInstance(esrName);
    
        if (esr != null && !esr.isActive__c) 
        {   logError('ESRSettings not Active', null);
            esr = null;      
        }
        if (esr != null)
        {   UserHelper uh = new UserHelper();        
            User caseUser = (uh.getUserById(esr.OwnerID__c) != null ? uh.getUserById(esr.OwnerID__c) : null);
            Group caseQueue = (uh.getQueueById(esr.OwnerID__c) != null ? uh.getQueueById(esr.OwnerID__c) : null);
            if (caseUser == null && caseQueue == null)
            {   logError('ESRSettings missing valid Case Owner', null); 
                esr = null;
            }
        } // esr!=null
        
        return esr;
        
    } // getESRSetting
    
    // save error and email in Error Log object
    public static void logError(String errMsg, String emailBody) {      
        ErrorLog__c err = new ErrorLog__c();
        err.ClassName__c = 'WebESREmailHandler';
        err.Description__c = errMsg;
        insert err;
        
        if (emailBody != null)
        {   Attachment attach = new Attachment();
            attach.Body = Blob.valueOf(emailBody);  
            attach.Name = 'WebESREmailHandler';             
            attach.ParentID = err.id;
            insert attach;
        }
    } // logError
    
    // get all Campaign members so don't try to add someone again
    private static Map<Id, CampaignMember> getCampaignMemberSet(Id campId) {
        List<CampaignMember> memberList = [Select Id, ContactId from CampaignMember where CampaignId = :campId];
        Map<Id, CampaignMember> memberMap = new Map<Id, CampaignMember>();
        for (CampaignMember cm: memberList)
        {   memberMap.put(cm.contactId, cm);    }
                 
        return memberMap;
    }
    
    // method to send error email to person listed in custom setting
    public static void forwardEmail (String p_email, String p_subj) {
               
         if (esrSettings != null && esrSettings.ErrorEmailAddresses__c != null)
         {      Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                //mail.setToAddresses (new String[]{esrSettings.ErrorEmailAddresses__c});
                String[] addressList = esrSettings.ErrorEmailAddresses__c.split(',');
                mail.setToAddresses(addressList);
                mail.setSubject ('ESR email - '+p_subj);                
                mail.setPlainTextBody(p_email);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
         }
        
    } // forwardEmail
   
    // this exception is used to throw missing attachment messages
    public class WebESREmailHelperException extends Exception {}   
    */ 
} // WebESREmailHelper