/*
 *  Methods used by Account Junction object to link parent and child accounts
 *
 * History
 * ---------
 * 06/29/2016 Cindy Freeman     created
 * 03/15/2017 Cindy Freeman     modified to be more efficient and work better, now junction upserts fire parent recalc
 * 03/28/2017 Cind Freeman      modified junction upsert to use Database.upsert so doesnt throw out entire transaction if hits 1 error
 * 04/12/2017 Cindy Freeman     modifed pushParentToChild to use Database methods so updates/inserts/deletes dont kill the whole transaction
 * 05/11/2017 Cindy Freeman     fixed it so user can enter 0 in employee count
 * 07/29/2017 Cindy Freeman     added Push Parent to Child checkbox to fix children with wrong owners
   02/27/2019 Dan Carmen         Added check for future before calling future
   03/18/2019 Dan Carmen         Change to use DmlHelper for some updates.
   09/06/2019 Dan Carmen         Change to always check account team members on children even if there are no changes to the main owner fields.
   10/19/2020 Dan Carmen         Problem with testOwnershipChanges test
   02/08/2021 Matt Fritschi		Removes certain Hold Outs if employees fall outside a given range.
   01/04/2022 Dan Carmen         Fix with setting the child contact owners
   03/04/2022 Dan Carmen          Clean up some ownership logic
   10/11/2022 Carrie Marciano   Added logic to check if all asset fields (5500, paychex and child) are blank set the aggregate 401K asset field to null
   09/06/2023 Dan Carmen         Always set SalesParentChild__c
   03/06/2024 Dan Carmen         Change deleteAcctTeams to a map to ensure ATM isn't in the list more than once.
 
 */


