/* Test methods for the MeetingController
   
  History
  -------
  02/22/2011 Dan Carmen   Created.
  11/16/2017 Dan Carmen   Increasing the API version
  
 */
@isTest
private class MeetingControllerTest {

   static testMethod void testController() {
      MeetingController mc = new MeetingController();
      // verify the correct number of options
      System.assertEquals(8,mc.durationOptions.size());
      System.assertEquals(48,mc.timeOptions.size());
   	  
      // verify default date settings
      //System.assertEquals('1 Hour',mc.getStartDt().Meeting_Duration__c);
      //System.assertEquals(Date.today(),mc.getStartDt().Start_Date__c);
   	  
      Event evnt = new Event();
      evnt.DurationInMinutes = 90;
      DateTime now = DateTime.now().addHours(1).addDays(3);

      evnt.ActivityDate=now.date();
      // set the time to the next full hour
      evnt.ActivityDateTime=DateTime.newInstance(now.year(),now.month(),now.day(),now.hour(),0,0);
      
      mc.evnt = evnt;
      
      // verify settings
      System.assertEquals('90',mc.durationSelection);
      //System.assertEquals(Date.today().addDays(3),mc.getStartDt().Start_Date__c);

      // change the time
      mc.durationSelection = '120';
      mc.changeDateTime();
      System.assertEquals(120,mc.evnt.DurationInMinutes);      
   } // testController
    
} // class MeetingControllerTest