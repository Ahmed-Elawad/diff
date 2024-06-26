/*
*
*   HISTORY
*  ---------
*   05/16/2018 Jake Hinds   Created
*   03/25/2024 Carrie Marciano	 CanBeDeleted old MPSC tech debt
*/
trigger IdeaTrigger on Idea (after insert, after update, before insert, before update) {
 /*
    Map<Id,Idea> mpscIdeaMap = new Map<Id,Idea>();
    Idea[] mpscIdeaManagers = new Idea[]{};
    if(IdeaMethods.mpscZoneId==null){
        IdeaMethods.mpscZoneId = [SELECT Id from Community WHERE Name = 'All MPSC/Enterprise'].Id;
    }
    
    for (Idea newIdea : Trigger.new){
        
        if(Trigger.isInsert){
            if(Trigger.isBefore){
                if(newIdea.CommunityId == IdeaMethods.mpscZoneId && newIdea.CSS_Manager_Sponsor__c==null){
                    mpscIdeaManagers.add(newIdea);
                }
                
            }//Trigger is before insert
            else{
            }//Trigger is after insert
        }//Trigger is insert
        else{
            Idea oldIdea = Trigger.oldMap.get(newIdea.id);
            if(Trigger.isBefore){
            }//Trigger is before update
            else{
                if(oldIdea!=null && newIdea.CommunityId == IdeaMethods.mpscZoneId  && newIdea.Case__c == null
                     && newIdea.Status!= oldIdea.Status && newIdea.Status == 'Submitted to Strategy Team for Review'){
                    mpscIdeaMap.put(newIdea.Id,newIdea);
                }
            }//Trigger is after update
        }//Trigger is update
    }//for
    if(!mpscIdeaManagers.isEmpty()){
        IdeaMethods.setManager(mpscIdeaManagers);
    }
    if(!mpscIdeaMap.isEmpty()){
        IdeaMethods.createMPSCCase(mpscIdeaMap);
    } 
  */   
}