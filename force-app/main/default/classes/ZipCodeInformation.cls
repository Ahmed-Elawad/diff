/**
 * Methods for the ZipCodeInformation object.
 *
 * History
 * -------
 * 09/17/2013 Dan Carmen   Created
   02/05/2016 Dan Carmen   Added getZipInfo method
   02/17/2016 Dan Carmen   Changed getZipInfo to getZciMap
   12/30/2022 Dan Carmen   Added checkStateAbbrev method
   03/04/2024 Dan Carmen   Move code to the apex class.


 */
public with sharing class ZipCodeInformation {

   public static final String TZ_DEFAULT='DEFAULT';
        
   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      if (isBefore) {
         handleBefore((Zip_Code_Information__c[])recs, (Map<Id,Zip_Code_Information__c>)oldMap); 
      } else if (isAfter) {
         handleAfter((Zip_Code_Information__c[])recs, (Map<Id,Zip_Code_Information__c>)oldMap); 
      }
   } // handleTrigger

   public static void handleBefore(Zip_Code_Information__c[] recs, Map<Id,Zip_Code_Information__c> oldMap) {
      for (Zip_Code_Information__c zci : recs) {
         // verify the country code
         zci.Country__c = TimeZoneHelper.verifyCountryCode(zci.State__c);
         
         // verify name field is 5 characters - left pad with zeroes
         // ensure a 5 digit zip code
         String checkZip = ZipAssignment.checkZipCodeLength(zci.Name,zci.Country__c);
         if (checkZip != zci.Name) {
            zci.Name = checkZip;
         } // if (checkZip
         
         // ensure the key is filled out
         String checkKey = 'Z'+zci.Name;
         if (checkKey != zci.Zip_Code_Key__c) {
            zci.Zip_Code_Key__c = checkKey;
         } // if (checkKey
         
         String tzKey = (String.isNotBlank(zci.City__c) ? zci.City__c.toUpperCase()+'-'+zci.State__c : null);
         TimeZone__c timeZone = null;
         if (tzKey != null) {
            timeZone = TimeZone__c.getInstance(tzKey);
         }
         if (timeZone == null && String.isNotBlank(zci.State__c)) {
            if (!zci.DaylightSavings__c) {
               tzKey = zci.State__c+'-NoDaylight';
               timeZone = TimeZone__c.getInstance(tzKey);
            }
            if (timeZone == null) {
               tzKey = zci.State__c;
               timeZone = TimeZone__c.getInstance(tzKey);
            }
         }
         if (timeZone == null) {
            tzKey = ZipCodeInformation.TZ_DEFAULT;
            timeZone = TimeZone__c.getInstance(tzKey);
         }
         if (timeZone != null) {
         	if (zci.TimeZoneName__c != timeZone.TimeZoneName__c) {
         		zci.TimeZoneName__c = timeZone.TimeZoneName__c;
         	}
         	if (zci.TimeZoneAbbrev__c != timeZone.Abbrev__c) {
               zci.TimeZoneAbbrev__c = timeZone.Abbrev__c;
            }
         } // if (timeZone != null
      } // for (Zip_Code_Information__c zc

   } // handleBefore
    
   public static void handleAfter(Zip_Code_Information__c[] recs, Map<Id,Zip_Code_Information__c> oldMap) {
      // a set of the zip codes
      Set<String> areaCodeSet = new Set<String>();
      // map, by the zci id, of the area codes per zip code
      Map<Id,Set<String>> zciAreaCodeMap = new Map<Id,Set<String>>();

      for (Zip_Code_Information__c zci : recs) {
         // check area code linking
         // check all records
         Set<String> thisAreaCodeSet = new Set<String>();
         if (String.isNotBlank(zci.AreaCode__c)) {
            // parse out the area code list
            thisAreaCodeSet.addAll(zci.AreaCode__c.split('/'));
            areaCodeSet.addAll(thisAreaCodeSet);
         }
         zciAreaCodeMap.put(zci.Id,thisAreaCodeSet);
      } // for (Zip_Code_Information

      if (!zciAreaCodeMap.isEmpty()) {
         processAreaCodes(zciAreaCodeMap,areaCodeSet);
      }

   } // handleAfter
    
   public static void processAreaCodes(Map<Id,Set<String>> zciAreaCodeMap, Set<String> p_areaCodeSet) {
   	// select all area code records
   	Map<String,AreaCode__c> areaCodeMap = new Map<String,AreaCode__c>();
   	for (AreaCode__c[] areaCodes : [Select Id, Name from AreaCode__c where Name in :p_areaCodeSet]) {
   	   for (AreaCode__c areaCode : areaCodes) {
   	      areaCodeMap.put(areaCode.Name, areaCode);
   	   } // for (AreaCode__c
   	} // for (AreaCode__c[]
   	
   	// store in a map for easy reference
   	Map<Id, Zip_Code_Information__c> zciMap = new Map<Id, Zip_Code_Information__c>();
   	// select zip code information records with area code links
   	for (Zip_Code_Information__c[] zcis : [Select Id
   	                                        ,Name
   	                                        ,AreaCode__c
   	                                        ,(Select Id
   	                                                ,AreaCode__c
   	                                                ,AreaCode__r.Id
   	                                                ,AreaCode__r.Name
   	                                                ,Zip_Code_Information__c
   	                                            From AreaCodeLinks__r)
   	                                    From Zip_Code_Information__c
   	                                   Where Id in :zciAreaCodeMap.keySet()]) {
   	   for (Zip_Code_Information__c zci : zcis) {
   	      zciMap.put(zci.Id, zci);
   	   } // for (Zip_Code_Information__c zci
   	   
   	} // for (Zip_Code_Information__c[] zcis

      // the links to delete
      AreaCodeLink__c[] linksToDelete = new AreaCodeLink__c[]{};
      // the links to add
      AreaCodeLink__c[] linksToCreate = new AreaCodeLink__c[]{};
      // areaCodes to create
      AreaCode__c[] areaCodesToCreate = new AreaCode__c[]{};
      
      // for each zip code make sure it has only the links it needs
      for (Id zciId : zciAreaCodeMap.keySet()) {
         Set<String> thisAreaCodeSet = zciAreaCodeMap.get(zciId);
         Zip_Code_Information__c zci = zciMap.get(zciId);
         if (zci.AreaCodeLinks__r != null) {
            // remove the area codes from the set that already exist. If an area code isn't in the set (not part of this zip code)
            // delete that link
            for (AreaCodeLink__c acl : zci.AreaCodeLinks__r) {
            	if (thisAreaCodeSet.contains(acl.AreaCode__r.Name)) {
            	   thisAreaCodeSet.remove(acl.AreaCode__r.Name);
            	} else {
                  // if not in the set remove this link
                  linksToDelete.add(acl);
               }
            } // for
         } // if (zci.AreaCodeLinks__r
         
         // if there's anything left in the set, create new links
         for (String areaCode : thisAreaCodeSet) {
            // find the area code record
            AreaCode__c ac = areaCodeMap.get(areaCode);
            if (ac == null) {
               ac = new AreaCode__c(Name=areaCode);
               areaCodesToCreate.add(ac);
               // store in the map to reuse
               areaCodeMap.put(areaCode,ac);
            }
            AreaCodeLink__c acl = new AreaCodeLink__c(Zip_Code_Information__c=zciId);
            if (ac.Id == null) {
               acl.AreaCode__r=ac;
            } else {
               acl.AreaCode__c=ac.Id;
            }
            linksToCreate.add(acl);
         } // for (String areaCode
      } // for (Id zciId
      
      if (!areaCodesToCreate.isEmpty()) {
         // insert the new area code records
         insert areaCodesToCreate;
         
         // find the links of the records that were created and set the ids
         for (AreaCodeLink__c acl : linksToCreate) {
            if (acl.AreaCode__c == null && acl.AreaCode__r != null) {
               acl.AreaCode__c = acl.AreaCode__r.Id;
               acl.AreaCode__r = null;
            }
         } // for (AreaCodeLink__c
      } // if (!areaCodesToCreate.isEmpty
      
      if (!linksToCreate.isEmpty()) {
      	insert linksToCreate;
      }
      
      if (!linksToDelete.isEmpty()) {
         delete linksToDelete;
      }
   } // processAreaCodes

   public static String format5DigitZip(String checkZip) {
      String zipCode = checkZip;
      if (String.isNotBlank(zipCode)) {
         // make sure at least 5 characters - left pad if needed
         while (zipCode.length() < 5) {
            zipCode = '0'+ZipCode;
         } // while
         // make sure no more than 5 characters
         zipCode = zipCode.left(5);
      } // if (String.isNotBlank(zipCode
      return zipCode;
   } // format5DigitZip
   
   // get a map of zip code information records based on the passed in zip codes
   public static Map<String,Zip_Code_Information__c> getZciMap(Set<String> zipCodeSet) {
      Map<String,Zip_Code_Information__c> zciMap = new Map<String,Zip_Code_Information__c>();
      if (zipCodeSet != null && !zipCodeSet.isEmpty()) {
         Zip_Code_Information__c[] zcis = [select Id, Name, City__c, State__c
                                             From Zip_Code_Information__c
                                            Where Name in :zipCodeSet];
         for (Zip_Code_Information__c zci : zcis) {
            zciMap.put(zci.Name, zci);
         }
      } // if (zipCodeSet
      return zciMap;
   } // getZciMap
    
   public static String checkStateAbbrev(String checkValue, Boolean returnBlankIfNoMatch) {
      String returnVal = checkValue;
      if (String.isNotBlank(checkValue) && checkValue.length()>2) {
         //Abbreviation__mdt[] abbrevs = [Select Id, MasterLabel, Abbrev__c, Type__c from Abbreviation__mdt where MasterLabel=:returnVal];
         //returnVal = (!abbrevs.isEmpty() ? abbrevs[0].Abbrev__c : checkValue);
         // getInstance uses the DeveloperName field which doesn't support spaces or periods
         checkValue = checkValue.replaceAll('[^a-zA-Z]', '');
         checkValue = checkValue.replaceAll(' ','');
         Abbreviation__mdt abbrev = Abbreviation__mdt.getInstance(checkValue);
         // if we don't have a valid abbreviation, do we ultimately want to clear the value?
         returnVal = (abbrev != null ? abbrev.Abbrev__c : (returnBlankIfNoMatch ? '' : returnVal));
      } // if (String.isNotBlank(returnVal
      return returnVal;
   } // checkStateAbbrev
   
} // class ZipCodeInformation