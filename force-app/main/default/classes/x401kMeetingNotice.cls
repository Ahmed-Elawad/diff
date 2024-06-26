/**
 * 
 *
 * History
 * -------
   10/26/2018 Dan Carmen        Increment API version to 44
   
 */
public with sharing class x401kMeetingNotice {
   private String msgStr = '';
   public Id contactId{get;
     set{
      ctct = null;
      evnt = null;
      
      try {
         ctct =[Select Id, Name, FirstName, LastName, Email, AccountID From Contact where id=:value];
      } catch (Exception e) {
         //System.debug('Exception occurred! contactId='+contactId+' e='+e);
         ctct = new Contact(FirstName='TestFirst', LastName='TestLast', Email='testEmail@testing.com');
      }
      
      if (ctct.Id != null && ctct.AccountID != null) {
         Opportunity oppty = null;
         Opportunity[] opptys = [select Id, AccountID
                                       from Opportunity
                                      where (x401_k__c = true or X401_k_Conversion__c = true or x401k_FSA__c = true or Profit_Sharing__c = true )
                                        and closeDate >= today
                                        and StageName='Pending' 
                                        and AccountID =:ctct.AccountID
                                        order by LastModifiedDate desc
                                    ];
         if (!opptys.isEmpty()) {
            oppty = opptys[0];
         }
         if (oppty != null) {
            Date today = Date.today();
            Event[] events = [select Id, ActivityDateTime, ActivityDate 
                                from Event 
                               where whoId = :value
                                 and Type like 'Presentation%'
                                 and WhatId = :oppty.Id
                                 and ActivityDate >= :today 
                               order by LastModifiedDate desc
                             ];
            if (!events.isEmpty()) {
               evnt = events[0];
            }
         }
      } // if (ctct.Id != null
      if (evnt == null) {
          DateTime dt = System.now().addHours(1);
          Date d = dt.date();
          evnt = new Event(ActivityDateTime = dt, ActivityDate = d);
      }
    }//set
   } // setContactId
   
   public Contact ctct{get; private set;}
   public Event evnt{get; private set;}
   
   public User curUser{get;set;}
   public x401kMeetingNotice() {
      curUser = [Select Id, Name, Phone, Email from User where Id=:UserInfo.getUserId()];
   }

   public String getMeetingDateString() {
      String output = ' ';
      if (evnt != null && (ctct.Id == null || evnt.Id != null)) {
         output += evnt.ActivityDateTime.format('EEEE')+', ';
         output += evnt.ActivityDateTime.format('MM/dd')+' at ';
         output += evnt.ActivityDateTime.format('h:mm aa');
      } else {
         
         output += 'unable to determine meeting date';
         // this is so the preview can be viewed if a contact is not selected.
         if (ctct.Id != null) {
            throw new MeetingException('Cannot send this email - No Pending 401(k) presentation and Meeting can be found');
         }
      }
      return output;
   } // getMeetingDateString
   
   public class MeetingException extends Exception {}
} // class x401kMeetingNotice