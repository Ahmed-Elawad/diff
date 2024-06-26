/* Server-side controller for OpptyTeam bundle
 * 
 * 11/07/2018 Lynn Michels  Created for OpptyTeam aura bundle
 * 07/06/2020  Jacob Hinds         Added without sharing per PMD
   01/04/2022 Dan Carmen           Change to fix the tests

 */ 
public without sharing class OpptyTeamController {
 
    @AuraEnabled
    public static User getRunningUser() {
        User runningUser = new User();
        runningUser = UserHelper.getRunningUser();
            system.debug('OpptyTeamController getRunningUser '+runningUser);
        return runningUser;
    }//end getRunningUserProfile
    
    
    @AuraEnabled
    public static List<User> getAllActiveUsers(string SearchName){
        List<User> users = new List<User>();
        Set<String> validProfiles = new Set<String>();
        List<Profile_List__c> profileDataSet = Profile_List__c.getall().values();
    
        system.debug('OpptyTeamController getAllActiveUsers validProfiles ' +validProfiles);
        try {
            if(!profileDataSet.isEmpty()){
                for (Profile_List__c pl : profileDataSet){
                    if(pl.OppTeamMember_Roles__c != null){
                        validProfiles.add(pl.Profile_Name__c);
                    }
                   
                }
            }//end if profileDataSet.isEmpty()
            
                users= [SELECT Id
                            ,Name
                            ,Profile.name
                            ,UserRole.name 
                    FROM User
                    WHERE IsActive = true
                    AND Profile.name IN: validProfiles
                    AND UserRoleId != null
                    AND Name LIKE :'%' + SearchName + '%'
                    ORDER BY Name
                    LIMIT 100];
            
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
        return users;
    }
    
    @AuraEnabled
    //return the list of roles that is set up for this profile
    //roles are saved in Profile_List custom setting
    public static List<String> getRoleList(String profileName){ 
        Profile_List__c profileDataSet = Profile_List__c.getValues(profileName);
        List<String> roleOptions = new List<String>();
       
        if(profileDataSet != null){
            if (profileDataSet.OppTeamMember_Roles__c != null){
                system.debug('getRoleList profileDataSet ' +profileDataSet.OppTeamMember_Roles__c);
                List<String> teamRoles = profileDataSet.OppTeamMember_Roles__c.split(',');
                for(String role : teamRoles){
                    roleOptions.add(role);
                }//end for
            }//end if oppTeamMember_Roles__c !=null
            
        }//end if profile was found
       
        return roleOptions;
   }//end getRoleList
    
   
    @AuraEnabled
    public static List<OpportunityTeamMember> checkCurrentTeamMembers(id uId, id opptyId){
        List<OpportunityTeamMember> teamMembers = new List<OpportunityTeamMember>();
        teamMembers = [SELECT Id, userId, opportunityId FROM OpportunityTeamMember
                                                    WHERE IsDeleted = false
                                                    AND OpportunityId =: opptyId
                                                    AND userId =: uId LIMIT 1];
        return teamMembers;
     }
    
    @AuraEnabled
    public static void addTeamMember (id userId, string roleSelected, id opptyId){
        OpportunityTeamMember otmCreate = new OpportunityTeamMember(UserId = userId,
                                      OpportunityId = opptyId,
                                      TeamMemberRole = roleSelected,
                                      OpportunityAccessLevel = 'Edit');
        List<OpportunityTeamMember> toAdd = new List<OpportunityTeamMember>();
        toAdd.add(otmCreate);
        DmlHelper.performDML2(toAdd, DmlHelper.DML_INSERT, 'opptyTeamController', 'addTeamMember', 'addTeamMember', true);
    }

    @AuraEnabled
    public static void deleteTeamMember (id memberToDelete, id uid, id oId){
        system.debug('OpptyTeamController deleteTeamMember ' +memberToDelete);
        system.debug('OpptyTeamController uid ' +uid);
        system.debug('OpptyTeamController oId ' +oId);
        
 //       List<OpportunitySplit> os = [SELECT Id, OpportunityId, SplitOwnerId FROM OpportunitySplit
 //                                    WHERE OpportunityId =: oId
 //AND SplitOwnerId =: uid];
        
 //       system.debug('OpptyTeamController OpportunitySplit ' + os);
        
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.id = memberToDelete;
        
        List<OpportunityTeamMember> toDelete = new List<OpportunityTeamMember>();
        toDelete.add(otm);
        
        //delete Opportunity split records before a team member can be deleted
  //      if(!os.isEmpty()){
  //          DmlHelper.performDML2(os, DmlHelper.DML_DELETE, 'opptyTeamController', 'deleteTeamMember', 'delete Opp Split records', true);
  //       }  
        
       if(!toDelete.isEmpty()){
            DmlHelper.performDML2(toDelete, DmlHelper.DML_DELETE, 'opptyTeamController', 'deleteTeamMember', 'delete opp team member', true);
        }   
    }
  }