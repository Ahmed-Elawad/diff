/* 
  Clear DNC on records that have an expiration of today or older.
   
  History
  -------
  10/03/2018  Jake Hinds        Created
  12/23/2018  Dan Carmen        Modified to use StringHelper.addToProcessNotes method

*/
global class DNCExpirationBatch implements Database.batchable<SObject>,Database.Stateful, Schedulable{ 
	
   global JobHelper jh = new JobHelper('DNCExpirationBatch');
   global Lead[] leadsToUpdate = new Lead[]{};
   global Account[] accountsToUpdate = new Account[]{};
   global Contact[] contactsToUpdate = new Contact[]{};
   
   global DNCExpirationBatch(){
   	
   }
   
   global Iterable<Sobject> start(Database.batchableContext info){ 
       Date expDate = system.today();
       Date checkDate = system.today().addDays(Integer.valueOf(Label.DNC_Expiration_Day_Check)*-1);
       system.debug('DNCExpirationBatch checkDate'+checkDate);
       jh.setStarted();
       system.debug('starting Batch process');
       Iterable<SObject> iteration = (Iterable<SObject>) new DNCExpirationIterator(expDate,checkDate);
       return iteration; 
   }     
   
   global void execute(SchedulableContext sc) {
      system.debug('Batch Process scheduled');
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('DNCExpirationBatch');
      // pull from the custom setting, otherwise use a default value.
      Integer batchSize = (abc != null ? Integer.valueOf(abc.BatchSize__c) : 500);
      DNCExpirationBatch dnceb = new DNCExpirationBatch();
      database.executeBatch(dnceb, batchSize);
   } // execute
   
   global void execute(Database.batchableContext info, List<SObject> scope){ 
       for(Sobject s:scope){
           if(s.getSObjectType().getDescribe().getName() == Account.getSObjectType().getDescribe().getName()){
               Account acct = (Account)s;
               acct.DNC_Expiration__c = null;
               acct.Do_Not_Call__c = false;
               StringHelper.addToProcessNotes(acct,'Clearing DNC because of expiration date');
               accountsToUpdate.add(acct);
           }
           else if(s.getSObjectType().getDescribe().getName() == Contact.getSObjectType().getDescribe().getName()){
           	   Contact ctct = (Contact)s;
               ctct.DNC_Expiration__c = null;
               ctct.DoNotCall = false;
               StringHelper.addToProcessNotes(ctct,'Clearing DNC because of expiration date');
               contactsToUpdate.add(ctct);
           }
           else if(s.getSObjectType().getDescribe().getName() == Lead.getSObjectType().getDescribe().getName()){
           	   Lead ld = (Lead)s;
               ld.DNC_Expiration__c = null;
               ld.DoNotCall = false;
               StringHelper.addToProcessNotes(ld,'Clearing DNC because of expiration date');
               leadsToUpdate.add(ld);
           }
       }
       if(!accountsToUpdate.isEmpty()){
       		DmlHelper.performDML2(accountsToUpdate, DmlHelper.DML_UPDATE, 'DNCExpirationBatch', 'execute', 'updateAccts', true);
       }
       if(!contactsToUpdate.isEmpty()){
       		DmlHelper.performDML2(contactsToUpdate, DmlHelper.DML_UPDATE, 'DNCExpirationBatch', 'execute', 'updateCtcts', true);
       }
       if(!leadsToUpdate.isEmpty()){
       		DmlHelper.performDML2(leadsToUpdate, DmlHelper.DML_UPDATE, 'DNCExpirationBatch', 'execute', 'updateLds', true);
       }
   }     
   
   global void finish(Database.batchableContext info){  
   	   String message = '\nAccount Records processed: '+ accountsToUpdate.size()+' ';
   	   message += '\nContact Records processed: '+ contactsToUpdate.size()+' ';
   	   message += '\nLead Records processed: '+ LeadsToUpdate.size()+' ';
	   system.debug('message:'+message);
       jh.completeJob(info, 'DNCExpirationBatch process', message);   
   } 
}