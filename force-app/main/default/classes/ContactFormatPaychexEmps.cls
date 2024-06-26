/**
 * Handle all of the logic for the Employee contact records
 *
 * History
 * -------
 * 09/30/2013 Dan Carmen        Created
   02/15/2015 Dan Carmen        Change to use the preferred name on the contact if it's available
   05/05/2015 Dan Carmen        Provide a linkage to the active user record from the paychex employee contact
   09/14/2017 Dan Carmen        Added a switch to not use the initCap method.
   10/13/2017 Dan Carmen        Added ability to save paychex contacts to different account based on last name
   01/31/2018 Dan Carmen        Merge in UserUpdateFromContact logic
   01/30/2019 Dan Carmen        Connect the contact to the Org Unit
   01/02/2020 Josh Cartwright   set and clear fed id on user if contact changes 
   03/06/2020 Dan Carmen        Change to without sharing
   06/17/2020 Dan Carmen        Change to use a callout
   02/04/2022 Dan Carmen        Add check for user lookup on contact if status changes
   03/09/2022 Dan Carmen        Populate other lat and long if postal code populated
   10/05/2023 Susmitha Somavarapu Uncommented the Cost Center and Department fields pushing from Contact record to User record directly(APR0159472)
   11/01/2023 Dan Carmen        Change to use queueable instead of callout, changed to TriggerInterfaceC
   02/21/2024 Dan Carmen        Add fields to the getUsersByPersonId query
   06/06/2024 Dan Carmen        Remove logic around lat and long for Other postal code.

 */
