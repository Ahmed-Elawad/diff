/* 
 *  Before trigger for the Web Service Log object
 *   
 * History
 * -------
 * 10/11/2018 	Jermaine Stukes     Created
 * 11/24/2019	Jermaine Stukes		Updated
 * 01/13/2022	Jermaine Stukes		Updated
 */
trigger WebServiceLogBefore on Web_Service_Log__c (before update) {
    for (Web_Service_Log__c wsLog : Trigger.new)
    {       
        if(Trigger.isUpdate){
            if(wsLog.UC_Service__c && !wsLog.Successful__c && wsLog.Rest_Response__c !=null)
            {
                if(wsLog.Rest_Response__c.Contains('SkillAddress is not valid') && String.isNotBlank(wsLog.UcServiceCaseId__c))
                {wsLog.Invalid_Skill__c = true;}
                else if(!wslog.UC_Retry__c && !wslog.UcRetryFailed__c && wsLog.UcServiceCaseId__c != null){
                    wsLog.UC_Retry__c = true;
                }
            }
        }        
    }
}