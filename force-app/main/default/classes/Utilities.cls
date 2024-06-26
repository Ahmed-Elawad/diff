/* 
 * General utilities for use by other classes.
 *
 * History
 * -------
 * 10/06/2009 Dan Carmen       Created
 * 07/12/2010 Dan Carmen       Added removeExtraChars method
   11/08/2011 Dan Carmen       Changed to not use the AAConfig__c object.
   12/28/2011 Dan Carmen       Added isSalesRep method.
   05/24/2012 Dan Carmen       Added variable for DSA profiles/Sales Rep profiles
   07/13/2012 Dan Carmen       Added variable for DSM profiles.
   11/26/2012 Dan Carmen       Added (temporarily) MMS Sales-SalesPrism profile as a rep profile
   03/23/2013 Dan Carmen       Added checks for more profiles
   05/22/2013 Dan Carmen       Updated zip code check to only allow numbers
   06/13/2013 Frank Lurz       Added NSS Core/HRS profile and modified checkDsaZsaProfName
   08/16/2013 Justin Stouffer   Added MSP Profile Information
   02/25/2014 Cindy Freeman   Added method to read custom setting Trigger Flags to decide if user can run a trigger
   04/10/2014 Cindy Freeman   modified runTrigger method to be able to stop a trigger for all users
   01/06/2015 Dan Carmen       Added checkDialedTimeOkay
   02/02/2014 Justin Stouffer   Added Clone method.
   10/14/2015 Carrie Marciano   Added Steelbrick profiles
   10/29/2015 Dan Carmen       Added checkDupeBlocker method
   06/18/2016 Dan Carmen       Fix for checking to use the cache.
   03/08/2017 Cindy Freeman     added new PEO Steelbrick profile
   03/13/2017 Jacob Hinds       added new HRS Steelbrick profile
   04/04/2017 Jacob Hinds      Adding Core DSM Steelbrick
   05/04/2017 Carrie Marciano  Removed deleted profiles from code
   06/05/2017 Dan Carmen         Change to isTestSiloed
   07/18/2017 Jacob Hinds    Adding additional Core SB profiles
   08/11/2017 Josh cartwright changed instance URL to reference a custom label
   09/08/2017 Jacob Hinds     Adding Virtual Sales Profile
   11/28/2017 Jacob Hinds    Adding PEO Centric
   12/04/2017 Dan Carmen      Modifications to cleanUrl to handle myDomain
   02/11/2019 Dan Carmen      Cache the checkForProduction value
   10/15/2019 Dan Carmen      More logging for sleep method
   10/16/2020 Dan Carmen      Added allowFuture method
   10/19/2020 Brandon Vidro   Added 4 profiles
   04/03/2022 Pujitha Madamanchi Added APLHA_NUMERIC tag parse
   09/26/2023 Dan Carmen      Comment out logic for checkDupeBlocker
   03/17/2024 Dan Carmen      Removed rcdsAffectedSet,runTrigger logic

 */
