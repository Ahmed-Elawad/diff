/* 
 * Controller for the MassEditTasksPage.
 *
 * History
 * -------
 * 10/14/2015 Justin Stouffer   Created
 * 11/16/2018 Josh cartwright added outcome to page - lightning project 
 * 03/10/2020 Saketh added PEO managers and admins to add the ability to use Mass Edit Tasks
 */
 public with sharing class MassEditTasksController {

    public integer numberOfSelected {get;set;}
    public integer numberOfEventsSelected {get;set;}
    public string tskId;
    private Date BTTFDate;
    public task emptyTask {get;set;}
    public List<Task> listOfTasks {get;set;}
    public boolean appendComment {get;set;}
    public boolean AssignedTask{get;set;}
     public boolean tasksSelected{get;set;}
    
    public MassEditTasksController() {
        appendComment = TRUE;
        //BTTFDate = Date.newinstance(1955, 11, 05);
        BTTFDate = System.today();
        emptyTask = new task();
        emptyTask.Status = '-Select a New Value-';
        emptyTask.Subject = 'Enter a New Subject Here';
        emptyTask.Description = 'Enter a New Comment Here';
        //emptyTask.ActivityDate = BTTFDate;
        emptyTask.OwnerId = null; //UserInfo.getUserId();
        emptyTask.Type = '';
        emptyTask.Lead_Source_WAR_Call_Type__c = '';
        emptyTask.Priority = '-Select a New Value-';
        emptyTask.CPE_Topic__c = '-Select a New Value-';
        emptyTask.TAP_Topic__c = '-Select a New Value-';
        emptyTask.Priority = '-Select a New Value-';
        emptyTask.Outcome__c = 'Add an Outcome'; 
        listOfTasks = new List<Task>();
        //List of Ids  
        set<id> ids = new set<id>();  
        //Fetch Ids from URL  
        tskId = ApexPages.currentPage().getParameters().get('id');   
        System.debug(tskId);
        //Split string of Ids
        if(tskId != NULL){  
            numberOfEventsSelected =0; 
            
            for(String str : tskId.split(',')) {  
                ids.add(str);  
                Id recordId = (Id) str;
                if(recordId.getSobjectType() == Event.getSobjectType()){
                    numberOfEventsSelected++; 

                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Mass_Edit_Tasks_Event_Error));

                }//if
                
             
            } //for 
            

            
            //Query  
            String profileName=[select id,profile.name from user where id=:UserInfo.getUserId()].profile.name;
            if(profileName=='Core Sales Administration'||profileName=='Core Sales Administration - SB'||profileName=='Core Zone Administration'||profileName=='Core Zone Administration - SB'||profileName=='HNBF Sales Administration - SB'||profileName=='HNBF Sales Administration'||profileName=='HRS Regional Sales Admin - SB'||profileName=='HRS Sales Administration - SB'||profileName=='MMS Sales DSA - SB'||profileName=='MMS Sales ZSA'||profileName=='MMS Sales ZSA - SB'||profileName=='System Administrator'||profileName=='Salesforce Support'
            ||profileName=='Core Manager - SB'||profileName=='Core Manager'||profileName=='HNBF Sales Manager - SB'||profileName=='HNBF Sales Manager'||profileName=='HRS Sales Manager - SB'||profileName=='MMS Manager - SB'||profileName=='MSP Manager' ||profileName=='Sales Data Steward' || profileName=='Sales Enablement' || profileName=='HRS PEO Centric Administration' || profileName=='HRS PEO Sales Manager'){
            listOfTasks = [Select Id,
                                CallType,
                                Lead_Source_WAR_Call_Type__c,
                                CPE_Topic__c,
                                TAP_Topic__c,
                                WhoId,
                                WhatId, 
                                subject,
                                Outcome__c,
                                status,
                                ActivityDate,
                                type,
                                Description,
                                Priority,
                                OwnerId,
                                Task_Duration__c
                                From Task Where Id in :ids order by ActivityDate]; 
                 AssignedTask=true;
                 System.debug('System admin');
                 
             }             
             else{
            listOfTasks = [Select Id,
                                CallType,
                                Lead_Source_WAR_Call_Type__c,
                                CPE_Topic__c,
                                TAP_Topic__c,
                                WhoId,
                                WhatId, 
                                subject,
                                Outcome__c, 
                                status,
                                ActivityDate,
                                type,
                                Description,
                                Priority,
                                OwnerId,
                                Task_Duration__c
                                From Task Where Id in :ids and OwnerId=:UserInfo.getUserId() order by ActivityDate]; 
        AssignedTask=false;
                         System.debug('System admin');

                }
        }
        
        System.debug(listOfTasks);        
        numberOfSelected = listOfTasks.size();
        
        If (numberOfEventsSelected>0 && numberOfSelected>0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The '+ numberOfEventsSelected + ' Event(s) you selected will not be processed. The '+ numberofSelected + ' task(s) you selected will be processed!'));

        }// if 
        
        if(numberOfEventsSelected>0 && numberOfSelected ==0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'You must Select at least one task')); 
        }//if
        
        tasksSelected =numberOfSelected>0; 
    }
    
    public void setTaskValues(){
        try{
            for(task tsk : listOfTasks){
                if(emptyTask.subject != 'Enter a New Subject Here'){tsk.subject = emptyTask.subject;}
                if(emptyTask.status != '-Select a New Value-'){tsk.status = emptyTask.status;}
                if(emptyTask.ActivityDate != null){tsk.ActivityDate = emptyTask.ActivityDate;}
                if(emptyTask.type != NULL){tsk.type= emptyTask.type;}
                if(emptyTask.Description != 'Enter a New Comment Here'){tsk.Description = (appendComment ? tsk.Description + '\n' + emptyTask.Description : emptyTask.Description);}
                if(emptyTask.Priority != '-Select a New Value-'){tsk.Priority = emptyTask.Priority;}
                if(emptyTask.OwnerId != NULL){tsk.OwnerId = emptyTask.OwnerId;} 
                if(emptyTask.Lead_Source_WAR_Call_Type__c != NULL){tsk.Lead_Source_WAR_Call_Type__c = emptyTask.Lead_Source_WAR_Call_Type__c;} 
                if(emptyTask.CPE_Topic__c != '-Select a New Value-'){tsk.CPE_Topic__c = emptyTask.CPE_Topic__c;} 
                if(emptyTask.TAP_Topic__c != '-Select a New Value-'){tsk.TAP_Topic__c = emptyTask.TAP_Topic__c;}  
                if(emptyTask.Outcome__c != 'Add an Outcome') {tsk.Outcome__c = emptyTask.Outcome__c;}
            }
        }
        catch(exception ex){
             ApexPages.addMessages(ex);       
        }
    }
    
    public pageReference commitChanges(){
        if(!listOfTasks.isEmpty()){
            update listOfTasks;
        }
        PageReference pageRef = new PageReference('/apex/MassEditTasksPage?Id=' + tskId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public pageReference commitChangesAndReturn(){
        if(!listOfTasks.isEmpty()){
            update listOfTasks;
        }       
        //PageReference pageRef = new PageReference('/one/one.app#/n/Mass_Edit');
        PageReference pageRef = new PageReference('/lightning/n/Mass_Edit') ;  
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public pageReference cancel(){
         //PageReference pageRef = new PageReference('/one/one.app#/n/Mass_Edit');
         PageReference pageRef = new PageReference('/lightning/n/Mass_Edit') ;  
         pageRef.setRedirect(true);
         return pageRef;  
    }    
}