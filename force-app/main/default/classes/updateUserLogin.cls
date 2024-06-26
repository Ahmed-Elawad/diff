/* 
  Update number of logins on user for active community  users
   
  History
  -------
   05/13/2021     Susmitha Somavarapu  Created

*/
global class updateUserLogin implements Database.Batchable<sObject>,Database.Stateful, Schedulable  {
     public static final String CLASS_NAME='updateUserLogin';
    global JobHelper jh = new JobHelper(CLASS_NAME);

    global Database.QueryLocator start(Database.BatchableContext BC) {
              jh.setStarted();
        String profileName='Customer Community Login User Clone';
        String query;
        if(!test.isRunningTest())
        query = 'SELECT Id, Name,Number_of_logins__c FROM User where isactive=true and profile.Name=:profileName';
        else
        query =  'SELECT Id, Name,Number_of_logins__c FROM User where isactive=true and profile.Name=:profileName limit 1';
        
        return Database.getQueryLocator(query);
    }
       global Integer numberUsers = 0;

    global void execute(Database.BatchableContext BC, List<User> usrList) {
              numberUsers += usrList.size();

        set<id> userIdSet=new set<id>();
        for(User usr : usrList) {        
            userIdSet.add(usr.id);
        }
        try {
            map<id,integer> userlogincount=new map<id, integer>();
            
            list<aggregateresult> loginHistoryRecords= [select count(logintime) cou, userid from loginhistory where userid in:useridset group by userid];
            for(aggregateresult agre:loginHistoryRecords){
                userlogincount.put((id)agre.get('userid'),(integer)agre.get('cou'));
            }
            for(User usr : usrList) {  
                
                usr.Number_of_logins__c= userlogincount.get(usr.id);
            }
            //database.update(usrList, false);
            if (!usrList.isEmpty()) {
                DmlHelper.performDML2(usrList, DmlHelper.DML_UPDATE, 'updateUserLogin', 'execute', 'usrList', true);
            }
        } catch(Exception e) {
            System.debug(e);
        }
        
    }  
    global void execute(SchedulableContext sc) {
      
      updateUserLogin updateUserBatch = new updateUserLogin();
      database.executeBatch(updateUserBatch);
   } // execute
    global void finish(Database.BatchableContext BC) {
         String message = '\nTotal Users processed: '+ numberUsers+' ';
      
      system.debug('message:'+message);
      jh.completeJob(BC,'UpdateUserLoginBatch process', message);

    }
}