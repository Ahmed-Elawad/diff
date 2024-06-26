/* Schedulable job to maintain the Org_Unit__c hierarchy.
   
  History
  -------
  03/04/2013 Dan Carmen   Created
  02/27/2015 Dan Carmen   Rewrite to be a batch process
  09/12/2018 Cindy Freeman	changed to use Files instead of Attachments
  04/04/2022 Dan Carmen     Increment API

 */
global with sharing class OrgUnitJob implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

   global static Integer BATCH_SIZE=1;

   global JobHelper jh = new JobHelper('OrgUnitJob');
   global OrgUnitMethods orgUnitM = new OrgUnitMethods();
   
   global Integer numberSalesOrgs = 0;
   
   global String errorMsg = '';

   /** Default constructor. */
   global OrgUnitJob() {
   } // OrgUnitJob
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      return Database.getQueryLocator([SELECT Id
                                             ,Name
                                         FROM SalesOrg__c 
                                        WHERE HasOrgStructure__c = true]);
   } // start

   global void execute(SchedulableContext ctx) {
      OrgUnitJob ouj = new OrgUnitJob();
      database.executeBatch(ouj, BATCH_SIZE);
   } // execute

   /** Execute a batch.
    */
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<SalesOrg__c> salesOrgs = (List<SalesOrg__c>)scope;
      numberSalesOrgs += salesOrgs.size();
      for (SalesOrg__c salesOrg : salesOrgs) {
         try {
            orgUnitM.checkOrgStructure(salesOrg.Name);
         } catch (Exception ex) {
            errorMsg = ex.getMessage()+'; '+ex.getStackTraceString();
         }
      } // for (SalesOrg__c
   } // execute


   global void finish(Database.BatchableContext bc){
      String message = '\nTotal Organization Structures Processed: '+orgUnitM.nbrStrcsProcessed+' '; 
      message += '\nExisting Org Unit objects found: '+orgUnitM.nbrExistingOrgUnits+' '; 
      message += '\nNumber of sales orgs: '+numberSalesOrgs+' ';
      message += '\nTotal Org Units updated: '+orgUnitM.nbrOrgUnitsUpdated+' '; 
      message += '\nTotal Org Units created: '+orgUnitM.nbrOrgUnitsCreated+' '; 
      message += '\nTotal Org Units deleted: '+orgUnitM.nbrOrgUnitsDeleted+' '; 


      message += '\n\nTotal Roles matched to Org Units: '+orgUnitM.nbrRolesMatched+' ';
      message += '\nTotal Org Units not matched to a Role: '+orgUnitM.nbrRolesNotMatched+' '; 
      //message += '\nNumber of roles found: '+OrgUnitMethods.userRoleMap.size()+' '; 

      message += '\n\nTotal User Links Created: '+orgUnitM.nbrUserLinksCreated+' '; 
      message += '\nTotal User Links Deleted: '+orgUnitM.nbrUserLinksDeleted+' '; 
      message += '\nTotal User Links matched to existing (not changed): '+orgUnitM.nbrUserLinksLeftAlone+' '; 

      message += '\n'+orgUnitM.logMsg;
      message += '\n'+errorMsg;

      // check for attachment
      String logFile = orgUnitM.getLogFile();
      message += checkLogFile(logFile);
      jh.completeJob(bc, 'Update Org Unit Structure', message);
      
   } // finish
    
   public String checkLogFile(String logFile) {
      String retMsg = '';
      if (String.isNotBlank(logFile)) {
         Blob csvBlob = Blob.valueOf(logFile);
         String rightNow = DateTime.now().format('yyyyMMddHHmmss');
         String fileName= 'OrgUnitJob.UnmatchedRoles.'+rightNow+'.csv';
         FileWrapper fw = new FileWrapper(null, fileName, fileName, null, csvBlob);
        
         jh.addFilesToJob(new FileWrapper[]{fw}); 
         retMsg = '\n See Attachment for additional Information';
      } // if (String.isNotBlank
      return retMsg;
   } // checkLogFile

} // class OrgUnitJob