/** Queueable class used for creating/setting up a user record
 * 
 * History
 * -------
   04/24/2024 Dan Carmen        Created

 
 */
public class NewUserQueueable implements Queueable, Finalizer { 
   
   public static final String MODE_USR='ProcessUser';
   public static final String MODE_REQ='SaveRequest';
   public String mode=MODE_USR;
   
   public Id[] requestIds;
   public NewUserQueueable(Id[] p_requestIds) {
      mode=MODE_USR;
      requestIds = p_requestIds;
   } // NewUserQueueable
   
   //public NewUserQueueable(AddUserController p_auc, Id[] p_requestIds) {
   //   mode=MODE_REQ;
   //   auc=p_auc;
   //   requestIds = p_requestIds;
   //} // NewUserQueueable
    
   public Id reqId;
   public AddUserController auc;
    
   public void execute(QueueableContext context) {
      if (mode == MODE_USR) {
         reqId = (requestIds != null && !requestIds.isEmpty() ? requestIds.remove(0) : null);
         if (reqId != null) {
            System.attachFinalizer(this);
            auc = new AddUserController();
            auc.clearSearchVariables();
            auc.setupRequest(reqId);
         
            Boolean userCreated = auc.newNur.User__r != null;
            System.debug('userCreated='+userCreated);
            StringHelper.addToProcessNotes(auc.newUser,'NewUserQueueable userCreated='+userCreated);
            if (userCreated && auc.saveNewUser(auc.newNur)) {
               //numberCreated++;
            }
            // send back the request
            NewUserHelper.ReqWrap rWrap = new NewUserHelper.ReqWrap();
            rWrap.req = new NewUserRequest__c(Id=auc.newNur.Id);
            rWrap.req.Approver_Notes__c = auc.newNur.Approver_Notes__c;
            rWrap.req.ProcessNotes__c = auc.newNur.ProcessNotes__c;
            rWrap.req.Request_Complete__c = auc.newNur.Request_Complete__c;
            rWrap.req.Status__c = auc.newNur.Status__c;
            rWrap.req.User__c = auc.newNur.User__c;
            rWrap.newLicenseRequests = auc.newLicenseRequests;
            
            if (NewUserHelper.userRequestEmail != 'NoMail') {
               String emailBody = json.serialize(rWrap).replace('number_Z','number')+NewUserHelper.emailTail;
               Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
               emailToSend.setSaveAsActivity(false);
               emailToSend.setToAddresses(new String[]{NewUserHelper.userRequestEmail});
               emailToSend.setSubject(NewUserHelper.SUBJECT_SAVE);
               emailToSend.setPlainTextBody(emailBody);
               Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emailToSend}, false);
            }
            
            NewUserQueueable nuq = new NewUserQueueable(requestIds);
            if (!Test.isRunningTest() && requestIds != null && !requestIds.isEmpty()) {
               System.debug('execute relaunching queueable');
               // relaunch the queueable to save the request
               NewUserQueueable.checkLaunchQueueable(nuq);
            }

         } // if (reqId != null
     /*    
     } else if (mode == MODE_REQ) {
         if (auc != null) {
            auc.saveRequest(auc.newNur);
         }
         NewUserQueueable nuq = new NewUserQueueable(requestIds);
         if (!Test.isRunningTest() && requestIds != null && !requestIds.isEmpty()) {
            NewUserQueueable.checkLaunchQueueable(nuq);
         }
      */
     }
      
   } // execute
       
   public static void checkLaunchQueueable(NewUserQueueable nuq) {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('NewUserQueueable');
      if (abc != null && abc.Active__c && nuq != null && (nuq.auc != null || !nuq.requestIds.isEmpty())) {
         System.debug('checkLaunchQueueable enqueuing new job');
         System.enqueueJob(nuq);
      }
   } // checkLaunchQueueable

    public void execute(FinalizerContext ctx) {
        String parentJobId = ctx.getAsyncApexJobId();
        System.debug('Begin: executing finalizer attached to queueable job: ' + parentJobId);
        System.debug('execute finalizer auc='+(auc != null));
        if (ctx.getResult() == ParentJobResult.SUCCESS) {
           //auc.saveRequest(auc.newNur);
        } else {
            //System.debug('Parent queueable job [' + parentJobId + '] failed due to unhandled exception: ' + ctx.getException().getMessage());
           ErrorLog.logError('NewUserQueueable', 'Unhandled Exception', 'Unhandled Exception ', reqId, ctx.getException(), null, true);
        }
    } // execute FinalizerContext

} // class NewUserQueueable