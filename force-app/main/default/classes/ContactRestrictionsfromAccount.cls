/* 
   update related contacts with Do Not Call or Email Opt Out for each passed in account
   
  History
  -------
  02/16/2012 Carrie Marciano    Created
  10/02/2014 Dan Carmen         Changed update statement to not fail for the entire transaction.
  09/16/2015 Cindy Freeman      added method to pull DNC and EOO down from account onto contact recently merged onto account
  10/26/2018 Dan Carmen        Setting API version to 44
  
 */
public without sharing class ContactRestrictionsfromAccount {


   public static void getContacts(Set<Id> DNCAccount, Set<Id> EmailAccount) {
      system.debug('***************BEGINNING OF CLASS******************');

      Set<Id> acctIdSet = new Set<id>();
      acctIdSet.addAll(DNCAccount);
      acctIdSet.addAll(EmailAccount);
	

      Contact[] contacts = [Select Id 
                               , AccountId  
                               , DoNotCall
                               , HasOptedOutOfEmail                               
                          from Contact
                          where AccountId in :acctIdSet limit :Integer.valueOf(label.dncContactLimit) 
                           ];
      system.debug('***************AFTER**CONTACT**QUERY******************');
      Contact[] updateContacts = new Contact[]{};
      
      system.debug('***************BEFORE**CONTACT**FOR**LOOP******************');
      
      // send email message to COE if number of contacts exceeds dncContactLimit
      
      if(contacts.size() == Integer.valueOf(label.dncContactLimit)){
      	 Messaging.SingleEmailMessage emailCOE = new Messaging.SingleEmailMessage();
      	 
      	 list<string> cOEEmails = Label.DNCWarningEmails.split(',');
//      	 list<string> subject = new list<string> {'DNC Limit Exceeded'};
      	 
      	 emailCOE.setToAddresses(cOEEmails);
      	 emailCOE.setSubject('DNC Limit Exceeded'); 
      	 
      	 string body = 'The number of contacts has exceeded the limit of '+  label.dncContactLimit + ' for the following client(s): '; 
      	 
      	 
      	 for(id acctID :acctIdSet ) {
      	 	body+= '\r\n' + acctID;
      	 }//for 
      	 
      	 emailCOE.setPlainTextBody(body); 
 //     	 messaging.sendEmail(new messaging.SingleEmailMessage()[emailCOE]); 
 
 		 Messaging.SendEmailResult[] res = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailCOE });
 	
      }//if nbr_recs
      
      
      
      for (Contact contact : contacts){
         if (DNCAccount.contains(contact.AccountId)){
            contact.DoNotCall = true;
            system.debug('***************AFTER**SET**DONOTCALL******************');
         }
         if (EmailAccount.contains(contact.AccountId)){
            contact.HasOptedOutOfEmail = true;  
            system.debug('***************AFTER**SET**HASOPTEDOUTOFEMAIL******************');
         }   
         updateContacts.add(contact);    
      } // for              
                
          
      if (!updateContacts.isEmpty()) {
         system.debug('***************BEFORE**UPDATE CONTACTS******************');
         Database.update(updateContacts,false);
         system.debug('***************AFTER**UPDATE CONTACTS******************');
      }
      
   } // getContacts
   
   /* pass in Account Ids from ContactAfter trigger for contact that had its account Id change
    * push Account DNC and EOO down to contact
    */
    public static void mergedContacts(Set<Id> acctIdSet) {
        List<Contact> ctctUpdateList = new List<Contact>();
        
        List<Account> acctList = [Select Id, Do_Not_Call__c, Email_Opt_Out__c, (Select Id, DoNotCall, HasOptedOutOfEmail from Contacts) 
                                  from Account where Id in :acctIdSet and (Do_Not_Call__c = true or Email_Opt_Out__c = true)];
        
        for (Account acct: acctList)
        {   for (Contact ctct: acct.Contacts)
            {   if (acct.Do_Not_Call__c == true)
                {   ctct.DoNotCall = true;  }
                if (acct.Email_Opt_Out__c == true)
                {   ctct.HasOptedOutOfEmail = true; }
                ctctUpdateList.add(ctct);
             } // for contact
        } // for account
        
        if (!ctctUpdateList.isEmpty())
        {   Database.update(ctctUpdateList,false);  }
        
    } // mergedContacts

   
} // ContactRestrictionsfromAccount