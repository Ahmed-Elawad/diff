/* 
 * A batch job for checking if email address has changed on user record
 *
 * History
 * -------
 * 10/08/2020 Carrie Marciano   Created
 * 02/25/2021 Carrie Marciano	Added Job Tracker entry
 *
 */

global without sharing class UserEmailChangeSchedulable implements Schedulable {

   public Job_Tracker__c tracker = new Job_Tracker__c();  
   public static String STATUS_STARTED='Started';
   public static String STATUS_COMPLETED='Completed';
    
   global void execute(SchedulableContext sc) {
       runProcess();
   } // execute

   global void runProcess(){      
       Apex_Batch_Control__c abc = getBatchControl();
       Integer batchSize = ((abc != null && abc.Active__c && abc.BatchSize__c != null) ? Integer.valueOf(abc.BatchSize__c) : 40);

       // need to exclude Admins (cafsl__User_Type__c FULL_ACCESS) because any update to a CPQ User record for an admin with All Access will clear their permissions
       cafsl__Oracle_User__c[] changedUsers = [Select Id, LatestEmail__c, LatestEmailChanged__c, cafsl__User__c
                                                   ,cafsl__User__r.Id, cafsl__User__r.Email, cafsl__User__r.Sales_Division__c, cafsl__User__r.Zonetxt__c, cafsl__User_Type__c
                                                   From cafsl__Oracle_User__c
                                                   Where LatestEmailChanged__c = true
                                              	   limit :batchSize];
       
        Boolean runAgain = (changedUsers.size() == batchSize);  
        for (cafsl__Oracle_User__c usr : changedUsers) {
                System.debug('runProcess before usr.cafsl__User__r.Email: '+usr.cafsl__User__r.Email+' usr.LatestEmail__c: '+usr.LatestEmail__c);
            	usr.LatestEmail__c = usr.cafsl__User__r.Email;
                System.debug('runProcess after usr.cafsl__User__r.Email: '+usr.cafsl__User__r.Email+' usr.LatestEmail__c: '+usr.LatestEmail__c); 
        }
		                                                       
        try {
                update changedUsers;
            } 
            catch (Exception e) {
                tracker.Notes__c += 'Error: '+e.getMessage();
                System.debug('runProcess Error: '+e.getMessage());
        }
       
       	if (runAgain && abc != null && abc.Active__c){
                System.debug('runProcess runAgain is true, schedule job.execute');
          		UserEmailChangeSchedulable job = new UserEmailChangeSchedulable();
           		job.execute(null);  
      	}
       
       tracker.Nbr_Batches__c = 1;
       tracker.Job_Name__c = 'UserEmailChangeSchedulable';
       tracker.Notes__c = 'Number of users updated: '+changedUsers;
       tracker.Process_End__c = DateTime.now();
       tracker.Status__c=STATUS_COMPLETED;
       insert tracker;
   }    

   public static Apex_Batch_Control__c getBatchControl() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('UserEmailChangeSchedulable');
      return abc;
   } // getBatchControl
       
}