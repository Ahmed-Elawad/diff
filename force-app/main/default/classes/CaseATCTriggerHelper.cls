/* ATC Case to allow for Enrollments Tracking and Reporting for Flock Clients(APR0143795)
 *  
 * History
 * --------
 * 3/6/2023  Susmitha Somavarapu  Created
   10/17/2023 Lalan Kumar APR0156165: Agency - Update Profile Permissions to update Case/Ref Object Owner field
   2/8/2024  Eric Porter APR0164353 Commenting out auto populating state field functionality
   */

public without sharing class CaseATCTriggerHelper implements TriggerInterfaceC {
    
  public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs('caseATCTriggerHelper', p_recs, oldMap, isBefore, isAfter, isDelete, 'caseATCTriggerHelper', null);
      if (recs == null || recs.isEmpty()) {
         return;
      }
      Map<id, Case> oldRecMap =(Map<id, case>) oldMap; 
      SObjectType objType = TriggerMethods.objType;
      String objTypeName = TriggerMethods.objectTypeName;
      System.debug('caseATCTriggerHelper objTypeName='+objTypeName+' recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete);
      /*APR0156165:trigger.isinsert is added to assign Queue only in creation  */
      if (trigger.isinsert && isBefore && objType == Case.sObjectType) {
         // Id hnbEnrollmentsATCRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HNB Enrollments ATC Case Record Type').getRecordTypeId();
          //Id hnbEnrollmentsATCRecType = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('HNB_Enrollments_ATC_Case_Record_type').getRecordTypeId();
          List<Case> atcCases = new List<Case>(); 
          RecordType hnbEnrollmentsATCRecType = [Select Id, Name, sobjectType from RecordType 
          where sObjectType = 'Case' and Name = 'HNB Enrollments ATC Case Record Type' and IsActive = true];  

          for (Case caseRecord : (Case[]) recs) {
            // Before Insert checking case record with Type=ATC and Record Type equals to HNB Enrollements ATC Case Record Type
              if (caseRecord.Type == 'ATC' && caseRecord.RecordTypeId == hnbEnrollmentsATCRecType.id) {                  
                  atcCases.add(caseRecord);
              }            
          } 
          if (!atcCases.isEmpty()) {
              processATCRecordsBefore(atcCases); 
              }             
      }
      else if (isAfter && objType == Case.sObjectType & !isDelete) {
          //Id hnbEnrollmentsATCRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HNB Enrollments ATC Case Record Type').getRecordTypeId();
        //  Id hnbEnrollmentsATCRecType = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('HNB_Enrollments_ATC_Case_Record_type').getRecordTypeId();
          RecordType hnbEnrollmentsATCRecType = [Select Id, Name, sobjectType from RecordType 
          where sObjectType = 'Case' and Name = 'HNB Enrollments ATC Case Record Type' and IsActive = true];  
          
          Set<Id> accIdSet4ATCCases = new set<Id>();
          List<Case> atcCases = new List<Case>(); 
          for (Case caseRecord : (Case[]) recs) {
           // After Insert checking case record with Type=ATC and Record Type equals to HNB Enrollements ATC Case Record Type

              if ( caseRecord.type == 'ATC' && caseRecord.RecordTypeId == hnbEnrollmentsATCRecType.id && (oldRecMap != null &&  oldRecMap.get(caseRecord.id).type != 'ATC')) {
                  accIdSet4ATCCases.add(caseRecord.AccountId);
                  atcCases.add(caseRecord);
              }
              else if ( caseRecord.type == 'ATC' && caseRecord.RecordTypeId == hnbEnrollmentsATCRecType .id&& oldRecMap == null) {
                  accIdSet4ATCCases.add(caseRecord.AccountId);
                  atcCases.add(caseRecord);
              }
          }
          if (!atcCases.isEmpty()) {
          processATCRecordsAfter(atcCases, accIdSet4ATCCases); 
          }
          
      } 
  }
  //Processing the ATC records before update, assigning to queue and changing the subject to Flock ATC
  public void processATCRecordsBefore(List<Case> atcCases){
     ID queueIdHNBFEnrolmentsCase = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'HNBF Enrollments' AND SobjectType = 'Case'].Queue.Id; //APR0143795
     for (Case caseRecord :  atcCases) {
          caseRecord.OwnerId = queueIdHNBFEnrolmentsCase;
          caseRecord.Subject = 'Flock ATC';                        
  } 

  }
// Processing ATC records by creating New HNBF Enrollment records with specified values
  public void processATCRecordsAfter(List<Case> atcCases, Set<id> accountIDset){
      Date todayDate = System.today(); //new Date.today();
      List<Reference_HNBF__c> refeHNBFToInser = new List<Reference_HNBF__c>();
      Id refAgecyHNBFRecType = Schema.SObjectType.Reference_HNBF__c.getRecordTypeInfosByName().get('HNB Enrollments ATC Record Type').getRecordTypeId();
      ID queueIdHNBFEnrolments = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'HNBF Enrollments' AND SobjectType = 'Reference_HNBF__c'].Queue.Id;
      Reference_HNBF__c newRefHNBF;
      //Collecting exisiting Account and Case record values to map the new HNBF records
      Map<ID, Account> accountMap = new Map<ID, Account>([ SELECT Id, Bank_Branch_Number__c, Bis_ID__c, BillingState, ShippingState, Name FROM Account WHERE id IN :accountIDset]); 
      Map<ID, Case> caseMapRE = new Map<ID, Case>([SELECT id, (SELECT id, Region__c, Account_Manager__c FROM Reference_HNBFs__r WHERE recordtype.name = 'HNB Enrollments ATC Record Type') FROM case WHERE id IN :atcCases AND recordtype.name = 'HNB Enrollments ATC Case Record type']);

      for (Case caseRecord  : atcCases) {
          newRefHNBF = new Reference_HNBF__c();
          Account caseAccount = accountMap.get(caseRecord.AccountId);
          newRefHNBF.RecordTypeId = refAgecyHNBFRecType; 
          newRefHNBF.ownerId = queueIdHNBFEnrolments;
          newRefHNBF.Case_Number__c = caseRecord.id;
          newRefHNBF.Status_Date__c = todayDate;
          newRefHNBF.Contact_Name__c = caseRecord.ContactId;
          if (
            caseMapRe.get(caseRecord.Id) != null &&
            caseMapRe.get(caseRecord.Id).Reference_HNBFs__r != null &&
            caseMapRe.get(caseRecord.Id).Reference_HNBFs__r.size() > 0
          ) {
            List<Reference_HNBF__c> refList = caseMapRe.get(caseRecord.Id)
              .Reference_HNBFs__r;
            newRefHNBF.Region__c = refList[0].Region__c;
            newRefHNBF.Account_Manager__c = refList[0].Account_Manager__c;
          }
          //APR0164353
          // if (caseAccount.BillingState != '') {
          //   newRefHNBF.State__c = caseAccount.BillingState;
          // } else {
          //   newRefHNBF.State__c = caseAccount.ShippingState;
          // }
          refeHNBFToInser.add(newRefHNBF);
      }
      // Inserting New HNBF Enrollments records using the DML helper
      if (!refeHNBFToInser.isEmpty()) {
          DmlHelper.performDML(refeHNBFToInser, DmlHelper.DML_INSERT, 'caseATCTriggerHelper', 'processATCRecordsAfter', 'Inserting new Reference HNBF  records', true);

      }
  }   
 

}