public without sharing class AccountJunctionMethods implements TriggerInterfaceC {
   
   // from the Interface
   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      System.debug('AccountJunctionMethods.handleTrigger recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete);
      if (TriggerMethods.didTriggerRun('AccountJunctionMethods',recs,isBefore,isAfter)) {
         return;
      }
      
      SObjectType objType = TriggerMethods.objType;
      if (isBefore && !isDelete) {
         if (objType == Account.sObjectType) {
            checkAccountsBefore((Account[])recs, (Map<Id,Account>)oldMap, isDelete);
         } else if (objType == Account_Junction__c.sObjectType) {
            processJunctionsBefore((Account_Junction__c[])recs, (Map<Id,Account_Junction__c>)oldMap, isDelete);
         }
      } else if (isAfter) {
         if (objType == Account.sObjectType) {
            checkAccountsAfter((Account[])recs, (Map<Id,Account>)oldMap, isDelete);
         } else if (objType == Account_Junction__c.sObjectType) {
            processJunctionsAfter((Account_Junction__c[])recs, (Map<Id,Account_Junction__c>)oldMap, isDelete);
         }
      }
   } // handleTrigger

    
    public static String DEFAULTTYPE = Label.AccountJunctionDefaultType;     // 'Sales Parent-Child';
    /** Ids that have already been processed from controller that we do not want to process again. */
    //public static Set<Id> childIdsProcessed = new Set<Id>();
    /** Parent Ids that have already been processed that we do not want to process again. */
    public static Set<Id> parentIdsProcessed = new Set<Id>();

   
   /* if child account SalesParent, asset or employees are updated, update AccountJunction record
    * if child account got a SalesParent, create new AccountJunction record 
   */ 
   public static void upsertAcctJunction(Set<Id> p_childUpsertSet, String p_type) {     
      processUpsertAcctJunction(p_childUpsertSet, p_type);
   }

   public static void processUpsertAcctJunction(Set<Id> p_childUpsertSet, String p_type) {
      Account[] accts = [Select Id, Name, Employees__c, NumberofEmployees, X401K_Assets__c, Larkspur_401k_Assets__c 
                                                              ,Paychex_401k_Assets__c,SalesParent__c, SalesParent__r.SalesParent__c, Create_Junction__c
                                                              ,(Select Id, Child_Account__c, Assets__c, Employees__c
                                                                      ,Parent_Account__c, SalesParentChild__c
                                                                  From Account_Junctions__r)
                                                          from Account 
                                                         where id in :p_childUpsertSet]; 
                                                                        
      List<Account_Junction__c> juncUpdateList = new List<Account_Junction__c>();     
       
      for (Account child: accts) {
         // if a child could be linked to multiple parents this would have to change
         Account_Junction__c junc = (!child.Account_Junctions__r.isEmpty() ? child.Account_Junctions__r[0] : null);
        //Account_Junction__c junc = acctJuncMap.get(child.Id);
         if (junc == null) {
            junc = new Account_Junction__c();
            junc.Child_Account__c = child.Id;
            junc.Parent_Account__c = child.SalesParent__c;
            junc.Type__c = p_type;
            junc.SalesParentChild__c = true;
         }
         if (child.SalesParent__c != junc.Parent_Account__c) {
            junc.Parent_Account__c = child.SalesParent__c;  
            junc.SalesParentChild__c = true;
         }
         if (child.Larkspur_401k_Assets__c != null && child.Larkspur_401k_Assets__c > -1) {  
            junc.Assets__c = child.Larkspur_401k_Assets__c;    
         } else {
            junc.Assets__c = (child.Paychex_401k_Assets__c == null ? 0 : child.Paychex_401k_Assets__c) ;    
         }
         junc.Employees__c = (child.Employees__c == null ? 0 : child.Employees__c);   
         juncUpdateList.add(junc);
      } // for
   
       System.debug('**CMF ** processUpsertAcctJunction upserting junc '+juncUpdateList.size());

      DmlHelper.performDML2(juncUpdateList, DmlHelper.DML_UPSERT, 'AccountJunctionMethods', 'upsertAcctJunction', 'upserting juncUpdateList', true, null);
   } // upsertAcctJunction
    
////////////////////////////////////////////////////////////

    /* if Sales Parent is cleared on child account or child account is deleted, delete junction record
     */  
    public static void deleteAcctJunction(Set<Id> p_childClearedParentSet, Set<Id> p_juncIdsToDeleteSet) {
        
      if ((p_childClearedParentSet != null && p_childClearedParentSet.size() > 1) || (p_juncIdsToDeleteSet != null && p_juncIdsToDeleteSet.size() > 1)) {
         if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
            processdeleteAcctJunc(p_childClearedParentSet, p_juncIdsToDeleteSet);
         } else {
            processdeleteAcctJuncFuture(p_childClearedParentSet, p_juncIdsToDeleteSet);
         }
      } // if (acctIdList.size() > 0
      else if ((p_childClearedParentSet != null &&p_childClearedParentSet.size() == 1) || (p_juncIdsToDeleteSet != null && p_juncIdsToDeleteSet.size() == 1)) 
      {    processdeleteAcctJunc(p_childClearedParentSet, p_juncIdsToDeleteSet);  }
   }
     
     @future
    public static void processdeleteAcctJuncFuture(Set<Id> p_childClearedParentSet, Set<Id> p_juncIdsToDeleteSet) {
         processdeleteAcctJunc(p_childClearedParentSet, p_juncIdsToDeleteSet);
    }
         
    public static void processdeleteAcctJunc(Set<Id> p_childClearedParentSet, Set<Id> p_juncIdsToDeleteSet) {
        System.debug('**CMF ** delete childClearedParentSet='+p_childClearedParentSet+' juncDeleteSet='+p_juncIdsToDeleteSet);    
        List<Account_Junction__c> childJuncList;
        if (p_childClearedParentSet != null) 
        {   childJuncList = [Select Id, Child_Account__c, Assets__c, Employees__c, Parent_Account__c 
                                                    from Account_Junction__c where Child_Account__c in :p_childClearedParentSet];
        }
        else
        {   childJuncList = [Select Id, Child_Account__c, Assets__c, Employees__c, Parent_Account__c 
                                                    from Account_Junction__c where Id in :p_juncIdsToDeleteSet];
        }                                                                                                                  
        //delete childJuncList;
        Database.DeleteResult[] drList = Database.delete(childJuncList,false);
        for(Database.DeleteResult dr : drList) {
            if (dr.isSuccess()) {                
            }            
            else {
                // Operation failed, so get all errors               
                for(Database.Error err : dr.getErrors()) {
                    System.debug('**CMF ** The following error has occurred.');                   
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('**CMF ** Account Junction fields that affected this error: ' + err.getFields());          
                } // for
            } // else           
        } // for
              
    } // deleteAcctJunction
    
