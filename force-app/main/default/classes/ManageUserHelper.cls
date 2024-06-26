/* 
* Helper methods for managing users

*
* History
* -------
04/08/2015 Dan Carmen   Created
10/12/2015 Dan Carmen   Attempt to capture timeout error.
02/27/2018 Dan Carmen   Fix so trigger doesn't fire multiple times while processing.
03/26/2018 Dan Carmen   Account for no activity to transfer
05/29/2020 Josh Cartwright added to oppty query to use closedate if custom label is set to Y 
06/01/2023 Carrie Marciano FY24 Transfer User options (originally done by Bindu)


*
*/
public without sharing class ManageUserHelper {
    
    public static final String STATUS_INCOMPLETE='Incomplete';
    public static final String STATUS_USER_CREATE='Pending User Create';
    public static final String STATUS_USER_ROLE_UPDATE='Pending Role Update';
    public static final String STATUS_USER_TXFER='Pending User Transfer';
    public static final String STATUS_ACT_TRANSFER='Pending Activity Transfer';
    public static final String STATUS_ACT_TRANSFER_ERROR='Pending Activity Error';
    public static final String STATUS_COMPLETE='Complete';
    public static final String STATUS_TXFER_ERROR='Transfer User Error';
    
    public static Boolean USE_QUEUEABLE=Label.UserTransfer_UseQueueable=='Y';
    
    // for testing purposes
    public static Boolean SKIP_FUTURE=Test.IsRunningTest();
    
    public static void checkActivityTransfer(String sessionId, Id[] userTransferIds) {
        if (!SKIP_FUTURE && !System.isFuture() && !System.isBatch()) {
            // run in future context
            checkTransferActivityFuture(sessionId, userTransferIds);
        } else {
            // run immediate
            checkTransferActivity(sessionId, userTransferIds);
        }
    } // checkActivityTransfer
    
    @future
    public static void checkTransferActivityFuture(String sessionId, Id[] userTransferIds) {
        checkTransferActivity(sessionId, userTransferIds);
    }
    
    public static void checkTransferActivity(String sessionId, Id[] userTransferIds) {
        User_Transfer__c[] userTransfers = getUserTransfers(userTransferIds);
        checkTransferActivity(sessionId, userTransfers);
    } // checkTransferActivity
    
    public static void checkTransferActivity(String sessionId, User_Transfer__c[] userTransfers) {
        system.debug('checkTransferActivity begin userTransfers: '+userTransfers);
        ManageUserHelper.USER_TRANSFER_TRIGGER_EXECUTING = true;
        for (User_Transfer__c userTransfer : userTransfers) {       
            if (!transferActivity(sessionId, userTransfer)) {
                userTransfer.Status__c = STATUS_ACT_TRANSFER_ERROR;
                //break;
            } else {
                if (!USE_QUEUEABLE || (USE_QUEUEABLE && !hasQueriesToTransfer)) {
                    userTransfer.Status__c = STATUS_COMPLETE;
                }
                // TODO - do we do anything if this is queueable?
            }
            system.debug('checkTransferActivity userTransfer.Status__c end for: '+userTransfer.Status__c);
        } // for (User_Transfer__c userTransfer
        
        system.debug('checkTransferActivity userTransfers.size(): '+userTransfers.size());        
        update userTransfers;
        system.debug('checkTransferActivity after update userTransfers'); 
        generateEmails(userTransfers);
                  
    } // checkTransferActivity
    
    public static List<UserRole> getUserRole(String roleName) {
        return [SELECT Id, Name FROM UserRole WHERE Name = :roleName];
    }
    
    public static List<Profile> getProfile(String profileName) {
        return [SELECT Id, Name FROM Profile WHERE Name = :profileName];
    }
    
    // general emails when the process completes
    public static void generateEmails(User_Transfer__c[] userTransfers) {
        Messaging.SingleEmailMessage[] messages = new Messaging.SingleEmailMessage[]{};
            for (User_Transfer__c userTransfer : userTransfers) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(userTransfer.CreatedById);
                mail.setSaveAsActivity(false);
                
                mail.setSubject('Transfer finished with a status of '+userTransfer.Status__c);
                
                String body = 'Transfer finished. \nOriginal user record ('+userTransfer.Existing_User__r.Name+'): '+Utilities.instanceUrl()+'/'+userTransfer.Existing_User__c;
                body += '\nNew user record ('+userTransfer.New_User__r.Name+'): '+Utilities.instanceUrl()+'/'+userTransfer.New_User__c;
                body += '\n\n Results of transfer:';
                body += '\nNbr Events Success: '+userTransfer.Nbr_Events__c;
                body += '\nNbr Events Failed: '+userTransfer.Nbr_Events_Failed__c;
                body += '\nNbr Tasks Success: '+userTransfer.Nbr_Tasks__c;
                body += '\nNbr Tasks Failed: '+userTransfer.Nbr_Tasks_Failed__c;
                body += '\nNbr Opportunities Success: '+userTransfer.Nbr_Opptys__c;
                body += '\nNbr Opportunities Failed: '+userTransfer.Nbr_Opptys_Failed__c;
                body += '\nNbr Cases Success: '+userTransfer.Nbr_Cases__c;
                body += '\nNbr Cases Failed: '+userTransfer.Nbr_Cases_Failed__c;
                
                
                mail.setPlainTextBody (body);
                messages.add(mail);
            }
        Messaging.sendEmail(messages);
        
    } // generateEmails
    
    public static User_Transfer__c[] getUserTransfers(Id[] userTransferIds) {
        System.debug('getUserTransfers begin userTransfers.size: '+userTransferIds.size());
        User_Transfer__c[] userTransfers = 
            [Select Id, Name
             ,Activity_Xfer_To__c
             ,Activity_Xfer_To__r.Id
             ,Activity_Xfer_To__r.Name
             ,Activity_Xfer_To__r.IsActive
             ,Comments__c
             ,CostCenter__c
             ,CreatedById
             ,Effective_Date__c
             ,Email__c
             ,Existing_User__c
             ,Existing_User__r.Id
             ,Existing_User__r.Name
             ,Existing_User__r.IsActive
             ,ExistingUserIsSurvivor__c
             ,HasClosedActivity__c
             ,HasOpenActivity__c
             ,IsExistingSales__c
             ,IsTxferSales__c
             ,Manage_Type__c
             ,Nbr_Cases_Failed__c
             ,Nbr_Cases__c
             ,Nbr_Events_Failed__c
             ,Nbr_Events__c
             ,Nbr_Opptys_Failed__c
             ,Nbr_Opptys__c
             ,Nbr_Tasks_Failed__c
             ,Nbr_Tasks__c
             ,New_User__c
             ,New_User__r.Id
             ,New_User__r.Name
             ,New_User__r.IsActive
             ,ProcessTracker__c
             ,Status__c
             ,Username__c
             ,Role__c
             ,Profile__c
             ,Transfer_Type__c
             From User_Transfer__c
             Where Id in :userTransferIds];
        return userTransfers;
    } // getUserTransfers
    
    public static Map<String,String> getActivityQueryMap(Id curOwnerId, Date effectiveDate,Boolean isOpen, Boolean isSalesTransfer, String transferType) {
        Map<String,String> activityQueryMap = new Map<String,String>();
        Decimal openProbability = Decimal.valueOf(Label.OpenOpportunityProbability);
        System.debug('getActivityQueryMap isSalesTransfer: '+isSalesTransfer+' transferType: '+transferType+' isOpen: '+isOpen);
        
        if (isSalesTransfer){
            if(isOpen){
                switch on transferType{
                    /* when 'Update User Role Only'{
                    // Only updating user role only no transferred user, Ex: District closing, District splitting
                    // done in ManageUserController.checkOptionTransferRecord
                    
                    }
                    when 'Transfer User Basic'{
                    // No Opportunities or Activity will Transfer, Ex: changing sales orgs
                    // done in ManageUserController.checkOptionTransferRecord
                    
                    }  */
                    when 'Transfer User with Open Activity'{
                        // Move All Open Tasks and Events Only, Ex: User needs tasks and scheduled activity to move with them
                        activityQueryMap.put(ObjectHelper.OBJECT_TASK,getClosedObjectQuery(curOwnerId,ObjectHelper.OBJECT_TASK,false, null, null)); 
                        activityQueryMap.put(ObjectHelper.OBJECT_EVENT,getEventsQuery(curOwnerId, effectiveDate, false)); 
                    }
                    when 'Transfer User and Open Opportunities Only'{
                        // Move open Opportunities that are in sold or prior status, Ex: User allowed to keep working open opportunities
                        activityQueryMap.put(ObjectHelper.OBJECT_OPPTY,getClosedObjectQuery(curOwnerId,ObjectHelper.OBJECT_OPPTY,false, null, openProbability));
                    }
                    when 'Move Open Activity and Open Opportunities'{
                        // Move both Activity and Opportunity, Ex: User allowed to keep working existing open opportunities and open activity
                        activityQueryMap.put(ObjectHelper.OBJECT_TASK,getClosedObjectQuery(curOwnerId,ObjectHelper.OBJECT_TASK,false, null, null)); 
                        activityQueryMap.put(ObjectHelper.OBJECT_OPPTY,getClosedObjectQuery(curOwnerId,ObjectHelper.OBJECT_OPPTY,false, null, openProbability));
                        activityQueryMap.put(ObjectHelper.OBJECT_EVENT,getEventsQuery(curOwnerId, effectiveDate, false)); 
                    }
                    when null{
                    	activityQueryMap.put(ObjectHelper.OBJECT_TASK,getClosedObjectQuery(curOwnerId,ObjectHelper.OBJECT_TASK,false, effectiveDate, null)); 
                        activityQueryMap.put(ObjectHelper.OBJECT_OPPTY,getClosedObjectQuery(curOwnerId,ObjectHelper.OBJECT_OPPTY,false, null, openProbability));
                        activityQueryMap.put(ObjectHelper.OBJECT_EVENT,getEventsQuery(curOwnerId, effectiveDate, false));     
                    }
                } // switch       
            } else{
                activityQueryMap.put(ObjectHelper.OBJECT_TASK,getClosedObjectQuery(curOwnerId,ObjectHelper.OBJECT_TASK,true, effectiveDate, null));
                activityQueryMap.put(ObjectHelper.OBJECT_OPPTY,getClosedObjectQuery(curOwnerId,ObjectHelper.OBJECT_OPPTY,true, effectiveDate, openProbability));
                activityQueryMap.put(ObjectHelper.OBJECT_EVENT,getEventsQuery(curOwnerId, effectiveDate, true));
            } // isOpen       		     
        } else {
            activityQueryMap.put(ObjectHelper.OBJECT_TASK,getClosedObjectQuery(curOwnerId,ObjectHelper.OBJECT_TASK,false, NULL, null));
            activityQueryMap.put(ObjectHelper.OBJECT_CASE,getClosedObjectQuery(curOwnerId,ObjectHelper.OBJECT_CASE,false, NULL, null));
            activityQueryMap.put(ObjectHelper.OBJECT_EVENT,getEventsQuery(curOwnerId, effectiveDate, false));  
        } // isSalesTransfer
        
        return activityQueryMap;
    } // getActivityQueryMap
    
    // Get the query to retrieve the objects that use the IsClosed field.
    // @param curOwnerId the Id of the current owner
    // @param isClosed true to select the closed tasks, false to select the open tasks
    public static String getClosedObjectQuery(Id curOwnerId, String objectName, Boolean isClosed, Date effectiveDate, Decimal probability) {
        String query = 'Select Id, OwnerId from '+objectName+' ' +
            'where ownerId = \''+ curOwnerId +'\' '+ 
            'and IsClosed = ';
        query += isClosed ? 'true' : 'false';
        if (objectName=='Task') {
            query += ' AND IsRecurrence=false AND RecurrenceActivityId=null ';
        }
        if (objectName =='Opportunity' && isClosed == false && probability != null){
        	query += ' AND Probability <' + probability;    
        }
        else if (objectName=='Opportunity' && effectiveDate != NULL){
            string compareDate = Datetime.newInstance(effectiveDate, Time.newInstance(23, 59, 59, 59)).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            if( Label.TransferUser_Use_Opp_Close_Date =='N' ){
                query += ' AND createdDate <=' + string.escapeSingleQuotes(compareDate);
            }
            if(Label.TransferUser_Use_Opp_Close_Date =='Y'){
                compareDate= Datetime.newInstance(effectiveDate, Time.newInstance(23, 59, 59, 59)).format('yyyy-MM-dd');
                query += ' AND closedate <=' + string.escapeSingleQuotes(compareDate);
            }
        }
        System.debug('getClosedObjectQuery query='+query);
        return query;
    } // getClosedObjectQuery 
    
    // Get the query used to retrieve the events.
    // @param curOwnerId the Id of the current owner
    // @param effectiveDate the date used to query the records.
    // @param beforeDate true to retrieve the records before the effective date, false to retrieve
    //           the records after.
    public static String getEventsQuery(Id curOwnerId, Date effectiveDate, Boolean beforeDate) {
        String query = 'Select Id, OwnerId from Event ' +
            'where ActivityDate ';
        query += beforeDate ? '<' : '>=';
        String dateStr = effectiveDate+' ';
        // remove the time stamp, keep the correct format.
        dateStr = dateStr.substring(0, dateStr.indexOf(' '));
        query += ' '+dateStr+' ';
        query += ' AND ownerId=\''+curOwnerId+'\' ';
        query += ' AND IsRecurrence=false AND RecurrenceActivityId=null ';
        System.debug('getEventsQuery query='+query);
        return query;
    } // getEventsQuery
    
    private static Boolean hasQueriesToTransfer = false;
    
    // Transfer all Activity before the effective date to the new User record that
    //    was created.
    //    For Sales, this is all closed Opportunities, and Tasks and Events with 
    //      Activity Date before the Effective Date.
    //    If unable to transfer all activity (because of limits) false is returned.
    private static Boolean transferActivity(String sessionId, User_Transfer__c userTransfer) {
        System.debug('transferActivity begin'); 
        Boolean okay = true;
        hasQueriesToTransfer = false;
        
        System.debug('transferActivity HasClosedActivity__c='+userTransfer.HasClosedActivity__c+' ExistingUserIsSurvivor__c='+userTransfer.ExistingUserIsSurvivor__c+' HasOpenActivity__c='+userTransfer.HasOpenActivity__c+' userTransfer.New_User__r='+userTransfer.New_User__r+' userTransfer.Transfer_Type__c='+userTransfer.Transfer_Type__c);
        // make sure target user record is active
        User closedTargetUser = ((userTransfer.HasClosedActivity__c && userTransfer.ExistingUserIsSurvivor__c) ? userTransfer.New_User__r : null);
        
        User openTargetUser = null;
        if (okay) {     
             if (userTransfer.HasOpenActivity__c) {   
                 if (userTransfer.IsTxferSales__c){
                 	openTargetUser = userTransfer.Activity_Xfer_To__r; 
                 	if (!userTransfer.ExistingUserIsSurvivor__c) {
                     	openTargetUser = userTransfer.New_User__r;
                	}    
                 }
                 else{ // not sales
                 	openTargetUser = userTransfer.Activity_Xfer_To__r; 
                 	if (openTargetUser == null && userTransfer.ExistingUserIsSurvivor__c){
                    	openTargetUser = closedTargetUser;
                 	}     
                 } // IsTxferSales__c
            } // if (userTransfer.HasOpenActivity__c     
        } // if (okay)
        
        System.debug('transferActivity closedTargetUser='+closedTargetUser+' openTargetUser='+openTargetUser); 
        
        if (okay) {
            TaskHelper.SKIP_TRIGGERS=true;
            OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
            UserTransferQueueable.QueryWrapper[] queryWraps = new UserTransferQueueable.QueryWrapper[]{};
                
            if (closedTargetUser != null) {
                Map<String,String> activityQueryMap = getActivityQueryMap(userTransfer.Existing_User__c, userTransfer.Effective_Date__c, false, userTransfer.IsExistingSales__c, userTransfer.Transfer_Type__c);
                okay = cycleThroughMap(userTransfer, activityQueryMap, closedTargetUser.Id, queryWraps);
            }
            if (okay && openTargetUser != null) {
                Map<String,String> activityQueryMap = getActivityQueryMap(userTransfer.Existing_User__c, userTransfer.Effective_Date__c, true, userTransfer.IsExistingSales__c, userTransfer.Transfer_Type__c);
                okay = cycleThroughMap(userTransfer, activityQueryMap, openTargetUser.Id, queryWraps);
            } // if (okay && openTargetUser
            // do we have queries to execute? 
            hasQueriesToTransfer = !queryWraps.isEmpty();
            
            System.debug('transferActivity USE_QUEUEABLE='+USE_QUEUEABLE+' queryWraps.size: '+queryWraps.size()+' hasQueriesToTransfer: '+hasQueriesToTransfer);
            if (USE_QUEUEABLE && !queryWraps.isEmpty()) {
                UserTransferQueueable.addToProcessTracker(userTransfer, 'Setting the queueable job');
                //update userTransfer;
                // enqueue the job - can't chain the jobs from tests
                UserTransferQueueable utq = new UserTransferQueueable(queryWraps, userTransfer);
                System.enqueueJob(utq);
            }
        } // if (okay)
        return okay;
    } // transferActivity
    
    public static Boolean USER_TRANSFER_TRIGGER_EXECUTING=false;
    
    // the size of the comments field
    public static final Integer COMMENTS_SIZE = User_Transfer__c.Comments__c.getDescribe().getLength();
    
    public static Boolean addToComments(User_Transfer__c userTransfer, String p_comments) {
        system.debug('addToComments begin'); 
        Boolean commentsLessThanSize = true;
        if (String.isNotBlank(p_comments)) {
            String comments = (p_comments + (String.isNotBlank(userTransfer.Comments__c) ?  '\n'+userTransfer.Comments__c : '')).left(COMMENTS_SIZE);
            system.debug('addToComments COMMENTS_SIZE: '+COMMENTS_SIZE+' comments: '+comments); 
            //commentsLessThanSize = comments.length() > COMMENTS_SIZE;
            userTransfer.Comments__c = comments.left(COMMENTS_SIZE);
        }
        return commentsLessThanSize;
    } // addToComments
    
    public class ResultCount {
        public Integer nbrSuccess = 0;
        public Integer nbrFailure = 0;
        public Integer nbrRecs {
            get { return (nbrSuccess + nbrFailure); }
        }
        public List<OutputMsg> errorMsgs = new List<OutputMsg>();
    } // class resultCount
    
    private static Boolean cycleThroughMap(User_Transfer__c userTransfer, Map<String,String> activityQueryMap, Id transferToId, UserTransferQueueable.QueryWrapper[] queryWraps) {
        system.debug('cycleThroughMap begin'); 
        Boolean okay = true;
        for (String objectType : activityQueryMap.keySet()) {
            String query = activityQueryMap.get(objectType);
            if (USE_QUEUEABLE) {
                queryWraps.add(new UserTransferQueueable.QueryWrapper(objectType, query, transferToId));
            } else if (!executeQuery(query, objectType, transferToId, userTransfer)) {
                okay = false;
                break;
            } // if (!updateOwner
            if (!USE_QUEUEABLE) {
                update userTransfer;
            }
        } // for (String objectType
        return okay;
    } // cycleThroughMap
    
    // execute the query to get activity to move
    private static Boolean executeQuery(String query, String objectType, Id newOwnerId, User_Transfer__c userTransfer) {
        // limit result set based on Limits
        Integer maxRows = ((Limits.getLimitDmlRows() - (Limits.getDMLRows()+1))/2);
        ResultCount rc = new ResultCount();
        UserTransferQueueable.addToProcessTracker(userTransfer, 'Start query for '+objectType);
        query += ' limit '+maxRows;
        for (List<SObject> objects : Database.query(query)) {
            for (SObject so : objects) {
                so.put('OwnerId',newOwnerId);
            } // for
            updateData(objects, rc);
        } // for
        UserTransferQueueable.addToProcessTracker(userTransfer, 'End query for '+objectType+' success='+rc.nbrSuccess+' Failure='+rc.nbrFailure);
        addToCounter(userTransfer, objectType,rc);
        return checkResult(userTransfer, maxRows, rc.nbrRecs);
    } // executeQuery
    
    private static Boolean updateData(List<SObject> objects, ResultCount rc) {
        Boolean allOkay = true;
        List<Database.SaveResult> uResults = Database.update(objects,false);
        for (Integer cnt=0; cnt<uResults.size(); cnt++) {
            Database.SaveResult result = uResults.get(cnt);
            if (!result.isSuccess()) {
                //SObject obj = objects.get(cnt);
                allOkay = logUpdateError(objects.get(cnt),result,rc);
                //rc.nbrFailure++;
                //System.debug('Logging error for id='+result.getId());
                //if (rc.errorMsgs.size() < 300) {
                //   rc.errorMsgs.add(new OutputMsg(obj.Id,result));
                //}
            } else {
                rc.nbrSuccess++;
            }
        } // for
        return allOkay;   
    } // updateData
    
    public static Boolean logUpdateError(SObject obj, Database.SaveResult result, ResultCount rc) {
        rc.nbrFailure++;
        System.debug('Logging error for id='+result.getId());
        if (rc.errorMsgs.size() < 300) {
            rc.errorMsgs.add(new OutputMsg(obj.Id,result));
        }
        return false;
    } // logUpdateError
    
    public class OutputMsg {
        public OutputMsg(Id recId, Database.SaveResult result) {
            
            recordId = recId; 
            msg = '';
            if (result != null) {
                for (Database.Error err : result.getErrors()) {
                    msg += err.getMessage();
                }
            } // if (result != null
        } // OutputMsg
        
        public Id recordId{get;private set;}
        
        public String msg{get; private set;}
    } // class OutputMsg
    
    private static Boolean checkResult(User_Transfer__c userTransfer, Integer maxRows, Integer resultsCounter) {
        if (resultsCounter == maxRows) {
            // hit the maximum allowed rows returned. False is returned so the operation will
            // be attempted again.
            // add a comment to the userTransfer that we hit the limit
            String comments = ('Limits reached on data transfer.'+(String.isBlank(userTransfer.Comments__c) ? '' : '\n'+userTransfer.Comments__c));
            addToComments(userTransfer,comments);
            return false;
        } // if (resultsCounter
        return true;
    } // checkResult
    
    // Add the results to the query.
    public static void addToCounter(User_Transfer__c userTransfer, String objectType, ResultCount rc) {
        if (objectType == ObjectHelper.OBJECT_TASK) {
            userTransfer.Nbr_Tasks__c += rc.nbrSuccess;
            userTransfer.Nbr_Tasks_Failed__c += rc.nbrFailure;
        } else if (objectType == ObjectHelper.OBJECT_OPPTY) {
            userTransfer.Nbr_Opptys__c += rc.nbrSuccess;
            userTransfer.Nbr_Opptys_Failed__c += rc.nbrFailure;
        } else if (objectType == ObjectHelper.OBJECT_CASE) {
            userTransfer.Nbr_Cases__c += rc.nbrSuccess;
            userTransfer.Nbr_Cases_Failed__c += rc.nbrFailure;
        } else if (objectType == ObjectHelper.OBJECT_EVENT) {
            userTransfer.Nbr_Events__c += rc.nbrSuccess;
            userTransfer.Nbr_Events_Failed__c += rc.nbrFailure;
        }
        
        if (!rc.errorMsgs.isEmpty()) {
            // attach the errors to the userTransfer record
            String errorOutput = 'Id,Msg';
            for (OutputMsg om : rc.errorMsgs) {
                errorOutput += '\n'+om.recordId+','+om.msg;
            }
            Attachment attach = new Attachment();
            attach.Body = Blob.valueOf(errorOutput);  
            attach.Name = objectType + '-'+Datetime.now().format('yyyyMMddHHmmss');          
            attach.ParentID = userTransfer.id;
            insert attach;
        } // if (!rc.errorMsgs.isEmpty
    } // addToCounter
    
    @future(callout=true)
    public static void processUserTxfers(String sessionId, Id[] userTransferIds) {
        User_Transfer__c[] userTransfers = getUserTransfers(userTransferIds);
        User_Transfer__c[] checkActivityTransfers = new User_Transfer__c[]{};
        Id[] updatedUserIds = new Id[]{};
               
        for (User_Transfer__c userTransfer : userTransfers) {                       
            HttpRequest req = new HttpRequest();
            Boolean okay = true;
            req.setEndpoint('https://'+URL.getSalesforceBaseUrl().getHost()+'/services/apexrest/updateTransferTxfer/');
            req.setMethod('POST');
            String body = '{"userTransferId":"'+userTransfer.Id+'"}';
            req.setBody(body);
            req.setHeader('Authorization', 'Bearer '+ sessionId);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);
            Http http = new Http();
            String returnValue = null;
            if (!test.isRunningTest()){
                System.debug('processUserTxfers performing rest callout');
                try {
                    HTTPResponse res = http.send(req);
                    System.debug('processUserTxfers res='+res+' body='+res.getBody());
                    returnValue = (res.getBody() != null ? res.getBody().replace('"','') : '');
                    okay = (res.getStatusCode() == 200);
                    if (okay) {
                        if (userTransfer.Transfer_Type__c == 'Update User Role Only'){
                            // set to Complete, there is no transfer activity to check
                            userTransfer.Status__c=STATUS_COMPLETE;
                            updatedUserIds.add(userTransfer.Existing_User__c);                                                        
                        }
                        else if(returnValue.startsWith('005')){
                        	if (!addToComments(userTransfer,'returned Id='+returnValue)) {
                            // add the return value as an attachment so we don't lose anything                                        
                        	}
                            if(userTransfer.Transfer_Type__c == 'Transfer User Basic' || userTransfer.Transfer_Type__c == null){
                                // set to Complete, there is no transfer activity to check
                                userTransfer.Status__c=STATUS_COMPLETE;
                                userTransfer.New_User__c=(Id)returnValue;
                                userTransfer.GrpMembershipCopied__c = true;
                                updatedUserIds.add(userTransfer.New_User__c);
                                updatedUserIds.add(userTransfer.Existing_User__c);
                            }                       
                            else {
                                // set to transfer activity so it can check for it.
                                userTransfer.Status__c=STATUS_ACT_TRANSFER;
                                userTransfer.New_User__c=(Id)returnValue;
                                userTransfer.GrpMembershipCopied__c = true;
                                updatedUserIds.add(userTransfer.New_User__c);
                                updatedUserIds.add(userTransfer.Existing_User__c);
                                //checkActivityTransfers.add(userTransfer);
                            } // if(userTransfer.Transfer_Type__c    
                        } 
                        else {
                        	okay = false;
                        }// if(userTransfer.Transfer_Type__c
                    } // if okay
                } catch (Exception ex) {
                    okay = false;
                    ErrorLog.logError('ManageUserHelper', 'processUserTxfers', 'Sending message', userTransferIds[0], ex,null, true);
                    addToComments(userTransfer,ex.getStackTraceString());
                } // try
                } // if (!test.isRunningTest
                
                System.debug('processUserTxfers okay: '+okay+' userTransfer.Status__c: '+userTransfer.Status__c);
                if (!okay) {
                    addToComments(userTransfer,returnValue);
                    userTransfer.Status__c=STATUS_TXFER_ERROR;
                } // !okay                      
        } // for (Id userTransferId
        
        if (!userTransfers.isEmpty()) {
            update userTransfers;  
            system.debug('processUserTxfers after update userTransfers'); 
        }
        
        if (!updatedUserIds.isEmpty()) {
            UserRoleUpdateREST.doPost(updatedUserIds);	
            system.debug('processUserTxfers after UserRoleUpdateREST'); 
        }
        
       	System.debug('processUserTxfers checkActivityTransfers.size: '+checkActivityTransfers.size());
        checkTransferActivity(sessionId, checkActivityTransfers);
        system.debug('processUserTxfers after checkTransferActivity');    
               
    } // processUserTxfers
   
    
    public static final Integer PROCESS_TRACKER_SIZE = User_Transfer__c.ProcessTracker__c.getDescribe().getLength();
    
    public static void addToProcessTracker(User_Transfer__c userTransfer, String notesToAdd) {
        StringHelper.addNotesToField(userTransfer, 'ProcessNotes__c', PROCESS_TRACKER_SIZE, notesToAdd, true);
    } // addToProcessTracker
    
} // class ManageUserHelper