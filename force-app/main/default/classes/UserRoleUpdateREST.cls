/* 
 *  Update the linkage to the Org Unit when the User Role changes
 
 * History
 * -------
 * 01/19/2015 Dan Carmen     created
 * 
 */
@RestResource(urlMapping='/UserRoleUpdate/*')
global without sharing class UserRoleUpdateREST {

   @HttpPost
   global static void doPost(Id[] userIds) {
   	System.debug('doPost userIds='+userIds);

      RestRequest req = RestContext.request;
      RestResponse res = RestContext.response;
   	
   	//Map<String,String> userDsaIdMap = new Map<String,String>();
   	
   	// select the users and existing org unit links
   	User[] users = [Select Id, Name, FirstName, LastName
   	                      ,UserRoleId
   	                      ,(Select Id, Name, Org_Unit__c, User__c
   	                          From Org_Unit_User_Links__r)
   	                  From User
   	                 Where Id in :userIds];
   	                 
   	System.debug('doPost users='+users.size());
      // collect the userRoleIds and select the org units
      Set<Id> userRoleIdSet = new Set<Id>();
      for (User usr : users) {
         userRoleIdSet.add(usr.UserRoleId);
      }
      
      // select the org units based on the roles
      Org_Unit__c[] districts = [Select Id, Name, RepUserRoleId__c, UserRoleId__c, Assistant__c
                                   From Org_Unit__c
                                  Where (RepUserRoleId__c in :userRoleIdSet or UserRoleId__c in :userRoleIdSet)
                                    and Org_Type__c = :OrgUnitMethods.TYPE_DISTRICT];
      System.debug('doPost districts='+districts.size());
                                  
      Map<Id,Org_Unit__c> orgUnitRoleMap = new Map<Id,Org_Unit__c>();
      for (Org_Unit__c district : districts) {
      	// store in the map under both role ids for easy reference
         if (district.RepUserRoleId__c != null) {
            orgUnitRoleMap.put(district.RepUserRoleId__c,district);
         }
         if (district.UserRoleId__c != null) {
            orgUnitRoleMap.put(district.UserRoleId__c,district);
         }
      } // for (Org_Unit__c
      
      Org_Unit_User_Link__c[] deleteLinks = new Org_Unit_User_Link__c[]{};
      Org_Unit_User_Link__c[] insertLinks = new Org_Unit_User_Link__c[]{};

      for (User usr : users) {
         Org_Unit__c district = orgUnitRoleMap.get(usr.UserRoleId);
         Org_Unit_User_Link__c foundLink = null;
         System.debug('doPost usr='+usr.Name+' numberOfLinks='+usr.Org_Unit_User_Links__r.size());
         
         // should be at most one good link. Delete any links not attached to this district.
         for (Org_Unit_User_Link__c ouul : usr.Org_Unit_User_Links__r) {
            if (foundLink == null && district != null && ouul.Org_Unit__c == district.Id) {
               foundLink = ouul;
               System.debug('foundLink='+ouul);
            } else {
            	System.debug('link to delete='+ouul);
               deleteLinks.add(ouul);
            } 
         } // for (Org_Unit_User_Link__c ouul

         if (district != null && foundLink == null) {
            // create a new link
            insertLinks.add(new Org_Unit_User_Link__c(Name=usr.LastName+', '+usr.FirstName, User__c=usr.Id, Org_Unit__c=district.Id));
         } // if (district != null
         
         //if (district != null && district.Assistant__c != null) {
         //   userDsaIdMap.put(usr.Id, district.Assistant__c);
         //}
      } // for (User usr
      
      System.debug('doPost deleteLinks='+deleteLinks.size()+' insertLinks='+insertLinks.size());
      
      if (!deleteLinks.isEmpty()) {
         Database.delete(deleteLinks,false);
      }
      
      if (!insertLinks.isEmpty()) {
         Database.insert(insertLinks,false);
      }
      
      //return userDsaIdMap;
   } // doPost

} // class UserRoleUpdateREST