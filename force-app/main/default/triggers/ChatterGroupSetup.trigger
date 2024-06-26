/* Trigger actions for the Chatter_Group__c object
   
  History
  -------
  04/06/2012 Dan Carmen   Created
  07/17/2015 Dan Carmen   Added ability to directly execute a setup record.
  
 */
trigger ChatterGroupSetup on Chatter_Group_Setup__c (before insert, after insert, after update) {

   if (ChatterMethods.TRIGGER_EXECUTING) {
      return;
   }
   
   ChatterMethods.TRIGGER_EXECUTING = true;
   
   // check fields on insert of the object
   Chatter_Group_Setup__c[] checkInsertGrps = new Chatter_Group_Setup__c[]{};
   
   // check that the orgs and children indicated in the fields are attached to this Chatter Group Setup object
   Id[] checkOrgsChildrenIds = new Id[]{};
   // run the setup object
   Id[] executeSetupIds = new Id[]{};
   
   for (Chatter_Group_Setup__c grp : Trigger.New) {
      if (Trigger.isBefore && Trigger.isInsert) {
         checkInsertGrps.add(grp);
      } else if (Trigger.isAfter && (grp.Child_Groups__c != null || grp.Org_Units__c != null)) {
         // always check on insert or update of record
         checkOrgsChildrenIds.add(grp.Id);
      }
      if (Trigger.isAfter && grp.ExecuteSetup__c) {
         executeSetupIds.add(grp.Id);
      }
   } // for (Chatter_Group__c
   
   if (!checkInsertGrps.isEmpty()) {
      ChatterMethods.checkChatterGroup(checkInsertGrps);
   }
   
   if (!checkOrgsChildrenIds.isEmpty()) {
      ChatterMethods.checkForLinks(checkOrgsChildrenIds);
   }
   
   if (!executeSetupIds.isEmpty()) {
      ChatterMethods.processOneRecord(executeSetupIds[0]);
   }
   
   ChatterMethods.TRIGGER_EXECUTING = false;

} // trigger ChatterGroup