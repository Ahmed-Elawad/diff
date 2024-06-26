/* 
 * Test method for the OpptyUpdateId class.
 *
 * History
 * -------
 * 01/05/2011 Dan Carmen   Created
   07/07/2011 Dan Carmen   Updated to take into account NSR_Email__c field on opportunity.
   10/26/2018 Dan Carmen   Increment API to version 44 - comment out code

 */
@isTest
private class OpptyUpdateIdTest {
   
   static testMethod void testNothing() {
      OpptyUpdateId oui = new OpptyUpdateId();
   }
/*
   static testMethod void testOpptyEvent() {
   	  // run as system admin so workflow doesn't fire that cleans out the fields.
   	  User u = [Select Id, Name from User where Profile.Name='System Administrator' and IsActive=true limit 1];
   	  System.runAs(u) {
         DateTime useDate = DateTime.now().addDays(14);
         // create opportunities
         Opportunity oppty1 = new Opportunity(Name='Test 1', StageName='PENDING', CloseDate=useDate.date(), NSR_Email__c='test@me.com');
         Opportunity oppty2 = new Opportunity(Name='Test 2', StageName='PENDING', CloseDate=useDate.date(), NSR_Email__c='test@me.com');
         Opportunity oppty3 = new Opportunity(Name='Test 3', StageName='PENDING', CloseDate=useDate.date());
         Opportunity[] opptys = new Opportunity[]{oppty1,oppty2,oppty3}; 
         insert opptys;
      
         // create events. Create 1 event not attached to an opportunity
         Event evnt1 = new Event(Type='Test Event 1',ActivityDateTime=useDate, ActivityDate=useDate.date(), DurationInMinutes=60, WhatId=oppty1.Id);
         Event evnt2 = new Event(Type='Test Event 2',ActivityDateTime=useDate, ActivityDate=useDate.date(), DurationInMinutes=60, WhatId=oppty2.Id);
         Event evnt3 = new Event(Type='Test Event 3',ActivityDateTime=useDate, ActivityDate=useDate.date(), DurationInMinutes=60, WhatId=oppty3.Id);
         Event evnt4 = new Event(Type='Test Event 4',ActivityDateTime=useDate, ActivityDate=useDate.date(), DurationInMinutes=60);
         Event[] evnts = new Event[]{evnt1,evnt2,evnt3,evnt4};
         insert evnts;
      
         // verify opportunities were updated
         oppty1 = [Select Id, Event_Id__c, NSR_Description__c from Opportunity where Id=:oppty1.Id];
         // TODO - figure out how to test values since workflow clears out the fields on successful completion.
         //System.assertEquals(evnt1.Id,oppty1.Event_Id__c);
         //System.assertEquals(true,(oppty1.NSR_Description__c != null));
         oppty2 = [Select Id, Event_Id__c, NSR_Description__c from Opportunity where Id=:oppty2.Id];
         //System.assertEquals(evnt2.Id,oppty2.Event_Id__c);
         //System.assertEquals(true,(oppty2.NSR_Description__c != null));
         // this opportunity should not be updated since no NSR_Email__c
         oppty3 = [Select Id, Event_Id__c, NSR_Description__c from Opportunity where Id=:oppty3.Id];
         //System.assertEquals(null,oppty3.Event_Id__c);
         //System.assertEquals(true,(oppty3.NSR_Description__c == null));
      
      
         // clear out the fields of oppty1
         oppty1.Event_Id__c = null;
         oppty1.NSR_Description__c = null;
         update oppty1;
      
         // test the update of the event date
         DateTime newDate = DateTime.now().addDays(16);
         evnt1.ActivityDateTime = newDate;
         evnt1.ActivityDate = newDate.date();
         update evnt1;
      
         // verify data was updated.
         oppty1 = [Select Id, Event_Id__c, NSR_Description__c from Opportunity where Id=:oppty1.Id];
         //System.assertEquals(evnt1.Id,oppty1.Event_Id__c);
         //System.assertEquals(true,(oppty1.NSR_Description__c != null));
   	  } // System.runAs
   } // testOpptyEvent
    */
} // class OpptyUpdateIdTest