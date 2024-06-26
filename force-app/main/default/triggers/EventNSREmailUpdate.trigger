/** 
 * If the meeting on the event changes, update the opportunity so an email is sent.
 *
 * History
 * -------
 * 10/23/2009 Kris Kratky  Created
 * 01/06/2011 Dan Carmen   Modified to move code to a separate class.
   11/03/2011 Dan Carmen   Modified to better capture errors that occur
   10/26/2018 Dan Carmen   Inactivate trigger
   

 */
trigger EventNSREmailUpdate on Event (after insert, after update) {

/*
   // do not fire if user is SFDC Data
   if (UserInfo.getName() != 'SFDC Data') {
      // The new event objects. 
      Map<Id, Event> evnts = new Map<Id, Event>();
      // The old event objects. 
      Map<Id, Event> oldEvnts = new Map<Id, Event>();
   
      for (Event e : Trigger.new) {
   	     // see if the event is attached to an opportunity
   	     String whatId = e.WhatId;
   	     if (whatId != null && whatId.subString(0,3) == '006') {
   	  	    // add the event to the mapping.
   	  	    if (Trigger.isInsert) {
               evnts.put(e.WhatId,e);
   	  	    } else if (Trigger.isUpdate) {
   	  	 	   Event oldEvnt = Trigger.oldMap.get(e.Id);
   	  	 	   if (oldEvnt != null && e.ActivityDate != oldEvnt.ActivityDate) {
   	  	 	   	  evnts.put(e.WhatId,e);
   	  	 	      oldEvnts.put(e.Id, oldEvnt);
   	  	 	   }
   	  	    } // if (Trigger.isUpdate
   	     } // if (whatId != null
      } // for (Event e
   
      if (!evnts.isEmpty()) {
   	     OpptyUpdateId.processEvents(evnts, oldEvnts);
      } // if
   } // if (UserInfo.getName
   */
} // trigger EventNSREmailUpdate