/* 
   Update the zip assignments attached to a territory
     
   History
   -------
   05/25/2021 Dan Carmen   Created
   02/08/2024 Dan Carmen   Try to force the change record creation

 */
public class ZipTerritoryQueueable implements Queueable {
    
   public static final String CLASSNAME='ZipTerritoryQueueable';
    
   public Set<Id> territoryIdSet;
    
   public ZipTerritoryQueueable(Set<Id> p_territoryIdSet) {
      territoryIdSet = p_territoryIdSet;
   } // ZipTerritoryQueueable
    
   public void execute(QueueableContext context) {
      processRecs();
   } // execute

   public void processRecs() {
      JobHelper jh = new JobHelper(CLASSNAME);
      Apex_Batch_Control__c abc = getBatchControl();
      // what's the maximum number of records we want to process before re-running?
      Integer recLimit = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 1000);
       
      System.debug('processRecs territoryIdSet='+territoryIdSet.size()+' recLimit='+recLimit);

      Integer zipRetrieved = 0;
       
      Map<Id,ZipTerritory__c> territoryMap = ZipTerritoryQueueable.getTerritoryMap(territoryIdSet);
      
      for (Zip_Assignment__c[] zipAssigns : [Select Id, Name
                                                   ,CreateChangeRecord__c
                                                   ,District__c
                                                   ,HR_Person_Id__c
                                                   ,Rep_Name__c
                                                   ,Sales_Office__c
                                                   ,Sales_Org__c
                                                   ,User__c
                                                   ,Zip_Code_Information__c
                                                   ,ZipTerritory__c
                                               From Zip_Assignment__c
                                              Where ZipTerritory__c in :territoryMap.keySet()
                                                and NeedsUpdate__c = true
                                                limit :recLimit
                                             ]) {
         zipRetrieved += zipAssigns.size();
         System.debug('processRecs zipRetrieved='+zipRetrieved);
         Zip_Assignment__c[] updateZipAssignments = new Zip_Assignment__c[]{};
         for (Zip_Assignment__c za : zipAssigns) {
            ZipTerritory__c territory = territoryMap.get(za.ZipTerritory__c);
            if (territory != null) {
                if (checkZaUpdate(territory, za)) {
                  updateZipAssignments.add(za);
                }
            } else {
                // if we didn't retrieve a territory, remove it from the set so we don't try to process it again.
                System.debug('processRecs territoryId not found: '+za.ZipTerritory__c);
                territoryIdSet.remove(za.ZipTerritory__c);
            } // if (territory != null
            
         } // for (Zip_Assignment__c za
         // make sure the triggers fire
         ZipAssignment.SKIP_TRIGGER=false;
         DmlHelper.performDML2(updateZipAssignments, DmlHelper.DML_UPDATE, CLASSNAME, 'processRecs', 'Update Zip Assignments', false);
      } // for (Zip_Assignment__c[] zipAssigns
      
      ErrorLog.checkSave();
      jh.tracker.Nbr_Batches__c = zipRetrieved;
      jh.completeJob(CLASSNAME, 'Number of Territories='+territoryMap.size()+' zipRetrieved='+zipRetrieved+' recLimit='+recLimit);
       
      System.debug('processRecs end of method zipRetrieved='+zipRetrieved);
      // if we've hit the limit then that means there are probably still more to process
      if (zipRetrieved >= recLimit) {
         launchQueueable(territoryIdSet, System.isQueueable());
      }
   } // processRecs
    
   // get all of the territories with rep information.
   public static Map<Id,ZipTerritory__c> getTerritoryMap(Set<Id> p_territoryIdSet) {
      // only select the territories with an active rep.
      Map<Id,ZipTerritory__c> territoryMap = new Map<Id,ZipTerritory__c>([Select Id, Name, CheckZipUser__c, District__c
                                                                                ,Rep_Name__c, Sales_Org__c
                                                                                ,TerritoryContact__c, Territory_Nbr__c
                                                                                ,TerritoryRep__c
                                                                                ,TerritoryRep__r.Id, TerritoryRep__r.Name
                                                                                ,TerritoryRep__r.HR_Person_Id__c
                                                                                ,TerritoryRep__r.SalesOfficeNumber__c
                                                                                ,Zip_Segment__c
                                                                            from ZipTerritory__c
                                                                           Where Id in :p_territoryIdSet
                                                                             and TerritoryOkay__c=true]);
      return territoryMap;
   } // getTerritoryMap
    
   public static Boolean checkZaUpdate(ZipTerritory__c territory, Zip_Assignment__c za) {
      Boolean updated = false;
      if (za.Rep_Name__c != territory.Rep_Name__c) {
         za.Rep_Name__c = territory.Rep_Name__c;
         updated = true;
      }
      if (za.User__c != territory.TerritoryRep__c) {
         za.User__c = territory.TerritoryRep__c;
         za.CreateChangeRecord__c = true;
         updated = true;
      }
      if (territory.TerritoryRep__c != null) {
         if (territory.TerritoryRep__r != null && (za.HR_Person_Id__c != territory.TerritoryRep__r.HR_Person_Id__c 
                                                   || za.Sales_Office__c != territory.TerritoryRep__r.SalesOfficeNumber__c)
            ) {
            za.HR_Person_Id__c = territory.TerritoryRep__r.HR_Person_Id__c;
            za.Sales_Office__c = territory.TerritoryRep__r.SalesOfficeNumber__c;
            updated = true;
         }
      } else {
         za.HR_Person_Id__c = null;
         za.Sales_Office__c = null;
         updated = true;
      } // if (territory.TerritoryRep__c
               
      if (za.District__c != territory.District__c) {
         za.District__c = territory.District__c;
         updated = true;
      }
      return updated;
   } // checkZaUpdate
    
   public static void launchQueueable(Set<Id> p_territoryIdSet, Boolean forceRelaunch){
      if (!p_territoryIdSet.isEmpty()) {
         Apex_Batch_Control__c abc = getBatchControl();
         System.debug('checkLaunchQueuable p_territoryIdSet='+p_territoryIdSet.size()+' abc='+abc);
         // we won't using this command during a test
         Boolean abcIsActive = (abc != null && abc.Active__c);
         ZipTerritoryQueueable ztq = new ZipTerritoryQueueable(p_territoryIdSet);
         Boolean allowFuture = Utilities.allowFuture();
         System.debug('checkLaunchQueuable abcIsActive='+abcIsActive+' forceRelaunch='+forceRelaunch+' allowFuture='+allowFuture);
         if (abcIsActive && (forceRelaunch || allowFuture)) {
            System.enqueueJob(ztq);
         } else {
            // run it inline
            System.debug('checkLaunchQueuable launching inline');
            ztq.processRecs();
         }
      } // if (!p_territoryIdSet.isEmpty
    } // launchQueueable

   public static Apex_Batch_Control__c getBatchControl() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      return abc;
   } // getBatchControl

} // class ZipTerritoryQueueable