/* 
 * Class to create a tracking record each time certain fields on certain objects change
 *
 * History
 * -------
   08/26/2019   Jake Hinds       Created
   01/23/2023   Dan Carmen       Update to TriggerInterfaceC

*/
public without sharing class DataEnrichmentLogQueueable implements Queueable{
    public list<SObject> objs;
    public Map<Id,sObject>oldMap;
    public Map<String,Data_Enrichment_Log_Fields__c> delfMap;
    public Schema.SObjectType objType;
    public Boolean isAccount;
    public Boolean isContact;
    public Boolean isBusinessProfile;
    
    public DataEnrichmentLogQueueable(Sobject[] p_objs, Map<Id,sObject>p_oldMap, Schema.SObjectType p_objType, Map<String,Data_Enrichment_Log_Fields__c> p_delfMap){
        objs = p_objs;
        oldMap = p_oldMap;
        objType = p_objType;
        delfMap = p_delfMap;
        isAccount = (objType == Account.sObjectType ? true : false);
        isContact = (objType == Contact.sObjectType ? true : false);
        isBusinessProfile = (objType == Business_Profile__c.sObjectType ? true : false);
    }
    
    public void execute(QueueableContext context) {
        Id[] objIds = new Id[]{};
        
        //need object Ids to query
        for(Sobject so:objs){
            objIds.add((Id)so.get('Id'));
        }
        system.debug('DataEnrichmentLogQueueable execute objIds'+objIds);
        Data_Enrichment_Log__c[] existingDELList;
        Map<Id,Data_Enrichment_Log__c> delByObjIdMap = new Map<Id,Data_Enrichment_Log__c>();
        //get any existing DEL created today to update instead of insert;
        system.debug('DataEnrichmentLogQueueable execute system.today:'+system.today());
        if(isAccount){
            existingDELList = [SELECT Id,Account__c,Contact__c,Business_Profile__c FROM Data_Enrichment_Log__c WHERE Business_Profile__c = null AND Contact__c = null AND Account__c in : objIds AND CreatedDate > :date.today()];
        }
        else if(isContact){
            existingDELList = [SELECT Id,Account__c,Contact__c,Business_Profile__c FROM Data_Enrichment_Log__c WHERE Contact__c in : objIds AND CreatedDate > :date.today()];
        }
        else if(isBusinessProfile){
            existingDELList = [SELECT Id,Account__c,Contact__c,Business_Profile__c FROM Data_Enrichment_Log__c WHERE Business_Profile__c in : objIds AND CreatedDate > :date.today()];
        }
        system.debug('DataEnrichmentLogQueueable execute existingDELList'+existingDELList);
        //separate existing del by object id, should only ever really have 1 object type in map - trigger will contain single object type
        for(Data_Enrichment_Log__c del : existingDELList){
            if(isAccount){delByObjIdMap.put(del.Account__c,del);}
            else if(isContact){delByObjIdMap.put(del.Contact__c,del);}
            else if(isBusinessProfile){delByObjIdMap.put(del.Business_Profile__c,del);}
        }
        system.debug('DataEnrichmentLogQueueable execute delByObjIdMap before evaluation'+delByObjIdMap);
        for(Sobject so:objs){
            Data_Enrichment_Log__c del = (delByObjIdMap!=null && delByObjIdMap.containsKey((Id)so.get('Id'))?delByObjIdMap.get((Id)so.get('Id')):null);
            system.debug('DataEnrichmentLogQueueable execute del'+del);
            Boolean delNeedsDML = false;
            for(String fieldToCheck:delfMap.keySet()){
                Data_Enrichment_Log_Fields__c delf = delfMap.get(fieldToCheck);
                if( (oldMap==null && so.get(fieldToCheck)!= null) || 
                  (oldMap!=null && oldMap.containsKey((Id)so.get('Id')) && oldMap.get((Id)so.get('Id')).get(fieldToCheck) != so.get(fieldToCheck))){
                      system.debug('DataEnrichmentLogQueueable execute field has changed: '+fieldToCheck);
                      if(del==null){
                          del = new Data_Enrichment_Log__c();
                          if(isAccount){
                          	del.Object_Type__c = 'Account';
                            del.Account__c = (Id)so.get('Id');
                          }
                          else if(isContact && oldMap == null){
                          	del.Object_Type__c = 'Contact - New';
                            del.Contact__c = (Id)so.get('Id');
                            del.Account__c = (Id)so.get('AccountId');
                          }
                          else if(isContact){
                          	del.Object_Type__c = 'Contact - Edit';
                            del.Contact__c = (Id)so.get('Id');  
                            del.Account__c = (Id)so.get('AccountId');
                          }
                          else if(isBusinessProfile){
                          	del.Object_Type__c = 'Business Profile';
                            del.Business_Profile__c = (Id)so.get('Id');
                            del.Account__c = (Id)so.get('Prospect_Client__c');
                          }
                      }
                      //if update of record and not insert, put old value on del
                      if(oldMap!=null && oldMap.containsKey((Id)so.get('Id'))){
                          del.put(delf.DEL_Field_Before__c,oldMap.get((Id)so.get('Id')).get(fieldToCheck));
                      }
                      //put new value on del
                      del.put(delf.DEL_Field_After__c,so.get(fieldToCheck));
                      
                      if(isAccount){delByObjIdMap.put(del.Account__c,del);}
                      else if(isContact){delByObjIdMap.put(del.Contact__c,del);}
                      else if(isBusinessProfile){delByObjIdMap.put(del.Business_Profile__c,del);}
                }//if field changes or field is not blank on insert
            }//for delfMap
        }
        system.debug('DataEnrichmentLogQueueable execute delByObjIdMap after evaluation'+delByObjIdMap);
        DMLHelper.performDML2(delByObjIdMap.values(),'Upsert','DataEnrichmentLogQueueable','saveRecords','upserting data enrichment logs',true);
    }
}