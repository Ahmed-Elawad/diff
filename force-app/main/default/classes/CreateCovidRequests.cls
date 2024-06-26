/*
  * This new process will dynamically create a new  COVID Request Reference_Terms_Transfers__c and link it back to the related case record.  For example, it can create 
  *  
  * 
  * COVID Request Reference_Terms_Transfers__c automatically upon insert of 401k/S125 Operations Support recordtype cases by autopopulating OwnerId,Case Look Up,Contact Name from Case
  *  
  * History
  * --------
  * 04/27/2020 Preetam Thandra    created
  * 
    
   */

public without sharing class CreateCovidRequests implements TriggerInterfaceC{

   public static final String CLASSNAME='CreateCovidRequests';
   public static Boolean SKIP_TRIGGERS=false;
   
   
   
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        
     if (TriggerMethods.didTriggerRun(CLASSNAME,recs,isBefore,isAfter)) {
         return;
      } 
      
     SObjectType objType = TriggerMethods.objType;
     
     if(isAfter && (Trigger.isInsert || Trigger.isUpdate)){
         if (objType == Case.sObjectType) {
                createRecordOperations((List<Case>)recs,(Map<Id,Case>)oldMap,Trigger.isInsert,Trigger.isUpdate);
          }
        }
    }
   
   
   public static void createRecordOperations(List < Case > caseRecords,Map<Id,Case> oldCaseMap,Boolean isInsert,Boolean isUpdate) {
        ErrorLog__c log = ErrorLog.getLog(CLASSNAME);
        log.ObjectId__c=caseRecords[0].Id;
        log.ObjectAPIName__c='Case';
        log.BatchSize__c=caseRecords.size();
        List < Reference_Terms_Transfers__c > refTermTransList = new List < Reference_Terms_Transfers__c > ();
        Id OperationSupportRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('401k/S125 Operations Support').getRecordTypeId();
        Id covidRequestRecordId = Schema.SObjectType.Reference_Terms_Transfers__c.getRecordTypeInfosByName().get('COVID Requests').getRecordTypeId();


        for (Case c: caseRecords) {

            if (isInsert && c.RecordTypeId == OperationSupportRecTypeId && c.Product__c == '401K' && c.Termination_Transfer_Type__c == 'COVID Request') {
                refTermTransList.add(new Reference_Terms_Transfers__c(OwnerId = c.OwnerId, Case_Lookup__c = c.Id, Contact_Name__c = c.ContactId, RecordTypeId = covidRequestRecordId));
            }
            
            if(isUpdate && c.RecordTypeId == OperationSupportRecTypeId && oldCaseMap.get(c.Id).RecordTypeId != OperationSupportRecTypeId  ){
                if(c.Product__c == '401K' && c.Termination_Transfer_Type__c == 'COVID Request'){
                 refTermTransList.add(new Reference_Terms_Transfers__c(OwnerId = c.OwnerId, Case_Lookup__c = c.Id, Contact_Name__c = c.ContactId, RecordTypeId = covidRequestRecordId));   
                }
            }

        }
        
        ErrorLog.addToDescription(log,'refTermTransList='+refTermTransList.size());
        CadenceHelper.SKIP_TRIGGERS=true;
        log.NbrSuccess__c=refTermTransList.size();
    
        DmlHelper.performDML2(refTermTransList, DmlHelper.DML_INSERT, 'CreateCovidRequests', 'createRecordOperations', 'Insert COVID Record Operation Records', false);
        
        ErrorLog.saveLog(log);
    
    }
    
    
    


}