public without sharing class ContactFormatPaychexEmps implements TriggerInterfaceC {
   public static String CLASSNAME='ContactFormatPaychexEmps';
   
   public static Boolean SET_REPORTS_TO=(Label.Contact_EmpSetReportsTo == 'Y');
   public static String SITE_PREFIX='Last Name-';
   public static Integer SITE_LETTERS=Integer.valueOf(Label.Contact_NbrLastLetters);
   // employees that are termed more than x number of days
   public static String SITE_TERMED='Termed Employees';
   public static Integer TERMED_DAYS = Integer.valueOf(Label.Contact_TermedDays);
   
   //public static Set<Id> ctctsProcessedSet = new Set<Id>();

   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs(CLASSNAME, p_recs, oldMap, isBefore, isAfter, isDelete, null, null);
      System.debug('ContactFormatPaychexEmps.handleTrigger recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
      if (recs != null && !recs.isEmpty()) {
         if (isBefore) {
            handleCtctsBefore((Contact[])recs, (Map<Id,Contact>)oldMap);
         } else if (isAfter) {
            handleCtctsAfter((Contact[])recs, (Map<Id,Contact>)oldMap);
         }
      }

   } // handleTrigger
    
   public static void handleCtctsBefore(Contact[] ctcts, Map<Id,Contact> oldMap) {
      Map<String,Contact> contactByPersonIdMap = new Map<String,Contact>();
      Map<String,Contact[]> contactsBySuperPersonIdMap = new Map<String,Contact[]>();
      Map<String,Contact[]> contactsBySiteName = new Map<String,Contact[]>();
       
      for (Contact ctct : ctcts) {
         Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);
         if (String.isNotBlank(ctct.HR_Person_Id__c)) {
            checkCtctBefore(ctct, oldCtct, contactByPersonIdMap, contactsBySuperPersonIdMap, contactsBySiteName);
         }
      } // for (Contact ctct : ctcts
      System.debug('handleCtctsBefore contactByPersonIdMap='+contactByPersonIdMap.size()
                   +' contactsBySuperPersonIdMap='+contactsBySuperPersonIdMap.size()+' contactsBySiteName='+contactsBySiteName.size());
       
      if (!contactByPersonIdMap.isEmpty() || !contactsBySuperPersonIdMap.isEmpty()) {
         checkUserLookups(contactByPersonIdMap, contactsBySuperPersonIdMap);
      }
       
      if (!contactsBySiteName.isEmpty()) {
         processSiteCtcts(contactsBySiteName);
      }

   } // handleCtctsBefore 
    
   public static void checkCtctBefore(Contact ctct, Contact oldCtct, Map<String,Contact> contactByPersonIdMap
                              ,Map<String,Contact[]> contactsBySuperPersonIdMap, Map<String,Contact[]> contactsBySiteName) {
      // should be set on employee records on insert
      if (!ctct.Sales_Contact__c && oldCtct == null) {
         ctct.Sales_Contact__c=true;
      }
      
      contactByPersonIdMap.put(ctct.HR_Person_Id__c, ctct);

      // use the preferred name if it's available
      String firstNameToUse = (String.isNotBlank(ctct.Prefered_Name__c) ? ctct.Prefered_Name__c : ctct.TempFirstName__c);

      if (String.isNotBlank(firstNameToUse) && (oldCtct == null || (oldCtct != null && !firstNameToUse.equals(ctct.FirstName)))) {
         ctct.FirstName = firstNameToUse;
      } 
      
      if (String.isNotBlank(ctct.TempLastName__c) && (oldCtct == null || (oldCtct != null && !ctct.TempLastName__c.equals(ctct.LastName)))) {
         ctct.LastName = ctct.TempLastName__c;
      }
      System.debug('checkCtctBefore ctct.LastName='+ctct.LastName+' ctct.TempLastName__c='+ctct.TempLastName__c);
      if (String.isNotBlank(ctct.TempTitle__c) && (oldCtct == null || (oldCtct != null && !ctct.TempTitle__c.equals(ctct.Title)))) {
         ctct.Title = ctct.TempTitle__c;
      }

      if (String.isNotBlank(ctct.TempDepartment__c) && (oldCtct == null || (oldCtct != null && !ctct.TempDepartment__c.equals(ctct.Department)))) {
         ctct.Department = ctct.TempDepartment__c;
      }

      // store the contacts by site name. We will look up sites, and create if not there     
      String siteName = null;
      if (ctct.Date_of_Employee_Termination__c != null && ctct.Date_of_Employee_Termination__c <= Date.today().addDays(-TERMED_DAYS)) {
         siteName = SITE_TERMED;
      } else {
         siteName = SITE_PREFIX+(String.isNotBlank(ctct.LastName) ? ctct.LastName.left(SITE_LETTERS).toUpperCase() : 'Default');
      }
      System.debug('checkCtctBefore siteName='+siteName+' LastName='+ctct.LastName);
      Contact[] siteCtcts = (contactsBySiteName.containsKey(siteName) ? contactsBySiteName.get(siteName) : new Contact[]{});
      siteCtcts.add(ctct);
      contactsBySiteName.put(siteName, siteCtcts);

      if (SET_REPORTS_TO && ctct.Supervisor_Person_Id__c != null) {
         Contact[] ctcts = (contactsBySuperPersonIdMap.containsKey(ctct.Supervisor_Person_Id__c) ? contactsBySuperPersonIdMap.get(ctct.Supervisor_Person_Id__c) : new Contact[]{});
         ctcts.add(ctct);
         contactsBySuperPersonIdMap.put(ctct.Supervisor_Person_Id__c, ctcts);
      }
   } // checkCtctBefore

   public static Map<Id,Contact> checkUserLookups(Map<String,Contact> contactByPersonIdMap ,Map<String,Contact[]> contactsBySuperPersonIdMap) {
      Map<Id,Contact> ctctByUserIdMap = new Map<Id,Contact>();
      if (!contactByPersonIdMap.isEmpty()) {
      
         // get the users
         Map<String,User> usersByPersonId = getUsersByPersonId(contactByPersonIdMap.keySet());
         for (Contact ctct : contactByPersonIdMap.values()) {
            User usr = usersByPersonId.get(ctct.HR_Person_Id__c);
            System.debug('checkUserLookups ctct='+ctct.LastName+ ' Term='+ctct.Date_of_Employee_Termination__c+' usr='+usr);
            Id checkId = usr != null ? usr.Id : null;
            // always keep the most relevant user attached to the contact
            if (ctct.User_Lookup__c != checkId) {
               System.debug('checkUserLookups set User_Lookup__c with '+checkId);
               ctct.User_Lookup__c = checkId; 
            }
            
            if (ctct.User_Lookup__c != null) {
               ctctByUserIdMap.put(ctct.User_Lookup__c, ctct);
            }
         } // for
      } // if (!contactByPersonIdMap.isEmpty
      
      if (!contactsBySuperPersonIdMap.isEmpty()) {
         Contact[] supervisorCtcts = [Select Id, HR_Person_Id__c, Name from Contact where HR_Person_Id__c in :contactsBySuperPersonIdMap.keySet()];
         for (Contact supervisor : supervisorCtcts) {
            Contact[] ctcts = contactsBySuperPersonIdMap.get(supervisor.HR_Person_Id__c);
            if (ctcts != null) {
               for (Contact ctct : ctcts) {
                  if (ctct.ReportsToId != supervisor.Id) {
                     ctct.ReportsToId = supervisor.Id;
                  }
               } // for (Contact ctct
               
            } // if (ctcts != null
         } // for (Contact supervisor
      } // if (!contactsBySuperPersonIdMap.isEmpty
      
      if (!ctctByUserIdMap.isEmpty()) {
         Org_Unit_User_Link__c[] links = [select Id, User__c, Org_Unit__c 
                                            from Org_Unit_User_Link__c 
                                           where User__c in :ctctByUserIdMap.keySet()
                                          order by CreatedDate desc];
         for (Org_Unit_User_Link__c link : links) {
            Contact ctct = ctctByUserIdMap.remove(link.User__c);
            if (ctct != null) {
               ctct.OrgUnit__c = link.Org_Unit__c;
            }
         } // for (Org_Unit_User_Link__c link
         
      } // if (!ctctByUserIdMap.isEmpty
      return ctctByUserIdMap;
   } // checkUserLookups
   
   public static void processSiteCtcts(Map<String,Contact[]> contactsBySiteName) {
      // don't do any further trigger processing
      ZipCheckOwner.SKIP_TRIGGERS = true;
      // retrieve existing accounts
      Account[] accts = [Select Id, Name, Site 
                           from Account 
                          where Name=:UserHelper.PAYCHEX_COMP
                            and Site in :contactsBySiteName.keySet()];
      System.debug('processSiteCtcts existing accounts found='+accts.size());
      // check the existing accts first
      for (Account acct : accts) {
         Contact[] ctcts = contactsBySiteName.remove(acct.Site);
         if (ctcts != null) {
            for (Contact ctct : ctcts) {
               if (ctct.AccountId != acct.Id) {
                  ctct.AccountId = acct.Id;
               }
            } // for (Contact ctct
         } // if (ctcts != null
      } // for (Account acct
      
      // if anything is left create new accounts for them.
      if (!contactsBySiteName.isEmpty()) {
         Account parentAcct = getParentAcct();
         
         Account[] newAccts = new Account[]{};
         for (String siteName : contactsBySiteName.keySet()) {
            Account siteAcct = parentAcct.clone();
            siteAcct.Name = UserHelper.PAYCHEX_COMP;
            siteAcct.Site = siteName;
            newAccts.add(siteAcct);
         } // for (String siteName
        
         insert newAccts;
         for (Account acct : newAccts) {
            Contact[] ctcts = contactsBySiteName.get(acct.Site);
            if (ctcts != null) {
               for (Contact ctct : ctcts) {
                  ctct.AccountId = acct.Id;
               }
            } // if (ctcts != null
         } // for (Account acct
      } // if (!contactsBySiteName
       
   } // processSiteCtcts
   
   public static String PAYCHEX_COMP_PARENT=UserHelper.PAYCHEX_COMP+'-Parent';
   
   public static Account getParentAcct() {
      Schema.RecordTypeInfo acctRtType = RecordTypeHelper.getRecordType(Label.RT_System_Admin_Account, ObjectHelper.OBJECT_ACCOUNT);
      // select the main record and copy the information from it.
      String parentName = PAYCHEX_COMP_PARENT;
      Account parentAcct = null;
      try {
         parentAcct = [Select Id, Name, OwnerId, Type
                                     ,BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                                     ,ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                                 From Account
                                Where RecordTypeId=:acctRtType.getRecordTypeId()
                                  and Name=:parentName
                                limit 1];
      } catch (Exception e) {
         System.debug('getParentAcct parentAcct not found! e='+e.getMessage()+'; '+e.getStackTraceString());
         if (Test.isRunningTest()) {
            parentAcct = new Account(RecordTypeId=acctRtType.getRecordTypeId(), Name=UserHelper.PAYCHEX_COMP+'-Parent'); 
            insert parentAcct;
         } else {
            Throw e;
         }            
      }
      return parentAcct;
   } // getParentAcct
    
   public static void handleCtctsAfter(Contact[] ctcts, Map<Id,Contact> oldMap) {
      System.debug('handleCtctsAfter ctctcs='+ctcts.size());
      Set<Id> contactsToProcessSet = new Set<Id>();
       
      for (Contact ctct : ctcts) {
         Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);
         if (String.IsNotBlank(ctct.HR_Person_Id__c) && ctct.DoNotUpdateUser__c == false) {
            contactsToProcessSet.add(ctct.Id);
         }

      } // for (Contact ctct : ctcts
       
      System.debug('handleCtctsAfter.processAfterTriggerActions contactsToProcessSet='+contactsToProcessSet.size());
      if (!contactsToProcessSet.isEmpty()) {
         checkUserCtctMatch(contactsToProcessSet);
      }
   } // handleCtctsAfter
   
   public static void checkUserCtctMatch(Set<Id> ctctIdSet) {
      // do this check outside of the queueable. Only use the queueable to save changes.
      Contact[] ctcts = getContacts(ctctIdSet);
      System.debug('handleUpdate ctctIdSet='+ctctIdSet.size()+' ctcts='+ctcts.size());
      
      // if we have to update in a future context instead of queueable, get the ids of the records to update
      Set<Id> ctctIdsToUpdate = new Set<Id>();
      User[] usersToUpdate = new User[]{};
      
      for (Contact ctct : ctcts) {
         checkContactUser(usersToUpdate,ctct, ctct.User_Lookup__r,(ctct.ReportsTo != null ? ctct.ReportsTo.User_Lookup__r : null),ctctIdsToUpdate);
      } // for (Contact ctct

      if (!usersToUpdate.isEmpty()) {
         Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
         Boolean allowQueueable = (abc != null && abc.Active__c);
         System.debug('ContactFormatPaychexEmps.checkUserCtctMatch allowQueueable='+allowQueueable);
         UpdateUserFromCtct uufc = new UpdateUserFromCtct(usersToUpdate);
         if (allowQueueable && Utilities.allowFuture()) {
            System.enqueueJob(uufc);
         } else if (Utilities.allowFuture()) {
            checkUserFromContactFuture(ctctIdsToUpdate);
         } else {
            uufc.handleUpdate();
         }
       }
   } // checkUserCtctMatch
   
   public class UpdateUserFromCtct implements Queueable {
      public User[] users;
      public UpdateUserFromCtct(User[] p_users) {
         users = p_users;
      } // UpdateUserFromCtct
       
      public void execute(QueueableContext context) {
         System.debug('UpdateUserFromCtct in execute method');
         handleUpdate();
      } // execute

      public void handleUpdate() {
         if (!users.isEmpty()) {
            DmlHelper.performDML2(users, DmlHelper.DML_UPDATE, 'handleUpdate', 'handleUpdate', 'updating users', true);
         }

     } // handleUpdate
      
  } // class UpdateUserFromCtct
   
   @future
   public static void checkUserFromContactFuture(Set<Id> ctctIdSet) {
      System.debug('checkUserFromContactFuture ctctIdSet='+ctctIdSet.size());
      checkUserFromContactNow(ctctIdSet);
   } // checkUserFromContactFuture

   public static void checkUserFromContactNow(Set<Id> ctctIdSet) {
      Contact[] ctcts = getContacts(ctctIdSet);
      System.debug('checkUserFromContactNow ctctIdSet='+ctctIdSet.size()+' ctcts='+ctcts.size());
      
      Set<Id> ctctIdsToUpdate = new Set<Id>();
      User[] usersToUpdate = new User[]{};
      
      for (Contact ctct : ctcts) {
         checkContactUser(usersToUpdate,ctct, ctct.User_Lookup__r,(ctct.ReportsTo != null ? ctct.ReportsTo.User_Lookup__r : null), ctctIdsToUpdate);
      } // for (Contact ctct
      
      if (!usersToUpdate.isEmpty()) {
         DmlHelper.performDML2(usersToUpdate, DmlHelper.DML_UPDATE, 'ContactFormatPaychexEmps', 'checkUserFromContactNow', 'updating users', true);
      }
   } // checkUserFromContact
   
   // Check for changed fields between the contact and user objects. Only 
   //    update changes.
   private static void checkContactUser(List<User> updateUsers, Contact c, User u, User supervisorU, Set<Id> ctctIdsToUpdate) {
      System.debug('checkContactUser c='+(c != null ? c.LastName + ' Term='+c.Date_of_Employee_Termination__c : 'No Contact')+' u='+(u != null ? u.LastName : 'No User'));
      if ((c != null) && (u != null) && (u.IsActive)) {
         // add one to the number of users found
                   
         if (String.isNotBlank(c.HRPurgeEmployee__c) && c.HRPurgeEmployee__c == 'Y') {
            System.debug('checkContactUser c.HRPurgeEmployee__c');
            setUserTermed(u,Date.today());
            updateUsers.add(u);
         } else if (c.Date_of_Employee_Termination__c != null && c.Date_of_Employee_Termination__c <= Date.today()) {
            setUserTermed(u,c.Date_of_Employee_Termination__c);
            updateUsers.add(u);
         } else {
            System.debug('checkContactUser in the else');
            Boolean updated=false;
            // use the Preferred name field if it exists.
            String tempFirst = (String.isNotBlank(c.Prefered_Name__c) ? c.Prefered_Name__c : c.FirstName);
            // if any of the fields we are using changed
            if (u.Termination_Date__c != c.Date_of_Employee_Termination__c ||
                  u.Department != c.Department ||
                  (String.IsBlank(u.FirstName) || !u.FirstName.equals(tempFirst)) ||
                  !u.LastName.equals(c.LastName) ||
                  u.Hire_Date__c != c.Hire_Date__c ||
                  u.Street != c.MailingStreet ||
                  u.City != c.MailingCity ||
                  u.State != c.MailingState ||
                  u.PostalCode != c.MailingPostalCode ||
                  u.Cost_Center__c != c.Paychex_Cost_Center__c ||
                  u.Person_Id_Number__c != c.Paychex_Rep_Code__c ||
                  (supervisorU != null && u.ManagerId != supervisorU.Id) ||
                  u.Title != c.Title
                  || u.Payroll_Employee_Number__c != c.Payroll_Employee_Number__c
            ) {
               // add to list to be updated.
               updated = true;
               u.Termination_Date__c = c.Date_of_Employee_Termination__c;
               u.Department = (String.isNotBlank(c.Department) ? c.Department : u.Department);
               u.FirstName = tempFirst;
               u.LastName = c.LastName;
               u.Hire_Date__c = c.Hire_Date__c;
               u.Street = (String.isNotBlank(c.MailingStreet) ? c.MailingStreet : u.Street);
               u.City = (String.isNotBlank(c.MailingCity) ? c.MailingCity : u.City);
               u.State = (String.isNotBlank(c.MailingState) ? c.MailingState : u.State);
               u.PostalCode = (String.isNotBlank(c.MailingPostalCode) ? c.MailingPostalCode : u.PostalCode);
               u.Cost_Center__c = c.Paychex_Cost_Center__c;
               u.Person_Id_Number__c = c.Paychex_Rep_Code__c;
               u.Title = c.Title;
               
               // only update the manager if we have a new one to replace the old one
               if (supervisorU != null) {
                  u.ManagerId = supervisorU.Id;
               }
               u.Payroll_Employee_Number__c = c.Payroll_Employee_Number__c;
            } // if (String.isNotBlank(c.HRPurgeEmployee__c
            
            if (String.isNotBlank(c.Payroll_Employee_Number__c) && String.isBlank(u.EmployeeNumber)) {
               u.Non_Paychex_Employee_User_Type__c = null;
               u.Non_Paychex_Employee__c = false;
               u.EmployeeNumber = c.HR_Person_Id__c;
               u.Payroll_Employee_Number__c = c.Payroll_Employee_Number__c;
               updated = true;
            }
              //JC added user update here when active 

              if(u.FederationIdentifier ==null){ 
                 u.FederationIdentifier =u.HR_Person_Id__c;
                 updated = true; 
             }           
            if (updated) {
               System.debug('checkContactUser updates found for '+u.LastName);
               updateUsers.add(u);
               ctctIdsToUpdate.add(c.Id);
            }
         } // if (String.isNotBlank
      } // if ((c != null)
   } // checkContactUser
   
   private static void setUserTermed(User u, Date termDate) {
      System.debug('setUserTermed termDate='+termDate+' u='+u);
      if (u.IsActive) {
         u.IsActive = false;
         //jc adding set federationId to false
         u.FederationIdentifier=null;           
         //processNotes += '\n'+u.Name+' set to InActive';
         ManageUserController muc = new ManageUserController();
         muc.userTransfer.Effective_Date__c = termDate;
         muc.setTermedFields(u);
      }
      System.debug('setUserTermed after setTermedFields u='+u);
   } // setUserTermed
   
   public static Contact[] getContacts(Set<Id> ctctIdSet) {
      Contact[] ctcts = [SELECT id
                               ,Date_of_Employee_Termination__c
                               ,Department
                               ,Email
                               ,FirstName
                               ,LastName
                               ,Hire_Date__c
                               ,HR_Person_Id__c
                               ,HRPurgeEmployee__c
                               ,MailingStreet
                               ,MailingCity
                               ,MailingState
                               ,MailingPostalCode
                               ,Paychex_Cost_Center__c
                               ,Paychex_Rep_Code__c
                               ,Paychex_Org_Type__c
                               ,Paychex_Job_Family__c
                               ,Payroll_Employee_Number__c
                               ,Phone
                               ,Prefered_Name__c
                               ,ReportsTo.Id
                               ,ReportsTo.Name
                               ,ReportsTo.User_Lookup__c
                               ,ReportsTo.User_Lookup__r.Id
                               ,ReportsTo.User_Lookup__r.IsActive
                               ,ReportsTo.User_Lookup__r.Name
                               ,Supervisor_Person_Id__c
                               ,Title
                               ,User_Lookup__c
                               ,User_Lookup__r.Id
                               ,User_Lookup__r.City
                               ,User_Lookup__r.Cost_Center__c
                               ,User_Lookup__r.Department
                               ,User_Lookup__r.Email
                               ,User_Lookup__r.EmployeeNumber 
                               ,User_Lookup__r.FederationIdentifier 
                               ,User_Lookup__r.FirstName
                               ,User_Lookup__r.Hire_Date__c
                               ,User_Lookup__r.HR_Person_Id__c
                               ,User_Lookup__r.IsActive
                               ,User_Lookup__r.LastName
                               ,User_Lookup__r.ManagerId
                               ,User_Lookup__r.Name
                               ,User_Lookup__r.Non_Paychex_Employee_User_Type__c
                               ,User_Lookup__r.Non_Paychex_Employee__c
                               ,User_Lookup__r.Payroll_Employee_Number__c
                               ,User_Lookup__r.Person_Id_Number__c // the rep code
                               ,User_Lookup__r.Phone
                               ,User_Lookup__r.PostalCode
                               ,User_Lookup__r.State
                               ,User_Lookup__r.Street
                               ,User_Lookup__r.Termination_Date__c
                               ,User_Lookup__r.Title
                               ,User_Lookup__r.Username
                           FROM Contact 
                          WHERE Id in :ctctIdSet
                            and DoNotUpdateUser__c = false];
                          
      return ctcts;
   } // getContacts
   
   public static Map<String,User> getUsersByPersonId(Set<String> personIdSet) {
      List<User> users = new List<User>([Select Id
                                               ,City
                                               ,Cost_Center__c
                                               ,Department
                                               ,Email
                                               ,EmployeeNumber 
                                               ,FederationIdentifier 
                                               ,FirstName
                                               ,Hire_Date__c
                                               ,HR_Person_Id__c
                                               ,IsActive
                                               ,LastName
                                               ,ManagerId
                                               ,Name
                                               ,Non_Paychex_Employee_User_Type__c
                                               ,Non_Paychex_Employee__c
                                               ,Payroll_Employee_Number__c
                                               ,Person_Id_Number__c // the rep code
                                               ,Phone
                                               ,PostalCode
                                               ,State
                                               ,Street
                                               ,Termination_Date__c
                                               ,Title
                                               ,Username
                                               ,ProfileId, Profile.Name
                                               ,UserRoleId, UserRole.Name
                                           from User
                                          where HR_Person_Id__c in :personIdSet
                                          order by createdDate desc]);

      // for easy access by person id
      Map<String,User> usersByPersonId = new Map<String,User>();
      for (User u : users) {
         // we can use an inactive user only if there isn't an active user for the same person id.
         User mapUser = usersByPersonId.get(u.HR_Person_Id__c);
         if (mapUser == null || (!mapUser.IsActive && u.IsActive)) {
            usersByPersonId.put(u.HR_Person_Id__c,u);
         }
      } // for (User u
      return usersByPersonId;
   } // getUsersByPersonId

   
} // class ContactFormatPaychexEmps