//////////////////////////////////////////////////////////////
    
    /* get parent acct ids so we can update asset, employee aggregate counts
    */
   
    public static void updateParentAggregates(Set<Id> juncIdSet) {
     // this should always be a future method so roll-up summary fields have time to calc
      if (!juncIdSet.isEmpty()) {
         if (System.isFuture() || System.isBatch()) {
            processParentAggregates(juncIdSet);
         } else {
            processParentAggregatesFuture(juncIdSet);
         }
      } // if 
   } // updateParentAggregates
     
     @future
    public static void processParentAggregatesFuture(Set<Id> juncIdSet) {
         processParentAggregates(juncIdSet);
    }
    
     public static void processParentAggregates(Set<Id> juncIdSet) {    
        List<Account_Junction__c> juncList = [Select Id, Child_Account__c, Assets__c, Employees__c, Parent_Account__c 
                                                    from Account_Junction__c where Id in :juncIdSet];       
        Set<Id> parentIdSet = new Set<Id>();
        for (Account_Junction__c junc : juncList)
        {   parentIdSet.add(junc.Parent_Account__c);    }
        
        //AccountMethods.processUpdateAssetEmps(parentIdSet);
        List<Account> acctList = new List<Account>([Select Id,Larkspur_401K_Assets__c , Paychex_401K_Assets__c, X401K_Assets__c, NumberOfEmployees, Employees__c,  
                                   Child_Assets__c, Child_Employees__c from Account where Id in :parentIdSet]);
      System.debug('processParentAggregatesFuture juncIdSet='+juncIdSet.size()+' juncList='+juncList.size()+' acctList='+acctList.size());
        for (Account acct: acctList)
        {   try
            {   if (acct.Larkspur_401k_Assets__c != null && acct.Larkspur_401k_Assets__c > 0)  
                {  acct.X401K_Assets__c = acct.Larkspur_401k_Assets__c + (acct.Child_Assets__c == null ? 0 : acct.Child_Assets__c); }
                else if (acct.Paychex_401k_Assets__c!= null && acct.Paychex_401k_Assets__c > 0)
                {  acct.X401K_Assets__c = acct.Paychex_401k_Assets__c + (acct.Child_Assets__c == null ? 0 : acct.Child_Assets__c);  }
                else if (acct.Larkspur_401k_Assets__c  == null && acct.Paychex_401k_Assets__c == null && acct.Child_Assets__c != null && acct.Child_Assets__c > 0)
                {  acct.X401K_Assets__c = acct.Child_Assets__c;  }
               
                if (acct.Employees__c!= null && acct.Employees__c > -1)
                {  acct.NumberOfEmployees = (Integer)acct.Employees__c + (Integer)(acct.Child_Employees__c == null ? 0 : acct.Child_Employees__c);     }
                else if (acct.Employees__c == null && acct.Child_Employees__c != null && acct.Child_Employees__c > -1)
                {  acct.NumberOfEmployees = (Integer)acct.Child_Employees__c;     }         
            } // try
            catch (Exception e) {
                ErrorLog.logError('AccountJunctionMethods', 'updateParentAggregates', 'updating assets, employees', acct.Id, e);
                ErrorLog.checkSave();
            } // catch                          
        } // for
        
        //v_juncIdsToProcessUpdParentSet.clear();        

        System.debug('**CMF ** updateParentAggregates updating acctList '+acctList.size());        
      DmlHelper.performDML2(acctList, DmlHelper.DML_UPDATE, 'AccountJunctionMentods', 'processParentAggregates', 'processParentAggregates', true);
        
    } // processParentAggregates
    
