/* 
* The methods used for assisting with User record transactions.
*
* History
* -------
* 09/16/2010 Dan Carmen   Created
04/05/2011 Dan Carmen   Modified getGroup to handle nulls.
04/15/2011 Dan Carmen   Add additional fields for User selection.
08/25/2011 Dan Carmen   Modified getQueue (getGroup) method.
12/08/2011 Dan Carmen   Added HR Solutions and DIVISION_LIST.
03/05/2012 Dan Carmen   Added getRoleMap method.
07/23/2012 Dan Carmen   Added in getProdTranslation method.
08/23/2012 Cindy Freeman   Added getRoleSubordinateSaleUsers method.
10/11/2012 Dan Carmen   Added in getDSA method
11/23/2012 Dan Carmen   Added in getContactById method.
12/10/2012 Dan Carmen   Added in getProfile method.
12/19/2012 Dan Carmen   Added in checkForDsaField method.
01/22/2013 Dan Carmen   Changes to allow Temporary Emps/Reactivations
03/21/2013 Dan Carmen   Added check to populate new Job Name field
05/06/2013 Cindy Freeman   Added set of Wholesaler user titles to determine if user is a wholesaler 
08/16/2013 Justin Stouffer   Added MSP, EW (ExpenseWire), RPS, and Merchant Services Sales Orgs   
10/03/2013 Dan Carmen   Code changes for NSS
10/05/2013 Cindy Freeman      Added method to return queue record when pass in the id
01/16/2014 Dan Carmen   Added method to return the running user
03/01/2014 Dan Carmen   Changes for NSS
04/01/2014 Cindy Freeman      Added check of Lead Loader user
03/02/2015 Dan Carmen   Changed checkForDsaField to checkInactiveUser. Added extra deletes.
04/22/2015 Dan Carmen   Added isUserVisible method
10/27/2015 Dan Carmen   Added caching for the running user
07/26/2016 Dan Carmen   Added fields to the contact query.
07/27/2016 Dan Carmen   Added getContactMapByEmail method.
11/28/2016 Cindy Freeman   changed MARKETO variable from 'Marketo API_User' to 'Corporate Marketing'
01/06/2017 Dan Carmen      Ability to have multiple inbound and outbound profile names
04/03/2017 Justin Stouffer Added checkADUsername.
05/11/2017 Dan Carmen      Add more options for determining the sales rep job name
05/23/2017 Cindy Freeman     Added getUserIM method.   
06/03/2017 Dan Carmen        Enhanced the method for retrieving queues to use the cache.
06/27/2017 Jacob Hinds      Adding getUserRoleByIdMap method
07/17/2017 Cindy Freeman      Modified getUserIM method to handle one user covering multiple zones
10/16/2017 Dan Carmen   Code Cleanup
03/12/2018 Carrie Marciano   Added ForecastEnabled to the userQuery
04/16/2018 Jermaine Stukes   Added getProfiles, queries list rather than one profile
06/08/2018 Cindy Freeman     removed getUserIM method and moved it to QuoteMethods class
08/14/2018 Dan Carmen         Added check for ASO_Partner__c in checkInactiveUser
09/05/2018 Jake Hinds        Adding aso partner
09/18/2018 Dan Carmen        Added cache for runningUser
10/09/2018 Jacob Hinds       adding more aso partner fields
12/14/2018 Dan Carmen        Modify checkForJobName to use the Profile_List__c custom setting
01/31/2019 Dan Carmen        Add check in getProdTranslation to make sure the salesOrg field isn't too long for the custom setting
03/11/2019 Jacob Hinds       Adding in PEO Sales Org
07/09/2019 Dan Carmen         Use custom metadata type for Job Name
09/23/2019 Jacob Hinds        User query fields
12/17/2019 Brandon Vidro     Added check to queryQueues before performing query. 
01/02/2019 Jacob Hinds     Adding PEO into DIVISION_LIST
01/02/2020 Josh Cartwright   added setFederationID
04/29/2020 Saketh Mysa        Add new Sales Orgs PC, MS, ESR, PBA
07/28/2020 Dan Carmen         update isRunningUserGuest method
04/16/2021 Dan Carmen         Clean up debug statements
06/22/2021 Dan Carmen         Added a static userMap to prevent querying the same user more than once. 
08/25/2021 Dan Carmen         Add runningUserIsCoe
11/05/2021 Dan Carmen         Add isRunningUserAnySystemAdmin method
12/20/2021 Carrie Marciano	  Added sales org BusDev
01/04/2022 Eric Porter        Added String.escapeSingleQuotes to getUserByPersonId
01/28/2022 Carrie Marciano	  Added getCPQUserQuery to be used with Manage Users
03/14/2022 Carrie Marciano	Added sales org BenAdmin
04/15/2022 Dan Carmen         Add findUserRoles method
07/19/2022 Dan Carmen         Add another parameter to findUserRoles
05/29/2023 Dan Carmen         Add exception handling in getProdTranslation
10/31/2023 Dan Carmen         Update getContact methods to store a copy in a static map in case the same contact is retrieved more than once in a session
11/03/2023 Dan Carmen         Update setUserFromContact to include the Payroll_Employee_Number__c
01/03/2024 Dan Carmen         Remove User License references

*/ 
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
public with sharing class UserHelper {
    
    public static final String UNKNOWN='NameUnknown';
    
    /** The Sales Org for Core Payroll. */
    public static final String SO_CORE='PAY';
    /** The Sales Org for MMS. */
    public static final String SO_MMS='MMS';
    /** The Sales Org for HRS-401k. */
    public static final String SO_401='HRS';
    /** The Sales Org for the SO organization. */
    public static final String SO_PEO_ASO='PAS';
    /** The Sales Org for the SO organization. */
    public static final String SO_PEO='PEO';
    /** The Sales Org for PBS. */
    public static final String SO_PBS='PBS';
    /** The Sales Org for the HNB Field organization. */
    public static final String SO_HNB='HNBF';
    /** The Sales Org for the BenAdmin organization. */
    public static final String SO_BenAdmin = 'BenAdmin';
    /** The Sales Org for the ExpenseWire organization. */
    public static final String SO_EW = 'EW';
    /** The Sales Org for the MSP organization. */
    public static final String SO_MSP = 'MSP';
    /** The Sales Org for the RPS organization. */
    public static final String SO_RPS = 'RPS';
    /** The Sales Org for the Merchant Services organization. */
    public static final String SO_MS = 'MS';
    /** The Sales Org for the TAA organization. */
    public static final String SO_TAA = 'TAA';
    /** The Sales Org for the BusDev organization. */
    public static final String SO_BusDev = 'BusDev';
    /*Added by Saketh*/
    /** The Sales Org for the PC organization. */
    public static final String SO_PC = 'PC';
    /** The Sales Org for the MS organization. */
    //public static final String SO_MS = 'MS';
    /** The Sales Org for the ESR organization. */
    public static final String SO_ESR = 'ESR';
    /** The Sales Org for the PBA organization. */
    public static final String SO_PBA = 'PBA';
    /*Added by Saketh*/
    
    /** The Sales Org for NSS */
    public static final String SO_NSS = 'NSS';
    /** The Sales Org for Advantage */
    public static final String SO_ADV='ADV';
    
    /** The Sales Org for PAY */
    public static final String SO_PAY='PAY';// addedbysana
    
    /** HR Solutions. */
    public static final String SO_HR_SOL = 'HR Solutions';
    /** Agency. */
    public static final String SO_AGENCY = 'Agency';
    
    public static final String SO_WHOLESALER = 'HRS WHOLESALER';
    
    public static String WHOLESALER_INTERNAL='INTERNAL';
    public static String WHOLESALER_EXTERNAL='EXTERNAL';
    
    /*** Person ids of generic users. *****/   
    public static String UNASSIGNED_CORE_PERSON_ID='821';
    public static String UNASSIGNED_MMS_PERSON_ID='75';
    public static String VIRTUAL_SALES_PERSON_ID='9';
    public static String HRS_VIRTUAL_SALES_PERSON_ID='20';
    
    public static String[] UNASSIGNED = new String[]{UNASSIGNED_CORE_PERSON_ID,UNASSIGNED_MMS_PERSON_ID};
        public static Set<String> UNASSIGNED_SET = new Set<String>{UNASSIGNED_CORE_PERSON_ID,UNASSIGNED_MMS_PERSON_ID};
            
            
            public static final Set<String> WHOLESALER_TITLES_SET = new Set<String> {'Internal Retirement Plan Wholesaler', 'Regional Retirement Wholesaler'};
                
                public static final String[] DIVISION_LIST = new String[]{SO_CORE,SO_MMS
                    ,SO_401,SO_PEO,SO_PEO_ASO,SO_HNB,SO_EW,SO_MSP,SO_MS,SO_ADV,SO_RPS,SO_TAA,SO_PC,SO_ESR,SO_PBA,SO_BusDev,SO_BenAdmin}; //,SO_PC
                        
                        public static final Set<String> DIVISION_LIST_SET = new Set<String>{SO_CORE,SO_MMS
                            ,SO_401,SO_PEO,SO_PEO_ASO,SO_HNB,SO_EW,SO_MSP,SO_MS,SO_ADV,SO_RPS,SO_TAA,SO_PC,SO_ESR,SO_PBA,SO_BusDev,SO_BenAdmin}; //,SO_PC
                                
                                public static Set<String> divisionStructureSet = null;
    // get a set of divisions that have an organization structure
    public static Set<String> getDivisionStructureSet() {
        if (divisionStructureSet == null) {
            divisionStructureSet = new Set<String>();
            for (SalesOrg__c salesOrg : SalesOrg__c.getAll().values()) {
                if (salesOrg.HasOrgStructure__c) {
                    divisionStructureSet.add(salesOrg.Name);
                }
            }
            // for backwards compatibility/testing - eventually should remove this
            if (divisionStructureSet.isEmpty()) {
                divisionStructureSet.addAll(DIVISION_LIST);
            }
        } // if (divisionStructureSet == null
        return divisionStructureSet;
    } // getDivisionStructureSet
    
    public static List<String> getDivisionStructureList() {
        List<String> divisionStructureList = new List<String>();
        divisionStructureList.addAll(getDivisionStructureSet());
        return divisionStructureList;
    } // getDivisionStructureList
    
    /*  JGS - Added the following exclude variables to workaround the displaylist size comparison in the ReferralControllerTest and ZipCheckOwnerTests. 
Sales Orgs that do not currently fit in the zip assignment hierarchy should be added here.*/           
    public static final String[] EXCLUDE_DIVISION_LIST = new String[]{SO_EW,SO_MSP,SO_MS,SO_RPS};
        public static final Set<String> EXCLUDE_DIVISION_LIST_SET = new Set<String>{SO_EW,SO_MSP,SO_MS,SO_RPS};
            
            public static final String PAYCHEX_COMP='Paychex Inc SA';
    
    /** The record type name for a license request. */
    public static final String RT_LICENSE_REQUEST='Add License';
    /** The record type name for the licensing budget. */
    public static final String RT_LICENSE_BUDGET='Budget';
    
    /** No argument constructor.
*/
    public UserHelper() {
    } // UserHelper
    
    /** Is this a core user based on the Sales Org?
*/
    public Boolean isCore(String salesOrg) {
        return (salesOrg != null && salesOrg == SO_CORE);
    } // isCore
    
    /** Is this an MMS user based on the Sales Org?
*/
    public Boolean isMMS(String salesOrg) {
        return (salesOrg != null && salesOrg == SO_MMS);
    } // isMMS
    
    public Boolean isHNB(String salesOrg) {
        return (String.isNotBlank(salesOrg) && salesOrg == SO_HNB);
    }
    
    public Boolean isMSP(String salesOrg) {
        return (String.isNotBlank(salesOrg) && salesOrg == SO_MSP);
    }
    public Boolean isTAA(String salesOrg) {
        return (String.isNotBlank(salesOrg) && salesOrg == SO_TAA);
    }    
    /*Added By Saketh*/
    public Boolean isPC(String salesOrg) {
        return (String.isNotBlank(salesOrg) && salesOrg == SO_PC);
    } 
    
    public Boolean isMS(String salesOrg) {
        System.debug('is MS in User Helper : ' + salesOrg);
        System.debug('is MS in User Helper : ' + SO_MS);
        return (String.isNotBlank(salesOrg) && salesOrg == SO_MS);
    }
    
    public Boolean isESR(String salesOrg) {
        return (String.isNotBlank(salesOrg) && salesOrg == SO_ESR);
    } 
    
    public Boolean isPBA(String salesOrg) {
        return (String.isNotBlank(salesOrg) && salesOrg == SO_PBA);
    }
    /*End Added By Saketh*/
    /** Is this an HRS user based on the Sales Org?
*/
    public Boolean isHRS(String salesOrg) {
        return (salesOrg != null && (salesOrg == SO_401 ||
                                     salesOrg == SO_PEO_ASO ||
                                     salesOrg == SO_PBS ||
                                     salesOrg == SO_HNB));
    } // isCore
    
    public Boolean isPEO(String salesOrg){
        return (salesOrg != null && salesOrg == SO_PEO);
    }//isPEO
    
    public String getSalesOrgTranslation(String checkSO) {
        String retVal = checkSO;
        if (checkSO != null) {
            if (checkSO == SO_HR_SOL) {
                retVal = SO_PEO_ASO;
            } else if (checkSO == SO_PEO_ASO) {
                retVal = SO_HR_SOL;
            }
        } // if (checkSO != null
        return retVal;
    } // getSalesOrgTranslation
    
    // Translate a sales org to a more descriptive name.
    public String getProdTranslation(String salesOrg) {
        String prod = salesOrg;
        if (String.isNotBlank(salesOrg)) {
            try {
               // check length and remove extra characters we don't want
               String cleanName = RecordTypeHelper.cleanRtName(salesOrg);
               SalesOrg__c salesOrgObj = SalesOrg__c.getInstance(cleanName);
               if (salesOrgObj != null) {
                   prod = salesOrgObj.Description__c;
               }
            } catch (Exception e) {
               System.debug('getProdTranslation e='+e.getMessage()+'; '+e.getStackTraceString());
            }
        } // if (String.isNotBlank(
        
        return prod;
    } // getProdTranslation
    
    
    /** Update fields on the User from the matching Contact record.
*/
    public void setUserFromContact(User usr, Contact ctct) {
        String tempFirst = (ctct.Prefered_Name__c != null ? ctct.Prefered_Name__c : ctct.FirstName);
        usr.FirstName = tempFirst;
        usr.LastName = ctct.LastName;
        usr.City = ctct.MailingCity;
        usr.Cost_Center__c = ctct.Paychex_Cost_Center__c;
        usr.Department = ctct.Department;
        // EmployeeNumber is the HR Person Id
        usr.EmployeeNumber = ctct.HR_Person_Id__c;
        usr.Hire_Date__c = ctct.Hire_Date__c;
        usr.HR_Person_Id__c = ctct.HR_Person_Id__c;
        usr.Payroll_Employee_Number__c = ctct.Payroll_Employee_Number__c;
        // Person_Id_Number is the rep code.
        usr.Person_ID_Number__c = ctct.Paychex_Rep_Code__c;
        usr.Phone = ctct.Phone;
        usr.PostalCode = ctct.MailingPostalCode;
        usr.State = ctct.MailingState;
        usr.Street = ctct.MailingStreet;
        usr.Termination_Date__c = ctct.Date_of_Employee_Termination__c;
        usr.Title = ctct.Title;
        // if there is a person id, see if there is an active user record with that person id.
        if (ctct.Supervisor_Person_Id__c != null) {
            try {
                User testUser = [Select Id, Name from User where IsActive=true and HR_Person_Id__c=:ctct.Supervisor_Person_Id__c limit 1];
                if (testUser != null) {
                    usr.ManagerId = testUser.Id;
                }
            } catch (System.QueryException e) {
                // do nothing here
            }
        } // if (thisC.Supervisor_Person_Id__c
    } // setContactFields
    
    /** Check to see if the Sales Org and cost center match to a value in the organization_Structure object.
*/
    public void checkOrganization(User usr) {
        User[] users = new User[]{usr};
            UpdateOrgInfo.SetUserInfo(users);
    } // checkOrganization
    
    /*
public static final String OLDuserQuery = 'Select Id, IsActive'+
',Alias'+
',Area_Nbr__c'+
',Areatxt__c'+
',ASO_Partner__c'+
',ASO_Partner__r.Id'+          
',ASO_Partner__r.IsActive'+        
',ASO_Partner__r.ManagerId'+        
',ASO_Partner__r.Name'+          
',ASO_Partner__r.HR_Person_Id__c'+  
',ASO_Partner__r.Non_Paychex_Employee__c'+
',ASO_Partner__r.Non_Paychex_Employee_User_Type__c'+
',ASO_Partner__r.NSS_Team__c'+
',ASO_Partner__r.Sales_Org__c'+
',ASO_Partner__r.Profile.Name'+
',ASO_Partner__r.Title'+
',CommunityNickname'+
',City'+
',CompanyName'+
',Cost_Center__c'+
',District__c'+
',District_Name__c'+
',DistrictsManaged__c'+
',Department'+
',DSA_FSS__c'+
',Email'+
',EmailEncodingKey'+
',EmployeeNumber'+
',FirstName'+
',ForecastEnabled'+   
',Hire_Date__c'+
',HR_Person_Id__c'+
',Job_Name__c'+
',LanguageLocaleKey'+
',LastLoginDate'+
',LastName'+
',License_Type__c'+
',License_Type_Delegation__c'+
',LocaleSidKey'+
',ManageZipOrgUnitsManaged__c'+
',ManagerId'+
',Manager.Name'+
',MobilePhone'+
',Name'+
',Non_Paychex_Employee__c'+
',Non_Paychex_Employee_User_Type__c'+
',NSS_Territory_Nbr__c'+
',NSS_Team__c'+
',Person_ID_Number__c'+
',Phone'+
',PilotUser__c'+
',ProfileId'+
',Profile.Id'+
',Profile.Name'+
',PostalCode'+
',Sales_Org__c'+
',SalesOfficeNumber__c'+
',Sales_Division__c'+
// ',SalesOrgsManaged__c'+
',Schedule_Indicator__c'+
',SFDC_User_Start_Date__c'+
',Start_Date__c'+
',State'+
',Street'+
',Termination_Date__c'+
',TimeZoneSidKey'+
',Title'+
',Username'+
',UserPermissionsMobileUser'+
',UserRoleId'+
',UserRole.Id'+
',UserRole.Name'+
',UserRole.ParentRoleId'+
',UserType'+
',User_Type__c'+
',Zone__c'+
',Zonetxt__c'+
' from User ';
*/
    public static String userQuery=null;
    public static String cpqUserQuery=null;
    public static String USER_CACHEKEY='UserQueryCacheKey';
    public static String CPQ_USER_CACHEKEY='CPQUserQueryCacheKey';
    public static String getUserQuery() {
        if (userQuery == null) {
            userQuery = (String)CacheManager.getOrg(USER_CACHEKEY);
            System.debug('getUserQuery userQuery: '+userQuery);
        }
        if (userQuery == null) {
            Set<String> fldSet = new Set<String>();
            Schema.FieldSet userFldSet = Schema.SObjectType.User.fieldSets.UserHelper_QueryFlds;
            for (Schema.FieldSetMember fsm : userFldSet.getFields()) {
                String fldName = fsm.getFieldPath();
                fldSet.add(fldName);
            }
            fldSet.addAll(Label.UserHelper_ExtraQueryFlds.split(','));
            String[] fldList = new String[]{};
                fldList.addAll(fldSet);
            fldList.sort();
            userQuery = 'Select '+String.join(fldList,',')+' From User ';
            CacheManager.putOrg(USER_CACHEKEY,userQuery);
        }
        return userQuery;
    } // getUserQuery
    
    public static String getCPQUserQuery() {
        if (cpqUserQuery == null) {
            cpqUserQuery = (String)CacheManager.getOrg(CPQ_USER_CACHEKEY);
            System.debug('getCPQUserQuery cpqUserQuery: '+cpqUserQuery);
        }
        if (cpqUserQuery == null) {
            Set<String> cpqfldSet = new Set<String>();
            Schema.FieldSet cPQUserFldSet = Schema.SObjectType.cafsl__Oracle_User__c.fieldSets.UserHelper_QueryFlds;
            System.debug('getCPQUserQuery cPQUserFldSet: '+cPQUserFldSet);  
            for (Schema.FieldSetMember fsm : cPQUserFldSet.getFields()) {
                String fldName = fsm.getFieldPath();
                cpqfldSet.add(fldName);
            }
            String[] cpqfldList = new String[]{};
                cpqfldList.addAll(cpqfldSet);
            cpqfldList.sort();
            cpqUserQuery = 'Select '+String.join(cpqfldList,',')+' From cafsl__Oracle_User__c ';
            CacheManager.putOrg(CPQ_USER_CACHEKEY,cpqUserQuery);
        }
        return cpqUserQuery;
    } // getCPQUserQuery
    
    
    // Get a User record by the Id. A null is returned if not found.
    public User getUserById(Id userId) {
        User usr = userMap.get(userId);
        if (usr == null) {
            String whereClause = 'where Id = \''+userId+'\' ';
            // get the users
            User[] usrs = getUsers(whereClause);
            // should only be one record returned
            if (usrs.size() > 0 ) {
                usr = usrs.get(0);
                userMap.put(userId,usr);
            }
        } // if (usr == null
        
        return usr;
    } // getUserById
    
    public static Map<Id,User> getUserMapById(Set<Id> p_userIdSet) {
        Set<Id> userIdSet = new Set<Id>();
        userIdSet.addAll(p_userIdSet);
        
        String query = getUserQuery()+' where Id in :userIdSet';
        System.debug('getUserMapById p_userIdSet='+p_userIdSet);
        Map<Id,User> userMap = new Map<Id,User>((List<User>)Database.query(query));
        return userMap;
    } // getUserMapById
    
    // keep track of users retrieved in this session so only retrieved once.
    public static Map<String,User> userMap = new Map<String,User>();
    // Get a User record by the Id. A null is returned if not found.
    public User getUserByPersonId(String personId) {
        User usr = (String.isNotBlank(personId) ? userMap.get(personId) : null);
        if (usr == null && String.isNotBlank(personId)) {
            String whereClause = 'where IsActive=true and HR_Person_Id__c = \''+String.escapeSingleQuotes(personId)+'\' limit 1 ';
            // get the users
            User[] usrs = getUsers(whereClause);
            // should only be one record returned
            if (usrs.size() > 0 ) {
                usr = usrs.get(0);
                userMap.put(personId,usr);
            }
        } // if (usr == null
        
        return usr;
    } // getUserByPersonId
    
    /** Get the users based on the where clause passed in
*/
    public User[] getUsers(String whereClause) {
        String query = getUserQuery()+(whereClause != null ? whereClause : '');
        System.debug('getUsers whereClause='+whereClause);
        User[] users = Database.query(query);
        return users;
    } // getUsers
    
    /** pass in list of Users and see if there is a CPQ user for them*/ 
    public cafsl__Oracle_User__c[] getCPQUsers(String whereClause){
        String cpqQuery = getCPQUserQuery()+(whereClause != null ? whereClause : '');
        cafsl__Oracle_User__c[] cpqUsers = NULL;
        System.debug('getCPQUsers cpqQuery='+cpqQuery);
        try {
            cpqUsers = Database.query(cpqQuery);
        } catch (Exception e) {
            
        }
        return cpqUsers; 
    }
    
    public static final String ctctQuery = 'Select Id'+
        ',Date_of_Employee_Termination__c'+
        ',Department'+
        ',Email'+
        ',FirstName'+
        ',Hire_Date__c'+
        ',HR_Person_Id__c'+
        ',LastName'+
        ',MailingCity'+
        ',MailingPostalCode'+
        ',MailingState'+
        ',MailingStreet'+
        ',Name'+
        ',Paychex_Cost_Center__c'+
        ',Paychex_Rep_Code__c'+
        ',Payroll_Employee_Number__c'+
        ',Phone'+
        ',Prefered_Name__c'+
        ',Supervisor__c'+
        ',Supervisor_Person_Id__c'+
        ',Title'+
        ',User_Lookup__c'+
        ' from Contact ';
    
    // keep track of contacts retrieved so we only retrieve them once a session
    Map<String,Contact> ctctMap = new Map<String,Contact>();
    
    // Get a Paychex Employee Contact record by the HR person Id.
    public Contact getContactByPersonId(String personId, String acctName) {
        String key = personId+acctName;
        Contact ctct = ctctMap.get(key);
        if (ctct == null) {
           // will always be attached to PAYCHEX_COMP - we'll ignore the passed in parameter
           String whereClause = 'where HR_Person_Id__c = \''+personId+'\' and Account.Name=\''+PAYCHEX_COMP+'\' ';
           // get the contacts
           Contact[] ctcts = getContacts(whereClause);
           // should only be one record returned
           if (ctcts.size() > 0 ) {
               ctct = ctcts.get(0);
               ctctMap.put(key,ctct);
           }
            
        } // if (ctct == null
        return ctct;
    } // getContactByPersonId
    
    // Get a Contact record by the record Id.
    public Contact getContactById(Id ctctId) {
        String key=ctctId;
        Contact ctct = ctctMap.get(key);
        if (ctct == null) {
           String whereClause = 'where Id = \''+ctctId+'\' ';
           // get the contacts
           Contact[] ctcts = getContacts(whereClause);
           // should only be one record returned
           if (ctcts.size() > 0 ) {
               ctct = ctcts.get(0);
               ctctMap.put(key,ctct);
           }
        }
        return ctct;
    } // getContactById
    
    /** Get the contacts based on the where clause passed in
*/
    public Contact[] getContacts(String whereClause) {
        String query = ctctQuery+(whereClause != null ? whereClause : '');
        System.debug('getContacts query='+query);
        Contact[] ctcts = Database.query(query);
        return ctcts;
    } // getContacts
    
    public static Map<String,Contact> getContactMapByEmail(Set<String> emailSet) {
        Map<String,Contact> ctctMap = new Map<String,Contact>();
        String[] emailList = new String[]{};
            emailList.addAll(emailSet);
        String query = ctctQuery+' where Date_of_Employee_Termination__c=null and HR_Person_Id__c != null and Email in :emailList ';
        for (Contact ctct : Database.query(query)) {
            ctctMap.put(ctct.Email, ctct);
        } // for
        
        return ctctMap;
    } // getContactMapByEmail
    
    
    /** Get the user Id from the email address.
*/
    public String getUserId(String email, Integer max) {
        String userId = '';
        if (email != null) {
            // get the position of the @ sign
            Integer pos = email.indexOf('@');
            if (pos > -1) {
                userId = email.substring(0,pos);
            }
        } // if (email != null
        if ((max != null) && (userId.length() > max)) {
            userId = userId.substring(0,max);
        }
        return userId;
    } // getUserId
    
    /** The Community Nickname needs to be unique within an organization. This method 
*  checks to see if another instance of it exists. 
*/
    public String getUniqueNicknameByEmail(String email) {
        String userId = getUserId(email,null);
        return getUniqueNickname(userId);
    } // getUniqueNicknameByEmail
    
    /** The Community Nickname needs to be unique within an organization. This method 
*  checks to see if another instance of it exists. 
*/
    public String getUniqueNickname(String userId) {
        Boolean keepLooking = true;
        String checkValue = userId;
        Integer counter = 0;
        
        while (keepLooking) {
            Integer nbrFound = [select count() from User where CommunityNickname = :checkValue];
            if (nbrFound == 0) {
                break;
            }
            checkValue = userId+counter;
            counter++;
        } // while
        return checkValue;
    } // getUniqueNickname
    
    public static String CACHE_KEY_QUEUE_NAME = 'UserHelperqueueByNameMap';
    public static String CACHE_KEY_QUEUE_ID = 'UserHelperqueueByIdMap';
    
    // All of the Groups retrieved
    private static Map<String,Group> queueByNameMap = null;
    private static Map<Id,Group> queueByIdMap = null;
    
    public static void checkQueueMaps() {
        if (queueByNameMap == null) {
            queueByNameMap = (!Utilities.SKIP_CACHE ? (Map<String,Group>)Cache.Org.get(CACHE_KEY_QUEUE_NAME) : null);
            System.debug('checkGrpsByKeyMap for '+CACHE_KEY_QUEUE_NAME+' found in cache='+(queueByNameMap != null)+' Utilities.SKIP_CACHE='+Utilities.SKIP_CACHE+' Utilities.CACHE_IN_USE='+Utilities.CACHE_IN_USE);
            if (queueByNameMap == null) {
                queueByNameMap = new Map<String,Group>();
            }
        }
        if (queueByIdMap == null) {
            queueByIdMap = (!Utilities.SKIP_CACHE ? (Map<Id,Group>)Cache.Org.get(CACHE_KEY_QUEUE_ID) : null);
            System.debug('checkGrpsByKeyMap for '+CACHE_KEY_QUEUE_ID+' found in cache='+(queueByIdMap != null)+' Utilities.SKIP_CACHE='+Utilities.SKIP_CACHE+' Utilities.CACHE_IN_USE='+Utilities.CACHE_IN_USE);
            if (queueByIdMap == null) {
                queueByIdMap = new Map<Id,Group>();
            }
        }
    } // checkQueueMaps
    
    public static Map<Id,Group> getQueueMapById(Id[] queueIds) {
        checkQueueMaps();
        Id[] idsToQuery = new Id[]{};
            // collect the ids we don't have a record for
            for (Id queueId : queueIds) {
                if (!queueByIdMap.containsKey(queueId)) {
                    idsToQuery.add(queueId);
                }
            } // for (Id queueId
        queryQueues(queueIds, new String[]{});
        return queueByIdMap;
    } // getQueueMapById
    
    public static Map<String,Group> getQueueMapByName(String[] queueNames) {
        checkQueueMaps();
        String[] namesToQuery = new String[]{};
            // collect the ids we don't have a record for
            for (String queueName : queueNames) {
                if (!queueByNameMap.containsKey(queueName)) {
                    namesToQuery.add(queueName);
                }
            } // for (Id queueId
        queryQueues(new Id[]{}, namesToQuery);
        return queueByNameMap;
    } // getQueueMapByName
    
    public static void queryQueues(Id[] queueIds, String[] queueNames) {
        if(!queueIds.isEmpty() || !queueNames.isEmpty()) {
            Group[] queryQueues = [Select Id, Type, OwnerId, Name, Email from Group 
                                   where Type = 'Queue'
                                   and (Name in :queueNames or Id in :queueIds)];
            if (!queryQueues.isEmpty()) {
                // add the records found to the maps
                for (Group queue : queryQueues) {
                    queueByNameMap.put(queue.Name, queue);
                    queueByIdMap.put(queue.Id, queue);
                }
                // store in cache if we're using it
                if (!Utilities.SKIP_CACHE && Utilities.CACHE_IN_USE) {
                    Cache.Org.put(CACHE_KEY_QUEUE_NAME,queueByNameMap);
                    Cache.Org.put(CACHE_KEY_QUEUE_ID,queueByIdMap);
                }
            }
        }
        
    } // queryQueues
    
    // groups by Name
    private static Map<String,Group> grps = new Map<String,Group>();
    // Get a group
    public Group getGroup(String groupName) {
        Group grp = grps.get(groupName);
        if (grp == null && String.isNotBlank(groupName)) {
            Group[] queryGrps = [Select Id, Type, OwnerId, Name, Email from Group 
                                 where Name = :groupName];
            if (!queryGrps.isEmpty()) {
                grp=queryGrps[0];
                grps.put(groupName, grp);
            }
        } // if (grp == null
        return grp;
    } // getGroup
    
    /** Get the Queue object for the passed in name.
*/
    public Group getQueue(String queueName) {
        Group queue = null;
        if (String.isNotBlank(queueName)) {
            getQueueMapByName(new String[]{queueName});
            queue = queueByNameMap.get(queueName);

        } // if (queueName != null
        return queue;
    } // getQueue
    
    /** Get all of the queues for the passed in names.
*/
    public Map<String,Group> getQueues(String[] queueNames) {
        return (getQueueMapByName(queueNames));

    } // getQueues
    
    //private static Map<Id,Group> queueByIdMap = new Map<Id,Group>();
    
    // Get queue for passed in id. returns null if not found
    public Group getQueueById(Id queueId) {
        getQueueMapById(new Id[]{queueId});
        return (queueByIdMap.get(queueId));
    } // getQueueById
    
    /** Get the UserRole details of the passed in role ids.
*/
    public Map<Id,UserRole> getRoleMap(Id[] userRoleIds) {
        Map<Id,UserRole> roleMap = new Map<Id,UserRole>();
        if (userRoleIds != null && !userRoleIds.isEmpty()) {
            roleMap = new Map<Id,UserRole>([Select Id, Name
                                            ,ParentRoleId
                                            From UserRole
                                            Where Id in :userRoleIds]);
        } // if (userRoleIds
        return roleMap;
    } // getRoleMap
    
    
    public static final String ORG_DISTRICT='District';
    public static final String ORG_ZONE='Zone';
    public static final String ORG_AREA='Area';
    
    /** Takes passed in user id, looks up role, then gathers user ids of sales reps in subRoles
*/
    public Set<ID> getRoleSubordinateSaleUsers(Id userId) {
        Map<Id,User> users = getRoleSubordinateSaleUsersMap(userId,Utilities.REP_PROFS);
        return users.keySet();
    } // getRoleSubordinateSaleUsers
    
    /** Get a map of all users under the passed in user that meets the profile criteria.
*/
    public Map<Id,User> getRoleSubordinateSaleUsersMap(Id userId, Set<String> profileNames) {
        
        // get requested user's role
        Id roleId = [select UserRoleId from User where Id = :userId].UserRoleId;
        // get all of the roles underneath the user
        Set<Id> allSubRoleIds = getAllSubRoleIds(new Set<ID>{roleId});
        // get all of the ids for the Sales users in those roles
        Map<Id,User> users = new Map<Id, User>([Select Id, Name, Job_Name__c, Title
                                                ,FirstName
                                                ,LastName
                                                ,IsActive
                                                ,Profile.Id
                                                ,Profile.Name
                                                ,UserRole.Id
                                                ,UserRole.Name
                                                From User 
                                                where UserRoleId IN :allSubRoleIds
                                                and Profile.Name in :profileNames]);
        
        return users;
    }  // getRoleSubordinateUsers
    
    public Set<ID> getAllSubRoleIds(Set<ID> roleIds) {
        Set<ID> currentRoleIds = new Set<ID>();
        // get all of the roles underneath the passed roles
        for(UserRole userRole :[select Id from UserRole where ParentRoleId IN :roleIds AND ParentRoleID != null])
            currentRoleIds.add(userRole.Id);
        // go fetch some more rolls!
        if(currentRoleIds.size() > 0)
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        
        return currentRoleIds;
    } // getAllSubRoleIds
    
    public static Map<Id,UserRole> getUserRoleByIdMap(Id topRoleId) {
        Map<Id,UserRole> userRoleMap = new Map<Id,UserRole>();
        if (topRoleId != null) {
            Integer levelCount = 0;
            Boolean okayToContinue = true;
            Id[] queryIds = new Id[]{topRoleId};
                while (okayToContinue && levelCount < 10) {
                    UserRole[] roles = getUserRolesByParentId(queryIds);
                    if (roles.isEmpty()) {
                        okayToContinue = false;
                    } else {
                        queryIds.clear();
                        levelCount++;
                        for (UserRole role : roles) {
                            userRoleMap.put(role.Id, role);
                            queryIds.add(role.Id);
                        } // for
                    }
                } // while
        } // if (topLevelRole
        return userRoleMap;
    } // getUserRoleMap
    
   // get all of the roles starting with the top level(s). Store the values by Role Name, and also store children by the parent id.
   // This reduces the searches needed
   public static void findUserRoles(String[] topLevelRoles, Map<String,UserRole> byNameMap, Map<Id,UserRole[]> byParentIdMap, Map<Id,UserRole> byIdMap) {
      for (String roleName : topLevelRoles) {
         UserRole topLevelRole = getRoleByName(roleName);
         if (topLevelRole != null) {
            byNameMap.put(topLevelRole.Name.trim().toUpperCase(),topLevelRole);
            // to make sure we don't dive too deep into the heirarchy
            Integer levelCount = 0;
            Boolean okayToContinue = true;
            Id[] queryIds = new Id[]{topLevelRole.Id};
            while (okayToContinue && levelCount < 8) {
               UserRole[] roles = getUserRolesByParentId(queryIds);
               if (roles.isEmpty()) {
                  okayToContinue = false;
               } else {
                  queryIds.clear();
                  for (UserRole role : roles) {
                     // put key as all upper case - case insensitive
                     byNameMap.put(role.Name.trim().toUpperCase(), role);
                     byIdMap.put(role.Id, role);
                     // store the children under the parent so we can narrow our search criteria if needed if we need to search the names. 
                     UserRole[] byParentId = (byParentIdMap.containsKey(role.ParentRoleId) ? byParentIdMap.get(role.ParentRoleId) : new UserRole[]{});
                     byParentId.add(role);
                     byParentIdMap.put(role.ParentRoleId,byParentId);
                     queryIds.add(role.Id);
                  } // for
               }
            } // while
         } // if (topLevelRole != null
      } // for (String roleName : topLevelRoles
   } // findUserRoles
    
    // Get a map of all of the UserRoles starting with the passed in role. Key will be all uppercase.
    public static Map<String,UserRole> getUserRoleMap(String topRoleName) {
        String key = 'getUserRoleMap'+topRoleName;
        // see if it exists in the cache - this is too large for the cache in test
        Map<String,UserRole> userRoleMap = null; //(Map<String,UserRole>)CacheManager.getOrg(key);
        //Map<String,UserRole> userRoleMap = new Map<String,UserRole>();
        if (userRoleMap == null) {
            userRoleMap = new Map<String,UserRole>();
            // get the top level role
            UserRole topLevelRole = getRoleByName(topRoleName);
            if (topLevelRole != null) {
                Integer levelCount = 0;
                Boolean okayToContinue = true;
                Id[] queryIds = new Id[]{topLevelRole.Id};
                    while (okayToContinue && levelCount < 10) {
                        UserRole[] roles = getUserRolesByParentId(queryIds);
                        if (roles.isEmpty()) {
                            okayToContinue = false;
                        } else {
                            queryIds.clear();
                            for (UserRole role : roles) {
                                // put key as all upper case - case insensitive
                                userRoleMap.put(role.Name.trim().toUpperCase(), role);
                                queryIds.add(role.Id);
                            } // for
                        }
                    } // while
            } // if (topLevelRole
            //if (!userRoleMap.isEmpty()) {
            //   CacheManager.putOrg(key,userRoleMap);
            //}
        } // if (userRoleMap == null
        return userRoleMap;
    } // getUserRoleMap
    
    public static UserRole getRoleByName(String roleName) {
        UserRole ur = null;
        if (String.isNotBlank(roleName)) {
            try {
                ur = [Select Id
                      ,Name
                      ,ParentRoleId
                      ,DeveloperName
                      From UserRole
                      Where Name=:roleName];
            } catch (Exception e) {
                // do nothing
            }
        }
        return ur;
    } // getRoleByName
    
    public static UserRole[] getUserRolesByParentId(Id[] parentIds) {
        UserRole[] roles = [Select Id
                            ,Name
                            ,ParentRoleId
                            ,DeveloperName
                            ,(Select Id, Name
                              ,FirstName
                              ,Job_Name__c
                              ,LastName
                              ,Profile.Name
                              ,UserRole.Name
                              From Users
                              Where IsActive=true)
                            from UserRole
                            Where ParentRoleId in :parentIds];
        return roles;
    } // getUserRolesByParentId
    
    /** Get the DSA of the Sales Rep - assume that the Profile.Name and UserRole.ParentRoleId fields have been selected
on the passed in user records.
*/
    public User getDSA(User checkUser) {
        User dsa = null;
        if (checkUser != null && checkUser.UserRole != null && Utilities.isSalesRep(checkUser.Profile.Name)) {
            // get the parent role - should be the district role
            try {
                dsa = [Select Id, Name
                       ,Profile.Name
                       ,UserRole.Id
                       ,UserRole.Name
                       From User
                       Where UserRoleId = :checkUser.UserRole.ParentRoleId
                       and Profile.Name in :Utilities.DSA_PROFS
                       and IsActive = true
                       order by LastLoginDate desc
                       limit 1];
            } catch (Exception e) {
                // do nothing on an exception
            }
        } // if (Utilities.isSalesRep
        return dsa;
    } // getDSA
    
    /** Check if the passed in user has a System Administrator profile.
*/
    public static Boolean isSystemAdmin(User u) {
        String profName=((u != null && u.Profile != null) ? u.Profile.Name : 'NoProf');
        return (profName.startsWith(Utilities.PROF_SYS_ADMIN));
    } // isSystemAdmin
    
    /** This is a list of Ids we are going to exclude from the DSA check.
This is because when a DSA is inactivated and we remove the DSA from the Users the trigger tries to add them back in. 
*/
    public static Set<Id> excludeDSAUserIdSet = new Set<Id>();
    
    // so we can skip the user triggers 
    public static Boolean SKIP_USER_TRIGGERS=false;
    
    public static void checkForDSA(User[] checkUsers) {
        System.debug('checkForDSA number of users='+checkUsers.size());
        // get the Profile records for the Sales Users - we only have the ID of the profile on the User record at this point.
        //Map<Id,Profile> repProfileMap = new Map<Id,Profile>([Select Id, Name from Profile where Name in :Utilities.REP_PROFS]);
        //Map<Id,User> usersToQueryMap = new Map<Id,User>();
        Map<String,List<User>> userListByRoleIdMap = new Map<String,List<User>>();
        for (User usr : checkUsers) {
            // clear out existing field for all users
            usr.DSA_FSS__c = null;
            if (usr.UserRoleId != null) {
                List<User> userList = userListByRoleIdMap.get(usr.UserRoleId);
                if (userList == null) {
                    userList = new List<User>();
                    userListByRoleIdMap.put(usr.UserRoleId,userList);
                }
                userList.add(usr);
            } // if (usr.UserRoleId
            
            //if (usr.ProfileId != null && repProfileMap.containsKey(usr.ProfileId)) {
            //   usersToQueryMap.put(usr.Id,usr);
            //}
        } // for (User usr : checkUsers
        
        System.debug('checkForDSA userListByRoleIdMap size='+userListByRoleIdMap.size());
        
        //if (usersToQueryMap.isEmpty()) {
        // return;
        //}
        
        Org_Unit__c[] orgUnits = OrgUnitMethods.getOrgUnitsByUserRole(userListByRoleIdMap.keySet());
        for (Org_Unit__c orgUnit : orgUnits) {
            if (orgUnit.RepUserRoleId__c != null && orgUnit.Assistant__c != null && orgUnit.Assistant__r.IsActive && !excludeDSAUserIdSet.contains(orgUnit.Assistant__c)) {
                List<User> userList = userListByRoleIdMap.get(orgUnit.RepUserRoleId__c);
                if (userList != null) {
                    for (User usr : userList) {
                        usr.DSA_FSS__c = orgUnit.Assistant__c;
                    }
                } // if (userList != null
            } // if (orgUnit.RepUserRoleId__c
        } // for (Org_Unit__c orgUnit
        
        
        System.debug('checkForDSA end of method');
    } // checkForDSA

    public static Profile getProfile(String profileName, Boolean logError) {
        Profile prof = null;
        try {
            prof = [Select Id, Name from Profile where Name=:profileName limit 1];
        } catch (Exception e) {
            // don't log an apex error from a trigger.
            if (logError && !Trigger.isExecuting) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The '+profileName+' could not be found! Cannot proceed!'));
            }
        } // try
        return prof;
    } // getProfile
    public static List<Profile> getProfiles(List<String> profileNameList, Boolean logError) {
        List<Profile> profileList = null;
        try {
            profileList = [Select Id, Name from Profile where Name in:profileNameList];
        } catch (Exception e) {
            // don't log an apex error from a trigger.
            if (logError && !Trigger.isExecuting) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The '+profileNameList+' could not be found! Cannot proceed!'));
            }
        } // try
        return profileList;
    } // getProfiles
    @future
    public static void checkOrgUnitsForInactive(Id[] userIds) {
        Set<Id> userIdSet = new Set<Id>();
        userIdSet.addAll(userIds);
        // delete any org unit user links
        try {
            delete [select Id from Org_Unit_User_Link__c where User__c in :userIds];
        } catch (Exception e) {
            // do nothing on an exception
            System.debug('checkOrgUnitsForInactive exception: '+e.getMessage()+'; '+e.getStackTraceString());
        }
        
        // remove them as the assistant or manager on an Org Unit
        Org_Unit__c[] orgUnits = [Select Id, Assistant__c, Manager__c, OverrideAssistant__c, OverrideMgr__c from Org_Unit__c
                                  Where Assistant__c in :userIds
                                  or Manager__c in :userIds];
        if (!orgUnits.isEmpty()) {
            // all org units should be modified as part of this check
            for (Org_Unit__c orgUnit : orgUnits) {
                if (userIdSet.contains(orgUnit.Assistant__c)) {
                    orgUnit.Assistant__c = null;
                    orgUnit.OverrideAssistant__c = false;
                }
                if (userIdSet.contains(orgUnit.Manager__c)) {
                    orgUnit.Manager__c = null;
                    orgUnit.OverrideMgr__c = false;
                }
            } // for (Org_Unit__c orgUnit
            
            Database.update(orgUnits,false);
        } // if (!orgUnits
    } // checkOrgUnitsForInactive
    
    public static String[] REP_ROLE_CHECKS = Label.JobRolesRep.split(';');
    /** Get the type of role the user has.
Role name examples:

HRS includes HRS and PAS

HRS VP
HRS SR DIR – EASTERN US
HRS ZONE 1
HRS DISTRICT 2
HRS SALES REP - DISTRICT 2

HNBF DIRECTOR
HNBF REGION 1
HNBF DISTRICT - BOSTON
HNBF SALES REP - BOSTON

Senior VP Sales
CORE AVP - CENTRAL
CORE ZONE 10
CORE DISTRICT - AUSTIN
Core Selling Manager - Austin
CORE SALES REP - AUSTIN  

MMS VP
MMS REGION MID-ATLANTIC
MMS DISTRICT BALTIMORE 430
MMS SALES REP BALTIMORE

If Zone:
<Sales Org> <Org Unit Name>
If District:
(HRS,PAS) HRS <District Name>
(HNBF) HNBF DISTRICT - <District Name>
(PAY) CORE DISTRICT - <District Name> 
(MMS) MMS DISTRICT <District Name> <District Number>
If Sales Office
(HRS,PAS) HRS SALES REP - <District Name>
(HNBF) HNBF SALES REP - <District Name>
(PAY) CORE SALES REP - <District Name> 
(MMS) MMS SALES REP <District Name>
*/
    public static String getRoleType(String roleName) {
        // get the type. If can't determine type, don't continue
        String roleType = null;
        if (roleName != null) {
            roleName = roleName.toUpperCase();
            for (String checkStr : REP_ROLE_CHECKS) {
                if (roleName.contains(checkStr)) {
                    return JOB_REP;
                }
            } // for (String checkStr
            //if (roleName.contains('SALES REP')) {
            //   roleType = JOB_REP;
            //} else 
            if (roleName.contains(UserHelper.ORG_DISTRICT.toUpperCase()) ||
                roleName.startsWith('MMS SELLING MGR') ||
                roleName.startsWith('CORE SELLING')) {
                    roleType = UserHelper.ORG_DISTRICT;
                } else if (roleName.contains(UserHelper.ORG_ZONE.toUpperCase()) ||
                           roleName.contains('REGION')) {
                               roleType = UserHelper.ORG_ZONE;                  
                           } else if (roleName.contains('CORE AVP') ||
                                      roleName.contains('HRS SR DIR')) {
                                          roleType = UserHelper.ORG_AREA;
                                      } else if (roleName.startsWith(Label.RoleNSSInboundRep) ||
                                                 roleName.startsWith(Label.RoleNSSOutboundRep)) {
                                                     roleType = JOB_NSR;
                                                 } else if (roleName.startsWith(Label.RoleNSSInboundSuper) ||
                                                            roleName.startsWith(Label.RoleNSSOutboundSuper)) {
                                                                roleType = JOB_NSS_SUPER;
                                                            }
        } // if (role != null)
        return roleType;
    } // getRoleType
    
    public static String JOB_REP='Sales Representative';
    public static String JOB_DSA='District Sales Assistant';
    public static String JOB_DSM='District Sales Manager';
    public static String JOB_ZSA='Zone Assistant';
    public static String JOB_ZSM='Zone Manager';
    public static String JOB_AREA='Area Assistant';
    public static String JOB_AVP='Area Vice President';
    public static String JOB_DIVISION='Division';
    
    public static String JOB_NSR=Label.JobNSR;
    public static String JOB_NSS_SUPER=Label.JobNSSSuper;
    
    public static Set<String> NSS_JOBS = new Set<String>{JOB_NSR,JOB_NSS_SUPER};
        
        /** This is used for testing reasons - can be changed if test! */
        public static Set<String> JOB_DIVISION_SET = new Set<String>();
    static {
        JOB_DIVISION_SET.addAll(DIVISION_LIST_SET);
        JOB_DIVISION_SET.add(SO_NSS);
    }
    
    /*
So,
Based on how people used to be setup, these are the rules:
For Sales Representative: Role must contain “SALES REP” or “CORE REP”
For District Sales Assistant: Role must be a District Role (contains “DISTRICT” or starts with “MMS SELLING MGR” or “CORE SELLING” and the Profile must be a DSA profile (based on the Profile List custom setting)
For District Sales Manager: Role must be a District Role (contains “DISTRICT” or starts with “MMS SELLING MGR” or “CORE SELLING”) and the Profile must be a DSM profile (based on the Profile List custom setting)
For Zone Assistant: Role must be a Zone Role (contains “ZONE” or starts with “REGION”) and the Profile must be a ZSA profile (based on the Profile List custom setting)
For Zone Manager: Role must be a Zone Role (contains “ZONE” or starts with “REGION”) and the Profile must be a ZSM profile (based on the Profile List custom setting)
For Area Assistant: Role must be an Area Role (contains “CORE AVP” or “HRS SR DIR”) 
*/
    
    
    //public static final Integer PROFILE_NAME_SIZE = Profile_List__c.Name.getDescribe().getLength();
    
    public static Boolean SKIP_LEGACY_CHECK=false;
    
    // Check the job name field on all user records.
    public static void checkForJobName(User[] triggerUsers) {
        // check for sales users to process further.
        User[] usersToProcess = new User[]{};
            // collect profile and role ids to select later
            Set<Id> profileIdSet = new Set<Id>(); 
        Set<Id> userRoleIdSet = new Set<Id>();
        
        for (User u : triggerUsers) {
            // always clear out the job name
            u.Job_Name__c = null;
            // just process all user records
            //if (u.Sales_Org__c != null && JOB_DIVISION_SET.contains(u.Sales_Org__c)) {
            usersToProcess.add(u);
            profileIdSet.add(u.ProfileId);
            if (u.UserRoleId != null) {
                userRoleIdSet.add(u.UserRoleId);
            }
            //}
        } // for (User u
        
        // if no users don't continue
        if (usersToProcess.isEmpty()) {
            return;
        }
        
        // select the profiles and roles
        Map<Id,Profile> profileMap = new Map<Id,Profile>([Select Id, Name from Profile where Id in :profileIdSet]);
        Map<Id,UserRole> userRoleMap = new Map<Id,UserRole>([Select Id, Name from UserRole where Id in :userRoleIdSet]);
        
        for (User u : usersToProcess) {
            UserRole ur = (u.UserRoleId != null ? userRoleMap.get(u.UserRoleId) : null);
            Profile prof = profileMap.get(u.ProfileId);
            u.ProfileName__c = (prof != null ? prof.Name : null);
            u.UserRoleName__c = (ur != null ? ur.Name : null);
            String roleType = (ur != null ? getRoleType(ur.Name) : null);
            if (!SKIP_LEGACY_CHECK && roleType != null) {
                if (roleType == JOB_REP) {
                    u.Job_Name__c=JOB_REP;
                } else if (NSS_JOBS.contains(roleType)) {
                    u.Job_Name__c=roleType;
                } else if (roleType == ORG_DISTRICT) {
                    if (prof != null) {
                        if (Utilities.isDsaProf(prof.Name)) {
                            u.Job_Name__c=JOB_DSA;
                        } else if (Utilities.isDsmProf(prof.Name)) {
                            u.Job_Name__c=JOB_DSM;
                        }
                    }
                } else if (roleType == ORG_ZONE) {
                    if (prof != null) {
                        if (Utilities.isZsaProf(prof.Name)) {
                            u.Job_Name__c=JOB_ZSA;
                        } else if (Utilities.isZsmProf(prof.Name)) {
                            u.Job_Name__c=JOB_ZSM;
                        }
                    }
                } else if (roleType == ORG_AREA) {
                    u.Job_Name__c = JOB_AREA;
                }
            }

            if (String.isBlank(u.Job_Name__c) && prof != null && ur != null) {
                JobMap__mdt[] jobMaps = [Select ProfileName__c, FilterType__c, RoleValue__c, JobName__c from JobMap__mdt where ProfileName__c=:prof.Name];
                for (JobMap__mdt jobMap : jobMaps) {
                    if (jobMap.FilterType__c == '=') {
                        if (ur.Name == jobMap.RoleValue__c) {
                            u.Job_Name__c = jobMap.JobName__c;
                            break;
                        }
                    } else if (jobMap.FilterType__c == 'contains') {
                        if (ur.Name.contains(jobMap.RoleValue__c)) {
                            u.Job_Name__c = jobMap.JobName__c;
                            break;
                        }
                    } else if (jobMap.FilterType__c == 'any') {
                        u.Job_Name__c = jobMap.JobName__c;
                        break;
                    }
                }
            } // if (String.isBlank(u.Job_Name__c
            System.debug('checkForJobName Id='+u.Id+' u='+u.LastName+' jobName='+u.Job_Name__c+' prof='+(prof != null ? prof.Name : 'No Prof')+' role='+(ur != null ? ur.Name : 'No Role'));
        } // for (User)
    } // checkForJobName
    
    private static User sfdcDataUser=null;
    
    public static User getSfdcData() {
        if (sfdcDataUser == null) {
            // TODO - not sure if we need to select all user fields here, but as a starting point...
            sfdcDataUser = [Select Id, Name from User where IsActive=true and Name=:SFDC_DATA limit 1];
        }
        return sfdcDataUser;
    } // getSfdcData
    
    public static final String SFDC_DATA = 'SFDC Data';
    public static final String RELATIONAL_JUNCTION = 'Relational Junction';
    public static final String LEAD_LOADER = 'Lead Loader';
    //public static final String MARKETO = 'Marketo API_User';    
    public static final String MARKETO = Label.Marketo_User;       // Corporate Marketing
    public static final String REFERRAL_OWNER='Referral_Owner';
    
    public static final String PREFIX_SFDC='SFDC-';
    public static final String PREFIX_RJ='RJ-';
    public static final String PREFIX_LL='LL-';
    public static final String PREFIX_ISDC='ISDC-';
    // amplifinity API user
    public static final String PREFIX_AMP='AMP-';
    // COE Automated User
    public static final String PREFIX_COE='COE-';
    
    public static User referralOwner = null;
    
    public static User getReferralOwner() {
        if (referralOwner == null) {
            String whereClause = ' where IsActive=true and Name = \''+REFERRAL_OWNER+'\' limit 1 ';
            User[] users = new UserHelper().getUsers(whereClause);
            if (!users.isEmpty()) {
                referralOwner = users[0];
            }
        } // if (referralOwner
        return referralOwner;
    } // getReferralOwner
    
    /** Is the name passed in used for the integration user? */
    public static Boolean isSfdcData(String checkName) {
        return hasActiveProcessName(PREFIX_SFDC+checkName);
    } // isSfdcData
    
    /** Is this the Relational Junction user? */
    public static boolean isRelationalJunction(String checkName) {
        return hasActiveProcessName(PREFIX_RJ+checkName);
    } // isRelationalJunction
    
    /** Is this the Lead Loader user? */
    public static boolean isLeadLoader(String checkName) {
        return hasActiveProcessName(PREFIX_LL+checkName);
    } // isLeadLoader
    
    public static boolean isIsdcApi(String checkName) {
        return hasActiveProcessName(PREFIX_ISDC+checkName);
    } // isIsdcApi
    
    public static boolean isAmpApi(String checkName) {
        return hasActiveProcessName(PREFIX_AMP+checkName);
    } // isIsdcApi
    
    public static boolean isCoe(String checkName) {
        return hasActiveProcessName(PREFIX_COE+checkName);
    } // isIsdcApi
    
    public static Boolean runningUserIsSfdcData = false;
    public static Boolean runningUserIsRelationalJunction = false;
    public static Boolean runningUserIsLeadLoader = false;
    public static Boolean runningUserIsIsdcApi = false;
    public static Boolean runningUserIsAmplifinity = false;
    public static Boolean runningUserIsCoe = false;
    
    public static Id currentRunningUserId = null;
    
    public static void setRunningUserAttributes() {
        if (currentRunningUserId == null || currentRunningUserId != UserInfo.getUserId()) {
            currentRunningUserId = UserInfo.getUserId();
            String runningUserName = UserInfo.getName();
            runningUserIsSfdcData = isSfdcData(runningUserName);
            runningUserIsRelationalJunction = isRelationalJunction(runningUserName);
            runningUserIsLeadLoader = isLeadLoader(runningUserName);
            runningUserIsIsdcApi = isIsdcApi(runningUserName);
            runningUserIsAmplifinity = isAmpApi(runningUserName);
            runningUserIsCoe = isCoe(runningUserName);
            System.debug('setRunningUserAttributes runningUserIsSfdcData='+runningUserIsSfdcData+' runningUserIsRelationalJunction='+runningUserIsRelationalJunction+' runningUserIsLeadLoader='+runningUserIsLeadLoader+' runningUserIsAmplifinity='+runningUserIsAmplifinity);
        }
    } // setRunningUserAttributes
    
    public static final String TYPE_USER='sfUser';
    public static final String TYPE_SFDC_DATA='sfdcData';
    public static final String TYPE_REL_JUNC='relJunc';
    public static final String TYPE_LEAD_LOAD='leadLoad';
    public static final String TYPE_ISDC='ISDCApi';
    
    // get the type of the running user
    public static String getRunningUserType() {
        String userType = TYPE_USER;
        setRunningUserAttributes();
        if (runningUserIsSfdcData) {
            userType=TYPE_SFDC_DATA;
        } else if (runningUserIsRelationalJunction) {
            userType=TYPE_REL_JUNC;
        } else if (runningUserIsLeadLoader) {
            userType=TYPE_LEAD_LOAD;
        } else if (runningUserIsIsdcApi) {
            userType=TYPE_ISDC;
        }
        return userType;
    } // getUserType
    
    public static Boolean hasActiveProcessName(String p_valueToCheck) {
        ProcessNameMap__c pnm = null;
        if (String.isNotBlank(p_valueToCheck)) {
            String valueToCheck = RecordTypeHelper.cleanRtName(p_valueToCheck);
            pnm = ProcessNameMap__c.getInstance(valueToCheck);
        }
        return (pnm != null && pnm.IsActive__c);
    } // hasActiveProcessName
    
    /** Profile name for the NSS Manager. */
    public static String PROF_NSS_MGR='NSS Manager';
    public static String PROF_NSS_MGR_ADMIN='NSS Manager Admin';
    public static Set<String> NSS_MGR_PROF_SET = new Set<String>{PROF_NSS_MGR,PROF_NSS_MGR_ADMIN};
        // The profile name for the NSS Inbound Reps. 
        public static String PROF_NSS_INBOUND='NSS Inbound Rep';
    // The profile name for the NSS Outbound Reps. 
    public static String PROF_NSS_OUTBOUND='NSS Outbound Rep';
    
    public static Set<String> profsNSSOutboundSet=null;
    public static Set<String> profsNSSInboundSet=null;
    
    // Is the passed in profile name for an NSS Inbound Rep? 
    public static Boolean isNSSInboundProf(String profName) {
        if (profsNSSInboundSet == null) {
            profsNSSInboundSet =  new Set<String>();
            profsNSSInboundSet.add(PROF_NSS_INBOUND);
            profsNSSInboundSet.addAll(Label.ProfilesNSSinbound.split(','));
        }
        return (String.isNotBlank(profName) && profsNSSInboundSet.contains(profName));
    } // isNSSInboundProf
    
    // Is the passed in profile name for an NSS Outbound Rep? 
    public static Boolean isNSSOutboundProf(String profName) {
        if (profsNSSOutboundSet == null) {
            profsNSSOutboundSet = new Set<String>();
            profsNSSOutboundSet.add(PROF_NSS_INBOUND);
            profsNSSOutboundSet.addAll(Label.ProfilesNSSoutbound.split(','));
        }
        return (String.isNotBlank(profName) && profsNSSOutboundSet.contains(profName));
    } // isNSSOutboundProf
    
    // Does the passed in user have an NSS profile? 
    public static Boolean isNSSProfile(String profName) {
        return (String.isNotBlank(profName) && profName.startsWith('NSS'));
    } // isNSSProfile
    
    public static Boolean isOasis(User usr) {
        Boolean oasis = false;
        if (usr != null && usr.Profile != null) {
            Profile_List__c pl = Profile_List__c.getInstance(RecordTypeHelper.cleanRtName(usr.Profile.Name));
            oasis = (pl != null && pl.Sales_Org__c == 'Oasis');
        }
        if (!oasis && usr != null && String.isNotBlank(usr.NSS_Team__c)) {
            NSSTeamMap__c ntm = NSSTeamMap__c.getInstance(RecordTypeHelper.cleanRtName(usr.NSS_Team__c));
            oasis = (ntm != null && ntm.Sales_Org__c == 'Oasis');
        }
        return oasis;
    } // isOasis
    
    private static User runningUser = null;
    
    // only allow the put operation to occur in a trigger.
    public static Boolean CACHE_IN_USE = Utilities.CACHE_IN_USE;
    public static Boolean SKIP_CACHE = Utilities.SKIP_CACHE;
    
    public static Boolean USE_CACHE_FOR_USER=(Label.UserHelper_CacheRunningUser == 'Y');
    
    // So we only retrieve it once per session. 
    public static User getRunningUser() {
        // add a check for the Id in case running tests and switch users.
        if (runningUser == null || (runningUser != null && runningUser.Id != UserInfo.getUserId())) {
            // try retrieving from the session cache
            runningUser = (USE_CACHE_FOR_USER ? (User)CacheManager.getSession(UserInfo.getUserId()) : null);
            if (runningUser == null) {
                UserHelper uh = new UserHelper();
                runningUser = uh.getUserById(UserInfo.getUserId());
                System.debug('getRunningUser runningUser='+runningUser);
                if (USE_CACHE_FOR_USER && runningUser != null) {
                    CacheManager.putSession(UserInfo.getUserId(), runningUser);
                }
            }
        } // if (runningUser == null
        return runningUser;
    } // getRunningUser
    
    // is the running user a guest user?
    public static Boolean isRunningUserGuest() {
        User runUser = getRunningUser();
        String runningUserName = UserInfo.getName();
        
        return ((String.isNotBlank(runningUserName) && runningUserName.contains('Guest User'))
                || (runUser != null && runUser.UserType=='Guest'));
    } // isRunningUserGuest
    
    public static Boolean isRunningUserSystemAdmin() {
        User runUser = getRunningUser();
        return (runUser != null && runUser.Profile != null && runUser.Profile.Name == Utilities.PROF_SYS_ADMIN);
    } // isRunningUserSystemAdmin
    
    // does the running user have any profile that starts with System Admin?
    public static Boolean isRunningUserAnySystemAdmin() {
        User runUser = getRunningUser();
        return (runUser != null && runUser.Profile != null && runUser.Profile.Name.StartsWith(Utilities.PROF_SYS_ADMIN));
    } // isRunningUserAnySystemAdmin
    
    
    public static String addToRestBody(String key, String value) {
        String output = '"'+key+'":'+(String.isBlank(value) ? '' : JSON.serialize(value));
        return output;
    } // addToRestBody
    
    public static String addToRestBody(String key, Date value) {
        String output = '"'+key+'":'+(value == null ? '' : JSON.serialize(value));
        return output;
    } // addToRestBody
    
    public static String addToRestBody(String key, DateTime value) {
        String output = '"'+key+'":'+(value == null ? '' : JSON.serialize(value));
        return output;
    } // addToRestBody
    
    public static String addToRestBody(String key, Boolean value) {
        String output = '"'+key+'":'+(value == null ? '' : JSON.serialize(value));
        return output;
    } // addToRestBody
    
    public static Boolean ALLOW_ROLE_CALLOUT=true;
    
    @future(callout=true)
    public static void handleUserRoleChanged(String sessionId, Id[] userIds) {
        HttpRequest req = new HttpRequest();
        Boolean okay = true;
        req.setEndpoint('https://'+URL.getOrgDomainUrl().getHost()+'/services/apexrest/UserRoleUpdate/');
        req.setMethod('POST');
        String body = '{"userIds":'+JSON.serialize(userIds)+'}';
        req.setBody(body);
        req.setHeader('Authorization', 'Bearer '+ sessionId);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(50000);
        Http http = new Http();
        if (!test.isRunningTest()){
            System.debug('handleUserRoleChanged performing rest callout');
            try {
                HTTPResponse res = http.send(req);
                System.debug('handleUserRoleChanged res='+res+' body='+res.getBody());
                
                //XmlStreamReader reader = res.getXmlStreamReader();
                //while(reader.hasNext()) {
                //   System.debug('Event Type:' + reader.getEventType());
                //   if (reader.getEventType() == XmlTag.START_ELEMENT) {
                //      System.debug(reader.getLocalName());
                //   }
                //   reader.next();
                //}
            } catch (Exception ex) {
                okay = false;
                ErrorLog.logError('UserHelper', 'handleUserRoleChanged', 'Sending message', userIds[0], ex);
            }
        } else {
            System.debug('handleUserRoleChanged calling roleChanged directly');
            //UserRoleUpdateREST.doPost(userIds);
        }
        
        if (okay) {
            // update the users to update the DSA
            User[] updateUsers = new User[]{};
                for (Id userId : userIds) {
                    User usr = new User(Id=userId);
                    updateUsers.add(usr);
                } // for (Id userId
            
            try {
                update updateUsers;
            } catch (Exception ex) {
                ErrorLog.logError('UserHelper', 'handleUserRoleChanged', 'updating users', userIds[0], ex);
            }
        } // if (okay
        
        ErrorLog.checkSave();
        
    } // handleUserRoleChanged
    
    public static String getTeamRole(String p_salesOrg, String p_segmentName) {
        String roleName = null;
        if (String.isNotBlank(p_salesOrg)) {
            String key = p_salesOrg+(String.isNotBlank(p_segmentName) ? '-'+p_segmentName : '');
            SalesOrg__c salesOrg = SalesOrg__c.getInstance(key);
            if (salesOrg == null && String.isNotBlank(p_segmentName)) {
                salesOrg = SalesOrg__c.getInstance(p_salesOrg);
            }
            if (salesOrg != null) {
                roleName = salesOrg.TeamRole__c;
            }
        } // if (String.isNotBlank
        return roleName;
    } // getTeamRole
    
    // the user record returned from the isUserVisible method.
    public static User isVisibleCheckUser = null;
    
    // for the checkUserId passed in, is that user visible to the runningUser's hierarchy?
    public static Boolean isUserVisible(User userToCheckAgainst, Id checkUserId, Boolean activeOnly) {
        Boolean okayToUse = areUsersVisible(userToCheckAgainst, new Id[]{checkUserId});
        if (okayToUse) {
            isVisibleCheckUser = usersVisible[0];
        }
        return okayToUse;
    } // isUserVisible
    
    public static User[] usersVisible = null;
    public static Set<Id> userIdVisibleSet = null;
    
    public static User[] usersNotVisible = null;
    public static Set<Id> userIdNotVisibleSet = null;
    
    // initialize the static variables for the visible method
    private static void setupVisibleVariables() {
        usersVisible = new User[]{};
            userIdVisibleSet = new Set<Id>();
        usersNotVisible = new User[]{};
            userIdNotVisibleSet = new Set<Id>();
    } // setupVisibleVariables
    
    public static Boolean areUsersVisible(User userToCheckAgainst, Id[] checkUserIds) {
        setupVisibleVariables();
        Boolean okay = true;
        User[] checkUsers = null;
        if (checkUserIds != null && !checkUserIds.isEmpty()) {
            checkUsers = [Select Id, Name, HR_Person_Id__c, Sales_Org__c, Profile.Name, UserRoleId, UserRole.ParentRoleId, Title from User where Id in :checkUserIds];
        }
        
        if (checkUsers != null && !checkUsers.isEmpty()) {
            Boolean isSysAdmin = isSystemAdmin(userToCheckAgainst);
            // if sys admin can see everyone
            if (isSysAdmin) {
                usersVisible.addAll(checkUsers);
                userIdVisibleSet.addAll(checkUserIds);
            } else {
                Set<Id> roleIds = getVisibleRoleIds(userToCheckAgainst);
                for (User checkUser : checkUsers) {
                    if (roleIds.contains(checkUser.UserRoleId)) {
                        usersVisible.add(checkUser);
                        userIdVisibleSet.add(checkUser.Id);
                    } else {
                        usersNotVisible.add(checkUser);
                        userIdNotVisibleSet.add(checkUser.Id);
                    }
                } // for (User checkUser
            } // if (isSysAdmin
        } // if (checkUsers != null &&
        
        return !usersVisible.isEmpty();
    } // areUsersVisible
    
    public static Map<Id,Set<Id>> visibleRoleIdByUserIdMap = new Map<Id,Set<Id>>(); 
    
    public static Set<Id> getVisibleRoleIds(User userToCheckAgainst) {
        Set<Id> roleIdSet = visibleRoleIdByUserIdMap.get(userToCheckAgainst.Id);
        if (roleIdSet == null) {
            roleIdSet = new Set<Id>{userToCheckAgainst.UserRoleId};
                // see if the running user has the override field filled out - might have more role ids.
                if (String.isNotBlank(userToCheckAgainst.ManageZipOrgUnitsManaged__c)) {
                    String[] orgUnitQueryKeys = new String[]{};
                        orgUnitQueryKeys.addAll(userToCheckAgainst.ManageZipOrgUnitsManaged__c.split(','));
                    
                    System.debug('getVisibleRoleIds orgUnitQueryKeys='+orgUnitQueryKeys);
                    Org_Unit__c[] orgUnits = OrgUnitMethods.getOrgUnits(null, null, null, null, orgUnitQueryKeys);
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'isUserVisible nbr orgUnits='+orgUnits.size()));
                    
                    for (Org_Unit__c orgUnit : orgUnits) {
                        if (orgUnit.UserRoleId__c != null) {
                            roleIdSet.add(orgUnit.UserRoleId__c);
                        }
                    }
                } // if (String.isNotBlank
            // get the child role ids
            roleIdSet = new UserHelper().getAllSubRoleIds(roleIdSet);
            roleIdSet.add(userToCheckAgainst.UserRoleId);
            
            visibleRoleIdByUserIdMap.put(userToCheckAgainst.Id, roleIdSet);
        } // if (roleIdSet == null
        return roleIdSet;
    } // getVisibleRoleIds
    
    // is this a guest user?
    public static Boolean isGuestUser(User checkUser) {
        return (checkUser != null && checkUser.UserType=='Guest');
    } // isGuestUser
    
} // UserHelper