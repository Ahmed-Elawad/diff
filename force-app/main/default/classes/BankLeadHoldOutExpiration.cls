/* 
 * A batch job for checking Lead Hold Out Expiration and clearing the Hold Out if equals or less than today
 *
 * History
 * -------
 * 10/30/2012 Carrie Marciano   Created
 * 11/27/2012 Carrie Marciano	updated to use the helper classes
   11/06/2014 Dan Carmen        Changed LeadSource reference
   01/15/2015 Dan Carmen        Change to only select unconverted leads.
 *
 */
global with sharing class BankLeadHoldOutExpiration implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

/** The total number of leads records found. */
   global Integer numberLeads = 0;
   global DateTime startTime;
 
   global JobHelper jh = new JobHelper('BankLeadHoldOutExpiration');
 
   global BankLeadHoldOutExpiration() {
   	  startTime = DateTime.now();
   } // BankLeadHoldOutExpiration
       
   public static String LEAD_SOURCE = Label.LeadSource_ReferralBank;

   global Database.QueryLocator start(Database.BatchableContext BC){
   
      return Database.getQueryLocator([SELECT id                                             
                                             ,Hold_Out__c
                                             ,Hold_Out_Expiration__c
                                         FROM Lead 
                                        WHERE IsConverted=false
                                          and Hold_Out_Expiration__c < :Date.TODAY()
                                          and LeadSource=:LEAD_SOURCE
                                          and Bank_Lead_ID__c != null]);
   } // start

   /** In order to schedule a batch run
    */
   global void execute(SchedulableContext sc) {
   	  BankLeadHoldOutExpiration blex = new BankLeadHoldOutExpiration();
   	  database.executeBatch(blex, 100);
   } // execute

   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<Lead> leads = (List<Lead>)scope;
      numberLeads += leads.size();
      
      for (Lead lead : leads) {
      	 lead.Hold_Out__c=FALSE;
      	 lead.Hold_Out_Expiration__c=NULL;      	
      } // for (Lead
      update leads;
     
   } // execute

   global void finish(Database.BatchableContext BC){     
      String message = '\nTotal Bank Leads with expired Hold Out: '+numberLeads+' '; 

      jh.completeJob(bc, 'Bank Lead Hold Out Expiration', message);
   } // finish
   

} // class BankLeadHoldOutExpiration