/* 
 *  After trigger for the Web Service Log object
 *   
 * History
 * -------
 * 09/04/2018	Jermaine Stukes Created
 * 12/31/2018	Jermaine Stukes	Update reassign logic
 * 03/14/2019	Jermaine Stukes	Update unsuccessful logs logic
 * 11/18/2019	Jermaine Stukes	Update retry
 * 01/13/2022	Jermaine Stukes	Removed retry logic as it is triggered from the queueable
 */
trigger WebServiceLogAfter on Web_Service_Log__c (after update) 
{   
    /*public static Boolean retryFailedSubmissions = false;
    List<Web_Service_Log__c> ucUnSuccessfulLogs = new List<Web_Service_Log__c>();*/
    List<Web_Service_Log__c> ucReassignSkillList = new List<Web_Service_Log__c>();
    for (Web_Service_Log__c wsLog : Trigger.new)
    {    
        if(Trigger.isUpdate){
            if(!wsLog.Successful__c && WsLog.Invalid_Skill__c){
                ucReassignSkillList.add(wsLog);
            }
            /*Web_Service_Log__c oldLog = (Web_Service_Log__c)Trigger.oldMap.get(wsLog.id);  
            if(wsLog.UC_Service__c && wsLog.Successful__c && !oldLog.UC_Retry__c){
                retryFailedSubmissions = true;
            }*/

            /*else if(wsLog.UC_Service__c && !wsLog.Successful__c && wsLog.Rest_Response__c !=null){
                if(!(wsLog.Rest_Response__c.Contains('SkillAddress is not valid')) && String.isNotBlank(wsLog.UcServiceCaseId__c)){
                    ucUnSuccessfulLogs.add(wsLog);
                }
            }*/
        } 
    }
    if(!ucReassignSkillList.isEmpty())
    {
        WebServicesHelper whHelper = new WebServicesHelper();
        whHelper.updateInvalidSkillList(ucReassignSkillList);       
    }
    /*if(retryFailedSubmissions){
        WebServicesHelper whHelper = new WebServicesHelper();
        whHelper.runRetry();
    }
    /*if(!ucUnSuccessfulLogs.isEmpty()){
        WebServicesHelper whHelper = new WebServicesHelper();
        whHelper.initiateSupportProcess(ucUnSuccessfulLogs);
    }*/
}