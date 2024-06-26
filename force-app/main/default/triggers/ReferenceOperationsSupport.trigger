/* 
   If the owner of the ref object changes to the approval queues, update the case owner so round robin gets hit. 
   
  History
  -------
  07/19/2016 Jacob Hinds   Created 
  08/10/2016 Jacob Hinds   Switching to Cancellations Queue only.
 
 */
trigger ReferenceOperationsSupport on Reference_Terms_Transfers__c (after update) {
    Map<Id,Id> updateOwnerMap = new Map<Id,Id>();
    String[] queueNames = new String[]{'HRS 4S Cancellations','HRS 4S Level 1 Approvers','HRS 4S Level 2 Approvers'};
    Group[] queues = [select Id,Name from Group where Name in: queueNames and Type = 'Queue'];
    Id cancellation;
    Id level1;
    Id level2;
    if(!queues.isEmpty()){
        for(Group g:queues){
            if(g.Name == 'HRS 4S Cancellations'){
                cancellation = g.Id;
            }
            else if(g.Name == 'HRS 4S Level 1 Approvers'){
                level1 = g.Id;
            }
            else if(g.Name == 'HRS 4S Level 2 Approvers'){
                level2 = g.Id;
            }
        }
    }
    
    /*Group cancellation = [select Id from Group where Name = 'HRS 4S Cancellations' and Type = 'Queue' LIMIT 1];
    Group level1 = [select Id from Group where Name = 'HRS 4S Level 1 Approvers' and Type = 'Queue' LIMIT 1];
    Group level2 = [select Id from Group where Name = 'HRS 4S Level 2 Approvers' and Type = 'Queue' LIMIT 1];*/

    for ( Reference_Terms_Transfers__c newRT: Trigger.new) {
        Reference_Terms_Transfers__c oldRT = Trigger.oldMap.get(newRT.id);

        //if owner changes to any of the three queues, send the owner up to the case
        if(newRT.OwnerId!=oldRT.OwnerId && cancellation!=null && newRT.OwnerId == cancellation){
            updateOwnerMap.put(newRT.Case_Lookup__c,cancellation);
        }
        else if(newRT.OwnerId!=oldRT.OwnerId && level1!=null && newRT.OwnerId == level1){
            updateOwnerMap.put(newRT.Case_Lookup__c,level1);
        }
        else if(newRT.OwnerId!=oldRT.OwnerId && level2!=null && newRT.OwnerId == level2){
            updateOwnerMap.put(newRT.Case_Lookup__c,level2);
        }
        //if the owner changes from one of the queues to a user (round robin), kick off approval process
        else if(level1!=null && oldRT.OwnerId == level1 && String.valueOf(newRt.OwnerId).startsWith('005') && newRt.Ready_for_Approval__c && !newRt.Ready_for_Approval_2__c && !oldRt.Ready_for_Approval_2__c && !newRt.Ready_for_Approval_3__c && !oldRt.Ready_for_Approval_3__c){
            system.debug('in step1');
            Approval.ProcessSubmitRequest step1 = new Approval.ProcessSubmitRequest();
            step1.setObjectId(newRT.id);
            step1.setProcessDefinitionNameOrId('Wire_Approval_Process_Step_1');
            Approval.ProcessResult result = Approval.process(step1);
        }
        else if(level1!=null && oldRT.OwnerId == level1 && String.valueOf(newRt.OwnerId).startsWith('005') && newRt.Ready_for_Approval__c && newRt.Ready_for_Approval_2__c && !newRt.Ready_for_Approval_3__c && !oldRt.Ready_for_Approval_3__c){
            Approval.ProcessSubmitRequest step2 = new Approval.ProcessSubmitRequest();
            step2.setObjectId(newRT.id);
            step2.setProcessDefinitionNameOrId('Wire_Approval_Process_Step_2');
            Approval.ProcessResult result = Approval.process(step2);
        }
        else if(level2!=null && oldRT.OwnerId == level2 && String.valueOf(newRt.OwnerId).startsWith('005') && newRt.Ready_for_Approval__c && newRt.Ready_for_Approval_2__c && newRt.Ready_for_Approval_3__c){
            Approval.ProcessSubmitRequest step3 = new Approval.ProcessSubmitRequest();
            step3.setObjectId(newRT.id);
            step3.setProcessDefinitionNameOrId('Wire_Approval_Process_Step_3');
            Approval.ProcessResult result = Approval.process(step3);
        }
        
        /*if(newRT.OwnerId!=oldRT.OwnerId && !queueMap.isEmpty()){
            Group queue = queueMap.get(oldRT.OwnerId);
            if(queue!= null){
                
            }
        }*/
    }
    if(!updateOwnerMap.isEmpty()){
        ReferenceUpdateCase.updateCaseOwner(updateOwnerMap);
    }
}