//////////////////////////////////    
    
    
   public static String processLog='';
   /* get Parent owners and push them down to children
    *  wont overwrite owner on child if has Hold Out
   */
   public static void pushParenttoChild(Set<Id> juncIdSet, List<Id> acctIdList) {
      processLog='pushParenttoChild acctIdList='+(acctIdList != null ? acctIdList.size() : -1);
      System.debug('pushParenttoChild juncIdSet='+(juncIdSet != null ? juncIdSet.size() : -1)+' acctIdList='+(acctIdList != null ? acctIdList.size() : -1));
      if (juncIdSet == null && acctIdList == null) {
         return;
      }
      Set<Id> queryIds = new Set<Id>();
      if (juncIdSet != null) {
         queryIds.addAll(juncIdSet);
      }
      if (acctIdList != null) {
         queryIds.addAll(acctIdList);
      }
      
      Account_Junction__c[] acctJuncList = (queryIds.isEmpty() ? new Account_Junction__c[]{}
                                               : [Select Id, Parent_Account__c, Parent_Account__r.Id, Child_Account__c, Child_Account__r.Id, Push_Parent_to_Child__c 
                                                    from Account_Junction__c
                                                   where Id in :queryIds
                                                      or Parent_Account__c in :queryIds
                                                      or Child_Account__c in :queryIds
                                                 ]);
     
      processLog += ' acctJuncList='+acctJuncList.size();
      if (acctJuncList.isEmpty()) {
         return;
      }
      parentIdsProcessed.addAll(queryIds);
      
      AccountTeamMember[] insertAcctTeams = new AccountTeamMember[]{};
      //AccountTeamMember[] deleteAcctTeams = new AccountTeamMember[]{};
      Map<Id,AccountTeamMember> delAcctTeamMap = new Map<Id,AccountTeamMember>();
      Contact[] ctctUpdateList = new Contact[]{};
        
      List<Id> ckAcctTeamList = new List<Id>();
      List<Id> allAcctIds = new list<Id>(); 

       
      System.debug('pushParenttoChild acctJuncList='+acctJuncList.size());
      
      Account_Junction__c[] updateJuncs = new Account_Junction__c[]{};
      
      for (Account_Junction__c junc: acctJuncList) {
         //childIdSet.add(junc.Child_Account__r.Id);
            //parentIdSet.add(junc.Parent_Account__r.Id);
            allAcctIds.add(junc.Child_Account__r.Id);
            allAcctIds.add(junc.Parent_Account__r.Id);  
            //childParentMap.put(junc.Child_Account__r.Id,junc.Parent_Account__r.Id);
            if (junc.Push_Parent_to_Child__c) {
               junc.Push_Parent_to_Child__c = false;                               // reset Push_Parent_to_Child__c checkbox
               updateJuncs.add(junc);
            }
      } // for (Account_Junction__c junc: acctJuncList)
        
      ZipCheckOwner.setupRecordTypeMaps();
      List<Account> acctList = ZipCheckOwner.getAccounts(allAcctIds,ZipCheckOwner.rtById.keySet());
      Map<Id,Account> acctMap = new Map<Id,Account>(acctList);
      
      System.debug('pushParenttoChild allAcctIds='+allAcctIds.size()+' acctList='+acctList.size());
      processLog += ' allAcctIds='+allAcctIds.size()+' acctList='+acctList.size();       
       
        
      //List<Account> childUpdateList = new List<Account>();
      Map<Id,Account> acctUpdateMap = new Map<Id,Account>();
      
      for (Account_Junction__c junc: acctJuncList) {
         Account child = acctMap.get(junc.Child_Account__c);
         Account parentAcct = acctMap.get(junc.Parent_Account__c);
         System.debug('pushParenttoChild hasChild='+(child != null)+' hasParent='+(parentAcct != null));
         Boolean changed = pushToChild(parentAcct, child, parentAcct.AccountTeamMembers, child.AccountTeamMembers, insertAcctTeams, delAcctTeamMap, ctctUpdateList);
         if (changed) {
            acctUpdateMap.put(child.Id,child);      
         }
          /*
          if (parentAcct != null && child != null) {  // this avoids problem with Referral Account Record Types
            Account updateChild = new Account(Id=child.Id);
            System.debug('pushParenttoChild parent='+parentAcct.Name+' child='+child.Name);
            for (String ownerFld : hoFieldMap.keySet()) {
               Id parentOwnerId = (Id)parentAcct.get(ownerFld);
               Id childOwnerId = (Id)child.get(ownerFld);
               Boolean childHoldOut = (Boolean)child.get(hoFieldMap.get(ownerFld));
               System.debug('pushParenttoChild ownerFld='+ownerFld+' parentOwnerId='+parentOwnerId+' childOwnerId='+childOwnerId+' childHoldOut='+childHoldOut);
               // if the values are different and there isn't a holdout on the child
               if (parentOwnerId != childOwnerId && childHoldOut != null && !childHoldOut) {
                  updateChild.put(ownerFld,parentAcct.get(ownerFld));
                  // we're not updating this record, but it's used for the contacts
                  child.put(ownerFld,parentAcct.get(ownerFld));
                  changed = true;
               }
           } // for fieldset
            System.debug('pushParenttoChild 1 changed='+changed);
            // update child record type to match parent record type
            if (child.RecordTypeId != parentAcct.recordTypeId) {
               updateChild.RecordTypeId = parentAcct.recordTypeId;               
               changed = true;
            } /// if
            System.debug('pushParenttoChild 2 changed='+changed);
             if (changed) {
                if (child.Use_Zip_Assignment_Rules__c == true) {
                   updateChild.Use_Zip_Assignment_Rules__c = false;  
                }
                //childUpdateList.add(updateChild);
                acctUpdateMap.put(child.Id,updateChild);      
                    
                ZipCheckOwner.checkContacts(child,child.Contacts, ctctUpdateList);
             } // if(changed)
            matchTeams(child, parentAcct, insertAcctTeams, deleteAcctTeams); 
         } // if (parentAcct != null && child != null
         */
      } // for (childAccts)
                
      processLog += ' acctUpdateMap='+acctUpdateMap.size()+' delAcctTeamMap='+delAcctTeamMap.size()+' insertAcctTeams='+insertAcctTeams.size()+' ctctUpdateList='+ctctUpdateList.size();
      ZipCheckOwner.SKIP_TRIGGERS=true;              // set flag so accounts dont get caught in triggers resetting values 
      System.debug('pushParenttoChild acctUpdateMap='+acctUpdateMap.size()+' delAcctTeamMap='+delAcctTeamMap.size()+' insertAcctTeams='+insertAcctTeams.size()+' ctctUpdateList='+ctctUpdateList.size());
      DmlHelper.performDML2(acctUpdateMap.values(), DmlHelper.DML_UPDATE, 'AccountJunctionMentods', 'pushParenttoChild', 'Update Child Accounts', false);
      DmlHelper.performDML2(delAcctTeamMap.values(), DmlHelper.DML_DELETE, 'AccountJunctionMentods', 'pushParenttoChild', 'Delete ATMs', false);  
      DmlHelper.performDML2(insertAcctTeams, DmlHelper.DML_INSERT, 'AccountJunctionMentods', 'pushParenttoChild', 'Insert ATMs', false);
      DmlHelper.performDML2(ctctUpdateList, DmlHelper.DML_UPDATE, 'AccountJunctionMentods', 'pushParenttoChild', 'Update Contacts', false);
      ErrorLog.checkSave();                    
   } // pushParenttoChild
    
   private static Map<String, String> v_hoFieldMap = null;
    
   public static Map<String, String> getHoFldMap() {
      if (v_hoFieldMap == null) {
           
         // get Hold Out field names to go with Owner field names      
         List<HoldOut_ExpirationDates__c> hoFieldList = HoldOut_ExpirationDates__c.getall().values();  
         v_hoFieldMap = new Map<String, String>();
         for (HoldOut_ExpirationDates__c ho: hoFieldList) {
            if (ho.UseForOwnershipChange__c && String.isNotBlank(ho.Account_Owner__c)) {
               v_hoFieldMap.put(ho.Account_Owner__c, ho.Account_Hold_Out__c);
            }
         } // for (HoldOut_ExpirationDates__c ho 
      } // if (v_hoFieldMap == null
      return v_hoFieldMap;
   } // getHoFldMap
    
   // this is used by ZipCheckOwner. Once we can modify that class this method can be removed
   public static Boolean pushToChild(Account parentAcct, Account child, AccountTeamMember[] parentAtms, AccountTeamMember[] childAtms
                                 , AccountTeamMember[] insertAcctTeams, AccountTeamMember[] deleteAcctTeams, Contact[] ctctUpdateList) {
      Map<Id,AccountTeamMember> delAcctTeamMap = new Map<Id,AccountTeamMember>(deleteAcctTeams);
      Boolean result = pushToChild(parentAcct, child, parentAcct.AccountTeamMembers, childAtms, insertAcctTeams, delAcctTeamMap, ctctUpdateList);
      deleteAcctTeams.clear();
      deleteAcctTeams.addAll(delAcctTeamMap.values());
      return result;
   } // pushToChild
    
   public static Boolean pushToChild(Account parentAcct, Account child, AccountTeamMember[] parentAtms, AccountTeamMember[] childAtms
                                 , AccountTeamMember[] insertAcctTeams, Map<Id,AccountTeamMember> delAcctTeamMap, Contact[] ctctUpdateList) {
      Boolean changed = false;
      if (parentAcct != null && child != null) {  // this avoids problem with Referral Account Record Types
         Map<String, String> hoFieldMap = getHoFldMap();
         //Account updateChild = new Account(Id=child.Id);
         System.debug('pushParenttoChild parent='+parentAcct.Name+' child='+child.Name);
         for (String ownerFld : hoFieldMap.keySet()) {
            Id parentOwnerId = (Id)parentAcct.get(ownerFld);
            Id childOwnerId = (Id)child.get(ownerFld);
            Boolean childHoldOut = (Boolean)child.get(hoFieldMap.get(ownerFld));
            System.debug('pushParenttoChild ownerFld='+ownerFld+' parentOwnerId='+parentOwnerId+' childOwnerId='+childOwnerId+' childHoldOut='+childHoldOut);
            // if the values are different and there isn't a holdout on the child
            if (parentOwnerId != childOwnerId && childHoldOut != null && !childHoldOut) {
               child.put(ownerFld,parentAcct.get(ownerFld));
               changed = true;
            }
         } // for fieldset
         System.debug('pushParenttoChild 1 changed='+changed);
         // update child record type to match parent record type
         if (child.RecordTypeId != parentAcct.recordTypeId) {
            child.RecordTypeId = parentAcct.recordTypeId;               
            changed = true;
         } /// if
         System.debug('pushParenttoChild 2 changed='+changed);
         if (child.Use_Zip_Assignment_Rules__c == true) {
            child.Use_Zip_Assignment_Rules__c = false;  
         }
                    
         ZipCheckOwner.checkContacts(child,child.Contacts, ctctUpdateList);
         matchTeams(child, parentAcct, parentAtms, childAtms, insertAcctTeams, delAcctTeamMap); 
      } // if (parentAcct != null && child != null
      return changed;
   } // pushToChild
   
   public static Set<String> atmRolesSet = null;
   
   public static void checkAtmRoleSet() {
      if (atmRolesSet == null) {
         atmRolesSet = new Set<String>();
         for (AccountTeamMemberRoles__c atmr : AccountTeamMemberRoles__c.getall().values()) {
            if (atmr.Sales__c) {
               System.debug('checkAtmRoleSet sales role='+atmr.RoleName__c);
               atmRolesSet.add(atmr.RoleName__c);  
            }
         } // for (AccountTeamMemberRoles__c atmr
      } // if (atmRolesSet == null
   } // checkAtmRoleSet
 
   // compare child to parent account team members and make child's team match the parent's team
   // except for any Hold Outs on the child!
   // uses custom setting - AccountTeamMemberRoles to only move Sales roles down to child
   public static void matchTeams(Account childAcct, Account parentAcct, AccountTeamMember[] parentAtms, AccountTeamMember[] childAtms
                                ,AccountTeamMember[] insertAcctTeams, Map<Id,AccountTeamMember> delAcctTeamMap) {
      checkAtmRoleSet();
      System.debug('matchTeams parentAtms='+parentAtms.size()+' childAtms='+childAtms.size());
      Map<String, AccountTeamMember> childTeamMap = new Map<String, AccountTeamMember>();
      Map<String, AccountTeamMember> parentTeamMap = new Map<String, AccountTeamMember>();
        
      for (AccountTeamMember atm: childAcct.AccountTeamMembers) {
         Boolean roleInSet = atmRolesSet.contains(atm.TeamMemberRole);
         System.debug('matchTeams childRole='+atm.TeamMemberRole+' roleInSet='+roleInSet);
         if (!atm.User.IsActive) { 
            System.debug('matchTeams deleting due to inactive user '+atm.TeamMemberRole);
            delAcctTeamMap.put(atm.Id,atm);
         } else if (roleInSet) {
            System.debug('matchTeams adding '+atm.TeamMemberRole+' to child map');
            childTeamMap.put(atm.TeamMemberRole, atm);  
         }
      } // for (childAcct.AccountTeamMembers)       
      
      for (AccountTeamMember atm: parentAcct.AccountTeamMembers) {
         Boolean roleInSet = atmRolesSet.contains(atm.TeamMemberRole);
         System.debug('matchTeams parentRole='+atm.TeamMemberRole+' in roleInSet='+roleInSet);
         if (roleInSet) {
            parentTeamMap.put(atm.TeamMemberRole, atm); 
         }
      } // for (parentAcct.AccountTeamMembers)
        
      System.debug('matchTeams childTeamMap='+childTeamMap.size()+' child ATMs='+childAcct.AccountTeamMembers.size()+' parentTeamMap='+parentTeamMap.size()+' parent ATMS='+parentAcct.AccountTeamMembers.size());
      // add or update child team members to match parent
      for (AccountTeamMember parentAtm : parentTeamMap.values()) {
         AccountTeamMember childAtm = childTeamMap.get(parentAtm.TeamMemberRole);    
         if (childAtm == null && parentAtm.User.IsActive) {
            System.debug('matchTeams no child team member found, creating new for '+parentAtm.TeamMemberRole);
            copyAtm(childAcct, parentAtm.UserId, parentAtm.TeamMemberRole,insertAcctTeams);
         } else if (childAtm != null && parentAtm.UserId != childAtm.UserId && parentAtm.User.IsActive) {      // cant update team member, need to delete existing and add a new one
            System.debug('matchTeams deleting existing child team member and creating new for '+parentAtm.TeamMemberRole);
            if (childAtm.User.IsActive) {     // if inactive was added to delAcctTeamMap above
               delAcctTeamMap.put(childAtm.Id,childAtm);
            }          
            copyAtm(childAcct, parentAtm.UserId, parentAtm.TeamMemberRole,insertAcctTeams);
         }
      } // for (parentAtm
                
  } // matchTeams

   public static void copyAtm(Account childAcct, Id userId, String teamMemberRole, AccountTeamMember[] insertAcctTeams) {
      AccountTeamMember newAtm = new AccountTeamMember(AccountId = childAcct.Id, UserId = userId, TeamMemberRole = teamMemberRole
                                                            ,AccountAccessLevel='Edit', ContactAccessLevel='Edit', OpportunityAccessLevel='Read');
      if (childAcct.Id == null) {
         // this is coming from the account before trigger. This will be saved later.
         ZipCheckOwner.atmsToInsert.add(new ZipCheckOwner.AcctTeamInsert(childAcct,newAtm));
      } else {
         insertAcctTeams.add(newAtm);                   
      }
   } // copyAtm
    
