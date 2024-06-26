/*
*
*   HISTORY
*  ---------
*   05/16/2018 Jake Hinds   Created
3/20/2024  Carrie Marciano    CanBeDeleted old MPSC tech debt
*
*/
public with sharing class IdeaMethods {
    public IdeaMethods(){}
    
/*
    public static Id mpscZoneId;
    public static void setManager(Idea[] ideas){
        User creator = [SELECT Id,ManagerId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        for(Idea idea:ideas){
            if(creator!=null){
                idea.CSS_Manager_Sponsor__c = creator.ManagerId;
            }
        }
    }
    public static void createMPSCCase(Map<Id,Idea>ideaMap){
        Id caseRTId = RecordTypeHelper.getRecordType('Service Support MPSC Analyst Case','Case').getRecordTypeId();
        AssignmentRule ar = [select id, active, name, SobjectType from AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.assignmentRuleId= ar.Id;
        Group analystQueue = [SELECT Id FROM Group WHERE Type='Queue' AND Name ='MPSC Analyst Case Queue'];
        Id[] creatorIds = new Id[]{};
        for(Idea idea:ideaMap.values()){
            creatorIds.add(idea.CreatedById);
        }
        Contact[] contacts = [SELECT Id,User_Lookup__c from Contact WHERE User_Lookup__c in:creatorIds];
        Map<Id,Id> contactIdByUserId = new Map<Id,Id>();
        for(Contact contact:contacts){
            contactIdByUserId.put(contact.User_Lookup__c,contact.Id);
        }
        Case[] casesToInsert = new Case[]{};
        for(Idea idea:ideaMap.values()){
            Case newCase = new Case();
            newCase.setOptions(dmo);
            //newCase.OwnerId = analystQueue.Id;
            newCase.Origin = 'Ideas';
            newCase.RecordTypeId = caseRTId;
            newCase.Idea__c = idea.id;
            newCase.Category__c = 'Business Process';
            newCase.Subject = idea.Title;
            newCase.Description = idea.Body;
            newCase.Status = 'In Review';
            if(idea.Categories != null){
                String[] categories = idea.Categories.split(';');
                newCase.Sales_Org__c = categories[0];
            }
            if(contactIdByUserId!=null && contactIdByUserId.containsKey(idea.CreatedById)){
                newCase.contactId = contactIdByUserId.get(idea.CreatedById);
            }
            casesToInsert.add(newCase);
        }
        system.debug('IdeaMethods createMPSCCase'+casesToInsert);
        if(!casesToInsert.isEmpty()){
            DMLHelper.performDML2(casesToInsert,'Insert','IdeaMethods','createMPSCCase','inserting new cases',true);
        }
    }
    public static void processIdeaCaseLink(Map<Id,Id> ideaIdByCaseIdMap){
        if(!ideaIdByCaseIdMap.isEmpty()){
            if (Test.isRunningTest() || System.isBatch() || System.isFuture()) {
                processIdeaCaseLinkNow(ideaIdByCaseIdMap);
            } else {
                processIdeaCaseLinkFuture(ideaIdByCaseIdMap);
            }
        }
   }
   
   //call future method to update lookup field on idea record with created case record
   @future
   public static void processIdeaCaseLinkFuture(Map<Id,Id> ideaIdByCaseIdMap) {
        processIdeaCaseLinkNow(ideaIdByCaseIdMap);
   }
   //populate the case lookup field on idea record
   public static void processIdeaCaseLinkNow(Map<Id,Id> ideaIdByCaseIdMap) {
        Idea[] ideasToUpdate = new Idea[]{};
        system.debug('IdeaMethods processIdeaCaseLink Now'+ideaIdByCaseIdMap);
        for(Case kase:[SELECT Id,Idea__c From Case WHERE Id in:ideaIdByCaseIdMap.keySet()]){
            Idea i = new Idea(Id = kase.Idea__c,Case__c=kase.Id);
            ideasToUpdate.add(i);
        }
        
        if(!ideasToUpdate.isEmpty()){
            DMLHelper.performDML2(ideasToUpdate,'Update','IdeaMethods','processIdeaCaseLinkNow','updating Case lookup on Ideas',true);
        }
   } // processIdeaCaseLinkNow
 */  
}