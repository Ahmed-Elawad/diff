/* Batch process to handle the chatter group setups. 
   The test methods for this are in the ChatterMethodsTest class.
   
  History
  -------
  04/10/2012 Dan Carmen   Created
  06/28/2012 Dan Carmen   Modified to use JobHelper class
  07/31/2012 Dan Carmen   Logic to select based only on profiles.
  10/29/2018 Dan Carmen   Increment API to version 44
  
 */
global with sharing class ChatterBatch implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

   global JobHelper jh = new JobHelper('ChatterBatch');

   global ChatterBatch() {
   } // ChatterBatch
   
   /** The total number of Chatter Groups found. */
   global Integer numberGrpSetups = 0;

   global ChatterMethods chatMethods = new ChatterMethods();
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.saveJob();
      return Database.getQueryLocator([SELECT Id, Name
                                             ,ChatterGroupId__c
                                             ,Do_Not_Include_Child_Profiles__c
                                             ,ExecuteSetup__c
                                             ,IsActive__c
                                             ,Manager_Profiles__c
                                             ,Owner_Profile__c
                                             ,Owner_Role__c
                                             ,Owner__c
                                             ,Owner__r.Id
                                             ,Owner__r.Name
                                             ,Owner__r.Profile.Name
                                             ,Owner__r.UserRole.Name
                                             ,Selected_Profiles__c
                                             ,Select_From_All_Profiles__c
                                             ,Status__c
                                             ,Type__c
                                             ,Use_Owner__c
                                         FROM Chatter_Group_Setup__c 
                                        WHERE IsActive__c=true]);
   } // start

   global static Integer BATCH_SIZE=2;
   
   /** In order to schedule a batch run
    */
   global void execute(SchedulableContext sc) {
      ChatterBatch cb = new ChatterBatch();
      database.executeBatch(cb, BATCH_SIZE);
   } // execute

   /** Execute a batch.
    */
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<Chatter_Group_Setup__c> setups = (List<Chatter_Group_Setup__c>)scope;
      numberGrpSetups += setups.size();
      
      // the group records to update
      Chatter_Group_Setup__c[] updateGrps = new Chatter_Group_Setup__c[]{};
      
      for (Chatter_Group_Setup__c cgs : setups) {
        if (chatMethods.checkForGroupMembers(cgs)) {
           updateGrps.add(cgs);
        }
      } // for (Chatter_Group_Setup__c
      
      if (!updateGrps.isEmpty()) {
         update updateGrps;
      }
      
   } // execute
   
   global void finish(Database.BatchableContext bc){
      String message = '\nTotal Chatter Groups Processed: '+numberGrpSetups+' '; 
      message += '\nTotal Users added to groups: '+chatMethods.nbrAdded+' '; 
      message += '\nTotal Users removed from groups: '+chatMethods.nbrRemoved+' ';
      message += '\nTotal Users changed from Admin to Standard Roles: '+chatMethods.nbrAdminToStand; 
      message += '\nTotal Users changed from Standard to Admin Roles: '+chatMethods.nbrStandToAdmin; 
      
      message += '\n\n'+chatMethods.emailErrors;
      message += '\n\n'+chatMethods.emailMessages;

      jh.completeJob(bc, 'Chatter Group update', message);
   } // finish
   

} // class ChatterBatch