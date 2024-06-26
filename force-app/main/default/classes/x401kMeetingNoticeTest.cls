/**
 * Testmethods for the x401kMeetingNotice_FLurz controller.
 *
 * History
 * -------
 * 05/02/2011 Frank Lurz        Created from x401kMeetingNotice_FLurz.
   10/26/2018 Dan Carmen        Increment API version to 44
   
 */
@isTest
private class x401kMeetingNoticeTest {

   private static User getHRSSalesRep() {
      User u = [Select Id, Name, Sales_Org__c from User where Profile.Name=:Utilities.PROF_HRS_401K  and UserRole.Name like '%Sales Rep%' and IsActive=true and Sales_Org__c='HRS' limit 1];
      return u;
   } // getSalesRep
   
   static testMethod void testCorrectRun()  {
      System.Debug('Debugging...');
      System.Debug('Unit Test1:');
      User u = getHRSSalesRep();
      System.runAs(u) {
         Account a = new Account(Name='Test Account');
         insert a;
         Contact c = new Contact(FirstName='Joe', LastName='Contact', Email='jcontact@test.com', AccountId=a.Id);
         insert c;
         Opportunity o = new Opportunity(Name='Test Opportunity',AccountId=a.Id, x401_k__c=true, CloseDate=Date.today().addDays(14),StageName='Pending');
         insert o;
         Date testDate = Date.today().addDays(7);
         Time testTime = Time.newInstance(9, 0, 0, 0);
         DateTime dt = DateTime.newInstance(testDate,testTime);
         String testDateStr = ' '+dt.format('EEEE')+', '+
              dt.format('MM/dd')+' at '+
              dt.format('h:mm aa');
         
         Event e = new Event(Type='Presentation Initial', ActivityDateTime=dt, ActivityDate=dt.date(), WhatId=o.Id, WhoId=c.Id, DurationInMinutes=60, Onsite_or_Virtual__c='Virtual');
         insert e;
         x401kMeetingNotice xmn = new x401kMeetingNotice();
         xmn.contactId = c.Id;
         System.assertEquals(testDateStr,xmn.getMeetingDateString());
         System.assertEquals(c.Id,xmn.ctct.Id);
         System.assertEquals(e.Id,xmn.evnt.Id);
         System.assertEquals(u.Id,xmn.curUser.Id);
      } // System.runAs
   } // testCorrectRun


   
  static testMethod void testDateDifference()  {
      System.Debug('Debugging...');
      System.Debug('Unit Test2:');
      User u = getHRSSalesRep();
      System.runAs(u) {
         Account a = new Account(Name='Test Account2');
         insert a;
         Contact c = new Contact(FirstName='Jane', LastName='Contacto', Email='jcontacto@test.com', AccountId=a.Id);
         insert c;
         
         Opportunity o = new Opportunity(Name='Test Opportunity',AccountId=a.Id, x401_k__c=true, CloseDate=Date.today().addDays(14),StageName='Pending');
         insert o;
         Date testDate = Date.today().addDays(14);
         Time testTime = Time.newInstance(9, 0, 0, 0);
         DateTime dt = DateTime.newInstance(testDate,testTime);
         String testDateStr = ' '+dt.format('EEEE')+', '+
              dt.format('MM/dd')+' at '+
              dt.format('h:mm aa');
         
         Event e = new Event(Type='Presentation Follow-Up(Phone)', ActivityDateTime=dt, ActivityDate=dt.date(), WhatId=o.Id, WhoId=c.Id, DurationInMinutes=60, Onsite_or_Virtual__c='Virtual');
         insert e;
         x401kMeetingNotice xmn = new x401kMeetingNotice();
         xmn.contactId = c.Id;
         System.assertEquals(testDateStr,xmn.getMeetingDateString());
         System.assertEquals(c.Id,xmn.ctct.Id);
         System.assertEquals(e.Id,xmn.evnt.Id);
         System.assertEquals(u.Id,xmn.curUser.Id);
      } // System.runAs
   } // testDateDifference


   



} // x401kMeetingNoticeTest