public without sharing class Utilities {

   public static String instanceURL() {
      if (label.SalesforceURL == 'Use cleanUrl') {
         return cleanUrl(URL.getOrgDomainUrl().toExternalForm(),'');
      }
      return label.SalesforceURL;
   }
   
   public static String getInstanceURL() {
      return URL.getOrgDomainUrl().toExternalForm();
   }
    
   public static Boolean OVERRIDE_PRODUCTION = null;
   
   public static String cleanUrl(String url, String nameSpace) {
      System.debug('cleanUrl url='+url);
      // if mydomain is in a VF context
      if (url.contains('--c')) {
         url = url.replace('--c','');

         Boolean isProduction = ((OVERRIDE_PRODUCTION != null && OVERRIDE_PRODUCTION) || (OVERRIDE_PRODUCTION==null && String.isBlank(Utilities.checkForProduction())));
         System.debug('cleanUrl isProduction='+isProduction);
         // if production, remove the instance name from the string
         if (isProduction) {
            // remove text between the first and second periods
            Integer firstIndex = url.indexOf('.');
            System.debug('cleanUrl firstIndex='+firstIndex);
            if (firstIndex > -1) {
               Integer secondIndex = url.indexOf('.',firstIndex+1);
               System.debug('cleanUrl secondIndex='+secondIndex);
               if (secondIndex > firstIndex) {
                  url = url.subString(0,firstIndex)+url.subString(secondIndex);
                  System.debug('cleanUrl firstIndex='+firstIndex+' secondIndex='+secondIndex+' url='+url);
               }
            }
         }
         url = url.replace('visual.force.com','my.salesforce.com');
      } else {
      
         url = url.replace('-api.','.');     // context: executeAnon, standard SOAP API
         if (url.contains('visual.force')) {  // context: packaged code
            url = url.replace('://' + nameSpace + '.', '://').replace('visual.force','salesforce');
            url = url.replace('://c.','://');
         }
      }
      // handle older pod naming inconsistency:
      //url = url.replace('://eu0.','://emea.');
      //url = url.replace('://na0.','://ssl.');
      //url = url.replace('://ap0.','://ap.');
      //url = url.replace('://cs0.','://tapp0.');
      return url;
   } // cleanUrl
   

   public static Date getNextBusinessDay(Integer numDays) {
      Datetime activityDate = System.now();
      return(getNextBusinessDay(activityDate,numDays));
   } // getNextBusinessDay
   
   /** Get the next business day that is at least numDays in the future.
    *  If the date falls on a weekend, get the next Monday.
    */
   public static Date getNextBusinessDay(Datetime currentDay, Integer numDays) {
    /*
      datetime date1 = (System.now()+numDays);
     */
      currentDay = currentDay.addDays(numDays);
      date activityDate = Date.newInstance(currentDay.year(),currentDay.month(),currentDay.day());

      String day = currentDay.format('EEE');
      if (day == 'Sat') {
         return activityDate.addDays(2);
      } else if (day == 'Sun') {
         return activityDate.addDays(1);
      }
      return activityDate;
   } // getNextBusinessDay
   
   /** The profile name for the System Administrator. */
   public static final String PROF_SYS_ADMIN='System Administrator';
   
   /** The profile name for Core Sales. */
   public static final String PROF_CORE_SALES='Core Sales';
   /** The profile name for Core Sales. */
   public static final String PROF_CORE_SALES_SB='Core Sales - SB';
   public static final String[] CORE_PROFS = new String[]{PROF_CORE_SALES,PROF_CORE_SALES_SB};
   
   /** The profile name for Core Sales Trainer. */
   public static final String PROF_CORE_SALES_TRAIN='Core Sales Trainer';
   /** The profile name for Core Virtual Sales. */
   public static final String PROF_CORE_VIRTUAL_SALES='Core Virtual Sales Rep';
   /** The profile name for MMS Sales. */
   public static final String PROF_MMS_SALES='MMS Sales';
   /** The profile name for MMS Sales Steelbrick. */
   public static final String PROF_MMS_SALES_SB='MMS Sales - SB';
   /** The profile name for MMS Sales Trainer. */
   public static final String PROF_MMS_SALES_TRAIN='MMS Sales Quote';
   /** The profile name for MMS Selling Manager Quote. */
   public static final String PROF_MMS_SELL_MGR_QUOTE='MMS Selling Manager Quote';
   /** The profile name for MMS Selling Manager. */
   public static final String PROF_MMS_SELL_MGR='MMS Selling Manager';
   /** The profile name for MMS Selling Manager Steelbrick. */
   public static final String PROF_MMS_SELL_MGR_SB='MMS Selling Manager - SB';
   /** The profile name for Core Selling Manager. */ 
   public static final String PROF_CORE_SELL_MGR='Core Selling Manager';
   /** The profile name for Core Selling Manager. */ 
   public static final String PROF_CORE_SELL_MGR_SB='Core Selling Manager - SB';
   /** The profile name for the Core Manager. */
   public static final String PROF_CORE_MGR='Core Manager';
   /** The profile name for the Core Manager. */
   public static final String PROF_CORE_MGR_SB='Core Manager - SB';
   /** The profile name for the MMS Manager. */
   public static final String PROF_MMS_MGR='MMS Manager';
   /** The profile name for the MMS Manager Steelbrick. */
   public static final String PROF_MMS_MGR_SB='MMS Manager - SB'; 
   /** The profile name for the MMS Manager Quote. */
   public static final String PROF_MMS_MGR_QUOTE='MMS Manager Quote';
   /** The profile name for the HRS 401(k) Sales. */
   public static final String PROF_HRS_401K='HRS 401(k) Sales - SB'; 
   /** The profile name for the HRS PEO-ASO Sales. */
   public static final String PROF_HRS_PEO_ASO='HRS PEO-ASO Sales';
   /** The profile name for the HRS PEO-ASO Sales Steelbrick. */
   public static final String PROF_HRS_PEO_ASO_SB='HRS PEO-ASO Sales - SB';   
   /** The profile name for the HRS PEO Reps. */
   public static final String PROF_HRS_PEO_CENTRIC='HRS PEO Centric Sales - SB';
   /** The profile name for the HNB Sales Rep. */
   public static final String PROF_HNBF_SALES_REP='HNBF Sales Rep'; 
   /** The profile name for the MSP Sales Rep. */                 // Updated For myStaffingPro
   public static final String PROF_MSP_REP='MSP Rep';

   public static String PROFILE_NAME_QUERY = null;

   // only allow the put operation to occur in a trigger.
   public static Boolean CACHE_IN_USE = Label.Cache_In_Use=='Y'; // Trigger.isExecuting && (Label.Cache_In_Use=='Y');
   // we skip using the cache if we're running in a siloed test.
   public static Boolean SKIP_CACHE = (Label.Cache_In_Use != 'Y' || (Test.isRunningTest() && !Utilities.isTestSiloed()));

/*
   public static Set<String> getMetadataProfileNames(String queryKey, String whereClause) {
      String cacheKey='getMetadataProfileNames'+queryKey;
      Set<String> profileNames = (!SKIP_CACHE ? (Set<String>)Cache.Org.get(cacheKey) : null);
      System.debug('getMetadataProfileNames checkCache profileNames='+profileNames);
      if (profileNames == null) {
         profileNames = new Set<String>();
         if (PROFILE_NAME_QUERY == null && String.isNotBlank(whereClause)) {
            PROFILE_NAME_QUERY = Objecthelper.getSOQLQuery('UserProfile__mdt',null,true,true);
            System.debug('getMetadataProfileNames PROFILE_NAME_QUERY='+PROFILE_NAME_QUERY);
            if (PROFILE_NAME_QUERY != null) {
               PROFILE_NAME_QUERY += ' where IsActive__c=true ';
            }
         } // if (PROFILE_NAME_QUERY
         if (PROFILE_NAME_QUERY != null && String.isNotBlank(whereClause)) {
            String query = PROFILE_NAME_QUERY + ' and '+whereClause;
            for (UserProfile__mdt userProf : Database.query(query)) {
               profileNames.add(userProf.ProfileName__c);
            }
         } // if (PROFILE_NAME_QUERY != null
         if (!SKIP_CACHE && CACHE_IN_USE && !profileNames.isEmpty()) {
            Cache.Org.put(cacheKey,profileNames);
         }
      } // if (profileNames == null
      System.debug('getMetadataProfileNames profileNames='+profileNames);
      return profileNames;
   } // getMetadataProfileNames
*/
   /** All of the profiles that are for Sales Reps.
    */
   public static final Set<String> REP_PROFS = new Set<String>{ 
           PROF_CORE_SALES
          ,PROF_CORE_SALES_SB
          ,PROF_CORE_VIRTUAL_SALES
          ,PROF_MMS_SALES
          ,PROF_MMS_SALES_SB     
          ,'MMS Sales-SalesPrism' // temporary!!
          ,PROF_HRS_401K
          ,PROF_HRS_PEO_ASO
          ,PROF_HRS_PEO_CENTRIC
          ,PROF_HNBF_SALES_REP
          ,PROF_MSP_REP};

   public static final Integer PROFILE_NAME_SIZE = Profile_List__c.Name.getDescribe().getLength();

   // check if the profile is 1) in the custom setting and 2) has the attribute set.
   public static Boolean doesProfileNameMatch(String profName, String fieldToCheck, Set<String> defaultSet) {
      Boolean matches = false;
      //System.debug('doesProfileNameMatch profName='+profName+' fieldToCheck='+fieldToCheck+' defaultSet='+(defaultSet != null ? String.valueOf(defaultSet.size()) : 'null'));
      // as long as there are values in the custom setting we'll use it.
      if (String.isNotBlank(profName)) {
         if (Profile_List__c.getAll().values().size() > 5) {
            //System.debug('doesProfileNameMatch Profile_List__c values found size='+Profile_List__c.getAll().values().size());
            // make sure the profile name isn't too large
            Profile_List__c prof = Profile_List__c.getInstance(profName.left(PROFILE_NAME_SIZE));
            if (prof != null) {
               matches = (Boolean)prof.get(fieldToCheck);
               System.debug('doesProfileNameMatch Profile_List__c value found matches='+matches+' prof='+prof);
            }
         } else if (defaultSet != null) {
            System.debug('doesProfileNameMatch Profile_List__c values not found using defaultSet');
            // this is so we don't break tests - eventually we will remove this.
            matches = defaultSet.contains(profName);
         }
      } // if (String.isNotBlank(profName
      return matches;
   } // doesProfileNameMatch

/*
   public static Boolean doesProfileNameMatch(String profName, String queryName, String whereClause, Set<String> defaultSet) {
      Boolean profileNameMatches = false;
      if (String.isNotBlank(profName)) {
         Set<String> profileSet = getMetadataProfileNames(queryName,whereClause);
         if (profileSet == null || profileSet.isEmpty()) {
            // this is just in case
            profileSet = defaultSet;
         }
         profileNameMatches = (profileSet.contains(profName));
      } // if (String.isNotBlank(profName
      return profileNameMatches;
   } // doesProfileNameMatch
*/

   public static Boolean isSalesRep(String profName) {
      //return doesProfileNameMatch(profName,'repProfs','SalesRep__c=true',REP_PROFS);
      return doesProfileNameMatch(profName,'SalesRep__c',REP_PROFS);
   } // isSalesRep
   
   public static final Set<String> OTHER_SALES_PROFS = new Set<String>{
           PROF_CORE_SALES_TRAIN
          ,PROF_MMS_SALES_TRAIN
          ,PROF_MMS_SELL_MGR_QUOTE
          ,PROF_MMS_SELL_MGR
          ,PROF_MMS_SELL_MGR_SB
          ,PROF_CORE_MGR
          ,PROF_CORE_MGR_SB
          ,PROF_MMS_MGR
          ,PROF_MMS_MGR_SB
          ,PROF_MMS_MGR_QUOTE
          ,PROF_CORE_SELL_MGR
          ,PROF_CORE_SELL_MGR_SB
        };
   
   /** Does the passed in profile have the same name as a Sales Profile.
    */
   public static Boolean isSalesProf(String profName) {
      Set<String> allSalesSet = new Set<String>();
      allSalesSet.addAll(REP_PROFS);
      allSalesSet.addAll(OTHER_SALES_PROFS);
      return doesProfileNameMatch(profName,'IsFieldSales__c',allSalesSet);
/*
      Boolean isSalesProf = false;
      if (String.isNotBlank(profName)) {
         
         Set<String> salesProfSet = getMetadataProfileNames('salesProfs','IsFieldSales__c=true');
         if (salesProfSet != null && !salesProfSet.isEmpty()) {
            isSalesProf = salesProfSet.contains(profName);
         } else {
            // leaving this in just in case
            isSalesProf = (isSalesRep(profName) ||
                (profName != null && OTHER_SALES_PROFS.contains(profName)));
         }
      } // if (String.isNotBlank
      return isSalesProf;
 */
   } // isSalesProf
   
   /** The profile name for Core Zone Administration. */
   public static final String PROF_CORE_ZONE_ADMIN = 'Core Zone Administration';
   /** The profile name for Core Zone Administration. */
   public static final String PROF_CORE_ZONE_ADMIN_SB = 'Core Zone Administration - SB';
   /** The profile name for Core Sales Administration. */
   public static final String PROF_CORE_SALES_ADMIN = 'Core Sales Administration';
   /** The profile name for Core Sales Administration. */
   public static final String PROF_CORE_SALES_ADMIN_SB = 'Core Sales Administration - SB';
   /** The profile name for MMS Sales DSA. */
   public static final String PROF_MMS_SALES_DSA = 'MMS Sales DSA';
   /** The profile name for MMS Sales DSA Steelbrick. */
   public static final String PROF_MMS_SALES_DSA_SB = 'MMS Sales DSA - SB';
   /** The profile name for MMS Sales DSA Quote. */
   public static final String PROF_MMS_SALES_DSA_QUOTE = 'MMS Sales DSA Quote';
   /** The profile name for MMS Sales ZSA. */
   public static final String PROF_MMS_SALES_ZSA = 'MMS Sales ZSA';
   /** The profile name for MMS Sales ZSA Steelbrick. */
   public static final String PROF_MMS_SALES_ZSA_SB = 'MMS Sales ZSA - SB';
   /** The profile name for MMS Sales ZSA Quote. */
   public static final String PROF_MMS_SALES_ZSA_QUOTE = 'MMS Sales ZSA Quote';
   public static final String PROF_HRS_REGIONAL_SALES='HRS Regional Sales Admin';
   public static final String PROF_HRS_REGIONAL_SALES_SB='HRS Regional Sales Admin - SB';
   public static final String PROF_HRS_SALES_ADMIN='HRS Sales Administration - SB';
   public static final String PROF_HRS_SALES_MANAGER='HRS Sales Manager';
   public static final String PROF_HRS_SALES_MANAGER_ADMIN='HRS Sales Manager Admin - SB';
   public static final String PROF_HNBF_SALES_ADMIN='HNBF Sales Administration';
   public static final String PROF_HNBF_SALES_MGR='HNBF Sales Manager';
   public static final String PROF_MSP_MGR='MSP Manager';               // Updated For myStaffingPro
   public static final String PROF_PC_SALES_MANAGER='PC Sales Manager - SB';
   public static final String PROF_PC_SALES_REP='PC Sales Rep - SB';
   public static final String PROF_PC_SALES_ADMINISTRATION_SB='PC Sales Administration - SB';
   /** The profile name for NSS Core/HRS. */
    
    
   public static final String PROF_CORE_SENIOR_MGR='Core Senior Manager';
   public static final String PROF_CORE_SENIOR_MGR_SB='Core Senior Manager - SB';
   public static final String PROF_MMS_SENIOR_MGR='MMS Senior Manager';
   public static final String PROF_MMS_SENIOR_MGR_SB='MMS Senior Manager - SB';
   
   /** All of the profiles that are of type DSA. */
   public static final Set<String> DSA_PROFS = new Set<String>{ 
           PROF_CORE_SALES_ADMIN
          ,PROF_CORE_SALES_ADMIN_SB
          ,PROF_HNBF_SALES_ADMIN
          ,PROF_HRS_SALES_ADMIN
          ,PROF_MMS_SALES_DSA
          ,PROF_MMS_SALES_DSA_SB     
          ,PROF_MMS_SALES_DSA_QUOTE};

   /** All of the DSM profiles. */
   public static final Set<String> DSM_PROFS = new Set<String>{
           PROF_CORE_MGR
          ,PROF_CORE_MGR_SB
          ,PROF_CORE_SELL_MGR
          ,PROF_CORE_SELL_MGR_SB
          ,PROF_HNBF_SALES_MGR
          ,PROF_HRS_SALES_MANAGER
          ,PROF_MMS_MGR
          ,PROF_MMS_MGR_SB
          ,PROF_MMS_SELL_MGR
          ,PROF_MMS_SELL_MGR_SB     
          ,PROF_MSP_MGR                            // Updated For myStaffingPro
           }; 
   
   public static final Set<String> ZSA_PROFS = new Set<String>(Label.Profiles_ZSA.split(','));
           /*
           PROF_CORE_ZONE_ADMIN
          ,PROF_CORE_ZONE_ADMIN_SB
          ,PROF_MMS_SALES_ZSA
          ,PROF_MMS_SALES_ZSA_SB   
          ,PROF_MMS_SALES_ZSA_QUOTE
          ,PROF_HRS_REGIONAL_SALES
          ,PROF_HRS_REGIONAL_SALES_SB
          ,PROF_HRS_SALES_ADMIN
          ,PROF_HRS_SALES_MANAGER_ADMIN
          ,PROF_HNBF_SALES_ADMIN
   };
   */
   public static final Set<String> ZSM_PROFS = new Set<String>(Label.Profiles_ZSM.split(','));
   /*
           PROF_CORE_SENIOR_MGR
          ,PROF_CORE_SENIOR_MGR_SB
          ,PROF_MMS_SENIOR_MGR
          ,PROF_MMS_SENIOR_MGR_SB     
          ,PROF_HRS_SALES_MANAGER
          ,PROF_HNBF_SALES_MGR
          ,PROF_MSP_MGR                            // Updated For myStaffingPro
   };
   */
   
   // Is the passed in profile name for a DSA profile.
   public static Boolean isDsaProf(String profName) {
      //return doesProfileNameMatch(profName,'dsaProfs','DsaFss__c=true',DSA_PROFS);
      return doesProfileNameMatch(profName,'Dsa__c',DSA_PROFS);
   } // isDsaProf
   
   // Is the passed in profile name for a DSM profile. 
   public static Boolean isDsmProf(String profName) {
      //return doesProfileNameMatch(profName,'dsmProfs','DsmFsm__c=true',DSM_PROFS);
      return doesProfileNameMatch(profName,'Dsm__c',DSM_PROFS);
   } // isDsmProf
   
   public static Boolean isZsaProf(String profName) {
      return doesProfileNameMatch(profName,'ZSA__c',ZSA_PROFS);
      //return doesProfileNameMatch(profName,'dsmProfs','ZSA__c=true',ZSA_PROFS);
      //return (profName != null && ZSA_PROFS.contains(profName));
   } // isZsaProf
   
   public static Boolean isZsmProf(String profName) {
      return doesProfileNameMatch(profName,'ZSM__c',ZSM_PROFS);
      //return doesProfileNameMatch(profName,'dsmProfs','ZSM__c=true',ZSM_PROFS);
      //return (profName != null && ZSM_PROFS.contains(profName));
   } // isZsmProf
   
   /** Check if this is a DSA or ZSA profile.
    */
   public static Boolean checkDsaZsaProf(Id userId) {
       User user = [select Id, Profile.Name from User where Id=:userId];
       return checkDsaZsaProfName(user.Profile.Name);
   } // checkDsaZsaProf

   public static Boolean checkDsaZsaProfName(String profName) {
      return (profName != null && (isDsaProf(profName)
                 || isZsaProf(profName)
                 || isZsmProf(profName)
                 || profName == PROF_SYS_ADMIN
               ));
   } // checkDsaZsaProfName
   
   public static Boolean checkSysAdminProf(String profName) {
      return (profName == PROF_SYS_ADMIN);
   } // checkSysAdminProf
   
   /** The name of the instance if a sandbox, or an empty string if production. */
   private static String sandboxName = null;
   
   /** The name of the instance of the custom setting that stores the default Paychex information. */
   public static final String PAYCHEX_SETTING_NAME='Primary Setting';
   
   /** The name of the role used to create new users. */
   public static final String NEW_USER_ROLE='New User Role';
   /** The name of the profile used to create new users. */
   public static final String NEW_USER_PROFILE='New User Profile';
   /** The username of the Integration User on production. */
   public static final String INTEGRATION_USER='sfdc_dm@paychex.com';
   
   
   
   /** Check to see if you are on a production instance. If yes, return an empty string.
    * If not, return the name of the sandbox instance you are on. 
    */
   public static String checkForProduction() {
      if (sandboxName == null) {
         sandboxName = (String)CacheManager.getOrg('ProductionOrSandboxName');
      }
      if (String.isBlank(sandboxName)) {
         User user = [Select Id, Username from User where UserName like :INTEGRATION_USER+'%' limit 1];
         // should always be a value returned. But just in case...
         if (user != null) {
            sandboxName = '';
            String username = user.Username;
            if (username.length() > INTEGRATION_USER.length()) {
               // the instance name will be what's left over after removing the username + '.'
               sandboxName = username.subString(INTEGRATION_USER.length()+1);
            }
         } // if (user != null
         if (String.isBlank(sandboxName)) {
            sandboxName = 'Production';
         }
         CacheManager.putOrg('ProductionOrSandboxName',sandboxName);
      } // if (instanceName == null
      String retVal = (String.isBlank(sandboxName) || sandboxName == 'Production' ? '' : sandboxName);
      System.debug('checkForProduction retVal='+retVal);
      return retVal;
   } // checkForProduction
   
   /** Check to see if the passed in value is null. If it is not, return that value.
    * If it is null, return 0.
    * @param testVal - the value to check if null.
    */
   public static Decimal nvl(Decimal testVal) {
      return nvl(testVal,0);
   } // nvl
   
   /** Check to see if the passed in value is null. If it is not, return that value.
    * If it is null, return the retIfNull value.
    * @param testVal - the value to check if null.
    * @param retIfNull - the value to return if testVal is null.
    */
   public static Decimal nvl(Decimal testVal, Decimal retIfNull) {
      if (testVal != null) {
         return testVal;
      }
      return retIfNull;
   } // nvl
   
   public static final String FORMAT_CURRENCY='Currency';
   
   public static String formatAsInteger(Decimal value, String outputType) {
      if (value != null) {
         return formatAsInteger(value.round().intValue(),outputType);
      }
      return null;
   } // formatAsInteger
   
   /** Format an incoming Integer.
    */
   public static String formatAsInteger(Integer value, String outputType) {
      if (value != null) {
         String output = value.format();
         if ((outputType != null) && (outputType == FORMAT_CURRENCY)) {
            output = '$'+output;
         }
         return output;
      } // if (value != null
      return null;
   } // formatInteger
   
   public static String formattedNumber(Integer value, String outputType) {
      return(formattedNumber((Decimal)(value != null ? Decimal.valueOf(value) : null),0,outputType ));
   } // formattedNumber
   
   public static String formattedNumber(Decimal value, Integer decimalPlaces, String outputType) {
      String output = null;
      if (value != null) {
         // if a negative currency, we are going to express it as ($10.00) instead of -$10.00
         Decimal checkValue = value.setScale(decimalPlaces) * ((outputType != null && outputType == FORMAT_CURRENCY && value < 0) ? -1 : 1);
         output = checkValue.format();
         if (decimalPlaces > 0) {
            // ensure that it is displaying to the correct number of significant digits
            if (output.indexOf('.') < 0) {
               // if no period found, add to end
               output += '.';
            }
            // ensure it goes to correct number of digits
            while (output.length() - output.indexOf('.') <= decimalPlaces) {
               output += '0';
            }
         } // if (decimalPlaces > 0
         if (outputType != null) {
            if (outputType == FORMAT_CURRENCY) {
               output = '$'+output;
               if (value < 0) {
                  output = '('+output+')';
               }
            }
         } // if (outputType != null
         
      } // if (value != null)
      return output;
   } // formattedNumber

   public static final String ALL_NUMBERS='0123456789';
   
   public static final String ALL_ALPHAS='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
   
   public static final String ALL_APLHA_NUMERIC ='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-';
   
   /** Remove characters not in p_check_mask from p_check_str. Return the result.
    */
   public static String removeExtraChars(String p_check_str, String p_check_mask) {
      // if no value passed in, return null
      if (String.isBlank(p_check_str)) {
         return null;
      }
      // if no mask passed in, return the original value
      if (String.isBlank(p_check_mask)) {
         return p_check_str;
      }
      String retVal = '';
      for (Integer i=0; i<p_check_str.length(); i++) {
         String token = p_check_str.substring(i, i+1);
         if (p_check_mask.contains(token)) {
            retVal += token;
         }
      } // for (Integer i=0
      return retVal;
   } // removeExtraChars
   
   public static String cleanUrlString(String p_check_str) {
      if (p_check_str != null) {
         p_check_str = p_check_str.replace('&','%26');
         p_check_str = p_check_str.replace('#','%23');      
         p_check_str = p_check_str.replace('\n','-');
      }
      return p_check_str;
   } // cleanUrlString
   
   public static Integer LIMIT_DML_STMT = Limits.getLimitDmlStatements();
   public static Integer LIMIT_DML_ROWS = Limits.getLimitDmlRows();
   
   /** Check to make sure we are not hitting DML limits with this transaction.
    * @param msg the message to display is the limits are hit
    * @param numStmts the number of statemets to add to the current statements executed to see 
                      if the limits are going to be reached.
    * @param numRows the number rows to add to the current DML rows processed to see if the 
                      limits are going to be reached.
    * @return null if no limits, else the error message.
    */
   public static String checkLimits (String msg, Integer numStmts, Integer numRows) {
      // check DML Statement limits
      System.debug('checkLimits dmlStatements='+(Limits.getDMLStatements()+numStmts)+' LIMIT_DML_STMT='+LIMIT_DML_STMT);
      if ((Limits.getDMLStatements()+numStmts) >= LIMIT_DML_STMT) {
         String errorMsg = 'DMLStatement Limits were reached processing '+msg+'. Limit='+Limits.getLimitDmlStatements();
         // limits reached - return error.
         return errorMsg;
      }
      System.debug('checkLimits dmlRows='+(Limits.getDMLRows()+numRows)+' LIMIT_DML_ROWS='+LIMIT_DML_ROWS);
      // check DML Rows Limits - add four to make sure there are enough to finish
      if ((Limits.getDMLRows()+numRows) >= LIMIT_DML_ROWS) {
         String errorMsg = 'DMLRows Limits were reached processing '+msg+'. Limit='+Limits.getLimitDmlRows();
         // limits reached - return error.
         return errorMsg;
      }
      return null;
   } // checkLimits
   
   /** Remove all leading zeroes from the passed in string.
    */
   public static String removeLeadingZero(String strToCheck) {
      if (strToCheck != null) {
         while (strToCheck.startsWith('0')) {
            if (strToCheck.length() > 1) {
               strToCheck = strToCheck.substring(1);
            } else {
               strToCheck = '';
            }
         }
         if (strToCheck.length() == 0) {
            return null;
         }
      } // if (strToCheck != null
      return strToCheck;
   } // removeLeadingZero

   /** Left pad a string with the lpadStr character up to numChars.
    */
   public static String leftPad(String strToCheck, String lpadStr, Integer numChars) {
      if (strToCheck == null) {
         strToCheck = '';
      }
      while (strToCheck.length() < numChars) {
         strToCheck = lpadStr+strToCheck;
      } // while
      return strToCheck;
   } // leftPad
   
   /** Get the FiscalYearSettings object for the passed in fiscal year. A null is 
    *  returned if the value is not found.
    */
   public static FiscalYearSettings getFY(String fiscalYear) {
      FiscalYearSettings fys = null;
      if (fiscalYear != null) {
         String[] fiscalYears = new String[]{fiscalYear};
         FiscalYearSettings[] allFYS = getFYs(fiscalYears);
         if ((allFYS != null) && (allFYS.size() > 0)) {
            fys = allFYS.get(0);
         }
      } // if (fiscalYear != null)
      return fys;
   } // getFY
   
   /** Get the FiscalYearSettings object for all of the passed in fiscal years. An empty list 
    *  returned if no values are found.
    */
   public static FiscalYearSettings[] getFYs(String[] fiscalYears) {
   
          // retrieve all fiscal year records
      FiscalYearSettings[] fySettings = [Select Id, Name, StartDate, EndDate 
                                  From FiscalYearSettings
                                  Where YearType = 'Custom'
                                  and Name IN :fiscalYears ];
      return fySettings;
   } // getFYs
   
   /** Get the FiscalYearSettings object based on the date passed in.
    */
   public static FiscalYearSettings getFYByDate(Date useDate) {
      try {
         FiscalYearSettings fySetting = [Select Id, Name, StartDate, EndDate 
                                  From FiscalYearSettings
                                  Where YearType = 'Custom'
                                  and StartDate <= :useDate
                                  and EndDate >= :useDate ];
         return fySetting;
      } catch (Exception e) {            
      }
      return null;
   } // getFYByDate
   
   /** Check the zip code - if it exists, make sure to only return the main value without an extension.
    * Ex zip code 12345-6789 will return 12345
    * 123 will return null (less than 5 characters - not valid)
    *
    * @param checkStr the postal code value to check
    * @param checkCountry the country value to use to validate the postal code. If null, assume US
    */
   public static String checkPostalCode(String checkStr, String checkCountry) {
      String returnVal = null;
    // make sure not null and at least 5 characters long
    if (checkStr != null && checkStr.length() >= 5) {
         returnVal = checkStr.substring(0,5);
         // make sure the zip code only contains numbers to be valid.
         if (!returnVal.containsOnly('0123456789')) {
            returnVal = null;
         }
      }
      return returnVal;
   } // checkPostalCode
   
   //public static final Integer NAME_FIELD_LENGTH = TriggerFlags__c.Name.getDescribe().getLength();
   
   /* if custom setting contains trigger name, user name (and component) means dont run trigger code for this person, return false
      if custom setting contains trigger name and component means dont run trigger code for anyone, return false 
      put something like this around trigger -  if (Utilities.runTrigger('LeadBefore', UserInfo.getName(), 'optionalcodesectionname')) {run code...
    */  
   /*
   public static Boolean runTrigger(String triggerName, String userName, String component)
   {    
      String squishedComponent = (component != null ? component.replaceAll(' ','') : '');
      // see if turned off for everyone
      String keyStr = (triggerName + squishedComponent).trim().left(NAME_FIELD_LENGTH);
      TriggerFlags__c  tf = TriggerFlags__c.getInstance(keyStr);
      Boolean runTrigger = (tf == null ? true : (tf.DoNotRunTrigger__c ? false : true));
      // if allowed to run for everyone, see if for the passed in user     
      if (runTrigger && String.isNotBlank(userName)) {
         String squishedUName = userName.replaceAll(' ','');
         keyStr = (triggerName + squishedUName + squishedComponent).trim().left(NAME_FIELD_LENGTH);
         tf = TriggerFlags__c.getInstance(keyStr);
         runTrigger = (tf == null ? true : (tf.DoNotRunTrigger__c ? false : true));
      } // if (runTrigger
      
        //String keyStr = triggerName + squishedUName + (component != null ? component.replaceAll(' ','').left(38 - triggerName.length() - squishedUName.length()) : '');       
        //TriggerFlags__c  tf = TriggerFlags__c.getInstance(keyStr.trim());
        //Boolean runTrigger = (tf == null ? true : (tf.DoNotRunTrigger__c ? false : true));        
        // double check if trigger is Not turned off for everyone       
        //if (runTrigger)    
        //{ keyStr = triggerName +  (component != null ? component.replaceAll(' ','').left(38 - triggerName.length() - squishedUName.length()) : '');
        //  tf = TriggerFlags__c.getInstance(keyStr.trim());
        //  runTrigger = (tf == null ? true : (tf.DoNotRunTrigger__c ? false : true));          
    //  }
        return runTrigger;
   } // runTrigger
   */
   public static final String DEFAULT_FORMAT='EEEE MMMM d, yyyy  h:mm a';
   
   private static Map<String,String> dateFormatMap = new Map<String,String>();
   
   /* Use this to quickly clone an instantiated class object. Cast the returning object to the appropriate class type.
    ex. bankLead tempBL = (WebBankLeadHelper.bankLead)utilities.clone(BL, 'WebBankLeadHelper.bankLead'); */
   public static object clone(object obj, string objName){
        String objS = JSON.serialize(obj);
        type ot  = Type.forName(objName);
        system.debug('objS' + objS);
        system.debug('ot' + ot);
        return (object)JSON.deserialize(objS, ot);  
    }

   public static String formatDate(String p_dateType, DateTime dtValue, Decimal p_hoursOffset, String attribute) {
      String formattedValue = null;
      if (dtValue != null) {
         String dateType = (String.isNotBlank(p_dateType) ? p_dateType : 'DEFAULT');
         Integer hoursOffset = (p_hoursOffset != null ? p_hoursOffset.intValue() : 0);
         String dateFormat = dateFormatMap.get(dateType);
         System.debug('formatDate dateType='+dateType+' dateFormat='+dateFormat);
         if (String.isBlank(dateFormat)) {
            PaychexSettings__c setting = PaychexSettings__c.getInstance(dateType);
            System.debug('formatDate setting='+setting);
            if (setting != null && setting.IsActive__c && String.isNotBlank(setting.Attribute1__c)) {
               dateFormat = setting.Attribute1__c;
            } else {
               dateFormat = DEFAULT_FORMAT;
            }
            dateFormatMap.put(dateType, dateFormat);
         } // if (dateFormat == null
         formattedValue = dtValue.addHours(-hoursOffset).format(dateFormat) + (String.isNotBlank(attribute) ? ' '+attribute : '');
         System.debug('formatDate after dateType='+dateType+' dateFormat='+dateFormat+' formattedValue='+formattedValue);
      } // if (dtValue
      return formattedValue;
   } // formatDate
   
   // static variable so can be manually set for testing.
   public static Double DIALED_NBR_SECONDS=(Long.valueOf(Label.NSS_Dialed_Minutes) * 60);
   
   // if the dialed time is within the time limit defined by the label DIALED_MINUTES. Returns
   // false if within that time limit (don't use the dialed checkbox) else if it's outside (or last dialed is null) then returns true.
   public static Boolean checkDialedTimeOkay(DateTime lastDialedTime) {
      Boolean okay = true;
      if (lastDialedTime != null) {
         Double timeDifferenceMilliseconds = lastDialedTime.getTime() - DateTime.now().getTime();
         // convert to seconds - make sure it's a positive number
         Double timeDifferenceSeconds = Math.abs(timeDifferenceMilliseconds / 1000);
         // it's only okay to use if time difference is greater than the value stored in the label.
         okay = timeDifferenceSeconds > DIALED_NBR_SECONDS;
         System.debug('checkDialedTimeOkay okay='+okay+' nbrSeconds='+DIALED_NBR_SECONDS+' timeDifferenceSeconds='+timeDifferenceSeconds+' timeDifferenceMilliseconds='+timeDifferenceMilliseconds);
      } // if (lastDialedTime != null
      System.debug('checkDialedTimeOkay okay='+okay+' lastDialedTime='+lastDialedTime);
      return okay;
   } // checkDialedTimeOkay
   
   //public static Map<String,Boolean> hasScenarioMap = new Map<String,Boolean>();
   // check to see if dupeblocker is setup
   public static Boolean checkDupeBlocker(String scenarioType) {
      return false;
      /*  commented out 9/26/2023 for Dupeblocker removal. Can be deleted in the future
      Boolean hasScenario = hasScenarioMap.get(scenarioType);
      Boolean retrieved = false;
      if (hasScenario == null) {
         // check if there is a dupeblocker scenario setup
         hasScenario = ([select count() from CRMfusionDBR101__Scenario__c where CRMFUSIONDBR101__SCENARIO_TYPE__C = :scenarioType limit 1] > 0);
         hasScenarioMap.put(scenarioType,hasScenario);
         retrieved = true;
      }
      System.debug('checkDupeBlocker hasScenario='+hasScenario+' retrieved='+retrieved);  
      return hasScenario;
      */
   } // checkDupeBlocker

   // is this test running where seeAllData=false
   public static Boolean isTestSiloed() {
      Boolean siloed = Test.IsRunningTest() && (SalesOrg__c.getAll().size() == 0 || TimeZone__c.getAll().size() == 0 || Apex_Batch_Control__c.getAll().size() == 0);
      return siloed;
   } // isTestSiloed
   
   /* Is this displaying in Salesforce1? */
   public static Boolean isSF1() {
      try {
       if(String.isNotBlank(ApexPages.currentPage().getParameters().get('sfdcIFrameHost')) ||
          String.isNotBlank(ApexPages.currentPage().getParameters().get('sfdcIFrameOrigin')) ||
          ApexPages.currentPage().getParameters().get('isdtp') == 'p1' ||
          (ApexPages.currentPage().getParameters().get('retURL') != null && ApexPages.currentPage().getParameters().get('retURL').contains('projectone') )
         ) {
             return true;
         }
      } catch (Exception e) {
         System.debug('isSF1 exception: '+e.getMessage()+'; '+e.getStackTraceString());
      }
      return false;
    } //isSF1
   /* Is this displaying in Salesforce1? */
   public static Boolean isMobile() {
      try {
       if(UserInfo.getUiThemeDisplayed()=='Theme4t') {
             return true;
         }
      } catch (Exception e) {
         System.debug('isMobile exception: '+e.getMessage()+'; '+e.getStackTraceString());
      }
      return false;
    } //isSF1
    
   public static String SLEEP_MODE=Label.SleepMode;
   public static String SLEEP_URL=Label.SleepURL;
    
   // perform a "wait" - be very careful with this, and the calling process must allow callouts. 
   public static Long Sleep(Integer sleepSeconds) {
      //Integer sleepSeconds = 4;
      // don't allow it to sleep more than 10 seconds
      String sleepDesc = 'StartTime: '+Datetime.now().format('M/d/yyyy H:mm:ss')+' sleepSeconds='+sleepSeconds;
      sleepSeconds = (sleepSeconds > 10 ? 10 : sleepSeconds);
      Long startTS = System.currentTimeMillis();
      System.debug('Start '+startTS);
      HttpRequest req = new HttpRequest();
      if (SLEEP_MODE=='PurgeSingle') {
         req.setEndpoint('https://'+URL.getOrgDomainUrl().getHost()+'/services/apexrest/purgeSingle/');
         req.setMethod('POST');
         String body = '{"nbrSecs":"'+sleepSeconds+'"}';
         req.setBody(body);
         req.setHeader('Authorization', 'Bearer '+ UserInfo.getSessionId());
         req.setHeader('Content-Type', 'application/json');
         req.setTimeout(120000);
      } else {
         req.setEndpoint(SLEEP_URL + sleepSeconds);
         req.setMethod('GET');
      }
      Http http = new Http();
      // let's not do the callout when running a test
      if (!Test.isRunningTest()) {
         try {
            HTTPResponse res = http.send(req);
         } catch (Exception e) {
            ErrorLog.logError('Utilities', 'Sleep', 'Calling the Sleep Method ', null, sleepDesc+' '+e.getMessage()+'; '+e.getStackTraceString(), null, true);
         }
      } // if (!Test.isRunningTest
      Long duration = System.currentTimeMillis() - startTS;
      System.debug('Sleep Duration: ' + duration + 'ms');
      return duration;
   } // Sleep
   
   // for testing purposes
   public static Boolean SKIP_FUTURE=false;
   // can we make a future call?
   public static Boolean allowFuture() {
      if (SKIP_FUTURE || System.isFuture() || System.isBatch() || System.isQueueable()) {
         return false;
      }
      return true;
   } // allowFuture

} // class Utilities