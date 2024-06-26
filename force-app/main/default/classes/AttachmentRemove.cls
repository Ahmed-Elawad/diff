/*
 * Remove Attachments for Email-to-Case before case insert 
 * The attachment is related to an Inbound Email Message and that is related to a Case 
 * History
 * -------
   02/05/2018 Lynn Michels      Created
   04/18/2018 Dan Carmen      Escape out of the method if nothing to process.
    
 */

public with sharing class AttachmentRemove implements TriggerInterface{
    List<Attachment> attachmentsToDelete = new List<Attachment>();  
    
    public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

    public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {
        //cast SObject array as List of Attachments
        List<Attachment> attachments = (List<Attachment>)recs;
        //map to hold Inbound Email Message record and all of its attachments
        Map<Id,List<Attachment>> emailMessageWithAttachments = new Map<Id,List<Attachment>>();
        
        //populate the emailMessageWithAttachments map with the attachment's ParentID and a list of the attachments
        for(Attachment a : attachments){
            String id = a.ParentId;
            //if the attachment is related to an Inbound Email Message ('02s')
            //add the attachment to the attachmentList
            //add its ParentId as the key in the map
            if (id.startsWith('02s') ){
            //create a new list for each parentId
                List<Attachment> attachmentList = emailMessageWithAttachments.containsKey(a.ParentId) ? emailMessageWithAttachments.get(a.ParentId) : new Attachment[]{};
                attachmentList.add(a);
                emailMessageWithAttachments.put(a.Parentid,attachmentList);
            }//end if '02s' 
        }//end for loop
            
       if (emailMessageWithAttachments.isEmpty()) {
          return;
       }
        //query Inbound Email Message to see if Parent Id is a specific Case
        List<EmailMessage> parentsOfEmailMessages = [SELECT ParentId from EmailMessage WHERE Id IN: emailMessageWithAttachments.keySet()];

        //a map to relate the email message to the case
        map<id, id> caseToEmailMessage = new map<id, id>();
        //a map to relate a case to the email message so I can get from the case, back to the attachments
        map<id, id> emailMessageToCase = new map<id, id>();

        for(EmailMessage e : parentsOfEmailMessages){
            if(!emailMessageToCase.containsKey(e.Id)){   //if the email message is not in the map, add it.
                caseToEmailMessage.put(e.ParentId, e.id);
                emailMessageToCase.put(e.id, e.ParentId);
            }//end if containsKey   
        }//end for parentsOfEmailMessages

        //query cases to check Record Type and Origin
        List<Case> cases = [SELECT Id, RecordType.Name, Origin FROM Case WHERE Id IN: emailMessageToCase.values()];
    
        List<Id> listOfEmailMessages = new List<Id>();
        //loop through the cases returned and if they have a custom setting set up for them, process them.
        for(Case c : cases){
            if(verifyCustomSettingExists('Case', c.RecordType.Name, c.Origin)){
                Id emailId = caseToEmailMessage.get(c.id);
                listOfEmailMessages.add(emailId);
            }
        }//end for cases
            
        
        //loop through listofEmailMessages and get the attachments from each email
        //loop through those attachments and create a new reference to each attachment before adding it to the List
        //cannot delete records directly from a trigger
        for(Id i : listOfEmailMessages){
          for (Attachment att : emailMessageWithAttachments.get(i)) {
             attachmentsToDelete.add(new Attachment(Id=att.Id));
          }
        } //end for listOfEmailMessages
    
        system.debug('checkAllAfterTrigger attachmentsToDelete' +attachmentsToDelete);
        DmlHelper.performDML2(attachmentsToDelete, DmlHelper.DML_DELETE, 'AttachmentRemove', 'processAfterTriggerActions', 'deleteing attachments', true);
    }//end checkAllAfterTrigger


    //See if there is an entry for this scenario in the Record type Custom Setting
    public static Boolean verifyCustomSettingExists(String objectName, String caseRecordType, String caseOrigin) 
    {
        Boolean processCase = false;
        //Grab all record types
        for (RecordType__c rt : RecordType__c.getAll().values()) 
        {
            //Verify there is a setting that matches parameter values
            if (rt.ObjectName__c == objectName && rt.RecordTypeName__c == caseRecordType && rt.Case_Origin__c == caseOrigin) 
            {   //Grab record type information
                processCase = true;
                break;
            }
        }
        return processCase;
    }//end verifyCustomSettingExists

    public void checkBeforeTrigger(SObject newRec, SObject oldRec) {}
   
    public void processBeforeTriggerActions() {}
   
    public void checkAfterTrigger(SObject newRec, SObject oldRec){}
    
    public void processAfterTriggerActions(){}
}