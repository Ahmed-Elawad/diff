/*   Handle all of the "after" Reference_HRE_CHB_Onboarding operations.
*
* History 
* -------
* 10/17/2013 Frank Lurz       created 
* 05/07/2014 Code Kata        add the "after update"-related code
* 01/05/2015 Frank Lurz       change ASO references to HR Solutions for the HK-0005 effort
* 02/20/2015 Frank Lurz       removed the reference to the Service Support HRE/CHB Ref Object record type
* 02/24/2015 Frank Lurz       removed the reference to the Handbook Support HRE/CHB Ref Object record type
*/

trigger ReferenceHRECHBAfter on Reference_HRE_CHB_Onboarding__c (after insert, after update) {
 
 //Schema.RecordTypeInfo refHRECHBHandbookSupportrt = RecordTypeHelper.getRecordType('Handbook Support HRE/CHB Ref Object', 'Reference_HRE_CHB_Onboarding__c');
 Schema.RecordTypeInfo refHRECHBOnbrt = RecordTypeHelper.getRecordType('Reference HRE/CHB Onboarding', 'Reference_HRE_CHB_Onboarding__c');
 Schema.RecordTypeInfo refHRECHBASO = RecordTypeHelper.getRecordType('Handbook Support HR Solutions Ref Object', 'Reference_HRE_CHB_Onboarding__c');
 Schema.RecordTypeInfo refHRECHBPEO = RecordTypeHelper.getRecordType('Handbook Support PEO Ref Object', 'Reference_HRE_CHB_Onboarding__c');
  
 list<Reference_HRE_CHB_Onboarding__c> refObjctsList = new list<Reference_HRE_CHB_Onboarding__c>();
 list<Reference_HRE_CHB_Onboarding__c> refOnbObjctsList = new list<Reference_HRE_CHB_Onboarding__c>();
  
 if (Trigger.isInsert) {
     //get account for the upserted Reference_HRE_CHB_Onboarding record
     for (Reference_HRE_CHB_Onboarding__c refHRECHBO : Trigger.new)    {          
        if ((refHRECHBO.RecordTypeId == refHRECHBASO.getRecordTypeId()) ||
            (refHRECHBO.RecordTypeId == refHRECHBPEO.getRecordTypeId())){   
            refObjctsList.add(refHRECHBO);      
        }
        else if(refHRECHBO.RecordTypeId == refHRECHBOnbrt.getRecordTypeId()){
            refOnbObjctsList.add(refHRECHBO);
        }
     }
      
      if (!refObjctsList.isEmpty()) {
          ReferenceHRECHBHelper.ReferenceHRECHBStates(refObjctsList);      
      } 
 } //isInsert  
 else if (Trigger.isUpdate) {    
     For(Reference_HRE_CHB_Onboarding__c newRecord: trigger.newmap.values()){
         if((newRecord.Interview_Completed_Date__c != trigger.oldmap.get(newRecord.ID).Interview_Completed_Date__c) && newRecord.Interview_Completed_Date__c != null &&
             ChatterMentionPost.postedOnce() && 
            (newRecord.Contract_Clean_Date__c > system.today() - 180)){
            list<id> atMentionList = new list<id>();
            atMentionList.add(newRecord.Sales_Rep__c);
            atMentionList.add(newRecord.DSM__c);
            atMentionList.add(newRecord.FSS__c);
            chatterMentionPost.createChatterMentionPost(newRecord.id,atMentionList,'Good news! The employee handbook interview for this client (' + newRecord.Prospect_Client_Number__c + ') has been conducted. If you have any questions, please contact 877-405-5877.');    
          }
         else if((newRecord.All_Versions_Printed_Date__c != trigger.oldmap.get(newRecord.ID).All_Versions_Printed_Date__c) && newRecord.All_Versions_Printed_Date__c != null &&
                 ChatterMentionPost.postedOnce() && 
                 (newRecord.Contract_Clean_Date__c > system.today() - 180)){
                list<id> atMentionList = new list<id>();
                atMentionList.add(newRecord.Sales_Rep__c);
                atMentionList.add(newRecord.DSM__c);
                atMentionList.add(newRecord.FSS__c);
                chatterMentionPost.createChatterMentionPost(newRecord.id,atMentionList,'Good news! The employee handbook for this client (' + newRecord.Prospect_Client_Number__c + ') has been finalized and will be shipped within three business days. If you have any questions, please contact 877-405-5877.');                   
                 }
     }    
 } //else-if    
        
} // trigger ReferenceHRECHBAfter