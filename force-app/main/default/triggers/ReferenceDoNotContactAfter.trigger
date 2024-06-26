/*  
  History
  -------
  04/13/2017 Jermaine Stukes    Created.
  10/17/2018 Jacob Hinds        Reworking DNC
  03/15/2019 Sunnish       adding Comments_and_follow_up__c to case ,
  02/24/2022 Pujitha Madamanchi Send it to emailhandler if, submitted via Unsubscribe form
  01/25/2024 Dan Carmen       Moved all code to the ReferenceDNCEmailHelper class

 */
trigger ReferenceDoNotContactAfter on Reference_Do_Not_Contact__c  (after insert, after update) {
   ReferenceDNCEmailHelper.checkAfterActions(Trigger.new, Trigger.oldMap);
} // trigger ReferenceDoNotContactAfter