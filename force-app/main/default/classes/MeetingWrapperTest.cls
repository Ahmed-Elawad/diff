/* Test Methods for the MeetingWrapper class
   
  History
  -------
  02/09/2012 Dan Carmen       Created.
  09/26/2017 Dan Carmen       Added additional functionality
  01/04/2022 Dan Carmen       Fix tests
  
 */
@isTest
private class MeetingWrapperTest {

   static testMethod void testNumberMinutes() {
   	  MeetingWrapper mw = new MeetingWrapper();
   	  System.assertEquals(0,mw.getNumberMinutes(null));
   	  System.assertEquals(0,mw.getNumberMinutes('Bad Value'));
   	  System.assertEquals(30,mw.getNumberMinutes('30 Minutes'));
   	  System.assertEquals(60,mw.getNumberMinutes('1 Hour'));
   	  System.assertEquals(90,mw.getNumberMinutes('1 1/2 Hours'));
   	  System.assertEquals(120,mw.getNumberMinutes('2 Hours'));
   	  System.assertEquals(150,mw.getNumberMinutes('2 1/2 Hours'));
   	  System.assertEquals(180,mw.getNumberMinutes('3 Hours'));
   	  System.assertEquals(210,mw.getNumberMinutes('3 1/2 Hours'));
   	  System.assertEquals(240,mw.getNumberMinutes('4 Hours'));
   	 
      System.assertEquals('30 Minutes',mw.getMinutesString(null));   	 

      System.assertEquals('30 Minutes',mw.getMinutesString(15));   	
      System.assertEquals('30 Minutes',mw.getMinutesString(30));   	
      System.assertEquals('1 Hour',mw.getMinutesString(45));   	
      System.assertEquals('1 Hour',mw.getMinutesString(60));   	
      System.assertEquals('1 1/2 Hours',mw.getMinutesString(75));   	
      System.assertEquals('1 1/2 Hours',mw.getMinutesString(90));   	
      System.assertEquals('2 Hours',mw.getMinutesString(105));   	
      System.assertEquals('2 Hours',mw.getMinutesString(120));   	
      System.assertEquals('2 1/2 Hours',mw.getMinutesString(135));   	
      System.assertEquals('2 1/2 Hours',mw.getMinutesString(150));   	
      System.assertEquals('3 Hours',mw.getMinutesString(165));   	
      System.assertEquals('3 Hours',mw.getMinutesString(180));   	
      System.assertEquals('3 1/2 Hours',mw.getMinutesString(195));   	
      System.assertEquals('3 1/2 Hours',mw.getMinutesString(210));   	
      System.assertEquals('4 Hours',mw.getMinutesString(225));   	
      System.assertEquals('4 Hours',mw.getMinutesString(240));   	
      System.assertEquals('4 Hours',mw.getMinutesString(999));   	

   } // testNumberMinutes
   
   static testMethod void testWrapper() {
   	  Event evnt = new Event();
   	  evnt.ActivityDateTime = DateTime.newInstance(1977, 07, 01, 06, 06, 06);
   	  evnt.ActivityDate = evnt.ActivityDateTime.date();
   	  evnt.DurationInMinutes = 60;
   	  MeetingWrapper mw = new MeetingWrapper();
   	  mw.evnt = evnt;
      //DateTime checkTime = DateTime.newInstance(1977, 07, 01, 07, 30, 00);
      //System.assertEquals(checkTime.format(), mw.getFormattedEndDateTime());
   	  System.assertEquals('7/1/1977 7:30 AM',mw.getFormattedEndDateTime());
   	  System.assertEquals('1 Hour',mw.meeting.Meeting_Duration__c);
   	  System.assertEquals('06:30 AM',mw.meeting.Meeting_Time__c);
   	  
   	  mw.meeting.Meeting_Time__c = '01:00 PM';
   	  mw.meeting.Meeting_Duration__c = '1 1/2 Hours';
   	  mw.evnt.ActivityDate = Date.newInstance(1977,7,7);
   	  mw.setEventFields();

   	  System.assertEquals('7/7/1977 2:30 PM',mw.getFormattedEndDateTime());
   	  System.assertEquals(mw.evnt.ActivityDateTime,DateTime.newInstance(1977,7,7,13,0,0));
   	  System.assertEquals(mw.evnt.DurationInMinutes,90);
   	  
   	  evnt = new Event();
   	  evnt.ActivityDateTime = DateTime.newInstance(1977, 07, 07, 22, 06, 06);
   	  evnt.ActivityDate = evnt.ActivityDateTime.date();
   	  evnt.DurationInMinutes = 300;
   	  
   	  mw.evnt = evnt;
   	  System.assertEquals('7/8/1977 1:00 AM',mw.getFormattedEndDateTime());
   	  // 4 hours is the maximum picklist length
   	  System.assertEquals('4 Hours',mw.meeting.Meeting_Duration__c);
   	  // 9 PM is the latest in the picklist
   	  System.assertEquals('09:00 PM',mw.meeting.Meeting_Time__c);
   	  
   } // testWrapper
   
} // class MeetingWrapperTest