/* 
 * Controller for managing the assignment groups.
   Allow supervisors to add/remove users in their group
   Set users to active/inactive
   System admin functions:
      Add new assignment groups
      Add/Remove queues to assignment group
      Set Manage Group flag
 *
 * History
 * -------
 * 08/11/2011 Dan Carmen        Created.
   08/28/2013 Dan Carmen        Added debugging, increased API version to 28
   10/15/2015 Jacob Hinds       Adding Scheduler Functionality
   05/10/2017 Jacob Hinds       Adding Weighting Functionality
   06/27/2017 Jacob Hinds       Adding Role Hierarchy Functionality, removing ESR and Round Robin Custom Setting
   09/14/2017 Jacob Hinds       Fixing role thing for test class
   02/09/2018 Jacob Hinds       Changing getTimes() to start at 5AM
   01/15/2018 Jake Hinds        Changing Scheduler fields from text to time.  Adding ability to toggle night/weekend weighting and copy schedule. Removing old code
   11/30/2023 Dan Carmen        Remove unused assignment group fields.
   12/23/2023 Dan Carmen        Clean up code to use the Time field on the VF page instead of picklist

*/
public without sharing class ManageAsgnGroupsController {

   /** The running user. */     
   public User curUser {get; private set;}

   public Boolean isSystemAdmin {get; private set;}
   
   /** The groups the user has access to to modify. */
   public Assignment_Group_Name__c[] grps = null;
   
   public Map<Id,Assignment_Group_Name__c> assignmentGroupMap = null;
   
   public Boolean isManager {get; private set;}
    
   public Boolean manageSelfOnly {get; private set;}
   
   public String selectedGroupId {get;set;}
   
   public Assignment_Group_Name__c selectedGroup {get;set;}
   
   //list of group members for table
   public List<SelectorWrap> memberList{get;set;}
   
   //used for Copy Schedule Section
   public List<SelectOption> memberCopyList{get;set;}
   public String selectedCopyMember{get;set;}
   
   //used for Manager Filter Section
   public List<SelectOption> managerIdList{get;set;}
   public String managerFilterId{get;set;}
   
   /** Default constructor. */
   public ManageAsgnGroupsController() {
      // get the profile of the user
          curUser = new UserHelper().getUserById(UserInfo.getUserId());

      // if system admin can see all
      isSystemAdmin = (curUser.Profile.Name == 'System Administrator');
      
      // if not system admin, see if they have manage access to any groups
      getGroupNames();
      // set the first group to be selected
      if (hasGroups) {
         //selectedGroupId = grps[0].Id;
         selectedGroupId = assignmentGroupMap.values()[0].Id;
         selectGroup(true);
         system.debug('selectedGroup: '+ selectedGroup.Name);
      }
          
   } // ManageAsgnGroupsController
   
   /** Does the running user have any groups to manage? */
   public Boolean hasGroups{
      //get {return (grps != null && !grps.isEmpty()); }
      get {return (assignmentGroupMap != null && !assignmentGroupMap.values().isEmpty()); }
   } // hasGroups
   
   /** Get the groups the user can manage.
    */
   public void getGroupNames(){
      manageSelfOnly = FALSE;
      if (!isSystemAdmin) {
             // get the records the user has direct access to
         assignmentGroupMap = new Map<Id,Assignment_Group_Name__c>([SELECT Id, Name, Use_Role_Hierarchy__c,Use_Scheduler__c,Use_Weighting__c,Use_Manager_Filter__c FROM Assignment_Group_Name__c WHERE Id IN 
                    (SELECT Group_Name__c FROM Assignment_Groups__c WHERE User__c = :curUser.Id AND Manage_Group__c = true)
                ORDER BY NAME]);
      } else {
           // get all groups
         assignmentGroupMap = new Map<Id,Assignment_Group_Name__c>([SELECT Id, Name, Use_Role_Hierarchy__c,Use_Scheduler__c,Use_Weighting__c,Use_Manager_Filter__c FROM Assignment_Group_Name__c ORDER BY NAME]);
      }
      if(assignmentGroupMap == null || assignmentGroupMap.isEmpty()){
         manageSelfOnly = TRUE;
         assignmentGroupMap = new Map<Id,Assignment_Group_Name__c>([SELECT Id, Name, Use_Role_Hierarchy__c,Use_Scheduler__c,Use_Weighting__c,Use_Manager_Filter__c FROM Assignment_Group_Name__c WHERE Id IN 
                    (SELECT Group_Name__c FROM Assignment_Groups__c WHERE User__c = :curUser.Id AND Manage_Self__c = true)
                ORDER BY NAME]);
       }
       system.debug('assignmentGroupMap'+assignmentGroupMap);
   }
   
   /** Get the package options displayed on the screen. */  
   public List<SelectOption> groupOptions {
      get {
         List<SelectOption> options = new List<SelectOption>();

         if (hasGroups) {
            for (Id grpId : assignmentGroupMap.keySet()) {
               options.add(new SelectOption(grpId,assignmentGroupMap.get(grpId).Name));
            } // for (Assignment_Group_Name__c
         } // if (hasGroups
         return options;
      } // get
   } // groupOptions
   
   /** Change the selected Group.
    */
   public PageReference changeGroup() {
      System.debug('changeGroup');
      selectGroup(true);
      return null;
   } // changeGroup
   
   public PageReference changeManager(){
      System.debug('changeManager');
      selectGroup(false);
      return null;
   }
   
   public void selectGroup(Boolean resetManagerFilter) {
      System.debug('selectGroup selectedGroupId='+selectedGroupId);
      getSelectedGroup();
      System.debug('selectGroup selectedGroupId='+selectedGroupId+' selectedGroup='+selectedGroup);
      setupMemberList(resetManagerFilter);
   } // selectGroup
   
   public void getSelectedGroup() {
      Boolean managerFilter = (assignmentGroupMap!=null && assignmentGroupMap.containsKey(selectedGroupId) 
                                && assignmentGroupMap.get(selectedGroupId).Use_Manager_Filter__c && String.IsNotBlank(managerFilterId));
      
      String query = '';
      
      //main ag fields
      query = 'SELECT Id,Current_Weighting_Round__c,Current_Weighting_Round_Time__c ,Round_Robin_Delegate__c, Name, Count_of_Users__c,ScheduleAllHours__c,';
      query += 'Use_Role_Hierarchy__c,Use_Scheduler__c,Use_Weighting__c,Use_Manager_Filter__c,Weekday_Start__c,Weekday_End__c,';
      query += 'Weekend_Start__c,Weekend_End__c,Weekend_Always_On__c';
      //subselect for group member
      query += ',(SELECT Id, Active__c,User_Active__c,Group_Name__c,Status__c,User__c,User__r.Name,User__r.UserRoleId,User__r.ManagerId,User__r.Manager.Name,Manage_Group__c,Manage_Self__c';
      query += ',Skill_Set__c,Weighting_Level__c';
      query += ',Monday_1__c,Monday_2__c,Monday_3__c,Monday_4__c,Tuesday_1__c,Tuesday_2__c,Tuesday_3__c,Tuesday_4__c,Wednesday_1__c,Wednesday_2__c,Wednesday_3__c,Wednesday_4__c';
      query += ',Thursday_1__c,Thursday_2__c,Thursday_3__c,Thursday_4__c,Friday_1__c,Friday_2__c,Friday_3__c,Friday_4__c,Saturday_1__c,Saturday_2__c,Saturday_3__c,Saturday_4__c';
      query += ',Sunday_1__c,Sunday_2__c,Sunday_3__c,Sunday_4__c';
      query += ' FROM Assignment_Groups__r';
      //WHERE clause for subselect of group member - should only hit if manager filter is used
      if(managerFilter){query+=' WHERE User__r.ManagerId = \'' + managerFilterId + '\'';}
      if(manageSelfOnly){query+=' WHERE User__c = \''+curUser.Id +'\' AND Manage_Self__c = true';}
      query += ' ORDER BY User__r.LastName)'; //end of group members subselect
      //subselect for ag-queue link
      query += ',(SELECT Id, Name, QueueId__c,Active__c, Valid_Queue__c FROM Assignment_Group_Queues__r)'; //end of queue link subselect
      query += 'FROM Assignment_Group_Name__c WHERE Id = \''+ selectedGroupId+'\' LIMIT 1';
      
      system.debug('query'+query);
      if(string.IsNotBlank(query)){
        selectedGroup = Database.query(query);
      }
   } // getSelectedGroup
   
   /** Get the weighting options displayed on the screen. */  
   public List<SelectOption> weightingOptions {
      get {
         List<SelectOption> options = new List<SelectOption>();

         Schema.DescribeFieldResult statusFieldDescription = Assignment_Groups__c.Weighting_Level__c.getDescribe();
         for (Schema.Picklistentry picklistEntry : statusFieldDescription.getPicklistValues())
         {
            options.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));
         }

         return options;
      } // get
   } // weightingOptions
   
   public void setupMemberList(Boolean resetManagerFilter) {
      memberList = null;
      memberCopyList = null;
      if(resetManagerFilter){
        managerIdList = null;
      }
      Map<Id,String> managerIdMap = new Map<Id,String>();
      
      if (selectedGroup != null && selectedGroup.Assignment_Groups__r != null && !selectedGroup.Assignment_Groups__r.isEmpty()) {
         memberList = new List<SelectorWrap>();
         Map<Id,UserRole> roleMap;
         
         //exclude certain profiles from role hierarchy check so they don't break the cache.  Used for profiles high in the hierarchy.
         String[] exceptionList = Label.MngAsgnGroupExceptionProfs.split(';');
         Set<String> exceptionSet = new Set<String>();
         exceptionSet.addAll(exceptionList);
         Boolean isExceptionProf = (exceptionSet!=null && exceptionSet.contains(curUser.Profile.Name)?true:false);
         
         //if assignment group uses role hierarchy, get map of all roles beneath running user
         if(!isSystemAdmin && !isExceptionProf && selectedGroup.Use_Role_Hierarchy__c){
            Id userRoleId = UserInfo.getUserRoleId();
            /*String cacheKey = 'ChildrenOfRoleId'+userRoleId;
            Object cacheObj = (!Utilities.SKIP_CACHE ? Cache.Org.get(cacheKey) : null);
            System.debug('cacheKey='+cacheKey+' cacheObj='+(cacheObj != null));
            if (cacheObj != null) {
                roleMap = (cacheObj!=null?(Map<Id,UserRole>)cacheObj:null);
            }*/
            if(roleMap==null){
                roleMap = UserHelper.getUserRoleByIdMap(userRoleId);
                /*if(!Utilities.SKIP_CACHE && !Test.isRunningTest()){
                    Cache.Org.put(cacheKey,roleMap);
                }*/
            }
         }
         system.debug('roleMap'+roleMap);
         //setup copy schedule options
         if(selectedGroup.Use_Scheduler__c){
            memberCopyList = new List<SelectOption>();
            memberCopyList.add(new SelectOption('','--None--'));
            memberCopyList.add(new SelectOption('All','All'));
         }
         for (Assignment_Groups__c ag : selectedGroup.Assignment_Groups__r) {
            SelectorWrap sw = new SelectorWrap(ag);
            if((roleMap!=null && (roleMap.containsKey(ag.User__r.UserRoleId) || ag.User__c == curUser.Id)) || roleMap==null){
                /*
                sw.monday1 = convertTimeToString(ag.Monday_1__c);
                sw.monday2 = convertTimeToString(ag.Monday_2__c);
                sw.monday3 = convertTimeToString(ag.Monday_3__c);
                sw.monday4 = convertTimeToString(ag.Monday_4__c);
                
                sw.tuesday1 = convertTimeToString(ag.Tuesday_1__c);
                sw.tuesday2 = convertTimeToString(ag.Tuesday_2__c);
                sw.tuesday3 = convertTimeToString(ag.Tuesday_3__c);
                sw.tuesday4 = convertTimeToString(ag.Tuesday_4__c);
                
                sw.wednesday1 = convertTimeToString(ag.Wednesday_1__c);
                sw.wednesday2 = convertTimeToString(ag.Wednesday_2__c);
                sw.wednesday3 = convertTimeToString(ag.Wednesday_3__c);
                sw.wednesday4 = convertTimeToString(ag.Wednesday_4__c);
                
                sw.thursday1 = convertTimeToString(ag.Thursday_1__c);
                sw.thursday2 = convertTimeToString(ag.Thursday_2__c);
                sw.thursday3 = convertTimeToString(ag.Thursday_3__c);
                sw.thursday4 = convertTimeToString(ag.Thursday_4__c);
                
                sw.friday1 = convertTimeToString(ag.Friday_1__c);
                sw.friday2 = convertTimeToString(ag.Friday_2__c);
                sw.friday3 = convertTimeToString(ag.Friday_3__c);
                sw.friday4 = convertTimeToString(ag.Friday_4__c);
                
                sw.saturday1 = convertTimeToString(ag.Saturday_1__c);
                sw.saturday2 = convertTimeToString(ag.Saturday_2__c);
                sw.saturday3 = convertTimeToString(ag.Saturday_3__c);
                sw.saturday4 = convertTimeToString(ag.Saturday_4__c);
                
                sw.sunday1 = convertTimeToString(ag.Sunday_1__c);
                sw.sunday2 = convertTimeToString(ag.Sunday_2__c);
                sw.sunday3 = convertTimeToString(ag.Sunday_3__c);
                sw.sunday4 = convertTimeToString(ag.Sunday_4__c);
                */
                memberList.add(sw);
                /*
                system.debug('sw'+sw.tuesday1);
                system.debug('sw'+sw.tuesday2);
                system.debug('sw'+sw.tuesday3);
                system.debug('sw'+sw.tuesday4);
                */
                if(ag.User__c == curUser.Id && ag.Manage_Group__c){
                    isManager = true;
                }
            }
            
            //add to list of copy schedule options
            if(memberCopyList!=null){
                memberCopyList.add(new SelectOption(ag.User__c,ag.User__r.Name));
            }
            //setup manager filter options
            if(selectedGroup.Use_Manager_Filter__c && !managerIdMap.containsKey(ag.User__r.ManagerId)){
                managerIdMap.put(ag.User__r.ManagerId,ag.User__r.Manager.Name);
            }
         }
         for(Id managerId : managerIdMap.keySet()){
            if(managerIdList==null && resetManagerFilter){
                managerIdList = new List<SelectOption>();
                managerIdList.add(new SelectOption('','All'));
                managerIdList.add(new SelectOption(managerId,managerIdMap.get(managerId)));
            }
            else if(resetManagerFilter){
                managerIdList.add(new SelectOption(managerId,managerIdMap.get(managerId)));
            }
         }
      } // if (selectedGroup
      
      newMember = null;
      if (selectedGroup != null) {
         newMember = new Assignment_Groups__c(Group_Name__c=selectedGroup.Id);
      }
   } // setupMemberList
   
   /** Does the selected group have any members? */
   public Boolean hasMembers {
      get { return (selectedGroup != null && memberList != null && !memberList.isEmpty()); }
   } // hasMembers
   
   /* Displays the scheduler if the assignment group has the custom setting value checked */    
   public Boolean useScheduler{
        get {return selectedGroup.Use_Scheduler__c;}
   }
   
   /* Displays the scheduler if the assignment group has the custom setting value checked */    
   public Boolean useManagerFilter{
        get {return selectedGroup.Use_Manager_Filter__c;}
   }
   /*
   //builds list for the scheduler
   public List<SelectOption> getTimes(){
        List<SelectOption> op = new List<SelectOption>();
        
        //default value
        op.add(new SelectOption('','--None--'));
        
        //for 7:00AM to 11:45AM
        for(Integer i=5;i<12;i++){
                op.add(new SelectOption(String.valueOf(i)+'00',String.valueOf(i)+':00 AM'));
                op.add(new SelectOption(String.valueOf(i)+'15',String.valueOf(i)+':15 AM'));
                op.add(new SelectOption(String.valueOf(i)+'30',String.valueOf(i)+':30 AM'));
                op.add(new SelectOption(String.valueOf(i)+'45',String.valueOf(i)+':45 AM'));
        }
        
        //for Noon to 12:45
            op.add(new SelectOption('1200','12:00 PM'));
                op.add(new SelectOption('1215','12:15 PM'));
                op.add(new SelectOption('1230','12:30 PM'));
                op.add(new SelectOption('1245','12:45 PM'));
                
        //for 1:00PM to 11:45PM
        for(Integer j=1;j<12;j++){
                op.add(new SelectOption(String.valueOf(j+12)+'00',String.valueOf(j)+':00 PM'));
                op.add(new SelectOption(String.valueOf(j+12)+'15',String.valueOf(j)+':15 PM'));
                op.add(new SelectOption(String.valueOf(j+12)+'30',String.valueOf(j)+':30 PM'));
                op.add(new SelectOption(String.valueOf(j+12)+'45',String.valueOf(j)+':45 PM'));
        }
        system.debug('op'+op);
        return op;
   }
   */
   public PageReference saveSchedule() {
      update selectedGroup.Assignment_Groups__r;
      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Schedule Saved!'));
      return null;
   } // saveSchedule2
   /*
   //saves the updated field values in the scheduler
   public PageReference saveSchedule() {
           Assignment_Groups__c[] updateRecords = new Assignment_Groups__c[]{};
           Boolean inactiveWarning=false;
           for(SelectorWrap sw:memberList){
                Assignment_Groups__c gm = sw.groupMember;
                gm.Monday_1__c = convertSelectToTime(sw.monday1);
                gm.Monday_2__c = convertSelectToTime(sw.monday2);
                gm.Monday_3__c = convertSelectToTime(sw.monday3);
                gm.Monday_4__c = convertSelectToTime(sw.monday4);
                
                gm.Tuesday_1__c = convertSelectToTime(sw.tuesday1);
                gm.Tuesday_2__c = convertSelectToTime(sw.tuesday2);
                gm.Tuesday_3__c = convertSelectToTime(sw.tuesday3);
                gm.Tuesday_4__c = convertSelectToTime(sw.tuesday4);
                
                gm.Wednesday_1__c = convertSelectToTime(sw.wednesday1);
                gm.Wednesday_2__c = convertSelectToTime(sw.wednesday2);
                gm.Wednesday_3__c = convertSelectToTime(sw.wednesday3);
                gm.Wednesday_4__c = convertSelectToTime(sw.wednesday4);
                
                gm.Thursday_1__c = convertSelectToTime(sw.thursday1);
                gm.Thursday_2__c = convertSelectToTime(sw.thursday2);
                gm.Thursday_3__c = convertSelectToTime(sw.thursday3);
                gm.Thursday_4__c = convertSelectToTime(sw.thursday4);
                
                gm.Friday_1__c = convertSelectToTime(sw.friday1);
                gm.Friday_2__c = convertSelectToTime(sw.friday2);
                gm.Friday_3__c = convertSelectToTime(sw.friday3);
                gm.Friday_4__c = convertSelectToTime(sw.friday4);
                
                gm.Saturday_1__c = convertSelectToTime(sw.saturday1);
                gm.Saturday_2__c = convertSelectToTime(sw.saturday2);
                gm.Saturday_3__c = convertSelectToTime(sw.saturday3);
                gm.Saturday_4__c = convertSelectToTime(sw.saturday4);
                
                gm.Sunday_1__c = convertSelectToTime(sw.sunday1);
                gm.Sunday_2__c = convertSelectToTime(sw.sunday2);
                gm.Sunday_3__c = convertSelectToTime(sw.sunday3);
                gm.Sunday_4__c = convertSelectToTime(sw.sunday4);
                
                if(!inactiveWarning){
                        inactiveWarning = (gm.Active__c == 'True' ? false : true);
                }
                system.debug('gm'+gm);
                updateRecords.add(gm);
           }//for
           
           if(!updateRecords.isEmpty()){
                   SObjectHelper soHelper = new SObjectHelper();
                   soHelper.saveRecords(updateRecords,null,null);
                   if(!ApexPages.hasMessages(ApexPages.Severity.ERROR)){
                      if(inactiveWarning){
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Schedule saved, but one or more users are inactive.  Please make sure scheduled users are active!'));
                           }
                           else{
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Schedule Saved!'));
                           }
                   }
           }
      return null;
   } // saveSchedule
   
   public Time convertSelectToTime(String timeString){
        Time returnTime;
        if(String.isNotBlank(timeString)){
            if(timeString.length() == 3){timeString = '0'+timeString;}
            returnTime = time.newInstance(Integer.valueOf(timeString.left(2)),Integer.valueOf(timeString.right(2)),0,0);
            system.debug(returnTime);
        }
        return returnTime;
   }
   
   public String convertTimeToString(Time timeValue){
        String returnString;
        if(timeValue!=null){
            String hour = String.valueOf(timeValue.hour());
            //if(hour.length()==1){hour = '0'+hour;}
            String minute = String.valueOf(timeValue.minute());
            if(minute.length()==1){minute = '0'+minute;}
            returnString = hour+minute;
        }
        else{
            returnString = '';
        }
        return returnString;
   }
   */
   public PageReference copySchedule(){
      if (selectedGroup!=null && String.isNotBlank(selectedCopyMember)){
         
         Map<Id,Assignment_Groups__c> groupMemberByUserId = new Map<Id,Assignment_Groups__c>();
         for (Assignment_Groups__c userInSelectedAG : selectedGroup.Assignment_Groups__r) {
            if(selectedCopyMember == 'All' || userInSelectedAG.User__c == selectedCopyMember) {
               groupMemberByUserId.put(userInSelectedAG.User__c,userInSelectedAG);
            }
               //else if(userInSelectedAG.User__c == selectedCopyMember){
                //    currentAG = userInSelectedAG;
                //}
                
         } // for (Assignment_Groups__c userInSelectedAG
         Assignment_Groups__c[] allGroupMemberRecords = [SELECT Id,User__c FROM Assignment_Groups__c WHERE User__c in :groupMemberByUserId.keySet() AND Group_Name__c != :selectedGroup.Id];
            
            //if(selectedCopyMember == 'All'){
            //    allGroupMemberRecords= [SELECT Id,User__c FROM Assignment_Groups__c WHERE User__c in :groupMemberByUserId.keySet() AND Group_Name__c != :selectedGroup.Id];
           // }
           // else{
           //     allGroupMemberRecords= [SELECT Id,User__c FROM Assignment_Groups__c WHERE User__c = :currentAG.User__c AND Id != :currentAG.Id];
            //}
         for(Assignment_Groups__c ag: allGroupMemberRecords){
            Assignment_Groups__c currentAG = groupMemberByUserId.get(ag.User__c);
            if (currentAG != null) {
                //if(selectedCopyMember == 'All' && groupMemberByUserId != null && groupMemberByUserId.containsKey(ag.User__c)){
                //    currentAG = groupMemberByUserId.get(ag.User__c);
                //}
               ag.Monday_1__c = currentAG.Monday_1__c;
               ag.Monday_2__c = currentAG.Monday_2__c;
               ag.Monday_3__c = currentAG.Monday_3__c;
               ag.Monday_4__c = currentAG.Monday_4__c;
                
               ag.Tuesday_1__c = currentAG.Tuesday_1__c;
               ag.Tuesday_2__c = currentAG.Tuesday_2__c;
               ag.Tuesday_3__c = currentAG.Tuesday_3__c;
               ag.Tuesday_4__c = currentAG.Tuesday_4__c;
                
               ag.Wednesday_1__c = currentAG.Wednesday_1__c;
               ag.Wednesday_2__c = currentAG.Wednesday_2__c;
               ag.Wednesday_3__c = currentAG.Wednesday_3__c;
               ag.Wednesday_4__c = currentAG.Wednesday_4__c;
                
               ag.Thursday_1__c = currentAG.Thursday_1__c;
               ag.Thursday_2__c = currentAG.Thursday_2__c;
               ag.Thursday_3__c = currentAG.Thursday_3__c;
               ag.Thursday_4__c = currentAG.Thursday_4__c;
                
               ag.Friday_1__c = currentAG.Friday_1__c;
               ag.Friday_2__c = currentAG.Friday_2__c;
               ag.Friday_3__c = currentAG.Friday_3__c;
               ag.Friday_4__c = currentAG.Friday_4__c;
                
               ag.Saturday_1__c = currentAG.Saturday_1__c;
               ag.Saturday_2__c = currentAG.Saturday_2__c;
               ag.Saturday_3__c = currentAG.Saturday_3__c;
               ag.Saturday_4__c = currentAG.Saturday_4__c;
                
               ag.Sunday_1__c = currentAG.Sunday_1__c;
               ag.Sunday_2__c = currentAG.Sunday_2__c;
               ag.Sunday_3__c = currentAG.Sunday_3__c;
               ag.Sunday_4__c = currentAG.Sunday_4__c;
           } // if (currentAG != null

        } // for(Assignment_Groups__c ag: allGroupMemberRecords
        DmlHelper.performDML2(allGroupMemberRecords, DmlHelper.DML_UPDATE, 'ManageAsgnGroupsController', 'copySchedule', 'update group members', true);
        //    if(!allGroupMemberRecords.isEmpty()){
        //        SObjectHelper soHelper = new SObjectHelper();
        //        soHelper.saveRecords(allGroupMemberRecords,null,null);
        //    }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'There were '+allGroupMemberRecords.size()+' schedules updated'));
        selectedCopyMember = null;
      } // if (selectedGroup!=null
      return null;
   } // copySchedule
   
   public PageReference saveGroupChanges() {
      update selectedGroup;
      return null;
   } // saveSchedule
   
   /** Does the selected group have any queues? */
   public Boolean hasQueue {
      get { return (selectedGroup != null && selectedGroup.Assignment_Group_Queues__r != null && !selectedGroup.Assignment_Group_Queues__r.isEmpty()); }
   } // hasQueues
   
   /** Will this use weighted round robin? */
   public Boolean isWeighted{
      get {
        return selectedGroup.Use_Weighting__c;
      }
   }
   
   public Boolean selectAll {get;set;}
   
   /** Set all of the members to the selectAll flag.
    */
   public PageReference selectAllMembers() {
          for (SelectorWrap sw : memberList) {
             sw.selected = selectAll;
          } // for
      return null;
   } // selectAllMembers
   
   /** Process all of the selected records. */
   public PageReference processAllSelected() {
          String actionType = System.currentPageReference().getParameters().get('actionType');
          System.debug('in processAllSelected actionType='+actionType);
          //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in processAllSelected actionType='+actionType));
      if (actionType != null) {
         selectAll = false;
             // the records to update
             Assignment_Groups__c[] updateRecords = new Assignment_Groups__c[]{};
             for (Integer cnt=0; cnt < memberList.size(); cnt++) {
                SelectorWrap sw = memberList.get(cnt);
                if (sw.selected) {
               updateRecords.add(sw.groupMember);
                   if (actionType != 'delete') {
                      performAction(actionType,sw.groupMember);
               }
               sw.selected=false;
                } // if (sw.selected
             } // for
             if (!updateRecords.isEmpty()) {
                if (actionType == 'delete') {
                   delete updateRecords;
                   getSelectedGroup();
                   selectGroup(false);
                } else {
                   SObjectHelper soHelper = new SObjectHelper();
                   soHelper.saveRecords(updateRecords,null,null);
                }
             }
      } // if (actionType != null
      return null;
   } // processAllSelected
   
   /** Process only one record. */
   public PageReference processOneRecord() {
      String actionType = System.currentPageReference().getParameters().get('actionType');
      Id memberId = System.currentPageReference().getParameters().get('memberId');
      System.debug('in processOneRecord actionType='+actionType+' memberId='+memberId);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in processOneRecord actionType='+actionType+' memberId='+memberId));
      if (actionType != null && memberId != null) {
         for (Integer cnt=0; cnt < memberList.size(); cnt++) {
            SelectorWrap sw = memberList.get(cnt);
            if (sw.groupMember.Id == memberId) {
               if (actionType == 'delete') {
                  // remove deleted rows
                  delete sw.groupMember;
                  selectGroup(false);
                  
               } 
               else if (actionType == 'changeSkill' || actionType == 'changeWeight') {
                  Assignment_Groups__c[] updateRecords = new Assignment_Groups__c[]{sw.groupMember};
                  SObjectHelper soHelper = new SObjectHelper();
                  soHelper.saveRecords(updateRecords,null,null);
               }
               else {
                  performAction(actionType,sw.groupMember);
                  Assignment_Groups__c[] updateRecords = new Assignment_Groups__c[]{sw.groupMember};
                  SObjectHelper soHelper = new SObjectHelper();
                  soHelper.saveRecords(updateRecords,null,null);
               }
               break;
            } // if
         } // for (Integer
      } // if (actionType != null
      return null;
   } // processOneRecord
   
   /** Perform the specified action on the Assignment_Groups__c record.
    */
   public Boolean performAction(String actionType, Assignment_Groups__c ag) {
      Boolean okay = true;
      if (actionType == 'active') {
         ag.Active__c = (ag.Active__c == 'True' ? 'False' : 'True');
      } else if (actionType == 'manageGroup') {
         ag.Manage_Group__c = !ag.Manage_Group__c;
      } else if (actionType == 'manageSelf') {
         ag.Manage_Self__c = !ag.Manage_Self__c;
      }
          return okay;
   } // performAction
   
   /** The record used for adding a new member to the group.
    */
   public Assignment_Groups__c newMember{get;set;}
   
   /** Add the new member to the group.
    */
   public PageReference addNewMember() {
          // verify user entered
      if (newMember.User__c == null) {
             ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A Valid User must be selected!'));
             return null;
      }
      newMember.Active__c = 'True';
      insert newMember;
      
      //update the newly added user's record to make them active
      User updateUserActive = new User();
      updateUserActive.Id = newMember.User__c;
      updateUserActive.Assignment_Group_Active__c = true;
      update updateUserActive;
      
      selectGroup(false);
      return null;
   } // addNewMember
   
   /** Wrapper to handle selection of items. 
    */
   public Class SelectorWrap {
        
          public Boolean selected {get;set;}
          
          public Assignment_Groups__c groupMember {get;set;}
          /*
          public String monday1 {get;set;}
          public String monday2 {get;set;}
          public String monday3 {get;set;}
          public String monday4 {get;set;}
          
          public String tuesday1 {get;set;}
          public String tuesday2 {get;set;}
          public String tuesday3 {get;set;}
          public String tuesday4 {get;set;}
          
          public String wednesday1 {get;set;}
          public String wednesday2 {get;set;}
          public String wednesday3 {get;set;}
          public String wednesday4 {get;set;}
          
          public String thursday1 {get;set;}
          public String thursday2 {get;set;}
          public String thursday3 {get;set;}
          public String thursday4 {get;set;}
          
          public String friday1 {get;set;}
          public String friday2 {get;set;}
          public String friday3 {get;set;}
          public String friday4 {get;set;}
          
          public String saturday1 {get;set;}
          public String saturday2 {get;set;}
          public String saturday3 {get;set;}
          public String saturday4 {get;set;}
          
          public String sunday1 {get;set;}
          public String sunday2 {get;set;}
          public String sunday3 {get;set;}
          public String sunday4 {get;set;}
          */
          
      /** Constructor. */
      public SelectorWrap(Assignment_Groups__c p_ag) {
         groupMember = p_ag;
         selected = false;
      } // SelectorWrap
      
   } // SelectorWrap
   
} // class ManageAsgnGroupsController