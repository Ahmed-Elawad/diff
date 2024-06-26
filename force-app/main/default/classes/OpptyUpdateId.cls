/* 
 * Update the Opportunity from the event.
 *
 * History
 * -------
 * 01/05/2011 Dan Carmen   Created
 * 01/13/2011 Dan Carmen   Changed to without sharing.
 * 07/07/2011 Dan Carmen   Modified to only select NSS opportunities
   11/03/2011 Dan Carmen   Modified to better capture errors that occur
   10/26/2018 Dan Carmen   Increment API to version 44 - this code is no longer needed.

 */
public without sharing class OpptyUpdateId {

/*
   public static void processEvents(Map<Id,Event> evnts, Map<Id,Event> oldEvnts) {
   	  // only select NSS opportunities - need to have an NSR Email to send it back to NSS
      List <Opportunity> oppList =[Select Id, Event_Id__c from Opportunity where Id in :evnts.keySet() and NSR_Email__c != null];
      System.debug('Events >>>>>>>>>'+evnts);
      System.debug('oppList>>>>>>>>>>>>'+oppList);
      Opportunity[] updateList = new Opportunity[]{};
      for (Opportunity o : oppList) {
    
         Event evnt = evnts.get(o.Id);
         // make sure the event_id is set
         o.Event_ID__c = evnt.Id;
         Event oldEvnt = oldEvnts.get(evnt.Id);
         Date oldDate = evnt.ActivityDate; 
         if (oldEvnt != null) {
         	oldDate = oldEvnt.ActivityDate;
         }
         if (evnt.ActivityDate != oldDate) {
            o.NSR_Description__c = 'The meeting date was changed from '+oldDate.format()+' to '+evnt.ActivityDate.format()+'.';
         } else {
            o.NSR_Description__c = 'The meeting date is '+evnt.ActivityDate.format()+'.';
         }
         updateList.add(o);
      } // for (Opportunity
      if (!updateList.isEmpty()) {
         List<Database.saveResult> uResults = Database.update(updateList,false);
         // if only 1 event, check the result to log any errors
         if (uResults.size() == 1 && evnts.size() == 1) {
            Database.saveResult result = uResults.get(0);
            if (!result.isSuccess()) {
               String errorStr = '';
               for (Database.Error err : result.getErrors()) {
                  errorStr += err.getMessage();
               }
               Event evnt = evnts.values().get(0);
               evnt.addError(errorStr);
            }
         }
      }
   } // processEvents
   */
} // class OpptyUpdateId