/* 
 *  Update the user record from the Org_Unit__c object
    ** TEST METHOD IS in UpdateOrgInfoTest **
 
 * History
 * -------
 * 02/26/2015 Dan Carmen     created
   05/18/2016 Dan Carmen     Slight adjustment when setting the DSA - look at role vs job name.
   11/11/2021 Dan Carmen     Update API, add tests

*/
@RestResource(urlMapping='/UserUpdateFromOrgUnit/*')
global without sharing class UserUpdateFromOrgUnitREST {

   public static Boolean allowUpdate = !Test.isRunningTest();
   public static Set<Id> testingIdSet = new Set<Id>();
    
   @HttpPost
   global static void doPost(Id[] orgUnitIds) {
      System.debug('UserUpdateFromOrgUnitREST doPost orgUnitIds='+orgUnitIds);

      RestRequest req = RestContext.request;
      RestResponse res = RestContext.response;
      
      // select the district and zone
      Org_Unit__c[] districts = [Select Id
                                      ,Name
                                      ,Assistant__c
                                      ,Assistant__r.Id
                                      ,Assistant__r.IsActive
                                      ,Org_Type__c
                                      ,Org_Unit_Name__c
                                      ,UserRoleId__c
                                      ,RepUserRoleId__c
                                      ,Parent__r.Id
                                      ,Parent__r.Name
                                      ,Parent__r.Org_Unit_Name__c
                                      ,Parent__r.Org_Type__c
                                      ,Parent__r.UserRoleId__c
                                 From Org_Unit__c
                                Where RepUserRoleId__c != null
                                  and Org_Type__c = :OrgUnitMethods.TYPE_DISTRICT
                                  and (Id in :orgUnitIds or Parent__c in :orgUnitIds)];
      // don't execute the user trigger when performing the update
      UserHelper.SKIP_USER_TRIGGERS = true;
      System.debug('doPost number districts='+districts.size());
      // extract the role ids
      Map<String,Org_Unit__c> orgUnitByRoleIdMap = new Map<String,Org_Unit__c>();
      for (Org_Unit__c district : districts) {
         if (district.RepUserRoleId__c != null) {
            orgUnitByRoleIdMap.put(district.RepUserRoleId__c,district);
         }
         if (district.UserRoleId__c != null) {
            orgUnitByRoleIdMap.put(district.UserRoleId__c,district);
         }
         // handle zone name changes
         if (district.Parent__r != null && district.Parent__r.UserRoleId__c != null && !orgUnitByRoleIdMap.containsKey(district.Parent__r.UserRoleId__c)) {
            orgUnitByRoleIdMap.put(district.Parent__r.UserRoleId__c,district.Parent__r);
         }
      } // for (Org_Unit__c district
      
      if (!orgUnitByRoleIdMap.isEmpty()) {
         for (User[] users : [Select Id, UserRoleId, District_Name__c, DSA_FSS__c, Zonetxt__c, Job_Name__c from User where UserRoleId in :orgUnitByRoleIdMap.keySet()]) {
            System.debug('doPost number users='+users.size());
            
            User[] updateUsers = new User[]{};
            for (User usr : users) {
            	Org_Unit__c orgUnit = orgUnitByRoleIdMap.get(usr.UserRoleId);
            	if (orgUnit != null) {
                  Boolean changed = false;
                  Org_Unit__c district = (orgUnit.Org_Type__c == OrgUnitMethods.TYPE_DISTRICT ? orgUnit : null);
                  Org_Unit__c zone = (orgUnit.Org_Type__c == OrgUnitMethods.TYPE_DISTRICT ? orgUnit.Parent__r : (orgUnit.Org_Type__c == OrgUnitMethods.TYPE_ZONE ? orgUnit : null));
                  System.debug('doPost district='+district+' zone='+zone);
                  
                  if (district != null && usr.UserRoleId == district.RepUserRoleId__c && district.Assistant__c != null && district.Assistant__r.IsActive && usr.DSA_FSS__c != district.Assistant__c) {
                     changed = true;
                     usr.DSA_FSS__c = district.Assistant__c;
                  }
                  if (district != null && usr.District_Name__c != district.Org_Unit_Name__c) {
                     changed = true;
                     usr.District_Name__c = district.Org_Unit_Name__c;
                  }
                  if (zone != null && usr.Zonetxt__c != zone.Org_Unit_Name__c) {
                     changed = true;
                     usr.Zonetxt__c = zone.Org_Unit_Name__c;
                  }
                  
                  if (changed && (!Test.isRunningTest() || (Test.isRunningTest() && testingIdSet.contains(usr.Id)))) {
                     updateUsers.add(usr);
                  }
            	} // if (orgUnit != null
               
            } // for (User usr
            
            System.debug('doPost '+updateUsers.size()+' users found for update');
            if (allowUpdate && !updateUsers.isEmpty()) {
               try {
                  update updateUsers;
               } catch (Exception ex) {
                  ErrorLog.logError('UserUpdateFromOrgUnitREST', 'doPost', 'updateUsers', updateUsers[0].Id, ex, updateUsers[0]);
               }
            }
         } // for (User[] users
         
         ErrorLog.checkSave();
      } // if (!orgUnitByRoleIdMap.isEmpty
      UserHelper.SKIP_USER_TRIGGERS = false;

   } // doPost
   
} // class UserUpdateFromOrgUnitREST