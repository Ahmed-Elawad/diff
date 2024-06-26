/* 
 * The methods used for assisting with forecast sharing. Moved from UserHelper to lessen impact since this feature was
 * 	a pilot during development.  Leaving in UserHelper would make it difficult to make changes to that class in a sbx without the pilot.
 *
 * History
 * -------
 * 10/31/2017	Jake Hinds   Created
 *
 *
 */ 
public with sharing class UserForecastSharing {
    public static void setForecastSharing(Map<Id,User> userMap){
   		//delete old forecasting share records since the user's role changed.  Does not apply for new users
   		Id[] fsToDelete = new Id[]{};
   		for(ForecastingShare fs: [SELECT Id FROM ForecastingShare WHERE UserOrGroupId in :userMap.keyset()]){
   			fsToDelete.add(fs.Id);
   		}
   		
   		//ForecastingShare[] fsToCreate = new ForecastingShare[]{};
   		Map<Id,Id> fsToCreate = new Map<Id,Id>();
   		
   		for(User u: userMap.values()){
   			//if user is a dsa/dsm/zsa/zsm, share their roles' forecast with them
   			system.debug('JSH JOB NAME'+u.Job_Name__c);
   			if(u.Job_Name__c == UserHelper.JOB_DSA || u.Job_Name__c == UserHelper.JOB_DSM || u.Job_Name__c == UserHelper.JOB_ZSA || u.Job_Name__c == UserHelper.JOB_ZSM){
   				//ForecastingShare fsu = new ForecastingShare(SharedForecastManagerRoleId = u.UserRoleId, UserOrGroupId = u.Id);
   				fsToCreate.put(u.Id,u.UserRoleId);
   			}
   		}
   		
   		if(!System.isFuture() && !System.isBatch() && !Test.isRunningTest() && (!fsToDelete.isEmpty() || !fsToCreate.isEmpty())){
   			system.debug('processForecastSharing'+ fsToCreate);
	        handleForecastSharingFuture(UserInfo.getSessionId(),fsToCreate,fsToDelete);
   		}
   }
   
   @future(callout=true)
   public static void handleForecastSharingFuture(String sessionId,Map<Id,Id> roleByUserIdMap,Id[]fsToDelete){ 
   		HttpRequest req = new HttpRequest();
        Boolean okay = true;
        //using the composite batch url allows us to specify multiple operations in a single json structure
        req.setEndpoint('https://'+URL.getSalesforceBaseUrl().getHost()+'/services/data/v41.0/composite/batch');
        //set as post, needs to be post to utilize body
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer '+ sessionId);
        req.setHeader('Content-Type', 'application/json');
	    req.setTimeout(120000);
	    //start json string
	    String body = '{"batchRequests" : [';
	    //iterate over all of the sharing records we need to create and build json
	    for(Id uId:roleByUserIdMap.keySet()){
	    	body+='{"method" : "POST", "url" : "v41.0/sobjects/ForecastingShare","richInput" : {"UserOrGroupId":"'+uId+'","SharedForecastManagerRoleId":"'+roleByUserIdMap.get(uId)+'"}},';
	    }
        //remove extra comma at the end of the list of records we just built
	    for(Id fsId:fsToDelete){
			body+='{"method" : "DELETE", "url" : "v41.0/sobjects/ForecastingShare/'+fsId+'"},';
		}
	    //remove extra comma at the end of the list of records we just built
	    body = body.removeEnd(',');
	    //close json string
	    body += ']}';
	    req.setBody(body);
	    system.debug('POST BODY'+body);
	    Http http = new Http();
        String returnValue = null;
        System.debug('createForecastSharing performing rest callout');
        try {
           HTTPResponse res = http.send(req);
           System.debug('createForecastSharing res='+res+' body='+res.getBody());
           returnValue = (res.getBody() != null ? res.getBody().replace('"','') : '');
           okay = (res.getStatusCode() >=200 && res.getStatusCode()< 300);
           if (okay) {
           } else {
           		//not sure what the error log record ID should be, if one record in the batch fails, the entire thing will return an error code of failure
           		//even if all of the other records pass
           		ErrorLog.logError('UserHelper', 'createForecastSharing', 'Sending message','specific ID goes here','',null, true);
           }
        } catch (Exception ex) {
           okay = false;
           //not sure what the error log record ID should be, if one record in the batch fails, the entire thing will return an error code of failure
           //even if all of the other records pass
           ErrorLog.logError('UserHelper', 'createForecastSharing', 'Sending message','specific ID goes here', ex,null, true);
        }
   }
}