//////////////////////////////////////////////////////////////////////

   public static Set<Id> upsertJunctionsFromBefore = new Set<Id>();
   public static Set<Id> checkOwnershipAccts = new Set<Id>();
   
   public static void checkAccountsBefore(Account[] accts, Map<Id,Account> oldMap, Boolean isDelete) {
      Set<Id> deleteJuncSet = new Set<Id>();
      upsertJunctionsFromBefore.clear();
      
      if (isDelete && oldMap != null) {
         for (Account acct : oldMap.values()) {
            deleteJuncSet.add(acct.Id);
         } // for (Account acct : oldMap.values
      } else if (!isDelete) {
         for (Account acct : accts) {
            Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
            if (acct.Create_Junction__c) {
               if (acct.SalesParent__c != null && oldAcct != null) {
                  upsertJunctionsFromBefore.add(acct.Id);
               }
               acct.Create_Junction__c=false;
            }
            // if cleared Sales Parent set Use Zip Assgn rules
            if (oldAcct != null && acct.SalesParent__c == null && oldAcct.SalesParent__c != null) {
               acct.Use_Zip_Assignment_Rules__c = true;
            }
            
            // if child reset Use Zip Assgn Rules - how do we pull ownership from the parent?
            if (acct.Use_Zip_Assignment_Rules__c && acct.SalesParent__c != null) {         
               acct.Use_Zip_Assignment_Rules__c = false;
               checkOwnershipAccts.add(acct.Id);
            }
			
            if (acct.Larkspur_401k_Assets__c != null && acct.Larkspur_401k_Assets__c > 0) {
               acct.X401K_Assets__c = acct.Larkspur_401k_Assets__c + (acct.Child_Assets__c == null ? 0 : acct.Child_Assets__c);
               system.debug('AccountJunctionMethods checkAccountsBefore use Larkspur assets'); 
            } else if (acct.Paychex_401k_Assets__c!= null && acct.Paychex_401k_Assets__c > 0) {
               acct.X401K_Assets__c = acct.Paychex_401k_Assets__c + (acct.Child_Assets__c == null ? 0 : acct.Child_Assets__c); 
               system.debug('AccountJunctionMethods checkAccountsBefore use Paychex assets');
            } else if (acct.Larkspur_401k_Assets__c  == null && acct.Paychex_401k_Assets__c == null && acct.Child_Assets__c != null && acct.Child_Assets__c > 0) {
               acct.X401K_Assets__c = acct.Child_Assets__c;  
               system.debug('AccountJunctionMethods checkAccountsBefore use child assets');
            } else if (acct.Larkspur_401k_Assets__c  == null && acct.Paychex_401k_Assets__c == null && (acct.Child_Assets__c == null || acct.Child_Assets__c == 0)){
               acct.X401K_Assets__c = null; 
               system.debug('AccountJunctionMethods checkAccountsBefore no assets'); 
            }
          	system.debug('AccountJunctionMethods checkAccountsBefore Aggregate 401K Assets: '+acct.X401K_Assets__c);
             
            if (acct.Employees__c!= null && acct.Employees__c > -1) {
               acct.NumberOfEmployees = (Integer)acct.Employees__c + (Integer)(acct.Child_Employees__c == null ? 0 : acct.Child_Employees__c);
            } else if (acct.Employees__c == null && acct.Child_Employees__c != null && acct.Child_Employees__c > -1) {
               acct.NumberOfEmployees = (Integer)acct.Child_Employees__c;
            }

             //If an Account has the Payroll Lost Client Hold Out and moves outside the employee range, use Zip Assignments instead.
            if(acct.Permanent_Hold_Out_Description__c != null && acct.Permanent_Hold_Out_Description__c == 'Payroll Lost Client' && acct.NumberOfEmployees != oldAcct.NumberOfEmployees)
            {
                HoldOut_Dictionary__c hod = HoldOut_Dictionary__c.getInstance('Payroll Lost Client');
      		    if(hod != null && 
                   (oldAcct.NumberOfEmployees >= hod.Min_Employees__c && oldAcct.NumberOfEmployees <= hod.Max_Employees__c) && (acct.NumberOfEmployees > hod.Max_Employees__c || acct.NumberOfEmployees < hod.Min_Employees__c))
      	        {
      			      acct.Hold_Out__c = false;
                      acct.Hold_Out_Expiration__c = null;
                      acct.Permanent_Hold_Out_Description__c = null;
          		      acct.Use_Zip_Assignment_Rules__c = true;
      	        }
            }
         } // for (Account acct : accts
      }
      
      if (!deleteJuncSet.isEmpty()) {
         deleteAcctJunction(null, deleteJuncSet);   
      }
   } // checkAccountsBefore
  
   public static void checkAccountsAfter(Account[] accts, Map<Id,Account> oldMap, Boolean isDelete) {
      Set<Id> checkSalesParentUpsertSet = new Set<Id>();
      checkSalesParentUpsertSet.addAll(upsertJunctionsFromBefore);
      upsertJunctionsFromBefore.clear();
      Set<Id> deleteJuncSet = new Set<Id>();
      
      for (Account acct : accts) {
         Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
         if (acct.SalesParent__c != null 
               && (oldAcct == null 
                      || (acct.SalesParent__c != oldAcct.SalesParent__c
                          || (acct.isChild__c && (acct.NumberOfEmployees != oldAcct.NumberOfEmployees
                                                 || acct.Employees__c != oldAcct.Employees__c
                                                 || acct.X401K_Assets__c != oldAcct.X401K_Assets__c))))) {
            checkSalesParentUpsertSet.add(acct.Id);
            // make sure it's not accidentally processed a second time.
            checkOwnershipAccts.remove(acct.Id);
         } else if (acct.SalesParent__c == null && oldAcct != null && oldAcct.SalesParent__c != null) {
            deleteJuncSet.add(acct.Id);
         }
         
      } // for (Account acct
      System.debug('checkAccountsAfter checkSalesParentUpsertSet='+checkSalesParentUpsertSet.size()+' deleteJuncSet='+deleteJuncSet.size()+' checkOwnershipAccts='+checkOwnershipAccts.size());
      if (!checkSalesParentUpsertSet.isEmpty()) {
         upsertAcctJunction(checkSalesParentUpsertSet, DEFAULTTYPE);
      }
      if (!deleteJuncSet.isEmpty()) {
         deleteAcctJunction(deleteJuncSet, null);   
      }
      if (!checkOwnershipAccts.isEmpty()) {
         Id[] checkIds = new Id[]{};
         checkIds.addAll(checkOwnershipAccts);
         pushParenttoChild(null,checkIds);
      }
   } // checkAccountsAfter
    

  // the account ids of the children accounts we want to update from their parents
  public static Set<Id> v_updateChildFromParentSet = new Set<Id>();
  
  public static void processJunctionsBefore(Account_Junction__c[] recs, Map<Id,Account_Junction__c> oldMap, Boolean isDelete) {
     v_updateChildFromParentSet.clear();
     for (Account_Junction__c rec : recs) {
        if (!isDelete && rec.Id != null && rec.Push_Parent_to_Child__c) {
           v_updateChildFromParentSet.add(rec.Child_Account__c);
           rec.Push_Parent_to_Child__c = false;
        }
        if (!isDelete && !rec.SalesParentChild__c) {
           rec.SalesParentChild__c = true;
        }
     } // for (Account_Junction__c rec
  } // processJunctionsBefore
  
   public static void processJunctionsAfter(Account_Junction__c[] recs, Map<Id,Account_Junction__c> oldMap, Boolean isDelete) {
      Set<Id> juncIdsToUpdateParentsSet = new Set<Id>();
      Set<Id> updateChildFromParentSet = new Set<Id>();
      updateChildFromParentSet.addAll(v_updateChildFromParentSet);
      v_updateChildFromParentSet.clear();
     
      if (isDelete && oldMap != null) {
         for (Account_Junction__c rec : oldMap.values()) {
            juncIdsToUpdateParentsSet.add(rec.Id);
         }
      } else if (!isDelete) {
         for (Account_Junction__c rec : recs) {
            Account_Junction__c oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
            if ((rec.Child_Account__c != null && rec.Parent_Account__c != null)
                && (oldRec == null
                     || (rec.Parent_Account__c != oldRec.Parent_Account__c
                          || rec.Assets__c != oldRec.Assets__c
                          || rec.Employees__c != oldRec.Employees__c))) {
               juncIdsToUpdateParentsSet.add(rec.Id);
               updateChildFromParentSet.add(rec.Child_Account__c);
            }
         } // for (Account_Junction__c rec : recs
      }
     
      // update parent account with child values or push parent owners down to children 
      if (!juncIdsToUpdateParentsSet.isEmpty()) {
         updateParentAggregates(juncIdsToUpdateParentsSet);
      }
      if (!updateChildFromParentSet.isEmpty()) {
         pushParenttoChild(updateChildFromParentSet,null);
      }

  } // processJunctionsAfter
  
} // AccountJunctionMethods