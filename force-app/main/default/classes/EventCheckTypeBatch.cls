/*
 * A one time use job to update the number of events on Opportunities with a Run-Effective date of this fiscal year
 *
 * History
 * -------
 * 03/30/2018 Cindy Freeman     created
 * 06/05/2018 Jacob Hinds     Commenting out EventCheckType.procesOpty, no longer needed 
 */

global class EventCheckTypeBatch implements Database.Batchable<SObject>, Schedulable {

  global JobHelper jh = new JobHelper('EventCheckTypeBatch');
   global DateTime startTime;
   
  global EventCheckTypeBatch() {
       startTime = DateTime.now();
    } // BatchJobChecker
 
  global Database.QueryLocator start(Database.BatchableContext BC){
    // save the record - show that the job started
      jh.setStarted();    
      return Database.getQueryLocator([Select Id, Number_Of_Events__c,Name from Opportunity where CloseDate = THIS_FISCAL_YEAR ]);
      //return Database.getQueryLocator([Select Id, Number_Of_Events__c,Name from Opportunity where CloseDate = TODAY and Name like 'A%' ]);
        
  } // start

  /** In order to schedule a batch run
    */
    global void execute(SchedulableContext sc) {
       EventCheckTypeBatch ect = new EventCheckTypeBatch();
         database.executeBatch(ect, 100);
    } // execute
    
    global void execute(Database.BatchableContext BC, List<Sobject> scope){
      Set<Id> optyIdSet = new Set<Id>();
System.debug('**CMF ** here at execute. scope='+scope.size());            
      List<Opportunity> optyList = (List<Opportunity>) scope;
      for (Opportunity opty : optyList)
      {  optyIdSet.add(opty.Id);    }
System.debug('**CMF ** here at execute, optyIdSet ='+optyIdSet.size());      
      /*if (!optyIdSet.isEmpty())
      { EventCheckType.procesOpty(optyIdSet);   }*/
    
    } // execute
    
    global void finish(Database.BatchableContext BC){               
        jh.completeJob(bc, 'EventCheckTypeBatch', 'All Opty Number of Events updated');
        
    } // finish
         
}