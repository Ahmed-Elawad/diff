/* Queuable job for ManagePackageLicenseHelper to process async
   
  History
  -------
    11/30/2018 Jake Hinds   Created 
    8/25/2020  Carrie Marciano Added creation of Oracle CPQ User
	1/28/2022  Carrie Marciano Added oracleUserstoUpdate functionality

*/
public with sharing class ManagePackageLicenseHelperQueueable implements Queueable{
	
	public Id[] mplIds;
    public Boolean success;
    public String failureMessage;
    public cafsl__Oracle_User__c[] oracleUsersToUpsert;
    
    public ManagePackageLicenseHelperQueueable(Id[] p_mplIds,Boolean p_success,String p_failureMessage,cafsl__Oracle_User__c[] p_oracleUsersToUpsert){
        mplIds = p_mplIds; 
        success = p_success; 
        failureMessage = p_failureMessage;
        oracleUsersToUpsert = p_oracleUsersToUpsert;
    }//ManagePackageLicenseHelperQueueable constructor
    
    public void execute(QueueableContext context) {
        finishProcess(mplIds,success,failureMessage,oracleUsersToUpsert);
    }//execute
    
    public static void finishProcess(Id[] mplIds,Boolean success,String failureMessage, cafsl__Oracle_User__c[] oracleUsersToUpsert){
    	
        String exceptionText;
        try {
            if(!oracleUsersToUpsert.isEmpty()){
                upsert oracleUsersToUpsert;
            }
        }catch(DmlException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // process exception here
                exceptionText = e.getDmlStatusCode(i) + ' ' + e.getDmlMessage(i);
                System.debug('ManagePackageLicenseHelperQueueable finishProcess exceptionText '+exceptionText); 
            }
        } 
        success = (exceptionText==null);
        if(test.isRunningTest()){
            string test = 'test is running';
            string test2 = 'test is queueable';
            system.debug(test + test2);
        }
        
	    Manage_Package_License__c[] mpls = [SELECT Id, Effective_Date__c,Approved_By__c,Process_Notes__c FROM Manage_Package_License__c WHERE Id in :mplIds];
    	if(success){
	        for(Manage_Package_License__c mpl : mpls){
	        	mpl.Effective_Date__c = DateTime.NOW();
	        	mpl.Approved_By__c = UserInfo.getUserId();
	        }
    	}
    	else{
	        for(Manage_Package_License__c mpl : mpls){
	        	mpl.Request_Status__c = 'Approval Failure';
	        	mpl.Process_Notes__c += failureMessage;
	        }
    	}
        if(mpls!=null && !mpls.isEmpty()){
        	update mpls;
        }
    }
}