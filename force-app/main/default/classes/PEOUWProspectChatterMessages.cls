/*
*  .
*
* History
* --------
* 06/16/2021  Matt Fritschi  created
* 11/04/2021  Jake Hinds	 chatter post for completed steps
*/ 

global without sharing class PEOUWProspectChatterMessages implements Messaging.InboundEmailHandler {
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env){
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        
        String bodyText= ''; 
        // Add the email plain text into the local variable 
        bodyText = email.plainTextBody;
        System.debug('MGF PEOUWDiscrepancy handleInboundEmail bodyText='+bodyText); 
        System.debug('MGF PEOUWDiscrepancy handleInboundEmail email.subject='+email.subject); 
        //SFDC-15863 removed the email notification
        /*
        if(email.subject.contains('Prospect Comments Chatter')) {
            createDiscrepancyChatterFromProspect(bodyText);                                                      
        }*/
         if(email.subject.contains('Step Complete Chatter')){
            postCompletedStepChatter(bodyText);
        }
        
        return result;
        
    }
    
    public void createDiscrepancyChatterFromProspect(String bodyText) {
        List<String> fieldsList = bodyText.split(';\n');
        System.debug('MGF PEOUWDiscrepancy createChatterFromProspect fieldsList='+fieldsList); 
        
        Map<String, String> fieldValueMap = new Map<String, String>();
        String error='';
        for(String fieldValue : fieldsList) {
            List<String> fieldValuePair = fieldValue.split(':'); 
            try{
                fieldValueMap.put(fieldValuePair[0], fieldValuePair[1]);
            }
            catch(exception e){
                error+=e+'\n';
            }
            
        }
        if(String.IsNotBlank(error)){
            ErrorLog.logError('PEOUWProspectChatterMessages','createChatterFromProspect','parse email',null,bodyText+'\n'+error,null,true);
        }
        
        System.debug('MGF PEOUWDiscrepancy createChatterFromProspect fieldValueMap='+fieldValueMap); 
        
        PEO_Onboarding_Document_Discrepency__c disc = null;
        List<Id> usersToMention = new List<Id>();
        Id parentId = null;
        String[] messages = new String[]{};
            
        if(fieldValueMap.containsKey('Id')) {
            parentId = fieldValueMap.get('Id');
            disc = [SELECT Id, Name, LastModifiedby.Name,Prospect_Comments__c, Discrepancy_Type__c, Discrepancy_Sub_Type__c,Comment_Log__c, 
                    PEO_Underwriting_Checklist__c,PEO_Underwriting_Checklist__r.Sales_Analyst__c, Prospect_Client_Name__c, 
                    PEO_Underwriting_Checklist__r.Sales_Rep__c FROM PEO_Onboarding_Document_Discrepency__c WHERE Id = :parentId];
        }
        
        if(disc != null) {
            String message = disc.Prospect_Client_Name__c + ' has responded to ' + disc.Discrepancy_Type__c;
            if(disc.Discrepancy_Sub_Type__c != null) {
                message += '/' + disc.Discrepancy_Sub_Type__c;
            }
            message += '. Please review the response and mark the discrepancy as resolved at your earliest convenience ';
            
            String checklistURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + disc.PEO_Underwriting_Checklist__c;
            message  += checklistURL;
            messages.add(message);
            
            if(disc.PEO_Underwriting_Checklist__c != null && disc.PEO_Underwriting_Checklist__r.Sales_Analyst__c != null){
            	usersToMention.add(disc.PEO_Underwriting_Checklist__r.Sales_Analyst__c);
            }
            if(disc.PEO_Underwriting_Checklist__c != null && disc.PEO_Underwriting_Checklist__r.Sales_Rep__c != null) {
                usersToMention.add(disc.PEO_Underwriting_Checklist__r.Sales_Rep__c);
            }
            /*if(disc.PEO_Underwriting_Checklist__c != null && disc.PEO_Underwriting_Checklist__r.PEO_NSC__c != null) {
                usersToMention.add(disc.PEO_Underwriting_Checklist__r.PEO_NSC__c);
            }*/
            
            ChatterMentionPost.createChatterMentionPost(parentId, usersToMention, messages, true);
            
            disc.Comment_Log__c += '\n '+disc.LastModifiedBy.Name+' ('+Datetime.now().format()+')\n'+disc.Prospect_Comments__c;
            disc.Prospect_Comments__c = '';
            PEO_Onboarding_Document_Discrepency__c[] discs = new PEO_Onboarding_Document_Discrepency__c[]{disc};
            DmlHelper.performDML2(discs, DmlHelper.DML_UPDATE, 'PEOUWProspectChatterMessages', 'createChatterFromProspect', 'Updating Comment Log', true);
        }
    }
    public Boolean postCompletedStepChatter(String bodyText) {
        Boolean chatterCreated = false;
        system.debug('PEOUWProspectChatterMessages postCompletedStepChatter bodyText'+bodyText);
        //body text is going to be a semi colon separated list.  The first element will be the current step, the second is the prospect name, 
        //the third is the checklist Id, the fourth is the contact id, the remaining will be those to @mention
        String[] bodyList = bodyText.split(';');
        String completedStep = bodylist.remove(0);
        system.debug('PEOUWProspectChatterMessages postCompletedStepChatter completedStep'+completedStep);
        String prospectName = bodyList.remove(0);
        system.debug('PEOUWProspectChatterMessages postCompletedStepChatter prospectName'+prospectName);
        Id checklistId = (Id)bodylist.remove(0);
        system.debug('PEOUWProspectChatterMessages postCompletedStepChatter checklistId'+checklistId);
        Id commUserId = (Id)bodyList[0];
        Id contactId;
        try{
            User commUser = [Select ContactId FROM User WHERE id = :commUserId AND ContactId != null LIMIT 1];
            if(commUser!=null){
                contactId = commUser.ContactId;
            }
        }
        catch(Exception e){
            system.debug('No comm user found');
        }
        
        system.debug('PEOUWProspectChatterMessages postCompletedStepChatter contactId'+contactId);
        Id[] usersToMention = new Id[]{};
        for(String remainingId : bodyList){
            if(commUserId == null || (commUserId!=null && (Id)remainingId != commUserId)){
            	usersToMention.add((Id)remainingId);
            }
        }
        system.debug('PEOUWProspectChatterMessages postCompletedStepChatter usersToMention'+usersToMention);
        String chatterText='';
        if(String.isNotBlank(completedStep) && completedStep == 'medicalPrequal'){
            chatterText = 'The HSF Census Review submission has been completed by '+prospectName+'.';  //SFDC-15719
        }
        else if(String.isNotBlank(completedStep) && (completedStep == 'acctUpdatePrequal' || completedStep == 'medical')){
            chatterText = 'Take a look! '+prospectName+' has finished submitting the required information for Medical Underwriting.';
        }
        else if(String.isNotBlank(completedStep) && completedStep.contains('wc')){
            chatterText = 'Heads up! '+prospectName+' has finished submitting the required information for Workers\' Comp underwriting.';
        }
        else if(String.isNotBlank(completedStep) && completedStep.contains('addtlInfo')){
            chatterText = 'It\'s Go Time! '+prospectName+' has completed the Additional Information section of the portal.  Please reference this section for additional product information and a completed EPLI form.';
        }
        system.debug('PEOUWProspectChatterMessages postCompletedStepChatter chatterText'+chatterText);
        if(String.isNotBlank(chatterText) && checklistId!=null && !usersToMention.isEmpty()){
            chatterText += ' Please review the submission and submit to the NBSC/Analyst Queue when ready.\n';
            if(contactId!=null){
            	//chatterText += 'Contact: https://'+System.URL.getSalesforceBaseUrl().getHost()+'/lightning/n/Contact/'+contactId+'/view';
                chatterText += 'Contact: https://'+System.URL.getSalesforceBaseUrl().getHost()+'/lightning/r/Contact/'+contactId+'/view';
            }
            system.debug('chatterText:'+chatterText);
            ChatterMentionPost.createChatterMentionPost(checklistId, usersToMention, new String[]{chatterText}, true);
            chatterCreated=true;
        }
        return chatterCreated;
    }
}