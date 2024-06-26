/* 
 * General web service methods.
 *
 * History
 * -------
 * 03/07/2014 Cindy Freeman   Created
 * 04/22/2014 Cindy Freeman	  Modified to add response and request attachments if they are passed in.
 * 08/22/2018 Cindy Freeman	  Modified to add Files instead of attachments for response and requests
 * 08/28/2018 Jermaine Stukes	Added data for UC Integration logic
 * 12/31/2018 Jermaine Stukes	Udpdated UC logic to create files instead of saving large data to record
 * 03/12/2019 Jermaine Stukes	Created new update methods for S2S, transferred file creation logic to new method
 * 04/24/2019 Jermaine Stukes	Added S2S Support methods
 * 11/18/2019 Jermaine Stukes	Update S2S support process
 * 06/18/2020 Jake Hinds		bug fix for processSupport, check sp!=null
   04/16/2021 Dan Carmen        Add ability to group service call saves
   01/24/2022 Jermaine Stukes	Removed retry logic which is now triggered from queueable
 */

public without sharing class WebServicesHelper {

    public static Integer NOTES_SIZE=Web_Service_Log__c.Notes__c.getDescribe().getLength();
    public static Integer ERROR_SIZE=Web_Service_Log__c.ErrorMsg__c.getDescribe().getLength();
    private static list<S2S_Support_Message__c> supportMessages = S2S_Support_Message__c.getAll().Values();
    
   /** Create a simple log. */
   public static Web_Service_Log__c logServiceCall(String serviceName, Boolean isSuccess, String errorMsg, String notes) {
      Web_Service_Log__c wslog = new Web_Service_Log__c();
      wslog.CalledBy__c = UserInfo.getUserId();
      wslog.CalledDT__c = System.now();
      wslog.ServiceName__c = serviceName;
      wslog.Successful__c = isSuccess;
      wslog.NbrAttempts__c = 0;
      wslog.ErrorMsg__c = (String.isNotBlank(errorMsg) ? errorMsg.left(ERROR_SIZE) : null);
      wslog.Notes__c = (String.isNotBlank(notes) ? notes.left(NOTES_SIZE) : null);
      insert wslog;
      return wslog;
   } // logServiceCall
    
   // if we are in a lead convert, there will be multiple operations. We want to gather them all together and perform them at once to save DML operations
   public static Boolean groupSaveCalls=false;
    
   public class GroupedSave {
      public Web_Service_Log__c wslog;
      public Attachment request;
      public Attachment response;
   } // classs GroupedSave
    
	// insert a record into the Web Service Log object 
	public static Web_Service_Log__c logServiceCall(WebServiceWrapper wsWrap)
	{		
        GroupedSave gs = new GroupedSave();
		gs.wslog = new Web_Service_Log__c();
		gs.wslog.ServiceName__c = wsWrap.svcName;
		gs.wslog.CalledBy__c = UserInfo.getUserId();
		gs.wslog.CalledDT__c = System.now();
		gs.wslog.Successful__c = wsWrap.succes;
        gs.wslog.Rest_Response__c = wsWrap.ucResponse;
		gs.wslog.ErrorMsg__c = wsWrap.errMsg;
		gs.wslog.SendMsg__c = wsWrap.sendMsg;
		gs.wslog.NbrAttempts__c = (wsWrap.nbrAttempts != null ? wsWrap.nbrAttempts : 0);
		gs.wslog.Notes__c = (wsWrap.notes != null ? wsWrap.notes : null);
		gs.wslog.NamedFunction__c = wsWrap.namedFunction;
		gs.wslog.SobjName__c = wsWrap.sobjName;
		gs.wslog.Action__c = wsWrap.action;
		gs.wslog.NbrRecs__c = wsWrap.nbrRecs;
		gs.wslog.ServiceEnd__c = wsWrap.serviceEnd;
		gs.wslog.ServiceStart__c = wsWrap.serviceStart;
        gs.wslog.JSON_Request__c = wsWrap.ucRequest;
        if (!groupSaveCalls) {
           insert gs.wslog;
        }
		System.debug('logServiceCall groupSaveCalls='+groupSaveCalls+' wslog='+gs.wslog.Id);
		Attachment[] attachments = new Attachment[]{};
		if (wsWrap.responsexml != null && wsWrap.responsexml.length() > 0)
		{	//Web_Service_Log__c newWslog = getWebServiceLog(wslog.Id);
			
			gs.response = new Attachment();
         	gs.response.Body = Blob.valueOf(wsWrap.responsexml);  
         	gs.response.Name = gs.wslog.Id + '-response';     		
         	gs.response.ParentID = gs.wslog.id;
         	attachments.add(gs.response);
         	/*
         	FileWrapper fw = new FileWrapper(new Id[]{newWsLog.Id}, newWslog.Name + '-response', newWslog.Name + '-response', null, Blob.valueOf(wsWrap.responsexml));
         	fileWrapList.add(fw);
			*/
		} // if (wsWrap.responsexml != null)
		
		if (wsWrap.requestxml != null && wsWrap.requestxml.length() > 0)
		{	//Web_Service_Log__c newWslog = getWebServiceLog(wslog.Id);
			
			gs.request = new Attachment();
         	gs.request.Body = Blob.valueOf(wsWrap.requestxml);  
         	gs.request.Name = gs.wslog.Id + '-request';     		
         	gs.request.ParentID = gs.wslog.id;
         	attachments.add(gs.request);
         	/*
         	FileWrapper fw = new FileWrapper(new Id[]{newWsLog.Id}, newWslog.Name + '-request', newWslog.Name + '-request', null, Blob.valueOf(wsWrap.requestxml));
         	fileWrapList.add(fw);
			*/
		} // if (requestxml != null)    
		
        if (!groupSaveCalls && !attachments.isEmpty()) {
           insert attachments;
        }
		
        if (groupSaveCalls) {
            groupedSaves.add(gs);
        }
      return gs.wslog;
	} // logServiceCall   
    
    public static GroupedSave[] groupedSaves = new GroupedSave[]{};
    
    public static void saveGroupedSaves() {
       Web_Service_Log__c[] logs = new Web_Service_Log__c[]{};
       for (GroupedSave gs : groupedSaves) {
          logs.add(gs.wslog);
       }
       insert logs;
       Attachment[] attachments = new Attachment[]{};
       for (GroupedSave gs : groupedSaves) {
          if (gs.request != null && gs.wsLog.Id != null) {
             gs.request.Name = gs.wslog.Id + '-request';     		
             gs.request.ParentID = gs.wslog.id;
             attachments.add(gs.request);
          }
          if (gs.response != null && gs.wsLog.Id != null) {
             gs.response.Name = gs.wslog.Id + '-response';     		
             gs.response.ParentID = gs.wslog.id;
             attachments.add(gs.response);
          }
       } // for (GroupedSave)
       if (!attachments.isEmpty()) {
          insert attachments;
       }

    } // saveGroupedSaves
    
	public static Web_Service_Log__c getWebServiceLog(Id logId) {
		Web_Service_Log__c wsl=null;
		if (logId != null) {
		   wsl = [select Id, Name from Web_Service_Log__c where id = :logId];
		}
		return wsl;
	} // getWebServiceLog 
	/* return web service custom setting
	*/
	public static WebServiceSettings__c getWebSvcSetting(String svcName) {
      WebServiceSettings__c wss = WebServiceSettings__c.getInstance(svcName);
      if (wss != null && !wss.IsActive__c) {
         wss = null;
      }
     	return wss;
     	
	} // getWebSvcSetting
    //UC Integration Methods
    public void sendToUC(List<Web_Service_Log__c> ucLogList){
        CaseS2SQueueable cS2S = new CaseS2SQueueable(ucLogList);
        cS2S.launchQueueable();
    }
    Public void createWsLog(Id caseId){
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        wslog.SobjName__c =  'Case';
        wsLog.CalledBy__c = UserInfo.getUserId();
        wsLog.CalledDT__c = System.now();
        wsLog.ServiceName__c = 'CaseS2SQueuable';
        wsLog.NbrAttempts__c = 0;
        wsLog.Action__c = 'Create case in UC';
        wsLog.NamedFunction__c = 'createUcCase';
        wsLog.Rest_Response__c = null;
        wsLog.UC_Service__c = true;
        wsLog.UcServiceCaseId__c = caseId;
        Web_Service_Log__c[] logList = new Web_Service_Log__c[]{wsLog};
            DmlHelper.performDML2(logList, DmlHelper.DML_INSERT, 'CaseS2SController', 'createWsLog', 'createWsLog', true);
        sendToUC(logList);
    }
    public static void createLogFile(FileWrapper[] fileWrapList){//List<WebServiceWrapper> wswList, Map<String,Web_Service_Log__c> wsLogMap){ // wsWrap,Web_Service_Log__c wslog ){
        //Update wsLogList;
        //DMLHelper.performDML2(wsLogList, DmlHelper.DML_UPDATE, 'WebServicesHelper', 'updateLog', 'Update Web Service Log', true);
        if (!fileWrapList.isEmpty())
		{	AddFileQueueable afq = new AddFileQueueable(fileWrapList);	
			afq.processRecs();
		}		
	}// updateLog  
    /*public void runRetry(){
        List<Web_Service_Log__c> wsRetryList = [Select Id, UcServiceCaseId__c, Invalid_Skill__c, UC_Retry__c, NbrAttempts__c, Rest_Response__c from Web_Service_Log__c where UC_Retry__c = true and UcServiceCaseId__c !=null];
        if(wsRetryList.size() > 10){
            List<Web_Service_Log__c> wslList = new List<Web_Service_Log__c>();
            for(Web_Service_Log__c wsl : wsRetryList){
                if(wslList.size() < 9){
                    wslList.add(wsl);
                }
                else{
                    wslList.add(wsl);
                    sendToUC(wslList, true);
                    wslList.clear();
                }
            }
            sendToUC(wslList, true);
        }
        else{
            sendToUC(wsRetryList, true);
        }
    }*/
    public void updateInvalidSkillList(List<Web_Service_Log__c> errorLogs){
        List<Web_Service_Log__c> logList = new List<Web_Service_Log__c>();
        for(Web_Service_Log__c log : errorLogs){
            Web_Service_Log__c cloneLog = new Web_Service_Log__c();
            cloneLog.UcServiceCaseId__c = log.UcServiceCaseId__c;
            cloneLog.UC_Service__c = true;
            cloneLog.UC_Notes__c = log.UC_Notes__c;
            cloneLog.ServiceName__c = log.ServiceName__c;
            cloneLog.NamedFunction__c = log.NamedFunction__c;
            cloneLog.Invalid_Skill__c = true;
            logList.add(cloneLog);
        }
        insert logList;
        sendToUC(logList);
    }// updateUnsuccessfulLogList
    /*public void initiateSupportProcess(List<Web_Service_Log__c> errorLogs){
        List<String> exceptionList = new List<String>();
        
        for(Web_Service_Log__c logFile : errorLogs){
            exceptionList.add(LogFile.ErrorMsg__c);
        }
        processSupport(exceptionList, null);
        checkThresholds();
    }
    
    private void checkThresholds(){
        DateTime last24Hours = DateTime.now().addHours(-24);
        List<Web_Service_Log__c> wsList = [select Id, SnowCaseCreated__c, Successful__c from Web_Service_Log__c where ServiceName__c='CaseS2SQueuable' and CreatedDate >=: last24Hours Order by CreatedDate Asc ];
        Integer thresholdLimit = Integer.valueOf(Label.UC_Failure_Limit);
        Integer consecutiveFailureCount = 0;
        Boolean  thresholdReached = true;
        if(wsList.size() >= thresholdLimit){
            for(integer i = 0 ; i < thresholdLimit; i++){
                if(wsList[i].Successful__c){
                    thresholdReached = false;
                    break;
                }
            }
        }else{
            thresholdReached = false;
        }

        if(thresholdReached){
            String exceptionCaught = 'Consecutive failure limit reached';
            processSupport(new String[]{exceptionCaught}, wsList);
        }     
    }
    private void processSupport(List<String> exceptionList, List<Web_Service_Log__c> wsList){
        List<Support_Process__c> supportList = Support_Process__c.getAll().Values();
        Map<String, Support_Process__c> s2sSupportMap = new Map<String, Support_Process__c>(); 
        for(Support_Process__c supportType : supportList) {
            if (supportType.Process_being_supported__c == 'S2S') {
                s2sSupportMap.put(supportType.Exception_caught__c, supportType);
            }
        }
        for(String exceptionCaught : exceptionList){
            Support_Process__c sp = s2sSupportMap.get(exceptionCaught) != null ? 
            s2sSupportMap.get(exceptionCaught) : s2sSupportMap.get('Default');
            if(sp!=null){
                if(sp.Create_Chatter_Message__c){
                    sendChatterNotification(sp);
                }
                if(sp.Create_SNOW_Case__c){
                    if(wsList != null){
                        Boolean emailSent = false;
                        for(Web_Service_Log__c log : wsList){
                            if(log.SnowCaseCreated__c){
                                emailSent = true;
                                break;
                            }
                        }
                        if(!emailSent){
                            createSnowCase(null);
                            wsList[0].SnowCaseCreated__c = true;
                            update wsList;
                        }
                    }
                }
            }
        }
    }*/
    private void sendChatterNotification(Support_Process__c supportProcessRecord){
        //String userToMention = supportProcessRecord.ChatterUser_to_Mention__c != null ? supportProcessRecord.ChatterUser_to_Mention__c : null;
        String[] userList = new String []{};
        String groupId = supportProcessRecord.Chatter_Group__c;
        String ChatterNotification = supportProcessRecord.Chatter_Notification__c;
        ChatterMentionPost.createChatterMentionPost(groupId,userList,ChatterNotification);
        ChatterMentionPost.checkPostFeedElements();
    }//sendChatterNotification   

    /*public void createSnowCase(List<Case> CaseList){
        if(CaseList != null){
            for(Case kase : CaseList){
                kase.Send_Case_to_Service_Now__c = true;
            }
        }
        else{
            Contact snowConcat = [Select Id from Contact where name=:label.s2s_Contact limit 1];
            Case snowCase = new Case(Service_Now_State__c = 'New', Originator__c = snowConcat.Id, Urgency__c = '1 - High', Assignment_Group__c = 'DEV - SALESFORCE.COM', Impact__c='2 - Medium', Business_Application__c = 'Sales Force Automation System', Service_Now_Priority__c = '2 - High', Service_Now_Caller__c = label.CoeUserEmail, Send_Case_to_Service_Now__c = true, Status = 'Escalated', Origin = 'Web', Subject = 'Sales2Service Issue');
            snowCase.recordTypeId = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case').getRecordTypeId();
            snowCase.Description = 'There have been 5 or more consecutive failed Sales2Service submissions to UC, Please contact Salesforce Dev to verify process is working as expected';
            insert snowCase;
        }
    }//createSnowCase*/
    
	// wrapper class to hold all fields that might be needed for log
	public class WebServiceWrapper
	{
        public String svcName;
        public Boolean succes = false;
        public String errMsg;
        public String notes;
        public String responsexml;
        public String requestxml;
        public String namedFunction;
        public Boolean sendMsg = false;
        public String sobjName;
        public String action;
        public Integer nbrAttempts;
        public Integer nbrRecs;
        public DateTime serviceStart;
        public DateTime serviceEnd;
        public String logFileId;
        public Boolean ucServiceCall = false;
        public Boolean ucRetryFailed = false;
        public Boolean ucJobError = false;
        public String ucCallCaseId;
        public String ucCallJobId;
        public String ucGuid;
        public String ucNotes;
        public String ucRequest;
        public String ucResponse;
        public Boolean ucRetry;
	} // class WebServiceWrapper		
	
} // class WebServicesHelper