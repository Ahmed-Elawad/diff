/* Methods to setup Chatter group and manage group membership
   
  History
  -------
  04/04/2012 Dan Carmen   Created
  06/11/2012 Dan Carmen   Fix for ownership.
  06/22/2012 Dan Carmen   Checks to make sure that the owner isn't deleted from the group.
  10/28/2014 Dan Carmen   Additional check for owner of a group not being deleted.
  07/17/2015 Dan Carmen   Ability to trigger just one record.
  10/29/2018 Dan Carmen   Increment API to version 44
  
 */
public with sharing class ChatterMethods {

   public static Boolean TRIGGER_EXECUTING=false;

   /** Check for the Org Units and Chatter Groups that are linked to this record. Make sure that all listed are attached. If
       not attach, attach them. Do not remove links if not in the list.
    */
   public static void checkForLinks(Id[] grpIds) {
    // reselect the records
    Chatter_Group_Setup__c[] grps = [Select Id, Name
                                           ,Child_Groups__c
                                           ,Org_Units__c
                                           ,(Select Id, Name, Org_Unit__r.Id, Org_Unit__r.Name from Chatter_Group_Org_Links__r)
                                           ,(Select Id, Name, Child_Group__r.Id, Child_Group__r.Name from Child_Groups__r)
                                       From Chatter_Group_Setup__c
                                      Where Id in :grpIds];
    // check for org units
    checkAddOrgUnits(grps);
    // check for child groups
    checkChildGroups(grps);
   } // checkForLinks
   
   /** Check to see if all of the child groups listed are already added. If not, try to find and add them.
    */
   public static void checkChildGroups(Chatter_Group_Setup__c[] grps) {
      // the names to search for - use a list of ids so we know what to create records for later
      Map<String,List<Id>> missingChildMap = new Map<String,List<id>>();

      for (Chatter_Group_Setup__c grp : grps) {
         if (grp.Child_Groups__c != null) {
            checkForMissingChildren(grp,missingChildMap);
         }
      } // for (Chatter_Group_Setup__c

      // if we have any missing orgs - try to select them.
      if (!missingChildMap.isEmpty()) {
         // new links to insert
         Chatter_Group_Link__c[] insertLinks = new Chatter_Group_Link__c[]{};
         Chatter_Group_Setup__c[] checkGrps = [Select Id, Name
                                     From Chatter_Group_Setup__c
                                    Where Name in :missingChildMap.keySet()];
         for (Chatter_Group_Setup__c cgs : checkGrps) {
            List<Id> grpIds = missingChildMap.get(cgs.Name);
            if (grpIds != null) {
               for (Id grpId : grpIds) {
                  Chatter_Group_Link__c link = new Chatter_Group_Link__c();
                  link.Parent_Group__c = grpId;
                  link.Child_Group__c = cgs.Id;
                  insertLinks.add(link);
               }
            } // if (grpIds != null
         } // for (Org_Unit__c
         
         if (!insertLinks.isEmpty()) {
            insert insertLinks;
         }
      } // if (!missingOrgMap
   } // checkChildGroups
   
   public static void checkForMissingChildren(Chatter_Group_Setup__c grp, Map<String,List<Id>> missingChildMap) {
      // separate into array
      String[] childrenNames = grp.Child_Groups__c.split(';');
      for (String childName : childrenNames) {

         Boolean found = false;
         if (grp.Child_Groups__r != null) {
            for (Chatter_Group_Link__c cgl : grp.Child_Groups__r) {
               if (childName == cgl.Child_Group__r.Name) {
                  found = true;
                  break;
               } // if (orgUnitName
            } // for (Chatter_Group_Org_Link__c
         } // if (grp.Chatter_Group_Org_Links__r
         
         // if the org is not already there, add to the map
         if (!found) {
            List<Id> missingIds = missingChildMap.get(childName);
            if (missingIds == null) {
               missingIds = new List<Id>();
               missingChildMap.put(childName,missingIds);
            }
            missingIds.add(grp.Id);
         } // if (!found
      } // for

   } // checkForMissingChildren
   

   /** Check to see if all of the org units listed are already added. If not, try to find and add them.
    */
   public static void checkAddOrgUnits(Chatter_Group_Setup__c[] grps) {
    // the names to search for - use a list of ids so we know what to create records for later
    Map<String,List<Id>> missingOrgMap = new Map<String,List<id>>();
    
    for (Chatter_Group_Setup__c grp : grps) {
       if (grp.Org_Units__c != null) {
          checkForMissingOrgs(grp,missingOrgMap);
       }
    } // for (Chatter_Group_Setup__c
    
    // if we have any missing orgs - try to select them.
    if (!missingOrgMap.isEmpty()) {
        // new links to insert
        Chatter_Group_Org_Link__c[] insertLinks = new Chatter_Group_Org_Link__c[]{};
        Org_Unit__c[] orgUnits = [Select Id, Name
                                    From Org_Unit__c
                                   Where Name in :missingOrgMap.keySet()
                                     and Org_Type__c = 'Cost Center'];
         for (Org_Unit__c ou : orgUnits) {
            List<Id> grpIds = missingOrgMap.get(ou.Name);
            if (grpIds != null) {
               for (Id grpId : grpIds) {
                  Chatter_Group_Org_Link__c link = new Chatter_Group_Org_Link__c();
                  link.Chatter_Group_Setup__c = grpId;
                  link.Org_Unit__c = ou.Id;
                  insertLinks.add(link);
               }
            } // if (grpIds != null
         } // for (Org_Unit__c
         
         if (!insertLinks.isEmpty()) {
            insert insertLinks;
         }
    } // if (!missingOrgMap
   } //checkAddOrgUnits
   
   public static void checkForMissingOrgs(Chatter_Group_Setup__c grp, Map<String,List<Id>> missingOrgMap) {
      // separate into array
      String[] orgUnitNbrs = grp.Org_Units__c.split(';');
      for (String orgUnitNbr : orgUnitNbrs) {
         // strip off any leading zeroes
         orgUnitNbr = Utilities.removeLeadingZero(orgUnitNbr);
         Boolean found = false;
         if (grp.Chatter_Group_Org_Links__r != null) {
            for (Chatter_Group_Org_Link__c cgol : grp.Chatter_Group_Org_Links__r) {
                if (orgUnitNbr == cgol.Org_Unit__r.Name) {
                   found = true;
                   break;
                } // if (orgUnitName
            } // for (Chatter_Group_Org_Link__c
         } // if (grp.Chatter_Group_Org_Links__r
         
         // if the org is not already there, add to the map
         if (!found) {
            List<Id> missingIds = missingOrgMap.get(orgUnitNbr);
            if (missingIds == null) {
               missingIds = new List<Id>();
               missingOrgMap.put(orgUnitNbr,missingIds);
            }
            missingIds.add(grp.Id);
         } // if (!found
      } // for

   } // checkForMissingOrgs
   
   /** Check the Chatter_Group_Setup__c when it is created.
    */
   public static void checkChatterGroup(Chatter_Group_Setup__c[] grps) {
    //CollaborationGroup[] insertGrps = new CollaborationGroup[]{};
    Map<String, Chatter_Group_Setup__c> grpMap = new Map<String,Chatter_Group_Setup__c>();
    //Map<String, CollaborationGroup> cgMap = new Map<String,CollaborationGroup>();
    
    // names in this trigger should be unique - will not create two groups called Core District 10 for example
    for (Chatter_Group_Setup__c grp : grps) {
        if (grp.Name != null) {
           // verify doesn't already exist
           if (grpMap.containsKey(grp.Name)) {
              // flag this as an error - record will not be processed further
              grp.addError('There is more than one record with the Name '+grp.Name+'. Only one will be processed.');
           } else {
              grpMap.put(grp.Name,grp);
           }
        } // if (grp.Name
        
    } // for (Chatter_Group_Setup__c
    
    // check for records that already exist in the Chatter_Group_Setup__c
    Chatter_Group_Setup__c[] checkSetups = [Select Id, Name, ChatterGroupId__c from Chatter_Group_Setup__c where Name in :grpMap.keySet()];
    // if records are returned then there are duplicates!
    for (Chatter_Group_Setup__c cgs : checkSetups) {
        Chatter_Group_Setup__c checkCgs = grpMap.remove(cgs.Name);
        if (checkCgs != null) {
            String errMsg = 'A record is already saved with the name '+cgs.Name+'. A new record will not be inserted';
            checkCgs.Status__c=errMsg;
            checkCgs.IsActive__c = false;
           checkCgs.addError(errMsg);
        }
       } // for (Chatter_Group_Setup__c
    
    // check for existing CollaborationGroup records. If we get to this point, that means that there isn't a Chatter_Group_Setup__c record
    // so we can use what we find and we don't need to create a new CollaborationGroup.
    CollaborationGroup[] collabGrps = [Select Id, Name from CollaborationGroup where Name in :grpMap.keySet()];
    for (CollaborationGroup cg : collabGrps) {
        Chatter_Group_Setup__c checkCgs = grpMap.get(cg.Name);
        // set the id
        checkCgs.ChatterGroupId__c = cg.Id;
    } // for (CollaborationGroup
    
   } // checkChatterGroup
   
   public static void processOneRecord(Id cgsId) {
      Chatter_Group_Setup__c cgs = [SELECT Id, Name
                                             ,ChatterGroupId__c
                                             ,Do_Not_Include_Child_Profiles__c
                                             ,ExecuteSetup__c
                                             ,IsActive__c
                                             ,Manager_Profiles__c
                                             ,Owner_Profile__c
                                             ,Owner_Role__c
                                             ,Owner__c
                                             ,Owner__r.Id
                                             ,Owner__r.Name
                                             ,Owner__r.Profile.Name
                                             ,Owner__r.UserRole.Name
                                             ,Selected_Profiles__c
                                             ,Select_From_All_Profiles__c
                                             ,Status__c
                                             ,Type__c
                                             ,Use_Owner__c
                                         FROM Chatter_Group_Setup__c 
                                        WHERE Id=:cgsId];
      new ChatterMethods().checkForGroupMembers(cgs);
      update cgs;
   } // processOneRecord
   
   // Check to make sure everyone who meets the specified criteria is a part of the group.
   //    Also check the ownership of the group to make sure it's correct.
   public Boolean checkForGroupMembers(Chatter_Group_Setup__c cgs) {
      // always clear out the previous status
    Boolean updateGrp = (cgs.Status__c != null);
    cgs.Status__c = null;
    
    Map<Id,Chatter_Group_Setup__c> allSetupsMap = getGroupAndChildren(cgs);
    
    // check for cost centers of all groups
    Org_Unit__c[] costCenters = getCostCenters(allSetupsMap.keySet());
    Set<String> costCenterNbrSet = new Set<String>();
    for (Org_Unit__c ou : costCenters) {
       costCenterNbrSet.add(ou.Org_Unit_Number_Padded__c);
    }
    
    Set<String> selectProfileSet = getProfileSet(cgs,allSetupsMap,'Selected_Profiles__c',!cgs.Do_Not_Include_Child_Profiles__c);
    Set<String> mngrProfileSet = getProfileSet(cgs,allSetupsMap,'Manager_Profiles__c',false);
    
      // get the chatter group - if the group doesn't exist, try to create it
      CollaborationGroup cg = null;
      
      if (cgs.ChatterGroupId__c != null) {
        try {
           cg = [Select Id, Name, CollaborationType, OwnerId, Owner.Name, Owner.Profile.Name, Owner.UserRole.Name from CollaborationGroup where Id = :cgs.ChatterGroupId__c];
        } catch (Exception e) {
           emailErrors += '\nGroup '+cgs.Name+': Could not find a CollaborationGroup. Creating new! Id='+cgs.ChatterGroupId__c+': '+e;
           // TODO - if no group - record isn't relevant. Do we delete?
           //return updateGrp;
           cgs.ChatterGroupId__c = null;
        }
      } // if (cgs
      
      System.debug('checkForGroupMembers cg='+cg);
      System.debug('checkForGroupMembers costCenterNbrSet='+costCenterNbrSet);
      System.debug('checkForGroupMembers selectProfileSet='+selectProfileSet);

      //emailMessages += '\nGroup '+cgs.Name+': nbr cost centers='+costCenterNbrSet.size()+', nbr profiles='+selectProfileSet.size();

      // verify owner role in cgs exists
      Id ownerRoleId = null;
      User owner = cgs.Owner__r;
      
      System.debug('checkForGroupMembers owner='+owner);

      // if the flag is set but there isn't an owner, set the flag to false.
      // this shouldn't be needed because of the validation rule, but just in case...
      if (cgs.Use_Owner__c && cgs.Owner__c == null) {
         System.debug('checkForGroupMembers resetting Use_Owner__c field');
         cgs.Use_Owner__c = false;
      } else if (cgs.Use_Owner__c && cgs.Owner__c != null
                 && (cgs.Owner_Role__c != cgs.Owner__r.UserRole.Name || cgs.Owner_Profile__c != cgs.Owner__r.Profile.Name)) {
         cgs.Owner_Role__c = cgs.Owner__r.UserRole.Name;
         cgs.Owner_Profile__c = cgs.Owner__r.Profile.Name;
         updateGrp = true;
      }

      if (!cgs.Use_Owner__c) {
         if (cgs.Owner_Role__c != null) {
            try {
               UserRole role = [Select Id, Name from UserRole where Name=:cgs.Owner_Role__c ];
               ownerRoleId = role.Id;
               // try to find a user with this role
               
            } catch (Exception e) {
               // if any exception occurs we can ignore it - should just mean it doesn't exist.
               // set to null so we can try to re-retrieve it.
               cgs.Owner_Role__c = null;
               cgs.Owner_Profile__c = null;
               cgs.Owner__c = null;
               updateGrp = true;
            }
         } // if (cgs.Owner_Role__c
      
      
         if (cgs.Owner_Role__c == null && !costCenterNbrSet.isEmpty() && !selectProfileSet.isEmpty()) {
            // find the highest role - start with System Admin and work your way down.
            UserRole systemAdmin = [Select Id, Name from UserRole where Name='System Administrator'];
            String[] roleIds = new Id[]{systemAdmin.Id};
            owner = findHighestRoleUser(roleIds,costCenterNbrSet,selectProfileSet);
            //emailMessages += '\nGroup '+cgs.Name+': owner='+owner;
            if (owner != null) {
               cgs.Owner_Role__c = owner.UserRole.Name;
               cgs.Owner_Profile__c = owner.Profile.Name;
               cgs.Owner__c = owner.Id;
               cgs.Owner__r = owner;
               //emailMessages += '\nGroup '+cgs.Name+' set Owner Role='+cgs.Owner_Role__c+', Owner Profile='+cgs.Owner_Profile__c;
               //emailMessages += '\nGroup '+cgs.Name+' current group owner='+cg.Owner.Profile.Name+' role='+cg.Owner.UserRole.Name;
               ownerRoleId = owner.UserRoleId;
               updateGrp = true;
            }
         } // if (cgs.Owner_Role__c == null &&
      } // if (!cgs.Use_Owner__c
      
      System.debug('checkForGroupMembers costCenterNbrSet='+costCenterNbrSet.size()+' selectProfileSet='+selectProfileSet.size()+' owner='+owner);
      System.debug('checkForGroupMembers cg='+cg);
      // try to create a group - has to have cost centers and profiles to continue
      if (cg == null && owner != null && !costCenterNbrSet.isEmpty() && !selectProfileSet.isEmpty()) {
         // find a top level User
         if (owner == null) {
            Id[] roleIds = new Id[]{ownerRoleId};
            owner = getUser(roleIds, costCenterNbrSet, selectProfileSet);
         }
         System.debug('checkForGroupMembers owner='+owner);
         if (owner != null) {
            cg = new CollaborationGroup();
            cg.Name = cgs.Name;
            cg.CollaborationType = (cgs.Type__c != null ? cgs.Type__c : 'Private');
            cg.OwnerId = owner.Id;
            cg.Owner = owner;
            try {
               insert cg;
            } catch (Exception e) {
               // if any exception occurs - for example there is a duplicate
               // set the group record to inactive, set the status
               cgs.IsActive__c = false;
               cgs.Status__c = e.getMessage();
               System.debug('checkForGroupMembers error inserting e:'+e);
               emailErrors += '\nError with '+cgs.Name+': '+e;
               return true;
            }

            emailMessages += '\nCreate group '+cgs.Name+' with owner='+owner.Name;
            cgs.ChatterGroupId__c = cg.Id;
            updateGrp = true;
         }
      } // if (cg == null
      
      // don't have enough information - do not proceed
      if (cg == null || (cg != null && cg.Id == null)) {
        cgs.Status__c = 'Not enough information to find an owner for '+cgs.Name+'. Nbr profiles='+selectProfileSet.size()+' nbr cost centers='+costCenterNbrSet.size();
        System.debug(cgs.Status__c);
        emailErrors += '\n'+cgs.Status__c;
         return true;
      }
      Boolean updateCg = false;
      
      // make sure the owner profile is in the manager profile list
      if (cgs.Owner_Profile__c != null && !mngrProfileSet.contains(cgs.Owner_Profile__c)) {
         mngrProfileSet.add(cgs.Owner_Profile__c);
         cgs.Manager_Profiles__c = (cgs.Manager_Profiles__c != null ? cgs.Manager_Profiles__c+';'+cgs.Owner_Profile__c : cgs.Owner_Profile__c);
         updateGrp = true;
      }
      
      if (!cgs.Use_Owner__c) {
         // verify the profile of the owner.
         if ((ownerRoleId != null) && ((cgs.Owner_Profile__c != null && cgs.Owner_Profile__c != cg.Owner.Profile.Name)
             || (cgs.Owner_Role__c != null && cgs.Owner_Role__c != cg.Owner.UserRole.Name))) {
            // if the role and profile don't match, find the first available user that meets the criteria.
            emailMessages += '\nGroup '+cgs.Name+': Profile and Role do not match current owner. ';
            Id[] roleIds = new Id[]{ownerRoleId};
            Set<String> profSet = new Set<String>{cgs.Owner_Profile__c};
            owner = getUser(roleIds, costCenterNbrSet, profSet);

            // if can't find another user just leave it as it is
            if (owner != null) {
               emailMessages += 'Changed ownership of group '+cgs.Name+' from '+cg.Owner.Name+' to '+owner.Name;
               cg.OwnerId = owner.Id;
               cg.Owner = owner;
               updateCg = true;
               cgs.Owner__c = owner.Id;
               cgs.Owner__r = owner;
               updateGrp = true;
            } else {
               emailMessages += '\nGroup '+cgs.Name+': Could not find a new owner that matches Profile '+cgs.Owner_Profile__c+' and Role '+cgs.Owner_Role__c;
            }
         } // if (cgs.Owner_Profile__c
      } else {
         // verify the owner matches the group owner
         if (cg.OwnerId != cgs.Owner__c) {
            cg.OwnerId = cgs.Owner__c;
            cg.Owner = cgs.Owner__r;
            updateCg = true;
         }
      } // if (!cgs.Use_Owner__c      
      
      // have to exclude users that were added to groups manually (not part of this process)
      // check to make sure users meet the criteria to stay in the group
      checkGroupMembers(cgs.Id, cg,costCenterNbrSet,selectProfileSet,mngrProfileSet);
      // Roles are Standard/Admin
      
      // look for Users not already in the group
      findNewMembers(cgs.Name, cgs.Id, cgs.ChatterGroupId__c,cg.OwnerId,costCenterNbrSet,selectProfileSet,mngrProfileSet);
      
      // keep the types in sync
      /*
      if (cg.CollaborationType != cgs.Type__c) {
         cg.CollaborationType = cgs.Type__c;
         updateCg = true;
      }
      */
      // keep the names in sync
      if (cg.Name != cgs.Name) {
         cg.Name = cgs.Name;
         updateCg = true;
      }
      
      if (updateCg) {
        try {
            update cg;
        } catch (Exception e) {
            emailErrors += '\nError when attempting to update '+cgs.Name+': '+e;
        }
      } // if (updateCg

      if (cgs.ExecuteSetup__c) {
         updateGrp = true;
         cgs.ExecuteSetup__c = false;
      }
      return updateGrp;
   } // checkForGroupMembers
   
   /** Find a User with the highest role based on the incoming parameters. Start at the top of the tree and recursively 
       work our way down.
    */
   public User findHighestRoleUser(Id[] userRoleIds,Set<String> costCenterNbrSet, Set<String> selectProfileSet) {
    System.debug('findHighestRoleUser nbrIds='+userRoleIds.size()+' userRoleIds='+userRoleIds);
    User u = getUser(userRoleIds, costCenterNbrSet, selectProfileSet);
    if (u != null) {
       return u;
    }

    // a User was not found. Select the roles that are the children of the passed in role ids and try again.
    for (UserRole[] childRoles : [Select Id, Name, ParentRoleId
                                From UserRole
                               Where ParentRoleId in :userRoleIds]) {
       if (!childRoles.isEmpty()) {
          Id[] childRoleIds = new Id[]{};
          for (UserRole role : childRoles) {
             childRoleIds.add(role.Id);
          }
          User checkU = findHighestRoleUser(childRoleIds, costCenterNbrSet, selectProfileSet);
          if (checkU != null) {
             return checkU;
          }
       } // if (!childRoles.isEmpty
    } // for (Id[] childRoleIds
    // if get here, nothing was found.
    return null;
   } // findHighestRoleUser
   
   public User getUser(Id[] userRoleIds, Set<String> costCenterNbrSet, Set<String> selectProfileSet) {
    User u = null;
    if (!userRoleIds.isEmpty()) {
         try {
            u = [Select Id, Name
                       ,UserRoleId
                       ,UserRole.ParentRoleId
                       ,UserRole.Name
                       ,ProfileId
                       ,Profile.Name
                   from User 
                  where IsActive=true
                    and Cost_Center__c in :costCenterNbrSet 
                    and Profile.Name in :selectProfileSet
                    and UserRoleId in :userRoleIds
                  order by LastLoginDate desc
                  limit 1];
         } catch (Exception e) {
            // if an exception occurs it means a User was not found.
         } // try
    } // if (!userRoleIds
      return u;
   } // getUser

   /** Get the profiles of the current group and any group children it has.
    */   
   public Set<String> getProfileSet(Chatter_Group_Setup__c cgs, Map<Id,Chatter_Group_Setup__c> allSetupsMap, String profField, Boolean includeChildren) {
    Set<String> profSet = new Set<String>();
    String profValue = (String)cgs.get(profField);
    if (profValue != null) {
         String[] profs = profValue.split(';');
         profSet.addAll(profs);
      } // if (profValue != null

      if (includeChildren) {
         // get the profiles for all groups included
         for (Id key : allSetupsMap.keySet()) {
            Chatter_Group_Setup__c checkGrp = allSetupsMap.get(key);
            String chkValue = (String)checkGrp.get(profField);
            if (chkValue != null) {
               String[] profs = chkValue.split(';');
               profSet.addAll(profs);
            }
         } // for (Id key
      }
    return profSet;
   } // getProfileSet
   
   public Map<Id,Chatter_Group_Setup__c> getGroupAndChildren(Chatter_Group_Setup__c cgs) {
      // check for child groups
      Id[] checkGroupIds = new Id[]{cgs.Id};
      Map<Id,Chatter_Group_Setup__c> allSetupsMap = new Map<Id,Chatter_Group_Setup__c>();
      allSetupsMap.put(cgs.Id,cgs);
      checkForGroupChildren(checkGroupIds,allSetupsMap);
      return allSetupsMap;
   } // getGroupAndChildren
   
   public String emailErrors = '';
   public String emailMessages = '';
   
   public void findNewMembers(String groupName, Id chatterGroupSetupId, Id collaborationGroupId, Id ownerId, Set<String> costCenterNbrSet, Set<String> selectProfileSet, Set<String> mngrProfileSet) {
    //emailMessages += '\nGroup='+groupName+' chatterGroupSetupId='+chatterGroupSetupId+' collaborationGroupId='+collaborationGroupId+' costCenterNbrSet='+costCenterNbrSet.size()+' selectProfileSet='+selectProfileSet.size();
    // select new members making sure they're not already part of the group (but maybe not added via this process)
    // always specifically include the owner id - make sure the owner is part of the group!
      for (User[] users : [Select Id, Name
                                 ,Profile.Name
                            from User
                           Where IsActive=true
                             and ((Id = :ownerId)
                                 or ( Cost_Center__c in :costCenterNbrSet
                                      and Profile.Name in :selectProfileSet))
                             and Id not in (Select MemberId from CollaborationGroupMember where CollaborationGroupId = :collaborationGroupId)]) {
         CollaborationGroupMember[] insertMembers = new CollaborationGroupMember[]{};
         // check to make sure we're not going to be going against any limits
         String errorMsg = Utilities.checkLimits(groupName, 3, users.size()*3);
         if (errorMsg != null) {
            emailErrors += '\n'+errorMsg;
            break;
         }
         
         for (User u : users) {
            CollaborationGroupMember cgm = new CollaborationGroupMember();
            cgm.CollaborationGroupId = collaborationGroupId;
            // if the owner or profile is a manager profile, set as Admin
            cgm.CollaborationRole = ((u.Id == ownerId || mngrProfileSet.contains(u.Profile.Name)) ? 'Admin' : 'Standard');
            cgm.MemberId = u.Id;

            System.debug('findNewMembers u='+u.Name+' id='+u.Id+' collaborationGroupId='+collaborationGroupId);
            insertMembers.add(cgm);
         } // for (User u
        
        if (!insertMembers.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(insertMembers,false);

            // create the links
            Chatter_Group_User_Link__c[] userLinks = new Chatter_Group_User_Link__c[]{};

            // check for users that error create links for ones that don't
            for (Integer cnt=0; cnt<results.size(); cnt++) {
               Database.SaveResult sr = results.get(cnt);
               CollaborationGroupMember cgm = insertMembers.get(cnt);
               
               if (!sr.isSuccess()) {
                // capture the error
                  String errorStr = '';
                  for (Database.Error err : sr.getErrors()) {
                     errorStr += err.getMessage();
                  }
                  emailErrors += '\nError adding '+cgm.MemberId+' to '+groupName+': '+errorStr;
               } else {
                  Chatter_Group_User_Link__c link = new Chatter_Group_User_Link__c();
                  link.Chatter_Group_Setup__c = chatterGroupSetupId;
                  link.CollaborationGroupMemberId__c = cgm.Id;
                  link.User__c = cgm.MemberId;
                  userLinks.add(link);
               }
            } // for (Integer cnt=0
           
            if (userLinks.size() > 0) {
               emailMessages += '\nGroup='+groupName+' number new members='+userLinks.size();
            }

            nbrAdded += userLinks.size();
            if (!userLinks.isEmpty()) {
               insert userLinks;
            }
        } // if (!insertMembers.isEmpty
        
      } // for (User[] users
   } // findNewMembers
   
   /* The number of users removed from groups. */
   public Integer nbrRemoved = 0;
   /* The number of users added to groups. */
   public Integer nbrAdded = 0;
   /* The number of users changed from Standard to Admin. */
   public Integer nbrStandToAdmin = 0;
   /* The number of users changed from Admin to Standard. */
   public Integer nbrAdminToStand = 0;
   
   /** Check the existing group members - make sure they still fit the criteria. If not, remove them.
       Return the existing members that are left so they are not added again.
    */
   public void checkGroupMembers(Id chatterGroupSetupId, CollaborationGroup cg, Set<String> costCenterNbrSet, Set<String> selectProfileSet, Set<String> mngrProfileSet) {

      // the users with an admin profile
      Id[] adminUserIds = new Id[]{};
      // the users with a standard profile
      Id[] standardUserIds = new Id[]{};
      
    for (Chatter_Group_User_Link__c[] userLinks : [Select Id
                                                         ,CollaborationGroupMemberId__c
                                                         ,User__c
                                                         ,User__r.Id
                                                         ,User__r.Name
                                                         ,User__r.Cost_Center__c
                                                         ,User__r.IsActive
                                                         ,User__r.Profile.Name
                                                     from Chatter_Group_User_Link__c
                                                    where Chatter_Group_Setup__c = :chatterGroupSetupId]) {

         // the ids of the records to delete from the group if they no longer meet the criteria
         Id[] deleteMemberIds = new Id[]{};
         // the links to delete
         Chatter_Group_User_Link__c[] deleteLinks = new Chatter_Group_User_Link__c[]{};

       for (Chatter_Group_User_Link__c userLink : userLinks) {
            
        if (!userLink.User__r.IsActive || 
               !costCenterNbrSet.contains(userLink.User__r.Cost_Center__c) ||
               !selectProfileSet.contains(userLink.User__r.Profile.Name)) {
               // we don't want to delete the owner, even if they don't meet the criteria
           if (userLink.User__c != cg.OwnerId) {
                  deleteMemberIds.add(userLink.CollaborationGroupMemberId__c);
                  deleteLinks.add(userLink);
           }
        } else {
            // make sure the owner is also a manager of the group
           if (mngrProfileSet.contains(userLink.User__r.Profile.Name) || userLink.User__c == cg.OwnerId) {
              adminUserIds.add(userLink.User__c);
           } else {
            standardUserIds.add(userLink.User__c);
           }
        }
       } // for (Chatter_Group_User_Link__c                                         

         nbrRemoved += deleteMemberIds.size();
         
         // delete the members from the group
         if (!deleteMemberIds.isEmpty()) {
            // get the ones that are not group owners
            CollaborationGroupMember[] members = [Select Id 
                                                    from CollaborationGroupMember 
                                                   where Id in :deleteMemberIds
                                                     and MemberId not in (Select OwnerId from CollaborationGroup where OwnerId in :deleteMemberIds)];
            Database.delete(members,false);
         }
         // delete the links
         if (!deleteLinks.isEmpty()) {
            delete deleteLinks;
         }
    } // for (Chatter_Group_User_Link__c[] userLinks
    
      
      
      nbrStandToAdmin += checkRole(cg.Id,adminUserIds,'Admin');
      nbrAdminToStand += checkRole(cg.Id,standardUserIds,'Standard');
      
   } // getGroupMembers
   
   /** Check to make sure the users that are supposed to be admins are, and the ones that shouldn't be are not.
    */
   public Integer checkRole(Id collaborationGroupId, Id[] userIds, String checkRole) {
    Integer nbrChanged = 0;
    if (!userIds.isEmpty()) {
         for (CollaborationGroupMember[] members : [Select Id, CollaborationRole
                                                 from CollaborationGroupMember
                                                Where CollaborationGroupId = :collaborationGroupId
                                                  and MemberId in :userIds
                                                  and CollaborationRole != :checkRole]) {
            // the number of records we're changing
            nbrChanged += members.size();
            // update these roles
            for (CollaborationGroupMember member : members) {
                member.CollaborationRole = checkRole;
            }
            if (!members.isEmpty()) {
               update members;
            }
         } // for (CollaborationGroupMember[] members
    } // if (!userIds.isEmpty()
    return nbrChanged;
   } // checkRole
   
   /** Get the children of all of the groups
    */
   public Boolean checkForGroupChildren(Id[] parentGroupIds, Map<Id,Chatter_Group_Setup__c> allSetupsMap) {
      Boolean childrenFound = false;
      Chatter_Group_Link__c[] links = [Select Id, Name
                                             ,Child_Group__c
                                             ,Child_Group__r.Id
                                             ,Child_Group__r.Name
                                             ,Child_Group__r.ChatterGroupId__c
                                             ,Child_Group__r.Manager_Profiles__c
                                             ,Child_Group__r.Selected_Profiles__c
                                             ,Child_Group__r.Type__c
                                             ,Parent_Group__c
                                         From Chatter_Group_Link__c
                                        Where Parent_Group__c in :parentGroupIds
                                          and Child_Group__r.IsActive__c=true];
      // if new ones are selected, check those recursively
      Id[] checkGroupIds = new Id[]{};
      for (Chatter_Group_Link__c link : links) {
         if (link.Child_Group__c != null) {
            if (!allSetupsMap.containsKey(link.Child_Group__c)) {
               checkGroupIds.add(link.Child_Group__c);
               allSetupsMap.put(link.Child_Group__c,link.Child_Group__r);
            }
         }
      } // for (Chatter_Group_Link__c
      if (!checkGroupIds.isEmpty()) {
         checkForGroupChildren(checkGroupIds,allSetupsMap);
      }
      return (!checkGroupIds.isEmpty());
   } // checkForGroupChildren
   
   public Org_Unit__c[] getCostCenters(Set<Id> grpIds) {
      Map<Id,Org_Unit__c> costCenterMap = new Map<Id,Org_Unit__c>();
      for (Chatter_Group_Org_Link__c[] links : [Select Id, Name
                                                      ,Org_Unit__c
                                                      ,Org_Unit__r.Id
                                                      ,Org_Unit__r.Name
                                                      ,Org_Unit__r.Available_Profiles__c
                                                      ,Org_Unit__r.Org_Type__c
                                                      ,Org_Unit__r.Org_Unit_Name__c
                                                      ,Org_Unit__r.Org_Unit_Number_Padded__c
                                                  From Chatter_Group_Org_Link__c
                                                 Where Chatter_Group_Setup__c in :grpIds
                                                   and Org_Unit__r.Org_Type__c = 'Cost Center']) {
         for (Chatter_Group_Org_Link__c link : links) {
            // only add if not already added.
            if (!costCenterMap.containsKey(link.Org_Unit__c)) {
               costCenterMap.put(link.Org_Unit__c,link.Org_Unit__r);
            }
         } // for (Chatter_Group_Org_Link__c link
      } // for (Chatter_Group_Org_Link__c[] links
      
      return costCenterMap.values();
   } // getCostCenters

} // class ChatterMethods