/* 
 * The controller used to setup the email that is sent to the NSRs based on changes that occur in Salesforce.
 *
 * History
 * -------
 * 12/20/2010 Dan Carmen   		Created
 * 10/7/2011  Carrie Marciano	Added isNotSold check and display of Comment to NSS field.
   10/26/2018 Dan Carmen        Commented out all code - not used.
 *
 */
public with sharing class NSREmailStatusController {
	
	/*
   private Opportunity oppty = null;
   
   // Get the Opportunity.
   public Opportunity getOppty() {
      if (oppty == null) {
  	     try {
   	  	    oppty=[Select o.Owner.Name, o.Account.Name,o.Account.AccountNumber 
   	  	         ,o.StageName, o.OwnerId, o.Reason_Not_Sold__c, o.Comment_to_NSS__c, o.Name
   	  	         , o.NSS_Prospect_ID__c, o.Event_Id__c, o.NSR_Description__c
                 ,o.Description, o.CloseDate From Opportunity o where id=:opptyId];
   	     } catch (Exception e) {
   	  	    System.debug('Exception occurred! opptyId='+opptyId+' e='+e);
   	  	    oppty = new Opportunity();
   	     }
   	  } // if (oppty == null
      return oppty;
   } // oppty
   
   private Event evnt = null;
   // Get the Event associated with the Opportunity.
   public Event getEvnt() {
   	  if (evnt == null && getOppty().Event_Id__c != null) {
         evnt=[Select t.OwnerId,t.whatId,t.whoId,t.Type, t.Subject, t.Meeting_Not_Held__c, 
                t.Description, t.ActivityDate, t.IsAllDayEvent, t.Presentation_Completed__c From Event t where Id=:oppty.Event_Id__c];
   	  }
   	  return evnt;
   } // getEvnt

   // Is there an event associated with the opportunity?
   public Boolean hasEvent{get {
   	  return getEvnt() != null;
      } // get
   } // hasEvent
   
   // Is the Stage of the opportunity SoldStarted?
   public Boolean isSoldStarted{
      get {
   	  	 oppty = null;
   	  	 getOppty();
   	  	 return oppty.StageName == 'Sold - Started';
      } // get
   } // isSoldStarted
   
   // Is the Stage of the opportunity Not Sold?
   public Boolean isNotSold{
      get {
   	  	 oppty = null;
   	  	 getOppty();
   	  	 return oppty.StageName == 'Not Sold';
      } // get
   } // isNotSold
   
   // The subject of the message.
   public String subject{
   	  get {
//   	  	 oppty = null;
//   	  	 getOppty();
   	  	 if (oppty.NSR_Description__c != null) {
   	     	if (oppty.NSR_Description__c.startsWith('The meeting date is')) {
   	           return 'You are receiving this email because a new meeting was created for a lead that you created:';
   	     	}
   	  	    return 'You are receiving this email because a meeting associated to a lead that you created has been updated:';
         }
   	  	 return 'You are receiving this email because the Disposition or Close Date on a lead that you created has changed:';
   	  } // get
   } // subject
      
   public Id opptyId{get;set;}
   */

   static testMethod void testNothing() {
      NSREmailStatusController nothing = new NSREmailStatusController();
   }
} // class NSREmailStatusController