/* Class to create a tracking record each time certain fields on certain objects change
 *
 * History
 * -------
   08/26/2019   Jake Hinds       Created
   10/28/2019   Dan Carmen       Change to use the runningUser from UserHelper to save a query.
   01/23/2023   Dan Carmen       Update to TriggerInterfaceC

*/

public without sharing class DataEnrichmentLogMethods implements TriggerInterfaceC {
    
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs('CallCenterHelper', p_recs, oldMap, isBefore, isAfter, null, null);
      System.debug('DataEnrichmentLogMethods.handleTrigger recs='+(recs != null ? recs.size() : -1));
      if (recs != null && !recs.isEmpty()) {
         User runningUser = UserHelper.getRunningUser();
         Profile prof = (runningUser != null ? runningUser.Profile : null);
         // if there isn't a profile we can't proceed
         if (prof == null) {
            return;
         }
         List<String> delProfiles = Label.Data_Enrichment_Log_Profiles.split(';');
         Boolean profGood = (delProfiles.contains(prof.Name));
         //should run on Account Update
         if (profGood && isAfter && recs[0].getSObjectType() == Account.sObjectType && oldMap!=null) {
             system.debug('DataEnrichmentLog sobjsForDEL In Account Trigger');
             checkRecords(recs,oldMap,recs[0].getSObjectType());
         }
         //should run on Contact Insert/Update
         else if (profGood && isAfter && recs[0].getSObjectType() == Contact.sObjectType) {
             system.debug('DataEnrichmentLog sobjsForDEL In Contact Trigger');
             checkRecords(recs,oldMap,recs[0].getSObjectType());
         } 
         //should run on Business Profile Insert/Update
         else if (profGood && isAfter && recs[0].getSObjectType() == Business_Profile__c.sObjectType) {
             system.debug('DataEnrichmentLog sobjsForDEL In BP Trigger');
             checkRecords(recs,oldMap,recs[0].getSObjectType());
         }
      } // if (recs != null && !recs.isEmpty

   } // handleTrigger

    public void checkRecords(sObject[] sobjs,Map<Id,sobject>oldMap,Schema.SObjectType objName){
        Map<String,Data_Enrichment_Log_Fields__c> delfMap = getDELFsForObject(objName);
        system.debug('DataEnrichmentLog checkRecords delfMap: '+delfMap.keySet());
        Sobject[] sobjsForDEL = new Sobject[]{};
        /********Nested for loop == bad?******/
        for(Sobject sobj:sobjs){
           SObject oldRec = (oldMap != null ? oldMap.get(sobj.Id) : null);
            //need to see if any of the fields in our custom setting have changed or are set on the record
            for(String fieldToCheck:delfMap.keySet()){
                system.debug('DataEnrichmentLog checkRecords has oldRec : '+(oldRec != null)+' fieldval:'+sobj.get(fieldToCheck));
                if(sobj.get(fieldToCheck)!= null && (oldRec == null || 
                    (oldRec != null && oldRec.get(fieldToCheck) != sobj.get(fieldToCheck)))){
                        system.debug('DataEnrichmentLog checkRecords field has changed: '+fieldToCheck);
                        sobjsForDEL.add(sobj);
                        break;
                }//if field changes or field is not blank on insert
            }//for delfMap
        }//for acct
        if(!sobjsForDEL.isEmpty()){
            system.debug('DataEnrichmentLog sobjsForDEL starting Queuable');
            DataEnrichmentLogQueueable delq = new DataEnrichmentLogQueueable(sobjsForDEL,oldMap,objName,delfMap);
            System.enqueueJob(delq);
        }
    }
    //get all fields relevant to the object we're tracking
    private Map<String,Data_Enrichment_Log_Fields__c> getDELFsForObject(Schema.SObjectType objName){
        Map<String,Data_Enrichment_Log_Fields__c> delfByObjFieldMap = new Map<String,Data_Enrichment_Log_Fields__c>();
        for(Data_Enrichment_Log_Fields__c delf:Data_Enrichment_Log_Fields__c.getAll().values()){
            if(String.valueOf(objName)==delf.Object_Name__c){
                delfByObjFieldMap.put(delf.Field_Name_on_Object__c,delf);
            }
        }
        return delfByObjFieldMap;
    }//getDELFsForObject
    
}