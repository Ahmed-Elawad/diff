/*
  04/26/2017 Josh Cartwright        created to update Accounts with Any POP, FSA, or 401k from the Client EDW Info Object
  07/31/2017 Dan Carmen             Add process tracker

*/

public with sharing class ClientEDWInfoHelper {

   public static Boolean TRIGGER_ALREADY_RAN=false;

   // if we want to skip the after trigger actions
   public static Boolean SKIP_TRIGGER=Label.ClientEdwInfo_SkipTrigger == 'Y';
   
   public static Id[] acctIdsToProcess = new Id[]{}; 
   
   //public static Map<Integer,ClientEdwInfo__c[]> searchAcctMap = new Map<Integer,ClientEdwInfo__c[]>();
   
   public static void processAllBefore(ClientEDWInfo__c[] recs, Map<Id,ClientEDWInfo__c> oldRecMap) {
      for (ClientEDWInfo__c rec : recs) {
         ClientEDWInfo__c oldRec = (oldRecMap != null ? oldRecMap.get(rec.Id) : null);
         checkBefore(rec, oldRec);
      } // for (ClientEDWInfo__c rec
   } // processAllBefore

   public static void checkBefore(ClientEDWInfo__c rec, ClientEDWInfo__c oldRec) {
      if (oldRec != null && rec.BisId__c != oldRec.BisId__c && rec.Account__c != null) {
         System.debug('checkBefore '+rec.Name+' bis id changed set account to null');
         addToProcessTracker(rec, 'Clearing Account__c due to bis id change');
         rec.Account__c = null;
      }
      if(oldRec == null || rec.BisId__c != oldRec.BisId__c || rec.BranchNumber__c != oldRec.BranchNumber__c 
          || rec.ClientNumber__c != oldRec.ClientNumber__c || rec.EndDate__c != oldRec.EndDate__c 
          || rec.StartDate__c != oldRec.StartDate__c || rec.ReProcess__c )
         {
         System.debug('checkBefore '+rec.Name+' insert or value changed set processed to false');
         addToProcessTracker(rec, 'Value changed set Processed to False');
         rec.Processed__c = false; 
         rec.ReProcess__c = false;
      }//if
      
      rec.Bad_BIS_ID__c = String.isBlank(rec.BisId__c);
      if (rec.Bad_BIS_ID__c) {
         rec.Account__c = null;
         rec.Processed__c = true; 
         addToProcessTracker(rec, 'No Bis Id');
         System.debug('checkBefore '+rec.Name+' bad bis id');
      }
      
      if (!rec.Bad_BIS_ID__c && rec.Account__c == null) {
         try {
            // try to convert to a valid bis id
            Integer bisId = Integer.valueOf(rec.BisId__c);
            //ClientEdwInfo__c[] edwList = (searchAcctMap.containsKey(bisId) ? searchAcctMap.get(bisId) : new ClientEdwInfo__c[]{});
            //edwList.add(rec);
            //searchAcctMap.put(bisId, edwList);
         } catch (Exception e) {
            rec.Bad_BIS_ID__c = true;
            rec.Processed__c = true;
            addToProcessTracker(rec, 'Could not convert Bis Id to a number');
         }
      }
   } // checkBefore
   
   /*
   public static void processBefore() {
      if (!searchAcctMap.isEmpty()) {
         list<Account> acctList = [select id, Bis_ID__c from Account where Bis_ID__c in: searchAcctMap.keyset()];
         System.debug('processBefore acctList='+acctList.size());
         for (Account acct : acctList) {
            ClientEdwInfo__c[] edwList = searchAcctMap.remove(Integer.valueOf(acct.Bis_ID__c));
            System.debug('processBefore bisId='+acct.Bis_ID__c+' edwList='+(edwList != null ? edwList.size() : -1));
            if (edwList != null) {
               for (ClientEdwInfo__c edw : edwList) {
                  System.debug('processBefore set acct id for '+edw.Name);
                  edw.Account__c = acct.Id;
                  edw.Processed__c = false;
                  addToProcessTracker(edw, 'Found Account set Id to '+acct.Id);
               }
            }
         } // for (Account acct : acctList
         
         for (ClientEdwInfo__c[] edwList : searchAcctMap.values()) {
            for (ClientEdwInfo__c edw : edwList) {
               edw.Bad_BIS_ID__c = true;
               edw.Processed__c = true;
               addToProcessTracker(edw, 'Could not find a matching Account for '+edw.BisId__c);
            }
         } // for (ClientEdwInfo__c[] edwList
      } // if (!searchAcctMap.isEmpty
   } // processBefore
   */
   
   public static void processAllAfter(ClientEDWInfo__c[] recs, Map<Id,ClientEDWInfo__c> oldRecMap) {
      UserHelper.setRunningUserAttributes();
      // if the SKIP_TRIGGER flag is set to true, then don't process the records in the after as Relational Junction
      Boolean doNotProcess = SKIP_TRIGGER && UserHelper.runningUserIsRelationalJunction;
      System.debug('processAllAfter doNotProcess='+doNotProcess+' SKIP_TRIGGER='+SKIP_TRIGGER);
      if (!doNotProcess) {
         Id[] clientEdwIds = new Id[]{};
         for (ClientEDWInfo__c cei : recs) {
            if (!cei.Processed__c) {
               clientEdwIds.add(cei.Id);
            }
         }
         processAfter(clientEdwIds);
      } // if (!doNotProcess
   } // processAllAfter
/*
   public static void checkAfter(ClientEDWInfo__c rec, ClientEDWInfo__c oldRec) {
      UserHelper.setRunningUserAttributes();
      if (!UserHelper.runningUserIsRelationalJunction) {
         if(!rec.Processed__c == false){
            acctIdsToProcess.add(rec.Account__c);
         }//if
      }
   } // checkAfter
  */
  
   public static Boolean SKIP_FUTURE=true; 
   public static void processAfter(Id[] clientEdwIds) {
      System.debug('processAfter acctIdsToProcess='+acctIdsToProcess);
      if (!clientEdwIds.isEmpty()) {
         if (SKIP_FUTURE || System.isFuture() || System.isBatch()) {
            processRecordsNow(clientEdwIds);
         } else {
            processRecordsFuture(clientEdwIds);
         }
      }
   } // processAfter

   @future
   public static void processRecordsFuture(Id[] clientEdwIds) {
      processRecordsNow(clientEdwIds);
   } // processRecordsFuture
   
   public static void processRecordsNow(Id[] clientEdwIds) {
      // select the list of passed in records - see if any need the account set
      Set<Id> acctIdSet = checkForAccounts(clientEdwIds);
      System.debug('processRecordsNow clientEdwIds='+clientEdwIds.size()+' acctIdSet='+acctIdSet.size());
      
      list<Account> acctList = [select id, Name, Any_401k__c, Any_FSA__c,Any_Pop__c, Bis_ID__c
                                      ,(select Account__c, id, EndDate__c, StartDate__c, Name
                                              ,Any401k__c, AnyFSA__c, AnyPOP__c
                                              ,Processed__c, ProcessTracker__c
                                          from ClientEDWInfos__r
                                          order by EndDate__c desc NULLS FIRST) 
                                    from Account where Id in: acctIdSet];
              
      Account[] acctsToUpdate = new Account[]{};
      ClientEdwInfo__c[] edwInfosToUpdate = new ClientEdwInfo__c[]{};
      
      Map<Id, ClientEdwInfo__c> edwToUpdateMap = new Map<Id, ClientEdwInfo__c>();
      Map<Id, Account> acctUpdateMap = new Map<Id, Account>();
                            
      for(account act :acctList){
         ClientEdwInfo__c edw401k = null;
         ClientEdwInfo__c edwFSA = null;
         ClientEdwInfo__c edwPOP = null;
         
         for (ClientEDWInfo__c edw: act.ClientEDWInfos__r) {
            System.debug('processRecordsNow edw='+edw);
            if (edw.Any401k__c && edw401k == null) {
               edw401k = edw;
            } else if (edw.AnyFSA__c && edwFSA == null) {
               edwFSA = edw;
            } else if (edw.AnyPOP__c && edwPOP == null) {
               edwPOP = edw;
            }
            //if (!edw.Processed__c) {
            //   edw.Processed__c =true;
            //   edwToUpdateMap.put(edw.Id, edw); 
            //} 
         } // for (ClientEDWInfo__c edw
         
         checkAccountField(act, 'Any_401k__c', edw401k, edwToUpdateMap, acctUpdateMap);
         checkAccountField(act, 'Any_FSA__c', edwFSA, edwToUpdateMap, acctUpdateMap);
         checkAccountField(act, 'Any_Pop__c', edwPOP, edwToUpdateMap, acctUpdateMap);
         
         /*
         boolean any401k = false; 
         boolean anyFSA = false;
         boolean anyPOP = false; 
            
         for(ClientEDWInfo__c edw: act.ClientEDWInfos__r){
            System.debug('processRecordsNow edw='+edw.Name+' any401k__c='+edw.any401k__c+' anyFSA__c='+edw.anyFSA__c+' anyPOP__c='+edw.anyPOP__c);
            any401k = (any401k || edw.any401k__c);
            anyFSA = (anyFSA || edw.anyFSA__c);
            anyPOP = (anyPOP || edw.anyPOP__c);
            
            if (!edw.Processed__c) {
               edw.Processed__c =true;
               edwInfosToUpdate.add(edw); 
            } 
         }//for // for(ClientEDWInfo__c edw
         // check if values change

      
         System.debug('processRecordsNow acct='+act.Name+' any401k='+any401k+' anyFSA='+anyFSA+' anyPOP='+anyPOP);
      
         if (act.Any_401k__c != any401k ||act.Any_FSA__c != anyFSA ||act.Any_POP__c != anyPOP) {
            act.Any_401k__c = any401k;
            act.Any_FSA__c = anyFSA;
            act.Any_Pop__c = anyPOP;
         
            acctsToUpdate.add(act);
         } // if 
         */
      } //for(account act
      
      if (!acctUpdateMap.isEmpty()) {
         //update acctUpdateMap.values();
         DmlHelper.performDML2(acctUpdateMap.values(), DmlHelper.DML_UPDATE, 'ClientEDWInfo', 'processRecordsNow', 'Updating Accounts with Prod Info', false);
      }
      
      if (!edwToUpdateMap.isEmpty()) {
         update edwToUpdateMap.values();
         DmlHelper.performDML2(edwToUpdateMap.values(), DmlHelper.DML_UPDATE, 'ClientEDWInfo', 'processRecordsNow', 'Updating Accounts with Prod Info', false);
      }
      
      
      
      /*
      if(!acctsToUpdate.isEmpty()){
         update acctsToUpdate; 
      }//if 

      if (!edwInfosToUpdate.isEmpty()) {
         update edwInfosToUpdate;
      }
      */ 
   } // processRecordsNow
   
   // check if the account is populated on the ClientEdwInfo__c record. Try to find if not. 
   // return a set of all the account ids found
   public static Set<Id> checkForAccounts(Id[] clientEdwIds) {
      Set<Id> acctIdSet = new Set<Id>();
      ClientEdwInfo__c[] edwInfos = [Select id, Name, Account__c, BisId__c, Bad_BIS_ID__c
                                           ,Processed__c, ProcessTracker__c
                                       From ClientEdwInfo__c
                                      Where Id in :clientEdwIds];
      System.debug('checkForAccounts edwInfos='+edwInfos.size());
      
      Map<Integer, ClientEdwInfo__c[]> acctSearchMap = new Map<Integer, ClientEdwInfo__c[]>();
      for (ClientEdwInfo__c edwInfo : edwInfos) {
         // mark all records as processed
         edwInfo.Processed__c = true;
         if (edwInfo.Account__c != null) {
            acctIdSet.add(edwInfo.Account__c);
         } else {
            Integer bisId = Integer.valueOf(edwInfo.BisId__c);
            if (bisId != null) {
               ClientEdwInfo__c[] searchRecs = (acctSearchMap.containsKey(bisId) ? acctSearchMap.get(bisId) : new ClientEdwInfo__c[]{});
               searchRecs.add(edwInfo);
               acctSearchMap.put(bisId, searchRecs);
            }
         }
      } // for (ClientEdwInfo__c edwInfo
      
      if (!acctSearchMap.isEmpty()) {
         ClientEdwInfo__c[] updateRecs = new ClientEdwInfo__c[]{};
         Account[] acctList = [select id, Bis_ID__c from Account where Bis_ID__c in: acctSearchMap.keyset()];
         System.debug('checkForAccounts acctList='+acctList.size());
         for (Account acct : acctList) {
            acctIdSet.add(acct.Id);
            ClientEdwInfo__c[] edwList = acctSearchMap.remove(Integer.valueOf(acct.Bis_ID__c));
            System.debug('checkForAccounts bisId='+acct.Bis_ID__c+' edwList='+(edwList != null ? edwList.size() : -1));
            if (edwList != null) {
               for (ClientEdwInfo__c edw : edwList) {
                  System.debug('checkForAccounts set acct id for '+edw.Name);
                  edw.Account__c = acct.Id;
                  addToProcessTracker(edw, 'Found Account set Id to '+acct.Id);
               }
            }
         } // for (Account acct : acctList
         
         for (ClientEdwInfo__c[] edwList : acctSearchMap.values()) {
            for (ClientEdwInfo__c edw : edwList) {
               edw.Bad_BIS_ID__c = true;
               addToProcessTracker(edw, 'Could not find a matching Account for '+edw.BisId__c);
            }
         } // for (ClientEdwInfo__c[] edwList
      }
      ClientEDWInfoHelper.TRIGGER_ALREADY_RAN = true;
      DmlHelper.performDML2(edwInfos, DmlHelper.DML_UPDATE, 'ClientEDWInfo', 'checkForAccounts', 'Updating ClientEDWInfo with Account info', true);
      return acctIdSet;
   } // checkForAccounts
   
   public static void checkAccountField(Account acct, String acctFldName, ClientEdwInfo__c edw, Map<Id
                                        ,ClientEdwInfo__c> edwToUpdateMap
                                        ,Map<Id, Account> acctUpdateMap) {
      Boolean acctValue = (Boolean)acct.get(acctFldName);
      Boolean checkValue = (edw != null && edw.EndDate__c == null);
      System.debug('checkAccountField edw='+(edw != null ? edw.Name : 'No edw')+' acctValue='+acctValue+' checkValue='+checkValue);
      if (acctValue != checkValue) {
         acct.put(acctFldName, checkValue);
         if (edw != null) {
            addToProcessTracker(edw, 'Updated '+acctFldName+' to '+checkValue);
            edwToUpdateMap.put(edw.Id, edw);
         }
         acctUpdateMap.put(acct.Id, acct);
      }
   } // checkAccountField
   
   public static Integer TRACKER_LENGTH=ClientEdwInfo__c.ProcessTracker__c.getDescribe().getLength();

   public static void addToProcessTracker(ClientEdwInfo__c edw, String notesToAdd) {
      if (String.IsNotBlank(notesToAdd)) {
         System.debug('addToProcessTracker notesToAdd: '+notesToAdd);
         StringHelper.addNotesToField(edw, 'ProcessTracker__c', TRACKER_LENGTH, notesToAdd, true);
      }
   } // addToProcessTracker
    
}//ClientEDWInfoHelper class