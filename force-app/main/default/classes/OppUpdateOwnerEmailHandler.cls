/*
01/09/2023  Jermaine Stukes   	Created.
02/07/2023	Jermaine Stukes		Add Debug Statements

*/
global without sharing class  OppUpdateOwnerEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email,Messaging.InboundEnvelope env){
      // Create an InboundEmailResult object for returning the result of the  Apex Email Service
      Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
      String emailBody = email.plainTextBody;
      Boolean updateOppOwnerToInactiveUser = emailBody.contains('Opportunity Ids');
        System.debug('OppUpdateOwnerEmailHandler-handleInboundEmail-Email Body: ='+emailBody);
      if (updateOppOwnerToInactiveUser) {
          Map<Opportunity, Id> oppMap = new Map<Opportunity, Id>();
          String opportunities = emailBody.substringBetween('Opportunity Ids:', 'endOfList');
          List<String> opportunityIds = opportunities.Split(',');
          System.debug('OppUpdateOwnerEmailHandler-handleInboundEmail-Opportunity List:'+opportunityIds);
          List<Opportunity> opptyList = [Select Id, Inactive_User_Id__c, OwnerId from Opportunity where Id in:opportunityIds];
          for(Opportunity opp : opptyList){
              oppMap.put(opp, opp.Inactive_User_Id__c);
          }
          Map<Id, User>  inactiveUserMap = new Map<Id, User>([SELECT Id, Name From User WHERE isActive = false AND Id in : oppMap.values()]);
          User newOwner = new User();
          for(Opportunity opp : oppMap.keySet())
          {
              System.debug('OppUpdateOwnerEmailHandler-handleInboundEmail-New Owner ID: ='+opp.Inactive_User_Id__c);
              newOwner = inactiveUserMap.get(opp.Inactive_User_Id__c);
              opp.Inactive_User_Id__c = null;
              if(newOwner!=null){
                  opp.OwnerId = newOwner.Id;   
              }        
          } 
          update opptyList;
      }
      return result;
   } // handleInboundEmail
}