/* 
 * Set the Role Name and Id on the Organization Structure object
 *
 * History
 * -------
 * 09/14/2011 Dan Carmen   Created
   03/05/2012 Dan Carmen   Added logic to populate zone and area role information
   07/17/2012 Dan Carmen   Added change to order of profile check
   02/15/2013 Dan Carmen   Logic to populate the Cost Center field from the Sales Office Number if not populated
   08/01/2014 Dan Carmen   Commented out the role code because it's no longer needed.
   04/30/2020 Dan Carmen   Add code back in to maintain roles if needed.
 
 */
public with sharing class OrgStrcRole {

   public static void processStrcs(Organization_Structure__c[] strcs, Map<Id,Organization_Structure__c> oldMap) {

      Set<String> roleNameSet = new Set<String>();
      
      for (Organization_Structure__c strc : strcs) {
         // clear out the id fields
         strc.RoleId_District__c = null;
         strc.RoleId_Sales_Office__c = null;
         strc.RoleId_Zone__c = null;
         strc.RoleId_Area__c = null;
          
         if (String.isNotBlank(strc.Role_Sales_Office__c)) {
             roleNameSet.add(strc.Role_Sales_Office__c);
         }
         if (String.isNotBlank(strc.Role_District__c)) {
             roleNameSet.add(strc.Role_District__c);
         }
         if (String.isNotBlank(strc.Role_Zone__c)) {
             roleNameSet.add(strc.Role_Zone__c);
         }
         if (String.isNotBlank(strc.Role_Area__c)) {
             roleNameSet.add(strc.Role_Area__c);
         }
      } // for (Organization_Structure__c strc
       
      if (!roleNameSet.isEmpty()) {
         UserRole[] roles = [Select Id, Name from UserRole where Name in :roleNameSet];
         Map<String,UserRole> roleMap = new Map<String,UserRole>();
         for (UserRole role : roles) {
             roleMap.put(role.Name, role);
         }
         for (Organization_Structure__c strc : strcs) {
            if (String.isNotBlank(strc.Role_Sales_Office__c)) {
               UserRole role = roleMap.get(strc.Role_Sales_Office__c);
               if (role != null) {
                  strc.RoleId_Sales_Office__c = role.Id;
               }
            }
            if (String.isNotBlank(strc.Role_District__c)) {
               UserRole role = roleMap.get(strc.Role_District__c);
               if (role != null) {
                  strc.RoleId_District__c = role.Id;
               }
            }
            if (String.isNotBlank(strc.Role_Zone__c)) {
               UserRole role = roleMap.get(strc.Role_Zone__c);
               if (role != null) {
                  strc.RoleId_Zone__c = role.Id;
               }
            }
            if (String.isNotBlank(strc.Role_Area__c)) {
               UserRole role = roleMap.get(strc.Role_Area__c);
               if (role != null) {
                  strc.RoleId_Area__c = role.Id;
               }
            }
         }
      } // if (!roleNameSet.isEmpty
       
   } // processStrcs
         
} // class OrgStrcRole