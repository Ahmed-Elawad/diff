/* 
 * Execute the transfer of activity in a queueable job.
 *
 * History
 * -------
 * 02/07/2018 Dan Carmen       Created
   08/20/2018 Dan Carmen       Added in a save for the error logs.

*/
public with sharing class UserTransferQueueable implements Queueable {
    
   public static Integer QUERY_LIMIT=500;
   
   /*
   public Map<String,String> queryMap;
   public Id newOwnerId;
   */
   public User_Transfer__c userTransfer;
   
   public QueryWrapper[] queryWraps = null;
   
   public class QueryWrapper {
      public QueryWrapper(String p_objectName, String p_query, Id p_newOwnerId) {
         objectName = p_objectName;
         query = p_query;
         newOwnerId = p_newOwnerId;
      }
      public String objectName;
      public String query;
      public Id newOwnerId;
   } // class QueryWrapper
   
   // generic constructor
   public UserTransferQueueable() {
      
   }
    
   public UserTransferQueueable(QueryWrapper[] p_queryWraps, User_Transfer__c p_userTransfer) {
      queryWraps = p_queryWraps;
      userTransfer = p_userTransfer;
   } // UserTransferQueueable
   
   /*
   public UserTransferQueueable(Map<String,String> p_queryMap, Id p_newOwnerId, User_Transfer__c p_userTransfer) {
      queryMap = p_queryMap;
      newOwnerId = p_newOwnerId;
      userTransfer = p_userTransfer;
   } // UserTransferQueueable
   */
   public String successFld = null;
   public String failFld = null;
   
   public void setFlds(String objectName) {
      if (objectName == ObjectHelper.OBJECT_OPPTY) {
         successFld = 'Nbr_Opptys__c';
         failFld = 'Nbr_Opptys_Failed__c';
      } else if (objectName == ObjectHelper.OBJECT_TASK) {
         successFld = 'Nbr_Tasks__c';
         failFld = 'Nbr_Tasks_Failed__c';
      } else if (objectName == ObjectHelper.OBJECT_CASE) {
         successFld = 'Nbr_Cases__c';
         failFld = 'Nbr_Cases_Failed__c';
      } else if (objectName == ObjectHelper.OBJECT_EVENT) {
         successFld = 'Nbr_Events__c';
         failFld = 'Nbr_Events_Failed__c';
      }
   } // setFlds
    
   public void execute(QueueableContext context) {
      TaskHelper.SKIP_TRIGGERS=true;
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;

      // pull the first query out of the stack, add a limit to it.
      QueryWrapper queryWrap = queryWraps.remove(0);
      /*
      String[] keys = new String[]{};
      keys.addAll(queryMap.keySet());
      String objectName = keys[0];
      String query = queryMap.remove(objectName);
      */
      String objectName = queryWrap.objectName;
      String query = queryWrap.query;
      Id newOwnerId = queryWrap.newOwnerId;
      
      System.debug('UserTransferQueueable objectName='+objectName+' limit='+QUERY_LIMIT+' query='+query);
      if (String.isNotBlank(objectName) && String.isNotBlank(query)) {
         setFlds(objectName);
         Integer recCount = 0;
         Integer nbrSuccess = 0;
         Integer nbrFailure = 0;
         String queryWithLimit = query + ' limit '+QUERY_LIMIT;
         for (SObject[] recs : Database.query(queryWithLimit)) {
            recCount += recs.size();
            for (SObject rec : recs) {
               rec.put('OwnerId',newOwnerId);
            }
            DmlHelper.performDML2(recs, DmlHelper.DML_UPDATE, 'UserTransferQueueable', 'execute', 'updating recs for '+objectName, false);
            if (DmlHelper.performDmlResult != null) {
               nbrSuccess += DmlHelper.performDmlResult.nbrSuccess;
               nbrFailure += DmlHelper.performDmlResult.nbrError;
            }
         } // for (SObject[] recs
         // update the value on the user transfer record
         addToField(userTransfer, successFld, nbrSuccess);
         addToField(userTransfer, failFld, nbrFailure);
         
         String trackerMsg = objectName+' had '+recCount+' records, success='+nbrSuccess+', failure='+nbrFailure;
         
         if (recCount >= QUERY_LIMIT) {
            // if we hit the limit, add back into the collection
            queryWraps.add(queryWrap);
            //queryMap.put(objectName, query);
            trackerMsg += ' Query for '+objectName+' is added back to queue.';
         }
         addToProcessTracker(userTransfer, trackerMsg);
      } // if (String.isNotBlank(fieldName)
      
      // check to see if we can continue
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('UserTransferQueueable');

      // save the status of the user transfer record.
      Boolean areWeDone = queryWraps.isEmpty();
      ErrorLog.checkSave();
      // so the trigger doesn't fire.
      ManageUserHelper.USER_TRANSFER_TRIGGER_EXECUTING = true;
      userTransfer.Status__c = (areWeDone ? ManageUserHelper.STATUS_COMPLETE : ManageUserHelper.STATUS_ACT_TRANSFER);
      update userTransfer;
      
      if (areWeDone) {
         ManageUserHelper.generateEmails(new User_Transfer__c[]{userTransfer});
      } else if (abc != null && abc.Active__c && !Test.isRunningTest()) {
         // re-enqueue the job - can't chain the jobs from tests
         UserTransferQueueable utq = new UserTransferQueueable(queryWraps, userTransfer);
         System.enqueueJob(utq);
      }
      
   } // execute
   
   public static void addToField(SObject rec, String fldName, Integer nbrToAdd) {
      if (rec != null && String.IsNotBlank(fldName)) {
         Object curValue = rec.get(fldName);
         Integer newValue = (curValue != null ? Integer.valueOf(curValue) : 0) + nbrToAdd;
         rec.put(fldName, newValue);
      }
   } // addToField
   
   
   public static final Integer PROCESS_TRACKER_SIZE = User_Transfer__c.ProcessTracker__c.getDescribe().getLength();

   public static void addToProcessTracker(User_Transfer__c p_userTransfer, String textToAdd) {
      StringHelper.addNotesToField(p_userTransfer, 'ProcessTracker__c', PROCESS_TRACKER_SIZE, textToAdd, true);
   } // addToProcessTracker
   
} // class UserTransferQueueable